-- MuseumBuilder.lua (ModuleScript)
-- Procedurally builds a stylized museum room with display pedestals.
-- Geometry is generated in code so it lives in the Rojo-synced project
-- (no hand-placed parts to keep in sync). Swap these for real models later.

local MuseumBuilder = {}

-- Room dimensions (studs)
local ROOM_X = 64        -- width
local ROOM_Z = 44        -- depth
local WALL_HEIGHT = 18
local WALL_THICK = 1
local PEDESTAL_COUNT = 6

local FLOOR_COLOR   = Color3.fromRGB(48, 44, 58)
local WALL_COLOR    = Color3.fromRGB(36, 33, 46)
local PEDESTAL_COLOR = Color3.fromRGB(90, 84, 104)
local LIGHT_COLOR   = Color3.fromRGB(255, 236, 200) -- warm museum light

-- Create an anchored part positioned relative to the museum origin.
local function makePart(origin: CFrame, parent: Instance, name: string, size: Vector3, localPos: Vector3, color: Color3, material: Enum.Material)
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

--- Build a museum at the given origin CFrame (origin = center of floor top).
-- Returns { Model, Pedestals = {Part...}, Spawn = SpawnLocation }.
function MuseumBuilder.Build(origin: CFrame, ownerName: string)
	local model = Instance.new("Model")
	model.Name = "Museum_" .. ownerName

	-- Floor (top surface sits at y = 0)
	makePart(origin, model, "Floor",
		Vector3.new(ROOM_X, WALL_THICK, ROOM_Z),
		Vector3.new(0, -WALL_THICK / 2, 0),
		FLOOR_COLOR, Enum.Material.Slate)

	-- Walls
	local halfX, halfZ = ROOM_X / 2, ROOM_Z / 2
	local wallY = WALL_HEIGHT / 2
	makePart(origin, model, "WallBack",
		Vector3.new(ROOM_X, WALL_HEIGHT, WALL_THICK),
		Vector3.new(0, wallY, -halfZ), WALL_COLOR, Enum.Material.Concrete)
	makePart(origin, model, "WallFront",
		Vector3.new(ROOM_X, WALL_HEIGHT, WALL_THICK),
		Vector3.new(0, wallY, halfZ), WALL_COLOR, Enum.Material.Concrete)
	makePart(origin, model, "WallLeft",
		Vector3.new(WALL_THICK, WALL_HEIGHT, ROOM_Z),
		Vector3.new(-halfX, wallY, 0), WALL_COLOR, Enum.Material.Concrete)
	makePart(origin, model, "WallRight",
		Vector3.new(WALL_THICK, WALL_HEIGHT, ROOM_Z),
		Vector3.new(halfX, wallY, 0), WALL_COLOR, Enum.Material.Concrete)

	-- Ceiling lights: a few warm point lights mounted near the top
	for i = -1, 1 do
		local fixture = makePart(origin, model, "LightFixture",
			Vector3.new(4, 0.5, 4),
			Vector3.new(i * 18, WALL_HEIGHT - 1, 0),
			Color3.fromRGB(20, 20, 20), Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Color = LIGHT_COLOR
		light.Brightness = 2
		light.Range = 28
		light.Parent = fixture
	end

	-- Pedestals along the back wall
	local pedestals = {}
	local spacing = 10
	local startX = -((PEDESTAL_COUNT - 1) * spacing) / 2
	for i = 1, PEDESTAL_COUNT do
		local pedestal = makePart(origin, model, "Pedestal",
			Vector3.new(3, 4, 3),
			Vector3.new(startX + (i - 1) * spacing, 2, -halfZ + 6),
			PEDESTAL_COLOR, Enum.Material.Marble)
		pedestal:SetAttribute("PedestalIndex", i)
		table.insert(pedestals, pedestal)
	end

	-- Spawn location near the front, facing the pedestals
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MuseumSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = origin * CFrame.new(0, 0.5, halfZ - 8)
	spawn.Color = Color3.fromRGB(70, 120, 90)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.Duration = 0
	spawn.Parent = model

	return {
		Model = model,
		Pedestals = pedestals,
		Spawn = spawn,
	}
end

-- Exposed so other systems (e.g. ChaosEffects) can place things inside the room.
MuseumBuilder.ROOM_X = ROOM_X
MuseumBuilder.ROOM_Z = ROOM_Z
MuseumBuilder.WALL_HEIGHT = WALL_HEIGHT

return MuseumBuilder
