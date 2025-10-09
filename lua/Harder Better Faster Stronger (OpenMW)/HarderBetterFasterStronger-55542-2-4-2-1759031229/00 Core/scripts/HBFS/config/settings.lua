local I = require("openmw.interfaces")

local mDef = require('scripts.HBFS.config.definition')
local mStore = require('scripts.HBFS.config.configuration')
local mTools = require('scripts.HBFS.util.tools')

local function getDescriptionIfOpenMWTooOld(key)
    if not mDef.isLuaApiRecentEnough then
        if mDef.isOpenMW049OrAbove then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

for _, section in mTools.spairs(mStore.sections, function(t, a, b) return t[a].order < t[b].order end) do
    local group = { settings = {} }
    group.key = section.key
    group.page = mDef.MOD_NAME
    group.l10n = mDef.MOD_NAME
    group.name = section.name .. "SectionTitle"
    group.description = getDescriptionIfOpenMWTooOld(section.name .. "SectionDesc")
    group.permanentStorage = false
    group.order = section.order
    for _, setting in mTools.spairs(
            mStore.settings,
            function(t, a, b) return t[a].order < t[b].order end,
            function(a) return a.section.key == section.key end) do
        setting.name = setting.key .. "_name"
        setting.description = setting.key .. "_desc"
        table.insert(group.settings, setting)
    end
    I.Settings.registerGroup(group)
end
