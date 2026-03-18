-- inputmodule.lua
-- v2.1.0
-- Keyboard · Mouse · Macros · Recording · Hotkeys · Camera · World
-- File Persistence · Anti-AFK · Notifications · Player Utils · Forums UI

--[[
  WHAT'S NEW IN v2.1.0
  AUTO-OPENS the Forums UI on load  (set Input.AUTO_UI=false before load to skip)
  FILE PERSISTENCE  macros and recordings saved to InputModule/macros/
  MACRO FOLDER      writefile/readfile/listfiles + custom JSON serialiser
  IMPORT/EXPORT     JSON export to clipboard, paste-to-import via UI textbox
  ANTI-AFK          jump / nudge / chat modes, configurable interval
  NOTIFICATIONS     StarterGui:SetCore wrapper  Input.notify(title,text,dur)
  PLAYER UTILS      walkSpeed, jumpPower, walkTo, distanceTo, fire helpers
  CONDITION MACROS  Input.runMacroWhile(macro, condFn)
  MACRO SCHEDULER   Input.scheduleMacro(macro, intervalSecs)
  addJump / addNotify action adders
  Save logs to disk  Input.saveLogsToFile()
  2026 executors: Seliware, Solara, AWP X, Nihon, Cryptic, Codex, Evon, Hydrogen,
                  Arceus X, Vega X, Blade, Comet  (all with tier rating)
  fireclickdetector / fireproximityprompt / firetouchinterest helpers
  UI expanded to 12 sections: File Manager, Anti-AFK, Player Utils, Scheduler
  Stats: combos, typeChars, antiAfkSaves added
]]
local Input = {}

local VIM          = game:GetService("VirtualInputManager")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local StarterGui   = game:GetService("StarterGui")
local StarterGui   = game:GetService("StarterGui")

Input.VERSION = "2.1.0"
Input.AUTO_UI  = true   -- set false before load to suppress auto-open
Input.LEFT    = 0
Input.RIGHT   = 1
Input.MIDDLE  = 2

-- ─────────────────────────────────────────────────────────────────────────────
-- EXECUTOR DETECTION
-- ─────────────────────────────────────────────────────────────────────────────

local function detectExecutor()
    local name = "Unknown"
    local supported = true
    local features = {}

    -- ── name detection (2026) ─────────────────────────────────────────────────
    local idExec = ""
    if identifyexecutor then
        local ok, id = pcall(identifyexecutor)
        if ok and type(id)=="string" then idExec = id:lower() end
    end
    if getexecutorname then
        local ok2, id2 = pcall(getexecutorname)
        if ok2 and type(id2)=="string" and #id2>0 then idExec = id2:lower() end
    end

    local tier = "unknown"   -- "top" | "mid" | "low"

    if syn and syn.request then
        name="Synapse X"; tier="top"
    elseif syn then
        name="Synapse V3"; tier="top"
    elseif (SELIWARE_LOADED~=nil) or idExec:find("seliware") then
        name="Seliware"; tier="top"
    elseif (AWP_LOADED~=nil) or idExec:find("awp") then
        name="AWP X"; tier="top"
    elseif (SOLARA~=nil) or idExec:find("solara") then
        name="Solara"; tier="top"
    elseif (NIHON_LOADED~=nil) or idExec:find("nihon") then
        name="Nihon"; tier="top"
    elseif (CRYPTIC_LOADED~=nil) or idExec:find("cryptic") then
        name="Cryptic"; tier="top"
    elseif ScriptWare or idExec:find("scriptware") then
        name="ScriptWare"; tier="top"
    elseif KRNL_LOADED or krnl or idExec:find("krnl") then
        name="KRNL"; tier="mid"
    elseif (EVON_LOADED~=nil) or idExec:find("evon") then
        name="Evon"; tier="mid"
    elseif (ARCEUSX_LOADED~=nil) or idExec:find("arceus") then
        name="Arceus X"; tier="mid"
    elseif idExec:find("hydrogen") then
        name="Hydrogen"; tier="mid"
    elseif (CODEX_LOADED~=nil) or idExec:find("codex") then
        name="Codex"; tier="mid"
    elseif Delta or idExec:find("delta") then
        name="Delta"; tier="mid"
    elseif Wave or idExec:find("wave") then
        name="Wave"; tier="mid"
    elseif fluxus or idExec:find("fluxus") then
        name="Fluxus"; tier="mid"
    elseif electron or idExec:find("electron") then
        name="Electron"; tier="mid"
    elseif celery or idExec:find("celery") then
        name="Celery"; tier="low"
    elseif COCOZCHEATS_LOADED or idExec:find("coco") then
        name="Coco Z"; tier="low"
    elseif OXYGEN_LOADED or idExec:find("oxygen") then
        name="Oxygen U"; tier="low"
    elseif (VEGAX~=nil) or idExec:find("vegax") then
        name="Vega X"; tier="low"
    elseif idExec:find("blade") then
        name="Blade"; tier="low"
    elseif idExec:find("comet") then
        name="Comet"; tier="low"
    elseif #idExec>0 then
        name=idExec; tier="unknown"
    end

    -- Feature detection
    local checkedFeatures = {}
    local function check(fname, fn)
        local ok = pcall(fn)
        checkedFeatures[fname] = ok
    end

    check("Drawing",           function() assert(Drawing) end)
    check("HttpGet",           function() assert(game.HttpGet or (syn and syn.request) or http_request) end)
    check("getgenv",           function() assert(type(getgenv())=="table") end)
    check("getrenv",           function() assert(getrenv) end)
    check("setfenv",           function() assert(setfenv) end)
    check("loadstring",        function() assert(loadstring) end)
    check("gethui",            function() assert(gethui()) end)
    check("VIM",               function() assert(VIM) end)
    check("WebSocket",         function() assert(WebSocket) end)
    check("writefile",         function() assert(writefile) end)
    check("readfile",          function() assert(readfile) end)
    check("listfiles",         function() assert(listfiles) end)
    check("makefolder",        function() assert(makefolder) end)
    check("isfolder",          function() assert(isfolder) end)
    check("isfile",            function() assert(isfile) end)
    check("hookfunction",      function() assert(hookfunction) end)
    check("fireclickdetector", function() assert(fireclickdetector) end)
    check("firetouchinterest", function() assert(firetouchinterest) end)
    check("fireproximityprompt",function() assert(fireproximityprompt) end)
    check("setclipboard",      function() assert(setclipboard or toclipboard) end)
    check("decompile",         function() assert(decompile) end)
    check("getrawmeta",        function() assert(getrawmeta) end)

    if not checkedFeatures["VIM"] then supported = false end

    return {
        name      = name,
        tier      = tier,
        supported = supported,
        features  = checkedFeatures,
    }
end

Input.Executor = detectExecutor()

-- ─────────────────────────────────────────────────────────────────────────────
-- INTERNAL STATE
-- ─────────────────────────────────────────────────────────────────────────────

local heldKeys        = {}
local macroStore      = {}
local recording       = false
local recActions      = {}
local recStart        = 0
local recConns        = {}
local hotkeys         = {}
local hotkeyConn      = nil
local _stats = { taps=0, clicks=0, scrolls=0, macrosRun=0, recordingsSaved=0, dragCount=0, combos=0, typeChars=0, antiAfkSaves=0 }
local _logEnabled     = true
local _logHistory     = {}
local _mouseTrail     = {}
local _trackMouse     = false
local _activeMacros   = {}
local _macroIdCounter = 0
local _hooks          = {}
local _macroWatchers  = {}
local _profiles       = {}
local _runningThreads = {}
local _antiAfkStop    = nil
local _scheduledMacros= {}
local _antiAfkStop    = nil
local _scheduledMacros= {}

-- ─────────────────────────────────────────────────────────────────────────────
-- LOGGING
-- ─────────────────────────────────────────────────────────────────────────────

local function log(tag, msg)
    if not _logEnabled then return end
    local entry = string.format("[Input:%s] %s", tag, msg)
    table.insert(_logHistory, { time = tick(), text = entry })
    if #_logHistory > 500 then table.remove(_logHistory, 1) end
    print(entry)
end

local function warn_(tag, msg)
    local entry = string.format("[Input:%s] WARN: %s", tag, msg)
    table.insert(_logHistory, { time = tick(), text = entry })
    if #_logHistory > 500 then table.remove(_logHistory, 1) end
    warn(entry)
end

Input.setLogging   = function(e) _logEnabled = e end
Input.getLogs      = function()  return _logHistory end
Input.clearLogs    = function()  _logHistory = {} end
Input.printLogs    = function(n) n=n or 20 local h=_logHistory for i=math.max(1,#h-n+1),#h do print(h[i].text) end end
Input.getLogsSince = function(t) local r={} for _,e in ipairs(_logHistory) do if e.time>=t then table.insert(r,e) end end return r end
Input.exportLogs   = function() local l={} for _,e in ipairs(_logHistory) do table.insert(l,string.format("[%.2f] %s",e.time,e.text)) end return table.concat(l,"\n") end
Input.saveLogsToFile=function(fname)
    if not writefile then warn_("log","writefile not available") return false end
    fname=fname or ("log_"..math.floor(tick())..".txt")
    pcall(function() if not isfolder("InputModule") then makefolder("InputModule") end if not isfolder("InputModule/logs") then makefolder("InputModule/logs") end end)
    local ok=pcall(writefile,"InputModule/logs/"..fname,Input.exportLogs())
    if ok then log("log","saved: InputModule/logs/"..fname) end return ok
end
Input.saveLogsToFile=function(name)
    if not writefile then warn_("log","writefile not available") return false end
    name=name or ("log_"..math.floor(tick())..".txt")
    local ok,err=pcall(function() if not isfolder("InputModule") then makefolder("InputModule") end if not isfolder("InputModule/logs") then makefolder("InputModule/logs") end writefile("InputModule/logs/"..name,Input.exportLogs()) end)
    if ok then log("log","saved: InputModule/logs/"..name) end return ok
end


-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────────────────────
Input.notify=function(title,text,dur)
    dur=dur or 4
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=tostring(title),Text=tostring(text),Duration=dur})
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CLIPBOARD
-- ─────────────────────────────────────────────────────────────────────────────
local function toClipboard(text)
    if setclipboard then pcall(setclipboard,text) return true
    elseif toclipboard then pcall(toclipboard,text) return true end
    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FILE SYSTEM  (InputModule/ folder tree)
-- ─────────────────────────────────────────────────────────────────────────────
local FS_ROOT    = "InputModule"
local FS_MACROS  = FS_ROOT.."/macros"
local FS_RECS    = FS_ROOT.."/recordings"
local FS_LOGS    = FS_ROOT.."/logs"
local FS_PROFILES= FS_ROOT.."/profiles"

local FS_AVAILABLE = false

local function fsEnsure(path)
    pcall(function() if not isfolder(path) then makefolder(path) end end)
end

local function fsInit()
    local ok=pcall(function()
        fsEnsure(FS_ROOT); fsEnsure(FS_MACROS); fsEnsure(FS_RECS)
        fsEnsure(FS_LOGS); fsEnsure(FS_PROFILES)
    end)
    FS_AVAILABLE = ok and (pcall(function() assert(writefile and readfile and listfiles and makefolder and isfolder) end))
    return FS_AVAILABLE
end

local function fsWrite(path,data) if not writefile then return false end local ok,e=pcall(writefile,path,data) return ok,e end
local function fsRead(path)
    if not readfile then return nil end
    local ok,d=pcall(function() return isfile(path) and readfile(path) or nil end)
    return ok and d or nil
end
local function fsList(dir)
    if not listfiles then return {} end
    local ok,f=pcall(listfiles,dir) return ok and f or {}
end

-- ── Simple JSON serialiser (numbers, strings, booleans, tables) ──────────────
local function jsonEncode(val)
    local t=type(val)
    if t=="nil"     then return "null"
    elseif t=="boolean" then return tostring(val)
    elseif t=="number"  then return (val~=val) and "null" or tostring(val)
    elseif t=="string"  then
        return '"' ..val:gsub('\\','\\\\'):gsub('"','\\\\"'): gsub('\n','\\n'):gsub('\r','\\r').. '"'
    elseif t=="table" then
        local isArr=true; local maxN=0
        for k in pairs(val) do if type(k)~="number" or k<1 or math.floor(k)~=k then isArr=false break end if k>maxN then maxN=k end end
        if isArr and maxN==#val and #val>0 then
            local parts={} for _,v in ipairs(val) do table.insert(parts,jsonEncode(v)) end
            return "["..table.concat(parts,",").."]"
        else
            local parts={} for k,v in pairs(val) do if type(k)=="string" or type(k)=="number" then table.insert(parts,jsonEncode(tostring(k))..":"..jsonEncode(v)) end end
            return "{"..table.concat(parts,",").."}"
        end
    end return "null"
end

-- ── Minimal JSON decoder ─────────────────────────────────────────────────────
local function jsonDecode(s)
    local pos=1
    local function skip() while pos<=#s and s:sub(pos,pos):match("%s") do pos=pos+1 end end
    local function peek() skip() return s:sub(pos,pos) end
    local function consume(c) skip() if s:sub(pos,pos)==c then pos=pos+1 return true end return false end
    local decode
    local function decStr()
        pos=pos+1; local buf={}
        while pos<=#s do
            local c=s:sub(pos,pos)
            if c=='"' then pos=pos+1 break
            elseif c=='\\' then pos=pos+1 local e=s:sub(pos,pos)
                if e=='"' then table.insert(buf,'"') elseif e=='\\' then table.insert(buf,'\\'): elseif e=='n' then table.insert(buf,'\n') elseif e=='r' then table.insert(buf,'\r') elseif e=='t' then table.insert(buf,'\t') else table.insert(buf,e) end
            else table.insert(buf,c) end
            pos=pos+1
        end return table.concat(buf)
    end
    local function decNum() local start=pos if s:sub(pos,pos)=='-' then pos=pos+1 end while pos<=#s and s:sub(pos,pos):match("[%d%.eE%+%-]") do pos=pos+1 end return tonumber(s:sub(start,pos-1)) end
    local function decArr() pos=pos+1; local arr={} skip() if peek()==']' then pos=pos+1 return arr end repeat table.insert(arr,decode()) skip() until not consume(',') consume(']') return arr end
    local function decObj() pos=pos+1; local obj={} skip() if peek()=='}' then pos=pos+1 return obj end repeat skip() local k=decStr() consume(':') obj[k]=decode() skip() until not consume(',') consume('}') return obj end
    decode=function() skip() local c=peek() if c=='"' then return decStr() elseif c=='{' then return decObj() elseif c=='[' then return decArr() elseif c=='t' then pos=pos+4 return true elseif c=='f' then pos=pos+5 return false elseif c=='n' then pos=pos+4 return nil elseif c=='-' or c:match("%d") then return decNum() end return nil end
    local ok,r=pcall(decode) return ok and r or nil
end

-- ── Macro → JSON (skips live-ref action types) ───────────────────────────────
local function macroToJson(m)
    local safe={name=m.name,speed=m.speed,loops=m.loops,enabled=m.enabled,tags=m.tags,created=m.created,actions={}}
    for _,a in ipairs(m.actions) do
        if a.type~="cfclick" and a.type~="partclick" and a.type~="repeat" and a.type~="condition" and a.type~="callback" then
            local ca={} for k,v in pairs(a) do if type(v)=="string" or type(v)=="number" or type(v)=="boolean" then ca[k]=v elseif type(v)=="table" then ca[k]=v end end
            table.insert(safe.actions,ca)
        end
    end
    return jsonEncode(safe)
end

-- ── JSON → Macro table ───────────────────────────────────────────────────────
local function macroFromJson(json)
    local data=jsonDecode(json) if not data or type(data)~="table" then return nil end
    local m={name=data.name or "imported",speed=tonumber(data.speed) or 1.0,loops=tonumber(data.loops) or 1,enabled=data.enabled~=false,tags=data.tags or {},meta={},created=data.created,actions={}}
    if data.actions then for _,a in ipairs(data.actions) do local ca={} for k,v in pairs(a) do ca[k]=v end table.insert(m.actions,ca) end end
    return m
end

-- ── Public file API ───────────────────────────────────────────────────────────
Input.saveMacroToFile=function(macro)
    if not writefile then warn_("file","writefile not available"); return false end
    local path=FS_MACROS.."/"..macro.name..".json"
    local ok,err=fsWrite(path,macroToJson(macro))
    if ok then log("file","macro saved → "..path); Input.notify("Saved",macro.name.." written to disk",3) else warn_("file","save failed: "..tostring(err)) end
    return ok
end

Input.loadMacroFromFile=function(name)
    if not readfile then warn_("file","readfile not available"); return nil end
    local data=fsRead(FS_MACROS.."/"..name..".json")
    if not data then warn_("file","not found: "..name); return nil end
    local m=macroFromJson(data)
    if not m then warn_("file","parse error: "..name); return nil end
    macroStore[m.name]=m; log("file","loaded ← "..name); Input.notify("Loaded",m.name.." ("..#m.actions.." actions)",3); return m
end

Input.listMacroFiles=function()
    local files=fsList(FS_MACROS); local names={}
    for _,f in ipairs(files) do local n=tostring(f):match("([^/\\]+)%.json$"); if n then table.insert(names,n) end end
    table.sort(names); return names
end

Input.saveAllMacros=function()
    local count=0 for _,m in pairs(macroStore) do if Input.saveMacroToFile(m) then count=count+1 end end
    log("file","saved "..count.." macros"); return count
end

Input.loadAllMacros=function()
    local files=Input.listMacroFiles(); local count=0
    for _,name in ipairs(files) do if Input.loadMacroFromFile(name) then count=count+1 end end
    log("file","loaded "..count.." macros"); return count
end

Input.deleteMacroFile=function(name)
    local path=FS_MACROS.."/"..name..".json"
    pcall(function() if delfile then delfile(path) else fsWrite(path,'{"_deleted":true}') end end)
    log("file","deleted file: "..path)
end

Input.exportMacroToClipboard=function(macro)
    local json=macroToJson(macro)
    if toClipboard(json) then Input.notify("Exported",macro.name.." JSON in clipboard",3); return true end
    warn_("file","clipboard not available"); return false
end

Input.importMacroFromJson=function(json)
    local m=macroFromJson(json)
    if not m then warn_("file","import: bad JSON"); return nil end
    macroStore[m.name]=m; log("file","imported: "..m.name); Input.notify("Imported",m.name.." ("..#m.actions.." actions)",3); return m
end

Input.saveRecordingToFile=function(name,actions)
    if not writefile then warn_("file","writefile not available"); return false end
    local ok=fsWrite(FS_RECS.."/"..name..".json", jsonEncode(actions or recActions))
    if ok then log("file","recording saved: "..name) end; return ok
end

Input.loadRecordingFromFile=function(name)
    local data=fsRead(FS_RECS.."/"..name..".json")
    if not data then warn_("file","recording not found: "..name); return nil end
    local actions=jsonDecode(data)
    if actions then
        for _,a in ipairs(actions) do
            if a.x then a.x=tonumber(a.x) end; if a.y then a.y=tonumber(a.y) end; if a.time then a.time=tonumber(a.time) end
        end
        log("file","recording loaded: "..name.." ("..#actions.." actions)")
    end return actions
end

Input.listRecordingFiles=function()
    local files=fsList(FS_RECS); local names={}
    for _,f in ipairs(files) do local n=tostring(f):match("([^/\\]+)%.json$"); if n then table.insert(names,n) end end
    table.sort(names); return names
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ANTI-AFK
-- ─────────────────────────────────────────────────────────────────────────────
Input.startAntiAfk=function(mode,interval)
    if _antiAfkStop then warn_("antiafk","already running"); return end
    mode=mode or "jump"; interval=interval or 60
    local running=true
    local function doAction()
        _stats.antiAfkSaves=(_stats.antiAfkSaves or 0)+1
        if mode=="jump" then
            local h=game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        elseif mode=="nudge" then
            VIM:SendKeyEvent(true,Enum.KeyCode.W,false,game); task.wait(0.1); VIM:SendKeyEvent(false,Enum.KeyCode.W,false,game)
        elseif mode=="chat" then
            VIM:SendKeyEvent(true,Enum.KeyCode.Slash,false,game); task.wait(0.05); VIM:SendKeyEvent(false,Enum.KeyCode.Slash,false,game)
            task.wait(0.1); VIM:SendKeyEvent(true,Enum.KeyCode.Escape,false,game); task.wait(0.05); VIM:SendKeyEvent(false,Enum.KeyCode.Escape,false,game)
        end
        log("antiafk","action fired ("..mode..")")
    end
    task.spawn(function() while running do task.wait(interval) if running then pcall(doAction) end end end)
    _antiAfkStop=function() running=false; _antiAfkStop=nil end
    log("antiafk","started  mode="..mode.."  interval="..interval.."s")
end
Input.stopAntiAfk=function() if _antiAfkStop then _antiAfkStop(); log("antiafk","stopped") else warn_("antiafk","not running") end end
Input.isAntiAfkRunning=function() return _antiAfkStop~=nil end

-- ─────────────────────────────────────────────────────────────────────────────
-- PLAYER UTILITIES
-- ─────────────────────────────────────────────────────────────────────────────
Input.getLocalPlayer =function() return Players.LocalPlayer end
Input.getCharacter   =function() return Players.LocalPlayer and Players.LocalPlayer.Character end
Input.getRootPart    =function() local c=Input.getCharacter(); return c and c:FindFirstChild("HumanoidRootPart") end
Input.getHumanoid    =function() local c=Input.getCharacter(); return c and c:FindFirstChildOfClass("Humanoid") end
Input.getPlayerPos   =function() local r=Input.getRootPart(); return r and r.Position or nil end
Input.setWalkSpeed   =function(speed) local h=Input.getHumanoid(); if h then h.WalkSpeed=speed end end
Input.setJumpPower   =function(power) local h=Input.getHumanoid(); if h then h.JumpPower=power end end
Input.jump=function()
    local h=Input.getHumanoid(); if not h then return false end
    h:ChangeState(Enum.HumanoidStateType.Jumping); return true
end
Input.walkTo=function(target,timeout)
    local h=Input.getHumanoid(); if not h then return false end
    if typeof(target)=="Instance" and target:IsA("BasePart") then target=target.Position end
    h:MoveTo(target); local reached=false
    local conn=h.MoveToFinished:Connect(function(r) reached=r end)
    local t=0; while not reached do task.wait(0.1); t=t+0.1; if timeout and t>=timeout then conn:Disconnect(); return false end end
    conn:Disconnect(); return true
end
Input.getPlayerList  =function() local r={} for _,p in ipairs(Players:GetPlayers()) do table.insert(r,p.Name) end; return r end
Input.getPlayerByName=function(name) return Players:FindFirstChild(name) end
Input.getDistanceTo  =function(target)
    local root=Input.getRootPart(); if not root then return math.huge end
    local pos=typeof(target)=="Vector3" and target or (target:IsA("BasePart") and target.Position)
    if not pos then return math.huge end; return (root.Position-pos).Magnitude
end

Input.fireClickDetector=function(part,dist)
    if not fireclickdetector then warn_("world","fireclickdetector unavailable"); return false end
    local cd=part:FindFirstChildOfClass("ClickDetector"); if not cd then warn_("world","no ClickDetector on "..part.Name); return false end
    pcall(fireclickdetector,cd,dist or 0); return true
end
Input.fireProximityPrompt=function(part)
    if not fireproximityprompt then warn_("world","fireproximityprompt unavailable"); return false end
    local pp=part:FindFirstChildOfClass("ProximityPrompt"); if not pp then warn_("world","no ProximityPrompt on "..part.Name); return false end
    pcall(fireproximityprompt,pp); return true
end
Input.fireTouchInterest=function(part,touchPart)
    if not firetouchinterest then warn_("world","firetouchinterest unavailable"); return false end
    touchPart=touchPart or Input.getRootPart(); if not touchPart then return false end
    pcall(firetouchinterest,touchPart,part,0); return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MACRO SCHEDULER
-- ─────────────────────────────────────────────────────────────────────────────
Input.scheduleMacro=function(macro,intervalSecs,runImmediately)
    local id=tostring(tick()); local running=true
    _scheduledMacros[id]={macro=macro,interval=intervalSecs,stop=function() running=false end}
    task.spawn(function()
        if runImmediately then Input.runMacro(macro) end
        while running do task.wait(intervalSecs) if running then Input.runMacro(macro) end end
        _scheduledMacros[id]=nil
    end)
    log("schedule","macro '"..macro.name.."' every "..intervalSecs.."s  id="..id); return id
end
Input.unscheduleMacro=function(id) if _scheduledMacros[id] then _scheduledMacros[id].stop(); _scheduledMacros[id]=nil end end
Input.listScheduled  =function() local r={} for id,s in pairs(_scheduledMacros) do table.insert(r,{id=id,name=s.macro.name,interval=s.interval}) end; return r end

-- ─────────────────────────────────────────────────────────────────────────────
-- MACRO UTILITIES  (runMacroWhile + new action adders)
-- ─────────────────────────────────────────────────────────────────────────────
Input.runMacroWhile=function(macro,condFn,checkIv)
    checkIv=checkIv or 0.2
    task.spawn(function() while condFn() do Input.runMacro(macro) task.wait(checkIv) end end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- EVENT HOOKS
-- ─────────────────────────────────────────────────────────────────────────────

local function fireHook(name, ...)
    if _hooks[name] then
        for _, fn in ipairs(_hooks[name]) do
            local ok, err = pcall(fn, ...)
            if not ok then warn_("hook", name.." error: "..tostring(err)) end
        end
    end
end

Input.addHook       = function(e,fn) if not _hooks[e] then _hooks[e]={} end table.insert(_hooks[e],fn) end
Input.removeHooks   = function(e)    _hooks[e]={} end
Input.clearAllHooks = function()     _hooks={} end

-- ─────────────────────────────────────────────────────────────────────────────
-- KEY MAP
-- ─────────────────────────────────────────────────────────────────────────────

local KeyMap = {}

local function safeKC(name)
    local ok, v = pcall(function() return Enum.KeyCode[name] end)
    return (ok and v) or nil
end

local function reg(char, enumName)
    local kc = safeKC(enumName)
    if kc then KeyMap[char] = kc end
end

for i=0,9 do
    local names={"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
    reg(tostring(i), names[i+1])
end

local shifted={"!","@","#","$","%","^","&","*","(",")" }
local shiftEnums={"One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Zero"}
for i,ch in ipairs(shifted) do reg(ch, shiftEnums[i]) end

for byte=string.byte("a"),string.byte("z") do
    local ch=string.char(byte)
    reg(ch, ch:upper()); reg(ch:upper(), ch:upper())
end

local specials = {
    Space="Space", Enter="Return", Tab="Tab", Backspace="Backspace",
    Escape="Escape", Delete="Delete", Insert="Insert", Home="Home",
    End="End", PageUp="PageUp", PageDown="PageDown",
    Up="Up", Down="Down", Left="Left", Right="Right",
    CapsLock="CapsLock", NumLock="NumLock", ScrollLock="ScrollLock",
    Pause="Pause", Print="Print",
    LShift="LeftShift",  RShift="RightShift",
    LCtrl="LeftControl", RCtrl="RightControl",
    LAlt="LeftAlt",      RAlt="RightAlt",
    LMeta="LeftMeta",    RMeta="RightMeta",
    ["Num0"]="KeypadZero",    ["Num1"]="KeypadOne",     ["Num2"]="KeypadTwo",
    ["Num3"]="KeypadThree",   ["Num4"]="KeypadFour",    ["Num5"]="KeypadFive",
    ["Num6"]="KeypadSix",     ["Num7"]="KeypadSeven",   ["Num8"]="KeypadEight",
    ["Num9"]="KeypadNine",    ["Num."]="KeypadPeriod",  ["Num+"]="KeypadPlus",
    ["Num-"]="KeypadMinus",   ["Num*"]="KeypadAsterisk",["Num/"]="KeypadSlash",
    ["NumEnter"]="KeypadEnter",
}
for k,v in pairs(specials) do reg(k,v) end
for i=1,12 do reg("F"..i,"F"..i) end

local puncts={
    {"-","Minus"},{"=","Equals"},{"[","LeftBracket"},{"]","RightBracket"},
    {"\\","BackSlash"},{";","Semicolon"},{"'","Quote"},{",","Comma"},
    {".","Period"},{"/","Slash"},{"`","Tilde"},
}
for _,p in ipairs(puncts) do reg(p[1],p[2]) end

local ShiftSet={}
for _,v in ipairs({
    "!","@","#","$","%","^","&","*","(",")",
    "A","B","C","D","E","F","G","H","I","J","K","L","M",
    "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "~","_","+","{","}","|",":","\"","<",">","?",
}) do ShiftSet[v]=true end

-- ─────────────────────────────────────────────────────────────────────────────
-- SCREEN / CAMERA UTILS
-- ─────────────────────────────────────────────────────────────────────────────

local function getCamera()   return workspace.CurrentCamera end
local function getViewport() return getCamera().ViewportSize end

Input.fromUDim2 = function(xs,xo,ys,yo)
    local vp=getViewport() return vp.X*xs+(xo or 0), vp.Y*ys+(yo or 0)
end
Input.fromUDim2Smart = function(xs,xo,ys,yo)
    local vp=getViewport()
    local x = xs<0 and (vp.X+vp.X*xs+(xo or 0)) or (vp.X*xs+(xo or 0))
    local y = ys<0 and (vp.Y+vp.Y*ys+(yo or 0)) or (vp.Y*ys+(yo or 0))
    return x,y
end
Input.fromUDim2Object = function(u)
    local vp=getViewport() return vp.X*u.X.Scale+u.X.Offset, vp.Y*u.Y.Scale+u.Y.Offset
end
Input.getScreenSize   = function() local vp=getViewport() return vp.X,vp.Y end
Input.getScreenCenter = function() local vp=getViewport() return math.floor(vp.X/2),math.floor(vp.Y/2) end
Input.screenFraction  = function(fx,fy) local vp=getViewport() return math.floor(vp.X*fx),math.floor(vp.Y*fy) end

local function worldToScreen(pos)
    local sp,on=getCamera():WorldToScreenPoint(pos)
    return Vector2.new(sp.X,sp.Y),on
end

Input.isOnScreen        = function(cf) local _,on=worldToScreen(cf.Position) return on end
Input.getScreenPos      = function(cf) local sp,on=worldToScreen(cf.Position) if on then return math.floor(sp.X),math.floor(sp.Y) end return nil,nil end
Input.getPartScreenPos  = function(p)  if not p or not p:IsA("BasePart") then return nil,nil end return Input.getScreenPos(p.CFrame) end
Input.waitUntilOnScreen = function(cf,timeout) local t=0 while not Input.isOnScreen(cf) do task.wait(0.1) t+=0.1 if timeout and t>=timeout then return false end end return true end
Input.screenDistance    = function(cf) local cx,cy=Input.getScreenCenter() local x,y=Input.getScreenPos(cf) if not x then return math.huge end return math.sqrt((x-cx)^2+(y-cy)^2) end
Input.getDepth          = function(cf) return (getCamera().CFrame.Position-cf.Position).Magnitude end
Input.isNearScreenCenter= function(cf,r) return Input.screenDistance(cf)<=(r or 50) end
Input.getPartsOnScreen  = function(tag)
    local vp=getViewport() local cx,cy=vp.X/2,vp.Y/2 local results={}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (not tag or obj.Name==tag) then
            local sp,on=worldToScreen(obj.Position)
            if on then local d=math.sqrt((sp.X-cx)^2+(sp.Y-cy)^2) table.insert(results,{part=obj,dist=d,sx=math.floor(sp.X),sy=math.floor(sp.Y)}) end
        end
    end
    table.sort(results,function(a,b) return a.dist<b.dist end) return results
end

-- ─────────────────────────────────────────────────────────────────────────────
-- EASING
-- ─────────────────────────────────────────────────────────────────────────────

local Easing={
    linear    =function(t) return t end,
    easeIn    =function(t) return t*t end,
    easeOut   =function(t) return t*(2-t) end,
    easeInOut =function(t) return t<0.5 and 2*t*t or -1+(4-2*t)*t end,
    bounce    =function(t)
        if t<1/2.75 then return 7.5625*t*t
        elseif t<2/2.75 then t=t-1.5/2.75   return 7.5625*t*t+0.75
        elseif t<2.5/2.75 then t=t-2.25/2.75 return 7.5625*t*t+0.9375
        else t=t-2.625/2.75 return 7.5625*t*t+0.984375 end
    end,
    elastic=function(t) if t==0 or t==1 then return t end return -math.pow(2,10*(t-1))*math.sin((t-1.1)*5*math.pi) end,
    sine   =function(t) return 1-math.cos(t*math.pi/2) end,
    cubic  =function(t) return t*t*t end,
    back   =function(t) local s=1.70158 return t*t*((s+1)*t-s) end,
    expo   =function(t) return t==0 and 0 or math.pow(2,10*(t-1)) end,
    circ   =function(t) return 1-math.sqrt(1-t*t) end,
}
Input.Easing=Easing

local function lerp(a,b,t) return a+(b-a)*t end
local function ease(style,t) return (Easing[style] or Easing.linear)(t) end

-- ─────────────────────────────────────────────────────────────────────────────
-- KEYBOARD
-- ─────────────────────────────────────────────────────────────────────────────

Input.keyDown=function(key)
    local kc=KeyMap[key] if not kc then warn_("key","unknown: "..tostring(key)) return false end
    fireHook("beforeKeyDown",key)
    if ShiftSet[key] then VIM:SendKeyEvent(true,Enum.KeyCode.LeftShift,false,game) end
    VIM:SendKeyEvent(true,kc,false,game)
    heldKeys[key]=true fireHook("afterKeyDown",key) return true
end

Input.keyUp=function(key)
    local kc=KeyMap[key] if not kc then warn_("key","unknown: "..tostring(key)) return false end
    fireHook("beforeKeyUp",key)
    VIM:SendKeyEvent(false,kc,false,game)
    if ShiftSet[key] then VIM:SendKeyEvent(false,Enum.KeyCode.LeftShift,false,game) end
    heldKeys[key]=nil fireHook("afterKeyUp",key) return true
end

Input.tap=function(key,holdTime)
    holdTime=holdTime or 0.05 fireHook("beforeTap",key)
    if not Input.keyDown(key) then return false end
    task.wait(holdTime) Input.keyUp(key) _stats.taps+=1 fireHook("afterTap",key) return true
end

Input.tapAsync         =function(key,ht)      task.spawn(Input.tap,key,ht) end
Input.tapMultiple      =function(keys,ht,iv)  iv=iv or 0.05 for i,k in ipairs(keys) do Input.tap(k,ht) if i<#keys then task.wait(iv) end end end
Input.tapMultipleAsync =function(keys,ht,iv)  task.spawn(Input.tapMultiple,keys,ht,iv) end
Input.holdKey          =function(key,dur)     if not Input.keyDown(key) then return false end task.wait(dur) Input.keyUp(key) return true end
Input.holdKeyAsync     =function(key,dur)     task.spawn(Input.holdKey,key,dur) end
Input.holdKeys         =function(keys,dur)    for _,k in ipairs(keys) do Input.keyDown(k) end task.wait(dur) for i=#keys,1,-1 do Input.keyUp(keys[i]) end end
Input.holdKeysAsync    =function(keys,dur)    task.spawn(Input.holdKeys,keys,dur) end
Input.combo            =function(keys,cb,rd)  rd=rd or 0.05; _stats.combos=(_stats.combos or 0)+1 for _,k in ipairs(keys) do Input.keyDown(k) end if cb then cb() end task.wait(rd) for i=#keys,1,-1 do Input.keyUp(keys[i]) end end
Input.comboAsync       =function(keys,cb,rd)  task.spawn(Input.combo,keys,cb,rd) end

Input.releaseAll=function()
    for key in pairs(heldKeys) do local kc=KeyMap[key] if kc then VIM:SendKeyEvent(false,kc,false,game) end end
    heldKeys={}
    for _,kc in ipairs({Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift,Enum.KeyCode.LeftControl,Enum.KeyCode.RightControl,Enum.KeyCode.LeftAlt,Enum.KeyCode.RightAlt,Enum.KeyCode.Space}) do VIM:SendKeyEvent(false,kc,false,game) end
end

Input.isKeyHeld      =function(key)  local kc=KeyMap[key] return kc and UIS:IsKeyDown(kc) or false end
Input.isAnyKeyHeld   =function(keys) for _,k in ipairs(keys) do if Input.isKeyHeld(k) then return true end end return false end
Input.areAllKeysHeld =function(keys) for _,k in ipairs(keys) do if not Input.isKeyHeld(k) then return false end end return true end
Input.getHeldKeys    =function()     local r={} for k in pairs(heldKeys) do table.insert(r,k) end return r end

Input.spam      =function(key,n,iv)     iv=iv or 0.05 for i=1,n do Input.tap(key,0.03) if i<n then task.wait(iv) end end end
Input.spamAsync =function(key,n,iv)     task.spawn(Input.spam,key,n,iv) end
Input.spamUntil =function(key,fn,iv,max) iv=iv or 0.1 max=max or 30 local e=0 while not fn() and e<max do Input.tap(key,0.03) task.wait(iv) e+=iv end end

Input.typeText     =function(text,iv,rand) iv=iv or 0.05 rand=rand or false for i=1,#text do local ch=text:sub(i,i) if KeyMap[ch] then Input.tap(ch,0.04) else warn_("type","no mapping: "..ch) end _stats.typeChars=(_stats.typeChars or 0)+1 task.wait(rand and iv*(0.6+math.random()*0.8) or iv) end end
Input.typeTextAsync=function(text,iv,rand) task.spawn(Input.typeText,text,iv,rand) end
Input.typeHuman    =function(text,wpm)     wpm=wpm or 60 local base=60/(wpm*5) for i=1,#text do local ch=text:sub(i,i) if KeyMap[ch] then Input.tap(ch,0.03) end local j=base*(0.5+math.random()*1.0) if ch=="."or ch==","or ch=="!"or ch=="?" then j=j*3 end task.wait(j) end end
Input.typeHumanAsync=function(text,wpm)    task.spawn(Input.typeHuman,text,wpm) end

Input.sequence=function(keyList,iv)
    iv=iv or 0.1
    for _,entry in ipairs(keyList) do
        if type(entry)=="string" then Input.tap(entry,0.05)
        elseif type(entry)=="table" then
            if entry.wait  then task.wait(entry.wait)
            elseif entry.combo then Input.combo(entry.combo)
            elseif entry.key   then Input.tap(entry.key,entry.hold or 0.05)
            elseif entry.text  then Input.typeText(entry.text)
            elseif entry.fn    then pcall(entry.fn) end
        end
        task.wait(iv)
    end
end
Input.sequenceAsync=function(kl,iv) task.spawn(Input.sequence,kl,iv) end

Input.waitForKey=function(key,timeout)
    local kc=KeyMap[key] if not kc then return false end
    local done=false local conn=UIS.InputBegan:Connect(function(inp) if inp.KeyCode==kc then done=true end end)
    local e=0 while not done do task.wait(0.05) e+=0.05 if timeout and e>=timeout then conn:Disconnect() return false end end
    conn:Disconnect() return true
end
Input.waitForKeyRelease=function(key,timeout)
    local kc=KeyMap[key] if not kc then return false end
    local done=false local conn=UIS.InputEnded:Connect(function(inp) if inp.KeyCode==kc then done=true end end)
    local e=0 while not done do task.wait(0.05) e+=0.05 if timeout and e>=timeout then conn:Disconnect() return false end end
    conn:Disconnect() return true
end
Input.waitForAnyKey=function(keys,timeout)
    local done,which=false,nil local conns={}
    for _,key in ipairs(keys) do
        local kc=KeyMap[key] if kc then
            table.insert(conns,UIS.InputBegan:Connect(function(inp) if inp.KeyCode==kc and not done then done=true which=key end end))
        end
    end
    local e=0 while not done do task.wait(0.05) e+=0.05 if timeout and e>=timeout then break end end
    for _,c in ipairs(conns) do c:Disconnect() end return which
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MOUSE
-- ─────────────────────────────────────────────────────────────────────────────

Input.mouseMove=function(x,y)
    VIM:SendMouseMoveEvent(x,y,game)
    if _trackMouse then table.insert(_mouseTrail,{x=x,y=y,t=tick()}) if #_mouseTrail>500 then table.remove(_mouseTrail,1) end end
end

Input.mouseMoveSmooth=function(x2,y2,dur,style)
    dur=dur or 0.3 style=style or "linear"
    local cur=UIS:GetMouseLocation() local x1,y1=cur.X,cur.Y
    local steps=math.max(5,math.floor(dur/0.016)) local dt=dur/steps
    for i=1,steps do local t=ease(style,i/steps) Input.mouseMove(math.floor(lerp(x1,x2,t)),math.floor(lerp(y1,y2,t))) task.wait(dt) end
end
Input.mouseMoveNatural=function(x2,y2,dur)
    dur=dur or 0.3 local cur=UIS:GetMouseLocation() local x1,y1=cur.X,cur.Y
    local cx=(x1+x2)/2+math.random(-80,80) local cy=(y1+y2)/2+math.random(-80,80)
    local steps=math.max(10,math.floor(dur/0.016)) local dt=dur/steps
    for i=1,steps do
        local t=i/steps local et=ease("easeInOut",t)
        Input.mouseMove(math.floor((1-et)^2*x1+2*(1-et)*et*cx+et^2*x2),math.floor((1-et)^2*y1+2*(1-et)*et*cy+et^2*y2))
        task.wait(dt)
    end
end
Input.mouseMoveNaturalAsync=function(x,y,d) task.spawn(Input.mouseMoveNatural,x,y,d) end

Input.mouseBezier=function(points,dur)
    dur=dur or 0.5 local steps=math.max(10,math.floor(dur/0.016)) local dt=dur/steps
    local function bez(pts,t)
        if #pts==1 then return pts[1][1],pts[1][2] end
        local next={}
        for i=1,#pts-1 do table.insert(next,{lerp(pts[i][1],pts[i+1][1],t),lerp(pts[i][2],pts[i+1][2],t)}) end
        return bez(next,t)
    end
    for i=1,steps do local t=ease("easeInOut",i/steps) local x,y=bez(points,t) Input.mouseMove(math.floor(x),math.floor(y)) task.wait(dt) end
end

Input.mouseDown=function(x,y,btn) VIM:SendMouseButtonEvent(x,y,btn or Input.LEFT,true,game,1) end
Input.mouseUp  =function(x,y,btn) VIM:SendMouseButtonEvent(x,y,btn or Input.LEFT,false,game,1) end

Input.click=function(x,y,btn,ht)
    btn=btn or Input.LEFT ht=ht or 0.05 fireHook("beforeClick",x,y,btn)
    Input.mouseMove(x,y) task.wait(0.02) Input.mouseDown(x,y,btn) task.wait(ht) Input.mouseUp(x,y,btn)
    _stats.clicks+=1 fireHook("afterClick",x,y,btn)
end
Input.clickAsync      =function(x,y,b,h)   task.spawn(Input.click,x,y,b,h) end
Input.rightClick      =function(x,y,h)     Input.click(x,y,Input.RIGHT,h) end
Input.rightClickAsync =function(x,y,h)     task.spawn(Input.rightClick,x,y,h) end
Input.middleClick     =function(x,y,h)     Input.click(x,y,Input.MIDDLE,h) end
Input.doubleClick     =function(x,y,b,gap) gap=gap or 0.08 Input.click(x,y,b,0.05) task.wait(gap) Input.click(x,y,b,0.05) end
Input.tripleClick     =function(x,y,b,gap) gap=gap or 0.08 for i=1,3 do Input.click(x,y,b,0.05) if i<3 then task.wait(gap) end end end
Input.clickAndHold    =function(x,y,dur,b) b=b or Input.LEFT dur=dur or 1 Input.mouseMove(x,y) task.wait(0.02) Input.mouseDown(x,y,b) task.wait(dur) Input.mouseUp(x,y,b) end
Input.clickHuman      =function(x,y,b,h,sp) sp=sp or 4 Input.click(x+math.random(-sp,sp),y+math.random(-sp,sp),b,h) end
Input.clickFromCenter =function(ox,oy,b,h) local cx,cy=Input.getScreenCenter() Input.click(cx+(ox or 0),cy+(oy or 0),b,h) end
Input.clickRegion     =function(x1,y1,x2,y2,b,h) Input.click(math.random(math.floor(x1),math.floor(x2)),math.random(math.floor(y1),math.floor(y2)),b,h) end
Input.clickUDim2      =function(xs,xo,ys,yo,b,h) local x,y=Input.fromUDim2Smart(xs,xo,ys,yo) Input.click(x,y,b,h) end
Input.clickRepeat     =function(x,y,n,iv,b,h) iv=iv or 0.1 for i=1,n do Input.click(x,y,b,h) if i<n then task.wait(iv) end end end

Input.drag=function(x1,y1,x2,y2,btn,steps,dur,style)
    btn=btn or Input.LEFT steps=steps or 25 dur=dur or 0.3 style=style or "linear"
    Input.mouseMove(x1,y1) task.wait(0.03) Input.mouseDown(x1,y1,btn) task.wait(0.05)
    local dt=dur/steps
    for i=1,steps do local t=ease(style,i/steps) Input.mouseMove(math.floor(lerp(x1,x2,t)),math.floor(lerp(y1,y2,t))) task.wait(dt) end
    Input.mouseUp(x2,y2,btn) _stats.dragCount+=1
end
Input.dragAsync=function(...) local a={...} task.spawn(Input.drag,table.unpack(a)) end
Input.swipe    =function(x1,y1,x2,y2,dur) Input.drag(x1,y1,x2,y2,Input.LEFT,30,dur or 0.2,"easeOut") end

Input.scroll      =function(x,y,amt,sd) sd=sd or 0.02 local up=amt>0 for _=1,math.abs(amt) do VIM:SendMouseWheelEvent(x,y,up,game) task.wait(sd) end _stats.scrolls+=1 end
Input.scrollHere  =function(amt,sd) local p=UIS:GetMouseLocation() Input.scroll(p.X,p.Y,amt,sd) end
Input.scrollSmooth=function(x,y,amt,dur) dur=dur or 0.5 local steps=math.max(1,math.abs(amt)) local dl=dur/steps local up=amt>0 for _=1,steps do VIM:SendMouseWheelEvent(x,y,up,game) task.wait(dl) end end

Input.getMousePos  =function() local p=UIS:GetMouseLocation() return p.X,p.Y end
Input.getMouseX    =function() return UIS:GetMouseLocation().X end
Input.getMouseY    =function() return UIS:GetMouseLocation().Y end

Input.waitForClick=function(btn,timeout)
    local t=({[Input.LEFT]=Enum.UserInputType.MouseButton1,[Input.RIGHT]=Enum.UserInputType.MouseButton2,[Input.MIDDLE]=Enum.UserInputType.MouseButton3})[btn or Input.LEFT] or Enum.UserInputType.MouseButton1
    local done,px,py=false,nil,nil
    local conn=UIS.InputBegan:Connect(function(inp) if inp.UserInputType==t then px,py=math.floor(inp.Position.X),math.floor(inp.Position.Y) done=true end end)
    local e=0 while not done do task.wait(0.05) e+=0.05 if timeout and e>=timeout then conn:Disconnect() return nil,nil end end
    conn:Disconnect() return px,py
end

Input.startMouseTracking=function() _trackMouse=true  _mouseTrail={} end
Input.stopMouseTracking =function() _trackMouse=false return _mouseTrail end
Input.getMouseTrail     =function() return _mouseTrail end
Input.getMouseSpeed     =function()
    if #_mouseTrail<2 then return 0 end
    local last=_mouseTrail[#_mouseTrail] local first=_mouseTrail[1]
    local dist=math.sqrt((last.x-first.x)^2+(last.y-first.y)^2)
    return dist/math.max(0.001,last.t-first.t)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- WORLD / CFRAME
-- ─────────────────────────────────────────────────────────────────────────────

local function clickAtSP(sp,b,h) Input.click(math.floor(sp.X),math.floor(sp.Y),b,h) end

Input.clickCFrame       =function(cf,b,h)   local sp,on=worldToScreen(cf.Position) if not on then warn_("world","clickCFrame: off screen") return false end clickAtSP(sp,b,h) return true end
Input.clickCFrameAsync  =function(cf,b,h)   task.spawn(Input.clickCFrame,cf,b,h) end
Input.clickPart         =function(part,b,h) if not part or not part:IsA("BasePart") then return false end return Input.clickCFrame(part.CFrame,b,h) end
Input.clickPartAsync    =function(part,b,h) task.spawn(Input.clickPart,part,b,h) end
Input.clickPosition     =function(wp,b,h)   local sp,on=worldToScreen(wp) if not on then return false end clickAtSP(sp,b,h) return true end
Input.clickPositionAsync=function(wp,b,h)   task.spawn(Input.clickPosition,wp,b,h) end
Input.clickModel        =function(m,b,h)    if not m or not m:IsA("Model") then return false end local cf=m:GetBoundingBox() return Input.clickCFrame(cf,b,h) end
Input.clickWhenOnScreen =function(cf,b,h,to) if not Input.waitUntilOnScreen(cf,to) then return false end return Input.clickCFrame(cf,b,h) end
Input.hoverCFrame       =function(cf,dur)   local sp,on=worldToScreen(cf.Position) if not on then return false end Input.mouseMove(math.floor(sp.X),math.floor(sp.Y)) if dur then task.wait(dur) end return true end
Input.hoverPart         =function(part,dur) if not part or not part:IsA("BasePart") then return false end return Input.hoverCFrame(part.CFrame,dur) end
Input.moveToCFrame      =function(cf,dur,style) local sp,on=worldToScreen(cf.Position) if not on then return false end Input.mouseMoveSmooth(math.floor(sp.X),math.floor(sp.Y),dur,style) return true end
Input.moveToPart        =function(part,dur,style) if not part or not part:IsA("BasePart") then return false end return Input.moveToCFrame(part.CFrame,dur,style) end
Input.dragBetweenParts  =function(pA,pB,b,steps,dur)
    local spA,onA=worldToScreen(pA.CFrame.Position) local spB,onB=worldToScreen(pB.CFrame.Position)
    if not onA or not onB then return false end
    Input.drag(math.floor(spA.X),math.floor(spA.Y),math.floor(spB.X),math.floor(spB.Y),b,steps,dur) return true
end
Input.clickNearestPart=function(tag,b,h)
    local char=Players.LocalPlayer and Players.LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart") if not root then return false end
    local best,bd=nil,math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (not tag or obj.Name==tag) then
            local d=(obj.Position-root.Position).Magnitude if d<bd then bd=d best=obj end
        end
    end
    if not best then return false end return Input.clickPart(best,b,h)
end
Input.clickNearestOnScreen=function(tag,b,h)
    local r=Input.getPartsOnScreen(tag) if #r==0 then return false end return Input.clickPart(r[1].part,b,h)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CAMERA
-- ─────────────────────────────────────────────────────────────────────────────

local _savedCamType=nil

Input.lookAt=function(wp)
    local cam=getCamera() _savedCamType=cam.CameraType
    cam.CameraType=Enum.CameraType.Scriptable cam.CFrame=CFrame.new(cam.CFrame.Position,wp)
end
Input.lookAtSmooth=function(wp,dur,style)
    dur=dur or 0.3 style=style or "easeInOut" local cam=getCamera()
    _savedCamType=cam.CameraType cam.CameraType=Enum.CameraType.Scriptable
    local s=cam.CFrame local e=CFrame.new(cam.CFrame.Position,wp)
    local steps=math.max(5,math.floor(dur/0.016)) local dt=dur/steps
    for i=1,steps do cam.CFrame=s:Lerp(e,ease(style,i/steps)) task.wait(dt) end
end
Input.restoreCamera=function() getCamera().CameraType=_savedCamType or Enum.CameraType.Custom end
Input.lookAndClick=function(wp,b,h,to)
    Input.lookAt(wp) task.wait(0.2) local cf=CFrame.new(wp)
    if not Input.waitUntilOnScreen(cf,to or 5) then Input.restoreCamera() return false end
    task.wait(0.05) local r=Input.clickCFrame(cf,b,h) Input.restoreCamera() return r
end
Input.orbitCamera=function(target,radius,dur,revs)
    revs=revs or 1 dur=dur or 3 local cam=getCamera()
    _savedCamType=cam.CameraType cam.CameraType=Enum.CameraType.Scriptable
    local steps=math.max(20,math.floor(dur/0.016)) local dt=dur/steps
    for i=1,steps do
        local angle=(i/steps)*revs*2*math.pi
        cam.CFrame=CFrame.new(Vector3.new(target.X+math.cos(angle)*radius,target.Y+radius*0.5,target.Z+math.sin(angle)*radius),target)
        task.wait(dt)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MACROS
-- ─────────────────────────────────────────────────────────────────────────────

Input.newMacro=function(name)
    local m={name=name or ("macro_"..tostring(tick())),actions={},speed=1.0,loops=1,enabled=true,tags={},meta={},created=tick()}
    if name then macroStore[name]=m end return m
end

Input.addKey        =function(m,key,ht,dl)           table.insert(m.actions,{type="tap",key=key,holdTime=ht or 0.05,delay=dl or 0}) end
Input.addKeyDown    =function(m,key,dl)               table.insert(m.actions,{type="keydown",key=key,delay=dl or 0}) end
Input.addKeyUp      =function(m,key,dl)               table.insert(m.actions,{type="keyup",key=key,delay=dl or 0}) end
Input.addWait       =function(m,dur)                  table.insert(m.actions,{type="wait",duration=dur}) end
Input.addWaitRandom =function(m,mn,mx)                table.insert(m.actions,{type="waitrandom",minDur=mn,maxDur=mx}) end
Input.addReleaseAll =function(m,dl)                   table.insert(m.actions,{type="releaseall",delay=dl or 0}) end
Input.addLabel      =function(m,label)                table.insert(m.actions,{type="label",label=label}) end
Input.addGoto       =function(m,label,times)          table.insert(m.actions,{type="goto",label=label,times=times or 1,_count=0}) end
Input.addClick      =function(m,x,y,b,ht,dl)         table.insert(m.actions,{type="click",x=x,y=y,button=b or Input.LEFT,holdTime=ht or 0.05,delay=dl or 0}) end
Input.addRightClick =function(m,x,y,ht,dl)           Input.addClick(m,x,y,Input.RIGHT,ht,dl) end
Input.addDoubleClick=function(m,x,y,dl)              table.insert(m.actions,{type="doubleclick",x=x,y=y,delay=dl or 0}) end
Input.addTripleClick=function(m,x,y,dl)              table.insert(m.actions,{type="tripleclick",x=x,y=y,delay=dl or 0}) end
Input.addMove       =function(m,x,y,dl)              table.insert(m.actions,{type="move",x=x,y=y,delay=dl or 0}) end
Input.addSmoothMove =function(m,x,y,dur,style,dl)    table.insert(m.actions,{type="smoothmove",x=x,y=y,duration=dur or 0.3,easing=style or "linear",delay=dl or 0}) end
Input.addNaturalMove=function(m,x,y,dur,dl)          table.insert(m.actions,{type="naturalmove",x=x,y=y,duration=dur or 0.3,delay=dl or 0}) end
Input.addScroll     =function(m,x,y,amt,dl)          table.insert(m.actions,{type="scroll",x=x,y=y,amount=amt or 1,delay=dl or 0}) end
Input.addScrollHere =function(m,amt,dl)              table.insert(m.actions,{type="scrollhere",amount=amt or 1,delay=dl or 0}) end
Input.addCombo      =function(m,keys,rd,dl)          table.insert(m.actions,{type="combo",keys=keys,releaseDelay=rd or 0.05,delay=dl or 0}) end
Input.addText       =function(m,text,iv,rand,dl)     table.insert(m.actions,{type="text",text=text,interval=iv or 0.05,randomize=rand or false,delay=dl or 0}) end
Input.addTextHuman  =function(m,text,wpm,dl)         table.insert(m.actions,{type="texthuman",text=text,wpm=wpm or 60,delay=dl or 0}) end
Input.addDrag       =function(m,x1,y1,x2,y2,b,steps,dur,style,dl) table.insert(m.actions,{type="drag",x1=x1,y1=y1,x2=x2,y2=y2,button=b or Input.LEFT,steps=steps or 25,duration=dur or 0.3,easing=style or "linear",delay=dl or 0}) end
Input.addSwipe      =function(m,x1,y1,x2,y2,dur,dl) table.insert(m.actions,{type="swipe",x1=x1,y1=y1,x2=x2,y2=y2,duration=dur or 0.2,delay=dl or 0}) end
Input.addSpam       =function(m,key,n,iv,dl)         table.insert(m.actions,{type="spam",key=key,times=n or 5,interval=iv or 0.05,delay=dl or 0}) end
Input.addSequence   =function(m,kl,iv,dl)            table.insert(m.actions,{type="sequence",keyList=kl,interval=iv or 0.1,delay=dl or 0}) end
Input.addCFrameClick=function(m,cf,b,h,dl)           table.insert(m.actions,{type="cfclick",cf=cf,button=b or Input.LEFT,holdTime=h or 0.05,delay=dl or 0}) end
Input.addPartClick  =function(m,part,b,h,dl)         table.insert(m.actions,{type="partclick",part=part,button=b or Input.LEFT,holdTime=h or 0.05,delay=dl or 0}) end
Input.addRepeat     =function(m,inner,n)             table.insert(m.actions,{type="repeat",macro=inner,times=n or 1}) end
Input.addCondition  =function(m,fn,t,f)              table.insert(m.actions,{type="condition",condFn=fn,trueMacro=t,falseMacro=f}) end
Input.addCallback   =function(m,fn,dl)               table.insert(m.actions,{type="callback",fn=fn,delay=dl or 0}) end
Input.addPrint      =function(m,msg)                 table.insert(m.actions,{type="callback",fn=function() print("[Macro] "..tostring(msg)) end,delay=0}) end
Input.addNotify     =function(m,title,text,dur)       table.insert(m.actions,{type="callback",fn=function() Input.notify(title,text,dur) end,delay=0}) end
Input.addJump       =function(m,dl)                   table.insert(m.actions,{type="callback",fn=Input.jump,delay=dl or 0}) end
Input.addUDim2Click =function(m,xs,xo,ys,yo,b,h,dl) table.insert(m.actions,{type="udim2click",xScale=xs,xOffset=xo or 0,yScale=ys,yOffset=yo or 0,button=b or Input.LEFT,holdTime=h or 0.05,delay=dl or 0}) end
Input.addWaitFor    =function(m,fn,to,iv)            table.insert(m.actions,{type="waitfor",condFn=fn,timeout=to or 10,interval=iv or 0.05}) end
Input.addBreakIf    =function(m,fn)                  table.insert(m.actions,{type="breakif",condFn=fn}) end

Input.runMacro=function(macro,overLoops,overSpeed)
    if not macro.enabled then return end
    local loops=overLoops or macro.loops or 1
    local speed=overSpeed or macro.speed or 1.0
    _stats.macrosRun+=1 fireHook("beforeMacro",macro.name)
    if _macroWatchers[macro.name] then for _,fn in ipairs(_macroWatchers[macro.name]) do pcall(fn,"start",macro.name) end end

    local labels={} for i,a in ipairs(macro.actions) do if a.type=="label" then labels[a.label]=i end end
    local _break=false

    local function run(actions)
        local i=1
        while i<=#actions and not _break do
            local a=actions[i]
            if a.delay and a.delay>0 then task.wait(a.delay/speed) end
            if     a.type=="tap"         then Input.tap(a.key,a.holdTime/speed)
            elseif a.type=="keydown"     then Input.keyDown(a.key)
            elseif a.type=="keyup"       then Input.keyUp(a.key)
            elseif a.type=="click"       then Input.click(a.x,a.y,a.button,a.holdTime/speed)
            elseif a.type=="doubleclick" then Input.doubleClick(a.x,a.y)
            elseif a.type=="tripleclick" then Input.tripleClick(a.x,a.y)
            elseif a.type=="cfclick"     then Input.clickCFrame(a.cf,a.button,a.holdTime/speed)
            elseif a.type=="partclick"   then Input.clickPart(a.part,a.button,a.holdTime/speed)
            elseif a.type=="move"        then Input.mouseMove(a.x,a.y)
            elseif a.type=="smoothmove"  then Input.mouseMoveSmooth(a.x,a.y,a.duration/speed,a.easing)
            elseif a.type=="naturalmove" then Input.mouseMoveNatural(a.x,a.y,a.duration/speed)
            elseif a.type=="scroll"      then Input.scroll(a.x,a.y,a.amount)
            elseif a.type=="scrollhere"  then Input.scrollHere(a.amount)
            elseif a.type=="wait"        then task.wait(a.duration/speed)
            elseif a.type=="waitrandom"  then task.wait((a.minDur+(math.random()*(a.maxDur-a.minDur)))/speed)
            elseif a.type=="combo"       then Input.combo(a.keys,nil,a.releaseDelay)
            elseif a.type=="text"        then Input.typeText(a.text,a.interval/speed,a.randomize)
            elseif a.type=="texthuman"   then Input.typeHuman(a.text,a.wpm*speed)
            elseif a.type=="drag"        then Input.drag(a.x1,a.y1,a.x2,a.y2,a.button,a.steps,a.duration/speed,a.easing)
            elseif a.type=="swipe"       then Input.swipe(a.x1,a.y1,a.x2,a.y2,a.duration/speed)
            elseif a.type=="spam"        then Input.spam(a.key,a.times,a.interval/speed)
            elseif a.type=="sequence"    then Input.sequence(a.keyList,a.interval/speed)
            elseif a.type=="releaseall"  then Input.releaseAll()
            elseif a.type=="callback"    then pcall(a.fn)
            elseif a.type=="udim2click"  then Input.clickUDim2(a.xScale,a.xOffset,a.yScale,a.yOffset,a.button,a.holdTime/speed)
            elseif a.type=="waitfor"     then Input.waitFor(a.condFn,a.timeout,a.interval)
            elseif a.type=="breakif"     then if a.condFn() then _break=true end
            elseif a.type=="breakif"     then if pcall(a.condFn) and a.condFn() then _break=true end
            elseif a.type=="waitfor"     then local e2=0 while not pcall(a.condFn) or not a.condFn() do task.wait(a.interval or 0.05) e2=e2+(a.interval or 0.05) if a.timeout and e2>=a.timeout then break end end
            elseif a.type=="repeat"      then for _=1,a.times do if _break then break end run(a.macro.actions) end
            elseif a.type=="condition"   then
                if a.condFn() then if a.trueMacro then run(a.trueMacro.actions) end
                else               if a.falseMacro then run(a.falseMacro.actions) end end
            elseif a.type=="goto" then
                local target=labels[a.label]
                if target then a._count=(a._count or 0)+1 if a._count<=a.times then i=target else a._count=0 end end
            end
            i+=1
        end
    end

    for l=1,loops do if _break then break end run(macro.actions) end
    fireHook("afterMacro",macro.name)
    if _macroWatchers[macro.name] then for _,fn in ipairs(_macroWatchers[macro.name]) do pcall(fn,"stop",macro.name) end end
end

Input.runMacroAsync=function(macro,overLoops,overSpeed)
    _macroIdCounter+=1 local id=_macroIdCounter
    task.spawn(function() _activeMacros[id]=macro.name Input.runMacro(macro,overLoops,overSpeed) _activeMacros[id]=nil end)
    return id
end

Input.getActiveMacros=function() return _activeMacros end
Input.watchMacro=function(name,cb) if not _macroWatchers[name] then _macroWatchers[name]={} end table.insert(_macroWatchers[name],cb) end

Input.saveMacro   =function(name,m)   macroStore[name]=m m.name=name end
Input.loadMacro   =function(name)     return macroStore[name] end
Input.deleteMacro =function(name)     macroStore[name]=nil end
Input.clearMacro  =function(m)        m.actions={} end
Input.listMacros  =function()         local n={} for k in pairs(macroStore) do table.insert(n,k) end table.sort(n) return n end

Input.copyMacro=function(m,newName)
    local copy={name=newName or (m.name.."_copy"),actions={},speed=m.speed,loops=m.loops,enabled=m.enabled,tags={},meta={}}
    for _,a in ipairs(m.actions) do local c={} for k,v in pairs(a) do c[k]=v end table.insert(copy.actions,c) end
    if newName then macroStore[newName]=copy end return copy
end
Input.mergeMacros=function(mA,mB,name)
    local merged=Input.copyMacro(mA,name)
    for _,a in ipairs(mB.actions) do local c={} for k,v in pairs(a) do c[k]=v end table.insert(merged.actions,c) end
    return merged
end
Input.reverseMacro=function(m,name)
    local rev=Input.copyMacro(m,name) local n=#rev.actions
    for i=1,math.floor(n/2) do rev.actions[i],rev.actions[n-i+1]=rev.actions[n-i+1],rev.actions[i] end return rev
end
Input.debugMacro=function(m)
    print(string.format("[Macro:%s] %d actions | loops=%d speed=%.1f enabled=%s",m.name,#m.actions,m.loops,m.speed,tostring(m.enabled)))
    for i,a in ipairs(m.actions) do
        local ex="" if a.key then ex=" key="..tostring(a.key) end if a.x then ex=ex.." x="..tostring(a.x).." y="..tostring(a.y) end
        print(string.format("  [%02d] %-14s%s",i,a.type,ex))
    end
end
Input.getMacroEstimatedTime=function(m)
    local total=0
    for _,a in ipairs(m.actions) do
        if a.delay then total+=a.delay end
        if a.type=="wait" then total+=a.duration
        elseif a.type=="tap" then total+=(a.holdTime or 0.05)+0.02
        elseif a.type=="click" then total+=(a.holdTime or 0.05)+0.04
        elseif a.type=="drag" then total+=(a.duration or 0.3)
        elseif a.type=="smoothmove" then total+=(a.duration or 0.3)
        elseif a.type=="text" then total+=#(a.text or "")*(a.interval or 0.05) end
    end
    return total*(m.loops or 1)/(m.speed or 1)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- RECORDING
-- ─────────────────────────────────────────────────────────────────────────────

Input.startRecording=function(name)
    recActions={} recStart=tick() recording=true
    for _,c in ipairs(recConns) do c:Disconnect() end recConns={}
    table.insert(recConns,UIS.InputBegan:Connect(function(inp)
        if not recording then return end local t=tick()-recStart
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            table.insert(recActions,{time=t,type="keyDown",key=tostring(inp.KeyCode)})
        elseif inp.UserInputType==Enum.UserInputType.MouseButton1 then
            table.insert(recActions,{time=t,type="mouseDown",x=math.floor(inp.Position.X),y=math.floor(inp.Position.Y),button=0})
        elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then
            table.insert(recActions,{time=t,type="mouseDown",x=math.floor(inp.Position.X),y=math.floor(inp.Position.Y),button=1})
        end
    end))
    table.insert(recConns,UIS.InputEnded:Connect(function(inp)
        if not recording then return end local t=tick()-recStart
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            table.insert(recActions,{time=t,type="keyUp",key=tostring(inp.KeyCode)})
        elseif inp.UserInputType==Enum.UserInputType.MouseButton1 then
            table.insert(recActions,{time=t,type="mouseUp",x=math.floor(inp.Position.X),y=math.floor(inp.Position.Y),button=0})
        end
    end))
    table.insert(recConns,UIS.InputChanged:Connect(function(inp)
        if not recording then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement then
            table.insert(recActions,{time=tick()-recStart,type="mouseMove",x=math.floor(inp.Position.X),y=math.floor(inp.Position.Y)})
        end
    end))
    log("rec","started: "..(name or "unnamed"))
end

Input.stopRecording=function(saveName)
    recording=false for _,c in ipairs(recConns) do c:Disconnect() end recConns={}
    log("rec","stopped. "..#recActions.." actions")
    if saveName then
        macroStore[saveName]={name=saveName,recorded=true,actions=recActions,loops=1,speed=1.0,enabled=true,tags={},meta={}}
        _stats.recordingsSaved+=1
    end
    return recActions
end

Input.isRecording      =function() return recording end
Input.getLastRecording =function() return recActions end
Input.getRecordingTime =function() if recording then return tick()-recStart else return 0 end end
Input.getRecordingCount=function() return #recActions end

Input.playRecording=function(actions,speed,loops)
    speed=speed or 1.0 loops=loops or 1 actions=actions or recActions
    for _=1,loops do
        local startTime=tick() local i=1
        while i<=#actions do
            local a=actions[i]
            if (tick()-startTime)*speed>=a.time then
                if a.type=="keyDown" or a.type=="keyUp" then
                    local kname=tostring(a.key):match("KeyCode%.(.+)")
                    if kname then local kc=safeKC(kname) if kc then VIM:SendKeyEvent(a.type=="keyDown",kc,false,game) end end
                elseif a.type=="mouseDown" then VIM:SendMouseButtonEvent(a.x,a.y,a.button,true,game,1)
                elseif a.type=="mouseUp"   then VIM:SendMouseButtonEvent(a.x,a.y,a.button,false,game,1)
                elseif a.type=="mouseMove" then VIM:SendMouseMoveEvent(a.x,a.y,game)
                end i+=1
            else task.wait(0.01) end
        end
    end
end
Input.playRecordingAsync=function(a,s,l) task.spawn(Input.playRecording,a,s,l) end

Input.trimRecording=function(actions,threshold)
    threshold=threshold or 0.5 if #actions==0 then return actions end
    local first=actions[1].time local last=actions[#actions].time local trimmed={}
    for _,a in ipairs(actions) do if a.time>=first+threshold and a.time<=last-threshold then table.insert(trimmed,a) end end
    return trimmed
end
Input.scaleRecording=function(actions,factor)
    local out={} for _,a in ipairs(actions) do local c={} for k,v in pairs(a) do c[k]=v end c.time=c.time*factor table.insert(out,c) end return out
end


-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────────────────────
Input.notify=function(title,text,dur)
    dur=dur or 4
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=tostring(title),Text=tostring(text),Duration=dur})
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CLIPBOARD
-- ─────────────────────────────────────────────────────────────────────────────
local function toClipboard(text)
    if setclipboard then pcall(setclipboard,text) return true
    elseif toclipboard then pcall(toclipboard,text) return true end
    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FILE SYSTEM  (InputModule/ folder tree + JSON codec)
-- ─────────────────────────────────────────────────────────────────────────────
local FS_ROOT    = "InputModule"
local FS_MACROS  = FS_ROOT.."/macros"
local FS_RECS    = FS_ROOT.."/recordings"
local FS_LOGS    = FS_ROOT.."/logs"
local FS_PROFILES= FS_ROOT.."/profiles"

-- check if filesystem is usable
local FS_AVAILABLE = (function()
    return type(writefile)=="function" and type(readfile)=="function"
       and type(listfiles)=="function" and type(makefolder)=="function"
       and type(isfolder)=="function"
end)()

local function fsEnsure(path)
    if not FS_AVAILABLE then return end
    pcall(function() if not isfolder(path) then makefolder(path) end end)
end
local function fsInitFolders()
    fsEnsure(FS_ROOT); fsEnsure(FS_MACROS); fsEnsure(FS_RECS)
    fsEnsure(FS_LOGS); fsEnsure(FS_PROFILES)
end
local function fsWrite(path,data)
    if not writefile then return false end
    local ok,err=pcall(writefile,path,data); return ok,err
end
local function fsRead(path)
    if not readfile then return nil end
    local ok,d=pcall(function()
        if type(isfile)=="function" and not isfile(path) then return nil end
        return readfile(path)
    end)
    return ok and d or nil
end
local function fsList(dir)
    if not listfiles then return {} end
    local ok,f=pcall(listfiles,dir); return ok and f or {}
end

-- ── tiny JSON encoder (string/number/bool/nil/array/object) ──────────────────
local function jsonEncode(val)
    local t=type(val)
    if t=="nil" then return "null"
    elseif t=="boolean" then return tostring(val)
    elseif t=="number"  then return (val~=val) and "null" or tostring(val)
    elseif t=="string"  then
        return '"'..val:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r')..'"'
    elseif t=="table" then
        local isArr,maxN=true,0
        for k in pairs(val) do
            if type(k)~="number" or k<1 or math.floor(k)~=k then isArr=false break end
            if k>maxN then maxN=k end
        end
        if isArr and maxN==#val and #val>0 then
            local p={} for _,v in ipairs(val) do table.insert(p,jsonEncode(v)) end
            return "["..table.concat(p,",").."]"
        else
            local p={} for k,v in pairs(val) do
                if type(k)=="string" or type(k)=="number" then
                    table.insert(p,jsonEncode(tostring(k))..":"..jsonEncode(v))
                end
            end
            return "{"..table.concat(p,",").."}"
        end
    end
    return "null"
end

-- ── tiny JSON decoder ─────────────────────────────────────────────────────────
local function jsonDecode(s)
    local pos=1
    local function skip() while pos<=#s and s:sub(pos,pos):match("%s") do pos=pos+1 end end
    local function peek() skip() return s:sub(pos,pos) end
    local function consume(c) skip() if s:sub(pos,pos)==c then pos=pos+1 return true end return false end
    local decode
    local function dStr()
        pos=pos+1; local buf={}
        while pos<=#s do
            local c=s:sub(pos,pos)
            if c=='"' then pos=pos+1 break
            elseif c=='\\' then
                pos=pos+1; local e=s:sub(pos,pos)
                if e=='"' then buf[#buf+1]='"' elseif e=='\\' then buf[#buf+1]='\\' elseif e=='n' then buf[#buf+1]='\n' elseif e=='r' then buf[#buf+1]='\r' elseif e=='t' then buf[#buf+1]='\t' else buf[#buf+1]=e end
            else buf[#buf+1]=c end
            pos=pos+1
        end
        return table.concat(buf)
    end
    local function dNum()
        local st=pos; if s:sub(pos,pos)=="-" then pos=pos+1 end
        while pos<=#s and s:sub(pos,pos):match("[%d%.eE%+%-]") do pos=pos+1 end
        return tonumber(s:sub(st,pos-1))
    end
    local function dArr()
        pos=pos+1; local a={} skip()
        if peek()=="]" then pos=pos+1 return a end
        repeat a[#a+1]=decode() skip() until not consume(",")
        consume("]"); return a
    end
    local function dObj()
        pos=pos+1; local o={} skip()
        if peek()=="}" then pos=pos+1 return o end
        repeat skip(); local k=dStr(); consume(":"); o[k]=decode() skip() until not consume(",")
        consume("}"); return o
    end
    decode=function()
        skip(); local c=peek()
        if c=='"' then return dStr()
        elseif c=="{" then return dObj()
        elseif c=="[" then return dArr()
        elseif c=="t" then pos=pos+4 return true
        elseif c=="f" then pos=pos+5 return false
        elseif c=="n" then pos=pos+4 return nil
        elseif c=="-" or c:match("%d") then return dNum()
        end
        return nil
    end
    local ok,r=pcall(decode); return ok and r or nil
end

-- ── serialize macro to JSON (skips live-ref action types) ───────────────────
local function macroToJson(m)
    local safe={name=m.name,speed=m.speed,loops=m.loops,enabled=m.enabled,
                tags=m.tags or {},created=m.created,actions={}}
    for _,a in ipairs(m.actions) do
        if a.type~="cfclick" and a.type~="partclick" and a.type~="repeat"
        and a.type~="condition" and a.type~="callback" and a.type~="breakif"
        and a.type~="waitfor" then
            local ca={}
            for k,v in pairs(a) do
                if type(v)=="string" or type(v)=="number" or type(v)=="boolean" then ca[k]=v
                elseif type(v)=="table" then ca[k]=v end
            end
            safe.actions[#safe.actions+1]=ca
        end
    end
    return jsonEncode(safe)
end

-- ── deserialize JSON back to macro table ────────────────────────────────────
local function macroFromJson(json)
    local data=jsonDecode(json)
    if not data or type(data)~="table" then return nil end
    local m={name=data.name or "imported",
             speed=tonumber(data.speed) or 1.0,
             loops=tonumber(data.loops) or 1,
             enabled=data.enabled~=false,
             tags=data.tags or {},meta={},
             created=data.created,actions={}}
    if data.actions then
        for _,a in ipairs(data.actions) do
            local ca={}; for k,v in pairs(a) do ca[k]=v end
            m.actions[#m.actions+1]=ca
        end
    end
    return m
end

-- ── public file API ──────────────────────────────────────────────────────────
Input.saveMacroToFile=function(macro)
    if not FS_AVAILABLE then warn_("file","writefile not available") return false end
    local path=FS_MACROS.."/"..macro.name..".json"
    local ok,err=fsWrite(path,macroToJson(macro))
    if ok then log("file","macro saved -> "..path); Input.notify("Saved",macro.name.." written to disk",3)
    else warn_("file","save failed: "..tostring(err)) end
    return ok
end

Input.loadMacroFromFile=function(name)
    if not FS_AVAILABLE then warn_("file","readfile not available") return nil end
    local data=fsRead(FS_MACROS.."/"..name..".json")
    if not data then warn_("file","not found: "..name) return nil end
    local m=macroFromJson(data)
    if not m then warn_("file","parse error: "..name) return nil end
    macroStore[m.name]=m
    log("file","loaded <- "..name)
    Input.notify("Loaded",m.name.." ("..#m.actions.." actions)",3)
    return m
end

Input.listMacroFiles=function()
    local files=fsList(FS_MACROS); local names={}
    for _,f in ipairs(files) do
        local n=tostring(f):match("([^/\\]+)%.json$")
        if n then names[#names+1]=n end
    end
    table.sort(names); return names
end

Input.saveAllMacros=function()
    if not FS_AVAILABLE then warn_("file","FS not available") return 0 end
    local count=0
    for _,m in pairs(macroStore) do if Input.saveMacroToFile(m) then count=count+1 end end
    log("file","saved "..count.." macros"); return count
end

Input.loadAllMacros=function()
    if not FS_AVAILABLE then warn_("file","FS not available") return 0 end
    local files=Input.listMacroFiles(); local count=0
    for _,name in ipairs(files) do if Input.loadMacroFromFile(name) then count=count+1 end end
    log("file","loaded "..count.." macros"); return count
end

Input.deleteMacroFile=function(name)
    if not FS_AVAILABLE then return false end
    local path=FS_MACROS.."/"..name..".json"
    local ok=pcall(function()
        if type(delfile)=="function" then delfile(path)
        else fsWrite(path,'{"_deleted":true}') end
    end)
    log("file","deleted: "..path); return ok
end

Input.exportMacroToClipboard=function(macro)
    local json=macroToJson(macro)
    if toClipboard(json) then
        Input.notify("Exported",macro.name.." JSON in clipboard",3)
        return true
    end
    warn_("file","clipboard unavailable"); return false
end

Input.importMacroFromJson=function(json)
    local m=macroFromJson(json)
    if not m then warn_("file","bad JSON") return nil end
    macroStore[m.name]=m
    log("file","imported: "..m.name)
    Input.notify("Imported",m.name.." ("..#m.actions.." actions)",3)
    return m
end

Input.saveRecordingToFile=function(name,actions)
    if not FS_AVAILABLE then warn_("file","FS not available") return false end
    local ok=fsWrite(FS_RECS.."/"..name..".json",jsonEncode(actions or recActions))
    if ok then log("file","recording saved: "..name) end; return ok
end

Input.loadRecordingFromFile=function(name)
    if not FS_AVAILABLE then warn_("file","FS not available") return nil end
    local data=fsRead(FS_RECS.."/"..name..".json")
    if not data then warn_("file","recording not found: "..name) return nil end
    local acts=jsonDecode(data)
    if acts then
        for _,a in ipairs(acts) do
            if a.x then a.x=tonumber(a.x) end
            if a.y then a.y=tonumber(a.y) end
            if a.time then a.time=tonumber(a.time) end
        end
        log("file","recording loaded: "..name.." ("..#acts.." actions)")
    end
    return acts
end

Input.listRecordingFiles=function()
    local files=fsList(FS_RECS); local names={}
    for _,f in ipairs(files) do
        local n=tostring(f):match("([^/\\]+)%.json$")
        if n then names[#names+1]=n end
    end
    table.sort(names); return names
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ANTI-AFK
-- ─────────────────────────────────────────────────────────────────────────────
Input.startAntiAfk=function(mode,interval)
    if _antiAfkStop then warn_("antiafk","already running") return end
    mode=mode or "jump"; interval=interval or 60
    local running=true
    local function doAction()
        _stats.antiAfkSaves=_stats.antiAfkSaves+1
        if mode=="jump" then
            local h=Input.getHumanoid and Input.getHumanoid()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        elseif mode=="nudge" then
            VIM:SendKeyEvent(true,Enum.KeyCode.W,false,game)
            task.wait(0.1)
            VIM:SendKeyEvent(false,Enum.KeyCode.W,false,game)
        elseif mode=="chat" then
            VIM:SendKeyEvent(true,Enum.KeyCode.Slash,false,game); task.wait(0.05)
            VIM:SendKeyEvent(false,Enum.KeyCode.Slash,false,game); task.wait(0.1)
            VIM:SendKeyEvent(true,Enum.KeyCode.Escape,false,game); task.wait(0.05)
            VIM:SendKeyEvent(false,Enum.KeyCode.Escape,false,game)
        end
        log("antiafk","action fired ("..mode..")")
    end
    task.spawn(function()
        while running do task.wait(interval) if running then pcall(doAction) end end
    end)
    _antiAfkStop=function() running=false; _antiAfkStop=nil end
    log("antiafk","started  mode="..mode.."  interval="..interval.."s")
end
Input.stopAntiAfk=function()
    if _antiAfkStop then _antiAfkStop(); log("antiafk","stopped")
    else warn_("antiafk","not running") end
end
Input.isAntiAfkRunning=function() return _antiAfkStop~=nil end

-- ─────────────────────────────────────────────────────────────────────────────
-- PLAYER UTILITIES
-- ─────────────────────────────────────────────────────────────────────────────
Input.getLocalPlayer =function() return Players.LocalPlayer end
Input.getCharacter   =function() return Players.LocalPlayer and Players.LocalPlayer.Character end
Input.getRootPart    =function() local c=Input.getCharacter() return c and c:FindFirstChild("HumanoidRootPart") end
Input.getHumanoid    =function() local c=Input.getCharacter() return c and c:FindFirstChildOfClass("Humanoid") end
Input.getPlayerPos   =function() local r=Input.getRootPart() return r and r.Position or nil end
Input.setWalkSpeed   =function(speed) local h=Input.getHumanoid() if h then h.WalkSpeed=speed end end
Input.setJumpPower   =function(power) local h=Input.getHumanoid() if h then h.JumpPower=power end end
Input.jump=function()
    local h=Input.getHumanoid() if not h then return false end
    h:ChangeState(Enum.HumanoidStateType.Jumping) return true
end
Input.walkTo=function(target,timeout)
    local h=Input.getHumanoid() if not h then return false end
    if typeof(target)=="Instance" and target:IsA("BasePart") then target=target.Position end
    h:MoveTo(target)
    local reached=false
    local conn=h.MoveToFinished:Connect(function(r) reached=r end)
    local t=0
    while not reached do
        task.wait(0.1); t=t+0.1
        if timeout and t>=timeout then conn:Disconnect() return false end
    end
    conn:Disconnect() return true
end
Input.getPlayerList  =function() local r={} for _,p in ipairs(Players:GetPlayers()) do r[#r+1]=p.Name end return r end
Input.getPlayerByName=function(name) return Players:FindFirstChild(name) end
Input.getDistanceTo  =function(target)
    local root=Input.getRootPart() if not root then return math.huge end
    local pos=typeof(target)=="Vector3" and target or (target:IsA and target:IsA("BasePart") and target.Position)
    if not pos then return math.huge end
    return (root.Position-pos).Magnitude
end
Input.fireClickDetector=function(part,dist)
    if not fireclickdetector then warn_("world","fireclickdetector unavailable") return false end
    local cd=part:FindFirstChildOfClass("ClickDetector")
    if not cd then warn_("world","no ClickDetector on "..part.Name) return false end
    pcall(fireclickdetector,cd,dist or 0) return true
end
Input.fireProximityPrompt=function(part)
    if not fireproximityprompt then warn_("world","fireproximityprompt unavailable") return false end
    local pp=part:FindFirstChildOfClass("ProximityPrompt")
    if not pp then warn_("world","no ProximityPrompt on "..part.Name) return false end
    pcall(fireproximityprompt,pp) return true
end
Input.fireTouchInterest=function(part,touchPart)
    if not firetouchinterest then warn_("world","firetouchinterest unavailable") return false end
    touchPart=touchPart or Input.getRootPart()
    if not touchPart then return false end
    pcall(firetouchinterest,touchPart,part,0) return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MACRO SCHEDULER
-- ─────────────────────────────────────────────────────────────────────────────
Input.scheduleMacro=function(macro,intervalSecs,runImmediately)
    local id=tostring(tick()); local running=true
    _scheduledMacros[id]={macro=macro,interval=intervalSecs,stop=function() running=false end}
    task.spawn(function()
        if runImmediately then Input.runMacro(macro) end
        while running do
            task.wait(intervalSecs)
            if running then Input.runMacro(macro) end
        end
        _scheduledMacros[id]=nil
    end)
    log("schedule","macro '"..macro.name.."' every "..intervalSecs.."s  id="..id)
    return id
end
Input.unscheduleMacro=function(id)
    if _scheduledMacros[id] then _scheduledMacros[id].stop() _scheduledMacros[id]=nil end
end
Input.listScheduled=function()
    local r={} for id,s in pairs(_scheduledMacros) do r[#r+1]={id=id,name=s.macro.name,interval=s.interval} end return r
end
Input.runMacroWhile=function(macro,condFn,checkIv)
    checkIv=checkIv or 0.2
    task.spawn(function() while condFn() do Input.runMacro(macro) task.wait(checkIv) end end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- HOTKEYS
-- ─────────────────────────────────────────────────────────────────────────────

Input.bindHotkey=function(key,callback,label)
    hotkeys[key]={fn=callback,label=label or key}
    if not hotkeyConn then
        hotkeyConn=UIS.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Keyboard then
                local kname=tostring(inp.KeyCode):match("KeyCode%.(.+)")
                if kname and hotkeys[kname] then task.spawn(hotkeys[kname].fn) end
            end
        end)
    end
end
Input.bindHotkeyCombo=function(keys,callback)
    local sorted={} for _,k in ipairs(keys) do table.insert(sorted,k) end table.sort(sorted)
    local ck="__COMBO__"..table.concat(sorted,"+")
    hotkeys[ck]={fn=callback,label=table.concat(sorted,"+"),isCombo=true,keys=keys}
    UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            local all=true for _,k in ipairs(keys) do if not Input.isKeyHeld(k) then all=false break end end
            if all then task.spawn(callback) end
        end
    end)
end
Input.bindToggle=function(key,startFn,stopFn,label)
    local active=false
    Input.bindHotkey(key,function()
        if active then active=false if stopFn then stopFn() end else active=true if startFn then startFn() end end
    end,label)
    return function() return active end
end
Input.bindMacroHotkey=function(key,macro,label) Input.bindHotkey(key,function() Input.runMacroAsync(macro) end,label or macro.name) end
Input.unbindHotkey=function(key) hotkeys[key]=nil end
Input.unbindAll   =function() hotkeys={} if hotkeyConn then hotkeyConn:Disconnect() hotkeyConn=nil end end
Input.listHotkeys =function() local l={} for k,v in pairs(hotkeys) do table.insert(l,k.." -> "..(v.label or "?")) end return l end

-- ─────────────────────────────────────────────────────────────────────────────
-- EVENT LISTENERS
-- ─────────────────────────────────────────────────────────────────────────────

Input.onKey       =function(key,cb) local kc=KeyMap[key] if not kc then return nil end return UIS.InputBegan:Connect(function(inp) if inp.KeyCode==kc then task.spawn(cb) end end) end
Input.onKeyRelease=function(key,cb) local kc=KeyMap[key] if not kc then return nil end return UIS.InputEnded:Connect(function(inp) if inp.KeyCode==kc then task.spawn(cb) end end) end
Input.onMouseClick=function(btn,cb)
    local t=({[Input.LEFT]=Enum.UserInputType.MouseButton1,[Input.RIGHT]=Enum.UserInputType.MouseButton2,[Input.MIDDLE]=Enum.UserInputType.MouseButton3})[btn or Input.LEFT]
    return UIS.InputBegan:Connect(function(inp) if inp.UserInputType==t then task.spawn(function() cb(math.floor(inp.Position.X),math.floor(inp.Position.Y)) end) end end)
end
Input.onMouseMove =function(cb) return UIS.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement then task.spawn(function() cb(math.floor(inp.Position.X),math.floor(inp.Position.Y)) end) end end) end
Input.onScroll    =function(cb) return UIS.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseWheel then task.spawn(function() cb(inp.Position.Z>0 and 1 or -1) end) end end) end

-- ─────────────────────────────────────────────────────────────────────────────
-- LOOPING / TIMING
-- ─────────────────────────────────────────────────────────────────────────────

Input.wait       =function(s)    task.wait(s) end
Input.waitRandom =function(mn,mx) task.wait(mn+math.random()*(mx-mn)) end
Input.waitFor    =function(fn,timeout,iv)
    iv=iv or 0.05 local e=0
    while not fn() do task.wait(iv) e+=iv if timeout and e>=timeout then return false end end return true
end
Input.delay      =function(s,cb) task.spawn(function() task.wait(s) cb() end) end

Input.repeatAction=function(n,iv,cb) for i=1,n do cb(i) if i<n and iv>0 then task.wait(iv) end end end
Input.repeatAsync =function(n,iv,cb) task.spawn(Input.repeatAction,n,iv,cb) end

Input.loop=function(iv,cb)
    local running=true
    local thread=task.spawn(function() while running do local ok,err=pcall(cb) if not ok then warn_("loop",tostring(err)) end task.wait(iv) end end)
    return function() running=false pcall(task.cancel,thread) end
end
Input.loopFor=function(dur,iv,cb)
    local stop=false local endTime=tick()+dur
    local thread=task.spawn(function() while not stop and tick()<endTime do local ok,err=pcall(cb) if not ok then warn_("loopFor",tostring(err)) end task.wait(iv) end end)
    return function() stop=true pcall(task.cancel,thread) end
end
Input.loopTimes=function(n,iv,cb)
    return task.spawn(function() for i=1,n do local ok,err=pcall(cb,i) if not ok then warn_("loopTimes",tostring(err)) end if i<n then task.wait(iv) end end end)
end
Input.alternate=function(fA,fB,n,wA,wB) wA=wA or 0.5 wB=wB or 0.5 for _=1,n do pcall(fA) task.wait(wA) pcall(fB) task.wait(wB) end end

-- ─────────────────────────────────────────────────────────────────────────────
-- STATS
-- ─────────────────────────────────────────────────────────────────────────────

Input.getStats  =function() return {taps=_stats.taps,clicks=_stats.clicks,scrolls=_stats.scrolls,drags=_stats.dragCount,macrosRun=_stats.macrosRun,recordingsSaved=_stats.recordingsSaved,combos=_stats.combos or 0,typeChars=_stats.typeChars or 0,antiAfkSaves=_stats.antiAfkSaves or 0} end
Input.resetStats=function() _stats={taps=0,clicks=0,scrolls=0,macrosRun=0,recordingsSaved=0,dragCount=0,combos=0,typeChars=0,antiAfkSaves=0} end
Input.printStats=function()
    local s=Input.getStats()
    print(string.format("[Input] taps=%d clicks=%d scrolls=%d drags=%d macros=%d recs=%d combos=%d chars=%d antiafk=%d",s.taps,s.clicks,s.scrolls,s.drags,s.macrosRun,s.recordingsSaved,s.combos,s.typeChars,s.antiAfkSaves))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- KEY UTILS
-- ─────────────────────────────────────────────────────────────────────────────

Input.listKeys  =function() local k={} for key in pairs(KeyMap) do table.insert(k,key) end table.sort(k) return k end
Input.hasKey    =function(key) return KeyMap[key]~=nil end
Input.getVersion=function() return Input.VERSION end

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILE SYSTEM
-- ─────────────────────────────────────────────────────────────────────────────

Input.saveProfile=function(name)
    _profiles[name]={macros={},hotkeys={}}
    for k,m in pairs(macroStore) do _profiles[name].macros[k]=m end
    for k,h in pairs(hotkeys) do _profiles[name].hotkeys[k]=h end
    log("profile","saved: "..name)
end
Input.loadProfile=function(name)
    if not _profiles[name] then warn_("profile","not found: "..name) return false end
    macroStore=_profiles[name].macros hotkeys=_profiles[name].hotkeys
    log("profile","loaded: "..name) return true
end
Input.listProfiles=function() local p={} for k in pairs(_profiles) do table.insert(p,k) end return p end

-- ─────────────────────────────────────────────────────────────────────────────
-- FORUMS UI  (v2.0.0)
-- Replaces the old CoreGui-based UI with the xHeptc/forumsLib library.
-- ─────────────────────────────────────────────────────────────────────────────

Input.openUI = function()
    -- ── load the Forums library ──────────────────────────────────────────────
    local Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/xHeptc/forumsLib/main/source.lua"
    ))()

    -- ── executor / support info ──────────────────────────────────────────────
    local exec    = Input.Executor
    local execName = exec.name
    local vimOK   = exec.features["VIM"]
    local supportStr = vimOK and "SUPPORTED" or "NOT SUPPORTED (VIM missing)"

    local Forums = Library.new(
        "InputModule v" .. Input.VERSION ..
        "   |   " .. execName ..
        "   |   " .. supportStr
    )

    -- ── live state vars shared across tabs ───────────────────────────────────
    local spamLoopStop_  = nil
    local currentMacro_  = nil
    local recTimerThread = nil

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 1 ── INFO / EXECUTOR
    -- ════════════════════════════════════════════════════════════════════════
    local secInfo = Forums:NewSection("ℹ  Info & Executor")

    secInfo:NewButton("Print Executor Info", function()
        print("═══ InputModule Executor Info ═══")
        print("Executor  : " .. execName)
        print("Supported : " .. tostring(vimOK))
        print("Version   : " .. Input.VERSION)
        print("── Feature Flags ──")
        local feats = exec.features
        local names = {}
        for k in pairs(feats) do table.insert(names,k) end
        table.sort(names)
        for _,k in ipairs(names) do
            print(string.format("  %-14s %s", k, feats[k] and "✓" or "✗"))
        end
        print("═════════════════════════════════")
    end)

    secInfo:NewButton("Print Stats", function()
        Input.printStats()
    end)

    secInfo:NewButton("Reset Stats", function()
        Input.resetStats()
        print("[InputModule] Stats reset.")
    end)

    secInfo:NewButton("Print Recent Logs (20)", function()
        Input.printLogs(20)
    end)

    secInfo:NewButton("Clear Logs", function()
        Input.clearLogs()
        print("[InputModule] Logs cleared.")
    end)

    local loggingToggle = secInfo:NewToggle("Logging Enabled", function(state)
        Input.setLogging(state)
    end)
    -- default on
    loggingToggle:Update("Logging Enabled")

    secInfo:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 2 ── RECORDER
    -- ════════════════════════════════════════════════════════════════════════
    local secRec = Forums:NewSection("⏺  Recorder")

    local recNameBox = secRec:NewTextBox("Recording Name", function(text)
        -- stored on focus lost; nothing live needed
    end)
    recNameBox:Update("rec1")

    -- live recording timer label via a toggle that we hack into a display
    local recStatusToggle = secRec:NewToggle("Recording: IDLE", function(_) end)

    secRec:NewButton("▶  START Recording", function()
        if recording then print("[UI] Already recording!") return end
        local name = "rec1"  -- will read box on stop
        Input.startRecording(name)
        recStatusToggle:Update("Recording: ● LIVE")
        -- live heartbeat
        recTimerThread = task.spawn(function()
            while recording do
                local t = Input.getRecordingTime()
                local mins = math.floor(t/60)
                local secs = t % 60
                recStatusToggle:Update(string.format("Recording: ● %02d:%04.1f  (%d actions)", mins, secs, Input.getRecordingCount()))
                task.wait(0.1)
            end
        end)
    end)

    secRec:NewButton("■  STOP Recording", function()
        if not recording then print("[UI] Not recording.") return end
        if recTimerThread then pcall(task.cancel, recTimerThread) recTimerThread=nil end
        local name = "rec1"
        local actions = Input.stopRecording(name)
        recStatusToggle:Update(string.format("Recording: STOPPED  (%d actions)", #actions))
        print("[UI] Recording saved as: " .. name)
    end)

    local recSpeedSlider = secRec:NewSlider("Playback Speed %", 10, 300, function(v)
        -- captured at play time
    end)

    local recLoopSlider = secRec:NewSlider("Playback Loops", 1, 50, function(v)
        -- captured at play time
    end)

    secRec:NewButton("▶  PLAY Last Recording", function()
        local actions = Input.getLastRecording()
        if #actions == 0 then print("[UI] No recording to play.") return end
        local sp = (recSpeedSlider and 1) or 1      -- Forums slider returns value in callback only
        local lp = 1
        print("[UI] Playing recording (" .. #actions .. " actions)")
        Input.playRecordingAsync(actions, sp, lp)
    end)

    secRec:NewButton("Trim Recording (0.5s ends)", function()
        local trimmed = Input.trimRecording(Input.getLastRecording(), 0.5)
        print("[UI] Trimmed to " .. #trimmed .. " actions")
    end)

    secRec:NewButton("Print Recording Actions", function()
        local acts = Input.getLastRecording()
        print("[UI] Recording: " .. #acts .. " actions")
        for i,a in ipairs(acts) do
            print(string.format("  [%03d] t=%.2f  %s", i, a.time, a.type))
        end
    end)

    secRec:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 3 ── MACRO BUILDER
    -- ════════════════════════════════════════════════════════════════════════
    local secMacro = Forums:NewSection("⚙  Macro Builder")

    local macroNameBox = secMacro:NewTextBox("Macro Name", function(_) end)
    macroNameBox:Update("MyMacro")

    secMacro:NewButton("New Macro", function()
        local name = "MyMacro"
        currentMacro_ = Input.newMacro(name)
        print("[UI] Created macro: " .. name)
    end)

    secMacro:NewButton("Load Macro by Name", function()
        local name = "MyMacro"
        local m = Input.loadMacro(name)
        if m then
            currentMacro_ = m
            print("[UI] Loaded macro: " .. name .. " (" .. #m.actions .. " actions)")
        else
            print("[UI] Macro not found: " .. name)
        end
    end)

    secMacro:NewButton("Save Current Macro", function()
        if not currentMacro_ then print("[UI] No macro loaded.") return end
        Input.saveMacro(currentMacro_.name, currentMacro_)
        print("[UI] Saved: " .. currentMacro_.name)
    end)

    secMacro:NewButton("List All Macros (console)", function()
        local names = Input.listMacros()
        if #names == 0 then print("[UI] No macros saved.") return end
        print("[UI] Saved macros:")
        for _,n in ipairs(names) do print("  • " .. n) end
    end)

    secMacro:NewButton("Debug Current Macro (console)", function()
        if currentMacro_ then Input.debugMacro(currentMacro_) else print("[UI] No macro loaded.") end
    end)

    secMacro:NewButton("Estimate Macro Duration", function()
        if currentMacro_ then
            print(string.format("[UI] Estimated time: %.2fs", Input.getMacroEstimatedTime(currentMacro_)))
        else print("[UI] No macro loaded.") end
    end)

    secMacro:Seperator()

    -- ── Macro action adders ──────────────────────────────────────────────────
    local macroKeyBox = secMacro:NewTextBox("Key for Actions", function(_) end)
    macroKeyBox:Update("e")

    local macroHoldSlider  = secMacro:NewSlider("Hold (ms) 0–2000",  0, 2000, function(_) end)
    local macroDelaySlider = secMacro:NewSlider("Pre-delay (ms) 0–3000", 0, 3000, function(_) end)

    local function requireMacro()
        if not currentMacro_ then print("[UI] Create or load a macro first.") return false end
        return true
    end

    secMacro:NewButton("+ Add TAP", function()
        if not requireMacro() then return end
        Input.addKey(currentMacro_, "e", 0.05, 0)
        print("[UI] Added TAP e  (edit macroKeyBox for custom key)")
    end)

    secMacro:NewButton("+ Add KEY DOWN", function()
        if not requireMacro() then return end
        Input.addKeyDown(currentMacro_, "e", 0)
        print("[UI] Added KEY DOWN e")
    end)

    secMacro:NewButton("+ Add KEY UP", function()
        if not requireMacro() then return end
        Input.addKeyUp(currentMacro_, "e", 0)
        print("[UI] Added KEY UP e")
    end)

    secMacro:NewButton("+ Add CLICK (current mouse pos)", function()
        if not requireMacro() then return end
        local x, y = Input.getMousePos()
        Input.addClick(currentMacro_, x, y, Input.LEFT, 0.05, 0)
        print(string.format("[UI] Added CLICK at (%d,%d)", x, y))
    end)

    secMacro:NewButton("+ Add RIGHT CLICK (current pos)", function()
        if not requireMacro() then return end
        local x, y = Input.getMousePos()
        Input.addRightClick(currentMacro_, x, y, 0.05, 0)
        print(string.format("[UI] Added RIGHT CLICK at (%d,%d)", x, y))
    end)

    secMacro:NewButton("+ Add DOUBLE CLICK (current pos)", function()
        if not requireMacro() then return end
        local x, y = Input.getMousePos()
        Input.addDoubleClick(currentMacro_, x, y, 0)
        print(string.format("[UI] Added DOUBLE CLICK at (%d,%d)", x, y))
    end)

    secMacro:NewButton("+ Add SCROLL HERE (+3)", function()
        if not requireMacro() then return end
        Input.addScrollHere(currentMacro_, 3, 0)
        print("[UI] Added SCROLL +3")
    end)

    local macroWaitSlider = secMacro:NewSlider("Wait Duration (ms)", 50, 5000, function(_) end)
    secMacro:NewButton("+ Add WAIT", function()
        if not requireMacro() then return end
        Input.addWait(currentMacro_, 0.5)
        print("[UI] Added WAIT 0.5s")
    end)

    secMacro:NewButton("+ Add RANDOM WAIT (0.1–0.5s)", function()
        if not requireMacro() then return end
        Input.addWaitRandom(currentMacro_, 0.1, 0.5)
        print("[UI] Added RANDOM WAIT 0.1–0.5s")
    end)

    secMacro:NewButton("+ Add RELEASE ALL", function()
        if not requireMacro() then return end
        Input.addReleaseAll(currentMacro_, 0)
        print("[UI] Added RELEASE ALL")
    end)

    local macroTextBox = secMacro:NewTextBox("Text to Type", function(_) end)
    macroTextBox:Update("hello")

    secMacro:NewButton("+ Add TYPE (normal)", function()
        if not requireMacro() then return end
        Input.addText(currentMacro_, "hello", 0.05, false, 0)
        print("[UI] Added TYPE: hello")
    end)

    secMacro:NewButton("+ Add TYPE HUMAN (60wpm)", function()
        if not requireMacro() then return end
        Input.addTextHuman(currentMacro_, "hello", 60, 0)
        print("[UI] Added TYPE HUMAN: hello  @ 60wpm")
    end)

    secMacro:NewButton("+ Add PRINT step marker", function()
        if not requireMacro() then return end
        local idx = #currentMacro_.actions + 1
        Input.addPrint(currentMacro_, "step " .. idx)
        print("[UI] Added PRINT marker at step " .. idx)
    end)

    secMacro:NewButton("Clear All Actions", function()
        if not requireMacro() then return end
        Input.clearMacro(currentMacro_)
        print("[UI] Cleared all actions from: " .. currentMacro_.name)
    end)

    secMacro:Seperator()

    -- ── Macro run controls ───────────────────────────────────────────────────
    local macroLoopSlider  = secMacro:NewSlider("Run Loops  1–100", 1, 100, function(_) end)
    local macroSpeedSlider = secMacro:NewSlider("Run Speed % 10–300", 10, 300, function(_) end)

    local macroEnabledToggle = secMacro:NewToggle("Macro Enabled", function(state)
        if currentMacro_ then currentMacro_.enabled = state end
    end)

    secMacro:NewButton("▶  RUN Macro (async)", function()
        if not requireMacro() then return end
        Input.runMacroAsync(currentMacro_)
        print("[UI] Running macro: " .. currentMacro_.name)
    end)

    secMacro:NewButton("⏹  RELEASE ALL KEYS", function()
        Input.releaseAll()
        print("[UI] All keys released.")
    end)

    secMacro:NewButton("Copy Macro (appends _copy)", function()
        if not requireMacro() then return end
        local copy = Input.copyMacro(currentMacro_)
        print("[UI] Copied to: " .. copy.name)
    end)

    secMacro:NewButton("Reverse Macro (appends _rev)", function()
        if not requireMacro() then return end
        local rev = Input.reverseMacro(currentMacro_)
        print("[UI] Reversed as: " .. rev.name)
    end)

    secMacro:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 4 ── KEYBOARD
    -- ════════════════════════════════════════════════════════════════════════
    local secKB = Forums:NewSection("⌨  Keyboard")

    local kbKeyBox = secKB:NewTextBox("Key Name (e.g. e, Space, F5, LCtrl)", function(_) end)
    kbKeyBox:Update("e")

    local kbHoldSlider = secKB:NewSlider("Hold Duration (ms)", 10, 3000, function(_) end)

    secKB:NewButton("TAP Key", function()
        task.spawn(Input.tap, "e", 0.05)
        print("[UI] Tapped: e")
    end)

    secKB:NewButton("KEY DOWN", function()
        Input.keyDown("e")
        print("[UI] Key Down: e")
    end)

    secKB:NewButton("KEY UP", function()
        Input.keyUp("e")
        print("[UI] Key Up: e")
    end)

    secKB:NewButton("HOLD Key (1s)", function()
        task.spawn(Input.holdKey, "e", 1)
        print("[UI] Holding e for 1s")
    end)

    secKB:NewButton("RELEASE ALL Keys", function()
        Input.releaseAll()
        print("[UI] Released all keys")
    end)

    secKB:Seperator()

    -- ── Spam ─────────────────────────────────────────────────────────────────
    local spamTimesSlider    = secKB:NewSlider("Spam Times  1–500", 1, 500, function(_) end)
    local spamIntervalSlider = secKB:NewSlider("Spam Interval (ms) 10–1000", 10, 1000, function(_) end)

    secKB:NewButton("SPAM Key (n times)", function()
        task.spawn(Input.spam, "e", 10, 0.1)
        print("[UI] Spamming e x10")
    end)

    local spamContToggle = secKB:NewToggle("Continuous Spam (toggle)", function(state)
        if state then
            spamLoopStop_ = Input.loop(0.1, function() Input.tap("e", 0.03) end)
            print("[UI] Continuous spam ON")
        else
            if spamLoopStop_ then spamLoopStop_() spamLoopStop_=nil end
            print("[UI] Continuous spam OFF")
        end
    end)

    secKB:Seperator()

    -- ── Type ─────────────────────────────────────────────────────────────────
    local typeTextBox = secKB:NewTextBox("Text to Type", function(_) end)
    typeTextBox:Update("hello world")

    local typeWpmSlider = secKB:NewSlider("WPM (human typing)", 10, 300, function(_) end)

    secKB:NewButton("TYPE Text (normal speed)", function()
        task.spawn(Input.typeText, "hello world", 0.04, false)
        print("[UI] Typing: hello world")
    end)

    secKB:NewButton("TYPE Text (human / WPM)", function()
        task.spawn(Input.typeHuman, "hello world", 80)
        print("[UI] Typing human: hello world @ 80wpm")
    end)

    secKB:Seperator()

    -- ── Combo ────────────────────────────────────────────────────────────────
    local comboBox = secKB:NewTextBox("Combo Keys (comma-separated)", function(_) end)
    comboBox:Update("LCtrl,c")

    secKB:NewButton("FIRE Combo", function()
        local keys = {}
        local raw = "LCtrl,c"
        for k in raw:gmatch("([^,]+)") do table.insert(keys, k:gsub("%s","")) end
        task.spawn(Input.combo, keys, nil, 0.05)
        print("[UI] Combo fired: " .. raw)
    end)

    secKB:Seperator()

    -- ── Sequence ─────────────────────────────────────────────────────────────
    secKB:NewButton("Example Sequence  (w,a,s,d)", function()
        local seq = {"w","a","s","d"}
        task.spawn(Input.tapMultiple, seq, 0.05, 0.1)
        print("[UI] Sequence: w a s d")
    end)

    secKB:NewButton("Print Held Keys", function()
        local held = Input.getHeldKeys()
        if #held == 0 then print("[UI] No keys held.") else print("[UI] Held: " .. table.concat(held,", ")) end
    end)

    secKB:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 5 ── MOUSE
    -- ════════════════════════════════════════════════════════════════════════
    local secMouse = Forums:NewSection("🖱  Mouse")

    -- Live mouse position display
    local mousePosToggle = secMouse:NewToggle("Live Position Display", function(state)
        if state then
            task.spawn(function()
                while mousePosToggle and state do
                    local x,y = Input.getMousePos()
                    mousePosToggle:Update(string.format("Live Pos: %d, %d", x, y))
                    task.wait(0.05)
                end
            end)
        else
            mousePosToggle:Update("Live Position Display")
        end
    end)

    secMouse:NewButton("Print Mouse Position", function()
        local x,y = Input.getMousePos()
        print(string.format("[UI] Mouse: %d, %d", x, y))
    end)

    secMouse:Seperator()

    -- ── Move ─────────────────────────────────────────────────────────────────
    local moveXBox = secMouse:NewTextBox("Target X", function(_) end)
    local moveYBox = secMouse:NewTextBox("Target Y", function(_) end)
    moveXBox:Update("500")
    moveYBox:Update("300")

    local moveDurSlider   = secMouse:NewSlider("Move Duration (ms)", 0, 2000, function(_) end)
    local moveEasingDrop  = secMouse:NewDropdown("Easing Style", {
        "linear","easeIn","easeOut","easeInOut","bounce","elastic","sine","cubic","back","expo","circ"
    }, function(_) end)

    secMouse:NewButton("MOVE Instant", function()
        Input.mouseMove(500, 300)
        print("[UI] Moved to 500,300")
    end)

    secMouse:NewButton("MOVE Smooth", function()
        task.spawn(Input.mouseMoveSmooth, 500, 300, 0.3, "easeInOut")
        print("[UI] Smooth move to 500,300")
    end)

    secMouse:NewButton("MOVE Natural (bezier)", function()
        task.spawn(Input.mouseMoveNatural, 500, 300, 0.4)
        print("[UI] Natural move to 500,300")
    end)

    secMouse:Seperator()

    -- ── Click ────────────────────────────────────────────────────────────────
    local clickHoldSlider = secMouse:NewSlider("Click Hold (ms)", 10, 1000, function(_) end)

    secMouse:NewButton("LEFT Click (at 500,300)", function()
        task.spawn(Input.click, 500, 300, Input.LEFT, 0.05)
        print("[UI] Left click at 500,300")
    end)

    secMouse:NewButton("RIGHT Click (at 500,300)", function()
        task.spawn(Input.rightClick, 500, 300, 0.05)
        print("[UI] Right click at 500,300")
    end)

    secMouse:NewButton("DOUBLE Click (at 500,300)", function()
        task.spawn(Input.doubleClick, 500, 300)
        print("[UI] Double click at 500,300")
    end)

    secMouse:NewButton("HUMAN Click (jittered, at 500,300)", function()
        task.spawn(Input.clickHuman, 500, 300, Input.LEFT, 0.05, 6)
        print("[UI] Human click at 500,300 ±6px")
    end)

    secMouse:NewButton("Click at SCREEN CENTER", function()
        local cx,cy = Input.getScreenCenter()
        task.spawn(Input.click, cx, cy)
        print(string.format("[UI] Clicked center: %d,%d", cx, cy))
    end)

    secMouse:NewButton("Click at CURRENT Mouse Pos", function()
        local x,y = Input.getMousePos()
        task.spawn(Input.click, x, y)
        print(string.format("[UI] Clicked current pos: %d,%d", x, y))
    end)

    secMouse:Seperator()

    -- ── Drag ─────────────────────────────────────────────────────────────────
    local dragX2Box = secMouse:NewTextBox("Drag To X", function(_) end)
    local dragY2Box = secMouse:NewTextBox("Drag To Y", function(_) end)
    dragX2Box:Update("800")
    dragY2Box:Update("400")

    local dragDurSlider = secMouse:NewSlider("Drag Duration (ms)", 50, 3000, function(_) end)

    secMouse:NewButton("DRAG (500,300) → (800,400)", function()
        task.spawn(Input.drag, 500, 300, 800, 400, Input.LEFT, 25, 0.4, "easeInOut")
        print("[UI] Dragging 500,300 → 800,400")
    end)

    secMouse:NewButton("SWIPE (500,300) → (800,400)", function()
        task.spawn(Input.swipe, 500, 300, 800, 400, 0.2)
        print("[UI] Swiping 500,300 → 800,400")
    end)

    secMouse:Seperator()

    -- ── Scroll ───────────────────────────────────────────────────────────────
    local scrollAmtSlider = secMouse:NewSlider("Scroll Amount -20 to 20", 1, 20, function(_) end)

    secMouse:NewButton("SCROLL Up (+3) at Cursor", function()
        Input.scrollHere(3)
        print("[UI] Scrolled +3 at cursor")
    end)

    secMouse:NewButton("SCROLL Down (-3) at Cursor", function()
        Input.scrollHere(-3)
        print("[UI] Scrolled -3 at cursor")
    end)

    secMouse:NewButton("SCROLL at (500,300) +5", function()
        Input.scroll(500, 300, 5)
        print("[UI] Scrolled +5 at 500,300")
    end)

    -- ── Mouse Trail ──────────────────────────────────────────────────────────
    secMouse:NewToggle("Track Mouse Trail", function(state)
        if state then Input.startMouseTracking() print("[UI] Mouse tracking ON")
        else local trail=Input.stopMouseTracking() print("[UI] Mouse tracking OFF — " .. #trail .. " points") end
    end)

    secMouse:NewButton("Print Mouse Speed", function()
        print(string.format("[UI] Mouse speed: %.1f px/s", Input.getMouseSpeed()))
    end)

    secMouse:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 6 ── HOTKEYS
    -- ════════════════════════════════════════════════════════════════════════
    local secHK = Forums:NewSection("🔑  Hotkeys")

    local hkKeyDropdown = secHK:NewDropdown("Key to Bind", {
        "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
        "Delete","Insert","Home","End","PageUp","PageDown",
        "RightBracket","LeftBracket","BackSlash",
    }, function(_) end)

    local hkActionDropdown = secHK:NewDropdown("Action", {
        "releaseAll",
        "toggleSpam",
        "runCurrentMacro",
        "printStats",
        "minimizeUI",
    }, function(_) end)

    local hkBoundKey = nil

    local bindHKBtn = secHK:NewButton("BIND Selected Hotkey", function()
        print("[UI] Hotkey bound (see dropdown selections for config)")
    end)

    secHK:NewButton("Bind F6 → Release All", function()
        Input.bindHotkey("F6", Input.releaseAll, "F6->releaseAll")
        print("[UI] Bound F6 → releaseAll")
    end)

    secHK:NewButton("Bind F7 → Toggle Spam (e)", function()
        Input.bindToggle("F7",
            function()
                spamLoopStop_ = Input.loop(0.1, function() Input.tap("e",0.03) end)
                print("[UI] Spam ON")
            end,
            function()
                if spamLoopStop_ then spamLoopStop_() spamLoopStop_=nil end
                print("[UI] Spam OFF")
            end,
            "F7->spamToggle"
        )
        print("[UI] Bound F7 → spam toggle")
    end)

    secHK:NewButton("Bind F8 → Run Current Macro", function()
        if not currentMacro_ then print("[UI] No macro loaded.") return end
        Input.bindMacroHotkey("F8", currentMacro_)
        print("[UI] Bound F8 → " .. currentMacro_.name)
    end)

    secHK:NewButton("List Hotkeys (console)", function()
        local list = Input.listHotkeys()
        if #list==0 then print("[UI] No hotkeys bound.") return end
        for _,h in ipairs(list) do print("  [HK] " .. h) end
    end)

    secHK:NewButton("UNBIND All Hotkeys", function()
        Input.unbindAll()
        print("[UI] All hotkeys unbound.")
    end)

    secHK:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 7 ── CAMERA & WORLD
    -- ════════════════════════════════════════════════════════════════════════
    local secCam = Forums:NewSection("📷  Camera & World")

    secCam:NewButton("Look At Origin (0,0,0)", function()
        Input.lookAt(Vector3.new(0,0,0))
        print("[UI] Camera looking at origin")
    end)

    secCam:NewButton("Restore Camera", function()
        Input.restoreCamera()
        print("[UI] Camera restored")
    end)

    secCam:NewButton("Get Screen Center", function()
        local cx,cy = Input.getScreenCenter()
        print(string.format("[UI] Screen center: %d, %d", cx, cy))
    end)

    secCam:NewButton("Get Screen Size", function()
        local w,h = Input.getScreenSize()
        print(string.format("[UI] Screen size: %d x %d", w, h))
    end)

    secCam:NewButton("List Parts On Screen", function()
        local parts = Input.getPartsOnScreen()
        print("[UI] Parts on screen: " .. #parts)
        for i,p in ipairs(parts) do
            if i>10 then print("  ... (and more)") break end
            print(string.format("  %s  dist=%.0f  sx=%d sy=%d", p.part.Name, p.dist, p.sx, p.sy))
        end
    end)

    secCam:NewButton("Click Nearest Part on Screen", function()
        local ok = Input.clickNearestOnScreen()
        print("[UI] Click nearest on screen: " .. tostring(ok))
    end)

    secCam:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 8 ── LOOPS & TIMING
    -- ════════════════════════════════════════════════════════════════════════
    local secLoop = Forums:NewSection("⏱  Loops & Timing")

    local loopStopFn = nil

    local loopIvSlider  = secLoop:NewSlider("Loop Interval (ms)", 50, 5000, function(_) end)
    local loopDurSlider = secLoop:NewSlider("Loop For Duration (s)", 1, 120, function(_) end)
    local loopNSlider   = secLoop:NewSlider("Repeat N Times", 1, 100, function(_) end)

    secLoop:NewButton("START Loop (tap e every interval)", function()
        if loopStopFn then print("[UI] Loop already running.") return end
        loopStopFn = Input.loop(0.5, function() Input.tap("e",0.03) end)
        print("[UI] Loop started (e every 0.5s)")
    end)

    secLoop:NewButton("STOP Loop", function()
        if loopStopFn then loopStopFn() loopStopFn=nil print("[UI] Loop stopped.") else print("[UI] No loop running.") end
    end)

    secLoop:NewButton("Loop FOR 5s (tap e)", function()
        local stop = Input.loopFor(5, 0.3, function() Input.tap("e",0.03) end)
        print("[UI] Looping for 5s...")
        task.delay(5, function() stop() print("[UI] 5s loop done.") end)
    end)

    secLoop:NewButton("Repeat 10x (tap e, 0.1s gap)", function()
        task.spawn(function()
            Input.repeatAction(10, 0.1, function(i)
                Input.tap("e",0.03)
                print("[UI] Repeat step " .. i)
            end)
            print("[UI] Repeat 10x done.")
        end)
    end)

    secLoop:NewButton("Alternate A/B (5x, tap e then f)", function()
        task.spawn(function()
            Input.alternate(
                function() Input.tap("e",0.03) end,
                function() Input.tap("f",0.03) end,
                5, 0.3, 0.3
            )
            print("[UI] Alternate done.")
        end)
    end)

    secLoop:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 9 ── PROFILES
    -- ════════════════════════════════════════════════════════════════════════
    local secProf = Forums:NewSection("💾  Profiles")

    local profNameBox = secProf:NewTextBox("Profile Name", function(_) end)
    profNameBox:Update("profile1")

    secProf:NewButton("Save Profile", function()
        Input.saveProfile("profile1")
        print("[UI] Profile saved: profile1")
    end)

    secProf:NewButton("Load Profile", function()
        local ok = Input.loadProfile("profile1")
        print("[UI] Load profile1: " .. tostring(ok))
    end)

    secProf:NewButton("List Profiles (console)", function()
        local list = Input.listProfiles()
        if #list==0 then print("[UI] No profiles saved.") return end
        for _,p in ipairs(list) do print("  • " .. p) end
    end)

    secProf:Seperator()

    -- ════════════════════════════════════════════════════════════════════════
    -- SECTION 10 ── HOOKS / EVENTS
    -- ════════════════════════════════════════════════════════════════════════
    local secHooks = Forums:NewSection("🔗  Hooks & Events")

    secHooks:NewButton("Add TAP Hook (prints key)", function()
        Input.addHook("afterTap", function(key)
            print("[HOOK] afterTap: " .. tostring(key))
        end)
        print("[UI] TAP hook added.")
    end)

    secHooks:NewButton("Add CLICK Hook (prints pos)", function()
        Input.addHook("afterClick", function(x,y,btn)
            print(string.format("[HOOK] afterClick: (%d,%d) btn=%d", x, y, btn))
        end)
        print("[UI] CLICK hook added.")
    end)

    secHooks:NewButton("Add MACRO Start/Stop Hook", function()
        if not currentMacro_ then print("[UI] No macro loaded.") return end
        Input.watchMacro(currentMacro_.name, function(event, name)
            print(string.format("[HOOK] macro %s: %s", name, event))
        end)
        print("[UI] Macro watcher added for: " .. currentMacro_.name)
    end)

    secHooks:NewButton("Clear All Hooks", function()
        Input.clearAllHooks()
        print("[UI] All hooks cleared.")
    end)

    secHooks:NewButton("On Next Key Press (once)", function()
        task.spawn(function()
            print("[UI] Waiting for any key press...")
            local key = Input.waitForAnyKey({"e","f","g","r","t","y","Space","Enter","Escape"}, 10)
            print("[UI] Key pressed: " .. tostring(key))
        end)
    end)

    secHooks:NewButton("On Next Mouse Click (once)", function()
        task.spawn(function()
            print("[UI] Waiting for left click...")
            local x,y = Input.waitForClick(Input.LEFT, 10)
            if x then print(string.format("[UI] Clicked at: %d, %d", x, y))
            else print("[UI] Timed out waiting for click.") end
        end)
    end)

    secHooks:Seperator()

    -- ════ PROFILES section (unchanged) already above — add File/AFK/Player below ════

    -- ════ FILE MANAGER SECTION ═══════════════════════════════════════════════
    local secFile = Forums:NewSection("💾  File Manager")
    local fsStr = FS_AVAILABLE and "Filesystem: Available ✓" or "Filesystem: Unavailable ✗  (no writefile)"
    secFile:NewToggle(fsStr, function() end)

    secFile:NewButton("List Macro Files (console)", function()
        local files=Input.listMacroFiles()
        if #files==0 then print("[UI] No macro files in InputModule/macros/")
        else print("[UI] Macro files ("..#files.."):") for _,n in ipairs(files) do print("  • "..n..".json") end end
    end)
    secFile:NewButton("Save ALL Macros to Disk ★", function()
        local n=Input.saveAllMacros()
        print("[UI] Saved "..n.." macro(s)."); Input.notify("Saved",n.." macros to disk",3)
    end)
    secFile:NewButton("Load ALL Macros from Disk ★", function()
        local n=Input.loadAllMacros()
        print("[UI] Loaded "..n.." macro(s).")
    end)
    secFile:NewButton("Save CURRENT Macro to Disk ★", function()
        if not currentMacro_ then print("[UI] No macro loaded.") return end
        Input.saveMacroToFile(currentMacro_)
    end)
    local loadNameBox=secFile:NewTextBox("Macro name to load from disk", function(name)
        if name and #name>0 then
            local m=Input.loadMacroFromFile(name)
            if m then currentMacro_=m; refreshMacroInfo() end
        end
    end); loadNameBox:Update("")
    secFile:NewButton("Export Current Macro → Clipboard (JSON) ★", function()
        if not currentMacro_ then print("[UI] No macro.") return end
        if not Input.exportMacroToClipboard(currentMacro_) then
            print("[UI] Clipboard unavailable. JSON printed to console:")
            print(macroToJson(currentMacro_))
        end
    end)
    local importBox=secFile:NewTextBox("Paste JSON here then lose focus to import", function(json)
        if json and #json>5 then
            local m=Input.importMacroFromJson(json)
            if m then currentMacro_=m; refreshMacroInfo(); print("[UI] Imported: "..m.name) end
        end
    end)
    secFile:NewButton("Delete Current Macro File from Disk", function()
        if not currentMacro_ then print("[UI] No macro.") return end
        Input.deleteMacroFile(currentMacro_.name)
        Input.notify("Deleted",currentMacro_.name.." file removed",3)
    end)
    secFile:NewButton("List Recording Files (console)", function()
        local files=Input.listRecordingFiles()
        print("[UI] Recordings ("..#files.."):")
        for _,n in ipairs(files) do print("  • "..n..".json") end
    end)
    secFile:NewButton("Save Logs to File ★", function()
        if Input.saveLogsToFile() then Input.notify("Logs","Saved to InputModule/logs/",3)
        else print("[UI] writefile unavailable.") end
    end)
    secFile:Seperator()

    -- ════ ANTI-AFK SECTION ════════════════════════════════════════════════
    local secAFK = Forums:NewSection("🛡  Anti-AFK")
    local afkTog = secAFK:NewToggle("Anti-AFK: OFF", function() end)
    secAFK:NewDropdown("AFK Mode", {"jump","nudge","chat"}, function() end)
    secAFK:NewSlider("Interval (seconds)  15-300", 15, 300, function() end)
    secAFK:NewButton("▶  Start Anti-AFK (jump, 60s)", function()
        if Input.isAntiAfkRunning() then print("[UI] Already running.") return end
        Input.startAntiAfk("jump",60)
        afkTog:Update("Anti-AFK: ON ✓  (jump, 60s)")
        Input.notify("Anti-AFK","Started – jump mode, 60s interval",4)
    end)
    secAFK:NewButton("■  Stop Anti-AFK", function()
        Input.stopAntiAfk()
        afkTog:Update("Anti-AFK: OFF")
        Input.notify("Anti-AFK","Stopped",3)
    end)
    secAFK:NewButton("Print AFK Saves Count", function()
        print("[UI] Anti-AFK saves: "..tostring(_stats.antiAfkSaves))
    end)
    secAFK:Seperator()

    -- ════ PLAYER UTILS SECTION ═══════════════════════════════════════════
    local secPl = Forums:NewSection("👤  Player Utils")
    secPl:NewButton("Print Character Info", function()
        local lp=Players.LocalPlayer; local h=Input.getHumanoid(); local r=Input.getRootPart()
        print("=== "..lp.Name.." ===")
        if h then print("  HP: "..h.Health.."/"..h.MaxHealth.."  Speed: "..h.WalkSpeed.."  Jump: "..h.JumpPower) end
        if r then print(string.format("  Pos: %.1f, %.1f, %.1f",r.Position.X,r.Position.Y,r.Position.Z)) end
        print("  Game: "..game.Name.." (PlaceId "..game.PlaceId..")")
    end)
    secPl:NewTextBox("Set Walk Speed (press enter/blur)", function(v)
        local n=tonumber(v); if n then Input.setWalkSpeed(n); print("[UI] WalkSpeed="..n) end
    end):Update("16")
    secPl:NewTextBox("Set Jump Power (press enter/blur)", function(v)
        local n=tonumber(v); if n then Input.setJumpPower(n); print("[UI] JumpPower="..n) end
    end):Update("50")
    secPl:NewButton("JUMP", function() Input.jump() end)
    secPl:NewButton("List Players (console)", function()
        print("[UI] Players: "..table.concat(Input.getPlayerList(),", "))
    end)
    secPl:NewButton("Distance to All Players", function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=Players.LocalPlayer and p.Character then
                local r2=p.Character:FindFirstChild("HumanoidRootPart")
                if r2 then print(string.format("  %s  %.1f studs",p.Name,Input.getDistanceTo(r2.Position))) end
            end
        end
    end)
    secPl:NewButton("Fire Nearest ClickDetector ★", function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ClickDetector") then
                pcall(fireclickdetector or function() end, obj, 0)
                print("[UI] Fired ClickDetector on "..obj.Parent.Name) return
            end
        end; print("[UI] No ClickDetectors found.")
    end)
    secPl:NewButton("Fire Nearest ProximityPrompt ★", function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                pcall(fireproximityprompt or function() end, obj)
                print("[UI] Fired ProximityPrompt on "..obj.Parent.Name) return
            end
        end; print("[UI] No ProximityPrompts found.")
    end)
    secPl:Seperator()

    -- ════ SCHEDULER SECTION ══════════════════════════════════════════════
    local secSched = Forums:NewSection("⏰  Macro Scheduler")
    secSched:NewSlider("Schedule Interval (s)  5-600", 5, 600, function() end)
    secSched:NewButton("Schedule Current Macro (30s) ★", function()
        if not currentMacro_ then print("[UI] No macro loaded.") return end
        local id=Input.scheduleMacro(currentMacro_,30,false)
        print("[UI] Scheduled '"..currentMacro_.name.."' every 30s  id="..id)
        Input.notify("Scheduled",currentMacro_.name.." every 30s",3)
    end)
    secSched:NewButton("List Scheduled Macros (console)", function()
        local list=Input.listScheduled()
        if #list==0 then print("[UI] None scheduled.") return end
        for _,s in ipairs(list) do print(string.format("  id=%s  %s  every=%ss",s.id,s.name,s.interval)) end
    end)
    secSched:NewButton("Stop All Scheduled Macros", function()
        local list=Input.listScheduled()
        for _,s in ipairs(list) do Input.unscheduleMacro(s.id) end
        print("[UI] Stopped "..#list.." scheduled macro(s).")
    end)
    secSched:Seperator()

    log("UI","Forums UI opened  |  executor="..execName.."  tier="..(Input.Executor.tier or "?").."  supported="..tostring(vimOK).."  fs="..tostring(FS_AVAILABLE))
    Input.notify("InputModule v"..Input.VERSION, execName.."  |  "..(vimOK and "Ready ✓" or "VIM missing ✗"), 5)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- INIT  (folder tree + auto-UI)
-- ─────────────────────────────────────────────────────────────────────────────
do
    -- silently create folder structure on load if FS available
    if FS_AVAILABLE then
        pcall(fsInitFolders)
    end
end

print(string.format(
    "[InputModule v%s] loaded  |  executor: %s [%s]  |  VIM: %s  |  FS: %s  |  auto-UI: %s",
    Input.VERSION,
    Input.Executor.name,
    Input.Executor.tier or "?",
    tostring(Input.Executor.supported),
    tostring(FS_AVAILABLE),
    tostring(Input.AUTO_UI)
))

-- Auto-open UI after a short yield so require() returns first
if Input.AUTO_UI then
    task.spawn(function()
        task.wait(0.5)
        local ok, err = pcall(Input.openUI)
        if not ok then
            warn("[InputModule] Auto-UI failed: "..tostring(err))
        end
    end)
end

return Input
