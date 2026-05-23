-- Model builder for "Singing Doorknob" (SingingDoorknob).
-- "Hums off-key show tunes. Knows your name and the chorus."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "SingingDoorknob"

	local knob = Instance.new("Part")
	knob.Shape = Enum.PartType.Ball
	knob.Size = Vector3.new(1,1,1)
	knob.Material = Enum.Material.Metal
	knob.Color = Color3.fromRGB(255,200,0)
	knob.Anchored = true
	knob.Parent = model

	return model
end

return Create
