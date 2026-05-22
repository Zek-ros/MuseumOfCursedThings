-- ChaosEffects.lua (ModuleScript)
-- The PHYSICAL side of chaos. ChaosManager decides when/which effect fires;
-- this module spawns the actual objects inside the player's museum, so anyone
-- standing there (the owner or a visitor) sees the same chaos.
--
-- Effects parent everything under museum.Model, so they're auto-cleaned when
-- the museum is destroyed. Debris handles short-lived props.
-- (Audio is intentionally omitted for now — add Sounds with SoundIds later.)

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local MuseumBuilder = require(script.Parent.MuseumBuilder)

local ChaosEffects = {}

-- =============================================
--  SHARED HELPERS
-- =============================================

-- A random CFrame somewhere inside the room, `yOffset` studs above the floor.
local function randomRoomCFrame(museum, yOffset: number?): CFrame
	local hx = (MuseumBuilder.ROOM_X / 2) - 6
	local hz = (MuseumBuilder.ROOM_Z / 2) - 6
	local x = (math.random() * 2 - 1) * hx
	local z = (math.random() * 2 - 1) * hz
	return museum.Origin * CFrame.new(x, yOffset or 0, z)
end

-- A floating text label that rises and fades, then cleans itself up.
local function floatingLabel(museum, cframe: CFrame, text: string, color: Color3, lifetime: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = cframe

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 240, 0, 50)
	billboard.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard
	billboard.Parent = anchor
	anchor.Parent = museum.Model

	TweenService:Create(anchor, TweenInfo.new(lifetime), { CFrame = cframe * CFrame.new(0, 6, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(lifetime), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, lifetime + 0.2)
end

-- Collect every PointLight in the museum (ceiling + artifact glows).
local function museumLights(museum)
	local lights = {}
	for _, descendant in ipairs(museum.Model:GetDescendants()) do
		if descendant:IsA("PointLight") then
			table.insert(lights, descendant)
		end
	end
	return lights
end

-- =============================================
--  ANGRY TOASTER: fling a burning piece of toast across the room
-- =============================================
local function launchToast(_player, museum)
	local startCF = museum.Origin * CFrame.new(
		(math.random() * 2 - 1) * 20,
		6,
		-(MuseumBuilder.ROOM_Z / 2) + 5
	)

	local toast = Instance.new("Part")
	toast.Name = "BurningToast"
	toast.Size = Vector3.new(1.8, 0.5, 1.3)
	toast.Color = Color3.fromRGB(150, 100, 50)
	toast.Material = Enum.Material.Wood
	toast.CFrame = startCF
	toast.CanCollide = true

	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 8
	fire.Color = Color3.fromRGB(255, 140, 40)
	fire.SecondaryColor = Color3.fromRGB(120, 30, 0)
	fire.Parent = toast

	toast.Parent = museum.Model

	local vx = (math.random() * 2 - 1) * 12
	toast.AssemblyLinearVelocity = museum.Origin:VectorToWorldSpace(Vector3.new(vx, 28, 42))
	toast.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))

	Debris:AddItem(toast, 5)
end

-- =============================================
--  TELEPORTING CONE: one persistent cone that jumps to a new spot
-- =============================================
local function teleportCone(_player, museum)
	local cone = museum.ChaosCone
	if not cone or not cone.Parent then
		cone = Instance.new("Part")
		cone.Name = "TeleportingCone"
		cone.Anchored = true
		cone.CanCollide = false
		cone.Size = Vector3.new(2.5, 4, 2.5)
		cone.Color = Color3.fromRGB(255, 120, 20)
		cone.Material = Enum.Material.Neon

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 80, 0, 80)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = false
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "🚧"
		label.TextScaled = true
		label.Parent = billboard
		billboard.Parent = cone

		cone.Parent = museum.Model
		museum.ChaosCone = cone
	end

	-- Smoke poof at the old location
	local puff = Instance.new("Part")
	puff.Anchored = true
	puff.CanCollide = false
	puff.Transparency = 1
	puff.Size = Vector3.new(1, 1, 1)
	puff.CFrame = CFrame.new(cone.Position)
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(200, 200, 200)
	smoke.Parent = puff
	puff.Parent = museum.Model
	Debris:AddItem(puff, 1.5)

	cone.CFrame = randomRoomCFrame(museum, 2)
end

-- =============================================
--  DIMENSIONAL MIRROR / INFINITE HAMSTER: fading shadow figures
-- =============================================
local function spawnShadows(_player, museum)
	for _ = 1, 2 do
		local figure = Instance.new("Part")
		figure.Name = "ShadowFigure"
		figure.Anchored = true
		figure.CanCollide = false
		figure.Size = Vector3.new(2, 5.5, 1)
		figure.Color = Color3.fromRGB(8, 8, 12)
		figure.Material = Enum.Material.SmoothPlastic
		figure.Transparency = 0.15
		figure.CFrame = randomRoomCFrame(museum, 2.75)

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 60, 0, 24)
		billboard.StudsOffset = Vector3.new(0, 2.4, 0)
		billboard.AlwaysOnTop = false
		local eyes = Instance.new("TextLabel")
		eyes.Size = UDim2.fromScale(1, 1)
		eyes.BackgroundTransparency = 1
		eyes.Text = "● ●"
		eyes.TextColor3 = Color3.fromRGB(255, 40, 40)
		eyes.Font = Enum.Font.GothamBold
		eyes.TextScaled = true
		eyes.Parent = billboard
		billboard.Parent = figure

		figure.Parent = museum.Model

		task.delay(4, function()
			if figure.Parent then
				TweenService:Create(figure, TweenInfo.new(1.5), { Transparency = 1 }):Play()
			end
		end)
		Debris:AddItem(figure, 6)
	end
end

-- =============================================
--  FLICKER LIGHTS: physically flicker the museum's own lights
-- =============================================
local function flickerLights(_player, museum)
	task.spawn(function()
		local lights = museumLights(museum)
		local elapsed = 0
		while elapsed < 2.4 do
			for _, light in ipairs(lights) do
				if light.Parent then
					light.Enabled = math.random() > 0.45
				end
			end
			task.wait(0.13)
			elapsed += 0.13
		end
		for _, light in ipairs(lights) do
			if light.Parent then
				light.Enabled = true
			end
		end
	end)
end

-- =============================================
--  WHISPERING LAMP: ghostly floating whispers of the owner's name
-- =============================================
local function whisperNames(player, museum)
	for i = 1, 3 do
		local cf = randomRoomCFrame(museum, math.random(3, 8))
		task.delay((i - 1) * 0.4, function()
			floatingLabel(museum, cf, "...  " .. player.Name .. "  ...", Color3.fromRGB(200, 200, 255), 2.5)
		end)
	end
end

-- =============================================
--  WEEPING MUG: falling tears + a sad face
-- =============================================
local function cryingTears(_player, museum)
	local cf = randomRoomCFrame(museum, 7)
	floatingLabel(museum, cf, "😢", Color3.fromRGB(150, 180, 255), 2)
	for _ = 1, 6 do
		local tear = Instance.new("Part")
		tear.Shape = Enum.PartType.Ball
		tear.Size = Vector3.new(0.4, 0.4, 0.4)
		tear.Color = Color3.fromRGB(120, 170, 255)
		tear.Material = Enum.Material.Glass
		tear.Transparency = 0.2
		tear.CanCollide = false
		tear.CFrame = cf * CFrame.new((math.random() * 2 - 1) * 1.5, -1, (math.random() * 2 - 1) * 1.5)
		tear.Parent = museum.Model
		tear.AssemblyLinearVelocity = Vector3.new(0, -2, 0)
		Debris:AddItem(tear, 3)
	end
end

-- =============================================
--  SCARE VISITORS: temporary visitors that panic and flee
-- =============================================
local function scareVisitors(_player, museum)
	for _ = 1, 3 do
		local visitor = Instance.new("Part")
		visitor.Name = "FleeingVisitor"
		visitor.Anchored = true
		visitor.CanCollide = false
		visitor.Size = Vector3.new(2, 4, 1)
		visitor.Color = Color3.fromRGB(200, 180, 160)
		visitor.Material = Enum.Material.SmoothPlastic
		visitor.CFrame = randomRoomCFrame(museum, 2)

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 40, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 2.6, 0)
		billboard.AlwaysOnTop = false
		local mark = Instance.new("TextLabel")
		mark.Size = UDim2.fromScale(1, 1)
		mark.BackgroundTransparency = 1
		mark.Text = "❗"
		mark.TextColor3 = Color3.fromRGB(255, 80, 80)
		mark.TextScaled = true
		mark.Parent = billboard
		billboard.Parent = visitor

		visitor.Parent = museum.Model

		-- Bolt for the front of the room
		local fleeCF = museum.Origin * CFrame.new((math.random() * 2 - 1) * 15, 2, (MuseumBuilder.ROOM_Z / 2) - 4)
		TweenService:Create(visitor, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { CFrame = fleeCF }):Play()
		Debris:AddItem(visitor, 1.6)
	end
end

-- =============================================
--  MEAT COMPUTER: ominous disaster warning + pulsing red light
-- =============================================
local function predictDisaster(_player, museum)
	local cf = museum.Origin * CFrame.new(0, 8, 0)
	floatingLabel(museum, cf, "⚠ DISASTER INCOMING ⚠", Color3.fromRGB(255, 60, 60), 4)

	local lamp = Instance.new("Part")
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.Transparency = 1
	lamp.Size = Vector3.new(1, 1, 1)
	lamp.CFrame = cf
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 30, 30)
	light.Range = 40
	light.Brightness = 4
	light.Parent = lamp
	lamp.Parent = museum.Model

	task.spawn(function()
		for _ = 1, 8 do
			light.Enabled = not light.Enabled
			task.wait(0.25)
		end
	end)
	Debris:AddItem(lamp, 4)
end

-- =============================================
--  GLITCH REALITY: a burst of flickering neon shards
-- =============================================
local function glitchReality(_player, museum)
	for _ = 1, 10 do
		local shard = Instance.new("Part")
		shard.Anchored = true
		shard.CanCollide = false
		shard.Size = Vector3.new(math.random(1, 4), math.random(1, 4), math.random(1, 4))
		shard.Material = Enum.Material.Neon
		shard.Color = Color3.fromHSV(math.random(), 1, 1)
		shard.CFrame = randomRoomCFrame(museum, math.random(2, 12))
			* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		shard.Parent = museum.Model
		Debris:AddItem(shard, 1.5)
	end
end

-- =============================================
--  CURSED MANNEQUIN: a figure that silently relocates when chaos hits
-- =============================================
local function moveMannequin(_player, museum)
	local mannequin = museum.ChaosMannequin
	if not mannequin or not mannequin.Parent then
		mannequin = Instance.new("Part")
		mannequin.Name = "CursedMannequin"
		mannequin.Anchored = true
		mannequin.CanCollide = false
		mannequin.Size = Vector3.new(2, 5, 1)
		mannequin.Color = Color3.fromRGB(220, 215, 205)
		mannequin.Material = Enum.Material.SmoothPlastic

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 50, 0, 24)
		billboard.StudsOffset = Vector3.new(0, 2.7, 0)
		billboard.AlwaysOnTop = false
		local face = Instance.new("TextLabel")
		face.Size = UDim2.fromScale(1, 1)
		face.BackgroundTransparency = 1
		face.Text = "•_•"
		face.TextColor3 = Color3.fromRGB(40, 40, 40)
		face.Font = Enum.Font.GothamBold
		face.TextScaled = true
		face.Parent = billboard
		billboard.Parent = mannequin

		mannequin.Parent = museum.Model
		museum.ChaosMannequin = mannequin
	end

	-- No smoke, no sound — it's just suddenly somewhere else.
	mannequin.CFrame = randomRoomCFrame(museum, 2.5)
end

-- =============================================
--  KING'S COIN: a stolen gold coin flies up and away
--  (the actual currency deduction happens in ChaosManager)
-- =============================================
local function stealCoin(_player, museum)
	local coin = Instance.new("Part")
	coin.Name = "StolenCoin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.3, 2, 2)
	coin.Color = Color3.fromRGB(255, 215, 0)
	coin.Material = Enum.Material.Metal
	coin.CanCollide = false
	coin.CFrame = randomRoomCFrame(museum, 3) * CFrame.Angles(0, 0, math.rad(90))
	coin.Parent = museum.Model
	coin.AssemblyLinearVelocity = Vector3.new(math.random(-5, 5), 25, math.random(-5, 5))
	coin.AssemblyAngularVelocity = Vector3.new(0, 30, 0)
	Debris:AddItem(coin, 2)
end

-- =============================================
--  TEETH PHONE: a jittering phone "ringing"
-- =============================================
local function ringPhone(_player, museum)
	local cf = randomRoomCFrame(museum, 4)
	floatingLabel(museum, cf, "📞 RING RING", Color3.fromRGB(255, 255, 150), 2.5)

	local phone = Instance.new("Part")
	phone.Name = "TeethPhone"
	phone.Anchored = true
	phone.CanCollide = false
	phone.Size = Vector3.new(1, 0.4, 2)
	phone.Color = Color3.fromRGB(20, 20, 20)
	phone.CFrame = cf * CFrame.new(0, -1, 0)
	phone.Parent = museum.Model

	task.spawn(function()
		local base = phone.CFrame
		for _ = 1, 14 do
			if not phone.Parent then break end
			phone.CFrame = base * CFrame.new((math.random() * 2 - 1) * 0.15, 0, (math.random() * 2 - 1) * 0.15)
			task.wait(0.08)
		end
	end)
	Debris:AddItem(phone, 2.5)
end

-- =============================================
--  CONTAINMENT BREACH: red alarm flashing across all museum lights
-- =============================================
local function containmentBreach(_player, museum)
	floatingLabel(museum, museum.Origin * CFrame.new(0, 8, 0), "⚠ CONTAINMENT BREACH ⚠", Color3.fromRGB(255, 40, 40), 3)

	task.spawn(function()
		local saved = {}
		for _, light in ipairs(museumLights(museum)) do
			table.insert(saved, { light = light, color = light.Color })
		end
		for _ = 1, 6 do
			for _, entry in ipairs(saved) do
				if entry.light.Parent then entry.light.Color = Color3.fromRGB(255, 0, 0) end
			end
			task.wait(0.2)
			for _, entry in ipairs(saved) do
				if entry.light.Parent then entry.light.Color = entry.color end
			end
			task.wait(0.2)
		end
	end)
end

-- =============================================
--  DIMENSIONAL MIRROR: a growing purple rift (server-wide banner elsewhere)
-- =============================================
local function alterServer(_player, museum)
	local portal = Instance.new("Part")
	portal.Name = "DimensionalRift"
	portal.Shape = Enum.PartType.Ball
	portal.Anchored = true
	portal.CanCollide = false
	portal.Material = Enum.Material.Neon
	portal.Color = Color3.fromRGB(180, 60, 255)
	portal.Transparency = 0.2
	portal.Size = Vector3.new(1, 1, 1)
	portal.CFrame = museum.Origin * CFrame.new(0, 8, 0)

	local light = Instance.new("PointLight")
	light.Color = portal.Color
	light.Range = 50
	light.Brightness = 5
	light.Parent = portal
	portal.Parent = museum.Model

	TweenService:Create(portal, TweenInfo.new(2.5), {
		Size = Vector3.new(20, 20, 20),
		Transparency = 1,
	}):Play()
	Debris:AddItem(portal, 3)
end

-- =============================================
--  DISPATCH
-- =============================================
local PhysicalEffects = {
	LaunchProjectile    = launchToast,
	Teleport            = teleportCone,
	SpawnClones         = spawnShadows,
	FlickerLights       = flickerLights,
	WhisperNames        = whisperNames,
	CryingSounds        = cryingTears,
	ScareVisitors       = scareVisitors,
	PredictDisaster     = predictDisaster,
	GlitchReality       = glitchReality,
	MoveWhenUnwatched   = moveMannequin,
	StealIncome         = stealCoin,
	RingDuringChaos     = ringPhone,
	OverrideContainment = containmentBreach,
	AlterServer         = alterServer,
}

--- Spawn the physical manifestation of `effectName` in `museum`, if one exists.
function ChaosEffects.Play(effectName: string, player: Player, museum)
	local impl = PhysicalEffects[effectName]
	if not impl then return end
	local ok, err = pcall(impl, player, museum)
	if not ok then
		warn("[ChaosEffects] " .. effectName .. " failed: " .. tostring(err))
	end
end

return ChaosEffects
