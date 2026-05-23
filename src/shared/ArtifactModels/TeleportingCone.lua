-- Model builder for "Teleporting Traffic Cone" (TeleportingCone).
-- "Randomly changes location. OSHA has no protocol for this."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "TeleportingCone"

	local cone = Instance.new("Part")
	cone.Shape = Enum.PartType.Cylinder
	cone.Size = Vector3.new(1.5,3,1.5)
	cone.Color = Color3.fromRGB(255,120,0)
	cone.Anchored = true
	cone.Parent = model

	local stripe = Instance.new("Part")
	stripe.Size = Vector3.new(1.7,0.4,1.7)
	stripe.Position = Vector3.new(0,0.6,0)
	stripe.Material = Enum.Material.Neon
	stripe.Color = Color3.fromRGB(255,255,255)
	stripe.Anchored = true
	stripe.Parent = model

	return model
end

return Create
