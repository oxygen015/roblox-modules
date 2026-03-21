--[[
╔═══════════════════════════════════════════════════════════════════╗
║  ██████╗ ██╗  ██╗██╗   ██╗ ██████╗ ███████╗███╗   ██╗           ║
║ ██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝██╔════╝ ██╔════╝████╗  ██║           ║
║ ██║   ██║ ╚███╔╝  ╚████╔╝ ██║  ███╗█████╗  ██╔██╗ ██║           ║
║ ██║   ██║ ██╔██╗   ╚██╔╝  ██║   ██║██╔══╝  ██║╚██╗██║           ║
║ ╚██████╔╝██╔╝ ██╗   ██║   ╚██████╔╝███████╗██║ ╚████║           ║
║  ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝           ║
║                                                                   ║
║  Oxygen UI Library  •  beta 0.0.1                                ║
║  github.com/oxygen015/roblox-modules                             ║
║                                                                   ║
║  LOAD:                                                            ║
║  local Oxygen = loadstring(game:HttpGet(RAW_URL))()              ║
║  local UI = Oxygen.new({ Title="Script", Theme="Carbon" })       ║
║                                                                   ║
║  KEYBINDS (configurable):                                         ║
║    RightControl  → Toggle show/hide                              ║
║    RightShift    → Minimize to title bar                         ║
╚═══════════════════════════════════════════════════════════════════╝

  CHANGELOG  beta 0.0.1
  ─────────────────────
  FIX  MouseMove → MouseMovement (killed the console spam)
  FIX  Per-window UIS connections (no global bleed)
  FIX  ColorPicker SV/Hue read correct target frame
  FIX  Dropdown hit-area deferred so AbsoluteSize is ready
  FIX  UIStroke no longer duplicates on TextInput focus
  FIX  Settings LayoutOrder = 9999, always last regardless of
       how many tabs are added or when

  NEW  16 themes – all fields propagated to every element via
       a registered theme table (_TR system)
  NEW  Animated splash screen (optional, configurable)
  NEW  Window resize by dragging bottom-right corner
  NEW  Signal class with :Once(), returned from Toggle/Slider
  NEW  tab.Accordion() – collapsible subsection
  NEW  tab.SearchBox() – live filtered search input
  NEW  tab.StatusIndicator() – pulsing dot with SetStatus()
  NEW  tab.Table() – scrollable data grid
  NEW  tab.Spinner() – loading animation with show/hide
  NEW  tab.LineChart() – real-time drawn chart with :Push()
  NEW  tab.Tabs() – nested tab group inside a page
  NEW  Notification action buttons support
  NEW  Notification :update() to change content live
  NEW  Tooltip delay (appears after 400 ms hover)
  NEW  UI:SetAccent(color) – override accent at runtime
  NEW  UI:GetTab(title) – returns tab API by name
  NEW  UI:ShowTab(title) – switches to tab by name
  NEW  Config:Watch(key, fn) – fires fn when key changes
  NEW  Watermark clock that updates every second
  NEW  All components: :SetVisible(bool), :SetDisabled(bool)
  NEW  Keybind supports mouse buttons (MouseButton1/2)
  NEW  ColorPicker hex input validated + opacity bar
  NEW  ProgressBar :SetColor(c), animated stripes
  NEW  Stepper hold-to-repeat (hold +/- to accelerate)
  NEW  Dropdown :Search(str) programmatic filter
  NEW  RadioGroup :SetOptions() to rebuild live
  NEW  Badge :Add() / :Remove() / :Clear()
]]

-- ═══════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ═══════════════════════════════════════════════
-- SIGNAL
-- ═══════════════════════════════════════════════
local Signal = {}; Signal.__index = Signal
function Signal.new() return setmetatable({_c={}}, Signal) end
function Signal:Connect(fn)
    local c={_fn=fn,_s=self,Connected=true}
    table.insert(self._c,c)
    function c:Disconnect()
        self.Connected=false
        for i,v in ipairs(self._s._c) do
            if v==self then table.remove(self._s._c,i); break end
        end
    end
    return c
end
function Signal:Fire(...)
    for _,c in ipairs(self._c) do
        if c.Connected then task.spawn(c._fn,...) end
    end
end
function Signal:Once(fn)
    local c; c=self:Connect(function(...) c:Disconnect(); fn(...) end); return c
end
function Signal:Wait()
    local t=coroutine.running(); local c
    c=self:Connect(function(...) c:Disconnect(); task.spawn(t,...) end)
    return coroutine.yield()
end
function Signal:Destroy() self._c={} end

-- ═══════════════════════════════════════════════
-- TWEEN HELPERS
-- ═══════════════════════════════════════════════
local TI={
    fast  =TweenInfo.new(0.13,Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    med   =TweenInfo.new(0.26,Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    slow  =TweenInfo.new(0.46,Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    spring=TweenInfo.new(0.52,Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    sine  =TweenInfo.new(1.20,Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut),
    linear=TweenInfo.new(1.00,Enum.EasingStyle.Linear),
}

local function Tw(obj,info,props)
    if not obj or not obj.Parent then return end
    local ok,t=pcall(TweenService.Create,TweenService,obj,info,props)
    if ok and t then t:Play(); return t end
end
local function FT(o,p) return Tw(o,TI.fast,p)   end
local function MT(o,p) return Tw(o,TI.med,p)    end
local function ST(o,p) return Tw(o,TI.slow,p)   end
local function SP(o,p) return Tw(o,TI.spring,p) end

-- ═══════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════
local U={}

function U.XY(f)
    local ap=f.AbsolutePosition; local as=f.AbsoluteSize
    return math.clamp(Mouse.X-ap.X,0,as.X)/math.max(as.X,1),
           math.clamp(Mouse.Y-ap.Y,0,as.Y)/math.max(as.Y,1)
end

function U.Ripple(p,col)
    if not p or not p.Parent then return end
    local px,py=U.XY(p)
    local r=Instance.new("ImageLabel")
    r.BackgroundTransparency=1; r.Image="rbxassetid://5554831670"
    r.ImageColor3=col or Color3.new(1,1,1); r.ImageTransparency=0.52
    r.ZIndex=p.ZIndex+50; r.Size=UDim2.fromOffset(0,0)
    r.Position=UDim2.fromScale(px,py); r.AnchorPoint=Vector2.new(.5,.5); r.Parent=p
    local sz=math.max(p.AbsoluteSize.X,p.AbsoluteSize.Y)*2.6
    Tw(r,TweenInfo.new(.52,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(sz,sz),ImageTransparency=1})
    task.delay(.56,function() if r.Parent then r:Destroy() end end)
end

function U.Lerp(a,b,t) return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t) end
function U.Contrast(c) return (.299*c.R+.587*c.G+.114*c.B)>.5 and Color3.new(0,0,0) or Color3.new(1,1,1) end
function U.Round(n,d) local m=10^(d or 0); return math.floor(n*m+.5)/m end
function U.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
function U.Has(t,v) for _,x in ipairs(t) do if x==v then return true end end return false end
function U.Copy(t) local c={}; for k,v in pairs(t) do c[k]=type(v)=="table"and U.Copy(v)or v end; return c end
function U.Call(fn,...) if type(fn)~="function" then return end local ok,e=pcall(fn,...); if not ok then warn("[Oxygen] "..tostring(e)) end end
function U.Map(n,a,b,c,d) return c+(d-c)*((n-a)/math.max(b-a,.001)) end

function U.Hex(c)
    return string.format("#%02X%02X%02X",
        U.Clamp(math.floor(c.R*255+.5),0,255),
        U.Clamp(math.floor(c.G*255+.5),0,255),
        U.Clamp(math.floor(c.B*255+.5),0,255))
end
function U.FromHex(h)
    h=h:gsub("#","")
    if #h~=6 then return nil end
    local r=tonumber(h:sub(1,2),16); local g=tonumber(h:sub(3,4),16); local b=tonumber(h:sub(5,6),16)
    if r and g and b then return Color3.fromRGB(r,g,b) end
end

function U.TimeStr()
    local t=os.time(); local h=math.floor(t/3600)%24; local m=math.floor(t/60)%60; local s=t%60
    return string.format("%02d:%02d:%02d",h,m,s)
end

-- ═══════════════════════════════════════════════
-- GUI FACTORY
-- ═══════════════════════════════════════════════
local G={}
function G.Frame(p,col,sz,pos,zi,clips)
    local f=Instance.new("Frame"); f.BackgroundColor3=col or Color3.new(.1,.1,.1)
    f.BorderSizePixel=0; f.Size=sz or UDim2.fromScale(1,1); f.Position=pos or UDim2.fromScale(0,0)
    f.ZIndex=zi or 1; f.ClipsDescendants=clips or false; f.Parent=p; return f
end
function G.Label(p,txt,col,sz,pos,font,ts,xa,zi)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1
    l.Text=txt or ""; l.TextColor3=col or Color3.new(1,1,1)
    l.Size=sz or UDim2.fromScale(1,1); l.Position=pos or UDim2.fromScale(0,0)
    l.Font=font or Enum.Font.Gotham; l.TextSize=ts or 14
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.ZIndex=zi or 2; l.TextTruncate=Enum.TextTruncate.AtEnd; l.Parent=p; return l
end
function G.Btn(p,col,sz,pos,zi)
    local b=Instance.new("ImageButton"); b.BackgroundColor3=col or Color3.new(.2,.2,.2)
    b.BorderSizePixel=0; b.Image="rbxassetid://5554237731"
    b.ScaleType=Enum.ScaleType.Slice; b.SliceCenter=Rect.new(3,3,297,297)
    b.AutoButtonColor=false; b.Size=sz or UDim2.fromScale(1,1)
    b.Position=pos or UDim2.fromScale(0,0); b.ZIndex=zi or 2; b.Parent=p; return b
end
function G.Corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
function G.Stroke(p,col,t) local s=Instance.new("UIStroke"); s.Color=col or Color3.new(1,1,1); s.Thickness=t or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
function G.Pad(p,t,r,b,l) local u=Instance.new("UIPadding"); u.PaddingTop=UDim.new(0,t or 5); u.PaddingRight=UDim.new(0,r or 5); u.PaddingBottom=UDim.new(0,b or 5); u.PaddingLeft=UDim.new(0,l or 5); u.Parent=p; return u end
function G.List(p,dir,ha,va,pad)
    local l=Instance.new("UIListLayout"); l.FillDirection=dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left; l.VerticalAlignment=va or Enum.VerticalAlignment.Top
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,pad or 5); l.Parent=p; return l
end
function G.Grid(p,cellsz,pad)
    local l=Instance.new("UIGridLayout"); l.CellSize=cellsz or UDim2.fromOffset(80,30)
    l.CellPaddingSize=pad or UDim2.fromOffset(4,4); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=p; return l
end
function G.Shadow(p,col,zi)
    local s=Instance.new("ImageLabel"); s.Name="Shadow"; s.BackgroundTransparency=1
    s.Image="rbxassetid://5554236805"; s.ScaleType=Enum.ScaleType.Slice; s.SliceCenter=Rect.new(23,23,277,277)
    s.ImageColor3=col or Color3.new(0,0,0); s.ImageTransparency=.5
    s.Size=UDim2.fromScale(1,1)+UDim2.fromOffset(36,36); s.Position=UDim2.fromOffset(-18,-18)
    s.ZIndex=(zi or 2)-1; s.Parent=p; return s
end
function G.Scroll(p,sz,pos,zi)
    local f=Instance.new("ScrollingFrame"); f.BackgroundTransparency=1; f.BorderSizePixel=0
    f.Size=sz or UDim2.fromScale(1,1); f.Position=pos or UDim2.fromScale(0,0)
    f.CanvasSize=UDim2.fromScale(0,0); f.ScrollBarThickness=3
    f.ScrollingDirection=Enum.ScrollingDirection.Y; f.ZIndex=zi or 2; f.Parent=p; return f
end
function G.AutoCanvas(frame,layout,pad)
    pad=pad or 16
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+pad)
    end)
end

-- ═══════════════════════════════════════════════
-- THEMES  (16, all fields filled)
-- ═══════════════════════════════════════════════
local Themes={}
local function DefTheme(t)
    t.AccentGlow   = t.AccentGlow   or U.Lerp(t.Accent,Color3.new(0,0,0),.45)
    t.NavBarActive = t.NavBarActive or t.Tertiary
    t.CardBg       = t.CardBg       or t.Secondary
    t.TextDis      = t.TextDis      or U.Lerp(t.TextMuted,t.Secondary,.5)
    t.BorderLight  = t.BorderLight  or U.Lerp(t.Border,t.Text,.07)
    t.ScrollBar    = t.ScrollBar    or t.Accent
    t.FontMono     = t.FontMono     or Enum.Font.Code
    return t
end

Themes.Carbon=DefTheme({Name="Carbon",
    Primary=Color3.fromRGB(16,16,22),Secondary=Color3.fromRGB(26,26,36),Tertiary=Color3.fromRGB(38,38,54),
    Accent=Color3.fromRGB(108,68,252),AccentDark=Color3.fromRGB(78,44,198),
    Text=Color3.fromRGB(236,236,245),TextMuted=Color3.fromRGB(136,136,162),TextDark=Color3.fromRGB(8,8,16),
    Success=Color3.fromRGB(48,212,112),Warning=Color3.fromRGB(252,182,38),Error=Color3.fromRGB(252,62,78),Info=Color3.fromRGB(68,172,252),
    Shadow=Color3.fromRGB(0,0,0),Border=Color3.fromRGB(48,48,66),TitleBar=Color3.fromRGB(20,20,28),NavBar=Color3.fromRGB(16,16,24),
    Toggle=Color3.fromRGB(108,68,252),Slider=Color3.fromRGB(108,68,252),Radius=8,Font=Enum.Font.GothamSemibold,FontTitle=Enum.Font.GothamBold})
Themes.Midnight=DefTheme({Name="Midnight",
    Primary=Color3.fromRGB(5,5,9),Secondary=Color3.fromRGB(11,11,18),Tertiary=Color3.fromRGB(18,18,30),
    Accent=Color3.fromRGB(168,88,252),AccentDark=Color3.fromRGB(128,58,218),
    Text=Color3.fromRGB(225,220,242),TextMuted=Color3.fromRGB(115,110,148),TextDark=Color3.fromRGB(5,5,9),
    Success=Color3.fromRGB(72,212,132),Warning=Color3.fromRGB(252,192,42),Error=Color3.fromRGB(252,62,82),Info=Color3.fromRGB(88,172,252),
    Shadow=Color3.fromRGB(0,0,0),Border=Color3.fromRGB(26,22,40),TitleBar=Color3.fromRGB(9,7,15),NavBar=Color3.fromRGB(7,5,12),
    Toggle=Color3.fromRGB(168,88,252),Slider=Color3.fromRGB(168,88,252),Radius=8,Font=Enum.Font.GothamSemibold,FontTitle=Enum.Font.GothamBold})
Themes.Neon=DefTheme({Name="Neon",
    Primary=Color3.fromRGB(3,3,7),Secondary=Color3.fromRGB(9,11,18),Tertiary=Color3.fromRGB(16,18,34),
    Accent=Color3.fromRGB(0,242,188),AccentDark=Color3.fromRGB(0,188,145),
    Text=Color3.fromRGB(208,252,245),TextMuted=Color3.fromRGB(85,168,155),TextDark=Color3.fromRGB(3,3,7),
    Success=Color3.fromRGB(0,252,142),Warning=Color3.fromRGB(252,212,0),Error=Color3.fromRGB(252,42,92),Info=Color3.fromRGB(0,192,252),
    Shadow=Color3.fromRGB(0,215,175),Border=Color3.fromRGB(0,75,62),TitleBar=Color3.fromRGB(7,7,14),NavBar=Color3.fromRGB(5,5,12),
    Toggle=Color3.fromRGB(0,242,188),Slider=Color3.fromRGB(0,242,188),Radius=4,Font=Enum.Font.Code,FontTitle=Enum.Font.Code})
Themes.Ocean=DefTheme({Name="Ocean",
    Primary=Color3.fromRGB(5,14,34),Secondary=Color3.fromRGB(9,22,50),Tertiary=Color3.fromRGB(14,35,74),
    Accent=Color3.fromRGB(22,152,252),AccentDark=Color3.fromRGB(12,112,208),
    Text=Color3.fromRGB(192,225,252),TextMuted=Color3.fromRGB(85,140,195),TextDark=Color3.fromRGB(5,14,34),
    Success=Color3.fromRGB(32,212,132),Warning=Color3.fromRGB(252,192,32),Error=Color3.fromRGB(252,72,72),Info=Color3.fromRGB(22,152,252),
    Shadow=Color3.fromRGB(0,12,52),Border=Color3.fromRGB(20,52,102),TitleBar=Color3.fromRGB(7,18,42),NavBar=Color3.fromRGB(5,14,36),
    Toggle=Color3.fromRGB(22,152,252),Slider=Color3.fromRGB(22,152,252),Radius=8,Font=Enum.Font.GothamSemibold,FontTitle=Enum.Font.GothamBold})
Themes.Forest=DefTheme({Name="Forest",
    Primary=Color3.fromRGB(12,20,14),Secondary=Color3.fromRGB(20,35,22),Tertiary=Color3.fromRGB(30,54,33),
    Accent=Color3.fromRGB(68,192,90),AccentDark=Color3.fromRGB(46,148,65),
    Text=Color3.fromRGB(202,235,207),TextMuted=Color3.fromRGB(105,162,115),TextDark=Color3.fromRGB(12,20,14),
    Success=Color3.fromRGB(68,192,90),Warning=Color3.fromRGB(212,182,42),Error=Color3.fromRGB(212,72,72),Info=Color3.fromRGB(72,172,212),
    Shadow=Color3.fromRGB(2,10,4),Border=Color3.fromRGB(34,64,37),TitleBar=Color3.fromRGB(16,26,18),NavBar=Color3.fromRGB(12,22,14),
    Toggle=Color3.fromRGB(68,192,90),Slider=Color3.fromRGB(68,192,90),Radius=6,Font=Enum.Font.Gotham,FontTitle=Enum.Font.GothamBold})
Themes.Mocha=DefTheme({Name="Mocha",
    Primary=Color3.fromRGB(36,26,16),Secondary=Color3.fromRGB(55,42,26),Tertiary=Color3.fromRGB(78,59,40),
    Accent=Color3.fromRGB(192,145,88),AccentDark=Color3.fromRGB(155,112,62),
    Text=Color3.fromRGB(240,225,207),TextMuted=Color3.fromRGB(165,138,108),TextDark=Color3.fromRGB(36,26,16),
    Success=Color3.fromRGB(72,178,98),Warning=Color3.fromRGB(208,168,38),Error=Color3.fromRGB(202,62,62),Info=Color3.fromRGB(92,162,212),
    Shadow=Color3.fromRGB(12,8,3),Border=Color3.fromRGB(84,62,42),TitleBar=Color3.fromRGB(46,32,20),NavBar=Color3.fromRGB(38,26,16),
    Toggle=Color3.fromRGB(192,145,88),Slider=Color3.fromRGB(192,145,88),Radius=8,Font=Enum.Font.Gotham,FontTitle=Enum.Font.GothamBold})
Themes.Dracula=DefTheme({Name="Dracula",
    Primary=Color3.fromRGB(40,42,54),Secondary=Color3.fromRGB(48,50,64),Tertiary=Color3.fromRGB(58,60,76),
    Accent=Color3.fromRGB(189,147,249),AccentDark=Color3.fromRGB(148,108,215),
    Text=Color3.fromRGB(248,248,242),TextMuted=Color3.fromRGB(146,146,146),TextDark=Color3.fromRGB(40,42,54),
    Success=Color3.fromRGB(80,250,123),Warning=Color3.fromRGB(241,250,140),Error=Color3.fromRGB(255,85,85),Info=Color3.fromRGB(139,233,253),
    Shadow=Color3.fromRGB(8,8,12),Border=Color3.fromRGB(66,68,86),TitleBar=Color3.fromRGB(44,46,60),NavBar=Color3.fromRGB(38,40,52),
    Toggle=Color3.fromRGB(189,147,249),Slider=Color3.fromRGB(189,147,249),Radius=6,Font=Enum.Font.GothamSemibold,FontTitle=Enum.Font.GothamBold})
Themes.Blood=DefTheme({Name="Blood",
    Primary=Color3.fromRGB(12,3,3),Secondary=Color3.fromRGB(25,7,7),Tertiary=Color3.fromRGB(44,12,12),
    Accent=Color3.fromRGB(218,32,48),AccentDark=Color3.fromRGB(172,20,32),
    Text=Color3.fromRGB(243,208,208),TextMuted=Color3.fromRGB(155,96,96),TextDark=Color3.fromRGB(12,3,3),
    Success=Color3.fromRGB(58,188,88),Warning=Color3.fromRGB(228,172,32),Error=Color3.fromRGB(218,32,48),Info=Color3.fromRGB(78,158,232),
    Shadow=Color3.fromRGB(0,0,0),Border=Color3.fromRGB(52,16,16),TitleBar=Color3.fromRGB(20,5,5),NavBar=Color3.fromRGB(14,3,3),
    Toggle=Color3.fromRGB(218,32,48),Slider=Color3.fromRGB(218,32,48),Radius=5,Font=Enum.Font.GothamSemibold,FontTitle=Enum.Font.GothamBold})
Themes.Monochrome=DefTheme({Name="Monochrome",
    Primary=Color3.fromRGB(10,10,10),Secondary=Color3.fromRGB(20,20,20),Tertiary=Color3.fromRGB(33,33,33),
    Accent=Color3.fromRGB(218,218,218),AccentDark=Color3.fromRGB(162,162,162),
    Text=Color3.fromRGB(238,238,238),TextMuted=Color3.fromRGB(126,126,126),TextDark=Color3.fromRGB(10,10,10),
    Success=Color3.fromRGB(185,185,185),Warning=Color3.fromRGB(205,205,205),Error=Color3.fromRGB(255,255,255),Info=Color3.fromRGB(150,150,150),
    Shadow=Color3.fromRGB(0,0,0),Border=Color3.fromRGB(44,44,44),TitleBar=Color3.fromRGB(16,16,16),NavBar=Color3.fromRGB(12,12,12),
    Toggle=Color3.fromRGB(205,205,205),Slider=Color3.fromRGB(205,205,205),Radius=4,Font=Enum.Font.GothamSemibold,FontTitle=Enum.Font.GothamBold})
Themes.Slate=DefTheme({Name="Slate",
    Primary=Color3.fromRGB(28,33,40),Secondary=Color3.fromRGB(38,44,53),Tertiary=Color3.fromRGB(50,58,68),
    Accent=Color3.fromRGB(92,178,228),AccentDark=Color3.fromRGB(66,142,192),
    Text=Color3.fromRGB(212,222,232),TextMuted=Color3.fromRGB(115,135,155),TextDark=Color3.fromRGB(28,33,40),
    Success=Color3.fromRGB(62,198,118),Warning=Color3.fromRGB(242,182,38),Error=Color3.fromRGB(232,72,78),Info=Color3.fromRGB(92,178,228),
    Shadow=Color3.fromRGB(8,10,14),Border=Color3.fromRGB(52,62,74),TitleBar=Color3.fromRGB(33,38,48),NavBar=Color3.fromRGB(26,30,38),
    Toggle=Color3.fromRGB(92,178,228),Slider=Color3.fromRGB(92,178,228),Radius=6,Font=Enum.Font.GothamSemibold,FontTitle=Enum.Font.GothamBold})
Themes.Light=DefTheme({Name="Light",
    Primary=Color3.fromRGB(244,244,250),Secondary=Color3.fromRGB(230,230,240),Tertiary=Color3.fromRGB(212,212,228),
    Accent=Color3.fromRGB(90,50,235),AccentDark=Color3.fromRGB(66,34,196),
    Text=Color3.fromRGB(20,20,32),TextMuted=Color3.fromRGB(108,108,138),TextDark=Color3.fromRGB(244,244,250),
    Success=Color3.fromRGB(32,175,92),Warning=Color3.fromRGB(198,155,20),Error=Color3.fromRGB(198,42,58),Info=Color3.fromRGB(50,132,218),
    Shadow=Color3.fromRGB(136,136,172),Border=Color3.fromRGB(188,188,212),TitleBar=Color3.fromRGB(90,50,235),NavBar=Color3.fromRGB(78,42,215),
    Toggle=Color3.fromRGB(90,50,235),Slider=Color3.fromRGB(90,50,235),Radius=10,Font=Enum.Font.Gotham,FontTitle=Enum.Font.GothamBold})
Themes.Rose=DefTheme({Name="Rose",
    Primary=Color3.fromRGB(254,242,246),Secondary=Color3.fromRGB(253,225,236),Tertiary=Color3.fromRGB(250,205,222),
    Accent=Color3.fromRGB(212,50,92),AccentDark=Color3.fromRGB(172,33,70),
    Text=Color3.fromRGB(46,16,26),TextMuted=Color3.fromRGB(142,88,108),TextDark=Color3.fromRGB(254,242,246),
    Success=Color3.fromRGB(52,172,92),Warning=Color3.fromRGB(212,142,26),Error=Color3.fromRGB(192,33,53),Info=Color3.fromRGB(72,132,212),
    Shadow=Color3.fromRGB(172,72,92),Border=Color3.fromRGB(212,170,182),TitleBar=Color3.fromRGB(212,50,92),NavBar=Color3.fromRGB(192,42,80),
    Toggle=Color3.fromRGB(212,50,92),Slider=Color3.fromRGB(212,50,92),Radius=12,Font=Enum.Font.Gotham,FontTitle=Enum.Font.GothamBold})
Themes.Ice=DefTheme({Name="Ice",
    Primary=Color3.fromRGB(236,246,254),Secondary=Color3.fromRGB(212,235,253),Tertiary=Color3.fromRGB(185,220,250),
    Accent=Color3.fromRGB(48,135,215),AccentDark=Color3.fromRGB(30,103,180),
    Text=Color3.fromRGB(16,46,86),TextMuted=Color3.fromRGB(88,132,176),TextDark=Color3.fromRGB(236,246,254),
    Success=Color3.fromRGB(32,175,112),Warning=Color3.fromRGB(198,155,22),Error=Color3.fromRGB(198,48,62),Info=Color3.fromRGB(48,135,215),
    Shadow=Color3.fromRGB(88,152,212),Border=Color3.fromRGB(162,208,243),TitleBar=Color3.fromRGB(48,135,215),NavBar=Color3.fromRGB(40,120,198),
    Toggle=Color3.fromRGB(48,135,215),Slider=Color3.fromRGB(48,135,215),Radius=12,Font=Enum.Font.Gotham,FontTitle=Enum.Font.GothamBold})
Themes.Sakura=DefTheme({Name="Sakura",
    Primary=Color3.fromRGB(254,241,247),Secondary=Color3.fromRGB(251,223,238),Tertiary=Color3.fromRGB(247,202,226),
    Accent=Color3.fromRGB(222,97,158),AccentDark=Color3.fromRGB(185,70,125),
    Text=Color3.fromRGB(60,20,43),TextMuted=Color3.fromRGB(158,104,135),TextDark=Color3.fromRGB(254,241,247),
    Success=Color3.fromRGB(78,185,112),Warning=Color3.fromRGB(212,165,36),Error=Color3.fromRGB(212,53,78),Info=Color3.fromRGB(102,145,222),
    Shadow=Color3.fromRGB(198,118,157),Border=Color3.fromRGB(228,182,207),TitleBar=Color3.fromRGB(222,97,158),NavBar=Color3.fromRGB(202,80,140),
    Toggle=Color3.fromRGB(222,97,158),Slider=Color3.fromRGB(222,97,158),Radius=14,Font=Enum.Font.Gotham,FontTitle=Enum.Font.GothamBold})
Themes.Candy=DefTheme({Name="Candy",
    Primary=Color3.fromRGB(254,238,254),Secondary=Color3.fromRGB(249,217,253),Tertiary=Color3.fromRGB(240,192,254),
    Accent=Color3.fromRGB(195,58,252),AccentDark=Color3.fromRGB(155,36,207),
    Text=Color3.fromRGB(50,7,70),TextMuted=Color3.fromRGB(152,95,175),TextDark=Color3.fromRGB(254,238,254),
    Success=Color3.fromRGB(58,202,118),Warning=Color3.fromRGB(252,178,28),Error=Color3.fromRGB(252,58,88),Info=Color3.fromRGB(58,178,252),
    Shadow=Color3.fromRGB(178,78,218),Border=Color3.fromRGB(225,182,245),TitleBar=Color3.fromRGB(195,58,252),NavBar=Color3.fromRGB(172,44,225),
    Toggle=Color3.fromRGB(195,58,252),Slider=Color3.fromRGB(195,58,252),Radius=14,Font=Enum.Font.Gotham,FontTitle=Enum.Font.GothamBold})

-- ═══════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════
local Cfg={}; Cfg.__index=Cfg
function Cfg.new(name)
    local s=setmetatable({_n=name,_f=name.."_OxCfg.json",_d={},_watchers={}},Cfg)
    s:_load(); return s
end
function Cfg:_load()
    pcall(function() if readfile then local r=readfile(self._f); self._d=HttpService:JSONDecode(r) or {} end end)
    self._d=self._d or {}
end
function Cfg:_save()
    pcall(function() if writefile then writefile(self._f,HttpService:JSONEncode(self._d)) end end)
end
function Cfg:Set(k,v)
    self._d[k]=v; self:_save()
    if self._watchers[k] then for _,fn in ipairs(self._watchers[k]) do U.Call(fn,v) end end
end
function Cfg:Get(k,def)  return self._d[k]~=nil and self._d[k] or def end
function Cfg:Del(k)      self._d[k]=nil; self:_save() end
function Cfg:Reset()     self._d={}; self:_save() end
function Cfg:All()       return U.Copy(self._d) end
function Cfg:Watch(k,fn) self._watchers[k]=self._watchers[k] or {}; table.insert(self._watchers[k],fn) end
function Cfg:Export()    local ok,s=pcall(HttpService.JSONEncode,HttpService,self._d); return ok and s or "{}" end
function Cfg:Import(j)   local ok,d=pcall(HttpService.JSONDecode,HttpService,j); if ok and type(d)=="table" then self._d=d; self:_save(); return true end return false end
function Cfg:FromClipboard() local ok,t=pcall(function() return getclipboard() end); if ok and t then return self:Import(t) end return false end

-- ═══════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════
local NPOS={
    BottomRight={ap=Vector2.new(1,1),pos=UDim2.new(1,-12,1,-12),va=Enum.VerticalAlignment.Bottom},
    TopRight   ={ap=Vector2.new(1,0),pos=UDim2.new(1,-12,0,12), va=Enum.VerticalAlignment.Top},
    BottomLeft ={ap=Vector2.new(0,1),pos=UDim2.new(0,12,1,-12), va=Enum.VerticalAlignment.Bottom},
    TopLeft    ={ap=Vector2.new(0,0),pos=UDim2.new(0,12,0,12),  va=Enum.VerticalAlignment.Top},
}
local NTYPES={
    success={icon="✓",col=Color3.fromRGB(46,196,108)},
    warning={icon="!",col=Color3.fromRGB(235,168,26)},
    error  ={icon="✕",col=Color3.fromRGB(230,55,72)},
    info   ={icon="i",col=Color3.fromRGB(60,160,248)},
}
local NotiSys={}; NotiSys.__index=NotiSys
function NotiSys.new(sg,pos)
    local s=setmetatable({_i=0},NotiSys)
    local pd=NPOS[pos] or NPOS.BottomRight
    s._cont=G.Frame(sg,Color3.new(0,0,0),UDim2.fromOffset(330,0),pd.pos,900)
    s._cont.BackgroundTransparency=1; s._cont.AnchorPoint=pd.ap
    local l=G.List(s._cont,nil,nil,pd.va,8)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s._cont.Size=UDim2.fromOffset(330,l.AbsoluteContentSize.Y+10)
    end)
    return s
end
function NotiSys:Push(cfg,th)
    local title =cfg.Title or ""; local desc =cfg.Description or ""
    local ntype =cfg.Type or "info"; local dur=cfg.Duration or 4
    local cb    =cfg.Callback; local btns=cfg.Buttons or {}
    local td    =NTYPES[ntype] or NTYPES.info
    self._i+=1
    local extraH=#btns>0 and 30 or 0
    local card=G.Frame(self._cont,th.Secondary,UDim2.fromOffset(330,68+extraH))
    card.ClipsDescendants=true; card.ZIndex=900; card.LayoutOrder=self._i
    G.Corner(card,10); G.Stroke(card,th.Border,1); G.Shadow(card,th.Shadow,900)
    G.Frame(card,td.col,UDim2.fromOffset(4,68+extraH),nil,901)
    local icBg=G.Frame(card,U.Lerp(td.col,Color3.new(0,0,0),.62),UDim2.fromOffset(28,28),UDim2.fromOffset(14,20),901)
    G.Corner(icBg,14)
    G.Label(icBg,td.icon,td.col,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,16,Enum.TextXAlignment.Center,902)
    local tl=G.Label(card,title,th.Text,UDim2.fromOffset(242,20),UDim2.fromOffset(52,8),Enum.Font.GothamBold,14,Enum.TextXAlignment.Left,901)
    local dl=G.Label(card,desc,th.TextMuted,UDim2.fromOffset(257,34),UDim2.fromOffset(52,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,901)
    dl.TextWrapped=true
    local xb=Instance.new("TextButton"); xb.BackgroundTransparency=1; xb.Size=UDim2.fromOffset(22,22); xb.Position=UDim2.new(1,-28,0,4); xb.Text="×"; xb.TextColor3=th.TextMuted; xb.Font=Enum.Font.GothamBold; xb.TextSize=20; xb.ZIndex=902; xb.Parent=card
    -- progress bar
    local pf=G.Frame(card,td.col,UDim2.fromOffset(0,3)); pf.Position=UDim2.new(0,0,1,-3); pf.ZIndex=901
    Tw(pf,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.fromOffset(330,3)})
    -- action buttons
    for i,btn in ipairs(btns) do
        local bb=Instance.new("TextButton"); bb.BackgroundColor3=th.Accent; bb.BorderSizePixel=0
        bb.Size=UDim2.fromOffset(80,22); bb.Position=UDim2.fromOffset(52+(i-1)*86,68+4)
        bb.Text=btn.label or "OK"; bb.TextColor3=th.TextDark; bb.Font=Enum.Font.GothamBold; bb.TextSize=11; bb.ZIndex=902; bb.Parent=card
        G.Corner(bb,5)
        bb.MouseButton1Click:Connect(function() U.Call(btn.callback) end)
    end
    card.Position=UDim2.fromOffset(345,0); SP(card,{Position=UDim2.fromOffset(0,0)})
    local gone=false
    local function dismiss()
        if gone then return end; gone=true
        FT(card,{Position=UDim2.fromOffset(345,0)})
        task.delay(.2,function() if card.Parent then card:Destroy() end end)
    end
    xb.MouseButton1Click:Connect(dismiss)
    if cb then card.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then U.Call(cb); dismiss() end end) end
    task.delay(dur,dismiss)
    return {
        Dismiss=dismiss,
        Update=function(_,t,d) tl.Text=t or title; dl.Text=d or desc end
    }
end

-- ═══════════════════════════════════════════════
-- TOOLTIP  (delayed)
-- ═══════════════════════════════════════════════
local function MkTooltip(el,text,th,sg)
    if not text or text=="" then return end
    local tip,mc,timer
    el.MouseEnter:Connect(function()
        timer=task.delay(.4,function()
            if tip then tip:Destroy() end
            local tw=TextService:GetTextSize(text,11,Enum.Font.Gotham,Vector2.new(9999,9999)).X
            tip=G.Frame(sg,th.Tertiary,UDim2.fromOffset(tw+18,24),nil,9500)
            G.Corner(tip,5); G.Stroke(tip,th.Border,1); G.Shadow(tip,th.Shadow,9500)
            G.Label(tip,text,th.Text,UDim2.fromScale(1,1),nil,Enum.Font.Gotham,11,Enum.TextXAlignment.Center,9501)
            tip.Position=UDim2.fromOffset(Mouse.X+14,Mouse.Y-32)
            mc=Mouse.Moved:Connect(function()
                if tip and tip.Parent then tip.Position=UDim2.fromOffset(Mouse.X+14,Mouse.Y-32) end
            end)
        end)
    end)
    el.MouseLeave:Connect(function()
        if timer then task.cancel(timer); timer=nil end
        if mc then mc:Disconnect(); mc=nil end
        if tip then tip:Destroy(); tip=nil end
    end)
end

-- ═══════════════════════════════════════════════
-- SPLASH
-- ═══════════════════════════════════════════════
local function ShowSplash(sg,cfg,th,onDone)
    local title   =cfg.Title    or "Oxygen"
    local subtitle=cfg.Subtitle or "Loading..."
    local version =cfg.Version  or "beta 0.0.1"
    local dur     =cfg.Duration or 2.8
    local logoIcon=cfg.Icon     or "⚡"

    local overlay=G.Frame(sg,Color3.new(0,0,0),UDim2.fromScale(1,1),nil,1000)
    overlay.BackgroundTransparency=1; FT(overlay,{BackgroundTransparency=0})

    local card=G.Frame(sg,th.Secondary,UDim2.fromOffset(30,30),UDim2.fromScale(.5,.5),1001)
    card.AnchorPoint=Vector2.new(.5,.5); G.Corner(card,16); G.Shadow(card,th.Shadow,1001); G.Stroke(card,th.Border,1)
    card.BackgroundTransparency=1
    SP(card,{Size=UDim2.fromOffset(400,230),BackgroundTransparency=0})

    task.delay(.1,function()
        -- icon circle
        local circle=G.Frame(card,th.Accent,UDim2.fromOffset(64,64),UDim2.fromOffset(168,28),1002)
        circle.BackgroundTransparency=1; G.Corner(circle,32)
        G.Label(circle,logoIcon,th.TextDark,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,26,Enum.TextXAlignment.Center,1003)
        SP(circle,{BackgroundTransparency=0})
        -- pulse ring
        local ring=G.Frame(card,th.Accent,UDim2.fromOffset(64,64),UDim2.fromOffset(168,28),1001)
        ring.BackgroundTransparency=.82; G.Corner(ring,32)
        task.spawn(function()
            while ring and ring.Parent do
                Tw(ring,TweenInfo.new(.9,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(90,90),Position=UDim2.fromOffset(155,16),BackgroundTransparency=1})
                task.wait(.9); ring.Size=UDim2.fromOffset(64,64); ring.Position=UDim2.fromOffset(168,28); ring.BackgroundTransparency=.82; task.wait(.1)
            end
        end)
    end)
    task.delay(.15,function()
        local tl=G.Label(card,title,th.Text,UDim2.fromOffset(400,38),UDim2.fromOffset(0,100),th.FontTitle,28,Enum.TextXAlignment.Center,1002)
        tl.TextTransparency=1; FT(tl,{TextTransparency=0})
        local sl=G.Label(card,subtitle,th.TextMuted,UDim2.fromOffset(400,20),UDim2.fromOffset(0,138),Enum.Font.Gotham,13,Enum.TextXAlignment.Center,1002)
        sl.TextTransparency=1; FT(sl,{TextTransparency=0})
        local vl=G.Label(card,version,th.Accent,UDim2.fromOffset(400,16),UDim2.fromOffset(0,158),Enum.Font.GothamBold,11,Enum.TextXAlignment.Center,1002)
        vl.TextTransparency=1; FT(vl,{TextTransparency=0})
    end)
    task.delay(.25,function()
        local bg=G.Frame(card,th.Tertiary,UDim2.fromOffset(336,4),UDim2.fromOffset(32,196),1002); G.Corner(bg,2)
        local fill=G.Frame(bg,th.Accent,UDim2.fromOffset(0,4),nil,1003); G.Corner(fill,2)
        Tw(fill,TweenInfo.new(dur-.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(336,4)})
    end)
    task.delay(dur,function()
        FT(card,{BackgroundTransparency=1}); FT(overlay,{BackgroundTransparency=1})
        task.delay(.2,function() card:Destroy(); overlay:Destroy(); if onDone then onDone() end end)
    end)
end

-- ═══════════════════════════════════════════════
-- MAIN LIBRARY
-- ═══════════════════════════════════════════════
local Oxygen={}; Oxygen.__index=Oxygen
Oxygen.Version="beta 0.0.1"; Oxygen.Themes=Themes

function Oxygen.new(config)
    local self=setmetatable({},Oxygen)
    config=config or {}
    self.Title     =config.Title       or "Oxygen"
    self.Subtitle  =config.Subtitle    or "beta 0.0.1"
    self.ThemeName =config.Theme       or "Carbon"
    self.SizeX     =config.SizeX       or 580
    self.SizeY     =config.SizeY       or 420
    self.DoSave    =config.SaveConfig  ~=false
    self.CfgName   =config.ConfigName  or self.Title
    self.ShowWM    =config.Watermark   ~=false
    self.ToggleKey =config.ToggleKey   or Enum.KeyCode.RightControl
    self.MinKey    =config.MinimizeKey or Enum.KeyCode.RightShift
    self.NotifPos  =config.NotifPos    or "BottomRight"
    self.Splash    =config.Splash
    self.SplashDur =(type(config.Splash)=="table" and config.Splash.Duration) or 2.8
    self.Theme     =Themes[self.ThemeName] or Themes.Carbon
    self.Tabs      ={}
    self._conns    ={}
    self._themed   ={}
    self._tabAPIs  ={}
    self.Visible   =true
    self.Minimized =false
    self.ActiveTab =1
    self.ThemeChanged=Signal.new()
    self.TabChanged  =Signal.new()

    if self.DoSave then
        self.Store=Cfg.new(self.CfgName)
        local saved=self.Store:Get("theme",nil)
        if saved and Themes[saved] then self.ThemeName=saved; self.Theme=Themes[saved] end
    end

    self:_Build()
    self:_Keys()
    self:_Watermark()

    if self.Splash then
        self.Win.Visible=false
        if self._wmF then self._wmF.Visible=false end
        ShowSplash(self.SG,{
            Title   =type(self.Splash)=="table" and(self.Splash.Title    or self.Title)   or self.Title,
            Subtitle=type(self.Splash)=="table" and(self.Splash.Subtitle or self.Subtitle)or self.Subtitle,
            Icon    =type(self.Splash)=="table" and self.Splash.Icon or "⚡",
            Version =Oxygen.Version,Duration=self.SplashDur,
        },self.Theme,function()
            self.Win.Visible=true
            if self._wmF then self._wmF.Visible=self.ShowWM end
            SP(self.Win,{Size=UDim2.fromOffset(self.SizeX,self.SizeY)})
        end)
        self.Win.Size=UDim2.fromOffset(0,0)
    end

    self:_BuildSettings()
    return self
end

function Oxygen:_C(c) table.insert(self._conns,c) end
function Oxygen:_TR(obj,prop,role) if obj then table.insert(self._themed,{obj=obj,prop=prop,role=role}) end end

function Oxygen:_ProtectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent=CoreGui
        elseif gethui then gui.Parent=gethui()
        else gui.Parent=CoreGui end
    end)
    if not gui.Parent then gui.Parent=LP:WaitForChild("PlayerGui") end
end

-- ─── BUILD WINDOW ─────────────────────────────
function Oxygen:_Build()
    local th=self.Theme
    self.SG=Instance.new("ScreenGui"); self.SG.Name="OxygenUI_"..self.Title
    self.SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; self.SG.ResetOnSpawn=false
    self:_ProtectGui(self.SG)
    self.NotifsObj=NotiSys.new(self.SG,self.NotifPos)

    self.Win=G.Frame(self.SG,th.Primary,UDim2.fromOffset(self.SizeX,self.SizeY),UDim2.fromScale(.5,.5),10)
    self.Win.AnchorPoint=Vector2.new(.5,.5); self.Win.ClipsDescendants=true
    G.Corner(self.Win,th.Radius); G.Shadow(self.Win,th.Shadow,10)
    self._winStroke=G.Stroke(self.Win,th.Border,1)
    self:_TR(self.Win,"BackgroundColor3","Primary"); self:_TR(self._winStroke,"Color","Border")
    if not self.Splash then self.Win.Size=UDim2.fromOffset(0,0); SP(self.Win,{Size=UDim2.fromOffset(self.SizeX,self.SizeY)}) end

    -- title bar
    self.TBar=G.Frame(self.Win,th.TitleBar,UDim2.fromOffset(self.SizeX,44),nil,15)
    self:_TR(self.TBar,"BackgroundColor3","TitleBar")
    self._stripe=G.Frame(self.TBar,th.Accent,UDim2.fromOffset(self.SizeX,2),UDim2.new(0,0,1,-2),16)
    self:_TR(self._stripe,"BackgroundColor3","Accent")
    self._pip=G.Frame(self.TBar,th.Accent,UDim2.fromOffset(8,8),UDim2.fromOffset(12,18),16); G.Corner(self._pip,4)
    self:_TR(self._pip,"BackgroundColor3","Accent")
    self._tLbl=G.Label(self.TBar,self.Title,th.Text,UDim2.fromOffset(240,26),UDim2.fromOffset(28,4),th.FontTitle,16,Enum.TextXAlignment.Left,16)
    self:_TR(self._tLbl,"TextColor3","Text")
    self._sLbl=G.Label(self.TBar,self.Subtitle,th.TextMuted,UDim2.fromOffset(240,14),UDim2.fromOffset(28,25),Enum.Font.Gotham,10,Enum.TextXAlignment.Left,16)
    self:_TR(self._sLbl,"TextColor3","TextMuted")

    -- window buttons
    local function WBtn(xo,bg,ic)
        local b=Instance.new("TextButton"); b.BackgroundColor3=bg; b.BorderSizePixel=0
        b.Size=UDim2.fromOffset(12,12); b.Position=UDim2.new(1,xo,.5,-6); b.Text=""; b.ZIndex=17; b.Parent=self.TBar; G.Corner(b,6)
        local ico=G.Label(b,ic,Color3.new(0,0,0),UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,9,Enum.TextXAlignment.Center,18)
        ico.TextTransparency=1
        b.MouseEnter:Connect(function() FT(ico,{TextTransparency=0}) end)
        b.MouseLeave:Connect(function() FT(ico,{TextTransparency=1}) end)
        return b
    end
    WBtn(-22,Color3.fromRGB(255,88,78),"×").MouseButton1Click:Connect(function() self:Destroy() end)
    WBtn(-40,Color3.fromRGB(255,183,28),"−").MouseButton1Click:Connect(function() self:ToggleMinimize() end)
    WBtn(-58,Color3.fromRGB(38,200,64),"⤢").MouseButton1Click:Connect(function() self:Toggle() end)

    -- drag
    local drag,ds,ws
    self.TBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; ds=Vector2.new(Mouse.X,Mouse.Y); ws=self.Win.Position end
    end)
    self:_C(UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=Vector2.new(Mouse.X-ds.X,Mouse.Y-ds.Y)
            self.Win.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
        end
    end))
    self:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end))

    -- resize handle
    local rh=G.Frame(self.Win,Color3.new(0,0,0),UDim2.fromOffset(16,16),UDim2.new(1,-16,1,-16),30); rh.BackgroundTransparency=1
    local ric=G.Label(rh,"⤡",th.TextMuted,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,12,Enum.TextXAlignment.Center,31)
    self:_TR(ric,"TextColor3","TextMuted")
    local res,rS,rW
    rh.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then res=true; rS=Vector2.new(Mouse.X,Mouse.Y); rW=self.Win.AbsoluteSize end end)
    self:_C(UserInputService.InputChanged:Connect(function(i)
        if res and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=Vector2.new(Mouse.X-rS.X,Mouse.Y-rS.Y)
            local nx=math.max(rW.X+d.X,380); local ny=math.max(rW.Y+d.Y,260)
            self.SizeX=nx; self.SizeY=ny; self.Win.Size=UDim2.fromOffset(nx,ny)
            self.TBar.Size=UDim2.fromOffset(nx,44); self._stripe.Size=UDim2.fromOffset(nx,2)
            self.SideBar.Size=UDim2.fromOffset(130,ny-44)
            self.Content.Size=UDim2.fromOffset(nx-130,ny-44)
            for _,t in ipairs(self.Tabs) do t.Page.Size=UDim2.fromOffset(nx-150,ny-82) end
        end
    end))
    self:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then res=false end end))

    -- sidebar
    self.SideBar=G.Frame(self.Win,th.NavBar,UDim2.fromOffset(130,self.SizeY-44),UDim2.fromOffset(0,44),5)
    self._sbStroke=G.Stroke(self.SideBar,th.Border,1)
    self:_TR(self.SideBar,"BackgroundColor3","NavBar"); self:_TR(self._sbStroke,"Color","Border")
    self.TabList=G.Scroll(self.SideBar,UDim2.fromScale(1,1),nil,6)
    self.TabList.ScrollBarImageColor3=th.Accent; self:_TR(self.TabList,"ScrollBarImageColor3","Accent")
    G.Pad(self.TabList,8,6,8,6)
    local tll=G.List(self.TabList,nil,nil,nil,4); G.AutoCanvas(self.TabList,tll,16)

    -- content
    self.Content=G.Frame(self.Win,th.Primary,UDim2.fromOffset(self.SizeX-130,self.SizeY-44),UDim2.fromOffset(130,44),3,true)
    self:_TR(self.Content,"BackgroundColor3","Primary")
    self.PageTitle=G.Label(self.Content,"",th.Text,UDim2.fromOffset(self.SizeX-165,28),UDim2.fromOffset(12,4),th.FontTitle,14,Enum.TextXAlignment.Left,4)
    self:_TR(self.PageTitle,"TextColor3","Text")
    self._pgSep=G.Frame(self.Content,th.Border,UDim2.new(1,-24,0,1),UDim2.fromOffset(12,32),4)
    self:_TR(self._pgSep,"BackgroundColor3","Border")
end

-- ─── TAB SYSTEM ───────────────────────────────
function Oxygen:AddTab(config)
    config=config or {}
    local title=config.Title or "Tab"; local icon=config.Icon or "•"
    local th=self.Theme; local idx=#self.Tabs+1

    local btn=Instance.new("TextButton")
    btn.BackgroundColor3=idx==1 and th.NavBarActive or th.NavBar
    btn.BorderSizePixel=0; btn.Size=UDim2.new(1,0,0,34); btn.Text=""
    btn.ZIndex=7; btn.LayoutOrder=idx; btn.Parent=self.TabList; G.Corner(btn,6)

    local ind=G.Frame(btn,th.Accent,UDim2.fromOffset(3,idx==1 and 20 or 0),UDim2.new(0,-1,.5,-(idx==1 and 10 or 0)),8); G.Corner(ind,2)
    local iconL=G.Label(btn,icon,idx==1 and th.Accent or th.TextMuted,UDim2.fromOffset(22,34),UDim2.fromOffset(8,0),Enum.Font.GothamBold,14,Enum.TextXAlignment.Center,8)
    local tabL=G.Label(btn,title,idx==1 and th.Text or th.TextMuted,UDim2.new(1,-38,1,0),UDim2.fromOffset(32,0),th.Font,13,Enum.TextXAlignment.Left,8)

    -- notification badge on tab
    local badge=G.Frame(btn,th.Error,UDim2.fromOffset(16,16),UDim2.new(1,-14,0,2),9); badge.Visible=false; G.Corner(badge,8)
    local badgeL=G.Label(badge,"0",th.TextDark,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,9,Enum.TextXAlignment.Center,10)

    local page=G.Scroll(self.Content,UDim2.fromOffset(self.SizeX-150,self.SizeY-82),UDim2.fromOffset(10,38),4)
    page.ScrollBarImageColor3=th.Accent; page.Visible=(idx==1)
    self:_TR(page,"ScrollBarImageColor3","Accent")
    G.Pad(page,6,6,12,4); local pl=G.List(page,nil,nil,nil,6); G.AutoCanvas(page,pl,24)

    btn.MouseEnter:Connect(function() if self.ActiveTab~=idx then FT(btn,{BackgroundColor3=th.Tertiary}) end end)
    btn.MouseLeave:Connect(function() if self.ActiveTab~=idx then FT(btn,{BackgroundColor3=th.NavBar}) end end)
    btn.MouseButton1Click:Connect(function() self:_Switch(idx) end)

    local entry={Title=title,Btn=btn,Page=page,Icon=iconL,Label=tabL,Ind=ind,Badge=badge,BadgeL=badgeL}
    table.insert(self.Tabs,entry)
    if idx==1 then self.ActiveTab=1; self.PageTitle.Text=title end

    local tabAPI=self:_API(idx,page,th)
    -- tab badge helpers
    tabAPI.SetBadge=function(_,n)
        if n and n>0 then badge.Visible=true; badgeL.Text=tostring(n>99 and "99+" or n)
        else badge.Visible=false end
    end
    self._tabAPIs[title]=tabAPI
    return tabAPI
end

function Oxygen:_Switch(idx)
    local th=self.Theme; self.ActiveTab=idx
    for i,t in ipairs(self.Tabs) do
        local a=(i==idx); t.Page.Visible=a
        FT(t.Btn,  {BackgroundColor3=a and th.NavBarActive or th.NavBar})
        FT(t.Icon, {TextColor3=a and th.Accent or th.TextMuted})
        FT(t.Label,{TextColor3=a and th.Text   or th.TextMuted})
        FT(t.Ind,  {Size=UDim2.fromOffset(3,a and 20 or 0),Position=UDim2.new(0,-1,.5,a and -10 or 0)})
    end
    self.PageTitle.Text=self.Tabs[idx].Title
    self.TabChanged:Fire(idx,self.Tabs[idx].Title)
end

function Oxygen:GetTab(title)   return self._tabAPIs[title] end
function Oxygen:ShowTab(title)
    for i,t in ipairs(self.Tabs) do if t.Title==title then self:_Switch(i); return end end
end

-- ─── SETTINGS TAB (ALWAYS LAST) ───────────────
function Oxygen:_BuildSettings()
    local s=self:AddTab({Title="Settings",Icon="⚙"})
    s.Section({Title="Appearance"})
    local names={}; for n in pairs(Themes) do table.insert(names,n) end; table.sort(names)
    s.Dropdown({Title="Theme",Description="Applies instantly to every element",Options=names,Default=self.ThemeName,
        Callback=function(v) self:SetTheme(v) end})
    s.Section({Title="Keybinds"})
    s.Keybind({Title="Toggle UI",  Description="Show / hide the window",   Default=self.ToggleKey, Callback=function(k) self.ToggleKey=k end})
    s.Keybind({Title="Minimize",   Description="Collapse to title bar",    Default=self.MinKey,    Callback=function(k) self.MinKey=k end})
    s.Section({Title="Window"})
    s.Toggle({Title="Watermark",Description="Bottom-left info strip",Default=self.ShowWM,
        Callback=function(v) self.ShowWM=v; if self._wmF then self._wmF.Visible=v end end})
    s.Section({Title="Notifications"})
    s.RadioGroup({Title="Position",Options={"BottomRight","TopRight","BottomLeft","TopLeft"},Default=self.NotifPos,
        Callback=function(pos)
            self.NotifPos=pos
            if self.NotifsObj and self.NotifsObj._cont then self.NotifsObj._cont:Destroy() end
            self.NotifsObj=NotiSys.new(self.SG,pos)
        end})
    s.Section({Title="Configuration"})
    s.Button({Title="Reset Config",    Description="Wipe all saved settings",       Callback=function() if self.DoSave then self.Store:Reset(); self:Notify({Title="Reset",Description="Cleared.",Type="warning"}) end end})
    s.Button({Title="Export Config",   Description="Copy JSON to clipboard",        Callback=function() if self.DoSave then pcall(function() setclipboard(self.Store:Export()) end); self:Notify({Title="Exported",Description="Config copied.",Type="success"}) end end})
    s.Button({Title="Import Config",   Description="Paste JSON from clipboard",     Callback=function() if self.DoSave then local ok=self.Store:FromClipboard(); self:Notify(ok and {Title="Imported",Type="success"} or {Title="Failed",Description="No valid config in clipboard.",Type="error"}) end end})
    s.Section({Title="About"})
    s.Label({Title="Oxygen UI Library  •  "..Oxygen.Version})
    s.Label({Title="github.com/oxygen015/roblox-modules"})
    s.Label({Title=tostring(#names).." themes available"})

    -- PIN SETTINGS TO LAST ─────────────────────
    local N=#self.Tabs
    for i=1,N-1 do self.Tabs[i].Btn.LayoutOrder=i end
    self.Tabs[N].Btn.LayoutOrder=9999
    -- switch to first real tab
    if N>1 then
        self.ActiveTab=1
        for i,t in ipairs(self.Tabs) do t.Page.Visible=(i==1) end
        self.PageTitle.Text=self.Tabs[1].Title
    end
end

-- ─── KEYS + WATERMARK ─────────────────────────
function Oxygen:_Keys()
    self:_C(UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==self.ToggleKey  then self:Toggle() end
        if i.KeyCode==self.MinKey     then self:ToggleMinimize() end
    end))
end

function Oxygen:_Watermark()
    local th=self.Theme
    local wm=G.Frame(self.SG,th.Secondary,UDim2.fromOffset(202,24),UDim2.new(0,10,1,-34),200)
    G.Corner(wm,6); G.Stroke(wm,th.Border,1); wm.Visible=self.ShowWM
    local wl=G.Label(wm,"⚡ Oxygen  •  "..self.Title,th.TextMuted,UDim2.fromScale(1,1),nil,Enum.Font.Gotham,11,Enum.TextXAlignment.Center,201)
    self:_TR(wm,"BackgroundColor3","Secondary"); self:_TR(wl,"TextColor3","TextMuted")
    self._wmF=wm; self._wmL=wl
    -- live clock on right side of watermark
    local cl=G.Label(wm,U.TimeStr(),th.TextMuted,UDim2.fromOffset(60,24),UDim2.new(1,-62,0,0),Enum.Font.Code,10,Enum.TextXAlignment.Center,202)
    self:_TR(cl,"TextColor3","TextMuted")
    task.spawn(function() while wm and wm.Parent do cl.Text=U.TimeStr(); task.wait(1) end end)
end

-- ─── PUBLIC API ───────────────────────────────
function Oxygen:Toggle()
    self.Visible=not self.Visible
    FT(self.Win,{Size=self.Visible and UDim2.fromOffset(self.SizeX,self.Minimized and 44 or self.SizeY) or UDim2.fromOffset(0,0)})
end
function Oxygen:ToggleMinimize()
    self.Minimized=not self.Minimized
    FT(self.Win,{Size=self.Minimized and UDim2.fromOffset(self.SizeX,44) or UDim2.fromOffset(self.SizeX,self.SizeY)})
end
function Oxygen:Notify(cfg)    return self.NotifsObj:Push(cfg,self.Theme) end
function Oxygen:SetTitle(t)    self._tLbl.Text=t end
function Oxygen:SetSubtitle(t) self._sLbl.Text=t end
function Oxygen:SetWatermarkText(t) if self._wmL then self._wmL.Text=t end end

function Oxygen:SetAccent(col)
    self.Theme.Accent=col; self.Theme.AccentGlow=U.Lerp(col,Color3.new(0,0,0),.45)
    for _,e in ipairs(self._themed) do
        if e.role=="Accent" and e.obj and e.obj.Parent then FT(e.obj,{[e.prop]=col}) end
    end
end

function Oxygen:SetTheme(name)
    local nt=Themes[name]; if not nt then warn("[Oxygen] theme not found: "..tostring(name)); return end
    self.Theme=nt; self.ThemeName=name
    -- re-apply all registered theme props
    for _,e in ipairs(self._themed) do
        local col=nt[e.role]
        if col and e.obj and e.obj.Parent then MT(e.obj,{[e.prop]=col}) end
    end
    -- update window corner radius
    pcall(function() local c=self.Win:FindFirstChildWhichIsA("UICorner"); if c then c.CornerRadius=UDim.new(0,nt.Radius) end end)
    -- update tabs
    for i,t in ipairs(self.Tabs) do
        local a=(i==self.ActiveTab)
        FT(t.Btn,  {BackgroundColor3=a and nt.NavBarActive or nt.NavBar})
        FT(t.Icon, {TextColor3=a and nt.Accent or nt.TextMuted})
        FT(t.Label,{TextColor3=a and nt.Text   or nt.TextMuted})
        FT(t.Ind,  {BackgroundColor3=nt.Accent})
        t.Page.ScrollBarImageColor3=nt.Accent
    end
    self.TabList.ScrollBarImageColor3=nt.Accent
    if self.DoSave then self.Store:Set("theme",name) end
    self.ThemeChanged:Fire(name,nt)
end

function Oxygen:GetThemeNames() local t={}; for k in pairs(Themes) do table.insert(t,k) end; table.sort(t); return t end
function Oxygen:AddTheme(n,d)   Themes[n]=d end

function Oxygen:Destroy()
    MT(self.Win,{Size=UDim2.fromOffset(0,0)})
    task.delay(.35,function()
        for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
        if self.SG and self.SG.Parent then self.SG:Destroy() end
        self.ThemeChanged:Destroy(); self.TabChanged:Destroy()
    end)
end

-- ═══════════════════════════════════════════════
-- COMPONENT API
-- ═══════════════════════════════════════════════
function Oxygen:_API(tabIdx,page,theme)
    local api={}; local win=self

    local function Card(h,clips)
        local c=G.Frame(page,theme.CardBg,UDim2.new(1,0,0,h or 38))
        c.ClipsDescendants=clips or false; c.ZIndex=7
        G.Corner(c,math.max(theme.Radius-2,3))
        local s=G.Stroke(c,theme.Border,1)
        win:_TR(c,"BackgroundColor3","CardBg"); win:_TR(s,"Color","Border")
        return c
    end
    local function Lbl(p,txt,col,sz,pos,font,ts,xa,zi)
        local l=G.Label(p,txt,col,sz,pos,font,ts,xa,zi); win:_TR(l,"TextColor3",col==theme.Text and "Text" or col==theme.TextMuted and "TextMuted" or col==theme.Accent and "Accent" or nil); return l
    end

    -- common disabled overlay
    local function DisableOverlay(card)
        local ov=G.Frame(card,Color3.new(0,0,0),UDim2.fromScale(1,1),nil,card.ZIndex+20)
        ov.BackgroundTransparency=.62; ov.Visible=false; G.Corner(ov,math.max(theme.Radius-2,3))
        return ov
    end

    -- ── SECTION ───────────────────────────────
    function api.Section(cfg)
        local f=G.Frame(page,Color3.new(0,0,0),UDim2.new(1,0,0,20)); f.BackgroundTransparency=1; f.ZIndex=7
        local bar=G.Frame(f,theme.Accent,UDim2.fromOffset(3,13),UDim2.fromOffset(0,3),8); G.Corner(bar,2); win:_TR(bar,"BackgroundColor3","Accent")
        G.Label(f,(cfg.Title or ""):upper(),theme.TextMuted,UDim2.new(1,-12,1,0),UDim2.fromOffset(10,0),Enum.Font.GothamBold,10,Enum.TextXAlignment.Left,8)
        return f
    end

    -- ── SEPARATOR ─────────────────────────────
    function api.Separator(cfg)
        cfg=cfg or {}; local f=G.Frame(page,Color3.new(0,0,0),UDim2.new(1,0,0,14)); f.BackgroundTransparency=1; f.ZIndex=7
        G.Frame(f,theme.Border,UDim2.new(1,0,0,1),UDim2.fromOffset(0,6),8)
        if cfg.Text and cfg.Text~="" then
            local tw=TextService:GetTextSize(cfg.Text,10,Enum.Font.Gotham,Vector2.new(9999,9999)).X
            local bg=G.Frame(f,theme.Primary,UDim2.fromOffset(tw+12,14),UDim2.new(.5,-(tw/2+6),0,0),9); win:_TR(bg,"BackgroundColor3","Primary")
            G.Label(bg,cfg.Text,theme.TextMuted,UDim2.fromScale(1,1),nil,Enum.Font.Gotham,10,Enum.TextXAlignment.Center,10)
        end
        return f
    end

    function api.Divider()
        local f=G.Frame(page,theme.Border,UDim2.new(1,0,0,1)); f.ZIndex=7; win:_TR(f,"BackgroundColor3","Border"); return f
    end

    -- ── LABEL ─────────────────────────────────
    function api.Label(cfg)
        local card=Card(28)
        local l=G.Label(card,cfg.Title or "",theme.TextMuted,UDim2.new(1,-16,1,0),UDim2.fromOffset(10,0),Enum.Font.Gotham,12,Enum.TextXAlignment.Left,8)
        l.TextWrapped=true; win:_TR(l,"TextColor3","TextMuted")
        local o={}
        function o:Set(t) l.Text=t end; function o:Get() return l.Text end
        function o:SetVisible(v) card.Visible=v end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ── PARAGRAPH ─────────────────────────────
    function api.Paragraph(cfg)
        local card=Card(58)
        local tl=G.Label(card,cfg.Title or "",theme.Text,UDim2.new(1,-16,0,16),UDim2.fromOffset(10,5),theme.FontTitle,13,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")
        local body=cfg.Content or ""
        local bl=G.Label(card,body,theme.TextMuted,UDim2.new(1,-16,0,36),UDim2.fromOffset(10,22),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8); bl.TextWrapped=true; win:_TR(bl,"TextColor3","TextMuted")
        task.defer(function()
            if not bl.Parent then return end
            local bh=TextService:GetTextSize(body,11,Enum.Font.Gotham,Vector2.new(page.AbsoluteSize.X-30,9999)).Y
            card.Size=UDim2.new(1,0,0,math.max(bh+30,46))
        end)
        local o={}
        function o:SetTitle(t) tl.Text=t end; function o:SetContent(t) bl.Text=t end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── BUTTON ────────────────────────────────
    function api.Button(cfg)
        local title=cfg.Title or "Button"; local desc=cfg.Description or ""; local cb=cfg.Callback or function() end; local tip=cfg.Tooltip
        local icon=cfg.Icon; local variant=cfg.Variant or "default"  -- "default","danger","success","ghost"
        local h=desc~=""and 54 or 36; local card=Card(h,true)
        local ov=DisableOverlay(card); local enabled=true

        local bgMap={default=theme.Accent,danger=theme.Error,success=theme.Success,ghost=theme.Tertiary}
        local btnCol=bgMap[variant] or theme.Accent

        if icon then
            G.Label(card,icon,theme.Text,UDim2.fromOffset(22,36),UDim2.fromOffset(10,0),Enum.Font.GothamBold,16,Enum.TextXAlignment.Center,8)
        end
        local xOff=icon and 36 or 12
        G.Label(card,title,theme.Text,UDim2.new(1,-88,0,18),UDim2.fromOffset(xOff,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8)
        if desc~="" then G.Label(card,desc,theme.TextMuted,UDim2.new(1,-88,0,14),UDim2.fromOffset(xOff,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8) end

        local rb=G.Btn(card,btnCol,UDim2.fromOffset(60,24),UDim2.new(1,-68,.5,-12),9); G.Corner(rb,5)
        win:_TR(rb,"ImageColor3",variant=="default" and "Accent" or nil)
        G.Label(rb,cfg.ButtonText or "RUN",theme.TextDark,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,11,Enum.TextXAlignment.Center,10)
        rb.MouseButton1Click:Connect(function() if not enabled then return end; U.Ripple(rb,U.Lerp(btnCol,Color3.new(0,0,0),.25)); U.Call(cb) end)
        rb.MouseEnter:Connect(function() FT(rb,{ImageColor3=U.Lerp(btnCol,Color3.new(0,0,0),.18)}) end)
        rb.MouseLeave:Connect(function() FT(rb,{ImageColor3=btnCol}) end)
        if tip then MkTooltip(card,tip,theme,win.SG) end

        local o={}
        function o:SetEnabled(v) enabled=v; ov.Visible=not v end
        function o:SetVisible(v) card.Visible=v end
        function o:Invoke() if enabled then U.Call(cb) end end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ── TOGGLE ────────────────────────────────
    function api.Toggle(cfg)
        local title=cfg.Title or "Toggle"; local desc=cfg.Description or ""; local def=cfg.Default or false
        local cb=cfg.Callback or function() end; local key=cfg.ConfigKey; local tip=cfg.Tooltip
        if key and win.DoSave then def=win.Store:Get(key,def) end
        local state=def; local disabled=false
        local h=desc~=""and 54 or 36; local card=Card(h)
        local ov=DisableOverlay(card)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-72,0,18),UDim2.fromOffset(12,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")
        if desc~="" then local dl=G.Label(card,desc,theme.TextMuted,UDim2.new(1,-72,0,14),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8); win:_TR(dl,"TextColor3","TextMuted") end
        local track=G.Frame(card,state and theme.Toggle or theme.Tertiary,UDim2.fromOffset(34,16),UDim2.new(1,-42,.5,-8),9); G.Corner(track,8); win:_TR(track,"BackgroundColor3","Tertiary")
        local knob=G.Frame(track,Color3.new(1,1,1),UDim2.fromOffset(10,10),state and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3),10); G.Corner(knob,5)
        local Changed=Signal.new()
        local function upd(v)
            state=v; FT(track,{BackgroundColor3=v and theme.Toggle or theme.Tertiary}); FT(knob,{Position=v and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3)})
            U.Call(cb,v); Changed:Fire(v); if key and win.DoSave then win.Store:Set(key,v) end
        end
        task.defer(function() U.Call(cb,state) end)
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=11; hit.Parent=card
        hit.MouseButton1Click:Connect(function() if not disabled then upd(not state) end end)
        if tip then MkTooltip(card,tip,theme,win.SG) end
        local o={}
        function o:Set(v)          upd(v) end
        function o:Get()           return state end
        function o:SetTitle(t)     tl.Text=t end
        function o:SetDisabled(v)  disabled=v; ov.Visible=v end
        function o:SetVisible(v)   card.Visible=v end
        o.Changed=Changed
        function o:Destroy()       card:Destroy(); Changed:Destroy() end
        return o
    end

    -- ── SLIDER ────────────────────────────────
    function api.Slider(cfg)
        local title=cfg.Title or "Slider"; local desc=cfg.Description or ""; local mn=cfg.Min or 0; local mx=cfg.Max or 100
        local def=cfg.Default or mn; local prec=cfg.Precision or 0; local suf=cfg.Suffix or ""; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        local snap=cfg.Snap  -- snap interval e.g. 5
        if key and win.DoSave then def=win.Store:Get(key,def) end
        def=U.Clamp(def,mn,mx); local value=def; local disabled=false
        local h=desc~=""and 66 or 52; local card=Card(h)
        local ov=DisableOverlay(card)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-84,0,18),UDim2.fromOffset(12,8),theme.Font,14,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")
        local vl=G.Label(card,tostring(def)..suf,theme.Accent,UDim2.fromOffset(72,18),UDim2.new(1,-80,0,8),Enum.Font.GothamBold,13,Enum.TextXAlignment.Right,8); win:_TR(vl,"TextColor3","Accent")
        if desc~="" then local dl=G.Label(card,desc,theme.TextMuted,UDim2.new(1,-20,0,13),UDim2.fromOffset(12,26),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8); win:_TR(dl,"TextColor3","TextMuted") end
        local ty=desc~=""and 48 or 34
        local track=G.Frame(card,theme.Tertiary,UDim2.new(1,-24,0,4),UDim2.fromOffset(12,ty),8); G.Corner(track,2); win:_TR(track,"BackgroundColor3","Tertiary")
        local ds=(def-mn)/math.max(mx-mn,.001)
        local fill=G.Frame(track,theme.Slider,UDim2.fromScale(ds,1),nil,9); G.Corner(fill,2); win:_TR(fill,"BackgroundColor3","Slider")
        local knob=G.Frame(track,Color3.new(1,1,1),UDim2.fromOffset(14,14),UDim2.new(ds,-7,.5,-7),10); G.Corner(knob,7); G.Stroke(knob,theme.Slider,2); win:_TR(knob,"BackgroundColor3","Text"); win:_TR(knob:FindFirstChildWhichIsA("UIStroke"),"Color","Slider")
        local drag=false; local Changed=Signal.new()
        local function upd(scale)
            scale=U.Clamp(scale,0,1)
            local v=mn+(mx-mn)*scale
            if snap and snap>0 then v=math.floor(v/snap+.5)*snap end
            local m=10^prec; v=math.floor(v*m+.5)/m; v=U.Clamp(v,mn,mx)
            value=v; local sc=(v-mn)/math.max(mx-mn,.001)
            FT(fill,{Size=UDim2.fromScale(sc,1)}); FT(knob,{Position=UDim2.new(sc,-7,.5,-7)})
            vl.Text=tostring(v)..suf; U.Call(cb,v); Changed:Fire(v)
            if key and win.DoSave then win.Store:Set(key,v) end
        end
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=12; hit.Parent=track
        hit.MouseButton1Down:Connect(function() if disabled then return end; drag=true; upd(U.XY(track)) end)
        win:_C(UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(U.XY(track)) end end))
        win:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end))
        task.defer(function() U.Call(cb,value) end)
        local o={}
        function o:Set(v)         v=U.Clamp(v,mn,mx); upd((v-mn)/math.max(mx-mn,.001)) end
        function o:Get()          return value end
        function o:SetMin(v)      mn=v end; function o:SetMax(v) mx=v end
        function o:SetTitle(t)    tl.Text=t end
        function o:SetDisabled(v) disabled=v; ov.Visible=v end
        function o:SetVisible(v)  card.Visible=v end
        o.Changed=Changed
        function o:Destroy()      card:Destroy(); Changed:Destroy() end
        return o
    end

    -- ── DROPDOWN ──────────────────────────────
    function api.Dropdown(cfg)
        local title=cfg.Title or "Dropdown"; local desc=cfg.Description or ""; local opts=cfg.Options or {}; local def=cfg.Default
        local multi=cfg.Multi or false; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey; local tip=cfg.Tooltip
        if key and win.DoSave then def=win.Store:Get(key,def) end
        local sel=multi and {} or def; local open=false
        local bh=desc~=""and 54 or 40; local card=Card(bh); card.ZIndex=22
        G.Label(card,title,theme.Text,UDim2.new(1,-22,0,18),UDim2.fromOffset(12,desc~=""and 8 or 11),theme.Font,14,Enum.TextXAlignment.Left,23)
        if desc~="" then G.Label(card,desc,theme.TextMuted,UDim2.new(1,-22,0,13),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,23) end
        local curL=G.Label(card,def and tostring(def) or "Select…",theme.Accent,UDim2.new(1,-32,0,16),UDim2.new(0,12,1,desc~=""and -24 or -26),Enum.Font.Gotham,12,Enum.TextXAlignment.Left,23)
        win:_TR(curL,"TextColor3","Accent")
        local arrow=G.Label(card,"▾",theme.TextMuted,UDim2.fromOffset(18,18),UDim2.new(1,-24,.5,-9),Enum.Font.GothamBold,13,Enum.TextXAlignment.Center,23)
        local panH=math.min(#opts*26+38,198)
        local panel=G.Frame(card,theme.Secondary,UDim2.new(1,0,0,0),UDim2.new(0,0,1,4),50,true); G.Corner(panel,6); G.Stroke(panel,theme.Border,1); G.Shadow(panel,theme.Shadow,50); win:_TR(panel,"BackgroundColor3","Secondary")
        local sb=Instance.new("TextBox"); sb.BackgroundColor3=theme.Tertiary; sb.BorderSizePixel=0; sb.Size=UDim2.new(1,-8,0,24); sb.Position=UDim2.fromOffset(4,4); sb.PlaceholderText="Search…"; sb.PlaceholderColor3=theme.TextMuted; sb.Text=""; sb.TextColor3=theme.Text; sb.Font=Enum.Font.Gotham; sb.TextSize=12; sb.ClearTextOnFocus=false; sb.ZIndex=51; sb.Parent=panel; G.Corner(sb,4); G.Pad(sb,0,6,0,6)
        win:_TR(sb,"BackgroundColor3","Tertiary"); win:_TR(sb,"TextColor3","Text")
        local sc=G.Scroll(panel,UDim2.new(1,0,1,-32),UDim2.fromOffset(0,30),51); sc.ScrollBarImageColor3=theme.Accent; win:_TR(sc,"ScrollBarImageColor3","Accent")
        G.Pad(sc,2,4,2,4); local sl=G.List(sc,nil,nil,nil,2); G.AutoCanvas(sc,sl,4)
        local obs={}
        local function rebuild(filter)
            for _,b in ipairs(obs) do b:Destroy() end; obs={}
            for _,opt in ipairs(opts) do
                local os=tostring(opt)
                if filter=="" or os:lower():find(filter:lower(),1,true) then
                    local isSel=multi and U.Has(sel,opt) or (sel==opt)
                    local ob=Instance.new("TextButton"); ob.BackgroundColor3=isSel and theme.Accent or theme.Tertiary; ob.BorderSizePixel=0; ob.Size=UDim2.new(1,0,0,24); ob.Text=""; ob.ZIndex=52; ob.Parent=sc; G.Corner(ob,4)
                    local ol=G.Label(ob,os,isSel and theme.TextDark or theme.Text,UDim2.new(1,-8,1,0),UDim2.fromOffset(6,0),Enum.Font.Gotham,12,Enum.TextXAlignment.Left,53)
                    ob.MouseButton1Click:Connect(function()
                        if multi then
                            if U.Has(sel,opt) then for i,v in ipairs(sel) do if v==opt then table.remove(sel,i); break end end else table.insert(sel,opt) end
                            curL.Text=#sel>0 and table.concat(sel,", ") or "Select…"; U.Call(cb,sel)
                        else sel=opt; curL.Text=os; U.Call(cb,opt); open=false; FT(panel,{Size=UDim2.new(1,0,0,0)}); FT(arrow,{Rotation=0}) end
                        if key and win.DoSave then win.Store:Set(key,sel) end; rebuild(sb.Text)
                    end)
                    ob.MouseEnter:Connect(function() if not(not multi and sel==opt) then FT(ob,{BackgroundColor3=theme.Accent}); FT(ol,{TextColor3=theme.TextDark}) end end)
                    ob.MouseLeave:Connect(function() local s2=multi and U.Has(sel,opt) or (sel==opt); FT(ob,{BackgroundColor3=s2 and theme.Accent or theme.Tertiary}); FT(ol,{TextColor3=s2 and theme.TextDark or theme.Text}) end)
                    table.insert(obs,ob)
                end
            end
        end
        rebuild(""); sb:GetPropertyChangedSignal("Text"):Connect(function() rebuild(sb.Text) end)
        task.defer(function()
            local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.new(1,0,0,bh); hit.Text=""; hit.ZIndex=24; hit.Parent=card
            hit.MouseButton1Click:Connect(function() open=not open; FT(panel,{Size=UDim2.new(1,0,0,open and panH or 0)}); FT(arrow,{Rotation=open and 180 or 0}); if open then sb:CaptureFocus() end end)
        end)
        if tip then MkTooltip(card,tip,theme,win.SG) end
        local o={}
        function o:Set(v)         sel=v; curL.Text=tostring(v) end
        function o:Get()          return sel end
        function o:SetOptions(v)  opts=v; panH=math.min(#v*26+38,198); rebuild(sb.Text) end
        function o:AddOption(v)   table.insert(opts,v); panH=math.min(#opts*26+38,198); rebuild(sb.Text) end
        function o:RemoveOption(v) for i,x in ipairs(opts) do if x==v then table.remove(opts,i); break end end; rebuild(sb.Text) end
        function o:Search(v)      sb.Text=v end
        function o:SetVisible(v)  card.Visible=v end
        function o:Destroy()      card:Destroy() end
        return o
    end

    -- ── KEYBIND ───────────────────────────────
    function api.Keybind(cfg)
        local title=cfg.Title or "Keybind"; local desc=cfg.Description or ""; local def=cfg.Default or Enum.KeyCode.Unknown
        local cb=cfg.Callback or function() end; local key=cfg.ConfigKey; local allowMouse=cfg.AllowMouse or false
        local bound=def; local listening=false
        local h=desc~=""and 54 or 36; local card=Card(h)
        G.Label(card,title,theme.Text,UDim2.new(1,-104,0,18),UDim2.fromOffset(12,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8)
        if desc~="" then G.Label(card,desc,theme.TextMuted,UDim2.new(1,-104,0,13),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8) end
        local kb=Instance.new("TextButton"); kb.BackgroundColor3=theme.Tertiary; kb.BorderSizePixel=0; kb.Size=UDim2.fromOffset(90,22); kb.Position=UDim2.new(1,-98,.5,-11); kb.Text=bound.Name; kb.TextColor3=theme.Accent; kb.Font=Enum.Font.GothamBold; kb.TextSize=11; kb.ZIndex=9; kb.Parent=card
        G.Corner(kb,5); G.Stroke(kb,theme.Border,1); win:_TR(kb,"BackgroundColor3","Tertiary"); win:_TR(kb,"TextColor3","Accent")
        kb.MouseButton1Click:Connect(function() listening=true; kb.Text="…"; kb.TextColor3=theme.Warning end)
        win:_C(UserInputService.InputBegan:Connect(function(i,gp)
            if not listening then return end
            if i.UserInputType==Enum.UserInputType.Keyboard then
                bound=i.KeyCode; kb.Text=bound.Name; kb.TextColor3=theme.Accent; listening=false; U.Call(cb,bound)
                if key and win.DoSave then win.Store:Set(key,bound.Name) end
            elseif allowMouse and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.MouseButton2) then
                local n=i.UserInputType==Enum.UserInputType.MouseButton1 and "MouseButton1" or "MouseButton2"
                kb.Text=n; kb.TextColor3=theme.Accent; listening=false
            end
        end))
        local o={}
        function o:Get() return bound end; function o:Set(kc) bound=kc; kb.Text=kc.Name end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── TEXT INPUT ────────────────────────────
    function api.TextInput(cfg)
        local title=cfg.Title or "Input"; local desc=cfg.Description or ""; local ph=cfg.Placeholder or "Type here…"
        local def=cfg.Default or ""; local cb=cfg.Callback or function() end; local num=cfg.Numeric or false
        local maxL=cfg.MaxLength or 200; local key=cfg.ConfigKey; local tip=cfg.Tooltip
        if key and win.DoSave then def=win.Store:Get(key,def) end
        local h=desc~=""and 72 or 58; local card=Card(h)
        G.Label(card,title,theme.Text,UDim2.new(1,-16,0,15),UDim2.fromOffset(12,5),theme.Font,13,Enum.TextXAlignment.Left,8)
        if desc~="" then G.Label(card,desc,theme.TextMuted,UDim2.new(1,-16,0,12),UDim2.fromOffset(12,20),Enum.Font.Gotham,10,Enum.TextXAlignment.Left,8) end
        local iy=desc~=""and 38 or 26
        local iF=G.Frame(card,theme.Tertiary,UDim2.new(1,-16,0,24),UDim2.fromOffset(8,iy),8); G.Corner(iF,5)
        local iS=G.Stroke(iF,theme.Border,1); win:_TR(iF,"BackgroundColor3","Tertiary"); win:_TR(iS,"Color","Border")
        local box=Instance.new("TextBox"); box.BackgroundTransparency=1; box.Size=UDim2.new(1,-50,1,0); box.Position=UDim2.fromOffset(6,0); box.Text=def; box.PlaceholderText=ph; box.PlaceholderColor3=theme.TextMuted; box.TextColor3=theme.Text; box.Font=Enum.Font.Gotham; box.TextSize=12; box.ClearTextOnFocus=false; box.ZIndex=9; box.Parent=iF
        win:_TR(box,"TextColor3","Text"); win:_TR(box,"PlaceholderColor3","TextMuted")
        local counter=G.Label(iF,"0/"..maxL,theme.TextMuted,UDim2.fromOffset(42,18),UDim2.new(1,-46,0,3),Enum.Font.Gotham,9,Enum.TextXAlignment.Right,9); win:_TR(counter,"TextColor3","TextMuted")
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if num then box.Text=box.Text:gsub("[^%d%.%-]","") end
            if #box.Text>maxL then box.Text=box.Text:sub(1,maxL) end
            counter.Text=#box.Text.."/"..maxL
        end)
        box.Focused:Connect(function() FT(iF,{BackgroundColor3=U.Lerp(theme.Tertiary,theme.Accent,.12)}); iS.Color=theme.Accent end)
        box.FocusLost:Connect(function(enter) FT(iF,{BackgroundColor3=theme.Tertiary}); iS.Color=theme.Border; if enter then U.Call(cb,box.Text); if key and win.DoSave then win.Store:Set(key,box.Text) end end end)
        if tip then MkTooltip(card,tip,theme,win.SG) end
        local o={}
        function o:Get() return box.Text end; function o:Set(t) box.Text=t end; function o:Clear() box.Text="" end; function o:Focus() box:CaptureFocus() end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── SEARCH BOX ────────────────────────────
    function api.SearchBox(cfg)
        local ph=cfg.Placeholder or "🔍 Search…"; local cb=cfg.Callback or function() end
        local card=Card(40)
        local iF=G.Frame(card,theme.Tertiary,UDim2.new(1,-16,0,28),UDim2.fromOffset(8,6),8); G.Corner(iF,6)
        local iS=G.Stroke(iF,theme.Border,1); win:_TR(iF,"BackgroundColor3","Tertiary"); win:_TR(iS,"Color","Border")
        G.Label(iF,"🔍",theme.TextMuted,UDim2.fromOffset(24,28),UDim2.fromOffset(4,0),Enum.Font.Gotham,13,Enum.TextXAlignment.Center,9); win:_TR(G.Label(iF,"",theme.TextMuted),"TextColor3","TextMuted")
        local box=Instance.new("TextBox"); box.BackgroundTransparency=1; box.Size=UDim2.new(1,-52,1,0); box.Position=UDim2.fromOffset(28,0); box.PlaceholderText=ph; box.PlaceholderColor3=theme.TextMuted; box.Text=""; box.TextColor3=theme.Text; box.Font=Enum.Font.Gotham; box.TextSize=13; box.ClearTextOnFocus=false; box.ZIndex=9; box.Parent=iF
        win:_TR(box,"TextColor3","Text"); win:_TR(box,"PlaceholderColor3","TextMuted")
        local clr=Instance.new("TextButton"); clr.BackgroundTransparency=1; clr.Size=UDim2.fromOffset(22,22); clr.Position=UDim2.new(1,-24,0,3); clr.Text="×"; clr.TextColor3=theme.TextMuted; clr.Font=Enum.Font.GothamBold; clr.TextSize=16; clr.ZIndex=10; clr.Parent=iF; clr.Visible=false
        clr.MouseButton1Click:Connect(function() box.Text=""; U.Call(cb,"") end)
        box:GetPropertyChangedSignal("Text"):Connect(function() clr.Visible=box.Text~=""; U.Call(cb,box.Text) end)
        box.Focused:Connect(function() FT(iF,{BackgroundColor3=U.Lerp(theme.Tertiary,theme.Accent,.11)}); iS.Color=theme.Accent end)
        box.FocusLost:Connect(function() FT(iF,{BackgroundColor3=theme.Tertiary}); iS.Color=theme.Border end)
        local o={}
        function o:Get() return box.Text end; function o:Set(t) box.Text=t end; function o:Clear() box.Text="" end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── COLOR PICKER ──────────────────────────
    function api.ColorPicker(cfg)
        local title=cfg.Title or "Color"; local def=cfg.Default or Color3.fromRGB(120,80,255)
        local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then local s=win.Store:Get(key,nil); if s then def=U.FromHex(s) or def end end
        local h,s,v=Color3.toHSV(def); local open=false
        local card=Card(36); card.ClipsDescendants=false
        G.Label(card,title,theme.Text,UDim2.new(1,-62,1,0),UDim2.fromOffset(12,0),theme.Font,14,Enum.TextXAlignment.Left,8)
        local prev=G.Frame(card,def,UDim2.fromOffset(48,20),UDim2.new(1,-56,.5,-10),9); G.Corner(prev,4); G.Stroke(prev,theme.Border,1)
        local hexL=G.Label(prev,U.Hex(def),U.Contrast(def),UDim2.fromScale(1,1),nil,Enum.Font.Code,9,Enum.TextXAlignment.Center,10)
        local pp=G.Frame(card,theme.Secondary,UDim2.new(1,0,0,0),UDim2.new(0,0,1,4),30,true); G.Corner(pp,6); G.Stroke(pp,theme.Border,1); G.Shadow(pp,theme.Shadow,30); win:_TR(pp,"BackgroundColor3","Secondary")
        local function updC() local col=Color3.fromHSV(h,s,v); prev.BackgroundColor3=col; hexL.TextColor3=U.Contrast(col); hexL.Text=U.Hex(col); U.Call(cb,col); if key and win.DoSave then win.Store:Set(key,U.Hex(col)) end end
        -- SV square
        local svSq=Instance.new("ImageLabel"); svSq.BackgroundColor3=Color3.fromHSV(h,1,1); svSq.BorderSizePixel=0; svSq.Size=UDim2.new(1,-16,0,100); svSq.Position=UDim2.fromOffset(8,8); svSq.Image="rbxassetid://4155801252"; svSq.ZIndex=31; svSq.Parent=pp; G.Corner(svSq,4)
        -- hue bar
        local hBar=Instance.new("ImageLabel"); hBar.BackgroundColor3=Color3.new(1,0,0); hBar.BorderSizePixel=0; hBar.Size=UDim2.new(1,-16,0,10); hBar.Position=UDim2.fromOffset(8,116); hBar.Image="rbxassetid://698052001"; hBar.ZIndex=31; hBar.Parent=pp; G.Corner(hBar,3)
        -- opacity preview
        local opBg=G.Frame(pp,theme.Tertiary,UDim2.new(1,-16,0,8),UDim2.fromOffset(8,132),31); G.Corner(opBg,3); win:_TR(opBg,"BackgroundColor3","Tertiary")
        local opFill=G.Frame(opBg,Color3.fromHSV(h,s,v),UDim2.fromScale(1,1),nil,32); G.Corner(opFill,3)
        -- hex input
        local hBox=Instance.new("TextBox"); hBox.BackgroundColor3=theme.Tertiary; hBox.BorderSizePixel=0; hBox.Size=UDim2.new(1,-16,0,22); hBox.Position=UDim2.fromOffset(8,147); hBox.Text=U.Hex(def); hBox.PlaceholderText="#FFFFFF"; hBox.PlaceholderColor3=theme.TextMuted; hBox.TextColor3=theme.Text; hBox.Font=Enum.Font.Code; hBox.TextSize=12; hBox.ClearTextOnFocus=false; hBox.ZIndex=31; hBox.Parent=pp; G.Corner(hBox,4); G.Pad(hBox,0,6,0,6)
        win:_TR(hBox,"BackgroundColor3","Tertiary"); win:_TR(hBox,"TextColor3","Text")
        local svK=G.Frame(svSq,Color3.new(1,1,1),UDim2.fromOffset(10,10),nil,32); G.Corner(svK,5); G.Stroke(svK,Color3.new(1,1,1),1)
        local hK=G.Frame(hBar,Color3.new(1,1,1),UDim2.fromOffset(4,12),nil,32); G.Corner(hK,2)
        local function refK() svK.Position=UDim2.new(s,-5,1-v,-5); hK.Position=UDim2.new(1-h,-2,0,-1); svSq.BackgroundColor3=Color3.fromHSV(h,1,1); opFill.BackgroundColor3=Color3.fromHSV(h,s,v) end; refK()
        local svD=false
        local svH=Instance.new("TextButton"); svH.BackgroundTransparency=1; svH.Size=UDim2.fromScale(1,1); svH.Text=""; svH.ZIndex=33; svH.Parent=svSq
        svH.MouseButton1Down:Connect(function() svD=true; local px,py=U.XY(svSq); s,v=U.Clamp(px,0,1),U.Clamp(1-py,0,1); refK(); updC() end)
        win:_C(UserInputService.InputChanged:Connect(function(i) if svD and i.UserInputType==Enum.UserInputType.MouseMovement then local px,py=U.XY(svSq); s,v=U.Clamp(px,0,1),U.Clamp(1-py,0,1); refK(); updC() end end))
        win:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svD=false end end))
        local hD=false
        local hH=Instance.new("TextButton"); hH.BackgroundTransparency=1; hH.Size=UDim2.fromScale(1,1); hH.Text=""; hH.ZIndex=33; hH.Parent=hBar
        hH.MouseButton1Down:Connect(function() hD=true; local px=U.XY(hBar); h=U.Clamp(1-px,0,1); refK(); updC() end)
        win:_C(UserInputService.InputChanged:Connect(function(i) if hD and i.UserInputType==Enum.UserInputType.MouseMovement then local px=U.XY(hBar); h=U.Clamp(1-px,0,1); refK(); updC() end end))
        win:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hD=false end end))
        hBox.FocusLost:Connect(function() local col=U.FromHex(hBox.Text); if col then h,s,v=Color3.toHSV(col); refK(); updC() end end)
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=10; hit.Parent=card
        hit.MouseButton1Click:Connect(function() open=not open; FT(pp,{Size=UDim2.new(1,0,0,open and 177 or 0)}) end)
        local o={}
        function o:Get()    return Color3.fromHSV(h,s,v) end
        function o:Set(col) h,s,v=Color3.toHSV(col); refK(); updC() end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── PROGRESS BAR ──────────────────────────
    function api.ProgressBar(cfg)
        local title=cfg.Title or "Progress"; local init=cfg.Value or 0; local mx=cfg.Max or 100; local suf=cfg.Suffix or "%"; local col=cfg.Color
        local card=Card(46)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-72,0,16),UDim2.fromOffset(12,6),theme.Font,13,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")
        local vl=G.Label(card,tostring(init)..suf,theme.Accent,UDim2.fromOffset(64,16),UDim2.new(1,-70,0,6),Enum.Font.GothamBold,12,Enum.TextXAlignment.Right,8); win:_TR(vl,"TextColor3","Accent")
        local track=G.Frame(card,theme.Tertiary,UDim2.new(1,-16,0,7),UDim2.fromOffset(8,30),8); G.Corner(track,3); win:_TR(track,"BackgroundColor3","Tertiary")
        local fillCol=col or theme.Accent
        local fill=G.Frame(track,fillCol,UDim2.fromScale(U.Clamp(init/math.max(mx,.001),0,1),1),nil,9); G.Corner(fill,3); win:_TR(fill,"BackgroundColor3",col and nil or "Accent")
        local shim=G.Frame(fill,Color3.new(1,1,1),UDim2.fromOffset(26,7),nil,10); shim.BackgroundTransparency=.7; G.Corner(shim,3)
        task.spawn(function()
            while fill and fill.Parent do shim.Position=UDim2.fromScale(-.3,0); Tw(shim,TI.sine,{Position=UDim2.fromScale(1.4,0)}); task.wait(2.1) end
        end)
        local o={}
        function o:Set(val)     local sc=U.Clamp(val/math.max(mx,.001),0,1); MT(fill,{Size=UDim2.fromScale(sc,1)}); vl.Text=tostring(U.Round(val,1))..suf end
        function o:SetMax(m)    mx=m end
        function o:SetColor(c)  FT(fill,{BackgroundColor3=c}) end
        function o:SetTitle(t)  tl.Text=t end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── STEPPER (hold to repeat) ───────────────
    function api.Stepper(cfg)
        local title=cfg.Title or "Stepper"; local mn=cfg.Min or 0; local mx=cfg.Max or 10; local def=cfg.Default or mn
        local step=cfg.Step or 1; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then def=win.Store:Get(key,def) end
        local value=U.Clamp(def,mn,mx); local card=Card(36)
        G.Label(card,title,theme.Text,UDim2.new(1,-118,1,0),UDim2.fromOffset(12,0),theme.Font,14,Enum.TextXAlignment.Left,8)
        local function mkB(sym,xo)
            local b=Instance.new("TextButton"); b.BackgroundColor3=theme.Tertiary; b.BorderSizePixel=0
            b.Size=UDim2.fromOffset(26,22); b.Position=UDim2.new(1,xo,.5,-11); b.Text=sym; b.TextColor3=theme.Accent; b.Font=Enum.Font.GothamBold; b.TextSize=16; b.ZIndex=9; b.Parent=card; G.Corner(b,5)
            win:_TR(b,"BackgroundColor3","Tertiary"); win:_TR(b,"TextColor3","Accent")
            b.MouseEnter:Connect(function() FT(b,{BackgroundColor3=theme.Accent}); b.TextColor3=theme.TextDark end)
            b.MouseLeave:Connect(function() FT(b,{BackgroundColor3=theme.Tertiary}); b.TextColor3=theme.Accent end)
            return b
        end
        local minus=mkB("−",-108)
        local vl=G.Label(card,tostring(value),theme.Text,UDim2.fromOffset(50,22),UDim2.new(1,-80,.5,-11),Enum.Font.GothamBold,14,Enum.TextXAlignment.Center,9)
        local plus=mkB("+", -30)
        local function upd(v) value=U.Clamp(v,mn,mx); vl.Text=tostring(value); U.Call(cb,value); if key and win.DoSave then win.Store:Set(key,value) end end
        -- hold-to-repeat
        local function holdRepeat(btn,dir)
            btn.MouseButton1Down:Connect(function()
                upd(value+dir*step)
                task.spawn(function()
                    task.wait(.45)
                    local t=0
                    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        upd(value+dir*step); t+=1; task.wait(t<10 and .1 or .05)
                    end
                end)
            end)
        end
        holdRepeat(minus,-1); holdRepeat(plus,1)
        local o={}
        function o:Get()       return value end
        function o:Set(v)      upd(v) end
        function o:SetVisible(v) card.Visible=v end
        function o:Destroy()   card:Destroy() end
        return o
    end

    -- ── RADIO GROUP ───────────────────────────
    function api.RadioGroup(cfg)
        local title=cfg.Title or "Choose"; local opts=cfg.Options or {}; local def=cfg.Default or opts[1]; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then def=win.Store:Get(key,def) end
        local sel=def; local rbs={}
        local function buildUI(card)
            for _,b in ipairs(rbs) do b.row:Destroy() end; rbs={}
            local h=26+#opts*30; card.Size=UDim2.new(1,0,0,h)
            G.Label(card,title,theme.TextMuted,UDim2.new(1,-16,0,20),UDim2.fromOffset(12,3),Enum.Font.GothamBold,10,Enum.TextXAlignment.Left,8)
            for i,opt in ipairs(opts) do
                local row=Instance.new("TextButton"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,-16,0,26); row.Position=UDim2.fromOffset(8,18+(i-1)*28); row.Text=""; row.ZIndex=9; row.Parent=card
                local ring=G.Frame(row,Color3.new(0,0,0),UDim2.fromOffset(16,16),UDim2.fromOffset(4,5),10); ring.BackgroundTransparency=1; G.Corner(ring,8)
                local rs=G.Stroke(ring,opt==sel and theme.Accent or theme.Border,2); win:_TR(rs,"Color",opt==sel and "Accent" or "Border")
                local dot=G.Frame(ring,theme.Accent,UDim2.fromOffset(opt==sel and 8 or 0,opt==sel and 8 or 0),UDim2.fromOffset(opt==sel and 4 or 8,opt==sel and 4 or 8),11); G.Corner(dot,4); win:_TR(dot,"BackgroundColor3","Accent")
                local lbl=G.Label(row,tostring(opt),opt==sel and theme.Text or theme.TextMuted,UDim2.new(1,-26,1,0),UDim2.fromOffset(24,0),Enum.Font.Gotham,13,Enum.TextXAlignment.Left,10)
                table.insert(rbs,{row=row,rs=rs,dot=dot,lbl=lbl,opt=opt})
                row.MouseButton1Click:Connect(function()
                    sel=opt; if key and win.DoSave then win.Store:Set(key,opt) end
                    for _,rb in ipairs(rbs) do
                        local a=rb.opt==opt; rb.rs.Color=a and theme.Accent or theme.Border
                        FT(rb.dot,{Size=a and UDim2.fromOffset(8,8) or UDim2.fromOffset(0,0),Position=a and UDim2.fromOffset(4,4) or UDim2.fromOffset(8,8)})
                        FT(rb.lbl,{TextColor3=a and theme.Text or theme.TextMuted})
                    end
                    U.Call(cb,opt)
                end)
            end
        end
        local card=Card(26+#opts*30)
        buildUI(card)
        local o={}
        function o:Get()          return sel end
        function o:Set(v)         sel=v; for _,rb in ipairs(rbs) do local a=rb.opt==v; rb.rs.Color=a and theme.Accent or theme.Border; FT(rb.dot,{Size=a and UDim2.fromOffset(8,8) or UDim2.fromOffset(0,0),Position=a and UDim2.fromOffset(4,4) or UDim2.fromOffset(8,8)}); FT(rb.lbl,{TextColor3=a and theme.Text or theme.TextMuted}) end end
        function o:SetOptions(v)  opts=v; buildUI(card) end
        function o:SetVisible(v)  card.Visible=v end
        function o:Destroy()      card:Destroy() end
        return o
    end

    -- ── ACCORDION ─────────────────────────────
    function api.Accordion(cfg)
        local title=cfg.Title or "Expand"; local openByDefault=cfg.Open or false
        local hdrH=36; local card=Card(hdrH,true)
        G.Label(card,title,theme.Text,UDim2.new(1,-40,0,hdrH),UDim2.fromOffset(12,0),theme.FontTitle,13,Enum.TextXAlignment.Left,9)
        local chev=G.Label(card,openByDefault and "▲" or "▼",theme.TextMuted,UDim2.fromOffset(22,22),UDim2.new(1,-28,.5,-11),Enum.Font.GothamBold,12,Enum.TextXAlignment.Center,9); win:_TR(chev,"TextColor3","TextMuted")
        local inner=G.Frame(card,theme.Primary,UDim2.new(1,-8,0,0),UDim2.fromOffset(4,hdrH+2),8,true); win:_TR(inner,"BackgroundColor3","Primary")
        G.Pad(inner,4,4,4,4); local il=G.List(inner,nil,nil,nil,5); local contentH=0
        il:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            contentH=il.AbsoluteContentSize.Y+14
            if openByDefault then card.Size=UDim2.new(1,0,0,hdrH+contentH); inner.Size=UDim2.new(1,-8,0,contentH) end
        end)
        local function toggle()
            openByDefault=not openByDefault; chev.Text=openByDefault and "▲" or "▼"
            if openByDefault then card.Size=UDim2.new(1,0,0,hdrH+contentH); inner.Size=UDim2.new(1,-8,0,contentH)
            else FT(card,{Size=UDim2.new(1,0,0,hdrH)}); FT(inner,{Size=UDim2.new(1,-8,0,0)}) end
        end
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.new(1,0,0,hdrH); hit.Text=""; hit.ZIndex=10; hit.Parent=card
        hit.MouseButton1Click:Connect(toggle)
        local innerAPI=win:_API(tabIdx,inner,theme)
        local o={}; for k,v in pairs(innerAPI) do o[k]=v end
        function o:Toggle()   toggle() end
        function o:IsOpen()   return openByDefault end
        function o:SetVisible(v) card.Visible=v end
        function o:Destroy()  card:Destroy() end
        return o
    end

    -- ── SPINNER ───────────────────────────────
    function api.Spinner(cfg)
        local title=cfg.Title or "Loading…"; local card=Card(44)
        local spin=G.Frame(card,theme.Accent,UDim2.fromOffset(22,22),UDim2.fromOffset(10,11),9)
        G.Corner(spin,11); G.Stroke(spin,theme.AccentDark,3); win:_TR(spin,"BackgroundColor3","Tertiary")
        local arc=G.Frame(spin,theme.Accent,UDim2.fromOffset(22,22),nil,10); G.Corner(arc,11); arc.BackgroundTransparency=1
        local arcS=G.Stroke(arc,theme.Accent,3); win:_TR(arcS,"Color","Accent")
        local lbl=G.Label(card,title,theme.TextMuted,UDim2.new(1,-44,1,0),UDim2.fromOffset(40,0),Enum.Font.Gotham,13,Enum.TextXAlignment.Left,8); win:_TR(lbl,"TextColor3","TextMuted")
        local running=true
        task.spawn(function()
            local r=0
            while card and card.Parent and running do
                r=(r+6)%360; spin.Rotation=r; task.wait(0.016)
            end
        end)
        local o={}
        function o:SetTitle(t) lbl.Text=t end
        function o:SetVisible(v) card.Visible=v; running=v end
        function o:Destroy() running=false; card:Destroy() end
        return o
    end

    -- ── STATUS INDICATOR ──────────────────────
    function api.StatusIndicator(cfg)
        local lbl=cfg.Label or "Status"; local status=cfg.Status or "idle"
        local SCOLS={online=Color3.fromRGB(48,208,108),offline=Color3.fromRGB(100,100,100),warning=Color3.fromRGB(235,168,26),idle=Color3.fromRGB(240,160,30),error=Color3.fromRGB(230,55,72)}
        local col=SCOLS[status] or cfg.Color or theme.Accent
        local card=Card(32)
        local dot=G.Frame(card,col,UDim2.fromOffset(10,10),UDim2.fromOffset(12,11),9); G.Corner(dot,5)
        task.spawn(function()
            while dot and dot.Parent do FT(dot,{BackgroundTransparency=.6}); task.wait(.75); FT(dot,{BackgroundTransparency=0}); task.wait(.75) end
        end)
        local tl=G.Label(card,lbl,theme.Text,UDim2.new(1,-100,1,0),UDim2.fromOffset(28,0),theme.Font,13,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")
        local sl=G.Label(card,status,col,UDim2.fromOffset(82,1),UDim2.new(1,-88,.5,-6),Enum.Font.GothamBold,11,Enum.TextXAlignment.Right,9)
        local o={}
        function o:SetStatus(s,c) status=s; col=SCOLS[s] or c or theme.Accent; FT(dot,{BackgroundColor3=col}); FT(sl,{TextColor3=col}); sl.Text=s end
        function o:SetLabel(t) tl.Text=t end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── LINE CHART ────────────────────────────
    function api.LineChart(cfg)
        local title=cfg.Title or "Chart"; local maxPts=cfg.MaxPoints or 40; local col=cfg.Color
        local yMin=cfg.YMin; local yMax=cfg.YMax  -- nil = auto-scale
        local points={}; local card=Card(cfg.Height or 100)
        G.Label(card,title,theme.TextMuted,UDim2.new(1,-16,0,16),UDim2.fromOffset(10,2),theme.Font,11,Enum.TextXAlignment.Left,8)
        local canvas=G.Frame(card,theme.Tertiary,UDim2.new(1,-16,1,-22),UDim2.fromOffset(8,18),8); G.Corner(canvas,3); win:_TR(canvas,"BackgroundColor3","Tertiary")
        local function redraw()
            for _,c in ipairs(canvas:GetChildren()) do if c.Name=="ChartLine" then c:Destroy() end end
            if #points<2 then return end
            local lo=yMin or math.huge; local hi=yMax or -math.huge
            if not yMin or not yMax then for _,p in ipairs(points) do lo=math.min(lo,p); hi=math.max(hi,p) end end
            local range=math.max(hi-lo,.001); local W=canvas.AbsoluteSize.X; local H=canvas.AbsoluteSize.Y
            for i=2,#points do
                local x1=U.Map(i-1,1,#points,0,W); local y1=H-U.Map(points[i-1],lo,hi+range*.05,0,H*.92)
                local x2=U.Map(i,  1,#points,0,W); local y2=H-U.Map(points[i],  lo,hi+range*.05,0,H*.92)
                local dx=x2-x1; local dy=y2-y1; local len=math.sqrt(dx*dx+dy*dy)
                local seg=G.Frame(canvas,col or theme.Accent,UDim2.fromOffset(len,2),UDim2.fromOffset(x1,y1),9)
                seg.Name="ChartLine"; seg.AnchorPoint=Vector2.new(0,.5)
                seg.Rotation=math.deg(math.atan2(dy,dx))
                win:_TR(seg,"BackgroundColor3",col and nil or "Accent")
            end
        end
        local o={}
        function o:Push(val)
            table.insert(points,val); if #points>maxPts then table.remove(points,1) end
            task.defer(redraw)
        end
        function o:Clear()  points={}; redraw() end
        function o:SetColor(c) col=c; redraw() end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── TABLE ─────────────────────────────────
    function api.Table(cfg)
        local headers=cfg.Headers or {}; local rows=cfg.Rows or {}; local cols=#headers; if cols==0 then return end
        local rH=26; local hH=30; local card=Card(math.min(hH+#rows*rH+10,250),true)
        local hRow=G.Frame(card,theme.Tertiary,UDim2.new(1,-4,0,hH),UDim2.fromOffset(2,2),8); G.Corner(hRow,4); win:_TR(hRow,"BackgroundColor3","Tertiary")
        for ci,hdr in ipairs(headers) do G.Label(hRow,tostring(hdr),theme.Accent,UDim2.fromScale(1/cols,1),UDim2.fromScale((ci-1)/cols,0),Enum.Font.GothamBold,11,Enum.TextXAlignment.Center,9) end
        local sc=G.Scroll(card,UDim2.new(1,-4,1,-(hH+4)),UDim2.fromOffset(2,hH+2),8); sc.ScrollBarImageColor3=theme.Accent; win:_TR(sc,"ScrollBarImageColor3","Accent")
        local rl=G.List(sc,nil,nil,nil,1); G.AutoCanvas(sc,rl,4)
        for ri,row in ipairs(rows) do
            local rFrame=G.Frame(sc,ri%2==0 and theme.Primary or theme.Secondary,UDim2.new(1,0,0,rH)); win:_TR(rFrame,"BackgroundColor3",ri%2==0 and "Primary" or "Secondary")
            for ci,cell in ipairs(row) do G.Label(rFrame,tostring(cell),theme.Text,UDim2.fromScale(1/cols,1),UDim2.fromScale((ci-1)/cols,0),Enum.Font.Gotham,11,Enum.TextXAlignment.Center,9) end
        end
        local o={}; function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end; return o
    end

    -- ── BADGE ─────────────────────────────────
    function api.Badge(cfg)
        local items=cfg.Items or {}; local card=Card(36)
        local cont=G.Frame(card,Color3.new(0,0,0),UDim2.fromScale(1,1)); cont.BackgroundTransparency=1; cont.ZIndex=8
        G.Pad(cont,6,6,6,8); G.List(cont,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center,4)
        local chips={}
        local function addChip(item)
            local col=item.Color or theme.Accent
            local chip=G.Frame(cont,col,UDim2.fromOffset(0,20)); chip.AutomaticSize=Enum.AutomaticSize.X; chip.ZIndex=9; G.Corner(chip,10); G.Pad(chip,3,8,3,8)
            local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.AutomaticSize=Enum.AutomaticSize.X; l.Size=UDim2.fromScale(1,1); l.Text=tostring(item.Text or ""); l.TextColor3=U.Contrast(col); l.Font=Enum.Font.GothamBold; l.TextSize=11; l.ZIndex=10; l.Parent=chip
            table.insert(chips,{chip=chip,label=item.Text})
            return chip
        end
        for _,item in ipairs(items) do addChip(item) end
        local o={}
        function o:Add(item) addChip(item) end
        function o:Remove(text) for i,c in ipairs(chips) do if c.label==text then c.chip:Destroy(); table.remove(chips,i); break end end end
        function o:Clear() for _,c in ipairs(chips) do c.chip:Destroy() end; chips={} end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── IMAGE ─────────────────────────────────
    function api.Image(cfg)
        local id=cfg.ID or ""; local height=cfg.Height or 120; local cap=cfg.Caption or ""
        local card=Card(height+(cap~=""and 28 or 8))
        local img=Instance.new("ImageLabel"); img.BackgroundTransparency=1; img.Size=UDim2.new(1,-16,0,height); img.Position=UDim2.fromOffset(8,4); img.Image="rbxassetid://"..id; img.ScaleType=Enum.ScaleType.Fit; img.ZIndex=8; img.Parent=card; G.Corner(img,4)
        if cap~="" then G.Label(card,cap,theme.TextMuted,UDim2.new(1,-16,0,20),UDim2.fromOffset(8,height+6),Enum.Font.Gotham,11,Enum.TextXAlignment.Center,8) end
        local o={}
        function o:SetImage(i) img.Image="rbxassetid://"..i end
        function o:SetVisible(v) card.Visible=v end; function o:Destroy() card:Destroy() end
        return o
    end

    return api
end

return Oxygen
