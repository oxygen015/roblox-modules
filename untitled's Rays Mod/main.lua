local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Untitled's Ray's Mods",
    LoadingTitle = "Untitled's Ray's Mods",
    LoadingSubtitle = "Enhanced Edition v2",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "UntitledRaysMods"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = false
    },
    KeySystem = false,
    KeySettings = {
        Title = "",
        Subtitle = "",
        Note = "",
        FileName = "",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = ""
    }
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function getChar() return LocalPlayer.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local loops = {}
local function startLoop(name, func)
    if loops[name] then return end
    loops[name] = RunService.Heartbeat:Connect(func)
end
local function stopLoop(name)
    if loops[name] then
        loops[name]:Disconnect()
        loops[name] = nil
    end
end

local function notify(title, text)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = text,
            Duration = 3,
        })
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SERVER / GAME FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Fixed vararg-in-closure bug
local function fireRS(name, ...)
    local args = {...}
    pcall(function()
        local r = ReplicatedStorage:WaitForChild(name, 3)
        if r and r:IsA("RemoteEvent") then r:FireServer(table.unpack(args)) end
    end)
end

local function getVoteKick()
    return ReplicatedStorage:FindFirstChild("VoteKickInProgress")
end

local function kickPlayer(targetName, reason)
    local vk = getVoteKick()
    if not vk then return end
    pcall(function()
        vk:WaitForChild("VoteEvent"):FireServer(targetName, reason or "Kicked via Untitled's Ray's Mods")
    end)
end

local function spamVote()
    local vk = getVoteKick()
    if not vk then return end
    local voteAdded = vk:FindFirstChild("VoteAdded")
    if not voteAdded then return end
    for _ = 1, #Players:GetPlayers() do
        pcall(function() voteAdded:FireServer() end)
    end
end

local function kickAll(reason)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            kickPlayer(player.Name, reason)
            task.spawn(function()
                for _ = 1, 20 do
                    task.wait(0.05)
                    pcall(function()
                        local vk = getVoteKick()
                        if vk then vk:WaitForChild("VoteAdded"):FireServer() end
                    end)
                end
            end)
            task.wait(15.7)
        end
    end
end

-- ┌─────────────────────────────────────────────────────────────────────────────
-- │  HEALTH  — truly instant: spawns ALL remote fires simultaneously
-- └─────────────────────────────────────────────────────────────────────────────
--
-- Each MoreHealth remote adds +100 HP server-side.
-- We spawn every fire in its own task.spawn so they all hit the server
-- in the same frame instead of one per frame.
--
local function addHealthInstant(amount)
    local fires = math.floor(amount / 100)
    if fires <= 0 then return end
    task.spawn(function()
        -- Cache the remote once to avoid repeated WaitForChild lookups
        local remote = ReplicatedStorage:FindFirstChild("MoreHealth")
        if not remote then
            pcall(function() remote = ReplicatedStorage:WaitForChild("MoreHealth", 5) end)
        end
        if not remote then
            notify("Health", "MoreHealth remote not found!")
            return
        end
        -- Fire all at once — no yielding between fires
        for _ = 1, fires do
            task.spawn(function() pcall(function() remote:FireServer() end) end)
        end
        notify("Health", "+" .. tostring(fires * 100) .. " HP fired instantly!")
    end)
end

local function repairBoard()
    fireRS("RepairBoard")
end

-- ┌─────────────────────────────────────────────────────────────────────────────
-- │  SCALE  — sends all 4 axis remotes simultaneously
-- └─────────────────────────────────────────────────────────────────────────────

local scaleAxes = {"Depth", "Width", "Height", "Head"}

local function scaleAxis(axis, size)
    pcall(function()
        local ps = ReplicatedStorage:WaitForChild("PlayerScale", 3)
        ps:WaitForChild(axis, 3):FireServer(size)
    end)
end

local function scaleplayer(size)
    for _, axis in ipairs(scaleAxes) do
        task.spawn(function() scaleAxis(axis, size) end)
    end
end

-- Scale each axis independently
local function scalePlayerCustom(depth, width, height, head)
    task.spawn(function() scaleAxis("Depth",  depth)  end)
    task.spawn(function() scaleAxis("Width",  width)  end)
    task.spawn(function() scaleAxis("Height", height) end)
    task.spawn(function() scaleAxis("Head",   head)   end)
end

local function giveAllAddons()
    pcall(function()
        local addonStorage = ReplicatedStorage:WaitForChild("AddonStorage", 5)
        if not addonStorage then
            notify("Addons", "AddonStorage not found!")
            return
        end
        local spawnerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
            :WaitForChild("Spawner", 5)
            :WaitForChild("SpawnFrame", 5)
            :WaitForChild("Addons", 5)
        local count = 0
        for _, addon in ipairs(addonStorage:GetChildren()) do
            if not spawnerGui:FindFirstChild(addon.Name) then
                addon:Clone().Parent = spawnerGui
                count += 1
            end
        end
        notify("Addons", "Unlocked " .. count .. " addons!")
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 1 — TRICKS
-- ═══════════════════════════════════════════════════════════════════════════════

local TricksTab = Window:CreateTab("Tricks", nil)

TricksTab:CreateSection("Board Tricks", false)

TricksTab:CreateToggle({
    Name = "Anti Ragdoll / Trip",
    Info = "Prevents your character from ragdolling or tripping.",
    CurrentValue = false,
    Flag = "AntiTrip",
    Callback = function(val)
        if val then
            startLoop("AntiTrip", function()
                local hum = getHum()
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                end
            end)
        else
            stopLoop("AntiTrip")
            local hum = getHum()
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            end
        end
    end
})

TricksTab:CreateToggle({
    Name = "No Trick Cooldown",
    Info = "Zeroes trick cooldown values on your character every frame.",
    CurrentValue = false,
    Flag = "NoTrickCD",
    Callback = function(val)
        if val then
            startLoop("NoTrickCD", function()
                pcall(function()
                    local char = getChar()
                    if not char then return end
                    for _, v in ipairs(char:GetDescendants()) do
                        if v.Name == "TrickCooldown" and v:IsA("NumberValue") then
                            v.Value = 0
                        end
                    end
                end)
            end)
        else
            stopLoop("NoTrickCD")
        end
    end
})

TricksTab:CreateToggle({
    Name = "No Wear & Tear",
    Info = "Keeps your board durability at 100 at all times.",
    CurrentValue = false,
    Flag = "NoWear",
    Callback = function(val)
        if val then
            startLoop("NoWear", function()
                pcall(function()
                    local char = getChar()
                    if not char then return end
                    for _, v in ipairs(char:GetDescendants()) do
                        if v.Name == "Durability" and v:IsA("NumberValue") then
                            v.Value = 100
                        end
                    end
                end)
            end)
        else
            stopLoop("NoWear")
        end
    end
})

TricksTab:CreateToggle({
    Name = "No Spawn Cooldown",
    Info = "Zeroes any SpawnCooldown values found on your character.",
    CurrentValue = false,
    Flag = "NoSpawnCD",
    Callback = function(val)
        if val then
            startLoop("NoSpawnCD", function()
                pcall(function()
                    local char = getChar()
                    if char then
                        for _, v in ipairs(char:GetDescendants()) do
                            if (v.Name:lower():find("spawncooldown")
                                or v.Name:lower():find("respawncooldown"))
                                and (v:IsA("NumberValue") or v:IsA("IntValue")) then
                                v.Value = 0
                            end
                        end
                    end
                    for _, v in ipairs(LocalPlayer:GetDescendants()) do
                        if (v.Name:lower():find("spawncooldown")
                            or v.Name:lower():find("respawncooldown"))
                            and (v:IsA("NumberValue") or v:IsA("IntValue")) then
                            v.Value = 0
                        end
                    end
                end)
                task.wait(0.1)
            end)
        else
            stopLoop("NoSpawnCD")
        end
    end
})

TricksTab:CreateToggle({
    Name = "Extend Combo Timeout",
    Info = "Keeps your combo timer high so combos never expire.",
    CurrentValue = false,
    Flag = "ExtendCombo",
    Callback = function(val)
        if val then
            startLoop("ExtendCombo", function()
                pcall(function()
                    local char = getChar()
                    if not char then return end
                    for _, v in ipairs(char:GetDescendants()) do
                        if v.Name == "ComboTimer" and v:IsA("NumberValue") then
                            v.Value = 60
                        end
                    end
                end)
            end)
        else
            stopLoop("ExtendCombo")
        end
    end
})

TricksTab:CreateSection("Board", false)

TricksTab:CreateButton({
    Name = "Repair Board",
    Info = "Instantly repairs your board once.",
    Interact = "Repair",
    Callback = function()
        repairBoard()
        notify("Board", "Board repaired!")
    end
})

TricksTab:CreateToggle({
    Name = "Auto Repair Board",
    Info = "Repairs your board automatically every 2 seconds.",
    CurrentValue = false,
    Flag = "AutoRepair",
    Callback = function(val)
        if val then
            startLoop("AutoRepair", function()
                repairBoard()
                task.wait(2)
            end)
        else
            stopLoop("AutoRepair")
        end
    end
})

TricksTab:CreateToggle({
    Name = "Auto Compete",
    Info = "Automatically fires the compete event.",
    CurrentValue = false,
    Flag = "AutoCompete",
    Callback = function(val)
        if val then
            startLoop("AutoCompete", function()
                fireRS("CompeteEvent")
                task.wait(1)
            end)
        else
            stopLoop("AutoCompete")
        end
    end
})

TricksTab:CreateSection("Addons", false)

TricksTab:CreateButton({
    Name = "Give All Addons",
    Info = "Clones every addon from AddonStorage into your spawner.",
    Interact = "Give",
    Callback = giveAllAddons
})

TricksTab:CreateToggle({
    Name = "Auto Give Addons (on respawn)",
    Info = "Re-gives all addons every time you respawn.",
    CurrentValue = false,
    Flag = "AutoAddons",
    Callback = function(val)
        if val then
            startLoop("AutoAddons", function()
                pcall(giveAllAddons)
                task.wait(5)
            end)
        else
            stopLoop("AutoAddons")
        end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 2 — PLAYER
-- ═══════════════════════════════════════════════════════════════════════════════

local PlayerTab = Window:CreateTab("Player", nil)

-- ══════════════════════════════════════════════════
--  HEALTH
-- ══════════════════════════════════════════════════

PlayerTab:CreateSection("Health", false)

-- Internal state
local hpAmount       = 5000
local autoHealPct    = 50   -- % threshold for auto-heal
local autoHealRefill = 5000 -- how much to add when auto-heal fires

PlayerTab:CreateSlider({
    Name = "HP Amount",
    Info = "How much HP to fire when using the Add HP buttons below. Each 100 = 1 remote fire. All fires happen simultaneously.",
    Range = {100, 10000000},
    Increment = 100,
    Suffix = " HP",
    CurrentValue = hpAmount,
    Flag = "HPAmount",
    Callback = function(val) hpAmount = val end
})

-- One-click add using the slider value
PlayerTab:CreateButton({
    Name = "Add HP — Instant",
    Info = "Fires ALL health remotes simultaneously for the amount set in the slider above.",
    Interact = "Add",
    Callback = function()
        addHealthInstant(hpAmount)
    end
})

-- Quick presets — all fire instantly (no yielding)
PlayerTab:CreateButton({
    Name = "Quick +1,000 HP",
    Info = "Fires 10 MoreHealth remotes simultaneously.",
    Interact = "+1K",
    Callback = function() addHealthInstant(1000) end
})

PlayerTab:CreateButton({
    Name = "Quick +10,000 HP",
    Info = "Fires 100 MoreHealth remotes simultaneously.",
    Interact = "+10K",
    Callback = function() addHealthInstant(10000) end
})

PlayerTab:CreateButton({
    Name = "Quick +100,000 HP",
    Info = "Fires 1,000 MoreHealth remotes simultaneously.",
    Interact = "+100K",
    Callback = function() addHealthInstant(100000) end
})

PlayerTab:CreateButton({
    Name = "Quick +1,000,000 HP",
    Info = "Fires 10,000 MoreHealth remotes simultaneously.",
    Interact = "+1M",
    Callback = function() addHealthInstant(1000000) end
})

PlayerTab:CreateButton({
    Name = "Quick +10,000,000 HP",
    Info = "Fires 100,000 MoreHealth remotes simultaneously.",
    Interact = "+10M",
    Callback = function() addHealthInstant(10000000) end
})

PlayerTab:CreateButton({
    Name = "MAX — 100,000,000 HP",
    Info = "Fires 1,000,000 MoreHealth remotes all at once. Pure overkill.",
    Interact = "MAX",
    Callback = function() addHealthInstant(100000000) end
})

-- God Mode — client-side HP lock every heartbeat
PlayerTab:CreateToggle({
    Name = "God Mode",
    Info = "Locks your health to MaxHealth every single heartbeat.",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(val)
        if val then
            startLoop("GodMode", function()
                local hum = getHum()
                if hum then hum.Health = hum.MaxHealth end
            end)
        else
            stopLoop("GodMode")
        end
    end
})

-- Auto-Heal with configurable threshold + refill amount
PlayerTab:CreateSlider({
    Name = "Auto-Heal Threshold",
    Info = "Auto-heal fires when your HP drops below this % of MaxHealth.",
    Range = {5, 95},
    Increment = 5,
    Suffix = "%",
    CurrentValue = autoHealPct,
    Flag = "AutoHealPct",
    Callback = function(val) autoHealPct = val end
})

PlayerTab:CreateSlider({
    Name = "Auto-Heal Refill Amount",
    Info = "How much HP to add each time Auto-Heal triggers.",
    Range = {100, 1000000},
    Increment = 100,
    Suffix = " HP",
    CurrentValue = autoHealRefill,
    Flag = "AutoHealRefill",
    Callback = function(val) autoHealRefill = val end
})

PlayerTab:CreateToggle({
    Name = "Auto-Heal When Low",
    Info = "Automatically fires health remotes when you fall below the threshold above.",
    CurrentValue = false,
    Flag = "AutoHeal",
    Callback = function(val)
        if val then
            startLoop("AutoHeal", function()
                local hum = getHum()
                if hum and hum.MaxHealth > 0 then
                    local pct = (hum.Health / hum.MaxHealth) * 100
                    if pct < autoHealPct then
                        addHealthInstant(autoHealRefill)
                    end
                end
                task.wait(1)
            end)
        else
            stopLoop("AutoHeal")
        end
    end
})

-- Set a specific MaxHealth cap locally (useful for god-mode display)
PlayerTab:CreateButton({
    Name = "Set MaxHealth to 1,000,000",
    Info = "Sets your local Humanoid MaxHealth to 1,000,000. Combined with God Mode this keeps you permanently full.",
    Interact = "Set",
    Callback = function()
        local hum = getHum()
        if hum then
            hum.MaxHealth = 1000000
            hum.Health    = 1000000
            notify("Health", "MaxHealth set to 1,000,000!")
        else
            notify("Health", "No humanoid found.")
        end
    end
})

PlayerTab:CreateButton({
    Name = "Reset MaxHealth",
    Info = "Resets MaxHealth back to 100.",
    Interact = "Reset",
    Callback = function()
        local hum = getHum()
        if hum then
            hum.MaxHealth = 100
            notify("Health", "MaxHealth reset to 100.")
        end
    end
})

-- ══════════════════════════════════════════════════
--  MOVEMENT
-- ══════════════════════════════════════════════════

PlayerTab:CreateSection("Movement", false)

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Info = "Your character's walk speed. Default is 16.",
    Range = {16, 500},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(val)
        local hum = getHum()
        if hum then hum.WalkSpeed = val end
    end
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Info = "Your character's jump height. Default is 50.",
    Range = {0, 500},
    Increment = 1,
    Suffix = " power",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(val)
        local hum = getHum()
        if hum then hum.JumpPower = val end
    end
})

PlayerTab:CreateSlider({
    Name = "Gravity",
    Info = "Workspace gravity. Default is 196.",
    Range = {0, 500},
    Increment = 1,
    Suffix = "",
    CurrentValue = 196,
    Flag = "Gravity",
    Callback = function(val)
        workspace.Gravity = val
    end
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    Info = "Lets you jump again while in mid-air.",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(val)
        if val then
            startLoop("InfJump", function()
                local hum = getHum()
                if hum and hum:GetState() == Enum.HumanoidStateType.Freefall then
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        else
            stopLoop("InfJump")
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Fly",
    Info = "Fly with WASD + Space (up) + LeftShift (down).",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(val)
        local char = getChar(); local root = getRoot(); local hum = getHum()
        if not char or not root or not hum then return end
        if val then
            hum.PlatformStand = true
            local bv = Instance.new("BodyVelocity")
            bv.Name = "_FlyBV"
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.zero
            bv.Parent = root
            local bg = Instance.new("BodyGyro")
            bg.Name = "_FlyBG"
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bg.P = 1e4
            bg.Parent = root
            startLoop("Fly", function()
                local r   = getRoot()
                local bvf = r and r:FindFirstChild("_FlyBV")
                local bgf = r and r:FindFirstChild("_FlyBG")
                if not bvf or not bgf then return end
                local cam = workspace.CurrentCamera
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cam.CFrame.LookVector  end
                if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cam.CFrame.LookVector  end
                if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.new(0,1,0)     end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0)     end
                bvf.Velocity = dir.Magnitude > 0 and dir.Unit * 80 or Vector3.zero
                bgf.CFrame   = cam.CFrame
            end)
        else
            stopLoop("Fly")
            local r = getRoot()
            if r then
                local bvf = r:FindFirstChild("_FlyBV")
                local bgf = r:FindFirstChild("_FlyBG")
                if bvf then bvf:Destroy() end
                if bgf then bgf:Destroy() end
            end
            local h = getHum()
            if h then h.PlatformStand = false end
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    Info = "Disables collision on your entire character.",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(val)
        if val then
            startLoop("Noclip", function()
                local char = getChar()
                if not char then return end
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        else
            stopLoop("Noclip")
            local char = getChar()
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end
})

-- ══════════════════════════════════════════════════
--  PLAYER SCALE
-- ══════════════════════════════════════════════════

PlayerTab:CreateSection("Player Scale", false)

-- Uniform scale
local uniformScale = 1

PlayerTab:CreateSlider({
    Name = "Uniform Scale",
    Info = "Scales all axes (Depth, Width, Height, Head) equally. 1 = default.",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "UniformScale",
    Callback = function(val) uniformScale = val end
})

PlayerTab:CreateButton({
    Name = "Apply Uniform Scale",
    Info = "Sends the same scale to all 4 axes simultaneously.",
    Interact = "Apply",
    Callback = function()
        scaleplayer(uniformScale)
        notify("Scale", "Applied " .. uniformScale .. "x to all axes!")
    end
})

-- Scale presets — send all fires simultaneously
PlayerTab:CreateButton({
    Name = "Preset — Tiny (0.5x)",
    Info = "Makes your character tiny. Fires all scale remotes simultaneously.",
    Interact = "Apply",
    Callback = function()
        scaleplayer(0.5)
        notify("Scale", "Tiny mode! (0.5x)")
    end
})

PlayerTab:CreateButton({
    Name = "Preset — Normal (1x)",
    Info = "Resets your character to default size.",
    Interact = "Reset",
    Callback = function()
        scaleplayer(1)
        notify("Scale", "Scale reset to 1x!")
    end
})

PlayerTab:CreateButton({
    Name = "Preset — Big (3x)",
    Info = "Makes your character 3x size.",
    Interact = "Apply",
    Callback = function()
        scaleplayer(3)
        notify("Scale", "Big mode! (3x)")
    end
})

PlayerTab:CreateButton({
    Name = "Preset — Giant (5x)",
    Info = "Makes your character 5x size.",
    Interact = "Apply",
    Callback = function()
        scaleplayer(5)
        notify("Scale", "Giant mode! (5x)")
    end
})

PlayerTab:CreateButton({
    Name = "Preset — MAX (10x)",
    Info = "Maximum scale on all axes.",
    Interact = "MAX",
    Callback = function()
        scaleplayer(10)
        notify("Scale", "Maximum scale! (10x)")
    end
})

-- Per-axis sliders
PlayerTab:CreateSection("Per-Axis Scale", false)

local axisDepth  = 1
local axisWidth  = 1
local axisHeight = 1
local axisHead   = 1

PlayerTab:CreateSlider({
    Name = "Depth",
    Info = "Front-to-back depth of your character.",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "ScaleDepth",
    Callback = function(val) axisDepth = val end
})

PlayerTab:CreateSlider({
    Name = "Width",
    Info = "Side-to-side width of your character.",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "ScaleWidth",
    Callback = function(val) axisWidth = val end
})

PlayerTab:CreateSlider({
    Name = "Height",
    Info = "Vertical height of your character.",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "ScaleHeight",
    Callback = function(val) axisHeight = val end
})

PlayerTab:CreateSlider({
    Name = "Head Size",
    Info = "Size of your character's head.",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "ScaleHead",
    Callback = function(val) axisHead = val end
})

PlayerTab:CreateButton({
    Name = "Apply Per-Axis Scale",
    Info = "Fires all four scale remotes with your individual axis values simultaneously.",
    Interact = "Apply",
    Callback = function()
        scalePlayerCustom(axisDepth, axisWidth, axisHeight, axisHead)
        notify("Scale", ("D:%dx W:%dx H:%dx Head:%dx"):format(
            axisDepth, axisWidth, axisHeight, axisHead))
    end
})

PlayerTab:CreateButton({
    Name = "Big Head Only",
    Info = "Resets body to 1x but makes head 5x.",
    Interact = "Apply",
    Callback = function()
        scalePlayerCustom(1, 1, 1, 5)
        notify("Scale", "Big head mode!")
    end
})

PlayerTab:CreateButton({
    Name = "Thin & Tall",
    Info = "Width 1x, Height 5x, Depth 1x, Head 1x.",
    Interact = "Apply",
    Callback = function()
        scalePlayerCustom(1, 1, 5, 1)
        notify("Scale", "Thin & tall mode!")
    end
})

PlayerTab:CreateButton({
    Name = "Wide & Short",
    Info = "Width 5x, Height 1x, Depth 3x, Head 2x.",
    Interact = "Apply",
    Callback = function()
        scalePlayerCustom(3, 5, 1, 2)
        notify("Scale", "Wide & short mode!")
    end
})

-- ══════════════════════════════════════════════════
--  MISC
-- ══════════════════════════════════════════════════

PlayerTab:CreateSection("Misc", false)

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    Info = "Stops the game from detecting you as AFK.",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(val)
        if val then
            startLoop("AntiAFK", function()
                pcall(function()
                    local vjs = game:GetService("VirtualUser")
                    vjs:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    vjs:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
                task.wait(55)
            end)
        else
            stopLoop("AntiAFK")
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Invisible",
    Info = "Makes your character fully transparent to yourself.",
    CurrentValue = false,
    Flag = "Invisible",
    Callback = function(val)
        local char = getChar()
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.Transparency = val and 1 or 0
            end
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Spin",
    Info = "Continuously rotates your character.",
    CurrentValue = false,
    Flag = "Spin",
    Callback = function(val)
        if val then
            startLoop("Spin", function()
                local root = getRoot()
                if root then
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(8), 0)
                end
            end)
        else
            stopLoop("Spin")
        end
    end
})

PlayerTab:CreateButton({
    Name = "Teleport to Spawn",
    Info = "Teleports you to the map SpawnLocation.",
    Interact = "TP",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local spawn = workspace:FindFirstChild("SpawnLocation")
        if spawn then
            root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            notify("TP", "Teleported to spawn!")
        else
            notify("TP", "No SpawnLocation found.")
        end
    end
})

PlayerTab:CreateButton({
    Name = "Teleport to Random Player",
    Info = "Teleports you to a random player in the server.",
    Interact = "TP",
    Callback = function()
        local others = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(others, p)
            end
        end
        if #others == 0 then
            notify("TP", "No other players found!")
            return
        end
        local t = others[math.random(1, #others)]
        local root = getRoot()
        if root then
            root.CFrame = t.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            notify("TP", "Teleported to " .. t.Name)
        end
    end
})

PlayerTab:CreateButton({
    Name = "Fling Self",
    Info = "Launches you in a random direction.",
    Interact = "Fling",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local bv = Instance.new("BodyVelocity")
        bv.Velocity  = Vector3.new(math.random(-500,500), 500, math.random(-500,500))
        bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
        bv.Parent    = root
        task.delay(0.15, function() bv:Destroy() end)
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 3 — ADMIN
-- ═══════════════════════════════════════════════════════════════════════════════

local AdminTab = Window:CreateTab("Admin", nil)

AdminTab:CreateSection("Vote Kick", false)

AdminTab:CreateButton({
    Name = "Win Current Vote",
    Info = "Spam-fires votes on the currently active vote kick.",
    Interact = "Spam",
    Callback = function()
        for _ = 1, 25 do task.spawn(spamVote) end
        notify("Admin", "Vote spam sent!")
    end
})

AdminTab:CreateToggle({
    Name = "Auto-Win All Votes",
    Info = "Continuously spams votes so every vote kick passes instantly.",
    CurrentValue = false,
    Flag = "AutoWin",
    Callback = function(val)
        if val then
            startLoop("AutoWin", function()
                spamVote()
                task.wait(0.25)
            end)
        else
            stopLoop("AutoWin")
        end
    end
})

AdminTab:CreateButton({
    Name = "Kick All Players",
    Info = "Starts vote-kicking every other player in the server, one by one.",
    Interact = "Kick All",
    Callback = function()
        task.spawn(function() kickAll("Kicked by Untitled's Ray's Mods") end)
        notify("Admin", "Kicking all players...")
    end
})

AdminTab:CreateSection("Player Actions", false)

local playerOptions = {"(no players)"}

local playerDropdown = AdminTab:CreateDropdown({
    Name = "Select Player",
    Info = "Pick a player from the list, then use the buttons below.",
    Options = playerOptions,
    CurrentOption = "(no players)",
    MultiSelection = false,
    Flag = "SelectedPlayer",
    Callback = function(_) end
})

local function getSelectedPlayer()
    local sel = nil
    pcall(function() sel = Rayfield.Flags["SelectedPlayer"] end)
    if not sel or sel == "(no players)" or sel == "" then
        notify("Admin", "No player selected!")
        return nil
    end
    return sel
end

local function rebuildPlayerList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    playerOptions = #names > 0 and names or {"(no players)"}
    pcall(function() playerDropdown:Set(playerOptions[1]) end)
end

AdminTab:CreateButton({
    Name = "Refresh Player List",
    Info = "Re-scans the server for players.",
    Interact = "Refresh",
    Callback = function()
        rebuildPlayerList()
        notify("Admin", "Refreshed — " .. #playerOptions .. " player(s)")
    end
})

AdminTab:CreateButton({
    Name = "Kick Selected Player",
    Info = "Vote-kicks the player selected in the dropdown above.",
    Interact = "Kick",
    Callback = function()
        local sel = getSelectedPlayer()
        if not sel then return end
        kickPlayer(sel, "Kicked via Untitled's Ray's Mods")
        task.spawn(function()
            for _ = 1, 25 do
                task.wait(0.04)
                pcall(function()
                    local vk = getVoteKick()
                    if vk then vk:WaitForChild("VoteAdded"):FireServer() end
                end)
            end
        end)
        notify("Admin", "Kicking " .. sel .. "...")
    end
})

AdminTab:CreateButton({
    Name = "TP to Selected Player",
    Info = "Teleports you to the selected player.",
    Interact = "TP",
    Callback = function()
        local sel = getSelectedPlayer()
        if not sel then return end
        local root = getRoot()
        if not root then return end
        local target = Players:FindFirstChild(sel)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            notify("Admin", "Teleported to " .. sel)
        else
            notify("Admin", sel .. " has no character.")
        end
    end
})

Players.PlayerAdded:Connect(function()   task.wait(1);   rebuildPlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); rebuildPlayerList() end)
task.spawn(rebuildPlayerList)

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 4 — FUN
-- ═══════════════════════════════════════════════════════════════════════════════

local FunTab = Window:CreateTab("Fun", nil)

FunTab:CreateSection("Ragdoll", false)

FunTab:CreateButton({
    Name = "Force Ragdoll",
    Info = "Instantly puts your character into ragdoll state.",
    Interact = "Go",
    Callback = function()
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Ragdoll) end
    end
})

FunTab:CreateToggle({
    Name = "Stay Ragdolled",
    Info = "Prevents your character from ever getting back up.",
    CurrentValue = false,
    Flag = "StayRag",
    Callback = function(val)
        if val then
            startLoop("StayRag", function()
                local hum = getHum()
                if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                elseif hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                end
                task.wait(0.1)
            end)
        else
            stopLoop("StayRag")
            local hum = getHum()
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true) end
        end
    end
})

FunTab:CreateToggle({
    Name = "Auto Get Up",
    Info = "Automatically gets up whenever you stop moving.",
    CurrentValue = false,
    Flag = "AutoGetUp",
    Callback = function(val)
        if val then
            startLoop("AutoGetUp", function()
                local hum  = getHum()
                local root = getRoot()
                if hum and root and root.Velocity.Magnitude < 1 then
                    if hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
                task.wait(0.3)
            end)
        else
            stopLoop("AutoGetUp")
        end
    end
})

FunTab:CreateSection("Chaos", false)

FunTab:CreateToggle({
    Name = "Seizure Mode",
    Info = "Rapidly jitters your character's position and rotation.",
    CurrentValue = false,
    Flag = "Seizure",
    Callback = function(val)
        if val then
            startLoop("Seizure", function()
                local root = getRoot()
                if root then
                    root.CFrame = root.CFrame
                        * CFrame.new(math.random(-3,3)*0.1, 0, math.random(-3,3)*0.1)
                        * CFrame.Angles(
                            math.random(-5,5)*0.04,
                            math.random(-5,5)*0.04,
                            math.random(-5,5)*0.04
                        )
                end
            end)
        else
            stopLoop("Seizure")
        end
    end
})

FunTab:CreateToggle({
    Name = "Bunny Hop",
    Info = "Constantly jumps as fast as possible.",
    CurrentValue = false,
    Flag = "BunnyHop",
    Callback = function(val)
        if val then
            startLoop("BunnyHop", function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                task.wait(0.35)
            end)
        else
            stopLoop("BunnyHop")
        end
    end
})

FunTab:CreateButton({
    Name = "Fling Self",
    Info = "Launches you into the air in a random direction.",
    Interact = "Fling",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(math.random(-500,500), 500, math.random(-500,500))
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Parent   = root
        task.delay(0.15, function() bv:Destroy() end)
    end
})

FunTab:CreateButton({
    Name = "Explode — Fling Nearby",
    Info = "Flings all players within 40 studs away from you.",
    Interact = "Boom",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if pr and (root.Position - pr.Position).Magnitude < 40 then
                    local bv  = Instance.new("BodyVelocity")
                    local dir = (pr.Position - root.Position + Vector3.new(0,1,0)).Unit
                    bv.Velocity  = dir * 400 + Vector3.new(0, 150, 0)
                    bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
                    bv.Parent    = pr
                    task.delay(0.2, function() bv:Destroy() end)
                    count += 1
                end
            end
        end
        notify("Fun", "Flung " .. count .. " players!")
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 5 — VISUALS
-- ═══════════════════════════════════════════════════════════════════════════════

local VisualsTab = Window:CreateTab("Visuals", nil)

VisualsTab:CreateSection("Player ESP", false)

local espHighlights = {}

local function cleanESP()
    for _, h in pairs(espHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    espHighlights = {}
end

local function applyESP(player)
    if not player.Character then return end
    if espHighlights[player.Name] and espHighlights[player.Name].Parent then return end
    local h = Instance.new("Highlight")
    h.Name               = "_RaysESP"
    h.FillColor          = Color3.fromRGB(255, 50, 50)
    h.FillTransparency   = 0.4
    h.OutlineColor       = Color3.fromRGB(255, 255, 255)
    h.OutlineTransparency = 0
    h.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee            = player.Character
    h.Parent             = player.Character
    espHighlights[player.Name] = h
end

VisualsTab:CreateToggle({
    Name = "Highlight Players",
    Info = "Shows a red highlight around all players through walls.",
    CurrentValue = false,
    Flag = "ESPChams",
    Callback = function(val)
        if val then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then applyESP(p) end
            end
            startLoop("ESPChams", function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        if not p.Character:FindFirstChild("_RaysESP") then
                            espHighlights[p.Name] = nil
                            applyESP(p)
                        end
                    end
                end
                task.wait(1)
            end)
        else
            stopLoop("ESPChams")
            cleanESP()
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Nametags",
    Info = "Displays floating names above all players.",
    CurrentValue = false,
    Flag = "ESPNames",
    Callback = function(val)
        if val then
            startLoop("ESPNames", function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local root = p.Character:FindFirstChild("HumanoidRootPart")
                        if root and not root:FindFirstChild("_RaysName") then
                            local bg  = Instance.new("BillboardGui")
                            bg.Name         = "_RaysName"
                            bg.Size         = UDim2.new(0,130,0,22)
                            bg.StudsOffset  = Vector3.new(0,4,0)
                            bg.AlwaysOnTop  = true
                            bg.Adornee      = root
                            bg.Parent       = root
                            local lbl = Instance.new("TextLabel")
                            lbl.Size                 = UDim2.new(1,0,1,0)
                            lbl.BackgroundTransparency = 1
                            lbl.Text                 = p.Name
                            lbl.TextColor3           = Color3.fromRGB(255,255,255)
                            lbl.TextStrokeTransparency = 0
                            lbl.Font                 = Enum.Font.GothamBold
                            lbl.TextScaled           = true
                            lbl.Parent               = bg
                        end
                    end
                end
                task.wait(2)
            end)
        else
            stopLoop("ESPNames")
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local t = root:FindFirstChild("_RaysName")
                        if t then t:Destroy() end
                    end
                end
            end
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Health Bars",
    Info = "Shows HP bars above all players.",
    CurrentValue = false,
    Flag = "ESPHealth",
    Callback = function(val)
        if val then
            startLoop("ESPHealth", function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local root = p.Character:FindFirstChild("HumanoidRootPart")
                        local hum  = p.Character:FindFirstChildOfClass("Humanoid")
                        if root and hum then
                            local bg = root:FindFirstChild("_RaysHP")
                            if not bg then
                                bg = Instance.new("BillboardGui")
                                bg.Name        = "_RaysHP"
                                bg.Size        = UDim2.new(0,100,0,8)
                                bg.StudsOffset = Vector3.new(0,2.5,0)
                                bg.AlwaysOnTop = true
                                bg.Adornee     = root
                                bg.Parent      = root
                                local back = Instance.new("Frame")
                                back.Name             = "Back"
                                back.Size             = UDim2.new(1,0,1,0)
                                back.BackgroundColor3 = Color3.fromRGB(40,0,0)
                                back.BorderSizePixel  = 0
                                back.Parent           = bg
                                local bar = Instance.new("Frame")
                                bar.Name             = "Bar"
                                bar.Size             = UDim2.new(1,0,1,0)
                                bar.BackgroundColor3 = Color3.fromRGB(0,220,80)
                                bar.BorderSizePixel  = 0
                                bar.Parent           = back
                            end
                            local pct  = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
                            local back = bg:FindFirstChild("Back")
                            local bar  = back and back:FindFirstChild("Bar")
                            if bar then
                                bar.Size             = UDim2.new(pct, 0, 1, 0)
                                bar.BackgroundColor3 = Color3.fromRGB(
                                    math.floor((1-pct)*220),
                                    math.floor(pct*220),
                                    40
                                )
                            end
                        end
                    end
                end
                task.wait(0.1)
            end)
        else
            stopLoop("ESPHealth")
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local h = root:FindFirstChild("_RaysHP")
                        if h then h:Destroy() end
                    end
                end
            end
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Distance Labels",
    Info = "Shows how far away each player is from you in studs.",
    CurrentValue = false,
    Flag = "ESPDist",
    Callback = function(val)
        if val then
            startLoop("ESPDist", function()
                local myRoot = getRoot()
                if not myRoot then return end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local pr = p.Character:FindFirstChild("HumanoidRootPart")
                        if pr then
                            local dist = math.floor((myRoot.Position - pr.Position).Magnitude)
                            local bg   = pr:FindFirstChild("_RaysDist")
                            if not bg then
                                bg = Instance.new("BillboardGui")
                                bg.Name        = "_RaysDist"
                                bg.Size        = UDim2.new(0,100,0,16)
                                bg.StudsOffset = Vector3.new(0,1,0)
                                bg.AlwaysOnTop = true
                                bg.Adornee     = pr
                                bg.Parent      = pr
                                local lbl = Instance.new("TextLabel")
                                lbl.Name                   = "Label"
                                lbl.Size                   = UDim2.new(1,0,1,0)
                                lbl.BackgroundTransparency = 1
                                lbl.TextColor3             = Color3.fromRGB(255,220,50)
                                lbl.TextStrokeTransparency = 0
                                lbl.Font                   = Enum.Font.Gotham
                                lbl.TextScaled             = true
                                lbl.Parent                 = bg
                            end
                            local lbl = bg:FindFirstChild("Label")
                            if lbl then lbl.Text = tostring(dist) .. "m" end
                        end
                    end
                end
                task.wait(0.1)
            end)
        else
            stopLoop("ESPDist")
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local pr = p.Character:FindFirstChild("HumanoidRootPart")
                    if pr then
                        local d = pr:FindFirstChild("_RaysDist")
                        if d then d:Destroy() end
                    end
                end
            end
        end
    end
})

VisualsTab:CreateButton({
    Name = "Clear All ESP",
    Info = "Removes every ESP element from all players.",
    Interact = "Clear",
    Callback = function()
        stopLoop("ESPChams"); stopLoop("ESPNames")
        stopLoop("ESPHealth"); stopLoop("ESPDist")
        cleanESP()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, n in ipairs({"_RaysName","_RaysHP","_RaysDist"}) do
                        local t = root:FindFirstChild(n)
                        if t then t:Destroy() end
                    end
                end
            end
        end
        notify("ESP", "All ESP cleared!")
    end
})

VisualsTab:CreateSection("World", false)

VisualsTab:CreateToggle({
    Name = "Fullbright",
    Info = "Maximises brightness, removes fog and post-processing.",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(val)
        if val then
            Lighting.Brightness   = 10
            Lighting.ClockTime    = 14
            Lighting.FogEnd       = 1e9
            Lighting.GlobalShadows = false
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect")
                    or v:IsA("SunRaysEffect") then
                    v.Enabled = false
                end
            end
        else
            Lighting.Brightness   = 1
            Lighting.ClockTime    = 10
            Lighting.FogEnd       = 100000
            Lighting.GlobalShadows = true
        end
    end
})

VisualsTab:CreateToggle({
    Name = "No Post-Processing",
    Info = "Disables blur, depth of field, sun rays, and colour correction.",
    CurrentValue = false,
    Flag = "NoFX",
    Callback = function(val)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect")
                or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
                v.Enabled = not val
            end
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Rainbow Ambient",
    Info = "Cycles the world ambient light through rainbow colours.",
    CurrentValue = false,
    Flag = "RainbowAmbient",
    Callback = function(val)
        if val then
            startLoop("RainbowAmbient", function()
                Lighting.Ambient = Color3.fromHSV((tick() * 0.3) % 1, 0.5, 1)
                task.wait(0.05)
            end)
        else
            stopLoop("RainbowAmbient")
            Lighting.Ambient = Color3.fromRGB(70,70,70)
        end
    end
})

VisualsTab:CreateSection("Character FX", false)

VisualsTab:CreateToggle({
    Name = "Rainbow Body",
    Info = "Cycles your character's colour through a rainbow.",
    CurrentValue = false,
    Flag = "RainbowBody",
    Callback = function(val)
        if val then
            startLoop("RainbowBody", function()
                local char = getChar()
                if not char then return end
                local col = Color3.fromHSV((tick() * 0.3) % 1, 1, 1)
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.Color = col end
                end
                task.wait(0.05)
            end)
        else
            stopLoop("RainbowBody")
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Neon Material",
    Info = "Makes your character glow like a neon sign.",
    CurrentValue = false,
    Flag = "NeonMat",
    Callback = function(val)
        local char = getChar()
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Material = val and Enum.Material.Neon or Enum.Material.SmoothPlastic
            end
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Neon Trail",
    Info = "Leaves a rainbow trail behind your character.",
    CurrentValue = false,
    Flag = "NeonTrail",
    Callback = function(val)
        local char = getChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if val then
            local a0 = Instance.new("Attachment")
            a0.Name = "_TrailA0"; a0.Position = Vector3.new(0,1,0); a0.Parent = root
            local a1 = Instance.new("Attachment")
            a1.Name = "_TrailA1"; a1.Position = Vector3.new(0,-1,0); a1.Parent = root
            local trail = Instance.new("Trail")
            trail.Name        = "_RaysTrailFX"
            trail.Attachment0 = a0; trail.Attachment1 = a1
            trail.Lifetime    = 1.5; trail.MinLength = 0; trail.LightEmission = 1
            trail.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,0,128)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,128,255)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(128,255,0))
            })
            trail.Parent = root
        else
            for _, n in ipairs({"_RaysTrailFX","_TrailA0","_TrailA1"}) do
                local t = root:FindFirstChild(n); if t then t:Destroy() end
            end
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Sparkles",
    Info = "Adds golden sparkles to your character.",
    CurrentValue = false,
    Flag = "Sparkles",
    Callback = function(val)
        local char = getChar(); if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local ex = root:FindFirstChild("_RaysSparkles")
        if val and not ex then
            local sp = Instance.new("Sparkles")
            sp.Name         = "_RaysSparkles"
            sp.SparkleColor = Color3.fromRGB(255, 215, 0)
            sp.Parent       = root
        elseif not val and ex then
            ex:Destroy()
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Smoke",
    Info = "Emits a smoke trail from your character.",
    CurrentValue = false,
    Flag = "Smoke",
    Callback = function(val)
        local char = getChar(); if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local ex = root:FindFirstChild("_RaysSmoke")
        if val and not ex then
            local smoke = Instance.new("Smoke")
            smoke.Name         = "_RaysSmoke"
            smoke.Color        = Color3.fromRGB(180,180,180)
            smoke.Opacity      = 0.3
            smoke.RiseVelocity = 6
            smoke.Size         = 2
            smoke.Parent       = root
        elseif not val and ex then
            ex:Destroy()
        end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- REAPPLY SETTINGS ON RESPAWN
-- ═══════════════════════════════════════════════════════════════════════════════

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            if Rayfield.Flags["WalkSpeed"] then hum.WalkSpeed = Rayfield.Flags["WalkSpeed"] end
            if Rayfield.Flags["JumpPower"]  then hum.JumpPower  = Rayfield.Flags["JumpPower"]  end
            if Rayfield.Flags["Gravity"]    then workspace.Gravity = Rayfield.Flags["Gravity"]  end
        end)
    end
    pcall(function()
        if Rayfield.Flags["AutoAddons"] then
            task.wait(2)
            giveAllAddons()
        end
    end)
end)

notify("Untitled's Ray's Mods", "v2 Loaded! Health & Scale upgraded.")