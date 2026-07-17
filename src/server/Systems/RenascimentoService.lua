--[[
	RenascimentoService.lua
	Checa a Prova do Renascimento atual e processa o reset quando o
	jogador confirma: zera dinheiro e coleção (exceto o que está no
	Relicário), reseta nível e contadores, mas concede um multiplicador
	permanente de $/s e, a cada 2 ciclos, +1 slot de Relicário.

	Local: ServerScriptService/Server/Systems/RenascimentoService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local LevelService = require(ServerScriptService.Server.Systems.LevelService)
local RenascimentoCatalog = require(ReplicatedStorage.Shared.Data.RenascimentoCatalog)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local RenascimentoService = {}

local EconomyService = nil -- carregado em Init() pra evitar circular require

-- Retorna o status completo da Prova atual (pra UI mostrar progresso),
-- reaproveitando o mesmo checador de requisitos do Nível.
function RenascimentoService.GetProvaStatus(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local prova = RenascimentoCatalog.GetRequirements(data.renascimentoLevel)
	local statuses = {}
	local allMet = true

	for _, req in prova do
		local met, current, needed = LevelService.CheckRequirement(player, req)
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

-- Tenta renascer: reconfirma tudo no servidor, consome os sacrifícios da
-- Prova, e só então executa o reset. Tudo ou nada.
function RenascimentoService.TryRenascer(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local prova = RenascimentoCatalog.GetRequirements(data.renascimentoLevel)

	for _, req in prova do
		local met = LevelService.CheckRequirement(player, req)
		if not met then
			return false, "Prova do Renascimento ainda não cumprida"
		end
	end

	-- Consome os sacrifícios da Prova (mesmo padrão do LevelService.TryLevelUp)
	for _, req in prova do
		if req.type == "sacrificeSpecificCreature" then
			local matches = InventoryService.FindUnplacedCards(player, function(c)
				return c.creatureId == req.creatureId
			end)
			InventoryService.RemoveCard(player, matches[1])
		end
		-- (esse catálogo específico não usa sacrificeMoney/sacrificeCardsByRarity/
		-- sacrificeCardsByClan, mas dá pra estender aqui do mesmo jeito se um
		-- ciclo futuro precisar.)
	end

	local newRenascimentoLevel = data.renascimentoLevel + 1

	-- Recompensas do ciclo
	local gotExtraSlot = (newRenascimentoLevel % 2 == 0)
	local startingMoney = 1000 * newRenascimentoLevel

	-- Reset: dinheiro e coleção (Relicário fica intacto - nem é tocado aqui)
	data.money = 0
	data.cards = {}
	data.placedSlots = {}
	data.level = 1
	data.stats = {
		packsOpened = 0,
		discoveries = 0,
		fusions = 0,
		awakensImproved = 0,
	}

	-- O que NÃO reseta: diamonds, discovered (Índice), maxCards, autoSell,
	-- handSlots, relicario - tudo isso é progresso permanente de propósito.

	data.renascimentoLevel = newRenascimentoLevel
	data.renascimentoMultiplier = 1.0 + newRenascimentoLevel * 0.1

	if gotExtraSlot then
		data.relicarioSlots += 1
	end

	EconomyService.RecalculateIncomePerSecond(player) -- vai dar 0, já que a base ficou vazia
	EconomyService.AddMoney(player, startingMoney) -- credita o dinheiro inicial e já avisa o cliente

	Remotes.RenascimentoResult:FireClient(player, true, {
		newRenascimentoLevel = newRenascimentoLevel,
		newMultiplier = data.renascimentoMultiplier,
		gotExtraRelicarioSlot = gotExtraSlot,
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
