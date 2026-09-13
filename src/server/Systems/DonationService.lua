--[[
	DonationService.lua
	Doação unilateral de carta: um jogador entrega 1 cópia de uma criatura
	(por creatureId) pra outro, sem nada em troca. Mais simples que a Troca
	(não precisa de confirmação dos dois lados), mas ainda precisa validar
	tudo no servidor - nunca confiar que o cliente mandou um creatureId que
	o doador realmente possui no Álbum.

	Local: ServerScriptService/Server/Systems/DonationService.lua
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local AlbumService = require(ServerScriptService.Server.Systems.AlbumService)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local DonationService = {}

-- Tenta doar 1 unidade de progresso (raridade atual) de uma criatura de
-- `fromPlayer` pra `toPlayer`. Sob o modelo de Álbum (1 registro por
-- criatura, sem cópias físicas), "doar uma carta" vira "abrir mão de 1
-- ponto/cópia daquela criatura, e o destinatário registra 1 cópia daquela
-- raridade" - mesma matemática usada por SellService.VenderCopias.
function DonationService.TryDonate(fromPlayer: Player, toUserId: number, creatureId: number)
	if fromPlayer.UserId == toUserId then
		return false, "Você não pode doar uma carta pra si mesmo"
	end

	local toPlayer = Players:GetPlayerByUserId(toUserId)
	if not toPlayer then
		return false, "Jogador de destino não está no servidor"
	end

	local entry = AlbumService.GetEntrada(fromPlayer, creatureId)
	if not entry then
		return false, "Você não possui essa criatura"
	end

	if not InventoryService.HasSpace(toPlayer, 1) then
		return false, "A Mochila do destinatário está cheia"
	end

	AlbumService.RemoverPontos(fromPlayer, creatureId, 1)
	AlbumService.RegistrarCopia(toPlayer, creatureId, entry.raridade)

	return true
end

function DonationService.Init()
	Remotes.DonateCardRequest.OnServerEvent:Connect(function(fromPlayer: Player, toUserId: number, creatureId: number)
		local success, errorReason = DonationService.TryDonate(fromPlayer, toUserId, creatureId)
		Remotes.DonateCardResult:FireClient(fromPlayer, success, errorReason)

		if success then
			local toPlayer = Players:GetPlayerByUserId(toUserId)
			if toPlayer then
				Remotes.DonateCardResult:FireClient(toPlayer, true, "Você recebeu uma doação de " .. fromPlayer.Name)
			end
		end
	end)
end

return DonationService
