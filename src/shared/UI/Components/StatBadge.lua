--!strict
--[[
	StatBadge.lua
	Display (não clicável) com a arte real de fundo (borda+gradiente já
	"baked" na imagem, ver Icons.lua), ícone + texto lado a lado — usado pro
	contador de Diamante e pro badge de Renascimento na topbar-direito do
	Figma (node 16:194 "HUD").

	Dois formatos, escolhidos por qual prop é passada:
	- Value only (Diamante): ícone + um valor grande, uma linha.
	- Title + Value (Renascimento): ícone + título em cima, valor embaixo.

	Localização Rojo: ReplicatedStorage/Shared/UI/Components/StatBadge
]]

local CollectionService = game:GetService("CollectionService")

local DesignTokens = require(script.Parent.Parent.Parent.Config.DesignTokens)
local UIKit = require(script.Parent.Parent.Utils.UIKit)

local Colors = DesignTokens.Colors
local Typography = DesignTokens.Typography

export type StatBadgeHandle = {
	Instance: ImageLabel,
	SetValue: (self: StatBadgeHandle, text: string) -> (),
	SetTitle: (self: StatBadgeHandle, text: string) -> (),
}

export type StatBadgeProps = {
	Width: number,
	Height: number,
	BackgroundImage: string, -- fundo real (borda+gradiente já na imagem, sem ícone) — ver Icons.lua "Fundos de botão do HUD"
	IconAsset: string,
	IconSize: number?,
	IconX: number?, -- posição X do ícone (default 13, igual ao Figma pro Diamante)
	TextLeft: number?, -- posição X do texto (default 69, igual ao Figma pro Diamante) — NÃO deriva de IconX+IconSize, cada badge do Figma tem seu próprio gap
	Title: string?, -- rótulo em cima (ex: "Renascimento"); se nil, só o Value grande aparece
	TitleY: number?, -- default 12 (Figma)
	TitleTextSize: number?, -- default 18
	TitleStrokeThickness: number?, -- default 2 — espessura do contorno grosso do Title, só usado com Title
	ValueY: number?, -- default 35 (Figma) — só usado quando Title existe; sem Title o valor fica centralizado verticalmente
	Value: string,
	ValueColor: Color3?,
	ValueTextSize: number?, -- default 28 (Figma) sem Title / 14 com Title
	ValueFont: Font?, -- default Typography.Fonts.HUDValue (Rubik ExtraBold) sem Title / HUDValueBold com Title
	ValueStrokeThickness: number?, -- default 2 — espessura do contorno grosso nas letras do Value
	Parent: Instance,
	LayoutOrder: number?,
}

local StatBadge = {}
StatBadge.__index = StatBadge

function StatBadge.new(props: StatBadgeProps): StatBadgeHandle
	local root = Instance.new("ImageLabel")
	root.Name = "StatBadge"
	root.Size = UDim2.new(0, props.Width, 0, props.Height)
	root.BackgroundTransparency = 1
	root.Image = props.BackgroundImage
	root.ScaleType = Enum.ScaleType.Stretch
	root.LayoutOrder = props.LayoutOrder or 0
	root.Parent = props.Parent
	CollectionService:AddTag(root, "TunerCard")

	local iconSize = props.IconSize or 44
	local iconX = props.IconX or 13
	local textLeft = props.TextLeft or 69

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, iconSize, 0, iconSize)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, iconX, 0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Image = props.IconAsset
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = root
	CollectionService:AddTag(icon, "TunerIcon")

	local hasTitle = props.Title ~= nil and props.Title ~= ""

	local titleLabel: TextLabel? = nil
	local titleOutlineCopies: { TextLabel }? = nil
	local valueLabel: TextLabel
	local valueOutlineCopies: { TextLabel }? = nil

	if hasTitle then
		titleLabel = Instance.new("TextLabel")
		local t = titleLabel :: TextLabel
		t.Name = "Title"
		t.Size = UDim2.new(1, -(textLeft + 6), 0, 26)
		t.Position = UDim2.new(0, textLeft, 0, props.TitleY or 12)
		t.BackgroundTransparency = 1
		t.Text = props.Title :: string
		t.FontFace = Typography.Fonts.HUDLabel
		t.TextSize = props.TitleTextSize or 18
		t.TextColor3 = Colors.Text
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.ZIndex = 2
		t.Parent = root

		UIKit.TextOutline(t)
		titleOutlineCopies = UIKit.TextThickOutline(t, props.TitleStrokeThickness or 2)

		valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Size = UDim2.new(1, -(textLeft + 12), 0, 18)
		valueLabel.Position = UDim2.new(0, textLeft, 0, props.ValueY or 35)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = props.Value
		valueLabel.FontFace = props.ValueFont or Typography.Fonts.HUDValueBold
		valueLabel.TextSize = props.ValueTextSize or 14
		valueLabel.TextColor3 = props.ValueColor or Colors.Text
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.ZIndex = 2
		valueLabel.Parent = root

		UIKit.TextOutline(valueLabel)
		valueOutlineCopies = UIKit.TextThickOutline(valueLabel, props.ValueStrokeThickness or 2)
	else
		valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Size = UDim2.new(1, -(textLeft + 12), 1, 0)
		valueLabel.Position = UDim2.new(0, textLeft, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = props.Value
		valueLabel.FontFace = props.ValueFont or Typography.Fonts.HUDValue
		valueLabel.TextSize = props.ValueTextSize or 28
		valueLabel.TextColor3 = props.ValueColor or Colors.Text
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
		valueLabel.ZIndex = 2
		valueLabel.Parent = root

		UIKit.TextOutline(valueLabel)
		valueOutlineCopies = UIKit.TextThickOutline(valueLabel, props.ValueStrokeThickness or 2)
	end

	local self = setmetatable({
		Instance = root,
		_titleLabel = titleLabel,
		_titleOutlineCopies = titleOutlineCopies,
		_valueLabel = valueLabel,
		_valueOutlineCopies = valueOutlineCopies,
	}, StatBadge) :: any

	return self
end

local function setTextEverywhere(label: TextLabel, outlineCopies: { TextLabel }?, text: string)
	label.Text = text
	if outlineCopies then
		for _, copy in outlineCopies do
			copy.Text = text
		end
	end
end

function StatBadge.SetValue(self: StatBadgeHandle, text: string)
	local s = self :: any
	setTextEverywhere(s._valueLabel :: TextLabel, s._valueOutlineCopies :: { TextLabel }?, text)
end

function StatBadge.SetTitle(self: StatBadgeHandle, text: string)
	local s = self :: any
	local label = s._titleLabel :: TextLabel?
	if label then
		setTextEverywhere(label, s._titleOutlineCopies :: { TextLabel }?, text)
	end
end

return StatBadge
