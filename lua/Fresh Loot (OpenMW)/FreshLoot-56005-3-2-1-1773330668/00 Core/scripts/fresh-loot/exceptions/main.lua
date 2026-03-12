local vfs = require('openmw.vfs')

local log = require("scripts.fresh-loot.util.log")
local mT = require("scripts.fresh-loot.config.types")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local exceptionPath = "scripts/fresh-loot/exceptions/"
local exceptionLuaPath = "scripts.fresh-loot.exceptions"

local exceptions = mT.new.exceptionLists()

local getNextFile = vfs.pathsWithPrefix(exceptionPath)
local filenameIndex = string.len(exceptionPath) + 1
local file = getNextFile();
while (file) do
    if string.sub(file, filenameIndex, filenameIndex + 10) == "exceptions-" then
        local listsName = string.sub(file, filenameIndex + 11, -5)
        local lists = require(exceptionLuaPath .. ".exceptions-" .. listsName)
        for type, list in pairs(lists) do
            assert(exceptions[type], string.format("Invalid exception type \"%s\" for list \"%s\"", type, listsName))
            exceptions[type] = list
            log(string.format("Found %d exceptions in the list \"%s\" type \"%s\"", mHelpers.mapSize(list), type, listsName))
        end
    end
    file = getNextFile();
end

return exceptions