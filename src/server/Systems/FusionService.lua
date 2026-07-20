--[[
	FusionService.lua

	OBSOLETO - substituído pelo AlbumService (evolução automática por pontos
	acumulados, ver SISTEMA_ALBUM_E_EVOLUCAO.md e AlbumService.lua). Mantido
	sem uso (não deletado) por enquanto: nem `Init()` nem `TryFuse` são mais
	chamados por nenhum sistema - `InventoryService.AddCard/RemoveCard/
	GetUnplacedCopies`, que este arquivo usa abaixo, também não existem mais
	(Mochila virou por criatura, não por cópia). Não usar como referência
	pra código novo.

	Comportamento antigo (histórico): consumia N cópias duplicadas de uma
	criatura/raridade (as de MENOR grau de Despertar primeiro) e gerava 1
	cópia nova da próxima raridade, no grau base de Despertar.

	Local: ServerScriptService/Server/Systems/FusionService.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Requires do corpo original (InventoryService/Creatures/Rarities/
-- StatsService/PortalService) removidos - só sobrevivem dentro do bloco
-- comentado abaixo, de referência histórica.
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local FusionService = {}

-- OBSOLETO - corpo original comentado abaixo só de referência histórica.
-- `InventoryService.GetUnplacedCopies/RemoveCard/AddCard` não existem mais
-- (Mochila virou por criatura, não por cópia) - chamar isso daria erro.
function FusionService.TryFuse(player: Player, creatureId: number, rarity: string)
	return false, "FusionService está obsoleto - evolução agora é automática via AlbumService"
end

--[[ Corpo original (histórico, não funciona mais - ver AlbumService):

function FusionService.TryFuse(player: Player, creatureId: number, rarity: string)
	local creature = Creatures[creatureId]
	if not creature then
		return false, "Criatura inválida"
	end

	local rarityData = Rarities.ById[rarity]
	if not rarityData then
		return false, "Raridade inválida"
	end

	if rarityData.duplicatesNeeded <= 0 or not rarityData.nextRarity then
		return false, "Essa criatura já está na raridade máxima"
	end

	local availableCopies = InventoryService.GetUnplacedCopies(player, creatureId, rarity)

	-- Portal da Sorte: Maré de Fusão reduz em 1 a quantidade de duplicatas
	-- necessárias (mínimo 1), enquanto o Portal estiver aberto.
	local duplicatesNeeded = rarityData.duplicatesNeeded
	if PortalService.IsFusionDiscount() then
		duplicatesNeeded = math.max(1, duplicatesNeeded - 1)
	end

	-- GetUnplacedCopies já devolve ordenado do menor grau pro maior - por
	-- isso pegamos os primeiros N, garantindo que sacrificamos as cópias
	-- "mais fracas" e preservamos as que já foram despertadas.
	if #availableCopies < duplicatesNeeded then
		return false,
			string.format(
				"Duplicatas insuficientes (tem %d, precisa de %d - cartas colocadas na base não contam)",
				#availableCopies,
				duplicatesNeeded
			)
	end

	for i = 1, duplicatesNeeded do
		InventoryService.RemoveCard(player, availableCopies[i])
	end

	local newCardId = InventoryService.AddCard(player, creatureId, rarityData.nextRarity)
	StatsService.Increment(player, "fusions", 1)

	return true, {
		cardId = newCardId,
		creatureId = creatureId,
		creatureName = creature.name,
		fromRarity = rarity,
		toRarity = rarityData.nextRarity,
	}
end
]]

function FusionService.Init()
	Remotes.FuseCreatureRequest.OnServerEvent:Connect(function(player: Player, creatureId: number, rarity: string)
		local success, resultOrError = FusionService.TryFuse(player, creatureId, rarity)

		if success then
			Remotes.FusionResult:FireClient(player, true, resultOrError)
		else
			Remotes.FusionResult:FireClient(player, false, resultOrError)
		end
	end)
end

return FusionService
