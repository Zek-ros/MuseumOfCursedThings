-- SoundData.lua (ModuleScript, shared)
-- Central sound config. Fill in Roblox audio asset ids (numbers) to enable
-- each sound — exactly like the model-swap framework. Id = 0 means "silent"
-- (the audio system simply skips it), so the game runs fine with no audio until
-- you've sourced real sounds.
--
-- HOW TO FILL THESE IN: in Studio open the Toolbox (View > Toolbox) > Audio tab,
-- or the Creator Store > Audio. Search the suggested term, click a free sound,
-- copy its Asset ID (the number in its URL / right-click > Copy Asset ID), and
-- paste it as the Id below. Uploaded/free audio only plays in the PUBLISHED game
-- (same placeid-0 limitation as meshes), so test sound in the live game.

return {
	-- Looping ambience (swapped based on where the player is)
	-- search: "ambient drone dark", "horror ambience", "eerie hum"
	MuseumAmbient     = { Id = 121654813380487, Volume = 0.25, Looped = true },
	-- search: "dungeon ambience", "cave wind", "dark reverb ambience"
	ExpeditionAmbient = { Id = 140115427069802, Volume = 0.35, Looped = true },

	-- Looping heartbeat that rises as a monster closes in (driven by proximity).
	-- search: "heartbeat loop", "heart beat"
	Heartbeat   = { Id = 6202853067, Volume = 0.55, Looped = true },

	-- One-shot stings / cues
	Coin        = { Id = 118144738910720, Volume = 0.40 }, -- passive income tick   (search: "coin", "cash register ding")
	ChaosSting  = { Id = 1846887108, Volume = 0.60 }, -- any chaos event fires  (search: "horror sting", "scary hit")
	MonsterSteal = { Id = 84772348230714, Volume = 0.75 }, -- a monster snatches your artifact (search: "monster snarl", "creature roar")
	MonsterGrab = { Id = 88417615058927, Volume = 0.70 }, -- a monster catches you  (search: "monster growl", "jumpscare")
	Extract     = { Id = 86584710094973, Volume = 0.55 }, -- successful extraction  (search: "success chime", "level up")
	Discover    = { Id = 75550445815052, Volume = 0.55 }, -- new artifact obtained  (search: "magic sparkle", "reward")
}
