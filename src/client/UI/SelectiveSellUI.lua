local SelectiveSellUI = {}

local screenGui: ScreenGui
local mainFrame: Frame
local itemsFrame: ScrollingFrame
local itemTemplate: Frame
local ServerInventoryData = nil

function SelectiveSellUI:Create()
	if screenGui then
		return
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SelectiveSellUI"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "SellMainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false -- เริ่มต้นด้วยการซ่อน
	mainFrame.Parent = screenGui
	mainFrame.ZIndex = 1
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.fromOffset(25, 25) -- ขนาด 25x25 pixels
	closeButton.AnchorPoint = Vector2.new(1, 0) -- ยึดมุมขวาบน
	closeButton.Position = UDim2.new(1, -5, 0, 5) -- ตำแหน่งมุมขวาบน (เยื้องเข้ามาเล็กน้อย)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- สีแดง
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.ZIndex = 2 -- ให้อยู่เหนือ Frame หลักเล็กน้อย
	closeButton.Parent = mainFrame
	Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 4)

	-- เมื่อกดปุ่มปิด
	closeButton.MouseButton1Click:Connect(function()
		-- เรียกใช้ฟังก์ชัน SetVisible เพื่อซ่อน UI
		SelectiveSellUI:SetVisible(false)
	end)

	local title = Instance.new("TextLabel")
	title.Text = "เลือกไอเทมที่จะขาย"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Font = Enum.Font.BuilderSansBold -- 1. ใช้ฟอนต์ใหม่
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 20 -- 2. กำหนดขนาดเอง
	title.TextStrokeColor3 = Color3.fromRGB(20, 20, 20) -- 3. เพิ่มเส้นขอบ
	title.TextStrokeTransparency = 0.5
	title.BackgroundTransparency = 1
	title.Parent = mainFrame

	itemsFrame = Instance.new("ScrollingFrame")
	itemsFrame.Size = UDim2.new(1, -20, 1, -95)
	itemsFrame.Position = UDim2.new(0, 10, 0, 30)
	itemsFrame.BackgroundTransparency = 1
	itemsFrame.CanvasSize = UDim2.new(0, 0, 4, 0) -- เพิ่มความสูง Canvas เผื่อเลื่อน
	itemsFrame.Parent = mainFrame

	local grid = Instance.new("UIGridLayout")
	-- 1. ปรับความสูงของ Cell ให้มากขึ้น (เช่น 180) เพื่อรองรับ Layout ใหม่
	grid.CellSize = UDim2.new(0.5, -5, 0, 180)
	grid.CellPadding = UDim2.new(0, 10, 0, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = itemsFrame

	-- สร้าง Template สำหรับไอเทมแต่ละชิ้น
	itemTemplate = Instance.new("Frame")
	itemTemplate.Name = "ItemTemplate"
	itemTemplate.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	itemTemplate.BorderSizePixel = 0
	itemTemplate.Visible = false
	itemTemplate.Parent = itemsFrame -- Parent ชั่วคราวเพื่อให้ Editor รู้จัก
	Instance.new("UICorner", itemTemplate).CornerRadius = UDim.new(0, 8)

	local templatePadding = Instance.new("UIPadding")
	templatePadding.PaddingTop = UDim.new(0, 8)
	templatePadding.PaddingBottom = UDim.new(0, 8)
	templatePadding.PaddingLeft = UDim.new(0, 8)
	templatePadding.PaddingRight = UDim.new(0, 8)
	templatePadding.Parent = itemTemplate

	local verticalLayout = Instance.new("UIListLayout")
	verticalLayout.FillDirection = Enum.FillDirection.Vertical
	verticalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	verticalLayout.Padding = UDim.new(0, 5) -- ระยะห่างระหว่างแต่ละชิ้น
	verticalLayout.Parent = itemTemplate

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(70, 70)
	icon.BackgroundTransparency = 1
	icon.Parent = itemTemplate

	local itemName = Instance.new("TextLabel")
	itemName.Name = "ItemName"
	itemName.Size = UDim2.new(1, 0, 0, 20)
	itemName.Font = Enum.Font.BuilderSans
	itemName.TextColor3 = Color3.new(1, 1, 1)
	itemName.TextSize = 16
	itemName.TextXAlignment = Enum.TextXAlignment.Center -- จัดกึ่งกลาง
	itemName.BackgroundTransparency = 1
	itemName.Text = "Item Name"
	itemName.Parent = itemTemplate -- << Parent คือ itemTemplate

	-- 6. แก้ไข ItemPrice (ไม่ต้องมี Position, เปลี่ยน Parent)
	local itemPrice = Instance.new("TextLabel")
	itemPrice.Name = "ItemPrice"
	itemPrice.Size = UDim2.new(1, 0, 0, 18)
	itemPrice.Font = Enum.Font.BuilderSansBold
	itemPrice.TextColor3 = Color3.fromRGB(255, 220, 0)
	itemPrice.TextSize = 14
	itemPrice.TextXAlignment = Enum.TextXAlignment.Center -- จัดกึ่งกลาง
	itemPrice.BackgroundTransparency = 1
	itemPrice.Text = "ราคา: 100"
	itemPrice.Parent = itemTemplate -- << Parent คือ itemTemplate

	-- 7. แก้ไข SellButton (ไม่ต้องมี Position)
	local sellButton = Instance.new("TextButton")
	sellButton.Name = "SellButton"
	sellButton.Size = UDim2.new(1, -20, 0, 35) -- กว้างเกือบเต็ม, สูง 35
	sellButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	sellButton.Text = "ขาย"
	sellButton.Font = Enum.Font.BuilderSansBold
	sellButton.TextSize = 16
	sellButton.TextColor3 = Color3.new(1, 1, 1)
	sellButton.Parent = itemTemplate
	Instance.new("UICorner", sellButton).CornerRadius = UDim.new(0, 4)

	local sellAllButton = Instance.new("TextButton")
	sellAllButton.Name = "SellAllButton"
	sellAllButton.Size = UDim2.new(1, -20, 0, 40) -- กว้างเกือบเต็มกรอบ, สูง 40px
	sellAllButton.AnchorPoint = Vector2.new(0.5, 1) -- ยึดมุมล่างกึ่งกลาง
	sellAllButton.Position = UDim2.new(0.5, 0, 1, -10) -- ตำแหน่งล่างสุดของ mainFrame
	sellAllButton.BackgroundColor3 = Color3.fromRGB(200, 120, 50) -- สีส้ม
	sellAllButton.Text = "ขายทั้งหมด"
	sellAllButton.Font = Enum.Font.BuilderSansBold
	sellAllButton.TextSize = 18
	sellAllButton.TextColor3 = Color3.new(1, 1, 1)
	sellAllButton.Parent = mainFrame
	Instance.new("UICorner", sellAllButton).CornerRadius = UDim.new(0, 6)
	local totalValue = CalculateClientTotalValue()

	sellAllButton.MouseButton1Click:Connect(function()
		print("Client: Requesting to sell all items.")

		local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
		-- self:ShowSellAllConfirmationPopup(totalValue, function()
		Remotes.RequestSellAllItems():FireServer()
		-- end)

		SelectiveSellUI:SetVisible(false)
	end)
end

-- ฟังก์ชันสำหรับสร้างรายการไอเทม
function SelectiveSellUI:BuildSellList(inventoryData, sellItemRemote: RemoteEvent)
	if not itemsFrame then
		return
	end

	-- ล้างรายการเก่า
	for _, child in ipairs(itemsFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= itemTemplate then
			child:Destroy()
		end
	end

	-- สร้างรายการใหม่
	for _, slotData in ipairs(inventoryData) do
		if slotData.item then
			local itemClone = itemTemplate:Clone()
			itemClone.Icon.Image = slotData.item.Icon
			itemClone.ItemName.Text = slotData.item.Name
			itemClone.ItemPrice.Text = "ราคา: " .. (slotData.item.Price or 0)

			-- เชื่อมต่อปุ่มขาย
			itemClone.SellButton.MouseButton1Click:Connect(function()
				print(`Client: Confirmed selling item in inventory slot ${slotData.slotId}`)
				sellItemRemote:FireServer("inventory", slotData.slotId)
			end)

			itemClone.Visible = true
			itemClone.Parent = itemsFrame
		end
	end
end

function SelectiveSellUI:SetVisible(visible: boolean)
	if mainFrame then
		mainFrame.Visible = visible
	end
end

function SelectiveSellUI:GetVisible()
	if mainFrame then
		return mainFrame.Visible
	end
	return false
end
-- ใน SelectiveSellUI.lua (วางไว้ใกล้ๆ กับ ShowConfirmationPopup เดิม)

function SelectiveSellUI:ShowSellAllConfirmationPopup(totalValue, onConfirmCallback)
	-- สร้าง Overlay และ Popup Frame (เหมือนเดิม)
	local overlay = Instance.new("Frame")
	overlay.Name = "ConfirmationOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.7
	overlay.ZIndex = 10
	overlay.Active = true
	overlay.Parent = screenGui

	local popupFrame = Instance.new("Frame")
	popupFrame.Name = "PopupFrame"
	popupFrame.Size = UDim2.new(0, 300, 0, 150)
	popupFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
	popupFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	popupFrame.ZIndex = 11
	popupFrame.Parent = overlay
	Instance.new("UICorner", popupFrame).CornerRadius = UDim.new(0, 8)

	-- สร้างข้อความ (ใช้ totalValue ที่รับเข้ามา)
	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Size = UDim2.new(1, -20, 0, 80)
	message.Position = UDim2.new(0, 10, 0, 10)
	message.BackgroundTransparency = 1
	message.Font = Enum.Font.SourceSans
	message.TextSize = 18
	message.TextColor3 = Color3.new(1, 1, 1)
	message.TextWrapped = true
	message.Text = string.format(
		"คุณต้องการขายไอเทมทั้งหมดในราคา %d บาทใช่หรือไม่?",
		totalValue
	)
	message.Parent = popupFrame

	-- ... (โค้ดสร้าง cancelButton และ confirmButton เหมือนเดิม) ...
	local cancelButton = Instance.new("TextButton")
	-- ...
	cancelButton.Parent = popupFrame
	local confirmButton = Instance.new("TextButton")
	-- ...
	confirmButton.Parent = popupFrame

	-- เชื่อมต่อ Event (เหมือนเดิม)
	cancelButton.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)

	confirmButton.MouseButton1Click:Connect(function()
		onConfirmCallback()
		overlay:Destroy()
	end)
end

function SelectiveSellUI:ShowConfirmationPopup(onConfirmCallback)
	-- สร้าง Overlay สีดำโปร่งแสง คลุมทั้งหน้าจอ
	local overlay = Instance.new("Frame")
	overlay.Name = "ConfirmationOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.7
	overlay.ZIndex = 10 -- << ให้ Overlay อยู่หน้าสุด
	overlay.Active = true -- << สำคัญ: ทำให้ Overlay "ดักจับ" การคลิก ไม่ให้ทะลุไปข้างหลัง
	overlay.Parent = screenGui
	-- สร้างกรอบ Popup
	local popupFrame = Instance.new("Frame")
	popupFrame.Name = "PopupFrame"
	popupFrame.Size = UDim2.new(0, 300, 0, 150)
	popupFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
	popupFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	popupFrame.BorderSizePixel = 0
	popupFrame.ZIndex = 11 -- << ให้กรอบ Popup อยู่หน้า Overlay อีกที
	popupFrame.Parent = overlay
	Instance.new("UICorner", popupFrame).CornerRadius = UDim.new(0, 8)

	-- สร้างข้อความคำถาม
	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Size = UDim2.new(1, -20, 0, 80)
	message.Position = UDim2.new(0, 10, 0, 10)
	message.BackgroundTransparency = 1
	message.Font = Enum.Font.SourceSans
	message.TextScaled = false
	message.TextSize = 18
	message.TextColor3 = Color3.new(1, 1, 1)
	message.TextWrapped = true
	message.Text = string.format(
		"คุณต้องการขาย '%s' ในราคา %d บาทใช่หรือไม่?"
		-- itemData.Name or "ไอเทม",
		-- itemData.Price or 0
	)
	message.Parent = popupFrame

	-- สร้างปุ่มยกเลิก
	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0.5, -15, 0, 40)
	cancelButton.Position = UDim2.new(0, 10, 1, -50)
	cancelButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	cancelButton.Text = "ยกเลิก"
	cancelButton.Font = Enum.Font.SourceSansBold
	cancelButton.TextSize = 16
	cancelButton.TextColor3 = Color3.new(1, 1, 1)
	cancelButton.Parent = popupFrame
	Instance.new("UICorner", cancelButton).CornerRadius = UDim.new(0, 6)

	-- สร้างปุ่มยืนยัน
	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "ConfirmButton"
	confirmButton.Size = UDim2.new(0.5, -15, 0, 40)
	confirmButton.Position = UDim2.new(0.5, 5, 1, -50)
	confirmButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	confirmButton.Text = "ยืนยัน"
	confirmButton.Font = Enum.Font.SourceSansBold
	confirmButton.TextSize = 16
	confirmButton.TextColor3 = Color3.new(1, 1, 1)
	confirmButton.Parent = popupFrame
	Instance.new("UICorner", confirmButton).CornerRadius = UDim.new(0, 6)

	-- เชื่อมต่อ Event ของปุ่ม
	cancelButton.MouseButton1Click:Connect(function()
		mainFrame.ZIndex = 0 -- คืนค่า ZIndex
		overlay:Destroy() -- แค่ทำลาย Popup ทิ้งไป
	end)

	confirmButton.MouseButton1Click:Connect(function()
		mainFrame.ZIndex = 0 -- คืนค่า ZIndex
		onConfirmCallback() -- เรียกใช้ฟังก์ชันที่ส่งเข้ามา
		overlay:Destroy() -- ทำลาย Popup ทิ้ง
	end)
end

function CalculateClientTotalValue()
	if not ServerInventoryData then
		return 0
	end

	local totalValue = 0
	for _, slotData in ipairs(ServerInventoryData.inventory) do
		if slotData.item then
			totalValue += slotData.item.Price or 0
		end
	end
	return totalValue
end

return SelectiveSellUI
