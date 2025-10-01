-- ServerScriptService/Controllers/FishingController.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local FishingService = require(game.ServerScriptService.Server.Services.FishingService)

local FishingController = {}
FishingController.__index = FishingController
function FishingController:Init()
	local fishingCast = Remotes.FishingCast()
	fishingCast.OnServerEvent:Connect(function(player, data)
		if typeof(data) ~= "table" then
			return
		end

		local rodData = data.rod or {}
		local baseLuck = rodData.luck or rodData.Luck or 0
		local bonusLuck = data.bonusLuck or 0
		local totalLuck = baseLuck + bonusLuck

		local fish = FishingService.RollFish(totalLuck)

		fishingCast:FireClient(player, {
			fish = fish,
			rod = rodData,
			position = data.position,
			bonusLuck = bonusLuck,
		})
	end)
end

return FishingController
