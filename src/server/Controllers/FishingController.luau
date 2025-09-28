-- ServerScriptService/Controllers/FishingController.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local FishingService = require(game.ServerScriptService.Server.Services.FishingService)

local FishingController = {}
FishingController.__index = FishingController
function FishingController:Init()
    local fishingCast = Remotes.FishingCast()
    fishingCast.OnServerEvent:Connect(function(player, data)
        local luck = data.rod.luck or 0
        local fish = FishingService.RollFish(luck)

        fishingCast:FireClient(player, {
            fish = fish,
            rod = data.rod,
            position = data.position,
        })
    end)
end

return FishingController
