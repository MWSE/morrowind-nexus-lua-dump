local I = require("openmw.interfaces")
local input = require('openmw.input')
local storage = require('openmw.storage')

local config = require("scripts.quest_guider_lite.config")
local commonData = require("scripts.quest_guider_lite.common")
local dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")

storage.playerSection(commonData.configJournalSectionName):setLifeTime(storage.LIFE_TIME.Persistent)
storage.playerSection(commonData.configTrackingSectionName):setLifeTime(storage.LIFE_TIME.Persistent)
storage.playerSection(commonData.configUISectionName):setLifeTime(storage.LIFE_TIME.Persistent)
storage.playerSection(commonData.configInputSectionName):setLifeTime(storage.LIFE_TIME.Persistent)

I.Settings.registerGroup{
    key = commonData.configQuestDataSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "questData",
    permanentStorage = true,
    order = 4,
    settings = {
        {
            key = "statusMessage",
            renderer = "QGL:Renderer:text",
            name = "status",
            default = "",
        },
        {
            key = "disabled",
            renderer = "checkbox",
            name = "disableQuestData",
            description = "disableQuestDataDescription",
            default = false,
        }
    },
}

local res, err = pcall(function()
    local bindingSection = storage.playerSection("OMWInputBindings")

    local inputModSettings = storage.playerSection(commonData.configInputSectionName)

    local initialized = inputModSettings:get("input.initialized")
    if initialized then return end

    local binds = bindingSection:asTable()
    local function getKey(triggerId)
        for kId, dt in pairs(binds) do
            if dt.key == triggerId and dt.button then
                if dt.device == "keyboard" then
                    for k, id in pairs(input.KEY) do
                        if dt.button == id then
                            return k, kId
                        end
                    end
                elseif dt.device == "mouse" then
                    local keys = {"LMB", "MMB", "RMB", "MB4", "MB5"}
                    return keys[dt.button], kId
                elseif dt.device == "controller" then
                    for k, id in pairs(input.CONTROLLER_BUTTON) do
                        if dt.button == id then
                            return "C_"..tostring(k), kId
                        end
                    end
                end
            end
        end
    end

    local trackingSection = storage.playerSection(commonData.configTrackingSectionName)
    local mainModSettings = storage.playerSection(commonData.configJournalSectionName)
    local journalMenuKey, journalKeySectionId = getKey(commonData.journalMenuTriggerId)

    if journalMenuKey ~= nil then
        bindingSection:set(journalKeySectionId, nil)
        I.DijectKeyBindings.registerKey(commonData.journalMenuTriggerId, journalMenuKey)
        if trackingSection:get("tracking.toggleVisibilityByJournalKey") == true then
            I.DijectKeyBindings.registerKey(commonData.toggleMarkersTriggerId, "LeftShift + "..journalMenuKey)
        end
        I.DijectKeyBindings.registerKey(commonData.allQuestsTriggerId, "LeftShift + LeftCtrl + "..journalMenuKey)
    end

    local trackingModSettings = storage.playerSection(commonData.configTrackingSectionName)
    local toggleTrackingKey, toggleTrackingSectionId = getKey(commonData.toggleMarkersTriggerId)
    if toggleTrackingKey ~= nil then
        bindingSection:set(toggleTrackingSectionId, nil)
        I.DijectKeyBindings.registerKey(commonData.toggleMarkersTriggerId, toggleTrackingKey)
        inputModSettings:set("input.keys.toggleMarkersVisibility", toggleTrackingKey)
        trackingModSettings:set("tracking.toggleVisibilityKey", nil)
    end

    I.DijectKeyBindings.registerKey(commonData.nextQuestTriggerId, config.default.input.keys.nextQuest)
    I.DijectKeyBindings.registerKey(commonData.previousQuestTriggerId, config.default.input.keys.previousQuest)
    I.DijectKeyBindings.registerKey(commonData.toggleTrackObjectsTriggerId, config.default.input.keys.toggleTrackObjects)
    I.DijectKeyBindings.registerKey(commonData.trackObjectsTriggerId, config.default.input.keys.trackObjects)
    I.DijectKeyBindings.registerKey(commonData.untrackObjectsTriggerId, config.default.input.keys.untrackObjects)
    I.DijectKeyBindings.registerKey(commonData.toggleTopTopicsTriggerId, config.default.input.keys.toggleTopTopics)

    if not journalMenuKey then
        I.DijectKeyBindings.registerKey(commonData.journalMenuTriggerId, config.default.journal.menuKey)
        I.DijectKeyBindings.registerKey(commonData.allQuestsTriggerId, config.default.input.keys.allQuestsMenu)
        I.DijectKeyBindings.registerKey(commonData.toggleMarkersTriggerId, config.default.input.keys.toggleMarkersVisibility)
    end

    inputModSettings:set("input.initialized", true)
end)
if not res then
    print(err)
end

dataHandler.initStorage()

return {

}
