--[[

'##:::::::'##::::'##:'##::: ##::::'###::::'##:::::::'##::::'##::::'###::::
 ##::::::: ##:::: ##: ###:: ##:::'## ##::: ##::::::: ##:::: ##:::'## ##:::
 ##::::::: ##:::: ##: ####: ##::'##:. ##:: ##::::::: ##:::: ##::'##:. ##::
 ##::::::: ##:::: ##: ## ## ##:'##:::. ##: ##::::::: ##:::: ##:'##:::. ##:
 ##::::::: ##:::: ##: ##. ####: #########: ##::::::: ##:::: ##: #########:
 ##::::::: ##:::: ##: ##:. ###: ##.... ##: ##::::::: ##:::: ##: ##.... ##:
 ########:. #######:: ##::. ##: ##:::: ##: ########:. #######:: ##:::: ##:
........:::.......:::..::::..::..:::::..::........:::.......:::..:::::..::
    '########:'##::: ##::'######:::'####:'##::: ##:'########::::
     ##.....:: ###:: ##:'##... ##::. ##:: ###:: ##: ##.....:::::
     ##::::::: ####: ##: ##:::..:::: ##:: ####: ##: ##::::::::::
     ######::: ## ## ##: ##::'####:: ##:: ## ## ##: ######::::::
     ##...:::: ##. ####: ##::: ##::: ##:: ##. ####: ##...:::::::
     ##::::::: ##:. ###: ##::: ##::: ##:: ##:. ###: ##::::::::::
     ########: ##::. ##:. ######:::'####: ##::. ##: ########::::
    ........::..::::..:::......::::....::..::::..::........:::::
                        (TheXTech Emulator)
]]

--LunaLua Version
__LUNALUA = "0.7 SEE Mod TheXTech Edition"
__isLuaError = false
__LUNALUA_TITLESCREENVER = "LUNALUA THEXTECH v0.0.1a"

--SMBX2 Version logic
do
    local function makeVersion(major, subver, minor, beta, preview, patch, hotfix)
        if beta == 0 then
            beta = 255
        else
            beta = beta-1
        end
        
        if preview == 0 then
            preview = 15
        else
            preview = preview-1
        end
        
        return major   * 17592186044416 --[[2^44 (lshift 44) - 8 bits - 0-255 - Major Version (i.e. 2)]]
             + subver  * 68719476736    --[[2^36 (lshift 36) - 8 bits - 0-255 - Subversion]]
             + minor   * 268435456      --[[2^28 (lshift 28) - 8 bits - 0-255 - Minor Version]] 
             + beta    * 1048576        --[[2^20 (lshift 20) - 8 bits - 0-255 - Beta Version      (0 largest)]]
             + preview * 65536            --[[2^16 (lshift 16) - 4 bits - 0-15  - Preview Version (0 largest)]]
             + patch   * 256            --[[2^8  (lshift 8)  - 8 bits - 0-255 - Patch]]
             + hotfix                    --[[                   8 bits - 0-255 - Hotfix]]
    end
    
                            
    --With EVERY release, a new version    MUST be added here.
    
    --                                        #  .#  .# .b# .p#  .#  .#
    _G["VER_BETA1"]             =     makeVersion(2,    0,    0,    1,    0,    0,    0)
    _G["VER_BETA2"]             =     makeVersion(2,    0,    0,    2,    0,    0,    0)
    _G["VER_BETA3"]             =     makeVersion(2,    0,    0,    3,    0,    0,    0)
    _G["VER_MAGLX3"]            =     makeVersion(2,    0,    0,    4,    1,    0,    0)
    _G["VER_PAL"]               =     makeVersion(2,    0,    0,    4,    2,    0,    0)
    _G["VER_PAL_HOTFIX"]        =     makeVersion(2,    0,    0,    4,    2,    0,    1)
    _G["VER_BETA4"]             =     makeVersion(2,    0,    0,    4,    0,    0,    0)
    _G["VER_BETA4_HOTFIX"]      =     makeVersion(2,    0,    0,    4,    0,    0,    1)
    _G["VER_BETA4_PATCH_2"]     =     makeVersion(2,    0,    0,    4,    0,    2,    0)
    _G["VER_BETA4_PATCH_2_1"]   =     makeVersion(2,    0,    0,    4,    0,    2,    1)
    _G["VER_BETA4_PATCH_3"]     =     makeVersion(2,    0,    0,    4,    0,    3,    0)
    _G["VER_BETA4_PATCH_3_1"]   =     makeVersion(2,    0,    0,    4,    0,    3,    1)
    _G["VER_BETA4_PATCH_4"]     =     makeVersion(2,    0,    0,    4,    0,    4,    0)
    _G["VER_BETA4_PATCH_4_1"]   =     makeVersion(2,    0,    0,    4,    0,    4,    1)
    _G["VER_SEE_MOD"]           =     makeVersion(3,    0,    0,    0,    0,    0,    0)
    _G["VER_THEXTECH_SEE_MOD"]  =     makeVersion(3,    0,    0,    0,    0,    0,    1)
    
    --                                e.g.        2  .0  .0 .b4 .p2  .0  .1    = PAL Hotfix
    
    
    --Update this to the latest version 
    _G["SMBX_VERSION"] = VER_THEXTECH_SEE_MOD
    
    
    
    --bit doesn't exist, so this will be commented out.
    --[[_G["getSMBXVersionString"] = function(v)
        v = v or SMBX_VERSION
        
        local major     =            math.floor(v / 17592186044416)
        local subver     = bit.band(math.floor(v / 68719476736), 0xFF)
        local minor     = bit.band(math.floor(v / 268435456),     0xFF)
        local beta        = bit.band(math.floor(v / 1048576),     0xFF)
        local preview    = bit.band(math.floor(v / 65536),         0xF)
        local patch        = bit.band(math.floor(v / 256),         0xFF)
        local hotfix    = bit.band(math.floor(v),                 0xFF)
        
        local s = major.."."..subver.."."..minor
        
        beta = beta+1
        if beta > 255 then
            beta = 0
        end
        
        preview = preview+1
        if preview > 15 then
            preview = 0
        end
        
        if beta > 0 then
            s = s..".b"..beta
        end
        
        if preview > 0 then
            s = s..".p"..preview
        end
        
        if patch > 0 or hotfix > 0 then
            s = s.."."..patch
        end
        
        if hotfix > 0 then
            s = s.."."..hotfix
        end
        
        return s
    end]]
end

--------------------
-- Error handling --
--------------------

local function __xpcall (f, ...)
  return xpcall(f,
    function (msg)
      -- build the error message
      return debug.traceback("==> " .. msg .. "\n=============", 2)
    end, ...)
end

-----------
-- Utils --
-----------

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local function __xpcallCheck(returnData)
    if not returnData[1] then
        Text.windowDebug(returnData[2])
        -- The following line used to cause shutdown of Lua
        -- __isLuaError = true
        -- TODO: See about a mechanism to avoid issues if errors keep happening repeatedly.
        return false
    end
    return true
end

function Misc.dialog(message)
    return Text.windowDebug(tostring(message))
end

function Misc.dialogSimple(message)
    return Text.windowDebugSimple(tostring(message))
end

local luaPath = "scripts/base/engine/"

local EventManager = require(luaPath.."main_events")
local constants = require(luaPath.."constants")

do
    _G.lunatime = require(luaPath.."lunatime")
    _G.repl = require("scripts/base/game/repl")
    --_G.ffi_utils = require(luaPath.."ffi_utils")
    _G.ffi_player = require(luaPath.."ffi_player")
    
    local currentTickTimeMs = 15.600
	local currentTps = 1000.0 / currentTickTimeMs
	local currentSpeed = 15.6 / currentTickTimeMs
    
    function Misc.GetEngineTickDuration()
		return currentTickTimeMs
	end
    
    function Misc.GetEngineTPS()
        return currentTps
	end
    
    function Misc.GetEngineSpeed()
        return currentSpeed
	end
end

local testLuaFile = require(luaPath.."testLuaFile")

function __callEvent(...)
    local pcallReturns = {__xpcall(EventManager.manageEventObj, {...})}
	__xpcallCheck(pcallReturns)
    
    local eventThings = {...}
    --local eventName = eventThings[1]
    
    --_G[eventName](eventThings[2], eventThings[3], eventThings[4], eventThings[5], eventThings[6])
    
    if Level.filename() == "test1.lvlx" then
        if eventThings[1] == "onStart" then
            
        elseif eventThings[1] == "onDrawPaint" then
            
        elseif eventThings[1] == "onDraw" then
            
        elseif eventThings[1] == "onMessageBox" then
            
        elseif eventThings[1] == "onEvent" then
            
        end
    end
end

function __doEventQueue()
	local pcallReturns = {__xpcall(EventManager.doQueue)}
	__xpcallCheck(pcallReturns)
end

--Loadeding function
--This code segment won't post any errors!
function __onInit()
    local pcallReturns = {__xpcall(function()
        
    end)}
    __xpcallCheck(pcallReturns)
end