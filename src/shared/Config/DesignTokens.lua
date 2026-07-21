--!strict
--[[
	DesignTokens.lua
	Fonte única de verdade para cores, radius, espaçamento e fontes.
	Baseado no Design System v2 — Cartas Míticas.

	Localização Rojo sugerida: ReplicatedStorage/Shared/DesignTokens
	Qualquer componente de UI deve consumir cores DAQUI, nunca hardcoded.
]]

local DesignTokens = {}

-- ===== CORES BASE DE INTERFACE =====
DesignTokens.Colors = {
	Background = Color3.fromHex("#0c0e1f"),
	Panel = Color3.fromHex("#181c38"),
	PanelHighlight = Color3.fromHex("#212650"),
	Border = Color3.fromHex("#31366b"),

	Text = Color3.fromHex("#f5f4ff"),
	TextDim = Color3.fromHex("#a6a8cf"),
	TextMute = Color3.fromHex("#6d709b"),

	Money = Color3.fromHex("#3ddc73"),
	Diamond = Color3.fromHex("#3ec1ff"),
	Robux = Color3.fromHex("#e9e9ef"),
	XP = Color3.fromHex("#ffd23f"),
	Event = Color3.fromHex("#ff9f3f"),
	Success = Color3.fromHex("#22c55e"),
	Danger = Color3.fromHex("#ff5c5c"),
}

-- ===== RARIDADES (8) =====
DesignTokens.Rarities = {
	Default = Color3.fromHex("#9195b8"),
	Bronze = Color3.fromHex("#d6934f"),
	Prata = Color3.fromHex("#eef1f5"),
	Ouro = Color3.fromHex("#ffd94a"),
	Platina = Color3.fromHex("#87e9ff"),
	Lendario = Color3.fromHex("#c58aff"),
	Mitico = Color3.fromHex("#ff4d5e"),
	Divino = Color3.fromHex("#ffdd6b"), -- + anel animado, ver CreatureCard.lua futuro
}

-- ===== CORES DOS 15 CLÃS =====
DesignTokens.Clans = {
	OrdemCelestial = Color3.fromHex("#F4D03F"),
	VeuSombrio = Color3.fromHex("#5B2C6F"),
	FuriaSelvagem = Color3.fromHex("#27AE60"),
	AbismoGlacial = Color3.fromHex("#AED6F1"),
	MareEterna = Color3.fromHex("#0E5C52"),
	ForjaIgnea = Color3.fromHex("#D30D0D"),
	TempestadeRunica = Color3.fromHex("#FF99CA"),
	RochaAncestral = Color3.fromHex("#935116"),
	AreiaAmaldicoada = Color3.fromHex("#AFA88C"),
	SelvaEsmeralda = Color3.fromHex("#147B16"),
	ConstelacaoArcana = Color3.fromHex("#B23488"),
	ProfundezasAbissais = Color3.fromHex("#231443"),
	ChamaVulcanica = Color3.fromHex("#3D0F17"),
	NevoaEspectral = Color3.fromHex("#AAB7B8"),
	EngrenagemRunica = Color3.fromHex("#DBF470"),
}

-- ===== RADIUS =====
DesignTokens.Radius = {
	Small = 12,
	Medium = 18,
	Large = 26,
	Pill = 999, -- badges/pills totalmente arredondados
}

-- ===== ESPAÇAMENTO (múltiplos de 8) =====
DesignTokens.Spacing = {
	XSmall = 4,
	Small = 8,
	Medium = 16,
	Large = 24,
	XLarge = 32,
}

-- ===== FONTES =====
-- Nota: usar fontes built-in do Roblox por padrão. Se subir fonte custom
-- (ex: Baloo 2 como FontFace via asset), trocar aqui centralizadamente.
DesignTokens.Fonts = {
	Display = Enum.Font.GothamBold, -- headers, botões, valores grandes
	Body = Enum.Font.GothamMedium, -- texto corrido
	Mono = Enum.Font.Code, -- valores numéricos ($ / 💎)
}

-- ===== HELPERS DE FORMATAÇÃO =====

--- Formata número grande para exibição (padrão brasileiro + abreviação)
--- Ex: 1250000 -> "1.250.000" | 4200000000 -> "4.20B"
function DesignTokens.FormatNumber(n: number): string
	if n >= 1e12 then
		return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	end

	local isNegative = n < 0
	local intPart = string.format("%d", math.floor(math.abs(n)))
	local reversed = intPart:reverse()
	local withDots = reversed:gsub("(%d%d%d)", "%1."):reverse()
	withDots = withDots:gsub("^%.", "")

	return (isNegative and "-" or "") .. withDots
end

return DesignTokens
