--[[
	CreatureArtIds.lua
	Mapeia cada uma das 300 criaturas (mesmo ID usado em Creatures.lua) pro
	asset de imagem da ilustração dela no Roblox. UMA arte por criatura -
	não varia por raridade (a raridade é só a moldura, ver CardFrameBuilder.lua).

	PREENCHER: depois de gerar e subir cada ilustração no Roblox (Decal/Image),
	cola o rbxassetid:// real no lugar do placeholder "rbxassetid://0".
	As criaturas já vêm agrupadas por clã, na mesma ordem do Creatures.lua,
	pra facilitar ir preenchendo em lote.

	Local: ReplicatedStorage/Shared/Data/CreatureArtIds.lua
]]

local CreatureArtIds: { [number]: string } = {}


-- ==== Ordem Celestial ====
CreatureArtIds[1] = "rbxassetid://0" -- Fênix Solar
CreatureArtIds[2] = "rbxassetid://0" -- Grifo Guardião
CreatureArtIds[3] = "rbxassetid://0" -- Pégaso Radiante
CreatureArtIds[4] = "rbxassetid://0" -- Serpente-Pluma Ancestral
CreatureArtIds[5] = "rbxassetid://0" -- Unicórnio Sagrado
CreatureArtIds[6] = "rbxassetid://0" -- Roc Celestial
CreatureArtIds[7] = "rbxassetid://0" -- Lamassu Dourado
CreatureArtIds[8] = "rbxassetid://0" -- Bennu Ancestral
CreatureArtIds[9] = "rbxassetid://0" -- Garuda Radiante
CreatureArtIds[10] = "rbxassetid://0" -- Simurgh Eterno
CreatureArtIds[11] = "rbxassetid://0" -- Kirin Puro
CreatureArtIds[12] = "rbxassetid://0" -- Huma Abençoada
CreatureArtIds[13] = "rbxassetid://0" -- Peri da Luz
CreatureArtIds[14] = "rbxassetid://0" -- Serafim de Seis Asas
CreatureArtIds[15] = "rbxassetid://0" -- Ave-Sol Inca
CreatureArtIds[16] = "rbxassetid://0" -- Alicanto Radiante
CreatureArtIds[17] = "rbxassetid://0" -- Aurora Ancestral
CreatureArtIds[18] = "rbxassetid://0" -- Corcel de Apolo
CreatureArtIds[19] = "rbxassetid://0" -- Anjo Guardião Menor
CreatureArtIds[20] = "rbxassetid://0" -- Zhar-Ptitsa

-- ==== Véu Sombrio ====
CreatureArtIds[21] = "rbxassetid://0" -- Kitsune das Nove Caudas
CreatureArtIds[22] = "rbxassetid://0" -- Nekomata Ancestral
CreatureArtIds[23] = "rbxassetid://0" -- Anansi, o Trapaceiro
CreatureArtIds[24] = "rbxassetid://0" -- Baku Devorador
CreatureArtIds[25] = "rbxassetid://0" -- Banshee Lamentosa
CreatureArtIds[26] = "rbxassetid://0" -- Yūrei Errante
CreatureArtIds[27] = "rbxassetid://0" -- Krampus Sombrio
CreatureArtIds[28] = "rbxassetid://0" -- Nuckelavee Amaldiçoado
CreatureArtIds[29] = "rbxassetid://0" -- Barghest Noturno
CreatureArtIds[30] = "rbxassetid://0" -- Alp Sussurrante
CreatureArtIds[31] = "rbxassetid://0" -- Strigoi Ancestral
CreatureArtIds[32] = "rbxassetid://0" -- Empusa Sedutora
CreatureArtIds[33] = "rbxassetid://0" -- Namahage da Meia-Noite
CreatureArtIds[34] = "rbxassetid://0" -- Yatagarasu Sombrio
CreatureArtIds[35] = "rbxassetid://0" -- Onryō Vingativo
CreatureArtIds[36] = "rbxassetid://0" -- Corvo de Baba Yaga
CreatureArtIds[37] = "rbxassetid://0" -- Huginn, o Corvo Vidente
CreatureArtIds[38] = "rbxassetid://0" -- Lobo das Sombras
CreatureArtIds[39] = "rbxassetid://0" -- Lilim Noturna
CreatureArtIds[40] = "rbxassetid://0" -- Djinn das Sombras

-- ==== Fúria Selvagem ====
CreatureArtIds[41] = "rbxassetid://0" -- Cérbero Guardião
CreatureArtIds[42] = "rbxassetid://0" -- Minotauro do Labirinto
CreatureArtIds[43] = "rbxassetid://0" -- Wendigo da Floresta Gelada
CreatureArtIds[44] = "rbxassetid://0" -- Sasquatch Ancestral
CreatureArtIds[45] = "rbxassetid://0" -- Ent Milenar
CreatureArtIds[46] = "rbxassetid://0" -- Tigre-Dente-de-Sabre Espiritual
CreatureArtIds[47] = "rbxassetid://0" -- Urso Sagrado do Norte
CreatureArtIds[48] = "rbxassetid://0" -- Javali de Erimanto
CreatureArtIds[49] = "rbxassetid://0" -- Touro Selvagem de Creta
CreatureArtIds[50] = "rbxassetid://0" -- Lobo Guerreiro Ancestral
CreatureArtIds[51] = "rbxassetid://0" -- Centauro Arqueiro
CreatureArtIds[52] = "rbxassetid://0" -- Fauno da Clareira
CreatureArtIds[53] = "rbxassetid://0" -- Sátiro Dançarino
CreatureArtIds[54] = "rbxassetid://0" -- Dríade da Grande Árvore
CreatureArtIds[55] = "rbxassetid://0" -- Leshy da Floresta Funda
CreatureArtIds[56] = "rbxassetid://0" -- Skogsrå Encantadora
CreatureArtIds[57] = "rbxassetid://0" -- Wolpertinger Travesso
CreatureArtIds[58] = "rbxassetid://0" -- Alce Ancestral
CreatureArtIds[59] = "rbxassetid://0" -- Rakshasa da Selva
CreatureArtIds[60] = "rbxassetid://0" -- Yeti das Terras Altas

-- ==== Abismo Glacial ====
CreatureArtIds[61] = "rbxassetid://0" -- Yuki-onna Congelante
CreatureArtIds[62] = "rbxassetid://0" -- Troll da Geada
CreatureArtIds[63] = "rbxassetid://0" -- Espectro de Gelo
CreatureArtIds[64] = "rbxassetid://0" -- Skoll, Perseguidor do Sol
CreatureArtIds[65] = "rbxassetid://0" -- Bergelmir Ancestral
CreatureArtIds[66] = "rbxassetid://0" -- Jotun das Nevascas
CreatureArtIds[67] = "rbxassetid://0" -- Ninfa da Geada
CreatureArtIds[68] = "rbxassetid://0" -- Yeti Guardião da Neve
CreatureArtIds[69] = "rbxassetid://0" -- Kraken Congelado
CreatureArtIds[70] = "rbxassetid://0" -- Selkie da Maré Fria
CreatureArtIds[71] = "rbxassetid://0" -- Draugr Gelado
CreatureArtIds[72] = "rbxassetid://0" -- Snegurochka Ancestral
CreatureArtIds[73] = "rbxassetid://0" -- Amarok, o Lobo Gigante
CreatureArtIds[74] = "rbxassetid://0" -- Qalupalik das Águas Frias
CreatureArtIds[75] = "rbxassetid://0" -- Tupilaq Vingativo
CreatureArtIds[76] = "rbxassetid://0" -- Fênix Glacial
CreatureArtIds[77] = "rbxassetid://0" -- Wyrm Glacial
CreatureArtIds[78] = "rbxassetid://0" -- Nix das Águas Geladas
CreatureArtIds[79] = "rbxassetid://0" -- Wisp do Inverno
CreatureArtIds[80] = "rbxassetid://0" -- Fúria da Nevasca

-- ==== Maré Eterna ====
CreatureArtIds[81] = "rbxassetid://0" -- Leviatã das Profundezas
CreatureArtIds[82] = "rbxassetid://0" -- Kappa do Rio
CreatureArtIds[83] = "rbxassetid://0" -- Ningyo Ancestral
CreatureArtIds[84] = "rbxassetid://0" -- Selkie das Marés
CreatureArtIds[85] = "rbxassetid://0" -- Nereida Radiante
CreatureArtIds[86] = "rbxassetid://0" -- Hipocampo Real
CreatureArtIds[87] = "rbxassetid://0" -- Náiade da Fonte Sagrada
CreatureArtIds[88] = "rbxassetid://0" -- Merrow das Ondas
CreatureArtIds[89] = "rbxassetid://0" -- Undine Encantada
CreatureArtIds[90] = "rbxassetid://0" -- Rusalka do Lago Negro
CreatureArtIds[91] = "rbxassetid://0" -- Vodyanoy das Profundezas
CreatureArtIds[92] = "rbxassetid://0" -- Bakunawa, a Serpente-Lua
CreatureArtIds[93] = "rbxassetid://0" -- Makara Guardião
CreatureArtIds[94] = "rbxassetid://0" -- Jengu da Correnteza
CreatureArtIds[95] = "rbxassetid://0" -- Aspidochelone Ancestral
CreatureArtIds[96] = "rbxassetid://0" -- Charybdis do Redemoinho
CreatureArtIds[97] = "rbxassetid://0" -- Kelpie das Águas Negras
CreatureArtIds[98] = "rbxassetid://0" -- Ceto, Mãe dos Monstros
CreatureArtIds[99] = "rbxassetid://0" -- Tritão Ancestral
CreatureArtIds[100] = "rbxassetid://0" -- Lorelei do Penhasco

-- ==== Forja Ígnea ====
CreatureArtIds[101] = "rbxassetid://0" -- Ifrit das Chamas
CreatureArtIds[102] = "rbxassetid://0" -- Salamandra de Lava
CreatureArtIds[103] = "rbxassetid://0" -- Touro de Fogo
CreatureArtIds[104] = "rbxassetid://0" -- Corcel Flamejante
CreatureArtIds[105] = "rbxassetid://0" -- Dragão Vermelho Cadente
CreatureArtIds[106] = "rbxassetid://0" -- Dáemon Vulcânico
CreatureArtIds[107] = "rbxassetid://0" -- Dracaena Flamejante
CreatureArtIds[108] = "rbxassetid://0" -- Dragão Galês da Chama (Y Ddraig Goch)
CreatureArtIds[109] = "rbxassetid://0" -- Ave-Sol Flamejante
CreatureArtIds[110] = "rbxassetid://0" -- Espírito da Forja
CreatureArtIds[111] = "rbxassetid://0" -- Djinn Ardente
CreatureArtIds[112] = "rbxassetid://0" -- Cão-Diabo Flamejante (Church Grim)
CreatureArtIds[113] = "rbxassetid://0" -- Basilisco de Fogo
CreatureArtIds[114] = "rbxassetid://0" -- Chama Viva Ancestral
CreatureArtIds[115] = "rbxassetid://0" -- Fera Incandescente
CreatureArtIds[116] = "rbxassetid://0" -- Golem de Brasa
CreatureArtIds[117] = "rbxassetid://0" -- Serpente de Enxofre
CreatureArtIds[118] = "rbxassetid://0" -- Wyrm Escaldante
CreatureArtIds[119] = "rbxassetid://0" -- Corvo em Chamas
CreatureArtIds[120] = "rbxassetid://0" -- Fagulha Ancestral

-- ==== Tempestade Rúnica ====
CreatureArtIds[121] = "rbxassetid://0" -- Thunderbird Ancestral
CreatureArtIds[122] = "rbxassetid://0" -- Raiju do Relâmpago
CreatureArtIds[123] = "rbxassetid://0" -- Ave-Relâmpago Andina
CreatureArtIds[124] = "rbxassetid://0" -- Harpia da Tempestade
CreatureArtIds[125] = "rbxassetid://0" -- Wyvern Elétrico
CreatureArtIds[126] = "rbxassetid://0" -- Espírito do Vendaval
CreatureArtIds[127] = "rbxassetid://0" -- Corcel da Tormenta
CreatureArtIds[128] = "rbxassetid://0" -- Kaminari-neko
CreatureArtIds[129] = "rbxassetid://0" -- Ave-Furacão
CreatureArtIds[130] = "rbxassetid://0" -- Grifo da Tempestade
CreatureArtIds[131] = "rbxassetid://0" -- Dragão do Vento Chinês
CreatureArtIds[132] = "rbxassetid://0" -- Sylph Ancestral
CreatureArtIds[133] = "rbxassetid://0" -- Djinn do Vendaval
CreatureArtIds[134] = "rbxassetid://0" -- Ave-Relâmpago Sioux
CreatureArtIds[135] = "rbxassetid://0" -- Fera do Tufão
CreatureArtIds[136] = "rbxassetid://0" -- Serpente do Vendaval
CreatureArtIds[137] = "rbxassetid://0" -- Falcão Elétrico
CreatureArtIds[138] = "rbxassetid://0" -- Coruja da Tormenta
CreatureArtIds[139] = "rbxassetid://0" -- Wisp Elétrico
CreatureArtIds[140] = "rbxassetid://0" -- Fúria do Ciclone

-- ==== Rocha Ancestral ====
CreatureArtIds[141] = "rbxassetid://0" -- Golem de Pedra
CreatureArtIds[142] = "rbxassetid://0" -- Troll da Montanha
CreatureArtIds[143] = "rbxassetid://0" -- Ciclope Ferreiro
CreatureArtIds[144] = "rbxassetid://0" -- Gigante de Granito
CreatureArtIds[145] = "rbxassetid://0" -- Behemoth Ancestral
CreatureArtIds[146] = "rbxassetid://0" -- Gnomo Guardião
CreatureArtIds[147] = "rbxassetid://0" -- Anão Ferreiro Ancestral
CreatureArtIds[148] = "rbxassetid://0" -- Quimera de Granito
CreatureArtIds[149] = "rbxassetid://0" -- Górgona Petrificante
CreatureArtIds[150] = "rbxassetid://0" -- Tartaruga-Montanha
CreatureArtIds[151] = "rbxassetid://0" -- Yaoguai de Pedra
CreatureArtIds[152] = "rbxassetid://0" -- Efreet de Terra
CreatureArtIds[153] = "rbxassetid://0" -- Colosso Ancestral
CreatureArtIds[154] = "rbxassetid://0" -- Argos de Cem Olhos
CreatureArtIds[155] = "rbxassetid://0" -- Espírito da Caverna
CreatureArtIds[156] = "rbxassetid://0" -- Talos, o Autômato de Bronze
CreatureArtIds[157] = "rbxassetid://0" -- Oni de Pedra
CreatureArtIds[158] = "rbxassetid://0" -- Guardião Megalítico
CreatureArtIds[159] = "rbxassetid://0" -- Titã Adormecido
CreatureArtIds[160] = "rbxassetid://0" -- Dragão de Granito

-- ==== Areia Amaldiçoada ====
CreatureArtIds[161] = "rbxassetid://0" -- Múmia Ancestral
CreatureArtIds[162] = "rbxassetid://0" -- Chacal Guardião
CreatureArtIds[163] = "rbxassetid://0" -- Esfinge Enigmática
CreatureArtIds[164] = "rbxassetid://0" -- Ammit, Devoradora de Almas
CreatureArtIds[165] = "rbxassetid://0" -- Ka Errante
CreatureArtIds[166] = "rbxassetid://0" -- Escorpião Gigante do Deserto
CreatureArtIds[167] = "rbxassetid://0" -- Serket Ancestral
CreatureArtIds[168] = "rbxassetid://0" -- Ushabti Animado
CreatureArtIds[169] = "rbxassetid://0" -- Ghoul das Dunas
CreatureArtIds[170] = "rbxassetid://0" -- Djinn da Areia
CreatureArtIds[171] = "rbxassetid://0" -- Basilisco do Deserto
CreatureArtIds[172] = "rbxassetid://0" -- Abutre Sagrado
CreatureArtIds[173] = "rbxassetid://0" -- Sarcófago Vivo
CreatureArtIds[174] = "rbxassetid://0" -- Espectro do Oásis
CreatureArtIds[175] = "rbxassetid://0" -- Víbora das Areias
CreatureArtIds[176] = "rbxassetid://0" -- Roc das Dunas
CreatureArtIds[177] = "rbxassetid://0" -- Camelo Espectral
CreatureArtIds[178] = "rbxassetid://0" -- Wyrm de Areia
CreatureArtIds[179] = "rbxassetid://0" -- Sombra do Faraó
CreatureArtIds[180] = "rbxassetid://0" -- Guardião de Obelisco

-- ==== Selva Esmeralda ====
CreatureArtIds[181] = "rbxassetid://0" -- Naga Venenosa
CreatureArtIds[182] = "rbxassetid://0" -- Basilisco da Selva
CreatureArtIds[183] = "rbxassetid://0" -- Hidra de Lerna
CreatureArtIds[184] = "rbxassetid://0" -- Cobra-Rei Ancestral
CreatureArtIds[185] = "rbxassetid://0" -- Jorōgumo, a Aranha Encantadora
CreatureArtIds[186] = "rbxassetid://0" -- Sapo-Veneno Místico
CreatureArtIds[187] = "rbxassetid://0" -- Quimera Tóxica
CreatureArtIds[188] = "rbxassetid://0" -- Wyvern Venenoso
CreatureArtIds[189] = "rbxassetid://0" -- Manticora Ancestral
CreatureArtIds[190] = "rbxassetid://0" -- Górgona da Selva
CreatureArtIds[191] = "rbxassetid://0" -- Serpente Esmeralda
CreatureArtIds[192] = "rbxassetid://0" -- Escaravelho Tóxico
CreatureArtIds[193] = "rbxassetid://0" -- Flor Devoradora Ancestral
CreatureArtIds[194] = "rbxassetid://0" -- Trepadeira Amaldiçoada
CreatureArtIds[195] = "rbxassetid://0" -- Sanguessuga Gigante
CreatureArtIds[196] = "rbxassetid://0" -- Víbora das Sombras Verdes
CreatureArtIds[197] = "rbxassetid://0" -- Camaleão Venenoso Ancestral
CreatureArtIds[198] = "rbxassetid://0" -- Tarântula Real
CreatureArtIds[199] = "rbxassetid://0" -- Anfisbena de Duas Cabeças
CreatureArtIds[200] = "rbxassetid://0" -- Lagarto-Praga

-- ==== Constelação Arcana ====
CreatureArtIds[201] = "rbxassetid://0" -- Ursa Estelar
CreatureArtIds[202] = "rbxassetid://0" -- Dragão das Constelações
CreatureArtIds[203] = "rbxassetid://0" -- Fenrir Celeste
CreatureArtIds[204] = "rbxassetid://0" -- Fera do Zodíaco
CreatureArtIds[205] = "rbxassetid://0" -- Ouroboros Cósmico
CreatureArtIds[206] = "rbxassetid://0" -- Corcel das Estrelas
CreatureArtIds[207] = "rbxassetid://0" -- Coruja Cósmica
CreatureArtIds[208] = "rbxassetid://0" -- Ave Cósmica Ancestral
CreatureArtIds[209] = "rbxassetid://0" -- Golem Estelar
CreatureArtIds[210] = "rbxassetid://0" -- Nebulosa Viva
CreatureArtIds[211] = "rbxassetid://0" -- Guardião da Via Láctea
CreatureArtIds[212] = "rbxassetid://0" -- Sombra Cósmica
CreatureArtIds[213] = "rbxassetid://0" -- Cometa Vivo
CreatureArtIds[214] = "rbxassetid://0" -- Espírito da Lua Cheia
CreatureArtIds[215] = "rbxassetid://0" -- Devoradora de Estrelas
CreatureArtIds[216] = "rbxassetid://0" -- Titã Astral
CreatureArtIds[217] = "rbxassetid://0" -- Naga Celestial
CreatureArtIds[218] = "rbxassetid://0" -- Dragão-Lunar Chinês
CreatureArtIds[219] = "rbxassetid://0" -- Wyrm das Galáxias
CreatureArtIds[220] = "rbxassetid://0" -- Vidente das Estrelas

-- ==== Profundezas Abissais ====
CreatureArtIds[221] = "rbxassetid://0" -- Kraken das Trincheiras
CreatureArtIds[222] = "rbxassetid://0" -- Cthon Abissal
CreatureArtIds[223] = "rbxassetid://0" -- Leviatã Ancestral
CreatureArtIds[224] = "rbxassetid://0" -- Serpente das Fossas
CreatureArtIds[225] = "rbxassetid://0" -- Behemoth das Profundezas
CreatureArtIds[226] = "rbxassetid://0" -- Peixe-Abissal Ancestral
CreatureArtIds[227] = "rbxassetid://0" -- Medusa das Profundezas
CreatureArtIds[228] = "rbxassetid://0" -- Kraken Filhote
CreatureArtIds[229] = "rbxassetid://0" -- Horror das Trincheiras
CreatureArtIds[230] = "rbxassetid://0" -- Serpente Ceto Ancestral
CreatureArtIds[231] = "rbxassetid://0" -- Devorador de Naufrágios
CreatureArtIds[232] = "rbxassetid://0" -- Polvo Ancestral
CreatureArtIds[233] = "rbxassetid://0" -- Sereia Abissal
CreatureArtIds[234] = "rbxassetid://0" -- Wyrm das Fossas Marianas
CreatureArtIds[235] = "rbxassetid://0" -- Titã Submerso
CreatureArtIds[236] = "rbxassetid://0" -- Espectro do Naufrágio
CreatureArtIds[237] = "rbxassetid://0" -- Anglerfish Ancestral
CreatureArtIds[238] = "rbxassetid://0" -- Hidra das Profundezas
CreatureArtIds[239] = "rbxassetid://0" -- Baleia Espectral
CreatureArtIds[240] = "rbxassetid://0" -- Guardião do Abismo

-- ==== Chama Vulcânica ====
CreatureArtIds[241] = "rbxassetid://0" -- Fera Magmática
CreatureArtIds[242] = "rbxassetid://0" -- Demônio do Vulcão
CreatureArtIds[243] = "rbxassetid://0" -- Golem de Magma
CreatureArtIds[244] = "rbxassetid://0" -- Dragão de Obsidiana
CreatureArtIds[245] = "rbxassetid://0" -- Fênix das Cinzas
CreatureArtIds[246] = "rbxassetid://0" -- Basilisco Magmático
CreatureArtIds[247] = "rbxassetid://0" -- Efrit Vulcânico
CreatureArtIds[248] = "rbxassetid://0" -- Touro de Magma
CreatureArtIds[249] = "rbxassetid://0" -- Serpente de Obsidiana
CreatureArtIds[250] = "rbxassetid://0" -- Titã Vulcânico
CreatureArtIds[251] = "rbxassetid://0" -- Salamandra Magmática
CreatureArtIds[252] = "rbxassetid://0" -- Fúria do Crater
CreatureArtIds[253] = "rbxassetid://0" -- Wyrm Vulcânico
CreatureArtIds[254] = "rbxassetid://0" -- Espírito da Erupção
CreatureArtIds[255] = "rbxassetid://0" -- Cão de Magma
CreatureArtIds[256] = "rbxassetid://0" -- Rocha Viva Incandescente
CreatureArtIds[257] = "rbxassetid://0" -- Fera das Cinzas
CreatureArtIds[258] = "rbxassetid://0" -- Corvo de Cinzas
CreatureArtIds[259] = "rbxassetid://0" -- Colosso de Lava
CreatureArtIds[260] = "rbxassetid://0" -- Núcleo Ardente

-- ==== Névoa Espectral ====
CreatureArtIds[261] = "rbxassetid://0" -- Alma Penada Ancestral
CreatureArtIds[262] = "rbxassetid://0" -- Fantasma da Névoa
CreatureArtIds[263] = "rbxassetid://0" -- Eco do Além
CreatureArtIds[264] = "rbxassetid://0" -- Espectro Errante
CreatureArtIds[265] = "rbxassetid://0" -- Dama de Branco
CreatureArtIds[266] = "rbxassetid://0" -- Poltergeist Ancestral
CreatureArtIds[267] = "rbxassetid://0" -- Sombra sem Corpo
CreatureArtIds[268] = "rbxassetid://0" -- Wisp das Almas
CreatureArtIds[269] = "rbxassetid://0" -- Espírito do Pântano
CreatureArtIds[270] = "rbxassetid://0" -- Fantasma do Farol
CreatureArtIds[271] = "rbxassetid://0" -- Ánima Errante
CreatureArtIds[272] = "rbxassetid://0" -- Sudário Vivo
CreatureArtIds[273] = "rbxassetid://0" -- Espectro da Torre
CreatureArtIds[274] = "rbxassetid://0" -- Névoa Consciente
CreatureArtIds[275] = "rbxassetid://0" -- Ecos de Batalha
CreatureArtIds[276] = "rbxassetid://0" -- Espírito do Espelho
CreatureArtIds[277] = "rbxassetid://0" -- Ceifador Silencioso
CreatureArtIds[278] = "rbxassetid://0" -- Choro da Meia-Noite
CreatureArtIds[279] = "rbxassetid://0" -- Espírito Guardião do Cemitério
CreatureArtIds[280] = "rbxassetid://0" -- Última Sombra

-- ==== Engrenagem Rúnica ====
CreatureArtIds[281] = "rbxassetid://0" -- Autômato de Bronze Ancestral
CreatureArtIds[282] = "rbxassetid://0" -- Golem de Engrenagens
CreatureArtIds[283] = "rbxassetid://0" -- Sentinela Rúnica
CreatureArtIds[284] = "rbxassetid://0" -- Homúnculo Mecânico
CreatureArtIds[285] = "rbxassetid://0" -- Coruja de Engrenagens
CreatureArtIds[286] = "rbxassetid://0" -- Dragão de Metal Rúnico
CreatureArtIds[287] = "rbxassetid://0" -- Aranha Mecânica Ancestral
CreatureArtIds[288] = "rbxassetid://0" -- Cavaleiro de Latão
CreatureArtIds[289] = "rbxassetid://0" -- Besouro de Cobre
CreatureArtIds[290] = "rbxassetid://0" -- Torre Ambulante Rúnica
CreatureArtIds[291] = "rbxassetid://0" -- Faísca Viva
CreatureArtIds[292] = "rbxassetid://0" -- Golem de Relógio
CreatureArtIds[293] = "rbxassetid://0" -- Falcão de Bronze
CreatureArtIds[294] = "rbxassetid://0" -- Guardião de Runas Vivas
CreatureArtIds[295] = "rbxassetid://0" -- Serpente de Engrenagens
CreatureArtIds[296] = "rbxassetid://0" -- Titã Mecânico Ancestral
CreatureArtIds[297] = "rbxassetid://0" -- Enxame de Nanoautômatos
CreatureArtIds[298] = "rbxassetid://0" -- Fera de Vapor
CreatureArtIds[299] = "rbxassetid://0" -- Oráculo Mecânico
CreatureArtIds[300] = "rbxassetid://0" -- Núcleo Rúnico Ancestral

return CreatureArtIds
