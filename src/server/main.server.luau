local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local FishingController = require(script.Parent.Controllers.FishingController)
local SellZoneController = require(script.Parent.Controllers.SellZoneController)
local PlayerController = require(script.Parent.Controllers.PlayerController)

Remotes:Init()
print("✅ All remotes initialized by server", Remotes)

local Fishing = setmetatable({}, FishingController)
Fishing:Init()
print("✅ FishingController initialized by server")

PlayerController:Init()
print("✅ PlayerController initialized by server")

SellZoneController:Init(PlayerController)
print("✅ SellZoneController initialized by server")