-- TutorialService.lua (ModuleScript)
-- Tracks whether a player has finished the first-time onboarding and grants a
-- one-time starter coin bonus on completion. The step-by-step progression
-- lives client-side (Onboarding.client.lua); this is just the authoritative
-- state + reward.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local MuseumChangedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MuseumChanged")

local TUTORIAL_BONUS = 250

local TutorialService = {}

RemoteFunctions:WaitForChild("GetTutorialState").OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	return data ~= nil and data.TutorialDone == true
end

RemoteFunctions:WaitForChild("CompleteTutorial").OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data or data.TutorialDone then
		return 0
	end
	data.TutorialDone = true
	DataService.UpdateCurrency(player, TUTORIAL_BONUS)
	-- Nudge the client to refresh its currency display with the new bonus.
	MuseumChangedEvent:FireClient(player)
	return TUTORIAL_BONUS
end

return TutorialService
