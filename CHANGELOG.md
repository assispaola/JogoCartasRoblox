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
