-- Model builder for "Angry Toaster" (AngryToaster).
-- "Launches burning toast at visitors. Has been returned 47 times."
--
-- Paste your object-building script here — a Create() function that builds and
-- returns a Model — then `return Create` at the bottom (replacing the line
-- below). Build it around the origin (0, 0, 0); set model.PrimaryPart to the
-- part that should sit at the display point. Until then, this artifact uses the
-- default neon-cube placeholder.

local function Create()
	local model = Instance.new("Model")
	model.Name = "AngryToaster"

	local body = Instance.new("Part")
	body.Size = Vector3.new(4,3,2)
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(80,80,80)
	body.Anchored = true
	body.Parent = model

	for _,x in pairs({-0.8,0.8}) do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.4,0.4,0.4)
		eye.Position = Vector3.new(x,0.5,-1.1)
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.fromRGB(255,0,0)
		eye.Anchored = true
		eye.Parent = model
	end

	return model
end

return Create
