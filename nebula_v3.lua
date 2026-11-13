--[[
   N E B U L A   |   visuals v3
   Только визуальные эффекты (ESP, chams, эффекты, мир, HUD).
   Открыть/закрыть: кнопка "N" или RightShift
]]

-- ===================================================================
--  SERVICES / STATE
-- ===================================================================
local P,UIS,RS,L,H,TS,CG=game:GetService("Players"),game:GetService("UserInputService"),game:GetService("RunService"),game:GetService("Lighting"),game:GetService("HttpService"),game:GetService("TweenService"),game:GetService("CoreGui")
local lp,cam=P.LocalPlayer,workspace.CurrentCamera
local par=(gethui and gethui()) or CG
pcall(function() if getgenv and getgenv().NEBULA_UNLOAD then getgenv().NEBULA_UNLOAD() end end)
pcall(function() local o=par:FindFirstChild("Nebula") if o then o:Destroy() end end)

local F,SET,DEF,C,TH,E,RB={}, {}, {}, {}, {}, {}, {}
local WW,WH=640,350
local TXT,DIM=Color3.fromRGB(236,236,244),Color3.fromRGB(128,128,146)
local BG0,BG1,BG2=Color3.fromRGB(11,11,15),Color3.fromRGB(19,19,25),Color3.fromRGB(30,30,39)
local A1,A2=Color3.fromRGB(150,110,255),Color3.fromRGB(110,160,255)
local hasD=pcall(function() local l=Drawing.new("Line") l:Remove() end)
local O={fov=cam.FieldOfView}
local AP,LA={}, {}
local open=false

-- ===================================================================
--  HELPERS
-- ===================================================================
local function N(c,p,pr) local o=Instance.new(c) if p then for k,v in pairs(p) do o[k]=v end end if pr then o.Parent=pr end return o end
local function corner(o,r) return N("UICorner",{CornerRadius=UDim.new(0,r or 8)},o) end
local function stroke(o,c,t,tr) return N("UIStroke",{Color=c or Color3.new(1,1,1),Thickness=t or 1,Transparency=tr or .9,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o) end
local function T(p,pr)
  p.BackgroundTransparency=1
  if not p.Font then p.Font=Enum.Font.Gotham end
  if not p.TextColor3 then p.TextColor3=TXT end
  if not p.TextSize then p.TextSize=12 end
  return N("TextLabel",p,pr)
end
local function tw(o,t,pr,st,dr) local x=TS:Create(o,TweenInfo.new(t,st or Enum.EasingStyle.Quint,dr or Enum.EasingDirection.Out),pr) x:Play() return x end
local function con(s,f) local c=s:Connect(f) C[#C+1]=c return c end
local function isP(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
local function isM(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end
local function shift(c) local h,s=Color3.toHSV(c) return Color3.fromHSV((h+.09)%1,math.clamp(s*.85,0,1),1) end
local function onTheme(fn) TH[#TH+1]=fn pcall(fn) end
local function applyTheme() for _,f in ipairs(TH) do pcall(f) end end
local function setAccent(c) A1=c A2=shift(c) applyTheme() end
local warned={}
local function safe(n,fn,...) local ok,err=pcall(fn,...) if not ok and not warned[n] then warned[n]=true warn("[Nebula] "..n..": "..tostring(err)) end end
local function hex(c) return string.format("#%02x%02x%02x",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255)) end

-- ===================================================================
--  ROOT GUI
-- ===================================================================
local ui=N("ScreenGui",{Name="Nebula",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=100},par)
local esp=N("Folder",{Name="esp"},ui)
local hud=N("Frame",{Name="hud",Size=UDim2.fromScale(1,1),BackgroundTransparency=1},ui)
local root=N("Frame",{Name="root",Size=UDim2.fromOffset(WW,WH),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Visible=false},ui)
local us=N("UIScale",{},root)

-- "3D" depth: stacked soft shadows + animated gradient border + aura glow
local depth={}
for i=1,4 do
  depth[i]=N("Frame",{Size=UDim2.new(1,i*10,1,i*10),Position=UDim2.fromOffset(-i*5,-i*5+12),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.5+i*.1,BorderSizePixel=0,ZIndex=0},root)
  corner(depth[i],14+i*4)
end
local aura=N("Frame",{Size=UDim2.new(1,26,1,26),Position=UDim2.fromOffset(-13,-13),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.88,BorderSizePixel=0,ZIndex=0},root) corner(aura,24)
local auraG=N("UIGradient",{},aura)
local bord=N("Frame",{Size=UDim2.new(1,2,1,2),Position=UDim2.fromOffset(-1,-1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=1},root) corner(bord,13)
local bordG=N("UIGradient",{},bord)
onTheme(function()
  local s=ColorSequence.new({ColorSequenceKeypoint.new(0,A1),ColorSequenceKeypoint.new(.5,A2),ColorSequenceKeypoint.new(1,A1)})
  auraG.Color=s bordG.Color=s
end)
local win=N("CanvasGroup",{Name="win",Size=UDim2.fromScale(1,1),BackgroundColor3=BG0,BackgroundTransparency=.03,BorderSizePixel=0,ZIndex=3,GroupTransparency=1},root) corner(win,12)

-- constellation background (like yanderov style)
local cv=N("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=1,ClipsDescendants=true},win)
local PT,LN,NP={}, {},12
for i=1,NP do
  local d=N("Frame",{Size=UDim2.fromOffset(3,3),AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,BackgroundTransparency=.3},cv) corner(d,2)
  PT[i]={x=math.random()*WW,y=math.random()*WH,vx=(math.random()-.5)*16,vy=(math.random()-.5)*16,d=d}
end
for i=1,NP-1 do for j=i+1,NP do
  LN[#LN+1]={i,j,N("Frame",{AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,Size=UDim2.fromOffset(0,1),Visible=false},cv)}
end end
onTheme(function() for _,p in ipairs(PT) do p.d.BackgroundColor3=A1 end for _,l in ipairs(LN) do l[3].BackgroundColor3=A1 end end)
local ox,oy=0,0
local function stepParticles(dt)
  for _,p in ipairs(PT) do
    p.x=p.x+p.vx*dt p.y=p.y+p.vy*dt
    if p.x<0 or p.x>WW then p.vx=-p.vx end
    if p.y<0 or p.y>WH then p.vy=-p.vy end
    p.d.Position=UDim2.fromOffset(p.x+ox,p.y+oy)
  end
  for _,l in ipairs(LN) do
    local a,b=PT[l[1]],PT[l[2]]
    local dx,dy=b.x-a.x,b.y-a.y
    local d=math.sqrt(dx*dx+dy*dy)
    local f=l[3]
    if d<125 then
