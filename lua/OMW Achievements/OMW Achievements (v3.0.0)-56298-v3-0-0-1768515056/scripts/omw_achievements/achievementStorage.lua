local storage = require('openmw.storage')
local achievements = require('scripts.omw_achievements.achievements.achievements')
local types = require('openmw.types')
local self = require('openmw.self')
local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')

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
        end

        if k == "currentSaveDir" then
            print('Found currentSaveDir in temporaryTable')
        end
    end

    if OMWACounters ~= nil then
        OMWACounters = stringToTable(OMWACounters)
        for i, v in ipairs(OMWACounters) do
            if temporaryTable[v] then
                temporaryTable[v] = stringToTable(temporaryTable[v])
            end
        end
    end

    for k, v in pairs(temporaryTable) do
        macData:set(k, v)
    end

end

local function createGlobalStorage()

    local omwaData = storage.playerSection('OMWA_Global_Section')

    omwaData:setLifeTime(storage.LIFE_TIME.Persistent)

    --- Initialize storage for achievements
    for i = 1, #achievements do 
        local achievementSection = omwaData:get(achievements[i].id)
        if achievementSection == nil then
            omwaData:set(achievements[i].id, false)
        end
    end
    
    return omwaData

end

local function createTemporaryPlayerSection()

    currentStorage = "temporary"

    local macData = storage.playerSection('OMWA_Temporary_Section')

    macData:setLifeTime(storage.LIFE_TIME.Temporary)

    --- Counters for achievement types "read_all", "global_variable" and "visit_all"
    if macData:get("bookRead") == nil then
        macData:set("bookRead", {})
    end

    if macData:get("visitedCells") == nil then
        macData:set("visitedCells", {})
    end

    if macData:get("globalVariables") == nil then
        macData:set("globalVariables", {})
    end

    --- Counters for unique achievements
    if macData:get("museumArtifacts") == nil then
        macData:set("museumArtifacts", {})
    end

    if macData:get("skoomaBottles") == nil then
        macData:set("skoomaBottles", 0)
    end

    if macData:get("slavesCounter") == nil then
        macData:set("slavesCounter", 0)
    end

    return macData

end

local function createPlayerSection()

    currentStorage = "savedir"

    local macData = storage.playerSection(currentSaveDir)

    macData:setLifeTime(storage.LIFE_TIME.Persistent)

    --- Counters for achievement types "read_all", "global_variable" and "visit_all"
    if macData:get("bookRead") == nil then
        macData:set("bookRead", {})
    end

    if macData:get("visitedCells") == nil then
        macData:set("visitedCells", {})
    end

    if macData:get("globalVariables") == nil then
        macData:set("globalVariables", {})
    end

    --- Counters for unique achievements
    if macData:get("museumArtifacts") == nil then
        macData:set("museumArtifacts", {})
    end

    if macData:get("skoomaBottles") == nil then
        macData:set("skoomaBottles", 0)
    end

    if macData:get("slavesIds") == nil then
        macData:set("slavesIds", {})
    end

    return macData

end

local function updateGlobalVariables(data)

    if currentSaveDir == nil then
        local macData = createTemporaryPlayerSection()
        macData:set("globalVariables", sk00maUtils.stringToTable(data))
    elseif currentSaveDir ~= nil then
        local macData = createPlayerSection()
        macData:set("globalVariables", sk00maUtils.stringToTable(data))
    end

end

local function getStorage(section)

    if section == "counters" and currentSaveDir ~= nil then
        return createPlayerSection()
    elseif section == "counters" and currentSaveDir == nil then
        return createTemporaryPlayerSection()
    end

    if section == "achievements" then
        return createGlobalStorage()
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
        version = 2,
        getStorage = getStorage,
    },
    eventHandlers = {
        createStorage = createStorage,
        updateStorage = updateStorage,
        updateGlobalVariables = updateGlobalVariables
    },
    engineHandlers = {
        onSave = onSave
    }
}