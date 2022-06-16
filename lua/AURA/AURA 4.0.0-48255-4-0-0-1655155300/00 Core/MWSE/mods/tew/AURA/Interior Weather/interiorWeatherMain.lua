-- TODOS:
-- Use weatherTransition scalar to determine fade-in?
-- do not fade in if cell changed, but weather did not

local config = require("tew.AURA.config")
local common=require("tew.AURA.common")
local tewLib = require("tew.tewLib.tewLib")
local isOpenPlaza=tewLib.isOpenPlaza
local sounds = require("tew.AURA.sounds")

local IWvol = config.IWvol/200

local cellLast, thunRef, windoors, thunder, interiorTimer, thunderTimerBig, thunderTimerSmall, thunderTime, interiorType, weather, weatherLast
local thunArray=common.thunArray

local debugLog = common.debugLog

local moduleName = "interiorWeather"

local function playThunder()
    local thunVol, thunPitch
    if thunRef==nil then return end
    
    thunVol = (math.random(3,8))/10
    thunPitch = (math.random(5,15))/10

    thunder=thunArray[math.random(1, #thunArray)]
    debugLog("Playing thunder: "..thunder)
    tes3.playSound{sound=thunder, volume=thunVol, pitch=thunPitch, reference=thunRef}
    event.trigger("AURA:thunderPlayed", {reference=thunRef})

    thunderTime = math.random(3,20)

    if interiorType == "big" then
        if thunderTimerBig then
            thunderTimerBig:pause()
            thunderTimerBig:cancel()
            thunderTimerBig = nil
        end
        thunRef = windoors[math.random(1, #windoors)]
        thunderTimerBig = timer.start({duration=thunderTime, iterations=1, callback=playThunder, type=timer.real})
    elseif interiorType == "sma" or interiorType == "ten" then
        if thunderTimerSmall then
            thunderTimerSmall:pause()
            thunderTimerSmall:cancel()
            thunderTimerSmall = nil
        end
        thunderTimerBig = timer.start({duration=thunderTime, iterations=1, callback=playThunder, type=timer.real})
    end
end

local function playInteriorSmall(cell)
    local volBoost=0

    if isOpenPlaza(cell)==true then
        volBoost=0.2
        debugLog("Found open plaza. Applying volume boost and removing thunder timer.")
    end

    if weather == 5 then
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.8*IWvol+volBoost, type = interiorType}
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.6*IWvol+volBoost, type = "wind"}
        thunRef=cell
        debugLog("Playing small interior storm, wind and thunder loops.")
        if isOpenPlaza(cell)==true then
            thunRef=nil
        end
    elseif weather == 4 then
        debugLog("Playing small interior rain loop.")
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.8*IWvol+volBoost, type = interiorType}
    elseif weather == 6 or weather == 7 or weather == 9 then
        debugLog("Playing small interior ash, blight or blizzard loop.")
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.5*IWvol, pitch = 0.7, type = interiorType}
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.4*IWvol+volBoost, type = "wind"}
    else
        debugLog("Playing small interior weather loop.")
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.5*IWvol, pitch = 0.6, type = interiorType}
    end
end

local function playInteriorBig(windoor)
    if windoor==nil then debugLog("Dodging an empty ref.") return end

    if weather == 4 then
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.9*IWvol, pitch = 1.0, type = interiorType, reference=windoor}
        debugLog("Playing big interior rain loop.")
    elseif weather == 5 then
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.9*IWvol, pitch = 1.0, type = interiorType, reference=windoor}
        debugLog("Playing big interior storm loop.")
    else
        debugLog("Playing big interior loop.")
        sounds.playImmediate{weather = weather, module = moduleName, volume = 0.4*IWvol, pitch = 0.7, type = interiorType, reference=windoor}
    end
end

local function updateInteriorBig()
    debugLog("Updating interior doors and windows.")
    local playerPos=tes3.player.position
    for _, windoor in ipairs(windoors) do
        if common.getDistance(playerPos, windoor.position) > 2048 then
            playInteriorBig(windoor)
        end
    end
end

local function cellCheck()

    IWvol = config.IWvol/200
    thunderTime = math.random(1,15)

    if not interiorTimer then
        interiorTimer = timer.start({duration=3, iterations=-1, callback=updateInteriorBig, type=timer.real})
        interiorTimer:pause()
    else
        interiorTimer:pause()
    end

    local cell = tes3.getPlayerCell()
    if not cell then debugLog("No cell detected. Returning.") return end

    if (not cell.isInterior or cell.behavesAsExterior)
    and (isOpenPlaza(cell)==false
    and common.checkCellDiff(cell, cellLast)==true) then
        debugLog("Found exterior cell. Removing sounds and returning.")
        -- Only need to remove from small types here, the rest is handled automatically in the engine
        sounds.removeImmediate{module = moduleName, type = "small"}
        cellLast = cell
        if thunderTimerBig then
            thunderTimerBig:pause()
            thunderTimerBig:cancel()
            thunderTimerBig = nil
        end
        if thunderTimerBig then
            thunderTimerSmall:pause()
            thunderTimerSmall:cancel()
            thunderTimerSmall = nil
        end
        return
    end

    weather = tes3.getRegion({useDoors=true}).weather.index
    debugLog("Weather: "..weather)

    if weather ~= weatherLast then
        sounds.removeImmediate{module = moduleName, type = "small"}
    end
    if weather == weatherLast and cellLast == cell then
        debugLog("Same weather detected. Returning.")
        return
    end

    if weather < 4 or weather == 8 then
        debugLog("Uneligible weather detected. Returning.")
        sounds.removeImmediate{module = moduleName, type = "small"}
        if windoors~={} and windoors~=nil then
            for _, windoor in ipairs(windoors) do
                sounds.removeImmediate{module = moduleName, reference=windoor, type = "big"}
            end
        end
        return
    end

    if (isOpenPlaza(cell) == true)
    and (weather == 6
    or weather == 7) then
        return
    end

    if common.getCellType(cell, common.cellTypesSmall)==true then
        interiorType = "sma"
    elseif common.getCellType(cell, common.cellTypesTent)==true then
        interiorType = "ten"
    else
        interiorType = "big"
    end

    windoors={}
    windoors=common.getWindoors(cell)

    debugLog("Found interior cell.")
    if interiorType == "sma" then
        debugLog("Playing small interior sounds.")
        if isOpenPlaza(cell) == true then
            tes3.getSound("Rain").volume = 0
            tes3.getSound("rain heavy").volume = 0
        else
            if weather == 5 then
                thunRef=cell
                thunderTimerSmall = timer.start({duration=thunderTime, iterations=1, callback=playThunder, type=timer.real})
            end
        end
        playInteriorSmall(cell)
    elseif interiorType == "ten" then
        debugLog("Playing tent interior sounds.")
        playInteriorSmall(cell)
        if weather == 5 then
            thunRef=cell
            thunderTimerSmall = timer.start({duration=thunderTime, iterations=1, callback=playThunder, type=timer.real})
        end
    else
        interiorType = "big"
        if windoors and windoors[1] ~= nil then
            debugLog("Playing big interior sound.")
            for _, windoor in ipairs(windoors) do
                sounds.removeImmediate{module = moduleName, reference=windoor, type = interiorType}
                playInteriorBig(windoor)
            end
            interiorTimer:resume()
            thunRef = windoors[math.random(1, #windoors)]
            if weather == 5 then
                thunderTimerBig = timer.start({duration=thunderTime, iterations=1, callback=playThunder, type=timer.real})
            end
        end
    end

    weatherLast = weather
    cellLast = cell
end


debugLog("Interior Weather module initialised.")

event.register("cellChanged", cellCheck, { priority = -165 })
event.register("weatherTransitionFinished", cellCheck, { priority = -165 })
event.register("weatherTransitionStarted", cellCheck, { priority = -165 })
event.register("weatherChangedImmediate", cellCheck, { priority = -165 })