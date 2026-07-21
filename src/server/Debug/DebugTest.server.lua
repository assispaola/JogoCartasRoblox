--[[
	DebugTest.server.lua
	Script TEMPORÁRIO pra testar o loop econômico + Álbum/Mochila + Diamante +
	Despertar + Nível de ponta a ponta, já no modelo novo (AlbumService, sem
	FusionService/cardId). Roda automaticamente no servidor.

	IMPORTANTE: apague este arquivo depois que o teste passar.

	Local: ServerScriptService/Server/DebugTest.server.lua
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
local PackService = require(ServerScriptService.Server.Systems.PackService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local AlbumService = require(ServerScriptService.Server.Systems.AlbumService)
local LevelService = require(ServerScriptService.Server.Systems.LevelService)
local Creatures = require(ReplicatedStorage.Shared.Data.Creatures)

local function runTest(player: Player)
	task.wait(3)

	print("--- INÍCIO DO TESTE ---")
	local data = PlayerDataService.GetData(player)
	print("Nível inicial:", data.level, "| Dinheiro:", data.money, "| Diamante:", data.diamonds)

	local statusBefore = LevelService.GetChallengeStatus(player)
	print("Desafio nível 1 - pode subir?", statusBefore.canLevelUp)
	for _, reqStatus in statusBefore.requirements do
		print(
			string.format(
				"  Requisito: %s | cumprido? %s | %s/%s",
				reqStatus.requirement.type,
				tostring(reqStatus.met),
				tostring(reqStatus.current),
				tostring(reqStatus.needed)
			)
		)
	end

	EconomyService.AddMoney(player, 1000)
	print("Dinheiro após bônus:", data.money)

	local leveledUp, newLevelOrErr = LevelService.TryLevelUp(player)
	print("Subiu de nível?", leveledUp, "| resultado:", newLevelOrErr)

	-- Abre o pacote Novato (soma no contador de packsOpened) e registra a
	-- carta sorteada no Álbum via PackService.OpenPack -> AlbumService.
	EconomyService.AddMoney(player, 20000000)
	local success, result = PackService.OpenPack(player, "Novato")
	if success then
		local card = result.Cards[1]
		local creature = Creatures[card.CreatureId]
		print("Pacote aberto:", creature.name, "-", card.Clan, "-", card.Rarity)

		local entry = AlbumService.GetEntrada(player, card.CreatureId)
		print("Entrada no Álbum:", entry and entry.raridade, entry and entry.totalCopias, "| Diamante:", data.diamonds)

		local placed, slotOrErr = InventoryService.PlaceCard(player, card.CreatureId)
		print("Colocado na base?", placed, slotOrErr)
		EconomyService.RecalculateIncomePerSecond(player)
		print("Novo $/s:", data.totalIncomePerSecond)

		EconomyService.AddDiamonds(player, 200)
		local awakened, _awakenResult = AlbumService.RollDespertar(player, card.CreatureId)
		print("Despertar tentado, sucesso?", awakened)
	else
		print("Falha ao abrir pacote:", result)
	end

	print("Contadores atuais:")
	print("  packsOpened:", data.stats.packsOpened)
	print("  discoveries:", data.stats.discoveries)
	print("  fusions:", data.stats.fusions, "(FusionService obsoleto, deve ficar em 0 daqui pra frente)")
	print("  awakensImproved:", data.stats.awakensImproved)

	local statusAfter = LevelService.GetChallengeStatus(player)
	print("Desafio nível " .. statusAfter.level .. " - pode subir?", statusAfter.canLevelUp)
	for _, reqStatus in statusAfter.requirements do
		print(
			string.format(
				"  Requisito: %s | cumprido? %s | %s/%s",
				reqStatus.requirement.type,
				tostring(reqStatus.met),
				tostring(reqStatus.current),
				tostring(reqStatus.needed)
			)
		)
	end

	-- Testa a curva de evolução automática do Álbum: abre vários pacotes
	-- Novato até uma criatura acumular pontos suficientes pra evoluir de
	-- Default/Bronze sozinha (sem fusão manual).
	print("--- TESTE DE EVOLUÇÃO AUTOMÁTICA (Álbum) ---")
	EconomyService.AddMoney(player, 20000000 * 30)

	local trackedCreatureId = nil
	for i = 1, 30 do
		local ok, packResult = PackService.OpenPack(player, "Novato")
		if ok then
			local card = packResult.Cards[1]
			if not trackedCreatureId then
				trackedCreatureId = card.CreatureId
			end
			if card.CreatureId == trackedCreatureId then
				local entry = AlbumService.GetEntrada(player, trackedCreatureId)
				print(
					string.format(
						"  Pacote %d: raridade %s, cópias %d (faltam %s p/ próxima)",
						i,
						entry.raridade,
						entry.totalCopias,
						tostring(entry.copiasParaProximo)
					)
				)
			end
		end
	end

	print("--- FIM DO TESTE ---")
end

Players.PlayerAdded:Connect(runTest)

for _, player in Players:GetPlayers() do
	task.spawn(runTest, player)
end
