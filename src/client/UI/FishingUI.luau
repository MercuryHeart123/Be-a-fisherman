-- StarterPlayerScripts/Client/UI/FishingUI.luau
local FishingUI = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SWEET_SPOT_MIN = 0.6
local SWEET_SPOT_MAX = 0.78
local SWEET_SPOT_LUCK_BONUS = 8

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
    bar.Name = "MiniGameBar"
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

    local arcContainer = Instance.new("Frame")
    arcContainer.Name = "FishingMinigame"
    arcContainer.Size = UDim2.fromOffset(60, 300)
    arcContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    arcContainer.Position = UDim2.new(0.25, 0, 0.4, 0)
    arcContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    arcContainer.BackgroundTransparency = 1
    arcContainer.Visible = false
    arcContainer.Parent = screenGui

    local arcTrack = Instance.new("Frame")
    arcTrack.Name = "ArcTrack"
    arcTrack.Size = UDim2.new(0, 20, 1, -20)
    arcTrack.AnchorPoint = Vector2.new(0.5, 0.5)
    arcTrack.Position = UDim2.new(0.5, 0, 0.5, 0)
    arcTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    arcTrack.BackgroundTransparency = 0.3
    arcTrack.BorderSizePixel = 0
    arcTrack.ClipsDescendants = false
    arcTrack.ZIndex = (powerFrame.ZIndex or 1) + 1
    arcTrack.Parent = arcContainer
    Instance.new("UICorner", arcTrack).CornerRadius = UDim.new(1, 0)

    local cover = Instance.new("ImageLabel")
    cover.Name = "Fishcover"
    cover.Size = UDim2.fromOffset(60, 60) -- bigger fish (overflow bar)
    cover.AnchorPoint = Vector2.new(0.5, 0.5)
    cover.Position = UDim2.new(0.5, 0, 1, 0) -- starts near top
    cover.BackgroundTransparency = 1 -- no background
    cover.Image = "rbxassetid://9400392150" -- 🐟 fish icon
    cover.ImageColor3 = Color3.fromRGB(220, 220, 220)
    cover.ZIndex = arcTrack.ZIndex + 1
    cover.Parent = arcTrack

    local sweetSpotFrame = Instance.new("Frame")
    sweetSpotFrame.Name = "SweetSpot"
    sweetSpotFrame.AnchorPoint = Vector2.new(0.5, 1)
    sweetSpotFrame.Position = UDim2.new(0.5, 0, 1, -2)
    sweetSpotFrame.Size = UDim2.new(1, -4, 0, 0)
    sweetSpotFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 90)
    sweetSpotFrame.BackgroundTransparency = 0.45
    sweetSpotFrame.BorderSizePixel = 0
    sweetSpotFrame.ZIndex = arcTrack.ZIndex
    sweetSpotFrame.Parent = arcTrack
    Instance.new("UICorner", sweetSpotFrame).CornerRadius = UDim.new(1, 0)

    local arcFill = Instance.new("Frame")
    arcFill.Name = "Progress"
    arcFill.AnchorPoint = Vector2.new(0.5, 1)
    arcFill.Position = UDim2.new(0.5, 0, 1, -2)
    arcFill.Size = UDim2.new(1, -4, 0, 0)
    arcFill.BackgroundColor3 = Color3.fromRGB(70, 200, 255)
    arcFill.BackgroundTransparency = 0.1
    arcFill.BorderSizePixel = 0
    arcFill.ZIndex = sweetSpotFrame.ZIndex + 1
    arcFill.Parent = arcTrack
    Instance.new("UICorner", arcFill).CornerRadius = UDim.new(1, 0)

    -- Catch toast (shows after successfully reeling a fish)
    local catchFrame = Instance.new("Frame")
    catchFrame.Name = "CatchToast"
    catchFrame.Size = UDim2.fromOffset(360, 80)
    catchFrame.AnchorPoint = Vector2.new(0.5, 0)
    catchFrame.Position = UDim2.new(0.5, 0, 0.12, 0)
    catchFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    catchFrame.BackgroundTransparency = 0.2
    catchFrame.Visible = false
    catchFrame.Parent = screenGui

    Instance.new("UICorner", catchFrame).CornerRadius = UDim.new(0, 12)

    local catchStroke = Instance.new("UIStroke")
    catchStroke.Color = Color3.fromRGB(255, 255, 255)
    catchStroke.Transparency = 0.4
    catchStroke.Thickness = 1
    catchStroke.Parent = catchFrame

    local catchIcon = Instance.new("ImageLabel")
    catchIcon.Name = "Icon"
    catchIcon.Size = UDim2.fromOffset(52, 52)
    catchIcon.AnchorPoint = Vector2.new(0, 0.5)
    catchIcon.Position = UDim2.new(0, 20, 0.5, 0)
    catchIcon.BackgroundTransparency = 1
    catchIcon.Image = ""
    catchIcon.Parent = catchFrame

    local catchLabel = Instance.new("TextLabel")
    catchLabel.Name = "Message"
    catchLabel.AnchorPoint = Vector2.new(0, 0.5)
    catchLabel.Position = UDim2.new(0, 20 + 52 + 12, 0.5, 0)
    catchLabel.Size = UDim2.new(1, -(20 + 52 + 12 + 20), 0, 48)
    catchLabel.BackgroundTransparency = 1
    catchLabel.Font = Enum.Font.GothamBold
    catchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    catchLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    catchLabel.TextStrokeTransparency = 1
    catchLabel.TextWrapped = true
    catchLabel.TextXAlignment = Enum.TextXAlignment.Left
    catchLabel.TextYAlignment = Enum.TextYAlignment.Center
    catchLabel.TextScaled = true
    catchLabel.Text = ""
    catchLabel.Parent = catchFrame

	self.SweetSpotRange = { min = SWEET_SPOT_MIN, max = SWEET_SPOT_MAX }
	self.SweetSpotLuckBonus = SWEET_SPOT_LUCK_BONUS
	self.PowerArcTrack = arcTrack
	self.PowerArcFill = arcFill
    self.Cover = cover
	self.PowerArcSweetSpot = sweetSpotFrame
	self.ArcFillDefaultColor = arcFill.BackgroundColor3
	self.ArcFillSweetColor = Color3.fromRGB(120, 255, 140)
	self.PowerFillDefaultColor = powerFill.BackgroundColor3
	self.PowerFillSweetColor = self.ArcFillSweetColor

	if self._arcSizeConn then
		self._arcSizeConn:Disconnect()
	end
	self._arcSizeConn = arcTrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:UpdateSweetSpotVisual()
	end)
	self:UpdateSweetSpotVisual()

	-- Store references so you can show/hide later
	self.ScreenGui = screenGui
	self.PowerFrame = powerFrame
	self.PowerFill = powerFill
    self.MiniFrame = miniFrame
    self.ArcContainer = arcContainer
    self.Cursor = cursor
    self.CatchFrame = catchFrame
    self.CatchIcon = catchIcon
    self.CatchLabel = catchLabel
    self.CatchStroke = catchStroke
end

function FishingUI:SetShowLuckyBar(show :boolean)
    self.ArcContainer.Visible = show
end

function FishingUI:UpdatePowerFill(power: number)
    local clamped = math.clamp(power, 0, 1)
    local inSweetSpot = self:IsPowerInSweetSpot(clamped)

    if self.PowerArcFill then
        self.PowerArcFill.Size = UDim2.new(1, -4, clamped, 0)
        self.Cover.Position = UDim2.new(0.5, 0, 1 - clamped, 0)
        if self.ArcFillDefaultColor then
            self.PowerArcFill.BackgroundColor3 = inSweetSpot and (self.ArcFillSweetColor or self.PowerArcFill.BackgroundColor3) or self.ArcFillDefaultColor
        end
    end

    if self.PowerArcSweetSpot then
        self.PowerArcSweetSpot.BackgroundTransparency = inSweetSpot and 0.15 or 0.45
    end

    self.LastPowerValue = clamped
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

function FishingUI:UpdateSweetSpotVisual()
	if not (self.PowerArcTrack and self.PowerArcSweetSpot and self.SweetSpotRange) then
		return
	end

	local trackHeight = self.PowerArcTrack.AbsoluteSize.Y
	if trackHeight <= 0 then
		return
	end

	local minValue = math.clamp(self.SweetSpotRange.min or 0, 0, 1)
	local maxValue = math.clamp(self.SweetSpotRange.max or 0, 0, 1)
	if maxValue < minValue then
		minValue, maxValue = maxValue, minValue
	end

	local span = maxValue - minValue
	local heightPixels = trackHeight * span
	local bottomOffset = trackHeight * minValue

	self.PowerArcSweetSpot.Size = UDim2.new(1, -4, 0, heightPixels)
	self.PowerArcSweetSpot.Position = UDim2.new(0.5, 0, 1, -2 - bottomOffset)
end

function FishingUI:GetSweetSpotRange()
	return self.SweetSpotRange
end

function FishingUI:GetSweetSpotBonus()
	return self.SweetSpotLuckBonus or 0
end

function FishingUI:IsPowerInSweetSpot(power: number?)
	local value = math.clamp(power or self.LastPowerValue or 0, 0, 1)
	local range = self.SweetSpotRange
	if not range then
		return false
	end

	local minValue = math.clamp(range.min or 0, 0, 1)
	local maxValue = math.clamp(range.max or 0, 0, 1)
	if maxValue < minValue then
		minValue, maxValue = maxValue, minValue
	end

	return value >= minValue and value <= maxValue
end

function FishingUI:ShowCatch(fish)
	if not fish or not self.CatchFrame then
		return
	end

	local nameText = fish.Name or "a fish"
	local rarityText = ""
	if fish.Rarity and fish.Rarity ~= "" then
		rarityText = " " .. fish.Rarity
	end
	self.CatchLabel.Text = ("You caught %s%s"):format(nameText, rarityText)

	local icon = fish.Icon
	if typeof(icon) == "string" and icon ~= "" then
		self.CatchIcon.Visible = true
		self.CatchIcon.Image = icon
		self.CatchIcon.ImageTransparency = 0
	else
		self.CatchIcon.Visible = false
		self.CatchIcon.Image = ""
		self.CatchIcon.ImageTransparency = 1
	end

	self.CatchFrame.Visible = true
	self.CatchFrame.BackgroundTransparency = 0.2
	self.CatchLabel.TextTransparency = 0
	self.CatchLabel.TextStrokeTransparency = 0.2
	if self.CatchStroke then
		self.CatchStroke.Transparency = 0.4
	end

	self._catchToken = (self._catchToken or 0) + 1
	local token = self._catchToken
	task.delay(3, function()
		if self._catchToken ~= token then
			return
		end
		if self.CatchFrame then
			self.CatchFrame.Visible = false
		end
	end)
end

return FishingUI
