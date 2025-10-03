local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Utility: create or fetch a RemoteEvent
local function getOrCreateRemoteEvent(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

-- Utility: create or fetch a RemoteFunction
local function getOrCreateRemoteFunction(name: string): RemoteFunction
    local existing = ReplicatedStorage:FindFirstChild(name)
    if existing and existing:IsA("RemoteFunction") then
        return existing
    end

    local remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = ReplicatedStorage
    return remote
end

-- Server calls this once on startup
function Remotes:Init()
	getOrCreateRemoteEvent("FishingCast")
	getOrCreateRemoteFunction("GetInventoryData")
	getOrCreateRemoteEvent("MoveInventoryItem")
	getOrCreateRemoteEvent("InventoryUpdated")
	getOrCreateRemoteEvent("SellAllItems")
end

-- Client/server both use these to always get live references
function Remotes.FishingCast(): RemoteEvent
	return ReplicatedStorage:WaitForChild("FishingCast") :: RemoteEvent
end

function Remotes.GetInventoryData(): RemoteFunction
	return ReplicatedStorage:WaitForChild("GetInventoryData") :: RemoteFunction
end

function Remotes.MoveInventoryItem(): RemoteEvent
	return ReplicatedStorage:WaitForChild("MoveInventoryItem") :: RemoteEvent
end

function Remotes.InventoryUpdated(): RemoteEvent
	return ReplicatedStorage:WaitForChild("InventoryUpdated") :: RemoteEvent
end

function Remotes.SellAllItems(): RemoteEvent
	return ReplicatedStorage:WaitForChild("SellAllItems") :: RemoteEvent
end

return Remotes
