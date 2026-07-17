# CLAUDE.md — JogoCartasRoblox

Contexto persistente do projeto. Lido automaticamente pelo Claude Code no início de
toda sessão nesta pasta — não precisa reexplicar isso no chat.

## O que é o projeto

Jogo de Roblox tipo simulador incremental de cartas colecionáveis, com identidade
100% original (sem IP licenciada). Tema: criaturas mitológicas reais de várias
culturas do mundo, organizadas em 15 clãs elementais. Loop principal: abrir
pacotes → evoluir cartas por fusão → gerar renda passiva → prestígio (Renascimento).

**Regra inegociável:** nenhum personagem de anime/jogo/IP protegida. Tudo é
mitologia de domínio público ou conteúdo 100% original.

## Stack

- **Engine:** Roblox Studio
- **Linguagem:** Luau (`--!strict` sempre que possível)
- **Sync:** Rojo (projeto vive fora do Studio, em `D:\JogoCartasRoblox`, não em
  pasta sincronizada com nuvem — evita conflito de sync do Rojo)
- **Versionamento:** GitHub
- **Fonte de verdade dos dados de conteúdo:** `Cartas_Miticas_Clans_e_Criaturas.xlsx`
  (15 clãs, 300 criaturas base, sistema de raridade, matriz de 1.800 combinações,
  15 criaturas Divinas)

## Estrutura de pastas (Rojo)

```
src/
├── shared/
│   └── Data/              -- módulos de dados puros (sem lógica de servidor)
│       ├── Clans.lua
│       ├── Creatures.lua
│       ├── Rarities.lua
│       └── DivineCreatures.lua
├── server/
│   └── Services/           -- lógica de servidor (DataStore, economia, etc.)
└── client/
    └── UI/                 -- scripts de UI do lado do cliente
        └── DivineBorder.lua
```

*(Se a estrutura real divergir disso, corrigir este arquivo — o objetivo é ela
sempre refletir a pasta de verdade.)*

## Sistemas já implementados (server-side)

Economia e renda passiva, instâncias individuais de carta com grau de Despertar,
catálogo de 60 pacotes (15 clãs × 4 tiers), sistema de nível com desafios
gerados por fórmula, Renascimento (prestígio) com proteção via Relicário, Bênção
Diária, Baús da Jornada, Roda do Destino, Pacto dos Guardiões (doação/troca com
anti-exploit), auto-venda, Equipar Melhor, snapshot completo do jogador.

**DataStore:** `PlayerData_v2`, com preenchimento automático de campos novos no
load (nunca resetar versão por causa de evolução de schema).

## Convenções de nomenclatura (manter em português, sempre)

| Termo no código | Significado |
|---|---|
| Despertar | sistema de grau (7.0–10.0) que multiplica valor/stats |
| Relicário | banco protegido de cartas |
| Renascimento | prestígio/reset com bônus permanente |
| Portal da Sorte | evento global de servidor |
| Bênção Diária | recompensa por streak de login |
| Baús da Jornada | recompensa por marco de tempo jogado |
| Roda do Destino | spin wheel a cada 30min |
| Pacto dos Guardiões | doação/troca bilateral entre jogadores |

## Sistema de Raridade + Despertar (referência rápida)

7 raridades: Bronze(×1) → Prata(×6) → Ouro(×18) → Platina(×50) → Lendário(×150)
→ Mítico(×500) → **Divino(×10.000)**.

Despertar: carta nasce "vazia" (sem badge de UI), 7.0(×1.05) até 10.0(×2.5).
Fórmula de valor: `seedValue × 1000 (fator de escala) × multRaridade × multGrau
× multRenascimento`. Ver `Rarities.lua` pra implementação exata — é a fonte de
verdade, não recalcular à mão.

## Divino — status atual (adicionado recentemente, pode ter partes pendentes)

7ª raridade, 15 cartas fixas (1 por clã), sem fusão, só via pacote de evento.
Identidade visual fixa (dourado + prisma máximo) independe do clã. Borda de UI:
prata com lascas prismáticas pastel, girando (`DivineBorder.lua`).

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
são propostas sem teste. `Chama Vulcânica (#66192B)` está com pendência aberta
de revisão (conflito de matiz com Forja Ígnea, só 14° de distância).

## Workflow esperado

1. Antes de alterar algo, ler o arquivo relevante primeiro (não assumir
   estrutura de dados sem checar)
2. Se uma mudança de sistema afeta valores já balanceados (economia, custo em
   diamante, stats), avisar antes de aplicar — não é decisão pra tomar sozinho
3. Manter `--!strict` e tipos exportados (`export type`) nos módulos de `Data/`
4. Textos visíveis ao jogador: sempre em português
