--[[
	GamepassCatalog.lua
	Configuração de todos os Gamepasses (compra única, permanente) e Dev
	Products (consumíveis - pacotes de Diamante) vendidos na Loja.

	IMPORTANTE: os `assetId` abaixo são PLACEHOLDERS (0). Você precisa
	criar cada Gamepass/Dev Product de verdade no Creator Dashboard do
	Roblox (create.roblox.com → seu jogo → Monetização) e colar o ID real
	aqui antes de publicar. Sem isso, as compras não vão funcionar - o
	MarketplaceService não encontra o produto.

	Local: ReplicatedStorage/Shared/Data/GamepassCatalog.lua
]]

local GamepassCatalog = {}

export type GamepassInfo = {
	key: string, -- bate com o campo em data.gamepasses
	assetId: number, -- ID do Gamepass no Roblox (PREENCHER depois de criar)
	name: string,
	description: string,
}

GamepassCatalog.Gamepasses = {
	{
		key = "vip",
		assetId = 0,
		name = "VIP",
		description = "+50% velocidade, renda offline em dobro, tag e título VIP, +25% valor em todas as cartas",
	},
	{
		key = "autoCollect",
		assetId = 0,
		name = "Coleta Automática",
		description = "A renda das cartas cai direto no seu saldo, sem precisar coletar manualmente",
	},
	{
		key = "sorteCeleste",
		assetId = 0,
		name = "Sorte Celestial",
		description = "Aumenta a sorte no Altar do Despertar (acumula com outros produtos de sorte)",
	},
	{
		key = "ultraSorte",
		assetId = 0,
		name = "Ultra Sorte",
		description = "Aumenta MUITO a sorte no Altar do Despertar (acumula com outros produtos de sorte)",
	},
	{
		key = "sorteDiamante",
		assetId = 0,
		name = "Sorte do Diamante",
		description = "+150% de sorte extra ao usar Diamante no Altar do Despertar",
	},
	{
		key = "inventarioExtra",
		assetId = 0,
		name = "Mochila +500",
		description = "Aumenta a capacidade da Mochila em 500 cartas",
	},
	{
		key = "bancoExtra",
		assetId = 0,
		name = "Relicário +5",
		description = "Adiciona 5 slots extras ao Relicário",
	},
	{
		key = "aberturaRapida",
		assetId = 0,
		name = "Abertura Rápida",
		description = "Abre pacotes mais rápido (efeito visual/cliente)",
	},
	{
		key = "pacotesExclusivos",
		assetId = 0,
		name = "Acesso a Pacotes Exclusivos",
		description = "Libera pacotes exclusivos, independente do seu nível",
	},
}

export type DiamondProductInfo = {
	productId: number, -- ID do Dev Product no Roblox (PREENCHER depois de criar)
	amount: number,
	name: string,
}

GamepassCatalog.DiamondProducts = {
	{ productId = 0, amount = 50, name = "Punhado de Diamante" },
	{ productId = 0, amount = 200, name = "Bolsa de Diamante" },
	{ productId = 0, amount = 600, name = "Baú de Diamante" },
	{ productId = 0, amount = 1500, name = "Tesouro de Diamante" },
}

-- Índices rápidos (montados uma vez, reaproveitados pelos serviços)
GamepassCatalog.ByKey = {}
for _, gp in GamepassCatalog.Gamepasses do
	GamepassCatalog.ByKey[gp.key] = gp
end

GamepassCatalog.ByAssetId = {}
for _, gp in GamepassCatalog.Gamepasses do
	GamepassCatalog.ByAssetId[gp.assetId] = gp
end

GamepassCatalog.DiamondByProductId = {}
for _, product in GamepassCatalog.DiamondProducts do
	GamepassCatalog.DiamondByProductId[product.productId] = product
end

return GamepassCatalog
