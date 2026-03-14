-- InputModule.lua
-- A full keyboard + mouse control module for Roblox
-- Usage: local Input = require(InputModule)  OR  loadstring(...)()
-- Compatible with VirtualInputManager (exploit/localscript context)

local InputModule = {}

-- ─────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────

local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ─────────────────────────────────────────
--  KEY MAP  (character → KeyCode)
-- ─────────────────────────────────────────

local KeyMap = {
    -- Numbers
    ["0"]=Enum.KeyCode.Zero,  ["1"]=Enum.KeyCode.One,   ["2"]=Enum.KeyCode.Two,
    ["3"]=Enum.KeyCode.Three, ["4"]=Enum.KeyCode.Four,  ["5"]=Enum.KeyCode.Five,
    ["6"]=Enum.KeyCode.Six,   ["7"]=Enum.KeyCode.Seven, ["8"]=Enum.KeyCode.Eight,
    ["9"]=Enum.KeyCode.Nine,

    -- Shifted numbers
    ["!"]=Enum.KeyCode.One,   ["@"]=Enum.KeyCode.Two,   ["#"]=Enum.KeyCode.Three,
    ["$"]=Enum.KeyCode.Four,  ["%"]=Enum.KeyCode.Five,  ["^"]=Enum.KeyCode.Six,
    ["&"]=Enum.KeyCode.Seven, ["*"]=Enum.KeyCode.Eight, ["("]=Enum.KeyCode.Nine,
    [")"]=Enum.KeyCode.Zero,

    -- Letters (both cases map to same KeyCode; shift handled separately)
    ["a"]=Enum.KeyCode.A, ["A"]=Enum.KeyCode.A,
    ["b"]=Enum.KeyCode.B, ["B"]=Enum.KeyCode.B,
    ["c"]=Enum.KeyCode.C, ["C"]=Enum.KeyCode.C,
    ["d"]=Enum.KeyCode.D, ["D"]=Enum.KeyCode.D,
    ["e"]=Enum.KeyCode.E, ["E"]=Enum.KeyCode.E,
    ["f"]=Enum.KeyCode.F, ["F"]=Enum.KeyCode.F,
    ["g"]=Enum.KeyCode.G, ["G"]=Enum.KeyCode.G,
    ["h"]=Enum.KeyCode.H, ["H"]=Enum.KeyCode.H,
    ["i"]=Enum.KeyCode.I, ["I"]=Enum.KeyCode.I,
    ["j"]=Enum.KeyCode.J, ["J"]=Enum.KeyCode.J,
    ["k"]=Enum.KeyCode.K, ["K"]=Enum.KeyCode.K,
    ["l"]=Enum.KeyCode.L, ["L"]=Enum.KeyCode.L,
    ["m"]=Enum.KeyCode.M, ["M"]=Enum.KeyCode.M,
    ["n"]=Enum.KeyCode.N, ["N"]=Enum.KeyCode.N,
    ["o"]=Enum.KeyCode.O, ["O"]=Enum.KeyCode.O,
    ["p"]=Enum.KeyCode.P, ["P"]=Enum.KeyCode.P,
    ["q"]=Enum.KeyCode.Q, ["Q"]=Enum.KeyCode.Q,
    ["r"]=Enum.KeyCode.R, ["R"]=Enum.KeyCode.R,
    ["s"]=Enum.KeyCode.S, ["S"]=Enum.KeyCode.S,
    ["t"]=Enum.KeyCode.T, ["T"]=Enum.KeyCode.T,
    ["u"]=Enum.KeyCode.U, ["U"]=Enum.KeyCode.U,
    ["v"]=Enum.KeyCode.V, ["V"]=Enum.KeyCode.V,
    ["w"]=Enum.KeyCode.W, ["W"]=Enum.KeyCode.W,
    ["x"]=Enum.KeyCode.X, ["X"]=Enum.KeyCode.X,
    ["y"]=Enum.KeyCode.Y, ["Y"]=Enum.KeyCode.Y,
    ["z"]=Enum.KeyCode.Z, ["Z"]=Enum.KeyCode.Z,

    -- Special keys (use these string names)
    ["Space"]    = Enum.KeyCode.Space,
    ["Enter"]    = Enum.KeyCode.Return,
    ["Tab"]      = Enum.KeyCode.Tab,
    ["Backspace"]= Enum.KeyCode.Backspace,
    ["Escape"]   = Enum.KeyCode.Escape,
    ["Delete"]   = Enum.KeyCode.Delete,
    ["Insert"]   = Enum.KeyCode.Insert,
    ["Home"]     = Enum.KeyCode.Home,
    ["End"]      = Enum.KeyCode.End,
    ["PageUp"]   = Enum.KeyCode.PageUp,
    ["PageDown"] = Enum.KeyCode.PageDown,
    ["Up"]       = Enum.KeyCode.Up,
    ["Down"]     = Enum.KeyCode.Down,
    ["Left"]     = Enum.KeyCode.Left,
    ["Right"]    = Enum.KeyCode.Right,
    ["F1"]       = Enum.KeyCode.F1,
    ["F2"]       = Enum.KeyCode.F2,
    ["F3"]       = Enum.KeyCode.F3,
    ["F4"]       = Enum.KeyCode.F4,
    ["F5"]       = Enum.KeyCode.F5,
    ["F6"]       = Enum.KeyCode.F6,
    ["F7"]       = Enum.KeyCode.F7,
    ["F8"]       = Enum.KeyCode.F8,
    ["F9"]       = Enum.KeyCode.F9,
    ["F10"]      = Enum.KeyCode.F10,
    ["F11"]      = Enum.KeyCode.F11,
    ["F12"]      = Enum.KeyCode.F12,
    ["LShift"]   = Enum.KeyCode.LeftShift,
    ["RShift"]   = Enum.KeyCode.RightShift,
    ["LCtrl"]    = Enum.KeyCode.LeftControl,
    ["RCtrl"]    = Enum.KeyCode.RightControl,
    ["LAlt"]     = Enum.KeyCode.LeftAlt,
    ["RAlt"]     = Enum.KeyCode.RightAlt,
    ["LMeta"]    = Enum.KeyCode.LeftMeta,
    ["RMeta"]    = Enum.KeyCode.RightMeta,
    ["CapsLock"] = Enum.KeyCode.CapsLock,
    ["NumLock"]  = Enum.KeyCode.NumLock,
    ["`"]        = Enum.KeyCode.BackQuote,
    ["-"]        = Enum.KeyCode.Minus,
    ["="]        = Enum.KeyCode.Equals,
    ["["]        = Enum.KeyCode.LeftBracket,
    ["]"]        = Enum.KeyCode.RightBracket,
    ["\\"]       = Enum.KeyCode.BackSlash,
    [";"]        = Enum.KeyCode.Semicolon,
    ["'"]        = Enum.KeyCode.Quote,
    [","]        = Enum.KeyCode.Comma,
    ["."]        = Enum.KeyCode.Period,
    ["/"]        = Enum.KeyCode.Slash,
}

-- Characters that require Shift to be held
local ShiftChars = {
    "!","@","#","$","%","^","&","*","(",")",
    "A","B","C","D","E","F","G","H","I","J","K","L","M",
    "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "~","_","+","{","}","|",":","\"","<",">","?"
}
local ShiftSet = {}
for _, v in ipairs(ShiftChars) do ShiftSet[v] = true end

-- ─────────────────────────────────────────
--  INTERNAL HELPERS
-- ─────────────────────────────────────────

local function resolveKey(key)
    return KeyMap[key]
end

local function needsShift(key)
    return ShiftSet[key] == true
end

-- ─────────────────────────────────────────
--  KEYBOARD API
-- ─────────────────────────────────────────

--- Press a key down (non-blocking).
-- @param key  string  single char like "a", "A", "1", or named key like "Space", "Enter", "F5"
function InputModule.keyDown(key)
    local kc = resolveKey(key)
    if not kc then warn("[InputModule] Unknown key: " .. tostring(key)) return end
    if needsShift(key) then
        VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
    end
    VIM:SendKeyEvent(true, kc, false, game)
end

--- Release a key (non-blocking).
function InputModule.keyUp(key)
    local kc = resolveKey(key)
    if not kc then warn("[InputModule] Unknown key: " .. tostring(key)) return end
    VIM:SendKeyEvent(false, kc, false, game)
    if needsShift(key) then
        VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end
end

--- Tap a key: press + wait holdTime + release (yields).
-- @param key       string
-- @param holdTime  number  seconds to hold (default 0.05)
function InputModule.tap(key, holdTime)
    holdTime = holdTime or 0.05
    InputModule.keyDown(key)
    task.wait(holdTime)
    InputModule.keyUp(key)
end

--- Type a full string, one character at a time.
-- @param text      string  the text to type
-- @param interval  number  seconds between each character (default 0.05)
function InputModule.typeText(text, interval)
    interval = interval or 0.05
    for i = 1, #text do
        local ch = text:sub(i, i)
        InputModule.tap(ch, 0.04)
        task.wait(interval)
    end
end

--- Hold multiple keys at once, run a callback, then release all.
-- Example: Input.combo({"LCtrl", "c"})  →  Ctrl+C
-- @param keys      table    list of key strings to hold simultaneously
-- @param callback  function optional function to call while keys are held
function InputModule.combo(keys, callback)
    for _, k in ipairs(keys) do
        InputModule.keyDown(k)
    end
    if callback then callback() end
    task.wait(0.05)
    for i = #keys, 1, -1 do
        InputModule.keyUp(keys[i])
    end
end

--- Check if a real physical key is currently held by the user.
function InputModule.isKeyHeld(keyCode)
    return UIS:IsKeyDown(keyCode)
end

-- ─────────────────────────────────────────
--  MOUSE API
-- ─────────────────────────────────────────

-- Button constants
InputModule.LEFT   = 0
InputModule.RIGHT  = 1
InputModule.MIDDLE = 2

--- Move the mouse cursor to (x, y) screen position.
function InputModule.mouseMove(x, y)
    VIM:SendMouseMoveEvent(x, y, game)
end

--- Press a mouse button down at (x, y).
-- button: InputModule.LEFT / RIGHT / MIDDLE
function InputModule.mouseDown(x, y, button)
    button = button or InputModule.LEFT
    VIM:SendMouseButtonEvent(x, y, button, true, game, 1)
end

--- Release a mouse button at (x, y).
function InputModule.mouseUp(x, y, button)
    button = button or InputModule.LEFT
    VIM:SendMouseButtonEvent(x, y, button, false, game, 1)
end

--- Click at (x, y) — move, press, wait, release (yields).
-- @param x, y      number  screen coords
-- @param button    number  LEFT/RIGHT/MIDDLE (default LEFT)
-- @param holdTime  number  seconds to hold click (default 0.05)
function InputModule.click(x, y, button, holdTime)
    button   = button   or InputModule.LEFT
    holdTime = holdTime or 0.05
    InputModule.mouseMove(x, y)
    task.wait(0.02)
    InputModule.mouseDown(x, y, button)
    task.wait(holdTime)
    InputModule.mouseUp(x, y, button)
end

--- Right-click shorthand.
function InputModule.rightClick(x, y, holdTime)
    InputModule.click(x, y, InputModule.RIGHT, holdTime)
end

--- Double-click at (x, y).
function InputModule.doubleClick(x, y, button)
    InputModule.click(x, y, button, 0.05)
    task.wait(0.08)
    InputModule.click(x, y, button, 0.05)
end

--- Click and drag from (x1,y1) to (x2,y2).
-- @param steps     number  how many move steps during drag (default 20)
-- @param duration  number  total drag time in seconds (default 0.3)
function InputModule.drag(x1, y1, x2, y2, button, steps, duration)
    button   = button   or InputModule.LEFT
    steps    = steps    or 20
    duration = duration or 0.3

    InputModule.mouseMove(x1, y1)
    task.wait(0.02)
    InputModule.mouseDown(x1, y1, button)
    task.wait(0.05)

    local stepDelay = duration / steps
    for i = 1, steps do
        local t  = i / steps
        local cx = x1 + (x2 - x1) * t
        local cy = y1 + (y2 - y1) * t
        InputModule.mouseMove(math.floor(cx), math.floor(cy))
        task.wait(stepDelay)
    end

    InputModule.mouseUp(x2, y2, button)
end

--- Scroll the mouse wheel at (x, y).
-- @param x, y   number  screen coords
-- @param amount number  positive = scroll up, negative = scroll down
function InputModule.scroll(x, y, amount)
    amount = amount or 1
    local up = amount > 0
    for _ = 1, math.abs(amount) do
        VIM:SendMouseWheelEvent(x, y, up, game)
        task.wait(0.02)
    end
end

--- Get the current mouse position as {x, y}.
function InputModule.getMousePos()
    local pos = UIS:GetMouseLocation()
    return {x = pos.X, y = pos.Y}
end

--- Get screen center as {x, y}.
function InputModule.getScreenCenter()
    local vp = workspace.CurrentCamera.ViewportSize
    return {x = math.floor(vp.X / 2), y = math.floor(vp.Y / 2)}
end

-- ─────────────────────────────────────────
--  MACRO RECORDER / PLAYER
-- ─────────────────────────────────────────

local recording    = false
local macroActions = {}
local recordStart  = 0
local recConn1, recConn2

--- Start recording all keyboard and mouse input into a macro table.
function InputModule.startRecording()
    macroActions = {}
    recordStart  = tick()
    recording    = true

    recConn1 = UIS.InputBegan:Connect(function(input, gpe)
        if not recording then return end
        local t = tick() - recordStart
        if input.UserInputType == Enum.UserInputType.Keyboard then
            table.insert(macroActions, {time=t, type="keyDown", key=tostring(input.KeyCode)})
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            table.insert(macroActions, {time=t, type="mouseDown", x=input.Position.X, y=input.Position.Y, button=0})
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            table.insert(macroActions, {time=t, type="mouseDown", x=input.Position.X, y=input.Position.Y, button=1})
        end
    end)

    recConn2 = UIS.InputEnded:Connect(function(input, gpe)
        if not recording then return end
        local t = tick() - recordStart
        if input.UserInputType == Enum.UserInputType.Keyboard then
            table.insert(macroActions, {time=t, type="keyUp", key=tostring(input.KeyCode)})
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            table.insert(macroActions, {time=t, type="mouseUp", x=input.Position.X, y=input.Position.Y, button=0})
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            table.insert(macroActions, {time=t, type="mouseUp", x=input.Position.X, y=input.Position.Y, button=1})
        end
    end)

    print("[InputModule] Recording started.")
end

--- Stop recording and return the macro table.
function InputModule.stopRecording()
    recording = false
    if recConn1 then recConn1:Disconnect() end
    if recConn2 then recConn2:Disconnect() end
    print("[InputModule] Recording stopped. " .. #macroActions .. " actions captured.")
    return macroActions
end

--- Play back a recorded macro (or any compatible action table).
-- @param actions  table   macro action list
-- @param speed    number  playback speed multiplier (default 1.0)
-- @param loops    number  how many times to loop (default 1)
function InputModule.playMacro(actions, speed, loops)
    speed = speed or 1.0
    loops = loops or 1

    for loop = 1, loops do
        local startTime = tick()
        local i = 1

        while i <= #actions do
            local action  = actions[i]
            local elapsed = (tick() - startTime) * speed

            if elapsed >= action.time then
                if action.type == "keyDown" then
                    -- action.key is "Enum.KeyCode.X" string, extract letter
                    local kname = action.key:match("KeyCode%.(.+)")
                    if kname then
                        local kc = Enum.KeyCode[kname]
                        if kc then VIM:SendKeyEvent(true, kc, false, game) end
                    end

                elseif action.type == "keyUp" then
                    local kname = action.key:match("KeyCode%.(.+)")
                    if kname then
                        local kc = Enum.KeyCode[kname]
                        if kc then VIM:SendKeyEvent(false, kc, false, game) end
                    end

                elseif action.type == "mouseDown" then
                    VIM:SendMouseButtonEvent(action.x, action.y, action.button, true, game, 1)

                elseif action.type == "mouseUp" then
                    VIM:SendMouseButtonEvent(action.x, action.y, action.button, false, game, 1)

                elseif action.type == "mouseMove" then
                    VIM:SendMouseMoveEvent(action.x, action.y, game)

                elseif action.type == "scroll" then
                    VIM:SendMouseWheelEvent(action.x, action.y, action.up, game)
                end

                i = i + 1
            else
                task.wait(0.01)
            end
        end

        if loop < loops then task.wait(0.1) end
    end
end

-- ─────────────────────────────────────────
--  UTILITY
-- ─────────────────────────────────────────

--- Wait a number of seconds (just a readable alias).
function InputModule.wait(seconds)
    task.wait(seconds)
end

--- Print all available named keys.
function InputModule.listKeys()
    local keys = {}
    for k in pairs(KeyMap) do table.insert(keys, k) end
    table.sort(keys)
    print("[InputModule] Available keys: " .. table.concat(keys, ", "))
end

-- ─────────────────────────────────────────

print("[InputModule] Loaded. Keyboard + Mouse ready.")
return InputModule