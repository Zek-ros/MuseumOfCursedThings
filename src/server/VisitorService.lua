-- VisitorService.lua (ModuleScript)
-- Spawns wandering NPC visitors inside each player's museum. Visitor count is a
-- pure function of the displayed collection's appeal (MuseumStats), so the crowd
-- always matches the visitor income. Visitors are body+head placeholder figures
-- (ModelFactory) that can be swapped for real character models by asset id.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService     = require(script.Parent.DataService)
local PedestalService = require(script.Parent.PedestalService)
local MuseumBuilder   = require(script.Parent.MuseumBuilder)
local MuseumSignals   = require(script.Parent.MuseumSignals)
local ModelFactory    = require(script.Parent.ModelFactory)
local MuseumStats     = require(ReplicatedStorage.Shared.MuseumStats)
local ArtifactData    = require(ReplicatedStorage.Shared.ArtifactData)
local Constants       = require(ReplicatedStorage.Shared.Constants)

-- Artifacts at or above this DangerLevel (1–8) make visitors recoil.
local DANGER_REACT = 5

local VisitorService = {}

-- Set this to a Roblox model asset id to use a real visitor model instead of
-- the placeholder figure. nil = procedural placeholder.
local VISITOR_MODEL_ID = 4446576906

-- [player] = { Visitors = { { Model = Model, State = "wander"|"panic", FleeTarget = CFrame? } } }
local crowds = {}

local SHIRT_COLORS = {
	Color3.fromRGB(210, 120, 120),
	Color3.fromRGB(120, 160, 210),
	Color3.fromRGB(140, 200, 140),
	Color3.fromRGB(220, 200, 120),
	Color3.fromRGB(190, 150, 210),
	Color3.fromRGB(200, 170, 140),
}

local function randomFloorCFrame(museum): CFrame
	local hx = (MuseumBuilder.ROOM_X / 2) - 6
	local hz = (MuseumBuilder.ROOM_Z / 2) - 6
	local x = (math.random() * 2 - 1) * hx
	local z = (math.random() * 2 - 1) * hz
	return museum.Origin * CFrame.new(x, 1.6, z)
end

local function makeVisitor(museum)
	local visitor = ModelFactory.Resolve(VISITOR_MODEL_ID, function()
		return ModelFactory.BuildFigure({
			Name = "Visitor",
			BodyColor = SHIRT_COLORS[math.random(#SHIRT_COLORS)],
			HeadColor = Color3.fromRGB(225, 205, 180),
			FaceText = ":)",
		})
	end)
	ModelFactory.Place(visitor, randomFloorCFrame(museum))
	visitor.Parent = museum.Model
	return visitor
end

-- Keep a point inside the room's walkable area.
local function clampToRoom(museum, pos: Vector3): Vector3
	local o = museum.Origin.Position
	local hx = (MuseumBuilder.ROOM_X / 2) - 4
	local hz = (MuseumBuilder.ROOM_Z / 2) - 4
	return Vector3.new(
		math.clamp(pos.X, o.X - hx, o.X + hx),
		pos.Y,
		math.clamp(pos.Z, o.Z - hz, o.Z + hz))
end

-- The currently-displayed exhibits: { Pos = pedestal pos, Def = artifact def }.
local function getExhibits(player: Player, museum)
	local data = DataService.GetData(player)
	if not data then return {} end
	local list = {}
	for pedIdx, artifactIndex in pairs(museum.Assignments) do
		local pedestal = museum.Pedestals[pedIdx]
		local art = data.Artifacts[artifactIndex]
		if pedestal and art then
			local def = ArtifactData.Artifacts[art.ArtifactId]
			if def then
				table.insert(list, { Pos = pedestal.Position, Def = def })
			end
		end
	end
	return list
end

-- Pick where a visitor goes next: usually a viewing spot around an exhibit
-- (weighted by rarity so rare pieces draw crowds), sometimes a random stroll.
local function pickDestination(player: Player, museum)
	local floorY = museum.Origin.Position.Y + 1.6
	local exhibits = getExhibits(player, museum)
	if #exhibits > 0 and math.random() < 0.75 then
		local totalW = 0
		for _, e in ipairs(exhibits) do
			e.W = Constants.VISITOR_APPEAL_WEIGHT[e.Def.Rarity] or 1
			totalW += e.W
		end
		local roll = math.random() * totalW
		local chosen = exhibits[#exhibits]
		for _, e in ipairs(exhibits) do
			roll -= e.W
			if roll <= 0 then
				chosen = e
				break
			end
		end
		-- Stand somewhere on the ring around the pedestal (just outside the ropes).
		local angle = math.random() * math.pi * 2
		local radius = 4.0 + math.random() * 1.6
		local pos = clampToRoom(museum, Vector3.new(
			chosen.Pos.X + math.cos(angle) * radius, floorY,
			chosen.Pos.Z + math.sin(angle) * radius))
		return { Pos = pos, FacePos = chosen.Pos, Danger = (chosen.Def.DangerLevel or 0) >= DANGER_REACT }
	end
	return { Pos = randomFloorCFrame(museum).Position }
end

-- Turn the visitor to face a point (horizontal only).
local function faceTowards(entry, facePos: Vector3)
	local model = entry.Model
	if not (model and model.Parent) then return end
	local p = model:GetPivot().Position
	local look = Vector3.new(facePos.X, p.Y, facePos.Z)
	if (look - p).Magnitude > 0.1 then
		model:PivotTo(CFrame.lookAt(p, look))
	end
end

-- Brief startled "!" above the visitor's head.
local function reactScared(entry)
	local model = entry.Model
	if not (model and model.Parent) then return end
	local head = model:FindFirstChild("Head") or ModelFactory.AnchorPart(model)
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 28, 0, 28)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 50
	bb.Adornee = head
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "!"
	lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
	lbl.TextStrokeTransparency = 0.4
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = bb
	bb.Parent = model
	task.delay(1.2, function() bb:Destroy() end)
end

-- Walk the visitor to a point, facing the travel direction. Returns false if it
-- was interrupted (panic) or the model went away, true if it arrived.
local function walkTo(entry, targetPos: Vector3, speed: number): boolean
	local model = entry.Model
	if not (model and model.Parent) then return false end
	local start = model:GetPivot()
	local flat = Vector3.new(targetPos.X - start.Position.X, 0, targetPos.Z - start.Position.Z)
	local dist = flat.Magnitude
	if dist < 0.4 then return true end
	local dir = flat.Unit
	local goal = CFrame.lookAt(targetPos, targetPos + dir)
	local startedPanicked = entry.State == "panic"
	local dur = math.clamp(dist / speed, 0.2, 6)
	local t = 0
	while t < dur do
		if not (model and model.Parent) then return false end
		local dt = task.wait()
		t += dt
		model:PivotTo(start:Lerp(goal, math.min(t / dur, 1)))
		if entry.State == "panic" and not startedPanicked then return false end
	end
	return true
end

-- Per-visitor behavior loop. Strolls to exhibits to admire them (or flees on
-- panic). Reads entry.State so panic interrupts whatever they're doing.
local function runWander(entry, player: Player)
	task.spawn(function()
		while entry.Model and entry.Model.Parent do
			local museum = PedestalService.GetMuseum(player)
			if not museum then break end

			if entry.State == "panic" then
				local target = entry.FleeTarget or randomFloorCFrame(museum)
				walkTo(entry, target.Position, 26)
				task.wait(0.2)
			else
				local dest = pickDestination(player, museum)
				local arrived = walkTo(entry, dest.Pos, 8)
				if arrived and entry.State ~= "panic" then
					if dest.FacePos then
						faceTowards(entry, dest.FacePos)
						if dest.Danger then
							reactScared(entry)
							task.wait(math.random(8, 14) / 10) -- recoil: a short, uneasy pause
						else
							task.wait(math.random(25, 55) / 10) -- admire a while
						end
					else
						task.wait(math.random(10, 22) / 10)
					end
				end
			end
		end
	end)
end

-- =============================================
--  SYNC: match crowd size to museum appeal
-- =============================================
function VisitorService.Sync(player: Player)
	local museum = PedestalService.GetMuseum(player)
	if not museum then return end
	local data = DataService.GetData(player)
	if not data then return end

	local target = MuseumStats.CalculateVisitorCount(data)
	local crowd = crowds[player]
	if not crowd then
		crowd = { Visitors = {} }
		crowds[player] = crowd
	end

	local current = #crowd.Visitors
	if current < target then
		for _ = current + 1, target do
			local entry = { Model = makeVisitor(museum), State = "wander" }
			table.insert(crowd.Visitors, entry)
			runWander(entry, player)
		end
	elseif current > target then
		for _ = current, target + 1, -1 do
			local entry = table.remove(crowd.Visitors)
			if entry and entry.Model then
				entry.Model:Destroy()
			end
		end
	end
end

-- =============================================
--  PANIC: scatter the crowd toward the exit for a few seconds
-- =============================================
function VisitorService.Panic(player: Player)
	local crowd = crowds[player]
	local museum = PedestalService.GetMuseum(player)
	if not crowd or not museum then return end

	for _, entry in ipairs(crowd.Visitors) do
		entry.State = "panic"
		entry.FleeTarget = museum.Origin * CFrame.new(
			(math.random() * 2 - 1) * 30, 1.6, (MuseumBuilder.ROOM_Z / 2) - 3)
	end

	task.delay(4, function()
		local c = crowds[player]
		if not c then return end
		for _, entry in ipairs(c.Visitors) do
			entry.State = "wander"
		end
	end)
end

local function cleanup(player: Player)
	local crowd = crowds[player]
	if crowd then
		for _, entry in ipairs(crowd.Visitors) do
			if entry.Model then
				entry.Model:Destroy()
			end
		end
	end
	crowds[player] = nil
end

-- =============================================
--  LIFECYCLE
-- =============================================
MuseumSignals.MuseumChanged.Event:Connect(VisitorService.Sync)
Players.PlayerRemoving:Connect(cleanup)

-- Initial crowd on join. Sync otherwise only runs on MuseumChanged (display
-- changes), so without this a player's visitors wouldn't appear until they
-- touched a pedestal. Poll until the museum is built (independent of load order).
local function spawnInitialCrowd(player: Player)
	for _ = 1, 150 do
		if PedestalService.GetMuseum(player) and DataService.GetData(player) then
			VisitorService.Sync(player)
			return
		end
		task.wait(0.1)
	end
end
Players.PlayerAdded:Connect(function(player)
	task.spawn(spawnInitialCrowd, player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(spawnInitialCrowd, player)
end

return VisitorService
