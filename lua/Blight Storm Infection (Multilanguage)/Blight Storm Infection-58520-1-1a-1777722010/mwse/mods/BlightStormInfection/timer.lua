local config = require("BlightStormInfection.config")
local blight = require("BlightStormInfection.blight")
require("BlightStormInfection.mcm")

local infectionTimer = nil

local function stopInfectionTimer()
    if infectionTimer then
        infectionTimer:cancel()
        infectionTimer = nil
    end
end

local function startInfectionTimer()
    -- Если Дагот Ур побежден - моровых бурь нет, таймер не нужен
    if tes3.getJournalIndex{id = "C3_DestroyDagoth"} >= 50 then return end

    -- Запускаем новый таймер с актуальным значением из конфига
    infectionTimer = timer.start({
        duration = config.base.duration,
        iterations = -1, -- бесконечно
        callback = blight.checkBlightInfection
    })
end

local function updateInfectionTimer()
    stopInfectionTimer()
    startInfectionTimer()
end

-- При загрузке сохранения запускаем таймер
event.register("loaded", updateInfectionTimer)

-- Обновляем таймер по запросу из MCM после сохранения настроек
event.register("BlightStormInfection:UpdateTimer", updateInfectionTimer)