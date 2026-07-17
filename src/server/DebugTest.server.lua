--[[
	DebugTest.server.lua
	Script TEMPORÁRIO pra testar o loop econômico + Diamante + Despertar +
	Nível de ponta a ponta. Roda automaticamente no servidor.

	IMPORTANTE: apague este arquivo depois que o teste passar.

	Local: ServerScriptService/Server/DebugTest.server.lua
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
local PackService = require(ServerScriptService.Server.Systems.PackService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local DespertarService = require(ServerScriptService.Server.Systems.DespertarService)
local FusionService = require(ServerScriptService.Server.Systems.FusionService)
local LevelService = require(ServerScriptService.Server.Systems.LevelService)
local PackCatalog = require(game:GetService("ReplicatedStorage").Shared.Data.PackCatalog)

local function runTest(player: Player)
	task.wait(3)

	print("--- INÍCIO DO TESTE ---")
	local data = PlayerDataService.GetData(player)
	print("Nível inicial:", data.level, "| Dinheiro:", data.money, "| Diamante:", data.diamonds)

	-- Mostra o desafio do nível 1 ANTES de cumprir (deve mostrar canLevelUp = false)
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

	-- Testa a tentativa de subir de nível agora que o dinheiro bate o requisito
	local leveledUp, newLevelOrErr = LevelService.TryLevelUp(player)
	print("Subiu de nível?", leveledUp, "| resultado:", newLevelOrErr)

	-- Abre um pacote (soma no contador de packsOpened, usado nos próximos desafios)
	local result = PackService.OpenPack(player, "Padrao")
	if result then
		print("Pacote aberto:", result.creatureName, "-", result.clan, "-", result.rarity, "| cardId:", result.cardId)
		print("Diamante após descoberta:", data.diamonds)

		if result.cardId then
			InventoryService.PlaceCard(player, result.cardId)
			EconomyService.RecalculateIncomePerSecond(player)
			print("Novo $/s:", data.totalIncomePerSecond)

			EconomyService.AddDiamonds(player, 200)
			local awakened, _awakenResult = DespertarService.TryAwaken(player, result.cardId)
			print("Despertar tentado, sucesso?", awakened)
		end
	end

	print("Contadores atuais:")
	print("  packsOpened:", data.stats.packsOpened)
	print("  discoveries:", data.stats.discoveries)
	print("  fusions:", data.stats.fusions)
	print("  awakensImproved:", data.stats.awakensImproved)

	-- Mostra o desafio do nível atual (2, se subiu certinho)
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

	-- Testa um pacote temático (Ordem Celestial, tier Iniciado) - confirma
	-- que só sorteia criaturas daquele clã específico
	local themedPackId = "OrdemCelestial_Iniciado"
	local themedPackInfo = PackCatalog.Packs[themedPackId]
	print(
		"Testando pacote temático "
			.. themedPackId
			.. " (desbloqueia no nível "
			.. themedPackInfo.unlockLevel
			.. ", jogador está no nível "
			.. data.level
			.. ")..."
	)
	EconomyService.AddMoney(player, 500)
	for i = 1, 3 do
		local themedResult, themedErr = PackService.OpenPack(player, themedPackId)
		if themedResult then
			print(
				string.format(
					"  Tentativa %d: %s (clã: %s, esperado: Ordem Celestial) - raridade %s",
					i,
					themedResult.creatureName,
					themedResult.clan,
					themedResult.rarity
				)
			)
		else
			print("  Tentativa " .. i .. " falhou:", themedErr)
		end
	end

	-- Testa Fusão: abre pacotes Bronze do Pacote Padrão até ter duplicatas
	-- suficientes de uma mesma criatura pra fundir (valida Rarities.ById,
	-- duplicatesNeeded e nextRarity depois da migração da API antiga).
	print("--- TESTE DE FUSÃO ---")
	EconomyService.AddMoney(player, 5000)

	local fusionTarget = nil
	for _ = 1, 30 do
		local packResult = PackService.OpenPack(player, "Padrao")
		if packResult and packResult.rarity == "Bronze" then
			local count = InventoryService.GetUnplacedCount(player, packResult.creatureId, "Bronze")
			print(string.format("  Pacote: %s (Bronze) - cópias sem colocar: %d", packResult.creatureName, count))
			if count >= 3 then
				fusionTarget = packResult.creatureId
				break
			end
		end
	end

	if fusionTarget then
		local fused, fusionResultOrErr = FusionService.TryFuse(player, fusionTarget, "Bronze")
		print("Fusão tentada, sucesso?", fused, "| resultado:", fusionResultOrErr)
	else
		print("Não juntou 3 cópias Bronze da mesma criatura em 30 pacotes - rode de novo ou aumente o teste.")
	end

	print("--- FIM DO TESTE ---")
end

Players.PlayerAdded:Connect(runTest)

for _, player in Players:GetPlayers() do
	task.spawn(runTest, player)
end
