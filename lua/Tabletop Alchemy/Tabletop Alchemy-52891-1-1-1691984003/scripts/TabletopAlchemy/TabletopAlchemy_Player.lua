local core = require("openmw.core")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")
local input = require("openmw.input")

if types.Player.quests == nil then
    I.Settings.registerPage {
        key = 'TabletopAlchemy',
        l10n = 'TabletopAlchemy',
        name = 'Tabletop Alchemy',
        description = 'This version of OpenMW is too old. Update to the latest 0.49 or development release.',
    }
    error("This version of OpenMW is too old. Update to the latest 0.49 or development release.")
end
I.Settings.registerPage {
    key = "TabletopAlchemy",
    l10n = "TabletopAlchemy",
    name = "Tabletop Alchemy",
    description = ""
}
I.Settings.registerGroup {
    key = "SettingsTTAlchemy",
    page = "TabletopAlchemy",
    l10n = "TabletopAlchemy",
    name = 'Settings',
    permanentStorage = true,
    settings = {
        {
            key = "UseOwnedContainers",
            renderer = "checkbox",
            name = "Allow using Owned Containers",
            description =
            "If set to true, you will be able to use ingredients from containers that are owned by other actors.",
            default = false
        },
        {
            key = "UseDeadBodies",
            renderer = "checkbox",
            name = "Allow using Dead Bodies",
            description =
            "If set to true, you will be able to use ingredients from nearby dead creatures or NPCs. Note that they may despawn if they are permanent.",
            default = false
        },
    }
}

local SettingsTTA = storage.playerSection("SettingsTTAlchemy")

SettingsTTA:subscribe(async:callback(function(section, key)
    if key then
        core.sendGlobalEvent("TabletopAlchemyUpdateSetting", { key = key, value = SettingsTTA:get(key) })
    end
end))
local function TTA_setControlState(state)
    input.setControlSwitch(input.CONTROL_SWITCH.Controls, state)
end
local function TTA_ShowMessage(msg)

ui.showMessage(msg)
end
return{eventHandlers = {TTA_ShowMessage = TTA_ShowMessage,TTA_setControlState = TTA_setControlState,}}