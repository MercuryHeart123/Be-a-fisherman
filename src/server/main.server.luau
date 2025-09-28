-- ServerScriptService/init.server.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local FishingController = require(script.Parent.Controllers.FishingController)
-- 1. Ensure remotes exist
Remotes:Init()
print("✅ All remotes initialized by server", Remotes)

local Fishing = setmetatable({}, FishingController)
Fishing:Init()
print("✅ FishingController initialized by server")
