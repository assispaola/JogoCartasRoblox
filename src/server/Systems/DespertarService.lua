--[[
	DespertarService.lua
	O Altar do Despertar: gasta Diamante pra tentar sortear um grau melhor
	numa carta específica. Regra de design ATUALIZADA: o resultado sorteado
	sempre substitui o grau atual, pra melhor OU PRA PIOR - risco real a
	cada tentativa (downgrade é possível), pra não virar um sistema
	"seguro" demais.

	Local: ServerScriptService/Server/Systems/DespertarService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatsService = require(ServerScriptService.Server.Systems.StatsService)

local DespertarService = {}

-- Custo em Diamante de cada tentativa. Fixo por enquanto - dá pra pensar
-- num custo crescente por grau atual mais pra frente, se o balanceamento
-- pedir.
local AWAKEN_COST = 15

-- Quantas rolagens extras ("melhor de N") cada gamepass de sorte concede.
-- Todos os que o jogador possui se somam (por isso "acumula com outros
-- produtos de sorte").
local LUCK_GAMEPASS_BONUS_ROLLS = {
	sorteCeleste = 1,
	ultraSorte = 2,
	sorteDiamante = 1,
}

-- EconomyService é carregado dentro de Init() (mesmo padrão do
-- InventoryService) pra evitar circular require.
local EconomyService = nil

-- Soma as rolagens extras de todos os gamepasses de sorte que o jogador
-- possui.
local function getExtraRolls(player: Player): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end

	local extra = 0
	for gamepassKey, bonusRolls in LUCK_GAMEPASS_BONUS_ROLLS do
		if data.gamepasses[gamepassKey] then
			extra += bonusRolls
		end
	end
	return extra
end

-- Tenta despertar uma carta. Retorna true + dados do resultado, ou
-- false + motivo do erro.
function DespertarService.TryAwaken(player: Player, cardId: number)
	local card = InventoryService.GetCard(player, cardId)
	if not card then
		return false, "Carta não encontrada"
	end

	if card.grade >= Rarities.AwakenGrades[#Rarities.AwakenGrades].grade then
		return false, "Essa carta já está no grau máximo de Despertar"
	end

	local spent = EconomyService.TrySpendDiamonds(player, AWAKEN_COST)
	if not spent then
		return false, "Diamante insuficiente"
	end

	local rolledGrade = Rarities.RollAwakenGradeBest(getExtraRolls(player))
	local previousGrade = card.grade
	local improved = rolledGrade > previousGrade
	local worsened = rolledGrade < previousGrade

	-- Nova regra: o resultado sorteado SEMPRE substitui o grau atual, pra
	-- melhor ou pra pior. Risco real a cada tentativa - sem essa proteção,
	-- o jogador realmente aposta o grau atual a cada vez que gasta Diamante.
	card.grade = rolledGrade

	if improved then
		StatsService.Increment(player, "awakensImproved", 1)
	end

	-- Se a carta está colocada na base, o $/s dela pode ter mudado (pra
	-- mais ou pra menos).
	if card.placed then
		EconomyService.RecalculateIncomePerSecond(player)
	end

	return true, {
		cardId = cardId,
		previousGrade = previousGrade,
		rolledGrade = rolledGrade,
		finalGrade = card.grade,
		improved = improved,
		worsened = worsened,
	}
end

function DespertarService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.AwakenRequest.OnServerEvent:Connect(function(player: Player, cardId: number)
		local success, resultOrError = DespertarService.TryAwaken(player, cardId)

		if success then
			Remotes.AwakenResult:FireClient(player, true, resultOrError)
		else
			Remotes.AwakenResult:FireClient(player, false, resultOrError)
		end
	end)
end

return DespertarService
