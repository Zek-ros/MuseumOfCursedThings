-- Model builder for "Screaming Alarm Clock" (ScreamingAlarmClock).
-- "Goes off at 3:00 AM sharp. There is no off button. There never was."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "ScreamingAlarmClock"

	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(1, 3, 3) -- round clock face: 3 wide, 1 thick (was a flat ellipse)
	body.Color = Color3.fromRGB(220,0,0)
	body.Anchored = true
	body.Parent = model

	return model
end

return Create
