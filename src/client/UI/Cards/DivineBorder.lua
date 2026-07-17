--!strict
-- DivineBorder.lua
-- Borda definitiva da raridade Divino: prata + lascas prismáticas pastel,
-- girando em volta da carta (só a BORDA gira — a arte do card fica parada).
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
	local corner = card:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = card
	end
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

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(138, 138, 138)), -- prata sombra
		ColorSequenceKeypoint.new(0.06, Color3.fromRGB(232, 232, 232)), -- prata claro
		ColorSequenceKeypoint.new(0.09, Color3.fromRGB(255, 255, 255)), -- pico branco
		ColorSequenceKeypoint.new(0.12, Color3.fromRGB(232, 232, 232)),
		ColorSequenceKeypoint.new(0.14, Color3.fromRGB(201, 166, 216)), -- lasca violeta pastel
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(192, 192, 192)),
		ColorSequenceKeypoint.new(0.27, Color3.fromRGB(138, 138, 138)),
		ColorSequenceKeypoint.new(0.36, Color3.fromRGB(192, 192, 192)),
		ColorSequenceKeypoint.new(0.38, Color3.fromRGB(166, 201, 216)), -- lasca ciano pastel
		ColorSequenceKeypoint.new(0.41, Color3.fromRGB(232, 232, 232)),
		ColorSequenceKeypoint.new(0.44, Color3.fromRGB(192, 192, 192)),
		ColorSequenceKeypoint.new(0.54, Color3.fromRGB(138, 138, 138)),
		ColorSequenceKeypoint.new(0.63, Color3.fromRGB(192, 192, 192)),
		ColorSequenceKeypoint.new(0.65, Color3.fromRGB(216, 201, 166)), -- lasca dourada pastel (discreta)
		ColorSequenceKeypoint.new(0.68, Color3.fromRGB(232, 232, 232)),
		ColorSequenceKeypoint.new(0.71, Color3.fromRGB(192, 192, 192)),
		ColorSequenceKeypoint.new(0.81, Color3.fromRGB(138, 138, 138)),
		ColorSequenceKeypoint.new(0.90, Color3.fromRGB(192, 192, 192)),
		ColorSequenceKeypoint.new(0.92, Color3.fromRGB(216, 166, 184)), -- lasca rosa pastel
		ColorSequenceKeypoint.new(0.95, Color3.fromRGB(232, 232, 232)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(138, 138, 138)),
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
