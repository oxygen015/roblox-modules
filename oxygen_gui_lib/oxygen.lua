--[[
    ██████╗ ██╗  ██╗██╗   ██╗ ██████╗ ███████╗███╗   ██╗
   ██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝██╔════╝ ██╔════╝████╗  ██║
   ██║   ██║ ╚███╔╝  ╚████╔╝ ██║  ███╗█████╗  ██╔██╗ ██║
   ██║   ██║ ██╔██╗   ╚██╔╝  ██║   ██║██╔══╝  ██║╚██╗██║
   ╚██████╔╝██╔╝ ██╗   ██║   ╚██████╔╝███████╗██║ ╚████║
    ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝
    
    Oxygen UI Library v1.0.0
    A modern, fully-featured Roblox GUI library
    
    Features:
    - Full OOP with metatables
    - Signal/Event system
    - 10+ built-in themes + live theme switching
    - Config save/load system
    - 20+ components
    - Notification system
    - Auto settings tab
    - Keyboard navigation
    - Mobile support
    - And much more!
--]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TextService       = game:GetService("TextService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- SIGNAL CLASS (No BindableEvents needed)
-- ============================================================
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _connections = {} }, Signal)
end

function Signal:Connect(fn)
    local connection = { _fn = fn, _signal = self, Connected = true }
    table.insert(self._connections, connection)
    function connection:Disconnect()
        self.Connected = false
        for i, c in ipairs(self._signal._connections) do
            if c == self then
                table.remove(self._signal._connections, i)
                break
            end
        end
    end
    return connection
end

function Signal:Fire(...)
    for _, connection in ipairs(self._connections) do
        task.spawn(connection._fn, ...)
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        coroutine.resume(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:Destroy()
    self._connections = {}
end

-- ============================================================
-- UTILITY
-- ============================================================
local Util = {}

function Util.Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

function Util.FastTween(obj, props, t)
    return Util.Tween(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
end

function Util.SlowTween(obj, props, t)
    return Util.Tween(obj, TweenInfo.new(t or 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
end

function Util.SpringTween(obj, props)
    return Util.Tween(obj, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), props)
end

function Util.GetMouseXY(GuiObject)
    local abs = GuiObject.AbsoluteSize
    local pos = GuiObject.AbsolutePosition
    local mx = math.clamp(Mouse.X - pos.X, 0, abs.X)
    local my = math.clamp(Mouse.Y - pos.Y, 0, abs.Y)
    return mx / abs.X, my / abs.Y
end

function Util.Ripple(parent, color)
    local px, py = Util.GetMouseXY(parent)
    local circle = Instance.new("ImageLabel")
    circle.BackgroundTransparency = 1
    circle.Image = "rbxassetid://5554831670"
    circle.ImageColor3 = color or Color3.new(1,1,1)
    circle.ImageTransparency = 0.7
    circle.ZIndex = parent.ZIndex + 10
    circle.Size = UDim2.fromOffset(0, 0)
    circle.Position = UDim2.fromScale(px, py)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Parent = parent
    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    Util.Tween(circle, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(size, size),
        ImageTransparency = 1
    })
    task.delay(0.6, function() circle:Destroy() end)
end

function Util.LerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

function Util.GetContrastColor(bg)
    local luminance = 0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B
    return luminance > 0.5 and Color3.new(0,0,0) or Color3.new(1,1,1)
end

function Util.Round(n, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(n * mult + 0.5) / mult
end

function Util.Clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

function Util.TableContains(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

function Util.DeepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == "table" and Util.DeepCopy(v) or v
    end
    return copy
end

function Util.SafeCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[Oxygen] Callback error: " .. tostring(err))
    end
end

function Util.ColorToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

function Util.HexToColor(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1,2), 16),
        tonumber(hex:sub(3,4), 16),
        tonumber(hex:sub(5,6), 16)
    )
end

-- ============================================================
-- ASSET CACHE
-- ============================================================
local Assets = {
    RoundRect   = "rbxassetid://5554237731",
    Shadow      = "rbxassetid://5554236805",
    Circle      = "rbxassetid://5554831670",
    CircleShadow= "rbxassetid://5554831957",
    Checkmark   = "rbxassetid://5554953789",
    Dropdown    = "rbxassetid://5574299686",
    Menu        = "rbxassetid://5555108481",
    Toggle      = "rbxassetid://3570695787",
    Close       = "rbxassetid://5034718129",
    Info        = "rbxassetid://5554838436",
    Warn        = "rbxassetid://5554838436",
    Success     = "rbxassetid://5554953789",
    Error       = "rbxassetid://5034718129",
    Settings    = "rbxassetid://5545724579",
    Search      = "rbxassetid://5547958855",
    Pin         = "rbxassetid://5576439039",
}

-- ============================================================
-- THEME DEFINITIONS
-- ============================================================
local Themes = {}

-- Base structure every theme must fill
local function makeTheme(t)
    return t
end

Themes.Carbon = makeTheme({
    Name = "Carbon",
    Primary       = Color3.fromRGB(20, 20, 25),
    Secondary     = Color3.fromRGB(32, 32, 40),
    Tertiary      = Color3.fromRGB(45, 45, 58),
    Accent        = Color3.fromRGB(120, 80, 255),
    AccentDark    = Color3.fromRGB(80, 50, 200),
    Text          = Color3.fromRGB(240, 240, 245),
    TextMuted     = Color3.fromRGB(150, 150, 165),
    TextDark      = Color3.fromRGB(20, 20, 25),
    Success       = Color3.fromRGB(50, 220, 120),
    Warning       = Color3.fromRGB(255, 190, 50),
    Error         = Color3.fromRGB(255, 75, 90),
    Info          = Color3.fromRGB(80, 180, 255),
    Shadow        = Color3.fromRGB(0, 0, 0),
    Border        = Color3.fromRGB(55, 55, 70),
    Highlight     = Color3.fromRGB(120, 80, 255),
    TitleBar      = Color3.fromRGB(28, 28, 36),
    NavBar        = Color3.fromRGB(24, 24, 30),
    Toggle        = Color3.fromRGB(120, 80, 255),
    Slider        = Color3.fromRGB(120, 80, 255),
    CornerRadius  = 8,
    Font          = Enum.Font.GothamSemibold,
    FontTitle     = Enum.Font.GothamBold,
})

Themes.Neon = makeTheme({
    Name = "Neon",
    Primary       = Color3.fromRGB(5, 5, 10),
    Secondary     = Color3.fromRGB(15, 15, 25),
    Tertiary      = Color3.fromRGB(25, 25, 45),
    Accent        = Color3.fromRGB(0, 255, 200),
    AccentDark    = Color3.fromRGB(0, 200, 155),
    Text          = Color3.fromRGB(220, 255, 250),
    TextMuted     = Color3.fromRGB(100, 180, 165),
    TextDark      = Color3.fromRGB(5, 5, 10),
    Success       = Color3.fromRGB(0, 255, 150),
    Warning       = Color3.fromRGB(255, 220, 0),
    Error         = Color3.fromRGB(255, 50, 100),
    Info          = Color3.fromRGB(0, 200, 255),
    Shadow        = Color3.fromRGB(0, 255, 200),
    Border        = Color3.fromRGB(0, 100, 80),
    Highlight     = Color3.fromRGB(0, 255, 200),
    TitleBar      = Color3.fromRGB(10, 10, 20),
    NavBar        = Color3.fromRGB(8, 8, 18),
    Toggle        = Color3.fromRGB(0, 255, 200),
    Slider        = Color3.fromRGB(0, 255, 200),
    CornerRadius  = 4,
    Font          = Enum.Font.Code,
    FontTitle     = Enum.Font.Code,
})

Themes.Rose = makeTheme({
    Name = "Rose",
    Primary       = Color3.fromRGB(255, 245, 248),
    Secondary     = Color3.fromRGB(255, 230, 238),
    Tertiary      = Color3.fromRGB(255, 210, 225),
    Accent        = Color3.fromRGB(220, 60, 100),
    AccentDark    = Color3.fromRGB(180, 40, 75),
    Text          = Color3.fromRGB(50, 20, 30),
    TextMuted     = Color3.fromRGB(150, 100, 115),
    TextDark      = Color3.fromRGB(255, 245, 248),
    Success       = Color3.fromRGB(60, 180, 100),
    Warning       = Color3.fromRGB(220, 150, 30),
    Error         = Color3.fromRGB(200, 40, 60),
    Info          = Color3.fromRGB(80, 140, 220),
    Shadow        = Color3.fromRGB(180, 80, 100),
    Border        = Color3.fromRGB(220, 180, 190),
    Highlight     = Color3.fromRGB(220, 60, 100),
    TitleBar      = Color3.fromRGB(220, 60, 100),
    NavBar        = Color3.fromRGB(200, 50, 85),
    Toggle        = Color3.fromRGB(220, 60, 100),
    Slider        = Color3.fromRGB(220, 60, 100),
    CornerRadius  = 12,
    Font          = Enum.Font.Gotham,
    FontTitle     = Enum.Font.GothamBold,
})

Themes.Ocean = makeTheme({
    Name = "Ocean",
    Primary       = Color3.fromRGB(8, 18, 38),
    Secondary     = Color3.fromRGB(12, 28, 58),
    Tertiary      = Color3.fromRGB(18, 42, 82),
    Accent        = Color3.fromRGB(30, 160, 255),
    AccentDark    = Color3.fromRGB(20, 120, 210),
    Text          = Color3.fromRGB(200, 230, 255),
    TextMuted     = Color3.fromRGB(100, 150, 200),
    TextDark      = Color3.fromRGB(8, 18, 38),
    Success       = Color3.fromRGB(40, 220, 140),
    Warning       = Color3.fromRGB(255, 200, 40),
    Error         = Color3.fromRGB(255, 80, 80),
    Info          = Color3.fromRGB(30, 160, 255),
    Shadow        = Color3.fromRGB(0, 20, 60),
    Border        = Color3.fromRGB(25, 60, 110),
    Highlight     = Color3.fromRGB(30, 160, 255),
    TitleBar      = Color3.fromRGB(10, 22, 48),
    NavBar        = Color3.fromRGB(8, 18, 40),
    Toggle        = Color3.fromRGB(30, 160, 255),
    Slider        = Color3.fromRGB(30, 160, 255),
    CornerRadius  = 8,
    Font          = Enum.Font.GothamSemibold,
    FontTitle     = Enum.Font.GothamBold,
})

Themes.Forest = makeTheme({
    Name = "Forest",
    Primary       = Color3.fromRGB(18, 28, 20),
    Secondary     = Color3.fromRGB(28, 45, 30),
    Tertiary      = Color3.fromRGB(40, 65, 42),
    Accent        = Color3.fromRGB(80, 200, 100),
    AccentDark    = Color3.fromRGB(55, 155, 70),
    Text          = Color3.fromRGB(210, 240, 215),
    TextMuted     = Color3.fromRGB(120, 175, 130),
    TextDark      = Color3.fromRGB(18, 28, 20),
    Success       = Color3.fromRGB(80, 200, 100),
    Warning       = Color3.fromRGB(220, 190, 50),
    Error         = Color3.fromRGB(220, 80, 80),
    Info          = Color3.fromRGB(80, 180, 220),
    Shadow        = Color3.fromRGB(5, 15, 8),
    Border        = Color3.fromRGB(45, 75, 48),
    Highlight     = Color3.fromRGB(80, 200, 100),
    TitleBar      = Color3.fromRGB(22, 35, 24),
    NavBar        = Color3.fromRGB(18, 30, 20),
    Toggle        = Color3.fromRGB(80, 200, 100),
    Slider        = Color3.fromRGB(80, 200, 100),
    CornerRadius  = 6,
    Font          = Enum.Font.Gotham,
    FontTitle     = Enum.Font.GothamBold,
})

Themes.Sunset = makeTheme({
    Name = "Sunset",
    Primary       = Color3.fromRGB(255, 235, 210),
    Secondary     = Color3.fromRGB(255, 215, 180),
    Tertiary      = Color3.fromRGB(255, 190, 145),
    Accent        = Color3.fromRGB(235, 100, 40),
    AccentDark    = Color3.fromRGB(200, 75, 20),
    Text          = Color3.fromRGB(60, 30, 15),
    TextMuted     = Color3.fromRGB(160, 110, 75),
    TextDark      = Color3.fromRGB(255, 235, 210),
    Success       = Color3.fromRGB(60, 180, 80),
    Warning       = Color3.fromRGB(235, 170, 20),
    Error         = Color3.fromRGB(210, 50, 50),
    Info          = Color3.fromRGB(60, 140, 220),
    Shadow        = Color3.fromRGB(180, 80, 20),
    Border        = Color3.fromRGB(225, 180, 140),
    Highlight     = Color3.fromRGB(235, 100, 40),
    TitleBar      = Color3.fromRGB(235, 100, 40),
    NavBar        = Color3.fromRGB(210, 85, 30),
    Toggle        = Color3.fromRGB(235, 100, 40),
    Slider        = Color3.fromRGB(235, 100, 40),
    CornerRadius  = 10,
    Font          = Enum.Font.Gotham,
    FontTitle     = Enum.Font.GothamBold,
})

Themes.Midnight = makeTheme({
    Name = "Midnight",
    Primary       = Color3.fromRGB(8, 8, 12),
    Secondary     = Color3.fromRGB(15, 15, 22),
    Tertiary      = Color3.fromRGB(22, 22, 35),
    Accent        = Color3.fromRGB(180, 100, 255),
    AccentDark    = Color3.fromRGB(140, 70, 220),
    Text          = Color3.fromRGB(230, 225, 245),
    TextMuted     = Color3.fromRGB(130, 125, 155),
    TextDark      = Color3.fromRGB(8, 8, 12),
    Success       = Color3.fromRGB(80, 220, 140),
    Warning       = Color3.fromRGB(255, 200, 50),
    Error         = Color3.fromRGB(255, 70, 90),
    Info          = Color3.fromRGB(100, 180, 255),
    Shadow        = Color3.fromRGB(0, 0, 0),
    Border        = Color3.fromRGB(30, 28, 45),
    Highlight     = Color3.fromRGB(180, 100, 255),
    TitleBar      = Color3.fromRGB(12, 10, 18),
    NavBar        = Color3.fromRGB(10, 8, 15),
    Toggle        = Color3.fromRGB(180, 100, 255),
    Slider        = Color3.fromRGB(180, 100, 255),
    CornerRadius  = 8,
    Font          = Enum.Font.GothamSemibold,
    FontTitle     = Enum.Font.GothamBold,
})

Themes.Ice = makeTheme({
    Name = "Ice",
    Primary       = Color3.fromRGB(240, 248, 255),
    Secondary     = Color3.fromRGB(220, 238, 252),
    Tertiary      = Color3.fromRGB(195, 225, 248),
    Accent        = Color3.fromRGB(60, 145, 220),
    AccentDark    = Color3.fromRGB(40, 110, 185),
    Text          = Color3.fromRGB(20, 50, 90),
    TextMuted     = Color3.fromRGB(100, 140, 185),
    TextDark      = Color3.fromRGB(240, 248, 255),
    Success       = Color3.fromRGB(40, 185, 120),
    Warning       = Color3.fromRGB(210, 165, 30),
    Error         = Color3.fromRGB(210, 55, 70),
    Info          = Color3.fromRGB(60, 145, 220),
    Shadow        = Color3.fromRGB(100, 160, 215),
    Border        = Color3.fromRGB(175, 215, 245),
    Highlight     = Color3.fromRGB(60, 145, 220),
    TitleBar      = Color3.fromRGB(60, 145, 220),
    NavBar        = Color3.fromRGB(50, 130, 200),
    Toggle        = Color3.fromRGB(60, 145, 220),
    Slider        = Color3.fromRGB(60, 145, 220),
    CornerRadius  = 12,
    Font          = Enum.Font.Gotham,
    FontTitle     = Enum.Font.GothamBold,
})

Themes.Mocha = makeTheme({
    Name = "Mocha",
    Primary       = Color3.fromRGB(45, 32, 22),
    Secondary     = Color3.fromRGB(65, 48, 32),
    Tertiary      = Color3.fromRGB(88, 68, 48),
    Accent        = Color3.fromRGB(200, 155, 100),
    AccentDark    = Color3.fromRGB(165, 120, 72),
    Text          = Color3.fromRGB(245, 232, 215),
    TextMuted     = Color3.fromRGB(175, 148, 118),
    TextDark      = Color3.fromRGB(45, 32, 22),
    Success       = Color3.fromRGB(80, 185, 105),
    Warning       = Color3.fromRGB(215, 175, 45),
    Error         = Color3.fromRGB(210, 70, 70),
    Info          = Color3.fromRGB(100, 170, 220),
    Shadow        = Color3.fromRGB(20, 12, 5),
    Border        = Color3.fromRGB(95, 72, 50),
    Highlight     = Color3.fromRGB(200, 155, 100),
    TitleBar      = Color3.fromRGB(55, 38, 25),
    NavBar        = Color3.fromRGB(48, 33, 20),
    Toggle        = Color3.fromRGB(200, 155, 100),
    Slider        = Color3.fromRGB(200, 155, 100),
    CornerRadius  = 8,
    Font          = Enum.Font.Gotham,
    FontTitle     = Enum.Font.GothamBold,
})

Themes.Light = makeTheme({
    Name = "Light",
    Primary       = Color3.fromRGB(248, 248, 252),
    Secondary     = Color3.fromRGB(235, 235, 242),
    Tertiary      = Color3.fromRGB(220, 220, 232),
    Accent        = Color3.fromRGB(100, 60, 240),
    AccentDark    = Color3.fromRGB(75, 40, 200),
    Text          = Color3.fromRGB(25, 25, 35),
    TextMuted     = Color3.fromRGB(120, 120, 145),
    TextDark      = Color3.fromRGB(248, 248, 252),
    Success       = Color3.fromRGB(40, 185, 100),
    Warning       = Color3.fromRGB(210, 165, 25),
    Error         = Color3.fromRGB(210, 50, 65),
    Info          = Color3.fromRGB(60, 140, 225),
    Shadow        = Color3.fromRGB(150, 150, 180),
    Border        = Color3.fromRGB(200, 200, 218),
    Highlight     = Color3.fromRGB(100, 60, 240),
    TitleBar      = Color3.fromRGB(100, 60, 240),
    NavBar        = Color3.fromRGB(88, 50, 220),
    Toggle        = Color3.fromRGB(100, 60, 240),
    Slider        = Color3.fromRGB(100, 60, 240),
    CornerRadius  = 10,
    Font          = Enum.Font.Gotham,
    FontTitle     = Enum.Font.GothamBold,
})

-- ============================================================
-- ELEMENT BUILDER (Low-level GUI factory)
-- ============================================================
local function MakeRound(parent, color, size, pos, radius, zindex)
    local f = Instance.new("ImageLabel")
    f.BackgroundTransparency = 1
    f.Image = Assets.RoundRect
    f.ScaleType = Enum.ScaleType.Slice
    f.SliceCenter = Rect.new(3,3,297,297)
    f.ImageColor3 = color or Color3.new(1,1,1)
    f.Size = size or UDim2.fromScale(1,1)
    f.Position = pos or UDim2.fromScale(0,0)
    f.ZIndex = zindex or 1
    f.Parent = parent
    return f
end

local function MakeShadow(parent, color, zindex)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.BackgroundTransparency = 1
    s.Image = Assets.Shadow
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(23,23,277,277)
    s.ImageColor3 = color or Color3.new(0,0,0)
    s.ImageTransparency = 0.6
    s.Size = UDim2.fromScale(1,1) + UDim2.fromOffset(32,32)
    s.Position = UDim2.fromOffset(-16,-16)
    s.ZIndex = (zindex or 1) - 1
    s.Parent = parent
    return s
end

local function MakeLabel(parent, text, color, size, pos, font, textsize, zindex)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = color or Color3.new(1,1,1)
    l.Size = size or UDim2.fromScale(1,1)
    l.Position = pos or UDim2.fromScale(0,0)
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textsize or 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = zindex or 2
    l.Parent = parent
    return l
end

local function MakeButton(parent, text, color, size, pos, font, textsize, zindex)
    local b = Instance.new("ImageButton")
    b.BackgroundTransparency = 1
    b.AutoButtonColor = false
    b.Image = Assets.RoundRect
    b.ScaleType = Enum.ScaleType.Slice
    b.SliceCenter = Rect.new(3,3,297,297)
    b.ImageColor3 = color or Color3.new(0.2,0.2,0.2)
    b.Size = size or UDim2.fromScale(1,1)
    b.Position = pos or UDim2.fromScale(0,0)
    b.ZIndex = zindex or 2
    b.Parent = parent

    if text then
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.new(1,1,1)
        l.Size = UDim2.fromScale(1,1)
        l.Font = font or Enum.Font.GothamSemibold
        l.TextSize = textsize or 14
        l.ZIndex = (zindex or 2) + 1
        l.Parent = b
        return b, l
    end
    return b
end

local function AddCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function AddPadding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 5)
    p.PaddingRight = UDim.new(0, right or 5)
    p.PaddingBottom = UDim.new(0, bottom or 5)
    p.PaddingLeft = UDim.new(0, left or 5)
    p.Parent = parent
    return p
end

local function AddList(parent, dir, halign, valign, padding, sortorder)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment = valign or Enum.VerticalAlignment.Top
    l.SortOrder = sortorder or Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, padding or 5)
    l.Parent = parent
    return l
end

local function AddStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1,1,1)
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- ============================================================
-- CONFIG SAVE SYSTEM
-- ============================================================
local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem

function ConfigSystem.new(libraryName)
    local self = setmetatable({}, ConfigSystem)
    self.LibraryName = libraryName or "OxygenUI"
    self.FileName = self.LibraryName .. "_Config.json"
    self.Data = {}
    self:Load()
    return self
end

function ConfigSystem:Load()
    pcall(function()
        if readfile then
            local raw = readfile(self.FileName)
            self.Data = HttpService:JSONDecode(raw)
        end
    end)
    self.Data = self.Data or {}
end

function ConfigSystem:Save()
    pcall(function()
        if writefile then
            writefile(self.FileName, HttpService:JSONEncode(self.Data))
        end
    end)
end

function ConfigSystem:Set(key, value)
    self.Data[key] = value
    self:Save()
end

function ConfigSystem:Get(key, default)
    return self.Data[key] ~= nil and self.Data[key] or default
end

function ConfigSystem:Reset()
    self.Data = {}
    self:Save()
end

function ConfigSystem:Export()
    return HttpService:JSONEncode(self.Data)
end

function ConfigSystem:Import(json)
    local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
    if ok then
        self.Data = data
        self:Save()
        return true
    end
    return false
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new(screenGui)
    local self = setmetatable({}, NotificationSystem)
    self.Queue = {}
    self.Container = Instance.new("Frame")
    self.Container.Name = "OxygenNotifications"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = UDim2.fromOffset(320, 0)
    self.Container.Position = UDim2.new(1, -330, 1, -10)
    self.Container.AnchorPoint = Vector2.new(0, 1)
    self.Container.Parent = screenGui
    
    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.Padding = UDim.new(0, 8)
    list.Parent = self.Container
    
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.Container.Size = UDim2.fromOffset(320, list.AbsoluteContentSize.Y + 8)
    end)
    
    return self
end

local NotifTypes = {
    success = { icon = "✓", color = Color3.fromRGB(50, 200, 100) },
    warning = { icon = "⚠", color = Color3.fromRGB(240, 175, 30) },
    error   = { icon = "✕", color = Color3.fromRGB(235, 65, 80) },
    info    = { icon = "i", color = Color3.fromRGB(70, 165, 255) },
}

function NotificationSystem:Push(config, theme)
    local title    = config.Title or "Notification"
    local desc     = config.Description or ""
    local ntype    = config.Type or "info"
    local duration = config.Duration or 4
    local callback = config.Callback

    local typeData = NotifTypes[ntype] or NotifTypes.info

    -- Container frame
    local card = Instance.new("Frame")
    card.Name = "Notification"
    card.BackgroundColor3 = theme.Secondary
    card.BorderSizePixel = 0
    card.Size = UDim2.fromOffset(320, 70)
    card.ClipsDescendants = true
    card.Parent = self.Container
    AddCorner(card, 10)
    AddStroke(card, theme.Border, 1)
    MakeShadow(card, theme.Shadow)

    -- Accent bar
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = typeData.color
    bar.BorderSizePixel = 0
    bar.Size = UDim2.fromOffset(4, 70)
    bar.Position = UDim2.fromScale(0, 0)
    bar.Parent = card
    AddCorner(bar, 4)

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.BackgroundTransparency = 1
    iconLabel.Size = UDim2.fromOffset(30, 30)
    iconLabel.Position = UDim2.fromOffset(14, 10)
    iconLabel.Text = typeData.icon
    iconLabel.TextColor3 = typeData.color
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 18
    iconLabel.Parent = card

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.fromOffset(240, 22)
    titleLabel.Position = UDim2.fromOffset(50, 8)
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card

    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.BackgroundTransparency = 1
    descLabel.Size = UDim2.fromOffset(255, 36)
    descLabel.Position = UDim2.fromOffset(50, 30)
    descLabel.Text = desc
    descLabel.TextColor3 = theme.TextMuted
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 12
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = card

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.fromOffset(20, 20)
    closeBtn.Position = UDim2.new(1, -26, 0, 6)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = theme.TextMuted
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.Parent = card

    -- Progress bar
    local progress = Instance.new("Frame")
    progress.BackgroundColor3 = typeData.color
    progress.BorderSizePixel = 0
    progress.Size = UDim2.fromScale(1, 0)
    progress.Position = UDim2.new(0, 0, 1, -3)
    progress.Parent = card
    local progressH = Instance.new("Frame")
    progressH.BackgroundColor3 = typeData.color
    progressH.BackgroundTransparency = 0
    progressH.BorderSizePixel = 0
    progressH.Size = UDim2.fromOffset(0, 3)
    progressH.Parent = card
    progressH.Position = UDim2.new(0, 0, 1, -3)

    -- Animate in
    card.Position = UDim2.fromOffset(340, 0)
    Util.SpringTween(card, { Position = UDim2.fromOffset(0, 0) })

    -- Progress tween
    Util.Tween(progressH, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.fromOffset(320, 3)
    })

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        Util.FastTween(card, { Position = UDim2.fromOffset(340, 0) }, 0.3)
        task.delay(0.35, function()
            card:Destroy()
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    if callback then
        card.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                Util.SafeCall(callback)
                dismiss()
            end
        end)
    end

    task.delay(duration, dismiss)
    return { Dismiss = dismiss }
end

-- ============================================================
-- TOOLTIP SYSTEM
-- ============================================================
local function AttachTooltip(element, text, theme, screenGui)
    local tooltip
    local conn1, conn2

    conn1 = element.MouseEnter:Connect(function()
        if tooltip then tooltip:Destroy() end
        tooltip = Instance.new("Frame")
        tooltip.BackgroundColor3 = theme.Tertiary
        tooltip.BorderSizePixel = 0
        tooltip.Size = UDim2.fromOffset(0, 28)
        tooltip.ZIndex = 9999
        tooltip.Parent = screenGui
        AddCorner(tooltip, 6)
        MakeShadow(tooltip, theme.Shadow)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = theme.Text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.Size = UDim2.fromScale(1,1)
        lbl.ZIndex = 9999
        lbl.Parent = tooltip
        AddPadding(tooltip, 4, 8, 4, 8)

        local textWidth = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(9999,9999)).X + 16
        tooltip.Size = UDim2.fromOffset(textWidth, 28)

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not tooltip or not tooltip.Parent then
                conn:Disconnect()
                return
            end
            tooltip.Position = UDim2.fromOffset(Mouse.X + 12, Mouse.Y - 34)
        end)
    end)

    conn2 = element.MouseLeave:Connect(function()
        if tooltip then
            tooltip:Destroy()
            tooltip = nil
        end
    end)
end

-- ============================================================
-- MAIN LIBRARY
-- ============================================================
local Oxygen = {}
Oxygen.__index = Oxygen

local ActiveTheme
local ActiveWindow
local _Connections = {}

local function AddConn(conn)
    table.insert(_Connections, conn)
end

function Oxygen.new(config)
    local self = setmetatable({}, Oxygen)

    config = config or {}
    self.Title        = config.Title or "Oxygen"
    self.Subtitle     = config.Subtitle or "UI Library"
    self.ThemeName    = config.Theme or "Carbon"
    self.SizeX        = config.SizeX or 580
    self.SizeY        = config.SizeY or 420
    self.SaveConfig   = config.SaveConfig ~= false
    self.ConfigName   = config.ConfigName or self.Title
    self.Watermark    = config.Watermark ~= false
    self.ToggleKey    = config.ToggleKey or Enum.KeyCode.RightControl
    self.MinimizeKey  = config.MinimizeKey or Enum.KeyCode.RightShift
    self.Debug        = config.Debug or false

    -- State
    self.Theme = Themes[self.ThemeName] or Themes.Carbon
    ActiveTheme = self.Theme
    self.Tabs = {}
    self.TabButtons = {}
    self.TabPages = {}
    self.ActiveTabIndex = 1
    self.Connections = {}
    self.Components = {}
    self.Visible = true
    self.Minimized = false

    -- Config system
    if self.SaveConfig then
        self.Config = ConfigSystem.new(self.ConfigName)
    end

    -- Build GUI
    self:_Build()
    self:_BuildSettingsTab()
    self:_SetupKeybinds()
    self:_SetupWatermark()

    ActiveWindow = self
    return self
end

function Oxygen:_GetExploit()
    if syn then return "Synapse"
    elseif KRNL_LOADED then return "Krnl"
    elseif getexecutorname then return getexecutorname()
    else return "Unknown" end
end

function Oxygen:_ProtectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        elseif gethui then
            gui.Parent = gethui()
        else
            gui.Parent = CoreGui
        end
    end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

function Oxygen:_Build()
    local theme = self.Theme

    -- Screen GUI
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "OxygenUI_" .. self.Title
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.ResetOnSpawn = false
    self:_ProtectGui(self.ScreenGui)

    -- Notification system
    self.Notifs = NotificationSystem.new(self.ScreenGui)

    -- Blur overlay
    self.BlurOverlay = Instance.new("Frame")
    self.BlurOverlay.Name = "BlurOverlay"
    self.BlurOverlay.BackgroundColor3 = Color3.new(0,0,0)
    self.BlurOverlay.BackgroundTransparency = 1
    self.BlurOverlay.Size = UDim2.fromScale(1,1)
    self.BlurOverlay.ZIndex = 0
    self.BlurOverlay.Parent = self.ScreenGui

    -- Main window frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "OxygenWindow"
    self.MainFrame.BackgroundColor3 = theme.Primary
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Size = UDim2.fromOffset(self.SizeX, self.SizeY)
    self.MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    self.MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui
    AddCorner(self.MainFrame, theme.CornerRadius)
    MakeShadow(self.MainFrame, theme.Shadow)
    AddStroke(self.MainFrame, theme.Border, 1)

    -- Animate open
    self.MainFrame.Size = UDim2.fromOffset(0, 0)
    Util.SpringTween(self.MainFrame, { Size = UDim2.fromOffset(self.SizeX, self.SizeY) })

    -- === TITLE BAR ===
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.BackgroundColor3 = theme.TitleBar
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Size = UDim2.fromOffset(self.SizeX, 42)
    self.TitleBar.ZIndex = 10
    self.TitleBar.Parent = self.MainFrame

    -- Accent line under title bar
    local titleAccent = Instance.new("Frame")
    titleAccent.BackgroundColor3 = theme.Accent
    titleAccent.BorderSizePixel = 0
    titleAccent.Size = UDim2.fromOffset(40, 2)
    titleAccent.Position = UDim2.fromOffset(12, 40)
    titleAccent.ZIndex = 11
    titleAccent.Parent = self.MainFrame

    -- Logo dot
    local logoDot = Instance.new("Frame")
    logoDot.BackgroundColor3 = theme.Accent
    logoDot.BorderSizePixel = 0
    logoDot.Size = UDim2.fromOffset(8, 8)
    logoDot.Position = UDim2.fromOffset(12, 17)
    logoDot.ZIndex = 11
    logoDot.Parent = self.TitleBar
    AddCorner(logoDot, 4)

    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(28, 0)
    titleLabel.Size = UDim2.fromOffset(200, 42)
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = theme.Text
    titleLabel.Font = theme.FontTitle
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 11
    titleLabel.Parent = self.TitleBar

    -- Subtitle
    local subLabel = Instance.new("TextLabel")
    subLabel.BackgroundTransparency = 1
    subLabel.Position = UDim2.fromOffset(28, 22)
    subLabel.Size = UDim2.fromOffset(200, 20)
    subLabel.Text = self.Subtitle
    subLabel.TextColor3 = theme.TextMuted
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextSize = 11
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.ZIndex = 11
    subLabel.Parent = self.TitleBar

    -- Window controls (close / minimize)
    local function makeControl(xOffset, color, icon)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Size = UDim2.fromOffset(12, 12)
        btn.Position = UDim2.new(1, xOffset, 0.5, -6)
        btn.Text = ""
        btn.ZIndex = 12
        btn.Parent = self.TitleBar
        AddCorner(btn, 6)

        local hover = Instance.new("TextLabel")
        hover.BackgroundTransparency = 1
        hover.Size = UDim2.fromScale(1,1)
        hover.Text = icon
        hover.TextColor3 = Color3.new(0,0,0)
        hover.Font = Enum.Font.GothamBold
        hover.TextSize = 9
        hover.TextTransparency = 1
        hover.ZIndex = 13
        hover.Parent = btn

        btn.MouseEnter:Connect(function()
            Util.FastTween(hover, { TextTransparency = 0 })
        end)
        btn.MouseLeave:Connect(function()
            Util.FastTween(hover, { TextTransparency = 1 })
        end)
        return btn
    end

    local closeBtn = makeControl(-22, Color3.fromRGB(255, 90, 80), "×")
    local minimBtn = makeControl(-40, Color3.fromRGB(255, 185, 30), "−")
    local hideBtn  = makeControl(-58, Color3.fromRGB(40, 205, 65), "⤢")

    self.CloseBtn  = closeBtn
    self.MinimBtn  = minimBtn

    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    minimBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)

    hideBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Drag
    local dragging, dragStart, startPos
    self.TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = Vector2.new(Mouse.X, Mouse.Y)
            startPos = self.MainFrame.Position
        end
    end)
    AddConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMove then
            local delta = Vector2.new(Mouse.X - dragStart.X, Mouse.Y - dragStart.Y)
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
    AddConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    -- === SIDEBAR (Tab nav) ===
    self.SideBar = Instance.new("Frame")
    self.SideBar.Name = "SideBar"
    self.SideBar.BackgroundColor3 = theme.NavBar
    self.SideBar.BorderSizePixel = 0
    self.SideBar.Size = UDim2.fromOffset(130, self.SizeY - 42)
    self.SideBar.Position = UDim2.fromOffset(0, 42)
    self.SideBar.ZIndex = 5
    self.SideBar.Parent = self.MainFrame
    AddStroke(self.SideBar, theme.Border, 1)

    -- Sidebar tab list
    self.TabList = Instance.new("ScrollingFrame")
    self.TabList.BackgroundTransparency = 1
    self.TabList.BorderSizePixel = 0
    self.TabList.Size = UDim2.fromScale(1, 1)
    self.TabList.CanvasSize = UDim2.fromScale(0, 0)
    self.TabList.ScrollBarThickness = 2
    self.TabList.ScrollBarImageColor3 = theme.Accent
    self.TabList.ZIndex = 6
    self.TabList.Parent = self.SideBar
    AddPadding(self.TabList, 8, 6, 8, 6)

    local tabListLayout = AddList(self.TabList, nil, nil, nil, 4)
    tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabList.CanvasSize = UDim2.fromOffset(0, tabListLayout.AbsoluteContentSize.Y + 16)
    end)

    -- === CONTENT AREA ===
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Name = "Content"
    self.ContentFrame.BackgroundColor3 = theme.Primary
    self.ContentFrame.BorderSizePixel = 0
    self.ContentFrame.Size = UDim2.fromOffset(self.SizeX - 130, self.SizeY - 42)
    self.ContentFrame.Position = UDim2.fromOffset(130, 42)
    self.ContentFrame.ClipsDescendants = true
    self.ContentFrame.ZIndex = 3
    self.ContentFrame.Parent = self.MainFrame

    -- Section title bar inside content
    self.SectionTitle = Instance.new("TextLabel")
    self.SectionTitle.BackgroundTransparency = 1
    self.SectionTitle.Size = UDim2.fromOffset(self.SizeX - 160, 32)
    self.SectionTitle.Position = UDim2.fromOffset(12, 4)
    self.SectionTitle.Text = ""
    self.SectionTitle.TextColor3 = theme.Text
    self.SectionTitle.Font = theme.FontTitle
    self.SectionTitle.TextSize = 15
    self.SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    self.SectionTitle.ZIndex = 4
    self.SectionTitle.Parent = self.ContentFrame

    self._titleAccent = titleAccent
    self._titleLabel = titleLabel
    self._subLabel = subLabel
end

function Oxygen:_SetupKeybinds()
    AddConn(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        elseif input.KeyCode == self.MinimizeKey then
            self:ToggleMinimize()
        end
    end))
end

function Oxygen:_SetupWatermark()
    if not self.Watermark then return end
    local wm = Instance.new("Frame")
    wm.BackgroundColor3 = self.Theme.Secondary
    wm.BorderSizePixel = 0
    wm.Size = UDim2.fromOffset(180, 28)
    wm.Position = UDim2.new(0, 10, 1, -38)
    wm.ZIndex = 100
    wm.Parent = self.ScreenGui
    AddCorner(wm, 6)
    AddStroke(wm, self.Theme.Border, 1)

    local wl = Instance.new("TextLabel")
    wl.BackgroundTransparency = 1
    wl.Size = UDim2.fromScale(1, 1)
    wl.Text = "⚡ Oxygen  |  " .. self.Title
    wl.TextColor3 = self.Theme.TextMuted
    wl.Font = Enum.Font.Gotham
    wl.TextSize = 11
    wl.ZIndex = 101
    wl.Parent = wm
    self._watermarkFrame = wm
    self._watermarkLabel = wl
end

function Oxygen:Toggle()
    self.Visible = not self.Visible
    Util.FastTween(self.MainFrame, { 
        Size = self.Visible and UDim2.fromOffset(self.SizeX, self.Minimized and 42 or self.SizeY) or UDim2.fromOffset(0, 0)
    }, 0.25)
end

function Oxygen:ToggleMinimize()
    self.Minimized = not self.Minimized
    Util.FastTween(self.MainFrame, {
        Size = self.Minimized and UDim2.fromOffset(self.SizeX, 42) or UDim2.fromOffset(self.SizeX, self.SizeY)
    }, 0.2)
end

function Oxygen:SetTheme(themeName)
    local newTheme = Themes[themeName]
    if not newTheme then
        warn("[Oxygen] Theme not found: " .. tostring(themeName))
        return
    end
    self.Theme = newTheme
    self.ThemeName = themeName
    ActiveTheme = newTheme

    -- Live update key elements
    local function tweenColor(obj, prop, color)
        Util.FastTween(obj, { [prop] = color }, 0.3)
    end

    tweenColor(self.MainFrame, "BackgroundColor3", newTheme.Primary)
    tweenColor(self.TitleBar, "BackgroundColor3", newTheme.TitleBar)
    tweenColor(self.SideBar, "BackgroundColor3", newTheme.NavBar)
    tweenColor(self.ContentFrame, "BackgroundColor3", newTheme.Primary)
    tweenColor(self._titleLabel, "TextColor3", newTheme.Text)
    tweenColor(self._subLabel, "TextColor3", newTheme.TextMuted)
    tweenColor(self._titleAccent, "BackgroundColor3", newTheme.Accent)

    if self.SaveConfig then
        self.Config:Set("Theme", themeName)
    end
end

function Oxygen:Notify(config)
    return self.Notifs:Push(config, self.Theme)
end

-- ============================================================
-- TAB SYSTEM
-- ============================================================
function Oxygen:AddTab(config)
    config = config or {}
    local tabTitle = config.Title or "Tab"
    local tabIcon  = config.Icon or "•"
    local theme = self.Theme
    local tabIndex = #self.Tabs + 1

    -- Sidebar button
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. tabTitle
    tabBtn.BackgroundColor3 = tabIndex == 1 and theme.Tertiary or theme.NavBar
    tabBtn.BorderSizePixel = 0
    tabBtn.Size = UDim2.new(1, 0, 0, 34)
    tabBtn.Text = ""
    tabBtn.ZIndex = 7
    tabBtn.Parent = self.TabList
    AddCorner(tabBtn, 6)

    -- Tab icon
    local iconLbl = Instance.new("TextLabel")
    iconLbl.BackgroundTransparency = 1
    iconLbl.Size = UDim2.fromOffset(22, 34)
    iconLbl.Position = UDim2.fromOffset(8, 0)
    iconLbl.Text = tabIcon
    iconLbl.TextColor3 = tabIndex == 1 and theme.Accent or theme.TextMuted
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextSize = 14
    iconLbl.ZIndex = 8
    iconLbl.Parent = tabBtn

    -- Tab label
    local tabLbl = Instance.new("TextLabel")
    tabLbl.BackgroundTransparency = 1
    tabLbl.Size = UDim2.new(1, -38, 1, 0)
    tabLbl.Position = UDim2.fromOffset(32, 0)
    tabLbl.Text = tabTitle
    tabLbl.TextColor3 = tabIndex == 1 and theme.Text or theme.TextMuted
    tabLbl.Font = theme.Font
    tabLbl.TextSize = 13
    tabLbl.TextXAlignment = Enum.TextXAlignment.Left
    tabLbl.ZIndex = 8
    tabLbl.Parent = tabBtn

    -- Active indicator bar
    local indicator = Instance.new("Frame")
    indicator.BackgroundColor3 = theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Size = UDim2.fromOffset(3, tabIndex == 1 and 24 or 0)
    indicator.Position = UDim2.new(0, -1, 0.5, -(tabIndex == 1 and 12 or 0))
    indicator.ZIndex = 9
    indicator.Parent = tabBtn
    AddCorner(indicator, 2)

    -- Content page (scrolling)
    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. tabTitle
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.fromOffset(self.SizeX - 150, self.SizeY - 80)
    page.Position = UDim2.fromOffset(10, 36)
    page.CanvasSize = UDim2.fromScale(0, 0)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = theme.Accent
    page.Visible = (tabIndex == 1)
    page.ZIndex = 4
    page.Parent = self.ContentFrame
    AddPadding(page, 6, 6, 10, 4)

    local pageList = AddList(page, nil, nil, nil, 6)
    pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(0, pageList.AbsoluteContentSize.Y + 20)
    end)

    -- Hover effect
    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTabIndex ~= tabIndex then
            Util.FastTween(tabBtn, { BackgroundColor3 = theme.Tertiary })
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTabIndex ~= tabIndex then
            Util.FastTween(tabBtn, { BackgroundColor3 = theme.NavBar })
        end
    end)

    -- Click to switch
    tabBtn.MouseButton1Click:Connect(function()
        self:_SwitchTab(tabIndex)
    end)

    table.insert(self.Tabs, { Title = tabTitle, Button = tabBtn, Page = page, Icon = iconLbl, Label = tabLbl, Indicator = indicator })
    table.insert(self.TabButtons, tabBtn)
    table.insert(self.TabPages, page)

    if tabIndex == 1 then
        self.SectionTitle.Text = tabTitle
    end

    -- Return tab component builder
    return self:_MakeTabAPI(tabIndex, page, pageList, theme)
end

function Oxygen:_SwitchTab(index)
    local theme = self.Theme
    for i, tab in ipairs(self.Tabs) do
        local active = (i == index)
        tab.Page.Visible = active
        Util.FastTween(tab.Button, { BackgroundColor3 = active and theme.Tertiary or theme.NavBar })
        Util.FastTween(tab.Icon, { TextColor3 = active and theme.Accent or theme.TextMuted })
        Util.FastTween(tab.Label, { TextColor3 = active and theme.Text or theme.TextMuted })
        Util.FastTween(tab.Indicator, {
            Size = UDim2.fromOffset(3, active and 24 or 0),
            Position = UDim2.new(0, -1, 0.5, active and -12 or 0)
        })
    end
    self.ActiveTabIndex = index
    self.SectionTitle.Text = self.Tabs[index].Title
end

-- ============================================================
-- SETTINGS TAB (Auto-generated)
-- ============================================================
function Oxygen:_BuildSettingsTab()
    local settingsTab = self:AddTab({ Title = "Settings", Icon = "⚙" })

    -- Move settings to end later; for now build it
    settingsTab.Section({ Title = "Appearance" })

    -- Theme selector
    local themeOptions = {}
    for name, _ in pairs(Themes) do
        table.insert(themeOptions, name)
    end
    table.sort(themeOptions)

    settingsTab.Dropdown({
        Title = "Theme",
        Description = "Choose a UI theme",
        Options = themeOptions,
        Default = self.ThemeName,
        Callback = function(val)
            self:SetTheme(val)
        end
    })

    settingsTab.Section({ Title = "Keybinds" })

    settingsTab.Keybind({
        Title = "Toggle UI",
        Description = "Show or hide the interface",
        Default = self.ToggleKey,
        Callback = function(key)
            self.ToggleKey = key
        end
    })

    settingsTab.Keybind({
        Title = "Minimize UI",
        Description = "Collapse to title bar only",
        Default = self.MinimizeKey,
        Callback = function(key)
            self.MinimizeKey = key
        end
    })

    settingsTab.Section({ Title = "Window" })

    settingsTab.Toggle({
        Title = "Watermark",
        Description = "Show the Oxygen watermark",
        Default = self.Watermark,
        Callback = function(val)
            self.Watermark = val
            if self._watermarkFrame then
                self._watermarkFrame.Visible = val
            end
        end
    })

    settingsTab.Section({ Title = "Configuration" })

    settingsTab.Button({
        Title = "Reset Config",
        Description = "Wipe all saved settings",
        Callback = function()
            if self.SaveConfig then
                self.Config:Reset()
                self:Notify({ Title = "Config Reset", Description = "All settings have been cleared.", Type = "warning" })
            end
        end
    })

    settingsTab.Button({
        Title = "Export Config",
        Description = "Copy config to clipboard",
        Callback = function()
            if self.SaveConfig then
                local json = self.Config:Export()
                pcall(function() setclipboard(json) end)
                self:Notify({ Title = "Exported!", Description = "Config copied to clipboard.", Type = "success" })
            end
        end
    })

    settingsTab.Section({ Title = "Info" })

    settingsTab.Label({ Title = "Oxygen UI Library v1.0.0" })
    settingsTab.Label({ Title = "Made with ❤ for Roblox" })

    -- Move settings tab to end of tab list
    -- (it was added first so we just visually move it)
    local settingsData = table.remove(self.Tabs, 1)
    table.remove(self.TabButtons, 1)
    table.remove(self.TabPages, 1)
    table.insert(self.Tabs, settingsData)
    table.insert(self.TabButtons, settingsData.Button)
    table.insert(self.TabPages, settingsData.Page)

    -- Fix layout order so settings appears last
    for i, tab in ipairs(self.Tabs) do
        tab.Button.LayoutOrder = i
    end

    -- Switch to first real tab (index 1 after reorder is now settings was moved)
    -- Actually settings is now at the end, so all real tabs come first
    -- We need to re-assign the initial visibility
    if #self.Tabs > 1 then
        self.ActiveTabIndex = 1
        for i, tab in ipairs(self.Tabs) do
            tab.Page.Visible = (i == 1)
        end
        self.SectionTitle.Text = self.Tabs[1].Title
    end
end

-- ============================================================
-- COMPONENT API FACTORY
-- ============================================================
function Oxygen:_MakeTabAPI(tabIndex, page, pageList, theme)
    local api = {}

    -- Helper: make a card container
    local function MakeCard(height)
        local card = Instance.new("Frame")
        card.BackgroundColor3 = theme.Secondary
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, height or 40)
        card.ZIndex = 5
        card.Parent = page
        AddCorner(card, theme.CornerRadius - 2)
        AddStroke(card, theme.Border, 1)
        return card
    end

    -- ── SECTION ──────────────────────────────────────────────
    function api.Section(config)
        local title = config.Title or "Section"

        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, 22)
        frame.ZIndex = 5
        frame.Parent = page

        local bar = Instance.new("Frame")
        bar.BackgroundColor3 = theme.Accent
        bar.BorderSizePixel = 0
        bar.Size = UDim2.fromOffset(3, 14)
        bar.Position = UDim2.fromOffset(0, 4)
        bar.ZIndex = 6
        bar.Parent = frame
        AddCorner(bar, 2)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -12, 1, 0)
        lbl.Position = UDim2.fromOffset(10, 0)
        lbl.Text = title:upper()
        lbl.TextColor3 = theme.TextMuted
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LetterSpacing = 2
        lbl.ZIndex = 6
        lbl.Parent = frame

        return frame
    end

    -- ── LABEL ─────────────────────────────────────────────────
    function api.Label(config)
        local title = config.Title or ""

        local card = MakeCard(30)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -16, 1, 0)
        lbl.Position = UDim2.fromOffset(10, 0)
        lbl.Text = title
        lbl.TextColor3 = theme.TextMuted
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        lbl.ZIndex = 6
        lbl.Parent = card

        local obj = {}
        function obj:Set(text) lbl.Text = text end
        function obj:Get() return lbl.Text end
        return obj
    end

    -- ── BUTTON ────────────────────────────────────────────────
    function api.Button(config)
        local title    = config.Title or "Button"
        local desc     = config.Description or ""
        local callback = config.Callback or function() end
        local tooltip  = config.Tooltip

        local card = MakeCard(desc ~= "" and 54 or 36)
        card.ClipsDescendants = true

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -80, 0, 20)
        titleLbl.Position = UDim2.fromOffset(12, desc ~= "" and 8 or 8)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        if desc ~= "" then
            local descLbl = Instance.new("TextLabel")
            descLbl.BackgroundTransparency = 1
            descLbl.Size = UDim2.new(1, -80, 0, 16)
            descLbl.Position = UDim2.fromOffset(12, 28)
            descLbl.Text = desc
            descLbl.TextColor3 = theme.TextMuted
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 11
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.ZIndex = 6
            descLbl.Parent = card
        end

        -- Action button on right
        local btn = Instance.new("ImageButton")
        btn.BackgroundColor3 = theme.Accent
        btn.BorderSizePixel = 0
        btn.Size = UDim2.fromOffset(60, 26)
        btn.Position = UDim2.new(1, -68, 0.5, -13)
        btn.AutoButtonColor = false
        btn.ZIndex = 7
        btn.Parent = card
        AddCorner(btn, 6)

        local btnLbl = Instance.new("TextLabel")
        btnLbl.BackgroundTransparency = 1
        btnLbl.Size = UDim2.fromScale(1,1)
        btnLbl.Text = "RUN"
        btnLbl.TextColor3 = theme.TextDark
        btnLbl.Font = Enum.Font.GothamBold
        btnLbl.TextSize = 11
        btnLbl.ZIndex = 8
        btnLbl.Parent = btn

        btn.MouseButton1Click:Connect(function()
            Util.Ripple(btn, theme.AccentDark)
            Util.SafeCall(callback)
        end)

        btn.MouseEnter:Connect(function()
            Util.FastTween(btn, { BackgroundColor3 = theme.AccentDark })
        end)
        btn.MouseLeave:Connect(function()
            Util.FastTween(btn, { BackgroundColor3 = theme.Accent })
        end)

        if tooltip then
            AttachTooltip(card, tooltip, theme, self.ScreenGui)
        end

        local obj = {}
        function obj:SetTitle(t) titleLbl.Text = t end
        function obj:SetCallback(fn) callback = fn end
        function obj:SetEnabled(v)
            btn.BackgroundColor3 = v and theme.Accent or theme.Tertiary
            btn.Active = v
        end
        return obj
    end

    -- ── TOGGLE ────────────────────────────────────────────────
    function api.Toggle(config)
        local title    = config.Title or "Toggle"
        local desc     = config.Description or ""
        local default  = config.Default or false
        local callback = config.Callback or function() end
        local tooltip  = config.Tooltip
        local key      = config.ConfigKey

        if key and self.SaveConfig then
            default = self.Config:Get(key, default)
        end

        local state = default
        local card = MakeCard(desc ~= "" and 54 or 36)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -70, 0, 18)
        titleLbl.Position = UDim2.fromOffset(12, desc ~= "" and 8 or 9)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        if desc ~= "" then
            local descLbl = Instance.new("TextLabel")
            descLbl.BackgroundTransparency = 1
            descLbl.Size = UDim2.new(1, -70, 0, 16)
            descLbl.Position = UDim2.fromOffset(12, 28)
            descLbl.Text = desc
            descLbl.TextColor3 = theme.TextMuted
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 11
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.ZIndex = 6
            descLbl.Parent = card
        end

        -- Track
        local track = Instance.new("Frame")
        track.BackgroundColor3 = state and theme.Toggle or theme.Tertiary
        track.BorderSizePixel = 0
        track.Size = UDim2.fromOffset(36, 18)
        track.Position = UDim2.new(1, -46, 0.5, -9)
        track.ZIndex = 7
        track.Parent = card
        AddCorner(track, 9)

        -- Knob
        local knob = Instance.new("Frame")
        knob.BackgroundColor3 = theme.Text
        knob.BorderSizePixel = 0
        knob.Size = UDim2.fromOffset(12, 12)
        knob.Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
        knob.ZIndex = 8
        knob.Parent = track
        AddCorner(knob, 6)

        local function updateToggle(val)
            state = val
            Util.FastTween(track, { BackgroundColor3 = val and theme.Toggle or theme.Tertiary })
            Util.FastTween(knob, { Position = val and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) })
            Util.SafeCall(callback, val)
            if key and self.SaveConfig then
                self.Config:Set(key, val)
            end
        end

        -- Fire initial callback
        task.defer(function() Util.SafeCall(callback, state) end)

        local clickArea = Instance.new("TextButton")
        clickArea.BackgroundTransparency = 1
        clickArea.Size = UDim2.fromScale(1,1)
        clickArea.Text = ""
        clickArea.ZIndex = 9
        clickArea.Parent = card
        clickArea.MouseButton1Click:Connect(function()
            updateToggle(not state)
        end)

        if tooltip then AttachTooltip(card, tooltip, theme, self.ScreenGui) end

        local obj = {}
        function obj:Set(val) updateToggle(val) end
        function obj:Get() return state end
        function obj:SetTitle(t) titleLbl.Text = t end
        return obj
    end

    -- ── SLIDER ────────────────────────────────────────────────
    function api.Slider(config)
        local title     = config.Title or "Slider"
        local desc      = config.Description or ""
        local min       = config.Min or 0
        local max       = config.Max or 100
        local default   = config.Default or min
        local precision = config.Precision or 0
        local suffix    = config.Suffix or ""
        local callback  = config.Callback or function() end
        local key       = config.ConfigKey

        if key and self.SaveConfig then
            default = self.Config:Get(key, default)
        end

        default = math.clamp(default, min, max)
        local value = default

        local card = MakeCard(desc ~= "" and 66 or 52)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -80, 0, 18)
        titleLbl.Position = UDim2.fromOffset(12, 8)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        local valueLbl = Instance.new("TextLabel")
        valueLbl.BackgroundTransparency = 1
        valueLbl.Size = UDim2.fromOffset(70, 18)
        valueLbl.Position = UDim2.new(1, -78, 0, 8)
        valueLbl.Text = tostring(value) .. suffix
        valueLbl.TextColor3 = theme.Accent
        valueLbl.Font = Enum.Font.GothamBold
        valueLbl.TextSize = 13
        valueLbl.TextXAlignment = Enum.TextXAlignment.Right
        valueLbl.ZIndex = 6
        valueLbl.Parent = card

        if desc ~= "" then
            local descLbl = Instance.new("TextLabel")
            descLbl.BackgroundTransparency = 1
            descLbl.Size = UDim2.new(1, -20, 0, 14)
            descLbl.Position = UDim2.fromOffset(12, 26)
            descLbl.Text = desc
            descLbl.TextColor3 = theme.TextMuted
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 11
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.ZIndex = 6
            descLbl.Parent = card
        end

        -- Track
        local trackY = desc ~= "" and 48 or 34
        local trackBG = Instance.new("Frame")
        trackBG.BackgroundColor3 = theme.Tertiary
        trackBG.BorderSizePixel = 0
        trackBG.Size = UDim2.new(1, -24, 0, 4)
        trackBG.Position = UDim2.fromOffset(12, trackY)
        trackBG.ZIndex = 6
        trackBG.Parent = card
        AddCorner(trackBG, 2)

        local defaultScale = (default - min) / math.max(max - min, 0.001)

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = theme.Slider
        fill.BorderSizePixel = 0
        fill.Size = UDim2.fromScale(defaultScale, 1)
        fill.ZIndex = 7
        fill.Parent = trackBG
        AddCorner(fill, 2)

        local knob = Instance.new("Frame")
        knob.BackgroundColor3 = theme.Text
        knob.BorderSizePixel = 0
        knob.Size = UDim2.fromOffset(14, 14)
        knob.Position = UDim2.new(defaultScale, -7, 0.5, -7)
        knob.ZIndex = 8
        knob.Parent = trackBG
        AddCorner(knob, 7)
        MakeShadow(knob, theme.Shadow)
        AddStroke(knob, theme.Slider, 2)

        local dragging = false

        local function updateSlider(scale)
            scale = math.clamp(scale, 0, 1)
            local mult = 10 ^ precision
            local v = math.floor((min + (max - min) * scale) * mult + 0.5) / mult
            value = v
            Util.FastTween(fill, { Size = UDim2.fromScale(scale, 1) })
            Util.FastTween(knob, { Position = UDim2.new(scale, -7, 0.5, -7) })
            valueLbl.Text = tostring(v) .. suffix
            Util.SafeCall(callback, v)
            if key and self.SaveConfig then
                self.Config:Set(key, v)
            end
        end

        local clickBtn = Instance.new("TextButton")
        clickBtn.BackgroundTransparency = 1
        clickBtn.Size = UDim2.fromScale(1,1)
        clickBtn.Text = ""
        clickBtn.ZIndex = 9
        clickBtn.Parent = trackBG

        clickBtn.MouseButton1Down:Connect(function()
            dragging = true
            local px, _ = Util.GetMouseXY(trackBG)
            updateSlider(px)
        end)
        AddConn(UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local px, _ = Util.GetMouseXY(trackBG)
                updateSlider(px)
            end
        end))
        AddConn(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))

        task.defer(function() Util.SafeCall(callback, value) end)

        local obj = {}
        function obj:Set(v)
            v = math.clamp(v, min, max)
            updateSlider((v - min) / math.max(max - min, 0.001))
        end
        function obj:Get() return value end
        function obj:SetMin(v) min = v end
        function obj:SetMax(v) max = v end
        function obj:SetTitle(t) titleLbl.Text = t end
        return obj
    end

    -- ── DROPDOWN ──────────────────────────────────────────────
    function api.Dropdown(config)
        local title    = config.Title or "Dropdown"
        local desc     = config.Description or ""
        local options  = config.Options or {}
        local default  = config.Default
        local multi    = config.Multi or false
        local callback = config.Callback or function() end
        local key      = config.ConfigKey

        if key and self.SaveConfig then
            default = self.Config:Get(key, default)
        end

        local selected = multi and {} or default
        local open = false

        local baseH = desc ~= "" and 54 or 40
        local card = MakeCard(baseH)
        card.ClipsDescendants = false
        card.ZIndex = 20

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -20, 0, 18)
        titleLbl.Position = UDim2.fromOffset(12, desc ~= "" and 8 or 11)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 21
        titleLbl.Parent = card

        if desc ~= "" then
            local descLbl = Instance.new("TextLabel")
            descLbl.BackgroundTransparency = 1
            descLbl.Size = UDim2.new(1, -20, 0, 14)
            descLbl.Position = UDim2.fromOffset(12, 28)
            descLbl.Text = desc
            descLbl.TextColor3 = theme.TextMuted
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 11
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.ZIndex = 21
            descLbl.Parent = card
        end

        local valueLbl = Instance.new("TextLabel")
        valueLbl.BackgroundTransparency = 1
        valueLbl.Size = UDim2.new(1, -30, 0, 18)
        valueLbl.Position = UDim2.new(0, 12, 1, -(desc ~= "" and 26 or 28))
        valueLbl.Text = default and tostring(default) or "Select..."
        valueLbl.TextColor3 = theme.Accent
        valueLbl.Font = Enum.Font.Gotham
        valueLbl.TextSize = 12
        valueLbl.TextXAlignment = Enum.TextXAlignment.Left
        valueLbl.ZIndex = 21
        valueLbl.Parent = card

        -- Arrow
        local arrow = Instance.new("TextLabel")
        arrow.BackgroundTransparency = 1
        arrow.Size = UDim2.fromOffset(20, 20)
        arrow.Position = UDim2.new(1, -26, 0.5, -10)
        arrow.Text = "▾"
        arrow.TextColor3 = theme.TextMuted
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 14
        arrow.ZIndex = 21
        arrow.Parent = card

        -- Dropdown panel
        local panelH = math.min(#options * 30 + 8, 180)
        local panel = Instance.new("Frame")
        panel.BackgroundColor3 = theme.Secondary
        panel.BorderSizePixel = 0
        panel.Size = UDim2.new(1, 0, 0, 0)
        panel.Position = UDim2.new(0, 0, 1, 4)
        panel.ClipsDescendants = true
        panel.ZIndex = 50
        panel.Parent = card
        AddCorner(panel, 6)
        AddStroke(panel, theme.Border, 1)
        MakeShadow(panel, theme.Shadow)

        -- Search box inside panel
        local searchBox = Instance.new("TextBox")
        searchBox.BackgroundColor3 = theme.Tertiary
        searchBox.BorderSizePixel = 0
        searchBox.Size = UDim2.new(1, -8, 0, 24)
        searchBox.Position = UDim2.fromOffset(4, 4)
        searchBox.PlaceholderText = "Search..."
        searchBox.PlaceholderColor3 = theme.TextMuted
        searchBox.Text = ""
        searchBox.TextColor3 = theme.Text
        searchBox.Font = Enum.Font.Gotham
        searchBox.TextSize = 12
        searchBox.ClearTextOnFocus = false
        searchBox.ZIndex = 51
        searchBox.Parent = panel
        AddCorner(searchBox, 4)
        AddPadding(searchBox, 0, 6, 0, 6)

        local scroll = Instance.new("ScrollingFrame")
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.Size = UDim2.new(1, 0, 1, -32)
        scroll.Position = UDim2.fromOffset(0, 30)
        scroll.CanvasSize = UDim2.fromScale(0,0)
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = theme.Accent
        scroll.ZIndex = 51
        scroll.Parent = panel
        AddPadding(scroll, 2, 4, 2, 4)

        local scrollList = AddList(scroll, nil, nil, nil, 2)
        scrollList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.fromOffset(0, scrollList.AbsoluteContentSize.Y + 4)
        end)

        local optionButtons = {}

        local function buildOptions(filter)
            for _, b in ipairs(optionButtons) do b:Destroy() end
            optionButtons = {}

            for _, opt in ipairs(options) do
                local optStr = tostring(opt)
                if filter == "" or optStr:lower():find(filter:lower(), 1, true) then
                    local isSelected = multi and Util.TableContains(selected, opt) or (selected == opt)

                    local optBtn = Instance.new("TextButton")
                    optBtn.BackgroundColor3 = isSelected and theme.Accent or theme.Tertiary
                    optBtn.BorderSizePixel = 0
                    optBtn.Size = UDim2.new(1, 0, 0, 26)
                    optBtn.Text = ""
                    optBtn.ZIndex = 52
                    optBtn.Parent = scroll
                    AddCorner(optBtn, 4)

                    local optLbl = Instance.new("TextLabel")
                    optLbl.BackgroundTransparency = 1
                    optLbl.Size = UDim2.new(1, -10, 1, 0)
                    optLbl.Position = UDim2.fromOffset(8, 0)
                    optLbl.Text = optStr
                    optLbl.TextColor3 = isSelected and theme.TextDark or theme.Text
                    optLbl.Font = Enum.Font.Gotham
                    optLbl.TextSize = 12
                    optLbl.TextXAlignment = Enum.TextXAlignment.Left
                    optLbl.ZIndex = 53
                    optLbl.Parent = optBtn

                    optBtn.MouseButton1Click:Connect(function()
                        if multi then
                            if Util.TableContains(selected, opt) then
                                for i, v in ipairs(selected) do
                                    if v == opt then table.remove(selected, i) break end
                                end
                            else
                                table.insert(selected, opt)
                            end
                            valueLbl.Text = #selected > 0 and table.concat(selected, ", ") or "Select..."
                            Util.SafeCall(callback, selected)
                        else
                            selected = opt
                            valueLbl.Text = optStr
                            Util.SafeCall(callback, opt)
                            -- close
                            open = false
                            Util.FastTween(panel, { Size = UDim2.new(1, 0, 0, 0) })
                            Util.FastTween(arrow, { Rotation = 0 })
                        end
                        if key and self.SaveConfig then
                            self.Config:Set(key, selected)
                        end
                        buildOptions(searchBox.Text)
                    end)

                    optBtn.MouseEnter:Connect(function()
                        if not (not multi and selected == opt) then
                            Util.FastTween(optBtn, { BackgroundColor3 = theme.Accent })
                            Util.FastTween(optLbl, { TextColor3 = theme.TextDark })
                        end
                    end)
                    optBtn.MouseLeave:Connect(function()
                        local isSel = multi and Util.TableContains(selected, opt) or (selected == opt)
                        Util.FastTween(optBtn, { BackgroundColor3 = isSel and theme.Accent or theme.Tertiary })
                        Util.FastTween(optLbl, { TextColor3 = isSel and theme.TextDark or theme.Text })
                    end)

                    table.insert(optionButtons, optBtn)
                end
            end
        end

        buildOptions("")

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            buildOptions(searchBox.Text)
        end)

        local clickBtn = Instance.new("TextButton")
        clickBtn.BackgroundTransparency = 1
        clickBtn.Size = UDim2.fromOffset(card.AbsoluteSize.X, baseH)
        clickBtn.Text = ""
        clickBtn.ZIndex = 22
        clickBtn.Parent = card

        clickBtn.MouseButton1Click:Connect(function()
            open = not open
            Util.FastTween(panel, { Size = UDim2.new(1, 0, 0, open and panelH or 0) })
            Util.FastTween(arrow, { Rotation = open and 180 or 0 })
            if open then searchBox:CaptureFocus() end
        end)

        local obj = {}
        function obj:Set(val) selected = val; valueLbl.Text = tostring(val) end
        function obj:Get() return selected end
        function obj:SetOptions(opts)
            options = opts
            buildOptions(searchBox.Text)
        end
        return obj
    end

    -- ── KEYBIND ───────────────────────────────────────────────
    function api.Keybind(config)
        local title    = config.Title or "Keybind"
        local desc     = config.Description or ""
        local default  = config.Default or Enum.KeyCode.Unknown
        local callback = config.Callback or function() end
        local key      = config.ConfigKey

        local bound = default
        local listening = false

        local card = MakeCard(desc ~= "" and 54 or 36)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -100, 0, 18)
        titleLbl.Position = UDim2.fromOffset(12, desc ~= "" and 8 or 9)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        if desc ~= "" then
            local descLbl = Instance.new("TextLabel")
            descLbl.BackgroundTransparency = 1
            descLbl.Size = UDim2.new(1, -100, 0, 14)
            descLbl.Position = UDim2.fromOffset(12, 28)
            descLbl.Text = desc
            descLbl.TextColor3 = theme.TextMuted
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 11
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.ZIndex = 6
            descLbl.Parent = card
        end

        local keyBtn = Instance.new("TextButton")
        keyBtn.BackgroundColor3 = theme.Tertiary
        keyBtn.BorderSizePixel = 0
        keyBtn.Size = UDim2.fromOffset(80, 24)
        keyBtn.Position = UDim2.new(1, -88, 0.5, -12)
        keyBtn.Text = bound.Name
        keyBtn.TextColor3 = theme.Accent
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.TextSize = 12
        keyBtn.ZIndex = 7
        keyBtn.Parent = card
        AddCorner(keyBtn, 6)
        AddStroke(keyBtn, theme.Border, 1)

        keyBtn.MouseButton1Click:Connect(function()
            listening = true
            keyBtn.Text = "..."
            keyBtn.TextColor3 = theme.Warning
        end)

        AddConn(UserInputService.InputBegan:Connect(function(input, processed)
            if not listening then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                bound = input.KeyCode
                keyBtn.Text = bound.Name
                keyBtn.TextColor3 = theme.Accent
                listening = false
                Util.SafeCall(callback, bound)
                if key and self.SaveConfig then
                    self.Config:Set(key, bound.Name)
                end
            end
        end))

        local obj = {}
        function obj:Get() return bound end
        function obj:Set(kc) bound = kc; keyBtn.Text = kc.Name end
        return obj
    end

    -- ── TEXT INPUT ────────────────────────────────────────────
    function api.TextInput(config)
        local title       = config.Title or "Input"
        local desc        = config.Description or ""
        local placeholder = config.Placeholder or "Enter text..."
        local default     = config.Default or ""
        local callback    = config.Callback or function() end
        local numeric     = config.Numeric or false
        local maxLength   = config.MaxLength or 200
        local key         = config.ConfigKey

        if key and self.SaveConfig then
            default = self.Config:Get(key, default)
        end

        local card = MakeCard(desc ~= "" and 68 or 54)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -16, 0, 16)
        titleLbl.Position = UDim2.fromOffset(12, 6)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 13
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        if desc ~= "" then
            local descLbl = Instance.new("TextLabel")
            descLbl.BackgroundTransparency = 1
            descLbl.Size = UDim2.new(1, -16, 0, 13)
            descLbl.Position = UDim2.fromOffset(12, 22)
            descLbl.Text = desc
            descLbl.TextColor3 = theme.TextMuted
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 10
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.ZIndex = 6
            descLbl.Parent = card
        end

        local inputY = desc ~= "" and 38 or 26
        local inputFrame = Instance.new("Frame")
        inputFrame.BackgroundColor3 = theme.Tertiary
        inputFrame.BorderSizePixel = 0
        inputFrame.Size = UDim2.new(1, -16, 0, 24)
        inputFrame.Position = UDim2.fromOffset(8, inputY)
        inputFrame.ZIndex = 6
        inputFrame.Parent = card
        AddCorner(inputFrame, 5)
        AddStroke(inputFrame, theme.Border, 1)

        local box = Instance.new("TextBox")
        box.BackgroundTransparency = 1
        box.Size = UDim2.new(1, -8, 1, 0)
        box.Position = UDim2.fromOffset(6, 0)
        box.Text = default
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = theme.TextMuted
        box.TextColor3 = theme.Text
        box.Font = Enum.Font.Gotham
        box.TextSize = 12
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.ZIndex = 7
        box.Parent = inputFrame

        -- Char counter
        local counter = Instance.new("TextLabel")
        counter.BackgroundTransparency = 1
        counter.Size = UDim2.fromOffset(40, 20)
        counter.Position = UDim2.new(1, -46, 0, 2)
        counter.Text = "0/" .. maxLength
        counter.TextColor3 = theme.TextMuted
        counter.Font = Enum.Font.Gotham
        counter.TextSize = 9
        counter.TextXAlignment = Enum.TextXAlignment.Right
        counter.ZIndex = 7
        counter.Parent = inputFrame

        box:GetPropertyChangedSignal("Text"):Connect(function()
            if numeric then
                box.Text = box.Text:gsub("[^%d%.%-]", "")
            end
            if #box.Text > maxLength then
                box.Text = box.Text:sub(1, maxLength)
            end
            counter.Text = #box.Text .. "/" .. maxLength
        end)

        box.Focused:Connect(function()
            Util.FastTween(inputFrame, { BackgroundColor3 = Util.LerpColor(theme.Tertiary, theme.Accent, 0.15) })
            AddStroke(inputFrame, theme.Accent, 1):Destroy() -- replace stroke
            pcall(function()
                inputFrame:FindFirstChildWhichIsA("UIStroke"):Destroy()
            end)
            AddStroke(inputFrame, theme.Accent, 1)
        end)

        box.FocusLost:Connect(function(enter)
            Util.FastTween(inputFrame, { BackgroundColor3 = theme.Tertiary })
            pcall(function()
                inputFrame:FindFirstChildWhichIsA("UIStroke"):Destroy()
            end)
            AddStroke(inputFrame, theme.Border, 1)
            if enter then
                Util.SafeCall(callback, box.Text)
                if key and self.SaveConfig then
                    self.Config:Set(key, box.Text)
                end
            end
        end)

        local obj = {}
        function obj:Get() return box.Text end
        function obj:Set(t) box.Text = t end
        function obj:SetTitle(t) titleLbl.Text = t end
        return obj
    end

    -- ── COLOR PICKER ──────────────────────────────────────────
    function api.ColorPicker(config)
        local title    = config.Title or "Color"
        local default  = config.Default or Color3.fromRGB(255, 100, 100)
        local callback = config.Callback or function() end

        local h, s, v = Color3.toHSV(default)
        local open = false

        local card = MakeCard(36)
        card.ClipsDescendants = false

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -60, 1, 0)
        titleLbl.Position = UDim2.fromOffset(12, 0)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        -- Color preview
        local preview = Instance.new("Frame")
        preview.BackgroundColor3 = default
        preview.BorderSizePixel = 0
        preview.Size = UDim2.fromOffset(50, 22)
        preview.Position = UDim2.new(1, -58, 0.5, -11)
        preview.ZIndex = 7
        preview.Parent = card
        AddCorner(preview, 5)
        AddStroke(preview, theme.Border, 1)

        -- Hex label inside preview
        local hexLbl = Instance.new("TextLabel")
        hexLbl.BackgroundTransparency = 1
        hexLbl.Size = UDim2.fromScale(1, 1)
        hexLbl.Text = Util.ColorToHex(default)
        hexLbl.TextColor3 = Util.GetContrastColor(default)
        hexLbl.Font = Enum.Font.Code
        hexLbl.TextSize = 9
        hexLbl.ZIndex = 8
        hexLbl.Parent = preview

        -- Expanded picker panel
        local pickerPanel = Instance.new("Frame")
        pickerPanel.BackgroundColor3 = theme.Secondary
        pickerPanel.BorderSizePixel = 0
        pickerPanel.Size = UDim2.new(1, 0, 0, 0)
        pickerPanel.Position = UDim2.new(0, 0, 1, 4)
        pickerPanel.ClipsDescendants = true
        pickerPanel.ZIndex = 30
        pickerPanel.Parent = card
        AddCorner(pickerPanel, 6)
        AddStroke(pickerPanel, theme.Border, 1)

        local function updateColor()
            local color = Color3.fromHSV(h, s, v)
            preview.BackgroundColor3 = color
            hexLbl.TextColor3 = Util.GetContrastColor(color)
            hexLbl.Text = Util.ColorToHex(color)
            Util.SafeCall(callback, color)
        end

        -- SV square
        local svSquare = Instance.new("ImageLabel")
        svSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svSquare.BorderSizePixel = 0
        svSquare.Size = UDim2.new(1, -16, 0, 100)
        svSquare.Position = UDim2.fromOffset(8, 8)
        svSquare.ZIndex = 31
        svSquare.Image = "rbxassetid://4155801252"
        svSquare.Parent = pickerPanel
        AddCorner(svSquare, 4)

        -- Hue bar
        local hueBar = Instance.new("ImageLabel")
        hueBar.BackgroundColor3 = Color3.new(1,0,0)
        hueBar.BorderSizePixel = 0
        hueBar.Size = UDim2.new(1, -16, 0, 12)
        hueBar.Position = UDim2.fromOffset(8, 116)
        hueBar.Image = "rbxassetid://698052001"
        hueBar.ZIndex = 31
        hueBar.Parent = pickerPanel
        AddCorner(hueBar, 3)

        -- Hex input
        local hexInput = Instance.new("TextBox")
        hexInput.BackgroundColor3 = theme.Tertiary
        hexInput.BorderSizePixel = 0
        hexInput.Size = UDim2.new(1, -16, 0, 22)
        hexInput.Position = UDim2.fromOffset(8, 136)
        hexInput.Text = Util.ColorToHex(default)
        hexInput.PlaceholderText = "#FFFFFF"
        hexInput.PlaceholderColor3 = theme.TextMuted
        hexInput.TextColor3 = theme.Text
        hexInput.Font = Enum.Font.Code
        hexInput.TextSize = 12
        hexInput.ClearTextOnFocus = false
        hexInput.ZIndex = 31
        hexInput.Parent = pickerPanel
        AddCorner(hexInput, 4)

        -- SV knob
        local svKnob = Instance.new("Frame")
        svKnob.BackgroundColor3 = Color3.new(1,1,1)
        svKnob.BorderSizePixel = 0
        svKnob.Size = UDim2.fromOffset(10, 10)
        svKnob.ZIndex = 32
        svKnob.Parent = svSquare
        AddCorner(svKnob, 5)
        AddStroke(svKnob, Color3.new(1,1,1), 1)

        local hueKnob = Instance.new("Frame")
        hueKnob.BackgroundColor3 = Color3.new(1,1,1)
        hueKnob.BorderSizePixel = 0
        hueKnob.Size = UDim2.fromOffset(4, 14)
        hueKnob.ZIndex = 32
        hueKnob.Parent = hueBar
        AddCorner(hueKnob, 2)

        local function refreshKnobs()
            svKnob.Position = UDim2.new(s, -5, 1-v, -5)
            hueKnob.Position = UDim2.new(1-h, -2, 0, -1)
            svSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        end
        refreshKnobs()

        -- SV drag
        local svDragging = false
        local svBtn = Instance.new("TextButton")
        svBtn.BackgroundTransparency = 1
        svBtn.Size = UDim2.fromScale(1,1)
        svBtn.Text = ""
        svBtn.ZIndex = 33
        svBtn.Parent = svSquare

        svBtn.MouseButton1Down:Connect(function()
            svDragging = true
            local px, py = Util.GetMouseXY(svSquare)
            s, v = px, 1 - py
            refreshKnobs()
            updateColor()
        end)
        AddConn(UserInputService.InputChanged:Connect(function(i)
            if svDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local px, py = Util.GetMouseXY(svSquare)
                s, v = math.clamp(px,0,1), math.clamp(1-py,0,1)
                refreshKnobs()
                updateColor()
            end
        end))
        AddConn(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
        end))

        -- Hue drag
        local hueDragging = false
        local hueBtn = Instance.new("TextButton")
        hueBtn.BackgroundTransparency = 1
        hueBtn.Size = UDim2.fromScale(1,1)
        hueBtn.Text = ""
        hueBtn.ZIndex = 33
        hueBtn.Parent = hueBar

        hueBtn.MouseButton1Down:Connect(function()
            hueDragging = true
            local px, _ = Util.GetMouseXY(hueBar)
            h = 1 - px
            refreshKnobs()
            updateColor()
        end)
        AddConn(UserInputService.InputChanged:Connect(function(i)
            if hueDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local px, _ = Util.GetMouseXY(hueBar)
                h = math.clamp(1-px, 0, 1)
                refreshKnobs()
                updateColor()
            end
        end))
        AddConn(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
        end))

        hexInput.FocusLost:Connect(function()
            local ok, color = pcall(Util.HexToColor, hexInput.Text)
            if ok then
                h, s, v = Color3.toHSV(color)
                refreshKnobs()
                updateColor()
            end
        end)

        -- Toggle panel
        local clickBtn = Instance.new("TextButton")
        clickBtn.BackgroundTransparency = 1
        clickBtn.Size = UDim2.fromScale(1,1)
        clickBtn.Text = ""
        clickBtn.ZIndex = 8
        clickBtn.Parent = card
        clickBtn.MouseButton1Click:Connect(function()
            open = not open
            Util.FastTween(pickerPanel, { Size = UDim2.new(1, 0, 0, open and 166 or 0) })
        end)

        local obj = {}
        function obj:Get() return Color3.fromHSV(h,s,v) end
        function obj:Set(color)
            h, s, v = Color3.toHSV(color)
            refreshKnobs()
            updateColor()
        end
        return obj
    end

    -- ── PROGRESS BAR ──────────────────────────────────────────
    function api.ProgressBar(config)
        local title    = config.Title or "Progress"
        local initial  = config.Value or 0
        local max      = config.Max or 100
        local suffix   = config.Suffix or "%"

        local card = MakeCard(46)
        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -60, 0, 16)
        titleLbl.Position = UDim2.fromOffset(12, 6)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 13
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        local valLbl = Instance.new("TextLabel")
        valLbl.BackgroundTransparency = 1
        valLbl.Size = UDim2.fromOffset(55, 16)
        valLbl.Position = UDim2.new(1, -63, 0, 6)
        valLbl.Text = tostring(initial) .. suffix
        valLbl.TextColor3 = theme.Accent
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 12
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.ZIndex = 6
        valLbl.Parent = card

        local track = Instance.new("Frame")
        track.BackgroundColor3 = theme.Tertiary
        track.BorderSizePixel = 0
        track.Size = UDim2.new(1, -16, 0, 6)
        track.Position = UDim2.fromOffset(8, 30)
        track.ZIndex = 6
        track.Parent = card
        AddCorner(track, 3)

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = theme.Accent
        fill.BorderSizePixel = 0
        fill.Size = UDim2.fromScale(math.clamp(initial/max,0,1), 1)
        fill.ZIndex = 7
        fill.Parent = track
        AddCorner(fill, 3)

        -- Shimmer animation
        local shimmer = Instance.new("Frame")
        shimmer.BackgroundColor3 = Color3.new(1,1,1)
        shimmer.BackgroundTransparency = 0.7
        shimmer.BorderSizePixel = 0
        shimmer.Size = UDim2.fromOffset(30, 6)
        shimmer.ZIndex = 8
        shimmer.ClipsDescendants = false
        shimmer.Parent = fill

        task.spawn(function()
            while fill.Parent do
                shimmer.Position = UDim2.fromScale(-0.3, 0)
                Util.Tween(shimmer, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Position = UDim2.fromScale(1.3, 0) })
                task.wait(2)
            end
        end)

        local obj = {}
        function obj:Set(val)
            local scale = math.clamp(val / math.max(max, 0.001), 0, 1)
            Util.FastTween(fill, { Size = UDim2.fromScale(scale, 1) }, 0.3)
            valLbl.Text = tostring(Util.Round(val, 1)) .. suffix
        end
        function obj:SetTitle(t) titleLbl.Text = t end
        return obj
    end

    -- ── SEPARATOR ─────────────────────────────────────────────
    function api.Separator(config)
        local text = config and config.Text or ""
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, 16)
        frame.ZIndex = 5
        frame.Parent = page

        local line = Instance.new("Frame")
        line.BackgroundColor3 = theme.Border
        line.BorderSizePixel = 0
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.fromOffset(0, 8)
        line.ZIndex = 6
        line.Parent = frame

        if text ~= "" then
            local bg = Instance.new("Frame")
            bg.BackgroundColor3 = theme.Primary
            bg.BorderSizePixel = 0
            bg.Size = UDim2.fromOffset(#text * 7 + 10, 14)
            bg.Position = UDim2.new(0.5, -math.floor(#text * 3.5 + 5), 0, 1)
            bg.ZIndex = 7
            bg.Parent = frame

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.fromScale(1,1)
            lbl.Text = text
            lbl.TextColor3 = theme.TextMuted
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 10
            lbl.ZIndex = 8
            lbl.Parent = bg
        end

        return frame
    end

    -- ── STEPPER ───────────────────────────────────────────────
    function api.Stepper(config)
        local title    = config.Title or "Stepper"
        local min      = config.Min or 0
        local max      = config.Max or 10
        local default  = config.Default or min
        local step     = config.Step or 1
        local callback = config.Callback or function() end

        local value = math.clamp(default, min, max)
        local card = MakeCard(36)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -110, 1, 0)
        titleLbl.Position = UDim2.fromOffset(12, 0)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.Text
        titleLbl.Font = theme.Font
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        local function makeStepBtn(symbol, xOff)
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = theme.Tertiary
            btn.BorderSizePixel = 0
            btn.Size = UDim2.fromOffset(26, 24)
            btn.Position = UDim2.new(1, xOff, 0.5, -12)
            btn.Text = symbol
            btn.TextColor3 = theme.Accent
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 16
            btn.ZIndex = 7
            btn.Parent = card
            AddCorner(btn, 5)
            return btn
        end

        local minusBtn = makeStepBtn("−", -104)
        local valLbl = Instance.new("TextLabel")
        valLbl.BackgroundTransparency = 1
        valLbl.Size = UDim2.fromOffset(44, 24)
        valLbl.Position = UDim2.new(1, -76, 0.5, -12)
        valLbl.Text = tostring(value)
        valLbl.TextColor3 = theme.Text
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 14
        valLbl.ZIndex = 7
        valLbl.Parent = card

        local plusBtn = makeStepBtn("+", -30)

        local function update(v)
            value = math.clamp(v, min, max)
            valLbl.Text = tostring(value)
            Util.SafeCall(callback, value)
        end

        minusBtn.MouseButton1Click:Connect(function() update(value - step) end)
        plusBtn.MouseButton1Click:Connect(function() update(value + step) end)

        local obj = {}
        function obj:Get() return value end
        function obj:Set(v) update(v) end
        return obj
    end

    -- ── RADIO GROUP ───────────────────────────────────────────
    function api.RadioGroup(config)
        local title    = config.Title or "Select one"
        local options  = config.Options or {}
        local default  = config.Default or options[1]
        local callback = config.Callback or function() end

        local selected = default
        local totalH = 30 + #options * 32

        local card = MakeCard(totalH)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, -16, 0, 22)
        titleLbl.Position = UDim2.fromOffset(12, 4)
        titleLbl.Text = title
        titleLbl.TextColor3 = theme.TextMuted
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        titleLbl.Parent = card

        local radioButtons = {}

        for i, opt in ipairs(options) do
            local row = Instance.new("TextButton")
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, -16, 0, 28)
            row.Position = UDim2.fromOffset(8, 22 + (i-1)*30)
            row.Text = ""
            row.ZIndex = 6
            row.Parent = card

            local ring = Instance.new("Frame")
            ring.BackgroundTransparency = 1
            ring.BorderSizePixel = 0
            ring.Size = UDim2.fromOffset(18, 18)
            ring.Position = UDim2.fromOffset(4, 5)
            ring.ZIndex = 7
            ring.Parent = row
            AddCorner(ring, 9)
            AddStroke(ring, opt == default and theme.Accent or theme.Border, 2)

            local dot = Instance.new("Frame")
            dot.BackgroundColor3 = theme.Accent
            dot.BorderSizePixel = 0
            dot.Size = UDim2.fromOffset(opt == default and 10 or 0, opt == default and 10 or 0)
            dot.Position = UDim2.fromOffset(opt == default and 4 or 9, opt == default and 4 or 9)
            dot.ZIndex = 8
            dot.Parent = ring
            AddCorner(dot, 5)

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, -28, 1, 0)
            lbl.Position = UDim2.fromOffset(26, 0)
            lbl.Text = tostring(opt)
            lbl.TextColor3 = opt == default and theme.Text or theme.TextMuted
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 7
            lbl.Parent = row

            table.insert(radioButtons, { Row = row, Ring = ring, Dot = dot, Lbl = lbl, Opt = opt })

            row.MouseButton1Click:Connect(function()
                selected = opt
                for _, rb in ipairs(radioButtons) do
                    local active = rb.Opt == opt
                    pcall(function()
                        rb.Ring:FindFirstChildWhichIsA("UIStroke"):Destroy()
                    end)
                    AddStroke(rb.Ring, active and theme.Accent or theme.Border, 2)
                    Util.FastTween(rb.Dot, {
                        Size = active and UDim2.fromOffset(10,10) or UDim2.fromOffset(0,0),
                        Position = active and UDim2.fromOffset(4,4) or UDim2.fromOffset(9,9)
                    })
                    Util.FastTween(rb.Lbl, { TextColor3 = active and theme.Text or theme.TextMuted })
                end
                Util.SafeCall(callback, opt)
            end)
        end

        local obj = {}
        function obj:Get() return selected end
        return obj
    end

    -- ── BADGE ─────────────────────────────────────────────────
    function api.Badge(config)
        local items    = config.Items or {}
        local badgeH   = 36

        local card = MakeCard(badgeH)
        local container = Instance.new("Frame")
        container.BackgroundTransparency = 1
        container.Size = UDim2.fromScale(1,1)
        container.ZIndex = 6
        container.Parent = card
        AddPadding(container, 6, 6, 6, 8)
        AddList(container, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center, 4)

        for _, item in ipairs(items) do
            local chip = Instance.new("Frame")
            chip.BackgroundColor3 = item.Color or theme.Accent
            chip.BorderSizePixel = 0
            chip.Size = UDim2.fromOffset(0, 22)
            chip.ZIndex = 7
            chip.AutomaticSize = Enum.AutomaticSize.X
            chip.Parent = container
            AddCorner(chip, 11)
            AddPadding(chip, 3, 8, 3, 8)

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.fromScale(1,1)
            lbl.AutomaticSize = Enum.AutomaticSize.X
            lbl.Text = tostring(item.Text or "")
            lbl.TextColor3 = item.TextColor or Util.GetContrastColor(item.Color or theme.Accent)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.ZIndex = 8
            lbl.Parent = chip
        end

        return card
    end

    -- ── IMAGE ─────────────────────────────────────────────────
    function api.Image(config)
        local imageId = config.ID or ""
        local height  = config.Height or 120
        local caption = config.Caption or ""

        local totalH = height + (caption ~= "" and 28 or 8)
        local card = MakeCard(totalH)

        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(1, -16, 0, height)
        img.Position = UDim2.fromOffset(8, 6)
        img.Image = "rbxassetid://" .. imageId
        img.ScaleType = Enum.ScaleType.Fit
        img.ZIndex = 6
        img.Parent = card
        AddCorner(img, 4)

        if caption ~= "" then
            local capLbl = Instance.new("TextLabel")
            capLbl.BackgroundTransparency = 1
            capLbl.Size = UDim2.new(1, -16, 0, 20)
            capLbl.Position = UDim2.fromOffset(8, height + 8)
            capLbl.Text = caption
            capLbl.TextColor3 = theme.TextMuted
            capLbl.Font = Enum.Font.Gotham
            capLbl.TextSize = 11
            capLbl.ZIndex = 6
            capLbl.Parent = card
        end

        local obj = {}
        function obj:SetImage(id) img.Image = "rbxassetid://" .. id end
        function obj:SetCaption(t)
            if caption ~= "" then
                card:FindFirstChild("TextLabel").Text = t
            end
        end
        return obj
    end

    return api
end

-- ============================================================
-- DESTROY / CLEANUP
-- ============================================================
function Oxygen:Destroy()
    Util.SlowTween(self.MainFrame, { Size = UDim2.fromOffset(0, 0) }, 0.3)
    task.delay(0.35, function()
        for _, conn in ipairs(_Connections) do
            pcall(function() conn:Disconnect() end)
        end
        _Connections = {}
        if self.ScreenGui and self.ScreenGui.Parent then
            self.ScreenGui:Destroy()
        end
    end)
end

-- ============================================================
-- PUBLIC API
-- ============================================================
Oxygen.Themes = Themes
Oxygen.Version = "1.0.0"

function Oxygen:GetThemeNames()
    local names = {}
    for k in pairs(Themes) do table.insert(names, k) end
    table.sort(names)
    return names
end

function Oxygen:AddTheme(name, themeData)
    Themes[name] = themeData
end

return Oxygen