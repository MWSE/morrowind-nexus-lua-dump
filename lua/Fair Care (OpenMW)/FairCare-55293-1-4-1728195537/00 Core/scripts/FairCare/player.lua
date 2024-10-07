local I = require("openmw.interfaces")

local S = require('scripts.FairCare.settings')
local mUtil = require('scripts.FairCare.util')

local currentNpc

I.Settings.registerPage {
    key = S.MOD_NAME,
    l10n = S.MOD_NAME,
    name = "name",
    description = "description",
}

local function uiModeChanged(data)
    if data.arg ~= nil and data.oldMode == nil and data.newMode == "Dialogue" then
        local npc = mUtil.getRecord(data.arg)
        if npc.servicesOffered["Spells"] then
            currentNpc = data.arg
            currentNpc:sendEvent("fc_removeHealSpells")
        end
    elseif currentNpc and data.oldMode == "Dialogue" and data.newMode == nil then
        currentNpc:sendEvent("fc_reAddHealSpells")
        currentNpc = nil
    end
end

return {
    eventHandlers = {
        UiModeChanged = uiModeChanged,
    }
}
