--!strict
--[[
	Sidebar.lua
	Navegação lateral esquerda (Figma node 16:194 "HUD" -> "sidebar-esquerda"):
	coluna única de 5 botões quadrados 80x80, cada um com a arte real de
	fundo (borda+gradiente já "baked" na imagem, ver Icons.lua) + ícone por
	cima (ver SquareIconButton.lua) — Loja, Pacotes, Álbum, Batalha, Altar,
	nessa ordem (de cima pra baixo no Figma).

	Diferente da versão anterior (9 itens: Início/Roda/Pacto/Ranking/Mochila
	inclusos) — este frame específico só mostra esses 5; Início e Mochila
	viram atalhos próprios (ver ActionButtons.lua), e Roda/Pacto/Ranking não
	aparecem neste frame. SetAlbumProgress/SetPackCooldown/
	SetWheelNotification continuam existindo como API pública (nenhum footer/
	badge visível neste layout, já que o Figma não mostra contadores nos
	tiles) — mantidos pra não quebrar Main.client.lua/HUDTest.client.lua.

	Localização Rojo: StarterPlayer/StarterPlayerScripts/UI/HUD/Sidebar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UI.Utils.UIKit)
local SquareIconButton = require(ReplicatedStorage.Shared.UI.Components.SquareIconButton)
local Icons = require(ReplicatedStorage.Shared.UI.Icons)

export type NavKey = "Loja" | "Pacotes" | "Album" | "Batalha" | "Altar"

export type SidebarHandle = {
	Instance: Frame,
	SetActive: (self: SidebarHandle, key: NavKey) -> (),
	SetAlbumProgress: (self: SidebarHandle, current: number, max: number) -> (), -- sem UI neste layout (ver header)
	SetBackpackCount: (self: SidebarHandle, count: number) -> (), -- sem UI neste layout (Mochila não está na sidebar deste frame)
	SetPackCooldown: (self: SidebarHandle, secondsRemaining: number?) -> (), -- sem UI neste layout
	SetWheelNotification: (self: SidebarHandle, hasNotification: boolean) -> (), -- sem UI neste layout (Roda não está neste frame)
}

local TILE_SIZE = 80
local ICON_SIZE = 58 -- próximo do tamanho real de cada ícone no Figma (~55-64px, varia por item)

local NAV_ITEMS: { { key: NavKey, icon: string, bg: string, label: string, iconSize: number? } } = {
	{ key = "Loja", icon = "Loja", bg = "BtnLojaBg", label = "Loja" },
	{ key = "Pacotes", icon = "Pacotes", bg = "BtnPacotesBg", label = "Pacotes", iconSize = 66 },
	{ key = "Album", icon = "Album", bg = "BtnAlbumBg", label = "Álbum" },
	{ key = "Batalha", icon = "Batalha", bg = "BtnBatalhaBg", label = "Batalha" },
	{ key = "Altar", icon = "Altar", bg = "BtnAltarBg", label = "Altar" },
}

local Sidebar = {}
Sidebar.__index = Sidebar

function Sidebar.new(parent: Instance, onNavigate: ((NavKey) -> ())?): SidebarHandle
	local root = Instance.new("Frame")
	root.Name = "Sidebar"
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Size = UDim2.new(0, TILE_SIZE, 0, 0)
	-- left-[50px] top-[calc(10%+83px)] no Figma: os 5 tiles (80+20*4=480px)
	-- preenchem exatamente a altura de 480px do grupo, então ancorar no
	-- topo-esquerda bate 1:1 com o "justify-center" do frame (sem sobra).
	root.AnchorPoint = Vector2.new(0, 0)
	root.Position = UDim2.new(0, 50, 0.1, 83)
	root.BackgroundTransparency = 1
	root.Parent = parent

	local layout = UIKit.ListLayout({
		direction = Enum.FillDirection.Vertical,
		padding = 20,
	})
	layout.Parent = root

	local tiles: { [NavKey]: SquareIconButton.SquareIconButtonHandle } = {}

	for order, item in ipairs(NAV_ITEMS) do
		local tile = SquareIconButton.new({
			Width = TILE_SIZE,
			Height = TILE_SIZE,
			BackgroundImage = Icons.Get(item.bg),
			IconAsset = Icons.Get(item.icon),
			IconSize = item.iconSize or ICON_SIZE,
			Label = item.label,
			Parent = root,
			LayoutOrder = order,
			OnClick = onNavigate and function()
				(onNavigate :: (NavKey) -> ())(item.key)
			end or nil,
		})
		tiles[item.key] = tile
	end

	local self = setmetatable({
		Instance = root,
		_tiles = tiles,
		_activeKey = nil :: NavKey?,
	}, Sidebar) :: any

	return self
end

function Sidebar.SetActive(self: SidebarHandle, key: NavKey)
	local s = self :: any
	local tiles: { [NavKey]: SquareIconButton.SquareIconButtonHandle } = s._tiles

	for itemKey, tile in pairs(tiles) do
		tile:SetActive(itemKey == key)
	end

	s._activeKey = key
end

function Sidebar.SetAlbumProgress(_self: SidebarHandle, _current: number, _max: number)
end

function Sidebar.SetBackpackCount(_self: SidebarHandle, _count: number)
end

function Sidebar.SetPackCooldown(_self: SidebarHandle, _secondsRemaining: number?)
end

function Sidebar.SetWheelNotification(_self: SidebarHandle, _hasNotification: boolean)
end

return Sidebar
