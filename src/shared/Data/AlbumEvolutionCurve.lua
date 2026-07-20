--!strict
--[[
	AlbumEvolutionCurve.lua

	Raridade não é mais um contador de pontos que soma e reseta ao evoluir -
	é uma FUNÇÃO CONTÍNUA, sempre recalculada a partir da quantidade TOTAL
	de cópias que o jogador tem AGORA daquela criatura (`totalCopias`,
	sobe com pacote/Atalho, desce com venda/sacrifício no Altar). A raridade
	é sempre a maior faixa cujo `EntryThreshold` o total atual alcança -
	funciona igual nos dois sentidos (subir ou descer), sem fluxos
	separados de "evoluir" vs. "rebaixar".

	`EntryThreshold[R]` = total de cópias necessário pra ENTRAR na raridade
	R (0 pra Default, já que é o piso). Construído a partir da mesma curva
	de incrementos por raridade que já era usada antes (agora só como
	referência de quanto cada faixa "vale" em largura, ver `TierWidth`):

	Default: 0  | Bronze: 5  | Prata: 15  | Ouro: 30  | Platina: 55 |
	Lendário: 90 | Mítico: 140  (Mítico é teto - sem próxima raridade)

	Exemplos de validação (ver correção de modelo, sessão com a Paola):
	- total=5 cópias -> Bronze (alcançou o threshold de 5)
	- total=4 cópias -> Default (ainda não alcançou 5)
	- total=7 cópias, sacrifica 1 -> total=6 -> continua Bronze (5<=6<15)

	Local: ReplicatedStorage/Shared/Data/AlbumEvolutionCurve.lua
]]

local Rarities = require(script.Parent.Rarities)

type RarityId = Rarities.RarityId

local AlbumEvolutionCurve = {}

-- Largura de cada faixa (quantas cópias a mais, além do threshold de
-- entrada, cabem dentro dela antes de alcançar a próxima raridade).
-- Mantido só como documentação/fonte de geração do EntryThreshold abaixo -
-- ninguém deve ler isto diretamente, use EntryThreshold/RarityForTotalCopies.
-- NOTA: chave `string` (não `RarityId`) de propósito - indexar uma tabela
-- `{[RarityId]: number}` com uma variável vinda de iterar `{RarityId}`
-- confunde o checador de tipos do Luau (achata a união em vários `string`
-- soltos). Manter string aqui e só devolver `RarityId` na fronteira das
-- funções públicas evita esse problema por completo.
local TierWidth: { [string]: number } = {
	Default = 5,
	Bronze = 10,
	Prata = 15,
	Ouro = 25,
	Platina = 35,
	["Lendário"] = 50,
	["Mítico"] = 70,
}

-- Ordem das raridades que o Álbum efetivamente percorre (exclui Divino -
-- não é alcançável por acúmulo de cópias, só via pacote de evento).
local ALBUM_RARITY_CHAIN: { RarityId } = { "Default", "Bronze", "Prata", "Ouro", "Platina", "Lendário", "Mítico" }

-- Total de cópias necessário pra ENTRAR em cada raridade (soma acumulada
-- das larguras de todas as faixas anteriores). Default = 0 (piso - toda
-- criatura descoberta, mesmo com 1 cópia só, já é pelo menos Default).
AlbumEvolutionCurve.EntryThreshold = {} :: { [string]: number }
do
	local acc = 0
	for _, rarityId in ALBUM_RARITY_CHAIN do
		AlbumEvolutionCurve.EntryThreshold[rarityId] = acc
		acc += TierWidth[rarityId] or 0
	end
end

-- Dado o total de cópias atual, retorna a raridade correspondente (a maior
-- faixa cujo EntryThreshold o total alcança). Nunca retorna nil - toda
-- criatura descoberta (totalCopias >= 1) é pelo menos Default.
function AlbumEvolutionCurve.RarityForTotalCopies(totalCopias: number): RarityId
	local current: RarityId = "Default"
	for _, rarityId in ALBUM_RARITY_CHAIN do
		if totalCopias >= (AlbumEvolutionCurve.EntryThreshold[rarityId] or 0) then
			-- Cast explícito: iterar um array `{RarityId}` com `for..in`
			-- genérico faz o Luau alargar o tipo do valor iterado (perde a
			-- união de literais) - o cast recupera o tipo real sem mudar
			-- nada em runtime.
			current = rarityId :: RarityId
		else
			break
		end
	end
	return current
end

-- Quantas cópias faltam pro total atual alcançar a PRÓXIMA raridade da
-- cadeia, ou nil se já está em Mítico (teto do Álbum - Divino não entra
-- nessa curva).
function AlbumEvolutionCurve.CopiesUntilNext(totalCopias: number): number?
	local currentRarity = AlbumEvolutionCurve.RarityForTotalCopies(totalCopias)
	if currentRarity == "Mítico" then
		return nil
	end

	for i, rarityId in ALBUM_RARITY_CHAIN do
		if rarityId == currentRarity then
			local nextRarityId = ALBUM_RARITY_CHAIN[i + 1]
			if not nextRarityId then
				return nil
			end
			return math.max(0, (AlbumEvolutionCurve.EntryThreshold[nextRarityId] or 0) - totalCopias)
		end
	end

	return nil
end

-- Total de cópias mínimo garantido pra uma criatura nascer/saltar direto
-- numa raridade específica (usado como "piso" quando um pacote sorteia
-- essa raridade - ver AlbumService.RegistrarCopia). Raridades fora da
-- cadeia do Álbum (Divino) não têm piso aqui - tratadas à parte.
function AlbumEvolutionCurve.FloorForRarity(rarity: RarityId): number
	return AlbumEvolutionCurve.EntryThreshold[rarity] or 0
end

return AlbumEvolutionCurve
