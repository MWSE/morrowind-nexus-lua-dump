local vfs = require('openmw.vfs')

local config = require("scripts.MoveObjects.config")
--local csv= require("scripts.MoveObjects.Utility.csv_reader")
local function parseCSV(lines)
    local headers = {}
    local isNumberColumn = {}

    -- Parse headers from the first line
    local headerLine = table.remove(lines, 1)
    for header in headerLine:gmatch("[^,]+") do
        table.insert(headers, header)
    end

    -- Determine which columns are numbers based on the second line
    local secondLine = lines[1]
    if secondLine then
        local values = {}
        for value in secondLine:gmatch("[^,]+") do
            table.insert(values, tonumber(value) or value)
        end

        for i, value in ipairs(values) do
            isNumberColumn[i] = type(value) == "number"
        end
    end
    local csvTable = {}

    -- Parse data rows using headers as keys and convert numerical values to numbers
    for _, line in ipairs(lines) do
        local row = {}
        local values = {}
        for value in line:gmatch("[^,]+") do
            table.insert(values, value)
        end
        for i, header in ipairs(headers) do
            local fieldValue = values[i] or ""
            if isNumberColumn[i] then
                row[header] = tonumber(fieldValue) or fieldValue
            else
                row[header] = fieldValue
            end
        end
        table.insert(csvTable, row)
    end

    return csvTable
end

local storage = require("openmw.storage")
local celldata = storage.globalSection("cellData")
local csvTable = celldata:getCopy("csvTable") or {}

local function getCSVTables(path)
    local files = {}
    for fileName in vfs.pathsWithPrefix("csv\\ashlander-architect\\" .. path) do
        local lines = {}
        for line in vfs.lines(fileName) do
            table.insert(lines, line)
        end
        table.insert(files, parseCSV(lines))
    end
    if path == "build" then
        local lines = {}
        table.insert(lines,
            "Static_ID,Texture_Name,Name,Category,Subcategory,Z_Offset,Grid_Size,XY_Offset,Object_Type,DefaultDist,IntCount,,,ItemNeeded2Count")
        for key, value in pairs(csvTable) do
            table.insert(lines, value)
        end
        local addedTable = parseCSV(lines)
        if addedTable then
            for index, value in ipairs(addedTable) do
                addedTable[index].IntCount = 9999 + index
            end
            table.insert(files, addedTable)
        else
            print("could not create table")
        end
        
    end
    return files
end
local function getCSVLines(path)
    local files = {}
    for fileName in vfs.pathsWithPrefix("csv\\ashlander-architect\\" .. path) do
        local lines = {}
        for line in vfs.lines(fileName) do
            table.insert(lines, line)
        end
        table.insert(files, lines)
    end
    return files
end
return { getCSVTables = getCSVTables, getCSVLines = getCSVLines }
