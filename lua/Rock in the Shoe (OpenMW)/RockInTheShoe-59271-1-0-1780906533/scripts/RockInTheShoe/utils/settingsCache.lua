---@omw-context local | global
--
-- USAGE:
--   local async   = require("openmw.async")
--   local storage = require("openmw.storage")
--   local settingsCache = require("scripts.MyMod.utils.settingsCache")
--
--   local section = storage.globalSection("MyModSettings")
--   local settings = settingsCache.new(section, async)
--
--   -- Read cached value (no storage call):
--   local val = settings.someKey
--
--   -- Optional: react to changes
--   local settings = settingsCache.new(section, async, function(key)
--       if key == "someKey" then doSomething(settings.someKey) end
--   end)

local M = {}

--- Create a new settings cache for a StorageSection.
---@param section  openmw.storage.StorageSection  The storage section to mirror
---@param async    table          The openmw.async instance from the calling script
---@param onChange function|nil   Optional callback(key) fired after the cache updates.
--- key is nil when the whole section was reset.
---@return table table  A plain table whose keys mirror the section's current values
function M.new(section, async, onChange)
    -- Seed the cache with whatever is already stored
    local cache = section:asTable()

    section:subscribe(async:callback(function(_, key)
        if key then
            -- Single key changed
            cache[key] = section:get(key)
        else
            -- Full reset — rebuild from scratch
            local fresh = section:asTable()
            -- Remove keys that no longer exist
            for k in pairs(cache) do
                if fresh[k] == nil then
                    cache[k] = nil
                end
            end
            -- Insert/update everything from the new snapshot
            for k, v in pairs(fresh) do
                cache[k] = v
            end
        end

        if onChange then onChange(key) end
    end))

    return cache
end

return M
