--[[
	TradeService.lua
	Troca bilateral: dois jogadores montam uma "oferta" (lista de cartas
	cada um), e só executa quando os DOIS confirmarem. Se qualquer um
	mexer na oferta depois de confirmar, as confirmações resetam (evita o
	golpe clássico de "confirmar, esperar o outro confirmar, trocar a
	oferta na última hora").

	As sessões de troca ficam só em memória (não são salvas no DataStore) -
	se o servidor reiniciar no meio de uma negociação, ela simplesmente
	some, sem problema (nenhuma carta chega a se mover até a confirmação
	dupla).

	Local: ServerScriptService/Server/Systems/TradeService.lua
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local TradeService = {}

-- sessions[sessionId] = {
--   playerAId, playerBId,
--   offerA = { [cardId] = true }, offerB = { [cardId] = true },
--   confirmedA = false, confirmedB = false,
-- }
local sessions = {}
local nextSessionId = 1

local function getSessionForPlayer(player: Player)
	for sessionId, session in sessions do
		if session.playerAId == player.UserId or session.playerBId == player.UserId then
			return sessionId, session
		end
	end
	return nil, nil
end

-- Retorna, dentro de uma sessão, qual "lado" (A ou B) é esse jogador.
local function getSide(session, userId: number): string?
	if session.playerAId == userId then
		return "A"
	elseif session.playerBId == userId then
		return "B"
	end
	return nil
end

local function broadcastSessionState(sessionId: number)
	local session = sessions[sessionId]
	if not session then
		return
	end

	local playerA = Players:GetPlayerByUserId(session.playerAId)
	local playerB = Players:GetPlayerByUserId(session.playerBId)

	local state = {
		sessionId = sessionId,
		offerA = session.offerA,
		offerB = session.offerB,
		confirmedA = session.confirmedA,
		confirmedB = session.confirmedB,
	}

	if playerA then
		Remotes.TradeUpdated:FireClient(playerA, state)
	end
	if playerB then
		Remotes.TradeUpdated:FireClient(playerB, state)
	end
end

-- Inicia uma sessão de troca entre dois jogadores. Retorna o sessionId, ou
-- nil + motivo do erro.
function TradeService.StartTrade(playerA: Player, toUserId: number)
	if playerA.UserId == toUserId then
		return nil, "Você não pode trocar consigo mesmo"
	end

	local playerB = Players:GetPlayerByUserId(toUserId)
	if not playerB then
		return nil, "Jogador de destino não está no servidor"
	end

	-- Impede um jogador de abrir 2 negociações ao mesmo tempo (simplifica
	-- bastante a lógica de segurança).
	if select(1, getSessionForPlayer(playerA)) then
		return nil, "Você já está numa negociação"
	end
	if select(1, getSessionForPlayer(playerB)) then
		return nil, "O outro jogador já está numa negociação"
	end

	local sessionId = nextSessionId
	nextSessionId += 1

	sessions[sessionId] = {
		playerAId = playerA.UserId,
		playerBId = playerB.UserId,
		offerA = {},
		offerB = {},
		confirmedA = false,
		confirmedB = false,
	}

	Remotes.TradeStarted:FireClient(playerA, sessionId, playerB.UserId)
	Remotes.TradeStarted:FireClient(playerB, sessionId, playerA.UserId)
	broadcastSessionState(sessionId)

	return sessionId
end

-- Adiciona ou remove uma carta da oferta de um jogador. Qualquer mudança
-- reseta as duas confirmações (segurança contra "troca de última hora").
function TradeService.UpdateOffer(player: Player, sessionId: number, cardId: number, include: boolean)
	local session = sessions[sessionId]
	if not session then
		return false, "Negociação não encontrada"
	end

	local side = getSide(session, player.UserId)
	if not side then
		return false, "Você não faz parte dessa negociação"
	end

	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	if include then
		local card = data.cards[cardId]
		if not card then
			return false, "Você não possui essa carta"
		end
		if card.placed then
			return false, "Tire a carta da base antes de oferecer"
		end
	end

	local offerKey = (side == "A") and "offerA" or "offerB"
	if include then
		session[offerKey][cardId] = true
	else
		session[offerKey][cardId] = nil
	end

	session.confirmedA = false
	session.confirmedB = false

	broadcastSessionState(sessionId)
	return true
end

-- Confirma a oferta atual. Quando os dois confirmarem, executa a troca.
function TradeService.Confirm(player: Player, sessionId: number)
	local session = sessions[sessionId]
	if not session then
		return false, "Negociação não encontrada"
	end

	local side = getSide(session, player.UserId)
	if not side then
		return false, "Você não faz parte dessa negociação"
	end

	if side == "A" then
		session.confirmedA = true
	else
		session.confirmedB = true
	end

	if session.confirmedA and session.confirmedB then
		return TradeService.Execute(sessionId)
	end

	broadcastSessionState(sessionId)
	return true
end

-- Executa a troca de verdade: revalida TUDO no servidor (as cartas ainda
-- existem? ainda não foram colocadas na base ou vendidas desde que
-- entraram na oferta?), e só move as cartas se as duas ofertas inteiras
-- forem válidas. Tudo ou nada.
function TradeService.Execute(sessionId: number)
	local session = sessions[sessionId]
	if not session then
		return false, "Negociação não encontrada"
	end

	local playerA = Players:GetPlayerByUserId(session.playerAId)
	local playerB = Players:GetPlayerByUserId(session.playerBId)

	if not playerA or not playerB then
		sessions[sessionId] = nil
		return false, "Um dos jogadores saiu do servidor"
	end

	local dataA = PlayerDataService.GetData(playerA)
	local dataB = PlayerDataService.GetData(playerB)

	-- Revalida cada carta oferecida - ainda existe, ainda pertence a quem
	-- ofereceu, ainda não está na base.
	for cardId in session.offerA do
		local card = dataA.cards[cardId]
		if not card or card.placed then
			sessions[sessionId] = nil
			return false, "Oferta de " .. playerA.Name .. " ficou inválida (carta movida/vendida)"
		end
	end
	for cardId in session.offerB do
		local card = dataB.cards[cardId]
		if not card or card.placed then
			sessions[sessionId] = nil
			return false, "Oferta de " .. playerB.Name .. " ficou inválida (carta movida/vendida)"
		end
	end

	-- Checa capacidade de Mochila dos dois lados antes de mover qualquer coisa.
	local countA = 0
	for _ in session.offerA do
		countA += 1
	end
	local countB = 0
	for _ in session.offerB do
		countB += 1
	end

	if not InventoryService.HasSpace(playerA, countB - countA) then
		sessions[sessionId] = nil
		return false, "Mochila de " .. playerA.Name .. " não tem espaço suficiente"
	end
	if not InventoryService.HasSpace(playerB, countA - countB) then
		sessions[sessionId] = nil
		return false, "Mochila de " .. playerB.Name .. " não tem espaço suficiente"
	end

	-- Move tudo: A entrega pra B, B entrega pra A.
	for cardId in session.offerA do
		local card = dataA.cards[cardId]
		InventoryService.RemoveCard(playerA, cardId)
		InventoryService.AddCard(playerB, card.creatureId, card.rarity, card.grade)
	end
	for cardId in session.offerB do
		local card = dataB.cards[cardId]
		InventoryService.RemoveCard(playerB, cardId)
		InventoryService.AddCard(playerA, card.creatureId, card.rarity, card.grade)
	end

	sessions[sessionId] = nil

	Remotes.TradeCompleted:FireClient(playerA, true)
	Remotes.TradeCompleted:FireClient(playerB, true)

	return true
end

function TradeService.Cancel(player: Player, sessionId: number)
	local session = sessions[sessionId]
	if not session then
		return false
	end

	local side = getSide(session, player.UserId)
	if not side then
		return false
	end

	local playerA = Players:GetPlayerByUserId(session.playerAId)
	local playerB = Players:GetPlayerByUserId(session.playerBId)

	sessions[sessionId] = nil

	if playerA then
		Remotes.TradeCancelled:FireClient(playerA)
	end
	if playerB then
		Remotes.TradeCancelled:FireClient(playerB)
	end

	return true
end

-- Limpa qualquer sessão pendente se um dos jogadores sair do servidor no
-- meio de uma negociação.
function TradeService.CancelSessionsForPlayer(player: Player)
	local sessionId = getSessionForPlayer(player)
	if sessionId then
		TradeService.Cancel(player, sessionId)
	end
end

function TradeService.Init()
	Remotes.StartTradeRequest.OnServerEvent:Connect(function(player: Player, toUserId: number)
		local sessionId, errorReason = TradeService.StartTrade(player, toUserId)
		if not sessionId then
			Remotes.TradeUpdated:FireClient(player, nil, errorReason)
		end
	end)

	Remotes.UpdateTradeOfferRequest.OnServerEvent:Connect(
		function(player: Player, sessionId: number, cardId: number, include: boolean)
			TradeService.UpdateOffer(player, sessionId, cardId, include)
		end
	)

	Remotes.ConfirmTradeRequest.OnServerEvent:Connect(function(player: Player, sessionId: number)
		TradeService.Confirm(player, sessionId)
	end)

	Remotes.CancelTradeRequest.OnServerEvent:Connect(function(player: Player, sessionId: number)
		TradeService.Cancel(player, sessionId)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		TradeService.CancelSessionsForPlayer(player)
	end)
end

return TradeService
