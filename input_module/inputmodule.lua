-- inputmodule.lua
-- v1.0.0
-- Comprehensive virtual input library for Roblox
-- Keyboard · Mouse · Macros · Recording · Hotkeys · Camera · World Interaction

local Input = {}

local VIM          = game:GetService("VirtualInputManager")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

Input.VERSION = "1.0.0"
Input.LEFT    = 0
Input.RIGHT   = 1
Input.MIDDLE  = 2

-- ─────────────────────────────────────────
-- INTERNAL STATE
-- ─────────────────────────────────────────

local heldKeys        = {}
local macroStore      = {}
local recording       = false
local recActions      = {}
local recStart        = 0
local recConns        = {}
local hotkeys         = {}
local hotkeyConn      = nil
local _stats          = { taps=0, clicks=0, scrolls=0, macrosRun=0, recordingsSaved=0, dragCount=0 }
local _logEnabled     = true
local _logHistory     = {}
local _mouseTrail     = {}
local _trackMouse     = false
local _activeMacros   = {}
local _macroIdCounter = 0
local _hooks          = {}
local _macroWatchers  = {}  -- callbacks that fire when a named macro runs

-- ─────────────────────────────────────────
-- LOGGING
-- ─────────────────────────────────────────

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

Input.setLogging   = function(enabled)  _logEnabled = enabled end
Input.getLogs      = function()         return _logHistory end
Input.clearLogs    = function()         _logHistory = {} end
Input.printLogs    = function(n)
	n = n or 20
	local h = _logHistory
	for i = math.max(1, #h - n + 1), #h do print(h[i].text) end
end
Input.getLogsSince = function(t)
	local r = {}
	for _, e in ipairs(_logHistory) do if e.time >= t then table.insert(r, e) end end
	return r
end
Input.exportLogs = function()
	local lines = {}
	for _, e in ipairs(_logHistory) do
		table.insert(lines, string.format("[%.2f] %s", e.time, e.text))
	end
	return table.concat(lines, "\n")
end

-- ─────────────────────────────────────────
-- EVENT HOOKS
-- ─────────────────────────────────────────

local function fireHook(name, ...)
	if _hooks[name] then
		for _, fn in ipairs(_hooks[name]) do
			local ok, err = pcall(fn, ...)
			if not ok then warn_("hook", name .. " error: " .. tostring(err)) end
		end
	end
end

Input.addHook = function(event, callback)
	if not _hooks[event] then _hooks[event] = {} end
	table.insert(_hooks[event], callback)
end

Input.removeHooks = function(event)
	_hooks[event] = {}
end

Input.clearAllHooks = function()
	_hooks = {}
end

-- ─────────────────────────────────────────
-- KEY MAP
-- ─────────────────────────────────────────

local KeyMap = {}

local function safeKC(name)
	local ok, v = pcall(function() return Enum.KeyCode[name] end)
	return (ok and v) or nil
end

local function reg(char, enumName)
	local kc = safeKC(enumName)
	if kc then KeyMap[char] = kc end
end

for i = 0, 9 do
	local names = {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
	reg(tostring(i), names[i+1])
end

local shifted    = {"!","@","#","$","%","^","&","*","(",")" }
local shiftEnums = {"One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Zero"}
for i, ch in ipairs(shifted) do reg(ch, shiftEnums[i]) end

for byte = string.byte("a"), string.byte("z") do
	local ch = string.char(byte)
	reg(ch, ch:upper())
	reg(ch:upper(), ch:upper())
end

local specials = {
	Space="Space", Enter="Return", Tab="Tab", Backspace="Backspace",
	Escape="Escape", Delete="Delete", Insert="Insert", Home="Home",
	End="End", PageUp="PageUp", PageDown="PageDown",
	Up="Up", Down="Down", Left="Left", Right="Right",
	CapsLock="CapsLock", NumLock="NumLock", ScrollLock="ScrollLock",
	Pause="Pause", Print="Print",
	LShift="LeftShift", RShift="RightShift",
	LCtrl="LeftControl", RCtrl="RightControl",
	LAlt="LeftAlt", RAlt="RightAlt",
	LMeta="LeftMeta", RMeta="RightMeta",
	["Num0"]="KeypadZero",  ["Num1"]="KeypadOne",   ["Num2"]="KeypadTwo",
	["Num3"]="KeypadThree", ["Num4"]="KeypadFour",  ["Num5"]="KeypadFive",
	["Num6"]="KeypadSix",   ["Num7"]="KeypadSeven", ["Num8"]="KeypadEight",
	["Num9"]="KeypadNine",  ["Num."]="KeypadPeriod",["Num+"]="KeypadPlus",
	["Num-"]="KeypadMinus", ["Num*"]="KeypadAsterisk",["Num/"]="KeypadSlash",
	["NumEnter"]="KeypadEnter",
}
for k, v in pairs(specials) do reg(k, v) end
for i = 1, 12 do reg("F"..i, "F"..i) end

local puncts = {
	{"-","Minus"},{"=","Equals"},{"[","LeftBracket"},{"]","RightBracket"},
	{"\\","BackSlash"},{";","Semicolon"},{"'","Quote"},{",","Comma"},
	{".","Period"},{"/","Slash"},{"`","Tilde"},
}
for _, p in ipairs(puncts) do reg(p[1], p[2]) end

local ShiftSet = {}
for _, v in ipairs({
	"!","@","#","$","%","^","&","*","(",")",
	"A","B","C","D","E","F","G","H","I","J","K","L","M",
	"N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"~","_","+","{","}","|",":","\"","<",">","?",
}) do ShiftSet[v] = true end

-- ─────────────────────────────────────────
-- SCREEN / CAMERA UTILS
-- ─────────────────────────────────────────

local function getCamera()   return workspace.CurrentCamera end
local function getViewport() return getCamera().ViewportSize end

Input.fromUDim2 = function(xScale, xOffset, yScale, yOffset)
	local vp = getViewport()
	return vp.X * xScale + (xOffset or 0), vp.Y * yScale + (yOffset or 0)
end

Input.fromUDim2Smart = function(xScale, xOffset, yScale, yOffset)
	local vp = getViewport()
	local x = xScale < 0 and (vp.X + vp.X * xScale + (xOffset or 0)) or (vp.X * xScale + (xOffset or 0))
	local y = yScale < 0 and (vp.Y + vp.Y * yScale + (yOffset or 0)) or (vp.Y * yScale + (yOffset or 0))
	return x, y
end

Input.fromUDim2Object = function(u)
	local vp = getViewport()
	return vp.X * u.X.Scale + u.X.Offset, vp.Y * u.Y.Scale + u.Y.Offset
end

Input.getScreenSize   = function() local vp = getViewport() return vp.X, vp.Y end
Input.getScreenCenter = function() local vp = getViewport() return math.floor(vp.X/2), math.floor(vp.Y/2) end
Input.screenFraction  = function(fx, fy) local vp = getViewport() return math.floor(vp.X*fx), math.floor(vp.Y*fy) end

local function worldToScreen(pos)
	local sp, on = getCamera():WorldToScreenPoint(pos)
	return Vector2.new(sp.X, sp.Y), on
end

Input.isOnScreen       = function(cf) local _, on = worldToScreen(cf.Position) return on end
Input.getScreenPos     = function(cf)
	local sp, on = worldToScreen(cf.Position)
	if on then return math.floor(sp.X), math.floor(sp.Y) end
	return nil, nil
end
Input.getPartScreenPos = function(part)
	if not part or not part:IsA("BasePart") then return nil, nil end
	return Input.getScreenPos(part.CFrame)
end
Input.waitUntilOnScreen = function(cf, timeout)
	local t = 0
	while not Input.isOnScreen(cf) do
		task.wait(0.1); t += 0.1
		if timeout and t >= timeout then return false end
	end
	return true
end
Input.screenDistance = function(cf)
	local cx, cy = Input.getScreenCenter()
	local x, y   = Input.getScreenPos(cf)
	if not x then return math.huge end
	return math.sqrt((x-cx)^2 + (y-cy)^2)
end
Input.getDepth = function(cf)
	return (getCamera().CFrame.Position - cf.Position).Magnitude
end
Input.isNearScreenCenter = function(cf, radius)
	return Input.screenDistance(cf) <= (radius or 50)
end

-- ─────────────────────────────────────────
-- EASING
-- ─────────────────────────────────────────

local Easing = {
	linear    = function(t) return t end,
	easeIn    = function(t) return t*t end,
	easeOut   = function(t) return t*(2-t) end,
	easeInOut = function(t) return t<0.5 and 2*t*t or -1+(4-2*t)*t end,
	bounce    = function(t)
		if t < 1/2.75 then return 7.5625*t*t
		elseif t < 2/2.75 then t=t-1.5/2.75  return 7.5625*t*t+0.75
		elseif t < 2.5/2.75 then t=t-2.25/2.75 return 7.5625*t*t+0.9375
		else t=t-2.625/2.75 return 7.5625*t*t+0.984375 end
	end,
	elastic = function(t)
		if t==0 or t==1 then return t end
		return -math.pow(2,10*(t-1)) * math.sin((t-1.1)*5*math.pi)
	end,
	sine  = function(t) return 1-math.cos(t*math.pi/2) end,
	cubic = function(t) return t*t*t end,
	back  = function(t) local s=1.70158 return t*t*((s+1)*t-s) end,
	expo  = function(t) return t==0 and 0 or math.pow(2,10*(t-1)) end,
	circ  = function(t) return 1-math.sqrt(1-t*t) end,
}
Input.Easing = Easing

local function lerp(a, b, t) return a+(b-a)*t end
local function applyEasing(style, t) return (Easing[style] or Easing.linear)(t) end

-- ─────────────────────────────────────────
-- KEYBOARD
-- ─────────────────────────────────────────

Input.keyDown = function(key)
	local kc = KeyMap[key]
	if not kc then warn_("key","unknown key: "..tostring(key)) return false end
	fireHook("beforeKeyDown", key)
	if ShiftSet[key] then VIM:SendKeyEvent(true,Enum.KeyCode.LeftShift,false,game) end
	VIM:SendKeyEvent(true,kc,false,game)
	heldKeys[key] = true
	fireHook("afterKeyDown", key)
	return true
end

Input.keyUp = function(key)
	local kc = KeyMap[key]
	if not kc then warn_("key","unknown key: "..tostring(key)) return false end
	fireHook("beforeKeyUp", key)
	VIM:SendKeyEvent(false,kc,false,game)
	if ShiftSet[key] then VIM:SendKeyEvent(false,Enum.KeyCode.LeftShift,false,game) end
	heldKeys[key] = nil
	fireHook("afterKeyUp", key)
	return true
end

Input.tap = function(key, holdTime)
	holdTime = holdTime or 0.05
	fireHook("beforeTap", key)
	if not Input.keyDown(key) then return false end
	task.wait(holdTime)
	Input.keyUp(key)
	_stats.taps += 1
	fireHook("afterTap", key)
	return true
end

Input.tapAsync         = function(key, holdTime)               task.spawn(Input.tap, key, holdTime) end
Input.tapMultiple      = function(keys, holdTime, interval)    interval=interval or 0.05 for i,k in ipairs(keys) do Input.tap(k,holdTime) if i<#keys then task.wait(interval) end end end
Input.tapMultipleAsync = function(keys, holdTime, interval)    task.spawn(Input.tapMultiple,keys,holdTime,interval) end
Input.holdKey          = function(key, duration)               if not Input.keyDown(key) then return false end task.wait(duration) Input.keyUp(key) return true end
Input.holdKeyAsync     = function(key, duration)               task.spawn(Input.holdKey,key,duration) end
Input.holdKeys         = function(keys, duration)              for _,k in ipairs(keys) do Input.keyDown(k) end task.wait(duration) for i=#keys,1,-1 do Input.keyUp(keys[i]) end end
Input.holdKeysAsync    = function(keys, duration)              task.spawn(Input.holdKeys,keys,duration) end

Input.combo = function(keys, callback, releaseDelay)
	releaseDelay = releaseDelay or 0.05
	for _,k in ipairs(keys) do Input.keyDown(k) end
	if callback then callback() end
	task.wait(releaseDelay)
	for i=#keys,1,-1 do Input.keyUp(keys[i]) end
end
Input.comboAsync = function(keys,callback,releaseDelay) task.spawn(Input.combo,keys,callback,releaseDelay) end

Input.releaseAll = function()
	for key in pairs(heldKeys) do
		local kc = KeyMap[key]
		if kc then VIM:SendKeyEvent(false,kc,false,game) end
	end
	heldKeys = {}
	for _,kc in ipairs({
		Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift,
		Enum.KeyCode.LeftControl,Enum.KeyCode.RightControl,
		Enum.KeyCode.LeftAlt,Enum.KeyCode.RightAlt,
		Enum.KeyCode.Space,
	}) do VIM:SendKeyEvent(false,kc,false,game) end
end

Input.isKeyHeld      = function(key)  local kc=KeyMap[key] return kc and UIS:IsKeyDown(kc) or false end
Input.isAnyKeyHeld   = function(keys) for _,k in ipairs(keys) do if Input.isKeyHeld(k) then return true end end return false end
Input.areAllKeysHeld = function(keys) for _,k in ipairs(keys) do if not Input.isKeyHeld(k) then return false end end return true end
Input.getHeldKeys    = function()     local r={} for k in pairs(heldKeys) do table.insert(r,k) end return r end

Input.spam      = function(key,times,interval) interval=interval or 0.05 for i=1,times do Input.tap(key,0.03) if i<times then task.wait(interval) end end end
Input.spamAsync = function(key,times,interval) task.spawn(Input.spam,key,times,interval) end

Input.spamUntil = function(key,condFn,interval,maxSec)
	interval=interval or 0.1; maxSec=maxSec or 30
	local elapsed=0
	while not condFn() and elapsed<maxSec do
		Input.tap(key,0.03); task.wait(interval); elapsed+=interval
	end
end

Input.typeText = function(text, interval, randomize)
	interval=interval or 0.05; randomize=randomize or false
	for i=1,#text do
		local ch=text:sub(i,i)
		if KeyMap[ch] then Input.tap(ch,0.04)
		else warn_("type","no mapping for: "..ch) end
		local w = randomize and interval*(0.6+math.random()*0.8) or interval
		task.wait(w)
	end
end

Input.typeHuman = function(text, wpm)
	wpm=wpm or 60
	local base=60/(wpm*5)
	for i=1,#text do
		local ch=text:sub(i,i)
		if KeyMap[ch] then Input.tap(ch,0.03) end
		local j=base*(0.5+math.random()*1.0)
		if ch=="." or ch=="," or ch=="!" or ch=="?" then j=j*3 end
		task.wait(j)
	end
end
Input.typeHumanAsync = function(text,wpm) task.spawn(Input.typeHuman,text,wpm) end
Input.typeTextAsync  = function(text,interval,randomize) task.spawn(Input.typeText,text,interval,randomize) end

Input.sequence = function(keyList, interval)
	interval=interval or 0.1
	for _,entry in ipairs(keyList) do
		if type(entry)=="string" then Input.tap(entry,0.05)
		elseif type(entry)=="table" then
			if entry.wait  then task.wait(entry.wait)
			elseif entry.combo then Input.combo(entry.combo)
			elseif entry.key   then Input.tap(entry.key,entry.hold or 0.05)
			elseif entry.text  then Input.typeText(entry.text)
			elseif entry.fn    then pcall(entry.fn)
			end
		end
		task.wait(interval)
	end
end
Input.sequenceAsync = function(keyList,interval) task.spawn(Input.sequence,keyList,interval) end

-- wait for a key press
Input.waitForKey = function(key,timeout)
	local kc=KeyMap[key]; if not kc then return false end
	local done=false
	local conn=UIS.InputBegan:Connect(function(inp) if inp.KeyCode==kc then done=true end end)
	local elapsed=0
	while not done do
		task.wait(0.05); elapsed+=0.05
		if timeout and elapsed>=timeout then conn:Disconnect() return false end
	end
	conn:Disconnect(); return true
end

Input.waitForKeyRelease = function(key,timeout)
	local kc=KeyMap[key]; if not kc then return false end
	local done=false
	local conn=UIS.InputEnded:Connect(function(inp) if inp.KeyCode==kc then done=true end end)
	local elapsed=0
	while not done do
		task.wait(0.05); elapsed+=0.05
		if timeout and elapsed>=timeout then conn:Disconnect() return false end
	end
	conn:Disconnect(); return true
end

Input.waitForAnyKey = function(keys,timeout)
	local done,which=false,nil
	local conns={}
	for _,key in ipairs(keys) do
		local kc=KeyMap[key]
		if kc then
			table.insert(conns,UIS.InputBegan:Connect(function(inp)
				if inp.KeyCode==kc and not done then done=true which=key end
			end))
		end
	end
	local elapsed=0
	while not done do
		task.wait(0.05); elapsed+=0.05
		if timeout and elapsed>=timeout then break end
	end
	for _,c in ipairs(conns) do c:Disconnect() end
	return which
end

-- ─────────────────────────────────────────
-- MOUSE
-- ─────────────────────────────────────────

Input.mouseMove = function(x,y)
	VIM:SendMouseMoveEvent(x,y,game)
	if _trackMouse then
		table.insert(_mouseTrail,{x=x,y=y,t=tick()})
		if #_mouseTrail>500 then table.remove(_mouseTrail,1) end
	end
end

Input.mouseMoveSmooth = function(x2,y2,duration,easingStyle)
	duration=duration or 0.3; easingStyle=easingStyle or "linear"
	local cur=UIS:GetMouseLocation()
	local x1,y1=cur.X,cur.Y
	local steps=math.max(5,math.floor(duration/0.016))
	local dt=duration/steps
	for i=1,steps do
		local t=applyEasing(easingStyle,i/steps)
		Input.mouseMove(math.floor(lerp(x1,x2,t)),math.floor(lerp(y1,y2,t)))
		task.wait(dt)
	end
end
Input.mouseMoveAsync = function(x,y) task.spawn(Input.mouseMove,x,y) end

Input.mouseMoveNatural = function(x2,y2,duration)
	duration=duration or 0.3
	local cur=UIS:GetMouseLocation()
	local x1,y1=cur.X,cur.Y
	local cx=(x1+x2)/2+math.random(-80,80)
	local cy=(y1+y2)/2+math.random(-80,80)
	local steps=math.max(10,math.floor(duration/0.016))
	local dt=duration/steps
	for i=1,steps do
		local t=i/steps
		local et=applyEasing("easeInOut",t)
		local bx=(1-et)^2*x1+2*(1-et)*et*cx+et^2*x2
		local by=(1-et)^2*y1+2*(1-et)*et*cy+et^2*y2
		Input.mouseMove(math.floor(bx),math.floor(by))
		task.wait(dt)
	end
end
Input.mouseMoveNaturalAsync = function(x2,y2,duration) task.spawn(Input.mouseMoveNatural,x2,y2,duration) end

-- Move along a bezier with N control points
Input.mouseBezier = function(points, duration)
	duration=duration or 0.5
	local steps=math.max(10,math.floor(duration/0.016))
	local dt=duration/steps
	local function bezier(pts,t)
		if #pts==1 then return pts[1][1],pts[1][2] end
		local next={}
		for i=1,#pts-1 do
			table.insert(next,{lerp(pts[i][1],pts[i+1][1],t),lerp(pts[i][2],pts[i+1][2],t)})
		end
		return bezier(next,t)
	end
	for i=1,steps do
		local t=applyEasing("easeInOut",i/steps)
		local x,y=bezier(points,t)
		Input.mouseMove(math.floor(x),math.floor(y))
		task.wait(dt)
	end
end

Input.mouseDown = function(x,y,button) VIM:SendMouseButtonEvent(x,y,button or Input.LEFT,true,game,1) end
Input.mouseUp   = function(x,y,button) VIM:SendMouseButtonEvent(x,y,button or Input.LEFT,false,game,1) end

Input.click = function(x,y,button,holdTime)
	button=button or Input.LEFT; holdTime=holdTime or 0.05
	fireHook("beforeClick",x,y,button)
	Input.mouseMove(x,y); task.wait(0.02)
	Input.mouseDown(x,y,button); task.wait(holdTime)
	Input.mouseUp(x,y,button)
	_stats.clicks+=1
	fireHook("afterClick",x,y,button)
end
Input.clickAsync    = function(x,y,button,holdTime) task.spawn(Input.click,x,y,button,holdTime) end
Input.rightClick    = function(x,y,h) Input.click(x,y,Input.RIGHT,h) end
Input.middleClick   = function(x,y,h) Input.click(x,y,Input.MIDDLE,h) end
Input.doubleClick   = function(x,y,button,gap)
	gap=gap or 0.08
	Input.click(x,y,button,0.05); task.wait(gap); Input.click(x,y,button,0.05)
end
Input.tripleClick   = function(x,y,button,gap)
	gap=gap or 0.08
	for i=1,3 do Input.click(x,y,button,0.05) if i<3 then task.wait(gap) end end
end
Input.clickAndHold  = function(x,y,duration,button)
	button=button or Input.LEFT; duration=duration or 1
	Input.mouseMove(x,y); task.wait(0.02); Input.mouseDown(x,y,button)
	task.wait(duration); Input.mouseUp(x,y,button)
end
Input.clickUDim2    = function(xScale,xOffset,yScale,yOffset,button,holdTime)
	local x,y=Input.fromUDim2Smart(xScale,xOffset,yScale,yOffset)
	Input.click(x,y,button,holdTime)
end
Input.clickFromCenter = function(offsetX,offsetY,button,holdTime)
	local cx,cy=Input.getScreenCenter()
	Input.click(cx+(offsetX or 0),cy+(offsetY or 0),button,holdTime)
end
Input.clickRegion   = function(x1,y1,x2,y2,button,holdTime)
	Input.click(math.random(math.floor(x1),math.floor(x2)),math.random(math.floor(y1),math.floor(y2)),button,holdTime)
end
Input.clickHuman    = function(x,y,button,holdTime,spread)
	spread=spread or 4
	Input.click(x+math.random(-spread,spread),y+math.random(-spread,spread),button,holdTime)
end

-- Repeat click at same spot
Input.clickRepeat = function(x,y,times,interval,button,holdTime)
	interval=interval or 0.1
	for i=1,times do
		Input.click(x,y,button,holdTime)
		if i<times then task.wait(interval) end
	end
end

Input.drag = function(x1,y1,x2,y2,button,steps,duration,easingStyle)
	button=button or Input.LEFT; steps=steps or 25; duration=duration or 0.3; easingStyle=easingStyle or "linear"
	Input.mouseMove(x1,y1); task.wait(0.03)
	Input.mouseDown(x1,y1,button); task.wait(0.05)
	local dt=duration/steps
	for i=1,steps do
		local t=applyEasing(easingStyle,i/steps)
		Input.mouseMove(math.floor(lerp(x1,x2,t)),math.floor(lerp(y1,y2,t)))
		task.wait(dt)
	end
	Input.mouseUp(x2,y2,button)
	_stats.dragCount+=1
end
Input.dragAsync = function(...) local a={...} task.spawn(Input.drag,table.unpack(a)) end
Input.swipe     = function(x1,y1,x2,y2,duration) Input.drag(x1,y1,x2,y2,Input.LEFT,30,duration or 0.2,"easeOut") end

Input.scroll = function(x,y,amount,stepDelay)
	stepDelay=stepDelay or 0.02
	local up=amount>0
	for _=1,math.abs(amount) do VIM:SendMouseWheelEvent(x,y,up,game) task.wait(stepDelay) end
	_stats.scrolls+=1
end
Input.scrollHere   = function(amount,stepDelay) local p=UIS:GetMouseLocation() Input.scroll(p.X,p.Y,amount,stepDelay) end
Input.scrollSmooth = function(x,y,amount,duration)
	duration=duration or 0.5
	local steps=math.max(1,math.abs(amount))
	local delay=duration/steps; local up=amount>0
	for _=1,steps do VIM:SendMouseWheelEvent(x,y,up,game) task.wait(delay) end
end

Input.getMousePos = function() local p=UIS:GetMouseLocation() return p.X,p.Y end
Input.getMouseX   = function() return UIS:GetMouseLocation().X end
Input.getMouseY   = function() return UIS:GetMouseLocation().Y end

Input.waitForClick = function(button,timeout)
	local targetType=({[Input.LEFT]=Enum.UserInputType.MouseButton1,[Input.RIGHT]=Enum.UserInputType.MouseButton2,[Input.MIDDLE]=Enum.UserInputType.MouseButton3})[button or Input.LEFT] or Enum.UserInputType.MouseButton1
	local done,px,py=false,nil,nil
	local conn=UIS.InputBegan:Connect(function(inp)
		if inp.UserInputType==targetType then px,py=math.floor(inp.Position.X),math.floor(inp.Position.Y) done=true end
	end)
	local elapsed=0
	while not done do task.wait(0.05) elapsed+=0.05 if timeout and elapsed>=timeout then conn:Disconnect() return nil,nil end end
	conn:Disconnect(); return px,py
end

Input.startMouseTracking = function() _trackMouse=true _mouseTrail={} end
Input.stopMouseTracking  = function() _trackMouse=false return _mouseTrail end
Input.getMouseTrail      = function() return _mouseTrail end

-- Calculate average mouse speed from trail (pixels/second)
Input.getMouseSpeed = function()
	if #_mouseTrail < 2 then return 0 end
	local last  = _mouseTrail[#_mouseTrail]
	local first = _mouseTrail[1]
	local dist  = math.sqrt((last.x-first.x)^2+(last.y-first.y)^2)
	local dt    = math.max(0.001, last.t-first.t)
	return dist/dt
end

-- ─────────────────────────────────────────
-- WORLD / CFRAME INTERACTION
-- ─────────────────────────────────────────

local function clickAtScreenPos(sp,button,holdTime)
	Input.click(math.floor(sp.X),math.floor(sp.Y),button,holdTime)
end

Input.clickCFrame       = function(cf,button,holdTime)  local sp,on=worldToScreen(cf.Position) if not on then warn_("world","clickCFrame: off screen") return false end clickAtScreenPos(sp,button,holdTime) return true end
Input.clickCFrameAsync  = function(cf,button,holdTime)  task.spawn(Input.clickCFrame,cf,button,holdTime) end
Input.clickPart         = function(part,button,holdTime) if not part or not part:IsA("BasePart") then warn_("world","clickPart: not a BasePart") return false end return Input.clickCFrame(part.CFrame,button,holdTime) end
Input.clickPartAsync    = function(part,button,holdTime) task.spawn(Input.clickPart,part,button,holdTime) end
Input.clickPosition     = function(worldPos,button,holdTime) local sp,on=worldToScreen(worldPos) if not on then warn_("world","clickPosition: off screen") return false end clickAtScreenPos(sp,button,holdTime) return true end
Input.clickPositionAsync= function(worldPos,button,holdTime) task.spawn(Input.clickPosition,worldPos,button,holdTime) end
Input.clickModel        = function(model,button,holdTime) if not model or not model:IsA("Model") then return false end local cf=model:GetBoundingBox() return Input.clickCFrame(cf,button,holdTime) end
Input.clickWhenOnScreen = function(cf,button,holdTime,timeout) if not Input.waitUntilOnScreen(cf,timeout) then return false end return Input.clickCFrame(cf,button,holdTime) end
Input.hoverCFrame       = function(cf,duration)          local sp,on=worldToScreen(cf.Position) if not on then return false end Input.mouseMove(math.floor(sp.X),math.floor(sp.Y)) if duration then task.wait(duration) end return true end
Input.hoverPart         = function(part,duration)        if not part or not part:IsA("BasePart") then return false end return Input.hoverCFrame(part.CFrame,duration) end
Input.moveToCFrame      = function(cf,duration,easingStyle) local sp,on=worldToScreen(cf.Position) if not on then return false end Input.mouseMoveSmooth(math.floor(sp.X),math.floor(sp.Y),duration,easingStyle) return true end
Input.moveToPart        = function(part,duration,easingStyle) if not part or not part:IsA("BasePart") then return false end return Input.moveToCFrame(part.CFrame,duration,easingStyle) end

Input.dragBetweenParts = function(partA,partB,button,steps,duration)
	local spA,onA=worldToScreen(partA.CFrame.Position)
	local spB,onB=worldToScreen(partB.CFrame.Position)
	if not onA or not onB then warn_("world","dragBetweenParts: part(s) off screen") return false end
	Input.drag(math.floor(spA.X),math.floor(spA.Y),math.floor(spB.X),math.floor(spB.Y),button,steps,duration)
	return true
end

Input.clickNearestPart = function(tag,button,holdTime)
	local char=Players.LocalPlayer and Players.LocalPlayer.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not root then warn_("world","clickNearestPart: no character") return false end
	local best,bestDist=nil,math.huge
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (not tag or obj.Name==tag) then
			local d=(obj.Position-root.Position).Magnitude
			if d<bestDist then bestDist=d best=obj end
		end
	end
	if not best then warn_("world","clickNearestPart: none found") return false end
	return Input.clickPart(best,button,holdTime)
end

Input.clickNearestOnScreen = function(tag,button,holdTime)
	local vp=getViewport(); local cx,cy=vp.X/2,vp.Y/2
	local best,bestDist=nil,math.huge
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (not tag or obj.Name==tag) then
			local sp,on=worldToScreen(obj.Position)
			if on then
				local d=math.sqrt((sp.X-cx)^2+(sp.Y-cy)^2)
				if d<bestDist then bestDist=d best=obj end
			end
		end
	end
	if not best then warn_("world","clickNearestOnScreen: none found") return false end
	return Input.clickPart(best,button,holdTime)
end

-- Find all parts matching tag visible on screen, sorted closest to center
Input.getPartsOnScreen = function(tag)
	local vp=getViewport(); local cx,cy=vp.X/2,vp.Y/2
	local results={}
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (not tag or obj.Name==tag) then
			local sp,on=worldToScreen(obj.Position)
			if on then
				local d=math.sqrt((sp.X-cx)^2+(sp.Y-cy)^2)
				table.insert(results,{part=obj,dist=d,sx=math.floor(sp.X),sy=math.floor(sp.Y)})
			end
		end
	end
	table.sort(results,function(a,b) return a.dist<b.dist end)
	return results
end

-- ─────────────────────────────────────────
-- CAMERA CONTROL
-- ─────────────────────────────────────────

local _savedCamType=nil

Input.lookAt = function(worldPos)
	local cam=getCamera()
	_savedCamType=cam.CameraType
	cam.CameraType=Enum.CameraType.Scriptable
	cam.CFrame=CFrame.new(cam.CFrame.Position,worldPos)
end

Input.lookAtSmooth = function(worldPos,duration,easingStyle)
	duration=duration or 0.3; easingStyle=easingStyle or "easeInOut"
	local cam=getCamera()
	_savedCamType=cam.CameraType
	cam.CameraType=Enum.CameraType.Scriptable
	local startCF=cam.CFrame
	local targetCF=CFrame.new(cam.CFrame.Position,worldPos)
	local steps=math.max(5,math.floor(duration/0.016))
	local dt=duration/steps
	for i=1,steps do
		local t=applyEasing(easingStyle,i/steps)
		cam.CFrame=startCF:Lerp(targetCF,t)
		task.wait(dt)
	end
end

Input.restoreCamera = function()
	getCamera().CameraType=_savedCamType or Enum.CameraType.Custom
end

Input.lookAndClick = function(worldPos,button,holdTime,timeout)
	Input.lookAt(worldPos); task.wait(0.2)
	local cf=CFrame.new(worldPos)
	if not Input.waitUntilOnScreen(cf,timeout or 5) then
		warn_("cam","lookAndClick: target never on screen")
		Input.restoreCamera(); return false
	end
	task.wait(0.05)
	local result=Input.clickCFrame(cf,button,holdTime)
	Input.restoreCamera(); return result
end

-- Orbit camera around a point
Input.orbitCamera = function(target, radius, duration, revolutions)
	revolutions=revolutions or 1; duration=duration or 3
	local cam=getCamera()
	_savedCamType=cam.CameraType
	cam.CameraType=Enum.CameraType.Scriptable
	local steps=math.max(20,math.floor(duration/0.016))
	local dt=duration/steps
	for i=1,steps do
		local angle=(i/steps)*revolutions*2*math.pi
		local x=target.X+math.cos(angle)*radius
		local z=target.Z+math.sin(angle)*radius
		cam.CFrame=CFrame.new(Vector3.new(x,target.Y+radius*0.5,z),target)
		task.wait(dt)
	end
end

-- ─────────────────────────────────────────
-- MACROS
-- ─────────────────────────────────────────

Input.newMacro = function(name)
	local m = {
		name    = name or ("macro_"..tostring(tick())),
		actions = {},
		speed   = 1.0,
		loops   = 1,
		enabled = true,
		tags    = {},
		meta    = {},   -- free-form user data
	}
	if name then macroStore[name]=m end
	return m
end

-- Action builders
Input.addKey        = function(m,key,holdTime,delay)           table.insert(m.actions,{type="tap",key=key,holdTime=holdTime or 0.05,delay=delay or 0}) end
Input.addKeyDown    = function(m,key,delay)                    table.insert(m.actions,{type="keydown",key=key,delay=delay or 0}) end
Input.addKeyUp      = function(m,key,delay)                    table.insert(m.actions,{type="keyup",key=key,delay=delay or 0}) end
Input.addWait       = function(m,dur)                          table.insert(m.actions,{type="wait",duration=dur}) end
Input.addWaitRandom = function(m,minDur,maxDur)                table.insert(m.actions,{type="waitrandom",minDur=minDur,maxDur=maxDur}) end
Input.addReleaseAll = function(m,delay)                        table.insert(m.actions,{type="releaseall",delay=delay or 0}) end
Input.addLabel      = function(m,label)                        table.insert(m.actions,{type="label",label=label}) end
Input.addGoto       = function(m,label,times)                  table.insert(m.actions,{type="goto",label=label,times=times or 1,_count=0}) end

Input.addClick       = function(m,x,y,button,holdTime,delay)   table.insert(m.actions,{type="click",x=x,y=y,button=button or Input.LEFT,holdTime=holdTime or 0.05,delay=delay or 0}) end
Input.addRightClick  = function(m,x,y,holdTime,delay)          Input.addClick(m,x,y,Input.RIGHT,holdTime,delay) end
Input.addDoubleClick = function(m,x,y,delay)                   table.insert(m.actions,{type="doubleclick",x=x,y=y,delay=delay or 0}) end
Input.addTripleClick = function(m,x,y,delay)                   table.insert(m.actions,{type="tripleclick",x=x,y=y,delay=delay or 0}) end
Input.addMove        = function(m,x,y,delay)                   table.insert(m.actions,{type="move",x=x,y=y,delay=delay or 0}) end
Input.addScroll      = function(m,x,y,amount,delay)            table.insert(m.actions,{type="scroll",x=x,y=y,amount=amount or 1,delay=delay or 0}) end
Input.addScrollHere  = function(m,amount,delay)                table.insert(m.actions,{type="scrollhere",amount=amount or 1,delay=delay or 0}) end
Input.addCombo       = function(m,keys,releaseDelay,delay)     table.insert(m.actions,{type="combo",keys=keys,releaseDelay=releaseDelay or 0.05,delay=delay or 0}) end
Input.addText        = function(m,text,interval,randomize,delay) table.insert(m.actions,{type="text",text=text,interval=interval or 0.05,randomize=randomize or false,delay=delay or 0}) end
Input.addTextHuman   = function(m,text,wpm,delay)              table.insert(m.actions,{type="texthuman",text=text,wpm=wpm or 60,delay=delay or 0}) end

Input.addSmoothMove  = function(m,x,y,duration,easing,delay)  table.insert(m.actions,{type="smoothmove",x=x,y=y,duration=duration or 0.3,easing=easing or "linear",delay=delay or 0}) end
Input.addNaturalMove = function(m,x,y,duration,delay)         table.insert(m.actions,{type="naturalmove",x=x,y=y,duration=duration or 0.3,delay=delay or 0}) end

Input.addDrag  = function(m,x1,y1,x2,y2,button,steps,duration,easing,delay) table.insert(m.actions,{type="drag",x1=x1,y1=y1,x2=x2,y2=y2,button=button or Input.LEFT,steps=steps or 25,duration=duration or 0.3,easing=easing or "linear",delay=delay or 0}) end
Input.addSwipe = function(m,x1,y1,x2,y2,duration,delay)      table.insert(m.actions,{type="swipe",x1=x1,y1=y1,x2=x2,y2=y2,duration=duration or 0.2,delay=delay or 0}) end
Input.addSpam  = function(m,key,times,interval,delay)         table.insert(m.actions,{type="spam",key=key,times=times or 5,interval=interval or 0.05,delay=delay or 0}) end

Input.addSequence    = function(m,keyList,interval,delay)     table.insert(m.actions,{type="sequence",keyList=keyList,interval=interval or 0.1,delay=delay or 0}) end
Input.addCFrameClick = function(m,cf,button,holdTime,delay)   table.insert(m.actions,{type="cfclick",cf=cf,button=button or Input.LEFT,holdTime=holdTime or 0.05,delay=delay or 0}) end
Input.addPartClick   = function(m,part,button,holdTime,delay) table.insert(m.actions,{type="partclick",part=part,button=button or Input.LEFT,holdTime=holdTime or 0.05,delay=delay or 0}) end
Input.addRepeat      = function(m,innerMacro,times)           table.insert(m.actions,{type="repeat",macro=innerMacro,times=times or 1}) end
Input.addCondition   = function(m,condFn,trueMacro,falseMacro) table.insert(m.actions,{type="condition",condFn=condFn,trueMacro=trueMacro,falseMacro=falseMacro}) end
Input.addCallback    = function(m,fn,delay)                   table.insert(m.actions,{type="callback",fn=fn,delay=delay or 0}) end
Input.addPrint       = function(m,msg)                        table.insert(m.actions,{type="callback",fn=function() print("[Macro] "..tostring(msg)) end,delay=0}) end
Input.addUDim2Click  = function(m,xScale,xOffset,yScale,yOffset,button,holdTime,delay) table.insert(m.actions,{type="udim2click",xScale=xScale,xOffset=xOffset or 0,yScale=yScale,yOffset=yOffset or 0,button=button or Input.LEFT,holdTime=holdTime or 0.05,delay=delay or 0}) end

-- Wait inside a macro until a condition is true (with optional timeout)
Input.addWaitFor = function(m,condFn,timeout,interval)
	table.insert(m.actions,{type="waitfor",condFn=condFn,timeout=timeout or 10,interval=interval or 0.05})
end

-- Notify a label (used externally to jump into macro mid-run—advanced)
Input.addBreakIf = function(m,condFn)
	table.insert(m.actions,{type="breakif",condFn=condFn})
end

Input.runMacro = function(macro, overrideLoops, overrideSpeed)
	if not macro.enabled then return end
	local loops = overrideLoops or macro.loops or 1
	local speed = overrideSpeed or macro.speed or 1.0
	_stats.macrosRun += 1
	fireHook("beforeMacro", macro.name)
	if _macroWatchers[macro.name] then
		for _,fn in ipairs(_macroWatchers[macro.name]) do pcall(fn,"start",macro.name) end
	end

	local labels={}
	for i,a in ipairs(macro.actions) do if a.type=="label" then labels[a.label]=i end end

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
			elseif a.type=="repeat"      then for _=1,a.times do if _break then break end run(a.macro.actions) end
			elseif a.type=="condition"   then
				if a.condFn() then if a.trueMacro  then run(a.trueMacro.actions)  end
				else               if a.falseMacro then run(a.falseMacro.actions) end end
			elseif a.type=="goto" then
				local target=labels[a.label]
				if target then
					a._count=(a._count or 0)+1
					if a._count<=a.times then i=target else a._count=0 end
				end
			end
			i+=1
		end
	end

	for l=1,loops do
		if _break then break end
		run(macro.actions)
	end

	fireHook("afterMacro",macro.name)
	if _macroWatchers[macro.name] then
		for _,fn in ipairs(_macroWatchers[macro.name]) do pcall(fn,"stop",macro.name) end
	end
end

Input.runMacroAsync = function(macro, overrideLoops, overrideSpeed)
	_macroIdCounter += 1
	local id=_macroIdCounter
	local thread=task.spawn(function()
		_activeMacros[id]=macro.name
		Input.runMacro(macro,overrideLoops,overrideSpeed)
		_activeMacros[id]=nil
	end)
	return id, thread
end

Input.stopMacroAsync = function(id)
	-- cancels by id (requires tracking thread; simplified here)
	_activeMacros[id]=nil
end

Input.getActiveMacros = function() return _activeMacros end

-- Macro watcher: fires callback(event, macroName) on start/stop
Input.watchMacro = function(name, callback)
	if not _macroWatchers[name] then _macroWatchers[name]={} end
	table.insert(_macroWatchers[name],callback)
end

Input.saveMacro   = function(name,m)    macroStore[name]=m m.name=name end
Input.loadMacro   = function(name)      return macroStore[name] end
Input.deleteMacro = function(name)      macroStore[name]=nil end
Input.clearMacro  = function(m)         m.actions={} end
Input.listMacros  = function()          local n={} for k in pairs(macroStore) do table.insert(n,k) end table.sort(n) return n end

Input.copyMacro = function(m,newName)
	local copy={name=newName or (m.name.."_copy"),actions={},speed=m.speed,loops=m.loops,enabled=m.enabled,tags={},meta={}}
	for _,a in ipairs(m.actions) do local c={} for k,v in pairs(a) do c[k]=v end table.insert(copy.actions,c) end
	if newName then macroStore[newName]=copy end
	return copy
end

Input.mergeMacros = function(mA,mB,newName)
	local merged=Input.copyMacro(mA,newName)
	for _,a in ipairs(mB.actions) do local c={} for k,v in pairs(a) do c[k]=v end table.insert(merged.actions,c) end
	return merged
end

Input.reverseMacro = function(m,newName)
	local rev=Input.copyMacro(m,newName)
	local n=#rev.actions
	for i=1,math.floor(n/2) do rev.actions[i],rev.actions[n-i+1]=rev.actions[n-i+1],rev.actions[i] end
	return rev
end

Input.debugMacro = function(m)
	print(string.format("[Macro:%s] %d actions | loops=%d speed=%.1f enabled=%s", m.name,#m.actions,m.loops,m.speed,tostring(m.enabled)))
	for i,a in ipairs(m.actions) do
		local extra=""
		if a.key then extra=" key="..tostring(a.key) end
		if a.x   then extra=extra.." x="..tostring(a.x).." y="..tostring(a.y) end
		print(string.format("  [%02d] %-14s%s",i,a.type,extra))
	end
end

Input.getMacroEstimatedTime = function(m)
	local total=0
	for _,a in ipairs(m.actions) do
		if a.delay then total+=a.delay end
		if a.type=="wait" then total+=a.duration
		elseif a.type=="tap" then total+=(a.holdTime or 0.05)+0.02
		elseif a.type=="click" then total+=(a.holdTime or 0.05)+0.04
		elseif a.type=="drag" then total+=(a.duration or 0.3)
		elseif a.type=="smoothmove" then total+=(a.duration or 0.3)
		elseif a.type=="text" then total+=#(a.text or "")*(a.interval or 0.05)
		end
	end
	return total*(m.loops or 1)/(m.speed or 1)
end

-- ─────────────────────────────────────────
-- RECORDING
-- ─────────────────────────────────────────

Input.startRecording = function(name)
	recActions={}; recStart=tick(); recording=true
	for _,c in ipairs(recConns) do c:Disconnect() end
	recConns={}

	table.insert(recConns,UIS.InputBegan:Connect(function(inp)
		if not recording then return end
		local t=tick()-recStart
		if inp.UserInputType==Enum.UserInputType.Keyboard then
			table.insert(recActions,{time=t,type="keyDown",key=tostring(inp.KeyCode)})
		elseif inp.UserInputType==Enum.UserInputType.MouseButton1 then
			table.insert(recActions,{time=t,type="mouseDown",x=math.floor(inp.Position.X),y=math.floor(inp.Position.Y),button=0})
		elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then
			table.insert(recActions,{time=t,type="mouseDown",x=math.floor(inp.Position.X),y=math.floor(inp.Position.Y),button=1})
		end
	end))

	table.insert(recConns,UIS.InputEnded:Connect(function(inp)
		if not recording then return end
		local t=tick()-recStart
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

	log("rec","recording started: "..(name or "unnamed"))
end

Input.stopRecording = function(saveName)
	recording=false
	for _,c in ipairs(recConns) do c:Disconnect() end
	recConns={}
	log("rec","stopped. "..#recActions.." actions captured")
	if saveName then
		macroStore[saveName]={name=saveName,recorded=true,actions=recActions,loops=1,speed=1.0,enabled=true,tags={},meta={}}
		_stats.recordingsSaved+=1
	end
	return recActions
end

Input.isRecording      = function() return recording end
Input.getLastRecording = function() return recActions end
Input.getRecordingTime = function() if recording then return tick()-recStart else return 0 end end
Input.getRecordingCount= function() return #recActions end

Input.playRecording = function(actions,speed,loops)
	speed=speed or 1.0; loops=loops or 1; actions=actions or recActions
	for _=1,loops do
		local startTime=tick(); local i=1
		while i<=#actions do
			local a=actions[i]
			if (tick()-startTime)*speed >= a.time then
				if a.type=="keyDown" or a.type=="keyUp" then
					local kname=tostring(a.key):match("KeyCode%.(.+)")
					if kname then local kc=safeKC(kname) if kc then VIM:SendKeyEvent(a.type=="keyDown",kc,false,game) end end
				elseif a.type=="mouseDown" then VIM:SendMouseButtonEvent(a.x,a.y,a.button,true,game,1)
				elseif a.type=="mouseUp"   then VIM:SendMouseButtonEvent(a.x,a.y,a.button,false,game,1)
				elseif a.type=="mouseMove" then VIM:SendMouseMoveEvent(a.x,a.y,game)
				end
				i+=1
			else
				task.wait(0.01)
			end
		end
	end
end
Input.playRecordingAsync = function(actions,speed,loops) task.spawn(Input.playRecording,actions,speed,loops) end

-- Trim silence from start/end of a recording
Input.trimRecording = function(actions, threshold)
	threshold=threshold or 0.5
	if #actions==0 then return actions end
	local first=actions[1].time
	local last=actions[#actions].time
	local trimmed={}
	for _,a in ipairs(actions) do
		if a.time>=first+threshold and a.time<=last-threshold then
			table.insert(trimmed,a)
		end
	end
	return trimmed
end

-- Scale timing of all recorded actions
Input.scaleRecording = function(actions, factor)
	local out={}
	for _,a in ipairs(actions) do
		local c={}; for k,v in pairs(a) do c[k]=v end
		c.time=c.time*factor
		table.insert(out,c)
	end
	return out
end

-- ─────────────────────────────────────────
-- HOTKEYS
-- ─────────────────────────────────────────

Input.bindHotkey = function(key,callback,label)
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

Input.bindHotkeyCombo = function(keys,callback)
	local sorted={}; for _,k in ipairs(keys) do table.insert(sorted,k) end table.sort(sorted)
	local comboKey="__COMBO__"..table.concat(sorted,"+")
	hotkeys[comboKey]={fn=callback,label=table.concat(sorted,"+"),isCombo=true,keys=keys}
	UIS.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.Keyboard then
			local allHeld=true
			for _,k in ipairs(keys) do if not Input.isKeyHeld(k) then allHeld=false break end end
			if allHeld then task.spawn(callback) end
		end
	end)
end

Input.bindToggle = function(key,startFn,stopFn,label)
	local active=false
	Input.bindHotkey(key,function()
		if active then active=false if stopFn then stopFn() end
		else active=true if startFn then startFn() end end
	end,label)
	return function() return active end  -- returns getter
end

Input.bindMacroHotkey = function(key,macro,label)
	Input.bindHotkey(key,function() Input.runMacroAsync(macro) end,label or macro.name)
end

Input.unbindHotkey = function(key) hotkeys[key]=nil end
Input.unbindAll    = function() hotkeys={} if hotkeyConn then hotkeyConn:Disconnect() hotkeyConn=nil end end

Input.listHotkeys = function()
	local list={}
	for k,v in pairs(hotkeys) do table.insert(list,k.." -> "..(v.label or "?")) end
	return list
end

-- ─────────────────────────────────────────
-- EVENT LISTENERS
-- ─────────────────────────────────────────

Input.onKey        = function(key,callback) local kc=KeyMap[key] if not kc then return nil end return UIS.InputBegan:Connect(function(inp) if inp.KeyCode==kc then task.spawn(callback) end end) end
Input.onKeyRelease = function(key,callback) local kc=KeyMap[key] if not kc then return nil end return UIS.InputEnded:Connect(function(inp) if inp.KeyCode==kc then task.spawn(callback) end end) end
Input.onMouseClick = function(button,callback)
	local t=({[Input.LEFT]=Enum.UserInputType.MouseButton1,[Input.RIGHT]=Enum.UserInputType.MouseButton2,[Input.MIDDLE]=Enum.UserInputType.MouseButton3})[button or Input.LEFT]
	return UIS.InputBegan:Connect(function(inp) if inp.UserInputType==t then task.spawn(function() callback(math.floor(inp.Position.X),math.floor(inp.Position.Y)) end) end end)
end
Input.onMouseMove  = function(callback)
	return UIS.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement then task.spawn(function() callback(math.floor(inp.Position.X),math.floor(inp.Position.Y)) end) end end)
end
Input.onScroll     = function(callback)
	return UIS.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseWheel then task.spawn(function() callback(inp.Position.Z>0 and 1 or -1) end) end end)
end

-- ─────────────────────────────────────────
-- LOOPING / TIMING UTILS
-- ─────────────────────────────────────────

Input.wait       = function(s)    task.wait(s) end
Input.waitRandom = function(mn,mx) task.wait(mn+math.random()*(mx-mn)) end
Input.waitFor    = function(condFn,timeout,interval)
	interval=interval or 0.05; local elapsed=0
	while not condFn() do
		task.wait(interval); elapsed+=interval
		if timeout and elapsed>=timeout then return false end
	end
	return true
end

Input.repeatAction = function(times,interval,callback)
	for i=1,times do callback(i) if i<times and interval>0 then task.wait(interval) end end
end
Input.repeatAsync = function(times,interval,callback) task.spawn(Input.repeatAction,times,interval,callback) end

Input.loop = function(interval,callback)
	local running=true
	local thread=task.spawn(function()
		while running do
			local ok,err=pcall(callback)
			if not ok then warn_("loop",tostring(err)) end
			task.wait(interval)
		end
	end)
	return function() running=false pcall(task.cancel,thread) end
end

Input.loopFor = function(duration,interval,callback)
	local stop=false; local endTime=tick()+duration
	local thread=task.spawn(function()
		while not stop and tick()<endTime do
			local ok,err=pcall(callback)
			if not ok then warn_("loopFor",tostring(err)) end
			task.wait(interval)
		end
	end)
	return function() stop=true pcall(task.cancel,thread) end
end

Input.loopTimes = function(times,interval,callback)
	return task.spawn(function()
		for i=1,times do
			local ok,err=pcall(callback,i)
			if not ok then warn_("loopTimes",tostring(err)) end
			if i<times then task.wait(interval) end
		end
	end)
end

Input.delay = function(seconds,callback)
	task.spawn(function() task.wait(seconds) callback() end)
end

-- Run two functions interleaved: alternates between funcA and funcB
Input.alternate = function(funcA, funcB, times, waitA, waitB)
	waitA=waitA or 0.5; waitB=waitB or 0.5
	for i=1,times do
		pcall(funcA); task.wait(waitA)
		pcall(funcB); task.wait(waitB)
	end
end

-- ─────────────────────────────────────────
-- STATS
-- ─────────────────────────────────────────

Input.getStats   = function() return {taps=_stats.taps,clicks=_stats.clicks,scrolls=_stats.scrolls,drags=_stats.dragCount,macrosRun=_stats.macrosRun,recordingsSaved=_stats.recordingsSaved} end
Input.resetStats = function() _stats={taps=0,clicks=0,scrolls=0,macrosRun=0,recordingsSaved=0,dragCount=0} end
Input.printStats = function()
	local s=Input.getStats()
	print(string.format("[Input] taps=%d  clicks=%d  scrolls=%d  drags=%d  macros=%d  recordings=%d",s.taps,s.clicks,s.scrolls,s.drags,s.macrosRun,s.recordingsSaved))
end

-- ─────────────────────────────────────────
-- KEY UTILS
-- ─────────────────────────────────────────

Input.listKeys   = function() local k={} for key in pairs(KeyMap) do table.insert(k,key) end table.sort(k) return k end
Input.hasKey     = function(key) return KeyMap[key]~=nil end
Input.getVersion = function() return Input.VERSION end

-- ─────────────────────────────────────────
-- PROFILE SYSTEM (save/load sets of settings)
-- ─────────────────────────────────────────

local _profiles={}

Input.saveProfile = function(name)
	_profiles[name]={
		macros  = {},
		hotkeys = {},
	}
	for k,m in pairs(macroStore) do _profiles[name].macros[k]=m end
	for k,h in pairs(hotkeys)    do _profiles[name].hotkeys[k]=h end
	log("profile","saved: "..name)
end

Input.loadProfile = function(name)
	if not _profiles[name] then warn_("profile","not found: "..name) return false end
	macroStore=_profiles[name].macros
	hotkeys   =_profiles[name].hotkeys
	log("profile","loaded: "..name)
	return true
end

Input.listProfiles = function()
	local p={}; for k in pairs(_profiles) do table.insert(p,k) end return p
end

-- ─────────────────────────────────────────

print(string.format("[InputModule v%s] loaded", Input.VERSION))

return Inputt
