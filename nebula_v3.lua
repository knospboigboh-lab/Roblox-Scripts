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
      f.Visible=true f.BackgroundTransparency=.5+.5*(d/125)
      f.Size=UDim2.fromOffset(d,1) f.Position=UDim2.fromOffset((a.x+b.x)/2+ox,(a.y+b.y)/2+oy) f.Rotation=math.deg(math.atan2(dy,dx))
    else f.Visible=false end
  end
end

-- ===================================================================
--  SIDEBAR (3D logo + tabs + user card)
-- ===================================================================
local side=N("Frame",{Size=UDim2.new(0,150,1,0),BackgroundColor3=BG1,BackgroundTransparency=.35,BorderSizePixel=0,ZIndex=2},win)
N("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.93,BorderSizePixel=0},side)

local vfl=N("ViewportFrame",{Position=UDim2.fromOffset(10,8),Size=UDim2.fromOffset(46,46),BackgroundTransparency=1,Ambient=Color3.fromRGB(200,200,230),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-1,-1,-1)},side)
local vcl=N("Camera",{FieldOfView=55},vfl) vfl.CurrentCamera=vcl
vcl.CFrame=CFrame.lookAt(Vector3.new(0,.2,5.2),Vector3.new(0,0,0))
local function gpart(sz,mat) return N("Part",{Size=sz,Material=mat or Enum.Material.Neon,Anchored=true,CanCollide=false,CastShadow=false},vfl) end
local gem,gem2=gpart(Vector3.new(1.7,1.7,1.7)),gpart(Vector3.new(.85,.85,.85))
local gorb={}
for i=1,8 do gorb[i]=gpart(Vector3.new(.2,.2,.2)) gorb[i].Shape=Enum.PartType.Ball end
onTheme(function() gem.Color=A1 gem2.Color=Color3.new(1,1,1) for i,o in ipairs(gorb) do o.Color=(i%2==0) and A1 or A2 end end)
local function logoStep(t)
  gem.CFrame=CFrame.Angles(t*.9,t*1.2,math.rad(20))
  gem2.CFrame=CFrame.Angles(-t*1.3,t*.7,0)
  for i,o in ipairs(gorb) do
    local a=t*1.7+i*math.pi/4
    o.CFrame=CFrame.new(math.cos(a)*1.5,math.sin(a*2)*.4,math.sin(a)*1.5)
  end
end

local ttl=T({Text="N E B U L A",Font=Enum.Font.GothamBlack,TextSize=16,Position=UDim2.fromOffset(62,12),Size=UDim2.new(1,-66,0,20),TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.new(1,1,1)},side)
local ttlG=N("UIGradient",{},ttl)
onTheme(function() ttlG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,A1),ColorSequenceKeypoint.new(.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,A2)}) end)
T({Text="visuals  |  v3",TextSize=10,TextColor3=DIM,Position=UDim2.fromOffset(62,32),Size=UDim2.new(1,-66,0,12),TextXAlignment=Enum.TextXAlignment.Left},side)

local tabList=N("Frame",{Position=UDim2.fromOffset(8,64),Size=UDim2.new(1,-16,1,-134),BackgroundTransparency=1},side)
N("UIListLayout",{Padding=UDim.new(0,4)},tabList)

local ucard=N("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,8,1,-8),Size=UDim2.new(1,-16,0,46),BackgroundColor3=BG2,BackgroundTransparency=.3},side) corner(ucard,10) stroke(ucard)
local av=N("ImageLabel",{Position=UDim2.fromOffset(8,7),Size=UDim2.fromOffset(32,32),BackgroundColor3=BG1,BorderSizePixel=0},ucard) corner(av,16)
task.spawn(function()
  local ok,img=pcall(function() return P:GetUserThumbnailAsync(lp.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)
  if ok and av.Parent then av.Image=img end
end)
T({Text=lp.DisplayName,Font=Enum.Font.GothamBold,TextSize=12,Position=UDim2.fromOffset(46,7),Size=UDim2.new(1,-50,0,16),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},ucard)
T({Text="visuals only",TextSize=10,TextColor3=DIM,Position=UDim2.fromOffset(46,23),Size=UDim2.new(1,-50,0,12),TextXAlignment=Enum.TextXAlignment.Left},ucard)

-- ===================================================================
--  MAIN AREA / TABS
-- ===================================================================
local main=N("Frame",{Position=UDim2.fromOffset(150,0),Size=UDim2.new(1,-150,1,0),BackgroundTransparency=1,ZIndex=2},win)
local head=N("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1},main)
local title=T({Text="ESP",Font=Enum.Font.GothamBold,TextSize=16,Position=UDim2.fromOffset(16,0),Size=UDim2.new(0,150,1,0),TextXAlignment=Enum.TextXAlignment.Left},head)
local sb=N("TextBox",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-46,.5,0),Size=UDim2.fromOffset(140,24),BackgroundColor3=BG2,BackgroundTransparency=.2,Text="",PlaceholderText="Search...",PlaceholderColor3=DIM,TextColor3=TXT,Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=false},head) corner(sb,7) stroke(sb)
local xb=N("TextButton",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-12,.5,0),Size=UDim2.fromOffset(26,24),BackgroundColor3=BG2,BackgroundTransparency=.2,Text="x",TextColor3=DIM,Font=Enum.Font.GothamBold,TextSize=13,AutoButtonColor=false},head) corner(xb,7) stroke(xb)
local content=N("Frame",{Position=UDim2.fromOffset(12,46),Size=UDim2.new(1,-24,1,-56),BackgroundTransparency=1,ClipsDescendants=true},main)

local pages,tabs={}, {}
local curPage
local function filter()
  local q=sb.Text:lower()
  if not curPage then return end
  for _,cd in ipairs(curPage.cards) do
    local any=false
    for _,rw in ipairs(cd.rows) do
      local m=(q=="" or rw.name:lower():find(q,1,true)~=nil)
      rw.f.Visible=m if m then any=true end
    end
    cd.f.Visible=(q=="") or any
  end
end
sb:GetPropertyChangedSignal("Text"):Connect(filter)
local PV={on=false}
local function selectTab(i)
  for k,pg in ipairs(pages) do
    local on=(k==i)
    if on and not pg.sf.Visible then pg.sf.Position=UDim2.fromOffset(0,12) tw(pg.sf,.3,{Position=UDim2.fromOffset(0,0)}) end
    pg.sf.Visible=on
    tw(tabs[k].bar,.2,{Size=UDim2.fromOffset(3,on and 16 or 0)})
    tw(tabs[k].btn,.2,{BackgroundTransparency=on and .84 or 1,TextColor3=on and TXT or DIM})
  end
  curPage=pages[i] title.Text=curPage.name sb.Text="" filter()
  PV.on=(curPage.name=="ESP")
end
local function page(name)
  local idx=#pages+1
  local sf=N("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,ScrollingDirection=Enum.ScrollingDirection.Y},content)
  onTheme(function() sf.ScrollBarImageColor3=A1 end)
  N("UIPadding",{PaddingBottom=UDim.new(0,12),PaddingRight=UDim.new(0,5)},sf)
  local function col(sx,ox2)
    local c=N("Frame",{Size=UDim2.new(.5,-4,0,0),Position=UDim2.new(sx,ox2,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},sf)
    N("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},c)
    return c
  end
  local pg={sf=sf,name=name,cards={},L=col(0,0),R=col(.5,4)}
  local btn=N("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=A1,BackgroundTransparency=1,Text=name,TextColor3=DIM,Font=Enum.Font.GothamMedium,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},tabList) corner(btn,8)
  N("UIPadding",{PaddingLeft=UDim.new(0,16)},btn)
  local bar=N("Frame",{AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,-12,.5,0),Size=UDim2.fromOffset(3,0),BackgroundColor3=A1,BorderSizePixel=0},btn) corner(bar,2)
  onTheme(function() btn.BackgroundColor3=A1 bar.BackgroundColor3=A1 end)
  pages[idx]=pg tabs[idx]={btn=btn,bar=bar}
  btn.MouseButton1Click:Connect(function() selectTab(idx) end)
