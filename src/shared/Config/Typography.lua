--!strict
--[[
	Typography.lua
	Fontes e escalas — Cartas Míticas.
	Rajdhani para UI/Body · JetBrains Mono para dados e números.
	Localização Rojo: ReplicatedStorage/Shared/Config/Typography

	Nota: Font.fromName() carrega fontes do catálogo Google Fonts nativo do
	Roblox — não precisa subir asset customizado.
]]

local Typography = {}

-- Font.fromName pode ESTOURAR ERRO em runtime se o nome da família não
-- existir no catálogo do Roblox (ex: "Fredoka One" com espaço pode não ser
-- o identificador interno exato, mesmo aparecendo assim no picker do
-- Properties). Como este módulo é importado por TODO componente de UI do
-- jogo, um erro aqui quebra o require inteiro — a HUD inteira some, sem
-- aviso nenhum. safeFontFromName nunca deixa isso acontecer: tenta o nome
-- pedido, e se falhar cai pra uma fonte segura conhecida (Enum.Font legado,
-- que não pode falhar) + avisa no Output pra ficar visível.
local function safeFontFromName(family: string, weight: Enum.FontWeight?, fallback: Enum.Font?): Font
	local ok, result = pcall(Font.fromName, family, weight)
	if ok then
		return result :: Font
	end
	warn(`[Typography] Font.fromName("{family}") falhou — usando fallback. Erro: {result}`)
	return Font.fromEnum(fallback or Enum.Font.GothamBold)
end

Typography.Fonts = {
	Display = Font.fromName("Rajdhani", Enum.FontWeight.Bold),
	Body = Font.fromName("Rajdhani", Enum.FontWeight.Medium),
	Mono = Font.fromName("JetBrainsMono", Enum.FontWeight.Medium),
	MonoBold = Font.fromName("JetBrainsMono", Enum.FontWeight.SemiBold),

	-- Confirmados no Figma pro HUD principal (node 16:194): Fredoka pra
	-- labels/textos de UI, Rubik ExtraBold pros valores numéricos em
	-- destaque ($, 💎, contadores). Não substituem Rajdhani/JetBrainsMono
	-- acima (usados no resto do projeto, ex: cartas) — uso restrito ao HUD.
	--
	-- IMPORTANTE: no catálogo nativo do Roblox o nome certo é "Fredoka One"
	-- (não "Fredoka" sozinho, que não existe e caía no fallback silencioso
	-- pra SourceSansPro). "Fredoka One" só tem UM peso (já é bold por
	-- natureza do desenho) — força Regular aqui; pedir SemiBold/Medium em
	-- cima disso faz o Roblox aplicar negrito SINTÉTICO extra, ficando
	-- grosso/borrado demais.
	HUDLabel = safeFontFromName("Fredoka One", Enum.FontWeight.Regular, Enum.Font.GothamBold),
	HUDLabelMedium = safeFontFromName("Fredoka One", Enum.FontWeight.Regular, Enum.Font.GothamBold),
	HUDValue = safeFontFromName("Rubik", Enum.FontWeight.ExtraBold, Enum.Font.GothamBlack),
	HUDValueBold = safeFontFromName("Rubik", Enum.FontWeight.Bold, Enum.Font.GothamBold),
}

-- Estilo unificado pra TODO texto branco de botão/rótulo da HUD (sidebar,
-- pills de ação, título "Renascimento"): mesmo tamanho + mesma espessura de
-- contorno preto grosso (ver UIKit.TextThickOutline), sem drop shadow.
-- NÃO inclui textos do painel do Portal da Sorte ("Portal da Sorte"/"Inicia
-- em:") — aquele painel não é um "botão", mantém o tamanho pixel-perfect do
-- Figma.
Typography.HUDWhiteLabel = {
	Size = 22,
	StrokeThickness = 2,
}

-- Escala para texto de UI (Rajdhani)
Typography.UI = {
	Large = 26, -- "Abrir Pacote" (títulos de tela / CTA grande)
	Medium = 18, -- "Slots de Base" (subtítulos)
	Body = 15, -- texto corrido
	Small = 13, -- "Renascimento reseta a Mochila"
	MicroBold = 11, -- "ALTAR DE SACRIFÍCIO" (labels/caption)
}

-- Escala para dados numéricos (JetBrains Mono)
Typography.Number = {
	XL = 32, -- "$4.200.000/s" (destaque total)
	LG = 24, -- "18.450" (valor grande)
	MD = 18, -- "×500 mult"
	SM = 14, -- "totalCopias >= 140"
	XS = 11, -- "THRESHOLD"
}

return Typography
