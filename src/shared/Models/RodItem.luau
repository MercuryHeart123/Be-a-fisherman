-- ReplicatedStorage/Models/RodItem.lua
local BaseItem = require(game.ReplicatedStorage.Shared.Models.BaseItem)

local RodItem = setmetatable({}, { __index = BaseItem })
RodItem.__index = RodItem
export type Type = BaseItem.Type & {
	Type: string,
	BasePower: number,
	Health: number,
	Luck: number,
	CritChance: number,
	CritMultiplier: number,
}
-- Constructor
function RodItem.new(
	name: string,
	icon: string,
	id: number,
	price: number,
	basePower: number,
	health: number,
	luck: number,
	model: Model?,
	critChance: number?,
	critMultiplier: number?
): Type
	local self = BaseItem.new(name, icon, id, price, model)
	setmetatable(self, RodItem)

	self.Type = "rod"
	self.BasePower = basePower
	self.Health = health
	self.Luck = luck
	self.CritChance = critChance or 0
	self.CritMultiplier = critMultiplier or 1.5

	return self
end

-- DTO for sending to client
function RodItem:ToDTO()
	return {
		Id = self.Id,
		Name = self.Name,
		Icon = self.Icon,
		Price = self.Price,
		Type = self.Type,
		BasePower = self.BasePower,
		Health = self.Health,
		Luck = self.Luck,
	}
end

return RodItem
