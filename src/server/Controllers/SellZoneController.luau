local ReplicatedStorage = game:GetService("ReplicatedStorage")
local popupGui = require(ReplicatedStorage.Shared.Gui:WaitForChild("SellPopupGui"))
local Remotes = require(ReplicatedStorage.Shared.Remotes) -- เพิ่ม Remotes

local SellZoneController = {}
local PlayerControllerModule

local function showSellPopup(player, totalValue, playerInventory)
	local playerGui = player:WaitForChild("PlayerGui")
	local popup = popupGui:Clone()

	popup.SellFrame.TotalValue.Text = "Total Value: " .. totalValue .. " Money"
	popup.Parent = playerGui

	popup.SellFrame.ConfirmButton.MouseButton1Click:Connect(function()
		if playerInventory then
			local totalSold = playerInventory:SellAllItems()
			print("[SellZone] Player sold items for:", totalSold)
		end

		popup:Destroy()
	end)

	popup.SellFrame.CancelButton.MouseButton1Click:Connect(function()
		popup:Destroy()
	end)
end

function SellZoneController:Init(inventories)
	PlayerControllerModule = inventories

	local requestSellRemote = Remotes.RequestSell()

	requestSellRemote.OnServerEvent:Connect(function(player)
		print(`[Server] Received sell request from ${player.Name}`)

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
	end)
end

return SellZoneController
