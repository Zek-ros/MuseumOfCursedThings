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

--- Return a real model for `assetId` if it loads, else `fallbackFn()`.
-- assetId may be a number or numeric string; nil/0/"" means "use fallback".
function ModelFactory.Resolve(assetId, fallbackFn: () -> Instance): Instance
	local numericId = tonumber(assetId)
	if numericId and numericId > 0 then
		local ok, loaded = pcall(function()
			return InsertService:LoadAsset(numericId)
		end)
		if ok and loaded then
			local model = loaded:FindFirstChildWhichIsA("Model") or loaded
			model.Parent = nil
			return normalize(model)
		end
		-- fall through to fallback on failure
	end
	return normalize(fallbackFn())
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
		billboard.AlwaysOnTop = true
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
