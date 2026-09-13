--!strict
--[[
	HUDTest.client.lua
	Script de TESTE — monta o HUDController completo e simula economia,
	renascimento, streak e evento do Portal da Sorte rodando ao vivo.

	Localização Rojo: StarterPlayer/StarterPlayerScripts/HUDTest

	Ao apertar Play, você deve ver:
	  - $ subindo sozinho + $/s fixo
	  - 💎 ganhando de tempos em tempos + toast
	  - Progresso de Renascimento enchendo até liberar o Altar
	  - Card de Streak de Login preenchido
	  - Notificações aparecendo na lista da direita
	  - Ícone do Portal da Sorte no canto inferior direito com countdown
	  - Sidebar (desktop) ou BottomBar (se encolher a janela) navegando
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Main.client.lua já monta o HUD de produção com dados reais do servidor.
-- Os dois são LocalScripts irmãos na mesma pasta (Rojo sincroniza ambos), e
-- rodar os dois juntos monta dois HUDControllers/ScreenGuis sobrepostos —
-- os chips ficam com números fantasmas de dois estados diferentes por cima
-- um do outro. Pra usar este teste manual, desative/apague Main.client.lua
-- no Studio antes de dar Play.
if script.Parent:FindFirstChild("Main") then
	warn("[HUDTest] Main.client.lua está presente — pulando montagem duplicada do HUD. Desative Main.client.lua no Studio pra rodar este teste manual.")
	return
end

local HUDController = require(script.Parent.UI.HUD.HUDController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== MONTAR O HUD =====================

local hud = HUDController.new(playerGui)

local state = {
	money = 1_250_000,
	diamonds = 450,
	incomePerSecond = 35_100,
	renascimentoCycle = 2,
	renascimentoMultiplier = 1.85,
	renascimentoCurrent = 6_250_000,
	renascimentoTarget = 10_000_000,
	albumDiscovered = 315,
	albumTotal = 315,
	backpackCount = 240,
}

hud:SetMoney(state.money)
hud:SetDiamonds(state.diamonds)
hud:SetIncomePerSecond(state.incomePerSecond)
hud:SetRenascimento(state.renascimentoCycle, state.renascimentoMultiplier)
hud:SetRenascimentoProgress(state.renascimentoCurrent, state.renascimentoTarget)
hud:SetAltarStatus(state.renascimentoCurrent >= state.renascimentoTarget)
hud:SetAlbumProgress(state.albumDiscovered, state.albumTotal)
hud:SetBackpackCount(state.backpackCount)
hud:SetBadge("gift", 3)
hud:SetBadge("bell", 7)
hud:SetWheelNotification(true)
hud:SetOfflineEarningsMessage("Você ganhou $3M enquanto estava offline")

hud:SetStreak(7, 7, "Pacote grátis + 50 Diamante!")

hud:PushNotification({
	icon = "🤝",
	title = "Pacto dos Guardiões",
	subtitle = "Trocas disponíveis!",
	time = "Agora",
})
hud:PushNotification({
	icon = "🎁",
	title = "Evento de Fim de Semana",
	subtitle = "Começou! Participe agora.",
	time = "2m",
})
hud:PushNotification({
	icon = "💎",
	title = "Desafio Diário",
	subtitle = "Recompensa disponível!",
	time = "5m",
})

hud:OnNavigate(function(key: string)
	print("[HUDTest] Navegou para:", key)
end)

-- ===================== SIMULAÇÃO 1: RENDA PASSIVA =====================

local accumulator = 0
RunService.Heartbeat:Connect(function(deltaTime: number)
	accumulator += state.incomePerSecond * deltaTime
	if accumulator >= 1 then
		local wholeAmount = math.floor(accumulator)
		accumulator -= wholeAmount
		state.money += wholeAmount
		hud:SetMoney(state.money)
	end
end)

-- ===================== SIMULAÇÃO 2: GANHO DE DIAMANTE ALEATÓRIO =====================

task.spawn(function()
	while true do
		task.wait(math.random(6, 10))
		local gained = math.random(20, 120)
		state.diamonds += gained
		hud:SetDiamonds(state.diamonds)
		hud:ShowToast(("✨ Você ganhou %d 💎!"):format(gained), Color3.fromHex("#3ec8ff"))
	end
end)

-- ===================== SIMULAÇÃO 3: PROGRESSO DO RENASCIMENTO =====================

task.spawn(function()
	while true do
		task.wait(math.random(2, 4))
		if state.renascimentoCurrent < state.renascimentoTarget then
			state.renascimentoCurrent = math.min(
				state.renascimentoTarget,
				state.renascimentoCurrent + math.random(200_000, 600_000)
			)
			hud:SetRenascimentoProgress(state.renascimentoCurrent, state.renascimentoTarget)

			local altarAvailable = state.renascimentoCurrent >= state.renascimentoTarget
			hud:SetAltarStatus(altarAvailable)
			if altarAvailable then
				hud:ShowToast("⛩️ Altar disponível! Você pode Renascer.", Color3.fromHex("#22c55e"))
			end
		end
	end
end)

-- ===================== SIMULAÇÃO 4: PORTAL DA SORTE (evento) =====================

task.spawn(function()
	local secondsUntilPortal = 5025 -- ~1h23m, igual ao protótipo
	hud:SetPortalCountdown(secondsUntilPortal, true)

	while secondsUntilPortal > 0 do
		task.wait(1)
		secondsUntilPortal -= 1
		hud:SetPortalCountdown(secondsUntilPortal, true)
	end

	hud:ShowToast("🌀 Portal da Sorte começou!", Color3.fromHex("#f5b301"))
	hud:SetPortalCountdown(nil, false)
end)

-- ===================== SIMULAÇÃO 5: BADGES / NOTIFICAÇÕES =====================

task.spawn(function()
	local giftCount = 3
	local bellCount = 7

	while true do
		task.wait(math.random(8, 14))
		giftCount += 1
		hud:SetBadge("gift", giftCount)

		task.wait(math.random(4, 9))
		bellCount += 1
		hud:SetBadge("bell", bellCount)
	end
end)

print("[HUDTest] HUDController montado. Simulação completa rodando — pressione Play para testar.")
