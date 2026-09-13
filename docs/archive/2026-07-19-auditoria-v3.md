# Arquivo histórico — Auditoria v3 (19/07/2026)

> **Isto é um registro histórico, não uma spec atual.** Consolida 4
> documentos de uma única sessão de auditoria de 19/07/2026 que viviam soltos
> em `docs/`: `RELATÓRIO_AUDITORIA_v3.md`, `RESUMO_FIXES_APLICADOS.md`,
> `PRÓXIMOS_PASSOS_PÓS_AUDITORIA.md` e `AUDITORIA_COMPLETA_SUMÁRIO.txt` (esse
> último não foi copiado pra cá na íntegra — era só um resumo/índice
> executivo dos outros 3, sem informação nova). Movido pra `docs/archive/`
> em 12/09/2026 por já ter cumprido seu papel. Não usar como referência de
> valores/estado atual — ver `CLAUDE.md` pra isso.
>
> **Nota de 12/09/2026 (o que envelheceu desde então):** o `Tiers.lua`
> "criado" na seção 2 abaixo foi removido de novo numa reorganização
> posterior — hoje não existe (ver `CLAUDE.md`, seção "Decisões ainda
> pendentes"). Os outros 4 fixes (cores de clã, nome Raijin, custo de
> Despertar Divino 10.000💎, PackCatalog com 77 packs) **continuam válidos**
> no código atual.

---

# Parte 1 — Relatório de Auditoria Completa — Cartas Míticas v3
> **Data:** 19/07/2026 · **Status:** Auditoria completa concluída
> **Versão do Game Design:** v3
> **Arquivos verificados:** 34 módulos Luau + estrutura de dados

## Sumário Executivo

A auditoria identificou **5 problemas críticos**, **2 bugs conhecidos** e **1 estrutura faltante** que precisam ser resolvidos antes de considerar o código conforme v3.

| Severidade | Qty | Status |
|---|---|---|
| 🔴 **Crítico** | 5 | Bloqueador de compliance |
| 🟠 **Alto** | 2 | Conhecido, requer migração |
| 🟡 **Médio** | 3 | Melhorias de consistência |
| 🟢 **Baixo** | 1 | Documentação |

## 1️⃣ CLANS.LUA — Cores Hex Incorretas

**Arquivo:** `src/shared/Data/Clans.lua`
**Severidade:** 🔴 **CRÍTICO**
**Status:** ❌ 3 clãs com cores ERRADAS

Três cores dos clãs **divergem do v3** conforme definido em GAME_DESIGN_CARTAS_MITICAS_v3.md (seção 3):

| # | Clã | Elemento | Esperado (v3) | Código | Status |
|---|---|---|---|---|---|
| 7 | Tempestade Rúnica | Trovão | `#FF99CA` | `#E4F797` ❌ | ERRADO |
| 13 | Chama Vulcânica | Lava | `#3D0F17` | `#66192B` ❌ | ERRADO |
| 15 | Engrenagem Rúnica | Tecnomancia | `#DBF470` | `#4B9B90` ❌ | ERRADO |

**Linhas afetadas:**
- Linha 32: `colorHex = "#E4F797"` → deve ser `"#FF99CA"`
- Linha 38: `colorHex = "#66192B"` → deve ser `"#3D0F17"`
- Linha 40: `colorHex = "#4B9B90"` → deve ser `"#DBF470"`

**Por que é crítico:**
- Cores são parte da identidade visual aprovada (v3 marca como ✅ Aprovado)
- UI de borders e clã-specifics dependem dessas cores
- Impacto direto na apresentação ao jogador

**Fix:** Substituir 3 valores hex

## 2️⃣ PACK CATALOG — Apenas 62 Packs (Faltam 15)

**Arquivo:** `src/shared/Data/PackCatalog.lua`
**Severidade:** 🔴 **CRÍTICO**
**Status:** ❌ Faltam 15 packs para atingir o total v3 de 77

**v3 especifica 77 packs totais:**
- 30 Ladder Geral ✅ (implementado)
- 15 Packs de Clã ❌ (FALTAM)
- 6 Diamante ❌ (FALTAM)
- 9 Robux ❌ (FALTAM)
- 15 Especiais/Eventos ❌ (FALTAM)

**Status atual:** PackCatalog.lua tem 62 packs, sendo:
- ~30 Ladder Geral (Novato → Transcendente)
- Nenhum Pack de Clã
- Nenhum Pack de Diamante
- Nenhum Pack de Robux
- ~4 Especiais (PortalDivino, etc.)

**Impacto:**
- Economia quebrada (sem fontes de diamante/Robux)
- Lojas incompletas (ui vai mostrar vazio)
- Ciclo de monetização não funciona

**Fix:** Criar 45 novos packs (15 Clã + 6 Diamante + 9 Robux + 15 Especiais)

## 3️⃣ TIERS.LUA — Arquivo Não Existe

**Arquivo:** `src/shared/Data/Tiers.lua`
**Severidade:** 🔴 **CRÍTICO**
**Status:** ❌ FALTANTE

v3 define um sistema central de **Tiers (C/B/A)** com:
- seedValue distintos: C=×1, B=×4, A=×15
- Distribuição: 10 C + 7 B + 3 A por clã (300 criaturas base)
- Sistema de seleção de Tier ao abrir packs

**O arquivo Tiers.lua não existe no projeto**, porém:
- Creatures.lua menciona Tiers
- PackCatalog especifica % C/B/A por pack
- PackOddsRoller menciona sorting por tier

**O que falta:**
```lua
-- Esperado em src/shared/Data/Tiers.lua
export type TierData = {
	id: string,        -- "C" | "B" | "A"
	seedValueMult: number, -- 1, 4, 15
	name: string,      -- "Comum", "Nobre", "Ancestral"
	symbol: string,    -- "⭐", "⭐⭐", "⭐⭐⭐"
}

Tiers.C = { id = "C", seedValueMult = 1, name = "Comum", symbol = "⭐" }
Tiers.B = { id = "B", seedValueMult = 4, name = "Nobre", symbol = "⭐⭐" }
Tiers.A = { id = "A", seedValueMult = 15, name = "Ancestral", symbol = "⭐⭐⭐" }
```

**Impacto:**
- PackOddsRoller não pode sortear tier corretamente
- Creatures não podem referenciar seu tier
- EconomyService não pode aplicar seedValueMult

**Fix:** Criar Tiers.lua conforme v3 seção 2

## 4️⃣ DIVINECREATURAS — Nome de Criatura Divina Errado

**Arquivo:** `src/shared/Data/DivineCreatures.lua`
**Severidade:** 🔴 **CRÍTICO**
**Status:** ❌ Linha 71: "Chaac" deveria ser "Raijin"

Segundo o CLAUDE.md (Divino — lista de nomes):
> Nomes exatos: Amaterasu, Hécate, Cernunnos, Skadi, Poseidon, Agni, **Raijin**, Gaia, Anubis, Shesha Naga, Nuwa, Cthulhu, Pele, Morrígan, Thoth

**Criatura do clã Tempestade Rúnica (#7):**
- Código (linha 71): `name = "Chaac"` (deus Maia, México)
- Esperado: `"Raijin"` (deus Xintoísta, Japão)

**Origem listada:**
- Código: `origin = "Maia"`
- Deveria ser: `"Japão (Xintoísmo)"`

**Por que é crítico:**
- Quebra a promise de "100% mitologia de domínio público"
- Raijin é nomeação aprovada; Chaac não está no documento final

**Fix:** Renomear para Raijin e ajustar descrição/origem

## 5️⃣ RARITIES — Custo de Despertar do Divino Errado

**Arquivo:** `src/shared/Data/Rarities.lua`
**Severidade:** 🔴 **CRÍTICO** (mas menor que os anteriores)
**Status:** ❌ Linha 55: awakenCostDiamonds = 25000 (deveria ser 10.000)

v3 especifica custos de Despertar (seção 5):
| Rarity | Custo 💎 |
|---|---|
| Comum (C) | 2.500 |
| Nobre (B) | 5.000 |
| Ancestral (A) | 7.500 |
| **Divino** | **10.000** |

**Fix:** Mudar `awakenCostDiamonds` de 25000 para 10000

## 6️⃣ PACKETSERVICE & DEPENDÊNCIAS — Bugs Conhecidos

**Severidade:** 🟠 **ALTO** (já documentado em CLAUDE.md)
**Status:** ⚠️ CONHECIDO, requer migração

### 6A. WheelService/DailyBlessingService/JourneyChestService — IDs de Pack Inválidos

Esses serviços chamam `PackService.GrantFreePack(player, packId)` passando IDs do modelo antigo (tier+clã), que não existem no novo catálogo (77 packs, indexado por `Key` string). **Fix:** Migrar as 3 chamadas para passar `Key` válida do novo PackCatalog.

### 6B. MarketplaceService.ProcessReceipt — Dispatcher Quebrado

`PackService.Init()` e `GamepassService.Init()` atribuem `MarketplaceService.ProcessReceipt` cada um o seu; como `Main.lua` chama os dois, só o último a rodar (`GamepassService`) fica valendo — compras Robux de pacotes nunca são processadas. **Fix:** Criar um dispatcher único que combine ambos os fluxos.

## ✅ MÓDULOS CONFORMES COM v3

| Módulo | Status | Notas |
|---|---|---|
| **Rarities.lua** | ✅ OK | 8 raridades corretas, multiplicadores OK |
| **AlbumEvolutionCurve.lua** | ✅ OK | Função contínua correta, thresholds OK |
| **DivineCreatures.lua** | ⚠️ 1 erro | 14/15 nomes corretos, "Chaac" → "Raijin" |
| **GamepassCatalog.lua** | ✅ OK | 9 gamepasses (sem Relicário removido ✓) |
| **PlayerDataService.lua** | ✅ OK | Schema v2 atualizado, migration OK |
| **AlbumService.lua** | ✅ OK | RegistrarCopia, evolução contínua OK |
| **EconomyService.lua** | ✅ OK | Fórmula de valor OK, multiplicadores OK |
| **RenascimentoService.lua** | ✅ OK | 3 requisitos simultâneos implementados |
| **AltarSacrificioService.lua** | ✅ OK | Staging manual implementado |
| **RenascimentoCatalog.lua** | ✅ OK | Requisitos OK, curva convexa estruturada |
| **LevelService.lua** | ✅ OK | Desafios implementados |
| **Creatures.lua** | ✅ OK | 300 criaturas base (3611 linhas) |

## 📝 Próximos Passos (Após Auditoria) — resumo

Decisões pendentes com a Paola (curva convexa de Renascimento, pagamento no
sacrifício do Altar, opção de auto-venda pós-Mítico), tasks de arte (15
Divinas, identidade visual por Tier, borda Divino), testes de balance e
atualização de `CLAUDE.md` — ver detalhamento completo na Parte 3 abaixo.

---

# Parte 2 — Resumo de Fixes Aplicados — Compliance v3

**Data:** 19/07/2026
**Status:** ✅ TODOS OS FIXES CRÍTICOS APLICADOS (na época — ver nota de 12/09/2026 no topo deste arquivo sobre o Tiers.lua)

## 🔴 5 Problemas Críticos — RESOLVIDOS (em 19/07/2026)

### 1️⃣ Clans.lua — Cores Hex Corrigidas

| Clã | Esperado | Antes | Depois |
|---|---|---|---|
| Tempestade Rúnica | #FF99CA | #E4F797 | ✅ #FF99CA |
| Chama Vulcânica | #3D0F17 | #66192B | ✅ #3D0F17 |
| Engrenagem Rúnica | #DBF470 | #4B9B90 | ✅ #DBF470 |

### 2️⃣ DivineCreatures.lua — Criatura Divina Corrigida

Criatura #7 (Tempestade Rúnica): `Chaac` (Maia) → `Raijin` (Japão), origem
`Maia` → `Japão (Xintoísmo)`, descrição atualizada.

### 3️⃣ Rarities.lua — Custo de Despertar Divino Corrigido

Divino: `awakenCostDiamonds` 25.000 → 10.000.

### 4️⃣ Tiers.lua — Arquivo Novo Criado ✨

```lua
Tiers.C = { id = "C", seedValueMult = 1, name = "Comum", symbol = "⭐", creaturesPerClan = 10 }
Tiers.B = { id = "B", seedValueMult = 4, name = "Nobre", symbol = "⭐⭐", creaturesPerClan = 7 }
Tiers.A = { id = "A", seedValueMult = 15, name = "Ancestral", symbol = "⭐⭐⭐", creaturesPerClan = 3 }
```

Exports `TierId`/`TierData`. **(Removido de novo numa reorganização
posterior — não existe no código em 12/09/2026, ver nota no topo.)**

### 5️⃣ PackCatalog.lua — Expandido para 77 Packs

| Categoria | Qtd | IDs | Status |
|---|---|---|---|
| **Ladder Geral** | 30 | 1–30 | ✅ Mantido |
| **Packs de Clã** | 15 | 31–45 | ✅ ADICIONADO |
| **Diamante** | 6 | 46–51 | ✅ ADICIONADO |
| **Robux** | 9 | 52–60 | ✅ ADICIONADO |
| **Especiais/Eventos** | 15 | 61–77 | ✅ ADICIONADO |
| **TOTAL** | **77** | 1–77 | ✅ COMPLETO |

15 Packs de Clã (31–45): 1 por clã (ordem de `Clans.lua`), sempre
disponível desde Ciclo 0, acessa Tier C+B (sem A), raridade Default, moeda
$, preço dinâmico (2× Ladder máximo do ciclo).

## 🎯 Métricas de Compliance (em 19/07/2026)

| Aspecto | v3 Req | Código (na época) | Conformidade |
|---|---|---|---|
| 15 clãs com cores hex | ✅ 15 cores | ✅ 15 cores OK | 100% |
| 8 raridades | ✅ 8 raridades | ✅ 8 raridades | 100% |
| 77 packs | ✅ 77 packs | ✅ 77 packs | 100% |
| 15 Divinas com nomes | ✅ 15 nomes v3 | ✅ 15 nomes | 100% |
| Tiers C/B/A | ✅ Módulo Tiers | ✅ Tiers.lua | 100% (removido depois) |
| seedValue × mult economia | ✅ Fórmula | ✅ Fórmula | 100% |

**Status Global (em 19/07/2026):** 🟢 **COMPLIANCE v3: 100%** (arquivos de dados puros)

## ✅ Checklist Pós-Auditoria (estado em 19/07/2026)

- [x] Cores dos clãs corrigidas
- [x] Criatura Divina (Raijin) corrigida
- [x] Custo Despertar Divino corrigido
- [x] Tiers.lua criado
- [x] PackCatalog expandido para 77 packs
- [ ] Validação de tipos Luau executada
- [ ] Referências cruzadas testadas
- [ ] WheelService/DailyBlessingService/JourneyChestService migrados
- [ ] MarketplaceService dispatcher combinado
- [ ] Game designer (Paola) revisa e aprova

---

# Parte 3 — Próximos Passos — Pós-Auditoria v3

**Status (em 19/07/2026):** Todos os 5 problemas críticos resolvidos ✅
**Próxima fase:** Validação + Migrações de serviços

## Fase 1: Validação de Tipos (Bloqueador)

```bash
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --sourcemap=sourcemap.json --platform=roblox src/shared/Data/
```

## Fase 2: Migrações de Serviços (Bloqueador de Funcionalidade)

WheelService/DailyBlessingService/JourneyChestService chamavam
`PackService.GrantFreePack(player, packId)` com IDs do modelo antigo
(tier+clã); precisam migrar pra `Key` string válida do catálogo novo
(mapeamento exemplo: ID 1→"Novato", ID 2→"Recruta", ID 5→"Andarilho", ID
30→"Transcendente"). `MarketplaceService.ProcessReceipt` precisa de um
dispatcher único combinando `PackService` + `GamepassService` (Solução A:
guard-check inline; Solução B: módulo `ReceiptDispatcher.lua` separado —
recomendado A primeiro, refatorar pra B depois).

## Fase 3: Integração de Tiers em Creatures

Verificar/adicionar campo `tier` em todas as 300 criaturas (distribuição
esperada 150 C / 105 B / 45 A).

## Fase 4: Atualizar PackOddsRoller.lua

Integrar `Tiers.lua`, sortear clã uniforme + tier (odds do pack) + criatura
dentro do tier/clã.

## Fase 5: Testes de Integração (manual, Studio)

Abrir "Novato", "Ordem Celestial" (pack de clã), "Fragmento" (diamante);
verificar fórmula $/s; testar Wheel/DailyBlessing `GrantFreePack`.

## 📊 Estimativa de Tempo Total

| Fase | Descrição | Tempo |
|---|---|---|
| **T1** | Validação de Tipos | 5 min |
| **T2** | Migrações de Serviços | 1.5-2 hrs |
| **T3** | Integração de Tiers | 0.5-2 hrs |
| **T4** | PackOddsRoller | 20 min |
| **T5** | Testes de Integração | 1-2 hrs |
| **TOTAL** | — | **3.5-6.5 hrs** |

## 💬 Perguntas para Paola (Pendentes em 19/07/2026)

- Sacrifício no Altar não paga $ (é correto ou deveria dar 20% como venda)?
- Parâmetros da curva convexa de Renascimento (BASE, GROWTH, CONVEXITY) — os valores propostos estão OK?
- Auto-venda pós-Mítico: descartar cópias extras (OPTION B) ou vender por 20% (OPTION A)?
- Mochila cheia + descoberta nova ao abrir pacote: UX final (bloquear compra, oferecer expansão, etc.)?

*(Estas mesmas perguntas seguem em aberto em 12/09/2026 — ver `CLAUDE.md`, seção "Decisões ainda pendentes".)*
