# HUD v2 — Cartas Míticas

Reescrita completa do HUD baseada no protótipo aprovado + Design System.
Arquitetura modular: `Config` (tokens) → `UI/Components` (primitivos reutilizáveis
em qualquer tela) → `UI/HUD` (composição específica do HUD) → `HUDController`
(API pública única).

## Estrutura do Projeto

Árvore completa de `src/` (Rojo), com o propósito de cada pasta e arquivo.
`client/` → `StarterPlayer/StarterPlayerScripts`, `server/` → `ServerScriptService/Server`,
`shared/` → `ReplicatedStorage/Shared` (ver `default.project.json`).

```
src/
├── client/                        -- código que só roda no jogador (UI, input)
│   ├── Main.client.lua             -- bootstrap de produção (faltava nesta árvore)
│   ├── HUDTest.client.lua          -- script de TESTE/simulação que monta o HUD com dados falsos (não é o bootstrap de produção)
│   └── UI/
│       ├── Cards/                  -- visual de carta (feature ainda não conectada em nenhum lugar)
│       │   ├── ClanBorderColors.lua  -- cores de borda de carta por clã
│       │   └── DivineBorder.lua      -- borda animada específica das criaturas Divinas
│       └── HUD/                    -- composição da tela de HUD
│           ├── BottomBar.lua         -- navegação mobile (substitui a Sidebar em telas estreitas)
│           ├── HUDController.lua     -- ponto de entrada único, monta e expõe a API pública do HUD
│           ├── MoneyCounter.lua      -- grupo "Cash" (cifrão + valor + linha de renda offline);
│           │                            substituiu o antigo Notifications.lua, que não existe mais
│           ├── Progress.lua          -- progresso de Renascimento + status do Altar
│           ├── Sidebar.lua           -- navegação desktop (9 itens)
│           └── TopBar.lua            -- dinheiro, diamante, $/s e ciclo de Renascimento
│
├── server/                        -- código que só roda no servidor
│   ├── Debug/DebugTest.server.lua  -- script de teste manual do loop econômico ponta a ponta (apagar quando não precisar mais)
│   ├── Main.server.lua             -- ponto de entrada: Init() de todos os serviços, autosave, snapshot
│   └── Systems/                    -- lógica de servidor, um serviço por sistema de jogo
│       ├── AlbumService.lua          -- fonte da verdade de cópias acumuladas e grau de Despertar por criatura
│       ├── AltarSacrificioService.lua -- staging (por quantidade) da Prova de Renascimento
│       ├── AutoSellService.lua       -- toggle de auto-venda (reinterpretação pós-Mítico existe mas está desligada)
│       ├── DailyBlessingService.lua  -- recompensa por streak de login diário
│       ├── DespertarService.lua      -- OBSOLETO: stub de erro, lógica original preservada em comentário (ver AlbumService.RollDespertar)
│       ├── DonationService.lua       -- doa 1 unidade de progresso de uma criatura pra outro jogador
│       ├── EconomyService.lua        -- $/s, coleta de renda dos Slots de Base, renda offline
│       ├── FusionService.lua         -- OBSOLETO: stub de erro, lógica original preservada em comentário (ver AlbumService)
│       ├── GamepassService.lua       -- posse de gamepasses + processamento de recibo (Robux/Dev Products)
│       ├── HandService.lua           -- "Mão": 10 slots pra fixar cartas específicas, sem efeito de jogo ainda
│       ├── InventoryService.lua      -- Mochila (1 registro por criatura descoberta) + Slots de Base
│       ├── JourneyChestService.lua   -- recompensa por marco de tempo jogado
│       ├── LevelService.lua          -- Desafios de Nível (motor de requisito genérico)
│       ├── PackService.lua           -- compra/abertura de pacotes, ladder Geral, recibo de compra via Robux
│       ├── PlayerDataService.lua     -- único ponto de acesso ao DataStore + migração de saves antigos
│       ├── PortalService.lua         -- evento global de servidor (Portal da Sorte)
│       ├── RenascimentoService.lua   -- valida a Prova e executa o reset de Renascimento (só Dinheiro)
│       ├── SellService.lua           -- venda de cópias (20% fixo do valor de mercado)
│       ├── SnapshotService.lua       -- monta e envia o retrato completo dos dados do jogador
│       ├── StatsService.lua          -- contadores cumulativos usados pelos requisitos de Nível/Renascimento
│       ├── TradeService.lua          -- sessão de troca bilateral entre jogadores com confirmação dupla
│       └── WheelService.lua          -- Roda do Destino (spin a cada 30min)
│
└── shared/                        -- código/dados usados por client E server
    ├── Config/                     -- tokens de design do HUD
    │   ├── Colors.lua                -- paleta de cores base
    │   ├── DesignTokens.lua           -- agregador: reexporta Colors + Typography + Layout
    │   ├── Layout.lua                 -- dimensões, espaçamentos, breakpoint mobile/desktop
    │   └── Typography.lua             -- fontes e escalas de texto
    ├── Data/                       -- catálogos de dados do jogo (fonte de verdade de gameplay)
    │   ├── AlbumEvolutionCurve.lua    -- thresholds acumulados de raridade (função contínua de evolução)
    │   ├── ChallengeCatalog.lua       -- desafios de nível gerados por fórmula
    │   ├── Clans.lua                  -- 15 clãs + cor oficial
    │   ├── CreatureArtIds.lua         -- mapeamento de arte por criatura
    │   ├── Creatures.lua              -- 300 criaturas base (id numérico = chave)
    │   ├── DailyBlessingCatalog.lua   -- recompensas por streak de login
    │   ├── DivineCreatures.lua        -- 15 criaturas Divinas (1 por clã)
    │   ├── GamepassCatalog.lua        -- catálogo de gamepasses
    │   ├── JourneyChestCatalog.lua    -- marcos de tempo jogado e suas recompensas
    │   ├── PackCatalog.lua            -- 77 pacotes (fonte de verdade atual do sorteio, chaves ASCII)
    │   ├── PackOddsRoller.lua         -- sorteio de raridade/clã/criatura + tradução de grafia ASCII↔acentuada
    │   ├── PortalCatalog.lua          -- variações do evento Portal da Sorte
    │   ├── Rarities.lua               -- 8 raridades + Despertar + fórmula de valor (fonte canônica de RarityId)
    │   ├── RenascimentoCatalog.lua    -- requisitos da Prova do Renascimento por ciclo
    │   └── WheelCatalog.lua           -- prêmios da Roda do Destino
    ├── Networking/
    │   └── Remotes.lua                -- registro central de todos os RemoteEvents/RemoteFunctions
    └── UI/
        ├── CardFrameBuilder.lua       -- monta o frame visual de uma carta (feature ainda não conectada)
        ├── Components/                 -- primitivos reutilizáveis em QUALQUER tela, não só HUD
        │   ├── Button.lua               -- botão genérico
        │   ├── Chip.lua                 -- badge/chip genérico
        │   ├── IconButton.lua           -- botão de ícone genérico
        │   ├── ProgressBar.lua          -- barra de progresso genérica
        │   ├── StatBadge.lua            -- badge de estatística (adicionado depois, faltava aqui)
        │   ├── SquareIconButton.lua     -- botão de ícone quadrado (adicionado depois, faltava aqui)
        │   └── PillActionButton.lua     -- botão de ação em formato pill (adicionado depois, faltava aqui)
        └── Utils/
            └── UIKit.lua                -- helpers de UI (corner, stroke, animação)
```

> `src/starterGui/UI/{Assets,Components,Screens,Theme}` também existe no
> projeto mas está totalmente vazio (scaffold ainda não usado).

## O que mudou vs. a v1

| Item | v1 | v2 |
|---|---|---|
| Estrutura | 1 arquivo `HUD.lua` monolítico | 6 arquivos especializados + 4 componentes reutilizáveis |
| Fontes | Gotham (built-in) | Rajdhani (UI) + JetBrains Mono (números), via `Font.fromName` |
| Nível/XP | Existia | ❌ Removido (não existe na lógica do jogo) |
| Renascimento | Não existia | ✅ Ciclo + multiplicador na TopBar, progresso + status do Altar |
| Navegação | Não existia | ✅ Sidebar completa (9 itens) + BottomBar mobile |
| Streak / Notificações | Não existia | ✅ Painel direito completo |
| Portal da Sorte | Não existia | ✅ Ícone flutuante isolado (não é a Roda do Destino) |
| Responsividade | Não existia | ✅ Sidebar ↔ BottomBar automático por largura de tela |
| Loja | "Loja de Pacotes" único item | ✅ Separado em **Pacotes** e **Loja** (gamepass/Robux) |

## Como testar

1. Copie os arquivos para as pastas indicadas acima.
2. `rojo serve` → Connect no plugin do Studio.
3. Aperte **Play**.
4. Redimensione a janela do Studio pra ver a Sidebar virar BottomBar
   automaticamente (breakpoint em `Layout.HUD.MobileBreakpoint`, hoje 700px).
5. Veja o Output — deve aparecer:
   `[HUDController]` sem erros e `[HUDTest] HUDController montado...`

## Conectando aos sistemas reais (próximo passo)

O `HUDController` já expõe toda a API que os sistemas reais vão chamar.
Nenhum componente visual precisa mudar — só trocar quem chama:

| Sistema real | Método do HUDController a chamar |
|---|---|
| `EconomyService` | `SetMoney`, `AddMoney`, `SetIncomePerSecond` |
| `PlayerDataService` (diamante) | `SetDiamonds`, `AddDiamonds` |
| `RenascimentoService` | `SetRenascimento`, `SetRenascimentoProgress`, `SetAltarStatus` |
| `AlbumService` | `SetAlbumProgress` |
| `PackService` (cooldown) | `SetPackCooldown` |
| `WheelService` | `SetWheelNotification` |
| Streak/Daily Blessing | `SetStreak` |
| `PortalDaSorteService` (evento) | `SetPortalCountdown` |
| Qualquer evento de recompensa | `ShowToast`, `PushNotification`, `SetBadge` |
| Navegação entre telas | `OnNavigate(callback)` recebe a chave clicada (`"Album"`, `"Altar"`, etc.) e deve abrir a tela correspondente |
