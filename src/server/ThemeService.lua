-- ThemeService.lua (ModuleScript)
-- Buyable museum themes: a coin sink + customization layer on top of the level
-- system. A theme re-skins the room's structural parts (floor, walls, ceiling,
-- trim, carpet) and the ceiling light color. Buying unlocks + applies it; owned
-- themes can be re-applied for free. The choice persists and is re-applied on join.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService     = require(script.Parent.DataService)
local PedestalService = require(script.Parent.PedestalService)

local RemoteFunctions    = ReplicatedStorage:WaitForChild("RemoteFunctions")
local MuseumChangedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MuseumChanged")

local ThemeService = {}

-- Display order for the UI.
local THEME_ORDER = { "Default", "Marble", "Gothic", "Neon", "Gilded" }

-- Each part spec is { Color = Color3, Material = Enum.Material }. Light is a Color3.
local THEMES = {
	Default = {
		Name = "Classic Slate", Cost = 0,
		Floor   = { Color = Color3.fromRGB(52, 48, 62),  Material = Enum.Material.Marble },
		Wall    = { Color = Color3.fromRGB(36, 33, 46),  Material = Enum.Material.Concrete },
		Ceiling = { Color = Color3.fromRGB(36, 33, 46),  Material = Enum.Material.Concrete },
		Trim    = { Color = Color3.fromRGB(150, 132, 96), Material = Enum.Material.Marble },
		Carpet  = { Color = Color3.fromRGB(96, 26, 34),  Material = Enum.Material.Fabric },
		Light = Color3.fromRGB(255, 236, 200),
	},
	Marble = {
		Name = "Grand Marble", Cost = 3000,
		Floor   = { Color = Color3.fromRGB(228, 224, 214), Material = Enum.Material.Marble },
		Wall    = { Color = Color3.fromRGB(206, 202, 194), Material = Enum.Material.Marble },
		Ceiling = { Color = Color3.fromRGB(196, 192, 184), Material = Enum.Material.Marble },
		Trim    = { Color = Color3.fromRGB(184, 158, 104), Material = Enum.Material.Metal },
		Carpet  = { Color = Color3.fromRGB(120, 32, 40),  Material = Enum.Material.Fabric },
		Light = Color3.fromRGB(255, 247, 228),
	},
	Gothic = {
		Name = "Gothic Crypt", Cost = 10000,
		Floor   = { Color = Color3.fromRGB(42, 40, 46),  Material = Enum.Material.Slate },
		Wall    = { Color = Color3.fromRGB(30, 28, 34),  Material = Enum.Material.Cobblestone },
		Ceiling = { Color = Color3.fromRGB(24, 22, 28),  Material = Enum.Material.Cobblestone },
		Trim    = { Color = Color3.fromRGB(96, 90, 76),  Material = Enum.Material.Slate },
		Carpet  = { Color = Color3.fromRGB(58, 14, 18),  Material = Enum.Material.Fabric },
		Light = Color3.fromRGB(172, 166, 206),
	},
	Neon = {
		Name = "Cursed Neon", Cost = 30000,
		Floor   = { Color = Color3.fromRGB(18, 18, 28),  Material = Enum.Material.SmoothPlastic },
		Wall    = { Color = Color3.fromRGB(24, 20, 38),  Material = Enum.Material.SmoothPlastic },
		Ceiling = { Color = Color3.fromRGB(14, 12, 24),  Material = Enum.Material.SmoothPlastic },
		Trim    = { Color = Color3.fromRGB(150, 80, 240), Material = Enum.Material.Neon },
		Carpet  = { Color = Color3.fromRGB(60, 16, 84),  Material = Enum.Material.Neon },
		Light = Color3.fromRGB(150, 90, 255),
	},
	Gilded = {
		Name = "Gilded Hall", Cost = 80000,
		Floor   = { Color = Color3.fromRGB(64, 54, 32),  Material = Enum.Material.Marble },
		Wall    = { Color = Color3.fromRGB(52, 44, 28),  Material = Enum.Material.Marble },
		Ceiling = { Color = Color3.fromRGB(44, 37, 24),  Material = Enum.Material.Marble },
		Trim    = { Color = Color3.fromRGB(214, 176, 82), Material = Enum.Material.Neon },
		Carpet  = { Color = Color3.fromRGB(122, 30, 38), Material = Enum.Material.Fabric },
		Light = Color3.fromRGB(255, 228, 165),
	},
}

local function ensure(data)
	data.MuseumTheme = data.MuseumTheme or "Default"
	data.OwnedThemes = data.OwnedThemes or {}
	data.OwnedThemes.Default = true -- the starter theme is always owned
	return data
end

local function paint(part: BasePart, spec)
	part.Color = spec.Color
	if spec.Material then
		part.Material = spec.Material
	end
end

-- Re-skin the room structural parts to the theme (matched by the names
-- MuseumBuilder gives them). Pedestals, exhibits, decor and visitors are untouched.
local function apply(player: Player, themeId: string)
	local museum = PedestalService.GetMuseum(player)
	if not museum or not museum.Model then return end
	local t = THEMES[themeId] or THEMES.Default
	for _, p in ipairs(museum.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			local n = p.Name
			if n == "Floor" then
				paint(p, t.Floor)
			elseif n == "Ceiling" then
				paint(p, t.Ceiling)
			elseif string.sub(n, 1, 4) == "Wall" then
				paint(p, t.Wall)
			elseif n == "Trim" then
				paint(p, t.Trim)
			elseif n == "Carpet" then
				paint(p, t.Carpet)
			end
		elseif p:IsA("PointLight") then
			local par = p.Parent
			if par and par.Name == "LightFixture" then
				p.Color = t.Light
			end
		end
	end
end

function ThemeService.GetThemes(player: Player)
	local data = DataService.GetData(player)
	if not data then return { Currency = 0, Themes = {} } end
	ensure(data)
	local list = {}
	for _, id in ipairs(THEME_ORDER) do
		local t = THEMES[id]
		table.insert(list, {
			Id = id,
			Name = t.Name,
			Cost = t.Cost,
			Owned = data.OwnedThemes[id] == true,
			Selected = data.MuseumTheme == id,
		})
	end
	return { Currency = data.Currency, Themes = list }
end

function ThemeService.SelectTheme(player: Player, themeId: string)
	local data = DataService.GetData(player)
	if not data then return { Ok = false, Msg = "No data" } end
	ensure(data)
	local t = THEMES[themeId]
	if not t then return { Ok = false, Msg = "Unknown theme" } end

	local bought = false
	if not data.OwnedThemes[themeId] then
		if data.Currency < t.Cost then
			return { Ok = false, Msg = "Not enough coins" }
		end
		DataService.UpdateCurrency(player, -t.Cost)
		data.OwnedThemes[themeId] = true
		bought = true
	end

	data.MuseumTheme = themeId
	apply(player, themeId)
	MuseumChangedEvent:FireClient(player) -- refresh the currency display
	return { Ok = true, Bought = bought, Msg = (bought and "Unlocked " or "Applied ") .. t.Name }
end

RemoteFunctions:WaitForChild("GetThemes").OnServerInvoke = function(player)
	return ThemeService.GetThemes(player)
end
RemoteFunctions:WaitForChild("SelectTheme").OnServerInvoke = function(player, themeId)
	return ThemeService.SelectTheme(player, themeId)
end

-- Re-apply the saved theme once the museum exists (independent of load order).
local function applyOnJoin(player: Player)
	for _ = 1, 150 do
		local data = DataService.GetData(player)
		if PedestalService.GetMuseum(player) and data then
			ensure(data)
			apply(player, data.MuseumTheme)
			return
		end
		task.wait(0.1)
	end
end
Players.PlayerAdded:Connect(function(player)
	task.spawn(applyOnJoin, player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(applyOnJoin, player)
end

return ThemeService
