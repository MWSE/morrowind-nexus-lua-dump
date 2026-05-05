local vfs = require("openmw.vfs")

local U = {}

--- Merges handler tables from multiple Lua files, supporting multiple handler types.
--- @param folderPath string
--- @return table<string, table<string, function>>
U.mergeAllHandlers = function(folderPath)
    local merged = {}

    -- Temporary storage: all[handlerType][handlerName] = {func1, func2, ...}
    local all = {}

    for filePath in vfs.pathsWithPrefix(folderPath) do
        -- Remove .lua extension for require
        local modulePath = filePath:gsub("%.lua$", "")
        local ok, newHandlers = pcall(require, modulePath)

        if not ok then
            error(("Failed to require '%s': %s\n"):format(modulePath, newHandlers))
        end

        if type(newHandlers) == "table" then
            -- Iterate over handler types (e.g., eventHandlers, uiHandlers, etc.)
            for handlerType, handlers in pairs(newHandlers) do
                if type(handlers) == "table" then
                    all[handlerType] = all[handlerType] or {}

                    -- Iterate over individual handlers within the type
                    for name, func in pairs(handlers) do
                        if type(func) == "function" then
                            all[handlerType][name] = all[handlerType][name] or {}
                            table.insert(all[handlerType][name], func)
                        end
                    end
                end
            end
        end
    end

    -- Create dispatcher functions for each handler type and name
    for handlerType, handlers in pairs(all) do
        merged[handlerType] = {}

        for name, funcs in pairs(handlers) do
            merged[handlerType][name] = function(...)
                for _, f in ipairs(funcs) do
                    f(...)
                end
            end
        end
    end

    return merged
end

return U
