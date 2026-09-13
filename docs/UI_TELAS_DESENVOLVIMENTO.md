# 🎨 UI/TELAS — GUIA DETALHADO DE DESENVOLVIMENTO

**Data**: 19 de Julho de 2026 (reconciliado com o código real em 12/09/2026 —
contagem de pacotes e paleta de raridade/moedas)
**Status**: Especificação Executiva para Fase 5 — ainda vigente, confirmado
com a Paola em 12/09/2026 (a reescrita "HUD v2" em `README.md` é a
arquitetura de componentes, não substitui esta spec de conteúdo/layout)
**Público**: Devs Luau/Roblox Studio  

---

## 📋 ÍNDICE

1. [Design System Global](#design-system-global)
2. [HUD Geral](#hud-geral--header-permanente)
3. [Loja de Pacotes](#loja-de-pacotes)
4. [Mochila](#mochila)
5. [Álbum](#álbum)
6. [Altar de Sacrifício](#altar-de-sacrifício)
7. [Tela de Venda](#tela-de-venda)
8. [Pacto dos Guardiões](#pacto-dos-guardiões)
9. [Roda do Destino](#roda-do-destino)
10. [Bênção Diária](#bênção-diária)
11. [Nível & Desafios](#nível--desafios)
12. [Gamepasses & Dev Products](#gamepasses--dev-products)
13. [Notificações & Popups](#notificações--popups)
14. [Animações & Transições](#animações--transições)

---

## DESIGN SYSTEM GLOBAL

### Paleta de Cores

> ⚠️ **A paleta "Base"/"Semânticas" abaixo é uma proposta que nunca chegou a
> ser implementada tal como está** — o HUD v2 real (`README.md`,
> `src/shared/Config/Colors.lua`/`DesignTokens.lua`) usa uma paleta dark-navy
> diferente (Background `#0b0d1e`, Painel `#161a35`, Texto `#f5f4ff`, $
> `#79E600`, 💎 `#87E1E8`, Evento `#FFDA1E`). Não copiar os hex abaixo pra
> código novo sem checar `Colors.lua` primeiro — as tabelas de **Raridades**
> e **Moedas** logo abaixo já foram corrigidas pra bater com o código; o
> resto desta seção (Base/Semânticas) ainda reflete só a proposta original de
> 19/07/2026 e precisa de uma revisão completa quando essas telas entrarem
> em produção de verdade.

**Base (Dark Navy Theme) — proposta original, não implementada**
- Background Primário: `#0F1419` (muito escuro, quase preto)
- Background Secundário: `#1A2332` (cinza escuro)
- Background Terciário: `#2A4158` (cinza médio, headers)
- Text Primário: `#FFFFFF` (branco)
- Text Secundário: `#B0B0B0` (cinza claro)
- Text Terciário: `#707070` (cinza escuro)
- Accent Principal: `#FFD700` (ouro)
- Accent Secundário: `#FFE066` (ouro claro, hover)

**Moedas** *(corrigido 12/09/2026 — bate com `Colors.lua`)*
- Coins ($): `#79E600` (verde)
- Diamantes (💎): `#87E1E8` (ciano claro)
- Robux: `#FFFFFF` (branco, segue oficial Roblox)
- Grátis/Evento: `#FFDA1E` (amarelo)

**Raridades** *(corrigido 12/09/2026 — bate com `Colors.lua`)*
- Default: `#2A2E3D` (grafite)
- Bronze: `#CD7F32`
- Prata: `#E0E6ED`
- Ouro: `#FFD700`
- Platina: `#00F0FF`
- Lendário: `#C800FF`
- Mítico: `#FF007F`
- Divino: arco-íris (magenta/dourado/ciano/violeta, ver `DivineBorder.lua`)

**Semânticas**
- Sucesso: `#27AE60` (verde)
- Aviso: `#F39C12` (laranja)
- Erro: `#E74C3C` (vermelho)
- Info: `#3498DB` (azul)

### Tipografia

**Font Stack**: Inter, Baloo 2 (títulos)

| Elemento | Font | Tamanho | Weight | Casos de Uso |
|----------|------|---------|--------|--------------|
| Título Principal | Baloo 2 | 28px | 600 | Nome da tela, HUD title |
| Título Secundário | Baloo 2 | 20px | 600 | Seções dentro de telas |
| Heading 3 | Inter | 16px | 500 | Subheadings |
| Body Text | Inter | 14px | 400 | Descrições, labels |
| Small Text | Inter | 12px | 400 | Hints, metadata |
| Micro Text | Inter | 10px | 400 | Tooltips, rodapé |
| Mono (valores) | Inter | 14px | 600 | Números, IDs |

### Espaçamento & Dimensões

| Token | Valor | Uso |
|-------|-------|-----|
| `--pad-xs` | 4px | Espaçamento interno mínimo |
| `--pad-sm` | 8px | Padding card/componente pequeno |
| `--pad-md` | 12px | Padding padrão componente |
| `--pad-lg` | 16px | Padding card grande, container |
| `--pad-xl` | 20px | Padding tela inteira |
| `--gap-xs` | 4px | Gap entre itens micro |
| `--gap-sm` | 8px | Gap entre itens pequeno |
| `--gap-md` | 12px | Gap padrão entre items |
| `--gap-lg` | 16px | Gap entre seções |
| `--radius-sm` | 4px | Border radius button, input |
| `--radius-md` | 8px | Border radius card |
| `--radius-lg` | 12px | Border radius grande (modal) |

### Elevação (Shadows)

```lua
-- CardShadow: Sombra sutil para cards elevados
shadow-md = "0 4px 12px rgba(0, 0, 0, 0.3)"

-- ModalShadow: Sombra forte pra modals
shadow-lg = "0 8px 24px rgba(0, 0, 0, 0.5)"

-- NoShadow: UI plana (maioria dos elementos)
```

### Estados Padrão de Componentes

Cada componente interativo (botão, input, card clicável) tem 4 estados:

1. **Default** — cor base, sem alteração
2. **Hover** — `+10% brilho` (mais claro) ou borda destacada
3. **Press/Active** — `−10% brilho` (mais escuro), scale 0.95
4. **Disabled** — `opacity 0.5`, cursor não-allowed

---

## HUD GERAL — Header Permanente

### Localização & Estrutura

**Onde:** Topo da tela (fixo, ScreenGui com ZIndex alto)  
**Altura:** 60px  
**Fundo:** `#1A2332` com linha de separação inferior `1px solid #707070`  
**Padding:** 12px (esquerda/direita)

### Layout (da esquerda pra direita)

```
┌─────────────────────────────────────────────────────────┐
│ [Logo] │ $1.2M      │ 💎 450    │ $/s: 50K  │  Nível 42 │ ⚙️ │
└─────────────────────────────────────────────────────────┘
```

### Componentes

#### 1. Logo/Título
- Ícone + "Cartas Míticas" (ou abreviado em mobile)
- Font: Baloo 2, 16px bold, cor `#FFD700`
- Clicável: retorna pra Lobby/Home
- Hover: cursor pointer, brilho +5%

#### 2. Saldo de Dinheiro ($)
- Layout: Ícone (moeda verde) + número formatado
- Formato: "$1.2M" (abreviado com sufixo K/M/B)
- Font: Mono 14px
- Cor: `#27AE60` (verde)
- Atualização: tempo real conforme renda acumula
- Clicável: abre tela de Renda/Slots (TBD)

#### 3. Saldo de Diamantes (💎)
- Layout: Ícone (diamante ciano) + número bruto
- Font: Mono 14px
- Cor: `#00CED1` (ciano)
- Atualização: tempo real
- Clicável: abre Loja de Dev Products

#### 4. Renda Atual ($/s)
- Label: "$/s:" (pequeno, 12px)
- Valor: "50K" (14px mono, cor `#FFD700`)
- Tooltip ao hover: "Renda por segundo (todos os slots)"
- Nenhuma ação ao clicar

#### 5. Nível do Jogador
- Label: "Nível" (12px)
- Badge: número em círculo `#FFD700`, 16px
- Cor texto: `#FFFFFF`
- Clicável: abre tela de Desafios/Nível
- Badge tem subtle glow ao melhorar de nível

#### 6. Botão de Configurações (⚙️)
- Ícone: engrenagem, 20px
- Cor: `#B0B0B0`
- Hover: cor muda pra `#FFD700`
- Clicável: abre modal de Settings (Áudio, Privacidade, Logout, etc.)

### Responsividade (Mobile)

- Em telas < 400px: abreviar pra ícone + número apenas (sem label)
- Logo vira só ícone
- Ordem compacta: $ | 💎 | ⚙️ | Nível

### Animações

- **Level-up notification**: badge do nível pisca 2x com scale animado
- **Ganho de Diamante**: número de diamante tem transição de cor (branco → ciano) ao mudar
- **Transição entre telas**: fade in/out 200ms

---

## LOJA DE PACOTES

### Overview

A **Loja de Pacotes** é a tela mais complexa do jogo. Ela governa a monetização (todos os 77 pacotes passam por aqui — corrigido 12/09/2026, o número original desta seção era 62, do modelo antigo de `PackCatalog.lua`).

**Acesso:** Botão "Loja" no HUD, ou tela inicial  
**Saída:** Voltar pro Lobby/HUD

### Estrutura Geral da Tela

```
┌─ LOJA DE PACOTES ─────────────────────────────┐
│                                               │
│  [HEADER: Saldo, botão Voltar]               │
│                                               │
│  [ABAS] Geral | Diamante | Robux | Especial  │
│                                               │
│  ┌─ PRATELEIRA "EM DESTAQUE AGORA" ──────┐   │
│  │ [Pacote 1] [Pacote 2] [Pacote 3]     │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  ┌─ LISTA SCROLLÁVEL DE PACOTES ─────────┐   │
│  │ [Pack] Novato          $200  [Abrir]  │   │
│  │ [Pack] Recruta         $299  [Abrir]  │   │
│  │ ...                                    │   │
│  │ [BLOQUEADO] Transcendente   Nível 300 │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  [PAINEL DE DETALHE] (ao selecionar um pack) │
│  Nome | Descrição | Tabela de Odds | Preço   │
│                                               │
└───────────────────────────────────────────────┘
```

### 1. Header da Tela

**Altura:** 60px  
**Layout:**
```
[← Voltar]     Loja de Pacotes     [💎 450] [$1.2M]
```

- Botão Voltar: ícone de seta esquerda, cor `#B0B0B0`
- Título: Baloo 2, 24px, `#FFFFFF`, centralizado
- Saldo à direita (replicado do HUD por conveniência)

### 2. Sistema de Abas

**Posição:** Logo abaixo do header, sticky (não scroll com conteúdo)  
**Design:** Barra horizontal com 5 botões *(corrigido 12/09/2026 — o
`PackCatalog.lua` real tem 5 categorias, não 4; a aba "Clã" estava faltando
nesta spec)*

| Aba | Cor Associada | Pacotes (IDs em `PackCatalog.lua`) |
|-----|---------------|---------|
| Geral | Verde (`#79E600`) | 1-30 |
| Clã | cor do clã selecionado | 31-45 |
| Diamante | Ciano (`#87E1E8`) | 46-51 |
| Robux | Branco (#FFFFFF) | 52-60 |
| Especial | Ouro (`#FFD700`) | 61-77 |

**Cada aba:**
- Altura: 40px
- Padding: 10px 16px
- Fundo: transparent, border-bottom 2px (cor da moeda) na aba ativa
- Hover: fundo `rgba(255, 215, 0, 0.1)`
- Font: Inter 14px, 500
- Clicável, atualiza lista abaixo

### 3. Prateleira "Em Destaque Agora"

**Posição:** Abaixo das abas, antes da lista principal  
**Altura:** ~200px  
**Conteúdo:** Cards de pacotes com `Availability.Kind = "EventWindow"` (portal divino, sazonais, etc.)

**Layout:** Scroll horizontal (carroussel)
```
┌─────────────────────────────────────────┐
│  ← [Card1] [Card2] [Card3] →           │
└─────────────────────────────────────────┘
```

**Card do Pacote (Destaque):**
- Dimensões: 160x240px
- Fundo: imagem do pack (art final Midjourney)
- Overlay: gradiente preto (0% opacity top → 60% bottom) pra deixar texto legível
- Badge: "EVENTO" canto superior esquerdo, fundo `#FFD700`, cor texto `#0F1419`, padding 4px 8px, border-radius 4px
- Texto embaixo: nome + preço + moeda
- Hover: scale 1.05, shadow-md mais forte

### 4. Lista Principal de Pacotes

**Posição:** Abaixo da prateleira  
**Scroll:** Vertical, preenchimento automático  
**Altura máxima:** calc(100% - header - abas - destaque - padding)

**Cada linha de pacote:**
```
┌─────────────────────────────────────────────────┐
│ [IMG] │ Novato      │ $200  │ 1 carta │ [Abrir] │
│      │ Bronze 70%  │ Geral │         │         │
└─────────────────────────────────────────────────┘
```

**Estrutura interna:**
- Altura: 80px
- Padding: 12px
- Border-bottom: `0.5px solid #707070`
- Fundo: alternado entre `#1A2332` e `#242f3e` (subtle stripe pra legibilidade)

**Componentes (L→R):**

1. **Imagem do Pacote**
   - Dimensões: 60x80px (aspecto ratio 2:3)
   - Border: `1px solid #707070`
   - Border-radius: 4px
   - Sombra: shadow-sm
   - Source: `/PackArt/{Categoria}/{PackKey}.png`

2. **Metadados (coluna central, flex-grow)**
   - Linha 1: Nome (14px bold, `#FFFFFF`)
   - Linha 2: Odds resumidas (12px, `#B0B0B0`) — ex: "Bronze 70%, Prata 20%, Ouro 8%, Platina 2%"
   - Linha 3: Tipo (10px, `#707070`) — ex: "Geral", "Diamante", "Evento"

3. **Preço (coluna direita, 80px)**
   - Número: 16px mono, cor da moeda (verde/ciano/branco/ouro)
   - Sufixo: moeda (K, M, B pra Coins/Diamantes; ícone $ pra Robux)
   - Alinhamento: right

4. **Botão Abrir**
   - Style: `background: cor_moeda, color: #0F1419, border-radius: 4px, padding: 8px 16px`
   - Hover: +10% brilho, cursor pointer
   - Press: −10% brilho, scale 0.98
   - Disabled (se bloqueado): opacity 0.5, cursor not-allowed
   - Text: "Abrir" ou "Nível X" (se bloqueado)

**Estado BLOQUEADO (Geral, antes de atingir UnlockLevel):**
- Overlay cinza: `rgba(0, 0, 0, 0.4)`
- Ícone de cadeado no lugar do botão Abrir
- Texto em cinza: "Nível {X} necessário"
- Não interativo

### 5. Painel de Detalhe (Modal)

Ao selecionar um pacote (clicar na linha ou na imagem), abre um modal lado-direito ou popup centralizado:

**Layout Modal (lado-direito em desktop, popup centralizado em mobile):**
```
╔════════════════════════╗
║ [Novato] [×]           ║
╠════════════════════════╣
║ Descrição:             ║
║ "Seu primeiro pacote,  ║
║  ideal pra começar!"   ║
║                        ║
║ Conteúdo:              ║
║ • 1 criatura           ║
║ • Raridade: até Bronze ║
║                        ║
║ Odds de Raridade:      ║
║ Bronze:  70.0%         ║
║ Prata:   20.0%         ║
║ Ouro:     8.0%         ║
║ Platina:  2.0%         ║
║ Lendário: 0.0%         ║
║ Mítico:   0.0%         ║
║                        ║
║ Preço: $200            ║
║ [ABRIR]                ║
╚════════════════════════╝
```

**Componentes:**

1. **Header**
   - Título: nome do pacote (16px bold)
   - Botão fechar: ícone X, cor `#B0B0B0`, hover `#FFD700`

2. **Descrição**
   - Texto: 12px, `#B0B0B0`, line-height 1.5
   - Max-width: 300px (quebra linhas automático)

3. **Odds de Raridade (Tabela)**
   - 2 colunas: [Raridade] [%]
   - Font: 12px mono
   - Barra visual: fundo da raridade (cor correspondente), preenchimento proporcional

4. **Botão Abrir (Final)**
   - CTA principal: fundo `cor_moeda`, texto `#0F1419` bold
   - Hover: +10% brilho
   - Clicável: chama `RemoteEvent:FireServer("OpenPack", packKey)`

### 6. Fluxo de Abertura de Pacote

**Sequência:**

1. Jogador clica "Abrir"
2. Cliente valida saldo (feedback imediato se insuficiente)
3. Cliente envia `OpenPack` RemoteEvent ao servidor
4. Servidor valida de novo + consome moeda + sorteia criatura
5. Cliente recebe resultado (raridade, criatura, clone, grau)
6. Anima a revelação em overlay (zoom + brilho + texto)
7. Mostra resultado por 2 segundos
8. Botão "Próximo Pacote" ou "Voltar à Loja"

**Tela de Revelação:**
```
                    ✨
         CRIATURA REVELADA
                    
        [ART DE CRIATURA]
        Fênix Solar
        Ouro ⭐⭐⭐
        
        ATK 48 | DEF 42 | HP 180
        Ordem Celestial • Criatura #1
        
        [Próximo Pacote]  [Voltar à Loja]
```

---

## MOCHILA

### Overview

A **Mochila** é o inventário do jogador. Armazena até 200 criaturas descobertas (1 objeto = 1 criatura descoberta, não cópias duplicadas).

**Acesso:** Botão "Mochila" no HUD  
**Saída:** Voltar ao HUD

### Estrutura Geral

```
┌─ MOCHILA ─────────────────────────────────────┐
│                                               │
│  [HEADER: Progresso, Filtros, Busca]          │
│                                               │
│  [FILTROS]                                    │
│  Clã: [Todos] Raridade: [Todos] Grau: [Todos]│
│  Ordenar: [Valor ↓] [Nome] [Data] [Grau]     │
│                                               │
│  [BUSCA] Buscar criatura... [×]               │
│                                               │
│  ┌─ GRID DE CRIATURAS ───────────────────┐   │
│  │ [Card] [Card] [Card] [Card]           │   │
│  │ [Card] [Card] [Card] [Card]           │   │
│  │ ...                                    │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  Resultado: 47 de 200 criaturas               │
│                                               │
└───────────────────────────────────────────────┘
```

### 1. Header (Progresso)

**Altura:** 50px  
**Conteúdo:**
```
Mochila: 47 / 200 [████░░░░░░] 23%
```

- Número absoluto + percentual
- Barra de progresso: fundo `#1A2332`, preenchimento `#FFD700`, border-radius 4px
- Alerta se ≥ 90%: "Mochila quase cheia" em `#F39C12` (aviso)

### 2. Filtros

**Localização:** Abaixo do header  
**Tipo:** Dropdowns + botões toggle

**Dropdowns:**
- **Clã**: "Todos" | lista de 15 clãs com cores
- **Raridade**: "Todos" | Default, Bronze, Prata, Ouro, Platina, Lendário, Mítico, Divino
- **Grau**: "Todos" | vazio, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0
- **Ordenar**: "Valor (descendente)" | "Nome", "Data adicionada", "Grau", "Raridade"

**Design dos dropdowns:**
- Altura: 32px
- Border: `1px solid #707070`
- Background: `#1A2332`
- Hover: border `#FFD700`
- Opção selecionada: checkmark e fundo subtle (cor da categoria se aplicável)

### 3. Barra de Busca

**Posição:** Abaixo dos filtros  
**Altura:** 36px  
**Comportamento:**
- Placeholder: "Buscar por nome de criatura..."
- Caracteres digitados filtram em tempo real (sem delay de digitar)
- Ícone X aparece se houver texto (limpa ao clicar)
- Focus: border `#FFD700`, shadow-sm

### 4. Grid de Criaturas

**Layout:** Responsivo, 3-5 colunas conforme tela  
**Tamanho célula:** ~120x140px (móvel), ~140x160px (desktop)  
**Gap:** 12px

**Card Individual (Criatura):**
```
┌──────────────────┐
│    [IMAGEM]      │
│  (80x100px)      │
│                  │
│ Fênix Solar      │
│ Ouro ⭐⭐⭐     │
│ Grau: 8.5        │
│ Cópias: 8/31     │
│                  │
│ [$2.4M] [+]      │
└──────────────────┘
```

**Componentes do card:**

1. **Imagem** (topo)
   - Tamanho: 80x100px
   - Border: `2px solid {cor_raridade}` (ex: ouro pra Ouro)
   - Background: `#0F1419`
   - Sem sombra (design plano)

2. **Título** (criatura)
   - Font: Inter 12px bold
   - Cor: `#FFFFFF`
   - Truncado se muito longo

3. **Raridade + Ícone**
   - Font: 11px, cor da raridade
   - Ícone: ⭐ repetido (Bronze 1⭐, Prata 2⭐, etc.)
   - Divino: ✨ (brilho especial)

4. **Grau** (se > vazio)
   - Font: 10px, `#B0B0B0`
   - Formato: "Grau: 8.5" ou "-" se vazio

5. **Progresso de Cópias**
   - Font: 10px, `#707070`
   - Formato: "Cópias: 8/31"
   - Barra micro abaixo (1px altura, % preenchida)

6. **Ações** (fundo do card)
   - **Ícone de venda** (moeda): valor em `#27AE60` (verde), 11px
   - **Botão "+"** (equipar): pequenininho, background `#FFD700`, cor `#0F1419`

### 5. Interações

**Clique no card:** Abre modal de preview (nome, stats, grau, valor, histórico)  
**Clique no "+":** Abre popup "Equipar em qual slot?" com lista de slots disponíveis  
**Clique no ícone de venda:** Abre confirmação de venda

### 6. Estados

- **Vazio (nenhuma criatura):** Card cinzento (opacity 0.5), "Não descoberta"
- **Selecionado:** Border mais grossa, background subtle highlight
- **Hover:** Sombra aparece, scale ligeiro 1.02

---

## ÁLBUM

### Overview

O **Álbum** é a tela de coleção do jogador. Mostra todas as 300 criaturas possíveis, com progresso de descoberta, pontos de evolução e stats.

**Acesso:** Botão "Álbum" no HUD  
**Saída:** Voltar ao HUD

### Estrutura Geral

```
┌─ ÁLBUM DE COLEÇÃO ────────────────────────────┐
│                                               │
│  [HEADER: Progresso Total, Abas por Clã]      │
│  Descobertas: 47 / 300 (15.7%)                │
│                                               │
│  [ABAS] Todas | Ordem C. | Véu S. | ...      │
│                                               │
│  ┌─ GRID 6-7 COLUNAS ────────────────────┐    │
│  │ [Card] [Card] [Card] [Card] [Card]    │    │
│  │ [Card] [Card] [Card] [Card] [Card]    │    │
│  │ ... (300 total) ...                   │    │
│  └───────────────────────────────────────┘    │
│                                               │
│  [LEGENDA] Cinza = não descoberta             │
│                                               │
└───────────────────────────────────────────────┘
```

### 1. Header (Progresso Total)

**Altura:** 60px  
**Conteúdo:**
```
Álbum de Coleção      Descobertas: 47 / 300 (15.7%)
```

- Título: Baloo 2, 22px
- Stats: Inter 14px, `#B0B0B0`
- Barra visual: grid visual pequeno mostrando % por rarity (6 barrinhas lado-a-lado)

### 2. Sistema de Abas (por Clã)

**Sticky:** sim, fixo ao scroll

**Abas:**
- "Todas" (grid completo 300)
- "Ordem Celestial" (20)
- "Véu Sombrio" (20)
- ... (15 total)

**Design aba:**
- Altura: 40px
- Cor de fundo: cor do clã se ativa, else `transparent`
- Hover: background subtle (rgba da cor do clã, 20%)
- Border-bottom: `2px solid cor_do_clan` se ativa

### 3. Grid de Criaturas

**Layout:** 6-7 colunas (ajusta responsivo)  
**Gap:** 10px  
**Card tamanho:** ~100x130px (desktop), ~90x120px (mobile)

**Card Individual (não descoberta):**
```
┌──────────────┐
│   [??????]   │
│              │
│   Bloqueado  │
│   Discover   │
└──────────────┘
```

- Fundo: cinza (#707070, opacity 0.3)
- Imagem: "???" ou sombra da silhueta (nunca a arte real)
- Texto: "Bloqueado" (10px, `#B0B0B0`)
- Border: `1px solid #707070`
- Não clicável

**Card Individual (descoberta):**
```
┌──────────────┐
│  [IMAGEM]    │
│ (80x100px)   │
│              │
│ Criatura     │
│ Ouro ⭐⭐   │
│ 8/31 cópias  │
│ [Grau 8.5]   │
└──────────────┘
```

- Imagem: arte real (80x100px), border `2px solid {cor_raridade}`
- Nome: truncado, 11px
- Raridade: ícone ⭐
- Progresso: "8/31 cópias", 9px, `#B0B0B0`
- Grau badge: fundo escuro, "8.5", 9px, canto inferior direito
- Hover: scale 1.05, sombra aparece
- Clicável: abre preview detalhado (sidebar ou modal)

### 4. Preview Detalhado

Ao clicar num card descoberto:

**Modal / Sidebar (à direita em desktop):**
```
╔════════════════════════════════╗
║ Fênix Solar      [×]           ║
╠════════════════════════════════╣
║                                ║
║        [IMAGEM GRANDE]         ║
║        (150x180px)             ║
║                                ║
║ Raridade: Ouro                 ║
║ Grau: 8.5                      ║
║ Clã: Ordem Celestial           ║
║ Origem: Grécia / Egito         ║
║                                ║
║ Stats Atuais:                  ║
║ ├─ Valor: $2.4M               ║
║ ├─ Ataque: 48                 ║
║ ├─ Defesa: 42                 ║
║ └─ HP: 180                     ║
║                                ║
║ Progresso de Evolução:         ║
║ Ouro (8/31 cópias)            ║
║ ████████░░░░ (26%)            ║
║                                ║
║ Próxima evolução:             ║
║ Platina (23 cópias faltam)    ║
║                                ║
║ [Equipar] [Vender] [Despertar]║
╚════════════════════════════════╝
```

**Componentes:**

1. **Header**
   - Nome + botão fechar

2. **Imagem Expandida**
   - Tamanho: 150x180px
   - Border: `2px solid {cor_raridade}`
   - Sombra: shadow-md

3. **Metadados**
   - Raridade, Grau, Clã, Origem
   - Font: 12px
   - Alinhamento: label | valor

4. **Stats Atuais**
   - Valor, Ataque, Defesa, HP
   - Números em mono font, cores temáticas
   - Tooltip: mostra fórmula de cálculo

5. **Barra de Progresso**
   - Raridade atual + quantas cópias faltam pra próxima
   - Cores: gradiente de raridade

6. **Botões de Ação**
   - **Equipar**: abre selector de slots (ícone: +)
   - **Vender**: mostra confirmação + valor (ícone: moeda)
   - **Despertar**: abre tela de Despertar (ícone: diamante)

---

## ALTAR DE SACRIFÍCIO

### Overview

O **Altar** é onde o jogador prepara o Renascimento. Precisa reunir 3 requisitos simultâneos.

**Acesso:** Botão "Renascimento" no HUD  
**Saída:** "Renascer" ou "Voltar"

### Estrutura Geral

```
┌─ ALTAR DE SACRIFÍCIO ─────────────────────────┐
│                                               │
│  Prepare-se para o Renascimento               │
│  Ciclo #3 | Multiplicador: ×1.30              │
│                                               │
│  ┌─ REQUISITO 1 ────────────────────────────┐ │
│  │ Sacrificar 3 criaturas do clã:           │ │
│  │ Ordem Celestial (sorteado)               │ │
│  │                                          │ │
│  │ [Criatura 1] [Criatura 2] [×]            │ │
│  │ [Criatura 3] [+] Adicionar              │ │
│  │ Status: 2/3 ✓ (faltam 1)                │ │
│  └──────────────────────────────────────────┘ │
│                                               │
│  ┌─ REQUISITO 2 ────────────────────────────┐ │
│  │ Sacrificar criatura específica:          │ │
│  │ Fênix Solar (qualquer raridade/grau)    │ │
│  │                                          │ │
│  │ [Fênix Solar - Ouro Grau 8.5]           │ │
│  │ Status: 1/1 ✓ (pronta)                  │ │
│  └──────────────────────────────────────────┘ │
│                                               │
│  ┌─ REQUISITO 3 ────────────────────────────┐ │
│  │ Saldo mínimo de dinheiro:                │ │
│  │ $1.5B necessário                         │ │
│  │                                          │ │
│  │ Você tem: $2.3B ✓                        │ │
│  └──────────────────────────────────────────┘ │
│                                               │
│  [RENASCER] (ativado quando 3/3 OK)           │
│  ou [PREPARAR] se não está pronto            │
│                                               │
└───────────────────────────────────────────────┘
```

### 1. Header

- Título: "Altar de Sacrifício"
- Subtitle: "Ciclo #{num} | Multiplicador: ×{valor}"
- Hint: "Reúna os 3 requisitos abaixo pra renascer"

### 2. Requisito 1 — 3 Criaturas do Clã

**Card:**
- Título: "Sacrificar 3 criaturas do clã:" + nome do clã com cor
- Layout: grid `1x3` de slots (ou flex-wrap)
- Altura total: ~120px

**Slots:**
- Vazio: placeholder cinzento com ícone "+" (clicável)
- Preenchido: miniatura da criatura (60x80px), com ícone [×] pra remover

**Clicável (slot vazio):** Abre seletor de criaturas
- Mostra: apenas criaturas disponíveis do clã sorteado
- Restrições: não pode colocar a mesma criatura 2x (se há 1 Fênix no slot 1, slot 2 não oferece Fênix)
- Após selecionar: slot preenche, status atualiza

**Status:** "2/3 ✓ Faltam 1 criatura do clã"
- Cor: verde se 3/3, amarela se 1-2, vermelho se 0
- Atualiza em tempo real

### 3. Requisito 2 — 1 Criatura Específica

**Card:**
- Título: "Sacrificar criatura específica:"
- Subtitle: nome da criatura fixa (ex: "Fênix Solar")
- Hint: "(qualquer raridade ou grau)"

**Slot:**
- Vazio: placeholder com ícone "Procurar"
- Preenchido: card da criatura (120x140px com raridade/grau)
- Ícone [×] pra remover

**Clicável (vazio):** Abre modal buscando criaturas com nome exato
- Autocomplete se houver múltiplas em raridades diferentes
- Seleciona a que o jogador escolhe
- Se não possui: modal cinzento, "Você não possui essa criatura"

**Status:** "1/1 ✓ Pronta" ou "0/1 ✗ Não possui"
- Cor: verde se 1/1, vermelho se 0

### 4. Requisito 3 — Saldo de Dinheiro

**Card (visual simples, não interativo):**
- Título: "Saldo mínimo de dinheiro:"
- Valor necessário: "$ {valor_threshhold}" (mono font, tamanho grande, cor `#27AE60`)
- Seu saldo: "Você tem: $ {seu_saldo}" (cor verde se ≥ limiar, vermelho se < limiar)
- Progressbar visual: `[████████░░] 92%`

### 5. Botão de Ação

**Estado 1:** Todos 3/3 requisitos OK
```
[✓ RENASCER]
```
- Background: `#27AE60` (verde)
- Cor texto: `#FFFFFF`
- Hover: +10% brilho
- Clicável: abre confirmação final (modal com "Tem certeza?")

**Estado 2:** Faltam requisitos
```
[✗ PREPARAR]
```
- Background: `#707070` (cinzento)
- Cursor: not-allowed
- Tooltip ao hover: lista quais requisitos faltam (ex: "Faltam 1 criatura do clã")

### 6. Confirmação Final

Modal antes de confirmar renascimento:

```
╔═════════════════════════════╗
║ Confirmar Renascimento      ║
╠═════════════════════════════╣
║                             ║
║ Você vai:                   ║
║ • Sacrificar 3 criaturas    ║
║ • Sacrificar Fênix Solar    ║
║ • Gastar $1.5B              ║
║                             ║
║ Seu multiplicador vai:      ║
║ ×1.30 → ×1.40 (+10%)        ║
║                             ║
║ Dinheiro reseta a $0        ║
║ Nível mantém                ║
║ Álbum persiste              ║
║                             ║
║ [RENASCER DE VERDADE]       ║
║ [CANCELAR]                  ║
╚═════════════════════════════╝
```

---

## TELA DE VENDA

### Overview

Tela para vender criaturas individuais (não é bulk auto-sell).

**Acesso:** Botão em card da Mochila ou Álbum  
**Saída:** "Confirmar" ou "Cancelar"

### Estrutura

```
┌─ VENDER CRIATURA ─────────────────────────────┐
│                                               │
│  Fênix Solar                                  │
│  Ouro • Grau 8.5 • Cópia 8/31                │
│                                               │
│  [IMAGEM]                                     │
│                                               │
│  Valor de Venda: $480K (20% de $2.4M)        │
│                                               │
│  ⚠️ AVISO DE DOWNGRADE:                       │
│  Você tem 8 cópias. Ao vender 1, ficarão 7.  │
│  Com 7 cópias, a raridade vai baixar:        │
│  Ouro → Prata (perderá multiplicador)        │
│                                               │
│  [VENDER DE VERDADE] [CANCELAR]              │
│                                               │
└───────────────────────────────────────────────┘
```

### Componentes

1. **Metadados da criatura**
   - Nome, raridade, grau, cópia atual

2. **Imagem**
   - 100x120px, border rarity color

3. **Valor de Venda**
   - Font: mono 16px bold
   - Cor: `#27AE60` (verde, pois ganha $)
   - Cálculo: valor_real × 0.20

4. **Aviso de Downgrade** (CONDICIONAL)
   - Só aparece se vender vai causar downgrade
   - Explica: "raridade vai baixar de X para Y"
   - Background: `#FFF8DC` (cream), border `1px solid #F39C12` (aviso)
   - Font: 12px, `#8B4513` (marrom escuro, contraste em background claro)

5. **Botões**
   - [VENDER DE VERDADE]: confirmação explícita
   - [CANCELAR]: volta sem fazer nada

---

## PACTO DOS GUARDIÕES

### Overview

Sistema de troca e doação entre jogadores.

**Acesso:** Aba/Menu "Pacto dos Guardiões"  
**Saída:** Voltar

### 1. Abas Principais

- **Doação** — enviar criatura pra jogador pelo ID
- **Troca** — proposta bilateral (requer confirmação de ambos)
- **Histórico** — log de transações passadas

### Doação

```
┌─ DOAÇÃO ──────────────────────────────────────┐
│                                               │
│  Enviar criatura pra um amigo                 │
│                                               │
│  ID/Nome do jogador: [________________]       │
│  [Procurar] ou [Amigos Online] dropdown       │
│                                               │
│  Selecione criatura a enviar:                 │
│  ┌─ GRID de suas criaturas ─────────────────┐│
│  │ [Card] [Card] [Card] ...                 ││
│  └──────────────────────────────────────────┘│
│                                               │
│  [ENVIAR CRIATURA]                           │
│                                               │
│  Status: {mensagem de sucesso/erro}          │
│                                               │
└───────────────────────────────────────────────┘
```

### Troca

```
┌─ TROCA (Bilateral) ────────────────────────────┐
│                                               │
│  Propor troca com outro jogador               │
│                                               │
│  ID/Nome: [_________________] [Procurar]     │
│                                               │
│  Lado VOCÊ                 │  Lado OUTRO      │
│  Ofereço:                  │  Ele oferece:    │
│  ┌──────────────────────┐ │ ┌──────────────┐ │
│  │ [Card] [Card] ...    │ │ │ [Card] ...   │ │
│  └──────────────────────┘ │ └──────────────┘ │
│  [+ Adicionar]             │ [Ver Ofertas]    │
│                                               │
│  [PROPOR TROCA]            [CANCELAR]         │
│                                               │
│  Propostas Recebidas:                         │
│  • De {jogador A}: quer X, oferece Y          │
│    [ACEITAR] [REJEITAR]                       │
│  • De {jogador B}: ...                        │
│                                               │
└───────────────────────────────────────────────┘
```

---

## RODA DO DESTINO

### Overview

Spinner diário com recompensas.

**Acesso:** Botão "Roda do Destino" no HUD  
**Duração girar:** 2-3 segundos de animação

### Tela

```
┌─ RODA DO DESTINO ─────────────────────────────┐
│                                               │
│  Próximo giro grátis em: 28:14:33             │
│                                               │
│          ╱─────────────╲                      │
│       ╱─────────────────────╲                 │
│      │  💎  │  💎 │ $  │ 🎁  │                │
│      │      │     │    │     │                │
│      │  💎  │  ♻  │💎  │ +1  │                │
│      │      │     │    │     │                │
│      │ $  │ 🎁 │ 💎 │ $+$ │                │
│       ╲─────────────────────╱                 │
│          ╲─────────────╱                      │
│                 │ Ponteiro                    │
│                 ▼                             │
│          [GIRAR GRÁTIS]                       │
│          ou                                  │
│          [GIRAR +3] (pago em giros extras)    │
│          [GIRAR +10] (pago)                   │
│                                               │
│  Resultado último giro:                       │
│  Você ganhou: $2.5M + 💎50                    │
│                                               │
└───────────────────────────────────────────────┘
```

### Componentes

1. **Timer de próximo giro grátis**
   - Formato: HH:MM:SS
   - Cor: `#FFD700` se ≤1h, else `#B0B0B0`

2. **Roda (Spinner Visual)**
   - Círculo com 8 segmentos (diferentes recompensas)
   - Cada segmento: cor distinta, ícone, label
   - Animação: rotação suave ao girar (CSS transform rotate)
   - Ponteiro fixo no topo

3. **Botões de Giro**
   - [GIRAR GRÁTIS]: ativo se timer = 0, else disabled
   - [GIRAR +3]: pago em moeda de jogo (não Robux)
   - [GIRAR +10]: lote com desconto

4. **Resultado**
   - Aparece 2s após o giro
   - Animação: zoom + brilho
   - Formato: "Você ganhou: {item 1} + {item 2}"

---

## BÊNÇÃO DIÁRIA

### Overview

Login streak de 7 dias com recompensas crescentes.

**Acesso:** Aba "Bênção Diária" na tela inicial / HUD  
**Ciclo:** resets às 00:00 (horário do servidor)

### Tela

```
┌─ BÊNÇÃO DIÁRIA ────────────────────────────────┐
│                                               │
│  Dia 5 de 7 — Volte amanhã pra continuar     │
│                                               │
│  [Day 1]  [Day 2]  [Day 3]  [Day 4]  [Day 5] │
│   $10K    $50K     $200K    💎25     ✓✓      │
│    ✓       ✓        ✓        ✓       HOJE    │
│                                               │
│  [Day 6]  [Day 7]                            │
│   $500K   📦Pack                             │
│    ?       ?       (próximas)                │
│                                               │
│  ⏰ Próxima recompensa em: 18:30:45           │
│                                               │
│  [REIVINDICAR AGORA] (se pronto) ou timer   │
│                                               │
│  Streak atual: 5 dias (não quebrada)          │
│  ⚠️ Quebrará se não voltar em 48h             │
│                                               │
└───────────────────────────────────────────────┘
```

### Componentes

1. **Progress Visual**
   - 7 boxes em linha
   - Box 1-5: preenchidas com checkmark + recompensa já reclamada
   - Box 6-7: cinzenta (futura) com ícone de "?"
   - Box atual: destaca com borda `#FFD700`

2. **Timer pra próxima recompensa**
   - Aparece sempre
   - Contraste alto se ≤30min pra poder reclamar

3. **Botão de Ação**
   - [REIVINDICAR AGORA]: se passou de 24h desde último login
   - Timer: se ainda não passou

4. **Aviso de Streak**
   - "Streak: 5 dias" em verde
   - "⚠️ Quebrará em 48h" em laranja se próximo

---

## NÍVEL & DESAFIOS

### Overview

Sistema onde desafios geram XP e Nível (não XP genérico).

**Acesso:** Clicando no Nível no HUD  
**Saída:** Voltar

### Tela

```
┌─ DESAFIOS & PROGRESSO ────────────────────────┐
│                                               │
│  Nível 42 — 1.200 / 5.000 XP pra Nível 43   │
│  [████████░░░░░░░░░░] 24%                    │
│                                               │
│  DESAFIOS DO NÍVEL ATUAL (últimos 7 dias):  │
│                                               │
│  ┌─ FÁCIL (500 XP) ──────────────────────┐   │
│  │ Abrir 5 pacotes da Loja               │   │
│  │ Progresso: 2/5 ✓✓░░░ [████░░]       │   │
│  │ Status: Em Progresso                  │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  ┌─ NORMAL (1.500 XP) ───────────────────┐   │
│  │ Evoluir 1 criatura para Ouro          │   │
│  │ Progresso: 0/1 ░ [░░░░░░]            │   │
│  │ Recompensa: 🎁 Pack Especial         │   │
│  │ Status: Pendente                      │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  ┌─ DIFÍCIL (3.000 XP) ──────────────────┐   │
│  │ Atingir 10 criaturas em Grau 9.0      │   │
│  │ Progresso: 3/10 ███░░░░░░░ [███░░░░]│   │
│  │ Status: Em Progresso                  │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  [DESAFIOS COMPLETADOS ESTE MÊS: 12]        │
│                                               │
└───────────────────────────────────────────────┘
```

### Componentes

1. **Progress de Nível**
   - "Nível {num}" em grande (22px)
   - Barra de XP: `{atual} / {max} XP`
   - % até próximo nível

2. **Desafios Ativos**
   - Cada card tem:
     - Dificuldade (cor-codificada: verde fácil, amarelo normal, vermelho difícil)
     - Descrição breve
     - Barra de progresso
     - Status (Em Progresso, Pendente, Completado!)
     - Recompensa (texto + ícone)
   - Max 3-4 ativos simultaneamente
   - Scroll se mais

3. **Desafios Completados**
   - Contador no fundo: "Completados este mês: 12"
   - Link pra histórico (opcional)

---

## GAMEPASSES & DEV PRODUCTS

### Overview

Loja monetizada com Gamepasses (assinatura) e Dev Products (compra única).

**Acesso:** Botão "Loja" no HUD  
**Saída:** Voltar

### Estrutura

```
┌─ LOJA ────────────────────────────────────────┐
│                                               │
│  [ABAS] Gamepasses | Dev Products             │
│                                               │
│  ┌─ GAMEPASSES ──────────────────────────┐    │
│  │ Cada linha: [ícone] Nome | Desc | Preço   │
│  │                                       │    │
│  │ VIP                                   │    │
│  │ +20% $/s em todos os slots            │    │
│  │ $4.99 / mês  [ASSINAR]               │    │
│  │                                       │    │
│  │ Coleta Automática                     │    │
│  │ Renda é coletada automaticamente      │    │
│  │ $2.99 / mês  [ASSINAR]               │    │
│  │                                       │    │
│  │ ... (9 total) ...                    │    │
│  └───────────────────────────────────────┘    │
│                                               │
│  ┌─ DEV PRODUCTS ────────────────────────┐    │
│  │ Cada linha: [ícone] Nome | Preço      │    │
│  │                                       │    │
│  │ Diamante ×100                         │    │
│  │ $0.99  [COMPRAR]                     │    │
│  │                                       │    │
│  │ Diamante ×500 (Melhor Valor!)        │    │
│  │ $4.99  [COMPRAR]                     │    │
│  │                                       │    │
│  │ ... (4 total) ...                    │    │
│  └───────────────────────────────────────┘    │
│                                               │
│  ⚠️ ODDS OBRIGATÓRIAS:                        │
│  Alguns itens podem conter elementos         │
│  aleatórios. Veja as odds abaixo.            │
│  [Ver Odds] (linked ao painel de odds)       │
│                                               │
└───────────────────────────────────────────────┘
```

### Componentes

1. **Sistema de Abas**
   - "Gamepasses" | "Dev Products"
   - Design: botões/tabs simples

2. **Card de Gamepass**
   - Layout: `[ícone 32px] | Título + Desc | Preço | [ASSINAR]`
   - Ícone: cor temática (ex: VIP = dourado)
   - Título: 14px bold
   - Desc: 11px, `#B0B0B0`
   - Preço: 12px mono, `#27AE60` (verde = custa $)
   - Botão: fundo `#27AE60`, texto branco
   - Se já tem: [CANCELAR] em lugar de [ASSINAR]

3. **Card de Dev Product**
   - Layout: `[ícone] | Nome | Preço | [COMPRAR]`
   - Preço: USD (ex: $0.99)
   - Botão: fundo `#FFD700` (ouro, destaca monetização)
   - Badge "Melhor Valor" em alguns

4. **Odds Obrigatórias**
   - Texto de aviso simples
   - Link "[Ver Odds]" abre modal detalhado
   - Modal mostra tabela: Item | % de chance

---

## NOTIFICAÇÕES & POPUPS

### Estilos Globais

**Toast Notification (canto inferior direito)**
```
┌──────────────────────────────┐
│ ✓ Criatura vendida!          │
│ Ganhou: $480K                │
└──────────────────────────────┘
```

- Altura: 60px
- Background: `#27AE60` (sucesso verde)
- Cor texto: `#FFFFFF`
- Font: 13px
- Duration: 3-4 segundos (auto-close)
- Shadow: shadow-md
- Apareça de baixo → cima (animação)
- Stacking: até 3 simultâneas, depois queue

**Modal de Confirmação (overlay centralizado)**
```
╔════════════════════════════════╗
║  Confirmar Venda               ║
╠════════════════════════════════╣
║                                ║
║  Tem certeza que quer vender   ║
║  Fênix Solar por $480K?        ║
║                                ║
║  [VENDER] [CANCELAR]           ║
║                                ║
╚════════════════════════════════╝
```

- Background overlay: `rgba(0, 0, 0, 0.6)`
- Modal box: `#1A2332`, border `1px solid #707070`, border-radius 8px
- Padding: 20px
- Max-width: 400px
- Z-index: 1000 (acima de tudo)
- Botões: [Confirmar] primário (cor temática), [Cancelar] secundário (cinzento)

**Tooltip (hover)**
```
Renda por segundo
(todos os slots)
```

- Background: `#2A4158`
- Cor texto: `#FFFFFF`
- Font: 11px
- Padding: 6px 10px
- Border-radius: 3px
- Arrow pointer ao alvo
- Delay: 200ms antes de aparecer

---

## ANIMAÇÕES & TRANSIÇÕES

### Padrões Globais

| Elemento | Animação | Duração | Easing |
|----------|----------|---------|--------|
| Card aparece | fade-in + translate-up | 200ms | ease-out |
| Card desaparece | fade-out + translate-down | 150ms | ease-in |
| Botão hover | color change + scale 1.02 | 100ms | ease-in-out |
| Botão press | scale 0.98 | 100ms | ease-in-out |
| Scroll de página | smooth scroll | 300ms | ease-out |
| Modal abre | fade-in + scale 0.8→1 | 250ms | ease-out |
| Modal fecha | fade-out + scale 1→0.8 | 200ms | ease-in |
| Level-up badge | scale pulse | 400ms (1 ciclo) | ease-in-out |
| Barra de progresso | fill animado | 600ms | ease-out |

### Animações Específicas por Tela

#### Loja de Pacotes — Abertura de Pacote

1. **Fade out da tela anterior** (150ms)
2. **Zoom + brilho na carta** (600ms)
   - Scale 0.3 → 1.0
   - Opacity 0 → 1
   - Glow/shadow aumenta
3. **Exibir resultado** (estático, 2s)
4. **Fade out do resultado** (200ms)
5. **Transição pra próxima tela** (fade-in, 150ms)

#### Álbum — Grid de Criaturas

- Ao entrar na tela: grid aparece com stagger (cada card 50ms depois do anterior)
- Ao filtrar: cards saem com fade-out (100ms), novos entram com fade-in (100ms)
- Transição suave sem salto visual

#### Roda do Destino — Spinner

- Rotação contínua suave durante o giro (2000ms, linear)
- Desaceleração gradual no final (easing ease-out)
- Resultado aparece com scale pulse (400ms)

#### Despertar — Roll de Grau

- Antes: card com border cinzento
- Durante roll (1s): card brilha, número "flutua" up (animação de valores flutuando)
- Depois: card com border dourada (se melhorou de grau)
- Feedback sonoro: "ding" ao completar

---

## 🎯 CHECKLIST DE IMPLEMENTAÇÃO (Fase 5)

### Sprint 1 — Infraestrutura (1 semana)
- [ ] Screen hierarchy definida (Lobby → Loja → Álbum → etc.)
- [ ] ScreenGui + Frame templates (dark theme)
- [ ] Input handler (remotes, validações client)
- [ ] Sistema de transição entre telas (fade, slide)

### Sprint 2 — HUD + Loja (2 semanas)
- [ ] HUD permanente (header com saldo/nível/⚙️)
- [ ] Estrutura de abas na Loja
- [ ] Grid de pacotes + componente de linha
- [ ] Painel de odds
- [ ] Integração com PackService

### Sprint 3 — Álbum + Mochila (2 semanas)
- [ ] Grid de criaturas (300 cards)
- [ ] Filtros + busca
- [ ] Modal de preview
- [ ] Integração com AlbumService

### Sprint 4 — Sistemas Diversos (2 semanas)
- [ ] Altar de Sacrifício
- [ ] Tela de Venda
- [ ] Roda do Destino
- [ ] Bênção Diária
- [ ] Desafios/Nível

### Sprint 5 — Polimento (1 semana)
- [ ] Animações finais
- [ ] Responsividade mobile
- [ ] Tooltips e hints
- [ ] Testes de usabilidade
- [ ] Acessibilidade (fontes, contraste)

---

## 📝 NOTAS FINAIS

- **Responsive Design:** Testar em 3 breakpoints: 300px (mobile), 768px (tablet), 1200px (desktop)
- **Performance:** Lazy load de imagens, pool de UI elements pra não criar/destruir constantemente
- **Acessibilidade:** High contrast, font sizes ≥ 10px, tap targets ≥ 44px mobile
- **Testes:** Validar fluxos críticos (abertura de pacote, venda, Renascimento) antes de polonês visual

**Documentação gerada**: 19 de Julho de 2026  
**Próxima revisão**: Durante Sprint 1 (feedback do desenvolvimento real)
