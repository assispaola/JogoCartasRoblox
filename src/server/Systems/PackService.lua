--[[
	PackService.lua

	Orquestra a compra/abertura dos 62 pacotes do PackCatalog:
	- valida disponibilidade (limite diário/semanal, once-per-account, janela de evento...)
	- cobra a moeda certa (Coins, Diamonds ou nada, no caso de Free/Robux)
	- sorteia as cartas via PackOddsRoller
	- registra as cartas no Álbum via AlbumService.RegistrarCopia
	- processa recibos de compra com Robux via MarketplaceService.ProcessReceipt

	Consertado pra usar os serviços reais do projeto direto (mesmo padrão de
	require que o resto de src/server/Systems usa) em vez de uma camada de
	adapters genéricos - a versão anterior deste arquivo nunca chegou a ser
	ligada de verdade (Init() era chamado sem argumentos em Main.server.lua e
	`Inventory:GrantCard` não existia em lugar nenhum).

	NOTA (bug pré-existente, fora de escopo aqui): `WheelService.lua`,
	`DailyBlessingService.lua` e `JourneyChestService.lua` chamam
	`PackService.GrantFreePack(player, packId)` passando um `packId` vindo de
	um `PackCatalog.Order`/`PackCatalog.Packs[packId]` de um modelo antigo
	(tier+clã) que não existe mais neste `PackCatalog.lua` (62 pacotes,
	sorteio uniforme de clã). `GrantFreePack` abaixo já usa a Key real do
	catálogo atual - esses 3 chamadores precisam ser migrados separadamente
	pra passar uma Key válida (ver Checklist_Desenvolvimento.md).

	Local: ServerScriptService/Server/Systems/PackService.lua
]]

local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PackCatalog = require(ReplicatedStorage.Shared.Data.PackCatalog)
local PackOddsRoller = require(ReplicatedStorage.Shared.Data.PackOddsRoller)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local AlbumService = require(ServerScriptService.Server.Systems.AlbumService)

type PackDefinition = PackCatalog.PackDefinition
type RolledCard = PackOddsRoller.RolledCard

local EconomyService = nil -- carregado em Init() pra evitar circular require

local PackService = {}

local roller: PackOddsRoller.PackOddsRoller? = nil

-- Pacotes de evento ficam fechados por padrão; um EventService/painel de admin
-- deve chamar PackService.SetEventWindowOpen(key, true) quando o evento começar.
local activeEventWindows: { [string]: boolean } = {}

-- Índice reverso ProductId -> packKey, montado uma vez no Init.
local robuxProductIndex: { [number]: string } = {}

-- Índice Id -> packKey só da categoria "Geral", em ordem (1 = Novato ... 30 = Transcendente).
local generalPacksById: { [number]: string } = {}
local generalPackCount = 0

-- ============================================================================
-- CreatureProvider real sobre Creatures.lua
-- ============================================================================
-- `rarity` é recebido só por compatibilidade de assinatura - Creatures.lua
-- não amarra raridade à identidade da criatura (ver PackOddsRoller.lua). O
-- provider sorteia uniformemente entre as ~20 criaturas daquele clã.

local creaturesByClan: { [string]: { number } } = {}

local function buildCreatureIndex()
	creaturesByClan = {}
	for id, creature in Creatures do
		local list = creaturesByClan[creature.clan]
		if not list then
			list = {}
			creaturesByClan[creature.clan] = list
		end
		table.insert(list, id)
	end
end

local creatureProvider: PackOddsRoller.CreatureProvider = {
	GetRandomCreature = function(_self, clan: string, _rarity)
		local ids = creaturesByClan[clan]
		if not ids or #ids == 0 then
			error("[PackService] Nenhuma criatura cadastrada pro clã: " .. tostring(clan))
		end
		return ids[math.random(1, #ids)]
	end,
}

-- ============================================================================

function PackService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	buildCreatureIndex()
	roller = PackOddsRoller.new(creatureProvider)

	-- valida os dados do catálogo uma única vez, no boot do servidor
	for key, pack in PackCatalog do
		local ok, sum = PackOddsRoller.ValidateOdds(pack.Odds)
		if not ok then
			warn(("PackCatalog: pacote '%s' tem odds somando %.4f (esperado ~1.0)"):format(key, sum))
		end
		if pack.Category == "Robux" then
			if not pack.RobuxProductId or pack.RobuxProductId == 0 then
				warn(("PackCatalog: pacote Robux '%s' ainda usa RobuxProductId placeholder (0)"):format(key))
			else
				robuxProductIndex[pack.RobuxProductId] = key
			end
		end
		if pack.Category == "Geral" then
			generalPacksById[pack.Id] = key
			generalPackCount = math.max(generalPackCount, pack.Id)
			if not pack.UnlockLevel then
				warn(("PackCatalog: pacote Geral '%s' sem UnlockLevel definido"):format(key))
			end
		end
	end

	-- Dispatcher que combina PackService + GamepassService
	-- (ambos precisam processar recibos via MarketplaceService.ProcessReceipt)
	MarketplaceService.ProcessReceipt = function(receiptInfo: any): Enum.ProductPurchaseDecision
		-- Tenta processar como pack Robux primeiro
		if robuxProductIndex[receiptInfo.ProductId] then
			return PackService.ProcessReceipt(receiptInfo)
		end

		-- Senão, tenta processar como Dev Product (Diamante) via GamepassService
		local GamepassService = require(ServerScriptService.Server.Systems.GamepassService)
		local GamepassCatalog = require(ReplicatedStorage.Shared.Data.GamepassCatalog)

		if GamepassCatalog.DiamondByProductId[receiptInfo.ProductId] then
			-- Chama processReceipt do GamepassService internamente
			-- (precisa de acesso, então vou chamar a lógica aqui)
			local Players = game:GetService("Players")
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local data = PlayerDataService.GetData(player)
			if not data then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			if data.processedReceipts[receiptInfo.PurchaseId] then
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end

			local product = GamepassCatalog.DiamondByProductId[receiptInfo.ProductId]
			if not product then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			EconomyService.AddDiamonds(player, product.amount)
			data.processedReceipts[receiptInfo.PurchaseId] = true

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		-- ProductId desconhecido
		warn("[ProcessReceiptDispatcher] ProductId desconhecido: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	Remotes.BuyPackRequest.OnServerEvent:Connect(function(player: Player, packKey: string)
		local success, resultOrError = PackService.OpenPack(player, packKey)
		if success then
			Remotes.PackOpened:FireClient(player, true, resultOrError)
		else
			Remotes.PackOpened:FireClient(player, false, resultOrError)
		end
	end)

	Remotes.UnlockedPacksRequest.OnServerEvent:Connect(function(player: Player)
		Remotes.UnlockedPacksUpdated:FireClient(player, PackService.GetHighestUnlockedGeneralPackId(player))
	end)
end

function PackService.SetEventWindowOpen(packKey: string, isOpen: boolean)
	activeEventWindows[packKey] = isOpen
end

function PackService.GetPack(packKey: string): PackDefinition?
	return (PackCatalog :: any)[packKey]
end

-- ============================================================================
-- Desbloqueio da ladder Geral (persistente, 1 pacote por vez)
-- ============================================================================

function PackService.GetHighestUnlockedGeneralPackId(player: Player): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 1
	end
	return math.max(1, data.highestUnlockedGeneralPackId or 1)
end

function PackService.IsGeneralPackUnlocked(player: Player, packKey: string): boolean
	local pack = PackService.GetPack(packKey)
	if not pack or pack.Category ~= "Geral" then
		return true -- só a ladder Geral usa esse tipo de trava
	end
	return pack.Id <= PackService.GetHighestUnlockedGeneralPackId(player)
end

--[[
	Chame isso toda vez que o LevelService aumentar o nível do jogador. Libera
	NO MÁXIMO 1 pacote por chamada - PERSISTENTE, o RenascimentoService nunca
	deve tocar em `data.highestUnlockedGeneralPackId`.
]]
function PackService.TryUnlockNextGeneralPack(player: Player, currentLevel: number): string?
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local highest = PackService.GetHighestUnlockedGeneralPackId(player)
	local nextId = highest + 1
	if nextId > generalPackCount then
		return nil
	end

	local nextKey = generalPacksById[nextId]
	if not nextKey then
		return nil
	end

	local nextPack = PackService.GetPack(nextKey)
	if not nextPack or not nextPack.UnlockLevel then
		return nil
	end

	if currentLevel < nextPack.UnlockLevel then
		return nil
	end

	data.highestUnlockedGeneralPackId = nextId
	return nextKey
end

-- ============================================================================
-- Disponibilidade
-- ============================================================================

local SECONDS_PER_DAY = 24 * 60 * 60
local SECONDS_PER_WEEK = 7 * SECONDS_PER_DAY

local function getPackState(player: Player, packKey: string)
	local data = PlayerDataService.GetData(player)
	if not data then
		return { LastOpenedAt = nil, TimesOpened = 0 }
	end

	local state = data.packStates[packKey]
	if not state then
		return { LastOpenedAt = nil, TimesOpened = 0 }
	end
	return state
end

local function markPackOpened(player: Player, packKey: string)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	local state = data.packStates[packKey]
	if not state then
		state = { LastOpenedAt = nil, TimesOpened = 0 }
		data.packStates[packKey] = state
	end

	state.LastOpenedAt = os.time()
	state.TimesOpened += 1
end

function PackService.CanOpen(player: Player, packKey: string): (boolean, string?)
	local pack = PackService.GetPack(packKey)
	if not pack then
		return false, "Pacote inexistente: " .. packKey
	end

	if pack.Category == "Geral" and pack.UnlockLevel then
		if not PackService.IsGeneralPackUnlocked(player, packKey) then
			return false, ("Pacote bloqueado — alcance o nível %d para desbloquear."):format(pack.UnlockLevel)
		end
	end

	local availability = pack.Availability
	if availability then
		local state = getPackState(player, packKey)

		if availability.Kind == "OncePerAccount" then
			if state.TimesOpened > 0 then
				return false, "Este pacote só pode ser aberto uma vez por conta."
			end
		elseif availability.Kind == "DailyLimit" then
			if state.LastOpenedAt and (os.time() - state.LastOpenedAt) < SECONDS_PER_DAY then
				return false, "Volte amanhã para abrir este pacote de novo."
			end
		elseif availability.Kind == "WeeklyStreak" then
			if state.LastOpenedAt and (os.time() - state.LastOpenedAt) < SECONDS_PER_WEEK then
				return false, "Este pacote renova semanalmente."
			end
		elseif availability.Kind == "EventWindow" then
			if not activeEventWindows[packKey] then
				return false, "Este pacote só está disponível durante o evento."
			end
		end
		-- Milestone/ReturningPlayer/Referral: dependem de outros sistemas
		-- ainda não conectados aqui (fora de escopo desta passada) -
		-- tratados como "AlwaysAvailable" por enquanto.
	end

	if pack.Currency == "Coins" and pack.Price then
		if PlayerDataService.GetData(player).money < pack.Price then
			return false, "Moedas insuficientes."
		end
	elseif pack.Currency == "Diamonds" and pack.Price then
		if PlayerDataService.GetData(player).diamonds < pack.Price then
			return false, "Diamantes insuficientes."
		end
	end

	return true, nil
end

-- ============================================================================
-- Abertura (Coins / Diamonds / Free / Event)
-- ============================================================================

export type OpenPackResult = {
	PackKey: string,
	Cards: { RolledCard },
}

-- Registra o resultado sorteado no Álbum de cada carta. Compartilhado por
-- OpenPack/ProcessReceipt/GrantFreePack.
local function grantRolledCards(player: Player, pack: PackDefinition, cards: { RolledCard })
	local isBencaoDiaria = pack.Key == "BencaoDiaria"
	for _, card in cards do
		local canonicalRarity = PackOddsRoller.ToCanonicalRarityId(card.Rarity)
		AlbumService.RegistrarCopia(player, card.CreatureId, canonicalRarity :: any, isBencaoDiaria)
	end
end

-- Mochila cheia + descoberta nova: bloqueia ANTES de cobrar (não gasta moeda
-- nem perde a carta). UX final (o que mostrar/oferecer nesse caso) ainda
-- está pendente de decisão - ver Checklist_Desenvolvimento.md.
local function hasRoomForNewDiscoveries(player: Player, cards: { RolledCard }): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	local newDiscoveries = 0
	local seen = {}
	for _, card in cards do
		if not data.album[card.CreatureId] and not seen[card.CreatureId] then
			seen[card.CreatureId] = true
			newDiscoveries += 1
		end
	end

	local currentCount = 0
	for _ in data.mochila do
		currentCount += 1
	end

	return currentCount + newDiscoveries <= data.maxCards
end

function PackService.OpenPack(player: Player, packKey: string): (boolean, OpenPackResult | string)
	local r = assert(roller, "PackService.Init não foi chamado")

	local pack = PackService.GetPack(packKey)
	if not pack then
		return false, "Pacote inexistente: " .. packKey
	end

	if pack.Currency == "Robux" then
		return false, "Pacotes de Robux são processados via MarketplaceService.PromptProductPurchase, não OpenPack."
	end

	local canOpen, reason = PackService.CanOpen(player, packKey)
	if not canOpen then
		return false, reason or "Pacote indisponível."
	end

	local cards: { RolledCard } = r:RollCards(pack.Odds, pack.CardsPerPurchase)

	if not hasRoomForNewDiscoveries(player, cards) then
		return false, "Mochila cheia — libere espaço (venda ou expanda) antes de abrir este pacote."
	end

	-- cobra a moeda só depois de confirmar que cabe na Mochila
	if pack.Currency == "Coins" and pack.Price then
		if not EconomyService.TrySpendMoney(player, pack.Price) then
			return false, "Falha ao cobrar Moedas (saldo mudou?)."
		end
	elseif pack.Currency == "Diamonds" and pack.Price then
		if not EconomyService.TrySpendDiamonds(player, pack.Price) then
			return false, "Falha ao cobrar Diamantes (saldo mudou?)."
		end
	end
	-- Currency == "Free" ou "Event": nada a cobrar aqui.

	grantRolledCards(player, pack, cards)

	if pack.Availability then
		markPackOpened(player, packKey)
	end

	return true, { PackKey = packKey, Cards = cards }
end

-- Wrapper fino de OpenPack que ignora cobrança - usado por fontes de pacote
-- já gratuitas por contexto (Roda do Destino, Bênção Diária, Baús da
-- Jornada). Não corrige a incompatibilidade de `packId` desses 3
-- chamadores (ver nota no topo do arquivo).
function PackService.GrantFreePack(player: Player, packKey: string): (boolean, OpenPackResult | string)
	local r = assert(roller, "PackService.Init não foi chamado")

	local pack = PackService.GetPack(packKey)
	if not pack then
		return false, "Pacote inexistente: " .. packKey
	end

	local cards: { RolledCard } = r:RollCards(pack.Odds, pack.CardsPerPurchase)

	if not hasRoomForNewDiscoveries(player, cards) then
		return false, "Mochila cheia — libere espaço antes de resgatar este pacote."
	end

	grantRolledCards(player, pack, cards)

	return true, { PackKey = packKey, Cards = cards }
end

-- ============================================================================
-- Robux (MarketplaceService.ProcessReceipt)
-- ============================================================================

function PackService.ProcessReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = PlayerDataService.GetData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if data.processedReceipts[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local packKey = robuxProductIndex[receiptInfo.ProductId]
	if not packKey then
		warn("PackService.ProcessReceipt: ProductId sem pacote correspondente: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local pack = PackService.GetPack(packKey)
	if not pack then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local r = assert(roller, "PackService.Init não foi chamado")
	local cards: { RolledCard } = r:RollCards(pack.Odds, pack.CardsPerPurchase)

	local ok = pcall(function()
		grantRolledCards(player, pack, cards)
	end)

	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.processedReceipts[receiptInfo.PurchaseId] = true

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

return PackService
