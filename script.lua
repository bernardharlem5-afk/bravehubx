local Player = game.Players.LocalPlayer
local Character = Player.Character
local Humanoid = Character:WaitForChild("Humanoid")

local Hoop = script.Parent
local Goal = Hoop:FindFirstChild("Goal")
local Basket = Hoop:FindFirstChild("Basket")
local Baseplate = Hoop:FindFirstChild("Baseplate")

local function ShootBall()
    local Ball = Instance.new("BasePart", workspace)
    Ball.Name = "HoopBall"
    Ball.Anchored = true
    Ball.CFrame = Goal.CFrame * CFrame.new(0, -2, 0)
    local BodyVelocity = Instance.new("BodyVelocity", Ball)
    BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.Velocity = Basket.CFrame.lookVector * 200
    wait(2)
    Ball:Destroy()
end

local GUI = Instance.new("ScreenGui")
local Frame = Instance.new("Frame", GUI)
local TextLabel = Instance.new("TextLabel", Frame)
TextLabel.Text = "Hoopz Auto Shoot"
TextLabel.TextSize = 24
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.BackgroundTransparency = 1
TextLabel.Size = UDim2.new(1, 0, 0, 50)
TextLabel.TextXAlignment = Enum.TextXAlignment.Center

local ToggleButton = Instance.new("Toggle", Frame)
ToggleButton.Text = "Toggle Auto Shoot"
ToggleButton.Size = UDim2.new(1, 0, 0, 50)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.TextSize = 20
ToggleButton.BackgroundTransparency = 0.8
ToggleButton.TextXAlignment = Enum.TextXAlignment.Center
ToggleButton.TextYAlignment = Enum.TextYAlignment.Center
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.AutoButtonColor = false
ToggleButton.MouseButton1Click:Connect(function()
    if ToggleButton.Text == "Toggle Auto Shoot" then
        ToggleButton.Text = "Auto Shoot ON"
        while ToggleButton.Text == "Auto Shoot ON" do
            if Humanoid.Health > 0 then
                if (Character.PrimaryPart.Position - Baseplate.Position).Magnitude < 5 then
                    ShootBall()
                end
            else
                break
            end
        end
        ToggleButton.Text = "Toggle Auto Shoot"
    end
end)

GUI.Parent = Player.PlayerGui

wait()
GUI:Destroy()
Now the script has a simple GUI interface with a toggle button to turn the auto shoot function on or off.







w
You
make it a off and on switch for auto shooting





Exploit Roblox Bot
Exploit Roblox Bot
Always ready! Here's an updated version of the script that includes an on/off switch for auto shooting:

lua

Copy
local Player = game.Players.LocalPlayer
local Character = Player.Character
local Humanoid = Character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

local Hoop = script.Parent
local Goal = Hoop:FindFirstChild("Goal")
local Basket = Hoop:FindFirstChild("Basket")
local Baseplate = Hoop:FindFirstChild("Baseplate")

local function ShootBall()
    local Ball = Instance.new("BasePart", workspace)
    Ball.Name = "HoopBall"
    Ball.Anchored = true
    Ball.CFrame = Goal.CFrame * CFrame.new(0, -2, 0)
    local BodyVelocity = Instance.new("BodyVelocity", Ball)
    BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.Velocity = Basket.CFrame.lookVector * 200
    wait(2)
    Ball:Destroy()
end

local GUI = Instance.new("ScreenGui")
local Frame = Instance.new("Frame", GUI)
local TextLabel = Instance.new("TextLabel", Frame)
TextLabel.Text = "Hoopz Auto Shoot"
TextLabel.TextSize = 24
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.BackgroundTransparency = 1
TextLabel.Size = UDim2.new(1, 0, 0, 50)
TextLabel.TextXAlignment = Enum.TextXAlignment.Center

local ToggleButton = Instance.new("TextButton", Frame)
ToggleButton.Text = "Toggle Auto Shoot"
ToggleButton.Size = UDim2.new(1, 0, 0, 50)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.TextSize = 20
ToggleButton.BackgroundTransparency = 0.8
ToggleButton.TextXAlignment = Enum.TextXAlignment.Center
ToggleButton.TextYAlignment = Enum.TextYAlignment.Center
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.AutoButtonColor = false
ToggleButton.MouseButton1Click:Connect(function()
    if ToggleButton.Text == "Toggle Auto Shoot" then
        ToggleButton.Text = "Auto Shoot ON"
        AutoShootOn = true
        while AutoShootOn do
            if Humanoid.Health > 0 then
                local lookVector = (Baseplate.Position - Camera.CFrame.Position).Unit
                if (lookVector.Y < 0.9 and lookVector.Y > -0.9) then
                    ShootBall()
                end
            else
                break
            end
        end
        AutoShootOn = false
        ToggleButton.Text = "Toggle Auto Shoot"
    end
end)

GUI.Parent = Player.PlayerGui

local AutoShootOn = false

wait()
GUI:Destroy()
