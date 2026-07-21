--!strict
--[[
	HUDTest.client.lua
	Script de TESTE — monta o HUD e simula uma economia rodando ao vivo,
	sem depender ainda do EconomyService real. Serve para validar visualmente
	o componente antes de conectar aos sistemas reais.

	Localização Rojo sugerida: StarterPlayer/StarterPlayerScripts/HUDTest

	Ao apertar Play no Studio, você deve ver:
	  - $ subindo sozinho (renda passiva simulada)
	  - 💎 ganhando de tempos em tempos + toast avisando
	  - Barra de XP enchendo e "levando up" ao encher
	  - Badges nos ícones de presente/sino aumentando

	IMPORTANTE: este script é só para teste. Quando o EconomyService,
	PlayerDataService etc. estiverem prontos, substituir os "simulate*"
	por eventos reais (RemoteEvent / atributos do jogador).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HUD = require(ReplicatedStorage.Shared.UI.HUD)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== MONTAR O HUD =====================

local hud = HUD.new(playerGui)

-- Estado inicial (equivalente ao que viria do PlayerDataService)
local state = {
	money = 1_250_000,
	diamonds = 450,
	incomePerSecond = 50_000,
	level = 42,
	currentXP = 12_450,
	maxXP = 25_000,
}

hud:SetMoney(state.money)
hud:SetDiamonds(state.diamonds)
hud:SetIncomePerSecond(state.incomePerSecond)
hud:SetLevel(state.level, state.currentXP, state.maxXP)
hud:SetBadge("gift", 3)
hud:SetBadge("bell", 7)

-- ===================== SIMULAÇÃO 1: RENDA PASSIVA =====================
-- Credita a renda por segundo de forma gradual (igual ao loop real do jogo)

local accumulator = 0
RunService.Heartbeat:Connect(function(deltaTime: number)
	accumulator += state.incomePerSecond * deltaTime
	if accumulator >= 1 then
		local wholeAmount = math.floor(accumulator)
		accumulator -= wholeAmount
		state.money += wholeAmount
		hud:SetMoney(state.money)
	end
end)

-- ===================== SIMULAÇÃO 2: GANHO DE DIAMANTE ALEATÓRIO =====================
-- Simula Roda do Destino / Baús da Jornada premiando o jogador periodicamente

task.spawn(function()
	while true do
		task.wait(math.random(6, 10))
		local gained = math.random(20, 120)
		state.diamonds += gained
		hud:SetDiamonds(state.diamonds)
		hud:ShowToast(("✨ Você ganhou %d 💎!"):format(gained), Color3.fromHex("#3ec1ff"))
	end
end)

-- ===================== SIMULAÇÃO 3: PROGRESSO DE XP E LEVEL UP =====================

task.spawn(function()
	while true do
		task.wait(math.random(3, 6))
		local xpGained = math.random(500, 2000)
		state.currentXP += xpGained

		if state.currentXP >= state.maxXP then
			state.currentXP -= state.maxXP
			state.level += 1
			state.maxXP = math.floor(state.maxXP * 1.15) -- próximo nível exige mais XP
			hud:ShowToast(("🏅 Nível %d alcançado!"):format(state.level), Color3.fromHex("#ffd23f"))
		end

		hud:SetLevel(state.level, state.currentXP, state.maxXP)
	end
end)

-- ===================== SIMULAÇÃO 4: NOTIFICAÇÕES (presente/sino) =====================

task.spawn(function()
	local giftCount = 3
	local bellCount = 7

	while true do
		task.wait(math.random(8, 14))
		giftCount += 1
		hud:SetBadge("gift", giftCount)

		task.wait(math.random(4, 9))
		bellCount += 1
		hud:SetBadge("bell", bellCount)
	end
end)

print("[HUDTest] HUD montado e simulação de economia rodando. Pressione Play para testar.")
