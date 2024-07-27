local core = require('openmw.core')
local ui = require('openmw.ui')
local self = require('openmw.self')
local async = require('openmw.async')
local I = require("openmw.interfaces")
local T = require('openmw.types')

local S = require('scripts.BMSO.settings')
local C = require("scripts.BMSO.common")

I.Settings.registerPage {
    key = S.MOD_NAME,
    l10n = S.MOD_NAME,
    name = "name",
    description = C.getDescriptionIfOpenMWTooOld("description")
}

local currentNpc

local function onActive()
    if not S.isLuaApiRecentEnough then
        async:newSimulationTimer(
                4,
                async:registerTimerCallback(
                        "oldOpenMwWarning",
                        function()
                            local msg = core.l10n(S.MOD_NAME, 'en')
                            if S.isOpenMW049 then
                                ui.showMessage(msg("requiresNewerOpenmw49"))
                            else
                                ui.showMessage(msg("requiresOpenmw49"))
                            end
                        end
                )
        )
    end
end

local function uiModeChanged(data)
    --C.debugPrint('UI mode changed from %s to %s (%s)', data.oldMode, data.newMode, tostring(data.arg))
    if data.arg ~= nil and data.arg.type == T.NPC and data.oldMode == nil and data.newMode == "Dialogue" then
        local npc = T.NPC.record(data.arg)
        if npc.servicesOffered["Barter"] then
            currentNpc = data.arg
            C.debugPrint("Detected merchant '%s' (%s)", npc.name, npc.id)
            currentNpc:sendEvent('handleStats', {
                { type = "computeStats", player = self },
                { type = "boost", kind = "attributes", statId = "personality" },
            })
        end
    elseif data.newMode == "Barter" then
        if currentNpc == nil then
            print("Error: Barter without current NPC")
            return
        end
        currentNpc:sendEvent('handleStats', {
            { type = "restore", kind = "attributes", statId = "personality" },
            { type = "boost", kind = "skills", statId = "mercantile" },
        })
    elseif data.oldMode == "Barter" then
        if currentNpc == nil then
            print("Error: Return to dialogue without current NPC")
            return
        end
        currentNpc:sendEvent('handleStats', {
            { type = "restore", kind = "skills", statId = "mercantile" },
            { type = "boost", kind = "attributes", statId = "personality" },
        })
    elseif currentNpc ~= nil and data.oldMode == "Dialogue" and data.newMode == nil then
        currentNpc:sendEvent('handleStats', {
            { type = "restore", kind = "attributes", statId = "personality" },
        })
        currentNpc = nil
    end
end

return {
    engineHandlers = {
        onActive = onActive,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
    }
}
