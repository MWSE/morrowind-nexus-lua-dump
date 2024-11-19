local common = require("mer.darkShard.common")
local logger = common.createLogger("weather")

---@class DarkShard.Weather
local Weather = {}

local sky = tes3.worldController.weatherController.sceneSkyRoot

function Weather.getClouds()
    return sky.children[6]
end

function Weather.disableClouds()
    logger:debug("Disabling clouds")
    for _, child in ipairs(Weather.getClouds().children) do
        if child then
            if not child.name:startswith("AFQ_") then
                child.appCulled = true
            end
        end
    end
end

function Weather.enableClouds()
    logger:debug("Enabling clouds")
    for _, child in ipairs(Weather.getClouds().children) do
        if child then
            child.appCulled = false
        end
    end
end

return Weather