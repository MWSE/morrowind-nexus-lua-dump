-- torch_radius_global.lua
-- GLOBAL script: creates enhanced light records and patches the player's inventory
-- Compatible with OpenMW 0.49+

local types = require('openmw.types')
local world = require('openmw.world')

local SCRIPT_VERSION = 1

local DEBUG = false  -- set to true to enable log messages

local TORCH_RADIUS = {
    ["torch"]                  = 1024,
    ["light_com_torch_01"]     = 1024,
    ["torch_256"]              = 1024,
    ["light_com_torch_01_128"] = 1024,
    ["torch_infinite_time"]    = 1024,
}

local newRecordIds  = {}
local initialized   = false
local pollTimer     = 0
local POLL_INTERVAL = 1.0  -- check inventory every second

-- Creates a new record for each torch with the target radius
local function createEnhancedTorches()
    for id, targetRadius in pairs(TORCH_RADIUS) do
        -- Skip if record already created (prevents duplicates on script reload)
        if not newRecordIds[id] then
            local ok, record = pcall(function()
                return types.Light.record(id)
            end)
            if ok and record then
                local draft = types.Light.createRecordDraft({
                    template = record,
                    radius   = targetRadius,
                })
                local newRecord = world.createRecord(draft)
                newRecordIds[id] = newRecord.id
                if DEBUG then print("[torch_radius] " .. id .. " : radius " .. record.radius .. " -> " .. targetRadius) end
            else
                if DEBUG then print("[torch_radius] WARNING: record not found for '" .. id .. "'") end
            end
        end
    end
end

-- Scan inventory and replace any vanilla torch found
local function patchInventory(player)
    local inv = types.Actor.inventory(player)

    -- Buffer items to replace before modifying inventory
    local toReplace = {}
    for _, item in ipairs(inv:getAll()) do
        local originalId = item.recordId
        if newRecordIds[originalId] then
            table.insert(toReplace, { item = item, id = originalId, count = item.count })
        end
    end

    -- Now safely replace buffered items
    for _, entry in ipairs(toReplace) do
        entry.item:remove(entry.count)
        world.createObject(newRecordIds[entry.id], entry.count):moveInto(inv)
        if DEBUG then print("[torch_radius] Inventory patched: " .. entry.id .. " x" .. entry.count) end
    end
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            if not initialized then
                createEnhancedTorches()
                initialized = true
                local player = world.players[1]
                if player then patchInventory(player) end
                return
            end

            pollTimer = pollTimer + dt
            if pollTimer >= POLL_INTERVAL then
                pollTimer = 0
                local player = world.players[1]
                if player then patchInventory(player) end
            end
        end,

        -- Save the patched record IDs into the save file
        onSave = function()
            return {
                version   = SCRIPT_VERSION,
                recordIds = newRecordIds,
            }
        end,

        -- Restore the patched record IDs from the save file
        onLoad = function(data)
            if not data or not data.version or data.version < SCRIPT_VERSION then
                if DEBUG then print("[torch_radius] No save data found, creating records from scratch.") end
                return
            end
            -- Validate that all restored records still exist
            for _, patchedId in pairs(data.recordIds) do
                local ok = pcall(function()
                    return types.Light.record(patchedId)
                end)
                if not ok then
                    -- Reset to clean state before recreating from scratch
                    newRecordIds = {}
                    initialized  = false
                    if DEBUG then print("[torch_radius] Invalid records detected, recreating from scratch.") end
                    return
                end
            end
            -- All records valid, restore them
            newRecordIds = data.recordIds
            initialized  = true
            if DEBUG then print("[torch_radius] Record IDs restored from save.") end
        end,
    }
}
