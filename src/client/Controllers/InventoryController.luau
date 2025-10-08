local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UserController = require(script.Parent.UserController)
local InventoryUI = require(script.Parent.Parent.UI.InventoryUI)
local HandUI = require(script.Parent.Parent.UI.HandUI)
local DragSystem = require(script.Parent.Parent.UI.InventoryDragSystem)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local InventoryService = require(ReplicatedStorage.Shared.Services.Inventory)
local SelectiveSellUI = require(script.Parent.Parent.UI.SelectiveSellUI)

-- Define the type explicitly for clarity
export type ItemType = InventoryService.ItemType

-- Ensure SelectedItem is declared at the top
local SelectedItem: ItemType = nil

local player = UserController:GetLocalUser()
local InventoryController = {}
InventoryController.__index = InventoryController

-- Remote variables
local getInventoryDataRemote = Remotes.GetInventoryData()
local moveInventoryItemRemote = Remotes.MoveInventoryItem()
local inventoryUpdatedRemote = Remotes.InventoryUpdated()

-- Server inventory data
local ServerInventoryData = nil

-- Added a guard variable `isInitialized` to prevent multiple initializations.
-- Updated `Init` to check and set `isInitialized`.
local isInitialized = false

function InventoryController:Init()
	if isInitialized then
		return
	end

	InventoryUI:Create()
	HandUI:Create()
	SelectiveSellUI:Create()

	ServerInventoryData = getInventoryDataRemote:InvokeServer()
	print("Client: Received inventory data!", ServerInventoryData)
	DragSystem:Init(ServerInventoryData, moveInventoryItemRemote)

	if not ServerInventoryData then
		warn("Could not get inventory data from server!")
		return
	end

	-- สร้าง UI จากข้อมูลจริงที่ได้รับมา
	InventoryUI:BuildSlots(ServerInventoryData.inventory, "inventory")
	HandUI:BuildSlots(ServerInventoryData.hand, "hand")
	InventoryUI:UpdateAllSlots(ServerInventoryData.inventory, ServerInventoryData.hand)
	HandUI:UpdateAllSlots(ServerInventoryData.hand)

	-- Setup character preview
	if player.Character then
		InventoryUI:SetupCharacterPreview(player)
	end
	player.CharacterAdded:Connect(function()
		InventoryUI:SetupCharacterPreview(player)
	end)

	DragSystem:Init(ServerInventoryData, moveInventoryItemRemote)

	local function connectSlotEvents(slots, slotType)
		for _, slotData in ipairs(slots) do
			if slotData.uiSlot then
				slotData.uiSlot.MouseButton1Down:Connect(function()
					-- 1. Retrieve SlotId from the attribute
					local slotId = slotData.uiSlot:GetAttribute("SlotId")

					-- 2. Fetch the latest data from ServerInventoryData
					local currentDataForSlot
					if slotType == "inventory" then
						currentDataForSlot = ServerInventoryData.inventory[slotId]
					else
						currentDataForSlot = ServerInventoryData.hand[slotId]
					end

					-- 3. Use the latest data for operations
					if not InventoryUI:GetVisible() or not currentDataForSlot.item then
						return
					end

					DragSystem:BeginDrag(currentDataForSlot, slotType)
				end)
			end
		end
	end

	connectSlotEvents(ServerInventoryData.inventory, "inventory")
	connectSlotEvents(ServerInventoryData.hand, "hand")

	-- จัดการ Input Keyboard
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			-- แก้ไข: เรียกใช้ InventoryController โดยตรง
			InventoryController:ToggleInventory()
		elseif input.KeyCode == Enum.KeyCode.One then
			InventoryController:EquipItem(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			InventoryController:EquipItem(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			InventoryController:EquipItem(3)
		end
	end)

	-- ดักฟังข้อมูลอัปเดตจาก Server
	inventoryUpdatedRemote.OnClientEvent:Connect(function(newData)
		print("Client: Received inventory update from server!")
		print("DEBUG: Data received from server:", newData)

		if ServerInventoryData then
			-- Update Inventory
			for i, newSlotData in ipairs(newData.inventory) do
				if ServerInventoryData.inventory[i] then
					ServerInventoryData.inventory[i].item = newSlotData.item
				end
			end

			-- Update Hand
			for i, newSlotData in ipairs(newData.hand) do
				if ServerInventoryData.hand[i] then
					ServerInventoryData.hand[i].item = newSlotData.item
				end
			end
		else
			-- Emergency case: if ServerInventoryData is missing (should not happen)
			ServerInventoryData = newData
		end

		InventoryUI:UpdateAllSlots(ServerInventoryData.inventory, ServerInventoryData.hand)
		HandUI:UpdateAllSlots(ServerInventoryData.hand)
	end)

	isInitialized = true
	print("✅ InventoryController initialized successfully.")
end

-- Toggle inventory UI
function InventoryController:ToggleInventory()
	local currentVisibility = InventoryUI:GetVisible()
	local newVisibility = not currentVisibility
	print("Setting new visibility to:", newVisibility)
	InventoryUI:SetVisible(newVisibility)
	print("SetVisible has been called.")
end

local function getRightHand(model: Model): BasePart?
	local part = model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

function InventoryController:EquipItem(selectedIndex: number)
	if not selectedIndex or not ServerInventoryData then
		return
	end

	local slot = ServerInventoryData.hand[selectedIndex]
	if not slot or not slot.item then
		return
	end

	local item = slot.item
	local c = player.Character or player.CharacterAdded:Wait()
	c.Archivable = true
	if not item.Model or not c then
		return
	end

	local hand = getRightHand(c)
	if not hand then
		return
	end
	if item.Type == "rod" then
		UserController:SetSpeedToRun(false)
	else
		UserController:SetSpeedToRun(true)
	end
	local itemClone: Model = item.Model:Clone()
	-- make sure all parts are non-colliding for preview
	for _, d in ipairs(itemClone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.Anchored = false
		end
	end
	-- itemClone.Parent = characterClone

	-- choose attach part
	local attach: BasePart? = nil
	if itemClone.PrimaryPart then
		attach = itemClone.PrimaryPart
	else
		for _, d in ipairs(itemClone:GetDescendants()) do
			if d:IsA("BasePart") then
				attach = d
				break
			end
		end
	end
	if not attach then
		return
	end

	-- create a Motor6D from hand to the item
	local motor = Instance.new("Motor6D")
	motor.Name = "ItemGrip"
	motor.Part0 = hand
	motor.Part1 = attach
	motor.C0 = CFrame.new(
		attach.Size.X / 4,
		-attach.Size.Z / 2 + attach.Size.Z * 0.2 / 2,
		-attach.Size.Y / 2 + attach.Size.Y * 0.2 / 2
	)
	motor.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.pi / 2, 0, 0)
	motor.Parent = hand

	attach.Parent = hand

	HandUI:UpdateHandSelectionVisual(selectedIndex)
	self:SetSelectedItem(slot.item)
	-- equippedPreviewModel = attach
	-- equippedMotor = motor
end

function InventoryController:IsInventoryOpen(): boolean
	return InventoryUI:GetVisible()
end

function InventoryController:SetSelectedItem(item: InventoryService.ItemType)
	SelectedItem = item
end
function InventoryController:GetSelectedItem(): InventoryService.ItemType
	return SelectedItem
end

function InventoryController:AddItemToInventory(item: InventoryService.ItemType)
	local slot = ServerInventoryData:AddItemToInventory(item)
	print("Added item to inventory:", item, slot)
	if slot and slot.uiSlot then
		InventoryUI:UpdateSlot(slot)
		return true
	end
	return false
end

function InventoryController:OpenSellUI()
	if not ServerInventoryData then
		return
	end

	print("Client: Opening selective sell UI.")

	local sellItemRemote = Remotes.SellSpecificItem()

	SelectiveSellUI:BuildSellList(ServerInventoryData.inventory, sellItemRemote)

	SelectiveSellUI:SetVisible(true)
end

return InventoryController
