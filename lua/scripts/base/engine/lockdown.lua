local lockdown = {}
lockdown.defaultLoadEnv = {}

------------------
-- Lock down io --
------------------
do
	local error = error
	local nativeIO = io
	local newIO = {}
	
	local string_find = string.find
	local string_lower = string.lower
	local string_gsub = string.gsub
	local string_match = string.match
	local string_len = string.len
	local string_byte = string.byte
	local string_sub = string.sub
	
	local function makeSafeAbsolutePath(path)
		local ptr = LunaDLL.LunaLuaMakeSafeAbsolutePath(path)
		if ptr == nil then
			error("Invalid path!\nPath: " .. path)
			return nil, false
		end
		
		return ffi.string(ptr.path, ptr.len), ptr.canWrite
	end
    
    
	
	local validOpenModes = {["r"]=true, ["w"]=true, ["a"]=true, ["r+"]=true, ["w+"]=true, ["a+"]=true}
	newIO.close = nativeIO.close
	newIO.read = nativeIO.read
	newIO.flush = nativeIO.flush
	newIO.type = nativeIO.type
	newIO.open = function(path, mode)
		local canWrite
		path, canWrite = makeSafeAbsolutePath(path)
		
		-- Make sure the mode is good
		if mode == nil then
			mode = "r"
		end
		mode = string_lower(mode)
		if not validOpenModes[mode] then
			error("Invalid open mode!")
			return nil
		end
		if (mode ~= "r") and not canWrite then
			error("Writing to '" .. path .. "' is not allowed.")
			return nil
		end
		
		return nativeIO.open(path, mode)
	end
	newIO.lines = function(path)
		local canWrite
		path, canWrite = makeSafeAbsolutePath(path)
		
		return nativeIO.lines(path)
	end
	newIO.makeSafeAbsolutePath = makeSafeAbsolutePath
	
	io = newIO
	_G.io = newIO
end

------------------
-- Lock down os --
------------------
if os ~= nil then
    local makeSafeAbsolutePath = io.makeSafeAbsolutePath
	local nativeOS = os
	local newOS = {}
	newOS.clock = nativeOS.clock
	newOS.date = nativeOS.date
	newOS.time = nativeOS.time
	newOS.difftime = nativeOS.difftime
	newOS.exit = function() error("Shutdown") end
    
    local string_match = string.match
	
    local osRemove = nativeOS.remove
    local osRename = nativeOS.rename

    do
        newOS.remove = (function(filePath)
            local canWrite
            filePath, canWrite = makeSafeAbsolutePath(filePath)
            if canWrite then
                osRemove(filePath)
            else
                error("Removing at '" .. filePath .. "' is not allowed.")
                return
            end
        end)
        
        newOS.rename = (function(oldFilePath, newFilePath)  
            local canWrite1
            oldFilePath, canWrite1 = makeSafeAbsolutePath(oldFilePath)
            local canWrite2
            newFilePath, canWrite2 = makeSafeAbsolutePath(newFilePath)
            if canWrite1 and canWrite2 then
                osRename(oldFilePath, newFilePath)
            elseif not canWrite1 and canWrite2 then
                error("Renaming at '" .. oldFilePath .. "' is not allowed.")
                return
            elseif canWrite1 and not canWrite2 then
                error("Renaming at '" .. newFilePath .. "' is not allowed.")
                return
            end
        end)
    end
    
	os = newOS
	_G.os = newOS
end

-----------------------------------------------------------------------
-- Lock down a few extra functions that do filesystem related things --
-- (These only read to probably not really so necessary, but eh...)  --
-----------------------------------------------------------------------
do
	local type = type
	local makeSafeAbsolutePath = io.makeSafeAbsolutePath

	local function getCustomFolderPath()
		local dir = Native.getEpisodePath()
		if (not isOverworld) and (Level ~= nil) then
			local lvlName = Level.filename()
			local i = lvlName:match(".*%.()")
			if i ~= nil then
				lvlName = lvlName:sub(1,(i-2))
			end
			dir = dir .. lvlName .. "\\"
		end
		return dir
	end
	local customFolderPath = getCustomFolderPath()
	
	if Misc ~= nil then
		local nativeListFiles = Misc.listFiles
		if (nativeListFiles ~= nil) then
			function Misc.listFiles(path)
				path = makeSafeAbsolutePath(path)
				return nativeListFiles(path)
			end
			function Misc.listLocalFiles(path)
				path = makeSafeAbsolutePath(customFolderPath .. path)
				return nativeListFiles(path)
			end
		end
		
		local nativeListDirectories = Misc.listDirectories
		if (nativeListDirectories ~= nil) then
			function Misc.listDirectories(path)
				path = makeSafeAbsolutePath(path)
				return nativeListDirectories(path)
			end
			function Misc.listLocalDirectories(path)
				path = makeSafeAbsolutePath(customFolderPath .. path)
				return nativeListDirectories(path)
			end
		end
	end
end

--------------------------------
-- Lock down AsyncHTTPRequest --
-- (Not currently used...)    --
--------------------------------
do
	AsyncHTTPRequest = nil
	_G.AsyncHTTPRequest = nil
end

---------------------
-- Lock down debug --
---------------------
if debug ~= nil then
	local nativeDebug = debug
	local newDebug = {}
	
	-- Safe getfenv that only accepts 1 for an input
	function newDebug.getfenv(o)
		if (o == 1) then
			return nativeDebug.getfenv(2)
		end
		error("Only allowed to call getfenv(n) with n==1")
	end
	
	-- Functions passed through
	newDebug.getmetatable = nativeDebug.getmetatable
	newDebug.traceback = nativeDebug.traceback
	newDebug.getinfo = nativeDebug.getinfo
	
	debug = newDebug
	_G.debug = newDebug
	getfenv = newDebug.getfenv
	_G.getfenv = newDebug.getfenv
	
	function unpack_here(tbl)
		local ctx = nativeDebug.getfenv(2)
		for k, v in pairs(tbl) do
			ctx[k] = v
		end
	end
end

-- Utility code for reading a file
local cachedReadFile
local cachedReadFileLines
local cachedExists
do
	local string_gmatch = string.gmatch
	local makeSafeAbsolutePath = io.makeSafeAbsolutePath
	local ffi = require("ffi")
	ffi.cdef([[
		typedef struct
		{
			int len;
			char data[0];
		} ReadFileStruct;
		
		ReadFileStruct* LunaLuaCachedReadFile(const char* path);
		void LunaLuaFreeCachedReadFileData(ReadFileStruct* cpy);
		bool LunaLuaCachedExists(const char* path);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	function cachedReadFile(path)
		assert(path ~= nil, "Error reading file, invalid path was provided.")
		local ptr = LunaDLL.LunaLuaCachedReadFile(path);
		if ptr == nil then
			return nil
		end
		local ret = ffi.string(ptr.data, ptr.len)
		LunaDLL.LunaLuaFreeCachedReadFileData(ptr)
		return ret
	end
	
	function cachedReadFileLines(path)
		local data = cachedReadFile(path)
		if (data == nil) then
			return nil
		end
		
		local ret = {}	
		for line in string_gmatch(data, "([^\n\r]*)\r?\n?") do
			ret[#ret+1] = line
		end
		ret[#ret] = nil
		return ret
	end
	
	function cachedExists(path)
		local ret = LunaDLL.LunaLuaCachedExists(path)
		return ret
	end
end
io.readFile = cachedReadFile
io.readFileLines = cachedReadFileLines
io.exists = cachedExists
lockdown.readFile = cachedReadFile

-----------------------
-- Lock down globals --
-----------------------
do
	local type = type
	local error = error
	local nativeLoad = load
	local io_open = io.open
	_G.setfenv = nil
	_G.newproxy = nil
	
	local function safeLoad(s, chunkname, mode, env)
		if env == nil then
			env = lockdown.defaultLoadEnv
		end
		mode = "t" -- Force 't' mode
		return nativeLoad(s, chunkname, mode, env)
	end
	
	local function safeLoadFile(filename, mode, env)
		local s = cachedReadFile(filename)
		chunkname = "@" .. filename
		return safeLoad(s, chunkname, mode, env)
	end
	
	local function safeDoFile(filename)
		local func, err = safeLoadFile(filename)
		
		-- Handle error loading code
		if (func == nil) then
			error("Error: " .. err)
		end
		
		return func()
	end
	
	_G.load = safeLoad
	_G.dofile = safeDoFile
	_G.loadfile = safeLoadFile
	_G.loadstring = safeLoad
end

return lockdown
