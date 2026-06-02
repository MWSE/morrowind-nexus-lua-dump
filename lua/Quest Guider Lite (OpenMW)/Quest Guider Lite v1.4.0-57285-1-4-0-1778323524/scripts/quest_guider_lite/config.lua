local util = require('openmw.util')

local commonData = require("scripts.quest_guider_lite.common")
local tableLib = require("scripts.quest_guider_lite.utils.table")


local this = {}

this.inputSectionVersion = 1

---@class questGuider.config
this.default = {
    tracking = {
        autoTrack = true,
        autoTrackSideBranches = false,
        autoTrackOneEntryDialogues = false,
        trackDisabled = false,
        questGivers = true,
        colored = true,
        minChance = 20, -- %
        maxPos = 20,
        proximity = 2000,
        questGiverProximity = 100,
        hudMarkers = {
            enabled = true,
            range = 60,
            rayTracing = true,
            opacity = 100, -- %
            details = {
                givers = true,
                markers = true,
            }
        },
        proximityMarkers = {
            enabled = true,
            details = {
                givers = true,
                markers = true,
            }
        },
        advWMapMarkers = {
            enabled = true,
            size = 12,
            wSize = 18,
            maxWorldMapMarkersForCell = 2,
            details = {
                givers = true,
                markers = true,
            }
        },
        toggleVisibilityKey = "P", -- deprecated
        toggleVisibilityByJournalKey = false, -- deprecated
    },
    journal = {
        overrideJournal = false,
        menuKey = "H",
        objectNames = 3,
        widthProportional = 75, -- %
        heightProportional = 70, -- %
        width = 1100,
        height = 700,
        position = { -- %
            x = 12,
            y = 15,
        },
        listRelativeSize = 25, -- %
        trackedColorMarks = true,
        maxColorMarks = 10,
        textHeightMul = 0.5, -- deprecated
        textHeightMulRecord = 0.7,
        ssqnIcons = true,
        mouseScrollAmount = 40,
        topicTextMaxLenToProcess = 20000, -- deprecated
        maxTopicEntriesInTopicMenu = 5,
        maxTopicEntriesInJournal = 2,
        maxPosDescrInTracking = 3,
        mapByDefault = true,
        useGlobalDate = true,
        firstInitMenu = true,
        fuzzyTopicMatching = true,
        bottomInfoText = {
            enabled = true,
        },
    },
    ui = {
        fontSize = 20,
        defaultColor = commonData.defaultColor,
        backgroundColor = commonData.backgroundColor,
        disabledColor = commonData.disabledColor,
        dateColor = commonData.journalDateColor,
        selectionColor = commonData.selectedColor,
        shadowColor = commonData.selectedShadowColor,
        linkColor = commonData.journalLinkColor,
        objectColor = commonData.objectColor,
        scrollArrowSize = 16,
        headerBackgroundAlpha = 50,
        tooltipDelay = 1, -- local
    },
    input = {
        version = nil,
        gamepadJournalScroll = true,
        keys = {
            allQuestsMenu = "LeftShift + LeftCtrl + H", -- global
            topicMenu = nil, -- global
            trackingMenu = nil, -- global
            toggleMarkersVisibility = nil, -- global
            nextQuest = "C_DPadDown",
            previousQuest = "C_DPadUp",
            trackObjects = nil, -- deprecated
            untrackObjects = nil, -- deprecated
            toggleTrackObjects = "C_X",
            toggleTopTopics = "C_Y",
            topicMenuLocal = "C_RightShoulder", -- local
            nearbyMenuLocal = "C_LeftShoulder", -- local
            toggleTracking = "C_DPadRight", -- local
            toggleFinishedHidden = "C_DPadLeft", -- local
            toggleStartedHidden = "C_DPadLeft", -- local
            toggleNearby = nil, -- local
            toggleAllEntries = nil, -- local
            toggleQuestHidden = "C_RightStick", -- local
            toggleQuestPinned = nil, -- local
            toggleAlphabetical = "C_DPadLeft", -- local
        },
        initialized = false,
    },
}


---@class questGuider.config
this.data = tableLib.deepcopy(this.default)


this.keyToTriggerMap = {
    ["input.keys.allQuestsMenu"] = commonData.allQuestsTriggerId,
    ["input.keys.topicMenu"] = commonData.topicMenuTriggerId,
    ["input.keys.trackingMenu"] = commonData.trackingMenuTriggerId,
    ["input.keys.toggleMarkersVisibility"] = commonData.toggleMarkersTriggerId,
    ["input.keys.nextQuest"] = commonData.nextQuestTriggerId,
    ["input.keys.previousQuest"] = commonData.previousQuestTriggerId,
    ["input.keys.trackObjects"] = commonData.trackObjectsTriggerId, -- deprecated
    ["input.keys.untrackObjects"] = commonData.untrackObjectsTriggerId, -- deprecated
    ["input.keys.toggleTrackObjects"] = commonData.toggleTrackObjectsTriggerId,
    ["input.keys.toggleTopTopics"] = commonData.toggleTopTopicsTriggerId,
    ["input.keys.topicMenuLocal"] = commonData.topicMenuLocalTriggerId,
    ["input.keys.nearbyMenuLocal"] = commonData.nearbyMenuLocalTriggerId,
    ["input.keys.toggleTracking"] = commonData.toggleTrackingTriggerId,
    ["input.keys.toggleFinishedHidden"] = commonData.toggleFinishedHiddenTriggerId,
    ["input.keys.toggleStartedHidden"] = commonData.toggleStartedHiddenTriggerId,
    ["input.keys.toggleNearby"] = commonData.toggleNearbyTriggerId,
    ["input.keys.toggleAllEntries"] = commonData.toggleAllEntriesTriggerId,
    ["input.keys.toggleAlphabetical"] = commonData.toggleAlphabeticalTriggerId,
    ["input.keys.toggleQuestHidden"] = commonData.toggleQuestHiddenTriggerId,
    ["input.keys.toggleQuestPinned"] = commonData.toggleQuestPinnedTriggerId,
}


function this.getTrackingConfigData()
    return {
        journal = {
            objectNames = this.data.journal.objectNames,
        },
        tracking = this.data.tracking
    }
end


return this