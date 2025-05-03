local core = require("openmw.core")
local vfs = require('openmw.vfs')

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local itemListsPath = "scripts/fresh-loot/item-lists/"
local itemListsLuaPath = "scripts.fresh-loot.item-lists"

local function hasOnePlugin(plugins)
    if not plugins then
        return true
    end
    for _, plugin in ipairs(plugins) do
        if core.contentFiles.has(plugin) then
            return true
        end
    end
    return false
end

local itemIds = {}
local listIds = {}

local getNextFile = vfs.pathsWithPrefix(itemListsPath)
local filenameIndex = string.len(itemListsPath) + 1
local file = getNextFile();
while (file) do
    if string.sub(file, filenameIndex, filenameIndex + 3) == "ids-" then
        local listName = string.sub(file, filenameIndex + 4, -5)
        local builtinList = mDef.itemIdsLists[listName]
        if hasOnePlugin(builtinList) then
            local ids = require(itemListsLuaPath .. ".ids-" .. listName)
            mHelpers.addAllToHashset(itemIds, ids)
            table.insert(listIds, listName)
            log(string.format("Found %d item ids in the list \"%s\"", #ids, listName))
        end
    end
    file = getNextFile();
end

table.sort(listIds)

return { itemIds = itemIds, listIds = listIds }