local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")

local FolderPath = "SlowHub"
local SubFolderPath = "SlowHub/RollAnAnime"
local ConfigPath = "SlowHub/RollAnAnime/config.json"

if not isfolder(FolderPath) then
    makefolder(FolderPath)
end

if not isfolder(SubFolderPath) then
    makefolder(SubFolderPath)
end

local Config = {
    SelectedBlocks = {"CommonBlock"},
    AutoBuy = false
}

local function Save()
    writefile(ConfigPath, HttpService:JSONEncode(Config))
end

local function Load()
    if isfile(ConfigPath) then
        local success, data = pcall(function()
            local decoded = HttpService:JSONDecode(readfile(ConfigPath))
            if decoded then Config = decoded end
        end)
    end
end

Load()

local Window = Rayfield:CreateWindow({
    Name = "Slow Hub | Roll An Anime",
    LoadingTitle = "Slow Hub Team",
    LoadingSubtitle = "by Slow Hub Team",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)

local Blocks = {
    "CommonBlock", "UncommonBlock", "RareBlock", "EpicBlock", "LegendaryBlock",
    "MythicBlock", "GalaxyBlock", "QuantumBlock", "AscendantBlock", "DevilBlock",
    "HeavenlyBlock", "MagicBlock", "BrambleBlock", "TimeBenderBlock", "InfinityBlock",
    "KingSunBlock", "OuroborosBlock", "MoltenCoreBlock", "ToxicReactorBlock", "KingsMantleBlock",
    "TheEndBlock", "AetherialBlock", "RadiantBlock", "CelestialEmperorBlock", "PhantomBlock",
    "AnomalyBlock", "VercaBlock", "VortexBlock", "BloodcodeBlock", "DoomBlock",
    "HellcoreBlock", "VerdictBlock", "PinnacleBlock"
}

MainTab:CreateDropdown({
    Name = "Select Blocks to Buy",
    Options = Blocks,
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
                            game:GetService("ReplicatedStorage").Network.Client.PurchaseItem:InvokeServer(blockName)
                        end)
                        task.wait(0.05)
                    end
                    task.wait(0.01)
                end
            end)
        end
    end,
})
