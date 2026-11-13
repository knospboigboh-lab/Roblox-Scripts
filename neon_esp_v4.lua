--[[ NEON ESP v4 | Delta Android
     Визуал: ESP, команды, эффекты, мир, меню ]]

if not Drawing then warn("Drawing API is not supported") return end

local genv = (getgenv and getgenv()) or _G
if genv.NeonESP_Unload then pcall(genv.NeonESP_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TeamsService = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local S = {
    ESP = true, Box = true, Names = true, Health = true, Distance = true,
    Skeleton = true, Tracers = false,
    TeamInfo = true, TeamColor = false, TeamCheck = false, TeamPanel = true,
    Walls = true, VisCheck = true, MaxDistance = 2000,
    Glow = true, Pulse = true, Aura = true, Halo = true, Wings = true,
    Rune = true, Sparks = true, AuraSpeed = 1,
    Night = true, Atmos = true, Bloom = true,
    InfoBar = true, TargetCard = true, Keybinds = true, Coords = true,
    Theme = "Purple",
}

local THEMES = {
    Purple = {Color3.fromRGB(190, 80, 255), Color3.fromRGB(80, 200, 255)},
    Cyan   = {Color3.fromRGB(60, 210, 255), Color3.fromRGB(150, 110, 255)},
    Pink   = {Color3.fromRGB(255, 80, 170), Color3.fromRGB(255, 170, 90)},
    Red    = {Color3.fromRGB(255, 70, 90),  Color3.fromRGB(255, 160, 60)},
    Green  = {Color3.fromRGB(70, 255, 140), Color3.fromRGB(60, 190, 255)},
}
local THEME_LIST = {"Purple", "Cyan", "Pink", "Red", "Green"}

local White = Color3.fromRGB(255, 255, 255)
local PANEL = Color3.fromRGB(22, 18, 38)
local MUTED = Color3.fromRGB(150, 145, 178)
local DIM = Color3.fromRGB(115, 115, 135)
local C1, C2 = THEMES.Purple[1], THEMES.Purple[2]
local Theme, Theme2 = C1, C2
local Seq = ColorSequence.new(C1, C2)

local conns = {}
local function connect(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local uiParent = game:GetService("CoreGui")
pcall(function() if gethui then uiParent = gethui() end end)

local Off, U = UDim2.fromOffset, UDim2.new
local CENTER = Enum.TextXAlignment.Center
local RIGHT = Enum.TextXAlignment.Right
local order = 0
local function nxt()
    order += 1
    return order
end

------------------------------------------------------------ Хелперы UI
local function new(class, props, parent)
    local i = Instance.new(class)
    if props then for k, v in pairs(props) do i[k] = v end end
    if parent then i.Parent = parent end
    return i
end

local function corner(inst, r)
    return new("UICorner", {CornerRadius = UDim.new(0, r)}, inst)
end

local gradients, accents = {}, {}
local function grad(inst)
    local g = new("UIGradient", {Color = Seq}, inst)
    gradients[#gradients + 1] = g
    return g
end
local function accent(inst, prop)
    accents[#accents + 1] = {inst, prop}
end

local function stroke(inst, thick, transp, gradient)
    local st = new("UIStroke", {
        Thickness = thick, Transparency = transp, Color = White,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
    if gradient then grad(st) end
    return st
end

local function label(parent, str, pos, size, ts, color, align, bold)
    return new("TextLabel", {
        BackgroundTransparency = 1, Position = pos, Size = size, Text = str,
        TextSize = ts or 13, TextColor3 = color or White,
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextXAlignment = align or Enum.TextXAlignment.Left,
    }, parent)
end

local gui = new("ScreenGui", {Name = "NeonESP_UI", ResetOnSpawn = false, IgnoreGuiInset = true}, uiParent)
local holder = new("Folder", {Name = "NeonHL"}, uiParent)
local fx = new("Folder", {Name = "NeonFX"}, workspace)

local function glass(size, pos)
    local f = new("Frame", {
        Size = size, Position = pos, BackgroundColor3 = Color3.fromRGB(12, 10, 22),
        BackgroundTransparency = 0.12, BorderSizePixel = 0,
    }, gui)
    corner(f, 12)
    stroke(f, 1.2, 0.45, true)
    return f
end

local function hpColor(t)
    return Color3.fromRGB(255 * (1 - t), 255 * t, 60)
end

local function isPress(i)
    return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement
end

local thumbs = {}
local function getThumb(id)
    if thumbs[id] then return thumbs[id] end
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    thumbs[id] = ok and img or ""
    return thumbs[id]
end

------------------------------------------------------------ ESP (Drawing)
local Objects, HL, visCache = {}, {}, {}

local BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SINGLE = {"Tracer", "LabelBg", "Label", "HpBar", "Dist", "TeamTag"}

local function draw(kind, props)
    local o = Drawing.new(kind)
    for k, v in pairs(props) do o[k] = v end
    return o
end

local function createESP(p)
    if p == LocalPlayer or Objects[p] then return end
    local o = {
        Corners = {}, Skeleton = {},
        Tracer = draw("Line", {Thickness = 1.5, Color = C1}),
        LabelBg = draw("Square", {Filled = true, Color = Color3.fromRGB(10, 10, 16), Transparency = 0.6}),
        Label = draw("Text", {Size = 15, Center = true, Outline = true, Color = White}),
        HpBar = draw("Line", {Thickness = 3, Color = Color3.fromRGB(70, 255, 120)}),
        Dist = draw("Text", {Size = 13, Center = true, Outline = true, Color = C1}),
        TeamTag = draw("Text", {Size = 13, Center = true, Outline = true, Color = White}),
    }
    for i = 1, 8 do o.Corners[i] = draw("Line", {Thickness = 2, Color = C1}) end
    for i = 1, #BONES do o.Skeleton[i] = draw("Line", {Thickness = 1.5, Color = C1}) end
    Objects[p] = o
end

local function eachDrawing(o, fn)
    for _, k in ipairs(SINGLE) do pcall(fn, o[k]) end
    for _, d in ipairs(o.Corners) do pcall(fn, d) end
    for _, d in ipairs(o.Skeleton) do pcall(fn, d) end
end

local function hide(o)
    eachDrawing(o, function(d) d.Visible = false end)
end

local function removeESP(p)
    local o = Objects[p]
    if o then
        eachDrawing(o, function(d) d:Remove() end)
        Objects[p] = nil
    end
    if HL[p] then pcall(function() HL[p]:Destroy() end) HL[p] = nil end
    visCache[p] = nil
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
connect(Players.PlayerAdded, createESP)
connect(Players.PlayerRemoving, removeESP)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(player, char, head)
    local c = visCache[player]
    local now = os.clock()
    if c and now - c.t < 0.1 then return c.v end
    local ex = {fx, char}
    if LocalPlayer.Character then ex[#ex + 1] = LocalPlayer.Character end
    rayParams.FilterDescendantsInstances = ex
    local origin = Camera.CFrame.Position
    local hit = workspace:Raycast(origin, head.Position - origin, rayParams)
    local v = (hit == nil)
    visCache[player] = {t = now, v = v}
    return v
end

local function setGlow(p, char, on, col)
    local h = HL[p]
    if on and char then
        if not h or h.Adornee ~= char then
            if h then h:Destroy() end
            h = new("Highlight", {Adornee = char, FillTransparency = 0.8, OutlineTransparency = 0.05}, holder)
            HL[p] = h
        end
        h.FillColor, h.OutlineColor = col, Theme2
        h.DepthMode = S.Walls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        h.Enabled = true
    elseif h then
        h.Enabled = false
    end
end

local function partPos(char, name)
    local part = char:FindFirstChild(name)
    if not part then return nil end
    local v = Camera:WorldToViewportPoint(part.Position)
    if v.Z <= 0 then return nil end
    return Vector2.new(v.X, v.Y)
end

local function setCorners(o, x, y, w, h, col)
    local l = math.min(w, h) * 0.28
    local pts = {
        {Vector2.new(x, y), Vector2.new(x + l, y)}, {Vector2.new(x, y), Vector2.new(x, y + l)},
        {Vector2.new(x + w, y), Vector2.new(x + w - l, y)}, {Vector2.new(x + w, y), Vector2.new(x + w, y + l)},
        {Vector2.new(x, y + h), Vector2.new(x + l, y + h)}, {Vector2.new(x, y + h), Vector2.new(x, y + h - l)},
        {Vector2.new(x + w, y + h), Vector2.new(x + w - l, y + h)}, {Vector2.new(x + w, y + h), Vector2.new(x + w, y + h - l)},
    }
    for i = 1, 8 do
        local c = o.Corners[i]
        c.From, c.To, c.Color, c.Visible = pts[i][1], pts[i][2], col, S.Box
    end
end

------------------------------------------------------------ Мир
local orig = {Clock = Lighting.ClockTime, Amb = Lighting.Ambient, Out = Lighting.OutdoorAmbient}

local sky = Instance.new("Sky")
for _, f in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","SunTextureId","MoonTextureId"}) do
    sky[f] = ""
end
sky.StarCount = 4000
sky.CelestialBodiesShown = true

local atm = new("Atmosphere", {
    Density = 0.3, Offset = 0.25, Glare = 0.4, Haze = 1.2,
    Color = Color3.fromRGB(170, 110, 255), Decay = Color3.fromRGB(90, 40, 160),
})
local cc = new("ColorCorrectionEffect", {
    TintColor = Color3.fromRGB(240, 215, 255), Saturation = 0.15, Contrast = 0.08,
})
local bloom = new("BloomEffect", {Intensity = 0.7, Size = 28, Threshold = 0.85})

local stash = {}
local function stashClass(class, keep)
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA(class) and c ~= keep then
            stash[#stash + 1] = c
            c.Parent = nil
        end
    end
end
local function unstash(class)
    for i = #stash, 1, -1 do
        if stash[i]:IsA(class) then
            stash[i].Parent = Lighting
            table.remove(stash, i)
        end
    end
end

local function applyWorld()
    if S.Night then
        stashClass("Sky", sky)
        sky.Parent = Lighting
        Lighting.ClockTime = 0
        Lighting.Ambient = Color3.fromRGB(70, 40, 110)
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 40, 110)
    else
        sky.Parent = nil
        unstash("Sky")
        Lighting.ClockTime, Lighting.Ambient, Lighting.OutdoorAmbient = orig.Clock, orig.Amb, orig.Out
    end
    if S.Atmos then
        stashClass("Atmosphere", atm)
        atm.Parent = Lighting
    else
        atm.Parent = nil
        unstash("Atmosphere")
    end
    cc.Parent = S.Bloom and Lighting or nil
    bloom.Parent = S.Bloom and Lighting or nil
end

------------------------------------------------------------ Эффекты на персонаже
local orbiters = {}
local function orbiter(kind, radius, height, speed, width, flat)
    local p = new("Part", {
        Size = Vector3.new(0.2, 0.2, 0.2), Anchored = true, CanCollide = false,
        CanQuery = false, CanTouch = false, Transparency = 1,
    }, fx)
    local a0, a1 = Instance.new("Attachment", p), Instance.new("Attachment", p)
    local off = Vector3.new(flat and width / 2 or 0, flat and 0 or width / 2, 0)
    a0.Position, a1.Position = off, -off
    local tr = new("Trail", {
        Attachment0 = a0, Attachment1 = a1, Lifetime = 1.0, LightEmission = 1,
        FaceCamera = false, Enabled = false,
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}),
    }, p)
    orbiters[#orbiters + 1] = {part = p, trail = tr, kind = kind, r = radius, h = height, sp = speed}
end
orbiter("aura", 3.4, 0.25, 2.4, 0.5, true)
orbiter("aura", 4.8, 0.6, -1.8, 0.45, true)
orbiter("aura", 2.2, 1.0, -3.0, 0.4, true)
orbiter("halo", 1.7, 3.2, 3.0, 0.3, false)

-- Крылья
local WING_N = 6
local WING_LEN = {2.6, 3.4, 4.0, 4.2, 3.6, 2.8}
local wings = {}
for _, side in ipairs({-1, 1}) do
    for i = 1, WING_N do
        local len = WING_LEN[i]
        local part = new("Part", {
            Material = Enum.Material.Neon, Anchored = true, CanCollide = false,
            CanQuery = false, CanTouch = false, CastShadow = false,
            Size = Vector3.new(0.45, 0.1, len), Transparency = 1,
        }, fx)
        wings[#wings + 1] = {part = part, side = side, i = i, len = len}
    end
end

-- Руна на земле
local rune = new("Part", {
    Size = Vector3.new(10, 0.1, 10), Transparency = 1, Anchored = true,
    CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
}, fx)
local sg = new("SurfaceGui", {
    Face = Enum.NormalId.Top, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
    CanvasSize = Vector2.new(400, 400), LightInfluence = 0, Brightness = 2, Enabled = true,
}, rune)
local runeStrokes = {}
local function ringFrame(scale, thick, rot, round)
    local f = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = U(0.5, 0, 0.5, 0),
        Size = U(scale, 0, scale, 0), BackgroundTransparency = 1, Rotation = rot,
    }, sg)
    if round then new("UICorner", {CornerRadius = UDim.new(1, 0)}, f) end
    runeStrokes[#runeStrokes + 1] = new("UIStroke", {Thickness = thick, Transparency = 0.1}, f)
    return f
end
ringFrame(0.98, 6, 0, true)
ringFrame(0.80, 3, 0, true)
local sq1 = ringFrame(0.58, 3, 0, false)
local sq2 = ringFrame(0.58, 3, 45, false)
ringFrame(0.30, 4, 0, true)

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true

local sparks
local function updateSparks(root)
    if root and S.Sparks then
        if not sparks or sparks.Parent ~= root then
            if sparks then sparks:Destroy() end
            sparks = new("ParticleEmitter", {
                Texture = "rbxasset://textures/particles/sparkles_main.dds",
                Rate = 22, Lifetime = NumberRange.new(1.5, 2.6), Speed = NumberRange.new(0.5, 2.5),
                SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 2, 0),
                RotSpeed = NumberRange.new(-60, 60), LightEmission = 1,
                Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)}),
                Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
            }, root)
        end
        sparks.Color = Seq
        sparks.Enabled = true
    elseif sparks then
        sparks.Enabled = false
    end
end

local function stepFX(now, char, root)
    if not root then
        for _, ob in ipairs(orbiters) do ob.trail.Enabled = false end
        for _, w in ipairs(wings) do w.part.Transparency = 1 end
        sg.Enabled = false
        updateSparks(nil)
        return
    end

    local gy = root.Position.Y - 3
    groundParams.FilterDescendantsInstances = {char, fx}
    local hit = workspace:Raycast(root.Position, Vector3.new(0, -14, 0), groundParams)
    if hit then gy = hit.Position.Y end

    for _, ob in ipairs(orbiters) do
        local on = (ob.kind == "aura" and S.Aura) or (ob.kind == "halo" and S.Halo)
        ob.trail.Enabled = on and true or false
        if on then
            local a = now * ob.sp * S.AuraSpeed
            local y = (ob.kind == "aura") and (gy + ob.h) or (root.Position.Y + ob.h)
            ob.part.CFrame = CFrame.new(
                root.Position.X + math.cos(a) * ob.r, y, root.Position.Z + math.sin(a) * ob.r
            ) * CFrame.Angles(0, -a, 0)
            ob.trail.Color = Seq
        end
    end

    local cf = root.CFrame
    local flap = math.sin(now * 2.2) * 0.12
    for _, w in ipairs(wings) do
        if S.Wings then
            local a = 0.3 + (w.i - 1) * 0.3 + flap
            local dir = cf:VectorToWorldSpace(Vector3.new(w.side * math.sin(a), math.cos(a), 0.32).Unit)
            local base = cf:PointToWorldSpace(Vector3.new(w.side * 0.45, 0.9, 0.55))
            w.part.CFrame = CFrame.lookAt(base + dir * (w.len / 2), base + dir * w.len)
            w.part.Color = Theme:Lerp(Theme2, w.i / WING_N)
            w.part.Transparency = 0.3
        else
            w.part.Transparency = 1
        end
    end

    sg.Enabled = S.Rune
    if S.Rune then
        local s = 10 + math.sin(now * 2) * 0.5
        rune.Size = Vector3.new(s, 0.1, s)
        rune.CFrame = CFrame.new(root.Position.X, gy + 0.08, root.Position.Z)
        for _, st in ipairs(runeStrokes) do st.Color = Theme end
        sq1.Rotation = now * 40
        sq2.Rotation = 45 - now * 30
    end

    updateSparks(root)
end

------------------------------------------------------------ HUD
local infoBar = glass(Off(330, 32), U(0.5, -165, 0, 8))
local infoText = label(infoBar, "", U(), U(1, 0, 1, 0), 12, White, CENTER, true)

local tcard = glass(Off(250, 80), U(1, -262, 0, 52))
local avatar = new("ImageLabel", {
    Size = Off(46, 46), Position = Off(10, 17), BackgroundColor3 = Color3.fromRGB(50, 40, 70), BorderSizePixel = 0,
}, tcard)
corner(avatar, 23)
local tName = label(tcard, "", Off(64, 9), Off(120, 20), 14, White, nil, true)
local tDist = label(tcard, "", Off(64, 29), Off(120, 16), 12, Color3.fromRGB(190, 190, 215))
local tTeam = label(tcard, "", Off(64, 47), Off(120, 16), 12, White, nil, true)
local ring = new("Frame", {Size = Off(42, 42), Position = U(1, -54, 0, 19), BackgroundTransparency = 1}, tcard)
corner(ring, 21)
local ringStroke = new("UIStroke", {Thickness = 4, Color = White}, ring)
local ringText = label(ring, "100", U(), U(1, 0, 1, 0), 12, White, CENTER, true)

local keys = glass(Off(250, 56), U(1, -262, 0, 140))
label(keys, "Keybinds", Off(12, 5), Off(120, 18), 13, White, nil, true)
label(keys, "Menu", Off(12, 30), Off(60, 18), 12, MUTED)
local keyTxt = label(keys, "RIGHT_SHIFT / NL", Off(70, 30), U(1, -82, 0, 18), 12, C1, RIGHT, true)
accent(keyTxt, "TextColor3")

local teamsP = glass(Off(250, 80), U(1, -262, 0, 204))
label(teamsP, "Teams", Off(12, 6), Off(120, 18), 13, White, nil, true)
local teamsTxt = new("TextLabel", {
    BackgroundTransparency = 1, Position = Off(12, 28), Size = Off(226, 16), RichText = true,
    Text = "", TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = White,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, teamsP)
local legend = label(teamsP, "Bright = visible, dim = behind wall", Off(12, 50), Off(226, 14), 10, MUTED)

local coords = glass(Off(200, 28), U(0.5, -100, 1, -40))
local coordText = label(coords, "", U(), U(1, 0, 1, 0), 12, White, CENTER)

local function updateTeams()
    local counts = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        local k = pl.Team or false
        counts[k] = (counts[k] or 0) + 1
    end
    local lines, n = {}, 0
    for _, t in ipairs(TeamsService:GetTeams()) do
        local cnt = counts[t]
        if cnt and cnt > 0 then
            n += 1
            if n <= 6 then
                local me = (LocalPlayer.Team == t) and "  (you)" or ""
                local nm = (t.Name:gsub("[<>&]", ""))
                lines[#lines + 1] = string.format('<font color="#%s">%s</font>  <b>%d</b>%s',
                    t.TeamColor.Color:ToHex(), nm, cnt, me)
            end
        end
    end
    if counts[false] then
        n += 1
        lines[#lines + 1] = string.format('<font color="#aaaaaa">No team</font>  <b>%d</b>', counts[false])
    end
    if #lines == 0 then lines[1] = "No players" end
    teamsTxt.Text = table.concat(lines, "\n")
    local rows = #lines
    teamsTxt.Size = Off(226, rows * 16)
    legend.Visible = S.VisCheck
    legend.Position = Off(12, 30 + rows * 16)
    teamsP.Size = Off(250, 36 + rows * 16 + (S.VisCheck and 18 or 0))
end

------------------------------------------------------------ Меню
local MW, MH = 620, 360
local menu = glass(Off(MW, MH), U(0.5, 0, 0.5, 0))
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Visible = false
menu.ClipsDescendants = true
local menuScale = new("UIScale", {}, menu)

-- созвездия на фоне
local bg = new("Frame", {Size = U(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0}, menu)
local stars, lines, LINE_N = {}, {}, 28
for i = 1, 18 do
    local d = new("Frame", {
        Size = Off(3, 3), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundTransparency = 0.3,
    }, bg)
    corner(d, 2)
    stars[i] = {
        x = math.random(0, MW), y = math.random(0, MH),
        vx = (math.random() - 0.5) * 14, vy = (math.random() - 0.5) * 14, f = d,
    }
end
for i = 1, LINE_N do
    lines[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}, bg)
end
local function stepStars(dt)
    for _, s in ipairs(stars) do
        s.x += s.vx * dt
        s.y += s.vy * dt
        if s.x < 0 or s.x > MW then s.vx = -s.vx end
        if s.y < 0 or s.y > MH then s.vy = -s.vy end
        s.f.Position = Off(s.x, s.y)
        s.f.BackgroundColor3 = Theme
    end
    local n = 0
    for i = 1, #stars do
        for j = i + 1, #stars do
            if n < LINE_N then
                local a, b = stars[i], stars[j]
                local dx, dy = b.x - a.x, b.y - a.y
                local d = math.sqrt(dx * dx + dy * dy)
                if d < 110 then
                    n += 1
                    local l = lines[n]
                    l.Visible = true
                    l.Size = Off(d, 1)
                    l.Position = Off((a.x + b.x) / 2, (a.y + b.y) / 2)
                    l.Rotation = math.deg(math.atan2(dy, dx))
                    l.BackgroundTransparency = 0.6 + 0.4 * (d / 110)
                    l.BackgroundColor3 = Theme
                end
            end
        end
    end
    for k = n + 1, LINE_N do lines[k].Visible = false end
end

-- боковая панель
local sidebar = new("Frame", {
    Position = Off(8, 8), Size = Off(142, MH - 16), BackgroundColor3 = PANEL,
    BackgroundTransparency = 0.3, BorderSizePixel = 0,
}, menu)
corner(sidebar, 10)
stroke(sidebar, 1, 0.9)
local logo = label(sidebar, "NEON", Off(14, 8), Off(110, 28), 24, White, nil, true)
grad(logo)
label(sidebar, "ESP  v4", Off(15, 35), Off(110, 14), 10, MUTED)

-- перетаскивание (создаём до кнопок, чтобы не перекрывать их)
local dragZone = new("Frame", {Size = U(1, -44, 0, 44), BackgroundTransparency = 1, Active = true}, menu)
do
    local dragging, start, startPos
    dragZone.InputBegan:Connect(function(i)
        if isPress(i) then dragging, start, startPos = true, i.Position, menu.Position end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and isMove(i) then
            local d = i.Position - start
            menu.Position = U(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
end

local headerTitle = label(menu, "ESP", Off(166, 8), Off(260, 24), 18, White, nil, true)
local headerSub = label(menu, "", Off(166, 29), Off(300, 14), 11, MUTED)

local pages, navBtns, curTab = {}, {}, "ESP"
local TAB_INFO = {
    ESP = "Boxes, labels, teams and visibility",
    Effects = "Aura, wings, rune and glow",
    World = "Sky and lighting",
    HUD = "On-screen overlay",
    Settings = "Theme and script",
}

local selectTab
local function navItem(name, y)
    local b = new("TextButton", {
        Position = Off(8, y), Size = Off(126, 30), BackgroundColor3 = Color3.fromRGB(80, 50, 140),
        BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
    }, sidebar)
    corner(b, 8)
    local ind = new("Frame", {Position = Off(0, 7), Size = Off(3, 16), BackgroundColor3 = White, BorderSizePixel = 0, Visible = false}, b)
    corner(ind, 2)
    grad(ind)
    local dot = new("Frame", {Position = Off(12, 11), Size = Off(8, 8), BackgroundColor3 = MUTED, BorderSizePixel = 0}, b)
    corner(dot, 4)
    local t = label(b, name, Off(28, 0), U(1, -34, 1, 0), 13, MUTED, nil, true)
    navBtns[name] = {b = b, ind = ind, dot = dot, t = t}
    b.MouseButton1Click:Connect(function() selectTab(name) end)
end

label(sidebar, "VISUALS", Off(14, 58), Off(100, 14), 10, MUTED, nil, true)
navItem("ESP", 74)
navItem("Effects", 108)
navItem("World", 142)
label(sidebar, "INTERFACE", Off(14, 182), Off(100, 14), 10, MUTED, nil, true)
navItem("HUD", 198)
navItem("Settings", 232)

-- профиль внизу
local prof = new("Frame", {
    Position = Off(8, MH - 16 - 54), Size = Off(126, 44), BackgroundColor3 = Color3.fromRGB(34, 26, 58),
    BackgroundTransparency = 0.25, BorderSizePixel = 0,
}, sidebar)
corner(prof, 10)
local pav = new("ImageLabel", {
    Size = Off(30, 30), Position = Off(7, 7), BackgroundColor3 = Color3.fromRGB(50, 40, 70), BorderSizePixel = 0,
}, prof)
corner(pav, 15)
task.spawn(function() pav.Image = getThumb(LocalPlayer.UserId) end)
local pn = label(prof, LocalPlayer.DisplayName, Off(43, 6), Off(78, 18), 12, White, nil, true)
pn.TextTruncate = Enum.TextTruncate.AtEnd
label(prof, "Visual only", Off(43, 23), Off(78, 14), 10, MUTED)

-- страницы и карточки
local function newPage(name)
    local sf = new("ScrollingFrame", {
        Position = Off(166, 50), Size = U(1, -176, 1, -60), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = U(), Visible = false,
    }, menu)
    accent(sf, "ScrollBarImageColor3")
    local colL = new("Frame", {BackgroundTransparency = 1, Size = U(0.5, -4, 1, 0)}, sf)
    local colR = new("Frame", {BackgroundTransparency = 1, Size = U(0.5, -4, 1, 0), Position = U(0.5, 4, 0, 0)}, sf)
    local llL = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, colL)
    local llR = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, colR)
    local function fit()
        sf.CanvasSize = Off(0, math.max(llL.AbsoluteContentSize.Y, llR.AbsoluteContentSize.Y) + 6)
    end
    llL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
    llR:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
    pages[name] = {sf = sf, L = colL, R = colR, fit = fit}
    return pages[name]
end

local function card(col, title, sub)
    local f = new("Frame", {
        Size = U(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = PANEL,
        BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = nxt(),
    }, col)
    corner(f, 10)
    stroke(f, 1, 0.88)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
    }, f)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
    local h = new("Frame", {Size = U(1, 0, 0, sub and 34 or 22), BackgroundTransparency = 1, LayoutOrder = nxt()}, f)
    label(h, title, Off(0, 0), U(1, 0, 0, 16), 14, White, nil, true)
    if sub then label(h, sub, Off(0, 17), U(1, 0, 0, 14), 10, MUTED) end
    return f
end

local function row(c, h)
    return new("Frame", {Size = U(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = nxt()}, c)
end

local function addToggle(c, name, key, cb)
    local r = row(c, 26)
    label(r, name, Off(0, 0), U(1, -46, 1, 0), 12, White)
    local sw = new("TextButton", {
        Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        Size = Off(36, 18), Position = U(1, -36, 0.5, -9),
    }, r)
    corner(sw, 9)
    local g = grad(sw)
    local knob = new("Frame", {Size = Off(12, 12), BackgroundColor3 = White, BorderSizePixel = 0}, sw)
    corner(knob, 6)
    local function refresh(anim)
        local on = S[key]
        sw.BackgroundColor3 = on and White or Color3.fromRGB(46, 40, 66)
        g.Enabled = on
        local pos = Off(on and 21 or 3, 3)
        if anim then
            TweenService:Create(knob, TweenInfo.new(0.14), {Position = pos}):Play()
        else
            knob.Position = pos
        end
    end
    refresh(false)
    sw.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        refresh(true)
        if cb then cb() end
    end)
end

local function addSlider(c, name, key, min, max, step)
    local sf = c.Parent.Parent
    local r = row(c, 38)
    label(r, name, Off(0, 0), U(1, -60, 0, 16), 12, White)
    local val = label(r, "", U(1, -60, 0, 0), Off(60, 16), 11, MUTED, RIGHT)
    local bar = new("TextButton", {
        Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = Off(0, 24),
        Size = U(1, 0, 0, 8), BackgroundColor3 = Color3.fromRGB(40, 34, 60),
    }, r)
    corner(bar, 4)
    local fill = new("Frame", {BackgroundColor3 = White, BorderSizePixel = 0, Size = U(0, 0, 1, 0)}, bar)
    corner(fill, 4)
    grad(fill)
    local knob = new("Frame", {
        Size = Off(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = U(0, 0, 0.5, 0),
        BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 2,
    }, bar)
    corner(knob, 6)
    local function refresh()
        local t = (S[key] - min) / (max - min)
        fill.Size = U(t, 0, 1, 0)
        knob.Position = U(t, 0, 0.5, 0)
        val.Text = tostring(S[key])
    end
    refresh()
    local dragging = false
    local function setFrom(x)
        local t = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local v = math.floor((min + (max - min) * t) / step + 0.5) * step
        S[key] = tonumber(string.format("%.2f", math.clamp(v, min, max)))
        refresh()
    end
    bar.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging = true
            pcall(function() sf.ScrollingEnabled = false end)
            setFrom(i.Position.X)
        end
    end)
    connect(UIS.InputChanged, function(i) if dragging and isMove(i) then setFrom(i.Position.X) end end)
    connect(UIS.InputEnded, function(i)
        if isPress(i) and dragging then
            dragging = false
            pcall(function() sf.ScrollingEnabled = true end)
        end
    end)
end

local function addChoice(c, name, key, list, cb)
    local r = row(c, 28)
    label(r, name, Off(0, 0), U(1, -96, 1, 0), 12, White)
    local b = new("TextButton", {
        Size = Off(90, 22), Position = U(1, -90, 0.5, -11), BackgroundColor3 = Color3.fromRGB(40, 34, 62),
        BorderSizePixel = 0, Text = "", AutoButtonColor = true,
    }, r)
    corner(b, 6)
    stroke(b, 1, 0.8)
    local t = label(b, "", U(), U(1, 0, 1, 0), 11, White, CENTER, true)
    local function refresh() t.Text = tostring(S[key]) .. "  >" end
    refresh()
    b.MouseButton1Click:Connect(function()
        local idx = table.find(list, S[key]) or 0
        S[key] = list[idx % #list + 1]
        refresh()
        if cb then cb() end
    end)
end

local function addButton(c, name, cb)
    local holderF = new("Frame", {Size = U(1, 0, 0, 30), BackgroundColor3 = White, BorderSizePixel = 0, LayoutOrder = nxt()}, c)
    corner(holderF, 8)
    grad(holderF)
    local b = new("TextButton", {
        Size = U(1, 0, 1, 0), BackgroundTransparency = 1, Text = name, TextColor3 = White,
        TextSize = 12, Font = Enum.Font.GothamBold,
    }, holderF)
    b.MouseButton1Click:Connect(cb)
end

local function addNote(c, str)
    local l = label(c, str, U(), U(1, 0, 0, 30), 10, MUTED)
    l.TextWrapped = true
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.LayoutOrder = nxt()
end

-- превью в стиле Yanderov
local PV = {corners = {}, skel = {}}
local function buildPreview(c)
    local f = new("Frame", {
        Size = U(1, 0, 0, 160), BackgroundColor3 = Color3.fromRGB(10, 8, 18), BackgroundTransparency = 0.05,
        BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = nxt(),
    }, c)
    corner(f, 8)

    PV.glow = new("Frame", {
        Position = U(0.5, -48, 0, 26), Size = Off(96, 124), BackgroundColor3 = C1,
        BackgroundTransparency = 0.8, BorderSizePixel = 0,
    }, f)
    corner(PV.glow, 48)
    accent(PV.glow, "BackgroundColor3")

    local function part(x, y, w, h, r)
        local p = new("Frame", {
            Position = U(0.5, x, 0, y), Size = Off(w, h),
            BackgroundColor3 = Color3.fromRGB(185, 185, 200), BorderSizePixel = 0,
        }, f)
        corner(p, r)
        return p
    end
    part(-9, 44, 18, 18, 9)
    part(-13, 64, 26, 34, 4)
    part(-20, 64, 6, 32, 3)
    part(14, 64, 6, 32, 3)
    part(-12, 99, 11, 36, 3)
    part(1, 99, 11, 36, 3)

    local function bar(list, x, y, w, h)
        local b = new("Frame", {Position = U(0.5, x, 0, y), Size = Off(w, h), BackgroundColor3 = C1, BorderSizePixel = 0}, f)
        accent(b, "BackgroundColor3")
        list[#list + 1] = b
    end
    bar(PV.skel, 0, 53, 1, 48)
    bar(PV.skel, -17, 66, 34, 1)
    bar(PV.skel, -17, 66, 1, 30)
    bar(PV.skel, 16, 66, 1, 30)
    bar(PV.skel, -6, 99, 1, 36)
    bar(PV.skel, 6, 99, 1, 36)

    local L, T, R, B, len = -32, 36, 32, 140, 14
    bar(PV.corners, L, T, len, 2)
    bar(PV.corners, L, T, 2, len)
    bar(PV.corners, R - len, T, len, 2)
    bar(PV.corners, R - 2, T, 2, len)
    bar(PV.corners, L, B - 2, len, 2)
    bar(PV.corners, L, B - len, 2, len)
    bar(PV.corners, R - len, B - 2, len, 2)
    bar(PV.corners, R - 2, B - len, 2, len)

    PV.nameBg = new("Frame", {
        Position = U(0.5, -58, 0, 6), Size = Off(116, 18), BackgroundColor3 = Color3.fromRGB(8, 8, 14),
        BackgroundTransparency = 0.35, BorderSizePixel = 0,
    }, f)
    PV.name = label(PV.nameBg, "Player | 100 HP", U(), U(1, 0, 1, 0), 11, White, CENTER, true)
    PV.hp = new("Frame", {
        Position = U(0.5, -58, 0, 25), Size = Off(116, 3), BackgroundColor3 = Color3.fromRGB(70, 255, 120), BorderSizePixel = 0,
    }, f)
    PV.dist = label(f, "42 studs", U(0.5, -40, 0, 142), Off(80, 14), 10, C1, CENTER)
    accent(PV.dist, "TextColor3")
    PV.team = label(f, "[RED]", Off(8, 6), Off(50, 14), 10, Color3.fromRGB(255, 90, 90), nil, true)
end

local function stepPreview(now)
    PV.glow.Visible = S.Glow
    for _, x in ipairs(PV.corners) do x.Visible = S.Box end
    for _, x in ipairs(PV.skel) do x.Visible = S.Skeleton end
    PV.nameBg.Visible = S.Names
    PV.hp.Visible = S.Health
    PV.dist.Visible = S.Distance
    PV.team.Visible = S.TeamInfo
    local t = 0.5 + 0.5 * math.sin(now * 1.2)
    PV.hp.Size = Off(116 * t, 3)
    PV.hp.BackgroundColor3 = hpColor(t)
    PV.name.Text = "Player | " .. math.floor(100 * t) .. " HP"
end

-- наполнение страниц
local pg = newPage("ESP")
local c1 = card(pg.L, "Player ESP", "Boxes, labels and health")
addToggle(c1, "ESP", "ESP")
addToggle(c1, "Corner box", "Box")
addToggle(c1, "Name | HP", "Names")
addToggle(c1, "Health bar", "Health")
addToggle(c1, "Distance", "Distance")
addToggle(c1, "Skeleton", "Skeleton")
addToggle(c1, "Tracers", "Tracers")
local c2 = card(pg.L, "Teams", "Who they play for")
addToggle(c2, "Team tag [NAME]", "TeamInfo")
addToggle(c2, "Use team colors", "TeamColor")
addToggle(c2, "Hide teammates", "TeamCheck")
local c3 = card(pg.R, "Preview", "Live look of your settings")
buildPreview(c3)
local c4 = card(pg.R, "Visibility", "Walls and range")
addToggle(c4, "Through walls", "Walls")
addToggle(c4, "Dim behind walls", "VisCheck")
addSlider(c4, "Max distance", "MaxDistance", 200, 5000, 100)

pg = newPage("Effects")
local c5 = card(pg.L, "Character FX", "Around your avatar")
addToggle(c5, "Neon rings", "Aura")
addToggle(c5, "Halo", "Halo")
addToggle(c5, "Wings", "Wings")
addToggle(c5, "Ground rune", "Rune")
addToggle(c5, "Sparks", "Sparks")
local c6 = card(pg.R, "Glow", "Players and colors")
addToggle(c6, "Player glow", "Glow")
addToggle(c6, "Color pulse", "Pulse")
addSlider(c6, "Ring speed", "AuraSpeed", 0.2, 3, 0.1)

pg = newPage("World")
local c7 = card(pg.L, "Sky", "Night and atmosphere")
addToggle(c7, "Night + stars", "Night", applyWorld)
addToggle(c7, "Purple atmosphere", "Atmos", applyWorld)
local c8 = card(pg.R, "Post FX", "Bloom and tint")
addToggle(c8, "Bloom + tint", "Bloom", applyWorld)

pg = newPage("HUD")
local c9 = card(pg.L, "Overlay", "On-screen panels")
addToggle(c9, "Top bar", "InfoBar")
addToggle(c9, "Target card", "TargetCard")
addToggle(c9, "Keybinds", "Keybinds")
addToggle(c9, "Coordinates", "Coords")
addToggle(c9, "Teams list", "TeamPanel")

pg = newPage("Settings")
local c10 = card(pg.L, "Appearance", "Colors of everything")
addChoice(c10, "Theme", "Theme", THEME_LIST, function()
    C1, C2 = THEMES[S.Theme][1], THEMES[S.Theme][2]
end)
local c11 = card(pg.R, "Script", "Manage")
addButton(c11, "Unload script", function()
    if genv.NeonESP_Unload then genv.NeonESP_Unload() end
end)
addNote(c11, "Menu: NL button or RIGHT SHIFT")

selectTab = function(name)
    curTab = name
    for n, p in pairs(pages) do p.sf.Visible = (n == name) end
    for n, nb in pairs(navBtns) do
        local on = (n == name)
        nb.b.BackgroundTransparency = on and 0.55 or 1
        nb.ind.Visible = on
        nb.t.TextColor3 = on and White or MUTED
        nb.dot.BackgroundColor3 = on and White or MUTED
    end
    headerTitle.Text = name
    headerSub.Text = TAB_INFO[name] or ""
    pages[name].fit()
end

local function setMenu(v)
    if v then
        menuScale.Scale = 0.9
        menu.Visible = true
        TweenService:Create(menuScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        task.defer(function() if pages[curTab] then pages[curTab].fit() end end)
    else
        menu.Visible = false
    end
end

local closeBtn = new("TextButton", {
    Size = Off(26, 26), Position = U(1, -34, 0, 8), BackgroundColor3 = Color3.fromRGB(110, 35, 70),
    BackgroundTransparency = 0.25, BorderSizePixel = 0, Text = "X", TextColor3 = White,
    TextSize = 12, Font = Enum.Font.GothamBold,
}, menu)
corner(closeBtn, 13)
closeBtn.MouseButton1Click:Connect(function() setMenu(false) end)

-- кнопка NL для телефона
local nl = new("TextButton", {
    Size = Off(44, 44), Position = Off(12, 56), BackgroundColor3 = Color3.fromRGB(12, 12, 24),
    BorderSizePixel = 0, Text = "NL", TextColor3 = C2, TextSize = 17, Font = Enum.Font.GothamBold,
}, gui)
corner(nl, 12)
stroke(nl, 1.6, 0.1, true)
accent(nl, "TextColor3")
nl.MouseButton1Click:Connect(function() setMenu(not menu.Visible) end)