--!strict
-- ClanBorderColors.lua
-- Cores oficiais dos clãs e cálculo da cor de borda por raridade (progressão de
-- luminosidade sobre a cor base do clã, sem trocar o matiz).
--
-- Paleta FINAL — todos os 15 clãs fechados nesta rodada de revisão.

local ClanBorderColors = {}

type ColorMap = { [string]: Color3 }

-- Cor base oficial de cada clã (hex -> Color3)
local baseColors: ColorMap = {
	["Ordem Celestial"]      = Color3.fromHex("F4D03F"),
	["Véu Sombrio"]          = Color3.fromHex("5B2C6F"),
	["Fúria Selvagem"]       = Color3.fromHex("27AE60"),
	["Abismo Glacial"]       = Color3.fromHex("AED6F1"),
	["Maré Eterna"]          = Color3.fromHex("0E5C52"),
	["Forja Ígnea"]          = Color3.fromHex("D30D0D"),
	["Tempestade Rúnica"]    = Color3.fromHex("FF99CA"),
	-- ATENÇÃO: a planilha ainda mostra o hex antigo (4B9B90) no texto dessa
	-- célula, mas o preenchimento já está com a cor certa (FF99CA). Vale
	-- corrigir o texto lá também.
	["Rocha Ancestral"]      = Color3.fromHex("935116"),
	["Areia Amaldiçoada"]    = Color3.fromHex("AFA88C"),
	["Selva Esmeralda"]      = Color3.fromHex("147B16"),
	["Constelação Arcana"]   = Color3.fromHex("B23488"),
	["Profundezas Abissais"] = Color3.fromHex("231443"),
	["Chama Vulcânica"]      = Color3.fromHex("3D0F17"),
	["Névoa Espectral"]      = Color3.fromHex("AAB7B8"),
	["Engrenagem Rúnica"]    = Color3.fromHex("DBF470"),
}
ClanBorderColors.BaseColors = baseColors

-- Ordem oficial das 6 raridades
local rarityOrder: { string } = { "Bronze", "Prata", "Ouro", "Platina", "Lendário", "Mítico" }
ClanBorderColors.RarityOrder = rarityOrder

-- Progressão de luminosidade aplicada sobre o V (brightness) do HSV da cor base
-- do clã. Mantém matiz e saturação (identidade do clã) e só clareia/intensifica
-- conforme a raridade sobe.
local LUMINOSITY_MULTIPLIER: { [string]: number } = {
	Bronze          = 0.55,
	Prata           = 0.68,
	Ouro            = 0.80,
	Platina         = 0.90,
	["Lendário"]    = 1.00,
	["Mítico"]      = 1.15, -- estoura o V original de propósito; clamp cuida do limite
}

-- No Mítico a saturação recua um pouco pra dar aquele efeito "quase brilho puro"
local SATURATION_ADJUST: { [string]: number } = {
	["Mítico"] = 0.85,
}

--[[
	Retorna a cor de borda (Color3) pra combinação clã + raridade.
	Uso: ClanBorderColors.GetBorderColor("Forja Ígnea", "Lendário")
]]
function ClanBorderColors.GetBorderColor(clanName: string, rarity: string): Color3
	local baseColor = baseColors[clanName]
	if not baseColor then
		warn(("ClanBorderColors: clã '%s' ainda não tem cor definida/fechada"):format(clanName))
		return Color3.fromRGB(255, 255, 255)
	end

	local multiplier = LUMINOSITY_MULTIPLIER[rarity]
	if not multiplier then
		warn(("ClanBorderColors: raridade '%s' inválida"):format(rarity))
		multiplier = 1.0
	end

	local h, s, v = baseColor:ToHSV()
	v = math.clamp(v * multiplier, 0, 1)

	local satMult = SATURATION_ADJUST[rarity]
	if satMult then
		s = math.clamp(s * satMult, 0, 1)
	end

	return Color3.fromHSV(h, s, v)
end

--[[
	Retorna a tabela completa { [raridade] = Color3 } pra um clã, já pronta
	pra popular UI (ex: preview de todas as raridades de uma vez).
]]
function ClanBorderColors.GetAllRarityColors(clanName: string): ColorMap
	local result: ColorMap = {}
	for _, rarity in rarityOrder do
		result[rarity] = ClanBorderColors.GetBorderColor(clanName, rarity)
	end
	return result
end

return ClanBorderColors
