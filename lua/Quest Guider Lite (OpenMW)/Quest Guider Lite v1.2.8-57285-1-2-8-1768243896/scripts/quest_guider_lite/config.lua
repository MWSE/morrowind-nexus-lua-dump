local util = require('openmw.util')

local commonData = require("scripts.quest_guider_lite.common")
local tableLib = require("scripts.quest_guider_lite.utils.table")


local this = {}

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
        toggleVisibilityKey = "P",
        toggleVisibilityByJournalKey = false,
    },
    journal = {
        overrideJournal = false,
        menuKey = "H",
        objectNames = 3,
        widthProportional = 80, -- %
        heightProportional = 70, -- %
        width = 1100,
        height = 700,
        position = { -- %
            x = 10,
            y = 10,
        },
        listRelativeSize = 30, -- %
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
    },
}


---@class questGuider.config
this.data = tableLib.deepcopy(this.default)

return this