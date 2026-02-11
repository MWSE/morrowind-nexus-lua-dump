local core = require("openmw.core")
local async = require("openmw.async")

local mDef = require("scripts.fresh-loot.config.definition")
local mT = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")

local l10n = core.l10n(mDef.MOD_NAME);

local logMode = mStore.cfg.logMode.get()

local function log(str, level)
    level = level or mT.logLevels.Info
    if level <= logMode then
        print(l10n(mStore.cfg.logMode.keys[level]) .. ": " .. str)
    end
end

mStore.section.global.get():subscribe(async:callback(function(_, key)
    if key == mStore.cfg.logMode.key then
        logMode = mStore.cfg.logMode.get()
    end
end))

return log