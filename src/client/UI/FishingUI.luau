-- StarterPlayerScripts/Client/UI/FishingUI.luau
local FishingUI = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

function FishingUI:BuildUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.Parent = playerGui

	local powerFrame = Instance.new("Frame")
	powerFrame.Name = "PowerMeter"
	powerFrame.Size = UDim2.fromOffset(180, 180)
	powerFrame.AnchorPoint = Vector2.new(1, 1) -- bottom-right
	powerFrame.Position = UDim2.new(1, -20, 1, -20) -- 20px from right and bottom
	powerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	powerFrame.BackgroundTransparency = 0.2
	powerFrame.Visible = true
	powerFrame.Parent = screenGui

	local powerCorner = Instance.new("UICorner")
	powerCorner.CornerRadius = UDim.new(1, 0)
	powerCorner.Parent = powerFrame

	local powerFill = Instance.new("Frame")
	powerFill.Name = "Fill"
	powerFill.BackgroundColor3 = Color3.fromRGB(70, 200, 255)
	powerFill.BackgroundTransparency = 0.1
	powerFill.Size = UDim2.new(1, 0, 0, 0)
	powerFill.AnchorPoint = Vector2.new(0.5, 1)
	powerFill.Position = UDim2.new(0.5, 0, 1, 0)
	powerFill.Parent = powerFrame

	local powerFillCorner = Instance.new("UICorner")
	powerFillCorner.CornerRadius = UDim.new(1, 0)
	powerFillCorner.Parent = powerFill

    -- Minigame panel (hidden until hooked)
    local miniFrame = Instance.new("Frame")
    miniFrame.Name = "FishingMinigame"
    miniFrame.Size = UDim2.fromOffset(60, 300)
    miniFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    miniFrame.Position = UDim2.new(0.25, 0, 0.4, 0)
    miniFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    miniFrame.BackgroundTransparency = 1
    miniFrame.Visible = false
    miniFrame.Parent = screenGui

    -- Vertical bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 20, 1, -20) -- tall, thin bar
    bar.AnchorPoint = Vector2.new(0.5, 0.5)
    bar.Position = UDim2.new(0.5, 0, 0.5, 0)
    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- base color (not visible once gradient is applied)
    bar.Parent = miniFrame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90 -- vertical top-to-bottom
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(196, 224, 255)),   -- top (0%)
        ColorSequenceKeypoint.new(0.15, Color3.fromRGB(196, 224, 255)), -- keep red until 15%
        ColorSequenceKeypoint.new(0.151, Color3.fromRGB(73, 182, 224)), -- transition just after 15%
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 10, 94))   -- bottom
    })
    gradient.Parent = bar

    -- Cursor (moves up & down)
    local cursor = Instance.new("ImageLabel")
    cursor.Name = "FishCursor"
    cursor.Size = UDim2.fromOffset(60, 60) -- bigger fish (overflow bar)
    cursor.AnchorPoint = Vector2.new(0.5, 0.5)
    cursor.Position = UDim2.new(0.5, 0, 1, 0) -- starts near top
    cursor.BackgroundTransparency = 1 -- no background
    cursor.Image = "rbxassetid://9400392150" -- 🐟 fish icon
    cursor.ImageColor3 = Color3.fromRGB(220, 220, 220)
    cursor.Parent = bar

    -- Make sure the bar does NOT clip children
    bar.ClipsDescendants = false

	-- Store references so you can show/hide later
	self.ScreenGui = screenGui
	self.PowerFrame = powerFrame
	self.PowerFill = powerFill
    self.MiniFrame = miniFrame
    self.Cursor = cursor
end

function FishingUI:UpdatePowerFill(power: number)
    self.PowerFill.Size = UDim2.new(1, 0, power, 0)
end

function FishingUI:SetMiniGameState(state:boolean)
    self.MiniFrame.Visible = state
end

function FishingUI:SetCursorPostion(udim2: UDim2)
    self.Cursor.Position = udim2
end
function FishingUI:BuildHealthBar(health: number)
    -- Create container next to mini bar
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthBar"
    healthFrame.Size = UDim2.fromOffset(60, 300)
    healthFrame.AnchorPoint = Vector2.new(0, 0.5)
    healthFrame.Position = UDim2.new(0, -45, 0.75, 0) -- to the right of mini bar
    healthFrame.BackgroundTransparency = 1
    healthFrame.Parent = self.MiniFrame

    -- UIListLayout for stacking vertically
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.Parent = healthFrame

    -- store references
    self.HealthFrame = healthFrame
    self.MaxHealth = health
    self.CurrentHealth = health
    self.Hearts = {}
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local heartDecal = ReplicatedStorage:WaitForChild("heart") :: Decal
    -- Create heart icons
    for i = 1, health do
        local heart = Instance.new("ImageLabel")
        heart.Name = "Heart" .. i
        heart.Size = UDim2.fromOffset(24, 24) -- nice small heart
        heart.BackgroundTransparency = 1
        heart.Image = heartDecal.Texture
        heart.ImageRectOffset = Vector2.new(0, 0)
        heart.Parent = healthFrame

        table.insert(self.Hearts, heart)
    end
end

function FishingUI:LoseHealth()
    if not self.CurrentHealth or self.CurrentHealth <= 0 then return end

    -- reduce current health
    self.CurrentHealth -= 1

    -- fade out the lost heart
    local heart = self.Hearts[self.CurrentHealth + 1]
    if heart then
        heart.ImageTransparency = 0.3
        heart.ImageColor3 = Color3.fromRGB(100, 100, 100) -- greyed out
    end
end
return FishingUI
