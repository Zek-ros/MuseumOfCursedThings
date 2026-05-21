-- ExpeditionMaps.lua (ModuleScript, shared)
-- Definitions for the expedition maps. The server builds one of each from
-- these themes; the client reads Name/Description for the map chooser.
-- Add a new entry here and a new themed map appears in the game.

return {
	{
		Id = "school",
		Name = "Abandoned School",
		Description = "Dusty halls and flickering fluorescents. The silence watches back.",
		Floor  = Color3.fromRGB(60, 54, 44),
		Wall   = Color3.fromRGB(45, 40, 32),
		Pillar = Color3.fromRGB(72, 64, 50),
		Light  = Color3.fromRGB(230, 220, 170),
	},
	{
		Id = "lab",
		Name = "Underground Lab",
		Description = "Cold containment cells and emergency lighting. Something got out.",
		Floor  = Color3.fromRGB(30, 34, 38),
		Wall   = Color3.fromRGB(22, 26, 30),
		Pillar = Color3.fromRGB(40, 44, 50),
		Light  = Color3.fromRGB(120, 200, 220),
	},
}
