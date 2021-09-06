local config = require("ConsistentKeys.config")
local data = require("ConsistentKeys.data")
local modInfo = require("ConsistentKeys.modInfo")
local common = require("ConsistentKeys.common")

local function logMsg(msg)
    if config.logging then
        mwse.log("%s %s", modInfo.modVersion, msg)
    end
end

local function capitalizeFirstChar(text)
    if string.find(text, "%l") == 1 then
        text = string.gsub(text, "%l", string.upper, 1)
    end

    return text
end

local function checkNameChangeEnabled(id)
    if not config.changeNames then
        logMsg(string.format("%s: Name changes disabled. Skipping name change.", id))
        return false
    end

    if config.blacklists.names[id] then
        logMsg(string.format("%s: On names blacklist. Skipping name change.", id))
        return false
    end

    return true
end

local function getNewName(id, oldName)
    if not checkNameChangeEnabled(id) then
        return oldName
    end

    local newName = data.keyNames[id]

    if newName then
        logMsg(string.format("%s: Name in data tables: %s.", id, newName))
    else
        logMsg(string.format("%s: No name specified in data tables.", id))
    end

    -- Dynamically renames keys if they don't have a new name specified in the data table.
    if not newName then
        local dynamicName = oldName

        if string.find(dynamicName:lower(), "key ") == 1
        and #dynamicName >= 5 then
            dynamicName = string.sub(dynamicName, 5, #dynamicName)
            dynamicName = capitalizeFirstChar(dynamicName)

            if string.find(dynamicName:lower(), "to ") == 1
            and #dynamicName >= 4 then
                dynamicName = string.sub(dynamicName, 4, #dynamicName)
                dynamicName = capitalizeFirstChar(dynamicName)
            end
        end

        if string.endswith(dynamicName:lower(), " key")
        and #dynamicName >= 5 then
            dynamicName = string.sub(dynamicName, 1, #dynamicName - 4)
        end

        if dynamicName ~= oldName then
            dynamicName = string.format("%s%s", "Key, ", dynamicName)
            newName = dynamicName
            logMsg(string.format("%s: Object is not on key names list. Changing name dynamically. New name: %s.", id, newName))
        end
    end

    if not newName then
        logMsg(string.format("%s: No new name. Skipping name change.", id))
        return oldName
    end

    return newName
end

local function processMiscItem(object)
    local id = object.id:lower()

    if not common.checkValidObject(object) then
        logMsg(string.format("%s: Object does not have a name. Skipping object.", id))
        return
    end

    if not common.checkKey(object) then
        logMsg(string.format("%s: Object is not a key. Skipping object.", id))
        return
    end

    if config.blacklists.overall[id] then
        logMsg(string.format("%s: On overall blacklist. Skipping object.", id))
        return
    end

    local oldName = object.name
    logMsg(string.format("%s: Old name: %s.", id, oldName))

    local newName = getNewName(id, oldName)

    -- Assuming no one adds names to the data table that are too long, this should only be possible with keys that are
    -- dynamically renamed.
    if #newName > 31 then
        if config.truncateLong then
            newName = string.sub(newName, 1, 31)
            logMsg(string.format("%s: New name is > 31 characters. Truncating name to: %s.", id, newName))
        else
            newName = oldName
            logMsg(string.format("%s: New name is > 31 characters. Skipping name change.", id))
        end
    end

    if newName ~= oldName then
        object.name = newName
        logMsg(string.format("%s: Name set to: %s.", id, object.name))
    else
        logMsg(string.format("%s: Final name (%s) is identical to original name. Not changing name.", id, newName))
    end

    if config.weightValue then
        object.value = 0
        object.weight = 0
        logMsg(string.format("%s: Per config option, setting value and weight to 0.", id))
    end

    if config.isKeyFlag then
        object.isKey = true
        logMsg(string.format("%s: Per config option, setting isKey flag to true.", id))
    end
end

local function onInitialized()
    if not config.enable then
        mwse.log("%s Mod disabled.", modInfo.modVersion)
        return
    end

    mwse.log(string.format("%s Initialized.", modInfo.modVersion))

    for object in tes3.iterateObjects(tes3.objectType.miscItem) do
        processMiscItem(object)
    end
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("ConsistentKeys.mcm")
end

event.register("modConfigReady", onModConfigReady)