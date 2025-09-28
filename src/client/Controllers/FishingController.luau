-- StarterPlayerScripts/Client/Controllers/FishingController.lua
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
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
powerIncrementPerSecond = 1.4 -- Adjust as needed
local roamSize = 24 -- square side length (studs)
local debugBorderParts: {BasePart} = {}
local pathCircles: {{ part: BasePart, center: Vector3, radius: number, entered: boolean, isPressed: boolean }} = {}
local roamConn: RBXScriptConnection? = nil

type BaitState = Types.BaitState
local BaitState = Types.BaitState

function isBaitInsideCircle(bait: Part): Types.BaitState
	for idx = #pathCircles, 1, -1 do
		local info = pathCircles[idx]
		local dist = (bait.Position - info.center).Magnitude

		-- 🟢 Already pressed
		if info.isPressed then
			return BaitState.Pressed
		end

		-- 🟢 Just entered the circle
		if dist <= info.radius then
			info.part.Color = Color3.fromRGB(0, 255, 0)
			info.isPressed = true
			return BaitState.In
		end
	end

	-- ⚪ Not inside any circle
	return BaitState.Out
end

local function handleMinigameInput(actionName, inputState, inputObject, fish: FishItem.Fish, rod: RodItem.Type, bait: Part)
	if inputState == Enum.UserInputState.Begin then
		-- local currentScale = cursor.Position.Y.Scale
		local state = isBaitInsideCircle(bait)
        print("Bait state:", state)
		if state == BaitState.Out  then
			rod.Health = rod.Health - 1
            FishingUI:LoseHealth()
		elseif state == BaitState.In then
			fish.Health = fish.Health - rod.BasePower
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

-- Initialize the controller

function FishingController:Init()
    FishingUI:BuildUI()
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not InventoryController:IsInventoryOpen() then
            local item = InventoryController:GetSelectedItem()
            if item and item.Type == "rod" then
                self:startCharging()
            end
        end
	end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and charging then
            charging = false
            self:TryToSwingRodWithPower(InventoryController:GetSelectedItem(), power)
            power = 0
            FishingUI:UpdatePowerFill(power)
        end
    end)

    -- Update power meter while charging
    RunService.Heartbeat:Connect(function(dt)
        if charging then
            power = math.clamp(power + powerIncrementPerSecond * dt, 0, 1)
            FishingUI:UpdatePowerFill(power)
        end
    end)

    Remotes.FishingCast().OnClientEvent:Connect(function(data)
        print("🐟 You caught:", data.fish)
        startMinigame(data.rod, data.fish, self.bait)
        -- Example: add to inventory
        -- InventoryController:AddItem(data.fish)
        -- FishingUI:ShowCatch(data.fish)
    end)
end

function FishingController:startCharging()
    if not charging then
        charging = true
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
		-- lastBait = clone
		-- startBaitRoam(position)
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
	-- startBaitRoam(position)
end


function FishingController:TryToSwingRodWithPower(rod: RodItem.Type, power: number)
    -- Implement the logic to swing the rod with the given power
    print("Swinging rod:", rod.Name, "with power:", power)
	-- scale distance based on power
	local maxDistance = 20 + power * 50
	
	local ignore: {Instance} = {}
	local char = UserController:GetLocalUser().Character
	if char then table.insert(ignore, char) end
	local result = getProjectileLanding(
		char,
		maxDistance,
		Vector3.new(0, -196.2, 0)
	)
	if result then
        print("Calculated landing position:", result)
		local bait = spawnBaitAt(result)
        self.bait = bait
        self.roamCenter = result
        Remotes.FishingCast():FireServer({
            position = result,    -- where the bait lands
            rod = rod,          -- the rod used
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
    print("Minigame finished. Caught fish:", fish)
    ContextActionService:UnbindAction("MiniGameSpace") -- ปลด bind space กลับมากระโดดได้
    destroyDebugBorder()
    destroyPathCircles()
    if bait then
        bait:Destroy()
        self.bait = nil
    end
    if roamConn then
		roamConn:Disconnect()
		roamConn = nil
	end
    FishingUI:SetMiniGameState(false)
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
