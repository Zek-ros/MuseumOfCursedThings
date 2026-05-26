-- AdminService.lua (ModuleScript)
-- Owner-only utilities. Right now: a "/resetprogress" (or "/resetme") chat command
-- that wipes the caller's save AND removes them from the global leaderboards, then
-- kicks them so they rejoin completely fresh. Gated to the game's creator so
-- regular players can never trigger it.
--
-- NOTE: this only resets the LIVE (published) game's data + leaderboards — local
-- Studio testing is memory-only, so there's nothing persistent to reset there.

local Players         = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local DataService        = require(script.Parent.DataService)
local LeaderboardService = require(script.Parent.LeaderboardService)

local AdminService = {}

local resetting = {} -- guard so a player isn't reset twice (e.g. both chat paths fire)

local function isOwner(player: Player): boolean
	return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local function resetPlayer(player: Player)
	if resetting[player] then return end
	resetting[player] = true
	LeaderboardService.RemovePlayer(player)
	DataService.ResetData(player)
	player:Kick("Your progress has been reset. Rejoin to start fresh!")
end

local RESET_ALIASES = { ["/resetprogress"] = true, ["/resetme"] = true }

-- Modern chat (TextChatService — the default).
local cmd = Instance.new("TextChatCommand")
cmd.Name = "ResetProgressCommand"
cmd.PrimaryAlias = "/resetprogress"
cmd.SecondaryAlias = "/resetme"
cmd.Parent = TextChatService
cmd.Triggered:Connect(function(source, _unfiltered)
	local player = Players:GetPlayerByUserId(source.UserId)
	if player and isOwner(player) then
		resetPlayer(player)
	end
end)

-- Legacy chat fallback (in case the experience still uses the old chat system).
local function hookChat(player: Player)
	player.Chatted:Connect(function(message)
		if isOwner(player) and RESET_ALIASES[string.lower(message)] then
			resetPlayer(player)
		end
	end)
end
Players.PlayerAdded:Connect(hookChat)
for _, player in ipairs(Players:GetPlayers()) do
	hookChat(player)
end

Players.PlayerRemoving:Connect(function(player)
	resetting[player] = nil
end)

return AdminService
