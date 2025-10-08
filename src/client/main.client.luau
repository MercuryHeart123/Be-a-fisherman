local InventoryController = require(script.Parent.Controllers.InventoryController)
local FishingController = require(script.Parent.Controllers.FishingController)
local InteractionController = require(script.Parent.Controllers.InteractionController)

local inventory = setmetatable({}, InventoryController)
inventory:Init()

local fishing = setmetatable({}, FishingController)
fishing:Init()

InteractionController:Init()
