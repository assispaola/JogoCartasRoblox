--[[
	LevelService.lua
	Checa se o jogador cumpre os requisitos do Desafio de Nível atual, e
	processa a subida de nível (incluindo consumir os sacrifícios, se
	houver). A função CheckRequirement é genérica o bastante pra ser
	reaproveitada pelas Provas de Renascimento.

	Requisitos de posse/sacrifício agora leem do Álbum/Mochila (1 registro
	por criatura descoberta), não mais de `data.cards` por cópia física.
	"Sacrificar" uma cópia vira "remover 1 ponto do Álbum daquela criatura"
	(AlbumService.RemoverPontos) - a criatura continua descoberta (só perde
	1 unidade de progresso), consistente com a venda de cartas.

	Local: ServerScriptService/Server/Systems/LevelService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local AlbumService = require(ServerScriptService.Server.Systems.AlbumService)
local StatsService = require(ServerScriptService.Server.Systems.StatsService)
local ChallengeCatalog = require(ReplicatedStorage.Shared.Data.ChallengeCatalog)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local LevelService = {}

local EconomyService = nil -- carregado em Init() pra evitar circular require

-- Quantas criaturas DISTINTAS descobertas o jogador tem de um clã.
local function countClan(player: Player, clan: string): number
	return #InventoryService.FindDiscoveredCreatures(player, function(_entry, creatureId)
		local creature = Creatures[creatureId]
		return creature ~= nil and creature.clan == clan
	end)
end

-- Verifica se o jogador possui QUALQUER carta de um clã específico.
local function ownsClan(player: Player, clan: string): boolean
	return countClan(player, clan) > 0
end

-- Verifica se o jogador possui uma criatura específica (qualquer raridade).
local function ownsCreature(player: Player, creatureId: number): boolean
	return InventoryService.GetMochilaEntry(player, creatureId) ~= nil
end

-- Quantas criaturas DISTINTAS descobertas o jogador tem numa raridade
-- específica (usado por `sacrificeCardsByRarity`/checks equivalentes).
local function countRarity(player: Player, rarity: string): number
	return #InventoryService.FindDiscoveredCreatures(player, function(entry)
		return entry.raridade == rarity
	end)
end

-- Checa se um requisito específico está cumprido. Retorna:
-- (cumprido: boolean, valorAtual: number, valorNecessário: number)
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
	elseif req.type == "ownClanCount" then
		-- Novo: posse de X criaturas DISTINTAS de um clã (não mais cópias
		-- físicas) - usado pelas Provas de Renascimento reformuladas.
		local current = countClan(player, req.clan)
		return current >= req.count, current, req.count
	elseif req.type == "ownCreature" then
		local owns = ownsCreature(player, req.creatureId)
		return owns, owns and 1 or 0, 1
	elseif req.type == "sacrificeCardsByRarity" then
		local count = countRarity(player, req.rarity)
		return count >= req.count, count, req.count
	elseif req.type == "sacrificeCardsByClan" then
		local count = countClan(player, req.clan)
		return count >= req.count, count, req.count
	elseif req.type == "sacrificeSpecificCreature" then
		local owns = ownsCreature(player, req.creatureId)
		return owns, owns and 1 or 0, 1
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
			local matches = InventoryService.FindDiscoveredCreatures(player, function(entry)
				return entry.raridade == req.rarity
			end)
			for i = 1, math.min(req.count, #matches) do
				AlbumService.RemoverPontos(player, matches[i], 1)
			end
		elseif req.type == "sacrificeCardsByClan" then
			local matches = InventoryService.FindDiscoveredCreatures(player, function(_entry, creatureId)
				local creature = Creatures[creatureId]
				return creature ~= nil and creature.clan == req.clan
			end)
			for i = 1, math.min(req.count, #matches) do
				AlbumService.RemoverPontos(player, matches[i], 1)
			end
		elseif req.type == "sacrificeSpecificCreature" then
			AlbumService.RemoverPontos(player, req.creatureId, 1)
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
	end)

	Remotes.ChallengeStatusRequest.OnServerEvent:Connect(function(player: Player)
		local status = LevelService.GetChallengeStatus(player)
		Remotes.ChallengeStatusUpdated:FireClient(player, status)
	end)
end

return LevelService
