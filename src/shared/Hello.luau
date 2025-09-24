type InventoryItem = {
    Name: string,
    Icon: string,
    Damage: number,
    Id: number,
}

local item: InventoryItem = {
	Name = "Sword",
	Icon = "sword_icon.png",
	Damage = 25,
	Id = 1,
}
return function()
	print(item)
end
