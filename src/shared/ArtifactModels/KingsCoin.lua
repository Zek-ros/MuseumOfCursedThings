-- Model builder for "King's Coin" (KingsCoin).
-- "Steals nearby income. The king is not sorry."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "KingsCoin"

	local coin = Instance.new("Part")
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(3,0.3,3)
	coin.Material = Enum.Material.Metal
	coin.Color = Color3.fromRGB(255,215,0)
	coin.Anchored = true
	coin.Parent = model

	return model
end

return Create
