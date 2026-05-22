-- MonsterService.lua (ModuleScript)
-- Threats on expedition maps. Monsters STALK — they are slow and creepy and
-- never faster than you — rather than punish your movement:
--   * PATROL monsters roam each maze and chase players who get close.
--   * HUNT monsters spawn when you pick up an artifact and converge on you.
-- When a monster catches a player who is CARRYING, it STEALS the artifact and
-- flees into the dark as a glowing THIEF; chase the thief down and tackle it to
-- wrench the artifact back, or it escapes after a while and the loot is lost.
-- Catching an EMPTY-HANDED player does nothing but a fright (no movement penalty).
-- ExpeditionService wires steal/recover/escape to carry state via the OnSteal /
-- OnRecover / OnStealEscape callbacks. Monsters are placeholder figures
-- (ModelFactory), swappable for real models later.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelFactory = require(script.Parent.ModelFactory)
local Constants    = require(ReplicatedStorage.Shared.Constants)

local MonsterService = {}

local MONSTER_MODEL_ID = nil

local CATCH_RADIUS    = 6
local SPAWN_DISTANCE  = 34
local PATROL_SPEED    = 6    -- wandering (a slow stalk)
local PATROL_CHASE    = 9    -- chasing (player walks 16 — always escapable)
local AGGRO_RANGE     = 36   -- patrol notices you within this
local HUNT_SPEED_BASE = 10
local HUNT_SPEED_MAX  = 14
local CATCH_COOLDOWN  = 2

local THIEF_SPEED       = 13 -- flees fast, but a running player (16) can catch up
local THIEF_RECOVER     = 7  -- tackle the thief within this to wrench the loot back
local THIEF_ESCAPE_TIME = 18 -- after this long it gets away and the loot is lost

-- Callbacks set by ExpeditionService (it owns carry/artifact state):
--   OnSteal(player) -> artifactId?, rarity?   (remove + return their carry)
--   OnRecover(player, artifactId, rarity)     (give the carry back)
--   OnStealEscape(player?, artifactId)
MonsterService.OnSteal = nil
MonsterService.OnRecover = nil
MonsterService.OnStealEscape = nil

local hunts = {}         -- [player] = { Monsters = {Model}, Speed }
local patrols = {}       -- array of { Model, Center, HalfX, HalfZ, Target }
local thieves = {}       -- array of { Model, ArtifactId, Rarity, Center, HalfX, HalfZ, Born, Victim, Target }
local mapRegions = {}    -- array of { Center, HalfX, HalfZ }
local catchCooldown = {} -- [player] = true

local function rarityColor(rarity: string?): Color3
	local info = rarity and Constants.RARITY[rarity]
	return (info and info.Color) or Color3.fromRGB(255, 255, 255)
end

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

local function flatDist(a: Vector3, b: Vector3): number
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

local function clampToBounds(pos: Vector3, center: Vector3, hx: number, hz: number): Vector3
	return Vector3.new(
		math.clamp(pos.X, center.X - hx + 4, center.X + hx - 4),
		pos.Y,
		math.clamp(pos.Z, center.Z - hz + 4, center.Z + hz - 4))
end

local function randomPoint(center: Vector3, hx: number, hz: number): Vector3
	return center + Vector3.new((math.random() * 2 - 1) * (hx - 8), 0, (math.random() * 2 - 1) * (hz - 8))
end

-- Which registered map region contains this position (for bounding a thief).
local function regionFor(pos: Vector3)
	for _, r in ipairs(mapRegions) do
		if math.abs(pos.X - r.Center.X) <= r.HalfX and math.abs(pos.Z - r.Center.Z) <= r.HalfZ then
			return r
		end
	end
	return nil
end

-- Nearest player whose character is inside the given region bounds.
local function nearestPlayerInRegion(center: Vector3, hx: number, hz: number, fromPos: Vector3)
	local best, bestPos, bestDist
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local pos = hrp.Position
			if math.abs(pos.X - center.X) <= hx and math.abs(pos.Z - center.Z) <= hz then
				local d = flatDist(pos, fromPos)
				if not bestDist or d < bestDist then
					best, bestPos, bestDist = player, pos, d
				end
			end
		end
	end
	return best, bestPos, bestDist
end

-- =============================================
--  THIEVES (flee with stolen loot)
-- =============================================
local function spawnThief(victim: Player, pos: Vector3, artifactId: string, rarity: string, region)
	if not region then
		-- Nowhere to bound a thief; treat as an immediate escape so the loot is
		-- not silently swallowed.
		if MonsterService.OnStealEscape then
			MonsterService.OnStealEscape(victim, artifactId)
		end
		return
	end

	local monster = makeMonster()
	ModelFactory.Place(monster, CFrame.new(pos))

	-- A glowing loot orb so you can spot (and chase) the thief in the dark.
	local orb = Instance.new("Part")
	orb.Name = "StolenLoot"
	orb.Anchored = true
	orb.CanCollide = false
	orb.Size = Vector3.new(1.6, 1.6, 1.6)
	orb.Material = Enum.Material.Neon
	orb.Color = rarityColor(rarity)
	orb.CFrame = monster:GetPivot() * CFrame.new(0, 3.6, 0)
	local orbLight = Instance.new("PointLight")
	orbLight.Color = orb.Color
	orbLight.Range = 10
	orbLight.Brightness = 2
	orbLight.Parent = orb
	orb.Parent = monster

	monster.Parent = workspace
	table.insert(thieves, {
		Model = monster, ArtifactId = artifactId, Rarity = rarity,
		Center = region.Center, HalfX = region.HalfX, HalfZ = region.HalfZ,
		Born = os.clock(), Victim = victim,
	})
end

-- Caught: steal the carry and flee with it, or — if empty-handed — just a fright.
local function catchPlayer(player: Player, monster: Model?, region)
	if catchCooldown[player] then return end
	catchCooldown[player] = true
	task.delay(CATCH_COOLDOWN, function()
		catchCooldown[player] = nil
	end)

	local artifactId, rarity
	if MonsterService.OnSteal then
		artifactId, rarity = MonsterService.OnSteal(player)
	end
	if not artifactId then
		return -- empty-handed: no penalty, just the scare
	end

	-- They had loot: end the converging hunt, let a thief flee with it.
	MonsterService.StopHunt(player)
	local pos = (monster and monster:GetPivot().Position)
		or (player.Character and player.Character:GetPivot().Position)
	region = region or (pos and regionFor(pos))
	spawnThief(player, pos or Vector3.new(), artifactId, rarity, region)
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
	local speed = math.clamp(HUNT_SPEED_BASE + danger * 0.5, HUNT_SPEED_BASE, HUNT_SPEED_MAX)

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
--- Spawn `count` roaming monsters bound to a map region.
function MonsterService.SpawnPatrol(origin: CFrame, halfX: number, halfZ: number, count: number, parent: Instance)
	local center = origin.Position
	table.insert(mapRegions, { Center = center, HalfX = halfX, HalfZ = halfZ })
	for _ = 1, count do
		local monster = makeMonster()
		local entry = { Model = monster, Center = center, HalfX = halfX, HalfZ = halfZ }
		entry.Target = randomPoint(center, halfX, halfZ)
		ModelFactory.Place(monster, CFrame.new(entry.Target))
		monster.Parent = parent or workspace
		table.insert(patrols, entry)
	end
end

-- =============================================
--  UPDATE LOOP (hunts + patrols + thieves)
-- =============================================
RunService.Heartbeat:Connect(function(dt)
	-- Hunts converge on the carrier
	for player, hunt in pairs(hunts) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			for _, monster in ipairs(hunt.Monsters) do
				if monster.Parent then
					local dist = chaseStep(monster, hrp.Position, hunt.Speed, dt)
					if dist <= CATCH_RADIUS then
						catchPlayer(player, monster, regionFor(hrp.Position))
					end
				end
			end
		end
	end

	-- Patrols roam, and chase anyone who strays too close
	for _, p in ipairs(patrols) do
		if p.Model.Parent then
			local targetPlayer, targetPos = nearestPlayerInRegion(p.Center, p.HalfX, p.HalfZ, p.Model:GetPivot().Position)
			if targetPlayer and targetPos then
				local d = flatDist(targetPos, p.Model:GetPivot().Position)
				if d <= AGGRO_RANGE then
					if d <= CATCH_RADIUS then
						catchPlayer(targetPlayer, p.Model, { Center = p.Center, HalfX = p.HalfX, HalfZ = p.HalfZ })
					else
						chaseStep(p.Model, targetPos, PATROL_CHASE, dt)
					end
					continue
				end
			end
			-- Wander
			local dist = chaseStep(p.Model, p.Target, PATROL_SPEED, dt)
			if dist < 3 then
				p.Target = randomPoint(p.Center, p.HalfX, p.HalfZ)
			end
		end
	end

	-- Thieves flee with stolen loot until caught or escaped
	for i = #thieves, 1, -1 do
		local t = thieves[i]
		if not t.Model.Parent then
			table.remove(thieves, i)
		else
			local tpos = t.Model:GetPivot().Position
			local np, npos = nearestPlayerInRegion(t.Center, t.HalfX, t.HalfZ, tpos)
			local removed = false

			if npos then
				local d = flatDist(npos, tpos)
				if d <= THIEF_RECOVER then
					-- Tackled: give the loot back to whoever caught it.
					if MonsterService.OnRecover and np then
						MonsterService.OnRecover(np, t.ArtifactId, t.Rarity)
					end
					t.Model:Destroy()
					table.remove(thieves, i)
					removed = true
				else
					-- Flee directly away from the nearest player, staying in bounds.
					local away = Vector3.new(tpos.X - npos.X, 0, tpos.Z - npos.Z)
					away = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
					local goal = clampToBounds(tpos + away * 12, t.Center, t.HalfX, t.HalfZ)
					chaseStep(t.Model, goal, THIEF_SPEED, dt)
				end
			else
				-- No one nearby: drift around so it doesn't just stand still.
				t.Target = t.Target or randomPoint(t.Center, t.HalfX, t.HalfZ)
				local d = chaseStep(t.Model, t.Target, PATROL_SPEED, dt)
				if d < 3 then
					t.Target = randomPoint(t.Center, t.HalfX, t.HalfZ)
				end
			end

			if not removed and (os.clock() - t.Born > THIEF_ESCAPE_TIME) then
				if MonsterService.OnStealEscape then
					MonsterService.OnStealEscape(t.Victim, t.ArtifactId)
				end
				t.Model:Destroy()
				table.remove(thieves, i)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	MonsterService.StopHunt(player)
	catchCooldown[player] = nil
end)

return MonsterService
