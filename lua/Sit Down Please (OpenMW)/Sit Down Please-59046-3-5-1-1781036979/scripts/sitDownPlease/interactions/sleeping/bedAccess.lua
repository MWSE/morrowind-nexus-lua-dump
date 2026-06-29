-- interactions/sleeping/bedAccess.lua
---@omw-context none
--
-- Shared bed-access policy for public lodging and player-rental rooms.
-- Keep this separate from interactionAssignment.lua; that file owns scheduling,
-- while this module owns whether a bed is eligible for ordinary NPC sleep use.

local cellContext = require('scripts/sitDownPlease/world/cellContext')

local M = {}

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
