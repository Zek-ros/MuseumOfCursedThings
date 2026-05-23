-- Model builder for "Teeth Phone" (TeethPhone).
-- "Rings during chaos events. Never good news."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "TeethPhone"

	local base = Instance.new("Part")
	base.Size = Vector3.new(3,1,3)
	base.Color = Color3.fromRGB(20,20,20)
	base.Anchored = true
	base.Parent = model

	for i=-2,2 do
		local tooth = Instance.new("WedgePart")
		tooth.Size = Vector3.new(0.4,0.7,0.4)
		tooth.Position = Vector3.new(i*0.45,-0.2,-1.2)
		tooth.Color = Color3.fromRGB(255,255,220)
		tooth.Anchored = true
		tooth.Parent = model
	end

	return model
end

return Create
