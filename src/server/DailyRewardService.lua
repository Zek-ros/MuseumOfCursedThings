-- DailyRewardService.lua (ModuleScript)
-- A daily login reward that scales with a login streak. Persists via the normal
-- save data (DailyReward.LastClaim / Streak), so it only truly resets per day
-- once the place is published; in unpublished Studio it's always claimable.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local MuseumChangedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MuseumChanged")

local DailyRewardService = {}

local BASE_REWARD = 200
local MAX_STREAK = 7              -- reward caps at BASE * 7
local CLAIM_COOLDOWN = 20 * 3600  -- claimable again after 20 hours
local STREAK_RESET = 48 * 3600    -- miss ~2 days and the streak resets

local function ensure(data)
	data.DailyReward = data.DailyReward or { LastClaim = 0, Streak = 0 }
	return data.DailyReward
end

function DailyRewardService.GetStatus(player: Player)
	local data = DataService.GetData(player)
	if not data then return { Claimable = false } end
	local dr = ensure(data)
	local now = os.time()
	local elapsed = now - (dr.LastClaim or 0)
	local claimable = (dr.LastClaim == 0) or (elapsed >= CLAIM_COOLDOWN)
	return {
		Claimable = claimable,
		Streak = dr.Streak or 0,
		SecondsUntilNext = claimable and 0 or math.max(0, CLAIM_COOLDOWN - elapsed),
	}
end

function DailyRewardService.Claim(player: Player)
	local data = DataService.GetData(player)
	if not data then return { Granted = false } end
	local dr = ensure(data)
	local now = os.time()
	local elapsed = now - (dr.LastClaim or 0)

	if dr.LastClaim ~= 0 and elapsed < CLAIM_COOLDOWN then
		return { Granted = false, Reason = "Not ready yet" }
	end

	-- Continue the streak unless they've been away too long
	if dr.LastClaim ~= 0 and elapsed > STREAK_RESET then
		dr.Streak = 0
	end
	dr.Streak = math.min((dr.Streak or 0) + 1, MAX_STREAK)
	dr.LastClaim = now

	local amount = BASE_REWARD * dr.Streak
	if data.VIP then
		amount = math.floor(amount * 1.5) -- VIP game pass: +50% daily reward
	end
	DataService.UpdateCurrency(player, amount)
	-- Nudge the client to refresh its currency display
	MuseumChangedEvent:FireClient(player)

	return { Granted = true, Amount = amount, Streak = dr.Streak }
end

RemoteFunctions:WaitForChild("GetDailyRewardStatus").OnServerInvoke = function(player)
	return DailyRewardService.GetStatus(player)
end
RemoteFunctions:WaitForChild("ClaimDailyReward").OnServerInvoke = function(player)
	return DailyRewardService.Claim(player)
end

return DailyRewardService
