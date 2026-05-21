-- MonsterService.lua (ModuleScript)
-- Cursed artifacts attract monsters. While a player is carrying an artifact on
-- an expedition, monsters spawn and hunt them — reach the extraction pad before
-- one catches you, or you drop the artifact. Monsters are placeholder figures
-- (ModelFactory) swappable for real monster models by asset id.
--
-- Decoupled from ExpeditionService via the Caught BindableEvent (no require
-- cycle): MonsterService fires Caught(player); ExpeditionService listens and
-- drops the carry, then calls StopHunt.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local ModelFactory = require(script.Parent.ModelFactory)

local MonsterService = {}

-- Set to a Roblox model asset id for a real monster model. nil = placeholder.
local MONSTER_MODEL_ID = nil

local MONSTERS_PER_HUNT = 2
local MONSTER_SPEED = 13      -- studs/sec (player walks 16, so it's escapable)
local CATCH_RADIUS = 6
local SPAWN_DISTANCE = 36

-- [player] = { Monsters = { Model }, Caught = bool }
local hunts = {}

-- Fired with (player) when a monster catches them.
MonsterService.Caught = Instance.new("BindableEvent")

local function makeMonster(): Model
	return ModelFactory.Resolve(MONSTER_MODEL_ID, function()
		return ModelFactory.BuildFigure({
			Name = "Monster",
			BodySize = Vector3.new(2.4, 4, 1.4),
			BodyColor = Color3.fromRGB(20, 18, 24),
			HeadColor = Color3.fromRGB(15, 13, 18),
			Material = Enum.Material.SmoothPlastic,
			FaceText = "● ●",
			FaceColor = Color3.fromRGB(255, 40, 40),
			LightColor = Color3.fromRGB(180, 0, 0),
		})
	end)
end

--- Begin hunting `player` from around their current position.
function MonsterService.StartHunt(player: Player)
	if hunts[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local hunt = { Monsters = {}, Caught = false }
	hunts[player] = hunt

	for i = 1, MONSTERS_PER_HUNT do
		local angle = (i / MONSTERS_PER_HUNT) * math.pi * 2 + math.random() * 1.5
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * SPAWN_DISTANCE
		local monster = makeMonster()
		ModelFactory.Place(monster, CFrame.new(hrp.Position + offset))
		monster.Parent = workspace
		table.insert(hunt.Monsters, monster)
	end
end

--- Stop hunting `player` and despawn their monsters.
function MonsterService.StopHunt(player: Player)
	local hunt = hunts[player]
	if not hunt then return end
	for _, monster in ipairs(hunt.Monsters) do
		monster:Destroy()
	end
	hunts[player] = nil
end

-- =============================================
--  HUNT LOOP
-- =============================================
RunService.Heartbeat:Connect(function(dt)
	for player, hunt in pairs(hunts) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		local targetPos = hrp.Position
		for _, monster in ipairs(hunt.Monsters) do
			if monster.Parent then
				local cur = monster:GetPivot().Position
				local toTarget = targetPos - cur
				local dist = toTarget.Magnitude

				if dist <= CATCH_RADIUS then
					if not hunt.Caught then
						hunt.Caught = true
						MonsterService.Caught:Fire(player)
					end
				elseif dist > 0.1 then
					local step = toTarget.Unit * math.min(MONSTER_SPEED * dt, dist)
					local newPos = cur + step
					local lookAt = Vector3.new(targetPos.X, newPos.Y, targetPos.Z)
					ModelFactory.Place(monster, CFrame.lookAt(newPos, lookAt))
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(MonsterService.StopHunt)

return MonsterService
