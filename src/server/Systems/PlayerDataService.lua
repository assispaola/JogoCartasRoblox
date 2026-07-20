--[[
	PlayerDataService.lua
	Responsável por carregar, guardar em memória, e salvar os dados de cada
	jogador no DataStore. TODO outro sistema (economia, inventário, etc.)
	lê e escreve através deste serviço - ninguém mexe direto no DataStore.

	ESTRUTURA DE DADOS (v2 - Álbum/Mochila por criatura, não mais por cópia):
		data.money             -> number
		data.diamonds          -> number
		data.totalIncomePerSecond -> number
		data.lastSaveTimestamp -> number (os.time())
		data.album              -> { [creatureId] = { totalCopias, grau } }  (fonte da verdade - raridade
		                            é SEMPRE derivada de totalCopias, ver AlbumService.lua/AlbumEvolutionCurve.lua)
		data.mochila            -> { [creatureId] = { favorito, noSlot } }  (1 registro por criatura
		                            descoberta, capacidade em data.maxCards)
		data.altarSacrificio    -> { staged = { [creatureId] = true } }  (staging manual pras Provas
		                            de Renascimento - ver AltarSacrificioService.lua)
		data.discovered         -> { ["<creatureId>_<rarity>"] = true }  (Diamante de descoberta,
		                            disparado de dentro do AlbumService)
		data.placedSlots        -> { [slotId] = creatureId }  (Slots de Base - só cartas aqui geram $/s)

		Campos abaixo só existem em saves ANTIGOS (modelo por cópia física) e
		são lidos uma única vez pela migration em LoadData pra popular
		album/mochila; contas novas nunca os recebem de createDefaultData():
		data.cards              -> { [cardId] = { creatureId, rarity, grade, placed, slotId } }
		data.relicario          -> { [cardId] = { creatureId, rarity, grade } }
		data.nextCardId         -> number

	Local: ServerScriptService/Server/Systems/PlayerDataService.lua
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local AlbumEvolutionCurve = require(ReplicatedStorage.Shared.Data.AlbumEvolutionCurve)

local PlayerDataService = {}

local playerDataStore = DataStoreService:GetDataStore("PlayerData_v2")
-- Subimos de "_v1" pra "_v2" porque a estrutura mudou de forma incompatível
-- (inventário por quantidade -> cartas individuais). Jogadores que tinham
-- dados na v1 começam do zero na v2. Como ainda estamos em desenvolvimento
-- (sem jogadores reais), isso é seguro agora - depois de publicado de
-- verdade, mudanças assim exigem um script de migração.

local function createDefaultData()
	return {
		money = 0,
		diamonds = 0,
		totalIncomePerSecond = 0,
		lastSaveTimestamp = os.time(),
		album = {}, -- [creatureId] = { raridade, pontos, grau } - fonte da verdade (AlbumService)
		mochila = {}, -- [creatureId] = { favorito, noSlot } - 1 registro por criatura descoberta
		altarSacrificio = { staged = {} }, -- staging manual pras Provas de Renascimento
		discovered = {},
		placedSlots = {}, -- [slotId] = creatureId
		maxCards = 200, -- capacidade da Mochila (expansível via Loja/Robux mais pra frente)
		maxPlacedSlots = 20, -- teto dos Slots de Base, independente de nível/Renascimento (gamepass "slotsExtras")
		packStates = {}, -- [packKey] = { lastOpenedAt, timesOpened } - usado por PackService.CanOpen
		highestUnlockedGeneralPackId = 1, -- ladder Geral (Novato=1 sempre liberado) - PERSISTENTE, nunca reseta
		autoSell = {
			byRarity = {}, -- ["Bronze"] = true/false
			byClan = {}, -- ["Ordem Celestial"] = true/false
		},
		handSlots = {}, -- [1..10] = cardId ou nil (a "Mão" - organização rápida)
		level = 1,
		stats = {
			-- Contadores CUMULATIVOS (nunca resetam, nem no Renascimento) -
			-- usados pra checar requisitos de Desafio de Nível do tipo
			-- "abra N pacotes", "descubra N criaturas", etc.
			packsOpened = 0,
			discoveries = 0,
			fusions = 0,
			awakensImproved = 0,
		},
		renascimentoLevel = 0, -- quantas vezes já renasceu
		renascimentoMultiplier = 1.0, -- multiplicador permanente de $/s (+10% por ciclo)
		wheel = {
			cycleStart = 0, -- os.time() de quando o giro grátis atual liberou (0 = nunca girou)
			freeSpinUsed = false,
			bonusSpins = 0, -- giros extras ganhos como prêmio ("+2 Giros"), somam com o grátis
		},
		dailyBlessing = {
			lastClaimTimestamp = 0, -- 0 = nunca resgatou
			streak = 0, -- dias consecutivos resgatados
		},
		journeyChests = {
			cycleStart = 0, -- os.time() de quando o ciclo atual começou (0 = ainda não iniciado)
			claimed = {}, -- [chestIndex] = true
		},
		gamepasses = {
			autoCollect = false, -- Coleta Automática
			vip = false, -- VIP (velocidade, renda offline em dobro, +25% valor de carta)
			sorteCeleste = false, -- Sorte Celestial (Despertar)
			ultraSorte = false, -- Ultra Sorte (Despertar)
			sorteDiamante = false, -- Sorte pra classificar cartas (Despertar)
			inventarioExtra = false, -- Mochila +500
			slotsExtras = false, -- +5 Slots de Base
			aberturaRapida = false, -- abrir pacotes mais rápido (client-side, Fase 5)
			pacotesExclusivos = false, -- acesso a pacotes exclusivos
		},
		slotPending = {}, -- [slotId] = dinheiro acumulado esperando coleta (só usado sem Coleta Automática)
		processedReceipts = {}, -- [receiptId] = true (evita creditar Dev Product duas vezes)
	}
end

-- Migration do modelo antigo (cartas individuais por cópia, `data.cards` +
-- `data.relicario`) pro novo modelo por criatura (`data.album`/`data.mochila`,
-- raridade derivada de `totalCopias` - ver AlbumEvolutionCurve.lua).
-- Idempotente: só roda se `loaded.album` ainda estiver vazio E houver algo
-- pra migrar - depois da primeira vez, `album` nunca mais fica vazio pra um
-- jogador que já tinha cartas, então isso não roda de novo em saves já
-- migrados. Não há como recuperar o histórico exato de cópias empilhadas
-- do modelo antigo (era rastreado por evolução/fusão manual, não por
-- contagem bruta) - a aproximação usada é: `totalCopias` = o PISO mínimo
-- da MAIOR raridade já alcançada por aquela criatura (mesmo cálculo que um
-- pull sortudo de pacote usaria, ver AlbumEvolutionCurve.FloorForRarity) -
-- suficiente pra preservar a raridade exibida, sem inventar histórico.
local function migrateCardsToAlbum(loaded)
	local hasOldCards = type(loaded.cards) == "table" and next(loaded.cards) ~= nil
	local hasOldRelicario = type(loaded.relicario) == "table" and next(loaded.relicario) ~= nil
	local albumIsEmpty = type(loaded.album) ~= "table" or next(loaded.album) == nil

	if not albumIsEmpty or (not hasOldCards and not hasOldRelicario) then
		return
	end

	loaded.album = loaded.album or {}
	loaded.mochila = loaded.mochila or {}

	local function considerCopy(creatureId: number, rarity: string, grade: number?)
		local rarityData = Rarities.ById[rarity :: Rarities.RarityId]
		if not rarityData then
			return
		end

		local floor = AlbumEvolutionCurve.FloorForRarity(rarity :: Rarities.RarityId)

		local existing = loaded.album[creatureId]
		if not existing then
			loaded.album[creatureId] = { totalCopias = math.max(1, floor), grau = grade or Rarities.BaseAwakenGrade }
			loaded.mochila[creatureId] = { favorito = false, noSlot = false }
			return
		end

		if floor > existing.totalCopias then
			existing.totalCopias = floor
		end
		if (grade or 0) > existing.grau then
			existing.grau = grade or existing.grau
		end
	end

	if hasOldCards then
		for _, card in loaded.cards do
			considerCopy(card.creatureId, card.rarity, card.grade)
		end
	end

	if hasOldRelicario then
		for _, card in loaded.relicario do
			considerCopy(card.creatureId, card.rarity, card.grade)
		end
	end
end

local sessionData: { [number]: any } = {}

function PlayerDataService.LoadData(player: Player): boolean
	local success, result = pcall(function()
		return playerDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success then
		local loaded = result or createDefaultData()

		-- Preenche automaticamente qualquer campo que exista nos dados
		-- padrão mas não exista no save carregado (ex: o jogador salvou
		-- antes da gente adicionar "level"/"stats" ao jogo). Isso evita
		-- ter que mudar a versão do DataStore (e resetar todo mundo)
		-- toda vez que adicionamos um campo novo à estrutura de dados.
		local defaults = createDefaultData()
		for key, value in defaults do
			if loaded[key] == nil then
				loaded[key] = value
			end
		end

		-- Reforço extra pra sub-tabelas que mudam de formato ao longo do
		-- desenvolvimento (ex: "wheel" ganhou/perdeu campos): preenche
		-- qualquer campo que falte DENTRO delas também, não só no nível
		-- mais alto.
		if type(loaded.wheel) == "table" then
			for key, value in defaults.wheel do
				if loaded.wheel[key] == nil then
					loaded.wheel[key] = value
				end
			end
		end

		-- Migração do modelo antigo por cópia (data.cards/data.relicario) pro
		-- Álbum/Mochila por criatura - ver comentário de migrateCardsToAlbum.
		migrateCardsToAlbum(loaded)

		sessionData[player.UserId] = loaded
		return true
	else
		warn("[PlayerDataService] Falha ao carregar dados de " .. player.Name .. ": " .. tostring(result))
		return false
	end
end

function PlayerDataService.SaveData(player: Player): boolean
	local data = sessionData[player.UserId]
	if not data then
		return false
	end

	data.lastSaveTimestamp = os.time()

	local success, err = pcall(function()
		playerDataStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("[PlayerDataService] Falha ao salvar dados de " .. player.Name .. ": " .. tostring(err))
	end

	return success
end

function PlayerDataService.GetData(player: Player)
	return sessionData[player.UserId]
end

function PlayerDataService.ClearSessionData(player: Player)
	sessionData[player.UserId] = nil
end

-- Gera um novo ID único de carta pra esse jogador (contador incremental,
-- nunca reaproveita IDs mesmo depois de vender/remover cartas antigas).
function PlayerDataService.GenerateCardId(player: Player): number
	local data = sessionData[player.UserId]
	if not data then
		return -1
	end

	local id = data.nextCardId
	data.nextCardId += 1
	return id
end

return PlayerDataService
