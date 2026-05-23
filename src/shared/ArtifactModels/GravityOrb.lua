-- Model builder for "Gravity Orb" (GravityOrb).
-- "Forgets which way is down. So does everything near it."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "GravityOrb"

	local orb = Instance.new("Part")
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(4,4,4)
	orb.Material = Enum.Material.Neon
	orb.Color = Color3.fromRGB(120,0,255)
	orb.Anchored = true
	orb.Parent = model

	return model
end

return Create
