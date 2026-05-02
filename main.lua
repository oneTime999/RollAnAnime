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
    AutoBuy = false,
    AutoRoll = false
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
        if obj and (obj:IsA("NumberValue") or obj:IsA("IntValue")) and obj.Value > 0 then
            table.insert(list, name .. " (" .. tostring(obj.Value) .. "x)")
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
