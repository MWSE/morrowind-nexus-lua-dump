------------------------------------------------------------
-- DAEDRA SELF-REMOVAL SCRIPT (CREATURE-ATTACHED)
------------------------------------------------------------

local selfObj = require("openmw.self")
local core    = require("openmw.core")
local types   = require("openmw.types")

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

-- ONLY these Daedra record IDs will remove themselves
-- (lowercase record IDs)
local DAEDRA_ID_WHITELIST = {
    ["scamp"] = true,
    ["clannfear"] = true,
    ["winged twilight"] = true,
    ["atronach_flame"] = true,
    ["daedroth"] = true,
    ["hunger"] = true,
    ["golden saint"] = true,
    ["atronach_storm"] = true,
    ["atronach_frost"] = true,
    ["ogrim"] = true,
    ["dremora_lord"] = true,
    ["dead_scamp"] = true,
    ["ogrim titan"] = true,
    ["dremora"] = true,
}

-- Exact cell names to block (lowercase)
local CELL_BLOCKLIST = {
    ["kora-dur"] = true,
    ["kora-dur'"] = true,
}

-- Keywords: if the cell name CONTAINS any of these, block it
-- (case-insensitive)
local CELL_BLOCK_KEYWORDS = {
    "oblivion",
}

------------------------------------------------------------
-- CELL CHECK (replace the old cell check with this)
------------------------------------------------------------

local function isCellBlocked()
    local cell = selfObj.cell
    if not cell or not cell.name then
        return false
    end

    local cellName = string.lower(cell.name)

    -- Exact match block
    if CELL_BLOCKLIST[cellName] then
        return true
    end

    -- Keyword match block
    for _, keyword in ipairs(CELL_BLOCK_KEYWORDS) do
        if string.find(cellName, keyword, 1, true) then
            return true
        end
    end

    return false
end
------------------------------------------------------------
-- LOGIC
------------------------------------------------------------

local function shouldRemoveSelf()
    --------------------------------------------------------
    -- Only CREATURE objects
    --------------------------------------------------------
    if selfObj.type ~= types.Creature then
        return false
    end

    --------------------------------------------------------
    -- Only DAEDRA
    --------------------------------------------------------
    local record = types.Creature.record(selfObj.recordId)
    if not record then
        return false
    end

    if record.type ~= types.Creature.TYPE.Daedra then
        return false
    end

    --------------------------------------------------------
    -- Whitelist ID check
    --------------------------------------------------------
    if not DAEDRA_ID_WHITELIST[selfObj.recordId] then
        return false
    end

    --------------------------------------------------------
    -- Cell blocklist check
    --------------------------------------------------------
     if isCellBlocked() then
        return false
    end

    return true
end

------------------------------------------------------------
-- INIT
------------------------------------------------------------

local function onInit()
    if shouldRemoveSelf() then
        core.sendGlobalEvent("DaedraRemoveSelf", {
            obj = selfObj
        })
    end
end

------------------------------------------------------------
-- RETURN
------------------------------------------------------------

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onInit,
    }
}
