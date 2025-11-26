-- scripts/remove_roots.lua

local world = require('openmw.world')
local types = require('openmw.types')

-- Base object IDs to remove
local TARGETS = {
    flora_root_wg_01 = true,
    flora_root_wg_02 = true,
    flora_root_wg_03 = true,
    flora_root_wg_04 = true,
    flora_root_wg_05 = true,
    flora_root_wg_06 = true,
    flora_root_wg_07 = true,
    flora_root_wg_08 = true,
}

----------------------------------------------------
--  CELL BLACKLIST
----------------------------------------------------
-- 1) INTERIORS: use the cell *name* as shown in the CS / in game
local BLACKLIST_INTERIORS = {
    -- ["Balmora, Hlaalu Council Manor"] = true,
    -- ["Caldera, Ghorak Manor"] = true,
}

-- 2) EXTERIORS: use "gridX,gridY" as the key
--    You can get gridX/gridY from OpenMW-CS or the vanilla CS
local BLACKLIST_EXTERIORS = {
    -- ["-3,2"] = true,  -- example: cell at gridX=-3, gridY=2
}

local function isCellBlacklisted(cell)
    if cell.isInterior then
        return BLACKLIST_INTERIORS[cell.name] == true
    else
        local key = tostring(cell.gridX) .. "," .. tostring(cell.gridY)
        return BLACKLIST_EXTERIORS[key] == true
    end
end

----------------------------------------------------
--  ROOT REMOVAL
----------------------------------------------------
local function removeRootsInCell(cell)
    -- skip blacklisted cells entirely
    if isCellBlacklisted(cell) then
        return
    end

    local statics = cell:getAll(types.Static)
    for _, obj in ipairs(statics) do
        if TARGETS[obj.recordId] then
            obj.enabled = false
        end
    end
end

local function processWorld()
    for _, cell in ipairs(world.cells) do
        removeRootsInCell(cell)
    end
end

local function onPlayerAdded(player)
    processWorld()
end

return {
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
    }
}
