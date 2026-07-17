--[[
	LevelService.lua
	Checa se o jogador cumpre os requisitos do Desafio de Nível atual, e
	processa a subida de nível (incluindo consumir os sacrifícios, se
	houver). A função CheckRequirement é genérica o bastante pra ser
	reaproveitada depois pelas Provas de Renascimento.

	Local: ServerScriptService/Server/Systems/LevelService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local StatsService = require(ServerScriptService.Server.Systems.StatsService)
local ChallengeCatalog = require(ReplicatedStorage.Shared.Data.ChallengeCatalog)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local LevelService = {}

local EconomyService = nil -- carregado em Init() pra evitar circular require

-- Verifica se o jogador possui QUALQUER carta de um clã específico.
local function ownsClan(player: Player, clan: string): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	for _, card in data.cards do
		local creature = Creatures[card.creatureId]
		if creature and creature.clan == clan then
			return true
		end
	end
	return false
end

-- Verifica se o jogador possui uma criatura específica (qualquer raridade).
local function ownsCreature(player: Player, creatureId: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	for _, card in data.cards do
		if card.creatureId == creatureId then
			return true
		end
	end
	return false
end

-- Checa se um requisito específico está cumprido. Retorna:
-- (cumprido: boolean, valorAtual: number, valorNecessário: number)
-- Os dois últimos valores são só pra UI mostrar progresso (ex: "3/5 pacotes").
function LevelService.CheckRequirement(player: Player, req)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, 0, 0
	end

	if req.type == "money" or req.type == "sacrificeMoney" then
		return data.money >= req.amount, data.money, req.amount
	elseif req.type == "playerLevel" then
		return data.level >= req.amount, data.level, req.amount
	elseif req.type == "packsOpened" then
		local current = StatsService.Get(player, "packsOpened")
		return current >= req.amount, current, req.amount
	elseif req.type == "discoveries" then
		local current = StatsService.Get(player, "discoveries")
		return current >= req.amount, current, req.amount
	elseif req.type == "fusions" then
		local current = StatsService.Get(player, "fusions")
		return current >= req.amount, current, req.amount
	elseif req.type == "awakensImproved" then
		local current = StatsService.Get(player, "awakensImproved")
		return current >= req.amount, current, req.amount
	elseif req.type == "ownClan" then
		local owns = ownsClan(player, req.clan)
		return owns, owns and 1 or 0, 1
	elseif req.type == "ownCreature" then
		local owns = ownsCreature(player, req.creatureId)
		return owns, owns and 1 or 0, 1
	elseif req.type == "sacrificeCardsByRarity" then
		local count = #InventoryService.FindUnplacedCards(player, function(c)
			return c.rarity == req.rarity
		end)
		return count >= req.count, count, req.count
	elseif req.type == "sacrificeCardsByClan" then
		local count = #InventoryService.FindUnplacedCards(player, function(c)
			local creature = Creatures[c.creatureId]
			return creature ~= nil and creature.clan == req.clan
		end)
		return count >= req.count, count, req.count
	elseif req.type == "sacrificeSpecificCreature" then
		local count = #InventoryService.FindUnplacedCards(player, function(c)
			return c.creatureId == req.creatureId
		end)
		return count >= 1, count, 1
	end

	warn("[LevelService] Tipo de requisito desconhecido: " .. tostring(req.type))
	return false, 0, 0
end

-- Retorna o status completo do desafio atual: se pode subir de nível, e o
-- progresso de cada requisito individualmente (pra UI mostrar barra/checklist).
function LevelService.GetChallengeStatus(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local challenge = ChallengeCatalog.GetChallenge(data.level)
	local statuses = {}
	local allMet = true

	for _, req in challenge do
		local met, current, needed = LevelService.CheckRequirement(player, req)
		table.insert(statuses, {
			requirement = req,
			met = met,
			current = current,
			needed = needed,
		})
		if not met then
			allMet = false
		end
	end

	return {
		level = data.level,
		canLevelUp = allMet,
		requirements = statuses,
	}
end

-- Tenta subir de nível: reconfirma TODOS os requisitos (nunca confia só no
-- que o cliente mandou), e se tudo bater, consome os sacrifícios e
-- incrementa o nível. Tudo ou nada - se qualquer requisito falhar, nada é
-- consumido.
function LevelService.TryLevelUp(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local challenge = ChallengeCatalog.GetChallenge(data.level)

	for _, req in challenge do
		local met = LevelService.CheckRequirement(player, req)
		if not met then
			return false, "Requisitos do desafio ainda não cumpridos"
		end
	end

	-- Todos os requisitos bateram - agora sim consome os sacrifícios.
	for _, req in challenge do
		if req.type == "sacrificeMoney" then
			EconomyService.TrySpendMoney(player, req.amount)
		elseif req.type == "sacrificeCardsByRarity" then
			local matches = InventoryService.FindUnplacedCards(player, function(c)
				return c.rarity == req.rarity
			end)
			for i = 1, req.count do
				InventoryService.RemoveCard(player, matches[i])
			end
		elseif req.type == "sacrificeCardsByClan" then
			local matches = InventoryService.FindUnplacedCards(player, function(c)
				local creature = Creatures[c.creatureId]
				return creature ~= nil and creature.clan == req.clan
			end)
			for i = 1, req.count do
				InventoryService.RemoveCard(player, matches[i])
			end
		elseif req.type == "sacrificeSpecificCreature" then
			local matches = InventoryService.FindUnplacedCards(player, function(c)
				return c.creatureId == req.creatureId
			end)
			InventoryService.RemoveCard(player, matches[1])
		end
	end

	data.level += 1
	Remotes.LevelUpResult:FireClient(player, true, data.level)

	return true, data.level
end

function LevelService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.LevelUpRequest.OnServerEvent:Connect(function(player: Player)
		local success, resultOrError = LevelService.TryLevelUp(player)
		if not success then
			Remotes.LevelUpResult:FireClient(player, false, resultOrError)
		end
		-- Em caso de sucesso, o próprio TryLevelUp já disparou o
		-- LevelUpResult com os dados certos.
	end)

	Remotes.ChallengeStatusRequest.OnServerEvent:Connect(function(player: Player)
		local status = LevelService.GetChallengeStatus(player)
		Remotes.ChallengeStatusUpdated:FireClient(player, status)
	end)
end

return LevelService
