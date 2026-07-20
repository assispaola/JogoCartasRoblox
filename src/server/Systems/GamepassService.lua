--[[
	GamepassService.lua
	Verifica quais Gamepasses o jogador possui (ao entrar, e sempre que
	compra um novo), aplica os efeitos permanentes correspondentes
	(Mochila +500, Slots de Base +5, etc.), e processa a compra de pacotes de
	Diamante (Dev Products, consumíveis).

	Local: ServerScriptService/Server/Systems/GamepassService.lua
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GamepassCatalog = require(ReplicatedStorage.Shared.Data.GamepassCatalog)

local GamepassService = {}

local EconomyService = nil -- carregado em Init() pra evitar circular require

local BASE_MAX_CARDS = 200
local INVENTARIO_EXTRA_BONUS = 500
local BASE_MAX_PLACED_SLOTS = 20 -- teto fixo dos Slots de Base, independente de nível/Renascimento
local SLOTS_EXTRAS_BONUS = 5

-- Aplica os efeitos "permanentes" (não é por segundo, é só ajustar um
-- número uma vez) de cada gamepass que o jogador possui. Roda de novo
-- sempre que a posse é atualizada, então precisa ser idempotente (rodar
-- várias vezes não pode ficar somando o bônus repetido).
local function applyPermanentEffects(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	data.maxCards = BASE_MAX_CARDS + (data.gamepasses.inventarioExtra and INVENTARIO_EXTRA_BONUS or 0)
	data.maxPlacedSlots = BASE_MAX_PLACED_SLOTS + (data.gamepasses.slotsExtras and SLOTS_EXTRAS_BONUS or 0)

	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = data.gamepasses.vip and 24 or 16 -- 16 é o padrão do Roblox, 24 é +50%
		end
	end
end

-- Verifica a posse de TODOS os gamepasses de uma vez (chamado ao entrar
-- no jogo). Cada chamada a UserOwnsGamePassAsync tem uma leve chance de
-- falhar por instabilidade de rede - por isso o pcall.
function GamepassService.CheckAllOwnership(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	for _, gp in GamepassCatalog.Gamepasses do
		if gp.assetId > 0 then -- ignora entradas ainda não configuradas (assetId placeholder = 0)
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.assetId)
			end)

			if success then
				data.gamepasses[gp.key] = owns
			else
				warn("[GamepassService] Falha ao checar posse de " .. gp.key .. " pra " .. player.Name)
			end
		end
	end

	applyPermanentEffects(player)
	Remotes.GamepassesUpdated:FireClient(player, data.gamepasses)
end

-- Chamado quando o jogador compra um gamepass NA HORA (durante a sessão),
-- via o evento PromptGamePassPurchaseFinished do Roblox.
local function onGamepassPurchaseFinished(player: Player, gamepassAssetId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	local gp = GamepassCatalog.ByAssetId[gamepassAssetId]
	if not gp then
		return
	end

	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	data.gamepasses[gp.key] = true
	applyPermanentEffects(player)
	Remotes.GamepassesUpdated:FireClient(player, data.gamepasses)
end

-- Processa a compra de um Dev Product (pacote de Diamante). Segue o
-- padrão recomendado pelo Roblox: só retorna PurchaseGranted depois de
-- creditar com sucesso, e marca o recibo como processado pra nunca
-- creditar duas vezes o mesmo pagamento (o Roblox pode reenviar o mesmo
-- recibo se a resposta anterior se perder).
local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Jogador não está mais no servidor - o Roblox tenta de novo mais
		-- tarde automaticamente, então é seguro dizer "ainda não".
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = PlayerDataService.GetData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if data.processedReceipts[receiptInfo.PurchaseId] then
		-- Já processamos esse recibo antes - confirma de novo sem creditar
		-- de novo.
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = GamepassCatalog.DiamondByProductId[receiptInfo.ProductId]
	if not product then
		warn("[GamepassService] Dev Product desconhecido: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	EconomyService.AddDiamonds(player, product.amount)
	data.processedReceipts[receiptInfo.PurchaseId] = true

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function GamepassService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchaseFinished)
	MarketplaceService.ProcessReceipt = processReceipt

	Remotes.PromptGamepassPurchaseRequest.OnServerEvent:Connect(function(player: Player, gamepassKey: string)
		local gp = GamepassCatalog.ByKey[gamepassKey]
		if gp and gp.assetId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, gp.assetId)
		end
	end)

	Remotes.PromptDiamondPurchaseRequest.OnServerEvent:Connect(function(player: Player, productId: number)
		if GamepassCatalog.DiamondByProductId[productId] then
			MarketplaceService:PromptProductPurchase(player, productId)
		end
	end)
end

return GamepassService
