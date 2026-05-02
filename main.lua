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
    "HellcorellBlock", "VerdictBlock", "PinnacleBlock"
}

local function GetInventoryList()
    local list = {}
    for _, name in ipairs(StaticBlocks) do
        local obj = PlayerBlocks:FindFirstChild(name)
        if obj and obj.Value > 0 then
            table.insert(list, name .. " (" .. tostring(obj.Value) .. "x)")
        end
    end
    return list
end

local function GetMyPlot()
    local plots = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("4")
    if plots then
        for i = 1, 8 do
            local plot = plots:FindFirstChild(tostring(i))
            if plot and plot:FindFirstChild("Owner") and (tostring(plot.Owner.Value) == LocalPlayer.Name or tostring(plot.Owner.Value) == tostring(LocalPlayer.UserId)) then
                return plot
            end
        end
    end
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
                table.insert(list, "[" .. tostring(i) .. "] " .. name .. " " .. mut .. " Lv. " .. tostring(lv))
            end
        end
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
                        pcall(function()
                            ReplicatedStorage.Network.Client.PurchaseItem:InvokeServer(blockName)
                        end)
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
    Callback = function()
        RollDropdown:Refresh(GetInventoryList())
    end,
})

MainTab:CreateToggle({
    Name = "Auto Roll Blocks",
    CurrentValue = Config.AutoRoll,
    Callback = function(Value)
        Config.AutoRoll = Value
        Save()
        if Config.AutoRoll then
            task.spawn(function()
                while Config.AutoRoll do
                    for _, formattedName in ipairs(Config.SelectedRollBlocks) do
                        if not Config.AutoRoll then break end
                        local realName = string.gsub(formattedName, " %(%d+x%)", "")
                        pcall(function()
                            ReplicatedStorage.Network.Client.RollBlock:InvokeServer(realName)
                        end)
                        task.wait(0.05)
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
        UpgradeDropdown:Refresh(GetAnimeList())
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
                    for _, formatted in ipairs(Config.SelectedUpgradeAnimes) do
                        if not Config.AutoUpgrade then break end
                        local slotNum = string.match(formatted, "%[(%d+)%]")
                        if slotNum then
                            pcall(function()
                                ReplicatedStorage.Network.Client.UpgradeBrainrot:InvokeServer(slotNum)
                            end)
                            task.wait(0.05)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

MiscTab:CreateSection("Economy")

MiscTab:CreateToggle({
    Name = "Auto Collect Cash (1-24)",
    CurrentValue = Config.AutoCollect,
    Callback = function(Value)
        Config.AutoCollect = Value
        Save()
        if Config.AutoCollect then
            task.spawn(function()
                while Config.AutoCollect do
                    for i = 1, 24 do
                        if not Config.AutoCollect then break end
                        pcall(function()
                            ReplicatedStorage.Network.Client.ClaimCash:FireServer(tostring(i))
                        end)
                        task.wait(0.02)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})
