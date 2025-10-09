local vfs = require('openmw.vfs')

local config = require("scripts.MoveObjects.config")
local I = require("openmw.interfaces")
local markup = require("openmw.markup")
local storage = require("openmw.storage")
local celldata = storage.globalSection("cellData")
local csvTable = celldata:getCopy("csvTable") or {}

-- CSV reader (unchanged)
local function parseCSV(lines)
    local headers = {}
    local isNumberColumn = {}

    local headerLine = table.remove(lines, 1)
    for header in headerLine:gmatch("[^,]+") do
        table.insert(headers, header)
    end

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

    local out = {}
    for _, line in ipairs(lines) do
        local row, values = {}, {}
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
        table.insert(out, row)
    end
    return out
end

-- -------- YAML helpers --------

-- Load YAML from a string (support multiple runtimes)
local function loadYamlString(yamlText)
    if markup then
        if markup.loadYamlString then
            return markup.loadYamlString(yamlText)
        elseif markup.decodeYaml then
            return markup.decodeYaml(yamlText)
        elseif markup.parseYaml then
            return markup.parseYaml(yamlText)
        end
    end
    local ok, lyaml = pcall(require, "lyaml")
    if ok and lyaml and lyaml.load then
        return lyaml.load(yamlText)
    end
    error("No YAML string parser available (need markup.loadYamlString/decodeYaml/parseYaml or lyaml).")
end

local function shallow_copy(tbl)
    local out = {}
    for k, v in pairs(tbl) do out[k] = v end
    return out
end

-- Loads YAML prefabs and injects Category/Subcategory based on YAML structure.
-- Category = the chosen top-level table in the YAML (ignoring 'format', 'notes')
-- Subcategory = the subtable key that contains each record, or "items" for Saved Items style
local function getYAMLTables(path, raw)
    local files = {}

    local function firstCategoryKey(doc)
        -- Gather top-level table keys except metadata
        local candidates = {}
        for k, v in pairs(doc) do
            if type(k) == "string" and type(v) == "table" and k ~= "format" and k ~= "notes" then
                candidates[#candidates + 1] = k
            end
        end
        if #candidates == 0 then return nil end
        if #candidates == 1 then return candidates[1] end

        -- Prefer a key that is directly an array or contains at least one array child
        for _, k in ipairs(candidates) do
            local t = doc[k]
            if type(t) == "table" then
                if t[1] ~= nil then return k end
                for _, sub in pairs(t) do
                    if type(sub) == "table" and sub[1] ~= nil then
                        return k
                    end
                end
            end
        end
        return candidates[1]
    end

    local function flattenWithCategory(doc)
        if type(doc) ~= "table" then return {} end
        -- Already a flat list at the root
        if doc[1] ~= nil then return doc end

        local catKey = firstCategoryKey(doc)
        if not catKey then return {} end
        local catTable = doc[catKey]
        if type(catTable) ~= "table" then return {} end

        -- Special case: { <Category>: { items: [ ... ] } }
        if type(catTable.items) == "table" and catTable.items[1] ~= nil then
            local out = {}
            for _, row in ipairs(catTable.items) do
                if type(row) == "table" then
                    local newRow = shallow_copy(row)
                    newRow.Category    = newRow.Category    or catKey
                    newRow.Subcategory = newRow.Subcategory or "items"
                    out[#out + 1] = newRow
                end
            end
            return out
        end

        -- General case: { <Category>: { SubA: [ ... ], SubB: [ ... ] } }
        local out = {}
        for subName, items in pairs(catTable) do
            if type(subName) == "string" and type(items) == "table" then
                for _, row in ipairs(items) do
                    if type(row) == "table" then
                        local newRow = shallow_copy(row)
                        newRow.Category    = newRow.Category    or catKey
                        newRow.Subcategory = newRow.Subcategory or subName
                        out[#out + 1] = newRow
                    end
                end
            end
        end
        return out
    end

    -- 1) Load real YAML files from disk
    for fileName in vfs.pathsWithPrefix("yaml/ashlander-architect/" .. path) do
        local ok, data = pcall(markup.loadYaml, fileName)
        if ok and data then
            files[#files + 1] = raw and data or flattenWithCategory(data)
        else
            print(("Failed to load YAML: %s (%s)"):format(tostring(fileName), tostring(data)))
        end
    end

    -- 2) Also load the in-memory YAML provided by AA_CustomObject (as if it were another file)
    if not raw and I.AA_CustomObject and I.AA_CustomObject.getYaml then
        local okText, yamlText = pcall(I.AA_CustomObject.getYaml)
        if okText and yamlText and yamlText ~= "" then
            local okParse, data = pcall(loadYamlString, yamlText)
            if okParse and data then
                files[#files + 1] = flattenWithCategory(data)
            else
                print(("Failed to parse in-memory YAML from AA_CustomObject (%s)"):format(tostring(data)))
            end
        end
    end

    -- 3) Special-case augmentation for path == "build"
    if not raw and path == "build" then
        local base = files[1] or {}
        local addedTable = {}
        for index, row in ipairs(base) do
            local newRow = shallow_copy(row)
            newRow.IntCount   = (newRow.IntCount or 0) + (9999 + index)
            newRow.Category   = newRow.Category   or "Uncategorized"
            newRow.Subcategory= newRow.Subcategory or "Unspecified"
            addedTable[#addedTable + 1] = newRow
        end
        if #addedTable > 0 then
            files[#files + 1] = addedTable
        else
            print("could not create build table")
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

return { getYAMLTables = getYAMLTables, getCSVLines = getCSVLines }