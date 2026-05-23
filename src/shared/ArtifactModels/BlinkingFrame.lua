-- Model builder for "Blinking Picture Frame" (BlinkingFrame).
-- "The eyes in the painting follow you. They blink when you blink."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "BlinkingFrame"

	local frame = Instance.new("Part")
	frame.Size = Vector3.new(4,5,0.4)
	frame.Material = Enum.Material.Wood
	frame.Color = Color3.fromRGB(90,60,40)
	frame.Anchored = true
	frame.Parent = model

	local painting = Instance.new("Part")
	painting.Size = Vector3.new(3.3,4.3,0.1)
	painting.Position = Vector3.new(0,0,-0.3)
	painting.Color = Color3.fromRGB(25,25,25)
	painting.Anchored = true
	painting.Parent = model

	return model
end

return Create