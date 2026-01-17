local I = require("openmw.interfaces")

local mDef = require("scripts.TakeCover.definition")

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}