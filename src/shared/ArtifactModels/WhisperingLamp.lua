local function Create()

	local model = Instance.new("Model")
	model.Name = "WhisperingLamp"

	local base = Instance.new("Part")
	base.Size = Vector3.new(2, 0.5, 2)
	base.Material = Enum.Material.Metal
	base.Color = Color3.fromRGB(50, 50, 50)
	base.Anchored = true
	base.Parent = model

	local stand = Instance.new("Part")
	stand.Size = Vector3.new(0.4, 4, 0.4)
	stand.Position = Vector3.new(0, 2, 0)
	stand.Material = Enum.Material.Metal
	stand.Color = Color3.fromRGB(70, 70, 70)
	stand.Anchored = true
	stand.Parent = model

	local shade = Instance.new("Part")
	shade.Shape = Enum.PartType.Cylinder
	shade.Size = Vector3.new(2.5, 2, 2.5)
	shade.Position = Vector3.new(0, 4.5, 0)
	shade.Material = Enum.Material.Fabric
	shade.Color = Color3.fromRGB(255, 240, 180)
	shade.Anchored = true
	shade.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 150)
	light.Range = 15
	light.Brightness = 2
	light.Parent = shade

	-- The base sits at the origin, so center it at the display point.
	model.PrimaryPart = base

	return model

end

return Create
