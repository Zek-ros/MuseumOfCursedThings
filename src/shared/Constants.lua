-- Constants.lua
-- Game-wide configuration values for Museum of Cursed Things

local Constants = {}

-- How often passive income ticks (seconds)
Constants.INCOME_TICK_RATE = 5

-- How often chaos events are checked (seconds)
Constants.CHAOS_CHECK_RATE = 10

-- Rarity definitions: spawn weight, income multiplier, UI color
Constants.RARITY = {
	Common    = { Weight = 50, Multiplier = 1.0, Color = Color3.fromRGB(200, 200, 200) },
	Uncommon  = { Weight = 30, Multiplier = 1.5, Color = Color3.fromRGB(100, 200, 100) },
	Rare      = { Weight = 15, Multiplier = 2.5, Color = Color3.fromRGB(100, 150, 255) },
	Legendary = { Weight = 4,  Multiplier = 5.0, Color = Color3.fromRGB(255, 200, 50)  },
	Forbidden = { Weight = 1,  Multiplier = 10.0, Color = Color3.fromRGB(200, 50, 255) },
}

-- Museum danger score thresholds
Constants.DANGER_THRESHOLDS = {
	Low      = 0,
	Medium   = 15,
	High     = 30,
	Critical = 50,
}

-- Probability of a chaos event firing per check at each danger tier
Constants.CHAOS_BASE_CHANCE = {
	Low      = 0.05,
	Medium   = 0.15,
	High     = 0.30,
	Critical = 0.60,
}

-- Base display slot count (increased by museum level)
Constants.MAX_DISPLAYED_ARTIFACTS = 20

-- Currency given to new players
Constants.STARTING_CURRENCY = 100

-- Extra income percentage when visitors are present
Constants.MUSEUM_VISIT_INCOME_BONUS = 0.10

-- The "risk premium": total museum danger multiplies passive income.
-- Displaying dangerous artifacts earns more — but also triggers more chaos.
Constants.DANGER_INCOME_MULTIPLIER = {
	Low      = 1.0,
	Medium   = 1.25,
	High     = 1.6,
	Critical = 2.1,
}

-- The "risk" half of the loop: when chaos fires, the chance (per event) that an
-- artifact breaches containment and is knocked off display. Higher danger =
-- more breaches. Good containment lowers each artifact's escape odds.
Constants.CHAOS_BREACH_CHANCE = {
	Low      = 0.0,
	Medium   = 0.08,
	High     = 0.20,
	Critical = 0.35,
}

-- Fraction of current coins the income-theft chaos steals, by danger tier.
Constants.CHAOS_THEFT_PCT = {
	Low      = 0.02,
	Medium   = 0.035,
	High     = 0.055,
	Critical = 0.08,
}

-- Ordered containment upgrade path for the shop (cheapest/weakest -> strongest).
Constants.CONTAINMENT_ORDER = {
	"GlassCase",
	"ReinforcedCase",
	"ElectricCage",
	"AntiTeleportField",
	"FreezingChamber",
	"HolySeal",
	"ReinforcedVault",
}

-- Museum visitors: rarer displayed artifacts draw bigger crowds, and each
-- visitor adds a little passive income. Visitor count is a pure function of
-- the displayed collection (no saved state), so income + spawning stay in sync.
Constants.VISITOR_APPEAL_WEIGHT = {
	Common    = 1,
	Uncommon  = 2,
	Rare      = 4,
	Legendary = 8,
	Forbidden = 15,
}
Constants.VISITOR_APPEAL_PER = 3   -- appeal points needed per visitor
Constants.MAX_VISITORS = 10        -- crowd cap per museum
Constants.VISITOR_INCOME_EACH = 2  -- income per tick per visitor

-- Museum growth: leveling up adds pedestals (= display slots) and income.
-- Display slots are tied to physical pedestals so what you can show always
-- matches what appears in the room.
Constants.PEDESTALS_BASE = 6        -- pedestals at museum level 1
Constants.PEDESTALS_PER_LEVEL = 3   -- extra pedestals per level
Constants.MAX_MUSEUM_LEVEL = 5      -- level cap
Constants.MAX_PEDESTALS = 18        -- = BASE + (MAX_LEVEL-1)*PER_LEVEL
Constants.MUSEUM_UPGRADE_BASE_COST = 1000 -- cost = BASE * currentLevel

return Constants
