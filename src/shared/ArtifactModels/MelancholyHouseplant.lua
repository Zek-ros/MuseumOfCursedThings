-- Model builder for "Melancholy Houseplant" (MelancholyHouseplant).
-- "Wilts dramatically when criticized. Cannot be over-watered, only out-grieved."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "MelancholyHouseplant"

	local pot = Instance.new("Part")
	pot.Shape = Enum.PartType.Cylinder
	pot.Size = Vector3.new(2,2,2)
	pot.Color = Color3.fromRGB(120,70,40)
	pot.Anchored = true
	pot.Parent = model

	local stem = Instance.new("Part")
	stem.Size = Vector3.new(0.3,3,0.3)
	stem.Position = Vector3.new(0,2,0)
	stem.Color = Color3.fromRGB(40,120,40)
	stem.Anchored = true
	stem.Parent = model

	return model
end

return Create
