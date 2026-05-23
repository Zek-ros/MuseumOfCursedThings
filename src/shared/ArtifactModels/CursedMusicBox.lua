-- Model builder for "Cursed Music Box" (CursedMusicBox).
-- "Plays a lullaby when no one's winding it. The ballerina is facing the wrong way again."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "CursedMusicBox"

	local box = Instance.new("Part")
	box.Size = Vector3.new(3,2,3)
	box.Material = Enum.Material.Wood
	box.Color = Color3.fromRGB(90,60,40)
	box.Anchored = true
	box.Parent = model

	return model
end

return Create
