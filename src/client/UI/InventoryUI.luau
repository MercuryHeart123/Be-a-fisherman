local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local InventoryService = require(ReplicatedStorage.Shared.Services.Inventory)

-- Declare UI elements here so they can be accessed by all functions in the module
local screenGui: ScreenGui
local mainFrame: Frame
local inventoryFrame: Frame
local handFrame: Frame -- Assuming you will create this later
local viewport: ViewportFrame
local worldModel: WorldModel
local previewCamera: Camera

local uiSlotsInventory = {}
local uiSlotsHand = {}

local characterClone: Model?
local cloneNeck: Motor6D?
local defaultNeckC0: CFrame?
local renderStepConnection: RBXScriptConnection?

-- Constants for head tracking
local HEAD_YAW_RANGE = math.rad(55)
local HEAD_PITCH_RANGE = math.rad(35)

local InventoryUI = {}

function InventoryUI:Create()
	if screenGui then
		return
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 400) -- ลดขนาดความกว้างเป็น 600 และความสูงเป็น 400
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200) -- ปรับตำแหน่งกึ่งกลางตามขนาดใหม่ (0.5 - (600/2), 0.5 - (400/2))
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	-- Use a layout to manage left and right frames automatically
	local mainLayout = Instance.new("UIListLayout")
	mainLayout.FillDirection = Enum.FillDirection.Horizontal
	mainLayout.Parent = mainFrame

	-- ===== All UI creation code is moved inside Create() function =====

	-- Left Frame (Character Preview)
	local leftFrame = Instance.new("Frame")
	leftFrame.LayoutOrder = 1
	leftFrame.Size = UDim2.new(0.4, 0, 1, 0)
	leftFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	leftFrame.BorderSizePixel = 0
	leftFrame.Parent = mainFrame
	Instance.new("UICorner", leftFrame).CornerRadius = UDim.new(0, 12)

	-- Character preview in left panel
	viewport = Instance.new("ViewportFrame")
	viewport.Name = "CharacterPreview"
	viewport.Size = UDim2.new(1, -20, 1, -20)
	viewport.Position = UDim2.new(0, 10, 0, 10)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Parent = leftFrame

	worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	previewCamera = Instance.new("Camera")
	previewCamera.FieldOfView = 20
	viewport.CurrentCamera = previewCamera
	previewCamera.Parent = worldModel -- Parent camera to WorldModel as well

	-- Right Frame (Inventory)
	local rightFrame = Instance.new("Frame")
	rightFrame.LayoutOrder = 2
	rightFrame.Size = UDim2.new(0.6, 0, 1, 0)
	rightFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	rightFrame.BorderSizePixel = 0
	rightFrame.Parent = mainFrame

	Instance.new("UICorner", rightFrame).CornerRadius = UDim.new(0, 12)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = rightFrame

	-- Inventory section
	inventoryFrame = Instance.new("Frame")
	inventoryFrame.Size = UDim2.new(1, 0, 1, 0) -- Adjust size as needed
	inventoryFrame.BackgroundTransparency = 1
	inventoryFrame.Parent = rightFrame

	-- ในไฟล์ InventoryUI.lua ภายในฟังก์ชัน InventoryUI:Create()
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 60, 0, 60) -- ปรับขนาด Cell Size ให้เล็กลงเล็กน้อย
	grid.CellPadding = UDim2.new(0, 4, 0, 4) -- ปรับ Cell Padding ให้เล็กลง
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = inventoryFrame
	grid.SortOrder = Enum.SortOrder.LayoutOrder

	-- Ensure RenderStepped is connected for head tracking
	if not renderStepConnection then
		renderStepConnection = RunService.RenderStepped:Connect(function()
			self:applyHeadTracking()
		end)
	end
end

function InventoryUI:BuildSlots(inventoryData, slotType: "inventory" | "hand")
	if not screenGui then
		self:Create()
	end

	local targetFrame = (slotType == "inventory") and inventoryFrame or handFrame
	if not targetFrame then
		warn("Target frame for slot type '" .. slotType .. "' not found!")
		return
	end

	local targetTable = (slotType == "inventory") and uiSlotsInventory or uiSlotsHand

	for _, button in ipairs(targetTable) do
		button:Destroy()
	end
	table.clear(targetTable)

	for i, slotData in ipairs(inventoryData) do
		local newSlotButton = Instance.new("ImageButton")
		newSlotButton.Name = slotType .. "_Slot_" .. i
		newSlotButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		newSlotButton.BackgroundTransparency = 0.5
		newSlotButton.Parent = targetFrame
		Instance.new("UICorner", newSlotButton).CornerRadius = UDim.new(0, 8)

		newSlotButton:SetAttribute("SlotId", i)
		newSlotButton:SetAttribute("SlotType", slotType)

		targetTable[i] = newSlotButton
		slotData.uiSlot = newSlotButton
	end
end

function InventoryUI:UpdateSlot(slotData: InventoryService.SlotData)
	if slotData and slotData.uiSlot then
		slotData.uiSlot.Image = slotData.item and slotData.item.Icon or ""
	end
end

function InventoryUI:UpdateAllSlots(newInventoryData, newHandData)
	print("UI: Updating all slots with new data...")

	for i, uiSlotButton in ipairs(uiSlotsInventory) do
		local correspondingData = newInventoryData[i]
		if correspondingData and correspondingData.item then
			uiSlotButton.Image = correspondingData.item.Icon
		else
			uiSlotButton.Image = ""
		end
	end

	-- Handle hand slots if they exist
	if newHandData and uiSlotsHand then
		for i, uiSlotButton in ipairs(uiSlotsHand) do
			local correspondingData = newHandData[i]
			if correspondingData and correspondingData.item then
				uiSlotButton.Image = correspondingData.item.Icon
			else
				uiSlotButton.Image = ""
			end
		end
	end
end

local function resetHeadTracking()
	if cloneNeck and defaultNeckC0 then
		cloneNeck.C0 = defaultNeckC0
	end
end

function InventoryUI:SetVisible(visible: boolean)
	if mainFrame then
		mainFrame.Visible = visible
	end
end

function InventoryUI:GetVisible(): boolean
	if mainFrame then
		return mainFrame.Visible
	end
	return false
end

-- Helper functions for character preview
local function getHumanoidRoot(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart")
end

local function findNeckJoint(model: Model): Motor6D?
	return model:FindFirstChild("Head", true):FindFirstChild("Neck", true)
end

local function getMouseOffsetForViewport(): Vector2?
	if not viewport then
		return nil
	end
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

function InventoryUI:applyHeadTracking()
	if not mainFrame or not mainFrame.Visible or not cloneNeck or not defaultNeckC0 then
		return
	end

	local offset = getMouseOffsetForViewport()
	if not offset then
		cloneNeck.C0 = defaultNeckC0
		return
	end

	local yaw = -offset.X * HEAD_YAW_RANGE
	local pitch = offset.Y * HEAD_PITCH_RANGE
	cloneNeck.C0 = defaultNeckC0 * CFrame.Angles(-pitch, -yaw, 0)
end

local function clearCharacterClone()
	if characterClone then
		resetHeadTracking()
		characterClone:Destroy()
		characterClone = nil
	end
	cloneNeck = nil
	defaultNeckC0 = nil
end

function InventoryUI:SetupCharacterPreview(pl: Player)
	-- Ensure UI is created first
	if not worldModel then
		warn("Cannot setup character preview because UI has not been created.")
		return
	end

	clearCharacterClone()
	local c = pl.Character or pl.CharacterAdded:Wait()
	c.Archivable = true

	local newClone = c:Clone()
	-- Strip scripts and other unwanted instances
	for _, inst in ipairs(newClone:GetDescendants()) do
		if inst:IsA("Script") or inst:IsA("LocalScript") then
			inst:Destroy()
		end
	end

	newClone.Parent = worldModel
	characterClone = newClone

	local hrp = getHumanoidRoot(newClone)
	if not hrp then
		return
	end

	hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180), 0)

	-- Make sure everything is unanchored except the HRP and non-collidable
	for _, part in ipairs(newClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = (part == hrp)
			part.CanCollide = false
		end
	end

	cloneNeck = findNeckJoint(newClone)
	if cloneNeck then
		defaultNeckC0 = cloneNeck.C0
		resetHeadTracking()
	end

	-- Camera placement
	local lookAt = hrp.Position

	-- ระยะห่างของกล้อง (เพิ่มค่านี้เพื่อให้ซูมออก)
	local camDistance = 25 -- << ลองปรับค่านี้ดูได้ครับ ถ้าอยากให้ไกลขึ้นอีกก็เพิ่มค่านี้

	-- ตำแหน่งของกล้อง: เริ่มจากจุดที่มอง (lookAt) แล้วขยับขึ้นเล็กน้อย และถอยหลังตามระยะ camDistance
	local camPosition = lookAt + Vector3.new(0, 1, camDistance)

	-- ตั้งค่า CFrame ของกล้อง
	previewCamera.CFrame = CFrame.new(camPosition, lookAt)
end

return InventoryUI
