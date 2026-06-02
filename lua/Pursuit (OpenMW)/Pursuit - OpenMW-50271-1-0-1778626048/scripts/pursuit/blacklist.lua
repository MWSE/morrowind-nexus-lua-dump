local markup = require("openmw.markup")
local types = require("openmw.types")
local vfs = require("openmw.vfs")

-- recordIds added through I.Pursuit.addBlacklist goes into this table
-- entries will be lost on new game session/save reload
local __data__ = { --[[runtime added blacklist]] }

-- recordIds from yaml goes into this table
-- removable at runtime via remove(), but changes do not persist across sessions
local __xdata__ = { --[[yaml added blacklist]] }

local blacklist = {}

local function recordExists(recordId)
    return types.NPC.records[recordId] or types.Creature.records[recordId]
end

local function handleLazyIndexing(t, key)
    if type(key) ~= "string" then error("Key is not a string", 2) end
    local value = __xdata__[key:lower()]
    return value or rawget(t, key:lower())
end

local function mergedIterator(tData, txData)
    local list = tData
    local seen = {}
    local key = nil
    local last_Key = nil

    return function()
        if list == tData then
            key = next(tData, last_Key)
            if key ~= nil then
                seen[key] = true
                last_Key = key
                return key, "added"
            else
                list = txData
                last_Key = nil
            end
        end

        while list == txData do
            key = next(txData, last_Key)
            last_Key = key
            if key == nil then
                return nil
            end
            if not seen[key] then
                seen[key] = true
                return key, "yaml"
            end
        end
    end
end

setmetatable(__data__, {
    __index = handleLazyIndexing,
    __pairs = function(t)
        return mergedIterator(t, __xdata__)
    end
})

function blacklist:get()
    return __data__
end

function blacklist:add(recordId)
    if type(recordId) ~= "string" then error("`blacklist:add` Argument must be a string", 2) end
    if not recordExists(recordId) then error("`blacklist:add` Unknown actor recordId: " .. recordId, 2) end
    local added = __data__[recordId]
    if not added then __data__[recordId:lower()] = true end
    return not added -- returns true for new entry, false otherwise
end

function blacklist:remove(recordId)
    if type(recordId) ~= "string" then error("`blacklist:remove` Argument must be a string", 2) end
    if not recordExists(recordId) then error("`blacklist:remove` Unknown actor recordId: " .. recordId, 2) end
    local added = __data__[recordId]
    __data__[recordId:lower()] = nil
    __xdata__[recordId:lower()] = nil
    return added or false -- returns true if recordId exists before removal, false otherwise
end

function blacklist:updateBlacklist()
    for file in vfs.pathsWithPrefix("scripts\\pursuit\\blacklist\\") do
        if file:match("%.ya?ml$") then
            local list = markup.loadYaml(file)
            for _, recordId in pairs(list) do
                __xdata__[recordId:lower()] = true
            end
        end
    end
end

return blacklist
