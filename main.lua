--[[
    Delta X - Lag Fix
    Client-side FPS / Graphics Optimizer
    No gameplay automation
    v1.0
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

--//====================================================
--// CONFIG
--//====================================================

local Config = {
    FPSBoost = false,
    Particles = false,
    Trails = false,
    Beams = false,
    PostFX = false,
    Shadows = false,
    Textures = false,
    Terrain = false,
    Decorations = false,

    ShowFPS = true,
    ShowPing = true,

    Preset = "Balanced"
}

local Saved = {
    Lighting = {},
    Effects = {},
    Terrain = {},
    Parts = {}
}

--//====================================================
--// SAFE CALL
--//====================================================

local function safe(fn, ...)
    local ok, result = pcall(fn, ...)
    return ok, result
end

--//====================================================
--// GUI ROOT
--//====================================================

local GuiParent

safe(function()
    if gethui then
        GuiParent = gethui()
    else
        GuiParent = game:GetService("CoreGui")
    end
end)

if not GuiParent then
    GuiParent = Player:WaitForChild("PlayerGui")
end

local old = GuiParent:FindFirstChild("DeltaX_LagFix")
if old then
    old:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaX_LagFix"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

--//====================================================
--// HELPERS
--//====================================================

local function New(class, props, parent)
    local obj = Instance.new(class)

    for k, v in pairs(props or {}) do
        safe(function()
            obj[k] = v
        end)
    end

    obj.Parent = parent
    return obj
end

local function Corner(obj, radius)
    New("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, obj)
end

local function Stroke(obj, color, transparency, thickness)
    New("UIStroke", {
        Color = color or Color3.fromRGB(40, 120, 255),
        Transparency = transparency or 0,
        Thickness = thickness or 1
    }, obj)
end

local function Gradient(obj, c1, c2, rotation)
    local g = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2)
        }),
        Rotation = rotation or 0
    }, obj)

    return g
end

local function Text(parent, text, size, color, bold)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Color3.fromRGB(235, 240, 255),
        TextSize = size or 14,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)
end

--//====================================================
--// COLORS
--//====================================================

local BG = Color3.fromRGB(5, 10, 20)
local PANEL = Color3.fromRGB(9, 18, 32)
local PANEL2 = Color3.fromRGB(12, 25, 43)
local BLUE = Color3.fromRGB(0, 125, 255)
local BLUE2 = Color3.fromRGB(45, 170, 255)
local TEXT = Color3.fromRGB(235, 242, 255)
local MUTED = Color3.fromRGB(135, 155, 180)
local GREEN = Color3.fromRGB(45, 230, 110)
local RED = Color3.fromRGB(255, 75, 90)

--//====================================================
--// MAIN WINDOW
--//====================================================

local Main = New("Frame", {
    Size = UDim2.new(0, 720, 0, 470),
    Position = UDim2.new(0.5, -360, 0.5, -235),
    BackgroundColor3 = BG,
    BorderSizePixel = 0
}, ScreenGui)

Corner(Main, 14)
Stroke(Main, Color3.fromRGB(0, 115, 255), 0.25, 1)

Gradient(
    Main,
    Color3.fromRGB(5, 15, 30),
    Color3.fromRGB(3, 7, 14),
    90
)

--//====================================================
--// HEADER
--//====================================================

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundTransparency = 1
}, Main)

local Logo = New("Frame", {
    Size = UDim2.new(0, 45, 0, 45),
    Position = UDim2.new(0, 12, 0, 9),
    BackgroundColor3 = Color3.fromRGB(0, 90, 210)
}, Header)

Corner(Logo, 12)

local LogoText = Text(
    Logo,
    "▶",
    25,
    Color3.fromRGB(255,255,255),
    true
)

LogoText.Size = UDim2.fromScale(1,1)
LogoText.TextXAlignment = Enum.TextXAlignment.Center
LogoText.TextYAlignment = Enum.TextYAlignment.Center

local Title = Text(Header, "Delta X - Lag Fix", 18, TEXT, true)
Title.Position = UDim2.new(0, 68, 0, 10)
Title.Size = UDim2.new(0, 300, 0, 25)

local Subtitle = Text(
    Header,
    "Tối ưu hiệu suất • Mượt mà hơn",
    11,
    MUTED,
    false
)

Subtitle.Position = UDim2.new(0, 68, 0, 34)
Subtitle.Size = UDim2.new(0, 300, 0, 20)

local Version = Text(Header, "v1.0", 11, BLUE2, true)
Version.Position = UDim2.new(1, -95, 0, 12)
Version.Size = UDim2.new(0, 35, 0, 20)
Version.TextXAlignment = Enum.TextXAlignment.Right

--//====================================================
--// WINDOW BUTTONS
--//====================================================

local Minimize = New("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -70, 0, 12),
    BackgroundColor3 = PANEL2,
    Text = "—",
    TextColor3 = TEXT,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, Header)

Corner(Minimize, 8)

local Close = New("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 12),
    BackgroundColor3 = PANEL2,
    Text = "×",
    TextColor3 = TEXT,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, Header)

Corner(Close, 8)

--//====================================================
--// SIDEBAR
--//====================================================

local Sidebar = New("Frame", {
    Size = UDim2.new(0, 160, 1, -75),
    Position = UDim2.new(0, 10, 0, 70),
    BackgroundColor3 = Color3.fromRGB(6, 14, 26),
    BorderSizePixel = 0
}, Main)

Corner(Sidebar, 12)

local SideLayout = New("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, Sidebar)

New("UIPadding", {
    PaddingTop = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8)
}, Sidebar)

local Pages = {}
local SideButtons = {}

local function CreatePage(name)
    local page = New("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, -185, 1, -75),
        Position = UDim2.new(0, 175, 0, 70),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = BLUE,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, Main)

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 15)
    }, page)

    Pages[name] = page
    return page
end

local function CreateSideButton(name, icon)
    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(7, 17, 30),
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #SideButtons + 1
    }, Sidebar)

    Corner(btn, 8)

    local ic = Text(btn, icon, 16, MUTED, true)
    ic.Position = UDim2.new(0, 10, 0, 0)
    ic.Size = UDim2.new(0, 25, 1, 0)
    ic.TextXAlignment = Enum.TextXAlignment.Center
    ic.TextYAlignment = Enum.TextYAlignment.Center

    local label = Text(btn, name, 12, MUTED, true)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.Size = UDim2.new(1, -45, 1, 0)
    label.TextYAlignment = Enum.TextYAlignment.Center

    SideButtons[name] = {
        Button = btn,
        Icon = ic,
        Label = label
    }

    btn.MouseButton1Click:Connect(function()
        for n, data in pairs(SideButtons) do
            data.Button.BackgroundColor3 = Color3.fromRGB(7,17,30)
            data.Icon.TextColor3 = MUTED
            data.Label.TextColor3 = MUTED
        end

        btn.BackgroundColor3 = Color3.fromRGB(0, 80, 180)
        ic.TextColor3 = TEXT
        label.TextColor3 = TEXT

        for _, p in pairs(Pages) do
            p.Visible = false
        end

        Pages[name].Visible = true
    end)

    return btn
end

CreateSideButton("Trang chủ", "⌂")
CreateSideButton("FPS Boost", "◉")
CreateSideButton("Đồ họa", "▣")
CreateSideButton("Hiệu ứng", "✦")
CreateSideButton("Nâng cao", "⚙")
CreateSideButton("Cài đặt", "⚙")

local Footer = Text(
    Sidebar,
    "◆ Made for Delta X",
    9,
    BLUE2,
    true
)

Footer.Position = UDim2.new(0, 10, 1, -25)
Footer.Size = UDim2.new(1, -20, 0, 20)

--//====================================================
--// PAGE HELPERS
--//====================================================

local function SectionTitle(page, title, desc)
    local holder = New("Frame", {
        Size = UDim2.new(1,0,0,55),
        BackgroundTransparency = 1
    }, page)

    local t = Text(holder, title, 22, TEXT, true)
    t.Size = UDim2.new(1,0,0,30)

    local d = Text(holder, desc or "", 11, MUTED, false)
    d.Position = UDim2.new(0,0,0,30)
    d.Size = UDim2.new(1,0,0,20)

    return holder
end

local function Card(page, height)
    local frame = New("Frame", {
        Size = UDim2.new(1,0,0,height or 55),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0
    }, page)

    Corner(frame, 10)
    Stroke(frame, Color3.fromRGB(25,55,85), 0.55, 1)

    return frame
end

local function Button(parent, text, callback, width)
    local b = New("TextButton", {
        Size = UDim2.new(0, width or 150, 0, 38),
        BackgroundColor3 = BLUE,
        Text = text,
        TextColor3 = TEXT,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    }, parent)

    Corner(b, 8)

    b.MouseEnter:Connect(function()
        b.BackgroundColor3 = BLUE2
    end)

    b.MouseLeave:Connect(function()
        b.BackgroundColor3 = BLUE
    end)

    b.MouseButton1Click:Connect(function()
        safe(callback)
    end)

    return b
end

local function Toggle(page, title, description, default, callback)
    local card = Card(page, 60)

    local t = Text(card, title, 12, TEXT, true)
    t.Position = UDim2.new(0, 14, 0, 8)
    t.Size = UDim2.new(1, -90, 0, 20)

    local d = Text(card, description or "", 9, MUTED, false)
    d.Position = UDim2.new(0, 14, 0, 30)
    d.Size = UDim2.new(1, -90, 0, 20)

    local switch = New("TextButton", {
        Size = UDim2.new(0, 44, 0, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = default and BLUE or Color3.fromRGB(35,48,65),
        Text = "",
        AutoButtonColor = false
    }, card)

    Corner(switch, 20)

    local knob = New("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = default
            and UDim2.new(1,-21,0.5,-9)
            or UDim2.new(0,3,0.5,-9),
        BackgroundColor3 = Color3.fromRGB(240,245,255)
    }, switch)

    Corner(knob, 20)

    local state = default

    local function Set(v)
        state = v

        switch.BackgroundColor3 =
            state and BLUE or Color3.fromRGB(35,48,65)

        knob.Position = state
            and UDim2.new(1,-21,0.5,-9)
            or UDim2.new(0,3,0.5,-9)

        safe(callback, state)
    end

    switch.MouseButton1Click:Connect(function()
        Set(not state)
    end)

    return {
        Set = Set,
        Get = function()
            return state
        end
    }
end

--//====================================================
--// OPTIMIZATION FUNCTIONS
--//====================================================

local function DisablePostFX()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("BloomEffect")
        or obj:IsA("BlurEffect")
        or obj:IsA("SunRaysEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("DepthOfFieldEffect") then

            if Saved.Effects[obj] == nil then
                Saved.Effects[obj] = obj.Enabled
            end

            obj.Enabled = false
        end
    end
end

local function EnablePostFX()
    for obj, state in pairs(Saved.Effects) do
        if obj and obj.Parent then
            safe(function()
                obj.Enabled = state
            end)
        end
    end
end

local function DisableParticles()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            if Saved.Parts[obj] == nil then
                Saved.Parts[obj] = obj.Enabled
            end
            obj.Enabled = false
        end
    end
end

local function DisableTrails()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Trail") then
            if Saved.Parts[obj] == nil then
                Saved.Parts[obj] = obj.Enabled
            end
            obj.Enabled = false
        end
    end
end

local function DisableBeams()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Beam") then
            if Saved.Parts[obj] == nil then
                Saved.Parts[obj] = obj.Enabled
            end
            obj.Enabled = false
        end
    end
end

local function RestoreAll()
    EnablePostFX()

    for obj, state in pairs(Saved.Parts) do
        if obj and obj.Parent then
            safe(function()
                obj.Enabled = state
            end)
        end
    end

    safe(function()
        Lighting.GlobalShadows = Saved.Lighting.GlobalShadows
    end)

    safe(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")

        if terrain and Saved.Terrain.WaterWaveSize then
            terrain.WaterWaveSize = Saved.Terrain.WaterWaveSize
            terrain.WaterWaveSpeed = Saved.Terrain.WaterWaveSpeed
            terrain.WaterReflectance = Saved.Terrain.WaterReflectance
            terrain.WaterTransparency = Saved.Terrain.WaterTransparency
        end
    end)
end

--// SAVE ORIGINAL SETTINGS

safe(function()
    Saved.Lighting.GlobalShadows = Lighting.GlobalShadows
end)

safe(function()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")

    if terrain then
        Saved.Terrain.WaterWaveSize = terrain.WaterWaveSize
        Saved.Terrain.WaterWaveSpeed = terrain.WaterWaveSpeed
        Saved.Terrain.WaterReflectance = terrain.WaterReflectance
        Saved.Terrain.WaterTransparency = terrain.WaterTransparency
    end
end)

--//====================================================
--// HOME PAGE
--//====================================================

local Home = CreatePage("Trang chủ")

SectionTitle(
    Home,
    "Tối ưu Roblox",
    "Giảm tải client • Tăng FPS • Mượt hơn"
)

local Hero = Card(Home, 150)

local Rocket = Text(Hero, "🚀", 40, BLUE2, true)
Rocket.Position = UDim2.new(0, 20, 0, 20)
Rocket.Size = UDim2.new(0, 70, 0, 60)
Rocket.TextXAlignment = Enum.TextXAlignment.Center

local HeroTitle = Text(Hero, "Sẵn sàng tối ưu", 18, TEXT, true)
HeroTitle.Position = UDim2.new(0, 105, 0, 22)
HeroTitle.Size = UDim2.new(1, -120, 0, 28)

local HeroDesc = Text(
    Hero,
    "Tắt các hiệu ứng không cần thiết và giảm tải đồ họa.",
    10,
    MUTED
)

HeroDesc.Position = UDim2.new(0, 105, 0, 52)
HeroDesc.Size = UDim2.new(1, -120, 0, 35)

local OptimizeButton = Button(
    Hero,
    "⚡  BẬT TỐI ƯU NGAY",
    function()
        Config.FPSBoost = true
        DisablePostFX()
        DisableParticles()
        DisableTrails()
        DisableBeams()

        safe(function()
            Lighting.GlobalShadows = false
        end)
    end,
    190
)

OptimizeButton.Position = UDim2.new(0, 105, 1, -52)

local StatsFrame = New("Frame", {
    Size = UDim2.new(1,0,0,90),
    BackgroundTransparency = 1
}, Home)

local function StatCard(pos, title)
    local c = Card(StatsFrame, 80)
    c.Size = UDim2.new(0.31,0,1,0)
    c.Position = pos

    local t = Text(c, title, 10, MUTED, true)
    t.Position = UDim2.new(0,12,0,10)
    t.Size = UDim2.new(1,-24,0,20)

    local v = Text(c, "--", 20, GREEN, true)
    v.Position = UDim2.new(0,12,0,32)
    v.Size = UDim2.new(1,-24,0,30)

    return v
end

local FPSValue = StatCard(UDim2.new(0,0,0,0), "FPS")
local PingValue = StatCard(UDim2.new(0.345,0,0,0), "PING")
local StatusValue = StatCard(UDim2.new(0.69,0,0,0), "STATUS")

--//====================================================
--// FPS PAGE
--//====================================================

local FPSPage = CreatePage("FPS Boost")

SectionTitle(
    FPSPage,
    "FPS Boost",
    "Các chế độ tối ưu hiệu suất"
)

local PresetCard = Card(FPSPage, 100)

local PresetTitle = Text(PresetCard, "Chế độ tối ưu", 13, TEXT, true)
PresetTitle.Position = UDim2.new(0,14,0,12)
PresetTitle.Size = UDim2.new(1,-28,0,22)

local presets = {"Balanced", "Performance", "Potato"}

for i, preset in ipairs(presets) do
    local b = Button(PresetCard, preset, function()
        Config.Preset = preset

        if preset == "Performance" then
            DisablePostFX()
            DisableParticles()
            DisableTrails()
            DisableBeams()

            safe(function()
                Lighting.GlobalShadows = false
            end)

        elseif preset == "Potato" then
            DisablePostFX()
            DisableParticles()
            DisableTrails()
            DisableBeams()

            safe(function()
                Lighting.GlobalShadows = false
            end)

            local terrain = Workspace:FindFirstChildOfClass("Terrain")

            if terrain then
                safe(function()
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                end)
            end

        elseif preset == "Balanced" then
            DisablePostFX()
            DisableParticles()
        end
    end, 130)

    b.Position = UDim2.new(0, 14 + (i-1)*140, 0, 48)
end

Toggle(
    FPSPage,
    "Tắt bóng đổ",
    "Giảm tải render",
    false,
    function(v)
        safe(function()
            Lighting.GlobalShadows = not v
        end)
    end
)

Toggle(
    FPSPage,
    "Tắt Particle",
    "Giảm hiệu ứng hạt",
    false,
    function(v)
        if v then
            DisableParticles()
        else
            RestoreAll()
        end
    end
)

Toggle(
    FPSPage,
    "Tắt Trail",
    "Giảm hiệu ứng chuyển động",
    false,
    function(v)
        if v then
            DisableTrails()
        else
            RestoreAll()
        end
    end
)

Toggle(
    FPSPage,
    "Tắt Beam",
    "Giảm hiệu ứng tia",
    false,
    function(v)
        if v then
            DisableBeams()
        else
            RestoreAll()
        end
    end
)

--//====================================================
--// GRAPHICS PAGE
--//====================================================

local Graphics = CreatePage("Đồ họa")

SectionTitle(
    Graphics,
    "Đồ họa",
    "Giảm hiệu ứng hình ảnh để ưu tiên FPS"
)

Toggle(
    Graphics,
    "Tắt Bloom",
    "Loại bỏ ánh sáng phát sáng",
    false,
    function(v)
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("BloomEffect") then
                obj.Enabled = not v
            end
        end
    end
)

Toggle(
    Graphics,
    "Tắt Blur",
    "Loại bỏ hiệu ứng mờ",
    false,
    function(v)
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("BlurEffect") then
                obj.Enabled = not v
            end
        end
    end
)

Toggle(
    Graphics,
    "Tắt Sun Rays",
    "Giảm hiệu ứng tia nắng",
    false,
    function(v)
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("SunRaysEffect") then
                obj.Enabled = not v
            end
        end
    end
)

Toggle(
    Graphics,
    "Tắt Color Correction",
    "Giảm hậu kỳ màu",
    false,
    function(v)
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("ColorCorrectionEffect") then
                obj.Enabled = not v
            end
        end
    end
)

Toggle(
    Graphics,
    "Tắt Depth Of Field",
    "Giảm hiệu ứng chiều sâu",
    false,
    function(v)
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("DepthOfFieldEffect") then
                obj.Enabled = not v
            end
        end
    end
)

--//====================================================
--// EFFECT PAGE
--//====================================================

local Effects = CreatePage("Hiệu ứng")

SectionTitle(
    Effects,
    "Hiệu ứng",
    "Tắt các hiệu ứng không cần thiết"
)

Toggle(
    Effects,
    "Particle Effects",
    "Tắt ParticleEmitter",
    false,
    function(v)
        if v then
            DisableParticles()
        end
    end
)

Toggle(
    Effects,
    "Trail Effects",
    "Tắt Trail",
    false,
    function(v)
        if v then
            DisableTrails()
        end
    end
)

Toggle(
    Effects,
    "Beam Effects",
    "Tắt Beam",
    false,
    function(v)
        if v then
            DisableBeams()
        end
    end
)

Toggle(
    Effects,
    "Post Processing",
    "Tắt toàn bộ hậu kỳ",
    false,
    function(v)
        if v then
            DisablePostFX()
        else
            EnablePostFX()
        end
    end
)

--//====================================================
--// ADVANCED PAGE
--//====================================================

local Advanced = CreatePage("Nâng cao")

SectionTitle(
    Advanced,
    "Nâng cao",
    "Các tùy chọn tối ưu bổ sung"
)

local Cleanup = Card(Advanced, 100)

local CT = Text(
    Cleanup,
    "Dọn hiệu ứng một lần",
    13,
    TEXT,
    true
)

CT.Position = UDim2.new(0,14,0,12)
CT.Size = UDim2.new(1,-180,0,22)

local CD = Text(
    Cleanup,
    "Quét client và tắt các hiệu ứng nặng hiện tại.",
    10,
    MUTED
)

CD.Position = UDim2.new(0,14,0,38)
CD.Size = UDim2.new(1,-180,0,30)

local CleanButton = Button(
    Cleanup,
    "DỌN NGAY",
    function()
        DisablePostFX()
        DisableParticles()
        DisableTrails()
        DisableBeams()
    end,
    120
)

CleanButton.Position = UDim2.new(1,-135,0.5,-19)

local RestoreCard = Card(Advanced, 80)

local RT = Text(
    RestoreCard,
    "Khôi phục đồ họa",
    13,
    TEXT,
    true
)

RT.Position = UDim2.new(0,14,0,10)
RT.Size = UDim2.new(1,-180,0,22)

local RD = Text(
    RestoreCard,
    "Khôi phục những thiết lập đã lưu.",
    10,
    MUTED
)

RD.Position = UDim2.new(0,14,0,35)
RD.Size = UDim2.new(1,-180,0,20)

local RestoreButton = Button(
    RestoreCard,
    "RESTORE",
    RestoreAll,
    120
)

RestoreButton.Position = UDim2.new(1,-135,0.5,-19)

--//====================================================
--// SETTINGS PAGE
--//====================================================

local Settings = CreatePage("Cài đặt")

SectionTitle(
    Settings,
    "Cài đặt",
    "Tùy chỉnh giao diện và thông tin"
)

Toggle(
    Settings,
    "Hiển thị FPS",
    "Hiển thị FPS trên menu",
    true,
    function(v)
        Config.ShowFPS = v
    end
)

Toggle(
    Settings,
    "Hiển thị Ping",
    "Hiển thị ping hiện tại",
    true,
    function(v)
        Config.ShowPing = v
    end
)

local Info = Card(Settings, 110)

local IT = Text(
    Info,
    "Delta X - Lag Fix",
    15,
    TEXT,
    true
)

IT.Position = UDim2.new(0,14,0,12)
IT.Size = UDim2.new(1,-28,0,25)

local ID = Text(
    Info,
    "Client-side performance utility\nKhông thay đổi gameplay.",
    10,
    MUTED
)

ID.Position = UDim2.new(0,14,0,40)
ID.Size = UDim2.new(1,-28,0,50)

--//====================================================
--// DEFAULT PAGE
--//====================================================

Pages["Trang chủ"].Visible = true

SideButtons["Trang chủ"].Button.BackgroundColor3 = Color3.fromRGB(0,80,180)
SideButtons["Trang chủ"].Icon.TextColor3 = TEXT
SideButtons["Trang chủ"].Label.TextColor3 = TEXT

--//====================================================
--// FPS / PING MONITOR
--//====================================================

local frames = 0
local last = os.clock()
local currentFPS = 60

RunService.RenderStepped:Connect(function()
    frames += 1

    local now = os.clock()

    if now - last >= 1 then
        currentFPS = frames / (now - last)
        frames = 0
        last = now

        FPSValue.Text = tostring(math.floor(currentFPS + 0.5))

        if currentFPS >= 55 then
            FPSValue.TextColor3 = GREEN
        elseif currentFPS >= 30 then
            FPSValue.TextColor3 = Color3.fromRGB(255,210,70)
        else
            FPSValue.TextColor3 = RED
        end

        safe(function()
            local ping = Stats.Network.ServerStatsItem[
                "Data Ping"
            ]:GetValueString()

            PingValue.Text = ping
        end)

        if Config.FPSBoost then
            StatusValue.Text = "Đang tối ưu"
            StatusValue.TextColor3 = GREEN
        else
            StatusValue.Text = "Sẵn sàng"
            StatusValue.TextColor3 = BLUE2
        end
    end
end)

--//====================================================
--// FLOATING MINI BUTTON
--//====================================================

local Mini = New("TextButton", {
    Size = UDim2.new(0, 58, 0, 58),
    Position = UDim2.new(0, 20, 0.5, -29),
    BackgroundColor3 = Color3.fromRGB(5,18,35),
    Text = "▶",
    TextColor3 = BLUE2,
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    Visible = false,
    AutoButtonColor = false
}, ScreenGui)

Corner(Mini, 18)
Stroke(Mini, BLUE, 0.25, 1)

Mini.MouseButton1Click:Connect(function()
    Mini.Visible = false
    Main.Visible = true
end)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Mini.Visible = true
end)

Close.MouseButton1Click:Connect(function()
    RestoreAll()
    ScreenGui:Destroy()
end)

--//====================================================
--// DRAG SYSTEM - MOBILE + PC
--//====================================================

local dragging = false
local dragStart
local startPos

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

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--//====================================================
--// RESPONSIVE MOBILE SIZE
--//====================================================

local function Resize()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize

    if viewport.X < 700 then
        Main.Size = UDim2.new(
            1, -20,
            0, math.min(470, viewport.Y - 30)
        )

        Main.Position = UDim2.new(
            0.5, 0,
            0.5, 0
        )

        Main.AnchorPoint = Vector2.new(0.5,0.5)
    else
        Main.AnchorPoint = Vector2.new(0,0)
        Main.Size = UDim2.new(0,720,0,470)
        Main.Position = UDim2.new(0.5,-360,0.5,-235)
    end
end

safe(function()
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(Resize)
end)

Resize()

print("Delta X - Lag Fix loaded successfully.")
