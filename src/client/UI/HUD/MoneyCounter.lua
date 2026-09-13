--!strict
--[[
	MoneyCounter.lua
	Grupo "Cash" no canto inferior esquerdo (Figma node 16:194 "HUD" -> nó
	42:7 "Cash"): ícone do cifrão + valor grande (sem painel/borda de fundo,
	fundo transparente no Figma), com uma linha opcional abaixo pra avisar
	quanto o jogador ganhou de renda offline.

	Localização Rojo: StarterPlayer/StarterPlayerScripts/UI/HUD/MoneyCounter
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local DesignTokens = require(ReplicatedStorage.Shared.Config.DesignTokens)
local UIKit = require(ReplicatedStorage.Shared.UI.Utils.UIKit)
local Icons = require(ReplicatedStorage.Shared.UI.Icons)

local Colors = DesignTokens.Colors
local Typography = DesignTokens.Typography

--- Formato compacto "456.238 B" (Figma): 3 casas decimais + espaço + letra
--- maiúscula — diferente de DesignTokens.FormatCompact (2 casas, sem
--- espaço, usado em $/s), pra não mudar esse formato em outros lugares que
--- já usam ele.
local function formatCompact(n: number): string
	local abs = math.abs(n)
	local sign = n < 0 and "-" or ""

	if abs >= 1e12 then
		return string.format("%s%.3f T", sign, abs / 1e12)
	elseif abs >= 1e9 then
		return string.format("%s%.3f B", sign, abs / 1e9)
	elseif abs >= 1e6 then
		return string.format("%s%.3f M", sign, abs / 1e6)
	elseif abs >= 1e3 then
		return string.format("%s%.3f K", sign, abs / 1e3)
	end

	return sign .. string.format("%d", abs)
end

export type MoneyCounterHandle = {
	Instance: Frame,
	SetMoney: (self: MoneyCounterHandle, amount: number) -> (),
	SetOfflineEarningsMessage: (self: MoneyCounterHandle, text: string?) -> (),
}

local MoneyCounter = {}
MoneyCounter.__index = MoneyCounter

function MoneyCounter.new(parent: Instance): MoneyCounterHandle
	local root = Instance.new("Frame")
	root.Name = "Cash"
	root.AutomaticSize = Enum.AutomaticSize.XY
	root.Size = UDim2.new(0, 0, 0, 0)
	-- left: 50px, top: calc(83.33% + 33px) no Figma.
	root.AnchorPoint = Vector2.new(0, 0)
	root.Position = UDim2.new(0, 50, 0.8333, 33)
	root.BackgroundTransparency = 1
	root.Parent = parent

	local rootLayout = UIKit.ListLayout({
		direction = Enum.FillDirection.Vertical,
		padding = 4,
	})
	rootLayout.Parent = root

	local cashRow = Instance.new("Frame")
	cashRow.Name = "CashRow"
	cashRow.AutomaticSize = Enum.AutomaticSize.XY
	cashRow.Size = UDim2.new(0, 0, 0, 0)
	cashRow.BackgroundTransparency = 1
	cashRow.LayoutOrder = 1
	cashRow.Parent = root

	local rowLayout = UIKit.ListLayout({
		direction = Enum.FillDirection.Horizontal,
		padding = 12,
		vAlign = Enum.VerticalAlignment.Center,
	})
	rowLayout.Parent = cashRow

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 41, 0, 62)
	icon.BackgroundTransparency = 1
	icon.Image = Icons.Get("Dinheiro")
	icon.ScaleType = Enum.ScaleType.Fit
	icon.LayoutOrder = 1
	icon.Parent = cashRow
	CollectionService:AddTag(icon, "TunerIcon")

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.AutomaticSize = Enum.AutomaticSize.XY
	valueLabel.Size = UDim2.new(0, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "0"
	valueLabel.FontFace = Typography.Fonts.HUDValue
	valueLabel.TextSize = 52
	valueLabel.TextColor3 = Colors.Money
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.LayoutOrder = 2
	valueLabel.Parent = cashRow

	-- Stroke preto grosso (Figma: Outside, 2px, 100% opaco) — mesma técnica
	-- usada no valor do Diamante/Renascimento: TextStrokeColor3 nativo pro
	-- contorno nítido nas letras + várias cópias offset por trás pro peso
	-- extra (TextStrokeColor3 sozinho não tem espessura ajustável).
	UIKit.TextOutline(valueLabel)
	local valueOutlineCopies = UIKit.TextThickOutline(valueLabel, 2)

	-- "Você ganhou $X enquanto estava offline" — some por padrão, só some
	-- quando SetOfflineEarningsMessage(nil) ou "" for chamado.
	local offlineLabel = Instance.new("TextLabel")
	offlineLabel.Name = "OfflineEarnings"
	offlineLabel.AutomaticSize = Enum.AutomaticSize.XY
	offlineLabel.Size = UDim2.new(0, 0, 0, 0)
	offlineLabel.BackgroundTransparency = 1
	offlineLabel.Text = ""
	offlineLabel.FontFace = Typography.Fonts.HUDLabelMedium
	offlineLabel.TextSize = 20
	offlineLabel.TextColor3 = Colors.Text
	offlineLabel.TextXAlignment = Enum.TextXAlignment.Left
	offlineLabel.LayoutOrder = 2
	offlineLabel.Visible = false
	offlineLabel.Parent = root
	UIKit.TextOutline(offlineLabel)

	local self = setmetatable({
		Instance = root,
		_valueLabel = valueLabel,
		_valueOutlineCopies = valueOutlineCopies,
		_offlineLabel = offlineLabel,
		_money = 0,
	}, MoneyCounter) :: any

	return self
end

function MoneyCounter.SetMoney(self: MoneyCounterHandle, amount: number)
	local s = self :: any
	local from = s._money
	s._money = amount
	local outlineCopies = s._valueOutlineCopies :: { TextLabel }
	UIKit.AnimateNumber(s._valueLabel, from, amount, function(v)
		local text = formatCompact(v)
		for _, copy in outlineCopies do
			copy.Text = text
		end
		return text
	end, 0.5)
end

function MoneyCounter.SetOfflineEarningsMessage(self: MoneyCounterHandle, text: string?)
	local label = (self :: any)._offlineLabel :: TextLabel
	local hasText = text ~= nil and text ~= ""
	label.Visible = hasText
	label.Text = hasText and (text :: string) or ""
end

return MoneyCounter
