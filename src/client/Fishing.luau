--!strict
-- Fishing.luau (Client Module)
-- Handles rod swing, raycast to ground, bait spawn, cooldown, previous bait cleanup

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fishing = {}

local isCooldown = false
local lastBait: Instance? = nil

function Fishing.clearBait()
	if lastBait then
		lastBait:Destroy()
		lastBait = nil
	end
end

local function spawnBaitAt(position: Vector3)
	Fishing.clearBait()

	local baitModel = ReplicatedStorage:FindFirstChild("BaitModel")
	if baitModel and baitModel:IsA("Model") then
		local clone = baitModel:Clone()
		clone:PivotTo(CFrame.new(position + Vector3.new(0, 0.1, 0)))
		clone.Parent = Workspace
		lastBait = clone
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
	print(landingPos)
	return landingPos
end


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
	print(maxDistance)
	local result = getProjectileLanding(
		char,
		maxDistance,                          -- initial speed (studs/second)
		Vector3.new(0, -196.2, 0)    -- gravity (Roblox default ~ -196.2 
	)
		print(result)
	if result then
		spawnBaitAt(result)
		isCooldown = true
		task.delay(0.8, function()
			isCooldown = false
		end)
	end
end

return Fishing 