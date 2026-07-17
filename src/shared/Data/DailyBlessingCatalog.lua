--[[
	DailyBlessingCatalog.lua
	Recompensas por dia consecutivo de login, num ciclo de 7 dias que se
	repete (dia 8 = recompensas do dia 1 de novo, e assim por diante). O
	dia 7 é sempre o "jackpot" do ciclo.

	Local: ReplicatedStorage/Shared/Data/DailyBlessingCatalog.lua
]]

local DailyBlessingCatalog = {}

export type BlessingReward = {
	day: number,
	label: string,
	type: string, -- "money" | "diamonds" | "freePack"
	incomeSeconds: number?,
	minAmount: number?,
	amount: number?,
	packTier: string?,
}

DailyBlessingCatalog.Rewards = {
	{ day = 1, label = "5s de renda", type = "money", incomeSeconds = 5, minAmount = 15 },
	{ day = 2, label = "10 Diamante", type = "diamonds", amount = 10 },
	{ day = 3, label = "15s de renda", type = "money", incomeSeconds = 15, minAmount = 30 },
	{ day = 4, label = "20 Diamante", type = "diamonds", amount = 20 },
	{ day = 5, label = "25s de renda", type = "money", incomeSeconds = 25, minAmount = 50 },
	{ day = 6, label = "30 Diamante", type = "diamonds", amount = 30 },
	{ day = 7, label = "Pacote grátis + 50 Diamante!", type = "freePack", packTier = "Iniciado", amount = 50 },
}

-- Dado o número de dias consecutivos (streak), retorna a recompensa do dia
-- correspondente dentro do ciclo de 7.
function DailyBlessingCatalog.GetReward(streak: number)
	local dayInCycle = ((streak - 1) % 7) + 1
	return DailyBlessingCatalog.Rewards[dayInCycle]
end

return DailyBlessingCatalog
