--!strict
--[[
	Layout.lua
	Radius, espaçamento e dimensões estruturais — Cartas Míticas.
	Localização Rojo: ReplicatedStorage/Shared/Config/Layout
]]

local Layout = {}

Layout.Radius = {
	SM = 12,
	MD = 18,
	LG = 26,
	Pill = 999,
}

Layout.Spacing = {
	XS = 4,
	SM = 8,
	MD = 16,
	LG = 24,
	XL = 32,
}

-- Dimensões específicas do HUD (mantidas centralizadas para fácil ajuste)
Layout.HUD = {
	TopBarHeight = 38, -- altura de cada chip/botão da TopBar (compacta)
	SidebarWidth = 72, -- coluna única compacta (era grid 2 colunas de 232px)
	SidebarItemHeight = 60,
	RightPanelWidth = 232, -- painéis de Notificações/Streak, compactados
	BottomBarHeight = 64, -- diâmetro do botão redondo de Mochila (não mais dock de 5 ícones)
	MobileBreakpoint = 700, -- abaixo disso: Sidebar esconde (Mochila redonda cobre o atalho)
}

return Layout
