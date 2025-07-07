local lfs = require("lfs")

---@param moduleRoot string  -- e.g., "Syanide.HammerAndProngs.Armor"
---@param opts? { recursive: boolean }  -- optional settings
local function includeFolder(moduleRoot, opts)
    opts = opts or {}
    local folderPath = "Data Files\\MWSE\\mods\\" .. moduleRoot:gsub("%.", "\\")

    local function scan(dirModulePath, dirFSPath)
        for file in lfs.dir(dirFSPath) do
            if file ~= "." and file ~= ".." then
                local fullFSPath = dirFSPath .. "\\" .. file
                local fullModulePath = dirModulePath .. "." .. file:gsub("%.lua$", "")
                local attr = lfs.attributes(fullFSPath)
                if attr.mode == "file" and file:sub(-4) == ".lua" then
                    local ok, err = pcall(include, fullModulePath)
                    if not ok then
                        print("[includeFolder] Error including " .. fullModulePath .. ": " .. err)
                    end
                elseif attr.mode == "directory" and opts.recursive then
                    scan(fullModulePath, fullFSPath)
                end
            end
        end
    end

    scan(moduleRoot, folderPath)
end

return includeFolder