--[[
	RenascimentoCatalog.lua
	Gera os requisitos da Prova do Renascimento pra cada ciclo, por fórmula.

	REGRA FINAL (3 requisitos simultâneos, todos exigidos ao mesmo tempo):
	1. Sacrificar 3 cartas de um clã sorteado (o jogador escolhe livremente
	   QUAIS 3 criaturas daquele clã sacrificar - não são criaturas fixas).
	2. Sacrificar 1 cópia de uma criatura ESPECÍFICA (fixa, sorteada
	   deterministicamente por ciclo - todo mundo no servidor pede a mesma,
	   o que é o que torna troca/doação valiosa entre jogadores).
	3. Ter uma quantia mínima de Dinheiro em caixa no momento de renascer
	   (checagem de saldo simples - NÃO passa pelo Altar, não é sacrificado,
	   só precisa estar disponível; o Dinheiro reseta a 0 de qualquer forma
	   no Renascimento).

	Os itens 1 e 2 são satisfeitos posicionando cópias no Altar de
	Sacrifício (AltarSacrificioService.lua) - SEM pagamento em $ (isso é
	sacrifício puro, diferente da venda normal que dá 20% do valor; essa
	ausência de pagamento é uma suposição, não fechada explicitamente com a
	Paola - revisitar se necessário). RenascimentoService não escolhe mais
	sozinho o que consumir; o jogador precisa ter posicionado manualmente
	as cópias exigidas antes de conseguir confirmar.

	Local: ReplicatedStorage/Shared/Data/RenascimentoCatalog.lua
]]

local Clans = require(script.Parent.Clans)

local RenascimentoCatalog = {}

local TOTAL_CREATURES = 300

-- Quantidade fixa de cartas do clã sorteado exigida no item 1 da Prova
-- (o texto de design fala em "3 cartas", sem escalar por ciclo).
local CLAN_SACRIFICE_COUNT = 3

-- ============================================================================
-- Quantia mínima de Dinheiro (item 3) - curva CONVEXA, salto agressivo
-- entre ciclos (bem mais íngreme que a curva dos 30 pacotes Gerais, que já
-- é convexa mas suave no início). Mesma estrutura de parâmetros usada lá
-- (valor base, multiplicador/crescimento por ciclo, expoente de
-- convexidade), só que aplicada de forma ilimitada (Renascimento não tem
-- teto de 30 níveis).
--
-- ⚠️ PENDENTE: números abaixo são só uma PROPOSTA DE ESTRUTURA (a própria
-- Paola pediu pra não fechar os parâmetros sozinho) - ainda não validados.
-- Fórmula: custo(n) = BASE * CRESCIMENTO ^ (n ^ CONVEXIDADE)
-- ============================================================================
local MONEY_BASE = 1000000000 -- 1B no ciclo 0 (mesmo piso que a curva antiga)
local MONEY_GROWTH_PER_STEP = 10 -- cada "passo" de crescimento multiplica por 10x
local MONEY_CONVEXITY_EXPONENT = 1.3 -- >1 = cada ciclo acelera mais que o anterior (convexo)

local function calculateMoneyRequirement(renascimentoLevel: number): number
	local step = renascimentoLevel ^ MONEY_CONVEXITY_EXPONENT
	return math.floor(MONEY_BASE * (MONEY_GROWTH_PER_STEP ^ step))
end

-- Retorna a lista de requisitos pro jogador renascer DO ciclo
-- `renascimentoLevel` PRO próximo (renascimentoLevel + 1).
function RenascimentoCatalog.GetRequirements(renascimentoLevel: number)
	local reqs = {}

	-- Item 1: 3 cartas de um clã sorteado deterministicamente por ciclo,
	-- escolha livre de quais criaturas do clã sacrificar.
	local clan = Clans.Order[(renascimentoLevel % #Clans.Order) + 1]
	table.insert(reqs, { type = "sacrificeCardsByClan", clan = clan, count = CLAN_SACRIFICE_COUNT })

	-- Item 2: 1 cópia de uma criatura específica e fixa.
	local creatureId = ((renascimentoLevel * 17 + 5) % TOTAL_CREATURES) + 1
	table.insert(reqs, { type = "sacrificeSpecificCreature", creatureId = creatureId })

	-- Item 3: saldo mínimo de Dinheiro (não sacrificado, só checado).
	table.insert(reqs, { type = "money", amount = calculateMoneyRequirement(renascimentoLevel) })

	return reqs
end

return RenascimentoCatalog
