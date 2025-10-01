-- StarterPlayerScripts/Client/UI/InventoryDragSystem.luau
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")

screenGui.Name = "InventoryUI"
screenGui.Parent = playerGui
local InventoryService = require(ReplicatedStorage.Shared.Services.Inventory)
local InventoryDragSystem = {}

-- State variables
local draggingItemData = nil -- SlotData.item
local originalSlotData = nil -- SlotData
local ghostImage = nil -- ImageLabel
local offset = Vector2.new(0, 0)

-- Must be initialized with inventory service
local inventoryService: InventoryService.Type = nil

function InventoryDragSystem:Init(service: InventoryService.Type)
	inventoryService = service
	-- Mouse events
	UserInputService.InputChanged:Connect(function(input)
		if ghostImage and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = input.Position
			ghostImage.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if ghostImage and input.UserInputType == Enum.UserInputType.MouseButton1 then
			print(inventoryService:GetAllInventoryItems())
			self:EndDrag(input.Position)
			print(inventoryService:GetAllInventoryItems())
		end
	end)
end

-- Called when player starts dragging a slot
function InventoryDragSystem:BeginDrag(slotData: InventoryService.SlotData)
	draggingItemData = slotData.item
	originalSlotData = slotData

	local ghost = Instance.new("ImageLabel")
	ghost.Size = UDim2.fromOffset(slotData.uiSlot.AbsoluteSize.X, slotData.uiSlot.AbsoluteSize.Y)
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.Image = slotData.item.Icon
	ghost.BackgroundTransparency = 1
	ghost.ZIndex = 10
	ghost.Parent = screenGui
	ghostImage = ghost

	local mousePos = UserInputService:GetMouseLocation()
	local guiInset = GuiService:GetGuiInset() -- offset from top bar etc.

	-- Adjust so ghost is centered on mouse
	local adjustedX = mousePos.X - guiInset.X
	local adjustedY = mousePos.Y - guiInset.Y

	ghost.Position = UDim2.fromOffset(adjustedX, adjustedY)

	-- slotData.item = nil
	slotData.uiSlot.Image = ""
end

-- Called when player releases mouse
function InventoryDragSystem:EndDrag(mousePos)
	if not draggingItemData or not originalSlotData or not ghostImage then
		return
	end
	local mouseX, mouseY = mousePos.X, mousePos.Y

	local function checkDrop(targetSlots)
		for _, slot in pairs(targetSlots) do
			local absPos, size = slot.uiSlot.AbsolutePosition, slot.uiSlot.AbsoluteSize
			if
				mouseX >= absPos.X
				and mouseX <= absPos.X + size.X
				and mouseY >= absPos.Y
				and mouseY <= absPos.Y + size.Y
			then
				inventoryService:MoveItem(
					originalSlotData == slot and "inventory"
						or (table.find(inventoryService.InventoryItems, originalSlotData) and "inventory" or "hand"),
					originalSlotData.slotId,
					targetSlots == inventoryService.InventoryItems and "inventory" or "hand",
					slot.slotId
				)
				return true
			end
		end
		return false
	end
	-- Try hand slots first
	if not checkDrop(inventoryService.HandItems) then
		-- Then inventory slots
		if not checkDrop(inventoryService.InventoryItems) then
			-- If nowhere valid, return to original
			originalSlotData.item = draggingItemData
			originalSlotData.uiSlot.Image = draggingItemData.Icon
		end
	end

	-- Cleanup
	ghostImage:Destroy()
	ghostImage = nil
	draggingItemData = nil
	originalSlotData = nil
end

return InventoryDragSystem
