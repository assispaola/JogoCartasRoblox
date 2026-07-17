--[[
	StatsService.lua
	Contadores cumulativos usados pelos requisitos de Desafio de Nível (e,
	mais pra frente, Provas de Renascimento). Centralizar aqui evita que
	cada sistema (PackService, FusionService, etc.) mexa direto na tabela
	de dados do jogador.

	Local: ServerScriptService/Server/Systems/StatsService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)

local StatsService = {}

-- Incrementa um contador (ex: "packsOpened", "discoveries", "fusions",
-- "awakensImproved") em `amount` (padrão 1).
function StatsService.Increment(player: Player, statName: string, amount: number?)
	local data = PlayerDataService.GetData(player)
	if not data or not data.stats then
		return
	end

	if data.stats[statName] == nil then
		warn("[StatsService] Estatística desconhecida: " .. tostring(statName))
		return
	end

	data.stats[statName] += (amount or 1)
end

function StatsService.Get(player: Player, statName: string): number
	local data = PlayerDataService.GetData(player)
	if not data or not data.stats then
		return 0
	end
	return data.stats[statName] or 0
end

return StatsService
