-- Simple MCM.lua for DremoraModelRandomizer

local config = require("DremoraModelRandomizer.config")

-- Create template
local template = mwse.mcm.createTemplate("Уникальные модели Дремор")
template:saveOnClose("DremoraModelRandomizer", config)
template:register()

-- Create page
local page = template:createSideBarPage{ label = "Настройки", description = "Уникальные модели Дремор\n\nЗаменяет стандартных Дремор на 8 новых случайных существ с более качественными лицами и броней." }

page:createOnOffButton({
    label = "Включение уникальных моделей Дремор",
    description = "Если включено, модели Дремор будут уникальными для разных видов.",
    variable = mwse.mcm.createTableVariable({ id = "enabled", table = config })
})

page:createDropdown({
    label = "Уровень ведения журнала",
    description = "Установить уровень ведения журнала. Предназначено только для использования в целях отладки..\n\nПо умолчанию: INFO",
    options = {
        { label = "TRACE", value = "TRACE" },
        { label = "DEBUG", value = "DEBUG" },
        { label = "INFO",  value = "INFO" },
        { label = "WARN",  value = "WARN" },
        { label = "ERROR", value = "ERROR" },
        { label = "NONE",  value = "NONE" },
    },
    variable = mwse.mcm.createTableVariable({
        id = "logLevel",
        table = config,
    }),
    callback = function(self)
        local log = require("animationBlending.log")
        log:setLogLevel(self.variable.value)
    end,
})

page:createButton({
    label = "Принудительное обновление моделей",
    buttonText = "Обновить",
    callback = function()
        timer.delayOneFrame(function()
            for _, cell in ipairs(tes3.getActiveCells()) do
                for ref in cell:iterateReferences(tes3.objectType.creature) do
                    if ref.sceneNode and not (ref.deleted or ref.disabled) then
                        event.trigger("DremoraModelRandomizer:Refresh", { reference = ref })
                    end
                end
            end
        end)
    end
})
