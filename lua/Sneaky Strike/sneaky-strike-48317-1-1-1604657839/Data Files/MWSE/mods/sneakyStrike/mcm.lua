local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("sneakyStrike.config")
local strings = require("sneakyStrike.strings")

local template = EasyMCM.createTemplate(strings.mcm.modName)
template:saveOnClose("sneakyStrike", config)
template:register();

local page = template:createSideBarPage({
  label = strings.mcm.settings,
});
local settings = page:createCategory(strings.mcm.settings)


settings:createOnOffButton({
  label = strings.mcm.modEnabled,
  description = strings.mcm.modEnabledDesc,
  variable = EasyMCM.createTableVariable {
    id = "modEnabled",
    table = config
  }
})

local gmst = tes3.findGMST("fCombatCriticalStrikeMult").value

settings:createSlider({
  label = strings.mcm.coefShift,
  max = gmst - 1,
  description = strings.mcm.coefShiftDesc,
  variable = EasyMCM.createTableVariable {
    id = "coefShift",
    table = config
  }
})