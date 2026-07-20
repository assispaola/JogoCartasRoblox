--[[
	AutoSellService.lua
	Configuração de Venda Automática: o jogador liga/desliga categorias
	(por raridade e por clã) que devem ser vendidas sozinhas ao sair de um
	pacote, sem nunca ocupar espaço na Mochila.

	Regra: uma carta é vendida automaticamente se a RARIDADE dela OU o
	CLÃ dela estiver marcado (basta um dos dois).

	Local: ServerScriptService/Server/Systems/AutoSellService.lua
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Systems.PlayerDataService)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Clans = require(ReplicatedStorage.Shared.Data.Clans)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local AutoSellService = {}

-- Verdadeiro se essa criatura+raridade deve ser vendida automaticamente,
-- segundo a configuração atual do jogador.
function AutoSellService.ShouldAutoSell(player: Player, clan: string, rarity: string): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	if data.autoSell.byRarity[rarity] then
		return true
	end
	if data.autoSell.byClan[clan] then
		return true
	end
	return false
end

-- Liga/desliga um toggle de raridade ou clã. `category` é "rarity" ou
-- "clan"; `name` é o nome da raridade/clã; `enabled` é o novo estado.
function AutoSellService.SetToggle(player: Player, category: string, name: string, enabled: boolean): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	if category == "rarity" then
		if not Rarities.ById[name :: Rarities.RarityId] then
			return false
		end
		data.autoSell.byRarity[name] = enabled or nil -- nil em vez de false, pra não inflar o save à toa
	elseif category == "clan" then
		if not Clans.ByName[name] then
			return false
		end
		data.autoSell.byClan[name] = enabled or nil
	else
		return false
	end

	return true
end

function AutoSellService.Init()
	Remotes.SetAutoSellConfigRequest.OnServerEvent:Connect(
		function(player: Player, category: string, name: string, enabled: boolean)
			local success = AutoSellService.SetToggle(player, category, name, enabled)
			local data = PlayerDataService.GetData(player)

			Remotes.AutoSellConfigUpdated:FireClient(player, success, data and data.autoSell or nil)
		end
	)
end

return AutoSellService
