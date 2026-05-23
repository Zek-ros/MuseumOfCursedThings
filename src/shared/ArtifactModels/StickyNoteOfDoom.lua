-- Model builder for "Sticky Note of Doom" (StickyNoteOfDoom).
-- "Always reads 'behind you :)'. It is never wrong."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "StickyNoteOfDoom"

	local note = Instance.new("Part")
	note.Size = Vector3.new(2,2,0.1)
	note.Color = Color3.fromRGB(255,255,120)
	note.Material = Enum.Material.SmoothPlastic
	note.Anchored = true
	note.Parent = model

	return model
end

return Create
