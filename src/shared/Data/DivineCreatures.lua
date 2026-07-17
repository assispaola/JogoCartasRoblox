--!strict
-- DivineCreatures.lua
-- ReplicatedStorage > Shared > Data > DivineCreatures.lua
--
-- As 15 criaturas Divinas (1 por clã). Sem fusão, sem evolução de raridade —
-- fixas, obtidas só via pacote de evento. Stats calibrados acima do teto
-- do Mítico (Valor 69-71, Atq 41-43, Def 34-36, HP 221-227).

export type DivineCreature = {
	order: number,
	clan: string,
	element: string,
	name: string,
	origin: string,
	description: string,
	seedValue: number,
	attackBase: number,
	defenseBase: number,
	hpBase: number,
	obtainMethod: string,
}

local DivineCreatures = {}

DivineCreatures.List = {
	{
		order = 1, clan = "Ordem Celestial", element = "Luz",
		name = "Amaterasu", origin = "Japão (Xintoísmo)",
		description = "Deusa do sol que ilumina todos os reinos com luz divina inextinguível",
		seedValue = 90, attackBase = 54, defenseBase = 44, hpBase = 260,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 2, clan = "Véu Sombrio", element = "Sombra",
		name = "Hécate", origin = "Grécia",
		description = "Deusa das encruzilhadas, da magia e da noite, guia entre os mundos visível e oculto",
		seedValue = 92, attackBase = 55, defenseBase = 45, hpBase = 262,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 3, clan = "Fúria Selvagem", element = "Natureza",
		name = "Cernunnos", origin = "Celta",
		description = "Senhor cornífero da floresta, guardião de todas as feras e ciclos selvagens",
		seedValue = 91, attackBase = 56, defenseBase = 46, hpBase = 265,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 4, clan = "Abismo Glacial", element = "Gelo",
		name = "Skadi", origin = "Nórdica",
		description = "Deusa caçadora do inverno eterno, senhora das montanhas geladas",
		seedValue = 93, attackBase = 55, defenseBase = 47, hpBase = 268,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		-- ATUALIZADO: Poseidon no lugar de Yemanjá
		order = 5, clan = "Maré Eterna", element = "Água",
		name = "Poseidon", origin = "Grécia",
		description = "Deus supremo dos mares, portador do tridente, senhor de tempestades aquáticas e terremotos",
		seedValue = 94, attackBase = 54, defenseBase = 48, hpBase = 270,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 6, clan = "Forja Ígnea", element = "Fogo",
		name = "Agni", origin = "Hindu",
		description = "Deus do fogo sagrado, mensageiro entre mortais e divindades através da chama eterna",
		seedValue = 95, attackBase = 58, defenseBase = 44, hpBase = 258,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 7, clan = "Tempestade Rúnica", element = "Trovão",
		name = "Chaac", origin = "Maia",
		description = "Senhor da chuva e do raio, cujo machado divino racha os céus em tempestade",
		seedValue = 92, attackBase = 57, defenseBase = 45, hpBase = 262,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 8, clan = "Rocha Ancestral", element = "Terra",
		name = "Pachamama", origin = "Andina/Inca",
		description = "Mãe Terra primordial, de quem nasce toda montanha, colheita e vida sobre a rocha",
		seedValue = 96, attackBase = 52, defenseBase = 52, hpBase = 285,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 9, clan = "Areia Amaldiçoada", element = "Morte",
		name = "Anúbis", origin = "Egito",
		description = "Guardião dos mortos e senhor do embalsamamento, juiz das almas no além",
		seedValue = 93, attackBase = 56, defenseBase = 47, hpBase = 264,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 10, clan = "Selva Esmeralda", element = "Veneno",
		name = "Jörmungandr", origin = "Nórdica",
		description = "A Serpente do Mundo, tão vasta que envolve toda a criação com seu veneno ancestral",
		seedValue = 97, attackBase = 59, defenseBase = 46, hpBase = 266,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 11, clan = "Constelação Arcana", element = "Astral",
		name = "Nut", origin = "Egito",
		description = "Deusa do céu estrelado que arqueia o firmamento e engole o sol todas as noites",
		seedValue = 94, attackBase = 55, defenseBase = 49, hpBase = 272,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 12, clan = "Profundezas Abissais", element = "Mar Profundo",
		name = "Tiamat", origin = "Mesopotâmia",
		description = "Deusa primordial do caos salgado, mãe de monstros e origem de todas as profundezas",
		seedValue = 98, attackBase = 60, defenseBase = 48, hpBase = 275,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 13, clan = "Chama Vulcânica", element = "Lava",
		name = "Pele", origin = "Havaí",
		description = "Deusa do vulcão que molda ilhas com fogo líquido e fúria incandescente",
		seedValue = 95, attackBase = 58, defenseBase = 45, hpBase = 260,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 14, clan = "Névoa Espectral", element = "Fantasma",
		name = "Mictēcacihuātl", origin = "Asteca (Mexica)",
		description = "Rainha do Mictlán, guardiã dos ossos e senhora do sétimo nível do submundo",
		seedValue = 91, attackBase = 53, defenseBase = 50, hpBase = 278,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
	{
		order = 15, clan = "Engrenagem Rúnica", element = "Tecnomancia",
		name = "Hefesto", origin = "Grécia",
		description = "O grande ferreiro divino, criador de autômatos vivos e forjador dos primeiros mecanismos",
		seedValue = 96, attackBase = 57, defenseBase = 47, hpBase = 267,
		obtainMethod = "Pacote exclusivo de Evento (Robux/sorte)",
	},
} :: { DivineCreature }

-- Lookup por clã (já que é 1-pra-1, útil pro sistema de pacote de evento)
DivineCreatures.ByClan = {} :: { [string]: DivineCreature }
for _, creature in DivineCreatures.List do
	DivineCreatures.ByClan[creature.clan] = creature
end

return DivineCreatures
