--[[
	JourneyChestService.lua
	Baús da Jornada: marcos de tempo jogado (contagem em tempo real desde o
	início do ciclo, não pausa se o jogador ficar offline). O ciclo inteiro
	reseta periodicamente, liberando todos os baús de novo.

	Local: ServerScriptService/Server/Systems/JourneyChestService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local PackService = require(ServerScriptService.Server.Systems.PackService)
local PackCatalog = require(ReplicatedStorage.Shared.Data.PackCatalog)
local JourneyChestCatalog = require(ReplicatedStorage.Shared.Data.JourneyChestCatalog)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local JourneyChestService = {}

local EconomyService = nil -- carregado em Init() pra evitar circular require

local function refreshCycleIfNeeded(data)
	local now = os.time()
	if data.journeyChests.cycleStart == 0 then
		data.journeyChests.cycleStart = now
		return
	end

	if (now - data.journeyChests.cycleStart) >= JourneyChestCatalog.CycleDurationSeconds then
		data.journeyChests.cycleStart = now
		data.journeyChests.claimed = {}
	end
end

-- Retorna o status de todos os baús: disponível, já resgatado, ou ainda
-- travado (com quanto tempo falta).
function JourneyChestService.GetStatus(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	refreshCycleIfNeeded(data)

	local elapsed = os.time() - data.journeyChests.cycleStart
	local chestStatuses = {}

	for _, chest in JourneyChestCatalog.Chests do
		local claimed = data.journeyChests.claimed[chest.index] == true
		local unlocked = elapsed >= chest.thresholdSeconds

		table.insert(chestStatuses, {
			index = chest.index,
			label = chest.label,
			claimed = claimed,
			unlocked = unlocked,
			secondsUntilUnlock = unlocked and 0 or (chest.thresholdSeconds - elapsed),
		})
	end

	return {
		chests = chestStatuses,
		secondsUntilCycleReset = JourneyChestCatalog.CycleDurationSeconds - elapsed,
	}
end

function JourneyChestService.TryClaim(player: Player, chestIndex: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	refreshCycleIfNeeded(data)

	local chest = JourneyChestCatalog.Chests[chestIndex]
	if not chest then
		return false, "Baú inválido"
	end

	if data.journeyChests.claimed[chestIndex] then
		return false, "Baú já resgatado nesse ciclo"
	end

	local elapsed = os.time() - data.journeyChests.cycleStart
	if elapsed < chest.thresholdSeconds then
		return false, "Ainda não jogou tempo suficiente pra esse baú"
	end

	data.journeyChests.claimed[chestIndex] = true

	local resultDetails = { chestIndex = chestIndex, label = chest.label, type = chest.type }

	if chest.type == "money" then
		local amount = math.max(chest.minAmount or 0, data.totalIncomePerSecond * chest.incomeSeconds)
		EconomyService.AddMoney(player, amount)
		resultDetails.amount = amount

		-- Alguns baús (como o final) também dão Diamante extra além do dinheiro
		if chest.amount then
			EconomyService.AddDiamonds(player, chest.amount)
			resultDetails.bonusDiamonds = chest.amount
		end
	elseif chest.type == "diamonds" then
		EconomyService.AddDiamonds(player, chest.amount)
		resultDetails.amount = chest.amount
	elseif chest.type == "freePack" then
		if InventoryService.HasSpace(player, 1) then
			-- Sortear entre packs Geral (Ladder) conforme o baú
			local packKey = "Novato" -- padrão

			local candidates = {}
			for key, pack in PackCatalog do
				if pack.Category == "Geral" then
					table.insert(candidates, pack.Key)
				end
			end

			if #candidates > 0 then
				packKey = candidates[math.random(1, #candidates)]
			end

			resultDetails.packResult = PackService.GrantFreePack(player, packKey)
		end
	end

	return true, resultDetails
end

function JourneyChestService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.ClaimJourneyChestRequest.OnServerEvent:Connect(function(player: Player, chestIndex: number)
		local success, resultOrError = JourneyChestService.TryClaim(player, chestIndex)
		Remotes.JourneyChestResult:FireClient(player, success, resultOrError)
	end)

	Remotes.JourneyChestStatusRequest.OnServerEvent:Connect(function(player: Player)
		local status = JourneyChestService.GetStatus(player)
		Remotes.JourneyChestStatusUpdated:FireClient(player, status)
	end)
end

return JourneyChestService
