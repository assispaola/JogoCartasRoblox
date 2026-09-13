--[[
	DespertarService.lua

	OBSOLETO - substituído por AlbumService.RollDespertar. Sob o modelo de
	Álbum, o grau de Despertar é 1 campo por CRIATURA (data.album[creatureId].grau),
	não mais por cópia física (cardId) - este arquivo (que ainda opera em
	cima de `InventoryService.GetCard(player, cardId)`, função que não
	existe mais) fica mantido só de referência histórica, sem uso. Não
	chamar `.Init()` (Main.server.lua já religou `Remotes.AwakenRequest`
	através de `AlbumService.Init()`).

	Comportamento antigo (histórico): gastava Diamante pra tentar sortear um
	grau melhor numa carta específica (cardId) - resultado sorteado sempre
	substituía o grau atual, pra melhor ou pra pior.

	Local: ServerScriptService/Server/Systems/DespertarService.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Requires do corpo original (InventoryService/PlayerDataService/Rarities/
-- StatsService, além de AWAKEN_COST/LUCK_GAMEPASS_BONUS_ROLLS/getExtraRolls)
-- removidos - só sobrevivem dentro do bloco comentado abaixo, de
-- referência histórica.
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local DespertarService = {}

-- OBSOLETO - corpo original comentado abaixo só de referência histórica.
-- `InventoryService.GetCard` não existe mais (grau vive em
-- data.album[creatureId].grau, não por cardId) - chamar isso daria erro.
function DespertarService.TryAwaken(player: Player, cardId: number)
	return false, "DespertarService está obsoleto - use AlbumService.RollDespertar(player, creatureId)"
end

--[[ Corpo original (histórico, não funciona mais - ver AlbumService.RollDespertar):

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
]]

function DespertarService.Init()
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
