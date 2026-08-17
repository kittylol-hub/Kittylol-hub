local G = getgenv()
G.InterfaceName = "Astra Hub"
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
local Brand = {
    Ink        = Color3.fromRGB(8, 9, 12),
    Backdrop   = Color3.fromRGB(11, 12, 16),
    Surface    = Color3.fromRGB(17, 19, 25),
    Raised     = Color3.fromRGB(23, 26, 34),
    Hover      = Color3.fromRGB(31, 35, 45),
    Line       = Color3.fromRGB(38, 43, 55),
    LineSoft   = Color3.fromRGB(29, 33, 43),
    Text       = Color3.fromRGB(237, 240, 248),
    Sub        = Color3.fromRGB(150, 158, 178),
    Muted      = Color3.fromRGB(104, 112, 132),
    Accent     = Color3.fromRGB(228, 30, 74),
    AccentHi   = Color3.fromRGB(255, 74, 112),
    AccentDeep = Color3.fromRGB(126, 14, 42),
}

local function NewInst(class, props, children)
    local inst = Instance.new(class)
    local parent = nil
    for key, value in pairs(props or {}) do
        if key == "Parent" then parent = value else inst[key] = value end
    end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function Corner(parent, radius)
    return NewInst("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function Stroke(parent, color, thickness, transparency)
    return NewInst("UIStroke", {
        Color = color or Brand.Line,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

-- Builds the Astra monogram: a crimson tile holding a bold triangular "A"
-- with three tapered light streaks cut across its strokes.
local function BuildAstraMark(px, flat)
    local unit = px / 200
    local function u(n) return math.floor(n * unit + 0.5) end

    local tile = NewInst("Frame", {
        Name = "AstraMark",
        Size = UDim2.fromOffset(px, px),
        BackgroundColor3 = Color3.fromRGB(126, 13, 39),
        BorderSizePixel = 0,
    })
    Corner(tile, u(46))
    NewInst("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(158, 17, 50)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(120, 12, 37)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 7, 24)),
        }),
        Rotation = 115,
        Parent = tile,
    })
    if not flat then
        Stroke(tile, Color3.fromRGB(255, 108, 140), 1, 0.72)
    end

    -- Design grid for the glyph: 120 wide x 130 tall.
    local glyph = NewInst("Frame", {
        Name = "Glyph",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.52),
        Size = UDim2.fromOffset(u(120), u(130)),
        Parent = tile,
    })

    -- The legs carry the full light-to-dark ramp; the crossbar only spans a
    -- slice of the letter's height, so it gets the matching slice of the ramp
    -- and reads as one continuous surface instead of a brighter patch.
    local function bar(w, h, cx, cy, rot, from, to)
        local f = NewInst("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(u(w), u(h)),
            Position = UDim2.fromOffset(u(cx), u(cy)),
            Rotation = rot,
            BackgroundColor3 = Color3.fromRGB(226, 32, 76),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = glyph,
        })
        Corner(f, math.max(1, u(5)))
        NewInst("UIGradient", {
            Color = ColorSequence.new(
                from or Color3.fromRGB(255, 72, 112),
                to or Color3.fromRGB(186, 18, 56)
            ),
            Rotation = 90,
            Parent = f,
        })
        return f
    end

    -- Two legs meeting at the apex, plus the crossbar low in the counter.
    local leftLeg  = bar(26, 138, 37, 65, 19.5)
    local rightLeg = bar(26, 138, 83, 65, -19.5)
    local crossbar = bar(66, 22, 60, 88, 0,
        Color3.fromRGB(216, 40, 82), Color3.fromRGB(200, 30, 68))

    -- Apex cap hides the mitre joint where the two legs overlap; it matches
    -- the top of the leg gradient so the peak stays one solid colour, and its
    -- upper point overshoots slightly to sharpen the tip.
    local cap = NewInst("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(u(24), u(24)),
        Position = UDim2.fromOffset(u(60), u(11)),
        Rotation = 45,
        BackgroundColor3 = Color3.fromRGB(255, 72, 112),
        BorderSizePixel = 0,
        Parent = glyph,
    })
    Corner(cap, math.max(1, u(5)))

    local streaks = {}
    local function streak(parent, w, h, yScale, rot)
        local s = NewInst("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, u(w), 0, math.max(2, u(h))),
            Position = UDim2.new(0.5, 0, yScale, 0),
            Rotation = rot,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = parent,
        })
        Corner(s, math.max(1, u(3)))
        NewInst("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.28, 0),
                NumberSequenceKeypoint.new(0.72, 0.08),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = s,
        })
        streaks[#streaks + 1] = s
        return s
    end

    -- Clipped inside each stroke, so the light only ever cuts the letter.
    streak(leftLeg, 62, 10, 0.26, -54)
    streak(leftLeg, 54, 9, 0.83, -54)
    streak(rightLeg, 66, 11, 0.52, -16)

    -- Four-point twinkle in the lower-right corner.
    local sparkPos = UDim2.fromScale(0.845, 0.845)
    local spark = NewInst("Frame", {
        Name = "Spark",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = sparkPos,
        Size = UDim2.fromOffset(u(26), u(26)),
        Parent = tile,
    })
    for i = 0, 1 do
        local blade = NewInst("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = i == 0 and UDim2.fromScale(1, 0.24) or UDim2.fromScale(0.24, 1),
            BackgroundColor3 = Color3.fromRGB(255, 226, 232),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Parent = spark,
        })
        NewInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = blade })
    end

    return tile, { streaks = streaks, spark = spark, glyph = glyph, cap = cap }
end

--==========================================================================
--  ASTRA HUB · BOOT SEQUENCE
--  Splash lands first, the Discord invite fires alongside it, and the hub
--  window is only revealed once the splash has played out.
--==========================================================================
local AstraIntro = {}
do
    local TS = Services.TweenService
    local DISCORD_INVITE = "https://discord.gg/tEmMW68zgW"
    local DISCORD_CODE = "tEmMW68zgW"
    local MIN_DURATION = 3.4

    local gui, card, fill, statusLabel, glowRing
    local startedAt = 0
    local progress = 0
    local closed = false
    local ease = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local function protect(instance)
        pcall(function()
            if syn and syn.protect_gui then syn.protect_gui(instance) end
        end)
    end

    function AstraIntro:SetStatus(text, pct)
        if not gui then return end
        if text and statusLabel then statusLabel.Text = text end
        if pct then
            progress = math.clamp(pct, progress, 1)
            if fill then
                TS:Create(fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromScale(progress, 1),
                }):Play()
            end
        end
    end

    -- Discord's local RPC bridge: pops the native "join server" prompt.
    -- Falls back to putting the invite on the clipboard when unavailable.
    local function OpenDiscordInvite()
        local http = Services.HttpService
        local requestFn = (syn and syn.request)
            or (http and http.request)
            or http_request
            or (fluxus and fluxus.request)
            or request

        local delivered = false
        if type(requestFn) == "function" then
            local body = http:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = { code = DISCORD_CODE },
                nonce = http:GenerateGUID(false),
            })
            for port = 6463, 6472 do
                local ok, response = pcall(requestFn, {
                    Url = ("http://127.0.0.1:%d/rpc?v=1"):format(port),
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["Origin"] = "https://discord.com",
                    },
                    Body = body,
                })
                if ok and response and (response.StatusCode == 200 or response.Success) then
                    delivered = true
                    break
                end
            end
        end

        pcall(function()
            if setclipboard then setclipboard(DISCORD_INVITE)
            elseif toclipboard then toclipboard(DISCORD_INVITE) end
        end)

        return delivered
    end

    function -- Astra intro UI removed; Obsidian is the only interface.
        if gui then return end
        startedAt = os.clock()

        gui = NewInst("ScreenGui", {
            Name = "AstraBoot",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 9999,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        protect(gui)
        gui.Parent = Services.CoreGui

        local backdrop = NewInst("Frame", {
            Name = "Backdrop",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Brand.Ink,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = gui,
        })
        NewInst("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(26, 6, 13), Color3.fromRGB(6, 7, 10)),
            Rotation = 90,
            Parent = backdrop,
        })
        TS:Create(backdrop, TweenInfo.new(0.35), { BackgroundTransparency = 0.06 }):Play()

        card = NewInst("Frame", {
            Name = "Card",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.52),
            Size = UDim2.fromOffset(430, 372),
            BackgroundColor3 = Brand.Surface,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = gui,
        })
        Corner(card, 20)
        local cardStroke = Stroke(card, Brand.Line, 1, 1)
        NewInst("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(24, 27, 35), Color3.fromRGB(14, 15, 20)),
            Rotation = 90,
            Parent = card,
        })

        -- Soft crimson bloom behind the logo.
        glowRing = NewInst("Frame", {
            Name = "Glow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 108),
            Size = UDim2.fromOffset(210, 210),
            Rotation = 0,
            BackgroundColor3 = Brand.Accent,
            BackgroundTransparency = 0.86,
            BorderSizePixel = 0,
            Parent = card,
        })
        Corner(glowRing, 62)
        NewInst("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(0.5, 0.85),
                NumberSequenceKeypoint.new(1, 0.2),
            }),
            Rotation = 45,
            Parent = glowRing,
        })

        local mark, markParts = BuildAstraMark(112)
        mark.AnchorPoint = Vector2.new(0.5, 0.5)
        mark.Position = UDim2.new(0.5, 0, 0, 108)
        mark.Parent = card

        local markHolder = mark
        markHolder.Rotation = -8

        local title = NewInst("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 188),
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.GothamBold,
            Text = "Thanks for using our script!",
            TextColor3 = Brand.Text,
            TextSize = 21,
            TextTransparency = 1,
            Parent = card,
        })

        local subtitle = NewInst("TextLabel", {
            Name = "Subtitle",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 218),
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.Gotham,
            Text = ("ASTRA HUB  ·  %s"):format(string.upper(Config.GameName or "RIVALS")),
            TextColor3 = Brand.Sub,
            TextSize = 12,
            TextTransparency = 1,
            Parent = card,
        })

        local greeting = NewInst("TextLabel", {
            Name = "Greeting",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 244),
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.Gotham,
            Text = ("Welcome back, %s"):format(Config.PlayerName or "player"),
            TextColor3 = Brand.Muted,
            TextSize = 12,
            TextTransparency = 1,
            Parent = card,
        })

        local track = NewInst("Frame", {
            Name = "Track",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 288),
            Size = UDim2.fromOffset(310, 5),
            BackgroundColor3 = Brand.Raised,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = card,
        })
        Corner(track, 3)

        fill = NewInst("Frame", {
            Name = "Fill",
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = Brand.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = track,
        })
        Corner(fill, 3)
        NewInst("UIGradient", {
            Color = ColorSequence.new(Brand.AccentDeep, Brand.AccentHi),
            Parent = fill,
        })

        statusLabel = NewInst("TextLabel", {
            Name = "Status",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 306),
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.Gotham,
            Text = "Preparing runtime...",
            TextColor3 = Brand.Muted,
            TextSize = 11,
            TextTransparency = 1,
            Parent = card,
        })

        local footer = NewInst("TextLabel", {
            Name = "Footer",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 1, -34),
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.Gotham,
            Text = "discord.gg/tEmMW68zgW",
            TextColor3 = Brand.Sub,
            TextSize = 11,
            TextTransparency = 1,
            Parent = card,
        })

        -- Entrance.
        card.Size = UDim2.fromOffset(430, 340)
        TS:Create(card, ease, {
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(430, 372),
            Position = UDim2.fromScale(0.5, 0.5),
        }):Play()
        TS:Create(cardStroke, ease, { Transparency = 0.35 }):Play()
        TS:Create(markHolder, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
        TS:Create(track, ease, { BackgroundTransparency = 0 }):Play()
        TS:Create(fill, ease, { BackgroundTransparency = 0 }):Play()

        for index, label in ipairs({ title, subtitle, greeting, statusLabel, footer }) do
            task.delay(0.12 + index * 0.07, function()
                if label and label.Parent then
                    TS:Create(label, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
                end
            end)
        end

        -- Idle motion: breathing bloom, twinkling spark, sweeping streaks.
        task.spawn(function()
            while gui and not closed do
                TS:Create(glowRing, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Rotation = glowRing.Rotation + 180,
                    BackgroundTransparency = 0.93,
                }):Play()
                task.wait(1.6)
                if not gui or closed then break end
                TS:Create(glowRing, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Rotation = glowRing.Rotation + 180,
                    BackgroundTransparency = 0.84,
                }):Play()
                task.wait(1.6)
            end
        end)

        task.spawn(function()
            while gui and not closed do
                for _, streakFrame in ipairs(markParts.streaks) do
                    if streakFrame and streakFrame.Parent then
                        TS:Create(streakFrame, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                            BackgroundTransparency = 0.45,
                        }):Play()
                    end
                end
                task.wait(0.95)
                if not gui or closed then break end
                for _, streakFrame in ipairs(markParts.streaks) do
                    if streakFrame and streakFrame.Parent then
                        TS:Create(streakFrame, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                            BackgroundTransparency = 0,
                        }):Play()
                    end
                end
                task.wait(0.95)
            end
        end)

        task.spawn(function()
            while gui and not closed do
                TS:Create(markParts.spark, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Rotation = 90 }):Play()
                task.wait(1.5)
                if not gui or closed then break end
                TS:Create(markParts.spark, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Rotation = 0 }):Play()
                task.wait(1.5)
            end
        end)

        -- Discord invite, fired the moment the splash is up.
        task.spawn(function()
            task.wait(0.5)
            AstraIntro:SetStatus("Opening Discord invite...", 0.3)
            local delivered = OpenDiscordInvite()
            AstraIntro:SetStatus(delivered and "Discord invite opened" or "Invite copied to clipboard", 0.55)
            task.wait(0.7)
            AstraIntro:SetStatus("Building interface...", 0.72)
        end)

        -- Safety net: never leave the splash stuck if a later stage throws.
        task.delay(25, function()
            if not closed then AstraIntro:Finish() end
        end)
    end

    function AstraIntro:Finish(onDone)
        if closed then
            if onDone then task.spawn(onDone) end
            return
        end
        closed = true

        task.spawn(function()
            local remaining = MIN_DURATION - (os.clock() - startedAt)
            if remaining > 0 then task.wait(remaining) end

            if fill then
                TS:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromScale(1, 1),
                }):Play()
            end
            if statusLabel then statusLabel.Text = "Ready" end
            task.wait(0.4)

            if gui then
                for _, descendant in ipairs(gui:GetDescendants()) do
                    pcall(function()
                        if descendant:IsA("GuiObject") then
                            TS:Create(descendant, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
                        end
                        if descendant:IsA("TextLabel") then
                            TS:Create(descendant, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
                        end
                        if descendant:IsA("UIStroke") then
                            TS:Create(descendant, TweenInfo.new(0.3), { Transparency = 1 }):Play()
                        end
                    end)
                end
                if card then
                    TS:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                        Size = UDim2.fromOffset(430, 340),
                        BackgroundTransparency = 1,
                    }):Play()
                end
            end

            if onDone then task.spawn(onDone) end
            task.wait(0.4)
            if gui then gui:Destroy() end
            gui = nil
        end)
    end
end

-- Astra intro UI removed; Obsidian is the only interface.

local State = {
    SolunaState = G.SolunaState or {},
    ESPCache = {},
    HighlightCache = {},
    ViewportChamsCache = {},
    rpcShown = false,
    AntiKatanaEnabled = false,
    AntiKatanaHooked = false,
    OriginalEquippedItemInput = nil,
    SilentAimEnabled = false,
    SilentAimHitchance = 100,
    SilentAimHooked = false,
    WallCheckEnabled = true,
    WallBangEnabled = false,
    Aiming = false,
    LockedTarget = nil,
    SlideSpeed = 1,
    SlideDuration = 1,
    SlideEnabled = false,
    WalkSpeedEnabled = false,
    WalkSpeedValue = 50,
    InfiniteJump = false,
    RequireBlocked = ExecutorNameLower == "xeno" or ExecutorNameLower == "solara",
    IsRunning = true,
    RenderTick = 0,
    LastESPUpdate = 0,
    ESPUpdateInterval = 0.1,
    Initialized = false,
    ShowTargetInfo = false,
    PlayerCache = {},
    PlayerCacheTime = 0,
    ChamsEnabled = false
}

local requireCache = {}
local function RequireModule(moduleScript)
    if not moduleScript then return nil end
    if State.RequireBlocked then return nil end
    
    local path = tostring(moduleScript)
    if requireCache[path] ~= nil then
        return requireCache[path]
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        requireCache[path] = result
        return result
    end
    
    requireCache[path] = false
    return nil
end

local function GetFighterController() return RequireModule(Config.LocalPlayer.PlayerScripts.Controllers.FighterController) end
local function GetMechanicsController() return RequireModule(Config.LocalPlayer.PlayerScripts.Controllers.MechanicsController) end
local function GetItemLibrary() return RequireModule(Services.ReplicatedStorage.Modules.ItemLibrary) end
local function GetUtilityLibrary() return RequireModule(Services.ReplicatedStorage.Modules.Utility) end
local function GetGameplayUtility() return RequireModule(Services.ReplicatedStorage.Modules.GameplayUtility) end
local function GetDuelController() return RequireModule(Config.LocalPlayer.PlayerScripts.Controllers.DuelController) end
local function GetCameraController() return RequireModule(Config.LocalPlayer.PlayerScripts.Controllers.CameraController) end
local function GetCosmeticLibrary() return RequireModule(Services.ReplicatedStorage.Modules.CosmeticLibrary) end
local function GetClientViewModelModule(moduleScript) return RequireModule(moduleScript or Config.LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ClientViewModel) end
local function GetEnumLibrary() return RequireModule(Services.ReplicatedStorage.Modules.EnumLibrary) end
local function GetSoundLibrary() return RequireModule(Services.ReplicatedStorage.Modules.SoundLibrary) end
local function GetTracerEffect() return RequireModule(Config.LocalPlayer.PlayerScripts.Modules.TracerEffect) end
local function GetGunModule() return RequireModule(Config.LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end

local ChamsSettings = {
    Enabled = false,
    Color = Color3.fromRGB(50, 150, 255),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    FillTransparency = 0.45,
    OutlineTransparency = 0,
}

local function HandleChamsPlayer(v)
    local function InjectChams(char)
        if not char then return end
        local tag = "hx_" .. v.UserId
        local h = ChamsTargetContainer:FindFirstChild(tag) or Instance.new("Highlight")
        h.Name = tag
        h.Adornee = char
        h.FillColor = ChamsSettings.Color
        h.OutlineColor = ChamsSettings.OutlineColor
        h.FillTransparency = ChamsSettings.FillTransparency
        h.OutlineTransparency = ChamsSettings.OutlineTransparency
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = ChamsTargetContainer
        h.Enabled = false
    end
    v.CharacterAdded:Connect(InjectChams)
    if v.Character then InjectChams(v.Character) end
end

local function CreateDrawing(type)
    local success, drawing = pcall(function()
        return Drawing.new(type)
    end)
    if success and drawing then
        return drawing
    end
    return nil
end

local ESPSettings = {
    ESPTeamCheck = true,
    MaxESPDistance = 2000,
}

local function GetHealthColor(health, maxHealth)
    local ratio = math.clamp(health / maxHealth, 0, 1)
    if ratio > 0.6 then
        return Color3.fromRGB(0, 255, 0)
    elseif ratio > 0.3 then
        return Color3.fromRGB(255, 255, 0)
    else
        return Color3.fromRGB(255, 0, 0)
    end
end

local function IsTeammate(player)
    if player.Team and Config.LocalPlayer.Team and player.Team == Config.LocalPlayer.Team then return true end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("TeammateLabel") then return true end
    return false
end

local DeflectingPlayers = {}

local function IsEnemyDeflecting(player)
    if not State.AntiKatanaEnabled then return false end
    if DeflectingPlayers[player] and tick() < DeflectingPlayers[player] then return true end

    local character = player.Character
    if not character then return false end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local deflectAttachment = rootPart:FindFirstChild("_katana_deflect_active_not_local")
    if deflectAttachment then
        for _, emitter in ipairs(deflectAttachment:GetChildren()) do
            if emitter:IsA("ParticleEmitter") and emitter.Enabled then return true end
        end
    end

    return false
end

local function IsAnyVisibleEnemyDeflecting()
    if not State.AntiKatanaEnabled then return false end
    local localChar = Config.LocalPlayer.Character
    if not localChar then return false end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end
    local camera = Services.Camera
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Config.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                if rootPart:FindFirstChild("TeammateLabel") then continue end
                if IsEnemyDeflecting(player) then
                    local screenPos, onScreen = camera:WorldToScreenPoint(rootPart.Position)
                    if onScreen then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {localChar}
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local result = workspace:Raycast(localRoot.Position, (rootPart.Position - localRoot.Position).Unit * 500, rayParams)
                        if result and result.Instance and result.Instance:IsDescendantOf(player.Character) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function SetupAntiKatanaHook()
    if State.RequireBlocked or State.AntiKatanaHooked then return end
    
    pcall(function()
        local ItemLibrary = GetItemLibrary()
        if not ItemLibrary then return end
        
        local KatanaItems = {}
        if ItemLibrary.Items then
            for itemName, itemData in pairs(ItemLibrary.Items) do
                if itemData and itemData.DeflectDuration then
                    KatanaItems[itemName] = itemData.DeflectDuration
                end
            end
        end

        local fc = GetFighterController()
        if not fc then return end
        
        State.AntiKatanaHooked = true
    end)
end

local function IsVisible(targetPart, targetPlayer)
    local character = Config.LocalPlayer.Character
    if not character then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character, Services.Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local origin = Services.Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil or result.Instance:IsDescendantOf(targetPlayer.Character)
end

local function IsTargetValidAimbot(player)
    if not player or player == Config.LocalPlayer then return false end
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if ESPSettings.ESPTeamCheck and IsTeammate(player) then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("TeammateLabel") then return false end
    if IsEnemyDeflecting(player) then return false end
    return true
end

local AimbotSettings = { TargetPart = "Head", Smoothing = 5, MaxDistance = 1000 }
local TargetBodyParts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftFoot", "RightFoot"}

local function GetSilentAimTarget()
    local localChar = Config.LocalPlayer.Character
    if not localChar then return nil, nil end
    local mousePos = Services.UserInputService:GetMouseLocation()
    local targetPartName = AimbotSettings.TargetPart or "Head"
    local closestPart = nil
    local closestPlayer = nil
    local minDist = math.huge
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if IsTargetValidAimbot(player) then
            local targetPart = player.Character:FindFirstChild(targetPartName) or player.Character:FindFirstChild("Head")
            if targetPart then
                local screenPos, onScreen = Services.Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    if not State.WallBangEnabled and State.WallCheckEnabled and not IsVisible(targetPart, player) then 
                        continue 
                    end
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    local fovVal = Options.fov_slider and Options.fov_slider.Value or 90
                    if dist < fovVal and dist < minDist then
                        minDist = dist
                        closestPart = targetPart
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPart, closestPlayer
end

local function GetValidPlayers()
    local now = tick()
    if now - State.PlayerCacheTime < 0.1 then
        return State.PlayerCache
    end
    State.PlayerCacheTime = now
    local players = Services.Players:GetPlayers()
    State.PlayerCache = players
    return players
end

local SetupSilentAimHook = function()
    if State.RequireBlocked or State.SilentAimHooked then return end
    
    pcall(function()
        local Utility = GetUtilityLibrary()
        if not Utility then return end
        
        local oldRaycast = Utility.Raycast
        Utility.Raycast = function(self, origin, target, distance, whitelist, filterType)
            if not checkcaller() and State.SilentAimEnabled then
                local targetPart, targetPlayer = GetSilentAimTarget()
                if targetPart and math.random(1, 100) <= State.SilentAimHitchance then
                    target = targetPart.Position
                end
            end
            return oldRaycast(self, origin, target, distance, whitelist, filterType)
        end
        
        State.SilentAimHooked = true
    end)
end

local function ApplySilentAimEnabled(Value)
    State.SilentAimEnabled = Value
    if State.RequireBlocked then
        if Value then
            if not Runtime.ExternalSilentAimLoaded then
                task.spawn(function()
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/EndOverdosing/Soluna-API/refs/heads/main/rivals-modern/silent-aim.lua", true))()
                    end)
                    Runtime.ExternalSilentAimLoaded = true
                    if not Runtime.ExternalSilentAimConnection then
                        Runtime.ExternalSilentAimConnection = Services.RunService.Heartbeat:Connect(function()
                            getgenv().SilentAimEnabled = State.SilentAimEnabled
                        end)
                    end
                    getgenv().SilentAimEnabled = true
                    Notify({ Title = "Silent Aim", Content = "Silent Aim Enabled", Duration = 3 })
                end)
            else
                getgenv().SilentAimEnabled = true
                Notify({ Title = "Silent Aim", Content = "Silent Aim Enabled", Duration = 3 })
            end
        else
            getgenv().SilentAimEnabled = false
        end
        return
    end
    if Value then
        SetupSilentAimHook()
        Notify({ Title = "Silent Aim", Content = "Silent Aim Enabled", Duration = 3 })
    end
end

local __a1b2c3 = setmetatable({}, {
    __index = function(__d4e5f6, __g7h8i9)
        local __j0k1l2, __m3n4o5 = pcall(function()
            return game:GetService(__g7h8i9)
        end)
        if __m3n4o5 then
            return cloneref(__m3n4o5)
        end
        return nil
    end
})

local __p6q7r8 = getgenv()
if __p6q7r8.__s9t0u1 then
    __p6q7r8.__s9t0u1:Shutdown()
end

local __v2w3x4 = __a1b2c3.Players
local __y5z6a7 = __a1b2c3.RunService
local __b8c9d0 = __a1b2c3.ReplicatedStorage
local __e1f2g3 = __a1b2c3.Workspace
local __h4i5j6 = __a1b2c3.UserInputService
local __k7l8m9 = __v2w3x4.LocalPlayer
local __n0o1p2 = __e1f2g3.CurrentCamera
local __q3r4s5 = __k7l8m9.PlayerScripts
local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
local __w9x0y1 = require(__b8c9d0.Modules.Utility)

local __z2a3b4 = setmetatable({}, {
    __index = function(_, __c5d6e7)
        local __f8g9h0 = __k7l8m9.Character
        if not __f8g9h0 then return nil end
        if __c5d6e7 == "__root" then
            return __f8g9h0:FindFirstChild("HumanoidRootPart")
        elseif __c5d6e7 == "__head" then
            return __f8g9h0:FindFirstChild("Head")
        end
        return nil
    end
})

__p6q7r8.__s9t0u1 = {}

do
    local __i1j2k3 = __p6q7r8.__s9t0u1

    function __i1j2k3:__init()
        self.__active = false
        self.__target = nil
        self.__desync = false
        self.__conn1 = nil
        self.__conn2 = nil
        self.__task1 = nil
        self.__oldfunc = nil
        self.__setup_done = false
    end

    function __i1j2k3:__setup()
        if self.__setup_done then return end
        self.__setup_done = true
        
        self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__active then return end
            self.__target = self:__find()
        end)

        local __l4m5n6 = __t6u7v8.StartShooting
        self.__oldfunc = __l4m5n6
        __t6u7v8.StartShooting = function(__o7p8q9, ...)
            local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
            if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                return unpack(__r0s1t2)
            end

            local __u3v4w5 = __r0s1t2[3]
            if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                return unpack(__r0s1t2)
            end

            __r0s1t2[4] = true
            local __x6y7z8 = self.__target

            if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                return unpack(__r0s1t2)
            end

            if not self.__desync or self.__curr ~= __x6y7z8 then
                self:__desync_start(__x6y7z8)
                task.wait(0.1)
            end

            if self.__task1 then
                task.cancel(self.__task1)
                self.__task1 = nil
            end

            local __a9b0c1 = __x6y7z8.Character:FindFirstChild("Head")
            if not __a9b0c1 then return unpack(__r0s1t2) end

            local __d2e3f4 = __a9b0c1.Position
            local __g5h6i7 = __a9b0c1.CFrame
            local __j8k9l0 = __d2e3f4 - Vector3.new(0, 5, 0)
            local __m1n2o3 = CFrame.lookAt(__j8k9l0, __d2e3f4)
            local __p4q5r6 = __g5h6i7:ToObjectSpace(CFrame.new(__d2e3f4 + Vector3.new(math.random(), math.random(), math.random())))

            __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(__j8k9l0, __d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
            __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(__d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
            __u3v4w5[utf8.char(2)] = __a9b0c1
            __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(__p4q5r6)

            self.__task1 = task.delay(0.15, function()
                self:__desync_stop()
            end)

            return unpack(__r0s1t2)
        end
    end

    function __i1j2k3:__find()
        local myChar = __k7l8m9.Character
        if not myChar then return nil end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
       
        local closest = nil
        local closestDist = math.huge
        local MAX_DISTANCE = 200

        local gameMode = __b8c9d0:FindFirstChild("GameMode")
        local isFFA = gameMode and gameMode.Value == "FFA"
        
        local myTeamID = __k7l8m9:GetAttribute("TeamID")
        
        local players = __v2w3x4:GetPlayers()
        for i = 1, #players do
            local player = players[i]
            if player == __k7l8m9 then continue end
            
            local char = player.Character
            if not char then continue end

            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            
            if not (root and head and hum and hum.Health > 0) then continue end
            
            local playerTeamID = player:GetAttribute("TeamID")
            
            if not isFFA then
                if myTeamID and playerTeamID and myTeamID == playerTeamID then
                    continue
                end
            end
           
            local dist = (myRoot.Position - root.Position).Magnitude
            
            if dist > MAX_DISTANCE then continue end
            
            if dist < closestDist then
                closestDist = dist
                closest = player
            end
        end
        
        return closest
    end

    function __i1j2k3:__desync_start(__c3d4e5)
        if self.__conn2 then self.__conn2:Disconnect() end
        self.__desync = true
        self.__curr = __c3d4e5

        self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__desync then return end
            local __f6g7h8 = __z2a3b4.__root
            if not __f6g7h8 then return end

            local __i9j0k1 = __c3d4e5.Character and __c3d4e5.Character:FindFirstChild("HumanoidRootPart")
            if not __i9j0k1 then
                self:__desync_stop()
                return
            end

            local __l2m3n4 = __f6g7h8.CFrame
            local __o5p6q7 = __f6g7h8.Velocity
            local __r8s9t0 = __f6g7h8.RotVelocity

            __f6g7h8.CFrame = __i9j0k1.CFrame * CFrame.new(0, -5, 0)

            __y5z6a7:BindToRenderStep("__restore", 101, function()
                __f6g7h8.CFrame = __l2m3n4
                __f6g7h8.Velocity = __o5p6q7
                __f6g7h8.RotVelocity = __r8s9t0
                __y5z6a7:UnbindFromRenderStep("__restore")
            end)
        end)
    end

    function __i1j2k3:__desync_stop()
        self.__desync = false
        self.__curr = nil
        if self.__conn2 then
            self.__conn2:Disconnect()
            self.__conn2 = nil
        end
    end

    function __i1j2k3:Shutdown()
        self.__active = false
        if self.__conn1 then self.__conn1:Disconnect() end
        if self.__conn2 then self.__conn2:Disconnect() end
        if self.__task1 then task.cancel(self.__task1) end
        if self.__oldfunc then
            __t6u7v8.StartShooting = self.__oldfunc
        end
        self.__setup_done = false
    end

    function __i1j2k3:Enable()
        if not self.__setup_done then
            self:__setup()
        end
        self.__active = true
    end

    function __i1j2k3:Disable()
        self.__active = false
    end

    __i1j2k3:__init()
end

--==========================================================================
--  ASTRA UI  ·  self-contained dark interface library
--  Written to be a drop-in replacement for the Fluent API this hub was


-- ======================================================================
-- Kittylol / Obsidian Combat UI
-- ======================================================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kittylol-hub/Kittylol/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/kittylol-hub/Kittylol-hub/refs/heads/main/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Kittylol",
    Footer = "v1.0",
    Icon = 121663636062758,
    CornerElements = false,
    NotifySide = "Right",
    ShowCustomCursor = true,
    Size = UDim2.fromOffset(720, 600),
})

Options = Library.Options
Notify = function(data)
    pcall(function()
        Library:Notify({
            Title = data.Title,
            Description = data.Content,
            Time = data.Duration or 3,
        })
    end)
end

NotifyUnsupportedFeature = function(featureName)
    Notify({Title = featureName, Content = "Your executor doesn't support this feature", Duration = 3})
end

local CombatTab = Window:AddTab("Combat", "swords")

local AimbotSection = CombatTab:AddLeftGroupbox("Aimbot")
AimbotSection:AddToggle("aimbot_enabled", { Text = "Enabled", Default = false })
AimbotSection:AddDropdown("aim_mode", { Text = "Aim Mode", Values = {"Mouse"}, Default = "Mouse", Multi = false })
AimbotSection:AddSlider("max_distance", { Text = "Max Distance", Default = 1000, Min = 0, Max = 5000, Rounding = 0 })
AimbotSection:AddSlider("aimbot_smoothing", { Text = "Smoothing", Default = 5, Min = 1, Max = 50, Rounding = 1 })
AimbotSection:AddDropdown("aim_target", { Text = "Target Part", Values = TargetBodyParts, Default = "Head", Multi = false, Callback = function(v) AimbotSettings.TargetPart = v end })
AimbotSection:AddKeybind("aimbot_bind", { Text = "Aim Key", Mode = "Hold", Default = "MouseRight", Callback = function(Value)
    State.Aiming = Value
    if not Value then State.LockedTarget = nil end
end })

local SilentAimSection = CombatTab:AddRightGroupbox("Silent Aim")
local SilentAimToggle = SilentAimSection:AddToggle("silent_aim_enabled", { Text = "Enabled", Default = false })
SilentAimToggle:OnChanged(function()
    local v = Options.silent_aim_enabled.Value
    ApplySilentAimEnabled(v)
    if v then
        Notify({Title = "Silent Aim", Content = "Silent Aim Enabled", Duration = 3})
    end
end)
SilentAimSection:AddSlider("silent_aim_hitchance", { Text = "Hitchance", Default = 100, Min = 1, Max = 100, Rounding = 0, Callback = function(v) State.SilentAimHitchance = v end })
SilentAimSection:AddDropdown("silent_aim_target", { Text = "Target Part", Values = TargetBodyParts, Default = "Head", Multi = false, Callback = function(v) AimbotSettings.TargetPart = v end })
local wallBang = __p6q7r8.__s9t0u1
SilentAimSection:AddToggle("wall_bang_enabled", { Text = "Wall Bang", Default = false, Callback = function(v)
    State.WallBangEnabled = v
    if v and State.SilentAimEnabled then
        pcall(function() wallBang:Enable() end)
        Notify({Title = "Wall Bang", Content = "Wall Bang activated", Duration = 3})
    else
        pcall(function() wallBang:Disable() end)
        if v and not State.SilentAimEnabled then Notify({Title = "Wall Bang", Content = "Enable Silent Aim first", Duration = 3}) end
    end
end })

local ChecksSection = CombatTab:AddLeftGroupbox("Aimbot Checks")
ChecksSection:AddToggle("team_check", { Text = "Team Check", Default = true })
ChecksSection:AddToggle("wall_check", { Text = "Wall Check", Default = true, Callback = function(v) State.WallCheckEnabled = v end })
ChecksSection:AddToggle("show_fov", { Text = "Show FOV", Default = false })
ChecksSection:AddSlider("fov_slider", { Text = "Field of View", Default = 90, Min = 0, Max = 1000, Rounding = 0 })
local FOVFilledValue = false
local FOVFilledTransparency = 0.8
ChecksSection:AddToggle("fov_filled", { Text = "FOV Filled", Default = false, Callback = function(v) FOVFilledValue = v end })
ChecksSection:AddSlider("fov_fill_opacity", { Text = "FOV Fill Opacity", Default = 0.8, Min = 0, Max = 1, Rounding = 2, Callback = function(v) FOVFilledTransparency = v end })

local TriggerbotSection = CombatTab:AddRightGroupbox("Triggerbot")
local TriggerbotEnabled = false
local TriggerbotDelay = 0.05
TriggerbotSection:AddToggle("triggerbot_enabled", { Text = "Enabled", Default = false, Callback = function(v) TriggerbotEnabled = v end })
TriggerbotSection:AddKeybind("triggerbot_bind", { Text = "Hold Key", Mode = "Hold", Default = "MouseRight", Callback = function(Value) State.TriggerbotActive = Value end })
TriggerbotSection:AddSlider("triggerbot_delay", { Text = "Delay", Default = 0.05, Min = 0, Max = 0.5, Rounding = 2, Callback = function(v) TriggerbotDelay = v end })

local OrbitSection = CombatTab:AddLeftGroupbox("Orbit")
local OrbitEnabled = false
local OrbitSpeed = 1
local OrbitDistance = 5
local OrbitHeight = 3
local OrbitRunning = false
local OrbitAngle = 0
local OrbitTargetMode = "Closest Enemy"
local OrbitAutoShoot = false
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
OrbitSection:AddToggle("orbit_enabled", { Text = "Enabled", Default = false, Callback = function(v)
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


local AntiKatanaSection = CombatTab:AddRightGroupbox("Anti-Katana")
local AntiKatanaToggle = AntiKatanaSection:AddToggle("anti_katana", { Text = "Enabled", Default = false })
AntiKatanaToggle:OnChanged(function()
    local v = Options.anti_katana.Value
    State.AntiKatanaEnabled = v
    if v and State.RequireBlocked then
        State.AntiKatanaEnabled = false
        NotifyUnsupportedFeature("Anti-Katana")
        AntiKatanaToggle:SetValue(false)
        return
    end
    task.defer(function()
        if v then
            SetupAntiKatanaHook()
            pcall(function()
                local mc = GetMechanicsController()
                if mc and not State.OriginalEquippedItemInput then
                    State.OriginalEquippedItemInput = mc.EquippedItemInput
                    mc.EquippedItemInput = function(self, inputName, ...)
                        if State.AntiKatanaEnabled and (inputName == "StartShooting" or inputName == "FinishShooting") and IsAnyVisibleEnemyDeflecting() then
                            return
                        end
                        return State.OriginalEquippedItemInput(self, inputName, ...)
                    end
                end
            end)
            Notify({Title = "Anti-Katana Enabled", Content = "Shots blocked when enemies deflect", Duration = 3})
        else
            pcall(function()
                local mc = GetMechanicsController()
                if mc and State.OriginalEquippedItemInput then
                    mc.EquippedItemInput = State.OriginalEquippedItemInput
                    State.OriginalEquippedItemInput = nil
                end
            end)
            Notify({Title = "Anti-Katana Disabled", Content = "Normal shooting restored", Duration = 3})
        end
    end)
end)

local StatusSection = CombatTab:AddRightGroupbox("Status")
StatusSection:AddLabel("Combat functions extracted from the original hub.")

-- Target/FOV runtime used by the original combat logic.
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
            if targetPart and humanoid and humanoid.Health > 0 then
                local dist = (targetPart.Position - camera.CFrame.Position).Magnitude
                if dist <= distLimit and (not teamCheck or not IsTeammate(player)) then
                    local pos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local magnitude = (Vector2.new(pos.X, pos.Y) - mouseLocation).Magnitude
                        if magnitude < shortestDistance and magnitude <= fovLimit and (not State.WallCheckEnabled or IsVisible(targetPart, player)) then
                            shortestDistance = magnitude
                            closestPlayer = player
                        end
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
    if Options.team_check and Options.team_check.Value and IsTeammate(player) then return false end
    if State.WallCheckEnabled and not IsVisible(targetPart, player) then return false end
    return true
end

local lastTriggerTime = 0
local lastRenderTime = 0
local lastTargetAcquireTime = 0
local lastTargetValidationTime = 0
local aimbotSmoothVelocity = Vector2.new(0, 0)
local lastAimbotTarget = nil

Services.RunService.RenderStepped:Connect(function(deltaTime)
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

    local isAiming = Options.aimbot_bind and Options.aimbot_bind:GetState() or false
    if Options.aimbot_enabled and Options.aimbot_enabled.Value and isAiming then
        local target = State.LockedTarget
        if target and (now - lastTargetValidationTime) >= 0.08 then
            lastTargetValidationTime = now
            if not IsTargetValid(target) then target = nil; State.LockedTarget = nil end
        end
        if not target and (now - lastTargetAcquireTime) >= 0.05 then
            lastTargetAcquireTime = now
            target = GetClosestPlayer(false)
            State.LockedTarget = target
        end
        if target ~= lastAimbotTarget then
            aimbotSmoothVelocity = Vector2.new(0, 0)
            lastAimbotTarget = target
        end
        if target and target.Character then
            local aimPart = target.Character:FindFirstChild(AimbotSettings.TargetPart or "Head") or target.Character:FindFirstChild("Head")
            if aimPart then
                local pos, onScreen = Services.Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local smoothing = tonumber(Options.aimbot_smoothing and Options.aimbot_smoothing.Value or 5) or 5
                    local delta = Vector2.new(pos.X, pos.Y) - Services.UserInputService:GetMouseLocation()
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
        State.LockedTarget = nil
        lastAimbotTarget = nil
        aimbotSmoothVelocity = Vector2.new(0, 0)
    end

    local isTriggerbotActive = Options.triggerbot_bind and Options.triggerbot_bind:GetState() or false
    if TriggerbotEnabled and isTriggerbotActive and (now - lastTriggerTime) >= 0.05 then
        local closestPlayer = GetClosestPlayer(false)
        if closestPlayer and closestPlayer.Character and not (State.AntiKatanaEnabled and IsEnemyDeflecting(closestPlayer)) then
            local targetPart = closestPlayer.Character:FindFirstChild(AimbotSettings.TargetPart or "Head") or closestPlayer.Character:FindFirstChild("Head")
            if targetPart and IsVisible(targetPart, closestPlayer) then
                local pos, onScreen = Services.Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Services.UserInputService:GetMouseLocation()).Magnitude
                    if dist <= 25 and mouse1click then
                        local delay = tonumber(TriggerbotDelay) or 0.05
                        lastTriggerTime = now
                        if delay > 0 then task.wait(delay) end
                        mouse1click()
                        lastTriggerTime = tick()
                    end
                end
            end
        end
    end
end)


