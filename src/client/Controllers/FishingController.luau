-- StarterPlayerScripts/Client/Controllers/FishingController.lua
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Types = require(script.Parent.Parent.Types)

local FishingUI = require(script.Parent.Parent.UI.FishingUI)
local InventoryController = require(script.Parent.InventoryController)
local UserController = require(script.Parent.UserController)
local RodItem = require(game.ReplicatedStorage.Shared.Models.RodItem)
local FishItem = require(game.ReplicatedStorage.Shared.Models.FishItem)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local FishingController = {}
FishingController.__index = FishingController
charging = false
power = 0
bait = nil
powerIncrementPerSecond = 1.4 -- Adjust as needed
local roamSize = 24 -- square side length (studs)
local debugBorderParts: {BasePart} = {}
local pathCircles: {{ part: BasePart, center: Vector3, radius: number, entered: boolean, isPressed: boolean }} = {}
local roamConn: RBXScriptConnection? = nil

type BaitState = Types.BaitState
local BaitState = Types.BaitState
local function showDamageText(circlePart: BasePart?, damage: number)
	if not circlePart or damage <= 0 then
		return
	end

	local displayValue = math.floor(damage + 0.5)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamagePop"
	billboard.Size = UDim2.fromOffset(80, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local label = Instance.new("TextLabel")
	label.Name = "DamageText"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = string.format("-%d", displayValue)
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextStrokeColor3 = Color3.new()
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard

	billboard.Parent = circlePart

	local riseTween = TweenService:Create(
		billboard,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = billboard.StudsOffsetWorldSpace + Vector3.new(0, 1, 0) }
	)
	riseTween:Play()

	local fadeTween = TweenService:Create(
		label,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		if billboard then
			billboard:Destroy()
		end
	end)
end

local function showMissHeart(worldPos: Vector3?)
	if not worldPos then
		return
	end

	local anchor = Instance.new("Part")
	anchor.Name = "MissHeartAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = CFrame.new(worldPos)
	anchor.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MissHeart"
	billboard.Size = UDim2.fromOffset(70, 70)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local label = Instance.new("TextLabel")
	label.Name = "HeartText"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = "❤"
	label.TextColor3 = Color3.fromRGB(255, 110, 150)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Parent = billboard

	billboard.Parent = anchor

	local riseTween = TweenService:Create(
		billboard,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = billboard.StudsOffsetWorldSpace + Vector3.new(0, 1.2, 0) }
	)
	riseTween:Play()

	local fadeTween = TweenService:Create(
		label,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	fadeTween:Play()

	local function cleanup()
		if anchor then
			anchor:Destroy()
			anchor = nil
		end
	end

	fadeTween.Completed:Connect(cleanup)
	task.delay(1.2, cleanup)
end

function isBaitInsideCircle(bait: Part): (Types.BaitState, BasePart?)
	for idx = #pathCircles, 1, -1 do
		local info = pathCircles[idx]
		local dist = (bait.Position - info.center).Magnitude

		-- 🟢 Already pressed
		if info.isPressed then
			return BaitState.Pressed, info.part
		end

		-- 🟢 Just entered the circle
		if dist <= info.radius then
			info.part.Color = Color3.fromRGB(0, 255, 0)
			info.isPressed = true
			return BaitState.In, info.part
		end
	end

	-- ⚪ Not inside any circle
	return BaitState.Out, nil
end

local function handleMinigameInput(actionName, inputState, inputObject, fish: FishItem.Fish, rod: RodItem.Type, bait: Part)
	if inputState == Enum.UserInputState.Begin then
		local state, circlePart = isBaitInsideCircle(bait)
		if state == BaitState.Out  then
			rod.Health = rod.Health - 1
            FishingUI:LoseHealth()
			showMissHeart(bait.Position)
		elseif state == BaitState.In then
			local damage = math.max(0, rod.BasePower or 0)
			fish.Health = fish.Health - damage
			showDamageText(circlePart, damage)
		elseif state == BaitState.Pressed then
		end
		-- เด้ง cursor ขึ้น - jumpScale
		-- local newPos = math.clamp(step, 0, 1)
        local health = math.clamp(fish.Health, 0, fish.MaxHelth)
        local pos = health / fish.MaxHelth
        FishingUI:SetCursorPostion(UDim2.new(0.5, 0, pos, 0))
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function startMinigame(rod: RodItem.Type,fish: FishItem.Fish, bait: Part)
    local miniActive = true
	FishingUI:SetMiniGameState(true)
	FishingController:startBaitRoam(bait)
	FishingUI:BuildHealthBar(rod.Health)
    ContextActionService:BindAction(
        "MiniGameSpace",
        function(actionName, inputState, inputObject)
            handleMinigameInput(actionName, inputState, inputObject, fish, rod, bait)
        end,
        false,
        Enum.KeyCode.Space
    )

    FishingUI:SetCursorPostion(UDim2.new(0.5, 0, fish.Health/fish.MaxHelth, 0))

	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		if not miniActive then
			connection:Disconnect()
			return
		end

		-- -- ถ้ายังไม่ถึง top ให้เคลื่อน
		-- if not reachedTopTime then
		-- 	pos = pos + speed * dt
		-- 	if pos >= 1 then
		-- 		pos = 1
		-- 		reachedTopTime = tick()
		-- 	end
		-- 	cursor.Position = UDim2.new(0.5, 0, pos, 0)
		-- else
		-- 	-- ถ้าอยู่บนสุดแล้ว 0.2 วิผ่านไป → จบเกม
		-- 	if tick() - reachedTopTime >= 0.2 then
		-- 		connection:Disconnect()
		-- 		if miniActive then
		-- 			finishMinigame(false)
		-- 		end
		-- 	end
		-- end

		if fish.Health <= 0 then
			connection:Disconnect()
			fish.Health = 0
				if miniActive then
					FishingController:finishMinigame(fish, bait)
                    miniActive = false
				end
		end

        -- auto lose condition: rod breaks
        if rod.Health <= 0 then
            connection:Disconnect()
                if miniActive then
                    FishingController:finishMinigame(nil,bait)
                    miniActive = false
                end
        end
	end)
end


function FishingController:Init()
    FishingUI:BuildUI()
    
    self:ReadyToCast()
    -- Update power meter while charging
    RunService.Heartbeat:Connect(function(dt)
        if charging then
            power = math.clamp(power + powerIncrementPerSecond * dt, 0, 1)
            FishingUI:UpdatePowerFill(power)
        end
    end)

    Remotes.FishingCast().OnClientEvent:Connect(function(data)
        startMinigame(data.rod, data.fish, bait)
        -- Example: add to inventory
        -- InventoryController:AddItem(data.fish)
        -- FishingUI:ShowCatch(data.fish)
    end)
end

-- Initialize the controller
function FishingController:ReadyToCast()
    ContextActionService:BindAction(
	"RodSwing",
	function(_, inputState)
		if inputState == Enum.UserInputState.Begin and not InventoryController:IsInventoryOpen() then
			local item = InventoryController:GetSelectedItem()
			if item and item.Type == "rod" then
				self:startCharging()
			end
		elseif inputState == Enum.UserInputState.End and charging then
			charging = false
			FishingUI:SetShowLuckyBar(false)
			self:TryToSwingRodWithPower(InventoryController:GetSelectedItem(), power)
			power = 0
			FishingUI:UpdatePowerFill(power)

			return ContextActionService:UnbindAction("RodSwing")
		end
	end,
	false,
	Enum.KeyCode.Space
)
end

function FishingController:startCharging()
    if not charging then
        charging = true
        FishingUI:SetShowLuckyBar(true)
        power = 0
        FishingUI:UpdatePowerFill(power)
    end
end


local function getProjectileLanding(char: Model, initialSpeed: number, gravity: Vector3): Vector3?
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local origin = hrp.Position
	local velocity = hrp.CFrame.LookVector * initialSpeed

	-- Quadratic solve for time when projectile hits Y = 0
	local a = 0.5 * gravity.Y
	local b = velocity.Y
	local c = origin.Y

	-- Discriminant
	local discriminant = b*b - 4*a*c
	if discriminant < 0 then
		return nil -- no real solution (never lands)
	end

	-- Positive root (time)
	local t = (-b - math.sqrt(discriminant)) / (2*a)
	if t < 0 then
		t = (-b + math.sqrt(discriminant)) / (2*a)
	end
	if t < 0 then
		return nil -- never lands in positive time
	end

	-- Plug back into full formula: p = p0 + v*t + 0.5*a*t^2
	local landingPos = origin + velocity * t + 0.5 * gravity * t * t
	return landingPos
end


local function spawnBaitAt(position: Vector3)
	local baitModel = ReplicatedStorage:FindFirstChild("BaitModel")
	if baitModel and baitModel:IsA("Model") then
		local clone = baitModel:Clone()
		clone:PivotTo(CFrame.new(position + Vector3.new(0, 0.1, 0)))
		clone.Parent = Workspace
		return clone
	end

	local p = Instance.new("Part")
	p.Name = "Bait"
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.Shape = Enum.PartType.Ball
	p.Color = Color3.fromRGB(255, 200, 0)
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Position = position + Vector3.new(0, 0.1, 0)
	p.Parent = Workspace
	return p
end


function FishingController:TryToSwingRodWithPower(rod: RodItem.Type, power: number)
    -- Implement the logic to swing the rod with the given power
    local clampedPower = math.clamp(power or 0, 0, 1)
	-- scale distance based on power
	local maxDistance = 20 + clampedPower * 50

	local inSweetSpot = FishingUI:IsPowerInSweetSpot(clampedPower)
	local bonusLuck = inSweetSpot and FishingUI:GetSweetSpotBonus() or 0
	
	local ignore: {Instance} = {}
	local char = UserController:GetLocalUser().Character
	if char then table.insert(ignore, char) end
	local result = getProjectileLanding(
		char,
		maxDistance,
		Vector3.new(0, -196.2, 0)
	)
	if result then
        bait = spawnBaitAt(result)
        self.roamCenter = result

        Remotes.FishingCast():FireServer({
            position = result,    -- where the bait lands
            rod = rod,          -- the rod used
            bonusLuck = bonusLuck,
        })
		-- task.delay(0.8, function()
		-- 	isCooldown = false
		-- end)
	end
end
local function destroyDebugBorder()
	for _, p in ipairs(debugBorderParts) do
		p:Destroy()
	end
	table.clear(debugBorderParts)
end
local function destroyPathCircles()
	for _, info in ipairs(pathCircles) do
		info.part:Destroy()
	end
	table.clear(pathCircles)
end
function FishingController:finishMinigame(fish: FishItem.Fish?, bait: Part?)
    ContextActionService:UnbindAction("MiniGameSpace") -- ปลด bind space กลับมากระโดดได้
    destroyDebugBorder()
    destroyPathCircles()
    if bait then
        bait:Destroy()
        bait = nil
    end
    if roamConn then
		roamConn:Disconnect()
		roamConn = nil
	end
    FishingUI:SetMiniGameState(false)
    if fish then
        FishingUI:ShowCatch(fish)
    end
    self:ReadyToCast()

	if fish then
		-- Example: add to inventory
		print("Caught fish:", fish)
		InventoryController:AddItemToInventory(fish)

	end
    -- if success and miniResultFish then
    -- 	-- addFishToInventory(miniResultFish)
    -- end

end



local function createDebugBorder(center: Vector3)
	destroyDebugBorder()
	local half = roamSize/2
	local y = center.Y + 0.05
	local thickness = 0.2
	local color = Color3.fromRGB(255, 0, 0)

	local function mk(pos: Vector3, size: Vector3)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Color = color
		part.Material = Enum.Material.Neon
		part.Size = size
		part.CFrame = CFrame.new(pos)
		part.Name = "BaitBorder"
		part.Parent = Workspace
		table.insert(debugBorderParts, part)
	end

	-- four edges of the square aligned to world axes
	mk(center + Vector3.new(0, y - center.Y, -half), Vector3.new(roamSize, thickness, thickness))
	mk(center + Vector3.new(0, y - center.Y, half), Vector3.new(roamSize, thickness, thickness))
	mk(center + Vector3.new(-half, y - center.Y, 0), Vector3.new(thickness, thickness, roamSize))
	mk(center + Vector3.new(half, y - center.Y, 0), Vector3.new(thickness, thickness, roamSize))
end

local function createCircleMarker(center: Vector3, radius: number)
	local part = Instance.new("Part")
	part.Name = "BaitPathCircle"
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Plastic
	part.Color = Color3.fromRGB(255, 255, 255)
	part.Shape = Enum.PartType.Cylinder
	-- Make a flat disc on the ground. Cylinder axis is along X in Roblox; rotate so axis points up (Y)
	part.Size = Vector3.new(0, radius*2,radius*2)
	part.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	part.Parent = Workspace
	return part
end
function FishingController:createPathCircles(startPos: Vector3, endPos: Vector3, maxCircles: number, circleRadius: number, circleGap: number)
	destroyPathCircles()
	local total = (endPos - startPos)
	local len = total.Magnitude
	if len < 1e-3 then return end
	local dir = total.Unit
	-- enforce spacing between circles: at least diameter + gap
	local minStep = (circleRadius * 2) + circleGap
	local maxCountBySpacing = math.max(1, math.floor(len / minStep))
	local count = math.min(maxCircles, maxCountBySpacing)
	if count <= 0 then return end
	-- place circles with equal spacing based on count
	local step = len / (count + 1)
	for i = 1, count do
		local n =  math.random()
		if n >= 0.75 then
			continue
		end
		local distAlong = step * i
		local pos = startPos + dir * distAlong
		pos = Vector3.new(pos.X, (self.roamCenter and self.roamCenter.Y or pos.Y), pos.Z)
		local p = createCircleMarker(pos, circleRadius)
		table.insert(pathCircles, { part = p, center = pos, radius = circleRadius, entered = false })
	end
end

local function updatePathCircles(baitPos: Vector3)
	-- remove circles that have been entered and then exited
	for idx = #pathCircles, 1, -1 do
		local info = pathCircles[idx]
		local dist = (baitPos - info.center).Magnitude
		if not info.entered then
			if dist <= info.radius then
				info.entered = true
			end
		else
			if dist > info.radius then
				info.part:Destroy()
				table.remove(pathCircles, idx)
			end
		end
	end
end
function FishingController:startBaitRoam(bait: Part)
    local center = bait.Position
	print("Starting bait roam at:", center)
	createDebugBorder(center)
	if roamConn then roamConn:Disconnect() roamConn = nil end
	
	local currentStart = center
	local currentTarget = center
	local elapsed = 0
	local duration = 1

	local redirectTimer = 0
	local warningTime = 0.2 -- seconds
	local pendingRedirect = false

	local function chooseNewTarget(now)
		if not center then return end
		currentStart = now
		local half = roamSize / 2
		local target = Vector3.new(
			center.X + (math.random() * 2 - 1) * half,
			center.Y,
			center.Z + (math.random() * 2 - 1) * half
		)
		currentTarget = target
		elapsed = 0
		local dist = (currentTarget - currentStart).Magnitude
		local speed = 6 + math.random() * 6 -- studs/sec
		duration = math.max(0.25, dist / speed)
		FishingController:createPathCircles(currentStart, currentTarget,5, 2, 1)
	end
	
	chooseNewTarget(currentStart)

	roamConn = RunService.Heartbeat:Connect(function(dt)
		if not bait then
			if roamConn then
				roamConn:Disconnect()
				roamConn = nil
			end
			return
		end

		elapsed += dt
		redirectTimer += dt

		-- Handle pending redirect after warning
		if pendingRedirect then
			warningTime -= dt
			if warningTime <= 0 then
				pendingRedirect = false
				isWarning = false
				bait.Color = Color3.fromRGB(255, 200, 0) -- 🟡 after redirect
				chooseNewTarget(bait.Position)
			end
		end

		local alpha = math.clamp(elapsed / duration, 0, 1)
		local newPos = currentStart:Lerp(currentTarget, alpha)
		bait.Position = newPos
		updatePathCircles(newPos)

		-- Try to redirect every 1 second
		if redirectTimer >= 1 then
			redirectTimer = 0
			if not pendingRedirect and math.random() < 0.25 and alpha < 1 then
				-- ⚠️ Start warning
				pendingRedirect = true
				isWarning = true
				warningTime = 0.5
				bait.Color = Color3.fromRGB(255, 0, 0) -- 🔴 warning color
			end
		end

		-- If reached target, pick new one
		if alpha >= 1 and not pendingRedirect then
			chooseNewTarget(bait.Position)
		end
	end)
end

return FishingController
