local sellZone = game.Workspace:WaitForChild("SellZone")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local popupGui = require(ReplicatedStorage.Shared.Gui:WaitForChild("SellPopupGui"))

local SellZoneController = {}
local activePopups = {}
local playersOnCooldown = {}
local PlayerControllerModule

local function showSellPopup(player, totalValue, playerInventory)
	local playerGui = player:WaitForChild("PlayerGui")
	local popup = popupGui:Clone()
	
	activePopups[player] = popup
	
	popup.SellFrame.TotalValue.Text = "Total Value: " .. totalValue .. " Money"
	popup.Parent = playerGui

	popup.SellFrame.ConfirmButton.MouseButton1Click:Connect(function()
		if playerInventory then
			local totalSold = playerInventory:SellAllItems()
			print("[SellZone] Player sold items for:", totalSold)
		end
		
		activePopups[player] = nil
		popup:Destroy()
		playersOnCooldown[player] = true
	end)

	popup.SellFrame.CancelButton.MouseButton1Click:Connect(function()
		activePopups[player] = nil
		popup:Destroy()
		playersOnCooldown[player] = true
	end)
end

function SellZoneController:Init(inventories)
	PlayerControllerModule = inventories
	print("✅ SellZoneController initialized by server")
	
	sellZone.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if playersOnCooldown[player] then
			task.delay(5, function()
				if player and player.Name then
					print("[SellZone] Cooldown 5s finished for:", player.Name)
					playersOnCooldown[player] = false
				else
					print("[SellZone] Player is nil or has no Name")
				end
			end)
		end
		
		if player then
			if activePopups[player] then
				return 
			end
			
			local playerInventory = PlayerControllerModule:GetPlayerInventory(player)
			if playerInventory then
				local totalValue = playerInventory:CalculateTotalInventoryValue()
				if totalValue > 0 then
					showSellPopup(player, totalValue, playerInventory)
				else
					print("[SellZone] No items to sell for " .. player.Name)
				end
			else
				print("[Debug] No inventory data found on server for player:", player.Name)
			end
		end
	end)

end

return SellZoneController
