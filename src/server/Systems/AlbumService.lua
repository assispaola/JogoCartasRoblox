--[[
	AlbumService.lua

	Fonte da verdade de raridade, cópias acumuladas e grau de Despertar POR
	CRIATURA (não mais por cópia física). Substitui:
	  - FusionService (evolução manual por fusão) -> evolução automática,
	    ver AlbumEvolutionCurve.lua.
	  - DespertarService (grau por cardId) -> AlbumService.RollDespertar,
	    grau por creatureId (um único valor vale pra criatura inteira).
	  - InventoryService.GrantDiscoveryIfNew ("Índice") -> consolidado aqui,
	    disparado no mesmo evento que cria/eleva uma entrada do Álbum.

	MODELO DE RARIDADE (correção - raridade NÃO é mais pontos que somam e
	resetam ao evoluir): cada criatura guarda só `totalCopias` (sobe com
	pacote/Atalho, desce com venda/sacrifício) e `grau` (Despertar,
	independente). A raridade é sempre DERIVADA de `totalCopias` via
	`AlbumEvolutionCurve.RarityForTotalCopies` - a mesma função vale tanto
	pra ganhar quanto pra perder cópia, sem fluxos separados de
	evoluir/rebaixar.

	Todo pacote (PackService) e toda fonte de cópia grátis (Roda do Destino,
	Bênção Diária, Baús da Jornada) devem terminar chamando
	AlbumService.RegistrarCopia em vez de adicionar objetos soltos ao
	inventário.

	Local: ServerScriptService/Server/Systems/AlbumService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local AlbumEvolutionCurve = require(ReplicatedStorage.Shared.Data.AlbumEvolutionCurve)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatsService = require(ServerScriptService.Server.Systems.StatsService)
local PortalService = require(ServerScriptService.Server.Systems.PortalService)

type RarityId = Rarities.RarityId

local AlbumService = {}

-- Decisão pendente (ver SISTEMA_ALBUM_E_EVOLUCAO.md seção 8/13 e
-- Checklist_Desenvolvimento.md): se vender/sacrificar uma criatura até 0
-- cópias deve fazê-la sumir do Álbum/Mochila (liberando capacidade) ou
-- ficar "descoberta pra sempre". Enquanto não for confirmado pela Paola,
-- esta função fica isolada e DESLIGADA por padrão - ninguém deve chamá-la
-- condicionalmente sem checar este flag primeiro.
local FEATURE_REMOVE_ON_ZERO_COPIES = false

local EconomyService = nil -- carregado em Init() pra evitar circular require

-- Callbacks simples registrados via AlbumService.OnEvolucao(fn) - não há
-- framework de Signal/BindableEvent compartilhado no projeto hoje, então
-- este é um mini pub/sub interno.
local evolutionListeners: { (player: Player, creatureId: number, previousRarity: RarityId, newRarity: RarityId) -> () } =
	{}

local function discoveryKey(creatureId: number, rarity: string): string
	return tostring(creatureId) .. "_" .. rarity
end

-- Concede Diamante se essa for a primeira vez que o jogador alcança essa
-- combinação criatura+raridade (mesma regra/tabela que o antigo
-- InventoryService.GrantDiscoveryIfNew usava - só migrou de dono).
local function grantDiscoveryIfNew(player: Player, creatureId: number, rarity: RarityId): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end

	local key = discoveryKey(creatureId, rarity)
	if data.discovered[key] then
		return 0
	end

	data.discovered[key] = true
	local reward = Rarities.DiscoveryDiamondReward[rarity] or 0

	if PortalService.IsDiamondBoost() then
		reward *= 2
	end

	data.diamonds += reward

	if reward > 0 then
		Remotes.DiamondsUpdated:FireClient(player, data.diamonds)
		StatsService.Increment(player, "discoveries", 1)
	end

	return reward
end

-- Dispara os callbacks registrados via OnEvolucao. Erros num listener não
-- devem derrubar o registro da cópia - por isso pcall.
local function fireEvolution(player: Player, creatureId: number, previousRarity: RarityId, newRarity: RarityId)
	for _, listener in evolutionListeners do
		local ok, err = pcall(listener, player, creatureId, previousRarity, newRarity)
		if not ok then
			warn("[AlbumService] Erro num listener de OnEvolucao: " .. tostring(err))
		end
	end
end

-- Registra um callback pra rodar sempre que uma criatura mudar de raridade
-- (pra cima OU pra baixo - mesma função, sem caso especial). Usado pela
-- Mochila/Slots pra atualizar visual sem precisar dar polling no Álbum.
function AlbumService.OnEvolucao(
	listener: (player: Player, creatureId: number, previousRarity: RarityId, newRarity: RarityId) -> ()
)
	table.insert(evolutionListeners, listener)
end

-- Aplica o total de cópias novo, dispara diamante de descoberta se a
-- raridade alcançada for inédita pra essa criatura, e notifica
-- OnEvolucao se a raridade mudou. Núcleo compartilhado por
-- RegistrarCopia/RemoverPontos - a mesma checagem serve pra ganhar ou
-- perder cópia.
local function applyTotalCopias(player: Player, creatureId: number, entry, newTotal: number)
	local previousRarity: RarityId = AlbumEvolutionCurve.RarityForTotalCopies(entry.totalCopias)
	entry.totalCopias = math.max(0, newTotal)
	local newRarity: RarityId = AlbumEvolutionCurve.RarityForTotalCopies(entry.totalCopias)

	local diamonds = 0
	if newRarity ~= previousRarity then
		if Rarities.ById[newRarity].order > Rarities.ById[previousRarity].order then
			diamonds = grantDiscoveryIfNew(player, creatureId, newRarity)
		end
		fireEvolution(player, creatureId, previousRarity, newRarity)
	end

	if FEATURE_REMOVE_ON_ZERO_COPIES and entry.totalCopias <= 0 then
		AlbumService.RemoverSeVazio(player, creatureId)
	end

	return previousRarity, newRarity, diamonds
end

-- Ponto de entrada chamado pelo PackService (e por qualquer outra fonte de
-- cópia grátis) depois que o PackOddsRoller sorteia criatura + raridade.
-- `isBencaoDiaria` força a raridade sorteada pra "Default", ignorando o que
-- foi sorteado - regra fechada da Bênção Diária.
--
-- A raridade sorteada funciona como um PISO (substitui o antigo "Atalho"):
-- o total de cópias sobe pelo MAIOR entre "+1 cópia normal" e "o mínimo
-- garantido pra já estar na raridade sorteada" - um pull de alta raridade
-- ainda dá o salto instantâneo de antes, mas dentro do mesmo cálculo
-- contínuo (sem fluxo especial de Atalho).
export type RegistrarCopiaResult = {
	isNewDiscovery: boolean,
	previousRarity: RarityId,
	newRarity: RarityId,
	totalCopias: number,
	evolved: boolean,
	diamondsGranted: number,
}

function AlbumService.RegistrarCopia(
	player: Player,
	creatureId: number,
	raridadeSorteada: RarityId,
	isBencaoDiaria: boolean?
): RegistrarCopiaResult?
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	if not Creatures[creatureId] or not Rarities.ById[raridadeSorteada] then
		warn("[AlbumService] Criatura ou raridade inválida: " .. tostring(creatureId) .. " / " .. tostring(raridadeSorteada))
		return nil
	end

	local rarity: RarityId = if isBencaoDiaria then "Default" else raridadeSorteada
	local floor = AlbumEvolutionCurve.FloorForRarity(rarity)

	local entry = data.album[creatureId]

	-- Descoberta nova: entrada não existia ainda - trata à parte (não passa
	-- por applyTotalCopias, que só compara "raridade mudou?" contra um
	-- estado anterior que aqui não existe de verdade). Sempre dispara o
	-- Diamante de descoberta e notifica OnEvolucao pra o que quer que seja
	-- a raridade inicial (mesmo Default), exatamente uma vez.
	if not entry then
		local newTotal = math.max(1, floor)
		entry = { totalCopias = newTotal, grau = Rarities.BaseAwakenGrade }
		data.album[creatureId] = entry
		data.mochila[creatureId] = { favorito = false, noSlot = false }

		local newRarity = AlbumEvolutionCurve.RarityForTotalCopies(newTotal)
		local diamonds = grantDiscoveryIfNew(player, creatureId, newRarity)
		fireEvolution(player, creatureId, nil :: any, newRarity)

		return {
			isNewDiscovery = true,
			previousRarity = newRarity,
			newRarity = newRarity,
			totalCopias = newTotal,
			evolved = false,
			diamondsGranted = diamonds,
		}
	end

	local newTotal = math.max(entry.totalCopias + 1, floor)
	local previousRarity, newRarity, diamonds = applyTotalCopias(player, creatureId, entry, newTotal)

	return {
		isNewDiscovery = false,
		previousRarity = previousRarity,
		newRarity = newRarity,
		totalCopias = entry.totalCopias,
		evolved = newRarity ~= previousRarity,
		diamondsGranted = diamonds,
	}
end

-- Leitura pública do estado de uma criatura no Álbum - usado pela Mochila,
-- Slots de Base e EconomyService (fonte da verdade de raridade/grau).
export type AlbumEntrada = {
	raridade: RarityId,
	totalCopias: number,
	copiasParaProximo: number?,
	grau: number,
}

function AlbumService.GetEntrada(player: Player, creatureId: number): AlbumEntrada?
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local entry = data.album[creatureId]
	if not entry then
		return nil
	end

	return {
		raridade = AlbumEvolutionCurve.RarityForTotalCopies(entry.totalCopias),
		totalCopias = entry.totalCopias,
		copiasParaProximo = AlbumEvolutionCurve.CopiesUntilNext(entry.totalCopias),
		grau = entry.grau,
	}
end

-- ============================================================================
-- Despertar (grau) - substitui DespertarService.TryAwaken, agora por
-- creatureId em vez de cardId. Mesmo custo/regra de risco (resultado sempre
-- substitui, pra melhor ou pior). Independente da raridade - não é afetado
-- por RegistrarCopia/RemoverPontos.
-- ============================================================================

local AWAKEN_COST = 15

local LUCK_GAMEPASS_BONUS_ROLLS = {
	sorteCeleste = 1,
	ultraSorte = 2,
	sorteDiamante = 1,
}

local function getExtraRolls(player: Player): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end

	local extra = 0
	for gamepassKey, bonusRolls in LUCK_GAMEPASS_BONUS_ROLLS do
		if data.gamepasses[gamepassKey] then
			extra += bonusRolls
		end
	end
	return extra
end

function AlbumService.RollDespertar(player: Player, creatureId: number): (boolean, any)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	local entry = data.album[creatureId]
	if not entry then
		return false, "Criatura não descoberta"
	end

	if entry.grau >= Rarities.AwakenGrades[#Rarities.AwakenGrades].grade then
		return false, "Essa criatura já está no grau máximo de Despertar"
	end

	if not EconomyService then
		EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
	end

	local spent = EconomyService.TrySpendDiamonds(player, AWAKEN_COST)
	if not spent then
		return false, "Diamante insuficiente"
	end

	local rolledGrade = Rarities.RollAwakenGradeBest(getExtraRolls(player))
	local previousGrade = entry.grau
	local improved = rolledGrade > previousGrade
	local worsened = rolledGrade < previousGrade

	entry.grau = rolledGrade

	if improved then
		StatsService.Increment(player, "awakensImproved", 1)
	end

	-- Se a criatura está equipada num slot, o $/s pode ter mudado.
	if data.mochila[creatureId] and data.mochila[creatureId].noSlot then
		EconomyService.RecalculateIncomePerSecond(player)
	end

	return true, {
		creatureId = creatureId,
		previousGrade = previousGrade,
		rolledGrade = rolledGrade,
		finalGrade = entry.grau,
		improved = improved,
		worsened = worsened,
	}
end

-- ============================================================================
-- Remoção de cópias (venda / Altar de Sacrifício)
-- ============================================================================

-- Simula `RemoverPontos` sem aplicar - usado pelo preview de venda (mostra
-- raridade final/total antes do jogador confirmar).
function AlbumService.PreviewRemoverPontos(player: Player, creatureId: number, quantidade: number): AlbumEntrada?
	local entry = AlbumService.GetEntrada(player, creatureId)
	if not entry then
		return nil
	end

	local finalTotal = math.max(0, entry.totalCopias - quantidade)

	return {
		raridade = AlbumEvolutionCurve.RarityForTotalCopies(finalTotal),
		totalCopias = finalTotal,
		copiasParaProximo = AlbumEvolutionCurve.CopiesUntilNext(finalTotal),
		grau = entry.grau,
	}
end

-- Reduz `quantidade` cópias do total de uma criatura. A raridade é
-- recalculada automaticamente pela mesma função contínua - cruzar um
-- threshold pra baixo faz downgrade na hora, sem lógica separada.
-- Usado tanto por SellService.VenderCopias quanto pelo Altar de
-- Sacrifício (sem pagamento em $ nesse segundo caso - quem paga é quem
-- chama, este método só mexe no Álbum).
function AlbumService.RemoverPontos(player: Player, creatureId: number, quantidade: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	local entry = data.album[creatureId]
	if not entry then
		return false
	end

	applyTotalCopias(player, creatureId, entry, entry.totalCopias - quantidade)

	return true
end

-- Remove por completo uma criatura do Álbum/Mochila (volta a "não
-- descoberta"), liberando 1 de capacidade da Mochila. Função isolada,
-- DESLIGADA por padrão - ver FEATURE_REMOVE_ON_ZERO_COPIES no topo do
-- arquivo. Só deve ser chamada de dentro deste módulo até a decisão da
-- Paola ser fechada.
function AlbumService.RemoverSeVazio(player: Player, creatureId: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	if not data.album[creatureId] then
		return false
	end

	data.album[creatureId] = nil
	data.mochila[creatureId] = nil

	return true
end

function AlbumService.Init()
	Remotes.AwakenRequest.OnServerEvent:Connect(function(player: Player, creatureId: number)
		local success, resultOrError = AlbumService.RollDespertar(player, creatureId)

		if success then
			Remotes.AwakenResult:FireClient(player, true, resultOrError)
		else
			Remotes.AwakenResult:FireClient(player, false, resultOrError)
		end
	end)
end

return AlbumService
