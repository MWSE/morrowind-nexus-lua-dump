local data = require("tew.AURA.Ambient.Populated.populatedData")
local config = require("tew.AURA.config")
local sounds = require("tew.AURA.sounds")
local common=require("tew.AURA.common")
local tewLib = require("tew.tewLib.tewLib")
local popVol = config.popVol/200
local isOpenPlaza=tewLib.isOpenPlaza


local time, timeLast, typeCellLast, weatherNow, weatherLast

local WtC

local moduleName = "populated"

local debugLog = common.debugLog

local blacklistedCells = {"Holamayan"}

local function getPopulatedCell(maxCount, cell)
    for _, v in ipairs(blacklistedCells) do
        if string.find(cell.name, v) then
            debugLog("Cell is blacklisted: "..v..". Returning.") return false
        end
    end
    local count = 0
    for npc in cell:iterateReferences(tes3.objectType.NPC) do
        if (npc.object.mobile) and (not npc.object.mobile.isDead) then
            count = count + 1
        end
        if count >= maxCount then debugLog("Enough people in a cell. Count: "..count) return true end
    end
    if count < maxCount then debugLog("Too few people in a cell. Count: "..count) return false end
end

local function getTypeCell(maxCount, cell)
    local count = 0
    local typeCell
    for stat in cell:iterateReferences(tes3.objectType.static) do
        for cellType, typeArray in pairs(data.statics) do
            for _, statName in ipairs(typeArray) do
                if string.startswith(stat.object.id:lower(), statName) then
                    count = count + 1
                    typeCell = cellType
                    if count >= maxCount then debugLog("Enough statics. Cell: "..cell.name..", cell type: "..typeCell) return typeCell end
                end
            end
        end
    end
    if count == 0 then debugLog("Too few statics. Count: "..count) return nil end
end

local function cellCheck()

	-- Gets messy otherwise
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		debugLog("Player waiting or travelling. Returning.")
		timer.start{
			duration = 1,
			callback = cellCheck,
		}
		return
	end

    local cell = tes3.getPlayerCell()

    if (not cell) or (not cell.name) then
        debugLog("Player in the wilderness. Returning.")
        sounds.remove{module = moduleName, volume = popVol}
        timeLast = nil
        typeCellLast = nil
        return
    elseif not (cell.isOrBehavesAsExterior and not isOpenPlaza(cell)) then
        debugLog("Player in interior cell. Removing sounds immediately.")
        sounds.removeImmediate{module = moduleName, volume = popVol}
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
	debugLog("Weather: "..weatherNow)

    if (weatherNow >= 4 and weatherNow <= 7) or (weatherNow == 8) and weatherNow ~= weatherLast then
        debugLog("Bad weather detected. Removing sounds.")
        sounds.remove{module = moduleName, volume = popVol}
        timeLast = nil
        typeCellLast = nil
        return
    end

    local gameHour = tes3.worldController.hour.value
    if (gameHour < WtC.sunriseHour + 1) or (gameHour > WtC.sunsetHour + 1) then time = "night" else time = "day" end

    local typeCell = getTypeCell(5, cell)

    if typeCell == typeCellLast
    and time == timeLast
    and weatherNow == weatherLast then
        debugLog("Same conditions. Returning.")
        return
    end

    debugLog("Different conditions. Removing sounds.")
    sounds.remove{module = moduleName, volume = popVol}
    timeLast = nil

    if typeCell ~= nil and getPopulatedCell(5, cell) == true then
        if typeCell~="dae" and
        typeCell~="dwe" and
        time == "night" then
            debugLog("Found appropriate cell at night. Playing populated ambient night sound.")
            sounds.play{module = moduleName, volume = popVol, type = "night"}
            timeLast = time
            typeCellLast = typeCell
            weatherLast = weatherNow
            return
        elseif time == "day" then
            debugLog("Found appropriate cell at day. Playing populated ambient day sound.")
            sounds.play{module = moduleName, volume = popVol, type = "day", typeCell = typeCell}
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
    timer.start({duration=0.5, callback=cellCheck, iterations=-1, type=timer.game})
end

local function onCOC()
	-- sounds.removeImmediate{module = moduleName}
    cellCheck()
end


WtC = tes3.worldController.weatherController
event.register("cellChanged", cellCheck, { priority = -190 })
event.register("weatherTransitionImmediate", onCOC, {priority=-190})
event.register("weatherChangedImmediate", onCOC, {priority=-190})
event.register("loaded", populatedTimer)
debugLog("Populated Sounds module initialised.")

