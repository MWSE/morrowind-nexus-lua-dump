local intcells = {}
local vfs = require('openmw.vfs')
local storage = require('openmw.storage')
local celldata = storage.globalSection("cellData")
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
    for fileName in vfs.pathsWithPrefix("scripts\\MoveObjects\\data\\cellcache") do
        local tbl = require(removeFileExtension(fileName))
        if tbl then
            for key, value in pairs(tbl) do
                intcells[key] = value
            end
        end
    end
    local cellTable = celldata:getCopy("cellTable")
    if cellTable then
        for index, value in pairs(cellTable) do
            if not intcells[index] then
                intcells[index] = value
            end
        end
    end
    return files
end
getCellCache()
return intcells
