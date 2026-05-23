-- Model builder for "Possessed Roomba" (PossessedRoomba).
-- "Patrols the museum at night. Judges your cleanliness. Plots."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "PossessedRoomba"

	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(3,1,3)
	body.Color = Color3.fromRGB(30,30,30)
	body.Anchored = true
	body.Parent = model

	return model
end

return Create
