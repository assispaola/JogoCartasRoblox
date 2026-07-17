--!strict
-- ClanBorderColors.lua
-- Cores oficiais dos clãs e cálculo da cor de borda por raridade (progressão de
-- luminosidade sobre a cor base do clã, sem trocar o matiz).
--
-- IMPORTANTE: só contém os clãs já FECHADOS na revisão de paleta. Os demais
-- (Tempestade Rúnica, Selva Esmeralda, Constelação Arcana, Profundezas Abissais,
-- Chama Vulcânica, Névoa Espectral, Engrenagem Rúnica, Rocha Ancestral) ainda
-- estão pendentes de teste/aprovação e não devem ser adicionados aqui até
-- confirmarmos. Mesclar essa tabela com a Clans.lua existente quando os outros
-- clãs forem fechados.

local ClanBorderColors = {}

-- Cor base oficial de cada clã (hex -> Color3)
ClanBorderColors.BaseColors = {
	["Ordem Celestial"]     = Color3.fromHex("F4D03F"), -- travado (arte pronta)
	["Véu Sombrio"]         = Color3.fromHex("5B2C6F"), -- travado (arte pronta)
	["Fúria Selvagem"]      = Color3.fromHex("27AE60"), -- travado (arte pronta)
	["Abismo Glacial"]      = Color3.fromHex("AED6F1"), -- travado (arte pronta)
	["Maré Eterna"]         = Color3.fromHex("0E5C52"), -- fechado (teal profundo)
	["Forja Ígnea"]         = Color3.fromHex("D30D0D"), -- fechado (escarlate profundo)
	["Areia Amaldiçoada"]   = Color3.fromHex("AFA88C"), -- fechado (osso pálido)
} :: { [string]: Color3 }

-- Ordem oficial das 6 raridades
ClanBorderColors.RarityOrder = { "Bronze", "Prata", "Ouro", "Platina", "Lendário", "Mítico" }

-- Progressão de luminosidade aplicada sobre o V (brightness) do HSV da cor base
-- do clã. Mantém matiz e saturação (identidade do clã) e só clareia/intensifica
-- conforme a raridade sobe.
local LUMINOSITY_MULTIPLIER: { [string]: number } = {
	Bronze         = 0.55,
	Prata          = 0.68,
	Ouro           = 0.80,
	Platina        = 0.90,
	["Lendário"]   = 1.00,
	["Mítico"]     = 1.15, -- estoura o V original de propósito; clamp cuida do limite
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
	local baseColor = ClanBorderColors.BaseColors[clanName]
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
function ClanBorderColors.GetAllRarityColors(clanName: string): { [string]: Color3 }
	local result = {}
	for _, rarity in ClanBorderColors.RarityOrder do
		result[rarity] = ClanBorderColors.GetBorderColor(clanName, rarity)
	end
	return result
end

return ClanBorderColors
