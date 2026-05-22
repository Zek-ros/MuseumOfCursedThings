-- MonetizationConfig.lua (ModuleScript, shared)
-- The catalog of game passes (permanent perks) and developer products
-- (repeatable coin purchases). Create these in the Creator Dashboard, then paste
-- the IDs here — same swap-in pattern as models/sounds. An id of 0 means "not
-- set up yet" and the Shop shows it as "Coming soon" rather than prompting.
--
-- A pass's Key MUST match a boolean field in DataService's DEFAULT_DATA
-- (DoubleIncome, VIP) — that's how the effect is applied.

return {
	Passes = {
		{
			Key = "DoubleIncome",
			Name = "Double Income",
			Description = "Permanently DOUBLE every coin your museum earns.",
			GamePassId = 0, -- <- paste your game pass id here
		},
		{
			Key = "VIP",
			Name = "VIP Curator",
			Description = "+50% income and +50% daily reward, forever. Support the game!",
			GamePassId = 0, -- <- paste your game pass id here
		},
	},

	Products = {
		{
			Key = "coins_small",
			Name = "Pouch of Coins",
			Description = "+2,500 coins",
			Coins = 2500,
			ProductId = 0, -- <- paste your developer product id here
		},
		{
			Key = "coins_large",
			Name = "Chest of Coins",
			Description = "+25,000 coins",
			Coins = 25000,
			ProductId = 0,
		},
		{
			Key = "coins_mega",
			Name = "Vault of Coins",
			Description = "+150,000 coins",
			Coins = 150000,
			ProductId = 0,
		},
	},
}
