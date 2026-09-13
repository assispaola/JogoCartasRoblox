--[[
	SellService.lua
	Vende cópias de uma criatura (por creatureId) por dinheiro. O preço é uma
	fração pequena do valor real da cópia (raridade × grau, lidos do Álbum) -
	de propósito bem menor do que manter a criatura gerando renda na base,
	pra não criar um loop de "comprar pacote só pra vender" que quebraria a
	economia.

	Local: ServerScriptService/Server/Systems/SellService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AlbumService = require(ServerScriptService.Server.Systems.AlbumService)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local SellService = {}

-- Fração do valor real que cada cópia rende ao ser vendida. Ajustável -
-- se o balanceamento pedir vender por mais ou menos, muda só esse número.
local SELL_PERCENTAGE = 0.20

-- Venda Automática pós-Mítico: proposta ainda não confirmada pela Paola
-- (ver CLAUDE.md, seção "Decisões ainda pendentes") - função isolada, DESLIGADA por
-- padrão, não ligada à abertura de pacote enquanto o flag estiver off.
local FEATURE_AUTOSELL_POST_MITICO = false

local EconomyService = nil -- carregado em Init() pra evitar circular require

local function unitPrice(player: Player, creatureId: number, entry): number
	if not entry then
		return 0
	end
	local fullValue = EconomyService.GetCardValue({ creatureId = creatureId, rarity = entry.raridade, grade = entry.grau })
	return math.floor(fullValue * SELL_PERCENTAGE)
end

-- Calcula o resultado de vender `quantidade` cópias SEM aplicar - a UI
-- decide se mostra isso automaticamente ou pede confirmação antes de
-- chamar VenderCopias (decisão de UX ainda pendente, Fase 5).
export type SellPreview = {
	creatureId: number,
	quantidade: number,
	precoTotal: number,
	raridadeFinal: string,
	totalCopiasFinal: number,
}

function SellService.PreviewVenda(player: Player, creatureId: number, quantidade: number): SellPreview?
	local entryAtual = AlbumService.GetEntrada(player, creatureId)
	if not entryAtual then
		return nil
	end

	if not EconomyService then
		EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
	end

	local preco = unitPrice(player, creatureId, entryAtual) * quantidade
	local entryFinal = AlbumService.PreviewRemoverPontos(player, creatureId, quantidade)

	return {
		creatureId = creatureId,
		quantidade = quantidade,
		precoTotal = preco,
		raridadeFinal = entryFinal and entryFinal.raridade or entryAtual.raridade,
		totalCopiasFinal = entryFinal and entryFinal.totalCopias or entryAtual.totalCopias,
	}
end

-- Tenta vender `quantidade` cópias de uma criatura. Sempre calcula o preview
-- primeiro (preço calculado sobre a raridade/grau ATUAIS, antes do
-- downgrade) e só então aplica a redução de pontos no Álbum.
function SellService.VenderCopias(player: Player, creatureId: number, quantidade: number)
	if quantidade <= 0 then
		return false, "Quantidade inválida"
	end

	local preview = SellService.PreviewVenda(player, creatureId, quantidade)
	if not preview then
		return false, "Você não possui essa criatura"
	end

	AlbumService.RemoverPontos(player, creatureId, quantidade)

	if not EconomyService then
		EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
	end
	EconomyService.AddMoney(player, preview.precoTotal)

	return true, {
		creatureId = creatureId,
		creatureName = Creatures[creatureId] and Creatures[creatureId].name,
		quantidade = quantidade,
		price = preview.precoTotal,
		raridadeFinal = preview.raridadeFinal,
		totalCopiasFinal = preview.totalCopiasFinal,
	}
end

-- Gancho isolado da Venda Automática pós-Mítico (ver flag no topo do
-- arquivo). Vende automaticamente cópias extras de uma criatura só depois
-- dela já estar em Mítico - NÃO é chamado por nenhum fluxo de pacote
-- enquanto o flag estiver desligado.
function SellService.TryAutoSellPostMitico(player: Player, creatureId: number)
	if not FEATURE_AUTOSELL_POST_MITICO then
		return false
	end

	local entry = AlbumService.GetEntrada(player, creatureId)
	if not entry or entry.raridade ~= "Mítico" then
		return false
	end

	return SellService.VenderCopias(player, creatureId, 1)
end

function SellService.Init()
	EconomyService = require(ServerScriptService.Server.Systems.EconomyService)

	Remotes.SellCardRequest.OnServerEvent:Connect(function(player: Player, creatureId: number, quantidade: number)
		local success, resultOrError = SellService.VenderCopias(player, creatureId, quantidade or 1)

		if success then
			Remotes.SellCardResult:FireClient(player, true, resultOrError)
		else
			Remotes.SellCardResult:FireClient(player, false, resultOrError)
		end
	end)
end

return SellService
