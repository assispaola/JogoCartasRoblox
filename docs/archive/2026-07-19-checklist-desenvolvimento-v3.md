# Arquivo histórico — Checklist de Desenvolvimento v3 (19/07/2026)

> **Isto é um registro histórico, não uma spec atual.** Movido de
> `docs/CHECKLIST_DESENVOLVIMENTO_v3_CORRIGIDO.md` pra `docs/archive/` em
> 12/09/2026. É um checklist de progresso datado de uma sessão específica —
> a "Fonte de Verdade" que ele cita (`/mnt/user-data/uploads/...`) é um
> caminho de sandbox de sessão de chat com upload, não algo do repositório,
> o que confirma que isto nunca foi pensado como algo a manter sincronizado
> indefinidamente. Vários itens marcados `[x]` aqui (Tiers.lua, fórmula com
> `multTier`, `data.backpack`/`data.baseSlots`/`data.balance` em inglês)
> **não refletem o código atual** — ver `CLAUDE.md` pro estado real.
> Conteúdo original preservado abaixo sem edição.

---

# 🎯 CHECKLIST DE DESENVOLVIMENTO — Cartas Míticas v3 (CORRIGIDO)

**Data de Atualização**: 19 de Julho de 2026
**Status**: ✅ Reconciliado com GAME_DESIGN_CARTAS_MITICAS_v3.md (real)
**Fonte de Verdade**: `/mnt/user-data/uploads/GAME_DESIGN_CARTAS_MITICAS_v3.md`
**Modelo**: Task-based com status de bloqueadores

## 📋 CONVENÇÕES

- ✅ = Completo e testado
- 🔄 = Em progresso ou requer revisão
- ⏳ = Bloqueado (aguardando decisão/outro componente)
- ⚠️ = Bug ou reconciliação pendente
- 🔴 = Não iniciado
- 📌 = Crítico para MVP
- 🎨 = Requer arte/design

## FASE 0 — Pré-produção ✅

- [x] Conceito do jogo e loop principal definidos
- [x] 15 clãs definidos com elementos
- [x] 300 criaturas base catalogadas (20 por clã, em Tiers C/B/A)
- [x] 15 criaturas divinas definidas (1 por clã, raridade própria)
- [x] **Sistema de Raridade (8 níveis)** documentado
- [x] **Sistema de Tiers (C/B/A)** definido
- [x] **77 pacotes** estruturados (30 Ladder + 15 Clã + 6 Diamante + 9 Robux + 15 Eventos)
- [x] Planilha mestre atualizada com UI Style Guide integrado

## FASE 1 — Fundação Técnica ✅

### Infraestrutura
- [x] Instalar Roblox Studio, Rojo, VS Code
- [x] Estruturar pastas do projeto
- [x] Configurar sincronização Rojo
- [x] Criar repositório Git
- [x] Importar dados da planilha como módulos Luau

### Módulos Essenciais
- [x] `Clans.lua` — 15 clãs com cores, elementos, vantagens
- [x] `Creatures.lua` — 300 criaturas base (Tier C/B/A por clã)
- [x] `DivineCreatures.lua` — 15 divinas (1 por clã, seedValue 10.000)
- [x] `Rarities.lua` — 8 raridades com thresholds e multiplicadores
- [x] `Tiers.lua` — C/B/A com seedValue e distribuição

### Data Persistence
- [x] DataStore implementado com PlayerDataService
- [x] `data.album` (total de copias por criatura)
- [x] `data.backpack` (criaturas na mochila, até 200)
- [x] `data.baseSlots` (criaturas equipadas)
- [x] `data.balance` (dinheiro, diamante, multiplicador renascimento)
- [x] Migration v2→v3 (atalho removido, sistema de tiers integrado)

## FASE 2 — Sistemas Centrais (Core Loop)

### 💰 Economia
- [x] Sistema de moeda (Coins, Diamantes, Robux rastreados)
- [x] Coleta manual de renda por slot (com gamepass de automático)
- [x] **Fórmula de valor v3:** `seedValue × 1.000 × multRaridade × multTier × multGrau × multRenascimento`
  - `seedValue` = valor base da criatura (C=×1, B=×4, A=×15)
  - `multRaridade` = Default 0.4 → Mítico 500 → Divino 10.000
  - `multTier` = inerente ao seedValue
  - `multGrau` = 1.0 (vazio) até 2.5 (10.0)
  - `multRenascimento` = 1.0 × (1.1 ^ ciclo)
- [x] Renda offline calculada (90 minutos de limite padrão)
- [x] Salvamento persistente em DataStore
- ⏳ **Pendente:** Testar fórmula com valores reais em Roblox Studio

### 📖 Álbum (Raridade Contínua)
- [x] AlbumService.lua — rastreia `totalCopias` por criatura
- [x] **Raridade = RarityForTotalCopias(totalCopias)**
  - Default: ≥0 (mult ×0.4) · Bronze: ≥5 (×1) · Prata: ≥15 (×6) · Ouro: ≥30 (×18)
  - Platina: ≥55 (×50) · Lendário: ≥90 (×150) · Mítico: ≥140 (×500, teto) · Divino: N/A (×10.000, fixo)
- [x] Cálculo **em tempo real** — raridade nunca armazenada separadamente
- [x] Índice de descoberta (Diamante por 1ª criatura de cada)
- [x] `data.album` schema validado

### 🎴 Pacotes (Sistema v3 — 77 Total)

**Ladder Geral (30):** desbloqueio +1 pack a cada 2 ciclos, preços em curva
exponencial (~1.5x), raridade sempre Default, Tier progride C→B→A conforme
o pacote sobe (#1-3 100% C · #4-9 70C/30B · #10-16 50/50 · #17-19
20C/70B/10A · #26-30 5C/60B/35A).

**Packs de Clã (15):** 1 por clã, sempre disponível, preço = Ladder máximo
do ciclo × 2, Tier C+B (sem A), moeda $, raridade sempre Default.

**Diamante (6):** recargas de 💎 (10/25/50/100/250/500), sem criaturas.

**Robux (9):** monetização real, mix de criaturas + 💎 (pode ter raridade
alta), 9 variações.

**Especiais/Eventos (15):** Seasonal/Daily/Journey/Bênção, Portal Divino
(acessa Divinas), variações temáticas por clã.

- [x] **77 PackCatalog.lua** definido, PackService.lua, PackOddsRoller.lua
- [x] **Atalho removido** — todo pacote +1 cópia apenas
- ⏳ WheelService/DailyBlessingService/JourneyChestService migrar pra Key string válida
- ⏳ dispatcher único pra MarketplaceService.ProcessReceipt
- ⏳ 9 RobuxProductId reais no Creator Dashboard

### 😴 Despertar (Grau)
- [x] Escala de 8 graus (vazio + 7.0 até 10.0), multiplicadores 1.0/1.05/1.15/1.30/1.50/1.75/2.10/2.50
- [x] RollDespertar por creatureId, AlbumService.RollDespertar integrado
- [x] Diamante cost progressivo por raridade
- [x] Safety rule: awakened card não supera base value do próximo nível

### 🎒 Inventário (Camadas)
- [x] Slots de Base (3+, renda passiva $/s), Mochila (200 cap, 1 obj = 1 criatura), Álbum (totalCopias, nunca perdido), Mão (10 slots)
- [x] Drag-drop integrado
- ✅ Mochila reseta no Renascimento — Álbum persiste
- ⏳ Pendente (Paola): capacidade Slots de Base escala? (+1 cada 2 ciclos?)

### 🌦️ Portal da Sorte / 🎡 Roda do Destino / 🙏 Bênção Diária / 🧳 Baús da Jornada
- [x] Todos implementados (PortalService, WheelService, DailyBlessingService, JourneyChestService)

### ♻️ Renascimento + Altar de Sacrifício
- [x] 3 requisitos simultâneos (3 criaturas de 1 clã sorteado, 1 cópia de criatura específica fixa, saldo mínimo de Dinheiro)
- [x] Fluxo completo (staging → confirma → consome → reset Dinheiro → Nível/Álbum persistem → Mochila reseta → multiplicador +10%)
- [x] AltarSacrificioService.lua, RenascimentoService.lua implementados
- ⏳ Pendente (Paola): validar parâmetros exatos de $ mínimo curva

### 💳 Venda de Cartas (REMOVIDA)
- ✅ Venda manual REMOVIDA completamente (v3) — *nota 12/09/2026: código atual TEM venda manual ativa (`SellService.VenderCopias`), este item não reflete o estado real.*
- ✅ Auto-venda pós-Mítico apenas
- ✅ Dinheiro não é fonte primária (Slots geram $/s)

### 🤝 Pacto dos Guardiões / 🛒 Gamepasses + Dev Products / 📊 Nível / 🧪 Cooldown
- [x] Doação + Troca bilateral implementadas
- [x] 9 Gamepasses, 4 Dev Products, GamepassCatalog/Service
- [x] XP substituído por Desafios, ChallengesCatalog com 59 níveis
- [x] Cooldown de compra implementado

## FASE 3 — Arte Inicial 🎨

Direção "semi-realista neon painting", paleta de 15 cores de clã validada.
300 criaturas distribuídas por Tier (150 C / 105 B / 45 A) — 4 clãs 100%
prontos, 2 em ajuste, 9 não iniciados. 15 Divinas definidas, arte pendente.
77 pacotes com prompts prontos, poucas artes testadas/aprovadas. Ícones e
efeitos majoritariamente pendentes.

## FASE 4 — UI/Telas

Ver `UI_TELAS_DESENVOLVIMENTO.md`. 11+ telas planejadas, nenhuma marcada
como pronta neste checklist (todas 🔴 na época).

## FASE 5 — Testes Internos / FASE 6-7 — Battle System / FASE 8 — Monetização Avançada / FASE 9 — Polish / FASE 10 — Beta / FASE 11-13 — Lançamento

Todas ainda não iniciadas na época deste checklist (unit tests, PvE, PvP
assíncrono, áudio, localização, acessibilidade, beta fechado, lançamento).

## 🚨 CORTES DE ESCOPO

**Prioridade (do menos crítico ao mais):** PvP Assíncrono (pós-launch) ·
Pacto/Troca bilateral (manter só doação pré-launch) · Portal variações
(lançar com 2-3) · Gamepasses de sorte (lançar só VIP+Coleta) ·
**Renascimento + Altar (pode ser update pós-launch)**.

**Nunca cortar:** DataStore/Persistência, loop econômico, 77 Pacotes,
Despertar, Raridade contínua (8 níveis), Tiers C/B/A, HUD/UI básica, 315
criaturas (300+15 Divinas).

## 📊 MÉTRICAS DE LANÇAMENTO

| Métrica | Target |
|---------|--------|
| Usuários simultâneos | 50+ |
| Tempo de sessão médio | 15-30 min |
| Retenção D1 | 30%+ |
| Retenção D7 | 15%+ |
| ARPU (30d) | $0.50+ |
| Taxa de crash | <0.1% |
| Tempo de load | <3s |

## 🎯 TIMELINE ESTIMADA (na época)

| Marco | Data | Entregáveis |
|-------|------|------------|
| **MVP Alpha** | Sem 2 | Core loop playable, 5 clãs |
| **Closed Beta** | Sem 4 | 15 clãs, todas telas, sem art perfeita |
| **Balance Pass** | Sem 6 | Tuning de drop rates, preços |
| **Polish Beta** | Sem 7 | UI completa, sons, animações |
| **Soft Launch** | Sem 8 | Pronto público limitado |
| **Public Launch** | Sem 9-10 | Go live |

## 🎯 DIFERENÇAS v2 → v3

| Aspecto | v2 | v3 |
|--------|----|----|
| **Pacotes** | 62 | **77** |
| **Raridades** | 7 | **8** |
| **Estrutura Packs** | Tier+Moeda | **Tier (C/B/A) + Moeda** |
| **Atalho** | Sim (sorteio raridade alta) | **Removido** |
| **Mochila no Renascimento** | Persiste | **Reseta** |
| **Venda** | Manual (20% valor) | **Removida (auto só pós-Mítico)** |
| **Criaturas** | 300 | **315 (300+15 Divinas)** |
| **Packs de Clã** | Não existe | **15 packs (1 por clã)** |
| **Multiplicador Renascimento** | +5% | **+10%** |

---

**Gerado em:** 19 de Julho de 2026
**Versão:** 3.0 CORRIGIDA
**Próxima revisão:** Quando fases completarem
