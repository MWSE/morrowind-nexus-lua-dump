-- Check Magicka Expanded framework.
local common = require("OperatorJack.MagickaExpanded.common")
local log = require("OperatorJack.MagickaExpanded.utils.logger")
local config = require("OperatorJack.MagickaExpanded.config")

local function createGeneralCategory(template)
    local page = template:createPage{label = "General Settings"}
    page:createDropdown{
        label = "Уровень журнала",
        description = "Установите уровень ведения журнала событий mwse.log.",
        options = {
            {label = "TRACE", value = "TRACE"}, {label = "DEBUG", value = "DEBUG"},
            {label = "INFO", value = "INFO"}, {label = "WARN", value = "WARN"},
            {label = "ERROR", value = "ERROR"}, {label = "NONE", value = "NONE"}
        },
        variable = mwse.mcm.createTableVariable {id = "logLevel", table = config},
        callback = function(self) log:setLogLevel(self.variable.value) end
    }

    page:createInfo{
        text = "Эти функции добавляют все заклинания и книги заклинаний, которые используют Расширенную магию.\nПредназначены для тестирования и предварительного просмотра заклинаний."
    }
    page:createButton{
        buttonText = "Добавить все заклинания",
        callback = function()
            if (tes3.player ~= nil) then
                common.addTestSpellsToPlayer()
                tes3.messageBox("[Расширенная магия] Все загруженные заклинания были добавлены игроку.")
                log:info("Added all currently loaded spells to player.")
            end
        end,
        inGameOnly = true
    }
    page:createButton{
        buttonText = "Добавить все тома и гримуары",
        callback = function()
            if (tes3.player ~= nil) then
                local tomes = require("OperatorJack.MagickaExpanded.classes.tomes")
                local grimoires = require("OperatorJack.MagickaExpanded.classes.grimoires")
                tomes.addTomesToPlayer()
                grimoires.addGrimoiresToPlayer()
                tes3.messageBox(
                    "[Расширенная магия] Все загруженные книги заклинаний были добавлены игроку.")
                log:info("Added all currently loaded spellbooks to player.")
            end
        end,
        inGameOnly = true
    }
    page:createInfo{
        text = "\nЭта функция увеличивает Магию до 5000 и устанавливает Интеллект, Силу воли и шесть магических навыков, связанных с заклинаниями, на 100."
    }
    page:createButton{
        buttonText = "Увеличение магии и магических навыков",
        callback = function()
            if (tes3.player ~= nil) then
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    attribute = tes3.attribute.intelligence,
                    current = 100
                })
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    attribute = tes3.attribute.willpower,
                    current = 100
                })
                -- fuck me, fuck lua scripting and fuck this particular chunk of code
                tes3.setStatistic({reference = tes3.mobilePlayer, name = "magicka", value = 5000})
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    skill = tes3.skill.alteration,
                    current = 100
                })
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    skill = tes3.skill.destruction,
                    current = 100
                })
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    skill = tes3.skill.restoration,
                    current = 100
                })
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    skill = tes3.skill.conjuration,
                    current = 100
                })
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    skill = tes3.skill.illusion,
                    current = 100
                })
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    skill = tes3.skill.mysticism,
                    current = 100
                })
                tes3.messageBox("[Расширенная магия] Магические атрибуты и навыки игрока увеличены.")
                log:info("Increased player's magic attributes and skills.")
            end
        end,
        inGameOnly = true
    }
end

local template = mwse.mcm.createTemplate("Расширенная магия")
template:saveOnClose("Magicka Expanded", config)

createGeneralCategory(template)

mwse.mcm.register(template)
