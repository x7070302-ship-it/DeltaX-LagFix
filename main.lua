--[[
    ========================================================
    DELTA X - LAG FIX
    Version: 2.9
    Author: Minh Tiến
    Client-side FPS / Graphics / Performance Utility
    Mobile First • Liquid Glass • Smart Cleanup Engine • Aura
    Dynamic Island Premium (no floating toggle)
    NO ESP • NO FLY • NO AIMBOT • NO SPEED • NO TELEPORT • NO GAMEPLAY CHEAT
    ========================================================
]]

repeat task.wait() until game:IsLoaded()

--------------------------------------------------
-- 0. DUPLICATE RUN PROTECTION + SESSION GUARD
--------------------------------------------------
if _G.DeltaXLagFix_Running then
    pcall(function()
        if type(_G.DeltaXLagFix_Cleanup) == "function" then
            _G.DeltaXLagFix_Cleanup()
        end
    end)
    task.wait(0.2)
end
_G.DeltaXLagFix_Running = true

--------------------------------------------------
-- 1. SERVICES
--------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Stats             = game:GetService("Stats")
local ContentProvider   = game:GetService("ContentProvider")
local SoundService      = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- 2. CONFIGURATION
--------------------------------------------------
local VERSION   = "2.9"
local AVATAR_ID = "rbxassetid://81764145447029"
local BANNER_ID = "rbxassetid://108458220171454"
local FPS_TARGET = 120

local Config = {
    ShowFPS            = true,
    ShowPing           = true,
    Notifications      = true,
    Animations         = true,
    Preset             = "Cân bằng",
    Optimized          = false,
    AuraEnabled        = false,
    AuraStyle          = "Soft",
    AuraColor          = Color3.fromRGB(0, 170, 255),
    DistanceNear       = 80,
    DistanceMid        = 160,
    DistanceFar        = 260,
    MusicVolume        = 0.45,
    MusicLoop          = true,
    SmartMode          = "BALANCED",
    SmartBatchSize     = 70,
    SmartCooldown       = 3.0,
    FPSUpdateInterval  = 0.85,
}

--------------------------------------------------
-- 3. CONNECTION + CLEANUP MANAGER
--------------------------------------------------
local Connections = {}
local CharacterConnections = {}

local function register(conn)
    if conn then table.insert(Connections, conn) end
    return conn
end

local function disconnectAll()
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Connections)
    for _, c in ipairs(CharacterConnections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(CharacterConnections)
end

local function safe(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    return ok, a, b, c
end

local function tween(obj, props, duration, style, dir)
    if not obj or not obj.Parent then return end
    if not Config.Animations then
        for k, v in pairs(props) do
            safe(function() obj[k] = v end)
        end
        return
    end
    safe(function()
        TweenService:Create(obj, TweenInfo.new(
            duration or 0.25,
            style or Enum.EasingStyle.Quad,
            dir or Enum.EasingDirection.Out
        ), props):Play()
    end)
end

local function applyRobloxImage(obj, assetId)
    if not obj or not assetId then return end
    obj.Image = assetId
    obj.ScaleType = Enum.ScaleType.Crop
    obj.ImageTransparency = 0
    task.spawn(function()
        local loaded = false
        pcall(function()
            ContentProvider:PreloadAsync({obj})
            loaded = obj.IsLoaded
        end)
        if not loaded and obj.Parent then
            pcall(function()
                local id = string.match(assetId, "%d+")
                if id then
                    obj.Image = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
                end
            end)
        end
    end)
end

local function setFPSCap(enabled)
    if typeof(setfpscap) == "function" then
        local ok = pcall(function()
            setfpscap(enabled and FPS_TARGET or 60)
        end)
        return ok
    end
    return false
end

--------------------------------------------------
-- 4. GUI PARENT
--------------------------------------------------
local function getGuiParent()
    local parent
    safe(function()
        if typeof(gethui) == "function" then
            parent = gethui()
        end
    end)
    if not parent then
        safe(function() parent = game:GetService("CoreGui") end)
    end
    if not parent then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    return parent
end

local GUI_PARENT = getGuiParent()

do
    local old = GUI_PARENT:FindFirstChild("DeltaX_LagFix")
    if old then pcall(function() old:Destroy() end) end
end

--------------------------------------------------
-- 5. STATE + RESTORE ENGINE
--------------------------------------------------
local Original = {
    Lighting   = {},
    Terrain    = {},
    Effects    = {},
    CastShadow = {},
}

local Counts = {
    Scanned   = 0,
    Particles = 0,
    Trails    = 0,
    Beams     = 0,
    PostFX    = 0,
    FireSmoke = 0,
    Shadows   = 0,
}

local FeatureState = {
    Particles = false,
    Trails    = false,
    Beams     = false,
    PostFX    = false,
    FireSmoke = false,
    Shadows   = false,
    Terrain   = false,
}

local SmartOriginal = {}
local SmartProcessed = {}

safe(function()
    Original.Lighting.GlobalShadows            = Lighting.GlobalShadows
    Original.Lighting.Brightness               = Lighting.Brightness
    Original.Lighting.EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale
    Original.Lighting.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
end)

safe(function()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        Original.Terrain.WaterWaveSize     = terrain.WaterWaveSize
        Original.Terrain.WaterWaveSpeed    = terrain.WaterWaveSpeed
        Original.Terrain.WaterReflectance  = terrain.WaterReflectance
        Original.Terrain.WaterTransparency = terrain.WaterTransparency
        Original.Terrain.Decoration        = terrain.Decoration
    end
end)

local POSTFX_CLASSES = {
    BloomEffect = true, BlurEffect = true, SunRaysEffect = true,
    ColorCorrectionEffect = true, DepthOfFieldEffect = true,
}

local VISUAL_CLASSES = {
    ParticleEmitter = "Particles",
    Trail           = "Trails",
    Beam            = "Beams",
    Fire            = "FireSmoke",
    Smoke           = "FireSmoke",
    Sparkles        = "FireSmoke",
}

local function rememberEnabled(obj)
    if Original.Effects[obj] == nil then
        Original.Effects[obj] = obj.Enabled
    end
end

local function rememberShadow(obj)
    if Original.CastShadow[obj] == nil then
        Original.CastShadow[obj] = obj.CastShadow
    end
end

local function disableObject(obj, feature)
    if not obj or not obj.Parent then return false end
    if feature == "PostFX" and POSTFX_CLASSES[obj.ClassName] then
        rememberEnabled(obj)
        safe(function() obj.Enabled = false end)
        return true
    end
    local typeName = VISUAL_CLASSES[obj.ClassName]
    if typeName == feature then
        rememberEnabled(obj)
        safe(function() obj.Enabled = false end)
        return true
    end
    if feature == "Shadows" and obj:IsA("BasePart") then
        rememberShadow(obj)
        safe(function() obj.CastShadow = false end)
        return true
    end
    return false
end

local function scanAndDisable(feature)
    Counts.Scanned = 0
    local count = 0
    safe(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            Counts.Scanned += 1
            if disableObject(obj, feature) then count += 1 end
        end
    end)
    for _, obj in ipairs(Lighting:GetChildren()) do
        if feature == "PostFX" and POSTFX_CLASSES[obj.ClassName] then
            if disableObject(obj, feature) then count += 1 end
        end
    end
    if feature == "Particles" then Counts.Particles = count
    elseif feature == "Trails" then Counts.Trails = count
    elseif feature == "Beams" then Counts.Beams = count
    elseif feature == "PostFX" then Counts.PostFX = count
    elseif feature == "FireSmoke" then Counts.FireSmoke = count
    elseif feature == "Shadows" then Counts.Shadows = count end
end

local function setLightingLow()
    safe(function() Lighting.GlobalShadows = false end)
    safe(function()
        Lighting.EnvironmentDiffuseScale  = 0
        Lighting.EnvironmentSpecularScale = 0
    end)
end

local function setTerrainLow()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    safe(function()
        terrain.WaterWaveSize    = 0
        terrain.WaterWaveSpeed   = 0
        terrain.WaterReflectance = 0
        terrain.Decoration       = false
    end)
end

local function setFeature(feature, enabled)
    FeatureState[feature] = enabled
    if enabled then
        scanAndDisable(feature)
        if feature == "Terrain" then setTerrainLow()
        elseif feature == "Shadows" then
            setLightingLow()
            scanAndDisable("Shadows")
        end
    else
        for obj, oldState in pairs(Original.Effects) do
            if obj and obj.Parent then
                local matches = (feature == "PostFX" and POSTFX_CLASSES[obj.ClassName])
                             or (VISUAL_CLASSES[obj.ClassName] == feature)
                if matches then safe(function() obj.Enabled = oldState end) end
            end
        end
        if feature == "Shadows" then
            for obj, oldState in pairs(Original.CastShadow) do
                if obj and obj.Parent then
                    safe(function() obj.CastShadow = oldState end)
                end
            end
            safe(function()
                Lighting.GlobalShadows            = Original.Lighting.GlobalShadows
                Lighting.EnvironmentDiffuseScale  = Original.Lighting.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = Original.Lighting.EnvironmentSpecularScale
            end)
        end
        if feature == "Terrain" then
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                safe(function()
                    terrain.WaterWaveSize     = Original.Terrain.WaterWaveSize
                    terrain.WaterWaveSpeed    = Original.Terrain.WaterWaveSpeed
                    terrain.WaterReflectance  = Original.Terrain.WaterReflectance
                    terrain.WaterTransparency = Original.Terrain.WaterTransparency
                    terrain.Decoration        = Original.Terrain.Decoration
                end)
            end
        end
    end
end

local function restoreAll()
    for obj, oldValue in pairs(SmartOriginal) do
        if obj and obj.Parent then
            pcall(function() obj.LocalTransparencyModifier = oldValue end)
        end
    end
    table.clear(SmartOriginal)
    table.clear(SmartProcessed)

    for obj, oldState in pairs(Original.Effects) do
        if obj and obj.Parent then safe(function() obj.Enabled = oldState end) end
    end
    for obj, oldState in pairs(Original.CastShadow) do
        if obj and obj.Parent then safe(function() obj.CastShadow = oldState end) end
    end
    safe(function()
        Lighting.GlobalShadows            = Original.Lighting.GlobalShadows
        Lighting.Brightness               = Original.Lighting.Brightness
        Lighting.EnvironmentDiffuseScale  = Original.Lighting.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = Original.Lighting.EnvironmentSpecularScale
    end)
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        safe(function()
            terrain.WaterWaveSize     = Original.Terrain.WaterWaveSize
            terrain.WaterWaveSpeed    = Original.Terrain.WaterWaveSpeed
            terrain.WaterReflectance  = Original.Terrain.WaterReflectance
            terrain.WaterTransparency = Original.Terrain.WaterTransparency
            terrain.Decoration        = Original.Terrain.Decoration
        end)
    end
    for k in pairs(FeatureState) do FeatureState[k] = false end
    Config.Optimized = false
end

--------------------------------------------------
-- 6. SMART CLEANUP ENGINE
--------------------------------------------------
local SmartCleanup = {
    Enabled  = false,
    Mode     = "BALANCED",
    Radius   = 120,
    Busy     = false,
    LastScan = 0,
}

local SmartStats = {Scanned = 0, Affected = 0, Faded = 0, Hidden = 0}

local SAFE_KEYWORDS = {
    "decor","decoration","foliage","leaf","leaves","grass","flower","bush",
    "tree","rock","pebble","detail","scenery","background","backdrop",
    "debris","junk","trash","vfx","effect","visual","dust","particle",
    "prop","ornament","plant","shrub"
}

local function hasKeyword(name, list)
    name = string.lower(name or "")
    for _, key in ipairs(list) do
        if string.find(name, key, 1, true) then return true end
    end
    return false
end

local function isGameplaySensitive(obj)
    if not obj or not obj.Parent then return true end
    if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then return true end
    if obj:IsA("Seat") or obj:IsA("VehicleSeat") then return true end
    if obj:FindFirstChildOfClass("Humanoid") then return true end
    if obj:FindFirstChildOfClass("ProximityPrompt") then return true end
    if obj:FindFirstChildOfClass("ClickDetector") then return true end
    if obj:FindFirstChildOfClass("TouchInterest") then return true end
    local current = obj.Parent
    for _ = 1, 6 do
        if not current then break end
        if current:IsA("Tool") or (current:IsA("Model") and current:FindFirstChildOfClass("Humanoid")) then
            return true
        end
        current = current.Parent
    end
    return false
end

local function isSmartCandidate(obj, rootPos, mode)
    if not obj:IsA("BasePart") or obj:IsA("Terrain") then return false end
    if isGameplaySensitive(obj) then return false end
    if obj.CanCollide then return false end
    if obj.Transparency >= 0.92 then return false end
    if SmartProcessed[obj] then return false end

    local named = hasKeyword(obj.Name, SAFE_KEYWORDS)
    local far = false
    if rootPos then
        local ok, dist = pcall(function() return (obj.Position - rootPos).Magnitude end)
        if ok then
            if mode == "SAFE" then
                far = dist >= (SmartCleanup.Radius + 50)
            elseif mode == "BALANCED" then
                far = dist >= SmartCleanup.Radius
            else
                far = dist >= math.max(55, SmartCleanup.Radius - 35)
            end
        end
    end

    if mode == "SAFE" then
        return named
    else
        return named or far
    end
end

local function rememberSmart(obj)
    if SmartOriginal[obj] == nil then
        SmartOriginal[obj] = obj.LocalTransparencyModifier
    end
end

local function smartApplyObject(obj, mode, rootPos)
    if not isSmartCandidate(obj, rootPos, mode) then return false end
    rememberSmart(obj)
    SmartProcessed[obj] = true

    if mode == "AGGRESSIVE" then
        obj.LocalTransparencyModifier = 1
        SmartStats.Hidden += 1
    else
        obj.LocalTransparencyModifier = math.max(obj.LocalTransparencyModifier, 0.62)
        SmartStats.Faded += 1
    end
    SmartStats.Affected += 1
    return true
end

local function smartCleanupBatch(mode)
    if SmartCleanup.Busy then return 0 end
    local now = os.clock()
    if now - SmartCleanup.LastScan < Config.SmartCooldown then return 0 end
    SmartCleanup.Busy = true
    SmartCleanup.LastScan = now

    SmartStats.Scanned = 0
    SmartStats.Affected = 0
    SmartStats.Faded = 0
    SmartStats.Hidden = 0

    local rootPos
    safe(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then rootPos = root.Position end
    end)

    local batch = 0
    local maxBatch = Config.SmartBatchSize or 70

    safe(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if batch >= maxBatch then break end
            SmartStats.Scanned += 1
            if smartApplyObject(obj, mode or SmartCleanup.Mode, rootPos) then
                batch += 1
            end
        end
    end)

    SmartCleanup.Busy = false
    return SmartStats.Affected
end

local function restoreSmartCleanup()
    local restored = 0
    for obj, oldValue in pairs(SmartOriginal) do
        if obj and obj.Parent then
            local ok = pcall(function() obj.LocalTransparencyModifier = oldValue end)
            if ok then restored += 1 end
        end
    end
    table.clear(SmartOriginal)
    table.clear(SmartProcessed)
    SmartStats.Affected = 0
    return restored
end

local function setSmartCleanup(enabled, mode)
    SmartCleanup.Enabled = enabled
    if mode then
        SmartCleanup.Mode = mode
        Config.SmartMode = mode
    end
    if not enabled then
        restoreSmartCleanup()
        return
    end
    smartCleanupBatch(SmartCleanup.Mode)
end

--------------------------------------------------
-- 7. OPTIMIZE + PRESETS
--------------------------------------------------
local function optimize120()
    for feature in pairs(FeatureState) do FeatureState[feature] = true end
    for k in pairs(Counts) do Counts[k] = 0 end

    safe(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            Counts.Scanned += 1
            local feature = VISUAL_CLASSES[obj.ClassName]
            if feature then
                if disableObject(obj, feature) then
                    if feature == "Particles" then Counts.Particles += 1
                    elseif feature == "Trails" then Counts.Trails += 1
                    elseif feature == "Beams" then Counts.Beams += 1
                    elseif feature == "FireSmoke" then Counts.FireSmoke += 1 end
                end
            elseif obj:IsA("BasePart") and FeatureState.Shadows then
                if disableObject(obj, "Shadows") then Counts.Shadows += 1 end
            end
        end
    end)

    for _, obj in ipairs(Lighting:GetChildren()) do
        if POSTFX_CLASSES[obj.ClassName] then
            if disableObject(obj, "PostFX") then Counts.PostFX += 1 end
        end
    end

    setLightingLow()
    setTerrainLow()
    FeatureState.Terrain = true
    FeatureState.Shadows = true
    FeatureState.PostFX = true

    local ok = setFPSCap(true)
    Config.Optimized = true
    return ok
end

local function applyPreset(name)
    Config.Preset = name
    if name == "Cân bằng" then
        setFeature("Particles", true)
        setFeature("Trails", true)
        setFeature("Beams", false)
        setFeature("PostFX", true)
        setFeature("FireSmoke", true)
        setFeature("Shadows", false)
        setFeature("Terrain", false)
        setSmartCleanup(true, "BALANCED")
        setFPSCap(false)
    elseif name == "Hiệu năng" then
        setFeature("Particles", true)
        setFeature("Trails", true)
        setFeature("Beams", true)
        setFeature("PostFX", true)
        setFeature("FireSmoke", true)
        setFeature("Shadows", true)
        setFeature("Terrain", true)
        setSmartCleanup(true, "BALANCED")
        setFPSCap(true)
    elseif name == "Siêu nhẹ" then
        setFeature("Particles", true)
        setFeature("Trails", true)
        setFeature("Beams", true)
        setFeature("PostFX", true)
        setFeature("FireSmoke", true)
        setFeature("Shadows", true)
        setFeature("Terrain", true)
        setSmartCleanup(true, "AGGRESSIVE")
        setFPSCap(true)
    end
    Config.Optimized = true
end

--------------------------------------------------
-- 8. AURA SYSTEM
--------------------------------------------------
local Aura = {
    Highlight = nil,
    PulseConn = nil,
}

local function cleanupAura()
    if Aura.PulseConn then
        pcall(function() Aura.PulseConn:Disconnect() end)
        Aura.PulseConn = nil
    end
    if Aura.Highlight then
        pcall(function() Aura.Highlight:Destroy() end)
        Aura.Highlight = nil
    end
end

local function applyAuraToCharacter(char)
    if not char then return end
    cleanupAura()

    local hl = Instance.new("Highlight")
    hl.Name = "DeltaX_Aura"
    hl.Adornee = char
    hl.FillColor = Config.AuraColor
    hl.OutlineColor = Config.AuraColor
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    if Config.AuraStyle == "Soft" then
        hl.FillTransparency = 0.78
        hl.OutlineTransparency = 0.35
    elseif Config.AuraStyle == "Neon" then
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0.05
    else -- Pulse
        hl.FillTransparency = 0.7
        hl.OutlineTransparency = 0.25
        local t = 0
        Aura.PulseConn = RunService.Heartbeat:Connect(function(dt)
            t += dt * 2.2
            local s = (math.sin(t) + 1) * 0.5
            hl.FillTransparency = 0.55 + s * 0.3
            hl.OutlineTransparency = 0.1 + s * 0.35
        end)
        table.insert(CharacterConnections, Aura.PulseConn)
    end

    Aura.Highlight = hl
end

local function setAura(enabled, style, color)
    Config.AuraEnabled = enabled
    if style then Config.AuraStyle = style end
    if color then Config.AuraColor = color end

    if not enabled then
        cleanupAura()
        return
    end

    local char = LocalPlayer.Character
    if char then
        applyAuraToCharacter(char)
    end
end

register(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.4)
    if Config.AuraEnabled then
        applyAuraToCharacter(char)
    end
end))

--------------------------------------------------
-- 9. MUSIC
--------------------------------------------------
local MusicSound = nil

local function stopMusic()
    if MusicSound then
        pcall(function() MusicSound:Stop() end)
        pcall(function() MusicSound:Destroy() end)
        MusicSound = nil
    end
end

local function playMusic(soundId)
    stopMusic()
    local s = Instance.new("Sound")
    s.Name = "DeltaX_Music"
    s.SoundId = "rbxassetid://" .. tostring(soundId)
    s.Volume = Config.MusicVolume
    s.Looped = Config.MusicLoop
    s.Parent = SoundService
    local ok = pcall(function() s:Play() end)
    if ok then
        MusicSound = s
        return true
    else
        pcall(function() s:Destroy() end)
        return false
    end
end

--------------------------------------------------
-- 10. COLORS + HELPERS
--------------------------------------------------
local COLORS = {
    BG       = Color3.fromRGB(6, 10, 18),
    PANEL    = Color3.fromRGB(10, 18, 32),
    PANEL2   = Color3.fromRGB(14, 26, 46),
    BLUE     = Color3.fromRGB(0, 120, 255),
    CYAN     = Color3.fromRGB(0, 200, 255),
    TEXT     = Color3.fromRGB(235, 245, 255),
    MUTED    = Color3.fromRGB(140, 165, 195),
    GREEN    = Color3.fromRGB(60, 220, 130),
    YELLOW   = Color3.fromRGB(255, 200, 60),
    RED      = Color3.fromRGB(255, 80, 90),
    WHITE    = Color3.fromRGB(255, 255, 255),
}

local function new(class, props, parent)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = obj
    return c
end

local function stroke(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.CYAN
    s.Transparency = transparency or 0.5
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

local function label(parent, text, size, color, bold)
    local l = new("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or COLORS.TEXT,
        TextSize = size or 12,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, size + 4),
    }, parent)
    return l
end

local function button(parent, text, callback, width)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(width or 90, 28),
        BackgroundColor3 = COLORS.BLUE,
        Text = text,
        TextColor3 = COLORS.TEXT,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, parent)
    corner(b, 8)
    stroke(b, COLORS.CYAN, 0.6, 1)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function card(parent, height)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 80),
        BackgroundColor3 = COLORS.PANEL,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, parent)
    corner(f, 12)
    stroke(f, Color3.fromRGB(40, 90, 160), 0.7, 1)
    return f
end

local function section(parent, title, desc)
    local s = new("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
    }, parent)
    local t = label(s, title, 14, COLORS.TEXT, true)
    t.Position = UDim2.fromOffset(0, 2)
    t.Size = UDim2.new(1, 0, 0, 20)
    local d = label(s, desc or "", 10, COLORS.MUTED, false)
    d.Position = UDim2.fromOffset(0, 22)
    d.Size = UDim2.new(1, 0, 0, 16)
    return s
end

--------------------------------------------------
-- 11. SCREEN GUI + MAIN FRAME
--------------------------------------------------
local ScreenGui = new("ScreenGui", {
    Name = "DeltaX_LagFix",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    IgnoreGuiInset = true,
}, GUI_PARENT)

local Main = new("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(520, 400),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Visible = true,
    Active = true,
}, ScreenGui)

local MainScale = new("UIScale", {Scale = 1}, Main)

local MainGlass = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(8, 14, 26),
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
}, Main)
corner(MainGlass, 18)
stroke(MainGlass, Color3.fromRGB(0, 160, 255), 0.55, 1.4)

new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 24, 48)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 16, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 12, 24)),
    }),
    Rotation = 120,
}, MainGlass)

local MIN_W, MAX_W = 320, 700
local MIN_H, MAX_H = 300, 620

--------------------------------------------------
-- 12. HEADER
--------------------------------------------------
local Header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 72),
    BackgroundTransparency = 1,
    ZIndex = 5,
}, Main)

local BannerImage = new("ImageLabel", {
    Size = UDim2.new(1, 0, 0, 72),
    BackgroundTransparency = 1,
    Image = BANNER_ID,
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0.35,
    ZIndex = 1,
}, Header)
corner(BannerImage, 18)

local HeaderOverlay = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(4, 10, 22),
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    ZIndex = 2,
}, Header)
corner(HeaderOverlay, 18)

local Logo = new("ImageLabel", {
    Size = UDim2.fromOffset(42, 42),
    Position = UDim2.fromOffset(14, 15),
    BackgroundColor3 = Color3.fromRGB(8, 18, 34),
    Image = AVATAR_ID,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 3,
}, Header)
corner(Logo, 12)
stroke(Logo, COLORS.CYAN, 0.25, 1.5)

local Title = label(Header, "DELTA X", 16, COLORS.TEXT, true)
Title.Position = UDim2.fromOffset(66, 14)
Title.Size = UDim2.new(0, 180, 0, 22)
Title.ZIndex = 3

local Subtitle = label(Header, "Lag Fix v" .. VERSION .. " • Performance Utility", 11, COLORS.MUTED, false)
Subtitle.Position = UDim2.fromOffset(66, 36)
Subtitle.Size = UDim2.new(0, 240, 0, 16)
Subtitle.ZIndex = 3

local MinimizeBtn = new("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -72, 0, 21),
    BackgroundColor3 = COLORS.PANEL2,
    Text = "—",
    TextColor3 = COLORS.TEXT,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 4,
}, Header)
corner(MinimizeBtn, 9)
stroke(MinimizeBtn, COLORS.CYAN, 0.65, 1)

local CloseBtn = new("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -36, 0, 21),
    BackgroundColor3 = Color3.fromRGB(50, 18, 28),
    Text = "×",
    TextColor3 = COLORS.TEXT,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 4,
}, Header)
corner(CloseBtn, 9)
stroke(CloseBtn, Color3.fromRGB(255, 90, 110), 0.55, 1)

--------------------------------------------------
-- 13. DYNAMIC ISLAND (PREMIUM - NO FLOATING TOGGLE)
--------------------------------------------------
local IslandState = "HIDDEN" -- HIDDEN | COLLAPSED | EXPANDING | EXPANDED | COLLAPSING

local Island = new("Frame", {
    Name = "DeltaX_Island",
    Size = UDim2.fromOffset(132, 32),
    Position = UDim2.new(0.5, -66, 0, 14),
    BackgroundColor3 = Color3.fromRGB(5, 9, 16),
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 260,
    Active = true,
    ClipsDescendants = true,
}, ScreenGui)
corner(Island, 22)
local IslandStroke = stroke(Island, COLORS.CYAN, 0.48, 1.25)

local IslandGlow = new("Frame", {
    Size = UDim2.new(1, 18, 1, 18),
    Position = UDim2.fromOffset(-9, -9),
    BackgroundTransparency = 1,
    ZIndex = 259,
}, Island)
corner(IslandGlow, 30)
local GlowStroke = stroke(IslandGlow, Color3.fromRGB(140, 210, 255), 0.78, 1.8)

local IslandHighlight = new("Frame", {
    Size = UDim2.new(1, -6, 0, 12),
    Position = UDim2.fromOffset(3, 2),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.92,
    BorderSizePixel = 0,
    ZIndex = 261,
}, Island)
corner(IslandHighlight, 10)
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, IslandHighlight)

local IslandContent = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 262,
}, Island)

-- Collapsed content
local CollapsedIcon = label(IslandContent, "⚡", 14, COLORS.CYAN, true)
CollapsedIcon.Position = UDim2.fromOffset(12, 0)
CollapsedIcon.Size = UDim2.fromOffset(22, 32)
CollapsedIcon.TextXAlignment = Enum.TextXAlignment.Center

local CollapsedText = label(IslandContent, "Delta X • --", 12, COLORS.TEXT, true)
CollapsedText.Position = UDim2.fromOffset(34, 0)
CollapsedText.Size = UDim2.new(1, -42, 1, 0)
CollapsedText.TextXAlignment = Enum.TextXAlignment.Left

-- Expanded content
local ExpandedIcon = new("ImageLabel", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.fromOffset(12, 10),
    BackgroundTransparency = 1,
    Image = AVATAR_ID,
    ScaleType = Enum.ScaleType.Crop,
    Visible = false,
    ZIndex = 263,
}, IslandContent)
corner(ExpandedIcon, 999)
stroke(ExpandedIcon, COLORS.CYAN, 0.3, 1.2)

local ExpandedTitle = label(IslandContent, "Delta X Lag Fix", 13, COLORS.TEXT, true)
ExpandedTitle.Position = UDim2.fromOffset(48, 6)
ExpandedTitle.Size = UDim2.new(1, -160, 0, 18)
ExpandedTitle.Visible = false

local ExpandedSub = label(IslandContent, "Sẵn sàng • -- FPS", 10, COLORS.MUTED, false)
ExpandedSub.Position = UDim2.fromOffset(48, 24)
ExpandedSub.Size = UDim2.new(1, -160, 0, 16)
ExpandedSub.Visible = false

local ExpandedAction = new("TextButton", {
    Size = UDim2.fromOffset(72, 26),
    Position = UDim2.new(1, -150, 0.5, -13),
    BackgroundColor3 = COLORS.BLUE,
    Text = "Mở Menu",
    TextColor3 = COLORS.TEXT,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Visible = false,
    ZIndex = 264,
}, IslandContent)
corner(ExpandedAction, 8)
stroke(ExpandedAction, COLORS.CYAN, 0.45, 1)

local ExpandedClose = new("TextButton", {
    Size = UDim2.fromOffset(52, 26),
    Position = UDim2.new(1, -70, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(40, 18, 28),
    Text = "Đóng",
    TextColor3 = COLORS.TEXT,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Visible = false,
    ZIndex = 264,
}, IslandContent)
corner(ExpandedClose, 8)

local function SetIslandState(newState)
    if IslandState == newState then return end
    IslandState = newState

    if newState == "HIDDEN" then
        Island.Visible = false
        return
    end

    if newState == "COLLAPSED" then
        Island.Visible = true
        Island.Size = UDim2.fromOffset(132, 32)
        Island.Position = UDim2.new(0.5, -66, 0, 14)
        Island.BackgroundTransparency = 0.04
        IslandStroke.Transparency = 0.48
        GlowStroke.Transparency = 0.78

        CollapsedIcon.Visible = true
        CollapsedText.Visible = true
        ExpandedIcon.Visible = false
        ExpandedTitle.Visible = false
        ExpandedSub.Visible = false
        ExpandedAction.Visible = false
        ExpandedClose.Visible = false
        return
    end

    if newState == "EXPANDING" then
        Island.Visible = true
        CollapsedIcon.Visible = false
        CollapsedText.Visible = false

        tween(Island, {
            Size = UDim2.fromOffset(300, 48),
            Position = UDim2.new(0.5, -150, 0, 12),
            BackgroundTransparency = 0.02,
        }, 0.32, Enum.EasingStyle.Quint)
        tween(IslandStroke, {Transparency = 0.28}, 0.3)
        tween(GlowStroke, {Transparency = 0.65}, 0.3)

        task.delay(0.18, function()
            if IslandState ~= "EXPANDING" and IslandState ~= "EXPANDED" then return end
            ExpandedIcon.Visible = true
            ExpandedTitle.Visible = true
            ExpandedSub.Visible = true
            ExpandedAction.Visible = true
            ExpandedClose.Visible = true
            ExpandedIcon.ImageTransparency = 1
            ExpandedTitle.TextTransparency = 1
            ExpandedSub.TextTransparency = 1
            ExpandedAction.BackgroundTransparency = 1
            ExpandedAction.TextTransparency = 1
            ExpandedClose.BackgroundTransparency = 1
            ExpandedClose.TextTransparency = 1

            tween(ExpandedIcon, {ImageTransparency = 0}, 0.18)
            tween(ExpandedTitle, {TextTransparency = 0}, 0.18)
            tween(ExpandedSub, {TextTransparency = 0}, 0.18)
            tween(ExpandedAction, {BackgroundTransparency = 0, TextTransparency = 0}, 0.18)
            tween(ExpandedClose, {BackgroundTransparency = 0, TextTransparency = 0}, 0.18)

            IslandState = "EXPANDED"
        end)
        return
    end

    if newState == "COLLAPSING" then
        tween(ExpandedAction, {BackgroundTransparency = 1, TextTransparency = 1}, 0.12)
        tween(ExpandedClose, {BackgroundTransparency = 1, TextTransparency = 1}, 0.12)
        tween(ExpandedSub, {TextTransparency = 1}, 0.12)
        tween(ExpandedTitle, {TextTransparency = 1}, 0.12)
        tween(ExpandedIcon, {ImageTransparency = 1}, 0.12)

        task.delay(0.14, function()
            ExpandedIcon.Visible = false
            ExpandedTitle.Visible = false
            ExpandedSub.Visible = false
            ExpandedAction.Visible = false
            ExpandedClose.Visible = false

            tween(Island, {
                Size = UDim2.fromOffset(132, 32),
                Position = UDim2.new(0.5, -66, 0, 14),
                BackgroundTransparency = 0.04,
            }, 0.28, Enum.EasingStyle.Quint)
            tween(IslandStroke, {Transparency = 0.48}, 0.24)
            tween(GlowStroke, {Transparency = 0.78}, 0.24)

            task.delay(0.2, function()
                CollapsedIcon.Visible = true
                CollapsedText.Visible = true
                IslandState = "COLLAPSED"
            end)
        end)
        return
    end
end

local function onIslandTap()
    if IslandState == "COLLAPSED" then
        tween(Island, {Size = UDim2.fromOffset(124, 30)}, 0.07)
        task.delay(0.08, function()
            SetIslandState("EXPANDING")
        end)
    elseif IslandState == "EXPANDED" then
        SetIslandState("COLLAPSING")
    end
end

Island.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        onIslandTap()
    end
end)

--------------------------------------------------
-- 14. NOTIFICATION
--------------------------------------------------
local function notification(title, msg, kind)
    if not Config.Notifications then return end
    local color = COLORS.CYAN
    if kind == "success" then color = COLORS.GREEN
    elseif kind == "warning" then color = COLORS.YELLOW
    elseif kind == "error" then color = COLORS.RED end

    local n = new("Frame", {
        Size = UDim2.fromOffset(260, 56),
        Position = UDim2.new(1, -280, 0, 70),
        BackgroundColor3 = Color3.fromRGB(8, 14, 26),
        BackgroundTransparency = 0.08,
        ZIndex = 300,
    }, ScreenGui)
    corner(n, 12)
    stroke(n, color, 0.4, 1.3)

    local t = label(n, title, 12, COLORS.TEXT, true)
    t.Position = UDim2.fromOffset(14, 8)
    t.Size = UDim2.new(1, -28, 0, 18)

    local m = label(n, msg, 10, COLORS.MUTED, false)
    m.Position = UDim2.fromOffset(14, 28)
    m.Size = UDim2.new(1, -28, 0, 20)

    tween(n, {Position = UDim2.new(1, -280, 0, 80)}, 0.28, Enum.EasingStyle.Quint)
    task.delay(2.6, function()
        tween(n, {BackgroundTransparency = 1}, 0.3)
        task.delay(0.35, function()
            pcall(function() n:Destroy() end)
        end)
    end)
end

--------------------------------------------------
-- 15. SIDEBAR + PAGES
--------------------------------------------------
local Sidebar = new("ScrollingFrame", {
    Size = UDim2.new(0, 136, 1, -88),
    Position = UDim2.fromOffset(8, 80),
    BackgroundColor3 = Color3.fromRGB(5, 12, 22),
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = COLORS.CYAN,
    ClipsDescendants = true,
    ZIndex = 6,
}, Main)
corner(Sidebar, 14)
stroke(Sidebar, Color3.fromRGB(30, 80, 140), 0.75, 1)

new("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 8),
}, Sidebar)

local SideList = new("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)

local Pages = {}
local SideButtons = {}
local CurrentPage = "Trang chủ"

local function createPage(name)
    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, -156, 1, -88),
        Position = UDim2.fromOffset(150, 80),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.CYAN,
        Visible = false,
        ZIndex = 6,
    }, Main)
    new("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 12),
    }, page)
    Pages[name] = page
    return page
end

local function switchPage(name)
    if not Pages[name] then return end
    for n, p in pairs(Pages) do
        p.Visible = (n == name)
    end
    for n, data in pairs(SideButtons) do
        local active = (n == name)
        data.Button.BackgroundColor3 = active and Color3.fromRGB(0, 75, 170) or Color3.fromRGB(8, 16, 30)
        data.Icon.TextColor3 = active and COLORS.TEXT or COLORS.MUTED
        data.Text.TextColor3 = active and COLORS.TEXT or COLORS.MUTED
        data.Stroke.Transparency = active and 0.35 or 0.7
        data.Indicator.BackgroundTransparency = active and 0 or 1
    end
    CurrentPage = name
end

local function addSideButton(name, icon, order)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(8, 16, 30),
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order or 1,
        ZIndex = 7,
    }, Sidebar)
    corner(btn, 10)
    local st = stroke(btn, COLORS.CYAN, 0.7, 1)

    local indicator = new("Frame", {
        Size = UDim2.fromOffset(3, 22),
        Position = UDim2.fromOffset(2, 9),
        BackgroundColor3 = COLORS.CYAN,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, btn)
    corner(indicator, 2)

    local ic = label(btn, icon, 15, COLORS.MUTED, true)
    ic.Position = UDim2.fromOffset(12, 0)
    ic.Size = UDim2.fromOffset(24, 40)
    ic.TextXAlignment = Enum.TextXAlignment.Center
    ic.ZIndex = 8

    local tx = label(btn, name, 11, COLORS.MUTED, false)
    tx.Position = UDim2.fromOffset(38, 0)
    tx.Size = UDim2.new(1, -44, 1, 0)
    tx.ZIndex = 8

    btn.MouseButton1Click:Connect(function()
        switchPage(name)
    end)

    SideButtons[name] = {
        Button = btn,
        Icon = ic,
        Text = tx,
        Stroke = st,
        Indicator = indicator,
    }
end

addSideButton("Trang chủ", "⌂", 1)
addSideButton("FPS Boost", "⚡", 2)
addSideButton("Đồ họa", "◈", 3)
addSideButton("Hiệu ứng", "✧", 4)
addSideButton("Tiện ích", "✦", 5)
addSideButton("Nâng cao", "⚙", 6)
addSideButton("Cài đặt", "☰", 7)

--------------------------------------------------
-- 16. TOGGLE HELPER
--------------------------------------------------
local function makeToggle(parent, title, desc, default, callback)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = COLORS.PANEL,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, parent)
    corner(row, 11)
    stroke(row, Color3.fromRGB(35, 80, 140), 0.75, 1)

    local t = label(row, title, 12, COLORS.TEXT, true)
    t.Position = UDim2.fromOffset(12, 6)
    t.Size = UDim2.new(1, -80, 0, 18)

    local d = label(row, desc, 9, COLORS.MUTED, false)
    d.Position = UDim2.fromOffset(12, 26)
    d.Size = UDim2.new(1, -80, 0, 18)

    local track = new("Frame", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = default and COLORS.BLUE or Color3.fromRGB(40, 50, 70),
        BorderSizePixel = 0,
    }, row)
    corner(track, 11)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.fromOffset(2, 2),
        BackgroundColor3 = COLORS.WHITE,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 9)

    local state = default
    local function setState(v)
        state = v
        tween(track, {BackgroundColor3 = v and COLORS.BLUE or Color3.fromRGB(40, 50, 70)}, 0.18)
        tween(knob, {Position = v and UDim2.new(1, -20, 0.5, -9) or UDim2.fromOffset(2, 2)}, 0.18)
        if callback then callback(v) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            setState(not state)
        end
    end)
    return setState
end

--------------------------------------------------
-- 17. TRANG CHỦ
--------------------------------------------------
local Home = createPage("Trang chủ")
section(Home, "Tổng quan", "Theo dõi FPS • Ping • Trạng thái tối ưu")

local StatsRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundTransparency = 1,
}, Home)
local StatsLayout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, StatsRow)

local function statCard(title)
    local f = new("Frame", {
        Size = UDim2.new(1/3, -6, 1, 0),
        BackgroundColor3 = COLORS.PANEL,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
    }, StatsRow)
    corner(f, 12)
    stroke(f, Color3.fromRGB(40, 100, 180), 0.65, 1)
    local t = label(f, title, 9, COLORS.MUTED, false)
    t.Position = UDim2.fromOffset(10, 8)
    t.Size = UDim2.new(1, -16, 0, 14)
    local v = label(f, "--", 20, COLORS.TEXT, true)
    v.Position = UDim2.fromOffset(10, 26)
    v.Size = UDim2.new(1, -16, 0, 28)
    return v
end

local FPSValue    = statCard("CURRENT FPS")
local PingValue   = statCard("PING")
local StatusValue = statCard("TRẠNG THÁI")

local PresetPanel = card(Home, 104)
local pt = label(PresetPanel, "Preset tối ưu", 12, COLORS.TEXT, true)
pt.Position = UDim2.fromOffset(12, 8)
pt.Size = UDim2.new(1, -24, 0, 18)

local presetRow = new("Frame", {
    Size = UDim2.new(1, -16, 0, 54),
    Position = UDim2.fromOffset(8, 36),
    BackgroundTransparency = 1,
}, PresetPanel)

local presetGrid = new("UIGridLayout", {
    CellSize = UDim2.new(0.25, -5, 1, 0),
    CellPadding = UDim2.fromOffset(5, 0),
    FillDirectionMaxCells = 4,
}, presetRow)

local function presetBtn(name, color)
    local b = new("TextButton", {
        BackgroundColor3 = color or COLORS.BLUE,
        Text = name,
        TextColor3 = COLORS.TEXT,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        TextWrapped = true,
    }, presetRow)
    corner(b, 9)
    b.MouseButton1Click:Connect(function()
        applyPreset(name)
        notification("Preset", name .. " đã áp dụng", "success")
    end)
    return b
end

presetBtn("Cân bằng", Color3.fromRGB(0, 110, 200))
presetBtn("Hiệu năng", Color3.fromRGB(0, 150, 100))
presetBtn("Siêu nhẹ", Color3.fromRGB(180, 80, 0))
presetBtn("Tùy chỉnh", Color3.fromRGB(80, 80, 120))

local QuickOpt = card(Home, 58)
local qo = label(QuickOpt, "Tối ưu nhanh 120 FPS", 12, COLORS.TEXT, true)
qo.Position = UDim2.fromOffset(12, 8)
qo.Size = UDim2.new(1, -140, 0, 18)
local qd = label(QuickOpt, "Tắt hiệu ứng nặng + cap FPS", 9, COLORS.MUTED, false)
qd.Position = UDim2.fromOffset(12, 28)
qd.Size = UDim2.new(1, -140, 0, 20)

button(QuickOpt, "OPTIMIZE", function()
    local ok = optimize120()
    notification("FPS Boost", ok and "Đã tối ưu + setfpscap 120" or "Đã tối ưu (executor không hỗ trợ setfpscap)", "success")
end, 110).Position = UDim2.new(1, -122, 0.5, -16)

--------------------------------------------------
-- 18. FPS BOOST
--------------------------------------------------
local FPSPage = createPage("FPS Boost")
section(FPSPage, "FPS Boost", "Target 120 FPS khi môi trường hỗ trợ")

makeToggle(FPSPage, "120 FPS Cap", "Yêu cầu executor hỗ trợ setfpscap", false, function(v)
    local ok = setFPSCap(v)
    notification("FPS Cap", ok and (v and "Đã bật 120 FPS" or "Đã tắt") or "Executor không hỗ trợ setfpscap", ok and "success" or "warning")
end)

local OptCard = card(FPSPage, 70)
local ot = label(OptCard, "Tối ưu toàn diện", 12, COLORS.TEXT, true)
ot.Position = UDim2.fromOffset(12, 10)
ot.Size = UDim2.new(1, -130, 0, 18)
local od = label(OptCard, "Particles + Trails + Beams + PostFX + Shadows + Terrain", 9, COLORS.MUTED, false)
od.Position = UDim2.fromOffset(12, 32)
od.Size = UDim2.new(1, -130, 0, 28)

button(OptCard, "OPTIMIZE", function()
    local ok = optimize120()
    notification("Optimize", ok and "Hoàn tất + 120 FPS" or "Hoàn tất (không setfpscap)", "success")
end, 100).Position = UDim2.new(1, -112, 0.5, -16)

--------------------------------------------------
-- 19. ĐỒ HỌA
--------------------------------------------------
local Graphics = createPage("Đồ họa")
section(Graphics, "Đồ họa", "Tắt bóng, terrain, post-processing")

makeToggle(Graphics, "Tắt Shadows", "CastShadow + GlobalShadows", false, function(v)
    setFeature("Shadows", v)
    notification("Shadows", v and "Đã tắt" or "Đã bật lại", "info")
end)

makeToggle(Graphics, "Tắt Terrain Water", "Wave / Reflectance / Decoration", false, function(v)
    setFeature("Terrain", v)
    notification("Terrain", v and "Đã tối ưu" or "Đã khôi phục", "info")
end)

makeToggle(Graphics, "Tắt PostFX", "Bloom, Blur, SunRays, DoF, ColorCorrection", false, function(v)
    setFeature("PostFX", v)
    notification("PostFX", v and "Đã tắt" or "Đã bật lại", "info")
end)

--------------------------------------------------
-- 20. HIỆU ỨNG
--------------------------------------------------
local Effects = createPage("Hiệu ứng")
section(Effects, "Hiệu ứng", "Particles • Trails • Beams • Fire/Smoke")

makeToggle(Effects, "Tắt Particles", "ParticleEmitter", false, function(v)
    setFeature("Particles", v)
end)
makeToggle(Effects, "Tắt Trails", "Trail objects", false, function(v)
    setFeature("Trails", v)
end)
makeToggle(Effects, "Tắt Beams", "Beam objects", false, function(v)
    setFeature("Beams", v)
end)
makeToggle(Effects, "Tắt Fire / Smoke / Sparkles", "Fire, Smoke, Sparkles", false, function(v)
    setFeature("FireSmoke", v)
end)

local SmartCard = card(Effects, 130)
local sct = label(SmartCard, "Smart Cleanup", 12, COLORS.TEXT, true)
sct.Position = UDim2.fromOffset(12, 8)
sct.Size = UDim2.new(1, -24, 0, 18)
local scd = label(SmartCard, "Chỉ ẩn vật trang trí client-side (LocalTransparencyModifier)", 9, COLORS.MUTED, false)
scd.Position = UDim2.fromOffset(12, 28)
scd.Size = UDim2.new(1, -24, 0, 22)

button(SmartCard, "SAFE", function()
    setSmartCleanup(true, "SAFE")
    notification("Smart Cleanup", "SAFE • chỉ keyword", "success")
end, 80).Position = UDim2.fromOffset(12, 56)

button(SmartCard, "BALANCED", function()
    setSmartCleanup(true, "BALANCED")
    notification("Smart Cleanup", "BALANCED • keyword + khoảng cách", "success")
end, 90).Position = UDim2.fromOffset(98, 56)

button(SmartCard, "AGGRESSIVE", function()
    setSmartCleanup(true, "AGGRESSIVE")
    notification("Smart Cleanup", "AGGRESSIVE • ẩn mạnh hơn", "warning")
end, 95).Position = UDim2.fromOffset(195, 56)

button(SmartCard, "Tắt Cleanup", function()
    setSmartCleanup(false)
    notification("Smart Cleanup", "Đã tắt & khôi phục", "info")
end, 100).Position = UDim2.fromOffset(12, 92)

--------------------------------------------------
-- 21. TIỆN ÍCH
--------------------------------------------------
local Utilities = createPage("Tiện ích")
section(Utilities, "Tiện ích", "Aura quanh nhân vật • Music • Restore")

local AuraCard = card(Utilities, 130)
local at = label(AuraCard, "Aura (Highlight)", 12, COLORS.TEXT, true)
at.Position = UDim2.fromOffset(12, 8)
at.Size = UDim2.new(1, -24, 0, 18)
local ad = label(AuraCard, "Highlight bao quanh silhouette. Không phải vòng dưới chân.", 8, COLORS.MUTED, false)
ad.Position = UDim2.fromOffset(12, 28)
ad.Size = UDim2.new(1, -24, 0, 22)

button(AuraCard, "Soft", function()
    setAura(true, "Soft")
    notification("Aura", "Soft đã bật", "success")
end, 85).Position = UDim2.fromOffset(12, 56)

button(AuraCard, "Neon", function()
    setAura(true, "Neon")
    notification("Aura", "Neon đã bật", "success")
end, 85).Position = UDim2.fromOffset(105, 56)

button(AuraCard, "Pulse", function()
    setAura(true, "Pulse")
    notification("Aura", "Pulse đã bật", "success")
end, 85).Position = UDim2.fromOffset(198, 56)

button(AuraCard, "Tắt Aura", function()
    setAura(false)
    notification("Aura", "Đã tắt", "info")
end, 95).Position = UDim2.fromOffset(12, 92)

local MusicCard = card(Utilities, 104)
local mt = label(MusicCard, "♪ Music (client)", 12, COLORS.TEXT, true)
mt.Position = UDim2.fromOffset(12, 8)
mt.Size = UDim2.new(1, -24, 0, 18)

local MusicInput = new("TextBox", {
    Size = UDim2.new(1, -24, 0, 26),
    Position = UDim2.fromOffset(12, 32),
    BackgroundColor3 = Color3.fromRGB(15, 30, 50),
    Text = "",
    PlaceholderText = "Nhập SoundId (số)",
    TextColor3 = COLORS.TEXT,
    PlaceholderColor3 = COLORS.MUTED,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
}, MusicCard)
corner(MusicInput, 8)

button(MusicCard, "▶ Play", function()
    local id = tonumber(MusicInput.Text)
    if id then
        local ok = playMusic(id)
        notification("Music", ok and "Đang phát" or "SoundId lỗi / không load được", ok and "success" or "error")
    else
        notification("Music", "SoundId không hợp lệ", "warning")
    end
end, 75).Position = UDim2.fromOffset(12, 66)

button(MusicCard, "■ Stop", function()
    stopMusic()
    notification("Music", "Đã dừng", "info")
end, 75).Position = UDim2.fromOffset(95, 66)

local RestCard = card(Utilities, 66)
local rt = label(RestCard, "Khôi phục toàn bộ", 12, COLORS.TEXT, true)
rt.Position = UDim2.fromOffset(12, 8)
rt.Size = UDim2.new(1, -130, 0, 18)
local rd = label(RestCard, "Trả hiệu ứng, bóng, terrain về trạng thái đã lưu.", 8, COLORS.MUTED, false)
rd.Position = UDim2.fromOffset(12, 30)
rd.Size = UDim2.new(1, -130, 0, 26)

button(RestCard, "RESTORE", function()
    restoreAll()
    setFPSCap(false)
    setAura(false)
    setSmartCleanup(false)
    notification("Restore", "Mọi thay đổi đã được hoàn tác", "success")
end, 100).Position = UDim2.new(1, -112, 0.5, -16)

--------------------------------------------------
-- 22. NÂNG CAO
--------------------------------------------------
local Advanced = createPage("Nâng cao")
section(Advanced, "Nâng cao", "Scan • Thống kê • Distance")

local ScanCard = card(Advanced, 112)
local sct2 = label(ScanCard, "Thống kê lần quét gần nhất", 12, COLORS.TEXT, true)
sct2.Position = UDim2.fromOffset(12, 8)
sct2.Size = UDim2.new(1, -24, 0, 18)

local SummaryLbl = label(ScanCard, "Chưa có dữ liệu.", 9, COLORS.MUTED, false)
SummaryLbl.Position = UDim2.fromOffset(12, 30)
SummaryLbl.Size = UDim2.new(1, -24, 0, 36)

button(ScanCard, "🔎 QUÉT LẠI", function()
    for feature, enabled in pairs(FeatureState) do
        if enabled then
            scanAndDisable(feature)
        end
    end
    SummaryLbl.Text = string.format(
        "Đã quét: %d object\nParticle: %d • Trail: %d • Beam: %d • PostFX: %d • Fire/Smoke: %d",
        Counts.Scanned, Counts.Particles, Counts.Trails, Counts.Beams, Counts.PostFX, Counts.FireSmoke
    )
    notification("Quét xong", "Thống kê đã cập nhật", "success")
end, 110).Position = UDim2.new(1, -122, 1, -40)

local DistCard = card(Advanced, 84)
local dt = label(DistCard, "Smart Distance (studs)", 12, COLORS.TEXT, true)
dt.Position = UDim2.fromOffset(12, 8)
dt.Size = UDim2.new(1, -24, 0, 18)
local dd = label(DistCard, string.format("Near %d • Mid %d • Far %d  (chỉ ảnh hưởng vật trang trí)", Config.DistanceNear, Config.DistanceMid, Config.DistanceFar), 9, COLORS.MUTED, false)
dd.Position = UDim2.fromOffset(12, 30)
dd.Size = UDim2.new(1, -24, 0, 40)

--------------------------------------------------
-- 23. CÀI ĐẶT
--------------------------------------------------
local SettingsPage = createPage("Cài đặt")
section(SettingsPage, "Cài đặt", "Tùy chỉnh hiển thị & Aura")

makeToggle(SettingsPage, "Hiển thị FPS", "Hiện FPS ở trang chủ", true, function(v)
    Config.ShowFPS = v
    FPSValue.Visible = v
end)
makeToggle(SettingsPage, "Hiển thị Ping", "Hiện ping ở trang chủ", true, function(v)
    Config.ShowPing = v
    PingValue.Visible = v
end)
makeToggle(SettingsPage, "Thông báo", "Hiện notification", true, function(v)
    Config.Notifications = v
end)
makeToggle(SettingsPage, "Hoạt ảnh giao diện", "Bật/tắt animation", true, function(v)
    Config.Animations = v
end)
makeToggle(SettingsPage, "Aura", "Bật/tắt aura quanh nhân vật", false, function(v)
    setAura(v)
end)

local about = card(SettingsPage, 100)
local abt = label(about, "Delta X - Lag Fix v" .. VERSION, 13, COLORS.TEXT, true)
abt.Position = UDim2.fromOffset(12, 10)
abt.Size = UDim2.new(1, -24, 0, 20)
local abv = label(about, "Tác giả: Minh Tiến\nClient-side FPS / Graphics / Performance Utility\nMobile First • Liquid Glass • Smart Cleanup • Aura\nNO ESP • NO FLY • NO GAMEPLAY CHEAT", 9, COLORS.MUTED, false)
abv.Position = UDim2.fromOffset(12, 34)
abv.Size = UDim2.new(1, -24, 0, 58)

--------------------------------------------------
-- 24. INITIAL PAGE STATE
--------------------------------------------------
Pages["Trang chủ"].Visible = true
SideButtons["Trang chủ"].Button.BackgroundColor3 = Color3.fromRGB(0, 75, 170)
SideButtons["Trang chủ"].Icon.TextColor3 = COLORS.TEXT
SideButtons["Trang chủ"].Text.TextColor3 = COLORS.TEXT
SideButtons["Trang chủ"].Stroke.Transparency = 0.35
SideButtons["Trang chủ"].Indicator.BackgroundTransparency = 0

--------------------------------------------------
-- 25. FPS / PING MONITOR
--------------------------------------------------
local frameCounter = 0
local elapsed = 0
local displayedFPS = 60

register(RunService.RenderStepped:Connect(function(dt)
    frameCounter += 1
    elapsed += dt
    if elapsed >= Config.FPSUpdateInterval then
        local fps = frameCounter / elapsed
        displayedFPS = math.clamp(math.floor(fps + 0.5), 1, 999)
        FPSValue.Text = tostring(displayedFPS)

        if displayedFPS >= 55 then
            FPSValue.TextColor3 = COLORS.GREEN
        elseif displayedFPS >= 30 then
            FPSValue.TextColor3 = COLORS.YELLOW
        else
            FPSValue.TextColor3 = COLORS.RED
        end

        if Config.ShowPing then
            safe(function()
                local item = Stats.Network.ServerStatsItem["Data Ping"]
                PingValue.Text = item:GetValueString()
            end)
        end

        local statusStr = Config.Optimized and "Đã tối ưu" or "Sẵn sàng"
        StatusValue.Text = statusStr
        StatusValue.TextColor3 = Config.Optimized and COLORS.GREEN or COLORS.CYAN

        ExpandedSub.Text = string.format("%s • %d FPS", statusStr, displayedFPS)
        CollapsedText.Text = string.format("Delta X • %d", displayedFPS)

        frameCounter = 0
        elapsed = 0
    end
end))

--------------------------------------------------
-- 26. UI STATE MACHINE (NO FLOATING MINI)
--------------------------------------------------
local UIState = "Open"

local function SetUIState(state)
    if UIState == state then return end
    UIState = state

    if state == "Open" then
        Main.Visible = true
        MainScale.Scale = 0.96
        MainGlass.BackgroundTransparency = 0.32
        tween(MainScale, {Scale = 1}, 0.24, Enum.EasingStyle.Quint)
        tween(MainGlass, {BackgroundTransparency = 0.18}, 0.24)
        SetIslandState("HIDDEN")
    elseif state == "Minimized" then
        tween(MainScale, {Scale = 0.94}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(MainGlass, {BackgroundTransparency = 0.45}, 0.15)
        task.delay(0.16, function()
            if UIState == "Minimized" then
                Main.Visible = false
                MainScale.Scale = 1
            end
        end)
        SetIslandState("COLLAPSED")
    elseif state == "Closed" then
        Main.Visible = false
        SetIslandState("COLLAPSED")
    end
end

ExpandedAction.MouseButton1Click:Connect(function()
    SetUIState("Open")
end)

ExpandedClose.MouseButton1Click:Connect(function()
    SetIslandState("COLLAPSING")
    -- keep Island collapsed after close
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    SetUIState("Minimized")
end)

--------------------------------------------------
-- 27. FULL CLEANUP
--------------------------------------------------
local function fullCleanup()
    restoreAll()
    setFPSCap(false)
    setAura(false)
    stopMusic()
    cleanupAura()
    disconnectAll()
    if ScreenGui and ScreenGui.Parent then
        pcall(function() ScreenGui:Destroy() end)
    end
    _G.DeltaXLagFix_Running = false
    _G.DeltaXLagFix_Cleanup = nil
end

_G.DeltaXLagFix_Cleanup = fullCleanup

CloseBtn.MouseButton1Click:Connect(function()
    fullCleanup()
end)

--------------------------------------------------
-- 28. DRAG
--------------------------------------------------
local dragging, dragInput, dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

register(UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

register(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

--------------------------------------------------
-- 29. RESIZE
--------------------------------------------------
local ResizeHandle = new("TextButton", {
    Size = UDim2.fromOffset(24, 24),
    Position = UDim2.new(1, -28, 1, -28),
    BackgroundColor3 = Color3.fromRGB(12, 30, 52),
    BackgroundTransparency = 0.1,
    Text = "↘",
    TextColor3 = COLORS.CYAN,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 40,
}, Main)
corner(ResizeHandle, 8)
stroke(ResizeHandle, COLORS.BLUE, 0.5, 1)

do
    local resizing, resizeStart, resizeOriginal, resizeInput
    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            resizeOriginal = Main.Size
        end
    end)
    ResizeHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            resizeInput = input
        end
    end)
    register(UserInputService.InputChanged:Connect(function(input)
        if resizing and input == resizeInput then
            local d = input.Position - resizeStart
            local newW = math.clamp(resizeOriginal.X.Offset + d.X, MIN_W, MAX_W)
            local newH = math.clamp(resizeOriginal.Y.Offset + d.Y, MIN_H, MAX_H)
            Main.Size = UDim2.fromOffset(newW, newH)
        end
    end))
    register(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end))
end

--------------------------------------------------
-- 30. RESPONSIVE
--------------------------------------------------
local function layoutMain()
    local camera = Workspace.CurrentCamera
    local mobile = camera and camera.ViewportSize.X <= 800 or false
    local w = Main.AbsoluteSize.X
    local top = 80
    local sideW = mobile and math.clamp(math.floor(w * 0.2), 72, 96) or math.clamp(math.floor(w * 0.25), 120, 140)
    local contentX = sideW + 12

    Sidebar.Size = UDim2.new(0, sideW, 1, -92)
    Sidebar.Position = UDim2.fromOffset(6, top)

    for _, page in pairs(Pages) do
        page.Position = UDim2.fromOffset(contentX, top)
        page.Size = UDim2.new(1, -(contentX + 6), 1, -92)
    end

    local compact = mobile or w < 460
    for _, data in pairs(SideButtons) do
        data.Text.Visible = not compact
        if compact then
            data.Icon.Position = UDim2.new(0.5, -11, 0, 0)
        else
            data.Icon.Position = UDim2.fromOffset(12, 0)
        end
    end

    if presetGrid then
        if mobile then
            PresetPanel.Size = UDim2.new(1, 0, 0, 150)
            presetRow.Size = UDim2.new(1, -16, 0, 100)
            presetGrid.CellSize = UDim2.new(0.5, -4, 0, 46)
            presetGrid.FillDirectionMaxCells = 2
        else
            PresetPanel.Size = UDim2.new(1, 0, 0, 104)
            presetRow.Size = UDim2.new(1, -16, 0, 54)
            presetGrid.CellSize = UDim2.new(0.25, -5, 1, 0)
            presetGrid.FillDirectionMaxCells = 4
        end
    end

    StatsLayout.FillDirection = mobile and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
    if mobile then
        StatsRow.Size = UDim2.new(1, 0, 0, 198)
        for _, child in ipairs(StatsRow:GetChildren()) do
            if child:IsA("Frame") then child.Size = UDim2.new(1, 0, 0, 60) end
        end
    else
        StatsRow.Size = UDim2.new(1, 0, 0, 66)
        for _, child in ipairs(StatsRow:GetChildren()) do
            if child:IsA("Frame") then child.Size = UDim2.new(1/3, -4, 1, 0) end
        end
    end
end

local function fitToViewport()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local vp = camera.ViewportSize
    local maxW = math.max(280, vp.X - 16)
    local maxH = math.max(260, vp.Y - 20)

    if vp.X <= 800 then
        local w = math.min(400, maxW)
        local h = math.min(460, maxH)
        Main.Size = UDim2.fromOffset(w, h)
        Main.AnchorPoint = Vector2.new(0.5, 0.5)
        Main.Position = UDim2.fromScale(0.5, 0.5)
    else
        Main.Size = UDim2.fromOffset(math.min(520, vp.X - 160), math.min(400, vp.Y - 70))
        Main.AnchorPoint = Vector2.new(0.5, 0.5)
        Main.Position = UDim2.fromScale(0.5, 0.5)
    end
    layoutMain()
end

safe(layoutMain)
safe(fitToViewport)

safe(function()
    if Workspace.CurrentCamera then
        register(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToViewport))
    end
end)

--------------------------------------------------
-- 31. BOOT
--------------------------------------------------
SetUIState("Open")

task.defer(function()
    for _, obj in ipairs({Logo, BannerImage, ExpandedIcon}) do
        applyRobloxImage(obj, obj == BannerImage and BANNER_ID or AVATAR_ID)
    end
end)

notification("Delta X - Lag Fix", "Bản " .. VERSION .. " • Dynamic Island Premium", "success")
print("Delta X - Lag Fix v" .. VERSION .. " loaded.")
