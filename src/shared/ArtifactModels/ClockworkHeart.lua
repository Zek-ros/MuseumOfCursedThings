-- Model builder for "Clockwork Heart" (ClockworkHeart).
-- "Ticks louder the more danger surrounds it. Right now it is very, very loud."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "ClockworkHeart"

	local heart = Instance.new("Part")
	heart.Shape = Enum.PartType.Ball
	heart.Size = Vector3.new(3,3,3)
	heart.Material = Enum.Material.Metal
	heart.Color = Color3.fromRGB(180,0,0)
	heart.Anchored = true
	heart.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255,0,0)
	light.Brightness = 3
	light.Range = 12
	light.Parent = heart

	return model
end

return Create
