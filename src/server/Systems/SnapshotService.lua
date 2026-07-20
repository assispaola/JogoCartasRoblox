--[[
	SnapshotService.lua
	Monta e envia o "retrato completo" dos dados do jogador de uma vez só -
	usado tanto automaticamente ao entrar no jogo (Main.server.lua chama
	isso depois de carregar os dados) quanto sob demanda, se o cliente
	precisar re-sincronizar (ex: depois de reconectar, ou ao abrir uma UI
	que precisa do estado completo, como a Mochila ou o Álbum).

	Local: ServerScriptService/Server/Systems/SnapshotService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SnapshotService = {}

-- Monta a tabela de snapshot. Os dados de referência (Creatures, Clans,
-- Rarities, Grades) NÃO entram aqui de propósito - o cliente já tem esses
-- módulos disponíveis direto via ReplicatedStorage.Shared.Data, não
-- precisa duplicar isso a cada snapshot.
function SnapshotService.BuildSnapshot(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	return {
		money = data.money,
		diamonds = data.diamonds,
		totalIncomePerSecond = data.totalIncomePerSecond,
		level = data.level,
		stats = data.stats,
		album = data.album,
		mochila = data.mochila,
		altarSacrificio = data.altarSacrificio,
		placedSlots = data.placedSlots,
		discovered = data.discovered,
		maxCards = data.maxCards,
		autoSell = data.autoSell,
		handSlots = data.handSlots,
		renascimentoLevel = data.renascimentoLevel,
		renascimentoMultiplier = data.renascimentoMultiplier,
		gamepasses = data.gamepasses,
		slotPending = data.slotPending,
	}
end

-- Monta e já envia o snapshot pro cliente. Chamado automaticamente pelo
-- Main.server.lua assim que os dados do jogador terminam de carregar.
function SnapshotService.SendSnapshot(player: Player)
	local snapshot = SnapshotService.BuildSnapshot(player)
	if snapshot then
		Remotes.PlayerSnapshotResult:FireClient(player, snapshot)
	end
end

function SnapshotService.Init()
	Remotes.GetPlayerSnapshotRequest.OnServerEvent:Connect(function(player: Player)
		SnapshotService.SendSnapshot(player)
	end)
end

return SnapshotService
