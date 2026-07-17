--[[
	Main.server.lua
	Ponto de entrada do servidor. Conecta os eventos de jogador entrando/saindo
	aos sistemas (PlayerDataService, EconomyService) e cuida do autosave.

	Local: ServerScriptService/Server/Main.server.lua
	(repare no ".server.lua" - isso diz ao Roblox que é um Script, não um
	ModuleScript, e que ele roda automaticamente ao iniciar o servidor)
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local EconomyService = require(ServerScriptService.Server.Systems.EconomyService)
local InventoryService = require(ServerScriptService.Server.Systems.InventoryService)
local AutoSellService = require(ServerScriptService.Server.Systems.AutoSellService)
local PackService = require(ServerScriptService.Server.Systems.PackService)
local FusionService = require(ServerScriptService.Server.Systems.FusionService)
local DespertarService = require(ServerScriptService.Server.Systems.DespertarService)
local SellService = require(ServerScriptService.Server.Systems.SellService)
local HandService = require(ServerScriptService.Server.Systems.HandService)
local LevelService = require(ServerScriptService.Server.Systems.LevelService)
local RelicarioService = require(ServerScriptService.Server.Systems.RelicarioService)
local RenascimentoService = require(ServerScriptService.Server.Systems.RenascimentoService)
local SnapshotService = require(ServerScriptService.Server.Systems.SnapshotService)
local DonationService = require(ServerScriptService.Server.Systems.DonationService)
local TradeService = require(ServerScriptService.Server.Systems.TradeService)
local WheelService = require(ServerScriptService.Server.Systems.WheelService)
local DailyBlessingService = require(ServerScriptService.Server.Systems.DailyBlessingService)
local JourneyChestService = require(ServerScriptService.Server.Systems.JourneyChestService)
local PortalService = require(ServerScriptService.Server.Systems.PortalService)
local GamepassService = require(ServerScriptService.Server.Systems.GamepassService)

-- Liga os listeners de RemoteEvents uma única vez, quando o servidor inicia
-- (não a cada jogador que entra - por isso fica aqui fora, não dentro de
-- onPlayerAdded)
InventoryService.Init()
AutoSellService.Init()
PackService.Init()
FusionService.Init()
DespertarService.Init()
SellService.Init()
HandService.Init()
LevelService.Init()
RelicarioService.Init()
RenascimentoService.Init()
SnapshotService.Init()
DonationService.Init()
TradeService.Init()
WheelService.Init()
DailyBlessingService.Init()
JourneyChestService.Init()
PortalService.Init()
GamepassService.Init()

-- Remotes de coleta manual de renda (implementados direto aqui, já que
-- são simples e não precisam de um serviço próprio)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

Remotes.CollectSlotRequest.OnServerEvent:Connect(function(player: Player, slotId: number)
	local amount = EconomyService.CollectSlot(player, slotId)
	if amount > 0 then
		Remotes.SlotPendingUpdated:FireClient(player, PlayerDataService.GetData(player).slotPending)
	end
end)

Remotes.CollectAllSlotsRequest.OnServerEvent:Connect(function(player: Player)
	local total = EconomyService.CollectAllSlots(player)
	if total > 0 then
		Remotes.SlotPendingUpdated:FireClient(player, PlayerDataService.GetData(player).slotPending)
	end
end)

-- A cada quantos segundos salvamos automaticamente (além de salvar sempre
-- que o jogador sai). Isso protege contra perda de progresso se o servidor
-- cair inesperadamente.
local AUTOSAVE_INTERVAL_SECONDS = 120

local function onPlayerAdded(player: Player)
	local loaded = PlayerDataService.LoadData(player)

	if not loaded then
		-- Não conseguimos carregar os dados com segurança. Em vez de deixar
		-- o jogador jogar com progresso zerado (o que apagaria o save dele
		-- se o DataStore só estiver temporariamente instável), pedimos pra
		-- tentar novamente.
		player:Kick("Não foi possível carregar seus dados. Por favor, tente entrar novamente em alguns instantes.")
		return
	end

	-- Confere quais gamepasses o jogador possui e aplica os efeitos
	-- permanentes (Mochila +500, Relicário +5, velocidade VIP, etc.)
	GamepassService.CheckAllOwnership(player)

	-- O WalkSpeed reseta a cada respawn - reaplica o bônus VIP toda vez
	-- que o personagem nascer.
	player.CharacterAdded:Connect(function(character)
		local data = PlayerDataService.GetData(player)
		if data and data.gamepasses.vip then
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.WalkSpeed = 24
		end
	end)

	-- Calcula quanto o jogador ganhou enquanto estava fora
	EconomyService.RecalculateIncomePerSecond(player)
	EconomyService.GrantOfflineEarnings(player)

	-- Envia o retrato completo dos dados pro cliente (cartas, Índice,
	-- config, Relicário, etc.) - depois disso, os RemoteEvents reativos
	-- (MoneyUpdated, PackOpened, etc.) mantêm tudo sincronizado sozinho.
	SnapshotService.SendSnapshot(player)

	-- Liga o "relógio" que paga a renda passiva a cada segundo
	EconomyService.StartIncomeLoop(player)

	-- Autosave periódico enquanto o jogador estiver no servidor
	task.spawn(function()
		while player and player.Parent do
			task.wait(AUTOSAVE_INTERVAL_SECONDS)
			if player and player.Parent then
				PlayerDataService.SaveData(player)
			end
		end
	end)

	print("[Main] " .. player.Name .. " carregado com sucesso.")
end

local function onPlayerRemoving(player: Player)
	PlayerDataService.SaveData(player)
	PlayerDataService.ClearSessionData(player)
	print("[Main] " .. player.Name .. " salvo e desconectado.")
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Proteção extra: salvar todo mundo se o servidor for encerrado
-- (deploy de atualização, shutdown, etc.)
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerDataService.SaveData(player)
	end
end)

print("[Main] Servidor iniciado. Sistemas de economia e dados carregados.")
