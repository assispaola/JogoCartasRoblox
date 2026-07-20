--[[
	AltarSacrificioService.lua

	O Altar de Sacrifício: o jogador posiciona manualmente (staging, com
	QUANTIDADE por criatura - não é só um booleano "está no altar ou não")
	as cópias que serão consumidas como prova de Renascimento. Sem perda
	"aleatória" - RenascimentoService.TryRenascer só libera o Renascer
	quando os requisitos de sacrifício da Prova atual (RenascimentoCatalog)
	estão 100% cobertos pelo que foi staged aqui. Sacrifício no Altar NÃO
	paga nada em $ (diferente da venda normal, que dá 20% do valor).

	Cobre os 2 tipos de requisito de sacrifício da Prova final:
	- "sacrificeSpecificCreature": 1 cópia exata de uma criatura fixa.
	- "sacrificeCardsByClan": N cópias de escolha livre dentro de um clã
	  (podem vir de uma só criatura ou espalhadas entre várias).

	Cuidado com DUPLA CONTAGEM: se a criatura exigida pelo requisito
	específico (2) também pertencer ao clã exigido pelo requisito (1), as
	unidades já reservadas pro requisito (2) NÃO contam de novo pro
	requisito (1) - cada cópia staged só cobre um requisito por vez.

	Local: ServerScriptService/Server/Systems/AltarSacrificioService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local AlbumService = require(ServerScriptService.Server.Systems.AlbumService)
local RenascimentoCatalog = require(ReplicatedStorage.Shared.Data.RenascimentoCatalog)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local AltarSacrificioService = {}

-- Coloca `quantidade` cópias de uma criatura no Altar (staging - não remove
-- nada do Álbum ainda, só marca intenção). `quantidade <= 0` remove do
-- staging. Não deixa stagear mais cópias do que o jogador realmente tem.
function AltarSacrificioService.StageCreature(player: Player, creatureId: number, quantidade: number): (boolean, string?)
	local data = PlayerDataService.GetData(player)
	if not data then
		return false, "Dados não carregados"
	end

	if quantidade <= 0 then
		data.altarSacrificio.staged[creatureId] = nil
		return true
	end

	local entry = AlbumService.GetEntrada(player, creatureId)
	if not entry then
		return false, "Criatura não descoberta"
	end

	if quantidade > entry.totalCopias then
		return false, "Você não tem cópias suficientes dessa criatura"
	end

	data.altarSacrificio.staged[creatureId] = quantidade
	return true
end

function AltarSacrificioService.UnstageCreature(player: Player, creatureId: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	data.altarSacrificio.staged[creatureId] = nil
	return true
end

-- Quantas cópias staged de um clã específico estão disponíveis pro
-- requisito de clã, DESCONTANDO `reservedCreatureId`/`reservedAmount`
-- (unidades já reservadas por outro requisito, pra não contar 2x).
local function stagedClanTotal(staged, clan: string, reservedCreatureId: number?, reservedAmount: number): number
	local total = 0
	for creatureId, amount in staged do
		local creature = Creatures[creatureId]
		if creature and creature.clan == clan then
			local available = amount
			if reservedCreatureId == creatureId then
				available = math.max(0, available - reservedAmount)
			end
			total += available
		end
	end
	return total
end

-- Cruza o que está staged com os requisitos de sacrifício da Prova atual.
export type AltarStatus = {
	staged: { [number]: number },
	requirements: { { requirement: any, satisfied: boolean, staged: number } },
	allSatisfied: boolean,
}

function AltarSacrificioService.GetAltarStatus(player: Player): AltarStatus?
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local reqs = RenascimentoCatalog.GetRequirements(data.renascimentoLevel)
	local staged = data.altarSacrificio.staged
	local statuses = {}
	local allSatisfied = true

	-- A criatura específica (se houver) reserva 1 unidade antes de contar
	-- o pool do requisito de clã, pra nunca dar dupla contagem.
	local specificCreatureId: number? = nil
	for _, req in reqs do
		if req.type == "sacrificeSpecificCreature" then
			specificCreatureId = req.creatureId
		end
	end

	for _, req in reqs do
		if req.type == "sacrificeSpecificCreature" then
			local stagedAmount = staged[req.creatureId] or 0
			local satisfied = stagedAmount >= 1
			table.insert(statuses, { requirement = req, satisfied = satisfied, staged = stagedAmount })
			if not satisfied then
				allSatisfied = false
			end
		elseif req.type == "sacrificeCardsByClan" then
			local available = stagedClanTotal(staged, req.clan, specificCreatureId, 1)
			local satisfied = available >= req.count
			table.insert(statuses, { requirement = req, satisfied = satisfied, staged = available })
			if not satisfied then
				allSatisfied = false
			end
		end
		-- "money" não passa pelo Altar - checado direto por RenascimentoService.
	end

	return {
		staged = staged,
		requirements = statuses,
		allSatisfied = allSatisfied,
	}
end

-- Consome de verdade (via AlbumService.RemoverPontos, sem pagamento em $)
-- tudo que está staged e corresponde aos requisitos de sacrifício da
-- Prova atual, e limpa o staging inteiro. Revalida contra o Álbum atual
-- (nunca confia cegamente no que foi staged antes) - chamado por
-- RenascimentoService.TryRenascer DEPOIS de confirmar que
-- GetAltarStatus().allSatisfied é true.
function AltarSacrificioService.ConsumeStagedForProva(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	local reqs = RenascimentoCatalog.GetRequirements(data.renascimentoLevel)
	local staged = data.altarSacrificio.staged

	-- Clamp defensivo: nunca consumir mais do que o jogador realmente tem
	-- no Álbum agora (pode ter mudado desde que foi staged).
	local remaining = {}
	for creatureId, amount in staged do
		local entry = AlbumService.GetEntrada(player, creatureId)
		remaining[creatureId] = math.min(amount, entry and entry.totalCopias or 0)
	end

	for _, req in reqs do
		if req.type == "sacrificeSpecificCreature" and (remaining[req.creatureId] or 0) >= 1 then
			AlbumService.RemoverPontos(player, req.creatureId, 1)
			remaining[req.creatureId] -= 1
		end
	end

	for _, req in reqs do
		if req.type == "sacrificeCardsByClan" then
			local toConsume = req.count
			for creatureId, amount in remaining do
				if toConsume <= 0 then
					break
				end
				local creature = Creatures[creatureId]
				if creature and creature.clan == req.clan and amount > 0 then
					local consumed = math.min(amount, toConsume)
					AlbumService.RemoverPontos(player, creatureId, consumed)
					remaining[creatureId] -= consumed
					toConsume -= consumed
				end
			end
		end
	end

	data.altarSacrificio.staged = {}
end

function AltarSacrificioService.Init()
	Remotes.StageAltarCreatureRequest.OnServerEvent:Connect(function(player: Player, creatureId: number, quantidade: number)
		local success, errorReason = AltarSacrificioService.StageCreature(player, creatureId, quantidade)
		Remotes.AltarStatusUpdated:FireClient(player, AltarSacrificioService.GetAltarStatus(player), not success and errorReason or nil)
	end)

	Remotes.UnstageAltarCreatureRequest.OnServerEvent:Connect(function(player: Player, creatureId: number)
		AltarSacrificioService.UnstageCreature(player, creatureId)
		Remotes.AltarStatusUpdated:FireClient(player, AltarSacrificioService.GetAltarStatus(player))
	end)

	Remotes.AltarStatusRequest.OnServerEvent:Connect(function(player: Player)
		Remotes.AltarStatusUpdated:FireClient(player, AltarSacrificioService.GetAltarStatus(player))
	end)
end

return AltarSacrificioService
