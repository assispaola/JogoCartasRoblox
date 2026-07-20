--!strict
--[[
	PackOddsRoller.lua

	Lógica de sorteio usada por QUALQUER pacote do PackCatalog:
	1) sorteia a raridade a partir da tabela Odds do pacote (RollRarity)
	2) sorteia o clã de forma uniforme entre os 15 clãs (RollClan)
	3) delega a escolha da criatura específica (clã + raridade) pra um
	   "CreatureProvider" injetado, porque essa parte já deve existir no
	   seu banco de criaturas atual (Matriz Completa / CreatureCatalog) —
	   este módulo não assume a API exata dele, só o contrato mínimo.

	Uso típico dentro do PackService:

		local roller = PackOddsRoller.new(creatureProvider)
		local rarity = roller:RollRarity(packDef.Odds)
		local clan = roller:RollClan()
		local creatureId = roller:RollCreature(clan, rarity)
]]

export type RarityKey = "Default" | "Bronze" | "Prata" | "Ouro" | "Platina" | "Lendario" | "Mitico" | "Divino"

-- Traduz a chave ASCII sem acento usada neste módulo/PackCatalog pro RarityId
-- acentuado canônico de Rarities.lua (fonte de verdade real do resto do
-- jogo). Chame isso sempre que uma raridade sorteada aqui for cruzar a
-- fronteira pro AlbumService/InventoryService/Rarities.
local CANONICAL_RARITY_ID: { [RarityKey]: string } = {
	Default = "Default",
	Bronze = "Bronze",
	Prata = "Prata",
	Ouro = "Ouro",
	Platina = "Platina",
	Lendario = "Lendário",
	Mitico = "Mítico",
	Divino = "Divino",
}

-- Ajuste esta lista se o módulo Clans.lua já existente tiver nomes diferentes.
-- Idealmente, troque esta constante por: local Clans = require(path.to.Clans)
local CLAN_NAMES: { string } = {
	"Ordem Celestial",
	"Véu Sombrio",
	"Fúria Selvagem",
	"Abismo Glacial",
	"Maré Eterna",
	"Forja Ígnea",
	"Tempestade Rúnica",
	"Rocha Ancestral",
	"Areia Amaldiçoada",
	"Selva Esmeralda",
	"Constelação Arcana",
	"Profundezas Abissais",
	"Chama Vulcânica",
	"Névoa Espectral",
	"Engrenagem Rúnica",
}

export type RarityOdds = {
	Default: number,
	Bronze: number,
	Prata: number,
	Ouro: number,
	Platina: number,
	Lendario: number,
	Mitico: number,
	Divino: number,
}

-- Contrato mínimo que o seu banco de criaturas real precisa satisfazer.
-- Implemente um adapter fino em cima do CreatureCatalog/Matriz Completa existente.
-- NOTA: `rarity` é recebido mas normalmente IGNORADO pelo provider real -
-- Creatures.lua não amarra raridade à identidade da criatura (raridade é
-- progresso por jogador, vive no Álbum). O provider só precisa sortear
-- uniformemente entre as criaturas daquele clã (ver PackService.lua).
export type CreatureProvider = {
	-- Deve retornar o id de uma criatura aleatória daquele clã.
	-- Se não houver nenhuma criatura cadastrada pro clã, deve dar error()
	-- (não deveria acontecer: 20 criaturas por clã cobrem os 15 clãs).
	GetRandomCreature: (self: CreatureProvider, clan: string, rarity: RarityKey) -> number,
}

local PackOddsRoller = {}
PackOddsRoller.__index = PackOddsRoller

export type PackOddsRoller = typeof(setmetatable(
	{} :: { _creatureProvider: CreatureProvider, _rng: Random },
	PackOddsRoller
))

function PackOddsRoller.new(creatureProvider: CreatureProvider, rngSeed: number?): PackOddsRoller
	local self = setmetatable({
		_creatureProvider = creatureProvider,
		_rng = rngSeed and Random.new(rngSeed) or Random.new(),
	}, PackOddsRoller)
	return self
end

--[[
	Sorteia uma raridade a partir da tabela de odds do pacote.
	Assume que as odds já somam ~1 (validado em tempo de dev, ver ValidateOdds).
	Usa varredura acumulada simples — 7 raridades, custo desprezível.
]]
function PackOddsRoller.RollRarity(self: PackOddsRoller, odds: RarityOdds): RarityKey
	local roll = self._rng:NextNumber() -- [0, 1)
	local acc = 0

	-- Default nunca tem chance > 0 em nenhum pacote comprável hoje (só a
	-- Bênção Diária a força fora desta tabela de odds), mas entra na
	-- varredura por completude/consistência com RarityOdds.
	acc += odds.Default
	if roll < acc then
		return "Default"
	end

	acc += odds.Bronze
	if roll < acc then
		return "Bronze"
	end

	acc += odds.Prata
	if roll < acc then
		return "Prata"
	end

	acc += odds.Ouro
	if roll < acc then
		return "Ouro"
	end

	acc += odds.Platina
	if roll < acc then
		return "Platina"
	end

	acc += odds.Lendario
	if roll < acc then
		return "Lendario"
	end

	acc += odds.Mitico
	if roll < acc then
		return "Mitico"
	end

	acc += odds.Divino
	if roll < acc then
		return "Divino"
	end

	-- Fallback por segurança (erro de arredondamento de ponto flutuante):
	-- devolve a maior raridade com chance > 0.
	if odds.Divino > 0 then
		return "Divino"
	elseif odds.Mitico > 0 then
		return "Mitico"
	elseif odds.Lendario > 0 then
		return "Lendario"
	elseif odds.Platina > 0 then
		return "Platina"
	elseif odds.Ouro > 0 then
		return "Ouro"
	elseif odds.Prata > 0 then
		return "Prata"
	end

	return "Bronze"
end

-- Ver comentário de `CANONICAL_RARITY_ID` no topo do arquivo.
function PackOddsRoller.ToCanonicalRarityId(rarity: RarityKey): string
	return CANONICAL_RARITY_ID[rarity]
end

function PackOddsRoller.RollClan(self: PackOddsRoller): string
	local index = self._rng:NextInteger(1, #CLAN_NAMES)
	return CLAN_NAMES[index]
end

function PackOddsRoller.RollCreature(self: PackOddsRoller, clan: string, rarity: RarityKey): number
	return self._creatureProvider:GetRandomCreature(clan, rarity)
end

--[[
	Sorteia N cartas completas (clã + raridade + criatura) de uma vez —
	usado pelos pacotes multi-carta (Baús, Confluência Mística).
]]
export type RolledCard = {
	Clan: string,
	Rarity: RarityKey,
	CreatureId: number,
}

function PackOddsRoller.RollCards(self: PackOddsRoller, odds: RarityOdds, count: number): { RolledCard }
	local results: { RolledCard } = table.create(count)
	for _ = 1, count do
		local rarity: RarityKey = self:RollRarity(odds) :: RarityKey
		local clan = self:RollClan()
		local creatureId = self:RollCreature(clan, rarity)
		table.insert(results, { Clan = clan, Rarity = rarity, CreatureId = creatureId })
	end
	return results
end

--[[
	Checagem de dev-time: soma das odds deve ficar bem próxima de 1.
	Chame isso uma vez no boot do servidor (ex: dentro do PackService.Init),
	iterando o PackCatalog inteiro, pra pegar erro de dado antes de ir pra produção.
]]
function PackOddsRoller.ValidateOdds(odds: RarityOdds): (boolean, number)
	local sum = odds.Default + odds.Bronze + odds.Prata + odds.Ouro + odds.Platina + odds.Lendario + odds.Mitico + odds.Divino
	local ok = math.abs(sum - 1) < 0.001
	return ok, sum
end

return PackOddsRoller
