local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SellZoneController = {}
local PlayerControllerModule

function SellZoneController:Init(inventories)
	PlayerControllerModule = inventories

	local sellItemRemote = Remotes.SellSpecificItem()

	sellItemRemote.OnServerEvent:Connect(function(player, slotType, slotId)
		local playerInventory = PlayerControllerModule:GetPlayerInventory(player)
		if playerInventory then
			playerInventory:SellItemInSlot(slotType, slotId)

			local inventoryUpdatedRemote = Remotes.InventoryUpdated()
			local inventoryData = playerInventory:GetAllInventoryItems()
			local handData = playerInventory:GetAllHandItems()
			inventoryUpdatedRemote:FireClient(player, {
				inventory = inventoryData,
				hand = handData,
			})
		end
	end)

	local requestSellAllRemote = Remotes.RequestSellAllItems()

	requestSellAllRemote.OnServerEvent:Connect(function(player)
		local playerInventory = PlayerControllerModule:GetPlayerInventory(player)
		if playerInventory then
			local totalSold = playerInventory:SellAllItems()

			print(`[Server] Player ${player.Name} sold all items for ${totalSold}`)

			local inventoryUpdatedRemote = Remotes.InventoryUpdated()
			local inventoryData = playerInventory:GetAllInventoryItems()
			local handData = playerInventory:GetAllHandItems()
			inventoryUpdatedRemote:FireClient(player, {
				inventory = inventoryData,
				hand = handData,
			})
		end
	end)
end

return SellZoneController
