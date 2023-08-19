
local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local async = require("openmw.async")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")

local Actor = require("openmw.types").Actor
local myModData = storage.globalSection("MundisData")




if core.API_REVISION > 29 then
    I.Settings.registerPage {
        key = "SettingsMundis",
        l10n = "SettingsMundis",
        name = "MUNDIS",
        description = "These settings allow you to modify the behavior of the MUNDIS."
    }
I.Settings.registerGroup {
    key = "SettingsMundis",
    page = "SettingsMundis",
    l10n = "SettingsMundis",
    name = "Main Settings",
    permanentStorage = true,
    
    settings = {
        {
            key = "enableCheats",
            renderer = "checkbox",
            name = "Enable Mundis Cheats",
            description =
            "If enabled, will allow followers to teleport with you when you cast recall.",
            default = false
        },
        {
            key = "enableLegacySummon",
            renderer = "checkbox",
            name = "Enable Legacy Summon",
            description =
            "If Legacy Summon is enabled, the summon spell will attempt to teleport to a predetermined location, if it can't find one, it will use the position in front of you.",
            default = false
        }
    },

}
else
    I.Settings.registerPage {
        key = "SettingsMundis",
        l10n = "SettingsMundis",
        name = "MUNDIS",
        description = "These settings allow you to modify the behavior of the MUNDIS.\n\nPlease note that the mod functionality is limited in OpenMW 0.48. It will work better in 0.49.\n\nSorters, Merchants, and the power system will not function in 0.48."
    }
    I.Settings.registerGroup {
        key = "SettingsMundis",
        page = "SettingsMundis",
        l10n = "SettingsMundis",
        name = "Main Settings",
        permanentStorage = true,
        
        settings = {
            {
                key = "enableLegacySummon",
                renderer = "checkbox",
                name = "Enable Legacy Summon",
                description =
                "If Legacy Summon is enabled, the summon spell will attempt to teleport to a predetermined location, if it can't find one, it will use the position in front of you.",
                default = false
            }
        },
    
    }
end

local playerSettings = storage.playerSection("SettingsMundis")
playerSettings:subscribe(async:callback(function(section, key)
    if key then

        
            core.sendGlobalEvent("setSettingMundis", {
                key = key,
                value = playerSettings:get(key),
                player = self
            })
        
    end
end))
