--!strict
-- Clans.lua
-- ReplicatedStorage > Shared > Data > Clans.lua
--
-- Os 15 clãs elementais + cores finais (hex), já com distância de matiz
-- ajustada pra nenhum clã ficar visualmente parecido com outro.

export type ClanData = {
	order: number,
	name: string,
	element: string,
	colorHex: string,
	color: Color3,
}

local function hexToColor3(hex: string): Color3
	local r = tonumber(hex:sub(2, 3), 16) :: number
	local g = tonumber(hex:sub(4, 5), 16) :: number
	local b = tonumber(hex:sub(6, 7), 16) :: number
	return Color3.fromRGB(r, g, b)
end

local Clans = {}

local clanSeeds = {
	{ order = 1,  name = "Ordem Celestial",       element = "Luz",           colorHex = "#F4D03F" },
	{ order = 2,  name = "Véu Sombrio",            element = "Sombra",        colorHex = "#5B2C6F" },
	{ order = 3,  name = "Fúria Selvagem",         element = "Natureza",      colorHex = "#27AE60" },
	{ order = 4,  name = "Abismo Glacial",         element = "Gelo",          colorHex = "#AED6F1" },
	{ order = 5,  name = "Maré Eterna",            element = "Água",         colorHex = "#0E5C52" },
	{ order = 6,  name = "Forja Ígnea",            element = "Fogo",          colorHex = "#D30D0D" },
	{ order = 7,  name = "Tempestade Rúnica",      element = "Trovão",        colorHex = "#FF99CA" },
	{ order = 8,  name = "Rocha Ancestral",        element = "Terra",         colorHex = "#935116" },
	{ order = 9,  name = "Areia Amaldiçoada",      element = "Morte",         colorHex = "#AFA88C" },
	{ order = 10, name = "Selva Esmeralda",        element = "Veneno",        colorHex = "#147B16" },
	{ order = 11, name = "Constelação Arcana",     element = "Astral",        colorHex = "#B23488" },
	{ order = 12, name = "Profundezas Abissais",   element = "Mar Profundo",  colorHex = "#231443" },
	{ order = 13, name = "Chama Vulcânica",        element = "Lava",          colorHex = "#3D0F17" },
	{ order = 14, name = "Névoa Espectral",        element = "Fantasma",      colorHex = "#AAB7B8" },
	{ order = 15, name = "Engrenagem Rúnica",      element = "Tecnomancia",   colorHex = "#DBF470" },
}

-- `clanSeeds` não tem o campo `color` ainda (calculado abaixo por
-- `hexToColor3`) - por isso monta-se `Clans.List` só depois de preenchido,
-- já como `ClanData` completo.
Clans.List = {} :: { ClanData }
Clans.ByName = {} :: { [string]: ClanData }
for _, seed in clanSeeds do
	local clan: ClanData = {
		order = seed.order,
		name = seed.name,
		element = seed.element,
		colorHex = seed.colorHex,
		color = hexToColor3(seed.colorHex),
	}
	table.insert(Clans.List, clan)
	Clans.ByName[clan.name] = clan
end

-- Lista dos 15 nomes na ordem de `order` - usada por quem precisa iterar
-- os clãs (geração de pacotes, rotação de Desafio de Nível, Portal da Sorte).
Clans.Order = {} :: { string }
for _, clan in Clans.List do
	table.insert(Clans.Order, clan.name)
end

return Clans
