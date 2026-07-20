--!strict
-- Tiers.lua
-- ReplicatedStorage > Shared > Data > Tiers.lua
--
-- Sistema de 3 Tiers (Comum/Nobre/Ancestral) que determinam o seedValue
-- multiplicador de cada criatura. Cada clã tem 10 C + 7 B + 3 A (20 total).
--
-- Usado por:
-- - Creatures.lua: cada criatura tem tier "C" | "B" | "A"
-- - PackCatalog.lua: cada pack tem distribuição % C/B/A
-- - PackOddsRoller.lua: sorteia tier por probabilities, depois criatura dentro clã
-- - EconomyService.lua: calcula seedValue = creature.seedValue * Tier.seedValueMult

export type TierId = "C" | "B" | "A"

export type TierData = {
	id: TierId,
	seedValueMult: number, -- multiplicador aplicado ao seedValue da criatura
	name: string,          -- nome legível
	symbol: string,        -- ⭐, ⭐⭐, ⭐⭐⭐ (exibido na UI)
	creaturesPerClan: number, -- quantas criaturas deste tier por clã (total 20 por clã)
}

local Tiers = {}

Tiers.C = {
	id = "C",
	seedValueMult = 1,
	name = "Comum",
	symbol = "⭐",
	creaturesPerClan = 10,
} :: TierData

Tiers.B = {
	id = "B",
	seedValueMult = 4,
	name = "Nobre",
	symbol = "⭐⭐",
	creaturesPerClan = 7,
} :: TierData

Tiers.A = {
	id = "A",
	seedValueMult = 15,
	name = "Ancestral",
	symbol = "⭐⭐⭐",
	creaturesPerClan = 3,
} :: TierData

-- Lookup por id (C/B/A)
Tiers.ById = {
	C = Tiers.C,
	B = Tiers.B,
	A = Tiers.A,
} :: { [TierId]: TierData }

-- Lista em ordem de progressão
Tiers.Order = { "C", "B", "A" } :: { TierId }

-- Total de criaturas por clã (10 + 7 + 3)
Tiers.TotalPerClan = 20

return Tiers
