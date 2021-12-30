-- Mist module

-->>>---------------------------------------------------------------------------------------------<<<--

local mist, WtC
local mistyCells = {}

local version = require("tew\\Vapourmist\\version")
local VERSION = version.version

local config = require("tew\\Vapourmist\\config")
local debugLogOn = config.debugLogOn

local function debugLog(string)
    if debugLogOn then
        string = tostring(string)
        mwse.log("[Vapourmist "..VERSION.." --- MIST] "..string.format("%s", string))
    end
end

--[[local COLOURS = {
["day"] = {
    emissive = {0.79172962903976, 0.79172962903976, 0.79172962903976},
    diffuse = {0.7622644305229, 0.7622644305229, 0.76226443052292},
    ambient = {0.8188754320144, 0.81887543201447, 0.81887543201447},
    specular = {0.0, 0.0, 0.0}
    },
["night"]  = {
    emissive = {0.06, 0.06, 0.06},
    diffuse = {0.0, 0.0, 0.0},
    ambient = {0.0, 0.0, 0.0},
    specular = {0.0, 0.0, 0.0}
    }
}]]

-- Create regex for static names used to spawn the mesh in natural locations
local re = require("re")
local PATTERNS = re.compile[[ "ashtree" / "rock" / "_rock_" / "menhir" / "_tree_" / "ex_" / "hlaalu" / "bw_" / "necrom" / "parasol" ]]

-- Main control of fog amount
local CHANCE = 0.07

-- Main control of movement speed
-- Less = faster
local MOVE_SPEED = 60

-- Table with blacklisted weather types
local BLOCKED_WEATHERS = {4, 5, 6, 7, 8, 9}

local function reColour(weatherNow, time)

    debugLog("Running colour change.")

    local weather
    for i, w in ipairs(WtC.weathers) do
        if i-1 == weatherNow then weather = w break end
    end

    for _, activeCell in ipairs(tes3.getActiveCells()) do
        for stat in activeCell:iterateReferences(tes3.objectType.static) do
            if stat.id == "tew_vapour" then
                for node in table.traverse({stat.sceneNode}) do

                    local materialProperty = node:getProperty(0x2)
                    if materialProperty then
                        local fogColour
                        debugLog("Time: "..time)
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
                            v = v - 0.08
                        end

                        local emissive = materialProperty.emissive
                        if time == "night" then
                            emissive.r, emissive.g, emissive.b = 0.06, 0.06, 0.06
                        else
                            emissive.r, emissive.g, emissive.b = table.unpack(fogColour)
                        end
                        materialProperty.emissive = emissive

                        local diffuse = materialProperty.diffuse
                        if time == "night" then
                            diffuse.r, diffuse.g, diffuse.b = 0.0, 0.0, 0.0001
                        else
                            diffuse.r, diffuse.g, diffuse.b = table.unpack(fogColour)
                        end
                        materialProperty.diffuse = diffuse

                        local ambient = materialProperty.ambient
                        if time == "night" then
                            ambient.r, ambient.g, ambient.b = 0.0, 0.0, 0.00001
                        else
                            ambient.r, ambient.g, ambient.b = table.unpack(fogColour)
                        end
                        materialProperty.ambient = ambient

                        local specular = materialProperty.specular
                        if time == "night" then
                            specular.r, specular.g, specular.b = 0.0, 0.0, 0.00001
                        else
                            specular.r, specular.g, specular.b = table.unpack(fogColour)
                        end
                        materialProperty.specular = specular

                        node:updateEffects()
                        node:updateProperties()
                    end
                end
            end
        end
    end

end

-- Controls fog removal from active cells
local function removeMist()
    for _, activeCell in ipairs(tes3.getActiveCells()) do
        for stat in activeCell:iterateReferences(tes3.objectType.static) do
            if stat.id == "tew_vapour" then
                stat:delete()
                debugLog("Fog removed.")
            end
        end
    end
    for _, cell in ipairs(mistyCells) do
        for stat in cell:iterateReferences(tes3.objectType.static) do
            if stat.id == "tew_vapour" then
                stat:delete()
                debugLog("Fog removed.")
            end
        end
    end
    mistyCells = {}
end

-- Controls conditions and fog spawning/removing
local function addMist(e)
    debugLog("Running check.")

    local cell = e.cell or tes3.getPlayerCell()
  
    -- Sanity check
    if not cell then debugLog("No cell. Returning.") return end

    if cell.name then debugLog("Cell: "..cell.name) else debugLog("Cell: Wilderness.") end

    if (cell.isInterior) and not (cell.behavesAsExterior) then debugLog("Interior cell. Returning.") return end

    -- Check weather and remove fog if needed
    local weatherNow = tes3.getRegion({useDoors=true}).weather.index
    for _, i in ipairs(BLOCKED_WEATHERS) do
        if weatherNow == i then
            debugLog("Uneligible weather detected. Removing fog.")
            removeMist()
            return
        end
    end

    -- Check time and remove fog if needed
    local gameHour = tes3.worldController.hour.value
    if ((gameHour >= WtC.sunriseHour + 2 and gameHour <= 24)
    or (gameHour >= 24 and gameHour < WtC.sunsetHour - 1))
    and not (weatherNow == 2 or weatherNow == 3) then
        debugLog("Uneligible time detected. Removing fog.")
        removeMist()
        return
    end

    local time
    if (gameHour >= WtC.sunriseHour - 1) and (gameHour < WtC.sunriseHour + 2) then
        time = "dawn"
    elseif (gameHour >= WtC.sunriseHour + 2) and (gameHour < WtC.sunsetHour - 1) then
        time = "day"
    elseif (gameHour >= WtC.sunsetHour - 1) and (gameHour < WtC.sunsetHour + 1) then
        time = "dusk"
    elseif (gameHour >= WtC.sunsetHour + 1) or (gameHour < WtC.sunriseHour - 1) then
        time = "night"
    end

    --[[WtC.sunriseDuration
    WtC.sunsetDuration]]

    -- Remove fog from active cells if we're transitioning from ext to int or vice versa
    if e.previousCell then
        if ((cell.isInterior) and (not e.previousCell.isInterior))
        or ((not cell.isInterior) and (e.previousCell.isInterior)) then
            debugLog("INT/EXT transition. Removing fog.")
            removeMist()
        end
    end

    -- Do not readd mist if it's already there but do recolour it

    for stat in cell:iterateReferences(tes3.objectType.static) do
        if stat.id == "tew_vapour"
        and not stat.deleted then
            debugLog("Already fogged cell. Updating colour and returning.")
            reColour(weatherNow, time)
            return
        end
    end

    -- Add mist if all checks are passed
    for stat in cell:iterateReferences(tes3.objectType.static) do

        local counter = 0
        if re.find(stat.id:lower(), PATTERNS) then

            if counter > 25 then debugLog("Limit reached.") break end

            if CHANCE > math.random() then

                debugLog("First check passed.")

                local statPosition = stat.position:copy()
                statPosition.x = statPosition.x + math.random(-20,100)
                statPosition.y = statPosition.y + math.random(-50,100)
                statPosition.z = statPosition.z + math.random(200,500)
                local mistPosition = statPosition

                local statOrientation = stat.position:copy()
                statOrientation.x = statOrientation.x + math.random(-5, 10)
                statOrientation.y = statOrientation.y + math.random(-5, 10)
                statOrientation.z = statOrientation.z + math.random(-5, 10)
                local mistOrientation = statOrientation

                tes3.createReference{
                    object = mist,
                    position = mistPosition,
                    orientation = mistOrientation,
                    cell = cell,
                    scale = math.random(6,10)/10
                }

                debugLog("First level fog added.")

                if CHANCE > math.random() then

                    debugLog("Second check passed.")

                    statPosition.x = statPosition.x + math.random(100,500)
                    statPosition.y = statPosition.y + math.random(100,500)
                    statPosition.z = statPosition.z + math.random(100,500)
                    mistPosition = statPosition

                    statOrientation.x = statOrientation.x + math.random(-5, 10)
                    statOrientation.y = statOrientation.y + math.random(-5, 10)
                    statOrientation.z = statOrientation.z + math.random(-5, 10)
                    mistOrientation = statOrientation

                    tes3.createReference{
                        object = mist,
                        position = mistPosition,
                        orientation = mistOrientation,
                        cell = cell,
                        scale = math.random(3,8)/10
                    }

                    debugLog("Second level fog added.")

                end
            end

            counter = counter + 1

        end

    end

    table.insert(mistyCells, cell)

    -- Recolour mist
    timer.delayOneFrame(function() reColour(weatherNow, time) end)

end

-- Controls faux animation of mist rising up and moving away with time
local function moveMist()
    for _, activeCell in ipairs(tes3.getActiveCells()) do
        for stat in activeCell:iterateReferences(tes3.objectType.static) do
            if stat.id == "tew_vapour" then

                stat.sceneNode.translation.x = stat.sceneNode.translation.x + math.random(-5,60)/MOVE_SPEED
                stat.sceneNode.translation.y = stat.sceneNode.translation.y + math.random(-10,20)/MOVE_SPEED
                stat.sceneNode.translation.z = stat.sceneNode.translation.z + math.random(10,40)/MOVE_SPEED

                stat.sceneNode:update()

            end
        end
    end
end

-- A timer needed to check for time changes
local function runHourTimer()
    timer.start({duration = 0.5, callback = addMist, iterations = -1, type = timer.game})
    debugLog("Timer started.")
end

local function init()

    WtC = tes3.getWorldController().weatherController

    event.register("loaded", runHourTimer)

    event.register("weatherChangedImmediate", addMist)
    event.register("weatherTransitionFinished", addMist)
    event.register("cellChanged", addMist)

    event.register("simulate", moveMist)

    -- Create the mist object
    mist = tes3.createObject{
        objectType = tes3.objectType.static,
        id = "tew_vapour",
        mesh = "tew\\Vapourmist\\vapourmist.nif",
        getIfExists = true
    }


end

init()
