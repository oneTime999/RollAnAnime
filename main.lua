local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser") -- Corrigido: VirtualUser é um serviço próprio

local LP = Players.LocalPlayer
local Blocks = LP:WaitForChild("Blocks")
local Net = RS.Network.Client

if not isfolder("SlowHub") then makefolder("SlowHub") end
if not isfolder("SlowHub/RollAnAnime") then makefolder("SlowHub/RollAnAnime") end

local CFG = {
    SelectedBlocks = {}, SelectedRollBlocks = {}, SelectedUpgradeAnimes = {},
    AutoBuy = false, AutoRoll = false, AutoCollect = false, AutoCollectIndex = false, AutoUpgrade = false, AntiAfk = false
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

-- Sistema de Anti-AFK Otimizado (Event-Driven)
LP.Idled:Connect(function()
    if CFG.AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        -- Se preferir garantir, pode usar o método anterior corrigido:
        -- VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        -- task.wait(0.1)
        -- VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- Loop starters
local function StartAutoBuy()
    task.spawn(function()
        while CFG.AutoBuy do
            for _, b in ipairs(CFG.SelectedBlocks) do
                if not CFG.AutoBuy then break end
                pcall(function() Net.PurchaseItem:InvokeServer(b) end)
                task.wait(0.05)
            end
            task.wait(0.1)
        end
    end)
end

local function StartAutoCollect()
    task.spawn(function()
        while CFG.AutoCollect do
            for i = 1, 24 do
                if not CFG.AutoCollect then break end
                pcall(function() Net.ClaimCash:FireServer(tostring(i)) end)
                task.wait(0.05)
            end
            task.wait(1)
        end
    end)
end

local function StartAutoCollectIndex()
    task.spawn(function()
        while CFG.AutoCollectIndex do
            pcall(function() Net.ClaimAllIndexRewards:FireServer() end)
            task.wait(1)
        end
    end)
end

local function StartAutoUpgrade()
    task.spawn(function()
        while CFG.AutoUpgrade do
            if #CFG.SelectedUpgradeAnimes == 0 then task.wait(1) continue end
            for _, fmt in ipairs(CFG.SelectedUpgradeAnimes) do
                if not CFG.AutoUpgrade then break end
                local slot = ParseSlot(fmt)
                if slot then
                    pcall(function() Net.UpgradeBrainrot:InvokeServer(slot) end)
                    task.wait(0.1)
                end
            end
            task.wait(0.5)
        end
    end)
end

-- UI
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
    if v then StartAutoBuy() end
end})

-- Auto Roll
Main:CreateSection("Auto Roll Blocks")
local RollDrop = Main:CreateDropdown({Name="Select Blocks to Roll",Options=GetInventory(),CurrentOption={},MultipleOptions=true,Callback=function(v) CFG.SelectedRollBlocks=v Save() end})
Main:CreateButton({Name="Refresh Inventory",Callback=function() RollDrop:Refresh(GetInventory()) CFG.SelectedRollBlocks={} Save() end})

local RollSession = 0
local RollToggle
RollToggle = Main:CreateToggle({Name="Auto Roll Blocks",CurrentValue=CFG.AutoRoll,Callback=function(v)
    CFG.AutoRoll=v Save()
    if not v then return end
    RollSession = RollSession + 1
    local sid = RollSession
    task.spawn(function()
        for _, fmt in ipairs(CFG.SelectedRollBlocks) do
            if not CFG.AutoRoll or sid ~= RollSession then break end
            local name = ParseBlock(fmt)
            local obj = Blocks:FindFirstChild(name)
            if not obj then continue end
            while CFG.AutoRoll and sid == RollSession do
                if obj.Value <= 0 then break end
                pcall(function() Net.RollBlock:InvokeServer(name) end)
                task.wait(0.2)
            end
        end
        if CFG.AutoRoll and sid == RollSession then
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
    if v then StartAutoUpgrade() end
end})

-- Misc
Misc:CreateSection("Economy")
Misc:CreateToggle({Name="Auto Collect Cash (1-24)",CurrentValue=CFG.AutoCollect,Callback=function(v)
    CFG.AutoCollect=v Save()
    if v then StartAutoCollect() end
end})

Misc:CreateToggle({Name="Auto Collect Index Rewards",CurrentValue=CFG.AutoCollectIndex,Callback=function(v)
    CFG.AutoCollectIndex=v Save()
    if v then StartAutoCollectIndex() end
end})

Misc:CreateSection("Player")
Misc:CreateToggle({Name="Anti-AFK",CurrentValue=CFG.AntiAfk,Callback=function(v)
    -- Não precisamos mais iniciar um loop. O evento LP.Idled faz tudo automaticamente de acordo com o valor no CFG!
    CFG.AntiAfk=v Save()
end})

-- Boot: reinicia loops que estavam ativos no save
if CFG.AutoBuy then StartAutoBuy() end
if CFG.AutoCollect then StartAutoCollect() end
if CFG.AutoCollectIndex then StartAutoCollectIndex() end
if CFG.AutoUpgrade then StartAutoUpgrade() end
