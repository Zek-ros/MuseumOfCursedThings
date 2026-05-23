-- Model builder for "Eternal Candle" (EternalCandle).
-- "Never melts, never goes out, and gets noticeably hotter before bad things happen."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "EternalCandle"

	-- Invisible upright root so PivotTo/spin keeps the rotated cylinder vertical.
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root

	local candle = Instance.new("Part")
	candle.Shape = Enum.PartType.Cylinder
	candle.Size = Vector3.new(4, 0.9, 0.9) -- length (X) is the height
	candle.CFrame = CFrame.Angles(0, 0, math.rad(90)) -- stand it upright
	candle.Color = Color3.fromRGB(255,240,200)
	candle.Anchored = true
	candle.Parent = model

	local flame = Instance.new("Part")
	flame.Shape = Enum.PartType.Ball
	flame.Size = Vector3.new(0.5,1,0.5)
	flame.Position = Vector3.new(0,2.5,0)
	flame.Material = Enum.Material.Neon
	flame.Color = Color3.fromRGB(255,120,0)
	flame.Anchored = true
	flame.Parent = model

	return model
end

return Create
