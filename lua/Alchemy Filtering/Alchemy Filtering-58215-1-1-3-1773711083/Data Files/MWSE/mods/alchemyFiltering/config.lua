local EasyMCM = require("easyMCM.EasyMCM")
local i18n = require("alchemyFiltering.i18n")

local textHeight = 20
local defaultConfig = {
    modEnabled = true,
    chosenEffectSticky = true,
    sortSticky = true,
    chooserHeight = 12 * textHeight,
}

local configFilename = "Alchemy Filtering"

local config = mwse.loadConfig(configFilename, defaultConfig)

local function onModConfigReady()
    local template = EasyMCM.createTemplate(i18n("mcm.modName"))
    template:saveOnClose(configFilename, config)
    template:register();

    local page = template:createSideBarPage{label = i18n("mcm.settings")};
    local settings = page:createCategory(i18n("mcm.settings"))

    settings:createOnOffButton({
        label = i18n("mcm.modEnabled.label"),
        description = i18n("mcm.modEnabled.desc"),
        variable = EasyMCM.createTableVariable {
            id = "modEnabled",
            table = config
        }
    })

    settings:createOnOffButton({
        label = i18n("mcm.chosenEffectSticky.label"),
        description = i18n("mcm.chosenEffectSticky.desc"),
        variable = EasyMCM.createTableVariable {
            id = "chosenEffectSticky",
            table = config
        }
    })

    settings:createOnOffButton({
        label = i18n("mcm.sortSticky.label"),
        description = i18n("mcm.sortSticky.desc"),
        variable = EasyMCM.createTableVariable {
            id = "sortSticky",
            table = config
        }
    })

    settings:createSlider({
        label = i18n("mcm.chooserHeight.label"),
        min = 80,
        max = 300,
        description = i18n("mcm.chooserHeight.desc"),
        variable = EasyMCM.createTableVariable {
            id = "chooserHeight",
            table = config
        }
    })
end

event.register("modConfigReady", onModConfigReady)

return config
