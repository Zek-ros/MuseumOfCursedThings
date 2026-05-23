-- Model builder for "Possessed Roomba" (PossessedRoomba).
-- "Patrols the museum at night. Judges your cleanliness. Plots."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "PossessedRoomba"

	-- Invisible upright root so PivotTo/spin keeps the rotated cylinder flat.
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root

	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(1, 3, 3) -- thin disc (length X = 1 thick, 3 wide)
	body.CFrame = CFrame.Angles(0, 0, math.rad(90)) -- lay it flat like a roomba
	body.Color = Color3.fromRGB(30,30,30)
	body.Anchored = true
	body.Parent = model

	return model
end

return Create
