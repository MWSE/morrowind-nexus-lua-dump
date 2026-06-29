-- profiles/scope.lua
---@omw-context none
--
-- Place/cell scoping for TSV profile rows. Folder names are for humans; these
-- helpers make scope enforceable at runtime through PlaceKey/CellPrefix/etc.

local module = {}

local PLACE_CELL_PREFIXES = {
    ald_ruhn = { "Ald-ruhn" },
    anvil = { "Anvil" },
    balmora = { "Balmora" },
    caldera = { "Caldera" },
    dagon_fel = { "Dagon Fel" },
    dragonstar = { "Dragonstar" },
    ebon_tower = { "Ebon Tower" },
    firewatch = { "Firewatch" },
    five_fathoms = { "Five Fathoms" },
    fort_frostmoth = { "Fort Frostmoth" },
    gnisis = { "Gnisis" },
    gorne = { "Gorne" },
    karthwasten = { "Karthwasten" },
    nivalis = { "Nivalis" },
    old_ebonheart = { "Old Ebonheart" },
    ossuary = { "Ossuary" },
    pelagiad = { "Pelagiad" },
    port_telvannis = { "Port Telvannis" },
    saint_laecas = { "Saint Laeca" },
    sadrith_mora = { "Sadrith Mora" },
    seyda_neen = { "Seyda Neen" },
    vivec = { "Vivec" },
}

local function trim(value)
    if value == nil then return "" end
    return tostring(value):match("^%s*(.-)%s*$") or ""
end

local function lower(value)
    local s = trim(value)
    if s == "" then return "" end
    return string.lower(s)
end

local function split(raw)
    local out = {}
    raw = tostring(raw or "")
    raw = raw:gsub("[|,]", ";")
    for part in raw:gmatch("([^;]+)") do
        local value = trim(part)
        if value ~= "" then out[#out + 1] = value end
    end
    return out
end

local function normalizePlaceKey(raw)
    local value = lower(raw)
    if value == "" then return "" end
    value = value:gsub("[^%w]+", "_")
    value = value:gsub("^_+", ""):gsub("_+$", "")
    return value
end
module.normalizePlaceKey = normalizePlaceKey

local function titleFromPlaceKey(placeKey)
    local parts = {}
    for part in tostring(placeKey or ""):gmatch("[^_]+") do
        if part ~= "" then
            parts[#parts + 1] = part:gsub("^%l", string.upper)
        end
    end
    return table.concat(parts, " ")
end

local function sourcePlaceKey(sourceName)
    local source = tostring(sourceName or ""):gsub("\\", "/")
    local key = source:match("[Ss][Dd][Pp]_[Ff][Uu][Rr][Nn][Ii][Tt][Uu][Rr][Ee][Pp][Rr][Oo][Ff][Ii][Ll][Ee][Ss]/[Pp][Ll][Aa][Cc][Ee][Ss]/([^/]+)/")
    if key and key ~= "" then return normalizePlaceKey(key) end
    return ""
end

local function addAll(target, values)
    for _, value in ipairs(values or {}) do
        local normalized = lower(value)
        if normalized ~= "" then target[#target + 1] = normalized end
    end
end

function module.placeLabel(placeKey)
    local normalized = normalizePlaceKey(placeKey)
    if normalized == "" then return "" end
    return titleFromPlaceKey(normalized)
end

function module.cellPrefixesForPlaceKey(placeKey)
    local normalized = normalizePlaceKey(placeKey)
    if normalized == "" then return {} end
    local out = {}
    local prefixes = PLACE_CELL_PREFIXES[normalized]
    if prefixes then
        addAll(out, prefixes)
    else
        addAll(out, { titleFromPlaceKey(normalized) })
    end
    return out
end

function module.cellPrefixesForPlaceKeys(placeKeys)
    local out = {}
    for placeKey, trusted in pairs(placeKeys or {}) do
        if trusted == true then
            local prefixes = module.cellPrefixesForPlaceKey(placeKey)
            for _, prefix in ipairs(prefixes) do
                out[#out + 1] = prefix
            end
        end
    end
    return out
end

function module.scopeFromRow(row, sourceName)
    row = row or {}
    local exactCells = {}
    local cellPrefixes = {}
    local regions = {}

    addAll(exactCells, split(row.cell or row.cellname or row.exactcell))
    addAll(cellPrefixes, split(row.cellprefix or row.cell_prefix))
    addAll(regions, split(row.region or row.regionname))

    local placeKey = normalizePlaceKey(row.placekey or row.place or row.place_key)
    if placeKey == "" then placeKey = sourcePlaceKey(sourceName) end
    if placeKey ~= "" and #cellPrefixes == 0 then
        local prefixes = PLACE_CELL_PREFIXES[placeKey]
        if prefixes then
            addAll(cellPrefixes, prefixes)
        else
            addAll(cellPrefixes, { titleFromPlaceKey(placeKey) })
        end
    end

    if #exactCells == 0 and #cellPrefixes == 0 and #regions == 0 and placeKey == "" then
        return nil
    end

    return {
        cells = exactCells,
        cellPrefixes = cellPrefixes,
        regions = regions,
        placeKey = placeKey ~= "" and placeKey or nil,
    }
end

local function objectCell(obj)
    local cell = nil
    if obj then
        local ok, value = pcall(function() return obj.cell end)
        if ok then cell = value end
    end
    return cell
end

local function objectCellName(obj)
    local cell = objectCell(obj)
    if not cell then return "" end
    local ok, value = pcall(function() return cell.name end)
    if ok and value ~= nil and tostring(value) ~= "" then return tostring(value) end
    ok, value = pcall(function() return cell.id end)
    if ok and value ~= nil then return tostring(value) end
    return ""
end

local function objectRegionName(obj)
    local cell = objectCell(obj)
    if not cell then return "" end
    local ok, value = pcall(function() return cell.region end)
    if ok and value ~= nil and tostring(value) ~= "" then return tostring(value) end
    ok, value = pcall(function() return cell.regionName end)
    if ok and value ~= nil then return tostring(value) end
    return ""
end

local function anyEquals(value, candidates)
    value = lower(value)
    if value == "" then return false end
    for _, candidate in ipairs(candidates or {}) do
        if value == lower(candidate) then return true end
    end
    return false
end

local function anyPrefix(value, prefixes)
    value = lower(value)
    if value == "" then return false end
    for _, prefix in ipairs(prefixes or {}) do
        prefix = lower(prefix)
        if prefix ~= "" and value:sub(1, #prefix) == prefix then return true end
    end
    return false
end

function module.matchesObject(scope, obj)
    if not scope then return true end
    local cellName = objectCellName(obj)
    if scope.cells and #scope.cells > 0 and not anyEquals(cellName, scope.cells) then
        return false
    end
    if scope.cellPrefixes and #scope.cellPrefixes > 0 and not anyPrefix(cellName, scope.cellPrefixes) then
        return false
    end
    if scope.regions and #scope.regions > 0 and not anyEquals(objectRegionName(obj), scope.regions) then
        return false
    end
    return true
end

function module.specificityScore(scope)
    if not scope then return 0 end
    local score = 0
    if scope.regions and #scope.regions > 0 then score = score + 1000 end
    if scope.placeKey then score = score + 2000 end
    if scope.cellPrefixes and #scope.cellPrefixes > 0 then score = score + 3000 end
    if scope.cells and #scope.cells > 0 then score = score + 4000 end
    return score
end

function module.label(scope)
    if not scope then return "" end
    local parts = {}
    if scope.placeKey then parts[#parts + 1] = "place=" .. tostring(scope.placeKey) end
    if scope.cells and #scope.cells > 0 then parts[#parts + 1] = "cell=" .. table.concat(scope.cells, ";") end
    if scope.cellPrefixes and #scope.cellPrefixes > 0 then parts[#parts + 1] = "cellPrefix=" .. table.concat(scope.cellPrefixes, ";") end
    if scope.regions and #scope.regions > 0 then parts[#parts + 1] = "region=" .. table.concat(scope.regions, ";") end
    return table.concat(parts, " ")
end

return module
