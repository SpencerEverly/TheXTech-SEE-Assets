local load  = load
local setmetatable = setmetatable
local string_find = string.find
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_sub = string.sub
local string_len = string.len
local string_lower = string.lower
local string_byte = string.byte
local getSMBXPath = getSMBXPath
local _G = _G

-- Constant values
local smbxPath = getSMBXPath()

-- Function definitions
local isAbsolutePath
local normalizeRelPath
local readFile = io.readFile
local readFileFromPath
local makeRequire
local makeEnvironment
local makeGlobalContext

-- Function to check for an absolute path
function isAbsolutePath(possiblePath)
	return string_find(possiblePath, "%a:[/\\]") == 1 -- Either returns the first character with the matching search pattern or nil
end

-- Utility code to generate a normalized relative path
function normalizeRelPath(path, relBase)
	if (relBase == nil) then
		relBase = smbxPath
	end
	path = string_gsub(path, [[[\/]+]], [[/]])
	relBase = string_gsub(relBase, [[[\/]+]], [[/]])
	local relBaseLen = string_len(relBase)
	if (string_byte(relBase, relBaseLen) ~= string_byte([[/]], 1)) then
		relBase = relBase .. [[/]]
		relBaseLen = relBaseLen + 1
	end
	local pathStart = string_sub(path, 1, relBaseLen)
	if (string_lower(pathStart) == string_lower(relBase)) then
		path = string_sub(path, relBaseLen + 1)
	end
	return path
end

-- Utility code to read a file, searching by path
function readFileFromPath(path, name)
	if isAbsolutePath(name) then
		local fileData = readFile(name)
		
		if (fileData ~= nil) then
			return fileData, normalizeRelPath(name)
		end
	else
		name = string_gsub(name, "%.", "/")
		
		for entry in string_gmatch(path, "[^;]+") do
			-- Replace < with ; after seperation (special replacement)
			entry = string_gsub(entry, "<", ";")
			
			-- Substitute ? with
			entry = string_gsub(entry, "%?", name)
			
			--Text.windowDebugSimple(":::" .. entry)
			
			-- Try to load
			local fileData = readFile(entry)
			
			if (fileData ~= nil) then
				return fileData, normalizeRelPath(entry)
			end
		end
	end
	return nil, nil
end

function makeRequire(path, globalTable, loadedTable, shareGlobals, assignRequire, loadCallback, fallbackRequire, environmentCallback, debugstats, returnpath)
	-- Default arguments
	if (globalTable == nil) then
		globalTable = makeGlobalContext(_G)
	end
	if (loadedTable == nil) then
		loadedTable = {}
	end
	local preloadTable = {}
	
	local package = {loaded = loadedTable, preload = preloadTable, path = path}

	local function require(name)
		-- Load by loaded if possible
		if (loadedTable[string_lower(name)] ~= nil) then
			return loadedTable[string_lower(name)]
		end
		
		if (debugstats) then
			debugstats(string_lower(name))
		end
		
		-- Check preload table
		local preloadFunc = preloadTable[name] or preloadTable[string_lower(name)]
		if (preloadFunc) then
			local ret = preloadFunc()
			loadedTable[name] = ret
			loadedTable[string_lower(name)] = ret
			return ret
		end
		
		local fileData, filePath = readFileFromPath(package.path, name)
		
		if (fileData == nil) then
			if (fallbackRequire ~= nil) then
				return fallbackRequire(name)
			end
		
			error("module '" .. name .. "' not found", 1)
		end
		
		-- Load by loaded of the normalized path if possible
		local ret = loadedTable[string_lower(filePath)]
		if (ret ~= nil) then
			loadedTable[name] = ret
			loadedTable[string_lower(name)] = ret
			return ret
		end
	
		-- Declare environment 
		local environment
		if (shareGlobals) then
			environment = globalTable
		else
			environment = makeEnvironment(globalTable)
		end
		
		if (environmentCallback) then
			environmentCallback(name, environment)
		end
	
		-- Load the code
		local func, err = load(fileData, "@" .. filePath, "bt", environment)
		
		-- Handle error loading code
		if (func == nil) then
			error("Error: " .. err)
		end
		
		-- Run the code
		ret = func()
		
		-- Save the loaded
		ret = ret or {}
		loadedTable[name] = ret
		loadedTable[string_lower(name)] = ret
		loadedTable[string_lower(filePath)] = ret
		
		-- Call callback for loading
		if (loadCallback ~= nil) then
			loadCallback(name, filePath, ret, environment)
		end
		
		if returnpath then
			return ret, string_lower(filePath)
		else
			return ret
		end
	end
	
	if (assignRequire) then
		globalTable.require = require
		globalTable.package = package
	end
	
	return require, package
end

-- So... we have two environment implementations here, one for dynamic resolution but with performance penalty
-- and one where all environments are copies, but allowing _G to overwrite child context things
local dynamicEnvironments = false

if dynamicEnvironments then
	function makeEnvironment(context, extraFields)
		local env = {}
		local values = {}
		local locals = {}
		local children = {}
		
		setmetatable(env, {
			__index = function(tbl, key)
				if values[key] then
					return values[key]
				elseif locals[key] then
					return nil
				end
				return context[key]
			end,
			__newindex = function(tbl, key, value)
				values[key] = value
				locals[key] = true
			end
		})
		
		if (extraFields ~= nil) then
			for k,v in pairs(extraFields) do
				env[k] = v
			end
		end

		return env
	end

	function makeGlobalContext(context, extraFields)
		local env = makeEnvironment(context, extraFields)
		
		if (extraFields == nil) or (extraFields._G == nil) then
			env._G = env
		end
		
		return env
	end
end

if not dynamicEnvironments then
	local childEnvsByGlobal = setmetatable({}, {__mode = "k"})

	local function setAsChildEnv(env, g)
		local childEnvs = childEnvsByGlobal[g]
		if childEnvs ~= nil then
			childEnvs[#childEnvs+1] = env
		end
	end

	function makeEnvironment(templateEnv, extraFields, dontSetAsChild)
		local env = {}
		for k,v in pairs(templateEnv) do
			env[k] = v
		end
		
		if not dontSetAsChild then
			local templateGlobal = templateEnv._G
			if (childEnvsByGlobal[templateGlobal] ~= nil) then
				env._G = templateGlobal
				setAsChildEnv(env, templateGlobal)
			end
		end
		
		if (extraFields ~= nil) then
			for k,v in pairs(extraFields) do
				env[k] = v
			end
		end
		
		return env
	end

	function makeGlobalContext(templateEnv, extraFields)
		local sharedEnv = makeEnvironment(templateEnv, extraFields, true)
		
		local contextObj = {}
		local childEnvs = {}
		local globalObj = {}
		childEnvsByGlobal[globalObj] = childEnvs
		sharedEnv._G = globalObj
		setAsChildEnv(sharedEnv, globalObj)
		
		if (extraFields ~= nil) and (extraFields._G ~= nil) then
			childEnvs[#childEnvs+1] = extraFields._G
		end
		
		setmetatable(globalObj, {
			__index = sharedEnv,
			__newindex = function(tbl, key, value)
				for _,e in ipairs(childEnvs) do
					e[key] = value
				end
			end
		})

		-- If the template has a global context _G, make this _G a child of that so that writes will recusively propagate
		local templateGlobal = templateEnv._G
		if (childEnvsByGlobal[templateGlobal] ~= nil) then
			setAsChildEnv(globalObj, templateGlobal)
		end
		
		return sharedEnv
	end
end

return {
	isAbsolutePath    = isAbsolutePath,
	normalizeRelPath  = normalizeRelPath, 
	makeRequire       = makeRequire,
	makeEnvironment   = makeEnvironment,
	makeGlobalContext = makeGlobalContext
}
