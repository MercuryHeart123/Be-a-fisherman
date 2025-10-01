--!strict
local BaseItem = require(script.Parent.BaseItem)

export type Fish = {
	Id: number,
	Name: string,
	Icon: string,
	Health: number,
	MaxHelth: number,
	Rarity: string,
	Price: number,
	Model: Model?,
	Type: "fish",
}

local FishItem = {}
FishItem.__index = FishItem

function FishItem.new(
	id: number,
	name: string,
	icon: string,
	health: number,
	rarity: string,
	price: number,
	model: Model?
): Fish
	local self = setmetatable(BaseItem.new(name, icon, id, price, model), FishItem) :: Fish
	self.Rarity = rarity
	self.Type = "fish"
	self.Health = health
	self.MaxHelth = health
	return self
end

return FishItem
