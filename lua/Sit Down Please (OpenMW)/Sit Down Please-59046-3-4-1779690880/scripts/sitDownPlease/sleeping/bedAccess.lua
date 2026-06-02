-- sleeping/bedAccess.lua
--
-- Shared bed-access policy for public lodging and player-rental rooms.
-- Keep this separate from interactionAssignment.lua; that file owns scheduling,
-- while this module owns whether a bed is eligible for ordinary NPC sleep use.

local cellContext = require('scripts/sitDownPlease/world/cellContext')

local M = {}

local function lower(value)
    if value == nil then return "" end
    return string.lower(tostring(value))
end

local function cellName(cell)
    if not cell then return "" end
    local ok, name = pcall(function()
        return cell.name or cell.id or ""
    end)
    if ok then return tostring(name or "") end
    return ""
end

local publicLodgingTerms = {
    "tavern",
    "inn",
    "tradehouse",
    "cornerclub",
}

local function containsAny(text, terms)
    text = lower(text)
    for _, term in ipairs(terms or {}) do
        if text:find(term, 1, true) then return true, term end
    end
    return false, nil
end

function M.isPublicLodgingCell(cell)
    if not cellContext.isLikelyPublicOrSharedInterior(cell) then return false end
    return containsAny(cellName(cell), publicLodgingTerms)
end

function M.rentalRoomReason(cell, candidate, helpers)
    if cellContext.bedLooksInRentedRoom(cell, candidate, helpers) then
        return "rented_or_private_inn_bed"
    end
    return nil
end

function M.normalAssignmentBlockReason(args)
    args = args or {}
    local cell = args.cell
    local candidate = args.candidate
    if args.debugForce ~= true then
        local rentalReason = M.rentalRoomReason(cell, candidate, args.helpers)
        if rentalReason then return rentalReason end
    end

    return nil
end

function M.shouldRestrictDoorAssist(cell, originPreferred, debugForce)
    return cellContext.isLikelyPublicOrSharedInterior(cell)
        and originPreferred ~= true
        and debugForce ~= true
end

return M
