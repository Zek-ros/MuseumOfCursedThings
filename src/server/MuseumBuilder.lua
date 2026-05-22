-- MuseumBuilder.lua (ModuleScript)
-- Procedurally builds a stylized museum room with display pedestals.
-- Geometry is generated in code so it lives in the Rojo-synced project
-- (no hand-placed parts to keep in sync). Swap these for real models later.
--
-- Pedestals are laid out in rows and created one at a time (MakePedestal) so
-- PedestalService can ADD pedestals when the player levels their museum up.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local MuseumBuilder = {}

-- Room dimensions (studs) — sized to fit MAX_PEDESTALS in rows.
local ROOM_X = 84
local ROOM_Z = 56
local WALL_HEIGHT = 18
local WALL_THICK = 1

-- Pedestal layout
local PEDESTALS_PER_ROW = 6
local PED_SPACING_X = 12
local PED_ROW_SPACING = 12
local PED_FIRST_ROW_Z = -(ROOM_Z / 2) + 10

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

-- Local position (relative to origin) of the Nth pedestal slot.
local function pedestalLocalPos(index: number): Vector3
	local i0 = index - 1
	local row = math.floor(i0 / PEDESTALS_PER_ROW)
	local col = i0 % PEDESTALS_PER_ROW
	local startX = -((PEDESTALS_PER_ROW - 1) * PED_SPACING_X) / 2
	local x = startX + col * PED_SPACING_X
	local z = PED_FIRST_ROW_Z + row * PED_ROW_SPACING
	return Vector3.new(x, 2, z)
end

--- Create a single pedestal at slot `index`, parented to `parent`. Returns the part.
function MuseumBuilder.MakePedestal(origin: CFrame, index: number, parent: Instance)
	local pedestal = makePart(origin, parent, "Pedestal",
		Vector3.new(3, 4, 3),
		pedestalLocalPos(index),
		PEDESTAL_COLOR, Enum.Material.Marble)
	pedestal:SetAttribute("PedestalIndex", index)
	return pedestal
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

	-- Roof
	makePart(origin, model, "Ceiling",
		Vector3.new(ROOM_X, WALL_THICK, ROOM_Z),
		Vector3.new(0, WALL_HEIGHT + WALL_THICK / 2, 0), WALL_COLOR, Enum.Material.Concrete)

	-- Ceiling lights: warm point lights spread across the (bigger) room
	for _, lx in ipairs({ -28, 0, 28 }) do
		local fixture = makePart(origin, model, "LightFixture",
			Vector3.new(4, 0.5, 4),
			Vector3.new(lx, WALL_HEIGHT - 1, 0),
			Color3.fromRGB(20, 20, 20), Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Color = LIGHT_COLOR
		light.Brightness = 2
		light.Range = 30
		light.Parent = fixture
	end

	-- Initial pedestals (level 1 count); more are added on level-up.
	local pedestals = {}
	for i = 1, Constants.PEDESTALS_BASE do
		table.insert(pedestals, MuseumBuilder.MakePedestal(origin, i, model))
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
	-- Disabled as an auto-spawn: players spawn in the hub and teleport here.
	-- We still use this part's CFrame as the museum teleport target.
	spawn.Enabled = false
	spawn.Duration = 0
	spawn.Parent = model

	-- Hub portal on the left wall (walk into it to travel to the hub).
	-- Placed away from the spawn-arrival point so you don't bounce straight back.
	local portalColor = Color3.fromRGB(150, 90, 230)
	local px = -halfX + 1.5
	makePart(origin, model, "PortalFrame", Vector3.new(1, 11, 1), Vector3.new(px, 5.5, -3.5), portalColor, Enum.Material.Neon)
	makePart(origin, model, "PortalFrame", Vector3.new(1, 11, 1), Vector3.new(px, 5.5, 3.5), portalColor, Enum.Material.Neon)
	makePart(origin, model, "PortalFrame", Vector3.new(1.2, 1, 8), Vector3.new(px, 11, 0), portalColor, Enum.Material.Neon)

	local portal = makePart(origin, model, "HubPortal", Vector3.new(0.6, 10, 6.5), Vector3.new(px + 0.4, 5, 0), portalColor, Enum.Material.Neon)
	portal.CanCollide = false
	portal.Transparency = 0.35
	local portalLight = Instance.new("PointLight")
	portalLight.Color = portalColor
	portalLight.Range = 16
	portalLight.Brightness = 3
	portalLight.Parent = portal

	local portalBillboard = Instance.new("BillboardGui")
	portalBillboard.Size = UDim2.new(0, 140, 0, 40)
	portalBillboard.StudsOffset = Vector3.new(0, 6.5, 0)
	-- AlwaysOnTop so the portal frame doesn't hide the label; MaxDistance caps range.
	portalBillboard.AlwaysOnTop = true
	portalBillboard.MaxDistance = 60
	local portalLabel = Instance.new("TextLabel")
	portalLabel.Size = UDim2.fromScale(1, 1)
	portalLabel.BackgroundTransparency = 1
	portalLabel.Text = "TO HUB ▶"
	portalLabel.TextColor3 = Color3.fromRGB(230, 200, 255)
	portalLabel.Font = Enum.Font.GothamBold
	portalLabel.TextScaled = true
	portalLabel.Parent = portalBillboard
	portalBillboard.Parent = portal

	return {
		Model = model,
		Pedestals = pedestals,
		Spawn = spawn,
		Portal = portal,
	}
end

-- Exposed so other systems (e.g. ChaosEffects) can place things inside the room.
MuseumBuilder.ROOM_X = ROOM_X
MuseumBuilder.ROOM_Z = ROOM_Z
MuseumBuilder.WALL_HEIGHT = WALL_HEIGHT

return MuseumBuilder
