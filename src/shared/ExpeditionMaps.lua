-- ExpeditionMaps.lua (ModuleScript, shared)
-- Definitions for the expedition maps. Each map is a PROCEDURAL maze generated
-- by ExpeditionBuilder from `Width` x `Height` cells — so the layout is
-- different every server start and needs no bespoke art. The client reads
-- Name/Description for the map chooser. Add an entry for a new maze size/flavor.

return {
	{
		Id = "tangle",
		Name = "The Tangle",
		Description = "A cramped, pitch-black labyrinth. Bring a steady nerve — your flashlight only reaches so far.",
		Width = 6,
		Height = 5,
	},
	{
		Id = "warren",
		Name = "The Warren",
		Description = "Tight, winding corridors that double back on themselves. The things in here know the way better than you do.",
		Width = 7,
		Height = 7,
	},
	{
		Id = "sprawl",
		Name = "The Sprawl",
		Description = "A vast unlit maze. More room to run — and far more places to lose your way and your loot.",
		Width = 8,
		Height = 6,
	},
}
