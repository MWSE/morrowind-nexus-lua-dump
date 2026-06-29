-- JsonMergeLoader.lua
-- Shared VFS-scan + deep-merge helper for JSON data files.
-- Reuses the read/scan pattern from CompanionDialogueLoader.lua.

local vfs = require("openmw.vfs")
local json = require("scripts.ProceduralChatter.lib.json")

local JsonMergeLoader = {}

local function readVfsFile(path)
    local ok, stream = pcall(vfs.open, path)
    if not ok or not stream then return nil end
    local chunks = {}
    local readOk, err = pcall(function()
        for line in stream:lines() do
            chunks[#chunks + 1] = line .. "\n"
        end
    end)
    pcall(function() stream:close() end)
    if not readOk then return nil end
    return table.concat(chunks)
end

--- Scan all *.json files under the given VFS prefix and call handler(data, path) for each.
--- Returns the number of JSON files processed.
function JsonMergeLoader.scan(prefix, handler)
    if not (vfs and vfs.pathsWithPrefix) then
        print("[JsonMergeLoader] WARNING: vfs.pathsWithPrefix unavailable")
        return 0
    end

    local count = 0
    for path in vfs.pathsWithPrefix(prefix) do
        if path:lower():match("%.json$") then
            local text = readVfsFile(path)
            if text and text ~= "" then
                local ok, data = pcall(json.decode, text)
                if ok and type(data) == "table" then
                    local hok, herr = pcall(handler, data, path)
                    if not hok then
                        print(string.format("[JsonMergeLoader] WARNING: handler failed for '%s': %s", path, tostring(herr)))
                    end
                else
                    print(string.format("[JsonMergeLoader] WARNING: failed to parse '%s': %s", path, tostring(data)))
                end
            else
                print(string.format("[JsonMergeLoader] WARNING: empty or unreadable file '%s'", path))
            end
            count = count + 1
        end
    end
    return count
end

--- Recursively merge tables. Nested tables are merged; non-table values are overwritten (last-writer-wins).
function JsonMergeLoader.deepMerge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            JsonMergeLoader.deepMerge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

--- Shallow key-level merge. Last-writer-wins on every key.
function JsonMergeLoader.mapMerge(target, source)
    for k, v in pairs(source) do
        target[k] = v
    end
    return target
end

--- Concatenate source array onto target array.
function JsonMergeLoader.arrayConcat(target, source)
    for _, v in ipairs(source) do
        table.insert(target, v)
    end
    return target
end

return JsonMergeLoader
