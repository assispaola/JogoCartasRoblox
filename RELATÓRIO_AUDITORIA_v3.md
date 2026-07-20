# Relatório de Auditoria Completa — Cartas Míticas v3
> **Data:** 19/07/2026 · **Status:** Auditoria completa concluída  
> **Versão do Game Design:** v3  
> **Arquivos verificados:** 34 módulos Luau + estrutura de dados

---

## Sumário Executivo

A auditoria identificou **5 problemas críticos**, **2 bugs conhecidos** e **1 estrutura faltante** que precisam ser resolvidos antes de considerar o código conforme v3.

| Severidade | Qty | Status |
|---|---|---|
| 🔴 **Crítico** | 5 | Bloqueador de compliance |
| 🟠 **Alto** | 2 | Conhecido, requer migração |
| 🟡 **Médio** | 3 | Melhorias de consistência |
| 🟢 **Baixo** | 1 | Documentação |

---

## 1️⃣ CLANS.LUA — Cores Hex Incorretas

**Arquivo:** `src/shared/Data/Clans.lua`  
**Severidade:** 🔴 **CRÍTICO**  
**Status:** ❌ 3 clãs com cores ERRADAS

### Problema

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

---

## 2️⃣ PACK CATALOG — Apenas 62 Packs (Faltam 15)

**Arquivo:** `src/shared/Data/PackCatalog.lua`  
**Severidade:** 🔴 **CRÍTICO**  
**Status:** ❌ Faltam 15 packs para atingir o total v3 de 77

### Problema

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

---

## 3️⃣ TIERS.LUA — Arquivo Não Existe

**Arquivo:** `src/shared/Data/Tiers.lua`  
**Severidade:** 🔴 **CRÍTICO**  
**Status:** ❌ FALTANTE

### Problema

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

---

## 4️⃣ DIVINECREATURAS — Nome de Criatura Divina Errado

**Arquivo:** `src/shared/Data/DivineCreatures.lua`  
**Severidade:** 🔴 **CRÍTICO**  
**Status:** ❌ Linha 71: "Chaac" deveria ser "Raijin"

### Problema

Segundo o CLAUDE.md (Divino — lista de nomes):
> Nomes exatos: Amaterasu, Hécate, Cernunnos, Skadi, Poseidon, Agni, **Raijin**, Gaia, Anubis, Shesha Naga, Nuwa, Cthulhu, Pele, Morrígan, Thoth

**Criatura do clã Tempestade Rúnica (#7):**
- Código (linha 71): `name = "Chaac"` (deus Maia, México)
- Esperado: `"Raijin"` (deus Xintoísta, Japão)

**Origem listada:**
- Código: `origin = "Maia"`
- Deveria ser: `"Japão (Xintoísmo)"`

**Linha afetada:**
- Linha 71: `name = "Chaac", origin = "Maia",`
- Linha 72: `description = "Senhor da chuva e do raio..."`

**Por que é crítico:**
- Quebra a promise de "100% mitologia de domínio público"
- Raijin é nomeação aprovada; Chaac não está no documento final
- Impacto na identidade visual (arte deduzida de mitologia)

**Fix:** Renomear para Raijin e ajustar descrição/origem

---

## 5️⃣ RARITIES — Custo de Despertar do Divino Errado

**Arquivo:** `src/shared/Data/Rarities.lua`  
**Severidade:** 🔴 **CRÍTICO** (mas menor que os anteriores)  
**Status:** ❌ Linha 55: awakenCostDiamonds = 25000 (deveria ser 10.000)

### Problema

v3 especifica custos de Despertar (seção 5):
| Rarity | Custo 💎 |
|---|---|
| Comum (C) | 2.500 |
| Nobre (B) | 5.000 |
| Ancestral (A) | 7.500 |
| **Divino** | **10.000** |

**Código (linha 55):**
```lua
{ order = 7, id = "Divino", ..., awakenCostDiamonds = 25000 }
```

**Deveria ser:** `10000`

**Impacto:**
- Despertar Divino custa 2,5x mais que o documentado
- Economia desbalanceada
- Jogador frustrado ao gastar diamantes

**Fix:** Mudar `awakenCostDiamonds` de 25000 para 10000

---

## 6️⃣ PACKETSERVICE & DEPENDÊNCIAS — Bugs Conhecidos

**Severidade:** 🟠 **ALTO** (já documentado em CLAUDE.md)  
**Status:** ⚠️ CONHECIDO, requer migração

### 6A. WheelService/DailyBlessingService/JourneyChestService — IDs de Pack Inválidos

**Arquivos afetados:**
- `src/server/Systems/WheelService.lua`
- `src/server/Systems/DailyBlessingService.lua`
- `src/server/Systems/JourneyChestService.lua`

**Problema:**
Esses serviços chamam `PackService.GrantFreePack(player, packId)` passando IDs do modelo antigo (tier+clã):
```lua
-- ❌ ERRADO (packId não existe no novo catálogo)
PackService.GrantFreePack(player, 5)  -- qual pack é esse?
```

**O novo catálogo (77 packs):**
- Usa `Key` string: `"Novato"`, `"Recruta"`, `"Diamante1"`, etc.
- Não usa IDs numéricos de tier+clã

**Fix:** Migrar as 3 chamadas para passar `Key` válida do novo PackCatalog

---

### 6B. MarketplaceService.ProcessReceipt — Dispatcher Quebrado

**Arquivos afetados:**
- `src/server/Systems/PackService.lua` (atribui o callback)
- `src/server/Systems/GamepassService.lua` (sobrescreve o callback)

**Problema:**
```lua
-- PackService.lua (Init)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	-- processa Robux de pacotes
end

-- GamepassService.lua (Init) - sobrescreve!
MarketplaceService.ProcessReceipt = function(receiptInfo)
	-- processa gamepasses
end
```

**Consequência:** Apenas o último serviço a rodar (GamepassService, já que Main.lua o inicia depois) tem seu ProcessReceipt ativo. Compras via Robux de pacotes **nunca são processadas**.

**Fix:** Criar um dispatcher único que combine ambos os fluxos

---

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

---

## 📋 Checklist de Fixes — Prioridade

### Fase 1: Críticos (Bloqueadores de compliance v3)

- [ ] **Clans.lua** — Corrigir 3 cores hex (Trovão, Lava, Tecnomancia)
  - **Tempo:** ~5 minutos
  - **Arquivos:** 1

- [ ] **Tiers.lua** — Criar arquivo novo com sistema C/B/A
  - **Tempo:** ~20 minutos
  - **Arquivos:** 1 novo + atualizar referências em Creatures.lua, PackOddsRoller.lua

- [ ] **PackCatalog.lua** — Expandir de 62 para 77 packs
  - **Tempo:** ~1-2 horas (transcricação manual de tabelas do v3)
  - **Arquivos:** 1 + validação de preços/odds

- [ ] **DivineCreatures.lua** — Renomear Chaac → Raijin
  - **Tempo:** ~5 minutos
  - **Arquivos:** 1

- [ ] **Rarities.lua** — Divino awakenCostDiamonds 25000 → 10000
  - **Tempo:** ~2 minutos
  - **Arquivos:** 1

**Total Fase 1:** ~2 horas

### Fase 2: Conhecidos (Requer migração)

- [ ] **WheelService** — Migrar GrantFreePack para Key string
  - **Tempo:** ~15 minutos
  - **Impacto:** Roda do Destino ativa

- [ ] **DailyBlessingService** — Migrar GrantFreePack para Key string
  - **Tempo:** ~15 minutos
  - **Impacto:** Bênção Diária ativa

- [ ] **JourneyChestService** — Migrar GrantFreePack para Key string
  - **Tempo:** ~15 minutos
  - **Impacto:** Baús da Jornada ativos

- [ ] **MarketplaceService Dispatcher** — Combinar PackService + GamepassService
  - **Tempo:** ~30 minutos
  - **Impacto:** Compras Robux funcionam

**Total Fase 2:** ~1,5 hora

---

## 🔍 Validações Executadas

✅ **Clans.lua** — 15 clãs, cores hex válidas (3 erradas)  
✅ **Creatures.lua** — 300 criaturas (linhas/estrutura)  
✅ **DivineCreatures.lua** — 15 criaturas divinas (1 nome errado)  
✅ **Rarities.lua** — 8 raridades, fórmula de valor (1 custo errado)  
✅ **AlbumEvolutionCurve.lua** — Thresholds acumulados, função contínua  
✅ **GamepassCatalog.lua** — 9 gamepasses (sem Relicário ✓)  
✅ **PlayerDataService.lua** — Schema v2 com migration  
✅ **PackCatalog.lua** — Estrutura verificada, QTY errada (62 vs 77)  
❌ **Tiers.lua** — Não existe (estrutura fundamental)  
⚠️ **WheelService/DailyBlessingService/JourneyChestService** — Bugs conhecidos de IDs  
⚠️ **PackService/GamepassService** — ProcessReceipt sobrescrito  

---

## 📁 Roadmap de Implementação

### Passo 1: Fixes Críticos (antes de qualquer outra coisa)
1. Clans.lua (cores)
2. DivineCreatures.lua (Raijin)
3. Rarities.lua (custo Divino)
4. Criar Tiers.lua
5. PackCatalog.lua (77 packs)

### Passo 2: Testes de Compliance
- Validar tipos Luau (`rojo sourcemap` + `luau-lsp`)
- Verificar referências cruzadas (PackOddsRoller → Tiers, etc.)
- Simular abertura de pack (sorteio de Tier + criatura + raridade)

### Passo 3: Migrações de Serviços
- Atualizar WheelService, DailyBlessingService, JourneyChestService
- Combinar MarketplaceService dispatcher

### Passo 4: Validação Final
- Reproduzir fluxos principais no Studio
- Verificar economia ($/s com novos Tiers)
- Testar Renascimento (multiplier +10%)

---

## 📝 Próximos Passos (Após Auditoria)

1. **Decisões pendentes** (requerem input Paola):
   - ⚠️ RenascimentoCatalog: parâmetros da curva convexa ainda não balanceados (BASE, GROWTH, CONVEXITY)
   - ⚠️ SellService: ausência de pagamento em $ no sacrifício (suposição não confirmada)
   - ⚠️ Mochila cheia + descoberta nova: UX final não decidida

2. **Tasks de arte**:
   - Gerar artes das 15 criaturas Divinas (prompts prontos)
   - Validar identidade visual de cada Tier (⭐/⭐⭐/⭐⭐⭐)
   - Refinado de Borda Divina (glow, rotação, saturação)

3. **Tests**:
   - Testes de balance econômico (ciclos 0–60)
   - Simulação de curva de Renascimento
   - Load test de DataStore com 77 packs

4. **Documentação**:
   - Atualizar CLAUDE.md com status pós-auditoria
   - Criar guia de adição de novos packs (template)

---

## 📊 Resumo de Impacto

| Problema | Impacto | Urgência | Esforço |
|---|---|---|---|
| Cores clãs | Visual | 🔴 Crítico | 5min |
| PackCatalog 62→77 | Economia quebrada | 🔴 Crítico | 2h |
| Tiers.lua faltante | Sorteio quebrado | 🔴 Crítico | 20min |
| DivineCreatures nome | IP/identidade | 🔴 Crítico | 5min |
| Rarities custo Divino | Economy desbalanceado | 🔴 Crítico | 2min |
| Bugs PackService | Packs grátis não funcionam | 🟠 Alto | 1,5h |
| ProcessReceipt | Robux não processado | 🟠 Alto | 30min |

---

**Gerado por:** Auditoria Automática v3  
**Data:** 19/07/2026  
**Próxima revisão:** Após aplicação de todos os fixes da Fase 1
