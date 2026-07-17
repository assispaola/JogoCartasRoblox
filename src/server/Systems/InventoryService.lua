--[[
	InventoryService.lua
	Gerencia as cartas individuais do jogador (cada uma com ID, criatura,
	raridade e grau de Despertar próprios), coloca/remove da base, e
	credita Diamante na primeira descoberta de cada criatura+raridade.

	Local: ServerScriptService/Server/Systems/InventoryService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatsService = require(ServerScriptService.Server.Systems.StatsService)
local PortalService = require(ServerScriptService.Server.Systems.PortalService)

local InventoryService = {}

local MAX_PLACED_SLOTS = 20

local EconomyService = nil -- carregado dentro de Init() pra evitar circular require

local function discoveryKey(creatureId: number, rarity: string): string
	return tostring(creatureId) .. "_" .. rarity
end

-- Credita Diamante se essa for a primeira vez que o jogador descobre essa
-- combinação criatura+raridade. Retorna a quantidade ganha (0 se já tinha
-- descoberto antes). Pública porque a Venda Automática também precisa
-- chamar isso (o Índice registra a descoberta mesmo quando a carta é
-- vendida sozinha, sem nunca entrar na Mochila).
function InventoryService.GrantDiscoveryIfNew(player: Player, creatureId: number, rarity: string): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end

	local key = discoveryKey(creatureId, rarity)
	if data.discovered[key] then
		return 0 -- já descoberto antes, sem recompensa de novo
	end

	data.discovered[key] = true
	local reward = Rarities.DiscoveryDiamondReward[rarity] or 0

	-- Portal da Sorte: Chuva de Diamantes dobra o ganho de Diamante do Índice.
	if PortalService.IsDiamondBoost() then
		reward *= 2
	end

	data.diamonds += reward

	if reward > 0 then
		Remotes.DiamondsUpdated:FireClient(player, data.diamonds)
		StatsService.Increment(player, "discoveries", 1)
	end

	return reward
end

-- Cria uma nova carta individual no inventário do jogador. Usado tanto por
-- pacotes (grau inicial = base) quanto por fusão (grau inicial = base,
-- mesmo que as consumidas tivessem grau mais alto - ver FusionService).
-- Retorna o cardId da nova carta.
function InventoryService.AddCard(player: Player, creatureId: number, rarity: string, grade: number?)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	if not Creatures[creatureId] or not Rarities.ById[rarity] then
		warn("[InventoryService] Criatura ou raridade inválida: " .. tostring(creatureId) .. " / " .. tostring(rarity))
		return nil
	end

	local cardId = PlayerDataService.GenerateCardId(player)
	data.cards[cardId] = {
		creatureId = creatureId,
		rarity = rarity,
		grade = grade or Rarities.BaseAwakenGrade,
		placed = false,
		slotId = nil,
	}

	InventoryService.GrantDiscoveryIfNew(player, creatureId, rarity)

	return cardId
end

-- Quantas cartas o jogador tem no total (Mochila), e se ainda cabe mais.
function InventoryService.GetCardCount(player: Player): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end

	local count = 0
	for _ in data.cards do
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
	return InventoryService.GetCardCount(player) + amountToAdd <= data.maxCards
end

-- Remove uma carta específica (usado ao vender, fundir, ou perder no
-- Renascimento). Retorna true se a carta existia e foi removida.
function InventoryService.RemoveCard(player: Player, cardId: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data or not data.cards[cardId] then
		return false
	end

	local card = data.cards[cardId]
	if card.placed and card.slotId then
		data.placedSlots[card.slotId] = nil
	end

	data.cards[cardId] = nil
	return true
end

function InventoryService.GetCard(player: Player, cardId: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end
	return data.cards[cardId]
end

-- Lista os IDs de todas as cópias (não colocadas na base) de uma
-- criatura+raridade específica. Útil pra fusão (escolher quais consumir) e
-- pra UI mostrar duplicatas agrupadas.
function InventoryService.GetUnplacedCopies(player: Player, creatureId: number, rarity: string): { number }
	local data = PlayerDataService.GetData(player)
	if not data then
		return {}
	end

	local copies = {}
	for cardId, card in data.cards do
		if card.creatureId == creatureId and card.rarity == rarity and not card.placed then
			table.insert(copies, cardId)
		end
	end

	-- Ordena da MENOR nota de Despertar pra maior. Isso importa pra fusão:
	-- quando o jogador funde duplicatas, queremos consumir por padrão as
	-- cópias de grau mais baixo primeiro, preservando as cópias que ele já
	-- investiu Diamante pra melhorar.
	table.sort(copies, function(a, b)
		return data.cards[a].grade < data.cards[b].grade
	end)

	return copies
end

function InventoryService.GetUnplacedCount(player: Player, creatureId: number, rarity: string): number
	return #InventoryService.GetUnplacedCopies(player, creatureId, rarity)
end

-- Busca genérica: retorna os cardIds de todas as cartas NÃO colocadas na
-- base que satisfazem `filterFn(card)`, ordenadas do menor grau pro maior
-- (mesma lógica de "sacrificar as mais fracas primeiro" usada na fusão).
-- Usado pelos requisitos de sacrifício do Desafio de Nível/Renascimento.
function InventoryService.FindUnplacedCards(player: Player, filterFn: (any) -> boolean): { number }
	local data = PlayerDataService.GetData(player)
	if not data then
		return {}
	end

	local matches = {}
	for cardId, card in data.cards do
		if not card.placed and filterFn(card) then
			table.insert(matches, cardId)
		end
	end

	table.sort(matches, function(a, b)
		return data.cards[a].grade < data.cards[b].grade
	end)

	return matches
end

-- Coloca uma carta específica (por cardId) na base.
function InventoryService.PlaceCard(player: Player, cardId: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local card = data.cards[cardId]
	if not card then
		return false, "Carta não encontrada"
	end
	if card.placed then
		return false, "Carta já está colocada na base"
	end

	local usedSlots = 0
	for _ in data.placedSlots do
		usedSlots += 1
	end
	if usedSlots >= MAX_PLACED_SLOTS then
		return false, "Todos os slots da base estão ocupados"
	end

	-- Acha o primeiro número de slot livre (1, 2, 3, ... sem buracos óbvios)
	local slotId = 1
	while data.placedSlots[slotId] do
		slotId += 1
	end

	card.placed = true
	card.slotId = slotId
	data.placedSlots[slotId] = cardId

	return true, slotId
end

function InventoryService.UnplaceCard(player: Player, slotId: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	local cardId = data.placedSlots[slotId]
	if not cardId then
		return false
	end

	local card = data.cards[cardId]
	if card then
		card.placed = false
		card.slotId = nil
	end
	data.placedSlots[slotId] = nil

	return true
end

-- "Equipar Melhor": reorganiza a base automaticamente, colocando as N
-- cartas de maior valor (considerando raridade + grau de Despertar) nos
-- slots disponíveis, substituindo o que estava lá antes.
function InventoryService.EquipBest(player: Player): (boolean, number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, 0
	end

	-- EconomyService é resolvido pela variável de módulo já carregada em
	-- Init() (mesmo padrão usado no resto do arquivo).
	if not EconomyService then
		EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
	end

	-- Pontua TODAS as cartas do jogador (coloca na base ou não) pelo valor.
	local scored = {}
	for cardId, card in data.cards do
		table.insert(scored, { cardId = cardId, value = EconomyService.GetCardValue(card) })
	end
	table.sort(scored, function(a, b)
		return a.value > b.value
	end)

	-- Esvazia a base inteira antes de realocar - mais simples e garante que
	-- o resultado final é sempre o ótimo, sem depender do estado anterior.
	for _, cardId in data.placedSlots do
		local card = data.cards[cardId]
		if card then
			card.placed = false
			card.slotId = nil
		end
	end
	data.placedSlots = {}

	local placedCount = 0
	for _, entry in scored do
		if placedCount >= MAX_PLACED_SLOTS then
			break
		end

		local card = data.cards[entry.cardId]
		placedCount += 1
		card.placed = true
		card.slotId = placedCount
		data.placedSlots[placedCount] = entry.cardId
	end

	EconomyService.RecalculateIncomePerSecond(player)

	return true, placedCount
end

-- Liga os listeners dos RemoteEvents de colocação/remoção.
function InventoryService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.PlaceCreatureRequest.OnServerEvent:Connect(function(player: Player, cardId: number)
		local success, errorOrSlot = InventoryService.PlaceCard(player, cardId)

		if success then
			EconomyService.RecalculateIncomePerSecond(player)
			Remotes.PlacementResult:FireClient(player, true, { slotId = errorOrSlot, cardId = cardId })
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
