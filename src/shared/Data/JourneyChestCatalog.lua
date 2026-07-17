--[[
	JourneyChestCatalog.lua
	Marcos de tempo jogado (contados em tempo real desde o início do ciclo,
	não pausam se o jogador ficar offline) e as recompensas de cada um. O
	ciclo inteiro reseta depois de CYCLE_DURATION_SECONDS, liberando todos
	os baús de novo.

	Local: ReplicatedStorage/Shared/Data/JourneyChestCatalog.lua
]]

local JourneyChestCatalog = {}

JourneyChestCatalog.CycleDurationSeconds = 6 * 60 * 60 -- ciclo inteiro reseta a cada 6h

export type ChestReward = {
	index: number,
	thresholdSeconds: number,
	label: string,
	type: string, -- "money" | "diamonds" | "freePack"
	incomeSeconds: number?,
	minAmount: number?,
	amount: number?,
	packTier: string?,
}

JourneyChestCatalog.Chests = {
	{ index = 1, thresholdSeconds = 5 * 60, label = "5 min jogados", type = "money", incomeSeconds = 5, minAmount = 15 },
	{ index = 2, thresholdSeconds = 15 * 60, label = "15 min jogados", type = "diamonds", amount = 15 },
	{ index = 3, thresholdSeconds = 30 * 60, label = "30 min jogados", type = "money", incomeSeconds = 20, minAmount = 40 },
	{ index = 4, thresholdSeconds = 60 * 60, label = "1h jogada", type = "diamonds", amount = 30 },
	{ index = 5, thresholdSeconds = 2 * 60 * 60, label = "2h jogadas", type = "freePack", packTier = "Iniciado" },
	{
		index = 6,
		thresholdSeconds = 4 * 60 * 60,
		label = "4h jogadas - baú final!",
		type = "money",
		incomeSeconds = 60,
		minAmount = 100,
		amount = 50, -- Diamante extra além do dinheiro, nesse baú especificamente
	},
}

return JourneyChestCatalog
