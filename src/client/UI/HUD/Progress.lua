--!strict
--[[
	Progress.lua
	Widget "Portal da Sorte" (Figma node 16:194 "HUD" -> "portal-sorte"):
	imagem única (Icons.Get("PortalSortePanel")) com o painel inteiro já
	"baked" — fundo roxo, borda e o ícone giratório do portal já dentro da
	arte — mais os TextLabels de "EVENTO ESPECIAL" / "Portal da Sorte" /
	"Inicia em: HH:MM:SS" posicionados por cima, nas mesmas coordenadas
	exatas do frame original (container 447x201).

	O card "PROGRESSO ATÉ O PRÓXIMO RENASCIMENTO" não existe neste frame —
	SetRenascimentoProgress/SetAltarStatus continuam existindo como API
	pública (não-visuais aqui) só pra não quebrar HUDController/Main.client.

	Timer: o countdown em si só formata segundos -> HH:MM:SS: quem decrementa
	o valor a cada segundo é o chamador (ver o loop task.spawn em
	Main.client.lua/HUDTest.client.lua que chama SetPortalCountdown a cada
	tick) — este componente só re-renderiza o texto a cada chamada.

	Localização Rojo: StarterPlayer/StarterPlayerScripts/UI/HUD/Progress
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DesignTokens = require(ReplicatedStorage.Shared.Config.DesignTokens)
local UIKit = require(ReplicatedStorage.Shared.UI.Utils.UIKit)
local Icons = require(ReplicatedStorage.Shared.UI.Icons)

local Colors = DesignTokens.Colors
local Typography = DesignTokens.Typography

export type ProgressHandle = {
	Instance: Frame,
	SetRenascimentoProgress: (self: ProgressHandle, current: number, target: number) -> (),
	SetAltarStatus: (self: ProgressHandle, available: boolean) -> (),
	SetPortalCountdown: (self: ProgressHandle, secondsRemaining: number?, active: boolean?) -> (),
}

local EVENTO_ESPECIAL_COLOR = Color3.fromHex("#8535FD")
local COUNTDOWN_COLOR = Color3.fromHex("#FFFC62")

-- Dimensões exatas do container "portal-sorte" no Figma (node 16:194) x0.75
-- (pedido explícito de ficar menor) — todo texto/posição interna escala
-- junto por essa mesma proporção, pra manter tudo alinhado dentro do painel.
local SCALE = 0.75
local CONTAINER_WIDTH = math.floor(447 * SCALE)
local CONTAINER_HEIGHT = math.floor(201 * SCALE)

local function px(value: number): number
	return math.floor(value * SCALE)
end

local Progress = {}
Progress.__index = Progress

function Progress.new(parent: Instance): ProgressHandle
	local root = Instance.new("Frame")
	root.Name = "PortalDaSorte"
	-- Canto inferior direito, mesma margem de 50px usada no resto do HUD —
	-- voltou pra baixo (a tentativa de alinhar com a topbar colidia com ela
	-- horizontalmente, ver histórico).
	root.Size = UDim2.new(0, CONTAINER_WIDTH, 0, CONTAINER_HEIGHT)
	root.AnchorPoint = Vector2.new(1, 1)
	root.Position = UDim2.new(1, -50, 1, -50)
	root.BackgroundTransparency = 1
	root.Visible = false -- só aparece quando há evento configurado
	root.Parent = parent

	-- Imagem única: painel + borda + ícone giratório do portal já "baked".
	local panelImage = Instance.new("ImageLabel")
	panelImage.Name = "PanelImage"
	panelImage.Size = UDim2.new(1, 0, 1, 0)
	panelImage.BackgroundTransparency = 1
	panelImage.Image = Icons.Get("PortalSortePanel")
	panelImage.ScaleType = Enum.ScaleType.Stretch
	panelImage.Parent = root

	local eventoLabel = Instance.new("TextLabel")
	eventoLabel.Name = "EventoEspecial"
	eventoLabel.Size = UDim2.new(0, px(180), 0, px(18))
	eventoLabel.Position = UDim2.new(0, px(240), 0, px(84))
	eventoLabel.BackgroundTransparency = 1
	eventoLabel.Text = "EVENTO ESPECIAL"
	eventoLabel.FontFace = Typography.Fonts.HUDLabel
	eventoLabel.TextSize = px(14)
	eventoLabel.TextColor3 = EVENTO_ESPECIAL_COLOR
	eventoLabel.TextXAlignment = Enum.TextXAlignment.Left
	eventoLabel.ZIndex = 2
	eventoLabel.Parent = root
	UIKit.TextOutline(eventoLabel)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0, px(200), 0, px(34))
	titleLabel.Position = UDim2.new(0, px(221), 0, px(42))
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Portal da Sorte"
	titleLabel.FontFace = Typography.Fonts.HUDLabel
	titleLabel.TextSize = px(28)
	titleLabel.TextColor3 = Colors.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 2
	titleLabel.Parent = root
	UIKit.TextOutline(titleLabel)

	local iniciaEmLabel = Instance.new("TextLabel")
	iniciaEmLabel.Name = "IniciaEm"
	iniciaEmLabel.Size = UDim2.new(0, px(100), 0, px(18))
	iniciaEmLabel.Position = UDim2.new(0, px(289), 0, px(109))
	iniciaEmLabel.BackgroundTransparency = 1
	iniciaEmLabel.Text = "Inicia em:"
	iniciaEmLabel.FontFace = Typography.Fonts.HUDLabel
	iniciaEmLabel.TextSize = px(14)
	iniciaEmLabel.TextColor3 = Colors.Text
	iniciaEmLabel.TextXAlignment = Enum.TextXAlignment.Left
	iniciaEmLabel.ZIndex = 2
	iniciaEmLabel.Parent = root
	UIKit.TextOutline(iniciaEmLabel)

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "Countdown"
	countdownLabel.Size = UDim2.new(0, px(160), 0, px(32))
	countdownLabel.Position = UDim2.new(0, px(263), 0, px(126))
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = "00:00:00"
	countdownLabel.FontFace = Typography.Fonts.HUDLabel
	countdownLabel.TextSize = px(28)
	countdownLabel.TextColor3 = COUNTDOWN_COLOR
	countdownLabel.TextXAlignment = Enum.TextXAlignment.Left
	countdownLabel.ZIndex = 2
	countdownLabel.Parent = root
	UIKit.TextOutline(countdownLabel)

	local self = setmetatable({
		Instance = root,
		_root = root,
		_countdownLabel = countdownLabel,
	}, Progress) :: any

	return self
end

-- Sem UI visível pro progresso do Renascimento/status do Altar neste frame
-- (ver header) — métodos mantidos só pra não quebrar a API pública.
function Progress.SetRenascimentoProgress(_self: ProgressHandle, _current: number, _target: number)
end

function Progress.SetAltarStatus(_self: ProgressHandle, _available: boolean)
end

--- secondsRemaining == nil ou active == false esconde o widget (sem evento ativo)
function Progress.SetPortalCountdown(self: ProgressHandle, secondsRemaining: number?, active: boolean?)
	local s = self :: any
	local root = s._root :: Frame
	local countdownLabel = s._countdownLabel :: TextLabel

	local shouldShow = active ~= false and secondsRemaining ~= nil
	root.Visible = shouldShow

	if shouldShow and secondsRemaining then
		countdownLabel.Text = DesignTokens.FormatCountdown(secondsRemaining, "hms")
	end
end

return Progress
