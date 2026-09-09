--[[
    Delta X - Lag Fix
    Phiên bản: 1.4
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

local VERSION = "1.4"
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

local Main = new("Frame", {
    Size = UDim2.fromOffset(640, 430),
    Position = UDim2.new(0.5, -320, 0.5, -215),
    BackgroundColor3 = COLORS.BG,
    BorderSizePixel = 0,
    Active = true,
}, ScreenGui)

corner(Main, 14)
stroke(Main, Color3.fromRGB(0, 120, 255), 0.25, 1)

-- Thu gọn giao diện để không chiếm gần hết màn hình.
local MainScale = new("UIScale", {Scale = 0.82}, Main)

--==================================================
-- HEADER
--==================================================

local Header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 62),
    BackgroundTransparency = 1,
    Active = true,
}, Main)

-- Banner artwork supplied by the user.
local BannerImage = new("ImageLabel", {
    Size = UDim2.fromOffset(250, 52),
    Position = UDim2.new(0, 345, 0, 5),
    BackgroundTransparency = 1,
    Image = BANNER_ID,
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0.06,
    ZIndex = 0,
}, Header)
corner(BannerImage, 12)

local Logo = new("Frame", {
    Size = UDim2.fromOffset(42, 42),
    Position = UDim2.fromOffset(12, 10),
    BackgroundColor3 = Color3.fromRGB(0, 83, 190),
}, Header)

corner(Logo, 11)

local LogoText = label(Logo, "▶", 24, COLORS.TEXT, true)
LogoText.Size = UDim2.fromScale(1, 1)
LogoText.TextXAlignment = Enum.TextXAlignment.Center

local Title = label(Header, "Delta X - Lag Fix", 18, COLORS.TEXT, true)
Title.Position = UDim2.fromOffset(65, 7)
Title.Size = UDim2.new(0, 300, 0, 24)

local Subtitle = label(Header, "Tối ưu hiệu suất • Mượt hơn • Nhẹ hơn", 10, COLORS.MUTED, false)
Subtitle.Position = UDim2.fromOffset(65, 31)
Subtitle.Size = UDim2.new(0, 330, 0, 18)

local Version = label(Header, "v" .. VERSION, 10, COLORS.BLUE2, true)
Version.Position = UDim2.new(1, -120, 0, 10)
Version.Size = UDim2.fromOffset(35, 22)
Version.TextXAlignment = Enum.TextXAlignment.Right

local Minimize = new("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -72, 0, 9),
    BackgroundColor3 = COLORS.PANEL2,
    Text = "—",
    TextColor3 = COLORS.TEXT,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, Header)

corner(Minimize, 8)

local Close = new("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -36, 0, 9),
    BackgroundColor3 = COLORS.PANEL2,
    Text = "×",
    TextColor3 = COLORS.TEXT,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, Header)

corner(Close, 8)

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = new("Frame", {
    Size = UDim2.new(0, 160, 1, -76),
    Position = UDim2.fromOffset(10, 68),
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

local Pages = {}
local SideButtons = {}
local CurrentPage = "Trang chủ"

local function createPage(name)
    local page = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, -182, 1, -76),
        Position = UDim2.fromOffset(173, 68),
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
section(Home, "Tối ưu Roblox", "Giảm tải đồ họa • Theo dõi FPS • Khôi phục dễ dàng")

local Hero = card(Home, 142)

local heroIcon = label(Hero, "⚡", 36, COLORS.BLUE2, true)
heroIcon.Position = UDim2.fromOffset(18, 20)
heroIcon.Size = UDim2.fromOffset(65, 60)
heroIcon.TextXAlignment = Enum.TextXAlignment.Center

local heroTitle = label(Hero, "Sẵn sàng tối ưu", 17, COLORS.TEXT, true)
heroTitle.Position = UDim2.fromOffset(95, 18)
heroTitle.Size = UDim2.new(1, -110, 0, 25)

local heroDesc = label(Hero, "Tắt hiệu ứng nặng và giảm tải render mà không xoá object.", 9, COLORS.MUTED, false)
heroDesc.Position = UDim2.fromOffset(95, 48)
heroDesc.Size = UDim2.new(1, -110, 0, 34)

local Optimize = button(Hero, "⚡ BẬT TỐI ƯU", function()
    local supported = optimize120()
    local msg = supported and "Đã bật tối ưu hiệu năng + mục tiêu 120 FPS." or "Đã tối ưu đồ họa; môi trường hiện tại không hỗ trợ đặt cap 120 FPS."
    notification("Đã tối ưu", msg, supported and "success" or "warning")
end, 180)

Optimize.Position = UDim2.fromOffset(95, 96)

local StatsRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 84),
    BackgroundTransparency = 1,
}, Home)

local statsLayout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, StatsRow)

local function statCard(titleText)
    local c = card(StatsRow, 84)
    c.Size = UDim2.new(1/3, -6, 1, 0)

    local t = label(c, titleText, 9, COLORS.MUTED, true)
    t.Position = UDim2.fromOffset(11, 8)
    t.Size = UDim2.new(1, -22, 0, 18)

    local v = label(c, "--", 19, COLORS.GREEN, true)
    v.Position = UDim2.fromOffset(11, 30)
    v.Size = UDim2.new(1, -22, 0, 30)

    return v
end

local FPSValue = statCard("FPS")
local PingValue = statCard("PING")
local StatusValue = statCard("TRẠNG THÁI")

local InfoCard = card(Home, 58)
local info = label(InfoCard, "Mẹo: dùng “Cân bằng” để giảm hiệu ứng nhưng vẫn giữ hình ảnh.", 9, COLORS.MUTED, false)
info.Position = UDim2.fromOffset(12, 0)
info.Size = UDim2.new(1, -24, 1, 0)

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
-- NÚT THU NHỎ
--==================================================

local Mini = new("ImageButton", {
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.new(0, 14, 0.5, -27),
    BackgroundColor3 = Color3.fromRGB(5, 19, 36),
    BackgroundTransparency = 0.08,
    Image = AVATAR_ID,
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0,
    Visible = false,
    AutoButtonColor = false,
    Active = true,
}, ScreenGui)

corner(Mini, 1)
stroke(Mini, COLORS.BLUE, 0.12, 2)

Mini.MouseButton1Click:Connect(function()
    Mini.Visible = false
    Main.Visible = true
end)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Mini.Visible = true
end)

Close.MouseButton1Click:Connect(function()
    restoreAll()
    setFPSCap120(false)

    if DescendantConnection then
        safe(function() DescendantConnection:Disconnect() end)
    end

    safe(function() ScreenGui:Destroy() end)
end)

-- Nút nổi cũng kéo được khi menu đang thu nhỏ.
do
    local miniDragging, miniStart, miniPos = false, nil, nil
    Mini.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            miniDragging = true; miniStart = input.Position; miniPos = Mini.Position
        end
    end)
    Mini.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then miniDragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if miniDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - miniStart
            Mini.Position = UDim2.new(miniPos.X.Scale, miniPos.X.Offset + d.X, miniPos.Y.Scale, miniPos.Y.Offset + d.Y)
        end
    end)
end

--==================================================
-- KÉO MENU: CHUỘT + CẢM ỨNG
--==================================================

local dragging = false
local dragInput
local dragStart
local startPos

local function updateDrag(input)
    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

--==================================================
-- RESPONSIVE MOBILE
--==================================================

local function resize()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local vp = camera.ViewportSize
    local mobile = vp.X <= 800

    -- Tỉ lệ vừa phải: menu không phủ kín màn hình.
    local scale = mobile and math.clamp(math.min((vp.X - 24) / 640, (vp.Y - 110) / 430), 0.62, 0.78)
        or math.clamp(math.min((vp.X - 80) / 640, (vp.Y - 120) / 430), 0.78, 0.92)

    MainScale.Scale = scale
    Main.Size = UDim2.fromOffset(640, 430)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)

    if mobile then
        Sidebar.Size = UDim2.new(0, 112, 1, -76)
        Sidebar.Position = UDim2.fromOffset(8, 68)

        for _, data in pairs(SideButtons) do
            data.Text.Visible = false
            data.Icon.Position = UDim2.new(0.5, -13, 0, 0)
        end

        for _, page in pairs(Pages) do
            page.Position = UDim2.fromOffset(130, 68)
            page.Size = UDim2.new(1, -138, 1, -76)
        end
    else
        Sidebar.Size = UDim2.new(0, 145, 1, -76)
        Sidebar.Position = UDim2.fromOffset(10, 68)

        for _, data in pairs(SideButtons) do
            data.Text.Visible = true
            data.Icon.Position = UDim2.fromOffset(8, 0)
        end

        for _, page in pairs(Pages) do
            page.Position = UDim2.fromOffset(158, 68)
            page.Size = UDim2.new(1, -167, 1, -76)
        end
    end
end

safe(function()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    end
end)

resize()

notification("Delta X - Lag Fix", "Đã tải bản " .. VERSION .. " thành công.", "success")

print("Delta X - Lag Fix v" .. VERSION .. " loaded.")

-- Apply uploaded Delta X artwork after UI is built.
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
