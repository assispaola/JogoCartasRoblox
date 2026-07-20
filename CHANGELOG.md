# Changelog

## [Não lançado] — Correção de modelo: raridade contínua + Prova de Renascimento final

Substitui a modelagem de raridade da entrada anterior deste changelog (pontos
que somavam e resetavam ao evoluir) e fecha a regra da Prova do Renascimento.

**Corrigido:**
- **Raridade não é mais um contador de pontos que reseta ao evoluir.** Vira
  uma função contínua, sempre recalculada a partir de `totalCopias`
  (`data.album[creatureId] = { totalCopias, grau }`, campo `raridade` foi
  removido do armazenamento). `AlbumEvolutionCurve.RarityForTotalCopies`
  deriva a raridade comparando `totalCopias` contra thresholds acumulados de
  entrada (Default 0 → Bronze 5 → Prata 15 → Ouro 30 → Platina 55 →
  Lendário 90 → Mítico 140). Cruzar um threshold pra cima OU pra baixo usa a
  MESMA função (`AlbumService`'s `applyTotalCopias`) — elimina os dois fluxos
  separados de evolução/downgrade que existiam antes.
- O antigo "Atalho" (salto instantâneo numa raridade sorteada por pacote)
  agora é um PISO sobre `totalCopias`: `max(atual + 1, pisoDaRaridade)` —
  mesmo efeito de antes (pull de alta raridade ainda dá salto), dentro do
  cálculo único.
- Migration (`PlayerDataService.migrateCardsToAlbum`) ajustada pra popular
  `totalCopias` (aproximado pelo piso da maior raridade já alcançada) em vez
  de `raridade`/`pontos`.

**Alterado — Renascimento:**
- Prova reformulada pra 3 requisitos simultâneos: sacrificar 3 cartas de um
  clã sorteado (escolha livre de quais), sacrificar 1 cópia de uma criatura
  específica fixa, e ter saldo mínimo de Dinheiro (não passa pelo Altar).
  Substitui a versão anterior (nível mínimo + `ownClanCount` como posse
  simples).
- `AltarSacrificioService`: staging vira quantidade por criatura (não mais
  booleano), cobre os dois tipos de requisito de sacrifício, com cuidado
  explícito pra não contar a mesma cópia staged duas vezes entre os dois
  requisitos.
- `RenascimentoCatalog`: nova curva convexa e agressiva pra quantia mínima de
  Dinheiro (parâmetros ainda não validados com a Paola — só a estrutura).
- Novo `RenascimentoService.GetConfirmationPreview` — dados pro popup de
  confirmação antes de renascer (Fase 5/UI).

---

## [Não lançado] — Sistema de Álbum e Evolução (substitui Fusão manual)

Arquitetura de 3 camadas por criatura descoberta (Álbum / Mochila / Slots de
Base), ver `SISTEMA_ALBUM_E_EVOLUCAO.md` e `CLAUDE.md`.

**Adicionado:**
- `AlbumService.lua` (novo) — fonte da verdade de raridade/pontos/grau por
  criatura; evolução automática por pontos acumulados (curva em
  `AlbumEvolutionCurve.lua`, novo); consolida o "Índice" (Diamante de
  descoberta) que antes vivia em `InventoryService.GrantDiscoveryIfNew`.
- `AltarSacrificioService.lua` (novo) — staging manual de criaturas pra prova
  de Renascimento.
- Raridade **Default** (8ª, abaixo de Bronze) em `Rarities.lua` — estado
  forçado pela Bênção Diária.
- Gamepass "Slots de Base +5" (`slotsExtras`) em `GamepassCatalog.lua`, teto
  dos Slots de Base agora vive em `data.maxPlacedSlots` (base 20).
- Novos campos em `PlayerData_v2`: `album`, `mochila`, `altarSacrificio`,
  `packStates`, `highestUnlockedGeneralPackId`, `maxPlacedSlots`. Migration
  automática (idempotente) do modelo antigo por cópia (`data.cards` +
  `data.relicario`) pro Álbum/Mochila, na primeira carga de um save antigo.

**Alterado:**
- Mochila: de 1 objeto por cópia física pra 1 objeto por criatura descoberta.
  `InventoryService`/`EconomyService`/`HandService` reescritos pra operar por
  `creatureId` em vez de `cardId`.
- `SellService.VenderCopias` (novo, substitui `TrySell`): vende por
  `creatureId` + quantidade, com preview antes de aplicar.
- `DonationService`/`TradeService`: transferem "1 unidade de progresso" de
  uma criatura (via `AlbumService.RemoverPontos`/`RegistrarCopia`) em vez de
  mover objetos de carta por `cardId`.
- `PackService.lua` religado de verdade aos serviços reais (antes era um
  scaffold nunca inicializado corretamente); `PackOddsRoller`/`PackCatalog`
  corrigidos pra usar os IDs de raridade acentuados canônicos de
  `Rarities.lua` (tradução em `PackOddsRoller.ToCanonicalRarityId`).
- `RenascimentoCatalog`: Provas agora usam `ownClanCount` (posse de X
  criaturas distintas de um clã) em vez de posse simples; reset do
  Renascimento passa a zerar **só o Dinheiro** (Nível/stats/Álbum/Mochila
  persistem — `data.stats` já devia ser cumulativo por design, isso corrige
  uma inconsistência do código antigo).
- `LevelService`: requisitos de posse/sacrifício (`ownClan`, `ownClanCount`,
  `sacrificeCardsByRarity/Clan`, `sacrificeSpecificCreature`) agora leem do
  Álbum/Mochila; "sacrificar" vira remover 1 ponto (`AlbumService.RemoverPontos`),
  não mais apagar um objeto de carta inteiro.

**Removido:**
- **Relicário removido do projeto por completo** (não depreciado — deletado):
  `RelicarioService.lua`, gamepass "Relicário +5" (`bancoExtra`), campos
  `data.relicario`/`data.relicarioSlots`, remotes `MoveToRelicarioRequest`/
  `MoveFromRelicarioRequest`/`RelicarioResult`. Motivo: sob o Álbum, nada é
  perdido no Renascimento, então não existe mais o que proteger.

**Depreciado (mantido no repo, sem uso real):**
- `FusionService.lua` — evolução manual por fusão, substituída pela
  automática do Álbum.
- `DespertarService.lua` — Despertar por `cardId`, substituído por
  `AlbumService.RollDespertar` (por `creatureId`).

**Bugs pré-existentes descobertos (não corrigidos, ver CLAUDE.md):**
- `WheelService`/`DailyBlessingService`/`JourneyChestService` chamam
  `PackService.GrantFreePack` com um `packId` de um `PackCatalog` antigo
  (tier+clã) que não existe mais.
- `MarketplaceService.ProcessReceipt` é sobrescrito duas vezes
  (`PackService.Init()` e `GamepassService.Init()`) — só o último vale.

---

# Changelog — Sistema de Raridade, Despertar e Divino

Resumo de tudo que foi decidido nesta sessão + onde colar cada arquivo no projeto.

---

## Onde colar cada arquivo

```
JogoCartasRoblox/
└── src/
    ├── shared/
    │   └── Data/
    │       ├── Rarities.lua          ← SUBSTITUIR o arquivo antigo
    │       ├── Clans.lua             ← SUBSTITUIR o arquivo antigo
    │       └── DivineCreatures.lua   ← NOVO
    │
    └── client/
        └── UI/
            └── DivineBorder.lua      ← NOVO (ou UI/Cards/DivineBorder.lua se
                                          você organiza por subpasta)
```

---

## 1. Sistema de Raridade — `Rarities.lua`

**O que mudou:** multiplicadores de valor foram todos recalculados, e a raridade
**Divino** foi adicionada (7ª raridade, acima de Mítico).

| Raridade | Chance no Pacote | Duplicatas p/ Evoluir | Multiplicador | Custo Despertar (💎) |
|----------|-------------------|------------------------|----------------|------------------------|
| Bronze | 45% | 3 | ×1 | 1.200 |
| Prata | 25% | 4 | ×6 | 2.100 |
| Ouro | 15% | 5 | ×18 | 3.300 |
| Platina | 8% | 6 | ×50 | 4.800 |
| Lendário | 5% | 8 | ×150 | 6.300 |
| Mítico | 2% | — | ×500 | 10.000 |
| **Divino** | **só evento** | — | **×10.000** | **25.000** |

**Regra de segurança:** `Raridade(N) x 2.5 (grau máx.) < Raridade(N+1) base` — garante
que evoluir a raridade SEMPRE compensa mais do que só despertar no teto.

---

## 2. Despertar (Grau) — dentro do `Rarities.lua`

**O que mudou:** carta nasce **sem despertar** (grau "vazio", multiplicador x1.0,
badge não aparece na UI). Multiplicadores recalibrados pra grau 7.0 já valer a pena
(mas sem estourar o teto da próxima raridade).

| Grau | Multiplicador | Chance no Altar |
|------|----------------|-------------------|
| — (vazio, default) | ×1.0 | não exibido na UI |
| 7.0 | ×1.05 | 40% |
| 7.5 | ×1.15 | 27% |
| 8.0 | ×1.30 | 17% |
| 8.5 | ×1.50 | 9% |
| 9.0 | ×1.75 | 4.5% |
| 9.5 | ×2.10 | 2% |
| 10.0 | ×2.50 | 0.5% |

O resultado sorteado **sempre substitui** o grau atual (pode piorar). Uma vez
despertado, não volta pro estado vazio.

---

## 3. Fórmula de Valor Final

```
Valor = SeedValue x FatorEscala(1.000) x MultRaridade x MultGrau x MultRenascimento
```

Uso no código:

```lua
local Rarities = require(path.to.Rarities)

local valor = Rarities.CalculateValue(
    creature.seedValue,   -- valor semente da criatura (10-100)
    "Mítico",              -- raridade atual da carta
    9.0,                    -- grau de despertar atual
    renascimentoMultiplier  -- opcional; passa nil ou 1 se não tiver prestígio ainda
)
```

Isso já entrega o jogador começando na casa dos **milhares**, evoluindo pra
**milhões** no mid-game, e cartas Divinas no teto perto de **bilhões** — deixando
o Renascimento empurrar pra trilhões nos resets avançados.

---

## 4. Cores dos Clãs — `Clans.lua`

Paleta final com boa distância de matiz entre todos os 15 clãs (sem clusters de
cor parecida). Uso:

```lua
local Clans = require(path.to.Clans)
local corDoCla = Clans.ByName["Forja Ígnea"].color -- já é um Color3 pronto
```

---

## 5. Criaturas Divinas — `DivineCreatures.lua`

As 15 criaturas fixas (1 por clã), sem fusão, só via pacote de evento. Stats
calibrados acima do teto do Mítico. **Poseidon já substituindo Yemanjá** na Maré
Eterna (mudança mais recente).

```lua
local DivineCreatures = require(path.to.DivineCreatures)
local divinaDoClA = DivineCreatures.ByClan["Ordem Celestial"] -- Amaterasu
```

---

## 6. Borda de UI do Divino — `DivineBorder.lua`

Borda animada prata + lascas prismáticas pastel (violeta/ciano/dourado/rosa),
girando 360° a cada 6s — só o anel gira, a arte do card fica parada.

```lua
local DivineBorder = require(path.to.DivineBorder)

if card:GetAttribute("Raridade") == "Divino" then
    DivineBorder.Apply(card)
else
    -- seu código atual de UIStroke sólido no tom do clã
end
```

---

## Pendências / próximos passos sugeridos

- [x] Ajustar o `PackService` (ou equivalente) pra excluir Divino do sorteio normal
      de pacotes — ele só deve sair via um pacote de evento separado (já não incluía
      Divino no `RARITY_ORDER`/tabelas de chance)
- [x] Migrar os serviços que ainda usavam a API antiga de `Rarities.lua`/`Grades.lua`
      (`Rarities.Data`, `.multiplier`, `Grades.BaseGrade`, etc.) pra API nova
      (`Rarities.ById`, `.valueMultiplier`, `Rarities.BaseAwakenGrade`,
      `Rarities.AwakenGrades`, `Rarities.CalculateValue`, `Rarities.DiscoveryDiamondReward`)
      — `EconomyService`, `InventoryService`, `FusionService`, `AutoSellService`,
      `DespertarService`, `PackService`. `Grades.lua` e `DiamondRewards.lua` foram
      removidos (substituídos por `Rarities.lua`). Também corrigido `AutoSellService`
      indexando `Clans[name]` direto (não existe) em vez de `Clans.ByName[name]`, e
      adicionado `Clans.Order` (faltava, usado por `PackCatalog`/`ChallengeCatalog`/
      `PortalService`) e `Rarities.Order`/`nextRarity` (faltava, usado por
      `FusionService`/`ChallengeCatalog`).
- [ ] Criar o "Pacote de Evento" que sorteia entre as 15 `DivineCreatures`
- [ ] Verificar se o `DataStore` (`PlayerData_v2`) precisa de novo campo pra marcar
      cartas Divinas já descobertas (pro bônus de Diamante do Índice)
- [ ] Gerar as artes finais das 15 Divinas (prompts já prontos, faltam Poseidon
      re-gerado + as que ainda não foram testadas)
