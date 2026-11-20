if game.PlaceId == 2788229376 then
    MainEvent = game:GetService('ReplicatedStorage').MainEvent
end

--//bypass
assert(getrawmetatable)
grm = getrawmetatable(game)
setreadonly(grm, false)
old = grm.__namecall
grm.__namecall = newcclosure(function(self, ...)
    local args = {...}
    if tostring(args[1]) == "TeleportDetect" then
        return
    elseif tostring(args[1]) == "CHECKER_1" then
        return
    elseif tostring(args[1]) == "CHECKER" then
        return
    elseif tostring(args[1]) == "GUI_CHECK" then
        return
    elseif tostring(args[1]) == "OneMoreTime" then
        return
    elseif tostring(args[1]) == "checkingSPEED" then
        return
    elseif tostring(args[1]) == "BANREMOTE" then
        return
    elseif tostring(args[1]) == "PERMAIDBAN" then
        return
    elseif tostring(args[1]) == "KICKREMOTE" then
        return
    elseif tostring(args[1]) == "BR_KICKPC" then
        return
    elseif tostring(args[1]) == "BR_KICKMOBILE" then
        return
    end
    return old(self, ...)
end)
--//bypass

local Players = game:GetService("Players")
local rrr = game:GetService("RunService")
local Client = Players.LocalPlayer

Grabbed = function (Plr)
    if Plr and Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") and Plr.Character:FindFirstChild("Humanoid") and Plr.Character:FindFirstChild("Head") and Plr.Character:FindFirstChild("GRABBING_CONSTRAINT") then
        return true
    end
    return false
end

rrr.RenderStepped:Connect(function()
    MainEvent:FireServer("Stomp")
end)    

task.spawn(function()
    while task.wait() do
for PlayerNumber, Player in pairs(Players:GetPlayers()) do
    if Player.Character and Player ~= Client then
        local BodyEffects = Player.Character:WaitForChild("BodyEffects")
        if BodyEffects["K.O"].Value == true and not Grabbed(Player) then
            local lastpos = Client.Character:WaitForChild("HumanoidRootPart").Position
            task.wait(1)
            Client.Character:MoveTo(Player.Character.UpperTorso.Position)
            task.wait(1)
            Client.Character:MoveTo(lastpos)
        end    

    end    
end    
end
end)
