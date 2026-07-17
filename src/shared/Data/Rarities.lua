--!strict
-- Rarities.lua
-- ReplicatedStorage > Shared > Data > Rarities.lua
--
-- Sistema de Raridade + Despertar (Grau) + fórmula de valor final.
-- Substitui a versão antiga (Bronze->Mítico com multiplicadores baixos).

export type RarityId = "Bronze" | "Prata" | "Ouro" | "Platina" | "Lendário" | "Mítico" | "Divino"

export type RarityData = {
	order: number,
	id: RarityId,
	dropChancePercent: number?, -- nil = não sai em pacote normal (só Divino)
	duplicatesNeeded: number, -- 0 = não evolui por fusão
	nextRarity: RarityId?, -- nil = não evolui por fusão (preenchido abaixo por ordem)
	valueMultiplier: number,
	awakenCostDiamonds: number, -- custo por tentativa no Altar
}

local Rarities = {}

-- ============================================================
-- RARIDADES (Bronze -> Divino)
-- ============================================================
local raritySeeds = {
	{ order = 1, id = "Bronze",   dropChancePercent = 45, duplicatesNeeded = 3, valueMultiplier = 1,     awakenCostDiamonds = 1200 },
	{ order = 2, id = "Prata",    dropChancePercent = 25, duplicatesNeeded = 4, valueMultiplier = 6,     awakenCostDiamonds = 2100 },
	{ order = 3, id = "Ouro",     dropChancePercent = 15, duplicatesNeeded = 5, valueMultiplier = 18,    awakenCostDiamonds = 3300 },
	{ order = 4, id = "Platina",  dropChancePercent = 8,  duplicatesNeeded = 6, valueMultiplier = 50,    awakenCostDiamonds = 4800 },
	{ order = 5, id = "Lendário", dropChancePercent = 5,  duplicatesNeeded = 8, valueMultiplier = 150,   awakenCostDiamonds = 6300 },
	{ order = 6, id = "Mítico",   dropChancePercent = 2,  duplicatesNeeded = 0, valueMultiplier = 500,   awakenCostDiamonds = 10000 },
	-- Divino: NÃO sai em pacote normal (dropChancePercent = nil), sem fusão,
	-- só via pacote de evento. Multiplicador MUITO acima do Mítico.
	{ order = 7, id = "Divino",   dropChancePercent = nil, duplicatesNeeded = 0, valueMultiplier = 10000, awakenCostDiamonds = 25000 },
}

-- `raritySeeds` não tem o campo `nextRarity` ainda (calculado abaixo, olhando
-- a próxima da lista) - por isso monta-se `Rarities.List`/`ById`/`Order`
-- juntos aqui, já como `RarityData` completo.
Rarities.List = {} :: { RarityData }
Rarities.ById = {} :: { [RarityId]: RarityData }
Rarities.Order = {} :: { RarityId }
for i, seed in raritySeeds do
	local nextRarity: RarityId? = nil
	if seed.duplicatesNeeded > 0 then
		local nextSeed = raritySeeds[i + 1]
		if nextSeed then
			nextRarity = nextSeed.id
		end
	end

	local data: RarityData = {
		order = seed.order,
		id = seed.id,
		dropChancePercent = seed.dropChancePercent,
		duplicatesNeeded = seed.duplicatesNeeded,
		nextRarity = nextRarity,
		valueMultiplier = seed.valueMultiplier,
		awakenCostDiamonds = seed.awakenCostDiamonds,
	}
	table.insert(Rarities.List, data)
	Rarities.ById[data.id] = data
	table.insert(Rarities.Order, data.id)
end

-- ============================================================
-- DESPERTAR (GRAU)
-- Toda carta nasce SEM despertar ativo ("vazio", multiplicador x1.0).
-- O badge de grau na UI só aparece a partir do primeiro despertar (7.0+).
-- O resultado sorteado no Altar SEMPRE substitui o grau atual (pode piorar).
-- ============================================================
export type AwakenGrade = {
	grade: number, -- 0 = vazio/default (não exibir na UI)
	valueMultiplier: number,
	rollChancePercent: number?, -- nil para o grau vazio (não é sorteável)
}

Rarities.AwakenGrades = {
	{ grade = 0,    valueMultiplier = 1.0,  rollChancePercent = nil }, -- vazio (default)
	{ grade = 7.0,  valueMultiplier = 1.05, rollChancePercent = 40 },
	{ grade = 7.5,  valueMultiplier = 1.15, rollChancePercent = 27 },
	{ grade = 8.0,  valueMultiplier = 1.30, rollChancePercent = 17 },
	{ grade = 8.5,  valueMultiplier = 1.50, rollChancePercent = 9 },
	{ grade = 9.0,  valueMultiplier = 1.75, rollChancePercent = 4.5 },
	{ grade = 9.5,  valueMultiplier = 2.10, rollChancePercent = 2 },
	{ grade = 10.0, valueMultiplier = 2.50, rollChancePercent = 0.5 },
} :: { AwakenGrade }

-- Lookup rápido por grau
Rarities.AwakenByGrade = {} :: { [number]: AwakenGrade }
for _, g in Rarities.AwakenGrades do
	Rarities.AwakenByGrade[g.grade] = g
end

-- Grau inicial de toda carta nova (vinda de pacote ou de fusão): vazio,
-- sem badge de UI, multiplicador x1.0.
Rarities.BaseAwakenGrade = 0

-- Sorteia um grau no Altar (ponderado pelas chances). Sempre retorna 7.0-10.0,
-- nunca retorna ao estado vazio (0) uma vez que o jogador já despertou uma vez.
function Rarities.RollAwakenGrade(): number
	local roll = math.random() * 100
	local cumulative = 0
	for _, g in Rarities.AwakenGrades do
		if g.rollChancePercent then
			cumulative += g.rollChancePercent
			if roll <= cumulative then
				return g.grade
			end
		end
	end
	return 7.0 -- fallback de segurança
end

-- Rola o grau `1 + extraRolls` vezes e fica com o MAIOR resultado entre
-- todas as tentativas. Usado pelos gamepasses de sorte do Altar do
-- Despertar (Sorte Celestial, Ultra Sorte, Sorte do Diamante) - cada um
-- contribui com uma quantidade de rolagens extras, que se somam.
function Rarities.RollAwakenGradeBest(extraRolls: number?): number
	local rollsToDo = extraRolls or 0
	local best = Rarities.RollAwakenGrade()

	for _ = 1, rollsToDo do
		local attempt = Rarities.RollAwakenGrade()
		if attempt > best then
			best = attempt
		end
	end

	return best
end

-- ============================================================
-- FATOR DE ESCALA ECONÔMICA
-- Converte os "valores semente" pequenos (10-100) da planilha em números
-- na casa de milhares/milhões, pra já nascer com valores altos ($/s) e
-- deixar o Renascimento (prestígio) levar pra bilhões/trilhões depois.
-- ============================================================
Rarities.GlobalScaleFactor = 1000

-- ============================================================
-- FÓRMULA DE VALOR FINAL
-- Valor = SeedValue x FatorEscala x MultRaridade x MultGrau x MultRenascimento
-- (MultRenascimento é opcional aqui — passa 1 se não estiver calculando com prestígio)
-- ============================================================
function Rarities.CalculateValue(
	seedValue: number,
	rarityId: RarityId,
	awakenGrade: number,
	renascimentoMultiplier: number?
): number
	local rarityData = Rarities.ById[rarityId]
	assert(rarityData, `Raridade inválida: {rarityId}`)

	local awakenData = Rarities.AwakenByGrade[awakenGrade]
	assert(awakenData, `Grau de despertar inválido: {awakenGrade}`)

	local renasc = renascimentoMultiplier or 1

	return seedValue
		* Rarities.GlobalScaleFactor
		* rarityData.valueMultiplier
		* awakenData.valueMultiplier
		* renasc
end

-- Diamante ganho na primeira descoberta de uma combinação criatura+raridade
-- (usado pelo sistema de Índice/Diamante do Índice)
Rarities.DiscoveryDiamondReward = {
	Bronze = 5,
	Prata = 10,
	Ouro = 25,
	Platina = 60,
	["Lendário"] = 150,
	["Mítico"] = 400,
	Divino = 1000,
} :: { [RarityId]: number }

return Rarities
