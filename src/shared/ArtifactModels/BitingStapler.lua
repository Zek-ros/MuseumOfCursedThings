-- Model builder for "The Biting Stapler" (BitingStapler).
-- "Snaps at fingers and flings staples at passersby. HR has a thick file on it."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "BitingStapler"

	local base = Instance.new("Part")
	base.Size = Vector3.new(3,0.5,1)
	base.Color = Color3.fromRGB(50,50,50)
	base.Anchored = true
	base.Parent = model

	local top = Instance.new("Part")
	top.Size = Vector3.new(3,0.4,1)
	top.Position = Vector3.new(0,0.6,0)
	top.Color = Color3.fromRGB(70,70,70)
	top.Anchored = true
	top.Parent = model

	return model
end

return Create
