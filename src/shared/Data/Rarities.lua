--[[
	Rarities.lua
	As 6 raridades: ordem, chance de drop direto no pacote,
	duplicatas necessárias pra evoluir (fusão) e multiplicador de valor/stats.
	Gerado a partir de Cartas_Miticas_Clans_e_Criaturas.xlsx
]]

local Rarities = {}

-- Lista ordenada (Bronze = 1 ... Mítico = 6), útil pra iterar em ordem
Rarities.Order = {
	"Bronze",
	"Prata",
	"Ouro",
	"Platina",
	"Lendário",
	"Mítico",
}

-- Dados por raridade
Rarities.Data = {}

Rarities.Data["Bronze"] = {
	order = 1,
	name = "Bronze",
	dropChance = 45, -- % de chance de vir direto nessa raridade num pacote
	duplicatesNeeded = 3, -- cópias necessárias pra evoluir pra próxima (0 = raridade máxima)
	multiplier = 1, -- multiplicador aplicado sobre seedValue/baseAttack/baseDefense/baseHp
	nextRarity = "Prata",
}
Rarities.Data["Prata"] = {
	order = 2,
	name = "Prata",
	dropChance = 25, -- % de chance de vir direto nessa raridade num pacote
	duplicatesNeeded = 4, -- cópias necessárias pra evoluir pra próxima (0 = raridade máxima)
	multiplier = 2.5, -- multiplicador aplicado sobre seedValue/baseAttack/baseDefense/baseHp
	nextRarity = "Ouro",
}
Rarities.Data["Ouro"] = {
	order = 3,
	name = "Ouro",
	dropChance = 15, -- % de chance de vir direto nessa raridade num pacote
	duplicatesNeeded = 5, -- cópias necessárias pra evoluir pra próxima (0 = raridade máxima)
	multiplier = 6, -- multiplicador aplicado sobre seedValue/baseAttack/baseDefense/baseHp
	nextRarity = "Platina",
}
Rarities.Data["Platina"] = {
	order = 4,
	name = "Platina",
	dropChance = 8, -- % de chance de vir direto nessa raridade num pacote
	duplicatesNeeded = 6, -- cópias necessárias pra evoluir pra próxima (0 = raridade máxima)
	multiplier = 15, -- multiplicador aplicado sobre seedValue/baseAttack/baseDefense/baseHp
	nextRarity = "Lendário",
}
Rarities.Data["Lendário"] = {
	order = 5,
	name = "Lendário",
	dropChance = 5, -- % de chance de vir direto nessa raridade num pacote
	duplicatesNeeded = 8, -- cópias necessárias pra evoluir pra próxima (0 = raridade máxima)
	multiplier = 40, -- multiplicador aplicado sobre seedValue/baseAttack/baseDefense/baseHp
	nextRarity = "Mítico",
}
Rarities.Data["Mítico"] = {
	order = 6,
	name = "Mítico",
	dropChance = 2, -- % de chance de vir direto nessa raridade num pacote
	duplicatesNeeded = 0, -- cópias necessárias pra evoluir pra próxima (0 = raridade máxima)
	multiplier = 100, -- multiplicador aplicado sobre seedValue/baseAttack/baseDefense/baseHp
	nextRarity = nil,
}

return Rarities
