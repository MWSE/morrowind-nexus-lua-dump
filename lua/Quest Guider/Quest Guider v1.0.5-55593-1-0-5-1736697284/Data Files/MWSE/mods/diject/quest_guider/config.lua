local tableLib = include("diject.quest_guider.utils.table")
local log = include("diject.quest_guider.utils.log")

local storageName = "Quest_Guider_Config"

local this = {}

this.firstInit = true

---@class questGuider.config
this.default = {
    main = {
        enabled = true,
        helpLabels = true,
        iconProfile = "default",
    },
    journal = {
        enabled = true,
        info = {
            enabled = true,
            tooltip = true,
        },
        requirements = {
            enabled = false,
            tooltip = true,
            currentByDefault = true,
            scriptValues = true,
            pathDescriptions = 5,
        },
        map = {
            enabled = true,
            tooltip = true,
            maxScale = 3,
        },
        objectNames = 3,
    },
    map = {
        enabled = true,
        showJournalTextTooltip = true,
    },
    tooltip = {
        width = 400,
        object = {
            enabled = true,
            invNamesMax = 3,
            startsNamesMax = 3,
        },
        door = {
            enabled = true,
            starterNames = 3,
            starterQuestNames = 3,
            objectNames = 3,
            npcNames = 3,
        },
        tracking = {
            maxPositions = 50,
        }
    },
    tracking = {
        quest = {
            enabled = true,
            finished = false, -- autotrack finished
        },
        maxPositions = 20,
        maxCellDepth = 12,
        giver = {
            enabled = true,
            hideStarted = true,
            namesMax = 3,
        },
    },
    init = {
        ignoreDataChanges = false,
    },
    data = {
        maxPos = 50,
    },
}

this.protected = {
    tracking = {
        interior = {
            depthConut = 2,
            depthMaxDifference = 3,
        },
    },
}

---@class questGuider.config
this.data = mwse.loadConfig(storageName)

if this.data then
    tableLib.addMissing(this.data, this.default)
    this.firstInit = false
else
    this.data = table.deepcopy(this.default)
    mwse.saveConfig(storageName, this.data)
end


function this.save()
    mwse.saveConfig(storageName, this.data)
end

---@param path string
---@return any
function this.getValueByPath(path)
    return tableLib.getValueByPath(this.data, path)
end

---@param path string
---@param newValue any
---@return boolean success
function this.setValueByPath(path, newValue)
    return tableLib.setValueByPath(this.data, path, newValue)
end

return this