local util = require('openmw.util')

local reqTypes = require("scripts.quest_guider_lite.types.requirement")

local this = {}

this.modName = "Quest Guider Lite"
this.interfaceName = "QuestGuiderLite"

this.l10nKey = "quest_guider_lite"

this.settingPage = "QuestGuiderLite:Settings"

this.configJournalSectionName = "Settings:QGL:Journal"
this.configUISectionName = "Settings:QGL:UI"
this.configQuestDataSectionName = "Settings:QGL:QuestData"
this.configTrackingSectionName = "Settings:QGL:Tracking"
this.settingStorageToRemoveId = "Settings:QGL:ToRemove"

this.miscPalyerStorage = "QuestGuider:MiscPlayerStorage"

this.elementMetatableTypes = {
    ["nextStages"] = "nextStages",
}

this.dataStorageName = "QuestGuider:dataStorage"
this.localDataName = "QuestGuider:playerData"

this.journalMenuTriggerId = "QGL:journal.menuKey"
this.toggleMarkersTriggerId = "QGL:markers.toggleVisibility"

this.defaultColorData = {202/255, 165/255, 96/255}
this.defaultColor = util.color.rgb(this.defaultColorData[1], this.defaultColorData[2], this.defaultColorData[3])

this.selectedColorData = {0.2, 1, 0.2}
this.selectedColor = util.color.rgb(this.selectedColorData[1], this.selectedColorData[2], this.selectedColorData[3])

this.journalDateColorData = {0.8, 0.2, 0.2}
this.journalDateColor = util.color.rgb(this.journalDateColorData[1], this.journalDateColorData[2], this.journalDateColorData[3])

this.journalLinkColorData = {112 / 255, 126 / 255, 207 / 255}
this.journalLinkColor = util.color.rgb(this.journalLinkColorData[1], this.journalLinkColorData[2], this.journalLinkColorData[3])

this.objectColorData = {51 / 255, 229 / 255, 153 / 255}
this.objectColor = util.color.rgb(this.objectColorData[1], this.objectColorData[2], this.objectColorData[3])

this.disabledColorData = {0.5, 0.5, 0.5}
this.disabledColor = util.color.rgb(this.disabledColorData[1], this.disabledColorData[2], this.disabledColorData[3])

this.selectedShadowColorData = {1, 1, 1}
this.selectedShadowColor = util.color.rgb(this.selectedShadowColorData[1], this.selectedShadowColorData[2], this.selectedShadowColorData[3])

this.backgroundColorData = {0, 0, 0}
this.backgroundColor = util.color.rgb(this.backgroundColorData[1], this.backgroundColorData[2], this.backgroundColorData[3])

this.mapWaterColor = util.color.rgb(36 / 255, 53 / 255, 48 / 255)

this.whiteTexture = nil
pcall(function ()
    local constants = require('scripts.omw.mwui.constants')
    this.whiteTexture = constants.whiteTexture
end)

this.playerQuestDataLabel = "playerQuests"
this.killCounterDataLabel = "killCounter"


this.hudMarkerPath = "textures/icons/quest_guider/HUDMarker.dds"
this.hudQuestionMarkPath = "textures/icons/quest_guider/HUDQuestionMark.dds"
this.hudExclamationMarkPath = "textures/icons/quest_guider/HUDExclamationMark.dds"
this.exclamationMarkPath = "textures/icons/quest_guider/exclamationMark.dds"
this.doorMarkPath = "textures/icons/quest_guider/toDoorIcon.dds"
this.doorExclMarkPath = "textures/icons/quest_guider/doorExclIcon.dds"
this.mapMarkerPath = "textures/icons/quest_guider/mapMarker.dds"
this.playerMapMarkerPath = "textures/icons/quest_guider/playerMapMarker.dds"

this.questGiverGroup = "~__QGL:GIVER__"

this.forbiddenForTracking = {
    ["DIAO"] = true,
}


this.journalMenuId = "__QGL:Journal__"
this.allQuestsMenuId = "__QGL:AllQuests__"
this.topicsMenuId = "__QGL:Topics__"
this.trackingMenuId = "__QGL:Tracking__"
this.simpleMapMenuId = "__QGL:Journal__"
this.messageBoxMenuId = "__QGL:MessageBox__"


function this.colorToArray(color)
    return {color.r, color.g, color.b, color.a}
end

return this