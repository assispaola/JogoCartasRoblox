# CLAUDE.md — JogoCartasRoblox

Contexto persistente do projeto. Lido automaticamente pelo Claude Code no início de
toda sessão nesta pasta — não precisa reexplicar isso no chat.

## O que é o projeto

Jogo de Roblox tipo simulador incremental de cartas colecionáveis, com identidade
100% original (sem IP licenciada). Tema: criaturas mitológicas reais de várias
culturas do mundo, organizadas em 15 clãs elementais. Loop principal: abrir
pacotes → acumular cópias de criaturas (Álbum, raridade sobe/desce sozinha) →
gerar renda passiva → prestígio (Renascimento via Altar de Sacrifício).

**Regra inegociável:** nenhum personagem de anime/jogo/IP protegida. Tudo é
mitologia de domínio público ou conteúdo 100% original.

## Stack

- **Engine:** Roblox Studio
- **Linguagem:** Luau (`--!strict` nos módulos de dados puros em `shared/Data/`;
  os serviços de servidor em `server/Systems/` normalmente NÃO usam `--!strict`
  porque tocam direto na tabela solta que `PlayerDataService.GetData()` devolve)
- **Sync:** Rojo (projeto vive fora do Studio, em `D:\JogoCartasRoblox`, não em
  pasta sincronizada com nuvem — evita conflito de sync do Rojo)
- **Versionamento:** GitHub
- **Fonte de verdade dos dados de conteúdo:** `docs/Cartas_Miticas_Clans_e_Criaturas_REVISADA.xlsx`
  (15 clãs, 300 criaturas base, sistema de raridade, matriz de 1.800 combinações,
  15 criaturas Divinas). Confirmado batendo com o código (raridades, cores de
  clã, curva de Despertar, Diamante do Índice) em 12/09/2026 — **exceção: a
  aba "Pacotes - Catálogo" dessa planilha e o arquivo separado
  `docs/Catalogo_Pacotes_Cartas_Miticas.xlsx` ainda têm o modelo antigo de 62
  pacotes; a fonte de verdade real de pacotes hoje é `PackCatalog.lua` (77
  pacotes) + `docs/GAME_DESIGN_CARTAS_MITICAS_v3.md`, não essas planilhas.**
  `docs/Icons_Registry_Corrigido.xlsx` também está desatualizado/desconectado
  — pelo menos 2 IDs conferidos (`Album`, `Altar`) não batem com os valores
  reais em `Icons.lua`; não usar essa planilha como fonte pra novos ícones.

## Estrutura de pastas (Rojo) — real, atualizada

```
src/
├── shared/
│   ├── Data/                    -- módulos de dados puros (--!strict, sem lógica de servidor)
│   │   ├── Clans.lua            -- 15 clãs + cor oficial (Clans.Order/ByName)
│   │   ├── Creatures.lua        -- 300 criaturas base (id numérico = chave)
│   │   ├── Rarities.lua         -- 8 raridades + Despertar + fórmula de valor (fonte canônica de RarityId)
│   │   ├── AlbumEvolutionCurve.lua -- thresholds acumulados de raridade (função contínua)
│   │   ├── DivineCreatures.lua  -- 15 criaturas Divinas (1 por clã)
│   │   ├── PackCatalog.lua      -- 77 pacotes (odds em chaves ASCII, ver "Grafia" abaixo)
│   │   ├── PackOddsRoller.lua   -- sorteio de raridade/clã/criatura + tradução de grafia
│   │   ├── RenascimentoCatalog.lua -- Prova do Renascimento por ciclo
│   │   ├── ChallengeCatalog.lua, WheelCatalog.lua, PortalCatalog.lua,
│   │   │   DailyBlessingCatalog.lua, JourneyChestCatalog.lua, GamepassCatalog.lua
│   │   └── CreatureArtIds.lua
│   ├── Networking/Remotes.lua   -- registro central de todos os RemoteEvents
│   └── UI/
│       ├── CardFrameBuilder.lua -- moldura metálica por raridade (Default..Mítico),
│       │   direto de docs/game-design/moldura_refinada_8tiers.html
│       └── Components/          -- Button, Chip, IconButton, ProgressBar, StatBadge,
│           SquareIconButton, PillActionButton (peças de UI reutilizáveis, HUD v2)
├── server/
│   ├── Main.server.lua          -- ponto de entrada: Init() de todos os serviços, autosave, snapshot
│   ├── Debug/DebugTest.server.lua -- script de teste manual (apagar quando não precisar mais)
│   └── Systems/                 -- lógica de servidor (nome real da pasta - NÃO é "Services")
│       ├── PlayerDataService.lua -- único ponto de acesso ao DataStore + migração de saves antigos
│       ├── AlbumService.lua     -- fonte da verdade de raridade/grau por criatura (ver seção própria)
│       ├── AltarSacrificioService.lua -- staging da Prova de Renascimento
│       ├── InventoryService.lua -- Mochila (por criatura) + Slots de Base
│       ├── EconomyService.lua   -- $/s, coleta, renda offline
│       ├── SellService.lua      -- venda de cópias (20% fixo)
│       ├── PackService.lua      -- compra/abertura de pacotes, ladder Geral, Robux
│       ├── RenascimentoService.lua -- Prova + reset (só Dinheiro)
│       ├── LevelService.lua     -- Desafios de Nível (motor de requisito genérico)
│       ├── TradeService.lua / DonationService.lua -- troca/doação entre jogadores
│       ├── AutoSellService.lua, HandService.lua, GamepassService.lua,
│       │   SnapshotService.lua, StatsService.lua, PortalService.lua,
│       │   WheelService.lua, DailyBlessingService.lua, JourneyChestService.lua
│       └── FusionService.lua, DespertarService.lua -- OBSOLETOS (ver abaixo), mantidos sem uso
└── client/
    ├── Main.client.lua          -- ponto de entrada do client (HUD v2, ver README.md)
    ├── HUDTest.client.lua       -- script de teste manual do HUD
    └── UI/
        ├── Cards/ClanBorderColors.lua, DivineBorder.lua -- borda arco-íris do
        │   Divino, direto de docs/game-design/moldura_carta_divino.html
        └── HUD/                 -- BottomBar, HUDController, TopBar, Sidebar,
            Progress, MoneyCounter (arquitetura "HUD v2", ver README.md pro
            detalhe de cada componente e o que falta ligar no backend)
```

*(Se a estrutura real divergir disso, corrigir este arquivo — o objetivo é ela
sempre refletir a pasta de verdade.)*

## Arquitetura de 3 camadas (Álbum / Mochila / Slots de Base)

Substitui o modelo antigo de "cartas individuais por cópia" (`FusionService`,
Despertar por cardId). Tudo agora é **por criatura descoberta** (`creatureId`),
não por cópia física:

- **Álbum** (`AlbumService.lua`, `data.album[creatureId] = { totalCopias, grau }`)
  — fonte da verdade de cópias acumuladas e grau de Despertar. **Raridade não
  é armazenada** — é sempre derivada de `totalCopias` via
  `AlbumEvolutionCurve.RarityForTotalCopies` (função contínua, ver seção de
  Raridade abaixo), a mesma conta serve tanto pra subir quanto pra descer.
  Também dispara o Diamante de descoberta (o antigo "Índice" foi consolidado
  aqui, não é mais um serviço separado).
- **Mochila** (`data.mochila[creatureId] = { favorito, noSlot }`) — 1 registro
  por criatura descoberta (capacidade em `data.maxCards`, 200 base, gamepass
  "Mochila +500"). Lê raridade/grau do Álbum, nunca guarda cópia própria
  desses dados.
- **Slots de Base** (`data.placedSlots[slotId] = creatureId`) — só cartas aqui
  geram $/s. Teto fixo em `data.maxPlacedSlots` (20 base, gamepass "Slots de
  Base +5" via `data.gamepasses.slotsExtras`), independente de nível/Renascimento.

**Altar de Sacrifício** (`AltarSacrificioService.lua`, `data.altarSacrificio.staged[creatureId] = quantidade`)
— staging manual (com QUANTIDADE por criatura, não booleano) das cópias que
servem de prova de Renascimento; substitui a escolha automática que existia
antes. Ver seção própria de Renascimento abaixo pros detalhes da Prova.

`FusionService.lua` e `DespertarService.lua` ficam no repo como referência
histórica (OBSOLETOS: o corpo de suas funções públicas foi substituído por um
stub que retorna erro, com a lógica original preservada em bloco de
comentário — não são mais chamados por `Main.server.lua`). Não usar como base
pra código novo:
- Fusão manual de duplicatas → `AlbumService` (evolução automática, função
  contínua).
- Despertar por `cardId` → `AlbumService.RollDespertar(player, creatureId)`
  (grau por criatura).

`RelicarioService.lua` foi **removido** do projeto (não apenas depreciado, o
arquivo não existe mais): sob o Álbum, nada é perdido no Renascimento, então
não há mais o que proteger. Foram removidos junto: gamepass "Relicário +5"
(`bancoExtra`), campos `data.relicario`/`data.relicarioSlots`, e os remotes
`MoveToRelicarioRequest`/`MoveFromRelicarioRequest`/`RelicarioResult`.

**DataStore:** `PlayerData_v2`, com preenchimento automático de campos novos no
load (nunca resetar versão por causa de evolução de schema — ver
`createDefaultData()`/`LoadData()` em `PlayerDataService.lua`). Saves antigos
(modelo por cópia, `data.cards`/`data.relicario`) migram automaticamente pro
Álbum/Mochila na primeira carga, uma única vez, de forma idempotente (ver
`migrateCardsToAlbum` em `PlayerDataService.lua`) — a raridade migrada é
aproximada pelo PISO da maior raridade já alcançada (não há como recuperar o
histórico exato de cópias do modelo antigo).

### Venda, Troca e Doação — todas operam em "unidades de progresso"

Não existem mais objetos de carta individuais pra mover entre estruturas.
Vender, doar ou trocar uma "cópia" de uma criatura significa, por baixo dos
panos, chamar `AlbumService.RemoverPontos(player, creatureId, quantidade)` (no
doador/vendedor) e, se aplicável, `AlbumService.RegistrarCopia(destinatário,
creatureId, raridadeAtual)` (no receptor) — a mesma matemática de decremento/
incremento de `totalCopias` que já é usada em todo o resto do sistema.

- **`SellService.VenderCopias(player, creatureId, quantidade)`** — 20% fixo do
  valor de mercado (`SELL_PERCENTAGE`), sempre calcula um preview
  (`PreviewVenda`/`AlbumService.PreviewRemoverPontos`) antes de aplicar de
  verdade. Downgrade de raridade acontece sozinho (é só a função contínua
  recalculando com `totalCopias` menor).
- **`DonationService.TryDonate`** — doa 1 unidade de progresso pra outro
  jogador, na raridade atual da criatura.
- **`TradeService`** — sessão de troca com confirmação dupla; cada oferta é
  por `creatureId` (não mais `cardId`), executa como transferência de 1
  unidade por criatura ofertada, dos dois lados.
- **`AutoSellService`** — só o toggle de configuração existe hoje
  (`ShouldAutoSell`/`SetToggle`); a reinterpretação "vender excedente pós-
  Mítico" está implementada em `SellService.TryAutoSellPostMitico`, mas
  **isolada e desligada** (`FEATURE_AUTOSELL_POST_MITICO = false`) até
  confirmar com a Paola.

## Sistemas já implementados (server-side)

Economia e renda passiva, Álbum/Mochila/Slots de Base (ver acima), catálogo de
77 pacotes (religado de verdade ao `AlbumService` — ver nota do `PackService`
abaixo), sistema de nível com desafios gerados por fórmula, Renascimento
(prestígio, reset só de Dinheiro) via Altar de Sacrifício, Bênção Diária, Baús
da Jornada, Roda do Destino, Pacto dos Guardiões (doação/troca com
anti-exploit), auto-venda, Equipar Melhor, snapshot completo do jogador.

**`PackService.lua`**: antes desta sessão era um scaffold nunca ligado de
verdade (`Init()` esperava argumentos que `Main.server.lua` nunca passava, e
chamava um método `Inventory:GrantCard` que não existia em lugar nenhum).
Consertado pra usar os serviços reais direto (mesmo padrão de `require` do
resto do projeto): `CreatureProvider` real sobre `Creatures.lua` (sorteia
uniformemente entre as ~20 criaturas do clã, ignorando `rarity` no parâmetro —
raridade não é uma propriedade fixa da criatura, é progresso do jogador),
`OpenPack`/`ProcessReceipt`/`GrantFreePack` chamam `AlbumService.RegistrarCopia`
direto. Bloqueia a abertura ANTES de cobrar se a Mochila estiver cheia (não
perde carta nem moeda).

## Convenções de nomenclatura (manter em português, sempre)

| Termo no código | Significado |
|---|---|
| Álbum | fonte da verdade de cópias acumuladas (`totalCopias`) e grau por criatura (`AlbumService.lua`) — raridade é sempre derivada, nunca armazenada |
| Despertar | sistema de grau (7.0–10.0) que multiplica valor/stats, 1 por criatura, independente da raridade |
| Mochila | 1 registro por criatura DESCOBERTA (não por cópia), organização/colocação na base |
| Slots de Base | onde as criaturas equipadas geram $/s, teto fixo independente de Renascimento |
| Altar de Sacrifício | staging manual (com quantidade) de criaturas pra prova de Renascimento |
| Renascimento | prestígio/reset (só Dinheiro) com bônus permanente de $/s |
| Portal da Sorte | evento global de servidor |
| Bênção Diária | recompensa por streak de login (força raridade Default) |
| Baús da Jornada | recompensa por marco de tempo jogado |
| Roda do Destino | spin wheel a cada 30min |
| Pacto dos Guardiões | doação/troca bilateral entre jogadores |

## Sistema de Raridade + Despertar (referência rápida)

8 raridades: Default(×0.4, só via Bênção Diária) → Bronze(×1) → Prata(×6) →
Ouro(×18) → Platina(×50) → Lendário(×150) → Mítico(×500) → **Divino(×10.000)**.

**Raridade é uma função contínua, não um contador que reseta.** Cada
criatura guarda só `totalCopias` (`AlbumService`/`data.album[creatureId]`) —
sobe com pacote/Atalho, desce com venda/sacrifício. A raridade é sempre
recalculada a partir do total atual via `AlbumEvolutionCurve.RarityForTotalCopies`,
comparando contra os thresholds ACUMULADOS de entrada (`AlbumEvolutionCurve.lua`):
Default 0 → Bronze 5 → Prata 15 → Ouro 30 → Platina 55 → Lendário 90 →
Mítico 140 (teto do Álbum). Cruzar um threshold pra cima OU pra baixo usa a
MESMA função — sem fluxos separados de "evoluir" vs. "rebaixar". Exemplos:
total=5 cópias → Bronze; total=4 → Default; total=7 (Bronze), sacrifica 1 →
total=6 → continua Bronze (ainda dentro de 5–14).

Um pull de pacote de alta raridade funciona como um PISO (substitui o antigo
conceito de "Atalho"): `totalCopias = max(atual + 1, pisoDaRaridadeSorteada)`
— um Mítico sortudo ainda salta a criatura direto pra Mítico, dentro do mesmo
cálculo único (sem fluxo especial).

Despertar: 1 grau por CRIATURA (não mais por cópia), "vazio" (sem badge de UI)
até 7.0(×1.05)–10.0(×2.5). Independente da raridade — não muda quando o
totalCopias sobe/desce e a raridade calculada muda junto. Rolado via
`AlbumService.RollDespertar(player, creatureId)` (substitui
`DespertarService.TryAwaken`), custo **fixo de 15 diamantes por tentativa,
sempre, não importa a raridade** (`AWAKEN_COST` em `AlbumService.lua`).
Resultado sempre substitui o grau atual, pra melhor ou pra pior.

⚠️ **`Rarities.lua` tem um campo `awakenCostDiamonds` por raridade (800 a
10.000) que é MORTO — não é lido por nenhum código real.** O custo de
verdade é o flat de 15💎 acima. Não usar esse campo como referência de
custo; existe só porque nunca foi removido da tabela.

Fórmula de valor: `seedValue × 1000 (fator de escala) × multRaridade × multGrau
× multRenascimento`. Ver `Rarities.lua` pra implementação exata — é a fonte de
verdade, não recalcular à mão.

**Grafia:** `Rarities.lua` usa IDs acentuados (`"Default"`, `"Lendário"`,
`"Mítico"`) — é a fonte canônica de `RarityId`. `PackCatalog.lua`/
`PackOddsRoller.lua` usam chaves ASCII sem acento (`Lendario`, `Mitico`)
porque Luau não aceita acento em nome de campo bareword (só via
`["Lendário"] = ...`, o que deixaria os 77 pacotes ilegíveis); a tradução
acontece em `PackOddsRoller.ToCanonicalRarityId`, chamada no ponto onde o
resultado do pacote cruza a fronteira pro `AlbumService`.

## Renascimento + Altar de Sacrifício (regra final)

**Prova do Renascimento — 3 requisitos simultâneos** (todos exigidos ao mesmo
tempo pro botão "Renascer" habilitar, gerados por `RenascimentoCatalog.GetRequirements(renascimentoLevel)`):

1. **Sacrificar 3 cartas de um clã sorteado** (`sacrificeCardsByClan`) —
   escolha livre de QUAIS 3 criaturas daquele clã sacrificar, não é uma
   criatura fixa. Clã sorteado deterministicamente por ciclo
   (`Clans.Order[(renascimentoLevel % 15) + 1]`).
2. **Sacrificar 1 cópia de uma criatura ESPECÍFICA** (`sacrificeSpecificCreature`)
   — fixa, mesma pra todo mundo no servidor naquele ciclo (torna troca/doação
   valiosa entre jogadores).
3. **Saldo mínimo de Dinheiro** (`money`) — checagem simples, NÃO passa pelo
   Altar (não é sacrificado, só precisa estar disponível no momento de
   confirmar). Curva CONVEXA e agressiva (`calculateMoneyRequirement` em
   `RenascimentoCatalog.lua`: `BASE * GROWTH ^ (n ^ CONVEXIDADE)`) —
   ⚠️ parâmetros ainda não validados com a Paola, só a estrutura.

Os itens 1 e 2 passam pelo **Altar de Sacrifício** (`AltarSacrificioService.lua`):
staging por QUANTIDADE (`StageCreature(player, creatureId, quantidade)`, não
booleano), `GetAltarStatus` cruza o que está staged com os 2 requisitos de
sacrifício (com cuidado explícito pra NÃO contar a mesma cópia staged duas
vezes se a criatura específica do item 2 também pertencer ao clã do item 1),
`ConsumeStagedForProva` consome de verdade (via `AlbumService.RemoverPontos`)
só quando chamado por `RenascimentoService.TryRenascer` depois de validar
tudo. Sacrifício no Altar **não paga nada em $** (diferente da venda normal,
que dá 20%) — suposição assumida na implementação, ⚠️ não fechada com a Paola.

**O que reseta:** só `data.money` (zerado a 0). Nível, stats, Álbum e Mochila
persistem incondicionalmente — corrige uma inconsistência do código antigo
(`data.stats` já era documentado como "nunca reseta" mas o `RenascimentoService`
antigo resetava mesmo assim). `data.highestUnlockedGeneralPackId` (ladder
Geral) também nunca é tocado pelo reset, propositalmente.

**Multiplicador permanente:** `renascimentoMultiplier = 1.0 + renascimentoLevel * 0.1`
(+10%/ciclo), aplicado no total de $/s em `EconomyService.RecalculateIncomePerSecond`.

## Divino — status atual (adicionado recentemente, pode ter partes pendentes)

7ª raridade (8ª contando Default), 15 cartas fixas (1 por clã), sem fusão, só
via pacote de evento (`PortalDivino`, único pacote com odds de Divino = 100%).
Identidade visual fixa independe do clã. Borda de UI: arco-íris saturado
(magenta → dourado → ciano → violeta), girando (`DivineBorder.lua`, atualizado
em 12/09/2026 pra bater com `docs/game-design/moldura_carta_divino.html` —
substituiu uma versão anterior prata/pastel). As bordas metálicas das outras 7
raridades (Default..Mítico) vêm de `CardFrameBuilder.lua`, direto de
`docs/game-design/moldura_refinada_8tiers.html` (também atualizado em
12/09/2026); ambos os mockups em `docs/game-design/` já estão implementados,
não são mais referência pendente.

**Pendências conhecidas** (checar se já foram feitas antes de reimplementar):
- Excluir Divino do sorteio de pacote normal (só deve sair em pacote de evento
  dedicado, ainda não criado)
- Criar o Pacote de Evento que sorteia entre as 15 `DivineCreatures`
- Verificar se o `PlayerData_v2` precisa de campo novo pra marcar Divinas
  descobertas (bônus de Diamante do Índice)
- Artes finais das 15 Divinas (prompts prontos, mas nem todas foram geradas)

## Cores dos clãs (fonte de verdade: `Clans.lua`)

Não recalcular ou "arredondar" cores sem confirmar — algumas já foram testadas
e aprovadas com arte real (marcadas como "Fechado" na planilha), outras ainda
são propostas sem teste. `Chama Vulcânica = #3D0F17` — a revisão de matiz
(conflito com Forja Ígnea) foi resolvida na auditoria de 19/07/2026 (era
`#66192B`; ver `docs/archive/2026-07-19-auditoria-v3.md`), não é mais
pendência em aberto.

## Decisões ainda pendentes (não assumir sozinho, ver flags no código)

- **Sistema de Tier C/B/A** (Comum/Nobre/Ancestral — seedValue e custo de
  Despertar por tier, `docs/GAME_DESIGN_CARTAS_MITICAS_v3.md` seção 3): está
  especificado no design mas **não implementado** — não existe `Tiers.lua`
  (chegou a existir, foi removido de novo numa reorganização posterior),
  criaturas não têm campo `tier`, e o Despertar usa custo fixo de 15💎 (ver
  seção de Despertar acima) em vez de escalar por tier. Confirmado com a
  Paola em 12/09/2026: é **trabalho incompleto**, não abandono de design —
  ainda precisa ser implementado quando entrar na Fase 5/6.
- **UX do downgrade ao vender**: automático e silencioso vs. modal de aviso
  mostrando o resultado antes de confirmar (Fase 5/UI).
- **Criatura vendida/sacrificada até 0 cópias**: some do Álbum/Mochila
  (libera capacidade) ou fica "descoberta pra sempre"? Função isolada e
  DESLIGADA por padrão: `AlbumService.RemoverSeVazio`,
  `FEATURE_REMOVE_ON_ZERO_COPIES = false`.
- **Venda Automática pós-Mítico**: `SellService.TryAutoSellPostMitico`,
  `FEATURE_AUTOSELL_POST_MITICO = false`.
- **Mochila cheia + descoberta nova ao abrir pacote**: hoje bloqueia a compra
  ANTES de cobrar (default seguro); UX final (o que oferecer ao jogador
  nesse caso) ainda não decidida.
- **Sacrifício no Altar não paga $**: suposição assumida na implementação,
  não confirmada.
- **Parâmetros exatos da curva convexa** da quantia mínima de Dinheiro do
  Renascimento: só a estrutura foi definida.

## Bugs pré-existentes conhecidos (não corrigidos, fora de escopo das últimas sessões)

- `WheelService.lua`, `DailyBlessingService.lua`, `JourneyChestService.lua`
  chamam `PackService.GrantFreePack(player, packId)` passando um `packId`
  vindo de um `PackCatalog.Order`/`PackCatalog.Packs[packId]` de um modelo
  antigo (tier+clã) que não existe mais no `PackCatalog.lua` atual (77
  pacotes, sorteio uniforme de clã, indexado por `Key` string). Precisam ser
  migrados pra passar uma `Key` válida do catálogo atual.
- `MarketplaceService.ProcessReceipt` é atribuído tanto em
  `PackService.Init()` quanto em `GamepassService.Init()` — como
  `Main.server.lua` chama os dois, só o último a rodar (`GamepassService`)
  fica valendo, e a compra de pacotes via Robux nunca chega a processar.
  Precisa de um dispatcher único que combine os dois fluxos de recibo.

## Fonte da verdade e manutenção de docs

Fontes da verdade vivas deste projeto, nesta ordem de precedência quando
houver conflito (código sempre vence sobre doc — se divergir, o doc está
desatualizado, não o código):

1. **O código em `src/`** — sempre a verdade sobre o que o jogo faz hoje.
2. **`CLAUDE.md`** (este arquivo, na raiz do projeto) — visão operacional do
   estado atual.
3. **`docs/GAME_DESIGN_CARTAS_MITICAS_v3.md`** — spec de design/números
   (raridades, pacotes, clãs, economia, Renascimento, Tier C/B/A pendente de
   implementação).
4. **`docs/UI_TELAS_DESENVOLVIMENTO.md`** — spec de telas/UI (Mochila, Álbum,
   Altar, Venda, Pacto, Roda, Bênção, Nível). Ainda é a direção vigente
   (confirmado 12/09/2026), mesmo com a reescrita "HUD v2" em andamento
   (ver `README.md`) — as duas coisas não são conflitantes: HUD v2 é a
   arquitetura de componentes, esse doc é a spec de conteúdo/layout de cada
   tela.
5. **`docs/game-design/*.html`** — referência visual (mockups de moldura de
   carta/borda), não spec funcional. `moldura_carta_divino.html` e
   `moldura_refinada_8tiers.html` já estão implementados (ver seção Divino
   acima); `card_ui_proposta_v4.html`, `conceito_slots_spec.html` e
   `conceito_slots_topdown.html` ainda são referência futura.
6. **`docs/*.xlsx`** — fonte de dados de conteúdo (criaturas/clãs/raridade),
   com as exceções de pacotes e ícones documentadas na seção "Stack" acima
   (essas duas planilhas ficaram pra trás do código).

`docs/CHANGELOG.md` é histórico (log), não fonte da verdade sobre o estado
atual — não usar pra saber "como o sistema funciona hoje", só "o que mudou e
quando". Relatórios de auditoria e checklists datados vivem em
`docs/archive/` e nunca devem ser tratados como spec atual (são fotografia de
um momento específico, não algo a manter sincronizado).

**Regra de workflow:** sempre que uma mudança de sistema for implementada
(nova mecânica, novo valor numérico balanceado, nova cor/UI aprovada), os
docs relevantes da lista acima precisam ser atualizados **na mesma sessão**,
não depois. Não deixe a documentação acumular divergência do código de novo
— se não der tempo de atualizar o doc certo, pelo menos deixe uma nota em
`docs/CHANGELOG.md` sinalizando a divergência pendente.

## Workflow esperado

1. Antes de alterar algo, ler o arquivo relevante primeiro (não assumir
   estrutura de dados sem checar)
2. Se uma mudança de sistema afeta valores já balanceados (economia, custo em
   diamante, stats), avisar antes de aplicar — não é decisão pra tomar sozinho
3. Manter `--!strict` e tipos exportados (`export type`) nos módulos de
   `shared/Data/`. Nos serviços de `server/Systems/` não force `--!strict` sem
   necessidade — eles leem `PlayerDataService.GetData()` (tabela solta sem
   tipo forte) o tempo todo, e strict mode aumenta muito a chance de falso
   positivo nessas leituras.
4. Textos visíveis ao jogador: sempre em português
5. **Verificação de tipos sem abrir o Studio**: o luau-lsp da extensão do
   VSCode tem uma CLI de análise standalone. Rode
   `rojo sourcemap default.project.json -o sourcemap.json` pra gerar/atualizar
   o sourcemap, depois
   `<caminho-da-extensão>/bin/server.exe analyze --sourcemap=sourcemap.json --platform=roblox --defs=<globalTypes.d.luau cacheado pela extensão> <arquivos .lua>`
   pra rodar o mesmo typecheck/lint que aparece no painel "Problems" do
   VSCode, direto no terminal — útil pra validar mudanças em lote sem
   depender do Studio/extensão abertos.
