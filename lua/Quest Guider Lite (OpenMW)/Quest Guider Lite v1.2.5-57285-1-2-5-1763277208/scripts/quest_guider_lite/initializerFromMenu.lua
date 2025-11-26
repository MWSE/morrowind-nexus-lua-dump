local I = require("openmw.interfaces")
local dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")

local commonData = require("scripts.quest_guider_lite.common")

I.Settings.registerGroup{
    key = commonData.configQuestDataSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "questData",
    permanentStorage = true,
    order = 3,
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

dataHandler.initStorage()

return {

}