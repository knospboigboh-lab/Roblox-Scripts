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
  return pg
end

-- notifications
local nf=N("Frame",{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-22),Size=UDim2.fromOffset(240,300),BackgroundTransparency=1},hud)
N("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},nf)
local function notify(ti,tx)
  local f=N("Frame",{Size=UDim2.fromOffset(230,44),BackgroundColor3=BG0,BackgroundTransparency=1},nf) corner(f,10)
  local st=stroke(f,Color3.new(1,1,1),1,1)
  local bar=N("Frame",{Size=UDim2.new(0,3,1,-14),Position=UDim2.fromOffset(8,7),BackgroundColor3=A1,BorderSizePixel=0,BackgroundTransparency=1},f) corner(bar,2)
  local a=T({Text=ti,Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(20,5),Size=UDim2.new(1,-28,0,16),TextXAlignment=Enum.TextXAlignment.Left,TextTransparency=1},f)
  local b=T({Text=tx,TextSize=11,TextColor3=DIM,Position=UDim2.fromOffset(20,22),Size=UDim2.new(1,-28,0,16),TextXAlignment=Enum.TextXAlignment.Left,TextTransparency=1},f)
  tw(f,.25,{BackgroundTransparency=.1}) tw(st,.25,{Transparency=.85}) tw(bar,.25,{BackgroundTransparency=0}) tw(a,.25,{TextTransparency=0}) tw(b,.25,{TextTransparency=0})
  task.delay(2.8,function()
    if not f.Parent then return end
    tw(f,.3,{BackgroundTransparency=1}) tw(st,.3,{Transparency=1}) tw(bar,.3,{BackgroundTransparency=1}) tw(a,.3,{TextTransparency=1}) tw(b,.3,{TextTransparency=1})
    task.delay(.35,function() f:Destroy() end)
  end)
end

-- ===================================================================
--  CONTROL LIBRARY
-- ===================================================================
local DRAG,DRAGEND
con(UIS.InputChanged,function(i) if DRAG and isM(i) then DRAG(i.Position) end end)
con(UIS.InputEnded,function(i) if DRAG and isP(i) then DRAG=nil if DRAGEND then DRAGEND() DRAGEND=nil end end end)
local function beginDrag(fn,pg,pos) DRAG=fn if pg then pg.sf.ScrollingEnabled=false DRAGEND=function() pg.sf.ScrollingEnabled=true end end fn(pos) end

local function card(pg,col,ti,sub)
  local f=N("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=BG1,BackgroundTransparency=.2},col) corner(f,10) stroke(f)
  N("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},f)
  N("UIPadding",{PaddingTop=UDim.new(0,9),PaddingBottom=UDim.new(0,9),PaddingLeft=UDim.new(0,11),PaddingRight=UDim.new(0,11)},f)
  local cd={f=f,pg=pg,n=1,rows={}}
  T({Text=ti,Font=Enum.Font.GothamBold,TextSize=13,Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0},f)
  if sub then T({Text=sub,TextSize=10,TextColor3=DIM,Size=UDim2.new(1,0,0,12),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},f) end
  pg.cards[#pg.cards+1]=cd
  return cd
end
local function addRow(cd,f,name) cd.n=cd.n+1 f.LayoutOrder=cd.n cd.rows[#cd.rows+1]={f=f,name=name or ""} end
local function rowFrame(cd,h) return N("Frame",{Size=UDim2.new(1,0,0,h),BackgroundTransparency=1},cd.f) end

local function toggle(cd,name,flag,def,cb)
  F[flag]=def DEF[flag]=def
  local r=rowFrame(cd,26)
  T({Text=name,Size=UDim2.new(1,-46,1,0),TextXAlignment=Enum.TextXAlignment.Left},r)
  local sw=N("TextButton",{Text="",AutoButtonColor=false,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(34,18)},r) corner(sw,9)
  local kn=N("Frame",{Size=UDim2.fromOffset(12,12),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},sw) corner(kn,6)
  local function paint(a)
    local on=F[flag]
    local c=on and A1 or BG2
    local p=on and UDim2.fromOffset(19,3) or UDim2.fromOffset(3,3)
    if a then tw(sw,.18,{BackgroundColor3=c}) tw(kn,.18,{Position=p}) else sw.BackgroundColor3=c kn.Position=p end
  end
  onTheme(function() paint(false) end)
  SET[flag]=function(v) F[flag]=v paint(true) if cb then cb(v) end end
  sw.MouseButton1Click:Connect(function() SET[flag](not F[flag]) end)
  addRow(cd,r,name)
end

local function slider(cd,name,flag,mn,mx,def,cb,dec)
  F[flag]=def DEF[flag]=def dec=dec or 0
  local r=rowFrame(cd,36)
  T({Text=name,Size=UDim2.new(.65,0,0,18),TextXAlignment=Enum.TextXAlignment.Left},r)
  local vl=T({Size=UDim2.new(.35,0,0,18),Position=UDim2.fromScale(.65,0),TextXAlignment=Enum.TextXAlignment.Right,TextColor3=DIM,TextSize=11},r)
  local bar=N("Frame",{Position=UDim2.fromOffset(0,24),Size=UDim2.new(1,0,0,5),BackgroundColor3=BG2,BorderSizePixel=0},r) corner(bar,3)
  local fill=N("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=A1,BorderSizePixel=0},bar) corner(fill,3)
  local kn=N("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(11,11),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},bar) corner(kn,6)
  local hit=N("TextButton",{Text="",BackgroundTransparency=1,Position=UDim2.fromOffset(0,14),Size=UDim2.new(1,0,0,22)},r)
  onTheme(function() fill.BackgroundColor3=A1 end)
  local function apply(v,anim,silent)
    v=math.clamp(v,mn,mx) local m=10^dec v=math.floor(v*m+.5)/m
    F[flag]=v vl.Text=string.format("%."..dec.."f",v)
    local x=(v-mn)/(mx-mn)
    if anim then tw(fill,.12,{Size=UDim2.fromScale(x,1)}) tw(kn,.12,{Position=UDim2.fromScale(x,.5)})
    else fill.Size=UDim2.fromScale(x,1) kn.Position=UDim2.fromScale(x,.5) end
    if cb and not silent then cb(v) end
  end
  apply(def,false,true)
  SET[flag]=function(v) apply(v,true) end
  hit.InputBegan:Connect(function(i)
    if isP(i) then beginDrag(function(pos) apply(mn+(mx-mn)*math.clamp((pos.X-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1),false) end,cd.pg,i.Position) end
  end)
  addRow(cd,r,name)
end

local function dropdown(cd,name,flag,opts,def,cb)
  F[flag]=def DEF[flag]=def
  local box=N("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},cd.f)
  N("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},box)
  local top=N("TextButton",{Text="",AutoButtonColor=false,Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,LayoutOrder=1},box)
  T({Text=name,Size=UDim2.new(.5,0,1,0),TextXAlignment=Enum.TextXAlignment.Left},top)
  local cur=T({AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(96,22),BackgroundTransparency=0,BackgroundColor3=BG2,TextSize=11},top) corner(cur,6) stroke(cur)
  local list=N("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false,LayoutOrder=2},box)
  N("UIListLayout",{Padding=UDim.new(0,2)},list)
  local btns={}
  local function paint() cur.Text=tostring(F[flag]) for o,b in pairs(btns) do b.TextColor3=(o==F[flag]) and A1 or DIM end end
  local function build(o)
    for _,b in pairs(btns) do b:Destroy() end
    btns={}
    for _,v in ipairs(o) do
      local b=N("TextButton",{Text=v,Size=UDim2.new(1,0,0,22),BackgroundColor3=BG2,BackgroundTransparency=.35,TextColor3=DIM,Font=Enum.Font.Gotham,TextSize=11,AutoButtonColor=false},list) corner(b,6)
      btns[v]=b
      b.MouseButton1Click:Connect(function() SET[flag](v) list.Visible=false end)
    end
    paint()
  end
  SET[flag]=function(v) F[flag]=v paint() if cb then cb(v) end end
  top.MouseButton1Click:Connect(function() list.Visible=not list.Visible end)
  onTheme(paint)
  build(opts) addRow(cd,box,name)
  return {set=build}
end

local function picker(cd,name,flag,def,cb)
  F[flag]=def DEF[flag]=def
  local box=N("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},cd.f)
  N("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},box)
  local top=N("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,LayoutOrder=1},box)
  T({Text=name,Size=UDim2.new(1,-46,1,0),TextXAlignment=Enum.TextXAlignment.Left},top)
  local swb=N("TextButton",{Text="",AutoButtonColor=false,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(34,18),BackgroundColor3=def},top) corner(swb,5) stroke(swb,Color3.new(1,1,1),1,.7)
  local pn=N("Frame",{Size=UDim2.new(1,0,0,96),BackgroundTransparency=1,Visible=false,LayoutOrder=2},box)
  local sv=N("TextButton",{Text="",AutoButtonColor=false,Size=UDim2.new(1,-24,1,0),BorderSizePixel=0,BackgroundColor3=Color3.new(1,0,0)},pn) corner(sv,6)
  local w=N("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},sv) corner(w,6) N("UIGradient",{Transparency=NumberSequence.new(0,1)},w)
  local bl=N("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0},sv) corner(bl,6) N("UIGradient",{Rotation=90,Transparency=NumberSequence.new(1,0)},bl)
  local svk=N("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(9,9),BackgroundTransparency=1},sv) corner(svk,5) stroke(svk,Color3.new(1,1,1),2,0)
  local hue=N("TextButton",{Text="",AutoButtonColor=false,Position=UDim2.new(1,-18,0,0),Size=UDim2.new(0,18,1,0),BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1)},pn) corner(hue,6)
  local ks={} for i=0,6 do ks[#ks+1]=ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i==6 and 0 or i/6,1,1)) end
  N("UIGradient",{Rotation=90,Color=ColorSequence.new(ks)},hue)
  local hk=N("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.new(1,4,0,3),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},hue) corner(hk,2)
  local h,s,v=Color3.toHSV(def)
  local function apply(silent)
    local c=Color3.fromHSV(h,s,v)
    F[flag]=c swb.BackgroundColor3=c sv.BackgroundColor3=Color3.fromHSV(h,1,1)
    svk.Position=UDim2.fromScale(s,1-v) hk.Position=UDim2.fromScale(.5,h)
    if cb and not silent then cb(c) end
  end
  apply(true)
  SET[flag]=function(c) h,s,v=Color3.toHSV(c) apply() end
  swb.MouseButton1Click:Connect(function() pn.Visible=not pn.Visible end)
  sv.InputBegan:Connect(function(i) if isP(i) then beginDrag(function(pos)
    s=math.clamp((pos.X-sv.AbsolutePosition.X)/math.max(sv.AbsoluteSize.X,1),0,1)
    v=1-math.clamp((pos.Y-sv.AbsolutePosition.Y)/math.max(sv.AbsoluteSize.Y,1),0,1) apply() end,cd.pg,i.Position) end end)
  hue.InputBegan:Connect(function(i) if isP(i) then beginDrag(function(pos)
    h=math.clamp((pos.Y-hue.AbsolutePosition.Y)/math.max(hue.AbsoluteSize.Y,1),0,.999) apply() end,cd.pg,i.Position) end end)
  addRow(cd,box,name)
end

local function keybind(cd,name,flag,def,cb)
  F[flag]=def DEF[flag]=def
  local r=rowFrame(cd,26)
  T({Text=name,Size=UDim2.new(1,-92,1,0),TextXAlignment=Enum.TextXAlignment.Left},r)
  local b=N("TextButton",{Text=def,AutoButtonColor=false,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(88,22),BackgroundColor3=BG2,TextColor3=TXT,Font=Enum.Font.Gotham,TextSize=11},r) corner(b,6) stroke(b)
  local wait=false
  SET[flag]=function(v) F[flag]=v b.Text=v if cb then cb(v) end end
  b.MouseButton1Click:Connect(function() wait=true b.Text="..." end)
  con(UIS.InputBegan,function(i)
    if wait and i.UserInputType==Enum.UserInputType.Keyboard then wait=false SET[flag](i.KeyCode==Enum.KeyCode.Escape and def or i.KeyCode.Name) end
  end)
  addRow(cd,r,name)
end

local function textbox(cd,name,flag,def,cb)
  F[flag]=def DEF[flag]=def
  local r=rowFrame(cd,26)
  T({Text=name,Size=UDim2.new(1,-116,1,0),TextXAlignment=Enum.TextXAlignment.Left},r)
  local tb=N("TextBox",{Text=def,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(110,22),BackgroundColor3=BG2,TextColor3=TXT,Font=Enum.Font.Gotham,TextSize=11,ClearTextOnFocus=false},r) corner(tb,6) stroke(tb)
  SET[flag]=function(v) F[flag]=tostring(v) tb.Text=F[flag] if cb then cb(F[flag]) end end
  tb.FocusLost:Connect(function() SET[flag](tb.Text) end)
  addRow(cd,r,name)
end

local function button(cd,name,cb)
  local r=rowFrame(cd,30)
  local b=N("TextButton",{Text=name,AutoButtonColor=false,Size=UDim2.new(1,0,0,26),Position=UDim2.fromOffset(0,2),BackgroundColor3=BG2,TextColor3=TXT,Font=Enum.Font.GothamMedium,TextSize=12},r) corner(b,7) local st=stroke(b)
  b.MouseEnter:Connect(function() tw(st,.15,{Transparency=.6,Color=A1}) end)
  b.MouseLeave:Connect(function() tw(st,.15,{Transparency=.9,Color=Color3.new(1,1,1)}) end)
  b.MouseButton1Click:Connect(function() tw(b,.08,{BackgroundColor3=A1}) task.delay(.1,function() tw(b,.2,{BackgroundColor3=BG2}) end) cb() end)
  addRow(cd,r,name)
  return b
end
local function note(cd,text,h)
  local r=rowFrame(cd,h or 28)
  T({Text=text,TextSize=10,TextColor3=DIM,Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true},r)
  addRow(cd,r,text)
end

-- ===================================================================
--  ESP ENGINE (BillboardGui: рамка, имя, HP, дистанция; Drawing: tracers/skeleton)
-- ===================================================================
local function buildESP(pr)
  local e={}
  e.box=N("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},pr)
  e.fill=N("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},e.box)
  N("UIGradient",{Rotation=90,Transparency=NumberSequence.new(.65,.95)},e.fill)
  e.st=N("UIStroke",{Thickness=1.5,Color=Color3.new(1,1,1),ApplyStrokeMode=Enum.ApplyStrokeMode.Border},e.box)
  e.cn={}
  local defs={{0,0,0,0,.3,2,0,0},{0,0,0,0,0,2,0,.2},{1,0,1,0,.3,2,0,0},{1,0,1,0,0,2,0,.2},{0,1,0,1,.3,2,0,0},{0,1,0,1,0,2,0,.2},{1,1,1,1,.3,2,0,0},{1,1,1,1,0,2,0,.2}}
  for i,d in ipairs(defs) do
    local horiz=(i%2==1)
    e.cn[i]=N("Frame",{AnchorPoint=Vector2.new(d[3],d[4]),Position=UDim2.fromScale(d[1],d[2]),Size=horiz and UDim2.new(.3,0,0,2) or UDim2.new(0,2,.22,0),BorderSizePixel=0},e.box)
  end
  e.hb=N("Frame",{Position=UDim2.new(0,-7,0,0),Size=UDim2.new(0,3,1,0),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.3,BorderSizePixel=0},pr)
  e.hf=N("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.fromScale(1,1),BorderSizePixel=0},e.hb)
  e.ht=T({AnchorPoint=Vector2.new(1,0),Position=UDim2.new(0,-10,0,0),Size=UDim2.fromOffset(26,12),TextXAlignment=Enum.TextXAlignment.Right,TextSize=9,Font=Enum.Font.GothamBold,TextStrokeTransparency=.4},pr)
  e.nm=T({AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,0,-3),Size=UDim2.fromOffset(180,14),Font=Enum.Font.GothamBold,TextSize=12,TextStrokeTransparency=.35},pr)
  e.inf=T({AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,1,3),Size=UDim2.fromOffset(180,26),TextYAlignment=Enum.TextYAlignment.Top,TextSize=11,TextStrokeTransparency=.35},pr)
  return e
end
local function paint(e,d)
  local col=d.col
  local full=(F.BoxStyle=="Full")
  e.box.Visible=F.Box
  e.st.Enabled=full e.st.Color=col
  for _,c in ipairs(e.cn) do c.Visible=not full c.BackgroundColor3=col end
  e.fill.Visible=F.BoxFill e.fill.BackgroundColor3=col
  e.hb.Visible=F.HealthBar
  local f=math.clamp(d.hpf,0,1)
  e.hf.Size=UDim2.fromScale(1,f) e.hf.BackgroundColor3=Color3.fromHSV(f*.33,.9,1)
  e.ht.Visible=F.HealthText e.ht.Position=UDim2.new(0,-10,1-f,-6) e.ht.Text=tostring(math.floor(d.hp))
  e.nm.Visible=F.Name e.nm.Text=d.name
  local s={}
  if F.Distance then s[#s+1]=d.dist.."m" end
  if F.Tool and d.tool then s[#s+1]="["..d.tool.."]" end
  e.inf.Visible=(#s>0) e.inf.Text=table.concat(s,"\n")
end

local B15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local B6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local function hideSk(e) if e.sk then for _,l in ipairs(e.sk) do l.Visible=false end end end
local function skel(e,c,r15,col)
  local bones=r15 and B15 or B6
  e.sk=e.sk or {}
  for i,b in ipairs(bones) do
    local ln=e.sk[i]
    if not ln then ln=Drawing.new("Line") ln.Thickness=1 e.sk[i]=ln end
    local a,bb=c:FindFirstChild(b[1]),c:FindFirstChild(b[2])
    local vis=false
    if a and bb then
      local pa,va=cam:WorldToViewportPoint(a.Position)
      local pb,vb=cam:WorldToViewportPoint(bb.Position)
      if va and vb then ln.From=Vector2.new(pa.X,pa.Y) ln.To=Vector2.new(pb.X,pb.Y) ln.Color=col vis=true end
    end
    ln.Visible=vis
  end
  for i=#bones+1,#e.sk do e.sk[i].Visible=false end
end
local function espCol(p,rb) return F.RainbowESP and rb or ((F.TeamColor and p and p.Team) and p.TeamColor.Color) or F.ESPColor end
local function tracerFrom()
  local vp=cam.ViewportSize local m=F.TracerFrom
  if m=="Center" then return Vector2.new(vp.X/2,vp.Y/2) elseif m=="Top" then return Vector2.new(vp.X/2,0) elseif m=="Mouse" then return UIS:GetMouseLocation() end
  return Vector2.new(vp.X/2,vp.Y)
end

local function mkESP(p)
  if p==lp or E[p] then return end
  local bb=N("BillboardGui",{AlwaysOnTop=true,Size=UDim2.fromOffset(40,70),Enabled=false,LightInfluence=0},esp)
  local e=buildESP(bb)
  e.bb=bb e.lt=0
  e.hl=N("Highlight",{Enabled=false},esp)
  if hasD then e.ln=Drawing.new("Line") e.ln.Visible=false end
  E[p]=e
end
local function killESP(p)
  local e=E[p] if not e then return end
  pcall(function() e.bb:Destroy() e.hl:Destroy() end)
  if e.ln then pcall(function() e.ln:Remove() end) end
  if e.sk then for _,l in ipairs(e.sk) do pcall(function() l:Remove() end) end end
  E[p]=nil
end
for _,p in ipairs(P:GetPlayers()) do mkESP(p) end
con(P.PlayerAdded,mkESP) con(P.PlayerRemoving,killESP)

local function espStep(t)
  local lr=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
  local vp=cam.ViewportSize
  local k=vp.Y/(2*math.tan(math.rad(cam.FieldOfView)/2))
  local rb=Color3.fromHSV(t*.2%1,.8,1)
  local tf=(hasD and F.Tracers) and tracerFrom() or nil
  for p,e in pairs(E) do
    local c=p.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    local r=c and c:FindFirstChild("HumanoidRootPart")
    local on=F.ESP and r and h and h.Health>0
    local dist=0
    if on then
      dist=lr and (lr.Position-r.Position).Magnitude or (cam.CFrame.Position-r.Position).Magnitude
      if dist>F.MaxDist or (F.TeamCheck and p.Team~=nil and p.Team==lp.Team) then on=false end
    end
    local tv=false
    if on then
      local col=espCol(p,rb)
      local cd=math.max((cam.CFrame.Position-r.Position).Magnitude,1)
      local hpx=math.clamp(5.8*k/cd,16,700)
      e.bb.Adornee=r e.bb.Size=UDim2.fromOffset(hpx*.55,hpx)
      if t-e.lt>.08 then
        e.lt=t
        local tool=c:FindFirstChildOfClass("Tool")
        paint(e,{name=(F.NameSrc=="Username") and p.Name or p.DisplayName,hpf=h.Health/math.max(h.MaxHealth,1),hp=h.Health,dist=math.floor(dist),tool=tool and tool.Name,col=col})
      end
      e.hl.Adornee=c
      e.hl.FillColor=F.ChamUseESP and col or F.ChamFill
      e.hl.OutlineColor=F.ChamUseESP and col or F.ChamOutline
      e.hl.FillTransparency=F.ChamFillT e.hl.OutlineTransparency=F.ChamOutT
      e.hl.DepthMode=Enum.HighlightDepthMode[F.ChamDepth]
      if tf and e.ln then
        local ps,vs=cam:WorldToViewportPoint(r.Position)
        if vs then tv=true e.ln.From=tf e.ln.To=Vector2.new(ps.X,ps.Y) e.ln.Color=col e.ln.Thickness=F.TracerThick end
      end
      if hasD and F.Skeleton then skel(e,c,h.RigType==Enum.HumanoidRigType.R15,col) else hideSk(e) end
    else hideSk(e) end
    if e.ln then e.ln.Visible=tv end
    e.bb.Enabled=not not on
    e.hl.Enabled=not not (on and F.Chams)
  end
end

-- ===================================================================
--  FX ENGINE (эффекты на своём персонаже, локально)
-- ===================================================================
local FXF=N("Folder",{Name="NBFX"},workspace)
local fx={}
local function clr(k) local t=fx[k] if t then for _,o in ipairs(t.objs or {}) do pcall(function() o:Destroy() end) end fx[k]=nil end end
local function myRoot() local c=lp.Character return c and c:FindFirstChild("HumanoidRootPart"),c end
local function mkPart(sz,col,shape)
  return N("Part",{Size=sz,Color=col,Material=Enum.Material.Neon,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false,Massless=true,Shape=shape or Enum.PartType.Block},FXF)
end
local function mkRing(n,col,w,r,fill)
  local t={n=n,r=r,parts={}}
  local len=2*math.pi*r/n*fill
  for i=1,n do t.parts[i]=mkPart(Vector3.new(w,w,len),(i%2==0) and col or shift(col)) end
  return t
end
local function ringCF(t,ctr,spin)
  local cfs={}
  for i=1,t.n do
    local a=spin+(i-1)*2*math.pi/t.n
    local pos=Vector3.new(math.cos(a)*t.r,0,math.sin(a)*t.r)
    cfs[i]=ctr*CFrame.new(pos,pos+Vector3.new(-math.sin(a),0,math.cos(a)))
  end
  return cfs
end
local function bulk(parts,cfs) if #parts>0 then workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged) end end
local function nsq(a,b,c) return NumberSequence.new({NumberSequenceKeypoint.new(0,a),NumberSequenceKeypoint.new(1,b)}) end

RB.aura=function()
  clr("aura") if not F.Aura then return end
  local r=myRoot() if not r then return end
  local pe=N("ParticleEmitter",{Rate=F.AuraRate,Lifetime=NumberRange.new(.7,1.4),Speed=NumberRange.new(2,5),SpreadAngle=Vector2.new(180,180),Size=nsq(F.AuraSize,0),Transparency=nsq(.3,1),LightEmission=1,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-70,70),Acceleration=Vector3.new(0,3,0),Color=ColorSequence.new(F.AuraColor,shift(F.AuraColor)),Shape=Enum.ParticleEmitterShape.Cylinder},r)
  fx.aura={objs={pe}}
end
RB.trail=function()
  clr("trail") if not F.Trail then return end
  local r=myRoot() if not r then return end
  local a0=N("Attachment",{Position=Vector3.new(0,1.2,0)},r)
  local a1=N("Attachment",{Position=Vector3.new(0,-1.2,0)},r)
  local tr=N("Trail",{Attachment0=a0,Attachment1=a1,Lifetime=F.TrailLife,Color=ColorSequence.new(F.TrailColor,shift(F.TrailColor)),Transparency=nsq(.1,1),WidthScale=nsq(1,0),LightEmission=1,FaceCamera=true,MinLength=.05},r)
  fx.trail={objs={a0,a1,tr}}
end
RB.halo=function()
  clr("halo") if not F.Halo then return end
  local ring=mkRing(18,F.HaloColor,.14,1.1,.8)
  fx.halo={ring=ring,objs=ring.parts}
end
RB.rings=function()
  clr("rings") if not F.Rings then return end
  local a,b=mkRing(28,F.RingColor,.18,3.2,.55),mkRing(20,shift(F.RingColor),.14,2.3,.5)
  local objs={}
  for _,p in ipairs(a.parts) do objs[#objs+1]=p end
  for _,p in ipairs(b.parts) do objs[#objs+1]=p end
  fx.rings={a=a,b=b,objs=objs}
end
RB.orbs=function()
  clr("orbs") if not F.Orbs then return end
  local objs={}
  for i=1,F.OrbCount do objs[i]=mkPart(Vector3.new(.4,.4,.4),(i%2==0) and F.OrbColor or shift(F.OrbColor),Enum.PartType.Ball) end
  fx.orbs={objs=objs}
end
RB.wings=function()
  clr("wings") if not F.Wings then return end
  local objs,fe={}, {}
  local lens={2.9,2.7,2.4,2.0,1.6}
  for side=-1,1,2 do
    for i,len in ipairs(lens) do
      local p=mkPart(Vector3.new(.1,len,.5),(i%2==0) and F.WingColor or shift(F.WingColor))
      p.Transparency=.15
      objs[#objs+1]=p fe[#fe+1]={p=p,side=side,i=i,len=len}
    end
  end
  fx.wings={objs=objs,fe=fe}
end
RB.fly=function()
  clr("fly") if not F.Fly then return end
  local p=N("Part",{Size=Vector3.new(70,40,70),Transparency=1,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false},FXF)
  N("ParticleEmitter",{Shape=Enum.ParticleEmitterShape.Box,Rate=F.FlyAmt,Lifetime=NumberRange.new(5,9),Speed=NumberRange.new(.3,1.2),SpreadAngle=Vector2.new(180,180),Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,.18),NumberSequenceKeypoint.new(1,0)}),LightEmission=1,Transparency=NumberSequence.new(.1),Color=ColorSequence.new(F.FlyColor,shift(F.FlyColor)),Drag=1},p)
  fx.fly={objs={p},part=p}
end

local SC={}
local function selfApply()
  local c=lp.Character if not c then return end
  for _,d in ipairs(c:GetDescendants()) do
    if d:IsA("BasePart") then
      if not SC[d] then SC[d]={d.Material,d.Color,d.Transparency} end
      if F.SelfChams and d.Name~="HumanoidRootPart" then
        d.Material=Enum.Material[F.SelfMat] d.Color=F.SelfColor d.Transparency=F.SelfTrans
      else d.Material,d.Color,d.Transparency=SC[d][1],SC[d][2],SC[d][3] end
    end
  end
  if not F.SelfChams then SC={} end
end
local function rebuildAll() for _,f in pairs(RB) do pcall(f) end pcall(selfApply) end
con(lp.CharacterAdded,function() task.delay(1,rebuildAll) end)

local function fxStep(t)
  if fx.fly then fx.fly.part.CFrame=CFrame.new(cam.CFrame.Position) end
  local r,c=myRoot() if not r then return end
  local hum=c:FindFirstChildOfClass("Humanoid")
  local head=c:FindFirstChild("Head")
  if fx.halo then
    local hp=(head or r).Position+Vector3.new(0,head and 1.45 or 3,0)+Vector3.new(0,math.sin(t*2)*.08,0)
    local ctr=CFrame.new(hp)*CFrame.Angles(math.sin(t*1.1)*.1,0,math.cos(t*1.3)*.1)
    bulk(fx.halo.ring.parts,ringCF(fx.halo.ring,ctr,t*1.5))
  end
  if fx.rings then
    local hh=hum and ((hum.RigType==Enum.HumanoidRigType.R6) and 2 or hum.HipHeight) or 2
    local base=CFrame.new(r.Position.X,r.Position.Y-r.Size.Y/2-hh+.15,r.Position.Z)
    local sp=t*F.RingSpeed
    bulk(fx.rings.a.parts,ringCF(fx.rings.a,base,sp))
    bulk(fx.rings.b.parts,ringCF(fx.rings.b,base,-sp*1.3))
  end
  if fx.orbs then
    local cfs,n={}, #fx.orbs.objs
    for i=1,n do
      local a=t*F.OrbSpeed+i*2*math.pi/n
      cfs[i]=CFrame.new(r.Position+Vector3.new(math.cos(a)*F.OrbRadius,math.sin(t*1.7+i)*.9,math.sin(a)*F.OrbRadius))
    end
    bulk(fx.orbs.objs,cfs)
  end
  if fx.wings then
    local base=r.CFrame*CFrame.new(0,.6,.55)
    local flap=math.sin(t*F.WingSpeed)*.22
    local cfs,ps={}, {}
    for _,f in ipairs(fx.wings.fe) do
      local ang=math.rad(16+f.i*15)+flap
      cfs[#cfs+1]=base*CFrame.new(f.side*.35,0,0)*CFrame.Angles(math.rad(14),0,-f.side*ang)*CFrame.new(0,f.len/2,0)
      ps[#ps+1]=f.p
    end
    bulk(ps,cfs)
  end
end

-- ===================================================================
--  WORLD (lighting + post effects)
-- ===================================================================
local function ov(p,v) if LA[p]==nil then LA[p]=L[p] end L[p]=v end
local function rel(p) if LA[p]~=nil then L[p]=LA[p] LA[p]=nil end end
local function lighting()
  if F.Fullbright then
    ov("Brightness",2) ov("Ambient",Color3.new(1,1,1)) ov("OutdoorAmbient",Color3.new(1,1,1)) ov("GlobalShadows",false)
  else
    rel("Brightness") rel("GlobalShadows")
    if F.AmbOn then ov("Ambient",F.AmbColor) ov("OutdoorAmbient",F.AmbColor) else rel("Ambient") rel("OutdoorAmbient") end
  end
  if F.NoFog then ov("FogEnd",1e6) ov("FogStart",1e6) else rel("FogEnd") rel("FogStart") end
  if F.TimeOn then ov("ClockTime",F.Time) else rel("ClockTime") end
  if F.ExpOn then ov("ExposureCompensation",F.Exp) else rel("ExposureCompensation") end
  if F.FOVOn then AP.fov=true cam.FieldOfView=F.FOV elseif AP.fov then AP.fov=false cam.FieldOfView=O.fov end
end
local function ensure(cls,nm) local o=L:FindFirstChild(nm) if not o or not o:IsA(cls) then o=Instance.new(cls) o.Name=nm o.Parent=L end return o end
local function post()
  local b=ensure("BloomEffect","NB_Bloom") b.Enabled=F.Bloom b.Intensity=F.BloomInt b.Size=F.BloomSize b.Threshold=F.BloomTh
  local cc=ensure("ColorCorrectionEffect","NB_CC") cc.Enabled=F.CC cc.Saturation=F.Sat cc.Contrast=F.Con cc.Brightness=F.Bri cc.TintColor=F.Tint
  local bl=ensure("BlurEffect","NB_Blur") bl.Enabled=F.Blur bl.Size=F.BlurSize
  local sr=ensure("SunRaysEffect","NB_Sun") sr.Enabled=F.Sun sr.Intensity=F.SunInt sr.Spread=F.SunSpread
end

-- ===================================================================
--  HUD (watermark, active list, crosshair)
-- ===================================================================
local wm=N("Frame",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,10),Size=UDim2.fromOffset(0,28),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=BG0,BackgroundTransparency=.12},hud) corner(wm,14) stroke(wm)
N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,10),VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},wm)
N("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)},wm)
local function wl(o,bold) return T({AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,28),Font=bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium,LayoutOrder=o,Text=""},wm) end
local wT,wF,wP,wC=wl(1,true),wl(2),wl(3),wl(4)
local wTG=N("UIGradient",{},wT) wT.TextColor3=Color3.new(1,1,1)
onTheme(function() wTG.Color=seqAB or ColorSequence.new(A1,A2) end)

local ap=N("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,58),Size=UDim2.fromOffset(150,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=BG0,BackgroundTransparency=.15},hud) corner(ap,10) stroke(ap)
N("UIListLayout",{Padding=UDim.new(0,4)},ap)
N("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},ap)
T({Text="ACTIVE",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=DIM,Size=UDim2.new(1,0,0,12),TextXAlignment=Enum.TextXAlignment.Right},ap)
local apL=T({RichText=true,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Top,TextSize=12,Font=Enum.Font.GothamMedium},ap)
local FL={{"Box","Box ESP"},{"Name","Names"},{"HealthBar","Health"},{"Distance","Distance"},{"Tool","Tools"},{"Tracers","Tracers"},{"Skeleton","Skeleton"},{"Chams","Chams"},{"SelfChams","Self chams"},{"Aura","Aura"},{"Trail","Trail"},{"Halo","Halo"},{"Rings","Rings"},{"Orbs","Orbs"},{"Wings","Wings"},{"Fly","Fireflies"},{"Fullbright","Fullbright"},{"NoFog","No fog"},{"Bloom","Bloom"},{"CC","Color grade"},{"Blur","Blur"},{"Sun","Sun rays"}}

local ch=N("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(80,80),BackgroundTransparency=1,Visible=false},hud)
local arms={}
for i=1,4 do arms[i]=N("Frame",{AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0},ch) end
local dot=N("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BorderSizePixel=0,Size=UDim2.fromOffset(6,6)},ch) corner(dot,3)
local circ=N("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundTransparency=1},ch) corner(circ,100)
local cst=N("UIStroke",{Thickness=1.5},circ)
local function crosshair()
  ch.Visible=F.Cross
  local s,g,st,col=F.CrossSize,F.CrossGap,F.CrossStyle,F.CrossColor
  for i,a in ipairs(arms) do
    a.Visible=(st=="Cross") a.BackgroundColor3=col
    if i==1 then a.Size=UDim2.fromOffset(s,2) a.Position=UDim2.new(.5,-(g+s/2),.5,0)
    elseif i==2 then a.Size=UDim2.fromOffset(s,2) a.Position=UDim2.new(.5,g+s/2,.5,0)
    elseif i==3 then a.Size=UDim2.fromOffset(2,s) a.Position=UDim2.new(.5,0,.5,-(g+s/2))
    else a.Size=UDim2.fromOffset(2,s) a.Position=UDim2.new(.5,0,.5,g+s/2) end
  end
  dot.Visible=(st=="Dot") dot.BackgroundColor3=col
  circ.Visible=(st=="Circle") circ.Size=UDim2.fromOffset(s*2,s*2) cst.Color=col
end

-- ===================================================================
--  3D PREVIEW (живой предпросмотр ESP на модели)
-- ===================================================================
local function buildPreview(cd)
  local pf=N("Frame",{Size=UDim2.new(1,0,0,176),BackgroundColor3=BG0,BackgroundTransparency=.2},cd.f) corner(pf,8) stroke(pf)
  addRow(cd,pf,"preview")
  local vf=N("ViewportFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Ambient=Color3.fromRGB(170,170,200),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-.5,-.8,-.6)},pf)
  local vc=N("Camera",{FieldOfView=70},vf) vf.CurrentCamera=vc
  local wmod=N("WorldModel",{},vf)
  local model
  pcall(function() local c=lp.Character if c then c.Archivable=true model=c:Clone() end end)
  if model then
    for _,d in ipairs(model:GetDescendants()) do
      if d:IsA("LuaSourceContainer") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored=true end
    end
  else
    model=N("Model",{})
    local function bp(sz,pos,col) N("Part",{Size=sz,CFrame=CFrame.new(pos),Color=col,Anchored=true,Material=Enum.Material.SmoothPlastic},model) end
    bp(Vector3.new(1.2,1,1),Vector3.new(0,4.5,0),Color3.fromRGB(245,205,170)) bp(Vector3.new(2,2,1),Vector3.new(0,3,0),Color3.fromRGB(80,90,200))
    bp(Vector3.new(1,2,1),Vector3.new(-1.5,3,0),Color3.fromRGB(245,205,170)) bp(Vector3.new(1,2,1),Vector3.new(1.5,3,0),Color3.fromRGB(245,205,170))
    bp(Vector3.new(1,2,1),Vector3.new(-.5,1,0),Color3.fromRGB(40,40,52)) bp(Vector3.new(1,2,1),Vector3.new(.5,1,0),Color3.fromRGB(40,40,52))
  end
  model.Parent=wmod
  model:PivotTo(CFrame.new(0,0,0))
  local cf,sz=model:GetBoundingBox()
  local d=sz.Y*.95+2
  vc.CFrame=CFrame.lookAt(Vector3.new(0,cf.Position.Y,d),Vector3.new(0,cf.Position.Y,0))
  local frac=sz.Y/(2*d*math.tan(math.rad(35)))
  local oh=176*frac*1.1
  local oc=N("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(oh*.55,oh),BackgroundTransparency=1},pf)
  PV.e=buildESP(oc) PV.model=model PV.lt=0
end

-- ===================================================================
--  PAGES
-- ===================================================================
local pgESP=page("ESP")
local c1=card(pgESP,pgESP.L,"Players","Boxes, names and bars")
toggle(c1,"Enable ESP","ESP",true)
toggle(c1,"Box","Box",true)
dropdown(c1,"Box style","BoxStyle",{"Corner","Full"},"Corner")
toggle(c1,"Box fill","BoxFill",true)
toggle(c1,"Name","Name",true)
dropdown(c1,"Name source","NameSrc",{"Display","Username"},"Display")
toggle(c1,"Health bar","HealthBar",true)
toggle(c1,"Health number","HealthText",false)
toggle(c1,"Distance","Distance",true)
toggle(c1,"Held tool","Tool",false)
local c2=card(pgESP,pgESP.L,"Filters","Who to show")
toggle(c2,"Skip teammates","TeamCheck",false)
slider(c2,"Max distance","MaxDist",50,5000,1500)
local c3=card(pgESP,pgESP.L,"Lines","Needs Drawing API")
note(c3,hasD and "Drawing: available" or "Drawing: not supported by this executor",14)
toggle(c3,"Tracers","Tracers",false)
dropdown(c3,"Tracer from","TracerFrom",{"Bottom","Center","Top","Mouse"},"Bottom")
slider(c3,"Tracer width","TracerThick",1,4,1)
toggle(c3,"Skeleton","Skeleton",false)
local c4=card(pgESP,pgESP.R,"Preview","Live look of your ESP")
buildPreview(c4)
local c5=card(pgESP,pgESP.R,"Colors")
picker(c5,"ESP color","ESPColor",Color3.fromRGB(150,110,255))
toggle(c5,"Team color","TeamColor",false)
toggle(c5,"Rainbow","RainbowESP",false)

local pgCh=page("Chams")
local h1=card(pgCh,pgCh.L,"Highlight","Glow around players")
toggle(h1,"Chams","Chams",false)
toggle(h1,"Use ESP color","ChamUseESP",true)
dropdown(h1,"Depth","ChamDepth",{"AlwaysOnTop","Occluded"},"AlwaysOnTop")
slider(h1,"Fill transparency","ChamFillT",0,1,.5,nil,2)
slider(h1,"Outline transparency","ChamOutT",0,1,0,nil,2)
local h2=card(pgCh,pgCh.R,"Custom colors")
picker(h2,"Fill color","ChamFill",Color3.fromRGB(150,110,255))
picker(h2,"Outline color","ChamOutline",Color3.new(1,1,1))
local h3=card(pgCh,pgCh.R,"Self chams","Your own character (local)")
toggle(h3,"Enable","SelfChams",false,selfApply)
dropdown(h3,"Material","SelfMat",{"Neon","ForceField","Glass","SmoothPlastic","Metal"},"Neon",selfApply)
slider(h3,"Transparency","SelfTrans",0,1,.2,selfApply,2)
picker(h3,"Color","SelfColor",Color3.fromRGB(150,110,255),selfApply)

local pgFx=page("Effects")
local f1=card(pgFx,pgFx.L,"Aura","Particles around you")
toggle(f1,"Aura","Aura",false,RB.aura)
slider(f1,"Rate","AuraRate",5,150,40,RB.aura)
slider(f1,"Size","AuraSize",.3,3,1.2,RB.aura,1)
picker(f1,"Color","AuraColor",Color3.fromRGB(120,160,255),RB.aura)
local f2=card(pgFx,pgFx.L,"Trail","Light streak")
toggle(f2,"Trail","Trail",false,RB.trail)
slider(f2,"Lifetime","TrailLife",.2,2,.6,RB.trail,1)
picker(f2,"Color","TrailColor",Color3.fromRGB(150,110,255),RB.trail)
local f3=card(pgFx,pgFx.L,"Halo and rings","Neon rings")
toggle(f3,"Halo","Halo",false,RB.halo)
picker(f3,"Halo color","HaloColor",Color3.fromRGB(255,230,150),RB.halo)
toggle(f3,"Ground rings","Rings",false,RB.rings)
slider(f3,"Ring speed","RingSpeed",.2,5,1.5,nil,1)
picker(f3,"Ring color","RingColor",Color3.fromRGB(200,90,255),RB.rings)
local f4=card(pgFx,pgFx.R,"Orbs","Orbiting lights")
toggle(f4,"Orbs","Orbs",false,RB.orbs)
slider(f4,"Count","OrbCount",2,12,6,RB.orbs)
slider(f4,"Speed","OrbSpeed",.5,6,2,nil,1)
slider(f4,"Radius","OrbRadius",1.5,8,3.5,nil,1)
picker(f4,"Color","OrbColor",Color3.fromRGB(110,200,255),RB.orbs)
local f5=card(pgFx,pgFx.R,"Wings","Neon feathers")
toggle(f5,"Wings","Wings",false,RB.wings)
slider(f5,"Flap speed","WingSpeed",.5,8,3,nil,1)
picker(f5,"Color","WingColor",Color3.new(1,1,1),RB.wings)
local f6=card(pgFx,pgFx.R,"Ambient","Fireflies around the camera")
toggle(f6,"Fireflies","Fly",false,RB.fly)
slider(f6,"Amount","FlyAmt",5,200,40,RB.fly)
picker(f6,"Color","FlyColor",Color3.fromRGB(255,240,150),RB.fly)

local pgW=page("World")
local w1=card(pgW,pgW.L,"Lighting")
toggle(w1,"Fullbright","Fullbright",false)
toggle(w1,"No fog","NoFog",false)
toggle(w1,"Custom time","TimeOn",false)
slider(w1,"Time of day","Time",0,24,14,nil,1)
toggle(w1,"Ambient color","AmbOn",false)
picker(w1,"Ambient","AmbColor",Color3.fromRGB(120,100,200))
toggle(w1,"Exposure","ExpOn",false)
slider(w1,"Exposure value","Exp",-3,3,0,nil,1)
local w2=card(pgW,pgW.L,"Camera")
toggle(w2,"Custom FOV","FOVOn",false)
slider(w2,"FOV","FOV",30,120,90)
local w3=card(pgW,pgW.R,"Bloom and sun")
toggle(w3,"Bloom","Bloom",false,post)
slider(w3,"Intensity","BloomInt",0,3,1,post,1)
slider(w3,"Size","BloomSize",0,56,24,post)
slider(w3,"Threshold","BloomTh",0,3,1,post,1)
toggle(w3,"Sun rays","Sun",false,post)
slider(w3,"Sun intensity","SunInt",0,1,.25,post,2)
slider(w3,"Sun spread","SunSpread",0,1,1,post,2)
local w4=card(pgW,pgW.R,"Color grading")
toggle(w4,"Color correction","CC",false,post)
slider(w4,"Saturation","Sat",-1,1.5,.2,post,2)
slider(w4,"Contrast","Con",-1,1,.1,post,2)
slider(w4,"Brightness","Bri",-.5,.5,0,post,2)
picker(w4,"Tint","Tint",Color3.new(1,1,1),post)
toggle(w4,"Blur","Blur",false,post)
slider(w4,"Blur size","BlurSize",0,40,6,post)

local pgH=page("HUD")
local u1=card(pgH,pgH.L,"Watermark")
toggle(u1,"Show watermark","WM",true)
textbox(u1,"Title","WMTitle","nebula")
toggle(u1,"FPS","WMFps",true)
toggle(u1,"Ping","WMPing",true)
toggle(u1,"Clock","WMTime",true)
local u2=card(pgH,pgH.L,"Active list")
toggle(u2,"Show list","ActiveList",true)
local u3=card(pgH,pgH.R,"Crosshair")
toggle(u3,"Crosshair","Cross",false,crosshair)
dropdown(u3,"Style","CrossStyle",{"Cross","Dot","Circle"},"Cross",crosshair)
slider(u3,"Size","CrossSize",3,30,10,crosshair)
slider(u3,"Gap","CrossGap",0,15,4,crosshair)
toggle(u3,"Spin","CrossSpin",false)
picker(u3,"Color","CrossColor",Color3.new(1,1,1),crosshair)

local pgS=page("Settings")
local s1=card(pgS,pgS.L,"Menu")
local rescale
keybind(s1,"Menu key","MenuKey","RightShift")
slider(s1,"Menu scale","UIScale",.6,1.4,1,function() if rescale then rescale() end end,2)
slider(s1,"Menu transparency","Opacity",0,.5,.03,function(v) win.BackgroundTransparency=v end,2)
toggle(s1,"Particles","Particles",true)
toggle(s1,"3D parallax","Parallax",true)
local s2=card(pgS,pgS.R,"Theme")
local PRESETS={Violet=Color3.fromRGB(150,110,255),Ocean=Color3.fromRGB(70,170,255),Rose=Color3.fromRGB(255,90,150),Emerald=Color3.fromRGB(70,230,150),Amber=Color3.fromRGB(255,190,60),Crimson=Color3.fromRGB(255,70,80),Ice=Color3.fromRGB(190,225,255)}
dropdown(s2,"Accent preset","AccentPreset",{"Violet","Ocean","Rose","Emerald","Amber","Crimson","Ice"},"Violet",function(v) if SET.AccentColor then SET.AccentColor(PRESETS[v]) end end)
picker(s2,"Accent color","AccentColor",Color3.fromRGB(150,110,255),setAccent)
toggle(s2,"Rainbow accent","RainbowUI",false)

local pgC=page("Config")
local g1=card(pgC,pgC.L,"Configs","Saved in workspace/Nebula")
local DIR="Nebula"
local function cfgList()
  local out={}
  pcall(function()
    if isfolder and not isfolder(DIR) then makefolder(DIR) end
    for _,f in ipairs(listfiles(DIR)) do local n=tostring(f):match("([^/\\]+)%.json$") if n then out[#out+1]=n end end
  end)
  if #out==0 then out[1]="default" end
  return out
end
local function cfgSave(n)
  local t={}
  for k,v in pairs(F) do
    if k:sub(1,3)~="Cfg" then
      local tv=typeof(v)
      if tv=="Color3" then t[k]={c={v.R,v.G,v.B}} elseif tv=="boolean" or tv=="number" or tv=="string" then t[k]=v end
    end
  end
  return pcall(function() if makefolder and not isfolder(DIR) then makefolder(DIR) end writefile(DIR.."/"..n..".json",H:JSONEncode(t)) end)
end
local function cfgLoad(n)
  local ok,d=pcall(function() return H:JSONDecode(readfile(DIR.."/"..n..".json")) end)
  if not ok or type(d)~="table" then return false end
  for k,v in pairs(d) do
    if SET[k] then
      if type(v)=="table" and v.c then v=Color3.new(v.c[1],v.c[2],v.c[3]) end
      pcall(SET[k],v)
    end
  end
  return true
end
textbox(g1,"Config name","CfgName","default")
local dd=dropdown(g1,"Saved","CfgSel","default" and cfgList(),cfgList()[1])
button(g1,"Save config",function()
  local n=F.CfgName~="" and F.CfgName or "default"
  if cfgSave(n) then notify("Config","Saved: "..n) dd.set(cfgList()) else notify("Config","Save failed (no writefile)") end
end)
button(g1,"Load selected",function() if cfgLoad(F.CfgSel) then notify("Config","Loaded: "..F.CfgSel) else notify("Config","Config not found") end end)
button(g1,"Refresh list",function() dd.set(cfgList()) end)
local g2=card(pgC,pgC.R,"Session")
local unload
button(g2,"Reset all to default",function() for k,v in pairs(DEF) do if SET[k] then pcall(SET[k],v) end end notify("Nebula","Settings reset") end)
button(g2,"Unload Nebula",function() unload() end)
note(g2,"Visual effects are local: other players do not see your effects.",28)

-- ===================================================================
--  OPEN / CLOSE / DRAG / FAB
-- ===================================================================
local function scaleBase() local vp=cam.ViewportSize return math.min(1,(vp.X-20)/WW,(vp.Y-20)/WH)*F.UIScale end
rescale=function() if open then us.Scale=scaleBase() end end
local function setOpen(b)
  open=b
  if b then
    root.Visible=true us.Scale=scaleBase()*.88
    tw(us,.35,{Scale=scaleBase()},Enum.EasingStyle.Back) tw(win,.25,{GroupTransparency=0})
  else
    tw(us,.2,{Scale=scaleBase()*.92}) tw(win,.2,{GroupTransparency=1})
    task.delay(.22,function() if not open then root.Visible=false end end)
  end
end
local function makeDrag(handle,target,click)
  local on,st,sp,moved=false
  handle.InputBegan:Connect(function(i) if isP(i) then on=true moved=false st=i.Position sp=target.Position end end)
  con(UIS.InputChanged,function(i)
    if on and isM(i) then
      local d=i.Position-st
      if d.Magnitude>6 then moved=true end
      if moved then target.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end
    end
  end)
  con(UIS.InputEnded,function(i) if on and isP(i) then on=false if not moved and click then click() end end end)
end
makeDrag(head,root)
xb.MouseButton1Click:Connect(function() setOpen(false) end)

local fab=N("TextButton",{Name="fab",Size=UDim2.fromOffset(46,46),Position=UDim2.new(1,-64,.42,0),BackgroundColor3=BG0,Text="N",TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBlack,TextSize=22,AutoButtonColor=false},ui) corner(fab,23)
local fabS=N("UIStroke",{Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},fab)
local fabG=N("UIGradient",{},fabS)
onTheme(function() fabG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,A1),ColorSequenceKeypoint.new(.5,A2),ColorSequenceKeypoint.new(1,A1)}) end)
makeDrag(fab,fab,function() setOpen(not open) end)

-- ===================================================================
--  MAIN LOOP
-- ===================================================================
local fps,acc,pacc,lacc,racc=60,0,0,0,0
local px,py=0,0
con(RS.RenderStepped,function(dt)
  local t=tick()
  cam=workspace.CurrentCamera
  fps=fps+(1/math.max(dt,.001)-fps)*.08
  safe("esp",espStep,t)
  safe("light",lighting)
  safe("fx",fxStep,t)

  ch.Rotation=F.CrossSpin and (t*90)%360 or 0

  if root.Visible then
    bordG.Rotation=(t*50)%360 auraG.Rotation=(t*30)%360 ttlG.Rotation=(t*60)%360
    safe("logo",logoStep,t)
    if F.Parallax then
      local mp=UIS:GetMouseLocation()
      local vp=cam.ViewportSize
      local tx=(mp.X==0 and mp.Y==0) and 0 or (mp.X/vp.X-.5)*2
      local ty=(mp.X==0 and mp.Y==0) and 0 or (mp.Y/vp.Y-.5)*2
      px=px+(tx-px)*.08 py=py+(ty-py)*.08
    else px,py=0,0 end
    ox,oy=-px*8,-py*8
    aura.Position=UDim2.fromOffset(-13+px*5,-13+py*5)
    for i,d in ipairs(depth) do d.Position=UDim2.fromOffset(-i*5+px*i*2.2,-i*5+12+py*i*2.2) end
    pacc=pacc+dt
    if pacc>.033 then
      if F.Particles then safe("particles",stepParticles,pacc) end