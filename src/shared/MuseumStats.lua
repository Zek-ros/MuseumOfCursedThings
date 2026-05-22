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

	-- Risk premium: more total danger = more income (but more chaos too).
	total *= MuseumStats.DangerMultiplier(data)

	-- Visitors add a flat bonus on top of artifact income.
	total += MuseumStats.CalculateVisitorIncome(data)

	-- Prestige: a permanent multiplier earned by rebirthing.
	total *= MuseumStats.PrestigeMultiplier(data)

	return math.floor(total)
end

--- Permanent income multiplier from the player's prestige level.
function MuseumStats.PrestigeMultiplier(data): number
	local prestige = (data and data.Prestige) or 0
	return 1 + prestige * Constants.PRESTIGE_INCOME_BONUS
end

--- Coins required to perform the next prestige (also needs max museum level).
function MuseumStats.PrestigeCost(prestige: number): number
	return Constants.PRESTIGE_BASE_COST * ((prestige or 0) + 1)
end

--- The income multiplier earned from a museum's current danger tier.
function MuseumStats.DangerMultiplier(data): number
	local tier = MuseumStats.GetDangerTier(MuseumStats.CalculateDanger(data))
	return Constants.DANGER_INCOME_MULTIPLIER[tier] or 1.0
end

--- How many visitors the displayed collection currently attracts.
-- A pure function of the data so VisitorService and income stay in sync.
function MuseumStats.CalculateVisitorCount(data): number
	if not data then return 0 end
	local appeal = 0
	for _, artifact in ipairs(data.Artifacts) do
		if artifact.IsDisplayed then
			local def = ArtifactData.Artifacts[artifact.ArtifactId]
			if def then
				appeal += Constants.VISITOR_APPEAL_WEIGHT[def.Rarity] or 0
			end
		end
	end
	local count = math.floor(appeal / Constants.VISITOR_APPEAL_PER)
	return math.clamp(count, 0, Constants.MAX_VISITORS)
end

--- Passive income contributed by the current crowd of visitors.
function MuseumStats.CalculateVisitorIncome(data): number
	return MuseumStats.CalculateVisitorCount(data) * Constants.VISITOR_INCOME_EACH
end

--- How many artifacts a museum can display (= physical pedestals) at its level.
function MuseumStats.DisplaySlots(data): number
	local level = (data and data.MuseumLevel) or 1
	local slots = Constants.PEDESTALS_BASE + (level - 1) * Constants.PEDESTALS_PER_LEVEL
	return math.clamp(slots, Constants.PEDESTALS_BASE, Constants.MAX_PEDESTALS)
end

--- Cost to upgrade from `level` to the next level, or nil if already maxed.
function MuseumStats.MuseumUpgradeCost(level: number): number?
	if level >= Constants.MAX_MUSEUM_LEVEL then
		return nil
	end
	return Constants.MUSEUM_UPGRADE_BASE_COST * level
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
