local constants = require("JosephMcKean.MistyStep.constants")
local config = require("JosephMcKean.MistyStep.config")
local log = require("JosephMcKean.MistyStep.log")

local function createTemplate()
    local template = mwse.mcm.createTemplate({
        name = constants.MOD_NAME,
        config = config
    })
    template:register()
    template:saveOnClose(constants.MOD_NAME, config)
    local settings = template:createSideBarPage({label = "Settings"})
    settings:createDropdown{
        label = "Should Misty Step use camera aim (includes up/down) or character facing (horizontal only)?",
        description = "- Camera: uses camera aim (including up/down). \n\n- Facing: uses character facing and ignores vertical aim.",
        options = {
            {label = "Camera Mode", value = "camera"},
            {label = "Facing Mode", value = "facing"}
        },
        variable = mwse.mcm.createTableVariable {
            id = "targetMode",
            table = config
        }
    }
    settings:createLogLevelOptions{
        config = config,
        configKey = "logLevel",
        logger = log
    }
    template:createExclusionsPage({
        label = "Spell Merchants",
        description = "Select which spell merchants should sell the Misty Step spell.",
        leftListLabel = "Merchants Selling Misty Step",
        rightListLabel = "All Spell Merchants",
        variable = mwse.mcm.createTableVariable {
            id = "spellMerchants",
            table = config
        },
        filters = {
            {
                label = "Spell Merchants",
                callback = function()
                    local merchants = {}
                    for merchant in tes3.iterateObjects(tes3.objectType.npc) do
                        ---@cast merchant tes3npc
                        if merchant:offersService(tes3.merchantService.spells) then
                            table.insert(merchants, merchant.id)
                        end
                    end
                    table.sort(merchants)
                    return merchants
                end
            }
        }
    })
    template:createExclusionsPage({
        label = "Scroll Merchants",
        description = "Select which scroll merchants should sell the Scroll of Misty Step.",
        leftListLabel = "Merchants Selling Scroll of Misty Step",
        rightListLabel = "All Scroll Merchants",
        variable = mwse.mcm.createTableVariable {
            id = "scrollMerchants",
            table = config
        },
        filters = {
            {
                label = "Scroll Merchants",
                callback = function()
                    local merchants = {}
                    for merchant in tes3.iterateObjects(tes3.objectType.npc) do
                        ---@cast merchant tes3npc
                        if merchant.aiConfig.bartersBooks then
                            table.insert(merchants, merchant.id)
                        end
                    end
                    table.sort(merchants)
                    return merchants
                end
            }
        }
    })
end
event.register(tes3.event.modConfigReady, createTemplate)
