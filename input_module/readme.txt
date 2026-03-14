InputModule - Full Cheatsheet
==============================
v3.0.0

LOAD
  local Input = loadstring(game:HttpGet("https://raw.githubusercontent.com/oxygen015/roblox-modules/refs/heads/main/input_module/inputmodule.lua"))()


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KEYBOARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.tap("e")                              tap a key once
Input.tap("Space", 0.2)                     tap + hold 0.2s
Input.tapAsync("e")                         tap without yielding
Input.tapMultiple({"e","f","g"})            tap a list of keys in order
Input.tapMultiple({"e","f"}, 0.05, 0.1)     with holdTime + interval between each
Input.tapMultipleAsync({"e","f","g"})

Input.keyDown("w")                          hold key down
Input.keyUp("w")                            release key
Input.holdKey("w", 2)                       hold for 2 seconds
Input.holdKeyAsync("w", 2)
Input.holdKeys({"w","LShift"}, 1.5)         hold multiple keys together
Input.holdKeysAsync({"w","LShift"}, 1.5)

Input.combo({"LCtrl","c"})                  Ctrl+C
Input.combo({"LCtrl","LShift","i"})         Ctrl+Shift+I
Input.comboAsync({"LCtrl","z"})

Input.typeText("hello world")               type a string
Input.typeText("hello", 0.05, true)         type with random timing
Input.typeHuman("hello world", 60)          type at ~60 WPM with natural variation
                                            -- pauses longer after . , ! ?

Input.spam("e", 10, 0.1)                    tap E 10 times, 0.1s apart
Input.spamAsync("e", 10, 0.1)
Input.spamUntil("e", function()             spam until condition is true
    return someCondition
end, 0.1, 30)

Input.sequence({                            run a structured key sequence
    "w",
    {key="e", hold=0.1},
    {wait=0.5},
    {combo={"LCtrl","z"}},
    {text="hello"},                         type text inline in a sequence
})
Input.sequenceAsync({...})

Input.isKeyHeld("w")                        true/false
Input.isAnyKeyHeld({"w","a","s","d"})       true if any is held
Input.areAllKeysHeld({"LCtrl","LShift"})    true only if ALL are held
Input.releaseAll()                          release everything held

Input.waitForKey("f")                       yield until F is pressed
Input.waitForKey("f", 5)                    yield with 5s timeout
Input.waitForKeyRelease("f", 5)             yield until key released
Input.waitForAnyKey({"f","g","h"})          yield until any of the keys is pressed
Input.waitForAnyKey({"f","g"}, 5)           -- returns which key was pressed, or nil


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KEY NAMES REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Letters:     a-z  A-Z
Numbers:     0-9
Shifted:     ! @ # $ % ^ & * ( )
Special:     Space  Enter  Tab  Backspace  Escape
             Delete Insert Home End PageUp PageDown
             Up Down Left Right  CapsLock
Arrow keys:  Up Down Left Right
Function:    F1 - F12
Modifiers:   LShift RShift LCtrl RCtrl LAlt RAlt LMeta RMeta
Numpad:      Num0-Num9  Num.  Num+  Num-  Num*  Num/  NumEnter
Punctuation: - = [ ] \ ; ' , . /  and  ` (backtick)

Input.listKeys()       -- print all valid names
Input.hasKey("`")      -- check if a key is supported on this executor


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MOUSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.mouseMove(500, 300)                   move cursor instantly
Input.mouseMoveSmooth(500, 300, 0.4)        smooth move over 0.4s
Input.mouseMoveSmooth(x, y, t, "easeInOut") easing styles below
Input.mouseMoveNatural(500, 300, 0.4)       smooth move along a bezier curve
                                            -- random arc, looks human

Input.click(500, 300)                       left click
Input.click(500, 300, Input.RIGHT)          right click
Input.click(500, 300, Input.LEFT, 0.2)      hold 0.2s
Input.clickAsync(500, 300)
Input.rightClick(500, 300)
Input.rightClickAsync(500, 300)
Input.middleClick(500, 300)
Input.doubleClick(500, 300)
Input.tripleClick(500, 300)
Input.clickAndHold(500, 300, 2)             hold for 2 seconds

Input.clickHuman(500, 300)                  click with slight random pixel offset
Input.clickHuman(500, 300, Input.LEFT, 0.05, 6)   custom spread radius (default 4)
Input.clickFromCenter(100, -50)             click offset from screen center
Input.clickRegion(100, 100, 400, 300)       click random spot inside a rectangle
Input.clickUDim2(0.5, 0, 0.5, 0)           click at a UDim2 scale position
Input.clickUDim2(xScale, xOffset, yScale, yOffset, button, holdTime)
                                            -- negative xScale anchors from right edge

Input.drag(100,200, 500,200)                drag left to right
Input.drag(x1,y1, x2,y2, btn, steps, dur, "easeInOut")
Input.dragAsync(...)
Input.swipe(x1,y1, x2,y2, 0.2)             fast swipe

Input.scroll(500, 300, 3)                   scroll up 3 ticks at pos
Input.scroll(500, 300, -3)                  scroll down
Input.scrollHere(2)                         scroll at current cursor
Input.scrollSmooth(500, 300, 5, 0.5)        smooth scroll over 0.5s

Input.mouseDown(500, 300)                   raw button down
Input.mouseUp(500, 300)                     raw button up

Input.getMousePos()                         returns x, y as two numbers
Input.getMouseX()                           number
Input.getMouseY()                           number
Input.getScreenCenter()                     returns x, y as two numbers
Input.getScreenSize()                       returns width, height as two numbers
Input.screenFraction(0.5, 0.5)             returns x, y as two numbers

Input.waitForClick()                        yield, returns x, y
Input.waitForClick(Input.RIGHT, 5)          right click, 5s timeout

Input.startMouseTracking()                  start recording mouse positions
Input.stopMouseTracking()                   stop + returns trail table
Input.getMouseTrail()                       get current trail table
                                            -- each entry: {x, y, t}


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EASING STYLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Used in smooth moves, drags, macros, and camera functions.

  linear      constant speed (default)
  easeIn      starts slow, ends fast
  easeOut     starts fast, ends slow
  easeInOut   slow at both ends, fast in the middle
  bounce      bounces at the end
  elastic     springy overshoot
  sine        gentle sine curve
  cubic       stronger ease using t^3
  back        slight overshoot before settling


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCREEN / UDIM2 UTILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All of these auto-calculate based on your actual viewport size.

Input.fromUDim2(xScale, xOffset, yScale, yOffset)
    -- converts UDim2 values to real screen pixel x, y
    -- example: Input.fromUDim2(0.5, 0, 0.5, 0) -> screen center

Input.fromUDim2Smart(xScale, xOffset, yScale, yOffset)
    -- same as above but negative scales anchor from the right/bottom edge
    -- example: Input.fromUDim2Smart(-0.02, 0, 0.8, 0)
    --          -> x is 2% from the right edge

Input.getScreenSize()                       returns width, height
Input.getScreenCenter()                     returns center x, y
Input.screenFraction(0.5, 0.5)             returns x, y at that fraction
Input.screenDistance(cf)                    pixel distance from screen center to a CFrame


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CFRAME / WORLD INTERACTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.clickCFrame(cf)                       click a world CFrame
Input.clickCFrameAsync(cf)
Input.clickPart(workspace.MyPart)           click a BasePart
Input.clickPartAsync(workspace.MyPart)
Input.clickPosition(Vector3.new(0,5,0))     click a world Vector3
Input.clickPositionAsync(Vector3.new(...))
Input.clickModel(workspace.MyModel)         click model bounding box center
Input.clickNearestPart("ButtonName")        click nearest part with that name
Input.clickNearestPart()                    click nearest part (any name)
Input.clickNearestOnScreen("ButtonName")    click the part closest to screen center
Input.clickNearestOnScreen()                -- any name, on screen only
Input.clickWhenOnScreen(cf, btn, hold, 10)  wait until on screen then click

Input.hoverCFrame(cf)                       move mouse to cf, no click
Input.hoverCFrame(cf, 1)                    hover and wait 1s
Input.hoverPart(part, 1)
Input.moveToCFrame(cf, 0.3, "easeOut")      smooth move to cf
Input.moveToPart(part, 0.3)
Input.dragBetweenParts(partA, partB)        drag from A to B

Input.isOnScreen(cf)                        true/false
Input.getScreenPos(cf)                      returns x, y or nil, nil
Input.getPartScreenPos(part)                returns x, y or nil, nil
Input.waitUntilOnScreen(cf, 10)             yield until visible (10s timeout)
Input.screenDistance(cf)                    pixel distance from screen center

-- All world functions warn + return false if the target is off-screen.


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CAMERA CONTROL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.lookAt(Vector3.new(0, 5, 0))          snap camera to face a world position
                                            -- switches to Scriptable camera mode

Input.lookAtSmooth(Vector3.new(0,5,0), 0.4)         smooth camera rotation
Input.lookAtSmooth(pos, duration, "easeInOut")       with easing

Input.restoreCamera()                       restore camera to previous mode (Custom)

Input.lookAndClick(Vector3.new(0,5,0))      look at pos, wait for it to be on screen,
                                            click it, then restore camera automatically
Input.lookAndClick(pos, button, holdTime, timeout)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BUILDING MACROS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local m = Input.newMacro("mymacro")
m.loops = 5
m.speed = 2.0
m.enabled = false     -- disable without deleting

Input.addKey(m, "e")                        tap E
Input.addKey(m, "e", 0.1, 0.5)             tap E (hold 0.1s), pre-delay 0.5s
Input.addKeyDown(m, "w")                    hold W down (no release)
Input.addKeyUp(m, "w")                      release W
Input.addSpam(m, "e", 10, 0.05)             spam E 10 times inside macro
Input.addSequence(m, {"w","a","s","d"}, 0.1)

Input.addClick(m, 500, 300)
Input.addClick(m, 500, 300, Input.RIGHT, 0.05, 0.2)
Input.addRightClick(m, 500, 300)
Input.addDoubleClick(m, 500, 300)
Input.addTripleClick(m, 500, 300)
Input.addCFrameClick(m, workspace.Part.CFrame)
Input.addPartClick(m, workspace.Part)
Input.addUDim2Click(m, 0.5, 0, 0.5, 0)     click at UDim2 scale position
Input.addUDim2Click(m, xScale, xOffset, yScale, yOffset, button, holdTime, delay)

Input.addMove(m, 400, 200)
Input.addSmoothMove(m, 400, 200, 0.3, "easeInOut")
Input.addScroll(m, 500, 300, 2)
Input.addScrollHere(m, -1)
Input.addDrag(m, 100,200, 500,200)
Input.addDrag(m, x1,y1, x2,y2, btn, steps, dur, "easeOut", preDelay)
Input.addSwipe(m, 100,300, 700,300, 0.15)
Input.addCombo(m, {"LCtrl","z"})
Input.addText(m, "hello", 0.05)
Input.addText(m, "hello", 0.05, true)       randomized typing speed
Input.addWait(m, 1)
Input.addReleaseAll(m)

Input.addCallback(m, function()             run any function as a macro step
    print("custom step!")
end)
Input.addPrint(m, "reached step 3")         debug print at a specific step

local inner = Input.newMacro("inner")
Input.addKey(inner, "f")
Input.addRepeat(m, inner, 5)                run inner 5 times inside m

Input.addLabel(m, "start")                  named jump target
Input.addGoto(m, "start", 3)                jump back to label 3 times

Input.addCondition(m,                       if/else branching
    function() return someValue == true end,
    trueMacro,
    falseMacro
)

Input.runMacro(m)
Input.runMacroAsync(m)
Input.runMacro(m, 10)                       override loops
Input.runMacro(m, nil, 0.5)                 override speed

Input.debugMacro(m)                         print a full list of macro steps


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MACRO MANAGEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.saveMacro("farm", m)
Input.loadMacro("farm")
Input.listMacros()                          returns sorted table of names
Input.deleteMacro("farm")
Input.clearMacro(m)                         empty the actions list
Input.copyMacro(m, "farm_v2")               duplicate a macro
Input.mergeMacros(macroA, macroB, "combo")  append B onto A
Input.debugMacro(m)                         print step-by-step breakdown


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECORDING (capture real input)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.startRecording("run1")
-- play the game, do your thing...
local actions = Input.stopRecording()
-- or auto-save:
Input.stopRecording("run1")

Input.playRecording(actions)
Input.playRecording(actions, 1.5, 3)        1.5x speed, loop 3 times
Input.playRecordingAsync(actions, 2.0)

Input.isRecording()                         true/false
Input.getLastRecording()                    get last action table


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HOTKEYS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.bindHotkey("F6", function()
    Input.runMacroAsync(m)
end)
Input.bindHotkey("F7", stopFn, "Stop loop")

Input.bindHotkeyCombo({"LCtrl","F6"}, function()
    print("Ctrl+F6 pressed")
end)

Input.bindToggle("F5", startFn, stopFn)     one key to start AND stop
Input.bindToggle("F5", startFn, stopFn, "Farm toggle")

Input.unbindHotkey("F6")
Input.unbindAll()
Input.listHotkeys()                         returns list of bound keys


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EVENT LISTENERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local conn = Input.onKey("f", function()    fires every time F is pressed
    print("F pressed!")
end)
conn:Disconnect()                           remove listener

Input.onKeyRelease("f", function()
    print("F released!")
end)

Input.onMouseClick(Input.LEFT, function(x, y)
    print("Clicked at", x, y)
end)

Input.onMouseMove(function(x, y)            fires on every mouse movement
    print("Mouse at", x, y)
end)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UTILITY / LOOPING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.wait(1.5)
Input.waitRandom(0.5, 1.5)                  wait random time between 0.5-1.5s
Input.waitFor(function()                    yield until a condition is true
    return someValue == true
end)
Input.waitFor(condFn, timeout, interval)    with optional timeout + check interval
Input.delay(2, function()                   run callback after delay, non-blocking
    print("2 seconds later")
end)

Input.repeatAction(5, 0.5, function(i)
    Input.tap("e")
end)
Input.repeatAsync(5, 0.5, function(i) end)

local stop = Input.loop(1, function()       run every 1s forever
    Input.tap("e")
end)
stop()                                      call returned function to stop

local stop = Input.loopFor(30, 0.5, function()   run for 30s, every 0.5s
    Input.tap("e")
end)

Input.loopTimes(10, 0.2, function(i)        run exactly 10 times
    print("pass "..i)
end)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LOGGING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.setLogging(false)                     disable all print output
Input.setLogging(true)                      re-enable
Input.getLogs()                             returns table of {time, text} entries
Input.clearLogs()                           wipe log history


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STATS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Input.getStats()       -- {taps, clicks, scrolls, drags, macrosRun, recordingsSaved}
Input.printStats()     -- print to console
Input.resetStats()
Input.getVersion()     -- "3.0.0"


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRACTICAL EXAMPLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Auto-farm toggle with F5 (new bindToggle, no manual state needed):
local stopFarm
Input.bindToggle("F5",
    function()
        stopFarm = Input.loop(0.5, function()
            Input.tap("e")
        end)
        print("Farm started")
    end,
    function()
        if stopFarm then stopFarm() end
        print("Farm stopped")
    end
)

-- Click a part in the 3D world:
Input.clickPart(workspace.SomeButton)

-- Look at a world position and click it (handles camera automatically):
Input.lookAndClick(Vector3.new(-151.37, 4.67, 18.64))

-- Click a GUI button using UDim2 coordinates (auto screen calculation):
Input.clickUDim2(0.5, 0, 0.84, -24)

-- Click nearest part named "Collect":
Input.clickNearestPart("Collect")

-- Click the part named "Ore" that is closest to the center of the screen:
Input.clickNearestOnScreen("Ore")

-- Record then replay at 2x speed:
Input.startRecording("run1")
task.wait(5)
Input.stopRecording("run1")
Input.playRecordingAsync(Input.loadMacro("run1").actions, 2.0, 999)

-- Macro with branching:
local farmMacro = Input.newMacro("farm")
Input.addCondition(farmMacro,
    function() return workspace:FindFirstChild("Ore") ~= nil end,
    collectMacro,
    walkMacro
)
Input.runMacroAsync(farmMacro)

-- Macro with debug prints and a callback step:
local m = Input.newMacro("test")
Input.addPrint(m, "starting")
Input.addKey(m, "e")
Input.addCallback(m, function()
    print("custom logic here")
end)
Input.addPrint(m, "done")
Input.runMacro(m)

-- Human-like typing at 80 WPM:
Input.typeHuman("hello world", 80)

-- Natural bezier mouse movement:
Input.mouseMoveNatural(800, 400, 0.5)

-- Smooth drag with easing:
Input.drag(200, 400, 800, 400, Input.LEFT, 30, 0.5, "easeInOut")

-- Wait for player to press any of several keys:
print("Press F, G, or H to begin...")
local key = Input.waitForAnyKey({"f","g","h"})
print("You pressed: "..tostring(key))
Input.runMacroAsync(myMacro)

-- Wait for a condition before doing something:
Input.waitFor(function()
    return workspace:FindFirstChild("Boss") ~= nil
end, 60)
print("Boss spawned, starting macro")
Input.runMacroAsync(bossMacro)

-- Fire-and-forget delayed action:
Input.delay(3, function()
    Input.tap("e")
    print("tapped e after 3 seconds")
end)

-- Track mouse movement for 5 seconds:
Input.startMouseTracking()
task.wait(5)
local trail = Input.stopMouseTracking()
print("recorded "..#trail.." mouse positions")
