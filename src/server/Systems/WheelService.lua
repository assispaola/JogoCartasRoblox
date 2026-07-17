--[[
	WheelService.lua
	A Roda do Destino: 1 giro grátis a cada 30 minutos + giros pagos com
	Diamante (em lote: 1, 3 ou 10 de uma vez, com bônus de sorte a partir
	de 3). Também processa giros bônus ganhos como prêmio ("+2 Giros").

	Local: ServerScriptService/Server/Systems/WheelService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local PackService = require(ServerScriptService.Server.Systems.PackService)
local PackCatalog = require(ReplicatedStorage.Shared.Data.PackCatalog)
local WheelCatalog = require(ReplicatedStorage.Shared.Data.WheelCatalog)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local WheelService = {}

local FREE_SPIN_INTERVAL_SECONDS = 30 * 60 -- 30 minutos
local PAID_SPIN_COST_DIAMONDS = 10
local LUCK_BOOST_MIN_QUANTITY = 3 -- giros pagos em lote de 3+ ganham bônus de sorte

local EconomyService = nil -- carregado em Init() pra evitar circular require

local function refreshFreeSpinIfNeeded(data)
	local now = os.time()
	if data.wheel.cycleStart == 0 or (now - data.wheel.cycleStart) >= FREE_SPIN_INTERVAL_SECONDS then
		data.wheel.cycleStart = now
		data.wheel.freeSpinUsed = false
	end
end

local function pickRandomPackOfTierAndClan(tierName: string, clanName: string?): string?
	local candidates = {}
	for _, packId in PackCatalog.Order do
		local pack = PackCatalog.Packs[packId]
		if pack.tier == tierName and (not clanName or pack.clan == clanName) then
			table.insert(candidates, packId)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(1, #candidates)]
end

-- Aplica um único prêmio já sorteado aos dados do jogador.
local function applyPrize(player: Player, prize)
	local resultDetails = { prizeId = prize.id, label = prize.label, type = prize.type }
	local data = PlayerDataService.GetData(player)

	if prize.type == "money" then
		local amount = math.max(prize.minAmount or 0, data.totalIncomePerSecond * prize.incomeSeconds)
		EconomyService.AddMoney(player, amount)
		resultDetails.amount = amount
	elseif prize.type == "diamonds" then
		EconomyService.AddDiamonds(player, prize.amount)
		resultDetails.amount = prize.amount
	elseif prize.type == "bonusSpins" then
		data.wheel.bonusSpins += prize.amount
		resultDetails.amount = prize.amount
	elseif prize.type == "freePack" then
		local packId = pickRandomPackOfTierAndClan(prize.packTier, prize.packClan)
		if packId then
			resultDetails.packResult = PackService.GrantFreePack(player, packId)
		end
	elseif prize.type == "exclusiveCard" then
		-- Concede uma criatura aleatória direto na raridade definida pelo
		-- prêmio, ignorando o sorteio normal de raridade - é o "grande
		-- prêmio" da roleta.
		local ids = {}
		for id in Creatures do
			table.insert(ids, id)
		end
		local creatureId = ids[math.random(1, #ids)]

		if InventoryService.HasSpace(player, 1) then
			local cardId = InventoryService.AddCard(player, creatureId, prize.exclusiveRarity)
			resultDetails.cardId = cardId
			resultDetails.creatureName = Creatures[creatureId].name
			resultDetails.rarity = prize.exclusiveRarity
		else
			resultDetails.blockedByFullMochila = true
		end
	end

	return resultDetails
end

function WheelService.GetStatus(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	refreshFreeSpinIfNeeded(data)

	local secondsUntilFreeSpin = 0
	if data.wheel.freeSpinUsed then
		secondsUntilFreeSpin = math.max(0, FREE_SPIN_INTERVAL_SECONDS - (os.time() - data.wheel.cycleStart))
	end

	return {
		freeSpinAvailable = not data.wheel.freeSpinUsed,
		bonusSpinsAvailable = data.wheel.bonusSpins,
		secondsUntilFreeSpin = secondsUntilFreeSpin,
		paidSpinCost = PAID_SPIN_COST_DIAMONDS,
	}
end

-- Gira `quantity` vezes. `usePaid` decide se consome Diamante (true) ou
-- tenta usar giro grátis/bônus primeiro (false). Giros em lote de 3+ pagos
-- ganham bônus de sorte automaticamente.
function WheelService.TrySpin(player: Player, quantity: number, usePaid: boolean)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	refreshFreeSpinIfNeeded(data)
	quantity = math.max(1, quantity)

	if usePaid then
		local totalCost = PAID_SPIN_COST_DIAMONDS * quantity
		local spent = EconomyService.TrySpendDiamonds(player, totalCost)
		if not spent then
			return false, "Diamante insuficiente (precisa de " .. totalCost .. ")"
		end
	else
		-- Giro grátis/bônus só permite 1 de cada vez - lote é exclusivo
		-- de giro pago.
		if quantity ~= 1 then
			return false, "Giro grátis/bônus só pode ser usado 1 por vez"
		end

		if data.wheel.bonusSpins > 0 then
			data.wheel.bonusSpins -= 1
		elseif not data.wheel.freeSpinUsed then
			data.wheel.freeSpinUsed = true
		else
			return false, "Nenhum giro grátis ou bônus disponível agora"
		end
	end

	local luckBoost = usePaid and quantity >= LUCK_BOOST_MIN_QUANTITY

	local results = {}
	for _ = 1, quantity do
		local prize = WheelCatalog.RollPrize(luckBoost)
		table.insert(results, applyPrize(player, prize))
	end

	return true, results
end

function WheelService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.SpinWheelRequest.OnServerEvent:Connect(function(player: Player, quantity: number, usePaid: boolean)
		local success, resultOrError = WheelService.TrySpin(player, quantity, usePaid)
		Remotes.SpinWheelResult:FireClient(player, success, resultOrError)
	end)

	Remotes.WheelStatusRequest.OnServerEvent:Connect(function(player: Player)
		local status = WheelService.GetStatus(player)
		Remotes.WheelStatusUpdated:FireClient(player, status)
	end)
end

return WheelService
