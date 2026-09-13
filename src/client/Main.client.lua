--!strict
--[[
	Main.client.lua
	Bootstrap de PRODUÇÃO do cliente: monta o HUDController e conecta os
	RemoteEvents reais do jogo (shared/Networking/Remotes.lua) à API pública
	do HUD. Sem simulação e sem dado de exemplo — isso é HUDTest.client.lua,
	que continua existindo só como ferramenta de teste manual.

	Localização Rojo: StarterPlayer/StarterPlayerScripts/Main
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUDController = require(script.Parent.UI.HUD.HUDController)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local DivineCreatures = require(ReplicatedStorage.Shared.Data.DivineCreatures)
local Icons = require(ReplicatedStorage.Shared.UI.Icons)
local DesignTokens = require(ReplicatedStorage.Shared.Config.DesignTokens)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hud = HUDController.new(playerGui)

-- ===================== ÁLBUM: TOTAL DE SLOTS =====================
-- 300 criaturas base + 15 Divinas = 315 slots no total (ver
-- GAME_DESIGN_CARTAS_MITICAS_v3.md, seção "Coleção"). Contado a partir dos
-- catálogos reais em vez de cravar "315" na mão, pra nunca ficar desatualizado
-- se um catálogo mudar de tamanho.
local ALBUM_TOTAL = 0
for _ in Creatures do
	ALBUM_TOTAL += 1
end
ALBUM_TOTAL += #DivineCreatures.List

-- Mochila tem 1 registro por criatura DESCOBERTA (não por cópia) - mesma
-- contagem serve tanto pro contador do Álbum quanto da Mochila na Sidebar
-- (ver CLAUDE.md, seção "Arquitetura de 3 camadas").
local function countDiscovered(mochila: { [number]: any }): number
	local count = 0
	for _ in mochila do
		count += 1
	end
	return count
end

-- ===================== RESYNC SOB DEMANDA =====================
-- Não existe (nem deveria existir) um RemoteEvent dedicado de "o Álbum
-- mudou" - PlayerSnapshotResult já é o retrato completo pensado pra
-- ressincronizar o cliente (ver SnapshotService.lua), então reusamos ele
-- depois de qualquer ação que possa ter mudado Álbum/Mochila/saldo, em vez
-- de inventar um remote novo.
local function requestFreshSnapshot()
	Remotes.GetPlayerSnapshotRequest:FireServer()
end

-- ===================== BADGE "bell": não lidas, só estado de cliente =====================
-- Contagem de notificações não lidas é estado de UI puro - não existe (nem
-- faria sentido existir) um RemoteEvent servidor->cliente só pra isso.
-- Incrementa a cada notificação empurrada, zera quando o jogador clica no
-- sino (ver OnNavigate mais abaixo).
local unreadBellCount = 0

local function pushNotification(icon: string, title: string, subtitle: string)
	unreadBellCount += 1
	hud:SetBadge("bell", unreadBellCount)
	hud:PushNotification({ icon = icon, title = title, subtitle = subtitle, time = "Agora" })
end

-- ===================== BADGE "gift": presentes não resgatados =====================
-- Soma duas fontes independentes de "presente esperando": Baús da Jornada
-- desbloqueados e não resgatados + Bênção Diária disponível agora. Cada uma
-- guarda sua própria contagem e o badge mostra sempre a soma das duas.
local unclaimedJourneyChests = 0
local dailyBlessingAvailable = 0 -- 0 ou 1 - Bênção Diária não tem "quantidade", só disponível/resgatada

local function refreshGiftBadge()
	hud:SetBadge("gift", unclaimedJourneyChests + dailyBlessingAvailable)
end

Remotes.JourneyChestStatusUpdated.OnClientEvent:Connect(function(status: any)
	if not status then
		return
	end

	unclaimedJourneyChests = 0
	for _, chest in status.chests do
		if chest.unlocked and not chest.claimed then
			unclaimedJourneyChests += 1
		end
	end
	refreshGiftBadge()
end)

-- ===================== ECONOMIA =====================

-- Guarda o requisito de Dinheiro da Prova atual (vem de ProvaStatusUpdated)
-- pra recalcular a barra de progresso localmente a cada MoneyUpdated, sem
-- precisar pedir ProvaStatusRequest de novo a cada centavo que entra.
local currentMoneyRequirement: number? = nil

Remotes.MoneyUpdated.OnClientEvent:Connect(function(amount: number)
	hud:SetMoney(amount)
	if currentMoneyRequirement then
		hud:SetRenascimentoProgress(amount, currentMoneyRequirement)
	end
end)

Remotes.DiamondsUpdated.OnClientEvent:Connect(function(amount: number)
	hud:SetDiamonds(amount)
end)

Remotes.IncomePerSecondUpdated.OnClientEvent:Connect(function(amount: number)
	hud:SetIncomePerSecond(amount)
end)

Remotes.OfflineEarningsReady.OnClientEvent:Connect(function(earned: number, _secondsOffline: number)
	local message = string.format("Você ganhou $%s enquanto estava offline", DesignTokens.FormatCompact(earned))
	pushNotification(Icons.Get("PilhaDeMoedas"), "Renda Offline", string.format("Você ganhou $ %s enquanto estava fora", tostring(math.floor(earned))))
	hud:SetOfflineEarningsMessage(message)
end)

-- ===================== RENASCIMENTO / ALTAR =====================

Remotes.ProvaStatusUpdated.OnClientEvent:Connect(function(status: any)
	if not status then
		return
	end

	for _, reqStatus in status.requirements do
		if reqStatus.requirement.type == "money" then
			currentMoneyRequirement = reqStatus.needed
			hud:SetRenascimentoProgress(reqStatus.current, reqStatus.needed)
			break
		end
	end

	hud:SetAltarStatus(status.canRenascer)
end)

Remotes.RenascimentoResult.OnClientEvent:Connect(function(success: boolean, resultOrError: any)
	if success then
		hud:SetRenascimento(resultOrError.newRenascimentoLevel, resultOrError.newMultiplier)
		pushNotification("♻️", "Renascimento!", "Você renasceu para o ciclo " .. tostring(resultOrError.newRenascimentoLevel))
		-- Ciclo novo = clã/criatura/quantia da Prova mudaram - reconsulta.
		Remotes.ProvaStatusRequest:FireServer()
	else
		hud:ShowToast("⛩️ " .. tostring(resultOrError))
	end
end)

-- ===================== PORTAL DA SORTE (evento global) =====================

-- O Portal só avisa o cliente quando abre/fecha (PortalOpened/PortalClosed)
-- ou sob demanda (PortalStatusRequest) - não existe um "tick" de servidor a
-- cada segundo. Pra o número do countdown continuar descendo entre um
-- evento e outro, guardamos o valor recebido e decrementamos localmente a
-- cada segundo (mesma técnica de qualquer countdown de UI - não é
-- simulação, é só exibir o tempo real passando a partir de uma âncora real
-- do servidor).
local portalSecondsRemaining: number? = nil

local function applyPortalStatus(status: any)
	if not status then
		return
	end

	portalSecondsRemaining = status.active and status.secondsRemaining or status.secondsUntilNext
	hud:SetPortalCountdown(portalSecondsRemaining, true)
end

Remotes.PortalStatusUpdated.OnClientEvent:Connect(applyPortalStatus)

Remotes.PortalOpened.OnClientEvent:Connect(function(status: any)
	applyPortalStatus(status)
	pushNotification("🌀", "Portal da Sorte", (status and status.label) or "O Portal abriu!")
end)

Remotes.PortalClosed.OnClientEvent:Connect(function(status: any)
	applyPortalStatus(status)
end)

task.spawn(function()
	while true do
		task.wait(1)
		if portalSecondsRemaining and portalSecondsRemaining > 0 then
			portalSecondsRemaining -= 1
			hud:SetPortalCountdown(portalSecondsRemaining, true)
		end
	end
end)

-- ===================== RODA DO DESTINO =====================

local function applyWheelStatus(status: any)
	if not status then
		return
	end
	hud:SetWheelNotification(status.freeSpinAvailable or status.bonusSpinsAvailable > 0)
end

Remotes.WheelStatusUpdated.OnClientEvent:Connect(applyWheelStatus)

Remotes.SpinWheelResult.OnClientEvent:Connect(function(success: boolean, resultOrError: any)
	if success then
		for _, prizeResult in resultOrError do
			pushNotification("🎡", "Roda do Destino", prizeResult.label or "Prêmio resgatado!")
		end
		requestFreshSnapshot()
	else
		hud:ShowToast("🎡 " .. tostring(resultOrError))
	end
	Remotes.WheelStatusRequest:FireServer()
end)

-- ===================== PACOTES =====================

Remotes.PackOpened.OnClientEvent:Connect(function(success: boolean, resultOrError: any)
	if success then
		pushNotification("🃏", "Pacote aberto", string.format("%d carta(s) reveladas", #resultOrError.Cards))
		requestFreshSnapshot()
	else
		hud:ShowToast("🃏 " .. tostring(resultOrError))
	end
end)

-- Sidebar mostra só UM cooldown global ao lado do ícone "Pacotes" (não um
-- por pacote) - reflete sempre o cooldown do ÚLTIMO pacote com limite de
-- tempo que o jogador abriu, não uma soma de todos os 62 pacotes.
local packCooldownSecondsRemaining: number? = nil

Remotes.PackCooldownUpdated.OnClientEvent:Connect(function(_packKey: string, secondsRemaining: number)
	packCooldownSecondsRemaining = secondsRemaining
	hud:SetPackCooldown(secondsRemaining)
end)

task.spawn(function()
	while true do
		task.wait(1)
		if packCooldownSecondsRemaining and packCooldownSecondsRemaining > 0 then
			packCooldownSecondsRemaining -= 1
			hud:SetPackCooldown(packCooldownSecondsRemaining)
		end
	end
end)

-- ===================== ÁLBUM / MOCHILA / RETRATO COMPLETO =====================

Remotes.PlayerSnapshotResult.OnClientEvent:Connect(function(snapshot: any)
	if not snapshot then
		return
	end

	hud:SetMoney(snapshot.money)
	hud:SetDiamonds(snapshot.diamonds)
	hud:SetIncomePerSecond(snapshot.totalIncomePerSecond)
	hud:SetRenascimento(snapshot.renascimentoLevel, snapshot.renascimentoMultiplier)

	local discovered = countDiscovered(snapshot.mochila)
	hud:SetAlbumProgress(discovered, ALBUM_TOTAL)
	hud:SetBackpackCount(discovered)
end)

-- ===================== DESPERTAR =====================

Remotes.AwakenResult.OnClientEvent:Connect(function(success: boolean, resultOrError: any)
	if success then
		if resultOrError.improved then
			pushNotification("✨", "Despertar melhorou!", string.format("Novo grau: %.1f", resultOrError.finalGrade))
		elseif resultOrError.worsened then
			pushNotification("💔", "Despertar piorou", string.format("Novo grau: %.1f", resultOrError.finalGrade))
		end
	else
		hud:ShowToast("✨ " .. tostring(resultOrError))
	end
end)

-- ===================== VENDA =====================

Remotes.SellCardResult.OnClientEvent:Connect(function(success: boolean, resultOrError: any)
	if success then
		requestFreshSnapshot()
	else
		hud:ShowToast("💰 " .. tostring(resultOrError))
	end
end)

-- ===================== PACTO DOS GUARDIÕES (doação / troca) =====================

Remotes.DonateCardResult.OnClientEvent:Connect(function(success: boolean, messageOrError: any)
	if success then
		pushNotification("🤝", "Pacto dos Guardiões", tostring(messageOrError or "Doação concluída"))
		requestFreshSnapshot()
	else
		hud:ShowToast("🤝 " .. tostring(messageOrError))
	end
end)

Remotes.TradeCompleted.OnClientEvent:Connect(function()
	pushNotification("🤝", "Pacto dos Guardiões", "Troca concluída!")
	requestFreshSnapshot()
end)

Remotes.TradeCancelled.OnClientEvent:Connect(function()
	hud:ShowToast("🤝 Troca cancelada")
end)

-- ===================== BÊNÇÃO DIÁRIA / STREAK =====================

Remotes.DailyBlessingStatusUpdated.OnClientEvent:Connect(function(status: any)
	if not status then
		return
	end

	dailyBlessingAvailable = status.available and 1 or 0
	refreshGiftBadge()

	if status.nextReward then
		hud:SetStreak(status.currentStreak, status.nextReward.day, status.nextReward.label)
	end
end)

Remotes.DailyBlessingResult.OnClientEvent:Connect(function(success: boolean, resultOrError: any)
	if success then
		pushNotification("🎁", "Bênção Diária", resultOrError.label or "Recompensa resgatada")
		if resultOrError.packResult then
			requestFreshSnapshot()
		end
	else
		hud:ShowToast("🎁 " .. tostring(resultOrError))
	end
	-- Resgatou (ou tentou) - reconsulta o status pra atualizar streak/badge.
	Remotes.DailyBlessingStatusRequest:FireServer()
end)

-- ===================== BAÚS DA JORNADA =====================

Remotes.JourneyChestResult.OnClientEvent:Connect(function(success: boolean, resultOrError: any)
	if success then
		pushNotification("🎁", "Baú da Jornada", resultOrError.label or "Baú resgatado")
		if resultOrError.packResult then
			requestFreshSnapshot()
		end
	else
		hud:ShowToast("🎁 " .. tostring(resultOrError))
	end
end)

-- ===================== NAVEGAÇÃO =====================
-- Nenhuma tela (Álbum, Mochila, Altar, Pacotes, Loja, Roda do Destino, Pacto,
-- Ranking, Recompensas, Configurações) existe como módulo em client/UI/
-- ainda - só o HUD em si está construído. Todo destino abaixo é placeholder
-- até essas telas serem implementadas.

hud:OnNavigate(function(key: string)
	if key == "Notificacoes" then
		-- Não abre tela nenhuma - o painel de notificações já fica sempre
		-- visível; clicar no sino só marca as notificações como lidas.
		unreadBellCount = 0
		hud:SetBadge("bell", 0)
		return
	end

	if key == "Inicio" then
		-- O próprio HUD já É a tela "Início" - nada a abrir.
		return
	end

	-- TODO: abrir a tela real de "key" quando o módulo existir em
	-- client/UI/<Tela>/. Por enquanto só avisa no Output pra não travar o
	-- clique do jogador.
	warn(("[Main.client.lua] Navegação para '%s' ainda não tem tela implementada"):format(key))
end)

-- ===================== BOOT =====================

requestFreshSnapshot()
Remotes.ProvaStatusRequest:FireServer()
Remotes.PortalStatusRequest:FireServer()
Remotes.WheelStatusRequest:FireServer()
Remotes.JourneyChestStatusRequest:FireServer()
Remotes.DailyBlessingStatusRequest:FireServer()

print("[Main.client.lua] HUD de produção montado, aguardando dados do servidor.")
