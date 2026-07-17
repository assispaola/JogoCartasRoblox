--[[
	RenascimentoCatalog.lua
	Gera os requisitos da Prova do Renascimento pra cada ciclo, por
	fórmula. Reaproveita os MESMOS tipos de requisito do
	ChallengeCatalog/LevelService (é o mesmo motor de checagem por baixo).

	Ciclo 0 -> 1 (primeiro Renascimento): mais tranquilo, serve de
	introdução ao sistema.
	Ciclos seguintes: nível mínimo mais alto, dinheiro maior, e a partir
	do ciclo 2 passa a exigir sacrificar uma criatura específica (a
	"desculpa" pra trocas/doações ficarem valiosas entre jogadores).

	Local: ReplicatedStorage/Shared/Data/RenascimentoCatalog.lua
]]

local RenascimentoCatalog = {}

local TOTAL_CREATURES = 300

-- Retorna a lista de requisitos pro jogador renascer DO ciclo
-- `renascimentoLevel` PRO próximo (renascimentoLevel + 1).
function RenascimentoCatalog.GetRequirements(renascimentoLevel: number)
	local reqs = {}

	local minPlayerLevel = 20 + renascimentoLevel * 15
	table.insert(reqs, { type = "playerLevel", amount = minPlayerLevel })

	local moneyRequired = (renascimentoLevel + 1) * 1000000000 -- 1B no 1º ciclo, escalando
	table.insert(reqs, { type = "money", amount = moneyRequired })

	-- Criatura específica sorteada deterministicamente por ciclo - todo
	-- mundo no servidor pede a mesma, o que é o que torna troca/doação
	-- valiosa entre jogadores.
	local creatureId = ((renascimentoLevel * 17 + 5) % TOTAL_CREATURES) + 1

	if renascimentoLevel == 0 then
		-- Primeiro ciclo: só precisa POSSUIR a criatura, não perde ela.
		table.insert(reqs, { type = "ownCreature", creatureId = creatureId })
	else
		-- Ciclos seguintes: precisa SACRIFICAR a criatura de verdade.
		table.insert(reqs, { type = "sacrificeSpecificCreature", creatureId = creatureId })
	end

	return reqs
end

return RenascimentoCatalog
