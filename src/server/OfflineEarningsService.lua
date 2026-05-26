-- OfflineEarningsService.lua (ModuleScript)
-- Retention: when a player rejoins, grant the coins their museum would have
-- earned while they were away (capped, at a reduced rate) and show a
-- "Welcome Back" popup. This is the core return-the-next-day hook for a
-- passive-income game — leaving is rewarding because coming back pays out.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local MuseumStats = require(ReplicatedStorage.Shared.MuseumStats)
local Constants   = require(ReplicatedStorage.Shared.Constants)

local WelcomeBackEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("WelcomeBack")

local OfflineEarningsService = {}

local MAX_AWAY     = 8 * 3600 -- cap accrual at 8 hours (so it stays a nudge, not a jackpot)
local MIN_AWAY     = 60       -- ignore quick rejoins (under a minute)
local OFFLINE_RATE = 0.5      -- earn 50% of the live rate while away (still rewards playing)

local function grantOffline(player: Player)
	-- Wait for DataService to finish loading this player's data.
	local data
	for _ = 1, 100 do
		data = DataService.GetData(player)
		if data then break end
		task.wait(0.1)
	end
	if not data then return end

	local now = os.time()
	local lastSeen = data.LastSeen or 0
	data.LastSeen = now -- consume the away window so it can't be double-counted

	if lastSeen <= 0 then return end -- brand-new player; nothing accrued yet
	local away = math.min(now - lastSeen, MAX_AWAY)
	if away < MIN_AWAY then return end

	-- Per-second rate = per-tick income / tick length, then the offline discount.
	local perSecond = MuseumStats.CalculateIncome(data) / Constants.INCOME_TICK_RATE
	local earned = math.floor(perSecond * away * OFFLINE_RATE)
	if earned <= 0 then return end

	DataService.UpdateCurrency(player, earned)

	-- Give the client a moment to finish loading its UI, then show the payout.
	task.wait(3)
	if player.Parent then
		WelcomeBackEvent:FireClient(player, { Amount = earned, SecondsAway = away })
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(grantOffline, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(grantOffline, player)
end

return OfflineEarningsService
