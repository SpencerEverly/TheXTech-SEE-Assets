local ffi_player = {}

function PlayerLua.isValid(pl)
    local idx = PlayerLua.idx(pl)

    if (idx >= 0) and (idx <= PlayerLua.count()) then
        return true
    end

    return false
end

local PlayerFields = {
        idx                   = {get = PlayerLua.idx, readonly = true},
        isValid               = {get = PlayerLua.isValid, readonly = true},
        x                     = {get = PlayerLua.x, set = PlayerLua.x},
        y                     = {get = PlayerLua.y, set = PlayerLua.y},
        speedX                = {get = PlayerLua.speedX, set = PlayerLua.speedX},
        speedY                = {get = PlayerLua.speedY, set = PlayerLua.speedY},
        width                 = {get = PlayerLua.width, set = PlayerLua.width},
        height                = {get = PlayerLua.height, set = PlayerLua.height},
}

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