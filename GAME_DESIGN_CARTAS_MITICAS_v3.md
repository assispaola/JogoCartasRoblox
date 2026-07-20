# Cartas Míticas — Documento Mestre de Game Design (v3)
> **Versão:** 3.0 · **Data:** Julho 2026 · **Status:** documento vivo  
> **Fonte de verdade:** `Cartas_Miticas_Clans_e_Criaturas.xlsx` + módulos Luau  
> **Convenção:** tudo em português

---

## Índice

1. [Visão Geral e Loop Principal](#1-visão-geral-e-loop-principal)
2. [Criaturas, Clãs e Tiers](#2-criaturas-clãs-e-tiers)
3. [Cores Oficiais dos 15 Clãs](#3-cores-oficiais-dos-15-clãs)
4. [Sistema de Raridade — Álbum e Função Contínua](#4-sistema-de-raridade--álbum-e-função-contínua)
5. [Sistema de Despertar (Grau)](#5-sistema-de-despertar-grau)
6. [Pacotes — Estrutura Geral](#6-pacotes--estrutura-geral)
7. [Ladder Geral (30 Packs)](#7-ladder-geral-30-packs)
8. [Packs de Clã (15 Packs)](#8-packs-de-clã-15-packs)
9. [Packs de Diamante (6 Packs)](#9-packs-de-diamante-6-packs)
10. [Packs de Robux (9) e Especiais (15)](#10-packs-de-robux-9-e-especiais-15)
11. [Cooldown Temporal de Compra](#11-cooldown-temporal-de-compra)
12. [Mochila e Slots de Base](#12-mochila-e-slots-de-base)
13. [Fluxo de Renascimento — Passo-a-Passo](#13-fluxo-de-renascimento--passo-a-passo)
14. [Economia — Renda Passiva](#14-economia--renda-passiva)
15. [Ganho de Diamante — Todas as Fontes](#15-ganho-de-diamante--todas-as-fontes)
16. [Auto-Venda Pós-Mítico](#16-auto-venda-pós-mítico)
17. [Altar de Sacrifício e Renascimento](#17-altar-de-sacrifício-e-renascimento)
18. [Ciclos de Renascimento — Progressão Completa](#18-ciclos-de-renascimento--progressão-completa)
19. [Sistemas de Engajamento Recorrente](#19-sistemas-de-engajamento-recorrente)
20. [Pacto dos Guardiões](#20-pacto-dos-guardiões)
21. [Portal da Sorte](#21-portal-da-sorte)
22. [Sistema de Nível e Desafios](#22-sistema-de-nível-e-desafios)
23. [Gamepasses e Monetização](#23-gamepasses-e-monetização)
24. [Identidade Visual e Arte](#24-identidade-visual-e-arte)
25. [UI — Estrutura de Telas](#25-ui--estrutura-de-telas)
26. [Arquitetura Técnica](#26-arquitetura-técnica)
27. [Roadmap de Desenvolvimento](#27-roadmap-de-desenvolvimento)
28. [Decisões Finais — v3](#28-decisões-finais--v3)

---

## 1. Visão Geral e Loop Principal

### O que é o jogo
Simulador incremental de cartas colecionáveis para Roblox. 100% original — mitologia real de domínio público de múltiplas culturas.

### Loop principal

```
Abrir Pacotes
      ↓
Acumular Cópias → Raridade sobe automaticamente
      ↓
Equipar nos Slots de Base → Geram $/s
      ↓
Renascer → Mochila reseta, Álbum persiste, +bônus permanente
```

### Linhas de progressão

| Linha | O que progride | Núcleo |
|---|---|---|
| **Econômica** | $/s, compra de packs, desbloqueio Ladder | Slots crescem, multiplicador sobe |
| **Coleção** | 315 criaturas no Álbum, raridade, Tier | Descobertas dão 💎, Álbum persiste sempre |
| **Slots** | Quantidade de cartas base aumenta | +1 slot a cada 2 ciclos |

---

## 2. Criaturas, Clãs e Tiers

### Estrutura total
- **300 criaturas base:** 20 por clã × 15 clãs
- **15 criaturas Divinas:** 1 por clã (raridade própria)
- **Total no Álbum:** 315 slots

### Sistema de Tiers — 3 níveis por clã

| Tier | Símbolo | Qtd | seedValue | Descrição |
|---|---|---|---|---|
| **C** | ⭐ Comum | 10 | ×1 | Entrada |
| **B** | ⭐⭐ Nobre | 7 | ×4 | Intermediário |
| **A** | ⭐⭐⭐ Ancestral | 3 | ×15 | Topo |

**Total:** 10 + 7 + 3 = 20 criaturas por clã.

### Criaturas Divinas
- 15 no total (1 por clã)
- **Não evoluem** — só existem em raridade Divino
- **Fonte exclusiva:** pacote Portal Divino (evento)
- Identidade visual **uniforme** (não herda cor do clã)
- seedValue: ×10.000 (fixo)

---

## 3. Cores Oficiais dos 15 Clãs

| # | Clã | Elemento | Cor (Hex) | Status |
|---|---|---|---|---|
| 1 | Ordem Celestial | Luz | `#F4D03F` | ✅ Aprovado |
| 2 | Véu Sombrio | Sombra | `#5B2C6F` | ✅ Aprovado |
| 3 | Fúria Selvagem | Natureza | `#27AE60` | ✅ Aprovado |
| 4 | Abismo Glacial | Gelo | `#AED6F1` | ✅ Aprovado |
| 5 | Maré Eterna | Água | `#0E5C52` | ✅ Aprovado |
| 6 | Forja Ígnea | Fogo | `#D30D0D` | ✅ Aprovado |
| 7 | Tempestade Rúnica | Trovão | `#FF99CA` | ✅ Aprovado |
| 8 | Rocha Ancestral | Terra | `#935116` | ✅ Aprovado |
| 9 | Areia Amaldiçoada | Morte | `#AFA88C` | ✅ Aprovado |
| 10 | Selva Esmeralda | Veneno | `#147B16` | ✅ Aprovado |
| 11 | Constelação Arcana | Astral | `#B23488` | ✅ Aprovado |
| 12 | Profundezas Abissais | Mar Profundo | `#231443` | ✅ Aprovado |
| 13 | Chama Vulcânica | Lava | `#3D0F17` | ✅ Aprovado |
| 14 | Névoa Espectral | Fantasma | `#AAB7B8` | ✅ Aprovado |
| 15 | Engrenagem Rúnica | Tecnomancia | `#DBF470` | ✅ Aprovado |

---

## 4. Sistema de Raridade — Álbum e Função Contínua

### Conceito central
Raridade é **sempre derivada em tempo real** de `totalCopias`. Nunca armazenada separadamente.

```
raridade_atual = RarityForTotalCopies(totalCopias_atual)
```

### As 8 raridades

| Raridade | Threshold | Multiplicador | Cor (Hex) |
|---|---|---|---|
| Default | ≥ 0 | ×0,4 | `#8a8fa8` (cinza) |
| Bronze | ≥ 5 | ×1 | `#C98A4B` |
| Prata | ≥ 15 | ×6 | `#E8ECF0` |
| Ouro | ≥ 30 | ×18 | `#FFE066` |
| Platina | ≥ 55 | ×50 | `#A5F3FC` |
| Lendário | ≥ 90 | ×150 | `#B983FF` |
| Mítico | ≥ 140 (teto) | ×500 | `#FF4D4D` |
| **Divino** | N/A | ×10.000 | `#F4D03F` |

### Fluxo de abertura de pacote — v3 (sem Atalho)

```
1. Sorteia criatura (uniforme: 15 clãs, depois 20 dentro clã)
2. Adiciona 1 cópia: totalCopias_novo = totalCopias_atual + 1
3. Recalcula raridade: raridade = RarityForTotalCopies(totalCopias_novo)
4. Se 1ª cópia: cria na Mochila + ganha 💎
   Se duplicata: só atualiza Álbum
```

**Mudança v2 → v3:** Sem Atalho. Todo pacote sempre retorna +1 cópia. Raridade é consequência natural da acumulação. A única coisa que diferencia packs é o Tier acessado (C/B/A).

---

## 5. Sistema de Despertar (Grau)

### Escala de grau

| Grau | Multiplicador | Chance |
|---|---|---|
| Vazio (0) | ×1,00 | — |
| 7,0 | ×1,05 | 36,5% |
| 7,5 | ×1,15 | 27,0% |
| 8,0 | ×1,25 | 18,0% |
| 8,5 | ×1,50 | 10,0% |
| 9,0 | ×2,00 | 5,0% |
| 9,5 | ×2,50 | 2,5% |
| 10,0 | ×3,00 | 1,0% |

### Custos de Despertar (Diamante)
- Comum (Tier C): 2.500 💎
- Nobre (Tier B): 5.000 💎
- Ancestral (Tier A): 7.500 💎
- Divino: 10.000 💎

### Regras
- 1 grau por criatura (fixo, não varia por cópia/raridade)
- Rolar substitui o grau atual (pode melhorar ou piorar)
- Persiste quando raridade muda
- **Persiste no Renascimento**

### Fórmula de valor

```
valorFinal = seedValue_tier × 1.000 × multRaridade × multGrau × multRenascimento
```

---

## 6. Pacotes — Estrutura Geral

### Regra universal
**Todo pacote sorteia entre os 15 clãs uniformemente.** Diferenças entre packs:
1. **Tier que acessa** (quais raridades vêm)
2. **Moeda** ($ / 💎 / Robux)
3. **Efeitos** (Diamante = +cópias, Robux = pode vir raridade alta, etc.)

### Total: 77 packs
- 30 Ladder Geral
- 15 Packs de Clã
- 6 Diamante
- 9 Robux
- 15 Especiais/Eventos

---

## 7. Ladder Geral (30 Packs)

### Desbloqueio progressivo

```
Ciclo 0: Pack #1
Ciclo 2: Packs #1-#2
Ciclo 4: Packs #1-#3
...
Ciclo 60: Packs #1-#31 (continua crescendo)
```

**Padrão:** +1 pack a cada 2 ciclos (infinito).

### Tabela completa: 30 Packs

| # | Nome | Preço ($) | % C | % B | % A | Raridade |
|---|---|---|---|---|---|---|
| 1 | Novato | 200 | 100% | — | — | Default |
| 2 | Recruta | 299 | 100% | — | — | Default |
| 3 | Aprendiz | 448 | 100% | — | — | Default |
| 4 | Errante | 672 | 70% | 30% | — | Default |
| 5 | Andarilho | 1.006 | 70% | 30% | — | Default |
| 6 | Explorador | 1.507 | 70% | 30% | — | Default |
| 7 | Caçador | 2.257 | 70% | 30% | — | Default |
| 8 | Rastreador | 3.380 | 70% | 30% | — | Default |
| 9 | Guerreiro | 5.062 | 70% | 30% | — | Default |
| 10 | Bravo | 7.585 | 50% | 50% | — | Default |
| 11 | Guardião | 11.359 | 50% | 50% | — | Default |
| 12 | Sentinela | 17.021 | 50% | 50% | — | Default |
| 13 | Vigia | 25.500 | 30% | 70% | — | Default |
| 14 | Campeão | 38.219 | 30% | 70% | — | Default |
| 15 | Herói | 57.265 | 30% | 70% | — | Default |
| 16 | Vencedor | 85.777 | 30% | 70% | — | Default |
| 17 | Mestre | 128.530 | 20% | 70% | 10% | Default |
| 18 | Especialista | 192.500 | 20% | 70% | 10% | Default |
| 19 | Perito | 288.298 | 20% | 70% | 10% | Default |
| 20 | Arauto | 432.000 | 10% | 70% | 20% | Default |
| 21 | Mensageiro | 647.400 | 10% | 70% | 20% | Default |
| 22 | Sábio | 970.000 | 10% | 70% | 20% | Default |
| 23 | Erudito | 1.453.000 | 10% | 70% | 20% | Default |
| 24 | Vidente | 2.177.450 | 10% | 70% | 20% | Default |
| 25 | Oráculo | 3.263.500 | 10% | 70% | 20% | Default |
| 26 | Profeta | 4.892.475 | 5% | 60% | 35% | Default |
| 27 | Visionário | 7.331.500 | 5% | 60% | 35% | Default |
| 28 | Avatar | 10.986.000 | 5% | 60% | 35% | Default |
| 29 | Ascendente | 16.463.750 | 5% | 60% | 35% | Default |
| 30 | Transcendente | 280.000.000.000 | — | 40% | 60% | Default |

**Todos retornam raridade Default sempre.** Diferença é o Tier.

---

## 8. Packs de Clã (15 Packs)

### Características
- 1 por clã (sempre disponível desde Ciclo 0)
- Clã fixo (jogador escolhe)
- Acessa: Tier C + B (sem Tier A)
- Raridade: sempre Default
- Moeda: $ (Dinheiro)

### Preço por Ciclo

```
preço_PackClã_ciclo = (preço do pack Ladder máximo do ciclo) × 2
```

| Ciclo | Ladder Máx | Preço Ladder | Pack Clã (×2) |
|---|---|---|---|
| 0 | #1 | $200 | **$400** |
| 2 | #2 | $299 | **$598** |
| 4 | #3 | $448 | **$896** |
| 8 | #5 | $1.006 | **$2.012** |
| 20 | #11 | $11.359 | **$22.718** |
| 60 | #31 | ~$419B | **~$838B** |

---

## 9. Packs de Diamante (6 Packs)

### Mecânica
Abre **3 criaturas**, jogador escolhe qual/quais ganham +cópias.

| # | Nome | Preço 💎 | Efeito |
|---|---|---|---|
| 1 | Fragmento | 600 | Abre 3, escolhe 1 para +1 cópia |
| 2 | Cristal | 1.200 | Abre 3, escolhe 1 para +2 cópias |
| 3 | Núcleo | 2.000 | Abre 3, todas 3 ganham +1 cópia |
| 4 | Prisma | 3.500 | Abre 3, escolhe 2 para +2 cópias cada |
| 5 | Coroa | 5.000 | Abre 3 (min Tier B), escolhe 1 para +1 |
| 6 | Ápice | 7.500 | Abre 3 (min Tier A), escolhe a A para +2 |

**Raridade:** Todos Default. Efeito é só +cópias e acesso a Tier melhor.

---

## 10. Packs de Robux (9) e Especiais (15)

### Robux (9)
- Melhores odds do jogo
- Alguns com raridade acima de Default (Platina+)
- Podem entregar múltiplas cartas
- Preços: R$ 99 até R$ 1.499

### Especiais/Eventos (15)
- "Daily Blessings" (pacote grátis diário, força Default) — ver seção 19
- "Portal Divino" — **ÚNICA fonte do Divino**
- Promo sazonais, marcos, eventos

---

## 11. Cooldown Temporal de Compra

**Intervalo fixo:** 3 minutos (todos os ciclos)

Fluxo:
1. Jogador abre 1-N packs (quantos quiser, respeitando $)
2. Timer: "Novos pacotes em 3:00"
3. Após 3min, pode comprar novamente

Gamepass "Abertura Rápida": –50% cooldown → 1:30

---

## 12. Mochila e Slots de Base

### Arquitetura

```
Álbum ────────── fonte da verdade (totalCopias, grau)
      ↓
Mochila ──────── 1 objeto por criatura descoberta
      ↓
Slots de Base ── onde geram $/s
```

### Mochila — RESETA no Renascimento

- 1 objeto por criatura descoberta (não por cópia)
- Capacidade base: 200
- Lê raridade/valor do Álbum em tempo real
- **IMPORTANTE:** Zera completamente ao renascer
  - Jogador precisa reorganizar antes de renascer
  - Qualquer carta na Mochila é perdida
  - Cartas nos Slots também são desalocadas (mas Álbum persiste)

### Slots de Base — CRESCEM a cada 2 ciclos

| Ciclo | Slots | Mudança |
|---|---|---|
| 0 | 3 | inicial |
| 2 | 4 | +1 |
| 4 | 5 | +1 |
| 6 | 6 | +1 |
| ... | ... | +1 a cada 2 ciclos |
| 60 | 33 | exponencial |

---

## 13. Fluxo de Renascimento — Passo-a-Passo

### ANTES de renascer

**Fase 1 — Preparação (5-10 min)**
```
1. Abrir Álbum
   → Revisar todas as 315 criaturas
   → Ver quais tem melhor valor $/s
   → Mental: "O que vou querer equipar depois?"

2. Abrir Mochila
   → Ver todas as criaturas descobertas
   → Decidir qual vender ou descartar
   → Lembrar: tudo aqui vai sumir no renascimento

3. Auto-Sell pós-Mítico (opcional)
   → Ver se alguma criatura chegou ao Mítico
   → Cópias extras serão auto-removidas

4. Desalocar Slots
   → Remover todas as cartas dos 3-33 Slots
   → Confirmação: "Tem certeza?"
   → Cartas volta pra... nada (Mochila vai resetar)
```

**Fase 2 — Requisitos do Altar (10-15 min)**
```
1. Ir pro Altar de Sacrifício

2. Requisito 1: sacrificar 3 do clã sorteado
   → Clã está exibido: ex "Maré Eterna"
   → Jogador escolhe qual 3 criaturas
   → Arrasta da Mochila pro Altar (staging)
   → Status: "1/3 sacrificadas"

3. Requisito 2: sacrificar 1 criatura fixa
   → Criatura está exibida: ex "Kitsune das Nove Caudas"
   → Jogador procura na Mochila
   → Se não tem: botão "Pedir no Pacto dos Guardiões"
   → Arrasta pro Altar
   → Status: "0/1 sacrificada" ou "1/1 OK"

4. Requisito 3: verificar $ mínimo
   → Sistema verifica automaticamente
   → Ex: "Precisa de $50T em caixa"
   → Status: "✅ OK" ou "❌ Falta $30T"

5. Botão "RENASCER"
   → Desabilitado até os 3 simultâneos
   → Quando todos OK: habilita e fica brilhando
```

### NO RENASCIMENTO (instantâneo)

```
1. Consumir requisitos
   → 3 criaturas do Altar → totalCopias -= 3
   → 1 criatura do Altar → totalCopias -= 1
   → $ mínimo não é consumido (só verificado)

2. Reset de Mochila
   → Mochila = vazia completamente
   → Todas as descobertas persistem no Álbum

3. Reset de Slots
   → Slots desalocam automaticamente (já estavam vazios)
   → Configuração de Slots persiste (número, layout)

4. Reset de $
   → $ = 0
   → 💎 persiste

5. Incrementar ciclo
   → cicloAtual += 1
   → Novos packs desbloqueados (+1 a cada 2 ciclos)
   → +1 Slot adicionado (a cada 2 ciclos)
   → Multiplicador $/s += 0.1

6. Álbum intacto
   → Todas as 315 criaturas persisem com totalCopias e grau
   → Nada muda no Álbum
```

### DEPOIS de renascer

**Fase 3 — Re-equipar (2-5 min)**
```
1. Abrir Mochila
   → Mostrar: "Mochila vazia"
   → Botão grande: "EQUIPAR MELHOR"

2. Sistema auto-aloca
   → Consulta Álbum
   → Ordena todas as criaturas por $/s
   → Aloca nos Slots em ordem decrescente
   → "Equipadas: 4 de 4 Slots disponíveis"

3. Resultado imediato
   → $/s atual exibido no topo
   → Jogador pode então:
     a) Ir abrir packs (Ladder agora tem 1 pack extra)
     b) Ir organizar Mochila manualmente se quiser
     c) Voltar pra Lobby

4. Reiniciar loop
   → Voltar pra loja
   → Começar a comprar packs
   → Acumular $ novamente
```

### Fluxo visual resumido

```
[ANTES]                     [DURANTE]              [DEPOIS]
Abrir Álbum          →      Requisitos OK  →       Mochila vazia
Ver Mochila          →      Renascer!      →       Equipar Melhor
Tirar dos Slots      →      $ = 0          →       $/s = reset
Staging Altar        →      💎 persiste    →       Novo ciclo
```

---

## 14. Economia — Renda Passiva

### Geração de $/s

```
valorPorSegundo_slot = seedValue_tier × 1.000 × multRaridade × multGrau × multRenascimento
total_$/s = soma de todos os Slots ocupados
```

### Coleta

- **Manual (padrão):** renda acumula em "pendente", clica botão/pad pra coletar
- **Automática (gamepass):** creditada direto

### Offline

Acumula até teto configurável. Creditada no login.

---

## 15. Ganho de Diamante — Todas as Fontes

| Fonte | Frequência | Diamante | Total/ciclo |
|---|---|---|---|
| Descoberta nova | Única (315 max) | 1-5 💎 | ~315 lifetime |
| Roda (grátis) | 1× a cada 30min | 50-200 💎 | ~9.600-38.400 |
| Roda (pago) | A cada compra | bônus | extra |
| Baús da Jornada | 6 marcos/6h | 25-100 💎 | ~100-400 |
| Streak Login | 1×/dia | 50 💎 | ~1.500 |
| Completar Clã | Única/clã | 500 💎 | ~7.500 lifetime |
| Tier A 1ª vez | Única/criatura | 100-200 💎 | ~600 lifetime |
| Eventos sazonais | Semanal/mensal | 100-500 💎 | ~2.000-8.000 |
| **TOTAL estimado** | — | — | **~21.500-50.000/ciclo** |

---

## 16. Auto-Venda Pós-Mítico

### Conceito
Quando uma criatura chega ao teto de raridade (Mítico = 140 cópias), cópias extras a partir daí são **automaticamente removidas**.

### Regra
```
IF totalCopias > 140:
  THEN auto-remove (totalCopias - 140)
  OPTION A: vender 20% do valor
  OPTION B: simplesmente descartar (sem pagar $)
```

**Nota:** Decisão pendente entre A e B. Sugestão: descartar (OPTION B) pra não complicar.

### Por quê?
- Cópias pós-Mítico só relevantes em batalhas (v2 do jogo)
- Jogador não precisa gerenciar manualmente
- Álbum fica "limpo"

---

## 17. Altar de Sacrifício e Renascimento

### O que reseta vs. persiste

| Item | Reseta? | Nota |
|---|---|---|
| $ (Dinheiro) | ✅ Zera | vai a 0 |
| 💎 Diamante | ✗ Persiste | não muda |
| Álbum (totalCopias, grau) | ✗ Persiste | intacto 100% |
| Mochila | ✅ Zera | vira vazia |
| Slots (config) | ✗ Persiste | mas sem cartas (+1 novo) |
| Desbloqueio Ladder | ✗ Persiste | +1 pack liberado |
| Nível/Desafios | ✗ Persiste | progresso mantido |

### Prova do Renascimento — 3 requisitos

**Requisito 1:** 3 criaturas do clã sorteado (escolha livre)
- Clã é determinado por ciclo: `Clans.Order[(cicloAtual % 15) + 1]`
- Mesmo clã pra todo servidor neste ciclo
- Via Altar de Sacrifício (staging manual)

**Requisito 2:** 1 criatura específica fixa (igual pra todo servidor)
- Fixa por ciclo
- Incentiva uso do **Pacto dos Guardiões** (doação/troca)
- Via Altar de Sacrifício

**Requisito 3:** Saldo mínimo de $ em caixa
- **NÃO é sacrificado** — só verificado
- Curva convexa escalando por ciclo
- Estrutura: `BASE × GROWTH ^ (cicloAtual ^ CONVEXIDADE)`

### Multiplicador permanente

```
multiplicador_renascimento = 1.0 + cicloAtual × 0.1
```

Exemplos:
- Ciclo 0: ×1.0
- Ciclo 10: ×2.0
- Ciclo 30: ×4.0
- Ciclo 60: ×7.0

---

## 18. Ciclos de Renascimento — Progressão Completa

| Ciclo | Renascimentos | Packs Ladder Máx | Slots | $/s Mult | Pack Clã |
|---|---|---|---|---|---|
| 0 | — | #1 | 3 | ×1.0 | $400 |
| 2 | 1 | #2 | 4 | ×1.1 | $598 |
| 4 | 2 | #3 | 5 | ×1.2 | $896 |
| 6 | 3 | #4 | 6 | ×1.3 | $1.344 |
| 10 | 5 | #6 | 8 | ×1.5 | $3.014 |
| 20 | 10 | #11 | 13 | ×2.0 | $22.718 |
| 30 | 15 | #16 | 18 | ×2.5 | $171.554 |
| 60 | 30 | #31 | 33 | ×4.0 | ~$838B |

**Padrão:** a cada 2 ciclos, +1 pack + 1 slot + ×0.1 multiplicador.

---

## 19. Sistemas de Engajamento Recorrente

### Streak de Login (7 dias)

- Ciclo de 7 dias com streak
- Quebra após 48h sem resgatar
- **Cada dia:** recebe pacote "Daily Blessings" (grátis, força Default)
- Recompensas crescentes por dia de streak

### Baús da Jornada

- 6 marcos (5min, 15min, 30min, 1h, 2h, 4h)
- Ciclo reseta a cada 6h
- Recompensas: $, 💎, pacotes

### Roda do Destino

- Giro grátis a cada 30min
- Giros pagos (1/3/10) em 💎
- Bônus sorte (3+ = rola 2×, pega melhor)
- Prêmios: 💎, $, +giros, pacote, carta exclusiva

### Constância Semanal

- Pacote grátis por X dias ativos na semana

---

## 20. Pacto dos Guardiões

### Doação
Jogador doa 1 unidade de progresso de criatura.

### Troca bilateral
Oferta mútua, confirmação dupla, por `creatureId`.

### Importância
Requisito 2 do Renascimento (criatura fixa por ciclo) cria demanda natural de troca entre jogadores.

---

## 21. Portal da Sorte

### Mecânica
- Abre 1×/dia por 30min
- Sincronizado globalmente
- Sorteia 1 de 6 variações

### As 6 variações
1. Eclipse de Clã — boost de drops
2. Maré de Fusão — desconto em custos
3. Chuva de Diamantes — ganho 💎 multiplicado
4. Maré Reversa — inverte vantagens elementais
5. Pacote Duplo — cada abertura = 2 resultados
6. Grande Portal — combo de dois efeitos

---

## 22. Sistema de Nível e Desafios

Nível avança por Desafios (contadores, posse, sacrifícios, etc.). Nível gatilha desbloqueio de Ladder.

---

## 23. Gamepasses e Monetização

### 9 Gamepasses
1. VIP
2. Coleta Automática
3. Sorte Celestial
4. Ultra Sorte
5. Sorte do Diamante
6. Mochila +500
7. Slots +5
8. Abertura Rápida (cooldown –50%)
9. Pacotes Exclusivos (revisar se redundante)

### Dev Products (4)
Recarga de 💎 (repetível)

---

## 24. Identidade Visual e Arte

### Direção: Atlas Iluminado

Pintura digital semi-realista, aura fluida abstrata.

### Sistema de cor
- **Clã:** cor dominante da arte (tabela seção 3)
- **Raridade:** borda aplicada por código
- **Tier:** estrelas no canto superior esquerdo (1★/2★/3★)

### Moldura de raridade (por código)

| Raridade | Cor |
|---|---|
| Default | Sem borda (border-none) |
| Bronze | `#C98A4B` |
| Prata | `#E8ECF0` |
| Ouro | `#FFE066` |
| Platina | `#A5F3FC` |
| Lendário | `#B983FF` |
| Mítico | `#FF4D4D` |
| **Divino** | Especial (ver abaixo) |

### Borda Divina — Refinada v3

**Especificações:**
- Base: prateada (cores primárias: prata + pastel)
- Lascas pastel: violeta, ciano, dourado, rosa
- **Efeito de giro:** só o anel da borda gira (~4s por volta, mais rápido que antes)
- **Glow:** aumentado (mais brilho), visível
- **Saturação:** mais saturada que a versão anterior
- **Arte:** fica **totalmente estática** (não gira)
- Resultado: diferença visual clara e sofisticada em relação às outras bordas

---

## 25. UI — Estrutura de Telas

### Paleta

| Token | Valor |
|---|---|
| Background | `#0d1024` |
| Painel | `#171b34` |
| Linha | `#2c3157` |
| Texto | `#f3f2ff` |
| $ | `#4ade80` |
| 💎 | `#38bdf8` |
| Evento | `#ffb020` |

### Telas principais
1. Lobby/HUD
2. Loja de Pacotes (4 abas)
3. Resultado de Abertura
4. Álbum (315 slots)
5. Mochila (1 por criatura)
6. Altar de Sacrifício
7. Roda do Destino
8. Loja (Gamepasses)

---

## 26. Arquitetura Técnica

### Stack
- Engine: Roblox Studio
- Linguagem: Luau (`--!strict`)
- Sync: Rojo
- Versionamento: GitHub

### Módulos críticos
- `Clans.lua` — 15 clãs com cores
- `Creatures.lua` — 300 criaturas com Tier
- `DivineCreatures.lua` — 15 Divinas
- `Rarities.lua` — 8 raridades
- `AlbumEvolutionCurve.lua` — thresholds
- `PackCatalog.lua` — 62 packs
- `PackClanCatalog.lua` — 15 packs clã
- `RenascimentoCatalog.lua` — provas

---

## 27. Roadmap de Desenvolvimento

| Fase | Status |
|---|---|
| 0–2 · Conceito + Systems | ✅ Completo (v3) |
| 3 · Arte Inicial | 🔄 Em andamento |
| 3 · UI/Protótipos | 🔄 Em andamento |
| 4–5 · UI Completa | ⏳ Pendente |
| 6 · Batalha PvE | ⏳ Pendente (v2) |
| 7–13 · Polish/Launch | ⏳ Pendente |

---

## 28. Decisões Finais — v3

✅ **Atalho removido completamente** — todo pacote +1 cópia
✅ **Mochila reseta no Renascimento** — jogador reorganiza antes
✅ **Venda manual removida** — só auto-venda pós-Mítico
✅ **Streak de Login** — diferente do pacote Daily Blessings
✅ **Cores dos 15 clãs** — finalizadas e aprovadas
✅ **Borda Divina refinada** — glow +, saturação +, rotação mais rápida
✅ **Renascimento passo-a-passo** — fluxo completo detalhado

---

**Próximo passo:** Distribuir as 300 criaturas por Tier (C/B/A) em cada clã? Ou começar a gerar arte dos packs?
