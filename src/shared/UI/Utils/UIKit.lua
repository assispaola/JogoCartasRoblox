--!strict
--[[
	UIKit.lua
	Helpers de construção de UI reutilizados por todos os componentes
	(Button, Chip, IconButton, ProgressBar, TopBar, Sidebar, etc.)
	Evita repetir boilerplate de UICorner/UIStroke/UIPadding em cada arquivo.

	Localização Rojo: ReplicatedStorage/Shared/UI/Utils/UIKit
]]

local TweenService = game:GetService("TweenService")

local UIKit = {}

function UIKit.Corner(radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	return c
end

function UIKit.Stroke(color: Color3, thickness: number?, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 2
	s.Transparency = transparency or 0.15
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

type PaddingOverrides = { left: number?, right: number?, top: number?, bottom: number? }

function UIKit.Padding(all: number?, overrides: PaddingOverrides?): UIPadding
	local p = Instance.new("UIPadding")
	local base = all or 0
	local o: PaddingOverrides = overrides or {}
	p.PaddingLeft = UDim.new(0, o.left or base)
	p.PaddingRight = UDim.new(0, o.right or base)
	p.PaddingTop = UDim.new(0, o.top or base)
	p.PaddingBottom = UDim.new(0, o.bottom or base)
	return p
end

function UIKit.ListLayout(props: {
	direction: Enum.FillDirection?,
	padding: number?,
	hAlign: Enum.HorizontalAlignment?,
	vAlign: Enum.VerticalAlignment?,
}): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = props.direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, props.padding or 0)
	layout.HorizontalAlignment = props.hAlign or Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = props.vAlign or Enum.VerticalAlignment.Top
	return layout
end

--- Anima um TextLabel numérico contando suavemente de um valor até outro.
--- formatFn recebe o valor corrente e retorna a string a exibir.
function UIKit.AnimateNumber(label: TextLabel, fromValue: number, toValue: number, formatFn: (number) -> string, duration: number?)
	local holder = Instance.new("NumberValue")
	holder.Value = fromValue

	local tween = TweenService:Create(
		holder,
		TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = toValue }
	)

	local connection: RBXScriptConnection
	connection = holder.Changed:Connect(function(v: number)
		label.Text = formatFn(v)
	end)

	tween:Play()
	tween.Completed:Connect(function()
		connection:Disconnect()
		holder:Destroy()
	end)
end

--- Contorno preto nítido nas LETRAS de um TextLabel (Figma: Stroke
--- "Outside", 100% opaco) — usado nos rótulos de texto E nos valores
--- numéricos da HUD (ex: "3.634", "x1.5", "$ 456.238"). IMPORTANTE: isso usa
--- as propriedades nativas TextStrokeColor3/TextStrokeTransparency do
--- TextLabel — NÃO um UIStroke. Um UIStroke parentado a um TextLabel
--- contorna a CAIXA retangular do label (vira um "chip" sólido atrás do
--- texto), não os glifos; só as propriedades nativas de texto contornam
--- letra por letra.
function UIKit.TextOutline(label: TextLabel)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
end

--- Sombra "dura" (sem blur) atrás de um TextLabel — Figma: Drop shadow
--- X0/Y3/Blur0/Spread0, preto 100% (comum nos valores numéricos da HUD:
--- "3.634", "x1.5", "$ 456.238"). Cria uma cópia preta do texto, deslocada
--- `offsetY` pra baixo, atrás do label original (ZIndex menor) — mesma
--- técnica clássica de "sombra de texto" no Roblox, já que TextLabel não tem
--- drop-shadow nativo. IMPORTANTE: chame isso DEPOIS de configurar todas as
--- propriedades do label (Text/Font/TextSize/Position/etc.) — a sombra
--- clona o estado atual, uma vez só; texto dinâmico precisa ser propagado
--- manualmente pro label retornado quando o valor mudar.
function UIKit.TextDropShadow(label: TextLabel, offsetY: number?, color: Color3?): TextLabel
	local shadow = Instance.new("TextLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = label.AnchorPoint
	shadow.Size = label.Size
	shadow.Position = label.Position + UDim2.new(0, 0, 0, offsetY or 3)
	shadow.BackgroundTransparency = 1
	shadow.Text = label.Text
	shadow.FontFace = label.FontFace
	shadow.TextSize = label.TextSize
	shadow.TextColor3 = color or Color3.new(0, 0, 0)
	shadow.TextXAlignment = label.TextXAlignment
	shadow.TextYAlignment = label.TextYAlignment
	shadow.ZIndex = math.max(0, label.ZIndex - 1)
	label.ZIndex = math.max(label.ZIndex, shadow.ZIndex + 1)
	shadow.Parent = label.Parent
	return shadow
end

--- Contorno GROSSO nas letras de um TextLabel: o TextStrokeColor3 nativo do
--- Roblox (usado por UIKit.TextOutline) tem espessura FIXA, sem controle —
--- pra um contorno mais "pesado" (pedido nos valores numéricos grandes da
--- HUD, ex: Diamante), criamos várias cópias pretas do texto, deslocadas em
--- 8 direções ao redor do original, todas atrás dele. IMPORTANTE: chame
--- DEPOIS de configurar Text/Font/TextSize/Position do label (clona o
--- estado atual, uma vez só); texto dinâmico precisa ser propagado
--- manualmente pras cópias retornadas quando o valor mudar.
function UIKit.TextThickOutline(label: TextLabel, thickness: number?, color: Color3?): { TextLabel }
	local t = thickness or 2
	local col = color or Color3.new(0, 0, 0)
	local offsets = {
		Vector2.new(-t, -t), Vector2.new(0, -t), Vector2.new(t, -t),
		Vector2.new(-t, 0), Vector2.new(t, 0),
		Vector2.new(-t, t), Vector2.new(0, t), Vector2.new(t, t),
	}

	local copies = {}
	local copyZIndex = math.max(0, label.ZIndex - 1)

	for _, offset in ipairs(offsets) do
		local copy = Instance.new("TextLabel")
		copy.Name = "OutlineCopy"
		copy.AnchorPoint = label.AnchorPoint
		copy.Size = label.Size
		copy.Position = label.Position + UDim2.new(0, offset.X, 0, offset.Y)
		copy.BackgroundTransparency = 1
		copy.Text = label.Text
		copy.FontFace = label.FontFace
		copy.TextSize = label.TextSize
		copy.TextColor3 = col
		copy.TextXAlignment = label.TextXAlignment
		copy.TextYAlignment = label.TextYAlignment
		copy.ZIndex = copyZIndex
		copy.Parent = label.Parent
		table.insert(copies, copy)
	end

	label.ZIndex = math.max(label.ZIndex, copyZIndex + 1)
	return copies
end

--- Feedback tátil padrão de clique (scale down/up) para botões e ícones.
function UIKit.ApplyPressFeedback(button: GuiButton, pressedScale: number?)
	local originalSize = button.Size
	local scale = pressedScale or 0.92

	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.08), {
			Size = UDim2.new(originalSize.X.Scale * scale, originalSize.X.Offset * scale, originalSize.Y.Scale * scale, originalSize.Y.Offset * scale),
		}):Play()
	end)

	local function restore()
		TweenService:Create(button, TweenInfo.new(0.08), { Size = originalSize }):Play()
	end
	button.MouseButton1Up:Connect(restore)
	button.MouseLeave:Connect(restore)
end

return UIKit
