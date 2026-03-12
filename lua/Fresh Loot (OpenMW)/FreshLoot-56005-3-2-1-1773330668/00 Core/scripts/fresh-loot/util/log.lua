local core = require("openmw.core")

local mDef = require("scripts.fresh-loot.config.definition")
local mT = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")

local l10n = core.l10n(mDef.MOD_NAME);

return function(str, level)
    level = level or mT.logLevels.Info
    if level <= mStore.settings.logMode.get() then
        print(l10n(mStore.settings.logMode.keys[level]) .. ": " .. str)
    end
end