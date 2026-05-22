-- ExpeditionMaps.lua (ModuleScript, shared)
-- Definitions for the expedition maps. The server builds one of each from these
-- themes; the client reads Name/Description for the map chooser.
-- `Theme` selects which procedural prop set ExpeditionBuilder lays down so each
-- map reads as a distinct place. Add an entry here for a new themed map.

return {
	{
		Id = "school",
		Theme = "school",
		Name = "Abandoned School",
		Description = "Rows of empty desks, a cracked chalkboard, lockers that rattle on their own.",
		Floor  = Color3.fromRGB(64, 56, 44),
		Wall   = Color3.fromRGB(48, 42, 33),
		Pillar = Color3.fromRGB(74, 66, 52),
		Light  = Color3.fromRGB(232, 222, 170),
	},
	{
		Id = "lab",
		Theme = "lab",
		Name = "Underground Lab",
		Description = "Humming containment pods and steel tables. One of the pods is open.",
		Floor  = Color3.fromRGB(32, 36, 40),
		Wall   = Color3.fromRGB(24, 28, 32),
		Pillar = Color3.fromRGB(42, 46, 52),
		Light  = Color3.fromRGB(120, 200, 220),
	},
	{
		Id = "mall",
		Theme = "mall",
		Name = "Cursed Shopping Mall",
		Description = "Dead storefronts, a dry fountain, and muzak that stopped decades ago.",
		Floor  = Color3.fromRGB(70, 66, 72),
		Wall   = Color3.fromRGB(54, 50, 58),
		Pillar = Color3.fromRGB(88, 84, 92),
		Light  = Color3.fromRGB(255, 210, 230),
	},
}
