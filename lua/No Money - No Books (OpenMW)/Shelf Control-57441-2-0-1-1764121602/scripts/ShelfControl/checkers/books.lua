local types = require("openmw.types")

require("scripts.ShelfControl.utils.tables")
require("scripts.ShelfControl.utils.consts")

--- A book is NPC owned if:
---   - It has a living NPC owner.
--- Dead or unloaded NPCs don't count as owners.
function IsNpcOwned(owner)
    if not owner.recordId then return false end
    if owner.factionId then return false end
    if owner.isDead then return false end
    return true
end

--- A book is buyable if:
---   - It has a living NPC owner,
---   - The owner sells books,
---   - It is not faction-owned.
--- Dead or unloaded NPCs don't count as owners.
function IsBuyable(owner)
    if not owner.recordId then return false end
    if owner.factionId then return false end
    if not owner.sellsBooks then return false end
    if owner.isDead then return false end
    return true
end

--- A book is faction owned if:
---   - It has a owner faction,
---   - The cell has at least one NPC loaded in.
function IsFactionOwned(owner)
    if not owner.factionId then return false end
    if UnrestrictiveFactions[string.lower(owner.factionId)] then return true end
    local actorsNearby = owner.book.cell:getAll(types.NPC)[1]
    if actorsNearby == nil then return false end
    return true
end