-- ReplicatedStorage/Models/ConsumableItem.lua
local BaseItem = require(game.ReplicatedStorage.Shared.Models.BaseItem)
local ConsumableItem = setmetatable({}, { __index = BaseItem })
ConsumableItem.__index = ConsumableItem

export type Type = BaseItem.Type & {
	Type: string,
}
-- Constructor
function ConsumableItem.new(name: string, icon: string, id: number, price: number, model: Model?): Type
	local self = BaseItem.new(name, icon, id, price, model)
	setmetatable(self, ConsumableItem)

	self.Type = "consumable"
	return self
end

-- DTO for sending to client
function ConsumableItem:ToDTO()
	return {
		Id = self.Id,
		Name = self.Name,
		Icon = self.Icon,
		Price = self.Price,
		Type = self.Type,
	}
end

return ConsumableItem
