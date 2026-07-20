# Próximos Passos — Pós-Auditoria v3

**Status:** Todos os 5 problemas críticos resolvidos ✅  
**Próxima fase:** Validação + Migrações de serviços  
**Urgência:** 🔴 ALTA (migrações bloqueiam funcionalidade)

---

## 📋 Checklist de Tarefas

### 🔴 Fase 1: Validação de Tipos (Bloqueador)

**Por quê:** PackCatalog foi reescrito, Tiers.lua é novo. Precisa garantir que todo o Luau compila sem erros.

- [ ] **T1.1** — Gerar sourcemap do projeto
  ```bash
  rojo sourcemap default.project.json -o sourcemap.json
  ```
  **Tempo:** ~30 segundos

- [ ] **T1.2** — Rodar análise de tipos via luau-lsp
  ```bash
  luau-lsp analyze --sourcemap=sourcemap.json --platform=roblox src/shared/Data/
  ```
  **Tempo:** ~1-2 minutos  
  **Esperado:** 0 erros (ou listar e corrigir)

- [ ] **T1.3** — Validar imports cruzados
  - PackService.lua lê PackCatalog ✓
  - PackOddsRoller.lua lê Tiers.lua ✓
  - EconomyService.lua lê Rarities + Creatures ✓

**Total T1:** ~5 minutos

---

### 🔴 Fase 2: Migrações de Serviços (Bloqueador de Funcionalidade)

**Por quê:** WheelService, DailyBlessingService, JourneyChestService chamam GrantFreePack com IDs do modelo antigo. Sem migração, **packs grátis não funcionam**.

#### T2.1 — WheelService.lua

**Arquivo:** `src/server/Systems/WheelService.lua`

**O quê:** Encontrar todas as chamadas de `PackService.GrantFreePack` e atualizar IDs → Keys

**Como:**
1. Grep por `GrantFreePack` no arquivo
2. Exemplo de ERRO:
   ```lua
   PackService.GrantFreePack(player, 5)  -- ❌ ID 5 não existe mais no novo catálogo
   ```
3. Mudar pra Key válida:
   ```lua
   PackService.GrantFreePack(player, "Andarilho")  -- ✅ ID 5 do catálogo = Key "Andarilho"
   ```

**Mapeamento útil (Ladder Geral):**
- ID 1 → "Novato"
- ID 2 → "Recruta"
- ID 5 → "Andarilho"
- ID 30 → "Transcendente"
- (ver tabela completa em PackCatalog.lua linhas 1-30)

**Tempo:** ~15 minutos

---

#### T2.2 — DailyBlessingService.lua

**Arquivo:** `src/server/Systems/DailyBlessingService.lua`

**O quê:** Migrar GrantFreePack IDs → Keys (mesma coisa que T2.1)

**Nota:** Bênção Diária deve usar `PackCatalog.BencaoDiaria` (Key = "BencaoDiaria"), não ID numérico.

**Tempo:** ~15 minutos

---

#### T2.3 — JourneyChestService.lua

**Arquivo:** `src/server/Systems/JourneyChestService.lua`

**O quê:** Migrar GrantFreePack IDs → Keys (mesma coisa que T2.1)

**Tempo:** ~15 minutos

---

#### T2.4 — MarketplaceService.ProcessReceipt Dispatcher

**Arquivo:** Precisa de novo módulo ou refactoring em PackService.lua + GamepassService.lua

**O quê:** Atualmente existem 2 `ProcessReceipt` callbacks:
- PackService.lua (compra de Robux de pacotes)
- GamepassService.lua (compra de gamepasses)

Quando Main.lua carrega ambos, o último sobrescreve o primeiro. **Resultado:** compras Robux de pacotes nunca são processadas.

**Solução A (Simples):** Criar função dispatcher que checa tipo do produto:
```lua
-- Em PackService.lua, no lugar de atribuir direto:
if not MarketplaceService.ProcessReceipt then
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		-- Determina se é pack ou gamepass
		-- Delega ao serviço correto
		-- Retorna true/false
	end
end
```

**Solução B (Robusto):** Criar módulo `ReceiptDispatcher.lua` que PackService + GamepassService compartilham.

**Tempo:** ~30 minutos (A) / ~1 hora (B)

**Recomendação:** Usar Solução A agora, refactor pra B se crescer.

---

**Total T2:** ~1,5-2 horas

---

### 🟡 Fase 3: Integração de Tiers em Creatures (Médio)

**Por quê:** Creatures.lua menciona "tier" nas descrições/comments, mas pode não ter campo estruturado.

- [ ] **T3.1** — Verificar se Creatures.lua tem campo `tier` em cada entrada
  ```lua
  Creatures[1] = {
    id = 1,
    name = "...",
    tier = "C",  -- ← Isso existe?
    ...
  }
  ```

- [ ] **T3.2** — Se não tem, adicionar campo `tier` a todas as 300 criaturas
  - Distribuição esperada: 150 C, 105 B, 45 A (10+7+3 por clã)
  - Pode ser automatizado via script Lua ou Excel antes de copiar

**Tempo:** ~30 minutos (se já tem) / ~1-2 horas (se precisa adicionar)

---

### 🟡 Fase 4: Atualizar PackOddsRoller.lua (Médio)

**Por quê:** PackOddsRoller precisa usar Tiers.lua para sortear tier + criatura corretamente.

- [ ] **T4.1** — Adicionar `local Tiers = require(...Tiers.lua)`

- [ ] **T4.2** — Verificar se função `sortRarity` ainda existe (pode ter mudado com v3)

- [ ] **T4.3** — Garantir que sorteia:
  1. Clã uniforme (15 clãs)
  2. Tier conforme odds do pack (% C/B/A)
  3. Criatura dentro tier do clã

**Tempo:** ~20 minutos

---

### 🟢 Fase 5: Testes de Integração (Baixo, Manual)

Depois que Fases 1-4 terminarem:

- [ ] **T5.1** — Abrir Studio, inicializar servidor
- [ ] **T5.2** — Testar fluxo de abertura de pack:
  - Abrir "Novato" (Ladder Geral) → vira Default, sorteia criatura aleatória
  - Abrir "Ordem Celestial" (Pack Clã) → Default, só Tier C/B, só clã Ordem Celestial
  - Abrir "Fragmento" (Diamante) → abre 3 criaturas
- [ ] **T5.3** — Verificar economia: $/s de uma criatura = `seedValue × tierMult × rarityMult × grauMult × renascMult`
- [ ] **T5.4** — Testar Roda do Destino, Bênção Diária → GrantFreePack funciona

**Tempo:** ~1 hora (se sem bugs) / ~2+ horas (se bugs encontrados)

---

## 📊 Estimativa de Tempo Total

| Fase | Descrição | Tempo |
|---|---|---|
| **T1** | Validação de Tipos | 5 min |
| **T2** | Migrações de Serviços | 1.5-2 hrs |
| **T3** | Integração de Tiers | 0.5-2 hrs |
| **T4** | PackOddsRoller | 20 min |
| **T5** | Testes de Integração | 1-2 hrs |
| **TOTAL** | — | **3.5-6.5 hrs** |

**Recomendação:** Bloquear 1 dia de trabalho. Fases T1-T2 são críticas (bloqueiam resto).

---

## 🎯 Ordem de Execução (Recomendada)

```
1. T1.1 + T1.2 + T1.3  (Validação)
   ↓
2. T2.1 + T2.2 + T2.3  (Migrações PackService)
   ↓
3. T2.4                 (MarketplaceService dispatcher)
   ↓
4. T3.1 + T3.2         (Tiers em Creatures)
   ↓
5. T4.1 + T4.2 + T4.3  (PackOddsRoller)
   ↓
6. T5 (Testes)         (Validar tudo no Studio)
```

**Pontos de risco:**
- Após T1: se tem erros de tipo, parar e corrigir antes de continuar
- Após T2: testar GrantFreePack de verdade (emular Roda do Destino)
- Após T4: testar sorteio de Tier (abrir pack, verificar tier da criatura)

---

## 🔗 Documentos de Referência

Leia estes em ordem:

1. **GAME_DESIGN_CARTAS_MITICAS_v3.md** — Source of truth do design
2. **RELATÓRIO_AUDITORIA_v3.md** — Achados completos da auditoria
3. **RESUMO_FIXES_APLICADOS.md** — O que foi corrigido
4. **Este documento** — O que falta fazer

---

## 💬 Perguntas para Paola (Pendentes)

Antes de finalizar Fase 5, confirmar com a Paola:

- [ ] **Decisão 1:** Sacrifício no Altar não paga $ (é correto ou deveria dar 20% como venda)?
- [ ] **Decisão 2:** Parâmetros da curva convexa de Renascimento (BASE, GROWTH, CONVEXITY) — os valores propostos estão OK?
- [ ] **Decisão 3:** Auto-venda pós-Mítico: descartar cópias extras (OPTION B) ou vender por 20% (OPTION A)?
- [ ] **Decisão 4:** Mochila cheia + descoberta nova ao abrir pacote: UX final (bloquear compra, oferecer expansão, etc.)?

---

## 📌 Não Esquecer

- **Backup:** Git commit após cada fase principal
- **Type checking:** Rodar `rojo sourcemap` sempre que editar Tiers.lua ou PackCatalog.lua
- **Teste de regressão:** Após cada migração, rodar servidor em Studio
- **Comunicação:** Avisar Paola se encontrar bugs ou inconsistências

---

## ✅ Checklist Final (para fechar auditoria)

- [ ] Todos os 5 fixes críticos aplicados (TEM OS ARQUIVOS ATUALIZADOS AQUI)
- [ ] Tiers.lua criado e compilando
- [ ] PackCatalog.lua com 77 packs, sem erros de tipo
- [ ] Todas as 4 migrações de serviços completadas (T2.1-2.4)
- [ ] Testes básicos passando no Studio
- [ ] Paola revisa e aprova conformidade com v3
- [ ] CHANGELOG.md atualizado
- [ ] Relatório final enviado pro repositório

---

**Próximo passo:** Executar Fase 1 (Validação de Tipos) — leva 5 minutos.

**Blocker:** Se T1 falhar, parar e debugar antes de continuar.

---

*Gerado: 2026-07-19 · Auditoria Completa do Game Design v3*
