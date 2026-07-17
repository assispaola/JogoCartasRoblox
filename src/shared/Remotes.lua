--[[
	Remotes.lua
	Define e centraliza todos os RemoteEvents/RemoteFunctions do jogo.

	Por que centralizar assim: em vez de cada sistema criar seus próprios
	RemoteEvents espalhados, criamos todos aqui, uma vez só, e tanto o
	servidor quanto o cliente puxam desse mesmo lugar. Evita duplicar nomes
	ou esquecer de criar um remote em algum lado.

	Uso:
		local Remotes = require(ReplicatedStorage.Shared.Remotes)
		Remotes.MoneyUpdated:FireClient(player, novoValor)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Pasta que vai guardar todos os RemoteEvents dentro do ReplicatedStorage
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

-- Função auxiliar: pega o RemoteEvent se já existe, ou cria se não existe.
-- Isso permite que tanto o servidor quanto o cliente rodem esse mesmo
-- arquivo sem dar erro de "já existe" ou "não existe".
local function getOrCreateRemoteEvent(name: string): RemoteEvent
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote :: RemoteEvent
end

-- === Remotes de Economia ===
Remotes.MoneyUpdated = getOrCreateRemoteEvent("MoneyUpdated") -- servidor -> cliente: avisa novo valor de dinheiro
Remotes.IncomePerSecondUpdated = getOrCreateRemoteEvent("IncomePerSecondUpdated") -- servidor -> cliente: avisa novo $/s total
Remotes.OfflineEarningsReady = getOrCreateRemoteEvent("OfflineEarningsReady") -- servidor -> cliente: "você ganhou X offline"

-- === Remotes de Pacotes ===
Remotes.BuyPackRequest = getOrCreateRemoteEvent("BuyPackRequest") -- cliente -> servidor: "quero comprar pacote X"
Remotes.PackOpened = getOrCreateRemoteEvent("PackOpened") -- servidor -> cliente: "aqui está o que você ganhou"
Remotes.UnlockedPacksRequest = getOrCreateRemoteEvent("UnlockedPacksRequest") -- cliente -> servidor: "me manda os pacotes que já desbloqueei"
Remotes.UnlockedPacksUpdated = getOrCreateRemoteEvent("UnlockedPacksUpdated") -- servidor -> cliente: lista de pacotes desbloqueados

-- === Remotes de Colocação na Base (Inventário) ===
Remotes.PlaceCreatureRequest = getOrCreateRemoteEvent("PlaceCreatureRequest") -- cliente -> servidor: "quero colocar essa carta (cardId) na base"
Remotes.UnplaceCreatureRequest = getOrCreateRemoteEvent("UnplaceCreatureRequest") -- cliente -> servidor: "quero tirar a carta desse slot da base"
Remotes.PlacementResult = getOrCreateRemoteEvent("PlacementResult") -- servidor -> cliente: resultado da tentativa (sucesso/erro)

-- === Remotes de Evolução/Fusão ===
Remotes.FuseCreatureRequest = getOrCreateRemoteEvent("FuseCreatureRequest") -- cliente -> servidor: "quero evoluir essa criatura"
Remotes.FusionResult = getOrCreateRemoteEvent("FusionResult") -- servidor -> cliente: resultado da fusão (sucesso/erro)

-- === Remotes de Diamante e Despertar ===
Remotes.DiamondsUpdated = getOrCreateRemoteEvent("DiamondsUpdated") -- servidor -> cliente: avisa novo saldo de Diamante
Remotes.AwakenRequest = getOrCreateRemoteEvent("AwakenRequest") -- cliente -> servidor: "quero despertar essa carta"
Remotes.AwakenResult = getOrCreateRemoteEvent("AwakenResult") -- servidor -> cliente: resultado do Despertar

-- === Remotes de Venda ===
Remotes.SellCardRequest = getOrCreateRemoteEvent("SellCardRequest") -- cliente -> servidor: "quero vender essa carta"
Remotes.SellCardResult = getOrCreateRemoteEvent("SellCardResult") -- servidor -> cliente: resultado da venda

-- === Remotes de Equipar Melhor ===
Remotes.EquipBestRequest = getOrCreateRemoteEvent("EquipBestRequest") -- cliente -> servidor: "reorganize a base com as melhores cartas"
Remotes.EquipBestResult = getOrCreateRemoteEvent("EquipBestResult") -- servidor -> cliente: quantas cartas foram equipadas

-- === Remotes de Venda Automática ===
Remotes.SetAutoSellConfigRequest = getOrCreateRemoteEvent("SetAutoSellConfigRequest") -- cliente -> servidor: liga/desliga uma categoria
Remotes.AutoSellConfigUpdated = getOrCreateRemoteEvent("AutoSellConfigUpdated") -- servidor -> cliente: config atual

-- === Remotes da Mão ===
Remotes.PinCardRequest = getOrCreateRemoteEvent("PinCardRequest") -- cliente -> servidor: fixar carta num slot da Mão
Remotes.UnpinCardRequest = getOrCreateRemoteEvent("UnpinCardRequest") -- cliente -> servidor: soltar carta de um slot da Mão
Remotes.HandUpdated = getOrCreateRemoteEvent("HandUpdated") -- servidor -> cliente: estado atual da Mão

-- === Remotes de Nível/Desafio ===
Remotes.LevelUpRequest = getOrCreateRemoteEvent("LevelUpRequest") -- cliente -> servidor: "quero subir de nível"
Remotes.LevelUpResult = getOrCreateRemoteEvent("LevelUpResult") -- servidor -> cliente: resultado da tentativa
Remotes.ChallengeStatusRequest = getOrCreateRemoteEvent("ChallengeStatusRequest") -- cliente -> servidor: "me manda o status do desafio atual"
Remotes.ChallengeStatusUpdated = getOrCreateRemoteEvent("ChallengeStatusUpdated") -- servidor -> cliente: status detalhado dos requisitos

-- === Remotes do Relicário ===
Remotes.MoveToRelicarioRequest = getOrCreateRemoteEvent("MoveToRelicarioRequest") -- cliente -> servidor: guardar carta no Relicário
Remotes.MoveFromRelicarioRequest = getOrCreateRemoteEvent("MoveFromRelicarioRequest") -- cliente -> servidor: retirar carta do Relicário
Remotes.RelicarioResult = getOrCreateRemoteEvent("RelicarioResult") -- servidor -> cliente: resultado da tentativa

-- === Remotes de Renascimento ===
Remotes.RenascerRequest = getOrCreateRemoteEvent("RenascerRequest") -- cliente -> servidor: "quero renascer"
Remotes.RenascimentoResult = getOrCreateRemoteEvent("RenascimentoResult") -- servidor -> cliente: resultado da tentativa
Remotes.ProvaStatusRequest = getOrCreateRemoteEvent("ProvaStatusRequest") -- cliente -> servidor: "me manda o status da Prova atual"
Remotes.ProvaStatusUpdated = getOrCreateRemoteEvent("ProvaStatusUpdated") -- servidor -> cliente: status detalhado dos requisitos

-- === Remote de Snapshot Completo ===
Remotes.GetPlayerSnapshotRequest = getOrCreateRemoteEvent("GetPlayerSnapshotRequest") -- cliente -> servidor: "me manda todos os meus dados de uma vez"
Remotes.PlayerSnapshotResult = getOrCreateRemoteEvent("PlayerSnapshotResult") -- servidor -> cliente: retrato completo (cartas, Índice, config, Relicário, etc.)

-- === Remotes de Doação (Pacto dos Guardiões) ===
Remotes.DonateCardRequest = getOrCreateRemoteEvent("DonateCardRequest") -- cliente -> servidor: "quero doar essa carta pra esse jogador"
Remotes.DonateCardResult = getOrCreateRemoteEvent("DonateCardResult") -- servidor -> cliente: resultado da doação

-- === Remotes de Troca (Pacto dos Guardiões) ===
Remotes.StartTradeRequest = getOrCreateRemoteEvent("StartTradeRequest") -- cliente -> servidor: "quero trocar com esse jogador"
Remotes.TradeStarted = getOrCreateRemoteEvent("TradeStarted") -- servidor -> cliente: negociação iniciada
Remotes.UpdateTradeOfferRequest = getOrCreateRemoteEvent("UpdateTradeOfferRequest") -- cliente -> servidor: adicionar/remover carta da oferta
Remotes.TradeUpdated = getOrCreateRemoteEvent("TradeUpdated") -- servidor -> cliente: estado atual da negociação
Remotes.ConfirmTradeRequest = getOrCreateRemoteEvent("ConfirmTradeRequest") -- cliente -> servidor: "confirmo minha oferta"
Remotes.CancelTradeRequest = getOrCreateRemoteEvent("CancelTradeRequest") -- cliente -> servidor: "quero cancelar a negociação"
Remotes.TradeCompleted = getOrCreateRemoteEvent("TradeCompleted") -- servidor -> cliente: troca executada com sucesso
Remotes.TradeCancelled = getOrCreateRemoteEvent("TradeCancelled") -- servidor -> cliente: negociação cancelada

-- === Remotes da Roda do Destino ===
Remotes.SpinWheelRequest = getOrCreateRemoteEvent("SpinWheelRequest") -- cliente -> servidor: "quero girar" (grátis ou pago)
Remotes.SpinWheelResult = getOrCreateRemoteEvent("SpinWheelResult") -- servidor -> cliente: resultado do giro
Remotes.WheelStatusRequest = getOrCreateRemoteEvent("WheelStatusRequest") -- cliente -> servidor: "me manda o status da roleta"
Remotes.WheelStatusUpdated = getOrCreateRemoteEvent("WheelStatusUpdated") -- servidor -> cliente: status (giro grátis disponível? quantos pagos restam?)

-- === Remotes da Bênção Diária ===
Remotes.ClaimDailyBlessingRequest = getOrCreateRemoteEvent("ClaimDailyBlessingRequest") -- cliente -> servidor: "quero resgatar a bênção de hoje"
Remotes.DailyBlessingResult = getOrCreateRemoteEvent("DailyBlessingResult") -- servidor -> cliente: resultado do resgate
Remotes.DailyBlessingStatusRequest = getOrCreateRemoteEvent("DailyBlessingStatusRequest") -- cliente -> servidor: "me manda o status da bênção"
Remotes.DailyBlessingStatusUpdated = getOrCreateRemoteEvent("DailyBlessingStatusUpdated") -- servidor -> cliente: status (disponível? streak atual? próxima recompensa?)

-- === Remotes dos Baús da Jornada ===
Remotes.ClaimJourneyChestRequest = getOrCreateRemoteEvent("ClaimJourneyChestRequest") -- cliente -> servidor: "quero resgatar esse baú"
Remotes.JourneyChestResult = getOrCreateRemoteEvent("JourneyChestResult") -- servidor -> cliente: resultado do resgate
Remotes.JourneyChestStatusRequest = getOrCreateRemoteEvent("JourneyChestStatusRequest") -- cliente -> servidor: "me manda o status dos baús"
Remotes.JourneyChestStatusUpdated = getOrCreateRemoteEvent("JourneyChestStatusUpdated") -- servidor -> cliente: status de todos os baús do ciclo

-- === Remotes do Portal da Sorte (evento global) ===
Remotes.PortalOpened = getOrCreateRemoteEvent("PortalOpened") -- servidor -> TODOS os clientes: o Portal abriu, com qual variação
Remotes.PortalClosed = getOrCreateRemoteEvent("PortalClosed") -- servidor -> TODOS os clientes: o Portal fechou
Remotes.PortalStatusRequest = getOrCreateRemoteEvent("PortalStatusRequest") -- cliente -> servidor: "me manda o status do Portal"
Remotes.PortalStatusUpdated = getOrCreateRemoteEvent("PortalStatusUpdated") -- servidor -> cliente: status atual (aberto? qual variação? quanto tempo falta?)

-- === Remotes de Coleta Manual de Renda ===
Remotes.CollectSlotRequest = getOrCreateRemoteEvent("CollectSlotRequest") -- cliente -> servidor: "coleta a renda pendente desse slot"
Remotes.CollectAllSlotsRequest = getOrCreateRemoteEvent("CollectAllSlotsRequest") -- cliente -> servidor: "coleta tudo de uma vez"
Remotes.SlotPendingUpdated = getOrCreateRemoteEvent("SlotPendingUpdated") -- servidor -> cliente: estado atual de renda pendente por slot

-- === Remotes de Gamepasses/Loja ===
Remotes.GamepassesUpdated = getOrCreateRemoteEvent("GamepassesUpdated") -- servidor -> cliente: quais gamepasses o jogador possui
Remotes.PromptGamepassPurchaseRequest = getOrCreateRemoteEvent("PromptGamepassPurchaseRequest") -- cliente -> servidor: "abre o prompt de compra desse gamepass"
Remotes.PromptDiamondPurchaseRequest = getOrCreateRemoteEvent("PromptDiamondPurchaseRequest") -- cliente -> servidor: "abre o prompt de compra desse pacote de Diamante"

return Remotes
