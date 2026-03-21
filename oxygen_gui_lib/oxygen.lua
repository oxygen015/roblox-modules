--[[
╔══════════════════════════════════════════════════════════════╗
║   ██████╗ ██╗  ██╗██╗   ██╗ ██████╗ ███████╗███╗   ██╗     ║
║  ██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝██╔════╝ ██╔════╝████╗  ██║     ║
║  ██║   ██║ ╚███╔╝  ╚████╔╝ ██║  ███╗█████╗  ██╔██╗ ██║     ║
║  ██║   ██║ ██╔██╗   ╚██╔╝  ██║   ██║██╔══╝  ██║╚██╗██║     ║
║  ╚██████╔╝██╔╝ ██╗   ██║   ╚██████╔╝███████╗██║ ╚████║     ║
║   ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝     ║
║                                                              ║
║   Oxygen UI Library  •  beta 0.0.1                          ║
║   github.com/oxygen015/roblox-modules                       ║
║                                                              ║
║   USAGE:                                                     ║
║   local Oxygen = loadstring(game:HttpGet(RAW_URL))()        ║
║   local UI = Oxygen.new({ Title="MyScript", ... })          ║
║                                                              ║
║   FEATURES:                                                  ║
║   • 16 themes — fully applied to every element              ║
║   • Optional animated splash screen                         ║
║   • Settings tab always pinned to last position             ║
║   • Resizable window (drag bottom-right corner)             ║
║   • Draggable window                                        ║
║   • Notification system (4 types, 4 positions)              ║
║   • Config save / load / export / import                    ║
║   • 15+ components, each with :Destroy()                    ║
║   • Tooltip system                                          ║
║   • Watermark with live text update                         ║
║   • SearchBox component                                     ║
║   • Accordion / collapsible section                         ║
║   • Chip / Tag list component                               ║
║   • Divider, Paragraph, Label, Image                        ║
╚══════════════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ════════════════════════════════════════════════════════════
--  SIGNAL
-- ════════════════════════════════════════════════════════════
local Signal = {}; Signal.__index = Signal
function Signal.new() return setmetatable({_c={}}, Signal) end
function Signal:Connect(fn)
    local c = {_fn=fn, _s=self, Connected=true}
    table.insert(self._c, c)
    function c:Disconnect()
        self.Connected = false
        for i,v in ipairs(self._s._c) do
            if v==self then table.remove(self._s._c,i); break end
        end
    end
    return c
end
function Signal:Fire(...) for _,c in ipairs(self._c) do task.spawn(c._fn,...) end end
function Signal:Once(fn)
    local c; c = self:Connect(function(...) c:Disconnect(); fn(...) end)
    return c
end
function Signal:Destroy() self._c = {} end

-- ════════════════════════════════════════════════════════════
--  TWEEN HELPERS
-- ════════════════════════════════════════════════════════════
local TI = {
    fast   = TweenInfo.new(0.14, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out),
    med    = TweenInfo.new(0.28, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out),
    slow   = TweenInfo.new(0.50, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out),
    spring = TweenInfo.new(0.55, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    bounce = TweenInfo.new(0.60, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    linear = TweenInfo.new(1.00, Enum.EasingStyle.Linear),
}

local function Tween(obj, info, props)
    if not obj or not obj.Parent then return end
    local ok, t = pcall(TweenService.Create, TweenService, obj, info, props)
    if ok and t then t:Play(); return t end
end

local function FT(o,p)  return Tween(o, TI.fast,   p) end
local function MT(o,p)  return Tween(o, TI.med,    p) end
local function ST(o,p)  return Tween(o, TI.slow,   p) end
local function SP(o,p)  return Tween(o, TI.spring, p) end

-- ════════════════════════════════════════════════════════════
--  UTILITY
-- ════════════════════════════════════════════════════════════
local Util = {}

function Util.GetXY(f)
    local ap = f.AbsolutePosition; local as = f.AbsoluteSize
    return math.clamp(Mouse.X-ap.X,0,as.X) / math.max(as.X,1),
           math.clamp(Mouse.Y-ap.Y,0,as.Y) / math.max(as.Y,1)
end

function Util.Ripple(parent, color)
    if not parent or not parent.Parent then return end
    local px, py = Util.GetXY(parent)
    local r = Instance.new("ImageLabel")
    r.BackgroundTransparency = 1
    r.Image = "rbxassetid://5554831670"
    r.ImageColor3 = color or Color3.new(1,1,1)
    r.ImageTransparency = 0.55
    r.ZIndex = parent.ZIndex + 50
    r.Size = UDim2.fromOffset(0,0)
    r.Position = UDim2.fromScale(px, py)
    r.AnchorPoint = Vector2.new(0.5, 0.5)
    r.Parent = parent
    local sz = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.6
    Tween(r, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(sz, sz), ImageTransparency = 1
    })
    task.delay(0.6, function() if r.Parent then r:Destroy() end end)
end

function Util.Lerp(a,b,t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

function Util.Contrast(bg)
    return (0.299*bg.R + 0.587*bg.G + 0.114*bg.B) > 0.5
        and Color3.new(0,0,0) or Color3.new(1,1,1)
end

function Util.Round(n, d) local m=10^(d or 0); return math.floor(n*m+0.5)/m end

function Util.Has(t, v)
    for _,x in ipairs(t) do if x==v then return true end end; return false
end

function Util.DeepCopy(t)
    local c={}
    for k,v in pairs(t) do c[k] = type(v)=="table" and Util.DeepCopy(v) or v end
    return c
end

function Util.Call(fn, ...)
    if type(fn)~="function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Oxygen] callback error: "..tostring(err)) end
end

function Util.Hex(c)
    return string.format("#%02X%02X%02X",
        math.clamp(math.floor(c.R*255+.5),0,255),
        math.clamp(math.floor(c.G*255+.5),0,255),
        math.clamp(math.floor(c.B*255+.5),0,255))
end

function Util.FromHex(h)
    h = h:gsub("#","")
    if #h ~= 6 then return nil end
    local r = tonumber(h:sub(1,2),16)
    local g = tonumber(h:sub(3,4),16)
    local b = tonumber(h:sub(5,6),16)
    if r and g and b then return Color3.fromRGB(r,g,b) end
    return nil
end

function Util.Map(n, a, b, c, d)
    return c + (d-c) * ((n-a) / math.max(b-a, 0.001))
end

-- ════════════════════════════════════════════════════════════
--  GUI FACTORY
-- ════════════════════════════════════════════════════════════
local G = {}

function G.Frame(p, col, sz, pos, zi, clips)
    local f = Instance.new("Frame")
    f.BackgroundColor3  = col   or Color3.new(0.1,0.1,0.1)
    f.BorderSizePixel   = 0
    f.Size              = sz    or UDim2.fromScale(1,1)
    f.Position          = pos   or UDim2.fromScale(0,0)
    f.ZIndex            = zi    or 1
    f.ClipsDescendants  = clips or false
    f.Parent = p; return f
end

function G.Label(p, txt, col, sz, pos, font, ts, xa, zi)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text           = txt  or ""
    l.TextColor3     = col  or Color3.new(1,1,1)
    l.Size           = sz   or UDim2.fromScale(1,1)
    l.Position       = pos  or UDim2.fromScale(0,0)
    l.Font           = font or Enum.Font.Gotham
    l.TextSize       = ts   or 14
    l.TextXAlignment = xa   or Enum.TextXAlignment.Left
    l.ZIndex         = zi   or 2
    l.TextTruncate   = Enum.TextTruncate.AtEnd
    l.Parent = p; return l
end

function G.ImageBtn(p, col, sz, pos, zi)
    local b = Instance.new("ImageButton")
    b.BackgroundColor3  = col or Color3.new(0.2,0.2,0.2)
    b.BorderSizePixel   = 0
    b.Image             = "rbxassetid://5554237731"
    b.ScaleType         = Enum.ScaleType.Slice
    b.SliceCenter       = Rect.new(3,3,297,297)
    b.AutoButtonColor   = false
    b.Size              = sz  or UDim2.fromScale(1,1)
    b.Position          = pos or UDim2.fromScale(0,0)
    b.ZIndex            = zi  or 2
    b.Parent = p; return b
end

function G.Corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,r or 8); c.Parent = p; return c
end

function G.Stroke(p, col, t)
    local s = Instance.new("UIStroke")
    s.Color = col or Color3.new(1,1,1); s.Thickness = t or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

function G.Pad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0,t or 5); u.PaddingRight  = UDim.new(0,r or 5)
    u.PaddingBottom = UDim.new(0,b or 5); u.PaddingLeft   = UDim.new(0,l or 5)
    u.Parent = p; return u
end

function G.List(p, dir, ha, va, pad)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = ha  or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = va  or Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Padding             = UDim.new(0, pad or 5)
    l.Parent = p; return l
end

function G.Shadow(p, col, zi)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"; s.BackgroundTransparency = 1
    s.Image = "rbxassetid://5554236805"; s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(23,23,277,277)
    s.ImageColor3 = col or Color3.new(0,0,0); s.ImageTransparency = 0.5
    s.Size = UDim2.fromScale(1,1)+UDim2.fromOffset(36,36)
    s.Position = UDim2.fromOffset(-18,-18); s.ZIndex = (zi or 2)-1; s.Parent = p; return s
end

function G.ScrollFrame(p, sz, pos, zi)
    local f = Instance.new("ScrollingFrame")
    f.BackgroundTransparency = 1; f.BorderSizePixel = 0
    f.Size = sz or UDim2.fromScale(1,1); f.Position = pos or UDim2.fromScale(0,0)
    f.CanvasSize = UDim2.fromScale(0,0); f.ScrollBarThickness = 3
    f.ScrollingDirection = Enum.ScrollingDirection.Y
    f.ZIndex = zi or 2; f.Parent = p; return f
end

-- auto canvas-fit helper
function G.AutoCanvas(frame, layout, padding)
    padding = padding or 16
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + padding)
    end)
end

-- ════════════════════════════════════════════════════════════
--  THEMES  (16 themes, all fields required by every component)
-- ════════════════════════════════════════════════════════════
local Themes = {}

-- All fields:
-- Primary, Secondary, Tertiary, Accent, AccentDark, AccentGlow
-- Text, TextMuted, TextDisabled, TextDark
-- Success, Warning, Error, Info
-- Shadow, Border, BorderLight, Highlight
-- TitleBar, NavBar, NavBarActive, CardBg
-- Toggle, Slider, ScrollBar
-- Radius, Font, FontTitle, FontMono

local function DefTheme(t)
    -- fill optional defaults
    t.BorderLight    = t.BorderLight    or Util.Lerp(t.Border,    t.Text,       0.08)
    t.AccentGlow     = t.AccentGlow     or Util.Lerp(t.Accent,    Color3.new(0,0,0), 0.4)
    t.NavBarActive   = t.NavBarActive   or t.Tertiary
    t.CardBg         = t.CardBg         or t.Secondary
    t.TextDisabled   = t.TextDisabled   or Util.Lerp(t.TextMuted, t.Secondary, 0.4)
    t.ScrollBar      = t.ScrollBar      or t.Accent
    t.Highlight      = t.Highlight      or t.Accent
    t.FontMono       = t.FontMono       or Enum.Font.Code
    return t
end

Themes.Carbon = DefTheme({
    Name="Carbon",
    Primary=Color3.fromRGB(16,16,22),        Secondary=Color3.fromRGB(26,26,36),
    Tertiary=Color3.fromRGB(38,38,54),       Accent=Color3.fromRGB(108,68,252),
    AccentDark=Color3.fromRGB(78,44,198),    Text=Color3.fromRGB(236,236,245),
    TextMuted=Color3.fromRGB(136,136,162),   TextDark=Color3.fromRGB(8,8,16),
    Success=Color3.fromRGB(48,212,112),      Warning=Color3.fromRGB(252,182,38),
    Error=Color3.fromRGB(252,62,78),         Info=Color3.fromRGB(68,172,252),
    Shadow=Color3.fromRGB(0,0,0),            Border=Color3.fromRGB(48,48,66),
    TitleBar=Color3.fromRGB(20,20,28),       NavBar=Color3.fromRGB(16,16,24),
    Toggle=Color3.fromRGB(108,68,252),       Slider=Color3.fromRGB(108,68,252),
    Radius=8, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})

Themes.Midnight = DefTheme({
    Name="Midnight",
    Primary=Color3.fromRGB(5,5,9),           Secondary=Color3.fromRGB(11,11,18),
    Tertiary=Color3.fromRGB(18,18,30),       Accent=Color3.fromRGB(168,88,252),
    AccentDark=Color3.fromRGB(128,58,218),   Text=Color3.fromRGB(225,220,242),
    TextMuted=Color3.fromRGB(115,110,148),   TextDark=Color3.fromRGB(5,5,9),
    Success=Color3.fromRGB(72,212,132),      Warning=Color3.fromRGB(252,192,42),
    Error=Color3.fromRGB(252,62,82),         Info=Color3.fromRGB(88,172,252),
    Shadow=Color3.fromRGB(0,0,0),            Border=Color3.fromRGB(26,22,40),
    TitleBar=Color3.fromRGB(9,7,15),         NavBar=Color3.fromRGB(7,5,12),
    Toggle=Color3.fromRGB(168,88,252),       Slider=Color3.fromRGB(168,88,252),
    Radius=8, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})

Themes.Neon = DefTheme({
    Name="Neon",
    Primary=Color3.fromRGB(3,3,7),           Secondary=Color3.fromRGB(9,11,18),
    Tertiary=Color3.fromRGB(16,18,34),       Accent=Color3.fromRGB(0,242,188),
    AccentDark=Color3.fromRGB(0,188,145),    Text=Color3.fromRGB(208,252,245),
    TextMuted=Color3.fromRGB(85,168,155),    TextDark=Color3.fromRGB(3,3,7),
    Success=Color3.fromRGB(0,252,142),       Warning=Color3.fromRGB(252,212,0),
    Error=Color3.fromRGB(252,42,92),         Info=Color3.fromRGB(0,192,252),
    Shadow=Color3.fromRGB(0,215,175),        Border=Color3.fromRGB(0,75,62),
    TitleBar=Color3.fromRGB(7,7,14),         NavBar=Color3.fromRGB(5,5,12),
    Toggle=Color3.fromRGB(0,242,188),        Slider=Color3.fromRGB(0,242,188),
    Radius=4, Font=Enum.Font.Code, FontTitle=Enum.Font.Code,
})

Themes.Ocean = DefTheme({
    Name="Ocean",
    Primary=Color3.fromRGB(5,14,34),         Secondary=Color3.fromRGB(9,22,50),
    Tertiary=Color3.fromRGB(14,35,74),       Accent=Color3.fromRGB(22,152,252),
    AccentDark=Color3.fromRGB(12,112,208),   Text=Color3.fromRGB(192,225,252),
    TextMuted=Color3.fromRGB(85,140,195),    TextDark=Color3.fromRGB(5,14,34),
    Success=Color3.fromRGB(32,212,132),      Warning=Color3.fromRGB(252,192,32),
    Error=Color3.fromRGB(252,72,72),         Info=Color3.fromRGB(22,152,252),
    Shadow=Color3.fromRGB(0,12,52),          Border=Color3.fromRGB(20,52,102),
    TitleBar=Color3.fromRGB(7,18,42),        NavBar=Color3.fromRGB(5,14,36),
    Toggle=Color3.fromRGB(22,152,252),       Slider=Color3.fromRGB(22,152,252),
    Radius=8, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})

Themes.Forest = DefTheme({
    Name="Forest",
    Primary=Color3.fromRGB(12,20,14),        Secondary=Color3.fromRGB(20,35,22),
    Tertiary=Color3.fromRGB(30,54,33),       Accent=Color3.fromRGB(68,192,90),
    AccentDark=Color3.fromRGB(46,148,65),    Text=Color3.fromRGB(202,235,207),
    TextMuted=Color3.fromRGB(105,162,115),   TextDark=Color3.fromRGB(12,20,14),
    Success=Color3.fromRGB(68,192,90),       Warning=Color3.fromRGB(212,182,42),
    Error=Color3.fromRGB(212,72,72),         Info=Color3.fromRGB(72,172,212),
    Shadow=Color3.fromRGB(2,10,4),           Border=Color3.fromRGB(34,64,37),
    TitleBar=Color3.fromRGB(16,26,18),       NavBar=Color3.fromRGB(12,22,14),
    Toggle=Color3.fromRGB(68,192,90),        Slider=Color3.fromRGB(68,192,90),
    Radius=6, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

Themes.Mocha = DefTheme({
    Name="Mocha",
    Primary=Color3.fromRGB(36,26,16),        Secondary=Color3.fromRGB(55,42,26),
    Tertiary=Color3.fromRGB(78,59,40),       Accent=Color3.fromRGB(192,145,88),
    AccentDark=Color3.fromRGB(155,112,62),   Text=Color3.fromRGB(240,225,207),
    TextMuted=Color3.fromRGB(165,138,108),   TextDark=Color3.fromRGB(36,26,16),
    Success=Color3.fromRGB(72,178,98),       Warning=Color3.fromRGB(208,168,38),
    Error=Color3.fromRGB(202,62,62),         Info=Color3.fromRGB(92,162,212),
    Shadow=Color3.fromRGB(12,8,3),           Border=Color3.fromRGB(84,62,42),
    TitleBar=Color3.fromRGB(46,32,20),       NavBar=Color3.fromRGB(38,26,16),
    Toggle=Color3.fromRGB(192,145,88),       Slider=Color3.fromRGB(192,145,88),
    Radius=8, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

Themes.Dracula = DefTheme({
    Name="Dracula",
    Primary=Color3.fromRGB(40,42,54),        Secondary=Color3.fromRGB(48,50,64),
    Tertiary=Color3.fromRGB(58,60,76),       Accent=Color3.fromRGB(189,147,249),
    AccentDark=Color3.fromRGB(148,108,215),  Text=Color3.fromRGB(248,248,242),
    TextMuted=Color3.fromRGB(146,146,146),   TextDark=Color3.fromRGB(40,42,54),
    Success=Color3.fromRGB(80,250,123),      Warning=Color3.fromRGB(241,250,140),
    Error=Color3.fromRGB(255,85,85),         Info=Color3.fromRGB(139,233,253),
    Shadow=Color3.fromRGB(8,8,12),           Border=Color3.fromRGB(66,68,86),
    TitleBar=Color3.fromRGB(44,46,60),       NavBar=Color3.fromRGB(38,40,52),
    Toggle=Color3.fromRGB(189,147,249),      Slider=Color3.fromRGB(189,147,249),
    Radius=6, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})

Themes.Blood = DefTheme({
    Name="Blood",
    Primary=Color3.fromRGB(12,3,3),          Secondary=Color3.fromRGB(25,7,7),
    Tertiary=Color3.fromRGB(44,12,12),       Accent=Color3.fromRGB(218,32,48),
    AccentDark=Color3.fromRGB(172,20,32),    Text=Color3.fromRGB(243,208,208),
    TextMuted=Color3.fromRGB(155,96,96),     TextDark=Color3.fromRGB(12,3,3),
    Success=Color3.fromRGB(58,188,88),       Warning=Color3.fromRGB(228,172,32),
    Error=Color3.fromRGB(218,32,48),         Info=Color3.fromRGB(78,158,232),
    Shadow=Color3.fromRGB(0,0,0),            Border=Color3.fromRGB(52,16,16),
    TitleBar=Color3.fromRGB(20,5,5),         NavBar=Color3.fromRGB(14,3,3),
    Toggle=Color3.fromRGB(218,32,48),        Slider=Color3.fromRGB(218,32,48),
    Radius=5, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})

Themes.Monochrome = DefTheme({
    Name="Monochrome",
    Primary=Color3.fromRGB(10,10,10),        Secondary=Color3.fromRGB(20,20,20),
    Tertiary=Color3.fromRGB(33,33,33),       Accent=Color3.fromRGB(218,218,218),
    AccentDark=Color3.fromRGB(162,162,162),  Text=Color3.fromRGB(238,238,238),
    TextMuted=Color3.fromRGB(126,126,126),   TextDark=Color3.fromRGB(10,10,10),
    Success=Color3.fromRGB(185,185,185),     Warning=Color3.fromRGB(205,205,205),
    Error=Color3.fromRGB(255,255,255),       Info=Color3.fromRGB(150,150,150),
    Shadow=Color3.fromRGB(0,0,0),            Border=Color3.fromRGB(44,44,44),
    TitleBar=Color3.fromRGB(16,16,16),       NavBar=Color3.fromRGB(12,12,12),
    Toggle=Color3.fromRGB(205,205,205),      Slider=Color3.fromRGB(205,205,205),
    Radius=4, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})

Themes.Slate = DefTheme({
    Name="Slate",
    Primary=Color3.fromRGB(28,33,40),        Secondary=Color3.fromRGB(38,44,53),
    Tertiary=Color3.fromRGB(50,58,68),       Accent=Color3.fromRGB(92,178,228),
    AccentDark=Color3.fromRGB(66,142,192),   Text=Color3.fromRGB(212,222,232),
    TextMuted=Color3.fromRGB(115,135,155),   TextDark=Color3.fromRGB(28,33,40),
    Success=Color3.fromRGB(62,198,118),      Warning=Color3.fromRGB(242,182,38),
    Error=Color3.fromRGB(232,72,78),         Info=Color3.fromRGB(92,178,228),
    Shadow=Color3.fromRGB(8,10,14),          Border=Color3.fromRGB(52,62,74),
    TitleBar=Color3.fromRGB(33,38,48),       NavBar=Color3.fromRGB(26,30,38),
    Toggle=Color3.fromRGB(92,178,228),       Slider=Color3.fromRGB(92,178,228),
    Radius=6, Font=Enum.Font.GothamSemibold, FontTitle=Enum.Font.GothamBold,
})

Themes.Light = DefTheme({
    Name="Light",
    Primary=Color3.fromRGB(244,244,250),     Secondary=Color3.fromRGB(230,230,240),
    Tertiary=Color3.fromRGB(212,212,228),    Accent=Color3.fromRGB(90,50,235),
    AccentDark=Color3.fromRGB(66,34,196),    Text=Color3.fromRGB(20,20,32),
    TextMuted=Color3.fromRGB(108,108,138),   TextDark=Color3.fromRGB(244,244,250),
    Success=Color3.fromRGB(32,175,92),       Warning=Color3.fromRGB(198,155,20),
    Error=Color3.fromRGB(198,42,58),         Info=Color3.fromRGB(50,132,218),
    Shadow=Color3.fromRGB(136,136,172),      Border=Color3.fromRGB(188,188,212),
    TitleBar=Color3.fromRGB(90,50,235),      NavBar=Color3.fromRGB(78,42,215),
    Toggle=Color3.fromRGB(90,50,235),        Slider=Color3.fromRGB(90,50,235),
    Radius=10, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

Themes.Rose = DefTheme({
    Name="Rose",
    Primary=Color3.fromRGB(254,242,246),     Secondary=Color3.fromRGB(253,225,236),
    Tertiary=Color3.fromRGB(250,205,222),    Accent=Color3.fromRGB(212,50,92),
    AccentDark=Color3.fromRGB(172,33,70),    Text=Color3.fromRGB(46,16,26),
    TextMuted=Color3.fromRGB(142,88,108),    TextDark=Color3.fromRGB(254,242,246),
    Success=Color3.fromRGB(52,172,92),       Warning=Color3.fromRGB(212,142,26),
    Error=Color3.fromRGB(192,33,53),         Info=Color3.fromRGB(72,132,212),
    Shadow=Color3.fromRGB(172,72,92),        Border=Color3.fromRGB(212,170,182),
    TitleBar=Color3.fromRGB(212,50,92),      NavBar=Color3.fromRGB(192,42,80),
    Toggle=Color3.fromRGB(212,50,92),        Slider=Color3.fromRGB(212,50,92),
    Radius=12, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

Themes.Ice = DefTheme({
    Name="Ice",
    Primary=Color3.fromRGB(236,246,254),     Secondary=Color3.fromRGB(212,235,253),
    Tertiary=Color3.fromRGB(185,220,250),    Accent=Color3.fromRGB(48,135,215),
    AccentDark=Color3.fromRGB(30,103,180),   Text=Color3.fromRGB(16,46,86),
    TextMuted=Color3.fromRGB(88,132,176),    TextDark=Color3.fromRGB(236,246,254),
    Success=Color3.fromRGB(32,175,112),      Warning=Color3.fromRGB(198,155,22),
    Error=Color3.fromRGB(198,48,62),         Info=Color3.fromRGB(48,135,215),
    Shadow=Color3.fromRGB(88,152,212),       Border=Color3.fromRGB(162,208,243),
    TitleBar=Color3.fromRGB(48,135,215),     NavBar=Color3.fromRGB(40,120,198),
    Toggle=Color3.fromRGB(48,135,215),       Slider=Color3.fromRGB(48,135,215),
    Radius=12, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

Themes.Sunset = DefTheme({
    Name="Sunset",
    Primary=Color3.fromRGB(254,233,206),     Secondary=Color3.fromRGB(253,212,172),
    Tertiary=Color3.fromRGB(252,190,136),    Accent=Color3.fromRGB(225,88,30),
    AccentDark=Color3.fromRGB(188,66,16),    Text=Color3.fromRGB(56,26,10),
    TextMuted=Color3.fromRGB(152,100,65),    TextDark=Color3.fromRGB(254,233,206),
    Success=Color3.fromRGB(52,172,75),       Warning=Color3.fromRGB(225,162,16),
    Error=Color3.fromRGB(202,42,42),         Info=Color3.fromRGB(52,132,212),
    Shadow=Color3.fromRGB(172,72,16),        Border=Color3.fromRGB(218,172,128),
    TitleBar=Color3.fromRGB(225,88,30),      NavBar=Color3.fromRGB(202,75,20),
    Toggle=Color3.fromRGB(225,88,30),        Slider=Color3.fromRGB(225,88,30),
    Radius=10, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

Themes.Sakura = DefTheme({
    Name="Sakura",
    Primary=Color3.fromRGB(254,241,247),     Secondary=Color3.fromRGB(251,223,238),
    Tertiary=Color3.fromRGB(247,202,226),    Accent=Color3.fromRGB(222,97,158),
    AccentDark=Color3.fromRGB(185,70,125),   Text=Color3.fromRGB(60,20,43),
    TextMuted=Color3.fromRGB(158,104,135),   TextDark=Color3.fromRGB(254,241,247),
    Success=Color3.fromRGB(78,185,112),      Warning=Color3.fromRGB(212,165,36),
    Error=Color3.fromRGB(212,53,78),         Info=Color3.fromRGB(102,145,222),
    Shadow=Color3.fromRGB(198,118,157),      Border=Color3.fromRGB(228,182,207),
    TitleBar=Color3.fromRGB(222,97,158),     NavBar=Color3.fromRGB(202,80,140),
    Toggle=Color3.fromRGB(222,97,158),       Slider=Color3.fromRGB(222,97,158),
    Radius=14, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

Themes.Candy = DefTheme({
    Name="Candy",
    Primary=Color3.fromRGB(254,238,254),     Secondary=Color3.fromRGB(249,217,253),
    Tertiary=Color3.fromRGB(240,192,254),    Accent=Color3.fromRGB(195,58,252),
    AccentDark=Color3.fromRGB(155,36,207),   Text=Color3.fromRGB(50,7,70),
    TextMuted=Color3.fromRGB(152,95,175),    TextDark=Color3.fromRGB(254,238,254),
    Success=Color3.fromRGB(58,202,118),      Warning=Color3.fromRGB(252,178,28),
    Error=Color3.fromRGB(252,58,88),         Info=Color3.fromRGB(58,178,252),
    Shadow=Color3.fromRGB(178,78,218),       Border=Color3.fromRGB(225,182,245),
    TitleBar=Color3.fromRGB(195,58,252),     NavBar=Color3.fromRGB(172,44,225),
    Toggle=Color3.fromRGB(195,58,252),       Slider=Color3.fromRGB(195,58,252),
    Radius=14, Font=Enum.Font.Gotham, FontTitle=Enum.Font.GothamBold,
})

-- ════════════════════════════════════════════════════════════
--  CONFIG
-- ════════════════════════════════════════════════════════════
local Cfg = {}; Cfg.__index = Cfg
function Cfg.new(name)
    local s = setmetatable({_name=name, _file=name.."_OxConfig.json", _data={}}, Cfg)
    s:_load(); return s
end
function Cfg:_load()
    local ok = pcall(function()
        if readfile then
            local raw = readfile(self._file)
            self._data = HttpService:JSONDecode(raw) or {}
        end
    end)
    if not ok then self._data = {} end
end
function Cfg:_save()
    pcall(function()
        if writefile then writefile(self._file, HttpService:JSONEncode(self._data)) end
    end)
end
function Cfg:Set(k,v)    self._data[k]=v; self:_save() end
function Cfg:Get(k, def) local v=self._data[k]; return v~=nil and v or def end
function Cfg:Delete(k)   self._data[k]=nil; self:_save() end
function Cfg:Reset()     self._data={}; self:_save() end
function Cfg:All()       return Util.DeepCopy(self._data) end
function Cfg:Export()
    local ok,s = pcall(HttpService.JSONEncode, HttpService, self._data)
    return ok and s or "{}"
end
function Cfg:Import(json)
    local ok,d = pcall(HttpService.JSONDecode, HttpService, json)
    if ok and type(d)=="table" then self._data=d; self:_save(); return true end
    return false
end
function Cfg:FromClipboard()
    local ok,txt = pcall(function() return getclipboard() end)
    if ok and txt then return self:Import(txt) end; return false
end

-- ════════════════════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ════════════════════════════════════════════════════════════
local NPOS = {
    BottomRight = {ap=Vector2.new(1,1), pos=UDim2.new(1,-12,1,-12),  va=Enum.VerticalAlignment.Bottom},
    TopRight    = {ap=Vector2.new(1,0), pos=UDim2.new(1,-12,0,12),   va=Enum.VerticalAlignment.Top},
    BottomLeft  = {ap=Vector2.new(0,1), pos=UDim2.new(0,12,1,-12),   va=Enum.VerticalAlignment.Bottom},
    TopLeft     = {ap=Vector2.new(0,0), pos=UDim2.new(0,12,0,12),    va=Enum.VerticalAlignment.Top},
}

local NTYPES = {
    success = {icon="✓", col=Color3.fromRGB(46,196,108)},
    warning = {icon="!", col=Color3.fromRGB(235,168,26)},
    error   = {icon="✕", col=Color3.fromRGB(230,55,72)},
    info    = {icon="i", col=Color3.fromRGB(60,160,248)},
}

local NotifSys = {}; NotifSys.__index = NotifSys
function NotifSys.new(sg, pos)
    local s = setmetatable({_idx=0}, NotifSys)
    local pd = NPOS[pos] or NPOS.BottomRight
    s._cont = G.Frame(sg, Color3.new(0,0,0), UDim2.fromOffset(325,0), pd.pos, 900)
    s._cont.BackgroundTransparency=1; s._cont.AnchorPoint=pd.ap
    local l = G.List(s._cont,nil,nil,pd.va,8)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s._cont.Size = UDim2.fromOffset(325, l.AbsoluteContentSize.Y+10)
    end)
    return s
end

function NotifSys:Push(cfg, th)
    local title   = cfg.Title       or "Notification"
    local desc    = cfg.Description or ""
    local ntype   = cfg.Type        or "info"
    local dur     = cfg.Duration    or 4
    local cb      = cfg.Callback
    local buttons = cfg.Buttons     -- optional {label=str, callback=fn}
    local td      = NTYPES[ntype] or NTYPES.info
    self._idx += 1

    local cardH = 68 + (buttons and 32 or 0)
    local card  = G.Frame(self._cont, th.Secondary, UDim2.fromOffset(325, cardH))
    card.ClipsDescendants=true; card.ZIndex=900; card.LayoutOrder=self._idx
    G.Corner(card,10); G.Stroke(card,th.Border,1); G.Shadow(card,th.Shadow,900)

    -- coloured left bar
    G.Frame(card, td.col, UDim2.fromOffset(4,cardH), nil, 901)

    -- icon circle
    local icBg = G.Frame(card, Util.Lerp(td.col,Color3.new(0,0,0),0.62),
        UDim2.fromOffset(28,28), UDim2.fromOffset(14,20), 901)
    G.Corner(icBg,14)
    G.Label(icBg,td.icon,td.col,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,16,Enum.TextXAlignment.Center,902)

    -- text
    G.Label(card,title,th.Text,UDim2.fromOffset(240,20),UDim2.fromOffset(52,8),Enum.Font.GothamBold,14,Enum.TextXAlignment.Left,901)
    local dl = G.Label(card,desc,th.TextMuted,UDim2.fromOffset(255,34),UDim2.fromOffset(52,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,901)
    dl.TextWrapped=true

    -- close btn
    local xb = Instance.new("TextButton")
    xb.BackgroundTransparency=1; xb.Size=UDim2.fromOffset(22,22)
    xb.Position=UDim2.new(1,-28,0,4); xb.Text="×"; xb.TextColor3=th.TextMuted
    xb.Font=Enum.Font.GothamBold; xb.TextSize=20; xb.ZIndex=902; xb.Parent=card

    -- progress bar
    local pf = G.Frame(card,td.col,UDim2.fromOffset(0,3))
    pf.Position=UDim2.new(0,0,1,-3); pf.ZIndex=901
    Tween(pf, TweenInfo.new(dur,Enum.EasingStyle.Linear), {Size=UDim2.fromOffset(325,3)})

    -- optional action buttons
    if buttons then
        for i, btn in ipairs(buttons) do
            local bb = Instance.new("TextButton")
            bb.BackgroundColor3 = th.Tertiary
            bb.BorderSizePixel  = 0
            bb.Size   = UDim2.fromOffset(90,22)
            bb.Position = UDim2.fromOffset(52+(i-1)*96, 68-28)
            bb.Text   = btn.label or "OK"
            bb.TextColor3 = th.Accent
            bb.Font   = Enum.Font.GothamBold
            bb.TextSize=11; bb.ZIndex=902; bb.Parent=card
            G.Corner(bb,5)
            bb.MouseButton1Click:Connect(function()
                if btn.callback then Util.Call(btn.callback) end
            end)
        end
    end

    -- slide in
    card.Position = UDim2.fromOffset(340,0)
    SP(card, {Position=UDim2.fromOffset(0,0)})

    local gone = false
    local function dismiss()
        if gone then return end; gone=true
        FT(card, {Position=UDim2.fromOffset(340,0)})
        task.delay(0.2, function() if card.Parent then card:Destroy() end end)
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
--  TOOLTIP
-- ════════════════════════════════════════════════════════════
local function MakeTooltip(el, text, th, sg)
    if not text or text=="" then return end
    local tip, mc
    el.MouseEnter:Connect(function()
        if tip then tip:Destroy() end
        local tw = TextService:GetTextSize(text,11,Enum.Font.Gotham,Vector2.new(9999,9999)).X
        tip = G.Frame(sg,th.Tertiary,UDim2.fromOffset(tw+18,24),nil,9500)
        G.Corner(tip,5); G.Stroke(tip,th.Border,1); G.Shadow(tip,th.Shadow,9500)
        G.Label(tip,text,th.Text,UDim2.fromScale(1,1),nil,Enum.Font.Gotham,11,Enum.TextXAlignment.Center,9501)
        tip.Position=UDim2.fromOffset(Mouse.X+14,Mouse.Y-32)
        mc = Mouse.Moved:Connect(function()
            if tip and tip.Parent then tip.Position=UDim2.fromOffset(Mouse.X+14,Mouse.Y-32) end
        end)
    end)
    el.MouseLeave:Connect(function()
        if mc then mc:Disconnect(); mc=nil end
        if tip then tip:Destroy(); tip=nil end
    end)
end

-- ════════════════════════════════════════════════════════════
--  SPLASH SCREEN
-- ════════════════════════════════════════════════════════════
local function ShowSplash(sg, cfg, th, onDone)
    local title    = cfg.Title    or "Oxygen"
    local subtitle = cfg.Subtitle or "Loading..."
    local version  = cfg.Version  or "beta 0.0.1"
    local dur      = cfg.Duration or 2.8

    local overlay = G.Frame(sg, Color3.new(0,0,0), UDim2.fromScale(1,1), nil, 1000)
    overlay.BackgroundTransparency = 1
    FT(overlay, {BackgroundTransparency=0})

    -- card
    local card = G.Frame(sg, th.Secondary, UDim2.fromOffset(380,220),
        UDim2.fromScale(0.5,0.5), 1001)
    card.AnchorPoint=Vector2.new(0.5,0.5)
    G.Corner(card, 14); G.Shadow(card,th.Shadow,1001); G.Stroke(card,th.Border,1)
    card.BackgroundTransparency=1
    card.Size = UDim2.fromOffset(30,30)
    SP(card,{Size=UDim2.fromOffset(380,220), BackgroundTransparency=0})

    -- logo big circle
    task.delay(0.1, function()
        local circle = G.Frame(card,th.Accent,UDim2.fromOffset(62,62),UDim2.fromOffset(159,30),1002)
        circle.BackgroundTransparency=1; G.Corner(circle,31)
        local innerCircle = G.Frame(circle,th.AccentDark,UDim2.fromOffset(38,38),UDim2.fromOffset(12,12),1003)
        G.Corner(innerCircle,19)
        SP(circle,{BackgroundTransparency=0})

        local dot = G.Frame(circle,Color3.new(1,1,1),UDim2.fromOffset(12,12),UDim2.fromOffset(25,25),1004)
        G.Corner(dot,6)
        dot.BackgroundTransparency=1
        FT(dot,{BackgroundTransparency=0.3})
    end)

    -- title
    task.delay(0.18, function()
        local tl=G.Label(card,title,th.Text,UDim2.fromOffset(360,36),UDim2.fromOffset(10,100),th.FontTitle,30,Enum.TextXAlignment.Center,1002)
        tl.TextTransparency=1; FT(tl,{TextTransparency=0})
        local sl=G.Label(card,subtitle,th.TextMuted,UDim2.fromOffset(360,20),UDim2.fromOffset(10,136),Enum.Font.Gotham,13,Enum.TextXAlignment.Center,1002)
        sl.TextTransparency=1; FT(sl,{TextTransparency=0})
        local vl=G.Label(card,version,th.Accent,UDim2.fromOffset(360,16),UDim2.fromOffset(10,156),Enum.Font.GothamBold,11,Enum.TextXAlignment.Center,1002)
        vl.TextTransparency=1; FT(vl,{TextTransparency=0})
    end)

    -- animated loading bar
    task.delay(0.3, function()
        local barBg = G.Frame(card,th.Tertiary,UDim2.fromOffset(320,4),UDim2.fromOffset(30,188),1002)
        G.Corner(barBg,2)
        local bar = G.Frame(barBg,th.Accent,UDim2.fromOffset(0,4),nil,1003)
        G.Corner(bar,2)
        Tween(bar,TweenInfo.new(dur-0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
            {Size=UDim2.fromOffset(320,4)})
    end)

    -- done
    task.delay(dur, function()
        FT(card,{BackgroundTransparency=1})
        FT(overlay,{BackgroundTransparency=1})
        task.delay(0.2, function()
            card:Destroy(); overlay:Destroy()
            if onDone then onDone() end
        end)
    end)
end

-- ════════════════════════════════════════════════════════════
--  MAIN LIBRARY
-- ════════════════════════════════════════════════════════════
local Oxygen = {}; Oxygen.__index = Oxygen
Oxygen.Version = "beta 0.0.1"
Oxygen.Themes  = Themes

function Oxygen.new(config)
    local self = setmetatable({}, Oxygen)
    config = config or {}

    self.Title      = config.Title       or "Oxygen"
    self.Subtitle   = config.Subtitle    or "beta 0.0.1"
    self.ThemeName  = config.Theme       or "Carbon"
    self.SizeX      = config.SizeX       or 580
    self.SizeY      = config.SizeY       or 420
    self.DoSave     = config.SaveConfig  ~= false
    self.CfgName    = config.ConfigName  or self.Title
    self.ShowWM     = config.Watermark   ~= false
    self.ToggleKey  = config.ToggleKey   or Enum.KeyCode.RightControl
    self.MinKey     = config.MinimizeKey or Enum.KeyCode.RightShift
    self.NotifPos   = config.NotifPos    or "BottomRight"
    self.Splash     = config.Splash      -- nil / false = no splash; table = show splash
    self.SplashDur  = (type(config.Splash)=="table" and config.Splash.Duration) or 2.8

    self.Theme      = Themes[self.ThemeName] or Themes.Carbon
    self.Tabs       = {}         -- {Title, Btn, Page, IconL, LabelL, Ind}
    self._conns     = {}
    self._themed    = {}         -- {obj, prop, role} for live theme re-apply
    self.Visible    = true
    self.Minimized  = false
    self.ActiveTab  = 1

    if self.DoSave then
        self.Store = Cfg.new(self.CfgName)
        local saved = self.Store:Get("theme", nil)
        if saved and Themes[saved] then
            self.ThemeName = saved
            self.Theme     = Themes[saved]
        end
    end

    self:_Build()
    self:_Keys()
    self:_Watermark()

    -- splash runs before settings tab so the window isn't visible during splash
    if self.Splash then
        self.Win.Visible = false
        if self._wmF then self._wmF.Visible = false end
        ShowSplash(self.SG, {
            Title    = type(self.Splash)=="table" and (self.Splash.Title    or self.Title)    or self.Title,
            Subtitle = type(self.Splash)=="table" and (self.Splash.Subtitle or self.Subtitle) or self.Subtitle,
            Version  = Oxygen.Version,
            Duration = self.SplashDur,
        }, self.Theme, function()
            self.Win.Visible = true
            if self._wmF then self._wmF.Visible = self.ShowWM end
            SP(self.Win, {Size=UDim2.fromOffset(self.SizeX, self.SizeY)})
        end)
        self.Win.Size = UDim2.fromOffset(0,0)
    end

    self:_BuildSettings()  -- always after user tabs, always last

    return self
end

function Oxygen:_C(c) table.insert(self._conns, c) end

-- register for live theme re-application
function Oxygen:_TR(obj, prop, role)
    table.insert(self._themed, {obj=obj, prop=prop, role=role})
end

function Oxygen:_ProtectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent=CoreGui
        elseif gethui                then gui.Parent=gethui()
        else                              gui.Parent=CoreGui end
    end)
    if not gui.Parent then gui.Parent=LP:WaitForChild("PlayerGui") end
end

-- ════════════════════════════════════════════════════════════
--  BUILD WINDOW
-- ════════════════════════════════════════════════════════════
function Oxygen:_Build()
    local th = self.Theme

    -- screen gui
    self.SG = Instance.new("ScreenGui")
    self.SG.Name = "OxygenUI_"..self.Title
    self.SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.SG.ResetOnSpawn   = false
    self:_ProtectGui(self.SG)

    self.NotifsObj = NotifSys.new(self.SG, self.NotifPos)

    -- ── main window ──────────────────────────────────────
    self.Win = G.Frame(self.SG, th.Primary,
        UDim2.fromOffset(self.SizeX, self.SizeY),
        UDim2.fromScale(0.5,0.5), 10)
    self.Win.AnchorPoint    = Vector2.new(0.5,0.5)
    self.Win.ClipsDescendants = true
    G.Corner(self.Win, th.Radius)
    G.Shadow(self.Win, th.Shadow, 10)
    self._winStroke = G.Stroke(self.Win, th.Border, 1)
    self:_TR(self.Win, "BackgroundColor3", "Primary")
    self:_TR(self._winStroke, "Color", "Border")

    if not self.Splash then
        self.Win.Size = UDim2.fromOffset(0,0)
        SP(self.Win, {Size=UDim2.fromOffset(self.SizeX, self.SizeY)})
    end

    -- ── title bar ────────────────────────────────────────
    self.TBar = G.Frame(self.Win, th.TitleBar, UDim2.fromOffset(self.SizeX,44), nil, 15)
    self:_TR(self.TBar, "BackgroundColor3", "TitleBar")

    self._tbarStripe = G.Frame(self.TBar, th.Accent, UDim2.fromOffset(self.SizeX,2), UDim2.new(0,0,1,-2), 16)
    self:_TR(self._tbarStripe, "BackgroundColor3", "Accent")

    self._pip = G.Frame(self.TBar, th.Accent, UDim2.fromOffset(8,8), UDim2.fromOffset(12,18), 16)
    G.Corner(self._pip,4)
    self:_TR(self._pip,"BackgroundColor3","Accent")

    self._tLbl = G.Label(self.TBar, self.Title, th.Text,
        UDim2.fromOffset(240,26), UDim2.fromOffset(28,4),
        th.FontTitle, 16, Enum.TextXAlignment.Left, 16)
    self:_TR(self._tLbl,"TextColor3","Text")

    self._sLbl = G.Label(self.TBar, self.Subtitle, th.TextMuted,
        UDim2.fromOffset(240,14), UDim2.fromOffset(28,25),
        Enum.Font.Gotham, 10, Enum.TextXAlignment.Left, 16)
    self:_TR(self._sLbl,"TextColor3","TextMuted")

    -- window control buttons (close/min/hide)
    local function WBtn(xo, bgCol, ic)
        local b = Instance.new("TextButton")
        b.BackgroundColor3=bgCol; b.BorderSizePixel=0
        b.Size=UDim2.fromOffset(12,12); b.Position=UDim2.new(1,xo,0.5,-6)
        b.Text=""; b.ZIndex=17; b.Parent=self.TBar; G.Corner(b,6)
        local ico=G.Label(b,ic,Color3.new(0,0,0),UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,9,Enum.TextXAlignment.Center,18)
        ico.TextTransparency=1
        b.MouseEnter:Connect(function()  FT(ico,{TextTransparency=0}) end)
        b.MouseLeave:Connect(function()  FT(ico,{TextTransparency=1}) end)
        return b
    end
    WBtn(-22,Color3.fromRGB(255,88,78), "×").MouseButton1Click:Connect(function() self:Destroy() end)
    WBtn(-40,Color3.fromRGB(255,183,28),"−").MouseButton1Click:Connect(function() self:ToggleMinimize() end)
    WBtn(-58,Color3.fromRGB(38,200,64), "⤢").MouseButton1Click:Connect(function() self:Toggle() end)

    -- ── drag ────────────────────────────────────────────
    local dragging,dStart,wStart
    self.TBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dStart=Vector2.new(Mouse.X,Mouse.Y); wStart=self.Win.Position
        end
    end)
    self:_C(UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=Vector2.new(Mouse.X-dStart.X, Mouse.Y-dStart.Y)
            self.Win.Position=UDim2.new(wStart.X.Scale,wStart.X.Offset+d.X,wStart.Y.Scale,wStart.Y.Offset+d.Y)
        end
    end))
    self:_C(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end))

    -- ── resize handle ───────────────────────────────────
    local rHandle = G.Frame(self.Win,Color3.new(0,0,0),UDim2.fromOffset(16,16),UDim2.new(1,-16,1,-16),30)
    rHandle.BackgroundTransparency=1
    G.Label(rHandle,"⤡",th.TextMuted,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,12,Enum.TextXAlignment.Center,31)
    local resizing,rStart,rSize
    rHandle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            resizing=true; rStart=Vector2.new(Mouse.X,Mouse.Y); rSize=self.Win.AbsoluteSize
        end
    end)
    self:_C(UserInputService.InputChanged:Connect(function(i)
        if resizing and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=Vector2.new(Mouse.X-rStart.X,Mouse.Y-rStart.Y)
            local nx=math.max(rSize.X+d.X,380); local ny=math.max(rSize.Y+d.Y,260)
            self.SizeX=nx; self.SizeY=ny; self.Win.Size=UDim2.fromOffset(nx,ny)
            self.TBar.Size=UDim2.fromOffset(nx,44)
            self._tbarStripe.Size=UDim2.fromOffset(nx,2)
            self.SideBar.Size=UDim2.fromOffset(130,ny-44)
            self.Content.Size=UDim2.fromOffset(nx-130,ny-44)
            for _,t in ipairs(self.Tabs) do t.Page.Size=UDim2.fromOffset(nx-150,ny-82) end
        end
    end))
    self:_C(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end
    end))

    -- ── sidebar ─────────────────────────────────────────
    self.SideBar = G.Frame(self.Win, th.NavBar, UDim2.fromOffset(130,self.SizeY-44), UDim2.fromOffset(0,44), 5)
    self._sbStroke = G.Stroke(self.SideBar, th.Border, 1)
    self:_TR(self.SideBar,"BackgroundColor3","NavBar")
    self:_TR(self._sbStroke,"Color","Border")

    self.TabList = G.ScrollFrame(self.SideBar, UDim2.fromScale(1,1), nil, 6)
    self.TabList.ScrollBarImageColor3 = th.Accent
    self:_TR(self.TabList,"ScrollBarImageColor3","Accent")
    G.Pad(self.TabList,8,6,8,6)
    local tll = G.List(self.TabList,nil,nil,nil,4)
    G.AutoCanvas(self.TabList, tll, 16)

    -- ── content area ────────────────────────────────────
    self.Content = G.Frame(self.Win, th.Primary,
        UDim2.fromOffset(self.SizeX-130,self.SizeY-44),
        UDim2.fromOffset(130,44), 3, true)
    self:_TR(self.Content,"BackgroundColor3","Primary")

    self.PageTitle = G.Label(self.Content,"",th.Text,
        UDim2.fromOffset(self.SizeX-165,28), UDim2.fromOffset(12,4),
        th.FontTitle,14,Enum.TextXAlignment.Left,4)
    self:_TR(self.PageTitle,"TextColor3","Text")

    self._pgSep = G.Frame(self.Content,th.Border,UDim2.new(1,-24,0,1),UDim2.fromOffset(12,32),4)
    self:_TR(self._pgSep,"BackgroundColor3","Border")
end

-- ════════════════════════════════════════════════════════════
--  TAB SYSTEM
-- ════════════════════════════════════════════════════════════
function Oxygen:AddTab(config)
    config = config or {}
    local title = config.Title or "Tab"
    local icon  = config.Icon  or "•"
    local th    = self.Theme
    local idx   = #self.Tabs + 1

    -- button
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = idx==1 and th.NavBarActive or th.NavBar
    btn.BorderSizePixel  = 0
    btn.Size             = UDim2.new(1,0,0,34)
    btn.Text             = ""
    btn.ZIndex           = 7
    btn.LayoutOrder      = idx
    btn.Parent           = self.TabList
    G.Corner(btn,6)

    local ind = G.Frame(btn,th.Accent,UDim2.fromOffset(3,idx==1 and 20 or 0),UDim2.new(0,-1,0.5,-(idx==1 and 10 or 0)),8)
    G.Corner(ind,2)

    local iconL = G.Label(btn,icon,idx==1 and th.Accent or th.TextMuted,
        UDim2.fromOffset(22,34),UDim2.fromOffset(8,0),Enum.Font.GothamBold,14,Enum.TextXAlignment.Center,8)

    local tabL = G.Label(btn,title,idx==1 and th.Text or th.TextMuted,
        UDim2.new(1,-38,1,0),UDim2.fromOffset(32,0),th.Font,13,Enum.TextXAlignment.Left,8)

    -- page (scrollable content)
    local page = G.ScrollFrame(self.Content, UDim2.fromOffset(self.SizeX-150,self.SizeY-82),
        UDim2.fromOffset(10,38), 4)
    page.ScrollBarImageColor3 = th.Accent
    page.Visible = (idx==1)
    self:_TR(page,"ScrollBarImageColor3","Accent")
    G.Pad(page,6,6,12,4)
    local pl = G.List(page,nil,nil,nil,6)
    G.AutoCanvas(page, pl, 24)

    -- hover
    btn.MouseEnter:Connect(function()
        if self.ActiveTab~=idx then FT(btn,{BackgroundColor3=th.Tertiary}) end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab~=idx then FT(btn,{BackgroundColor3=th.NavBar}) end
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
        FT(t.Btn,  {BackgroundColor3=a and th.NavBarActive or th.NavBar})
        FT(t.Icon, {TextColor3=a and th.Accent or th.TextMuted})
        FT(t.Label,{TextColor3=a and th.Text   or th.TextMuted})
        FT(t.Ind,  {Size=UDim2.fromOffset(3,a and 20 or 0),
                    Position=UDim2.new(0,-1,0.5,a and -10 or 0)})
    end
    self.PageTitle.Text=self.Tabs[idx].Title
end

-- ════════════════════════════════════════════════════════════
--  SETTINGS TAB  (always built last, always LayoutOrder = max)
-- ════════════════════════════════════════════════════════════
function Oxygen:_BuildSettings()
    -- Temporarily count user tabs so we can forcibly append settings AFTER
    local s = self:AddTab({Title="Settings", Icon="⚙"})

    s.Section({Title="Appearance"})
    local names={}
    for n in pairs(Themes) do table.insert(names,n) end
    table.sort(names)
    s.Dropdown({
        Title="Theme", Description="Applies instantly to all elements",
        Options=names, Default=self.ThemeName,
        Callback=function(v) self:SetTheme(v) end
    })

    s.Section({Title="Keybinds"})
    s.Keybind({Title="Toggle UI",   Description="Show / hide window",    Default=self.ToggleKey, Callback=function(k) self.ToggleKey=k end})
    s.Keybind({Title="Minimize UI", Description="Collapse to title bar", Default=self.MinKey,    Callback=function(k) self.MinKey=k end})

    s.Section({Title="Window"})
    s.Toggle({Title="Watermark", Description="Bottom-left info strip", Default=self.ShowWM,
        Callback=function(v) self.ShowWM=v; if self._wmF then self._wmF.Visible=v end end})

    s.Section({Title="Notifications"})
    s.RadioGroup({
        Title="Notification Position",
        Options={"BottomRight","TopRight","BottomLeft","TopLeft"},
        Default=self.NotifPos,
        Callback=function(pos)
            self.NotifPos=pos
            -- rebuild notif container at new position
            if self.NotifsObj and self.NotifsObj._cont then
                self.NotifsObj._cont:Destroy()
            end
            self.NotifsObj = NotifSys.new(self.SG, pos)
        end
    })

    s.Section({Title="Configuration"})
    s.Button({Title="Reset Config",  Description="Wipe all saved settings", Callback=function()
        if self.DoSave then self.Store:Reset()
            self:Notify({Title="Reset",Description="All settings cleared.",Type="warning"}) end
    end})
    s.Button({Title="Export Config", Description="Copy JSON to clipboard", Callback=function()
        if self.DoSave then
            pcall(function() setclipboard(self.Store:Export()) end)
            self:Notify({Title="Exported",Description="Config copied to clipboard.",Type="success"}) end
    end})
    s.Button({Title="Import Config", Description="Paste JSON from clipboard", Callback=function()
        if self.DoSave then
            local ok=self.Store:FromClipboard()
            self:Notify(ok and {Title="Imported",Description="Config applied.",Type="success"}
                           or  {Title="Failed",  Description="No valid config in clipboard.",Type="error"}) end
    end})

    s.Section({Title="About"})
    s.Label({Title="Oxygen UI Library  •  "..Oxygen.Version})
    s.Label({Title="github.com/oxygen015/roblox-modules"})
    s.Label({Title="Themes: "..#names.." available"})

    -- ── PIN SETTINGS TAB LAST ───────────────────────────
    -- pop the settings entry (always added last by AddTab) and ensure
    -- its LayoutOrder beats all other tabs even if tabs are added later
    local function pinSettings()
        local N = #self.Tabs
        local settingsEntry = self.Tabs[N]  -- always the last one we just added
        settingsEntry.Btn.LayoutOrder = 9999
        -- make sure all non-settings tabs have correct order 1..N-1
        for i = 1, N-1 do
            self.Tabs[i].Btn.LayoutOrder = i
        end
    end
    pinSettings()

    -- switch to tab 1 if there are user tabs
    if #self.Tabs > 1 then
        self.ActiveTab=1
        for i,t in ipairs(self.Tabs) do t.Page.Visible=(i==1) end
        self.PageTitle.Text=self.Tabs[1].Title
    end
end

-- ════════════════════════════════════════════════════════════
--  KEYS / WATERMARK
-- ════════════════════════════════════════════════════════════
function Oxygen:_Keys()
    self:_C(UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==self.ToggleKey  then self:Toggle() end
        if i.KeyCode==self.MinKey     then self:ToggleMinimize() end
    end))
end

function Oxygen:_Watermark()
    local th = self.Theme
    local wm = G.Frame(self.SG, th.Secondary, UDim2.fromOffset(202,24), UDim2.new(0,10,1,-34), 200)
    G.Corner(wm,6); G.Stroke(wm,th.Border,1)
    wm.Visible = self.ShowWM
    local wl = G.Label(wm,"⚡ Oxygen  •  "..self.Title,th.TextMuted,
        UDim2.fromScale(1,1),nil,Enum.Font.Gotham,11,Enum.TextXAlignment.Center,201)
    self:_TR(wm,"BackgroundColor3","Secondary")
    self:_TR(wl,"TextColor3","TextMuted")
    self._wmF=wm; self._wmL=wl
end

-- ════════════════════════════════════════════════════════════
--  PUBLIC METHODS
-- ════════════════════════════════════════════════════════════
function Oxygen:Toggle()
    self.Visible=not self.Visible
    FT(self.Win,{Size=self.Visible
        and UDim2.fromOffset(self.SizeX,self.Minimized and 44 or self.SizeY)
        or  UDim2.fromOffset(0,0)})
end

function Oxygen:ToggleMinimize()
    self.Minimized=not self.Minimized
    FT(self.Win,{Size=self.Minimized
        and UDim2.fromOffset(self.SizeX,44)
        or  UDim2.fromOffset(self.SizeX,self.SizeY)})
end

function Oxygen:Notify(cfg) return self.NotifsObj:Push(cfg, self.Theme) end

function Oxygen:SetTheme(name)
    local nt = Themes[name]
    if not nt then warn("[Oxygen] unknown theme: "..tostring(name)); return end
    self.Theme = nt; self.ThemeName = name

    -- re-apply every registered themed object
    for _, entry in ipairs(self._themed) do
        local col = nt[entry.role]
        if col and entry.obj and entry.obj.Parent then
            MT(entry.obj, {[entry.prop]=col})
        end
    end

    -- re-apply corner radius on win
    pcall(function()
        local c = self.Win:FindFirstChildWhichIsA("UICorner")
        if c then c.CornerRadius = UDim.new(0, nt.Radius) end
    end)

    -- update tab button colours
    for i,t in ipairs(self.Tabs) do
        local a=(i==self.ActiveTab)
        FT(t.Btn,  {BackgroundColor3=a and nt.NavBarActive or nt.NavBar})
        FT(t.Icon, {TextColor3=a and nt.Accent or nt.TextMuted})
        FT(t.Label,{TextColor3=a and nt.Text   or nt.TextMuted})
        FT(t.Ind,  {BackgroundColor3=nt.Accent})
        t.Page.ScrollBarImageColor3 = nt.Accent
    end
    self.TabList.ScrollBarImageColor3 = nt.Accent

    if self.DoSave then self.Store:Set("theme",name) end
end

function Oxygen:SetTitle(txt)    self._tLbl.Text=txt end
function Oxygen:SetSubtitle(txt) self._sLbl.Text=txt end
function Oxygen:SetWatermarkText(txt) if self._wmL then self._wmL.Text=txt end end

function Oxygen:GetThemeNames()
    local t={}; for k in pairs(Themes) do table.insert(t,k) end; table.sort(t); return t
end
function Oxygen:AddTheme(name,data) Themes[name]=data end

function Oxygen:Destroy()
    MT(self.Win,{Size=UDim2.fromOffset(0,0)})
    task.delay(0.35,function()
        for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
        if self.SG and self.SG.Parent then self.SG:Destroy() end
    end)
end

-- ════════════════════════════════════════════════════════════
--  COMPONENT API  (returned by AddTab)
-- ════════════════════════════════════════════════════════════
function Oxygen:_API(tabIdx, page, theme)
    local api = {}
    local win  = self

    -- helpers
    local function Card(h, clips)
        local c = G.Frame(page, theme.CardBg, UDim2.new(1,0,0,h or 38))
        c.ClipsDescendants=clips or false; c.ZIndex=7
        G.Corner(c, math.max(theme.Radius-2,3))
        G.Stroke(c, theme.Border, 1)
        -- register for theme propagation
        win:_TR(c, "BackgroundColor3", "CardBg")
        win:_TR(c:FindFirstChildWhichIsA("UIStroke"), "Color", "Border")
        return c
    end

    -- ────────────────────────────────────────────────────
    --  SECTION
    -- ────────────────────────────────────────────────────
    function api.Section(cfg)
        local f = G.Frame(page,Color3.new(0,0,0),UDim2.new(1,0,0,20))
        f.BackgroundTransparency=1; f.ZIndex=7
        local bar=G.Frame(f,theme.Accent,UDim2.fromOffset(3,13),UDim2.fromOffset(0,3),8); G.Corner(bar,2)
        win:_TR(bar,"BackgroundColor3","Accent")
        G.Label(f,(cfg.Title or ""):upper(),theme.TextMuted,UDim2.new(1,-12,1,0),UDim2.fromOffset(10,0),
            Enum.Font.GothamBold,10,Enum.TextXAlignment.Left,8)
        return f
    end

    -- ────────────────────────────────────────────────────
    --  SEPARATOR  (with optional centred text)
    -- ────────────────────────────────────────────────────
    function api.Separator(cfg)
        cfg=cfg or {}
        local f=G.Frame(page,Color3.new(0,0,0),UDim2.new(1,0,0,14))
        f.BackgroundTransparency=1; f.ZIndex=7
        G.Frame(f,theme.Border,UDim2.new(1,0,0,1),UDim2.fromOffset(0,6),8)
        if cfg.Text and cfg.Text~="" then
            local tw=TextService:GetTextSize(cfg.Text,10,Enum.Font.Gotham,Vector2.new(9999,9999)).X
            local bg=G.Frame(f,theme.Primary,UDim2.fromOffset(tw+12,14),UDim2.new(0.5,-(tw/2+6),0,0),9)
            win:_TR(bg,"BackgroundColor3","Primary")
            G.Label(bg,cfg.Text,theme.TextMuted,UDim2.fromScale(1,1),nil,Enum.Font.Gotham,10,Enum.TextXAlignment.Center,10)
        end
        return f
    end

    -- ────────────────────────────────────────────────────
    --  DIVIDER
    -- ────────────────────────────────────────────────────
    function api.Divider()
        local f=G.Frame(page,theme.Border,UDim2.new(1,0,0,1)); f.ZIndex=7; win:_TR(f,"BackgroundColor3","Border"); return f
    end

    -- ────────────────────────────────────────────────────
    --  LABEL
    -- ────────────────────────────────────────────────────
    function api.Label(cfg)
        local card=Card(28)
        local l=G.Label(card,cfg.Title or "",theme.TextMuted,UDim2.new(1,-16,1,0),UDim2.fromOffset(10,0),
            Enum.Font.Gotham,12,Enum.TextXAlignment.Left,8)
        l.TextWrapped=true; win:_TR(l,"TextColor3","TextMuted")
        local o={}
        function o:Set(t)  l.Text=t end
        function o:Get()   return l.Text end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  PARAGRAPH
    -- ────────────────────────────────────────────────────
    function api.Paragraph(cfg)
        local card=Card(58)
        local tl=G.Label(card,cfg.Title or "",theme.Text,UDim2.new(1,-16,0,16),UDim2.fromOffset(10,5),
            theme.FontTitle,13,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")
        local body=cfg.Content or ""
        local bl=G.Label(card,body,theme.TextMuted,UDim2.new(1,-16,0,36),UDim2.fromOffset(10,22),
            Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8); bl.TextWrapped=true; win:_TR(bl,"TextColor3","TextMuted")
        task.defer(function()
            if not bl.Parent then return end
            local bh=TextService:GetTextSize(body,11,Enum.Font.Gotham,Vector2.new(page.AbsoluteSize.X-30,9999)).Y
            card.Size=UDim2.new(1,0,0,math.max(bh+30,46))
        end)
        local o={}
        function o:SetTitle(t)   tl.Text=t end
        function o:SetContent(t) bl.Text=t end
        function o:Destroy()     card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  BUTTON
    -- ────────────────────────────────────────────────────
    function api.Button(cfg)
        local title=cfg.Title or "Button"; local desc=cfg.Description or ""
        local cb=cfg.Callback or function() end; local tip=cfg.Tooltip
        local h=desc~=""and 54 or 36; local card=Card(h,true)

        G.Label(card,title,theme.Text,UDim2.new(1,-80,0,18),UDim2.fromOffset(12,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8)
        if desc~="" then G.Label(card,desc,theme.TextMuted,UDim2.new(1,-80,0,14),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8) end

        local rb=G.ImageBtn(card,theme.Accent,UDim2.fromOffset(58,24),UDim2.new(1,-66,0.5,-12),9)
        win:_TR(rb,"ImageColor3","Accent"); G.Corner(rb,5)
        G.Label(rb,"RUN",theme.TextDark,UDim2.fromScale(1,1),nil,Enum.Font.GothamBold,11,Enum.TextXAlignment.Center,10)

        rb.MouseButton1Click:Connect(function() Util.Ripple(rb,theme.AccentDark); Util.Call(cb) end)
        rb.MouseEnter:Connect(function() FT(rb,{ImageColor3=theme.AccentDark}) end)
        rb.MouseLeave:Connect(function() FT(rb,{ImageColor3=theme.Accent}) end)
        if tip then MakeTooltip(card,tip,theme,win.SG) end

        local o={}; local enabled=true
        function o:SetEnabled(v)
            enabled=v
            FT(rb,{ImageColor3=v and theme.Accent or theme.Tertiary})
        end
        function o:Invoke() if enabled then Util.Call(cb) end end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  TOGGLE
    -- ────────────────────────────────────────────────────
    function api.Toggle(cfg)
        local title=cfg.Title or "Toggle"; local desc=cfg.Description or ""
        local def=cfg.Default or false; local cb=cfg.Callback or function() end
        local key=cfg.ConfigKey; local tip=cfg.Tooltip
        if key and win.DoSave then def=win.Store:Get(key,def) end
        local state=def

        local h=desc~=""and 54 or 36; local card=Card(h)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-72,0,18),UDim2.fromOffset(12,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8)
        win:_TR(tl,"TextColor3","Text")
        if desc~="" then
            local dl=G.Label(card,desc,theme.TextMuted,UDim2.new(1,-72,0,14),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8)
            win:_TR(dl,"TextColor3","TextMuted")
        end

        local track=G.Frame(card,state and theme.Toggle or theme.Tertiary,UDim2.fromOffset(34,16),UDim2.new(1,-42,0.5,-8),9); G.Corner(track,8)
        local knob=G.Frame(track,theme.Text,UDim2.fromOffset(10,10),state and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3),10); G.Corner(knob,5)
        win:_TR(knob,"BackgroundColor3","Text")

        local Changed = Signal.new()

        local function upd(v)
            state=v
            FT(track,{BackgroundColor3=v and theme.Toggle or theme.Tertiary})
            FT(knob, {Position=v and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3)})
            Util.Call(cb,v); Changed:Fire(v)
            if key and win.DoSave then win.Store:Set(key,v) end
        end

        task.defer(function() Util.Call(cb,state) end)

        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=11; hit.Parent=card
        hit.MouseButton1Click:Connect(function() upd(not state) end)
        if tip then MakeTooltip(card,tip,theme,win.SG) end

        local o={}
        function o:Set(v)     upd(v) end
        function o:Get()      return state end
        function o:SetTitle(t) tl.Text=t end
        o.Changed = Changed
        function o:Destroy()  card:Destroy(); Changed:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  SLIDER
    -- ────────────────────────────────────────────────────
    function api.Slider(cfg)
        local title=cfg.Title or "Slider"; local desc=cfg.Description or ""
        local mn=cfg.Min or 0; local mx=cfg.Max or 100
        local def=cfg.Default or mn; local prec=cfg.Precision or 0
        local suf=cfg.Suffix or ""; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then def=win.Store:Get(key,def) end
        def=math.clamp(def,mn,mx); local value=def

        local h=desc~=""and 66 or 52; local card=Card(h)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-84,0,18),UDim2.fromOffset(12,8),theme.Font,14,Enum.TextXAlignment.Left,8)
        win:_TR(tl,"TextColor3","Text")
        local vl=G.Label(card,tostring(def)..suf,theme.Accent,UDim2.fromOffset(72,18),UDim2.new(1,-80,0,8),Enum.Font.GothamBold,13,Enum.TextXAlignment.Right,8)
        win:_TR(vl,"TextColor3","Accent")
        if desc~="" then
            local dl=G.Label(card,desc,theme.TextMuted,UDim2.new(1,-20,0,13),UDim2.fromOffset(12,26),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8)
            win:_TR(dl,"TextColor3","TextMuted")
        end

        local ty=desc~=""and 48 or 34
        local track=G.Frame(card,theme.Tertiary,UDim2.new(1,-24,0,4),UDim2.fromOffset(12,ty),8); G.Corner(track,2); win:_TR(track,"BackgroundColor3","Tertiary")
        local ds=(def-mn)/math.max(mx-mn,0.001)
        local fill=G.Frame(track,theme.Slider,UDim2.fromScale(ds,1),nil,9); G.Corner(fill,2); win:_TR(fill,"BackgroundColor3","Slider")
        local knob=G.Frame(track,theme.Text,UDim2.fromOffset(14,14),UDim2.new(ds,-7,0.5,-7),10); G.Corner(knob,7)
        local ks=G.Stroke(knob,theme.Slider,2); win:_TR(ks,"Color","Slider"); win:_TR(knob,"BackgroundColor3","Text")

        local dragging=false; local Changed=Signal.new()
        local function upd(scale)
            scale=math.clamp(scale,0,1)
            local m=10^prec; local v=math.floor((mn+(mx-mn)*scale)*m+0.5)/m
            value=v; FT(fill,{Size=UDim2.fromScale(scale,1)}); FT(knob,{Position=UDim2.new(scale,-7,0.5,-7)})
            vl.Text=tostring(v)..suf; Util.Call(cb,v); Changed:Fire(v)
            if key and win.DoSave then win.Store:Set(key,v) end
        end
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=12; hit.Parent=track
        hit.MouseButton1Down:Connect(function() dragging=true; upd(Util.GetXY(track)) end)
        win:_C(UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then upd(Util.GetXY(track)) end
        end))
        win:_C(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end))
        task.defer(function() Util.Call(cb,value) end)

        local o={}
        function o:Set(v) v=math.clamp(v,mn,mx); upd((v-mn)/math.max(mx-mn,0.001)) end
        function o:Get()       return value end
        function o:SetMin(v)   mn=v end
        function o:SetMax(v)   mx=v end
        function o:SetTitle(t) tl.Text=t end
        o.Changed=Changed
        function o:Destroy() card:Destroy(); Changed:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  DROPDOWN
    -- ────────────────────────────────────────────────────
    function api.Dropdown(cfg)
        local title=cfg.Title or "Dropdown"; local desc=cfg.Description or ""
        local opts=cfg.Options or {}; local def=cfg.Default; local multi=cfg.Multi or false
        local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then def=win.Store:Get(key,def) end
        local sel=multi and {} or def; local open=false
        local bh=desc~=""and 54 or 40; local card=Card(bh); card.ZIndex=22

        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-22,0,18),UDim2.fromOffset(12,desc~=""and 8 or 11),theme.Font,14,Enum.TextXAlignment.Left,23)
        win:_TR(tl,"TextColor3","Text")
        if desc~="" then
            local dl=G.Label(card,desc,theme.TextMuted,UDim2.new(1,-22,0,13),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,23)
            win:_TR(dl,"TextColor3","TextMuted")
        end
        local curL=G.Label(card,def and tostring(def) or "Select…",theme.Accent,UDim2.new(1,-32,0,16),
            UDim2.new(0,12,1,desc~=""and -24 or -26),Enum.Font.Gotham,12,Enum.TextXAlignment.Left,23)
        win:_TR(curL,"TextColor3","Accent")
        local arrow=G.Label(card,"▾",theme.TextMuted,UDim2.fromOffset(18,18),UDim2.new(1,-24,0.5,-9),Enum.Font.GothamBold,13,Enum.TextXAlignment.Center,23)

        local panH=math.min(#opts*26+38,196)
        local panel=G.Frame(card,theme.Secondary,UDim2.new(1,0,0,0),UDim2.new(0,0,1,4),50,true)
        G.Corner(panel,6); G.Stroke(panel,theme.Border,1); G.Shadow(panel,theme.Shadow,50)
        win:_TR(panel,"BackgroundColor3","Secondary")

        local sb=Instance.new("TextBox"); sb.BackgroundColor3=theme.Tertiary; sb.BorderSizePixel=0
        sb.Size=UDim2.new(1,-8,0,24); sb.Position=UDim2.fromOffset(4,4)
        sb.PlaceholderText="🔍 Search…"; sb.PlaceholderColor3=theme.TextMuted; sb.Text=""
        sb.TextColor3=theme.Text; sb.Font=Enum.Font.Gotham; sb.TextSize=12; sb.ClearTextOnFocus=false
        sb.ZIndex=51; sb.Parent=panel; G.Corner(sb,4); G.Pad(sb,0,6,0,6)
        win:_TR(sb,"BackgroundColor3","Tertiary"); win:_TR(sb,"TextColor3","Text")

        local sc=G.ScrollFrame(panel,UDim2.new(1,0,1,-32),UDim2.fromOffset(0,30),51)
        sc.ScrollBarImageColor3=theme.Accent; win:_TR(sc,"ScrollBarImageColor3","Accent")
        G.Pad(sc,2,4,2,4); local sl=G.List(sc,nil,nil,nil,2); G.AutoCanvas(sc,sl,4)

        local obs={}
        local function rebuild(filter)
            for _,b in ipairs(obs) do b:Destroy() end; obs={}
            for _,opt in ipairs(opts) do
                local os=tostring(opt)
                if filter=="" or os:lower():find(filter:lower(),1,true) then
                    local isSel=multi and Util.Has(sel,opt) or (sel==opt)
                    local ob=Instance.new("TextButton")
                    ob.BackgroundColor3=isSel and theme.Accent or theme.Tertiary; ob.BorderSizePixel=0
                    ob.Size=UDim2.new(1,0,0,24); ob.Text=""; ob.ZIndex=52; ob.Parent=sc; G.Corner(ob,4)
                    local ol=G.Label(ob,os,isSel and theme.TextDark or theme.Text,UDim2.new(1,-8,1,0),UDim2.fromOffset(6,0),Enum.Font.Gotham,12,Enum.TextXAlignment.Left,53)
                    ob.MouseButton1Click:Connect(function()
                        if multi then
                            if Util.Has(sel,opt) then for i,v in ipairs(sel) do if v==opt then table.remove(sel,i); break end end
                            else table.insert(sel,opt) end
                            curL.Text=#sel>0 and table.concat(sel,", ") or "Select…"; Util.Call(cb,sel)
                        else
                            sel=opt; curL.Text=os; Util.Call(cb,opt)
                            open=false; FT(panel,{Size=UDim2.new(1,0,0,0)}); FT(arrow,{Rotation=0})
                        end
                        if key and win.DoSave then win.Store:Set(key,sel) end; rebuild(sb.Text)
                    end)
                    ob.MouseEnter:Connect(function() if not(not multi and sel==opt) then FT(ob,{BackgroundColor3=theme.Accent}); FT(ol,{TextColor3=theme.TextDark}) end end)
                    ob.MouseLeave:Connect(function() local is2=multi and Util.Has(sel,opt) or (sel==opt); FT(ob,{BackgroundColor3=is2 and theme.Accent or theme.Tertiary}); FT(ol,{TextColor3=is2 and theme.TextDark or theme.Text}) end)
                    table.insert(obs,ob)
                end
            end
        end
        rebuild("")
        sb:GetPropertyChangedSignal("Text"):Connect(function() rebuild(sb.Text) end)
        task.defer(function()
            local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.new(1,0,0,bh); hit.Text=""; hit.ZIndex=24; hit.Parent=card
            hit.MouseButton1Click:Connect(function()
                open=not open; FT(panel,{Size=UDim2.new(1,0,0,open and panH or 0)}); FT(arrow,{Rotation=open and 180 or 0})
                if open then sb:CaptureFocus() end
            end)
        end)

        local o={}
        function o:Set(v)         sel=v; curL.Text=tostring(v) end
        function o:Get()          return sel end
        function o:SetOptions(v)  opts=v; rebuild(sb.Text) end
        function o:AddOption(v)   table.insert(opts,v); rebuild(sb.Text) end
        function o:RemoveOption(v)
            for i,x in ipairs(opts) do if x==v then table.remove(opts,i); break end end; rebuild(sb.Text)
        end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  KEYBIND
    -- ────────────────────────────────────────────────────
    function api.Keybind(cfg)
        local title=cfg.Title or "Keybind"; local desc=cfg.Description or ""
        local def=cfg.Default or Enum.KeyCode.Unknown; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        local bound=def; local listening=false

        local h=desc~=""and 54 or 36; local card=Card(h)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-104,0,18),UDim2.fromOffset(12,desc~=""and 8 or 9),theme.Font,14,Enum.TextXAlignment.Left,8)
        win:_TR(tl,"TextColor3","Text")
        if desc~="" then
            local dl=G.Label(card,desc,theme.TextMuted,UDim2.new(1,-104,0,13),UDim2.fromOffset(12,28),Enum.Font.Gotham,11,Enum.TextXAlignment.Left,8)
            win:_TR(dl,"TextColor3","TextMuted")
        end
        local kb=Instance.new("TextButton"); kb.BackgroundColor3=theme.Tertiary; kb.BorderSizePixel=0
        kb.Size=UDim2.fromOffset(90,22); kb.Position=UDim2.new(1,-98,0.5,-11); kb.Text=bound.Name
        kb.TextColor3=theme.Accent; kb.Font=Enum.Font.GothamBold; kb.TextSize=11; kb.ZIndex=9; kb.Parent=card
        G.Corner(kb,5); G.Stroke(kb,theme.Border,1)
        win:_TR(kb,"BackgroundColor3","Tertiary"); win:_TR(kb,"TextColor3","Accent")

        kb.MouseButton1Click:Connect(function() listening=true; kb.Text="…"; kb.TextColor3=theme.Warning end)
        win:_C(UserInputService.InputBegan:Connect(function(i,gp)
            if not listening then return end
            if i.UserInputType==Enum.UserInputType.Keyboard then
                bound=i.KeyCode; kb.Text=bound.Name; kb.TextColor3=theme.Accent; listening=false
                Util.Call(cb,bound); if key and win.DoSave then win.Store:Set(key,bound.Name) end
            end
        end))

        local o={}
        function o:Get()    return bound end
        function o:Set(kc)  bound=kc; kb.Text=kc.Name end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  TEXT INPUT
    -- ────────────────────────────────────────────────────
    function api.TextInput(cfg)
        local title=cfg.Title or "Input"; local desc=cfg.Description or ""
        local ph=cfg.Placeholder or "Type here…"; local def=cfg.Default or ""
        local cb=cfg.Callback or function() end; local num=cfg.Numeric or false
        local maxL=cfg.MaxLength or 200; local key=cfg.ConfigKey; local tip=cfg.Tooltip
        if key and win.DoSave then def=win.Store:Get(key,def) end

        local h=desc~=""and 72 or 58; local card=Card(h)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-16,0,15),UDim2.fromOffset(12,5),theme.Font,13,Enum.TextXAlignment.Left,8)
        win:_TR(tl,"TextColor3","Text")
        if desc~="" then
            local dl=G.Label(card,desc,theme.TextMuted,UDim2.new(1,-16,0,12),UDim2.fromOffset(12,20),Enum.Font.Gotham,10,Enum.TextXAlignment.Left,8)
            win:_TR(dl,"TextColor3","TextMuted")
        end
        local iy=desc~=""and 38 or 26
        local iF=G.Frame(card,theme.Tertiary,UDim2.new(1,-16,0,24),UDim2.fromOffset(8,iy),8); G.Corner(iF,5)
        local iS=G.Stroke(iF,theme.Border,1)
        win:_TR(iF,"BackgroundColor3","Tertiary"); win:_TR(iS,"Color","Border")

        local box=Instance.new("TextBox"); box.BackgroundTransparency=1; box.Size=UDim2.new(1,-8,1,0); box.Position=UDim2.fromOffset(6,0)
        box.Text=def; box.PlaceholderText=ph; box.PlaceholderColor3=theme.TextMuted; box.TextColor3=theme.Text
        box.Font=Enum.Font.Gotham; box.TextSize=12; box.ClearTextOnFocus=false; box.ZIndex=9; box.Parent=iF
        win:_TR(box,"TextColor3","Text"); win:_TR(box,"PlaceholderColor3","TextMuted")

        local counter=G.Label(iF,"0/"..maxL,theme.TextMuted,UDim2.fromOffset(42,18),UDim2.new(1,-48,0,3),Enum.Font.Gotham,9,Enum.TextXAlignment.Right,9)
        win:_TR(counter,"TextColor3","TextMuted")

        box:GetPropertyChangedSignal("Text"):Connect(function()
            if num then box.Text=box.Text:gsub("[^%d%.%-]","") end
            if #box.Text>maxL then box.Text=box.Text:sub(1,maxL) end
            counter.Text=#box.Text.."/"..maxL
        end)
        box.Focused:Connect(function()
            FT(iF,{BackgroundColor3=Util.Lerp(theme.Tertiary,theme.Accent,0.13)}); iS.Color=theme.Accent
        end)
        box.FocusLost:Connect(function(enter)
            FT(iF,{BackgroundColor3=theme.Tertiary}); iS.Color=theme.Border
            if enter then Util.Call(cb,box.Text); if key and win.DoSave then win.Store:Set(key,box.Text) end end
        end)
        if tip then MakeTooltip(card,tip,theme,win.SG) end

        local o={}
        function o:Get()    return box.Text end
        function o:Set(t)   box.Text=t end
        function o:Clear()  box.Text="" end
        function o:Focus()  box:CaptureFocus() end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  SEARCH BOX  (TextInput variant with live callback)
    -- ────────────────────────────────────────────────────
    function api.SearchBox(cfg)
        local title=cfg.Title or "Search"; local ph=cfg.Placeholder or "🔍 Search…"
        local cb=cfg.Callback or function() end

        local card=Card(40)
        local iF=G.Frame(card,theme.Tertiary,UDim2.new(1,-16,0,28),UDim2.fromOffset(8,6),8); G.Corner(iF,6)
        local iS=G.Stroke(iF,theme.Border,1)
        win:_TR(iF,"BackgroundColor3","Tertiary"); win:_TR(iS,"Color","Border")

        local icon=G.Label(iF,"🔍",theme.TextMuted,UDim2.fromOffset(22,28),UDim2.fromOffset(4,0),Enum.Font.Gotham,13,Enum.TextXAlignment.Center,9)
        win:_TR(icon,"TextColor3","TextMuted")

        local box=Instance.new("TextBox"); box.BackgroundTransparency=1; box.Size=UDim2.new(1,-32,1,0); box.Position=UDim2.fromOffset(26,0)
        box.PlaceholderText=ph; box.PlaceholderColor3=theme.TextMuted; box.Text=""
        box.TextColor3=theme.Text; box.Font=Enum.Font.Gotham; box.TextSize=13; box.ClearTextOnFocus=false; box.ZIndex=9; box.Parent=iF
        win:_TR(box,"TextColor3","Text")

        -- clear button
        local clr=Instance.new("TextButton"); clr.BackgroundTransparency=1; clr.Size=UDim2.fromOffset(22,22); clr.Position=UDim2.new(1,-24,0,3)
        clr.Text="×"; clr.TextColor3=theme.TextMuted; clr.Font=Enum.Font.GothamBold; clr.TextSize=16; clr.ZIndex=10; clr.Parent=iF; clr.Visible=false
        clr.MouseButton1Click:Connect(function() box.Text=""; Util.Call(cb,"") end)

        box:GetPropertyChangedSignal("Text"):Connect(function()
            clr.Visible=box.Text~=""
            Util.Call(cb, box.Text)
        end)
        box.Focused:Connect(function() FT(iF,{BackgroundColor3=Util.Lerp(theme.Tertiary,theme.Accent,0.11)}); iS.Color=theme.Accent end)
        box.FocusLost:Connect(function() FT(iF,{BackgroundColor3=theme.Tertiary}); iS.Color=theme.Border end)

        local o={}
        function o:Get()    return box.Text end
        function o:Set(t)   box.Text=t end
        function o:Clear()  box.Text="" end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  COLOR PICKER
    -- ────────────────────────────────────────────────────
    function api.ColorPicker(cfg)
        local title=cfg.Title or "Color"; local def=cfg.Default or Color3.fromRGB(120,80,255)
        local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then
            local hexSaved=win.Store:Get(key,nil)
            if hexSaved then def=Util.FromHex(hexSaved) or def end
        end

        local h,s,v=Color3.toHSV(def); local open=false
        local card=Card(36); card.ClipsDescendants=false
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-62,1,0),UDim2.fromOffset(12,0),theme.Font,14,Enum.TextXAlignment.Left,8)
        win:_TR(tl,"TextColor3","Text")

        local prev=G.Frame(card,def,UDim2.fromOffset(48,20),UDim2.new(1,-56,0.5,-10),9); G.Corner(prev,4); G.Stroke(prev,theme.Border,1)
        local hexL=G.Label(prev,Util.Hex(def),Util.Contrast(def),UDim2.fromScale(1,1),nil,Enum.Font.Code,9,Enum.TextXAlignment.Center,10)

        local pp=G.Frame(card,theme.Secondary,UDim2.new(1,0,0,0),UDim2.new(0,0,1,4),30,true); G.Corner(pp,6); G.Stroke(pp,theme.Border,1); G.Shadow(pp,theme.Shadow,30)
        win:_TR(pp,"BackgroundColor3","Secondary")

        local function updC()
            local col=Color3.fromHSV(h,s,v); prev.BackgroundColor3=col; hexL.TextColor3=Util.Contrast(col); hexL.Text=Util.Hex(col)
            Util.Call(cb,col); if key and win.DoSave then win.Store:Set(key,Util.Hex(col)) end
        end

        local svSq=Instance.new("ImageLabel"); svSq.BackgroundColor3=Color3.fromHSV(h,1,1); svSq.BorderSizePixel=0; svSq.Size=UDim2.new(1,-16,0,100); svSq.Position=UDim2.fromOffset(8,8); svSq.Image="rbxassetid://4155801252"; svSq.ZIndex=31; svSq.Parent=pp; G.Corner(svSq,4)
        local hBar=Instance.new("ImageLabel"); hBar.BackgroundColor3=Color3.new(1,0,0); hBar.BorderSizePixel=0; hBar.Size=UDim2.new(1,-16,0,12); hBar.Position=UDim2.fromOffset(8,116); hBar.Image="rbxassetid://698052001"; hBar.ZIndex=31; hBar.Parent=pp; G.Corner(hBar,3)

        -- opacity strip (alpha preview)
        local opFrame=G.Frame(pp,theme.Tertiary,UDim2.new(1,-16,0,10),UDim2.fromOffset(8,136),31); G.Corner(opFrame,3)
        local opFill=G.Frame(opFrame,Color3.fromHSV(h,s,v),UDim2.fromScale(1,1),nil,32); G.Corner(opFill,3)

        local hBox=Instance.new("TextBox"); hBox.BackgroundColor3=theme.Tertiary; hBox.BorderSizePixel=0; hBox.Size=UDim2.new(1,-16,0,22); hBox.Position=UDim2.fromOffset(8,154); hBox.Text=Util.Hex(def); hBox.PlaceholderText="#FFFFFF"; hBox.PlaceholderColor3=theme.TextMuted; hBox.TextColor3=theme.Text; hBox.Font=Enum.Font.Code; hBox.TextSize=12; hBox.ClearTextOnFocus=false; hBox.ZIndex=31; hBox.Parent=pp; G.Corner(hBox,4)
        win:_TR(hBox,"BackgroundColor3","Tertiary"); win:_TR(hBox,"TextColor3","Text")

        local svK=G.Frame(svSq,Color3.new(1,1,1),UDim2.fromOffset(10,10),nil,32); G.Corner(svK,5); G.Stroke(svK,Color3.new(1,1,1),1)
        local hK=G.Frame(hBar,Color3.new(1,1,1),UDim2.fromOffset(4,14),nil,32); G.Corner(hK,2)

        local function refK() svK.Position=UDim2.new(s,-5,1-v,-5); hK.Position=UDim2.new(1-h,-2,0,-1); svSq.BackgroundColor3=Color3.fromHSV(h,1,1); opFill.BackgroundColor3=Color3.fromHSV(h,s,v) end
        refK()

        local svDrag=false
        local svH=Instance.new("TextButton"); svH.BackgroundTransparency=1; svH.Size=UDim2.fromScale(1,1); svH.Text=""; svH.ZIndex=33; svH.Parent=svSq
        svH.MouseButton1Down:Connect(function() svDrag=true; local px,py=Util.GetXY(svSq); s,v=math.clamp(px,0,1),math.clamp(1-py,0,1); refK(); updC() end)
        win:_C(UserInputService.InputChanged:Connect(function(i)
            if svDrag and i.UserInputType==Enum.UserInputType.MouseMovement then local px,py=Util.GetXY(svSq); s,v=math.clamp(px,0,1),math.clamp(1-py,0,1); refK(); updC() end
        end))
        win:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=false end end))

        local hDrag=false
        local hH=Instance.new("TextButton"); hH.BackgroundTransparency=1; hH.Size=UDim2.fromScale(1,1); hH.Text=""; hH.ZIndex=33; hH.Parent=hBar
        hH.MouseButton1Down:Connect(function() hDrag=true; local px=Util.GetXY(hBar); h=math.clamp(1-px,0,1); refK(); updC() end)
        win:_C(UserInputService.InputChanged:Connect(function(i)
            if hDrag and i.UserInputType==Enum.UserInputType.MouseMovement then local px=Util.GetXY(hBar); h=math.clamp(1-px,0,1); refK(); updC() end
        end))
        win:_C(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hDrag=false end end))

        hBox.FocusLost:Connect(function() local col=Util.FromHex(hBox.Text); if col then h,s,v=Color3.toHSV(col); refK(); updC() end end)

        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.ZIndex=10; hit.Parent=card
        hit.MouseButton1Click:Connect(function() open=not open; FT(pp,{Size=UDim2.new(1,0,0,open and 184 or 0)}) end)

        local o={}
        function o:Get()    return Color3.fromHSV(h,s,v) end
        function o:Set(col) h,s,v=Color3.toHSV(col); refK(); updC() end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  PROGRESS BAR
    -- ────────────────────────────────────────────────────
    function api.ProgressBar(cfg)
        local title=cfg.Title or "Progress"; local init=cfg.Value or 0; local mx=cfg.Max or 100; local suf=cfg.Suffix or "%"
        local card=Card(46)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-72,0,16),UDim2.fromOffset(12,6),theme.Font,13,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")
        local vl=G.Label(card,tostring(init)..suf,theme.Accent,UDim2.fromOffset(64,16),UDim2.new(1,-70,0,6),Enum.Font.GothamBold,12,Enum.TextXAlignment.Right,8); win:_TR(vl,"TextColor3","Accent")
        local track=G.Frame(card,theme.Tertiary,UDim2.new(1,-16,0,6),UDim2.fromOffset(8,30),8); G.Corner(track,3); win:_TR(track,"BackgroundColor3","Tertiary")
        local fill=G.Frame(track,theme.Accent,UDim2.fromScale(math.clamp(init/math.max(mx,.001),0,1),1),nil,9); G.Corner(fill,3); win:_TR(fill,"BackgroundColor3","Accent")
        local shim=G.Frame(fill,Color3.new(1,1,1),UDim2.fromOffset(24,6),nil,10); shim.BackgroundTransparency=0.72; G.Corner(shim,3)
        task.spawn(function()
            while fill and fill.Parent do
                shim.Position=UDim2.fromScale(-0.3,0)
                Tween(shim,TweenInfo.new(1.2,Enum.EasingStyle.Sine),{Position=UDim2.fromScale(1.3,0)})
                task.wait(2)
            end
        end)
        local o={}
        function o:Set(val)
            local sc=math.clamp(val/math.max(mx,.001),0,1)
            MT(fill,{Size=UDim2.fromScale(sc,1)}); vl.Text=tostring(Util.Round(val,1))..suf
        end
        function o:SetMax(m) mx=m end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  STEPPER
    -- ────────────────────────────────────────────────────
    function api.Stepper(cfg)
        local title=cfg.Title or "Stepper"; local mn=cfg.Min or 0; local mx=cfg.Max or 10
        local def=cfg.Default or mn; local step=cfg.Step or 1; local cb=cfg.Callback or function() end; local key=cfg.ConfigKey
        if key and win.DoSave then def=win.Store:Get(key,def) end
        local value=math.clamp(def,mn,mx); local card=Card(36)
        local tl=G.Label(card,title,theme.Text,UDim2.new(1,-118,1,0),UDim2.fromOffset(12,0),theme.Font,14,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")

        local function mkB(sym,xo)
            local b=Instance.new("TextButton"); b.BackgroundColor3=theme.Tertiary; b.BorderSizePixel=0
            b.Size=UDim2.fromOffset(26,22); b.Position=UDim2.new(1,xo,0.5,-11)
            b.Text=sym; b.TextColor3=theme.Accent; b.Font=Enum.Font.GothamBold; b.TextSize=16; b.ZIndex=9; b.Parent=card; G.Corner(b,5)
            win:_TR(b,"BackgroundColor3","Tertiary"); win:_TR(b,"TextColor3","Accent")
            b.MouseEnter:Connect(function() FT(b,{BackgroundColor3=theme.Accent}); b.TextColor3=theme.TextDark end)
            b.MouseLeave:Connect(function() FT(b,{BackgroundColor3=theme.Tertiary}); b.TextColor3=theme.Accent end)
            return b
        end
        local minus=mkB("−",-108)
        local vl=G.Label(card,tostring(value),theme.Text,UDim2.fromOffset(50,22),UDim2.new(1,-80,0.5,-11),Enum.Font.GothamBold,14,Enum.TextXAlignment.Center,9); win:_TR(vl,"TextColor3","Text")
        local plus=mkB("+", -30)
        local function upd(v) value=math.clamp(v,mn,mx); vl.Text=tostring(value); Util.Call(cb,value); if key and win.DoSave then win.Store:Set(key,value) end end
        minus.MouseButton1Click:Connect(function() upd(value-step) end)
        plus.MouseButton1Click:Connect(function()  upd(value+step) end)
        local o={}
        function o:Get() return value end; function o:Set(v) upd(v) end; function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  RADIO GROUP
    -- ────────────────────────────────────────────────────
    function api.RadioGroup(cfg)
        local title=cfg.Title or "Choose"; local opts=cfg.Options or {}; local def=cfg.Default or opts[1]; local cb=cfg.Callback or function() end
        local sel=def; local h=26+#opts*30; local card=Card(h)
        G.Label(card,title,theme.TextMuted,UDim2.new(1,-16,0,20),UDim2.fromOffset(12,3),Enum.Font.GothamBold,10,Enum.TextXAlignment.Left,8)
        local rbs={}
        for i,opt in ipairs(opts) do
            local row=Instance.new("TextButton"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,-16,0,26); row.Position=UDim2.fromOffset(8,18+(i-1)*28); row.Text=""; row.ZIndex=9; row.Parent=card
            local ring=G.Frame(row,Color3.new(0,0,0),UDim2.fromOffset(16,16),UDim2.fromOffset(4,5),10); ring.BackgroundTransparency=1; G.Corner(ring,8)
            local rs=G.Stroke(ring,opt==def and theme.Accent or theme.Border,2); win:_TR(rs,"Color", opt==def and "Accent" or "Border")
            local dot=G.Frame(ring,theme.Accent,UDim2.fromOffset(opt==def and 8 or 0, opt==def and 8 or 0),UDim2.fromOffset(opt==def and 4 or 8, opt==def and 4 or 8),11); G.Corner(dot,4); win:_TR(dot,"BackgroundColor3","Accent")
            local lbl=G.Label(row,tostring(opt),opt==def and theme.Text or theme.TextMuted,UDim2.new(1,-26,1,0),UDim2.fromOffset(24,0),Enum.Font.Gotham,13,Enum.TextXAlignment.Left,10)
            table.insert(rbs,{ring=ring,rs=rs,dot=dot,lbl=lbl,opt=opt})
            row.MouseButton1Click:Connect(function()
                sel=opt
                for _,rb in ipairs(rbs) do
                    local a=rb.opt==opt
                    rb.rs.Color=a and theme.Accent or theme.Border
                    FT(rb.dot,{Size=a and UDim2.fromOffset(8,8) or UDim2.fromOffset(0,0), Position=a and UDim2.fromOffset(4,4) or UDim2.fromOffset(8,8)})
                    FT(rb.lbl,{TextColor3=a and theme.Text or theme.TextMuted})
                end
                Util.Call(cb,opt)
            end)
        end
        local o={}; function o:Get() return sel end; function o:Destroy() card:Destroy() end; return o
    end

    -- ────────────────────────────────────────────────────
    --  ACCORDION  (collapsible section)
    -- ────────────────────────────────────────────────────
    function api.Accordion(cfg)
        local title=cfg.Title or "Expand"; local open=cfg.Open or false
        local headerH=36; local card=Card(headerH,true)

        local hRow=G.Frame(card,Color3.new(0,0,0),UDim2.new(1,0,0,headerH)); hRow.BackgroundTransparency=1; hRow.ZIndex=8
        G.Label(hRow,title,theme.Text,UDim2.new(1,-40,1,0),UDim2.fromOffset(12,0),theme.FontTitle,13,Enum.TextXAlignment.Left,9)
        local chevron=G.Label(hRow,open and "▲" or "▼",theme.TextMuted,UDim2.fromOffset(22,22),UDim2.new(1,-28,0.5,-11),Enum.Font.GothamBold,12,Enum.TextXAlignment.Center,9)
        win:_TR(chevron,"TextColor3","TextMuted")

        -- inner content frame
        local inner=G.Frame(card,theme.Primary,UDim2.new(1,-8,0,0),UDim2.fromOffset(4,headerH+2),8); inner.ClipsDescendants=true
        win:_TR(inner,"BackgroundColor3","Primary")
        G.Pad(inner,4,4,4,4)
        local il=G.List(inner,nil,nil,nil,5)
        local contentH=0
        il:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            contentH=il.AbsoluteContentSize.Y+14
            if open then card.Size=UDim2.new(1,0,0,headerH+contentH); inner.Size=UDim2.new(1,-8,0,contentH) end
        end)

        local function toggle()
            open=not open; chevron.Text=open and "▲" or "▼"
            if open then
                card.Size=UDim2.new(1,0,0,headerH+contentH); inner.Size=UDim2.new(1,-8,0,contentH)
            else
                FT(card,{Size=UDim2.new(1,0,0,headerH)}); FT(inner,{Size=UDim2.new(1,-8,0,0)})
            end
        end

        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Size=UDim2.fromOffset(0,headerH); hit.Size=UDim2.new(1,0,0,headerH); hit.Text=""; hit.ZIndex=10; hit.Parent=card
        hit.MouseButton1Click:Connect(toggle)

        -- return an API that lets you add child components inside the accordion
        local innerAPI = win:_API(tabIdx, inner, theme)
        local o = {}
        for k,v in pairs(innerAPI) do o[k]=v end  -- expose all component builders
        function o:Toggle() toggle() end
        function o:IsOpen() return open end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  BADGE / CHIP LIST
    -- ────────────────────────────────────────────────────
    function api.Badge(cfg)
        local items=cfg.Items or {}; local card=Card(36)
        local cont=G.Frame(card,Color3.new(0,0,0),UDim2.fromScale(1,1)); cont.BackgroundTransparency=1; cont.ZIndex=8
        G.Pad(cont,6,6,6,8); G.List(cont,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center,4)
        for _,item in ipairs(items) do
            local col=item.Color or theme.Accent
            local chip=G.Frame(cont,col,UDim2.fromOffset(0,20)); chip.AutomaticSize=Enum.AutomaticSize.X; chip.ZIndex=9; G.Corner(chip,10); G.Pad(chip,3,8,3,8)
            local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.AutomaticSize=Enum.AutomaticSize.X; l.Size=UDim2.fromScale(1,1); l.Text=tostring(item.Text or ""); l.TextColor3=item.TextColor or Util.Contrast(col); l.Font=Enum.Font.GothamBold; l.TextSize=11; l.ZIndex=10; l.Parent=chip
        end
        return card
    end

    -- ────────────────────────────────────────────────────
    --  IMAGE
    -- ────────────────────────────────────────────────────
    function api.Image(cfg)
        local id=cfg.ID or ""; local height=cfg.Height or 120; local cap=cfg.Caption or ""
        local card=Card(height+(cap~=""and 28 or 8))
        local img=Instance.new("ImageLabel"); img.BackgroundTransparency=1; img.Size=UDim2.new(1,-16,0,height); img.Position=UDim2.fromOffset(8,4); img.Image="rbxassetid://"..id; img.ScaleType=Enum.ScaleType.Fit; img.ZIndex=8; img.Parent=card; G.Corner(img,4)
        if cap~="" then G.Label(card,cap,theme.TextMuted,UDim2.new(1,-16,0,20),UDim2.fromOffset(8,height+6),Enum.Font.Gotham,11,Enum.TextXAlignment.Center,8) end
        local o={}
        function o:SetImage(i) img.Image="rbxassetid://"..i end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  STATUS INDICATOR  (small coloured dot + text)
    -- ────────────────────────────────────────────────────
    function api.StatusIndicator(cfg)
        local label=cfg.Label or "Status"; local status=cfg.Status or "idle"
        -- status can be: "online","offline","warning","idle","custom"
        local STATUS_COLORS={online=Color3.fromRGB(48,208,108), offline=Color3.fromRGB(120,120,120), warning=Color3.fromRGB(235,168,26), idle=Color3.fromRGB(240,160,30), error=Color3.fromRGB(232,55,72)}
        local col=STATUS_COLORS[status] or cfg.Color or theme.Accent

        local card=Card(32)
        local dot=G.Frame(card,col,UDim2.fromOffset(10,10),UDim2.fromOffset(12,11),9); G.Corner(dot,5)
        -- pulse
        task.spawn(function()
            while dot and dot.Parent do
                FT(dot,{BackgroundTransparency=0.55}); task.wait(0.8); FT(dot,{BackgroundTransparency=0}); task.wait(0.8)
            end
        end)
        local tl=G.Label(card,label,theme.Text,UDim2.new(1,-30,1,0),UDim2.fromOffset(28,0),theme.Font,13,Enum.TextXAlignment.Left,8); win:_TR(tl,"TextColor3","Text")
        local sl=G.Label(card,status,theme.TextMuted,UDim2.fromOffset(80,1),UDim2.new(1,-86,0.5,-6),Enum.Font.Gotham,11,Enum.TextXAlignment.Right,9); win:_TR(sl,"TextColor3","TextMuted")

        local o={}
        function o:SetStatus(s,c)
            status=s; col=STATUS_COLORS[s] or c or theme.Accent
            FT(dot,{BackgroundColor3=col}); sl.Text=s
        end
        function o:SetLabel(t) tl.Text=t end
        function o:Destroy() card:Destroy() end
        return o
    end

    -- ────────────────────────────────────────────────────
    --  TABLE  (data grid)
    -- ────────────────────────────────────────────────────
    function api.Table(cfg)
        local headers=cfg.Headers or {}; local rows=cfg.Rows or {}
        local cols=#headers; if cols==0 then return end
        local rowH=28; local headerH=30
        local totalH=headerH + #rows*rowH + 10
        local card=Card(math.min(totalH,260),true)

        -- header row
        local hRow=G.Frame(card,theme.Tertiary,UDim2.new(1,-4,0,headerH),UDim2.fromOffset(2,2),8)
        win:_TR(hRow,"BackgroundColor3","Tertiary"); G.Corner(hRow,4)
        for ci,hdr in ipairs(headers) do
            G.Label(hRow,tostring(hdr),theme.Accent,UDim2.fromScale(1/cols,1),UDim2.fromScale((ci-1)/cols,0),Enum.Font.GothamBold,11,Enum.TextXAlignment.Center,9)
        end

        local scroll=G.ScrollFrame(card,UDim2.new(1,-4,1,-(headerH+4)),UDim2.fromOffset(2,headerH+2),8)
        scroll.ScrollBarImageColor3=theme.Accent; win:_TR(scroll,"ScrollBarImageColor3","Accent")
        local rl=G.List(scroll,nil,nil,nil,1); G.AutoCanvas(scroll,rl,4)

        for ri,row in ipairs(rows) do
            local rFrame=G.Frame(scroll,ri%2==0 and theme.Primary or theme.Secondary,UDim2.new(1,0,0,rowH)); win:_TR(rFrame,"BackgroundColor3",ri%2==0 and "Primary" or "Secondary")
            for ci,cell in ipairs(row) do
                G.Label(rFrame,tostring(cell),theme.Text,UDim2.fromScale(1/cols,1),UDim2.fromScale((ci-1)/cols,0),Enum.Font.Gotham,11,Enum.TextXAlignment.Center,9); win:_TR(G.Label(rFrame,"",theme.Text,UDim2.fromScale(0,0)),"TextColor3","Text")
            end
        end

        local o={}; function o:Destroy() card:Destroy() end; return o
    end

    return api
end

return Oxygen
