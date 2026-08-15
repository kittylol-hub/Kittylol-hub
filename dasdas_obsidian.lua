local G = getgenv()
G.InterfaceName = "Kittylol"
G.SecureMode = false

-- Install executor hooks only once. Re-installing hookfunction layers on every
-- execution stacks wrappers and can cause severe frame drops when the script
-- is reloaded while the game is already running.
G.AstraHookRuntime = G.AstraHookRuntime or {}
local AstraHooks = G.AstraHookRuntime

pcall(function()
    if not AstraHooks.Installed then
        local lp = cloneref(game:GetService("Players")).LocalPlayer
        local oldKick = lp and lp.Kick

        if lp and oldKick and hookfunction and newcclosure then
            local mtHook
            mtHook = hookfunction(getrenv().setmetatable, newcclosure(function(t, mt)
                if mt and type(mt) == "table" and rawget(mt, "__mode") then
                    local mode = rawget(mt, "__mode")
                    if mode == "kv" or mode == "v" or mode == "k" then
                        local trace = debug.traceback()
                        if trace:find("MiscellaneousController")
                            or trace:find("CameraSecurity")
                            or trace:find("AnalyticsPipelineController") then
                            return mtHook({1,2,3}, {})
                        end
                    end
                end
                return mtHook(t, mt)
            end))

            hookfunction(oldKick, newcclosure(function(self, ...)
                if self == lp then return end
                return oldKick(self, ...)
            end))

            AstraHooks.Installed = true
        end
    end
end)

G.SolunaState = G.SolunaState or {}
G.SolunaRuntime = G.SolunaRuntime or {}
G.SolunaSkinRuntime = G.SolunaSkinRuntime or {}
local Runtime = G.SolunaRuntime


pcall(function()
    if Runtime.RenderConnection then Runtime.RenderConnection:Disconnect() end
    if Runtime.HeartbeatConnection then Runtime.HeartbeatConnection:Disconnect() end
    if Runtime.CleanupConnection then Runtime.CleanupConnection:Disconnect() end
    if Runtime.WalkSpeedConnection then Runtime.WalkSpeedConnection:Disconnect() end
    if Runtime.TargetInfoBlurConnection then Runtime.TargetInfoBlurConnection:Disconnect() end
    if Runtime.ExternalSilentAimConnection then Runtime.ExternalSilentAimConnection:Disconnect() end
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
    if FlyConnection then FlyConnection:Disconnect() end
end)

local function GetService(name)
    local success, service = pcall(function()
        return game:GetService(name)
    end)
    if success and service then
        return cloneref and cloneref(service) or service
    end
    return nil
end

local Services = {
    Players = GetService("Players"),
    HttpService = GetService("HttpService"),
    MarketplaceService = GetService("MarketplaceService"),
    RunService = GetService("RunService"),
    UserInputService = GetService("UserInputService"),
    ContentProvider = GetService("ContentProvider"),
    ReplicatedStorage = GetService("ReplicatedStorage"),
    Debris = GetService("Debris"),
    Lighting = GetService("Lighting"),
    SoundService = GetService("SoundService"),
    TweenService = GetService("TweenService"),
    TextService = GetService("TextService"),
    Camera = workspace and workspace.CurrentCamera or nil,
    CoreGui = (gethui and gethui()) or GetService("CoreGui")
}

local Config = {
    GameId = 17625359962,
    InviteCode = "tEmMW68zgW",
    rpcFile = "RPCShown.txt",
}

pcall(function()
    Config.LocalPlayer = Services.Players.LocalPlayer
end)

if not Config.LocalPlayer then
    warn("LocalPlayer not found")
    return
end

pcall(function()
    Config.GameInfo = Services.MarketplaceService:GetProductInfo(17625359962)
end)

Config.GameName = Config.GameInfo and Config.GameInfo.Name or "Rivals"
Config.PlayerName = Config.LocalPlayer.DisplayName
local ChamsTargetContainer = (gethui and gethui()) or Services.CoreGui

local ExecutorName = tostring(identifyexecutor and identifyexecutor() or "")
local ExecutorNameLower = string.lower(ExecutorName)

-- Forward-declared: several features defined above the UI reference these
-- (GetSilentAimTarget reads Options.fov_slider, ApplySilentAimEnabled calls
-- Notify), so they must resolve to the same locals the UI later assigns.
local Notify, NotifyUnsupportedFeature, Options

--==========================================================================
--  ASTRA HUB · BRAND
--  Shared palette + a procedurally drawn "A" monogram, so the logo needs no
--  uploaded asset and stays crisp at any size.
--==========================================================================

-- ======================================================================
-- Obsidian UI
-- Replaces the old Astra/dasdas UI completely.
-- ======================================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "Kittylol",
    Footer = Config.GameName,
    Icon = 121663636062758,
    NotifySide = "Right",
    ShowCustomCursor = true,
    AutoShow = true,
    Resizable = true,
})

Notify = function(data)
    Library:Notify({
        Title = data.Title or "Kittylol",
        Description = data.Content or "",
        Time = data.Duration or 3,
    })
end

NotifyUnsupportedFeature = function(featureName)
    Notify({ Title = featureName, Content = "Your executor doesn't support this feature", Duration = 3 })
end

-- Small compatibility layer for the feature code below. This is only an
-- adapter over Obsidian Groupboxes; no old Astra UI is retained.
local function AdaptGroupbox(groupbox)
    function groupbox:AddSection(title)
        return self
    end

    function groupbox:AddColorpicker(index, data)
        data = data or {}
        return self:AddColorPicker(index, data)
    end

    function groupbox:AddKeybind(index, data)
        data = data or {}
        local label = self:AddLabel(data.Title or data.Text or index)
        local defaultKey = data.Default
        if defaultKey == "MouseRight" then defaultKey = "MB2" end
        if defaultKey == "MouseLeft" then defaultKey = "MB1" end
        return label:AddKeyPicker(index, {
            Default = defaultKey,
            Mode = data.Mode or "Toggle",
            Text = data.Title or data.Text or index,
            NoUI = data.NoUI,
            SyncToggleState = data.SyncToggleState,
            Callback = data.Callback,
            ChangedCallback = data.ChangedCallback,
        })
    end

    function groupbox:AddToggle(index, data)
        data = data or {}
        if data.Title and not data.Text then data.Text = data.Title end
        return self.__AddToggle(self, index, data)
    end

    function groupbox:AddSlider(index, data)
        data = data or {}
        if data.Title and not data.Text then data.Text = data.Title end
        return self.__AddSlider(self, index, data)
    end

    function groupbox:AddDropdown(index, data)
        data = data or {}
        if data.Title and not data.Text then data.Text = data.Title end
        return self.__AddDropdown(self, index, data)
    end

    function groupbox:AddInput(index, data)
        data = data or {}
        if data.Title and not data.Text then data.Text = data.Title end
        return self.__AddInput(self, index, data)
    end

    function groupbox:AddButton(data)
        if type(data) == "table" then
            local d = table.clone(data)
            if d.Title and not d.Text then d.Text = d.Title end
            if d.Callback and not d.Func then d.Func = d.Callback end
            return self.__AddButton(self, d)
        end
        return self.__AddButton(self, data)
    end

    return groupbox
end

local Tabs = {}
local function AddTab(name, icon)
    local tab = Window:AddTab(name, icon)
    local original = tab.AddLeftGroupbox
    local originalRight = tab.AddRightGroupbox

    function tab:AddSection(title)
        return AdaptGroupbox(self:AddLeftGroupbox(title))
    end

    function tab:AddLeftGroupbox(title, iconName)
        local box = original(self, title, iconName)
        box.__AddToggle = box.AddToggle
        box.__AddSlider = box.AddSlider
        box.__AddDropdown = box.AddDropdown
        box.__AddInput = box.AddInput
        box.__AddButton = box.AddButton
        return AdaptGroupbox(box)
    end

    function tab:AddRightGroupbox(title, iconName)
        local box = originalRight(self, title, iconName)
        box.__AddToggle = box.AddToggle
        box.__AddSlider = box.AddSlider
        box.__AddDropdown = box.AddDropdown
        box.__AddInput = box.AddInput
        box.__AddButton = box.AddButton
        return AdaptGroupbox(box)
    end

    return tab
end

Tabs.Aimbot = AddTab("Aimbot", "crosshair")
Tabs.Utility = AddTab("Utility", "shield")
Tabs.Weapons = AddTab("Weapons", "package")
Tabs.Player = AddTab("Player", "user")
Tabs.ESP = AddTab("ESP", "eye")
Tabs.Misc = AddTab("Miscellaneous", "box")
Tabs.Skins = AddTab("Skins", "brush")
Tabs.Settings = AddTab("Settings", "settings")
Tabs.About = AddTab("About", "info")

-- Obsidian managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "ui_accent" })
ThemeManager:SetFolder("Kittylol")
SaveManager:SetFolder("Kittylol/Rivals")

-- Brand is kept only as a data value used by the existing feature section.
local Brand = { Accent = Color3.fromRGB(255, 105, 180) }


local AimbotSection = Tabs.Aimbot:AddSection("Aimbot")

AimbotSection:AddToggle("aimbot_enabled", { Title = "Enabled", Default = false })

AimbotSection:AddDropdown("aim_mode", {
    Title = "Aim Mode",
    Values = {"Mouse"},
    Default = "Mouse",
    Multi = false,
})

AimbotSection:AddSlider("max_distance", {
    Title = "Max Distance",
    Default = 1000,
    Min = 0,
    Max = 5000,
    Rounding = 0,
})

AimbotSection:AddSlider("aimbot_smoothing", {
    Title = "Smoothing",
    Default = 5,
    Min = 1,
    Max = 50,
    Rounding = 1,
})

AimbotSection:AddDropdown("aim_target", {
    Title = "Target Part",
    Values = TargetBodyParts,
    Default = "Head",
    Multi = false,
    Callback = function(v) AimbotSettings.TargetPart = v end
})

AimbotSection:AddKeybind("aimbot_bind", {
    Title = "Aim Key",
    Mode = "Hold",
    Default = "MouseRight",
    Callback = function(Value)
        State.Aiming = Value
        if not Value then State.LockedTarget = nil end
    end
})

local SilentAimSection = Tabs.Aimbot:AddSection("Silent Aim")

local SilentAimToggleSync = false
local SilentAimToggle = SilentAimSection:AddToggle("silent_aim_enabled", { Title = "Enabled", Default = false })

SilentAimToggle:OnChanged(function()
    local v = Options.silent_aim_enabled.Value
    if Runtime.FeatureControlSync == "silent_aim_enabled" then
        ApplySilentAimEnabled(v)
        return
    end
    if SilentAimToggleSync then
        ApplySilentAimEnabled(v)
        return
    end
    if not v then
        ApplySilentAimEnabled(false)
        return
    end
    SilentAimToggleSync = true
    SilentAimToggle:SetValue(false)
    SilentAimToggleSync = false

    task.spawn(function()
        local confirmed = false
        Window:Dialog({
            Title = "Silent Aim",
            Content = "This feature is detectable. Are you sure you want to enable Silent Aim?",
            Buttons = {
                { Title = "Yes", Callback = function()
                    confirmed = true
                    SilentAimToggleSync = true
                    SilentAimToggle:SetValue(true)
                    SilentAimToggleSync = false
                end },
                { Title = "No", Callback = function()
                    confirmed = true
                    ApplySilentAimEnabled(false)
                end }
            }
        })
        task.wait(10)
        if not confirmed then
            SilentAimToggleSync = true
            SilentAimToggle:SetValue(false)
            SilentAimToggleSync = false
        end
    end)
end)

SilentAimSection:AddSlider("silent_aim_hitchance", {
    Title = "Hitchance",
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(v) State.SilentAimHitchance = v end
})

SilentAimSection:AddDropdown("silent_aim_target", {
    Title = "Target Part",
    Values = TargetBodyParts,
    Default = "Head",
    Multi = false,
    Callback = function(v) AimbotSettings.TargetPart = v end
})

local wallBang = __p6q7r8.__s9t0u1

SilentAimSection:AddToggle("wall_bang_enabled", { 
    Title = "Wall Bang", 
    Default = false,
    Callback = function(v) 
        State.WallBangEnabled = v
        if v then
            if State.SilentAimEnabled then
                wallBang:Enable()
                Notify({ Title = "Wall Bang", Content = "Wall Bang activated! (Desync method)", Duration = 3 })
            else
                Notify({ Title = "Wall Bang", Content = "Enable Wall bang then Silent Aim!", Duration = 3 })
            end
        else
            wallBang:Disable()
        end
    end
})

SilentAimToggle:OnChanged(function(v)
    if v and State.WallBangEnabled then
        wallBang:Enable()
    elseif not v then
        wallBang:Disable()
    end
end)

local AimbotChecksSection = Tabs.Aimbot:AddSection("Checks")

AimbotChecksSection:AddToggle("team_check", { Title = "Team Check", Default = true })
AimbotChecksSection:AddToggle("wall_check", { Title = "Wall Check", Default = true, Callback = function(v) State.WallCheckEnabled = v end })
AimbotChecksSection:AddToggle("show_fov", { Title = "Show FOV", Default = false })
AimbotChecksSection:AddSlider("fov_slider", { Title = "Field of View", Default = 90, Min = 0, Max = 1000, Rounding = 0 })

local FOVFilledValue = false
local FOVFilledTransparency = 0.8
AimbotChecksSection:AddToggle("fov_filled", { Title = "FOV Filled", Default = false, Callback = function(v) FOVFilledValue = v end })
AimbotChecksSection:AddSlider("fov_fill_opacity", { Title = "FOV Fill Opacity", Default = 0.8, Min = 0, Max = 1, Rounding = 2, Callback = function(v) FOVFilledTransparency = v end })

local TriggerbotSection = Tabs.Aimbot:AddSection("Triggerbot")
local TriggerbotEnabled = false
local TriggerbotDelay = 0.05
local TriggerbotActive = false
local lastTriggerTime = 0

TriggerbotSection:AddToggle("triggerbot_enabled", { Title = "Enabled", Default = false, Callback = function(v) TriggerbotEnabled = v end })
TriggerbotSection:AddKeybind("triggerbot_bind", { Title = "Hold Key", Mode = "Hold", Default = "MouseRight", Callback = function(Value) TriggerbotActive = Value end })
TriggerbotSection:AddSlider("triggerbot_delay", { Title = "Delay", Default = 0.05, Min = 0, Max = 0.5, Rounding = 2, Callback = function(v) TriggerbotDelay = v end })

local OrbitSection = Tabs.Utility:AddSection("Orbit")

local OrbitEnabled = false
local OrbitSpeed = 1
local OrbitDistance = 5
local OrbitHeight = 3
local OrbitRunning = false
local OrbitAngle = 0
local OrbitTargetMode = "Closest Enemy"
local OrbitAutoShoot = false
local OrbitTargetPlayer = nil
local OrbitDuelScanResult = nil
local OrbitDuelScanTime = 0

local function GetDuelOpponentFromGarbageCollector()
    if not getgc then return nil end
    local now = tick()
    if now - OrbitDuelScanTime < 0.2 then return OrbitDuelScanResult end
    OrbitDuelScanTime = now
    OrbitDuelScanResult = nil
    pcall(function()
        for _, object in ipairs(getgc(true)) do
            if type(object) == "table" then
                local duelers = rawget(object, "Duelers")
                if type(duelers) == "table" then
                    local hasLocalPlayer = false
                    local opponentPlayer = nil
                    for _, dueler in pairs(duelers) do
                        local player = type(dueler) == "table" and rawget(dueler, "Player") or nil
                        if player == Config.LocalPlayer then
                            hasLocalPlayer = true
                        elseif typeof(player) == "Instance" and player:IsA("Player") then
                            opponentPlayer = player
                        end
                    end
                    if hasLocalPlayer and opponentPlayer then
                        OrbitDuelScanResult = opponentPlayer
                        return opponentPlayer
                    end
                end
            end
        end
    end)
    return OrbitDuelScanResult
end

local function GetDuelOpponent()
    if State.RequireBlocked then return GetDuelOpponentFromGarbageCollector() end
    local DuelController = GetDuelController()
    if not DuelController then return GetDuelOpponentFromGarbageCollector() end
    local duel = DuelController:GetDuel(Config.LocalPlayer)
    if not duel then return GetDuelOpponentFromGarbageCollector() end
    for _, dueler in pairs(duel.Duelers) do
        if dueler.Player and dueler.Player ~= Config.LocalPlayer then return dueler.Player end
    end
    return GetDuelOpponentFromGarbageCollector()
end

local function GetOrbitTarget()
    if OrbitTargetMode == "Duel Opponent" then return GetDuelOpponent()
    elseif OrbitTargetMode == "Aimbot Target" then return State.LockedTarget end
    local closestPlayer = nil
    local shortestDistance = math.huge
    local players = GetValidPlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= Config.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("TeammateLabel") then continue end
                local localRoot = Config.LocalPlayer.Character and Config.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if localRoot then
                    local dist = (rootPart.Position - localRoot.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

OrbitSection:AddToggle("orbit_enabled", { Title = "Enabled", Default = false, Callback = function(v)
    OrbitEnabled = v
    if v and not OrbitRunning then
        OrbitRunning = true
        OrbitAngle = 0
        task.spawn(function()
            while OrbitEnabled and OrbitRunning do
                local delta = Services.RunService.Heartbeat:Wait()
                local targetPlayer = GetOrbitTarget()
                if targetPlayer and targetPlayer.Character then
                    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local targetHead = targetPlayer.Character:FindFirstChild("Head")
                    local localChar = Config.LocalPlayer.Character
                    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                    local isInvincible = false
                    pcall(function()
                        local fc = GetFighterController()
                        if fc then
                            local targetFighter = fc:GetFighter(targetPlayer)
                            if targetFighter and targetFighter.Entity then
                                isInvincible = targetFighter.Entity:Get("IsInvincible") == true
                            end
                        end
                    end)
                    if targetRoot and localRoot and not isInvincible then
                        local targetPos = targetRoot.Position
                        local center = targetPos + Vector3.new(0, OrbitHeight, 0)
                        OrbitAngle = OrbitAngle + delta * OrbitSpeed * 2 * math.pi
                        local offset = Vector3.new(math.cos(OrbitAngle) * OrbitDistance, 0, math.sin(OrbitAngle) * OrbitDistance)
                        local desiredPos = center + offset
                        localRoot.CFrame = CFrame.new(desiredPos, center)
                        if OrbitAutoShoot and targetHead then
                            if not (State.AntiKatanaEnabled and IsEnemyDeflecting(targetPlayer)) then
                                pcall(function()
                                    local fc = GetFighterController()
                                    if fc and fc.LocalFighter then
                                        local equippedItem = fc.LocalFighter.EquippedItem
                                        if equippedItem then
                                            local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
                                            if not remotes then return end
                                            local replication = remotes:FindFirstChild("Replication")
                                            if not replication then return end
                                            local fighterRemote = replication:FindFirstChild("Fighter")
                                            if not fighterRemote then return end
                                            local UseItemRemote = fighterRemote:FindFirstChild("UseItem")
                                            if not UseItemRemote then return end
                                            
                                            local objectId = equippedItem:Get("ObjectID")
                                            if not objectId then return end
                                            
                                            local shootOrigin = Services.Camera.CFrame.Position
                                            local targetPos = targetHead.Position
                                            local direction = (targetPos - shootOrigin).Unit
                                            
                                            local function MakeCFrameData(cf)
                                                local rx, ry, rz = cf:ToOrientation()
                                                return {
                                                    [utf8.char(0)] = cf.X,
                                                    [utf8.char(1)] = cf.Y,
                                                    [utf8.char(2)] = cf.Z,
                                                    [utf8.char(3)] = rx,
                                                    [utf8.char(4)] = ry,
                                                    [utf8.char(5)] = rz
                                                }
                                            end
                                            
                                            local originCF = CFrame.new(shootOrigin, shootOrigin + direction)
                                            local destCF = CFrame.new(targetPos, targetPos + direction)
                                            local hitPart = targetPlayer.Character:FindFirstChild("UpperTorso") or targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetHead
                                            
                                            local cameraData = {
                                                [utf8.char(0)] = MakeCFrameData(originCF),
                                                [utf8.char(1)] = MakeCFrameData(destCF),
                                                [utf8.char(2)] = hitPart
                                            }
                                            
                                            local actionData = { [utf8.char(1)] = cameraData }
                                            UseItemRemote:FireServer(objectId, "\026", actionData, nil)
                                            
                                            if equippedItem.ViewModel and equippedItem.ViewModel.MuzzleFlash then
                                                equippedItem.ViewModel:MuzzleFlash()
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            OrbitRunning = false
        end)
    elseif not v then
        OrbitRunning = false
    end
end })

OrbitSection:AddDropdown("orbit_target_mode", { Title = "Target Mode", Values = {"Closest Enemy", "Aimbot Target", "Duel Opponent"}, Default = "Closest Enemy", Multi = false, Callback = function(v) OrbitTargetMode = v end })
OrbitSection:AddToggle("orbit_autoshoot", { Title = "Auto Shoot", Default = false, Callback = function(v) OrbitAutoShoot = v end })
OrbitSection:AddSlider("orbit_speed", { Title = "Speed", Default = 1, Min = 0.1, Max = 5, Rounding = 1, Callback = function(v) OrbitSpeed = v end })
OrbitSection:AddSlider("orbit_distance", { Title = "Distance", Default = 5, Min = 2, Max = 20, Rounding = 0, Callback = function(v) OrbitDistance = v end })
OrbitSection:AddSlider("orbit_height", { Title = "Height", Default = 3, Min = 0, Max = 10, Rounding = 1, Callback = function(v) OrbitHeight = v end })

local AntiKatanaSection = Tabs.Utility:AddSection("Anti-Katana")
local AntiKatanaToggle = AntiKatanaSection:AddToggle("anti_katana", { Title = "Enabled", Default = false })

AntiKatanaToggle:OnChanged(function()
    local v = Options.anti_katana.Value
    if Runtime.FeatureControlSync == "anti_katana" then State.AntiKatanaEnabled = v return end
    if v and State.RequireBlocked then
        State.AntiKatanaEnabled = false
        NotifyUnsupportedFeature("Anti-Katana")
        Runtime.FeatureControlSync = "anti_katana"
        AntiKatanaToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    State.AntiKatanaEnabled = v
    task.defer(function()
        if v then
            SetupAntiKatanaHook()
            pcall(function()
                local mc = GetMechanicsController()
                if mc and not State.OriginalEquippedItemInput then
                    State.OriginalEquippedItemInput = mc.EquippedItemInput
                    mc.EquippedItemInput = function(self, inputName, ...)
                        if State.AntiKatanaEnabled then
                            if inputName == "StartShooting" or inputName == "FinishShooting" then
                                if IsAnyVisibleEnemyDeflecting() then return end
                            end
                        end
                        return State.OriginalEquippedItemInput(self, inputName, ...)
                    end
                end
            end)
            Notify({ Title = "Anti-Katana Enabled", Content = "Shots blocked when enemies deflect", Duration = 3 })
        else
            pcall(function()
                local mc = GetMechanicsController()
                if mc and State.OriginalEquippedItemInput then
                    mc.EquippedItemInput = State.OriginalEquippedItemInput
                    State.OriginalEquippedItemInput = nil
                end
            end)
            Notify({ Title = "Anti-Katana Disabled", Content = "Normal shooting restored", Duration = 3 })
        end
    end)
end)

local WeaponBehaviorSection = Tabs.Weapons:AddSection("Weapon Behavior")
local GunModsSection = Tabs.Weapons:AddSection("Gun Modifications")

G.SolunaState.BulletColorEnabled = false
G.SolunaState.BulletColor = Color3.fromRGB(0, 120, 255)
G.SolunaState.BulletTransparency = 0
G.SolunaState.BulletSize = 1
G.SolunaState.BulletHooked = false
G.SolunaState.WeaponModsHooked = false
G.SolunaState.RapidFireEnabled = false
G.SolunaState.RapidFireSpeed = 0.01
G.SolunaState.NoRecoilEnabled = false
G.SolunaState.RecoilReduction = 100
G.SolunaState.NoSpreadEnabled = false
G.SolunaState.InstantADSEnabled = false

local function SetupWeaponModsHook()
    if State.RequireBlocked or G.SolunaState.WeaponModsHooked then return end
    G.SolunaState.WeaponModsHooked = true
    
    pcall(function()
        local GunModule = GetGunModule()
        local GameplayUtility = GetGameplayUtility()
        
        if GunModule then
            if not G.SolunaState.OriginalGunStartShooting and GunModule.StartShooting then
                G.SolunaState.OriginalGunStartShooting = GunModule.StartShooting
                GunModule.StartShooting = function(self, p26, p27)
                    local oldShootCooldown = nil
                    local oldBurstCooldown = nil
                    if G.SolunaState.RapidFireEnabled then
                        oldShootCooldown = self.Info.ShootCooldown
                        oldBurstCooldown = self.Info.ShootBurstCooldown
                        self.Info.ShootCooldown = G.SolunaState.RapidFireSpeed
                        self.Info.ShootBurstCooldown = G.SolunaState.RapidFireSpeed
                    end
                    local result = { G.SolunaState.OriginalGunStartShooting(self, p26, p27) }
                    if G.SolunaState.RapidFireEnabled then
                        self.Info.ShootCooldown = oldShootCooldown
                        self.Info.ShootBurstCooldown = oldBurstCooldown
                    end
                    return table.unpack(result)
                end
            end
            if not G.SolunaState.OriginalGunRecoil and GunModule._Recoil then
                G.SolunaState.OriginalGunRecoil = GunModule._Recoil
                GunModule._Recoil = function(self, multiplier)
                    if G.SolunaState.NoRecoilEnabled then
                        local recoilMultiplier = multiplier * (1 - G.SolunaState.RecoilReduction / 100)
                        if recoilMultiplier <= 0.001 then return end
                        return G.SolunaState.OriginalGunRecoil(self, recoilMultiplier)
                    end
                    return G.SolunaState.OriginalGunRecoil(self, multiplier)
                end
            end
            if not G.SolunaState.OriginalGunStartAiming and GunModule.StartAiming then
                G.SolunaState.OriginalGunStartAiming = GunModule.StartAiming
                GunModule.StartAiming = function(self, p71)
                    if G.SolunaState.InstantADSEnabled then
                        self:SetReplicate("IsAiming", true)
                        if self.StopSprinting then self.StopSprinting:Fire() end
                        self.ViewModel:SetAiming(true)
                        self:SetReplicate("FOVOffset", self.Info.AimFOVOffset)
                        if self.ViewModel.CurrentAimValue then self.ViewModel.CurrentAimValue = 1 end
                        return true, "StartAiming"
                    end
                    return G.SolunaState.OriginalGunStartAiming(self, p71)
                end
            end
            if not G.SolunaState.OriginalGunGetAimSpeed and GunModule.GetAimSpeed then
                G.SolunaState.OriginalGunGetAimSpeed = GunModule.GetAimSpeed
                GunModule.GetAimSpeed = function(self)
                    if G.SolunaState.InstantADSEnabled then return 999 end
                    return G.SolunaState.OriginalGunGetAimSpeed(self)
                end
            end
        end
        if GameplayUtility and not G.SolunaState.OriginalGameplaySpread and GameplayUtility.GetSpread then
            G.SolunaState.OriginalGameplaySpread = GameplayUtility.GetSpread
            GameplayUtility.GetSpread = function(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
                if G.SolunaState.NoSpreadEnabled then return CFrame.new() end
                return G.SolunaState.OriginalGameplaySpread(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
            end
        end
    end)
end

local function ApplyRequireBoundGunToggle(toggleId, syncKey, featureName, valueSetter, enabledCallback)
    return function(...)
        if not Options[toggleId] then return end
        local v = Options[toggleId].Value
        if Runtime.FeatureControlSync == syncKey then 
            if valueSetter then valueSetter(v) end 
            return 
        end
        if v and State.RequireBlocked then
            if valueSetter then valueSetter(false) end
            if NotifyUnsupportedFeature then NotifyUnsupportedFeature(featureName) end
            Runtime.FeatureControlSync = syncKey
            Options[toggleId]:SetValue(false)
            Runtime.FeatureControlSync = nil
            return
        end
        if valueSetter then valueSetter(v) end
        if v and SetupWeaponModsHook then SetupWeaponModsHook() end
        if enabledCallback then enabledCallback(v) end
    end
end

local BulletColorToggle = GunModsSection:AddToggle("bullet_color_enabled", { Title = "Custom Bullet Color", Default = false })
BulletColorToggle:OnChanged(function()
    local v = Options.bullet_color_enabled.Value
    if Runtime.FeatureControlSync == "bullet_color_enabled" then G.SolunaState.BulletColorEnabled = v return end
    if v and State.RequireBlocked then
        G.SolunaState.BulletColorEnabled = false
        NotifyUnsupportedFeature("Bullet Mods")
        Runtime.FeatureControlSync = "bullet_color_enabled"
        BulletColorToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    G.SolunaState.BulletColorEnabled = v
    if v then
        pcall(function()
            local TracerEffect = GetTracerEffect()
            if TracerEffect then
                G.SolunaState.HookedTracerEffect = TracerEffect
                if not G.SolunaState.OriginalTracerPlay then G.SolunaState.OriginalTracerPlay = TracerEffect.Play end
                TracerEffect.Play = function(self, tracerData, tracerSettings, tracerContext)
                    if G.SolunaState.BulletColorEnabled then
                        tracerSettings = tracerSettings or {}
                        local customColor = ColorSequence.new(G.SolunaState.BulletColor)
                        tracerSettings.Color = customColor
                        tracerSettings.Transparency = NumberSequence.new(G.SolunaState.BulletTransparency)
                        if tracerSettings.Size then
                            local originalSize = tracerSettings.Size.Keypoints
                            if #originalSize > 0 then
                                tracerSettings.Size = NumberSequence.new(G.SolunaState.BulletSize, originalSize[#originalSize].Value * G.SolunaState.BulletSize)
                            end
                        end
                    end
                    return G.SolunaState.OriginalTracerPlay(self, tracerData, tracerSettings, tracerContext)
                end
            end
        end)
    end
end)

GunModsSection:AddColorpicker("bullet_color_picker", { Title = "Bullet Color", Default = Color3.fromRGB(0, 120, 255), Callback = function(color) G.SolunaState.BulletColor = color end })
GunModsSection:AddSlider("bullet_transparency", { Title = "Bullet Transparency", Default = 0, Min = 0, Max = 1, Rounding = 1, Callback = function(v) G.SolunaState.BulletTransparency = v end })
GunModsSection:AddSlider("bullet_size", { Title = "Bullet Size", Default = 1, Min = 0.1, Max = 5, Rounding = 1, Callback = function(v) G.SolunaState.BulletSize = v end })

local RapidFireToggle = WeaponBehaviorSection:AddToggle("rapid_fire_enabled", { Title = "Rapid Fire", Default = false })
RapidFireToggle:OnChanged(ApplyRequireBoundGunToggle("rapid_fire_enabled", "rapid_fire_enabled", "Weapon Mods", function(v) G.SolunaState.RapidFireEnabled = v end))

WeaponBehaviorSection:AddSlider("rapid_fire_speed", { Title = "Rapid Fire Cooldown", Default = 0.01, Min = 0.001, Max = 0.5, Rounding = 3, Callback = function(v) G.SolunaState.RapidFireSpeed = v end })

local NoRecoilToggle = WeaponBehaviorSection:AddToggle("no_recoil_enabled", { Title = "No Recoil", Default = false })
NoRecoilToggle:OnChanged(ApplyRequireBoundGunToggle("no_recoil_enabled", "no_recoil_enabled", "Weapon Mods", function(v) G.SolunaState.NoRecoilEnabled = v end))

WeaponBehaviorSection:AddSlider("recoil_reduction", { Title = "Recoil Reduction", Default = 100, Min = 0, Max = 100, Rounding = 0, Callback = function(v) G.SolunaState.RecoilReduction = v end })

local NoSpreadToggle = WeaponBehaviorSection:AddToggle("no_spread_enabled", { Title = "No Spread", Default = false })
NoSpreadToggle:OnChanged(ApplyRequireBoundGunToggle("no_spread_enabled", "no_spread_enabled", "Weapon Mods", function(v) G.SolunaState.NoSpreadEnabled = v end))

local InstantADSToggle = WeaponBehaviorSection:AddToggle("instant_ads_enabled", { Title = "Instant ADS", Default = false })
InstantADSToggle:OnChanged(ApplyRequireBoundGunToggle("instant_ads_enabled", "instant_ads_enabled", "Weapon Mods", function(v) G.SolunaState.InstantADSEnabled = v end))

local HitSoundsSection = Tabs.Weapons:AddSection("Hit Sounds")
G.SolunaState.CustomHitSoundsEnabled = false
G.SolunaState.CustomHeadshotSoundId = "rbxassetid://16537449730"
G.SolunaState.CustomBodyshotSoundId = "rbxassetid://13110130082"

local HitSoundPresets = {
    ["Default"] = { headshot = "rbxassetid://16537449730", bodyshot = "rbxassetid://13110130082" },
    ["Minecraft"] = { headshot = "rbxassetid://4018616850", bodyshot = "rbxassetid://4018616850" },
    ["Meow"] = { headshot = "rbxassetid://7148585764", bodyshot = "rbxassetid://7148585764" },
}

local CustomHitSoundsToggle = HitSoundsSection:AddToggle("custom_hitsounds", { Title = "Enabled", Default = false })
CustomHitSoundsToggle:OnChanged(function()
    local v = Options.custom_hitsounds.Value
    if Runtime.FeatureControlSync == "custom_hitsounds" then G.SolunaState.CustomHitSoundsEnabled = v return end
    if v and State.RequireBlocked then
        G.SolunaState.CustomHitSoundsEnabled = false
        NotifyUnsupportedFeature("Custom Hit Sounds")
        Runtime.FeatureControlSync = "custom_hitsounds"
        CustomHitSoundsToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    G.SolunaState.CustomHitSoundsEnabled = v
    if v then
        pcall(function()
            local ClientViewModel = GetClientViewModelModule()
            if ClientViewModel and not G.SolunaState.OriginalPlayHitmarkerSound then
                G.SolunaState.OriginalPlayHitmarkerSound = ClientViewModel.PlayHitmarkerSound
                ClientViewModel.PlayHitmarkerSound = function(self, isHeadshot, hitCount)
                    if G.SolunaState.CustomHitSoundsEnabled then
                        local soundId = isHeadshot and G.SolunaState.CustomHeadshotSoundId or G.SolunaState.CustomBodyshotSoundId
                        local sound = Instance.new("Sound")
                        sound.SoundId = soundId
                        sound.Volume = isHeadshot and 3 / (hitCount or 1) or 1.5 / (hitCount or 1)
                        sound.PlaybackSpeed = 1 + 0.2 * math.random()
                        sound.Parent = Services.SoundService
                        sound:Play()
                        Services.Debris:AddItem(sound, 2)
                    else
                        return G.SolunaState.OriginalPlayHitmarkerSound(self, isHeadshot, hitCount)
                    end
                end
            end
        end)
        Notify({ Title = "Custom Hit Sounds", Content = "Hit sounds have been customized", Duration = 3 })
    end
end)

HitSoundsSection:AddDropdown("hitsound_preset", { Title = "Sound Preset", Values = {"Default", "Minecraft", "Meow"}, Default = "Default", Multi = false, Callback = function(v)
    local preset = HitSoundPresets[v] or HitSoundPresets["Default"]
    G.SolunaState.CustomHeadshotSoundId = preset.headshot
    G.SolunaState.CustomBodyshotSoundId = preset.bodyshot
end })

local FlySection = Tabs.Player:AddSection("Fly")
local MovementSection = Tabs.Player:AddSection("Movement")
local CameraSection = Tabs.Player:AddSection("Camera")

local function SetupRequireSlideModifierHook()
    if Runtime.RequireSlideHooked then return end
    local mechanicsController = GetMechanicsController()
    if not mechanicsController then return end
    Runtime.RequireSlideHooked = true
end

local function SetupMovementHooks()
    SetupRequireSlideModifierHook()
end

local function DestroyWalkSpeedModifier()
    if Runtime.WalkSpeedBodyVelocity then
        pcall(function() Runtime.WalkSpeedBodyVelocity:Destroy() end)
        Runtime.WalkSpeedBodyVelocity = nil
    end
end

local function UpdateWalkSpeedModifier()
    if not State.WalkSpeedEnabled then
        DestroyWalkSpeedModifier()
        return
    end
    local character = Config.LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then
        DestroyWalkSpeedModifier()
        return
    end
    if humanoid.MoveDirection.Magnitude <= 0 then
        if Runtime.WalkSpeedBodyVelocity then
            Runtime.WalkSpeedBodyVelocity.Velocity = Vector3.zero
        end
        return
    end
    if not Runtime.WalkSpeedBodyVelocity then
        Runtime.WalkSpeedBodyVelocity = Instance.new("BodyVelocity")
        Runtime.WalkSpeedBodyVelocity.Name = "AstraWalkSpeedModifier"
        Runtime.WalkSpeedBodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
        Runtime.WalkSpeedBodyVelocity.P = 1000
        Runtime.WalkSpeedBodyVelocity.Parent = humanoidRootPart
    elseif Runtime.WalkSpeedBodyVelocity.Parent ~= humanoidRootPart then
        Runtime.WalkSpeedBodyVelocity.Parent = humanoidRootPart
    end
    Runtime.WalkSpeedBodyVelocity.Velocity = humanoid.MoveDirection.Unit * State.WalkSpeedValue
end

local function SetupWalkSpeedHook()
    if Runtime.WalkSpeedConnection then return end
    Runtime.WalkSpeedConnection = Services.RunService.Heartbeat:Connect(function()
        UpdateWalkSpeedModifier()
    end)
end

local InfiniteJumpToggle = MovementSection:AddToggle("infinite_jump", { Title = "Infinite Jump", Default = false })
InfiniteJumpToggle:OnChanged(function()
    local v = Options.infinite_jump.Value
    if Runtime.FeatureControlSync == "infinite_jump" then State.InfiniteJump = v return end
    State.InfiniteJump = v
end)

local jumpGuard = false
local function PerformInfiniteJump()
    local character = Config.LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not humanoid then return end
    jumpGuard = true
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    humanoid.Jump = true
    task.defer(function() jumpGuard = false end)
end

local InfiniteJumpConnection = Services.UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump and not jumpGuard then PerformInfiniteJump() end
end)

local SlideModifierToggle = MovementSection:AddToggle("slide_modifier", { Title = "Slide Modifier", Default = false })
SlideModifierToggle:OnChanged(function()
    local v = Options.slide_modifier.Value
    if Runtime.FeatureControlSync == "slide_modifier" then State.SlideEnabled = v return end
    if v and State.RequireBlocked then
        State.SlideEnabled = false
        NotifyUnsupportedFeature("Slide Modifier")
        Runtime.FeatureControlSync = "slide_modifier"
        SlideModifierToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    State.SlideEnabled = v
    if v then SetupMovementHooks() end
end)

local WalkSpeedToggle = MovementSection:AddToggle("walkspeed_enabled", { Title = "Walkspeed", Default = false })
WalkSpeedToggle:OnChanged(function()
    local v = Options.walkspeed_enabled.Value
    if Runtime.FeatureControlSync == "walkspeed_enabled" then State.WalkSpeedEnabled = v return end
    State.WalkSpeedEnabled = v
    if v then SetupWalkSpeedHook() else DestroyWalkSpeedModifier() end
end)

MovementSection:AddSlider("walkspeed_value", { Title = "Walkspeed Value", Default = 50, Min = 1, Max = 200, Rounding = 0, Callback = function(v) State.WalkSpeedValue = v end })
MovementSection:AddSlider("slide_speed", { Title = "Slide Speed Multiplier", Default = 1, Min = 1, Max = 10, Rounding = 1, Callback = function(v) State.SlideSpeed = v end })
MovementSection:AddSlider("slide_duration", { Title = "Slide Duration Multiplier", Default = 1, Min = 1, Max = 10, Rounding = 1, Callback = function(v) State.SlideDuration = v end })

local FlyEnabled = false
local FlySpeed = 50
local FlyConnection = nil
local BodyGyro = nil
local BodyVelocity = nil

local function StopFly()
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
    if BodyVelocity then BodyVelocity:Destroy(); BodyVelocity = nil end
end

local function StartFly()
    StopFly()
    local character = Config.LocalPlayer.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end
    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    BodyGyro.P = 9e4
    BodyGyro.Parent = humanoidRootPart
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.Parent = humanoidRootPart
    FlyConnection = Services.RunService.RenderStepped:Connect(function()
        if not FlyEnabled then return end
        local moveDirection = Vector3.new(0, 0, 0)
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Services.Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Services.Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Services.Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Services.Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        if moveDirection.Magnitude > 0 then moveDirection = moveDirection.Unit end
        if BodyVelocity and BodyVelocity.Parent then BodyVelocity.Velocity = moveDirection * FlySpeed end
        if BodyGyro and BodyGyro.Parent then BodyGyro.CFrame = Services.Camera.CFrame end
    end)
end

FlySection:AddToggle("fly_enabled", { Title = "Enabled", Default = false, Callback = function(v)
    FlyEnabled = v
    if v then
        StartFly()
        Notify({ Title = "Fly Enabled", Content = "Use WASD/Space/Ctrl to move", Duration = 3 })
    else
        StopFly()
    end
end })

FlySection:AddKeybind("fly_bind", { Title = "Fly Key", Mode = "Toggle", Default = "T", Callback = function(Value)
    if Options.fly_enabled then Options.fly_enabled:SetValue(Value) end
end })

FlySection:AddSlider("fly_speed", { Title = "Speed", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) FlySpeed = v end })

local ThirdPersonEnabled = false
local OriginalHasThirdPersonAccess = nil

local function EnableThirdPerson(enabled)
    if State.RequireBlocked then return end
    local cc = GetCameraController()
    if not cc then return end
    if enabled then
        if not OriginalHasThirdPersonAccess and cc.HasThirdPersonAccess then
            OriginalHasThirdPersonAccess = cc.HasThirdPersonAccess
            cc.HasThirdPersonAccess = function(self, ...)
                if ThirdPersonEnabled then return true end
                return OriginalHasThirdPersonAccess(self, ...)
            end
        end
        cc._third_person_override = true
        if cc.CameraState and cc.CameraState.VerifyPOV then pcall(function() cc.CameraState:VerifyPOV() end) end
    else
        cc._third_person_override = nil
        if cc.CameraState and cc.CameraState.VerifyPOV then pcall(function() cc.CameraState:VerifyPOV() end) end
    end
end

local ThirdPersonToggle = CameraSection:AddToggle("third_person", { Title = "Third Person", Default = false })
ThirdPersonToggle:OnChanged(function()
    local v = Options.third_person.Value
    if Runtime.FeatureControlSync == "third_person" then ThirdPersonEnabled = v return end
    if v and State.RequireBlocked then
        ThirdPersonEnabled = false
        NotifyUnsupportedFeature("Third Person")
        Runtime.FeatureControlSync = "third_person"
        ThirdPersonToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    ThirdPersonEnabled = v
    EnableThirdPerson(v)
    if v then Notify({ Title = "Third Person Enabled", Content = "Press B to change your camera perspective", Duration = 4 }) end
end)

local ChamsSection = Tabs.ESP:AddSection("Chams")
ChamsSection:AddToggle("chams_enabled", { Title = "Enabled", Default = false, Callback = function(v) 
    ChamsSettings.Enabled = v 
    State.ChamsEnabled = v
    local players = Services.Players:GetPlayers()
    for i = 1, #players do
        local p = players[i]
        if p ~= Config.LocalPlayer then
            local tag = "hx_" .. p.UserId
            local obj = ChamsTargetContainer:FindFirstChild(tag)
            if obj then
                obj.Enabled = v
            end
        end
    end
end })

ChamsSection:AddColorpicker("chams_color", { Title = "Fill Color", Default = Color3.fromRGB(50, 150, 255), Callback = function(v) ChamsSettings.Color = v end })
ChamsSection:AddColorpicker("chams_outline_color", { Title = "Outline Color", Default = Color3.fromRGB(0, 0, 0), Callback = function(v) ChamsSettings.OutlineColor = v end })
ChamsSection:AddSlider("chams_fill_transparency", { Title = "Fill Transparency", Default = 0.45, Min = 0, Max = 1, Rounding = 2, Callback = function(v) ChamsSettings.FillTransparency = v end })
ChamsSection:AddSlider("chams_outline_transparency", { Title = "Outline Transparency", Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function(v) ChamsSettings.OutlineTransparency = v end })

local TargetInfoSection = Tabs.ESP:AddSection("Target Info")
TargetInfoSection:AddToggle("target_info_enabled", { 
    Title = "Show Target Info", 
    Default = false, 
    Callback = function(v) 
        State.ShowTargetInfo = v
        if not v then 
            if Runtime.TargetInfoFrame then Runtime.TargetInfoFrame.Visible = false end
            Runtime.CurrentTarget = nil
        end
    end 
})

local ESPSettingsSection = Tabs.ESP:AddSection("Checks")
ESPSettingsSection:AddToggle("esp_team_check", { Title = "Team Check", Default = true, Callback = function(v) ESPSettings.ESPTeamCheck = v end })
ESPSettingsSection:AddSlider("esp_max_distance", { Title = "Max Distance", Default = 2000, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) ESPSettings.MaxESPDistance = v end })

local ParticlesSection = Tabs.Misc:AddSection("Particles")
ParticlesSection:AddButton({ Title = "No Flash", Callback = function()
    pcall(function()
        local flashEffect = Config.LocalPlayer.PlayerScripts.Assets.Misc:FindFirstChild("FlashbangEffect")
        if flashEffect then
            flashEffect:Destroy()
            Notify({ Title = "Flashbang Removed", Content = "Flashbang effects have been disabled", Duration = 3 })
        else
            Notify({ Title = "Already Removed", Content = "Flashbang effects are already disabled", Duration = 3 })
        end
    end)
end })

ParticlesSection:AddButton({ Title = "No Smoke", Callback = function()
    pcall(function()
        local smokeEffect = Config.LocalPlayer.PlayerScripts.Assets.Misc:FindFirstChild("SmokeClouds")
        if smokeEffect then
            smokeEffect:Destroy()
            Notify({ Title = "Smoke Removed", Content = "Smoke effects have been disabled", Duration = 3 })
        else
            Notify({ Title = "Already Removed", Content = "Smoke effects are already disabled", Duration = 3 })
        end
    end)
end })

local DeviceSpoofSection = Tabs.Misc:AddSection("Device Spoofer")
DeviceSpoofSection:AddDropdown("device_spoof", { Title = "Spoof Device", Values = {"Computer", "Mobile", "Console", "VR"}, Default = "Computer", Multi = false, Callback = function(v)
    local devices = { Computer = "MouseKeyboard", Mobile = "Touch", Console = "Gamepad", VR = "VR" }
    local deviceString = devices[v]
    if deviceString then
        pcall(function()
            local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local replication = remotes:FindFirstChild("Replication")
                if replication then
                    local fighter = replication:FindFirstChild("Fighter")
                    if fighter then
                        local setControls = fighter:FindFirstChild("SetControls")
                        if setControls then setControls:FireServer(deviceString) end
                    end
                end
            end
            Notify({ Title = "Device Spoofed", Content = "Now spoofed as " .. v, Duration = 3 })
        end)
    end
end })

local RewardsSection = Tabs.Misc:AddSection("Rewards")
RewardsSection:AddButton({ Title = "Claim All Rewards", Callback = function()
    pcall(function()
        local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local data = remotes:FindFirstChild("Data")
            if data then
                if data.ClaimLikeReward then data.ClaimLikeReward:FireServer() end
                if data.ClaimFavoriteReward then data.ClaimFavoriteReward:FireServer() end
                if data.ClaimNotificationsReward then data.ClaimNotificationsReward:FireServer() end
                if data.ClaimWelcomeBackGift then data.ClaimWelcomeBackGift:FireServer() end
            end
        end
        Notify({ Title = "Rewards Claimed", Content = "All available rewards have been claimed!", Duration = 3 })
    end)
end })

RewardsSection:AddButton({ Title = "Claim All Codes", Callback = function()
    pcall(function()
        local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local data = remotes:FindFirstChild("Data")
            if data then
                if data.VerifyTwitter then data.VerifyTwitter:FireServer() end
                local codes = { "COMMUNITY19", "FREE131", "BONUS", "ROBLOX_RTC", "BOOST" }
                for _, code in ipairs(codes) do
                    if data.RedeemCode then pcall(function() data.RedeemCode:InvokeServer(code) end) end
                end
            end
        end
        Notify({ Title = "Codes Redeemed", Content = "All known codes have been redeemed!", Duration = 3 })
    end)
end })

G.SolunaState.SkinChangerEnabled = false
G.SolunaState.SkinChangerHooked = false
G.SolunaState.SelectedSkins = G.SolunaState.SelectedSkins or {}
G.SolunaState.AvailableSkins = {}
G.SolunaState.WeaponToSkins = {}
G.SolunaState.WeaponCatalog = {}
G.SolunaState.SkinWatcherConnections = {}
G.SolunaState.ProcessedSkinModels = {}

G.SolunaSkinRuntime.UsesHardcodedSkinChanger = function()
    return ExecutorNameLower == "xeno" or ExecutorNameLower == "solara"
end

G.SolunaSkinRuntime.WeaponPlaceholderImage = "rbxassetid://9968344227"
G.SolunaSkinRuntime.SkinPlaceholderImage = "rbxassetid://8992230677"
G.SolunaSkinRuntime.ViewModelImageMap = {
    ["10B Visits"] = "rbxassetid://101791753953377",
    ["AK-47"] = "rbxassetid://17691136128",
    ["AKEY-47"] = "rbxassetid://77244120212187",
    ["AUG"] = "rbxassetid://18770201102",
    ["Aces"] = "rbxassetid://78850921968876",
    ["Advanced Satchel"] = "rbxassetid://118684510688617",
    ["Air Horn"] = "rbxassetid://128732687072177",
    ["Anchor"] = "rbxassetid://18769023932",
    ["Apex Pistols"] = "rbxassetid://132394469151873",
    ["Apex Rifle"] = "rbxassetid://111748806401551",
    ["Aqua Burst"] = "rbxassetid://18837677725",
    ["Arcane Warper"] = "rbxassetid://92765478127490",
    ["Arch Crossbow"] = "rbxassetid://107213949119266",
    ["Arch Katana"] = "rbxassetid://98068422294741",
    ["Armature.001"] = "rbxassetid://91555068782550",
    ["Assault Rifle"] = "rbxassetid://13197584241",
    ["Bag o' Money"] = "rbxassetid://118634288543707",
    ["Balance"] = "rbxassetid://18766909964",
    ["Balisong"] = "rbxassetid://114825371645118",
    ["Balloon Shorty"] = "rbxassetid://87872312114961",
    ["Balloon Shotgun"] = "rbxassetid://17821266090",
    ["Ban Axe"] = "rbxassetid://100159715604530",
    ["Banana Flare"] = "rbxassetid://135246839855870",
    ["Bat Bow"] = "rbxassetid://71508472340303",
    ["Bat Daggers"] = "rbxassetid://137570635514267",
    ["Bat Scythe"] = "rbxassetid://104168535403995",
    ["Battle Axe"] = "rbxassetid://78364101927650",
    ["Blaster"] = "rbxassetid://17821265750",
    ["Blobsaw"] = "rbxassetid://17825961425",
    ["Boba Gun"] = "rbxassetid://18768828072",
    ["Boneblade"] = "rbxassetid://126287813768518",
    ["Boneclaw Horn"] = "rbxassetid://126578341307256",
    ["Boneclaw Revolver"] = "rbxassetid://134217952089145",
    ["Boneclaw Rifle"] = "rbxassetid://116725320040796",
    ["Boneclaw Spray"] = "rbxassetid://127336875478381",
    ["Boneshot"] = "rbxassetid://103283614012077",
    ["Bounce House"] = "rbxassetid://79326657484315",
    ["Bow"] = "rbxassetid://13717212331",
    ["Boxing Gloves"] = "rbxassetid://17672089761",
    ["Brain Gun"] = "rbxassetid://135843933439701",
    ["Brass Knuckles"] = "rbxassetid://18766909587",
    ["Briefcase"] = "rbxassetid://18142174697",
    ["Broomstick"] = "rbxassetid://126607371232554",
    ["Bubble Ray"] = "rbxassetid://18769002868",
    ["Bucket of Candy"] = "rbxassetid://95706110401359",
    ["Bug Net"] = "rbxassetid://99173928762511",
    ["Burst Rifle"] = "rbxassetid://13482243466",
    ["Buzzsaw"] = "rbxassetid://128354991167944",
    ["Cactus Shotgun"] = "rbxassetid://128141817339029",
    ["Camera"] = "rbxassetid://18766908915",
    ["Candy Cane"] = "rbxassetid://84302121354096",
    ["Cerulean Axe"] = "rbxassetid://82989708806032",
    ["Chainsaw"] = "rbxassetid://13717445410",
    ["Chancla"] = "rbxassetid://17672089600",
    ["Coffee"] = "rbxassetid://17672089358",
    ["Compound Bow"] = "rbxassetid://17672229023",
    ["Cookies"] = "rbxassetid://112581667413176",
    ["Crossbone"] = "rbxassetid://81476287380261",
    ["Crossbow"] = "rbxassetid://130065160832422",
    ["Crude Gunblade"] = "rbxassetid://111573250598753",
    ["Cryo Scythe"] = "rbxassetid://84690820919174",
    ["Crystal Daggers"] = "rbxassetid://92405854307880",
    ["Crystal Katana"] = "rbxassetid://107573852829996",
    ["Crystal Scythe"] = "rbxassetid://88778703942724",
    ["Cyber Distortion"] = "rbxassetid://78940266607471",
    ["Cyber Warpstone"] = "rbxassetid://78671282003316",
    ["DIY Tripmine"] = "rbxassetid://105200997776122",
    ["Daggers"] = "rbxassetid://138508026547275",
    ["Demon Shorty"] = "rbxassetid://110819203451709",
    ["Demon Uzi"] = "rbxassetid://81076572654230",
    ["Desert Eagle"] = "rbxassetid://17821265603",
    ["Dev-in-the-Box"] = "rbxassetid://93100882010950",
    ["Disco Ball"] = "rbxassetid://17672089136",
    ["Distortion"] = "rbxassetid://130153907701944",
    ["Don't Press"] = "rbxassetid://17821264419",
    ["Door"] = "rbxassetid://137027368393353",
    ["Dream Bow"] = "rbxassetid://104571173348964",
    ["Dynamite"] = "rbxassetid://97225646481020",
    ["Dynamite Gun"] = "rbxassetid://17691136322",
    ["Electro Rifle"] = "rbxassetid://87621360986223",
    ["Electro Uzi"] = "rbxassetid://98294074022488",
    ["Electropunk Distortion"] = "rbxassetid://91778033503945",
    ["Electropunk Warper"] = "rbxassetid://96080679722284",
    ["Electropunk Warpstone"] = "rbxassetid://121167052087315",
    ["Elf's Gunblade"] = "rbxassetid://81214817732179",
    ["Emoji Cloud"] = "rbxassetid://17821265237",
    ["Energy Pistols"] = "rbxassetid://125338509278840",
    ["Energy Rifle"] = "rbxassetid://103736834693278",
    ["Energy Shield"] = "rbxassetid://127037252186171",
    ["Event Horizon"] = "rbxassetid://82446563771968",
    ["Exogourd"] = "rbxassetid://125880131168138",
    ["Exogun"] = "rbxassetid://17344797370",
    ["Experiment D15"] = "rbxassetid://118366946179457",
    ["Experiment W4"] = "rbxassetid://77873591123909",
    ["Eyeball"] = "rbxassetid://103493376163318",
    ["Eyething Sniper"] = "rbxassetid://96377501719526",
    ["FAMAS"] = "rbxassetid://110423034763836",
    ["Festive Buzzsaw"] = "rbxassetid://111566667788893",
    ["Festive Fists"] = "rbxassetid://98061476050478",
    ["Fighter Jet"] = "rbxassetid://95650502925488",
    ["Firework Gun"] = "rbxassetid://17691136322",
    ["Firework Launcher"] = "rbxassetid://93131277391830",
    ["Fists"] = "rbxassetid://16560051320",
    ["Fists of Hurt"] = "rbxassetid://71585039030211",
    ["Flamethrower"] = "rbxassetid://85223987405833",
    ["Flare Gun"] = "rbxassetid://13197583892",
    ["Flashbang"] = "rbxassetid://14664488253",
    ["Freeze Ray"] = "rbxassetid://18429549331",
    ["Frost Warper"] = "rbxassetid://84458438183331",
    ["Frostbite Bow"] = "rbxassetid://82246935699705",
    ["Frostbite Crossbow"] = "rbxassetid://116171878456521",
    ["Frozen Grenade"] = "rbxassetid://101932886938992",
    ["Garden Shovel"] = "rbxassetid://18766908058",
    ["Gearnade Launcher"] = "rbxassetid://91208130484582",
    ["Gingerbread AUG"] = "rbxassetid://108476862508992",
    ["Gingerbread Handgun"] = "rbxassetid://72714528734588",
    ["Gingerbread Sniper"] = "rbxassetid://120163896680390",
    ["Glitter Warper"] = "rbxassetid://128289126916762",
    ["Glitterthrower"] = "rbxassetid://83419562243412",
    ["Glorious Assault Rifle"] = "rbxassetid://130592949312939",
    ["Glorious Battle Axe"] = "rbxassetid://72356106057179",
    ["Glorious Bow"] = "rbxassetid://139021383472653",
    ["Glorious Burst Rifle"] = "rbxassetid://125258150017244",
    ["Glorious Chainsaw"] = "rbxassetid://140353527719287",
    ["Glorious Crossbow"] = "rbxassetid://125494419498405",
    ["Glorious Daggers"] = "rbxassetid://89590724074968",
    ["Glorious Distortion"] = "rbxassetid://107736694179886",
    ["Glorious Energy Pistols"] = "rbxassetid://85080210873739",
    ["Glorious Energy Rifle"] = "rbxassetid://95552510838071",
    ["Glorious Exogun"] = "rbxassetid://105785189977176",
    ["Glorious Fists"] = "rbxassetid://79755997614985",
    ["Glorious Flamethrower"] = "rbxassetid://88697784394796",
    ["Glorious Flare Gun"] = "rbxassetid://128135635660577",
    ["Glorious Flashbang"] = "rbxassetid://131190784940519",
    ["Glorious Freeze Ray"] = "rbxassetid://96505833323714",
    ["Glorious Grenade"] = "rbxassetid://102502933883025",
    ["Glorious Grenade Launcher"] = "rbxassetid://133636006123737",
    ["Glorious Gunblade"] = "rbxassetid://88582922101753",
    ["Glorious Handgun"] = "rbxassetid://73041314820303",
    ["Glorious Jump Pad"] = "rbxassetid://96408475917789",
    ["Glorious Katana"] = "rbxassetid://94429900086533",
    ["Glorious Knife"] = "rbxassetid://122760026905111",
    ["Glorious Maul"] = "rbxassetid://109898315901573",
    ["Glorious Medkit"] = "rbxassetid://73397457340415",
    ["Glorious Minigun"] = "rbxassetid://99372535399034",
    ["Glorious Molotov"] = "rbxassetid://95650602989880",
    ["Glorious Paintball Gun"] = "rbxassetid://92272641219379",
    ["Glorious Permafrost"] = "rbxassetid://82134252571554",
    ["Glorious RPG"] = "rbxassetid://77567945870953",
    ["Glorious Revolver"] = "rbxassetid://137749607553707",
    ["Glorious Riot Shield"] = "rbxassetid://117405461442739",
    ["Glorious Satchel"] = "rbxassetid://85737788428846",
    ["Glorious Scythe"] = "rbxassetid://113721128462866",
    ["Glorious Shorty"] = "rbxassetid://78845944937729",
    ["Glorious Shotgun"] = "rbxassetid://104100596412940",
    ["Glorious Slingshot"] = "rbxassetid://111031840425662",
    ["Glorious Smoke Grenade"] = "rbxassetid://121565824954563",
    ["Glorious Sniper"] = "rbxassetid://94794978921271",
    ["Glorious Spray"] = "rbxassetid://103484739840527",
    ["Glorious Subspace Tripmine"] = "rbxassetid://80869057489077",
    ["Glorious Trowel"] = "rbxassetid://132433921578446",
    ["Glorious Uzi"] = "rbxassetid://121978889022374",
    ["Glorious War Horn"] = "rbxassetid://123021790391323",
    ["Glorious Warper"] = "rbxassetid://117284572803988",
    ["Glorious Warpstone"] = "rbxassetid://99142505492556",
    ["Goalpost"] = "rbxassetid://17672086378",
    ["Grenade"] = "rbxassetid://14526777692",
    ["Grenade Launcher"] = "rbxassetid://17250456230",
    ["Gum Ray"] = "rbxassetid://124339207784760",
    ["Gumball Handgun"] = "rbxassetid://138794077251754",
    ["Gunblade"] = "rbxassetid://131462750179690",
    ["Gunsaw"] = "rbxassetid://136642950174663",
    ["Hacker Pistols"] = "rbxassetid://105705939354438",
    ["Hacker Rifle"] = "rbxassetid://89213922790170",
    ["Hand Gun"] = "rbxassetid://18837677423",
    ["Handgun"] = "rbxassetid://13197583693",
    ["Handsaws"] = "rbxassetid://18769002596",
    ["Harp"] = "rbxassetid://89702051394732",
    ["Harpoon Crossbow"] = "rbxassetid://127546301627893",
    ["Hot Coals"] = "rbxassetid://98070129509602",
    ["Hotel Bell"] = "rbxassetid://74303585805484",
    ["Hourglass"] = "rbxassetid://70423041582442",
    ["Hydro Pistols"] = "rbxassetid://102390688726302",
    ["Hydro Rifle"] = "rbxassetid://101984348353475",
    ["Hyper Gunblade"] = "rbxassetid://134499903901922",
    ["Hyper Shotgun"] = "rbxassetid://18768974410",
    ["Hyper Sniper"] = "rbxassetid://18766907266",
    ["Ice Maul"] = "rbxassetid://79987597452893",
    ["Ice Permafrost"] = "rbxassetid://122848886028890",
    ["Jack O'Thrower"] = "rbxassetid://81280342017495",
    ["Jingle Grenade"] = "rbxassetid://117226824301607",
    ["Jolly Man"] = "rbxassetid://98002300428288",
    ["Jump Pad"] = "rbxassetid://102532564314723",
    ["Karambit"] = "rbxassetid://18766907079",
    ["Katana"] = "rbxassetid://13968137196",
    ["Ketchup Gun"] = "rbxassetid://130402361506639",
    ["Key Bow"] = "rbxassetid://101924188286368",
    ["Keylisong"] = "rbxassetid://118944160521617",
    ["Keynade"] = "rbxassetid://122922810220976",
    ["Keynais"] = "rbxassetid://133742080595679",
    ["Keyper"] = "rbxassetid://122634584511896",
    ["Keyrambit"] = "rbxassetid://73252950434501",
    ["Keyst Rifle"] = "rbxassetid://138268719789353",
    ["Keytana"] = "rbxassetid://120478111112813",
    ["Keythe"] = "rbxassetid://75967374711732",
    ["Keyttle Axe"] = "rbxassetid://100168194779130",
    ["Keyvolver"] = "rbxassetid://73746116648532",
    ["Keyzi"] = "rbxassetid://127937206087121",
    ["Knife"] = "rbxassetid://13197583583",
    ["Lamethrower"] = "rbxassetid://18766906741",
    ["Laptop"] = "rbxassetid://18766906510",
    ["Lasergun 3000"] = "rbxassetid://116040043955852",
    ["Lava Lamp"] = "rbxassetid://76191080417885",
    ["Lightbulb"] = "rbxassetid://78421244256536",
    ["Lightning Bolt"] = "rbxassetid://18769002278",
    ["Lovely Shorty"] = "rbxassetid://18766906011",
    ["Lovely Spray"] = "rbxassetid://138177960576401",
    ["Machete"] = "rbxassetid://90332754966135",
    ["Magma Distortion"] = "rbxassetid://109079139956898",
    ["Mammoth Horn"] = "rbxassetid://107659166723688",
    ["Masterpiece"] = "rbxassetid://72274483575028",
    ["Maul"] = "rbxassetid://96956174894354",
    ["Medkit"] = "rbxassetid://13717497368",
    ["Medkitty"] = "rbxassetid://126646607101307",
    ["Mega Drill"] = "rbxassetid://78828669740807",
    ["Megaphone"] = "rbxassetid://100739584109870",
    ["Midnight Festive Exogun"] = "rbxassetid://80015495064851",
    ["Milk & Cookies"] = "rbxassetid://73601847002267",
    ["Mimic Axe"] = "rbxassetid://96746396437552",
    ["Minigun"] = "rbxassetid://17250457775",
    ["Molotov"] = "rbxassetid://83303332331234",
    ["Money Gun"] = "rbxassetid://73092203311844",
    ["Nail Gun"] = "rbxassetid://79527532659144",
    ["New Year Energy Pistols"] = "rbxassetid://88240834599421",
    ["New Year Energy Rifle"] = "rbxassetid://101868484686291",
    ["New Year Katana"] = "rbxassetid://79288379571855",
    ["Nordic Axe"] = "rbxassetid://86476943038006",
    ["Not So Shorty"] = "rbxassetid://17672087325",
    ["Notebook Satchel"] = "rbxassetid://85589408404069",
    ["Nuke Launcher"] = "rbxassetid://17672088925",
    ["Paintball Gun"] = "rbxassetid://16560547676",
    ["Paintbrush"] = "rbxassetid://83196688094998",
    ["Paper Planes"] = "rbxassetid://90572065167686",
    ["Pencil Launcher"] = "rbxassetid://74125168400547",
    ["Peppergun"] = "rbxassetid://112311707478578",
    ["Peppermint Sheriff"] = "rbxassetid://71229586558137",
    ["Permafrost"] = "rbxassetid://78468628083590",
    ["Phoenix Rifle"] = "rbxassetid://115604025497445",
    ["Pine Burst"] = "rbxassetid://100589243117991",
    ["Pine Spray"] = "rbxassetid://79010014206302",
    ["Pine Uzi"] = "rbxassetid://80778273701013",
    ["Pixel Burst"] = "rbxassetid://81440970309830",
    ["Pixel Crossbow"] = "rbxassetid://129836248906904",
    ["Pixel Flamethrower"] = "rbxassetid://17771753119",
    ["Pixel Flashbang"] = "rbxassetid://82894448978638",
    ["Pixel Handgun"] = "rbxassetid://72665687846028",
    ["Pixel Katana"] = "rbxassetid://83686692916164",
    ["Pixel Minigun"] = "rbxassetid://18769001642",
    ["Pixel Sniper"] = "rbxassetid://17676083400",
    ["Plasma Distortion"] = "rbxassetid://83622093873798",
    ["Plastic Shovel"] = "rbxassetid://17672088012",
    ["Potion Satchel"] = "rbxassetid://112434777433399",
    ["Pumpkin Carver"] = "rbxassetid://130169648063116",
    ["Pumpkin Claws"] = "rbxassetid://110587168549532",
    ["Pumpkin Handgun"] = "rbxassetid://92824393890642",
    ["Pumpkin Launcher"] = "rbxassetid://130301464984534",
    ["Pumpkin Minigun"] = "rbxassetid://101609024294564",
    ["RPG"] = "rbxassetid://13197583434",
    ["RPKEY"] = "rbxassetid://122750504849596",
    ["Raven Bow"] = "rbxassetid://18766905321",
    ["Ray Gun"] = "rbxassetid://18766905089",
    ["Reindeer Slingshot"] = "rbxassetid://106406735551091",
    ["Repulsor"] = "rbxassetid://130472229545721",
    ["Revolver"] = "rbxassetid://14020829500",
    ["Riot Shield"] = "rbxassetid://126785276332335",
    ["Saber"] = "rbxassetid://17672087756",
    ["Sakura Scythe"] = "rbxassetid://115063494552764",
    ["Sandwich"] = "rbxassetid://17838233196",
    ["Satchel"] = "rbxassetid://132559258532984",
    ["Scythe"] = "rbxassetid://13834995858",
    ["Scythe of Death"] = "rbxassetid://17825961272",
    ["Shady Chicken Sandwich"] = "rbxassetid://113753042073837",
    ["Sheriff"] = "rbxassetid://18770200449",
    ["Shining Star"] = "rbxassetid://73486952957582",
    ["Shorty"] = "rbxassetid://13255103172",
    ["Shotgun"] = "rbxassetid://13197583302",
    ["Shotkey"] = "rbxassetid://101615278610735",
    ["Shurikens"] = "rbxassetid://118592510576313",
    ["Singularity"] = "rbxassetid://17676875650",
    ["Skull Launcher"] = "rbxassetid://88061081371943",
    ["Skullbang"] = "rbxassetid://94894233513600",
    ["Sled"] = "rbxassetid://127016476735322",
    ["Sleigh Maul"] = "rbxassetid://112835874307935",
    ["Sleighstortion"] = "rbxassetid://113075083434001",
    ["Slime Gun"] = "rbxassetid://17672087561",
    ["Slingshot"] = "rbxassetid://17095306079",
    ["Smoke Grenade"] = "rbxassetid://16373283577",
    ["Sniper"] = "rbxassetid://13197583098",
    ["Snow Shovel"] = "rbxassetid://96400887574950",
    ["Snowball Gun"] = "rbxassetid://78161595959189",
    ["Snowball Launcher"] = "rbxassetid://136762406657736",
    ["Snowblower"] = "rbxassetid://80434566532022",
    ["Snowglobe"] = "rbxassetid://86696224913566",
    ["Snowman Permafrost"] = "rbxassetid://70467865456788",
    ["Soul Grenade"] = "rbxassetid://126980255892476",
    ["Soul Pistols"] = "rbxassetid://95359207769282",
    ["Soul Rifle"] = "rbxassetid://140115840236565",
    ["Spaceship Launcher"] = "rbxassetid://18766904375",
    ["Spectral Burst"] = "rbxassetid://135650382469411",
    ["Spider Ray"] = "rbxassetid://92621276006979",
    ["Spider Web"] = "rbxassetid://133104747106136",
    ["Spray"] = "rbxassetid://87291726953666",
    ["Spray Bottle"] = "rbxassetid://88384629194597",
    ["Spring"] = "rbxassetid://18766904035",
    ["Squid Launcher"] = "rbxassetid://80877003243435",
    ["Stealth Handgun"] = "rbxassetid://99321324367928",
    ["Stellar Katana"] = "rbxassetid://90901679194899",
    ["Stick"] = "rbxassetid://17672086502",
    ["Subspace Tripmine"] = "rbxassetid://17098773688",
    ["Suspicious Gift"] = "rbxassetid://131542627171282",
    ["Swashbuckler"] = "rbxassetid://17821265007",
    ["Teleport Disc"] = "rbxassetid://81728761431901",
    ["Temporal Ray"] = "rbxassetid://18429549663",
    ["The Shred"] = "rbxassetid://95922136476180",
    ["Tombstone Shield"] = "rbxassetid://114630737114417",
    ["Tommy Gun"] = "rbxassetid://84369917689099",
    ["Too Shorty"] = "rbxassetid://18129532343",
    ["Torch"] = "rbxassetid://120882142047198",
    ["Towerstone Handgun"] = "rbxassetid://116418326352365",
    ["Trampoline"] = "rbxassetid://92310435035049",
    ["Trick or Treat"] = "rbxassetid://105864401236960",
    ["Trowel"] = "rbxassetid://16560547384",
    ["Trumpet"] = "rbxassetid://113408430051712",
    ["Unstable Warpstone"] = "rbxassetid://71896071193185",
    ["Uranium Launcher"] = "rbxassetid://18766902983",
    ["Uzi"] = "rbxassetid://14020829706",
    ["Vexed Candle"] = "rbxassetid://136079178184476",
    ["Vexed Flare Gun"] = "rbxassetid://138983159218333",
    ["Violin Crossbow"] = "rbxassetid://119666131999240",
    ["Void Pistols"] = "rbxassetid://114821885011907",
    ["Void Rifle"] = "rbxassetid://107749233395884",
    ["War Horn"] = "rbxassetid://97997387092919",
    ["Warp Handgun"] = "rbxassetid://117404871573487",
    ["Warpbone"] = "rbxassetid://132473085580193",
    ["Warper"] = "rbxassetid://97537499062821",
    ["Warpeye"] = "rbxassetid://129554679066276",
    ["Warpstar"] = "rbxassetid://85728240647371",
    ["Warpstone"] = "rbxassetid://99660718217521",
    ["Water Balloon"] = "rbxassetid://18769001397",
    ["Water Uzi"] = "rbxassetid://17821264784",
    ["Whoopee Cushion"] = "rbxassetid://17672086704",
    ["Wondergun"] = "rbxassetid://17672086052",
    ["Wrapped Flare Gun"] = "rbxassetid://135904023852615",
    ["Wrapped Freeze Ray"] = "rbxassetid://77624613843681",
    ["Wrapped Minigun"] = "rbxassetid://77902572458498",
    ["Wrapped Shorty"] = "rbxassetid://85255622402845",
    ["Wrapped Shotgun"] = "rbxassetid://122560535811833",
}

G.SolunaSkinRuntime.WeaponToSkinsMap = {
    ["Crossbow"] = {"Crossbow", "Arch Crossbow", "Crossbone", "Frostbite Crossbow", "Glorious Crossbow", "Harpoon Crossbow", "Pixel Crossbow", "Violin Crossbow"},
    ["Grenade Launcher"] = {"Grenade Launcher", "Gearnade Launcher", "Glorious Grenade Launcher", "Skull Launcher", "Snowball Launcher", "Swashbuckler", "Uranium Launcher"},
    ["Medkit"] = {"Medkit", "Briefcase", "Bucket of Candy", "Glorious Medkit", "Laptop", "Medkitty", "Milk & Cookies", "Sandwich"},
    ["Burst Rifle"] = {"Burst Rifle", "Aqua Burst", "Electro Rifle", "FAMAS", "Glorious Burst Rifle", "Keyst Rifle", "Pine Burst", "Pixel Burst", "Spectral Burst"},
    ["Flashbang"] = {"Flashbang", "Camera", "Disco Ball", "Glorious Flashbang", "Lightbulb", "Pixel Flashbang", "Shining Star", "Skullbang"},
    ["Energy Pistols"] = {"Energy Pistols", "Apex Pistols", "Glorious Energy Pistols", "Hacker Pistols", "Hydro Pistols", "New Year Energy Pistols", "Soul Pistols", "Void Pistols"},
    ["Revolver"] = {"Revolver", "Boneclaw Revolver", "Desert Eagle", "Glorious Revolver", "Keyvolver", "Peppergun", "Peppermint Sheriff", "Sheriff"},
    ["Grenade"] = {"Grenade", "Dynamite", "Frozen Grenade", "Glorious Grenade", "Jingle Grenade", "Keynade", "Soul Grenade", "Water Balloon", "Whoopee Cushion"},
    ["Fists"] = {"Fists", "Boxing Gloves", "Brass Knuckles", "Festive Fists", "Fists of Hurt", "Glorious Fists", "Pumpkin Claws"},
    ["Warpstone"] = {"Warpstone", "Cyber Warpstone", "Electropunk Warpstone", "Glorious Warpstone", "Teleport Disc", "Unstable Warpstone", "Warpbone", "Warpeye", "Warpstar"},
    ["Scythe"] = {"Scythe", "Anchor", "Bat Scythe", "Bug Net", "Cryo Scythe", "Crystal Scythe", "Glorious Scythe", "Keythe", "Sakura Scythe", "Scythe of Death"},
    ["Slingshot"] = {"Slingshot", "Boneshot", "Glorious Slingshot", "Goalpost", "Harp", "Reindeer Slingshot", "Stick"},
    ["Battle Axe"] = {"Battle Axe", "Ban Axe", "Cerulean Axe", "Glorious Battle Axe", "Keyttle Axe", "Mimic Axe", "Nordic Axe", "The Shred"},
    ["Flare Gun"] = {"Flare Gun", "Banana Flare", "Dynamite Gun", "Firework Gun", "Glorious Flare Gun", "Vexed Flare Gun", "Wrapped Flare Gun"},
    ["Molotov"] = {"Molotov", "Coffee", "Glorious Molotov", "Hot Coals", "Lava Lamp", "Torch", "Vexed Candle"},
    ["Flamethrower"] = {"Flamethrower", "Glitterthrower", "Glorious Flamethrower", "Jack O'Thrower", "Lamethrower", "Pixel Flamethrower", "Snowblower"},
    ["Shotgun"] = {"Shotgun", "Balloon Shotgun", "Broomstick", "Cactus Shotgun", "Glorious Shotgun", "Hyper Shotgun", "Shotkey", "Wrapped Shotgun"},
    ["Permafrost"] = {"Permafrost", "Glorious Permafrost", "Ice Permafrost", "Snowman Permafrost"},
    ["Distortion"] = {"Distortion", "Cyber Distortion", "Electropunk Distortion", "Experiment D15", "Glorious Distortion", "Magma Distortion", "Plasma Distortion", "Sleighstortion"},
    ["Assault Rifle"] = {"Assault Rifle", "10B Visits", "AK-47", "AKEY-47", "AUG", "Boneclaw Rifle", "Gingerbread AUG", "Glorious Assault Rifle", "Phoenix Rifle", "Tommy Gun"},
    ["Exogun"] = {"Exogun", "Exogourd", "Glorious Exogun", "Midnight Festive Exogun", "Ray Gun", "Repulsor", "Singularity", "Wondergun"},
    ["Maul"] = {"Maul", "Glorious Maul", "Ice Maul", "Sleigh Maul"},
    ["Subspace Tripmine"] = {"Subspace Tripmine", "DIY Tripmine", "Dev-in-the-Box", "Don't Press", "Glorious Subspace Tripmine", "Spring", "Trick or Treat"},
    ["Shorty"] = {"Shorty", "Balloon Shorty", "Demon Shorty", "Glorious Shorty", "Lovely Shorty", "Not So Shorty", "Too Shorty", "Wrapped Shorty"},
    ["Freeze Ray"] = {"Freeze Ray", "Bubble Ray", "Glorious Freeze Ray", "Gum Ray", "Spider Ray", "Temporal Ray", "Wrapped Freeze Ray"},
    ["Sniper"] = {"Sniper", "Event Horizon", "Eyething Sniper", "Gingerbread Sniper", "Glorious Sniper", "Hyper Sniper", "Keyper", "Pixel Sniper"},
    ["Knife"] = {"Knife", "Armature.001", "Balisong", "Candy Cane", "Chancla", "Glorious Knife", "Karambit", "Keylisong", "Keyrambit", "Machete"},
    ["Chainsaw"] = {"Chainsaw", "Blobsaw", "Buzzsaw", "Festive Buzzsaw", "Glorious Chainsaw", "Handsaws", "Mega Drill"},
    ["Warper"] = {"Warper", "Arcane Warper", "Electropunk Warper", "Experiment W4", "Frost Warper", "Glitter Warper", "Glorious Warper", "Hotel Bell"},
    ["RPG"] = {"RPG", "Firework Launcher", "Glorious RPG", "Nuke Launcher", "Pencil Launcher", "Pumpkin Launcher", "RPKEY", "Spaceship Launcher", "Squid Launcher"},
    ["Riot Shield"] = {"Riot Shield", "Door", "Energy Shield", "Glorious Riot Shield", "Masterpiece", "Sled", "Tombstone Shield"},
    ["Trowel"] = {"Trowel", "Garden Shovel", "Glorious Trowel", "Paintbrush", "Plastic Shovel", "Pumpkin Carver", "Snow Shovel"},
    ["Jump Pad"] = {"Jump Pad", "Bounce House", "Glorious Jump Pad", "Jolly Man", "Shady Chicken Sandwich", "Spider Web", "Trampoline"},
    ["Handgun"] = {"Handgun", "Blaster", "Gingerbread Handgun", "Glorious Handgun", "Gumball Handgun", "Hand Gun", "Pixel Handgun", "Pumpkin Handgun", "Stealth Handgun", "Towerstone Handgun", "Warp Handgun"},
    ["Energy Rifle"] = {"Energy Rifle", "Apex Rifle", "Glorious Energy Rifle", "Hacker Rifle", "Hydro Rifle", "New Year Energy Rifle", "Soul Rifle", "Void Rifle"},
    ["Katana"] = {"Katana", "Arch Katana", "Crystal Katana", "Devil's Trident", "Glorious Katana", "Keytana", "Lightning Bolt", "New Year Katana", "Pixel Katana", "Saber", "Stellar Katana"},
    ["Spray"] = {"Spray", "Boneclaw Spray", "Glorious Spray", "Lovely Spray", "Nail Gun", "Pine Spray", "Spray Bottle"},
    ["Paintball Gun"] = {"Paintball Gun", "Boba Gun", "Brain Gun", "Glorious Paintball Gun", "Ketchup Gun", "Slime Gun", "Snowball Gun"},
    ["Uzi"] = {"Uzi", "Demon Uzi", "Electro Uzi", "Glorious Uzi", "Keyzi", "Money Gun", "Pine Uzi", "Water Uzi"},
    ["Smoke Grenade"] = {"Smoke Grenade", "Balance", "Emoji Cloud", "Eyeball", "Glorious Smoke Grenade", "Hourglass", "Snowglobe"},
    ["War Horn"] = {"War Horn", "Air Horn", "Boneclaw Horn", "Glorious War Horn", "Mammoth Horn", "Megaphone", "Trumpet"},
    ["Satchel"] = {"Satchel", "Advanced Satchel", "Bag o' Money", "Glorious Satchel", "Notebook Satchel", "Potion Satchel", "Suspicious Gift"},
    ["Gunblade"] = {"Gunblade", "Boneblade", "Crude Gunblade", "Elf's Gunblade", "Glorious Gunblade", "Gunsaw", "Hyper Gunblade"},
    ["Bow"] = {"Bow", "Bat Bow", "Compound Bow", "Dream Bow", "Frostbite Bow", "Glorious Bow", "Key Bow", "Raven Bow"},
    ["Daggers"] = {"Daggers", "Aces", "Bat Daggers", "Cookies", "Crystal Daggers", "Glorious Daggers", "Keynais", "Paper Planes", "Shurikens"},
    ["Minigun"] = {"Minigun", "Fighter Jet", "Glorious Minigun", "Lasergun 3000", "Pixel Minigun", "Pumpkin Minigun", "Wrapped Minigun"},
}

G.SolunaSkinRuntime.SkinAttachmentNames = {"_aim_position", "_aim_lookat", "_center", "_muzzle", "_grip", "_scope_glare"}

G.SolunaSkinRuntime.FindSkinAsset = function(skinName)
    local viewModelsAssets = Config.LocalPlayer.PlayerScripts.Assets:FindFirstChild("ViewModels")
    if not viewModelsAssets then return nil end
    for _, category in ipairs(viewModelsAssets:GetChildren()) do
        local found = category:FindFirstChild(skinName)
        if found then return found end
    end
    return nil
end

G.SolunaSkinRuntime.LoadHardcodedSkinData = function()
    G.SolunaState.AvailableSkins = {}
    G.SolunaState.WeaponToSkins = {}
    G.SolunaState.WeaponCatalog = {}
    G.SolunaState.WeaponList = {}
    for weaponName, skins in pairs(G.SolunaSkinRuntime.WeaponToSkinsMap) do
        G.SolunaState.WeaponToSkins[weaponName] = {}
        G.SolunaState.WeaponCatalog[weaponName] = { Name = weaponName, Image = G.SolunaSkinRuntime.ViewModelImageMap[weaponName] or G.SolunaSkinRuntime.WeaponPlaceholderImage, Skins = {} }
        table.insert(G.SolunaState.WeaponList, weaponName)
        for index, skinName in ipairs(skins) do
            table.insert(G.SolunaState.WeaponToSkins[weaponName], skinName)
            table.insert(G.SolunaState.AvailableSkins, skinName)
            table.insert(G.SolunaState.WeaponCatalog[weaponName].Skins, { Name = skinName, Image = G.SolunaSkinRuntime.ViewModelImageMap[skinName] or G.SolunaSkinRuntime.SkinPlaceholderImage, Rarity = index == 1 and "Default" or "Skin" })
        end
        table.sort(G.SolunaState.WeaponToSkins[weaponName], function(left, right)
            if left == weaponName then return true end
            if right == weaponName then return false end
            return left < right
        end)
        table.sort(G.SolunaState.WeaponCatalog[weaponName].Skins, function(left, right)
            if left.Name == weaponName then return true end
            if right.Name == weaponName then return false end
            return left.Name < right.Name
        end)
    end
    table.sort(G.SolunaState.AvailableSkins)
    table.sort(G.SolunaState.WeaponList)
    if not G.SolunaState.CurrentWeaponSelection or not G.SolunaState.WeaponCatalog[G.SolunaState.CurrentWeaponSelection] then
        G.SolunaState.CurrentWeaponSelection = G.SolunaState.WeaponList[1]
    end
end

G.SolunaSkinRuntime.ClearHardcodedSkinModel = function(weaponModel)
    local rootPart = weaponModel:FindFirstChild("HumanoidRootPart")
    local itemVisual = weaponModel:FindFirstChild("ItemVisual")
    local overlay = weaponModel:FindFirstChild("ItemVisualSkin")
    if rootPart then
        for _, motor in ipairs(rootPart:GetChildren()) do
            if motor:IsA("Motor6D") and string.find(motor.Name, "SkinVisual", 1, true) then motor:Destroy() end
        end
    end
    if overlay then overlay:Destroy() end
    if itemVisual then
        for _, descendant in ipairs(itemVisual:GetDescendants()) do
            if descendant:IsA("BasePart") then descendant.Transparency = 0 end
        end
    end
    G.SolunaState.ProcessedSkinModels[weaponModel] = nil
end

G.SolunaSkinRuntime.ParseWeaponModelName = function(modelName)
    local parts = string.split(modelName, " - ")
    if #parts < 3 then return nil, nil, nil end
    local ownerName = parts[1]
    local currentSkin = parts[#parts]
    local weaponNameParts = {}
    for index = 2, #parts - 1 do table.insert(weaponNameParts, parts[index]) end
    return ownerName, table.concat(weaponNameParts, " - "), currentSkin
end

G.SolunaSkinRuntime.SwapHardcodedSkinModel = function(weaponModel, targetSkinName)
    local skinAsset = G.SolunaSkinRuntime.FindSkinAsset(targetSkinName)
    if not skinAsset then return false end
    local rootPart = weaponModel:FindFirstChild("HumanoidRootPart")
    local itemVisual = weaponModel:FindFirstChild("ItemVisual")
    if not rootPart or not itemVisual then return false end
    G.SolunaSkinRuntime.ClearHardcodedSkinModel(weaponModel)
    for _, descendant in ipairs(itemVisual:GetDescendants()) do
        if descendant:IsA("BasePart") then descendant.Transparency = 1 end
    end
    local newItemModel = skinAsset:Clone()
    newItemModel.Name = "ItemVisualSkin"
    newItemModel.Parent = weaponModel
    for _, subModel in ipairs(newItemModel:GetChildren()) do
        if subModel.Name == "_fake" then
            subModel:Destroy()
        elseif subModel:IsA("Model") then
            subModel.PrimaryPart = subModel:FindFirstChild("Primary")
            if not subModel.PrimaryPart then continue end
            local armName = subModel.Name == "_right_arm" and "RightArm" or (subModel.Name == "_left_arm" and "LeftArm" or nil)
            if armName then
                local armPart = weaponModel:FindFirstChild(armName)
                if armPart then
                    subModel.Parent = armPart
                    subModel:PivotTo(armPart.CFrame)
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = armPart
                    weld.Part1 = subModel.PrimaryPart
                    weld.Parent = subModel.PrimaryPart
                end
            else
                local motor = Instance.new("Motor6D")
                motor.Part0 = rootPart
                motor.Part1 = subModel.PrimaryPart
                motor.Name = "SkinVisual[\"" .. subModel.Name .. "\"]"
                motor.C0 = subModel:GetAttribute("C0") or CFrame.identity
                motor.C1 = subModel:GetAttribute("C1") or CFrame.identity
                motor.Parent = rootPart
            end
            for _, part in ipairs(subModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CastShadow = false
                    part.CanCollide = false
                    part.CanTouch = false
                    part.CanQuery = false
                    part.Massless = true
                    if subModel.PrimaryPart and part ~= subModel.PrimaryPart then
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = subModel.PrimaryPart
                        weld.Part1 = part
                        weld.Parent = subModel.PrimaryPart
                        part.Anchored = false
                    end
                end
            end
            subModel.PrimaryPart.Anchored = false
            if not armName then
                subModel.PrimaryPart.Name = subModel.Name .. "Primary"
                subModel:PivotTo(rootPart.CFrame)
            end
        end
    end
    for _, attachmentName in ipairs(G.SolunaSkinRuntime.SkinAttachmentNames) do
        local oldAttachment = itemVisual:FindFirstChild(attachmentName, true)
        local newAttachment = newItemModel:FindFirstChild(attachmentName, true)
        if oldAttachment and newAttachment and oldAttachment:IsA("Attachment") and newAttachment:IsA("Attachment") then
            oldAttachment.CFrame = newAttachment.CFrame
        end
    end
    return true
end

G.SolunaSkinRuntime.ProcessHardcodedWeaponModel = function(weaponModel)
    if not G.SolunaState.SkinChangerEnabled then return false end
    local ownerName, weaponName, currentSkin = G.SolunaSkinRuntime.ParseWeaponModelName(weaponModel.Name)
    if ownerName ~= Config.LocalPlayer.Name or not weaponName then return false end
    local targetSkin = G.SolunaState.SelectedSkins[weaponName]
    if not targetSkin or targetSkin == weaponName then
        if weaponModel:FindFirstChild("ItemVisualSkin") then
            G.SolunaSkinRuntime.ClearHardcodedSkinModel(weaponModel)
            return true
        end
        G.SolunaState.ProcessedSkinModels[weaponModel] = weaponName
        return false
    end
    if G.SolunaState.ProcessedSkinModels[weaponModel] == targetSkin then return false end
    if targetSkin == currentSkin and not weaponModel:FindFirstChild("ItemVisualSkin") then
        G.SolunaState.ProcessedSkinModels[weaponModel] = targetSkin
        return false
    end
    local success = G.SolunaSkinRuntime.SwapHardcodedSkinModel(weaponModel, targetSkin)
    if success then G.SolunaState.ProcessedSkinModels[weaponModel] = targetSkin end
    return success
end

G.SolunaSkinRuntime.ForEachViewModel = function(callback)
local viewModelsFolder = workspace:FindFirstChild("ViewModels")
if not viewModelsFolder then return end
    local firstPerson = viewModelsFolder:FindFirstChild("FirstPerson")
    if firstPerson then
        for _, model in ipairs(firstPerson:GetChildren()) do
            if model:IsA("Model") then callback(model) end
        end
    end
    for _, model in ipairs(viewModelsFolder:GetChildren()) do
        if model ~= firstPerson and model:IsA("Model") then callback(model) end
    end
end

G.SolunaSkinRuntime.ApplyHardcodedSkins = function()
    local applied = 0
    local matched = 0
    G.SolunaSkinRuntime.ForEachViewModel(function(model)
        local ownerName, weaponName = G.SolunaSkinRuntime.ParseWeaponModelName(model.Name)
        if ownerName == Config.LocalPlayer.Name and weaponName and G.SolunaState.SelectedSkins[weaponName] then matched = matched + 1 end
        if G.SolunaSkinRuntime.ProcessHardcodedWeaponModel(model) then applied = applied + 1 end
    end)
    return applied, matched
end

G.SolunaSkinRuntime.SetupHardcodedSkinChangerHook = function()
    if G.SolunaState.SkinChangerHooked then return end
local viewModelsFolder = workspace:FindFirstChild("ViewModels")
if not viewModelsFolder then return end
    G.SolunaState.SkinChangerHooked = true
    local firstPerson = viewModelsFolder:FindFirstChild("FirstPerson")
    local function onChildAdded(child)
        if child:IsA("Model") then
            task.wait(0.1)
            G.SolunaSkinRuntime.ProcessHardcodedWeaponModel(child)
        end
    end
    if firstPerson then table.insert(G.SolunaState.SkinWatcherConnections, firstPerson.ChildAdded:Connect(onChildAdded)) end
    table.insert(G.SolunaState.SkinWatcherConnections, viewModelsFolder.ChildAdded:Connect(function(child)
        if child ~= firstPerson then onChildAdded(child) end
    end))
    G.SolunaSkinRuntime.ApplyHardcodedSkins()
end

G.SolunaSkinRuntime.LoadSkinData = function()
    if G.SolunaSkinRuntime.UsesHardcodedSkinChanger() then
        G.SolunaSkinRuntime.LoadHardcodedSkinData()
        return
    end
    if State.RequireBlocked then return end
    pcall(function()
        local CosmeticLib = GetCosmeticLibrary()
        local ItemLib = GetItemLibrary()
        if not CosmeticLib or not ItemLib then return end
        G.SolunaState.AvailableSkins = {}
        G.SolunaState.WeaponToSkins = {}
        G.SolunaState.WeaponCatalog = {}
        for skinName, cosmetic in pairs(CosmeticLib.Cosmetics) do
            if cosmetic.Type == "Skin" and cosmetic.ItemName then
                local weaponName = cosmetic.ItemName
                if not G.SolunaState.WeaponToSkins[weaponName] then G.SolunaState.WeaponToSkins[weaponName] = {} end
                if not G.SolunaState.WeaponCatalog[weaponName] then
                    G.SolunaState.WeaponCatalog[weaponName] = { Name = weaponName, Image = ItemLib:GetViewModelImage(weaponName, nil, true) or ItemLib:GetViewModelImage(weaponName) or "", Skins = {} }
                end
                table.insert(G.SolunaState.WeaponToSkins[weaponName], skinName)
                table.insert(G.SolunaState.AvailableSkins, skinName)
                table.insert(G.SolunaState.WeaponCatalog[weaponName].Skins, { Name = skinName, Image = cosmetic.ImageHighResolution or cosmetic.Image or ItemLib:GetViewModelImage(skinName, nil, true) or ItemLib:GetViewModelImage(skinName) or "", Rarity = cosmetic.Rarity or "Common" })
            end
        end
        for weaponName, skins in pairs(G.SolunaState.WeaponToSkins) do
            table.sort(skins)
            table.sort(G.SolunaState.WeaponCatalog[weaponName].Skins, function(left, right) return left.Name < right.Name end)
        end
        table.sort(G.SolunaState.AvailableSkins)
        G.SolunaState.WeaponList = {}
        for weaponName in pairs(G.SolunaState.WeaponCatalog) do table.insert(G.SolunaState.WeaponList, weaponName) end
        table.sort(G.SolunaState.WeaponList)
        if not G.SolunaState.CurrentWeaponSelection or not G.SolunaState.WeaponCatalog[G.SolunaState.CurrentWeaponSelection] then
            G.SolunaState.CurrentWeaponSelection = G.SolunaState.WeaponList[1]
        end
    end)
end

G.SolunaSkinRuntime.SetupSkinChangerHook = function()
    if G.SolunaSkinRuntime.UsesHardcodedSkinChanger() then
        G.SolunaSkinRuntime.SetupHardcodedSkinChangerHook()
        return
    end
    if State.RequireBlocked then return end
    if G.SolunaState.SkinChangerHooked then return end
    G.SolunaState.SkinChangerHooked = true
    pcall(function()
        local ClientViewModelModule = GetClientViewModelModule()
        local ItemLibrary = GetItemLibrary()
        local Utility = GetUtilityLibrary()
        if not ClientViewModelModule or not ItemLibrary or not Utility then return end
        local ViewModelsAssets = Config.LocalPlayer.PlayerScripts.Assets.ViewModels
        if not G.SolunaState.OriginalViewModelNew then G.SolunaState.OriginalViewModelNew = ClientViewModelModule.new end
        ClientViewModelModule.new = function(serialData, clientItem)
            local originalName = nil
            local targetSkin = nil
            pcall(function()
                if not serialData then return end
                local EnumLib = GetEnumLibrary()
                if not EnumLib then return end
                local dataKey = EnumLib:ToEnum("Data")
                local nameKey = EnumLib:ToEnum("Name")
                if not dataKey or not serialData[dataKey] then return end
                originalName = serialData[dataKey][nameKey]
                if G.SolunaState.SkinChangerEnabled and clientItem and clientItem.Name then
                    targetSkin = G.SolunaState.SelectedSkins[clientItem.Name]
                    if targetSkin and ItemLibrary.ViewModels[targetSkin] then
                        serialData[dataKey][nameKey] = targetSkin
                    else
                        targetSkin = nil
                    end
                end
            end)
            local viewModelInstance = G.SolunaState.OriginalViewModelNew(serialData, clientItem)
            if targetSkin and viewModelInstance then
                pcall(function()
                    viewModelInstance.Name = targetSkin
                    viewModelInstance.Info = ItemLibrary.ViewModels[targetSkin]
                    if viewModelInstance.Animator then viewModelInstance.Animator:LoadAnimations() end
                    for _, sound in pairs(viewModelInstance._preloaded_sounds or {}) do pcall(function() sound:Destroy() end) end
                    viewModelInstance._preloaded_sounds = {}
                    local SoundLibrary = GetSoundLibrary()
                    if not SoundLibrary then return end
                    local skinInfo = ItemLibrary.ViewModels[targetSkin]
                    if skinInfo and skinInfo.Animations then
                        for _, animName in pairs(skinInfo.Animations) do
                            if SoundLibrary.AnimationSounds[animName] then SoundLibrary:PreloadSounds(SoundLibrary.AnimationSounds[animName], viewModelInstance._preloaded_sounds) end
                        end
                    end
                    if SoundLibrary.ViewModelSounds[targetSkin] then SoundLibrary:PreloadSounds(SoundLibrary.ViewModelSounds[targetSkin], viewModelInstance._preloaded_sounds) end
                end)
            end
            return viewModelInstance
        end
    end)
end

G.SolunaSkinRuntime.ApplySkinToCurrentWeapon = function()
    if G.SolunaSkinRuntime.UsesHardcodedSkinChanger() then
        local applied, matched = G.SolunaSkinRuntime.ApplyHardcodedSkins()
        if matched > 0 then return true, "Synced " .. tostring(matched) .. " equipped skin(s)" end
        return false, "No equipped weapon model found"
    end
    if State.RequireBlocked then return false, "Require unavailable" end
    local fc = GetFighterController()
    if not fc or not fc.LocalFighter then return false, "No fighter" end
    local equippedItem = fc.LocalFighter.EquippedItem
    if not equippedItem then return false, "No weapon equipped" end
    local itemName = equippedItem.Name
    local selectedSkin = G.SolunaState.SelectedSkins[itemName]
    if not selectedSkin then return false, "No skin selected for " .. itemName end
    local viewModel = equippedItem.ViewModel
    if not viewModel then return false, "No ViewModel" end
    local ItemLibrary = GetItemLibrary()
    local Utility = GetUtilityLibrary()
    local SoundLibrary = GetSoundLibrary()
    if not ItemLibrary or not Utility then return false, "Require unavailable" end
    if not SoundLibrary then return false, "Require unavailable" end
    local ViewModelsAssets = Config.LocalPlayer.PlayerScripts.Assets:FindFirstChild("ViewModels")
    if not ViewModelsAssets then return false, "ViewModels folder not found" end
    if not ItemLibrary.ViewModels[selectedSkin] then return false, "Skin not in ItemLibrary: " .. selectedSkin end
    local success, err = pcall(function()
        for _, motor in pairs(viewModel.Model.PrimaryPart:GetChildren()) do
            if motor:IsA("Motor6D") and string.find(motor.Name, "ItemVisual") then motor:Destroy() end
        end
        if viewModel.ItemModel then viewModel.ItemModel:Destroy() end
        local newItemModel = Utility:LookThrough(ViewModelsAssets, selectedSkin):Clone()
        local newInfo = ItemLibrary.ViewModels[selectedSkin]
        viewModel.Name = selectedSkin
        viewModel.Info = newInfo
        viewModel._root_part_offset_inverse = newInfo.RootPartOffset and newInfo.RootPartOffset:Inverse() or CFrame.identity
        newItemModel.Name = "ItemVisual"
        viewModel.ItemModel = newItemModel
        viewModel._original_scale = newItemModel:GetScale()
        viewModel._body_model = newItemModel:FindFirstChild("Body")
        viewModel._aim_position_attachment = newItemModel:FindFirstChild("_aim_position", true)
        viewModel._aim_lookat_attachment = newItemModel:FindFirstChild("_aim_lookat", true)
        viewModel._center_attachment = newItemModel:FindFirstChild("_center", true)
        viewModel._charm_attachment_model = newItemModel:FindFirstChild("_charm_attachment_model", true)
        viewModel._charm_pivot_attachment = viewModel._charm_attachment_model and viewModel._charm_attachment_model:FindFirstChild("_charm_pivot_attachment", true) or viewModel.Model:FindFirstChild("_charm_pivot_attachment", true)
        viewModel._scope_glare_attachment = newItemModel:FindFirstChild("_scope_glare", true)
        viewModel.AimingAnimationEnabled = viewModel._aim_position_attachment ~= nil and viewModel._aim_lookat_attachment ~= nil
        viewModel._muzzle_attachments = {}
        viewModel._hidden_submodels = {}
        viewModel._animation_context_submodels = {}
        viewModel._arm_submodels = {}
        local rootPart = viewModel.Model.PrimaryPart
        local firstCFrame = nil
        for _, subModel in pairs(newItemModel:GetChildren()) do
            if subModel.Name == "_fake" then
                subModel:Destroy()
            else
                if subModel:FindFirstChild("Primary") then subModel.PrimaryPart = subModel.Primary end
                firstCFrame = firstCFrame or (subModel.PrimaryPart and subModel.PrimaryPart.CFrame)
                local armName = subModel.Name == "_right_arm" and "RightArm" or (subModel.Name == "_left_arm" and "LeftArm" or nil)
                if armName then
                    viewModel._arm_submodels[subModel] = subModel:GetScale()
                    local armPart = viewModel.Model:FindFirstChild(armName)
                    if armPart then
                        subModel.Parent = armPart
                        subModel:PivotTo(armPart.CFrame)
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = armPart
                        weld.Part1 = subModel.PrimaryPart
                        weld.Parent = subModel.PrimaryPart
                    end
                else
                    local motor = Instance.new("Motor6D")
                    motor.Part0 = rootPart
                    motor.Part1 = subModel.PrimaryPart
                    motor.Name = "ItemVisual[\"" .. subModel.Name .. "\"]"
                    motor.C0 = subModel:GetAttribute("C0") or (subModel.PrimaryPart and firstCFrame and subModel.PrimaryPart.CFrame:ToObjectSpace(firstCFrame):Inverse() or CFrame.identity)
                    motor.C1 = subModel:GetAttribute("C1") or CFrame.identity
                    motor.Parent = rootPart
                end
                for _, part in pairs(subModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CastShadow = false
                        part.CanCollide = false
                        part.CanTouch = false
                        part.CanQuery = false
                        part.Massless = true
                        if subModel.PrimaryPart and part ~= subModel.PrimaryPart then
                            local weld = Instance.new("WeldConstraint")
                            weld.Part0 = subModel.PrimaryPart
                            weld.Part1 = part
                            weld.Parent = subModel.PrimaryPart
                            part.Anchored = false
                        end
                    end
                    if part.Name == "_muzzle" then table.insert(viewModel._muzzle_attachments, part) end
                end
                if subModel.PrimaryPart then
                    subModel.PrimaryPart.Anchored = false
                    if not armName then
                        subModel.PrimaryPart.Name = subModel.Name .. "Primary"
                        subModel:PivotTo(rootPart.CFrame)
                    end
                end
                local animContexts = subModel:GetAttribute("AnimationContexts")
                if animContexts then
                    viewModel._animation_context_submodels[subModel] = {}
                    for ctx in string.gmatch(animContexts, "[^,]+") do table.insert(viewModel._animation_context_submodels[subModel], ctx:match("^%s*(.-)%s*$")) end
                end
            end
        end
        newItemModel.Parent = viewModel.Model
        if viewModel.Animator then
            viewModel.Animator:StopAllAnimations()
            viewModel.Animator:LoadAnimations()
            viewModel.Animator:PlayIdleAnimation()
        end
        for _, sound in pairs(viewModel._preloaded_sounds or {}) do pcall(function() sound:Destroy() end) end
        viewModel._preloaded_sounds = {}
        if newInfo.Animations then
            for _, animName in pairs(newInfo.Animations) do
                if SoundLibrary.AnimationSounds[animName] then SoundLibrary:PreloadSounds(SoundLibrary.AnimationSounds[animName], viewModel._preloaded_sounds) end
            end
        end
        if SoundLibrary.ViewModelSounds[selectedSkin] then SoundLibrary:PreloadSounds(SoundLibrary.ViewModelSounds[selectedSkin], viewModel._preloaded_sounds) end
    end)
    if success then return true, "Applied " .. selectedSkin .. " to " .. itemName else return false, "Error: " .. tostring(err) end
end

G.SolunaSkinRuntime.ApplyAllSkins = function()
    if not G.SolunaState.SkinChangerEnabled then return end
    if G.SolunaSkinRuntime.UsesHardcodedSkinChanger() then
        G.SolunaSkinRuntime.ApplyHardcodedSkins()
        return
    end
    local fc = GetFighterController()
    if not fc or not fc.LocalFighter then return end
    local equippedItem = fc.LocalFighter.EquippedItem
    if equippedItem then G.SolunaSkinRuntime.ApplySkinToCurrentWeapon() end
end

G.SolunaState.WeaponList = {"Assault Rifle", "Crossbow", "Grenade Launcher", "Medkit", "Burst Rifle", "Flashbang", "Energy Pistols", "Revolver", "Grenade", "Fists", "Warpstone", "Scythe", "Slingshot", "Battle Axe", "Flare Gun", "Molotov", "Flamethrower", "Shotgun", "Permafrost", "Distortion", "Exogun", "Maul", "Subspace Tripmine", "Shorty", "Freeze Ray", "Sniper", "Knife", "Chainsaw", "Warper", "RPG", "Riot Shield", "Trowel", "Jump Pad", "Handgun", "Energy Rifle", "Katana", "Spray", "Paintball Gun", "Uzi", "Smoke Grenade", "War Horn", "Satchel", "Gunblade", "Bow", "Daggers", "Minigun"}
task.defer(G.SolunaSkinRuntime.LoadSkinData)

task.defer(function()
    G.SolunaState.WeaponList = {}
    for weaponName, _ in pairs(G.SolunaSkinRuntime.WeaponToSkinsMap) do
        table.insert(G.SolunaState.WeaponList, weaponName)
    end
    table.sort(G.SolunaState.WeaponList)
    G.SolunaState.WeaponCatalog = G.SolunaState.WeaponCatalog or {}
    if SkinWeaponDropdown then
        SkinWeaponDropdown:SetValues(G.SolunaState.WeaponList)
    end
end)

if not G.SolunaState.WeaponList or #G.SolunaState.WeaponList == 0 then
    G.SolunaState.WeaponList = {"Assault Rifle"}
end

G.SolunaState.WeaponList = {}
for weaponName, _ in pairs(G.SolunaSkinRuntime.WeaponToSkinsMap) do
    table.insert(G.SolunaState.WeaponList, weaponName)
end
table.sort(G.SolunaState.WeaponList)
G.SolunaState.WeaponCatalog = G.SolunaState.WeaponCatalog or {}

G.SolunaState.SkinConfigFile = "SSC.json"

G.SolunaSkinRuntime.GetSkinConfigData = function()
    return { SelectedSkins = G.SolunaState.SelectedSkins or {}, SkinChangerEnabled = G.SolunaState.SkinChangerEnabled, CurrentWeaponSelection = G.SolunaState.CurrentWeaponSelection }
end

G.SolunaSkinRuntime.SetSkinConfigData = function(data)
    if type(data) ~= "table" then return end
    if type(data.SelectedSkins) == "table" then G.SolunaState.SelectedSkins = data.SelectedSkins else G.SolunaState.SelectedSkins = data end
    if data.SkinChangerEnabled ~= nil then G.SolunaState.SkinChangerEnabled = data.SkinChangerEnabled == true end
    if type(data.CurrentWeaponSelection) == "string" then G.SolunaState.CurrentWeaponSelection = data.CurrentWeaponSelection end
    if not G.SolunaState.WeaponCatalog[G.SolunaState.CurrentWeaponSelection] then G.SolunaState.CurrentWeaponSelection = G.SolunaState.WeaponList and G.SolunaState.WeaponList[1] end
end

G.SolunaSkinRuntime.SaveSkinConfig = function()
    pcall(function()
        local data = Services.HttpService:JSONEncode(G.SolunaSkinRuntime.GetSkinConfigData())
        writefile(G.SolunaState.SkinConfigFile, data)
    end)
end

G.SolunaSkinRuntime.LoadSkinConfig = function()
    pcall(function()
        if isfile(G.SolunaState.SkinConfigFile) then
            local data = readfile(G.SolunaState.SkinConfigFile)
            G.SolunaSkinRuntime.SetSkinConfigData(Services.HttpService:JSONDecode(data) or {})
        end
    end)
end

G.SolunaSkinRuntime.LoadSkinConfig()

G.SolunaSkinRuntime.RefreshSkinChangerState = function()
    if G.SolunaState.SkinChangerEnabled then
        G.SolunaSkinRuntime.SetupSkinChangerHook()
        G.SolunaSkinRuntime.ApplyAllSkins()
    end
end

local SkinsSection = Tabs.Skins:AddSection("Skins")
local SkinWeaponDropdown = SkinsSection:AddDropdown("SkinWeapon", { Title = "Weapon", Values = G.SolunaState.WeaponList, Default = G.SolunaState.CurrentWeaponSelection or "Assault Rifle", Multi = false })
local SkinSelectionDropdown = SkinsSection:AddDropdown("SkinSelection", { Title = "Skin", Values = {}, Default = 1, Multi = false })

SkinWeaponDropdown:OnChanged(function(Value)
    if Value then
        G.SolunaState.CurrentWeaponSelection = Value
        local skins = {}
        if G.SolunaState.WeaponCatalog and G.SolunaState.WeaponCatalog[Value] then
            for _, s in ipairs(G.SolunaState.WeaponCatalog[Value].Skins) do table.insert(skins, s.Name) end
        elseif G.SolunaSkinRuntime.WeaponToSkinsMap and G.SolunaSkinRuntime.WeaponToSkinsMap[Value] then
            for _, s in ipairs(G.SolunaSkinRuntime.WeaponToSkinsMap[Value]) do table.insert(skins, s) end
        end
        SkinSelectionDropdown:SetValues(skins)
        local current = G.SolunaState.SelectedSkins[Value]
        if current then SkinSelectionDropdown:SetValue(current) end
    end
end)

task.defer(function()
    task.defer(G.SolunaSkinRuntime.LoadSkinData)
    if SkinWeaponDropdown and G.SolunaState.WeaponList then
        SkinWeaponDropdown:SetValues(G.SolunaState.WeaponList)
        if G.SolunaState.CurrentWeaponSelection then
            SkinWeaponDropdown:SetValue(G.SolunaState.CurrentWeaponSelection)
        end
    end
end)

SkinSelectionDropdown:OnChanged(function(Value)
    if Value and G.SolunaState.CurrentWeaponSelection then
        G.SolunaState.SelectedSkins[G.SolunaState.CurrentWeaponSelection] = Value
        if G.SolunaSkinRuntime.RefreshSkinChangerState then
            G.SolunaSkinRuntime.RefreshSkinChangerState()
        end
    end
end)

SkinsSection:AddToggle("SkinChangerEnabled", { Title = "Enable Skin Changer", Default = G.SolunaState.SkinChangerEnabled, Callback = function(v)
    G.SolunaState.SkinChangerEnabled = v
    if G.SolunaSkinRuntime.RefreshSkinChangerState then
        G.SolunaSkinRuntime.RefreshSkinChangerState()
    end
end })

SkinsSection:AddButton({ Title = "Apply Equipped", Callback = function()
    local success, message = G.SolunaSkinRuntime.ApplySkinToCurrentWeapon()
    Notify({ Title = success and "Skin Applied" or "Error", Content = message, Duration = 2 })
end })

SkinsSection:AddButton({ Title = "Save Config", Callback = function()
    G.SolunaSkinRuntime.SaveSkinConfig()
    Notify({ Title = "Skins Saved", Content = "Saved selections", Duration = 2 })
end })

SkinsSection:AddButton({ Title = "Load Config", Callback = function()
    Notify({ Title = "Loading Config", Content = "Please wait 2 seconds...", Duration = 2 })
    task.spawn(function()
        task.wait(2)
        G.SolunaSkinRuntime.LoadSkinConfig()
        if G.SolunaSkinRuntime.RefreshSkinChangerState then
            G.SolunaSkinRuntime.RefreshSkinChangerState()
        end
        SkinWeaponDropdown:SetValue(G.SolunaState.CurrentWeaponSelection or G.SolunaState.WeaponList[1])
        Notify({ Title = "Config Loaded", Content = "Skin config loaded successfully!", Duration = 2 })
    end)
end })

SkinsSection:AddButton({ Title = "Clear All", Callback = function()
    G.SolunaState.SelectedSkins = {}
    if G.SolunaSkinRuntime.RefreshSkinChangerState then
        G.SolunaSkinRuntime.RefreshSkinChangerState()
    end
    SkinSelectionDropdown:SetValue(nil)
end })

local UnlockAllSection = Tabs.Skins:AddSection("Unlock All")
local UnlockAllEnabled = false

UnlockAllSection:AddToggle("unlock_all_enabled", { Title = "Unlock All Cosmetics", Default = false, Callback = function(v)
    UnlockAllEnabled = v
    task.spawn(function()
    pcall(function()
        task.wait(4)

        local _plrs    = game:GetService("Players")
        local _rs      = game:GetService("ReplicatedStorage")
        local _http    = game:GetService("HttpService")
        local _run     = game:GetService("RunService")
        local _ws      = game:GetService("Workspace")
        local _lp      = _plrs.LocalPlayer
        local _pscripts = _lp.PlayerScripts
        local _ctrl    = _pscripts.Controllers
        local _mods    = _rs:WaitForChild("Modules", 10)

        local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
        if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

        local _cosLib  = require(_mods:WaitForChild("CosmeticLibrary", 10))
        local _itmLib  = require(_mods:WaitForChild("ItemLibrary", 10))
        local _datCtrl = require(_ctrl:WaitForChild("PlayerDataController", 10))

        local _eq, _favs = {}, {}
        local _buildingWep, _viewProf = nil, nil
        local _lastWep = nil
        local _fakeInv = {}

        local function _mkCosmetic(nm, ctype, opts)
            local _base = _cosLib.Cosmetics[nm]
            if not _base then return nil end
            local _d = {}
            for k, v in pairs(_base) do _d[k] = v end
            _d.Name = nm
            _d.Type = _d.Type or ctype
            _d.Seed = _d.Seed or math.random(1, 1000000)
            if _enumLib then
                local _s, _eid = pcall(_enumLib.ToEnum, _enumLib, nm)
                if _s and _eid then
                    _d.Enum = _eid
                    _d.ObjectID = _d.ObjectID or _eid
                end
            end
            if opts then
                if opts.inverted ~= nil then _d.Inverted = opts.inverted end
                if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
            end
            return _d
        end

        local _cfgFile = "rivals_unlocker_config.json"
        local _saveLock = false

        local function _stripForSave()
            local _out = {}
            for wn, cos in pairs(_eq) do
                _out[wn] = {}
                for ct, cd in pairs(cos) do
                    if cd and cd.Name then
                        _out[wn][ct] = {
                            Name = cd.Name,
                            Inverted = cd.Inverted,
                            OnlyUseFavorites = cd.OnlyUseFavorites
                        }
                    end
                end
            end
            return { equipped = _out, favorites = _favs }
        end

        local function _loadCfg()
            if not isfile or not readfile then return end
            local _ok1, _ex = pcall(isfile, _cfgFile)
            if not _ok1 or not _ex then return end
            local _ok2, _raw = pcall(readfile, _cfgFile)
            if not _ok2 or not _raw or _raw == "" then return end
            local _ok3, _dec = pcall(_http.JSONDecode, _http, _raw)
            if not _ok3 or not _dec then return end
            if _dec.favorites then
                _favs = _dec.favorites
            end
            if _dec.equipped then
                _eq = {}
                local _cnt = 0
                for wn, cos in pairs(_dec.equipped) do
                    _eq[wn] = {}
                    for ct, sd in pairs(cos) do
                        if sd and sd.Name then
                            if _cosLib.Cosmetics[sd.Name] then
                                local _cloned = _mkCosmetic(sd.Name, ct, {
                                    inverted = sd.Inverted,
                                    favoritesOnly = sd.OnlyUseFavorites
                                })
                                if _cloned then
                                    _eq[wn][ct] = _cloned
                                    _cnt += 1
                                end
                            end
                        end
                    end
                    if not next(_eq[wn]) then _eq[wn] = nil end
                end
            end
        end

        local function _saveCfg()
            if not writefile or _saveLock then return end
            _saveLock = true
            task.spawn(function()
                task.wait(1)
                local _payload = _stripForSave()
                local _ok, _enc = pcall(_http.JSONEncode, _http, _payload)
                if _ok then
                    pcall(writefile, _cfgFile, _enc)
                end
                _saveLock = false
            end)
        end

        _loadCfg()

        local _cosTypes = {"Skin","Wrap","Charm","Dance","Emote"}
        local function _isCosType(cosObj)
            if not cosObj then return false end
            for _, t in ipairs(_cosTypes) do
                if cosObj.Type == t then return true end
            end
            return false
        end

        if v then
            _cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep)
                local c = _cosLib.Cosmetics[nm]
                if c and c.Type == "Skin" then return true end
                return false
            end
            _cosLib.OwnsCosmeticUniversally = function(self, inv, nm, wep)
                local c = _cosLib.Cosmetics[nm]
                if c and c.Type == "Skin" then return true end
                return false
            end
            _cosLib.OwnsCosmeticForWeapon = function(self, inv, nm, wep)
                local c = _cosLib.Cosmetics[nm]
                if c and c.Type == "Skin" then return true end
                return false
            end

            if not _cosLib._origOwns then
                _cosLib._origOwns = _cosLib.OwnsCosmetic
            end
            _cosLib.OwnsCosmetic = function(self, inv, nm, wep)
                if nm:find("MISSING_") or nm == "Bubble Gun" then
                    return _cosLib._origOwns(self, inv, nm, wep)
                end
                local c = _cosLib.Cosmetics[nm]
                if c and _isCosType(c) then return true end
                return _cosLib._origOwns(self, inv, nm, wep)
            end

            if not _datCtrl._origGet then
                _datCtrl._origGet = _datCtrl.Get
            end
            _datCtrl.Get = function(self, key)
                local _val = _datCtrl._origGet(self, key)
                if key == "CosmeticInventory" then
                    local _prx = {}
                    if _val then
                        for k, v in pairs(_val) do
                            local c = _cosLib.Cosmetics[k]
                            if c and _isCosType(c) then _prx[k] = v end
                        end
                    end
                    return setmetatable(_prx, {
                        __index = function(t, k)
                            local c = _cosLib.Cosmetics[k]
                            if c and _isCosType(c) then return true end
                            return nil
                        end
                    })
                end
                if key == "FavoritedCosmetics" then
                    local _res = _val and table.clone(_val) or {}
                    for wep, fv in pairs(_favs) do
                        _res[wep] = _res[wep] or {}
                        for nm, isFav in pairs(fv) do
                            local c = _cosLib.Cosmetics[nm]
                            if c and _isCosType(c) then
                                _res[wep][nm] = isFav
                            end
                        end
                    end
                    return _res
                end
                return _val
            end

            if not _datCtrl._origGetWep then
                _datCtrl._origGetWep = _datCtrl.GetWeaponData
            end
            _datCtrl.GetWeaponData = function(self, wn)
                local _d = _datCtrl._origGetWep(self, wn)
                if not _d then return nil end
                local _m = {}
                for k, v in pairs(_d) do _m[k] = v end
                _m.Name = wn
                if _eq[wn] then
                    for ct, cd in pairs(_eq[wn]) do
                        _m[ct] = cd
                    end
                end
                return _m
            end

            local _fightCtrl
            pcall(function()
                _fightCtrl = require(_ctrl:WaitForChild("FighterController", 10))
            end)

            if hookmetamethod then
                local _remotes   = _rs:FindFirstChild("Remotes")
                local _dataRem   = _remotes and _remotes:FindFirstChild("Data")
                local _equipRem  = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
                local _favRem    = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
                local _repRem    = _remotes and _remotes:FindFirstChild("Replication")
                local _fightRem  = _repRem and _repRem:FindFirstChild("Fighter")
                local _useItmRem = _fightRem and _fightRem:FindFirstChild("UseItem")

                if _equipRem then
                    local _onc
                    _onc = hookmetamethod(game, "__namecall", function(self, ...)
                        if getnamecallmethod() ~= "FireServer" then
                            return _onc(self, ...)
                        end
                        local _a = {...}

                        if _useItmRem and self == _useItmRem then
                            local _oid = _a[1]
                            if _fightCtrl then
                                pcall(function()
                                    local _f = _fightCtrl:GetFighter(_lp)
                                    if _f and _f.Items then
                                        for _, itm in pairs(_f.Items) do
                                            if itm:Get("ObjectID") == _oid then
                                                _lastWep = itm.Name
                                                break
                                            end
                                        end
                                    end
                                end)
                            end
                        end

                        if self == _equipRem then
                            local _wn   = _a[1]
                            local _ct   = _a[2]
                            local _cn   = _a[3]
                            local _opts = _a[4] or {}
                            if _cn and _cn ~= "None" and _cn ~= "" then
                                local _inv = _datCtrl:Get("CosmeticInventory")
                                if _inv and rawget(_inv, _cn) then
                                    return _onc(self, ...)
                                end
                            end
                            _eq[_wn] = _eq[_wn] or {}
                            if not _cn or _cn == "None" or _cn == "" then
                                _eq[_wn][_ct] = nil
                                if not next(_eq[_wn]) then _eq[_wn] = nil end
                            else
                                local _cloned = _mkCosmetic(_cn, _ct, {
                                    inverted = _opts.IsInverted,
                                    favoritesOnly = _opts.OnlyUseFavorites
                                })
                                if _cloned then _eq[_wn][_ct] = _cloned end
                            end
                            task.defer(function()
                                pcall(function() _datCtrl.CurrentData:Replicate("WeaponInventory") end)
                            end)
                            _saveCfg()
                            return
                        end

                        if self == _favRem then
                            local _cos = _cosLib.Cosmetics[_a[2]]
                            if _cos then
                                _favs[_a[1]] = _favs[_a[1]] or {}
                                _favs[_a[1]][_a[2]] = _a[3] or nil
                                task.spawn(function()
                                    pcall(function() _datCtrl.CurrentData:Replicate("FavoritedCosmetics") end)
                                end)
                                _saveCfg()
                            end
                            return
                        end

                        return _onc(self, ...)
                    end)
                end
            end

            local _cliItem
            pcall(function()
                _cliItem = require(_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
            end)

            if _cliItem and _cliItem._CreateViewModel then
                local _origCVM = _cliItem._CreateViewModel
                _cliItem._CreateViewModel = function(self, vmRef)
                    local _wn  = self.Name
                    local _wp  = self.ClientFighter and self.ClientFighter.Player
                    _buildingWep = (_wp == _lp) and _wn or nil
                    if _wp == _lp and _eq[_wn] then
                        local _dk = self:ToEnum("Data")
                        if vmRef[_dk] then
                            if _eq[_wn].Skin then
                                vmRef[_dk][self:ToEnum("Skin")] = _eq[_wn].Skin
                                vmRef[_dk][self:ToEnum("Name")] = _eq[_wn].Skin.Name
                            end
                            if _eq[_wn].Charm then vmRef[_dk][self:ToEnum("Charm")] = _eq[_wn].Charm end
                            if _eq[_wn].Wrap  then vmRef[_dk][self:ToEnum("Wrap")]  = _eq[_wn].Wrap  end
                        elseif vmRef.Data then
                            if _eq[_wn].Skin  then vmRef.Data.Skin  = _eq[_wn].Skin; vmRef.Data.Name = _eq[_wn].Skin.Name end
                            if _eq[_wn].Charm then vmRef.Data.Charm = _eq[_wn].Charm end
                            if _eq[_wn].Wrap  then vmRef.Data.Wrap  = _eq[_wn].Wrap  end
                        end
                    end
                    local _r = _origCVM(self, vmRef)
                    _buildingWep = nil
                    return _r
                end
            end

            local _vmMod = _lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
            if _vmMod then
                local _CVM = require(_vmMod)
                local _origNew = _CVM.new
                _CVM.new = function(repData, cliItm)
                    local _wp  = cliItm.ClientFighter and cliItm.ClientFighter.Player
                    local _wn  = _buildingWep or cliItm.Name
                    if _wp == _lp and _eq[_wn] then
                        local _RC  = require(_rs.Modules.ReplicatedClass)
                        local _dk  = _RC:ToEnum("Data")
                        repData[_dk] = repData[_dk] or {}
                        local _cos = _eq[_wn]
                        if _cos.Skin  then repData[_dk][_RC:ToEnum("Skin")]  = _cos.Skin  end
                        if _cos.Charm then repData[_dk][_RC:ToEnum("Charm")] = _cos.Charm end
                        if _cos.Wrap  then repData[_dk][_RC:ToEnum("Wrap")]  = _cos.Wrap  end
                    end
                    return _origNew(repData, cliItm)
                end
            end

            local _unlockedCount = 0
            for _ in pairs(_cosLib.Cosmetics or {}) do
                _unlockedCount = _unlockedCount + 1
            end
            Notify({ Title = "Unlock All", Content = "Unlocked " .. tostring(_unlockedCount) .. " cosmetics!", Duration = 5 })
        else
            if _cosLib._origOwns then
                _cosLib.OwnsCosmetic = _cosLib._origOwns
            end
            if _datCtrl._origGet then
                _datCtrl.Get = _datCtrl._origGet
            end
            if _datCtrl._origGetWep then
                _datCtrl.GetWeaponData = _datCtrl._origGetWep
            end
            Notify({ Title = "Unlock All", Content = "Cosmetics locked", Duration = 3 })
        end
    end)
end)
end })

G.SolunaSkinRuntime.RefreshSkinChangerState()

local InterfaceSection = Tabs.Settings:AddSection("Interface")

InterfaceSection:AddColorpicker("ui_accent", {
    Title = "Accent Colour",
    Description = "Repaints the hub's highlight colour",
    Default = Brand.Accent,
    Callback = function(color) ThemeManager:ApplyToTab(Tabs.Settings) end
})

InterfaceSection:AddButton({
    Title = "Unload Kittylol",
    Description = "Closes the interface for this session",
    Callback = function()
        Notify({ Title = "Kittylol", Content = "Interface closed", Duration = 2 })
        task.delay(0.5, function()
            pcall(function() Library:Unload() end)
        end)
    end
})

task.spawn(function()
    local ok, err = pcall(function()
        SaveManager:BuildConfigSection(Tabs.Settings)
        ThemeManager:ApplyToTab(Tabs.Settings)
        SaveManager:LoadAutoloadConfig()
    end)
    if not ok then
        warn("[Kittylol Config] initialization failed: " .. tostring(err))
    end
end)

local AboutSection = Tabs.About:AddSection("About Kittylol")

AboutSection:AddButton({
    Title = " Join Discord",
    ActionText = "Copy",
    Callback = function()
        local link = "https://discord.gg/tEmMW68zgW"
        pcall(function()
            if setclipboard then
                setclipboard(link)
            elseif toclipboard then
                toclipboard(link)
            end
        end)
        Notify({
            Title = "Discord",
            Content = "Link copied to clipboard!",
            Duration = 3
        })
    end
})

AboutSection:AddLabel("Join the Discord for updates and support!")

local SocialsSection = Tabs.Settings:AddSection("Socials")

SocialsSection:AddButton({
    Title = "Join Discord",
    ActionText = "Copy",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/tEmMW68zgW")
            elseif toclipboard then
                toclipboard("https://discord.gg/tEmMW68zgW")
            end
        end)

        Notify({
            Title = "Kittylol",
            Content = "Invite copied!",
            Duration = 5
        })
    end
})

Runtime.TargetInfoGui = Instance.new("ScreenGui")
Runtime.TargetInfoGui.Name = "AstraTargetInfo"
Runtime.TargetInfoGui.ResetOnSpawn = false
Runtime.TargetInfoGui.Parent = Services.CoreGui

Runtime.TargetInfoFrame = Instance.new("Frame")
Runtime.TargetInfoFrame.Name = "TargetInfo"
Runtime.TargetInfoFrame.Size = UDim2.new(0, 260, 0, 170)
Runtime.TargetInfoFrame.Position = UDim2.new(0.5, 0, 1, -16)
Runtime.TargetInfoFrame.BackgroundColor3 = Color3.fromRGB(23, 25, 29)
Runtime.TargetInfoFrame.BackgroundTransparency = 0.3
Runtime.TargetInfoFrame.BorderSizePixel = 0
Runtime.TargetInfoFrame.Visible = false
Runtime.TargetInfoFrame.AnchorPoint = Vector2.new(0.5, 1)
Runtime.TargetInfoFrame.Parent = Runtime.TargetInfoGui

local TargetInfoCorner = Instance.new("UICorner")
TargetInfoCorner.CornerRadius = UDim.new(0, 6)
TargetInfoCorner.Parent = Runtime.TargetInfoFrame

Runtime.TargetAvatar = Instance.new("ImageLabel")
Runtime.TargetAvatar.Name = "Avatar"
Runtime.TargetAvatar.Size = UDim2.new(0, 50, 0, 50)
Runtime.TargetAvatar.Position = UDim2.new(0, 8, 0, 8)
Runtime.TargetAvatar.BackgroundColor3 = Color3.fromRGB(33, 36, 42)
Runtime.TargetAvatar.BorderSizePixel = 0
Runtime.TargetAvatar.Parent = Runtime.TargetInfoFrame

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(0, 5)
AvatarCorner.Parent = Runtime.TargetAvatar

Runtime.TargetName = Instance.new("TextLabel")
Runtime.TargetName.Name = "TargetName"
Runtime.TargetName.Size = UDim2.new(0, 190, 0, 18)
Runtime.TargetName.Position = UDim2.new(0, 66, 0, 8)
Runtime.TargetName.BackgroundTransparency = 1
Runtime.TargetName.Font = Enum.Font.GothamBold
Runtime.TargetName.Text = "Loading..."
Runtime.TargetName.TextColor3 = Color3.fromRGB(255, 255, 255)
Runtime.TargetName.TextSize = 14
Runtime.TargetName.TextXAlignment = Enum.TextXAlignment.Left
Runtime.TargetName.Parent = Runtime.TargetInfoFrame

local HealthBarBG = Instance.new("Frame")
HealthBarBG.Size = UDim2.new(0, 190, 0, 6)
HealthBarBG.Position = UDim2.new(0, 66, 0, 30)
HealthBarBG.BackgroundColor3 = Color3.fromRGB(33, 36, 42)
HealthBarBG.BackgroundTransparency = 0
HealthBarBG.BorderSizePixel = 0
HealthBarBG.Parent = Runtime.TargetInfoFrame

local HealthBarBGCorner = Instance.new("UICorner")
HealthBarBGCorner.CornerRadius = UDim.new(0, 3)
HealthBarBGCorner.Parent = HealthBarBG

Runtime.HealthBarFill = Instance.new("Frame")
Runtime.HealthBarFill.Name = "Fill"
Runtime.HealthBarFill.Size = UDim2.new(1, 0, 1, 0)
Runtime.HealthBarFill.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
Runtime.HealthBarFill.BorderSizePixel = 0
Runtime.HealthBarFill.Parent = HealthBarBG

local HealthFillCorner = Instance.new("UICorner")
HealthFillCorner.CornerRadius = UDim.new(0, 3)
HealthFillCorner.Parent = Runtime.HealthBarFill

Runtime.HealthText = Instance.new("TextLabel")
Runtime.HealthText.Name = "HealthText"
Runtime.HealthText.Size = UDim2.new(0, 190, 0, 14)
Runtime.HealthText.Position = UDim2.new(0, 66, 0, 38)
Runtime.HealthText.BackgroundTransparency = 1
Runtime.HealthText.Font = Enum.Font.GothamMedium
Runtime.HealthText.Text = "100 / 100 HP"
Runtime.HealthText.TextColor3 = Color3.fromRGB(165, 165, 165)
Runtime.HealthText.TextSize = 10
Runtime.HealthText.TextXAlignment = Enum.TextXAlignment.Left
Runtime.HealthText.Parent = Runtime.TargetInfoFrame

Runtime.DistanceLabel = Instance.new("TextLabel")
Runtime.DistanceLabel.Name = "Distance"
Runtime.DistanceLabel.Size = UDim2.new(0, 190, 0, 14)
Runtime.DistanceLabel.Position = UDim2.new(0, 66, 0, 55)
Runtime.DistanceLabel.BackgroundTransparency = 1
Runtime.DistanceLabel.Font = Enum.Font.Gotham
Runtime.DistanceLabel.Text = "0 studs away"
Runtime.DistanceLabel.TextColor3 = Color3.fromRGB(165, 165, 165)
Runtime.DistanceLabel.TextSize = 10
Runtime.DistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
Runtime.DistanceLabel.Parent = Runtime.TargetInfoFrame

function UpdateTargetInfo(target)
    if not Runtime.TargetInfoFrame then return end
    if not target then
        Runtime.TargetInfoFrame.Visible = false
        Runtime.CurrentTarget = nil
        return
    end
    local character = target.Character
    if not character then
        Runtime.TargetInfoFrame.Visible = false
        Runtime.CurrentTarget = nil
        return
    end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        Runtime.TargetInfoFrame.Visible = false
        Runtime.CurrentTarget = nil
        return
    end
    Runtime.CurrentTarget = target
    Runtime.TargetInfoFrame.Visible = State.ShowTargetInfo
    
    pcall(function()
        Runtime.TargetAvatar.Image = Services.Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        Runtime.TargetName.Text = target.DisplayName
        
        local healthRatio = math.clamp(humanoid.Health / (humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100), 0, 1)
        Runtime.HealthBarFill.Size = UDim2.new(healthRatio, 0, 1, 0)
        Runtime.HealthBarFill.BackgroundColor3 = GetHealthColor(humanoid.Health, humanoid.MaxHealth)
        Runtime.HealthText.Text = string.format("%d / %d HP", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local localCharacter = Config.LocalPlayer.Character
        local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        if rootPart and localRoot then
            local dist = math.floor((rootPart.Position - localRoot.Position).Magnitude)
            Runtime.DistanceLabel.Text = dist .. " studs away"
        end
    end)
end

local FOVCircle = CreateDrawing("Circle")
if FOVCircle then
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 100
    FOVCircle.Radius = 90
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.Color = Color3.fromRGB(0, 150, 255)
    FOVCircle.Transparency = 1
end

local function GetClosestPlayer(ignoreFOV)
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mouseLocation = Services.UserInputService:GetMouseLocation()
    local showFov = Options.show_fov and Options.show_fov.Value or false
    local fovVal = tonumber(Options.fov_slider and Options.fov_slider.Value or 90) or 90
    local fovLimit = (ignoreFOV or not showFov) and math.huge or fovVal
    local distLimit = tonumber(Options.max_distance and Options.max_distance.Value or 1000) or 1000
    local targetPartName = AimbotSettings.TargetPart or "Head"
    local teamCheck = Options.team_check and Options.team_check.Value or false
    local camera = workspace.CurrentCamera or Services.Camera
    if not camera then return nil end
    Services.Camera = camera

    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Config.LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(targetPartName) or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if not targetPart or not humanoid or humanoid.Health <= 0 then continue end

            local dist = (targetPart.Position - camera.CFrame.Position).Magnitude
            if dist > distLimit then continue end
            if teamCheck and IsTeammate(player) then continue end

            local pos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local magnitude = (Vector2.new(pos.X, pos.Y) - mouseLocation).Magnitude
                if magnitude < shortestDistance and magnitude <= fovLimit then
                    if not State.WallCheckEnabled or IsVisible(targetPart, player) then
                        shortestDistance = magnitude
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function IsTargetValid(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local targetPartName = AimbotSettings.TargetPart or "Head"
    local targetPart = player.Character:FindFirstChild(targetPartName) or player.Character:FindFirstChild("Head")
    if not targetPart then return false end

    local camera = workspace.CurrentCamera or Services.Camera
    if not camera then return false end
    Services.Camera = camera

    local distLimit = tonumber(Options.max_distance and Options.max_distance.Value or 1000) or 1000
    if (targetPart.Position - camera.CFrame.Position).Magnitude > distLimit then return false end

    local teamCheck = Options.team_check and Options.team_check.Value or false
    if teamCheck and IsTeammate(player) then return false end
    if State.WallCheckEnabled and not IsVisible(targetPart, player) then return false end
    return true
end

local lastTriggerTime = 0
local lastRenderTime = 0
local lastTargetAcquireTime = 0
local lastTargetValidationTime = 0
local lastTargetInfoTime = 0
local lastChamsUpdateTime = 0
local renderConnection = nil
local aimbotSmoothVelocity = Vector2.new(0, 0)
local lastAimbotTarget = nil

renderConnection = Services.RunService.RenderStepped:Connect(function(deltaTime)
    if not State.IsRunning then return end
    
    local now = tick()
    if now - lastRenderTime < 0.008 then return end
    lastRenderTime = now
    
    local show = Options.show_fov and Options.show_fov.Value or false
    local radius = tonumber(Options.fov_slider and Options.fov_slider.Value or 90) or 90
    local currentCamera = workspace.CurrentCamera
    if currentCamera then Services.Camera = currentCamera end
    local fovCenter = Services.UserInputService:GetMouseLocation()

    if FOVCircle then
        FOVCircle.Visible = show
        if show then
            FOVCircle.Radius = radius
            FOVCircle.Position = fovCenter
            FOVCircle.Filled = FOVFilledValue
            FOVCircle.Transparency = FOVFilledValue and FOVFilledTransparency or 1
        end
    end

    if ChamsSettings.Enabled and (now - lastChamsUpdateTime) >= 0.15 then
        lastChamsUpdateTime = now
        local localChar = Config.LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local players = Services.Players:GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p == Config.LocalPlayer then continue end
            local tag = "hx_" .. p.UserId
            local obj = ChamsTargetContainer:FindFirstChild(tag)
            if not obj then 
                HandleChamsPlayer(p)
                obj = ChamsTargetContainer:FindFirstChild(tag)
            end
            if obj then
                obj.FillColor = ChamsSettings.Color
                obj.OutlineColor = ChamsSettings.OutlineColor
                obj.FillTransparency = ChamsSettings.FillTransparency
                obj.OutlineTransparency = ChamsSettings.OutlineTransparency
                obj.Enabled = true
                
                if not p.Character or (ESPSettings.ESPTeamCheck and IsTeammate(p)) then
                    obj.Enabled = false
                elseif localRoot then
                    local rootPart = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local dist = (rootPart.Position - localRoot.Position).Magnitude
                        obj.Enabled = dist <= ESPSettings.MaxESPDistance
                    else
                        obj.Enabled = false
                    end
                end
            end
        end
    end    local isAiming = Options.aimbot_bind and Options.aimbot_bind:GetState() or false
    if Options.aimbot_enabled and Options.aimbot_enabled.Value and isAiming then
        -- Target scanning and wall-ray validation are throttled; cursor
        -- movement remains on RenderStepped for smooth aiming.
        local target = State.LockedTarget

        if target and (now - lastTargetValidationTime) >= 0.08 then
            lastTargetValidationTime = now
            if not IsTargetValid(target) then
                target = nil
                State.LockedTarget = nil
            end
        end

        if not target and (now - lastTargetAcquireTime) >= 0.05 then
            lastTargetAcquireTime = now
            target = GetClosestPlayer(false)
            State.LockedTarget = target
            lastTargetValidationTime = now
        end

        if target ~= lastAimbotTarget then
            aimbotSmoothVelocity = Vector2.new(0, 0)
            lastAimbotTarget = target
        end

        if now - lastTargetInfoTime >= 0.1 then
            lastTargetInfoTime = now
            UpdateTargetInfo(target)
        end

        if target and target.Character then
            local targetPartName = AimbotSettings.TargetPart or "Head"
            local aimPart = target.Character:FindFirstChild(targetPartName) or target.Character:FindFirstChild("Head")
            if aimPart then
                local worldPos = aimPart.Position
                local pos, onScreen = Services.Camera:WorldToViewportPoint(worldPos)
                if onScreen then
                    local smoothing = tonumber(Options.aimbot_smoothing and Options.aimbot_smoothing.Value or 5) or 5
                    local mouseLocation = Services.UserInputService:GetMouseLocation()
                    local targetPos = Vector2.new(pos.X, pos.Y)
                    local delta = targetPos - mouseLocation
                    
                    local smoothFactor = math.clamp(1 - math.exp(-deltaTime * (60 / math.max(smoothing, 0.1))), 0, 1)
                    aimbotSmoothVelocity = aimbotSmoothVelocity:Lerp(delta, 0.3)
                    local moveDelta = aimbotSmoothVelocity * smoothFactor
                    
                    if mousemoverel and (math.abs(moveDelta.X) > 0.5 or math.abs(moveDelta.Y) > 0.5) then
                        mousemoverel(moveDelta.X, moveDelta.Y)
                    end
                end
            end
        end
    else
        if State.LockedTarget then
            State.LockedTarget = nil
            lastAimbotTarget = nil
            aimbotSmoothVelocity = Vector2.new(0, 0)
            lastTargetAcquireTime = 0
            lastTargetValidationTime = 0
            lastTargetInfoTime = 0
        end
        if State.ShowTargetInfo and now - lastTargetInfoTime >= 0.1 then
            lastTargetInfoTime = now
            local target = GetClosestPlayer(false)
            if target then
                UpdateTargetInfo(target)
            elseif Runtime.CurrentTarget then
                UpdateTargetInfo(nil)
            end
        end
    end

    local isTriggerbotActive = Options.triggerbot_bind and Options.triggerbot_bind:GetState() or false
    if TriggerbotEnabled and isTriggerbotActive and (now - lastTriggerTime) >= 0.05 then
        lastTriggerTime = now
        local closestPlayer = GetClosestPlayer(false)
        if closestPlayer and closestPlayer.Character then
            if not (State.AntiKatanaEnabled and IsEnemyDeflecting(closestPlayer)) then
                local targetPartName = AimbotSettings.TargetPart or "Head"
                local targetPart = closestPlayer.Character:FindFirstChild(targetPartName) or closestPlayer.Character:FindFirstChild("Head")
                if targetPart and IsVisible(targetPart, closestPlayer) then
                    local pos, onScreen = Services.Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local mouseLocation = Services.UserInputService:GetMouseLocation()
                        local dist = (Vector2.new(pos.X, pos.Y) - mouseLocation).Magnitude
                        local currentTime = tick()
                        local triggerDelay = tonumber(TriggerbotDelay) or 0.05
                        if dist <= 25 and mouse1click and (triggerDelay <= 0 or (currentTime - lastTriggerTime) >= triggerDelay) then
                            if triggerDelay > 0 then
                                task.wait(triggerDelay)
                            end
                            mouse1click()
                            lastTriggerTime = tick()
                        end
                    end
                end
            end
        end
    end
end)

for _, v in next, Services.Players:GetPlayers() do
    if v ~= Config.LocalPlayer then
        HandleChamsPlayer(v)
    end
end

Services.Players.PlayerAdded:Connect(function(v)
    if v ~= Config.LocalPlayer then
        HandleChamsPlayer(v)
    end
end)

Services.Players.PlayerRemoving:Connect(function(v)
    local tag = "hx_" .. v.UserId
    local obj = ChamsTargetContainer:FindFirstChild(tag)
    if obj then obj:Destroy() end
end)

Window:SelectTab(1)

Library:OnUnload(function()
    print("[Kittylol] Unloaded")
end)
