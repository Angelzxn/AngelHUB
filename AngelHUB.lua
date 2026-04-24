--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                   🔥 ANGEL HUB v1.0 🔥                     ║
    ║              World Fighters — Premium Hub                   ║
    ║                                                             ║
    ║  Compatible: Madium, Synapse, KRNL, Fluxus, Wave           ║
    ║  Game: World Fighters (95630541662383)                      ║
    ╚══════════════════════════════════════════════════════════════╝
    
    COMMUNICATION SYSTEM DISCOVERED:
    ───────────────────────────────────
    World Fighters uses BridgeNet for ALL client→server communication.
    
    Remote: ReplicatedStorage.BridgeNet.dataRemoteEvent
    
    Pattern: {{{Category, System, Action, ...params, n = count}, "\002"}}
    
    Discovered categories:
      "General" → Attack, CurrencyDrops, Gacha, Stars, Achievements, 
                  TimeRewards, FollowRewards, Gamemodes
      "Player"  → Teleport
    
    Mob Structure:
      Workspace > Server > Enemies > [World] > [SubWorld] > [Mob]
    
    Player Data:
      leaderstats > Power (StringValue), Crystals (StringValue), Awakening (NumberValue)
]]

-- ══════════════════════════════════════
-- ANTI-DUPLICATE PROTECTION
-- ══════════════════════════════════════
if getgenv and getgenv().AngelHUB_Loaded then
    if getgenv().AngelHUB_Destroy then
        getgenv().AngelHUB_Destroy()
    end
    task.wait(0.5)
end

-- ══════════════════════════════════════
-- ROBLOX SERVICES
-- ══════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════
-- BRIDGENET — WORLD FIGHTERS COMMUNICATION SYSTEM
-- ══════════════════════════════════════
local BridgeNet = {}

-- Main remote cache
local dataRemoteEvent

local function resolveDataRemoteEvent(timeout)
    local bridgeNetFolder = ReplicatedStorage:FindFirstChild("BridgeNet")
    if not bridgeNetFolder then
        bridgeNetFolder = ReplicatedStorage:WaitForChild("BridgeNet", timeout or 10)
    end
    
    if not bridgeNetFolder then
        warn("[Angel HUB] BridgeNet nao encontrado em ReplicatedStorage")
        return nil
    end
    
    local remote = bridgeNetFolder:FindFirstChild("dataRemoteEvent")
    if not remote then
        remote = bridgeNetFolder:WaitForChild("dataRemoteEvent", timeout or 10)
    end
    
    if not remote then
        warn("[Angel HUB] dataRemoteEvent nao encontrado em BridgeNet")
        return nil
    end
    
    return remote
end

local function getDataRemoteEvent()
    if dataRemoteEvent and dataRemoteEvent.Parent then
        return dataRemoteEvent
    end
    
    dataRemoteEvent = resolveDataRemoteEvent(3)
    return dataRemoteEvent
end

--- Fires a command via BridgeNet
--- @param category string "General" or "Player"
--- @param system string Ex: "Attack", "Teleport", "Gacha"
--- @param action string Ex: "Click", "Roll", "Claim"
--- @param ... any Additional parameters
function BridgeNet.Fire(category, system, action, ...)
    local params = {category, system, action}
    local extra = {...}
    local n = 3
    
    for _, v in ipairs(extra) do
        table.insert(params, v)
        n = n + 1
    end
    
    -- O n no BridgeNet inclui slots vazios no final
    -- Teleport usa n=6, outros usam n=3,4,5
    params.n = n
    
    local args = {{params, "\002"}}
    local remote = getDataRemoteEvent()
    if not remote then
        return false, "BridgeNet dataRemoteEvent indisponivel"
    end
    
    local ok, err = pcall(function()
        remote:FireServer(unpack(args))
    end)
    
    return ok, err
end

--- Specific version for Teleport (fixed n=6)
function BridgeNet.Teleport(worldName, subIndex)
    subIndex = subIndex or 1
    local params = {"Player", "Teleport", "Teleport", worldName, subIndex, n = 6}
    local args = {{params, "\002"}}
    local remote = getDataRemoteEvent()
    if not remote then
        return false, "BridgeNet dataRemoteEvent indisponivel"
    end
    pcall(function()
        remote:FireServer(unpack(args))
    end)
    return true
end

--- Attack with specific targets (mob UUIDs)
function BridgeNet.Attack(targetTable)
    targetTable = targetTable or {}
    local params = {"General", "Attack", "Click", targetTable, n = 4}
    local args = {{params, "\002"}}
    local remote = getDataRemoteEvent()
    if not remote then
        return false, "BridgeNet dataRemoteEvent indisponivel"
    end
    pcall(function()
        remote:FireServer(unpack(args))
    end)
    return true
end

--- Collect currency drop
function BridgeNet.CollectDrop(dropUUID)
    BridgeNet.Fire("General", "CurrencyDrops", "Collect", dropUUID)
end

--- Gacha Roll
function BridgeNet.GachaRoll(bannerName)
    local params = {"General", "Gacha", "Roll", bannerName, {}, n = 5}
    local args = {{params, "\002"}}
    local remote = getDataRemoteEvent()
    if not remote then
        return false, "BridgeNet dataRemoteEvent indisponivel"
    end
    pcall(function()
        remote:FireServer(unpack(args))
    end)
    return true
end

--- Stars/Pet Open
function BridgeNet.StarsOpen(bannerName, quantity)
    quantity = quantity or 1
    local params = {"General", "Stars", "Open", bannerName, quantity, n = 5}
    local args = {{params, "\002"}}
    local remote = getDataRemoteEvent()
    if not remote then
        return false, "BridgeNet dataRemoteEvent indisponivel"
    end
    pcall(function()
        remote:FireServer(unpack(args))
    end)
    return true
end

--- Claim Achievement
function BridgeNet.ClaimAchievement(achievementName)
    BridgeNet.Fire("General", "Achievements", "Claim", achievementName)
end

--- Claim Time Reward
function BridgeNet.ClaimTimeReward(rewardIndex)
    BridgeNet.Fire("General", "TimeRewards", "Claim", rewardIndex)
end

--- Join Gamemode
function BridgeNet.JoinGamemode(modeName)
    BridgeNet.Fire("General", "Gamemodes", "Join", modeName)
end

--- Verify Follow Rewards
function BridgeNet.VerifyFollow()
    local params = {"General", "FollowRewards", "Verify", n = 3}
    local args = {{params, "\002"}}
    local remote = getDataRemoteEvent()
    if not remote then
        return false, "BridgeNet dataRemoteEvent indisponivel"
    end
    pcall(function()
        remote:FireServer(unpack(args))
    end)
    return true
end

-- ══════════════════════════════════════
-- DEBOUNCE SERVICE
-- ══════════════════════════════════════
local Debounce = {}
local _locks = {}
local _loops = {}

function Debounce.Check(key) return not _locks[key] end
function Debounce.Lock(key) _locks[key] = true end
function Debounce.Unlock(key) _locks[key] = false end

function Debounce.StartLoop(key)
    local id = key .. "_" .. tostring(tick())
    _loops[key] = id
    return id
end

function Debounce.IsActive(key, id) return _loops[key] == id end
function Debounce.StopLoop(key) _loops[key] = nil end
function Debounce.ResetAll() _locks = {} _loops = {} end

-- ══════════════════════════════════════
-- PLAYER HELPERS
-- ══════════════════════════════════════
local PlayerHelper = {}

function PlayerHelper.GetCharacter()
    return LocalPlayer and LocalPlayer.Character
end

function PlayerHelper.GetHumanoid()
    local char = PlayerHelper.GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function PlayerHelper.GetRootPart()
    local char = PlayerHelper.GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function PlayerHelper.IsAlive()
    local hum = PlayerHelper.GetHumanoid()
    return hum and hum.Health > 0
end

function PlayerHelper.GetPosition()
    local root = PlayerHelper.GetRootPart()
    return root and root.Position or Vector3.new(0, 0, 0)
end

function PlayerHelper.SetWalkSpeed(speed)
    local hum = PlayerHelper.GetHumanoid()
    if hum then hum.WalkSpeed = speed end
end

function PlayerHelper.GetWalkSpeed()
    local hum = PlayerHelper.GetHumanoid()
    return hum and hum.WalkSpeed or 16
end

function PlayerHelper.SetJumpPower(power)
    local hum = PlayerHelper.GetHumanoid()
    if hum then hum.JumpPower = power end
end

function PlayerHelper.TeleportTo(cframe)
    local root = PlayerHelper.GetRootPart()
    if root then
        root.CFrame = typeof(cframe) == "CFrame" and cframe or CFrame.new(cframe)
    end
end

-- ══════════════════════════════════════
-- MOB FINDER — Finds mobs in World Fighters
-- Structure: Workspace > Server > Enemies > [World] > [SubWorld] > [Mob]
-- ══════════════════════════════════════
local MobFinder = {}

function MobFinder.GetEnemiesFolder()
    local server = Workspace:FindFirstChild("Server")
    if not server then return nil end
    return server:FindFirstChild("Enemies")
end

--- Lists all available worlds
function MobFinder.GetWorlds()
    local enemies = MobFinder.GetEnemiesFolder()
    if not enemies then return {} end
    
    local worlds = {}
    for _, child in ipairs(enemies:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            table.insert(worlds, child.Name)
        end
    end
    return worlds
end

--- Lists sub-worlds of a world
function MobFinder.GetSubWorlds(worldName)
    local enemies = MobFinder.GetEnemiesFolder()
    if not enemies then return {} end
    
    local world = enemies:FindFirstChild(worldName)
    if not world then return {} end
    
    local subs = {}
    for _, child in ipairs(world:GetChildren()) do
        table.insert(subs, child.Name)
    end
    return subs
end

--- Finds all alive mobs in a world/subworld
function MobFinder.GetMobs(worldName, subWorldName)
    local enemies = MobFinder.GetEnemiesFolder()
    if not enemies then return {} end
    
    local path = enemies
    if worldName then
        path = path:FindFirstChild(worldName)
        if not path then return {} end
    end
    if subWorldName then
        path = path:FindFirstChild(subWorldName)
        if not path then return {} end
    end
    
    local mobs = {}
    for _, mob in ipairs(path:GetChildren()) do
        -- Mobs are Models with Humanoid
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            table.insert(mobs, {
                Model = mob,
                Name = mob.Name,
                Health = humanoid.Health,
                MaxHealth = humanoid.MaxHealth,
                Position = mob:FindFirstChild("HumanoidRootPart") and mob.HumanoidRootPart.Position or mob:GetPivot().Position,
                UUID = mob:GetAttribute("UUID") or mob:FindFirstChild("UUID") and mob.UUID.Value or nil,
            })
        end
    end
    
    return mobs
end

--- Finds the nearest mob
function MobFinder.GetNearest(worldName, subWorldName)
    local mobs = MobFinder.GetMobs(worldName, subWorldName)
    local myPos = PlayerHelper.GetPosition()
    
    local nearest, nearestDist = nil, math.huge
    for _, mob in ipairs(mobs) do
        local dist = (myPos - mob.Position).Magnitude
        if dist < nearestDist then
            nearestDist = dist
            nearest = mob
        end
    end
    
    return nearest, nearestDist
end

-- ══════════════════════════════════════
-- THEME — Tema Visual Premium v2
-- ══════════════════════════════════════
local Theme = {
    Background = Color3.fromRGB(13, 13, 18),
    BackgroundSecondary = Color3.fromRGB(19, 19, 27),
    BackgroundTertiary = Color3.fromRGB(26, 26, 38),
    CardBg = Color3.fromRGB(30, 30, 44),
    Sidebar = Color3.fromRGB(10, 10, 16),
    SidebarHover = Color3.fromRGB(30, 30, 48),
    SidebarActive = Color3.fromRGB(99, 102, 241),
    TitleBar = Color3.fromRGB(10, 10, 16),
    Accent = Color3.fromRGB(99, 102, 241),
    AccentHover = Color3.fromRGB(79, 82, 210),
    AccentLight = Color3.fromRGB(129, 132, 255),
    AccentGlow = Color3.fromRGB(99, 102, 241),
    GradientStart = Color3.fromRGB(99, 102, 241),
    GradientEnd = Color3.fromRGB(168, 85, 247),
    Success = Color3.fromRGB(52, 211, 153),
    Warning = Color3.fromRGB(251, 191, 36),
    Error = Color3.fromRGB(248, 113, 113),
    Info = Color3.fromRGB(96, 165, 250),
    TextPrimary = Color3.fromRGB(240, 240, 250),
    TextSecondary = Color3.fromRGB(148, 155, 180),
    TextMuted = Color3.fromRGB(80, 85, 110),
    Toggle = {
        On = Color3.fromRGB(99, 102, 241),
        Off = Color3.fromRGB(45, 47, 60),
        Knob = Color3.fromRGB(255, 255, 255),
    },
    Slider = {
        Track = Color3.fromRGB(45, 47, 60),
        Fill = Color3.fromRGB(99, 102, 241),
        Knob = Color3.fromRGB(255, 255, 255),
    },
    Border = Color3.fromRGB(38, 40, 58),
    BorderLight = Color3.fromRGB(50, 52, 70),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontLight = Enum.Font.Gotham,
    CornerRadius = UDim.new(0, 8),
    CornerRadiusSmall = UDim.new(0, 6),
    CornerRadiusLarge = UDim.new(0, 12),
    SidebarWidth = 140,
    TitleBarHeight = 42,
}

-- ══════════════════════════════════════
-- TWEEN HELPERS
-- ══════════════════════════════════════
local function tween(instance, duration, props, style, direction)
    local info = TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function tweenBounce(instance, duration, props)
    return tween(instance, duration, props, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ══════════════════════════════════════
-- UI FRAMEWORK — Component Creation
-- ══════════════════════════════════════
local UI = {}

--- Creates the main ScreenGui
function UI.CreateScreenGui()
    -- Destroy existing
    local existing = PlayerGui:FindFirstChild("AngelHUB")
    if existing then existing:Destroy() end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "AngelHUB"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.Parent = PlayerGui
    
    return gui
end

--- Section Header (e.g. "🌍 Teleport")
function UI.SectionHeader(props)
    local container = Instance.new("Frame")
    container.Name = props.Name or "SectionHeader"
    container.Size = UDim2.new(1, -24, 0, 24)
    container.BackgroundTransparency = 1
    container.Parent = props.Parent
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0, 0, 0.5, -2)
    dot.BackgroundColor3 = props.Color or Theme.Accent
    dot.BorderSizePixel = 0
    dot.Parent = container
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = props.Text or ""
    label.TextColor3 = Theme.TextSecondary
    label.Font = Theme.FontBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    return container
end

--- Thin Separator
function UI.Separator(props)
    local sep = Instance.new("Frame")
    sep.Name = "Separator"
    sep.Size = UDim2.new(1, -24, 0, 1)
    sep.BackgroundColor3 = Theme.Border
    sep.BackgroundTransparency = 0.5
    sep.BorderSizePixel = 0
    sep.Parent = props.Parent
    return sep
end

--- Creates a styled base Frame
function UI.Frame(props)
    local frame = Instance.new("Frame")
    frame.Name = props.Name or "Frame"
    frame.Size = props.Size or UDim2.new(0, 100, 0, 100)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    frame.BackgroundColor3 = props.Color or Theme.Background
    frame.BackgroundTransparency = props.Transparency or 0
    frame.BorderSizePixel = 0
    frame.Parent = props.Parent
    
    if props.Corner ~= false then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = props.CornerRadius or Theme.CornerRadius
        corner.Parent = frame
    end
    
    if props.Stroke then
        local stroke = Instance.new("UIStroke")
        stroke.Color = props.StrokeColor or Theme.Border
        stroke.Thickness = props.StrokeThickness or 1
        stroke.Transparency = props.StrokeTransparency or 0
        stroke.Parent = frame
    end
    
    return frame
end

--- Creates a text label
function UI.Text(props)
    local label = Instance.new("TextLabel")
    label.Name = props.Name or "Label"
    label.Size = props.Size or UDim2.new(1, 0, 0, 20)
    label.Position = props.Position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = props.Text or ""
    label.TextColor3 = props.Color or Theme.TextPrimary
    label.Font = props.Font or Theme.Font
    label.TextSize = props.TextSize or 14
    label.TextXAlignment = props.Align or Enum.TextXAlignment.Left
    label.TextYAlignment = props.VAlign or Enum.TextYAlignment.Center
    label.TextWrapped = props.Wrapped or false
    label.TextTruncate = props.Truncate or Enum.TextTruncate.None
    label.Parent = props.Parent
    
    return label
end

--- Creates a button
function UI.Button(props)
    local btn = Instance.new("TextButton")
    btn.Name = props.Name or "Button"
    btn.Size = props.Size or UDim2.new(0, 120, 0, 36)
    btn.Position = props.Position or UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = props.Color or Theme.Accent
    btn.Text = props.Text or "Button"
    btn.TextColor3 = props.TextColor or Theme.TextPrimary
    btn.Font = props.Font or Theme.FontBold
    btn.TextSize = props.TextSize or 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = props.Parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = props.CornerRadius or Theme.CornerRadiusSmall
    corner.Parent = btn
    
    -- Hover effect
    local normalColor = props.Color or Theme.Accent
    local hoverColor = props.HoverColor or Theme.AccentHover
    
    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = hoverColor})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = normalColor})
    end)
    
    -- Click effect
    btn.MouseButton1Down:Connect(function()
        tween(btn, 0.08, {Size = UDim2.new(
            btn.Size.X.Scale, btn.Size.X.Offset - 2,
            btn.Size.Y.Scale, btn.Size.Y.Offset - 2
        )})
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, 0.15, {Size = props.Size or UDim2.new(0, 120, 0, 36)})
    end)
    
    if props.Callback then
        btn.MouseButton1Click:Connect(props.Callback)
    end
    
    return btn
end

--- Creates a Toggle (on/off switch)
function UI.Toggle(props)
    local container = Instance.new("Frame")
    container.Name = props.Name or "Toggle"
    container.Size = props.Size or UDim2.new(1, -24, 0, 42)
    container.BackgroundColor3 = Theme.BackgroundTertiary
    container.BackgroundTransparency = 0
    container.BorderSizePixel = 0
    container.Parent = props.Parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.CornerRadiusSmall
    corner.Parent = container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = container
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = props.Text or "Toggle"
    label.TextColor3 = Theme.TextPrimary
    label.Font = Theme.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Description (optional)
    if props.Description then
        label.Size = UDim2.new(1, -55, 0, 20)
        label.Position = UDim2.new(0, 0, 0, 4)
        
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, -55, 0, 16)
        desc.Position = UDim2.new(0, 0, 0, 22)
        desc.BackgroundTransparency = 1
        desc.Text = props.Description
        desc.TextColor3 = Theme.TextMuted
        desc.Font = Theme.FontLight
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextWrapped = true
        desc.Parent = container
        
        container.Size = UDim2.new(1, -24, 0, 50)
    end
    
    -- Switch track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(0, 44, 0, 22)
    track.Position = UDim2.new(1, -44, 0.5, -11)
    track.BackgroundColor3 = Theme.Toggle.Off
    track.BorderSizePixel = 0
    track.Parent = container
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Theme.Toggle.Knob
    knob.BorderSizePixel = 0
    knob.Parent = track
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    -- State
    local enabled = props.Default or false
    
    local function updateVisual(animate)
        if animate then
            if enabled then
                tween(track, 0.2, {BackgroundColor3 = Theme.Toggle.On})
                tween(knob, 0.2, {Position = UDim2.new(0, 24, 0.5, -9)}, Enum.EasingStyle.Back)
            else
                tween(track, 0.2, {BackgroundColor3 = Theme.Toggle.Off})
                tween(knob, 0.2, {Position = UDim2.new(0, 2, 0.5, -9)}, Enum.EasingStyle.Back)
            end
        else
            track.BackgroundColor3 = enabled and Theme.Toggle.On or Theme.Toggle.Off
            knob.Position = enabled and UDim2.new(0, 24, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        end
    end
    
    updateVisual(false)
    
    -- Click handler
    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = container
    
    clickBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        updateVisual(true)
        if props.Callback then
            props.Callback(enabled)
        end
    end)
    
    -- Hover
    clickBtn.MouseEnter:Connect(function()
        tween(container, 0.15, {BackgroundColor3 = Theme.SidebarHover})
    end)
    clickBtn.MouseLeave:Connect(function()
        tween(container, 0.15, {BackgroundColor3 = Theme.BackgroundTertiary})
    end)
    
    -- API (wrapper table, not Instance properties)
    local api = {
        Instance = container,
        SetValue = function(val)
            enabled = val
            updateVisual(true)
        end,
        GetValue = function() return enabled end,
    }
    
    return api
end

--- Creates a Slider (value bar)
function UI.Slider(props)
    local min = props.Min or 0
    local max = props.Max or 100
    local step = props.Step or 1
    local default = props.Default or min
    local currentValue = default
    
    local container = Instance.new("Frame")
    container.Name = props.Name or "Slider"
    container.Size = props.Size or UDim2.new(1, -24, 0, 58)
    container.BackgroundColor3 = Theme.BackgroundTertiary
    container.BorderSizePixel = 0
    container.Parent = props.Parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.CornerRadiusSmall
    corner.Parent = container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 8)
    padding.Parent = container
    
    -- Title + value
    local titleRow = Instance.new("Frame")
    titleRow.Size = UDim2.new(1, 0, 0, 20)
    titleRow.BackgroundTransparency = 1
    titleRow.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = props.Text or "Slider"
    label.TextColor3 = Theme.TextPrimary
    label.Font = Theme.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = titleRow
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(currentValue) .. (props.Suffix or "")
    valueLabel.TextColor3 = Theme.AccentLight
    valueLabel.Font = Theme.FontBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = titleRow
    
    -- Track
    local trackFrame = Instance.new("Frame")
    trackFrame.Name = "TrackFrame"
    trackFrame.Size = UDim2.new(1, 0, 0, 6)
    trackFrame.Position = UDim2.new(0, 0, 0, 36)
    trackFrame.BackgroundColor3 = Theme.Slider.Track
    trackFrame.BorderSizePixel = 0
    trackFrame.Parent = container
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = trackFrame
    
    -- Fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Slider.Fill
    fill.BorderSizePixel = 0
    fill.Parent = trackFrame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Theme.Slider.Knob
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = trackFrame
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    -- Shadow on knob
    local knobShadow = Instance.new("UIStroke")
    knobShadow.Color = Color3.fromRGB(0, 0, 0)
    knobShadow.Thickness = 1
    knobShadow.Transparency = 0.7
    knobShadow.Parent = knob
    
    -- Drag interaction
    local dragging = false
    
    local inputBtn = Instance.new("TextButton")
    inputBtn.Size = UDim2.new(1, 20, 0, 26)
    inputBtn.Position = UDim2.new(0, -10, 0, 26)
    inputBtn.BackgroundTransparency = 1
    inputBtn.Text = ""
    inputBtn.ZIndex = 10
    inputBtn.Parent = container
    
    local function updateValue(inputX)
        local trackAbsPos = trackFrame.AbsolutePosition.X
        local trackAbsSize = trackFrame.AbsoluteSize.X
        
        local relativeX = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
        local rawValue = min + relativeX * (max - min)
        
        -- Snap to step
        currentValue = math.floor(rawValue / step + 0.5) * step
        currentValue = math.clamp(currentValue, min, max)
        
        local percent = (currentValue - min) / (max - min)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -8, 0.5, -8)
        valueLabel.Text = tostring(currentValue) .. (props.Suffix or "")
        
        if props.Callback then
            props.Callback(currentValue)
        end
    end
    
    inputBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    inputBtn.MouseButton1Click:Connect(function()
        local mouse = UserInputService:GetMouseLocation()
        updateValue(mouse.X)
    end)
    
    -- API (wrapper table)
    local api = {
        Instance = container,
        SetValue = function(val)
            currentValue = math.clamp(val, min, max)
            local percent = (currentValue - min) / (max - min)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            knob.Position = UDim2.new(percent, -8, 0.5, -8)
            valueLabel.Text = tostring(currentValue) .. (props.Suffix or "")
        end,
        GetValue = function() return currentValue end,
    }
    
    return api
end

--- Creates a Dropdown
function UI.Dropdown(props)
    local options = props.Options or {}
    local multi = props.Multi or false
    local selected = props.Default or (multi and {} or nil)
    local isOpen = false
    
    local container = Instance.new("Frame")
    container.Name = props.Name or "Dropdown"
    container.Size = props.Size or UDim2.new(1, -24, 0, 42)
    container.BackgroundColor3 = Theme.BackgroundTertiary
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    container.Parent = props.Parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.CornerRadiusSmall
    corner.Parent = container
    
    -- Header
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundTransparency = 1
    header.Text = ""
    header.Parent = container
    
    local hpadding = Instance.new("UIPadding")
    hpadding.PaddingLeft = UDim.new(0, 12)
    hpadding.PaddingRight = UDim.new(0, 12)
    hpadding.Parent = header
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = props.Text or "Select"
    label.TextColor3 = Theme.TextPrimary
    label.Font = Theme.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Name = "Selected"
    selectedLabel.Size = UDim2.new(0.45, 0, 1, 0)
    selectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.TextColor3 = Theme.TextSecondary
    selectedLabel.Font = Theme.FontLight
    selectedLabel.TextSize = 12
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
    selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
    selectedLabel.Parent = header
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -8, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▾"
    arrow.TextColor3 = Theme.TextMuted
    arrow.Font = Theme.FontBold
    arrow.TextSize = 16
    arrow.Parent = header
    
    -- Options container
    local optContainer = Instance.new("Frame")
    optContainer.Name = "Options"
    optContainer.Size = UDim2.new(1, 0, 0, 0) -- Starts collapsed
    optContainer.Position = UDim2.new(0, 0, 0, 44)
    optContainer.BackgroundColor3 = Theme.BackgroundSecondary
    optContainer.BorderSizePixel = 0
    optContainer.ClipsDescendants = true
    optContainer.ZIndex = 50
    optContainer.Parent = container
    
    local optCorner = Instance.new("UICorner")
    optCorner.CornerRadius = Theme.CornerRadiusSmall
    optCorner.Parent = optContainer
    
    local optStroke = Instance.new("UIStroke")
    optStroke.Color = Theme.Border
    optStroke.Thickness = 1
    optStroke.Parent = optContainer
    
    local optLayout = Instance.new("UIListLayout")
    optLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optLayout.Padding = UDim.new(0, 1)
    optLayout.Parent = optContainer
    
    local function getSelectedText()
        if multi then
            if #selected == 0 then return "None" end
            if #selected == 1 then return selected[1] end
            return #selected .. " selected"
        else
            return selected or "None"
        end
    end
    
    local function refreshOptions()
        -- Clear existing
        for _, child in ipairs(optContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Name = "Opt_" .. opt
            optBtn.Size = UDim2.new(1, 0, 0, 32)
            optBtn.BackgroundColor3 = Theme.BackgroundSecondary
            optBtn.BackgroundTransparency = 0
            optBtn.Text = ""
            optBtn.AutoButtonColor = false
            optBtn.BorderSizePixel = 0
            optBtn.ZIndex = 51
            optBtn.LayoutOrder = i
            optBtn.Parent = optContainer
            
            local optLabel = Instance.new("TextLabel")
            optLabel.Size = UDim2.new(1, -40, 1, 0)
            optLabel.Position = UDim2.new(0, 12, 0, 0)
            optLabel.BackgroundTransparency = 1
            optLabel.Text = opt
            optLabel.TextColor3 = Theme.TextPrimary
            optLabel.Font = Theme.FontLight
            optLabel.TextSize = 12
            optLabel.TextXAlignment = Enum.TextXAlignment.Left
            optLabel.ZIndex = 52
            optLabel.Parent = optBtn
            
            -- Check mark for multi
            local checkMark = Instance.new("TextLabel")
            checkMark.Size = UDim2.new(0, 20, 1, 0)
            checkMark.Position = UDim2.new(1, -28, 0, 0)
            checkMark.BackgroundTransparency = 1
            checkMark.Font = Theme.FontBold
            checkMark.TextSize = 14
            checkMark.ZIndex = 52
            checkMark.Parent = optBtn
            
            local function updateCheck()
                if multi then
                    local isSelected = table.find(selected, opt) ~= nil
                    checkMark.Text = isSelected and "✓" or ""
                    checkMark.TextColor3 = isSelected and Theme.Success or Theme.TextMuted
                    optLabel.TextColor3 = isSelected and Theme.TextPrimary or Theme.TextSecondary
                else
                    checkMark.Text = (selected == opt) and "✓" or ""
                    checkMark.TextColor3 = Theme.Success
                end
            end
            updateCheck()
            
            optBtn.MouseEnter:Connect(function()
                tween(optBtn, 0.1, {BackgroundColor3 = Theme.SidebarHover})
            end)
            optBtn.MouseLeave:Connect(function()
                tween(optBtn, 0.1, {BackgroundColor3 = Theme.BackgroundSecondary})
            end)
            
            optBtn.MouseButton1Click:Connect(function()
                if multi then
                    local idx = table.find(selected, opt)
                    if idx then
                        table.remove(selected, idx)
                    else
                        table.insert(selected, opt)
                    end
                else
                    selected = opt
                    -- Close dropdown for single select
                    isOpen = false
                    tween(optContainer, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
                    arrow.Text = "▾"
                end
                
                updateCheck()
                selectedLabel.Text = getSelectedText()
                
                -- Refresh all check marks
                for _, child in ipairs(optContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        -- Find and update check
                    end
                end
                
                if props.Callback then
                    props.Callback(multi and selected or selected)
                end
            end)
        end
    end
    
    selectedLabel.Text = getSelectedText()
    refreshOptions()
    
    -- Toggle open/close
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local totalHeight = math.min(#options * 33, 200)
            tween(optContainer, 0.25, {Size = UDim2.new(1, 0, 0, totalHeight)})
            arrow.Text = "▴"
        else
            tween(optContainer, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
            arrow.Text = "▾"
        end
    end)
    
    -- Hover
    header.MouseEnter:Connect(function()
        tween(container, 0.15, {BackgroundColor3 = Theme.SidebarHover})
    end)
    header.MouseLeave:Connect(function()
        tween(container, 0.15, {BackgroundColor3 = Theme.BackgroundTertiary})
    end)
    
    -- API (wrapper table)
    local api = {
        Instance = container,
        SetOptions = function(newOptions)
            options = newOptions
            if multi then selected = {} else selected = nil end
            selectedLabel.Text = getSelectedText()
            refreshOptions()
        end,
        GetValue = function() return multi and selected or selected end,
        SetValue = function(val)
            selected = val
            selectedLabel.Text = getSelectedText()
            refreshOptions()
        end,
    }
    
    return api
end

--- Toast Notification System
local NotificationSystem = {}
local notifQueue = {}

function NotificationSystem.Init(parent)
    NotificationSystem.Container = Instance.new("Frame")
    NotificationSystem.Container.Name = "Notifications"
    NotificationSystem.Container.Size = UDim2.new(0, 280, 1, 0)
    NotificationSystem.Container.Position = UDim2.new(1, -290, 0, 0)
    NotificationSystem.Container.BackgroundTransparency = 1
    NotificationSystem.Container.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = NotificationSystem.Container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 16)
    padding.Parent = NotificationSystem.Container
end

function NotificationSystem.Show(title, message, type, duration)
    type = type or "info"
    duration = duration or 3
    
    local colors = {
        info = Theme.Info,
        success = Theme.Success,
        warning = Theme.Warning,
        error = Theme.Error,
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌",
    }
    
    local notif = Instance.new("Frame")
    notif.Name = "Notification"
    notif.Size = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = Theme.BackgroundSecondary
    notif.BorderSizePixel = 0
    notif.BackgroundTransparency = 1
    notif.Parent = NotificationSystem.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.CornerRadiusSmall
    corner.Parent = notif
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = colors[type] or Theme.Info
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = notif
    
    -- Accent bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0.8, 0)
    bar.Position = UDim2.new(0, 6, 0.1, 0)
    bar.BackgroundColor3 = colors[type] or Theme.Info
    bar.BorderSizePixel = 0
    bar.Parent = notif
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -24, 0, 20)
    titleLabel.Position = UDim2.new(0, 16, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = (icons[type] or "") .. " " .. title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.Font = Theme.FontBold
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif
    
    -- Message
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -24, 0, 24)
    msgLabel.Position = UDim2.new(0, 16, 0, 28)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Theme.TextSecondary
    msgLabel.Font = Theme.FontLight
    msgLabel.TextSize = 11
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = notif
    
    -- Animate in
    tween(notif, 0.3, {BackgroundTransparency = 0}, Enum.EasingStyle.Back)
    
    -- Auto remove
    task.delay(duration, function()
        tween(notif, 0.3, {BackgroundTransparency = 1})
        task.wait(0.35)
        notif:Destroy()
    end)
end

-- ══════════════════════════════════════
-- MAIN HUB WINDOW
-- ══════════════════════════════════════

-- Hub State
local HubState = {
    ActiveTab = "Main",
    ModuleStates = {},
    Connections = {},
}

-- Tab definitions
local Tabs = {
    {Name = "Main", Icon = "⚔️", Color = Color3.fromRGB(237, 66, 69)},
    {Name = "Gamemodes", Icon = "🏆", Color = Color3.fromRGB(88, 101, 242)},
    {Name = "Gacha", Icon = "🎰", Color = Color3.fromRGB(165, 108, 255)},
    {Name = "Quests", Icon = "📜", Color = Color3.fromRGB(254, 231, 92)},
    {Name = "Rewards", Icon = "🎁", Color = Color3.fromRGB(87, 242, 135)},
    {Name = "Misc", Icon = "⚙️", Color = Color3.fromRGB(148, 155, 175)},
}

local ScreenGui, MainFrame, SideBar, ContentArea, ContentPages

local function buildHub()
    ScreenGui = UI.CreateScreenGui()
    
    -- Notification system
    NotificationSystem.Init(ScreenGui)
    
    -- ═══ MAIN CONTAINER ═══
    MainFrame = UI.Frame({
        Name = "MainFrame",
        Size = UDim2.new(0, 720, 0, 470),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Color = Theme.Background,
        Parent = ScreenGui,
        Stroke = true,
        StrokeColor = Theme.Border,
        CornerRadius = Theme.CornerRadiusLarge,
    })
    MainFrame.ClipsDescendants = true
    
    -- Drop shadow (sublte)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014054970"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = MainFrame
    
    -- ═══ TITLE BAR ═══
    local titleBar = UI.Frame({
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, Theme.TitleBarHeight),
        Color = Theme.TitleBar,
        Parent = MainFrame,
        Corner = false,
    })
    
    -- Gradient line at bottom of title bar
    local titleGradientLine = Instance.new("Frame")
    titleGradientLine.Size = UDim2.new(1, 0, 0, 2)
    titleGradientLine.Position = UDim2.new(0, 0, 1, -2)
    titleGradientLine.BackgroundColor3 = Color3.new(1,1,1)
    titleGradientLine.BorderSizePixel = 0
    titleGradientLine.Parent = titleBar
    local titleGrad = Instance.new("UIGradient")
    titleGrad.Color = ColorSequence.new(Theme.GradientStart, Theme.GradientEnd)
    titleGrad.Parent = titleGradientLine
    
    -- Fire icon with glow
    local title = UI.Text({
        Name = "Title",
        Text = "  🔥 ANGEL HUB",
        Size = UDim2.new(0, 200, 1, 0),
        Color = Theme.TextPrimary,
        Font = Theme.FontBold,
        TextSize = 15,
        Parent = titleBar,
    })
    
    -- Version badge with gradient
    local verBadge = UI.Frame({
        Name = "Version",
        Size = UDim2.new(0, 48, 0, 20),
        Position = UDim2.new(0, 148, 0.5, -10),
        Color = Theme.Accent,
        Parent = titleBar,
        CornerRadius = UDim.new(1, 0),
    })
    local verGrad = Instance.new("UIGradient")
    verGrad.Color = ColorSequence.new(Theme.GradientStart, Theme.GradientEnd)
    verGrad.Parent = verBadge
    UI.Text({
        Text = "v1.0",
        Size = UDim2.new(1, 0, 1, 0),
        Align = Enum.TextXAlignment.Center,
        TextSize = 10,
        Font = Theme.FontBold,
        Parent = verBadge,
    })
    
    -- Game info + player
    UI.Text({
        Text = "World Fighters  •  " .. LocalPlayer.Name,
        Size = UDim2.new(0, 250, 1, 0),
        Position = UDim2.new(0, 210, 0, 0),
        Color = Theme.TextMuted,
        TextSize = 11,
        Font = Theme.FontLight,
        Parent = titleBar,
    })
    
    -- Close button (DESTROY hub)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, Theme.TitleBarHeight, 0, Theme.TitleBarHeight)
    closeBtn.Position = UDim2.new(1, -Theme.TitleBarHeight, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Theme.TextMuted
    closeBtn.Font = Theme.FontBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, 0.15, {TextColor3 = Theme.Error})
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, 0.15, {TextColor3 = Theme.TextMuted})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        destroyHub()
    end)
    
    -- Minimize button (HIDE hub, RCtrl to show)
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.Size = UDim2.new(0, Theme.TitleBarHeight, 0, Theme.TitleBarHeight)
    minBtn.Position = UDim2.new(1, -Theme.TitleBarHeight*2, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "-"
    minBtn.TextColor3 = Theme.TextMuted
    minBtn.Font = Theme.FontBold
    minBtn.TextSize = 18
    minBtn.Parent = titleBar
    
    minBtn.MouseEnter:Connect(function()
        tween(minBtn, 0.15, {TextColor3 = Theme.Warning})
    end)
    minBtn.MouseLeave:Connect(function()
        tween(minBtn, 0.15, {TextColor3 = Theme.TextMuted})
    end)
    minBtn.MouseButton1Click:Connect(function()
        tween(MainFrame, 0.25, {
            Size = UDim2.new(0, 720, 0, 0),
            BackgroundTransparency = 0.5,
        })
        task.wait(0.3)
        MainFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 720, 0, 470)
        MainFrame.BackgroundTransparency = 0
        NotificationSystem.Show("Minimized", "RightControl to open", "info", 3)
    end)
    
    -- ═══ DRAG FUNCTIONALITY ═══
    local dragging, dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- ═══ SIDEBAR ═══
    SideBar = UI.Frame({
        Name = "Sidebar",
        Size = UDim2.new(0, Theme.SidebarWidth, 1, -Theme.TitleBarHeight),
        Position = UDim2.new(0, 0, 0, Theme.TitleBarHeight),
        Color = Theme.Sidebar,
        Parent = MainFrame,
        Corner = false,
    })
    
    local sepLine = Instance.new("Frame")
    sepLine.Size = UDim2.new(0, 1, 1, 0)
    sepLine.Position = UDim2.new(1, 0, 0, 0)
    sepLine.BackgroundColor3 = Theme.Border
    sepLine.BorderSizePixel = 0
    sepLine.Parent = SideBar
    
    local sideLayout = Instance.new("UIListLayout")
    sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sideLayout.Padding = UDim.new(0, 2)
    sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sideLayout.Parent = SideBar
    
    local sidePadding = Instance.new("UIPadding")
    sidePadding.PaddingTop = UDim.new(0, 10)
    sidePadding.PaddingLeft = UDim.new(0, 8)
    sidePadding.PaddingRight = UDim.new(0, 8)
    sidePadding.Parent = SideBar
    
    -- ═══ CONTENT AREA ═══
    ContentArea = UI.Frame({
        Name = "ContentArea",
        Size = UDim2.new(1, -Theme.SidebarWidth, 1, -Theme.TitleBarHeight - 28),
        Position = UDim2.new(0, Theme.SidebarWidth, 0, Theme.TitleBarHeight),
        Color = Theme.BackgroundSecondary,
        Parent = MainFrame,
        Corner = false,
    })
    ContentArea.ClipsDescendants = true
    
    -- ═══ STATUS BAR (bottom) ═══
    local statusBar = UI.Frame({
        Name = "StatusBar",
        Size = UDim2.new(1, -Theme.SidebarWidth, 0, 28),
        Position = UDim2.new(0, Theme.SidebarWidth, 1, -28),
        Color = Theme.TitleBar,
        Parent = MainFrame,
        Corner = false,
    })
    local statusPad = Instance.new("UIPadding")
    statusPad.PaddingLeft = UDim.new(0, 12)
    statusPad.PaddingRight = UDim.new(0, 12)
    statusPad.Parent = statusBar
    
    local statusLeft = UI.Text({
        Name = "StatusLeft",
        Text = "⚡ Power: ... | 💎 Crystals: ...",
        Size = UDim2.new(0.6, 0, 1, 0),
        Color = Theme.TextMuted,
        TextSize = 10,
        Font = Theme.FontLight,
        Parent = statusBar,
    })
    local statusRight = UI.Text({
        Name = "StatusRight",
        Text = "RCtrl: Toggle  •  Drag: Title Bar",
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0.6, 0, 0, 0),
        Align = Enum.TextXAlignment.Right,
        Color = Theme.TextMuted,
        TextSize = 10,
        Font = Theme.FontLight,
        Parent = statusBar,
    })
    
    -- Live status bar update
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls then
                local p = ls:FindFirstChild("Power")
                local c = ls:FindFirstChild("Crystals")
                statusLeft.Text = "⚡ " .. (p and tostring(p.Value) or "?") .. "  |  💎 " .. (c and tostring(c.Value) or "?")
            end
            task.wait(1)
        end
    end)
    
    -- Content pages (one per tab)
    ContentPages = {}
    
    -- ═══ CREATE TABS & PAGES ═══
    for i, tabDef in ipairs(Tabs) do
        -- Sidebar button with icon + label
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. tabDef.Name
        tabBtn.Size = UDim2.new(1, 0, 0, 36)
        tabBtn.BackgroundColor3 = Theme.Sidebar
        tabBtn.BackgroundTransparency = 0
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.BorderSizePixel = 0
        tabBtn.LayoutOrder = i
        tabBtn.Parent = SideBar
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = Theme.CornerRadiusSmall
        tabCorner.Parent = tabBtn
        
        -- Icon
        local tabIcon = Instance.new("TextLabel")
        tabIcon.Size = UDim2.new(0, 30, 1, 0)
        tabIcon.Position = UDim2.new(0, 10, 0, 0)
        tabIcon.BackgroundTransparency = 1
        tabIcon.Text = tabDef.Icon
        tabIcon.TextSize = 16
        tabIcon.Font = Theme.Font
        tabIcon.Parent = tabBtn
        
        -- Label
        local tabLabel = Instance.new("TextLabel")
        tabLabel.Size = UDim2.new(1, -48, 1, 0)
        tabLabel.Position = UDim2.new(0, 40, 0, 0)
        tabLabel.BackgroundTransparency = 1
        tabLabel.Text = tabDef.Name
        tabLabel.TextColor3 = Theme.TextSecondary
        tabLabel.TextSize = 12
        tabLabel.Font = Theme.Font
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.Parent = tabBtn
        
        -- Active indicator
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 3, 0.6, 0)
        indicator.Position = UDim2.new(0, -1, 0.2, 0)
        indicator.BackgroundColor3 = tabDef.Color
        indicator.BorderSizePixel = 0
        indicator.Visible = (i == 1)
        indicator.Parent = tabBtn
        
        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(1, 0)
        indCorner.Parent = indicator
        
        -- Hover
        tabBtn.MouseEnter:Connect(function()
            if HubState.ActiveTab ~= tabDef.Name then
                tween(tabBtn, 0.15, {BackgroundColor3 = Theme.SidebarHover})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if HubState.ActiveTab ~= tabDef.Name then
                tween(tabBtn, 0.15, {BackgroundColor3 = Theme.Sidebar})
            end
        end)
        
        -- Content page
        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. tabDef.Name
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.Accent
        page.ScrollBarImageTransparency = 0.5
        page.BorderSizePixel = 0
        page.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto
        page.Visible = (i == 1)
        page.Parent = ContentArea
        
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = page
        
        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop = UDim.new(0, 12)
        pagePadding.PaddingLeft = UDim.new(0, 12)
        pagePadding.PaddingRight = UDim.new(0, 12)
        pagePadding.PaddingBottom = UDim.new(0, 12)
        pagePadding.Parent = page
        
        -- Auto canvas size
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 24)
        end)
        
        -- Page header with gradient accent
        local pageHeader = UI.Frame({
            Name = "Header",
            Size = UDim2.new(1, -24, 0, 40),
            Color = Theme.BackgroundSecondary,
            Parent = page,
            Corner = false,
        })
        pageHeader.BackgroundTransparency = 1
        
        UI.Text({
            Text = tabDef.Icon .. "  " .. string.upper(tabDef.Name),
            Size = UDim2.new(1, 0, 0, 30),
            Color = Theme.TextPrimary,
            Font = Theme.FontBold,
            TextSize = 16,
            Parent = pageHeader,
        })
        
        -- Gradient accent line under header
        local accentLine = Instance.new("Frame")
        accentLine.Size = UDim2.new(0, 60, 0, 3)
        accentLine.Position = UDim2.new(0, 0, 1, -3)
        accentLine.BackgroundColor3 = Color3.new(1,1,1)
        accentLine.BorderSizePixel = 0
        accentLine.Parent = pageHeader
        
        local accentGrad = Instance.new("UIGradient")
        accentGrad.Color = ColorSequence.new(tabDef.Color, Theme.GradientEnd)
        accentGrad.Parent = accentLine
        
        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accentLine
        
        ContentPages[tabDef.Name] = page
        
        -- Tab click handler
        tabBtn.MouseButton1Click:Connect(function()
            -- Deactivate all tabs
            for _, child in ipairs(SideBar:GetChildren()) do
                if child:IsA("TextButton") then
                    tween(child, 0.15, {BackgroundColor3 = Theme.Sidebar})
                    local ind = child:FindFirstChild("Indicator")
                    if ind then ind.Visible = false end
                    -- Reset label color
                    for _, sub in ipairs(child:GetChildren()) do
                        if sub:IsA("TextLabel") and sub.Name ~= "" and sub.TextSize == 12 then
                            tween(sub, 0.15, {TextColor3 = Theme.TextSecondary})
                        end
                    end
                end
            end
            
            -- Activate this tab
            tween(tabBtn, 0.15, {BackgroundColor3 = Theme.SidebarHover})
            tween(tabLabel, 0.15, {TextColor3 = Theme.TextPrimary})
            indicator.Visible = true
            
            -- Show correct page with fade
            for name, pg in pairs(ContentPages) do
                pg.Visible = (name == tabDef.Name)
            end
            
            HubState.ActiveTab = tabDef.Name
        end)
        
        -- Set initial active state
        if i == 1 then
            tabBtn.BackgroundColor3 = Theme.SidebarHover
            tabLabel.TextColor3 = Theme.TextPrimary
        end
    end
    
    -- ═══ TOGGLE HOTKEY (RightControl) ═══
    table.insert(HubState.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            MainFrame.Visible = not MainFrame.Visible
        end
    end))
    
    -- ═══ OPEN ANIMATION ═══
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    task.wait(0.1)
    tween(MainFrame, 0.5, {
        Size = UDim2.new(0, 720, 0, 470),
        BackgroundTransparency = 0,
    }, Enum.EasingStyle.Back)
end

-- ══════════════════════════════════════
-- MODULE: MAIN (Auto Farm)
-- ══════════════════════════════════════
local function setupMainTab()
    local page = ContentPages["Main"]
    if not page then return end
    
    -- Combat section
    UI.SectionHeader({Text = "COMBAT", Color = Theme.Error, Parent = page})
    
    -- Auto Click (uses the game's native attack system)
    UI.Toggle({
        Name = "AutoClick",
        Text = "Auto Click",
        Description = "Enables auto click using the game's attack system",
        Parent = page,
        Callback = function(enabled)
            HubState.ModuleStates.AutoClick = enabled
            if enabled then
                local loopId = Debounce.StartLoop("autoclick")
                task.spawn(function()
                    while Debounce.IsActive("autoclick", loopId) and HubState.ModuleStates.AutoClick do
                        BridgeNet.Attack({})
                        task.wait(0.1)
                    end
                end)
                NotificationSystem.Show("Auto Click", "Enabled!", "success")
            else
                Debounce.StopLoop("autoclick")
                NotificationSystem.Show("Auto Click", "Disabled", "info")
            end
        end,
    })
    
    -- Auto Collect Drops
    UI.Toggle({
        Name = "AutoCollect",
        Text = "Auto Collect Drops",
        Description = "Collects crystals/drops automatically",
        Parent = page,
        Callback = function(enabled)
            HubState.ModuleStates.AutoCollect = enabled
            if enabled then
                local loopId = Debounce.StartLoop("autocollect")
                task.spawn(function()
                    while Debounce.IsActive("autocollect", loopId) and HubState.ModuleStates.AutoCollect do
                        -- Search for drops in workspace
                        local server = Workspace:FindFirstChild("Server")
                        if server then
                            local drops = server:FindFirstChild("CurrencyDrops") or server:FindFirstChild("Drops")
                            if drops then
                                for _, drop in ipairs(drops:GetChildren()) do
                                    local uuid = drop:GetAttribute("UUID") or drop.Name
                                    pcall(function()
                                        BridgeNet.CollectDrop(uuid)
                                    end)
                                end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
                NotificationSystem.Show("Auto Collect", "Collecting drops!", "success")
            else
                Debounce.StopLoop("autocollect")
            end
        end,
    })
    
    UI.Separator({Parent = page})
    UI.SectionHeader({Text = "AUTO FARM", Color = Theme.Success, Parent = page})
    
    -- World Selection
    local worlds = MobFinder.GetWorlds()
    local selectedWorld = nil
    local selectedSubWorld = nil
    
    local subWorldDropdown -- forward declaration
    
    local worldDropdown = UI.Dropdown({
        Name = "WorldSelect",
        Text = "World",
        Options = worlds,
        Parent = page,
        Callback = function(val)
            selectedWorld = val
            -- Update sub-worlds
            if selectedWorld and subWorldDropdown then
                local subs = MobFinder.GetSubWorlds(selectedWorld)
                subWorldDropdown.SetOptions(subs)
            end
        end,
    })
    
    subWorldDropdown = UI.Dropdown({
        Name = "SubWorldSelect",
        Text = "Sub-World",
        Options = {},
        Parent = page,
        Callback = function(val)
            selectedSubWorld = val
        end,
    })
    
    -- Attack nearest mob
    UI.Toggle({
        Name = "AutoFarm",
        Text = "⚔️ Auto Farm (Attack Nearest)",
        Description = "Attacks the nearest mob automatically",
        Parent = page,
        Callback = function(enabled)
            HubState.ModuleStates.AutoFarm = enabled
            if enabled then
                local loopId = Debounce.StartLoop("autofarm")
                task.spawn(function()
                    while Debounce.IsActive("autofarm", loopId) and HubState.ModuleStates.AutoFarm do
                        if PlayerHelper.IsAlive() and selectedWorld then
                            local nearest, dist = MobFinder.GetNearest(selectedWorld, selectedSubWorld)
                            if nearest and nearest.Model then
                                -- Teleport near the mob
                                local mobRoot = nearest.Model:FindFirstChild("HumanoidRootPart")
                                if mobRoot and dist > 15 then
                                    PlayerHelper.TeleportTo(mobRoot.CFrame * CFrame.new(0, 0, 5))
                                    task.wait(0.3)
                                end
                                
                                -- Attack
                                BridgeNet.Attack({})
                            end
                        end
                        task.wait(0.15)
                    end
                end)
                NotificationSystem.Show("Auto Farm", "Farming at " .. (selectedWorld or "?"), "success")
            else
                Debounce.StopLoop("autofarm")
                NotificationSystem.Show("Auto Farm", "Disabled", "info")
            end
        end,
    })
    
    -- Attack Speed slider
    UI.Slider({
        Name = "AttackSpeed",
        Text = "Attack Delay",
        Min = 0.05,
        Max = 1,
        Step = 0.05,
        Default = 0.15,
        Suffix = "s",
        Parent = page,
        Callback = function(val)
            HubState.ModuleStates.AttackDelay = val
        end,
    })
end

-- ══════════════════════════════════════
-- MODULE: GAMEMODES
-- ══════════════════════════════════════
local function setupGamemodesTab()
    local page = ContentPages["Gamemodes"]
    if not page then return end
    
    -- Teleport section
    UI.SectionHeader({Text = "TELEPORT", Color = Theme.Info, Parent = page})
    
    local worldsForTP = {"Fruits Verse", "Trial"}
    
    UI.Dropdown({
        Name = "TeleportWorld",
        Text = "Teleport to",
        Options = worldsForTP,
        Parent = page,
        Callback = function(val)
            if val then
                BridgeNet.Teleport(val, 1)
                NotificationSystem.Show("Teleport", "Going to " .. val, "info")
            end
        end,
    })
    
    -- Sub world index
    UI.Slider({
        Name = "SubWorldIndex",
        Text = "Sub-World Index",
        Min = 1,
        Max = 10,
        Step = 1,
        Default = 1,
        Parent = page,
    })
    
    -- Teleport button
    UI.Button({
        Name = "TeleportBtn",
        Text = "🚀 Teleportar",
        Size = UDim2.new(1, -24, 0, 36),
        Parent = page,
        Callback = function()
            local worldDD = ContentPages["Gamemodes"]:FindFirstChild("TeleportWorld")
            local subSlider = ContentPages["Gamemodes"]:FindFirstChild("SubWorldIndex")
            
            local world = worldDD and worldDD.GetValue() or "Fruits Verse"
            local sub = subSlider and subSlider.GetValue() or 1
            
            BridgeNet.Teleport(world, sub)
            NotificationSystem.Show("Teleport", "Teleporting to " .. tostring(world) .. " #" .. tostring(sub), "success")
        end,
    })
    
    UI.Separator({Parent = page})
    
    -- Trials section
    UI.SectionHeader({Text = "TRIALS", Color = Theme.Warning, Parent = page})
    
    UI.Dropdown({
        Name = "TrialSelect",
        Text = "Trial",
        Options = {"Trial Easy", "Trial Medium", "Trial Hard", "Trial Insane", "Trial Nightmare"},
        Parent = page,
    })
    
    UI.Button({
        Name = "JoinTrialBtn",
        Text = "⚡ Entrar na Trial",
        Size = UDim2.new(1, -24, 0, 36),
        Parent = page,
        Callback = function()
            -- First teleport to lobby
            BridgeNet.Teleport("Trial", 1)
            task.wait(1)
            
            -- Then join the selected trial
            local trialDD = ContentPages["Gamemodes"]:FindFirstChild("TrialSelect")
            local trial = trialDD and trialDD.GetValue() or "Trial Easy"
            
            BridgeNet.JoinGamemode(trial)
            NotificationSystem.Show("Trial", "Joining " .. trial, "success")
        end,
    })
    
    -- Auto Trial
    UI.Toggle({
        Name = "AutoTrial",
        Text = "Auto Trial Loop",
        Description = "Automatically joins trials in a loop",
        Parent = page,
        Callback = function(enabled)
            HubState.ModuleStates.AutoTrial = enabled
            if enabled then
                local loopId = Debounce.StartLoop("autotrial")
                task.spawn(function()
                    while Debounce.IsActive("autotrial", loopId) and HubState.ModuleStates.AutoTrial do
                        local trialDD = ContentPages["Gamemodes"]:FindFirstChild("TrialSelect")
                        local trial = trialDD and trialDD.GetValue() or "Trial Easy"
                        
                        BridgeNet.Teleport("Trial", 1)
                        task.wait(2)
                        BridgeNet.JoinGamemode(trial)
                        
                        -- Wait for trial to finish (adjust as needed)
                        task.wait(60)
                    end
                end)
                NotificationSystem.Show("Auto Trial", "Loop enabled!", "success")
            else
                Debounce.StopLoop("autotrial")
            end
        end,
    })
    
    -- Trial wait time slider
    UI.Slider({
        Name = "TrialWait",
        Text = "Time Between Trials",
        Min = 10,
        Max = 300,
        Step = 10,
        Default = 60,
        Suffix = "s",
        Parent = page,
    })
    
    -- Position display
    UI.Text({
        Text = "Current Position",
        Size = UDim2.new(1, -24, 0, 20),
        Color = Theme.TextSecondary,
        Font = Theme.FontBold,
        TextSize = 12,
        Parent = page,
    })
    
    local posLabel = UI.Text({
        Name = "PosDisplay",
        Text = "X: 0 | Y: 0 | Z: 0",
        Size = UDim2.new(1, -24, 0, 20),
        Color = Theme.AccentLight,
        Font = Theme.Font,
        TextSize = 12,
        Parent = page,
    })
    
    -- Update position display
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            local pos = PlayerHelper.GetPosition()
            posLabel.Text = string.format("X: %.0f | Y: %.0f | Z: %.0f", pos.X, pos.Y, pos.Z)
            task.wait(0.5)
        end
    end)
end

-- ══════════════════════════════════════
-- MODULE: GACHA
-- ══════════════════════════════════════
local function setupGachaTab()
    local page = ContentPages["Gacha"]
    if not page then return end
    
    -- Gacha section
    UI.SectionHeader({Text = "GACHA ROLL", Color = Theme.GradientEnd, Parent = page})
    
    UI.Dropdown({
        Name = "GachaBanner",
        Text = "Banner",
        Options = {"Haki"},  -- Add more as we discover them
        Parent = page,
    })
    
    UI.Toggle({
        Name = "AutoGacha",
        Text = "Auto Gacha Roll",
        Description = "Rolls gacha automatically",
        Parent = page,
        Callback = function(enabled)
            HubState.ModuleStates.AutoGacha = enabled
            if enabled then
                local loopId = Debounce.StartLoop("autogacha")
                task.spawn(function()
                    while Debounce.IsActive("autogacha", loopId) and HubState.ModuleStates.AutoGacha do
                        local bannerDD = ContentPages["Gacha"]:FindFirstChild("GachaBanner")
                        local banner = bannerDD and bannerDD.GetValue() or "Haki"
                        
                        BridgeNet.GachaRoll(banner)
                        task.wait(HubState.ModuleStates.GachaDelay or 1)
                    end
                end)
                NotificationSystem.Show("Auto Gacha", "Rolling!", "success")
            else
                Debounce.StopLoop("autogacha")
            end
        end,
    })
    
    UI.Slider({
        Name = "GachaDelay",
        Text = "Delay Between Rolls",
        Min = 0.5,
        Max = 5,
        Step = 0.5,
        Default = 1,
        Suffix = "s",
        Parent = page,
        Callback = function(val)
            HubState.ModuleStates.GachaDelay = val
        end,
    })
    
    UI.Separator({Parent = page})
    
    -- Stars/Pets section
    UI.SectionHeader({Text = "STARS / PETS", Color = Theme.Warning, Parent = page})
    
    UI.Dropdown({
        Name = "StarsBanner",
        Text = "Banner",
        Options = {"Dressrosa"},  -- Add more as we discover them
        Parent = page,
    })
    
    UI.Dropdown({
        Name = "StarsQuantity",
        Text = "Quantity",
        Options = {"1", "4"},
        Default = "1",
        Parent = page,
    })
    
    UI.Toggle({
        Name = "AutoStars",
        Text = "Auto Stars Roll",
        Description = "Opens stars/pets automatically",
        Parent = page,
        Callback = function(enabled)
            HubState.ModuleStates.AutoStars = enabled
            if enabled then
                local loopId = Debounce.StartLoop("autostars")
                task.spawn(function()
                    while Debounce.IsActive("autostars", loopId) and HubState.ModuleStates.AutoStars do
                        local bannerDD = ContentPages["Gacha"]:FindFirstChild("StarsBanner")
                        local qtyDD = ContentPages["Gacha"]:FindFirstChild("StarsQuantity")
                        
                        local banner = bannerDD and bannerDD.GetValue() or "Dressrosa"
                        local qty = qtyDD and tonumber(qtyDD.GetValue()) or 1
                        
                        BridgeNet.StarsOpen(banner, qty)
                        task.wait(HubState.ModuleStates.GachaDelay or 1)
                    end
                end)
                NotificationSystem.Show("Auto Stars", "Opening stars!", "success")
            else
                Debounce.StopLoop("autostars")
            end
        end,
    })
end

-- ══════════════════════════════════════
-- MODULE: QUESTS
-- ══════════════════════════════════════
local function setupQuestsTab()
    local page = ContentPages["Quests"]
    if not page then return end
    
    UI.SectionHeader({Text = "QUEST SYSTEM", Color = Theme.Warning, Parent = page})
    
    UI.Text({
        Text = "Use SimpleSpy to capture quest RemoteEvents.\nPaste data in spy/quests.md and let me know to configure.",
        Size = UDim2.new(1, -24, 0, 40),
        Color = Theme.TextMuted,
        Font = Theme.FontLight,
        TextSize = 11,
        Wrapped = true,
        Parent = page,
    })
    
    -- Position tracker (useful for quests)
    UI.Button({
        Name = "CopyPosition",
        Text = "Copy Current Position",
        Size = UDim2.new(1, -24, 0, 36),
        Parent = page,
        Callback = function()
            local pos = PlayerHelper.GetPosition()
            local text = string.format("Vector3.new(%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z)
            if setclipboard then
                setclipboard(text)
                NotificationSystem.Show("Position", "Copied: " .. text, "success")
            else
                NotificationSystem.Show("Position", text, "info")
            end
        end,
    })
end

-- ══════════════════════════════════════
-- MODULE: REWARDS
-- ══════════════════════════════════════
local function setupRewardsTab()
    local page = ContentPages["Rewards"]
    if not page then return end
    
    -- Time Rewards
    UI.SectionHeader({Text = "TIME REWARDS", Color = Theme.Info, Parent = page})
    
    UI.Toggle({
        Name = "AutoTimeRewards",
        Text = "Auto Claim Time Rewards",
        Description = "Collects time rewards automatically",
        Parent = page,
        Callback = function(enabled)
            HubState.ModuleStates.AutoTimeRewards = enabled
            if enabled then
                local loopId = Debounce.StartLoop("autotimerewards")
                task.spawn(function()
                    while Debounce.IsActive("autotimerewards", loopId) and HubState.ModuleStates.AutoTimeRewards do
                        -- Try to collect rewards 1-10
                        for i = 1, 10 do
                            BridgeNet.ClaimTimeReward(i)
                            task.wait(0.3)
                        end
                        task.wait(30) -- Check every 30s
                    end
                end)
                NotificationSystem.Show("Time Rewards", "Auto claim enabled!", "success")
            else
                Debounce.StopLoop("autotimerewards")
            end
        end,
    })
    
    UI.Separator({Parent = page})
    
    -- Achievements
    UI.SectionHeader({Text = "ACHIEVEMENTS", Color = Theme.Warning, Parent = page})
    
    -- Trial Achievements (I through X)
    local trialTypes = {"Trial Easy", "Trial Medium", "Trial Hard", "Trial Insane", "Trial Nightmare"}
    local romanNums = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}
    
    UI.Dropdown({
        Name = "AchievementType",
        Text = "Achievement Type",
        Options = trialTypes,
        Default = "Trial Easy",
        Parent = page,
    })
    
    UI.Button({
        Name = "ClaimAllAchievements",
        Text = "🏆 Claim All (I → X)",
        Size = UDim2.new(1, -24, 0, 36),
        Parent = page,
        Callback = function()
            local typeDD = ContentPages["Rewards"]:FindFirstChild("AchievementType")
            local trialType = typeDD and typeDD.GetValue() or "Trial Easy"
            
            NotificationSystem.Show("Achievements", "Collecting " .. trialType .. "...", "info")
            
            for _, num in ipairs(romanNums) do
                local name = trialType .. " " .. num
                BridgeNet.ClaimAchievement(name)
                task.wait(0.3)
            end
            
            NotificationSystem.Show("Achievements", "Done!", "success")
        end,
    })
    
    UI.Separator({Parent = page})
    
    -- Follow Rewards
    UI.SectionHeader({Text = "FOLLOW REWARDS", Color = Theme.Success, Parent = page})
    
    UI.Button({
        Name = "VerifyFollowBtn",
        Text = "Verify Follow Rewards",
        Size = UDim2.new(1, -24, 0, 36),
        Color = Theme.Success,
        HoverColor = Color3.fromRGB(67, 200, 110),
        Parent = page,
        Callback = function()
            BridgeNet.VerifyFollow()
            NotificationSystem.Show("Follow Rewards", "Verification sent!", "success")
        end,
    })
end

-- ══════════════════════════════════════
-- MODULE: MISC
-- ══════════════════════════════════════
local function setupMiscTab()
    local page = ContentPages["Misc"]
    if not page then return end
    
    UI.SectionHeader({Text = "CHARACTER", Color = Theme.AccentLight, Parent = page})
    
    -- WalkSpeed
    UI.Slider({
        Name = "WalkSpeed",
        Text = "WalkSpeed",
        Min = 16,
        Max = 200,
        Step = 4,
        Default = 16,
        Parent = page,
        Callback = function(val)
            PlayerHelper.SetWalkSpeed(val)
        end,
    })
    
    -- JumpPower
    UI.Slider({
        Name = "JumpPower",
        Text = "JumpPower",
        Min = 50,
        Max = 300,
        Step = 10,
        Default = 50,
        Parent = page,
        Callback = function(val)
            PlayerHelper.SetJumpPower(val)
        end,
    })
    
    -- Anti AFK
    UI.Toggle({
        Name = "AntiAFK",
        Text = "Anti-AFK",
        Description = "Prevents AFK kick",
        Default = true,
        Parent = page,
        Callback = function(enabled)
            HubState.ModuleStates.AntiAFK = enabled
        end,
    })
    
    UI.Separator({Parent = page})
    
    -- Stats Display
    UI.SectionHeader({Text = "PLAYER STATS", Color = Theme.AccentLight, Parent = page})
    
    local statsContainer = UI.Frame({
        Name = "Stats",
        Size = UDim2.new(1, -24, 0, 80),
        Color = Theme.BackgroundTertiary,
        Parent = page,
    })
    
    local statsPadding = Instance.new("UIPadding")
    statsPadding.PaddingLeft = UDim.new(0, 12)
    statsPadding.PaddingTop = UDim.new(0, 8)
    statsPadding.Parent = statsContainer
    
    local powerLabel = UI.Text({
        Name = "Power",
        Text = "⚡ Power: ...",
        Size = UDim2.new(1, -12, 0, 20),
        Color = Theme.TextPrimary,
        TextSize = 13,
        Parent = statsContainer,
    })
    
    local crystalsLabel = UI.Text({
        Name = "Crystals",
        Text = "💎 Crystals: ...",
        Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.new(0, 0, 0, 24),
        Color = Theme.AccentLight,
        TextSize = 13,
        Parent = statsContainer,
    })
    
    local awakeningLabel = UI.Text({
        Name = "Awakening",
        Text = "🔮 Awakening: ...",
        Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.new(0, 0, 0, 48),
        Color = Theme.Warning,
        TextSize = 13,
        Parent = statsContainer,
    })
    
    -- Update stats
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                local power = leaderstats:FindFirstChild("Power")
                local crystals = leaderstats:FindFirstChild("Crystals")
                local awakening = leaderstats:FindFirstChild("Awakening")
                
                if power then powerLabel.Text = "⚡ Power: " .. tostring(power.Value) end
                if crystals then crystalsLabel.Text = "💎 Crystals: " .. tostring(crystals.Value) end
                if awakening then awakeningLabel.Text = "🔮 Awakening: " .. tostring(awakening.Value) end
            end
            task.wait(1)
        end
    end)
    
    UI.Separator({Parent = page})
    
    -- Hub info
    UI.SectionHeader({Text = "HUB INFO", Color = Theme.TextMuted, Parent = page})
    
    UI.Text({
        Text = "Angel HUB v1.0 | World Fighters | Toggle: RCtrl",
        Size = UDim2.new(1, -24, 0, 20),
        Color = Theme.TextMuted,
        Font = Theme.FontLight,
        TextSize = 11,
        Parent = page,
    })
    
    -- Destroy Hub button
    UI.Button({
        Name = "DestroyHub",
        Text = "Destroy Hub",
        Size = UDim2.new(1, -24, 0, 36),
        Color = Theme.Error,
        HoverColor = Color3.fromRGB(200, 50, 50),
        Parent = page,
        Callback = function()
            destroyHub()
        end,
    })
end

-- ══════════════════════════════════════
-- ANTI-AFK SYSTEM
-- ══════════════════════════════════════
local function setupAntiAFK()
    local VIM = game:GetService("VirtualInputManager")
    
    table.insert(HubState.Connections, task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            if HubState.ModuleStates.AntiAFK then
                pcall(function()
                    VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.1)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
            end
            task.wait(60)
        end
    end))
end

-- ══════════════════════════════════════
-- DESTROY
-- ══════════════════════════════════════
function destroyHub()
    -- Stop all loops
    Debounce.ResetAll()
    
    -- Disconnect all connections
    for _, conn in ipairs(HubState.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    
    -- Destroy GUI
    if ScreenGui then
        tween(MainFrame, 0.3, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
        task.wait(0.35)
        ScreenGui:Destroy()
    end
    
    -- Clear globals
    if getgenv then
        getgenv().AngelHUB_Loaded = false
        getgenv().AngelHUB_Destroy = nil
    end
    
    print("[Angel HUB] Destroyed!")
end

-- ══════════════════════════════════════
-- INITIALIZE
-- ══════════════════════════════════════

local function init()
    print("\n╔══════════════════════════════════════╗")
    print("║       🔥 ANGEL HUB v1.0 🔥          ║")
    print("║       World Fighters Edition         ║")
    print("╚══════════════════════════════════════╝\n")
    
    -- Build the UI
    buildHub()
    
    -- Setup all tabs
    setupMainTab()
    setupGamemodesTab()
    setupGachaTab()
    setupQuestsTab()
    setupRewardsTab()
    setupMiscTab()
    
    -- Setup anti-afk
    HubState.ModuleStates.AntiAFK = true
    setupAntiAFK()
    
    -- Register globals
    if getgenv then
        getgenv().AngelHUB_Loaded = true
        getgenv().AngelHUB_Destroy = destroyHub
    end
    
    -- Welcome notification
    task.wait(0.5)
    NotificationSystem.Show("Angel HUB", "Hub loaded! Toggle: RCtrl", "success", 4)
    
    print("[Angel HUB] Loaded successfully!")
    print("[Angel HUB] Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))
    print("[Angel HUB] Player: " .. LocalPlayer.Name)
    print("[Angel HUB] Toggle: RightControl")
end

-- RUN!
init()
