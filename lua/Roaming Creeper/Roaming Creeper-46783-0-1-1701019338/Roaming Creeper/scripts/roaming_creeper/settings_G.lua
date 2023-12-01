require("scripts.roaming_creeper.openmw")




I.Settings.registerGroup {
    key = "SettingsRoamingCreeperMain",
    page = "roaming_creeper",
    l10n = "roaming_creeper",
    name = "setings_modCategory1_name",
    permanentStorage = true,
    order = 0,
    settings = {
        {
            key = "Mod Status",
            renderer = "checkbox",
            name = "setings_modCategory1_setting1_name",
            description = "setings_modCategory1_setting1_desc",
            default = true,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo")
            }
        },
    }
}

I.Settings.registerGroup {
    key = "SettingsRoamingCreeperMain_misc",
    page = "roaming_creeper",
    l10n = "roaming_creeper",
    name = "setings_modCategory2_name",
    description = (function()
        local destinations = require("scripts.roaming_creeper.destinations")
        local desc = "_______________________________________________\n"
        for k, v in pairs(destinations) do
            local cell = v.cell
            desc = desc .. cell .. "\n"
        end
        return desc
    end)(),
    permanentStorage = false,
    order = 0,
    settings = {
        {
            key = "Debug",
            renderer = "checkbox",
            name = "setings_modCategory1_setting2_name",
            description = "setings_modCategory1_setting2_desc",
            default = false,
            argument = {
                trueLabel = core.getGMST("sOn"),
                falseLabel = core.getGMST("sOff")
            }
        },
    }
}

local globalSetting = storage.globalSection("SettingsRoamingCreeperMain")
local miscSetting = storage.globalSection("SettingsRoamingCreeperMain_misc")

globalSetting:subscribe(async:callback(function(sectionName, changedKey)
    if sectionName == "SettingsRoamingCreeperMain" then
        if changedKey == nil or changedKey == "Mod Status" then
            core.sendGlobalEvent("RoamingCreeper_update_eqnx", { turnedOff = not globalSetting:get("Mod Status") })
        end
    end
end))

return {
    engineHandlers = {
        onUpdate = function()
            if miscSetting:get("Debug") then
                I.RoamingCreeper_interface.nextDest(true)
            end
        end
    }
}
