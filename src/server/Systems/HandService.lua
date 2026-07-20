--[[
	HandService.lua
	A "Mão": 10 slots simples pra fixar cartas específicas, separadas do
	resto da Mochila, só por organização (sem efeito de jogo por enquanto).

	Nota de design: essa estrutura é genérica de propósito - a ideia é
	poder reaproveitá-la como base do time de batalha na Fase 6 (PvE),
	já que "separar algumas cartas específicas" é exatamente o que um
	time de batalha também precisa.

	Local: ServerScriptService/Server/Systems/HandService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local HandService = {}

local HAND_SLOT_COUNT = 10

-- Fixa uma criatura (por creatureId) num slot da Mão (1 a 10). Se o slot já
-- tiver algo, substitui.
function HandService.PinCard(player: Player, slotIndex: number, creatureId: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	if slotIndex < 1 or slotIndex > HAND_SLOT_COUNT then
		return false
	end

	if not data.mochila[creatureId] then
		return false -- criatura não descoberta (ou foi vendida até sumir)
	end

	data.handSlots[slotIndex] = creatureId
	return true
end

function HandService.UnpinCard(player: Player, slotIndex: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	data.handSlots[slotIndex] = nil
	return true
end

function HandService.Init()
	Remotes.PinCardRequest.OnServerEvent:Connect(function(player: Player, slotIndex: number, cardId: number)
		local success = HandService.PinCard(player, slotIndex, cardId)
		local data = PlayerDataService.GetData(player)
		Remotes.HandUpdated:FireClient(player, success, data and data.handSlots or nil)
	end)

	Remotes.UnpinCardRequest.OnServerEvent:Connect(function(player: Player, slotIndex: number)
		local success = HandService.UnpinCard(player, slotIndex)
		local data = PlayerDataService.GetData(player)
		Remotes.HandUpdated:FireClient(player, success, data and data.handSlots or nil)
	end)
end

return HandService
