-- PedestalService.lua (ModuleScript)
-- Gives each player a physical museum: builds the room, teleports them in,
-- and turns their displayed artifacts into rotating, glowing exhibits on
-- pedestals. Listens to MuseumSignals.MuseumChanged to stay in sync with
-- the data layer.
--
-- NOTE: artifact "models" are procedural neon cubes for now — drop in real
-- meshes later by replacing spawnArtifactDisplay().

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService   = require(script.Parent.DataService)
local MuseumService = require(script.Parent.MuseumService)
local MuseumBuilder = require(script.Parent.MuseumBuilder)
local MuseumSignals = require(script.Parent.MuseumSignals)
local ModelFactory  = require(script.Parent.ModelFactory)
local ArtifactData  = require(ReplicatedStorage.Shared.ArtifactData)
local Constants     = require(ReplicatedStorage.Shared.Constants)
local MuseumStats   = require(ReplicatedStorage.Shared.MuseumStats)

local OpenInventoryEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("OpenInventory")

local PedestalService = {}

-- [player] = { Model, Pedestals = {Part}, Spawn, Assignments = {pedIdx = artifactIndex}, DisplayParts = {{Part, Base}} }
local museums = {}
local nextPlotIndex = 0
local PLOT_SPACING = 160
local portalDebounce = {} -- [player] = true while a hub-portal teleport is cooling down

-- =============================================
--  ARTIFACT DISPLAY MODELS
-- =============================================
local function rarityColor(rarity: string): Color3
	local info = Constants.RARITY[rarity]
	return (info and info.Color) or Color3.fromRGB(255, 255, 255)
end

local function spawnArtifactDisplay(museum, pedestal: BasePart, def)
	local base = pedestal.Position + Vector3.new(0, pedestal.Size.Y / 2 + 3, 0)
	local color = rarityColor(def.Rarity)

	-- Real model by asset id if the artifact defines one; else a neon cube.
	local visual = ModelFactory.Resolve(def.ModelId, function()
		local part = Instance.new("Part")
		part.Name = "ArtifactDisplay"
		part.CastShadow = false
		part.Size = Vector3.new(2.4, 2.4, 2.4)
		part.Material = Enum.Material.Neon
		part.Color = color
		return part
	end)

	-- Glow + name label attach to the visual's main part (works for both).
	local anchor = ModelFactory.AnchorPart(visual)
	if anchor then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 3
		light.Range = 12
		light.Parent = anchor

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 200, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = false -- let walls/roof occlude it
		billboard.MaxDistance = 55     -- only readable up close
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = def.Name
		label.TextColor3 = color
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextStrokeTransparency = 0.3
		label.Parent = billboard
		billboard.Parent = anchor
	end

	ModelFactory.Place(visual, CFrame.new(base))
	visual.Parent = museum.Model
	return visual, base
end

-- =============================================
--  REFRESH: sync pedestals to a player's displayed artifacts
-- =============================================
-- Attach the interaction prompt to a pedestal (empty -> open inventory,
-- occupied -> remove the displayed artifact).
local function attachPrompt(player: Player, pedestal: BasePart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Inventory"
	prompt.ObjectText = "Empty Pedestal"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pedestal

	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player then return end
		local museum = museums[player]
		if not museum then return end
		local pedIdx = pedestal:GetAttribute("PedestalIndex")
		local artifactIndex = museum.Assignments[pedIdx]
		if artifactIndex then
			MuseumService.UndisplayArtifact(player, artifactIndex)
		else
			OpenInventoryEvent:FireClient(player)
		end
	end)
end

-- Grow the museum's physical pedestals to match its current level.
local function ensurePedestals(player: Player, data, museum)
	local target = MuseumStats.DisplaySlots(data)
	while #museum.Pedestals < target do
		local index = #museum.Pedestals + 1
		local pedestal = MuseumBuilder.MakePedestal(museum.Origin, index, museum.Model)
		attachPrompt(player, pedestal)
		table.insert(museum.Pedestals, pedestal)
	end
end

local function refreshPlayer(player: Player)
	local museum = museums[player]
	if not museum then return end
	local data = DataService.GetData(player)
	if not data then return end

	-- Add pedestals if the museum has leveled up since last refresh
	ensurePedestals(player, data, museum)

	-- Clear current display models
	for _, d in ipairs(museum.DisplayParts) do
		d.Visual:Destroy()
	end
	table.clear(museum.DisplayParts)
	table.clear(museum.Assignments)

	-- Gather displayed artifacts (preserving their inventory index)
	local displayed = {}
	for i, art in ipairs(data.Artifacts) do
		if art.IsDisplayed then
			local def = ArtifactData.Artifacts[art.ArtifactId]
			if def then
				table.insert(displayed, { Index = i, Def = def })
			end
		end
	end

	-- Assign displayed artifacts to pedestals in order
	for pedIdx, pedestal in ipairs(museum.Pedestals) do
		local prompt = pedestal:FindFirstChildOfClass("ProximityPrompt")
		local entry = displayed[pedIdx]
		if entry then
			local visual, base = spawnArtifactDisplay(museum, pedestal, entry.Def)
			table.insert(museum.DisplayParts, { Visual = visual, Base = base })
			museum.Assignments[pedIdx] = entry.Index
			if prompt then
				prompt.ActionText = "Remove"
				prompt.ObjectText = entry.Def.Name
			end
		else
			if prompt then
				prompt.ActionText = "Open Inventory"
				prompt.ObjectText = "Empty Pedestal"
			end
		end
	end
end

-- =============================================
--  MUSEUM SETUP / TELEPORT
-- =============================================
local function teleportIntoMuseum(player: Player, spawn: BasePart)
	task.spawn(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then
			-- character may still be loading; wait briefly for the root part
			root = char:WaitForChild("HumanoidRootPart", 5)
		end
		if root then
			pcall(function()
				root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
			end)
		end
	end)
end

local function setupMuseum(player: Player)
	if museums[player] then return end

	local plotIndex = nextPlotIndex
	nextPlotIndex += 1
	local origin = CFrame.new(plotIndex * PLOT_SPACING, 0, 0)

	local built = MuseumBuilder.Build(origin, player.Name)
	built.Model.Parent = workspace
	print(("[PedestalService] Built museum for %s at plot %d (%s)"):format(player.Name, plotIndex, tostring(origin.Position)))

	museums[player] = {
		Model = built.Model,
		Pedestals = built.Pedestals,
		Spawn = built.Spawn,
		Origin = origin,
		Assignments = {},
		DisplayParts = {},
		ChaosCone = nil, -- lazily created by ChaosEffects
		ChaosMannequin = nil, -- lazily created by ChaosEffects
	}

	-- Add an interaction prompt to each starting pedestal
	for _, pedestal in ipairs(built.Pedestals) do
		attachPrompt(player, pedestal)
	end

	-- Walk into the hub portal to travel to the hub (HubService listens).
	if built.Portal then
		built.Portal.Touched:Connect(function(hit)
			local toucher = Players:GetPlayerFromCharacter(hit.Parent)
			if not toucher then return end
			if portalDebounce[toucher] then return end
			portalDebounce[toucher] = true
			MuseumSignals.GoToHubRequested:Fire(toucher)
			task.delay(2, function()
				portalDebounce[toucher] = nil
			end)
		end)
	end

	-- Note: spawning is owned by HubService now (players spawn in the hub and
	-- reach their museum via the hub pad / "My Museum" button). We just build it.

	refreshPlayer(player)
end

local function cleanupMuseum(player: Player)
	local museum = museums[player]
	if museum and museum.Model then
		museum.Model:Destroy()
	end
	museums[player] = nil
end

-- =============================================
--  ARTIFACT SPIN / BOB ANIMATION
-- =============================================
local spinAngle = 0
RunService.Heartbeat:Connect(function(dt)
	spinAngle += dt * 1.5
	local bob = math.sin(spinAngle * 1.5) * 0.4
	for _, museum in pairs(museums) do
		for _, d in ipairs(museum.DisplayParts) do
			ModelFactory.Place(d.Visual, CFrame.new(d.Base + Vector3.new(0, bob, 0)) * CFrame.Angles(0, spinAngle, 0))
		end
	end
end)

-- =============================================
--  LIFECYCLE
-- =============================================
local function onPlayerAdded(player: Player)
	-- Wait for DataService to finish loading this player's data
	local data
	for _ = 1, 100 do
		data = DataService.GetData(player)
		if data then break end
		task.wait(0.1)
	end
	if not data then
		warn("[PedestalService] Data never loaded for " .. player.Name .. "; skipping museum build.")
		return
	end
	print("[PedestalService] Data ready for " .. player.Name .. ", building museum...")
	local ok, err = pcall(setupMuseum, player)
	if not ok then
		warn("[PedestalService] setupMuseum failed for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(cleanupMuseum)

-- Handle any players already present when this module loads
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Rebuild a player's exhibits whenever their displayed artifacts change
MuseumSignals.MuseumChanged.Event:Connect(refreshPlayer)

-- Let other systems (ChaosEffects) find a player's museum to spawn effects in.
function PedestalService.GetMuseum(player: Player)
	return museums[player]
end

-- =============================================
--  MUSEUM VISITING
-- =============================================
function PedestalService.VisitMuseum(player: Player, targetName: string)
	local target = Players:FindFirstChild(targetName)
	if not target then return false, "Player not found" end
	if target == player then return false, "That's your own museum" end
	local museum = museums[target]
	if not museum or not museum.Spawn then return false, "Their museum isn't ready yet" end
	teleportIntoMuseum(player, museum.Spawn)
	return true, "Visiting " .. targetName .. "'s museum"
end

function PedestalService.ReturnHome(player: Player)
	local museum = museums[player]
	if museum and museum.Spawn then
		teleportIntoMuseum(player, museum.Spawn)
	end
	return true
end

local PedestalRemotes = ReplicatedStorage:WaitForChild("RemoteFunctions")
PedestalRemotes:WaitForChild("VisitMuseum").OnServerInvoke = function(player, targetName)
	return PedestalService.VisitMuseum(player, targetName)
end
PedestalRemotes:WaitForChild("ReturnHome").OnServerInvoke = function(player)
	return PedestalService.ReturnHome(player)
end

return PedestalService
