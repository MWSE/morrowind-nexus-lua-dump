local vfs = require('openmw.vfs')
local storage = require("openmw.storage")

local ret = {}

local structureTable = storage.globalSection("cellData")
local function removeFileExtension(filename)
    local lastDotPos = filename:match(".*()%.")

    if lastDotPos then
        return filename:sub(1, lastDotPos - 1)
    else
        return filename
    end
end
local function getCellCache()
    local files = {}
    for fileName in vfs.pathsWithPrefix("scripts\\MoveObjects\\data\\structuregen") do
        local tbl = require(removeFileExtension(fileName))
        for key, value in pairs(tbl) do
            ret[key] = value
        end
    end
    local cellTable = structureTable:getCopy("structureTable")
    if cellTable then
        for index, subtable in pairs(cellTable) do
                if not files[index] then
                    ret[index] = subtable
                end
        end
    end
    return files
end
getCellCache()

return ret
