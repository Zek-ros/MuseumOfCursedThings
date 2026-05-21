-- ArtifactService.lua (ModuleScript)
-- Handles artifact rolling, granting, and expedition rewards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService    = require(script.Parent.DataService)
local ArtifactData   = require(ReplicatedStorage.Shared.ArtifactData)
local Constants      = require(ReplicatedStorage.Shared.Constants)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local ArtifactService = {}

-- =============================================
--  RARITY ROLLING
-- =============================================

-- Pre-build a weighted pool so rolling is O(1)
local rarityPool = {}
do
	for rarityName, info in pairs(Constants.RARITY) do
		for _ = 1, info.Weight do
			table.insert(rarityPool, rarityName)
		end
	end
end

local function rollRarity(): string
	return rarityPool[math.random(#rarityPool)]
end

local function getArtifactsByRarity(rarity: string): { string }
	local results = {}
	for id, def in pairs(ArtifactData.Artifacts) do
		if def.Rarity == rarity then
			table.insert(results, id)
		end
	end
	return results
end

--- Roll a random artifact id + rarity string.
local function rollArtifact(): (string?, string?)
	local rarity = rollRarity()
	local candidates = getArtifactsByRarity(rarity)

	-- If no artifacts exist at this rarity, fall back to Common
	if #candidates == 0 then
		candidates = getArtifactsByRarity("Common")
	end
	if #candidates == 0 then
		return nil, nil
	end

	return candidates[math.random(#candidates)], rarity
end

-- =============================================
--  PUBLIC API
-- =============================================

--- Grant a specific artifact to a player.
function ArtifactService.GrantArtifact(player: Player, artifactId: string): boolean
	local def = ArtifactData.Artifacts[artifactId]
	if not def then
		warn("[ArtifactService] Unknown artifact: " .. tostring(artifactId))
		return false
	end

	DataService.AddArtifact(player, artifactId, "GlassCase")
	-- Reward currency for the extraction itself
	DataService.UpdateCurrency(player, def.Value)
	return true
end

--- Roll a random artifact and grant it. Returns artifactId, rarity or nil.
function ArtifactService.GrantRandomArtifact(player: Player): (string?, string?)
	local artifactId, rarity = rollArtifact()
	if not artifactId then return nil, nil end

	ArtifactService.GrantArtifact(player, artifactId)
	return artifactId, rarity
end

--- Roll a random artifact WITHOUT granting it. Returns artifactId, rarity.
-- Used by ExpeditionService to populate collectible pickups on the map.
function ArtifactService.RollArtifact(): (string?, string?)
	return rollArtifact()
end

-- =============================================
--  REMOTES
-- =============================================

-- Let the client look up static artifact definitions for UI
RemoteFunctions:WaitForChild("GetArtifactData").OnServerInvoke = function(_player, artifactId)
	return ArtifactData.Artifacts[artifactId]
end

-- MVP: simulate an expedition completion from the client
-- (In production this would be validated by server-side expedition logic.)
RemoteFunctions:WaitForChild("CompleteExpedition").OnServerInvoke = function(player)
	local artifactId, rarity = ArtifactService.GrantRandomArtifact(player)
	if artifactId then
		local def = ArtifactData.Artifacts[artifactId]
		return {
			ArtifactId = artifactId,
			Name = def.Name,
			Rarity = rarity,
			Value = def.Value,
		}
	end
	return nil
end

return ArtifactService
