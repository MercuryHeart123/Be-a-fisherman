--!strict
-- Server bootstrap

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Ensure folder for fishing remotes
local fishingFolder = ReplicatedStorage:FindFirstChild("Fishing")
if not fishingFolder then
	fishingFolder = Instance.new("Folder")
	fishingFolder.Name = "Fishing"
	fishingFolder.Parent = ReplicatedStorage
end

local fishingCast = fishingFolder:FindFirstChild("Cast") :: RemoteEvent?
if not fishingCast then
	fishingCast = Instance.new("RemoteEvent")
	fishingCast.Name = "Cast"
	fishingCast.Parent = fishingFolder
end

local fishingHooked = fishingFolder:FindFirstChild("Hooked") :: RemoteEvent?
if not fishingHooked then
	fishingHooked = Instance.new("RemoteEvent")
	fishingHooked.Name = "Hooked"
	fishingHooked.Parent = fishingFolder
end

-- Simple fish table (server decides)
local FishCatalog = {
	{ Name = "Small Fish", Icon = "rbxassetid://12345578", Type = "consumable", Id = 1001 },
	{ Name = "Bass", Icon = "rbxassetid://12345579", Type = "consumable", Id = 1002 },
	{ Name = "Salmon", Icon = "rbxassetid://12345580", Type = "consumable", Id = 1003 },
}

local function chooseFish(): any
	local idx = math.random(1, #FishCatalog)
	return FishCatalog[idx]
end

fishingCast.OnServerEvent:Connect(function(player: Player, castInfo: any)
	-- castInfo may include position/power if needed later
	-- Decide fish and notify this player to start minigame
	local fish = chooseFish()
	fishingHooked:FireClient(player, fish)
end)