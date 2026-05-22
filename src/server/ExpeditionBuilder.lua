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

-- Like makePart but takes a full local CFrame (so props can be rotated).
local function makePartCF(origin, parent, name, size, cframeLocal, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = origin * cframeLocal
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- =============================================
--  THEMED PROPS — make each map read as a distinct place.
--  (Procedural for now; swap for real models via ModelFactory later.)
-- =============================================
local function schoolProps(origin, model)
	-- Cracked chalkboard on the back wall
	makePart(origin, model, "Chalkboard", Vector3.new(26, 9, 0.4),
		Vector3.new(0, 8, -34.6), Color3.fromRGB(24, 60, 42), Enum.Material.SmoothPlastic)
	-- Rows of desks
	for _, dx in ipairs({ -30, -18, -6, 6, 18, 30 }) do
		for _, dz in ipairs({ -24, -12 }) do
			makePart(origin, model, "Desk", Vector3.new(3, 2, 2),
				Vector3.new(dx, 1, dz), Color3.fromRGB(95, 62, 40), Enum.Material.Wood)
		end
	end
	-- Lockers down both side walls
	for _, lz in ipairs({ -22, -10, 2, 14 }) do
		makePart(origin, model, "Locker", Vector3.new(2, 9, 4),
			Vector3.new(-43.5, 4.5, lz), Color3.fromRGB(80, 92, 112), Enum.Material.Metal)
		makePart(origin, model, "Locker", Vector3.new(2, 9, 4),
			Vector3.new(43.5, 4.5, lz), Color3.fromRGB(80, 92, 112), Enum.Material.Metal)
	end
end

local function labProps(origin, model)
	-- Glowing containment pods along the back
	for _, px in ipairs({ -28, -14, 0, 14, 28 }) do
		local pod = makePartCF(origin, model, "ContainmentPod", Vector3.new(7, 4, 4),
			CFrame.new(px, 3.5, -28) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(90, 180, 220), Enum.Material.Neon)
		pod.Shape = Enum.PartType.Cylinder
		pod.Transparency = 0.45
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(90, 180, 220)
		glow.Range = 12
		glow.Brightness = 2
		glow.Parent = pod
	end
	-- Steel lab tables
	for _, tx in ipairs({ -24, -8, 8, 24 }) do
		makePart(origin, model, "LabTable", Vector3.new(8, 3, 3),
			Vector3.new(tx, 1.5, -6), Color3.fromRGB(120, 128, 135), Enum.Material.Metal)
	end
	-- Caution stripe on the floor
	makePart(origin, model, "Caution", Vector3.new(60, 0.12, 2),
		Vector3.new(0, 0.07, 14), Color3.fromRGB(220, 200, 40), Enum.Material.SmoothPlastic)
end

local function mallProps(origin, model)
	local storeColors = {
		Color3.fromRGB(200, 80, 90),
		Color3.fromRGB(80, 160, 200),
		Color3.fromRGB(200, 180, 80),
		Color3.fromRGB(150, 100, 200),
	}
	local i = 0
	for _, sz in ipairs({ -22, -6, 10 }) do
		i += 1
		makePart(origin, model, "Storefront", Vector3.new(1.2, 10, 12),
			Vector3.new(-43.4, 5, sz), storeColors[((i - 1) % #storeColors) + 1], Enum.Material.SmoothPlastic)
		makePart(origin, model, "Storefront", Vector3.new(1.2, 10, 12),
			Vector3.new(43.4, 5, sz), storeColors[(i % #storeColors) + 1], Enum.Material.SmoothPlastic)
	end
	-- Dry fountain in the middle
	local basin = makePartCF(origin, model, "Fountain", Vector3.new(2, 12, 12),
		CFrame.new(0, 1, -6) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(120, 120, 130), Enum.Material.Marble)
	basin.Shape = Enum.PartType.Cylinder
	-- Planters
	for _, px in ipairs({ -20, 20 }) do
		makePart(origin, model, "Planter", Vector3.new(4, 2, 4),
			Vector3.new(px, 1, -22), Color3.fromRGB(90, 70, 55), Enum.Material.Wood)
	end
end

local PROP_BUILDERS = {
	school = schoolProps,
	lab = labProps,
	mall = mallProps,
}

local function buildProps(origin, model, theme)
	local fn = PROP_BUILDERS[theme.Theme]
	if fn then
		local ok, err = pcall(fn, origin, model)
		if not ok then
			warn("[ExpeditionBuilder] props for " .. tostring(theme.Theme) .. " failed: " .. tostring(err))
		end
	end
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

	-- Roof
	makePart(origin, model, "Ceiling", Vector3.new(EX_X, WALL_THICK, EX_Z),
		Vector3.new(0, WALL_HEIGHT + WALL_THICK / 2, 0), wallColor, Enum.Material.Concrete)

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

	-- Themed props that make this map look like its name
	buildProps(origin, model, theme)

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
	exBillboard.AlwaysOnTop = false
	exBillboard.MaxDistance = 120 -- visible across the map you're in, not beyond
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
