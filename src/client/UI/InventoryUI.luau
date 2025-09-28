local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(ReplicatedStorage.Shared.Services.Inventory)

local InventoryUI = {
    characterClone = nil :: Model?,
}

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

-- Set inventory visibility
function InventoryUI:SetVisible(visible: boolean)
	mainFrame.Visible = visible
end

function InventoryUI:GetVisible(): boolean
    return mainFrame.Visible
end

local function clearCharacterClone()
	if characterClone then
		characterClone:Destroy()
		characterClone = nil
	end
end

local function getHumanoidRoot(model: Model): BasePart?
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end
	return nil
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
	
	local hrp = getHumanoidRoot(clone)
	if not hrp then return end
	
	-- camera placement: slightly above and in front looking at upper body
	local lookAt = hrp.Position + Vector3.new(0, 0, 0)
    local camDistance = 24

    -- Camera 180° around Y
    local camOffset = Vector3.new(0, 0, -camDistance) -- negative Z
    previewCamera.CFrame = CFrame.new(lookAt + camOffset, lookAt)
	previewCamera.Parent = worldModel
end

return InventoryUI
