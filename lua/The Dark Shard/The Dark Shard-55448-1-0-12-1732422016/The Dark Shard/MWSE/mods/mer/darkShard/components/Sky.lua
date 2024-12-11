

---@class DarkShard.Sky
local Sky = {}

function Sky.enable()
    tes3.worldController.menuController.skyDisabled = false
end

function Sky.disable()
    tes3.worldController.menuController.skyDisabled = true
end

function Sky.isEnabled()
    return not tes3.worldController.menuController.skyDisabled
end

function Sky.toggle()
    tes3.worldController.menuController.skyDisabled =
        not tes3.worldController.menuController.skyDisabled
end

function Sky.getMasser()
    return tes3.worldController.weatherController.masser, tes3.worldController.weatherController.sceneSkyRoot:getObjectByName("sky_moon_large")
end

function Sky.getSecunda()
    return tes3.worldController.weatherController.secunda, tes3.worldController.weatherController.sceneSkyRoot:getObjectByName("sky_moon_small")
end



return Sky