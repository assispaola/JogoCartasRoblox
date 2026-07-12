--[[
	Clans.lua
	Dados dos 15 clãs do jogo: elemento, cor e vantagem elemental.
	Gerado a partir de Cartas_Miticas_Clans_e_Criaturas.xlsx
]]

local Clans = {}

Clans["Ordem Celestial"] = {
	name = "Ordem Celestial",
	element = "Luz",
	color = "#F4D03F",
	strongAgainst = "Véu Sombrio",
	weakAgainst = "Constelação Arcana",
}
Clans["Véu Sombrio"] = {
	name = "Véu Sombrio",
	element = "Sombra",
	color = "#5B2C6F",
	strongAgainst = "Constelação Arcana",
	weakAgainst = "Ordem Celestial",
}
Clans["Fúria Selvagem"] = {
	name = "Fúria Selvagem",
	element = "Natureza",
	color = "#27AE60",
	strongAgainst = "Rocha Ancestral",
	weakAgainst = "Chama Vulcânica",
}
Clans["Abismo Glacial"] = {
	name = "Abismo Glacial",
	element = "Gelo",
	color = "#AED6F1",
	strongAgainst = "Fúria Selvagem",
	weakAgainst = "Forja Ígnea",
}
Clans["Maré Eterna"] = {
	name = "Maré Eterna",
	element = "Água",
	color = "#2E86C1",
	strongAgainst = "Forja Ígnea",
	weakAgainst = "Tempestade Rúnica",
}
Clans["Forja Ígnea"] = {
	name = "Forja Ígnea",
	element = "Fogo",
	color = "#E74C3C",
	strongAgainst = "Abismo Glacial",
	weakAgainst = "Maré Eterna",
}
Clans["Tempestade Rúnica"] = {
	name = "Tempestade Rúnica",
	element = "Trovão",
	color = "#F7DC6F",
	strongAgainst = "Maré Eterna",
	weakAgainst = "Rocha Ancestral",
}
Clans["Rocha Ancestral"] = {
	name = "Rocha Ancestral",
	element = "Terra",
	color = "#935116",
	strongAgainst = "Tempestade Rúnica",
	weakAgainst = "Fúria Selvagem",
}
Clans["Areia Amaldiçoada"] = {
	name = "Areia Amaldiçoada",
	element = "Morte",
	color = "#C9B037",
	strongAgainst = "Selva Esmeralda",
	weakAgainst = "Névoa Espectral",
}
Clans["Selva Esmeralda"] = {
	name = "Selva Esmeralda",
	element = "Veneno",
	color = "#145A32",
	strongAgainst = "Maré Eterna",
	weakAgainst = "Areia Amaldiçoada",
}
Clans["Constelação Arcana"] = {
	name = "Constelação Arcana",
	element = "Astral",
	color = "#8E44AD",
	strongAgainst = "Véu Sombrio",
	weakAgainst = "Ordem Celestial",
}
Clans["Profundezas Abissais"] = {
	name = "Profundezas Abissais",
	element = "Mar Profundo",
	color = "#154360",
	strongAgainst = "Chama Vulcânica",
	weakAgainst = "Maré Eterna",
}
Clans["Chama Vulcânica"] = {
	name = "Chama Vulcânica",
	element = "Lava",
	color = "#922B21",
	strongAgainst = "Rocha Ancestral",
	weakAgainst = "Profundezas Abissais",
}
Clans["Névoa Espectral"] = {
	name = "Névoa Espectral",
	element = "Fantasma",
	color = "#AAB7B8",
	strongAgainst = "Areia Amaldiçoada",
	weakAgainst = "Véu Sombrio",
}
Clans["Engrenagem Rúnica"] = {
	name = "Engrenagem Rúnica",
	element = "Tecnomancia",
	color = "#B87333",
	strongAgainst = nil,
	weakAgainst = nil,
}

return Clans
