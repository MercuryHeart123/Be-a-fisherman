-- InventoryService.lua
local ItemFactory = require(game.ReplicatedStorage.Shared.Factories.ItemFactory)
local RodItem = require(game.ReplicatedStorage.Shared.Models.RodItem)
local ConsumableItem = require(game.ReplicatedStorage.Shared.Models.ConsumableItem)

-- Define the full InventoryService type (methods + fields)
export type ItemType = RodItem.Type | ConsumableItem.Type | nil
export type SlotData = {
	slotId: number,
	uiSlot: ImageButton?, -- Reference to the UI slot, optional
	item: ItemType,
}

export type Type = {
	-- Methods
	new: (itemFactory: ItemFactory.Type) -> Type,
	AddRod: (self: Type, name: string, price: number) -> (),
	AddConsumable: (self: Type, name: string, price: number) -> (), -- example extra method
	GetAllInventoryItems: (self: Type) -> { SlotData }, -- example extra method
	GetAllHandItems: (self: Type) -> { SlotData }, -- example extra method
	MoveItem: (
		self: Type,
		fromType: "inventory" | "hand",
		fromIndex: number,
		toType: "inventory" | "hand",
		toIndex: number
	) -> (),
	AddItemByIndex: (
		self: Type,
		slotType: "inventory" | "hand",
		index: number,
		item: RodItem.Type | ConsumableItem.Type
	) -> (),
	AddItemToInventory: (self: Type, item: RodItem.Type | ConsumableItem.Type) -> boolean, -- returns true if added, false if full
	-- Fields
	ItemFactory: ItemFactory.Type,
	InventoryItems: { SlotData },
	HandItems: { SlotData },
	EquippedIndex: number?,
}

local InventoryService: Type = {}
InventoryService.__index = InventoryService

-- Constructor
function InventoryService.new(itemFactory: ItemFactory.Type): Type
	local self: Type = setmetatable({}, InventoryService)
	self.ItemFactory = itemFactory

	self.InventoryItems = {} :: { SlotData }
	for i = 1, 25 do
		table.insert(self.InventoryItems, { slotId = i, item = nil })
	end

	self.HandItems = {} :: { SlotData }
	for i = 1, 3 do
		table.insert(self.HandItems, { slotId = i, item = nil })
	end

	return self
end

-- Methods
function InventoryService:AddRod(name: string, price: number)
	print("[InventoryService] Adding rod:", name, price)
	local rod = self.ItemFactory.createRod(name, "icon.png", 1, price, 10, 5, 2)
	table.insert(self.InventoryItems, rod)
end

function InventoryService:AddConsumable(name: string, price: number)
	local consumable = self.ItemFactory.createConsumable(name, "icon.png", 2, price)
	table.insert(self.InventoryItems, consumable)
end

function InventoryService:GetAllInventoryItems()
	return self.InventoryItems
end

function InventoryService:GetAllHandItems()
	return self.HandItems
end

function InventoryService:MoveItem(
	fromType: "inventory" | "hand",
	fromIndex: number,
	toType: "inventory" | "hand",
	toIndex: number
)
	-- Select the correct source and destination tables
	local fromList = if fromType == "inventory" then self.InventoryItems else self.HandItems
	local toList = if toType == "inventory" then self.InventoryItems else self.HandItems
	-- Validate indexes
	if not fromList[fromIndex] or not toList[toIndex] then
		warn(`[InventoryService] Invalid slot index (from {fromType}:{fromIndex} → to {toType}:{toIndex})`)
		return
	end

	local fromSlot = fromList[fromIndex]
	local toSlot = toList[toIndex]

	-- If both have items, swap them
	if fromSlot.item and toSlot.item then
		fromSlot.uiSlot.Image, toSlot.uiSlot.Image = toSlot.item.Icon, fromSlot.item.Icon
		fromSlot.item, toSlot.item = toSlot.item, fromSlot.item
	else
		-- Otherwise, move item
		toSlot.item = fromSlot.item
		toSlot.uiSlot.Image = fromSlot.item.Icon
		fromSlot.item = nil
	end
end

function InventoryService:AddItemByIndex(
	slotType: "inventory" | "hand",
	index: number,
	item: RodItem.Type | ConsumableItem.Type
)
	-- Select the correct target list
	local targetList = if slotType == "inventory" then self.InventoryItems else self.HandItems

	-- Validate index
	if not targetList[index] then
		warn(`[InventoryService] Invalid slot index {slotType}:{index}`)
		return
	end

	-- Place item in the specified slot
	targetList[index].item = item
end

function InventoryService:AddItemToInventory(item: ItemType)
	if not item then
		warn("[InventoryService] Cannot add nil item to inventory")
		return nil
	end
	-- Find the first empty slot
	for _, slot in ipairs(self.InventoryItems) do
		if not slot.item then
			slot.item = item
			return slot
		end
	end
	warn("[InventoryService] Inventory full, cannot add item:", item.Name)
	return nil
end

return InventoryService
