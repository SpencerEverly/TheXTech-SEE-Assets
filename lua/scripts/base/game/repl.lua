local repl = {}

local unpack = _G.unpack or table.unpack
local memo_mt = {__mode = "k"} --recommended by Rednaxela

local blinker = 0

function table.reverse(t)
    local len = 0
    for k,_ in ipairs(t) do
        len = k
    end
    local rt = {}
    for i = 1, len do
        rt[len - i + 1] = t[i]
    end
    return rt
end

function string.split2(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Memoize a function with one argument.
local function memoize(func)
	local t = {}
	setmetatable(t, memo_mt)
	return function(x)
		if t[x] then
			return unpack(t[x])
		else
			local ret = {func(x)}
			t[x] = ret
			return unpack(ret)
		end
	end
end

-- Splits a string at a position.
local function split(str, idx)
	return str:sub(1, idx), str:sub(idx + 1)
end

------------
-- SYNTAX --
------------

local repl_env = {}
local repl_mt = {__index = {}}
setmetatable(repl_env, repl_mt)

local rawload = load
local function load(str)
	return rawload(str, str, "t", repl_env)
end
load = memoize(load)

-- Check whether a string is syntactically valid Lua.
local function isValid(str)
	return not not load(str)
end
isValid = memoize(isValid)

-- Check whether a string is a valid Lua expression.
local function isExpression(str)
	return isValid("return " .. str .. ";")
end
isExpression = memoize(isExpression)

-- Check whether a string is a valid Lua function call.
-- Anything that's both an expression and a chunk is a function call.
local function isFunctionCall(str)
	return isExpression(str) and isValid(str)
end
isFunctionCall = memoize(isFunctionCall)

-- Create a shallow copy of a list, missing the first entry.
local function trim(t)
	local ret = {}
	for k,v in ipairs(t) do
		if k ~= 1 then
			ret[k - 1] = v
		end
	end
	return ret
end

---------------------------
-- CONSOLE FUNCTIONALITY --
---------------------------


repl.log = {}
repl.history = {}
repl.buffer = ""
repl.historyPos = 0
repl.cursorPos = 0

local function printString(str)
	if str == nil then
		str = ""
	end
	if str:find("/br") then
		for k,v in ipairs(str:split("/br")) do
			table.insert(repl.log, v)
		end
	elseif str then
		table.insert(repl.log, str)
	end
end

local function printValues(vals)
	if next(vals, nil) == nil then
		return
	end
	local t = {}
	local multiline = false
	local maxIdx = 0
	for k,v in pairs(vals) do
		maxIdx = math.max(maxIdx, k)
		t[k] = inspect(v)
		if t[k]:find("/br") then
			multiline = true
		end
	end
	if multiline then
		for i = 1, maxIdx do
			printString(t[i] or "nil")
		end
	else
		local s = ""
		for i = 1, maxIdx do
			if s ~= "" then
				s = s .. " "
			end
			s = s .. (t[i] or "nil")
		end
		printString(s)
	end
end

_G.rawprint = print
function _G.print(...)
	printValues{...}
end

local function printError(err)
	printString("error: " .. err:gsub("%[?.*%]?:%d+: ", "", 1))
end

local function exec(block)
	local chunk = load(block)
	local x = {pcall(chunk)}
	local success = x[1]
	local vals = trim(x)
	if success then
		printValues(vals)
	else
		printError(vals[1])
	end
end

local function eval(expr)
	local chunk = load("return " .. expr .. ";")
	local x = {pcall(chunk)}
	local success = x[1]
	local vals = trim(x)
	if success then
		printValues(vals)
		if next(vals, nil) == nil and not isFunctionCall(expr) then
			printString("nil")
		end
	else
		printError(vals[1])
	end
end

local function cmd(str)
	if isExpression(str) then
		eval(str)
	elseif isValid(str) then
		exec(str)
	else
		printError(select(2, load(str)))
	end
end

function repl.cmd()
	local isIncomplete = false
	if not isExpression(repl.buffer) then
		local _, err = load(repl.buffer)
		if err then
			isIncomplete = err:match("expected near '<eof>'$") or err:match("'end' expected")
		end
	end
	if isIncomplete then
		repl.buffer = repl.buffer .. "/br"
		repl.cursorPos = #repl.buffer
		return
	end
	printString(">" .. repl.buffer:gsub("/br", "/br "))
	if repl.buffer ~= "" then
		table.insert(repl.history, repl.buffer)
		cmd(repl.buffer)
		repl.buffer = ""
		repl.historyPos = 0
		repl.cursorPos = 0
	end
end

-----------------------------
-- SMBX ENGINE INTEGRATION --
-----------------------------

local event_tbl = {}
function repl_mt.__newindex(t, k, v)
	if Misc.LUNALUA_EVENTS_TBL[k] then
		if type(v) == "function" and type(event_tbl[k]) ~= "function" then
			registerEvent(event_tbl, k)
		elseif type(event_tbl[k]) == "function" and type(v) ~= "function" then
			unregisterEvent(event_tbl, k)
		end
		event_tbl[k] = v
	else
		_G[k] = v
	end
end

repl.active = false
repl.activeInEpisode = true
repl.background = 1

registerEvent(repl, "onKeyboardPress")
registerEvent(repl, "onDrawPaint")
registerEvent(repl, "onPasteText")

function repl.onKeyboardPress(vk, repeated, chara)
	if not (repl.activeInEpisode) then return end

	if not repl.active then
		if (vk == VK_TAB) and (repeated == 0) then
            Misc.cheatBuffer("")
			repl.active = true
			Misc.pause()
		end
		return
	end
	
	if vk == VK_TAB or vk == VK_ESCAPE then
		if (repeated == 0) then
			Misc.unpause()
			repl.active = false
		end
	elseif vk == VK_RETURN then
		if vk == VK_SHIFT and repeated > 0 then
			local left, right = split(repl.buffer, repl.cursorPos)
			repl.buffer = left .. "/br" .. right
			repl.cursorPos = repl.cursorPos + 1
			blinker = 1
		else
			repl.cmd()
		end
	elseif vk == VK_BACK then
		local left, right = split(repl.buffer, repl.cursorPos)
		repl.buffer = left:sub(1, -2) .. right
		repl.cursorPos = math.max(0, repl.cursorPos - 1)
		blinker = 1
	elseif vk == VK_DELETE then
		local left, right = split(repl.buffer, repl.cursorPos)
		repl.buffer = left .. right:sub(2)
		blinker = 1
	elseif vk == VK_UP or vk == VK_DOWN then
		if vk == VK_UP then
			repl.historyPos = math.min(repl.historyPos + 1, #repl.history)
		elseif vk == VK_DOWN then
			repl.historyPos = math.max(0, repl.historyPos - 1)
		end
		if repl.historyPos == 0 then
			repl.buffer = ""
		else
			repl.buffer = repl.history[#repl.history - repl.historyPos + 1]
		end
		repl.cursorPos = #repl.buffer
		blinker = 1
	elseif vk == VK_LEFT then
		repl.cursorPos = math.max(0, repl.cursorPos - 1)
		blinker = 1
	elseif vk == VK_RIGHT then
		repl.cursorPos = math.min(repl.cursorPos + 1, #repl.buffer)
		blinker = 1
	elseif vk == VK_HOME then
		if Misc.GetKeyState(VK_MENU) then
			--repl.resetFontSize()
		else
			repl.cursorPos = 0
			blinker = 1
		end
	elseif vk == VK_END then
		repl.cursorPos = #repl.buffer
		blinker = 1
	elseif vk == VK_PRIOR then
		--repl.increaseFontSize(0.1)
	elseif vk == VK_NEXT then
		--repl.decreaseFontSize(0.1)
	elseif chara ~= "" and #chara <= 1 then
		local left, right = split(repl.buffer, repl.cursorPos)
		repl.buffer = left .. chara .. right
		repl.cursorPos = repl.cursorPos + #chara
		blinker = 1
    elseif vk == VK_SPACE then
        local left, right = split(repl.buffer, repl.cursorPos)
		repl.buffer = left .. " " .. right
		repl.cursorPos = repl.cursorPos + 1
		blinker = 1
    end
	Misc.cheatBuffer("")
end

function repl.onPasteText(pastedText)
	local left, right = split(repl.buffer, repl.cursorPos)
	repl.buffer = left .. pastedText .. right
	repl.cursorPos = repl.cursorPos + #pastedText
	blinker = 1
end

do
	local gtltreplace = {["<"] = "<lt>", [">"] = "<gt>", ["/br"] = "/br"}
	
	local xscale = 2
	local yscale = 2
	
	local glyphwid = (9 + 1)*2
	
	local gsub = string.gsub
	local sub = string.sub
	local split = string.split2
	local find = string.find

	local bgobj = {color = repl.background, priority = 10}
	local printlist = {}
	local listidx = 1
	local function addprint(v)
		printlist[listidx] = v
		listidx = listidx + 1
	end
	local baseX, baseY = 0, 582
    
    local function _print(str, x, y)
		Text.print(str, x, y)
	end
	
	function repl.onDrawPaint()
		if not repl.active then
			return
		end
		
		Graphics.drawScreen(0, 0, 0, 0.5, true)
		local buffer
		if string.find(repl.buffer, "/br") then
			buffer = string.split2(repl.buffer, "/br")
		else
			buffer = {repl.buffer}
		end

		local y = baseY
		for i = #buffer, 1, -1 do
			if (i ~= #buffer) then
				y = y - 9*2
				addprint("/br")
			end
			if y < 0 then
				break
			end
			addprint(buffer[i])
			if i == 1 then
				addprint(">")
			else
				addprint(" ")
			end
		end
		
		if blinker > 0 then
			local x = baseX + glyphwid/2
			local y = y
			if #buffer > 1 then
				local t = 0
				for i = 1, #buffer do
					local nt = t + #(buffer[i]) + 1
					if nt > repl.cursorPos then
						x = x + (glyphwid * (repl.cursorPos - t))
						break
					elseif nt == repl.cursorPos then
						x = baseX + 4*xscale
						y = y + 9*yscale
						break
					end
					y = y + 9*yscale
					t = nt
				end
			else
				x = x + (glyphwid * repl.cursorPos)
			end
			_print("|", x, y)
		end
		blinker = blinker + 1
		if blinker > 32 then
			blinker = -32
		end
		
		for i = #repl.log, 1, -1 do
			y = y - 18
			addprint("/br")
			if y < 0 then
				break
			end
			addprint(repl.log[i])
		end

		printlist[listidx] = nil
		listidx = 1
		
        for i = 1,#printlist do
            _print(printlist[i], baseX + 15, baseY - (i * 26) + 25)
        end
	end
end

return repl