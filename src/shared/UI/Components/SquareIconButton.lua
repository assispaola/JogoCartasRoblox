--!strict
--[[
	SquareIconButton.lua
	Botão quadrado com a arte real do Figma como fundo (borda + gradiente já
	"baked" na imagem, node 16:194 "HUD"): ícone centralizado por cima (via
	Icons.lua, não incluído na imagem de fundo) + rótulo opcional abaixo
	(sidebar-esquerda: Loja/Pacotes/Álbum/Batalha/Altar; topbar-direito:
	Presente/Config, sem rótulo).

	Localização Rojo: ReplicatedStorage/Shared/UI/Components/SquareIconButton
]]

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local DesignTokens = require(script.Parent.Parent.Parent.Config.DesignTokens)
local UIKit = require(script.Parent.Parent.Utils.UIKit)

local Colors = DesignTokens.Colors
local Typography = DesignTokens.Typography

export type SquareIconButtonHandle = {
	Instance: ImageButton,
	SetActive: (self: SquareIconButtonHandle, active: boolean) -> (),
}

export type SquareIconButtonProps = {
	Width: number,
	Height: number,
	Radius: number?, -- só molda o stroke de "ativo" (a arte real já vem com cantos arredondados)
	BackgroundImage: string, -- fundo real (borda+gradiente já na imagem, sem ícone) — ver Icons.lua "Fundos de botão do HUD"
	IconAsset: string,
	IconSize: number?,
	Label: string?, -- texto abaixo do ícone (opcional — ex: "Loja")
	Parent: Instance,
	LayoutOrder: number?,
	OnClick: (() -> ())?,
}

local SquareIconButton = {}
SquareIconButton.__index = SquareIconButton

function SquareIconButton.new(props: SquareIconButtonProps): SquareIconButtonHandle
	local width = props.Width
	local height = props.Height
	local hasLabel = props.Label ~= nil and props.Label ~= ""

	local button = Instance.new("ImageButton")
	button.Name = "SquareIconButton"
	button.Size = UDim2.new(0, width, 0, height)
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Image = props.BackgroundImage
	button.ScaleType = Enum.ScaleType.Stretch
	button.LayoutOrder = props.LayoutOrder or 0
	button.Parent = props.Parent
	CollectionService:AddTag(button, "TunerCard")

	-- Highlight de "ativo" (aba selecionada): stroke extra por cima da arte
	-- real, invisível por padrão (Transparency 1) — a arte não tem estado de
	-- seleção própria.
	UIKit.Corner(props.Radius or 8).Parent = button
	local activeStroke = UIKit.Stroke(Colors.Text, 3, 1)
	activeStroke.Parent = button

	local iconSize = props.IconSize or math.floor(math.min(width, height) * 0.62)
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, iconSize, 0, iconSize)
	icon.AnchorPoint = Vector2.new(0.5, hasLabel and 0 or 0.5)
	icon.Position = hasLabel and UDim2.new(0.5, 0, 0, 8) or UDim2.new(0.5, 0, 0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Image = props.IconAsset
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = button
	CollectionService:AddTag(icon, "TunerIcon")

	if hasLabel then
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, -6, 0, 22)
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.new(0.5, 0, 1, -6)
		label.BackgroundTransparency = 1
		label.Text = props.Label :: string
		-- Mesma fonte + tamanho + contorno de TODO texto branco de botão da
		-- HUD (ver Typography.HUDWhiteLabel) — sidebar, pills de ação,
		-- "Renascimento" (Fredoka SemiBold, não Medium).
		label.FontFace = Typography.Fonts.HUDLabel
		label.TextSize = Typography.HUDWhiteLabel.Size
		label.TextColor3 = Colors.Text
		label.TextScaled = false
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.ZIndex = 2
		label.Parent = button

		UIKit.TextOutline(label)
		UIKit.TextThickOutline(label, Typography.HUDWhiteLabel.StrokeThickness)
	end

	UIKit.ApplyPressFeedback(button, 0.94)

	if props.OnClick then
		button.MouseButton1Click:Connect(props.OnClick)
	end

	local self = setmetatable({
		Instance = button,
		_activeStroke = activeStroke,
	}, SquareIconButton) :: any

	return self
end

function SquareIconButton.SetActive(self: SquareIconButtonHandle, active: boolean)
	local stroke = (self :: any)._activeStroke :: UIStroke
	TweenService:Create(stroke, TweenInfo.new(0.15), {
		Transparency = active and 0.15 or 1,
	}):Play()
end

return SquareIconButton
