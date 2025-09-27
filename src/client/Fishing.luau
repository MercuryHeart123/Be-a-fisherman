--!strict
-- Fishing.luau (Client Module)
-- Handles rod swing, raycast to ground, bait spawn, cooldown, previous bait cleanup

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(script.Parent:WaitForChild("types"))

type BaitState = Types.BaitState

-- Now you can use both
local BaitState = Types.BaitState
local Fishing = {}

local isCooldown = false
local lastBait: Instance? = nil

local fishingFolder = ReplicatedStorage:WaitForChild("Fishing")
local fishingCast = fishingFolder:WaitForChild("Cast") :: RemoteEvent
local fishingHooked = fishingFolder:WaitForChild("Hooked") :: RemoteEvent

local onHookedCallback: ((fish: any) -> ())? = nil

-- Roaming/debug state
local roamConn: RBXScriptConnection? = nil
local roamCenter: Vector3? = nil
local roamSize = 24 -- square side length (studs)
local debugBorderParts: {BasePart} = {}

-- Path circles
local pathCircles: {{ part: BasePart, center: Vector3, radius: number, entered: boolean, isPressed: boolean }} = {}
local circleRadius = 1.5
local maxCircles = 5
local circleGap = 0.5 -- extra spacing between circles beyond diameter

local function destroyPathCircles()
	for _, info in ipairs(pathCircles) do
		info.part:Destroy()
	end
	table.clear(pathCircles)
end

local function destroyDebugBorder()
	for _, p in ipairs(debugBorderParts) do
		p:Destroy()
	end
	table.clear(debugBorderParts)
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

local function getBaitPosition(inst: Instance): Vector3
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	else
		return Vector3.new()
	end
end

local function setBaitPosition(inst: Instance, pos: Vector3)
	if inst:IsA("BasePart") then
		inst.Position = pos
	elseif inst:IsA("Model") then
		inst:PivotTo(CFrame.new(pos))
	end
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

local function createPathCircles(startPos: Vector3, endPos: Vector3)
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
		pos = Vector3.new(pos.X, (roamCenter and roamCenter.Y or pos.Y), pos.Z)
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

local function startBaitRoam(center: Vector3)
	roamCenter = center
	createDebugBorder(center)
	if roamConn then roamConn:Disconnect() roamConn = nil end
	
	local currentStart = center
	local currentTarget = center
	local elapsed = 0
	local duration = 1

	local redirectTimer = 0
	local isWarning = false
	local warningTime = 0.2 -- seconds
	local pendingRedirect = false

	local function chooseNewTarget()
		if not roamCenter then return end
		currentStart = getBaitPosition(lastBait :: Instance)
		local half = roamSize / 2
		local target = Vector3.new(
			roamCenter.X + (math.random() * 2 - 1) * half,
			roamCenter.Y,
			roamCenter.Z + (math.random() * 2 - 1) * half
		)
		currentTarget = target
		elapsed = 0
		local dist = (currentTarget - currentStart).Magnitude
		local speed = 6 + math.random() * 6 -- studs/sec
		duration = math.max(0.25, dist / speed)
		createPathCircles(currentStart, currentTarget)
	end
	
	chooseNewTarget()

	roamConn = RunService.Heartbeat:Connect(function(dt)
		if not lastBait then
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
				lastBait.Color = Color3.fromRGB(255, 200, 0) -- 🟡 after redirect
				chooseNewTarget()
			end
		end

		local alpha = math.clamp(elapsed / duration, 0, 1)
		local newPos = currentStart:Lerp(currentTarget, alpha)
		setBaitPosition(lastBait, newPos)
		updatePathCircles(newPos)

		-- Try to redirect every 1 second
		if redirectTimer >= 1 then
			redirectTimer = 0
			if not pendingRedirect and math.random() < 0.25 and alpha < 1 then
				-- ⚠️ Start warning
				pendingRedirect = true
				isWarning = true
				warningTime = 0.5
				lastBait.Color = Color3.fromRGB(255, 0, 0) -- 🔴 warning color
			end
		end

		-- If reached target, pick new one
		if alpha >= 1 and not pendingRedirect then
			chooseNewTarget()
		end
	end)
end

local function stopBaitRoam()
	if roamConn then
		roamConn:Disconnect()
		roamConn = nil
	end
	roamCenter = nil
	destroyDebugBorder()
	destroyPathCircles()
end

function Fishing.onHooked(callback: (fish: any) -> ())
	onHookedCallback = callback
end

function Fishing.clearBait()
	if lastBait then
		lastBait:Destroy()
		lastBait = nil
	end
	stopBaitRoam()
end

local function spawnBaitAt(position: Vector3)
	Fishing.clearBait()

	local baitModel = ReplicatedStorage:FindFirstChild("BaitModel")
	if baitModel and baitModel:IsA("Model") then
		local clone = baitModel:Clone()
		clone:PivotTo(CFrame.new(position + Vector3.new(0, 0.1, 0)))
		clone.Parent = Workspace
		lastBait = clone
		startBaitRoam(position)
		return
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
	lastBait = p
	startBaitRoam(position)
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

fishingHooked.OnClientEvent:Connect(function(fish: any)
	if onHookedCallback then
		onHookedCallback(fish)
	end
end)

function Fishing.trySwingRodWithPower(player: Player, selectedHandIndex: number?, handSlots: {[number]: any}, power01: number?)
	if isCooldown then return end
	if not selectedHandIndex then return end
	local slot = handSlots[selectedHandIndex]
	if not slot or not slot.item or slot.item.Type ~= "rod" then return end
	local p = math.clamp(power01 or 0, 0, 1)
	-- scale distance based on power
	local maxDistance = 20 + p * 50
	
	local ignore: {Instance} = {}
	local char = player.Character
	if char then table.insert(ignore, char) end
	local result = getProjectileLanding(
		char,
		maxDistance,
		Vector3.new(0, -196.2, 0)
	)
	if result then
		spawnBaitAt(result)
		isCooldown = true
		print("start fire")
		fishingCast:FireServer({ position = result, power = p })
		task.delay(0.8, function()
			isCooldown = false
		end)
	end
end

function Fishing.isBaitInsideCircle(): Types.BaitState
	for idx = #pathCircles, 1, -1 do
		local info = pathCircles[idx]
		local dist = (lastBait.Position - info.center).Magnitude

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


return Fishing