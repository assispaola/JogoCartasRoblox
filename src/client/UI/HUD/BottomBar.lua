--!strict
--[[
	BottomBar.lua
	Cluster "Base/Mochila" (Figma node 16:194 "HUD" -> "Base/Mochila", nó
	42:13): "Ir para a Base" + "Abrir Mochila" empilhados verticalmente, no
	meio-direita da tela (left: calc(83.33%+119px), top: calc(40%+70px) —
	NÃO fica mais colado perto do Portal da Sorte, como numa versão anterior
	deste frame).

	Substitui o antigo botão redondo único de atalho da Mochila (era um
	design anterior) — este frame do Figma usa dois pills retangulares
	separados em vez disso.

	Localização Rojo: StarterPlayer/StarterPlayerScripts/UI/HUD/BottomBar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UI.Utils.UIKit)
local PillActionButton = require(ReplicatedStorage.Shared.UI.Components.PillActionButton)
local Icons = require(ReplicatedStorage.Shared.UI.Icons)

local IR_PARA_BASE_KEY = "Inicio"
local MOCHILA_KEY = "Mochila"

export type BottomBarHandle = {
	Instance: Frame,
	SetActive: (self: BottomBarHandle, key: string) -> (), -- sem estado "ativo" visível neste layout (ver header)
	SetBackpackCount: (self: BottomBarHandle, count: number) -> (), -- sem badge neste layout (Figma não mostra contador no pill)
}

local PILL_WIDTH = 151
local PILL_HEIGHT = 37

local BottomBar = {}
BottomBar.__index = BottomBar

function BottomBar.new(parent: Instance, onNavigate: ((string) -> ())?): BottomBarHandle
	local root = Instance.new("Frame")
	root.Name = "ActionButtons"
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Size = UDim2.new(0, PILL_WIDTH, 0, 0)
	-- left: calc(83.33% + 119px), top: calc(40% + 70px) no Figma.
	root.AnchorPoint = Vector2.new(0, 0)
	root.Position = UDim2.new(0.8333, 119, 0.4, 70)
	root.BackgroundTransparency = 1
	root.Parent = parent

	local layout = UIKit.ListLayout({
		direction = Enum.FillDirection.Vertical,
		padding = 20,
		hAlign = Enum.HorizontalAlignment.Left,
	})
	layout.Parent = root

	local _irParaBase = PillActionButton.new({
		Width = PILL_WIDTH,
		Height = PILL_HEIGHT,
		BackgroundImage = Icons.Get("BtnCasaBg"),
		IconAsset = Icons.Get("Inicio"),
		Label = "Ir para a Base",
		Parent = root,
		LayoutOrder = 1,
		OnClick = onNavigate and function()
			(onNavigate :: (string) -> ())(IR_PARA_BASE_KEY)
		end or nil,
	})

	local _abrirMochila = PillActionButton.new({
		Width = PILL_WIDTH,
		Height = PILL_HEIGHT,
		BackgroundImage = Icons.Get("BtnMochilaBg"),
		IconAsset = Icons.Get("Mochila"),
		Label = "Abrir Mochila",
		Parent = root,
		LayoutOrder = 2,
		OnClick = onNavigate and function()
			(onNavigate :: (string) -> ())(MOCHILA_KEY)
		end or nil,
	})

	local self = setmetatable({
		Instance = root,
	}, BottomBar) :: any

	return self
end

function BottomBar.SetActive(_self: BottomBarHandle, _key: string)
end

function BottomBar.SetBackpackCount(_self: BottomBarHandle, _count: number)
end

return BottomBar
