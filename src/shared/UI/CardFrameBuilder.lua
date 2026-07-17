--[[
	CardFrameBuilder.lua
	Constrói visualmente um card completo (moldura + badge de Despertar +
	selo de texto) em cima de um ImageLabel de arte já existente. Segue a
	especificação fechada em moldura_raridade_final.md.

	Uso típico (dentro de um script client-side de UI):
		local CardFrameBuilder = require(...)
		local cardFrame = CardFrameBuilder.Build({
			parent = algumFrame,
			artImageId = "rbxassetid://123456", -- a ilustração da criatura
			rarity = "Lendário",
			grade = 8.5,
			creatureName = "Kitsune das Nove Caudas",
		})

	Local: ReplicatedStorage/Shared/UI/CardFrameBuilder.lua (client/shared -
	isso é só construção visual, não tem lógica de servidor nenhuma)
]]

local CardFrameBuilder = {}

-- Gradiente metálico por raridade (5 pontos de parada: escuro→claro→médio→claro→escuro)
-- Direto da especificação em moldura_raridade_final.md
local RARITY_STYLES = {
	Bronze = {
		gradient = { Color3.fromHex("5C3A1A"), Color3.fromHex("C98A4B"), Color3.fromHex("8C5A2B"), Color3.fromHex("C98A4B"), Color3.fromHex("5C3A1A") },
		textColor = Color3.fromHex("C98A4B"),
		strokeWidth = 2.5,
		complexity = 1,
	},
	Prata = {
		gradient = { Color3.fromHex("6E747C"), Color3.fromHex("E8ECF0"), Color3.fromHex("B8BEC7"), Color3.fromHex("E8ECF0"), Color3.fromHex("6E747C") },
		textColor = Color3.fromHex("D3D8DE"),
		strokeWidth = 2.5,
		complexity = 2,
	},
	Ouro = {
		gradient = { Color3.fromHex("8A6410"), Color3.fromHex("FFE066"), Color3.fromHex("D4A017"), Color3.fromHex("FFE066"), Color3.fromHex("8A6410") },
		textColor = Color3.fromHex("FFD34D"),
		strokeWidth = 3,
		complexity = 3,
	},
	Platina = {
		gradient = { Color3.fromHex("155E75"), Color3.fromHex("A5F3FC"), Color3.fromHex("22D3EE"), Color3.fromHex("A5F3FC"), Color3.fromHex("155E75") },
		textColor = Color3.fromHex("A5F3FC"),
		strokeWidth = 3,
		complexity = 4,
	},
	["Lendário"] = {
		gradient = { Color3.fromHex("5B1E7A"), Color3.fromHex("E0AAFF"), Color3.fromHex("9B4DCA"), Color3.fromHex("E0AAFF"), Color3.fromHex("5B1E7A") },
		textColor = Color3.fromHex("E0AAFF"),
		strokeWidth = 3.5,
		complexity = 5,
		glowBackground = true,
	},
	["Mítico"] = {
		gradient = { Color3.fromHex("FF6EC7"), Color3.fromHex("FFD86C"), Color3.fromHex("6EE7FF"), Color3.fromHex("C77DFF"), Color3.fromHex("FF6EC7") },
		textColor = Color3.fromHex("FFF6E0"),
		strokeWidth = 3.5,
		complexity = 6,
		glowBackground = true,
		particles = true,
	},
}

-- Cria o UIGradient com as 5 paradas de cor do material daquela raridade.
local function createMetallicGradient(style)
	local gradient = Instance.new("UIGradient")
	local n = #style.gradient
	local keypoints = {}
	for i, color in style.gradient do
		local time = (i - 1) / (n - 1)
		table.insert(keypoints, ColorSequenceKeypoint.new(time, color))
	end
	gradient.Color = ColorSequence.new(keypoints)
	gradient.Rotation = 45 -- diagonal, igual ao mockup (0%→100% em ângulo)
	return gradient
end

-- Monta os 4 pequenos acentos de canto (pontos/losangos/flourish), cuja
-- forma varia por raridade - implementados como pequenos Frames rotacionados
-- 45° (losango) ou Circle (ponto), reaproveitando a mesma cor do gradiente.
local function addCornerAccents(parent, style, cardSize)
	if style.complexity < 2 then
		return -- Bronze não tem acento de canto
	end

	local shape = (style.complexity == 4) and "diamond" or "dot"
	local positions = {
		Vector2.new(10, 10),
		Vector2.new(cardSize.X - 10, 10),
		Vector2.new(10, cardSize.Y - 10),
		Vector2.new(cardSize.X - 10, cardSize.Y - 10),
	}

	for _, pos in positions do
		local accent = Instance.new("Frame")
		accent.Size = UDim2.fromOffset(6, 6)
		accent.Position = UDim2.fromOffset(pos.X - 3, pos.Y - 3)
		accent.BackgroundColor3 = style.gradient[3] -- tom médio do material
		accent.BorderSizePixel = 0
		accent.Parent = parent

		if shape == "diamond" then
			accent.Rotation = 45
		else
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0) -- círculo perfeito
			corner.Parent = accent
		end
	end
end

-- Monta o card completo. `params` é uma tabela com:
--   parent (Instance), artImageId (string), rarity (string), grade (number),
--   creatureName (string), size (UDim2, opcional - padrão 180x270 escalado)
function CardFrameBuilder.Build(params)
	local style = RARITY_STYLES[params.rarity]
	if not style then
		warn("[CardFrameBuilder] Raridade desconhecida: " .. tostring(params.rarity))
		return nil
	end

	local size = params.size or UDim2.fromOffset(180, 270)

	-- Container principal do card
	local card = Instance.new("Frame")
	card.Name = "Card_" .. params.creatureName
	card.Size = size
	card.BackgroundTransparency = 1
	card.Parent = params.parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 6)
	cardCorner.Parent = card

	-- 1) A arte da criatura (ilustração pura, sem moldura/texto - já vem assim)
	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.Size = UDim2.fromScale(1, 1)
	art.Image = params.artImageId
	art.ScaleType = Enum.ScaleType.Crop
	art.BackgroundTransparency = 1
	art.Parent = card
	local artCorner = Instance.new("UICorner")
	artCorner.CornerRadius = UDim.new(0, 6)
	artCorner.Parent = art

	-- 2) Brilho de fundo sutil (só Lendário/Mítico)
	if style.glowBackground then
		local glow = Instance.new("Frame")
		glow.Size = UDim2.fromScale(1, 1)
		glow.BackgroundColor3 = style.gradient[3]
		glow.BackgroundTransparency = 0.9
		glow.BorderSizePixel = 0
		glow.ZIndex = 2
		glow.Parent = card
		local glowCorner = Instance.new("UICorner")
		glowCorner.CornerRadius = UDim.new(0, 6)
		glowCorner.Parent = glow
	end

	-- 3) A moldura (UIStroke com o gradiente metálico por cima)
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Thickness = style.strokeWidth
	frameStroke.Color = style.gradient[3]
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Parent = card
	createMetallicGradient(style).Parent = frameStroke

	-- 4) Acentos de canto (varia por raridade)
	addCornerAccents(card, style, Vector2.new(size.X.Offset, size.Y.Offset))

	-- 5) Badge de Despertar (canto superior esquerdo)
	local gradeBadge = Instance.new("Frame")
	gradeBadge.Size = UDim2.fromOffset(32, 18)
	gradeBadge.Position = UDim2.fromOffset(6, 6)
	gradeBadge.BackgroundColor3 = Color3.fromHex("0B0E1A")
	gradeBadge.BackgroundTransparency = 0.2
	gradeBadge.ZIndex = 3
	gradeBadge.Parent = card
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 3)
	badgeCorner.Parent = gradeBadge
	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Thickness = 0.75
	badgeStroke.Color = style.gradient[3]
	badgeStroke.Parent = gradeBadge

	local gradeText = Instance.new("TextLabel")
	gradeText.Size = UDim2.fromScale(1, 1)
	gradeText.BackgroundTransparency = 1
	gradeText.Text = string.format("%.1f", params.grade)
	gradeText.TextColor3 = Color3.fromHex("EDE6D6")
	gradeText.Font = Enum.Font.GothamBold
	gradeText.TextSize = 12
	gradeText.ZIndex = 4
	gradeText.Parent = gradeBadge

	-- 6) Selo de texto (faixa inferior: raridade + nome da criatura)
	local labelStrip = Instance.new("Frame")
	labelStrip.Size = UDim2.new(1, -20, 0, 34)
	labelStrip.Position = UDim2.new(0, 10, 1, -42)
	labelStrip.BackgroundColor3 = Color3.fromHex("0B0E1A")
	labelStrip.BackgroundTransparency = 0.2
	labelStrip.ZIndex = 3
	labelStrip.Parent = card
	local stripCorner = Instance.new("UICorner")
	stripCorner.CornerRadius = UDim.new(0, 4)
	stripCorner.Parent = labelStrip

	local rarityText = Instance.new("TextLabel")
	rarityText.Size = UDim2.new(1, 0, 0.45, 0)
	rarityText.BackgroundTransparency = 1
	rarityText.Text = string.upper(params.rarity)
	rarityText.TextColor3 = style.textColor
	rarityText.Font = Enum.Font.GothamBold
	rarityText.TextSize = 9
	rarityText.ZIndex = 4
	rarityText.Parent = labelStrip

	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(1, 0, 0.55, 0)
	nameText.Position = UDim2.new(0, 0, 0.45, 0)
	nameText.BackgroundTransparency = 1
	nameText.Text = params.creatureName
	nameText.TextColor3 = Color3.fromHex("EDE6D6")
	nameText.Font = Enum.Font.Gotham
	nameText.TextSize = 10
	nameText.ZIndex = 4
	nameText.Parent = labelStrip

	return card
end

return CardFrameBuilder
