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
