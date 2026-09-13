--!strict
--[[
	Emblems.lua
	Registry único dos emblemas dos 15 clãs — Cartas Míticas.
	Usado em: borda/moldura de CreatureCard, filtro de clã no Álbum/Loja,
	ícone de área temática no Lobby.

	Localização Rojo: ReplicatedStorage/Shared/UI/Emblems

	v2 — IDs corrigidos (Image ID real, resolvido via GetObjects().Texture,
	não o Decal ID original retornado pela Open Cloud API).
]]

local Emblems = {}

Emblems.Registry = {
	OrdemCelestial = "rbxassetid://74290067877763",
	VeuSombrio = "rbxassetid://113224734660404",
	FuriaSelvagem = "rbxassetid://94575570854356",
	AbismoGlacial = "rbxassetid://107841577894385",
	MareEterna = "rbxassetid://118044028914075",
	ForjaIgnea = "rbxassetid://126491609191920",
	TempestadeRunica = "rbxassetid://131309756676996",
	RochaAncestral = "rbxassetid://119658897913471",
	AreiaAmaldicoada = "rbxassetid://72644212510056",
	SelvaEsmeralda = "rbxassetid://82220918959029",
	ConstelacaoArcana = "rbxassetid://118313593968882",
	ProfundezasAbissais = "rbxassetid://90393419209887",
	ChamaVulcanica = "rbxassetid://124704767839442",
	NevoaEspectral = "rbxassetid://127373848336154",
	EngrenagemRunica = "rbxassetid://73071373776535",
}

--- Retorna o rbxassetid:// do emblema. Estoura erro claro se o clã não existir
--- (evita emblema quebrado silencioso em produção).
function Emblems.Get(clanName: string): string
	local id = Emblems.Registry[clanName]
	assert(id, `[Emblems] clã "{clanName}" não existe no Registry`)
	return id
end

--- Aplica o emblema diretamente numa ImageLabel/ImageButton existente.
function Emblems.Apply(imageObject: Instance, clanName: string)
	(imageObject :: any).Image = Emblems.Get(clanName)
end

return Emblems
