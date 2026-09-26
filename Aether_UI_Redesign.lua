--[[
============================================================
 AETHER  v2.5  —  Light Glass · Menu Fix · VIP Lag · Key Auth
 Full: Lag Fix VIP + Music + AI + Speed + Spin + Godmode
       + ESP + Sword + Aura + Invis + Items + Save + Login
============================================================
]]

repeat task.wait() until game:IsLoaded()

if _G.Aether_Engine then
	pcall(function()
		if type(_G.Aether_Engine) == "table" and _G.Aether_Engine.Destroy then
			_G.Aether_Engine:Destroy()
		end
	end)
end

local VERSION = "2.5"
local APP_NAME = "Aether"
local ScriptAlive = true
local SESSION_START = os.clock()

--------------------------------------------------
-- SERVICES
--------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local SoundService     = game:GetService("SoundService")
local Stats            = game:GetService("Stats")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait() LocalPlayer = Players.LocalPlayer end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 12)

-- Early boot indicator (always visible if anything works)
local function parentGui(gui)
	local ok = false
	pcall(function()
		if gethui then gui.Parent = gethui() ok = true end
	end)
	if not ok then pcall(function() gui.Parent = CoreGui ok = true end) end
	if not ok and PlayerGui then pcall(function() gui.Parent = PlayerGui ok = true end) end
	return ok
end

local BootGui = Instance.new("ScreenGui")
BootGui.Name = "AetherBoot"
BootGui.ResetOnSpawn = false
BootGui.IgnoreGuiInset = true
BootGui.DisplayOrder = 1000000
BootGui.Enabled = true
parentGui(BootGui)
local BootLbl = Instance.new("TextLabel")
BootLbl.Size = UDim2.fromOffset(220, 36)
BootLbl.Position = UDim2.new(0.5, -110, 0.08, 0)
BootLbl.BackgroundColor3 = Color3.fromRGB(0, 185, 155)
BootLbl.BackgroundTransparency = 0.1
BootLbl.Text = "Aether · loading…"
BootLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
BootLbl.Font = Enum.Font.GothamBold
BootLbl.TextSize = 14
BootLbl.Parent = BootGui
Instance.new("UICorner", BootLbl).CornerRadius = UDim.new(0, 10)

if not PlayerGui then
	BootLbl.Text = "Aether · PlayerGui missing"
	warn("[Aether] PlayerGui missing")
end
task.delay(6, function()
	pcall(function()
		if BootGui and BootGui.Parent and BootLbl then
			BootLbl.Text = "Aether · still loading / check F9"
			BootLbl.BackgroundColor3 = Color3.fromRGB(230, 70, 90)
		end
	end)
end)

--------------------------------------------------
-- DESIGN TOKENS
--------------------------------------------------
local THEME = {
	BG              = Color3.fromRGB(236, 242, 250),
	Glass           = Color3.fromRGB(255, 255, 255),
	GlassStrong     = Color3.fromRGB(248, 252, 255),
	Card            = Color3.fromRGB(255, 255, 255),
	CardElevated    = Color3.fromRGB(245, 250, 255),
	Primary         = Color3.fromRGB(0, 185, 155),
	Secondary       = Color3.fromRGB(70, 130, 255),
	Accent          = Color3.fromRGB(150, 90, 255),
	Danger          = Color3.fromRGB(230, 70, 90),
	Warning         = Color3.fromRGB(235, 150, 40),
	Success         = Color3.fromRGB(0, 175, 130),
	TextPrimary     = Color3.fromRGB(18, 28, 42),
	TextSecondary   = Color3.fromRGB(70, 90, 115),
	TextMuted       = Color3.fromRGB(120, 135, 155),
	Stroke          = Color3.fromRGB(180, 205, 235),
	On              = Color3.fromRGB(0, 185, 155),
	Off             = Color3.fromRGB(220, 228, 238),
	AIBubble        = Color3.fromRGB(240, 246, 255),
	UserBubble      = Color3.fromRGB(220, 250, 242),
}

local SPACING = { XS = 4, SM = 8, MD = 12, LG = 16, XL = 20, XXL = 28 }
local RADIUS  = { Micro = 8, Small = 12, Medium = 16, Large = 20, Hero = 22, Shell = 28, Island = 20, Dock = 26 }
local ANIM    = { FAST = 0.12, NORMAL = 0.22, MEDIUM = 0.32, SLOW = 0.45, SPRING = 0.36 }

--------------------------------------------------
-- CONFIG
--------------------------------------------------
local Config = {
	FPSCap = 0, AutoBoost = false, LowDevice = false,
	Shadows = true, Terrain = true, PostFX = true,
	Particles = true, Trails = true, Beams = true, FireSmoke = true,
	MusicVolume = 0.5, MusicMuted = false, MusicLoop = true, MusicId = "",
	WalkSpeed = 16,
	Fullscreen = false,
	SpinEnabled = false,
	SpinSpeed = 20,
	Godmode = false,
	ESPEnabled = false,
	ESPBox = true,
	ESPName = true,
	ESPTracer = false,
	ESPRainbow = false,
	ESPCircle = false,
	SwordOrbit = false,
	SwordSpeed = 30,
	SwordAura = true,
	Invisibility = false,
	AimEnabled = false,
	AimFOV = 120,
	AimSmooth = 0.35,
	AimShowCircle = true,
	ShiftLock = false,
	Noclip = false,
	Fly = false,
	FlySpeed = 50,
	InfJump = false,
	ClickTP = false,
	Language = "vi", -- "vi" | "en"
	SavedKey = "",
	VipLag = false,
	KeyType = "free", -- "free" | "vip"
}

--------------------------------------------------
-- AUTH + SAVE
--------------------------------------------------
-- Key database: type + expiry (unix). nil expires = never
-- Types: vip | pro | free | trial
local function parseExpiry(str)
	-- "YYYY-MM-DD HH:MM:SS" or "YYYY-MM-DD"
	if type(str) ~= "string" then return nil end
	local y, m, d, H, M, S = str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)%s+(%d%d):(%d%d):(%d%d)$")
	if not y then
		y, m, d = str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
		H, M, S = 23, 59, 59
	end
	if not y then return nil end
	return os.time({
		year = tonumber(y), month = tonumber(m), day = tonumber(d),
		hour = tonumber(H) or 23, min = tonumber(M) or 59, sec = tonumber(S) or 59,
	})
end

local VALID_KEYS = {
	-- VIP lifetime test
	["mtdz"] = { type = "vip", expires = parseExpiry("2099-12-31 23:59:59"), label = "VIP Lifetime" },
	["aether"] = { type = "vip", expires = parseExpiry("2099-12-31 23:59:59"), label = "VIP Lifetime" },
	-- PRO 1 year
	["pro2026"] = { type = "pro", expires = parseExpiry("2027-01-01 00:00:00"), label = "PRO 2026" },
	-- Free / demo
	["demo"] = { type = "free", expires = parseExpiry("2026-12-31 23:59:59"), label = "Free Demo" },
	["free"] = { type = "free", expires = parseExpiry("2026-12-31 23:59:59"), label = "Free" },
	-- Trial 7-day style (fixed end date for demo)
	["trial"] = { type = "trial", expires = parseExpiry("2026-10-31 23:59:59"), label = "Trial" },
	-- Day key example
	["daykey"] = { type = "free", expires = parseExpiry("2026-09-27 23:59:59"), label = "1-Day" },
}

local SAVE_FILE = "AetherConfig.json"
local AUTHENTICATED = false

local function serializeConfig()
	local parts = {}
	for k, v in pairs(Config) do
		local t = type(v)
		if t == "string" then
			table.insert(parts, string.format("%s=%q", k, v))
		elseif t == "number" or t == "boolean" then
			table.insert(parts, string.format("%s=%s", k, tostring(v)))
		end
	end
	return table.concat(parts, "\n")
end

local function deserializeConfig(raw)
	if type(raw) ~= "string" then return end
	for line in string.gmatch(raw, "[^\r\n]+") do
		local k, v = string.match(line, "^([%w_]+)=(.+)$")
		if k and v and Config[k] ~= nil then
			if v == "true" then Config[k] = true
			elseif v == "false" then Config[k] = false
			elseif tonumber(v) then Config[k] = tonumber(v)
			else
				local s = string.match(v, '^"(.*)"$') or string.match(v, "^'(.*)'$")
				if s then Config[k] = s end
			end
		end
	end
end

local function saveConfig()
	local ok, err = pcall(function()
		local data = serializeConfig()
		if writefile then
			writefile(SAVE_FILE, data)
		elseif isfolder and makefolder and writefile then
			writefile(SAVE_FILE, data)
		else
			-- fallback: store in _G
			_G.Aether_SavedConfig = data
		end
	end)
	return ok, err
end

local function loadConfig()
	local ok, data = pcall(function()
		if readfile and isfile and isfile(SAVE_FILE) then
			return readfile(SAVE_FILE)
		elseif _G.Aether_SavedConfig then
			return _G.Aether_SavedConfig
		end
		return nil
	end)
	if ok and data then
		deserializeConfig(data)
		return true
	end
	return false
end

local function formatTimeLeft(exp)
	if not exp then return "Lifetime hạn" end
	local left = exp - os.time()
	if left <= 0 then return "Hết hạn" end
	local d = math.floor(left / 86400)
	local h = math.floor((left % 86400) / 3600)
	local m = math.floor((left % 3600) / 60)
	if d > 0 then return string.format("%dd %dh", d, h) end
	if h > 0 then return string.format("%dh %dm", h, m) end
	return string.format("%dm", m)
end

local function validateKey(key)
	key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if key == "" then return false, nil, "Empty key" end

	local entry = VALID_KEYS[key]
	if not entry then
		local lower = string.lower(key)
		for k, v in pairs(VALID_KEYS) do
			if string.lower(k) == lower then entry = v break end
		end
	end
	if not entry then return false, nil, "Invalid key" end

	local typ = entry.type or "free"
	local exp = entry.expires
	if exp and os.time() > exp then
		return false, typ, "Key expired (" .. (entry.label or typ) .. ")"
	end
	return true, typ, entry.label or typ, exp
end

pcall(loadConfig)

--------------------------------------------------
-- STATE
--------------------------------------------------
local UIState = {
	CurrentPage = "Home",
	MainVisible = false,
	IslandState = "COLLAPSED",
	IslandContent = "IDLE",
	Authenticated = false,
}

local MusicState = {
	Playing = false, Muted = false, Loop = true,
	Volume = 0.5, SoundId = "", Title = "Unknown Track",
}

local BoostState = { Preset = "Balanced", FPSCap = 0, AutoBoost = false }
local AIState    = { Busy = false }

--------------------------------------------------
-- LOCALIZATION
--------------------------------------------------
local L = {}

local function setLanguage(lang)
	Config.Language = lang or "vi"
	if Config.Language == "en" then
		L = {
			Ready = "Ready to enhance your Roblox session.",
			Overview = "OVERVIEW",
			QuickOptimize = "⚡   Quick Optimize",
			SmartCleanup = "♻   Smart Cleanup",
			PerformanceMode = "PERFORMANCE MODE",
			LowDevice = "📱   Low Device",
			Performance = "⚡   Performance",
			Balanced = "⚖   Balanced",
			RestoreAll = "♻   Restore All",
			FPSCap = "FPS CAP",
			AutoBoost = "Auto Boost",
			Lighting = "LIGHTING",
			Shadows = "Shadows",
			World = "WORLD",
			TerrainWater = "Terrain Water",
			PostProcessing = "POST PROCESSING",
			PostFX = "Post FX",
			Effects = "EFFECTS",
			Particles = "Particles",
			Trails = "Trails",
			Beams = "Beams",
			FireSmoke = "Fire / Smoke",
			Cleanup = "CLEANUP",
			SmartCleanupNow = "♻   Smart Cleanup Now",
			NowPlaying = "NOW PLAYING",
			UnknownTrack = "Unknown Track",
			RobloxSound = "Roblox Sound",
			Stopped = "Stopped",
			Playing = "Playing",
			Muted = "Muted",
			SoundID = "SOUND ID",
			EnterSoundID = "Enter Sound ID or URL",
			Play = "▶  Play",
			Stop = "⏹  Stop",
			Mute = "🔇  Mute",
			Volume = "VOLUME",
			Loop = "Loop  ·  Repeat this sound",
			AskAether = "Ask Aether…",
			Utilities = "UTILITIES",
			Fullscreen = "Fullscreen",
			SpeedTitle = "WALK SPEED (Max 1000)",
			Apply = "Apply",
			ResetSpeed = "↺ Reset Speed (16)",
			SpinTitle = "SPIN 360°",
			EnableSpin = "Enable Spin",
			SpinSpeed = "Spin Speed",
			Godmode = "Godmode",
			ESPTitle = "ESP (R6 + R15)",
			ESPFull = "ESP Full (Name + Box + HP)",
			ESPDesc = "ESP supports both R6 and R15.\nShows Name + Box + Health.",
			SwordTitle = "ORBIT SWORD",
			EnableSword = "Orbit Sword",
			SwordSpeed = "Orbit Speed",
			SwordAura = "Sword Aura",
			InvisTitle = "INVISIBILITY",
			EnableInvis = "Invisibility",
			ItemsTitle = "ITEMS",
			SelectItem = "Select an item",
			ClaimItem = "Get Item",
			PlayOnSpeaker = "Play on Speaker",
			SpeakerIdHint = "Sound ID for speaker",
			ClearItems = "Clear All Items",
			SaveTitle = "SAVE",
			SaveConfig = "Save Settings",
			SaveDone = "Settings saved",
			SaveFail = "Save failed",
			Language = "LANGUAGE",
			Vietnamese = "Tiếng Việt",
			English = "English",
			Enabled = "Enabled",
			Disabled = "Disabled",
			Speed = "Speed",
		}
	else
		L = {
			Ready = "Sẵn sàng nâng cấp trải nghiệm Roblox của bạn.",
			Overview = "TỔNG QUAN",
			QuickOptimize = "⚡   Tối ưu nhanh",
			SmartCleanup = "♻   Dọn dẹp thông minh",
			PerformanceMode = "CHẾ ĐỘ HIỆU NĂNG",
			LowDevice = "📱   Máy yếu",
			Performance = "⚡   Hiệu năng",
			Balanced = "⚖   Cân bằng",
			RestoreAll = "♻   Khôi phục tất cả",
			FPSCap = "GIỚI HẠN FPS",
			AutoBoost = "Tự động Boost",
			Lighting = "ÁNH SÁNG",
			Shadows = "Đổ bóng",
			World = "THẾ GIỚI",
			TerrainWater = "Nước địa hình",
			PostProcessing = "HẬU KỲ",
			PostFX = "Hiệu ứng hậu kỳ",
			Effects = "HIỆU ỨNG",
			Particles = "Hạt",
			Trails = "Vệt",
			Beams = "Tia",
			FireSmoke = "Lửa / Khói",
			Cleanup = "DỌN DẸP",
			SmartCleanupNow = "♻   Dọn dẹp ngay",
			NowPlaying = "ĐANG PHÁT",
			UnknownTrack = "Bài hát không xác định",
			RobloxSound = "Âm thanh Roblox",
			Stopped = "Đã dừng",
			Playing = "Đang phát",
			Muted = "Tắt tiếng",
			SoundID = "SOUND ID",
			EnterSoundID = "Nhập Sound ID hoặc URL",
			Play = "▶  Phát",
			Stop = "⏹  Dừng",
			Mute = "🔇  Tắt tiếng",
			Volume = "ÂM LƯỢNG",
			Loop = "Lặp lại  ·  Lặp bài hát này",
			AskAether = "Hỏi Aether…",
			Utilities = "TIỆN ÍCH",
			Fullscreen = "Toàn hình",
			SpeedTitle = "TỐC ĐỘ CHẠY (Tối đa 1000)",
			Apply = "Áp dụng",
			ResetSpeed = "↺ Đặt lại tốc độ (16)",
			SpinTitle = "XOAY 360°",
			EnableSpin = "Bật Spin",
			SpinSpeed = "Tốc độ xoay",
			Godmode = "Bất tử",
			ESPTitle = "ESP (R6 + R15)",
			ESPFull = "ESP Full (Tên + Hộp + Máu)",
			ESPDesc = "ESP hỗ trợ cả R6 và R15.\nHiển thị Tên + Hộp + Máu.",
			SwordTitle = "THANH KIẾM QUAY",
			EnableSword = "Bật thanh kiếm quay",
			SwordSpeed = "Tốc độ quay kiếm",
			SwordAura = "Aura thanh kiếm",
			InvisTitle = "TÀN HÌNH",
			EnableInvis = "Bật tàn hình",
			ItemsTitle = "VẬT PHẨM",
			SelectItem = "Chọn vật phẩm",
			ClaimItem = "Lấy vật phẩm",
			PlayOnSpeaker = "Phát trên loa",
			SpeakerIdHint = "Sound ID cho loa",
			ClearItems = "Xóa tất cả vật phẩm",
			SaveTitle = "LƯU",
			SaveConfig = "Lưu cài đặt",
			SaveDone = "Đã lưu cài đặt",
			SaveFail = "Lưu thất bại",
			Language = "NGÔN NGỮ",
			Vietnamese = "Tiếng Việt",
			English = "English",
			Enabled = "Đã bật",
			Disabled = "Đã tắt",
			Speed = "Tốc độ",
		}
	end
end
setLanguage(Config.Language)

--------------------------------------------------
-- HELPERS
--------------------------------------------------
local Connections = {}
local function reg(c) table.insert(Connections, c) return c end

local function tween(obj, props, dur, style, dir)
	if not obj or not ScriptAlive then return end
	local t = TweenService:Create(obj, TweenInfo.new(dur or ANIM.NORMAL, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function spring(obj, props, dur)
	return tween(obj, props, dur or ANIM.SPRING, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or RADIUS.Medium)
	c.Parent = p
	return c
end

local function stroke(p, col, tr, th)
	local s = Instance.new("UIStroke")
	s.Color = col or THEME.Stroke
	s.Transparency = tr or 0.6
	s.Thickness = th or 1
	s.Parent = p
	return s
end

local function label(parent, text, size, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextSize = size or 13
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextColor3 = color or THEME.TextPrimary
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.ZIndex = (parent and parent.ZIndex or 1) + 1
	l.Parent = parent
	return l
end

local function pad(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.Parent = parent
	return p
end

--------------------------------------------------
-- ORIGINAL STATE
--------------------------------------------------
local Original = {
	GlobalShadows = true,
	FogEnd = 1000,
	Brightness = 1,
	QualityLevel = Enum.QualityLevel.Automatic,
	WalkSpeed = 16,
}
pcall(function()
	Original.GlobalShadows = Lighting.GlobalShadows
	Original.FogEnd = Lighting.FogEnd
	Original.Brightness = Lighting.Brightness
	Original.QualityLevel = settings().Rendering.QualityLevel
end)
pcall(function()
	Original.TerrainWaterWaveSize = Workspace.Terrain.WaterWaveSize
	Original.TerrainWaterWaveSpeed = Workspace.Terrain.WaterWaveSpeed
	Original.TerrainWaterReflectance = Workspace.Terrain.WaterReflectance
	Original.TerrainWaterTransparency = Workspace.Terrain.WaterTransparency
end)

--------------------------------------------------
-- PERFORMANCE
--------------------------------------------------
local function setFPSCap(n)
	Config.FPSCap = n or 0
	BoostState.FPSCap = Config.FPSCap
	pcall(function()
		if setfpscap then setfpscap(Config.FPSCap > 0 and Config.FPSCap or 999) end
	end)
end

local function applyLightingBoost(level)
	pcall(function()
		if level >= 1 then
			Lighting.GlobalShadows = false
			Config.Shadows = false
		else
			Lighting.GlobalShadows = Original.GlobalShadows
			Config.Shadows = Original.GlobalShadows
		end
		if level >= 2 then
			Lighting.FogEnd = 1e6
			Lighting.Brightness = math.min(Lighting.Brightness, 1.2)
		end
		if level >= 3 then
			pcall(function() pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end) end)
		end
	end)
end

local function setFeature(name, enabled)
	Config[name] = enabled
	task.spawn(function()
		if name == "Shadows" then
			pcall(function() Lighting.GlobalShadows = enabled end)
		elseif name == "Terrain" then
			pcall(function()
				local t = Workspace.Terrain
				if not enabled then
					t.WaterWaveSize, t.WaterWaveSpeed, t.WaterReflectance, t.WaterTransparency = 0, 0, 0, 1
				else
					t.WaterWaveSize = Original.TerrainWaterWaveSize or 0.15
					t.WaterWaveSpeed = Original.TerrainWaterWaveSpeed or 10
					t.WaterReflectance = Original.TerrainWaterReflectance or 0.2
					t.WaterTransparency = Original.TerrainWaterTransparency or 0.3
				end
			end)
		elseif name == "PostFX" then
			pcall(function()
				for _, fx in ipairs(Lighting:GetChildren()) do
					if fx:IsA("BlurEffect") or fx:IsA("BloomEffect") or fx:IsA("SunRaysEffect")
						or fx:IsA("ColorCorrectionEffect") or fx:IsA("DepthOfFieldEffect") then
						fx.Enabled = enabled
					end
				end
			end)
		elseif name == "Particles" or name == "Trails" or name == "Beams" or name == "FireSmoke" then
			local budget, t0, list, i = 0.004, os.clock(), Workspace:GetDescendants(), 1
			while i <= #list and ScriptAlive do
				local inst = list[i]; i += 1
				pcall(function()
					if name == "Particles" and (inst:IsA("ParticleEmitter") or inst:IsA("Smoke") or inst:IsA("Sparkles")) then
						inst.Enabled = enabled
					elseif name == "Trails" and inst:IsA("Trail") then
						inst.Enabled = enabled
					elseif name == "Beams" and inst:IsA("Beam") then
						inst.Enabled = enabled
					elseif name == "FireSmoke" and (inst:IsA("Fire") or inst:IsA("Smoke")) then
						inst.Enabled = enabled
					end
				end)
				if os.clock() - t0 > budget then task.wait() t0 = os.clock() end
			end
		end
	end)
end

local function smartCleanup()
	task.spawn(function()
		local budget, t0 = 0.005, os.clock()
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if not ScriptAlive then break end
			pcall(function()
				if inst:IsA("ParticleEmitter") and inst.Rate > 40 then
					inst.Rate = math.min(inst.Rate, 20)
				elseif inst:IsA("Explosion") then
					inst:Destroy()
				end
			end)
			if os.clock() - t0 > budget then task.wait() t0 = os.clock() end
		end
	end)
end

local VipLagConnection = nil
local function applyVipLag(on)
	Config.VipLag = on
	if VipLagConnection then
		pcall(function() VipLagConnection:Disconnect() end)
		VipLagConnection = nil
	end
	if not on then
		applyPreset("Restore")
		return
	end
	Config.LowDevice = true
	setFPSCap(60)
	applyLightingBoost(3)
	for _, f in ipairs({"Particles","Trails","Beams","FireSmoke","PostFX","Terrain","Shadows"}) do
		setFeature(f, false)
	end
	pcall(function()
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.Brightness = 1
	end)
	smartCleanup()
	-- periodic ultra cleanup while VIP lag is on
	VipLagConnection = RunService.Heartbeat:Connect(function()
		if not ScriptAlive or not Config.VipLag then return end
	end)
	reg(VipLagConnection)
	task.spawn(function()
		while ScriptAlive and Config.VipLag do
			pcall(smartCleanup)
			task.wait(45)
		end
	end)
end

local function applyPreset(name)
	BoostState.Preset = name
	if name == "VIP" or name == "Vip" then
		applyVipLag(true)
		BoostState.Preset = "VIP"
	elseif name == "Low" then
		Config.VipLag = false
		Config.LowDevice = true; setFPSCap(30); applyLightingBoost(3)
		for _, f in ipairs({"Particles","Trails","Beams","FireSmoke","PostFX","Terrain","Shadows"}) do setFeature(f, false) end
		smartCleanup()
	elseif name == "Performance" then
		Config.VipLag = false
		Config.LowDevice = false; setFPSCap(60); applyLightingBoost(2)
		setFeature("Particles", false); setFeature("Trails", true); setFeature("Beams", false)
		setFeature("FireSmoke", false); setFeature("PostFX", false); setFeature("Terrain", true); setFeature("Shadows", false)
	elseif name == "Balanced" then
		Config.VipLag = false
		Config.LowDevice = false; setFPSCap(0); applyLightingBoost(1)
		for _, f in ipairs({"Particles","Trails","Beams","FireSmoke","PostFX","Terrain","Shadows"}) do setFeature(f, true) end
	elseif name == "Restore" then
		Config.VipLag = false
		Config.LowDevice = false; setFPSCap(0)
		pcall(function()
			Lighting.GlobalShadows = Original.GlobalShadows
			Lighting.FogEnd = Original.FogEnd
			Lighting.Brightness = Original.Brightness
			pcall(function() settings().Rendering.QualityLevel = Original.QualityLevel end)
		end)
		for _, f in ipairs({"Particles","Trails","Beams","FireSmoke","PostFX","Terrain"}) do setFeature(f, true) end
		setFeature("Shadows", Original.GlobalShadows)
	end
end

local function panicReset()
	pcall(function()
		applyVipLag(false)
		applyPreset("Restore")
		setSpin(false)
		setGodmode(false)
		setESP(false)
		setSwordOrbit(false)
		setInvisibility(false)
		setWalkSpeed(16)
		clearItems()
		-- aim / lock / utils / emote cleared when those locals exist
		if setAim then setAim(false) end
		if setShiftLock then setShiftLock(false) end
		if setNoclip then setNoclip(false) end
		if setFly then setFly(false) end
		if setInfJump then setInfJump(false) end
		if setClickTP then setClickTP(false) end
		if stopEmote then stopEmote() end
	end)
end

--------------------------------------------------
-- SPEED
--------------------------------------------------
local function setWalkSpeed(value)
	Config.WalkSpeed = math.clamp(tonumber(value) or 16, 0, 1000)
	pcall(function()
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = Config.WalkSpeed end
		end
	end)
end

reg(LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.35)
	if ScriptAlive then
		setWalkSpeed(Config.WalkSpeed)
		if Config.Godmode then
			local hum = char:WaitForChild("Humanoid", 5)
			if hum then
				hum.MaxHealth = math.huge
				hum.Health = math.huge
			end
		end
	end
end))

--------------------------------------------------
-- SPIN
--------------------------------------------------
local SpinConnection = nil
local function setSpin(enabled, speed)
	Config.SpinEnabled = enabled
	Config.SpinSpeed = math.clamp(tonumber(speed) or 20, 1, 200)
	if SpinConnection then
		SpinConnection:Disconnect()
		SpinConnection = nil
	end
	if not enabled then return end
	SpinConnection = RunService.Heartbeat:Connect(function(dt)
		if not ScriptAlive or not Config.SpinEnabled then return end
		local char = LocalPlayer.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed * 60 * dt), 0)
		end
	end)
	reg(SpinConnection)
end

--------------------------------------------------
-- GODMODE
--------------------------------------------------
local GodConnection = nil
local function setGodmode(enabled)
	Config.Godmode = enabled
	if GodConnection then
		GodConnection:Disconnect()
		GodConnection = nil
	end
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			if enabled then
				hum.MaxHealth = math.huge
				hum.Health = math.huge
			else
				hum.MaxHealth = 100
				hum.Health = 100
			end
		end
	end
	if enabled then
		GodConnection = RunService.Heartbeat:Connect(function()
			if not ScriptAlive or not Config.Godmode then return end
			local c = LocalPlayer.Character
			if c then
				local h = c:FindFirstChildOfClass("Humanoid")
				if h and h.Health < h.MaxHealth then
					h.Health = h.MaxHealth
				end
			end
		end)
		reg(GodConnection)
	end
end

--------------------------------------------------
-- ESP  (Box · Name · Tracer · Rainbow · Circle)
--------------------------------------------------
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "AetherESP"
ESPFolder.Parent = CoreGui
local ESPObjects = {}

local function rainbowColor(t)
	local h = (t * 0.15) % 1
	return Color3.fromHSV(h, 0.9, 1)
end

local function clearESP()
	for _, objs in pairs(ESPObjects) do
		pcall(function()
			if objs.box then objs.box:Destroy() end
			if objs.name then objs.name:Destroy() end
			if objs.tracer then objs.tracer:Destroy() end
			if objs.circle then objs.circle:Destroy() end
		end)
	end
	table.clear(ESPObjects)
end

local function createESP(player)
	if player == LocalPlayer or ESPObjects[player] then return end

	local box = Instance.new("BoxHandleAdornment")
	box.Name = "ESPBox"
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Size = Vector3.new(4, 6, 2)
	box.Color3 = THEME.Primary
	box.Transparency = 0.5
	box.Visible = Config.ESPBox
	box.Parent = ESPFolder

	local bill = Instance.new("BillboardGui")
	bill.Name = "ESPName"
	bill.Size = UDim2.fromOffset(120, 40)
	bill.StudsOffset = Vector3.new(0, 3.2, 0)
	bill.AlwaysOnTop = true
	bill.Enabled = Config.ESPName
	bill.Parent = ESPFolder

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.fromScale(1, 0.55)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = player.Name
	nameLbl.TextColor3 = THEME.Primary
	nameLbl.TextStrokeTransparency = 0.35
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 13
	nameLbl.Parent = bill

	local hpLbl = Instance.new("TextLabel")
	hpLbl.Size = UDim2.fromScale(1, 0.45)
	hpLbl.Position = UDim2.fromScale(0, 0.55)
	hpLbl.BackgroundTransparency = 1
	hpLbl.Text = "100"
	hpLbl.TextColor3 = THEME.Success
	hpLbl.TextStrokeTransparency = 0.35
	hpLbl.Font = Enum.Font.Gotham
	hpLbl.TextSize = 11
	hpLbl.Parent = bill

	-- Tracer line (from local HRP toward target)
	local tracer = Instance.new("Beam")
	tracer.Name = "ESPTracer"
	tracer.Width0 = 0.12
	tracer.Width1 = 0.04
	tracer.FaceCamera = true
	tracer.LightEmission = 0.6
	tracer.Transparency = NumberSequence.new(0.25)
	tracer.Color = ColorSequence.new(THEME.Primary)
	tracer.Enabled = Config.ESPTracer
	tracer.Parent = ESPFolder
	local att0 = Instance.new("Attachment")
	att0.Name = "TracerA0"
	att0.Parent = ESPFolder
	local att1 = Instance.new("Attachment")
	att1.Name = "TracerA1"
	att1.Parent = ESPFolder
	tracer.Attachment0 = att0
	tracer.Attachment1 = att1

	-- Circle ring under feet
	local circle = Instance.new("CylinderHandleAdornment")
	circle.Name = "ESPCircle"
	circle.AlwaysOnTop = true
	circle.Height = 0.12
	circle.Radius = 2.4
	circle.Color3 = THEME.Secondary
	circle.Transparency = 0.35
	circle.Visible = Config.ESPCircle
	circle.CFrame = CFrame.Angles(0, 0, math.rad(90))
	circle.Parent = ESPFolder

	ESPObjects[player] = {
		box = box, name = bill, health = hpLbl, nameLbl = nameLbl,
		tracer = tracer, att0 = att0, att1 = att1, circle = circle,
	}
end

local function updateESP()
	if not Config.ESPEnabled then return end
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local t = os.clock()
	local col = Config.ESPRainbow and rainbowColor(t) or THEME.Primary

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		local char = player.Character
		if not char then
			local objs = ESPObjects[player]
			if objs then
				if objs.box then objs.box.Adornee = nil end
				if objs.name then objs.name.Adornee = nil end
				if objs.circle then objs.circle.Adornee = nil end
				if objs.tracer then objs.tracer.Enabled = false end
			end
			continue
		end
		if not ESPObjects[player] then createESP(player) end
		local objs = ESPObjects[player]
		local root = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")
		local hum = char:FindFirstChildOfClass("Humanoid")

		if root and objs.box then
			objs.box.Adornee = root
			objs.box.Visible = Config.ESPBox
			objs.box.Color3 = col
			local isR15 = char:FindFirstChild("UpperTorso") ~= nil
			objs.box.Size = isR15 and Vector3.new(3.5, 6.5, 2) or Vector3.new(4, 5.5, 2)
		end
		if head and objs.name then
			objs.name.Adornee = head
			objs.name.Enabled = Config.ESPName
			if objs.nameLbl then objs.nameLbl.TextColor3 = col end
		end
		if hum and objs.health then
			local hp = math.floor(hum.Health)
			objs.health.Text = tostring(hp)
			if hp > 70 then objs.health.TextColor3 = THEME.Success
			elseif hp > 30 then objs.health.TextColor3 = THEME.Warning
			else objs.health.TextColor3 = THEME.Danger end
		end
		-- Tracer
		if objs.tracer and objs.att0 and objs.att1 and myRoot and root and Config.ESPTracer then
			objs.att0.Parent = myRoot
			objs.att0.Position = Vector3.zero
			objs.att1.Parent = root
			objs.att1.Position = Vector3.zero
			objs.tracer.Enabled = true
			objs.tracer.Color = ColorSequence.new(col)
		elseif objs.tracer then
			objs.tracer.Enabled = false
		end
		-- Circle under feet
		if root and objs.circle then
			objs.circle.Adornee = root
			objs.circle.Visible = Config.ESPCircle
			objs.circle.Color3 = col
			objs.circle.CFrame = CFrame.new(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90))
		end
	end
end

local ESPConnection = nil
local function setESP(enabled)
	Config.ESPEnabled = enabled
	if ESPConnection then
		ESPConnection:Disconnect()
		ESPConnection = nil
	end
	if not enabled then
		clearESP()
		return
	end
	for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
	ESPConnection = RunService.RenderStepped:Connect(function()
		if ScriptAlive and Config.ESPEnabled then updateESP() end
	end)
	reg(ESPConnection)
end

reg(Players.PlayerRemoving:Connect(function(player)
	if ESPObjects[player] then
		pcall(function()
			local o = ESPObjects[player]
			if o.box then o.box:Destroy() end
			if o.name then o.name:Destroy() end
			if o.tracer then o.tracer:Destroy() end
			if o.circle then o.circle:Destroy() end
			if o.att0 then o.att0:Destroy() end
			if o.att1 then o.att1:Destroy() end
		end)
		ESPObjects[player] = nil
	end
end))

--------------------------------------------------
-- AIM  (FOV circle + smooth look)
--------------------------------------------------
local AimCircleGui = nil
local AimCircleFrame = nil
local AimConnection = nil

local function ensureAimCircle()
	if AimCircleGui and AimCircleGui.Parent then return end
	AimCircleGui = Instance.new("ScreenGui")
	AimCircleGui.Name = "AetherAimFOV"
	AimCircleGui.IgnoreGuiInset = true
	AimCircleGui.DisplayOrder = 999998
	AimCircleGui.ResetOnSpawn = false
	local parent = PlayerGui
	pcall(function() if gethui then parent = gethui() end end)
	AimCircleGui.Parent = parent

	AimCircleFrame = Instance.new("Frame")
	AimCircleFrame.Name = "FOV"
	AimCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	AimCircleFrame.Position = UDim2.fromScale(0.5, 0.5)
	AimCircleFrame.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
	AimCircleFrame.BackgroundTransparency = 1
	AimCircleFrame.Visible = false
	AimCircleFrame.Parent = AimCircleGui

	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.Primary
	stroke.Thickness = 1.5
	stroke.Transparency = 0.35
	stroke.Parent = AimCircleFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = AimCircleFrame

	-- center dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(4, 4)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.BackgroundColor3 = THEME.Primary
	dot.BackgroundTransparency = 0.2
	dot.BorderSizePixel = 0
	dot.Parent = AimCircleFrame
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
end

local function getClosestInFOV()
	local cam = Workspace.CurrentCamera
	if not cam then return nil end
	local center = cam.ViewportSize / 2
	local best, bestDist = nil, Config.AimFOV
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == LocalPlayer then continue end
		local char = plr.Character
		local head = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not head or not hum or hum.Health <= 0 then continue end
		local sp, onScreen = cam:WorldToViewportPoint(head.Position)
		if not onScreen or sp.Z < 0 then continue end
		local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
		if dist < bestDist then
			bestDist = dist
			best = head
		end
	end
	return best
end

local function setAim(enabled)
	Config.AimEnabled = enabled
	ensureAimCircle()
	if AimConnection then
		pcall(function() AimConnection:Disconnect() end)
		AimConnection = nil
	end
	if AimCircleFrame then
		AimCircleFrame.Visible = enabled and Config.AimShowCircle
		AimCircleFrame.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
	end
	if not enabled then return end
	AimConnection = RunService.RenderStepped:Connect(function()
		if not ScriptAlive or not Config.AimEnabled then return end
		if AimCircleFrame then
			AimCircleFrame.Visible = Config.AimShowCircle
			AimCircleFrame.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
		end
		local target = getClosestInFOV()
		if not target then return end
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local goal = CFrame.lookAt(cam.CFrame.Position, target.Position)
		local smooth = math.clamp(Config.AimSmooth or 0.35, 0.05, 1)
		cam.CFrame = cam.CFrame:Lerp(goal, smooth)
	end)
	reg(AimConnection)
end

--------------------------------------------------
-- SHIFT LOCK
--------------------------------------------------
local ShiftLockConnection = nil
local function setShiftLock(enabled)
	Config.ShiftLock = enabled
	if ShiftLockConnection then
		pcall(function() ShiftLockConnection:Disconnect() end)
		ShiftLockConnection = nil
	end
	pcall(function()
		LocalPlayer.DevEnableMouseLock = enabled
	end)
	if not enabled then
		pcall(function()
			local char = LocalPlayer.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then hum.AutoRotate = true end
			end
		end)
		return
	end
	ShiftLockConnection = RunService.RenderStepped:Connect(function()
		if not ScriptAlive or not Config.ShiftLock then return end
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local cam = Workspace.CurrentCamera
		if not root or not hum or not cam then return end
		hum.AutoRotate = false
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.05 then
			root.CFrame = CFrame.new(root.Position, root.Position + flat.Unit)
		end
	end)
	reg(ShiftLockConnection)
end

--------------------------------------------------
-- EMOTES / DANCE  (MJ · Moonwalk · full list)
--------------------------------------------------
local EMOTE_CATALOG = {
	{ id = "dance1", name = "Dance 1", nameVi = "Nhảy 1", anim = "rbxassetid://507771019" },
	{ id = "dance2", name = "Dance 2", nameVi = "Nhảy 2", anim = "rbxassetid://507771955" },
	{ id = "dance3", name = "Dance 3", nameVi = "Nhảy 3", anim = "rbxassetid://507772268" },
	{ id = "wave", name = "Wave", nameVi = "Vẫy tay", anim = "rbxassetid://507770239" },
	{ id = "cheer", name = "Cheer", nameVi = "Cổ vũ", anim = "rbxassetid://507770677" },
	{ id = "laugh", name = "Laugh", nameVi = "Cười", anim = "rbxassetid://507770818" },
	{ id = "point", name = "Point", nameVi = "Chỉ tay", anim = "rbxassetid://507770453" },
	{ id = "sit", name = "Sit", nameVi = "Ngồi", anim = "rbxassetid://2506281703" },
	-- Custom-style movement (moonwalk / MJ vibe via animation + scripted slide)
	{ id = "moonwalk", name = "Moonwalk (MJ)", nameVi = "Đi lùi MJ", anim = "special_moonwalk" },
	{ id = "shuffle", name = "Shuffle", nameVi = "Shuffle", anim = "special_shuffle" },
	{ id = "spinmove", name = "Spin Move", nameVi = "Xoay múa", anim = "special_spin" },
	{ id = "flex", name = "Flex", nameVi = "Gồng", anim = "rbxassetid://3360689775" },
	{ id = "stage", name = "Stage Dance", nameVi = "Múa sân khấu", anim = "rbxassetid://3333499508" },
}

local CurrentEmoteTrack = nil
local EmoteSpecialConn = nil

local function stopEmote()
	if CurrentEmoteTrack then
		pcall(function() CurrentEmoteTrack:Stop(0.2) end)
		CurrentEmoteTrack = nil
	end
	if EmoteSpecialConn then
		pcall(function() EmoteSpecialConn:Disconnect() end)
		EmoteSpecialConn = nil
	end
end

local function playSpecialMove(kind)
	stopEmote()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return false, "No character" end

	if kind == "special_moonwalk" then
		-- slide backwards while facing forward (MJ moonwalk vibe)
		local t0 = os.clock()
		EmoteSpecialConn = RunService.RenderStepped:Connect(function(dt)
			if not ScriptAlive or os.clock() - t0 > 4 then
				stopEmote()
				return
			end
			local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not r then return end
			local back = -r.CFrame.LookVector
			r.CFrame = r.CFrame + back * (8 * dt)
		end)
		reg(EmoteSpecialConn)
		-- try play a walk-like anim if available
		pcall(function()
			local animator = hum:FindFirstChildOfClass("Animator") or hum
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://507777826" -- walk
			CurrentEmoteTrack = animator:LoadAnimation(anim)
			CurrentEmoteTrack.Priority = Enum.AnimationPriority.Action
			CurrentEmoteTrack:Play(0.15)
		end)
		return true, "Moonwalk"
	elseif kind == "special_shuffle" then
		local t0 = os.clock()
		local dir = 1
		EmoteSpecialConn = RunService.RenderStepped:Connect(function(dt)
			if not ScriptAlive or os.clock() - t0 > 3.5 then
				stopEmote()
				return
			end
			local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not r then return end
			if (os.clock() - t0) % 0.35 < dt then dir = -dir end
			local side = r.CFrame.RightVector * dir
			r.CFrame = r.CFrame + side * (10 * dt)
		end)
		reg(EmoteSpecialConn)
		return true, "Shuffle"
	elseif kind == "special_spin" then
		local t0 = os.clock()
		EmoteSpecialConn = RunService.RenderStepped:Connect(function(dt)
			if not ScriptAlive or os.clock() - t0 > 3 then
				stopEmote()
				return
			end
			local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not r then return end
			r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(420 * dt), 0)
		end)
		reg(EmoteSpecialConn)
		return true, "Spin Move"
	end
	return false, "Unknown"
end

local function playEmote(emoteId)
	local entry = nil
	for _, e in ipairs(EMOTE_CATALOG) do
		if e.id == emoteId then entry = e break end
	end
	if not entry then return false, "Unknown emote" end

	if type(entry.anim) == "string" and entry.anim:find("special_") then
		return playSpecialMove(entry.anim)
	end

	stopEmote()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return false, "No humanoid" end

	local ok, err = pcall(function()
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = hum
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = entry.anim
		CurrentEmoteTrack = animator:LoadAnimation(anim)
		CurrentEmoteTrack.Priority = Enum.AnimationPriority.Action
		CurrentEmoteTrack.Looped = true
		CurrentEmoteTrack:Play(0.2)
	end)
	if not ok then return false, tostring(err) end
	return true, entry.name
end

--------------------------------------------------
-- EXTRA UTILITIES  (Noclip · Fly · InfJump · ClickTP)
--------------------------------------------------
local NoclipConnection = nil
local function setNoclip(enabled)
	Config.Noclip = enabled
	if NoclipConnection then
		pcall(function() NoclipConnection:Disconnect() end)
		NoclipConnection = nil
	end
	if not enabled then
		pcall(function()
			local char = LocalPlayer.Character
			if not char then return end
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = true end
			end
		end)
		return
	end
	NoclipConnection = RunService.Stepped:Connect(function()
		if not ScriptAlive or not Config.Noclip then return end
		local char = LocalPlayer.Character
		if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
	reg(NoclipConnection)
end

local FlyBody = nil
local FlyConnection = nil
local function setFly(enabled)
	Config.Fly = enabled
	if FlyConnection then
		pcall(function() FlyConnection:Disconnect() end)
		FlyConnection = nil
	end
	if FlyBody then
		pcall(function() FlyBody:Destroy() end)
		FlyBody = nil
	end
	if not enabled then return end

	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	FlyBody = Instance.new("BodyVelocity")
	FlyBody.Name = "AetherFly"
	FlyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	FlyBody.Velocity = Vector3.zero
	FlyBody.Parent = root

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not ScriptAlive or not Config.Fly or not FlyBody then return end
		local cam = Workspace.CurrentCamera
		local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not cam or not r then return end
		if FlyBody.Parent ~= r then FlyBody.Parent = r end
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
		if dir.Magnitude > 0 then
			FlyBody.Velocity = dir.Unit * (Config.FlySpeed or 50)
		else
			FlyBody.Velocity = Vector3.zero
		end
	end)
	reg(FlyConnection)
end

local InfJumpConnection = nil
local function setInfJump(enabled)
	Config.InfJump = enabled
	if InfJumpConnection then
		pcall(function() InfJumpConnection:Disconnect() end)
		InfJumpConnection = nil
	end
	if not enabled then return end
	InfJumpConnection = UserInputService.JumpRequest:Connect(function()
		if not ScriptAlive or not Config.InfJump then return end
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
	reg(InfJumpConnection)
end

local ClickTPConnection = nil
local function setClickTP(enabled)
	Config.ClickTP = enabled
	if ClickTPConnection then
		pcall(function() ClickTPConnection:Disconnect() end)
		ClickTPConnection = nil
	end
	if not enabled then return end
	local mouse = nil
	pcall(function() mouse = LocalPlayer:GetMouse() end)
	if not mouse then return end
	ClickTPConnection = mouse.Button1Down:Connect(function()
		if not ScriptAlive or not Config.ClickTP then return end
		local ctrl = false
		pcall(function()
			ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		end)
		if not ctrl then return end
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and mouse.Hit then
			pcall(function()
				root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
			end)
		end
	end)
	reg(ClickTPConnection)
end

--------------------------------------------------
-- ORBIT SWORD + AURA  (Workspace — visible)
--------------------------------------------------
local SwordFolder = Instance.new("Folder")
SwordFolder.Name = "AetherSword"
SwordFolder.Parent = Workspace

local SwordParts = {}
local SwordConnection = nil
local SwordAngle = 0

local function clearSword()
	pcall(function()
		for _, obj in ipairs(SwordParts) do
			if obj.model and obj.model.Parent then obj.model:Destroy() end
		end
	end)
	table.clear(SwordParts)
	if SwordConnection then
		pcall(function() SwordConnection:Disconnect() end)
		SwordConnection = nil
	end
	-- safety: wipe leftover children
	pcall(function()
		for _, c in ipairs(SwordFolder:GetChildren()) do c:Destroy() end
	end)
end

local function makePart(props)
	local p = Instance.new("Part")
	p.Name = props.Name or "Part"
	p.Size = props.Size or Vector3.new(1, 1, 1)
	p.Material = props.Material or Enum.Material.Neon
	p.Color = props.Color or THEME.Primary
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Transparency = props.Transparency or 0
	p.Parent = props.Parent
	return p
end

local function createSwordModel(index)
	local model = Instance.new("Model")
	model.Name = "OrbitSword_" .. index
	model.Parent = SwordFolder

	local blade = makePart({
		Name = "Blade",
		Size = Vector3.new(0.28, 3.6, 0.55),
		Material = Enum.Material.Neon,
		Color = THEME.Primary,
		Transparency = 0.05,
		Parent = model,
	})
	local tip = makePart({
		Name = "Tip",
		Size = Vector3.new(0.22, 0.85, 0.4),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(200, 255, 240),
		Transparency = 0.1,
		Parent = model,
	})
	local hilt = makePart({
		Name = "Hilt",
		Size = Vector3.new(0.4, 0.65, 0.4),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(50, 55, 70),
		Transparency = 0,
		Parent = model,
	})
	local guard = makePart({
		Name = "Guard",
		Size = Vector3.new(0.9, 0.18, 0.35),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(180, 190, 210),
		Transparency = 0,
		Parent = model,
	})

	local aura = makePart({
		Name = "Aura",
		Size = Vector3.new(1.6, 4.5, 1.6),
		Material = Enum.Material.ForceField,
		Color = THEME.Primary,
		Transparency = Config.SwordAura and 0.55 or 1,
		Parent = model,
	})

	local att0 = Instance.new("Attachment")
	att0.Position = Vector3.new(0, 2, 0)
	att0.Parent = blade
	local att1 = Instance.new("Attachment")
	att1.Position = Vector3.new(0, -1.6, 0)
	att1.Parent = blade
	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(THEME.Primary, THEME.Accent)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.28
	trail.MinLength = 0.08
	trail.FaceCamera = true
	trail.Enabled = Config.SwordAura
	trail.Parent = blade

	model.PrimaryPart = blade
	return {
		model = model,
		blade = blade,
		tip = tip,
		hilt = hilt,
		guard = guard,
		aura = aura,
		trail = trail,
		angle = (index - 1) * (math.pi * 2 / 3),
	}
end

local function setSwordOrbit(enabled, speed)
	local ok, err = pcall(function()
		Config.SwordOrbit = enabled
		Config.SwordSpeed = math.clamp(tonumber(speed) or Config.SwordSpeed or 30, 5, 120)
		clearSword()
		if not enabled then return end

		local char = LocalPlayer.Character
		if not char then
			char = LocalPlayer.CharacterAdded:Wait()
			task.wait(0.3)
		end

		-- Parent under character so parts follow player (best-effort visibility)
		if not SwordFolder or not SwordFolder.Parent then
			SwordFolder = Instance.new("Folder")
			SwordFolder.Name = "AetherSword"
		end
		SwordFolder.Parent = char

		for i = 1, 3 do
			local obj = createSwordModel(i)
			-- Try set network owner to local player for better control
			pcall(function()
				if obj.blade and obj.blade:IsA("BasePart") then
					obj.blade:SetNetworkOwner(LocalPlayer)
				end
			end)
			table.insert(SwordParts, obj)
		end

		local radius = 5
		SwordConnection = RunService.RenderStepped:Connect(function(dt)
			if not ScriptAlive or not Config.SwordOrbit then return end
			local c = LocalPlayer.Character
			if not c then return end
			local root = c:FindFirstChild("HumanoidRootPart")
			if not root then return end

			-- Keep folder under character
			if SwordFolder.Parent ~= c then
				pcall(function() SwordFolder.Parent = c end)
			end

			SwordAngle = SwordAngle + math.rad(Config.SwordSpeed * 60 * dt)
			local center = root.Position
			local t = os.clock()

			for _, obj in ipairs(SwordParts) do
				local ang = SwordAngle + obj.angle
				local pos = center + Vector3.new(math.cos(ang) * radius, 1.4 + math.sin(t * 2 + obj.angle) * 0.15, math.sin(ang) * radius)
				local look = CFrame.lookAt(pos, center + Vector3.new(0, 1.2, 0))
				local cf = look * CFrame.Angles(0, 0, math.rad(90))

				if obj.blade then obj.blade.CFrame = cf end
				if obj.tip then obj.tip.CFrame = cf * CFrame.new(0, 2.05, 0) end
				if obj.hilt then obj.hilt.CFrame = cf * CFrame.new(0, -1.85, 0) end
				if obj.guard then obj.guard.CFrame = cf * CFrame.new(0, -1.45, 0) end
				if obj.aura then
					obj.aura.CFrame = cf
					if Config.SwordAura then
						obj.aura.Transparency = 0.5 + 0.2 * math.sin(t * 5 + obj.angle)
						if obj.trail then obj.trail.Enabled = true end
					else
						obj.aura.Transparency = 1
						if obj.trail then obj.trail.Enabled = false end
					end
				end
			end
		end)
		reg(SwordConnection)
	end)
	if not ok then
		warn("[Aether] SwordOrbit error:", err)
		pcall(clearSword)
	end
end

local function setSwordAura(enabled)
	Config.SwordAura = enabled
	for _, obj in ipairs(SwordParts) do
		pcall(function()
			if obj.aura then obj.aura.Transparency = enabled and 0.55 or 1 end
			if obj.trail then obj.trail.Enabled = enabled end
		end)
	end
end

--------------------------------------------------
-- INVISIBILITY (Tàn hình)
--------------------------------------------------
local InvisConnection = nil
local InvisOriginal = {} -- [instance] = original transparency / enabled

local function setInvisibility(enabled)
	Config.Invisibility = enabled
	if InvisConnection then
		pcall(function() InvisConnection:Disconnect() end)
		InvisConnection = nil
	end

	local function applyInvis(char, on)
		if not char then return end
		for _, inst in ipairs(char:GetDescendants()) do
			pcall(function()
				if inst:IsA("BasePart") then
					if on then
						if InvisOriginal[inst] == nil then
							InvisOriginal[inst] = inst.Transparency
						end
						inst.Transparency = 1
						-- also push local modifier so local view is fully hidden
						inst.LocalTransparencyModifier = 1
					else
						local orig = InvisOriginal[inst]
						if orig ~= nil then
							inst.Transparency = orig
						else
							inst.Transparency = 0
						end
						inst.LocalTransparencyModifier = 0
						InvisOriginal[inst] = nil
					end
				elseif inst:IsA("Decal") or inst:IsA("Texture") then
					if on then
						if InvisOriginal[inst] == nil then InvisOriginal[inst] = inst.Transparency end
						inst.Transparency = 1
					else
						inst.Transparency = InvisOriginal[inst] or 0
						InvisOriginal[inst] = nil
					end
				elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
					or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
					if on then
						if InvisOriginal[inst] == nil then InvisOriginal[inst] = inst.Enabled end
						inst.Enabled = false
					else
						if InvisOriginal[inst] ~= nil then
							inst.Enabled = InvisOriginal[inst]
							InvisOriginal[inst] = nil
						else
							inst.Enabled = true
						end
					end
				elseif inst:IsA("Shirt") or inst:IsA("Pants") or inst:IsA("ShirtGraphic") then
					-- clothing: hide by moving off character temporarily not reliable; skip
				end
			end)
		end
		-- Force face / accessories
		for _, acc in ipairs(char:GetChildren()) do
			if acc:IsA("Accessory") or acc:IsA("Hat") then
				for _, p in ipairs(acc:GetDescendants()) do
					if p:IsA("BasePart") then
						pcall(function()
							if on then
								if InvisOriginal[p] == nil then InvisOriginal[p] = p.Transparency end
								p.Transparency = 1
								p.LocalTransparencyModifier = 1
							else
								p.Transparency = InvisOriginal[p] or 0
								p.LocalTransparencyModifier = 0
								InvisOriginal[p] = nil
							end
						end)
					end
				end
			end
		end
	end

	local char = LocalPlayer.Character
	if char then applyInvis(char, enabled) end

	if enabled then
		InvisConnection = RunService.Heartbeat:Connect(function()
			if not ScriptAlive or not Config.Invisibility then return end
			local c = LocalPlayer.Character
			if c then applyInvis(c, true) end
		end)
		reg(InvisConnection)
	else
		if char then applyInvis(char, false) end
		table.clear(InvisOriginal)
	end
end

-- Re-apply on respawn
reg(LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.4)
	if not ScriptAlive then return end
	if Config.SwordOrbit then setSwordOrbit(true, Config.SwordSpeed) end
	if Config.Invisibility then setInvisibility(true) end
end))

--------------------------------------------------
-- ITEM SELECTOR  (spawn tools near player)
--------------------------------------------------
local ItemFolder = Instance.new("Folder")
ItemFolder.Name = "AetherItems"
ItemFolder.Parent = Workspace

local ActiveItems = {}
local SelectedItemId = nil

local ITEM_CATALOG = {
	{
		id = "speaker",
		name = "Loa nhạc",
		nameEn = "Speaker",
		desc = "Loa phát nhạc — nhập Sound ID",
		icon = "🔊",
		color = THEME.Primary,
	},
	{
		id = "light",
		name = "Đèn neon",
		nameEn = "Neon Light",
		desc = "Đèn sáng quanh bạn",
		icon = "💡",
		color = THEME.Warning,
	},
	{
		id = "platform",
		name = "Sàn đứng",
		nameEn = "Platform",
		desc = "Sàn neon dưới chân",
		icon = "⬜",
		color = THEME.Secondary,
	},
	{
		id = "beacon",
		name = "Beacon",
		nameEn = "Beacon",
		desc = "Cột sáng đánh dấu vị trí",
		icon = "📡",
		color = THEME.Accent,
	},
	{
		id = "orb",
		name = "Quả cầu năng lượng",
		nameEn = "Energy Orb",
		desc = "Quả cầu bay quanh người",
		icon = "🔮",
		color = THEME.Accent,
	},
}

local function clearItems()
	for _, obj in pairs(ActiveItems) do
		pcall(function()
			if obj.model then obj.model:Destroy() end
			if obj.conn then obj.conn:Disconnect() end
			if obj.sound then obj.sound:Destroy() end
		end)
	end
	table.clear(ActiveItems)
	pcall(function()
		for _, c in ipairs(ItemFolder:GetChildren()) do c:Destroy() end
	end)
end

local function getSpawnCFrame()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		return root.CFrame * CFrame.new(0, 0, -4)
	end
	return CFrame.new(0, 5, 0)
end

local function spawnSpeaker()
	local model = Instance.new("Model")
	model.Name = "AetherSpeaker"
	model.Parent = ItemFolder

	local base = makePart({
		Name = "Body",
		Size = Vector3.new(1.4, 1.8, 1.0),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(30, 34, 48),
		Transparency = 0,
		Parent = model,
	})
	local cone = makePart({
		Name = "Cone",
		Size = Vector3.new(0.9, 0.9, 0.5),
		Material = Enum.Material.Neon,
		Color = THEME.Primary,
		Transparency = 0.2,
		Parent = model,
	})
	local ring = makePart({
		Name = "Ring",
		Size = Vector3.new(1.1, 0.12, 1.1),
		Material = Enum.Material.Neon,
		Color = THEME.Secondary,
		Transparency = 0.15,
		Parent = model,
	})

	local cf = getSpawnCFrame()
	base.CFrame = cf
	cone.CFrame = cf * CFrame.new(0, 0.2, -0.6)
	ring.CFrame = cf * CFrame.new(0, -0.85, 0)

	local sound = Instance.new("Sound")
	sound.Name = "SpeakerSound"
	sound.Looped = true
	sound.Volume = 0.6
	sound.RollOffMaxDistance = 80
	sound.Parent = base

	-- Billboard for ID input hint
	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(140, 36)
	bill.StudsOffset = Vector3.new(0, 1.6, 0)
	bill.AlwaysOnTop = true
	bill.Parent = base
	local bl = Instance.new("TextLabel")
	bl.Size = UDim2.fromScale(1, 1)
	bl.BackgroundTransparency = 0.3
	bl.BackgroundColor3 = THEME.BG
	bl.Text = "🔊 Speaker"
	bl.TextColor3 = THEME.Primary
	bl.Font = Enum.Font.GothamBold
	bl.TextSize = 12
	bl.Parent = bill
	corner(bl, 8)

	model.PrimaryPart = base
	ActiveItems.speaker = { model = model, sound = sound, base = base }
	return true, "Speaker spawned"
end

local function playSpeakerSound(idStr)
	local item = ActiveItems.speaker
	if not item or not item.sound then return false, "Chưa có loa — hãy lấy Loa trước" end
	local id = tostring(idStr or ""):gsub("%s+", "")
	local num = id:match("(%d+)")
	if not num then return false, "ID không hợp lệ" end
	item.sound.SoundId = "rbxassetid://" .. num
	local ok, err = pcall(function() item.sound:Play() end)
	if not ok then return false, tostring(err) end
	return true, "Playing on speaker"
end

local function spawnLight()
	local model = Instance.new("Model")
	model.Name = "AetherLight"
	model.Parent = ItemFolder
	local core = makePart({
		Name = "Core",
		Size = Vector3.new(0.8, 0.8, 0.8),
		Material = Enum.Material.Neon,
		Color = THEME.Warning,
		Transparency = 0.1,
		Parent = model,
	})
	local glow = makePart({
		Name = "Glow",
		Size = Vector3.new(1.6, 1.6, 1.6),
		Material = Enum.Material.ForceField,
		Color = THEME.Warning,
		Transparency = 0.6,
		Parent = model,
	})
	local pl = Instance.new("PointLight")
	pl.Color = THEME.Warning
	pl.Brightness = 2.5
	pl.Range = 18
	pl.Parent = core
	local cf = getSpawnCFrame() * CFrame.new(0, 2, 0)
	core.CFrame = cf
	glow.CFrame = cf
	model.PrimaryPart = core

	local conn = RunService.Heartbeat:Connect(function()
		if not ScriptAlive or not core.Parent then return end
		local t = os.clock()
		core.CFrame = cf * CFrame.new(0, math.sin(t * 2) * 0.3, 0)
		glow.CFrame = core.CFrame
		glow.Transparency = 0.5 + 0.2 * math.sin(t * 3)
	end)
	ActiveItems.light = { model = model, conn = conn }
	return true, "Neon Light spawned"
end

local function spawnPlatform()
	local model = Instance.new("Model")
	model.Name = "AetherPlatform"
	model.Parent = ItemFolder
	local plate = makePart({
		Name = "Plate",
		Size = Vector3.new(8, 0.4, 8),
		Material = Enum.Material.Neon,
		Color = THEME.Secondary,
		Transparency = 0.25,
		Parent = model,
	})
	local edge = makePart({
		Name = "Edge",
		Size = Vector3.new(8.4, 0.15, 8.4),
		Material = Enum.Material.ForceField,
		Color = THEME.Primary,
		Transparency = 0.4,
		Parent = model,
	})
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local pos = root and (root.Position - Vector3.new(0, 3.2, 0)) or Vector3.new(0, 1, 0)
	plate.CFrame = CFrame.new(pos)
	edge.CFrame = CFrame.new(pos)
	plate.Anchored = true
	edge.Anchored = true
	model.PrimaryPart = plate
	ActiveItems.platform = { model = model }
	return true, "Platform spawned"
end

local function spawnBeacon()
	local model = Instance.new("Model")
	model.Name = "AetherBeacon"
	model.Parent = ItemFolder
	local pole = makePart({
		Name = "Pole",
		Size = Vector3.new(0.35, 10, 0.35),
		Material = Enum.Material.Neon,
		Color = THEME.Accent,
		Transparency = 0.15,
		Parent = model,
	})
	local top = makePart({
		Name = "Top",
		Size = Vector3.new(1.2, 1.2, 1.2),
		Material = Enum.Material.ForceField,
		Color = THEME.Primary,
		Transparency = 0.3,
		Parent = model,
	})
	local pl = Instance.new("PointLight")
	pl.Color = THEME.Accent
	pl.Brightness = 3
	pl.Range = 30
	pl.Parent = top
	local cf = getSpawnCFrame()
	pole.CFrame = cf * CFrame.new(0, 5, 0)
	top.CFrame = cf * CFrame.new(0, 10.5, 0)
	model.PrimaryPart = pole
	local conn = RunService.Heartbeat:Connect(function()
		if not top.Parent then return end
		top.Transparency = 0.2 + 0.25 * math.sin(os.clock() * 4)
	end)
	ActiveItems.beacon = { model = model, conn = conn }
	return true, "Beacon spawned"
end

local function spawnOrb()
	local model = Instance.new("Model")
	model.Name = "AetherOrb"
	model.Parent = ItemFolder
	local orb = makePart({
		Name = "Orb",
		Size = Vector3.new(1.2, 1.2, 1.2),
		Material = Enum.Material.Neon,
		Color = THEME.Accent,
		Transparency = 0.15,
		Parent = model,
	})
	local shell = makePart({
		Name = "Shell",
		Size = Vector3.new(1.8, 1.8, 1.8),
		Material = Enum.Material.ForceField,
		Color = THEME.Primary,
		Transparency = 0.55,
		Parent = model,
	})
	model.PrimaryPart = orb
	local angle = 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		if not ScriptAlive or not orb.Parent then return end
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		angle = angle + dt * 1.8
		local pos = root.Position + Vector3.new(math.cos(angle) * 3.5, 2 + math.sin(angle * 2) * 0.5, math.sin(angle) * 3.5)
		orb.CFrame = CFrame.new(pos)
		shell.CFrame = CFrame.new(pos)
		shell.Transparency = 0.45 + 0.2 * math.sin(os.clock() * 3)
	end)
	ActiveItems.orb = { model = model, conn = conn }
	return true, "Energy Orb spawned"
end

local ITEM_SPAWNERS = {
	speaker = spawnSpeaker,
	light = spawnLight,
	platform = spawnPlatform,
	beacon = spawnBeacon,
	orb = spawnOrb,
}

local function claimItem(itemId)
	local fn = ITEM_SPAWNERS[itemId]
	if not fn then return false, "Unknown item" end
	-- remove previous of same type
	if ActiveItems[itemId] then
		pcall(function()
			if ActiveItems[itemId].model then ActiveItems[itemId].model:Destroy() end
			if ActiveItems[itemId].conn then ActiveItems[itemId].conn:Disconnect() end
			if ActiveItems[itemId].sound then ActiveItems[itemId].sound:Destroy() end
		end)
		ActiveItems[itemId] = nil
	end
	local ok, msg = pcall(fn)
	if not ok then return false, tostring(msg) end
	return true, msg or "OK"
end

--------------------------------------------------
-- MUSIC
--------------------------------------------------
local MusicSound = Instance.new("Sound")
MusicSound.Name = "AetherMusic"
MusicSound.Looped = true
MusicSound.Volume = Config.MusicVolume
MusicSound.Parent = SoundService

local function musicPlay(idStr)
	local id = tostring(idStr or Config.MusicId or ""):gsub("%s+", "")
	if id == "" then return false, "Chưa nhập Sound ID" end
	local num = id:match("(%d+)")
	if not num then return false, "ID không hợp lệ" end
	Config.MusicId = num
	MusicState.SoundId = num
	MusicState.Title = L.UnknownTrack
	MusicSound.Looped = Config.MusicLoop
	MusicSound.Volume = Config.MusicMuted and 0 or Config.MusicVolume
	MusicSound.SoundId = "rbxassetid://" .. num
	local ok, err = pcall(function() MusicSound:Play() end)
	if not ok then return false, tostring(err) end
	MusicState.Playing = true
	return true, "Playing"
end

local function musicStop()
	pcall(function() MusicSound:Stop() end)
	MusicState.Playing = false
end

local function musicSetVolume(v)
	Config.MusicVolume = math.clamp(v, 0, 1)
	MusicState.Volume = Config.MusicVolume
	if not Config.MusicMuted then MusicSound.Volume = Config.MusicVolume end
end

local function musicMute(on)
	Config.MusicMuted = on
	MusicState.Muted = on
	MusicSound.Volume = on and 0 or Config.MusicVolume
end

--------------------------------------------------
-- GUI
--------------------------------------------------
pcall(function() if BootLbl then BootLbl.Text = "Aether · building UI…" end end)
local GUI_PARENT = PlayerGui
pcall(function() if gethui then GUI_PARENT = gethui() end end)
pcall(function()
	for _, n in ipairs({"Aether", "DeltaX", "DeltaX_UI", "DeltaX_Engine"}) do
		local a = GUI_PARENT:FindFirstChild(n); if a then a:Destroy() end
		local b = PlayerGui:FindFirstChild(n); if b then b:Destroy() end
	end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Aether"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Enabled = true
-- Parent: gethui → CoreGui → PlayerGui (executor-friendly)
pcall(function()
	if gethui then ScreenGui.Parent = gethui() end
end)
if not ScreenGui.Parent then pcall(function() ScreenGui.Parent = CoreGui end) end
if not ScreenGui.Parent then pcall(function() ScreenGui.Parent = PlayerGui end) end
if not ScreenGui.Parent then pcall(function() ScreenGui.Parent = GUI_PARENT end) end
print("[Aether] ScreenGui parent =", ScreenGui.Parent and ScreenGui.Parent.Name)
if not ScreenGui.Parent then
	warn("[Aether] ScreenGui has no parent — UI will not show")
	pcall(function()
		if BootLbl then
			BootLbl.Text = "Aether · GUI parent FAIL"
			BootLbl.BackgroundColor3 = Color3.fromRGB(230, 70, 90)
		end
	end)
end
pcall(function() ScreenGui.Enabled = true end)

local cam = workspace.CurrentCamera
local function fitSize()
	local vs = (cam and cam.ViewportSize) or Vector2.new(390, 720)
	local w = math.clamp(math.floor(vs.X * 0.88), 300, 390)
	local h = math.clamp(math.floor(vs.Y * 0.76), 400, 640)
	if vs.Y < 620 then h = math.clamp(math.floor(vs.Y * 0.8), 380, 540) end
	return w, h
end
local mw, mh = fitSize()

--------------------------------------------------
-- LOGIN SCREEN
--------------------------------------------------
local LoginOverlay = Instance.new("Frame")
LoginOverlay.Name = "LoginOverlay"
LoginOverlay.Size = UDim2.fromScale(1, 1)
LoginOverlay.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
LoginOverlay.BackgroundTransparency = 0.35
LoginOverlay.BorderSizePixel = 0
LoginOverlay.Visible = true
LoginOverlay.Active = true
LoginOverlay.ZIndex = 190
LoginOverlay.Parent = ScreenGui

local LoginFrame = Instance.new("Frame")
LoginFrame.Name = "Login"
LoginFrame.Size = UDim2.fromOffset(math.clamp(mw, 300, 360), 340)
LoginFrame.Position = UDim2.new(0.5, -math.clamp(mw, 300, 360)/2, 0.5, -170)
LoginFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LoginFrame.BackgroundTransparency = 0
LoginFrame.BorderSizePixel = 0
LoginFrame.Visible = true
LoginFrame.Active = true
LoginFrame.ClipsDescendants = true
LoginFrame.ZIndex = 200
LoginFrame.Parent = ScreenGui
corner(LoginFrame, RADIUS.Shell)
stroke(LoginFrame, THEME.Primary, 0.25, 2)

local LoginAmbient = Instance.new("Frame")
LoginAmbient.Size = UDim2.fromScale(1, 1)
LoginAmbient.BackgroundTransparency = 0.92
LoginAmbient.BackgroundColor3 = Color3.fromRGB(200, 235, 245)
LoginAmbient.BorderSizePixel = 0
LoginAmbient.ZIndex = 200
LoginAmbient.Parent = LoginFrame
corner(LoginAmbient, RADIUS.Shell)

local LoginLogo = Instance.new("Frame")
LoginLogo.Size = UDim2.fromOffset(48, 48)
LoginLogo.Position = UDim2.new(0.5, -24, 0, 28)
LoginLogo.BackgroundColor3 = THEME.Primary
LoginLogo.BorderSizePixel = 0
LoginLogo.ZIndex = 201
LoginLogo.Parent = LoginFrame
corner(LoginLogo, 14)
local LoginLogoTx = label(LoginLogo, "Æ", 20, Color3.fromRGB(5, 16, 12), true)
LoginLogoTx.Size = UDim2.fromScale(1, 1)
LoginLogoTx.TextXAlignment = Enum.TextXAlignment.Center
LoginLogoTx.ZIndex = 202

local LoginTitle = label(LoginFrame, APP_NAME, 20, THEME.TextPrimary, true)
LoginTitle.Size = UDim2.new(1, -32, 0, 26)
LoginTitle.Position = UDim2.fromOffset(16, 88)
LoginTitle.TextXAlignment = Enum.TextXAlignment.Center
LoginTitle.ZIndex = 201

local LoginSub = label(LoginFrame, "Enter key to unlock", 12, THEME.TextMuted, false)
LoginSub.Size = UDim2.new(1, -32, 0, 18)
LoginSub.Position = UDim2.fromOffset(16, 116)
LoginSub.TextXAlignment = Enum.TextXAlignment.Center
LoginSub.ZIndex = 201

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -48, 0, 44)
KeyBox.Position = UDim2.fromOffset(24, 150)
KeyBox.BackgroundColor3 = THEME.Glass
KeyBox.BackgroundTransparency = 0.12
KeyBox.BorderSizePixel = 0
KeyBox.PlaceholderText = "License key…"
KeyBox.PlaceholderColor3 = THEME.TextMuted
KeyBox.TextColor3 = THEME.TextPrimary
KeyBox.TextSize = 14
KeyBox.Font = Enum.Font.Gotham
KeyBox.Text = Config.SavedKey or ""
KeyBox.ClearTextOnFocus = false
KeyBox.ZIndex = 201
KeyBox.Parent = LoginFrame
corner(KeyBox, RADIUS.Medium)
stroke(KeyBox, THEME.Stroke, 0.6, 1)
pad(KeyBox, 0, 0, 14, 14)

local LoginStatus = label(LoginFrame, "", 11, THEME.TextMuted, false)
LoginStatus.Size = UDim2.new(1, -48, 0, 16)
LoginStatus.Position = UDim2.fromOffset(24, 200)
LoginStatus.TextXAlignment = Enum.TextXAlignment.Center
LoginStatus.ZIndex = 201

local LoginBtn = Instance.new("TextButton")
LoginBtn.Size = UDim2.new(1, -48, 0, 44)
LoginBtn.Position = UDim2.fromOffset(24, 224)
LoginBtn.BackgroundColor3 = THEME.Primary
LoginBtn.BackgroundTransparency = 0.04
LoginBtn.Text = "Unlock"
LoginBtn.TextSize = 14
LoginBtn.Font = Enum.Font.GothamBold
LoginBtn.TextColor3 = Color3.fromRGB(6, 18, 12)
LoginBtn.AutoButtonColor = false
LoginBtn.ZIndex = 201
LoginBtn.Parent = LoginFrame
corner(LoginBtn, RADIUS.Medium)

local GetKeyHint = label(LoginFrame, "Get key: open GetKey.html  ·  test: mtdz", 10, THEME.TextMuted, false)
GetKeyHint.Size = UDim2.new(1, -32, 0, 16)
GetKeyHint.Position = UDim2.fromOffset(16, 280)
GetKeyHint.TextXAlignment = Enum.TextXAlignment.Center
GetKeyHint.ZIndex = 201

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(mw, mh)
Main.Position = UDim2.new(0.5, -mw/2, 0.5, -mh/2)
Main.BackgroundColor3 = THEME.BG
Main.BackgroundTransparency = 0.04
Main.BorderSizePixel = 0
Main.Visible = false
Main.Active = true
Main.ClipsDescendants = true
Main.ZIndex = 50
Main.Parent = ScreenGui
corner(Main, RADIUS.Shell)
stroke(Main, Color3.fromRGB(150, 190, 255), 0.55, 1.2)

local Ambient = Instance.new("Frame")
Ambient.Size = UDim2.fromScale(1, 1)
Ambient.BackgroundColor3 = Color3.fromRGB(190, 230, 245)
Ambient.BackgroundTransparency = 0.9
Ambient.BorderSizePixel = 0
Ambient.ZIndex = 50
Ambient.Parent = Main
corner(Ambient, RADIUS.Shell)
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 230, 170)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 80, 255)),
	})
	g.Rotation = 135
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.88),
		NumberSequenceKeypoint.new(0.5, 0.96),
		NumberSequenceKeypoint.new(1, 0.90),
	})
	g.Parent = Ambient
end

local MainScale = Instance.new("UIScale")
MainScale.Scale = 1
MainScale.Parent = Main

local TopLight = Instance.new("Frame")
TopLight.Size = UDim2.new(1, 0, 0, 2)
TopLight.Position = UDim2.fromOffset(0, 0)
TopLight.BackgroundColor3 = THEME.Primary
TopLight.BackgroundTransparency = 0.4
TopLight.BorderSizePixel = 0
TopLight.ZIndex = 52
TopLight.Parent = Main
do
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = TopLight
end

-- Liquid Drag
local DragHandle = Instance.new("Frame")
DragHandle.Size = UDim2.fromOffset(82, 32)
DragHandle.Position = UDim2.new(0.5, -41, 0, 12)
DragHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DragHandle.BackgroundTransparency = 0.55
DragHandle.BorderSizePixel = 0
DragHandle.ZIndex = 95
DragHandle.Active = true
DragHandle.Parent = Main
corner(DragHandle, 16)
stroke(DragHandle, Color3.fromRGB(255, 255, 255), 0.18, 1.5)

local DragGlow = Instance.new("Frame")
DragGlow.Size = UDim2.new(1, 14, 1, 14)
DragGlow.Position = UDim2.fromOffset(-7, -7)
DragGlow.BackgroundColor3 = THEME.Primary
DragGlow.BackgroundTransparency = 0.88
DragGlow.BorderSizePixel = 0
DragGlow.ZIndex = 94
DragGlow.Parent = DragHandle
corner(DragGlow, 20)

local Liquid = Instance.new("Frame")
Liquid.Size = UDim2.new(0.78, 0, 0.62, 0)
Liquid.Position = UDim2.new(0.11, 0, 0.19, 0)
Liquid.BackgroundColor3 = THEME.Primary
Liquid.BackgroundTransparency = 0.02
Liquid.BorderSizePixel = 0
Liquid.ZIndex = 96
Liquid.Parent = DragHandle
corner(Liquid, 12)

local LiquidShine = Instance.new("Frame")
LiquidShine.Size = UDim2.new(0.45, 0, 0.38, 0)
LiquidShine.Position = UDim2.fromOffset(5, 2)
LiquidShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LiquidShine.BackgroundTransparency = 0.4
LiquidShine.BorderSizePixel = 0
LiquidShine.ZIndex = 97
LiquidShine.Parent = Liquid
corner(LiquidShine, 6)

local DragHit = Instance.new("TextButton")
DragHit.Size = UDim2.new(1, 30, 1, 24)
DragHit.Position = UDim2.fromOffset(-15, -12)
DragHit.BackgroundTransparency = 1
DragHit.Text = ""
DragHit.ZIndex = 98
DragHit.Parent = DragHandle

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 52)
Header.Position = UDim2.fromOffset(0, 44)
Header.BackgroundTransparency = 1
Header.ZIndex = 60
Header.Parent = Main

local LogoRing = Instance.new("Frame")
LogoRing.Size = UDim2.fromOffset(34, 34)
LogoRing.Position = UDim2.fromOffset(14, 9)
LogoRing.BackgroundColor3 = THEME.Primary
LogoRing.BackgroundTransparency = 0.85
LogoRing.BorderSizePixel = 0
LogoRing.ZIndex = 60
LogoRing.Parent = Header
corner(LogoRing, 11)

local Logo = Instance.new("Frame")
Logo.Size = UDim2.fromOffset(28, 28)
Logo.Position = UDim2.fromOffset(3, 3)
Logo.BackgroundColor3 = THEME.Primary
Logo.BorderSizePixel = 0
Logo.ZIndex = 61
Logo.Parent = LogoRing
corner(Logo, 9)
local LogoTx = label(Logo, "Æ", 13, Color3.fromRGB(6, 18, 14), true)
LogoTx.Size = UDim2.fromScale(1, 1)
LogoTx.TextXAlignment = Enum.TextXAlignment.Center

-- Subtle logo pulse
task.spawn(function()
	local ls = Instance.new("UIScale")
	ls.Scale = 1
	ls.Parent = LogoRing
	while ScriptAlive and LogoRing.Parent do
		tween(ls, { Scale = 1.08 }, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		tween(LogoRing, { BackgroundTransparency = 0.7 }, 0.9, Enum.EasingStyle.Sine)
		task.wait(0.95)
		if not ScriptAlive then break end
		tween(ls, { Scale = 1 }, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		tween(LogoRing, { BackgroundTransparency = 0.88 }, 0.9, Enum.EasingStyle.Sine)
		task.wait(0.95)
	end
end)

local Title = label(Header, APP_NAME, 17, THEME.TextPrimary, true)
Title.Position = UDim2.fromOffset(56, 8)
Title.Size = UDim2.new(1, -130, 0, 22)

local SubTitle = label(Header, "v" .. VERSION .. "  ·  Liquid Glass", 11, THEME.TextMuted, false)
SubTitle.Position = UDim2.fromOffset(56, 30)
SubTitle.Size = UDim2.new(1, -130, 0, 16)

local function iconBtn(parent, symbol, xOff, bg, tc)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.fromOffset(42, 42)
	wrap.Position = UDim2.new(1, xOff, 0, 5)
	wrap.BackgroundTransparency = 1
	wrap.ZIndex = 62
	wrap.Parent = parent
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(32, 32)
	b.Position = UDim2.fromOffset(5, 5)
	b.BackgroundColor3 = bg or THEME.Card
	b.BackgroundTransparency = 0.12
	b.Text = symbol
	b.TextSize = 16
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = tc or THEME.TextPrimary
	b.AutoButtonColor = false
	b.ZIndex = 63
	b.Parent = wrap
	corner(b, 11)
	stroke(b, Color3.fromRGB(190, 210, 255), 0.75, 1)
	return b
end

local MinimizeBtn = iconBtn(Header, "–", -84, THEME.Card)
local CloseBtn = iconBtn(Header, "×", -42, Color3.fromRGB(48, 16, 22), THEME.Danger)

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -156)
Content.Position = UDim2.fromOffset(8, 100)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.ZIndex = 52
Content.Parent = Main

local Pages, DockButtons = {}, {}
local PageOrder = {"Home", "Boost", "Gfx", "Music", "AI", "Tools"}

local function makePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 2
	page.ScrollBarImageColor3 = THEME.Primary
	page.ScrollBarImageTransparency = 0.4
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.ZIndex = 53
	page.Parent = Content
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, SPACING.MD)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = page
	pad(page, 2, 14, 2, 4)
	Pages[name] = page
	return page
end
for _, n in ipairs(PageOrder) do makePage(n) end

local function switchPage(name)
	if not Pages[name] or name == UIState.CurrentPage then return end
	local old = Pages[UIState.CurrentPage]
	local newp = Pages[name]
	UIState.CurrentPage = name
	if old then
		tween(old, { Position = UDim2.new(-0.04, 0, 0, 0) }, ANIM.FAST, Enum.EasingStyle.Quad)
		task.delay(ANIM.FAST * 0.6, function()
			if old then old.Visible = false; old.Position = UDim2.fromScale(0, 0) end
		end)
	end
	newp.Visible = true
	newp.Position = UDim2.new(0.04, 0, 0, 0)
	newp.CanvasPosition = Vector2.new(0, 0)
	tween(newp, { Position = UDim2.fromScale(0, 0) }, ANIM.NORMAL, Enum.EasingStyle.Quint)
	for n, btn in pairs(DockButtons) do
		local on = (n == name)
		tween(btn, {
			BackgroundTransparency = on and 0.05 or 0.78,
			BackgroundColor3 = on and THEME.Primary or Color3.fromRGB(255, 255, 255),
		}, ANIM.NORMAL)
		local ic = btn:FindFirstChild("Icon")
		if ic then ic.TextColor3 = on and Color3.fromRGB(6, 20, 14) or THEME.TextPrimary end
		local ind = btn:FindFirstChild("Ind")
		if ind then tween(ind, { BackgroundTransparency = on and 0.1 or 1 }, ANIM.FAST) end
	end
end

local function glassCard(parent, height, elevated)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, height or 56)
	card.BackgroundColor3 = elevated and THEME.CardElevated or THEME.Glass
	card.BackgroundTransparency = elevated and 0.12 or 0.18
	card.BorderSizePixel = 0
	card.ZIndex = 55
	card.Parent = parent
	corner(card, RADIUS.Large)
	stroke(card, Color3.fromRGB(140, 180, 255), elevated and 0.48 or 0.65, 1)
	return card
end

local function sectionTitle(parent, text, order)
	local t = label(parent, text, 11, THEME.TextMuted, true)
	t.Size = UDim2.new(1, -4, 0, 15)
	t.LayoutOrder = order or 0
	return t
end

local function makeToggle(parent, title, initial, callback, order)
	local card = glassCard(parent, 48)
	card.LayoutOrder = order or 1
	local t = label(card, title, 13, THEME.TextPrimary, false)
	t.Position = UDim2.fromOffset(SPACING.LG, 0)
	t.Size = UDim2.new(1, -70, 1, 0)
	local track = Instance.new("Frame")
	track.Size = UDim2.fromOffset(44, 24)
	track.Position = UDim2.new(1, -56, 0.5, -12)
	track.BackgroundColor3 = initial and THEME.On or THEME.Off
	track.BorderSizePixel = 0
	track.ZIndex = 56
	track.Parent = card
	corner(track, 12)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(20, 20)
	knob.Position = UDim2.fromOffset(initial and 22 or 2, 2)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 57
	knob.Parent = track
	corner(knob, 10)
	local state = initial
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 58
	hit.Parent = card
	hit.MouseButton1Click:Connect(function()
		state = not state
		tween(track, { BackgroundColor3 = state and THEME.On or THEME.Off }, ANIM.FAST)
		spring(knob, { Position = UDim2.fromOffset(state and 22 or 2, 2) }, 0.28)
		if callback then callback(state) end
	end)
	return { set = function(v)
		state = v
		track.BackgroundColor3 = state and THEME.On or THEME.Off
		knob.Position = UDim2.fromOffset(state and 22 or 2, 2)
	end }
end

local function makeButton(parent, text, order, bg, callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 44)
	b.BackgroundColor3 = bg or THEME.Primary
	b.BackgroundTransparency = 0.04
	b.Text = text
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.fromRGB(6, 18, 12)
	b.AutoButtonColor = false
	b.LayoutOrder = order or 1
	b.ZIndex = 55
	b.Parent = parent
	corner(b, RADIUS.Medium)
	stroke(b, Color3.fromRGB(255, 255, 255), 0.65, 1)
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = b
	b.MouseButton1Down:Connect(function()
		tween(scale, { Scale = 0.96 }, ANIM.FAST, Enum.EasingStyle.Quad)
		tween(b, { BackgroundTransparency = 0.16 }, ANIM.FAST)
	end)
	b.MouseButton1Up:Connect(function()
		spring(scale, { Scale = 1 }, 0.26)
		tween(b, { BackgroundTransparency = 0.04 }, ANIM.FAST)
	end)
	b.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	return b
end

--------------------------------------------------
-- NOTIFY
--------------------------------------------------
local activeNotify = nil
local function notify(emoji, title, msg, dur)
	task.spawn(function()
		if activeNotify and activeNotify.Parent then pcall(function() activeNotify:Destroy() end) end
		local n = Instance.new("Frame")
		n.Size = UDim2.fromOffset(280, 60)
		n.Position = UDim2.new(0.5, -140, 0, -80)
		n.BackgroundColor3 = THEME.BG
		n.BackgroundTransparency = 0.04
		n.BorderSizePixel = 0
		n.ZIndex = 300
		n.Parent = ScreenGui
		corner(n, 18)
		stroke(n, THEME.Primary, 0.45, 1.2)
		activeNotify = n
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 3, 0.55, 0)
		bar.Position = UDim2.new(0, 10, 0.225, 0)
		bar.BackgroundColor3 = THEME.Primary
		bar.BorderSizePixel = 0
		bar.ZIndex = 301
		bar.Parent = n
		corner(bar, 2)
		local em = label(n, emoji or "✦", 15, THEME.TextPrimary, true)
		em.Position = UDim2.fromOffset(20, 0)
		em.Size = UDim2.fromOffset(28, 60)
		em.TextXAlignment = Enum.TextXAlignment.Center
		em.ZIndex = 301
		local tt = label(n, title or "", 13, THEME.TextPrimary, true)
		tt.Position = UDim2.fromOffset(50, 11)
		tt.Size = UDim2.new(1, -62, 0, 18)
		tt.ZIndex = 301
		local mm = label(n, msg or "", 11, THEME.TextMuted, false)
		mm.Position = UDim2.fromOffset(50, 31)
		mm.Size = UDim2.new(1, -62, 0, 16)
		mm.ZIndex = 301
		spring(n, { Position = UDim2.new(0.5, -140, 0, 14) }, 0.42)
		task.wait(dur or 2.2)
		if not ScriptAlive or not n.Parent then return end
		tween(n, { Position = UDim2.new(0.5, -140, 0, -90), BackgroundTransparency = 1 }, 0.28)
		task.wait(0.32)
		if n.Parent then n:Destroy() end
		if activeNotify == n then activeNotify = nil end
	end)
end

--------------------------------------------------
-- DYNAMIC ISLAND
--------------------------------------------------
local Island = Instance.new("Frame")
Island.Name = "Island"
Island.Size = UDim2.fromOffset(130, 34)
Island.Position = UDim2.new(0.5, -65, 0, 12)
Island.BackgroundColor3 = Color3.fromRGB(6, 9, 16)
Island.BackgroundTransparency = 0.06
Island.BorderSizePixel = 0
Island.Visible = false
Island.Active = true
Island.ZIndex = 200
Island.ClipsDescendants = true
Island.Parent = ScreenGui
corner(Island, RADIUS.Island)
local IslandStroke = stroke(Island, THEME.Primary, 0.5, 1.3)

local IslandDot = Instance.new("Frame")
IslandDot.Size = UDim2.fromOffset(7, 7)
IslandDot.Position = UDim2.fromOffset(13, 13.5)
IslandDot.BackgroundColor3 = THEME.Primary
IslandDot.BorderSizePixel = 0
IslandDot.ZIndex = 201
IslandDot.Parent = Island
corner(IslandDot, 4)

local IslandIcon = label(Island, "✦", 12, THEME.TextPrimary, true)
IslandIcon.Position = UDim2.fromOffset(26, 0)
IslandIcon.Size = UDim2.fromOffset(20, 34)
IslandIcon.TextXAlignment = Enum.TextXAlignment.Center
IslandIcon.ZIndex = 202

local IslandText = label(Island, APP_NAME, 12, THEME.TextPrimary, true)
IslandText.Position = UDim2.fromOffset(48, 0)
IslandText.Size = UDim2.new(1, -56, 1, 0)
IslandText.ZIndex = 202

local IslandSub = label(Island, "", 10, THEME.TextMuted, false)
IslandSub.Position = UDim2.fromOffset(48, 16)
IslandSub.Size = UDim2.new(1, -56, 0, 14)
IslandSub.Visible = false
IslandSub.ZIndex = 202

local function setIslandContent(mode, data)
	UIState.IslandContent = mode or "IDLE"
	data = data or {}
	if mode == "MUSIC" then
		IslandIcon.Text = "♫"
		IslandText.Text = MusicState.Title
		IslandSub.Text = MusicState.Muted and L.Muted or (MusicState.Playing and L.Playing or L.Stopped)
		IslandSub.Visible = true
		IslandDot.BackgroundColor3 = MusicState.Playing and THEME.Primary or THEME.TextMuted
	elseif mode == "BOOST" then
		IslandIcon.Text = "⚡"
		IslandText.Text = "Boost Active"
		IslandSub.Text = data.preset or BoostState.Preset
		IslandSub.Visible = true
		IslandDot.BackgroundColor3 = THEME.Primary
	elseif mode == "AI" then
		IslandIcon.Text = "✦"
		IslandText.Text = "Aether AI"
		IslandSub.Text = "Thinking…"
		IslandSub.Visible = true
		IslandDot.BackgroundColor3 = THEME.Accent
	else
		IslandIcon.Text = "✦"
		IslandText.Text = APP_NAME
		IslandSub.Visible = false
		IslandDot.BackgroundColor3 = THEME.Primary
	end
end

local function expandIsland()
	if UIState.IslandState == "EXPANDED" or UIState.IslandState == "EXPANDING" then return end
	UIState.IslandState = "EXPANDING"
	Island.Visible = true
	local targetW = 160
	local targetH = IslandSub.Visible and 48 or 34
	tween(IslandStroke, { Transparency = 0.35 }, ANIM.FAST)
	tween(Island, { Size = UDim2.fromOffset(targetW, targetH), Position = UDim2.new(0.5, -targetW/2, 0, 12) }, ANIM.MEDIUM, Enum.EasingStyle.Quart)
	task.delay(ANIM.MEDIUM, function() if ScriptAlive then UIState.IslandState = "EXPANDED" end end)
end

local function collapseIsland()
	if UIState.IslandState == "COLLAPSED" or UIState.IslandState == "COLLAPSING" then return end
	UIState.IslandState = "COLLAPSING"
	IslandSub.Visible = false
	tween(IslandStroke, { Transparency = 0.5 }, ANIM.FAST)
	tween(Island, { Size = UDim2.fromOffset(130, 34), Position = UDim2.new(0.5, -65, 0, 12) }, ANIM.MEDIUM, Enum.EasingStyle.Quart)
	task.delay(ANIM.MEDIUM, function()
		if ScriptAlive then UIState.IslandState = "COLLAPSED" setIslandContent("IDLE") end
	end)
end

local function toggleFullscreen(on)
	Config.Fullscreen = on
	if on then
		local vs = cam and cam.ViewportSize or Vector2.new(390, 720)
		tween(Main, { Size = UDim2.fromOffset(vs.X - 16, vs.Y - 24), Position = UDim2.fromOffset(8, 12) }, ANIM.MEDIUM, Enum.EasingStyle.Quint)
		notify("⛶", "Fullscreen", L.Enabled, 1.5)
	else
		local w, h = fitSize()
		tween(Main, { Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, -w/2, 0.5, -h/2) }, ANIM.MEDIUM, Enum.EasingStyle.Quint)
		notify("⛶", "Fullscreen", L.Disabled, 1.5)
	end
end

--------------------------------------------------
-- HOME
--------------------------------------------------
do
	local page = Pages.Home
	sectionTitle(page, L.Overview, 0)

	local hero = glassCard(page, 92, true)
	hero.LayoutOrder = 1
	local heroGrad = Instance.new("Frame")
	heroGrad.Size = UDim2.fromScale(1, 1)
	heroGrad.BackgroundTransparency = 0.88
	heroGrad.BackgroundColor3 = THEME.Primary
	heroGrad.BorderSizePixel = 0
	heroGrad.ZIndex = 55
	heroGrad.Parent = hero
	corner(heroGrad, RADIUS.Large)
	do
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Rotation = 90
		g.Parent = heroGrad
	end
	local hi = label(hero, L.Ready, 15, THEME.TextPrimary, true)
	hi.Position = UDim2.fromOffset(SPACING.LG, 14)
	hi.Size = UDim2.new(1, -40, 0, 20)
	hi.ZIndex = 56
	hi.TextWrapped = true
	local hs = label(hero, "Light Glass · VIP Lag · Music · AI", 11, THEME.TextMuted, false)
	hs.Position = UDim2.fromOffset(SPACING.LG, 36)
	hs.Size = UDim2.new(1, -40, 0, 16)
	hs.ZIndex = 56
	local profile = label(hero, "Key: " .. (Config.KeyType == "vip" and "VIP" or "Free"), 11, THEME.Primary, true)
	profile.Position = UDim2.fromOffset(SPACING.LG, 56)
	profile.Size = UDim2.new(1, -40, 0, 16)
	profile.ZIndex = 56
	task.spawn(function()
		while ScriptAlive and hero.Parent do
			local mins = math.floor((os.clock() - SESSION_START) / 60)
			local secs = math.floor((os.clock() - SESSION_START) % 60)
			profile.Text = string.format("%s · %02d:%02d", Config.KeyType == "vip" and "VIP" or "Free", mins, secs)
			task.wait(1)
		end
	end)

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 78)
	row.BackgroundTransparency = 1
	row.LayoutOrder = 2
	row.Parent = page

	local function mini(parent, title, value, x, accentCol)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(0.485, 0, 1, 0)
		c.Position = UDim2.fromScale(x, 0)
		c.BackgroundColor3 = THEME.Glass
		c.BackgroundTransparency = 0.2
		c.BorderSizePixel = 0
		c.ZIndex = 55
		c.Parent = parent
		corner(c, RADIUS.Medium)
		stroke(c, accentCol or THEME.Primary, 0.65, 1.1)
		label(c, title, 11, THEME.TextMuted, false).Position = UDim2.fromOffset(14, 12)
		local v = label(c, value, 22, THEME.TextPrimary, true)
		v.Position = UDim2.fromOffset(14, 36)
		v.Size = UDim2.new(1, -24, 0, 28)
		return v
	end
	local FpsVal = mini(row, "FPS", "--", 0, THEME.Primary)
	local PingVal = mini(row, "PING", "--", 0.515, THEME.Secondary)

	makeButton(page, "⚡ VIP Super Lag Fix", 3, THEME.Accent, function()
		applyVipLag(true)
		setIslandContent("BOOST", { preset = "VIP" })
		notify("👑", "VIP Lag", "Ultra performance ON", 2)
	end)
	makeButton(page, L.QuickOptimize, 4, THEME.Primary, function()
		applyPreset("Performance")
		setIslandContent("BOOST", { preset = "Performance" })
		notify("⚡", "Quick Optimize", "Performance", 2)
	end)
	makeButton(page, L.SmartCleanup, 5, THEME.Secondary, function()
		smartCleanup()
		notify("♻", "Cleanup", "Scanning…", 2)
	end)
	makeButton(page, "🛑 Panic Reset", 6, THEME.Danger, function()
		panicReset()
		notify("🛑", "Panic", "All features off", 1.8)
	end)

	local frames, lastT = 0, os.clock()
	reg(RunService.RenderStepped:Connect(function()
		if not ScriptAlive then return end
		frames += 1
		local now = os.clock()
		if now - lastT >= 0.5 then
			local fps = math.floor(frames / (now - lastT) + 0.5)
			frames, lastT = 0, now
			if FpsVal then FpsVal.Text = tostring(fps) end
			local ok, ping = pcall(function()
				return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			if ok and PingVal then PingVal.Text = tostring(ping) .. " ms" end
		end
	end))
end

--------------------------------------------------
-- BOOST
--------------------------------------------------
do
	local page = Pages.Boost
	sectionTitle(page, L.PerformanceMode, 0)
	makeButton(page, "👑 VIP Super Lag Fix", 1, THEME.Accent, function()
		applyVipLag(true)
		notify("👑", "VIP Lag", "Ultra ON · auto cleanup", 2)
	end)
	makeButton(page, L.LowDevice, 2, THEME.Warning, function()
		applyPreset("Low")
		notify("📱", "Low Device", "Applied", 1.8)
	end)
	makeButton(page, L.Performance, 3, THEME.Primary, function()
		applyPreset("Performance")
		notify("⚡", "Performance", "Applied", 1.8)
	end)
	makeButton(page, L.Balanced, 4, THEME.Secondary, function()
		applyPreset("Balanced")
		notify("⚖", "Balanced", "Applied", 1.8)
	end)
	makeButton(page, L.RestoreAll, 5, THEME.Success, function()
		applyPreset("Restore")
		notify("♻", "Restore", "Applied", 1.8)
	end)

	sectionTitle(page, L.FPSCap, 6)
	local capRow = Instance.new("Frame")
	capRow.Size = UDim2.new(1, 0, 0, 40)
	capRow.BackgroundTransparency = 1
	capRow.LayoutOrder = 7
	capRow.Parent = page
	local capLay = Instance.new("UIListLayout")
	capLay.FillDirection = Enum.FillDirection.Horizontal
	capLay.Padding = UDim.new(0, 6)
	capLay.Parent = capRow
	for _, cap in ipairs({0, 30, 60, 90, 120}) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(54, 38)
		b.BackgroundColor3 = THEME.Card
		b.BackgroundTransparency = 0.1
		b.Text = cap == 0 and "∞" or tostring(cap)
		b.TextSize = 13
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = THEME.TextPrimary
		b.AutoButtonColor = false
		b.ZIndex = 55
		b.Parent = capRow
		corner(b, RADIUS.Small)
		stroke(b, THEME.Primary, 0.8, 1)
		b.MouseButton1Click:Connect(function()
			setFPSCap(cap)
			notify("🎯", "FPS Cap", cap == 0 and "Uncapped" or (cap .. " FPS"), 1.5)
		end)
	end
	sectionTitle(page, "AUTO", 7)
	makeToggle(page, L.AutoBoost, Config.AutoBoost, function(on)
		Config.AutoBoost = on
		BoostState.AutoBoost = on
		notify("🤖", "Auto Boost", on and L.Enabled or L.Disabled, 1.4)
	end, 8)
end

--------------------------------------------------
-- GFX
--------------------------------------------------
do
	local page = Pages.Gfx
	sectionTitle(page, L.Lighting, 0)
	makeToggle(page, L.Shadows, Config.Shadows, function(on) setFeature("Shadows", on) end, 1)
	sectionTitle(page, L.World, 2)
	makeToggle(page, L.TerrainWater, Config.Terrain, function(on) setFeature("Terrain", on) end, 3)
	sectionTitle(page, L.PostProcessing, 4)
	makeToggle(page, L.PostFX, Config.PostFX, function(on) setFeature("PostFX", on) end, 5)
	sectionTitle(page, L.Effects, 6)
	makeToggle(page, L.Particles, Config.Particles, function(on) setFeature("Particles", on) end, 7)
	makeToggle(page, L.Trails, Config.Trails, function(on) setFeature("Trails", on) end, 8)
	makeToggle(page, L.Beams, Config.Beams, function(on) setFeature("Beams", on) end, 9)
	makeToggle(page, L.FireSmoke, Config.FireSmoke, function(on) setFeature("FireSmoke", on) end, 10)
	sectionTitle(page, L.Cleanup, 11)
	makeButton(page, L.SmartCleanupNow, 12, THEME.Secondary, function()
		smartCleanup()
		notify("♻", "Cleanup", "Scanning…", 2)
	end)
end

--------------------------------------------------
-- MUSIC
--------------------------------------------------
local WaveBars = {}
local statusLbl, idBox

do
	local page = Pages.Music
	sectionTitle(page, L.NowPlaying, 0)
	local nowCard = glassCard(page, 110, true)
	nowCard.LayoutOrder = 1

	local waveFrame = Instance.new("Frame")
	waveFrame.Size = UDim2.new(1, -28, 0, 28)
	waveFrame.Position = UDim2.fromOffset(14, 12)
	waveFrame.BackgroundTransparency = 1
	waveFrame.ZIndex = 56
	waveFrame.Parent = nowCard

	for i = 1, 18 do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.fromOffset(4, 6)
		bar.Position = UDim2.fromOffset((i - 1) * 7, 22)
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.BackgroundColor3 = THEME.Primary
		bar.BackgroundTransparency = 0.15
		bar.BorderSizePixel = 0
		bar.ZIndex = 57
		bar.Parent = waveFrame
		corner(bar, 2)
		WaveBars[i] = bar
	end

	local trackTitle = label(nowCard, L.UnknownTrack, 14, THEME.TextPrimary, true)
	trackTitle.Position = UDim2.fromOffset(14, 46)
	trackTitle.Size = UDim2.new(1, -28, 0, 20)
	trackTitle.ZIndex = 56

	local trackSub = label(nowCard, L.RobloxSound, 11, THEME.TextMuted, false)
	trackSub.Position = UDim2.fromOffset(14, 68)
	trackSub.Size = UDim2.new(1, -28, 0, 16)
	trackSub.ZIndex = 56

	statusLbl = label(nowCard, L.Stopped, 11, THEME.TextMuted, true)
	statusLbl.Position = UDim2.new(1, -90, 0, 68)
	statusLbl.Size = UDim2.fromOffset(76, 16)
	statusLbl.TextXAlignment = Enum.TextXAlignment.Right
	statusLbl.ZIndex = 56

	sectionTitle(page, L.SoundID, 2)
	idBox = Instance.new("TextBox")
	idBox.Size = UDim2.new(1, 0, 0, 44)
	idBox.BackgroundColor3 = THEME.Glass
	idBox.BackgroundTransparency = 0.18
	idBox.BorderSizePixel = 0
	idBox.Text = ""
	idBox.PlaceholderText = L.EnterSoundID
	idBox.PlaceholderColor3 = THEME.TextMuted
	idBox.TextColor3 = THEME.TextPrimary
	idBox.TextSize = 13
	idBox.Font = Enum.Font.Gotham
	idBox.ClearTextOnFocus = false
	idBox.LayoutOrder = 3
	idBox.ZIndex = 55
	idBox.Parent = page
	corner(idBox, RADIUS.Medium)
	stroke(idBox, THEME.Secondary, 0.65, 1)
	pad(idBox, 0, 0, 14, 14)

	local btnRow = Instance.new("Frame")
	btnRow.Size = UDim2.new(1, 0, 0, 48)
	btnRow.BackgroundTransparency = 1
	btnRow.LayoutOrder = 4
	btnRow.Parent = page

	local function mbtn(text, x, w, bg, fn)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(w, -4, 1, 0)
		b.Position = UDim2.fromScale(x, 0)
		b.BackgroundColor3 = bg
		b.BackgroundTransparency = 0.05
		b.Text = text
		b.TextSize = 13
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.fromRGB(8, 18, 14)
		b.AutoButtonColor = false
		b.ZIndex = 55
		b.Parent = btnRow
		corner(b, RADIUS.Medium)
		local sc = Instance.new("UIScale")
		sc.Scale = 1
		sc.Parent = b
		b.MouseButton1Down:Connect(function() tween(sc, { Scale = 0.97 }, ANIM.FAST, Enum.EasingStyle.Quad) end)
		b.MouseButton1Up:Connect(function() spring(sc, { Scale = 1 }, 0.28) end)
		b.MouseButton1Click:Connect(fn)
	end

	mbtn(L.Play, 0, 0.33, THEME.Primary, function()
		local ok, msg = musicPlay(idBox.Text)
		if ok then
			statusLbl.Text = L.Playing
			statusLbl.TextColor3 = THEME.Primary
			setIslandContent("MUSIC")
			notify("🎵", "Music", L.Playing, 1.5)
		else
			statusLbl.Text = "Error"
			statusLbl.TextColor3 = THEME.Danger
			notify("⚠", "Music", tostring(msg), 2)
		end
	end)
	mbtn(L.Stop, 0.33, 0.33, THEME.Secondary, function()
		musicStop()
		statusLbl.Text = L.Stopped
		statusLbl.TextColor3 = THEME.TextMuted
		setIslandContent("IDLE")
	end)
	mbtn(L.Mute, 0.66, 0.34, THEME.Accent, function()
		musicMute(not Config.MusicMuted)
		statusLbl.Text = Config.MusicMuted and L.Muted or (MusicState.Playing and L.Playing or L.Stopped)
		statusLbl.TextColor3 = Config.MusicMuted and THEME.Accent or (MusicState.Playing and THEME.Primary or THEME.TextMuted)
		setIslandContent(MusicState.Playing and "MUSIC" or "IDLE")
	end)

	sectionTitle(page, L.Volume, 5)
	local volCard = glassCard(page, 54)
	volCard.LayoutOrder = 6
	local volTrack = Instance.new("Frame")
	volTrack.Size = UDim2.new(1, -28, 0, 8)
	volTrack.Position = UDim2.new(0, 14, 0.5, -4)
	volTrack.BackgroundColor3 = THEME.Off
	volTrack.BorderSizePixel = 0
	volTrack.ZIndex = 56
	volTrack.Parent = volCard
	corner(volTrack, 4)
	local volFill = Instance.new("Frame")
	volFill.Size = UDim2.new(Config.MusicVolume, 0, 1, 0)
	volFill.BackgroundColor3 = THEME.Primary
	volFill.BorderSizePixel = 0
	volFill.ZIndex = 57
	volFill.Parent = volTrack
	corner(volFill, 4)
	local volKnob = Instance.new("Frame")
	volKnob.Size = UDim2.fromOffset(18, 18)
	volKnob.Position = UDim2.new(Config.MusicVolume, -9, 0.5, -9)
	volKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	volKnob.BorderSizePixel = 0
	volKnob.ZIndex = 58
	volKnob.Parent = volTrack
	corner(volKnob, 9)

	local volDrag = false
	local volHit = Instance.new("TextButton")
	volHit.Size = UDim2.new(1, 0, 1, 28)
	volHit.Position = UDim2.fromOffset(0, -10)
	volHit.BackgroundTransparency = 1
	volHit.Text = ""
	volHit.ZIndex = 59
	volHit.Parent = volTrack
	local function setVolFromX(x)
		local abs = volTrack.AbsoluteSize.X
		if abs <= 0 then return end
		local rel = math.clamp((x - volTrack.AbsolutePosition.X) / abs, 0, 1)
		musicSetVolume(rel)
		volFill.Size = UDim2.new(rel, 0, 1, 0)
		volKnob.Position = UDim2.new(rel, -9, 0.5, -9)
	end
	volHit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			volDrag = true; setVolFromX(input.Position.X)
		end
	end)
	reg(UserInputService.InputChanged:Connect(function(input)
		if volDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setVolFromX(input.Position.X)
		end
	end))
	reg(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			volDrag = false
		end
	end))

	makeToggle(page, L.Loop, Config.MusicLoop, function(on)
		Config.MusicLoop = on
		MusicState.Loop = on
		MusicSound.Looped = on
	end, 7)
end

task.spawn(function()
	while ScriptAlive do
		task.wait(0.08)
		if not ScriptAlive then break end
		local shouldRun = MusicState.Playing and (UIState.MainVisible or UIState.IslandContent == "MUSIC")
		if shouldRun then
			for i, bar in ipairs(WaveBars) do
				if bar and bar.Parent then
					local h = math.random(4, 24)
					if MusicState.Muted then h = math.floor(h * 0.35) end
					tween(bar, { Size = UDim2.fromOffset(4, h) }, 0.1, Enum.EasingStyle.Sine)
				end
			end
		else
			for i, bar in ipairs(WaveBars) do
				if bar and bar.Parent then
					tween(bar, { Size = UDim2.fromOffset(4, 5) }, 0.2, Enum.EasingStyle.Sine)
				end
			end
			task.wait(0.4)
		end
	end
end)

--------------------------------------------------
-- AI
--------------------------------------------------
local AI_KB = {
	{ keys = {"xin chào","hello","hi","chào"}, reply = "Xin chào! Aether AI đây ✨\nHỏi Boost, Music, Island…" },
	{ keys = {"boost","lag","fps","tối ưu"}, reply = "Tab Boost: Low / Performance / Balanced / Restore." },
	{ keys = {"music","nhạc","sound"}, reply = "Tab Music: dán Sound ID → Play." },
	{ keys = {"speed","tốc độ","chạy nhanh"}, reply = "Tab Tools → Walk Speed." },
	{ keys = {"spin","xoay"}, reply = "Tab Tools → Spin 360°." },
	{ keys = {"god","bất tử"}, reply = "Tab Tools → Godmode." },
	{ keys = {"esp"}, reply = "Tab Tools → ESP Full." },
}
local function aiReply(t)
	local lower = string.lower(t or "")
	for _, item in ipairs(AI_KB) do
		for _, k in ipairs(item.keys) do
			if string.find(lower, k, 1, true) then return item.reply end
		end
	end
	return "Thử hỏi: boost · music · speed · spin · god · esp"
end

do
	local page = Pages.AI
	local head = glassCard(page, 44, true)
	head.LayoutOrder = 1
	local headLbl = label(head, "✦  Aether AI", 13, THEME.TextPrimary, true)
	headLbl.Position = UDim2.fromOffset(14, 0)
	headLbl.Size = UDim2.new(1, -28, 1, 0)

	local chatCard = glassCard(page, 220)
	chatCard.LayoutOrder = 2
	chatCard.ClipsDescendants = true
	local ChatScroll = Instance.new("ScrollingFrame")
	ChatScroll.Size = UDim2.new(1, -12, 1, -12)
	ChatScroll.Position = UDim2.fromOffset(6, 6)
	ChatScroll.BackgroundTransparency = 1
	ChatScroll.BorderSizePixel = 0
	ChatScroll.ScrollBarThickness = 2
	ChatScroll.ScrollBarImageColor3 = THEME.Primary
	ChatScroll.ScrollBarImageTransparency = 0.4
	ChatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ChatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ChatScroll.ZIndex = 56
	ChatScroll.Parent = chatCard
	local chatLay = Instance.new("UIListLayout")
	chatLay.Padding = UDim.new(0, 8)
	chatLay.SortOrder = Enum.SortOrder.LayoutOrder
	chatLay.Parent = ChatScroll
	pad(ChatScroll, 6, 10, 6, 6)

	local function addBubble(text, isUser)
		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(1, 0, 0, 0)
		wrap.AutomaticSize = Enum.AutomaticSize.Y
		wrap.BackgroundTransparency = 1
		wrap.ZIndex = 57
		wrap.Parent = ChatScroll

		local bubble = Instance.new("Frame")
		bubble.AutomaticSize = Enum.AutomaticSize.Y
		bubble.Size = UDim2.new(0.86, 0, 0, 0)
		bubble.BackgroundColor3 = isUser and THEME.UserBubble or THEME.AIBubble
		bubble.BackgroundTransparency = 0.06
		bubble.BorderSizePixel = 0
		bubble.ZIndex = 58
		bubble.Parent = wrap
		corner(bubble, 14)
		if isUser then
			bubble.Position = UDim2.new(0.14, 0, 0, 0)
		else
			bubble.Position = UDim2.new(0, 0, 0, 0)
		end
		pad(bubble, 10, 10, 12, 12)

		local msg = Instance.new("TextLabel")
		msg.Size = UDim2.new(1, 0, 0, 0)
		msg.AutomaticSize = Enum.AutomaticSize.Y
		msg.BackgroundTransparency = 1
		msg.Text = tostring(text or "")
		msg.TextSize = 12
		msg.Font = Enum.Font.Gotham
		msg.TextColor3 = THEME.TextPrimary
		msg.TextWrapped = true
		msg.TextXAlignment = Enum.TextXAlignment.Left
		msg.TextYAlignment = Enum.TextYAlignment.Top
		msg.RichText = false
		msg.ZIndex = 59
		msg.Parent = bubble

		-- Force layout refresh so height is correct (prevents overflow)
		task.defer(function()
			if ChatScroll and ChatScroll.Parent then
				ChatScroll.CanvasPosition = Vector2.new(0, math.max(0, ChatScroll.AbsoluteCanvasSize.Y - ChatScroll.AbsoluteSize.Y))
			end
		end)
	end
	addBubble("Xin chào! Hỏi Boost, Music, Speed, Spin, God, ESP…", false)

	local inputRow = Instance.new("Frame")
	inputRow.Size = UDim2.new(1, 0, 0, 42)
	inputRow.BackgroundTransparency = 1
	inputRow.LayoutOrder = 3
	inputRow.Parent = page

	local InputBox = Instance.new("TextBox")
	InputBox.Size = UDim2.new(1, -50, 1, 0)
	InputBox.BackgroundColor3 = THEME.Glass
	InputBox.BackgroundTransparency = 0.12
	InputBox.BorderSizePixel = 0
	InputBox.PlaceholderText = L.AskAether
	InputBox.PlaceholderColor3 = THEME.TextMuted
	InputBox.TextColor3 = THEME.TextPrimary
	InputBox.TextSize = 12
	InputBox.Font = Enum.Font.Gotham
	InputBox.Text = ""
	InputBox.ClearTextOnFocus = false
	InputBox.TextWrapped = false
	InputBox.ZIndex = 56
	InputBox.Parent = inputRow
	corner(InputBox, RADIUS.Medium)
	stroke(InputBox, THEME.Stroke, 0.7, 1)
	pad(InputBox, 0, 0, 12, 12)

	local SendBtn = Instance.new("TextButton")
	SendBtn.Size = UDim2.fromOffset(42, 42)
	SendBtn.Position = UDim2.new(1, -42, 0, 0)
	SendBtn.BackgroundColor3 = THEME.Primary
	SendBtn.Text = "↑"
	SendBtn.TextSize = 16
	SendBtn.Font = Enum.Font.GothamBold
	SendBtn.TextColor3 = Color3.fromRGB(5, 18, 12)
	SendBtn.AutoButtonColor = false
	SendBtn.ZIndex = 57
	SendBtn.Parent = inputRow
	corner(SendBtn, RADIUS.Medium)

	local function sendMessage()
		if AIState.Busy then return end
		local text = (InputBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if text == "" then return end
		InputBox.Text = ""
		AIState.Busy = true
		setIslandContent("AI")
		addBubble(text, true)
		task.delay(0.26, function()
			addBubble(aiReply(text), false)
			AIState.Busy = false
			if MusicState.Playing then setIslandContent("MUSIC") else setIslandContent("IDLE") end
		end)
	end
	SendBtn.MouseButton1Click:Connect(sendMessage)
	InputBox.FocusLost:Connect(function(e) if e then sendMessage() end end)
end

--------------------------------------------------
-- TOOLS (Full)
--------------------------------------------------
do
	local page = Pages.Tools
	sectionTitle(page, L.Utilities, 0)

	makeToggle(page, L.Fullscreen, Config.Fullscreen, function(on)
		toggleFullscreen(on)
	end, 1)

	-- EXTRA UTILS
	makeToggle(page, "Noclip", Config.Noclip, function(on)
		setNoclip(on)
		notify(on and "👻" or "🚫", "Noclip", on and L.Enabled or L.Disabled, 1.2)
	end, 50)
	makeToggle(page, "Fly (WASD + Space/Ctrl)", Config.Fly, function(on)
		setFly(on)
		notify(on and "🕊" or "🚫", "Fly", on and L.Enabled or L.Disabled, 1.2)
	end, 51)
	makeToggle(page, "Infinite Jump", Config.InfJump, function(on)
		setInfJump(on)
		notify(on and "⬆" or "🚫", "Inf Jump", on and L.Enabled or L.Disabled, 1.2)
	end, 52)
	makeToggle(page, "Click TP (Ctrl + Click)", Config.ClickTP, function(on)
		setClickTP(on)
		notify(on and "🖱" or "🚫", "Click TP", on and L.Enabled or L.Disabled, 1.3)
	end, 53)

	-- EMOTES / DANCE
	sectionTitle(page, "EMOTES · MÚA", 54)
	local emoteHint = label(page, "Chọn hành động · MJ Moonwalk · Shuffle · Dance", 11, THEME.TextMuted, false)
	emoteHint.Size = UDim2.new(1, 0, 0, 16)
	emoteHint.LayoutOrder = 55

	local emoteGrid = Instance.new("Frame")
	emoteGrid.Size = UDim2.new(1, 0, 0, 0)
	emoteGrid.AutomaticSize = Enum.AutomaticSize.Y
	emoteGrid.BackgroundTransparency = 1
	emoteGrid.LayoutOrder = 56
	emoteGrid.Parent = page
	local emoteLay = Instance.new("UIListLayout")
	emoteLay.Padding = UDim.new(0, 5)
	emoteLay.SortOrder = Enum.SortOrder.LayoutOrder
	emoteLay.Parent = emoteGrid

	for i, em in ipairs(EMOTE_CATALOG) do
		local row = glassCard(emoteGrid, 40)
		row.LayoutOrder = i
		local nm = (Config.Language == "en") and em.name or em.nameVi
		local tx = label(row, nm, 12, THEME.TextPrimary, true)
		tx.Position = UDim2.fromOffset(14, 0)
		tx.Size = UDim2.new(1, -90, 1, 0)
		tx.TextXAlignment = Enum.TextXAlignment.Left
		local play = Instance.new("TextButton")
		play.Size = UDim2.fromOffset(64, 28)
		play.Position = UDim2.new(1, -74, 0.5, -14)
		play.BackgroundColor3 = THEME.Primary
		play.Text = "Play"
		play.Font = Enum.Font.GothamBold
		play.TextSize = 11
		play.TextColor3 = Color3.fromRGB(255, 255, 255)
		play.ZIndex = 58
		play.Parent = row
		corner(play, 8)
		play.MouseButton1Click:Connect(function()
			local ok, msg = playEmote(em.id)
			if ok then notify("💃", "Emote", tostring(msg), 1.4)
			else notify("⚠", "Emote", tostring(msg), 1.5) end
		end)
	end

	makeButton(page, "Stop Emote", 57, THEME.Danger, function()
		stopEmote()
		notify("⏹", "Emote", "Stopped", 1.2)
	end)

	sectionTitle(page, L.SpeedTitle, 2)
	local speedCard = glassCard(page, 90)
	speedCard.LayoutOrder = 3
	local speedLbl = label(speedCard, L.Speed .. ": " .. Config.WalkSpeed, 13, THEME.TextPrimary, true)
	speedLbl.Position = UDim2.fromOffset(16, 8)
	speedLbl.Size = UDim2.new(1, -32, 0, 20)

	local speedBox = Instance.new("TextBox")
	speedBox.Size = UDim2.new(0.45, 0, 0, 32)
	speedBox.Position = UDim2.fromOffset(16, 36)
	speedBox.BackgroundColor3 = THEME.Glass
	speedBox.BackgroundTransparency = 0.15
	speedBox.Text = tostring(Config.WalkSpeed)
	speedBox.PlaceholderText = "0 - 1000"
	speedBox.TextColor3 = THEME.TextPrimary
	speedBox.PlaceholderColor3 = THEME.TextMuted
	speedBox.Font = Enum.Font.Gotham
	speedBox.TextSize = 13
	speedBox.ZIndex = 56
	speedBox.Parent = speedCard
	corner(speedBox, 10)
	pad(speedBox, 0, 0, 8, 8)

	local applySpeed = Instance.new("TextButton")
	applySpeed.Size = UDim2.new(0.4, 0, 0, 32)
	applySpeed.Position = UDim2.new(0.55, 0, 0, 36)
	applySpeed.BackgroundColor3 = THEME.Primary
	applySpeed.Text = L.Apply
	applySpeed.Font = Enum.Font.GothamBold
	applySpeed.TextSize = 13
	applySpeed.TextColor3 = Color3.fromRGB(8, 18, 14)
	applySpeed.ZIndex = 56
	applySpeed.Parent = speedCard
	corner(applySpeed, 10)
	applySpeed.MouseButton1Click:Connect(function()
		local v = tonumber(speedBox.Text) or 16
		setWalkSpeed(v)
		speedLbl.Text = L.Speed .. ": " .. Config.WalkSpeed
		speedBox.Text = tostring(Config.WalkSpeed)
		notify("🏃", "WalkSpeed", tostring(Config.WalkSpeed), 1.4)
	end)

	makeButton(page, L.ResetSpeed, 4, THEME.Secondary, function()
		setWalkSpeed(16)
		speedLbl.Text = L.Speed .. ": 16"
		speedBox.Text = "16"
		notify("↺", "WalkSpeed", "Reset", 1.3)
	end)

	sectionTitle(page, L.SpinTitle, 5)
	makeToggle(page, L.EnableSpin, Config.SpinEnabled, function(on)
		setSpin(on, Config.SpinSpeed)
		notify("🌀", "Spin", on and L.Enabled or L.Disabled, 1.3)
	end, 6)

	local spinCard = glassCard(page, 70)
	spinCard.LayoutOrder = 7
	local spinLbl = label(spinCard, L.SpinSpeed .. ": " .. Config.SpinSpeed, 13, THEME.TextPrimary, true)
	spinLbl.Position = UDim2.fromOffset(16, 8)
	spinLbl.Size = UDim2.new(1, -32, 0, 20)

	local spinBox = Instance.new("TextBox")
	spinBox.Size = UDim2.new(0.45, 0, 0, 28)
	spinBox.Position = UDim2.fromOffset(16, 34)
	spinBox.BackgroundColor3 = THEME.Glass
	spinBox.BackgroundTransparency = 0.15
	spinBox.Text = tostring(Config.SpinSpeed)
	spinBox.PlaceholderText = "1 - 200"
	spinBox.TextColor3 = THEME.TextPrimary
	spinBox.Font = Enum.Font.Gotham
	spinBox.TextSize = 13
	spinBox.ZIndex = 56
	spinBox.Parent = spinCard
	corner(spinBox, 10)
	pad(spinBox, 0, 0, 8, 8)

	local applySpin = Instance.new("TextButton")
	applySpin.Size = UDim2.new(0.4, 0, 0, 28)
	applySpin.Position = UDim2.new(0.55, 0, 0, 34)
	applySpin.BackgroundColor3 = THEME.Accent
	applySpin.Text = L.Apply
	applySpin.Font = Enum.Font.GothamBold
	applySpin.TextSize = 13
	applySpin.TextColor3 = Color3.fromRGB(8, 18, 14)
	applySpin.ZIndex = 56
	applySpin.Parent = spinCard
	corner(applySpin, 10)
	applySpin.MouseButton1Click:Connect(function()
		local v = tonumber(spinBox.Text) or 20
		Config.SpinSpeed = math.clamp(v, 1, 200)
		spinLbl.Text = L.SpinSpeed .. ": " .. Config.SpinSpeed
		spinBox.Text = tostring(Config.SpinSpeed)
		if Config.SpinEnabled then setSpin(true, Config.SpinSpeed) end
		notify("🌀", "Spin Speed", tostring(Config.SpinSpeed), 1.3)
	end)

	sectionTitle(page, L.Godmode, 8)
	makeToggle(page, L.Godmode, Config.Godmode, function(on)
		setGodmode(on)
		notify(on and "🛡" or "💔", "Godmode", on and L.Enabled or L.Disabled, 1.4)
	end, 9)

	-- SHIFT LOCK
	sectionTitle(page, "SHIFT LOCK", 10)
	makeToggle(page, "Shift Lock", Config.ShiftLock, function(on)
		setShiftLock(on)
		notify(on and "🔒" or "🔓", "Shift Lock", on and L.Enabled or L.Disabled, 1.3)
	end, 11)

	-- AIM
	sectionTitle(page, "AIM", 12)
	makeToggle(page, "Aim Assist", Config.AimEnabled, function(on)
		setAim(on)
		notify(on and "🎯" or "🚫", "Aim", on and L.Enabled or L.Disabled, 1.3)
	end, 13)
	makeToggle(page, "Show FOV Circle", Config.AimShowCircle, function(on)
		Config.AimShowCircle = on
		if AimCircleFrame then AimCircleFrame.Visible = Config.AimEnabled and on end
	end, 14)

	local aimCard = glassCard(page, 70)
	aimCard.LayoutOrder = 15
	local aimFovLbl = label(aimCard, "FOV: " .. Config.AimFOV, 12, THEME.TextPrimary, true)
	aimFovLbl.Position = UDim2.fromOffset(14, 6)
	aimFovLbl.Size = UDim2.new(1, -28, 0, 16)
	local aimFovBox = Instance.new("TextBox")
	aimFovBox.Size = UDim2.new(0.42, 0, 0, 24)
	aimFovBox.Position = UDim2.fromOffset(14, 28)
	aimFovBox.BackgroundColor3 = THEME.Glass
	aimFovBox.BackgroundTransparency = 0.1
	aimFovBox.Text = tostring(Config.AimFOV)
	aimFovBox.PlaceholderText = "40-300"
	aimFovBox.TextColor3 = THEME.TextPrimary
	aimFovBox.Font = Enum.Font.Gotham
	aimFovBox.TextSize = 12
	aimFovBox.ZIndex = 57
	aimFovBox.Parent = aimCard
	corner(aimFovBox, 8)
	aimFovBox.FocusLost:Connect(function()
		local v = tonumber(aimFovBox.Text)
		if v then
			Config.AimFOV = math.clamp(v, 40, 300)
			aimFovLbl.Text = "FOV: " .. Config.AimFOV
			if AimCircleFrame then AimCircleFrame.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2) end
		end
		aimFovBox.Text = tostring(Config.AimFOV)
	end)
	local aimSmLbl = label(aimCard, "Smooth", 11, THEME.TextMuted, false)
	aimSmLbl.Position = UDim2.fromOffset(170, 8)
	aimSmLbl.Size = UDim2.fromOffset(80, 14)
	local aimSmBox = Instance.new("TextBox")
	aimSmBox.Size = UDim2.fromOffset(70, 24)
	aimSmBox.Position = UDim2.fromOffset(170, 28)
	aimSmBox.BackgroundColor3 = THEME.Glass
	aimSmBox.BackgroundTransparency = 0.1
	aimSmBox.Text = tostring(Config.AimSmooth)
	aimSmBox.PlaceholderText = "0.1-1"
	aimSmBox.TextColor3 = THEME.TextPrimary
	aimSmBox.Font = Enum.Font.Gotham
	aimSmBox.TextSize = 12
	aimSmBox.ZIndex = 57
	aimSmBox.Parent = aimCard
	corner(aimSmBox, 8)
	aimSmBox.FocusLost:Connect(function()
		local v = tonumber(aimSmBox.Text)
		if v then Config.AimSmooth = math.clamp(v, 0.05, 1) end
		aimSmBox.Text = tostring(Config.AimSmooth)
	end)

	-- ESP FULL
	sectionTitle(page, L.ESPTitle, 16)
	makeToggle(page, "ESP Master", Config.ESPEnabled, function(on)
		setESP(on)
		notify(on and "👁" or "🚫", "ESP", on and L.Enabled or L.Disabled, 1.4)
	end, 17)
	makeToggle(page, "ESP Box", Config.ESPBox, function(on)
		Config.ESPBox = on
	end, 18)
	makeToggle(page, "ESP Name + HP", Config.ESPName, function(on)
		Config.ESPName = on
	end, 19)
	makeToggle(page, "ESP Tracer Line", Config.ESPTracer, function(on)
		Config.ESPTracer = on
	end, 20)
	makeToggle(page, "ESP Circle", Config.ESPCircle, function(on)
		Config.ESPCircle = on
	end, 21)
	makeToggle(page, "ESP Rainbow", Config.ESPRainbow, function(on)
		Config.ESPRainbow = on
	end, 22)

	-- ORBIT SWORD
	sectionTitle(page, L.SwordTitle, 23)
	makeToggle(page, L.EnableSword, Config.SwordOrbit, function(on)
		setSwordOrbit(on, Config.SwordSpeed)
		notify(on and "⚔" or "🚫", "Orbit Sword", on and L.Enabled or L.Disabled, 1.3)
	end, 24)

	local swordCard = glassCard(page, 66)
	swordCard.LayoutOrder = 25
	local swordLbl = label(swordCard, L.SwordSpeed .. ": " .. Config.SwordSpeed, 12, THEME.TextPrimary, true)
	swordLbl.Position = UDim2.fromOffset(14, 7)
	swordLbl.Size = UDim2.new(1, -28, 0, 18)

	local swordBox = Instance.new("TextBox")
	swordBox.Size = UDim2.new(0.45, 0, 0, 26)
	swordBox.Position = UDim2.fromOffset(14, 32)
	swordBox.BackgroundColor3 = THEME.Glass
	swordBox.BackgroundTransparency = 0.12
	swordBox.Text = tostring(Config.SwordSpeed)
	swordBox.PlaceholderText = "5 - 120"
	swordBox.TextColor3 = THEME.TextPrimary
	swordBox.Font = Enum.Font.Gotham
	swordBox.TextSize = 12
	swordBox.ZIndex = 56
	swordBox.Parent = swordCard
	corner(swordBox, 9)
	pad(swordBox, 0, 0, 8, 8)

	local applySword = Instance.new("TextButton")
	applySword.Size = UDim2.new(0.4, 0, 0, 26)
	applySword.Position = UDim2.new(0.55, 0, 0, 32)
	applySword.BackgroundColor3 = THEME.Primary
	applySword.Text = L.Apply
	applySword.Font = Enum.Font.GothamBold
	applySword.TextSize = 12
	applySword.TextColor3 = Color3.fromRGB(6, 16, 12)
	applySword.ZIndex = 56
	applySword.Parent = swordCard
	corner(applySword, 9)
	applySword.MouseButton1Click:Connect(function()
		local v = tonumber(swordBox.Text) or 30
		Config.SwordSpeed = math.clamp(v, 5, 120)
		swordLbl.Text = L.SwordSpeed .. ": " .. Config.SwordSpeed
		swordBox.Text = tostring(Config.SwordSpeed)
		if Config.SwordOrbit then setSwordOrbit(true, Config.SwordSpeed) end
		notify("⚔", "Orbit Speed", tostring(Config.SwordSpeed), 1.2)
	end)

	makeToggle(page, L.SwordAura, Config.SwordAura, function(on)
		setSwordAura(on)
		notify(on and "✨" or "🚫", "Sword Aura", on and L.Enabled or L.Disabled, 1.2)
	end, 26)

	-- INVISIBILITY
	sectionTitle(page, L.InvisTitle, 27)
	makeToggle(page, L.EnableInvis, Config.Invisibility, function(on)
		setInvisibility(on)
		notify(on and "👻" or "👁", "Invisibility", on and L.Enabled or L.Disabled, 1.3)
	end, 28)

	-- ITEMS
	sectionTitle(page, L.ItemsTitle, 29)
	local itemSelectLbl = label(page, L.SelectItem, 12, THEME.TextSecondary, false)
	itemSelectLbl.Size = UDim2.new(1, 0, 0, 18)
	itemSelectLbl.LayoutOrder = 30

	local itemGrid = Instance.new("Frame")
	itemGrid.Size = UDim2.new(1, 0, 0, 0)
	itemGrid.AutomaticSize = Enum.AutomaticSize.Y
	itemGrid.BackgroundTransparency = 1
	itemGrid.LayoutOrder = 31
	itemGrid.Parent = page
	local itemLay = Instance.new("UIListLayout")
	itemLay.Padding = UDim.new(0, 6)
	itemLay.SortOrder = Enum.SortOrder.LayoutOrder
	itemLay.Parent = itemGrid

	local selectedItemBtn = nil
	local claimBtnRef = nil
	local speakerRowRef = nil

	for i, item in ipairs(ITEM_CATALOG) do
		local row = glassCard(itemGrid, 48)
		row.LayoutOrder = i
		local icon = label(row, item.icon, 16, item.color, true)
		icon.Position = UDim2.fromOffset(12, 0)
		icon.Size = UDim2.fromOffset(28, 48)
		icon.TextXAlignment = Enum.TextXAlignment.Center
		local nm = label(row, (Config.Language == "en" and item.nameEn or item.name), 12, THEME.TextPrimary, true)
		nm.Position = UDim2.fromOffset(44, 6)
		nm.Size = UDim2.new(1, -56, 0, 18)
		local ds = label(row, item.desc, 10, THEME.TextMuted, false)
		ds.Position = UDim2.fromOffset(44, 26)
		ds.Size = UDim2.new(1, -56, 0, 16)

		local hit = Instance.new("TextButton")
		hit.Size = UDim2.fromScale(1, 1)
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.ZIndex = 58
		hit.Parent = row
		hit.MouseButton1Click:Connect(function()
			SelectedItemId = item.id
			itemSelectLbl.Text = (Config.Language == "en" and item.nameEn or item.name) .. "  ·  " .. item.icon
			if selectedItemBtn then
				pcall(function()
					selectedItemBtn.BackgroundColor3 = THEME.Glass
					selectedItemBtn.BackgroundTransparency = 0.18
				end)
			end
			selectedItemBtn = row
			row.BackgroundColor3 = THEME.CardElevated
			row.BackgroundTransparency = 0.08
			if claimBtnRef then claimBtnRef.Visible = true end
			if speakerRowRef then speakerRowRef.Visible = (item.id == "speaker") end
		end)
	end

	local claimBtn = makeButton(page, L.ClaimItem, 32, THEME.Primary, function()
		if not SelectedItemId then
			notify("⚠", "Items", L.SelectItem, 1.4)
			return
		end
		local ok, msg = claimItem(SelectedItemId)
		if ok then
			notify("✅", "Items", tostring(msg), 1.5)
		else
			notify("⚠", "Items", tostring(msg), 1.8)
		end
	end)
	claimBtn.Visible = false
	claimBtnRef = claimBtn

	-- Speaker controls (shown when speaker selected)
	local speakerRow = Instance.new("Frame")
	speakerRow.Size = UDim2.new(1, 0, 0, 44)
	speakerRow.BackgroundTransparency = 1
	speakerRow.LayoutOrder = 33
	speakerRow.Visible = false
	speakerRow.Parent = page
	speakerRowRef = speakerRow

	local spkBox = Instance.new("TextBox")
	spkBox.Size = UDim2.new(0.58, 0, 1, 0)
	spkBox.BackgroundColor3 = THEME.Glass
	spkBox.BackgroundTransparency = 0.12
	spkBox.PlaceholderText = L.SpeakerIdHint
	spkBox.PlaceholderColor3 = THEME.TextMuted
	spkBox.TextColor3 = THEME.TextPrimary
	spkBox.TextSize = 12
	spkBox.Font = Enum.Font.Gotham
	spkBox.Text = ""
	spkBox.ZIndex = 56
	spkBox.Parent = speakerRow
	corner(spkBox, 10)
	pad(spkBox, 0, 0, 10, 10)

	local spkPlay = Instance.new("TextButton")
	spkPlay.Size = UDim2.new(0.38, 0, 1, 0)
	spkPlay.Position = UDim2.new(0.62, 0, 0, 0)
	spkPlay.BackgroundColor3 = THEME.Secondary
	spkPlay.Text = L.PlayOnSpeaker
	spkPlay.Font = Enum.Font.GothamBold
	spkPlay.TextSize = 11
	spkPlay.TextColor3 = Color3.fromRGB(6, 16, 12)
	spkPlay.ZIndex = 56
	spkPlay.Parent = speakerRow
	corner(spkPlay, 10)
	spkPlay.MouseButton1Click:Connect(function()
		local ok, msg = playSpeakerSound(spkBox.Text)
		if ok then notify("🔊", "Speaker", tostring(msg), 1.4)
		else notify("⚠", "Speaker", tostring(msg), 1.6) end
	end)

	makeButton(page, L.ClearItems, 34, THEME.Danger, function()
		clearItems()
		notify("🗑", "Items", "Cleared", 1.3)
	end)

	-- SAVE
	sectionTitle(page, L.SaveTitle, 40)
	makeButton(page, L.SaveConfig, 41, THEME.Success, function()
		local ok = saveConfig()
		if ok then
			notify("💾", "Save", L.SaveDone, 1.5)
		else
			notify("⚠", "Save", L.SaveFail, 1.6)
		end
	end)

	-- LANGUAGE
	sectionTitle(page, L.Language, 42)
	local langCard = glassCard(page, 66)
	langCard.LayoutOrder = 43
	local langLbl = label(langCard, Config.Language == "en" and "English" or "Tiếng Việt", 13, THEME.TextPrimary, true)
	langLbl.Position = UDim2.fromOffset(16, 10)
	langLbl.Size = UDim2.new(1, -32, 0, 20)

	local langRow = Instance.new("Frame")
	langRow.Size = UDim2.new(1, -24, 0, 32)
	langRow.Position = UDim2.fromOffset(12, 34)
	langRow.BackgroundTransparency = 1
	langRow.ZIndex = 56
	langRow.Parent = langCard

	local function makeLangBtn(text, lang, x)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.48, -4, 1, 0)
		b.Position = UDim2.fromScale(x, 0)
		b.BackgroundColor3 = Config.Language == lang and THEME.Primary or THEME.Card
		b.BackgroundTransparency = Config.Language == lang and 0.05 or 0.15
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		b.TextColor3 = Config.Language == lang and Color3.fromRGB(6, 18, 14) or THEME.TextPrimary
		b.ZIndex = 57
		b.Parent = langRow
		corner(b, 10)
		b.MouseButton1Click:Connect(function()
			setLanguage(lang)
			langLbl.Text = lang == "en" and "English" or "Tiếng Việt"
			notify("🌐", "Language", lang == "en" and "English" or "Tiếng Việt", 1.5)
			-- Note: Full UI text update requires re-executing the script for complete refresh
		end)
	end
	makeLangBtn("Tiếng Việt", "vi", 0)
	makeLangBtn("English", "en", 0.52)
end

--------------------------------------------------
-- DOCK (Liquid Glass bottom nav)
--------------------------------------------------
local Dock = Instance.new("Frame")
Dock.Size = UDim2.new(1, -18, 0, 52)
Dock.Position = UDim2.new(0, 9, 1, -62)
Dock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Dock.BackgroundTransparency = 0.90
Dock.BorderSizePixel = 0
Dock.ZIndex = 70
Dock.Parent = Main
corner(Dock, RADIUS.Dock)
stroke(Dock, Color3.fromRGB(190, 220, 255), 0.38, 1.1)

local DockLay = Instance.new("UIListLayout")
DockLay.FillDirection = Enum.FillDirection.Horizontal
DockLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
DockLay.VerticalAlignment = Enum.VerticalAlignment.Center
DockLay.Padding = UDim.new(0, 3)
DockLay.Parent = Dock

local function dockBtn(name, icon)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.fromOffset(48, 42)
	b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	b.BackgroundTransparency = 0.80
	b.Text = ""
	b.AutoButtonColor = false
	b.ZIndex = 71
	b.Parent = Dock
	corner(b, 14)

	local ic = Instance.new("TextLabel")
	ic.Name = "Icon"
	ic.Size = UDim2.fromScale(1, 1)
	ic.BackgroundTransparency = 1
	ic.Text = icon
	ic.TextSize = 16
	ic.Font = Enum.Font.GothamBold
	ic.TextColor3 = THEME.TextPrimary
	ic.TextXAlignment = Enum.TextXAlignment.Center
	ic.TextYAlignment = Enum.TextYAlignment.Center
	ic.ZIndex = 72
	ic.Parent = b

	local ind = Instance.new("Frame")
	ind.Name = "Ind"
	ind.Size = UDim2.fromOffset(3.5, 3.5)
	ind.Position = UDim2.new(0.5, -1.75, 1, -7)
	ind.BackgroundColor3 = Color3.fromRGB(5, 18, 12)
	ind.BackgroundTransparency = 1
	ind.BorderSizePixel = 0
	ind.ZIndex = 73
	ind.Parent = b
	corner(ind, 2)

	local sc = Instance.new("UIScale")
	sc.Scale = 1
	sc.Parent = b
	b.MouseButton1Down:Connect(function()
		tween(sc, { Scale = 0.92 }, ANIM.FAST)
	end)
	b.MouseButton1Up:Connect(function()
		spring(sc, { Scale = 1 }, 0.24)
	end)
	b.MouseButton1Click:Connect(function() switchPage(name) end)
	DockButtons[name] = b
end

dockBtn("Home", "⌂")
dockBtn("Boost", "⚡")
dockBtn("Gfx", "◈")
dockBtn("Music", "♫")
dockBtn("AI", "✦")
dockBtn("Tools", "⚙")
switchPage("Home")

--------------------------------------------------
-- UI STATE + DRAG + CLEANUP
--------------------------------------------------
local function setUIState(state)
	if state == "Open" then
		if not AUTHENTICATED then return end
		UIState.MainVisible = true
		Main.Visible = true
		LoginFrame.Visible = false
		Island.Visible = false
		UIState.IslandState = "COLLAPSED"
		MainScale.Scale = 0.92
		spring(MainScale, { Scale = 1 }, 0.45)
		tween(Main, { BackgroundTransparency = 0.04 }, ANIM.NORMAL)
	elseif state == "Minimized" then
		UIState.MainVisible = false
		Main.Visible = false
		Island.Visible = true
		Island.Size = UDim2.fromOffset(36, 36)
		Island.Position = UDim2.new(0.5, -18, 0, 12)
		if MusicState.Playing then setIslandContent("MUSIC") else setIslandContent("IDLE") end
		tween(Island, { Size = UDim2.fromOffset(130, 34), Position = UDim2.new(0.5, -65, 0, 12) }, 0.38, Enum.EasingStyle.Quint)
		UIState.IslandState = "COLLAPSED"
	end
end

Island.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setUIState("Open")
	end
end)
MinimizeBtn.MouseButton1Click:Connect(function() setUIState("Minimized") end)

local dragging, dragStart, startPos = false, nil, nil
local function beginDrag(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	dragging = true
	dragStart = input.Position
	startPos = Main.Position
	tween(Liquid, { Size = UDim2.new(0.9, 0, 0.78, 0), Position = UDim2.new(0.05, 0, 0.11, 0), BackgroundTransparency = 0 }, 0.18)
	tween(DragHandle, { BackgroundTransparency = 0.3, Size = UDim2.fromOffset(92, 34), Position = UDim2.new(0.5, -46, 0, 11) }, 0.18)
	tween(DragGlow, { BackgroundTransparency = 0.7 }, 0.18)
end
local function endDrag(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	if not dragging then return end
	dragging = false
	tween(Liquid, { Size = UDim2.new(0.78, 0, 0.62, 0), Position = UDim2.new(0.11, 0, 0.19, 0), BackgroundTransparency = 0.02 }, 0.26)
	tween(DragHandle, { BackgroundTransparency = 0.55, Size = UDim2.fromOffset(82, 32), Position = UDim2.new(0.5, -41, 0, 12) }, 0.26)
	tween(DragGlow, { BackgroundTransparency = 0.88 }, 0.26)
end
DragHit.InputBegan:Connect(beginDrag)
DragHandle.InputBegan:Connect(beginDrag)
Header.InputBegan:Connect(beginDrag)
reg(UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local d = input.Position - dragStart
	Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end))
reg(UserInputService.InputEnded:Connect(endDrag))

task.spawn(function()
	while ScriptAlive do
		task.wait(2.4)
		if not ScriptAlive or dragging or not UIState.MainVisible or not Liquid.Parent then continue end
		tween(Liquid, { Size = UDim2.new(0.84, 0, 0.68, 0), Position = UDim2.new(0.08, 0, 0.16, 0) }, 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		tween(TopLight, { BackgroundTransparency = 0.18 }, 1.1, Enum.EasingStyle.Sine)
		task.wait(1.15)
		if not ScriptAlive or dragging or not UIState.MainVisible then continue end
		tween(Liquid, { Size = UDim2.new(0.78, 0, 0.62, 0), Position = UDim2.new(0.11, 0, 0.19, 0) }, 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		tween(TopLight, { BackgroundTransparency = 0.4 }, 1.1, Enum.EasingStyle.Sine)
	end
end)

local function fullDestroy()
	ScriptAlive = false
	pcall(function() MusicSound:Stop() end)
	pcall(function() MusicSound:Destroy() end)
	setSpin(false)
	setGodmode(false)
	setESP(false)
	clearESP()
	setAim(false)
	setShiftLock(false)
	setNoclip(false)
	setFly(false)
	setInfJump(false)
	setClickTP(false)
	stopEmote()
	setSwordOrbit(false)
	clearSword()
	setInvisibility(false)
	clearItems()
	pcall(function() ESPFolder:Destroy() end)
	pcall(function() SwordFolder:Destroy() end)
	pcall(function() ItemFolder:Destroy() end)
	pcall(function() if AimCircleGui then AimCircleGui:Destroy() end end)
	pcall(function()
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = Original.WalkSpeed or 16 end
		end
	end)
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	table.clear(Connections)
	pcall(function() ScreenGui:Destroy() end)
	_G.Aether_Engine = nil
end

CloseBtn.MouseButton1Click:Connect(function()
	tween(MainScale, { Scale = 0.82 }, 0.2)
	tween(Main, { BackgroundTransparency = 1 }, 0.2)
	task.delay(0.22, fullDestroy)
end)

local function layoutMain()
	if not cam or Config.Fullscreen then return end
	local w, h = fitSize()
	Main.Size = UDim2.fromOffset(w, h)
	local pos, vs = Main.AbsolutePosition, cam.ViewportSize
	if pos.X < 4 or pos.Y < 4 or pos.X + w > vs.X - 4 or pos.Y + h > vs.Y - 4 then
		Main.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
	end
end
if cam then reg(cam:GetPropertyChangedSignal("ViewportSize"):Connect(layoutMain)) end

_G.Aether_Engine = {
	Version = VERSION,
	Name = APP_NAME,
	Destroy = fullDestroy,
	Notify = notify,
	SetState = setUIState,
	ApplyPreset = applyPreset,
	MusicPlay = musicPlay,
	MusicStop = musicStop,
	SetWalkSpeed = setWalkSpeed,
	ToggleFullscreen = toggleFullscreen,
	SetSpin = setSpin,
	SetGodmode = setGodmode,
	SetESP = setESP,
	SetAim = setAim,
	SetShiftLock = setShiftLock,
	SetSwordOrbit = setSwordOrbit,
	SetSwordAura = setSwordAura,
	SetInvisibility = setInvisibility,
	ClaimItem = claimItem,
	ClearItems = clearItems,
	SetLanguage = setLanguage,
	ApplyVipLag = applyVipLag,
	PanicReset = panicReset,
	PlayEmote = playEmote,
	StopEmote = stopEmote,
	SetNoclip = setNoclip,
	SetFly = setFly,
	SetInfJump = setInfJump,
	SetClickTP = setClickTP,
}

--------------------------------------------------
-- LOGIN HANDLER
--------------------------------------------------
local function unlockUI()
	AUTHENTICATED = true
	UIState.Authenticated = true
	LoginFrame.Visible = false
	if LoginOverlay then LoginOverlay.Visible = false end
	Main.Visible = true
	setUIState("Open")
	local tier = Config.KeyType == "vip" and "VIP" or "Free"
	notify("✦", APP_NAME .. " v" .. VERSION, tier .. " unlocked", 2.0)
end

local function tryLogin()
	local key = KeyBox.Text or ""
	local ok, typ, msg, exp = validateKey(key)
	if ok then
		Config.SavedKey = key:gsub("^%s+", ""):gsub("%s+$", "")
		Config.KeyType = typ or "free"
		pcall(saveConfig)
		local left = formatTimeLeft(exp)
		LoginStatus.Text = string.format("%s · %s", tostring(msg), left)
		LoginStatus.TextColor3 = THEME.Success
		task.delay(0.25, unlockUI)
	else
		LoginStatus.Text = tostring(msg or "Invalid key")
		LoginStatus.TextColor3 = THEME.Danger
		tween(LoginFrame, { Position = LoginFrame.Position + UDim2.fromOffset(6, 0) }, 0.05)
		task.delay(0.05, function()
			tween(LoginFrame, { Position = LoginFrame.Position - UDim2.fromOffset(12, 0) }, 0.05)
			task.delay(0.05, function()
				tween(LoginFrame, { Position = UDim2.new(0.5, -LoginFrame.Size.X.Offset/2, 0.5, -160) }, 0.1)
			end)
		end)
	end
end

LoginBtn.MouseButton1Click:Connect(tryLogin)
KeyBox.FocusLost:Connect(function(enter)
	if enter then tryLogin() end
end)

-- Force login UI visible (menu-not-showing fix)
pcall(function()
	if not ScreenGui.Parent then
		if gethui then ScreenGui.Parent = gethui()
		elseif CoreGui then ScreenGui.Parent = CoreGui
		elseif PlayerGui then ScreenGui.Parent = PlayerGui end
	end
	ScreenGui.Enabled = true
	ScreenGui.DisplayOrder = 999999
	Main.Visible = false
	LoginFrame.Visible = true
	LoginFrame.ZIndex = 200
	if LoginOverlay then
		LoginOverlay.Visible = true
		LoginOverlay.ZIndex = 190
	end
end)

do
	local ok, typ, msg, exp = validateKey(Config.SavedKey)
	if Config.SavedKey and Config.SavedKey ~= "" and ok then
		Config.KeyType = typ or Config.KeyType or "free"
		KeyBox.Text = Config.SavedKey
		task.defer(unlockUI)
	else
		Main.Visible = false
		LoginFrame.Visible = true
		if LoginOverlay then LoginOverlay.Visible = true end
		if msg and Config.SavedKey and Config.SavedKey ~= "" then
			pcall(function() LoginStatus.Text = tostring(msg) LoginStatus.TextColor3 = THEME.Danger end)
		end
	end
end

-- Keep boot until login is on-screen, then fade out
task.delay(1.2, function()
	pcall(function()
		if LoginFrame and LoginFrame.Visible and LoginFrame.Parent then
			if BootGui then BootGui:Destroy() end
		else
			if BootLbl then
				BootLbl.Text = "Login hidden — press F9"
				BootLbl.BackgroundColor3 = Color3.fromRGB(230, 70, 90)
			end
		end
	end)
end)

print("[Aether] v" .. VERSION .. " ready · parent=" .. tostring(ScreenGui.Parent and ScreenGui.Parent.Name))
print("[Aether] Test key: mtdz · Login Visible=" .. tostring(LoginFrame.Visible))