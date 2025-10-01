-- StarterPlayerScripts/Client/Controllers/UserController.lua
local Players = game:GetService("Players")

local UserController = {}
UserController.__index = UserController
player = nil
function UserController:GetLocalUser()
	if not player then
		player = Players.LocalPlayer
	end
	return player
end

function UserController:SetSpeedToRun(canRun: boolean)
	local humanoid = player.character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if canRun then
		humanoid.WalkSpeed = 16
	else
		humanoid.WalkSpeed = 10
	end
end

return UserController
