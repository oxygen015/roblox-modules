╔══════════════════════════════════════════════════════════════════════════════╗
║              InputModule  v2.1.0  —  Roblox Exploit Input Library           ║
╚══════════════════════════════════════════════════════════════════════════════╝

WHAT'S NEW IN v2.1.0
──────────────────────────────────────────────────────────────────────────────
  ★ AUTO-OPENS the Forums UI on load (set Input.AUTO_UI=false to skip)
  ★ FILE PERSISTENCE — macros saved to InputModule/macros/<name>.json
  ★ MACRO FOLDER SYSTEM — writefile/readfile backed JSON save/load
  ★ IMPORT / EXPORT — copy macro JSON to clipboard, paste to import
  ★ ANTI-AFK — built-in loop: jump / nudge / chat modes
  ★ NOTIFICATIONS — Input.notify(title, text, dur) wrapper
  ★ PLAYER UTILITIES — walkSpeed, jumpPower, walkTo, getDistanceTo, etc.
  ★ FIRE HELPERS — fireclickdetector / fireproximityprompt / firetouchinterest
  ★ CONDITION MACROS — Input.runMacroWhile(macro, condFn)
  ★ MACRO SCHEDULER — Input.scheduleMacro(macro, intervalSecs)
  ★ NEW ACTION ADDERS — addJump, addNotify, addBreakIf, addWaitFor
  ★ SAVE LOGS TO FILE — Input.saveLogsToFile()
  ★ RECORDING TO FILE — saveRecordingToFile / loadRecordingFromFile
  ★ 2026 EXECUTOR DETECTION (see table below)
  ★ UI expanded to 13 sections including File Manager, Anti-AFK,
    Player Utils, Macro Scheduler
  ★ Stats now track: combos, typeChars, antiAfkSaves

──────────────────────────────────────────────────────────────────────────────
REQUIREMENTS
──────────────────────────────────────────────────────────────────────────────
  - A Roblox executor that exposes VirtualInputManager (VIM)
  - forumsLib loaded automatically when Input.openUI() is called
    (requires game:HttpGet)
  - File persistence requires: writefile, readfile, listfiles,
    makefolder, isfolder  (most mid/top tier executors)

──────────────────────────────────────────────────────────────────────────────
QUICK START
──────────────────────────────────────────────────────────────────────────────

  -- Load (UI auto-opens after 0.5s)
  local Input = loadstring(readfile("inputmodule.lua"))()

  -- Prevent auto-open:
  Input.AUTO_UI = false
  local Input = loadstring(readfile("inputmodule.lua"))()

  -- Open manually:
  Input.openUI()

──────────────────────────────────────────────────────────────────────────────
FILE SYSTEM — FOLDER STRUCTURE
──────────────────────────────────────────────────────────────────────────────

  InputModule/
  ├── macros/       ← macro JSON files  (<name>.json)
  ├── recordings/   ← recorded input JSON files
  ├── logs/         ← saved log files
  └── profiles/     ← profile metadata

  Folders are created automatically on load when FS is available.

──────────────────────────────────────────────────────────────────────────────
FILE API — MACROS
──────────────────────────────────────────────────────────────────────────────

  Input.saveMacroToFile(macro)
    Saves macro to InputModule/macros/<name>.json

  Input.loadMacroFromFile("MacroName")
    Loads InputModule/macros/MacroName.json into memory.

  Input.saveAllMacros()
    Saves every in-memory macro to disk. Returns count.

  Input.loadAllMacros()
    Loads every .json in InputModule/macros/ into memory. Returns count.

  Input.deleteMacroFile("MacroName")
    Removes the macro file from disk.

  Input.listMacroFiles()
    Returns sorted list of macro names on disk (without .json).

  Input.exportMacroToClipboard(macro)
    Copies macro JSON to clipboard. Falls back to console print.

  Input.importMacroFromJson(json)
    Parses JSON string and loads into macroStore. Returns macro.

  Input.saveRecordingToFile("rec1", actions)
    Saves recording to InputModule/recordings/rec1.json

  Input.loadRecordingFromFile("rec1")
    Returns recording actions from disk.

  Input.listRecordingFiles()
    Returns list of recording names on disk.

──────────────────────────────────────────────────────────────────────────────
ANTI-AFK API
──────────────────────────────────────────────────────────────────────────────

  Input.startAntiAfk(mode, interval)
    mode:     "jump"  — character jumps
              "nudge" — taps W briefly
              "chat"  — opens/closes chat
    interval: seconds between actions (default 60)

  Input.stopAntiAfk()
  Input.isAntiAfkRunning() → bool

  Example:
    Input.startAntiAfk("jump", 45)

──────────────────────────────────────────────────────────────────────────────
NOTIFICATIONS
──────────────────────────────────────────────────────────────────────────────

  Input.notify(title, text, duration)
    Uses StarterGui:SetCore("SendNotification", ...).
    duration defaults to 4s.

──────────────────────────────────────────────────────────────────────────────
PLAYER UTILITIES
──────────────────────────────────────────────────────────────────────────────

  Input.getCharacter()         → character or nil
  Input.getRootPart()          → HumanoidRootPart or nil
  Input.getHumanoid()          → Humanoid or nil
  Input.getPlayerPos()         → Vector3 or nil
  Input.setWalkSpeed(n)
  Input.setJumpPower(n)
  Input.jump()                 → triggers jump
  Input.walkTo(target, timeout)
  Input.getPlayerList()        → {name, ...}
  Input.getPlayerByName(name)  → Player or nil
  Input.getDistanceTo(pos)     → studs (Vector3 or Part)
  Input.fireClickDetector(part, dist)
  Input.fireProximityPrompt(part)
  Input.fireTouchInterest(part, touchPart)

──────────────────────────────────────────────────────────────────────────────
MACRO SCHEDULER
──────────────────────────────────────────────────────────────────────────────

  id = Input.scheduleMacro(macro, intervalSecs, runImmediately)
  Input.unscheduleMacro(id)
  Input.listScheduled()            → {{id, name, interval}, ...}
  Input.runMacroWhile(macro, condFn, checkIv)

  Example:
    local id = Input.scheduleMacro(myMacro, 30, true)
    Input.unscheduleMacro(id)

──────────────────────────────────────────────────────────────────────────────
NEW MACRO ACTION ADDERS
──────────────────────────────────────────────────────────────────────────────

  Input.addJump(m, delay)
  Input.addNotify(m, title, text, dur)
  Input.addBreakIf(m, condFn)       → stops macro loop if condFn() == true
  Input.addWaitFor(m, condFn, timeout, interval)

──────────────────────────────────────────────────────────────────────────────
COMPLETE MACRO EXAMPLE
──────────────────────────────────────────────────────────────────────────────

  local Input = loadstring(readfile("inputmodule.lua"))()

  local m = Input.newMacro("FarmLoop")
  Input.addKey(m, "e", 0.05, 0)
  Input.addWait(m, 0.5)
  Input.addJump(m)
  Input.addNotify(m, "Farm", "cycle done", 2)
  m.loops = 10

  -- Save to disk
  Input.saveMacroToFile(m)

  -- Run it
  Input.runMacroAsync(m)

  -- Schedule every 30s
  local id = Input.scheduleMacro(m, 30, true)

  -- Load it next session
  local loaded = Input.loadMacroFromFile("FarmLoop")

──────────────────────────────────────────────────────────────────────────────
STATS
──────────────────────────────────────────────────────────────────────────────

  Input.getStats()
    Returns: taps, clicks, scrolls, drags, macrosRun,
             recordingsSaved, combos, typeChars, antiAfkSaves

  Input.resetStats()
  Input.printStats()

──────────────────────────────────────────────────────────────────────────────
LOGS
──────────────────────────────────────────────────────────────────────────────

  Input.setLogging(bool)
  Input.getLogs()              → table
  Input.clearLogs()
  Input.printLogs(n)           → last n entries (default 30)
  Input.exportLogs()           → string
  Input.saveLogsToFile(name)   → InputModule/logs/<name>.txt

──────────────────────────────────────────────────────────────────────────────
KEY NAME REFERENCE
──────────────────────────────────────────────────────────────────────────────

  Letters:   a-z  A-Z
  Numbers:   0-9
  Shifted:   ! @ # $ % ^ & * ( )
  F-Keys:    F1-F12
  Special:   Space  Enter  Tab  Backspace  Escape  Delete  Insert
             Home  End  PageUp  PageDown  Up  Down  Left  Right
             CapsLock  NumLock  ScrollLock  Pause  Print
  Modifiers: LShift RShift LCtrl RCtrl LAlt RAlt LMeta RMeta
  Numpad:    Num0-Num9  Num.  Num+  Num-  Num*  Num/  NumEnter
  Symbols:   - = [ ] \ ; ' , . / `

──────────────────────────────────────────────────────────────────────────────
EASING STYLES
──────────────────────────────────────────────────────────────────────────────

  "linear"  "easeIn"  "easeOut"  "easeInOut"
  "bounce"  "elastic" "sine"     "cubic"
  "back"    "expo"    "circ"

──────────────────────────────────────────────────────────────────────────────
2026 EXECUTOR SUPPORT TABLE
──────────────────────────────────────────────────────────────────────────────

  Executor        Tier   VIM  FS   Detection
  ─────────────── ────── ──── ──── ──────────────────────────────────────────
  Synapse X       top    ✓    ✓    syn + syn.request
  Synapse V3      top    ✓    ✓    syn (no syn.request)
  Seliware        top    ✓    ✓    SELIWARE_LOADED / "seliware"
  AWP X           top    ✓    ✓    AWP_LOADED / "awp"
  Solara          top    ✓    ✓    SOLARA / "solara"
  Nihon           top    ✓    ✓    NIHON_LOADED / "nihon"
  Cryptic         top    ✓    ✓    CRYPTIC_LOADED / "cryptic"
  ScriptWare      top    ✓    ✓    ScriptWare global / "scriptware"
  KRNL            mid    ✓    ✓    KRNL_LOADED / krnl
  Evon            mid    ✓    ✓    EVON_LOADED / "evon"
  Arceus X        mid    ✓    ✓    ARCEUSX_LOADED / "arceus"
  Hydrogen        mid    ✓    ✓    "hydrogen"
  Codex           mid    ✓    ✓    CODEX_LOADED / "codex"
  Delta           mid    ✓    ✓    Delta global / "delta"
  Wave            mid    ✓    ✓    Wave global / "wave"
  Fluxus          mid    ✓    ✓    fluxus global / "fluxus"
  Electron        mid    ✓    ~    electron global / "electron"
  Celery          low    ✓    ~    celery global / "celery"
  Coco Z          low    ✓    ~    COCOZCHEATS_LOADED / "coco"
  Oxygen U        low    ✓    ~    OXYGEN_LOADED / "oxygen"
  Vega X          low    ✓    ~    VEGAX global / "vegax"
  Blade           low    ✓    ~    "blade" via identifyexecutor
  Comet           low    ✓    ~    "comet" via identifyexecutor
  Unknown         ?      ?    ?    identifyexecutor / getexecutorname

  ✓ = supported   ~ = partial   ✗ = not supported

──────────────────────────────────────────────────────────────────────────────
UI SECTIONS  (v2.1.0 — 13 sections)
──────────────────────────────────────────────────────────────────────────────

   1. ℹ  Info & Executor     version, exec name + tier, full feature table
   2. ⏺  Recorder            live recording with timer, stop+save to disk
   3. ⚙  Macro Builder       build / run / save / load / export macros
   4. ⌨  Keyboard            tap, hold, spam, type, combos, hotkeys
   5. 🖱  Mouse               move, click, drag, swipe, scroll, trail
   6. 📷  Camera & World      lookAt, click parts, list on-screen
   7. ⏱  Loops & Timing      loop, loopFor, repeat, alternate
   8. 🔗  Hooks & Events      add/clear hooks, wait for key/click
   9. 📁  Profiles            save/load named profiles
  10. 💾  File Manager ★      list/save/load/export/import/delete files
  11. 🛡  Anti-AFK ★          start/stop, mode, interval
  12. 👤  Player Utils ★      char info, speed, jump, fire helpers
  13. ⏰  Macro Scheduler ★   schedule / list / stop scheduled macros

──────────────────────────────────────────────────────────────────────────────
CHANGELOG
──────────────────────────────────────────────────────────────────────────────

  v2.1.0  (current)
    + Input.AUTO_UI — UI auto-opens 0.5s after load
    + Full FS with custom JSON codec (no external deps)
    + InputModule/ folder tree auto-created on load
    + saveMacroToFile / loadMacroFromFile / saveAllMacros / loadAllMacros
    + deleteMacroFile / listMacroFiles / exportMacroToClipboard / importMacroFromJson
    + saveRecordingToFile / loadRecordingFromFile / listRecordingFiles
    + saveLogsToFile()
    + Input.notify() — StarterGui notification wrapper
    + Anti-AFK (jump / nudge / chat)
    + Player utilities
    + fireclickdetector / fireproximityprompt / firetouchinterest
    + Macro scheduler + runMacroWhile
    + addJump / addNotify / addBreakIf / addWaitFor
    + Stats: combos, typeChars, antiAfkSaves
    + 2026 executors: Seliware, Solara, AWP X, Nihon, Cryptic, Codex,
      Evon, Hydrogen, Arceus X, Vega X, Blade, Comet
    + executor.tier field: "top" / "mid" / "low"
    + Extra feature probes: makefolder, isfolder, hookfunction,
      fireclickdetector, firetouchinterest, fireproximityprompt,
      setclipboard, decompile, getrawmeta
    + 4 new UI sections: File Manager, Anti-AFK, Player Utils, Scheduler
    + Disk-save + schedule buttons in Macro Builder section

  v2.0.0
    + Forums UI (xHeptc/forumsLib)
    + 2025 executor detection
    + Full keyboard / mouse / camera / macro / recording / hotkey API
    + Easing, Bezier mouse, macro goto/labels, screen utilities
    + Mouse trail, profiles, hooks, stats

  v1.x.x
    Initial versions with basic keyboard/mouse simulation.

──────────────────────────────────────────────────────────────────────────────
DISCLAIMER
──────────────────────────────────────────────────────────────────────────────
  For educational and personal use only. Using exploit scripts may violate
  Roblox Terms of Service. Use at your own risk.
