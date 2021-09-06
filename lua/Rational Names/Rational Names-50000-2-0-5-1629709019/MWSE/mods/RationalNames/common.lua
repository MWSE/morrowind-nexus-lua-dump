local modInfo = require("RationalNames.modInfo")
local config = require("RationalNames.config")
local data = require("RationalNames.data")

local this = {}

this.logMsg = function(msg)
    if config.logging then
        mwse.log("%s %s", modInfo.modVersion, msg)
    end
end

local function printLogList(logTable, tableName)
    this.logMsg(string.format("%s:", tableName))

    for _, line in ipairs(logTable) do
        this.logMsg(line)
    end

    this.logMsg(string.format("end %s.", tableName))
end

-- We do it this way so the list will appear in the log in alphabetical order by ID (pairs results in random order).
local function populateLogList(dataTable)
    local logTable = {}

    for key, value in pairs(dataTable) do
        local line = string.format("%s: %s", key, value)
        table.insert(logTable, line)
    end

    table.sort(logTable)
    return logTable
end

this.logTable = function(dataTable, logText)
    local logList = populateLogList(dataTable)
    printLogList(logList, logText)
end

-- Returns the correct display name for a given object (if it differs from the object name), depending on whether the
-- mod is configured to display prefixes, and whether the object is a player-created enchanted item.
this.getDisplayName = function(id)
    if config.displayPrefixes then
        return data.enchDisplayNames[id] or data.displayNames[id]
    else
        return data.enchDisplayNamesNoPrefix[id] or data.displayNamesNoPrefix[id]
    end
end

-- Does a reverse ID lookup using an item's object name (needed for magic effect icons and dialogue notification
-- messages), and gets the correct display name from there. Can potentially result in problems if two different items
-- have identical object names but different display names, but that's unlikely to happen.
this.getDisplayNameFromObjectName = function(objectName)
    local id = data.enchObjectNameToID[objectName] or data.objectNameToID[objectName] or nil
    local displayName = this.getDisplayName(id)
    return id, displayName
end

this.checkValidObject = function(object)
    local name = object.name

    if ( not name )
    or name == ""
    or name == "FOR SPELL CASTING" then
        return false
    end

    return true
end

-- This function removes any previously-existing prefix from the name of player-created enchanted items, and from the
-- name field of the enchanting menu. (The real prefix will be added later.)
this.getInitialNameForEnch = function(oldName)
    local newName = oldName

    if string.find(newName, "%(") == 1 then
        local index = string.find(newName, "%) ")

        if index then
            local nameStart = index + 2
            local numName = #newName

            if numName >= nameStart then
                newName = string.sub(newName, nameStart, numName)
            end
        end
    end

    return newName
end

return this