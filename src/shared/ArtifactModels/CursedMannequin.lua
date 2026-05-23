-- Model builder for "Cursed Mannequin" (CursedMannequin).
-- "Moves when not observed. Scientists refuse to investigate."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "CursedMannequin"

	local torso = Instance.new("Part")
	torso.Size = Vector3.new(2,3,1)
	torso.Color = Color3.fromRGB(230,230,230)
	torso.Anchored = true
	torso.Parent = model

	local head = Instance.new("Part")
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2,2,2)
	head.Position = Vector3.new(0,2.5,0)
	head.Color = torso.Color
	head.Anchored = true
	head.Parent = model

	return model
end

return Create
