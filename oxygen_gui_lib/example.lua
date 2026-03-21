--[[
╔══════════════════════════════════════════════════════════╗
║   OXYGEN UI LIBRARY  •  beta 0.0.1  —  Full Example     ║
║   Covers every component and feature of the library.    ║
║                                                          ║
║   LOAD:                                                  ║
║   local Oxygen = loadstring(game:HttpGet(RAW_URL))()    ║
╚══════════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════════════════════
--  LOAD
-- ════════════════════════════════════════════════════════
local Oxygen = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/oxygen015/roblox-modules/refs/heads/main/oxygen_gui_lib/oxygen.lua"
))()

-- ════════════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Lighting    = game:GetService("Lighting")
local LP          = Players.LocalPlayer

-- ════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ════════════════════════════════════════════════════════
local UI = Oxygen.new({
    -- Basic
    Title       = "Phantom",
    Subtitle    = "Undetected  •  v1.0",
    Theme       = "Carbon",          -- starting theme

    -- Layout
    SizeX       = 580,
    SizeY       = 420,

    -- Config persistence
    SaveConfig  = true,
    ConfigName  = "Phantom",         -- saves to Phantom_OxCfg.json

    -- Extras
    Watermark   = true,
    NotifPos    = "BottomRight",     -- BottomRight | TopRight | BottomLeft | TopLeft

    -- Splash screen
    Splash = {
        Title    = "Phantom",
        Subtitle = "Initializing modules...",
        Icon     = "🔮",             -- emoji shown in the splash circle
        Duration = 2.6,
    },

    -- Keybinds
    ToggleKey   = Enum.KeyCode.RightControl,
    MinimizeKey = Enum.KeyCode.RightShift,
})

--[[ Available themes:
     Carbon, Midnight, Neon, Ocean, Forest, Mocha, Dracula,
     Blood, Monochrome, Slate, Light, Rose, Ice, Sunset, Sakura, Candy
     Switch programmatically: UI:SetTheme("Neon")
     Or use the built-in dropdown in the Settings tab.         ]]

-- ════════════════════════════════════════════════════════
--  LISTEN TO SIGNALS
-- ════════════════════════════════════════════════════════

-- Fires whenever the user changes the theme
UI.ThemeChanged:Connect(function(name, themeData)
    print("[Phantom] Theme changed to:", name)
end)

-- Fires whenever the active tab changes
UI.TabChanged:Connect(function(index, title)
    print("[Phantom] Switched to tab:", title, "(index "..index..")")
end)

-- ════════════════════════════════════════════════════════
--  TAB 1 — COMBAT
-- ════════════════════════════════════════════════════════
local Combat = UI:AddTab({ Title = "Combat", Icon = "⚔" })

-- ─── Aimbot ─────────────────────────────────────────
Combat.Section({ Title = "Aimbot" })

local aimbotOn = Combat.Toggle({
    Title       = "Aimbot",
    Description = "Locks onto the nearest visible player",
    Default     = false,
    ConfigKey   = "aimbot_enabled",
    Tooltip     = "Requires FOV radius above zero",
    Callback    = function(v)
        UI:Notify({
            Title       = v and "Aimbot Enabled" or "Aimbot Disabled",
            Description = v and "Locking to nearest target." or "Aim lock off.",
            Type        = v and "success" or "info",
            Duration    = 2,
        })
    end
})

-- .Changed signal — alternative to Callback
aimbotOn.Changed:Connect(function(v)
    -- e.g. update your aimbot module here
end)

local fovSlider = Combat.Slider({
    Title       = "FOV Radius",
    Description = "Search radius around your crosshair (pixels)",
    Min         = 10,
    Max         = 600,
    Default     = 150,
    Precision   = 0,
    Suffix      = " px",
    ConfigKey   = "aimbot_fov",
    Callback    = function(v)
        -- resize your FOV circle drawing here
    end
})

Combat.Slider({
    Title     = "Smoothness",
    Min       = 1, Max = 20, Default = 6,
    Precision = 1, Suffix = "x",
    ConfigKey = "aimbot_smooth",
    Snap      = 0.5,   -- snaps to nearest 0.5
    Callback  = function(v) end
})

Combat.Dropdown({
    Title     = "Target Part",
    Options   = { "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LeftArm", "RightArm" },
    Default   = "Head",
    ConfigKey = "aimbot_part",
    Callback  = function(v) print("Aiming at:", v) end
})

Combat.RadioGroup({
    Title    = "Activation Mode",
    Options  = { "Hold RMB", "Hold LMB", "Toggle", "Always On" },
    Default  = "Hold RMB",
    ConfigKey = "aimbot_mode",
    Callback  = function(v) print("Mode:", v) end
})

Combat.ColorPicker({
    Title    = "FOV Circle Color",
    Default  = Color3.fromRGB(255, 80, 80),
    ConfigKey = "fov_color",
    Callback  = function(c)
        -- update your circle drawing color here
    end
})

-- ─── Silent Aim ─────────────────────────────────────
Combat.Section({ Title = "Silent Aim" })

Combat.Toggle({
    Title       = "Silent Aim",
    Description = "Bullets curve toward target silently",
    Default     = false,
    ConfigKey   = "silent_aim",
    Callback    = function(v) end
})

Combat.Slider({
    Title    = "Hit Chance",
    Min      = 1, Max = 100, Default = 100,
    Suffix   = "%",
    Tooltip  = "Lower = misses sometimes to avoid detection",
    Callback = function(v) end
})

-- ─── Extras ─────────────────────────────────────────
Combat.Section({ Title = "Extras" })

Combat.Toggle({ Title = "Infinite Ammo",   Default = false, ConfigKey = "inf_ammo",  Callback = function(v) end })
Combat.Toggle({ Title = "No Recoil",       Default = false, ConfigKey = "no_recoil", Callback = function(v) end })
Combat.Toggle({ Title = "Rapid Fire",      Default = false, ConfigKey = "rapid_fire",Callback = function(v) end })

Combat.Keybind({
    Title       = "Aimbot Toggle Key",
    Description = "Press this key in-game to toggle aimbot",
    Default     = Enum.KeyCode.CapsLock,
    ConfigKey   = "aimbot_key",
    AllowMouse  = true,   -- can also bind MouseButton1 / MouseButton2
    Callback    = function(key) print("Aimbot key set to:", key.Name) end
})

-- ════════════════════════════════════════════════════════
--  TAB 2 — VISUALS / ESP
-- ════════════════════════════════════════════════════════
local Visuals = UI:AddTab({ Title = "Visuals", Icon = "👁" })

Visuals.Section({ Title = "Player ESP" })

local espEnabled = Visuals.Toggle({ Title = "ESP", Default = false, ConfigKey = "esp_on", Callback = function(v) end })
Visuals.Toggle({ Title = "Box ESP",      Default = false, ConfigKey = "esp_box",     Callback = function(v) end })
Visuals.Toggle({ Title = "Name Tags",    Default = true,  ConfigKey = "esp_names",   Callback = function(v) end })
Visuals.Toggle({ Title = "Health Bars",  Default = true,  ConfigKey = "esp_hp",      Callback = function(v) end })
Visuals.Toggle({ Title = "Distance",     Default = true,  ConfigKey = "esp_dist",    Callback = function(v) end })
Visuals.Toggle({ Title = "Tracelines",   Default = false, ConfigKey = "esp_traces",  Callback = function(v) end })
Visuals.Toggle({ Title = "Skeletons",    Default = false, ConfigKey = "esp_skel",    Callback = function(v) end })

Visuals.Separator({ Text = "Colors" })

Visuals.ColorPicker({ Title = "ESP Box",       Default = Color3.fromRGB(255,60,60),  ConfigKey = "col_box",   Callback = function(c) end })
Visuals.ColorPicker({ Title = "Name Color",    Default = Color3.fromRGB(255,255,255),ConfigKey = "col_name",  Callback = function(c) end })
Visuals.ColorPicker({ Title = "Traceline",     Default = Color3.fromRGB(100,200,255),ConfigKey = "col_trace", Callback = function(c) end })
Visuals.ColorPicker({ Title = "Skeleton",      Default = Color3.fromRGB(200,200,200),ConfigKey = "col_skel",  Callback = function(c) end })

Visuals.Section({ Title = "World" })

Visuals.Toggle({
    Title     = "Full Bright",
    Default   = false,
    ConfigKey = "fullbright",
    Callback  = function(v)
        Lighting.Brightness = v and 5 or 1
        if v then Lighting.ClockTime = 14 end
    end
})

Visuals.Toggle({
    Title     = "No Fog",
    Default   = false,
    ConfigKey = "no_fog",
    Callback  = function(v)
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = v and 0 or 0.3 end
    end
})

Visuals.Slider({
    Title     = "FOV Changer",
    Min       = 30, Max = 120, Default = 70, Suffix = "°",
    ConfigKey = "fov_val",
    Callback  = function(v)
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = v end
    end
})

-- Custom accent override at runtime
Visuals.Button({
    Title       = "Set Custom Accent",
    Description = "Override the theme accent with a custom color",
    ButtonText  = "APPLY",
    Callback    = function()
        UI:SetAccent(Color3.fromRGB(255, 140, 0))
        UI:Notify({ Title = "Accent Changed", Description = "Orange accent applied.", Type = "info" })
    end
})

-- ════════════════════════════════════════════════════════
--  TAB 3 — MOVEMENT
-- ════════════════════════════════════════════════════════
local Movement = UI:AddTab({ Title = "Movement", Icon = "🏃" })

Movement.Section({ Title = "Speed" })

local speedSlider  -- forward reference

local speedOn = Movement.Toggle({
    Title     = "Speed Hack",
    Default   = false,
    ConfigKey = "speed_on",
    Callback  = function(v)
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and (speedSlider and speedSlider:Get() or 100) or 16 end
    end
})

speedSlider = Movement.Slider({
    Title     = "Walk Speed",
    Min       = 16, Max = 500, Default = 100, Suffix = " ws",
    ConfigKey = "walk_speed",
    Callback  = function(v)
        if speedOn:Get() then
            local char = LP.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

Movement.Section({ Title = "Jump" })

Movement.Toggle({
    Title     = "Infinite Jump",
    Default   = false,
    ConfigKey = "inf_jump",
    Callback  = function(v)
        -- hook UserInputService.JumpRequest in your script
    end
})

Movement.Slider({
    Title     = "Jump Power",
    Min       = 7, Max = 300, Default = 50, Suffix = " jp",
    ConfigKey = "jump_pow",
    Callback  = function(v)
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
})

Movement.Section({ Title = "Flight" })

Movement.Toggle({
    Title       = "Fly",
    Description = "Space = up  •  Shift = down",
    Default     = false,
    ConfigKey   = "fly_on",
    Callback    = function(v) end
})

Movement.Slider({ Title = "Fly Speed", Min = 10, Max = 800, Default = 100, Suffix = "x", ConfigKey = "fly_sp", Callback = function(v) end })

Movement.Keybind({
    Title    = "Fly Toggle Key",
    Default  = Enum.KeyCode.F,
    ConfigKey = "fly_key",
    Callback = function(k) print("Fly key:", k.Name) end
})

Movement.Section({ Title = "Misc" })

Movement.Toggle({ Title = "Noclip",       Default = false, ConfigKey = "noclip",     Callback = function(v) end })
Movement.Toggle({ Title = "Anti-Gravity", Default = false, ConfigKey = "anti_grav",  Callback = function(v) end })

Movement.Stepper({
    Title    = "Hip Height",
    Min      = 0, Max = 30, Default = 0, Step = 1,
    ConfigKey = "hip_h",
    Callback = function(v)
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.HipHeight = v end
    end
})

-- ════════════════════════════════════════════════════════
--  TAB 4 — FARM
-- ════════════════════════════════════════════════════════
local Farm = UI:AddTab({ Title = "Farm", Icon = "⚡" })

Farm.Section({ Title = "Auto Farm" })

-- Progress bar with shimmer animation
local farmProgress = Farm.ProgressBar({
    Title  = "Farm Progress",
    Value  = 0, Max = 100, Suffix = "%",
})

local farmRunning = false
local farmToggle = Farm.Toggle({
    Title       = "Auto Farm",
    Description = "Kills mobs and collects loot automatically",
    Default     = false,
    Callback    = function(v)
        farmRunning = v
        if v then
            task.spawn(function()
                local n = 0
                while farmRunning do
                    n = (n + 1) % 101
                    farmProgress:Set(n)
                    task.wait(0.04)
                end
            end)
        end
    end
})

Farm.Toggle({ Title = "Auto Collect", Default = true,  ConfigKey = "auto_col",  Callback = function(v) end })
Farm.Toggle({ Title = "Auto Sell",    Default = false, ConfigKey = "auto_sell", Callback = function(v) end })
Farm.Toggle({ Title = "Auto Quest",   Default = false, ConfigKey = "auto_quest",Callback = function(v) end })

Farm.Section({ Title = "Targeting" })

Farm.Dropdown({
    Title     = "Target Mob",
    Options   = { "Any", "Goblin", "Orc", "Dragon", "Slime", "Boss", "Elite" },
    Default   = "Any",
    ConfigKey = "farm_mob",
    Callback  = function(v) print("Targeting:", v) end
})

-- Multi-select dropdown — callback receives a table
Farm.Dropdown({
    Title    = "Loot Filter",
    Options  = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
    Multi    = true,
    Callback = function(selected)
        -- selected is e.g. {"Rare", "Legendary"}
    end
})

Farm.Section({ Title = "Status" })

local farmStatus = Farm.StatusIndicator({
    Label  = "Auto Farm",
    Status = "idle",
})

farmToggle.Changed:Connect(function(v)
    farmStatus:SetStatus(v and "online" or "idle")
end)

-- Badges
Farm.Badge({
    Items = {
        { Text = "v1.0",          Color = Color3.fromRGB(60,60,70)   },
        { Text = "Auto Farm",     Color = Color3.fromRGB(48,200,108) },
        { Text = "Safe Mode",     Color = Color3.fromRGB(60,140,255) },
    }
})

-- ════════════════════════════════════════════════════════
--  TAB 5 — PLAYER
-- ════════════════════════════════════════════════════════
local Player = UI:AddTab({ Title = "Player", Icon = "👤" })

Player.Section({ Title = "Stats" })

Player.Toggle({ Title = "God Mode",         Default = false, ConfigKey = "god",      Callback = function(v) end })
Player.Toggle({ Title = "Infinite Stamina", Default = false, ConfigKey = "inf_stam", Callback = function(v) end })
Player.Toggle({ Title = "Anti-AFK",         Default = true,  ConfigKey = "anti_afk", Callback = function(v) end })
Player.Toggle({ Title = "No Fall Damage",   Default = false, ConfigKey = "no_fall",  Callback = function(v) end })

Player.Section({ Title = "Appearance" })

Player.TextInput({
    Title       = "Display Tag",
    Description = "Custom BillboardGui text above your head",
    Placeholder = "Enter tag…",
    MaxLength   = 24,
    ConfigKey   = "display_tag",
    Tooltip     = "Shown above character in-game",
    Callback    = function(text) print("Tag set:", text) end
})

Player.ColorPicker({
    Title     = "Tag Color",
    Default   = Color3.fromRGB(120,80,255),
    ConfigKey = "tag_col",
    Callback  = function(c) end
})

Player.Section({ Title = "Tools" })

Player.Button({
    Title       = "Reset Character",
    Description = "Kills and respawns your character",
    Tooltip     = "Same as the in-menu reset",
    Variant     = "danger",   -- "default" | "danger" | "success" | "ghost"
    Callback    = function()
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
        UI:Notify({ Title = "Reset", Description = "Character respawning…", Type = "info" })
    end
})

Player.Button({
    Title    = "Copy User ID",
    Icon     = "🆔",
    Variant  = "ghost",
    Callback = function()
        local id = tostring(LP.UserId)
        pcall(function() setclipboard(id) end)
        UI:Notify({ Title = "Copied!", Description = "UserId: "..id, Type = "success" })
    end
})

Player.Button({
    Title       = "Rejoin Server",
    Description = "Teleports you to a fresh server instance",
    Callback    = function()
        UI:Notify({
            Title    = "Rejoining…",
            Description = "Connecting to a new server.",
            Type     = "info", Duration = 3,
        })
        task.delay(1, function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
        end)
    end
})

-- Notification with action buttons
Player.Button({
    Title    = "Confirm Action",
    Description = "Shows a notification with action buttons",
    Callback = function()
        UI:Notify({
            Title   = "Are you sure?",
            Description = "This will reset all your data.",
            Type    = "warning", Duration = 10,
            Buttons = {
                { label = "Yes, do it", callback = function()
                    UI:Notify({ Title = "Done!", Type = "success" })
                end },
                { label = "Cancel", callback = function() end },
            }
        })
    end
})

-- ════════════════════════════════════════════════════════
--  TAB 6 — MISC
-- ════════════════════════════════════════════════════════
local Misc = UI:AddTab({ Title = "Misc", Icon = "🔧" })

Misc.Section({ Title = "Chat" })

local chatMsg = Misc.TextInput({
    Title       = "Auto Chat",
    Placeholder = "Message to spam…",
    MaxLength   = 100,
    ConfigKey   = "chat_msg",
    Callback    = function(text) end
})

Misc.Slider({ Title = "Chat Interval", Min = 5, Max = 120, Default = 30, Suffix = " sec", ConfigKey = "chat_int", Callback = function(v) end })
Misc.Toggle({ Title = "Auto Chat",     Default = false, ConfigKey = "auto_chat", Callback = function(v) end })

Misc.Section({ Title = "Search Example" })

-- SearchBox: fires callback live as you type
local searchBox = Misc.SearchBox({
    Placeholder = "Filter components…",
    Callback    = function(text)
        -- e.g. show/hide elements based on text
        print("Searching:", text)
    end
})

Misc.Section({ Title = "Notifications" })

Misc.Button({ Title = "✓  Success",  Callback = function() UI:Notify({ Title = "Success",  Description = "Everything worked fine.",          Type = "success" }) end })
Misc.Button({ Title = "⚠  Warning",  Callback = function() UI:Notify({ Title = "Warning",  Description = "Something may not work.",          Type = "warning", Duration = 5 }) end })
Misc.Button({ Title = "✕  Error",    Callback = function() UI:Notify({ Title = "Error",    Description = "An unexpected error occurred.",    Type = "error"   }) end })
Misc.Button({ Title = "ℹ  Info",     Callback = function() UI:Notify({ Title = "Info",     Description = "RightControl toggles the UI.",     Type = "info",  Duration = 6 }) end })

Misc.Separator()

-- Updatable notification
Misc.Button({
    Title    = "Updatable Notification",
    Description = "Push it twice to see the update",
    Callback = function()
        local notif = UI:Notify({
            Title       = "Fetching data…",
            Description = "Please wait.",
            Type        = "info", Duration = 6,
        })
        task.delay(2, function()
            notif:Update("Data loaded!", "All 42 items fetched successfully.")
        end)
    end
})

Misc.Section({ Title = "Keybinds" })

Misc.Keybind({ Title = "ESP Toggle",    Default = Enum.KeyCode.Insert,   Callback = function(k) print("ESP key:", k.Name) end })
Misc.Keybind({ Title = "Farm Toggle",   Default = Enum.KeyCode.Home,     Callback = function(k) print("Farm key:", k.Name) end })
Misc.Keybind({ Title = "Fly Toggle",    Default = Enum.KeyCode.PageUp,   Callback = function(k) print("Fly key:", k.Name) end })

-- ════════════════════════════════════════════════════════
--  TAB 7 — INFO / DASHBOARD
-- ════════════════════════════════════════════════════════
local Info = UI:AddTab({ Title = "Info", Icon = "ℹ" })

-- ── Accordion (collapsible subsection) ──────────────────
local playerInfo = Info.Accordion({ Title = "Player Info", Open = true })

local nameLabel   = playerInfo.Label({ Title = "Player: "  .. LP.Name })
local idLabel     = playerInfo.Label({ Title = "UserId: "  .. tostring(LP.UserId) })
local placeLabel  = playerInfo.Label({ Title = "Place ID: " .. tostring(game.PlaceId) })
local fpsLabel    = playerInfo.Label({ Title = "FPS: calculating…" })
local pingLabel   = playerInfo.Label({ Title = "Ping: …" })

-- Live FPS counter
task.spawn(function()
    local frames, last = 0, tick()
    RunService.RenderStepped:Connect(function()
        frames += 1
        if tick() - last >= 1 then
            fpsLabel:Set("FPS: " .. frames)
            frames, last = 0, tick()
        end
    end)
end)

-- Live ping
task.spawn(function()
    while task.wait(2) do
        local ok, ms = pcall(function()
            return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok then pingLabel:Set("Ping: " .. ms .. " ms") end
    end
end)

-- ── Real-time FPS chart ──────────────────────────────────
Info.Section({ Title = "FPS Chart" })

local fpsChart = Info.LineChart({
    Title     = "Frames Per Second",
    Height    = 90,
    MaxPoints = 50,
    YMin      = 0,
    YMax      = 120,
})

task.spawn(function()
    local frames, last = 0, tick()
    RunService.RenderStepped:Connect(function()
        frames += 1
        if tick() - last >= 0.5 then
            fpsChart:Push(frames * 2)  -- *2 because we sample every 0.5s
            frames, last = 0, tick()
        end
    end)
end)

-- ── Data table ──────────────────────────────────────────
Info.Section({ Title = "Data Table" })

Info.Table({
    Headers = { "Name", "Value", "Status" },
    Rows = {
        { "Walk Speed",  "16",   "Default" },
        { "Jump Power",  "50",   "Default" },
        { "FOV",         "70°",  "Active"  },
        { "Ping",        "~",    "Live"    },
    }
})

-- ── Spinner (loading state) ──────────────────────────────
Info.Section({ Title = "Spinner Demo" })

local spinner = Info.Spinner({ Title = "Fetching server data…" })
task.delay(4, function()
    spinner:SetTitle("Done!")
    task.delay(1, function() spinner:SetVisible(false) end)
end)

-- ── Paragraph ───────────────────────────────────────────
Info.Section({ Title = "About" })

Info.Paragraph({
    Title   = "Oxygen UI Library",
    Content = "A fully-featured, theme-aware UI framework for Roblox executor scripts. "
           .. "Supports 16 built-in themes with live switching, config persistence, notifications, "
           .. "and 20+ components — all with full :Destroy() support."
})

Info.Label({ Title = "Version: "..Oxygen.Version })
Info.Label({ Title = "github.com/oxygen015/roblox-modules" })
Info.Label({ Title = "Themes available: "..#UI:GetThemeNames() })

-- ── Theme switcher buttons ──────────────────────────────
Info.Section({ Title = "Quick Theme Switch" })

Info.Dropdown({
    Title    = "Theme",
    Options  = UI:GetThemeNames(),
    Default  = "Carbon",
    Callback = function(name)
        UI:SetTheme(name)
        UI:Notify({ Title = "Theme: "..name, Description = "Applied instantly.", Type = "success", Duration = 2 })
    end
})

-- ════════════════════════════════════════════════════════
--  TAB BADGE DEMO
--  (set a notification count badge on the Farm tab)
-- ════════════════════════════════════════════════════════
task.spawn(function()
    local farmTab = UI:GetTab("Farm")  -- get tab API by name
    local count = 0
    while task.wait(5) do
        if farmToggle:Get() then
            count += 1
            farmTab:SetBadge(count)
        end
    end
end)

-- ════════════════════════════════════════════════════════
--  WATERMARK CLOCK
--  The watermark auto-shows a live clock on the right.
--  You can override the main text:
-- ════════════════════════════════════════════════════════
UI:SetWatermarkText("⚡ Phantom  •  " .. LP.Name)

-- ════════════════════════════════════════════════════════
--  CONFIG WATCHER  (react when a saved key changes)
-- ════════════════════════════════════════════════════════
if UI.DoSave then
    UI.Store:Watch("aimbot_enabled", function(v)
        print("[Config] aimbot_enabled changed to:", v)
    end)
end

-- ════════════════════════════════════════════════════════
--  PROGRAMMATIC CONTROL EXAMPLES
-- ════════════════════════════════════════════════════════

-- Switch to a tab by name
-- UI:ShowTab("Combat")

-- Get any tab's API after creation
-- local combatAPI = UI:GetTab("Combat")

-- Disable / re-enable a component
-- aimbotOn:SetDisabled(true)   -- greys it out, blocks interaction
-- aimbotOn:SetDisabled(false)

-- Hide / show a component
-- fovSlider:SetVisible(false)

-- Update slider range at runtime
-- fovSlider:SetMax(800)

-- Add / remove dropdown options
-- local dd = Combat:GetTab("...)   -- not real, just pseudo
-- dd:AddOption("NewTarget")
-- dd:RemoveOption("LeftArm")

-- Live chart interaction
-- fpsChart:Clear()   -- clear all points
-- fpsChart:SetColor(Color3.fromRGB(0,255,150))

-- Progress bar color
-- farmProgress:SetColor(Color3.fromRGB(255,200,0))

-- ════════════════════════════════════════════════════════
--  STARTUP NOTIFICATION
-- ════════════════════════════════════════════════════════
task.delay(1, function()
    UI:Notify({
        Title       = "Phantom Loaded ✓",
        Description = "RightControl = toggle  •  RightShift = minimize",
        Type        = "success",
        Duration    = 6,
    })
end)

--[[
╔════════════════════════════════════════════════════════╗
║   QUICK REFERENCE                                      ║
╠════════════════════════════════════════════════════════╣
║  WINDOW                                                ║
║   UI:AddTab({ Title, Icon })      → tabAPI             ║
║   UI:GetTab(title)                → tabAPI             ║
║   UI:ShowTab(title)                                    ║
║   UI:SetTheme("Name")                                  ║
║   UI:SetAccent(Color3)                                 ║
║   UI:Notify({ Title, Description, Type, Duration,      ║
║               Buttons, Callback })  → {Dismiss,Update} ║
║   UI:SetTitle(str)  / SetSubtitle(str)                 ║
║   UI:SetWatermarkText(str)                             ║
║   UI:Toggle()  /  ToggleMinimize()  /  Destroy()       ║
║   UI.ThemeChanged:Connect(fn(name,data))               ║
║   UI.TabChanged:Connect(fn(index,title))               ║
║                                                        ║
║  COMPONENTS  (all accept ConfigKey for auto-save)      ║
║   .Section   ({ Title })                               ║
║   .Separator ({ Text? })  /  .Divider()                ║
║   .Label     ({ Title })      → :Set, :Get             ║
║   .Paragraph ({ Title, Content })                      ║
║   .Button    ({ Title, Desc, Icon, Variant,            ║
║                 Tooltip, Callback })                   ║
║   .Toggle    ({ Title, Desc, Default, Tooltip })       ║
║             → :Set, :Get, :SetDisabled, .Changed       ║
║   .Slider    ({ Title, Min, Max, Default,              ║
║                 Precision, Suffix, Snap })             ║
║             → :Set, :Get, :SetMin/Max,  .Changed       ║
║   .Dropdown  ({ Title, Options, Default, Multi })      ║
║             → :Set, :Get, :SetOptions, :Add/Remove     ║
║   .RadioGroup({ Title, Options, Default })             ║
║             → :Get, :Set, :SetOptions                  ║
║   .ColorPicker({ Title, Default })                     ║
║             → :Get, :Set                              ║
║   .Keybind  ({ Title, Default, AllowMouse })           ║
║             → :Get, :Set                              ║
║   .TextInput ({ Title, Placeholder, MaxLength,         ║
║                 Numeric, Tooltip })                    ║
║             → :Get, :Set, :Clear, :Focus               ║
║   .SearchBox ({ Placeholder, Callback })               ║
║             → :Get, :Set, :Clear                       ║
║   .Stepper  ({ Title, Min, Max, Step }) — hold-repeat  ║
║             → :Get, :Set                              ║
║   .ProgressBar({ Title, Value, Max, Suffix })          ║
║             → :Set, :SetMax, :SetColor, :SetTitle      ║
║   .StatusIndicator({ Label, Status })                  ║
║             → :SetStatus(s, color?), :SetLabel         ║
║   .Spinner  ({ Title }) — animated loader              ║
║             → :SetTitle, :SetVisible                   ║
║   .LineChart ({ Title, Height, MaxPoints, YMin, YMax })║
║             → :Push(val), :Clear, :SetColor            ║
║   .Table    ({ Headers, Rows })                        ║
║   .Badge    ({ Items:[{Text,Color}] })                 ║
║             → :Add, :Remove, :Clear                    ║
║   .Accordion({ Title, Open? })  → full component API  ║
║   .Image    ({ ID, Height, Caption })                  ║
║                                                        ║
║  EVERY component also has:                             ║
║   :SetVisible(bool)   — show/hide without destroying   ║
║   :SetDisabled(bool)  — grey overlay, blocks input     ║
║   :Destroy()          — removes the card entirely      ║
╚════════════════════════════════════════════════════════╝
]]
