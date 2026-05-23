-- Model builder for "Whispering Wallpaper" (WhisperingWallpaper).
-- "Its pattern rearranges into faces when you look away. They are mouthing your name."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "WhisperingWallpaper"

	local wall = Instance.new("Part")
	wall.Size = Vector3.new(8,8,0.2)
	wall.Material = Enum.Material.Fabric
	wall.Color = Color3.fromRGB(100,80,100)
	wall.Anchored = true
	wall.Parent = model

	return model
end

return Create
