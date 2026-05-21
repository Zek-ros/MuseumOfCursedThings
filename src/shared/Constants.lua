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

return Constants
