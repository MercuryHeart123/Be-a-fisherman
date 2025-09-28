-- --!strict
-- -- InventoryUI.lua (Client)
-- -- Handles UI, drag & drop between inventory & hand slots
-- print("InventoryUI loaded")
-- local Players = game:GetService("Players")
-- local UserInputService = game:GetService("UserInputService")
-- local Fishing = require(script.Parent:WaitForChild("Fishing"))
-- local Types = require(script.Parent:WaitForChild("types"))

-- type BaitState = Types.BaitState
-- local BaitState = Types.BaitState
-- local GuiService = game:GetService("GuiService")

-- local player = Players.LocalPlayer
-- local playerGui = player:WaitForChild("PlayerGui")
-- local handSlots: {[number]: SlotData} = {}

-- --// Types
-- type ItemType =  "consumable" | "rod"

-- type InventoryItem = {
-- 	Name: string,
-- 	Icon: string,
-- 	Type: ItemType,
-- 	Model: Model?,
-- 	Id: number,
-- }

-- type SlotData = {
-- 	slot: ImageButton,
-- 	item: InventoryItem?,
-- }
 
--  type SelectedItem = {
-- 	item: InventoryItem,
-- 	slot: SlotData,
--  }
 
-- --// UI Containers

-- local screenGui = Instance.new("ScreenGui")
-- screenGui.Name = "InventoryUI"
-- screenGui.Parent = playerGui

-- local mainFrame = Instance.new("Frame")
-- mainFrame.Size = UDim2.new(0, 600, 0, 400)
-- mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
-- mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
-- mainFrame.Parent = screenGui
-- mainFrame.Visible = false -- start hidden

-- -- Minigame panel (hidden until hooked)
-- local miniFrame = Instance.new("Frame")
-- miniFrame.Name = "FishingMinigame"
-- miniFrame.Size = UDim2.fromOffset(60, 300)
-- miniFrame.AnchorPoint = Vector2.new(0.5, 0.5)
-- miniFrame.Position = UDim2.new(0.25, 0, 0.4, 0)
-- miniFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
-- miniFrame.BackgroundTransparency = 1
-- miniFrame.Visible = false
-- miniFrame.Parent = screenGui

-- -- Vertical bar
-- local bar = Instance.new("Frame")
-- bar.Size = UDim2.new(0, 20, 1, -20) -- tall, thin bar
-- bar.AnchorPoint = Vector2.new(0.5, 0.5)
-- bar.Position = UDim2.new(0.5, 0, 0.5, 0)
-- bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- base color (not visible once gradient is applied)
-- bar.Parent = miniFrame
-- Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

-- -- Gradient
-- local gradient = Instance.new("UIGradient")
-- gradient.Rotation = 90 -- vertical top-to-bottom
-- gradient.Color = ColorSequence.new({
--     ColorSequenceKeypoint.new(0, Color3.fromRGB(196, 224, 255)),   -- top (0%)
--     ColorSequenceKeypoint.new(0.15, Color3.fromRGB(196, 224, 255)), -- keep red until 15%
--     ColorSequenceKeypoint.new(0.151, Color3.fromRGB(73, 182, 224)), -- transition just after 15%
--     ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 10, 94))   -- bottom
-- })
-- gradient.Parent = bar

-- -- Cursor (moves up & down)
-- local cursor = Instance.new("ImageLabel")
-- cursor.Name = "FishCursor"
-- cursor.Size = UDim2.fromOffset(80, 80) -- bigger fish (overflow bar)
-- cursor.AnchorPoint = Vector2.new(0.5, 0.5)
-- cursor.Position = UDim2.new(0.5, 0, 0.5, 0) -- starts near top
-- cursor.BackgroundTransparency = 1 -- no background
-- cursor.Image = "rbxassetid://9400392150" -- 🐟 fish icon
-- cursor.ImageColor3 = Color3.fromRGB(220, 220, 220)
-- cursor.Parent = bar

-- -- Make sure the bar does NOT clip children
-- bar.ClipsDescendants = false


-- local ContextActionService = game:GetService("ContextActionService")

-- local miniActive = false
-- local miniResultFish: any = nil
-- local inventorySlots: {[number]: SlotData} = {}

-- local function updateSlotVisual(slotData: SlotData)
-- 	if slotData.item then
-- 		slotData.slot.Image = slotData.item.Icon
-- 	else
-- 		slotData.slot.Image = ""
-- 	end
-- end

-- local function addFishToInventory(fish: any)
-- 	-- find first empty slot
-- 	for i = 1, #inventorySlots do
-- 		if not inventorySlots[i].item then
-- 			local slotData = inventorySlots[i]
-- 			slotData.item = {
-- 				Name = fish.Name,
-- 				Icon = fish.Icon or "",
-- 				Type = "consumable",
-- 				Model = nil,
-- 				Id = fish.Id or 0,
-- 			}
-- 			updateSlotVisual(slotData)
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end


-- local jumpScale = 0.1 -- ปรับขนาดเด้ง
-- local pos = 0.5

-- local function finishMinigame(success: boolean)
-- 	pos = 0.5
-- 	miniActive = false
-- 	miniFrame.Visible = false
-- 	ContextActionService:UnbindAction("MiniGameSpace") -- ปลด bind space กลับมากระโดดได้
-- 	if success and miniResultFish then
-- 		addFishToInventory(miniResultFish)
-- 	end
-- 	Fishing.clearBait()
-- 	miniResultFish = nil
-- end


-- local function handleMinigameInput(actionName, inputState, inputObject)
-- 	if not miniActive then return Enum.ContextActionResult.Pass end
-- 	if inputState == Enum.UserInputState.Begin then
-- 		local currentScale = cursor.Position.Y.Scale
-- 		local step = 0
-- 		local bait = Fishing.isBaitInsideCircle()
-- 		if bait == BaitState.Out  then
-- 			step = currentScale + jumpScale
-- 		elseif bait == BaitState.In then
-- 			step = currentScale - jumpScale
-- 		elseif bait == BaitState.Pressed then
-- 			step = currentScale
-- 		end
-- 		-- เด้ง cursor ขึ้น - jumpScale
-- 		local newPos = math.clamp(step, 0, 1)
-- 		cursor.Position = UDim2.new(0.5, 0, newPos, 0)
-- 		if newPos <= 0.15 then
-- 			finishMinigame(true)
-- 			miniActive = false
-- 			return Enum.ContextActionResult.Sink
-- 		end
-- 		-- **อัพเดท pos ด้วย**
-- 		pos = newPos

		
-- 		return Enum.ContextActionResult.Sink
-- 	end
-- 	return Enum.ContextActionResult.Pass
-- end

-- local function startMinigame(fish: any)
-- 	miniResultFish = fish
-- 	miniActive = true
-- 	miniFrame.Visible = true

-- 	ContextActionService:BindAction("MiniGameSpace", handleMinigameInput, false, Enum.KeyCode.Space)

-- 	local speed = 0.1

-- 	cursor.Position = UDim2.new(0.5, 0, 0.5, 0)

-- 	local reachedTopTime = nil
-- 	local connection
-- 	connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
-- 		if not miniActive then
-- 			connection:Disconnect()
-- 			return
-- 		end

-- 		-- -- ถ้ายังไม่ถึง top ให้เคลื่อน
-- 		-- if not reachedTopTime then
-- 		-- 	pos = pos + speed * dt
-- 		-- 	if pos >= 1 then
-- 		-- 		pos = 1
-- 		-- 		reachedTopTime = tick()
-- 		-- 	end
-- 		-- 	cursor.Position = UDim2.new(0.5, 0, pos, 0)
-- 		-- else
-- 		-- 	-- ถ้าอยู่บนสุดแล้ว 0.2 วิผ่านไป → จบเกม
-- 		-- 	if tick() - reachedTopTime >= 0.2 then
-- 		-- 		connection:Disconnect()
-- 		-- 		if miniActive then
-- 		-- 			finishMinigame(false)
-- 		-- 		end
-- 		-- 	end
-- 		-- end
-- 		if pos >= 1 then
-- 			connection:Disconnect()
-- 			pos = 1
-- 				if miniActive then
-- 					finishMinigame(false)
-- 				end
-- 		end
-- 	end)
-- end


-- Fishing.onHooked(function(fish)
-- 	startMinigame(fish)
-- end)


-- -- Power meter (bottom-left)

-- local powerFrame = Instance.new("Frame")
-- powerFrame.Name = "PowerMeter"
-- powerFrame.Size = UDim2.fromOffset(180, 180)
-- powerFrame.AnchorPoint = Vector2.new(1, 1) -- bottom-right
-- powerFrame.Position = UDim2.new(1, -20, 1, -20) -- 20px from right and bottom
-- powerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
-- powerFrame.BackgroundTransparency = 0.2
-- powerFrame.Visible = false
-- powerFrame.Parent = screenGui


-- local powerCorner = Instance.new("UICorner")
-- powerCorner.CornerRadius = UDim.new(1, 0)
-- powerCorner.Parent = powerFrame

-- local powerFill = Instance.new("Frame")
-- powerFill.Name = "Fill"
-- powerFill.BackgroundColor3 = Color3.fromRGB(70, 200, 255)
-- powerFill.BackgroundTransparency = 0.1
-- powerFill.Size = UDim2.new(1, 0, 0, 0)
-- powerFill.AnchorPoint = Vector2.new(0.5, 1)
-- powerFill.Position = UDim2.new(0.5, 0, 1, 0)
-- powerFill.Parent = powerFrame

-- local powerFillCorner = Instance.new("UICorner")
-- powerFillCorner.CornerRadius = UDim.new(1, 0)
-- powerFillCorner.Parent = powerFill

-- local charging = false
-- local power01 = 0
-- local powerIncrementPerSecond = 1.4 -- seconds to full ~1.42

-- -- Permanent Hand Bar (always visible)
-- local handBar = Instance.new("Frame")
-- handBar.Name = "HandBar"
-- handBar.Size = UDim2.new(0, 230, 0, 80)
-- handBar.AnchorPoint = Vector2.new(0.5, 1)
-- handBar.Position = UDim2.new(0.5, 0, 1, -20)
-- handBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
-- handBar.BackgroundTransparency = 0.2
-- handBar.Parent = screenGui

-- Instance.new("UICorner", handBar).CornerRadius = UDim.new(0,12)
-- local handBarPadding = Instance.new("UIPadding")
-- handBarPadding.PaddingTop = UDim.new(0,8)
-- handBarPadding.PaddingBottom = UDim.new(0,8)
-- handBarPadding.PaddingLeft = UDim.new(0,8)
-- handBarPadding.PaddingRight = UDim.new(0,8)
-- handBarPadding.Parent = handBar

-- local handBarLayout = Instance.new("UIListLayout")
-- handBarLayout.FillDirection = Enum.FillDirection.Horizontal
-- handBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
-- handBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
-- handBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
-- handBarLayout.Padding = UDim.new(0,8)
-- handBarLayout.Parent = handBar


-- -- Layout horizontal: left/right
-- local layout = Instance.new("UIListLayout")
-- layout.FillDirection = Enum.FillDirection.Horizontal
-- layout.SortOrder = Enum.SortOrder.LayoutOrder
-- layout.Padding = UDim.new(0,10)
-- layout.Parent = mainFrame

-- -- Left Frame
-- local leftFrame = Instance.new("Frame")
-- leftFrame.Size = UDim2.new(0.4,0,1,0)
-- leftFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
-- leftFrame.Parent = mainFrame
-- Instance.new("UICorner", leftFrame).CornerRadius = UDim.new(0,12)

-- -- Character preview in left panel
-- local viewport = Instance.new("ViewportFrame")
-- viewport.Name = "CharacterPreview"
-- viewport.Size = UDim2.new(1, -20, 1, -20)
-- viewport.Position = UDim2.new(0, 10, 0, 10)
-- viewport.BackgroundTransparency = 1
-- viewport.Ambient = Color3.fromRGB(200, 200, 200)
-- viewport.LightDirection = Vector3.new(-1, -1, -1)
-- viewport.Parent = leftFrame

-- local worldModel = Instance.new("WorldModel")
-- worldModel.Parent = viewport

-- local previewCamera = Instance.new("Camera")
-- previewCamera.FieldOfView = 20
-- viewport.CurrentCamera = previewCamera

-- local characterClone: Model? = nil
-- local baseNeckC0: CFrame? = nil
-- local equippedPreviewModel: BasePart? = nil
-- local equippedMotor: Motor6D? = nil

-- local function clearCharacterClone()
-- 	if characterClone then
-- 		characterClone:Destroy()
-- 		characterClone = nil
-- 		baseNeckC0 = nil
-- 	end
-- end

-- local function getHumanoidRoot(model: Model): BasePart?
-- 	local hrp = model:FindFirstChild("HumanoidRootPart")
-- 	if hrp and hrp:IsA("BasePart") then return hrp end
-- 	return nil
-- end

-- local function getRightHand(model: Model): BasePart?
-- 	local part = model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
-- 	if part and part:IsA("BasePart") then return part end
-- 	return nil
-- end

-- local function cacheBaseNeckC0(model: Model)
-- 	local head = model:FindFirstChild("Head")
-- 	if not head then return end
-- 	local upper = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
-- 	if not upper then return end
-- 	for _, obj in ipairs(upper:GetChildren()) do
-- 		if obj:IsA("Motor6D") and obj.Part1 == head then
-- 			baseNeckC0 = obj.C0
-- 			return
-- 		end
-- 	end
-- end

-- local function setFishingMovement(character, canRun)
-- 	local humanoid = character:FindFirstChildOfClass("Humanoid")
-- 	if not humanoid then return end

-- 	if canRun then
-- 		humanoid.WalkSpeed = 16
-- 	else
-- 		humanoid.WalkSpeed = 10
-- 	end
-- end
-- local function clearEquippedOnPreview()
-- 	setFishingMovement(player.Character, true)

-- 	if equippedPreviewModel then
-- 		equippedPreviewModel.Parent = nil
-- 		equippedPreviewModel:Destroy()
-- 		equippedPreviewModel = nil
-- 	end

-- 	if equippedMotor then
-- 		equippedMotor:Destroy()
-- 		equippedMotor = nil
-- 	end
-- end

-- local function equipSelectedItemOnPreview(selectedIndex: number?)
-- 	clearEquippedOnPreview()
-- 	if not selectedIndex then return end
-- 	local slot = handSlots[selectedIndex]
-- 	if not slot or not slot.item then return end
-- 	local item = slot.item
-- 	local c = player.Character or player.CharacterAdded:Wait()
-- 	c.Archivable = true

-- 	if not item.Model or not c then return end
	
-- 	local hand = getRightHand(c)
-- 	if not hand then return end
-- 	if item.Type == "rod" then
-- 		setFishingMovement(player.Character, false)
-- 	end
-- 	local itemClone:Model = item.Model:Clone()
-- 	-- make sure all parts are non-colliding for preview
-- 	for _, d in ipairs(itemClone:GetDescendants()) do
-- 		if d:IsA("BasePart") then
-- 			d.CanCollide = false
-- 			d.Anchored = false
-- 		end
-- 	end
-- 	itemClone.Parent = characterClone
	
-- 	-- choose attach part
-- 	local attach: BasePart? = nil
-- 	if itemClone.PrimaryPart then
-- 		attach = itemClone.PrimaryPart
-- 	else
-- 		for _, d in ipairs(itemClone:GetDescendants()) do
-- 			if d:IsA("BasePart") then attach = d break end
-- 		end
-- 	end
-- 	if not attach then return end
	
-- 	-- create a Motor6D from hand to the item
-- 	local motor = Instance.new("Motor6D")
-- 	motor.Name = "ItemGrip"
-- 	motor.Part0 = hand
-- 	motor.Part1 = attach
-- 	motor.C0 = CFrame.new(attach.Size.X/4, -attach.Size.Z/2+ attach.Size.Z*0.2/2, -attach.Size.Y/2 + attach.Size.Y*0.2/2)
-- 	motor.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.pi/2, 0, 0)
-- 	motor.Parent = hand

-- 	attach.Parent = hand

-- 	equippedPreviewModel = attach
-- 	equippedMotor = motor
-- end

-- local function setupCharacterPreview(pl: Player)
-- 	clearCharacterClone()
-- 	local c = pl.Character or pl.CharacterAdded:Wait()
-- 	c.Archivable = true

-- 	local clone = c:Clone()
-- 	-- strip scripts for safety
-- 	for _, inst in ipairs(clone:GetDescendants()) do
-- 		if inst:IsA("Script") or inst:IsA("LocalScript") then
-- 			inst:Destroy()
-- 		end
-- 	end
-- 	clone.Parent = worldModel
-- 	characterClone = clone
-- 	cacheBaseNeckC0(clone)
	
-- 	local hrp = getHumanoidRoot(clone)
-- 	if not hrp then return end
	
-- 	-- camera placement: slightly above and in front looking at upper body
-- 	local lookAt = hrp.Position + Vector3.new(0, 0, 0)
-- 	local camOffset = Vector3.new(0, 0, 24)
-- 	previewCamera.CFrame = CFrame.new(lookAt + camOffset, lookAt)
-- 	previewCamera.Parent = worldModel
-- end

-- local function updatePreviewOrientation(mousePos: Vector2)
-- 	if not characterClone then return end
-- 	local hrp = getHumanoidRoot(characterClone)
-- 	if not hrp then return end
	
-- 	-- map mouse within leftFrame to yaw/pitch
-- 	local framePos = leftFrame.AbsolutePosition
-- 	local frameSize = leftFrame.AbsoluteSize
-- 	local relX = -math.clamp((mousePos.X - framePos.X) / math.max(frameSize.X, 1), 0, 1)
-- 	local relY = -math.clamp((mousePos.Y - framePos.Y) / math.max(frameSize.Y, 1), 0, 1)
-- 	local yaw = (relX - 0.5) * 1.2 -- +/- ~69 deg
-- 	local pitch = (0.5 - relY) * 0.6 -- +/- ~34 deg
	
-- 	-- rotate body yaw
-- 	local pos = hrp.Position
-- 	hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.pi, 0)
	
-- 	-- tilt head via neck if available
-- 	local upper = characterClone:FindFirstChild("UpperTorso") or characterClone:FindFirstChild("Torso")
-- 	local head = characterClone:FindFirstChild("Head")
-- 	if upper and head and baseNeckC0 then
-- 		for _, obj in ipairs(upper:GetChildren()) do
-- 			if obj:IsA("Motor6D") and obj.Part1 == head then
-- 				obj.C0 = baseNeckC0 * CFrame.Angles(pitch, 0, 0)
-- 				break
-- 			end
-- 		end
-- 	end
-- end


-- local function connectCharacter()
-- 	if player.Character then
-- 		setupCharacterPreview(player)
-- 	end
-- 	player.CharacterAdded:Connect(function()
-- 		setupCharacterPreview(player)
-- 	end)
-- end

-- connectCharacter()

-- -- Right Frame
-- local rightFrame = Instance.new("Frame")
-- rightFrame.Size = UDim2.new(0.6,0,1,0)
-- rightFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
-- rightFrame.Parent = mainFrame

-- Instance.new("UICorner", rightFrame).CornerRadius = UDim.new(0,12)
-- local padding = Instance.new("UIPadding")
-- padding.PaddingTop = UDim.new(0,10)
-- padding.PaddingBottom = UDim.new(0,10)
-- padding.PaddingLeft = UDim.new(0,10)
-- padding.PaddingRight = UDim.new(0,10)
-- padding.Parent = rightFrame

-- local rightLayout = Instance.new("UIListLayout")
-- rightLayout.FillDirection = Enum.FillDirection.Vertical
-- rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
-- rightLayout.Padding = UDim.new(0,10)
-- rightLayout.Parent = rightFrame

-- -- Inventory section
-- local inventoryFrame = Instance.new("Frame")
-- inventoryFrame.Size = UDim2.new(1,0,1,0)
-- inventoryFrame.BackgroundTransparency = 1
-- inventoryFrame.Parent = rightFrame

-- local grid = Instance.new("UIGridLayout")
-- grid.FillDirection = Enum.FillDirection.Horizontal
-- grid.SortOrder = Enum.SortOrder.LayoutOrder
-- grid.CellPadding = UDim2.new(0,0,0,0)
-- grid.CellSize = UDim2.new(1/5,0,1/5,0)
-- grid.Parent = inventoryFrame

-- -- Removed embedded hand section from the main panel; using permanent hand bar instead

-- --// Data containers
-- -- handSlots declared earlier to be used in equip function

-- -- Selection state
-- local selectedHand: number? = nil
-- local HAND_DEFAULT_COLOR = Color3.fromRGB(255, 0, 0)
-- local HAND_SELECTED_COLOR = Color3.fromRGB(255, 200, 0)

-- local function findHandIndexFromSlot(target: SlotData): number?
-- 	for i, s in pairs(handSlots) do
-- 		if s == target then return i end
-- 	end
-- 	return nil
-- end

-- local function updateHandSelectionVisual()
-- 	for i, s in pairs(handSlots) do
-- 		local isSelected = (selectedHand == i) and s.item ~= nil
-- 		s.slot.BorderColor3 = isSelected and HAND_SELECTED_COLOR or HAND_DEFAULT_COLOR
-- 	end
-- end

-- local function showPowerMeterIfRod()
-- 	local slot = selectedHand and handSlots[selectedHand] or nil
-- 	local shouldShow = slot ~= nil and slot.item ~= nil and slot.item.Type == "rod"
-- 	powerFrame.Visible = shouldShow
-- 	if not shouldShow then
-- 		charging = false
-- 		power01 = 0
-- 		powerFill.Size = UDim2.new(1, 0, 0, 0)
-- 	end
-- end

-- local function startCharging()
-- 	charging = true
-- end

-- local function stopChargingAndCast()
-- 	if not charging then return end
-- 	charging = false
-- 	Fishing.trySwingRodWithPower(player, selectedHand, handSlots, power01)
-- 	power01 = 0
-- 	powerFill.Size = UDim2.new(1, 0, 0, 0)
-- end

-- -- heartbeat update for charging
-- local RunService = game:GetService("RunService")
-- RunService.Heartbeat:Connect(function(dt)
-- 	if charging then
-- 		power01 = math.clamp(power01 + powerIncrementPerSecond * dt, 0, 1)
-- 		powerFill.Size = UDim2.new(1, 0, power01, 0)
-- 	end
-- end)

-- local function selectHandIndex(i: number)
-- 	local slot = handSlots[i]
-- 	if slot and slot.item then
-- 		selectedHand = i
-- 		equipSelectedItemOnPreview(selectedHand)
-- 	else
-- 		selectedHand = nil
-- 		clearEquippedOnPreview()
-- 		Fishing.clearBait()
-- 	end
-- 	updateHandSelectionVisual()
-- 	showPowerMeterIfRod()
-- end
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- -- Example items
-- local sampleItems: {InventoryItem} = {
-- 	{ Name="Fishing Rod", Icon="rbxassetid://12345678", Type="rod", Model=ReplicatedStorage:WaitForChild("FishingRodModel"), Id=1 },
-- 	{ Name="Fish", Icon="rbxassetid://12345578", Type="consumable", Model=nil, Id=2 },
-- }

-- --// Dragging State
-- local draggingItem: ImageLabel? = nil
-- local draggingData: InventoryItem? = nil
-- local originalSlot: SlotData? = nil
-- local offset = Vector2.new()

-- --// Helpers
-- local function makeSlot(parent: Instance, index: number, isHand: boolean): SlotData
-- 	local slot = Instance.new("ImageButton")
-- 	slot.Name = (isHand and "HandSlot" or "Slot") .. tostring(index)
-- 	slot.BackgroundColor3 = isHand and HAND_DEFAULT_COLOR or Color3.fromRGB(72, 255, 0)
	
-- 	slot.Parent = parent
-- 	slot.ScaleType = Enum.ScaleType.Fit
-- 	slot.Image = ""
-- 	-- Ensure visible size for permanent hand bar slots
-- 	if isHand then
-- 		slot.Size = UDim2.fromOffset(64, 64)
-- 	end
	
-- 	local slotData: SlotData = {slot=slot, item=nil}
-- 	return slotData
-- end


-- --// Drag system
-- local function beginDrag(slotData: SlotData)
-- 	if not slotData.item  then
-- 		selectedHand = findHandIndexFromSlot(slotData)
-- 		clearEquippedOnPreview()
-- 		updateHandSelectionVisual()
-- 		return
-- 	end
-- 	if not mainFrame.Visible then
-- 		selectedHand = findHandIndexFromSlot(slotData)
-- 		clearEquippedOnPreview()
-- 		updateHandSelectionVisual()
-- 		equipSelectedItemOnPreview(selectedHand)
-- 		return
-- 	end

-- 	draggingData = slotData.item
-- 	originalSlot = slotData
	
-- 	-- ghost image
-- 	local ghost = Instance.new("ImageLabel")
-- 	ghost.Size = UDim2.fromOffset(slotData.slot.AbsoluteSize.X, slotData.slot.AbsoluteSize.Y)
-- 	ghost.AnchorPoint = Vector2.new(0.5,0.5)
-- 	ghost.Image = slotData.item.Icon
-- 	ghost.BackgroundTransparency = 1
-- 	ghost.ZIndex = 10
-- 	ghost.Parent = screenGui
-- 	draggingItem = ghost
	
-- 	local mousePos = UserInputService:GetMouseLocation()
-- 	offset = Vector2.new(ghost.AbsoluteSize.X/2, ghost.AbsoluteSize.Y/2)
-- 	ghost.Position = UDim2.fromOffset(mousePos.X-offset.X, mousePos.Y-offset.Y)
	
-- 	-- clear slot
-- 	slotData.item = nil
-- 	updateSlotVisual(slotData)
-- 	-- clear selection if it was the selected hand slot
-- 	local idx = findHandIndexFromSlot(slotData)
-- 	if idx and selectedHand == idx then
-- 		selectedHand = nil
-- 		updateHandSelectionVisual()
-- 		clearEquippedOnPreview()
-- 	end
-- end

-- local function endDrag(mousePos: Vector2)
-- 	if not draggingItem or not draggingData or not originalSlot then return end
-- 	if mainFrame.Visible == false then
-- 		-- if inventory closed, return to original
-- 		originalSlot.item = draggingData
-- 		updateSlotVisual(originalSlot)
-- 		draggingItem:Destroy()
-- 		draggingItem, draggingData, originalSlot = nil, nil, nil
-- 		return
-- 	end
-- 	-- fix mouse pos relative to GUI inset
-- 	local guiInset = GuiService:GetGuiInset()
-- 	local mouseX, mouseY = mousePos.X, mousePos.Y - guiInset.Y
	
-- 	-- Try drop on hand slot
-- 	for i, handSlot in pairs(handSlots) do
-- 		local absPos, size = handSlot.slot.AbsolutePosition, handSlot.slot.AbsoluteSize
-- 		if mouseX >= absPos.X and mouseX <= absPos.X + size.X and
-- 		   mouseY >= absPos.Y and mouseY <= absPos.Y + size.Y then
-- 			handSlot.item = draggingData
-- 			updateSlotVisual(handSlot)
-- 			-- keep selection if selecting this filled slot
-- 			if selectedHand == i then
-- 				updateHandSelectionVisual()
-- 				-- re-equip model in case item changed
-- 				equipSelectedItemOnPreview(selectedHand)
-- 			end
-- 			draggingItem:Destroy()
-- 			draggingItem, draggingData, originalSlot = nil, nil, nil
-- 			return
-- 		end
-- 	end
	
-- 	-- Try drop on inventory slot
-- 	for _, invSlot in pairs(inventorySlots) do
-- 		local absPos, size = invSlot.slot.AbsolutePosition, invSlot.slot.AbsoluteSize
-- 		if mouseX >= absPos.X and mouseX <= absPos.X + size.X and
-- 		   mouseY >= absPos.Y and mouseY <= absPos.Y + size.Y then
-- 			invSlot.item = draggingData
-- 			updateSlotVisual(invSlot)
-- 			draggingItem:Destroy()
-- 			draggingItem, draggingData, originalSlot = nil, nil, nil
-- 			return
-- 		end
-- 	end
	
-- 	-- Else → return to original
-- 	originalSlot.item = draggingData
-- 	updateSlotVisual(originalSlot)
-- 	-- if we returned to a hand slot that is selected, refresh
-- 	local idxBack = findHandIndexFromSlot(originalSlot)
-- 	if idxBack and selectedHand == idxBack then
-- 		updateHandSelectionVisual()
-- 		-- re-equip model
-- 		equipSelectedItemOnPreview(selectedHand)
-- 	end
-- 	draggingItem:Destroy()
-- 	draggingItem, draggingData, originalSlot = nil, nil, nil
-- end

-- --// Mouse move update
-- UserInputService.InputChanged:Connect(function(input)
-- 	if draggingItem and input.UserInputType == Enum.UserInputType.MouseMovement then
-- 		local mousePos = UserInputService:GetMouseLocation()
-- 		draggingItem.Position = UDim2.fromOffset(mousePos.X-offset.X, mousePos.Y-offset.Y)
-- 	end
-- 	if input.UserInputType == Enum.UserInputType.MouseMovement and mainFrame.Visible then
-- 		updatePreviewOrientation(UserInputService:GetMouseLocation())
-- 	end
-- end)


-- UserInputService.InputEnded:Connect(function(input)
-- 	if input.UserInputType == Enum.UserInputType.MouseButton1 then
-- 		endDrag(UserInputService:GetMouseLocation())
-- 	end
-- end)

-- --// Create slots
-- for i=1,25 do
-- 	local slotData = makeSlot(inventoryFrame, i, false)
-- 	inventorySlots[i] = slotData
	
-- 	slotData.slot.MouseButton1Down:Connect(function()
-- 		beginDrag(slotData)
-- 	end)
-- end

-- for i=1,3 do
-- 	local slotData = makeSlot(handBar, i, true)
-- 	handSlots[i] = slotData
	
-- 	slotData.slot.MouseButton1Down:Connect(function()
-- 		beginDrag(slotData)
-- 	end)
-- end

-- --// Add example items
-- inventorySlots[1].item = sampleItems[1]
-- inventorySlots[2].item = sampleItems[2]
-- for _, s in pairs(inventorySlots) do updateSlotVisual(s) end

-- -- Keyboard shortcuts: Tab toggle and 1-3 hand selection
-- UserInputService.InputBegan:Connect(function(input)
-- 	if input.UserInputType == Enum.UserInputType.Keyboard then
-- 		if input.KeyCode == Enum.KeyCode.Tab then
-- 			mainFrame.Visible = not mainFrame.Visible
-- 		elseif input.KeyCode == Enum.KeyCode.One then
-- 			selectHandIndex(1)
-- 		elseif input.KeyCode == Enum.KeyCode.Two then
-- 			selectHandIndex(2)
-- 		elseif input.KeyCode == Enum.KeyCode.Three then
-- 			selectHandIndex(3)
-- 		end
-- 	end

-- 	if input.UserInputType == Enum.UserInputType.MouseButton1 and not mainFrame.Visible then
-- 		local slot = selectedHand and handSlots[selectedHand] or nil
-- 		if slot and slot.item and slot.item.Type == "rod" then
-- 			startCharging()
-- 		end
-- 	end
-- end)

-- UserInputService.InputEnded:Connect(function(input)
-- 	if input.UserInputType == Enum.UserInputType.MouseButton1 then
-- 		stopChargingAndCast()
-- 	end
-- end)
