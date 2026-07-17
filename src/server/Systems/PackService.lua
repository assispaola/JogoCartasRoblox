--[[
	PackService.lua
	Processa a compra e abertura de qualquer um dos 61 pacotes (60
	temáticos + Padrão): valida nível de desbloqueio, cobra o custo,
	sorteia raridade (pela tabela do tier) e criatura (restrita ao clã do
	pacote, ou qualquer uma no caso do Padrão), e decide se a carta entra
	na Mochila ou é vendida sozinha (Venda Automática).

	Também aplica os efeitos ativos do Portal da Sorte: Eclipse de Clã
	(desconto de 50% no custo de pacotes daquele clã) e Pacote Duplo
	(entrega 2 criaturas por pacote, mesmo custo).

	Local: ServerScriptService/Server/Systems/PackService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local AutoSellService = require(ServerScriptService.Server.Systems.AutoSellService)
local SellService = require(ServerScriptService.Server.Systems.SellService)
local StatsService = require(ServerScriptService.Server.Systems.StatsService)
local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local PortalService = require(ServerScriptService.Server.Systems.PortalService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local PackCatalog = require(ReplicatedStorage.Shared.Data.PackCatalog)

local PackService = {}

local RARITY_ORDER = { "Bronze", "Prata", "Ouro", "Platina", "Lendário", "Mítico" }

local function rollRarity(chances: { [string]: number }): string
	local roll = math.random(1, 100)
	local accumulated = 0

	for _, rarityName in RARITY_ORDER do
		accumulated += chances[rarityName] or 0
		if roll <= accumulated then
			return rarityName
		end
	end

	return RARITY_ORDER[1]
end

local function rollCreature(clan: string?): number
	if not clan then
		local ids = {}
		for id in Creatures do
			table.insert(ids, id)
		end
		return ids[math.random(1, #ids)]
	end

	local clanIds = PackCatalog.CreatureIdsByClan[clan]
	return clanIds[math.random(1, #clanIds)]
end

-- Lógica compartilhada entre pacote pago e pacote grátis: sorteia o
-- resultado e decide se vai pra Mochila ou é vendido sozinho.
local function processPackOutcome(player: Player, packInfo)
	StatsService.Increment(player, "packsOpened", 1)

	local rarity = rollRarity(packInfo.rarityChances)
	local creatureId = rollCreature(packInfo.clan)
	local creature = Creatures[creatureId]

	if AutoSellService.ShouldAutoSell(player, creature.clan, rarity) then
		InventoryService.GrantDiscoveryIfNew(player, creatureId, rarity)

		local hypotheticalCard = { creatureId = creatureId, rarity = rarity, grade = Rarities.BaseAwakenGrade }
		local price = SellService.GetSellPrice(hypotheticalCard)
		EconomyService.AddMoney(player, price)

		return {
			cardId = nil,
			creatureId = creatureId,
			creatureName = creature.name,
			clan = creature.clan,
			rarity = rarity,
			autoSold = true,
			autoSoldPrice = price,
		}
	end

	local cardId = InventoryService.AddCard(player, creatureId, rarity)

	return {
		cardId = cardId,
		creatureId = creatureId,
		creatureName = creature.name,
		clan = creature.clan,
		rarity = rarity,
		autoSold = false,
	}
end

-- Calcula o custo efetivo do pacote, considerando o desconto do Eclipse
-- de Clã (se estiver ativo pro clã desse pacote específico).
local function getEffectiveCost(packInfo): number
	if packInfo.clan and PortalService.IsEclipseClan(packInfo.clan) then
		return math.floor(packInfo.cost * PortalService.GetEclipsePackCostMultiplier())
	end
	return packInfo.cost
end

-- Processa a compra e abertura de um pacote PAGO. Retorna os dados do
-- resultado se der certo (incluindo `bonusCard` se o Pacote Duplo do
-- Portal da Sorte estiver ativo), ou nil + motivo do erro.
function PackService.OpenPack(player: Player, packId: string)
	local packInfo = PackCatalog.Packs[packId]
	if not packInfo then
		return nil, "Pacote inválido"
	end

	local data = PlayerDataService.GetData(player)
	if not data then
		return nil, "Dados não carregados"
	end

	if data.level < packInfo.unlockLevel then
		return nil, "Pacote bloqueado - alcance o nível " .. packInfo.unlockLevel .. " pra desbloquear"
	end

	if not InventoryService.HasSpace(player, 1) then
		return nil, "Mochila cheia! Libere espaço, venda cartas, ou ative Venda Automática pra mais categorias."
	end

	local effectiveCost = getEffectiveCost(packInfo)
	local spent = EconomyService.TrySpendMoney(player, effectiveCost)
	if not spent then
		return nil, "Dinheiro insuficiente"
	end

	local result = processPackOutcome(player, packInfo)

	-- Portal da Sorte: Pacote Duplo entrega uma segunda criatura, mesmo
	-- custo já pago. Só tenta se ainda houver espaço na Mochila.
	if PortalService.IsDoublePack() and InventoryService.HasSpace(player, 1) then
		result.bonusCard = processPackOutcome(player, packInfo)
	end

	return result
end

-- Concede um pacote GRÁTIS (usado por recompensas: Roda do Destino, Baús
-- da Jornada, Bênção Diária, etc.) - ignora custo e nível de desbloqueio,
-- mas ainda respeita a capacidade da Mochila.
function PackService.GrantFreePack(player: Player, packId: string)
	local packInfo = PackCatalog.Packs[packId]
	if not packInfo then
		return nil, "Pacote inválido"
	end

	if not InventoryService.HasSpace(player, 1) then
		return nil, "Mochila cheia! Libere espaço antes de resgatar."
	end

	return processPackOutcome(player, packInfo)
end

-- Retorna a lista de pacotes que o jogador já desbloqueou no nível atual -
-- útil pra UI montar a loja (Fase 5).
function PackService.GetUnlockedPacks(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return {}
	end

	local unlocked = {}
	for _, packId in PackCatalog.Order do
		local pack = PackCatalog.Packs[packId]
		if data.level >= pack.unlockLevel then
			table.insert(unlocked, pack)
		end
	end
	table.insert(unlocked, PackCatalog.Packs["Padrao"])

	return unlocked
end

function PackService.Init()
	Remotes.BuyPackRequest.OnServerEvent:Connect(function(player: Player, packId: string)
		local result, errorReason = PackService.OpenPack(player, packId)

		if result then
			Remotes.PackOpened:FireClient(player, true, result)
		else
			Remotes.PackOpened:FireClient(player, false, errorReason)
		end
	end)

	Remotes.UnlockedPacksRequest.OnServerEvent:Connect(function(player: Player)
		local unlocked = PackService.GetUnlockedPacks(player)
		Remotes.UnlockedPacksUpdated:FireClient(player, unlocked)
	end)
end

return PackService
