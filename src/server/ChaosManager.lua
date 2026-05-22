-- ChaosManager.lua (ModuleScript)
-- Periodically checks each player's museum danger level and fires
-- chaos events drawn from their displayed artifacts' effect pools.
-- Flavor (banners / data effects) goes through Effects; the physical
-- manifestation goes through ChaosEffects into the player's museum.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService    = require(script.Parent.DataService)
local PedestalService = require(script.Parent.PedestalService)
local VisitorService = require(script.Parent.VisitorService)
local MuseumService  = require(script.Parent.MuseumService)
local ChaosEffects   = require(script.Parent.ChaosEffects)
local ArtifactData   = require(ReplicatedStorage.Shared.ArtifactData)
local Constants      = require(ReplicatedStorage.Shared.Constants)
local MuseumStats    = require(ReplicatedStorage.Shared.MuseumStats)

local ChaosEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ChaosEvent")

local ChaosManager = {}

-- =============================================
--  CHAOS EFFECT IMPLEMENTATIONS (flavor / data)
-- =============================================
-- Each function receives the player and fires the appropriate client event.
-- Effects that modify server state (e.g. StealIncome) do so here;
-- the physical, in-world manifestation is handled by ChaosEffects.

local Effects = {}

Effects.CryingSounds = function(player)
	ChaosEvent:FireClient(player, "CryingSounds", {})
end

Effects.FlickerLights = function(player)
	ChaosEvent:FireClient(player, "FlickerLights", { Duration = 3 })
end

Effects.LaunchProjectile = function(player)
	ChaosEvent:FireClient(player, "LaunchProjectile", {})
end

Effects.ScareVisitors = function(player)
	ChaosEvent:FireClient(player, "ScareVisitors", {})
end

Effects.SpawnClones = function(player)
	ChaosEvent:FireClient(player, "SpawnClones", { Count = 2 })
end

Effects.WhisperNames = function(player)
	ChaosEvent:FireClient(player, "WhisperNames", { Name = player.Name })
end

Effects.Teleport = function(player)
	ChaosEvent:FireClient(player, "Teleport", {})
end

Effects.PredictDisaster = function(player)
	ChaosEvent:FireClient(player, "PredictDisaster", {})
end

Effects.GlitchReality = function(player)
	ChaosEvent:FireClient(player, "GlitchReality", { Duration = 5 })
end

Effects.MoveWhenUnwatched = function(player)
	ChaosEvent:FireClient(player, "MoveWhenUnwatched", {})
end

Effects.StealIncome = function(player)
	local data = DataService.GetData(player)
	if not data then return end
	local tier = MuseumStats.GetDangerTier(MuseumStats.CalculateDanger(data))
	local pct = Constants.CHAOS_THEFT_PCT[tier] or 0.02
	local stolen = math.max(1, math.floor(data.Currency * pct))
	DataService.UpdateCurrency(player, -stolen)
	ChaosEvent:FireClient(player, "StealIncome", { Amount = stolen })
end

Effects.RingDuringChaos = function(player)
	ChaosEvent:FireClient(player, "RingDuringChaos", {})
end

Effects.OverrideContainment = function(player)
	ChaosEvent:FireClient(player, "OverrideContainment", {})
end

Effects.AlterServer = function(player)
	-- This one hits everyone in the server
	ChaosEvent:FireAllClients("AlterServer", { SourcePlayer = player.Name })
end

-- =============================================
--  DANGER HELPERS
-- =============================================

local function gatherPossibleEffects(data): { string }
	local pool = {}
	for _, artifact in ipairs(data.Artifacts) do
		if artifact.IsDisplayed then
			local def = ArtifactData.Artifacts[artifact.ArtifactId]
			if def and def.ChaosEffects then
				for _, effect in ipairs(def.ChaosEffects) do
					table.insert(pool, effect)
				end
			end
		end
	end
	return pool
end

-- A containment breach: knock one displayed artifact off display. Weighted by
-- effective danger (dangerous + poorly-contained artifacts escape more often),
-- so investing in containment genuinely protects your exhibits.
local function breachArtifact(player: Player, data)
	local candidates = {}
	for i, artifact in ipairs(data.Artifacts) do
		if artifact.IsDisplayed then
			local def = ArtifactData.Artifacts[artifact.ArtifactId]
			if def then
				local containment = ArtifactData.ContainmentTypes[artifact.ContainmentType]
				local reduction = containment and containment.DangerReduction or 0
				local weight = math.max(0.5, def.DangerLevel - reduction)
				table.insert(candidates, { Index = i, Def = def, Weight = weight })
			end
		end
	end
	if #candidates == 0 then return end

	local total = 0
	for _, c in ipairs(candidates) do total += c.Weight end
	local roll = math.random() * total
	local picked = candidates[#candidates]
	for _, c in ipairs(candidates) do
		roll -= c.Weight
		if roll <= 0 then picked = c break end
	end

	-- Undisplay it (fires MuseumChanged -> pedestal + UI update + income drop)
	MuseumService.UndisplayArtifact(player, picked.Index)
	ChaosEvent:FireClient(player, "ArtifactEscaped", { Name = picked.Def.Name })
end

-- =============================================
--  MAIN LOOP
-- =============================================

task.spawn(function()
	while true do
		task.wait(Constants.CHAOS_CHECK_RATE)

		for _, player in ipairs(Players:GetPlayers()) do
			local data = DataService.GetData(player)
			if not data or #data.Artifacts == 0 then continue end

			-- Chaos only happens while the player is actually IN their museum
			-- (don't pop chaos banners while they're in the hub / on expeditions).
			local museum = PedestalService.GetMuseum(player)
			if not museum then continue end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			if (hrp.Position - museum.Origin.Position).Magnitude > 70 then continue end

			local score = MuseumStats.CalculateDanger(data)
			local tier = MuseumStats.GetDangerTier(score)
			local chance = Constants.CHAOS_BASE_CHANCE[tier]

			if math.random() < chance then
				local pool = gatherPossibleEffects(data)
				if #pool > 0 then
					local chosen = pool[math.random(#pool)]

					-- Flavor: client banner / data effects (StealIncome, etc.)
					local fn = Effects[chosen]
					if fn then
						pcall(fn, player)
					end

					-- Physical: spawn the real thing inside the museum
					ChaosEffects.Play(chosen, player, museum)

					-- Real visitors panic and scatter when scared
					if chosen == "ScareVisitors" then
						VisitorService.Panic(player)
					end

					-- Real danger: a chance the chaos breaches containment and
					-- knocks an artifact off display (scales with danger tier).
					if math.random() < (Constants.CHAOS_BREACH_CHANCE[tier] or 0) then
						breachArtifact(player, data)
					end

					data.Statistics.ChaosEventsSurvived += 1
				end
			end
		end
	end
end)

return ChaosManager
