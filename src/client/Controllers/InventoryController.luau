--!strict
-- StarterPlayerScripts/Client/Controllers/InventoryController.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemFactory = require(ReplicatedStorage.Shared.Factories.ItemFactory)
local InventoryService = require(ReplicatedStorage.Shared.Services.Inventory)
local UserController = require(script.Parent.UserController)

-- Optional: UI modules
local InventoryUI = require(script.Parent.Parent.UI.InventoryUI)
local HandUI = require(script.Parent.Parent.UI.HandUI)
local DragSystem = require(script.Parent.Parent.UI.InventoryDragSystem)

-- Create the client-side inventory service
local clientInventory = InventoryService.new(ItemFactory)
local player = UserController:GetLocalUser()
local InventoryController = {}
local SelectedItem = nil
InventoryController.__index = InventoryController

-- Initialize the controller
function InventoryController:Init()
	-- Build the UI
	InventoryUI:BuildSlots(clientInventory.InventoryItems)
	local tempRod = ItemFactory.createRod("test", "rbxassetid://12345678", 1, 123, 10, 5, 2, ReplicatedStorage.Assets.Models:WaitForChild("FishingRodModel"))
	clientInventory:AddItemByIndex("inventory",1,tempRod)
	InventoryUI:UpdateAllSlots(clientInventory.InventoryItems,clientInventory.HandItems)
	if player.Character then
		InventoryUI:SetupCharacterPreview(player)

	end
	player.CharacterAdded:Connect(function()
		InventoryUI:SetupCharacterPreview(player)

	end)
	HandUI:BuildSlots(clientInventory.HandItems)

	DragSystem:Init(clientInventory)

	for _, slot in ipairs(clientInventory.InventoryItems) do
		slot.uiSlot = slot.uiSlot or nil
		if slot.uiSlot then
			slot.uiSlot.MouseButton1Down:Connect(function()
				if not InventoryUI:GetVisible() or not slot.item then
					return
				end
				DragSystem:BeginDrag(slot)
			end)
		end
	end

	for _, slot in ipairs(clientInventory.HandItems) do
		slot.uiSlot = slot.uiSlot or nil
		if slot.uiSlot then
			slot.uiSlot.MouseButton1Down:Connect(function()
				if not InventoryUI:GetVisible() or not slot.item then
					return
				end
				DragSystem:BeginDrag(slot)
			end)
		end
	end


	-- Example: connect key to toggle inventory
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Tab then
			self:ToggleInventory()
		elseif input.KeyCode == Enum.KeyCode.One then
			self:EquipItem(1)
			print("Before fishing, selected item:", InventoryController:GetSelectedItem())

		elseif input.KeyCode == Enum.KeyCode.Two then
			self:EquipItem(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			self:EquipItem(3)
		end
	end)
end

-- Toggle inventory UI
function InventoryController:ToggleInventory()
    local visible = not InventoryUI:GetVisible()
    InventoryUI:SetVisible(visible)
end

local function getRightHand(model: Model): BasePart?
	local part = model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
	if part and part:IsA("BasePart") then return part end
	return nil
end
function InventoryController:EquipItem(selectedIndex: number)
	-- clearEquippedOnPreview()
	if not selectedIndex then return end
	local slot = clientInventory.HandItems[selectedIndex]
	if not slot or not slot.item then return end
	local item = slot.item
	local c = player.Character or player.CharacterAdded:Wait()
	c.Archivable = true
	if not item.Model or not c then return end
	
	local hand = getRightHand(c)
	if not hand then return end
	if item.Type == "rod" then
		UserController:SetSpeedToRun(false)
	else
		UserController:SetSpeedToRun(true)
	end
	local itemClone:Model = item.Model:Clone()
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
			if d:IsA("BasePart") then attach = d break end
		end
	end
	if not attach then return end
	
	-- create a Motor6D from hand to the item
	local motor = Instance.new("Motor6D")
	motor.Name = "ItemGrip"
	motor.Part0 = hand
	motor.Part1 = attach
	motor.C0 = CFrame.new(attach.Size.X/4, -attach.Size.Z/2+ attach.Size.Z*0.2/2, -attach.Size.Y/2 + attach.Size.Y*0.2/2)
	motor.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.pi/2, 0, 0)
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
function InventoryController:SetSelectedItem(item:InventoryService.ItemType)
	SelectedItem = item
end
function InventoryController:GetSelectedItem():InventoryService.ItemType
	return SelectedItem
end

return InventoryController
