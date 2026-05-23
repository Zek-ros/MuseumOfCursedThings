-- Model builder for "Infinite Hamster" (InfiniteHamster).
-- "Duplicates over time. Museum regulations unclear."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "InfiniteHamster"

	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2,2,2)
	body.Color = Color3.fromRGB(181,120,65)
	body.Anchored = true
	body.Parent = model

	return model
end

return Create