local InputModule = {}

local VIM     = game:GetService("VirtualInputManager")
local UIS     = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

InputModule.LEFT   = 0
InputModule.RIGHT  = 1
InputModule.MIDDLE = 2

InputModule.VERSION = "2.0.0"

local function safeKeyCode(name)
	local ok, result = pcall(function() return Enum.KeyCode[name] end)
	if ok and result then return result end
	return nil
end

local KeyMap = {}

local function addKey(char, enumName)
	local kc = safeKeyCode(enumName)
	if kc then KeyMap[char] = kc end
end

addKey("0", "Zero")
addKey("1", "One")
addKey("2", "Two")
addKey("3", "Three")
addKey("4", "Four")
addKey("5", "Five")
addKey("6", "Six")
addKey("7", "Seven")
addKey("8", "Eight")
addKey("9", "Nine")

addKey("!", "One")
addKey("@", "Two")
addKey("#", "Three")
addKey("$", "Four")
addKey("%", "Five")
addKey("^", "Six")
addKey("&", "Seven")
addKey("*", "Eight")
addKey("(", "Nine")
addKey(")", "Zero")

addKey("a", "A") addKey("A", "A")
addKey("b", "B") addKey("B", "B")
addKey("c", "C") addKey("C", "C")
addKey("d", "D") addKey("D", "D")
addKey("e", "E") addKey("E", "E")
addKey("f", "F") addKey("F", "F")
addKey("g", "G") addKey("G", "G")
addKey("h", "H") addKey("H", "H")
addKey("i", "I") addKey("I", "I")
addKey("j", "J") addKey("J", "J")
addKey("k", "K") addKey("K", "K")
addKey("l", "L") addKey("L", "L")
addKey("m", "M") addKey("M", "M")
addKey("n", "N") addKey("N", "N")
addKey("o", "O") addKey("O", "O")
addKey("p", "P") addKey("P", "P")
addKey("q", "Q") addKey("Q", "Q")
addKey("r", "R") addKey("R", "R")
addKey("s", "S") addKey("S", "S")
addKey("t", "T") addKey("T", "T")
addKey("u", "U") addKey("U", "U")
addKey("v", "V") addKey("V", "V")
addKey("w", "W") addKey("W", "W")
addKey("x", "X") addKey("X", "X")
addKey("y", "Y") addKey("Y", "Y")
addKey("z", "Z") addKey("Z", "Z")

addKey("Space",      "Space")
addKey("Enter",      "Return")
addKey("Tab",        "Tab")
addKey("Backspace",  "Backspace")
addKey("Escape",     "Escape")
addKey("Delete",     "Delete")
addKey("Insert",     "Insert")
addKey("Home",       "Home")
addKey("End",        "End")
addKey("PageUp",     "PageUp")
addKey("PageDown",   "PageDown")
addKey("Up",         "Up")
addKey("Down",       "Down")
addKey("Left",       "Left")
addKey("Right",      "Right")
addKey("CapsLock",   "CapsLock")
addKey("NumLock",    "NumLock")
addKey("ScrollLock", "ScrollLock")
addKey("Pause",      "Pause")
addKey("Print",      "Print")

addKey("F1",  "F1")  addKey("F2",  "F2")  addKey("F3",  "F3")
addKey("F4",  "F4")  addKey("F5",  "F5")  addKey("F6",  "F6")
addKey("F7",  "F7")  addKey("F8",  "F8")  addKey("F9",  "F9")
addKey("F10", "F10") addKey("F11", "F11") addKey("F12", "F12")

addKey("LShift",  "LeftShift")
addKey("RShift",  "RightShift")
addKey("LCtrl",   "LeftControl")
addKey("RCtrl",   "RightControl")
addKey("LAlt",    "LeftAlt")
addKey("RAlt",    "RightAlt")
addKey("LMeta",   "LeftMeta")
addKey("RMeta",   "RightMeta")
addKey("LSuper",  "LeftSuper")
addKey("RSuper",  "RightSuper")

addKey("Num0", "KeypadZero")
addKey("Num1", "KeypadOne")
addKey("Num2", "KeypadTwo")
addKey("Num3", "KeypadThree")
addKey("Num4", "KeypadFour")
addKey("Num5", "KeypadFive")
addKey("Num6", "KeypadSix")
addKey("Num7", "KeypadSeven")
addKey("Num8", "KeypadEight")
addKey("Num9", "KeypadNine")
addKey("Num.", "KeypadPeriod")
addKey("Num+", "KeypadPlus")
addKey("Num-", "KeypadMinus")
addKey("Num*", "KeypadAsterisk")
addKey("Num/", "KeypadSlash")
addKey("NumEnter", "KeypadEnter")

local punctuationMap = {
	{"-",  "Minus"},
	{"=",  "Equals"},
	{"[",  "LeftBracket"},
	{"]",  "RightBracket"},
	{"\\", "BackSlash"},
	{";",  "Semicolon"},
	{"'",  "Quote"},
	{",",  "Comma"},
	{".",  "Period"},
	{"/",  "Slash"},
	{"`",  "Tilde"},
}

for _, pair in ipairs(punctuationMap) do
	local char, enumName = pair[1], pair[2]
	local kc = safeKeyCode(enumName)
	if not kc then
		kc = safeKeyCode("BackQuote")
		if char ~= "`" then kc = nil end
	end
	if kc then KeyMap[char] = kc end
end

local ShiftSet = {}
for _, v in ipairs({
	"!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
	"A","B","C","D","E","F","G","H","I","J","K","L","M",
	"N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"~","_","+","{","}","|",":","\"","<",">","?",
}) do
	ShiftSet[v] = true
end

local heldKeys     = {}
local macroStore   = {}
local recording    = false
local macroActions = {}
local recordStart  = 0
local recConnections = {}
local hotkeyBinds  = {}
local hotkeyConn   = nil
local conditionals = {}
local _stats       = {taps=0, clicks=0, macrosRun=0, recordingsSaved=0}

local function resolveKey(key)
	return KeyMap[key]
end

local function screenPos(position)
	local cam = workspace.CurrentCamera
	local sp, onScreen = cam:WorldToScreenPoint(position)
	return Vector2.new(sp.X, sp.Y), onScreen
end

local function cfScreen(cf)
	return screenPos(cf.Position)
end

local function clamp(v, lo, hi)
	return math.max(lo, math.min(hi, v))
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function easeInOut(t)
	return t < 0.5 and 2*t*t or -1+(4-2*t)*t
end

local function easeIn(t)
	return t * t
end

local function easeOut(t)
	return t * (2 - t)
end

InputModule.keyDown = function(key)
	local kc = resolveKey(key)
	if not kc then
		warn("[Input] keyDown: unknown key '"..tostring(key).."'")
		return false
	end
	if ShiftSet[key] then
		VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
	end
	VIM:SendKeyEvent(true, kc, false, game)
	heldKeys[key] = true
	return true
end

InputModule.keyUp = function(key)
	local kc = resolveKey(key)
	if not kc then
		warn("[Input] keyUp: unknown key '"..tostring(key).."'")
		return false
	end
	VIM:SendKeyEvent(false, kc, false, game)
	if ShiftSet[key] then
		VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
	end
	heldKeys[key] = nil
	return true
end

InputModule.tap = function(key, holdTime)
	holdTime = holdTime or 0.05
	if not InputModule.keyDown(key) then return false end
	task.wait(holdTime)
	InputModule.keyUp(key)
	_stats.taps = _stats.taps + 1
	return true
end

InputModule.tapAsync = function(key, holdTime)
	task.spawn(function()
		InputModule.tap(key, holdTime)
	end)
end

InputModule.tapMultiple = function(keys, holdTime)
	for _, key in ipairs(keys) do
		InputModule.tap(key, holdTime)
	end
end

InputModule.tapMultipleAsync = function(keys, holdTime)
	task.spawn(function()
		InputModule.tapMultiple(keys, holdTime)
	end)
end

InputModule.typeText = function(text, interval, randomize)
	interval  = interval  or 0.05
	randomize = randomize or false
	for i = 1, #text do
		local ch = text:sub(i, i)
		if KeyMap[ch] then
			InputModule.tap(ch, 0.04)
		else
			warn("[Input] typeText: no mapping for char '"..ch.."'")
		end
		local wait = interval
		if randomize then
			wait = interval * (0.7 + math.random() * 0.6)
		end
		task.wait(wait)
	end
end

InputModule.combo = function(keys, callback, releaseDelay)
	releaseDelay = releaseDelay or 0.05
	for _, k in ipairs(keys) do
		InputModule.keyDown(k)
	end
	if callback then callback() end
	task.wait(releaseDelay)
	for i = #keys, 1, -1 do
		InputModule.keyUp(keys[i])
	end
end

InputModule.comboAsync = function(keys, callback, releaseDelay)
	task.spawn(function()
		InputModule.combo(keys, callback, releaseDelay)
	end)
end

InputModule.holdKey = function(key, duration)
	if not InputModule.keyDown(key) then return false end
	task.wait(duration)
	InputModule.keyUp(key)
	return true
end

InputModule.holdKeyAsync = function(key, duration)
	task.spawn(function()
		InputModule.holdKey(key, duration)
	end)
end

InputModule.holdKeys = function(keys, duration)
	for _, k in ipairs(keys) do
		InputModule.keyDown(k)
	end
	task.wait(duration)
	for i = #keys, 1, -1 do
		InputModule.keyUp(keys[i])
	end
end

InputModule.holdKeysAsync = function(keys, duration)
	task.spawn(function()
		InputModule.holdKeys(keys, duration)
	end)
end

InputModule.releaseAll = function()
	for key in pairs(heldKeys) do
		local kc = resolveKey(key)
		if kc then VIM:SendKeyEvent(false, kc, false, game) end
	end
	heldKeys = {}
	VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift,   false, game)
	VIM:SendKeyEvent(false, Enum.KeyCode.RightShift,  false, game)
	VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
	VIM:SendKeyEvent(false, Enum.KeyCode.RightControl,false, game)
	VIM:SendKeyEvent(false, Enum.KeyCode.LeftAlt,     false, game)
	VIM:SendKeyEvent(false, Enum.KeyCode.RightAlt,    false, game)
	VIM:SendKeyEvent(false, Enum.KeyCode.Space,        false, game)
end

InputModule.isKeyHeld = function(key)
	local kc = resolveKey(key)
	if not kc then return false end
	return UIS:IsKeyDown(kc)
end

InputModule.isAnyKeyHeld = function(keys)
	for _, k in ipairs(keys) do
		if InputModule.isKeyHeld(k) then return true end
	end
	return false
end

InputModule.spam = function(key, times, interval)
	interval = interval or 0.05
	for i = 1, times do
		InputModule.tap(key, 0.03)
		if i < times then task.wait(interval) end
	end
end

InputModule.spamAsync = function(key, times, interval)
	task.spawn(function()
		InputModule.spam(key, times, interval)
	end)
end

InputModule.spamUntil = function(key, conditionFunc, interval, maxSeconds)
	interval   = interval   or 0.1
	maxSeconds = maxSeconds or 30
	local elapsed = 0
	while not conditionFunc() and elapsed < maxSeconds do
		InputModule.tap(key, 0.03)
		task.wait(interval)
		elapsed = elapsed + interval
	end
end

InputModule.sequence = function(keyList, interval)
	interval = interval or 0.1
	for _, entry in ipairs(keyList) do
		if type(entry) == "string" then
			InputModule.tap(entry, 0.05)
		elseif type(entry) == "table" then
			if entry.wait then
				task.wait(entry.wait)
			elseif entry.combo then
				InputModule.combo(entry.combo)
			elseif entry.key then
				InputModule.tap(entry.key, entry.hold or 0.05)
			end
		end
		task.wait(interval)
	end
end

InputModule.sequenceAsync = function(keyList, interval)
	task.spawn(function()
		InputModule.sequence(keyList, interval)
	end)
end

InputModule.waitForKey = function(key, timeout)
	local kc = resolveKey(key)
	if not kc then return false end
	local done  = false
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if input.KeyCode == kc then
			done = true
			conn:Disconnect()
		end
	end)
	local elapsed = 0
	local step    = 0.05
	while not done do
		task.wait(step)
		elapsed = elapsed + step
		if timeout and elapsed >= timeout then
			conn:Disconnect()
			return false
		end
	end
	return true
end

InputModule.waitForKeyRelease = function(key, timeout)
	local kc = resolveKey(key)
	if not kc then return false end
	local done = false
	local conn
	conn = UIS.InputEnded:Connect(function(input)
		if input.KeyCode == kc then
			done = true
			conn:Disconnect()
		end
	end)
	local elapsed = 0
	local step    = 0.05
	while not done do
		task.wait(step)
		elapsed = elapsed + step
		if timeout and elapsed >= timeout then
			conn:Disconnect()
			return false
		end
	end
	return true
end

InputModule.mouseMove = function(x, y)
	VIM:SendMouseMoveEvent(x, y, game)
end

InputModule.mouseMoveSmooth = function(x2, y2, duration, easingStyle)
	duration    = duration    or 0.3
	easingStyle = easingStyle or "linear"
	local current = UIS:GetMouseLocation()
	local x1, y1  = current.X, current.Y
	local steps    = math.max(5, math.floor(duration / 0.016))
	local stepDelay = duration / steps
	for i = 1, steps do
		local t = i / steps
		local et
		if easingStyle == "easeInOut" then
			et = easeInOut(t)
		elseif easingStyle == "easeIn" then
			et = easeIn(t)
		elseif easingStyle == "easeOut" then
			et = easeOut(t)
		else
			et = t
		end
		InputModule.mouseMove(
			math.floor(lerp(x1, x2, et)),
			math.floor(lerp(y1, y2, et))
		)
		task.wait(stepDelay)
	end
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
	_stats.clicks = _stats.clicks + 1
end

InputModule.clickAsync = function(x, y, button, holdTime)
	task.spawn(function()
		InputModule.click(x, y, button, holdTime)
	end)
end

InputModule.rightClick = function(x, y, holdTime)
	InputModule.click(x, y, InputModule.RIGHT, holdTime)
end

InputModule.rightClickAsync = function(x, y, holdTime)
	task.spawn(function()
		InputModule.rightClick(x, y, holdTime)
	end)
end

InputModule.middleClick = function(x, y, holdTime)
	InputModule.click(x, y, InputModule.MIDDLE, holdTime)
end

InputModule.doubleClick = function(x, y, button, gap)
	gap = gap or 0.08
	InputModule.click(x, y, button, 0.05)
	task.wait(gap)
	InputModule.click(x, y, button, 0.05)
end

InputModule.tripleClick = function(x, y, button, gap)
	gap = gap or 0.08
	for i = 1, 3 do
		InputModule.click(x, y, button, 0.05)
		if i < 3 then task.wait(gap) end
	end
end

InputModule.drag = function(x1, y1, x2, y2, button, steps, duration, easingStyle)
	button      = button      or InputModule.LEFT
	steps       = steps       or 25
	duration    = duration    or 0.3
	easingStyle = easingStyle or "linear"
	InputModule.mouseMove(x1, y1)
	task.wait(0.03)
	InputModule.mouseDown(x1, y1, button)
	task.wait(0.05)
	local stepDelay = duration / steps
	for i = 1, steps do
		local t = i / steps
		local et
		if easingStyle == "easeInOut" then et = easeInOut(t)
		elseif easingStyle == "easeIn" then et = easeIn(t)
		elseif easingStyle == "easeOut" then et = easeOut(t)
		else et = t end
		InputModule.mouseMove(
			math.floor(lerp(x1, x2, et)),
			math.floor(lerp(y1, y2, et))
		)
		task.wait(stepDelay)
	end
	InputModule.mouseUp(x2, y2, button)
end

InputModule.dragAsync = function(x1, y1, x2, y2, button, steps, duration, easingStyle)
	task.spawn(function()
		InputModule.drag(x1, y1, x2, y2, button, steps, duration, easingStyle)
	end)
end

InputModule.scroll = function(x, y, amount, stepDelay)
	amount    = amount    or 1
	stepDelay = stepDelay or 0.02
	local up = amount > 0
	for _ = 1, math.abs(amount) do
		VIM:SendMouseWheelEvent(x, y, up, game)
		task.wait(stepDelay)
	end
end

InputModule.scrollHere = function(amount, stepDelay)
	local pos = UIS:GetMouseLocation()
	InputModule.scroll(pos.X, pos.Y, amount, stepDelay)
end

InputModule.scrollSmooth = function(x, y, amount, duration)
	duration = duration or 0.5
	local steps = math.max(1, math.abs(amount))
	local delay = duration / steps
	local up = amount > 0
	for _ = 1, steps do
		VIM:SendMouseWheelEvent(x, y, up, game)
		task.wait(delay)
	end
end

InputModule.clickAndHold = function(x, y, duration, button)
	button   = button   or InputModule.LEFT
	duration = duration or 1
	InputModule.mouseMove(x, y)
	task.wait(0.02)
	InputModule.mouseDown(x, y, button)
	task.wait(duration)
	InputModule.mouseUp(x, y, button)
end

InputModule.swipe = function(x1, y1, x2, y2, duration)
	InputModule.drag(x1, y1, x2, y2, InputModule.LEFT, 30, duration or 0.2, "easeOut")
end

InputModule.getMousePos = function()
	local pos = UIS:GetMouseLocation()
	return {x = pos.X, y = pos.Y}
end

InputModule.getMouseX = function()
	return UIS:GetMouseLocation().X
end

InputModule.getMouseY = function()
	return UIS:GetMouseLocation().Y
end

InputModule.getScreenCenter = function()
	local vp = workspace.CurrentCamera.ViewportSize
	return {x = math.floor(vp.X / 2), y = math.floor(vp.Y / 2)}
end

InputModule.getScreenSize = function()
	local vp = workspace.CurrentCamera.ViewportSize
	return {width = vp.X, height = vp.Y}
end

InputModule.screenFraction = function(fx, fy)
	local vp = workspace.CurrentCamera.ViewportSize
	return math.floor(vp.X * fx), math.floor(vp.Y * fy)
end

InputModule.waitForClick = function(button, timeout)
	local targetType
	if (button or InputModule.LEFT) == InputModule.RIGHT then
		targetType = Enum.UserInputType.MouseButton2
	elseif (button or InputModule.LEFT) == InputModule.MIDDLE then
		targetType = Enum.UserInputType.MouseButton3
	else
		targetType = Enum.UserInputType.MouseButton1
	end
	local done, px, py = false, nil, nil
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if input.UserInputType == targetType then
			px   = math.floor(input.Position.X)
			py   = math.floor(input.Position.Y)
			done = true
			conn:Disconnect()
		end
	end)
	local elapsed = 0
	local step    = 0.05
	while not done do
		task.wait(step)
		elapsed = elapsed + step
		if timeout and elapsed >= timeout then
			conn:Disconnect()
			return nil, nil
		end
	end
	return px, py
end

InputModule.clickCFrame = function(cf, button, holdTime)
	local sp, onScreen = cfScreen(cf)
	if not onScreen then
		warn("[Input] clickCFrame: position is off-screen.")
		return false
	end
	InputModule.click(math.floor(sp.X), math.floor(sp.Y), button, holdTime)
	return true
end

InputModule.clickCFrameAsync = function(cf, button, holdTime)
	task.spawn(function()
		InputModule.clickCFrame(cf, button, holdTime)
	end)
end

InputModule.clickPart = function(part, button, holdTime)
	if not part or not part:IsA("BasePart") then
		warn("[Input] clickPart: expected a BasePart, got "..tostring(part))
		return false
	end
	return InputModule.clickCFrame(part.CFrame, button, holdTime)
end

InputModule.clickPartAsync = function(part, button, holdTime)
	task.spawn(function()
		InputModule.clickPart(part, button, holdTime)
	end)
end

InputModule.clickPosition = function(worldPos, button, holdTime)
	local sp, onScreen = screenPos(worldPos)
	if not onScreen then
		warn("[Input] clickPosition: position is off-screen.")
		return false
	end
	InputModule.click(math.floor(sp.X), math.floor(sp.Y), button, holdTime)
	return true
end

InputModule.clickPositionAsync = function(worldPos, button, holdTime)
	task.spawn(function()
		InputModule.clickPosition(worldPos, button, holdTime)
	end)
end

InputModule.clickModel = function(model, button, holdTime)
	if not model or not model:IsA("Model") then
		warn("[Input] clickModel: expected a Model.")
		return false
	end
	local cf, size = model:GetBoundingBox()
	return InputModule.clickCFrame(cf, button, holdTime)
end

InputModule.hoverCFrame = function(cf, duration)
	local sp, onScreen = cfScreen(cf)
	if not onScreen then return false end
	InputModule.mouseMove(math.floor(sp.X), math.floor(sp.Y))
	if duration then task.wait(duration) end
	return true
end

InputModule.hoverPart = function(part, duration)
	if not part or not part:IsA("BasePart") then return false end
	return InputModule.hoverCFrame(part.CFrame, duration)
end

InputModule.dragBetweenParts = function(partA, partB, button, steps, duration)
	local spA, onA = cfScreen(partA.CFrame)
	local spB, onB = cfScreen(partB.CFrame)
	if not onA or not onB then
		warn("[Input] dragBetweenParts: one or both parts are off-screen.")
		return false
	end
	InputModule.drag(
		math.floor(spA.X), math.floor(spA.Y),
		math.floor(spB.X), math.floor(spB.Y),
		button, steps, duration
	)
	return true
end

InputModule.moveToCFrame = function(cf, duration, easingStyle)
	local sp, onScreen = cfScreen(cf)
	if not onScreen then return false end
	InputModule.mouseMoveSmooth(math.floor(sp.X), math.floor(sp.Y), duration, easingStyle)
	return true
end

InputModule.moveToPart = function(part, duration, easingStyle)
	if not part or not part:IsA("BasePart") then return false end
	return InputModule.moveToCFrame(part.CFrame, duration, easingStyle)
end

InputModule.isOnScreen = function(cf)
	local _, onScreen = cfScreen(cf)
	return onScreen
end

InputModule.getScreenPos = function(cf)
	local sp, onScreen = cfScreen(cf)
	if onScreen then
		return math.floor(sp.X), math.floor(sp.Y)
	end
	return nil, nil
end

InputModule.getPartScreenPos = function(part)
	if not part or not part:IsA("BasePart") then return nil, nil end
	return InputModule.getScreenPos(part.CFrame)
end

InputModule.waitUntilOnScreen = function(cf, timeout)
	local elapsed = 0
	local step    = 0.1
	while not InputModule.isOnScreen(cf) do
		task.wait(step)
		elapsed = elapsed + step
		if timeout and elapsed >= timeout then return false end
	end
	return true
end

InputModule.clickWhenOnScreen = function(cf, button, holdTime, timeout)
	local visible = InputModule.waitUntilOnScreen(cf, timeout)
	if not visible then return false end
	return InputModule.clickCFrame(cf, button, holdTime)
end

InputModule.clickNearestPart = function(tag, button, holdTime)
	local player = Players.LocalPlayer
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		warn("[Input] clickNearestPart: local character not found.")
		return false
	end
	local bestPart, bestDist = nil, math.huge
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (not tag or obj.Name == tag) then
			local dist = (obj.Position - root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestPart = obj
			end
		end
	end
	if not bestPart then
		warn("[Input] clickNearestPart: no part found.")
		return false
	end
	return InputModule.clickPart(bestPart, button, holdTime)
end

InputModule.newMacro = function(name)
	local m = {
		name    = name or ("macro_"..tostring(tick())),
		actions = {},
		speed   = 1.0,
		loops   = 1,
		enabled = true,
	}
	if name then macroStore[name] = m end
	return m
end

InputModule.addKey = function(macro, key, holdTime, delay)
	table.insert(macro.actions, {
		type     = "tap",
		key      = key,
		holdTime = holdTime or 0.05,
		delay    = delay    or 0,
	})
end

InputModule.addKeyDown = function(macro, key, delay)
	table.insert(macro.actions, {type="keydown", key=key, delay=delay or 0})
end

InputModule.addKeyUp = function(macro, key, delay)
	table.insert(macro.actions, {type="keyup", key=key, delay=delay or 0})
end

InputModule.addClick = function(macro, x, y, button, holdTime, delay)
	table.insert(macro.actions, {
		type     = "click",
		x        = x,
		y        = y,
		button   = button   or InputModule.LEFT,
		holdTime = holdTime or 0.05,
		delay    = delay    or 0,
	})
end

InputModule.addRightClick = function(macro, x, y, holdTime, delay)
	InputModule.addClick(macro, x, y, InputModule.RIGHT, holdTime, delay)
end

InputModule.addDoubleClick = function(macro, x, y, delay)
	table.insert(macro.actions, {type="doubleclick", x=x, y=y, delay=delay or 0})
end

InputModule.addTripleClick = function(macro, x, y, delay)
	table.insert(macro.actions, {type="tripleclick", x=x, y=y, delay=delay or 0})
end

InputModule.addCFrameClick = function(macro, cf, button, holdTime, delay)
	table.insert(macro.actions, {
		type     = "cfclick",
		cf       = cf,
		button   = button   or InputModule.LEFT,
		holdTime = holdTime or 0.05,
		delay    = delay    or 0,
	})
end

InputModule.addPartClick = function(macro, part, button, holdTime, delay)
	table.insert(macro.actions, {
		type     = "partclick",
		part     = part,
		button   = button   or InputModule.LEFT,
		holdTime = holdTime or 0.05,
		delay    = delay    or 0,
	})
end

InputModule.addMove = function(macro, x, y, delay)
	table.insert(macro.actions, {type="move", x=x, y=y, delay=delay or 0})
end

InputModule.addSmoothMove = function(macro, x, y, duration, easing, delay)
	table.insert(macro.actions, {
		type     = "smoothmove",
		x        = x,
		y        = y,
		duration = duration or 0.3,
		easing   = easing   or "linear",
		delay    = delay    or 0,
	})
end

InputModule.addScroll = function(macro, x, y, amount, delay)
	table.insert(macro.actions, {type="scroll", x=x, y=y, amount=amount or 1, delay=delay or 0})
end

InputModule.addScrollHere = function(macro, amount, delay)
	table.insert(macro.actions, {type="scrollhere", amount=amount or 1, delay=delay or 0})
end

InputModule.addWait = function(macro, duration)
	table.insert(macro.actions, {type="wait", duration=duration})
end

InputModule.addCombo = function(macro, keys, releaseDelay, delay)
	table.insert(macro.actions, {
		type         = "combo",
		keys         = keys,
		releaseDelay = releaseDelay or 0.05,
		delay        = delay        or 0,
	})
end

InputModule.addText = function(macro, text, interval, randomize, delay)
	table.insert(macro.actions, {
		type      = "text",
		text      = text,
		interval  = interval  or 0.05,
		randomize = randomize or false,
		delay     = delay     or 0,
	})
end

InputModule.addDrag = function(macro, x1, y1, x2, y2, button, steps, duration, easing, delay)
	table.insert(macro.actions, {
		type     = "drag",
		x1       = x1,
		y1       = y1,
		x2       = x2,
		y2       = y2,
		button   = button   or InputModule.LEFT,
		steps    = steps    or 25,
		duration = duration or 0.3,
		easing   = easing   or "linear",
		delay    = delay    or 0,
	})
end

InputModule.addSwipe = function(macro, x1, y1, x2, y2, duration, delay)
	table.insert(macro.actions, {
		type     = "swipe",
		x1       = x1, y1=y1, x2=x2, y2=y2,
		duration = duration or 0.2,
		delay    = delay    or 0,
	})
end

InputModule.addRepeat = function(macro, innerMacro, times)
	table.insert(macro.actions, {type="repeat", macro=innerMacro, times=times or 1})
end

InputModule.addCondition = function(macro, condFunc, trueMacro, falseMacro)
	table.insert(macro.actions, {
		type       = "condition",
		condFunc   = condFunc,
		trueMacro  = trueMacro,
		falseMacro = falseMacro,
	})
end

InputModule.addLabel = function(macro, labelName)
	table.insert(macro.actions, {type="label", label=labelName})
end

InputModule.addGoto = function(macro, labelName, times)
	table.insert(macro.actions, {type="goto", label=labelName, times=times or 1, _count=0})
end

InputModule.addReleaseAll = function(macro, delay)
	table.insert(macro.actions, {type="releaseall", delay=delay or 0})
end

InputModule.addSpam = function(macro, key, times, interval, delay)
	table.insert(macro.actions, {
		type     = "spam",
		key      = key,
		times    = times    or 5,
		interval = interval or 0.05,
		delay    = delay    or 0,
	})
end

InputModule.addSequence = function(macro, keyList, interval, delay)
	table.insert(macro.actions, {
		type     = "sequence",
		keyList  = keyList,
		interval = interval or 0.1,
		delay    = delay    or 0,
	})
end

InputModule.runMacro = function(macro, overrideLoops, overrideSpeed)
	if not macro.enabled then return end
	local loops = overrideLoops or macro.loops or 1
	local speed = overrideSpeed or macro.speed or 1.0
	_stats.macrosRun = _stats.macrosRun + 1

	local labels = {}
	for i, action in ipairs(macro.actions) do
		if action.type == "label" then
			labels[action.label] = i
		end
	end

	local function runActions(actions)
		local i = 1
		while i <= #actions do
			local action = actions[i]

			if action.delay and action.delay > 0 then
				task.wait(action.delay / speed)
			end

			if action.type == "tap" then
				InputModule.tap(action.key, (action.holdTime or 0.05) / speed)

			elseif action.type == "keydown" then
				InputModule.keyDown(action.key)

			elseif action.type == "keyup" then
				InputModule.keyUp(action.key)

			elseif action.type == "click" then
				InputModule.click(action.x, action.y, action.button, (action.holdTime or 0.05) / speed)

			elseif action.type == "doubleclick" then
				InputModule.doubleClick(action.x, action.y)

			elseif action.type == "tripleclick" then
				InputModule.tripleClick(action.x, action.y)

			elseif action.type == "cfclick" then
				InputModule.clickCFrame(action.cf, action.button, (action.holdTime or 0.05) / speed)

			elseif action.type == "partclick" then
				InputModule.clickPart(action.part, action.button, (action.holdTime or 0.05) / speed)

			elseif action.type == "move" then
				InputModule.mouseMove(action.x, action.y)

			elseif action.type == "smoothmove" then
				InputModule.mouseMoveSmooth(action.x, action.y, (action.duration or 0.3) / speed, action.easing)

			elseif action.type == "scroll" then
				InputModule.scroll(action.x, action.y, action.amount)

			elseif action.type == "scrollhere" then
				InputModule.scrollHere(action.amount)

			elseif action.type == "wait" then
				task.wait((action.duration or 0.1) / speed)

			elseif action.type == "combo" then
				InputModule.combo(action.keys, nil, action.releaseDelay)

			elseif action.type == "text" then
				InputModule.typeText(action.text, (action.interval or 0.05) / speed, action.randomize)

			elseif action.type == "drag" then
				InputModule.drag(
					action.x1, action.y1, action.x2, action.y2,
					action.button, action.steps,
					(action.duration or 0.3) / speed, action.easing
				)

			elseif action.type == "swipe" then
				InputModule.swipe(action.x1, action.y1, action.x2, action.y2, (action.duration or 0.2) / speed)

			elseif action.type == "repeat" then
				for _ = 1, action.times do
					runActions(action.macro.actions)
				end

			elseif action.type == "condition" then
				if action.condFunc() then
					if action.trueMacro then runActions(action.trueMacro.actions) end
				else
					if action.falseMacro then runActions(action.falseMacro.actions) end
				end

			elseif action.type == "releaseall" then
				InputModule.releaseAll()

			elseif action.type == "spam" then
				InputModule.spam(action.key, action.times, (action.interval or 0.05) / speed)

			elseif action.type == "sequence" then
				InputModule.sequence(action.keyList, (action.interval or 0.1) / speed)

			elseif action.type == "goto" then
				local target = labels[action.label]
				if target then
					action._count = (action._count or 0) + 1
					if action._count <= action.times then
						i = target
					else
						action._count = 0
					end
				end

			elseif action.type == "label" then
				-- just a marker, nothing to execute

			end

			i = i + 1
		end
	end

	for loop = 1, loops do
		runActions(macro.actions)
	end
end

InputModule.runMacroAsync = function(macro, overrideLoops, overrideSpeed)
	task.spawn(function()
		InputModule.runMacro(macro, overrideLoops, overrideSpeed)
	end)
end

InputModule.saveMacro = function(name, macro)
	macroStore[name] = macro
	macro.name       = name
end

InputModule.loadMacro = function(name)
	return macroStore[name]
end

InputModule.listMacros = function()
	local names = {}
	for k in pairs(macroStore) do
		table.insert(names, k)
	end
	table.sort(names)
	return names
end

InputModule.deleteMacro = function(name)
	macroStore[name] = nil
end

InputModule.clearMacro = function(macro)
	macro.actions = {}
end

InputModule.copyMacro = function(macro, newName)
	local copy = {
		name    = newName or (macro.name.."_copy"),
		actions = {},
		speed   = macro.speed,
		loops   = macro.loops,
		enabled = macro.enabled,
	}
	for _, action in ipairs(macro.actions) do
		local a = {}
		for k, v in pairs(action) do a[k] = v end
		table.insert(copy.actions, a)
	end
	if newName then macroStore[newName] = copy end
	return copy
end

InputModule.mergeMacros = function(macroA, macroB, newName)
	local merged = InputModule.copyMacro(macroA, newName)
	for _, action in ipairs(macroB.actions) do
		local a = {}
		for k, v in pairs(action) do a[k] = v end
		table.insert(merged.actions, a)
	end
	return merged
end

InputModule.startRecording = function(name)
	macroActions = {}
	recordStart  = tick()
	recording    = true

	for _, conn in ipairs(recConnections) do conn:Disconnect() end
	recConnections = {}

	table.insert(recConnections, UIS.InputBegan:Connect(function(input)
		if not recording then return end
		local t = tick() - recordStart
		if input.UserInputType == Enum.UserInputType.Keyboard then
			table.insert(macroActions, {time=t, type="keyDown", key=tostring(input.KeyCode)})
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(macroActions, {time=t, type="mouseDown", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=0})
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			table.insert(macroActions, {time=t, type="mouseDown", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=1})
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			table.insert(macroActions, {time=t, type="mouseDown", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=2})
		end
	end))

	table.insert(recConnections, UIS.InputEnded:Connect(function(input)
		if not recording then return end
		local t = tick() - recordStart
		if input.UserInputType == Enum.UserInputType.Keyboard then
			table.insert(macroActions, {time=t, type="keyUp", key=tostring(input.KeyCode)})
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(macroActions, {time=t, type="mouseUp", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=0})
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			table.insert(macroActions, {time=t, type="mouseUp", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=1})
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			table.insert(macroActions, {time=t, type="mouseUp", x=math.floor(input.Position.X), y=math.floor(input.Position.Y), button=2})
		end
	end))

	table.insert(recConnections, UIS.InputChanged:Connect(function(input)
		if not recording then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local t = tick() - recordStart
			table.insert(macroActions, {time=t, type="mouseMove", x=math.floor(input.Position.X), y=math.floor(input.Position.Y)})
		end
	end))

	print("[Input] Recording started: "..(name or "unnamed"))
end

InputModule.stopRecording = function(saveName)
	recording = false
	for _, conn in ipairs(recConnections) do conn:Disconnect() end
	recConnections = {}
	print("[Input] Recording stopped. "..#macroActions.." actions captured.")
	if saveName then
		macroStore[saveName] = {name=saveName, recorded=true, actions=macroActions, loops=1, speed=1.0, enabled=true}
		_stats.recordingsSaved = _stats.recordingsSaved + 1
	end
	return macroActions
end

InputModule.isRecording = function()
	return recording
end

InputModule.getLastRecording = function()
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
						local kc = safeKeyCode(kname)
						if kc then VIM:SendKeyEvent(true, kc, false, game) end
					end
				elseif action.type == "keyUp" then
					local kname = tostring(action.key):match("KeyCode%.(.+)")
					if kname then
						local kc = safeKeyCode(kname)
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

InputModule.playRecordingAsync = function(actions, speed, loops)
	task.spawn(function()
		InputModule.playRecording(actions, speed, loops)
	end)
end

InputModule.bindHotkey = function(key, callback, label)
	hotkeyBinds[key] = {func=callback, label=label or key}
	if not hotkeyConn then
		hotkeyConn = UIS.InputBegan:Connect(function(input, gpe)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local kname = tostring(input.KeyCode):match("KeyCode%.(.+)")
				if kname and hotkeyBinds[kname] then
					task.spawn(hotkeyBinds[kname].func)
				end
			end
		end)
	end
end

InputModule.bindHotkeyCombo = function(keys, callback)
	local sorted = {}
	for _, k in ipairs(keys) do table.insert(sorted, k) end
	table.sort(sorted)
	local comboKey = table.concat(sorted, "+")
	hotkeyBinds["__COMBO__"..comboKey] = {func=callback, label=comboKey, isCombo=true, keys=keys}

	UIS.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local allHeld = true
			for _, k in ipairs(keys) do
				if not InputModule.isKeyHeld(k) and tostring(input.KeyCode) ~= "Enum.KeyCode."..k then
					allHeld = false
					break
				end
			end
			if allHeld then
				task.spawn(callback)
			end
		end
	end)
end

InputModule.unbindHotkey = function(key)
	hotkeyBinds[key] = nil
end

InputModule.unbindAll = function()
	hotkeyBinds = {}
	if hotkeyConn then
		hotkeyConn:Disconnect()
		hotkeyConn = nil
	end
end

InputModule.listHotkeys = function()
	local list = {}
	for k, v in pairs(hotkeyBinds) do
		table.insert(list, k.." -> "..(v.label or "unnamed"))
	end
	return list
end

InputModule.wait = function(seconds)
	task.wait(seconds)
end

InputModule.waitRandom = function(minTime, maxTime)
	task.wait(minTime + math.random() * (maxTime - minTime))
end

InputModule.repeatAction = function(times, interval, callback)
	for i = 1, times do
		callback(i)
		if i < times and interval > 0 then
			task.wait(interval)
		end
	end
end

InputModule.repeatAsync = function(times, interval, callback)
	task.spawn(function()
		InputModule.repeatAction(times, interval, callback)
	end)
end

InputModule.loop = function(interval, callback)
	local running = true
	local thread  = task.spawn(function()
		while running do
			local ok, err = pcall(callback)
			if not ok then
				warn("[Input] loop error: "..tostring(err))
			end
			task.wait(interval)
		end
	end)
	return function()
		running = false
		pcall(function() task.cancel(thread) end)
	end
end

InputModule.loopFor = function(duration, interval, callback)
	local stop    = false
	local endTime = tick() + duration
	local thread  = task.spawn(function()
		while not stop and tick() < endTime do
			local ok, err = pcall(callback)
			if not ok then warn("[Input] loopFor error: "..tostring(err)) end
			task.wait(interval)
		end
	end)
	return function()
		stop = true
		pcall(function() task.cancel(thread) end)
	end
end

InputModule.loopTimes = function(times, interval, callback)
	local thread = task.spawn(function()
		for i = 1, times do
			local ok, err = pcall(callback, i)
			if not ok then warn("[Input] loopTimes error: "..tostring(err)) end
			if i < times then task.wait(interval) end
		end
	end)
	return thread
end

InputModule.onKey = function(key, callback)
	local kc = resolveKey(key)
	if not kc then return nil end
	return UIS.InputBegan:Connect(function(input, gpe)
		if input.KeyCode == kc then
			task.spawn(callback)
		end
	end)
end

InputModule.onKeyRelease = function(key, callback)
	local kc = resolveKey(key)
	if not kc then return nil end
	return UIS.InputEnded:Connect(function(input)
		if input.KeyCode == kc then
			task.spawn(callback)
		end
	end)
end

InputModule.onMouseClick = function(button, callback)
	local targetType
	if (button or InputModule.LEFT) == InputModule.RIGHT then
		targetType = Enum.UserInputType.MouseButton2
	elseif (button or InputModule.LEFT) == InputModule.MIDDLE then
		targetType = Enum.UserInputType.MouseButton3
	else
		targetType = Enum.UserInputType.MouseButton1
	end
	return UIS.InputBegan:Connect(function(input)
		if input.UserInputType == targetType then
			task.spawn(function()
				callback(math.floor(input.Position.X), math.floor(input.Position.Y))
			end)
		end
	end)
end

InputModule.getStats = function()
	return {
		taps           = _stats.taps,
		clicks         = _stats.clicks,
		macrosRun      = _stats.macrosRun,
		recordingsSaved = _stats.recordingsSaved,
	}
end

InputModule.resetStats = function()
	_stats = {taps=0, clicks=0, macrosRun=0, recordingsSaved=0}
end

InputModule.printStats = function()
	local s = InputModule.getStats()
	print(string.format(
		"[Input] Stats | Taps: %d | Clicks: %d | Macros run: %d | Recordings saved: %d",
		s.taps, s.clicks, s.macrosRun, s.recordingsSaved
	))
end

InputModule.listKeys = function()
	local keys = {}
	for k in pairs(KeyMap) do table.insert(keys, k) end
	table.sort(keys)
	print("[Input] Available keys: "..table.concat(keys, ", "))
	return keys
end

InputModule.hasKey = function(key)
	return KeyMap[key] ~= nil
end

InputModule.getVersion = function()
	return InputModule.VERSION
end

print(string.format("[InputModule v%s].", InputModule.VERSION))

return InputModule
