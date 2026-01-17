local I = require("openmw.interfaces")

local mDef = require('scripts.FairCare.config.definition')

local currentNpc

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local function uiModeChanged(data)
    if data.arg and not data.oldMode and data.newMode == "Dialogue" then
        if data.arg.type.record(data.arg).servicesOffered["Spells"] then
            currentNpc = data.arg
            currentNpc:sendEvent(mDef.events.removeTouchHealSpell)
        end
    elseif currentNpc and data.oldMode == "Dialogue" and not data.newMode then
        currentNpc:sendEvent(mDef.events.addTouchHealSpell)
        currentNpc = nil
    end
end

return {
    eventHandlers = {
        UiModeChanged = uiModeChanged,
    }
}
