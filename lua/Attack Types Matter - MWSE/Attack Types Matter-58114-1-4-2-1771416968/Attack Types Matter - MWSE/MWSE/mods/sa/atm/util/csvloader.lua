local csvloader = {}
local log = mwse.Logger.new()

local lfs = require("lfs")

local function getScriptDirAbsolute()
    local source = debug.getinfo(1, "S").source
    if source:sub(1, 1) == "@" then
        source = source:sub(2)  -- Remove the "@" character.
    end
    local dir = source:match("(.+[/\\])")
    if not dir then
        return lfs.currentdir() .. "/"
    end
    if dir:sub(1, 1) == "." then
        local cwd = lfs.currentdir()
        if cwd:sub(-1) ~= "/" then
            cwd = cwd .. "/"
        end
        dir = cwd .. dir:sub(2)
    end
    dir = dir:gsub("[/\\]+", "/")
    return dir
end

--- Parses a CSV line into fields
---@param line string
---@return table
local function parseLine(line)
    local fields = {}
    for field in line:gmatch("([^,]+)") do
        table.insert(fields, field:match("^%s*(.-)%s*$")) -- trim whitespace
    end
    return fields
end


function csvloader.load(name)
    if type(name) ~= "string" then return end
    local csvFilename = getScriptDirAbsolute() .. "../" .. name
    log:info("Trying to load data in the main mod folder: " .. csvFilename)
    local data = {}
    local file = io.open(csvFilename, "r")
    if not file then
        log:info("ERROR reading CSV. File not found: " .. csvFilename)
        return data
    end

        for line in file:lines() do
        if line:match("%S") then
            local fields = parseLine(line)

            if #fields >= 2 then
                local id = fields[1]:lower()
                local values = {}
                for i=2, #fields do
                    local num = tonumber(fields[i])
                    table.insert(values, num or fields[i])
                end
               
                if id then
                    data[id] = values
                end
            end
        end
    end

    file:close()

    local count = 0

    log:debug("%-25s : %8s %8s %12s", "ID", "Slash", "Piercing", "Bludgeoning", "Material", "Bonus")
    for k, v in pairs(data) do
        count = count + 1
        log:debug("%-25s : %8.2f %8.2f %12.2f", k or "nil", v[1] or "nil", v[2] or 0, v[3] or 0, v[4] or 0, v[5] or 0)
    end
 

    if count > 0 then
        log:info("Loading succeded. %d entries parsed ", count)
    else
        log:info("Loading failed. %d entries parsed ", count)
    end
    return data
end

return csvloader