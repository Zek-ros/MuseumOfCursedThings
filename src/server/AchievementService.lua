-- AchievementService.lua (ModuleScript)
-- Checks each player's stats against AchievementData and auto-grants the coin
-- reward (once) when a goal is reached. Drives a checklist of long-term goals.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService     = require(script.Parent.DataService)
local AchievementData = require(ReplicatedStorage.Shared.AchievementData)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local AchievementUnlocked = RemoteEvents:WaitForChild("AchievementUnlocked")
local MuseumChangedEvent  = RemoteEvents:WaitForChild("MuseumChanged")

local AchievementService = {}

local CHECK_RATE = 15

local function getStat(data, stat: string): number
	if stat == "TotalEarned" then
		return data.Statistics.TotalEarned or 0
	elseif stat == "ChaosEventsSurvived" then
		return data.Statistics.ChaosEventsSurvived or 0
	elseif stat == "ArtifactsCollected" then
		return data.Statistics.ArtifactsCollected or 0
	elseif stat == "MuseumLevel" then
		return data.MuseumLevel or 1
	elseif stat == "Prestige" then
		return data.Prestige or 0
	elseif stat == "Discovered" then
		local n = 0
		for _ in pairs(data.Discovered or {}) do n += 1 end
		return n
	end
	return 0
end

-- Grant any newly-completed achievements for a player.
local function checkPlayer(player: Player)
	local data = DataService.GetData(player)
	if not data then return end
	data.Achievements = data.Achievements or {}

	local grantedAny = false
	for _, ach in ipairs(AchievementData) do
		if not data.Achievements[ach.Id] and getStat(data, ach.Stat) >= ach.Goal then
			data.Achievements[ach.Id] = true
			DataService.UpdateCurrency(player, ach.Reward)
			AchievementUnlocked:FireClient(player, { Name = ach.Name, Reward = ach.Reward })
			grantedAny = true
		end
	end

	if grantedAny then
		MuseumChangedEvent:FireClient(player) -- refresh currency display
	end
end

function AchievementService.GetAll(player: Player)
	local data = DataService.GetData(player)
	if not data then return nil end
	data.Achievements = data.Achievements or {}

	local list = {}
	for _, ach in ipairs(AchievementData) do
		table.insert(list, {
			Id = ach.Id,
			Name = ach.Name,
			Description = ach.Description,
			Goal = ach.Goal,
			Reward = ach.Reward,
			Current = getStat(data, ach.Stat),
			Claimed = data.Achievements[ach.Id] == true,
		})
	end
	return list
end

-- =============================================
--  LOOP + REMOTE
-- =============================================
task.spawn(function()
	while true do
		task.wait(CHECK_RATE)
		for _, player in ipairs(Players:GetPlayers()) do
			checkPlayer(player)
		end
	end
end)

-- Quick first check shortly after a player joins
Players.PlayerAdded:Connect(function(player)
	task.delay(6, function()
		checkPlayer(player)
	end)
end)

RemoteFunctions:WaitForChild("GetAchievements").OnServerInvoke = function(player)
	return AchievementService.GetAll(player)
end

return AchievementService
