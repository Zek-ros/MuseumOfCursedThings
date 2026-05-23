-- Model builder for "Haunted Umbrella" (HauntedUmbrella).
-- "Opens itself indoors. The bad luck is, frankly, relentless."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "HauntedUmbrella"

	local handle = Instance.new("Part")
	handle.Size = Vector3.new(0.3,5,0.3)
	handle.Color = Color3.fromRGB(60,40,20)
	handle.Anchored = true
	handle.Parent = model

	local canopy = Instance.new("Part")
	canopy.Shape = Enum.PartType.Ball
	canopy.Size = Vector3.new(5,2,5)
	canopy.Position = Vector3.new(0,3,0)
	canopy.Color = Color3.fromRGB(20,20,20)
	canopy.Anchored = true
	canopy.Parent = model

	return model
end

return Create
