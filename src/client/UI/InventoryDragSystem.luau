-- StarterPlayerScripts/Client/UI/InventoryDragSystem.luau
local UserInputService = game:GetService("UserInputService")
local InventoryDragSystem = {}

local inventoryData = nil
local moveInventoryItemRemote = nil
local originalSlotType = nil

-- State variables
local draggingItemData = nil -- SlotData.item
local originalSlotData = nil -- SlotData
local ghostImage = nil -- ImageLabel

function InventoryDragSystem:Init(serverData, remote: RemoteEvent)
	inventoryData = serverData
	moveInventoryItemRemote = remote

	UserInputService.InputChanged:Connect(function(input)
		if ghostImage and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = input.Position
			ghostImage.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if ghostImage and input.UserInputType == Enum.UserInputType.MouseButton1 then
			InventoryDragSystem:EndDrag(input.Position)
		end
	end)
end

-- Called when player starts dragging a slot
function InventoryDragSystem:BeginDrag(slotData, slotType: "inventory" | "hand")
	draggingItemData = slotData.item
	originalSlotData = slotData
	originalSlotType = slotType

	local ghost = Instance.new("ImageLabel")
	ghost.Size = UDim2.fromOffset(slotData.uiSlot.AbsoluteSize.X, slotData.uiSlot.AbsoluteSize.Y)
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.Image = slotData.item.Icon
	ghost.BackgroundTransparency = 1
	ghost.ZIndex = 10

	local parentGui = slotData.uiSlot:FindFirstAncestorOfClass("ScreenGui")
	ghost.Parent = parentGui

	ghostImage = ghost

	local mousePos = UserInputService:GetMouseLocation()
	ghost.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)

	slotData.uiSlot.Image = ""
end

-- Called when player releases mouse
function InventoryDragSystem:EndDrag(mousePos)
	if not draggingItemData or not originalSlotData or not ghostImage then
		return
	end

	local mouseX, mouseY = mousePos.X, mousePos.Y
	local dropTargetFound = false

	local function checkDrop(targetSlots, targetType: "inventory" | "hand")
		for _, slot in pairs(targetSlots) do
			if not slot.uiSlot then
				continue
			end
			local absPos, size = slot.uiSlot.AbsolutePosition, slot.uiSlot.AbsoluteSize
			if
				mouseX >= absPos.X
				and mouseX <= absPos.X + size.X
				and mouseY >= absPos.Y
				and mouseY <= absPos.Y + size.Y
			then
				print(
					`Client: Requesting move from ${originalSlotType}:${originalSlotData.slotId} to ${targetType}:${slot.slotId}`
				)
				moveInventoryItemRemote:FireServer(originalSlotType, originalSlotData.slotId, targetType, slot.slotId)

				dropTargetFound = true
				return true
			end
		end
		return false
	end

	checkDrop(inventoryData.hand, "hand")
	if not dropTargetFound then
		checkDrop(inventoryData.inventory, "inventory")
	end

	if not dropTargetFound then
		originalSlotData.uiSlot.Image = draggingItemData.Icon
	end

	ghostImage:Destroy()
	ghostImage = nil
	draggingItemData = nil
	originalSlotData = nil
	originalSlotType = nil
end

return InventoryDragSystem
