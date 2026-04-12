require("BlightStormInfection.timer") -- Главный файл. Проверки заражения работают по таймеру

-- Блокируем скрипт BlightStorms из GFM
local function blockBlightStormScript()
    local script = "BlightStorms"
    if tes3.getLegacyScriptRunning({ script = script }) then
        tes3.stopLegacyScript({ script = script })
    end
end
event.register("loaded", blockBlightStormScript)