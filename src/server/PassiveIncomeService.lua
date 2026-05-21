-- PassiveIncomeService.lua (ModuleScript)
-- Ticks passive income every few seconds for all players.
-- Income math lives in the shared MuseumStats module.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService  = require(script.Parent.DataService)
local MuseumStats  = require(ReplicatedStorage.Shared.MuseumStats)
local Constants    = require(ReplicatedStorage.Shared.Constants)

local IncomeEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("IncomeReceived")

local PassiveIncomeService = {}

-- Main loop
task.spawn(function()
	while true do
		task.wait(Constants.INCOME_TICK_RATE)

		for _, player in ipairs(Players:GetPlayers()) do
			local data = DataService.GetData(player)
			local income = MuseumStats.CalculateIncome(data)
			if income > 0 then
				DataService.UpdateCurrency(player, income)
				IncomeEvent:FireClient(player, income)
			end
		end
	end
end)

return PassiveIncomeService
