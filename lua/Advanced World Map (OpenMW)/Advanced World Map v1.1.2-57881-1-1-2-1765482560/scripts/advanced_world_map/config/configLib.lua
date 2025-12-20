local storage = require('openmw.storage')
local async = require('openmw.async')
local core = require("openmw.core")

local tableLib = require("scripts.advanced_world_map.utils.table")
local commonData = require("scripts.advanced_world_map.common")


local this = {}

this.data = require("scripts.advanced_world_map.config.config").data

local defaultStorage = storage.playerSection(commonData.configMiscSectionName)

this.storageSections = {
    storage.playerSection(commonData.configMainSectionName),
    storage.playerSection(commonData.configLegendSectionName),
    storage.playerSection(commonData.configTilesetSectionName),
    storage.playerSection(commonData.configFastTravelSectionName),
    storage.playerSection(commonData.configDataSectionName),
    storage.playerSection(commonData.configUISectionName),
    storage.playerSection(commonData.configNotesSectionName),
    defaultStorage,
}


function this.loadFromStorage(section)
    local data = section:asTable() or {}
    for path, value in pairs(data) do
        tableLib.setValueByPath(this.data, path, value)
    end
end

for _, section in pairs(this.storageSections) do
    section:subscribe(async:callback(function(s, key)
        if key then
            tableLib.setValueByPath(this.data, key, section:get(key))
        else
            this.loadFromStorage(section)
        end
        core.sendGlobalEvent("AdvWMap:updateConfigData", this.data)
    end))

    this.loadFromStorage(section)
    core.sendGlobalEvent("AdvWMap:updateConfigData", this.data)
end


function this.setValue(str, val)
    local wasSet = false
    for _, section in pairs(this.storageSections) do
        if section:get(str) ~= nil then
            section:set(str, val)
            wasSet = true
        end
    end
    if not wasSet then
        defaultStorage:set(str, val)
    end
    return tableLib.setValueByPath(this.data, str, val)
end

function this.getValue(str)
    return tableLib.getValueByPath(this.data, str)
end

return this