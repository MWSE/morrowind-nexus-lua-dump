-- Check Magicka Expanded framework.
local common = require("OperatorJack.MagickaExpanded.common")
local log = require("OperatorJack.MagickaExpanded.utils.logger")
local config = require("OperatorJack.MagickaExpanded.config")

local function createGeneralCategory(template)
    local page = template:createPage{label = "General Settings"}
    page:createDropdown{
        label = "Logging Level",
        description = "Set the log level.",
        options = {
            {label = "TRACE", value = "TRACE"}, {label = "DEBUG", value = "DEBUG"},
            {label = "INFO", value = "INFO"}, {label = "WARN", value = "WARN"},
            {label = "ERROR", value = "ERROR"}, {label = "NONE", value = "NONE"}
        },
        variable = mwse.mcm.createTableVariable {id = "logLevel", table = config},
        callback = function(self) log:setLogLevel(self.variable.value) end
    }

    page:createInfo{
        text = "These functions add all spells and spellbooks used with Magicka Expanded framework.\nUse for testing and spell preview."
    }
    page:createButton{
        buttonText = "Add all spells",
        callback = function()
            if (tes3.player ~= nil) then
                common.addTestSpellsToPlayer()
                tes3.messageBox("[Magicka Expanded] Added all currently loaded spells to player.")
                log:info("Added all currently loaded spells to player.")
            end
        end,
        inGameOnly = true
    }
    page:createButton{
        buttonText = "Add all tomes and grimoires",
        callback = function()
            if (tes3.player ~= nil) then
                local tomes = require("OperatorJack.MagickaExpanded.classes.tomes")
                local grimoires = require("OperatorJack.MagickaExpanded.classes.grimoires")
                tomes.addTomesToPlayer()
                grimoires.addGrimoiresToPlayer()
                tes3.messageBox(
                    "[Magicka Expanded] Added all currently loaded spellbooks to player.")
                log:info("Added all currently loaded spellbooks to player.")
            end
        end,
        inGameOnly = true
    }
    page:createInfo{
        text = "\nThis function increases Magicka by 5000, and sets Intelligence, Willpower, and the six spell-relevant magic skills to 100."
    }
    page:createButton{
        buttonText = "Boost Magicka and magic skills",
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
                tes3.messageBox("[Magicka Expanded] Increased player's magic attributes and skills.")
                log:info("Increased player's magic attributes and skills.")
            end
        end,
        inGameOnly = true
    }
end

local template = mwse.mcm.createTemplate("Magicka Expanded")
template:saveOnClose("Magicka Expanded", config)

createGeneralCategory(template)

mwse.mcm.register(template)
