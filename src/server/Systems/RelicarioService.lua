--[[
	RelicarioService.lua
	O Relicário: até `relicarioSlots` cartas podem ser guardadas aqui,
	protegidas de um Renascimento (que zera o resto da coleção). Cartas no
	Relicário saem do inventário normal (data.cards) - se ela estiver
	colocada na base, é removida de lá primeiro.

	Local: ServerScriptService/Server/Systems/RelicarioService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local RelicarioService = {}

local EconomyService = nil -- carregado em Init() pra evitar circular require

local function countRelicario(data): number
	local count = 0
	for _ in data.relicario do
		count += 1
	end
	return count
end

-- Move uma carta da Mochila pro Relicário.
function RelicarioService.MoveToRelicario(player: Player, cardId: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local card = data.cards[cardId]
	if not card then
		return false, "Carta não encontrada"
	end

	if countRelicario(data) >= data.relicarioSlots then
		return false, "Relicário cheio"
	end

	local wasPlaced = card.placed
	if wasPlaced then
		InventoryService.UnplaceCard(player, card.slotId)
	end

	data.relicario[cardId] = {
		creatureId = card.creatureId,
		rarity = card.rarity,
		grade = card.grade,
	}
	data.cards[cardId] = nil

	if wasPlaced then
		EconomyService.RecalculateIncomePerSecond(player)
	end

	return true
end

-- Move uma carta do Relicário de volta pra Mochila.
function RelicarioService.MoveFromRelicario(player: Player, cardId: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local relicCard = data.relicario[cardId]
	if not relicCard then
		return false, "Carta não está no Relicário"
	end

	if not InventoryService.HasSpace(player, 1) then
		return false, "Mochila cheia - libere espaço antes de retirar do Relicário"
	end

	data.cards[cardId] = {
		creatureId = relicCard.creatureId,
		rarity = relicCard.rarity,
		grade = relicCard.grade,
		placed = false,
		slotId = nil,
	}
	data.relicario[cardId] = nil

	return true
end

function RelicarioService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.MoveToRelicarioRequest.OnServerEvent:Connect(function(player: Player, cardId: number)
		local success, errorReason = RelicarioService.MoveToRelicario(player, cardId)
		Remotes.RelicarioResult:FireClient(player, success, errorReason)
	end)

	Remotes.MoveFromRelicarioRequest.OnServerEvent:Connect(function(player: Player, cardId: number)
		local success, errorReason = RelicarioService.MoveFromRelicario(player, cardId)
		Remotes.RelicarioResult:FireClient(player, success, errorReason)
	end)
end

return RelicarioService
