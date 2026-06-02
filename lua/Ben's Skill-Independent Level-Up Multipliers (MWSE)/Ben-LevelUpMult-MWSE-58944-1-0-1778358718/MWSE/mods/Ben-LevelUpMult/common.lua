local config = require("Ben-LevelUpMult.config")
local util = require("Ben-LevelUpMult.util")

this = {}

--------------------------------------------------
-- LOGGING HELPERS
--------------------------------------------------

local function getModNameAndVersion()
    return string.format("%s v%.1f", config.getModName(), config.getVersion())
end

local function log(...)
    
    if not config.getLoggingEnabled() then return end
    
    local message = ""
    local arg1, arg2 = ...
    
    if arg1 == nil
    or arg2 == nil
    then message = tostring(arg1)
    else message = string.format(...) end
    
    mwse.log("[%s] %s", getModNameAndVersion(), message)
    
end

this.log = function(...)
    return log(...)
end

this.toast = function(...)
    
    if not config.getLoggingEnabled() then return end
    
    local message = ""
    local arg1, arg2 = ...
    
    if arg1 == nil
    or arg2 == nil
    then message = tostring(arg1)
    else message = string.format(...) end
    
    tes3.messageBox("[%s]\n%s", getModNameAndVersion(), message)
    
end

--------------------------------------------------
-- OBJECT HELPERS
--------------------------------------------------

local function sortedIterateObjects(filter)

    if not config.getLoggingEnabled() then
        return tes3.iterateObjects(filter)
    end
    
    local objects = {}
    local sortedTable = {}
    
    for object in tes3.iterateObjects(filter) do
        
        objects[object.id] = object
        table.insert(sortedTable, object.id)
        
    end
    
    table.sort(sortedTable, util.sortFunction_ByStringKey)
    
    local i = 0 -- iterator variable
    local iteratorFunction = function ()
        
        i = i + 1
        if sortedTable[i] == nil then return nil
        else return objects[sortedTable[i]] end
        
    end
    
    return iteratorFunction
    
end

this.sortedIterateObjects = function(filter)
    return sortedIterateObjects(filter)
end

--------------------------------------------------
-- GMST HELPERS
--------------------------------------------------

local gmst_DisplayName = {
    [tes3.gmst.iLevelUp01Mult] = "iLevelUp01Mult",
    [tes3.gmst.iLevelUp02Mult] = "iLevelUp02Mult",
    [tes3.gmst.iLevelUp03Mult] = "iLevelUp03Mult",
    [tes3.gmst.iLevelUp04Mult] = "iLevelUp04Mult",
    [tes3.gmst.iLevelUp05Mult] = "iLevelUp05Mult",
    [tes3.gmst.iLevelUp06Mult] = "iLevelUp06Mult",
    [tes3.gmst.iLevelUp07Mult] = "iLevelUp07Mult",
    [tes3.gmst.iLevelUp08Mult] = "iLevelUp08Mult",
    [tes3.gmst.iLevelUp09Mult] = "iLevelUp09Mult",
    [tes3.gmst.iLevelUp10Mult] = "iLevelUp10Mult",
}

local function setGmst(gmstId, newValue)
    
    local gmst = tes3.findGMST(gmstId)
    local oldValue = gmst.value
    
    tes3.findGMST(gmstId).value = newValue
    if not config.getLoggingEnabled() then return end
    
    local displayName = gmst_DisplayName[gmstId]
    local valueFormat = nil
    
    if gmst.type == "i" then
        valueFormat = "%d"
    elseif gmst.type == "f" then
        valueFormat = "%.4f"
    elseif gmst.type == "s" then
        valueFormat = "%s"
    end
    
    local message = "GMST %s: " .. valueFormat .. " -> " .. valueFormat
    log(message, displayName, oldValue, newValue)
    
end

this.setGmsts = function(gmstTable)
    
    for gmstId, value in util.sortedPairs(gmstTable) do
        setGmst(gmstId, value)
    end
    
end

return this
