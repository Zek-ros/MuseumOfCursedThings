-- GoalService.lua (ModuleScript)
-- A linear "next goal" chain that gives players a clear thing to chase, especially
-- in their first session (the main fix for "they play a few minutes and leave").
-- Each goal completes once, in order, pays a coin reward, and then the next one
-- appears. Progress is measured off monotonic stats so the bar never goes backward.
--
-- The server is the single writer: a slow loop re-evaluates every player, awards
-- any newly-satisfied goals, and only pushes the HUD when its display changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Get a remote, but NEVER hang the server boot waiting on one. If Rojo hasn't
-- synced a newly-added remote into this session yet, we create it ourselves
-- (server-created instances replicate to clients, so the HUD still works).
local function ensureRemote(parent: Instance, name: string, className: string): Instance
	local existing = parent:FindFirstChild(name) or parent:WaitForChild(name, 5)
	if existing then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local GoalUpdatedEvent = ensureRemote(RemoteEvents, "GoalUpdated", "RemoteEvent")
local GetGoalStatusFn = ensureRemote(RemoteFunctions, "GetGoalStatus", "RemoteFunction")
local MuseumChangedEvent = RemoteEvents:WaitForChild("MuseumChanged")

local GoalService = {}

local EVAL_RATE = 3 -- seconds between re-evaluations

-- ----- measurements (each returns the player's current count for a goal) -----
local function collected(data: any): number
	return data.Statistics.ArtifactsCollected or 0
end
local function earned(data: any): number
	return data.Statistics.TotalEarned or 0
end
local function displayedCount(data: any): number
	local n = 0
	for _, a in ipairs(data.Artifacts) do
		if a.IsDisplayed then n += 1 end
	end
	return n
end
local function discoveredCount(data: any): number
	local n = 0
	for _ in pairs(data.Discovered or {}) do n += 1 end
	return n
end

-- The chain. Ordered easiest-first; early ones are reachable in the first minutes.
local GOALS = {
	{ Title = "Collect your first artifact",   Target = 1,     Reward = 200,  Measure = collected },
	{ Title = "Put an artifact on display",     Target = 1,     Reward = 250,  Measure = displayedCount },
	{ Title = "Collect 3 artifacts",            Target = 3,     Reward = 350,  Measure = collected },
	{ Title = "Earn 2,000 coins total",         Target = 2000,  Reward = 500,  Measure = earned },
	{ Title = "Display 5 artifacts",            Target = 5,     Reward = 700,  Measure = displayedCount },
	{ Title = "Discover 10 unique artifacts",   Target = 10,    Reward = 1000, Measure = discoveredCount },
	{ Title = "Earn 10,000 coins total",        Target = 10000, Reward = 1500, Measure = earned },
	{ Title = "Discover 20 unique artifacts",   Target = 20,    Reward = 2500, Measure = discoveredCount },
	{ Title = "Earn 50,000 coins total",        Target = 50000, Reward = 5000, Measure = earned },
}

local lastSig = {} -- [player] = last pushed HUD signature, so we don't spam the client

local function statusFor(data: any)
	local idx = (data.GoalsCompleted or 0) + 1
	local goal = GOALS[idx]
	if not goal then
		return { AllDone = true, Index = #GOALS, Total = #GOALS }
	end
	return {
		AllDone = false,
		Title = goal.Title,
		Current = math.min(goal.Measure(data), goal.Target),
		Target = goal.Target,
		Reward = goal.Reward,
		Index = idx,
		Total = #GOALS,
	}
end

-- Advance + award every goal the player currently satisfies, then push the HUD
-- (only if it actually changed). Called from the loop, which is the only writer.
function GoalService.Evaluate(player: Player)
	local data = DataService.GetData(player)
	if not data then return end
	data.GoalsCompleted = data.GoalsCompleted or 0

	local awarded = false
	while true do
		local idx = data.GoalsCompleted + 1
		local goal = GOALS[idx]
		if not goal then break end
		if goal.Measure(data) >= goal.Target then
			DataService.UpdateCurrency(player, goal.Reward)
			data.GoalsCompleted = idx
			awarded = true
			GoalUpdatedEvent:FireClient(player, {
				Completed = true,
				Title = goal.Title,
				Reward = goal.Reward,
			})
		else
			break
		end
	end

	if awarded then
		-- The reward changed their balance; nudge the top bar to refresh.
		MuseumChangedEvent:FireClient(player)
	end

	local status = statusFor(data)
	local sig = status.AllDone and "done" or (status.Index .. ":" .. status.Current)
	if awarded or sig ~= lastSig[player] then
		lastSig[player] = sig
		GoalUpdatedEvent:FireClient(player, { Status = status })
	end
end

GetGoalStatusFn.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return { AllDone = false, Title = "Loading...", Current = 0, Target = 1, Reward = 0, Index = 1, Total = #GOALS }
	end
	return statusFor(data)
end

Players.PlayerRemoving:Connect(function(player)
	lastSig[player] = nil
end)

-- Single evaluation loop = single writer (no double-award races).
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			GoalService.Evaluate(player)
		end
		task.wait(EVAL_RATE)
	end
end)

return GoalService
