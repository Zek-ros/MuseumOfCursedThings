-- ModelFactory.lua (ModuleScript)
-- The model-swap framework. Every visual in the game (artifacts, visitors,
-- monsters) goes through Resolve(), which loads a REAL model by asset id if one
-- is provided, and otherwise builds a procedural placeholder. This means real
-- meshes can be dropped in later just by setting an asset id — no other code
-- changes. Until then, everything uses the (improved) procedural fallbacks.

local InsertService = game:GetService("InsertService")

local ModelFactory = {}

-- Normalize a loaded/created instance so it floats and never collides, and
-- has a usable PrimaryPart.
local function normalize(instance: Instance)
	local primary
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
		primary = instance
	else
		for _, d in ipairs(instance:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				primary = primary or d
			end
		end
		if instance:IsA("Model") and not instance.PrimaryPart and primary then
			instance.PrimaryPart = primary
		end
	end
	return instance
end

-- Asset templates are loaded ONCE and cloned thereafter — frequently-spawned
-- monsters/visitors shouldn't hit InsertService every time. `false` = load failed
-- (so we don't keep retrying a bad/locked id every spawn).
local cache: { [number]: Instance | false } = {}

local function loadTemplate(numericId: number)
	local cached = cache[numericId]
	if cached ~= nil then
		return cached
	end
	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(numericId)
	end)
	if ok and loaded then
		local model = loaded:FindFirstChildWhichIsA("Model") or loaded
		model.Parent = nil
		-- Strip bundled Toolbox scripts: we drive/animate these models ourselves,
		-- and their built-in AI / Animate / teleporter scripts only spam errors
		-- (missing deps, private animation assets, network ownership on anchored parts).
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BaseScript") then
				d:Destroy()
			end
		end
		cache[numericId] = model
		return model
	end
	warn("[ModelFactory] LoadAsset failed for id " .. tostring(numericId) .. " — using placeholder.")
	cache[numericId] = false
	return false
end

--- Return a real model for `assetId` if it loads, else `fallbackFn()`. The result
-- is normalized (anchored + non-colliding) for use as a floating/moving visual
-- (artifacts, monsters, visitors). nil/0/"" means "use fallback".
function ModelFactory.Resolve(assetId, fallbackFn: () -> Instance): Instance
	local numericId = tonumber(assetId)
	if numericId and numericId > 0 then
		local template = loadTemplate(numericId)
		if template then
			return normalize(template:Clone())
		end
		-- load failed → fall through to fallback
	end
	return normalize(fallbackFn())
end

--- Load a real model by asset id for use as a SOLID, grounded prop (pedestals,
-- portals): anchors every part but KEEPS the authored collisions. Returns nil if
-- the asset can't be loaded, so the caller can keep its own procedural fallback.
function ModelFactory.TryLoad(assetId): Instance?
	local numericId = tonumber(assetId)
	if not (numericId and numericId > 0) then
		return nil
	end
	local template = loadTemplate(numericId)
	if not template then
		return nil
	end
	local clone = template:Clone()
	if clone:IsA("BasePart") then
		clone.Anchored = true
	else
		for _, d in ipairs(clone:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		if clone:IsA("Model") and not clone.PrimaryPart then
			clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
		end
	end
	return clone
end

--- Position/orient an instance, whether it's a single Part or a Model.
function ModelFactory.Place(instance: Instance, cframe: CFrame)
	if instance:IsA("Model") then
		instance:PivotTo(cframe)
	elseif instance:IsA("BasePart") then
		instance.CFrame = cframe
	end
end

--- The BasePart to attach lights/labels to (the part itself, or a Model's main part).
function ModelFactory.AnchorPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
end

--- Build a simple body+head humanoid-ish placeholder figure (a Model).
-- opts: BodyColor, HeadColor, BodySize, Material, FaceText, FaceColor, LightColor, Name
function ModelFactory.BuildFigure(opts)
	opts = opts or {}
	local model = Instance.new("Model")
	model.Name = opts.Name or "Figure"

	local bodySize = opts.BodySize or Vector3.new(2, 3.2, 1)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = bodySize
	body.Color = opts.BodyColor or Color3.fromRGB(150, 150, 160)
	body.Material = opts.Material or Enum.Material.SmoothPlastic
	body.CFrame = CFrame.new(0, bodySize.Y / 2, 0)
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Anchored = true
	head.CanCollide = false
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Color = opts.HeadColor or Color3.fromRGB(225, 205, 180)
	head.Material = body.Material
	head.CFrame = body.CFrame * CFrame.new(0, bodySize.Y / 2 + 0.5, 0)
	head.Parent = model

	if opts.FaceText then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 44, 0, 24)
		billboard.StudsOffset = Vector3.new(0, 0, -0.9)
		billboard.AlwaysOnTop = false
		billboard.MaxDistance = 45
		billboard.Adornee = head
		local face = Instance.new("TextLabel")
		face.Size = UDim2.fromScale(1, 1)
		face.BackgroundTransparency = 1
		face.Text = opts.FaceText
		face.TextColor3 = opts.FaceColor or Color3.fromRGB(40, 40, 40)
		face.Font = Enum.Font.GothamBold
		face.TextScaled = true
		face.Parent = billboard
		billboard.Parent = head
	end

	if opts.LightColor then
		local light = Instance.new("PointLight")
		light.Color = opts.LightColor
		light.Brightness = 2
		light.Range = 10
		light.Parent = body
	end

	model.PrimaryPart = body
	return model
end

return ModelFactory
