InputModule - Full Cheatsheet
==============================

LOAD
  local Input = loadstring(game:HttpGet("https://raw.githubusercontent.com/oxygen015/roblox-modules/refs/heads/main/input_module/inputmodule.lua"))()


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KEYBOARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.tap("e")                         -- tap E once
Input.tap("Space", 0.1)                -- tap Space, hold 0.1s
Input.tapAsync("e")                    -- tap without yielding

Input.keyDown("w")                     -- hold W down
Input.keyUp("w")                       -- release W

Input.holdKey("w", 2)                  -- hold W for 2 seconds
Input.holdKeyAsync("w", 2)             -- hold W async

Input.combo({"LCtrl", "c"})            -- Ctrl+C
Input.combo({"LCtrl", "LShift", "i"})  -- Ctrl+Shift+I

Input.typeText("hello world", 0.05)    -- type a string char by char
Input.spam("e", 10, 0.1)               -- tap E 10 times, 0.1s apart
Input.spamAsync("e", 10, 0.1)          -- spam async

Input.isKeyHeld("w")                   -- returns true/false
Input.releaseAll()                     -- release every held key

Input.waitForKey("f")                  -- yields until player presses F


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MOUSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.mouseMove(500, 300)              -- move cursor to screen pos
Input.click(500, 300)                  -- left click at position
Input.click(500, 300, Input.RIGHT)     -- right click
Input.click(500, 300, Input.LEFT, 0.2) -- click + hold 0.2s
Input.clickAsync(500, 300)             -- click without yielding
Input.rightClick(500, 300)             -- right click shorthand
Input.doubleClick(500, 300)            -- double click

Input.drag(100, 200, 500, 200)         -- drag left to right
Input.drag(x1,y1, x2,y2, btn, steps, duration)

Input.scroll(500, 300, 3)              -- scroll up 3 ticks at pos
Input.scroll(500, 300, -3)             -- scroll down
Input.scrollHere(2)                    -- scroll at current cursor pos

Input.mouseDown(500, 300)              -- raw button down
Input.mouseUp(500, 300)                -- raw button up

Input.getMousePos()                    -- returns {x, y}
Input.getScreenCenter()                -- returns {x, y} of center
Input.getScreenSize()                  -- returns {width, height}

Input.waitForClick()                   -- yields, returns x, y of click


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CFRAME / WORLD CLICKING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.clickCFrame(someCFrame)          -- click a world CFrame pos
Input.clickPart(workspace.SomePart)    -- click a BasePart directly
Input.clickPosition(Vector3.new(0,0,0))-- click a world Vector3

Input.moveToCFrame(cf, steps, time)    -- smoothly move cursor to cf
Input.getScreenPos(cf)                 -- returns x, y or nil if off screen
Input.isOnScreen(cf)                   -- returns true/false

-- All three return false and warn if the target is off-screen.


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BUILDING MACROS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local m = Input.newMacro("mymacro")    -- create a named macro
m.loops = 3                            -- run 3 times
m.speed = 2.0                          -- run at 2x speed

Input.addKey(m, "e")                   -- tap E
Input.addKey(m, "e", 0.1, 0.5)        -- tap E (hold 0.1s), wait 0.5s before
Input.addClick(m, 500, 300)            -- left click at 500,300
Input.addClick(m, 500, 300, Input.RIGHT, 0.05, 0.2)
Input.addRightClick(m, 500, 300)       -- right click shorthand
Input.addDoubleClick(m, 500, 300)      -- double click
Input.addCFrameClick(m, someCF)        -- click world CFrame
Input.addPartClick(m, workspace.Part) -- click a part
Input.addMove(m, 400, 200)             -- move mouse
Input.addScroll(m, 500, 300, 2)        -- scroll up 2
Input.addScrollAction(m, -1)           -- scroll down at current pos
Input.addDrag(m, 100,200, 500,200)     -- drag
Input.addCombo(m, {"LCtrl","z"})       -- key combo
Input.addText(m, "hello", 0.05)        -- type text
Input.addWait(m, 1)                    -- wait 1 second

local inner = Input.newMacro("inner")
Input.addKey(inner, "f")
Input.addRepeat(m, inner, 5)           -- run inner macro 5 times inside m

Input.runMacro(m)                      -- run (yields until done)
Input.runMacroAsync(m)                 -- run without yielding
Input.runMacro(m, 10)                  -- override loops to 10


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MACRO STORE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.saveMacro("farm", m)             -- save macro by name
Input.loadMacro("farm")                -- get saved macro
Input.listMacros()                     -- returns table of names
Input.deleteMacro("farm")             -- remove from store


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECORDING (capture real input)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.startRecording("myrecording")    -- start capturing
-- do stuff in game...
local actions = Input.stopRecording()  -- stop, returns action table
-- or: Input.stopRecording("myrecording") to auto-save

Input.playRecording(actions)           -- replay at 1x speed
Input.playRecording(actions, 2.0, 3)  -- 2x speed, loop 3 times
Input.playRecording(Input.loadMacro("myrecording").actions)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HOTKEYS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.bindHotkey("F6", function()      -- bind F6 to a function
    Input.runMacroAsync(m)
end)

Input.unbindHotkey("F6")               -- remove one hotkey
Input.unbindAll()                      -- remove all hotkeys


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UTILITY / LOOPING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.wait(1.5)                        -- wait 1.5 seconds

Input.repeatAction(5, 0.5, function(i) -- run 5 times, 0.5s apart
    Input.tap("e")
end)
Input.repeatAsync(5, 0.5, function(i) end)  -- async version

local stop = Input.loop(1, function()  -- run every 1 second forever
    Input.tap("e")
end)
stop()                                 -- call the returned function to stop

Input.listKeys()                       -- print all valid key names


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
QUICK EXAMPLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Auto-farm loop:
local stop = Input.loop(0.5, function()
    Input.tap("e")
end)
Input.bindHotkey("F5", stop)  -- press F5 to stop

-- Click a part in the world:
Input.clickPart(workspace.MyButton)

-- Record then replay:
Input.startRecording()
task.wait(5)
local rec = Input.stopRecording("run1")
Input.playRecording(rec, 1.0, 999)

-- Ctrl+A then type replacement text:
Input.combo({"LCtrl", "a"})
Input.typeText("new text here")

-- Drag from left side to right:
Input.drag(200, 400, 800, 400, Input.LEFT, 30, 0.5)
