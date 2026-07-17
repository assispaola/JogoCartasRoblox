--[[
	DonationService.lua
	Doação unilateral de carta: um jogador entrega uma carta pra outro, sem
	nada em troca. Mais simples que a Troca (não precisa de confirmação dos
	dois lados), mas ainda precisa validar tudo no servidor - nunca confiar
	que o cliente mandou um cardId que realmente pertence a quem está
	doando.

	Local: ServerScriptService/Server/Systems/DonationService.lua
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DonationService = {}

-- Tenta doar uma carta de `fromPlayer` pra `toPlayer`. Retorna true em caso
-- de sucesso, ou false + motivo do erro.
function DonationService.TryDonate(fromPlayer: Player, toUserId: number, cardId: number)
	if fromPlayer.UserId == toUserId then
		return false, "Você não pode doar uma carta pra si mesmo"
	end

	local toPlayer = Players:GetPlayerByUserId(toUserId)
	if not toPlayer then
		return false, "Jogador de destino não está no servidor"
	end

	local fromData = PlayerDataService.GetData(fromPlayer)
	if not fromData then
		return false, "Dados não carregados"
	end

	local card = fromData.cards[cardId]
	if not card then
		return false, "Você não possui essa carta"
	end

	if card.placed then
		return false, "Tire a carta da base antes de doar"
	end

	if not InventoryService.HasSpace(toPlayer, 1) then
		return false, "A Mochila do destinatário está cheia"
	end

	-- Remove de quem doou e recria do lado de quem recebe, preservando o
	-- grau de Despertar (a carta chega exatamente como estava, sem resetar
	-- o progresso investido nela).
	InventoryService.RemoveCard(fromPlayer, cardId)
	InventoryService.AddCard(toPlayer, card.creatureId, card.rarity, card.grade)

	return true
end

function DonationService.Init()
	Remotes.DonateCardRequest.OnServerEvent:Connect(function(fromPlayer: Player, toUserId: number, cardId: number)
		local success, errorReason = DonationService.TryDonate(fromPlayer, toUserId, cardId)
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
