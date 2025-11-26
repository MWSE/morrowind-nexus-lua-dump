local types = require("openmw.types")

require("scripts.CanonicalGear.utils")

WizardStaffId = "ebony wizard's staff"
MGFactionIds = {
    ["mages guild"] = true,
    ["t_mw_magesguild"] = true,
    ["t_sky_magesguild"] = true,
    ["t_ham_magesguild"] = true,
    ["t_cyr_magesguild"] = true,
}
MGRanks = {
    associate    = 1,
    apprentice   = 2,
    journeyman   = 3,
    evoker       = 4,
    conjurer     = 5,
    magician     = 6,
    warlock      = 7,
    wizard       = 8,
    masterWizard = 9,
    archMage     = 10,
}
ExcludedWizards = {
    ["trebonius artorius"] = true,
}

MouthStaffId = "silver staff of peace"
TelFactionIds = {
    ["telvanni"] = true,
    ["t_mw_housetelvanni"] = true,
}
TelvanniRanks = {
    hireling     = 1,
    retainer     = 2,
    oathman      = 3,
    lawman       = 4,
    mouth        = 5,
    spellwright  = 6,
    wizard       = 7,
    master       = 8,
    magister     = 9,
    archmagister = 10,
}
ExcludedMouths = {
    ["edd theman"] = true,
}

KingsOathId = "King's_Oath"
AdamantiumClaymoreId = "adamantium_claymore"
RoyalGuardRanks = {
    guard   = 1,
    captain = 2,
}

DorisaDarvel = "dorisa darvel"
DorisaDarvelsBooks = {
    "bk_WaroftheFirstCouncil",
    "bk_SaintNerevar",
    "bk_NerevarMoonandStar",
    "bk_RealNerevar"
}

function TryItemEquip(actor, item, slot, forceEquip)
    local eqItem = actor.type.equipment(actor, slot)

    -- if nothing is equipped, equip the item
    if not eqItem then
        actor:sendEvent("equipItem", {
            item = item,
            slot = slot
        })
        return
    end

    local eqItemRecordId = eqItem.recordId

    -- dont's swap out scripted items
    if eqItemRecordId.mwsript then return end

    local eqItemRecord = eqItem.type.records[eqItemRecordId]
    local newItemRecord = item.type.records[item.recordId]
    if forceEquip or newItemRecord.value > eqItemRecord.value then
        actor:sendEvent("equipItem", {
            item = item,
            slot = slot
        })
    end
end

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