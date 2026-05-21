-- GameManager.server.lua
-- The single auto-running server Script. Every other server file is a
-- ModuleScript that does its setup work when first required. Requiring
-- them here, in dependency order, boots the whole backend.

local Workspace = game:GetService("Workspace")

print("[Museum of Cursed Things] Server booting...")

-- The default Studio "Baseplate" template part sits at height 0 and z-fights
-- with our museum floors (also at height 0), making the floor flicker. We build
-- our own floors, so remove it. Also clear the template's default spawn so
-- players always spawn at their museum.
local templateBaseplate = Workspace:FindFirstChild("Baseplate")
if templateBaseplate then
	templateBaseplate:Destroy()
end
local templateSpawn = Workspace:FindFirstChild("SpawnLocation")
if templateSpawn and templateSpawn:IsA("SpawnLocation") then
	templateSpawn:Destroy()
end

-- Safety floor FIRST, before any require. Guarantees players never fall into
-- the void even if a service is slow to build their museum (or errors).
if not Workspace:FindFirstChild("SafetyBaseplate") then
	local plate = Instance.new("Part")
	plate.Name = "SafetyBaseplate"
	plate.Anchored = true
	plate.Size = Vector3.new(2048, 2, 2048)
	plate.Position = Vector3.new(0, -3, 0)
	plate.Color = Color3.fromRGB(28, 26, 34)
	plate.Material = Enum.Material.Slate
	plate.TopSurface = Enum.SurfaceType.Smooth
	plate.Parent = Workspace
end

-- DataService first: it owns player data and the join/leave/save hooks.
require(script.Parent.DataService)

-- Services that wire up RemoteFunction handlers.
require(script.Parent.ArtifactService)
require(script.Parent.MuseumService)

-- Builds each player's physical museum and syncs displayed artifacts to it.
require(script.Parent.PedestalService)

-- Spawns wandering NPC visitors scaled to each museum's appeal.
require(script.Parent.VisitorService)

-- Builds the expedition map and runs the go-out-and-collect gameplay.
require(script.Parent.ExpeditionService)

-- First-time onboarding state + completion reward.
require(script.Parent.TutorialService)

-- Background loops (income ticks, chaos events). These depend on DataService.
require(script.Parent.PassiveIncomeService)
require(script.Parent.ChaosManager)

print("[Museum of Cursed Things] Server initialized.")
