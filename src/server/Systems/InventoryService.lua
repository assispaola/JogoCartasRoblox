--[[
	InventoryService.lua
	Gerencia a Mochila (1 registro por criatura DESCOBERTA, não mais por
	cópia física) e os Slots de Base (colocar/remover criaturas pra gerar
	$/s). Raridade/grau de cada criatura vivem no Álbum (AlbumService.lua) -
	este módulo só cuida de "o que está na Mochila" e "o que está equipado".

	Local: ServerScriptService/Server/Systems/InventoryService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local AlbumService = require(ServerScriptService.Server.Systems.AlbumService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InventoryService = {}

-- Teto dos Slots de Base vive em `data.maxPlacedSlots` (default 20, ver
-- PlayerDataService.createDefaultData), expansível via gamepass
-- "slotsExtras" (GamepassService.applyPermanentEffects) - independente de
-- nível/Renascimento.

local EconomyService = nil -- carregado dentro de Init() pra evitar circular require

-- Quantas criaturas distintas o jogador tem descobertas (Mochila).
function InventoryService.GetDiscoveredCount(player: Player): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end

	local count = 0
	for _ in data.mochila do
		count += 1
	end
	return count
end

function InventoryService.HasSpace(player: Player, amount: number?): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	local amountToAdd = amount or 1
	return InventoryService.GetDiscoveredCount(player) + amountToAdd <= data.maxCards
end

function InventoryService.GetMochilaEntry(player: Player, creatureId: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end
	return data.mochila[creatureId]
end

-- Busca genérica: retorna os creatureIds da Mochila que satisfazem
-- `filterFn(albumEntry, creatureId)`. Substitui o antigo
-- InventoryService.FindUnplacedCards (que operava por cardId/cópia) -
-- usado pelos requisitos de Desafio de Nível/Renascimento.
function InventoryService.FindDiscoveredCreatures(
	player: Player,
	filterFn: (AlbumService.AlbumEntrada, number) -> boolean
): { number }
	local data = PlayerDataService.GetData(player)
	if not data then
		return {}
	end

	local matches = {}
	for creatureId in data.mochila do
		local entry = AlbumService.GetEntrada(player, creatureId)
		if entry and filterFn(entry, creatureId) then
			table.insert(matches, creatureId)
		end
	end
	return matches
end

-- Coloca uma criatura (por creatureId) num Slot de Base.
function InventoryService.PlaceCard(player: Player, creatureId: number): (boolean, string | number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local mochilaEntry = data.mochila[creatureId]
	if not mochilaEntry then
		return false, "Criatura não descoberta"
	end
	if mochilaEntry.noSlot then
		return false, "Criatura já está colocada na base"
	end

	local usedSlots = 0
	for _ in data.placedSlots do
		usedSlots += 1
	end
	if usedSlots >= data.maxPlacedSlots then
		return false, "Todos os slots da base estão ocupados"
	end

	local slotId = 1
	while data.placedSlots[slotId] do
		slotId += 1
	end

	mochilaEntry.noSlot = true
	data.placedSlots[slotId] = creatureId

	return true, slotId
end

function InventoryService.UnplaceCard(player: Player, slotId: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	local creatureId = data.placedSlots[slotId]
	if not creatureId then
		return false
	end

	local mochilaEntry = data.mochila[creatureId]
	if mochilaEntry then
		mochilaEntry.noSlot = false
	end
	data.placedSlots[slotId] = nil

	return true
end

-- "Equipar Melhor": reorganiza a base automaticamente, colocando as N
-- criaturas de maior valor (raridade + grau, lidos do Álbum) nos slots
-- disponíveis, substituindo o que estava lá antes.
function InventoryService.EquipBest(player: Player): (boolean, number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, 0
	end

	if not EconomyService then
		EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
	end

	local scored = {}
	for creatureId in data.mochila do
		local entry = AlbumService.GetEntrada(player, creatureId)
		if entry then
			local value = EconomyService.GetCardValue({
				creatureId = creatureId,
				rarity = entry.raridade,
				grade = entry.grau,
			})
			table.insert(scored, { creatureId = creatureId, value = value })
		end
	end
	table.sort(scored, function(a, b)
		return a.value > b.value
	end)

	-- Esvazia a base inteira antes de realocar - mais simples e garante o
	-- resultado ótimo, sem depender do estado anterior.
	for _, creatureId in data.placedSlots do
		local mochilaEntry = data.mochila[creatureId]
		if mochilaEntry then
			mochilaEntry.noSlot = false
		end
	end
	data.placedSlots = {}

	local placedCount = 0
	for _, entryScore in scored do
		if placedCount >= data.maxPlacedSlots then
			break
		end

		local mochilaEntry = data.mochila[entryScore.creatureId]
		placedCount += 1
		mochilaEntry.noSlot = true
		data.placedSlots[placedCount] = entryScore.creatureId
	end

	EconomyService.RecalculateIncomePerSecond(player)

	return true, placedCount
end

-- Liga os listeners dos RemoteEvents de colocação/remoção.
function InventoryService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.PlaceCreatureRequest.OnServerEvent:Connect(function(player: Player, creatureId: number)
		local success, errorOrSlot = InventoryService.PlaceCard(player, creatureId)

		if success then
			EconomyService.RecalculateIncomePerSecond(player)
			Remotes.PlacementResult:FireClient(player, true, { slotId = errorOrSlot, creatureId = creatureId })
		else
			Remotes.PlacementResult:FireClient(player, false, errorOrSlot)
		end
	end)

	Remotes.UnplaceCreatureRequest.OnServerEvent:Connect(function(player: Player, slotId: number)
		local success = InventoryService.UnplaceCard(player, slotId)

		if success then
			EconomyService.RecalculateIncomePerSecond(player)
			Remotes.PlacementResult:FireClient(player, true, { slotId = slotId, unplaced = true })
		else
			Remotes.PlacementResult:FireClient(player, false, "Slot inválido ou vazio")
		end
	end)

	Remotes.EquipBestRequest.OnServerEvent:Connect(function(player: Player)
		local success, count = InventoryService.EquipBest(player)
		Remotes.EquipBestResult:FireClient(player, success, count)
	end)
end

return InventoryService
