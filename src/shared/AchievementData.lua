-- AchievementData.lua (ModuleScript, shared)
-- Long-term goals. Each is checked against a single stat the game already
-- tracks; reaching the goal auto-grants the coin reward (AchievementService).
-- Stat is one of: TotalEarned, Discovered (unique artifacts), ChaosEventsSurvived,
-- MuseumLevel, Prestige, ArtifactsCollected. Listed roughly easiest -> hardest.

return {
	{ Id = "first_find",   Name = "First Find",        Stat = "Discovered",          Goal = 1,      Reward = 100,
		Description = "Recover your first cursed artifact." },
	{ Id = "petty_cash",   Name = "Petty Cash",        Stat = "TotalEarned",         Goal = 1000,   Reward = 150,
		Description = "Earn 1,000 coins in total." },
	{ Id = "hoarder",      Name = "Hoarder",           Stat = "ArtifactsCollected",  Goal = 50,     Reward = 800,
		Description = "Collect 50 artifacts (duplicates count)." },
	{ Id = "collector",    Name = "Collector",         Stat = "Discovered",          Goal = 5,      Reward = 300,
		Description = "Discover 5 different artifacts." },
	{ Id = "survivor",     Name = "Survivor",          Stat = "ChaosEventsSurvived", Goal = 25,     Reward = 500,
		Description = "Survive 25 chaos events." },
	{ Id = "architect",    Name = "Grand Architect",   Stat = "MuseumLevel",         Goal = 5,      Reward = 1000,
		Description = "Expand your museum to the maximum level." },
	{ Id = "connoisseur",  Name = "Connoisseur",       Stat = "Discovered",          Goal = 15,     Reward = 1500,
		Description = "Discover 15 different artifacts." },
	{ Id = "wealthy",      Name = "Wealthy Curator",   Stat = "TotalEarned",         Goal = 50000,  Reward = 1500,
		Description = "Earn 50,000 coins in total." },
	{ Id = "reborn",       Name = "Reborn",            Stat = "Prestige",            Goal = 1,      Reward = 2000,
		Description = "Prestige for the first time." },
	{ Id = "storm",        Name = "Eye of the Storm",  Stat = "ChaosEventsSurvived", Goal = 200,    Reward = 3000,
		Description = "Survive 200 chaos events." },
	{ Id = "completionist",Name = "Completionist",     Stat = "Discovered",          Goal = 25,     Reward = 5000,
		Description = "Discover every artifact in the game." },
	{ Id = "tycoon",       Name = "Cursed Tycoon",     Stat = "TotalEarned",         Goal = 500000, Reward = 10000,
		Description = "Earn 500,000 coins in total." },
	{ Id = "ascended",     Name = "Ascended",          Stat = "Prestige",            Goal = 5,      Reward = 15000,
		Description = "Reach prestige level 5." },
}
