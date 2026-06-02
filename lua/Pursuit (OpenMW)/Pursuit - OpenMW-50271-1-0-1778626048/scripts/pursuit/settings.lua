local I = require("openmw.interfaces")
local core = require("openmw.core")

local key_group_1 = "Settings!_Pursuit_!"
local key_group_2 = "Settings!_PursuitExtra_!"
local key_group_3 = "Settings!_PursuitDebug_!"

local settings = {}

function settings:updateCoreSettings()
    I.Settings.registerGroup {
        key = key_group_1,
        page = "pursuit",
        l10n = "pursuit",
        name = "settings_group1_name",
        permanentStorage = true,
        order = 0,
        settings = {
            {
                key = "isActive",
                renderer = "checkbox",
                name = "settings_group1_setting1_name",
                description = "settings_group1_setting1_desc",
                default = true,
                argument = {
                    trueLabel = core.getGMST("sYes"),
                    falseLabel = core.getGMST("sNo")
                }
            },
            {
                key = "useNavmesh",
                renderer = "checkbox",
                name = "settings_group1_setting3_name",
                description = "settings_group1_setting3_desc",
                default = true,
                argument = {
                    trueLabel = core.getGMST("sYes"),
                    falseLabel = core.getGMST("sNo")
                }
            },
            {
                key = "actorReturn",
                renderer = "checkbox",
                name = "settings_group1_setting4_name",
                description = "settings_group1_setting4_desc",
                default = true,
                argument = {
                    trueLabel = core.getGMST("sYes"),
                    falseLabel = core.getGMST("sNo")
                }
            },
            {
                key = "maxPursueTime",
                renderer = "number",
                name = "settings_group1_setting2_name",
                description = "settings_group1_setting2_desc",
                default = 15
            },
        }
    }
end

function settings:updateExtraSettings(extraSettings)
    I.Settings.registerGroup {
        key = key_group_2,
        page = "pursuit",
        l10n = "pursuit",
        name = "settings_group2_name",
        permanentStorage = true,
        order = 1,
        settings = extraSettings
    }
end

function settings:updateDebugSettings()
    I.Settings.registerGroup {
        key = key_group_3,
        page = "pursuit",
        l10n = "pursuit",
        name = "settings_group3_name",
        permanentStorage = true,
        order = 2,
        settings = {
            {
                key = "Debug",
                renderer = "checkbox",
                name = "settings_group3_setting1_name",
                description = "settings_group3_setting1_desc",
                default = false,
                argument = {
                    trueLabel = core.getGMST("sYes"),
                    falseLabel = core.getGMST("sNo")
                }
            },
        }
    }
end

function settings:updateSettings(extraSettings)
    self:updateCoreSettings()
    self:updateExtraSettings(extraSettings)
    self:updateDebugSettings()
end

return settings
