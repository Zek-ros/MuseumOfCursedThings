-- ExpeditionService.lua (ModuleScript)
-- Real expedition gameplay: send the player to a chosen expedition map, let
-- them physically pick up an artifact, carry it to the extraction pad, and
-- return to their museum with it. Artifacts are only granted on extraction.
--
-- Supports multiple themed maps (see ExpeditionMaps). Each map is built once at
-- its own location with its own pickups + extraction zone.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local ArtifactService   = require(script.Parent.ArtifactService)
local PedestalService   = require(script.Parent.PedestalService)
local MonsterService    = require(script.Parent.MonsterService)
local ExpeditionBuilder = require(script.Parent.ExpeditionBuilder)
local ModelFactory      = require(script.Parent.ModelFactory)
local ArtifactData      = require(ReplicatedStorage.Shared.ArtifactData)
local ArtifactModels    = require(ReplicatedStorage.Shared.ArtifactModels)
local Constants         = require(ReplicatedStorage.Shared.Constants)
local ExpeditionMaps    = require(ReplicatedStorage.Shared.ExpeditionMaps)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local ExpeditionStateEvent = RemoteEvents:WaitForChild("ExpeditionState")

local ExpeditionService = {}

local EXPEDITION_BASE = Vector3.new(-1000, 0, 0)
local MAP_SPACING = 320 -- mazes are big now; keep them well clear of each other
local PICKUP_RESPAWN = 12 -- slower respawn keeps artifacts scarce
local DEFAULT_PICKUPS = 6 -- fallback artifact count if a map doesn't specify one
local DEFAULT_MONSTERS = 4 -- fallback patrol count if a map doesn't specify one

-- State
local maps = {}             -- [mapId] = { Info, Pickups = {idx=Part}, BaseCF = {idx=CFrame} }
local carrying = {}         -- [player] = { ArtifactId, Rarity }
local carriedPart = {}      -- [player] = Part
local inExpedition = {}     -- [player] = mapId
local extractDebounce = {}  -- [player] = true

local function rarityColor(rarity: string): Color3
	local info = Constants.RARITY[rarity]
	return (info and info.Color) or Color3.fromRGB(255, 255, 255)
end

local function fireState(player: Player, state: string, artifactName: string?, extra: { [string]: any }?)
	local payload = { State = state, ArtifactName = artifactName }
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	ExpeditionStateEvent:FireClient(player, payload)
end

-- =============================================
--  PICKUPS
-- =============================================
local function makeNameLabel(parent: Instance, text: string, color: Color3, offsetY: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 150, 0, 36)
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard
	billboard.Parent = parent
	return billboard
end

local spawnRandomPickup -- forward declare (spawnPickup respawns via this)

local function spawnPickup(mapId: string, index: number, forcedId: string?, forcedRarity: string?)
	local map = maps[mapId]
	if not map then return end

	-- A specific artifact (e.g. one dropped by a swap) or a fresh random roll.
	local artifactId, rarity
	if forcedId then
		artifactId, rarity = forcedId, forcedRarity
	else
		artifactId, rarity = ArtifactService.RollArtifact(map.Luck)
	end
	if not artifactId then return end
	local def = ArtifactData.Artifacts[artifactId]
	if not def then return end

	local color = rarityColor(rarity)

	-- The artifact's real model (asset id → builder) or a small neon cube.
	local builder = ArtifactModels[artifactId]
	local visual = ModelFactory.Resolve(def.ModelId, builder or function()
		local cube = Instance.new("Part")
		cube.Size = Vector3.new(1.8, 1.8, 1.8)
		cube.Material = Enum.Material.Neon
		cube.Color = color
		return cube
	end)
	visual.Name = "ArtifactPickup"

	-- Glow + name label + the "Take" prompt all hang off the model's main part.
	local anchor = ModelFactory.AnchorPart(visual)
	if anchor then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 6
		light.Brightness = 1.4
		light.Parent = anchor

		-- Name only legible up close (can't ID artifacts from across the room).
		local nameTag = makeNameLabel(anchor, def.Name, color, 3)
		nameTag.MaxDistance = 16

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Take"
		prompt.ObjectText = def.Name
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchor

		prompt.Triggered:Connect(function(triggerPlayer)
			if not inExpedition[triggerPlayer] then return end
			if not visual.Parent then return end -- already taken

			local swappingOut = carrying[triggerPlayer]
			visual:Destroy()
			map.Pickups[index] = nil

			-- Carry this artifact (AttachCarry replaces any existing carried model).
			carrying[triggerPlayer] = { ArtifactId = artifactId, Rarity = rarity }
			ExpeditionService.AttachCarry(triggerPlayer, artifactId, rarity)

			if swappingOut then
				-- SWAP: leave the previously-carried artifact here in its place.
				fireState(triggerPlayer, "Swapped", def.Name)
				spawnPickup(mapId, index, swappingOut.ArtifactId, swappingOut.Rarity)
			else
				fireState(triggerPlayer, "Carrying", def.Name)
				-- The artifact attracts monsters while carried — more/faster for scarier ones.
				MonsterService.StartHunt(triggerPlayer, def.DangerLevel)
				-- Respawn elsewhere (a random free spot) so locations keep shifting.
				task.delay(PICKUP_RESPAWN, function()
					spawnRandomPickup(mapId)
				end)
			end
		end)
	end

	ModelFactory.Place(visual, map.BaseCF[index])
	visual.Parent = map.Info.Model
	map.Pickups[index] = visual
end

-- Spawn one pickup at a random unoccupied position in the map's pool.
spawnRandomPickup = function(mapId: string)
	local map = maps[mapId]
	if not map then return end
	local free = {}
	for i = 1, #map.BaseCF do
		if not map.Pickups[i] then
			table.insert(free, i)
		end
	end
	if #free == 0 then return end
	spawnPickup(mapId, free[math.random(#free)])
end

-- =============================================
--  CARRYING
-- =============================================
function ExpeditionService.AttachCarry(player: Player, artifactId: string, rarity: string)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local def = ArtifactData.Artifacts[artifactId]

	local color = rarityColor(rarity)

	-- Replace any existing carried visual (e.g. when swapping artifacts).
	if carriedPart[player] then
		carriedPart[player]:Destroy()
		carriedPart[player] = nil
	end

	-- Carry the real artifact model, shrunk so it doesn't block your view.
	local builder = ArtifactModels[artifactId]
	local visual = ModelFactory.Resolve(def and def.ModelId, builder or function()
		local cube = Instance.new("Part")
		cube.Size = Vector3.new(2, 2, 2)
		cube.Material = Enum.Material.Neon
		cube.Color = color
		return cube
	end)
	visual.Name = "CarriedArtifact"
	if visual:IsA("Model") then
		pcall(function()
			visual:ScaleTo(0.55)
		end)
	end

	local anchor = ModelFactory.AnchorPart(visual)
	if anchor and def then
		makeNameLabel(anchor, def.Name, color, 2)
	end

	-- Float it above the player and weld every part so it rides along.
	ModelFactory.Place(visual, hrp.CFrame * CFrame.new(0, 3.2, 0))
	local function rideAlong(p: BasePart)
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = p
		weld.Parent = p
	end
	if visual:IsA("BasePart") then
		rideAlong(visual)
	else
		for _, d in ipairs(visual:GetDescendants()) do
			if d:IsA("BasePart") then
				rideAlong(d)
			end
		end
	end

	visual.Parent = char
	carriedPart[player] = visual
end

local function removeCarry(player: Player)
	local part = carriedPart[player]
	if part then part:Destroy() end
	carriedPart[player] = nil
end

-- =============================================
--  FLASHLIGHT (held in hand on expeditions)
-- =============================================
local FLASHLIGHT_MODEL_ID = 516522664
local flashlights = {} -- [player] = { Model, Joint, SavedC0 }

local function removeFlashlight(player: Player)
	local entry = flashlights[player]
	if not entry then return end
	if entry.Joint and entry.SavedC0 then
		pcall(function()
			entry.Joint.C0 = entry.SavedC0
		end)
	end
	if entry.Model then
		entry.Model:Destroy()
	end
	flashlights[player] = nil
end

local function equipFlashlight(player: Player)
	removeFlashlight(player)
	local char = player.Character
	if not char then return end
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end

	local fl = ModelFactory.TryLoad(FLASHLIGHT_MODEL_ID)
	if not fl then return end
	local handle = (fl:IsA("Model") and (fl.PrimaryPart or fl:FindFirstChildWhichIsA("BasePart"))) or fl
	if not handle or not handle:IsA("BasePart") then
		fl:Destroy()
		return
	end

	-- Sit it in the palm and weld every part so it rides with the hand.
	if fl:IsA("Model") then
		fl:PivotTo(hand.CFrame * CFrame.new(0, -0.6, -0.3))
	else
		fl.CFrame = hand.CFrame * CFrame.new(0, -0.6, -0.3)
	end
	local parts = {}
	if fl:IsA("BasePart") then
		parts = { fl }
	else
		for _, d in ipairs(fl:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
	end
	for _, p in ipairs(parts) do
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		local w = Instance.new("WeldConstraint")
		w.Part0 = hand
		w.Part1 = p
		w.Parent = p
	end
	fl.Parent = char

	-- A beam from the flashlight itself (the client also lights the local player).
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Front
	beam.Angle = 60
	beam.Range = 30
	beam.Brightness = 2
	beam.Color = Color3.fromRGB(255, 244, 214)
	beam.Parent = handle

	local entry = { Model = fl }

	-- Pose the right arm forward (best-effort; depends on R15/R6 rig).
	local upperArm = char:FindFirstChild("RightUpperArm")
	local shoulder = upperArm and upperArm:FindFirstChild("RightShoulder")
	if shoulder and shoulder:IsA("Motor6D") then
		entry.Joint = shoulder
		entry.SavedC0 = shoulder.C0
		shoulder.C0 = shoulder.C0 * CFrame.Angles(math.rad(-75), 0, 0)
	else
		local torso = char:FindFirstChild("Torso")
		local rs = torso and torso:FindFirstChild("Right Shoulder")
		if rs and rs:IsA("Motor6D") then
			entry.Joint = rs
			entry.SavedC0 = rs.C0
			rs.C0 = rs.C0 * CFrame.Angles(0, 0, math.rad(-75))
		end
	end

	flashlights[player] = entry
end

-- =============================================
--  TRAVEL
-- =============================================
local function teleportTo(player: Player, cframe: CFrame)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		pcall(function()
			hrp.CFrame = cframe
		end)
	end
end

local function returnToMuseum(player: Player)
	inExpedition[player] = nil
	removeFlashlight(player)
	local museum = PedestalService.GetMuseum(player)
	if museum and museum.Spawn then
		teleportTo(player, museum.Spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

function ExpeditionService.Start(player: Player, mapId: string)
	if inExpedition[player] then return false, "Already on an expedition" end
	local map = maps[mapId]
	if not map then return false, "Unknown expedition" end

	inExpedition[player] = mapId
	teleportTo(player, map.Info.SpawnCFrame)
	-- Fire the darkness/lighting IMMEDIATELY so it doesn't wait on the flashlight
	-- asset download; equip the flashlight in the background.
	fireState(player, "Entered", nil, { Fog = map.Fog, FogColor = map.FogColor, Ambient = map.Ambient })
	task.spawn(equipFlashlight, player)
	return true, "Expedition started"
end

function ExpeditionService.Leave(player: Player)
	if not inExpedition[player] then return end
	if carrying[player] then
		carrying[player] = nil
		removeCarry(player)
	end
	MonsterService.StopHunt(player)
	returnToMuseum(player)
	fireState(player, "Left")
end

-- A monster caught the player: they drop the artifact but stay on the map.
function ExpeditionService.DropCarry(player: Player)
	if not carrying[player] then return end
	carrying[player] = nil
	removeCarry(player)
	MonsterService.StopHunt(player)
	fireState(player, "Dropped")
end

local function doExtract(player: Player)
	local carry = carrying[player]
	if not carry then return end
	carrying[player] = nil
	removeCarry(player)
	MonsterService.StopHunt(player)

	ArtifactService.GrantArtifact(player, carry.ArtifactId)
	local def = ArtifactData.Artifacts[carry.ArtifactId]
	returnToMuseum(player)
	fireState(player, "Extracted", def and def.Name or "artifact")
end

-- =============================================
--  STALK & STEAL: monsters take your carry and flee with it (MonsterService
--  drives the chase; ExpeditionService owns the carry, so it does the handoff).
-- =============================================

-- A monster caught a carrier: take the artifact off them and hand it to the thief.
MonsterService.OnSteal = function(player: Player): (string?, string?)
	local carry = carrying[player]
	if not carry then return nil, nil end
	carrying[player] = nil
	removeCarry(player)
	local def = ArtifactData.Artifacts[carry.ArtifactId]
	fireState(player, "Stolen", def and def.Name or "your artifact")
	return carry.ArtifactId, carry.Rarity
end

-- The player tackled the thief: snap the artifact back onto them (the heat's on again).
MonsterService.OnRecover = function(player: Player, artifactId: string, rarity: string)
	if not inExpedition[player] or carrying[player] then return end
	carrying[player] = { ArtifactId = artifactId, Rarity = rarity }
	ExpeditionService.AttachCarry(player, artifactId, rarity)
	local def = ArtifactData.Artifacts[artifactId]
	fireState(player, "Recovered", def and def.Name or "your artifact")
	MonsterService.StartHunt(player, def and def.DangerLevel or 2)
end

-- The thief got away: the artifact is lost.
MonsterService.OnStealEscape = function(player: Player?, artifactId: string)
	if player and inExpedition[player] then
		local def = ArtifactData.Artifacts[artifactId]
		fireState(player, "StealEscaped", def and def.Name or "the artifact")
	end
end

-- =============================================
--  PICKUP SPIN (all maps)
-- =============================================
local spinAngle = 0
RunService.Heartbeat:Connect(function(dt)
	spinAngle += dt * 1.2
	for _, map in pairs(maps) do
		for index, visual in pairs(map.Pickups) do
			if visual.Parent and map.BaseCF[index] then
				ModelFactory.Place(visual, map.BaseCF[index] * CFrame.Angles(0, spinAngle, 0))
			end
		end
	end
end)

-- =============================================
--  INIT
-- =============================================
local function buildMap(def, mapIndex: number)
	local origin = CFrame.new(EXPEDITION_BASE + Vector3.new(0, 0, (mapIndex - 1) * MAP_SPACING))
	local info = ExpeditionBuilder.Build(origin, def)
	info.Model.Parent = workspace

	-- Per-map tuning (see ExpeditionMaps): how much loot, how rare, how crowded.
	local pickupCount = def.Pickups or DEFAULT_PICKUPS
	local monsterCount = def.Monsters or DEFAULT_MONSTERS

	local map = { Info = info, Pickups = {}, BaseCF = {}, Luck = def.Luck or 1, Fog = def.Fog, FogColor = def.FogColor, Ambient = def.Ambient }
	maps[def.Id] = map

	-- Seed the position pool, then place only a few artifacts at random spots.
	for index, cf in ipairs(info.SpawnPoints) do
		map.BaseCF[index] = cf
	end
	for _ = 1, math.min(pickupCount, #info.SpawnPoints) do
		spawnRandomPickup(def.Id)
	end

	-- Roaming monsters that make just being on the map dangerous.
	MonsterService.SpawnPatrol(origin, info.HalfX, info.HalfZ, monsterCount)

	-- Extraction detection (any map's pad extracts whoever is carrying)
	info.ExtractionZone.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		if not inExpedition[player] or not carrying[player] then return end
		if extractDebounce[player] then return end
		extractDebounce[player] = true
		doExtract(player)
		task.delay(1, function()
			extractDebounce[player] = nil
		end)
	end)
end

local function init()
	for i, def in ipairs(ExpeditionMaps) do
		buildMap(def, i)
	end
	-- Warm the flashlight asset cache so the first expedition equips instantly.
	task.spawn(function()
		ModelFactory.TryLoad(FLASHLIGHT_MODEL_ID)
	end)
end

-- =============================================
--  REMOTES + LIFECYCLE
-- =============================================
RemoteFunctions:WaitForChild("StartExpedition").OnServerInvoke = function(player, mapId)
	return ExpeditionService.Start(player, mapId)
end

RemoteEvents:WaitForChild("LeaveExpedition").OnServerEvent:Connect(function(player)
	ExpeditionService.Leave(player)
end)

Players.PlayerRemoving:Connect(function(player)
	carrying[player] = nil
	inExpedition[player] = nil
	extractDebounce[player] = nil
	removeCarry(player)
	removeFlashlight(player)
end)

init()

return ExpeditionService
