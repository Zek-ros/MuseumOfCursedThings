-- Audio.client.lua
-- The audio system. Plays looping ambience that follows the player between the
-- museum and expeditions, plus one-shot stings tied to the events the game
-- already fires. Sound asset ids live in shared/SoundData (all 0 for now), so
-- this is silent until ids are filled in — same swap-in pattern as models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local SoundData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundData"))

local RemoteEvents      = ReplicatedStorage:WaitForChild("RemoteEvents")
local IncomeEvent       = RemoteEvents:WaitForChild("IncomeReceived")
local ChaosEventRemote  = RemoteEvents:WaitForChild("ChaosEvent")
local ExpeditionState   = RemoteEvents:WaitForChild("ExpeditionState")

local function idToContent(id: number?): string
	if id and id > 0 then
		return "rbxassetid://" .. id
	end
	return ""
end

-- Fire-and-forget sound that cleans itself up.
local function playOneShot(name: string)
	local cfg = SoundData[name]
	if not cfg or (cfg.Id or 0) <= 0 then return end -- not configured -> silent
	local sound = Instance.new("Sound")
	sound.SoundId = idToContent(cfg.Id)
	sound.Volume = cfg.Volume or 0.5
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(10, function()
		if sound.Parent then sound:Destroy() end
	end)
end

-- A single looping ambience sound we retune as context changes.
local ambient = Instance.new("Sound")
ambient.Name = "Ambient"
ambient.Looped = true
ambient.Parent = SoundService

local function setAmbient(name: string)
	local cfg = SoundData[name]
	if cfg and (cfg.Id or 0) > 0 then
		ambient.SoundId = idToContent(cfg.Id)
		ambient.Volume = cfg.Volume or 0.3
		if not ambient.IsPlaying then
			ambient:Play()
		end
	else
		ambient:Stop()
	end
end

setAmbient("MuseumAmbient")

-- =============================================
--  EVENT HOOKS
-- =============================================
IncomeEvent.OnClientEvent:Connect(function()
	playOneShot("Coin")
end)

ChaosEventRemote.OnClientEvent:Connect(function()
	playOneShot("ChaosSting")
end)

ExpeditionState.OnClientEvent:Connect(function(info)
	local state = info.State
	if state == "Entered" then
		setAmbient("ExpeditionAmbient")
	elseif state == "Extracted" then
		playOneShot("Extract")
		playOneShot("Discover")
		setAmbient("MuseumAmbient")
	elseif state == "Left" then
		setAmbient("MuseumAmbient")
	elseif state == "Dropped" then
		playOneShot("MonsterGrab")
	end
end)
