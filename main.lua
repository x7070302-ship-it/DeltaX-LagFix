--[[
    Delta X - Lag Fix
    Phiên bản: 1.6
    Tác giả: Minh Tiến
    Client-side FPS / Graphics Optimizer
    Chỉ tối ưu đồ họa và giao diện, không tự động chơi game.
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CẤU HÌNH
--==================================================

local VERSION = "1.7"
local AVATAR_ID = "rbxassetid://118787890588648"
local BANNER_ID = "rbxassetid://117945200016708"


local FPS_TARGET = 120
local FPSCapEnabled = false

local function setFPSCap120(enabled)
    FPSCapEnabled = enabled
    if typeof(setfpscap) == "function" then
        safe(function() setfpscap(enabled and FPS_TARGET or 60) end)
        return true
    end
    return false
end

local Config = {
    ShowFPS = true,
    ShowPing = true,
    Notifications = true,
    Animations = true,
    Preset = "Cân bằng",
    Optimized = false,
}

--==================================================
-- AN TOÀN / TIỆN ÍCH
--==================================================

local function safe(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    return ok, a, b, c
end

local function tween(obj, info, props)
    if not obj or not obj.Parent then return end
    safe(function()
        TweenService:Create(obj, info, props):Play()
    end)
end

local function getGuiParent()
    local parent
    safe(function()
        if typeof(gethui) == "function" then
            parent = gethui()
        end
    end)

    if not parent then
        safe(function()
            parent = game:GetService("CoreGui")
        end)
    end

    if not parent then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    return parent
end

local GUI_PARENT = getGuiParent()

local old = GUI_PARENT:FindFirstChild("DeltaX_LagFix")
if old then
    old:Destroy()
end

--==================================================
-- TRẠNG THÁI / RESTORE
--==================================================

local Original = {
    Lighting = {},
    Terrain = {},
    Effects = {},
    VisualObjects = {},
    CastShadow = {},
}

local Counts = {
    Scanned = 0,
    Particles = 0,
    Trails = 0,
    Beams = 0,
    PostFX = 0,
    FireSmoke = 0,
    Shadows = 0,
}

local FeatureState = {
    Particles = false,
    Trails = false,
    Beams = false,
    PostFX = false,
    FireSmoke = false,
    Shadows = false,
    Terrain = false,
}

local DescendantConnection

-- Lưu trạng thái trước khi sửa
safe(function()
    Original.Lighting.GlobalShadows = Lighting.GlobalShadows
    Original.Lighting.Brightness = Lighting.Brightness
    Original.Lighting.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
    Original.Lighting.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
end)

safe(function()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        Original.Terrain.WaterWaveSize = terrain.WaterWaveSize
        Original.Terrain.WaterWaveSpeed = terrain.WaterWaveSpeed
        Original.Terrain.WaterReflectance = terrain.WaterReflectance
        Original.Terrain.WaterTransparency = terrain.WaterTransparency
        Original.Terrain.Decoration = terrain.Decoration
    end
end)

local POSTFX_CLASSES = {
    BloomEffect = true,
    BlurEffect = true,
    SunRaysEffect = true,
    ColorCorrectionEffect = true,
    DepthOfFieldEffect = true,
}

local VISUAL_CLASSES = {
    ParticleEmitter = "Particles",
    Trail = "Trails",
    Beam = "Beams",
    Fire = "FireSmoke",
    Smoke = "FireSmoke",
    Sparkles = "FireSmoke",
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

local function applyFeatureToObject(obj, feature)
    if not obj then return end
    disableObject(obj, feature)
end

local function scanAndDisable(feature)
    Counts.Scanned = 0
    local count = 0

    safe(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            Counts.Scanned += 1

            if disableObject(obj, feature) then
                count += 1
            end
        end
    end)

    for _, obj in ipairs(Lighting:GetChildren()) do
        if feature == "PostFX" and POSTFX_CLASSES[obj.ClassName] then
            if disableObject(obj, feature) then
                count += 1
            end
        end
    end

    if feature == "Particles" then
        Counts.Particles = count
    elseif feature == "Trails" then
        Counts.Trails = count
    elseif feature == "Beams" then
        Counts.Beams = count
    elseif feature == "PostFX" then
        Counts.PostFX = count
    elseif feature == "FireSmoke" then
        Counts.FireSmoke = count
    elseif feature == "Shadows" then
        Counts.Shadows = count
    end
end

local function setLightingLow()
    safe(function()
        Lighting.GlobalShadows = false
    end)

    safe(function()
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    end)
end

local function setTerrainLow()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end

    safe(function()
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.Decoration = false
    end)
end

local function setFeature(feature, enabled)
    FeatureState[feature] = enabled

    if enabled then
        scanAndDisable(feature)

        if feature == "Terrain" then
            setTerrainLow()
        elseif feature == "Shadows" then
            setLightingLow()
            scanAndDisable("Shadows")
        end
    else
        -- Khôi phục riêng nhóm này
        for obj, oldState in pairs(Original.Effects) do
            if obj and obj.Parent then
                local matches = false

                if feature == "PostFX" and POSTFX_CLASSES[obj.ClassName] then
                    matches = true
                elseif VISUAL_CLASSES[obj.ClassName] == feature then
                    matches = true
                end

                if matches then
                    safe(function() obj.Enabled = oldState end)
                end
            end
        end

        if feature == "Shadows" then
            for obj, oldState in pairs(Original.CastShadow) do
                if obj and obj.Parent then
                    safe(function() obj.CastShadow = oldState end)
                end
            end

            safe(function()
                Lighting.GlobalShadows = Original.Lighting.GlobalShadows
                Lighting.EnvironmentDiffuseScale = Original.Lighting.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = Original.Lighting.EnvironmentSpecularScale
            end)
        end

        if feature == "Terrain" then
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                safe(function()
                    terrain.WaterWaveSize = Original.Terrain.WaterWaveSize
                    terrain.WaterWaveSpeed = Original.Terrain.WaterWaveSpeed
                    terrain.WaterReflectance = Original.Terrain.WaterReflectance
                    terrain.WaterTransparency = Original.Terrain.WaterTransparency
                    terrain.Decoration = Original.Terrain.Decoration
                end)
            end
        end
    end
end

local function restoreAll()
    for obj, oldState in pairs(Original.Effects) do
        if obj and obj.Parent then
            safe(function() obj.Enabled = oldState end)
        end
    end

    for obj, oldState in pairs(Original.CastShadow) do
        if obj and obj.Parent then
            safe(function() obj.CastShadow = oldState end)
        end
    end

    safe(function()
        Lighting.GlobalShadows = Original.Lighting.GlobalShadows
        Lighting.Brightness = Original.Lighting.Brightness
        Lighting.EnvironmentDiffuseScale = Original.Lighting.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = Original.Lighting.EnvironmentSpecularScale
    end)

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        safe(function()
            terrain.WaterWaveSize = Original.Terrain.WaterWaveSize
            terrain.WaterWaveSpeed = Original.Terrain.WaterWaveSpeed
            terrain.WaterReflectance = Original.Terrain.WaterReflectance
            terrain.WaterTransparency = Original.Terrain.WaterTransparency
            terrain.Decoration = Original.Terrain.Decoration
        end)
    end

    for k in pairs(FeatureState) do
        FeatureState[k] = false
    end

    Config.Optimized = false
end

local function optimize120()
    setFeature("PostFX", true)
    setFeature("Particles", true)
    setFeature("Trails", true)
    setFeature("Beams", true)
    setFeature("FireSmoke", true)
    setFeature("Shadows", true)
    setFeature("Terrain", true)
    local supported = setFPSCap120(true)
    Config.Optimized = true
    return supported
end

local function applyPreset(name)
    Config.Preset = name

    if name == "Cân bằng" then
        setFeature("PostFX", true)
        setFeature("Particles", true)
        setFeature("Trails", false)
        setFeature("Beams", false)
        setFeature("FireSmoke", false)
        setFeature("Shadows", false)
        setFeature("Terrain", false)

    elseif name == "Hiệu năng" then
        optimize120()

    elseif name == "Siêu nhẹ" then
        setFeature("PostFX", true)
        setFeature("Particles", true)
        setFeature("Trails", true)
        setFeature("Beams", true)
        setFeature("FireSmoke", true)
        setFeature("Shadows", true)
        setFeature("Terrain", true)
    end

    Config.Optimized = true
end

-- Tự xử lý hiệu ứng mới xuất hiện khi tối ưu đang bật.
DescendantConnection = Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        for feature, enabled in pairs(FeatureState) do
            if enabled then
                applyFeatureToObject(obj, feature)
            end
        end
    end)
end)

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaX_LagFix"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GUI_PARENT

local function new(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        safe(function() obj[k] = v end)
    end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    new("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, obj)
end

local function stroke(obj, color, transparency, thickness)
    new("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    }, obj)
end

local function label(parent, text, size, color, bold)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color,
        TextSize = size,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end

local COLORS = {
    BG = Color3.fromRGB(4, 9, 18),
    PANEL = Color3.fromRGB(8, 17, 31),
    PANEL2 = Color3.fromRGB(12, 26, 44),
    BLUE = Color3.fromRGB(0, 125, 255),
    BLUE2 = Color3.fromRGB(35, 165, 255),
    TEXT = Color3.fromRGB(235, 243, 255),
    MUTED = Color3.fromRGB(135, 155, 180),
    GREEN = Color3.fromRGB(45, 225, 105),
    YELLOW = Color3.fromRGB(255, 205, 70),
    RED = Color3.fromRGB(255, 70, 85),
}

local DEFAULT_W, DEFAULT_H = 560, 390
local MIN_W, MIN_H = 350, 290
local MAX_W, MAX_H = 780, 540

local Main = new("Frame", {
    Size = UDim2.fromOffset(DEFAULT_W, DEFAULT_H),
    Position = UDim2.new(0.5, -DEFAULT_W / 2, 0.5, -DEFAULT_H / 2),
    BackgroundColor3 = COLORS.BG,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = false,
}, ScreenGui)

corner(Main, 16)
stroke(Main, Color3.fromRGB(0, 130, 255), 0.18, 1)

local MainGlass = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(8, 18, 34),
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
    Active = false,
    ZIndex = 0,
}, Main)
corner(MainGlass, 16)

local MainHighlight = new("Frame", {
    Size = UDim2.new(1, -4, 0, 2),
    Position = UDim2.fromOffset(2, 2),
    BackgroundColor3 = COLORS.BLUE2,
    BackgroundTransparency = 0.52,
    BorderSizePixel = 0,
    Active = false,
    ZIndex = 1,
}, Main)
corner(MainHighlight, 5)

--==================================================
-- HEADER
--==================================================

local Header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 84),
    BackgroundTransparency = 1,
    Active = true,
}, Main)

-- Banner artwork supplied by the user.
local BannerImage = new("ImageLabel", {
    Name = "BannerImage",
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.fromOffset(6, 6),
    BackgroundTransparency = 1,
    Image = BANNER_ID,
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0.08,
    ZIndex = 0,
}, Header)
corner(BannerImage, 12)

-- Lớp kính tối để banner không lấn chữ.
local BannerGlass = new("Frame", {
    Name = "BannerGlass",
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.fromOffset(5, 5),
    BackgroundColor3 = COLORS.BG,
    BackgroundTransparency = 0.48,
    BorderSizePixel = 0,
    ZIndex = 1,
}, Header)
corner(BannerGlass, 12)
local BannerGradient = new("UIGradient", {
    Rotation = 0,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.10),
        NumberSequenceKeypoint.new(0.55, 0.28),
        NumberSequenceKeypoint.new(1, 0.02),
    }),
}, BannerGlass)

local Logo = new("ImageLabel", {
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.fromOffset(12, 12),
    BackgroundColor3 = Color3.fromRGB(0, 70, 160),
    BackgroundTransparency = 0.08,
    Image = AVATAR_ID,
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 3,
}, Header)

corner(Logo, 999)
stroke(Logo, COLORS.BLUE2, 0.10, 2)

local Title = label(Header, "Delta X - Lag Fix", 18, COLORS.TEXT, true)
Title.Position = UDim2.fromOffset(72, 13)
Title.Size = UDim2.new(0, 300, 0, 24)
Title.ZIndex = 3

local Subtitle = label(Header, "Tối ưu hiệu suất • Mượt hơn • Nhẹ hơn", 10, COLORS.MUTED, false)
Subtitle.Position = UDim2.fromOffset(72, 39)
Subtitle.Size = UDim2.new(0, 330, 0, 18)
Subtitle.ZIndex = 3

local Version = label(Header, "v" .. VERSION, 10, COLORS.BLUE2, true)
Version.Position = UDim2.new(1, -120, 0, 14)
Version.Size = UDim2.fromOffset(35, 22)
Version.TextXAlignment = Enum.TextXAlignment.Right
Version.ZIndex = 3

local Minimize = new("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -72, 0, 12),
    BackgroundColor3 = COLORS.PANEL2,
    Text = "—",
    TextColor3 = COLORS.TEXT,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, Header)

corner(Minimize, 8)
Minimize.ZIndex = 4

local Close = new("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -36, 0, 12),
    BackgroundColor3 = COLORS.PANEL2,
    Text = "×",
    TextColor3 = COLORS.TEXT,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, Header)

corner(Close, 8)
Close.ZIndex = 4

local ProfilePill = new("Frame", {
    Size = UDim2.fromOffset(140, 44),
    Position = UDim2.new(1, -225, 0, 14),
    BackgroundColor3 = Color3.fromRGB(13, 31, 52),
    BackgroundTransparency = 0.28,
    BorderSizePixel = 0,
    ZIndex = 3,
}, Header)
corner(ProfilePill, 20)
stroke(ProfilePill, COLORS.BLUE, 0.55, 1)

local ProfileIcon = new("ImageLabel", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.fromOffset(6, 6),
    BackgroundColor3 = Color3.fromRGB(0, 70, 150),
    Image = AVATAR_ID,
    ScaleType = Enum.ScaleType.Crop,
    BorderSizePixel = 0,
    ZIndex = 4,
}, ProfilePill)
corner(ProfileIcon, 999)

local ProfileText = label(ProfilePill, "Minh Tiến", 10, COLORS.TEXT, true)
ProfileText.Position = UDim2.fromOffset(45, 5)
ProfileText.Size = UDim2.fromOffset(82, 16)
ProfileText.ZIndex = 4

local ProfileSub = label(ProfilePill, "Liquid Glass • v" .. VERSION, 8, COLORS.MUTED, false)
ProfileSub.Position = UDim2.fromOffset(45, 21)
ProfileSub.Size = UDim2.fromOffset(90, 14)
ProfileSub.ZIndex = 4

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = new("Frame", {
    Size = UDim2.new(0, 160, 1, -76),
    Position = UDim2.fromOffset(10, 92),
    BackgroundColor3 = Color3.fromRGB(6, 14, 25),
    BorderSizePixel = 0,
}, Main)

corner(Sidebar, 11)

local SidePadding = new("UIPadding", {
    PaddingTop = UDim.new(0, 9),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
}, Sidebar)

local SideLayout = new("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)

local SideProfile = new("Frame", {
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = Color3.fromRGB(11, 28, 47),
    BackgroundTransparency = 0.24,
    BorderSizePixel = 0,
    LayoutOrder = 0,
}, Sidebar)
corner(SideProfile, 12)
stroke(SideProfile, COLORS.BLUE, 0.62, 1)

local SideAvatar = new("ImageLabel", {
    Size = UDim2.fromOffset(38, 38),
    Position = UDim2.fromOffset(7, 8),
    BackgroundColor3 = Color3.fromRGB(0, 70, 150),
    Image = AVATAR_ID,
    ScaleType = Enum.ScaleType.Crop,
    BorderSizePixel = 0,
}, SideProfile)
corner(SideAvatar, 999)

local SideName = label(SideProfile, "Minh Tiến", 10, COLORS.TEXT, true)
SideName.Position = UDim2.fromOffset(52, 8)
SideName.Size = UDim2.new(1, -60, 0, 18)

local SideDesc = label(SideProfile, "Tối ưu • Mượt hơn", 8, COLORS.MUTED, false)
SideDesc.Position = UDim2.fromOffset(52, 27)
SideDesc.Size = UDim2.new(1, -60, 0, 16)

local Pages = {}
local SideButtons = {}
local CurrentPage = "Trang chủ"

local function createPage(name)
    local page = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, -182, 1, -76),
        Position = UDim2.fromOffset(173, 92),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.BLUE,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, Main)

    new("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 16),
    }, page)

    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    Pages[name] = page
    return page
end

local function createSideButton(name, icon)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Color3.fromRGB(7, 16, 28),
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #SideButtons + 1,
    }, Sidebar)

    corner(btn, 8)

    local ic = label(btn, icon, 15, COLORS.MUTED, true)
    ic.Position = UDim2.fromOffset(8, 0)
    ic.Size = UDim2.fromOffset(26, 38)
    ic.TextXAlignment = Enum.TextXAlignment.Center

    local txt = label(btn, name, 11, COLORS.MUTED, true)
    txt.Position = UDim2.fromOffset(39, 0)
    txt.Size = UDim2.new(1, -44, 1, 0)

    SideButtons[name] = {
        Button = btn,
        Icon = ic,
        Text = txt,
    }

    btn.MouseButton1Click:Connect(function()
        CurrentPage = name

        for n, data in pairs(SideButtons) do
            data.Button.BackgroundColor3 = Color3.fromRGB(7, 16, 28)
            data.Icon.TextColor3 = COLORS.MUTED
            data.Text.TextColor3 = COLORS.MUTED
        end

        btn.BackgroundColor3 = Color3.fromRGB(0, 76, 175)
        ic.TextColor3 = COLORS.TEXT
        txt.TextColor3 = COLORS.TEXT

        for _, page in pairs(Pages) do
            page.Visible = false
        end

        Pages[name].Visible = true
        Pages[name].CanvasPosition = Vector2.new(0, 0)
    end)

    return btn
end

createSideButton("Trang chủ", "⌂")
createSideButton("FPS Boost", "◉")
createSideButton("Đồ họa", "▣")
createSideButton("Hiệu ứng", "✦")
createSideButton("Tiện ích", "▦")
createSideButton("Nâng cao", "⚙")
createSideButton("Cài đặt", "☷")

local Footer = label(Sidebar, "◆ Tối ưu cho Delta X", 9, COLORS.BLUE2, true)
Footer.Position = UDim2.new(0, 8, 1, -25)
Footer.Size = UDim2.new(1, -16, 0, 18)

--==================================================
-- UI HELPERS
--==================================================

local function section(page, title, desc)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
    }, page)

    label(holder, title, 20, COLORS.TEXT, true).Size = UDim2.new(1, 0, 0, 26)

    local d = label(holder, desc or "", 10, COLORS.MUTED, false)
    d.Position = UDim2.fromOffset(0, 27)
    d.Size = UDim2.new(1, 0, 0, 18)

    return holder
end

local function card(page, height)
    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 58),
        BackgroundColor3 = COLORS.PANEL,
        BorderSizePixel = 0,
    }, page)

    corner(frame, 10)
    stroke(frame, Color3.fromRGB(25, 52, 80), 0.5, 1)
    return frame
end

local function button(parent, text, callback, width)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(width or 140, 36),
        BackgroundColor3 = COLORS.BLUE,
        Text = text,
        TextColor3 = COLORS.TEXT,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, parent)

    corner(b, 8)

    b.MouseEnter:Connect(function()
        b.BackgroundColor3 = COLORS.BLUE2
    end)

    b.MouseLeave:Connect(function()
        b.BackgroundColor3 = COLORS.BLUE
    end)

    b.MouseButton1Click:Connect(function()
        safe(callback)
    end)

    return b
end

local function makeToggle(page, titleText, descText, default, callback)
    local c = card(page, 58)

    local t = label(c, titleText, 11, COLORS.TEXT, true)
    t.Position = UDim2.fromOffset(13, 6)
    t.Size = UDim2.new(1, -90, 0, 22)

    local d = label(c, descText or "", 9, COLORS.MUTED, false)
    d.Position = UDim2.fromOffset(13, 28)
    d.Size = UDim2.new(1, -90, 0, 18)

    local switch = new("TextButton", {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = default and COLORS.BLUE or Color3.fromRGB(35, 48, 64),
        Text = "",
        AutoButtonColor = false,
    }, c)

    corner(switch, 20)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = COLORS.TEXT,
    }, switch)

    corner(knob, 20)

    local state = default

    local function set(v, invoke)
        state = v

        if Config.Animations then
            tween(knob, TweenInfo.new(0.15), {
                Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            })
            tween(switch, TweenInfo.new(0.15), {
                BackgroundColor3 = v and COLORS.BLUE or Color3.fromRGB(35, 48, 64)
            })
        else
            switch.BackgroundColor3 = v and COLORS.BLUE or Color3.fromRGB(35, 48, 64)
            knob.Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        end

        if invoke then
            safe(callback, v)
        end
    end

    switch.MouseButton1Click:Connect(function()
        set(not state, true)
    end)

    return {
        Set = function(v) set(v, true) end,
        Get = function() return state end,
    }
end

local function notification(titleText, bodyText, kind)
    if not Config.Notifications then return end

    local color = COLORS.BLUE2
    if kind == "success" then color = COLORS.GREEN end
    if kind == "warning" then color = COLORS.YELLOW end
    if kind == "error" then color = COLORS.RED end

    local box = new("Frame", {
        Size = UDim2.fromOffset(300, 70),
        Position = UDim2.new(1, 320, 1, -90),
        BackgroundColor3 = COLORS.PANEL,
        BorderSizePixel = 0,
        ZIndex = 50,
    }, ScreenGui)

    corner(box, 10)
    stroke(box, color, 0.35, 1)

    local bar = new("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        ZIndex = 51,
    }, box)

    corner(bar, 4)

    local t = label(box, titleText, 11, COLORS.TEXT, true)
    t.Position = UDim2.fromOffset(14, 8)
    t.Size = UDim2.new(1, -28, 0, 20)
    t.ZIndex = 51

    local d = label(box, bodyText, 9, COLORS.MUTED, false)
    d.Position = UDim2.fromOffset(14, 31)
    d.Size = UDim2.new(1, -28, 0, 30)
    d.ZIndex = 51

    tween(box, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        Position = UDim2.new(1, -315, 1, -90)
    })

    task.delay(3, function()
        if box and box.Parent then
            tween(box, TweenInfo.new(0.22), {
                Position = UDim2.new(1, 320, 1, -90)
            })
            task.delay(0.25, function()
                safe(function() box:Destroy() end)
            end)
        end
    end)
end

--==================================================
-- TRANG CHỦ
--==================================================

local Home = createPage("Trang chủ")
section(Home, "Tối ưu hiệu năng", "Liquid Glass • iOS 27 • Tối ưu client-side")

local PresetPanel = card(Home, 118)

local presetTitle = label(PresetPanel, "⚡ Preset nhanh", 13, COLORS.TEXT, true)
presetTitle.Position = UDim2.fromOffset(13, 8)
presetTitle.Size = UDim2.new(1, -26, 0, 20)

local presetSub = label(PresetPanel, "Chọn chế độ tối ưu phù hợp với thiết bị.", 9, COLORS.MUTED, false)
presetSub.Position = UDim2.fromOffset(13, 29)
presetSub.Size = UDim2.new(1, -26, 0, 18)

local presetRow = new("Frame", {
    Size = UDim2.new(1, -20, 0, 62),
    Position = UDim2.fromOffset(10, 49),
    BackgroundTransparency = 1,
}, PresetPanel)

new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 7),
}, presetRow)

local function presetButton(textValue, iconText, descValue, cb)
    local b = new("TextButton", {
        Size = UDim2.new(0.25, -6, 1, 0),
        BackgroundColor3 = Color3.fromRGB(10, 29, 52),
        BackgroundTransparency = 0.18,
        Text = "",
        AutoButtonColor = false,
    }, presetRow)
    corner(b, 11)
    stroke(b, COLORS.BLUE, 0.62, 1)

    local i = label(b, iconText, 17, COLORS.BLUE2, true)
    i.Position = UDim2.fromOffset(7, 8)
    i.Size = UDim2.fromOffset(28, 22)
    i.TextXAlignment = Enum.TextXAlignment.Center

    local t = label(b, textValue, 10, COLORS.TEXT, true)
    t.Position = UDim2.fromOffset(37, 7)
    t.Size = UDim2.new(1, -42, 0, 18)

    local d = label(b, descValue, 7, COLORS.MUTED, false)
    d.Position = UDim2.fromOffset(37, 27)
    d.Size = UDim2.new(1, -42, 0, 27)
    d.TextWrapped = true

    b.MouseEnter:Connect(function()
        tween(b, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(0, 75, 165),
            BackgroundTransparency = 0.05,
        })
    end)

    b.MouseLeave:Connect(function()
        tween(b, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(10, 29, 52),
            BackgroundTransparency = 0.18,
        })
    end)

    b.MouseButton1Click:Connect(function()
        safe(cb)
    end)
    return b
end

presetButton("Siêu nhẹ", "✦", "Máy yếu", function()
    applyPreset("Siêu nhẹ")
    notification("Đã chọn preset", "Siêu nhẹ đang hoạt động.", "success")
end)

presetButton("Cân bằng", "⚖", "Khuyến nghị", function()
    applyPreset("Cân bằng")
    notification("Đã chọn preset", "Cân bằng đang hoạt động.", "success")
end)

presetButton("Hiệu năng", "🚀", "Ưu tiên FPS", function()
    applyPreset("Hiệu năng")
    notification("Đã chọn preset", "Hiệu năng + mục tiêu 120 FPS.", "success")
end)

presetButton("Tùy chỉnh", "⚙", "Tự chọn", function()
    for _, p in pairs(Pages) do p.Visible = false end
    Pages["FPS Boost"].Visible = true
    CurrentPage = "FPS Boost"
end)

local OptimizeRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 204),
    BackgroundTransparency = 1,
}, Home)

new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
}, OptimizeRow)

local OptLeft = new("Frame", {
    Size = UDim2.new(0.65, -4, 1, 0),
    BackgroundColor3 = COLORS.PANEL,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
}, OptimizeRow)
corner(OptLeft, 12)
stroke(OptLeft, COLORS.BLUE, 0.58, 1)

local lt = label(OptLeft, "🚀 Tối ưu hiệu năng", 13, COLORS.TEXT, true)
lt.Position = UDim2.fromOffset(12, 10)
lt.Size = UDim2.new(1, -24, 0, 22)

local ld = label(OptLeft, "Giảm lag • Tăng FPS • Giảm tải hiệu ứng", 8, COLORS.MUTED, false)
ld.Position = UDim2.fromOffset(12, 30)
ld.Size = UDim2.new(1, -24, 0, 18)

local optButtons = new("Frame", {
    Size = UDim2.new(1, -18, 1, -58),
    Position = UDim2.fromOffset(9, 52),
    BackgroundTransparency = 1,
}, OptLeft)

new("UIListLayout", {
    Padding = UDim.new(0, 5),
}, optButtons)

local function addOptRow(parent, titleText, descText, cb)
    local row = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = Color3.fromRGB(12, 31, 53),
        BackgroundTransparency = 0.16,
        Text = "",
        AutoButtonColor = false,
    }, parent)
    corner(row, 9)
    stroke(row, COLORS.BLUE, 0.78, 1)

    local t = label(row, titleText, 9, COLORS.TEXT, true)
    t.Position = UDim2.fromOffset(10, 3)
    t.Size = UDim2.new(1, -65, 0, 17)

    local d = label(row, descText, 7, COLORS.MUTED, false)
    d.Position = UDim2.fromOffset(10, 19)
    d.Size = UDim2.new(1, -65, 0, 14)

    local dot = new("Frame", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(1, -31, 0.5, -11),
        BackgroundColor3 = COLORS.BLUE,
        BorderSizePixel = 0,
    }, row)
    corner(dot, 999)

    row.MouseButton1Click:Connect(function()
        safe(function() cb(dot) end)
    end)
end

addOptRow(optButtons, "Tăng FPS tối đa (120 FPS)", "Dùng 120 FPS nếu môi trường hỗ trợ.", function(dot)
    local supported = optimize120()
    dot.BackgroundColor3 = supported and COLORS.GREEN or COLORS.YELLOW
    notification("Tối ưu FPS", supported and "Mục tiêu 120 FPS đã được đặt." or "Đã tối ưu đồ họa; không có bộ giới hạn FPS.", supported and "success" or "warning")
end)

addOptRow(optButtons, "Tự động dọn effect", "Xử lý Particle / Trail / Beam mới.", function(dot)
    setFeature("Particles", true)
    setFeature("Trails", true)
    setFeature("Beams", true)
    setFeature("FireSmoke", true)
    dot.BackgroundColor3 = COLORS.GREEN
    notification("Đã dọn effect", "Các hiệu ứng nặng được giảm.", "success")
end)

addOptRow(optButtons, "Tắt hậu kỳ", "Bloom / Blur / SunRays / DOF.", function(dot)
    setFeature("PostFX", true)
    dot.BackgroundColor3 = COLORS.GREEN
    notification("Đã tắt hậu kỳ", "Post Processing đã được tắt.", "success")
end)

addOptRow(optButtons, "Tắt bóng đổ", "Giảm tải render ánh sáng.", function(dot)
    setFeature("Shadows", true)
    dot.BackgroundColor3 = COLORS.GREEN
    notification("Đã tắt bóng đổ", "Shadows đã được giảm.", "success")
end)

local QuickPanel = new("Frame", {
    Size = UDim2.new(0.35, -4, 1, 0),
    BackgroundColor3 = COLORS.PANEL,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
}, OptimizeRow)
corner(QuickPanel, 12)
stroke(QuickPanel, COLORS.BLUE, 0.58, 1)

local qt = label(QuickPanel, "✦ Tiện ích nhanh", 13, COLORS.TEXT, true)
qt.Position = UDim2.fromOffset(12, 10)
qt.Size = UDim2.new(1, -24, 0, 22)

local qd = label(QuickPanel, "Một chạm để thao tác.", 8, COLORS.MUTED, false)
qd.Position = UDim2.fromOffset(12, 30)
qd.Size = UDim2.new(1, -24, 0, 18)

local quickGrid = new("Frame", {
    Size = UDim2.new(1, -16, 1, -58),
    Position = UDim2.fromOffset(8, 52),
    BackgroundTransparency = 1,
}, QuickPanel)

new("UIGridLayout", {
    CellSize = UDim2.new(0.5, -4, 0, 50),
    CellPadding = UDim2.fromOffset(7, 7),
    FillDirectionMaxCells = 2,
}, quickGrid)

local function utilityButton(parent, titleText, subText, cb)
    local b = new("TextButton", {
        BackgroundColor3 = Color3.fromRGB(10, 30, 53),
        BackgroundTransparency = 0.18,
        Text = "",
        AutoButtonColor = false,
    }, parent)
    corner(b, 10)
    stroke(b, COLORS.BLUE, 0.75, 1)

    local i = label(b, "●", 13, COLORS.BLUE2, true)
    i.Position = UDim2.fromOffset(7, 6)
    i.Size = UDim2.fromOffset(20, 18)
    i.TextXAlignment = Enum.TextXAlignment.Center

    local t = label(b, titleText, 8, COLORS.TEXT, true)
    t.Position = UDim2.fromOffset(28, 4)
    t.Size = UDim2.new(1, -32, 0, 17)

    local d = label(b, subText, 6, COLORS.MUTED, false)
    d.Position = UDim2.fromOffset(28, 22)
    d.Size = UDim2.new(1, -32, 0, 20)
    d.TextWrapped = true

    b.MouseButton1Click:Connect(function() safe(cb) end)
end

utilityButton(quickGrid, "Tăng FPS", "Tối ưu tối đa", function()
    optimize120()
    notification("Tăng FPS", "Đã áp dụng tối ưu hiệu năng.", "success")
end)

utilityButton(quickGrid, "Dọn effect", "Particle / Trail / Beam", function()
    setFeature("Particles", true)
    setFeature("Trails", true)
    setFeature("Beams", true)
    notification("Dọn effect", "Đã làm sạch hiệu ứng.", "success")
end)

utilityButton(quickGrid, "Quét lại", "Thống kê client", function()
    local active = 0
    for feature, enabled in pairs(FeatureState) do
        if enabled then
            scanAndDisable(feature)
            active += 1
        end
    end
    notification("Đã quét", tostring(active) .. " nhóm tối ưu đang hoạt động.", "success")
end)

utilityButton(quickGrid, "Khôi phục", "Hoàn tác thay đổi", function()
    restoreAll()
    setFPSCap120(false)
    notification("Khôi phục", "Đã hoàn tác thay đổi.", "success")
end)

utilityButton(quickGrid, "120 FPS", "Nếu môi trường hỗ trợ", function()
    local ok = setFPSCap120(true)
    notification("120 FPS", ok and "Đã đặt cap 120 FPS." or "Môi trường không hỗ trợ setfpscap.", ok and "success" or "warning")
end)

utilityButton(quickGrid, "Cài đặt", "Tùy chỉnh", function()
    for _, p in pairs(Pages) do p.Visible = false end
    Pages["Cài đặt"].Visible = true
    CurrentPage = "Cài đặt"
end)

local StatsRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundTransparency = 1,
}, Home)

new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
}, StatsRow)

local function statCard(titleText)
    local c = card(StatsRow, 64)
    c.Size = UDim2.new(1/3, -6, 1, 0)

    local t = label(c, titleText, 8, COLORS.MUTED, true)
    t.Position = UDim2.fromOffset(9, 6)
    t.Size = UDim2.new(1, -18, 0, 16)

    local v = label(c, "--", 16, COLORS.GREEN, true)
    v.Position = UDim2.fromOffset(9, 24)
    v.Size = UDim2.new(1, -18, 0, 26)

    return v
end

local FPSValue = statCard("FPS")
local PingValue = statCard("PING")
local StatusValue = statCard("TRẠNG THÁI")

--==================================================
-- FPS BOOST
--==================================================

local FPSPage = createPage("FPS Boost")
section(FPSPage, "FPS Boost", "Chọn mức tối ưu phù hợp với máy")

local presetCard = card(FPSPage, 102)

local pt = label(presetCard, "Chế độ tối ưu", 12, COLORS.TEXT, true)
pt.Position = UDim2.fromOffset(13, 10)
pt.Size = UDim2.new(1, -26, 0, 20)

local presetNames = {"Cân bằng", "Hiệu năng", "Siêu nhẹ"}

for i, name in ipairs(presetNames) do
    local b = button(presetCard, name, function()
        applyPreset(name)
        notification("Đổi chế độ", "Đang dùng preset: " .. name, "success")
    end, 112)

    b.Position = UDim2.fromOffset(13 + (i - 1) * 120, 46)
end

makeToggle(FPSPage, "Tắt bóng đổ", "Giảm tải render ánh sáng.", false, function(v)
    setFeature("Shadows", v)
end)

makeToggle(FPSPage, "Tắt Particle", "Ẩn hiệu ứng hạt nặng.", false, function(v)
    setFeature("Particles", v)
end)

makeToggle(FPSPage, "Tắt Trail", "Ẩn vệt chuyển động.", false, function(v)
    setFeature("Trails", v)
end)

makeToggle(FPSPage, "Tắt Beam", "Ẩn hiệu ứng tia.", false, function(v)
    setFeature("Beams", v)
end)

--==================================================
-- ĐỒ HỌA
--==================================================

local Graphics = createPage("Đồ họa")
section(Graphics, "Đồ họa", "Giảm hậu kỳ để ưu tiên tốc độ khung hình")

makeToggle(Graphics, "Tắt Bloom", "Giảm ánh sáng phát sáng.", false, function(v)
    setFeature("PostFX", v)
end)

-- Các nút riêng bên dưới vẫn cùng nhóm PostFX; mỗi toggle hoạt động như gói hậu kỳ.
makeToggle(Graphics, "Giảm nước & Terrain", "Giảm sóng nước và trang trí terrain.", false, function(v)
    setFeature("Terrain", v)
end)

makeToggle(Graphics, "Tắt Color / Blur / DOF", "Tắt các hiệu ứng hậu kỳ còn lại.", false, function(v)
    setFeature("PostFX", v)
end)

makeToggle(Graphics, "Tắt hiệu ứng lửa / khói", "Ẩn Fire, Smoke và Sparkles.", false, function(v)
    setFeature("FireSmoke", v)
end)

--==================================================
-- HIỆU ỨNG
--==================================================

local Effects = createPage("Hiệu ứng")
section(Effects, "Hiệu ứng", "Tắt nhanh các hiệu ứng hình ảnh nặng")

local quick = card(Effects, 86)

local qt = label(quick, "Dọn nhanh", 12, COLORS.TEXT, true)
qt.Position = UDim2.fromOffset(13, 9)
qt.Size = UDim2.new(1, -26, 0, 20)

local qb = button(quick, "🧹 DỌN TẤT CẢ", function()
    setFeature("PostFX", true)
    setFeature("Particles", true)
    setFeature("Trails", true)
    setFeature("Beams", true)
    setFeature("FireSmoke", true)
    notification("Đã dọn hiệu ứng", "Đã tắt các hiệu ứng nặng hiện tại.", "success")
end, 160)

qb.Position = UDim2.fromOffset(13, 40)

local rb = button(quick, "↺ KHÔI PHỤC", function()
    restoreAll()
    notification("Đã khôi phục", "Đồ họa đã trở về trạng thái ban đầu.", "success")
end, 140)

rb.Position = UDim2.fromOffset(182, 40)

makeToggle(Effects, "ParticleEmitter", "Tắt emitter.", false, function(v)
    setFeature("Particles", v)
end)

makeToggle(Effects, "Trail", "Tắt trail.", false, function(v)
    setFeature("Trails", v)
end)

makeToggle(Effects, "Beam", "Tắt beam.", false, function(v)
    setFeature("Beams", v)
end)

makeToggle(Effects, "Post Processing", "Tắt Bloom, Blur, SunRays, ColorCorrection, DOF.", false, function(v)
    setFeature("PostFX", v)
end)

--==================================================
-- NÂNG CAO
--==================================================

local Advanced = createPage("Nâng cao")
section(Advanced, "Nâng cao", "Công cụ kiểm tra và khôi phục")

local scanCard = card(Advanced, 124)

local st = label(scanCard, "Thống kê lần quét gần nhất", 12, COLORS.TEXT, true)
st.Position = UDim2.fromOffset(13, 9)
st.Size = UDim2.new(1, -26, 0, 20)

local summary = label(scanCard, "Chưa có dữ liệu.", 9, COLORS.MUTED, false)
summary.Position = UDim2.fromOffset(13, 33)
summary.Size = UDim2.new(1, -26, 0, 44)
summary.TextWrapped = true

local scan = button(scanCard, "🔎 QUÉT LẠI", function()
    local was = {}
    for k, v in pairs(FeatureState) do
        was[k] = v
    end

    local total = 0

    for feature, enabled in pairs(was) do
        if enabled then
            scanAndDisable(feature)
            total += 1
        end
    end

    summary.Text = string.format(
        "Đã quét: %d object\nParticle: %d • Trail: %d • Beam: %d • PostFX: %d • Lửa/Khói: %d",
        Counts.Scanned,
        Counts.Particles,
        Counts.Trails,
        Counts.Beams,
        Counts.PostFX,
        Counts.FireSmoke
    )

    notification("Quét hoàn tất", "Đã cập nhật thống kê tối ưu.", "success")
end, 130)

scan.Position = UDim2.new(1, -145, 1, -48)

local restoreCard = card(Advanced, 78)

local rt = label(restoreCard, "Khôi phục toàn bộ", 12, COLORS.TEXT, true)
rt.Position = UDim2.fromOffset(13, 8)
rt.Size = UDim2.new(1, -170, 0, 20)

local rd = label(restoreCard, "Trả hiệu ứng, bóng đổ và Terrain về trạng thái đã lưu.", 9, COLORS.MUTED, false)
rd.Position = UDim2.fromOffset(13, 32)
rd.Size = UDim2.new(1, -170, 0, 22)

local restore = button(restoreCard, "RESTORE", function()
    restoreAll()
    notification("Đã khôi phục", "Mọi thay đổi của script đã được hoàn tác.", "success")
end, 120)

restore.Position = UDim2.new(1, -133, 0.5, -18)

local noteCard = card(Advanced, 70)

local note = label(
    noteCard,
    "Không tự ý xoá object gameplay. Script ưu tiên Enabled/thuộc tính hình ảnh để giảm rủi ro lỗi game.",
    9,
    COLORS.MUTED,
    false
)

note.Position = UDim2.fromOffset(13, 0)
note.Size = UDim2.new(1, -26, 1, 0)
note.TextWrapped = true

--==================================================
-- TIỆN ÍCH
--==================================================

local Utilities = createPage("Tiện ích")
section(Utilities, "Tiện ích", "Công cụ nhanh cho trải nghiệm mượt và dễ điều khiển")

local fps120Card = card(Utilities, 112)
local f120t = label(fps120Card, "FPS tối đa 120", 13, COLORS.TEXT, true)
f120t.Position = UDim2.fromOffset(13, 9)
f120t.Size = UDim2.new(1, -190, 0, 22)
local f120d = label(fps120Card, "Yêu cầu game/thiết bị/môi trường hỗ trợ giới hạn FPS.", 9, COLORS.MUTED, false)
f120d.Position = UDim2.fromOffset(13, 34)
f120d.Size = UDim2.new(1, -190, 0, 34)
f120d.TextWrapped = true
local fps120Btn = button(fps120Card, "⚡ BẬT 120 FPS", function()
    local supported = optimize120()
    notification("120 FPS", supported and "Đã đặt giới hạn FPS mục tiêu lên 120." or "Môi trường không có setfpscap; vẫn tối ưu đồ họa.", supported and "success" or "warning")
end, 155)
fps120Btn.Position = UDim2.new(1, -168, 0.5, -18)

local quickCard = card(Utilities, 126)
local qtitle = label(quickCard, "Thao tác nhanh", 13, COLORS.TEXT, true)
qtitle.Position = UDim2.fromOffset(13, 9)
qtitle.Size = UDim2.new(1, -26, 0, 22)
local b1 = button(quickCard, "🚀 Tối ưu tối đa", function()
    optimize120()
    notification("Đã tối ưu", "Preset Hiệu năng + mục tiêu 120 FPS đã được áp dụng.", "success")
end, 150)
b1.Position = UDim2.fromOffset(13, 42)
local b2 = button(quickCard, "🧹 Dọn hiệu ứng", function()
    setFeature("PostFX", true); setFeature("Particles", true); setFeature("Trails", true); setFeature("Beams", true); setFeature("FireSmoke", true)
    notification("Đã dọn", "Các hiệu ứng hình ảnh nặng đã được tắt.", "success")
end, 140)
b2.Position = UDim2.fromOffset(172, 42)
local b3 = button(quickCard, "↺ Khôi phục", function()
    restoreAll(); setFPSCap120(false)
    notification("Đã khôi phục", "Đã hoàn tác các thay đổi của Delta X.", "success")
end, 125)
b3.Position = UDim2.fromOffset(321, 42)

local dragInfo = card(Utilities, 78)
local dragTitle = label(dragInfo, "Nút menu nổi", 12, COLORS.TEXT, true)
dragTitle.Position = UDim2.fromOffset(13, 9)
dragTitle.Size = UDim2.new(1, -26, 0, 20)
local dragDesc = label(dragInfo, "Khi thu nhỏ, giữ và kéo biểu tượng DX để đặt ở bất kỳ vị trí nào trên màn hình.", 9, COLORS.MUTED, false)
dragDesc.Position = UDim2.fromOffset(13, 32)
dragDesc.Size = UDim2.new(1, -26, 0, 32)
dragDesc.TextWrapped = true

--==================================================
-- CÀI ĐẶT
--==================================================

local SettingsPage = createPage("Cài đặt")
section(SettingsPage, "Cài đặt", "Tùy chỉnh menu và thông tin hiển thị")

makeToggle(SettingsPage, "Hiển thị FPS", "Hiện FPS ở trang chủ.", true, function(v)
    Config.ShowFPS = v
    FPSValue.Visible = v
end)

makeToggle(SettingsPage, "Hiển thị Ping", "Hiện ping ở trang chủ.", true, function(v)
    Config.ShowPing = v
    PingValue.Visible = v
end)

makeToggle(SettingsPage, "Thông báo", "Hiện thông báo khi thao tác.", true, function(v)
    Config.Notifications = v
end)

makeToggle(SettingsPage, "Hoạt ảnh giao diện", "Bật/tắt animation của nút.", true, function(v)
    Config.Animations = v
end)

local about = card(SettingsPage, 100)

local at = label(about, "Delta X - Lag Fix", 14, COLORS.TEXT, true)
at.Position = UDim2.fromOffset(13, 10)
at.Size = UDim2.new(1, -26, 0, 22)

local av = label(about, "Phiên bản " .. VERSION .. "\nTác giả: Minh Tiến\nClient-side performance utility\nKhông có auto farm, aimbot, teleport hay bypass.", 9, COLORS.MUTED, false)
av.Position = UDim2.fromOffset(13, 35)
av.Size = UDim2.new(1, -26, 0, 55)
av.TextWrapped = true

--==================================================
-- HIỂN THỊ TRẠNG THÁI
--==================================================

Pages["Trang chủ"].Visible = true
SideButtons["Trang chủ"].Button.BackgroundColor3 = Color3.fromRGB(0, 76, 175)
SideButtons["Trang chủ"].Icon.TextColor3 = COLORS.TEXT
SideButtons["Trang chủ"].Text.TextColor3 = COLORS.TEXT

--==================================================
-- FPS / PING MONITOR
--==================================================

local frameCounter = 0
local elapsed = 0
local displayedFPS = 60

RunService.RenderStepped:Connect(function(dt)
    frameCounter += 1
    elapsed += dt

    if elapsed >= 0.75 then
        local fps = frameCounter / elapsed

        -- Giới hạn hiển thị để tránh số đo dị thường từ executor khi cửa sổ/overlay không được render bình thường.
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
                local value = item:GetValueString()
                PingValue.Text = value
            end)
        end

        if Config.Optimized then
            StatusValue.Text = "Đang tối ưu"
            StatusValue.TextColor3 = COLORS.GREEN
        else
            StatusValue.Text = "Sẵn sàng"
            StatusValue.TextColor3 = COLORS.BLUE2
        end

        frameCounter = 0
        elapsed = 0
    end
end)

--==================================================
-- NÚT AVATAR BẬT / TẮT MENU
--==================================================

local Mini = new("ImageButton", {
    Size = UDim2.fromOffset(58, 58),
    Position = UDim2.new(1, -82, 1, -110),
    BackgroundColor3 = Color3.fromRGB(6, 20, 38),
    BackgroundTransparency = 0.02,
    Image = AVATAR_ID,
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0,
    Visible = true,
    AutoButtonColor = false,
    Active = true,
    ZIndex = 100,
}, ScreenGui)

corner(Mini, 999)
stroke(Mini, COLORS.BLUE2, 0.03, 2)

local MiniRing = new("Frame", {
    Name = "MiniRing",
    Size = UDim2.new(1, 10, 1, 10),
    Position = UDim2.fromOffset(-5, -5),
    BackgroundTransparency = 1,
    Active = false,
    ZIndex = 99,
}, Mini)
corner(MiniRing, 999)
stroke(MiniRing, COLORS.BLUE, 0.55, 2)

local MiniDot = new("Frame", {
    Size = UDim2.fromOffset(9, 9),
    Position = UDim2.new(1, -12, 0, 4),
    BackgroundColor3 = COLORS.GREEN,
    BorderSizePixel = 0,
    ZIndex = 102,
}, Mini)
corner(MiniDot, 999)

local miniWasDragged = false

Mini.MouseButton1Click:Connect(function()
    if miniWasDragged then
        miniWasDragged = false
        return
    end
    Main.Visible = not Main.Visible
end)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

Close.MouseButton1Click:Connect(function()
    restoreAll()
    setFPSCap120(false)

    if DescendantConnection then
        safe(function() DescendantConnection:Disconnect() end)
    end

    safe(function() ScreenGui:Destroy() end)
end)

--==================================================
-- KÉO MENU + NÚT AVATAR + ĐỔI KÍCH THƯỚC
--==================================================

local dragging = false
local dragInput
local dragStart
local startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

do
    local miniDragging = false
    local miniStart
    local miniPos

    Mini.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            miniDragging = true
            miniWasDragged = false
            miniStart = input.Position
            miniPos = Mini.Position
        end
    end)

    Mini.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            miniDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if miniDragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - miniStart
            if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then
                miniWasDragged = true
            end

            Mini.Position = UDim2.new(
                miniPos.X.Scale,
                miniPos.X.Offset + delta.X,
                miniPos.Y.Scale,
                miniPos.Y.Offset + delta.Y
            )
        end
    end)
end

local ResizeHandle = new("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -32, 1, -32),
    BackgroundColor3 = Color3.fromRGB(13, 36, 61),
    BackgroundTransparency = 0.12,
    Text = "↘",
    TextColor3 = COLORS.BLUE2,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 30,
}, Main)

corner(ResizeHandle, 9)
stroke(ResizeHandle, COLORS.BLUE, 0.55, 1)

do
    local resizing = false
    local resizeStart
    local resizeOriginal
    local resizeInput

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            resizeOriginal = Main.Size
        end
    end)

    ResizeHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            resizeInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and input == resizeInput then
            local d = input.Position - resizeStart
            local newW = math.clamp(resizeOriginal.X.Offset + d.X, MIN_W, MAX_W)
            local newH = math.clamp(resizeOriginal.Y.Offset + d.Y, MIN_H, MAX_H)
            Main.Size = UDim2.fromOffset(newW, newH)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
            dragging = false
        end
    end)
end

--==================================================
-- RESPONSIVE MOBILE / DESKTOP
--==================================================

local function layoutMain()
    local camera = Workspace.CurrentCamera
    local mobile = camera and camera.ViewportSize.X <= 800 or false

    local w = Main.AbsoluteSize.X
    local top = 92
    local sideW = mobile and math.clamp(math.floor(w * 0.22), 92, 112)
        or math.clamp(math.floor(w * 0.27), 138, 160)

    local contentX = sideW + 14

    Sidebar.Size = UDim2.new(0, sideW, 1, -100)
    Sidebar.Position = UDim2.fromOffset(8, top)

    for _, page in pairs(Pages) do
        page.Position = UDim2.fromOffset(contentX, top)
        page.Size = UDim2.new(1, -(contentX + 8), 1, -100)
    end

    local compact = mobile or w < 470

    for _, data in pairs(SideButtons) do
        data.Text.Visible = not compact
        if compact then
            data.Icon.Position = UDim2.new(0.5, -13, 0, 0)
        else
            data.Icon.Position = UDim2.fromOffset(8, 0)
        end
    end

    SideProfile.Size = UDim2.new(1, 0, 0, compact and 48 or 54)
    SideAvatar.Visible = not compact
    SideName.Visible = not compact
    SideDesc.Visible = not compact
    Footer.Visible = not compact
    ProfilePill.Visible = not compact

    ResizeHandle.Position = UDim2.new(1, -32, 1, -32)
end

local function fitToViewport()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local vp = camera.ViewportSize
    if vp.X <= 800 then
        local w = math.clamp(math.min(430, vp.X - 18), MIN_W, MAX_W)
        local h = math.clamp(math.min(350, vp.Y - 70), MIN_H, MAX_H)
        Main.Size = UDim2.fromOffset(w, h)
        Main.AnchorPoint = Vector2.new(0.5, 0.5)
        Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    end

    layoutMain()
end

safe(layoutMain)
safe(fitToViewport)

safe(function()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToViewport)
    end
end)

notification("Delta X - Lag Fix", "Đã tải bản " .. VERSION .. " thành công.", "success")

print("Delta X - Lag Fix v" .. VERSION .. " loaded.")

-- Đồng bộ asset ảnh nếu giao diện được parent vào PlayerGui.
task.defer(function()
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("ImageButton") or obj:IsA("ImageLabel") then
                local n = string.lower(obj.Name)
                if n == "avatar" or n == "mini" or n == "floating" or n == "dxtoggle" then
                    obj.Image = AVATAR_ID
                    obj.ScaleType = Enum.ScaleType.Crop
                elseif n == "banner" or n == "bannerimage" or n == "headerimage" then
                    obj.Image = BANNER_ID
                    obj.ScaleType = Enum.ScaleType.Crop
                end
            end
        end
    end)
end)
