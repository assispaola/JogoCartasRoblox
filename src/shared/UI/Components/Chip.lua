--!strict
--[[
	Chip.lua
	Pill de moeda/estatística — $, 💎, $/s, Renascimento.
	Cada chip é independente (não uma barra contígua), igual ao protótipo.

	Localização Rojo: ReplicatedStorage/Shared/UI/Components/Chip

	USO:
		local chip = Chip.new({
			Icon = "💚",
			Value = "1.250.000",
			ValueColor = Colors.Money,
			Parent = topBarRow,
			ShowAdd = true,
			AddButtonVariant = "Gold",
			OnAdd = function() print("abrir loja de diamante") end,
		})
		chip:SetValue("1.300.000")
]]

local CollectionService = game:GetService("CollectionService")

local DesignTokens = require(script.Parent.Parent.Parent.Config.DesignTokens)
local UIKit = require(script.Parent.Parent.Utils.UIKit)

local Colors = DesignTokens.Colors
local Typography = DesignTokens.Typography

export type ChipHandle = {
	Instance: Frame,
	SetValue: (self: ChipHandle, text: string, animateFrom: number?, animateTo: number?, formatFn: ((number) -> string)?) -> (),
	SetSubtitle: (self: ChipHandle, text: string) -> (),
}

export type ChipProps = {
	Icon: string?, -- legado: emoji/texto (usar quando IconAsset não for fornecido)
	IconAsset: string?, -- rbxassetid:// vindo de Icons.Get(...) — tem prioridade sobre Icon
	AccentColor: Color3?, -- cor da borda/glow; default Colors.Border (neutro)
	Value: string,
	ValueColor: Color3?,
	Subtitle: string?,
	Parent: Instance,
	LayoutOrder: number?,
	Height: number?, -- default 38 (compacto — TopBar usa isso, não mais 44)
	ShowAdd: boolean?,
	OnAdd: (() -> ())?,
}

local Chip = {}
Chip.__index = Chip

function Chip.new(props: ChipProps): ChipHandle
	local accent = props.AccentColor or Colors.Border
	local height = props.Height or 38

	local root = Instance.new("Frame")
	root.Name = "Chip"
	root.AutomaticSize = Enum.AutomaticSize.X
	root.Size = UDim2.new(0, 0, 0, height)
	root.BackgroundColor3 = Colors.Panel
	root.BackgroundTransparency = 0.4 -- fundo translúcido (era quase opaco)
	root.LayoutOrder = props.LayoutOrder or 0
	root.Parent = props.Parent
	CollectionService:AddTag(root, "TunerCard")
	UIKit.Corner(999).Parent = root

	-- Glow sutil (stroke largo/transparente) + borda nítida e mais SATURADA
	-- por cima (compensa o fundo mais translúcido, mantém legibilidade) — na
	-- cor de destaque do chip, mesma técnica usada em IconButton.lua.
	local glowStroke = UIKit.Stroke(accent, 5, 0.8)
	glowStroke.Name = "GlowStroke"
	glowStroke.Parent = root
	local crispStroke = UIKit.Stroke(accent, 2, 0.15)
	crispStroke.Name = "CrispStroke"
	crispStroke.Parent = root

	UIKit.Padding(0, { left = 12, right = props.ShowAdd and 5 or 12 }).Parent = root

	local layout = UIKit.ListLayout({
		direction = Enum.FillDirection.Horizontal,
		padding = 7,
		vAlign = Enum.VerticalAlignment.Center,
	})
	layout.Parent = root

	-- Ícone generoso em relação ao chip (era 20px fixo independente da
	-- altura; agora ~62% da altura do chip).
	local iconSize = math.floor(height * 0.62)

	if props.IconAsset then
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, iconSize, 0, iconSize)
		icon.BackgroundTransparency = 1
		icon.Image = props.IconAsset
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = root
		CollectionService:AddTag(icon, "TunerIcon")
	else
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, iconSize, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = props.Icon or ""
		icon.TextSize = iconSize
		icon.FontFace = Typography.Fonts.Display
		icon.Parent = root
	end

	-- Coluna de texto (valor + subtítulo opcional, ex: multiplicador do Renascimento)
	local textCol = Instance.new("Frame")
	textCol.AutomaticSize = Enum.AutomaticSize.XY
	textCol.Size = UDim2.new(0, 0, 0, 0)
	textCol.BackgroundTransparency = 1
	textCol.Parent = root
	local colLayout = UIKit.ListLayout({ direction = Enum.FillDirection.Vertical })
	colLayout.Parent = textCol

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.AutomaticSize = Enum.AutomaticSize.X
	valueLabel.Size = UDim2.new(0, 0, 0, 20)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = props.Value
	-- Bold + tamanho maior (era Mono/Medium 18px — pedido explícito de ficar
	-- mais "gritante"/destacado).
	valueLabel.FontFace = Typography.Fonts.MonoBold
	valueLabel.TextSize = Typography.Number.LG - 2
	valueLabel.TextColor3 = props.ValueColor or Colors.Text
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.Parent = textCol

	local subtitleLabel: TextLabel? = nil
	if props.Subtitle then
		local subtitle = Instance.new("TextLabel")
		subtitle.Name = "Subtitle"
		subtitle.AutomaticSize = Enum.AutomaticSize.X
		subtitle.Size = UDim2.new(0, 0, 0, 14)
		subtitle.BackgroundTransparency = 1
		subtitle.Text = props.Subtitle
		subtitle.FontFace = Typography.Fonts.MonoBold
		subtitle.TextSize = Typography.Number.XS
		subtitle.TextColor3 = Colors.TextDim
		subtitle.TextXAlignment = Enum.TextXAlignment.Left
		subtitle.Parent = textCol
		subtitleLabel = subtitle
	end

	if props.ShowAdd then
		local addSize = math.floor(height * 0.68)
		local addBtn = Instance.new("TextButton")
		addBtn.Size = UDim2.new(0, addSize, 0, addSize)
		addBtn.BackgroundColor3 = Colors.Gold
		addBtn.AutoButtonColor = false
		addBtn.Text = "+"
		addBtn.FontFace = Typography.Fonts.Display
		addBtn.TextSize = math.floor(addSize * 0.6)
		addBtn.TextColor3 = Color3.fromHex("#2a1a00")
		addBtn.Parent = root
		UIKit.Corner(999).Parent = addBtn
		UIKit.ApplyPressFeedback(addBtn, 0.88)
		if props.OnAdd then
			addBtn.MouseButton1Click:Connect(props.OnAdd)
		end
	end

	local self = setmetatable({
		Instance = root,
		_valueLabel = valueLabel,
		_subtitleLabel = subtitleLabel,
	}, Chip) :: any

	return self
end

--- Define o texto do valor. Se animateFrom/animateTo + formatFn forem passados,
--- anima a contagem (usado pra $ e 💎 subindo suavemente).
function Chip.SetValue(self: ChipHandle, text: string, animateFrom: number?, animateTo: number?, formatFn: ((number) -> string)?)
	local label = (self :: any)._valueLabel :: TextLabel
	if animateFrom ~= nil and animateTo ~= nil and formatFn ~= nil then
		UIKit.AnimateNumber(label, animateFrom, animateTo, formatFn, 0.5)
	else
		label.Text = text
	end
end

function Chip.SetSubtitle(self: ChipHandle, text: string)
	local label = (self :: any)._subtitleLabel :: TextLabel?
	if label then
		label.Text = text
	end
end

return Chip
