--!strict
--[[
	PackCatalog.lua

	Catálogo estático dos 77 pacotes de Cartas Míticas (v3).
	Fonte da verdade: Cartas_Miticas_Clans_e_Criaturas.xlsx + GAME_DESIGN_CARTAS_MITICAS_v3.md
	  (abas "Pacotes - Parâmetros" e "Pacotes - Catálogo")

	Estrutura v3 (77 packs totais):
	- 30 Ladder Geral (progressão principal, moeda: $)
	- 15 Packs de Clã (1 por clã, sempre disponível, moeda: $, preço 2x Ladder max)
	- 6 Diamante (recargas via 💎, mecânica de +cópias)
	- 9 Robux (melhor odds, moeda: real money)
	- 15 Especiais/Eventos (gratuitos, sazonais, ou exclusivos)

	Regras gerais:
	- Todo pacote sorteia entre os 15 clãs de forma UNIFORME. Raridade é o único fator
	  que muda a distribuição entre pacotes (ver PackOddsRoller.lua).
	- Raridade "Divino" só existe no pacote "PortalDivino" (evento), com odds = 1 (100%).
	- Category "Geral" usa moeda Coins; "Diamante" usa Diamonds; "Robux" usa Robux real;
	  "Especial" varia (Free / Coins / Diamonds / Event) — ver campo Currency de cada entrada.
	- Price = nil significa "a definir" (pacotes gratuitos usam Currency = "Free").
	- UnlockLevel = nil significa "sem trava de nível" (categorias fora de Geral, e Especiais que
	  já têm sua própria regra em Availability). Só a linha Geral (30 pacotes) usa UnlockLevel hoje.
	- Desbloqueio de UnlockLevel é PERSISTENTE: uma vez desbloqueado, nunca reseta — nem com
	  Renascimento. Ver PackService.TryUnlockNextGeneralPack em PackService.lua.
	- Se a planilha mudar, regenerar esta tabela a partir dela — não editar os números à mão
	  sem atualizar a planilha também (ela é a fonte única de verdade do projeto).
]]

export type PackCategory = "Geral" | "Clã" | "Diamante" | "Robux" | "Especial"

export type Currency = "Coins" | "Diamonds" | "Robux" | "Free" | "Event"

-- NOTA: chaves em ASCII sem acento de propósito (Lendario, Mitico) - Luau não
-- aceita acento em nome de campo "bareword" (só via `["Lendário"] = ...`, o
-- que deixaria os 77 pacotes abaixo ilegíveis). A tradução pro RarityId
-- acentuado canônico de Rarities.lua acontece em
-- PackOddsRoller.ToCanonicalRarityId, na fronteira entre este catálogo e o
-- resto do jogo.
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

export type AvailabilityKind =
	"AlwaysAvailable"
	| "OncePerAccount"
	| "DailyLimit"
	| "WeeklyStreak"
	| "Milestone"
	| "EventWindow"
	| "Referral"
	| "ReturningPlayer"

export type Availability = {
	Kind: AvailabilityKind,
	Limit: number?, -- ex: DailyLimit = 1 (uma abertura por dia)
}

export type PackDefinition = {
	Id: number,
	Key: string,
	Name: string,
	Category: PackCategory,
	Currency: Currency,
	CardsPerPurchase: number,
	Odds: RarityOdds,
	Price: number?,
	RobuxProductId: number?, -- placeholder (0) até cadastrar no Creator Dashboard
	UnlockLevel: number?, -- nível mínimo do jogador pra este pacote aparecer desbloqueado (persistente)
	Availability: Availability?, -- nil = sempre disponível, sem limite
	Notes: string,
}

local PackCatalog: { [string]: PackDefinition } = {}

-- ============================================================
-- 30 LADDER GERAL (IDs 1-30)
-- ============================================================
PackCatalog.Novato = {
	Id = 1,
	Key = "Novato",
	Name = "Novato",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 200,
	UnlockLevel = 1,
	Notes = "Ladder geral — nível 1/30",
}

PackCatalog.Recruta = {
	Id = 2,
	Key = "Recruta",
	Name = "Recruta",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 299,
	UnlockLevel = 2,
	Notes = "Ladder geral — nível 2/30",
}

PackCatalog.Aprendiz = {
	Id = 3,
	Key = "Aprendiz",
	Name = "Aprendiz",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 448,
	UnlockLevel = 3,
	Notes = "Ladder geral — nível 3/30",
}

PackCatalog.Errante = {
	Id = 4,
	Key = "Errante",
	Name = "Errante",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 672,
	UnlockLevel = 4,
	Notes = "Ladder geral — nível 4/30",
}

PackCatalog.Andarilho = {
	Id = 5,
	Key = "Andarilho",
	Name = "Andarilho",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 1006,
	UnlockLevel = 5,
	Notes = "Ladder geral — nível 5/30",
}

PackCatalog.Explorador = {
	Id = 6,
	Key = "Explorador",
	Name = "Explorador",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 1507,
	UnlockLevel = 6,
	Notes = "Ladder geral — nível 6/30",
}

PackCatalog.Cacador = {
	Id = 7,
	Key = "Cacador",
	Name = "Caçador",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 2257,
	UnlockLevel = 7,
	Notes = "Ladder geral — nível 7/30",
}

PackCatalog.Rastreador = {
	Id = 8,
	Key = "Rastreador",
	Name = "Rastreador",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 3380,
	UnlockLevel = 8,
	Notes = "Ladder geral — nível 8/30",
}

PackCatalog.Guerreiro = {
	Id = 9,
	Key = "Guerreiro",
	Name = "Guerreiro",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 5062,
	UnlockLevel = 9,
	Notes = "Ladder geral — nível 9/30",
}

PackCatalog.Bravo = {
	Id = 10,
	Key = "Bravo",
	Name = "Bravo",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 7585,
	UnlockLevel = 10,
	Notes = "Ladder geral — nível 10/30",
}

PackCatalog.Guardiao = {
	Id = 11,
	Key = "Guardiao",
	Name = "Guardião",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 11359,
	UnlockLevel = 11,
	Notes = "Ladder geral — nível 11/30",
}

PackCatalog.Sentinela = {
	Id = 12,
	Key = "Sentinela",
	Name = "Sentinela",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 17021,
	UnlockLevel = 12,
	Notes = "Ladder geral — nível 12/30",
}

PackCatalog.Vigia = {
	Id = 13,
	Key = "Vigia",
	Name = "Vigia",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 25500,
	UnlockLevel = 13,
	Notes = "Ladder geral — nível 13/30",
}

PackCatalog.Campeao = {
	Id = 14,
	Key = "Campeao",
	Name = "Campeão",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 38219,
	UnlockLevel = 14,
	Notes = "Ladder geral — nível 14/30",
}

PackCatalog.Heroi = {
	Id = 15,
	Key = "Heroi",
	Name = "Herói",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 57265,
	UnlockLevel = 15,
	Notes = "Ladder geral — nível 15/30",
}

PackCatalog.Vencedor = {
	Id = 16,
	Key = "Vencedor",
	Name = "Vencedor",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 85777,
	UnlockLevel = 16,
	Notes = "Ladder geral — nível 16/30",
}

PackCatalog.Mestre = {
	Id = 17,
	Key = "Mestre",
	Name = "Mestre",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 128530,
	UnlockLevel = 17,
	Notes = "Ladder geral — nível 17/30",
}

PackCatalog.Especialista = {
	Id = 18,
	Key = "Especialista",
	Name = "Especialista",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 192500,
	UnlockLevel = 18,
	Notes = "Ladder geral — nível 18/30",
}

PackCatalog.Perito = {
	Id = 19,
	Key = "Perito",
	Name = "Perito",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 288298,
	UnlockLevel = 19,
	Notes = "Ladder geral — nível 19/30",
}

PackCatalog.Arauto = {
	Id = 20,
	Key = "Arauto",
	Name = "Arauto",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 432000,
	UnlockLevel = 20,
	Notes = "Ladder geral — nível 20/30",
}

PackCatalog.Mensageiro = {
	Id = 21,
	Key = "Mensageiro",
	Name = "Mensageiro",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 647400,
	UnlockLevel = 21,
	Notes = "Ladder geral — nível 21/30",
}

PackCatalog.Sabio = {
	Id = 22,
	Key = "Sabio",
	Name = "Sábio",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 970000,
	UnlockLevel = 22,
	Notes = "Ladder geral — nível 22/30",
}

PackCatalog.Erudito = {
	Id = 23,
	Key = "Erudito",
	Name = "Erudito",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 1453000,
	UnlockLevel = 23,
	Notes = "Ladder geral — nível 23/30",
}

PackCatalog.Vidente = {
	Id = 24,
	Key = "Vidente",
	Name = "Vidente",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 2177450,
	UnlockLevel = 24,
	Notes = "Ladder geral — nível 24/30",
}

PackCatalog.Oraculo = {
	Id = 25,
	Key = "Oraculo",
	Name = "Oráculo",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 3263500,
	UnlockLevel = 25,
	Notes = "Ladder geral — nível 25/30",
}

PackCatalog.Profeta = {
	Id = 26,
	Key = "Profeta",
	Name = "Profeta",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 4892475,
	UnlockLevel = 26,
	Notes = "Ladder geral — nível 26/30",
}

PackCatalog.Visionario = {
	Id = 27,
	Key = "Visionario",
	Name = "Visionário",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 7331500,
	UnlockLevel = 27,
	Notes = "Ladder geral — nível 27/30",
}

PackCatalog.Avatar = {
	Id = 28,
	Key = "Avatar",
	Name = "Avatar",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 10986000,
	UnlockLevel = 28,
	Notes = "Ladder geral — nível 28/30",
}

PackCatalog.Ascendente = {
	Id = 29,
	Key = "Ascendente",
	Name = "Ascendente",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 16463750,
	UnlockLevel = 29,
	Notes = "Ladder geral — nível 29/30",
}

PackCatalog.Transcendente = {
	Id = 30,
	Key = "Transcendente",
	Name = "Transcendente",
	Category = "Geral",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 280000000000,
	UnlockLevel = 30,
	Notes = "Ladder geral — nível 30/30 (final)",
}

-- ============================================================
-- 15 PACKS DE CLÃ (IDs 31-45)
-- Preço dinâmico: 2x o preço do pack Ladder máximo do ciclo
-- ============================================================
PackCatalog.ClanOrdemCelestial = {
	Id = 31,
	Key = "ClanOrdemCelestial",
	Name = "Ordem Celestial",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil, -- dinâmico: 2x Ladder máximo do ciclo
	Notes = "Pack de Clã — Ordem Celestial (sempre disponível)",
}

PackCatalog.ClanVeuSombrio = {
	Id = 32,
	Key = "ClanVeuSombrio",
	Name = "Véu Sombrio",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Véu Sombrio (sempre disponível)",
}

PackCatalog.ClanFuriaSelvagem = {
	Id = 33,
	Key = "ClanFuriaSelvagem",
	Name = "Fúria Selvagem",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Fúria Selvagem (sempre disponível)",
}

PackCatalog.ClanAbismoGlacial = {
	Id = 34,
	Key = "ClanAbismoGlacial",
	Name = "Abismo Glacial",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Abismo Glacial (sempre disponível)",
}

PackCatalog.ClanMareEterna = {
	Id = 35,
	Key = "ClanMareEterna",
	Name = "Maré Eterna",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Maré Eterna (sempre disponível)",
}

PackCatalog.ClanForgaIgnea = {
	Id = 36,
	Key = "ClanForgaIgnea",
	Name = "Forja Ígnea",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Forja Ígnea (sempre disponível)",
}

PackCatalog.ClanTempestadeRunica = {
	Id = 37,
	Key = "ClanTempestadeRunica",
	Name = "Tempestade Rúnica",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Tempestade Rúnica (sempre disponível)",
}

PackCatalog.ClanRochaAncestral = {
	Id = 38,
	Key = "ClanRochaAncestral",
	Name = "Rocha Ancestral",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Rocha Ancestral (sempre disponível)",
}

PackCatalog.ClanAreiaAmaldicoada = {
	Id = 39,
	Key = "ClanAreiaAmaldicoada",
	Name = "Areia Amaldiçoada",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Areia Amaldiçoada (sempre disponível)",
}

PackCatalog.ClanSelvaEsmeralda = {
	Id = 40,
	Key = "ClanSelvaEsmeralda",
	Name = "Selva Esmeralda",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Selva Esmeralda (sempre disponível)",
}

PackCatalog.ClanConstelaçãoArcana = {
	Id = 41,
	Key = "ClanConstelaçãoArcana",
	Name = "Constelação Arcana",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Constelação Arcana (sempre disponível)",
}

PackCatalog.ClanProfundezasAbissais = {
	Id = 42,
	Key = "ClanProfundezasAbissais",
	Name = "Profundezas Abissais",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Profundezas Abissais (sempre disponível)",
}

PackCatalog.ClanChamaVulcanica = {
	Id = 43,
	Key = "ClanChamaVulcanica",
	Name = "Chama Vulcânica",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Chama Vulcânica (sempre disponível)",
}

PackCatalog.ClanNeVoaEspectral = {
	Id = 44,
	Key = "ClanNeVoaEspectral",
	Name = "Névoa Espectral",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Névoa Espectral (sempre disponível)",
}

PackCatalog.ClanEngrenagemRunica = {
	Id = 45,
	Key = "ClanEngrenagemRunica",
	Name = "Engrenagem Rúnica",
	Category = "Clã",
	Currency = "Coins",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Notes = "Pack de Clã — Engrenagem Rúnica (sempre disponível)",
}

-- ============================================================
-- 6 PACKS DE DIAMANTE (IDs 46-51)
-- Mecânica: abre 3 criaturas, jogador escolhe quais ganham +cópias
-- ============================================================
PackCatalog.Fragmento = {
	Id = 46,
	Key = "Fragmento",
	Name = "Fragmento",
	Category = "Diamante",
	Currency = "Diamonds",
	CardsPerPurchase = 3,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 600,
	Notes = "Pack Diamante — abre 3, escolhe 1 para +1 cópia",
}

PackCatalog.Cristal = {
	Id = 47,
	Key = "Cristal",
	Name = "Cristal",
	Category = "Diamante",
	Currency = "Diamonds",
	CardsPerPurchase = 3,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 1200,
	Notes = "Pack Diamante — abre 3, escolhe 1 para +2 cópias",
}

PackCatalog.Nucleo = {
	Id = 48,
	Key = "Nucleo",
	Name = "Núcleo",
	Category = "Diamante",
	Currency = "Diamonds",
	CardsPerPurchase = 3,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 2000,
	Notes = "Pack Diamante — abre 3, todas 3 ganham +1 cópia",
}

PackCatalog.Prisma = {
	Id = 49,
	Key = "Prisma",
	Name = "Prisma",
	Category = "Diamante",
	Currency = "Diamonds",
	CardsPerPurchase = 3,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 3500,
	Notes = "Pack Diamante — abre 3, escolhe 2 para +2 cópias cada",
}

PackCatalog.Coroa = {
	Id = 50,
	Key = "Coroa",
	Name = "Coroa",
	Category = "Diamante",
	Currency = "Diamonds",
	CardsPerPurchase = 3,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 5000,
	Notes = "Pack Diamante — abre 3 (min Tier B), escolhe 1 para +1",
}

PackCatalog.Apice = {
	Id = 51,
	Key = "Apice",
	Name = "Ápice",
	Category = "Diamante",
	Currency = "Diamonds",
	CardsPerPurchase = 3,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = 7500,
	Notes = "Pack Diamante — abre 3 (min Tier A), escolhe A para +2",
}

-- ============================================================
-- 9 PACKS DE ROBUX (IDs 52-60)
-- Melhores odds do jogo
-- ============================================================
PackCatalog.Escudeiro = {
	Id = 52,
	Key = "Escudeiro",
	Name = "Escudeiro",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 1,
	Odds = { Default = 0, Bronze = 0.28, Prata = 0.22, Ouro = 0.19, Platina = 0.16, Lendario = 0.11, Mitico = 0.04, Divino = 0 },
	Price = 99,
	RobuxProductId = 0,
	Notes = "Pack Robux — nível 1/9",
}

PackCatalog.Nobre = {
	Id = 53,
	Key = "Nobre",
	Name = "Nobre",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 1,
	Odds = { Default = 0, Bronze = 0.2575, Prata = 0.21125, Ouro = 0.19125, Platina = 0.17125, Lendario = 0.12125, Mitico = 0.0475, Divino = 0 },
	Price = 149,
	RobuxProductId = 0,
	Notes = "Pack Robux — nível 2/9",
}

PackCatalog.Duque = {
	Id = 54,
	Key = "Duque",
	Name = "Duque",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 1,
	Odds = { Default = 0, Bronze = 0.235, Prata = 0.2025, Ouro = 0.1925, Platina = 0.1825, Lendario = 0.1325, Mitico = 0.055, Divino = 0 },
	Price = 249,
	RobuxProductId = 0,
	Notes = "Pack Robux — nível 3/9",
}

PackCatalog.Monarca = {
	Id = 55,
	Key = "Monarca",
	Name = "Monarca",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 1,
	Odds = { Default = 0, Bronze = 0.2125, Prata = 0.19375, Ouro = 0.19375, Platina = 0.19375, Lendario = 0.14375, Mitico = 0.0625, Divino = 0 },
	Price = 399,
	RobuxProductId = 0,
	Notes = "Pack Robux — nível 4/9",
}

PackCatalog.Soberano = {
	Id = 56,
	Key = "Soberano",
	Name = "Soberano",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 1,
	Odds = { Default = 0, Bronze = 0.19, Prata = 0.185, Ouro = 0.195, Platina = 0.205, Lendario = 0.155, Mitico = 0.07, Divino = 0 },
	Price = 649,
	RobuxProductId = 0,
	Notes = "Pack Robux — nível 5/9",
}

PackCatalog.Imperador = {
	Id = 57,
	Key = "Imperador",
	Name = "Imperador",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 1,
	Odds = { Default = 0, Bronze = 0.1675, Prata = 0.17625, Ouro = 0.19625, Platina = 0.21625, Lendario = 0.16625, Mitico = 0.0775, Divino = 0 },
	Price = 999,
	RobuxProductId = 0,
	Notes = "Pack Robux — nível 6/9",
}

PackCatalog.BauDoColecionador = {
	Id = 58,
	Key = "BauDoColecionador",
	Name = "Baú do Colecionador",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 3,
	Odds = { Default = 0, Bronze = 0.145, Prata = 0.1675, Ouro = 0.1975, Platina = 0.2275, Lendario = 0.1775, Mitico = 0.085, Divino = 0 },
	Price = 349,
	RobuxProductId = 0,
	Notes = "Pack Robux — multi-carta (3) — nível 7/9",
}

PackCatalog.BauDoPatrono = {
	Id = 59,
	Key = "BauDoPatrono",
	Name = "Baú do Patrono",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 5,
	Odds = { Default = 0, Bronze = 0.1225, Prata = 0.15875, Ouro = 0.19875, Platina = 0.23875, Lendario = 0.18875, Mitico = 0.0925, Divino = 0 },
	Price = 799,
	RobuxProductId = 0,
	Notes = "Pack Robux — multi-carta (5) — nível 8/9",
}

PackCatalog.BauDoFundador = {
	Id = 60,
	Key = "BauDoFundador",
	Name = "Baú do Fundador",
	Category = "Robux",
	Currency = "Robux",
	CardsPerPurchase = 8,
	Odds = { Default = 0, Bronze = 0.1, Prata = 0.15, Ouro = 0.2, Platina = 0.25, Lendario = 0.2, Mitico = 0.1, Divino = 0 },
	Price = 1499,
	RobuxProductId = 0,
	Notes = "Pack Robux — multi-carta (8) — nível 9/9",
}

-- ============================================================
-- 15 PACKS ESPECIAIS/EVENTOS (IDs 61-77)
-- Gratuitos, sazonais, eventos exclusivos
-- ============================================================
PackCatalog.Chegada = {
	Id = 61,
	Key = "Chegada",
	Name = "Chegada",
	Category = "Especial",
	Currency = "Free",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "OncePerAccount" },
	Notes = "Starter — 1x por conta nova",
}

PackCatalog.BencaoDiaria = {
	Id = 62,
	Key = "BencaoDiaria",
	Name = "Bênção Diária",
	Category = "Especial",
	Currency = "Free",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "DailyLimit", Limit = 1 },
	Notes = "Grátis, 1x por dia (força Default)",
}

PackCatalog.RetornoDoHeroi = {
	Id = 63,
	Key = "RetornoDoHeroi",
	Name = "Retorno do Herói",
	Category = "Especial",
	Currency = "Free",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "ReturningPlayer" },
	Notes = "Reengajamento — condicional",
}

PackCatalog.Relampago = {
	Id = 64,
	Key = "Relampago",
	Name = "Relâmpago",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Venda-relâmpago — janela de tempo limitada",
}

PackCatalog.SorteDoDestino = {
	Id = 65,
	Key = "SorteDoDestino",
	Name = "Sorte do Destino",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Evento live — odds turbinadas temporariamente",
}

PackCatalog.PrimeiroRenascimento = {
	Id = 66,
	Key = "PrimeiroRenascimento",
	Name = "Primeiro Renascimento",
	Category = "Especial",
	Currency = "Free",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "Milestone" },
	Notes = "Dado automaticamente no 1º Renascimento",
}

PackCatalog.PortalDivino = {
	Id = 67,
	Key = "PortalDivino",
	Name = "Portal Divino",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 0, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 1 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "ÚNICA fonte de Raridade Divino — garante 1 Divina (clã aleatório)",
}

PackCatalog.ConfluenciaMistica = {
	Id = 68,
	Key = "ConfluenciaMistica",
	Name = "Confluência Mística",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 3,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "AlwaysAvailable" },
	Notes = "Bundle — 3 cartas por compra",
}

PackCatalog.Aniversario = {
	Id = 69,
	Key = "Aniversario",
	Name = "Aniversário",
	Category = "Especial",
	Currency = "Free",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Evento anual — data de aniversário do jogo",
}

PackCatalog.SolsticioDeVerao = {
	Id = 70,
	Key = "SolsticioDeVerao",
	Name = "Solstício de Verão",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Sazonal — verão",
}

PackCatalog.NoiteDasSombras = {
	Id = 71,
	Key = "NoiteDasSombras",
	Name = "Noite das Sombras",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Sazonal — outubro",
}

PackCatalog.AmanhecerDeAnoNovo = {
	Id = 72,
	Key = "AmanhecerDeAnoNovo",
	Name = "Amanhecer de Ano Novo",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Sazonal — virada de ano",
}

PackCatalog.ColheitaDeOutono = {
	Id = 73,
	Key = "ColheitaDeOutono",
	Name = "Colheita de Outono",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Sazonal — outono",
}

PackCatalog.ConviteDoAmigo = {
	Id = 74,
	Key = "ConviteDoAmigo",
	Name = "Convite do Amigo",
	Category = "Especial",
	Currency = "Free",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "Referral" },
	Notes = "Recompensa de indicação",
}

PackCatalog.ConstanciaSemanal = {
	Id = 75,
	Key = "ConstanciaSemanal",
	Name = "Constância Semanal",
	Category = "Especial",
	Currency = "Free",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "WeeklyStreak" },
	Notes = "Recompensa de streak semanal",
}

PackCatalog.SolsticioDeInverno = {
	Id = 76,
	Key = "SolsticioDeInverno",
	Name = "Solstício de Inverno",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Sazonal — solstício de inverno",
}

PackCatalog.FestivalDaPrimavera = {
	Id = 77,
	Key = "FestivalDaPrimavera",
	Name = "Festival da Primavera",
	Category = "Especial",
	Currency = "Event",
	CardsPerPurchase = 1,
	Odds = { Default = 1, Bronze = 0, Prata = 0, Ouro = 0, Platina = 0, Lendario = 0, Mitico = 0, Divino = 0 },
	Price = nil,
	Availability = { Kind = "EventWindow" },
	Notes = "Sazonal — primavera",
}

return PackCatalog
