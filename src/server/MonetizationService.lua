-- MonetizationService.lua (ModuleScript)
-- Game passes (permanent perks) + developer products (repeatable coin buys) via
-- MarketplaceService. IDs live in shared/MonetizationConfig (all 0 = inert until
-- you create the products in the Creator Dashboard and paste the IDs).
--
-- Pass effect is applied by flipping the data flag named by the pass Key
-- (DoubleIncome / VIP), which MuseumStats reads.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DataService = require(script.Parent.DataService)
local Config = require(ReplicatedStorage.Shared.MonetizationConfig)

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local MuseumChangedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MuseumChanged")

local MonetizationService = {}

-- =============================================
--  GAME PASSES
-- =============================================
local function applyPasses(player: Player)
	local data = DataService.GetData(player)
	if not data then return end
	for _, pass in ipairs(Config.Passes) do
		if (pass.GamePassId or 0) > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.GamePassId)
			end)
			if ok then
				data[pass.Key] = owns
			end
		end
	end
	MuseumChangedEvent:FireClient(player) -- refresh income display
end

local function onPlayerAdded(player: Player)
	-- wait for data to load
	for _ = 1, 60 do
		if DataService.GetData(player) then break end
		task.wait(0.1)
	end
	applyPasses(player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if not purchased then return end
	for _, pass in ipairs(Config.Passes) do
		if pass.GamePassId == gamePassId then
			local data = DataService.GetData(player)
			if data then
				data[pass.Key] = true
				MuseumChangedEvent:FireClient(player)
			end
		end
	end
end)

-- =============================================
--  DEVELOPER PRODUCTS (coins)
-- =============================================
MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		-- Player left; let Roblox retry when they're back.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	for _, product in ipairs(Config.Products) do
		if product.ProductId == receipt.ProductId then
			local data = DataService.GetData(player)
			if data then
				DataService.UpdateCurrency(player, product.Coins)
				MuseumChangedEvent:FireClient(player)
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- =============================================
--  SHOP CATALOG (for the client)
-- =============================================
RemoteFunctions:WaitForChild("GetShop").OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	local passes = {}
	for _, p in ipairs(Config.Passes) do
		table.insert(passes, {
			Key = p.Key,
			Name = p.Name,
			Description = p.Description,
			GamePassId = p.GamePassId,
			Configured = (p.GamePassId or 0) > 0,
			Owned = data ~= nil and data[p.Key] == true,
		})
	end
	local products = {}
	for _, p in ipairs(Config.Products) do
		table.insert(products, {
			Key = p.Key,
			Name = p.Name,
			Description = p.Description,
			ProductId = p.ProductId,
			Coins = p.Coins,
			Configured = (p.ProductId or 0) > 0,
		})
	end
	return { Passes = passes, Products = products }
end

-- =============================================
--  LIFECYCLE
-- =============================================
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

return MonetizationService
