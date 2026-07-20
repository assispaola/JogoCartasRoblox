--[[
	EconomyService.lua
	Cuida de: adicionar/gastar dinheiro e Diamante, calcular o $/s gerado
	pela base, e o fluxo de coleta de renda.

	IMPORTANTE - mudança de comportamento: por padrão, a renda das cartas
	NÃO cai direto no saldo - ela se acumula como "pendente" em cada slot,
	e o jogador precisa coletar manualmente (andar até o slot/apertar o
	botão, implementado no client/Studio). Quem tem o gamepass Coleta
	Automática pula essa etapa - a renda cai direto no saldo, como era
	antes.

	Local: ServerScriptService/Server/Systems/EconomyService.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local PortalService = require(ServerScriptService.Server.Systems.PortalService)
local AlbumEvolutionCurve = require(ReplicatedStorage.Shared.Data.AlbumEvolutionCurve)
-- NOTA: lê `data.album[creatureId]` direto (em vez de chamar
-- AlbumService.GetEntrada) de propósito - AlbumService.RollDespertar
-- precisa chamar de volta EconomyService.TrySpendDiamonds/
-- RecalculateIncomePerSecond, e as duas pontas se requerendo uma à outra
-- forma uma dependência cíclica real (Luau acusa isso mesmo quando um dos
-- lados é lazy) - ler o dado bruto aqui evita o ciclo por completo.

local EconomyService = {}

local MAX_OFFLINE_HOURS = 12
-- Teto de acúmulo de renda PENDENTE por slot (sem Coleta Automática) -
-- mesma lógica do teto de renda offline, pra não virar um número infinito
-- se o jogador ficar horas sem passar coletando.
local MAX_PENDING_HOURS = 12

-- Calcula quanto $/s uma carta específica gera, considerando raridade,
-- grau de Despertar, Eclipse de Clã (Portal da Sorte) e o bônus VIP
-- (+25% em todas as cartas).
function EconomyService.GetCardValue(card): number
	local creature = Creatures[card.creatureId]
	local rarityData = Rarities.ById[card.rarity]

	if not creature or not rarityData then
		warn("[EconomyService] Carta com dados inválidos: " .. tostring(card.creatureId) .. " / " .. tostring(card.rarity))
		return 0
	end

	-- Renascimento é aplicado depois, no total (RecalculateIncomePerSecond) -
	-- aqui calculamos só o valor "base" da carta, por isso passamos nil.
	local value = Rarities.CalculateValue(creature.seedValue, card.rarity, card.grade, nil)

	if PortalService.IsEclipseClan(creature.clan) then
		value *= PortalService.GetEclipseValueMultiplier()
	end

	return value
end

-- Recalcula o total de $/s do jogador (usado pra UI mostrar "quanto você
-- está gerando", e como taxa de acúmulo de renda pendente por slot).
-- Já aplica o bônus VIP de +25% no total, se o jogador tiver o gamepass.
function EconomyService.RecalculateIncomePerSecond(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	local total = 0
	for _, creatureId in data.placedSlots do
		local albumEntry = data.album[creatureId]
		if albumEntry then
			local rarity = AlbumEvolutionCurve.RarityForTotalCopies(albumEntry.totalCopias)
			total += EconomyService.GetCardValue({ creatureId = creatureId, rarity = rarity, grade = albumEntry.grau })
		end
	end

	if data.gamepasses.vip then
		total *= 1.25
	end

	total *= (data.renascimentoMultiplier or 1.0)

	data.totalIncomePerSecond = total
	Remotes.IncomePerSecondUpdated:FireClient(player, total)
end

function EconomyService.AddMoney(player: Player, amount: number)
	local data = PlayerDataService.GetData(player)
	if not data or amount <= 0 then
		return
	end

	data.money += amount
	Remotes.MoneyUpdated:FireClient(player, data.money)
end

function EconomyService.TrySpendMoney(player: Player, amount: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data or amount <= 0 then
		return false
	end

	if data.money < amount then
		return false
	end

	data.money -= amount
	Remotes.MoneyUpdated:FireClient(player, data.money)
	return true
end

function EconomyService.AddDiamonds(player: Player, amount: number)
	local data = PlayerDataService.GetData(player)
	if not data or amount <= 0 then
		return
	end

	data.diamonds += amount
	Remotes.DiamondsUpdated:FireClient(player, data.diamonds)
end

function EconomyService.TrySpendDiamonds(player: Player, amount: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data or amount <= 0 then
		return false
	end

	if data.diamonds < amount then
		return false
	end

	data.diamonds -= amount
	Remotes.DiamondsUpdated:FireClient(player, data.diamonds)
	return true
end

-- Coleta a renda pendente de UM slot específico. Retorna quanto foi
-- coletado (0 se não tinha nada pendente ou o slot não existe).
function EconomyService.CollectSlot(player: Player, slotId: number): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end

	local amount = data.slotPending[slotId] or 0
	if amount <= 0 then
		return 0
	end

	data.slotPending[slotId] = 0
	EconomyService.AddMoney(player, amount)

	return amount
end

-- Coleta a renda pendente de TODOS os slots de uma vez (conveniência -
-- útil pra um botão "coletar tudo" na UI, além da coleta individual
-- andando até cada slot).
function EconomyService.CollectAllSlots(player: Player): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end

	local total = 0
	for slotId, amount in data.slotPending do
		if amount > 0 then
			total += amount
			data.slotPending[slotId] = 0
		end
	end

	if total > 0 then
		EconomyService.AddMoney(player, total)
	end

	return total
end

-- Renda ganha enquanto o jogador estava OFFLINE sempre cai direto no
-- saldo, independente de ter Coleta Automática ou não - não faria sentido
-- exigir "andar até o slot" por um tempo em que o jogador nem estava no
-- jogo. VIP dobra esse valor.
function EconomyService.GrantOfflineEarnings(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	local secondsOffline = os.time() - (data.lastSaveTimestamp or os.time())
	local maxSeconds = MAX_OFFLINE_HOURS * 3600
	secondsOffline = math.clamp(secondsOffline, 0, maxSeconds)

	if secondsOffline <= 0 or data.totalIncomePerSecond <= 0 then
		return
	end

	local earned = secondsOffline * data.totalIncomePerSecond
	if data.gamepasses.vip then
		earned *= 2
	end

	EconomyService.AddMoney(player, earned)
	Remotes.OfflineEarningsReady:FireClient(player, earned, secondsOffline)
end

-- O "relógio" principal: a cada segundo, ou credita direto no saldo
-- (Coleta Automática) ou acumula como pendente em cada slot (padrão).
function EconomyService.StartIncomeLoop(player: Player)
	task.spawn(function()
		while player and player.Parent do
			task.wait(1)
			local data = PlayerDataService.GetData(player)
			if not data then
				break
			end

			if data.gamepasses.autoCollect then
				if data.totalIncomePerSecond > 0 then
					EconomyService.AddMoney(player, data.totalIncomePerSecond)
				end
			else
				local anyChanged = false
				for slotId, creatureId in data.placedSlots do
					local albumEntry = data.album[creatureId]
					if albumEntry then
						local rarity = AlbumEvolutionCurve.RarityForTotalCopies(albumEntry.totalCopias)
						local cardValue =
							EconomyService.GetCardValue({ creatureId = creatureId, rarity = rarity, grade = albumEntry.grau })
						local cap = cardValue * MAX_PENDING_HOURS * 3600
						local current = data.slotPending[slotId] or 0

						if current < cap then
							data.slotPending[slotId] = math.min(cap, current + cardValue)
							anyChanged = true
						end
					end
				end

				if anyChanged then
					Remotes.SlotPendingUpdated:FireClient(player, data.slotPending)
				end
			end
		end
	end)
end

return EconomyService
