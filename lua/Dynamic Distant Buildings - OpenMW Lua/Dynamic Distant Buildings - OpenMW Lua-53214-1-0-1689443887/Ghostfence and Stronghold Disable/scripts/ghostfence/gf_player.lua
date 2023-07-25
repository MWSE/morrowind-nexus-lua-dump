local core = require("openmw.core")
local types = require("openmw.types")
local self = require("openmw.self")
local I = require("openmw.interfaces")
if types.Player.quests == nil then
    I.Settings.registerPage {
        key = 'SettingsGhostFence',
        l10n = 'AutoLootl10n',
        name = 'Auto Distant Buildings',
        description = 'This version of OpenMW has no lua quest support. Update to the latest 0.49 or development release.',
    }
    error("This version of OpenMW has no lua quest support. Update to the latest 0.49 or development release.")
else
    I.Settings.registerPage {
        key = 'SettingsGhostFence',
        l10n = 'AutoLootl10n',
        name = 'Auto Distant Buildings',
    }

end
local questIds = { c3_destroydagoth = 20, }
local strongIds = { hr_stronghold = 1, ht_stronghold = 2, hh_stronghold = 3 }
local function onQuestUpdate(questId, stage)
    if strongIds[questId] ~= nil then
        core.sendGlobalEvent("updateStrongholds")
    elseif questIds[questId] ~= nil then

    end
    if questId == "cO_12a" or questId == "cO_12" or questId == "colony_update" then
        core.sendGlobalEvent("updateRavenRock")
    end
    if questId == ("c3_destroydagoth") and stage >= 20 then
        core.sendGlobalEvent("disableFence_X")
    end
    print(questId, stage)
end
local function onLoad()
    core.sendGlobalEvent("onPlayerAdded", self)
end
return {
    engineHandlers = { onQuestUpdate = onQuestUpdate, onLoad = onLoad }
}
