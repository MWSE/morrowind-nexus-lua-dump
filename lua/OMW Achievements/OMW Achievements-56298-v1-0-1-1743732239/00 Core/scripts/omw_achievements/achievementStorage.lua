local storage = require('openmw.storage')
local achievements = require('scripts.omw_achievements.achievements.achievements')
local ui = require('openmw.ui')
local types = require('openmw.types')
local self = require('openmw.self')

local function tableToString(tbl)
    local result = "{"
    for i, v in ipairs(tbl) do
        result = result .. string.format("%q", v) .. (i < #tbl and ", " or "")
    end
    result = result .. "}"
    return result
end

local function stringToTable(str)
    local tbl = {}
    str = str:match("{(.*)}")
    if not str or str:match("^%s*$") then
        return tbl
    end
    for word in str:gmatch('"(.-)"') do
        table.insert(tbl, word)
    end
    return tbl
end

local function createStorage(data)

    currentSaveDir = data.currentSaveDir

    local count = 0
    for _ in pairs(data) do
        count = count + 1
    end

    if count > 1 then
        self.object:sendEvent('updateStorage', data )
    end

end

local function updateStorage(data)

    local macData = storage.playerSection(data.currentSaveDir)
    local temporaryTable = data

    for k, v in pairs(temporaryTable) do
        if k == "OMWACounters" then
            OMWACounters = temporaryTable["OMWACounters"]
            temporaryTable["OMWACounters"] = nil
        end

        if k == "currentSaveDir" then
            print('Found currentSaveDir in temporaryTable')
            temporaryTable["currentSaveDir"] = nil
        end
    end

    if OMWACounters ~= nil then
        OMWACounters = stringToTable(OMWACounters)
        for i, v in ipairs(OMWACounters) do
            if temporaryTable[v] then
                temporaryTable[v] = stringToTable(v)
            end
        end
    end

    for k, v in pairs(temporaryTable) do
        macData:set(k, v)
    end

end

local function createTemporaryPlayerSection()

    currentStorage = "temporary"

    local macData = storage.playerSection('OMWA_Temporary_Section')

    macData:setLifeTime(storage.LIFE_TIME.Temporary)

    --- Initialize storage for achievements
    for i = 1, #achievements do 
        local achievementSection = macData:get(achievements[i].id)
        if achievementSection == nil then
            macData:set(achievements[i].id, false)
        end
    end

    --- Counters for unique achievements
    if macData:get("bookRead") == nil then
        macData:set("bookRead", {})
    end

    return macData

end

local function createPlayerSection()

    currentStorage = "savedir"

    local macData = storage.playerSection(currentSaveDir)

    macData:setLifeTime(storage.LIFE_TIME.Persistent)

    --- Initialize storage for achievements
    for i = 1, #achievements do 
        local achievementSection = macData:get(achievements[i].id)
        if achievementSection == nil then
            macData:set(achievements[i].id, false)
        end
    end

    --- Counters for unique achievements
    if macData:get("bookRead") == nil then
        macData:set("bookRead", {})
    end

    return macData

end

local function getStorage()
    if currentSaveDir ~= nil then
        return createPlayerSection()
    else
        return createTemporaryPlayerSection()
    end
end

local function onSave()
    
    if currentStorage == "temporary" then

        local temporarySection = createTemporaryPlayerSection()
        local temporaryTable = temporarySection:asTable()
        local OMWACounters = {}

        for k, v in pairs(temporaryTable) do
            if type(v) == "table" then
                temporaryTable[k] = tableToString(v)
                table.insert(OMWACounters, tostring(k))
            end
        end

        if #OMWACounters ~= 0 then
            temporaryTable['OMWACounters'] = tableToString(OMWACounters)
        end

        types.Player.sendMenuEvent(self.object, 'requireCurrentSaveDir', temporaryTable)

    end

end

return {
    interfaceName = "storageUtils",
    interface = {
        version = 1,
        getStorage = getStorage,
    },
    eventHandlers = {
        createStorage = createStorage,
        updateStorage = updateStorage
    },
    engineHandlers = {
        onSave = onSave
    }
}