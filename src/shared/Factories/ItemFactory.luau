-- ItemFactory.lua
local RodItem = require(game.ReplicatedStorage.Shared.Models.RodItem)
local ConsumableItem = require(game.ReplicatedStorage.Shared.Models.ConsumableItem)
export type Type = {
	createRod: (
		name: string,
		icon: string,
		id: number,
		price: number,
		basePower: number,
		health: number,
		luck: number,
		model: Model?
	) -> RodItem.Type,

	createConsumable: (
		name: string,
		icon: string,
		id: number,
		price: number,
		model: Model?
	) -> ConsumableItem.Type,
}
local ItemFactory:Type = {}

function ItemFactory.createRod(
	name: string,
	icon: string,
	id: number,
	price: number,
	basePower: number,
	health: number,
	luck: number,
	model: Model?
)
	return RodItem.new(name, icon, id, price, basePower, health, luck, model)
end

function ItemFactory.createConsumable(
	name: string,
	icon: string,
	id: number,
	price: number,
	model: Model?
)
	return ConsumableItem.new(name, icon, id, price, model)
end

return ItemFactory
