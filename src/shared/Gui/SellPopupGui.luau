local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SellPopupGui"

local SellFrame = Instance.new("Frame")
SellFrame.Name = "SellFrame"
SellFrame.Size = UDim2.new(0, 300, 0, 200)
SellFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
SellFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SellFrame.Parent = ScreenGui

local TotalValue = Instance.new("TextLabel")
TotalValue.Name = "TotalValue"
TotalValue.Size = UDim2.new(1, 0, 0.5, 0)
TotalValue.Position = UDim2.new(0, 0, 0, 0)
TotalValue.BackgroundTransparency = 1
TotalValue.TextColor3 = Color3.fromRGB(255, 255, 255)
TotalValue.TextScaled = true
TotalValue.Text = "Total Value: 0 Money"
TotalValue.Parent = SellFrame

local ConfirmButton = Instance.new("TextButton")
ConfirmButton.Name = "ConfirmButton"
ConfirmButton.Size = UDim2.new(0.5, -10, 0.3, 0)
ConfirmButton.Position = UDim2.new(0, 5, 0.7, 0)
ConfirmButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
ConfirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmButton.TextScaled = true
ConfirmButton.Text = "Confirm"
ConfirmButton.Parent = SellFrame

local CancelButton = Instance.new("TextButton")
CancelButton.Name = "CancelButton"
CancelButton.Size = UDim2.new(0.5, -10, 0.3, 0)
CancelButton.Position = UDim2.new(0.5, 5, 0.7, 0)
CancelButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CancelButton.TextScaled = true
CancelButton.Text = "Cancel"
CancelButton.Parent = SellFrame

return ScreenGui