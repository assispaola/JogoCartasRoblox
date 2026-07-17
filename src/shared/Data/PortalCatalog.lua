--[[
	PortalCatalog.lua
	As variações do Portal da Sorte. Cada uma liga um conjunto de efeitos
	(flags) que outros sistemas checam enquanto o Portal está aberto.

	Efeitos possíveis:
		eclipseClan   -> um clã sorteado ganha +50% de valor ($/s) e
		                 pacotes daquele clã custam 50% menos
		fusionDiscount -> fusão exige 1 duplicata a menos (mínimo 1)
		diamondBoost  -> Diamante do Índice em dobro
		reversedElements -> vantagens elementais invertidas (efeito visual/
		                 narrativo por enquanto - só ganha uso de verdade
		                 quando o sistema de batalha existir, Fase 6)
		doublePack    -> pacotes abertos entregam 2 criaturas em vez de 1

	Grande Portal combina vários efeitos de uma vez - é a versão rara.

	Local: ReplicatedStorage/Shared/Data/PortalCatalog.lua
]]

local PortalCatalog = {}

PortalCatalog.EventDurationSeconds = 30 * 60 -- o Portal fica aberto por 30 min
PortalCatalog.IntervalSeconds = 24 * 60 * 60 -- abre 1x a cada 24h

export type PortalScenario = {
	id: string,
	label: string,
	chance: number,
	effects: { [string]: boolean },
}

PortalCatalog.Scenarios = {
	{ id = "eclipse", label = "Eclipse de Clã", chance = 25, effects = { eclipseClan = true } },
	{ id = "fusion_tide", label = "Maré de Fusão", chance = 20, effects = { fusionDiscount = true } },
	{ id = "diamond_rain", label = "Chuva de Diamantes", chance = 20, effects = { diamondBoost = true } },
	{ id = "reverse_tide", label = "Maré Reversa", chance = 15, effects = { reversedElements = true } },
	{ id = "double_pack", label = "Pacote Duplo", chance = 10, effects = { doublePack = true } },
	{
		id = "grande_portal",
		label = "Grande Portal!",
		chance = 10,
		effects = { eclipseClan = true, diamondBoost = true, doublePack = true },
	},
}

function PortalCatalog.RollScenario()
	local roll = math.random(1, 100)
	local accumulated = 0
	for _, scenario in PortalCatalog.Scenarios do
		accumulated += scenario.chance
		if roll <= accumulated then
			return scenario
		end
	end
	return PortalCatalog.Scenarios[1]
end

return PortalCatalog
