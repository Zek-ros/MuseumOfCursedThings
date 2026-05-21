-- ExpeditionBuilder.lua (ModuleScript)
-- Builds the shared expedition map: a dim, cold "abandoned location" where
-- artifacts spawn to be collected and carried back to an extraction pad.
-- Geometry is procedural so it lives in the Rojo project (swap for real
-- models / multiple themed maps later).

local ExpeditionBuilder = {}

local EX_X = 90
local EX_Z = 70
local WALL_HEIGHT = 20
local WALL_THICK = 1

-- Fallback theme if none is supplied
local DEFAULT_THEME = {
	Floor  = Color3.fromRGB(30, 34, 38),
	Wall   = Color3.fromRGB(22, 26, 30),
	Pillar = Color3.fromRGB(40, 44, 50),
	Light  = Color3.fromRGB(120, 200, 220),
}

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

--- Build the expedition map at the given origin (center of floor top).
-- `theme` supplies Floor/Wall/Pillar/Light colors (see ExpeditionMaps).
-- Returns { Model, SpawnCFrame, ExtractionZone, SpawnPoints = {CFrame...} }.
function ExpeditionBuilder.Build(origin: CFrame, theme)
	theme = theme or DEFAULT_THEME
	local floorColor  = theme.Floor  or DEFAULT_THEME.Floor
	local wallColor   = theme.Wall   or DEFAULT_THEME.Wall
	local pillarColor = theme.Pillar or DEFAULT_THEME.Pillar
	local lightColor  = theme.Light  or DEFAULT_THEME.Light

	local model = Instance.new("Model")
	model.Name = "ExpeditionMap_" .. (theme.Id or "default")

	local halfX, halfZ = EX_X / 2, EX_Z / 2
	local wallY = WALL_HEIGHT / 2

	-- Floor
	makePart(origin, model, "Floor",
		Vector3.new(EX_X, WALL_THICK, EX_Z),
		Vector3.new(0, -WALL_THICK / 2, 0), floorColor, Enum.Material.Concrete)

	-- Walls
	makePart(origin, model, "WallBack", Vector3.new(EX_X, WALL_HEIGHT, WALL_THICK),
		Vector3.new(0, wallY, -halfZ), wallColor, Enum.Material.Concrete)
	makePart(origin, model, "WallFront", Vector3.new(EX_X, WALL_HEIGHT, WALL_THICK),
		Vector3.new(0, wallY, halfZ), wallColor, Enum.Material.Concrete)
	makePart(origin, model, "WallLeft", Vector3.new(WALL_THICK, WALL_HEIGHT, EX_Z),
		Vector3.new(-halfX, wallY, 0), wallColor, Enum.Material.Concrete)
	makePart(origin, model, "WallRight", Vector3.new(WALL_THICK, WALL_HEIGHT, EX_Z),
		Vector3.new(halfX, wallY, 0), wallColor, Enum.Material.Concrete)

	-- Atmospheric pillars + lights
	for _, px in ipairs({ -22, 0, 22 }) do
		for _, pz in ipairs({ -16, 16 }) do
			makePart(origin, model, "Pillar", Vector3.new(4, WALL_HEIGHT, 4),
				Vector3.new(px, wallY, pz), pillarColor, Enum.Material.Slate)
			local fixture = makePart(origin, model, "LightFixture", Vector3.new(2, 0.4, 2),
				Vector3.new(px, WALL_HEIGHT - 1, pz), Color3.fromRGB(15, 15, 15), Enum.Material.Metal)
			local light = Instance.new("PointLight")
			light.Color = lightColor
			light.Brightness = 1.5
			light.Range = 22
			light.Parent = fixture
		end
	end

	-- Entrance / arrival spawn near the front wall
	local spawnCFrame = origin * CFrame.new(0, 4, halfZ - 8)

	-- Extraction pad next to the entrance (glowing green)
	local extraction = Instance.new("Part")
	extraction.Name = "ExtractionZone"
	extraction.Anchored = true
	extraction.CanCollide = false
	extraction.Size = Vector3.new(12, 1, 12)
	extraction.CFrame = origin * CFrame.new(0, 0.5, halfZ - 8)
	extraction.Color = Color3.fromRGB(60, 230, 120)
	extraction.Material = Enum.Material.Neon
	extraction.Transparency = 0.35
	local exLight = Instance.new("PointLight")
	exLight.Color = Color3.fromRGB(80, 255, 140)
	exLight.Range = 20
	exLight.Brightness = 4
	exLight.Parent = extraction
	local exBillboard = Instance.new("BillboardGui")
	exBillboard.Size = UDim2.new(0, 220, 0, 50)
	exBillboard.StudsOffset = Vector3.new(0, 5, 0)
	exBillboard.AlwaysOnTop = true
	local exLabel = Instance.new("TextLabel")
	exLabel.Size = UDim2.fromScale(1, 1)
	exLabel.BackgroundTransparency = 1
	exLabel.Text = "⮟ EXTRACTION ⮟"
	exLabel.TextColor3 = Color3.fromRGB(120, 255, 170)
	exLabel.Font = Enum.Font.GothamBold
	exLabel.TextScaled = true
	exLabel.Parent = exBillboard
	exBillboard.Parent = extraction
	extraction.Parent = model

	-- Scatter artifact spawn points across the back/middle of the room
	local spawnPoints = {}
	local cols = { -30, -15, 0, 15, 30 }
	local rows = { -18, 2 }
	for _, sx in ipairs(cols) do
		for _, sz in ipairs(rows) do
			table.insert(spawnPoints, origin * CFrame.new(sx, 3, sz))
		end
	end

	return {
		Model = model,
		SpawnCFrame = spawnCFrame,
		ExtractionZone = extraction,
		SpawnPoints = spawnPoints,
	}
end

return ExpeditionBuilder
