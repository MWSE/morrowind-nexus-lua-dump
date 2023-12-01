local vfs = require('openmw.vfs')
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


local function getCSVTables(path)
    local files = {}
    for fileName in vfs.pathsWithPrefix("csv\\ashlander-architect\\" .. path) do
        local lines = {}
        for line in vfs.lines(fileName) do
            table.insert(lines,line)
        end
        table.insert(files,parseCSV(lines))
    end
    return files
end
local function getCSVLines(path)
    local files = {}
    for fileName in vfs.pathsWithPrefix("csv\\ashlander-architect\\" .. path) do
        local lines = {}
        for line in vfs.lines(fileName) do
            table.insert(lines,line)
        end
        table.insert(files,lines)
    end
    return files
end
return{getCSVTables =getCSVTables,getCSVLines = getCSVLines}