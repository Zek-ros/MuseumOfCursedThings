-- Model builder for "Possessed Television" (PossessedTelevision).
-- "Broadcasts channels that don't exist. One of them is showing your museum. Right now."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "PossessedTelevision"

	local tv = Instance.new("Part")
	tv.Size = Vector3.new(5,4,2)
	tv.Color = Color3.fromRGB(30,30,30)
	tv.Anchored = true
	tv.Parent = model

	local screen = Instance.new("Part")
	screen.Size = Vector3.new(4,3,0.1)
	screen.Position = Vector3.new(0,0,-1.1)
	screen.Material = Enum.Material.Neon
	screen.Color = Color3.fromRGB(255,255,255)
	screen.Anchored = true
	screen.Parent = model

	return model
end

return Create
