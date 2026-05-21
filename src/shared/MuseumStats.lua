-- MuseumStats.lua
-- Single source of truth for museum-wide calculations.
-- Used by the server (income ticks, chaos checks, inventory queries)
-- so the income/danger formulas live in exactly one place.

local ArtifactData = require(script.Parent.ArtifactData)
local Constants    = require(script.Parent.Constants)

local MuseumStats = {}

--- Total passive income per tick from a player's displayed artifacts.
-- Factors: base income + containment bonus, multiplied by museum level.
function MuseumStats.CalculateIncome(data): number
	if not data then return 0 end

	local total = 0
	for _, artifact in ipairs(data.Artifacts) do
		if artifact.IsDisplayed then
			local def = ArtifactData.Artifacts[artifact.ArtifactId]
			if def then
				local income = def.PassiveIncome
				local containment = ArtifactData.ContainmentTypes[artifact.ContainmentType]
				if containment then
					-- better containment = small income bonus (reward for risk management)
					income += containment.DangerReduction * 0.5
				end
				total += income
			end
		end
	end

	-- Museum level multiplier: +10 % per level above 1
	local levelMultiplier = 1 + ((data.MuseumLevel - 1) * 0.1)
	total *= levelMultiplier

	return math.floor(total)
end

--- Total danger score from a player's displayed artifacts.
-- Containment reduces each artifact's effective danger.
function MuseumStats.CalculateDanger(data): number
	if not data then return 0 end

	local score = 0
	for _, artifact in ipairs(data.Artifacts) do
		if artifact.IsDisplayed then
			local def = ArtifactData.Artifacts[artifact.ArtifactId]
			if def then
				local danger = def.DangerLevel
				local containment = ArtifactData.ContainmentTypes[artifact.ContainmentType]
				if containment then
					danger = math.max(0, danger - containment.DangerReduction)
				end
				score += danger
			end
		end
	end

	return score
end

--- Map a raw danger score to a named tier string.
function MuseumStats.GetDangerTier(score: number): string
	if score >= Constants.DANGER_THRESHOLDS.Critical then
		return "Critical"
	elseif score >= Constants.DANGER_THRESHOLDS.High then
		return "High"
	elseif score >= Constants.DANGER_THRESHOLDS.Medium then
		return "Medium"
	else
		return "Low"
	end
end

return MuseumStats
