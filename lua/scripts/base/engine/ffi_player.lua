local ffi_player = {}

function Player.isValid(pl)
    local idx = Player.idx(pl)

    if (idx >= 0) and (idx <= Player.count()) then
        return true
    end

    return false
end

local PlayerFields = {
        idx                   = {get = Player.idx, readonly = true},
        isValid               = {get = playerGetIsValid, readonly = true},
        x                     = {get = Player.x, set = Player.x},
        y                     = {get = Player.y, set = Player.y},
        speedX                = {get = Player.speedX, set = Player.speedX},
        speedY                = {get = Player.speedY, set = Player.speedY},
        width                 = {get = Player.width, readonly = true},
        height                = {get = Player.height, readonly = true},
}

local function getOrSetPlayerValue(func, idx, value)
    if idx == nil then
        idx = 1
    end
    
    for k,v in ipairs(PlayerFields) do
        if PlayerFields[k].get == func and PlayerFields[k].readonly ~= nil and not getOrSet then
            error("Read only value "..tostring(getOrSet).." can't be set")
            return
        end
        
        if PlayerFields[k].get == func and value == nil then
            return func(idx)
        elseif PlayerFields[k].set == func and value ~= nil then
            return func(idx, value)
        end
    end
end

local KEYS_UP = false
local KEYS_RELEASED = nil
local KEYS_PRESSED = 1
local KEYS_DOWN = true

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------

_G.KEYS_UP = KEYS_UP
_G.KEYS_RELEASED = KEYS_RELEASED
_G.KEYS_PRESSED = KEYS_PRESSED
_G.KEYS_DOWN = KEYS_DOWN

return ffi_player