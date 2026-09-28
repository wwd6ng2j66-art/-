local gen2 = (loadstring(game:HttpGet("https://sirius.menu/gen2")))()
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local rEvents = ReplicatedStorage:WaitForChild("rEvents", 10)
local equipPetEvent = rEvents and rEvents:WaitForChild("equipPetEvent", 5)
local rebirthRemote = rEvents and rEvents:WaitForChild("rebirthRemote", 5)
local machineInteractRemote = rEvents and rEvents:WaitForChild("machineInteractRemote", 5)
local guiDamageEvent = rEvents and rEvents:WaitForChild("guiDamageEvent", 5)

local escanorHubWindow = gen2:CreateWindow({
    Name = "Escanor Hub",
    LoadingTitle = "Escanor Hub",
    LoadingSubtitle = "Muscle Legends",
    Theme = "cobalt",
    ConfigurationSaving = { Enabled = false },
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ShowSettings = false,
})

-- ===================== 伤害显示 UI =====================
local damageTrackerUI = Instance.new("ScreenGui")
damageTrackerUI.Name = "DamageTrackerUI"
damageTrackerUI.ResetOnSpawn = false
damageTrackerUI.Parent = (pcall(function() return CoreGui end)) and CoreGui or playerGui

local damageFrame = Instance.new("Frame")
damageFrame.Size = UDim2.new(0, 220, 0, 60)
damageFrame.Position = UDim2.new(0.49, 0, 0.33, 0)
damageFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
damageFrame.BackgroundTransparency = 0.15
damageFrame.Parent = damageTrackerUI
damageFrame.Visible = false

local corner = Instance.new("UICorner", damageFrame)
corner.CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", damageFrame)
stroke.Color = Color3.fromRGB(255, 60, 60)
stroke.Thickness = 2

local titleLabel = Instance.new("TextLabel", damageFrame)
titleLabel.Size = UDim2.new(1, 0, 0.35, 0)
titleLabel.Position = UDim2.new(0, 0, 0.05, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "DAMAGE DEALT"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.GothamBold

local damageLabel = Instance.new("TextLabel", damageFrame)
damageLabel.Size = UDim2.new(1, 0, 0.55, 0)
damageLabel.Position = UDim2.new(0, 0, 0.4, 0)
damageLabel.BackgroundTransparency = 1
damageLabel.Text = "-1"
damageLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
damageLabel.TextSize = 22
damageLabel.Font = Enum.Font.GothamBlack

local damageHideToken = 0

local function showDamage(amount)
    damageLabel.Text = tostring(amount)
    damageFrame.Visible = true
    damageHideToken += 1
    local token = damageHideToken
    task.delay(1.5, function()
        if token == damageHideToken then
            damageFrame.Visible = false
        end
    end)
end

if guiDamageEvent then
    guiDamageEvent.OnClientEvent:Connect(function(amount)
        if amount ~= nil then
            showDamage(amount)
        end
    end)
end

-- ===================== 通用工具函数 =====================
local function setStat(statObject, value)
    if not statObject then return end
    pcall(function()
        if statObject.Set then
            statObject:Set(value)
        elseif statObject.SetValue then
            statObject:SetValue(value)
        end
    end)
end

local autoPunchActive = false
local fastStrSmooth = false
local fastStrFast = false
local fastRebirth = false
local autoNormalRebirth = false

-- ===================== 宠物相关 =====================
local function unequipAllPets()
    if not equipPetEvent then return end
    local pets = localPlayer:FindFirstChild("petsFolder") or localPlayer:FindFirstChild("Pets")
    if not pets then return end

    for _, folder in pairs(pets:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
end

local function equipPets(petNames)
    if not equipPetEvent then return end
    unequipAllPets()

    local pets = localPlayer:FindFirstChild("petsFolder") or localPlayer:FindFirstChild("Pets")
    if not pets then return end

    for _, targetName in ipairs(petNames) do
        for _, folder in pairs(pets:GetChildren()) do
            if folder:IsA("Folder") then
                for _, pet in pairs(folder:GetChildren()) do
                    if pet.Name == targetName then
                        equipPetEvent:FireServer("equipPet", pet)
                        task.wait(0.02)
                    end
                end
            end
        end
    end
end

-- ===================== 数值读取 =====================
local function getStatValue(statName)
    local leaderstats = localPlayer:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild(statName) then
        return leaderstats[statName].Value
    end

    local durability = localPlayer:FindFirstChild("durability") or localPlayer:FindFirstChild("Durability")
    if durability and durability.Name == statName then
        return durability.Value
    end

    return 0
end

-- ===================== 网络延迟保护 =====================
local clockStart = 0

local function getBatchSize(baseSize)
    local dataPing = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
    if dataPing and dataPing:GetValue() >= 300 then
        clockStart = 0
        return 10
    end

    if clockStart == 0 then
        clockStart = os.clock()
    end

    if os.clock() - clockStart >= 2 then
        return baseSize
    end

    return 10
end

-- ===================== 主界面 =====================
escanorHubWindow:CreateSection({ name = "General" })
local tab = escanorHubWindow:CreateTab({ name = "Main" })
local tab2 = escanorHubWindow:CreateTab({ name = "Auto Strength" })
local tab3 = escanorHubWindow:CreateTab({ name = "Auto Rebirth" })

tab:CreateSection({ name = "UI Controls & Themes" })

tab:CreateButton({
    Name = "Toggle Hide UI",
    Callback = function()
        escanorHubWindow:ToggleHide()
    end,
})

tab:CreateDropdown({
    Name = "Select Theme",
    Options = { "default", "cobalt", "ember", "amethyst", "frost", "rose" },
    CurrentOption = { "cobalt" },
    MultipleOptions = false,
    Flag = "ThemeDropdown",
    Callback = function(value)
        local theme = type(value) == "table" and value[1] or value
        pcall(function()
            escanorHubWindow:ChangeTheme(theme)
        end)
    end,
})

tab:CreateSection({ name = "UI Options" })

tab:CreateToggle({
    Name = "Show Damage",
    CurrentValue = true,
    Flag = "ShowDamageToggle",
    Callback = function(value)
        damageTrackerUI.Enabled = value
    end,
})

tab:CreateSection({ name = "Pet Equipper Pack" })

tab:CreateButton({
    Name = "Equip Rep Pack",
    Callback = function()
        equipPets({ "Swift Samurai", "Rare Boss Pet", "Common Boss Pack" })
    end,
})

tab:CreateButton({
    Name = "Equip Health Pack",
    Callback = function()
        equipPets({ "Mighty Monster" })
    end,
})

tab:CreateButton({
    Name = "Equip Damage Pack",
    Callback = function()
        equipPets({ "Wild Wizard" })
    end,
})

tab:CreateButton({
    Name = "Equip Rebirth Pack",
    Callback = function()
        equipPets({ "Tribal Overlord" })
    end,
})

tab:CreateSection({ name = "Machine Controller" })

tab:CreateButton({
    Name = "Leave Machine",
    Callback = function()
        if machineInteractRemote then
            pcall(function()
                machineInteractRemote:InvokeServer("leaveMachine")
            end)
        end
    end,
})

tab:CreateSection({ name = "Manual Tools" })

tab:CreateToggle({
    Name = "Fast Punch",
    CurrentValue = false,
    Flag = "FastPunchToggle",
    Callback = function(value)
        autoPunchActive = value

        if value then
            task.spawn(function()
                while autoPunchActive do
                    local backpack = localPlayer:FindFirstChild("Backpack")
                    local punch = backpack and backpack:FindFirstChild("Punch")
                    if punch then
                        punch.Parent = localPlayer.Character
                        local attackTime = punch:FindFirstChild("attackTime")
                        if attackTime then
                            attackTime.Value = 0
                        end
                    end
                    task.wait()
                end
            end)

            task.spawn(function()
                while autoPunchActive do
                    local character = localPlayer.Character
                    local punch = character and character:FindFirstChild("Punch")
                    if punch then
                        punch:Activate()
                    end
                    task.wait()
                end
            end)
        else
            local character = localPlayer.Character
            local punch = character and character:FindFirstChild("Punch")
            local backpack = localPlayer:FindFirstChild("Backpack")
            if punch and backpack then
                punch.Parent = backpack
            end
        end
    end,
})

-- ===================== 自动力量 =====================
tab2:CreateSection({ name = "Strength Farming" })

tab2:CreateToggle({
    Name = "Fast Strength (Smooth)",
    CurrentValue = false,
    Flag = "FastStrSmoothToggle",
    Callback = function(value)
        fastStrSmooth = value

        if value then
            task.spawn(function()
                while fastStrSmooth do
                    local muscleEvent = localPlayer:FindFirstChild("muscleEvent")
                    if muscleEvent then
                        local batch = getBatchSize(20)
                        for _ = 1, batch do
                            if not fastStrSmooth then break end
                            muscleEvent:FireServer("rep")
                        end
                    end
                    task.wait()
                end
            end)
        end
    end,
})

tab2:CreateToggle({
    Name = "Fast Strength (Fast)",
    CurrentValue = false,
    Flag = "FastStrFastToggle",
    Callback = function(value)
        fastStrFast = value

        if value then
            task.spawn(function()
                while fastStrFast do
                    local muscleEvent = localPlayer:FindFirstChild("muscleEvent")
                    if muscleEvent then
                        for _ = 1, 1200 do
                            if not fastStrFast then break end
                            muscleEvent:FireServer("rep")
                        end
                    end
                    task.wait()
                end
            end)
        end
    end,
})

tab2:CreateSection({ name = "Strength Routine & Calculator" })
tab2:CreateStat({ name = "Routine Time (Sec)", value = 0, suffix = "s" })
tab2:CreateStat({ name = "Strength / Hour", value = 0, prefix = "+" })
tab2:CreateStat({ name = "Strength / Day", value = 0, prefix = "+" })
tab2:CreateStat({ name = "Durability / Hour", value = 0, prefix = "+" })
tab2:CreateStat({ name = "Durability / Day", value = 0, prefix = "+" })

-- ===================== 自动转生 =====================
tab3:CreateSection({ name = "Equipped Pet Boost Multipliers" })

local repSpeedStat = tab3:CreateStat({
    name = "Rep Speed Boost",
    value = 0,
    prefix = "+",
    suffix = "%",
})

tab3:CreateStat({ name = "Rebirth Boost", value = 1, suffix = "x" })

tab3:CreateSection({ name = "Live Stats (0 Delay)" })

local strengthStat = tab3:CreateStat({ name = "Strength Value", value = 0 })
local durabilityStat = tab3:CreateStat({ name = "Durability Value", value = 0 })
local rebirthsStat = tab3:CreateStat({ name = "Rebirths Value", value = 0 })

tab3:CreateSection({ name = "Auto Rebirth Routine" })
tab3:CreateStat({ name = "Rebirth Routine Time (Sec)", value = 0, suffix = "s" })
tab3:CreateStat({ name = "Rebirths / Hour", value = 0, prefix = "+" })
tab3:CreateStat({ name = "Rebirths / Day", value = 0, prefix = "+" })

tab3:CreateSection({ name = "Auto Rebirth Controls" })

local function getRebirthRequirement()
    local leaderstats = localPlayer:FindFirstChild("leaderstats")
    local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
    local rebirthCount = rebirths and rebirths.Value or 0

    local requirement = 10000 + 5000 * rebirthCount

    local ultimates = localPlayer:FindFirstChild("ultimatesFolder")
    local golden = ultimates and ultimates:FindFirstChild("Golden Rebirth")
    if golden then
        requirement = math.floor(requirement * (1 - golden.Value * 0.1))
    end

    return requirement
end

tab3:CreateToggle({
    Name = "Auto Rebirth (Normal)",
    CurrentValue = false,
    Flag = "AutoNormalRebirthToggle",
    Callback = function(value)
        autoNormalRebirth = value

        if value then
            task.spawn(function()
                while autoNormalRebirth do
                    local leaderstats = localPlayer:FindFirstChild("leaderstats")
                    if not leaderstats then break end

                    local strength = leaderstats:FindFirstChild("Strength")
                    if not strength then break end

                    local requirement = getRebirthRequirement()

                    while autoNormalRebirth and strength.Value < requirement do
                        local muscleEvent = localPlayer:FindFirstChild("muscleEvent")
                        if muscleEvent then
                            local batch = getBatchSize(50)
                            for _ = 1, batch do
                                if not autoNormalRebirth or strength.Value >= requirement then
                                    break
                                end
                                muscleEvent:FireServer("rep")
                            end
                        end
                        task.wait()
                    end

                    if not autoNormalRebirth then break end

                    local rebirths = leaderstats:FindFirstChild("Rebirths")
                    local oldRebirths = rebirths and rebirths.Value or 0

                    repeat
                        if rebirthRemote then
                            rebirthRemote:InvokeServer("rebirthRequest")
                        end
                        task.wait(0.02)
                    until not autoNormalRebirth or (rebirths and rebirths.Value > oldRebirths)

                    task.wait()
                end
            end)
        end
    end,
})

tab3:CreateToggle({
    Name = "Fast Rebirth",
    CurrentValue = false,
    Flag = "FastRebirthToggle",
    Callback = function(value)
        fastRebirth = value

        if value then
            task.spawn(function()
                while fastRebirth do
                    local leaderstats = localPlayer:FindFirstChild("leaderstats")
                    if not leaderstats then break end

                    local strength = leaderstats:FindFirstChild("Strength")
                    if not strength then break end

                    local requirement = getRebirthRequirement()

                    equipPets({ "Swift Samurai", "Rare Boss Pet", "Common Boss Pet" })

                    while fastRebirth and strength.Value < requirement do
                        local muscleEvent = localPlayer:FindFirstChild("muscleEvent")
                        if muscleEvent then
                            local batch = getBatchSize(50)
                            for _ = 1, batch do
                                if not fastRebirth or strength.Value >= requirement then
                                    break
                                end
                                muscleEvent:FireServer("rep")
                            end
                        end
                        task.wait()
                    end

                    if not fastRebirth then break end

                    equipPets({ "Tribal Overlord" })
                    task.wait(0.05)

                    local rebirths = leaderstats:FindFirstChild("Rebirths")
                    local oldRebirths = rebirths and rebirths.Value or 0

                    repeat
                        if rebirthRemote then
                            rebirthRemote:InvokeServer("rebirthRequest")
                        end
                        task.wait(0.02)
                    until not fastRebirth or (rebirths and rebirths.Value > oldRebirths)

                    task.wait()
                end
            end)
        end
    end,
})

-- ===================== 实时统计循环 =====================
task.spawn(function()
    while true do
        local repCount = 0
        local rareBossCount = 0
        local samuraiCount = 0
        local commonBossCount = 0

        local character = localPlayer.Character or Workspace:FindFirstChild(localPlayer.Name)

        if character then
            for _, obj in pairs(character:GetChildren()) do
                local lower = obj.Name:lower()
                if lower:find("samurai") then
                    samuraiCount += 1
                elseif lower:find("rare boss") then
                    rareBossCount += 1
                elseif lower:find("common boss") then
                    commonBossCount += 1
                elseif lower:find("tribal") or lower:find("overlord") or lower:find("rebirth") then
                    repCount += 1
                end
            end
        end

        if samuraiCount + rareBossCount + commonBossCount + repCount == 0 then
            local pets = localPlayer:FindFirstChild("petsFolder") or localPlayer:FindFirstChild("Pets")
            if pets then
                for _, folder in pairs(pets:GetChildren()) do
                    if folder:IsA("Folder") then
                        for _, pet in pairs(folder:GetChildren()) do
                            local equipped = pet:FindFirstChild("equipped") or pet:FindFirstChild("Equipped")
                            local isEquipped = equipped and (equipped.Value == true or equipped.Value == 1)

                            if isEquipped or pet:FindFirstChild("PetSelection") then
                                local lower = pet.Name:lower()
                                if lower:find("samurai") then
                                    samuraiCount += 1
                                elseif lower:find("rare boss") then
                                    rareBossCount += 1
                                elseif lower:find("common boss") then
                                    commonBossCount += 1
                                elseif lower:find("tribal") or lower:find("rebirth") then
                                    repCount += 1
                                end
                            end
                        end
                    end
                end
            end
        end

        setStat(repSpeedStat, samuraiCount * 15 + rareBossCount * 10 + commonBossCount * 5)
        task.wait(1)
    end
end)

task.spawn(function()
    task.wait(1)
    while true do
        setStat(strengthStat, getStatValue("Strength"))
        setStat(durabilityStat, getStatValue("Durability"))
        setStat(rebirthsStat, getStatValue("Rebirths"))
        task.wait(0.2)
    end
end)

escanorHubWindow:Navigate("Main")
return