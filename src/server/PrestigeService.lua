-- PrestigeService.lua (ModuleScript)
-- The endgame rebirth loop. At max museum level + enough coins, a player can
-- Prestige: reset their coins and museum level (keeping artifacts + collection)
-- for a permanent income multiplier. Each prestige makes the next climb faster.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService   = require(script.Parent.DataService)
local MuseumSignals = require(script.Parent.MuseumSignals)
local Constants     = require(ReplicatedStorage.Shared.Constants)
local MuseumStats   = require(ReplicatedStorage.Shared.MuseumStats)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local MuseumChangedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MuseumChanged")

local PrestigeService = {}

local function canPrestige(data): (boolean, string)
	if data.MuseumLevel < Constants.MAX_MUSEUM_LEVEL then
		return false, "Reach max museum level (" .. Constants.MAX_MUSEUM_LEVEL .. ") first"
	end
	local cost = MuseumStats.PrestigeCost(data.Prestige or 0)
	if data.Currency < cost then
		return false, string.format("Need %d coins to prestige", cost)
	end
	return true, "Ready to prestige"
end

function PrestigeService.GetInfo(player: Player)
	local data = DataService.GetData(player)
	if not data then return nil end
	local prestige = data.Prestige or 0
	local ok, reason = canPrestige(data)
	return {
		Prestige = prestige,
		Multiplier = MuseumStats.PrestigeMultiplier(data),
		NextMultiplier = 1 + (prestige + 1) * Constants.PRESTIGE_INCOME_BONUS,
		Cost = MuseumStats.PrestigeCost(prestige),
		MaxMuseumLevel = Constants.MAX_MUSEUM_LEVEL,
		MuseumLevel = data.MuseumLevel,
		CanPrestige = ok,
		Reason = reason,
	}
end

function PrestigeService.Prestige(player: Player)
	local data = DataService.GetData(player)
	if not data then return false, "No data" end

	local ok, reason = canPrestige(data)
	if not ok then return false, reason end

	-- Reset: coins -> starting, museum level -> 1, undisplay everything.
	-- Artifacts owned + collection index are KEPT.
	data.Currency = Constants.STARTING_CURRENCY
	data.MuseumLevel = 1
	for _, artifact in ipairs(data.Artifacts) do
		artifact.IsDisplayed = false
	end
	data.Prestige = (data.Prestige or 0) + 1

	-- Resync world (pedestals shrink, displays clear) + client UI/currency.
	MuseumSignals.MuseumChanged:Fire(player)
	MuseumChangedEvent:FireClient(player)

	return true, "Prestiged to level " .. data.Prestige
end

RemoteFunctions:WaitForChild("GetPrestigeInfo").OnServerInvoke = function(player)
	return PrestigeService.GetInfo(player)
end
RemoteFunctions:WaitForChild("Prestige").OnServerInvoke = function(player)
	return PrestigeService.Prestige(player)
end

return PrestigeService
