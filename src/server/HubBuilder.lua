-- HubBuilder.lua (ModuleScript)
-- Builds the shared social hub: where players spawn, meet, and queue for group
-- expeditions. Procedural for now; swap for a real model later.

local HubBuilder = {}

local HUB_X = 70
local HUB_Z = 70
local WALL_HEIGHT = 16
local WALL_THICK = 1

local FLOOR_COLOR = Color3.fromRGB(46, 42, 56)
local WALL_COLOR  = Color3.fromRGB(34, 31, 44)
local ACCENT      = Color3.fromRGB(140, 90, 220)

local function makePart(origin, parent, name, size, localPos, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = origin * CFrame.new(localPos)
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function labelOn(part: BasePart, text: string, color: Color3, offsetY: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 240, 0, 50)
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 100
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard
	billboard.Parent = part
end

--- Build the hub at the given origin. Returns { Model, Spawn, QueuePad, MuseumPad }.
function HubBuilder.Build(origin: CFrame)
	local model = Instance.new("Model")
	model.Name = "Hub"

	local halfX, halfZ = HUB_X / 2, HUB_Z / 2
	local wallY = WALL_HEIGHT / 2

	makePart(origin, model, "Floor", Vector3.new(HUB_X, WALL_THICK, HUB_Z),
		Vector3.new(0, -WALL_THICK / 2, 0), FLOOR_COLOR, Enum.Material.Marble)
	makePart(origin, model, "WallBack", Vector3.new(HUB_X, WALL_HEIGHT, WALL_THICK),
		Vector3.new(0, wallY, -halfZ), WALL_COLOR, Enum.Material.Concrete)
	makePart(origin, model, "WallFront", Vector3.new(HUB_X, WALL_HEIGHT, WALL_THICK),
		Vector3.new(0, wallY, halfZ), WALL_COLOR, Enum.Material.Concrete)
	makePart(origin, model, "WallLeft", Vector3.new(WALL_THICK, WALL_HEIGHT, HUB_Z),
		Vector3.new(-halfX, wallY, 0), WALL_COLOR, Enum.Material.Concrete)
	makePart(origin, model, "WallRight", Vector3.new(WALL_THICK, WALL_HEIGHT, HUB_Z),
		Vector3.new(halfX, wallY, 0), WALL_COLOR, Enum.Material.Concrete)

	-- Roof
	makePart(origin, model, "Ceiling", Vector3.new(HUB_X, WALL_THICK, HUB_Z),
		Vector3.new(0, WALL_HEIGHT + WALL_THICK / 2, 0), WALL_COLOR, Enum.Material.Concrete)

	-- Warm lights
	for _, lx in ipairs({ -20, 20 }) do
		local fixture = makePart(origin, model, "LightFixture", Vector3.new(3, 0.4, 3),
			Vector3.new(lx, WALL_HEIGHT - 1, 0), Color3.fromRGB(20, 20, 20), Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(220, 200, 255)
		light.Brightness = 2
		light.Range = 36
		light.Parent = fixture
	end

	-- Central sign
	local sign = makePart(origin, model, "Sign", Vector3.new(16, 6, 1),
		Vector3.new(0, 9, -halfZ + 2), ACCENT, Enum.Material.Neon)
	labelOn(sign, "MUSEUM OF CURSED THINGS", Color3.fromRGB(255, 255, 255), 0)

	-- Expedition Queue pad (purple, near the back)
	local queuePad = Instance.new("Part")
	queuePad.Name = "QueuePad"
	queuePad.Anchored = true
	queuePad.CanCollide = false
	queuePad.Size = Vector3.new(10, 1, 10)
	queuePad.CFrame = origin * CFrame.new(-14, 0.5, -10)
	queuePad.Color = ACCENT
	queuePad.Material = Enum.Material.Neon
	queuePad.Transparency = 0.3
	labelOn(queuePad, "🔦 EXPEDITION QUEUE", Color3.fromRGB(230, 200, 255), 5)
	local qLight = Instance.new("PointLight")
	qLight.Color = ACCENT
	qLight.Range = 16
	qLight.Brightness = 3
	qLight.Parent = queuePad
	queuePad.Parent = model

	-- My Museum pad (gold)
	local museumPad = Instance.new("Part")
	museumPad.Name = "MuseumPad"
	museumPad.Anchored = true
	museumPad.CanCollide = false
	museumPad.Size = Vector3.new(10, 1, 10)
	museumPad.CFrame = origin * CFrame.new(14, 0.5, -10)
	museumPad.Color = Color3.fromRGB(230, 190, 70)
	museumPad.Material = Enum.Material.Neon
	museumPad.Transparency = 0.3
	labelOn(museumPad, "🏛 MY MUSEUM", Color3.fromRGB(255, 235, 170), 5)
	local mLight = Instance.new("PointLight")
	mLight.Color = Color3.fromRGB(255, 220, 120)
	mLight.Range = 16
	mLight.Brightness = 3
	mLight.Parent = museumPad
	museumPad.Parent = model

	-- Spawn near the front, facing the pads
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = origin * CFrame.new(0, 0.5, halfZ - 10)
	spawn.Color = Color3.fromRGB(70, 120, 90)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.Duration = 0
	spawn.Parent = model

	return {
		Model = model,
		Spawn = spawn,
		QueuePad = queuePad,
		MuseumPad = museumPad,
	}
end

return HubBuilder
