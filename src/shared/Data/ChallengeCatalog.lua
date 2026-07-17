--[[
	ChallengeCatalog.lua
	Gera os requisitos do Desafio de Nível pra cada nível, por fórmula (em
	vez de escrever 59 listas na mão). A dificuldade cresce em degraus:

	Níveis 2-10   -> só dinheiro acumulado (fácil, "jogue normalmente")
	Níveis 11-25  -> pacotes abertos + dinheiro
	Níveis 26-40  -> descobertas + fusões + possuir uma carta de um clã
	Níveis 41-55  -> possuir criatura específica + sacrificar dinheiro/cartas
	Níveis 56+    -> sacrificar criatura específica + sacrifícios pesados

	Tipos de requisito possíveis:
		{ type = "money", amount }                      -- precisa TER esse dinheiro (não consome)
		{ type = "packsOpened", amount }                 -- contador cumulativo
		{ type = "discoveries", amount }                 -- contador cumulativo
		{ type = "fusions", amount }                     -- contador cumulativo
		{ type = "awakensImproved", amount }             -- contador cumulativo
		{ type = "ownClan", clan }                       -- possuir qualquer carta desse clã
		{ type = "ownCreature", creatureId }             -- possuir essa criatura (qualquer raridade)
		{ type = "sacrificeMoney", amount }               -- CONSOME dinheiro ao confirmar
		{ type = "sacrificeCardsByRarity", rarity, count } -- CONSOME N cartas dessa raridade (qualquer clã)
		{ type = "sacrificeCardsByClan", clan, count }     -- CONSOME N cartas desse clã (qualquer raridade)
		{ type = "sacrificeSpecificCreature", creatureId } -- CONSOME 1 cópia dessa criatura específica

	Essa mesma estrutura de requisito é reaproveitada pelas Provas de
	Renascimento (LevelService.CheckRequirement funciona pros dois).

	Local: ReplicatedStorage/Shared/Data/ChallengeCatalog.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clans = require(ReplicatedStorage.Shared.Data.Clans)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)

local ChallengeCatalog = {}

export type Requirement = {
	type: string,
	amount: number?,
	clan: string?,
	creatureId: number?,
	rarity: string?,
	count: number?,
}

local TOTAL_CREATURES = 300

-- Retorna a lista de requisitos pro jogador subir DO nível `level` PRO
-- próximo (level + 1).
function ChallengeCatalog.GetChallenge(level: number): { Requirement }
	local reqs: { Requirement } = {}

	if level <= 10 then
		table.insert(reqs, { type = "money", amount = level * 150 })
	elseif level <= 25 then
		table.insert(reqs, { type = "packsOpened", amount = level * 2 })
		table.insert(reqs, { type = "money", amount = level * 800 })
	elseif level <= 40 then
		table.insert(reqs, { type = "discoveries", amount = math.floor(level / 2) })
		table.insert(reqs, { type = "fusions", amount = math.floor(level / 8) })

		local clan = Clans.Order[(level % #Clans.Order) + 1]
		table.insert(reqs, { type = "ownClan", clan = clan })
	elseif level <= 55 then
		local creatureId = ((level * 7) % TOTAL_CREATURES) + 1
		table.insert(reqs, { type = "ownCreature", creatureId = creatureId })
		table.insert(reqs, { type = "sacrificeMoney", amount = level * 50000000 })

		local rarity = Rarities.Order[(level % 4) + 1] -- rotaciona entre Bronze..Platina
		table.insert(reqs, { type = "sacrificeCardsByRarity", rarity = rarity, count = 2 })
	else
		local creatureId = ((level * 13) % TOTAL_CREATURES) + 1
		table.insert(reqs, { type = "sacrificeSpecificCreature", creatureId = creatureId })
		table.insert(reqs, { type = "sacrificeMoney", amount = level * 2000000000 })
		table.insert(reqs, { type = "discoveries", amount = 5 })
	end

	return reqs
end

return ChallengeCatalog
