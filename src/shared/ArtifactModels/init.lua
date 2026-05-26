-- ArtifactModels (ModuleScript folder, shared)
-- ==========================================================================
--  ARTIFACT "OBJECT BUILDING SCRIPTS" LIVE HERE — one ModuleScript per artifact.
-- ==========================================================================
-- To add a model: drop a ModuleScript into this folder (src/shared/ArtifactModels/)
-- named EXACTLY after the artifact id (the key in ArtifactData.Artifacts, e.g.
-- "WhisperingLamp.lua") that RETURNS a builder function:
--
--     local function Create()
--         local model = Instance.new("Model")
--         ... build parts ...
--         return model
--     end
--     return Create
--
-- The builder returns ONE unparented Model (or BasePart), built around the
-- origin (0, 0, 0). The same model is used for BOTH that artifact's museum
-- exhibit and its expedition pickup. You do NOT need to add a name label or set
-- Anchored / CanCollide — that's handled for you (your own PointLights,
-- materials, shapes, etc. are kept as-is). Set `model.PrimaryPart` to the part
-- that should sit at the display point; otherwise the first part is used.
--
-- Any artifact WITHOUT a module here keeps the neon-cube placeholder, so you can
-- add them one at a time. This loader auto-registers every child module by name.
--
-- Valid ids: WhisperingLamp, BlinkingFrame, TeleportingCone, AngryToaster,
-- TeethPhone, WeepingMug, CursedMannequin, KingsCoin, InfiniteHamster,
-- MeatComputer, DimensionalMirror, SingingDoorknob, StickyNoteOfDoom,
-- MelancholyHouseplant, ScreamingAlarmClock, PossessedRoomba, HauntedUmbrella,
-- PossessedTelevision, CursedMusicBox, BitingStapler, GravityOrb,
-- WhisperingWallpaper, EternalCandle, HungryDoor, ClockworkHeart
-- ==========================================================================

local ArtifactModels = {}

for _, child in ipairs(script:GetChildren()) do
	if child:IsA("ModuleScript") then
		local ok, result = pcall(require, child)
		if not ok then
			warn("[ArtifactModels] '" .. child.Name .. "' errored while loading: " .. tostring(result))
		elseif type(result) == "function" then
			ArtifactModels[child.Name] = result
		elseif typeof(result) == "Instance" then
			-- Common mistake: returning Create() (a Model) instead of Create (the function).
			warn("[ArtifactModels] '" .. child.Name .. "' returned an Instance — return the Create FUNCTION, not Create().")
		end
		-- Anything else (e.g. a "TODO" stub) is silently skipped: that artifact
		-- just keeps the neon-cube placeholder until a real builder is added.
	end
end

-- Real 3D models OVERRIDE the code builders. Save an imported .glb as
-- "<ArtifactId>.rbxmx" into src/shared/ArtifactMeshes and it's auto-used for
-- that artifact's museum exhibit AND its maze pickup — no code needed.
local meshFolder = script.Parent:FindFirstChild("ArtifactMeshes")
if meshFolder then
	for _, model in ipairs(meshFolder:GetChildren()) do
		if model:IsA("Model") or model:IsA("BasePart") then
			ArtifactModels[model.Name] = function()
				return model:Clone()
			end
		end
	end
end

return ArtifactModels
