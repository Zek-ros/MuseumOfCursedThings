-- SoundData.lua (ModuleScript, shared)
-- Central sound config. Fill in Roblox audio asset ids (numbers) to enable
-- each sound — exactly like the model-swap framework. Id = 0 means "silent"
-- (the audio system simply skips it), so the game runs fine with no audio until
-- you've sourced real sounds.

return {
	-- Looping ambience (swapped based on where the player is)
	MuseumAmbient     = { Id = 0, Volume = 0.30, Looped = true },
	ExpeditionAmbient = { Id = 0, Volume = 0.35, Looped = true },

	-- One-shot stings / cues
	Coin       = { Id = 0, Volume = 0.45 },  -- passive income tick
	ChaosSting = { Id = 0, Volume = 0.60 },  -- any chaos event fires
	MonsterGrab = { Id = 0, Volume = 0.70 }, -- a monster catches you
	Extract    = { Id = 0, Volume = 0.55 },  -- successful extraction
	Discover   = { Id = 0, Volume = 0.55 },  -- new artifact obtained
}
