--[[
    ██████╗ ██╗  ██╗██╗   ██╗ ██████╗ ███████╗███╗   ██╗
   ██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝██╔════╝ ██╔════╝████╗  ██║
   ██║   ██║ ╚███╔╝  ╚████╔╝ ██║  ███╗█████╗  ██╔██╗ ██║
   ██║   ██║ ██╔██╗   ╚██╔╝  ██║   ██║██╔══╝  ██║╚██╗██║
   ╚██████╔╝██╔╝ ██╗   ██║   ╚██████╔╝███████╗██║ ╚████║
    ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝

    Oxygen UI Library  •  beta 0.0.1
    github.com/oxygen015/roblox-modules

    ── BUGS FIXED ──────────────────────────────────────────
    • Enum.UserInputType.MouseMove → MouseMovement  (was
      spamming "not a valid member" every frame on line 1109)
    • Drag connections are now per-window (no global bleed)
    • Slider / ColorPicker input types corrected everywhere
    • ColorPicker SV & Hue use the correct target frame for
      GetMouseXY instead of always reading HueTracker
    • Dropdown hit-area sized after layout (task.defer)
    • UIStroke no longer double-stacks on TextInput focus
    • Settings tab LayoutOrder fix (was reordering wrong)
    • AddConn scoped per-instance, not in a shared global

    ── NEW IN 0.0.1 ────────────────────────────────────────
    • 16 themes: Carbon, Midnight, Neon, Ocean, Forest,
      Mocha, Dracula, Blood, Light, Rose, Ice, Sunset,
      Sakura, Candy, Slate, Monochrome
    • Resizable window (drag bottom-right ⤡ handle)
    • Accent stripe under title bar
    • tab.Paragraph()  — titled multi-line text card
    • tab.Divider()    — full-width 1px rule
    • Component :Destroy() on every returned object
    • ui:SetWatermarkText(str) — live watermark update
    • Config:ImportFromClipboard() + Import from clipboard btn
    • Config:GetAll() — returns copy of entire saved table
    • Tooltip uses Mouse.Moved instead of RenderStepped
    • Notification position config (TopRight/BottomRight/etc)
    • Stepper button hover colour animations
]]

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ════════════════════════════════════════════════════════════
-- SIGNAL
-- ════════════════════════════════════════════════════════════
local Signal = {}
Signal.__index = Signal
function Signal.new()
    return setmetatable({ _c = {} }, Signal)
end
function Signal:Connect(fn)
    local c = { _fn=fn, _s=self, Connected=true }
    table.insert(self._c, c)
    function c:Disconnect()
        self.Connected = false
        for i,v in ipairs(self._s._c) do
            if v==self then table.remove(self._s._c,i); break end
        end
    end
    return c
end
function Signal:Fire(...)
    for _,c in ipairs(self._c) do task.spawn(c._fn,...) end
end
function Signal:Destroy() self._c = {} end

-- ════════════════════════════════════════════════════════════
-- UTILITY
-- ════════════════════════════════════════════════════════════
local Util = {}

function Util.Tween(obj, info, props)
    if not obj or not obj.Parent then return end
    local ok, t = pcall(TweenService.Create, TweenService, obj, info, props)
    if ok then t:Play(); return t end
end

local _FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local _MED    = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local _SPRING = TweenInfo.new(0.55, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

function Util.FT(o,p)  return Util.Tween(o, _FAST,   p) end
function Util.MT(o,p)  return Util.Tween(o, _MED,    p) end
function Util.SP(o,p)  return Util.Tween(o, _SPRING, p) end

function Util.GetXY(frame)
    local ap = frame.AbsolutePosition
    local as = frame.AbsoluteSize
    local mx = math.clamp(Mouse.X - ap.X, 0, as.X)
    local my = math.clamp(Mouse.Y - ap.Y, 0, as.Y)
    return mx / math.max(as.X,1), my / math.max(as.Y,1)
end

function Util.Ripple(parent, color)
    if not parent or not parent.Parent then return end
    local px,py = Util.GetXY(parent)
    local c = Instance.new("ImageLabel")
    c.BackgroundTransparency = 1
    c.Image  = "rbxassetid://5554831670"
    c.ImageColor3 = color or Color3.new(1,1,1)
    c.ImageTransparency = 0.6
    c.ZIndex = parent.ZIndex + 20
    c.Size   = UDim2.fromOffset(0,0)
    c.Position = UDim2.fromScale(px,py)
    c.AnchorPoint = Vector2.new(0.5,0.5)
    c.Parent = parent
    local sz = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    Util.Tween(c, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size=UDim2.fromOffset(sz,sz), ImageTransparency=1
    })
    task.delay(0.6, function() if c.Parent then c:Destroy() end end)
end

function Util.Lerp(a,b,t) return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t) end
function Util.Contrast(bg)
    return (0.299*bg.R+0.587*bg.G+0.114*bg.B)>0.5 and Color3.new(0,0,0) or Color3.new(1,1,1)
end
function Util.Round(n,d) local m=10^(d or 0); return math.floor(n*m+0.5)/m end
function Util.Has(t,v)  for _,x in ipairs(t) do if x==v then return true end end return false end
function Util.Copy(t)   local c={}; for k,v in pairs(t) do c[k]=type(v)=="table"and Util.Copy(v)or v end; return c end

function Util.Call(fn,...)
    if type(fn)~="function" then return end
    local ok,err = pcall(fn,...)
    if not ok then warn("[Oxygen] callback: "..tostring(err)) end
end

function Util.Hex(c)
    return string.format("#%02X%02X%02X",
        math.clamp(math.floor(c.R*255+.5),0,255),
        math.clamp(math.floor(c.G*255+.5),0,255),
        math.clamp(math.floor(c.B*255+.5),0,255))
end

function Util.FromHex(h)
    h = h:gsub("#","")
    if #h~=6 then return Color3.new(1,1,1) end
    local ok,r,g,b = pcall(function()
        return tonumber(h:sub(1,2),16)/255,
               tonumber(h:sub(3,4),16)/255,
               tonumber(h:sub(5,6),16)/255
    end)
    return ok and Color3.new(r,g,b) or Color3.new(1,1,1)
end

-- ════════════════════════════════════════════════════════════
-- GUI BUILDER HELPERS
-- ════════════════════════════════════════════════════════════
local function Corner(p,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c
end
local function Pad(p,t,r,b,l)
    local u=Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,t or 5); u.PaddingRight=UDim.new(0,r or 5)
    u.PaddingBottom=UDim.new(0,b or 5); u.PaddingLeft=UDim.new(0,l or 5)
    u.Parent=p; return u
end
local function List(p,dir,ha,va,pad)
    local l=Instance.new("UIListLayout")
    l.FillDirection=dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment=va or Enum.VerticalAlignment.Top
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Padding=UDim.new(0,pad or 5)
    l.Parent=p; return l
end
local function Stroke(p,col,th)
    local s=Instance.new("UIStroke")
    s.Color=col or Color3.new(1,1,1); s.Thickness=th or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end
local function Shadow(p,col,zi)
    local s=Instance.new("ImageLabel")
    s.Name="Shadow"; s.BackgroundTransparency=1
    s.Image="rbxassetid://5554236805"; s.ScaleType=Enum.ScaleType.Slice
    s.SliceCenter=Rect.new(23,23,277,277)
    s.ImageColor3=col or Color3.new(0,0,0); s.ImageTransparency=0.55
    s.Size=UDim2.fromScale(1,1)+UDim2.fromOffset(34,34)
    s.Position=UDim2.fromOffset(-17,-17); s.ZIndex=(zi or 2)-1; s.Parent=p; return s
end
local function MkFrame(p,col,sz,pos,zi,clips)
    local f=Instance.new("Frame")
    f.BackgroundColor3=col or Color3.new(0.15,0.15,0.15)
    f.BorderSizePixel=0; f.Size=sz or UDim2.fromScale(1,1)
    f.Position=pos or UDim2.fromScale(0,0); f.ZIndex=zi or 1
    f.ClipsDescendants=clips or false; f.Parent=p; return f
end
local function MkLabel(p,txt,col,sz,pos,font,ts,xi,zi)
    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1; l.Text=txt or ""
    l.TextColor3=col or Color3.new(1,1,1); l.Size=sz or UDim2.fromScale(1,1)
    l.Position=pos or UDim2.fromScale(0,0); l.Font=font or Enum.Font.Gotham
    l.TextSize=ts or 14; l.TextXAlignment=xi or Enum.TextXAlignment.Left
    l.ZIndex=zi or 2; l.Parent=p; return l
end

-- ════════════════════════════════════════════════════════════
-- THEMES  (16)
-- ════════════════════════════════════════════════════════════
local Themes = {}

-- helper
local function Th(t) return t end

Themes.Carbon = Th({
    Name="Carbon",
    Primary=Color3.fromRGB(18,18,24),       Secondary=Color3.fromRGB(28,28,38),
    Tertiary=Color3.fromRGB(42,42,58),      Accent=Color3.fromRGB(110,70,255),
    AccentDark=Color3.fromRGB(80,45,200),   Text=Color3.fromRGB(238,238,245),
    TextMuted=Color3.fromRGB(140,140,165),  TextDark=Color3.fromRGB(10,10,18),
    Success=Color3.fromRGB(50,215,115),     Warning=Color3.fromRGB(255,185,40),
    Error=Color3.fromRGB(255,65,80),        Info=Color3.fromRGB(70,175,255),
    Shadow=Color3.fromRGB(0,0,0),           Border=Color3.fromRGB(50,50,68),
    TitleBar=Color3.fromRGB(22,22,30),      NavBar=Color3.fromRGB(18,18,26),
    Toggle=Color3.fromRGB(110,70,255),      Slider=Color3.fromRGB(110,70,255),
    Radius=8, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})
Themes.Midnight = Th({
    Name="Midnight",
    Primary=Color3.fromRGB(6,6,10),         Secondary=Color3.fromRGB(13,13,20),
    Tertiary=Color3.fromRGB(20,20,34),      Accent=Color3.fromRGB(170,90,255),
    AccentDark=Color3.fromRGB(130,60,220),  Text=Color3.fromRGB(228,222,245),
    TextMuted=Color3.fromRGB(120,115,150),  TextDark=Color3.fromRGB(6,6,10),
    Success=Color3.fromRGB(75,215,135),     Warning=Color3.fromRGB(255,195,45),
    Error=Color3.fromRGB(255,65,85),        Info=Color3.fromRGB(90,175,255),
    Shadow=Color3.fromRGB(0,0,0),           Border=Color3.fromRGB(28,25,42),
    TitleBar=Color3.fromRGB(10,8,16),       NavBar=Color3.fromRGB(8,6,14),
    Toggle=Color3.fromRGB(170,90,255),      Slider=Color3.fromRGB(170,90,255),
    Radius=8, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})
Themes.Neon = Th({
    Name="Neon",
    Primary=Color3.fromRGB(4,4,8),          Secondary=Color3.fromRGB(10,12,20),
    Tertiary=Color3.fromRGB(18,20,38),      Accent=Color3.fromRGB(0,245,190),
    AccentDark=Color3.fromRGB(0,190,148),   Text=Color3.fromRGB(210,255,248),
    TextMuted=Color3.fromRGB(90,172,158),   TextDark=Color3.fromRGB(4,4,8),
    Success=Color3.fromRGB(0,255,145),      Warning=Color3.fromRGB(255,215,0),
    Error=Color3.fromRGB(255,45,95),        Info=Color3.fromRGB(0,195,255),
    Shadow=Color3.fromRGB(0,220,180),       Border=Color3.fromRGB(0,80,65),
    TitleBar=Color3.fromRGB(8,8,16),        NavBar=Color3.fromRGB(6,6,14),
    Toggle=Color3.fromRGB(0,245,190),       Slider=Color3.fromRGB(0,245,190),
    Radius=4, Font=Enum.Font.Code, FontTitle=Enum.Font.Code,
})
Themes.Ocean = Th({
    Name="Ocean",
    Primary=Color3.fromRGB(6,16,36),        Secondary=Color3.fromRGB(10,24,52),
    Tertiary=Color3.fromRGB(16,38,78),      Accent=Color3.fromRGB(25,155,255),
    AccentDark=Color3.fromRGB(15,115,210),  Text=Color3.fromRGB(195,228,255),
    TextMuted=Color3.fromRGB(90,145,198),   TextDark=Color3.fromRGB(6,16,36),
    Success=Color3.fromRGB(35,215,135),     Warning=Color3.fromRGB(255,195,35),
    Error=Color3.fromRGB(255,75,75),        Info=Color3.fromRGB(25,155,255),
    Shadow=Color3.fromRGB(0,15,55),         Border=Color3.fromRGB(22,55,106),
    TitleBar=Color3.fromRGB(8,20,44),       NavBar=Color3.fromRGB(6,16,38),
    Toggle=Color3.fromRGB(25,155,255),      Slider=Color3.fromRGB(25,155,255),
    Radius=8, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})
Themes.Forest = Th({
    Name="Forest",
    Primary=Color3.fromRGB(14,22,16),       Secondary=Color3.fromRGB(22,38,24),
    Tertiary=Color3.fromRGB(34,58,36),      Accent=Color3.fromRGB(72,195,95),
    AccentDark=Color3.fromRGB(50,150,68),   Text=Color3.fromRGB(205,238,210),
    TextMuted=Color3.fromRGB(110,168,120),  TextDark=Color3.fromRGB(14,22,16),
    Success=Color3.fromRGB(72,195,95),      Warning=Color3.fromRGB(215,185,45),
    Error=Color3.fromRGB(215,75,75),        Info=Color3.fromRGB(75,175,215),
    Shadow=Color3.fromRGB(4,12,6),          Border=Color3.fromRGB(38,68,40),
    TitleBar=Color3.fromRGB(18,28,20),      NavBar=Color3.fromRGB(14,24,16),
    Toggle=Color3.fromRGB(72,195,95),       Slider=Color3.fromRGB(72,195,95),
    Radius=6, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})
Themes.Mocha = Th({
    Name="Mocha",
    Primary=Color3.fromRGB(38,28,18),       Secondary=Color3.fromRGB(58,44,28),
    Tertiary=Color3.fromRGB(82,62,42),      Accent=Color3.fromRGB(195,148,92),
    AccentDark=Color3.fromRGB(158,115,65),  Text=Color3.fromRGB(242,228,210),
    TextMuted=Color3.fromRGB(168,142,112),  TextDark=Color3.fromRGB(38,28,18),
    Success=Color3.fromRGB(75,180,100),     Warning=Color3.fromRGB(210,170,40),
    Error=Color3.fromRGB(205,65,65),        Info=Color3.fromRGB(95,165,215),
    Shadow=Color3.fromRGB(15,10,5),         Border=Color3.fromRGB(88,65,44),
    TitleBar=Color3.fromRGB(48,34,22),      NavBar=Color3.fromRGB(40,28,18),
    Toggle=Color3.fromRGB(195,148,92),      Slider=Color3.fromRGB(195,148,92),
    Radius=8, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})
Themes.Dracula = Th({
    Name="Dracula",
    Primary=Color3.fromRGB(40,42,54),       Secondary=Color3.fromRGB(48,50,64),
    Tertiary=Color3.fromRGB(58,60,76),      Accent=Color3.fromRGB(189,147,249),
    AccentDark=Color3.fromRGB(148,108,215), Text=Color3.fromRGB(248,248,242),
    TextMuted=Color3.fromRGB(148,148,148),  TextDark=Color3.fromRGB(40,42,54),
    Success=Color3.fromRGB(80,250,123),     Warning=Color3.fromRGB(241,250,140),
    Error=Color3.fromRGB(255,85,85),        Info=Color3.fromRGB(139,233,253),
    Shadow=Color3.fromRGB(10,10,15),        Border=Color3.fromRGB(68,70,88),
    TitleBar=Color3.fromRGB(44,46,60),      NavBar=Color3.fromRGB(38,40,52),
    Toggle=Color3.fromRGB(189,147,249),     Slider=Color3.fromRGB(189,147,249),
    Radius=6, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})
Themes.Blood = Th({
    Name="Blood",
    Primary=Color3.fromRGB(14,4,4),         Secondary=Color3.fromRGB(28,8,8),
    Tertiary=Color3.fromRGB(48,14,14),      Accent=Color3.fromRGB(220,35,50),
    AccentDark=Color3.fromRGB(175,22,35),   Text=Color3.fromRGB(245,210,210),
    TextMuted=Color3.fromRGB(158,100,100),  TextDark=Color3.fromRGB(14,4,4),
    Success=Color3.fromRGB(60,190,90),      Warning=Color3.fromRGB(230,175,35),
    Error=Color3.fromRGB(220,35,50),        Info=Color3.fromRGB(80,160,235),
    Shadow=Color3.fromRGB(0,0,0),           Border=Color3.fromRGB(55,18,18),
    TitleBar=Color3.fromRGB(22,6,6),        NavBar=Color3.fromRGB(16,4,4),
    Toggle=Color3.fromRGB(220,35,50),       Slider=Color3.fromRGB(220,35,50),
    Radius=6, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})
Themes.Monochrome = Th({
    Name="Monochrome",
    Primary=Color3.fromRGB(12,12,12),       Secondary=Color3.fromRGB(22,22,22),
    Tertiary=Color3.fromRGB(36,36,36),      Accent=Color3.fromRGB(220,220,220),
    AccentDark=Color3.fromRGB(165,165,165), Text=Color3.fromRGB(240,240,240),
    TextMuted=Color3.fromRGB(130,130,130),  TextDark=Color3.fromRGB(12,12,12),
    Success=Color3.fromRGB(190,190,190),    Warning=Color3.fromRGB(210,210,210),
    Error=Color3.fromRGB(255,255,255),      Info=Color3.fromRGB(155,155,155),
    Shadow=Color3.fromRGB(0,0,0),           Border=Color3.fromRGB(48,48,48),
    TitleBar=Color3.fromRGB(18,18,18),      NavBar=Color3.fromRGB(14,14,14),
    Toggle=Color3.fromRGB(210,210,210),     Slider=Color3.fromRGB(210,210,210),
    Radius=4, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})
Themes.Slate = Th({
    Name="Slate",
    Primary=Color3.fromRGB(30,35,42),       Secondary=Color3.fromRGB(40,46,55),
    Tertiary=Color3.fromRGB(52,60,70),      Accent=Color3.fromRGB(95,180,230),
    AccentDark=Color3.fromRGB(70,145,195),  Text=Color3.fromRGB(215,225,235),
    TextMuted=Color3.fromRGB(118,138,158),  TextDark=Color3.fromRGB(30,35,42),
    Success=Color3.fromRGB(65,200,120),     Warning=Color3.fromRGB(245,185,40),
    Error=Color3.fromRGB(235,75,80),        Info=Color3.fromRGB(95,180,230),
    Shadow=Color3.fromRGB(10,12,16),        Border=Color3.fromRGB(55,65,78),
    TitleBar=Color3.fromRGB(35,40,50),      NavBar=Color3.fromRGB(28,32,40),
    Toggle=Color3.fromRGB(95,180,230),      Slider=Color3.fromRGB(95,180,230),
    Radius=6, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})
-- light themes
Themes.Light = Th({
    Name="Light",
    Primary=Color3.fromRGB(246,246,252),    Secondary=Color3.fromRGB(232,232,242),
    Tertiary=Color3.fromRGB(215,215,232),   Accent=Color3.fromRGB(92,52,238),
    AccentDark=Color3.fromRGB(68,36,198),   Text=Color3.fromRGB(22,22,34),
    TextMuted=Color3.fromRGB(112,112,142),  TextDark=Color3.fromRGB(246,246,252),
    Success=Color3.fromRGB(35,178,95),      Warning=Color3.fromRGB(202,158,22),
    Error=Color3.fromRGB(202,44,60),        Info=Color3.fromRGB(52,135,220),
    Shadow=Color3.fromRGB(140,140,175),     Border=Color3.fromRGB(192,192,215),
    TitleBar=Color3.fromRGB(92,52,238),     NavBar=Color3.fromRGB(80,44,218),
    Toggle=Color3.fromRGB(92,52,238),       Slider=Color3.fromRGB(92,52,238),
    Radius=10, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})
Themes.Rose = Th({
    Name="Rose",
    Primary=Color3.fromRGB(255,244,248),    Secondary=Color3.fromRGB(255,228,238),
    Tertiary=Color3.fromRGB(255,208,224),   Accent=Color3.fromRGB(215,52,94),
    AccentDark=Color3.fromRGB(175,35,72),   Text=Color3.fromRGB(48,18,28),
    TextMuted=Color3.fromRGB(145,92,110),   TextDark=Color3.fromRGB(255,244,248),
    Success=Color3.fromRGB(55,175,95),      Warning=Color3.fromRGB(215,145,28),
    Error=Color3.fromRGB(195,35,55),        Info=Color3.fromRGB(75,135,215),
    Shadow=Color3.fromRGB(175,75,95),       Border=Color3.fromRGB(215,172,185),
    TitleBar=Color3.fromRGB(215,52,94),     NavBar=Color3.fromRGB(195,44,82),
    Toggle=Color3.fromRGB(215,52,94),       Slider=Color3.fromRGB(215,52,94),
    Radius=12, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})
Themes.Ice = Th({
    Name="Ice",
    Primary=Color3.fromRGB(238,248,255),    Secondary=Color3.fromRGB(215,238,255),
    Tertiary=Color3.fromRGB(188,222,252),   Accent=Color3.fromRGB(50,138,218),
    AccentDark=Color3.fromRGB(32,106,182),  Text=Color3.fromRGB(18,48,88),
    TextMuted=Color3.fromRGB(92,136,180),   TextDark=Color3.fromRGB(238,248,255),
    Success=Color3.fromRGB(35,178,115),     Warning=Color3.fromRGB(202,158,25),
    Error=Color3.fromRGB(202,50,65),        Info=Color3.fromRGB(50,138,218),
    Shadow=Color3.fromRGB(92,155,215),      Border=Color3.fromRGB(165,210,245),
    TitleBar=Color3.fromRGB(50,138,218),    NavBar=Color3.fromRGB(42,122,200),
    Toggle=Color3.fromRGB(50,138,218),      Slider=Color3.fromRGB(50,138,218),
    Radius=12, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})
Themes.Sunset = Th({
    Name="Sunset",
    Primary=Color3.fromRGB(255,235,208),    Secondary=Color3.fromRGB(255,215,175),
    Tertiary=Color3.fromRGB(255,192,140),   Accent=Color3.fromRGB(228,92,32),
    AccentDark=Color3.fromRGB(190,68,18),   Text=Color3.fromRGB(58,28,12),
    TextMuted=Color3.fromRGB(155,105,68),   TextDark=Color3.fromRGB(255,235,208),
    Success=Color3.fromRGB(55,175,78),      Warning=Color3.fromRGB(228,165,18),
    Error=Color3.fromRGB(205,45,45),        Info=Color3.fromRGB(55,135,215),
    Shadow=Color3.fromRGB(175,75,18),       Border=Color3.fromRGB(220,175,132),
    TitleBar=Color3.fromRGB(228,92,32),     NavBar=Color3.fromRGB(205,78,22),
    Toggle=Color3.fromRGB(228,92,32),       Slider=Color3.fromRGB(228,92,32),
    Radius=10, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})
Themes.Sakura = Th({
    Name="Sakura",
    Primary=Color3.fromRGB(255,242,248),    Secondary=Color3.fromRGB(252,225,240),
    Tertiary=Color3.fromRGB(248,205,228),   Accent=Color3.fromRGB(225,100,160),
    AccentDark=Color3.fromRGB(188,72,128),  Text=Color3.fromRGB(62,22,45),
    TextMuted=Color3.fromRGB(162,108,138),  TextDark=Color3.fromRGB(255,242,248),
    Success=Color3.fromRGB(80,188,115),     Warning=Color3.fromRGB(215,168,38),
    Error=Color3.fromRGB(215,55,80),        Info=Color3.fromRGB(105,148,225),
    Shadow=Color3.fromRGB(200,120,160),     Border=Color3.fromRGB(230,185,210),
    TitleBar=Color3.fromRGB(225,100,160),   NavBar=Color3.fromRGB(205,82,142),
    Toggle=Color3.fromRGB(225,100,160),     Slider=Color3.fromRGB(225,100,160),
    Radius=14, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})
Themes.Candy = Th({
    Name="Candy",
    Primary=Color3.fromRGB(255,240,255),    Secondary=Color3.fromRGB(250,220,255),
    Tertiary=Color3.fromRGB(242,195,255),   Accent=Color3.fromRGB(198,60,255),
    AccentDark=Color3.fromRGB(158,38,210),  Text=Color3.fromRGB(52,8,72),
    TextMuted=Color3.fromRGB(155,98,178),   TextDark=Color3.fromRGB(255,240,255),
    Success=Color3.fromRGB(60,205,120),     Warning=Color3.fromRGB(255,182,30),
    Error=Color3.fromRGB(255,60,90),        Info=Color3.fromRGB(60,180,255),
    Shadow=Color3.fromRGB(180,80,220),      Border=Color3.fromRGB(228,185,248),
    TitleBar=Color3.fromRGB(198,60,255),    NavBar=Color3.fromRGB(175,45,228),
    Toggle=Color3.fromRGB(198,60,255),      Slider=Color3.fromRGB(198,60,255),
    Radius=14, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

-- ════════════════════════════════════════════════════════════
-- CONFIG SYSTEM
-- ════════════════════════════════════════════════════════════
local CfgMeta = {}; CfgMeta.__index = CfgMeta
function CfgMeta.new(name)
    local s=setmetatable({name=name, file=name.."_Config.json", data={}}, CfgMeta)
    s:Load(); return s
end
function CfgMeta:Load()
    pcall(function()
        if readfile then self.data=HttpService:JSONDecode(readfile(self.file)) end
    end); self.data=self.data or {}
end
function CfgMeta:Save()
    pcall(function()
        if writefile then writefile(self.file, HttpService:JSONEncode(self.data)) end
    end)
end
function CfgMeta:Set(k,v)   self.data[k]=v; self:Save() end
function CfgMeta:Get(k,def) return self.data[k]~=nil and self.data[k] or def end
function CfgMeta:Reset()    self.data={}; self:Save() end
function CfgMeta:GetAll()   return Util.Copy(self.data) end
function CfgMeta:Export()
    local ok,s=pcall(HttpService.JSONEncode,HttpService,self.data); return ok and s or "{}"
end
function CfgMeta:Import(json)
    local ok,d=pcall(HttpService.JSONDecode,HttpService,json)
    if ok and type(d)=="table" then self.data=d; self:Save(); return true end; return false
end
function CfgMeta:ImportFromClipboard()
    local ok,t=pcall(function() return getclipboard() end)
    if ok and t then return self:Import(t) end; return false
end

-- ════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ════════════════════════════════════════════════════════════
local NPOS = {
    BottomRight={anchor=Vector2.new(1,1), pos=UDim2.new(1,-10,1,-10),  va=Enum.VerticalAlignment.Bottom},
    TopRight   ={anchor=Vector2.new(1,0), pos=UDim2.new(1,-10,0,10),   va=Enum.VerticalAlignment.Top},
    BottomLeft ={anchor=Vector2.new(0,1), pos=UDim2.new(0,10,1,-10),   va=Enum.VerticalAlignment.Bottom},
    TopLeft    ={anchor=Vector2.new(0,0), pos=UDim2.new(0,10,0,10),    va=Enum.VerticalAlignment.Top},
}
local NTYPES = {
    success={icon="✓", col=Color3.fromRGB(48,198,110)},
    warning={icon="!", col=Color3.fromRGB(238,172,28)},
    error  ={icon="✕", col=Color3.fromRGB(232,58,75)},
    info   ={icon="i", col=Color3.fromRGB(62,162,252)},
}

local Notifs = {}; Notifs.__index = Notifs
function Notifs.new(sg, pos)
    local s=setmetatable({_order=0}, Notifs)
    local pd=NPOS[pos or "BottomRight"]
    s.cont=MkFrame(sg, Color3.new(0,0,0), UDim2.fromOffset(320,0), pd.pos, 500)
    s.cont.BackgroundTransparency=1; s.cont.AnchorPoint=pd.anchor
    local l=List(s.cont,nil, Enum.HorizontalAlignment.Left, pd.va, 8)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s.cont.Size=UDim2.fromOffset(320, l.AbsoluteContentSize.Y+10)
    end)
    return s
end
function Notifs:Push(cfg, th)
    local title=cfg.Title or ""; local desc=cfg.Description or ""
    local ntype=cfg.Type or "info"; local dur=cfg.Duration or 4; local cb=cfg.Callback
    local td=NTYPES[ntype] or NTYPES.info
    self._order+=1

    local card=MkFrame(self.cont, th.Secondary, UDim2.fromOffset(320,68))
    card.ClipsDescendants=true; card.ZIndex=500; card.LayoutOrder=self._order
    Corner(card,10); Stroke(card,th.Border,1); Shadow(card,th.Shadow,500)

    MkFrame(card, td.col, UDim2.fromOffset(4,68)); Corner(MkFrame(card,Util.Lerp(td.col,Color3.new(0,0,0),0.6),UDim2.fromOffset(26,26),UDim2.fromOffset(14,21),501),13)
    MkLabel(card, td.icon, td.col, UDim2.fromOffset(26,26), UDim2.fromOffset(14,21), Enum.Font.GothamBold,16,Enum.TextXAlignment.Center,502)
    MkLabel(card, title, th.Text, UDim2.fromOffset(240,20), UDim2.fromOffset(50,8), Enum.Font.GothamBold,14,Enum.TextXAlignment.Left,501)
    local dl=MkLabel(card, desc, th.TextMuted, UDim2.fromOffset(255,34), UDim2.fromOffset(50,28), Enum.Font.Gotham,11,Enum.TextXAlignment.Left,501)
    dl.TextWrapped=true
    local xb=Instance.new("TextButton")
    xb.BackgroundTransparency=1; xb.Size=UDim2.fromOffset(20,20)
    xb.Position=UDim2.new(1,-26,0,4); xb.Text="×"; xb.TextColor3=th.TextMuted
    xb.Font=Enum.Font.GothamBold; xb.TextSize=20; xb.ZIndex=502; xb.Parent=card

    local pf=MkFrame(card,td.col,UDim2.fromOffset(0,3)); pf.Position=UDim2.new(0,0,1,-3); pf.ZIndex=501
    Util.Tween(pf,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.fromOffset(320,3)})

    card.Position=UDim2.fromOffset(340,0)
    Util.SP(card,{Position=UDim2.fromOffset(0,0)})

    local dismissed=false
    local function dismiss()
        if dismissed then return end; dismissed=true
        Util.FT(card,{Position=UDim2.fromOffset(340,0)})
        task.delay(0.2,function() if card.Parent then card:Destroy() end end)
    end
    xb.MouseButton1Click:Connect(dismiss)
    if cb then
        card.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then Util.Call(cb); dismiss() end
        end)
    end
    task.delay(dur, dismiss)
    return {Dismiss=dismiss}
end

-- ════════════════════════════════════════════════════════════
-- TOOLTIP
-- ════════════════════════════════════════════════════════════
local function Tooltip(el, text, th, sg)
    if not text or text=="" then return end
    local tip, mc
    el.MouseEnter:Connect(function()
        if tip then tip:Destroy() end
        tip=MkFrame(sg, th.Tertiary, UDim2.fromOffset(10,24), nil, 9000)
        Corner(tip,5); Shadow(tip,th.Shadow,9000); Stroke(tip,th.Border,1)
        local tw=TextService:GetTextSize(text,11,Enum.Font.Gotham,Vector2.new(9999,9999)).X
        tip.Size=UDim2.fromOffset(tw+18,24)
        MkLabel(tip,text,th.Text,UDim2.fromScale(1,1),nil,Enum.Font.Gotham,11,Enum.TextXAlignment.Center,9001)
        mc=Mouse.Moved:Connect(function()
            if tip and tip.Parent then tip.Position=UDim2.fromOffset(Mouse.X+14,Mouse.Y-30) end
        end)
        tip.Position=UDim2.fromOffset(Mouse.X+14,Mouse.Y-30)
    end)
    el.MouseLeave:Connect(function()
        if mc then mc:Disconnect(); mc=nil end
        if tip then tip:Destroy(); tip=nil end
    end)
end

-- ════════════════════════════════════════════════════════════
-- MAIN LIBRARY
-- ════════════════════════════════════════════════════════════
local Oxygen={}; Oxygen.__index=Oxygen
Oxygen.Version = "beta 0.0.1"
Oxygen.Themes  = Themes

function Oxygen.new(cfg)
    local self=setmetatable({},Oxygen)
    cfg=cfg or {}
    self.Title      = cfg.Title       or "Oxygen"
    self.Subtitle   = cfg.Subtitle    or "beta 0.0.1"
    self.ThemeName  = cfg.Theme       or "Carbon"
    self.SizeX      = cfg.SizeX       or 580
    self.SizeY      = cfg.SizeY       or 420
    self.DoSave     = cfg.SaveConfig  ~= false
    self.CfgName    = cfg.ConfigName  or self.Title
    self.ShowWM     = cfg.Watermark   ~= false
    self.ToggleKey  = cfg.ToggleKey   or Enum.KeyCode.RightControl
    self.MinKey     = cfg.MinimizeKey or Enum.KeyCode.RightShift
    self.NotifPos   = cfg.NotifPos    or "BottomRight"
    self.Theme      = Themes[self.ThemeName] or Themes.Carbon
    self.Tabs       = {}
    self._conns     = {}
    self.Visible    = true
    self.Minimized  = false
    self.ActiveTab  = 1
    if self.DoSave then self.Cfg=CfgMeta.new(self.CfgName) end
    self:_Build()
    self:_BuildSettings()
    self:_Keys()
    self:_Watermark()
    return self
end

function Oxygen:_C(c) table.insert(self._conns,c) end

function Oxygen:_ProtectGui(g)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(g); g.Parent=CoreGui
        elseif gethui then g.Parent=gethui()
        else g.Parent=CoreGui end
    end)
    if not g.Parent then g.Parent=LocalPlayer:WaitForChild("PlayerGui") end
end

-- ════════════════════════════════════════════════════════════
-- BUILD WINDOW
-- ════════════════════════════════════════════════════════════
function Oxygen:_Build()
    local th=self.Theme
    self.SG=Instance.new("ScreenGui")
    self.SG.Name="OxygenUI_"..self.Title
    self.SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    self.SG.ResetOnSpawn=false
    self:_ProtectGui(self.SG)

    self.NotifsObj=Notifs.new(self.SG, self.NotifPos)

    -- window
    self.Win=MkFrame(self.SG, th.Primary,
        UDim2.fromOffset(self.SizeX,self.SizeY),
        UDim2.fromScale(0.5,0.5), 10)
    self.Win.AnchorPoint=Vector2.new(0.5,0.5)
    self.Win.ClipsDescendants=true
    Corner(self.Win,th.Radius); Shadow(self.Win,th.Shadow,10); Stroke(self.Win,th.Border,1)
    self.Win.Size=UDim2.fromOffset(0,0)
    Util.SP(self.Win,{Size=UDim2.fromOffset(self.SizeX,self.SizeY)})

    -- title bar
    self.TBar=MkFrame(self.Win, th.TitleBar, UDim2.fromOffset(self.SizeX,44), nil, 15)

    -- accent stripe
    self._stripe=MkFrame(self.TBar, th.Accent, UDim2.fromOffset(self.SizeX,2), UDim2.new(0,0,1,-2), 16)

    -- logo pip
    self._pip=MkFrame(self.TBar, th.Accent, UDim2.fromOffset(8,8), UDim2.fromOffset(12,18), 16)
    Corner(self._pip,4)

    -- title
    self._tLbl=MkLabel(self.TBar, self.Title, th.Text,
        UDim2.fromOffset(220,26), UDim2.fromOffset(28,5),
        th.FontTitle, 16, Enum.TextXAlignment.Left, 16)

    self._sLbl=MkLabel(self.TBar, self.Subtitle, th.TextMuted,
        UDim2.fromOffset(220,14), UDim2.fromOffset(28,25),
        Enum.Font.Gotham, 10, Enum.TextXAlignment.Left, 16)

    -- window buttons
    local function WBtn(xo,col,ic)
        local b=Instance.new("TextButton")
        b.BackgroundColor3=col; b.BorderSizePixel=0
        b.Size=UDim2.fromOffset(12,12); b.Position=UDim2.new(1,xo,0.5,-6)
        b.Text=""; b.ZIndex=17; b.Parent=self.TBar; Corner(b,6)
        local il=MkLabel(b,ic,Color3.new(0,0,0),UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,9,Enum.TextXAlignment.Center,18)
        il.TextTransparency=1
        b.MouseEnter:Connect(function() Util.FT(il,{TextTransparency=0}) end)
        b.MouseLeave:Connect(function() Util.FT(il,{TextTransparency=1}) end)
        return b
    end
    WBtn(-22,Color3.fromRGB(255,88,78), "×").MouseButton1Click:Connect(function() self:Destroy() end)
    WBtn(-40,Color3.fromRGB(255,183,28),"−").MouseButton1Click:Connect(function() self:ToggleMinimize() end)
    WBtn(-58,Color3.fromRGB(38,200,64), "⤢").MouseButton1Click:Connect(function() self:Toggle() end)

    -- drag
    local drag,dS,wS
    self.TBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; dS=Vector2.new(Mouse.X,Mouse.Y); wS=self.Win.Position
        end
    end)
    self:_C(UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=Vector2.new(Mouse.X-dS.X, Mouse.Y-dS.Y)
            self.Win.Position=UDim2.new(wS.X.Scale,wS.X.Offset+d.X, wS.Y.Scale,wS.Y.Offset+d.Y)
        end
    end))
    self:_C(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end))

    -- resize handle
    local rh=MkFrame(self.Win,Color3.new(0,0,0),UDim2.fromOffset(16,16),UDim2.new(1,-16,1,-16),20)
    rh.BackgroundTransparency=1
    local ric=MkLabel(rh,"⤡",th.TextMuted,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,12,Enum.TextXAlignment.Center,21)
    local res,rS,rW
    rh.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            res=true; rS=Vector2.new(Mouse.X,Mouse.Y); rW=self.Win.AbsoluteSize
        end
    end)
    self:_C(UserInputService.InputChanged:Connect(function(i)
        if res and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=Vector2.new(Mouse.X-rS.X, Mouse.Y-rS.Y)
            local nx=math.max(rW.X+d.X,380); local ny=math.max(rW.Y+d.Y,260)
            self.Win.Size=UDim2.fromOffset(nx,ny)
            self.SizeX=nx; self.SizeY=ny
            if self.TBar   then self.TBar.Size=UDim2.fromOffset(nx,44) end
            if self._stripe then self._stripe.Size=UDim2.fromOffset(nx,2) end
            if self.SideBar then self.SideBar.Size=UDim2.fromOffset(130,ny-44) end
            if self.Content then
                self.Content.Size=UDim2.fromOffset(nx-130,ny-44)
                for _,t in ipairs(self.Tabs) do
                    t.Page.Size=UDim2.fromOffset(nx-150,ny-82)
                end
            end
        end
    end))
    self:_C(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then res=false end
    end))

    -- sidebar
    self.SideBar=MkFrame(self.Win, th.NavBar,
        UDim2.fromOffset(130,self.SizeY-44),
        UDim2.fromOffset(0,44),5)
    Stroke(self.SideBar,th.Border,1)

    self.TabList=Instance.new("ScrollingFrame")
    self.TabList.BackgroundTransparency=1; self.TabList.BorderSizePixel=0
    self.TabList.Size=UDim2.fromScale(1,1); self.TabList.CanvasSize=UDim2.fromScale(0,0)
    self.TabList.ScrollBarThickness=2; self.TabList.ScrollBarImageColor3=th.Accent
    self.TabList.ZIndex=6; self.TabList.Parent=self.SideBar
    Pad(self.TabList,8,6,8,6)
    local tll=List(self.TabList,nil,nil,nil,4)
    tll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabList.CanvasSize=UDim2.fromOffset(0,tll.AbsoluteContentSize.Y+16)
    end)

    -- content
    self.Content=MkFrame(self.Win, th.Primary,
        UDim2.fromOffset(self.SizeX-130,self.SizeY-44),
        UDim2.fromOffset(130,44),3,true)

    self.PageTitle=MkLabel(self.Content,"",th.Text,
        UDim2.fromOffset(self.SizeX-165,28),
        UDim2.fromOffset(12,4), th.FontTitle, 13,
        Enum.TextXAlignment.Left,4)

    local sepLine=MkFrame(self.Content,th.Border,UDim2.new(1,-24,0,1),UDim2.fromOffset(12,31),4)
    self._sepLine=sepLine
end

-- ════════════════════════════════════════════════════════════
-- TAB SYSTEM
-- ════════════════════════════════════════════════════════════
function Oxygen:AddTab(cfg)
    cfg=cfg or {}
    local title=cfg.Title or "Tab"; local icon=cfg.Icon or "•"
    local th=self.Theme; local idx=#self.Tabs+1

    local btn=Instance.new("TextButton")
    btn.BackgroundColor3=idx==1 and th.Tertiary or th.NavBar
    btn.BorderSizePixel=0; btn.Size=UDim2.new(1,0,0,34)
    btn.Text=""; btn.ZIndex=7; btn.LayoutOrder=idx; btn.Parent=self.TabList
    Corner(btn,6)

    local ind=MkFrame(btn, th.Accent, UDim2.fromOffset(3,idx==1 and 22 or 0),
        UDim2.new(0,-1,0.5,-(idx==1 and 11 or 0)),9); Corner(ind,2)

    local iconL=MkLabel(btn, icon, idx==1 and th.Accent or th.TextMuted,
        UDim2.fromOffset(22,34), UDim2.fromOffset(8,0),
        Enum.Font.GothamBold,14,Enum.TextXAlignment.Center,8)

    local tabL=MkLabel(btn, title, idx==1 and th.Text or th.TextMuted,
        UDim2.new(1,-38,1,0), UDim2.fromOffset(32,0),
        th.Font,13,Enum.TextXAlignment.Left,8)

    local page=Instance.new("ScrollingFrame")
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.Size=UDim2.fromOffset(self.SizeX-150,self.SizeY-82)
    page.Position=UDim2.fromOffset(10,36)
    page.CanvasSize=UDim2.fromScale(0,0); page.ScrollBarThickness=3
    page.ScrollBarImageColor3=th.Accent; page.Visible=(idx==1)
    page.ZIndex=4; page.Parent=self.Content
    Pad(page,6,6,12,4)
    local pl=List(page,nil,nil,nil,6)
    pl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.fromOffset(0,pl.AbsoluteContentSize.Y+24)
    end)

    btn.MouseEnter:Connect(function()
        if self.ActiveTab~=idx then Util.FT(btn,{BackgroundColor3=th.Tertiary}) end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab~=idx then Util.FT(btn,{BackgroundColor3=th.NavBar}) end
    end)
    btn.MouseButton1Click:Connect(function() self:_Switch(idx) end)

    table.insert(self.Tabs,{Title=title,Btn=btn,Page=page,Icon=iconL,Label=tabL,Ind=ind})
    if idx==1 then self.ActiveTab=1; self.PageTitle.Text=title end
    return self:_API(idx, page, th)
end

function Oxygen:_Switch(idx)
    local th=self.Theme; self.ActiveTab=idx
    for i,t in ipairs(self.Tabs) do
        local a=(i==idx); t.Page.Visible=a
        Util.FT(t.Btn,  {BackgroundColor3=a and th.Tertiary or th.NavBar})
        Util.FT(t.Icon, {TextColor3=a and th.Accent or th.TextMuted})
        Util.FT(t.Label,{TextColor3=a and th.Text   or th.TextMuted})
        Util.FT(t.Ind,  {Size=UDim2.fromOffset(3,a and 22 or 0),
                          Position=UDim2.new(0,-1,0.5,a and -11 or 0)})
    end
    self.PageTitle.Text=self.Tabs[idx].Title
end

-- ════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════════════
function Oxygen:_BuildSettings()
    local s=self:AddTab({Title="Settings",Icon="⚙"})
    s.Section({Title="Appearance"})
    local names={}
    for n in pairs(Themes) do table.insert(names,n) end
    table.sort(names)
    s.Dropdown({Title="Theme",Description="Switches instantly",Options=names,Default=self.ThemeName,
        Callback=function(v) self:SetTheme(v) end})
    s.Section({Title="Keybinds"})
    s.Keybind({Title="Toggle UI",Description="Show / hide window",Default=self.ToggleKey,
        Callback=function(k) self.ToggleKey=k end})
    s.Keybind({Title="Minimize",Description="Collapse to title bar",Default=self.MinKey,
        Callback=function(k) self.MinKey=k end})
    s.Section({Title="Window"})
    s.Toggle({Title="Watermark",Default=self.ShowWM,
        Callback=function(v) self.ShowWM=v; if self._wmF then self._wmF.Visible=v end end})
    s.Section({Title="Config"})
    s.Button({Title="Reset Config",Description="Wipe all saved settings",Callback=function()
        if self.DoSave then self.Cfg:Reset()
            self:Notify({Title="Config Reset",Description="All settings cleared.",Type="warning"}) end
    end})
    s.Button({Title="Export to Clipboard",Description="Copies config JSON",Callback=function()
        if self.DoSave then pcall(function() setclipboard(self.Cfg:Export()) end)
            self:Notify({Title="Exported",Description="Config copied to clipboard.",Type="success"}) end
    end})
    s.Button({Title="Import from Clipboard",Description="Pastes and applies a config",Callback=function()
        if self.DoSave then
            local ok=self.Cfg:ImportFromClipboard()
            self:Notify(ok
                and {Title="Imported",Description="Config applied.",Type="success"}
                or  {Title="Failed",Description="Clipboard has no valid config.",Type="error"})
        end
    end})
    s.Section({Title="About"})
    s.Label({Title="Oxygen UI  •  "..Oxygen.Version})
    s.Label({Title="github.com/oxygen015/roblox-modules"})

    -- move to end
    local sd=table.remove(self.Tabs,1)
    table.insert(self.Tabs,sd)
    for i,t in ipairs(self.Tabs) do t.Btn.LayoutOrder=i end
    self.ActiveTab=1
    for i,t in ipairs(self.Tabs) do t.Page.Visible=(i==1) end
    if self.Tabs[1] then self.PageTitle.Text=self.Tabs[1].Title end
end

-- ════════════════════════════════════════════════════════════
-- KEYS / WATERMARK / PUBLIC
-- ════════════════════════════════════════════════════════════
function Oxygen:_Keys()
    self:_C(UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==self.ToggleKey  then self:Toggle() end
        if i.KeyCode==self.MinKey     then self:ToggleMinimize() end
    end))
end

function Oxygen:_Watermark()
    if not self.ShowWM then return end
    local th=self.Theme
    local wm=MkFrame(self.SG,th.Secondary,UDim2.fromOffset(200,24),UDim2.new(0,10,1,-34),200)
    Corner(wm,6); Stroke(wm,th.Border,1)
    local wl=MkLabel(wm,"⚡ Oxygen  •  "..self.Title,th.TextMuted,
        UDim2.fromScale(1,1),nil,Enum.Font.Gotham,11,Enum.TextXAlignment.Center,201)
    wm.Visible=self.ShowWM
    self._wmF=wm; self._wmL=wl
end

function Oxygen:Toggle()
    self.Visible=not self.Visible
    Util.FT(self.Win,{Size=self.Visible and UDim2.fromOffset(self.SizeX,self.Minimized and 44 or self.SizeY) or UDim2.fromOffset(0,0)})
end
function Oxygen:ToggleMinimize()
    self.Minimized=not self.Minimized
    Util.FT(self.Win,{Size=self.Minimized and UDim2.fromOffset(self.SizeX,44) or UDim2.fromOffset(self.SizeX,self.SizeY)})
end
function Oxygen:Notify(cfg) return self.NotifsObj:Push(cfg,self.Theme) end
function Oxygen:SetWatermarkText(t) if self._wmL then self._wmL.Text=t end end

function Oxygen:SetTheme(name)
    local nt=Themes[name]
    if not nt then warn("[Oxygen] unknown theme: "..tostring(name)); return end
    self.Theme=nt; self.ThemeName=name
    local function TC(o,prop,col) Util.MT(o,{[prop]=col}) end
    TC(self.Win,"BackgroundColor3",nt.Primary)
    TC(self.TBar,"BackgroundColor3",nt.TitleBar)
    TC(self.SideBar,"BackgroundColor3",nt.NavBar)
    TC(self.Content,"BackgroundColor3",nt.Primary)
    TC(self._tLbl,"TextColor3",nt.Text)
    TC(self._sLbl,"TextColor3",nt.TextMuted)
    TC(self._stripe,"BackgroundColor3",nt.Accent)
    TC(self._pip,"BackgroundColor3",nt.Accent)
    TC(self.PageTitle,"TextColor3",nt.Text)
    TC(self._sepLine,"BackgroundColor3",nt.Border)
    if self.DoSave then self.Cfg:Set("theme",name) end
end

function Oxygen:GetThemeNames()
    local t={}; for k in pairs(Themes) do table.insert(t,k) end; table.sort(t); return t
end
function Oxygen:AddTheme(name,data) Themes[name]=data end

function Oxygen:Destroy()
    Util.MT(self.Win,{Size=UDim2.fromOffset(0,0)})
    task.delay(0.35,function()
        for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
        if self.SG and self.SG.Parent then self.SG:Destroy() end
    end)
end

-- ════════════════════════════════════════════════════════════
-- COMPONENT API
-- ════════════════════════════════════════════════════════════
function Oxygen:_API(tabIdx, page, theme)
    local api={}
    local win=self   -- window reference

    local function Card(h,clips)
        local c=MkFrame(page,theme.Secondary,UDim2.new(1,0,0,h or 38))
        c.ClipsDescendants=clips or false; c.ZIndex=7
        Corner(c,math.max(theme.Radius-2,3)); Stroke(c,theme.Border,1)
        return c
    end

    -- ── SECTION ──────────────────────────────────────────
    function api.Section(cfg)
        local f=MkFrame(page,Color3.new(0,0,0),UDim2.new(1,0,0,20))
        f.BackgroundTransparency=1; f.ZIndex=7
        local bar=MkFrame(f,theme.Accent,UDim2.fromOffset(3,13),UDim2.fromOffset(0,3),8); Corner(bar,2)
        MkLabel(f,(cfg.Title or ""):upper(),theme.TextMuted,UDim2.new(1,-12,1,0),UDim2.fromOffset(10,0),Enum.Font.GothamBold,10,Enum.TextXAlignment.Left,8)
        return f
    end

    -- ── SEPARATOR ────────────────────────────────────────
    function api.Separator(cfg)
        local text=cfg and cfg.Text or ""
        local f=MkFrame(page,Color3.new(0,0,0),UDim2.new(1,0,0,14))
        f.BackgroundTransparency=1; f.ZIndex=7
        MkFrame(f,theme.Border,UDim2.new(1,0,0,1),UDim2.fromOffset(0,6),8)
        if text~="" then
            local tw=TextService:GetTextSize(text,10,Enum.Font.Gotham,Vector2.new(9999,9999)).X
            local bg=MkFrame(f,theme.Primary,UDim2.fromOffset(tw+12,14),UDim2.new(0.5,-(tw/2+6),0,0),9)
            MkLabel(bg,text,theme.TextMuted,UDim2.fromScale(1,1),nil,Enum.Font.Gotham,10,Enum.TextXAlignment.Center,10)
        end
        return f
    end

    -- ── DIVIDER ──────────────────────────────────────────
    function api.Divider()
        local f=MkFrame(page,theme.Border,UDim2.new(1,0,0,1)); f.ZIndex=7; return f
    end

    -- ── LABEL ────────────────────────────────────────────
    function api.Label(cfg)
        local card=Card(28)
        local l=MkLabel(card,cfg.Title or "",theme.TextMuted,UDim2.new(1,-16,1,0),UDim2.fromOffset(10,0),Enum.Font.Gotham,12,Enum.TextXAlignment.Left,8)
        l.TextWrapped=true
        local o={}
        function o:Set(t) l.Text=t end; function o:Get() return l.Text end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── PARAGRAPH ────────────────────────────────────────
    function api.Paragraph(cfg)
        local card=Card(58)
        local tl=MkLabel(card,cfg.Title or "",theme.Text,UDim2.new(1,-16,0,16),UDim2.fromOffset(10,5),theme.FontTitle,13,Enum.TextXAlignment.Left,8)
        local body=cfg.Content or ""
        local bl=MkLabel(card,body,theme.TextMuted,UDim2.new(1,-16,0,36),UDim2.fromOffset(10,22),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8)
        bl.TextWrapped=true
        task.defer(function()
            if not bl.Parent then return end
            local bh=TextService:GetTextSize(body,11,Enum.Font.Gotham,Vector2.new(page.AbsoluteSize.X-30,9999)).Y
            card.Size=UDim2.new(1,0,0,math.max(bh+30,46))
        end)
        local o={}
        function o:SetTitle(t) tl.Text=t end; function o:SetContent(t) bl.Text=t end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── BUTTON ───────────────────────────────────────────
    function api.Button(cfg)
        local title=cfg.Title or "Button"; local desc=cfg.Description or ""
        local cb=cfg.Callback or function() end; local tip=cfg.Tooltip
        local card=Card(desc~=""and 54 or 36, true)
        MkLabel(card,title,theme.Text,UDim2.new(1,-80,0,18),UDim2.fromOffset(12,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8)
        if desc~="" then MkLabel(card,desc,theme.TextMuted,UDim2.new(1,-80,0,14),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8) end
        local rb=Instance.new("ImageButton")
        rb.BackgroundColor3=theme.Accent; rb.BorderSizePixel=0
        rb.Size=UDim2.fromOffset(58,24); rb.Position=UDim2.new(1,-66,0.5,-12)
        rb.AutoButtonColor=false; rb.ZIndex=9; rb.Parent=card; Corner(rb,5)
        MkLabel(rb,"RUN",theme.TextDark,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,11,Enum.TextXAlignment.Center,10)
        rb.MouseButton1Click:Connect(function() Util.Ripple(rb,theme.AccentDark); Util.Call(cb) end)
        rb.MouseEnter:Connect(function() Util.FT(rb,{BackgroundColor3=theme.AccentDark}) end)
        rb.MouseLeave:Connect(function() Util.FT(rb,{BackgroundColor3=theme.Accent}) end)
        if tip then Tooltip(card,tip,theme,win.SG) end
        local o={}
        function o:SetEnabled(v) rb.BackgroundColor3=v and theme.Accent or theme.Tertiary end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ── TOGGLE ───────────────────────────────────────────
    function api.Toggle(cfg)
        local title=cfg.Title or "Toggle"; local desc=cfg.Description or ""
        local def=cfg.Default or false; local cb=cfg.Callback or function() end
        local key=cfg.ConfigKey; local tip=cfg.Tooltip
        if key and win.DoSave then def=win.Cfg:Get(key,def) end
        local state=def
        local card=Card(desc~=""and 54 or 36)
        MkLabel(card,title,theme.Text,UDim2.new(1,-72,0,18),UDim2.fromOffset(12,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8)
        if desc~="" then MkLabel(card,desc,theme.TextMuted,UDim2.new(1,-72,0,14),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8) end
        local track=MkFrame(card,state and theme.Toggle or theme.Tertiary,UDim2.fromOffset(34,16),UDim2.new(1,-42,0.5,-8),9); Corner(track,8)
        local knob=MkFrame(track,theme.Text,UDim2.fromOffset(10,10),state and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3),10); Corner(knob,5)
        local function upd(v)
            state=v
            Util.FT(track,{BackgroundColor3=v and theme.Toggle or theme.Tertiary})
            Util.FT(knob,{Position=v and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3)})
            Util.Call(cb,v)
            if key and win.DoSave then win.Cfg:Set(key,v) end
        end
        task.defer(function() Util.Call(cb,state) end)
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=11; hit.Parent=card
        hit.MouseButton1Click:Connect(function() upd(not state) end)
        if tip then Tooltip(card,tip,theme,win.SG) end
        local o={}
        function o:Set(v) upd(v) end; function o:Get() return state end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── SLIDER ───────────────────────────────────────────
    function api.Slider(cfg)
        local title=cfg.Title or "Slider"; local desc=cfg.Description or ""
        local mn=cfg.Min or 0; local mx=cfg.Max or 100
        local def=cfg.Default or mn; local prec=cfg.Precision or 0
        local suf=cfg.Suffix or ""; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then def=win.Cfg:Get(key,def) end
        def=math.clamp(def,mn,mx); local value=def
        local card=Card(desc~=""and 66 or 52)
        MkLabel(card,title,theme.Text,UDim2.new(1,-84,0,18),UDim2.fromOffset(12,8),theme.Font,14,Enum.TextXAlignment.Left,8)
        local vl=MkLabel(card,tostring(def)..suf,theme.Accent,UDim2.fromOffset(72,18),UDim2.new(1,-80,0,8),Enum.Font.GothamBold,13,Enum.TextXAlignment.Right,8)
        if desc~="" then MkLabel(card,desc,theme.TextMuted,UDim2.new(1,-20,0,13),UDim2.fromOffset(12,26),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8) end
        local ty=desc~=""and 48 or 34
        local track=MkFrame(card,theme.Tertiary,UDim2.new(1,-24,0,4),UDim2.fromOffset(12,ty),8); Corner(track,2)
        local ds=(def-mn)/math.max(mx-mn,0.001)
        local fill=MkFrame(track,theme.Slider,UDim2.fromScale(ds,1),nil,9); Corner(fill,2)
        local knob=MkFrame(track,theme.Text,UDim2.fromOffset(14,14),UDim2.new(ds,-7,0.5,-7),10); Corner(knob,7); Stroke(knob,theme.Slider,2)
        local drag=false
        local function upd(scale)
            scale=math.clamp(scale,0,1)
            local m=10^prec; local v=math.floor((mn+(mx-mn)*scale)*m+0.5)/m
            value=v; Util.FT(fill,{Size=UDim2.fromScale(scale,1)}); Util.FT(knob,{Position=UDim2.new(scale,-7,0.5,-7)})
            vl.Text=tostring(v)..suf; Util.Call(cb,v)
            if key and win.DoSave then win.Cfg:Set(key,v) end
        end
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=12; hit.Parent=track
        hit.MouseButton1Down:Connect(function() drag=true; upd(Util.GetXY(track)) end)
        win:_C(UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(Util.GetXY(track)) end
        end))
        win:_C(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
        end))
        task.defer(function() Util.Call(cb,value) end)
        local o={}
        function o:Set(v) v=math.clamp(v,mn,mx); upd((v-mn)/math.max(mx-mn,0.001)) end
        function o:Get() return value end; function o:SetMin(v) mn=v end; function o:SetMax(v) mx=v end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ── DROPDOWN ─────────────────────────────────────────
    function api.Dropdown(cfg)
        local title=cfg.Title or "Dropdown"; local desc=cfg.Description or ""
        local opts=cfg.Options or {}; local def=cfg.Default; local multi=cfg.Multi or false
        local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then def=win.Cfg:Get(key,def) end
        local sel=multi and {} or def; local open=false
        local bh=desc~=""and 54 or 40; local card=Card(bh); card.ZIndex=22
        MkLabel(card,title,theme.Text,UDim2.new(1,-20,0,18),UDim2.fromOffset(12,desc~=""and 8 or 11),theme.Font,14,Enum.TextXAlignment.Left,23)
        if desc~="" then MkLabel(card,desc,theme.TextMuted,UDim2.new(1,-20,0,13),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,23) end
        local curL=MkLabel(card,def and tostring(def) or "Select...",theme.Accent,UDim2.new(1,-30,0,16),UDim2.new(0,12,1,desc~=""and -24 or -26),Enum.Font.Gotham,12,Enum.TextXAlignment.Left,23)
        local arrow=MkLabel(card,"▾",theme.TextMuted,UDim2.fromOffset(18,18),UDim2.new(1,-24,0.5,-9),Enum.Font.GothamBold,13,Enum.TextXAlignment.Center,23)
        local maxPH=math.min(#opts*28+36,190)
        local panel=MkFrame(card,theme.Secondary,UDim2.new(1,0,0,0),UDim2.new(0,0,1,4),50,true); Corner(panel,6); Stroke(panel,theme.Border,1); Shadow(panel,theme.Shadow,50)
        local sb=Instance.new("TextBox"); sb.BackgroundColor3=theme.Tertiary; sb.BorderSizePixel=0
        sb.Size=UDim2.new(1,-8,0,24); sb.Position=UDim2.fromOffset(4,4)
        sb.PlaceholderText="Search..."; sb.PlaceholderColor3=theme.TextMuted; sb.Text=""
        sb.TextColor3=theme.Text; sb.Font=Enum.Font.Gotham; sb.TextSize=12; sb.ClearTextOnFocus=false; sb.ZIndex=51; sb.Parent=panel; Corner(sb,4); Pad(sb,0,6,0,6)
        local sc=Instance.new("ScrollingFrame"); sc.BackgroundTransparency=1; sc.BorderSizePixel=0
        sc.Size=UDim2.new(1,0,1,-32); sc.Position=UDim2.fromOffset(0,30); sc.CanvasSize=UDim2.fromScale(0,0)
        sc.ScrollBarThickness=2; sc.ScrollBarImageColor3=theme.Accent; sc.ZIndex=51; sc.Parent=panel
        Pad(sc,2,4,2,4); local sl=List(sc,nil,nil,nil,2)
        sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sc.CanvasSize=UDim2.fromOffset(0,sl.AbsoluteContentSize.Y+4) end)
        local obs={}
        local function rebuild(filter)
            for _,b in ipairs(obs) do b:Destroy() end; obs={}
            for _,opt in ipairs(opts) do
                local os=tostring(opt)
                if filter=="" or os:lower():find(filter:lower(),1,true) then
                    local isSel=multi and Util.Has(sel,opt) or (sel==opt)
                    local ob=Instance.new("TextButton"); ob.BackgroundColor3=isSel and theme.Accent or theme.Tertiary
                    ob.BorderSizePixel=0; ob.Size=UDim2.new(1,0,0,24); ob.Text=""; ob.ZIndex=52; ob.Parent=sc; Corner(ob,4)
                    local ol=MkLabel(ob,os,isSel and theme.TextDark or theme.Text,UDim2.new(1,-8,1,0),UDim2.fromOffset(6,0),Enum.Font.Gotham,12,Enum.TextXAlignment.Left,53)
                    ob.MouseButton1Click:Connect(function()
                        if multi then
                            if Util.Has(sel,opt) then for i,v in ipairs(sel) do if v==opt then table.remove(sel,i); break end end
                            else table.insert(sel,opt) end
                            curL.Text=#sel>0 and table.concat(sel,", ") or "Select..."; Util.Call(cb,sel)
                        else
                            sel=opt; curL.Text=os; Util.Call(cb,opt)
                            open=false; Util.FT(panel,{Size=UDim2.new(1,0,0,0)}); Util.FT(arrow,{Rotation=0})
                        end
                        if key and win.DoSave then win.Cfg:Set(key,sel) end; rebuild(sb.Text)
                    end)
                    ob.MouseEnter:Connect(function() if not(not multi and sel==opt) then Util.FT(ob,{BackgroundColor3=theme.Accent}); Util.FT(ol,{TextColor3=theme.TextDark}) end end)
                    ob.MouseLeave:Connect(function() local is2=multi and Util.Has(sel,opt) or (sel==opt); Util.FT(ob,{BackgroundColor3=is2 and theme.Accent or theme.Tertiary}); Util.FT(ol,{TextColor3=is2 and theme.TextDark or theme.Text}) end)
                    table.insert(obs,ob)
                end
            end
        end
        rebuild("")
        sb:GetPropertyChangedSignal("Text"):Connect(function() rebuild(sb.Text) end)
        task.defer(function()
            local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.new(1,0,0,bh); hit.Text=""; hit.ZIndex=24; hit.Parent=card
            hit.MouseButton1Click:Connect(function()
                open=not open; Util.FT(panel,{Size=UDim2.new(1,0,0,open and maxPH or 0)}); Util.FT(arrow,{Rotation=open and 180 or 0})
                if open then sb:CaptureFocus() end
            end)
        end)
        local o={}
        function o:Set(v) sel=v; curL.Text=tostring(v) end; function o:Get() return sel end
        function o:SetOptions(opts2) opts=opts2; rebuild(sb.Text) end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── KEYBIND ──────────────────────────────────────────
    function api.Keybind(cfg)
        local title=cfg.Title or "Keybind"; local desc=cfg.Description or ""
        local def=cfg.Default or Enum.KeyCode.Unknown; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        local bound=def; local listening=false
        local card=Card(desc~=""and 54 or 36)
        MkLabel(card,title,theme.Text,UDim2.new(1,-102,0,18),UDim2.fromOffset(12,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8)
        if desc~="" then MkLabel(card,desc,theme.TextMuted,UDim2.new(1,-102,0,13),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8) end
        local kb=Instance.new("TextButton"); kb.BackgroundColor3=theme.Tertiary; kb.BorderSizePixel=0
        kb.Size=UDim2.fromOffset(88,22); kb.Position=UDim2.new(1,-96,0.5,-11)
        kb.Text=bound.Name; kb.TextColor3=theme.Accent; kb.Font=Enum.Font.GothamBold; kb.TextSize=11; kb.ZIndex=9; kb.Parent=card; Corner(kb,5); Stroke(kb,theme.Border,1)
        kb.MouseButton1Click:Connect(function() listening=true; kb.Text="..."; kb.TextColor3=theme.Warning end)
        win:_C(UserInputService.InputBegan:Connect(function(i,gp)
            if not listening then return end
            if i.UserInputType==Enum.UserInputType.Keyboard then
                bound=i.KeyCode; kb.Text=bound.Name; kb.TextColor3=theme.Accent; listening=false
                Util.Call(cb,bound); if key and win.DoSave then win.Cfg:Set(key,bound.Name) end
            end
        end))
        local o={}
        function o:Get() return bound end; function o:Set(kc) bound=kc; kb.Text=kc.Name end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── TEXT INPUT ───────────────────────────────────────
    function api.TextInput(cfg)
        local title=cfg.Title or "Input"; local desc=cfg.Description or ""
        local ph=cfg.Placeholder or "Enter text..."; local def=cfg.Default or ""
        local cb=cfg.Callback or function() end; local num=cfg.Numeric or false
        local maxL=cfg.MaxLength or 200; local key=cfg.ConfigKey
        if key and win.DoSave then def=win.Cfg:Get(key,def) end
        local card=Card(desc~=""and 70 or 56)
        MkLabel(card,title,theme.Text,UDim2.new(1,-16,0,15),UDim2.fromOffset(12,5),theme.Font,13,Enum.TextXAlignment.Left,8)
        if desc~="" then MkLabel(card,desc,theme.TextMuted,UDim2.new(1,-16,0,12),UDim2.fromOffset(12,20),Enum.Font.Gotham,10,Enum.TextXAlignment.Left,8) end
        local iy=desc~=""and 36 or 24
        local iF=MkFrame(card,theme.Tertiary,UDim2.new(1,-16,0,24),UDim2.fromOffset(8,iy),8); Corner(iF,5)
        local iS=Stroke(iF,theme.Border,1)
        local box=Instance.new("TextBox"); box.BackgroundTransparency=1; box.Size=UDim2.new(1,-8,1,0); box.Position=UDim2.fromOffset(6,0)
        box.Text=def; box.PlaceholderText=ph; box.PlaceholderColor3=theme.TextMuted; box.TextColor3=theme.Text
        box.Font=Enum.Font.Gotham; box.TextSize=12; box.ClearTextOnFocus=false; box.ZIndex=9; box.Parent=iF
        local counter=MkLabel(iF,"0/"..maxL,theme.TextMuted,UDim2.fromOffset(42,18),UDim2.new(1,-48,0,3),Enum.Font.Gotham,9,Enum.TextXAlignment.Right,9)
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if num then box.Text=box.Text:gsub("[^%d%.%-]","") end
            if #box.Text>maxL then box.Text=box.Text:sub(1,maxL) end
            counter.Text=#box.Text.."/"..maxL
        end)
        box.Focused:Connect(function() Util.FT(iF,{BackgroundColor3=Util.Lerp(theme.Tertiary,theme.Accent,0.12)}); iS.Color=theme.Accent end)
        box.FocusLost:Connect(function(enter)
            Util.FT(iF,{BackgroundColor3=theme.Tertiary}); iS.Color=theme.Border
            if enter then Util.Call(cb,box.Text); if key and win.DoSave then win.Cfg:Set(key,box.Text) end end
        end)
        local o={}
        function o:Get() return box.Text end; function o:Set(t) box.Text=t end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── COLOR PICKER ─────────────────────────────────────
    function api.ColorPicker(cfg)
        local title=cfg.Title or "Color"; local def=cfg.Default or Color3.fromRGB(120,80,255)
        local cb=cfg.Callback or function() end
        local h,s,v=Color3.toHSV(def); local open=false
        local card=Card(36); card.ClipsDescendants=false
        MkLabel(card,title,theme.Text,UDim2.new(1,-62,1,0),UDim2.fromOffset(12,0),theme.Font,14,Enum.TextXAlignment.Left,8)
        local prev=MkFrame(card,def,UDim2.fromOffset(48,20),UDim2.new(1,-56,0.5,-10),9); Corner(prev,4); Stroke(prev,theme.Border,1)
        local hexL=MkLabel(prev,Util.Hex(def),Util.Contrast(def),UDim2.fromScale(1,1),nil,Enum.Font.Code,9,Enum.TextXAlignment.Center,10)
        local pp=MkFrame(card,theme.Secondary,UDim2.new(1,0,0,0),UDim2.new(0,0,1,4),30,true); Corner(pp,6); Stroke(pp,theme.Border,1)
        local function updC() local col=Color3.fromHSV(h,s,v); prev.BackgroundColor3=col; hexL.TextColor3=Util.Contrast(col); hexL.Text=Util.Hex(col); Util.Call(cb,col) end
        local svSq=Instance.new("ImageLabel"); svSq.BackgroundColor3=Color3.fromHSV(h,1,1); svSq.BorderSizePixel=0; svSq.Size=UDim2.new(1,-16,0,100); svSq.Position=UDim2.fromOffset(8,8); svSq.Image="rbxassetid://4155801252"; svSq.ZIndex=31; svSq.Parent=pp; Corner(svSq,4)
        local hBar=Instance.new("ImageLabel"); hBar.BackgroundColor3=Color3.new(1,0,0); hBar.BorderSizePixel=0; hBar.Size=UDim2.new(1,-16,0,12); hBar.Position=UDim2.fromOffset(8,116); hBar.Image="rbxassetid://698052001"; hBar.ZIndex=31; hBar.Parent=pp; Corner(hBar,3)
        local hBox=Instance.new("TextBox"); hBox.BackgroundColor3=theme.Tertiary; hBox.BorderSizePixel=0; hBox.Size=UDim2.new(1,-16,0,22); hBox.Position=UDim2.fromOffset(8,136); hBox.Text=Util.Hex(def); hBox.PlaceholderText="#FFFFFF"; hBox.PlaceholderColor3=theme.TextMuted; hBox.TextColor3=theme.Text; hBox.Font=Enum.Font.Code; hBox.TextSize=12; hBox.ClearTextOnFocus=false; hBox.ZIndex=31; hBox.Parent=pp; Corner(hBox,4)
        local svK=MkFrame(svSq,Color3.new(1,1,1),UDim2.fromOffset(10,10),nil,32); Corner(svK,5); Stroke(svK,Color3.new(1,1,1),1)
        local hK=MkFrame(hBar,Color3.new(1,1,1),UDim2.fromOffset(4,14),nil,32); Corner(hK,2)
        local function refK() svK.Position=UDim2.new(s,-5,1-v,-5); hK.Position=UDim2.new(1-h,-2,0,-1); svSq.BackgroundColor3=Color3.fromHSV(h,1,1) end
        refK()
        -- SV drag
        local svD=false
        local svH=Instance.new("TextButton"); svH.BackgroundTransparency=1; svH.Size=UDim2.fromScale(1,1); svH.Text=""; svH.ZIndex=33; svH.Parent=svSq
        svH.MouseButton1Down:Connect(function() svD=true; local px,py=Util.GetXY(svSq); s,v=math.clamp(px,0,1),math.clamp(1-py,0,1); refK(); updC() end)
        win:_C(UserInputService.InputChanged:Connect(function(i)
            if svD and i.UserInputType==Enum.UserInputType.MouseMovement then local px,py=Util.GetXY(svSq); s,v=math.clamp(px,0,1),math.clamp(1-py,0,1); refK(); updC() end
        end))
        win:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svD=false end end))
        -- hue drag
        local hD=false
        local hH=Instance.new("TextButton"); hH.BackgroundTransparency=1; hH.Size=UDim2.fromScale(1,1); hH.Text=""; hH.ZIndex=33; hH.Parent=hBar
        hH.MouseButton1Down:Connect(function() hD=true; local px,_=Util.GetXY(hBar); h=math.clamp(1-px,0,1); refK(); updC() end)
        win:_C(UserInputService.InputChanged:Connect(function(i)
            if hD and i.UserInputType==Enum.UserInputType.MouseMovement then local px,_=Util.GetXY(hBar); h=math.clamp(1-px,0,1); refK(); updC() end
        end))
        win:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hD=false end end))
        hBox.FocusLost:Connect(function() local ok,col=pcall(Util.FromHex,hBox.Text); if ok then h,s,v=Color3.toHSV(col); refK(); updC() end end)
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=10; hit.Parent=card
        hit.MouseButton1Click:Connect(function() open=not open; Util.FT(pp,{Size=UDim2.new(1,0,0,open and 166 or 0)}) end)
        local o={}
        function o:Get() return Color3.fromHSV(h,s,v) end
        function o:Set(col) h,s,v=Color3.toHSV(col); refK(); updC() end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ── PROGRESS BAR ─────────────────────────────────────
    function api.ProgressBar(cfg)
        local title=cfg.Title or "Progress"; local init=cfg.Value or 0; local mx=cfg.Max or 100; local suf=cfg.Suffix or "%"
        local card=Card(46)
        MkLabel(card,title,theme.Text,UDim2.new(1,-70,0,16),UDim2.fromOffset(12,6),theme.Font,13,Enum.TextXAlignment.Left,8)
        local vl=MkLabel(card,tostring(init)..suf,theme.Accent,UDim2.fromOffset(60,16),UDim2.new(1,-68,0,6),Enum.Font.GothamBold,12,Enum.TextXAlignment.Right,8)
        local track=MkFrame(card,theme.Tertiary,UDim2.new(1,-16,0,6),UDim2.fromOffset(8,30),8); Corner(track,3)
        local fill=MkFrame(track,theme.Accent,UDim2.fromScale(math.clamp(init/math.max(mx,0.001),0,1),1),nil,9); Corner(fill,3)
        local shim=MkFrame(fill,Color3.new(1,1,1),UDim2.fromOffset(26,6),nil,10); shim.BackgroundTransparency=0.72
        task.spawn(function() while fill and fill.Parent do shim.Position=UDim2.fromScale(-0.3,0); Util.Tween(shim,TweenInfo.new(1.3,Enum.EasingStyle.Sine),{Position=UDim2.fromScale(1.3,0)}); task.wait(2.2) end end)
        local o={}
        function o:Set(val) local sc=math.clamp(val/math.max(mx,0.001),0,1); Util.MT(fill,{Size=UDim2.fromScale(sc,1)}); vl.Text=tostring(Util.Round(val,1))..suf end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ── STEPPER ──────────────────────────────────────────
    function api.Stepper(cfg)
        local title=cfg.Title or "Stepper"; local mn=cfg.Min or 0; local mx=cfg.Max or 10
        local def=cfg.Default or mn; local step=cfg.Step or 1; local cb=cfg.Callback or function() end
        local value=math.clamp(def,mn,mx); local card=Card(36)
        MkLabel(card,title,theme.Text,UDim2.new(1,-115,1,0),UDim2.fromOffset(12,0),theme.Font,14,Enum.TextXAlignment.Left,8)
        local function mkB(sym,xo)
            local b=Instance.new("TextButton"); b.BackgroundColor3=theme.Tertiary; b.BorderSizePixel=0
            b.Size=UDim2.fromOffset(26,22); b.Position=UDim2.new(1,xo,0.5,-11)
            b.Text=sym; b.TextColor3=theme.Accent; b.Font=Enum.Font.GothamBold; b.TextSize=16; b.ZIndex=9; b.Parent=card; Corner(b,5)
            b.MouseEnter:Connect(function() Util.FT(b,{BackgroundColor3=theme.Accent}); b.TextColor3=theme.TextDark end)
            b.MouseLeave:Connect(function() Util.FT(b,{BackgroundColor3=theme.Tertiary}); b.TextColor3=theme.Accent end)
            return b
        end
        local minus=mkB("−",-106)
        local vl=MkLabel(card,tostring(value),theme.Text,UDim2.fromOffset(46,22),UDim2.new(1,-78,0.5,-11),Enum.Font.GothamBold,14,Enum.TextXAlignment.Center,9)
        local plus=mkB("+", -30)
        local function upd(v) value=math.clamp(v,mn,mx); vl.Text=tostring(value); Util.Call(cb,value) end
        minus.MouseButton1Click:Connect(function() upd(value-step) end)
        plus.MouseButton1Click:Connect(function()  upd(value+step) end)
        local o={}
        function o:Get() return value end; function o:Set(v) upd(v) end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ── RADIO GROUP ──────────────────────────────────────
    function api.RadioGroup(cfg)
        local title=cfg.Title or "Pick one"; local opts=cfg.Options or {}; local def=cfg.Default or opts[1]; local cb=cfg.Callback or function() end
        local sel=def; local h=28+#opts*30; local card=Card(h)
        MkLabel(card,title,theme.TextMuted,UDim2.new(1,-16,0,20),UDim2.fromOffset(12,4),Enum.Font.GothamBold,10,Enum.TextXAlignment.Left,8)
        local rbs={}
        for i,opt in ipairs(opts) do
            local row=Instance.new("TextButton"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,-16,0,26); row.Position=UDim2.fromOffset(8,20+(i-1)*28); row.Text=""; row.ZIndex=9; row.Parent=card
            local ring=MkFrame(row,Color3.new(0,0,0),UDim2.fromOffset(16,16),UDim2.fromOffset(4,5),10); ring.BackgroundTransparency=1; Corner(ring,8); Stroke(ring,opt==def and theme.Accent or theme.Border,2)
            local dot=MkFrame(ring,theme.Accent,UDim2.fromOffset(opt==def and 8 or 0,opt==def and 8 or 0),UDim2.fromOffset(opt==def and 4 or 8,opt==def and 4 or 8),11); Corner(dot,4)
            local lbl=MkLabel(row,tostring(opt),opt==def and theme.Text or theme.TextMuted,UDim2.new(1,-26,1,0),UDim2.fromOffset(24,0),Enum.Font.Gotham,13,Enum.TextXAlignment.Left,10)
            table.insert(rbs,{ring=ring,dot=dot,lbl=lbl,opt=opt})
            row.MouseButton1Click:Connect(function()
                sel=opt
                for _,rb in ipairs(rbs) do
                    local a=rb.opt==opt
                    pcall(function() rb.ring:FindFirstChildWhichIsA("UIStroke"):Destroy() end); Stroke(rb.ring,a and theme.Accent or theme.Border,2)
                    Util.FT(rb.dot,{Size=a and UDim2.fromOffset(8,8) or UDim2.fromOffset(0,0), Position=a and UDim2.fromOffset(4,4) or UDim2.fromOffset(8,8)})
                    Util.FT(rb.lbl,{TextColor3=a and theme.Text or theme.TextMuted})
                end
                Util.Call(cb,opt)
            end)
        end
        local o={}; function o:Get() return sel end; function o:Destroy() card:Destroy() end; return o
    end

    -- ── BADGE ────────────────────────────────────────────
    function api.Badge(cfg)
        local items=cfg.Items or {}; local card=Card(36)
        local cont=MkFrame(card,Color3.new(0,0,0),UDim2.fromScale(1,1)); cont.BackgroundTransparency=1; cont.ZIndex=8
        Pad(cont,6,6,6,8); List(cont,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center,4)
        for _,item in ipairs(items) do
            local col=item.Color or theme.Accent
            local chip=MkFrame(cont,col,UDim2.fromOffset(0,20)); chip.AutomaticSize=Enum.AutomaticSize.X; chip.ZIndex=9; Corner(chip,10); Pad(chip,3,8,3,8)
            local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.AutomaticSize=Enum.AutomaticSize.X; l.Size=UDim2.fromScale(1,1); l.Text=tostring(item.Text or ""); l.TextColor3=item.TextColor or Util.Contrast(col); l.Font=Enum.Font.GothamBold; l.TextSize=11; l.ZIndex=10; l.Parent=chip
        end
        return card
    end

    -- ── IMAGE ────────────────────────────────────────────
    function api.Image(cfg)
        local id=cfg.ID or ""; local height=cfg.Height or 120; local cap=cfg.Caption or ""
        local card=Card(height+(cap~=""and 26 or 8))
        local img=Instance.new("ImageLabel"); img.BackgroundTransparency=1; img.Size=UDim2.new(1,-16,0,height); img.Position=UDim2.fromOffset(8,4); img.Image="rbxassetid://"..id; img.ScaleType=Enum.ScaleType.Fit; img.ZIndex=8; img.Parent=card; Corner(img,4)
        if cap~="" then MkLabel(card,cap,theme.TextMuted,UDim2.new(1,-16,0,18),UDim2.fromOffset(8,height+6),Enum.Font.Gotham,11,Enum.TextXAlignment.Center,8) end
        local o={}; function o:SetImage(i) img.Image="rbxassetid://"..i end; function o:Destroy() card:Destroy() end; return o
    end

    return api
end

return Oxygen
