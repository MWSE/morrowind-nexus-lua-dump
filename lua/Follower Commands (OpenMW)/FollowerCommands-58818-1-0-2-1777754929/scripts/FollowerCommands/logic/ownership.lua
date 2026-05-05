local ownership = {}

---@param player GameObject
---@param obj GameObject
---@return boolean
ownership.isOwned = function(player, obj)
    local owner = obj.owner
    if not owner then return false end

    if owner.recordId then return true end

    -- owned by faction but doesn't have a faction requirements
    local availableAt = owner.factionRank
    if not availableAt then return false end

    local ownerFaction = owner.factionId
    local rank = player.type.getFactionRank(player, ownerFaction)
    return rank < availableAt
end

return ownership
