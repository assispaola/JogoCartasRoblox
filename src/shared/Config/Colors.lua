--!strict
--[[
	Colors.lua
	Paleta única de cores — Cartas Míticas.
	Localização Rojo: ReplicatedStorage/Shared/Config/Colors
]]

local Colors = {}

-- Base de interface
Colors.Background = Color3.fromHex("#0b0d1e")
Colors.Panel = Color3.fromHex("#161a35")
Colors.PanelHighlight = Color3.fromHex("#1f2444")
Colors.Border = Color3.fromHex("#4C58C6") -- token confirmado no Figma (HUD principal)

-- Gradiente de painel/carta confirmado no Figma (HUD principal): base -> topo
Colors.BackgroundGradientBase = Color3.fromHex("#0D1024")
Colors.BackgroundGradientTop = Color3.fromHex("#171B34")

Colors.Text = Color3.fromHex("#f5f4ff")
Colors.TextDim = Color3.fromHex("#a6a8cf")
Colors.TextMute = Color3.fromHex("#6d709b")

-- Moedas e economia
Colors.Money = Color3.fromHex("#79E600") -- token confirmado no Figma (HUD principal)
Colors.Diamond = Color3.fromHex("#87E1E8") -- token confirmado no Figma (HUD principal)
Colors.Robux = Color3.fromHex("#e9e9ef")
Colors.Renascimento = Color3.fromHex("#8b5cf6")
Colors.Event = Color3.fromHex("#FFDA1E") -- token confirmado no Figma (HUD principal, $/s)

-- Funcionais / botões
Colors.Primary = Color3.fromHex("#4c6fff")
Colors.Cyan = Color3.fromHex("#22c3ff")
Colors.Gold = Color3.fromHex("#f5b301")
Colors.Success = Color3.fromHex("#22c55e")
Colors.Danger = Color3.fromHex("#ff4d4d")
Colors.Ghost = Color3.fromHex("#2b3060")

-- Raridades (8) — cores confirmadas em docs/game-design/moldura_refinada_8tiers.html
-- e docs/game-design/card_ui_proposta_v4.html (campo rarityColor)
Colors.Rarities = {
	Default = Color3.fromHex("#2A2E3D"),
	Bronze = Color3.fromHex("#CD7F32"),
	Prata = Color3.fromHex("#E0E6ED"),
	Ouro = Color3.fromHex("#FFD700"),
	Platina = Color3.fromHex("#00F0FF"),
	Lendario = Color3.fromHex("#C800FF"),
	Mitico = Color3.fromHex("#FF007F"),
	Divino = Color3.fromHex("#FFD700"), -- ver Colors.DivinoRainbow p/ o gradiente completo
}

-- Divino não é uma cor única: é um arco-íris (magenta -> dourado -> ciano -> violeta),
-- usado no gradiente animado da moldura (ver DivineBorder.lua)
Colors.DivinoRainbow = {
	Color3.fromHex("#FF007F"),
	Color3.fromHex("#FFD700"),
	Color3.fromHex("#00F0FF"),
	Color3.fromHex("#C800FF"),
}

-- Cores dos 15 clãs
Colors.Clans = {
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

return Colors
