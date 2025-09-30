-- StarterPlayerScripts/Client/Controllers/CameraController.lua
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraController = {}
CameraController.__index = CameraController

local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer
local connection: RBXScriptConnection? = nil

-- Config
local distance = 30
local angle = Vector2.new(30, 0) -- (vertical tilt, horizontal orbit)
local centerOffset = Vector3.new(0, 0, 0)

-- store original camera state
local originalCF: CFrame? = nil
local originalType: Enum.CameraType? = nil

local function updateCamera(center: Vector3)
	camera.CameraType = Enum.CameraType.Scriptable

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local targetCenter = center + centerOffset

	-- convert angle to radians
	local vertical = math.rad(angle.X)
	local horizontal = math.rad(angle.Y)

	-- offset relative to HRP orientation
	local baseCF = hrp.CFrame
	local offsetDir = baseCF * CFrame.Angles(0, horizontal, 0) * CFrame.Angles(-vertical, 0, 0)

	local offset = offsetDir.LookVector * distance
	local camPos = targetCenter + offset

	camera.CFrame = CFrame.lookAt(camPos, targetCenter, Vector3.yAxis)
end

function CameraController:LookAtCenter(center: Vector3, newDistance: number?, newAngle: Vector2?)
	if newDistance then distance = newDistance end
	if newAngle then angle = newAngle end

	-- ✅ save original camera state once
	if not originalCF then
		originalCF = camera.CFrame
		originalType = camera.CameraType
	end

	if connection then connection:Disconnect() end
	connection = RunService.RenderStepped:Connect(function()
		updateCamera(center)
	end)
end

function CameraController:ClearTarget()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	-- ✅ restore camera to original position/type
	if originalCF and originalType then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = originalCF
		camera.CameraType = originalType
	else
		-- fallback
		camera.CameraType = Enum.CameraType.Custom
	end

	-- reset stored state
	originalCF = nil
	originalType = nil
end

return CameraController
