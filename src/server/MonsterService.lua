-- MonsterService.lua (ModuleScript)
-- Two kinds of threat on expedition maps:
--   * PATROL monsters roam each map and chase any player who gets close — so just
--     being in there is dangerous.
--   * HUNT monsters spawn when you pick up an artifact and converge on you; a more
--     dangerous artifact summons MORE and FASTER hunters.
-- Catching a player drops their carried artifact (via the Caught BindableEvent) and
-- briefly SLOWS them. Monsters are placeholder figures (ModelFactory), swappable.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local ModelFactory = require(script.Parent.ModelFactory)

local MonsterService = {}

local MONSTER_MODEL_ID = nil

local CATCH_RADIUS    = 6
local SPAWN_DISTANCE  = 34
local PATROL_SPEED    = 7    -- wandering
local PATROL_CHASE    = 11   -- chasing (player walks 16, so escapable if you keep moving)
local AGGRO_RANGE     = 38   -- patrol notices you within this
local HUNT_SPEED_BASE = 12
local SLOW_WALKSPEED  = 8
local SLOW_DURATION   = 2.5
local CATCH_COOLDOWN  = 3

-- [player] = { Monsters = { Model }, Speed = n }
local hunts = {}
-- array of { Model, Center = Vector3, HalfX, HalfZ, Target = Vector3 }
local patrols = {}
local catchCooldown = {} -- [player] = true

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

-- Caught: drop the carry (listeners) + slow the player for a moment.
local function catchPlayer(player: Player)
	if catchCooldown[player] then return end
	catchCooldown[player] = true
	MonsterService.Caught:Fire(player)

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = SLOW_WALKSPEED
		task.delay(SLOW_DURATION, function()
			local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if h then h.WalkSpeed = 16 end
		end)
	end
	task.delay(CATCH_COOLDOWN, function()
		catchCooldown[player] = nil
	end)
end

-- Move a monster horizontally toward `targetPos`; returns horizontal distance.
local function chaseStep(monster: Model, targetPos: Vector3, speed: number, dt: number): number
	local cur = monster:GetPivot().Position
	local flat = Vector3.new(targetPos.X - cur.X, 0, targetPos.Z - cur.Z)
	local dist = flat.Magnitude
	if dist > 0.1 then
		local newPos = cur + flat.Unit * math.min(speed * dt, dist)
		ModelFactory.Place(monster, CFrame.lookAt(newPos, newPos + flat.Unit))
	end
	return dist
end

-- =============================================
--  HUNTS (triggered by picking up an artifact)
-- =============================================
function MonsterService.StartHunt(player: Player, danger: number?)
	if hunts[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	danger = danger or 2
	local count = math.clamp(1 + math.floor(danger / 2), 1, 4)
	local speed = math.clamp(HUNT_SPEED_BASE + danger * 0.5, HUNT_SPEED_BASE, 16)

	local hunt = { Monsters = {}, Speed = speed }
	hunts[player] = hunt
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + math.random() * 1.5
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * SPAWN_DISTANCE
		local monster = makeMonster()
		ModelFactory.Place(monster, CFrame.new(hrp.Position + offset))
		monster.Parent = workspace
		table.insert(hunt.Monsters, monster)
	end
end

function MonsterService.StopHunt(player: Player)
	local hunt = hunts[player]
	if not hunt then return end
	for _, monster in ipairs(hunt.Monsters) do
		monster:Destroy()
	end
	hunts[player] = nil
end

-- =============================================
--  PATROLS (always roaming each map)
-- =============================================
local function randomPoint(p): Vector3
	return p.Center + Vector3.new(
		(math.random() * 2 - 1) * (p.HalfX - 8), 0, (math.random() * 2 - 1) * (p.HalfZ - 8))
end

--- Spawn `count` roaming monsters bound to a map region.
function MonsterService.SpawnPatrol(origin: CFrame, halfX: number, halfZ: number, count: number, parent: Instance)
	local center = origin.Position
	for _ = 1, count do
		local monster = makeMonster()
		local entry = { Model = monster, Center = center, HalfX = halfX, HalfZ = halfZ }
		entry.Target = randomPoint(entry)
		ModelFactory.Place(monster, CFrame.new(entry.Target))
		monster.Parent = parent or workspace
		table.insert(patrols, entry)
	end
end

-- Nearest player whose character is inside this patrol's map bounds.
local function nearestInBounds(p): (Player?, Vector3?)
	local center, mx, mz = p.Center, p.HalfX, p.HalfZ
	local monsterPos = p.Model:GetPivot().Position
	local best, bestPos, bestDist
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local pos = hrp.Position
			if math.abs(pos.X - center.X) <= mx and math.abs(pos.Z - center.Z) <= mz then
				local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(monsterPos.X, 0, monsterPos.Z)).Magnitude
				if not bestDist or d < bestDist then
					best, bestPos, bestDist = player, pos, d
				end
			end
		end
	end
	return best, bestPos
end

-- =============================================
--  UPDATE LOOP (hunts + patrols)
-- =============================================
RunService.Heartbeat:Connect(function(dt)
	-- Hunts
	for player, hunt in pairs(hunts) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			for _, monster in ipairs(hunt.Monsters) do
				if monster.Parent then
					local dist = chaseStep(monster, hrp.Position, hunt.Speed, dt)
					if dist <= CATCH_RADIUS then
						catchPlayer(player)
					end
				end
			end
		end
	end

	-- Patrols
	for _, p in ipairs(patrols) do
		if p.Model.Parent then
			local targetPlayer, targetPos = nearestInBounds(p)
			if targetPlayer and targetPos then
				local monsterPos = p.Model:GetPivot().Position
				local flatDist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(monsterPos.X, 0, monsterPos.Z)).Magnitude
				if flatDist <= AGGRO_RANGE then
					if flatDist <= CATCH_RADIUS then
						catchPlayer(targetPlayer)
					else
						chaseStep(p.Model, targetPos, PATROL_CHASE, dt)
					end
					continue
				end
			end
			-- Wander
			local dist = chaseStep(p.Model, p.Target, PATROL_SPEED, dt)
			if dist < 3 then
				p.Target = randomPoint(p)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(MonsterService.StopHunt)

return MonsterService
