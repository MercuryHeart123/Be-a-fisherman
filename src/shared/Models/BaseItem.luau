-- ReplicatedStorage/Models/BaseItem.lua
local BaseItem = {}
BaseItem.__index = BaseItem


export type Type = {
    Name: string,
    Icon: string,
    Id: number,
    Price: number,
    Model: Model?,
    Type: string?,
}
-- Constructor
-- model is optional
function BaseItem.new(name: string, icon: string, id: number, price: number, model: Model?):Type
	local self = setmetatable({}, BaseItem)
	self.Name = name
	self.Icon = icon
	self.Id = id
	self.Price = price
	self.Model = model
	return self
end

-- Optional method to get a DTO for client
function BaseItem:ToDTO()
	return {
		Id = self.Id,
		Name = self.Name,
		Icon = self.Icon,
		Price = self.Price,
	}
end

return BaseItem
