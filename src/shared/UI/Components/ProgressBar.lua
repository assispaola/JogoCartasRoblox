--!strict
--[[
	ProgressBar.lua
	Barra de progresso genérica — usada no progresso de Renascimento,
	Streak de Login, cooldowns, e qualquer outra tela que precise.

	Localização Rojo: ReplicatedStorage/Shared/UI/Components/ProgressBar
]]

local TweenService = game:GetService("TweenService")

local DesignTokens = require(script.Parent.Parent.Parent.Config.DesignTokens)
local UIKit = require(script.Parent.Parent.Utils.UIKit)

local Colors = DesignTokens.Colors

export type ProgressBarHandle = {
	Instance: Frame,
	SetProgress: (self: ProgressBarHandle, ratio: number, animated: boolean?) -> (),
}

export type ProgressBarProps = {
	Parent: Instance,
	Height: number?,
	FillColor: Color3?,
	LayoutOrder: number?,
}

local ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(props: ProgressBarProps): ProgressBarHandle
	local height = props.Height or 16

	local track = Instance.new("Frame")
	track.Name = "ProgressBar"
	track.Size = UDim2.new(1, 0, 0, height)
	track.BackgroundColor3 = Colors.Background
	track.LayoutOrder = props.LayoutOrder or 0
	track.Parent = props.Parent
	UIKit.Corner(999).Parent = track
	UIKit.Stroke(Colors.Border, 2).Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = props.FillColor or Colors.Success
	fill.BorderSizePixel = 0
	fill.Parent = track
	UIKit.Corner(999).Parent = fill

	local self = setmetatable({ Instance = track, _fill = fill }, ProgressBar) :: any
	return self
end

function ProgressBar.SetProgress(self: ProgressBarHandle, ratio: number, animated: boolean?)
	local fill = (self :: any)._fill :: Frame
	local clamped = math.clamp(ratio, 0, 1)
	local goal = UDim2.new(clamped, 0, 1, 0)

	if animated == false then
		fill.Size = goal
	else
		TweenService:Create(fill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = goal,
		}):Play()
	end
end

return ProgressBar
