-- Model builder for "Weeping Mug" (WeepingMug).
-- "Cries when nobody is watching. Somehow always knows."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "WeepingMug"

	local mug = Instance.new("Part")
	mug.Shape = Enum.PartType.Cylinder
	mug.Size = Vector3.new(2,2,2)
	mug.Material = Enum.Material.SmoothPlastic
	mug.Color = Color3.fromRGB(240,240,240)
	mug.Anchored = true
	mug.Parent = model

	local tear = Instance.new("Part")
	tear.Shape = Enum.PartType.Ball
	tear.Size = Vector3.new(0.2,0.5,0.2)
	tear.Position = Vector3.new(0,-1,1)
	tear.Material = Enum.Material.Neon
	tear.Color = Color3.fromRGB(100,180,255)
	tear.Anchored = true
	tear.Parent = model

	return model
end

return Create
