-- If you need more information about the script, you can find it in the outdoorMain.lua --
-----------------------------------------------------------------------------------------------

local data = require("tew.AURA.Ambient.Populated.populatedData")
local config = require("tew.AURA.config")
local sounds = require("tew.AURA.sounds")
local common = require("tew.AURA.common")
local isOpenPlaza = common.isOpenPlaza

local time, timeLast, typeCellLast, weatherNow, weatherLast
local WtC
local moduleName = "populated"
local debugLog = common.debugLog

-- Doesn't make any sense to play populated sound there --
local blacklistedCells = { "Holamayan" }

-- Let's see if there are enough people for us to consider the cell eligible --
local function getPopulatedCell(maxCount, cell)
    for _, v in ipairs(blacklistedCells) do
        if string.find(cell.name, v) then
            debugLog("Cell is blacklisted: " .. v .. ". Returning.")
            return false
        end
    end
    local count = 0
    for npc in cell:iterateReferences(tes3.objectType.NPC) do
        if (npc.object.mobile) and (not npc.object.mobile.isDead) then
            count = count + 1
        end
        if count >= maxCount then debugLog("Enough people in a cell. Count: " .. count) return true end
    end
    if count < maxCount then debugLog("Too few people in a cell. Count: " .. count) return false end
end

-- Get cell type with the aid of statics name matching --
local function getTypeCell(maxCount, cell)
    local count = 0
    local typeCell
    for stat in cell:iterateReferences(tes3.objectType.static) do
        for cellType, typeArray in pairs(data.statics) do
            for _, statName in ipairs(typeArray) do
                if string.startswith(stat.object.id:lower(), statName) then
                    count = count + 1
                    typeCell = cellType
                    if count >= maxCount then debugLog("Enough statics. Cell: " .. cell.name .. ", cell type: " .. typeCell) return typeCell end
                end
            end
        end
    end
    if count == 0 then debugLog("Too few statics. Count: " .. count) return nil end
end

local function cellCheck()

    -- Gets messy otherwise --
    local mp = tes3.mobilePlayer
    if (not mp) or (mp and (mp.waiting or mp.traveling or mp.sleeping)) then
        return
    end

    local cell = tes3.getPlayerCell()

    -- Wilderness shouldn't be considered populated --
    -- If cell name is nil (different from editorName!) then it's wilderness --
    if (not cell) or (not cell.name) then
        debugLog("Player in the wilderness. Returning.")
        sounds.remove { module = moduleName }
        timeLast = nil
        typeCellLast = nil
        return
    elseif not (cell.isOrBehavesAsExterior and not isOpenPlaza(cell)) then -- Bugger off if we're inside --
        debugLog("Player in interior cell. Removing sounds immediately.")
        sounds.removeImmediate { module = moduleName }
        timeLast = nil
        typeCellLast = nil
        return
    end

    -- Checking current weather --
    if WtC.nextWeather then
        weatherNow = WtC.nextWeather.index
    else
        weatherNow = WtC.currentWeather.index
    end
    debugLog("Weather: " .. weatherNow)

    -- No outside activity in ashstorms and that --
    if (weatherNow >= 4 and weatherNow <= 7) or (weatherNow == 8) and weatherNow ~= weatherLast then
        debugLog("Bad weather detected. Removing sounds.")
        sounds.remove { module = moduleName }
        timeLast = nil
        typeCellLast = nil
        return
    end

    local gameHour = tes3.worldController.hour.value
    if (gameHour < WtC.sunriseHour + 1) or (gameHour > WtC.sunsetHour + 1) then time = "night" else time = "day" end

    local typeCell = getTypeCell(5, cell)

    -- Do not reset sounds if conditions are the same at this point --
    if typeCell == typeCellLast
        and time == timeLast
        and weatherNow == weatherLast then
        debugLog("Same conditions. Returning.")
        return
    end

    -- Otherwise reset and resolve --
    debugLog("Different conditions. Removing sounds.")
    sounds.remove { module = moduleName }
    timeLast = nil

    -- Check if the cell is populated and whether it's night or day --
    if typeCell ~= nil and getPopulatedCell(5, cell) == true then
        if typeCell ~= "dae" and
            typeCell ~= "dwe" and
            time == "night" then
            debugLog("Found appropriate cell at night. Playing populated ambient night sound.")
            sounds.play { module = moduleName, type = "night" }
            timeLast = time
            typeCellLast = typeCell
            weatherLast = weatherNow
            return
        elseif time == "day" then
            debugLog("Found appropriate cell at day. Playing populated ambient day sound.")
            sounds.play { module = moduleName, type = "day", typeCell = typeCell }
            timeLast = time
            typeCellLast = typeCell
            weatherLast = weatherNow
            return
        end
    end

    timeLast = time
    typeCellLast = typeCell
    weatherLast = weatherNow

    debugLog("No appropriate cell detected.")
end

local function populatedTimer()
    timeLast = nil
    typeCellLast = nil
    timer.start({ duration = 0.5, callback = cellCheck, iterations = -1, type = timer.game })
end

local function runResetter()
    time, timeLast, typeCellLast, weatherNow, weatherLast = nil, nil, nil, nil, nil
    timer.start {
        type = timer.game,
        duration = 0.01,
        callback = cellCheck
    }
end

local function waitCheck(e)
    local element = e.element
    element:registerAfter("destroy", function()
        timer.start {
            type = timer.game,
            duration = 0.01,
            callback = cellCheck
        }
    end)
end

-- Timer here so that sky textures can work ok --
local function transitionStartedWrapper(e)
    timer.start {
        duration = 1.5,
        type = timer.simulate,
        iterations = 1,
        callback = cellCheck,
    }
end

WtC = tes3.worldController.weatherController
event.register("cellChanged", cellCheck, { priority = -190 })
event.register("weatherTransitionStarted", transitionStartedWrapper, { priority = -190 })
event.register("weatherTransitionFinished", cellCheck, { priority = -190 })
event.register("weatherChangedImmediate", cellCheck, { priority = -190 })
event.register("AURA:aboveOrUnderwater", cellCheck, { priority = -190 })
event.register("loaded", populatedTimer)
event.register("load", runResetter)
event.register("uiActivated", waitCheck, { filter = "MenuTimePass", priority = -5 })
debugLog("Populated Sounds module initialised.")
