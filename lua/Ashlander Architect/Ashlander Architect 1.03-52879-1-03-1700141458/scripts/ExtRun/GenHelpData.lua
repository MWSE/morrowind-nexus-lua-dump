-- Define interface name and output folder path
local interfaceName = "consolecommands_data"
local outputFolderPath = "../MoveObjects"
local csvFilePath = "../../Console Commands.csv"

-- Read CSV file
local function readCSV(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil
    end

    local data = {}
    local lineNumber = 0
    local headers = {}

    for line in file:lines() do
        local rowData = {}
        local startIndex = 1

        while true do
            local commaIndex = string.find(line, ",", startIndex, true)
            if commaIndex then
                local value = string.sub(line, startIndex, commaIndex - 1)
                table.insert(rowData, value)
                startIndex = commaIndex + 1
            else
                local value = string.sub(line, startIndex)
                table.insert(rowData, value)
                break
            end
        end

        if lineNumber == 0 then
            headers = rowData
        else
            local entry = {}
            for i, header in ipairs(headers) do
                local fieldValue = rowData[i]
                if fieldValue ~= "" then
                    -- Check if the value is numeric and remove quotes if it is
                    if tonumber(fieldValue) then
                        entry[header] = tonumber(fieldValue)
                    else
                        entry[header] = fieldValue
                    end
                end
            end
            table.insert(data, entry)
        end

        lineNumber = lineNumber + 1
    end

    file:close()

    return data
end

-- Convert CSV to Lua table
local luaTable = readCSV(csvFilePath)

-- Generate the output Lua code
local outputFileName = interfaceName .. ".lua"
local outputFilePath = outputFolderPath .. "/" .. outputFileName
local outputFile = io.open(outputFilePath, "w")

function serializeTable(tbl)
    local str = "{\n"
    for _, v in ipairs(tbl) do
        str = str .. serializeEntry(v) .. ",\n"
    end
    str = str .. "}"
    return str
end

function serializeEntry(entry)
    local str = ""
    for k, v in pairs(entry) do
        str = str .. k .. "=" .. serializeValue(v) .. ","
    end
    return "{" .. str .. "}"
end

function serializeValue(val)
    if type(val) == "string" then
        return '"' .. val .. '"'
    elseif type(val) == "table" then
        return serializeTable(val)
    else
        return tostring(val)
    end
end

outputFile:write("return {\n")
outputFile:write("  interfaceName = \"" .. interfaceName .. "\",\n")
outputFile:write("  interface = {\n")
outputFile:write("    version = 1,\n")
outputFile:write("    objectTypes = " .. serializeTable(luaTable) .. "\n")
outputFile:write("  }\n")
outputFile:write("}")
outputFile:close()

