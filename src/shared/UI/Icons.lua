--!strict
--[[
	Icons.lua
	Registry único de ícones de UI — Cartas Míticas.
	Nenhum componente deve ter rbxassetid:// escrito direto; sempre pedir
	via Icons.Get("NomeDoIcone") ou Icons.Registry.NomeDoIcone.

	Localização Rojo: ReplicatedStorage/Shared/UI/Icons

	v2 — IDs corrigidos. A Open Cloud Assets API cria um "Decal" (envelope),
	cujo ID não é diretamente utilizável em ImageLabel.Image. Os IDs abaixo
	já são os IMAGE IDs reais (resolvidos via game:GetObjects().Texture no
	Studio, ver ResolverDecalParaImagem.lua).
]]

local Icons = {}

Icons.Registry = {
	-- ===== HUD / Navegação =====
	Dinheiro = "rbxassetid://103102524631807", -- hud_dolar
	Diamante = "rbxassetid://72279167299039", -- diamante_novo
	Renascimento = "rbxassetid://128037708059523",
	RodaDoDestino = "rbxassetid://77487204102156",
	Sorte = "rbxassetid://136666402262301",
	Portal = "rbxassetid://95159326933163",
	Inicio = "rbxassetid://137919526040797", -- hud_casa
	Loja = "rbxassetid://108854477420869",
	Pacotes = "rbxassetid://70499720953058",
	Album = "rbxassetid://135209922726946", -- hud_album
	Mochila = "rbxassetid://88889954693316",
	Altar = "rbxassetid://72927220987723", -- hud_altar
	Batalha = "rbxassetid://111374346064118", -- hud_batalha
	Pacto = "rbxassetid://120300485867772",
	Trofeu = "rbxassetid://114598270833467",
	Configuracoes = "rbxassetid://80872555967468",
	Sino = "rbxassetid://98720812981115",
	Presente = "rbxassetid://82797854154610", -- hud_presente
	Fechar = "rbxassetid://129088989606231",
	Buscar = "rbxassetid://127632470554943",
	Adicionar = "rbxassetid://111012937231066",

	-- ===== Baús (packs de Robux) =====
	Bau = "rbxassetid://112425837797490",
	BauColecionador = "rbxassetid://139169712517437",
	BauPatrono = "rbxassetid://71830946313342",
	BauFundador = "rbxassetid://78958247153276",

	-- ===== Moeda / Economia extra =====
	Moeda = "rbxassetid://89829853081060",
	PilhaDeMoedas = "rbxassetid://117343522337543",

	-- ===== Fundos de botão do HUD (Figma node 16:194) =====
	-- Arte real (borda + gradiente já baked na imagem, SEM ícone) — usada
	-- como Image de ImageButton/ImageLabel no lugar do UIStroke/UIGradient
	-- desenhado à mão. O ícone continua vindo separado das chaves acima
	-- (Diamante, Renascimento, Loja, Pacotes, Album, Altar, Presente,
	-- Configuracoes, Mochila, Inicio), sobreposto por cima desta imagem.
	BtnDiamanteBg = "rbxassetid://128740887202817",
	BtnRenascerBg = "rbxassetid://104266290753394",
	BtnGiftBg = "rbxassetid://102618172530821",
	BtnConfigBg = "rbxassetid://127780940073215",
	BtnLojaBg = "rbxassetid://85647304694153",
	BtnPacotesBg = "rbxassetid://119650253225701",
	BtnAlbumBg = "rbxassetid://95493527093686",
	BtnBatalhaBg = "rbxassetid://130676759786294",
	BtnAltarBg = "rbxassetid://109041091363992",
	BtnCasaBg = "rbxassetid://122741243281193",
	BtnMochilaBg = "rbxassetid://103235683064631",

	-- Painel INTEIRO do Portal da Sorte (fundo + borda + ícone do portal já
	-- dentro da imagem, estático) — substitui o Frame com UIGradient +
	-- vórtice giratório desenhado em Luau.
	PortalSortePanel = "rbxassetid://89533178397081",

	-- ===== Bônus (não usados no HUD hoje, disponíveis pra outras telas) =====
	Aviso = "rbxassetid://93583066364694",
	BotaoConfirmar = "rbxassetid://91325602257376",
	Cadeado = "rbxassetid://140222518299467",
	Caveira = "rbxassetid://140581497378239",
	Confirmar = "rbxassetid://104431216885098",
	Controle = "rbxassetid://86054665299498",
	Coracao = "rbxassetid://78734733851736",
	CristalAmarelo = "rbxassetid://114684766155040",
	CristalAzul = "rbxassetid://117056384826033",
	CristalVerde = "rbxassetid://83428500548962",
	CristalVermelho = "rbxassetid://119591633643163",
	Cursor = "rbxassetid://76207641541772",
	Dado = "rbxassetid://96203403718981",
	Escudo = "rbxassetid://81366005116712",
	Espada = "rbxassetid://109433793734891",
	Fogo = "rbxassetid://85651557990714",
	Lapis = "rbxassetid://109366288131213",
	Lixeira = "rbxassetid://129818104868237",
	Machado = "rbxassetid://83758884841994",
	Raio = "rbxassetid://140257814021372",
	Rebaixar = "rbxassetid://88850676410421",
	Verificado = "rbxassetid://80210090096252",
}

--- Retorna o rbxassetid:// do ícone. Estoura erro claro se a chave não existir
--- (evita ícone quebrado silencioso em produção).
function Icons.Get(name: string): string
	local id = Icons.Registry[name]
	assert(id, `[Icons] ícone "{name}" não existe no Registry`)
	return id
end

--- Aplica o ícone diretamente numa ImageLabel/ImageButton existente.
function Icons.Apply(imageObject: Instance, name: string)
	(imageObject :: any).Image = Icons.Get(name)
end

return Icons
