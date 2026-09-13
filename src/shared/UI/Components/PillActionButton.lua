--!strict
--[[
	PillActionButton.lua
	Botão pequeno "pill" (cantos levemente arredondados) com ícone à esquerda
	+ texto alinhado à direita — usado pros atalhos "Ir para a Base" e "Abrir
	Mochila" no Figma (node 16:194 "HUD").

	Localização Rojo: ReplicatedStorage/Shared/UI/Components/PillActionButton
]]

local CollectionService = game:GetService("CollectionService")

local DesignTokens = require(script.Parent.Parent.Parent.Config.DesignTokens)
local UIKit = require(script.Parent.Parent.Utils.UIKit)

local Colors = DesignTokens.Colors
local Typography = DesignTokens.Typography

export type PillActionButtonHandle = {
	Instance: ImageButton,
}

export type PillActionButtonProps = {
	Width: number,
	Height: number,
	BackgroundImage: string, -- fundo real (borda+gradiente já na imagem, sem ícone) — ver Icons.lua "Fundos de botão do HUD"
	IconAsset: string,
	Label: string,
	Parent: Instance,
	LayoutOrder: number?,
	OnClick: (() -> ())?,
}

local PillActionButton = {}
PillActionButton.__index = PillActionButton

function PillActionButton.new(props: PillActionButtonProps): PillActionButtonHandle
	local button = Instance.new("ImageButton")
	button.Name = "PillActionButton"
	button.Size = UDim2.new(0, props.Width, 0, props.Height)
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Image = props.BackgroundImage
	button.ScaleType = Enum.ScaleType.Stretch
	button.LayoutOrder = props.LayoutOrder or 0
	button.Parent = props.Parent
	CollectionService:AddTag(button, "TunerCard")

	UIKit.Padding(0, { left = 10, right = 12 }).Parent = button

	local layout = UIKit.ListLayout({
		direction = Enum.FillDirection.Horizontal,
		padding = 8,
		vAlign = Enum.VerticalAlignment.Center,
		hAlign = Enum.HorizontalAlignment.Center,
	})
	layout.Parent = button

	local iconSize = math.floor(props.Height * 0.68)
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, iconSize, 0, iconSize)
	icon.BackgroundTransparency = 1
	icon.Image = props.IconAsset
	icon.ScaleType = Enum.ScaleType.Fit
	icon.LayoutOrder = 1
	icon.Parent = button
	CollectionService:AddTag(icon, "TunerIcon")

	-- Wrapper SEM UIListLayout próprio: as cópias do contorno grosso
	-- (UIKit.TextThickOutline) são criadas como IRMÃS do label, parentadas
	-- em label.Parent — se isso fosse o `button` direto (que TEM o
	-- UIListLayout do ícone+texto), cada cópia viraria um item de lista à
	-- parte, e o texto apareceria repetido várias vezes em fila. O wrapper
	-- isola isso: ele é o item de lista (LayoutOrder=2), e por dentro não
	-- tem layout nenhum, então as cópias só se empilham na mesma posição.
	local labelWrapper = Instance.new("Frame")
	labelWrapper.Name = "LabelWrapper"
	labelWrapper.Size = UDim2.new(1, -(iconSize + 8), 1, 0)
	labelWrapper.BackgroundTransparency = 1
	labelWrapper.LayoutOrder = 2
	labelWrapper.Parent = button

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = props.Label
	label.FontFace = Typography.Fonts.HUDLabel
	-- Estes pills são bem menores (37px de altura) que os outros botões
	-- brancos da HUD (sidebar/Renascimento, tiles de 62-80px) — usar o
	-- mesmo Typography.HUDWhiteLabel.Size (22) aqui estourava a caixa e
	-- sobrepunha o ícone. Fonte + contorno proporcionalmente menores.
	label.TextSize = 15
	label.TextColor3 = Colors.Text
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.ZIndex = 2
	label.Parent = labelWrapper

	UIKit.TextOutline(label)
	UIKit.TextThickOutline(label, 1)

	UIKit.ApplyPressFeedback(button, 0.95)

	if props.OnClick then
		button.MouseButton1Click:Connect(props.OnClick)
	end

	local self = setmetatable({
		Instance = button,
	}, PillActionButton) :: any

	return self
end

return PillActionButton
