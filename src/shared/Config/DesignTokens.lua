--!strict
--[[
	DesignTokens.lua
	Agregador único dos módulos de Config + formatadores de número.
	Qualquer componente de UI deve requisitar ESTE módulo (não os filhos direto),
	exceto quando só precisa de um pedaço específico.

	Localização Rojo: ReplicatedStorage/Shared/Config/DesignTokens
]]

local DesignTokens = {}

DesignTokens.Colors = require(script.Parent.Colors)
DesignTokens.Typography = require(script.Parent.Typography)
DesignTokens.Layout = require(script.Parent.Layout)

--- Formata número completo com separador de milhar brasileiro.
--- Ex: 1250000 -> "1.250.000"
function DesignTokens.FormatNumber(n: number): string
	local isNegative = n < 0
	local intPart = string.format("%d", math.floor(math.abs(n)))
	local reversed = intPart:reverse()
	local withDots = reversed:gsub("(%d%d%d)", "%1."):reverse()
	withDots = withDots:gsub("^%.", "")
	return (isNegative and "-" or "") .. withDots
end

--- Formata número compacto com abreviação. Ex: 35100 -> "35.1K"
function DesignTokens.FormatCompact(n: number): string
	local abs = math.abs(n)
	local sign = n < 0 and "-" or ""

	if abs >= 1e12 then
		return string.format("%s%.2fT", sign, abs / 1e12)
	elseif abs >= 1e9 then
		return string.format("%s%.2fB", sign, abs / 1e9)
	elseif abs >= 1e6 then
		return string.format("%s%.2fM", sign, abs / 1e6)
	elseif abs >= 1e3 then
		return string.format("%s%.1fK", sign, abs / 1e3)
	end

	return sign .. string.format("%d", abs)
end

--- Formata segundos em mm:ss (usado em cooldowns) ou HHhMMm (usado em eventos)
function DesignTokens.FormatCountdown(totalSeconds: number, style: string?): string
	totalSeconds = math.max(0, math.floor(totalSeconds))

	if style == "hm" then
		local hours = math.floor(totalSeconds / 3600)
		local minutes = math.floor((totalSeconds % 3600) / 60)
		return string.format("%02dh%02dm", hours, minutes)
	end

	if style == "hms" then
		local hours = math.floor(totalSeconds / 3600)
		local minutes = math.floor((totalSeconds % 3600) / 60)
		local seconds = totalSeconds % 60
		return string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end

	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	return string.format("%02d:%02d", minutes, seconds)
end

return DesignTokens
