local types = require("openmw.types")

require("scripts.ShelfControl.utils.tables")
require("scripts.ShelfControl.utils.consts")

--- A book is NPC owned if:
---   - It has a living NPC owner.
--- Dead or unloaded NPCs don't count as owners.
function IsNpcOwned(ctx)
    if not ctx.owner.recordId then return false end
    if ctx.owner.factionId then return false end
    if ctx.owner.isDead then return false end
    return true
end

--- A book is buyable if:
---   - It has a living NPC owner,
---   - The owner sells books,
---   - It is not faction-owned.
--- Dead or unloaded NPCs don't count as owners.
function IsBuyable(ctx)
    if not ctx.owner.recordId then return false end
    if ctx.owner.factionId then return false end
    if not ctx.owner.sellsBooks then return false end
    if ctx.owner.isDead then return false end
    return true
end

--- A book is faction owned if:
---   - It has a owner faction,
---   - Player is a member of a faction, but he is not of a sufficient rank
---   - The cell has at least one NPC loaded in.
function IsFactionOwned(ctx)
    if not ctx.owner.factionId then return false end
    if UnrestrictiveFactions[string.lower(ctx.owner.factionId)] then return true end

    local playerRank = ctx.player.type.getFactionRank(ctx.player, ctx.owner.factionId)
    local requiredRank = ctx.owner.factionRank or 1
    if playerRank >= requiredRank then return false end

    local actorsNearby = ctx.owner.book.cell:getAll(types.NPC)[1]
    if actorsNearby == nil then return false end
    return true
end