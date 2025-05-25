local I = require("openmw.interfaces")

local mDef = require('scripts.FairCare.config.definition')
local mTools = require('scripts.FairCare.util.tools')

local currentNpc

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local function uiModeChanged(data)
    if data.arg ~= nil and data.oldMode == nil and data.newMode == "Dialogue" then
        local npc = mTools.getRecord(data.arg)
        if npc.servicesOffered["Spells"] then
            currentNpc = data.arg
            currentNpc:sendEvent(mDef.events.removeTouchHealSpell)
        end
    elseif currentNpc and data.oldMode == "Dialogue" and data.newMode == nil then
        currentNpc:sendEvent(mDef.events.addTouchHealSpell)
        currentNpc = nil
    end
end

return {
    eventHandlers = {
        UiModeChanged = uiModeChanged,
    }
}
