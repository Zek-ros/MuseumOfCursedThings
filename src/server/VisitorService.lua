-- VisitorService.lua (ModuleScript)
-- Spawns wandering NPC visitors inside each player's museum. Visitor count is a
-- pure function of the displayed collection's appeal (MuseumStats), so the crowd
-- always matches the visitor income. Visitors are body+head placeholder figures
-- (ModelFactory) that can be swapped for real character models by asset id.

local Players       = game:GetService("Players")

local DataService     = require(script.Parent.DataService)
local PedestalService = require(script.Parent.PedestalService)
local MuseumBuilder   = require(script.Parent.MuseumBuilder)
local MuseumSignals   = require(script.Parent.MuseumSignals)
local ModelFactory    = require(script.Parent.ModelFactory)
local MuseumStats     = require(game:GetService("ReplicatedStorage").Shared.MuseumStats)

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

-- Per-visitor movement loop. Reads entry.State so panic can interrupt wandering.
local function runWander(entry, player: Player)
	task.spawn(function()
		while entry.Model and entry.Model.Parent do
			local museum = PedestalService.GetMuseum(player)
			if not museum then break end

			local start = entry.Model:GetPivot()
			local target, speed
			local startedPanicked = entry.State == "panic"
			if startedPanicked then
				target = entry.FleeTarget or randomFloorCFrame(museum)
				speed = 26
			else
				target = randomFloorCFrame(museum)
				speed = 8
			end

			local dir = target.Position - start.Position
			if dir.Magnitude < 0.1 then dir = start.LookVector end
			local goal = CFrame.lookAt(target.Position, target.Position + dir)
			local dur = math.clamp(dir.Magnitude / speed, 0.25, 4)

			local t = 0
			while t < dur do
				if not (entry.Model and entry.Model.Parent) then return end
				local dt = task.wait()
				t += dt
				entry.Model:PivotTo(start:Lerp(goal, math.min(t / dur, 1)))
				-- React quickly if panic kicks in mid-stroll
				if entry.State == "panic" and not startedPanicked then break end
			end

			task.wait(if entry.State == "panic" then 0.2 else math.random(10, 30) / 10)
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

return VisitorService
