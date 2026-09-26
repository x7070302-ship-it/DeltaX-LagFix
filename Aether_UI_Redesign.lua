--[[
  AETHER v2.2 — Vibrancy UI (stable)
  Patterns: vibrancy glass, switch, slider, combo-button Save,
  bottom tab bar, status-dot avatar, breadcrumbs, progress loading
]]

repeat task.wait() until game:IsLoaded()

if _G.Aether_Engine and type(_G.Aether_Engine) == "table" and _G.Aether_Engine.Destroy then
	pcall(function() _G.Aether_Engine.Destroy() end)
end

local VERSION = "2.2"
local APP = "Aether"
local Alive = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

local LP = Players.LocalPlayer
while not LP do task.wait() LP = Players.LocalPlayer end
local PlayerGui = LP:WaitForChild("PlayerGui", 15)

--------------------------------------------------
-- THEME (vibrancy / light glass)
--------------------------------------------------
local T = {
	BG = Color3.fromRGB(242, 246, 252),
	Glass = Color3.fromRGB(255, 255, 255),
	GlassSoft = Color3.fromRGB(248, 251, 255),
	Primary = Color3.fromRGB(0, 180, 150),
	Secondary = Color3.fromRGB(64, 128, 255),
	Accent = Color3.fromRGB(148, 88, 255),
	Danger = Color3.fromRGB(230, 72, 90),
	Warning = Color3.fromRGB(235, 150, 40),
	Success = Color3.fromRGB(0, 170, 120),
	Text = Color3.fromRGB(22, 30, 42),
	Muted = Color3.fromRGB(118, 132, 152),
	Stroke = Color3.fromRGB(175, 198, 228),
	Track = Color3.fromRGB(220, 228, 238),
	TrackFill = Color3.fromRGB(0, 180, 150),
	Online = Color3.fromRGB(52, 199, 89),
}

local Config = {
	Key = "", KeyType = "free",
	WalkSpeed = 16, Spin = false, SpinSpeed = 20,
	Godmode = false, ESP = false, ESPBox = true, ESPName = true,
	ESPTracer = false, ESPRainbow = false, ESPCircle = false,
	Aim = false, AimFOV = 120, AimSmooth = 0.35, AimCircle = true,
	ShiftLock = false, Noclip = false, Fly = false, FlySpeed = 50,
	InfJump = false, Sword = false, SwordSpeed = 30,
	VipLag = false, Volume = 0.5, MusicId = "",
}

--------------------------------------------------
-- KEYS
--------------------------------------------------
local function parseExp(s)
	local y, m, d, H, M, S = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)%s+(%d%d):(%d%d):(%d%d)$")
	if not y then
		y, m, d = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
		H, M, S = 23, 59, 59
	end
	if not y then return nil end
	return os.time({
		year = tonumber(y), month = tonumber(m), day = tonumber(d),
		hour = tonumber(H), min = tonumber(M), sec = tonumber(S),
	})
end

local KEYS = {
	mtdz    = { typ = "vip",   exp = parseExp("2099-12-31 23:59:59"), label = "VIP Lifetime" },
	aether  = { typ = "vip",   exp = parseExp("2099-12-31 23:59:59"), label = "VIP Lifetime" },
	pro2026 = { typ = "pro",   exp = parseExp("2027-01-01 00:00:00"), label = "PRO 2026" },
	demo    = { typ = "free",  exp = parseExp("2026-12-31 23:59:59"), label = "Free Demo" },
	free    = { typ = "free",  exp = parseExp("2026-12-31 23:59:59"), label = "Free" },
	trial   = { typ = "trial", exp = parseExp("2026-10-31 23:59:59"), label = "Trial" },
	daykey  = { typ = "free",  exp = parseExp("2026-09-27 23:59:59"), label = "1-Day" },
}

local function timeLeft(exp)
	if not exp then return "No expiry" end
	local left = exp - os.time()
	if left <= 0 then return "Expired" end
	local d = math.floor(left / 86400)
	local h = math.floor((left % 86400) / 3600)
	local m = math.floor((left % 3600) / 60)
	if d > 0 then return string.format("%dd %dh", d, h) end
	if h > 0 then return string.format("%dh %dm", h, m) end
	return m .. "m"
end

local function validateKey(key)
	key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if key == "" then return false, nil, "Empty key" end
	local e = KEYS[key] or KEYS[string.lower(key)]
	if not e then
		for k, v in pairs(KEYS) do
			if string.lower(k) == string.lower(key) then e = v break end
		end
	end
	if not e then return false, nil, "Invalid key" end
	if e.exp and os.time() > e.exp then return false, e.typ, "Expired: " .. e.label end
	return true, e.typ, e.label, e.exp
end

--------------------------------------------------
-- HELPERS
--------------------------------------------------
local Conns = {}
local function reg(c)
	table.insert(Conns, c)
	return c
end

local function tween(obj, props, dur)
	if not obj then return end
	local tw = TweenService:Create(obj, TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = p
	return c
end

local function stroke(p, col, tr, th)
	local s = Instance.new("UIStroke")
	s.Color = col or T.Stroke
	s.Transparency = tr or 0.45
	s.Thickness = th or 1
	s.Parent = p
	return s
end

local function parentGui(gui)
	local ok = pcall(function()
		if gethui then gui.Parent = gethui() end
	end)
	if ok and gui.Parent then return end
	ok = pcall(function() gui.Parent = CoreGui end)
	if ok and gui.Parent then return end
	pcall(function()
		if PlayerGui then gui.Parent = PlayerGui end
	end)
end

--------------------------------------------------
-- LOADING (progress + spinner)
--------------------------------------------------
local Boot = Instance.new("ScreenGui")
Boot.Name = "AetherBoot"
Boot.ResetOnSpawn = false
Boot.IgnoreGuiInset = true
Boot.DisplayOrder = 1000000
Boot.Enabled = true
parentGui(Boot)

local BootCard = Instance.new("Frame")
BootCard.Size = UDim2.fromOffset(260, 88)
BootCard.Position = UDim2.new(0.5, -130, 0.08, 0)
BootCard.BackgroundColor3 = T.Glass
BootCard.BackgroundTransparency = 0.08
BootCard.BorderSizePixel = 0
BootCard.Parent = Boot
corner(BootCard, 16)
stroke(BootCard, T.Stroke, 0.35)

local BootTitle = Instance.new("TextLabel")
BootTitle.Size = UDim2.new(1, -20, 0, 22)
BootTitle.Position = UDim2.fromOffset(14, 12)
BootTitle.BackgroundTransparency = 1
BootTitle.Text = "Aether · loading"
BootTitle.TextColor3 = T.Text
BootTitle.Font = Enum.Font.GothamBold
BootTitle.TextSize = 13
BootTitle.TextXAlignment = Enum.TextXAlignment.Left
BootTitle.Parent = BootCard

local BootBarBG = Instance.new("Frame")
BootBarBG.Size = UDim2.new(1, -28, 0, 8)
BootBarBG.Position = UDim2.fromOffset(14, 44)
BootBarBG.BackgroundColor3 = T.Track
BootBarBG.BorderSizePixel = 0
BootBarBG.Parent = BootCard
corner(BootBarBG, 4)

local BootBar = Instance.new("Frame")
BootBar.Size = UDim2.new(0.08, 0, 1, 0)
BootBar.BackgroundColor3 = T.Primary
BootBar.BorderSizePixel = 0
BootBar.Parent = BootBarBG
corner(BootBar, 4)

local BootSub = Instance.new("TextLabel")
BootSub.Size = UDim2.new(1, -20, 0, 16)
BootSub.Position = UDim2.fromOffset(14, 60)
BootSub.BackgroundTransparency = 1
BootSub.Text = "Starting…"
BootSub.TextColor3 = T.Muted
BootSub.Font = Enum.Font.Gotham
BootSub.TextSize = 11
BootSub.TextXAlignment = Enum.TextXAlignment.Left
BootSub.Parent = BootCard

local function boot(msg, pct, isErr)
	pcall(function()
		BootSub.Text = msg or BootSub.Text
		if typeof(pct) == "number" then
			tween(BootBar, { Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0) }, 0.25)
		end
		if isErr then
			BootBar.BackgroundColor3 = T.Danger
			BootTitle.Text = "Aether · error"
		end
	end)
end

task.delay(10, function()
	if Boot and Boot.Parent then
		boot("Still loading — open F9 for errors", 1, true)
	end
end)

boot("Services OK", 0.15)

--------------------------------------------------
-- FEATURES
--------------------------------------------------
local Original = { shadows = true, fog = 1000, bright = 1 }
pcall(function()
	Original.shadows = Lighting.GlobalShadows
	Original.fog = Lighting.FogEnd
	Original.bright = Lighting.Brightness
end)

local function setVipLag(on)
	Config.VipLag = on
	pcall(function()
		if on then
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			if setfpscap then setfpscap(60) end
		else
			Lighting.GlobalShadows = Original.shadows
			Lighting.FogEnd = Original.fog
			Lighting.Brightness = Original.bright
			if setfpscap then setfpscap(999) end
		end
	end)
end

local function setSpeed(v)
	Config.WalkSpeed = math.clamp(tonumber(v) or 16, 0, 500)
	pcall(function()
		local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if h then h.WalkSpeed = Config.WalkSpeed end
	end)
end

local SpinConn
local function setSpin(on, spd)
	Config.Spin = on
	Config.SpinSpeed = tonumber(spd) or Config.SpinSpeed
	if SpinConn then SpinConn:Disconnect() SpinConn = nil end
	if not on then return end
	SpinConn = RunService.Heartbeat:Connect(function(dt)
		if not Alive or not Config.Spin then return end
		local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed * 60 * dt), 0) end
	end)
	reg(SpinConn)
end

local GodConn
local function setGod(on)
	Config.Godmode = on
	if GodConn then GodConn:Disconnect() GodConn = nil end
	if not on then return end
	GodConn = RunService.Heartbeat:Connect(function()
		if not Alive or not Config.Godmode then return end
		local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if h then h.Health = h.MaxHealth end
	end)
	reg(GodConn)
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "AetherESP"
pcall(function() ESPFolder.Parent = CoreGui end)
local ESPObjs = {}

local function clearESP()
	for _, o in pairs(ESPObjs) do
		pcall(function()
			if o.box then o.box:Destroy() end
			if o.bill then o.bill:Destroy() end
			if o.beam then o.beam:Destroy() end
			if o.circle then o.circle:Destroy() end
		end)
	end
	table.clear(ESPObjs)
end

local function rainbow(t)
	return Color3.fromHSV((t * 0.15) % 1, 0.9, 1)
end

local ESPConn
local function setESP(on)
	Config.ESP = on
	if ESPConn then ESPConn:Disconnect() ESPConn = nil end
	if not on then clearESP() return end
	ESPConn = RunService.RenderStepped:Connect(function()
		if not Alive or not Config.ESP then return end
		local col = Config.ESPRainbow and rainbow(os.clock()) or T.Primary
		local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP then
				local char = plr.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local head = char and char:FindFirstChild("Head")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if root then
					if not ESPObjs[plr] then
						local box = Instance.new("BoxHandleAdornment")
						box.AlwaysOnTop = true
						box.Size = Vector3.new(3.5, 6, 2)
						box.Transparency = 0.5
						box.Parent = ESPFolder
						local bill = Instance.new("BillboardGui")
						bill.Size = UDim2.fromOffset(110, 32)
						bill.StudsOffset = Vector3.new(0, 3, 0)
						bill.AlwaysOnTop = true
						bill.Parent = ESPFolder
						local nl = Instance.new("TextLabel")
						nl.Size = UDim2.fromScale(1, 1)
						nl.BackgroundTransparency = 1
						nl.Text = plr.Name
						nl.TextColor3 = T.Primary
						nl.TextStrokeTransparency = 0.4
						nl.Font = Enum.Font.GothamBold
						nl.TextSize = 12
						nl.Parent = bill
						local beam = Instance.new("Beam")
						beam.Width0 = 0.1
						beam.Width1 = 0.03
						beam.FaceCamera = true
						beam.Parent = ESPFolder
						local a0 = Instance.new("Attachment")
						local a1 = Instance.new("Attachment")
						a0.Parent = ESPFolder
						a1.Parent = ESPFolder
						beam.Attachment0 = a0
						beam.Attachment1 = a1
						local circle = Instance.new("CylinderHandleAdornment")
						circle.AlwaysOnTop = true
						circle.Height = 0.1
						circle.Radius = 2.2
						circle.Transparency = 0.4
						circle.Parent = ESPFolder
						ESPObjs[plr] = { box = box, bill = bill, nl = nl, beam = beam, a0 = a0, a1 = a1, circle = circle }
					end
					local o = ESPObjs[plr]
					o.box.Adornee = root
					o.box.Visible = Config.ESPBox
					o.box.Color3 = col
					if head then o.bill.Adornee = head end
					o.bill.Enabled = Config.ESPName
					if o.nl then
						o.nl.TextColor3 = col
						o.nl.Text = plr.Name .. (hum and ("  " .. math.floor(hum.Health)) or "")
					end
					if Config.ESPTracer and my then
						o.a0.Parent = my
						o.a0.Position = Vector3.zero
						o.a1.Parent = root
						o.a1.Position = Vector3.zero
						o.beam.Enabled = true
						o.beam.Color = ColorSequence.new(col)
					else
						o.beam.Enabled = false
					end
					o.circle.Adornee = root
					o.circle.Visible = Config.ESPCircle
					o.circle.Color3 = col
					o.circle.CFrame = CFrame.new(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90))
				end
			end
		end
	end)
	reg(ESPConn)
end

local AimGui, AimRing, AimConn
local function setAim(on)
	Config.Aim = on
	if not AimGui then
		AimGui = Instance.new("ScreenGui")
		AimGui.Name = "AetherAim"
		AimGui.IgnoreGuiInset = true
		AimGui.DisplayOrder = 999998
		AimGui.ResetOnSpawn = false
		parentGui(AimGui)
		AimRing = Instance.new("Frame")
		AimRing.AnchorPoint = Vector2.new(0.5, 0.5)
		AimRing.Position = UDim2.fromScale(0.5, 0.5)
		AimRing.BackgroundTransparency = 1
		AimRing.Parent = AimGui
		local st = Instance.new("UIStroke")
		st.Color = T.Primary
		st.Thickness = 1.5
		st.Transparency = 0.35
		st.Parent = AimRing
		Instance.new("UICorner", AimRing).CornerRadius = UDim.new(1, 0)
		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(4, 4)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.BackgroundColor3 = T.Primary
		dot.BorderSizePixel = 0
		dot.Parent = AimRing
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	end
	if AimConn then AimConn:Disconnect() AimConn = nil end
	AimRing.Visible = on and Config.AimCircle
	AimRing.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
	if not on then return end
	AimConn = RunService.RenderStepped:Connect(function()
		if not Alive or not Config.Aim then return end
		AimRing.Visible = Config.AimCircle
		AimRing.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local center = cam.ViewportSize / 2
		local best, bestD = nil, Config.AimFOV
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP then
				local head = plr.Character and plr.Character:FindFirstChild("Head")
				local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
				if head and hum and hum.Health > 0 then
					local sp, onScreen = cam:WorldToViewportPoint(head.Position)
					if onScreen and sp.Z > 0 then
						local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
						if d < bestD then
							bestD = d
							best = head
						end
					end
				end
			end
		end
		if best then
			local goal = CFrame.lookAt(cam.CFrame.Position, best.Position)
			cam.CFrame = cam.CFrame:Lerp(goal, math.clamp(Config.AimSmooth, 0.05, 1))
		end
	end)
	reg(AimConn)
end

local SLConn
local function setShiftLock(on)
	Config.ShiftLock = on
	if SLConn then SLConn:Disconnect() SLConn = nil end
	pcall(function() LP.DevEnableMouseLock = on end)
	if not on then
		pcall(function()
			local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if h then h.AutoRotate = true end
		end)
		return
	end
	SLConn = RunService.RenderStepped:Connect(function()
		if not Alive or not Config.ShiftLock then return end
		local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		local cam = Workspace.CurrentCamera
		if not root or not hum or not cam then return end
		hum.AutoRotate = false
		local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		if look.Magnitude > 0.05 then
			root.CFrame = CFrame.new(root.Position, root.Position + look.Unit)
		end
	end)
	reg(SLConn)
end

local NoclipConn
local function setNoclip(on)
	Config.Noclip = on
	if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
	if not on then
		pcall(function()
			local c = LP.Character
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = true end
				end
			end
		end)
		return
	end
	NoclipConn = RunService.Stepped:Connect(function()
		if not Alive or not Config.Noclip then return end
		local c = LP.Character
		if c then
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end
	end)
	reg(NoclipConn)
end

local FlyBV, FlyConn
local function setFly(on)
	Config.Fly = on
	if FlyConn then FlyConn:Disconnect() FlyConn = nil end
	if FlyBV then pcall(function() FlyBV:Destroy() end) FlyBV = nil end
	if not on then return end
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	FlyBV = Instance.new("BodyVelocity")
	FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	FlyBV.Velocity = Vector3.zero
	FlyBV.Parent = root
	FlyConn = RunService.RenderStepped:Connect(function()
		if not Alive or not Config.Fly or not FlyBV then return end
		local cam = Workspace.CurrentCamera
		local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not cam or not r then return end
		if FlyBV.Parent ~= r then FlyBV.Parent = r end
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
		if dir.Magnitude > 0 then
			FlyBV.Velocity = dir.Unit * Config.FlySpeed
		else
			FlyBV.Velocity = Vector3.zero
		end
	end)
	reg(FlyConn)
end

local JumpConn
local function setInfJump(on)
	Config.InfJump = on
	if JumpConn then JumpConn:Disconnect() JumpConn = nil end
	if not on then return end
	JumpConn = UserInputService.JumpRequest:Connect(function()
		if not Alive or not Config.InfJump then return end
		local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
	reg(JumpConn)
end

local EmoteTrack, EmoteConn
local function stopEmote()
	if EmoteTrack then pcall(function() EmoteTrack:Stop(0.15) end) EmoteTrack = nil end
	if EmoteConn then EmoteConn:Disconnect() EmoteConn = nil end
end

local function playEmote(id)
	if id == "moonwalk" then
		stopEmote()
		local t0 = os.clock()
		EmoteConn = RunService.RenderStepped:Connect(function(dt)
			if not Alive or os.clock() - t0 > 4 then stopEmote() return end
			local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if r then r.CFrame = r.CFrame + (-r.CFrame.LookVector) * (8 * dt) end
		end)
		reg(EmoteConn)
		return true, "Moonwalk"
	end
	if id == "spin" then
		stopEmote()
		local t0 = os.clock()
		EmoteConn = RunService.RenderStepped:Connect(function(dt)
			if not Alive or os.clock() - t0 > 3 then stopEmote() return end
			local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(400 * dt), 0) end
		end)
		reg(EmoteConn)
		return true, "Spin"
	end
	stopEmote()
	local ids = {
		dance = "rbxassetid://507771019",
		wave = "rbxassetid://507770239",
		cheer = "rbxassetid://507770677",
	}
	local animId = ids[id]
	if not animId then return false, "Unknown" end
	local ok, err = pcall(function()
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then error("no hum") end
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		local a = Instance.new("Animation")
		a.AnimationId = animId
		EmoteTrack = animator:LoadAnimation(a)
		EmoteTrack.Looped = true
		EmoteTrack:Play(0.2)
	end)
	return ok, ok and id or tostring(err)
end

local SwordFolder = Instance.new("Folder")
SwordFolder.Name = "AetherSword"
SwordFolder.Parent = Workspace
local Swords, SwordConn, SwordAng = {}, nil, 0

local function clearSword()
	for _, s in ipairs(Swords) do pcall(function() s:Destroy() end) end
	table.clear(Swords)
	if SwordConn then SwordConn:Disconnect() SwordConn = nil end
end

local function setSword(on)
	Config.Sword = on
	clearSword()
	if not on then return end
	for _ = 1, 3 do
		local p = Instance.new("Part")
		p.Size = Vector3.new(0.3, 3.5, 0.5)
		p.Material = Enum.Material.Neon
		p.Color = T.Primary
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = false
		p.Parent = SwordFolder
		table.insert(Swords, p)
	end
	SwordConn = RunService.RenderStepped:Connect(function(dt)
		if not Alive or not Config.Sword then return end
		local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		SwordAng = SwordAng + math.rad(Config.SwordSpeed * 60 * dt)
		for i, p in ipairs(Swords) do
			local a = SwordAng + (i - 1) * (math.pi * 2 / 3)
			local pos = root.Position + Vector3.new(math.cos(a) * 5, 1.3, math.sin(a) * 5)
			p.CFrame = CFrame.lookAt(pos, root.Position) * CFrame.Angles(0, 0, math.rad(90))
		end
	end)
	reg(SwordConn)
end

-- Music (simple)
local MusicSound = Instance.new("Sound")
MusicSound.Name = "AetherMusic"
MusicSound.Looped = true
MusicSound.Volume = Config.Volume
MusicSound.Parent = SoundService

local function setVolume(v)
	Config.Volume = math.clamp(tonumber(v) or 0.5, 0, 1)
	MusicSound.Volume = Config.Volume
end

local function playMusic(idStr)
	local num = tostring(idStr or ""):match("(%d+)")
	if not num then return false, "Need Sound ID" end
	MusicSound.SoundId = "rbxassetid://" .. num
	local ok, err = pcall(function() MusicSound:Play() end)
	return ok, ok and "Playing" or tostring(err)
end

local function stopMusic()
	pcall(function() MusicSound:Stop() end)
end

local function panic()
	setVipLag(false)
	setSpin(false)
	setGod(false)
	setESP(false)
	setAim(false)
	setShiftLock(false)
	setNoclip(false)
	setFly(false)
	setInfJump(false)
	setSword(false)
	stopEmote()
	stopMusic()
	setSpeed(16)
end

local function saveConfig()
	local ok = pcall(function()
		local data = "Key=" .. tostring(Config.Key)
			.. "\nKeyType=" .. tostring(Config.KeyType)
			.. "\nVolume=" .. tostring(Config.Volume)
			.. "\nWalkSpeed=" .. tostring(Config.WalkSpeed)
		if writefile then
			writefile("AetherConfig.txt", data)
		else
			_G.Aether_Saved = data
		end
	end)
	return ok
end

boot("Features ready", 0.45)

--------------------------------------------------
-- UI COMPONENT FACTORY
--------------------------------------------------
boot("Building UI…", 0.55)

local Gui = Instance.new("ScreenGui")
Gui.Name = "Aether"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999999
Gui.Enabled = true
parentGui(Gui)

if not Gui.Parent then
	boot("Cannot parent GUI", 1, true)
	warn("[Aether] parent failed")
	return
end
print("[Aether] parent =", Gui.Parent.Name)

-- Toast / bubble notify
local function notify(title, body)
	local bubble = Instance.new("Frame")
	bubble.Size = UDim2.fromOffset(260, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.Position = UDim2.new(1, -280, 0, 60)
	bubble.BackgroundColor3 = T.Glass
	bubble.BackgroundTransparency = 0.05
	bubble.BorderSizePixel = 0
	bubble.ZIndex = 200
	bubble.Parent = Gui
	corner(bubble, 14)
	stroke(bubble, T.Stroke, 0.35)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = bubble
	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, 0, 0, 18)
	t1.BackgroundTransparency = 1
	t1.Text = title or ""
	t1.TextColor3 = T.Text
	t1.Font = Enum.Font.GothamBold
	t1.TextSize = 12
	t1.TextXAlignment = Enum.TextXAlignment.Left
	t1.Parent = bubble
	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.new(1, 0, 0, 0)
	t2.AutomaticSize = Enum.AutomaticSize.Y
	t2.Position = UDim2.fromOffset(0, 20)
	t2.BackgroundTransparency = 1
	t2.Text = body or ""
	t2.TextColor3 = T.Muted
	t2.Font = Enum.Font.Gotham
	t2.TextSize = 11
	t2.TextWrapped = true
	t2.TextXAlignment = Enum.TextXAlignment.Left
	t2.Parent = bubble
	task.delay(2.2, function()
		pcall(function()
			tween(bubble, { BackgroundTransparency = 1 }, 0.2)
			task.wait(0.2)
			bubble:Destroy()
		end)
	end)
end

--------------------------------------------------
-- LOGIN
--------------------------------------------------
local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
Overlay.BackgroundTransparency = 0.28
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 50
Overlay.Parent = Gui

local Login = Instance.new("Frame")
Login.Size = UDim2.fromOffset(340, 370)
Login.Position = UDim2.new(0.5, -170, 0.5, -185)
Login.BackgroundColor3 = T.Glass
Login.BackgroundTransparency = 0.04
Login.BorderSizePixel = 0
Login.ZIndex = 60
Login.Parent = Gui
corner(Login, 22)
stroke(Login, T.Primary, 0.25, 1.5)

local logo = Instance.new("Frame")
logo.Size = UDim2.fromOffset(52, 52)
logo.Position = UDim2.new(0.5, -26, 0, 28)
logo.BackgroundColor3 = T.Primary
logo.Parent = Login
corner(logo, 14)
local logoT = Instance.new("TextLabel")
logoT.Size = UDim2.fromScale(1, 1)
logoT.BackgroundTransparency = 1
logoT.Text = "AE"
logoT.TextColor3 = Color3.new(1, 1, 1)
logoT.Font = Enum.Font.GothamBold
logoT.TextSize = 18
logoT.Parent = logo

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -32, 0, 26)
title.Position = UDim2.fromOffset(16, 92)
title.BackgroundTransparency = 1
title.Text = APP .. "  v" .. VERSION
title.TextColor3 = T.Text
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = Login

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -32, 0, 18)
sub.Position = UDim2.fromOffset(16, 120)
sub.BackgroundTransparency = 1
sub.Text = "Enter license key"
sub.TextColor3 = T.Muted
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.Parent = Login

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -48, 0, 44)
KeyBox.Position = UDim2.fromOffset(24, 152)
KeyBox.BackgroundColor3 = T.GlassSoft
KeyBox.BorderSizePixel = 0
KeyBox.PlaceholderText = "mtdz / demo / pro2026"
KeyBox.PlaceholderColor3 = T.Muted
KeyBox.Text = ""
KeyBox.TextColor3 = T.Text
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14
KeyBox.ClearTextOnFocus = false
KeyBox.Parent = Login
corner(KeyBox, 12)
stroke(KeyBox, T.Stroke, 0.35)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -48, 0, 18)
Status.Position = UDim2.fromOffset(24, 204)
Status.BackgroundTransparency = 1
Status.Text = "VIP test key: mtdz"
Status.TextColor3 = T.Muted
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.Parent = Login

local LoginBtn = Instance.new("TextButton")
LoginBtn.Size = UDim2.new(1, -48, 0, 46)
LoginBtn.Position = UDim2.fromOffset(24, 232)
LoginBtn.BackgroundColor3 = T.Primary
LoginBtn.BorderSizePixel = 0
LoginBtn.Text = "Unlock"
LoginBtn.TextColor3 = Color3.new(1, 1, 1)
LoginBtn.Font = Enum.Font.GothamBold
LoginBtn.TextSize = 15
LoginBtn.AutoButtonColor = false
LoginBtn.Parent = Login
corner(LoginBtn, 12)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -32, 0, 48)
hint.Position = UDim2.fromOffset(16, 292)
hint.BackgroundTransparency = 1
hint.Text = "VIP mtdz · PRO pro2026 · Free demo\nGetKey.html — captcha / PAY-OK / PAY-PRO"
hint.TextColor3 = T.Muted
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextWrapped = true
hint.Parent = Login

--------------------------------------------------
-- MAIN (vibrancy shell)
--------------------------------------------------
local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(372, 560)
Main.Position = UDim2.new(0.5, -186, 0.5, -280)
Main.BackgroundColor3 = T.BG
Main.BackgroundTransparency = 0.06
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = Gui
corner(Main, 24)
stroke(Main, T.Stroke, 0.3, 1.2)

-- soft vibrancy overlay
local vib = Instance.new("Frame")
vib.Size = UDim2.fromScale(1, 1)
vib.BackgroundColor3 = Color3.fromRGB(200, 230, 245)
vib.BackgroundTransparency = 0.92
vib.BorderSizePixel = 0
vib.Parent = Main
corner(vib, 24)

-- HEADER: avatar + status dot + name
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 64)
Header.BackgroundColor3 = T.Glass
Header.BackgroundTransparency = 0.15
Header.BorderSizePixel = 0
Header.ZIndex = 5
Header.Parent = Main

local Avatar = Instance.new("Frame")
Avatar.Size = UDim2.fromOffset(36, 36)
Avatar.Position = UDim2.fromOffset(16, 14)
Avatar.BackgroundColor3 = T.Primary
Avatar.BorderSizePixel = 0
Avatar.ZIndex = 6
Avatar.Parent = Header
corner(Avatar, 18)
local AvTx = Instance.new("TextLabel")
AvTx.Size = UDim2.fromScale(1, 1)
AvTx.BackgroundTransparency = 1
AvTx.Text = string.sub(LP.Name, 1, 1):upper()
AvTx.TextColor3 = Color3.new(1, 1, 1)
AvTx.Font = Enum.Font.GothamBold
AvTx.TextSize = 14
AvTx.ZIndex = 7
AvTx.Parent = Avatar

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(10, 10)
StatusDot.Position = UDim2.fromOffset(40, 38)
StatusDot.BackgroundColor3 = T.Online
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 8
StatusDot.Parent = Header
corner(StatusDot, 5)
stroke(StatusDot, Color3.new(1, 1, 1), 0, 2)

local NameLbl = Instance.new("TextLabel")
NameLbl.Size = UDim2.new(1, -140, 0, 18)
NameLbl.Position = UDim2.fromOffset(60, 14)
NameLbl.BackgroundTransparency = 1
NameLbl.Text = LP.DisplayName or LP.Name
NameLbl.TextColor3 = T.Text
NameLbl.Font = Enum.Font.GothamBold
NameLbl.TextSize = 13
NameLbl.TextXAlignment = Enum.TextXAlignment.Left
NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
NameLbl.ZIndex = 6
NameLbl.Parent = Header

local CodeLbl = Instance.new("TextLabel")
CodeLbl.Size = UDim2.new(1, -140, 0, 16)
CodeLbl.Position = UDim2.fromOffset(60, 34)
CodeLbl.BackgroundTransparency = 1
CodeLbl.Text = "@" .. LP.Name .. " · —"
CodeLbl.TextColor3 = T.Muted
CodeLbl.Font = Enum.Font.Gotham
CodeLbl.TextSize = 11
CodeLbl.TextXAlignment = Enum.TextXAlignment.Left
CodeLbl.TextTruncate = Enum.TextTruncate.AtEnd
CodeLbl.ZIndex = 6
CodeLbl.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -15)
CloseBtn.BackgroundColor3 = T.Danger
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.ZIndex = 6
CloseBtn.Parent = Header
corner(CloseBtn, 9)

-- BREADCRUMBS
local Crumb = Instance.new("TextLabel")
Crumb.Size = UDim2.new(1, -24, 0, 18)
Crumb.Position = UDim2.fromOffset(14, 68)
Crumb.BackgroundTransparency = 1
Crumb.Text = "Home"
Crumb.TextColor3 = T.Muted
Crumb.Font = Enum.Font.Gotham
Crumb.TextSize = 11
Crumb.TextXAlignment = Enum.TextXAlignment.Left
Crumb.ZIndex = 5
Crumb.Parent = Main

local function setCrumb(path)
	Crumb.Text = path
end

-- CONTENT
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -160)
Content.Position = UDim2.fromOffset(10, 90)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.ZIndex = 5
Content.Parent = Main

local Pages = {}
local function makePage(name)
	local sc = Instance.new("ScrollingFrame")
	sc.Name = name
	sc.Size = UDim2.fromScale(1, 1)
	sc.BackgroundTransparency = 1
	sc.BorderSizePixel = 0
	sc.ScrollBarThickness = 3
	sc.ScrollBarImageColor3 = T.Muted
	sc.CanvasSize = UDim2.fromOffset(0, 0)
	sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sc.Visible = false
	sc.ZIndex = 5
	sc.Parent = Content
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 8)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = sc
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = sc
	Pages[name] = sc
	return sc
end

local function section(parent, text, order)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 18)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = T.Muted
	l.Font = Enum.Font.GothamBold
	l.TextSize = 10
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = order
	l.Parent = parent
end

local function card(parent, h, order)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, h or 48)
	f.BackgroundColor3 = T.Glass
	f.BackgroundTransparency = 0.12
	f.BorderSizePixel = 0
	f.LayoutOrder = order
	f.Parent = parent
	corner(f, 14)
	stroke(f, T.Stroke, 0.5)
	return f
end

-- SWITCH (track + thumb)
local function makeSwitch(parent, title, order, initial, cb)
	local row = card(parent, 50, order)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -78, 1, 0)
	t.Position = UDim2.fromOffset(14, 0)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = T.Text
	t.Font = Enum.Font.Gotham
	t.TextSize = 13
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = row

	local state = initial and true or false
	local track = Instance.new("Frame")
	track.Size = UDim2.fromOffset(46, 28)
	track.Position = UDim2.new(1, -58, 0.5, -14)
	track.BackgroundColor3 = state and T.Primary or T.Track
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, 14)

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.fromOffset(22, 22)
	thumb.Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
	thumb.BackgroundColor3 = Color3.new(1, 1, 1)
	thumb.BorderSizePixel = 0
	thumb.Parent = track
	corner(thumb, 11)

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Parent = track
	hit.MouseButton1Click:Connect(function()
		state = not state
		tween(track, { BackgroundColor3 = state and T.Primary or T.Track }, 0.15)
		tween(thumb, { Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11) }, 0.15)
		pcall(cb, state)
	end)
	return row
end

-- SLIDER (track + fill + knob)
local function makeSlider(parent, title, order, minV, maxV, value, cb)
	local row = card(parent, 64, order)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(0.7, 0, 0, 18)
	t.Position = UDim2.fromOffset(14, 8)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = T.Text
	t.Font = Enum.Font.Gotham
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.new(0.3, -14, 0, 18)
	valLbl.Position = UDim2.new(0.7, 0, 0, 8)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = tostring(value)
	valLbl.TextColor3 = T.Muted
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 12
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = row

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -28, 0, 6)
	track.Position = UDim2.fromOffset(14, 40)
	track.BackgroundColor3 = T.Track
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, 3)

	local pct = (value - minV) / math.max(maxV - minV, 0.001)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = T.TrackFill
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 3)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(math.clamp(pct, 0, 1), 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.ZIndex = 3
	knob.Parent = track
	corner(knob, 8)
	stroke(knob, T.Primary, 0.2, 1.5)

	local dragging = false
	local function setFromX(x)
		local rel = math.clamp(x / track.AbsoluteSize.X, 0, 1)
		local v = minV + rel * (maxV - minV)
		-- snap to 0.01 for volume-like, integer for speed
		if maxV <= 1 then
			v = math.floor(v * 100 + 0.5) / 100
		else
			v = math.floor(v + 0.5)
		end
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		valLbl.Text = tostring(v)
		pcall(cb, v)
	end

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 0, 24)
	hit.Position = UDim2.fromOffset(0, -9)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 4
	hit.Parent = track

	hit.MouseButton1Down:Connect(function()
		dragging = true
	end)
	reg(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	reg(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local x = input.Position.X - track.AbsolutePosition.X
			setFromX(x)
		end
	end))
	hit.MouseButton1Click:Connect(function()
		local x = UserInputService:GetMouseLocation().X - track.AbsolutePosition.X
		setFromX(x)
	end)
	return row
end

local function btn(parent, text, order, color, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 42)
	b.BackgroundColor3 = color or T.Primary
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.LayoutOrder = order
	b.AutoButtonColor = false
	b.Parent = parent
	corner(b, 12)
	b.MouseButton1Click:Connect(function() pcall(cb) end)
	return b
end

-- COMBO BUTTON (primary action + disclosure)
local function makeCombo(parent, mainText, order, mainColor, mainCb, menuItems)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(1, 0, 0, 42)
	wrap.BackgroundTransparency = 1
	wrap.LayoutOrder = order
	wrap.Parent = parent

	local main = Instance.new("TextButton")
	main.Size = UDim2.new(1, -42, 1, 0)
	main.BackgroundColor3 = mainColor or T.Primary
	main.BorderSizePixel = 0
	main.Text = mainText
	main.TextColor3 = Color3.new(1, 1, 1)
	main.Font = Enum.Font.GothamBold
	main.TextSize = 13
	main.AutoButtonColor = false
	main.Parent = wrap
	corner(main, 12)
	-- square right edge for split look
	local clip = Instance.new("Frame")
	clip.Size = UDim2.fromOffset(14, 42)
	clip.Position = UDim2.new(1, -14, 0, 0)
	clip.BackgroundColor3 = mainColor or T.Primary
	clip.BorderSizePixel = 0
	clip.Parent = main

	local arrow = Instance.new("TextButton")
	arrow.Size = UDim2.fromOffset(40, 42)
	arrow.Position = UDim2.new(1, -40, 0, 0)
	arrow.BackgroundColor3 = (mainColor or T.Primary):Lerp(Color3.new(0, 0, 0), 0.12)
	arrow.BorderSizePixel = 0
	arrow.Text = "▾"
	arrow.TextColor3 = Color3.new(1, 1, 1)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 14
	arrow.AutoButtonColor = false
	arrow.Parent = wrap
	corner(arrow, 12)

	local div = Instance.new("Frame")
	div.Size = UDim2.fromOffset(1, 22)
	div.Position = UDim2.new(1, -40, 0.5, -11)
	div.BackgroundColor3 = Color3.new(1, 1, 1)
	div.BackgroundTransparency = 0.55
	div.BorderSizePixel = 0
	div.ZIndex = 2
	div.Parent = wrap

	local menuOpen = false
	local menuFrame = Instance.new("Frame")
	menuFrame.Size = UDim2.new(1, 0, 0, 0)
	menuFrame.AutomaticSize = Enum.AutomaticSize.Y
	menuFrame.Position = UDim2.fromOffset(0, 46)
	menuFrame.BackgroundColor3 = T.Glass
	menuFrame.BorderSizePixel = 0
	menuFrame.Visible = false
	menuFrame.ZIndex = 20
	menuFrame.Parent = wrap
	corner(menuFrame, 12)
	stroke(menuFrame, T.Stroke, 0.35)
	local mLay = Instance.new("UIListLayout")
	mLay.Padding = UDim.new(0, 0)
	mLay.Parent = menuFrame

	for _, item in ipairs(menuItems or {}) do
		local ib = Instance.new("TextButton")
		ib.Size = UDim2.new(1, 0, 0, 36)
		ib.BackgroundTransparency = 1
		ib.Text = "  " .. item[1]
		ib.TextColor3 = T.Text
		ib.Font = Enum.Font.Gotham
		ib.TextSize = 12
		ib.TextXAlignment = Enum.TextXAlignment.Left
		ib.Parent = menuFrame
		ib.MouseButton1Click:Connect(function()
			menuFrame.Visible = false
			menuOpen = false
			pcall(item[2])
		end)
	end

	main.MouseButton1Click:Connect(function() pcall(mainCb) end)
	arrow.MouseButton1Click:Connect(function()
		menuOpen = not menuOpen
		menuFrame.Visible = menuOpen
	end)
	return wrap
end

--------------------------------------------------
-- PAGES
--------------------------------------------------
local home = makePage("Home")
section(home, "OVERVIEW", 0)
local hero = card(home, 72, 1)
local heroT = Instance.new("TextLabel")
heroT.Size = UDim2.new(1, -24, 1, -16)
heroT.Position = UDim2.fromOffset(12, 8)
heroT.BackgroundTransparency = 1
heroT.Text = "Ready · Vibrancy UI\nKey: —"
heroT.TextColor3 = T.Text
heroT.Font = Enum.Font.Gotham
heroT.TextSize = 13
heroT.TextXAlignment = Enum.TextXAlignment.Left
heroT.TextYAlignment = Enum.TextYAlignment.Top
heroT.TextWrapped = true
heroT.Parent = hero

btn(home, "VIP Super Lag Fix", 2, T.Accent, function()
	setVipLag(true)
	notify("VIP Lag", "Ultra performance ON")
	heroT.Text = "VIP Lag ON"
end)
btn(home, "Quick Optimize", 3, T.Primary, function()
	setVipLag(true)
	notify("Optimize", "Applied")
end)
btn(home, "Panic Reset", 4, T.Danger, function()
	panic()
	notify("Panic", "All features off")
	heroT.Text = "Panic · all off"
end)

-- SAVE combo button
section(home, "SAVE", 5)
makeCombo(home, "Save Settings", 6, T.Success, function()
	local ok = saveConfig()
	notify("Save", ok and "Settings saved" or "Save failed")
end, {
	{ "Save As Profile", function() saveConfig() notify("Save As", "Profile saved") end },
	{ "Export Config", function() saveConfig() notify("Export", "Exported") end },
})

local boost = makePage("Boost")
section(boost, "PERFORMANCE", 0)
btn(boost, "VIP Super Lag", 1, T.Accent, function() setVipLag(true) notify("VIP", "ON") end)
btn(boost, "Restore Graphics", 2, T.Secondary, function() setVipLag(false) notify("Restore", "Done") end)
section(boost, "SPEED", 3)
makeSlider(boost, "Walk Speed", 4, 0, 200, Config.WalkSpeed, function(v)
	setSpeed(v)
end)

local music = makePage("Music")
section(music, "VOLUME", 0)
makeSlider(music, "Volume", 1, 0, 1, Config.Volume, function(v)
	setVolume(v)
end)
section(music, "SOUND ID", 2)
local musicCard = card(music, 48, 3)
local musicBox = Instance.new("TextBox")
musicBox.Size = UDim2.new(0.58, 0, 0, 32)
musicBox.Position = UDim2.fromOffset(10, 8)
musicBox.BackgroundColor3 = T.GlassSoft
musicBox.Text = ""
musicBox.PlaceholderText = "rbxassetid / numbers"
musicBox.PlaceholderColor3 = T.Muted
musicBox.TextColor3 = T.Text
musicBox.Font = Enum.Font.Gotham
musicBox.TextSize = 12
musicBox.Parent = musicCard
corner(musicBox, 8)
local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0.34, 0, 0, 32)
playBtn.Position = UDim2.new(0.62, 0, 0, 8)
playBtn.BackgroundColor3 = T.Primary
playBtn.Text = "Play"
playBtn.TextColor3 = Color3.new(1, 1, 1)
playBtn.Font = Enum.Font.GothamBold
playBtn.TextSize = 12
playBtn.Parent = musicCard
corner(playBtn, 8)
playBtn.MouseButton1Click:Connect(function()
	local ok, msg = playMusic(musicBox.Text)
	notify("Music", tostring(msg))
end)
btn(music, "Stop Music", 4, T.Danger, function()
	stopMusic()
	notify("Music", "Stopped")
end)

local tools = makePage("Tools")
section(tools, "COMBAT / VISUAL", 0)
makeSwitch(tools, "ESP Master", 1, false, setESP)
makeSwitch(tools, "ESP Box", 2, true, function(v) Config.ESPBox = v end)
makeSwitch(tools, "ESP Name", 3, true, function(v) Config.ESPName = v end)
makeSwitch(tools, "ESP Tracer", 4, false, function(v) Config.ESPTracer = v end)
makeSwitch(tools, "ESP Circle", 5, false, function(v) Config.ESPCircle = v end)
makeSwitch(tools, "ESP Rainbow", 6, false, function(v) Config.ESPRainbow = v end)
makeSwitch(tools, "Aim Assist", 7, false, setAim)
makeSwitch(tools, "Aim FOV Circle", 8, true, function(v) Config.AimCircle = v end)
makeSlider(tools, "Aim FOV", 9, 40, 300, Config.AimFOV, function(v) Config.AimFOV = v end)
makeSwitch(tools, "Shift Lock", 10, false, setShiftLock)
makeSwitch(tools, "Godmode", 11, false, setGod)
makeSwitch(tools, "Spin", 12, false, function(v) setSpin(v, Config.SpinSpeed) end)
section(tools, "MOVEMENT", 20)
makeSwitch(tools, "Noclip", 21, false, setNoclip)
makeSwitch(tools, "Fly (WASD Space/Ctrl)", 22, false, setFly)
makeSwitch(tools, "Infinite Jump", 23, false, setInfJump)
section(tools, "SWORD / EMOTES", 30)
makeSwitch(tools, "Orbit Sword", 31, false, setSword)
btn(tools, "Moonwalk (MJ)", 32, T.Primary, function() playEmote("moonwalk") notify("Emote", "Moonwalk") end)
btn(tools, "Spin Move", 33, T.Secondary, function() playEmote("spin") notify("Emote", "Spin") end)
btn(tools, "Dance", 34, T.Accent, function() playEmote("dance") end)
btn(tools, "Stop Emote", 35, T.Danger, function() stopEmote() end)

--------------------------------------------------
-- BOTTOM TAB BAR
--------------------------------------------------
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 58)
TabBar.Position = UDim2.new(0, 10, 1, -68)
TabBar.BackgroundColor3 = T.Glass
TabBar.BackgroundTransparency = 0.08
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 10
TabBar.Parent = Main
corner(TabBar, 18)
stroke(TabBar, T.Stroke, 0.35)

local tabLay = Instance.new("UIListLayout")
tabLay.FillDirection = Enum.FillDirection.Horizontal
tabLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLay.VerticalAlignment = Enum.VerticalAlignment.Center
tabLay.Padding = UDim.new(0, 4)
tabLay.Parent = TabBar

local tabBtns = {}
local currentPage = "Home"

local function showPage(name)
	currentPage = name
	for n, p in pairs(Pages) do
		p.Visible = (n == name)
	end
	for n, b in pairs(tabBtns) do
		local active = (n == name)
		b.TextColor3 = active and T.Primary or T.Muted
		b.BackgroundColor3 = active and T.GlassSoft or Color3.fromRGB(0, 0, 0)
		b.BackgroundTransparency = active and 0.2 or 1
	end
	local paths = {
		Home = "Aether  /  Home",
		Boost = "Aether  /  Boost",
		Music = "Aether  /  Music",
		Tools = "Aether  /  Tools",
	}
	setCrumb(paths[name] or ("Aether  /  " .. name))
end

local function addTab(name, icon)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(78, 46)
	b.BackgroundTransparency = 1
	b.Text = icon .. "\n" .. name
	b.TextColor3 = T.Muted
	b.Font = Enum.Font.GothamBold
	b.TextSize = 10
	b.ZIndex = 11
	b.Parent = TabBar
	corner(b, 12)
	tabBtns[name] = b
	b.MouseButton1Click:Connect(function() showPage(name) end)
end

addTab("Home", "⌂")
addTab("Boost", "⚡")
addTab("Music", "♫")
addTab("Tools", "⚙")
showPage("Home")

--------------------------------------------------
-- LOGIN / DESTROY
--------------------------------------------------
local function unlock(typ, label, exp)
	Config.KeyType = typ or "free"
	Overlay.Visible = false
	Login.Visible = false
	Main.Visible = true
	CodeLbl.Text = "@" .. LP.Name .. " · " .. string.upper(typ or "free")
	heroT.Text = string.format("%s · %s\nExpires in: %s", label or typ, string.upper(typ or ""), timeLeft(exp))
	boot("Unlocked", 1)
	notify("Welcome", (label or typ) .. " · " .. timeLeft(exp))
	pcall(function()
		if Boot then Boot:Destroy() end
	end)
end

local function tryLogin()
	local ok, typ, msg, exp = validateKey(KeyBox.Text)
	if ok then
		Status.Text = msg .. " · " .. timeLeft(exp)
		Status.TextColor3 = T.Success
		Config.Key = KeyBox.Text
		task.delay(0.15, function() unlock(typ, msg, exp) end)
	else
		Status.Text = tostring(msg)
		Status.TextColor3 = T.Danger
	end
end

LoginBtn.MouseButton1Click:Connect(tryLogin)
KeyBox.FocusLost:Connect(function(enter)
	if enter then tryLogin() end
end)

local function fullDestroy()
	Alive = false
	panic()
	clearESP()
	clearSword()
	for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
	pcall(function() Gui:Destroy() end)
	pcall(function() Boot:Destroy() end)
	pcall(function() if AimGui then AimGui:Destroy() end end)
	pcall(function() ESPFolder:Destroy() end)
	pcall(function() SwordFolder:Destroy() end)
	pcall(function() MusicSound:Destroy() end)
	_G.Aether_Engine = nil
end

CloseBtn.MouseButton1Click:Connect(fullDestroy)

_G.Aether_Engine = {
	Version = VERSION,
	Destroy = fullDestroy,
	ValidateKey = validateKey,
}

boot("Login ready", 0.95)
print("[Aether] v" .. VERSION .. " vibrancy UI · key: mtdz")
