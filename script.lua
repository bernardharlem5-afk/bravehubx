-- ============================================================
-- FATAL LABS — Arcade Basketball + Basketball Legends + Hoopz
-- ============================================================

local _print, _warn = print, warn
print = function() end
warn = function() end

local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"))()
Airflow:LoadFont({Name = "ValleySans"})

Airflow.Themes.FatalBlue = {
    Background  = Color3.fromRGB(5,   10,  22),
    Surface     = Color3.fromRGB(9,   16,  34),
    Surface2    = Color3.fromRGB(13,  22,  45),
    Surface3    = Color3.fromRGB(20,  32,  60),
    Stroke      = Color3.fromRGB(28,  45,  90),
    StrokeHover = Color3.fromRGB(55,  90, 180),
    Accent      = Color3.fromRGB(60,  120, 255),
    AccentDark  = Color3.fromRGB(8,   18,  50),
    Text        = Color3.fromRGB(220, 230, 255),
    Muted       = Color3.fromRGB(110, 140, 200),
    Glow        = Color3.fromRGB(60,  120, 255),
    Warning     = Color3.fromRGB(240, 176, 108),
    Success     = Color3.fromRGB(150, 220, 170),
    Error       = Color3.fromRGB(240, 120, 120),
}

Airflow.Assets.Logo = "rbxassetid://114259170836940"

-- ============================================================
-- GAME ID WHITELIST
-- ============================================================
local ARCADE_IDS = {
    [134558434771720] = true,
    [130736793665498] = true,
    [92216849541624]  = true,
    [95439417741900]  = true,
}

local BL_IDS = {
    [14386691987]    = true,
    [71832465156084] = true,
    [17652855195]    = true,
}

local isArcade = ARCADE_IDS[game.PlaceId] == true
local isBL     = BL_IDS[game.PlaceId] == true

-- ============================================================
-- SHARED THEME
-- ============================================================


-- ============================================================
-- SHARED SERVICES
-- ============================================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInput        = game:GetService("VirtualInputManager")
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local isMobile    = UserInputService.TouchEnabled

-- ============================================================
-- SHARED HVH ENGINE (HipHeight + Swim + Speed + InfJump)
-- ============================================================
local HVH = {
    active = false,
    conn = nil,
    swimEngaged = false,
    infJumpState = {
        conn = nil,
        charBind = nil,
    },
    cfg = nil,
}

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char,
        char:FindFirstChild("Humanoid"),
        char:FindFirstChild("HumanoidRootPart")
end

local function hvhStart()
    if HVH.conn then HVH.conn:Disconnect(); HVH.conn = nil end
    if not HVH.cfg then return end

    HVH.active = true
    HVH.swimEngaged = false

    HVH.conn = RunService.Heartbeat:Connect(function()
        local cfg = HVH.cfg
        if not cfg then return end

        local char, hum, hrp = getChar()

        if cfg.HipHeight.Enabled and hum then
            if hum.HipHeight ~= cfg.HipHeight.Value then
                hum.HipHeight = cfg.HipHeight.Value
            end
        end

        if not hum then return end

        if cfg.Swim.Enabled then
            if hum.FloorMaterial ~= Enum.Material.Air then
                HVH.swimEngaged = false
            else
                local st = hum:GetState()
                if st ~= Enum.HumanoidStateType.Swimming then
                    hum:ChangeState(Enum.HumanoidStateType.Swimming)
                    if not HVH.swimEngaged and hrp then
                        local v = hrp.AssemblyLinearVelocity
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                        HVH.swimEngaged = true
                    end
                end
                if hrp then
                    local v = hrp.AssemblyLinearVelocity
                    local cap = 20 * (cfg.Swim.Power or 1)
                    if v.Y > cap then
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, cap, v.Z)
                    end
                end
            end
        else
            HVH.swimEngaged = false
        end

        if cfg.InfiniteJump.Enabled and hrp then
            local held = UserInputService:IsKeyDown(Enum.KeyCode.Space)
                or (isMobile and hum.Jump)
            if held then
                local st = hum:GetState()
                if st == Enum.HumanoidStateType.Freefall
                    or st == Enum.HumanoidStateType.Jumping then
                    hum.Jump = false
                    task.wait()
                    hum.Jump = true
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    local v = hrp.AssemblyLinearVelocity
                    local cap = 50 * (cfg.InfiniteJump.Power or 1)
                    if v.Y > cap then
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, cap, v.Z)
                    end
                end
            end
        end

        if cfg.Speed.Enabled and hrp and hum.MoveDirection.Magnitude > 0.05 then
            local mult = cfg.Speed.Multiplier or 1.35
            local targetVel = hum.MoveDirection.Unit * (16 * mult)
            local y = hrp.AssemblyLinearVelocity.Y
            hrp.AssemblyLinearVelocity = Vector3.new(targetVel.X, y, targetVel.Z)
        end
    end)
end

local function hvhStop()
    HVH.active = false
    if HVH.conn then HVH.conn:Disconnect(); HVH.conn = nil end
    HVH.swimEngaged = false
end

local function hvhResetAll()
    local cfg = HVH.cfg
    if not cfg then return end
    cfg.HipHeight.Enabled = false
    cfg.Swim.Enabled = false
    cfg.InfiniteJump.Enabled = false
    cfg.Speed.Enabled = false
    local char, hum = getChar()
    if hum then
        hum.HipHeight = cfg.HipHeight.Default
        if hum:GetState() == Enum.HumanoidStateType.Swimming then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

local function buildHVHTab(tab, cfg)
    tab:CreateSection("HipHeight")
    tab:CreateToggle({
        Name = "HipHeight changer",
        Desc = "Overrides your Humanoid.HipHeight each frame.",
        Flag = "hvh_hipheight",
        CurrentValue = cfg.HipHeight.Enabled,
        Callback = function(v) cfg.HipHeight.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "HipHeight value",
        Range = { -5, 20 }, Increment = 0.5, Suffix = " studs",
        CurrentValue = cfg.HipHeight.Value, Flag = "hvh_hipheight_val",
        Callback = function(v)
            cfg.HipHeight.Value = v
            local _, hum = getChar()
            if hum and cfg.HipHeight.Enabled then hum.HipHeight = v end
        end,
    })

    tab:CreateSection("Swim")
    tab:CreateToggle({
        Name = "Swim",
        Desc = "Forces swimming while airborne. Velocity is clamped to prevent launch.",
        Flag = "hvh_swim",
        CurrentValue = cfg.Swim.Enabled,
        Callback = function(v) cfg.Swim.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "Swim power",
        Desc = "Caps upward velocity while swimming (lower = less launch).",
        Range = { 0.1, 5 }, Increment = 0.1,
        CurrentValue = cfg.Swim.Power, Flag = "hvh_swim_power",
        Callback = function(v) cfg.Swim.Power = v end,
    })

    tab:CreateSection("Speed")
    tab:CreateToggle({
        Name = "Speed boost",
        Flag = "hvh_ws",
        CurrentValue = cfg.Speed.Enabled,
        Callback = function(v) cfg.Speed.Enabled = v end,
    })
    tab:CreateKeybind({
        Name = "Speed keybind",
        Flag = "hvh_ws_key",
        CurrentValue = cfg.Speed.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then cfg.Speed.Keybind = key end
        end,
    })
    tab:CreateSlider({
        Name = "Speed multiplier",
        Range = { 1, 3 }, Increment = 0.05,
        CurrentValue = cfg.Speed.Multiplier, Flag = "hvh_ws_val",
        Callback = function(v) cfg.Speed.Multiplier = v end,
    })

    tab:CreateSection("Infinite Jump")
    tab:CreateToggle({
        Name = "Infinite Jump",
        Desc = "Hold space to keep jumping (yields jump cooldown).",
        Flag = "hvh_infjump",
        CurrentValue = cfg.InfiniteJump.Enabled,
        Callback = function(v) cfg.InfiniteJump.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "Infinite Jump power",
        Desc = "Caps upward velocity after re-jumping.",
        Range = { 0.1, 5 }, Increment = 0.1,
        CurrentValue = cfg.InfiniteJump.Power, Flag = "hvh_infjump_power",
        Callback = function(v) cfg.InfiniteJump.Power = v end,
    })
end

-- ============================================================
-- BRANCH: ARCADE BASKETBALL
-- ============================================================
if isArcade then
    local Settings = {
        Shooting = {
            AutoGreen = false,
            AutoGreenKeybind = Enum.KeyCode.E,
            AutoGreenOnShootButton = true,
        },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1 },
        },
        AntiContest = {
            Enabled = false,
            Keybind = Enum.KeyCode.E,
            Height = 25,
        },
        BallSize = {
            Enabled = false,
            Size = 6,
            Transparency = 0.5,
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {} }
    local function Track(c) if c then table.insert(Cleanup.conns, c) end return c end

    local ShootRemote = nil
    local function resolveShootRemote()
        if ShootRemote and ShootRemote.Parent then return ShootRemote end
        pcall(function()
            local Events = ReplicatedStorage:FindFirstChild("Events")
            ShootRemote = Events and Events:FindFirstChild("Shoot")
        end)
        return ShootRemote
    end

    local function fireAutoGreen()
        local remote = resolveShootRemote()
        if not remote then return false end
        local ok = pcall(function()
            remote:FireServer(true, 100, false)
        end)
        pcall(function()
            remote:FireServer(false, -1, true)
        end)
        return ok
    end

    local greenLock = false
    local function fireAutoGreenSafe()
        if greenLock then return end
        greenLock = true
        fireAutoGreen()
        task.delay(0.15, function() greenLock = false end)
    end

    local ballResizeConn = nil
    local trackedBalls = {}
    local origData     = {}

    local function isBallPart(inst)
        if not inst:IsA("BasePart") then return false end
        return string.lower(inst.Name):find("ball", 1, true) ~= nil
    end

    local function addTrackedBall(inst)
        if not isBallPart(inst) or trackedBalls[inst] then return end
        trackedBalls[inst] = true
        origData[inst] = { Size = inst.Size, Transparency = inst.Transparency }
        if s.BallSize.Enabled then
            local size = tonumber(s.BallSize.Size) or 6
            local trans = tonumber(s.BallSize.Transparency) or 0.5
            pcall(function()
                inst.Size = Vector3.new(size, size, size)
                inst.Transparency = trans
            end)
        end
    end

    local function removeTrackedBall(inst)
        trackedBalls[inst] = nil
        origData[inst] = nil
    end

    local function applyBallSize()
        local size = tonumber(s.BallSize.Size) or 6
        local trans = tonumber(s.BallSize.Transparency) or 0.5
        for part in pairs(trackedBalls) do
            if part.Parent then
                pcall(function()
                    part.Size = Vector3.new(size, size, size)
                    part.Transparency = trans
                end)
            else
                removeTrackedBall(part)
            end
        end
    end

    local function restoreBallSize()
        for part, data in pairs(origData) do
            if part.Parent then
                pcall(function()
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                end)
            end
        end
        table.clear(origData)
        table.clear(trackedBalls)
    end

    local ballAddedConn, ballRemovedConn = nil, nil
    local function enableBallResizer()
        for _, inst in ipairs(workspace:GetDescendants()) do addTrackedBall(inst) end
        ballAddedConn = workspace.DescendantAdded:Connect(function(inst)
            if isBallPart(inst) then
                task.defer(function() addTrackedBall(inst) end)
            end
        end)
        ballRemovedConn = workspace.DescendantRemoving:Connect(function(inst)
            if isBallPart(inst) then removeTrackedBall(inst) end
        end)
        applyBallSize()
        if ballResizeConn then ballResizeConn:Disconnect() end
        ballResizeConn = RunService.Heartbeat:Connect(function()
            if s.BallSize.Enabled then applyBallSize() end
        end)
        Track(ballResizeConn)
    end

    local function disableBallResizer()
        if ballAddedConn then ballAddedConn:Disconnect(); ballAddedConn = nil end
        if ballRemovedConn then ballRemovedConn:Disconnect(); ballRemovedConn = nil end
        if ballResizeConn then ballResizeConn:Disconnect(); ballResizeConn = nil end
        restoreBallSize()
    end

    local antiContestLock = false
    local function doAntiContest()
        if antiContestLock then return end
        antiContestLock = true
        task.delay(0.1, function() antiContestLock = false end)
        local _, _, hrp = getChar()
        if not hrp then return end
        local height = tonumber(s.AntiContest.Height) or 25
        hrp.CFrame = hrp.CFrame + Vector3.new(0, height, 0)
    end

    local Window = Airflow:CreateWindow({Name = "Fatal Labs", LoadingSubtitle = "Fatal Labs basketball suite", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "FatalLabs", FileName = "FatalLabs"}})

    local Notify = function(props) pcall(function() Window:Notify(props) end) end

    local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "HVH", Icon = "activity" })

    CombatTab:CreateSection("Auto Green")
    CombatTab:CreateToggle({
        Name = "Auto Green",
        Desc = "Fires Events.Shoot with the perfect-shot sequence.",
        Flag = "ab_autogreen",
        CurrentValue = s.Shooting.AutoGreen,
        Callback = function(v) s.Shooting.AutoGreen = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto Green keybind",
        Desc = "Hold then RELEASE this key to fire a green shot.",
        Flag = "ab_autogreen_key",
        CurrentValue = s.Shooting.AutoGreenKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AutoGreenKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Shoot button",
        Desc = "Fires the remote INSTANTLY when you RELEASE the in-game Shoot button.",
        Flag = "ab_autogreen_btn",
        CurrentValue = s.Shooting.AutoGreenOnShootButton,
        Callback = function(v) s.Shooting.AutoGreenOnShootButton = v end,
    })
    CombatTab:CreateButton({
        Name = "Fire Green Now",
        Callback = function()
            if fireAutoGreen() then
                Notify({ title = "Auto Green", content = "Shot fired.", duration = 2 })
            else
                Notify({ title = "Auto Green", content = "Remote not found.", duration = 3 })
            end
        end,
    })

    CombatTab:CreateSection("Anti Contest")
    CombatTab:CreateToggle({
        Name = "Anti Contest",
        Desc = "Press E to teleport straight up (dodges contests).",
        Flag = "ab_ac",
        CurrentValue = s.AntiContest.Enabled,
        Callback = function(v) s.AntiContest.Enabled = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Anti Contest keybind",
        Desc = "Press this key to jump straight up.",
        Flag = "ab_ac_key",
        CurrentValue = s.AntiContest.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.AntiContest.Keybind = key end
        end,
    })
    CombatTab:CreateSlider({
        Name = "Anti Contest height",
        Range = { 1, 25 }, Increment = 1, Suffix = " studs",
        CurrentValue = s.AntiContest.Height, Flag = "ab_ac_h",
        Callback = function(v) s.AntiContest.Height = v end,
    })

    BallTab:CreateSection("Ball Resizer")
    BallTab:CreateToggle({
        Name = "Ball Resizer",
        Desc = "Scales every ball part and sets its transparency to 0.5.",
        Flag = "ab_ballsize",
        CurrentValue = s.BallSize.Enabled,
        Callback = function(v)
            s.BallSize.Enabled = v
            if v then enableBallResizer() else disableBallResizer() end
        end,
    })
    BallTab:CreateSlider({
        Name = "Ball size",
        Range = { 1, 12 }, Increment = 1, Suffix = " studs",
        CurrentValue = s.BallSize.Size, Flag = "ab_ballsize_val",
        Callback = function(v)
            s.BallSize.Size = v
            if s.BallSize.Enabled then applyBallSize() end
        end,
    })

    buildHVHTab(HVHTab, s.HVH)

    do
        local hookedButtons = {}
        local pressedButtons = {}

        local function matchesShoot(inst)
            if not (inst:IsA("GuiButton") or inst:IsA("ImageButton")) then return false end
            local n = string.lower(inst.Name)
            if n == "shoot" or n:find("shoot", 1, true) then return true end
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    if string.lower(d.Text or ""):find("shoot", 1, true) then return true end
                end
            end
            return false
        end

        local function onPress(inst)
            if not s.Shooting.AutoGreen then return end
            if not s.Shooting.AutoGreenOnShootButton then return end
            pressedButtons[inst] = true
        end

        local function onRelease(inst)
            if not s.Shooting.AutoGreen then return end
            if not s.Shooting.AutoGreenOnShootButton then return end
            if not pressedButtons[inst] then return end
            pressedButtons[inst] = nil
            fireAutoGreenSafe()
        end

        local function tryHook(inst)
            if hookedButtons[inst] then return end
            if not matchesShoot(inst) then return end
            hookedButtons[inst] = true
            Track(inst.MouseButton1Down:Connect(function() onPress(inst) end))
            Track(inst.MouseButton1Up:Connect(function() onRelease(inst) end))
            Track(inst.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onPress(inst)
                end
            end))
            Track(inst.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onRelease(inst)
                end
            end))
            Track(inst.MouseLeave:Connect(function()
                if pressedButtons[inst] then onRelease(inst) end
            end))
        end

        local function scanAndHook(root)
            if not root then return end
            for _, inst in ipairs(root:GetDescendants()) do tryHook(inst) end
        end

        local function watchRoot(root)
            if not root then return end
            Track(root.DescendantAdded:Connect(function(inst)
                task.wait(0.05)
                tryHook(inst)
            end))
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then scanAndHook(pg); watchRoot(pg) end
        Track(LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                task.wait(0.5)
                scanAndHook(child); watchRoot(child)
            end
        end))

        scanAndHook(workspace); watchRoot(workspace)
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            scanAndHook(char); watchRoot(char)
        end))

        pcall(function()
            scanAndHook(CoreGui); watchRoot(CoreGui)
        end)
    end

    local eWasHeld = false

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local hvhCfg = s.HVH

        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey then
            if s.Shooting.AutoGreen then eWasHeld = true end
            if s.AntiContest.Enabled then
                local acBind = s.AntiContest.Keybind
                local acKey = (type(acBind) == "string") and Enum.KeyCode[acBind] or acBind
                if input.KeyCode == acKey then doAntiContest() end
            end
            return
        end

        local acBind = s.AntiContest.Keybind
        local acKey = (type(acBind) == "string") and Enum.KeyCode[acBind] or acBind
        if input.KeyCode == acKey and s.AntiContest.Enabled then
            doAntiContest(); return
        end

        local speedBind = hvhCfg.Speed.Keybind
        local speedKey = (type(speedBind) == "string") and Enum.KeyCode[speedBind] or speedBind
        if input.KeyCode == speedKey then
            hvhCfg.Speed.Enabled = not hvhCfg.Speed.Enabled
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey and eWasHeld then
            eWasHeld = false
            if s.Shooting.AutoGreen then fireAutoGreenSafe() end
        end
    end)

    hvhStart()

    local function cleanup()
        pcall(disableBallResizer)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end
    Track(LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then cleanup() end
    end))

-- ============================================================
-- BRANCH: BASKETBALL LEGENDS
-- ============================================================
elseif isBL then
    local Settings = {
        Shooting = {
            AutoGreen = false,
            AutoGreenKeybind = Enum.KeyCode.E,
            AutoGreenOnJump = false,
            AutoGreenOnShootButton = true,
        },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1 },
        },
        Mag = {
            Enabled = false,
            BallName = "Ball",
            Reach = 20,
            Keybind = Enum.KeyCode.L,
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {} }
    local function Track(c) if c then table.insert(Cleanup.conns, c) end return c end

    local ShootRemote = nil
    local function resolveShootRemote()
        if ShootRemote and ShootRemote.Parent then return ShootRemote end
        pcall(function()
            local Packages = ReplicatedStorage:FindFirstChild("Packages")
            local Knit = Packages and Packages:FindFirstChild("Knit")
            local Services = Knit and Knit:FindFirstChild("Services")
            local ControlService = Services and Services:FindFirstChild("ControlService")
            local RE = ControlService and ControlService:FindFirstChild("RE")
            ShootRemote = RE and RE:FindFirstChild("Shoot")
        end)
        return ShootRemote
    end

    local function fireAutoGreen()
        local remote = resolveShootRemote()
        if not remote then return false end
        return pcall(function() remote:FireServer(1) end)
    end

    local greenLock = false
    local function fireAutoGreenSafe()
        if greenLock then return end
        greenLock = true
        fireAutoGreen()
        task.delay(0.15, function() greenLock = false end)
    end

    local magConnection = nil
    local magRefreshThread = nil
    local magCache = {}

    local function rebuildMagCache()
        table.clear(magCache)
        local targetName = s.Mag.BallName
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BasePart") and inst.Name == targetName then
                if inst:FindFirstChildWhichIsA("TouchTransmitter")
                    or inst:FindFirstChild("TouchInterest") then
                    magCache[#magCache + 1] = inst
                end
            end
        end
    end

    local function magTick()
        if not s.Mag.Enabled then return end
        local character, _, touchPart = getChar()
        if not character or not touchPart then return end
        if character:FindFirstChild("Basketball") then return end
        local reach = tonumber(s.Mag.Reach) or 20
        local reachSq = reach * reach
        local origin = touchPart.Position
        for i = #magCache, 1, -1 do
            local part = magCache[i]
            if not part or not part.Parent then
                table.remove(magCache, i)
            else
                local d = origin - part.Position
                if (d.X*d.X + d.Y*d.Y + d.Z*d.Z) <= reachSq then
                    pcall(function()
                        firetouchinterest(touchPart, part, 0)
                        firetouchinterest(touchPart, part, 1)
                    end)
                    if not part.Anchored then
                        part.AssemblyLinearVelocity = (touchPart.Position - part.Position) * 30
                    end
                end
            end
        end
    end

    local function enableMag()
        if magConnection then magConnection:Disconnect(); magConnection = nil end
        if magRefreshThread then task.cancel(magRefreshThread); magRefreshThread = nil end
        rebuildMagCache()
        magRefreshThread = task.spawn(function()
            while s.Mag.Enabled do
                task.wait(0.5)
                if s.Mag.Enabled then rebuildMagCache() end
            end
        end)
        magConnection = RunService.Heartbeat:Connect(function() pcall(magTick) end)
        Track(magConnection)
    end

    local function disableMag()
        if magConnection then magConnection:Disconnect(); magConnection = nil end
        if magRefreshThread then task.cancel(magRefreshThread); magRefreshThread = nil end
        table.clear(magCache)
    end

    local Window = Airflow:CreateWindow({Name = "Fatal Labs", LoadingSubtitle = "Fatal Labs basketball suite", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "FatalLabs", FileName = "FatalLabs"}})

    local Notify = function(props) pcall(function() Window:Notify(props) end) end

    local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "HVH", Icon = "activity" })

    CombatTab:CreateSection("Auto Green")
    CombatTab:CreateToggle({
        Name = "Auto Green",
        Desc = "Fires ControlService.RE.Shoot with argument 1 (perfect shot).",
        Flag = "bl_autogreen",
        CurrentValue = s.Shooting.AutoGreen,
        Callback = function(v) s.Shooting.AutoGreen = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto Green keybind",
        Desc = "Hold then RELEASE this key to fire a green shot.",
        Flag = "bl_autogreen_key",
        CurrentValue = s.Shooting.AutoGreenKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AutoGreenKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Jump",
        Desc = "Fires the remote automatically after you jump-shot.",
        Flag = "bl_autogreen_jump",
        CurrentValue = s.Shooting.AutoGreenOnJump,
        Callback = function(v) s.Shooting.AutoGreenOnJump = v end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Shoot button",
        Desc = "Fires the remote INSTANTLY when you RELEASE the in-game Shoot button.",
        Flag = "bl_autogreen_btn",
        CurrentValue = s.Shooting.AutoGreenOnShootButton,
        Callback = function(v) s.Shooting.AutoGreenOnShootButton = v end,
    })
    CombatTab:CreateButton({
        Name = "Fire Green Now",
        Callback = function()
            if fireAutoGreen() then
                Notify({ title = "Auto Green", content = "Shot fired.", duration = 2 })
            else
                Notify({ title = "Auto Green", content = "Remote not found.", duration = 3 })
            end
        end,
    })

    BallTab:CreateSection("Mag")
    BallTab:CreateToggle({
        Name = "Mag",
        Desc = "Fast cached magnet. Auto firetouchinterest on nearby balls.",
        Flag = "bl_mag",
        CurrentValue = s.Mag.Enabled,
        Callback = function(v)
            s.Mag.Enabled = v
            if v then enableMag() else disableMag() end
        end,
    })
    BallTab:CreateKeybind({
        Name = "Mag keybind",
        Desc = "Press this key to toggle Mag on/off.",
        Flag = "bl_mag_key",
        CurrentValue = s.Mag.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Mag.Keybind = key end
        end,
    })
    BallTab:CreateInput({
        Name = "Ball name",
        Desc = "Name of the part to magnet (default: Ball).",
        Placeholder = "Ball",
        CurrentValue = s.Mag.BallName,
        Flag = "bl_mag_name",
        Callback = function(text)
            if text ~= "" then
                s.Mag.BallName = text
                if s.Mag.Enabled then rebuildMagCache() end
            end
        end,
    })
    BallTab:CreateSlider({
        Name = "Reach (studs)",
        Range = { 1, 100 }, Increment = 1,
        CurrentValue = s.Mag.Reach, Flag = "bl_mag_reach",
        Callback = function(v) s.Mag.Reach = v end,
    })

    buildHVHTab(HVHTab, s.HVH)

    local function setupAutoGreenChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        Track(hum.Jumping:Connect(function(active)
            if not active then return end
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnJump then return end
            if not char:FindFirstChild("Basketball") then return end
            fireAutoGreenSafe()
        end))
    end
    if LocalPlayer.Character then setupAutoGreenChar(LocalPlayer.Character) end
    Track(LocalPlayer.CharacterAdded:Connect(setupAutoGreenChar))

    do
        local hookedButtons = {}
        local pressedButtons = {}

        local function matchesShoot(inst)
            if not (inst:IsA("GuiButton") or inst:IsA("ImageButton")) then return false end
            local n = string.lower(inst.Name)
            if n == "shoot" or n:find("shoot", 1, true) then return true end
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    if string.lower(d.Text or ""):find("shoot", 1, true) then return true end
                end
            end
            return false
        end

        local function onPress(inst)
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnShootButton then return end
            pressedButtons[inst] = true
        end

        local function onRelease(inst)
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnShootButton then return end
            if not pressedButtons[inst] then return end
            pressedButtons[inst] = nil
            fireAutoGreenSafe()
        end

        local function tryHook(inst)
            if hookedButtons[inst] or not matchesShoot(inst) then return end
            hookedButtons[inst] = true
            Track(inst.MouseButton1Down:Connect(function() onPress(inst) end))
            Track(inst.MouseButton1Up:Connect(function() onRelease(inst) end))
            Track(inst.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onPress(inst)
                end
            end))
            Track(inst.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onRelease(inst)
                end
            end))
            Track(inst.MouseLeave:Connect(function()
                if pressedButtons[inst] then onRelease(inst) end
            end))
        end

        local function scanAndHook(root)
            if not root then return end
            for _, inst in ipairs(root:GetDescendants()) do tryHook(inst) end
        end

        local function watchRoot(root)
            if not root then return end
            Track(root.DescendantAdded:Connect(function(inst)
                task.wait(0.05)
                tryHook(inst)
            end))
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then scanAndHook(pg); watchRoot(pg) end
        Track(LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                task.wait(0.5)
                scanAndHook(child); watchRoot(child)
            end
        end))

        scanAndHook(workspace); watchRoot(workspace)
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            scanAndHook(char); watchRoot(char)
        end))

        pcall(function()
            scanAndHook(CoreGui); watchRoot(CoreGui)
        end)
    end

    local eWasHeld = false

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey then
            if s.Shooting.AutoGreen then eWasHeld = true end
            return
        end

        local magBind = s.Mag.Keybind
        local magKey = (type(magBind) == "string") and Enum.KeyCode[magBind] or magBind
        if input.KeyCode == magKey then
            s.Mag.Enabled = not s.Mag.Enabled
            if s.Mag.Enabled then enableMag() else disableMag() end
            return
        end

        local speedBind = s.HVH.Speed.Keybind
        local speedKey = (type(speedBind) == "string") and Enum.KeyCode[speedBind] or speedBind
        if input.KeyCode == speedKey then
            s.HVH.Speed.Enabled = not s.HVH.Speed.Enabled
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey and eWasHeld then
            eWasHeld = false
            if s.Shooting.AutoGreen then fireAutoGreenSafe() end
        end
    end)

    hvhStart()

    local function cleanup()
        pcall(disableMag)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end
    Track(LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then cleanup() end
    end))

-- ============================================================
-- BRANCH: HOOPZ
-- ============================================================
else
    local TweenService = game:GetService("TweenService")
    local HttpService  = game:GetService("HttpService")
    local DeviceEvent  = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("deviceEvent")

    local Settings = {
        Shooting = {
            AuralEnabled = false, AuralKeybind = Enum.KeyCode.X,
            ShotYAxis = 0, ShotDelay = 0.32, EBLHop = false,
            HumanizeAim = false, HumanizeStrength = 1.2, MissChance = 0,
            RandomizeShotDelay = false, ShotDelayMin = 0.25, ShotDelayMax = 0.38,
        },
        Defending = {
            AutoGuard = false, AutoGuardButton = false, AutoGuardNearest = false,
            AutoGuardMode = "Balanced", AutoGuardRange = 33, GuardPrediction = 0.58,
            GuardKeybind = Enum.KeyCode.K,
        },
        Ball = {
            BallMags = false, BallMagRange = 15, BallMagVisualizer = false, MagnetKeybind = "M",
            BallReach = false, BallReachRange = 10, BallReachVisualizer = false, ReachKeybind = "N",
        },
        MagV2 = { Enabled = false, BallName = "Ball", Reach = 20, Keybind = Enum.KeyCode.U },
        TPWalk = { Enabled = false, Speed = 0.01, Keybind = Enum.KeyCode.P },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1 },
        },
        Misc = { AntiModerator = false, DeviceSpoofer = false, Device = "PC", MobilePanel = true },
        Visuals = {
            ShotIndicator = false, IndicatorColor = "Blue",
            CustomName = false, CustomNameText = "",
            CustomRecord = false, CustomRecordText = "",
            CustomTitle = false, CustomTitleText = "",
            HideOwnNameplate = false,
        },
        Goal = { Enabled = false, SelectedEffect = "LightRay", CurrentEffect = "LightRay" },
        CourtSpoofer = { Enabled = false, SelectedCourt = "None", CurrentCourt = "None" },
        BallChanger = { Enabled = false, SelectedBall = "ForceField", CurrentBall = "ForceField" },
        TrailSpoofer = { Enabled = false, SelectedTrail = "None", CurrentTrail = "None" },
        BallAura = { Enabled = false, SelectedAura = "None", CurrentAura = "None" },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {}, fns = {} }
    local function Track(c) table.insert(Cleanup.conns, c); return c end
    local function OnCleanup(fn) table.insert(Cleanup.fns, fn) end

    local setAural, setGuard, setMagnet, setReach, setTPWalk, setMagV2
    local MobileRefresh = function() end

    local IndicatorColors = {
        Blue = Color3.fromRGB(60, 150, 255),
        Purple = Color3.fromRGB(190, 165, 240),
        Green = Color3.fromRGB(0, 255, 128),
        Red = Color3.fromRGB(255, 60, 60),
        Yellow = Color3.fromRGB(255, 220, 0),
    }

    local function hasball(char) return char and char:FindFirstChild("Basketball") ~= nil end

    local fieldGoals = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst.Name == "FieldGoal" and inst:IsA("BasePart") then
            table.insert(fieldGoals, inst)
        end
    end

    local goals = {}
    local goalsDirty = true

    local function validgoal(o)
        if not o:IsA("BasePart") then return false end
        local n = string.lower(o.Name)
        if n ~= "goal" and n ~= "goalhome" and n ~= "goalaway" then return false end
        local p = o.Parent
        for _ = 1, 5 do
            if not p then break end
            local pn = string.lower(p.Name)
            if string.find(pn, "hitbox", 1, true) or string.find(pn, "fieldgoal", 1, true) then return true end
            p = p.Parent
        end
        return false
    end

    local function rebuildGoals()
        table.clear(goals)
        for _, o in workspace:GetDescendants() do
            if validgoal(o) then table.insert(goals, o) end
        end
        goalsDirty = false
    end
    rebuildGoals()

    Track(workspace.DescendantAdded:Connect(function(o)
        if validgoal(o) then
            table.insert(goals, o)
        elseif o:IsA("BasePart") and string.find(string.lower(o.Name), "goal", 1, true) then
            goalsDirty = true
        end
    end))

    local courtPlayerCache = {}
    local function rebuildCourtCache()
        table.clear(courtPlayerCache)
        for _, inst in next, workspace:GetChildren() do
            if inst.Name == "Courts" then
                for _, court in next, inst:GetChildren() do
                    local cp = court:FindFirstChild("_CourtPlayers")
                    if cp then table.insert(courtPlayerCache, cp) end
                end
            end
        end
    end
    rebuildCourtCache()

    Track(workspace.DescendantAdded:Connect(function(o)
        if o.Name == "_CourtPlayers" then
            table.insert(courtPlayerCache, o)
        end
    end))

    local function nearestgoal(root)
        if goalsDirty then rebuildGoals() end
        local rootPos = root.Position
        local best, bestDist = nil, math.huge
        for i = #goals, 1, -1 do
            local goal = goals[i]
            if not goal or not goal.Parent then table.remove(goals, i); continue end
            local delta = goal.Position - rootPos
            local flat = delta.X * delta.X + delta.Z * delta.Z
            if flat < bestDist then best, bestDist = goal, flat end
        end
        if best then return best, math.sqrt(bestDist) end
        return nil, math.huge
    end

    local function teamOf(nm)
        if nm:find("^Home") then return "Home" end
        if nm:find("^Away") then return "Away" end
        return nil
    end

    local function getTeammates()
        local tms = {}
        for _, cp in next, courtPlayerCache do
            if not cp.Parent then continue end
            local myTeam = nil
            for _, v in next, cp:GetChildren() do
                if v:IsA("ObjectValue") and v.Value == LocalPlayer then
                    myTeam = teamOf(v.Name)
                    break
                end
            end
            if not myTeam then continue end
            for _, tm in next, cp:GetChildren() do
                if tm:IsA("ObjectValue") and typeof(tm.Value) == "Instance"
                    and tm.Value:IsA("Player") and tm.Value ~= LocalPlayer
                    and teamOf(tm.Name) == myTeam then
                    table.insert(tms, tm.Value)
                end
            end
            break
        end
        return tms
    end

    local teammatesCache = { list = nil }
    local lastTeammateRefresh = 0

    local function isTeammatePlayer(player)
        local now = os.clock()
        if now - lastTeammateRefresh > 0.5 or not teammatesCache.list then
            teammatesCache.list = getTeammates()
            lastTeammateRefresh = now
        end
        for _, tm in ipairs(teammatesCache.list) do
            if tm == player then return true end
        end
        return false
    end

    local function getClosestDribbler()
        local char, _, root = getChar()
        if not root then return nil end
        local closestPlayer, closestDistance = nil, math.huge
        for _, part in workspace:GetPartBoundsInRadius(root.Position, s.Defending.AutoGuardRange) do
            if part:IsA("BasePart") and part.Name == "Ball" and part.Parent:IsA("Folder") then
                local holder = part.Parent.Parent
                local holderRoot = holder and holder:FindFirstChild("HumanoidRootPart")
                if holderRoot then
                    local distance = (holderRoot.Position - root.Position).Magnitude
                    if distance < closestDistance then
                        local holderPlayer = Players:GetPlayerFromCharacter(holder)
                        if holderPlayer and not isTeammatePlayer(holderPlayer) then
                            closestDistance = distance
                            closestPlayer = holderPlayer
                        end
                    end
                end
            end
        end
        return closestPlayer
    end

    local function getClosestPlayer()
        local char, _, root = getChar()
        if not root then return nil end
        local closestPlayer, closestDistance = nil, math.huge
        local rootPos = root.Position
        local range = s.Defending.AutoGuardRange
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local c = player.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - rootPos).Magnitude
                if dist < range and dist < closestDistance and not isTeammatePlayer(player) then
                    closestDistance = dist
                    closestPlayer = player
                end
            end
        end
        return closestPlayer
    end

    local function getGuardMode()
        local lowered = tostring(s.Defending.AutoGuardMode or "Balanced"):lower()
        if lowered == "reactive" then return "legit" end
        if lowered == "aggressive" then return "blatant" end
        return "prediction"
    end

    local function getGuardPosition(target)
        if not target then return nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Basketball") then return nil end
        local targetChar = target.Character
        if not targetChar then return nil end
        local targetBall = targetChar:FindFirstChild("Basketball") and targetChar.Basketball:FindFirstChild("Ball")
        if not targetBall then return nil end
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar:FindFirstChild("Humanoid")
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not targetHrp or not targetHum or not myHrp or not myHum then return nil end
        local mode = getGuardMode()
        local ballPos = targetBall.Position
        local vel = targetHrp.AssemblyLinearVelocity
        local speed = targetHum.WalkSpeed
        local moveDir = targetHum.MoveDirection
        local myPos = myHrp.Position
        local mySpeed = myHum.WalkSpeed
        local distance = (ballPos - myPos).Magnitude
        local timeToReach = distance / (mySpeed + 10)
        local predictionScale = s.Defending.GuardPrediction or 0.58
        if mode == "legit" then
            predictionScale = predictionScale * 0.7
            timeToReach = distance / (mySpeed + 12)
        elseif mode == "blatant" then
            predictionScale = predictionScale * 1.75
            timeToReach = distance / (mySpeed + 18)
        end
        local predictedMove = moveDir * speed * predictionScale + Vector3.new(vel.X, 0, vel.Z) * 0.5
        local interceptPos = targetHrp.Position + predictedMove * timeToReach
        local offsetDir = (moveDir.Magnitude > 0 and moveDir.Unit or Vector3.new(0, 0, 1)) * ((mode == "blatant") and 4 or 2)
        return Vector3.new(interceptPos.X + offsetDir.X, ballPos.Y, interceptPos.Z + offsetDir.Z)
    end

    local function getNearestGuardPosition(target)
        if not target then return nil end
        local targetChar = target.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHrp or not targetHum or not myHrp then return nil end
        local moveDir = targetHum.MoveDirection
        local vel = Vector3.new(targetHrp.AssemblyLinearVelocity.X, 0, targetHrp.AssemblyLinearVelocity.Z)
        local dist = (targetHrp.Position - myHrp.Position).Magnitude
        local timeToReach = dist / (targetHum.WalkSpeed + 10)
        local predictionScale = (getGuardMode() == "blatant") and (s.Defending.GuardPrediction * 1.5) or s.Defending.GuardPrediction
        local predicted = targetHrp.Position + (moveDir * targetHum.WalkSpeed * predictionScale + vel * 0.5) * timeToReach
        local facing = (moveDir.Magnitude > 0) and moveDir.Unit or (targetHrp.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
        local offset = facing * ((getGuardMode() == "blatant") and 4 or 2)
        return Vector3.new(predicted.X + offset.X, targetHrp.Position.Y, predicted.Z + offset.Z)
    end

    local guardConnection = nil

    local function enableAutoGuard()
        if guardConnection then guardConnection:Disconnect(); guardConnection = nil end
        local frameSkip = 0
        guardConnection = RunService.Stepped:Connect(function()
            if not s.Defending.AutoGuard then return end
