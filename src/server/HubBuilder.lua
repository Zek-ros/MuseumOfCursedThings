-- HubBuilder.lua (ModuleScript)
-- Builds the shared social hub: where players spawn, meet, read the leaderboards,
-- learn the loop, and launch into expeditions / their museum. Procedural.

local HubBuilder = {}

local HUB_X = 70
local HUB_Z = 70
local WALL_HEIGHT = 16
local WALL_THICK = 1

local FLOOR_COLOR = Color3.fromRGB(46, 42, 56)
local WALL_COLOR  = Color3.fromRGB(34, 31, 44)
local TRIM_COLOR  = Color3.fromRGB(150, 132, 96)
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
	billboard.AlwaysOnTop = true
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

-- A glowing floor pad with a floating label + light. Returns the pad part.
local function makePad(origin, model, name, localPos, color, labelText, labelColor)
	local pad = Instance.new("Part")
	pad.Name = name
	pad.Anchored = true
	pad.CanCollide = false
	pad.Size = Vector3.new(9, 1, 9)
	pad.CFrame = origin * CFrame.new(localPos)
	pad.Color = color
	pad.Material = Enum.Material.Neon
	pad.Transparency = 0.3
	labelOn(pad, labelText, labelColor, 5)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Brightness = 3
	light.Parent = pad
	pad.Parent = model
	return pad
end

-- A framed info board flush on the Left or Right wall. Returns the SurfaceGui so
-- the caller can fill it with rows/steps.
local function makeWallBoard(origin, model, side: string, zLocal: number, titleText: string, titleColor: Color3)
	local halfX = HUB_X / 2
	local boardX, frameX, face
	if side == "Left" then
		boardX, frameX, face = -halfX + 0.6, -halfX + 0.45, Enum.NormalId.Right
	else
		boardX, frameX, face = halfX - 0.6, halfX - 0.45, Enum.NormalId.Left
	end
	local y = WALL_HEIGHT * 0.52
	makePart(origin, model, "BoardFrame", Vector3.new(0.3, 13, 15), Vector3.new(frameX, y, zLocal), ACCENT, Enum.Material.Neon)
	local board = makePart(origin, model, "Board", Vector3.new(0.5, 12, 13.5), Vector3.new(boardX, y, zLocal), Color3.fromRGB(18, 16, 24), Enum.Material.SmoothPlastic)

	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(0.92, 0.1)
	title.Position = UDim2.fromScale(0.04, 0.02)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = titleText
	title.TextColor3 = titleColor
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = gui
	local tcap = Instance.new("UITextSizeConstraint")
	tcap.MaxTextSize = 52
	tcap.Parent = title

	return gui
end

-- Add 8 (initially empty) ranking rows to a board gui; returns the row labels.
local function addRows(gui)
	local rows = {}
	for i = 1, 8 do
		local row = Instance.new("TextLabel")
		row.Name = "Row" .. i
		row.Size = UDim2.fromScale(0.92, 0.095)
		row.Position = UDim2.fromScale(0.04, 0.14 + (i - 1) * 0.105)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.GothamMedium
		row.Text = ""
		row.TextColor3 = Color3.fromRGB(228, 228, 242)
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = gui
		local rcap = Instance.new("UITextSizeConstraint")
		rcap.MaxTextSize = 36
		rcap.Parent = row
		rows[i] = row
	end
	return rows
end

--- Build the hub. Returns spawn, pads, the leaderboard rows, and the centerpiece.
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
	makePart(origin, model, "Ceiling", Vector3.new(HUB_X, WALL_THICK, HUB_Z),
		Vector3.new(0, WALL_HEIGHT + WALL_THICK / 2, 0), WALL_COLOR, Enum.Material.Concrete)

	-- Baseboard + cornice trim around the walls.
	local inset = WALL_THICK / 2 + 0.5
	for _, band in ipairs({ { y = 1, h = 1.4 }, { y = WALL_HEIGHT - 1, h = 1.0 } }) do
		makePart(origin, model, "Trim", Vector3.new(HUB_X, band.h, 0.6), Vector3.new(0, band.y, -halfZ + inset), TRIM_COLOR, Enum.Material.Marble)
		makePart(origin, model, "Trim", Vector3.new(HUB_X, band.h, 0.6), Vector3.new(0, band.y, halfZ - inset), TRIM_COLOR, Enum.Material.Marble)
		makePart(origin, model, "Trim", Vector3.new(0.6, band.h, HUB_Z), Vector3.new(-halfX + inset, band.y, 0), TRIM_COLOR, Enum.Material.Marble)
		makePart(origin, model, "Trim", Vector3.new(0.6, band.h, HUB_Z), Vector3.new(halfX - inset, band.y, 0), TRIM_COLOR, Enum.Material.Marble)
	end

	-- Central floor medallion under the centerpiece.
	makePart(origin, model, "Medallion", Vector3.new(15, 0.12, 15), Vector3.new(0, 0.07, 0), Color3.fromRGB(28, 22, 40), Enum.Material.Slate)

	-- Layered lighting: warm fill spread across the room + a cool accent center.
	for _, lz in ipairs({ -16, 16 }) do
		for _, lx in ipairs({ -20, 20 }) do
			local fixture = makePart(origin, model, "LightFixture", Vector3.new(3, 0.4, 3),
				Vector3.new(lx, WALL_HEIGHT - 1, lz), Color3.fromRGB(20, 20, 20), Enum.Material.Metal)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(220, 200, 255)
			light.Brightness = 1.4
			light.Range = 32
			light.Parent = fixture
		end
	end

	-- Central title plaque on the back wall (framed, wall-mounted).
	makePart(origin, model, "SignFrame", Vector3.new(32, 10, 0.3),
		Vector3.new(0, WALL_HEIGHT * 0.58, -halfZ + 0.5), ACCENT, Enum.Material.Neon)
	local sign = makePart(origin, model, "Sign", Vector3.new(30, 8, 0.5),
		Vector3.new(0, WALL_HEIGHT * 0.58, -halfZ + 0.65), Color3.fromRGB(20, 17, 26), Enum.Material.SmoothPlastic)
	do
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.LightInfluence = 0
		gui.Parent = sign
		local title = Instance.new("TextLabel")
		title.Size = UDim2.fromScale(0.9, 0.5)
		title.Position = UDim2.fromScale(0.05, 0.08)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.Text = "MUSEUM OF CURSED THINGS"
		title.TextColor3 = Color3.fromRGB(235, 220, 255)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Center
		title.Parent = gui
		local tcap = Instance.new("UITextSizeConstraint")
		tcap.MaxTextSize = 92
		tcap.Parent = title
		local tstroke = Instance.new("UIStroke")
		tstroke.Color = Color3.fromRGB(50, 18, 80)
		tstroke.Thickness = 2
		tstroke.Transparency = 0.3
		tstroke.Parent = title
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.fromScale(0.9, 0.24)
		sub.Position = UDim2.fromScale(0.05, 0.64)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.GothamMedium
		sub.Text = "THE CURATORS' HUB"
		sub.TextColor3 = Color3.fromRGB(182, 152, 224)
		sub.TextScaled = true
		sub.TextXAlignment = Enum.TextXAlignment.Center
		sub.Parent = gui
		local scap = Instance.new("UITextSizeConstraint")
		scap.MaxTextSize = 48
		scap.Parent = sub
	end

	-- Hall of Fame: three boards on the left wall (filled by HubService).
	local boards = {
		Earned     = addRows(makeWallBoard(origin, model, "Left", -16, "TOP CURATORS", Color3.fromRGB(255, 220, 120))),
		Collection = addRows(makeWallBoard(origin, model, "Left", 0, "TOP COLLECTORS", Color3.fromRGB(150, 230, 170))),
		Prestige   = addRows(makeWallBoard(origin, model, "Left", 16, "TOP PRESTIGE", Color3.fromRGB(200, 160, 255))),
	}

	-- How-to-Play board on the right wall (teaches the core loop to new arrivals).
	local howGui = makeWallBoard(origin, model, "Right", 0, "HOW TO PLAY", Color3.fromRGB(245, 245, 255))
	local steps = {
		"1.  Step on EXPEDITION QUEUE",
		"2.  Find an artifact in the dark",
		"3.  Carry it to the EXTRACTION pad",
		"4.  Display it on a pedestal",
		"5.  Earn coins while you're away!",
	}
	for i, text in ipairs(steps) do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(0.92, 0.12)
		lbl.Position = UDim2.fromScale(0.05, 0.16 + (i - 1) * 0.16)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = text
		lbl.TextColor3 = Color3.fromRGB(225, 225, 240)
		lbl.TextScaled = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = howGui
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 40
		cap.Parent = lbl
	end

	-- Cursed centerpiece: a glowing orb on a plinth with orbiting shards.
	makePart(origin, model, "Plinth", Vector3.new(5, 3, 5), Vector3.new(0, 1.5, 0), Color3.fromRGB(40, 36, 52), Enum.Material.Marble)
	local crystal = Instance.new("Model")
	crystal.Name = "CenterCrystal"
	local orbCF = origin * CFrame.new(0, 8, 0)
	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Anchored = true
	orb.CanCollide = false
	orb.Size = Vector3.new(4.5, 4.5, 4.5)
	orb.Material = Enum.Material.Glass
	orb.Color = Color3.fromRGB(60, 24, 90)
	orb.Transparency = 0.35
	orb.CFrame = orbCF
	orb.Parent = crystal
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Anchored = true
	core.CanCollide = false
	core.Size = Vector3.new(2, 2, 2)
	core.Material = Enum.Material.Neon
	core.Color = ACCENT
	core.CFrame = orbCF
	core.Parent = crystal
	local coreLight = Instance.new("PointLight")
	coreLight.Color = ACCENT
	coreLight.Range = 26
	coreLight.Brightness = 5
	coreLight.Parent = core
	for i = 1, 3 do
		local angle = (i / 3) * math.pi * 2
		local shard = Instance.new("Part")
		shard.Name = "Shard"
		shard.Anchored = true
		shard.CanCollide = false
		shard.Size = Vector3.new(0.8, 2.4, 0.8)
		shard.Material = Enum.Material.Neon
		shard.Color = Color3.fromRGB(185, 130, 255)
		shard.CFrame = orbCF * CFrame.new(math.cos(angle) * 4, 0, math.sin(angle) * 4) * CFrame.Angles(0, 0, math.rad(35))
		shard.Parent = crystal
	end
	crystal.PrimaryPart = orb
	crystal.Parent = model

	-- Action pads (a row between the centerpiece and the back wall).
	local queuePad  = makePad(origin, model, "QueuePad",  Vector3.new(-21, 0.5, -9), ACCENT, "EXPEDITION QUEUE", Color3.fromRGB(230, 200, 255))
	local museumPad = makePad(origin, model, "MuseumPad", Vector3.new(-7, 0.5, -9),  Color3.fromRGB(230, 190, 70), "MY MUSEUM", Color3.fromRGB(255, 235, 170))
	local shopPad   = makePad(origin, model, "ShopPad",   Vector3.new(7, 0.5, -9),   Color3.fromRGB(70, 200, 150), "SHOP", Color3.fromRGB(210, 255, 235))
	local dailyPad  = makePad(origin, model, "DailyPad",  Vector3.new(21, 0.5, -9),  Color3.fromRGB(240, 170, 70), "DAILY REWARD", Color3.fromRGB(255, 230, 190))

	-- Spawn near the front, facing the pads.
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
		ShopPad = shopPad,
		DailyPad = dailyPad,
		Centerpiece = crystal,
		Boards = boards,
	}
end

return HubBuilder
