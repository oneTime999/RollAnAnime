local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Blocks = LP:WaitForChild("Blocks")
local Net = RS.Network.Client

if not isfolder("SlowHub") then makefolder("SlowHub") end
if not isfolder("SlowHub/RollAnAnime") then makefolder("SlowHub/RollAnAnime") end

local CFG = {
    SelectedBlocks = {}, SelectedRollBlocks = {}, SelectedUpgradeAnimes = {},
    AutoBuy = false, AutoRoll = false, AutoCollect = false, AutoCollectIndex = false, AutoUpgrade = false
}

local function Save() writefile("SlowHub/RollAnAnime/config.json", HttpService:JSONEncode(CFG)) end
local function Load()
    if isfile("SlowHub/RollAnAnime/config.json") then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile("SlowHub/RollAnAnime/config.json"))
        if ok and data then for k, v in pairs(data) do CFG[k] = v end end
    end
end
Load()

local StaticBlocks = {
    "CommonBlock","UncommonBlock","RareBlock","EpicBlock","LegendaryBlock",
    "MythicBlock","GalaxyBlock","QuantumBlock","AscendantBlock","DevilBlock",
    "HeavenlyBlock","MagicBlock","BrambleBlock","TimeBenderBlock","InfinityBlock",
    "KingSunBlock","OuroborosBlock","MoltenCoreBlock","ToxicReactorBlock","KingsMantleBlock",
    "TheEndBlock","AetherialBlock","RadiantBlock","CelestialEmperorBlock","PhantomBlock",
    "AnomalyBlock","VercaBlock","VortexBlock","BloodcodeBlock","DoomBlock",
    "HellcoreBlock","VerdictBlock","PinnacleBlock"
}

local function GetInventory()
    local t = {}
    for _, n in ipairs(StaticBlocks) do
        local o = Blocks:FindFirstChild(n)
        if o and o.Value > 0 then t[#t+1] = n.." ("..o.Value.."x)" end
    end
    return t
end

local function GetMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in pairs(plots:GetChildren()) do
        local o = plot:FindFirstChild("Owner")
        if o and (tostring(o.Value) == tostring(LP.UserId) or tostring(o.Value) == LP.Name) then
            return plot
        end
    end
end

local function GetAnimeList()
    local t, plot = {}, GetMyPlot()
    if not plot then return t end
    local slots = plot:FindFirstChild("Slots")
    if not slots then return t end
    for i = 1, 24 do
        local slot = slots:FindFirstChild(tostring(i))
        if slot then
            local m = slot:FindFirstChildOfClass("Model")
            if m then
                t[#t+1] = "["..i.."] "..m.Name.." "..(m:GetAttribute("Mutation") or "None").." Lv."..(m:GetAttribute("UpgradeLevel") or 0)
            end
        end
    end
    return t
end

local function ParseBlock(s) return s:match("^(.-)%s*%(") or s end
local function ParseSlot(s) return s:match("^%[(%d+)%]") end

local Win = Rayfield:CreateWindow({
    Name = "Slow Hub | Roll An Anime", LoadingTitle = "Slow Hub Team", LoadingSubtitle = "by Slow Hub Team",
    ConfigurationSaving = {Enabled=false}, Discord = {Enabled=false,Invite="",RememberJoins=true}, KeySystem = false
})

local Main = Win:CreateTab("Main", 4483362458)
local Misc = Win:CreateTab("Misc", 4483362458)

-- Auto Buy
Main:CreateSection("Auto Buy Blocks")
Main:CreateDropdown({Name="Select Blocks to Buy",Options=StaticBlocks,CurrentOption=CFG.SelectedBlocks,MultipleOptions=true,Callback=function(v) CFG.SelectedBlocks=v Save() end})
Main:CreateToggle({Name="Auto Buy Blocks",CurrentValue=CFG.AutoBuy,Callback=function(v)
    CFG.AutoBuy=v Save()
    if not v then return end
    task.spawn(function()
        while CFG.AutoBuy do
            for _, b in ipairs(CFG.SelectedBlocks) do
                if not CFG.AutoBuy then break end
                pcall(Net.PurchaseItem.InvokeServer, Net.PurchaseItem, b)
                task.wait(0.05)
            end
            task.wait(0.1)
        end
    end)
end})

-- Auto Roll
Main:CreateSection("Auto Roll Blocks")
local RollDrop = Main:CreateDropdown({Name="Select Blocks to Roll",Options=GetInventory(),CurrentOption={},MultipleOptions=true,Callback=function(v) CFG.SelectedRollBlocks=v Save() end})
Main:CreateButton({Name="Refresh Inventory",Callback=function() RollDrop:Refresh(GetInventory()) CFG.SelectedRollBlocks={} Save() end})
local RollToggle = Main:CreateToggle({Name="Auto Roll Blocks",CurrentValue=CFG.AutoRoll,Callback=function(v)
    CFG.AutoRoll=v Save()
    if not v then return end
    task.spawn(function()
        local selected = CFG.SelectedRollBlocks
        for _, fmt in ipairs(selected) do
            if not CFG.AutoRoll then break end
            local name = ParseBlock(fmt)
            local obj = Blocks:FindFirstChild(name)
            if not obj then continue end
            while CFG.AutoRoll do
                local count = obj.Value
                if count <= 0 then break end
                pcall(function() Net.RollBlock:InvokeServer(name) end)
                task.wait(0.1)
            end
        end
        if CFG.AutoRoll then
            CFG.AutoRoll=false Save() RollToggle:Set(false)
            Rayfield:Notify({Title="Auto Roll",Content="All selected blocks depleted!",Duration=5})
        end
    end)
end})

-- Auto Upgrade
Main:CreateSection("Auto Upgrade Anime")
local UpgDrop = Main:CreateDropdown({Name="Select Animes to Upgrade",Options=GetAnimeList(),CurrentOption={},MultipleOptions=true,Callback=function(v) CFG.SelectedUpgradeAnimes=v Save() end})
Main:CreateButton({Name="Refresh Anime List",Callback=function()
    local list = GetAnimeList()
    UpgDrop:Refresh(list) CFG.SelectedUpgradeAnimes={} Save()
    Rayfield:Notify({Title="Anime List",Content=#list>0 and #list.." anime(s) found." or "No animes found in your plot!",Duration=4})
end})
Main:CreateToggle({Name="Auto Upgrade Anime",CurrentValue=CFG.AutoUpgrade,Callback=function(v)
    CFG.AutoUpgrade=v Save()
    if not v then return end
    task.spawn(function()
        while CFG.AutoUpgrade do
            if #CFG.SelectedUpgradeAnimes == 0 then task.wait(1) continue end
            for _, fmt in ipairs(CFG.SelectedUpgradeAnimes) do
                if not CFG.AutoUpgrade then break end
                local slot = ParseSlot(fmt)
                if slot then pcall(Net.UpgradeBrainrot.InvokeServer, Net.UpgradeBrainrot, slot) task.wait(0.1) end
            end
            task.wait(0.5)
        end
    end)
end})

-- Misc
Misc:CreateSection("Economy")
Misc:CreateToggle({Name="Auto Collect Cash (1-24)",CurrentValue=CFG.AutoCollect,Callback=function(v)
    CFG.AutoCollect=v Save()
    if not v then return end
    task.spawn(function()
        while CFG.AutoCollect do
            for i = 1, 24 do
                if not CFG.AutoCollect then break end
                pcall(Net.ClaimCash.FireServer, Net.ClaimCash, tostring(i))
                task.wait(0.05)
            end
            task.wait(1)
        end
    end)
end})

Misc:CreateToggle({Name="Auto Collect Index Rewards",CurrentValue=CFG.AutoCollectIndex,Callback=function(v)
    CFG.AutoCollectIndex=v Save()
    if not v then return end
    task.spawn(function()
        while CFG.AutoCollectIndex do
            pcall(Net.ClaimAllIndexRewards.FireServer, Net.ClaimAllIndexRewards)
            task.wait(1)
        end
    end)
end})
