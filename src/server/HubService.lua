-- HubService.lua (ModuleScript)
-- Owns the shared hub: players spawn here, and it runs the multiplayer
-- expedition QUEUE. Players join a queue for a map; after a countdown (or when
-- someone hits Launch Now) everyone queued is sent to that map together.
--
-- In-server only for now — once the game is published, each live server has its
-- own hub + queue. (Cross-server matchmaking would need TeleportService.)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExpeditionService = require(script.Parent.ExpeditionService)
local PedestalService   = require(script.Parent.PedestalService)
local HubBuilder        = require(script.Parent.HubBuilder)
local ExpeditionMaps    = require(ReplicatedStorage.Shared.ExpeditionMaps)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local QueueStateEvent = RemoteEvents:WaitForChild("QueueState")
local OpenQueueEvent  = RemoteEvents:WaitForChild("OpenQueue")

local HubService = {}

local HUB_ORIGIN = CFrame.new(0, 0, 600)
local QUEUE_COUNTDOWN = 15

-- Valid map ids + display names
local mapNames = {}
for _, def in ipairs(ExpeditionMaps) do
	mapNames[def.Id] = def.Name
end

local hub          -- built hub info
-- [mapId] = { Members = { [player]=true }, EndsAt = clock }
local queues = {}

-- =============================================
--  TELEPORT / SPAWN
-- =============================================
local function teleportToHub(player: Player)
	task.spawn(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
		if root then
			pcall(function()
				root.CFrame = hub.Spawn.CFrame + Vector3.new(0, 4, 0)
			end)
		end
	end)
end

function HubService.GoToHub(player: Player)
	teleportToHub(player)
	return true
end

-- =============================================
--  QUEUE
-- =============================================
local function countMembers(q): number
	local n = 0
	for _ in pairs(q.Members) do n += 1 end
	return n
end

local function findPlayerQueue(player: Player): string?
	for mapId, q in pairs(queues) do
		if q.Members[player] then return mapId end
	end
	return nil
end

local function broadcast(mapId: string, secondsLeft: number)
	local q = queues[mapId]
	if not q then return end
	local count = countMembers(q)
	for member in pairs(q.Members) do
		QueueStateEvent:FireClient(member, {
			InQueue = true,
			MapId = mapId,
			MapName = mapNames[mapId],
			Count = count,
			SecondsLeft = secondsLeft,
		})
	end
end

local function launch(mapId: string)
	local q = queues[mapId]
	if not q then return end
	queues[mapId] = nil
	for player in pairs(q.Members) do
		ExpeditionService.Start(player, mapId)
	end
end

local function runCountdown(mapId: string)
	task.spawn(function()
		while true do
			local q = queues[mapId]
			if not q then return end
			if not next(q.Members) then
				queues[mapId] = nil
				return
			end
			local secondsLeft = math.max(0, math.ceil(q.EndsAt - os.clock()))
			broadcast(mapId, secondsLeft)
			if secondsLeft <= 0 then
				launch(mapId)
				return
			end
			task.wait(1)
		end
	end)
end

function HubService.JoinQueue(player: Player, mapId: string)
	if not mapNames[mapId] then return false, "Unknown expedition" end

	-- Leave any other queue first
	local existing = findPlayerQueue(player)
	if existing and existing ~= mapId and queues[existing] then
		queues[existing].Members[player] = nil
	end

	local q = queues[mapId]
	local isNew = (q == nil)
	if isNew then
		q = { Members = {}, EndsAt = os.clock() + QUEUE_COUNTDOWN }
		queues[mapId] = q
	end
	-- Add the player BEFORE starting the countdown loop. task.spawn runs the
	-- loop synchronously up to its first wait; if Members were still empty it
	-- would immediately cancel the queue.
	q.Members[player] = true
	if isNew then
		runCountdown(mapId)
	end
	broadcast(mapId, math.max(0, math.ceil(q.EndsAt - os.clock())))
	return true, "Queued"
end

function HubService.LeaveQueue(player: Player)
	local mapId = findPlayerQueue(player)
	if not mapId then return end
	queues[mapId].Members[player] = nil
	QueueStateEvent:FireClient(player, { InQueue = false })
	if next(queues[mapId].Members) then
		broadcast(mapId, math.max(0, math.ceil(queues[mapId].EndsAt - os.clock())))
	else
		queues[mapId] = nil
	end
end

function HubService.LaunchNow(player: Player)
	local mapId = findPlayerQueue(player)
	if mapId then
		launch(mapId)
	end
end

-- =============================================
--  INIT
-- =============================================
local function setupPlayer(player: Player)
	player.RespawnLocation = hub.Spawn
	teleportToHub(player)
end

local function init()
	hub = HubBuilder.Build(HUB_ORIGIN)
	hub.Model.Parent = workspace

	-- Hub pad prompts
	local queuePrompt = Instance.new("ProximityPrompt")
	queuePrompt.ActionText = "Queue for Expedition"
	queuePrompt.ObjectText = "Expedition Board"
	queuePrompt.HoldDuration = 0
	queuePrompt.MaxActivationDistance = 12
	queuePrompt.RequiresLineOfSight = false
	queuePrompt.Parent = hub.QueuePad
	queuePrompt.Triggered:Connect(function(player)
		OpenQueueEvent:FireClient(player)
	end)

	local museumPrompt = Instance.new("ProximityPrompt")
	museumPrompt.ActionText = "Go to My Museum"
	museumPrompt.ObjectText = "Museum Portal"
	museumPrompt.HoldDuration = 0
	museumPrompt.MaxActivationDistance = 12
	museumPrompt.RequiresLineOfSight = false
	museumPrompt.Parent = hub.MuseumPad
	museumPrompt.Triggered:Connect(function(player)
		PedestalService.ReturnHome(player)
	end)

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(setupPlayer, player)
	end
end

Players.PlayerRemoving:Connect(function(player)
	local mapId = findPlayerQueue(player)
	if mapId and queues[mapId] then
		queues[mapId].Members[player] = nil
	end
end)

-- =============================================
--  REMOTES
-- =============================================
RemoteFunctions:WaitForChild("GoToHub").OnServerInvoke = function(player)
	return HubService.GoToHub(player)
end
RemoteFunctions:WaitForChild("JoinExpeditionQueue").OnServerInvoke = function(player, mapId)
	return HubService.JoinQueue(player, mapId)
end
RemoteEvents:WaitForChild("LeaveExpeditionQueue").OnServerEvent:Connect(function(player)
	HubService.LeaveQueue(player)
end)
RemoteEvents:WaitForChild("LaunchExpeditionQueue").OnServerEvent:Connect(function(player)
	HubService.LaunchNow(player)
end)

init()

return HubService
