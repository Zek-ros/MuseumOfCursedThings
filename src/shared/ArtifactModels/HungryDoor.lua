-- Model builder for "The Hungry Door" (HungryDoor).
-- "Opens onto a different room every time. None of them are in this building."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "HungryDoor"

	local door = Instance.new("Part")
	door.Size = Vector3.new(4,8,0.5)
	door.Material = Enum.Material.Wood
	door.Color = Color3.fromRGB(60,30,20)
	door.Anchored = true
	door.Parent = model

	local mouth = Instance.new("Part")
	mouth.Size = Vector3.new(2,1,0.2)
	mouth.Position = Vector3.new(0,-1,-0.3)
	mouth.Material = Enum.Material.Neon
	mouth.Color = Color3.fromRGB(255,0,0)
	mouth.Anchored = true
	mouth.Parent = model

	return model
end

return Create
