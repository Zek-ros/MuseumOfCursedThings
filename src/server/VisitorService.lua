-- VisitorService.lua (ModuleScript)
-- Spawns wandering NPC visitors inside each player's museum. The number of
-- visitors is a pure function of the displayed collection's "appeal"
-- (MuseumStats.CalculateVisitorCount), so the crowd you see always matches the
-- visitor income you're earning. Rarer artifacts = bigger crowds.
--
-- Visitors wander between random points and panic (scatter) when a
-- ScareVisitors chaos event fires.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local DataService   = require(script.Parent.DataService)
local PedestalService = require(script.Parent.PedestalService)
local MuseumBuilder = require(script.Parent.MuseumBuilder)
local MuseumSignals = require(script.Parent.MuseumSignals)
local MuseumStats   = require(game:GetService("ReplicatedStorage").Shared.MuseumStats)

local VisitorService = {}

-- [player] = { Visitors = { { Part = Part, State = "wander"|"panic" } ... } }
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
	return museum.Origin * CFrame.new(x, 2, z)
end

local function makeVisitor(museum)
	local part = Instance.new("Part")
	part.Name = "Visitor"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(2, 4, 1)
	part.Color = SHIRT_COLORS[math.random(#SHIRT_COLORS)]
	part.Material = Enum.Material.SmoothPlastic
	part.CFrame = randomFloorCFrame(museum)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 40, 0, 24)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	local face = Instance.new("TextLabel")
	face.Size = UDim2.fromScale(1, 1)
	face.BackgroundTransparency = 1
	face.Text = ":)"
	face.TextColor3 = Color3.fromRGB(40, 40, 40)
	face.Font = Enum.Font.GothamBold
	face.TextScaled = true
	face.Parent = billboard
	billboard.Parent = part

	part.Parent = museum.Model
	return part
end

-- Per-visitor wander loop. Reads entry.State so panic can interrupt it.
local function runWander(entry, player: Player)
	task.spawn(function()
		while entry.Part.Parent do
			if entry.State == "panic" then
				task.wait(0.3)
			else
				local museum = PedestalService.GetMuseum(player)
				if not museum then break end

				local target = randomFloorCFrame(museum)
				local fromPos = entry.Part.Position
				local dir = target.Position - fromPos
				if dir.Magnitude < 0.1 then
					dir = Vector3.new(0, 0, -1)
				end
				local goalCFrame = CFrame.lookAt(target.Position, target.Position + dir)

				local seconds = math.clamp(dir.Magnitude / 8, 0.5, 4)
				local tween = TweenService:Create(entry.Part, TweenInfo.new(seconds, Enum.EasingStyle.Linear), {
					CFrame = goalCFrame,
				})
				tween:Play()
				tween.Completed:Wait()
				task.wait(math.random(10, 30) / 10) -- pause 1-3s
			end
		end
	end)
end

-- =============================================
--  SYNC: match the crowd size to the museum's appeal
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
			local entry = { Part = makeVisitor(museum), State = "wander" }
			table.insert(crowd.Visitors, entry)
			runWander(entry, player)
		end
	elseif current > target then
		for _ = current, target + 1, -1 do
			local entry = table.remove(crowd.Visitors)
			if entry and entry.Part then
				entry.Part:Destroy()
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
		if entry.Part.Parent then
			local fleeCF = museum.Origin * CFrame.new(
				(math.random() * 2 - 1) * 30, 2, (MuseumBuilder.ROOM_Z / 2) - 3)
			TweenService:Create(entry.Part, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {
				CFrame = fleeCF,
			}):Play()
		end
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
			if entry.Part then
				entry.Part:Destroy()
			end
		end
	end
	crowds[player] = nil
end

-- =============================================
--  LIFECYCLE
-- =============================================
-- Re-sync the crowd whenever the displayed collection changes.
MuseumSignals.MuseumChanged.Event:Connect(VisitorService.Sync)
Players.PlayerRemoving:Connect(cleanup)

return VisitorService
