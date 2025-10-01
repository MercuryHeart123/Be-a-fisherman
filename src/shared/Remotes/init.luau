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

-- Server calls this once on startup
function Remotes:Init()
	getOrCreateRemoteEvent("FishingCast")
end

-- Client/server both use these to always get live references
function Remotes.FishingCast(): RemoteEvent
	return ReplicatedStorage:WaitForChild("FishingCast") :: RemoteEvent
end

return Remotes
