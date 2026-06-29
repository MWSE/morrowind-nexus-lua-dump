local types = require("openmw.types")
local util  = require("openmw.util")

local RegionResolver = {}

-- ============================================================================
-- Province bounding boxes (axis-aligned, world-space coordinates)
-- ============================================================================
local PROVINCE_BOXES = {
    cyrodiil = {
        xmin = -1138688.0, xmax = -876544.0,
        ymin = -483328.0,  ymax = -303104.0,
    },
    skyrim = {
        xmin = -983040.0,  xmax = -794624.0,
        ymin = 0.0,        ymax = 180224.0,
    },
    -- morrowind is the implicit fallback for everything else
}

-- ============================================================================
-- Aliases so authors can write short names instead of exact CS region strings
-- ============================================================================
local REGION_ALIASES = {
    -- Provinces
    ["morrowind"] = "Morrowind",
    ["cyrodiil"]  = "Cyrodiil",
    ["skyrim"]    = "Skyrim",

    -- Base-game regions (common shorthand -> exact record name)
    ["vvardenfell"]      = "Vvardenfell",   -- not a real cell.region, but kept for compatibility
    ["ascadian isles"]   = "Ascadian Isles Region",
    ["bitter coast"]     = "Bitter Coast Region",
    ["west gash"]        = "West Gash Region",
    ["grazelands"]       = "Grazelands Region",
    ["azura's coast"]    = "Azura's Coast Region",
    ["azuras coast"]     = "Azura's Coast Region",
    ["sheogorad"]        = "Sheogorad",
    ["mournhold"]        = "Mournhold Region",
    ["ashlands"]         = "Ashlands Region",
    ["molag amur"]       = "Molag Amur Region",
    ["red mountain"]     = "Red Mountain Region",
    ["ghostfence"]       = "Ghostfence Region",

    -- Solstheim
    ["solstheim"]                    = "Solstheim, Isinfier Plains Region",
    ["isinfier plains"]              = "Solstheim, Isinfier Plains Region",
    ["moesring mountains"]           = "Solstheim, Moesring Mountains Region",
    ["brodir grove"]                 = "Solstheim, Brodir Grove Region",
    ["felsaad coast"]                = "Solstheim, Felsaad Coast Region",
    ["hirstaang forest"]             = "Solstheim, Hirstaang Forest Region",

    -- Tamriel Rebuilt (common mainland regions)
    ["aanthirin"]        = "Aanthirin Region",
    ["alt orethan"]      = "Alt Orethan Region",
    ["armun ashlands"]   = "Armun Ashlands Region",
    ["boethiah's spine"] = "Boethiah's Spine Region",
    ["clambering moor"]  = "Clambering Moor Region",
    ["coronati basin"]   = "Coronati Basin Region",
    ["dagon urul"]       = "Dagon Urul Region",
    ["deshaan plains"]   = "Deshaan Plains Region",
    ["dejasyte"]         = "Dejasyte Region",
    ["grey meadows"]     = "Grey Meadows Region",
    ["julan-shar"]       = "Julan-Shar Region",
    ["kartur dale"]      = "Kartur Dale Region",
    ["lan orethan"]      = "Lan Orethan Region",
    ["lorchwuir heath"]  = "Lorchwuir Heath Region",
    ["mephalan vales"]   = "Mephalan Vales Region",
    ["molag ruhn"]       = "Molag Ruhn Region",
    ["mudflats"]         = "Mudflats Region",
    ["nedothril"]        = "Nedothril Region",
}

-- ============================================================================
-- City-to-Region early-out table
-- ============================================================================
-- When an actor is in an interior, we can often infer region from the cell
-- name prefix (e.g. "Seyda Neen, Arrille's Tradehouse" -> "Seyda Neen").
-- This avoids the heavier door-scan fallback for the most common settlements.
--
-- Value = { region = string|nil, province = string|nil }
-- If region is omitted, door-scan will still be attempted for specific-region
-- checks, but province is already known.
-- ============================================================================
local CITY_TO_REGION = {
    -- Bitter Coast Region
    ["seyda neen"]      = { region = "Bitter Coast Region",     province = "morrowind" },
    ["balmora"]         = { region = "Bitter Coast Region",     province = "morrowind" },
    ["hla oad"]         = { region = "Bitter Coast Region",     province = "morrowind" },
    ["gnaar mok"]       = { region = "Bitter Coast Region",     province = "morrowind" },

    -- Ascadian Isles Region
    ["pelagiad"]        = { region = "Ascadian Isles Region",   province = "morrowind" },
    ["suran"]           = { region = "Ascadian Isles Region",   province = "morrowind" },
    ["ebonheart"]       = { region = "Ascadian Isles Region",   province = "morrowind" },
    ["vivec"]           = { region = "Ascadian Isles Region",   province = "morrowind" },

    -- West Gash Region
    ["gnisis"]          = { region = "West Gash Region",        province = "morrowind" },
    ["khuul"]           = { region = "West Gash Region",        province = "morrowind" },
    ["caldera"]         = { region = "West Gash Region",        province = "morrowind" },
    ["ald velothi"]     = { region = "West Gash Region",        province = "morrowind" },

    -- Ashlands Region
    ["ald-ruhn"]        = { region = "Ashlands Region",          province = "morrowind" },
    ["maar gan"]        = { region = "Ashlands Region",          province = "morrowind" },
    ["urshilaku camp"]  = { region = "Ashlands Region",          province = "morrowind" },

    -- Azura's Coast Region
    ["tel mora"]        = { region = "Azura's Coast Region",     province = "morrowind" },
    ["tel aruhn"]       = { region = "Azura's Coast Region",     province = "morrowind" },
    ["tel branora"]     = { region = "Azura's Coast Region",     province = "morrowind" },
    ["sadrith mora"]    = { region = "Azura's Coast Region",     province = "morrowind" },
    ["ahemmusa camp"]   = { region = "Azura's Coast Region",     province = "morrowind" },
    ["wolverine hall"]  = { region = "Azura's Coast Region",     province = "morrowind" },

    -- Grazelands Region
    ["vos"]             = { region = "Grazelands Region",        province = "morrowind" },
    ["tel vos"]         = { region = "Grazelands Region",        province = "morrowind" },
    ["zainab camp"]     = { region = "Grazelands Region",        province = "morrowind" },

    -- Molag Amur Region
    ["molag mar"]       = { region = "Molag Amur Region",        province = "morrowind" },
    ["erabenimsun camp"]= { region = "Molag Amur Region",        province = "morrowind" },

    -- Sheogorad
    ["dagon fel"]       = { region = "Sheogorad",                province = "morrowind" },

    -- Red Mountain / Ghostfence
    ["ghostgate"]       = { region = "Ghostfence Region",        province = "morrowind" },

    -- Mournhold (Tribunal)
    ["mournhold"]       = { region = "Mournhold Region",          province = "morrowind" },

    -- Solstheim (Bloodmoon)
    ["skaal village"]   = { region = "Solstheim, Felsaad Coast Region", province = "morrowind" },
    ["raven rock"]      = { region = "Solstheim, Hirstaang Forest Region", province = "morrowind" },
    ["fort frostmoth"]  = { region = "Solstheim, Isinfier Plains Region", province = "morrowind" },

    -- Province Cyrodiil (PC) — exact regions unknown, but province is certain
    ["anvil"]           = { province = "cyrodiil" },
    ["brina cross"]     = { province = "cyrodiil" },

    -- Skyrim (SHOTN / Skyrim mods)
    ["dragonstar east"] = { province = "skyrim" },
    ["dragonstar west"] = { province = "skyrim" },
    ["karthwasten"]     = { province = "skyrim" },
    ["karthgad"]        = { province = "skyrim" },
}

-- ============================================================================
-- Internal helpers
-- ============================================================================

--- Extract the settlement prefix from an interior cell name.
-- "Seyda Neen, Arrille's Tradehouse" -> "seyda neen"
local function getCityPrefix(cellName)
    if not cellName or cellName == "" then return nil end
    local prefix = cellName:lower():match("^(.-),%s")
    return prefix or cellName:lower()
end

local function getProvinceFromPosition(pos)
    if not pos then return "morrowind" end
    local x, y = pos.x, pos.y
    if x >= PROVINCE_BOXES.cyrodiil.xmin and x <= PROVINCE_BOXES.cyrodiil.xmax
       and y >= PROVINCE_BOXES.cyrodiil.ymin and y <= PROVINCE_BOXES.cyrodiil.ymax then
        return "cyrodiil"
    end
    if x >= PROVINCE_BOXES.skyrim.xmin and x <= PROVINCE_BOXES.skyrim.xmax
       and y >= PROVINCE_BOXES.skyrim.ymin and y <= PROVINCE_BOXES.skyrim.ymax then
        return "skyrim"
    end
    return "morrowind"
end

--- Scan doors in the given cell and return the first one that leads to an
-- exterior (or quasi-exterior) cell.
local function findExteriorCell(cell)
    if not cell then return nil end

    -- Try the fast path first: cell:getAll(types.Door)
    local ok, doors = pcall(function() return cell:getAll(types.Door) end)
    if not ok or not doors then
        -- Fallback: iterate all objects and filter by type
        ok, doors = pcall(function()
            local all = cell:getAll()
            local result = {}
            for _, obj in ipairs(all) do
                local isDoor = false
                pcall(function() isDoor = types.Door.objectIsInstance(obj) end)
                if isDoor then table.insert(result, obj) end
            end
            return result
        end)
    end
    if not ok or not doors then return nil end

    for _, door in ipairs(doors) do
        local destOk, destCell = pcall(types.Door.destCell, door)
        if destOk and destCell then
            local extOk, isExt = pcall(function() return destCell.isExterior end)
            if extOk and isExt then
                return destCell
            end
            local tagOk, hasTag = pcall(function() return destCell:hasTag("QuasiExterior") end)
            if tagOk and hasTag then
                return destCell
            end
        end
    end
    return nil
end

--- Approximate world-space position from an exterior cell's grid coordinates.
local function getPositionFromGrid(cell)
    local okX, gx = pcall(function() return cell.gridX end)
    local okY, gy = pcall(function() return cell.gridY end)
    if okX and okY and gx ~= nil and gy ~= nil then
        return util.vector3(gx * 8192 + 4096, gy * 8192 + 4096, 0)
    end
    return nil
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Resolve an actor's geographic region and province.
-- For exteriors: reads cell.region and actor.position directly.
-- For interiors: first tries a cell-name prefix lookup (e.g. "Balmora, Lucky
-- Lockup" -> "Balmora" -> Bitter Coast Region).  If that misses, scans doors
-- to find the exterior cell, then reads that exterior's region and grid.
--
-- @param actor  OpenMW actor object (must have .cell and optionally .position)
-- @return specificRegion (string|nil), province (string)
function RegionResolver.getActorRegionInfo(actor)
    if not actor then return nil, "morrowind" end

    local cell = actor.cell
    if not cell then return nil, "morrowind" end

    local isExterior = false
    local ok, extCheck = pcall(function() return cell.isExterior end)
    if ok then isExterior = extCheck end

    local specificRegion = nil
    local province = "morrowind"

    if isExterior then
        -- Direct region string from the engine
        local regOk, regionName = pcall(function() return cell.region end)
        if regOk and regionName and regionName ~= "" then
            specificRegion = regionName
        end

        -- Province from actor's world position
        local posOk, pos = pcall(function() return actor.position end)
        province = getProvinceFromPosition(pos)
    else
        -- Interior: early-out via cell-name city prefix if possible
        local cellName = ""
        pcall(function() cellName = cell.name or "" end)
        local cityPrefix = getCityPrefix(cellName)
        if cityPrefix then
            local cityInfo = CITY_TO_REGION[cityPrefix]
            if cityInfo then
                specificRegion = cityInfo.region
                if cityInfo.province then
                    province = cityInfo.province
                else
                    -- We have a region name but no explicit province; derive
                    -- from coordinates as a last resort (interior pos is usually
                    -- wrong, but morrowind is the safe default).
                    local posOk, pos = pcall(function() return actor.position end)
                    province = getProvinceFromPosition(pos)
                end
                -- If we got a specific region from the city map, we can stop.
                -- If only province was known, we leave specificRegion nil so
                -- that region-specific checks fall back to the fuzzy logic
                -- in RegionResolver.matches (which may reject or accept based
                -- on province fallback for Morrowind).
                if specificRegion then
                    return specificRegion, province
                end
            end
        end

        -- City map missed — try door scan
        local extCell = findExteriorCell(cell)
        if extCell then
            local regOk, regionName = pcall(function() return extCell.region end)
            if regOk and regionName and regionName ~= "" then
                specificRegion = regionName
            end

            -- Province from the door's exterior grid (accurate)
            local gridPos = getPositionFromGrid(extCell)
            if gridPos then
                province = getProvinceFromPosition(gridPos)
            else
                local posOk, pos = pcall(function() return actor.position end)
                province = getProvinceFromPosition(pos)
            end
        else
            -- No door found — fall back to actor position (likely wrong for
            -- province, but better than nothing)
            local posOk, pos = pcall(function() return actor.position end)
            province = getProvinceFromPosition(pos)
            specificRegion = nil
        end
    end

    return specificRegion, province
end

--- Normalize a user-provided region name to its canonical form.
-- Handles aliases and lower-case shortcuts.
function RegionResolver.normalizeRegionName(name)
    if not name then return nil end
    local lower = name:lower()
    if REGION_ALIASES[lower] then
        return REGION_ALIASES[lower]
    end
    return name
end

--- Test whether an actor satisfies a region requirement.
-- Accepts both provinces ("Morrowind", "Cyrodiil", "Skyrim") and specific
-- region names ("Ascadian Isles Region", "Bitter Coast Region", etc.).
--
-- @param actor           OpenMW actor object
-- @param requiredRegion  String from snippet conditions (e.g. reqs.region)
-- @return boolean
function RegionResolver.matches(actor, requiredRegion)
    if not requiredRegion or requiredRegion == "" then return true end

    local normReq = RegionResolver.normalizeRegionName(requiredRegion)
    if not normReq then return true end

    local specificRegion, province = RegionResolver.getActorRegionInfo(actor)
    local reqLower = normReq:lower()

    -- Broad province checks
    if reqLower == "morrowind" or reqLower == "cyrodiil" or reqLower == "skyrim" then
        return province and (province:lower() == reqLower)
    end

    -- Specific region checks (fuzzy: either string may contain the other)
    if specificRegion then
        local specLower = specificRegion:lower()
        if specLower == reqLower then return true end
        if specLower:find(reqLower, 1, true) then return true end
        if reqLower:find(specLower, 1, true) then return true end
    end

    -- If we have no specific region (interior, no doors) and the request is
    -- Morrowind, fall back to province.  Most interiors are in Morrowind,
    -- so this prevents silent rejection when door-scanning fails.
    if not specificRegion and reqLower == "morrowind" then
        return province and province:lower() == "morrowind"
    end

    return false
end

return RegionResolver
