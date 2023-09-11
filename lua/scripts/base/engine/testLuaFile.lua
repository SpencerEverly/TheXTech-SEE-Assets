local testLuaFile = {}

local levelTime = 400
local hurryUpThing = 0
local killThing = 0
local ScreenW = Misc.getScreenWidth()
local ScreenH = Misc.getScreenHeight()
local gotGameOver = false
local gameOverTimer = 0

registerEvent(testLuaFile,"onStart")
registerEvent(testLuaFile,"onDrawPaint")
registerEvent(testLuaFile,"onTickPaint")
registerEvent(testLuaFile,"onMessageBox")
registerEvent(testLuaFile,"onEvent")
registerEvent(testLuaFile,"onKeyboardPress")
registerEvent(testLuaFile,"onPlayerHarm")
registerEvent(testLuaFile,"onPlayerKill")
registerEvent(testLuaFile,"onPause")
registerEvent(testLuaFile,"onPlayerKillEnd")
registerEvent(testLuaFile,"onPasteText")

Graphics.loadImage("graphics/ui/", "Interface1", 1)
Graphics.loadImage("graphics/ui/", "Time", 2)

function testLuaFile.onStart()
    if Level.filename() == "test1.lvlx" then
        Audio.MusicChange(0, "BGM_24Hour_08_Sunny.mp3")
    end
end

function testLuaFile.onPasteText(text)
    if Level.filename() == "test1.lvlx" then
        
    end
end

function testLuaFile.onKeyboardPress(key, repeated, stri)
    if Level.filename() == "test1.lvlx" then
        if key == VK_D then
            
        end
    end
end

function testLuaFile.getLevelTime()
    if levelTime > 0 then
        return levelTime
    else
        return 0
    end
end

function testLuaFile.onPlayerHarm(eventObj, playerIdx)
    if Level.filename() == "test1.lvlx" then
        eventObj.cancelled = true
    end
end

function testLuaFile.onPlayerKill(eventObj, playerIdx)
    if Level.filename() == "test1.lvlx" then
        eventObj.cancelled = true
    end
end

function testLuaFile.onPlayerKillEnd(eventObj, playerIdx)
    if mem(0x00B2C5AC, FIELD_FLOAT) <= 0 and not Misc.inEditor() then
        eventObj.cancelled = true
        gotGameOver = true
        Misc.pause()
    end
end

function testLuaFile.onTickPaint()
    if Level.filename() == "test1.lvlx" then
        levelTime = levelTime - (1 / 64)
        if levelTime == 100 then
            hurryUpThing = hurryUpThing + 1
            if hurryUpThing == 1 then
                Audio.SfxPlay(92)
            end
        end
        if levelTime == 0 then
            killThing = killThing + 1
            if killThing == 1 then
                for i = 1,200 do
                    if Player.isValid(i) then
                        Player.kill(i)
                    end
                end
            end
        end
    end
end

function testLuaFile.onDrawPaint()
    if gotGameOver then
        Text.print("GAME OVER", 310, 290)
        gameOverTimer = gameOverTimer + 1
        if gameOverTimer == 1 then
            Audio.SfxPlay("sound/extended/game-over.ogg")
        end
        if gameOverTimer >= lunatime.toTicks(7) then
            Misc.unpause()
            mem(0x00B2C5AC, FIELD_FLOAT, 3)
            Level.exit()
        end
    end
    if Level.filename() == "test1.lvlx" then
        Text.print("TIME: "..tostring(math.ceil(testLuaFile.getLevelTime())), (ScreenW / 2 - 77), 80)
        
        Graphics.drawImage(1, (ScreenW / 2 - 50), 80)
        --Graphics.drawImage(2, (ScreenW / 2), 80)
    end
    if Level.filename() == "intro.lvl" then
        Text.print(__LUNALUA_TITLESCREENVER, 0, 0)
    end
end

function testLuaFile.onMessageBox(eventObj, messageText)
    if Level.filename() == "test1.lvlx" then
        if messageText == "test" then
            Audio.MusicChange(0, "Egypt Megalovania.wav")
        end
        if messageText == "test2" then
            Audio.MusicChange(0, "mus_temvillage.ogg")
            Player.speedY(1, -12)
            Player.speedX(1, 12)
        end
    end
end

function testLuaFile.onPause(eventObj)
    if Level.filename() == "test1.lvlx" then
        --eventObj.cancelled = true
    end
end

function testLuaFile.onEvent(eventObj, eventName)
    if Level.filename() == "test1.lvlx" then
        if eventName == "Event Trigger 1" then
            --Text.showMessageBox("Lua coded message box!!!")
        end
    end
end

return testLuaFile