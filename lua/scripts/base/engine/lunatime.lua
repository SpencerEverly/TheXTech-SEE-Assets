local lunatime = {}
local timerSinceChange = 0;
local timerBaseSec = 0;
local timer = 0;
local drawtimerSinceChange = 0;
local drawtimerBaseSec = 0;
local drawtimer = 0;

local GetEngineTickDuration = 15.6

registerEvent(lunatime, "onTick", "onTick", true);
registerEvent(lunatime, "onDraw", "onDraw", true);

function lunatime.onTick()
	timer = timer + 1;
	timerSinceChange = timerSinceChange + 1;
end

function lunatime.onDraw()
	drawtimer = drawtimer + 1;
	drawtimerSinceChange = drawtimerSinceChange + 1;
end

-- Get the current game tick
function lunatime.tick()
	return timer;
end

-- Get the current game time in seconds
function lunatime.time()
	return timerBaseSec + (timerSinceChange * GetEngineTickDuration) / 1000;
end

-- Get the current game draw tick (ticks up while the game is paused)
function lunatime.drawtick()
	return drawtimer
end

-- Get the current game draw time in seconds (ticks up while the game is paused)
function lunatime.drawtime()
	return drawtimerBaseSec + (drawtimerSinceChange * GetEngineTickDuration) / 1000;
end

-- Convert game seconds to game ticks
function lunatime.toTicks(seconds)
	return math.floor(((seconds * 1000) / GetEngineTickDuration) + 0.5);
end

-- Convert game ticks to game seconds
function lunatime.toSeconds(ticks)
	return (ticks * GetEngineTickDuration) / 1000;
end

-- Handle if the time changes
function lunatime._notifyTickDurationChange()
    timerBaseSec = lunatime.time();
	timerSinceChange = 0;
	
    drawtimerBaseSec = lunatime.drawtime()
	drawtimerSinceChange = 0;
end

return lunatime
