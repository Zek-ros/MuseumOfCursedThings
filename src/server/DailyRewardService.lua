-- DailyRewardService.lua (ModuleScript)
-- A daily login reward that scales with a login streak. Persists via the normal
-- save data (DailyReward.LastClaim / Streak), so it only truly resets per day
-- once the place is published; in unpublished Studio it's always claimable.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local MuseumChangedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MuseumChanged")

local DailyRewardService = {}

-- 7-day escalating cycle; day 7 is a jackpot. The streak keeps counting past 7
-- (for bragging + comeback logic) while the payout cycles every week.
local REWARD_TABLE = { 150, 250, 400, 600, 900, 1300, 2500 }
local CYCLE = #REWARD_TABLE
local CLAIM_COOLDOWN = 20 * 3600  -- claimable again after 20 hours
local STREAK_RESET = 48 * 3600    -- miss ~2 days and the streak resets
local COMEBACK_BONUS = 600        -- one-time welcome-back on top when returning from a lapse

local function ensure(data)
	data.DailyReward = data.DailyReward or { LastClaim = 0, Streak = 0 }
	return data.DailyReward
end

local function dayInCycle(streak: number): number
	return ((math.max(streak, 1) - 1) % CYCLE) + 1
end

local function rewardForStreak(streak: number, vip: boolean?): number
	local amount = REWARD_TABLE[dayInCycle(streak)]
	if vip then
		amount = math.floor(amount * 1.5) -- VIP game pass: +50% daily reward
	end
	return amount
end

function DailyRewardService.GetStatus(player: Player)
	local data = DataService.GetData(player)
	if not data then return { Claimable = false } end
	local dr = ensure(data)
	local now = os.time()
	local elapsed = now - (dr.LastClaim or 0)
	local claimable = (dr.LastClaim == 0) or (elapsed >= CLAIM_COOLDOWN)
	-- What the NEXT claim will pay (so the UI can show "come back for X").
	local lapsed = dr.LastClaim ~= 0 and elapsed > STREAK_RESET
	local nextStreak = lapsed and 1 or ((dr.Streak or 0) + 1)
	return {
		Claimable = claimable,
		Streak = dr.Streak or 0,
		Day = dayInCycle(nextStreak),
		NextReward = rewardForStreak(nextStreak, data.VIP),
		Comeback = lapsed,
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

	-- Continue the streak unless they've been away too long (then it restarts).
	local comeback = false
	if dr.LastClaim ~= 0 and elapsed > STREAK_RESET then
		dr.Streak = 0
		comeback = true
	end
	dr.Streak = (dr.Streak or 0) + 1
	dr.LastClaim = now

	local base = rewardForStreak(dr.Streak, data.VIP)
	-- Returning from a lapse pays a comeback bonus so coming back feels good,
	-- not punishing, even though the streak restarts.
	local bonus = 0
	if comeback then
		bonus = data.VIP and math.floor(COMEBACK_BONUS * 1.5) or COMEBACK_BONUS
	end
	local total = base + bonus

	DataService.UpdateCurrency(player, total)
	-- Nudge the client to refresh its currency display
	MuseumChangedEvent:FireClient(player)

	return {
		Granted = true,
		Amount = total,
		ComebackBonus = bonus,
		Streak = dr.Streak,
		Day = dayInCycle(dr.Streak),
		Jackpot = (dayInCycle(dr.Streak) == CYCLE),
	}
end

RemoteFunctions:WaitForChild("GetDailyRewardStatus").OnServerInvoke = function(player)
	return DailyRewardService.GetStatus(player)
end
RemoteFunctions:WaitForChild("ClaimDailyReward").OnServerInvoke = function(player)
	return DailyRewardService.Claim(player)
end

return DailyRewardService
