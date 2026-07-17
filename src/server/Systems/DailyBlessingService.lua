--[[
	DailyBlessingService.lua
	Resgate diário com streak: disponível a cada 24h (janela rolante).
	Resgatar dentro de 48h desde o último resgate mantém/aumenta o streak;
	deixar passar mais de 48h reseta o streak pra 1.

	Local: ServerScriptService/Server/Systems/DailyBlessingService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local PackService = require(ServerScriptService.Server.Systems.PackService)
local PackCatalog = require(ReplicatedStorage.Shared.Data.PackCatalog)
local DailyBlessingCatalog = require(ReplicatedStorage.Shared.Data.DailyBlessingCatalog)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DailyBlessingService = {}

local CLAIM_AVAILABLE_AFTER_SECONDS = 24 * 60 * 60 -- pode resgatar de novo depois de 24h
local STREAK_BREAKS_AFTER_SECONDS = 48 * 60 * 60 -- passou disso sem resgatar = perde o streak

local EconomyService = nil -- carregado em Init() pra evitar circular require

function DailyBlessingService.GetStatus(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local now = os.time()
	local elapsed = now - data.dailyBlessing.lastClaimTimestamp
	local available = data.dailyBlessing.lastClaimTimestamp == 0 or elapsed >= CLAIM_AVAILABLE_AFTER_SECONDS

	local nextStreak = data.dailyBlessing.streak + 1
	if data.dailyBlessing.lastClaimTimestamp ~= 0 and elapsed > STREAK_BREAKS_AFTER_SECONDS then
		nextStreak = 1 -- se resgatasse agora, o streak reiniciaria
	end

	return {
		available = available,
		secondsUntilAvailable = available and 0 or (CLAIM_AVAILABLE_AFTER_SECONDS - elapsed),
		currentStreak = data.dailyBlessing.streak,
		nextReward = DailyBlessingCatalog.GetReward(nextStreak),
	}
end

function DailyBlessingService.TryClaim(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local now = os.time()
	local elapsed = now - data.dailyBlessing.lastClaimTimestamp

	if data.dailyBlessing.lastClaimTimestamp ~= 0 and elapsed < CLAIM_AVAILABLE_AFTER_SECONDS then
		return false, "Bênção de hoje já foi resgatada"
	end

	if data.dailyBlessing.lastClaimTimestamp == 0 or elapsed > STREAK_BREAKS_AFTER_SECONDS then
		data.dailyBlessing.streak = 1
	else
		data.dailyBlessing.streak += 1
	end
	data.dailyBlessing.lastClaimTimestamp = now

	local reward = DailyBlessingCatalog.GetReward(data.dailyBlessing.streak)
	local resultDetails = { label = reward.label, type = reward.type, streak = data.dailyBlessing.streak }

	if reward.type == "money" then
		local amount = math.max(reward.minAmount or 0, data.totalIncomePerSecond * reward.incomeSeconds)
		EconomyService.AddMoney(player, amount)
		resultDetails.amount = amount
	elseif reward.type == "diamonds" then
		EconomyService.AddDiamonds(player, reward.amount)
		resultDetails.amount = reward.amount
	elseif reward.type == "freePack" then
		if reward.amount then
			EconomyService.AddDiamonds(player, reward.amount)
		end

		local candidates = {}
		for _, packId in PackCatalog.Order do
			if PackCatalog.Packs[packId].tier == reward.packTier then
				table.insert(candidates, packId)
			end
		end
		if #candidates > 0 and InventoryService.HasSpace(player, 1) then
			local packId = candidates[math.random(1, #candidates)]
			resultDetails.packResult = PackService.GrantFreePack(player, packId)
		end
	end

	return true, resultDetails
end

function DailyBlessingService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.ClaimDailyBlessingRequest.OnServerEvent:Connect(function(player: Player)
		local success, resultOrError = DailyBlessingService.TryClaim(player)
		Remotes.DailyBlessingResult:FireClient(player, success, resultOrError)
	end)

	Remotes.DailyBlessingStatusRequest.OnServerEvent:Connect(function(player: Player)
		local status = DailyBlessingService.GetStatus(player)
		Remotes.DailyBlessingStatusUpdated:FireClient(player, status)
	end)
end

return DailyBlessingService
