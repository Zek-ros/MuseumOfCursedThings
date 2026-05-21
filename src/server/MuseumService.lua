-- MuseumService.lua (ModuleScript)
-- Manages museum state: displaying artifacts, upgrading containment,
-- and letting players visit each other's museums.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService  = require(script.Parent.DataService)
local MuseumSignals = require(script.Parent.MuseumSignals)
local ArtifactData = require(ReplicatedStorage.Shared.ArtifactData)
local Constants    = require(ReplicatedStorage.Shared.Constants)
local MuseumStats  = require(ReplicatedStorage.Shared.MuseumStats)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local MuseumChangedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MuseumChanged")

local MuseumService = {}

-- Announce that a player's museum changed: notify server systems
-- (PedestalService rebuilds exhibits) and the owning client (refresh UI).
local function notifyChange(player: Player)
	MuseumSignals.MuseumChanged:Fire(player)
	MuseumChangedEvent:FireClient(player)
end

-- =============================================
--  DISPLAY / UNDISPLAY  (public so PedestalService can call them too)
-- =============================================

function MuseumService.DisplayArtifact(player: Player, artifactIndex: number)
	local data = DataService.GetData(player)
	if not data then return false, "No data" end

	local artifact = data.Artifacts[artifactIndex]
	if not artifact then return false, "Invalid index" end
	if artifact.IsDisplayed then return false, "Already displayed" end

	-- Count current displays
	local displayed = 0
	for _, a in ipairs(data.Artifacts) do
		if a.IsDisplayed then displayed += 1 end
	end

	local maxSlots = Constants.MAX_DISPLAYED_ARTIFACTS + ((data.MuseumLevel - 1) * 5)
	if displayed >= maxSlots then
		return false, "No display slots available"
	end

	artifact.IsDisplayed = true
	notifyChange(player)
	return true, "Displayed"
end

function MuseumService.UndisplayArtifact(player: Player, artifactIndex: number)
	local data = DataService.GetData(player)
	if not data then return false, "No data" end

	local artifact = data.Artifacts[artifactIndex]
	if not artifact then return false, "Invalid index" end

	artifact.IsDisplayed = false
	notifyChange(player)
	return true, "Removed from display"
end

-- =============================================
--  CONTAINMENT UPGRADE
-- =============================================

function MuseumService.UpgradeContainment(player: Player, artifactIndex: number, newType: string)
	local data = DataService.GetData(player)
	if not data then return false, "No data" end

	local artifact = data.Artifacts[artifactIndex]
	if not artifact then return false, "Invalid index" end

	local containment = ArtifactData.ContainmentTypes[newType]
	if not containment then return false, "Invalid containment type" end

	if data.Currency < containment.Cost then
		return false, "Not enough currency"
	end

	DataService.UpdateCurrency(player, -containment.Cost)
	artifact.ContainmentType = newType
	-- Containment changes effective danger + income, so resync.
	notifyChange(player)
	return true, "Upgraded"
end

-- =============================================
--  MUSEUM VISITING
-- =============================================

local function handleGetMuseumSummary(_caller: Player, targetName: string)
	local targetPlayer = Players:FindFirstChild(targetName)
	if not targetPlayer then return nil end

	local data = DataService.GetData(targetPlayer)
	if not data then return nil end

	local displayedArtifacts = {}
	for _, artifact in ipairs(data.Artifacts) do
		if artifact.IsDisplayed then
			local def = ArtifactData.Artifacts[artifact.ArtifactId]
			if def then
				table.insert(displayedArtifacts, {
					Name = def.Name,
					Rarity = def.Rarity,
					Description = def.Description,
					ContainmentType = artifact.ContainmentType,
				})
			end
		end
	end

	return {
		OwnerName = targetName,
		MuseumLevel = data.MuseumLevel,
		DisplayedArtifacts = displayedArtifacts,
		TotalArtifacts = #data.Artifacts,
	}
end

-- =============================================
--  GET INVENTORY (for client UI)
-- =============================================

local function handleGetInventory(player: Player)
	local data = DataService.GetData(player)
	if not data then return nil end

	local inventory = {}
	for i, artifact in ipairs(data.Artifacts) do
		local def = ArtifactData.Artifacts[artifact.ArtifactId]
		if def then
			table.insert(inventory, {
				Index = i,
				ArtifactId = artifact.ArtifactId,
				Name = def.Name,
				Rarity = def.Rarity,
				DangerLevel = def.DangerLevel,
				PassiveIncome = def.PassiveIncome,
				Description = def.Description,
				ContainmentType = artifact.ContainmentType,
				IsDisplayed = artifact.IsDisplayed,
			})
		end
	end

	local dangerScore = MuseumStats.CalculateDanger(data)

	return {
		Inventory = inventory,
		Currency = data.Currency,
		MuseumLevel = data.MuseumLevel,
		DangerScore = dangerScore,
		DangerTier = MuseumStats.GetDangerTier(dangerScore),
		IncomePerTick = MuseumStats.CalculateIncome(data),
	}
end

-- =============================================
--  WIRE UP REMOTES
-- =============================================

RemoteFunctions:WaitForChild("DisplayArtifact").OnServerInvoke      = MuseumService.DisplayArtifact
RemoteFunctions:WaitForChild("UndisplayArtifact").OnServerInvoke    = MuseumService.UndisplayArtifact
RemoteFunctions:WaitForChild("UpgradeContainment").OnServerInvoke   = MuseumService.UpgradeContainment
RemoteFunctions:WaitForChild("GetMuseumSummary").OnServerInvoke     = handleGetMuseumSummary
RemoteFunctions:WaitForChild("GetInventory").OnServerInvoke         = handleGetInventory

return MuseumService
