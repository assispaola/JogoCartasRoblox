--[[
	WheelCatalog.lua
	Tabela de prêmios da Roda do Destino. Prêmios de dinheiro são
	proporcionais ao $/s atual do jogador (nunca fixo).

	Local: ReplicatedStorage/Shared/Data/WheelCatalog.lua
]]

local WheelCatalog = {}

export type WheelPrize = {
	id: string,
	label: string,
	type: string, -- "money" | "diamonds" | "freePack" | "bonusSpins" | "exclusiveCard"
	chance: number,
	incomeSeconds: number?, -- pra type == "money"
	minAmount: number?, -- pra type == "money" (piso garantido)
	amount: number?, -- pra type == "diamonds" ou "bonusSpins"
	packTier: string?, -- pra type == "freePack"
	packClan: string?, -- pra type == "freePack" (clã fixo, ex: temática "gelo")
	exclusiveRarity: string?, -- pra type == "exclusiveCard" (raridade concedida direto)
}

WheelCatalog.Prizes = {
	{ id = "diamonds_small", label = "5 Diamante", type = "diamonds", chance = 25, amount = 5 },
	{ id = "diamonds_large", label = "20 Diamante", type = "diamonds", chance = 15, amount = 20 },
	{ id = "money_small", label = "10s de renda", type = "money", chance = 25, incomeSeconds = 10, minAmount = 20 },
	{ id = "money_large", label = "30s de renda", type = "money", chance = 15, incomeSeconds = 30, minAmount = 60 },
	{ id = "bonus_spins", label = "+2 Giros Grátis", type = "bonusSpins", chance = 10, amount = 2 },
	{
		id = "pack_frozen",
		label = "Pacote Gelado grátis",
		type = "freePack",
		chance = 8,
		packTier = "Iniciado",
		packClan = "Abismo Glacial",
	},
	{
		id = "exclusive_card",
		label = "Carta Exclusiva!",
		type = "exclusiveCard",
		chance = 2,
		exclusiveRarity = "Lendário",
	},
}

-- Sorteia um prêmio respeitando as chances (soma 100%). `luckBoost` (usado
-- em giros pagos em lote) sorteia duas vezes e fica com o resultado mais
-- raro (o de menor chance) das duas.
function WheelCatalog.RollPrize(luckBoost: boolean?)
	local function rollOnce()
		local roll = math.random(1, 100)
		local accumulated = 0
		for _, prize in WheelCatalog.Prizes do
			accumulated += prize.chance
			if roll <= accumulated then
				return prize
			end
		end
		return WheelCatalog.Prizes[1]
	end

	local first = rollOnce()
	if not luckBoost then
		return first
	end

	local second = rollOnce()
	return (second.chance < first.chance) and second or first
end

return WheelCatalog
