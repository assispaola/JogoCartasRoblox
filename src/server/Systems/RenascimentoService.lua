--[[
	RenascimentoService.lua
	Checa a Prova do Renascimento atual (3 requisitos simultâneos: 3 cartas
	de um clã à escolha livre + 1 criatura específica, ambos via Altar de
	Sacrifício, + saldo mínimo de Dinheiro) e processa o reset quando o
	jogador confirma.

	Sob o modelo de Álbum/Mochila (que persiste incondicionalmente através
	do Renascimento - ver SISTEMA_ALBUM_E_EVOLUCAO.md seção 7), não existe
	mais "coleção pra proteger" - por isso o Relicário foi removido do
	projeto por completo. O reset zera SÓ o Dinheiro; Nível, stats, Álbum e
	Mochila não resetam mais.

	Local: ServerScriptService/Server/Systems/RenascimentoService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local AltarSacrificioService = require(ServerScriptService.Server.Systems.AltarSacrificioService)
local RenascimentoCatalog = require(ReplicatedStorage.Shared.Data.RenascimentoCatalog)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local RenascimentoService = {}

local EconomyService = nil -- carregado em Init() pra evitar circular require

-- Retorna o status completo da Prova atual (pra UI mostrar progresso).
-- Requisitos de sacrifício (clã/criatura específica) vêm do
-- AltarSacrificioService (cumprido = já staged o suficiente); o requisito
-- de Dinheiro é só um check de saldo atual, não passa pelo Altar.
function RenascimentoService.GetProvaStatus(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local prova = RenascimentoCatalog.GetRequirements(data.renascimentoLevel)
	local altarStatus = AltarSacrificioService.GetAltarStatus(player)
	local statuses = {}
	local allMet = true

	for _, req in prova do
		local met, current, needed

		if req.type == "money" then
			met = data.money >= req.amount
			current = data.money
			needed = req.amount
		else
			-- sacrificeSpecificCreature / sacrificeCardsByClan: cumprido
			-- conforme o que já está staged no Altar (não posse simples).
			local altarReq = nil
			if altarStatus then
				for _, s in altarStatus.requirements do
					if s.requirement == req then
						altarReq = s
						break
					end
				end
			end
			met = altarReq ~= nil and altarReq.satisfied
			current = altarReq and altarReq.staged or 0
			needed = req.count or 1
		end

		table.insert(statuses, { requirement = req, met = met, current = current, needed = needed })
		if not met then
			allMet = false
		end
	end

	return {
		renascimentoLevel = data.renascimentoLevel,
		canRenascer = allMet,
		requirements = statuses,
	}
end

-- Monta o preview mostrado no popup de confirmação (Fase 5/UI): o que vai
-- ser sacrificado do Altar + o bônus permanente que será ganho. Não altera
-- nada - só leitura.
function RenascimentoService.GetConfirmationPreview(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local altarStatus = AltarSacrificioService.GetAltarStatus(player)
	local newRenascimentoLevel = data.renascimentoLevel + 1

	return {
		staged = altarStatus and altarStatus.staged or {},
		newRenascimentoMultiplier = 1.0 + newRenascimentoLevel * 0.1,
		startingMoney = 1000 * newRenascimentoLevel,
	}
end

-- Tenta renascer: reconfirma tudo no servidor (staging do Altar pros
-- requisitos de sacrifício + saldo mínimo de Dinheiro), e só então executa
-- o reset. Tudo ou nada.
function RenascimentoService.TryRenascer(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local status = RenascimentoService.GetProvaStatus(player)
	if not status or not status.canRenascer then
		return false, "Prova do Renascimento ainda não cumprida (confira o Altar de Sacrifício e seu saldo)"
	end

	-- Consome de verdade o que está staged no Altar (sem pagamento em $).
	AltarSacrificioService.ConsumeStagedForProva(player)

	local newRenascimentoLevel = data.renascimentoLevel + 1
	local startingMoney = 1000 * newRenascimentoLevel

	-- Reset: SÓ o dinheiro. Nível, stats, Álbum e Mochila persistem de
	-- propósito (ver cabeçalho do arquivo).
	data.money = 0

	data.renascimentoLevel = newRenascimentoLevel
	data.renascimentoMultiplier = 1.0 + newRenascimentoLevel * 0.1

	if not EconomyService then
		EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
	end
	EconomyService.RecalculateIncomePerSecond(player)
	EconomyService.AddMoney(player, startingMoney)

	Remotes.RenascimentoResult:FireClient(player, true, {
		newRenascimentoLevel = newRenascimentoLevel,
		newMultiplier = data.renascimentoMultiplier,
		startingMoney = startingMoney,
	})

	return true, newRenascimentoLevel
end

function RenascimentoService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.RenascerRequest.OnServerEvent:Connect(function(player: Player)
		local success, resultOrError = RenascimentoService.TryRenascer(player)
		if not success then
			Remotes.RenascimentoResult:FireClient(player, false, resultOrError)
		end
	end)

	Remotes.ProvaStatusRequest.OnServerEvent:Connect(function(player: Player)
		local status = RenascimentoService.GetProvaStatus(player)
		Remotes.ProvaStatusUpdated:FireClient(player, status)
	end)
end

return RenascimentoService
