-- StarterPlayerScripts/Client/UI/HandUI.luau
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(ReplicatedStorage.Shared.Services.Inventory)
local HandUI = {}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.Parent = playerGui

local handBar = Instance.new("Frame")
handBar.Name = "HandBar"
handBar.Size = UDim2.new(0, 230, 0, 80)
handBar.AnchorPoint = Vector2.new(0.5, 1)
handBar.Position = UDim2.new(0.5, 0, 1, -20)
handBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
handBar.BackgroundTransparency = 0.2
handBar.Parent = screenGui

Instance.new("UICorner", handBar).CornerRadius = UDim.new(0,12)
local handBarPadding = Instance.new("UIPadding")
handBarPadding.PaddingTop = UDim.new(0,8)
handBarPadding.PaddingBottom = UDim.new(0,8)
handBarPadding.PaddingLeft = UDim.new(0,8)
handBarPadding.PaddingRight = UDim.new(0,8)
handBarPadding.Parent = handBar

local handBarLayout = Instance.new("UIListLayout")
handBarLayout.FillDirection = Enum.FillDirection.Horizontal
handBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
handBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
handBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
handBarLayout.Padding = UDim.new(0,8)
handBarLayout.Parent = handBar

-- Keep track of hand slots
local handSlots: {[number]: ImageButton} = {}

-- Helper to create a hand slot
local SLOT_COLOR = Color3.fromRGB(72, 255, 0)
local HAND_DEFAULT_COLOR = Color3.fromRGB(255, 0, 0)
local HAND_SELECTED_COLOR = Color3.fromRGB(255, 200, 0)

local function makeSlot(parent: Instance, index: number)
	local slot = Instance.new("ImageButton")
	slot.Name = "HandSlot" .. tostring(index)
	slot.BackgroundColor3 = SLOT_COLOR
	slot.Parent = parent
	slot.ScaleType = Enum.ScaleType.Fit
	slot.Image = ""
	slot.Size = UDim2.fromOffset(64, 64)

	return slot
end

function HandUI:BuildSlots(handItems:{InventoryService.SlotData})
	-- Inventory slots
	for i, slotData in ipairs(handItems) do
		local slot = makeSlot(handBar, i)
		handSlots[i] = slot
		slotData.uiSlot = slot -- link UI button to SlotData
	end
end
-- Update slot image
function HandUI:UpdateHandSlot(index: number, item)
	local slot = handSlots[index]
	if slot then
		slot.Image = item and item.Icon or ""
	end
end

function HandUI:UpdateHandSelectionVisual(index: number)
	for i, s in pairs(handSlots) do
		local isSelected = (index == i)
		s.BorderColor3 = isSelected and HAND_SELECTED_COLOR or HAND_DEFAULT_COLOR
	end
end
-- Update all hand slots
function HandUI:UpdateHandSlots(handItems)
	for i, slotData in ipairs(handItems) do
		self:UpdateHandSlot(i, slotData.item)
	end
end

return HandUI
