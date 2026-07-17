--[[
	SellService.lua
	Vende uma carta por dinheiro. O preço é uma fração pequena do valor
	real da carta (raridade × grau) - de propósito bem menor do que manter
	a carta gerando renda na base, pra não criar um loop de "comprar pacote
	só pra vender" que quebraria a economia.

	Local: ServerScriptService/Server/Systems/SellService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SellService = {}

-- Fração do valor real que a carta rende ao ser vendida. Ajustável -
-- se o balanceamento pedir vender por mais ou menos, muda só esse número.
local SELL_PERCENTAGE = 0.20

local EconomyService = nil -- carregado em Init() pra evitar circular require

-- Calcula quanto uma carta específica vale se vendida.
function SellService.GetSellPrice(card): number
	local fullValue = EconomyService.GetCardValue(card)
	return math.floor(fullValue * SELL_PERCENTAGE)
end

-- Tenta vender uma carta. Se ela estiver colocada na base, é removida de
-- lá automaticamente antes de vender (perde o $/s dela, então recalcula).
function SellService.TrySell(player: Player, cardId: number)
	local card = InventoryService.GetCard(player, cardId)
	if not card then
		return false, "Carta não encontrada"
	end

	local price = SellService.GetSellPrice(card)
	local wasPlaced = card.placed

	InventoryService.RemoveCard(player, cardId)
	EconomyService.AddMoney(player, price)

	if wasPlaced then
		EconomyService.RecalculateIncomePerSecond(player)
	end

	return true, {
		cardId = cardId,
		creatureName = Creatures[card.creatureId].name,
		rarity = card.rarity,
		grade = card.grade,
		price = price,
	}
end

function SellService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.SellCardRequest.OnServerEvent:Connect(function(player: Player, cardId: number)
		local success, resultOrError = SellService.TrySell(player, cardId)

		if success then
			Remotes.SellCardResult:FireClient(player, true, resultOrError)
		else
			Remotes.SellCardResult:FireClient(player, false, resultOrError)
		end
	end)
end

return SellService
