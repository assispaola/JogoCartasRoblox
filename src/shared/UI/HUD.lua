--!strict
--[[
	HUD.lua
	Componente do painel fixo de topo — visível em TODAS as telas do jogo.
	Mostra: Dinheiro, Diamante, Renda ($/s), Nível/XP e ícones de notificação.

	Localização Rojo sugerida: ReplicatedStorage/Shared/UI/HUD

	USO:
		local HUD = require(ReplicatedStorage.Shared.UI.HUD)
		local hud = HUD.new(playerGui)

		hud:SetMoney(1250000)
		hud:SetDiamonds(450)
		hud:SetIncomePerSecond(50000)
		hud:SetLevel(42, 12450, 25000)
		hud:SetBadge("gift", 3)
		hud:SetBadge("bell", 7)
		hud:ShowToast("✨ Você ganhou 50 💎!", Color3.fromHex("#3ec1ff"))
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DesignTokens = require(script.Parent.DesignTokens)

local HUD = {}
HUD.__index = HUD

export type HUDInstance = typeof(setmetatable(
	{} :: {
		ScreenGui: ScreenGui,
		_money: number,
		_diamonds: number,
		_moneyLabel: TextLabel,
		_diamondLabel: TextLabel,
		_incomeLabel: TextLabel,
		_levelLabel: TextLabel,
		_xpFill: Frame,
		_badges: { [string]: TextLabel },
		_toastLayer: Frame,
	},
	HUD
))

-- ===================== HELPERS DE CONSTRUÇÃO =====================

local function corner(radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	return c
end

local function stroke(color: Color3, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 2
	s.Transparency = 0.15
	return s
end

--- Anima um TextLabel numérico contando de um valor até o outro (feedback imediato)
local function animateNumberLabel(label: TextLabel, fromValue: number, toValue: number, prefix: string?)
	local holder = Instance.new("NumberValue")
	holder.Value = fromValue

	local tween = TweenService:Create(holder, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Value = toValue,
	})

	holder.Changed:Connect(function(v)
		label.Text = (prefix or "") .. DesignTokens.FormatNumber(v)
	end)

	tween:Play()
	tween.Completed:Connect(function()
		holder:Destroy()
	end)
end

-- Chip de moeda (ícone + valor), usado para $, 💎 e $/s
local function createChip(parent: Instance, iconText: string, initialText: string, textColor: Color3): TextLabel
	local chip = Instance.new("Frame")
	chip.Name = "Chip"
	chip.AutomaticSize = Enum.AutomaticSize.X
	chip.Size = UDim2.new(0, 0, 1, 0)
	chip.BackgroundTransparency = 1
	chip.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = chip

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = chip

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 20, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = iconText
	icon.TextSize = 18
	icon.Font = DesignTokens.Fonts.Display
	icon.TextColor3 = DesignTokens.Colors.Text
	icon.Parent = chip

	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = initialText
	label.TextColor3 = textColor
	label.Font = DesignTokens.Fonts.Mono
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = chip

	return label
end

-- Divisor vertical fino entre chips
local function createDivider(parent: Instance)
	local div = Instance.new("Frame")
	div.Name = "Divider"
	div.Size = UDim2.new(0, 2, 0.6, 0)
	div.BackgroundColor3 = DesignTokens.Colors.Border
	div.BorderSizePixel = 0
	div.Parent = parent
end

-- Botão de ícone com badge de notificação (gift, bell, settings)
local function createIconButton(parent: Instance, iconText: string, layoutOrder: number): (TextButton, TextLabel)
	local btn = Instance.new("TextButton")
	btn.Name = "IconButton"
	btn.Size = UDim2.new(0, 44, 0, 44)
	btn.BackgroundColor3 = DesignTokens.Colors.Panel
	btn.AutoButtonColor = false
	btn.Text = iconText
	btn.TextSize = 20
	btn.Font = DesignTokens.Fonts.Display
	btn.TextColor3 = DesignTokens.Colors.Text
	btn.LayoutOrder = layoutOrder
	btn.Parent = parent
	corner(DesignTokens.Radius.Small).Parent = btn
	stroke(DesignTokens.Colors.Border, 2).Parent = btn

	-- Feedback tátil (scale down no clique)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), { Size = UDim2.new(0, 40, 0, 40) }):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), { Size = UDim2.new(0, 44, 0, 44) }):Play()
	end)

	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.Size = UDim2.new(0, 20, 0, 20)
	badge.Position = UDim2.new(1, -8, 0, -8)
	badge.AnchorPoint = Vector2.new(0, 0)
	badge.BackgroundColor3 = DesignTokens.Colors.Danger
	badge.Text = ""
	badge.TextColor3 = Color3.new(1, 1, 1)
	badge.Font = DesignTokens.Fonts.Display
	badge.TextSize = 11
	badge.Visible = false
	badge.Parent = btn
	corner(DesignTokens.Radius.Pill).Parent = badge
	stroke(DesignTokens.Colors.Background, 2).Parent = badge

	return btn, badge
end

-- ===================== CONSTRUTOR PRINCIPAL =====================

function HUD.new(playerGui: Instance): HUDInstance
	local self = setmetatable({}, HUD) :: HUDInstance

	self._money = 0
	self._diamonds = 0
	self._badges = {}

	-- ScreenGui raiz
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD_Main"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = playerGui
	self.ScreenGui = screenGui

	-- Barra principal (topo)
	local bar = Instance.new("Frame")
	bar.Name = "TopBar"
	bar.Size = UDim2.new(1, -32, 0, 52)
	bar.Position = UDim2.new(0, 16, 0, 16)
	bar.BackgroundColor3 = DesignTokens.Colors.Background
	bar.BackgroundTransparency = 0.1
	bar.Parent = screenGui
	corner(DesignTokens.Radius.Pill).Parent = bar
	stroke(DesignTokens.Colors.Border, 2).Parent = bar

	-- Container esquerdo: chips de moeda
	local leftGroup = Instance.new("Frame")
	leftGroup.Name = "CurrencyGroup"
	leftGroup.AutomaticSize = Enum.AutomaticSize.X
	leftGroup.Size = UDim2.new(0, 0, 1, 0)
	leftGroup.Position = UDim2.new(0, 4, 0, 0)
	leftGroup.BackgroundTransparency = 1
	leftGroup.Parent = bar

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.FillDirection = Enum.FillDirection.Horizontal
	leftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	leftLayout.Parent = leftGroup

	self._moneyLabel = createChip(leftGroup, "💚", "$ 0", DesignTokens.Colors.Money)
	createDivider(leftGroup)
	self._diamondLabel = createChip(leftGroup, "💎", "0", DesignTokens.Colors.Diamond)
	createDivider(leftGroup)
	self._incomeLabel = createChip(leftGroup, "⚡", "$/s 0", DesignTokens.Colors.XP)

	-- Container direito: nível/XP + ícones
	local rightGroup = Instance.new("Frame")
	rightGroup.Name = "RightGroup"
	rightGroup.AutomaticSize = Enum.AutomaticSize.X
	rightGroup.Size = UDim2.new(0, 0, 1, 0)
	rightGroup.AnchorPoint = Vector2.new(1, 0)
	rightGroup.Position = UDim2.new(1, -4, 0, 0)
	rightGroup.BackgroundTransparency = 1
	rightGroup.Parent = bar

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.FillDirection = Enum.FillDirection.Horizontal
	rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rightLayout.Padding = UDim.new(0, 8)
	rightLayout.Parent = rightGroup

	-- Badge de Nível (com barra de XP embutida)
	local levelBadge = Instance.new("Frame")
	levelBadge.Name = "LevelBadge"
	levelBadge.Size = UDim2.new(0, 130, 0, 40)
	levelBadge.BackgroundColor3 = DesignTokens.Colors.Panel
	levelBadge.LayoutOrder = 1
	levelBadge.Parent = rightGroup
	corner(DesignTokens.Radius.Small).Parent = levelBadge
	stroke(DesignTokens.Colors.Border, 2).Parent = levelBadge

	self._levelLabel = Instance.new("TextLabel")
	self._levelLabel.Size = UDim2.new(1, -16, 0, 18)
	self._levelLabel.Position = UDim2.new(0, 8, 0, 2)
	self._levelLabel.BackgroundTransparency = 1
	self._levelLabel.Text = "Nv. 1"
	self._levelLabel.Font = DesignTokens.Fonts.Display
	self._levelLabel.TextSize = 13
	self._levelLabel.TextColor3 = DesignTokens.Colors.Text
	self._levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._levelLabel.Parent = levelBadge

	local xpTrack = Instance.new("Frame")
	xpTrack.Size = UDim2.new(1, -16, 0, 8)
	xpTrack.Position = UDim2.new(0, 8, 1, -14)
	xpTrack.BackgroundColor3 = DesignTokens.Colors.Background
	xpTrack.Parent = levelBadge
	corner(DesignTokens.Radius.Pill).Parent = xpTrack

	self._xpFill = Instance.new("Frame")
	self._xpFill.Size = UDim2.new(0, 0, 1, 0)
	self._xpFill.BackgroundColor3 = DesignTokens.Colors.XP
	self._xpFill.Parent = xpTrack
	corner(DesignTokens.Radius.Pill).Parent = self._xpFill

	-- Ícones: presente, sino, config
	local giftBtn, giftBadge = createIconButton(rightGroup, "🎁", 2)
	local bellBtn, bellBadge = createIconButton(rightGroup, "🔔", 3)
	local gearBtn, _gearBadge = createIconButton(rightGroup, "⚙️", 4)
	self._badges["gift"] = giftBadge
	self._badges["bell"] = bellBadge

	-- Camada de Toasts (canto superior direito, abaixo da HUD)
	local toastLayer = Instance.new("Frame")
	toastLayer.Name = "ToastLayer"
	toastLayer.Size = UDim2.new(0, 280, 1, -90)
	toastLayer.Position = UDim2.new(1, -296, 0, 78)
	toastLayer.BackgroundTransparency = 1
	toastLayer.Parent = screenGui

	local toastListLayout = Instance.new("UIListLayout")
	toastListLayout.FillDirection = Enum.FillDirection.Vertical
	toastListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	toastListLayout.Padding = UDim.new(0, 8)
	toastListLayout.Parent = toastLayer

	self._toastLayer = toastLayer

	return self
end

-- ===================== API PÚBLICA =====================

function HUD.SetMoney(self: HUDInstance, amount: number)
	local previous = self._money
	self._money = amount
	animateNumberLabel(self._moneyLabel, previous, amount, "$ ")
end

function HUD.AddMoney(self: HUDInstance, delta: number)
	self:SetMoney(self._money + delta)
end

function HUD.SetDiamonds(self: HUDInstance, amount: number)
	local previous = self._diamonds
	self._diamonds = amount
	animateNumberLabel(self._diamondLabel, previous, amount)
end

function HUD.AddDiamonds(self: HUDInstance, delta: number)
	self:SetDiamonds(self._diamonds + delta)
end

function HUD.SetIncomePerSecond(self: HUDInstance, amount: number)
	self._incomeLabel.Text = "$/s " .. DesignTokens.FormatNumber(amount)
end

function HUD.SetLevel(self: HUDInstance, level: number, currentXP: number, maxXP: number)
	self._levelLabel.Text = string.format("Nv. %d", level)
	local ratio = maxXP > 0 and math.clamp(currentXP / maxXP, 0, 1) or 0
	TweenService:Create(self._xpFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, 1, 0),
	}):Play()
end

--- Atualiza o número do badge de notificação. count == 0 esconde o badge.
function HUD.SetBadge(self: HUDInstance, key: string, count: number)
	local badge = self._badges[key]
	if not badge then
		return
	end
	badge.Visible = count > 0
	badge.Text = count > 9 and "9+" or tostring(count)
end

--- Mostra um toast temporário no canto superior direito (auto-dismiss em 3s)
function HUD.ShowToast(self: HUDInstance, text: string, accentColor: Color3?)
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 0)
	toast.AutomaticSize = Enum.AutomaticSize.Y
	toast.BackgroundColor3 = DesignTokens.Colors.Panel
	toast.BackgroundTransparency = 1
	toast.LayoutOrder = -os.clock()
	toast.Parent = self._toastLayer
	corner(DesignTokens.Radius.Medium).Parent = toast
	local border = stroke(accentColor or DesignTokens.Colors.Diamond, 2)
	border.Transparency = 1
	border.Parent = toast

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = DesignTokens.Colors.Text
	label.Font = DesignTokens.Fonts.Body
	label.TextSize = 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toast

	-- Fade in
	TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(border, TweenInfo.new(0.2), { Transparency = 0.2 }):Play()

	task.delay(3, function()
		if not toast.Parent then
			return
		end
		local fadeOut = TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
		TweenService:Create(border, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			toast:Destroy()
		end)
	end)
end

function HUD.Destroy(self: HUDInstance)
	self.ScreenGui:Destroy()
end

return HUD
