--[[
  AETHER v3.0 — Full Premium UI
  Login · Keys+Expiry · VIP Lag · ESP · Aim · ShiftLock
  Noclip · Fly · InfJump · Sword · Emotes · Music · AI
  Items · Save · Panic · Vibrancy glass UI
]]

repeat task.wait() until game:IsLoaded()

pcall(function()
	if _G.Aether_Engine and type(_G.Aether_Engine.Destroy) == "function" then
		_G.Aether_Engine.Destroy()
	end
end)

local VERSION = "3.0"
local APP = "Aether"
local Alive = true
local SessionStart = os.clock()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")

local LP = Players.LocalPlayer
while not LP do task.wait() LP = Players.LocalPlayer end
local PlayerGui = LP:WaitForChild("PlayerGui", 12)

----------------------------------------------------------------
-- THEME
----------------------------------------------------------------
local T = {
	BG          = Color3.fromRGB(12, 16, 28),
	Glass       = Color3.fromRGB(22, 28, 48),
	GlassSoft   = Color3.fromRGB(28, 36, 58),
	Card        = Color3.fromRGB(26, 32, 54),
	Elevated    = Color3.fromRGB(34, 42, 68),
	Primary     = Color3.fromRGB(0, 230, 175),
	Secondary   = Color3.fromRGB(90, 150, 255),
	Accent      = Color3.fromRGB(180, 110, 255),
	Danger      = Color3.fromRGB(255, 85, 105),
	Warning     = Color3.fromRGB(255, 175, 70),
	Success     = Color3.fromRGB(0, 210, 150),
	Text        = Color3.fromRGB(245, 248, 255),
	Muted       = Color3.fromRGB(140, 155, 180),
	Dim         = Color3.fromRGB(90, 105, 130),
	Stroke      = Color3.fromRGB(80, 120, 180),
	Track       = Color3.fromRGB(40, 48, 70),
	Online      = Color3.fromRGB(50, 220, 120),
	UserBubble  = Color3.fromRGB(18, 70, 60),
	AIBubble    = Color3.fromRGB(30, 38, 58),
}

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local Config = {
	Key = "", KeyType = "free",
	WalkSpeed = 16, Spin = false, SpinSpeed = 20,
	Godmode = false,
	ESP = false, ESPBox = true, ESPName = true,
	ESPTracer = false, ESPRainbow = false, ESPCircle = false,
	Aim = false, AimFOV = 120, AimSmooth = 0.35, AimCircle = true,
	ShiftLock = false, Noclip = false, Fly = false, FlySpeed = 55,
	InfJump = false, Sword = false, SwordSpeed = 32, SwordAura = true,
	VipLag = false, Volume = 0.55, MusicId = "", Invis = false,
	Language = "vi",
}

----------------------------------------------------------------
-- KEYS
----------------------------------------------------------------
local function parseExp(s)
	local y,m,d,H,M,S = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)%s+(%d%d):(%d%d):(%d%d)$")
	if not y then y,m,d = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$"); H,M,S = 23,59,59 end
	if not y then return nil end
	return os.time({year=tonumber(y),month=tonumber(m),day=tonumber(d),hour=tonumber(H),min=tonumber(M),sec=tonumber(S)})
end

local KEYS = {
	mtdz    = { typ="vip",   exp=parseExp("2099-12-31 23:59:59"), label="VIP Lifetime" },
	aether  = { typ="vip",   exp=parseExp("2099-12-31 23:59:59"), label="VIP Lifetime" },
	pro2026 = { typ="pro",   exp=parseExp("2027-01-01 00:00:00"), label="PRO 2026" },
	demo    = { typ="free",  exp=parseExp("2026-12-31 23:59:59"), label="Free Demo" },
	free    = { typ="free",  exp=parseExp("2026-12-31 23:59:59"), label="Free" },
	trial   = { typ="trial", exp=parseExp("2026-10-31 23:59:59"), label="Trial" },
	daykey  = { typ="free",  exp=parseExp("2026-09-27 23:59:59"), label="1-Day" },
}

local function timeLeft(exp)
	if not exp then return "No limit" end
	local left = exp - os.time()
	if left <= 0 then return "Expired" end
	local d = math.floor(left/86400)
	local h = math.floor((left%86400)/3600)
	local m = math.floor((left%3600)/60)
	if d > 0 then return string.format("%dd %dh", d, h) end
	if h > 0 then return string.format("%dh %dm", h, m) end
	return m.."m"
end

local function validateKey(key)
	key = tostring(key or ""):gsub("^%s+",""):gsub("%s+$","")
	if key == "" then return false, nil, "Empty key" end
	local e = KEYS[key] or KEYS[string.lower(key)]
	if not e then
		for k,v in pairs(KEYS) do
			if string.lower(k) == string.lower(key) then e = v break end
		end
	end
	if not e then return false, nil, "Invalid key" end
	if e.exp and os.time() > e.exp then return false, e.typ, "Expired: "..e.label end
	return true, e.typ, e.label, e.exp
end

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local Conns = {}
local function reg(c) table.insert(Conns, c) return c end

local function tween(o, p, d, style)
	if not o then return end
	local tw = TweenService:Create(o, TweenInfo.new(d or 0.2, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p)
	tw:Play()
	return tw
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 14)
	c.Parent = p
	return c
end

local function stroke(p, col, tr, th)
	local s = Instance.new("UIStroke")
	s.Color = col or T.Stroke
	s.Transparency = tr or 0.5
	s.Thickness = th or 1.15
	s.Parent = p
	return s
end

local function gradient(p, c0, c1, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c0 or T.Primary, c1 or T.Secondary)
	g.Rotation = rot or 90
	g.Parent = p
	return g
end

local function parentGui(gui)
	local ok = pcall(function() if gethui then gui.Parent = gethui() end end)
	if ok and gui.Parent then return end
	ok = pcall(function() gui.Parent = CoreGui end)
	if ok and gui.Parent then return end
	pcall(function() if PlayerGui then gui.Parent = PlayerGui end end)
end

----------------------------------------------------------------
-- BOOT / LOADING
----------------------------------------------------------------
local Boot = Instance.new("ScreenGui")
Boot.Name = "AetherBoot"
Boot.ResetOnSpawn = false
Boot.IgnoreGuiInset = true
Boot.DisplayOrder = 1000001
Boot.Enabled = true
parentGui(Boot)

local BootCard = Instance.new("Frame")
BootCard.Size = UDim2.fromOffset(280, 100)
BootCard.Position = UDim2.new(0.5, -140, 0.07, 0)
BootCard.BackgroundColor3 = T.Glass
BootCard.BorderSizePixel = 0
BootCard.Parent = Boot
corner(BootCard, 18)
stroke(BootCard, T.Primary, 0.4, 1.3)

local BootTitle = Instance.new("TextLabel")
BootTitle.Size = UDim2.new(1, -24, 0, 22)
BootTitle.Position = UDim2.fromOffset(14, 14)
BootTitle.BackgroundTransparency = 1
BootTitle.Text = "Aether v"..VERSION
BootTitle.TextColor3 = T.Text
BootTitle.Font = Enum.Font.GothamBold
BootTitle.TextSize = 15
BootTitle.TextXAlignment = Enum.TextXAlignment.Left
BootTitle.Parent = BootCard

local BootBarBG = Instance.new("Frame")
BootBarBG.Size = UDim2.new(1, -28, 0, 8)
BootBarBG.Position = UDim2.fromOffset(14, 48)
BootBarBG.BackgroundColor3 = T.Track
BootBarBG.BorderSizePixel = 0
BootBarBG.Parent = BootCard
corner(BootBarBG, 4)

local BootBar = Instance.new("Frame")
BootBar.Size = UDim2.new(0.1, 0, 1, 0)
BootBar.BackgroundColor3 = T.Primary
BootBar.BorderSizePixel = 0
BootBar.Parent = BootBarBG
corner(BootBar, 4)
gradient(BootBar, T.Primary, T.Secondary, 0)

local BootSub = Instance.new("TextLabel")
BootSub.Size = UDim2.new(1, -24, 0, 18)
BootSub.Position = UDim2.fromOffset(14, 66)
BootSub.BackgroundTransparency = 1
BootSub.Text = "Starting…"
BootSub.TextColor3 = T.Muted
BootSub.Font = Enum.Font.Gotham
BootSub.TextSize = 12
BootSub.TextXAlignment = Enum.TextXAlignment.Left
BootSub.Parent = BootCard

local function boot(msg, pct, err)
	pcall(function()
		if msg then BootSub.Text = msg end
		if typeof(pct) == "number" then
			tween(BootBar, { Size = UDim2.new(math.clamp(pct,0,1), 0, 1, 0) }, 0.3)
		end
		if err then BootBar.BackgroundColor3 = T.Danger end
	end)
end

task.delay(12, function()
	if Boot and Boot.Parent then boot("Check F9 console", 1, true) end
end)

boot("Init…", 0.12)

----------------------------------------------------------------
-- FEATURES
----------------------------------------------------------------
local Original = { shadows=true, fog=1000, bright=1 }
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

reg(LP.CharacterAdded:Connect(function()
	task.wait(0.4)
	if Alive then setSpeed(Config.WalkSpeed) end
end))

local SpinConn
local function setSpin(on, spd)
	Config.Spin = on
	Config.SpinSpeed = tonumber(spd) or Config.SpinSpeed
	if SpinConn then SpinConn:Disconnect() SpinConn = nil end
	if not on then return end
	SpinConn = RunService.Heartbeat:Connect(function(dt)
		if not Alive or not Config.Spin then return end
		local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed*60*dt), 0) end
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

-- ESP
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

local function rainbow(t) return Color3.fromHSV((t*0.12)%1, 0.85, 1) end

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
						box.Size = Vector3.new(3.6, 6.2, 2)
						box.Transparency = 0.45
						box.Parent = ESPFolder
						local bill = Instance.new("BillboardGui")
						bill.Size = UDim2.fromOffset(120, 36)
						bill.StudsOffset = Vector3.new(0, 3.2, 0)
						bill.AlwaysOnTop = true
						bill.Parent = ESPFolder
						local nl = Instance.new("TextLabel")
						nl.Size = UDim2.fromScale(1,1)
						nl.BackgroundTransparency = 1
						nl.Text = plr.Name
						nl.TextColor3 = T.Primary
						nl.TextStrokeTransparency = 0.35
						nl.Font = Enum.Font.GothamBold
						nl.TextSize = 12
						nl.Parent = bill
						local beam = Instance.new("Beam")
						beam.Width0 = 0.12
						beam.Width1 = 0.04
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
						circle.Height = 0.12
						circle.Radius = 2.3
						circle.Transparency = 0.35
						circle.Parent = ESPFolder
						ESPObjs[plr] = {box=box,bill=bill,nl=nl,beam=beam,a0=a0,a1=a1,circle=circle}
					end
					local o = ESPObjs[plr]
					o.box.Adornee = root
					o.box.Visible = Config.ESPBox
					o.box.Color3 = col
					if head then o.bill.Adornee = head end
					o.bill.Enabled = Config.ESPName
					if o.nl then
						o.nl.TextColor3 = col
						o.nl.Text = plr.Name..(hum and ("  "..math.floor(hum.Health)) or "")
					end
					if Config.ESPTracer and my then
						o.a0.Parent = my; o.a0.Position = Vector3.zero
						o.a1.Parent = root; o.a1.Position = Vector3.zero
						o.beam.Enabled = true
						o.beam.Color = ColorSequence.new(col)
					else
						o.beam.Enabled = false
					end
					o.circle.Adornee = root
					o.circle.Visible = Config.ESPCircle
					o.circle.Color3 = col
					o.circle.CFrame = CFrame.new(0,-3,0)*CFrame.Angles(0,0,math.rad(90))
				end
			end
		end
	end)
	reg(ESPConn)
end

-- AIM
local AimGui, AimRing, AimConn
local function setAim(on)
	Config.Aim = on
	if not AimGui then
		AimGui = Instance.new("ScreenGui")
		AimGui.Name = "AetherAim"
		AimGui.IgnoreGuiInset = true
		AimGui.DisplayOrder = 999990
		AimGui.ResetOnSpawn = false
		parentGui(AimGui)
		AimRing = Instance.new("Frame")
		AimRing.AnchorPoint = Vector2.new(0.5,0.5)
		AimRing.Position = UDim2.fromScale(0.5,0.5)
		AimRing.BackgroundTransparency = 1
		AimRing.Parent = AimGui
		local st = Instance.new("UIStroke")
		st.Color = T.Primary
		st.Thickness = 1.6
		st.Transparency = 0.3
		st.Parent = AimRing
		Instance.new("UICorner", AimRing).CornerRadius = UDim.new(1,0)
		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(5,5)
		dot.AnchorPoint = Vector2.new(0.5,0.5)
		dot.Position = UDim2.fromScale(0.5,0.5)
		dot.BackgroundColor3 = T.Primary
		dot.BorderSizePixel = 0
		dot.Parent = AimRing
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
	end
	if AimConn then AimConn:Disconnect() AimConn = nil end
	AimRing.Visible = on and Config.AimCircle
	AimRing.Size = UDim2.fromOffset(Config.AimFOV*2, Config.AimFOV*2)
	if not on then return end
	AimConn = RunService.RenderStepped:Connect(function()
		if not Alive or not Config.Aim then return end
		AimRing.Visible = Config.AimCircle
		AimRing.Size = UDim2.fromOffset(Config.AimFOV*2, Config.AimFOV*2)
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local center = cam.ViewportSize/2
		local best, bestD = nil, Config.AimFOV
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP then
				local head = plr.Character and plr.Character:FindFirstChild("Head")
				local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
				if head and hum and hum.Health > 0 then
					local sp, onS = cam:WorldToViewportPoint(head.Position)
					if onS and sp.Z > 0 then
						local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
						if d < bestD then bestD = d best = head end
					end
				end
			end
		end
		if best then
			cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, best.Position), math.clamp(Config.AimSmooth,0.05,1))
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
			if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
		end)
		return
	end
	NoclipConn = RunService.Stepped:Connect(function()
		if not Alive or not Config.Noclip then return end
		local c = LP.Character
		if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
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
	FlyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
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
		FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
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

-- Invis
local InvisConn, InvisOrig = nil, {}
local function setInvis(on)
	Config.Invis = on
	if InvisConn then InvisConn:Disconnect() InvisConn = nil end
	local function apply(char, state)
		if not char then return end
		for _, inst in ipairs(char:GetDescendants()) do
			pcall(function()
				if inst:IsA("BasePart") then
					if state then
						if InvisOrig[inst] == nil then InvisOrig[inst] = inst.Transparency end
						inst.Transparency = 1
						inst.LocalTransparencyModifier = 1
					else
						inst.Transparency = InvisOrig[inst] or 0
						inst.LocalTransparencyModifier = 0
						InvisOrig[inst] = nil
					end
				elseif inst:IsA("Decal") or inst:IsA("Texture") then
					if state then
						if InvisOrig[inst] == nil then InvisOrig[inst] = inst.Transparency end
						inst.Transparency = 1
					else
						inst.Transparency = InvisOrig[inst] or 0
						InvisOrig[inst] = nil
					end
				end
			end)
		end
	end
	if on then
		apply(LP.Character, true)
		InvisConn = RunService.Heartbeat:Connect(function()
			if Alive and Config.Invis then apply(LP.Character, true) end
		end)
		reg(InvisConn)
	else
		apply(LP.Character, false)
		table.clear(InvisOrig)
	end
end

-- Emotes
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
			if not Alive or os.clock()-t0 > 4 then stopEmote() return end
			local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if r then r.CFrame = r.CFrame + (-r.CFrame.LookVector)*(8*dt) end
		end)
		reg(EmoteConn)
		return true, "Moonwalk MJ"
	end
	if id == "spin" then
		stopEmote()
		local t0 = os.clock()
		EmoteConn = RunService.RenderStepped:Connect(function(dt)
			if not Alive or os.clock()-t0 > 3 then stopEmote() return end
			local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(420*dt), 0) end
		end)
		reg(EmoteConn)
		return true, "Spin Move"
	end
	if id == "shuffle" then
		stopEmote()
		local t0, dir = os.clock(), 1
		EmoteConn = RunService.RenderStepped:Connect(function(dt)
			if not Alive or os.clock()-t0 > 3.5 then stopEmote() return end
			local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if not r then return end
			if (os.clock()-t0)%0.35 < dt then dir = -dir end
			r.CFrame = r.CFrame + r.CFrame.RightVector * dir * (10*dt)
		end)
		reg(EmoteConn)
		return true, "Shuffle"
	end
	stopEmote()
	local ids = {
		dance="rbxassetid://507771019",
		wave="rbxassetid://507770239",
		cheer="rbxassetid://507770677",
		laugh="rbxassetid://507770818",
		point="rbxassetid://507770453",
	}
	local animId = ids[id]
	if not animId then return false, "Unknown" end
	local ok, err = pcall(function()
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then error("no character") end
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		local a = Instance.new("Animation")
		a.AnimationId = animId
		EmoteTrack = animator:LoadAnimation(a)
		EmoteTrack.Looped = true
		EmoteTrack:Play(0.2)
	end)
	return ok, ok and id or tostring(err)
end

-- Sword
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
	local char = LP.Character
	if char then SwordFolder.Parent = char end
	for i = 1, 3 do
		local model = Instance.new("Model")
		model.Name = "Sword"..i
		model.Parent = SwordFolder
		local blade = Instance.new("Part")
		blade.Size = Vector3.new(0.28, 3.6, 0.5)
		blade.Material = Enum.Material.Neon
		blade.Color = T.Primary
		blade.Anchored = true
		blade.CanCollide = false
		blade.CastShadow = false
		blade.Parent = model
		local tip = Instance.new("Part")
		tip.Size = Vector3.new(0.22, 0.8, 0.4)
		tip.Material = Enum.Material.Neon
		tip.Color = Color3.fromRGB(180,255,230)
		tip.Anchored = true
		tip.CanCollide = false
		tip.Parent = model
		local aura = Instance.new("Part")
		aura.Size = Vector3.new(1.4, 4.2, 1.4)
		aura.Material = Enum.Material.ForceField
		aura.Color = T.Primary
		aura.Anchored = true
		aura.CanCollide = false
		aura.Transparency = Config.SwordAura and 0.55 or 1
		aura.Parent = model
		table.insert(Swords, {blade=blade, tip=tip, aura=aura, ang=(i-1)*(math.pi*2/3)})
	end
	SwordConn = RunService.RenderStepped:Connect(function(dt)
		if not Alive or not Config.Sword then return end
		local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		if SwordFolder.Parent ~= LP.Character then pcall(function() SwordFolder.Parent = LP.Character end) end
		SwordAng = SwordAng + math.rad(Config.SwordSpeed*60*dt)
		local t = os.clock()
		for _, s in ipairs(Swords) do
			local a = SwordAng + s.ang
			local pos = root.Position + Vector3.new(math.cos(a)*5, 1.3+math.sin(t*2+s.ang)*0.12, math.sin(a)*5)
			local cf = CFrame.lookAt(pos, root.Position+Vector3.new(0,1,0)) * CFrame.Angles(0,0,math.rad(90))
			if s.blade then s.blade.CFrame = cf end
			if s.tip then s.tip.CFrame = cf * CFrame.new(0, 2, 0) end
			if s.aura then
				s.aura.CFrame = cf
				s.aura.Transparency = Config.SwordAura and (0.5+0.15*math.sin(t*4+s.ang)) or 1
			end
		end
	end)
	reg(SwordConn)
end

-- Music
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
	MusicSound.SoundId = "rbxassetid://"..num
	local ok, err = pcall(function() MusicSound:Play() end)
	return ok, ok and "Playing" or tostring(err)
end

local function stopMusic()
	pcall(function() MusicSound:Stop() end)
end

-- Items
local ItemFolder = Instance.new("Folder")
ItemFolder.Name = "AetherItems"
ItemFolder.Parent = Workspace

local function spawnNear()
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	return root and (root.CFrame * CFrame.new(0,0,-4)) or CFrame.new(0,5,0)
end

local function claimItem(id)
	pcall(function()
		for _, c in ipairs(ItemFolder:GetChildren()) do
			if c.Name == id then c:Destroy() end
		end
	end)
	if id == "speaker" then
		local p = Instance.new("Part")
		p.Name = "speaker"
		p.Size = Vector3.new(1.5, 1.8, 1)
		p.Color = Color3.fromRGB(30,34,50)
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = spawnNear()
		p.Parent = ItemFolder
		local n = Instance.new("Part")
		n.Size = Vector3.new(0.9,0.9,0.4)
		n.Color = T.Primary
		n.Material = Enum.Material.Neon
		n.Anchored = true
		n.CanCollide = false
		n.CFrame = p.CFrame * CFrame.new(0,0.2,-0.55)
		n.Parent = ItemFolder
		return true, "Speaker spawned"
	elseif id == "light" then
		local p = Instance.new("Part")
		p.Name = "light"
		p.Size = Vector3.new(1,1,1)
		p.Color = T.Warning
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = spawnNear() * CFrame.new(0,2,0)
		p.Parent = ItemFolder
		local pl = Instance.new("PointLight")
		pl.Brightness = 2.5
		pl.Range = 20
		pl.Color = T.Warning
		pl.Parent = p
		return true, "Light spawned"
	elseif id == "platform" then
		local p = Instance.new("Part")
		p.Name = "platform"
		p.Size = Vector3.new(10, 0.4, 10)
		p.Color = T.Secondary
		p.Material = Enum.Material.Neon
		p.Transparency = 0.3
		p.Anchored = true
		p.CanCollide = true
		local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		p.CFrame = root and CFrame.new(root.Position - Vector3.new(0,3.2,0)) or CFrame.new(0,1,0)
		p.Parent = ItemFolder
		return true, "Platform spawned"
	end
	return false, "Unknown item"
end

local function clearItems()
	pcall(function() for _,c in ipairs(ItemFolder:GetChildren()) do c:Destroy() end end)
end

-- AI simple
local function aiReply(text)
	local t = string.lower(text or "")
	if t:find("lag") or t:find("fps") then return "Vào Boost → VIP Super Lag Fix để tối ưu lag." end
	if t:find("esp") then return "Tools → bật ESP Master + Box/Name/Tracer/Circle." end
	if t:find("aim") then return "Tools → Aim Assist + chỉnh FOV slider." end
	if t:find("fly") or t:find("bay") then return "Tools → Fly, dùng WASD + Space/Ctrl." end
	if t:find("kiếm") or t:find("sword") then return "Tools → Orbit Sword." end
	if t:find("múa") or t:find("dance") or t:find("mj") then return "Tools → Emotes: Moonwalk / Dance / Spin." end
	if t:find("key") or t:find("vip") then return "Key VIP: mtdz · PRO: pro2026 · Free: demo" end
	if t:find("xin chào") or t:find("hello") or t:find("hi") then return "Chào! Mình là Aether AI — hỏi về lag, ESP, aim, fly…" end
	return "Thử hỏi: lag, esp, aim, fly, sword, dance, key."
end

local function saveConfig()
	return pcall(function()
		local data = table.concat({
			"Key="..tostring(Config.Key),
			"KeyType="..tostring(Config.KeyType),
			"Volume="..tostring(Config.Volume),
			"WalkSpeed="..tostring(Config.WalkSpeed),
		}, "\n")
		if writefile then writefile("AetherConfig.txt", data)
		else _G.Aether_Saved = data end
	end)
end

local function panic()
	setVipLag(false) setSpin(false) setGod(false) setESP(false)
	setAim(false) setShiftLock(false) setNoclip(false) setFly(false)
	setInfJump(false) setSword(false) setInvis(false) stopEmote()
	stopMusic() clearItems() setSpeed(16)
end

boot("Features ready", 0.4)

----------------------------------------------------------------
-- UI BUILD
----------------------------------------------------------------
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
	boot("GUI parent failed", 1, true)
	warn("[Aether] cannot parent ScreenGui")
	return
end
print("[Aether] parent =", Gui.Parent.Name)

-- Notify bubbles
local function notify(title, body)
	local b = Instance.new("Frame")
	b.Size = UDim2.fromOffset(270, 0)
	b.AutomaticSize = Enum.AutomaticSize.Y
	b.Position = UDim2.new(1, -290, 0, 54)
	b.BackgroundColor3 = T.Glass
	b.BorderSizePixel = 0
	b.ZIndex = 300
	b.Parent = Gui
	corner(b, 14)
	stroke(b, T.Primary, 0.45)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = b
	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1,0,0,18)
	t1.BackgroundTransparency = 1
	t1.Text = title or "Aether"
	t1.TextColor3 = T.Primary
	t1.Font = Enum.Font.GothamBold
	t1.TextSize = 13
	t1.TextXAlignment = Enum.TextXAlignment.Left
	t1.Parent = b
	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.new(1,0,0,0)
	t2.AutomaticSize = Enum.AutomaticSize.Y
	t2.Position = UDim2.fromOffset(0, 20)
	t2.BackgroundTransparency = 1
	t2.Text = body or ""
	t2.TextColor3 = T.Muted
	t2.Font = Enum.Font.Gotham
	t2.TextSize = 12
	t2.TextWrapped = true
	t2.TextXAlignment = Enum.TextXAlignment.Left
	t2.Parent = b
	task.delay(2.4, function()
		pcall(function() tween(b,{BackgroundTransparency=1},0.2) task.wait(0.2) b:Destroy() end)
	end)
end

----------------------------------------------------------------
-- LOGIN
----------------------------------------------------------------
local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.fromScale(1,1)
Overlay.BackgroundColor3 = Color3.fromRGB(4,8,16)
Overlay.BackgroundTransparency = 0.25
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 40
Overlay.Parent = Gui

local Login = Instance.new("Frame")
Login.Size = UDim2.fromOffset(360, 400)
Login.Position = UDim2.new(0.5,-180,0.5,-200)
Login.BackgroundColor3 = T.Glass
Login.BorderSizePixel = 0
Login.ZIndex = 50
Login.Parent = Gui
corner(Login, 24)
stroke(Login, T.Primary, 0.3, 1.5)

local lg = Instance.new("Frame")
lg.Size = UDim2.fromOffset(56,56)
lg.Position = UDim2.new(0.5,-28,0,28)
lg.BackgroundColor3 = T.Primary
lg.Parent = Login
corner(lg, 16)
gradient(lg, T.Primary, T.Secondary, 45)
local lgt = Instance.new("TextLabel")
lgt.Size = UDim2.fromScale(1,1)
lgt.BackgroundTransparency = 1
lgt.Text = "Æ"
lgt.TextColor3 = Color3.fromRGB(8,20,16)
lgt.Font = Enum.Font.GothamBold
lgt.TextSize = 24
lgt.Parent = lg

local lt = Instance.new("TextLabel")
lt.Size = UDim2.new(1,-32,0,28)
lt.Position = UDim2.fromOffset(16,98)
lt.BackgroundTransparency = 1
lt.Text = APP.."  v"..VERSION
lt.TextColor3 = T.Text
lt.Font = Enum.Font.GothamBold
lt.TextSize = 22
lt.Parent = Login

local ls = Instance.new("TextLabel")
ls.Size = UDim2.new(1,-32,0,18)
ls.Position = UDim2.fromOffset(16,128)
ls.BackgroundTransparency = 1
ls.Text = "Premium · Enter license key"
ls.TextColor3 = T.Muted
ls.Font = Enum.Font.Gotham
ls.TextSize = 12
ls.Parent = Login

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1,-48,0,46)
KeyBox.Position = UDim2.fromOffset(24,164)
KeyBox.BackgroundColor3 = T.Elevated
KeyBox.BorderSizePixel = 0
KeyBox.PlaceholderText = "mtdz  ·  pro2026  ·  demo"
KeyBox.PlaceholderColor3 = T.Dim
KeyBox.Text = ""
KeyBox.TextColor3 = T.Text
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14
KeyBox.ClearTextOnFocus = false
KeyBox.Parent = Login
corner(KeyBox, 12)
stroke(KeyBox, T.Stroke, 0.4)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1,-48,0,18)
Status.Position = UDim2.fromOffset(24,218)
Status.BackgroundTransparency = 1
Status.Text = "VIP test: mtdz"
Status.TextColor3 = T.Muted
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.Parent = Login

local LoginBtn = Instance.new("TextButton")
LoginBtn.Size = UDim2.new(1,-48,0,48)
LoginBtn.Position = UDim2.fromOffset(24,248)
LoginBtn.BackgroundColor3 = T.Primary
LoginBtn.BorderSizePixel = 0
LoginBtn.Text = "Unlock"
LoginBtn.TextColor3 = Color3.fromRGB(6,18,14)
LoginBtn.Font = Enum.Font.GothamBold
LoginBtn.TextSize = 16
LoginBtn.AutoButtonColor = false
LoginBtn.Parent = Login
corner(LoginBtn, 14)

local lh = Instance.new("TextLabel")
lh.Size = UDim2.new(1,-32,0,50)
lh.Position = UDim2.fromOffset(16,312)
lh.BackgroundTransparency = 1
lh.Text = "VIP mtdz · PRO pro2026 · Free demo\nGetKey.html — captcha / PAY-OK / PAY-PRO"
lh.TextColor3 = T.Dim
lh.Font = Enum.Font.Gotham
lh.TextSize = 11
lh.TextWrapped = true
lh.Parent = Login

----------------------------------------------------------------
-- MAIN WINDOW
----------------------------------------------------------------
local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(390, 600)
Main.Position = UDim2.new(0.5,-195,0.5,-300)
Main.BackgroundColor3 = T.BG
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = Gui
corner(Main, 26)
stroke(Main, T.Stroke, 0.35, 1.3)

local amb = Instance.new("Frame")
amb.Size = UDim2.fromScale(1,1)
amb.BackgroundColor3 = Color3.fromRGB(0,40,60)
amb.BackgroundTransparency = 0.94
amb.BorderSizePixel = 0
amb.Parent = Main
corner(amb, 26)

-- HEADER
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,68)
Header.BackgroundColor3 = T.Glass
Header.BackgroundTransparency = 0.2
Header.BorderSizePixel = 0
Header.ZIndex = 10
Header.Parent = Main

local Avatar = Instance.new("Frame")
Avatar.Size = UDim2.fromOffset(40,40)
Avatar.Position = UDim2.fromOffset(16,14)
Avatar.BackgroundColor3 = T.Primary
Avatar.BorderSizePixel = 0
Avatar.ZIndex = 11
Avatar.Parent = Header
corner(Avatar, 20)
gradient(Avatar, T.Primary, T.Secondary, 45)
local AvT = Instance.new("TextLabel")
AvT.Size = UDim2.fromScale(1,1)
AvT.BackgroundTransparency = 1
AvT.Text = string.sub(LP.Name,1,1):upper()
AvT.TextColor3 = Color3.fromRGB(8,20,16)
AvT.Font = Enum.Font.GothamBold
AvT.TextSize = 16
AvT.ZIndex = 12
AvT.Parent = Avatar

local Dot = Instance.new("Frame")
Dot.Size = UDim2.fromOffset(11,11)
Dot.Position = UDim2.fromOffset(44,40)
Dot.BackgroundColor3 = T.Online
Dot.BorderSizePixel = 0
Dot.ZIndex = 13
Dot.Parent = Header
corner(Dot, 6)
stroke(Dot, T.BG, 0, 2)

local NameL = Instance.new("TextLabel")
NameL.Size = UDim2.new(1,-130,0,18)
NameL.Position = UDim2.fromOffset(66,16)
NameL.BackgroundTransparency = 1
NameL.Text = LP.DisplayName or LP.Name
NameL.TextColor3 = T.Text
NameL.Font = Enum.Font.GothamBold
NameL.TextSize = 14
NameL.TextXAlignment = Enum.TextXAlignment.Left
NameL.TextTruncate = Enum.TextTruncate.AtEnd
NameL.ZIndex = 11
NameL.Parent = Header

local CodeL = Instance.new("TextLabel")
CodeL.Size = UDim2.new(1,-130,0,16)
CodeL.Position = UDim2.fromOffset(66,36)
CodeL.BackgroundTransparency = 1
CodeL.Text = "@"..LP.Name.." · —"
CodeL.TextColor3 = T.Muted
CodeL.Font = Enum.Font.Gotham
CodeL.TextSize = 11
CodeL.TextXAlignment = Enum.TextXAlignment.Left
CodeL.TextTruncate = Enum.TextTruncate.AtEnd
CodeL.ZIndex = 11
CodeL.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(32,32)
CloseBtn.Position = UDim2.new(1,-46,0.5,-16)
CloseBtn.BackgroundColor3 = T.Danger
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.ZIndex = 12
CloseBtn.Parent = Header
corner(CloseBtn, 10)

-- Breadcrumbs
local Crumb = Instance.new("TextLabel")
Crumb.Size = UDim2.new(1,-28,0,16)
Crumb.Position = UDim2.fromOffset(16,72)
Crumb.BackgroundTransparency = 1
Crumb.Text = "Aether  /  Home"
Crumb.TextColor3 = T.Dim
Crumb.Font = Enum.Font.Gotham
Crumb.TextSize = 11
Crumb.TextXAlignment = Enum.TextXAlignment.Left
Crumb.ZIndex = 10
Crumb.Parent = Main

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-20,1,-168)
Content.Position = UDim2.fromOffset(10,94)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.ZIndex = 10
Content.Parent = Main

local Pages = {}
local function makePage(name)
	local sc = Instance.new("ScrollingFrame")
	sc.Name = name
	sc.Size = UDim2.fromScale(1,1)
	sc.BackgroundTransparency = 1
	sc.BorderSizePixel = 0
	sc.ScrollBarThickness = 3
	sc.ScrollBarImageColor3 = T.Primary
	sc.CanvasSize = UDim2.fromOffset(0,0)
	sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sc.Visible = false
	sc.ZIndex = 10
	sc.Parent = Content
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0,9)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = sc
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0,2)
	pad.PaddingBottom = UDim.new(0,14)
	pad.Parent = sc
	Pages[name] = sc
	return sc
end

local function section(p, text, order)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1,0,0,18)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = T.Dim
	l.Font = Enum.Font.GothamBold
	l.TextSize = 10
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = order
	l.Parent = p
end

local function card(p, h, order)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,0,h or 50)
	f.BackgroundColor3 = T.Card
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel = 0
	f.LayoutOrder = order
	f.Parent = p
	corner(f, 14)
	stroke(f, T.Stroke, 0.55)
	return f
end

-- Switch
local function makeSwitch(p, title, order, initial, cb)
	local row = card(p, 52, order)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1,-80,1,0)
	t.Position = UDim2.fromOffset(14,0)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = T.Text
	t.Font = Enum.Font.Gotham
	t.TextSize = 13
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = row
	local state = initial and true or false
	local track = Instance.new("Frame")
	track.Size = UDim2.fromOffset(48,28)
	track.Position = UDim2.new(1,-60,0.5,-14)
	track.BackgroundColor3 = state and T.Primary or T.Track
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, 14)
	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.fromOffset(22,22)
	thumb.Position = state and UDim2.new(1,-25,0.5,-11) or UDim2.new(0,3,0.5,-11)
	thumb.BackgroundColor3 = Color3.new(1,1,1)
	thumb.BorderSizePixel = 0
	thumb.Parent = track
	corner(thumb, 11)
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.fromScale(1,1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Parent = track
	hit.MouseButton1Click:Connect(function()
		state = not state
		tween(track,{BackgroundColor3=state and T.Primary or T.Track},0.15)
		tween(thumb,{Position=state and UDim2.new(1,-25,0.5,-11) or UDim2.new(0,3,0.5,-11)},0.15)
		pcall(cb, state)
	end)
end

-- Slider
local function makeSlider(p, title, order, minV, maxV, value, cb)
	local row = card(p, 68, order)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(0.65,0,0,18)
	t.Position = UDim2.fromOffset(14,10)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = T.Text
	t.Font = Enum.Font.Gotham
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = row
	local valL = Instance.new("TextLabel")
	valL.Size = UDim2.new(0.35,-14,0,18)
	valL.Position = UDim2.new(0.65,0,0,10)
	valL.BackgroundTransparency = 1
	valL.Text = tostring(value)
	valL.TextColor3 = T.Primary
	valL.Font = Enum.Font.GothamBold
	valL.TextSize = 12
	valL.TextXAlignment = Enum.TextXAlignment.Right
	valL.Parent = row
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1,-28,0,6)
	track.Position = UDim2.fromOffset(14,42)
	track.BackgroundColor3 = T.Track
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, 3)
	local pct = (value-minV)/math.max(maxV-minV,0.001)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp(pct,0,1),0,1,0)
	fill.BackgroundColor3 = T.Primary
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 3)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16,16)
	knob.AnchorPoint = Vector2.new(0.5,0.5)
	knob.Position = UDim2.new(math.clamp(pct,0,1),0,0.5,0)
	knob.BackgroundColor3 = Color3.new(1,1,1)
	knob.BorderSizePixel = 0
	knob.ZIndex = 3
	knob.Parent = track
	corner(knob, 8)
	stroke(knob, T.Primary, 0.15, 1.5)
	local dragging = false
	local function setFromX(x)
		local rel = math.clamp(x/math.max(track.AbsoluteSize.X,1),0,1)
		local v = minV + rel*(maxV-minV)
		if maxV <= 1 then v = math.floor(v*100+0.5)/100
		else v = math.floor(v+0.5) end
		fill.Size = UDim2.new(rel,0,1,0)
		knob.Position = UDim2.new(rel,0,0.5,0)
		valL.Text = tostring(v)
		pcall(cb, v)
	end
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1,0,0,28)
	hit.Position = UDim2.fromOffset(0,-11)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 4
	hit.Parent = track
	hit.MouseButton1Down:Connect(function() dragging = true end)
	reg(UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	reg(UserInputService.InputChanged:Connect(function(inp)
		if not dragging then return end
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			setFromX(inp.Position.X - track.AbsolutePosition.X)
		end
	end))
	hit.MouseButton1Click:Connect(function()
		setFromX(UserInputService:GetMouseLocation().X - track.AbsolutePosition.X)
	end)
end

local function btn(p, text, order, color, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,44)
	b.BackgroundColor3 = color or T.Primary
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = (color == T.Primary or not color) and Color3.fromRGB(6,18,14) or Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.LayoutOrder = order
	b.AutoButtonColor = false
	b.Parent = p
	corner(b, 12)
	b.MouseButton1Click:Connect(function()
		tween(b,{Size=UDim2.new(1,0,0,40)},0.08)
		task.delay(0.08, function() tween(b,{Size=UDim2.new(1,0,0,44)},0.12) end)
		pcall(cb)
	end)
	return b
end

-- Combo Save
local function makeCombo(p, mainText, order, color, mainCb, items)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(1,0,0,44)
	wrap.BackgroundTransparency = 1
	wrap.LayoutOrder = order
	wrap.ZIndex = 15
	wrap.Parent = p
	local main = Instance.new("TextButton")
	main.Size = UDim2.new(1,-44,1,0)
	main.BackgroundColor3 = color or T.Success
	main.BorderSizePixel = 0
	main.Text = mainText
	main.TextColor3 = Color3.fromRGB(6,18,14)
	main.Font = Enum.Font.GothamBold
	main.TextSize = 13
	main.AutoButtonColor = false
	main.Parent = wrap
	corner(main, 12)
	local edge = Instance.new("Frame")
	edge.Size = UDim2.fromOffset(16,44)
	edge.Position = UDim2.new(1,-16,0,0)
	edge.BackgroundColor3 = color or T.Success
	edge.BorderSizePixel = 0
	edge.Parent = main
	local arrow = Instance.new("TextButton")
	arrow.Size = UDim2.fromOffset(42,44)
	arrow.Position = UDim2.new(1,-42,0,0)
	arrow.BackgroundColor3 = (color or T.Success):Lerp(Color3.new(0,0,0),0.15)
	arrow.BorderSizePixel = 0
	arrow.Text = "▾"
	arrow.TextColor3 = Color3.fromRGB(6,18,14)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 14
	arrow.AutoButtonColor = false
	arrow.Parent = wrap
	corner(arrow, 12)
	local div = Instance.new("Frame")
	div.Size = UDim2.fromOffset(1,24)
	div.Position = UDim2.new(1,-42,0.5,-12)
	div.BackgroundColor3 = Color3.new(0,0,0)
	div.BackgroundTransparency = 0.55
	div.BorderSizePixel = 0
	div.ZIndex = 2
	div.Parent = wrap
	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(1,0,0,0)
	menu.AutomaticSize = Enum.AutomaticSize.Y
	menu.Position = UDim2.fromOffset(0,48)
	menu.BackgroundColor3 = T.Elevated
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.ZIndex = 25
	menu.Parent = wrap
	corner(menu, 12)
	stroke(menu, T.Stroke, 0.4)
	local mLay = Instance.new("UIListLayout")
	mLay.Parent = menu
	local open = false
	for _, it in ipairs(items or {}) do
		local ib = Instance.new("TextButton")
		ib.Size = UDim2.new(1,0,0,38)
		ib.BackgroundTransparency = 1
		ib.Text = "  "..it[1]
		ib.TextColor3 = T.Text
		ib.Font = Enum.Font.Gotham
		ib.TextSize = 12
		ib.TextXAlignment = Enum.TextXAlignment.Left
		ib.Parent = menu
		ib.MouseButton1Click:Connect(function()
			menu.Visible = false
			open = false
			pcall(it[2])
		end)
	end
	main.MouseButton1Click:Connect(function() pcall(mainCb) end)
	arrow.MouseButton1Click:Connect(function()
		open = not open
		menu.Visible = open
	end)
end

----------------------------------------------------------------
-- PAGES CONTENT
----------------------------------------------------------------
local home = makePage("Home")
section(home, "OVERVIEW", 0)
local hero = card(home, 88, 1)
local heroGrad = Instance.new("Frame")
heroGrad.Size = UDim2.fromScale(1,1)
heroGrad.BackgroundColor3 = T.Primary
heroGrad.BackgroundTransparency = 0.88
heroGrad.BorderSizePixel = 0
heroGrad.Parent = hero
corner(heroGrad, 14)
local heroT = Instance.new("TextLabel")
heroT.Size = UDim2.new(1,-24,1,-16)
heroT.Position = UDim2.fromOffset(12,8)
heroT.BackgroundTransparency = 1
heroT.Text = "Ready · Full Premium UI\nKey: —"
heroT.TextColor3 = T.Text
heroT.Font = Enum.Font.Gotham
heroT.TextSize = 13
heroT.TextXAlignment = Enum.TextXAlignment.Left
heroT.TextYAlignment = Enum.TextYAlignment.Top
heroT.TextWrapped = true
heroT.ZIndex = 2
heroT.Parent = hero

local stats = Instance.new("Frame")
stats.Size = UDim2.new(1,0,0,70)
stats.BackgroundTransparency = 1
stats.LayoutOrder = 2
stats.Parent = home
local function miniStat(x, title, val)
	local c = Instance.new("Frame")
	c.Size = UDim2.new(0.48,0,1,0)
	c.Position = UDim2.fromScale(x,0)
	c.BackgroundColor3 = T.Card
	c.BorderSizePixel = 0
	c.Parent = stats
	corner(c, 14)
	stroke(c, T.Stroke, 0.55)
	local a = Instance.new("TextLabel")
	a.Size = UDim2.new(1,-16,0,16)
	a.Position = UDim2.fromOffset(12,12)
	a.BackgroundTransparency = 1
	a.Text = title
	a.TextColor3 = T.Muted
	a.Font = Enum.Font.Gotham
	a.TextSize = 11
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Parent = c
	local b = Instance.new("TextLabel")
	b.Size = UDim2.new(1,-16,0,24)
	b.Position = UDim2.fromOffset(12,32)
	b.BackgroundTransparency = 1
	b.Text = val
	b.TextColor3 = T.Text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 18
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = c
	return b
end
local FpsL = miniStat(0, "FPS", "--")
local PingL = miniStat(0.52, "PING", "--")
reg(RunService.RenderStepped:Connect(function()
	-- lightweight sample each ~0.5s via counter
end))
do
	local frames, last = 0, os.clock()
	reg(RunService.RenderStepped:Connect(function()
		if not Alive then return end
		frames += 1
		local now = os.clock()
		if now - last >= 0.5 then
			FpsL.Text = tostring(math.floor(frames/(now-last)+0.5))
			frames, last = 0, now
			pcall(function()
				PingL.Text = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()).." ms"
			end)
		end
	end))
end

btn(home, "VIP Super Lag Fix", 3, T.Accent, function()
	setVipLag(true)
	notify("VIP Lag", "Ultra performance ON")
	heroT.Text = "VIP Lag ON · Full Premium"
end)
btn(home, "Quick Optimize", 4, T.Primary, function()
	setVipLag(true)
	notify("Optimize", "Applied")
end)
btn(home, "Panic Reset", 5, T.Danger, function()
	panic()
	notify("Panic", "All features off")
	heroT.Text = "Panic · all off"
end)
section(home, "SAVE", 6)
makeCombo(home, "Save Settings", 7, T.Success, function()
	local ok = saveConfig()
	notify("Save", ok and "Settings saved" or "Save failed")
end, {
	{"Save As Profile", function() saveConfig() notify("Save As","Profile saved") end},
	{"Export Config", function() saveConfig() notify("Export","Exported") end},
})

local boost = makePage("Boost")
section(boost, "PERFORMANCE", 0)
btn(boost, "VIP Super Lag", 1, T.Accent, function() setVipLag(true) notify("VIP","ON") end)
btn(boost, "Restore Graphics", 2, T.Secondary, function() setVipLag(false) notify("Restore","Done") end)
section(boost, "WALK SPEED", 3)
makeSlider(boost, "Walk Speed", 4, 0, 200, Config.WalkSpeed, setSpeed)
section(boost, "SPIN", 5)
makeSwitch(boost, "Spin Bot", 6, false, function(v) setSpin(v, Config.SpinSpeed) end)
makeSlider(boost, "Spin Speed", 7, 1, 100, Config.SpinSpeed, function(v) Config.SpinSpeed = v if Config.Spin then setSpin(true,v) end end)

local music = makePage("Music")
section(music, "VOLUME", 0)
makeSlider(music, "Volume", 1, 0, 1, Config.Volume, setVolume)
section(music, "PLAYBACK", 2)
local mCard = card(music, 52, 3)
local mBox = Instance.new("TextBox")
mBox.Size = UDim2.new(0.58,0,0,34)
mBox.Position = UDim2.fromOffset(10,9)
mBox.BackgroundColor3 = T.Elevated
mBox.BorderSizePixel = 0
mBox.PlaceholderText = "Sound ID"
mBox.PlaceholderColor3 = T.Dim
mBox.Text = ""
mBox.TextColor3 = T.Text
mBox.Font = Enum.Font.Gotham
mBox.TextSize = 12
mBox.Parent = mCard
corner(mBox, 10)
local mPlay = Instance.new("TextButton")
mPlay.Size = UDim2.new(0.34,0,0,34)
mPlay.Position = UDim2.new(0.62,0,0,9)
mPlay.BackgroundColor3 = T.Primary
mPlay.Text = "Play"
mPlay.TextColor3 = Color3.fromRGB(6,18,14)
mPlay.Font = Enum.Font.GothamBold
mPlay.TextSize = 12
mPlay.Parent = mCard
corner(mPlay, 10)
mPlay.MouseButton1Click:Connect(function()
	local ok,msg = playMusic(mBox.Text)
	notify("Music", tostring(msg))
end)
btn(music, "Stop Music", 4, T.Danger, function() stopMusic() notify("Music","Stopped") end)

local ai = makePage("AI")
section(ai, "CHAT", 0)
local chatScroll = Instance.new("ScrollingFrame")
chatScroll.Size = UDim2.new(1,0,0,280)
chatScroll.BackgroundColor3 = T.Card
chatScroll.BackgroundTransparency = 0.15
chatScroll.BorderSizePixel = 0
chatScroll.ScrollBarThickness = 3
chatScroll.CanvasSize = UDim2.fromOffset(0,0)
chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
chatScroll.LayoutOrder = 1
chatScroll.Parent = ai
corner(chatScroll, 14)
local chatLay = Instance.new("UIListLayout")
chatLay.Padding = UDim.new(0,8)
chatLay.SortOrder = Enum.SortOrder.LayoutOrder
chatLay.Parent = chatScroll
local chatPad = Instance.new("UIPadding")
chatPad.PaddingTop = UDim.new(0,10)
chatPad.PaddingBottom = UDim.new(0,10)
chatPad.PaddingLeft = UDim.new(0,10)
chatPad.PaddingRight = UDim.new(0,10)
chatPad.Parent = chatScroll

local function addBubble(text, isUser)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(1,0,0,0)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	wrap.BackgroundTransparency = 1
	wrap.Parent = chatScroll
	local bubble = Instance.new("Frame")
	bubble.Size = UDim2.new(0.82,0,0,0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.Position = isUser and UDim2.new(0.18,0,0,0) or UDim2.fromOffset(0,0)
	bubble.BackgroundColor3 = isUser and T.UserBubble or T.AIBubble
	bubble.BorderSizePixel = 0
	bubble.Parent = wrap
	corner(bubble, 14)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0,10)
	pad.PaddingBottom = UDim.new(0,10)
	pad.PaddingLeft = UDim.new(0,12)
	pad.PaddingRight = UDim.new(0,12)
	pad.Parent = bubble
	local lab = Instance.new("TextLabel")
	lab.Size = UDim2.new(1,0,0,0)
	lab.AutomaticSize = Enum.AutomaticSize.Y
	lab.BackgroundTransparency = 1
	lab.Text = text
	lab.TextColor3 = T.Text
	lab.Font = Enum.Font.Gotham
	lab.TextSize = 12
	lab.TextWrapped = true
	lab.TextXAlignment = Enum.TextXAlignment.Left
	lab.Parent = bubble
end
addBubble("Xin chào! Hỏi mình về lag, ESP, aim, fly, sword…", false)

local aiRow = Instance.new("Frame")
aiRow.Size = UDim2.new(1,0,0,44)
aiRow.BackgroundTransparency = 1
aiRow.LayoutOrder = 2
aiRow.Parent = ai
local aiBox = Instance.new("TextBox")
aiBox.Size = UDim2.new(1,-90,1,0)
aiBox.BackgroundColor3 = T.Elevated
aiBox.BorderSizePixel = 0
aiBox.PlaceholderText = "Nhắn với AI…"
aiBox.PlaceholderColor3 = T.Dim
aiBox.Text = ""
aiBox.TextColor3 = T.Text
aiBox.Font = Enum.Font.Gotham
aiBox.TextSize = 13
aiBox.ClearTextOnFocus = false
aiBox.Parent = aiRow
corner(aiBox, 12)
local aiSend = Instance.new("TextButton")
aiSend.Size = UDim2.fromOffset(80,44)
aiSend.Position = UDim2.new(1,-80,0,0)
aiSend.BackgroundColor3 = T.Primary
aiSend.Text = "Gửi"
aiSend.TextColor3 = Color3.fromRGB(6,18,14)
aiSend.Font = Enum.Font.GothamBold
aiSend.TextSize = 13
aiSend.Parent = aiRow
corner(aiSend, 12)
local function sendAI()
	local text = (aiBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
	if text == "" then return end
	aiBox.Text = ""
	addBubble(text, true)
	task.delay(0.3, function() addBubble(aiReply(text), false) end)
end
aiSend.MouseButton1Click:Connect(sendAI)
aiBox.FocusLost:Connect(function(e) if e then sendAI() end end)

local tools = makePage("Tools")
section(tools, "COMBAT / VISUAL", 0)
makeSwitch(tools, "ESP Master", 1, false, setESP)
makeSwitch(tools, "ESP Box", 2, true, function(v) Config.ESPBox = v end)
makeSwitch(tools, "ESP Name + HP", 3, true, function(v) Config.ESPName = v end)
makeSwitch(tools, "ESP Tracer Line", 4, false, function(v) Config.ESPTracer = v end)
makeSwitch(tools, "ESP Circle", 5, false, function(v) Config.ESPCircle = v end)
makeSwitch(tools, "ESP Rainbow", 6, false, function(v) Config.ESPRainbow = v end)
makeSwitch(tools, "Aim Assist", 7, false, setAim)
makeSwitch(tools, "Show FOV Circle", 8, true, function(v) Config.AimCircle = v end)
makeSlider(tools, "Aim FOV", 9, 40, 300, Config.AimFOV, function(v) Config.AimFOV = v end)
makeSlider(tools, "Aim Smooth", 10, 0.05, 1, Config.AimSmooth, function(v) Config.AimSmooth = v end)
makeSwitch(tools, "Shift Lock", 11, false, setShiftLock)
makeSwitch(tools, "Godmode", 12, false, setGod)
makeSwitch(tools, "Invisibility", 13, false, setInvis)
section(tools, "MOVEMENT", 20)
makeSwitch(tools, "Noclip", 21, false, setNoclip)
makeSwitch(tools, "Fly (WASD · Space/Ctrl)", 22, false, setFly)
makeSwitch(tools, "Infinite Jump", 23, false, setInfJump)
section(tools, "SWORD", 30)
makeSwitch(tools, "Orbit Sword", 31, false, setSword)
makeSwitch(tools, "Sword Aura", 32, true, function(v) Config.SwordAura = v end)
makeSlider(tools, "Sword Speed", 33, 5, 120, Config.SwordSpeed, function(v)
	Config.SwordSpeed = v
	if Config.Sword then setSword(true) end
end)
section(tools, "EMOTES · MÚA", 40)
btn(tools, "Moonwalk (MJ)", 41, T.Primary, function() local ok,m=playEmote("moonwalk") notify("Emote",tostring(m)) end)
btn(tools, "Shuffle", 42, T.Secondary, function() local ok,m=playEmote("shuffle") notify("Emote",tostring(m)) end)
btn(tools, "Spin Move", 43, T.Accent, function() local ok,m=playEmote("spin") notify("Emote",tostring(m)) end)
btn(tools, "Dance", 44, T.Primary, function() playEmote("dance") end)
btn(tools, "Wave · Cheer · Point", 45, T.Secondary, function() playEmote("wave") end)
btn(tools, "Stop Emote", 46, T.Danger, function() stopEmote() notify("Emote","Stopped") end)
section(tools, "ITEMS", 50)
btn(tools, "Spawn Speaker", 51, T.Primary, function() local ok,m=claimItem("speaker") notify("Item",tostring(m)) end)
btn(tools, "Spawn Neon Light", 52, T.Warning, function() local ok,m=claimItem("light") notify("Item",tostring(m)) end)
btn(tools, "Spawn Platform", 53, T.Secondary, function() local ok,m=claimItem("platform") notify("Item",tostring(m)) end)
btn(tools, "Clear Items", 54, T.Danger, function() clearItems() notify("Items","Cleared") end)

----------------------------------------------------------------
-- TAB BAR
----------------------------------------------------------------
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,-20,0,60)
TabBar.Position = UDim2.new(0,10,1,-70)
TabBar.BackgroundColor3 = T.Glass
TabBar.BackgroundTransparency = 0.1
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 20
TabBar.Parent = Main
corner(TabBar, 18)
stroke(TabBar, T.Stroke, 0.4)

local tabLay = Instance.new("UIListLayout")
tabLay.FillDirection = Enum.FillDirection.Horizontal
tabLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLay.VerticalAlignment = Enum.VerticalAlignment.Center
tabLay.Padding = UDim.new(0,4)
tabLay.Parent = TabBar

local tabBtns = {}
local function showPage(name)
	for n,p in pairs(Pages) do p.Visible = (n==name) end
	for n,b in pairs(tabBtns) do
		local on = (n==name)
		b.TextColor3 = on and T.Primary or T.Muted
		b.BackgroundTransparency = on and 0.15 or 1
		b.BackgroundColor3 = on and T.Elevated or T.Glass
	end
	local paths = {Home="Aether  /  Home", Boost="Aether  /  Boost", Music="Aether  /  Music", AI="Aether  /  AI", Tools="Aether  /  Tools"}
	Crumb.Text = paths[name] or ("Aether  /  "..name)
end

local function addTab(name, icon)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(68,48)
	b.BackgroundTransparency = 1
	b.Text = icon.."\n"..name
	b.TextColor3 = T.Muted
	b.Font = Enum.Font.GothamBold
	b.TextSize = 10
	b.ZIndex = 21
	b.Parent = TabBar
	corner(b, 12)
	tabBtns[name] = b
	b.MouseButton1Click:Connect(function() showPage(name) end)
end
addTab("Home","⌂")
addTab("Boost","⚡")
addTab("Music","♫")
addTab("AI","✦")
addTab("Tools","⚙")
showPage("Home")

----------------------------------------------------------------
-- LOGIN / DESTROY
----------------------------------------------------------------
local function unlock(typ, label, exp)
	Config.KeyType = typ or "free"
	Overlay.Visible = false
	Login.Visible = false
	Main.Visible = true
	CodeL.Text = "@"..LP.Name.." · "..string.upper(typ or "free")
	heroT.Text = string.format("%s · %s\nExpires: %s", label or typ, string.upper(typ or ""), timeLeft(exp))
	boot("Unlocked", 1)
	notify("Welcome", (label or typ).." · "..timeLeft(exp))
	pcall(function() if Boot then Boot:Destroy() end end)
end

local function tryLogin()
	local ok, typ, msg, exp = validateKey(KeyBox.Text)
	if ok then
		Status.Text = msg.." · "..timeLeft(exp)
		Status.TextColor3 = T.Success
		Config.Key = KeyBox.Text
		task.delay(0.18, function() unlock(typ, msg, exp) end)
	else
		Status.Text = tostring(msg)
		Status.TextColor3 = T.Danger
	end
end
LoginBtn.MouseButton1Click:Connect(tryLogin)
KeyBox.FocusLost:Connect(function(e) if e then tryLogin() end end)

local function fullDestroy()
	Alive = false
	panic()
	clearESP()
	clearSword()
	for _,c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
	pcall(function() Gui:Destroy() end)
	pcall(function() Boot:Destroy() end)
	pcall(function() if AimGui then AimGui:Destroy() end end)
	pcall(function() ESPFolder:Destroy() end)
	pcall(function() SwordFolder:Destroy() end)
	pcall(function() ItemFolder:Destroy() end)
	pcall(function() MusicSound:Destroy() end)
	_G.Aether_Engine = nil
end
CloseBtn.MouseButton1Click:Connect(fullDestroy)

_G.Aether_Engine = { Version = VERSION, Destroy = fullDestroy, ValidateKey = validateKey }

boot("Login ready", 0.95)
print("[Aether] v"..VERSION.." Full Premium · key: mtdz")
