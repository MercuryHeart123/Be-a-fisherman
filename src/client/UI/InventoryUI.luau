local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local InventoryService = require(ReplicatedStorage.Shared.Services.Inventory)

local InventoryUI = {
    characterClone = nil :: Model?,
}

local characterClone: Model?
local cloneNeck: Motor6D?
local defaultNeckC0: CFrame?
local renderStepConnection: RBXScriptConnection?
local MAX_HEAD_YAW = math.rad(40)   -- head can rotate left/right freely
local MAX_BODY_YAW = math.rad(20)   -- body can rotate left/right (small assist)
local BODY_TURN_SPEED = math.rad(8)

local HEAD_YAW_RANGE = math.rad(55)
local HEAD_PITCH_RANGE = math.rad(35)
local currentBodyYaw = 0 -- relative to default facing

local hrp -- set in SetupCharacterPreview
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryUI"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 600, 0, 400)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
mainFrame.Parent = screenGui
mainFrame.Visible = false -- start hidden

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,10)
layout.Parent = mainFrame

-- Left Frame
local leftFrame = Instance.new("Frame")
leftFrame.Size = UDim2.new(0.4,0,1,0)
leftFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
leftFrame.Parent = mainFrame
Instance.new("UICorner", leftFrame).CornerRadius = UDim.new(0,12)

-- Character preview in left panel
local viewport = Instance.new("ViewportFrame")
viewport.Name = "CharacterPreview"
viewport.Size = UDim2.new(1, -20, 1, -20)
viewport.Position = UDim2.new(0, 10, 0, 10)
viewport.BackgroundTransparency = 1
viewport.Ambient = Color3.fromRGB(200, 200, 200)
viewport.LightDirection = Vector3.new(-1, -1, -1)
viewport.Parent = leftFrame

local worldModel = Instance.new("WorldModel")
worldModel.Parent = viewport

local previewCamera = Instance.new("Camera")
previewCamera.FieldOfView = 20
viewport.CurrentCamera = previewCamera

-- Right Frame
local rightFrame = Instance.new("Frame")
rightFrame.Size = UDim2.new(0.6,0,1,0)
rightFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
rightFrame.Parent = mainFrame

Instance.new("UICorner", rightFrame).CornerRadius = UDim.new(0,12)
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0,10)
padding.PaddingBottom = UDim.new(0,10)
padding.PaddingLeft = UDim.new(0,10)
padding.PaddingRight = UDim.new(0,10)
padding.Parent = rightFrame

local rightLayout = Instance.new("UIListLayout")
rightLayout.FillDirection = Enum.FillDirection.Vertical
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Padding = UDim.new(0,10)
rightLayout.Parent = rightFrame

-- Inventory section
local inventoryFrame = Instance.new("Frame")
inventoryFrame.Size = UDim2.new(1,0,1,0)
inventoryFrame.BackgroundTransparency = 1
inventoryFrame.Parent = rightFrame

local grid = Instance.new("UIGridLayout")
grid.FillDirection = Enum.FillDirection.Horizontal
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.CellPadding = UDim2.new(0,0,0,0)
grid.CellSize = UDim2.new(1/5,0,1/5,0)
grid.Parent = inventoryFrame

-- Colors
local SLOT_COLOR = Color3.fromRGB(72, 255, 0)

-- Helper to make a slot button
local function makeSlot(parent: Instance, index: number): ImageButton
	local slot = Instance.new("ImageButton")
	slot.Name = "InventorySlot" .. tostring(index)
	slot.BackgroundColor3 = SLOT_COLOR
	slot.Image = ""
	slot.Parent = parent
	slot.ScaleType = Enum.ScaleType.Fit
	return slot
end

-- Build all slots given inventory & hand items
function InventoryUI:BuildSlots(inventoryItems:{InventoryService.SlotData})
	-- Inventory slots
	for i, slotData in ipairs(inventoryItems) do
		local slot = makeSlot(inventoryFrame, i)
		slotData.uiSlot = slot -- link UI button to SlotData
	end
end

-- Update visual of a single slot
function InventoryUI:UpdateSlot(slotData : InventoryService.SlotData)
	if slotData.uiSlot then
		slotData.uiSlot.Image = slotData.item and slotData.item.Icon or ""
	end
end

-- Update all slots
function InventoryUI:UpdateAllSlots(inventoryItems, handItems)
	for _, slot in ipairs(inventoryItems) do
		self:UpdateSlot(slot)
	end
	for _, slot in ipairs(handItems) do
		self:UpdateSlot(slot)
	end
end

local function resetHeadTracking()
	if cloneNeck and defaultNeckC0 then
		cloneNeck.C0 = defaultNeckC0
	end
end

-- Set inventory visibility
function InventoryUI:SetVisible(visible: boolean)
	mainFrame.Visible = visible
	if not visible then
		resetHeadTracking()
	end
end

function InventoryUI:GetVisible(): boolean
    return mainFrame.Visible
end

local function getHumanoidRoot(model: Model): BasePart?
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end
	return nil
end

local function findNeckJoint(model: Model): Motor6D?
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("Motor6D") and inst.Name == "Neck" then
			return inst
		end
	end
	return nil
end

local function getMouseOffsetForViewport(): Vector2?
	local size = viewport.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return nil
	end

	local mouseLocation = UserInputService:GetMouseLocation()
	local topLeft = viewport.AbsolutePosition

	local u = (mouseLocation.X - topLeft.X) / size.X
	local v = (mouseLocation.Y - topLeft.Y) / size.Y

	local clamped = Vector2.new(math.clamp(u, 0, 1), math.clamp(v, 0, 1))
	return (clamped - Vector2.new(0.5, 0.5)) * 2
end

local function applyHeadTracking()
	if not mainFrame.Visible or not cloneNeck or not defaultNeckC0 then
		return
	end

	local offset = getMouseOffsetForViewport()
	if not offset then
		cloneNeck.C0 = defaultNeckC0
		return
	end

	local desiredYaw = offset.X * HEAD_YAW_RANGE
	local pitch = offset.Y * HEAD_PITCH_RANGE

	-- Head yaw stays inside range
	local headYaw = math.clamp(desiredYaw - currentBodyYaw, -MAX_HEAD_YAW, MAX_HEAD_YAW)

	-- If head tries to look past limit → shift body (within its own limit)
	if headYaw == MAX_HEAD_YAW and desiredYaw > currentBodyYaw + MAX_HEAD_YAW then
		currentBodyYaw = math.clamp(currentBodyYaw + BODY_TURN_SPEED, -MAX_BODY_YAW, MAX_BODY_YAW)
	elseif headYaw == -MAX_HEAD_YAW and desiredYaw < currentBodyYaw - MAX_HEAD_YAW then
		currentBodyYaw = math.clamp(currentBodyYaw - BODY_TURN_SPEED, -MAX_BODY_YAW, MAX_BODY_YAW)
	end

	-- Apply head rotation
	cloneNeck.C0 = defaultNeckC0 * CFrame.Angles(-pitch, headYaw, 0)

	-- Apply small body rotation
	if hrp then
		local pos = hrp.Position
		hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, currentBodyYaw, 0)
	end
end

local function clearCharacterClone()
	if characterClone then
		resetHeadTracking()
		characterClone:Destroy()
		characterClone = nil
		InventoryUI.characterClone = nil
	end
	cloneNeck = nil
	defaultNeckC0 = nil
end

if not renderStepConnection then
	renderStepConnection = RunService.RenderStepped:Connect(function()
		applyHeadTracking()
	end)
end


function InventoryUI:SetupCharacterPreview(pl: Player)
	clearCharacterClone()
	local c = pl.Character or pl.CharacterAdded:Wait()
	c.Archivable = true

	local clone = c:Clone()
	-- strip scripts for safety
	for _, inst in ipairs(clone:GetDescendants()) do
		if inst:IsA("Script") or inst:IsA("LocalScript") then
			inst:Destroy()
		end
	end
    
	clone.Parent = worldModel
	characterClone = clone
	InventoryUI.characterClone = clone

	hrp = getHumanoidRoot(clone)
	if not hrp then return end

	for _, inst in ipairs(clone:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Anchored = (inst.Name == "HumanoidRootPart") -- only anchor HRP
			inst.CanCollide = false
			inst.AssemblyLinearVelocity = Vector3.zero
			inst.AssemblyAngularVelocity = Vector3.zero
		end
	end

	cloneNeck = findNeckJoint(clone)
	if cloneNeck then
		defaultNeckC0 = cloneNeck.C0
		resetHeadTracking()
	end

	-- camera placement: slightly above and in front looking at upper body
	local lookAt = hrp.Position + Vector3.new(0, 0, 0)
    local camDistance = 24

    -- Camera 180° around Y
    local camOffset = Vector3.new(0, 0, -camDistance) -- negative Z
    previewCamera.CFrame = CFrame.new(lookAt + camOffset, lookAt)
	previewCamera.Parent = worldModel
end

return InventoryUI
