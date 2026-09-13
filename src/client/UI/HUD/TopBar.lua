--!strict
--[[
	TopBar.lua
	Cluster do canto superior direito (Figma node 16:194 "HUD" ->
	"topbar-direito"): Diamante · Renascimento · Presente · Configurações.
	Cada item é um bloco quadrado independente com a arte real de fundo
	(borda+gradiente já "baked" na imagem, ver Icons.lua) + ícone por cima
	(ver StatBadge.lua/SquareIconButton.lua) — não mais um pill único
	contíguo — reproduz fielmente o layout do frame.

	Nota: o Figma deste frame NÃO tem ícone de Sino (notificações) nem chip
	de $/s na topbar — só os 4 itens acima. HUDController.SetBadge("bell",
	...) e SetIncomePerSecond continuam existindo como API pública (outros
	sistemas do jogo já chamam), mas não têm efeito visual aqui.

	Localização Rojo: StarterPlayer/StarterPlayerScripts/UI/HUD/TopBar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DesignTokens = require(ReplicatedStorage.Shared.Config.DesignTokens)
local UIKit = require(ReplicatedStorage.Shared.UI.Utils.UIKit)
local StatBadge = require(ReplicatedStorage.Shared.UI.Components.StatBadge)
local SquareIconButton = require(ReplicatedStorage.Shared.UI.Components.SquareIconButton)
local Icons = require(ReplicatedStorage.Shared.UI.Icons)

local Colors = DesignTokens.Colors

export type TopBarCallbacks = {
	OnGiftClick: (() -> ())?,
	OnSettingsClick: (() -> ())?,
}

export type TopBarHandle = {
	Instance: Frame,
	SetMoney: (self: TopBarHandle, amount: number) -> (), -- no-op aqui: $ mora no MoneyCounter (canto inferior esquerdo do Figma)
	SetDiamonds: (self: TopBarHandle, amount: number) -> (),
	SetIncomePerSecond: (self: TopBarHandle, amount: number) -> (), -- no-op: não existe chip de $/s neste frame
	SetRenascimento: (self: TopBarHandle, cycle: number, multiplier: number) -> (),
	SetBadge: (self: TopBarHandle, key: string, count: number) -> (),
}

local ITEM_HEIGHT = 62

-- Cor do valor do Diamante (única cor que não vem da imagem de fundo — é o
-- TextLabel desenhado por cima).
local DIAMOND_VALUE_COLOR = Color3.fromHex("#4AEDFF")

-- Rubik no peso mais pesado disponível (Heavy é mais bold que o ExtraBold
-- usado no resto da HUD) — pedido específico pro valor do Diamante.
local DIAMOND_VALUE_FONT = Font.fromName("Rubik", Enum.FontWeight.Heavy)

local TopBar = {}
TopBar.__index = TopBar

function TopBar.new(parent: Instance, callbacks: TopBarCallbacks?): TopBarHandle
	local cb: TopBarCallbacks = callbacks or {}

	local root = Instance.new("Frame")
	root.Name = "TopBar"
	root.AutomaticSize = Enum.AutomaticSize.X
	root.Size = UDim2.new(0, 0, 0, ITEM_HEIGHT)
	root.AnchorPoint = Vector2.new(1, 0)
	root.Position = UDim2.new(1, -50, 0, 50) -- safe-view do Figma: 50px de margem
	root.BackgroundTransparency = 1
	root.Parent = parent

	local layout = UIKit.ListLayout({
		direction = Enum.FillDirection.Horizontal,
		padding = 21, -- gap-[21px] no Figma
		vAlign = Enum.VerticalAlignment.Center,
	})
	layout.Parent = root

	local diamondBadge = StatBadge.new({
		Width = 168,
		Height = ITEM_HEIGHT,
		BackgroundImage = Icons.Get("BtnDiamanteBg"),
		IconAsset = Icons.Get("Diamante"),
		IconSize = 42,
		IconX = 13,
		TextLeft = 69,
		-- 34 (Heavy) estava largo demais pros ~87px disponíveis e truncava de
		-- forma inconsistente entre as 8 cópias do contorno + o texto
		-- principal (efeito "falhado"/cortado) — 28 é o tamanho do Figma e
		-- cabe com folga. Espessura 3 também contribuía pro efeito (Heavy já
		-- é um peso bem grosso por si só) — 2 é o mesmo valor que funcionou
		-- bem no "Renascimento".
		ValueTextSize = 28,
		ValueFont = DIAMOND_VALUE_FONT,
		ValueStrokeThickness = DesignTokens.Typography.HUDWhiteLabel.StrokeThickness,
		Value = "0",
		ValueColor = DIAMOND_VALUE_COLOR,
		Parent = root,
		LayoutOrder = 1,
	})

	local renascimentoBadge = StatBadge.new({
		Width = 203,
		Height = ITEM_HEIGHT,
		BackgroundImage = Icons.Get("BtnRenascerBg"),
		IconAsset = Icons.Get("Renascimento"),
		IconX = 15,
		-- Reduzido de 72 pra 68 (ganha ~4px de largura útil) — "Renascimento"
		-- é uma palavra longa numa caixa de 203px fixos (arte real, não dá
		-- pra esticar); com o texto maior, esse é o teto prático sem cortar
		-- nos cantos arredondados do fundo.
		TextLeft = 68,
		TitleY = 8,
		TitleTextSize = DesignTokens.Typography.HUDWhiteLabel.Size,
		TitleStrokeThickness = DesignTokens.Typography.HUDWhiteLabel.StrokeThickness,
		ValueY = 34,
		ValueTextSize = 20,
		ValueStrokeThickness = 2,
		Title = "Renascimento",
		Value = "x1.00",
		ValueColor = Colors.Money,
		Parent = root,
		LayoutOrder = 2,
	})

	local giftBtn = SquareIconButton.new({
		Width = 70,
		Height = ITEM_HEIGHT,
		BackgroundImage = Icons.Get("BtnGiftBg"),
		IconAsset = Icons.Get("Presente"),
		IconSize = 44,
		Parent = root,
		LayoutOrder = 3,
		OnClick = cb.OnGiftClick,
	})

	local _configBtn = SquareIconButton.new({
		Width = 70,
		Height = ITEM_HEIGHT,
		BackgroundImage = Icons.Get("BtnConfigBg"),
		IconAsset = Icons.Get("Configuracoes"),
		IconSize = 44,
		Parent = root,
		LayoutOrder = 4,
		OnClick = cb.OnSettingsClick,
	})

	local self = setmetatable({
		Instance = root,
		_diamondBadge = diamondBadge,
		_renascimentoBadge = renascimentoBadge,
		_giftBtn = giftBtn,
		_diamonds = 0,
	}, TopBar) :: any

	return self
end

function TopBar.SetMoney(_self: TopBarHandle, _amount: number)
end

function TopBar.SetDiamonds(self: TopBarHandle, amount: number)
	local s = self :: any
	s._diamonds = amount
	s._diamondBadge:SetValue(DesignTokens.FormatNumber(amount))
end

function TopBar.SetIncomePerSecond(_self: TopBarHandle, _amount: number)
end

-- O Figma mostra só "Renascimento" (título fixo) + "x1.5" (multiplicador) —
-- sem o número do ciclo em texto nenhum lugar deste frame. `cycle` continua
-- no parâmetro (API já usada por Main.client.lua/HUDTest.client.lua), mas
-- não aparece visualmente aqui de propósito.
function TopBar.SetRenascimento(self: TopBarHandle, _cycle: number, multiplier: number)
	local s = self :: any
	s._renascimentoBadge:SetValue(string.format("x%.2f", multiplier))
end

-- SquareIconButton não tem badge numérico próprio (o Figma não mostra badge
-- no botão "Presente" neste frame) — método mantido só pra não quebrar
-- HUDController.SetBadge, que outros sistemas do jogo já chamam.
function TopBar.SetBadge(_self: TopBarHandle, _key: string, _count: number)
end

return TopBar
