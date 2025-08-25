local storage = require('openmw.storage')
local section = storage.globalSection('FatigueOutOfCombat_Allies')
local core    = require('openmw.core')

local settings = require('scripts.FatigueOutOfCombat.settings')
settings.initSettings()

local function getSet()
    local sv = section:get('set')
    if type(sv) == "table" then
        return sv
    else
        return {}
    end
end

local function saveSet(tbl)
    section:set('set', tbl)
end

local function onReportPlayerAlly(data)
    if data and data.id then
        local set = getSet()
        set[data.id] = {true, data.time}
        saveSet(set)
    end
end

local function onClearPlayerAlly()
    local set = getSet()
    local now = core.getSimulationTime()
    for id, entry in pairs(set) do
        if now - entry[2] > 2 then
            set[id] = nil
        end
    end
    saveSet(set)
end

return {
    eventHandlers = {
        ReportPlayerAlly = onReportPlayerAlly,
        ClearPlayerAlly  = onClearPlayerAlly,
    }
}
