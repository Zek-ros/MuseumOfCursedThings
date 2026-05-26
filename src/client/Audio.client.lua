-- Audio.client.lua
-- The audio system. Plays looping ambience that follows the player between the
-- museum and expeditions, one-shot stings tied to the events the game fires, and
-- a heartbeat that rises as a monster closes in (synced to the danger vignette).
-- Sound asset ids live in shared/SoundData (all 0 by default), so this is silent
-- until ids are filled in — same swap-in pattern as models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local Players           = game:GetService("Players")

local SoundData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundData"))

local player = Players.LocalPlayer

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
--  MONSTER-PROXIMITY HEARTBEAT (synced to the danger vignette)
-- =============================================
local heartbeat = Instance.new("Sound")
heartbeat.Name = "Heartbeat"
heartbeat.Looped = true
heartbeat.Volume = 0
heartbeat.Parent = SoundService
do
	local cfg = SoundData.Heartbeat
	if cfg and (cfg.Id or 0) > 0 then
		heartbeat.SoundId = idToContent(cfg.Id)
	end
end

local inExpedition = false
local DANGER_RANGE = 45
local DANGER_CLOSE = 6

local function nearestMonsterDist(): number
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return math.huge end
	local folder = workspace:FindFirstChild("ExpeditionMonsters")
	if not folder then return math.huge end
	local best = math.huge
	for _, m in ipairs(folder:GetChildren()) do
		local pos
		if m:IsA("Model") then
			pos = m:GetPivot().Position
		elseif m:IsA("BasePart") then
			pos = m.Position
		end
		if pos then
			local d = (pos - hrp.Position).Magnitude
			if d < best then best = d end
		end
	end
	return best
end

task.spawn(function()
	local maxVol = (SoundData.Heartbeat and SoundData.Heartbeat.Volume) or 0.55
	while true do
		task.wait(0.15)
		if not inExpedition or heartbeat.SoundId == "" then
			if heartbeat.IsPlaying then heartbeat:Stop() end
		else
			local dist = nearestMonsterDist()
			local prox = math.clamp((DANGER_RANGE - dist) / (DANGER_RANGE - DANGER_CLOSE), 0, 1)
			if prox <= 0.02 then
				heartbeat.Volume = 0
				if heartbeat.IsPlaying then heartbeat:Stop() end
			else
				if not heartbeat.IsPlaying then heartbeat:Play() end
				-- louder + faster the closer it gets
				heartbeat.Volume = maxVol * prox
				heartbeat.PlaybackSpeed = 0.9 + prox * 0.8
			end
		end
	end
end)

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
		inExpedition = true
		setAmbient("ExpeditionAmbient")
	elseif state == "Stolen" then
		playOneShot("MonsterSteal")
	elseif state == "Scared" then
		-- monster reached you while empty-handed: a growl/jumpscare
		playOneShot("MonsterGrab")
	elseif state == "Extracted" then
		inExpedition = false
		playOneShot("Extract")
		playOneShot("Discover")
		setAmbient("MuseumAmbient")
	elseif state == "Left" then
		inExpedition = false
		setAmbient("MuseumAmbient")
	end
end)
