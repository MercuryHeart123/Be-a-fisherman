local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local SelectiveSellUI = require(script.Parent.Parent.UI.SelectiveSellUI)
local InteractionController = {}

local player = Players.LocalPlayer
local MAX_DISTANCE = 10 -- ระยะห่างที่สามารถคุยได้ (ปรับได้)

local currentTargetNpc = nil -- NPC ที่กำลังอยู่ในระยะ
local interactionPrompt = nil -- ป้ายข้อความของ NPC

local InventoryController = require(script.Parent.InventoryController)

function InteractionController:Init()
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local myPos = character.HumanoidRootPart.Position
		local sellNpc = workspace:FindFirstChild("SellNPC")

		if sellNpc and sellNpc:FindFirstChild("HumanoidRootPart") then
			local npcPos = sellNpc.HumanoidRootPart.Position
			local distance = (myPos - npcPos).Magnitude

			-- ถ้าอยู่ในระยะ
			if distance <= MAX_DISTANCE then
				if not currentTargetNpc then -- ถ้าเพิ่งเข้ามาในระยะ
					print("In range of NPC")
					currentTargetNpc = sellNpc
					interactionPrompt = sellNpc.Head:FindFirstChild("BillboardGui")
					if interactionPrompt then
						interactionPrompt.Enabled = true
					end
				end
			-- ถ้าอยู่นอกระยะ
			else
				if currentTargetNpc then -- ถ้าเพิ่งเดินออกมา
					print("Out of range of NPC")
					if interactionPrompt then
						interactionPrompt.Enabled = false
					end
					SelectiveSellUI:SetVisible(false)
					currentTargetNpc = nil
					interactionPrompt = nil
				end
			end
		end
	end)

	-- ดักฟังการกดปุ่ม
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.E and currentTargetNpc then
			-- เช็คว่าหน้าต่างขายของเปิดอยู่หรือไม่
			if SelectiveSellUI:GetVisible() then
				-- ถ้าเปิดอยู่ ให้สั่งปิด
				SelectiveSellUI:SetVisible(false)
			else
				-- ถ้าปิดอยู่ ให้สั่งเปิด (เหมือนเดิม)
				InventoryController:OpenSellUI()
			end
		end
	end)
	print("✅ InteractionController initialized")
end

return InteractionController
