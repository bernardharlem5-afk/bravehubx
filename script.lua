-- // Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- // UI Library
local repo = 'https://raw.githubusercontent.com/VardySc/XternalNew/main/'
local library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local thememanager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local savemanager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local game_name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

local window = library:CreateWindow({
    Title = 'Axiom | ' .. game_name,
    Center = true,
    AutoShow = true,
    Position = UDim2.new(0.5, -200, 0.5, -150),
    Size = UDim2.new(0, 400, 0, 412)
})

local tabs = {
    Aimbot = window:AddTab('Aimbot'),
    Config = window:AddTab('Config')
}

-- // Sections
local AimbotSection = tabs.Aimbot:AddLeftGroupbox("Aimbot")
local MagSection = tabs.Aimbot:AddRightGroupbox("Reach")
local OOBSection = tabs.Aimbot:AddLeftGroupbox("OOB")
local AutoGuardSection = tabs.Aimbot:AddLeftGroupbox("Auto Guard")
local AntiTravelSection = tabs.Aimbot:AddLeftGroupbox("Anti Travel / Fall")
local AutoShootSection = tabs.Aimbot:AddLeftGroupbox("Auto Shoot")

-- // FPS + Ping Watermark
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60
RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    library:SetWatermark(('Axiom | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)

-- // Camlock
local CamlockEnabled = false
local function Camlock()
    local Player = LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Camera = workspace.CurrentCamera
    local Humanoid = Character:WaitForChild("Humanoid")

    local function IsHoldingBasketball()
        local Basketball = Character:FindFirstChild("Basketball")
        return Basketball and Basketball:FindFirstChild("Ball")
    end

    local function GetGoal()
        local Distance, Goal = math.huge, nil
        local CharacterPosition = Character.PrimaryPart.Position  

        local function CheckHoops(container)
            if not container then return end
            for _, court in ipairs(container:GetChildren()) do
                for _, Obj in ipairs(court:GetDescendants()) do
                    if Obj.Name == "Swish" and Obj.Parent:FindFirstChildOfClass("TouchTransmitter") then
                        local HoopPosition = Obj.Parent.Position
                        local Magnitude = (CharacterPosition - HoopPosition).Magnitude
                        if Magnitude < Distance then
                            Distance = Magnitude
                            Goal = Obj.Parent
                        end
                    end
                end
            end
        end

        CheckHoops(workspace:FindFirstChild("Courts"))
        CheckHoops(workspace:FindFirstChild("PracticeArea"))

        return Goal, Distance
    end

    local function GetMobileArc(dist)
        local baseArc = ({
            [59] = 20, [60] = 20, [61] = 20, [62] = 20,
            [63] = 18, [64] = 18, [65] = 18,
            [66] = 15, [67] = 15,
            [68] = 13, [69] = 13,
            [70] = 10, [71] = 10
        })[dist] or 8
        return baseArc + 2
    end

    local function AdjustCameraForJump()
        if not CamlockEnabled or not IsHoldingBasketball() then return end
        
        local Goal, Distance = GetGoal()
        if Goal then
            local ArcAdjustment = GetMobileArc(math.floor(Distance))
            local BasketPosition = Goal.Position + Vector3.new(0, ArcAdjustment, 0)
            local OldCFrame = Camera.CFrame
            Player.DevEnableMouseLock = false
            Camera.CFrame = CFrame.new(Player.Character.Head.Position, BasketPosition)
            firesignal(Player.PlayerGui.Button.MouseButton1Click)
            Camera.CFrame = OldCFrame
            Player.DevEnableMouseLock = false
        end
    end

    local function ResetCamera()
        Camera.CameraType = Enum.CameraType.Custom
    end

    Humanoid.StateChanged:Connect(function(_, NewState)
        if CamlockEnabled and NewState == Enum.HumanoidStateType.Jumping then
            AdjustCameraForJump()
        elseif NewState == Enum.HumanoidStateType.Landed then
            ResetCamera()
        end
    end)
end
Camlock()

AimbotSection:AddToggle('CamlockToggle', {
    Text = 'Enable Camlock',
    Default = false,
    Tooltip = 'Locks camera to hoop when you jump with ball',
    Callback = function(Value)
        CamlockEnabled = Value
    end
})

-- // Ball Grab / Mag
local BallGrabEnabled = false
local BallGrabDistance = 50

MagSection:AddToggle('BallGrabToggle', {
    Text = 'Enable Mag',
    Default = false,
    Tooltip = 'Automatically grab nearby balls',
    Callback = function(Value)
        BallGrabEnabled = Value
    end
})

MagSection:AddSlider('BallGrabSlider', {
    Text = 'Mag distance',
    Default = 50,
    Min = 0,
    Max = 150,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        BallGrabDistance = Value
    end
})

-- // OOB Toggle
local deletedOOBs = {}
local oobDeleted = false
OOBSection:AddToggle("OOBToggle", {
    Text = "Delete OOB",
    Default = false,
    Tooltip = "Deletes/restores OOB folders in all courts",
    Callback = function(state)
        if state then
            deletedOOBs = {}
            for _, court in pairs(workspace.Courts:GetChildren()) do
                local oob = court:FindFirstChild("OOB")
                if oob then
                    deletedOOBs[court] = oob:Clone()
                    oob:Destroy()
                end
            end
            oobDeleted = true
        else
            if oobDeleted then
                for court, oobClone in pairs(deletedOOBs) do
                    if court and court.Parent then
                        oobClone.Parent = court
                    end
                end
                deletedOOBs = {}
                oobDeleted = false
            end
        end
    end
})

-- // Auto Guard
local autoGuardEnabled = false
local autoGuardLoopRunning = false
local autoGuardConnection = nil

AutoGuardSection:AddToggle("AutoGuardToggle", {
	Text = "Enable Auto Guard",
	Default = false,
	Tooltip = "Automatically follows target player with the ball",
	Callback = function(state)
		autoGuardEnabled = state
		if autoGuardEnabled then
			-- start loop
		else
			-- stop loop
		end
	end
})

-- // Anti Travel / Anti Fall toggles
local antiTravelEnabled = false
local antiFallEnabled = false

AntiTravelSection:AddToggle("AntiTravelToggle", {
    Text = "Anti Travel",
    Default = false,
    Tooltip = "Jump all you want, no travel call",
    Callback = function(state)
        antiTravelEnabled = state
    end
})

AntiTravelSection:AddToggle("AntiFallToggle", {
    Text = "Anti Fall",
    Default = false,
    Tooltip = "Prevents fall damage / broken ankles",
    Callback = function(state)
        antiFallEnabled = state
    end
})

-- // Auto Shoot
local autoShootEnabled = false
local shootRangeIndicator = Instance.new("BoxHandleAdornment")
shootRangeIndicator.Adornee = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
shootRangeIndicator.Size = Vector3.new(6,6,6)
shootRangeIndicator.Color3 = Color3.fromRGB(0,255,0)
shootRangeIndicator.AlwaysOnTop = true
shootRangeIndicator.Visible = false
shootRangeIndicator.Parent = workspace

AutoShootSection:AddToggle("AutoShootToggle", {
    Text = "Auto Shoot",
    Default = false,
    Tooltip = "Automatically shoots when jumping near rim",
    Callback = function(state)
        autoShootEnabled = state
        shootRangeIndicator.Visible = state
    end
})

-- // Config Section
savemanager:SetLibrary(library)
thememanager:SetLibrary(library)
thememanager:SetFolder('camlock')
savemanager:SetFolder('saint')
thememanager:ApplyToTab(tabs.Config)
savemanager:BuildConfigSection(tabs.Config)

-- // Hide / Show UI
local Ui22 = Instance.new("ScreenGui")
Ui22.Name = "Ui22"
Ui22.Parent = game.CoreGui
Ui22.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Ui22.ResetOnSpawn = false

local Image3 = Instance.new("TextButton")
Image3.Name = "Image3"
Image3.Parent = Ui22
Image3.Active = true
Image3.Draggable = true
Image3.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Image3.BackgroundTransparency = 0.3
Image3.Size = UDim2.new(0, 100, 0, 50)
Image3.Position = UDim2.new(1, -150, 0, 20)
Image3.Text = "Hide UI"
Image3.TextColor3 = Color3.fromRGB(200, 200, 200)
Image3.TextSize = 16
Image3.Font = Enum.Font.Gotham
Image3.BorderSizePixel = 0

local Ui2corner = Instance.new("UICorner")
Ui2corner.CornerRadius = UDim.new(0, 15)
Ui2corner.Parent = Image3

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 2
UIStroke.Parent = Image3

local Open = true
Image3.MouseButton1Click:Connect(function()
    Open = not Open
    library:Toggle(Open)
    if Open then
        Image3.Text = "Hide UI"
        Image3.BackgroundColor3 = Color3.fromRGB(30,30,30)
    else
        Image3.Text = "Show UI"
        Image3.BackgroundColor3 = Color3.fromRGB(50,50,50)
    end
end)

-- // Notifications
library:Notify("Saint Hub Rework", "Loaded successfully")
library:Notify("Discord", "Join: https://discord.gg/uhgsvXycU3")
