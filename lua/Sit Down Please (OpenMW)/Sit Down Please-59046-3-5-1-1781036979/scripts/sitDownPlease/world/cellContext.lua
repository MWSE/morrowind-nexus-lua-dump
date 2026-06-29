-- world/cellContext.lua
---@omw-context none
-- Runtime-only cell identity and tiny cache helpers. Nothing here is persisted.

local module = {}

function module.cellName(cell)
    if not cell then return "<no-cell>" end
    return tostring(cell.name or cell.id or cell)
end

function module.actorKey(actor)
    if not actor then return "<actor>" end
    return tostring(actor.id or actor.recordId or actor)
end

function module.cellInteractionCacheKey(cell, interactionType)
    return tostring(module.cellName(cell)) .. "::" .. tostring(interactionType or "<type>")
end

function module.newRuntimeCache()
    return {
        cell = nil,
        cellName = nil,
        buckets = {},
    }
end

function module.resetRuntimeCache(cache, cell)
    cache = cache or module.newRuntimeCache()
    cache.cell = cell
    cache.cellName = module.cellName(cell)
    cache.buckets = {}
    return cache
end

function module.getBucket(cache, key)
    if not cache or not key then return nil end
    return cache.buckets[key]
end

function module.setBucket(cache, key, value)
    if not cache or not key then return end
    cache.buckets[key] = value
end

local publicCellTerms = {
    "tavern", "inn", "cornerclub", "tradehouse", "club", "guild", "temple",
    "shrine", "shop", "store", "armorer", "smith", "clothier", "alchemist",
    "apothecary", "pawnbroker", "mage", "fighters", "thieves", "council",
    "palace", "barracks", "guard", "warehouse", "office", "outpost", "fort",
    "canton", "plaza", "hall", "manor district",
}

local privateHomeTerms = {
    "house", "home", "residence", "shack", "hut", "yurt", "manor",
    "farmhouse", "farmstead", "cabin", "room",
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function containsAny(text, terms)
    for _, term in ipairs(terms or {}) do
        if text:find(term, 1, true) then return true, term end
    end
    return false, nil
end

function module.cellKind(cell)
    local name = lower(module.cellName(cell))
    local isExterior = cell and (cell.isExterior == true or cell.hasSky == true)
    local isInterior = not isExterior
    if not isInterior then return "exterior", "has_sky" end

    local isPublic, publicTerm = containsAny(name, publicCellTerms)
    local isPrivate, privateTerm = containsAny(name, privateHomeTerms)

    if isPrivate and not isPublic then return "private_home", privateTerm end
    if isPublic then return "public_or_service", publicTerm end
    if isPrivate then return "private_home", privateTerm end
    return "interior_unknown", nil
end

function module.isLikelyPrivateResidence(cell)
    return module.cellKind(cell) == "private_home"
end

function module.isLikelyPublicOrSharedInterior(cell)
    local kind = module.cellKind(cell)
    return kind == "public_or_service" or kind == "interior_unknown"
end

function module.isLikelyRentedOrPrivateRoom(cell)
    local name = lower(module.cellName(cell))
    if name:find("rent", 1, true) or name:find("rented", 1, true) then return true end
    if name:find("renter", 1, true) then return true end
    if name:find("rental", 1, true) then return true end
    if name:find("guest room", 1, true) then return true end
    if name:find("room for rent", 1, true) then return true end
    if name:find("bedroom for rent", 1, true) then return true end

    local kind = module.cellKind(cell)
    if kind ~= "public_or_service" and kind ~= "interior_unknown" then return false end
    return false
end

local rentalRoomPublicTerms = {
    "tavern", "inn", "tradehouse", "cornerclub",
}

local function objectText(obj, helpers)
    helpers = helpers or {}
    local recordId = tostring(obj and (obj.recordId or obj.id) or "")
    local model = helpers.objectModelPath and tostring(helpers.objectModelPath(obj) or "") or ""
    local name = helpers.objectName and tostring(helpers.objectName(obj) or "") or ""
    local globalVariable = tostring(obj and obj.globalVariable or "")
    local ownerRecord, ownerFaction = "", ""
    if obj and obj.owner then
        ownerRecord = tostring(obj.owner.recordId or "")
        ownerFaction = tostring(obj.owner.factionId or "")
    end
    return lower(recordId .. " " .. model .. " " .. name .. " " .. globalVariable .. " " .. ownerRecord .. " " .. ownerFaction)
end

local function textLooksRentalMarked(text)
    text = lower(text)
    return text:find("rent", 1, true) ~= nil
        or text:find("rented", 1, true) ~= nil
        or text:find("rental", 1, true) ~= nil
        or text:find("renter", 1, true) ~= nil
end

local function textLooksRentalRoomDoor(text)
    text = lower(text)
    return textLooksRentalMarked(text)
        or text:find("guest room", 1, true) ~= nil
        or text:find("room for rent", 1, true) ~= nil
        or text:find("bedroom for rent", 1, true) ~= nil
end

local function objectIsType(obj, helpers, typeName)
    local types = helpers and helpers.types
    local typeApi = types and types[typeName]
    if not (typeApi and typeApi.objectIsInstance and obj) then return false end
    local ok, value = pcall(typeApi.objectIsInstance, obj)
    return ok and value == true
end

local function objectCanCarryRentalEvidence(obj, helpers)
    if not obj then return false end
    if objectIsType(obj, helpers, "NPC") or objectIsType(obj, helpers, "Creature") then return false end
    if objectIsType(obj, helpers, "Door") then return true end
    if objectIsType(obj, helpers, "Container") then return true end
    if objectIsType(obj, helpers, "Activator") then return true end
    if objectIsType(obj, helpers, "Miscellaneous") then return true end
    if objectIsType(obj, helpers, "Book") then return true end
    return false
end

local function flatDistance(a, b)
    if not (a and b) then return nil end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function lockKeyText(obj, helpers)
    local types = helpers and helpers.types
    local lockable = types and types.Lockable
    if not (lockable and lockable.getKeyRecord and obj) then return "" end
    local ok, keyRecord = pcall(lockable.getKeyRecord, obj)
    if ok and keyRecord then return tostring(keyRecord) end
    return ""
end

local function objectDoorIsLockedNonTeleport(obj, helpers)
    local types = helpers and helpers.types
    if not (obj and types and types.Door and types.Door.objectIsInstance) then return false end
    local okDoor, isDoor = pcall(types.Door.objectIsInstance, obj)
    if not (okDoor and isDoor == true) then return false end
    local okTeleport, isTeleport = pcall(types.Door.isTeleport, obj)
    if okTeleport and isTeleport == true then return false end
    local lockable = types.Lockable
    if not (lockable and lockable.isLocked) then return false end
    local okLocked, locked = pcall(lockable.isLocked, obj)
    return okLocked and locked == true
end

function module.bedLooksBehindRentedRoomDoor(cell, candidate, helpers)
    if not (cell and candidate and candidate.object and candidate.object.position) then return false end
    local cellNameText = lower(module.cellName(cell))
    local inPublicLodging = containsAny(cellNameText, rentalRoomPublicTerms)
    if not inPublicLodging then return false end
    helpers = helpers or {}

    for _, obj in ipairs(cell:getAll()) do
        if obj and obj.position and objectDoorIsLockedNonTeleport(obj, helpers) then
            local text = objectText(obj, helpers) .. " " .. lockKeyText(obj, helpers)
            if textLooksRentalRoomDoor(text) then
                local distance = flatDistance(candidate.object.position, obj.position)
                local vertical = math.abs((candidate.object.position.z or 0) - (obj.position.z or 0))
                if distance and distance <= 520 and vertical <= 180 then return true end
            end
        end
    end

    return false
end

function module.bedLooksInRentedRoom(cell, candidate, helpers)
    if not (cell and candidate and candidate.object and candidate.object.position) then return false end
    if module.isLikelyRentedOrPrivateRoom(cell) then return true end
    local cellNameText = lower(module.cellName(cell))
    local inPublicLodging = containsAny(cellNameText, rentalRoomPublicTerms)
    if not inPublicLodging then return false end
    if textLooksRentalMarked(objectText(candidate.object, helpers)) then return true end

    for _, obj in ipairs(cell:getAll()) do
        if obj and obj ~= candidate.object and obj.position and objectCanCarryRentalEvidence(obj, helpers) and textLooksRentalMarked(objectText(obj, helpers)) then
            local distance = flatDistance(candidate.object.position, obj.position)
            local vertical = math.abs((candidate.object.position.z or 0) - (obj.position.z or 0))
            if distance and distance <= 360 and vertical <= 160 then return true end
        end
    end
    if module.bedLooksBehindRentedRoomDoor(cell, candidate, helpers) then return true end
    return false
end

return module
