local storage = require('openmw.storage')
local async = require('openmw.async')
local core = require("openmw.core")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local commonData = require("scripts.quest_guider_lite.common")


local this = {}

this.data = require("scripts.quest_guider_lite.config").data

this.storageSections = {
    storage.playerSection(commonData.configJournalSectionName),
    storage.playerSection(commonData.configUISectionName),
    storage.playerSection(commonData.configTrackingSectionName),
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
        core.sendGlobalEvent("QGL:updateConfigData", this.data)
    end))

    this.loadFromStorage(section)
    core.sendGlobalEvent("QGL:updateConfigData", this.data)
end


function this.setValue(str, val)
    for _, section in pairs(this.storageSections) do
        if section:get(str) ~= nil then
            section:set(str, val)
        end
    end
    return tableLib.setValueByPath(this.data, str, val)
end

function this.getValue(str)
    return tableLib.getValueByPath(this.data, str)
end

return this