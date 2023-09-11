Misc.LUNALUA_EVENTS = {
    "onStart", "onLoad", "onTick", "onTickEnd", "onDraw", "onDrawEnd", "onLoop", "onTickPaint", "onDrawPaint",
    "onLoopSection0", "onLoopSection1", "onLoopSection2", "onLoopSection3", "onLoopSection4",
    "onLoopSection5", "onLoopSection6", "onLoopSection7", "onLoopSection8", "onLoopSection9",
    "onLoopSection10", "onLoopSection11", "onLoopSection12", "onLoopSection13", "onLoopSection14",
    "onLoopSection15", "onLoopSection16", "onLoopSection17", "onLoopSection18", "onLoopSection19", "onLoopSection20",
    "onLoadSection",
    "onLoadSection0", "onLoadSection1", "onLoadSection2", "onLoadSection3", "onLoadSection4",
    "onLoadSection5", "onLoadSection6", "onLoadSection7", "onLoadSection8", "onLoadSection9",
    "onLoadSection10", "onLoadSection11", "onLoadSection12", "onLoadSection13", "onLoadSection14",
    "onLoadSection15", "onLoadSection16", "onLoadSection17", "onLoadSection18", "onLoadSection19", "onLoadSection20",
    "onSectionChange", "onMouseButtonEvent", "onMouseWheelEvent",
    "onJump", "onJumpEnd",
    "onKeyDown", "onKeyUp",
    "onEvent", "onEventDirect", "onExitLevel", "onInputUpdate", "onMessageBox", "onColorSwitch", "onSyncSwitch", "onBeatStateChange",
    "onBlockHit", "onBlockRemove",
    "onHUDDraw", "onNPCKill", "onCameraUpdate", "onCameraDraw",
    "onKeyboardPress", "onPause", "onExit", "onPauseSEEMod", "onMessageBoxSEEMod",
    "onNPCHarm","onNPCCollect",
    "onCheckpoint",
    "onExplosion",
    "onRunEffectInternal", "onExplosionInternal",
    "onPostNPCRearrangeInternal", "onBlockInvalidateForReuseInternal",
    "onWarpEnter", "onWarp",
    "onPasteText",
    "onChangeController", "onControllerButtonPress",
    "onPostNPCKill", "onPostNPCHarm", "onPostNPCCollect", "onPostExplosion", "onPostEventDirect", "onPostWarpEnter",
    "onPostBlockHit", "onPostBlockRemove",
    "onNPCGenerated",
    "onNPCConfigChange", "onBlockConfigChange", "onBGOConfigChange",
    "onPlayerKill", "onPlayerHarm", "onPostPlayerKill", "onPostPlayerHarm", "onPlayerKillEnd", "onPostPlayerKillEnd",
    -- CUSTOM events below
    "onCollide", -- Defined for block collisions
    "onPOW",
    "onControllerButtonEvent",
}

Misc.LUNALUA_EVENTS_TBL = {}
for _, v in ipairs(Misc.LUNALUA_EVENTS) do
    Misc.LUNALUA_EVENTS_TBL[v] = true
end

local postCancellableMap = {
    onNPCKill           =        "onPostNPCKill",
    onNPCHarm           =        "onPostNPCHarm",
    onNPCCollect        =     "onPostNPCCollect",
    onPlayerKill        =     "onPostPlayerKill",
    onPlayerHarm        =     "onPostPlayerHarm",
    onPlayerKillEnd     =  "onPostPlayerKillEnd",
    onExplosion         =      "onPostExplosion",
    onEventDirect       =    "onPostEventDirect",
    onBlockHit          =       "onPostBlockHit",
    onBlockRemove       =    "onPostBlockRemove",
    onWarpEnter         =      "onPostWarpEnter",
}

------------------------
-- Main Event Manager --
------------------------
local EventManager = {}
EventManager.onStartRan = false
EventManager.userListeners = {}
EventManager.apiListeners = {[true]={}, [false]={}}
EventManager.queuedEvents = {}

function EventManager.callApiListeners(name, isBefore, args)
    local listenerTbl = EventManager.apiListeners[isBefore][name]
    if (listenerTbl ~= nil) then
        for _, nextAPIToHandle in ipairs(listenerTbl) do
            local hostObject = nextAPIToHandle.api
            if hostObject[nextAPIToHandle.eventHandlerName] ~= nil then
                pcall(function() hostObject[nextAPIToHandle.eventHandlerName](args[1], args[2], args[3], args[4]) end)
            end
        end
    end
end

function EventManager.callEvent(name, ...)
    EventManager.callEventInternal(name, {...})
end

function EventManager.callEventInternal(name, args)
    if (name == "onStart") then
        EventManager.onStartRan = true
        if (populateCustomParams ~= nil) then
            populateCustomParams()
        end
    end
    
    local mainName, childName = unpack(name:split("."))
    if mainName == nil or childName == nil then
        mainName, childName = unpack(name:split(":"))
    end
    
    -- Call API listeners before usercodes.
    EventManager.callApiListeners(name, true, args)
    
    -- Call usercode files
    for _, nextUserListener in ipairs(EventManager.userListeners) do
        local hostObject = nextUserListener
        if childName then
            hostObject = nextUserListener[mainName]
            mainName = childName
        end
        if hostObject[mainName] ~= nil then
            hostObject[mainName](args[1], args[2], args[3], args[4], args[5])
        end
    end
    
    -- Call API Listeners after usercodes.
    EventManager.callApiListeners(name, false, args)
    
    local postCancellableEventName = postCancellableMap[name]
	if (postCancellableEventName ~= nil) and (not args[1].cancelled) then
		EventManager.callEventInternal(postCancellableEventName, {args[2], args[3], args[4], args[5]})
	end
end

function EventManager.queueEvent(name, parameters)
	local newQueueEntry =
	{
		eventName = name,
		parameters = parameters
	}
	table.insert(EventManager.queuedEvents, newQueueEntry)
end

function EventManager.manageEventObj(args)
    local eventObj = args[1]
    
    local eventName = eventObj.eventName
    local loopable = eventObj.loopable
    local cancellable = eventObj.cancellable
    local directEventName = eventObj.directEventName
    
    if directEventName == "" then
        directEventName = eventName .. "Direct"
    end
    
    local parameters = nil
    if loopable or (not cancellable) then
        parameters = {}
        for i= 1, #args-1 do
            parameters[i] = args[i+1]
        end
    end
    
    if cancellable then
		EventManager.callEventInternal(directEventName, args)
	else
		EventManager.callEventInternal(directEventName, parameters)
	end
	
	if loopable then
		EventManager.queueEvent(eventName, parameters)
	end
end

-- Event Distribution
--
-- This will add a new listener object.
-- table listenerObject (A code file)
function EventManager.addUserListener(listenerObject)
    table.insert(EventManager.userListeners, listenerObject)
end

function EventManager.addAPIListener(thisTable, event, eventHandler, beforeMainCall)
    if type(thisTable) == "string" then
        error("\nOutdated version of API is trying to use registerEvent with string\nPlease contact the api developer to fix this issue!", 2)
    end
    eventHandler = eventHandler or event --FIXME: Handle ==> NPC:onKill
    if (beforeMainCall == nil) then
        beforeMainCall = true
    end
    local newApiHandler =
    {
        api = thisTable,
        eventName = event,
        eventHandlerName = eventHandler,
        callBefore = beforeMainCall
    }
    
    local listenerTbl = EventManager.apiListeners[beforeMainCall][event]
    if (listenerTbl == nil) then
        listenerTbl = {}
        EventManager.apiListeners[beforeMainCall][event] = listenerTbl
    end
    table.insert(listenerTbl, newApiHandler)
end

function EventManager.clearAPIListeners(apiTable)
    for _, isBefore in ipairs({true, false}) do
        for _, listenerTbl in pairs(EventManager.apiListeners[isBefore]) do
            for i = #listenerTbl, 1, -1 do
                local apiObj = listenerTbl[i]
                if(apiObj.api == apiTable) then
                    table.remove(listenerTbl, i)
                end
            end
        end
    end
end

-- FIXME: Check also if "beforeMainCall"
function EventManager.removeAPIListener(apiTable, event, eventHandler)
    local found = false
    for _, isBefore in ipairs({true, false}) do
        local listenerTbl = EventManager.apiListeners[isBefore][event]
        if listenerTbl ~= nil then
            local i = #listenerTbl
            while i > 0 do
                local apiObj = listenerTbl[i]
                if(apiObj.api == apiTable and
                    ((eventHandler == nil) or (apiObj.eventHandlerName == eventHandler))
                    )then
                    table.remove(listenerTbl, i)
                    found = true
                end
                i = i - 1
            end
        end
    end
    return found
end

local classicEventHandler = nil
function EventManager.doQueue()
    while(#EventManager.queuedEvents > 0)do
        local nextQueuedEvent = table.remove(EventManager.queuedEvents)
        EventManager.callEventInternal(nextQueuedEvent.eventName, nextQueuedEvent.parameters)
    end
    
    if (not isOverworld) and (classicEventHandler ~= nil) then
        classicEventHandler()
    end
end

function EventManager.registerClassicEventHandler(handler)
    classicEventHandler = handler
end

-- Globally defined functions
function _G.registerEvent(apiTable, event, eventHandler, beforeMainCall)
    EventManager.addAPIListener(apiTable, event, eventHandler, beforeMainCall)
end
function _G.unregisterEvent(apiTable, event, eventHandler)
    return EventManager.removeAPIListener(apiTable, event, eventHandler)
end
function _G.clearEvents(apiTable)
    EventManager.clearAPIListeners(apiTable)
end

return EventManager