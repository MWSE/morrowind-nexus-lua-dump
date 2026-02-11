local types = require("openmw.types")
local core = require("openmw.core")

require("scripts.ShelfControl.model.owner")

local l10n = core.l10n("ShelfControl_cells")
local ICFactionIds = {
    ["imperial cult"] = true,
    ["t_mw_imperialcult"] = true,
    ["t_sky_imperialcult"] = true,
}
local ICClasses = {
    priest = true,
}
local whitelistedCellNames = {
    l10n("library"),
    l10n("temple"),
    l10n("chapel"),
    l10n("shrine"),
}
local blacklistedCells = {
    -- [l10n("example")] = true,
}

function IsHighEnoughRankInFactionGroup(npc, factionList, rank)
    for _, faction in pairs(types.NPC.getFactions(npc)) do
        if factionList[faction] then
            if types.NPC.getFactionRank(npc, faction) >= rank then
                return true
            end
        end
    end
    return false
end

local function itsACultShrine(cell, owner)
    if not owner.self then return false end
    -- if cult srine is nearby
    for _, activator in pairs(cell:getAll(types.Activator)) do
        if types.Activator.record(activator).mwscript == "shrineimperial" then
            -- if owner is imperical cult member
            -- or if owner is a priest (class description says they work at imperial shrines + it make sense)
            -- on an unrelated note: why TF Vala Catraso is not a member of the cult???
            if IsHighEnoughRankInFactionGroup(owner.self, ICFactionIds, 1)
                or ICClasses[owner.record.class]
            then
                return true
            end
        end
    end
    return false
end

function LocationIsWhitelisted(ctx)
    local cell = ctx.book.cell
    local cellName = string.lower(cell.name)

    if blacklistedCells[cellName] then return false end

    for _, namePart in pairs(whitelistedCellNames) do
        if string.find(cellName, namePart) then
            return true
        end
    end
    -- double check if it's a cult shrine
    if itsACultShrine(cell, ctx.owner) then return true end

    return false
end
