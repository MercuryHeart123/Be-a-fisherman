--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishItem = require(ReplicatedStorage.Shared.Models.FishItem)

local FishingService = {}

local pool = {
	{
		id = 101,
		name = "Salmon",
		chance = 50,
		rarity = "Common",
		price = 10,
		health = 50,
		icon = "rbxassetid://9400392150",
		modelName = "SalmonModel",
	},
	{
		id = 102,
		name = "Golden Carp",
		chance = 10,
		rarity = "Rare",
		price = 50,
		health = 100,
		icon = "rbxassetid://9400392150",
		modelName = "GoldenCarpModel",
	},
	{
		id = 103,
		name = "Mysterious Fish",
		chance = 5,
		rarity = "Legendary",
		price = 200,
		health = 200,
		icon = "rbxassetid://9400392150",
		modelName = "MysteriousFishModel",
	},
	{
		id = 104,
		name = "Boot",
		chance = 35,
		rarity = "Trash",
		price = 1,
		health = 30,
		icon = "rbxassetid://9400392150",
		modelName = "BootModel",
	},
}

local function rollFish(luck: number): FishItem.Fish
	local total = 0
	for _, f in ipairs(pool) do
		total += f.chance
	end

	-- roll only within the actual pool range (luck shifts odds, not max)
	local roll = math.random(1, total)
	roll = math.max(1, math.min(total, roll + luck)) -- shift by luck, clamp into range

	local cumulative = 0
	for _, f in ipairs(pool) do
		cumulative += f.chance
		if roll <= cumulative then
			local model = ReplicatedStorage.Assets.Models:FindFirstChild(f.modelName)
			return FishItem.new(f.id, f.name, f.icon, f.health, f.rarity, f.price, model)
		end
	end

	-- ✅ guaranteed fallback
	local fallback = pool[1]
	local model = ReplicatedStorage.Assets.Models:FindFirstChild(fallback.modelName)
	return FishItem.new(
		fallback.id,
		fallback.name,
		fallback.icon,
		fallback.rarity,
		fallback.price,
		fallback.health,
		model
	)
end

function FishingService.RollFish(luck: number)
	return rollFish(luck)
end

return FishingService
