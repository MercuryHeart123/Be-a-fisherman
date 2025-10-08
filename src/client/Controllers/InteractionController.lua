local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InteractionController = {}

local player = Players.LocalPlayer
local MAX_DISTANCE = 10 -- ระยะห่างที่สามารถคุยได้ (ปรับได้)

local currentTargetNpc = nil -- NPC ที่กำลังอยู่ในระยะ
local interactionPrompt = nil -- ป้ายข้อความของ NPC

function InteractionController:Init()
	local requestSellRemote = Remotes.RequestSell()

	-- Loop ตรวจสอบระยะห่างตลอดเวลา
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

		-- ถ้ากด E และอยู่ในระยะ NPC
		if input.KeyCode == Enum.KeyCode.E and currentTargetNpc then
			print("Client: E pressed. Firing RequestSell to server.")
			requestSellRemote:FireServer()
		end
	end)

	print("✅ InteractionController initialized")
end

return InteractionController
