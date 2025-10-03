local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local popupGuiTemplate = require(ReplicatedStorage.Shared.Gui:WaitForChild("SellPopupGui"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local currentPopup = nil

local showSellPopupRemote = Remotes.ShowSellPopup()
local sellAllItemsRemote = Remotes.SellAllItems()

local function closePopup()
	if currentPopup then
		currentPopup:Destroy()
		currentPopup = nil
	end
end

showSellPopupRemote.OnClientEvent:Connect(function(shouldShow: boolean, totalValue: number?)
	-- ปิด Popup เก่าก่อนเสมอ
	closePopup()

	if shouldShow and totalValue and totalValue > 0 then
		-- Server สั่งให้เปิด
		currentPopup = popupGuiTemplate:Clone()
		currentPopup.SellFrame.TotalValue.Text = "Total Value: " .. totalValue .. " Money"
		currentPopup.Parent = playerGui

		-- Handle Confirm Button
		currentPopup.SellFrame.ConfirmButton.MouseButton1Click:Connect(function()
			print("[Client] Confirm button clicked. Firing SellAllItems to server.")
			-- ยิง RemoteEvent กลับไปบอก Server ว่ายืนยันการขาย
			sellAllItemsRemote:FireServer()
			closePopup()
		end)

		-- Handle Cancel Button
		currentPopup.SellFrame.CancelButton.MouseButton1Click:Connect(function()
			print("[Client] Cancel button clicked.")
			closePopup()
		end)
	end
	-- ถ้า shouldShow เป็น false, popup จะถูกปิดไปแล้วจาก closePopup() ด้านบน
end)
