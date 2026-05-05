local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local tableLib = require("scripts.advanced_world_map.utils.table")
local commonData = require("scripts.advanced_world_map.common")
local eventSys = require("scripts.advanced_world_map.eventSys")

local config = require("scripts.advanced_world_map.config.config")


local this = {}

this.data = config.data
this.default = config.default

local defaultStorage = storage.playerSection(commonData.configMiscSectionName)

this.storageSections = {
    storage.playerSection(commonData.configMainSectionName),
    storage.playerSection(commonData.configLegendSectionName),
    storage.playerSection(commonData.configTilesetSectionName),
    storage.playerSection(commonData.configFastTravelSectionName),
    storage.playerSection(commonData.configDataSectionName),
    storage.playerSection(commonData.configInputSectionName),
    storage.playerSection(commonData.configUISectionName),
    storage.playerSection(commonData.configNotesSectionName),
    defaultStorage,
}


function this.loadFromStorage(section)
    local data = section:asTable() or {}
    for path, value in pairs(data) do
        local event = {
            key = path,
            value = value,
        }
        tableLib.setValueByPath(this.data, path, event.value)
        eventSys.triggerEvent(eventSys.EVENT.onConfigChanged, event)
    end
end

for _, section in pairs(this.storageSections) do
    section:subscribe(async:callback(function(s, key)
        if key then
            local value = section:get(key)
            local event = {
                key = key,
                value = value,
            }
            tableLib.setValueByPath(this.data, key, event.value)
            eventSys.triggerEvent(eventSys.EVENT.onConfigChanged, event)

            if key == "main.menuKey" then
                I.DijectKeyBindings.registerKey(commonData.menuKeyId, value)
            end
        else
            this.loadFromStorage(section)
        end
    end))

    this.loadFromStorage(section)
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
    return true
end

function this.getValue(str)
    return tableLib.getValueByPath(this.data, str)
end

return this