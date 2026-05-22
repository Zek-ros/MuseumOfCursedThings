-- MuseumClient.client.lua
-- The whole client experience: top-bar HUD (coins / income / danger),
-- an Expedition button that grants random artifacts, an Inventory panel
-- for displaying artifacts, plus income popups and chaos-event visuals.

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents")
local IncomeEvent        = RemoteEvents:WaitForChild("IncomeReceived")
local ChaosEventRemote   = RemoteEvents:WaitForChild("ChaosEvent")
local OpenInventoryEvent  = RemoteEvents:WaitForChild("OpenInventory")
local MuseumChangedEvent  = RemoteEvents:WaitForChild("MuseumChanged")
local LeaveExpeditionEvent = RemoteEvents:WaitForChild("LeaveExpedition")
local ExpeditionStateEvent = RemoteEvents:WaitForChild("ExpeditionState")
local QueueStateEvent      = RemoteEvents:WaitForChild("QueueState")
local OpenQueueEvent       = RemoteEvents:WaitForChild("OpenQueue")
local LeaveQueueEvent      = RemoteEvents:WaitForChild("LeaveExpeditionQueue")
local LaunchQueueEvent     = RemoteEvents:WaitForChild("LaunchExpeditionQueue")

local RemoteFunctions  = ReplicatedStorage:WaitForChild("RemoteFunctions")
local GetInventoryRF   = RemoteFunctions:WaitForChild("GetInventory")
local DisplayRF        = RemoteFunctions:WaitForChild("DisplayArtifact")
local UndisplayRF      = RemoteFunctions:WaitForChild("UndisplayArtifact")
local UpgradeContainmentRF = RemoteFunctions:WaitForChild("UpgradeContainment")
local UpgradeMuseumRF   = RemoteFunctions:WaitForChild("UpgradeMuseum")
local GetCollectionRF   = RemoteFunctions:WaitForChild("GetCollection")
local VisitMuseumRF     = RemoteFunctions:WaitForChild("VisitMuseum")
local ReturnHomeRF      = RemoteFunctions:WaitForChild("ReturnHome")
local GoToHubRF         = RemoteFunctions:WaitForChild("GoToHub")
local JoinQueueRF       = RemoteFunctions:WaitForChild("JoinExpeditionQueue")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local ArtifactData = require(Shared:WaitForChild("ArtifactData"))
local ExpeditionMaps = require(Shared:WaitForChild("ExpeditionMaps"))

-- =============================================
--  COLORS / THEME
-- =============================================
local THEME = {
	Panel     = Color3.fromRGB(24, 22, 30),
	PanelLight = Color3.fromRGB(38, 35, 48),
	Accent    = Color3.fromRGB(140, 90, 220),
	Gold      = Color3.fromRGB(255, 220, 80),
	Good      = Color3.fromRGB(100, 255, 130),
	Bad       = Color3.fromRGB(255, 90, 90),
	Text      = Color3.fromRGB(235, 235, 245),
}

local DANGER_COLORS = {
	Low      = Color3.fromRGB(120, 220, 120),
	Medium   = Color3.fromRGB(245, 215, 90),
	High     = Color3.fromRGB(245, 140, 70),
	Critical = Color3.fromRGB(255, 70, 70),
}

local function rarityColor(rarity: string): Color3
	local info = Constants.RARITY[rarity]
	return (info and info.Color) or THEME.Text
end

-- The next (stronger) containment after the given type, or nil if maxed.
local function nextContainment(current: string): string?
	local order = Constants.CONTAINMENT_ORDER
	for i, name in ipairs(order) do
		if name == current then
			return order[i + 1]
		end
	end
	-- Unknown current type: offer the first upgrade above Glass
	return order[2]
end

-- Cost to switch to a containment type.
local function containmentCost(containmentType: string): number
	local info = ArtifactData.ContainmentTypes[containmentType]
	return (info and info.Cost) or 0
end

-- Turn a numeric danger level into a word + color so players can read risk
-- at a glance. Higher danger = more frequent chaos events in your museum.
local function dangerInfo(level: number): (string, Color3)
	if level <= 0 then
		return "Safe", Color3.fromRGB(150, 220, 150)
	elseif level <= 2 then
		return "Low", Color3.fromRGB(150, 220, 150)
	elseif level <= 4 then
		return "Risky", Color3.fromRGB(245, 215, 90)
	elseif level <= 6 then
		return "Dangerous", Color3.fromRGB(245, 140, 70)
	else
		return "DEADLY", Color3.fromRGB(255, 70, 70)
	end
end

-- =============================================
--  SMALL UI HELPERS
-- =============================================
local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function padding(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.Parent = parent
	return p
end

-- =============================================
--  ROOT GUI
-- =============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MuseumGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ----- Top bar -----
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0, 300, 0, 78)
topBar.Position = UDim2.new(0.5, -150, 0, 12)
topBar.BackgroundColor3 = THEME.Panel
topBar.BackgroundTransparency = 0.15
topBar.Parent = screenGui
corner(topBar, 10)
padding(topBar, 8)

local currencyLabel = Instance.new("TextLabel")
currencyLabel.Name = "CurrencyLabel"
currencyLabel.Size = UDim2.new(1, 0, 0, 28)
currencyLabel.BackgroundTransparency = 1
currencyLabel.TextColor3 = THEME.Gold
currencyLabel.Font = Enum.Font.GothamBold
currencyLabel.TextSize = 22
currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
currencyLabel.Text = "● ..."
currencyLabel.Parent = topBar

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(1, 0, 0, 18)
incomeLabel.Position = UDim2.new(0, 0, 0, 30)
incomeLabel.BackgroundTransparency = 1
incomeLabel.TextColor3 = THEME.Good
incomeLabel.Font = Enum.Font.Gotham
incomeLabel.TextSize = 14
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Text = "+0 / tick"
incomeLabel.Parent = topBar

local dangerLabel = Instance.new("TextLabel")
dangerLabel.Name = "DangerLabel"
dangerLabel.Size = UDim2.new(1, 0, 0, 18)
dangerLabel.Position = UDim2.new(0, 0, 0, 48)
dangerLabel.BackgroundTransparency = 1
dangerLabel.TextColor3 = DANGER_COLORS.Low
dangerLabel.Font = Enum.Font.Gotham
dangerLabel.TextSize = 14
dangerLabel.TextXAlignment = Enum.TextXAlignment.Left
dangerLabel.Text = "Danger: 0 (Low)"
dangerLabel.Parent = topBar

-- ----- Bottom-left buttons -----
local function makeActionButton(name: string, text: string, color: Color3, order: number)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 190, 0, 46)
	btn.Position = UDim2.new(0, 16, 1, -16 - (order * 56))
	btn.AnchorPoint = Vector2.new(0, 1)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(20, 18, 26)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.Text = text
	btn.AutoButtonColor = true
	btn.Parent = screenGui
	corner(btn, 10)
	return btn
end

local expeditionButton = makeActionButton("ExpeditionButton", "🔦 Go on Expedition", THEME.Accent, 1)
local inventoryButton  = makeActionButton("InventoryButton", "🏛 Inventory", THEME.PanelLight, 0)
inventoryButton.TextColor3 = THEME.Text

local museumButton  = makeActionButton("MuseumButton", "🏛 Expand Museum", THEME.PanelLight, 2)
museumButton.TextColor3 = THEME.Text
local collectionButton = makeActionButton("CollectionButton", "📖 Collection", THEME.PanelLight, 3)
collectionButton.TextColor3 = THEME.Text
local visitButton = makeActionButton("VisitButton", "👥 Visit Museums", THEME.PanelLight, 4)
visitButton.TextColor3 = THEME.Text

-- Shown only while on an expedition
local leaveButton = makeActionButton("LeaveExpeditionButton", "🏃 Leave Expedition", THEME.Bad, 5)
leaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
leaveButton.Visible = false

-- Top-left navigation between the hub and your museum
local function makeNavButton(name: string, text: string, order: number)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 150, 0, 34)
	btn.Position = UDim2.new(0, 16, 0, 16 + order * 40)
	btn.BackgroundColor3 = THEME.PanelLight
	btn.TextColor3 = THEME.Text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = text
	btn.Parent = screenGui
	corner(btn, 8)
	return btn
end
local hubButton = makeNavButton("HubButton", "🌐 Hub", 0)
local myMuseumButton = makeNavButton("MyMuseumButton", "🏛 My Museum", 1)

-- =============================================
--  INVENTORY PANEL
-- =============================================
local inventoryPanel = Instance.new("Frame")
inventoryPanel.Name = "InventoryPanel"
inventoryPanel.Size = UDim2.new(0, 460, 0, 460)
inventoryPanel.Position = UDim2.new(0.5, -230, 0.5, -230)
inventoryPanel.BackgroundColor3 = THEME.Panel
inventoryPanel.BackgroundTransparency = 0.05
inventoryPanel.Visible = false
inventoryPanel.Parent = screenGui
corner(inventoryPanel, 12)

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.new(1, -60, 0, 44)
panelTitle.Position = UDim2.new(0, 16, 0, 8)
panelTitle.BackgroundTransparency = 1
panelTitle.TextColor3 = THEME.Text
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 22
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.Text = "Your Artifacts"
panelTitle.Parent = inventoryPanel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -44, 0, 10)
closeButton.BackgroundColor3 = THEME.Bad
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 20
closeButton.Text = "✕"
closeButton.Parent = inventoryPanel
corner(closeButton, 8)

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, -32, 0, 40)
emptyLabel.Position = UDim2.new(0, 16, 0, 60)
emptyLabel.BackgroundTransparency = 1
emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextSize = 15
emptyLabel.TextWrapped = true
emptyLabel.Text = "No artifacts yet. Go on an expedition to find some!"
emptyLabel.Visible = false
emptyLabel.Parent = inventoryPanel

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ArtifactList"
scroll.Size = UDim2.new(1, -24, 1, -64)
scroll.Position = UDim2.new(0, 12, 0, 56)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = inventoryPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

-- =============================================
--  COLLECTION PANEL
-- =============================================
local collectionPanel = Instance.new("Frame")
collectionPanel.Name = "CollectionPanel"
collectionPanel.Size = UDim2.new(0, 460, 0, 460)
collectionPanel.Position = UDim2.new(0.5, -230, 0.5, -230)
collectionPanel.BackgroundColor3 = THEME.Panel
collectionPanel.BackgroundTransparency = 0.05
collectionPanel.Visible = false
collectionPanel.Parent = screenGui
corner(collectionPanel, 12)

local collTitle = Instance.new("TextLabel")
collTitle.Size = UDim2.new(1, -60, 0, 44)
collTitle.Position = UDim2.new(0, 16, 0, 8)
collTitle.BackgroundTransparency = 1
collTitle.TextColor3 = THEME.Text
collTitle.Font = Enum.Font.GothamBold
collTitle.TextSize = 22
collTitle.TextXAlignment = Enum.TextXAlignment.Left
collTitle.Text = "Collection"
collTitle.Parent = collectionPanel

local collClose = Instance.new("TextButton")
collClose.Size = UDim2.new(0, 36, 0, 36)
collClose.Position = UDim2.new(1, -44, 0, 10)
collClose.BackgroundColor3 = THEME.Bad
collClose.TextColor3 = Color3.fromRGB(255, 255, 255)
collClose.Font = Enum.Font.GothamBold
collClose.TextSize = 20
collClose.Text = "✕"
collClose.Parent = collectionPanel
corner(collClose, 8)

local collScroll = Instance.new("ScrollingFrame")
collScroll.Size = UDim2.new(1, -24, 1, -64)
collScroll.Position = UDim2.new(0, 12, 0, 56)
collScroll.BackgroundTransparency = 1
collScroll.BorderSizePixel = 0
collScroll.ScrollBarThickness = 6
collScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
collScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
collScroll.Parent = collectionPanel

local collLayout = Instance.new("UIListLayout")
collLayout.Padding = UDim.new(0, 6)
collLayout.SortOrder = Enum.SortOrder.LayoutOrder
collLayout.Parent = collScroll

-- =============================================
--  EXPEDITION CHOOSER PANEL
-- =============================================
local expeditionPanel = Instance.new("Frame")
expeditionPanel.Name = "ExpeditionPanel"
expeditionPanel.Size = UDim2.new(0, 440, 0, 320)
expeditionPanel.Position = UDim2.new(0.5, -220, 0.5, -160)
expeditionPanel.BackgroundColor3 = THEME.Panel
expeditionPanel.BackgroundTransparency = 0.05
expeditionPanel.Visible = false
expeditionPanel.Parent = screenGui
corner(expeditionPanel, 12)

local expTitle = Instance.new("TextLabel")
expTitle.Size = UDim2.new(1, -60, 0, 44)
expTitle.Position = UDim2.new(0, 16, 0, 8)
expTitle.BackgroundTransparency = 1
expTitle.TextColor3 = THEME.Text
expTitle.Font = Enum.Font.GothamBold
expTitle.TextSize = 22
expTitle.TextXAlignment = Enum.TextXAlignment.Left
expTitle.Text = "Choose an Expedition"
expTitle.Parent = expeditionPanel

local expClose = Instance.new("TextButton")
expClose.Size = UDim2.new(0, 36, 0, 36)
expClose.Position = UDim2.new(1, -44, 0, 10)
expClose.BackgroundColor3 = THEME.Bad
expClose.TextColor3 = Color3.fromRGB(255, 255, 255)
expClose.Font = Enum.Font.GothamBold
expClose.TextSize = 20
expClose.Text = "✕"
expClose.Parent = expeditionPanel
corner(expClose, 8)

local expList = Instance.new("Frame")
expList.Size = UDim2.new(1, -24, 1, -64)
expList.Position = UDim2.new(0, 12, 0, 56)
expList.BackgroundTransparency = 1
expList.Parent = expeditionPanel

local expListLayout = Instance.new("UIListLayout")
expListLayout.Padding = UDim.new(0, 10)
expListLayout.SortOrder = Enum.SortOrder.LayoutOrder
expListLayout.Parent = expList

-- =============================================
--  VISIT MUSEUMS PANEL
-- =============================================
local visitPanel = Instance.new("Frame")
visitPanel.Name = "VisitPanel"
visitPanel.Size = UDim2.new(0, 420, 0, 380)
visitPanel.Position = UDim2.new(0.5, -210, 0.5, -190)
visitPanel.BackgroundColor3 = THEME.Panel
visitPanel.BackgroundTransparency = 0.05
visitPanel.Visible = false
visitPanel.Parent = screenGui
corner(visitPanel, 12)

local visitTitle = Instance.new("TextLabel")
visitTitle.Size = UDim2.new(1, -60, 0, 44)
visitTitle.Position = UDim2.new(0, 16, 0, 8)
visitTitle.BackgroundTransparency = 1
visitTitle.TextColor3 = THEME.Text
visitTitle.Font = Enum.Font.GothamBold
visitTitle.TextSize = 22
visitTitle.TextXAlignment = Enum.TextXAlignment.Left
visitTitle.Text = "Visit a Museum"
visitTitle.Parent = visitPanel

local visitClose = Instance.new("TextButton")
visitClose.Size = UDim2.new(0, 36, 0, 36)
visitClose.Position = UDim2.new(1, -44, 0, 10)
visitClose.BackgroundColor3 = THEME.Bad
visitClose.TextColor3 = Color3.fromRGB(255, 255, 255)
visitClose.Font = Enum.Font.GothamBold
visitClose.TextSize = 20
visitClose.Text = "✕"
visitClose.Parent = visitPanel
corner(visitClose, 8)

local visitEmpty = Instance.new("TextLabel")
visitEmpty.Size = UDim2.new(1, -32, 0, 40)
visitEmpty.Position = UDim2.new(0, 16, 0, 60)
visitEmpty.BackgroundTransparency = 1
visitEmpty.TextColor3 = Color3.fromRGB(150, 150, 160)
visitEmpty.Font = Enum.Font.Gotham
visitEmpty.TextSize = 15
visitEmpty.TextWrapped = true
visitEmpty.Text = "No one else is online right now. Invite a friend to tour your cursed museum!"
visitEmpty.Visible = false
visitEmpty.Parent = visitPanel

local visitScroll = Instance.new("ScrollingFrame")
visitScroll.Size = UDim2.new(1, -24, 1, -64)
visitScroll.Position = UDim2.new(0, 12, 0, 56)
visitScroll.BackgroundTransparency = 1
visitScroll.BorderSizePixel = 0
visitScroll.ScrollBarThickness = 6
visitScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
visitScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
visitScroll.Parent = visitPanel

local visitLayout = Instance.new("UIListLayout")
visitLayout.Padding = UDim.new(0, 8)
visitLayout.SortOrder = Enum.SortOrder.LayoutOrder
visitLayout.Parent = visitScroll

-- =============================================
--  EXPEDITION QUEUE PANEL
-- =============================================
local queuePanel = Instance.new("Frame")
queuePanel.Name = "QueuePanel"
queuePanel.Size = UDim2.new(0, 360, 0, 200)
queuePanel.Position = UDim2.new(0.5, -180, 0.5, -100)
queuePanel.BackgroundColor3 = THEME.Panel
queuePanel.BackgroundTransparency = 0.05
queuePanel.Visible = false
queuePanel.Parent = screenGui
corner(queuePanel, 12)

local queueTitle = Instance.new("TextLabel")
queueTitle.Size = UDim2.new(1, -24, 0, 30)
queueTitle.Position = UDim2.new(0, 12, 0, 12)
queueTitle.BackgroundTransparency = 1
queueTitle.TextColor3 = THEME.Accent
queueTitle.Font = Enum.Font.GothamBold
queueTitle.TextSize = 20
queueTitle.Text = "Queued for Expedition"
queueTitle.Parent = queuePanel

local queueInfo = Instance.new("TextLabel")
queueInfo.Size = UDim2.new(1, -24, 0, 60)
queueInfo.Position = UDim2.new(0, 12, 0, 46)
queueInfo.BackgroundTransparency = 1
queueInfo.TextColor3 = THEME.Text
queueInfo.Font = Enum.Font.Gotham
queueInfo.TextSize = 16
queueInfo.TextWrapped = true
queueInfo.Text = ""
queueInfo.Parent = queuePanel

local launchNowBtn = Instance.new("TextButton")
launchNowBtn.Size = UDim2.new(0.5, -18, 0, 40)
launchNowBtn.Position = UDim2.new(0, 12, 1, -52)
launchNowBtn.BackgroundColor3 = THEME.Good
launchNowBtn.TextColor3 = Color3.fromRGB(20, 30, 20)
launchNowBtn.Font = Enum.Font.GothamBold
launchNowBtn.TextSize = 16
launchNowBtn.Text = "🔦 Launch Now"
launchNowBtn.Parent = queuePanel
corner(launchNowBtn, 8)

local leaveQueueBtn = Instance.new("TextButton")
leaveQueueBtn.Size = UDim2.new(0.5, -18, 0, 40)
leaveQueueBtn.Position = UDim2.new(0.5, 6, 1, -52)
leaveQueueBtn.BackgroundColor3 = THEME.Bad
leaveQueueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
leaveQueueBtn.Font = Enum.Font.GothamBold
leaveQueueBtn.TextSize = 16
leaveQueueBtn.Text = "Leave Queue"
leaveQueueBtn.Parent = queuePanel
corner(leaveQueueBtn, 8)

-- =============================================
--  FLOATING TEXT + BANNER HELPERS
-- =============================================
local function showFloatingText(text: string, color: Color3, yStart: number?)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 300, 0, 40)
	local startY = yStart or 0.7
	label.Position = UDim2.new(0.5, -150, startY, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	label.Text = text
	label.ZIndex = 50
	label.Parent = screenGui

	local tween = TweenService:Create(label, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -150, startY - 0.15, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function() label:Destroy() end)
end

local function showBanner(text: string, bgColor: Color3, textColor: Color3, duration: number?)
	local banner = Instance.new("TextLabel")
	banner.Size = UDim2.new(0, 520, 0, 50)
	banner.Position = UDim2.new(0.5, -260, 0.12, 0)
	banner.BackgroundColor3 = bgColor
	banner.BackgroundTransparency = 0.15
	banner.TextColor3 = textColor
	banner.Font = Enum.Font.GothamBold
	banner.TextSize = 18
	banner.TextWrapped = true
	banner.Text = text
	banner.ZIndex = 60
	banner.Parent = screenGui
	corner(banner, 8)

	task.delay(duration or 3, function()
		if banner.Parent then banner:Destroy() end
	end)
end

-- =============================================
--  INVENTORY RENDERING
-- =============================================
local cachedCurrency = 0

local function updateTopBar(info)
	if info.Currency then
		cachedCurrency = info.Currency
		currencyLabel.Text = "● " .. cachedCurrency
	end
	if info.IncomePerTick then
		local visitors = info.VisitorCount or 0
		if visitors > 0 then
			incomeLabel.Text = string.format("+%d / tick  ·  %d visitors", info.IncomePerTick, visitors)
		else
			incomeLabel.Text = "+" .. info.IncomePerTick .. " / tick"
		end
	end
	if info.DangerScore ~= nil then
		local tier = info.DangerTier or "Low"
		local mult = Constants.DANGER_INCOME_MULTIPLIER[tier] or 1.0
		dangerLabel.Text = string.format("Danger: %d (%s)  ·  income x%.2g", info.DangerScore, tier, mult)
		dangerLabel.TextColor3 = DANGER_COLORS[tier] or DANGER_COLORS.Low
	end
	if info.MuseumLevel then
		if info.NextUpgradeCost then
			museumButton.Text = string.format("🏛 Expand: Lv.%d (%d)", info.MuseumLevel, info.NextUpgradeCost)
		else
			museumButton.Text = string.format("🏛 Museum Lv.%d (MAX)", info.MuseumLevel)
		end
	end
end

local function buildArtifactRow(entry, refreshFn)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 70)
	row.BackgroundColor3 = THEME.PanelLight
	row.LayoutOrder = entry.Index
	corner(row, 8)
	padding(row, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -110, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = rarityColor(entry.Rarity)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = entry.Name
	nameLabel.Parent = row

	-- A clear, color-coded danger badge so players can read risk at a glance.
	local dWord, dColor = dangerInfo(entry.DangerLevel)
	local dangerBadge = Instance.new("TextLabel")
	dangerBadge.Size = UDim2.new(1, -110, 0, 16)
	dangerBadge.Position = UDim2.new(0, 0, 0, 22)
	dangerBadge.BackgroundTransparency = 1
	dangerBadge.TextColor3 = dColor
	dangerBadge.Font = Enum.Font.GothamBold
	dangerBadge.TextSize = 13
	dangerBadge.TextXAlignment = Enum.TextXAlignment.Left
	dangerBadge.Text = string.format("☠ Danger: %s (%d)", dWord, entry.DangerLevel)
	dangerBadge.Parent = row

	local detailLabel = Instance.new("TextLabel")
	detailLabel.Size = UDim2.new(1, -110, 0, 16)
	detailLabel.Position = UDim2.new(0, 0, 0, 40)
	detailLabel.BackgroundTransparency = 1
	detailLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	detailLabel.Font = Enum.Font.Gotham
	detailLabel.TextSize = 12
	detailLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailLabel.Text = string.format(
		"%s · 💰 %d/tick · 🔒 %s",
		entry.Rarity, entry.PassiveIncome, entry.ContainmentType
	)
	detailLabel.Parent = row

	-- Display / Remove (top-right)
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 96, 0, 28)
	toggle.Position = UDim2.new(1, -100, 0, 5)
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 13
	toggle.AutoButtonColor = true
	corner(toggle, 6)

	if entry.IsDisplayed then
		toggle.Text = "Remove"
		toggle.BackgroundColor3 = THEME.Bad
		toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		toggle.Text = "Display"
		toggle.BackgroundColor3 = THEME.Good
		toggle.TextColor3 = Color3.fromRGB(20, 30, 20)
	end
	toggle.Parent = row

	toggle.Activated:Connect(function()
		toggle.Active = false
		local rf = entry.IsDisplayed and UndisplayRF or DisplayRF
		local ok, msg = rf:InvokeServer(entry.Index)
		if not ok and msg then
			showBanner(msg, THEME.Bad, Color3.fromRGB(255, 255, 255), 2)
		end
		refreshFn()
	end)

	-- Upgrade containment (bottom-right) — the coin sink that tames chaos
	local upgrade = Instance.new("TextButton")
	upgrade.Size = UDim2.new(0, 96, 0, 28)
	upgrade.Position = UDim2.new(1, -100, 0, 37)
	upgrade.Font = Enum.Font.GothamBold
	upgrade.TextScaled = true
	corner(upgrade, 6)

	local nextType = nextContainment(entry.ContainmentType)
	if nextType then
		local cost = containmentCost(nextType)
		upgrade.Text = string.format("🔒⬆ %d", cost)
		upgrade.BackgroundColor3 = THEME.Accent
		upgrade.TextColor3 = Color3.fromRGB(255, 255, 255)
		upgrade.Activated:Connect(function()
			upgrade.Active = false
			local ok, msg = UpgradeContainmentRF:InvokeServer(entry.Index, nextType)
			if ok then
				showBanner("Containment upgraded to " .. nextType, Color3.fromRGB(30, 30, 50), THEME.Good, 2)
			elseif msg then
				showBanner(msg, THEME.Bad, Color3.fromRGB(255, 255, 255), 2)
			end
			refreshFn()
		end)
	else
		upgrade.Text = "🔒 Max"
		upgrade.BackgroundColor3 = Color3.fromRGB(50, 48, 60)
		upgrade.TextColor3 = Color3.fromRGB(160, 160, 170)
		upgrade.AutoButtonColor = false
	end
	upgrade.Parent = row

	row.Parent = scroll
end

local refreshInventory -- forward declare

refreshInventory = function()
	local info = GetInventoryRF:InvokeServer()
	if not info then return end

	updateTopBar(info)

	-- Clear existing rows (keep the UIListLayout)
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local count = #info.Inventory
	emptyLabel.Visible = (count == 0)

	for _, entry in ipairs(info.Inventory) do
		buildArtifactRow(entry, refreshInventory)
	end

	panelTitle.Text = string.format("Your Artifacts (%d)", count)
end

-- =============================================
--  COLLECTION RENDERING
-- =============================================
local function buildCollectionRow(entry, order: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 44)
	row.BackgroundColor3 = THEME.PanelLight
	row.LayoutOrder = order
	corner(row, 8)
	padding(row, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local subLabel = Instance.new("TextLabel")
	subLabel.Size = UDim2.new(1, 0, 0, 14)
	subLabel.Position = UDim2.new(0, 0, 0, 18)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.Gotham
	subLabel.TextSize = 12
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.Parent = row

	if entry.Discovered then
		nameLabel.Text = entry.Name
		nameLabel.TextColor3 = rarityColor(entry.Rarity)
		subLabel.Text = entry.Rarity .. " · " .. entry.Description
		subLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
	else
		nameLabel.Text = "??? "
		nameLabel.TextColor3 = Color3.fromRGB(110, 110, 120)
		subLabel.Text = entry.Rarity .. " · undiscovered"
		subLabel.TextColor3 = Color3.fromRGB(90, 90, 100)
	end

	row.Parent = collScroll
end

local function refreshCollection()
	local info = GetCollectionRF:InvokeServer()
	if not info then return end

	for _, child in ipairs(collScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for i, entry in ipairs(info.Entries) do
		buildCollectionRow(entry, i)
	end

	collTitle.Text = string.format("Collection  (%d / %d)", info.Discovered, info.Total)
end

-- =============================================
--  BUTTON BEHAVIOUR
-- =============================================
inventoryButton.Activated:Connect(function()
	inventoryPanel.Visible = not inventoryPanel.Visible
	if inventoryPanel.Visible then
		refreshInventory()
	end
end)

closeButton.Activated:Connect(function()
	inventoryPanel.Visible = false
end)

museumButton.Activated:Connect(function()
	local ok, msg = UpgradeMuseumRF:InvokeServer()
	if ok then
		showBanner(msg or "Museum expanded!", Color3.fromRGB(20, 40, 50), THEME.Good, 2.5)
	elseif msg then
		showBanner(msg, THEME.Bad, Color3.fromRGB(255, 255, 255), 2)
	end
	-- Top bar (and the button label) refresh via MuseumChanged.
end)

collectionButton.Activated:Connect(function()
	collectionPanel.Visible = not collectionPanel.Visible
	if collectionPanel.Visible then
		refreshCollection()
	end
end)

collClose.Activated:Connect(function()
	collectionPanel.Visible = false
end)

-- Build one button per expedition map (static list)
local expeditionBusy = false
for i, map in ipairs(ExpeditionMaps) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 64)
	btn.LayoutOrder = i
	btn.BackgroundColor3 = THEME.PanelLight
	btn.AutoButtonColor = true
	btn.Text = ""
	corner(btn, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -24, 0, 24)
	nameLabel.Position = UDim2.new(0, 12, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = THEME.Accent
	nameLabel.Text = "🔦 " .. map.Name
	nameLabel.Parent = btn

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -24, 0, 24)
	descLabel.Position = UDim2.new(0, 12, 0, 32)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 13
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	descLabel.Text = map.Description
	descLabel.Parent = btn

	btn.Activated:Connect(function()
		if expeditionBusy then return end
		expeditionBusy = true
		expeditionPanel.Visible = false
		-- Join the queue for this map; the queue panel takes over from here.
		local ok, msg = JoinQueueRF:InvokeServer(map.Id)
		if not ok and msg then
			showBanner(msg, THEME.PanelLight, THEME.Text, 2)
		end
		task.wait(0.5)
		expeditionBusy = false
	end)

	btn.Parent = expList
end

expeditionButton.Activated:Connect(function()
	-- Open the map chooser (close other panels first)
	inventoryPanel.Visible = false
	collectionPanel.Visible = false
	expeditionPanel.Visible = not expeditionPanel.Visible
end)

expClose.Activated:Connect(function()
	expeditionPanel.Visible = false
end)

-- ===== Visit museums =====
local function refreshVisitList()
	for _, child in ipairs(visitScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local others = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then table.insert(others, other) end
	end
	visitEmpty.Visible = (#others == 0)

	for i, other in ipairs(others) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 48)
		btn.LayoutOrder = i
		btn.BackgroundColor3 = THEME.PanelLight
		btn.TextColor3 = THEME.Text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 16
		btn.Text = "👥 " .. other.DisplayName .. "'s Museum"
		corner(btn, 8)
		btn.Activated:Connect(function()
			local ok, msg = VisitMuseumRF:InvokeServer(other.Name)
			if ok then
				visitPanel.Visible = false
				showBanner((msg or ("Visiting " .. other.DisplayName)) .. "  (use 🏛 My Museum to return)",
					Color3.fromRGB(30, 30, 50), THEME.Good, 3)
			elseif msg then
				showBanner(msg, THEME.Bad, Color3.fromRGB(255, 255, 255), 2)
			end
		end)
		btn.Parent = visitScroll
	end
end

visitButton.Activated:Connect(function()
	inventoryPanel.Visible = false
	collectionPanel.Visible = false
	expeditionPanel.Visible = false
	visitPanel.Visible = not visitPanel.Visible
	if visitPanel.Visible then refreshVisitList() end
end)

visitClose.Activated:Connect(function()
	visitPanel.Visible = false
end)

-- ===== Hub / museum navigation =====
hubButton.Activated:Connect(function()
	GoToHubRF:InvokeServer()
end)

myMuseumButton.Activated:Connect(function()
	ReturnHomeRF:InvokeServer()
end)

-- ===== Expedition queue =====
launchNowBtn.Activated:Connect(function()
	LaunchQueueEvent:FireServer()
end)

leaveQueueBtn.Activated:Connect(function()
	LeaveQueueEvent:FireServer()
	queuePanel.Visible = false
end)

QueueStateEvent.OnClientEvent:Connect(function(info)
	if info.InQueue then
		queuePanel.Visible = true
		queueTitle.Text = "Queued: " .. (info.MapName or "Expedition")
		queueInfo.Text = string.format(
			"%d player%s queued.\nLaunching in %d seconds — or press Launch Now.",
			info.Count or 1, (info.Count == 1) and "" or "s", info.SecondsLeft or 0)
	else
		queuePanel.Visible = false
	end
end)

-- Hub queue pad asks us to open the map chooser
OpenQueueEvent.OnClientEvent:Connect(function()
	inventoryPanel.Visible = false
	collectionPanel.Visible = false
	visitPanel.Visible = false
	expeditionPanel.Visible = true
end)

leaveButton.Activated:Connect(function()
	LeaveExpeditionEvent:FireServer()
end)

-- Server tells us about expedition progress (entered / carrying / extracted / left)
ExpeditionStateEvent.OnClientEvent:Connect(function(info)
	local state = info.State
	if state == "Entered" then
		expeditionButton.Visible = false
		leaveButton.Visible = true
		queuePanel.Visible = false -- the queue launched
		showBanner("Find a cursed artifact and carry it to the green EXTRACTION pad!",
			Color3.fromRGB(20, 40, 30), Color3.fromRGB(160, 255, 200), 4)
	elseif state == "Carrying" then
		showBanner(string.format("Picked up %s — get to the EXTRACTION pad!", info.ArtifactName or "an artifact"),
			Color3.fromRGB(30, 30, 50), Color3.fromRGB(220, 220, 255), 3)
	elseif state == "AlreadyCarrying" then
		showBanner("You can only carry one artifact at a time!", THEME.PanelLight, THEME.Text, 2)
	elseif state == "Extracted" then
		expeditionButton.Visible = true
		leaveButton.Visible = false
		showBanner(string.format("Extracted %s! Added to your collection.", info.ArtifactName or "an artifact"),
			Color3.fromRGB(20, 50, 30), THEME.Good, 3.5)
		-- Reflect the new artifact + extraction reward
		local data = GetInventoryRF:InvokeServer()
		if data then updateTopBar(data) end
		if inventoryPanel.Visible then refreshInventory() end
		if collectionPanel.Visible then refreshCollection() end
	elseif state == "Dropped" then
		showBanner("A monster caught you! You dropped the artifact — grab it and run!",
			Color3.fromRGB(60, 20, 20), Color3.fromRGB(255, 160, 160), 3)
	elseif state == "Left" then
		expeditionButton.Visible = true
		leaveButton.Visible = false
		showBanner("Returned to your museum empty-handed.", THEME.PanelLight, THEME.Text, 2)
	end
end)

-- =============================================
--  INCOME + CHAOS EVENT HANDLERS
-- =============================================
IncomeEvent.OnClientEvent:Connect(function(amount: number)
	cachedCurrency += amount
	currencyLabel.Text = "● " .. cachedCurrency
	showFloatingText("+" .. amount .. " coins", THEME.Good)
end)

local chaosHandlers = {}

chaosHandlers.FlickerLights = function()
	-- The actual flicker happens server-side on the museum's own lights
	-- (so visitors see it too). This is just a flavor banner.
	showBanner("The lights flicker violently...", Color3.fromRGB(20, 20, 30), Color3.fromRGB(220, 220, 255), 2)
end

chaosHandlers.CryingSounds = function()
	showBanner("You hear quiet sobbing from Exhibit A...", Color3.fromRGB(40, 40, 80), Color3.fromRGB(180, 180, 255), 3)
end

chaosHandlers.WhisperNames = function(data)
	showBanner("...  " .. (data.Name or player.Name) .. "  ...", Color3.fromRGB(20, 20, 40), Color3.fromRGB(200, 200, 255), 3)
end

chaosHandlers.ScareVisitors = function()
	showBanner("Visitors flee in terror!", Color3.fromRGB(60, 20, 20), Color3.fromRGB(255, 200, 200), 2)
end

chaosHandlers.LaunchProjectile = function()
	showBanner("BURNING TOAST INCOMING!", Color3.fromRGB(80, 40, 0), Color3.fromRGB(255, 200, 100), 2)
end

chaosHandlers.StealIncome = function(data)
	showFloatingText("King's Coin stole " .. (data.Amount or "?") .. " coins!", THEME.Bad, 0.65)
	cachedCurrency = math.max(0, cachedCurrency - (data.Amount or 0))
	currencyLabel.Text = "● " .. cachedCurrency
end

chaosHandlers.GlitchReality = function(data)
	local fx = Instance.new("ColorCorrectionEffect")
	fx.Saturation = -1
	fx.Brightness = 0.2
	fx.Parent = Lighting
	task.delay(data.Duration or 5, function()
		if fx.Parent then fx:Destroy() end
	end)
end

chaosHandlers.PredictDisaster = function()
	showBanner("MEAT COMPUTER PREDICTS: SOMETHING TERRIBLE IS COMING", Color3.fromRGB(20, 0, 0), Color3.fromRGB(255, 50, 50), 4)
end

chaosHandlers.AlterServer = function(data)
	showBanner("[DIMENSIONAL BREACH] " .. (data.SourcePlayer or "Someone") .. "'s museum has shattered reality.", Color3.fromRGB(50, 0, 80), Color3.fromRGB(220, 180, 255), 5)
end

chaosHandlers.RingDuringChaos = function()
	showBanner("The Teeth Phone is ringing... do NOT answer it.", Color3.fromRGB(40, 40, 40), Color3.fromRGB(255, 255, 200), 3)
end

chaosHandlers.Teleport = function()
	showBanner("The Traffic Cone has moved. Again.", Color3.fromRGB(60, 40, 0), Color3.fromRGB(255, 180, 50), 2)
end

chaosHandlers.MoveWhenUnwatched = function()
	showBanner("...was the mannequin always standing there?", Color3.fromRGB(30, 30, 30), Color3.fromRGB(200, 200, 200), 3)
end

chaosHandlers.SpawnClones = function()
	showBanner("Something has duplicated. This is fine.", Color3.fromRGB(30, 50, 30), Color3.fromRGB(150, 255, 150), 3)
end

chaosHandlers.OverrideContainment = function()
	showBanner("WARNING: CONTAINMENT BREACH", Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 255, 255), 3)
end

ChaosEventRemote.OnClientEvent:Connect(function(eventName, data)
	local handler = chaosHandlers[eventName]
	if handler then
		task.spawn(handler, data or {})
		-- A chaos event may change danger/income on the server side; refresh quietly.
		task.delay(0.2, function()
			local info = GetInventoryRF:InvokeServer()
			if info then updateTopBar(info) end
		end)
	else
		warn("[ChaosClient] Unknown event: " .. tostring(eventName))
	end
end)

-- =============================================
--  PEDESTAL INTERACTIONS (server-driven)
-- =============================================
-- An empty pedestal's prompt asks the server to open our inventory.
OpenInventoryEvent.OnClientEvent:Connect(function()
	inventoryPanel.Visible = true
	refreshInventory()
end)

-- The server tells us our museum changed (displayed artifacts / containment).
-- Keep the top bar accurate, and refresh the panel if it's open.
MuseumChangedEvent.OnClientEvent:Connect(function()
	local info = GetInventoryRF:InvokeServer()
	if info then updateTopBar(info) end
	if inventoryPanel.Visible then
		refreshInventory()
	end
end)

-- =============================================
--  INITIAL SYNC
-- =============================================
task.spawn(function()
	-- Retry until the server has loaded our data
	for _ = 1, 10 do
		local info = GetInventoryRF:InvokeServer()
		if info then
			updateTopBar(info)
			break
		end
		task.wait(0.5)
	end
end)

print("[Museum of Cursed Things] Client initialized.")
