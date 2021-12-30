-- Cloud module

-->>>---------------------------------------------------------------------------------------------<<<--

local cloud, WtC
local cloudyCells = {}

local version = require("tew\\Vapourmist\\version")
local VERSION = version.version

local config = require("tew\\Vapourmist\\config")
local debugLogOn = config.debugLogOn

local function debugLog(string)
    if debugLogOn then
        string = tostring(string)
        mwse.log("[Vapourmist "..VERSION.." --- CLOUD] "..string.format("%s", string))
    end
end

-- Table with blacklisted weather types
local BLOCKED_WEATHERS = {0, 6, 7}

local function reColour(weatherNow, time)

    debugLog("Running colour change.")

    local weather
    for i, w in ipairs(WtC.weathers) do
        if i-1 == weatherNow then weather = w break end
    end

    for _, activeCell in ipairs(tes3.getActiveCells()) do
        for stat in activeCell:iterateReferences(tes3.objectType.static) do
            if stat.id == "tew_cloud" then
                for node in table.traverse({stat.sceneNode}) do
                    local materialProperty = node:getProperty(0x2)
                    if materialProperty then
                        local fogColour
                        --materialProperty.alpha = 0.0
                        if time == "dawn" then
                            fogColour = {weather.fogSunriseColor.r, weather.fogSunriseColor.g, weather.fogSunriseColor.b}
                        elseif time == "day" then
                            fogColour = {weather.fogDayColor.r, weather.fogDayColor.g, weather.fogDayColor.b}
                        elseif time == "dusk" then
                            fogColour = {weather.fogSunsetColor.r, weather.fogSunsetColor.g, weather.fogSunsetColor.b}
                        elseif time == "night" then
                            fogColour = {weather.fogNightColor.r, weather.fogNightColor.g, weather.fogNightColor.b}
                        end

                         -- A bit of desaturation
                        for _, v in ipairs(fogColour) do
                            v = v - 0.05
                        end

                        local emissive = materialProperty.emissive
                        if time == "night" then
                            emissive.r, emissive.g, emissive.b = 0.06, 0.06, 0.06
                            --emissive.r, emissive.g, emissive.b = table.unpack(fogColour)
                        else
                            emissive.r, emissive.g, emissive.b = table.unpack(fogColour)
                        end
                        materialProperty.emissive = emissive

                        local diffuse = materialProperty.diffuse
                        if time == "night" then
                            diffuse.r, diffuse.g, diffuse.b = 0.0, 0.0, 0.0
                        else
                            diffuse.r, diffuse.g, diffuse.b = table.unpack(fogColour)
                        end
                        materialProperty.diffuse = diffuse

                        local ambient = materialProperty.ambient
                        ambient.r, ambient.g, ambient.b = table.unpack(fogColour)
                        materialProperty.ambient = ambient

                        local specular = materialProperty.specular
                        if time == "night" then
                            specular.r, specular.g, specular.b = 0.0, 0.0, 0.0
                        else
                            specular.r, specular.g, specular.b = table.unpack(fogColour)
                        end
                        materialProperty.specular = specular

                    end
                    node:updateProperties()
                end
            end
        end
    end

end

-- Controls cloud removal from active cells
local function removeCloud()
    for _, activeCell in ipairs(tes3.getActiveCells()) do
        for stat in activeCell:iterateReferences(tes3.objectType.static) do
            if stat.id == "tew_cloud" then
                stat:delete()
                debugLog("Cloud removed.")
            end
        end
    end
    for _, cell in ipairs(cloudyCells) do
        for stat in cell:iterateReferences(tes3.objectType.static) do
            if stat.id == "tew_cloud" then
                stat:delete()
                debugLog("Cloud removed.")
            end
        end
    end
    cloudyCells = {}
end

-- Controls conditions and cloud spawning/removing
local function addCloud(e)
    debugLog("Running check.")

    local cell = tes3.getPlayerCell()
  
    -- Sanity check
    if not cell then debugLog("No cell. Returning.") return end

    if cell.name then debugLog("Cell: "..cell.name) else debugLog("Cell: Wilderness.") end

    if (cell.isInterior) and not (cell.behavesAsExterior) then debugLog("Interior cell. Returning.") return end

    -- Check weather and remove cloud if needed
    local weatherNow = tes3.getRegion({useDoors=true}).weather.index
    for _, i in ipairs(BLOCKED_WEATHERS) do
        if weatherNow == i then
            debugLog("Uneligible weather detected. Removing cloud.")
            removeCloud()
            return
        end
    end

    local gameHour = tes3.worldController.hour.value
    local time
    if (gameHour >= WtC.sunriseHour - 2) and (gameHour < WtC.sunriseHour + 2) then
        time = "dawn"
    elseif (gameHour >= WtC.sunriseHour + 2) and (gameHour < WtC.sunsetHour - 1) then
        time = "day"
    elseif (gameHour >= WtC.sunsetHour - 1) and (gameHour < WtC.sunsetHour + 1) then
        time = "dusk"
    elseif (gameHour >= WtC.sunsetHour + 1) or (gameHour < WtC.sunriseHour - 2) then
        time = "night"
    end

    -- Remove cloud from active cells if we're transitioning from ext to int or vice versa
    if e and e.previousCell then
        if ((cell.isInterior) and (not e.previousCell.isInterior))
        or ((not cell.isInterior) and (e.previousCell.isInterior)) then
            debugLog("INT/EXT transition. Removing cloud.")
            removeCloud()
        end
    end

    -- Do not readd cloud if it's already there but do recolour it
    for stat in cell:iterateReferences(tes3.objectType.static) do
        if stat.id == "tew_cloud"
        and not stat.deleted then
            debugLog("Already clouded cell. Returning.")
            reColour(weatherNow, time)
            return
        end
    end

    -- Add cloud if all checks are passed
    for stat in cell:iterateReferences(tes3.objectType.static) do

        local counter = 0

            if counter >= config.CLOUD_LIMIT then debugLog("Limit reached.") break end

            if config.CLOUD_DENSITY/100 > math.random() then

                debugLog("First check passed.")

                local statPosition = stat.position:copy()
                statPosition.x = statPosition.x + math.random(-20,100)
                statPosition.y = statPosition.y + math.random(-50,100)
                statPosition.z = statPosition.z + math.random(2400,3500)
                local mistPosition = statPosition

                tes3.createReference{
                    object = cloud,
                    position = mistPosition,
                    cell = cell,
                    scale = math.random(7,10)/10
                }

                debugLog("First level cloud added.")

                if config.CLOUD_DENSITY/200 > math.random() then

                    debugLog("Second check passed.")

                    statPosition.x = statPosition.x - math.random(25,200)
                    statPosition.y = statPosition.y - math.random(10,300)
                    statPosition.z = statPosition.z - math.random(500,1000)
                    mistPosition = statPosition

                    tes3.createReference{
                        object = cloud,
                        position = mistPosition,
                        cell = cell,
                        scale = math.random(4,6)/10
                    }

                    debugLog("Second level cloud added.")

                end
            end

            counter = counter + 1
    end

    table.insert(cloudyCells, cell)

    -- Recolour cloud
    reColour(weatherNow, time)
    
end

-- Controls faux animation of cloud rising up and moving away with time
local function moveCloud()
    for _, activeCell in ipairs(tes3.getActiveCells()) do
        for stat in activeCell:iterateReferences(tes3.objectType.static) do
            if stat.id == "tew_cloud" then

                stat.sceneNode.translation.x = stat.sceneNode.translation.x + math.random(10,50)*config.MOVE_SPEED/700
                stat.sceneNode.translation.y = stat.sceneNode.translation.y + math.random(30,70)*config.MOVE_SPEED/700
                stat.sceneNode.translation.z = stat.sceneNode.translation.z + math.random(-10,15)*config.MOVE_SPEED/700

                stat.sceneNode:update()

            end
        end
    end
end

-- A timer needed to check for time changes
local function runTimers()
    timer.start({duration = 0.5, callback = addCloud, iterations = -1, type = timer.game})
    timer.start({duration = 1, iterations = -1, type = timer.game, callback = function() removeCloud() addCloud() end})
    debugLog("Timer started.")
end

local function init()

    WtC = tes3.getWorldController().weatherController

    event.register("loaded", runTimers)
    event.register("loaded", addCloud)
    event.register("cellChanged", addCloud)
    event.register("weatherChangedImmediate", addCloud)
    event.register("weatherTransitionFinished", addCloud)
    event.register("simulate", moveCloud)

    -- Create the cloud object
    cloud = tes3.createObject{
        objectType = tes3.objectType.static,
        id = "tew_cloud",
        mesh = "tew\\Vapourmist\\vapourcloud.nif",
        getIfExists = true
    }

end

init()