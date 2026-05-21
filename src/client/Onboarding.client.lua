-- Onboarding.client.lua
-- A first-time objective tracker that walks new players through the core loop:
-- expedition -> grab -> extract -> display. It listens to the same server
-- events the main HUD does, so it teaches by reacting to what the player does.
-- Skips entirely if the player has already finished the tutorial.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents")
local ExpeditionState  = RemoteEvents:WaitForChild("ExpeditionState")
local MuseumChanged     = RemoteEvents:WaitForChild("MuseumChanged")

local RemoteFunctions   = ReplicatedStorage:WaitForChild("RemoteFunctions")
local GetInventoryRF    = RemoteFunctions:WaitForChild("GetInventory")
local GetTutorialStateRF = RemoteFunctions:WaitForChild("GetTutorialState")
local CompleteTutorialRF = RemoteFunctions:WaitForChild("CompleteTutorial")

-- The four actionable steps. Step 5 is the completion message.
local STEPS = {
	"Head out! Press the  🔦 Go on Expedition  button (bottom-left).",
	"Find a glowing artifact and hold its  Take  prompt to grab it.",
	"Carry it to the glowing green  EXTRACTION  pad to bring it home.",
	"Back home: open  🏛 Inventory  and press  Display  on your artifact.",
}

local currentStep = 1
local active = false

-- =============================================
--  UI
-- =============================================
local gui = Instance.new("ScreenGui")
gui.Name = "OnboardingGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Tracker"
panel.Size = UDim2.new(0, 320, 0, 96)
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 12)
panel.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
panel.BackgroundTransparency = 0.1
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent = panel

local stripe = Instance.new("Frame")
stripe.Size = UDim2.new(0, 4, 1, 0)
stripe.Position = UDim2.new(0, -12, 0, -8)
stripe.BackgroundColor3 = Color3.fromRGB(140, 90, 220)
stripe.BorderSizePixel = 0
stripe.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(190, 160, 240)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "GETTING STARTED"
titleLabel.Parent = panel

local stepLabel = Instance.new("TextLabel")
stepLabel.Size = UDim2.new(1, 0, 0, 14)
stepLabel.Position = UDim2.new(0, 0, 1, -14)
stepLabel.AnchorPoint = Vector2.new(0, 1)
stepLabel.BackgroundTransparency = 1
stepLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
stepLabel.Font = Enum.Font.Gotham
stepLabel.TextSize = 11
stepLabel.TextXAlignment = Enum.TextXAlignment.Left
stepLabel.Text = ""
stepLabel.Parent = panel

local objectiveLabel = Instance.new("TextLabel")
objectiveLabel.Size = UDim2.new(1, 0, 0, 44)
objectiveLabel.Position = UDim2.new(0, 0, 0, 22)
objectiveLabel.BackgroundTransparency = 1
objectiveLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
objectiveLabel.Font = Enum.Font.GothamMedium
objectiveLabel.TextSize = 14
objectiveLabel.TextWrapped = true
objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
objectiveLabel.TextYAlignment = Enum.TextYAlignment.Top
objectiveLabel.Text = ""
objectiveLabel.Parent = panel

-- Brief green flash to acknowledge a completed step.
local function flash()
	stripe.BackgroundColor3 = Color3.fromRGB(100, 255, 130)
	TweenService:Create(stripe, TweenInfo.new(0.8), {
		BackgroundColor3 = Color3.fromRGB(140, 90, 220),
	}):Play()
end

local function setObjective(stepNum: number)
	objectiveLabel.Text = STEPS[stepNum]
	stepLabel.Text = string.format("Step %d of %d", stepNum, #STEPS)
end

local function finish()
	active = false
	local bonus = CompleteTutorialRF:InvokeServer() or 0
	flash()
	titleLabel.Text = "✓ ALL SET!"
	titleLabel.TextColor3 = Color3.fromRGB(120, 255, 150)
	stepLabel.Text = ""
	if bonus and bonus > 0 then
		objectiveLabel.Text = string.format(
			"You're earning passive income! Add more artifacts to grow — but watch your Danger.  +%d coins to start!", bonus)
	else
		objectiveLabel.Text = "You're earning passive income! Add more artifacts to grow — but watch your Danger."
	end
	task.delay(8, function()
		if panel.Parent then
			TweenService:Create(panel, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(objectiveLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
			task.wait(0.7)
			panel.Visible = false
		end
	end)
end

local function advanceTo(step: number)
	currentStep = step
	if step <= #STEPS then
		flash()
		setObjective(step)
	else
		finish()
	end
end

-- =============================================
--  STEP TRIGGERS (driven by the same events the HUD uses)
-- =============================================
ExpeditionState.OnClientEvent:Connect(function(info)
	if not active then return end
	local state = info.State
	if state == "Entered" and currentStep == 1 then
		advanceTo(2)
	elseif state == "Carrying" and currentStep == 2 then
		advanceTo(3)
	elseif state == "Extracted" and currentStep == 3 then
		advanceTo(4)
	end
end)

MuseumChanged.OnClientEvent:Connect(function()
	if not active or currentStep ~= 4 then return end
	local info = GetInventoryRF:InvokeServer()
	if not info then return end
	for _, artifact in ipairs(info.Inventory) do
		if artifact.IsDisplayed then
			advanceTo(5) -- triggers finish()
			break
		end
	end
end)

-- =============================================
--  INIT
-- =============================================
task.spawn(function()
	task.wait(2.5) -- let the HUD + data settle
	local done = GetTutorialStateRF:InvokeServer()
	if done then return end -- already completed; stay hidden

	active = true
	setObjective(1)
	panel.Visible = true
end)
