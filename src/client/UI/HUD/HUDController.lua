--!strict
--[[
	HUDController.lua
	Ponto de entrada ÚNICO do HUD. Monta TopBar + Sidebar/BottomBar +
	Progress + MoneyCounter, e expõe uma API pública simples pro resto do
	jogo consumir — nenhum outro sistema deve tocar nos subcomponentes
	diretamente.

	O painel de Streak/Notificações (card "Renda Offline" + lista +
	"STREAK DE LOGIN") não existe no Figma (node 16:194) — foi removido.
	SetStreak/PushNotification continuam na API pública (Main.client.lua já
	chama) mas são no-op, sem UI própria.

	Localização Rojo: StarterPlayer/StarterPlayerScripts/UI/HUD/HUDController

	USO:
		local HUDController = require(...)
		local hud = HUDController.new(playerGui)

		hud:SetMoney(1250000)
		hud:SetDiamonds(450)
		hud:SetIncomePerSecond(35100)
		hud:SetRenascimento(2, 1.85)
		hud:SetAlbumProgress(315, 315)
		hud:SetBackpackCount(240)
		hud:SetPackCooldown(180)
		hud:SetWheelNotification(true)
		hud:SetStreak(7, 7, "Pacote grátis + 50 Diamante!")
		hud:PushNotification({icon="🤝", title="Pacto dos Guardiões", subtitle="Trocas disponíveis!", time="Agora"})
		hud:SetRenascimentoProgress(6250000, 10000000)
		hud:SetAltarStatus(false)
		hud:SetPortalCountdown(5025, true) -- 1h23m
		hud:SetBadge("gift", 3)
		hud:SetBadge("bell", 7)
		hud:ShowToast("✨ Você ganhou 50 💎!", Color3.fromHex("#3ec8ff"))
		hud:OnNavigate(function(key) print("navegou para", key) end)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DesignTokens = require(ReplicatedStorage.Shared.Config.DesignTokens)
local UIKit = require(ReplicatedStorage.Shared.UI.Utils.UIKit)

local TopBar = require(script.Parent.TopBar)
local Sidebar = require(script.Parent.Sidebar)
local BottomBar = require(script.Parent.BottomBar)
local Progress = require(script.Parent.Progress)
local MoneyCounter = require(script.Parent.MoneyCounter)

-- Tipo do item de notificação — SetStreak/PushNotification continuam na API
-- pública (Main.client.lua já chama), mas não têm UI própria neste frame
-- (ver header).
export type NotificationItem = {
	icon: string,
	title: string,
	subtitle: string,
	time: string,
	unread: boolean?,
}

local Colors = DesignTokens.Colors
local Layout = DesignTokens.Layout

local HUDController = {}
HUDController.__index = HUDController

export type HUDControllerHandle = typeof(setmetatable(
	{} :: {
		ScreenGui: ScreenGui,
		_topBar: TopBar.TopBarHandle,
		_sidebar: Sidebar.SidebarHandle,
		_bottomBar: BottomBar.BottomBarHandle,
		_progress: Progress.ProgressHandle,
		_moneyCounter: MoneyCounter.MoneyCounterHandle,
		_toastLayer: Frame,
		_onNavigateCallback: ((string) -> ())?,
	},
	HUDController
))

function HUDController.new(playerGui: Instance): HUDControllerHandle
	local self = setmetatable({}, HUDController) :: any

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD_Main"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	-- Sem isso, o Roblox empurra o ScreenGui inteiro pra baixo (~36px) pra
	-- não cobrir a topbar nativa (Robux/chat/leaderboard) — a margem de 50px
	-- do "safe-view" do Figma já é a margem segura pretendida, então os dois
	-- insets somados jogavam a topbar-direito mais pra baixo/direita do que
	-- deveria (e disputando espaço com os ícones nativos).
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui
	self.ScreenGui = screenGui

	local function handleNavigate(key: string)
		if self._onNavigateCallback then
			self._onNavigateCallback(key)
		end
		self._sidebar:SetActive(key :: any)
		self._bottomBar:SetActive(key :: any)
	end

	self._topBar = TopBar.new(screenGui, {
		OnGiftClick = function()
			handleNavigate("Recompensas")
		end,
		OnSettingsClick = function()
			handleNavigate("Configuracoes")
		end,
	})

	self._sidebar = Sidebar.new(screenGui, handleNavigate)
	self._bottomBar = BottomBar.new(screenGui, handleNavigate)
	self._progress = Progress.new(screenGui)
	self._moneyCounter = MoneyCounter.new(screenGui)

	-- Camada de toasts (cross-cutting, fica por cima de tudo) — abaixo do
	-- cluster topbar-direito, encostada na margem segura de 50px do Figma.
	local toastLayer = Instance.new("Frame")
	toastLayer.Name = "ToastLayer"
	toastLayer.Size = UDim2.new(0, 320, 1, -220)
	toastLayer.Position = UDim2.new(1, -370, 0, 122)
	toastLayer.AnchorPoint = Vector2.new(0, 0)
	toastLayer.BackgroundTransparency = 1
	toastLayer.ZIndex = 10
	toastLayer.Parent = screenGui
	local toastListLayout = UIKit.ListLayout({ direction = Enum.FillDirection.Vertical, padding = 8 })
	toastListLayout.Parent = toastLayer
	self._toastLayer = toastLayer

	self:_setupResponsive(screenGui)

	return self
end

-- ===================== RESPONSIVIDADE (Desktop <-> Mobile) =====================

function HUDController._setupResponsive(self: HUDControllerHandle, screenGui: ScreenGui)
	local s = self :: any

	local function applyBreakpoint()
		local viewportWidth = screenGui.AbsoluteSize.X
		local isMobile = viewportWidth > 0 and viewportWidth < Layout.HUD.MobileBreakpoint

		s._sidebar.Instance.Visible = not isMobile

		-- BottomBar agora é só o botão redondo de atalho da Mochila — fica
		-- SEMPRE visível (não é mais um dock de navegação completo que
		-- substitui a Sidebar em mobile, por isso não alterna com isMobile).
	end

	applyBreakpoint()
	screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyBreakpoint)
end

-- ===================== API PÚBLICA: ECONOMIA =====================

function HUDController.SetMoney(self: HUDControllerHandle, amount: number)
	(self :: any)._moneyCounter:SetMoney(amount)
end

function HUDController.AddMoney(self: HUDControllerHandle, delta: number)
	local moneyCounter = (self :: any)._moneyCounter
	moneyCounter:SetMoney((moneyCounter :: any)._money + delta)
end

--- Mostra "Você ganhou $X enquanto estava offline" abaixo do contador de
--- Dinheiro (Figma node 16:194 "HUD"). Passe nil/"" pra esconder.
function HUDController.SetOfflineEarningsMessage(self: HUDControllerHandle, text: string?)
	(self :: any)._moneyCounter:SetOfflineEarningsMessage(text)
end

function HUDController.SetDiamonds(self: HUDControllerHandle, amount: number)
	(self :: any)._topBar:SetDiamonds(amount)
end

function HUDController.AddDiamonds(self: HUDControllerHandle, delta: number)
	local topBar = (self :: any)._topBar
	topBar:SetDiamonds((topBar :: any)._diamonds + delta)
end

function HUDController.SetIncomePerSecond(self: HUDControllerHandle, amount: number)
	(self :: any)._topBar:SetIncomePerSecond(amount)
end

function HUDController.SetRenascimento(self: HUDControllerHandle, cycle: number, multiplier: number)
	(self :: any)._topBar:SetRenascimento(cycle, multiplier)
end

-- ===================== API PÚBLICA: NAVEGAÇÃO =====================

function HUDController.OnNavigate(self: HUDControllerHandle, callback: (string) -> ())
	(self :: any)._onNavigateCallback = callback
end

function HUDController.SetActiveScreen(self: HUDControllerHandle, key: string)
	local s = self :: any
	s._sidebar:SetActive(key :: any)
	s._bottomBar:SetActive(key :: any)
end

function HUDController.SetAlbumProgress(self: HUDControllerHandle, current: number, max: number)
	(self :: any)._sidebar:SetAlbumProgress(current, max)
end

function HUDController.SetBackpackCount(self: HUDControllerHandle, count: number)
	local s = self :: any
	s._sidebar:SetBackpackCount(count)
	-- Sem badge visível neste layout (ver Sidebar.lua/BottomBar.lua) — os
	-- dois métodos continuam sendo chamados só pra manter a API compatível.
	s._bottomBar:SetBackpackCount(count)
end

function HUDController.SetPackCooldown(self: HUDControllerHandle, secondsRemaining: number?)
	(self :: any)._sidebar:SetPackCooldown(secondsRemaining)
end

function HUDController.SetWheelNotification(self: HUDControllerHandle, hasNotification: boolean)
	(self :: any)._sidebar:SetWheelNotification(hasNotification)
end

-- ===================== API PÚBLICA: NOTIFICAÇÕES / BADGES =====================

function HUDController.SetBadge(self: HUDControllerHandle, key: string, count: number)
	(self :: any)._topBar:SetBadge(key, count)
end

-- Sem UI própria neste frame (ver header) — mantidos só pra não quebrar
-- Main.client.lua/HUDTest.client.lua, que já chamam esses métodos.
function HUDController.SetStreak(_self: HUDControllerHandle, _currentStreak: number, _nextRewardDay: number, _nextRewardLabel: string)
end

function HUDController.PushNotification(_self: HUDControllerHandle, _item: NotificationItem)
end

-- ===================== API PÚBLICA: RENASCIMENTO / PORTAL =====================

function HUDController.SetRenascimentoProgress(self: HUDControllerHandle, current: number, target: number)
	(self :: any)._progress:SetRenascimentoProgress(current, target)
end

function HUDController.SetAltarStatus(self: HUDControllerHandle, available: boolean)
	(self :: any)._progress:SetAltarStatus(available)
end

function HUDController.SetPortalCountdown(self: HUDControllerHandle, secondsRemaining: number?, active: boolean?)
	(self :: any)._progress:SetPortalCountdown(secondsRemaining, active)
end

-- ===================== API PÚBLICA: TOAST =====================

function HUDController.ShowToast(self: HUDControllerHandle, text: string, accentColor: Color3?)
	local toastLayer = (self :: any)._toastLayer :: Frame
	local TweenService = game:GetService("TweenService")

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 0)
	toast.AutomaticSize = Enum.AutomaticSize.Y
	toast.BackgroundColor3 = Colors.Panel
	toast.BackgroundTransparency = 1
	toast.LayoutOrder = -os.clock()
	toast.Parent = toastLayer
	UIKit.Corner(Layout.Radius.MD).Parent = toast
	local border = UIKit.Stroke(accentColor or Colors.Diamond, 2, 1)
	border.Parent = toast
	UIKit.Padding(0, { left = 14, right = 14, top = 10, bottom = 10 }).Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Colors.Text
	label.FontFace = DesignTokens.Typography.Fonts.Body
	label.TextSize = DesignTokens.Typography.UI.Body
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toast

	TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(border, TweenInfo.new(0.2), { Transparency = 0.2 }):Play()

	task.delay(3, function()
		if not toast.Parent then
			return
		end
		TweenService:Create(border, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		local fadeOut = TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			toast:Destroy()
		end)
	end)
end

function HUDController.Destroy(self: HUDControllerHandle)
	(self :: any).ScreenGui:Destroy()
end

return HUDController
