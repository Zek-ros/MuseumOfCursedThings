-- ArtifactData.lua
-- Defines every artifact and containment type in the game.
-- Adding a new artifact is as simple as adding a new entry to the table.

local ArtifactData = {}

-- =============================================
--  ARTIFACTS
-- =============================================
ArtifactData.Artifacts = {

	-- ===== COMMON =====

	WhisperingLamp = {
		Name = "Whispering Lamp",
		Rarity = "Common",
		DangerLevel = 1,
		Value = 40,
		PassiveIncome = 2,
		Description = "Quietly says player names. Only your name. Always.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "WhisperNames" },
	},

	BlinkingFrame = {
		Name = "Blinking Picture Frame",
		Rarity = "Common",
		DangerLevel = 1,
		Value = 35,
		PassiveIncome = 1,
		Description = "The eyes in the painting follow you. They blink when you blink.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "FlickerLights" },
	},

	-- ===== UNCOMMON =====

	TeleportingCone = {
		Name = "Teleporting Traffic Cone",
		Rarity = "Uncommon",
		DangerLevel = 2,
		Value = 70,
		PassiveIncome = 3,
		Description = "Randomly changes location. OSHA has no protocol for this.",
		ContainmentRequired = "AntiTeleportField",
		ChaosEffects = { "Teleport" },
	},

	AngryToaster = {
		Name = "Angry Toaster",
		Rarity = "Uncommon",
		DangerLevel = 3,
		Value = 80,
		PassiveIncome = 3,
		Description = "Launches burning toast at visitors. Has been returned 47 times.",
		ContainmentRequired = "ReinforcedCase",
		ChaosEffects = { "LaunchProjectile", "ScareVisitors" },
	},

	TeethPhone = {
		Name = "Teeth Phone",
		Rarity = "Uncommon",
		DangerLevel = 2,
		Value = 90,
		PassiveIncome = 4,
		Description = "Rings during chaos events. Never good news.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "RingDuringChaos" },
	},

	-- ===== RARE =====

	WeepingMug = {
		Name = "Weeping Mug",
		Rarity = "Rare",
		DangerLevel = 2,
		Value = 150,
		PassiveIncome = 5,
		Description = "Cries when nobody is watching. Somehow always knows.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "CryingSounds", "FlickerLights" },
	},

	CursedMannequin = {
		Name = "Cursed Mannequin",
		Rarity = "Rare",
		DangerLevel = 4,
		Value = 200,
		PassiveIncome = 7,
		Description = "Moves when not observed. Scientists refuse to investigate.",
		ContainmentRequired = "ElectricCage",
		ChaosEffects = { "MoveWhenUnwatched", "ScareVisitors" },
	},

	KingsCoin = {
		Name = "King's Coin",
		Rarity = "Rare",
		DangerLevel = 3,
		Value = 180,
		PassiveIncome = 6,
		Description = "Steals nearby income. The king is not sorry.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "StealIncome" },
	},

	-- ===== LEGENDARY =====

	InfiniteHamster = {
		Name = "Infinite Hamster",
		Rarity = "Legendary",
		DangerLevel = 5,
		Value = 500,
		PassiveIncome = 15,
		Description = "Duplicates over time. Museum regulations unclear.",
		ContainmentRequired = "FreezingChamber",
		ChaosEffects = { "SpawnClones", "OverrideContainment" },
	},

	MeatComputer = {
		Name = "Meat Computer",
		Rarity = "Legendary",
		DangerLevel = 6,
		Value = 600,
		PassiveIncome = 18,
		Description = "Predicts disasters. Has been right 100% of the time.",
		ContainmentRequired = "HolySeal",
		ChaosEffects = { "PredictDisaster", "GlitchReality" },
	},

	-- ===== FORBIDDEN =====

	DimensionalMirror = {
		Name = "Dimensional Mirror",
		Rarity = "Forbidden",
		DangerLevel = 8,
		Value = 1000,
		PassiveIncome = 30,
		Description = "Creates fake player clones. The clones remember everything.",
		ContainmentRequired = "ReinforcedVault",
		ChaosEffects = { "SpawnClones", "AlterServer", "GlitchReality" },
	},

	-- ===== COMMON (added) =====

	SingingDoorknob = {
		Name = "Singing Doorknob",
		Rarity = "Common",
		DangerLevel = 1,
		Value = 38,
		PassiveIncome = 2,
		Description = "Hums off-key show tunes. Knows your name and the chorus.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "WhisperNames" },
	},

	StickyNoteOfDoom = {
		Name = "Sticky Note of Doom",
		Rarity = "Common",
		DangerLevel = 1,
		Value = 32,
		PassiveIncome = 1,
		Description = "Always reads 'behind you :)'. It is never wrong.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "FlickerLights" },
	},

	MelancholyHouseplant = {
		Name = "Melancholy Houseplant",
		Rarity = "Common",
		DangerLevel = 1,
		Value = 42,
		PassiveIncome = 2,
		Description = "Wilts dramatically when criticized. Cannot be over-watered, only out-grieved.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "CryingSounds" },
	},

	-- ===== UNCOMMON (added) =====

	ScreamingAlarmClock = {
		Name = "Screaming Alarm Clock",
		Rarity = "Uncommon",
		DangerLevel = 2,
		Value = 75,
		PassiveIncome = 3,
		Description = "Goes off at 3:00 AM sharp. There is no off button. There never was.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "RingDuringChaos", "ScareVisitors" },
	},

	PossessedRoomba = {
		Name = "Possessed Roomba",
		Rarity = "Uncommon",
		DangerLevel = 3,
		Value = 95,
		PassiveIncome = 4,
		Description = "Patrols the museum at night. Judges your cleanliness. Plots.",
		ContainmentRequired = "ElectricCage",
		ChaosEffects = { "MoveWhenUnwatched", "Teleport" },
	},

	HauntedUmbrella = {
		Name = "Haunted Umbrella",
		Rarity = "Uncommon",
		DangerLevel = 2,
		Value = 70,
		PassiveIncome = 3,
		Description = "Opens itself indoors. The bad luck is, frankly, relentless.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "FlickerLights", "ScareVisitors" },
	},

	-- ===== RARE (added) =====

	PossessedTelevision = {
		Name = "Possessed Television",
		Rarity = "Rare",
		DangerLevel = 4,
		Value = 210,
		PassiveIncome = 7,
		Description = "Broadcasts channels that don't exist. One of them is showing your museum. Right now.",
		ContainmentRequired = "ElectricCage",
		ChaosEffects = { "GlitchReality", "FlickerLights" },
	},

	CursedMusicBox = {
		Name = "Cursed Music Box",
		Rarity = "Rare",
		DangerLevel = 3,
		Value = 175,
		PassiveIncome = 6,
		Description = "Plays a lullaby when no one's winding it. The ballerina is facing the wrong way again.",
		ContainmentRequired = "GlassCase",
		ChaosEffects = { "CryingSounds", "WhisperNames" },
	},

	BitingStapler = {
		Name = "The Biting Stapler",
		Rarity = "Rare",
		DangerLevel = 4,
		Value = 195,
		PassiveIncome = 7,
		Description = "Snaps at fingers and flings staples at passersby. HR has a thick file on it.",
		ContainmentRequired = "ReinforcedCase",
		ChaosEffects = { "LaunchProjectile", "ScareVisitors" },
	},

	-- ===== LEGENDARY (added) =====

	GravityOrb = {
		Name = "Gravity Orb",
		Rarity = "Legendary",
		DangerLevel = 5,
		Value = 520,
		PassiveIncome = 16,
		Description = "Forgets which way is down. So does everything near it.",
		ContainmentRequired = "FreezingChamber",
		ChaosEffects = { "GlitchReality", "SpawnClones" },
	},

	WhisperingWallpaper = {
		Name = "Whispering Wallpaper",
		Rarity = "Legendary",
		DangerLevel = 6,
		Value = 560,
		PassiveIncome = 17,
		Description = "Its pattern rearranges into faces when you look away. They are mouthing your name.",
		ContainmentRequired = "HolySeal",
		ChaosEffects = { "WhisperNames", "GlitchReality" },
	},

	EternalCandle = {
		Name = "Eternal Candle",
		Rarity = "Legendary",
		DangerLevel = 5,
		Value = 540,
		PassiveIncome = 16,
		Description = "Never melts, never goes out, and gets noticeably hotter before bad things happen.",
		ContainmentRequired = "FreezingChamber",
		ChaosEffects = { "PredictDisaster", "FlickerLights" },
	},

	-- ===== FORBIDDEN (added) =====

	HungryDoor = {
		Name = "The Hungry Door",
		Rarity = "Forbidden",
		DangerLevel = 8,
		Value = 1100,
		PassiveIncome = 32,
		Description = "Opens onto a different room every time. None of them are in this building.",
		ContainmentRequired = "ReinforcedVault",
		ChaosEffects = { "Teleport", "GlitchReality", "AlterServer" },
	},

	ClockworkHeart = {
		Name = "Clockwork Heart",
		Rarity = "Forbidden",
		DangerLevel = 7,
		Value = 950,
		PassiveIncome = 28,
		Description = "Ticks louder the more danger surrounds it. Right now it is very, very loud.",
		ContainmentRequired = "ReinforcedVault",
		ChaosEffects = { "PredictDisaster", "OverrideContainment", "AlterServer" },
	},
}

-- =============================================
--  CONTAINMENT TYPES
-- =============================================
-- DangerReduction subtracts from the artifact's effective danger score.
-- Cost is the currency price to purchase / upgrade to this containment.

ArtifactData.ContainmentTypes = {
	GlassCase        = { DangerReduction = 0, Cost = 50   },
	ReinforcedCase   = { DangerReduction = 1, Cost = 150  },
	ElectricCage     = { DangerReduction = 2, Cost = 300  },
	AntiTeleportField = { DangerReduction = 2, Cost = 350 },
	FreezingChamber  = { DangerReduction = 3, Cost = 500  },
	HolySeal         = { DangerReduction = 3, Cost = 600  },
	ReinforcedVault  = { DangerReduction = 5, Cost = 1000 },
}

return ArtifactData
