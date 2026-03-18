╔══════════════════════════════════════════════════════════════════════════════╗
║                       InputModule  v2.0.0  README                          ║
║              Keyboard · Mouse · Macros · Recording · Hotkeys               ║
║                     Camera · World · Forums UI                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

── WHAT IS THIS? ───────────────────────────────────────────────────────────────

InputModule is a comprehensive Roblox exploit input-automation library.
It wraps VirtualInputManager and UserInputService to give you clean, high-level
APIs for keyboard automation, mouse control, macro building, input recording,
hotkeys, camera control, and more.

Version 2.0.0 replaces the old custom CoreGui UI with the Forums UI library
(xHeptc/forumsLib), adds executor detection, and adds a large number of new
UI sections.

── REQUIREMENTS ────────────────────────────────────────────────────────────────

  • A Roblox exploit executor that supports:
      - VirtualInputManager (VIM) ← REQUIRED for all input simulation
      - loadstring()              ← needed to load the Forums UI library
      - game:HttpGet()            ← needed to download the Forums UI library

  Supported / tested executors:
      Synapse X   ✓   Full support
      Synapse V3  ✓   Full support
      KRNL        ✓   Full support
      ScriptWare  ✓   Full support
      Wave        ✓   Full support
      Fluxus      ✓   Full support (HttpGet required for UI)
      Delta       ✓   Full support
      Electron    ✓   Partial (no WebSocket)
      Oxygen U    ✓   Partial
      Coco Z      ✓   Partial

  The executor name and feature support are detected automatically at load
  time and displayed in the window title bar.

── QUICK START ─────────────────────────────────────────────────────────────────

  -- Load the module (paste into your executor)
  local Input = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

  -- Open the GUI
  Input.openUI()

  -- Or use it programmatically:
  Input.tap("e")
  Input.click(500, 300)
  Input.typeHuman("hello world", 80)

── OPENING THE UI ──────────────────────────────────────────────────────────────

  Input.openUI()

  This downloads the Forums UI library from:
    https://raw.githubusercontent.com/xHeptc/forumsLib/main/source.lua
  and builds the full control panel.

  The window title shows:
    InputModule v2.0.0  |  <ExecutorName>  |  SUPPORTED / NOT SUPPORTED

── UI SECTIONS ─────────────────────────────────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────────────┐
  │  1. ℹ  Info & Executor                                                   │
  │     Executor name, feature flags, stats, logs.                           │
  │                                                                          │
  │  2. ⏺  Recorder                                                          │
  │     Record live keyboard/mouse input. Live timer display. Play back      │
  │     recordings with speed and loop controls.                             │
  │                                                                          │
  │  3. ⚙  Macro Builder                                                     │
  │     Create, load, save, copy, reverse macros. Add taps, clicks,          │
  │     scrolls, drags, text, waits, release-alls, print markers, and more.  │
  │     Run macros with loop/speed controls.                                 │
  │                                                                          │
  │  4. ⌨  Keyboard                                                          │
  │     Tap, down, up, hold, release all. Spam (n times or continuous        │
  │     toggle). Type text (normal / human WPM). Fire key combos.            │
  │     Sequences. Print held keys.                                          │
  │                                                                          │
  │  5. 🖱  Mouse                                                             │
  │     Live position display. Instant / smooth / natural move.              │
  │     Left, right, double, human, center, current-pos clicks.              │
  │     Drag, swipe. Scroll up/down at cursor or coordinates.                │
  │     Mouse trail tracking and speed readout.                              │
  │                                                                          │
  │  6. 🔑  Hotkeys                                                           │
  │     Bind F6 → releaseAll, F7 → spam toggle, F8 → run current macro.      │
  │     List and unbind all hotkeys.                                         │
  │                                                                          │
  │  7. 📷  Camera & World                                                    │
  │     Look at origin, restore camera. Screen center/size. List parts       │
  │     on screen. Click nearest on-screen part.                             │
  │                                                                          │
  │  8. ⏱  Loops & Timing                                                    │
  │     Start/stop loop (taps e on interval). Loop for duration. Repeat      │
  │     N times. Alternate between two actions.                              │
  │                                                                          │
  │  9. 💾  Profiles                                                          │
  │     Save/load/list named profiles (snapshot of macros + hotkeys).        │
  │                                                                          │
  │ 10. 🔗  Hooks & Events                                                    │
  │     Add afterTap, afterClick, macro start/stop hooks. Clear all hooks.   │
  │     Wait for next key press or mouse click (once).                       │
  └──────────────────────────────────────────────────────────────────────────┘

── PROGRAMMATIC API REFERENCE ──────────────────────────────────────────────────

  ── KEYBOARD ──────────────────────────────────────────────────────────────

  Input.tap(key, holdTime?)            -- Press and release a key
  Input.tapAsync(key, holdTime?)       -- Same, non-blocking
  Input.tapMultiple(keys, ht, iv)      -- Tap a list of keys with interval
  Input.keyDown(key)                   -- Hold key down
  Input.keyUp(key)                     -- Release key
  Input.holdKey(key, duration)         -- Hold for duration seconds
  Input.holdKeys(keys, duration)       -- Hold multiple keys
  Input.combo(keys, callback, rd)      -- Press all keys together
  Input.releaseAll()                   -- Release everything
  Input.spam(key, n, interval)         -- Tap n times
  Input.spamUntil(key, fn, iv, max)    -- Spam until condition is true
  Input.typeText(text, interval, rand) -- Type a string
  Input.typeHuman(text, wpm)           -- Type like a human at WPM speed
  Input.sequence(keyList, interval)    -- Run a key sequence table
  Input.isKeyHeld(key)                 -- Returns true if key is down
  Input.getHeldKeys()                  -- Returns table of held key names
  Input.waitForKey(key, timeout)       -- Block until key is pressed
  Input.waitForAnyKey(keys, timeout)   -- Block until any of the keys is pressed

  ── MOUSE ─────────────────────────────────────────────────────────────────

  Input.mouseMove(x, y)                     -- Instant move
  Input.mouseMoveSmooth(x, y, dur, style)   -- Smooth tweened move
  Input.mouseMoveNatural(x, y, dur)         -- Bezier natural move
  Input.mouseBezier(points, dur)            -- Multi-point bezier path
  Input.mouseDown(x, y, btn)               -- Press mouse button
  Input.mouseUp(x, y, btn)                 -- Release mouse button
  Input.click(x, y, btn, holdTime)         -- Full click
  Input.rightClick(x, y, holdTime)         -- Right click
  Input.doubleClick(x, y, btn, gap)        -- Double click
  Input.tripleClick(x, y, btn, gap)        -- Triple click
  Input.clickAndHold(x, y, duration, btn)  -- Click and hold
  Input.clickHuman(x, y, btn, ht, spread)  -- Jittered human click
  Input.clickFromCenter(ox, oy, btn, ht)   -- Click relative to center
  Input.clickRegion(x1,y1,x2,y2, btn, ht) -- Click random spot in region
  Input.clickUDim2(xs,xo,ys,yo, btn, ht)  -- Click at UDim2 coordinates
  Input.drag(x1,y1,x2,y2, btn, steps, dur, style) -- Drag
  Input.swipe(x1,y1,x2,y2, dur)           -- Fast swipe
  Input.scroll(x, y, amount, stepDelay)   -- Scroll wheel at position
  Input.scrollHere(amount, stepDelay)     -- Scroll at current cursor
  Input.getMousePos()                     -- Returns x, y
  Input.waitForClick(btn, timeout)        -- Block until clicked
  Input.startMouseTracking()              -- Begin recording trail
  Input.stopMouseTracking()               -- Stop and return trail
  Input.getMouseSpeed()                   -- px/s based on recent trail

  ── MACRO BUILDER ────────────────────────────────────────────────────────

  Input.newMacro(name)                   -- Create a new macro
  Input.saveMacro(name, macro)           -- Save to store
  Input.loadMacro(name)                  -- Load from store
  Input.deleteMacro(name)                -- Delete from store
  Input.clearMacro(macro)               -- Remove all actions
  Input.copyMacro(macro, newName)        -- Deep copy
  Input.mergeMacros(mA, mB, name)        -- Combine two macros
  Input.reverseMacro(macro, name)        -- Reverse action order
  Input.debugMacro(macro)               -- Print action list
  Input.getMacroEstimatedTime(macro)    -- Estimated run duration in seconds
  Input.runMacro(macro, loops, speed)   -- Run synchronously
  Input.runMacroAsync(macro, loops, speed) -- Run in background, returns id
  Input.getActiveMacros()               -- Table of running macro ids
  Input.watchMacro(name, callback)      -- Called on start/stop

  Action adders (call after newMacro):
    Input.addKey(m, key, holdTime, delay)
    Input.addKeyDown(m, key, delay)
    Input.addKeyUp(m, key, delay)
    Input.addWait(m, duration)
    Input.addWaitRandom(m, min, max)
    Input.addReleaseAll(m, delay)
    Input.addClick(m, x, y, btn, holdTime, delay)
    Input.addRightClick(m, x, y, holdTime, delay)
    Input.addDoubleClick(m, x, y, delay)
    Input.addTripleClick(m, x, y, delay)
    Input.addMove(m, x, y, delay)
    Input.addSmoothMove(m, x, y, dur, easing, delay)
    Input.addNaturalMove(m, x, y, dur, delay)
    Input.addScroll(m, x, y, amount, delay)
    Input.addScrollHere(m, amount, delay)
    Input.addCombo(m, keys, releaseDelay, delay)
    Input.addText(m, text, interval, randomize, delay)
    Input.addTextHuman(m, text, wpm, delay)
    Input.addDrag(m, x1, y1, x2, y2, btn, steps, dur, style, delay)
    Input.addSwipe(m, x1, y1, x2, y2, dur, delay)
    Input.addSpam(m, key, times, interval, delay)
    Input.addSequence(m, keyList, interval, delay)
    Input.addCFrameClick(m, cframe, btn, holdTime, delay)
    Input.addPartClick(m, part, btn, holdTime, delay)
    Input.addRepeat(m, innerMacro, times)
    Input.addCondition(m, condFn, trueMacro, falseMacro)
    Input.addCallback(m, fn, delay)
    Input.addPrint(m, message)
    Input.addUDim2Click(m, xs, xo, ys, yo, btn, holdTime, delay)
    Input.addWaitFor(m, conditionFn, timeout, interval)
    Input.addBreakIf(m, conditionFn)
    Input.addLabel(m, labelName)
    Input.addGoto(m, labelName, times)

  ── RECORDING ────────────────────────────────────────────────────────────

  Input.startRecording(name)             -- Begin capturing input
  Input.stopRecording(saveName?)         -- Stop, optionally save
  Input.isRecording()                    -- Returns bool
  Input.getLastRecording()              -- Returns action table
  Input.getRecordingTime()              -- Seconds elapsed
  Input.getRecordingCount()             -- Number of recorded actions
  Input.playRecording(actions, speed, loops)
  Input.playRecordingAsync(actions, speed, loops)
  Input.trimRecording(actions, threshold) -- Cut start/end dead time
  Input.scaleRecording(actions, factor)   -- Time-stretch recording

  ── HOTKEYS ──────────────────────────────────────────────────────────────

  Input.bindHotkey(key, callback, label)
  Input.bindHotkeyCombo(keys, callback)  -- Multi-key combo hotkey
  Input.bindToggle(key, startFn, stopFn, label)
  Input.bindMacroHotkey(key, macro, label)
  Input.unbindHotkey(key)
  Input.unbindAll()
  Input.listHotkeys()                    -- Returns list of strings

  ── HOOKS ────────────────────────────────────────────────────────────────

  Available hook names:
    beforeKeyDown, afterKeyDown
    beforeKeyUp,   afterKeyUp
    beforeTap,     afterTap
    beforeClick,   afterClick
    beforeMacro,   afterMacro

  Input.addHook(eventName, fn)
  Input.removeHooks(eventName)
  Input.clearAllHooks()

  ── CAMERA & WORLD ───────────────────────────────────────────────────────

  Input.lookAt(worldPos)
  Input.lookAtSmooth(worldPos, dur, easing)
  Input.restoreCamera()
  Input.lookAndClick(worldPos, btn, holdTime, timeout)
  Input.orbitCamera(target, radius, dur, revolutions)
  Input.clickCFrame(cframe, btn, holdTime)
  Input.clickPart(basePart, btn, holdTime)
  Input.clickPosition(worldPos, btn, holdTime)
  Input.clickModel(model, btn, holdTime)
  Input.clickWhenOnScreen(cframe, btn, holdTime, timeout)
  Input.clickNearestPart(tag?, btn, holdTime)
  Input.clickNearestOnScreen(tag?, btn, holdTime)
  Input.hoverCFrame(cframe, duration?)
  Input.hoverPart(basePart, duration?)
  Input.moveToCFrame(cframe, dur, style)
  Input.moveToPart(basePart, dur, style)
  Input.dragBetweenParts(partA, partB, btn, steps, dur)
  Input.getScreenPos(cframe)            -- Returns sx, sy or nil
  Input.getPartScreenPos(basePart)
  Input.isOnScreen(cframe)
  Input.waitUntilOnScreen(cframe, timeout)
  Input.screenDistance(cframe)         -- Pixels from screen center
  Input.getPartsOnScreen(tag?)         -- Sorted by screen distance
  Input.getDepth(cframe)               -- Distance from camera
  Input.isNearScreenCenter(cframe, radius)

  ── SCREEN UTILS ─────────────────────────────────────────────────────────

  Input.getScreenSize()
  Input.getScreenCenter()
  Input.screenFraction(fx, fy)
  Input.fromUDim2(xScale, xOffset, yScale, yOffset)
  Input.fromUDim2Smart(...)            -- Negative scale = from right/bottom
  Input.fromUDim2Object(udim2Object)

  ── LOOPS & TIMING ───────────────────────────────────────────────────────

  Input.wait(seconds)
  Input.waitRandom(min, max)
  Input.waitFor(conditionFn, timeout, interval)
  Input.delay(seconds, callback)
  Input.repeatAction(n, interval, callback)
  Input.repeatAsync(n, interval, callback)
  Input.loop(interval, callback)        -- Returns stop function
  Input.loopFor(duration, interval, cb) -- Returns stop function
  Input.loopTimes(n, interval, callback)
  Input.alternate(fnA, fnB, n, waitA, waitB)

  ── EASING STYLES ────────────────────────────────────────────────────────

  linear, easeIn, easeOut, easeInOut, bounce, elastic,
  sine, cubic, back, expo, circ

  ── STATS & LOGGING ──────────────────────────────────────────────────────

  Input.getStats()           -- Returns {taps, clicks, scrolls, drags, ...}
  Input.resetStats()
  Input.printStats()
  Input.setLogging(bool)
  Input.getLogs()            -- Returns full log history table
  Input.clearLogs()
  Input.printLogs(n?)        -- Print last n log lines
  Input.getLogsSince(tick)
  Input.exportLogs()         -- Returns log as single string

  ── PROFILES ─────────────────────────────────────────────────────────────

  Input.saveProfile(name)    -- Snapshot macros + hotkeys
  Input.loadProfile(name)
  Input.listProfiles()

  ── EXECUTOR DETECTION ───────────────────────────────────────────────────

  Input.Executor.name        -- String name of detected executor
  Input.Executor.supported   -- Bool: VIM available (required for module)
  Input.Executor.features    -- Table of { featureName = bool }

  Feature flags checked:
    Drawing, HttpGet, getgenv, getrenv, setfenv, getfenv,
    require, loadstring, gethui, VIM, WebSocket,
    writefile, readfile, listfiles

── KEY NAME REFERENCE ──────────────────────────────────────────────────────────

  Letters    :  a–z  A–Z
  Numbers    :  0–9
  Numpad     :  Num0–Num9  Num.  Num+  Num-  Num*  Num/  NumEnter
  Function   :  F1–F12
  Modifiers  :  LShift  RShift  LCtrl  RCtrl  LAlt  RAlt  LMeta  RMeta
  Navigation :  Up  Down  Left  Right  Home  End  PageUp  PageDown
  Editing    :  Enter  Backspace  Delete  Insert  Tab  Escape  Space
  Symbols    :  - = [ ] \ ; ' , . / `
  Locks      :  CapsLock  NumLock  ScrollLock
  Shifted    :  ! @ # $ % ^ & * ( ) ~ _ + { } | : " < > ?

── EXAMPLE SCRIPTS ─────────────────────────────────────────────────────────────

  ── 1. Simple loop that taps E every second ─────────────────────────────────

  local stop = Input.loop(1, function()
      Input.tap("e")
  end)
  -- later: stop()

  ── 2. Build and run a macro ─────────────────────────────────────────────────

  local m = Input.newMacro("farm")
  Input.addKey(m, "e", 0.05)
  Input.addWait(m, 0.3)
  Input.addKey(m, "f", 0.05)
  Input.addWait(m, 0.5)
  m.loops = 10
  Input.runMacroAsync(m)

  ── 3. Record and play back ──────────────────────────────────────────────────

  Input.startRecording("myRecording")
  task.wait(5)  -- do stuff
  local actions = Input.stopRecording("myRecording")
  Input.playRecordingAsync(actions, 1.0, 2)  -- play 2x at normal speed

  ── 4. Bind a toggle hotkey ──────────────────────────────────────────────────

  Input.bindToggle("F6",
      function()
          print("Started!")
      end,
      function()
          print("Stopped!")
      end
  )

  ── 5. Click a Part in the 3D world ─────────────────────────────────────────

  local part = workspace:FindFirstChild("TargetPart")
  Input.clickPart(part)

  ── 6. Type like a human ─────────────────────────────────────────────────────

  Input.typeHuman("Hello, how are you?", 75)  -- 75 WPM

── CHANGELOG ───────────────────────────────────────────────────────────────────

  v2.0.0 (current)
    ● Replaced CoreGui UI with xHeptc/forumsLib (Forums UI)
    ● Added executor detection system (Input.Executor)
    ● Added executor name + support status in window title
    ● Added feature flag detection (Drawing, WebSocket, VIM, etc.)
    ● Expanded UI to 10 sections (was 4 tabs)
    ● Added Info & Executor section
    ● Added Loops & Timing section
    ● Added Profiles section
    ● Added Hooks & Events section
    ● Added Camera & World section
    ● Added continuous spam toggle in Keyboard section
    ● Added mouse trail tracking controls in Mouse section
    ● Added live mouse position display toggle
    ● Extended recording UI with print actions button
    ● Added macro copy, reverse, merge buttons
    ● Added alternate() and loopFor() to loop section
    ● Removed CoreGui / TweenService / old custom window dependencies

  v1.1.0
    ● Initial CoreGui-based UI
    ● Tabs: Recorder, Macros, Keyboard, Mouse
    ● Macro builder with action list
    ● Full recording/playback
    ● Custom drag-to-move window

  v1.0.0
    ● Initial release (no UI)

── NOTES ───────────────────────────────────────────────────────────────────────

  • All inputs are fired through VirtualInputManager. This means they are
    processed by the game's input pipeline and are subject to any anti-cheat
    the game uses. Use responsibly.

  • Mouse coordinate inputs are raw screen pixels. Use Input.getScreenCenter()
    and Input.fromUDim2() to work with responsive coordinates.

  • The Forums UI library is loaded from GitHub at runtime. If the URL is
    unavailable, Input.openUI() will error. The rest of the module works
    without the UI.

  • Profiles are stored in memory only. They do not persist between sessions
    unless you implement file I/O using writefile/readfile if your executor
    supports it.
