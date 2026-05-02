local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerBlocks = LocalPlayer:WaitForChild("Blocks")

local FolderPath = "SlowHub"
local SubFolderPath = "SlowHub/RollAnAnime"
local ConfigPath = "SlowHub/RollAnAnime/config.json"

if not isfolder(FolderPath) then makefolder(FolderPath) end
if not isfolder(SubFolderPath) then makefolder(SubFolderPath) end

local Config = {
    SelectedBlocks = {},
    SelectedRollBlocks = {},
    SelectedUpgradeAnimes = {},
    AutoBuy = false,
    AutoRoll = false,
    AutoCollect = false,
    AutoUpgrade = false
}

local function Save()
    writefile(ConfigPath, HttpService:JSONEncode(Config))
end

local function Load()
    if isfile(ConfigPath) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigPath))
        end)
        if success and data then 
            for i, v in pairs(data) do Config[i] = v end 
        end
    end
end

Load()

local Window = Rayfield:CreateWindow({
    Name = "Slow Hub | Roll An Anime",
    LoadingTitle = "Slow Hub Team",
    LoadingSubtitle = "by Slow Hub Team",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false, Invite = "", RememberJoins = true},
    KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

local StaticBlocks = {
    "CommonBlock", "UncommonBlock", "RareBlock", "EpicBlock", "LegendaryBlock",
    "MythicBlock", "GalaxyBlock", "QuantumBlock", "AscendantBlock", "DevilBlock",
    "HeavenlyBlock", "MagicBlock", "BrambleBlock", "TimeBenderBlock", "InfinityBlock",
    "KingSunBlock", "OuroborosBlock", "MoltenCoreBlock", "ToxicReactorBlock", "KingsMantleBlock",
    "TheEndBlock", "AetherialBlock", "RadiantBlock", "CelestialEmperorBlock", "PhantomBlock",
    "AnomalyBlock", "VercaBlock", "VortexBlock", "BloodcodeBlock", "DoomBlock",
    "HellcoreBlock", "VerdictBlock", "PinnacleBlock"
}

local function GetInventoryList()
    local list = {}
    for _, name in ipairs(StaticBlocks) do
        local obj = PlayerBlocks:FindFirstChild(name)
        if obj and obj.Value > 0 then
            table.insert(list, name .. " (" .. obj.Value .. "x)")
        end
    end
    return list
end

local function GetMyPlot()
    local container = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("4")
    if not container then warn("[DEBUG] workspace.Plots['4'] not found") return nil end
    
    for _, plot in pairs(container:GetChildren()) do
        local ownerObj = plot:FindFirstChild("Owner")
        if ownerObj and (tostring(ownerObj.Value) == tostring(LocalPlayer.UserId) or tostring(ownerObj.Value) == LocalPlayer.Name) then
            return plot
        end
    end
    warn("[DEBUG] No plot found for " .. LocalPlayer.Name)
    return nil
end

local function GetAnimeList()
    local list = {}
    local plot = GetMyPlot()
    if plot and plot:FindFirstChild("Slots") then
        for i = 1, 24 do
            local slot = plot.Slots:FindFirstChild(tostring(i))
            local model = slot and slot:FindFirstChildOfClass("Model")
            if model then
                local name = model:GetAttribute("EntityName") or "Unknown"
                local mut = model:GetAttribute("Mutation") or "None"
                local lv = model:GetAttribute("UpgradeLevel") or 0
                table.insert(list, "[" .. i .. "] " .. name .. " (" .. mut .. ") Lv." .. lv)
            end
        end
    else
        warn("[DEBUG] Plots/Slots folder missing")
    end
    return list
end

MainTab:CreateSection("Auto Buy Blocks")

MainTab:CreateDropdown({
    Name = "Select Blocks to Buy",
    Options = StaticBlocks,
    CurrentOption = Config.SelectedBlocks,
    MultipleOptions = true,
    Callback = function(Options)
        Config.SelectedBlocks = Options
        Save()
    end,
})

MainTab:CreateToggle({
    Name = "Auto Buy Blocks",
    CurrentValue = Config.AutoBuy,
    Callback = function(Value)
        Config.AutoBuy = Value
        Save()
        if Config.AutoBuy then
            task.spawn(function()
                while Config.AutoBuy do
                    for _, blockName in ipairs(Config.SelectedBlocks) do
                        if not Config.AutoBuy then break end
                        pcall(function() ReplicatedStorage.Network.Client.PurchaseItem:InvokeServer(blockName) end)
                        task.wait(0.05)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

MainTab:CreateSection("Auto Roll Blocks")

local RollDropdown = MainTab:CreateDropdown({
    Name = "Select Blocks to Roll",
    Options = GetInventoryList(),
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(Options)
        Config.SelectedRollBlocks = Options
        Save()
    end,
})

MainTab:CreateButton({
    Name = "Refresh Inventory List",
    Callback = function() RollDropdown:Refresh(GetInventoryList()) end,
})

local AutoRollToggle = MainTab:CreateToggle({
    Name = "Auto Roll Blocks",
    CurrentValue = Config.AutoRoll,
    Callback = function(Value)
        Config.AutoRoll = Value
        Save()
        if Config.AutoRoll then
            task.spawn(function()
                while Config.AutoRoll do
                    local foundBlock = false
                    for _, formattedName in ipairs(Config.SelectedRollBlocks) do
                        if not Config.AutoRoll then break end
                        local realName = string.gsub(formattedName, " %(%d+x%)", "")
                        local blockObj = PlayerBlocks:FindFirstChild(realName)
                        
                        if blockObj and blockObj.Value > 0 then
                            foundBlock = true
                            pcall(function() ReplicatedStorage.Network.Client.RollBlock:InvokeServer(realName) end)
                            task.wait(0.05)
                            break 
                        end
                    end
                    
                    if not foundBlock then
                        Config.AutoRoll = false
                        Save()
                        Rayfield:Notify({Title = "Auto Roll", Content = "Out of selected blocks! Stopping...", Duration = 5})
                        break
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

MainTab:CreateSection("Auto Upgrade Anime")

local UpgradeDropdown = MainTab:CreateDropdown({
    Name = "Select Animes to Upgrade",
    Options = GetAnimeList(),
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(Options)
        Config.SelectedUpgradeAnimes = Options
        Save()
    end,
})

MainTab:CreateButton({
    Name = "Refresh Anime List",
    Callback = function() 
        local list = GetAnimeList()
        UpgradeDropdown:Refresh(list)
        if #list == 0 then
            Rayfield:Notify({Title = "Debug", Content = "No Animes found in your plot slots!", Duration = 5})
        end
    end,
})

MainTab:CreateToggle({
    Name = "Auto Upgrade Anime",
    CurrentValue = Config.AutoUpgrade,
    Callback = function(Value)
        Config.AutoUpgrade = Value
        Save()
        if Config.AutoUpgrade then
            task.spawn(function()
                while Config.AutoUpgrade do
                    if #Config.SelectedUpgradeAnimes == 0 then
                        task.wait(1)
                    else
                        for _, formatted in ipairs(Config.SelectedUpgradeAnimes) do
                            if not Config.AutoUpgrade then break end
                            local slotNum = string.match(formatted, "%[(%d+)%]")
                            if slotNum then
                                pcall(function() 
                                    ReplicatedStorage.Network.Client.UpgradeBrainrot:InvokeServer(tostring(slotNum)) 
                                end)
                                task.wait(0.1)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})

MiscTab:CreateSection("Economy")

MiscTab:CreateToggle({
    Name = "Auto Collect Cash",
    CurrentValue = Config.AutoCollect,
    Callback = function(Value)
        Config.AutoCollect = Value
        Save()
        if Config.AutoCollect then
            task.spawn(function()
                while Config.AutoCollect do
                    for i = 1, 24 do
                        if not Config.AutoCollect then break end
                        pcall(function() ReplicatedStorage.Network.Client.ClaimCash:FireServer(tostring(i)) end)
                        task.wait(0.05)
                    end
                    task.wait(1)
                end
            end)
        end
    end,
})
