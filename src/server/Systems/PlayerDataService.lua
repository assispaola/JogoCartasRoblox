--[[
	PlayerDataService.lua
	Responsável por carregar, guardar em memória, e salvar os dados de cada
	jogador no DataStore. TODO outro sistema (economia, inventário, etc.)
	lê e escreve através deste serviço - ninguém mexe direto no DataStore.

	ESTRUTURA DE DADOS (v2 - cartas individuais):
		data.money             -> number
		data.diamonds          -> number
		data.totalIncomePerSecond -> number
		data.lastSaveTimestamp -> number (os.time())
		data.nextCardId        -> number (contador pra gerar IDs únicos de carta)
		data.cards              -> { [cardId] = { creatureId, rarity, grade, placed, slotId } }
		data.discovered         -> { ["<creatureId>_<rarity>"] = true }  (pro Índice/Diamante)
		data.placedSlots        -> { [slotId] = cardId }  (mapa reverso, útil pra achar rápido o que tá em cada slot)

	Local: ServerScriptService/Server/Systems/PlayerDataService.lua
]]

local DataStoreService = game:GetService("DataStoreService")

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
		nextCardId = 1,
		cards = {},
		discovered = {},
		placedSlots = {},
		maxCards = 200, -- capacidade da Mochila (expansível via Loja/Robux mais pra frente)
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
		relicario = {}, -- [cardId] = {creatureId, rarity, grade} - cartas protegidas do reset
		relicarioSlots = 3, -- capacidade inicial do Relicário
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
			bancoExtra = false, -- Relicário +5 slots
			aberturaRapida = false, -- abrir pacotes mais rápido (client-side, Fase 5)
			pacotesExclusivos = false, -- acesso a pacotes exclusivos
		},
		slotPending = {}, -- [slotId] = dinheiro acumulado esperando coleta (só usado sem Coleta Automática)
		processedReceipts = {}, -- [receiptId] = true (evita creditar Dev Product duas vezes)
	}
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
