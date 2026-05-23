-- Model builder for "Meat Computer" (MeatComputer).
-- "Predicts disasters. Has been right 100% of the time."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "MeatComputer"

	local monitor = Instance.new("Part")
	monitor.Size = Vector3.new(4,3,1)
	monitor.Color = Color3.fromRGB(120,40,40)
	monitor.Material = Enum.Material.Fabric
	monitor.Anchored = true
	monitor.Parent = model

	local screen = Instance.new("Part")
	screen.Size = Vector3.new(3.3,2.3,0.1)
	screen.Position = Vector3.new(0,0,-0.6)
	screen.Material = Enum.Material.Neon
	screen.Color = Color3.fromRGB(255,0,0)
	screen.Anchored = true
	screen.Parent = model

	return model
end

return Create
