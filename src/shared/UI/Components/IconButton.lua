--!strict
--[[
	IconButton.lua
	Botão quadrado de ícone com badge numérico opcional.
	Usado em: TopBar (🎁 🔔 ⚙️), Sidebar (ícones de navegação).

	Localização Rojo: ReplicatedStorage/Shared/UI/Components/IconButton
]]

local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local DesignTokens = require(script.Parent.Parent.Parent.Config.DesignTokens)
local UIKit = require(script.Parent.Parent.Utils.UIKit)

local Colors = DesignTokens.Colors
local Typography = DesignTokens.Typography

export type IconButtonHandle = {
	Instance: TextButton,
	SetBadge: (self: IconButtonHandle, count: number) -> (),
	SetActive: (self: IconButtonHandle, active: boolean) -> (),
}

export type IconButtonProps = {
	Icon: string?, -- legado: emoji/texto (usar quando IconAsset não for fornecido)
	IconAsset: string?, -- rbxassetid:// vindo de Icons.Get(...) — tem prioridade sobre Icon
	AccentColor: Color3?, -- cor da borda/glow; default Colors.Border (neutro)
	Size: number?,
	Parent: Instance,
	LayoutOrder: number?,
	OnClick: (() -> ())?,
}

local IconButton = {}
IconButton.__index = IconButton

function IconButton.new(props: IconButtonProps): IconButtonHandle
	local size = props.Size or 44
	local accent = props.AccentColor or Colors.Border

	local button = Instance.new("TextButton")
	button.Name = "IconButton"
	button.Size = UDim2.new(0, size, 0, size)
	button.BackgroundColor3 = Colors.Panel
	button.BackgroundTransparency = 0.4 -- fundo translúcido (era quase opaco)
	button.AutoButtonColor = false
	button.Text = ""
	button.LayoutOrder = props.LayoutOrder or 0
	button.Parent = props.Parent
	UIKit.Corner(math.floor(size * 0.3)).Parent = button

	-- Glow: stroke largo e bem transparente por trás de um stroke fino e
	-- nítido por cima — as duas UIStroke são filhas independentes do botão,
	-- então empilham sem precisar de um ImageLabel de glow separado.
	local glowStroke = UIKit.Stroke(accent, 6, 0.82)
	glowStroke.Name = "GlowStroke"
	glowStroke.Parent = button

	local crispStroke = UIKit.Stroke(accent, 2, 0.15) -- mais saturado, compensa o fundo translúcido
	crispStroke.Name = "CrispStroke"
	crispStroke.Parent = button

	if props.IconAsset then
		local image = Instance.new("ImageLabel")
		image.Name = "Icon"
		image.Size = UDim2.new(0, math.floor(size * 0.55), 0, math.floor(size * 0.55))
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.new(0.5, 0, 0.5, 0)
		image.BackgroundTransparency = 1
		image.Image = props.IconAsset
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = button
		CollectionService:AddTag(image, "TunerIcon")
	else
		local label = Instance.new("TextLabel")
		label.Name = "Icon"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = props.Icon or ""
		label.TextSize = math.floor(size * 0.42)
		label.FontFace = Typography.Fonts.Display
		label.TextColor3 = Colors.Text
		label.Parent = button
	end

	UIKit.ApplyPressFeedback(button, 0.9)

	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.Size = UDim2.new(0, 20, 0, 20)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(1, -2, 0, -2)
	badge.BackgroundColor3 = Colors.Danger
	badge.Text = ""
	badge.TextColor3 = Color3.new(1, 1, 1)
	badge.FontFace = Typography.Fonts.Display
	badge.TextSize = 11
	badge.Visible = false
	badge.ZIndex = 2
	badge.Parent = button
	UIKit.Corner(999).Parent = badge
	UIKit.Stroke(Colors.Background, 2, 0).Parent = badge

	if props.OnClick then
		button.MouseButton1Click:Connect(props.OnClick)
	end

	local self = setmetatable({
		Instance = button,
		_badge = badge,
		_glowStroke = glowStroke,
		_crispStroke = crispStroke,
		_accent = accent,
	}, IconButton) :: any
	return self
end

function IconButton.SetBadge(self: IconButtonHandle, count: number)
	local badge = (self :: any)._badge :: TextLabel
	badge.Visible = count > 0
	badge.Text = count > 9 and "9+" or tostring(count)
end

function IconButton.SetActive(self: IconButtonHandle, active: boolean)
	local s = self :: any
	local button = self.Instance
	local glowStroke = s._glowStroke :: UIStroke
	local crispStroke = s._crispStroke :: UIStroke

	TweenService:Create(button, TweenInfo.new(0.15), {
		BackgroundColor3 = active and Colors.PanelHighlight or Colors.Panel,
	}):Play()
	TweenService:Create(glowStroke, TweenInfo.new(0.15), {
		Transparency = active and 0.55 or 0.82,
	}):Play()
	TweenService:Create(crispStroke, TweenInfo.new(0.15), {
		Transparency = active and 0.05 or 0.15,
	}):Play()
end

return IconButton
