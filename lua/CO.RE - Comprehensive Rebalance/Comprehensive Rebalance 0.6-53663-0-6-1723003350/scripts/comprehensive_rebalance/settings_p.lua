local I = require("openmw.interfaces")
local core = require("openmw.core")

local MOD_NAME = "comprehensive_rebalance"

I.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "settings_modName",
    description = "settings_modDesc"
}