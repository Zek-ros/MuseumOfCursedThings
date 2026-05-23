-- Model builder for "Dimensional Mirror" (DimensionalMirror).
-- "Creates fake player clones. The clones remember everything."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "DimensionalMirror"

	local frame = Instance.new("Part")
	frame.Size = Vector3.new(5,8,0.5)
	frame.Material = Enum.Material.Metal
	frame.Color = Color3.fromRGB(40,40,40)
	frame.Anchored = true
	frame.Parent = model

	local glass = Instance.new("Part")
	glass.Size = Vector3.new(4,7,0.1)
	glass.Position = Vector3.new(0,0,-0.3)
	glass.Material = Enum.Material.Glass
	glass.Transparency = 0.3
	glass.Color = Color3.fromRGB(100,0,255)
	glass.Anchored = true
	glass.Parent = model

	return model
end

return Create
