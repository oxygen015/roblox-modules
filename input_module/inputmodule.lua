local InputModule = {}

local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

InputModule.LEFT   = 0
InputModule.RIGHT  = 1
InputModule.MIDDLE = 2

local KeyMap = {
	["0"]=Enum.KeyCode.Zero,["1"]=Enum.KeyCode.One,["2"]=Enum.KeyCode.Two,
	["3"]=Enum.KeyCode.Three,["4"]=Enum.KeyCode.Four,["5"]=Enum.KeyCode.Five,
	["6"]=Enum.KeyCode.Six,["7"]=Enum.KeyCode.Seven,["8"]=Enum.KeyCode.Eight,
	["9"]=Enum.KeyCode.Nine,
	["!"]=Enum.KeyCode.One,["@"]=Enum.KeyCode.Two,["#"]=Enum.KeyCode.Three,
	["$"]=Enum.KeyCode.Four,["%"]=Enum.KeyCode.Five,["^"]=Enum.KeyCode.Six,
	["&"]=Enum.KeyCode.Seven,["*"]=Enum.KeyCode.Eight,["("]=Enum.KeyCode.Nine,
	[")"]=Enum.KeyCode.Zero,
	["a"]=Enum.KeyCode.A,["A"]=Enum.KeyCode.A,["b"]=Enum.KeyCode.B,["B"]=Enum.KeyCode.B,
	["c"]=Enum.KeyCode.C,["C"]=Enum.KeyCode.C,["d"]=Enum.KeyCode.D,["D"]=Enum.KeyCode.D,
	["e"]=Enum.KeyCode.E,["E"]=Enum.KeyCode.E,["f"]=Enum.KeyCode.F,["F"]=Enum.KeyCode.F,
	["g"]=Enum.KeyCode.G,["G"]=Enum.KeyCode.G,["h"]=Enum.KeyCode.H,["H"]=Enum.KeyCode.H,
	["i"]=Enum.KeyCode.I,["I"]=Enum.KeyCode.I,["j"]=Enum.KeyCode.J,["J"]=Enum.KeyCode.J,
	["k"]=Enum.KeyCode.K,["K"]=Enum.KeyCode.K,["l"]=Enum.KeyCode.L,["L"]=Enum.KeyCode.L,
	["m"]=Enum.KeyCode.M,["M"]=Enum.KeyCode.M,["n"]=Enum.KeyCode.N,["N"]=Enum.KeyCode.N,
	["o"]=Enum.KeyCode.O,["O"]=Enum.KeyCode.O,["p"]=Enum.KeyCode.P,["P"]=Enum.KeyCode.P,
	["q"]=Enum.KeyCode.Q,["Q"]=Enum.KeyCode.Q,["r"]=Enum.KeyCode.R,["R"]=Enum.KeyCode.R,
	["s"]=Enum.KeyCode.S,["S"]=Enum.KeyCode.S,["t"]=Enum.KeyCode.T,["T"]=Enum.KeyCode.T,
	["u"]=Enum.KeyCode.U,["U"]=Enum.KeyCode.U,["v"]=Enum.KeyCode.V,["V"]=Enum.KeyCode.V,
	["w"]=Enum.KeyCode.W,["W"]=Enum.KeyCode.W,["x"]=Enum.KeyCode.X,["X"]=Enum.KeyCode.X,
	["y"]=Enum.KeyCode.Y,["Y"]=Enum.KeyCode.Y,["z"]=Enum.KeyCode.Z,["Z"]=Enum.KeyCode.Z,
	["Space"]=Enum.KeyCode.Space,["Enter"]=Enum.KeyCode.Return,["Tab"]=Enum.KeyCode.Tab,
	["Backspace"]=Enum.KeyCode.Backspace,["Escape"]=Enum.KeyCode.Escape,
	["Delete"]=Enum.KeyCode.Delete,["Insert"]=Enum.KeyCode.Insert,
	["Home"]=Enum.KeyCode.Home,["End"]=Enum.KeyCode.End,
	["PageUp"]=Enum.KeyCode.PageUp,["PageDown"]=Enum.KeyCode.PageDown,
	["Up"]=Enum.KeyCode.Up,["Down"]=Enum.KeyCode.Down,
	["Left"]=Enum.KeyCode.Left,["Right"]=Enum.KeyCode.Right,
	["F1"]=Enum.KeyCode.F1,["F2"]=Enum.KeyCode.F2,["F3"]=Enum.KeyCode.F3,
	["F4"]=Enum.KeyCode.F4,["F5"]=Enum.KeyCode.F5,["F6"]=Enum.KeyCode.F6,
	["F7"]=Enum.KeyCode.F7,["F8"]=Enum.KeyCode.F8,["F9"]=Enum.KeyCode.F9,
	["F10"]=Enum.KeyCode.F10,["F11"]=Enum.KeyCode.F11,["F12"]=Enum.KeyCode.F12,
	["LShift"]=Enum.KeyCode.LeftShift,["RShift"]=Enum.KeyCode.RightShift,
	["LCtrl"]=Enum.KeyCode.LeftControl,["RCtrl"]=Enum.KeyCode.RightControl,
	["LAlt"]=Enum.KeyCode.LeftAlt,["RAlt"]=Enum.KeyCode.RightAlt,
	["CapsLock"]=Enum.KeyCode.CapsLock,
	["`"]=Enum.KeyCode.BackQuote,["-"]=Enum.KeyCode.Minus,["="]=Enum.KeyCode.Equals,
	["["]=Enum.KeyCode.LeftBracket,["]"]=Enum.KeyCode.RightBracket,
	["\\"]=Enum.KeyCode.BackSlash,[";"]=Enum.KeyCode.Semicolon,
	["'"]=Enum.KeyCode.Quote,[","]=Enum.KeyCode.Comma,["."]=Enum.KeyCode.Period,
	["/"]=Enum.KeyCode.Slash,
}

local ShiftSet = {}
for _,v in ipairs({
	"!","@","#","$","%","^","&","*","(",")",
	"A","B","C","D","E","F","G","H","I","J","K","L","M",
	"N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"~","_","+","{","}","|",":","\"","<",">","?"
}) do ShiftSet[v] = true end

local macroStore   = {}
local recording    = false
local macroActions = {}
local recordStart  = 0
local recConn1, recConn2, recConn3
local heldKeys     = {}
local hotkeyBinds  = {}
local hotkeyConn   = nil

local function resolveKey(key)
	return KeyMap[key]
end

local function worldToScreen(position)
	local camera = workspace.CurrentCamera
	local screenPos, onScreen = camera:WorldToScreenPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function cfToScreen(cf)
	return worldToScreen(cf.Position)
end

InputModule.keyDown = function(key)
	local kc = resolveKey(key)
	if not kc then warn("[Input] Unknown key: "..tostring(key)) return end
	if ShiftSet[key] then VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end
	VIM:SendKeyEvent(true, kc, false, game)
	heldKeys[key] = true
end

InputModule.keyUp = function(key)
	local kc = resolveKey(key)
	if not kc then warn("[Input] Unknown key: "..tostring(key)) return end
	VIM:SendKeyEvent(false, kc, false, game)
	if ShiftSet[key] then VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end
	heldKeys[key] = nil
end

InputModule.tap = function(key, holdTime)
	holdTime = holdTime or 0.05
	InputModule.keyDown(key)
	task.wait(holdTime)
	InputModule.keyUp(key)
end

InputModule.tapAsync = function(key, holdTime)
	task.spawn(function() InputModule.tap(key, holdTime) end)
end

InputModule.typeText = function(text, interval)
	interval = interval or 0.05
	for i = 1, #text do
		InputModule.tap(text:sub(i,i), 0.04)
		task.wait(interval)
	end
end

InputModule.combo = function(keys, callback)
	for _, k in ipairs(keys) do InputModule.keyDown(k) end
	if callback then callback() end
	task.wait(0.05)
	for i = #keys, 1, -1 do InputModule.keyUp(keys[i]) end
end

InputModule.holdKey = function(key, duration)
	InputModule.keyDown(key)
	task.wait(duration)
	InputModule.keyUp(key)
end

InputModule.holdKeyAsync = function(key, duration)
	task.spawn(function() InputModule.holdKey(key, duration) end)
end

InputModule.releaseAll = function()
	for key in pairs(heldKeys) do InputModule.keyUp(key) end
	VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift,   false, game)
	VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
	VIM:SendKeyEvent(false, Enum.KeyCode.LeftAlt,     false, game)
end

InputModule.isKeyHeld = function(key)
	local kc = resolveKey(key)
	if not kc then return false end
	return UIS:IsKeyDown(kc)
end

InputModule.spam = function(key, times, interval)
	interval = interval or 0.05
	for i = 1, times do
		InputModule.tap(key, 0.03)
		task.wait(interval)
	end
end

InputModule.spamAsync = function(key, times, interval)
	task.spawn(function() InputModule.spam(key, times, interval) end)
end

InputModule.mouseMove = function(x, y)
	VIM:SendMouseMoveEvent(x, y, game)
end

InputModule.mouseDown = function(x, y, button)
	VIM:SendMouseButtonEvent(x, y, button or InputModule.LEFT, true, game, 1)
end

InputModule.mouseUp = function(x, y, button)
	VIM:SendMouseButtonEvent(x, y, button or InputModule.LEFT, false, game, 1)
end

InputModule.click = function(x, y, button, holdTime)
	button   = button   or InputModule.LEFT
	holdTime = holdTime or 0.05
	InputModule.mouseMove(x, y)
	task.wait(0.02)
	InputModule.mouseDown(x, y, button)
	task.wait(holdTime)
	InputModule.mouseUp(x, y, button)
end

InputModule.clickAsync = function(x, y, button, holdTime)
	task.spawn(function() InputModule.click(x, y, button, holdTime) end)
end

InputModule.rightClick = function(x, y, holdTime)
	InputModule.click(x, y, InputModule.RIGHT, holdTime)
end

InputModule.doubleClick = function(x, y, button)
	InputModule.click(x, y, button, 0.05)
	task.wait(0.08)
	InputModule.click(x, y, button, 0.05)
end

InputModule.drag = function(x1, y1, x2, y2, button, steps, duration)
	button   = button   or InputModule.LEFT
	steps    = steps    or 20
	duration = duration or 0.3
	InputModule.mouseMove(x1, y1)
	task.wait(0.02)
	InputModule.mouseDown(x1, y1, button)
	task.wait(0.05)
	local stepDelay = duration / steps
	for i = 1, steps do
		local t = i / steps
		InputModule.mouseMove(
			math.floor(x1 + (x2 - x1) * t),
			math.floor(y1 + (y2 - y1) * t)
		)
		task.wait(stepDelay)
	end
	InputModule.mouseUp(x2, y2, button)
end

InputModule.scroll = function(x, y, amount)
	amount = amount or 1
	local up = amount > 0
	for _ = 1, math.abs(amount) do
		VIM:SendMouseWheelEvent(x, y, up, game)
		task.wait(0.02)
	end
end

InputModule.scrollHere = function(amount)
	local pos = UIS:GetMouseLocation()
	InputModule.scroll(pos.X, pos.Y, amount)
end

InputModule.clickCFrame = function(cf, button, holdTime)
	local screen, onScreen = cfToScreen(cf)
	if not onScreen then warn("[Input] CFrame not on screen.") return false end
	InputModule.click(math.floor(screen.X), math.floor(screen.Y), button, holdTime)
	return true
end

InputModule.clickPart = function(part, button, holdTime)
	if not part or not part:IsA("BasePart") then warn("[Input] Not a BasePart.") return false end
	return InputModule.clickCFrame(part.CFrame, button, holdTime)
end

InputModule.clickPosition = function(worldPos, button, holdTime)
	local screen, onScreen = worldToScreen(worldPos)
	if not onScreen then warn("[Input] World position not on screen.") return false end
	InputModule.click(math.floor(screen.X), math.floor(screen.Y), button, holdTime)
	return true
end

InputModule.isOnScreen = function(cf)
	local _, onScreen = cfToScreen(cf)
	return onScreen
end

InputModule.getScreenPos = function(cf)
	local screen, onScreen = cfToScreen(cf)
	if onScreen then return math.floor(screen.X), math.floor(screen.Y) end
	return nil, nil
end

InputModule.moveToCFrame = function(cf, steps, duration)
	local screen, onScreen = cfToScreen(cf)
	if not onScreen then return false end
	steps    = steps    or 20
	duration = duration or 0.3
	local current = UIS:GetMouseLocation()
	local x1, y1  = current.X, current.Y
	local x2, y2  = math.floor(screen.X), math.floor(screen.Y)
	for i = 1, steps do
		local t = i / steps
		InputModule.mouseMove(
			math.floor(x1 + (x2 - x1) * t),
			math.floor(y1 + (y2 - y1) * t)
		)
		task.wait(duration / steps)
	end
	return true
end

InputModule.getMousePos = function()
	local pos = UIS:GetMouseLocation()
	return {x = pos.X, y = pos.Y}
end

InputModule.getScreenCenter = function()
	local vp = workspace.CurrentCamera.ViewportSize
	return {x = math.floor(vp.X / 2), y = math.floor(vp.Y / 2)}
end

InputModule.getScreenSize = function()
	local vp = workspace.CurrentCamera.ViewportSize
	return {width = vp.X, height = vp.Y}
end

InputModule.newMacro = function(name)
	local m = {
		name    = name or ("macro_"..tostring(#macroStore + 1)),
		actions = {},
		speed   = 1.0,
		loops   = 1,
	}
	macroStore[m.name] = m
	return m
end

InputModule.addKey = function(macro, key, holdTime, delay)
	table.insert(macro.actions, {type="tap", key=key, holdTime=holdTime or 0.05, delay=delay or 0})
end

InputModule.addClick = function(macro, x, y, button, holdTime, delay)
	table.insert(macro.actions, {type="click", x=x, y=y, button=button or 0, holdTime=holdTime or 0.05, delay=delay or 0})
end

InputModule.addCFrameClick = function(macro, cf, button, holdTime, delay)
	table.insert(macro.actions, {type="cfclick", cf=cf, button=button or 0, holdTime=holdTime or 0.05, delay=delay or 0})
end

InputModule.addPartClick = function(macro, part, button, holdTime, delay)
	table.insert(macro.actions, {type="partclick", part=part, button=button or 0, holdTime=holdTime or 0.05, delay=delay or 0})
end

InputModule.addMove = function(macro, x, y, delay)
	table.insert(macro.actions, {type="move", x=x, y=y, delay=delay or 0})
end

InputModule.addScroll = function(macro, x, y, amount, delay)
	table.insert(macro.actions, {type="scroll", x=x, y=y, amount=amount or 1, delay=delay or 0})
end

InputModule.addWait = function(macro, duration)
	table.insert(macro.actions, {type="wait", duration=duration})
end

InputModule.addCombo = function(macro, keys, delay)
	table.insert(macro.actions, {type="combo", keys=keys, delay=delay or 0})
end

InputModule.addText = function(macro, text, interval, delay)
	table.insert(macro.actions, {type="text", text=text, interval=interval or 0.05, delay=delay or 0})
end

InputModule.addDrag = function(macro, x1, y1, x2, y2, steps, duration, delay)
	table.insert(macro.actions, {type="drag", x1=x1, y1=y1, x2=x2, y2=y2, steps=steps or 20, duration=duration or 0.3, delay=delay or 0})
end

InputModule.addRepeat = function(macro, innerMacro, times)
	table.insert(macro.actions, {type="repeat", macro=innerMacro, times=times or 1})
end

InputModule.addRightClick = function(macro, x, y, holdTime, delay)
	table.insert(macro.actions, {type="click", x=x, y=y, button=1, holdTime=holdTime or 0.05, delay=delay or 0})
end

InputModule.addDoubleClick = function(macro, x, y, delay)
	table.insert(macro.actions, {type="doubleclick", x=x, y=y, delay=delay or 0})
end

InputModule.addScrollAction = function(macro, amount, delay)
	local pos = UIS:GetMouseLocation()
	table.insert(macro.actions, {type="scroll", x=pos.X, y=pos.Y, amount=amount or 1, delay=delay or 0})
end

InputModule.runMacro = function(macro, overrideLoops)
	local loops = overrideLoops or macro.loops or 1
	local speed = macro.speed   or 1.0

	local function runOnce(actions)
		for _, action in ipairs(actions) do
			if action.delay and action.delay > 0 then
				task.wait(action.delay / speed)
			end
			if action.type == "tap" then
				InputModule.tap(action.key, action.holdTime)
			elseif action.type == "click" then
				InputModule.click(action.x, action.y, action.button, action.holdTime)
			elseif action.type == "doubleclick" then
				InputModule.doubleClick(action.x, action.y)
			elseif action.type == "cfclick" then
				InputModule.clickCFrame(action.cf, action.button, action.holdTime)
			elseif action.type == "partclick" then
				InputModule.clickPart(action.part, action.button, action.holdTime)
			elseif action.type == "move" then
				InputModule.mouseMove(action.x, action.y)
			elseif action.type == "scroll" then
				InputModule.scroll(action.x, action.y, action.amount)
			elseif action.type == "wait" then
				task.wait(action.duration / speed)
			elseif action.type == "combo" then
				InputModule.combo(action.keys)
			elseif action.type == "text" then
				InputModule.typeText(action.text, action.interval)
			elseif action.type == "drag" then
				InputModule.drag(action.x1, action.y1, action.x2, action.y2, nil, action.steps, action.duration / speed)
			elseif action.type == "repeat" then
				for _ = 1, action.times do runOnce(action.macro.actions) end
			end
		end
	end

	for i = 1, loops do
		runOnce(macro.actions)
	end
end

InputModule.runMacroAsync = function(macro, overrideLoops)
	task.spawn(function() InputModule.runMacro(macro, overrideLoops) end)
end

InputModule.saveMacro = function(name, macro)
	macroStore[name] = macro
end

InputModule.loadMacro = function(name)
	return macroStore[name]
end

InputModule.listMacros = function()
	local names = {}
	for k in pairs(macroStore) do table.insert(names, k) end
	return names
end

InputModule.deleteMacro = function(name)
	macroStore[name] = nil
end

InputModule.startRecording = function(name)
	macroActions = {}
	recordStart  = tick()
	recording    = true

	recConn1 = UIS.InputBegan:Connect(function(input)
		if not recording then return end
		local t = tick() - recordStart
		if input.UserInputType == Enum.UserInputType.Keyboard then
			table.insert(macroActions, {time=t, type="keyDown", key=tostring(input.KeyCode)})
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(macroActions, {time=t, type="mouseDown", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=0})
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			table.insert(macroActions, {time=t, type="mouseDown", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=1})
		end
	end)

	recConn2 = UIS.InputEnded:Connect(function(input)
		if not recording then return end
		local t = tick() - recordStart
		if input.UserInputType == Enum.UserInputType.Keyboard then
			table.insert(macroActions, {time=t, type="keyUp", key=tostring(input.KeyCode)})
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(macroActions, {time=t, type="mouseUp", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=0})
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			table.insert(macroActions, {time=t, type="mouseUp", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=1})
		end
	end)

	recConn3 = UIS.InputChanged:Connect(function(input)
		if not recording then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local t = tick() - recordStart
			table.insert(macroActions, {time=t, type="mouseMove", x=math.floor(input.Position.X), y=math.floor(input.Position.Y)})
		end
	end)

	print("[Input] Recording started: "..(name or "unnamed"))
end

InputModule.stopRecording = function(saveName)
	recording = false
	if recConn1 then recConn1:Disconnect() end
	if recConn2 then recConn2:Disconnect() end
	if recConn3 then recConn3:Disconnect() end
	print("[Input] Recording stopped. "..#macroActions.." actions captured.")
	if saveName then
		macroStore[saveName] = {name=saveName, recorded=true, actions=macroActions}
	end
	return macroActions
end

InputModule.playRecording = function(actions, speed, loops)
	speed   = speed  or 1.0
	loops   = loops  or 1
	actions = actions or macroActions

	for loop = 1, loops do
		local startTime = tick()
		local i = 1
		while i <= #actions do
			local action  = actions[i]
			local elapsed = (tick() - startTime) * speed
			if elapsed >= action.time then
				if action.type == "keyDown" then
					local kname = tostring(action.key):match("KeyCode%.(.+)")
					if kname then
						local kc = Enum.KeyCode[kname]
						if kc then VIM:SendKeyEvent(true, kc, false, game) end
					end
				elseif action.type == "keyUp" then
					local kname = tostring(action.key):match("KeyCode%.(.+)")
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
				end
				i = i + 1
			else
				task.wait(0.01)
			end
		end
		if loop < loops then task.wait(0.1) end
	end
end

InputModule.bindHotkey = function(key, callback)
	hotkeyBinds[key] = callback
	if not hotkeyConn then
		hotkeyConn = UIS.InputBegan:Connect(function(input, gpe)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local kname = tostring(input.KeyCode):match("KeyCode%.(.+)")
				if kname and hotkeyBinds[kname] then
					hotkeyBinds[kname]()
				end
			end
		end)
	end
end

InputModule.unbindHotkey = function(key)
	hotkeyBinds[key] = nil
end

InputModule.unbindAll = function()
	hotkeyBinds = {}
	if hotkeyConn then hotkeyConn:Disconnect() hotkeyConn = nil end
end

InputModule.wait = function(seconds)
	task.wait(seconds)
end

InputModule.repeatAction = function(times, interval, callback)
	for i = 1, times do
		callback(i)
		if i < times then task.wait(interval) end
	end
end

InputModule.repeatAsync = function(times, interval, callback)
	task.spawn(function() InputModule.repeatAction(times, interval, callback) end)
end

InputModule.loop = function(interval, callback)
	local running = true
	local thread = task.spawn(function()
		while running do
			callback()
			task.wait(interval)
		end
	end)
	return function()
		running = false
		task.cancel(thread)
	end
end

InputModule.waitForKey = function(key)
	local kc = resolveKey(key)
	if not kc then return end
	local done = false
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if input.KeyCode == kc then done = true conn:Disconnect() end
	end)
	repeat task.wait(0.05) until done
end

InputModule.waitForClick = function()
	local done, px, py = false, nil, nil
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			px, py = math.floor(input.Position.X), math.floor(input.Position.Y)
			done = true
			conn:Disconnect()
		end
	end)
	repeat task.wait(0.05) until done
	return px, py
end

InputModule.listKeys = function()
	local keys = {}
	for k in pairs(KeyMap) do table.insert(keys, k) end
	table.sort(keys)
	print("[Input] Keys: "..table.concat(keys, ", "))
end

print("[InputModule] Ready.")
return InputModule
