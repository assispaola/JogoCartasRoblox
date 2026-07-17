--[[
	PackCatalog.lua
	Gera os 60 pacotes temáticos (15 clãs x 4 tiers) por fórmula, cada um
	sorteando só entre as 20 criaturas daquele clã, com uma tabela de
	chance própria por tier. Também define o Pacote Padrão (sorteia entre
	as 300, sempre liberado).

	Desbloqueio: começa com 2 pacotes liberados no nível 1, +1 pacote a
	cada nível seguinte, na ordem: todos os 15 Iniciado primeiro, depois
	os 15 Adepto, depois Mestre, depois Supremo.

	Local: ReplicatedStorage/Shared/Data/PackCatalog.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clans = require(ReplicatedStorage.Shared.Data.Clans)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)

local PackCatalog = {}

export type PackInfo = {
	id: string,
	name: string,
	clan: string?, -- nil = sorteia entre TODAS as criaturas (só o Pacote Padrão)
	tier: string?,
	cost: number,
	unlockLevel: number,
	rarityChances: { [string]: number },
}

-- As 4 tabelas de chance por tier (cada uma soma 100%)
local TIERS = {
	{ name = "Iniciado", cost = 50, chances = { Bronze = 45, Prata = 25, Ouro = 15, Platina = 8, ["Lendário"] = 5, ["Mítico"] = 2 } },
	{ name = "Adepto", cost = 300, chances = { Bronze = 25, Prata = 30, Ouro = 25, Platina = 12, ["Lendário"] = 6, ["Mítico"] = 2 } },
	{ name = "Mestre", cost = 2000, chances = { Bronze = 10, Prata = 20, Ouro = 30, Platina = 25, ["Lendário"] = 12, ["Mítico"] = 3 } },
	{ name = "Supremo", cost = 15000, chances = { Bronze = 2, Prata = 8, Ouro = 20, Platina = 30, ["Lendário"] = 30, ["Mítico"] = 10 } },
}

PackCatalog.Packs = {} :: { [string]: PackInfo }
PackCatalog.Order = {} -- lista ordenada dos 60 IDs (ordem de desbloqueio)

-- Mapa clã -> lista de creatureIds daquele clã (montado uma vez, reaproveitado
-- pelo PackService toda vez que sorteia uma criatura de um pacote temático)
PackCatalog.CreatureIdsByClan = {} :: { [string]: { number } }
for creatureId, creature in Creatures do
	local list = PackCatalog.CreatureIdsByClan[creature.clan]
	if not list then
		list = {}
		PackCatalog.CreatureIdsByClan[creature.clan] = list
	end
	table.insert(list, creatureId)
end

-- Gera os 60 pacotes: tier por fora, clã por dentro - assim os 15
-- "Iniciado" desbloqueiam antes de qualquer "Adepto", etc.
local packIndex = 0
for _, tier in TIERS do
	for _, clanName in Clans.Order do
		packIndex += 1

		local id = clanName:gsub("%s+", "") .. "_" .. tier.name
		local unlockLevel = math.max(1, packIndex - 1) -- nível 1 já libera os 2 primeiros

		PackCatalog.Packs[id] = {
			id = id,
			name = tier.name .. " - " .. clanName,
			clan = clanName,
			tier = tier.name,
			cost = tier.cost,
			unlockLevel = unlockLevel,
			rarityChances = tier.chances,
		}
		table.insert(PackCatalog.Order, id)
	end
end

-- Pacote Padrão: sempre liberado, sorteia entre as 300 criaturas de
-- qualquer clã. Serve de opção "de segurança" enquanto os temáticos vão
-- sendo desbloqueados.
PackCatalog.Packs["Padrao"] = {
	id = "Padrao",
	name = "Pacote Padrão",
	clan = nil,
	tier = nil,
	cost = 50,
	unlockLevel = 1,
	rarityChances = TIERS[1].chances,
}

return PackCatalog
