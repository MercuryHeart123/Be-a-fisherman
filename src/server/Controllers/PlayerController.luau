local Players = game:GetService("Players")
local InventoryService = require(game.ReplicatedStorage.Shared.Services.Inventory)
local ItemFactory = require(game.ReplicatedStorage.Shared.Factories.ItemFactory)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PlayerController = {}
local PlayerInventories = {}

function PlayerController:Init()
    local function onGetInventoryData(player)
        local playerInventory = PlayerInventories[player]
        if playerInventory then
            local inventoryData = playerInventory:GetAllInventoryItems()
            local handData = playerInventory:GetAllHandItems()
            return { inventory = inventoryData, hand = handData }
        end
        return nil
    end

    local function onMoveItemRequest(player, fromType, fromIndex, toType, toIndex)
        local playerInventory = PlayerInventories[player]
        if playerInventory then
            playerInventory:MoveItem(fromType, fromIndex, toType, toIndex)

            local inventoryUpdatedRemote = Remotes.InventoryUpdated()
            local inventoryData = playerInventory:GetAllInventoryItems()
            local handData = playerInventory:GetAllHandItems()
            inventoryUpdatedRemote:FireClient(player, {
                inventory = inventoryData,
                hand = handData,
            })
        end
    end

    local getInventoryDataRemote = Remotes.GetInventoryData()
    getInventoryDataRemote.OnServerInvoke = onGetInventoryData

    local moveInventoryItemRemote = Remotes.MoveInventoryItem()
    moveInventoryItemRemote.OnServerEvent:Connect(onMoveItemRequest)

    Players.PlayerAdded:Connect(function(player)
        local leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player

        local moneyValue = Instance.new("IntValue")
        moneyValue.Name = "Money"
        moneyValue.Value = 0
        moneyValue.Parent = leaderstats

        local newInventory = InventoryService.new(ItemFactory, moneyValue)
		local tempRod = ItemFactory.createRod(
			"test",
			"rbxassetid://12345678",
			1,
			123,
			10,
			5,
			2,
			ReplicatedStorage.Assets.Models:WaitForChild("FishingRodModel"),
			0.1,
			2.0
		)
		newInventory:AddItemByIndex("inventory", 1, tempRod)
        newInventory:AddItemByIndex("inventory", 2,ItemFactory.createConsumable("ปลา", "rbxassetid://9400392150", 2, 15))
        newInventory:AddItemByIndex("inventory", 3,ItemFactory.createConsumable("ปลาทูน่า", "rbxassetid://9400392150", 3, 25))

        PlayerInventories[player] = newInventory
        print("✅ Created new inventory and leaderstats for player:", player.Name)
    end)

    Players.PlayerRemoving:Connect(function(player)
        PlayerInventories[player] = nil
        print("🗑️ Removed inventory for player:", player.Name)
    end)
end

function PlayerController:GetPlayerInventory(player)
    return PlayerInventories[player]
end

return PlayerController