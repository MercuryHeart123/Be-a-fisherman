-- StarterPlayerScripts/Client/UI/HandUI.luau (ฉบับแก้ไข)

local HandUI = {}

-- === 1. ย้ายตัวแปร UI มาไว้ข้างบนสุด แต่ยังไม่สร้าง ===
local screenGui: ScreenGui
local handBar: Frame

local uiSlotsHand = {} -- ตารางสำหรับเก็บปุ่ม UI ของ Hand Slots

-- สีสำหรับสถานะต่างๆ
local HAND_DEFAULT_COLOR = Color3.fromRGB(80, 80, 80)
local HAND_SELECTED_COLOR = Color3.fromRGB(255, 200, 0)

-- === 2. สร้างฟังก์ชัน Create() สำหรับสร้าง UI ทั้งหมด ===
function HandUI:Create()
	if screenGui then
		return
	end -- ถ้าเคยสร้างแล้ว ไม่ต้องสร้างซ้ำ

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	handBar = Instance.new("Frame")
	handBar.Name = "HandBar"
	handBar.Size = UDim2.new(0, 230, 0, 80)
	handBar.AnchorPoint = Vector2.new(0.5, 1)
	handBar.Position = UDim2.new(0.5, 0, 1, -20)
	handBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	handBar.BackgroundTransparency = 0.2
	handBar.Parent = screenGui

	Instance.new("UICorner", handBar).CornerRadius = UDim.new(0, 12)
	local handBarPadding = Instance.new("UIPadding")
	handBarPadding.PaddingTop = UDim.new(0, 8)
	handBarPadding.PaddingBottom = UDim.new(0, 8)
	handBarPadding.PaddingLeft = UDim.new(0, 8)
	handBarPadding.PaddingRight = UDim.new(0, 8)
	handBarPadding.Parent = handBar

	local handBarLayout = Instance.new("UIListLayout")
	handBarLayout.FillDirection = Enum.FillDirection.Horizontal
	handBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	handBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	handBarLayout.Padding = UDim.new(0, 8)
	handBarLayout.Parent = handBar
end

-- === 3. แก้ไข BuildSlots ให้สมบูรณ์ ===
function HandUI:BuildSlots(handData, slotType: "hand")
	if not handBar then
		warn("HandUI has not been created yet. Call HandUI:Create() first.")
		return
	end

	-- ล้างปุ่มเก่าทิ้งก่อน
	for _, button in ipairs(uiSlotsHand) do
		button:Destroy()
	end
	table.clear(uiSlotsHand)

	-- สร้างปุ่มใหม่
	for i, slotData in ipairs(handData) do
		local newSlotButton = Instance.new("ImageButton")
		newSlotButton.Name = slotType .. "_Slot_" .. i
		newSlotButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		newSlotButton.Size = UDim2.fromOffset(64, 64)
		newSlotButton.Parent = handBar -- กำหนด Parent

		-- เพิ่มเส้นขอบเพื่อให้เห็นสถานะ Selected
		local border = Instance.new("UIStroke")
		border.Color = HAND_DEFAULT_COLOR
		border.Thickness = 2
		border.Parent = newSlotButton

		-- ปั๊มตราข้อมูล
		newSlotButton:SetAttribute("SlotId", i)
		newSlotButton:SetAttribute("SlotType", slotType)

		-- บันทึก UI Button ลงใน "สมุดบันทึก"
		uiSlotsHand[i] = newSlotButton

		-- บันทึก reference ของ UI กลับเข้าไปในตารางข้อมูล
		slotData.uiSlot = newSlotButton
	end
end

-- === 4. สร้าง UpdateAllSlots (เหมือนกับ InventoryUI) ===
function HandUI:UpdateAllSlots(newHandData)
	for i, uiSlotButton in ipairs(uiSlotsHand) do
		local correspondingData = newHandData[i]
		if correspondingData and correspondingData.item then
			uiSlotButton.Image = correspondingData.item.Icon
		else
			uiSlotButton.Image = ""
		end
	end
end

-- ฟังก์ชันสำหรับอัปเดตเส้นขอบของช่องที่ถูกเลือก
function HandUI:UpdateHandSelectionVisual(selectedIndex: number?)
	for i, slotButton in ipairs(uiSlotsHand) do
		local border = slotButton:FindFirstChildOfClass("UIStroke")
		if border then
			if i == selectedIndex then
				border.Color = HAND_SELECTED_COLOR
			else
				border.Color = HAND_DEFAULT_COLOR
			end
		end
	end
end

return HandUI
