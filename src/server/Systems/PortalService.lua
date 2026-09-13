--[[
	PortalService.lua
	O Portal da Sorte: evento GLOBAL (não por jogador) que abre 1x por dia
	por 30 minutos, sorteando uma das variações do PortalCatalog. Todo
	jogador online durante a janela se beneficia dos efeitos ativos.

	Diferente dos outros sistemas, o estado aqui vive só em memória do
	servidor (não no PlayerData de cada jogador) - é um "relógio" único
	compartilhado.

	Local: ServerScriptService/Server/Systems/PortalService.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PortalCatalog = require(ReplicatedStorage.Shared.Data.PortalCatalog)
local Clans = require(ReplicatedStorage.Shared.Data.Clans)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local PortalService = {}

-- Estado global (não é por jogador) - fica só em memória do servidor.
-- Se o servidor reiniciar, o Portal simplesmente recomeça o ciclo.
-- As anotações de tipo (:: string?, :: {[string]: boolean}) forçam o
-- Luau a tratar esses campos como genéricos, permitindo atribuir valores
-- reais neles depois (mesma lógica aplicada em Rarities.lua/Clans.lua).
local state = {
	active = false,
	scenarioId = nil :: string?,
	label = nil :: string?,
	effects = {} :: { [string]: boolean },
	eclipseClan = nil :: string?,
	endsAt = 0,
	nextEventAt = os.time() + PortalCatalog.IntervalSeconds,
}

-- Multiplicadores usados pelos efeitos (centralizados aqui pra facilitar
-- balanceamento depois)
local ECLIPSE_VALUE_MULTIPLIER = 1.5
local ECLIPSE_PACK_COST_MULTIPLIER = 0.5

function PortalService.GetStatus()
	local now = os.time()
	return {
		active = state.active,
		scenarioId = state.scenarioId,
		label = state.label,
		effects = state.effects,
		eclipseClan = state.eclipseClan,
		secondsRemaining = state.active and math.max(0, state.endsAt - now) or 0,
		secondsUntilNext = state.active and 0 or math.max(0, state.nextEventAt - now),
	}
end

local function broadcastToAll(remote: RemoteEvent, ...)
	for _, player in Players:GetPlayers() do
		remote:FireClient(player, ...)
	end
end

local function startEvent()
	local scenario = PortalCatalog.RollScenario()

	state.active = true
	state.scenarioId = scenario.id
	state.label = scenario.label
	state.effects = scenario.effects
	state.endsAt = os.time() + PortalCatalog.EventDurationSeconds

	if scenario.effects.eclipseClan then
		state.eclipseClan = Clans.Order[math.random(1, #Clans.Order)]
	else
		state.eclipseClan = nil
	end

	broadcastToAll(Remotes.PortalOpened, PortalService.GetStatus())
end

local function endEvent()
	state.active = false
	state.scenarioId = nil
	state.label = nil
	state.effects = {}
	state.eclipseClan = nil
	state.nextEventAt = os.time() + PortalCatalog.IntervalSeconds

	broadcastToAll(Remotes.PortalClosed, PortalService.GetStatus())
end

-- === Funções de consulta usadas por outros sistemas ===

function PortalService.IsEclipseClan(clan: string): boolean
	return state.active and state.effects.eclipseClan == true and state.eclipseClan == clan
end

function PortalService.GetEclipseValueMultiplier(): number
	return ECLIPSE_VALUE_MULTIPLIER
end

function PortalService.GetEclipsePackCostMultiplier(): number
	return ECLIPSE_PACK_COST_MULTIPLIER
end

function PortalService.IsFusionDiscount(): boolean
	return state.active and state.effects.fusionDiscount == true
end

function PortalService.IsDiamondBoost(): boolean
	return state.active and state.effects.diamondBoost == true
end

function PortalService.IsDoublePack(): boolean
	return state.active and state.effects.doublePack == true
end

function PortalService.IsReversedElements(): boolean
	-- Só um flag por enquanto - ganha efeito de verdade quando o sistema
	-- de batalha existir (Fase 6).
	return state.active and state.effects.reversedElements == true
end

-- Loop que checa periodicamente se é hora de abrir ou fechar o Portal.
function PortalService.Init()
	Remotes.PortalStatusRequest.OnServerEvent:Connect(function(player: Player)
		Remotes.PortalStatusUpdated:FireClient(player, PortalService.GetStatus())
	end)

	task.spawn(function()
		while true do
			task.wait(10) -- checa a cada 10s, não precisa ser mais preciso que isso

			local now = os.time()
			if state.active and now >= state.endsAt then
				endEvent()
			elseif not state.active and now >= state.nextEventAt then
				startEvent()
			end
		end
	end)
end

return PortalService
