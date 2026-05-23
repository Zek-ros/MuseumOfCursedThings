-- MuseumBuilder.lua (ModuleScript)
-- Procedurally builds a stylized museum room with display pedestals.
-- Geometry is generated in code so it lives in the Rojo-synced project
-- (no hand-placed parts to keep in sync). Swap these for real models later.
--
-- Pedestals are laid out in rows and created one at a time (MakePedestal) so
-- PedestalService can ADD pedestals when the player levels their museum up.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local ModelFactory = require(script.Parent.ModelFactory)

local MuseumBuilder = {}

-- Real Store models for the solid props (nil = keep the procedural version).
local PEDESTAL_MODEL_ID = 5057773836
local HUB_PORTAL_MODEL_ID = 18506880748

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

-- Stand a loaded prop model on the floor at a local (x, _, z), optionally yawed
-- so it faces a direction. Returns the model's height (for hover math).
local function sitProp(origin: CFrame, model, localX: number, localZ: number, yaw: number?): number
	local floorPos = (origin * CFrame.new(localX, 0, localZ)).Position
	model:PivotTo(CFrame.new(floorPos) * CFrame.Angles(0, yaw or 0, 0))
	local cf, size = model:GetBoundingBox()
	local delta = Vector3.new(
		floorPos.X - cf.Position.X,
		(floorPos.Y + size.Y / 2) - cf.Position.Y,
		floorPos.Z - cf.Position.Z)
	model:PivotTo(model:GetPivot() + delta)
	return size.Y
end

-- World-space axis-aligned min/max corners of a (possibly rotated) model.
local function worldAABB(model): (Vector3, Vector3)
	local cf, size = model:GetBoundingBox()
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	local minv = Vector3.new(math.huge, math.huge, math.huge)
	local maxv = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local corner = (cf * CFrame.new(sx * hx, sy * hy, sz * hz)).Position
				minv = Vector3.new(math.min(minv.X, corner.X), math.min(minv.Y, corner.Y), math.min(minv.Z, corner.Z))
				maxv = Vector3.new(math.max(maxv.X, corner.X), math.max(maxv.Y, corner.Y), math.max(maxv.Z, corner.Z))
			end
		end
	end
	return minv, maxv
end

-- Stand a prop flush against the LEFT wall (local x = wallLocalX): its nearest
-- face touches the wall, its base sits on the floor, centered along z = localZ.
local function placeAgainstWall(origin: CFrame, model, wallLocalX: number, localZ: number, yaw: number?)
	local wallPos = (origin * CFrame.new(wallLocalX, 0, localZ)).Position
	model:PivotTo(CFrame.new(wallPos) * CFrame.Angles(0, yaw or 0, 0))
	local minv, maxv = worldAABB(model)
	local delta = Vector3.new(
		wallPos.X - minv.X,                 -- push the back face flush to the wall
		wallPos.Y - minv.Y,                 -- base on the floor
		wallPos.Z - (minv.Z + maxv.Z) / 2)  -- centered along the wall
	model:PivotTo(model:GetPivot() + delta)
end

--- Create a single pedestal at slot `index`, parented to `parent`. Returns the
-- part PedestalService treats as the pedestal (its prompt + hover anchor). If a
-- Store model is configured it becomes the visual; otherwise a marble block.
function MuseumBuilder.MakePedestal(origin: CFrame, index: number, parent: Instance)
	local lp = pedestalLocalPos(index)

	local model = ModelFactory.TryLoad(PEDESTAL_MODEL_ID)
	if model then
		local height = sitProp(origin, model, lp.X, lp.Z, 0)
		-- Invisible anchor: holds the prompt + index, and its top (Position +
		-- Size.Y/2) is where PedestalService floats the artifact.
		local anchor = makePart(origin, parent, "Pedestal",
			Vector3.new(3, height, 3), Vector3.new(lp.X, height / 2, lp.Z),
			PEDESTAL_COLOR, Enum.Material.SmoothPlastic)
		anchor.Transparency = 1
		anchor.CanCollide = false
		anchor:SetAttribute("PedestalIndex", index)
		model.Parent = anchor -- removing the anchor (on prestige reset) frees the model too
		return anchor
	end

	local pedestal = makePart(origin, parent, "Pedestal",
		Vector3.new(3, 4, 3),
		lp,
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

	-- Use the Store portal model if it loads; otherwise the original purple frame.
	local portalModel = ModelFactory.TryLoad(HUB_PORTAL_MODEL_ID)
	if portalModel then
		placeAgainstWall(origin, portalModel, -halfX, 0, math.rad(90)) -- flush to the left wall
		portalModel.Parent = model
	else
		makePart(origin, model, "PortalFrame", Vector3.new(1, 11, 1), Vector3.new(px, 5.5, -3.5), portalColor, Enum.Material.Neon)
		makePart(origin, model, "PortalFrame", Vector3.new(1, 11, 1), Vector3.new(px, 5.5, 3.5), portalColor, Enum.Material.Neon)
		makePart(origin, model, "PortalFrame", Vector3.new(1.2, 1, 8), Vector3.new(px, 11, 0), portalColor, Enum.Material.Neon)
	end

	-- Invisible touch trigger (the visual is the model above, or the frame fallback).
	local portal = makePart(origin, model, "HubPortal", Vector3.new(0.6, 10, 6.5), Vector3.new(px + 0.4, 5, 0), portalColor, Enum.Material.Neon)
	portal.CanCollide = false
	portal.Transparency = portalModel and 1 or 0.35
	if not portalModel then
		local portalLight = Instance.new("PointLight")
		portalLight.Color = portalColor
		portalLight.Range = 16
		portalLight.Brightness = 3
		portalLight.Parent = portal
	end

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
