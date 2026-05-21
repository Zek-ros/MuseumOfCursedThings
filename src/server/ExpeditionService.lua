-- ExpeditionService.lua (ModuleScript)
-- Real expedition gameplay: send the player to the expedition map, let them
-- physically pick up an artifact, carry it to the extraction pad, and return
-- to their museum with it. Artifacts are only granted on successful extraction.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local ArtifactService   = require(script.Parent.ArtifactService)
local PedestalService   = require(script.Parent.PedestalService)
local ExpeditionBuilder = require(script.Parent.ExpeditionBuilder)
local ArtifactData      = require(ReplicatedStorage.Shared.ArtifactData)
local Constants         = require(ReplicatedStorage.Shared.Constants)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local ExpeditionStateEvent = RemoteEvents:WaitForChild("ExpeditionState")

local ExpeditionService = {}

local EXPEDITION_ORIGIN = CFrame.new(-1000, 0, 0)
local PICKUP_RESPAWN = 8

-- State
local mapInfo
local pickups = {}          -- [spawnIndex] = Part
local pickupBaseCF = {}     -- [spawnIndex] = CFrame (for spin)
local carrying = {}         -- [player] = { ArtifactId, Rarity }
local carriedPart = {}      -- [player] = Part
local inExpedition = {}     -- [player] = true
local extractDebounce = {}  -- [player] = true

local function rarityColor(rarity: string): Color3
	local info = Constants.RARITY[rarity]
	return (info and info.Color) or Color3.fromRGB(255, 255, 255)
end

local function fireState(player: Player, state: string, artifactName: string?)
	ExpeditionStateEvent:FireClient(player, { State = state, ArtifactName = artifactName })
end

-- =============================================
--  PICKUPS
-- =============================================
local function makeNameLabel(parent: Instance, text: string, color: Color3, offsetY: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 150, 0, 36)
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.AlwaysOnTop = true
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

local function spawnPickup(index: number)
	local artifactId, rarity = ArtifactService.RollArtifact()
	if not artifactId then return end
	local def = ArtifactData.Artifacts[artifactId]
	if not def then return end

	local part = Instance.new("Part")
	part.Name = "ArtifactPickup"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(2.2, 2.2, 2.2)
	part.Material = Enum.Material.Neon
	part.Color = rarityColor(rarity)
	part.CFrame = pickupBaseCF[index]

	local light = Instance.new("PointLight")
	light.Color = part.Color
	light.Range = 10
	light.Brightness = 2
	light.Parent = part

	makeNameLabel(part, def.Name, part.Color, 2.5)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take"
	prompt.ObjectText = def.Name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	prompt.Triggered:Connect(function(triggerPlayer)
		if not inExpedition[triggerPlayer] then return end
		if carrying[triggerPlayer] then
			fireState(triggerPlayer, "AlreadyCarrying")
			return
		end
		if not part.Parent then return end -- already taken
		part:Destroy()
		pickups[index] = nil

		carrying[triggerPlayer] = { ArtifactId = artifactId, Rarity = rarity }
		ExpeditionService.AttachCarry(triggerPlayer, artifactId, rarity)
		fireState(triggerPlayer, "Carrying", def.Name)

		task.delay(PICKUP_RESPAWN, function()
			if not pickups[index] then
				spawnPickup(index)
			end
		end)
	end)

	part.Parent = mapInfo.Model
	pickups[index] = part
end

-- =============================================
--  CARRYING
-- =============================================
function ExpeditionService.AttachCarry(player: Player, artifactId: string, rarity: string)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local def = ArtifactData.Artifacts[artifactId]

	local part = Instance.new("Part")
	part.Name = "CarriedArtifact"
	part.Size = Vector3.new(2, 2, 2)
	part.Material = Enum.Material.Neon
	part.Color = rarityColor(rarity)
	part.CanCollide = false
	part.Massless = true
	part.CFrame = hrp.CFrame * CFrame.new(0, 3.5, 0)

	if def then
		makeNameLabel(part, def.Name, part.Color, 2)
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = part
	weld.Parent = part

	part.Parent = char
	carriedPart[player] = part
end

local function removeCarry(player: Player)
	local part = carriedPart[player]
	if part then part:Destroy() end
	carriedPart[player] = nil
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
	local museum = PedestalService.GetMuseum(player)
	if museum and museum.Spawn then
		teleportTo(player, museum.Spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

function ExpeditionService.Start(player: Player)
	if inExpedition[player] then return false, "Already on an expedition" end
	inExpedition[player] = true
	teleportTo(player, mapInfo.SpawnCFrame)
	fireState(player, "Entered")
	return true, "Expedition started"
end

function ExpeditionService.Leave(player: Player)
	if not inExpedition[player] then return end
	if carrying[player] then
		carrying[player] = nil
		removeCarry(player)
	end
	returnToMuseum(player)
	fireState(player, "Left")
end

local function doExtract(player: Player)
	local carry = carrying[player]
	if not carry then return end
	carrying[player] = nil
	removeCarry(player)

	ArtifactService.GrantArtifact(player, carry.ArtifactId)
	local def = ArtifactData.Artifacts[carry.ArtifactId]
	returnToMuseum(player)
	fireState(player, "Extracted", def and def.Name or "artifact")
end

-- =============================================
--  PICKUP SPIN
-- =============================================
local spinAngle = 0
RunService.Heartbeat:Connect(function(dt)
	spinAngle += dt * 1.2
	for index, part in pairs(pickups) do
		if part.Parent and pickupBaseCF[index] then
			part.CFrame = pickupBaseCF[index] * CFrame.Angles(0, spinAngle, 0)
		end
	end
end)

-- =============================================
--  INIT
-- =============================================
local function init()
	mapInfo = ExpeditionBuilder.Build(EXPEDITION_ORIGIN)
	mapInfo.Model.Parent = workspace

	-- Record base CFrames and spawn the initial pickups
	for index, cf in ipairs(mapInfo.SpawnPoints) do
		pickupBaseCF[index] = cf
		spawnPickup(index)
	end

	-- Extraction detection
	mapInfo.ExtractionZone.Touched:Connect(function(hit)
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

-- =============================================
--  REMOTES + LIFECYCLE
-- =============================================
RemoteFunctions:WaitForChild("StartExpedition").OnServerInvoke = function(player)
	return ExpeditionService.Start(player)
end

RemoteEvents:WaitForChild("LeaveExpedition").OnServerEvent:Connect(function(player)
	ExpeditionService.Leave(player)
end)

Players.PlayerRemoving:Connect(function(player)
	carrying[player] = nil
	inExpedition[player] = nil
	extractDebounce[player] = nil
	removeCarry(player)
end)

init()

return ExpeditionService
