-- DataService.lua (ModuleScript)
-- Saves and loads all player data using Roblox DataStoreService.
-- Other server scripts require() this module to read/write player state.
--
-- DataStores only work in a PUBLISHED place with API access enabled. In an
-- unpublished local place (e.g. fresh Studio testing) GetDataStore throws, so
-- we degrade gracefully to in-memory-only data: the game is fully playable,
-- progress just isn't persisted between sessions until the place is published.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Try to acquire the DataStore; tolerate failure (unpublished place / no API access).
local PlayerDataStore
local dataStoreAvailable = false
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("MuseumPlayerData_v1")
	end)
	if ok then
		PlayerDataStore = result
		dataStoreAvailable = true
	else
		warn("[DataService] DataStores unavailable (" .. tostring(result) .. ").")
		warn("[DataService] Running in MEMORY-ONLY mode — progress will not be saved this session.")
	end
end

local DataService = {}
local playerData = {} -- in-memory cache keyed by Player instance

-- =============================================
--  DEFAULT DATA TEMPLATE
-- =============================================
local DEFAULT_DATA = {
	Currency = 100,
	-- Each entry: { ArtifactId = string, ContainmentType = string, IsDisplayed = bool }
	Artifacts = {},
	MuseumLevel = 1,
	Discovered = {}, -- [artifactId] = true; powers the collection index
	TutorialDone = false,
	ResearchedArtifacts = {},
	Statistics = {
		ArtifactsCollected = 0,
		ChaosEventsSurvived = 0,
		TotalEarned = 0,
	},
}

-- =============================================
--  HELPERS
-- =============================================
local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Merge saved data on top of defaults so new fields added in updates
-- are automatically present for returning players.
local function mergeWithDefaults(saved)
	local merged = deepCopy(DEFAULT_DATA)
	for key, value in pairs(saved) do
		if type(value) == "table" and type(merged[key]) == "table" then
			-- one level deep merge for sub-tables like Statistics
			for k2, v2 in pairs(value) do
				merged[key][k2] = v2
			end
		else
			merged[key] = value
		end
	end
	return merged
end

-- =============================================
--  PUBLIC API
-- =============================================

function DataService.LoadData(player: Player)
	-- No DataStore (unpublished place): start everyone fresh, in memory.
	if not dataStoreAvailable then
		playerData[player] = deepCopy(DEFAULT_DATA)
		return playerData[player]
	end

	local userId = tostring(player.UserId)

	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(userId)
	end)

	if success and data then
		playerData[player] = mergeWithDefaults(data)
	else
		playerData[player] = deepCopy(DEFAULT_DATA)
		if not success then
			warn("[DataService] Failed to load data for " .. player.Name .. ": " .. tostring(data))
		end
	end

	return playerData[player]
end

function DataService.SaveData(player: Player)
	if not playerData[player] then return end
	-- Nothing to persist to in memory-only mode.
	if not dataStoreAvailable then return end

	local userId = tostring(player.UserId)
	local success, err = pcall(function()
		PlayerDataStore:SetAsync(userId, playerData[player])
	end)

	if not success then
		warn("[DataService] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

function DataService.GetData(player: Player)
	return playerData[player]
end

function DataService.UpdateCurrency(player: Player, amount: number)
	local data = playerData[player]
	if not data then return end
	data.Currency = math.max(0, data.Currency + amount)
	if amount > 0 then
		data.Statistics.TotalEarned += amount
	end
end

function DataService.AddArtifact(player: Player, artifactId: string, containmentType: string?)
	local data = playerData[player]
	if not data then return end
	table.insert(data.Artifacts, {
		ArtifactId = artifactId,
		ContainmentType = containmentType or "GlassCase",
		IsDisplayed = false,
	})
	data.Statistics.ArtifactsCollected += 1
	-- Record first-time discovery for the collection index
	data.Discovered = data.Discovered or {}
	data.Discovered[artifactId] = true
end

function DataService.CleanupPlayer(player: Player)
	playerData[player] = nil
end

-- =============================================
--  LIFECYCLE HOOKS
-- =============================================

Players.PlayerAdded:Connect(function(player)
	DataService.LoadData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.SaveData(player)
	DataService.CleanupPlayer(player)
end)

-- Save everyone on server shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SaveData(player)
	end
end)

-- Auto-save every 60 seconds
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			DataService.SaveData(player)
		end
	end
end)

return DataService
