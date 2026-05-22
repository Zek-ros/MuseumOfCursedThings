-- LeaderboardService.lua (ModuleScript)
-- Global leaderboards via OrderedDataStores: lifetime coins earned ("Top
-- Curators") and unique artifacts discovered ("Top Collectors"). Falls back to
-- ranking the current server's players when DataStores aren't available
-- (e.g. unpublished Studio testing), so it always shows something.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

local RemoteFunctions = game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunctions")

local LeaderboardService = {}

local TOP_N = 10
local REFRESH_RATE = 60

-- Try to acquire ordered stores (needs a published place + API access).
local earnedStore, collectionStore, prestigeStore
local available = false
do
	local ok = pcall(function()
		earnedStore = DataStoreService:GetOrderedDataStore("MuseumTopEarned_v1")
		collectionStore = DataStoreService:GetOrderedDataStore("MuseumTopCollection_v1")
		prestigeStore = DataStoreService:GetOrderedDataStore("MuseumTopPrestige_v1")
	end)
	available = ok and earnedStore ~= nil
	if not available then
		warn("[LeaderboardService] OrderedDataStores unavailable — using per-server leaderboard.")
	end
end

local cachedEarned = {}
local cachedCollection = {}
local cachedPrestige = {}
local nameCache = {} -- [userId] = name

local function discoveredCount(data): number
	local n = 0
	for _ in pairs(data.Discovered or {}) do n += 1 end
	return n
end

local function getName(userId: number): string
	if nameCache[userId] then return nameCache[userId] end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local resolved = (ok and name) or ("Player " .. userId)
	nameCache[userId] = resolved
	return resolved
end

-- =============================================
--  PERSISTENCE
-- =============================================
local function savePlayer(player: Player)
	if not available then return end
	local data = DataService.GetData(player)
	if not data then return end
	nameCache[player.UserId] = player.Name
	local key = tostring(player.UserId)
	pcall(function()
		earnedStore:SetAsync(key, math.floor(data.Statistics.TotalEarned or 0))
	end)
	pcall(function()
		collectionStore:SetAsync(key, discoveredCount(data))
	end)
	pcall(function()
		prestigeStore:SetAsync(key, data.Prestige or 0)
	end)
end

local function fetchTop(store): { { Name: string, Value: number } }
	local result = {}
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, TOP_N)
	end)
	if not ok or not pages then return result end
	local ok2, page = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not ok2 or not page then return result end
	for _, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		if userId then
			table.insert(result, { Name = getName(userId), Value = entry.value })
		end
	end
	return result
end

local function rankCurrentServer()
	local earned, collection, prestige = {}, {}, {}
	for _, player in ipairs(Players:GetPlayers()) do
		local data = DataService.GetData(player)
		if data then
			table.insert(earned, { Name = player.Name, Value = math.floor(data.Statistics.TotalEarned or 0) })
			table.insert(collection, { Name = player.Name, Value = discoveredCount(data) })
			table.insert(prestige, { Name = player.Name, Value = data.Prestige or 0 })
		end
	end
	table.sort(earned, function(a, b) return a.Value > b.Value end)
	table.sort(collection, function(a, b) return a.Value > b.Value end)
	table.sort(prestige, function(a, b) return a.Value > b.Value end)
	return earned, collection, prestige
end

local function refresh()
	if available then
		cachedEarned = fetchTop(earnedStore)
		cachedCollection = fetchTop(collectionStore)
		cachedPrestige = fetchTop(prestigeStore)
	else
		cachedEarned, cachedCollection, cachedPrestige = rankCurrentServer()
	end
end

-- =============================================
--  LOOP + REMOTES
-- =============================================
task.spawn(function()
	task.wait(5)
	refresh()
	while true do
		task.wait(REFRESH_RATE)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayer(player)
		end
		refresh()
	end
end)

Players.PlayerRemoving:Connect(savePlayer)

RemoteFunctions:WaitForChild("GetLeaderboards").OnServerInvoke = function()
	return {
		TopEarned = cachedEarned,
		TopCollection = cachedCollection,
		TopPrestige = cachedPrestige,
		Global = available,
	}
end

return LeaderboardService
