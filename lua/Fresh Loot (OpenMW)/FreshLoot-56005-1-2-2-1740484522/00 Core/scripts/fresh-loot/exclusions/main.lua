local vfs = require('openmw.vfs')

local log = require("scripts.fresh-loot.util.log")
local mTypes = require("scripts.fresh-loot.config.types")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local exclusionPath = "scripts/fresh-loot/exclusions/"
local exclusionLuaPath = "scripts.fresh-loot.exclusions"

local exclusions = mTypes.new.exclusionLists()

local getNextFile = vfs.pathsWithPrefix(exclusionPath)
local filenameIndex = string.len(exclusionPath) + 1
local file = getNextFile();
while (file) do
    if string.sub(file, filenameIndex, filenameIndex + 7) == "exclude-" then
        local listsName = string.sub(file, filenameIndex + 8, -5)
        local lists = require(exclusionLuaPath .. ".exclude-" .. listsName)
        local exclusionCount = 0
        for type, list in pairs(lists) do
            assert(type == "actorIds" or type == "containerIds", string.format("Invalid exclusion type \"%s\" for list \"%s\"", type, listsName))
            exclusions[type] = exclusions[type] or {}
            mHelpers.addAllToHashset(exclusions[type], list)
            exclusionCount = exclusionCount + #list
        end
        log(string.format("Found %d exclusions in the list \"%s\"", exclusionCount, listsName))
    end
    file = getNextFile();
end

return exclusions