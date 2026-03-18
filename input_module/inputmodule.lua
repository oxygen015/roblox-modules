-- inputmodule.lua
-- v1.1.0
-- Keyboard · Mouse · Macros · Recording · Hotkeys · Camera · World · Built-in UI

local Input = {}

local VIM          = game:GetService("VirtualInputManager")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")

Input.VERSION = "1.1.0"
Input.LEFT    = 0
Input.RIGHT   = 1
Input.MIDDLE  = 2

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
local _stats          = { taps=0, clicks=0, scrolls=0, macrosRun=0, recordingsSaved=0, dragCount=0 }
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
Input.exportLogs   = function()  local l={} for _,e in ipairs(_logHistory) do table.insert(l,string.format("[%.2f] %s",e.time,e.text)) end return table.concat(l,"\n") end

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

Input.addHook      = function(e,fn) if not _hooks[e] then _hooks[e]={} end table.insert(_hooks[e],fn) end
Input.removeHooks  = function(e)    _hooks[e]={} end
Input.clearAllHooks= function()     _hooks={} end

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

Input.tapAsync         =function(key,ht)          task.spawn(Input.tap,key,ht) end
Input.tapMultiple      =function(keys,ht,iv)       iv=iv or 0.05 for i,k in ipairs(keys) do Input.tap(k,ht) if i<#keys then task.wait(iv) end end end
Input.tapMultipleAsync =function(keys,ht,iv)       task.spawn(Input.tapMultiple,keys,ht,iv) end
Input.holdKey          =function(key,dur)          if not Input.keyDown(key) then return false end task.wait(dur) Input.keyUp(key) return true end
Input.holdKeyAsync     =function(key,dur)          task.spawn(Input.holdKey,key,dur) end
Input.holdKeys         =function(keys,dur)         for _,k in ipairs(keys) do Input.keyDown(k) end task.wait(dur) for i=#keys,1,-1 do Input.keyUp(keys[i]) end end
Input.holdKeysAsync    =function(keys,dur)         task.spawn(Input.holdKeys,keys,dur) end
Input.combo            =function(keys,cb,rd)       rd=rd or 0.05 for _,k in ipairs(keys) do Input.keyDown(k) end if cb then cb() end task.wait(rd) for i=#keys,1,-1 do Input.keyUp(keys[i]) end end
Input.comboAsync       =function(keys,cb,rd)       task.spawn(Input.combo,keys,cb,rd) end

Input.releaseAll=function()
	for key in pairs(heldKeys) do local kc=KeyMap[key] if kc then VIM:SendKeyEvent(false,kc,false,game) end end
	heldKeys={}
	for _,kc in ipairs({Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift,Enum.KeyCode.LeftControl,Enum.KeyCode.RightControl,Enum.KeyCode.LeftAlt,Enum.KeyCode.RightAlt,Enum.KeyCode.Space}) do VIM:SendKeyEvent(false,kc,false,game) end
end

Input.isKeyHeld      =function(key)  local kc=KeyMap[key] return kc and UIS:IsKeyDown(kc) or false end
Input.isAnyKeyHeld   =function(keys) for _,k in ipairs(keys) do if Input.isKeyHeld(k) then return true end end return false end
Input.areAllKeysHeld =function(keys) for _,k in ipairs(keys) do if not Input.isKeyHeld(k) then return false end end return true end
Input.getHeldKeys    =function()     local r={} for k in pairs(heldKeys) do table.insert(r,k) end return r end

Input.spam      =function(key,n,iv) iv=iv or 0.05 for i=1,n do Input.tap(key,0.03) if i<n then task.wait(iv) end end end
Input.spamAsync =function(key,n,iv) task.spawn(Input.spam,key,n,iv) end
Input.spamUntil =function(key,fn,iv,max) iv=iv or 0.1 max=max or 30 local e=0 while not fn() and e<max do Input.tap(key,0.03) task.wait(iv) e+=iv end end

Input.typeText     =function(text,iv,rand) iv=iv or 0.05 rand=rand or false for i=1,#text do local ch=text:sub(i,i) if KeyMap[ch] then Input.tap(ch,0.04) else warn_("type","no mapping: "..ch) end task.wait(rand and iv*(0.6+math.random()*0.8) or iv) end end
Input.typeTextAsync=function(text,iv,rand) task.spawn(Input.typeText,text,iv,rand) end
Input.typeHuman    =function(text,wpm)     wpm=wpm or 60 local base=60/(wpm*5) for i=1,#text do local ch=text:sub(i,i) if KeyMap[ch] then Input.tap(ch,0.03) end local j=base*(0.5+math.random()*1.0) if ch=="."or ch==","or ch=="!"or ch=="?" then j=j*3 end task.wait(j) end end
Input.typeHumanAsync=function(text,wpm)   task.spawn(Input.typeHuman,text,wpm) end

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
	local m={name=name or ("macro_"..tostring(tick())),actions={},speed=1.0,loops=1,enabled=true,tags={},meta={}}
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

Input.saveMacro   =function(name,m)    macroStore[name]=m m.name=name end
Input.loadMacro   =function(name)      return macroStore[name] end
Input.deleteMacro =function(name)      macroStore[name]=nil end
Input.clearMacro  =function(m)         m.actions={} end
Input.listMacros  =function()          local n={} for k in pairs(macroStore) do table.insert(n,k) end table.sort(n) return n end

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

Input.getStats  =function() return {taps=_stats.taps,clicks=_stats.clicks,scrolls=_stats.scrolls,drags=_stats.dragCount,macrosRun=_stats.macrosRun,recordingsSaved=_stats.recordingsSaved} end
Input.resetStats=function() _stats={taps=0,clicks=0,scrolls=0,macrosRun=0,recordingsSaved=0,dragCount=0} end
Input.printStats=function()
	local s=Input.getStats()
	print(string.format("[Input] taps=%d  clicks=%d  scrolls=%d  drags=%d  macros=%d  recordings=%d",s.taps,s.clicks,s.scrolls,s.drags,s.macrosRun,s.recordingsSaved))
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
-- BUILT-IN MACRO RECORDER UI
-- ─────────────────────────────────────────────────────────────────────────────

Input.openUI = function()

	-- destroy old UI if it exists
	local old = CoreGui:FindFirstChild("InputModuleUI")
	if old then old:Destroy() end

	-- ── CONSTANTS ────────────────────────────────────────────────────────────
	local C = {
		BG        = Color3.fromRGB(12, 12, 16),
		SURFACE   = Color3.fromRGB(20, 20, 28),
		PANEL     = Color3.fromRGB(26, 26, 36),
		BORDER    = Color3.fromRGB(45, 45, 65),
		ACCENT    = Color3.fromRGB(100, 80, 255),
		ACCENT2   = Color3.fromRGB(60, 200, 160),
		REC       = Color3.fromRGB(220, 50, 50),
		TEXT      = Color3.fromRGB(220, 220, 235),
		SUBTEXT   = Color3.fromRGB(120, 120, 145),
		MUTED     = Color3.fromRGB(60, 60, 80),
		WHITE     = Color3.fromRGB(255, 255, 255),
		GOOD      = Color3.fromRGB(80, 210, 120),
		WARN      = Color3.fromRGB(230, 180, 50),
	}

	local FONT_MONO  = Enum.Font.Code
	local FONT_UI    = Enum.Font.GothamMedium
	local FONT_BOLD  = Enum.Font.GothamBold
	local FONT_LIGHT = Enum.Font.Gotham

	-- ── TWEEN HELPERS ────────────────────────────────────────────────────────
	local function tw(obj, props, t, style, dir)
		return TweenService:Create(obj,
			TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
			props
		):Play()
	end
	local function twReturn(obj, props, t, style, dir)
		local tween = TweenService:Create(obj,
			TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
			props
		)
		tween:Play()
		return tween
	end

	-- ── BUILD HELPERS ─────────────────────────────────────────────────────────
	local function frame(parent, props)
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		for k,v in pairs(props or {}) do f[k]=v end
		f.Parent = parent
		return f
	end
	local function img(parent, props)
		local i = Instance.new("ImageLabel")
		i.BackgroundTransparency = 1
		i.BorderSizePixel = 0
		for k,v in pairs(props or {}) do i[k]=v end
		i.Parent = parent
		return i
	end
	local function label(parent, text, size, color, font, props)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.BorderSizePixel = 0
		l.Text = text or ""
		l.TextSize = size or 13
		l.TextColor3 = color or C.TEXT
		l.Font = font or FONT_UI
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Center
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Size = UDim2.new(1,0,0,20)
		for k,v in pairs(props or {}) do l[k]=v end
		l.Parent = parent
		return l
	end
	local function corner(parent, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r or 6)
		c.Parent = parent
		return c
	end
	local function stroke(parent, col, thickness)
		local s = Instance.new("UIStroke")
		s.Color = col or C.BORDER
		s.Thickness = thickness or 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = parent
		return s
	end
	local function padding(parent, t, r, b, l)
		local p = Instance.new("UIPadding")
		p.PaddingTop    = UDim.new(0, t or 6)
		p.PaddingRight  = UDim.new(0, r or 6)
		p.PaddingBottom = UDim.new(0, b or 6)
		p.PaddingLeft   = UDim.new(0, l or 6)
		p.Parent        = parent
		return p
	end
	local function listLayout(parent, dir, padding_)
		local u = Instance.new("UIListLayout")
		u.FillDirection = dir or Enum.FillDirection.Vertical
		u.Padding = UDim.new(0, padding_ or 4)
		u.SortOrder = Enum.SortOrder.LayoutOrder
		u.Parent = parent
		return u
	end

	-- ── ROOT ──────────────────────────────────────────────────────────────────
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InputModuleUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = CoreGui

	-- ── MAIN WINDOW ───────────────────────────────────────────────────────────
	local WIN_W, WIN_H = 520, 620
	local win = frame(screenGui, {
		Size = UDim2.new(0, WIN_W, 0, WIN_H),
		Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
		BackgroundColor3 = C.BG,
		ClipsDescendants = true,
	})
	corner(win, 10)
	stroke(win, C.BORDER, 1)

	-- drop shadow
	local shadow = img(screenGui, {
		Size = UDim2.new(0, WIN_W+40, 0, WIN_H+40),
		Position = UDim2.new(0.5, -(WIN_W+40)/2, 0.5, -(WIN_H+40)/2 + 8),
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.fromRGB(0,0,0),
		ImageTransparency = 0.55,
		ZIndex = 0,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49,49,450,450),
	})
	win.ZIndex = 1

	-- ── TITLE BAR ─────────────────────────────────────────────────────────────
	local titleBar = frame(win, {
		Size = UDim2.new(1,0,0,44),
		BackgroundColor3 = C.SURFACE,
	})
	stroke(titleBar, C.BORDER, 1)

	-- accent bar top
	local accentLine = frame(titleBar, {
		Size = UDim2.new(1,0,0,2),
		BackgroundColor3 = C.ACCENT,
	})

	-- title text
	local titleLabel = label(titleBar, "INPUT MODULE", 13, C.ACCENT, FONT_BOLD, {
		Position = UDim2.new(0,16,0,0),
		Size = UDim2.new(0,200,1,0),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local versionLabel = label(titleBar, "v1.1.0", 11, C.SUBTEXT, FONT_MONO, {
		Position = UDim2.new(0,16,0,0),
		Size = UDim2.new(0,200,1,0),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0,130,0,0),
	})

	-- close button
	local closeBtn = frame(titleBar, {
		Size = UDim2.new(0,28,0,28),
		Position = UDim2.new(1,-38,0.5,-14),
		BackgroundColor3 = C.MUTED,
	})
	corner(closeBtn, 6)
	label(closeBtn, "x", 14, C.SUBTEXT, FONT_BOLD, {
		Size = UDim2.new(1,0,1,0),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- minimize button
	local minBtn = frame(titleBar, {
		Size = UDim2.new(0,28,0,28),
		Position = UDim2.new(1,-72,0.5,-14),
		BackgroundColor3 = C.MUTED,
	})
	corner(minBtn, 6)
	label(minBtn, "_", 14, C.SUBTEXT, FONT_BOLD, {
		Size = UDim2.new(1,0,1,0),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- drag
	local dragging, dragStart, winStart = false, nil, nil
	titleBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = inp.Position
			winStart = win.Position
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = inp.Position - dragStart
			win.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset+delta.X, winStart.Y.Scale, winStart.Y.Offset+delta.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
	end)

	-- close / minimize
	local minimized = false
	local function hoverBtn(btn)
		btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3=C.BORDER}, 0.1) end)
		btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3=C.MUTED}, 0.1) end)
	end
	hoverBtn(closeBtn)
	hoverBtn(minBtn)

	closeBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then
			tw(win,{Size=UDim2.new(0,WIN_W,0,0),Position=UDim2.new(win.Position.X.Scale,win.Position.X.Offset,win.Position.Y.Scale,win.Position.Y.Offset+WIN_H/2)},0.2,Enum.EasingStyle.Quart)
			task.wait(0.22)
			screenGui:Destroy()
		end
	end)
	minBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then
			minimized = not minimized
			tw(win,{Size=UDim2.new(0,WIN_W,0,minimized and 44 or WIN_H)},0.25,Enum.EasingStyle.Quart)
		end
	end)

	-- ── TAB BAR ───────────────────────────────────────────────────────────────
	local tabBar = frame(win, {
		Size = UDim2.new(1,0,0,36),
		Position = UDim2.new(0,0,0,44),
		BackgroundColor3 = C.SURFACE,
	})
	stroke(tabBar, C.BORDER, 1)

	local tabNames = {"RECORDER", "MACROS", "KEYBOARD", "MOUSE"}
	local tabBtns = {}
	local tabIndicator = frame(tabBar, {
		Size = UDim2.new(0, WIN_W/#tabNames - 4, 0, 2),
		Position = UDim2.new(0, 2, 1, -2),
		BackgroundColor3 = C.ACCENT,
	})
	corner(tabIndicator, 2)

	for i, name in ipairs(tabNames) do
		local btn = frame(tabBar, {
			Size = UDim2.new(1/#tabNames, 0, 1, 0),
			Position = UDim2.new((i-1)/#tabNames, 0, 0, 0),
			BackgroundTransparency = 1,
		})
		local lbl = label(btn, name, 11, i==1 and C.TEXT or C.SUBTEXT, FONT_BOLD, {
			Size = UDim2.new(1,0,1,0),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 11,
		})
		btn.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 then
				for j,b in ipairs(tabBtns) do
					tw(b._lbl, {TextColor3 = j==i and C.TEXT or C.SUBTEXT}, 0.15)
				end
				local tabW = WIN_W/#tabNames
				tw(tabIndicator, {Position=UDim2.new(0,(i-1)*tabW+2,1,-2)}, 0.2, Enum.EasingStyle.Quart)
				-- show correct page
				for j, page in ipairs(tabBtns) do
					if page._page then page._page.Visible = (j==i) end
				end
			end
		end)
		btn._lbl = lbl
		btn.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseEnter then
				if lbl.TextColor3 ~= C.TEXT then tw(lbl,{TextColor3=Color3.fromRGB(180,180,200)},0.1) end
			end
		end)
		table.insert(tabBtns, btn)
	end

	-- ── CONTENT AREA ─────────────────────────────────────────────────────────
	local contentArea = frame(win, {
		Size = UDim2.new(1,0,1,-80),
		Position = UDim2.new(0,0,0,80),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	})

	local function makePage()
		local p = frame(contentArea, {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Visible = false,
		})
		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1,0,1,0)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 3
		scroll.ScrollBarImageColor3 = C.ACCENT
		scroll.CanvasSize = UDim2.new(0,0,0,0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.Parent = p
		padding(scroll, 10, 14, 10, 14)
		local layout = listLayout(scroll, Enum.FillDirection.Vertical, 6)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		return p, scroll
	end

	-- ── WIDGET FACTORIES ──────────────────────────────────────────────────────
	local function makeCard(parent, order)
		local card = frame(parent, {
			Size = UDim2.new(1,0,0,0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = C.PANEL,
			LayoutOrder = order or 0,
		})
		corner(card, 8)
		stroke(card, C.BORDER, 1)
		padding(card, 10, 12, 10, 12)
		listLayout(card, Enum.FillDirection.Vertical, 6)
		return card
	end

	local function sectionHeader(parent, text, order)
		local lbl = label(parent, text:upper(), 10, C.ACCENT, FONT_BOLD, {
			Size = UDim2.new(1,0,0,16),
			LayoutOrder = order or 0,
			TextSize = 10,
		})
		return lbl
	end

	local function makeButton(parent, text, callback, order, accent)
		local btn = frame(parent, {
			Size = UDim2.new(1,0,0,30),
			BackgroundColor3 = accent and C.ACCENT or C.SURFACE,
			LayoutOrder = order or 0,
		})
		corner(btn, 6)
		stroke(btn, accent and C.ACCENT or C.BORDER, 1)
		local lbl = label(btn, text, 12, accent and C.WHITE or C.TEXT, FONT_UI, {
			Size = UDim2.new(1,-12,1,0),
			Position = UDim2.new(0,12,0,0),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		btn.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 then
				tw(btn,{BackgroundColor3=accent and Color3.fromRGB(80,60,220) or C.MUTED},0.08)
				task.spawn(function()
					local ok,err=pcall(callback)
					if not ok then warn_("UI",tostring(err)) end
				end)
				task.delay(0.1,function() tw(btn,{BackgroundColor3=accent and C.ACCENT or C.SURFACE},0.1) end)
			end
		end)
		btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=accent and Color3.fromRGB(110,90,255) or C.MUTED},0.1) end)
		btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=accent and C.ACCENT or C.SURFACE},0.1) end)
		btn._label = lbl
		return btn
	end

	local function makeToggle(parent, text, default, callback, order)
		local row = frame(parent, {
			Size = UDim2.new(1,0,0,30),
			BackgroundColor3 = C.SURFACE,
			LayoutOrder = order or 0,
		})
		corner(row, 6)
		stroke(row, C.BORDER, 1)
		local lbl = label(row, text, 12, C.TEXT, FONT_UI, {
			Size = UDim2.new(1,-52,1,0),
			Position = UDim2.new(0,12,0,0),
		})
		local track = frame(row, {
			Size = UDim2.new(0,36,0,18),
			Position = UDim2.new(1,-46,0.5,-9),
			BackgroundColor3 = default and C.ACCENT or C.MUTED,
		})
		corner(track, 9)
		local knob = frame(track, {
			Size = UDim2.new(0,14,0,14),
			Position = UDim2.new(0, default and 19 or 3, 0.5,-7),
			BackgroundColor3 = C.WHITE,
		})
		corner(knob, 7)
		local state = default or false
		row.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 then
				state = not state
				tw(track,{BackgroundColor3=state and C.ACCENT or C.MUTED},0.15)
				tw(knob,{Position=UDim2.new(0,state and 19 or 3,0.5,-7)},0.15)
				if callback then pcall(callback,state) end
			end
		end)
		row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.MUTED},0.1) end)
		row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.SURFACE},0.1) end)
		local obj = {_lbl=lbl, _state=function() return state end}
		function obj:setText(t) lbl.Text=t end
		function obj:setState(s)
			state=s tw(track,{BackgroundColor3=s and C.ACCENT or C.MUTED},0.15)
			tw(knob,{Position=UDim2.new(0,s and 19 or 3,0.5,-7)},0.15)
		end
		return obj
	end

	local function makeInput(parent, placeholder, callback, order)
		local row = frame(parent, {
			Size = UDim2.new(1,0,0,30),
			BackgroundColor3 = C.SURFACE,
			LayoutOrder = order or 0,
		})
		corner(row, 6)
		stroke(row, C.BORDER, 1)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1,-24,1,0)
		box.Position = UDim2.new(0,12,0,0)
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 0
		box.PlaceholderText = placeholder or ""
		box.PlaceholderColor3 = C.SUBTEXT
		box.TextColor3 = C.TEXT
		box.Font = FONT_MONO
		box.TextSize = 12
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.ClearTextOnFocus = false
		box.Parent = row
		box.Focused:Connect(function() tw(row,{BackgroundColor3=C.PANEL},0.1) stroke(row,C.ACCENT,1) end)
		box.FocusLost:Connect(function()
			tw(row,{BackgroundColor3=C.SURFACE},0.1) stroke(row,C.BORDER,1)
			if callback then pcall(callback,box.Text) end
		end)
		local obj = {}
		function obj:getText() return box.Text end
		function obj:setText(t) box.Text=t end
		return obj
	end

	local function makeSlider(parent, text, min_, max_, default, callback, order)
		local card = frame(parent, {
			Size = UDim2.new(1,0,0,52),
			BackgroundColor3 = C.SURFACE,
			LayoutOrder = order or 0,
		})
		corner(card,6) stroke(card,C.BORDER,1)
		local topRow = frame(card, {Size=UDim2.new(1,-24,0,18),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1})
		local nameLbl = label(topRow, text, 12, C.TEXT, FONT_UI, {Size=UDim2.new(0.7,0,1,0)})
		local valLbl = label(topRow, tostring(default or min_), 12, C.ACCENT, FONT_MONO, {
			Size=UDim2.new(0.3,0,1,0),Position=UDim2.new(0.7,0,0,0),
			TextXAlignment=Enum.TextXAlignment.Right,
		})
		local track = frame(card, {
			Size=UDim2.new(1,-24,0,4),Position=UDim2.new(0,12,0,34),
			BackgroundColor3=C.MUTED,
		})
		corner(track,2)
		local fill = frame(track, {
			Size=UDim2.new((default or min_-min_)/(max_-min_),0,1,0),
			BackgroundColor3=C.ACCENT,
		})
		corner(fill,2)
		local thumb = frame(track, {
			Size=UDim2.new(0,12,0,12),
			Position=UDim2.new((default or min_-min_)/(max_-min_),0,0.5,-6),
			BackgroundColor3=C.WHITE,
		})
		corner(thumb,6)

		local value = default or min_
		local function setValue(v)
			v = math.clamp(math.floor(v),min_,max_)
			value = v
			local frac = (v-min_)/(max_-min_)
			tw(fill,{Size=UDim2.new(frac,0,1,0)},0.05)
			tw(thumb,{Position=UDim2.new(frac,0,0.5,-6)},0.05)
			valLbl.Text = tostring(v)
			if callback then pcall(callback,v) end
		end

		local sliding = false
		track.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true end
		end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
		end)
		UIS.InputChanged:Connect(function(inp)
			if sliding and inp.UserInputType==Enum.UserInputType.MouseMovement then
				local abs = track.AbsolutePosition
				local sz  = track.AbsoluteSize
				local frac = math.clamp((inp.Position.X - abs.X)/sz.X, 0, 1)
				setValue(min_ + math.floor(frac*(max_-min_)+0.5))
			end
		end)
		thumb.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true end
		end)

		local obj = {}
		function obj:get() return value end
		function obj:set(v) setValue(v) end
		return obj
	end

	local function makeSeparator(parent, order)
		local sep = frame(parent, {
			Size=UDim2.new(1,0,0,1),
			BackgroundColor3=C.BORDER,
			LayoutOrder=order or 0,
		})
		return sep
	end

	local function makeStatusBar(parent, order)
		local bar = frame(parent, {
			Size=UDim2.new(1,0,0,28),
			BackgroundColor3=C.SURFACE,
			LayoutOrder=order or 0,
		})
		corner(bar,6) stroke(bar,C.BORDER,1)
		local dot = frame(bar, {
			Size=UDim2.new(0,8,0,8),
			Position=UDim2.new(0,10,0.5,-4),
			BackgroundColor3=C.MUTED,
		})
		corner(dot,4)
		local lbl = label(bar, "Idle", 12, C.SUBTEXT, FONT_MONO, {
			Position=UDim2.new(0,26,0,0),
			Size=UDim2.new(1,-36,1,0),
		})
		local obj={}
		function obj:set(text, color)
			lbl.Text = text
			tw(dot,{BackgroundColor3=color or C.MUTED},0.15)
			tw(lbl,{TextColor3=color or C.SUBTEXT},0.15)
		end
		function obj:pulse(color)
			local c = color or C.ACCENT
			local function doPulse()
				tw(dot,{BackgroundColor3=c},0.1)
				task.delay(0.4,function() tw(dot,{BackgroundColor3=Color3.fromRGB(c.R*255*0.3,c.G*255*0.3,c.B*255*0.3)},0.3) end)
			end
			task.spawn(function()
				while recording do doPulse() task.wait(0.8) end
			end)
		end
		return obj, dot, lbl
	end

	local function makeActionRow(parent, actionData, index, deleteCallback, order)
		local row = frame(parent, {
			Size=UDim2.new(1,0,0,28),
			BackgroundColor3=C.PANEL,
			LayoutOrder=order or index,
		})
		corner(row,5) stroke(row,C.BORDER,1)

		-- index pill
		local pill = frame(row, {
			Size=UDim2.new(0,22,0,18),
			Position=UDim2.new(0,4,0.5,-9),
			BackgroundColor3=C.MUTED,
		})
		corner(pill,4)
		label(pill, tostring(index), 10, C.SUBTEXT, FONT_MONO, {
			Size=UDim2.new(1,0,1,0),
			TextXAlignment=Enum.TextXAlignment.Center,
		})

		-- type label
		local typeColors = {
			tap=C.ACCENT, keydown=C.ACCENT, keyup=C.SUBTEXT,
			click=C.ACCENT2, doubleclick=C.ACCENT2, scroll=C.ACCENT2,
			wait=C.WARN, waitrandom=C.WARN, releaseall=C.REC,
			text=C.GOOD, texthuman=C.GOOD, combo=C.ACCENT,
			drag=C.ACCENT2, swipe=C.ACCENT2, spam=C.WARN,
		}
		local typeCol = typeColors[actionData.type] or C.SUBTEXT
		local typeLbl = label(row, actionData.type:upper(), 10, typeCol, FONT_BOLD, {
			Position=UDim2.new(0,32,0,0),
			Size=UDim2.new(0,72,1,0),
			TextSize=10,
		})

		-- detail label
		local detail = ""
		if actionData.key  then detail = actionData.key end
		if actionData.text then detail = '"'..actionData.text:sub(1,20)..'"' end
		if actionData.x    then detail = string.format("(%d,%d)",actionData.x,actionData.y) end
		if actionData.duration then detail = string.format("%.2fs",actionData.duration) end
		if actionData.amount   then detail = (actionData.amount>0 and "+" or "")..tostring(actionData.amount) end
		if actionData.times    then detail = "x"..tostring(actionData.times) end
		label(row, detail, 11, C.SUBTEXT, FONT_MONO, {
			Position=UDim2.new(0,108,0,0),
			Size=UDim2.new(1,-136,1,0),
			TextSize=11,
		})

		-- delete btn
		if deleteCallback then
			local del = frame(row, {
				Size=UDim2.new(0,22,0,18),
				Position=UDim2.new(1,-26,0.5,-9),
				BackgroundColor3=Color3.fromRGB(80,20,20),
			})
			corner(del,4)
			label(del, "x", 11, Color3.fromRGB(200,80,80), FONT_BOLD, {
				Size=UDim2.new(1,0,1,0),
				TextXAlignment=Enum.TextXAlignment.Center,
			})
			del.InputBegan:Connect(function(inp)
				if inp.UserInputType==Enum.UserInputType.MouseButton1 then
					tw(row,{BackgroundColor3=Color3.fromRGB(60,10,10)},0.1)
					task.delay(0.1,function()
						row:Destroy()
						if deleteCallback then deleteCallback(index) end
					end)
				end
			end)
			del.MouseEnter:Connect(function() tw(del,{BackgroundColor3=Color3.fromRGB(120,30,30)},0.1) end)
			del.MouseLeave:Connect(function() tw(del,{BackgroundColor3=Color3.fromRGB(80,20,20)},0.1) end)
		end

		return row
	end

	-- ── PAGE 1: RECORDER ──────────────────────────────────────────────────────
	local page1, scroll1 = makePage()
	page1.Visible = true
	tabBtns[1]._page = page1

	-- live status
	local statusObj = makeStatusBar(scroll1, 1)

	-- rec time display
	local recCard = makeCard(scroll1, 2)
	local recTimeRow = frame(recCard, {Size=UDim2.new(1,0,0,40),BackgroundTransparency=1})
	listLayout(recTimeRow,Enum.FillDirection.Horizontal,8)
	local recTimeLbl = label(recTimeRow, "00:00.0", 28, C.TEXT, FONT_MONO, {
		Size=UDim2.new(0,120,1,0),
		TextSize=28,
		TextXAlignment=Enum.TextXAlignment.Left,
	})
	local recCountLbl = label(recTimeRow, "0 actions", 13, C.SUBTEXT, FONT_MONO, {
		Size=UDim2.new(1,0,1,0),
		TextSize=13,
		TextYAlignment=Enum.TextYAlignment.Bottom,
	})

	-- name input
	local nameInput = makeInput(scroll1, "recording name...", nil, 3)
	nameInput:setText("rec1")

	-- rec buttons row
	local recBtnCard = makeCard(scroll1, 4)
	local recBtnRow = frame(recBtnCard, {Size=UDim2.new(1,0,0,30),BackgroundTransparency=1})
	listLayout(recBtnRow,Enum.FillDirection.Horizontal,6)

	local recBtn = makeButton(recBtnRow, "RECORD", nil, 1, false)
	recBtn.Size = UDim2.new(0.33,-4,1,0)
	local stopBtn = makeButton(recBtnRow, "STOP", nil, 2, false)
	stopBtn.Size = UDim2.new(0.33,-4,1,0)
	local playBtn = makeButton(recBtnRow, "PLAY", nil, 3, true)
	playBtn.Size = UDim2.new(0.34,0,1,0)

	-- playback controls
	local pbCard = makeCard(scroll1, 5)
	sectionHeader(pbCard, "Playback", 1)
	local speedSlider = makeSlider(pbCard, "Speed %", 10, 300, 100, nil, 2)
	local loopSlider  = makeSlider(pbCard, "Loops", 1, 50, 1, nil, 3)

	-- action log header
	local logHeaderCard = makeCard(scroll1, 6)
	local logHeaderRow = frame(logHeaderCard,{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1})
	listLayout(logHeaderRow,Enum.FillDirection.Horizontal,0)
	sectionHeader(logHeaderRow, "Recorded Actions", 1)
	local logCountLbl = label(logHeaderRow, "", 10, C.SUBTEXT, FONT_MONO, {
		Size=UDim2.new(1,0,1,0),
		TextXAlignment=Enum.TextXAlignment.Right,
		TextSize=10,
	})
	local clearLogBtn = makeButton(logHeaderCard, "clear all", nil, 2, false)
	clearLogBtn.Size = UDim2.new(1,0,0,22)
	clearLogBtn._label.TextSize = 11

	-- scrollable action list container
	local actionListFrame = frame(scroll1, {
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,
		LayoutOrder=7,
	})
	listLayout(actionListFrame,Enum.FillDirection.Vertical,2)

	-- state
	local recTimerConn = nil
	local currentRecActions = {}

	local function refreshActionList()
		for _,c in ipairs(actionListFrame:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		local shown = {}
		for _,a in ipairs(currentRecActions) do
			if a.type ~= "mouseMove" then table.insert(shown,a) end
		end
		logCountLbl.Text = #shown.." shown / "..#currentRecActions.." total"
		for i,a in ipairs(shown) do
			makeActionRow(actionListFrame,a,i,nil,i)
		end
	end

	recBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		if recording then return end
		currentRecActions={}
		Input.startRecording(nameInput:getText())
		statusObj:set("Recording...", C.REC)
		statusObj:pulse(C.REC)
		tw(recBtn,{BackgroundColor3=Color3.fromRGB(60,10,10)},0.15)
		recBtn._label.Text="REC..."
		-- live timer update
		recTimerConn = RunService.Heartbeat:Connect(function()
			local t = Input.getRecordingTime()
			local mins = math.floor(t/60)
			local secs = t%60
			recTimeLbl.Text = string.format("%02d:%04.1f",mins,secs)
			recCountLbl.Text = Input.getRecordingCount().." actions"
		end)
	end)

	stopBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		if not recording then return end
		if recTimerConn then recTimerConn:Disconnect() recTimerConn=nil end
		currentRecActions = Input.stopRecording(nameInput:getText())
		statusObj:set("Stopped  —  "..#currentRecActions.." actions", C.GOOD)
		recTimeLbl.Text = "00:00.0"
		recCountLbl.Text = #currentRecActions.." saved"
		tw(recBtn,{BackgroundColor3=C.SURFACE},0.15)
		recBtn._label.Text="RECORD"
		refreshActionList()
	end)

	playBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		local actions = Input.getLastRecording()
		if #actions==0 then statusObj:set("No recording to play",C.WARN) return end
		local sp = speedSlider:get()/100
		local lp = loopSlider:get()
		statusObj:set("Playing x"..lp.."  @"..sp.."x", C.ACCENT)
		Input.playRecordingAsync(actions, sp, lp)
		task.delay(0.3, function() statusObj:set("Playing...", C.ACCENT2) end)
	end)

	clearLogBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		for _,c in ipairs(actionListFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		logCountLbl.Text = ""
		currentRecActions={}
	end)

	-- ── PAGE 2: MACROS ────────────────────────────────────────────────────────
	local page2, scroll2 = makePage()
	tabBtns[2]._page = page2

	local currentMacro_ = nil
	local function getCurrentMacro() return currentMacro_ end

	-- macro name + new/load
	local mgrCard = makeCard(scroll2,1)
	sectionHeader(mgrCard,"Macro Manager",1)
	local macroNameInput = makeInput(mgrCard,"macro name...",nil,2)
	macroNameInput:setText("MyMacro")

	local mgrRow = frame(mgrCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=3})
	listLayout(mgrRow,Enum.FillDirection.Horizontal,6)
	local newMBtn = makeButton(mgrRow,"NEW",nil,1,false)
	newMBtn.Size=UDim2.new(0.33,-4,1,0)
	local loadMBtn = makeButton(mgrRow,"LOAD",nil,2,false)
	loadMBtn.Size=UDim2.new(0.33,-4,1,0)
	local saveMBtn = makeButton(mgrRow,"SAVE",nil,3,false)
	saveMBtn.Size=UDim2.new(0.34,0,1,0)

	local macroInfoCard = makeCard(scroll2,2)
	sectionHeader(macroInfoCard,"Current Macro",1)
	local macroInfoLbl = label(macroInfoCard,"No macro loaded",12,C.SUBTEXT,FONT_MONO,{Size=UDim2.new(1,0,0,16),LayoutOrder=2})
	local macroActionListFrame = frame(macroInfoCard,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=3})
	listLayout(macroActionListFrame,Enum.FillDirection.Vertical,2)

	local function refreshMacroList()
		for _,c in ipairs(macroActionListFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		if not currentMacro_ then macroInfoLbl.Text="No macro loaded" return end
		macroInfoLbl.Text=string.format("%s  |  %d actions  |  loops %d  |  speed %.1fx",currentMacro_.name,#currentMacro_.actions,currentMacro_.loops,currentMacro_.speed)
		for i,a in ipairs(currentMacro_.actions) do
			makeActionRow(macroActionListFrame,a,i,function(idx)
				table.remove(currentMacro_.actions,idx)
				refreshMacroList()
			end,i)
		end
	end

	newMBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		local name=macroNameInput:getText()
		if name=="" then name="macro_"..tostring(math.floor(tick())) end
		currentMacro_=Input.newMacro(name)
		refreshMacroList()
	end)
	loadMBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		local m=Input.loadMacro(macroNameInput:getText())
		if m then currentMacro_=m refreshMacroList()
		else macroInfoLbl.Text="Not found: "..macroNameInput:getText() end
	end)
	saveMBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		if not currentMacro_ then return end
		Input.saveMacro(macroNameInput:getText(),currentMacro_)
		macroInfoLbl.Text="Saved: "..macroNameInput:getText()
	end)

	-- macro settings
	local mCfgCard = makeCard(scroll2,3)
	sectionHeader(mCfgCard,"Settings",1)
	local loopsSl = makeSlider(mCfgCard,"Loops",1,100,1,function(v) if currentMacro_ then currentMacro_.loops=v end end,2)
	local speedSl = makeSlider(mCfgCard,"Speed %",10,300,100,function(v) if currentMacro_ then currentMacro_.speed=v/100 end end,3)
	local enabledTog = makeToggle(mCfgCard,"Enabled",true,function(s) if currentMacro_ then currentMacro_.enabled=s end end,4)

	-- add action card
	local addCard = makeCard(scroll2,4)
	sectionHeader(addCard,"Add Action",1)
	local actionKeyInput = makeInput(addCard,"key name (e.g. e, Space, F5, LCtrl)",nil,2)
	actionKeyInput:setText("e")
	local holdSlider = makeSlider(addCard,"Hold (ms)",0,2000,50,nil,3)
	local delaySlider = makeSlider(addCard,"Pre-delay (ms)",0,3000,0,nil,4)

	local addRow1 = frame(addCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=5})
	listLayout(addRow1,Enum.FillDirection.Horizontal,4)
	local addTapBtn = makeButton(addRow1,"+ TAP",nil,1,false)
	addTapBtn.Size=UDim2.new(0.33,-3,1,0)
	local addKDBtn = makeButton(addRow1,"+ DOWN",nil,2,false)
	addKDBtn.Size=UDim2.new(0.33,-3,1,0)
	local addKUBtn = makeButton(addRow1,"+ UP",nil,3,false)
	addKUBtn.Size=UDim2.new(0.34,0,1,0)

	local addRow2 = frame(addCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=6})
	listLayout(addRow2,Enum.FillDirection.Horizontal,4)
	local addClickBtn = makeButton(addRow2,"+ CLICK",nil,1,false)
	addClickBtn.Size=UDim2.new(0.33,-3,1,0)
	local addRClickBtn = makeButton(addRow2,"+ RCLICK",nil,2,false)
	addRClickBtn.Size=UDim2.new(0.33,-3,1,0)
	local addScrollBtn = makeButton(addRow2,"+ SCROLL",nil,3,false)
	addScrollBtn.Size=UDim2.new(0.34,0,1,0)

	local addRow3 = frame(addCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=7})
	listLayout(addRow3,Enum.FillDirection.Horizontal,4)
	local addWaitBtn = makeButton(addRow3,"+ WAIT",nil,1,false)
	addWaitBtn.Size=UDim2.new(0.33,-3,1,0)
	local addRelBtn = makeButton(addRow3,"+ RELEASE",nil,2,false)
	addRelBtn.Size=UDim2.new(0.33,-3,1,0)
	local addCbBtn = makeButton(addRow3,"+ PRINT",nil,3,false)
	addCbBtn.Size=UDim2.new(0.34,0,1,0)

	local textInput_ = makeInput(addCard,"text to type...",nil,8)
	local addRow4 = frame(addCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=9})
	listLayout(addRow4,Enum.FillDirection.Horizontal,4)
	local addTextBtn = makeButton(addRow4,"+ TYPE",nil,1,false)
	addTextBtn.Size=UDim2.new(0.5,-2,1,0)
	local addHumanBtn = makeButton(addRow4,"+ TYPE HUMAN",nil,2,false)
	addHumanBtn.Size=UDim2.new(0.5,0,1,0)

	local function requireM()
		if not currentMacro_ then macroInfoLbl.Text="Create or load a macro first" return false end return true
	end

	addTapBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end Input.addKey(currentMacro_,actionKeyInput:getText(),holdSlider:get()/1000,delaySlider:get()/1000) refreshMacroList() end)
	addKDBtn.InputBegan:Connect(function(inp)  if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end Input.addKeyDown(currentMacro_,actionKeyInput:getText(),delaySlider:get()/1000) refreshMacroList() end)
	addKUBtn.InputBegan:Connect(function(inp)  if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end Input.addKeyUp(currentMacro_,actionKeyInput:getText(),delaySlider:get()/1000) refreshMacroList() end)
	addClickBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end local x,y=Input.getMousePos() Input.addClick(currentMacro_,x,y,Input.LEFT,holdSlider:get()/1000,delaySlider:get()/1000) refreshMacroList() end)
	addRClickBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end local x,y=Input.getMousePos() Input.addRightClick(currentMacro_,x,y,holdSlider:get()/1000,delaySlider:get()/1000) refreshMacroList() end)
	addScrollBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end Input.addScrollHere(currentMacro_,3,delaySlider:get()/1000) refreshMacroList() end)
	addWaitBtn.InputBegan:Connect(function(inp)  if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end Input.addWait(currentMacro_,math.max(0.05,holdSlider:get()/1000)) refreshMacroList() end)
	addRelBtn.InputBegan:Connect(function(inp)   if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end Input.addReleaseAll(currentMacro_,delaySlider:get()/1000) refreshMacroList() end)
	addCbBtn.InputBegan:Connect(function(inp)    if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end Input.addPrint(currentMacro_,"step "..#currentMacro_.actions+1) refreshMacroList() end)
	addTextBtn.InputBegan:Connect(function(inp)  if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end local t=textInput_:getText() if t=="" then return end Input.addText(currentMacro_,t,0.05,false,delaySlider:get()/1000) refreshMacroList() end)
	addHumanBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not requireM() then return end local t=textInput_:getText() if t=="" then return end Input.addTextHuman(currentMacro_,t,60,delaySlider:get()/1000) refreshMacroList() end)

	-- run / stop card
	local runCard = makeCard(scroll2,5)
	local runRow = frame(runCard,{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=1})
	listLayout(runRow,Enum.FillDirection.Horizontal,6)
	local runBtn = makeButton(runRow,"RUN",nil,1,true)
	runBtn.Size=UDim2.new(0.5,-3,1,0)
	local stopMBtn = makeButton(runRow,"STOP / RELEASE",nil,2,false)
	stopMBtn.Size=UDim2.new(0.5,0,1,0)
	local debugBtn = makeButton(runCard,"DEBUG  (print to console)",nil,2,false)

	runBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 or not currentMacro_ then return end
		Input.runMacroAsync(currentMacro_)
	end)
	stopMBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		Input.releaseAll()
	end)
	debugBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		if currentMacro_ then Input.debugMacro(currentMacro_) end
	end)

	-- ── PAGE 3: KEYBOARD ──────────────────────────────────────────────────────
	local page3, scroll3 = makePage()
	tabBtns[3]._page = page3

	local kbCard = makeCard(scroll3,1)
	sectionHeader(kbCard,"Key Controls",1)
	local kbKeyInput = makeInput(kbCard,"key name...",nil,2)
	kbKeyInput:setText("e")
	local kbHoldSl = makeSlider(kbCard,"Hold (ms)",10,3000,50,nil,3)

	local kbRow1 = frame(kbCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=4})
	listLayout(kbRow1,Enum.FillDirection.Horizontal,4)
	local tapKBtn  = makeButton(kbRow1,"TAP",nil,1,true)  tapKBtn.Size=UDim2.new(0.33,-3,1,0)
	local dnKBtn   = makeButton(kbRow1,"DOWN",nil,2,false) dnKBtn.Size=UDim2.new(0.33,-3,1,0)
	local upKBtn   = makeButton(kbRow1,"UP",nil,3,false)   upKBtn.Size=UDim2.new(0.34,0,1,0)

	local kbRow2 = frame(kbCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=5})
	listLayout(kbRow2,Enum.FillDirection.Horizontal,4)
	local holdKBtn = makeButton(kbRow2,"HOLD",nil,1,false) holdKBtn.Size=UDim2.new(0.5,-2,1,0)
	local relAllBtn= makeButton(kbRow2,"RELEASE ALL",nil,2,false) relAllBtn.Size=UDim2.new(0.5,0,1,0)

	tapKBtn.InputBegan:Connect(function(inp)  if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end task.spawn(Input.tap,kbKeyInput:getText(),kbHoldSl:get()/1000) end)
	dnKBtn.InputBegan:Connect(function(inp)   if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end Input.keyDown(kbKeyInput:getText()) end)
	upKBtn.InputBegan:Connect(function(inp)   if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end Input.keyUp(kbKeyInput:getText()) end)
	holdKBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end task.spawn(Input.holdKey,kbKeyInput:getText(),kbHoldSl:get()/1000) end)
	relAllBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end Input.releaseAll() end)

	-- spam
	local spamCard = makeCard(scroll3,2)
	sectionHeader(spamCard,"Spam",1)
	local spamTimesSl = makeSlider(spamCard,"Times",1,200,10,nil,2)
	local spamIvSl    = makeSlider(spamCard,"Interval (ms)",10,1000,100,nil,3)
	local spamBtn = makeButton(spamCard,"SPAM KEY",nil,4,false)
	local spamLoopStop_ = nil
	local spamToggle_ = makeToggle(spamCard,"Continuous Spam",false,function(state)
		if state then
			spamLoopStop_ = Input.loop(spamIvSl:get()/1000,function() Input.tap(kbKeyInput:getText(),0.03) end)
		else
			if spamLoopStop_ then spamLoopStop_() spamLoopStop_=nil end
		end
	end,5)
	spamBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		task.spawn(Input.spam,kbKeyInput:getText(),spamTimesSl:get(),spamIvSl:get()/1000)
	end)

	-- type
	local typeCard = makeCard(scroll3,3)
	sectionHeader(typeCard,"Type Text",1)
	local typeInput_ = makeInput(typeCard,"text to type...",nil,2)
	local typeWpmSl  = makeSlider(typeCard,"WPM",10,300,80,nil,3)
	local typeRow = frame(typeCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=4})
	listLayout(typeRow,Enum.FillDirection.Horizontal,4)
	local typeBtn = makeButton(typeRow,"TYPE",nil,1,false) typeBtn.Size=UDim2.new(0.5,-2,1,0)
	local typeHBtn= makeButton(typeRow,"TYPE HUMAN",nil,2,true) typeHBtn.Size=UDim2.new(0.5,0,1,0)
	typeBtn.InputBegan:Connect(function(inp)  if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end task.spawn(Input.typeText,typeInput_:getText(),0.04,false) end)
	typeHBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end task.spawn(Input.typeHuman,typeInput_:getText(),typeWpmSl:get()) end)

	-- combo
	local comboCard = makeCard(scroll3,4)
	sectionHeader(comboCard,"Combo",1)
	local comboInput = makeInput(comboCard,"comma-separated: LCtrl,c",nil,2)
	comboInput:setText("LCtrl,c")
	local comboFireBtn = makeButton(comboCard,"FIRE COMBO",nil,3,false)
	comboFireBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		local keys={}
		for k in comboInput:getText():gmatch("([^,]+)") do table.insert(keys,k:gsub("%s","")) end
		task.spawn(Input.combo,keys,nil,0.05)
	end)

	-- hotkeys
	local hkCard = makeCard(scroll3,5)
	sectionHeader(hkCard,"Hotkeys",1)
	local hkKeyInput = makeInput(hkCard,"key to bind (e.g. F6)",nil,2)
	hkKeyInput:setText("F6")
	local hkActionDrop = makeInput(hkCard,"action: releaseAll / spamToggle / runMacro",nil,3)
	hkActionDrop:setText("releaseAll")
	local hkBindBtn = makeButton(hkCard,"BIND HOTKEY",nil,4,false)
	local hkListBtn = makeButton(hkCard,"LIST HOTKEYS (console)",nil,5,false)
	local hkClearBtn= makeButton(hkCard,"UNBIND ALL",nil,6,false)
	hkBindBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		local key=hkKeyInput:getText()
		local action=hkActionDrop:getText()
		if action=="releaseAll" then Input.bindHotkey(key,Input.releaseAll,key.."->releaseAll")
		elseif action=="spamToggle" then
			Input.bindToggle(key,
				function() spamLoopStop_=Input.loop(spamIvSl:get()/1000,function() Input.tap(kbKeyInput:getText(),0.03) end) end,
				function() if spamLoopStop_ then spamLoopStop_() spamLoopStop_=nil end end
			)
		elseif action=="runMacro" then
			if currentMacro_ then Input.bindMacroHotkey(key,currentMacro_) end
		end
		print("[UI] Bound "..key.." -> "..action)
	end)
	hkListBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		for _,h in ipairs(Input.listHotkeys()) do print("[HK] "..h) end
	end)
	hkClearBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		Input.unbindAll()
		print("[UI] All hotkeys cleared")
	end)

	-- ── PAGE 4: MOUSE ─────────────────────────────────────────────────────────
	local page4, scroll4 = makePage()
	tabBtns[4]._page = page4

	-- live mouse tracker
	local mouseCard = makeCard(scroll4,1)
	sectionHeader(mouseCard,"Live Position",1)
	local mousePosLbl = label(mouseCard,"0, 0",20,C.TEXT,FONT_MONO,{Size=UDim2.new(1,0,0,24),TextSize=20,LayoutOrder=2})
	local mouseTrackTog = makeToggle(mouseCard,"Track Position",false,nil,3)
	RunService.Heartbeat:Connect(function()
		if mouseTrackTog._state() then
			local x,y=Input.getMousePos()
			mousePosLbl.Text=string.format("%d,  %d",x,y)
		end
	end)

	-- move
	local moveCard = makeCard(scroll4,2)
	sectionHeader(moveCard,"Move",1)
	local mxInput = makeInput(moveCard,"X",nil,2)
	local myInput = makeInput(moveCard,"Y",nil,3)
	mxInput:setText("500") myInput:setText("300")
	local moveDurSl = makeSlider(moveCard,"Duration (ms)",0,2000,300,nil,4)
	local moveStyleInput = makeInput(moveCard,"easing: linear easeInOut bounce elastic sine...",nil,5)
	moveStyleInput:setText("easeInOut")
	local moveRow = frame(moveCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=6})
	listLayout(moveRow,Enum.FillDirection.Horizontal,4)
	local moveInstBtn    = makeButton(moveRow,"INSTANT",nil,1,false) moveInstBtn.Size=UDim2.new(0.33,-3,1,0)
	local moveSmoothBtn  = makeButton(moveRow,"SMOOTH",nil,2,false)  moveSmoothBtn.Size=UDim2.new(0.33,-3,1,0)
	local moveNaturalBtn = makeButton(moveRow,"NATURAL",nil,3,false)  moveNaturalBtn.Size=UDim2.new(0.34,0,1,0)

	local function getXY() return tonumber(mxInput:getText()) or 500, tonumber(myInput:getText()) or 300 end
	moveInstBtn.InputBegan:Connect(function(inp)    if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() Input.mouseMove(x,y) end)
	moveSmoothBtn.InputBegan:Connect(function(inp)  if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() task.spawn(Input.mouseMoveSmooth,x,y,moveDurSl:get()/1000,moveStyleInput:getText()) end)
	moveNaturalBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() task.spawn(Input.mouseMoveNatural,x,y,moveDurSl:get()/1000) end)

	-- click
	local clickCard = makeCard(scroll4,3)
	sectionHeader(clickCard,"Click",1)
	local clickHoldSl = makeSlider(clickCard,"Hold (ms)",10,1000,50,nil,2)
	local clickRow = frame(clickCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=3})
	listLayout(clickRow,Enum.FillDirection.Horizontal,4)
	local clkBtn   = makeButton(clickRow,"LEFT",nil,1,true)  clkBtn.Size=UDim2.new(0.25,-3,1,0)
	local rClkBtn  = makeButton(clickRow,"RIGHT",nil,2,false) rClkBtn.Size=UDim2.new(0.25,-3,1,0)
	local dClkBtn  = makeButton(clickRow,"DOUBLE",nil,3,false) dClkBtn.Size=UDim2.new(0.25,-3,1,0)
	local humClkBtn= makeButton(clickRow,"HUMAN",nil,4,false) humClkBtn.Size=UDim2.new(0.25,0,1,0)

	clkBtn.InputBegan:Connect(function(inp)    if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() task.spawn(Input.click,x,y,Input.LEFT,clickHoldSl:get()/1000) end)
	rClkBtn.InputBegan:Connect(function(inp)   if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() task.spawn(Input.rightClick,x,y,clickHoldSl:get()/1000) end)
	dClkBtn.InputBegan:Connect(function(inp)   if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() task.spawn(Input.doubleClick,x,y) end)
	humClkBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() task.spawn(Input.clickHuman,x,y,Input.LEFT,clickHoldSl:get()/1000,6) end)

	-- drag
	local dragCard = makeCard(scroll4,4)
	sectionHeader(dragCard,"Drag",1)
	local dx2In = makeInput(dragCard,"To X",nil,2) dx2In:setText("800")
	local dy2In = makeInput(dragCard,"To Y",nil,3) dy2In:setText("400")
	local dragDurSl = makeSlider(dragCard,"Duration (ms)",50,3000,300,nil,4)
	local dragRow = frame(dragCard,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=5})
	listLayout(dragRow,Enum.FillDirection.Horizontal,4)
	local dragBtn  = makeButton(dragRow,"DRAG",nil,1,false)  dragBtn.Size=UDim2.new(0.5,-2,1,0)
	local swipeBtn = makeButton(dragRow,"SWIPE",nil,2,false) swipeBtn.Size=UDim2.new(0.5,0,1,0)
	dragBtn.InputBegan:Connect(function(inp)  if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() local x2,y2=tonumber(dx2In:getText()) or 800,tonumber(dy2In:getText()) or 400 task.spawn(Input.drag,x,y,x2,y2,Input.LEFT,25,dragDurSl:get()/1000,"easeInOut") end)
	swipeBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() local x2,y2=tonumber(dx2In:getText()) or 800,tonumber(dy2In:getText()) or 400 task.spawn(Input.swipe,x,y,x2,y2,0.15) end)

	-- scroll
	local scrollCard_ = makeCard(scroll4,5)
	sectionHeader(scrollCard_,"Scroll",1)
	local scrollAmtSl = makeSlider(scrollCard_,"Amount",-20,20,3,nil,2)
	local scrollRow = frame(scrollCard_,{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=3})
	listLayout(scrollRow,Enum.FillDirection.Horizontal,4)
	local scrHereBtn = makeButton(scrollRow,"AT CURSOR",nil,1,false) scrHereBtn.Size=UDim2.new(0.5,-2,1,0)
	local scrXYBtn   = makeButton(scrollRow,"AT X,Y",nil,2,false) scrXYBtn.Size=UDim2.new(0.5,0,1,0)
	scrHereBtn.InputBegan:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end Input.scrollHere(scrollAmtSl:get()) end)
	scrXYBtn.InputBegan:Connect(function(inp)   if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end local x,y=getXY() Input.scroll(x,y,scrollAmtSl:get()) end)

	-- ── FOOTER ────────────────────────────────────────────────────────────────
	local footer = frame(win,{
		Size=UDim2.new(1,0,0,24),
		Position=UDim2.new(0,0,1,-24),
		BackgroundColor3=C.SURFACE,
	})
	stroke(footer,C.BORDER,1)
	local statsLbl = label(footer,"",10,C.SUBTEXT,FONT_MONO,{
		Position=UDim2.new(0,12,0,0),
		Size=UDim2.new(1,-12,1,0),
		TextSize=10,
	})
	RunService.Heartbeat:Connect(function()
		local s=Input.getStats()
		statsLbl.Text=string.format("taps %d  clicks %d  scrolls %d  drags %d  macros %d",s.taps,s.clicks,s.scrolls,s.drags,s.macrosRun)
	end)

	-- ── OPEN ANIMATION ────────────────────────────────────────────────────────
	win.Size   = UDim2.new(0,WIN_W,0,0)
	win.Position = UDim2.new(0.5,-WIN_W/2,0.5,0)
	tw(win,{Size=UDim2.new(0,WIN_W,0,WIN_H),Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)},0.3,Enum.EasingStyle.Back)

	log("UI","opened")
	return screenGui
end

-- ─────────────────────────────────────────────────────────────────────────────

print(string.format("[InputModule v%s] loaded  |  Input.openUI() to open the recorder", Input.VERSION))
return Input
