--!strict
-- DivineBorder.lua
-- Borda definitiva da raridade Divino: arco-íris saturado (magenta, dourado,
-- ciano, violeta), girando em volta da carta (só a BORDA gira — a arte do
-- card fica parada).
--
-- Nota técnica: no Roblox, animar UIGradient.Rotation NÃO gira o elemento
-- pai — só desloca a direção da faixa de cor ao longo do UIStroke. Ou seja,
-- diferente do teste em HTML/CSS (onde tivemos que isolar a rotação num
-- pseudo-elemento à parte), aqui o efeito "só a borda gira" já é o
-- comportamento padrão do UIGradient aplicado a um UIStroke.

local TweenService = game:GetService("TweenService")

local DivineBorder = {}

function DivineBorder.Apply(card: GuiObject): UIStroke
	-- Corner radius (mesmo padrão já definido pros cards)
	local corner = (card:FindFirstChildOfClass("UICorner") :: UICorner?) or Instance.new("UICorner")
	corner.Parent = card
	corner.CornerRadius = UDim.new(0, 16)

	-- Remove stroke antigo (caso o card já tenha um sólido de outra raridade)
	local oldStroke = card:FindFirstChild("RarityBorder") or card:FindFirstChild("DivineBorder")
	if oldStroke then
		oldStroke:Destroy()
	end

	-- Stroke principal (anel prata + lascas prismáticas)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "DivineBorder"
	stroke.Thickness = 4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	-- Arco-íris saturado (magenta -> dourado -> ciano -> violeta), direto de
	-- docs/game-design/moldura_carta_divino.html
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromHex("8A0F49")), -- faixa magenta - base
		ColorSequenceKeypoint.new(0.05, Color3.fromHex("FF007F")),
		ColorSequenceKeypoint.new(0.09, Color3.fromHex("FFB6DC")),
		ColorSequenceKeypoint.new(0.13, Color3.fromHex("FF007F")),
		ColorSequenceKeypoint.new(0.20, Color3.fromHex("8A0F49")),
		ColorSequenceKeypoint.new(0.25, Color3.fromHex("8A6B00")), -- faixa dourada - base
		ColorSequenceKeypoint.new(0.30, Color3.fromHex("FFD700")),
		ColorSequenceKeypoint.new(0.34, Color3.fromHex("FFF2A6")),
		ColorSequenceKeypoint.new(0.38, Color3.fromHex("FFD700")),
		ColorSequenceKeypoint.new(0.45, Color3.fromHex("8A6B00")),
		ColorSequenceKeypoint.new(0.50, Color3.fromHex("006E80")), -- faixa ciano - base
		ColorSequenceKeypoint.new(0.55, Color3.fromHex("00F0FF")),
		ColorSequenceKeypoint.new(0.59, Color3.fromHex("B3FAFF")),
		ColorSequenceKeypoint.new(0.63, Color3.fromHex("00F0FF")),
		ColorSequenceKeypoint.new(0.70, Color3.fromHex("006E80")),
		ColorSequenceKeypoint.new(0.75, Color3.fromHex("4A0066")), -- faixa violeta - base
		ColorSequenceKeypoint.new(0.80, Color3.fromHex("C800FF")),
		ColorSequenceKeypoint.new(0.84, Color3.fromHex("E8B3FF")),
		ColorSequenceKeypoint.new(0.88, Color3.fromHex("C800FF")),
		ColorSequenceKeypoint.new(0.95, Color3.fromHex("4A0066")),
		ColorSequenceKeypoint.new(1.00, Color3.fromHex("8A0F49")),
	})
	gradient.Parent = stroke

	-- Hairline interno branco sutil (refinamento — separa a borda da arte)
	local innerHairline = Instance.new("UIStroke")
	innerHairline.Name = "DivineInnerHairline"
	innerHairline.Thickness = 1
	innerHairline.Color = Color3.fromRGB(255, 255, 255)
	innerHairline.Transparency = 0.5
	innerHairline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	innerHairline.Parent = card

	-- Animação contínua: a faixa de cor desliza ao redor do anel.
	task.spawn(function()
		while stroke.Parent do
			local tween = TweenService:Create(
				gradient,
				TweenInfo.new(6, Enum.EasingStyle.Linear),
				{ Rotation = gradient.Rotation + 360 }
			)
			tween:Play()
			tween.Completed:Wait()
		end
	end)

	return stroke
end

-- Remove a animação/borda (útil se o card for reciclado num ScrollingFrame com pooling)
function DivineBorder.Remove(card: GuiObject)
	local stroke = card:FindFirstChild("DivineBorder")
	if stroke then
		stroke:Destroy()
	end
	local hairline = card:FindFirstChild("DivineInnerHairline")
	if hairline then
		hairline:Destroy()
	end
end

return DivineBorder
