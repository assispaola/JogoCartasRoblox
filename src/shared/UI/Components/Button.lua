--!strict
--[[
	Button.lua
	Botão "pop" reutilizável — usado em TODAS as telas, não só no HUD.
	Variantes: Primary, Secondary, Gold, Cyan, Danger, Ghost, Special (Renascer)
	Tamanhos: SM, MD, LG
	Estados: Default, Disabled

	Localização Rojo: ReplicatedStorage/Shared/UI/Components/Button

	USO:
		local Button = require(ReplicatedStorage.Shared.UI.Components.Button)

		local btn = Button.new({
			Text = "Abrir Pacote",
			Variant = "Primary",
			Size = "LG",
			Parent = someFrame,
			OnClick = function() print("clicou!") end,
		})

		Button.SetEnabled(btn, false) -- desabilita
]]

local TweenService = game:GetService("TweenService")

local DesignTokens = require(script.Parent.Parent.Parent.Config.DesignTokens)
local UIKit = require(script.Parent.Parent.Utils.UIKit)

local Colors = DesignTokens.Colors
local Typography = DesignTokens.Typography

export type ButtonVariant = "Primary" | "Secondary" | "Gold" | "Cyan" | "Danger" | "Ghost" | "Special"
export type ButtonSize = "SM" | "MD" | "LG"

export type ButtonProps = {
	Text: string,
	Variant: ButtonVariant?,
	Size: ButtonSize?,
	Icon: string?,
	Parent: Instance,
	LayoutOrder: number?,
	OnClick: (() -> ())?,
}

local VARIANT_STYLE: { [ButtonVariant]: { bg: Color3, shadow: Color3, text: Color3 } } = {
	Primary = { bg = Colors.Primary, shadow = Color3.fromHex("#1f34a8"), text = Color3.new(1, 1, 1) },
	Secondary = { bg = Colors.PanelHighlight, shadow = Color3.fromHex("#0c0e1f"), text = Colors.Text },
	Gold = { bg = Colors.Gold, shadow = Color3.fromHex("#8a5c00"), text = Color3.fromHex("#2a1a00") },
	Cyan = { bg = Colors.Cyan, shadow = Color3.fromHex("#0a6a91"), text = Color3.fromHex("#052030") },
	Danger = { bg = Colors.Danger, shadow = Color3.fromHex("#8f1f1f"), text = Color3.new(1, 1, 1) },
	Ghost = { bg = Colors.Ghost, shadow = Color3.fromHex("#14172c"), text = Colors.TextDim },
	Special = { bg = Colors.Renascimento, shadow = Color3.fromHex("#4c2d94"), text = Color3.new(1, 1, 1) },
}

local SIZE_STYLE: { [ButtonSize]: { height: number, textSize: number, padX: number, radius: number, shadowH: number } } = {
	SM = { height = 32, textSize = Typography.UI.Small, padX = 14, radius = 10, shadowH = 4 },
	MD = { height = 44, textSize = Typography.UI.Body, padX = 20, radius = 14, shadowH = 6 },
	LG = { height = 56, textSize = Typography.UI.Medium, padX = 28, radius = 18, shadowH = 8 },
}

local Button = {}

function Button.new(props: ButtonProps): CanvasGroup
	local variant: ButtonVariant = props.Variant or "Primary"
	local sizeKey: ButtonSize = props.Size or "MD"
	local style = VARIANT_STYLE[variant]
	local sizing = SIZE_STYLE[sizeKey]

	-- Wrapper controla a sombra "pop" (o botão real sobe/desce dentro dele).
	-- CanvasGroup permite esmaecer o botão inteiro de uma vez (estado Disabled).
	local wrapper = Instance.new("CanvasGroup")
	wrapper.Name = "Button_" .. props.Text:gsub("%s", "")
	wrapper.Size = UDim2.new(0, 0, 0, sizing.height + sizing.shadowH)
	wrapper.AutomaticSize = Enum.AutomaticSize.X
	wrapper.BackgroundTransparency = 1
	wrapper.LayoutOrder = props.LayoutOrder or 0
	wrapper.Parent = props.Parent

	-- Sombra sólida (fica visível embaixo do botão, cria efeito 3D)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 0, 0, sizing.height)
	shadow.Position = UDim2.new(0, 0, 0, sizing.shadowH)
	shadow.BackgroundColor3 = style.shadow
	shadow.BorderSizePixel = 0
	shadow.Parent = wrapper
	UIKit.Corner(sizing.radius).Parent = shadow

	local button = Instance.new("TextButton")
	button.Name = "Surface"
	button.Size = UDim2.new(1, 0, 0, sizing.height)
	button.Position = UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = style.bg
	button.AutoButtonColor = false
	button.Text = ""
	button.BorderSizePixel = 0
	button.Parent = wrapper
	UIKit.Corner(sizing.radius).Parent = button

	local padding = UIKit.Padding(0, { left = sizing.padX, right = sizing.padX })
	padding.Parent = button

	local layout = UIKit.ListLayout({
		direction = Enum.FillDirection.Horizontal,
		padding = 8,
		hAlign = Enum.HorizontalAlignment.Center,
		vAlign = Enum.VerticalAlignment.Center,
	})
	layout.Parent = button

	if props.Icon then
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, sizing.textSize + 2, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = props.Icon
		icon.TextSize = sizing.textSize
		icon.FontFace = Typography.Fonts.Display
		icon.TextColor3 = style.text
		icon.Parent = button
	end

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = props.Text
	label.FontFace = Typography.Fonts.Display
	label.TextSize = sizing.textSize
	label.TextColor3 = style.text
	label.Parent = button

	-- Feedback "pop": botão desce até encostar na sombra, sobe ao soltar
	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.08), {
			Position = UDim2.new(0, 0, 0, sizing.shadowH),
		}):Play()
	end)
	local function restore()
		TweenService:Create(button, TweenInfo.new(0.08), {
			Position = UDim2.new(0, 0, 0, 0),
		}):Play()
	end
	button.MouseButton1Up:Connect(restore)
	button.MouseLeave:Connect(restore)

	if props.OnClick then
		button.MouseButton1Click:Connect(props.OnClick)
	end

	wrapper:SetAttribute("Enabled", true)
	return wrapper
end

--- Habilita/desabilita um botão criado por Button.new (dim + bloqueia clique)
function Button.SetEnabled(wrapper: CanvasGroup, enabled: boolean)
	wrapper:SetAttribute("Enabled", enabled)
	local surface = wrapper:FindFirstChild("Surface") :: TextButton?
	if surface then
		surface.Active = enabled
	end
	TweenService:Create(wrapper, TweenInfo.new(0.15), {
		GroupTransparency = enabled and 0 or 0.55,
	}):Play()
end

return Button
