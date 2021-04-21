local modversion = require("tew\\AURA\\version")
local config = require("tew\\AURA\\config")
local common=require("tew\\AURA\\common")
local tewLib = require("tew\\tewLib\\tewLib")
local isOpenPlaza=tewLib.isOpenPlaza

local IWAURAdir="tew\\AURA\\Interior Weather\\"
local version = modversion.version
local debugLogOn=config.debugLogOn
local IWvol = config.IWvol/200

local cellLast
local IWLoop, thunRef, windoors, interiorType, thunder, interiorTimer, thunderTimerBig, thunderTimerSmall

--local WtC=tes3.getWorldController().weatherController

local thunArray=common.thunArray

local function debugLog(string)
    if debugLogOn then
       mwse.log("[AURA "..version.."] IW: "..string)
    end
end

local function playThunder()
    local thunVol
    if thunRef==nil then return end
    if thunRef.region then
        thunVol=0.8
    else
        thunVol=0.2
    end
    thunder=thunArray[math.random(1, #thunArray)]
    debugLog("Playing thunder: "..thunder)
    tes3.playSound{sound=thunder, volume=thunVol, pitch=0.7, reference=thunRef}
end

local function updateThunderBig()
    debugLog("Updating interior doors for thunders.")
    local playerPos=tes3.player.position
    for _, windoor in ipairs(windoors) do
        if common.getDistance(playerPos, windoor.position) < 2048
        and windoor~=nil then
            thunRef=windoor
            playThunder()
        end
    end
end

local function playInteriorSmall(cell)
    local volBoost=0

    if isOpenPlaza(cell)==true then
        volBoost=0.2
        thunderTimerSmall:pause()
        debugLog("Found open plaza. Applying volume boost and removing thunder timer.")
    end

    local IWPath=IWAURAdir..interiorType.."\\"..IWLoop..".wav"

    if IWLoop=="rain heavy" then
        tes3.playSound{soundPath=IWPath, volume=0.7*IWvol+volBoost, loop=true, reference=cell}
        thunRef=cell
        debugLog("Playing small interior storm and thunder loops.")
        if isOpenPlaza(cell)==true then
            thunRef=nil
        end
    elseif IWLoop=="Rain" then
        tes3.playSound{soundPath=IWPath, volume=0.6*IWvol+volBoost, loop=true, reference=cell}
        debugLog("Playing small interior rain loops.")
    elseif IWLoop=="Blight" or IWLoop=="ashstorm" or IWLoop=="BM Blizzard" then
        tes3.playSound{sound=IWLoop, volume=0.5*IWvol, pitch=0.7, loop=true, reference=cell}
        tes3.playSound{soundPath=IWAURAdir.."Common\\wind gust.wav", volume=0.2, loop=true, reference=cell}
    else
        tes3.playSound{sound=IWLoop, volume=0.5*IWvol, pitch=0.6, loop=true, reference=cell}
    end
end

local function playInteriorBig(windoor)
    if windoor==nil then debugLog("Dodging an empty ref.") return end
    if IWLoop=="Rain" then
        tes3.playSound{sound="Sound Test", volume=0.9*IWvol, pitch=0.8, loop=true, reference=windoor}
        debugLog("Playing big interior rain loop.")
    elseif IWLoop=="rain heavy" then
        tes3.playSound{sound="Sound Test", volume=0.9*IWvol, pitch=1.4, loop=true, reference=windoor}
        debugLog("Playing big interior storm loop.")
        thunderTimerBig:resume()
    else
        debugLog("Playing big interior loop: "..IWLoop)
        tes3.playSound{sound=IWLoop, volume=0.5*IWvol, pitch=0.6, loop=true, reference=windoor}
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

    if not interiorTimer then
        interiorTimer = timer.start({duration=3, iterations=-1, callback=updateInteriorBig, type=timer.real})
        interiorTimer:pause()
    else
        interiorTimer:pause()
    end
    if not thunderTimerBig then
        thunderTimerBig = timer.start({duration=15, iterations=-1, callback=updateThunderBig, type=timer.real})
        thunderTimerBig:pause()
    else
        thunderTimerBig:pause()
    end
    if not thunderTimerSmall then
        thunderTimerSmall = timer.start({duration=15, iterations=-1, callback=playThunder, type=timer.real})
        thunderTimerSmall:pause()
    else
        thunderTimerSmall:pause()
    end

    local cell=tes3.getPlayerCell()
    if not cell then debugLog("No cell detected. Returning.") return end

    if (not cell.isInterior or cell.behavesAsExterior)
    and (isOpenPlaza(cell)==false
    and common.checkCellDiff(cell, cellLast)==true) then
        debugLog("Found exterior cell. Returning.")
        return
    end

    local IWweather = tes3.getRegion({useDoors=true}).weather.index
    IWLoop=nil
    if not (IWweather >=4 and IWweather <= 7) and not IWweather==9 then
        debugLog("Uneligible weather detected. Returning.")
        return
    elseif IWweather==4 then
        IWLoop="Rain"
    elseif IWweather==5 then
        IWLoop="rain heavy"
    elseif IWweather==6 then
        IWLoop="ashstorm"
    elseif IWweather==7 then
        IWLoop="Blight"
    elseif IWweather==9 then
        IWLoop="BM Blizzard"
    end
    debugLog("Weather: "..IWweather)

    if (isOpenPlaza(cell) == true)
    and (IWLoop == "Blight"
    or IWLoop == "ashstorm") then
        return
    end

    tes3.removeSound{reference=cell}

    if IWLoop==nil then
        if windoors~={} and windoors~=nil then
            debugLog("Clearing windoors.")
            for _, windoor in ipairs(windoors) do
                tes3.removeSound{reference=windoor}
            end
            return
        else
            return
        end
    end

    windoors={}
    windoors=common.getWindoors(cell)

    debugLog("Found interior cell.")
    if common.getCellType(cell, common.cellTypesSmall)==true then
        debugLog("Playing small interior sounds.")
        if isOpenPlaza(cell) == true then
            tes3.getSound("Rain").volume = 0
            tes3.getSound("rain heavy").volume = 0
        else
            if IWLoop=="rain heavy" then
                thunRef=cell
                thunderTimerSmall:resume()
            end
        end
        interiorType="Small"
        playInteriorSmall(cell, interiorType)
    elseif common.getCellType(cell, common.cellTypesTent)==true then
        interiorType="Tent"
        playInteriorSmall(cell, interiorType)
        debugLog("Playing tent interior sounds.")
        if IWLoop=="rain heavy" then
            thunRef=cell
            thunderTimerSmall:resume()
        end
    else
        if windoors and windoors[1] ~= nil then
            for _, windoor in ipairs(windoors) do
                tes3.removeSound{reference=windoor}
                playInteriorBig(windoor)
            end
            interiorTimer:resume()
            debugLog("Playing big interior sound.")
            if IWLoop=="rain heavy" then
                updateThunderBig()
                thunderTimerBig:resume()
            end
        end
    end

    cellLast=cell
end


debugLog("Interior Weather module initialised.")

event.register("cellChanged", cellCheck, { priority = -165 })
event.register("weatherTransitionFinished", cellCheck, { priority = -165 })
event.register("weatherTransitionStarted", cellCheck, { priority = -165 })
event.register("weatherChangedImmediate", cellCheck, { priority = -165 })