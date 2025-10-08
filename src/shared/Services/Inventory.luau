local ItemFactory = require(game.ReplicatedStorage.Shared.Factories.ItemFactory)
local RodItem = require(game.ReplicatedStorage.Shared.Models.RodItem)
local ConsumableItem = require(game.ReplicatedStorage.Shared.Models.ConsumableItem)
export type ItemType = RodItem.Type | ConsumableItem.Type | nil
export type SlotData = {
	slotId: number,
	uiSlot: ImageButton?,
	item: ItemType,
}

export type Type = {
	-- Methods
	new: (itemFactory: ItemFactory.Type) -> Type,
	AddRod: (self: Type, name: string, price: number) -> (),
	AddConsumable: (self: Type, name: string, price: number) -> (),
	GetAllInventoryItems: (self: Type) -> { SlotData },
	GetAllHandItems: (self: Type) -> { SlotData },
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
	MoneyValue: IntValue,
}

local InventoryService: Type = {}
InventoryService.__index = InventoryService

function InventoryService.new(itemFactory: ItemFactory.Type, moneyValue: IntValue): Type
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

	self.MoneyValue = moneyValue

	return self
end

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

function InventoryService:AddMoney(amount: number)
	self.MoneyValue.Value += amount
end

function InventoryService:MoveItem(
	fromType: "inventory" | "hand",
	fromIndex: number,
	toType: "inventory" | "hand",
	toIndex: number
)
	local fromList = if fromType == "inventory" then self.InventoryItems else self.HandItems
	local toList = if toType == "inventory" then self.InventoryItems else self.HandItems

	if not fromList[fromIndex] or not toList[toIndex] then
		warn(`[InventoryService] Invalid slot index during MoveItem`)
		return
	end

	fromList[fromIndex].item, toList[toIndex].item = toList[toIndex].item, fromList[fromIndex].item
	print("[InventoryService] Swapped items between slots.")
end

function InventoryService:AddItemByIndex(
	slotType: "inventory" | "hand",
	index: number,
	item: RodItem.Type | ConsumableItem.Type
)
	local targetList = if slotType == "inventory" then self.InventoryItems else self.HandItems

	if not targetList[index] then
		warn(`[InventoryService] Invalid slot index {slotType}:{index}`)
		return
	end

	targetList[index].item = item
end

function InventoryService:AddItemToInventory(item: ItemType)
	if not item then
		warn("[InventoryService] Cannot add nil item to inventory")
		return nil
	end
	for _, slot in ipairs(self.InventoryItems) do
		if not slot.item then
			slot.item = item
			return slot
		end
	end
	warn("[InventoryService] Inventory full, cannot add item:", item.Name)
	return nil
end

function InventoryService:CalculateTotalInventoryValue(): number
	local totalValue = 0
	for _, slot in ipairs(self.InventoryItems) do
		if slot.item then
			totalValue += slot.item.Price or 0
		end
	end
	return totalValue
end

function InventoryService:SellAllItems()
	local totalValue = self:CalculateTotalInventoryValue()

	for _, slot in ipairs(self.InventoryItems) do
		slot.item = nil
	end

	if totalValue > 0 then
		self:AddMoney(totalValue)
	end

	print("[InventoryService] Sold all items for:", totalValue)
	return totalValue
end

return InventoryService
