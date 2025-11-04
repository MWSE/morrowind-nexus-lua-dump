local types = require("openmw.types")
local world = require("openmw.world")

require("scripts.CanonicalGear.globalValues")
require("scripts.CanonicalGear.utils")
require("scripts.CanonicalGear.equipment.items")

local function isRoyalGuard(actor)
    return types.NPC.getFactionRank(actor, "royal guard") >= RoyalGuardRanks.guard
end

local function hasKingsOath(actor)
    local hasOldWeapon = types.Actor.inventory(actor):find(AdamantiumClaymoreId) ~= nil
    local hasNewWeapon = types.Actor.inventory(actor):find(KingsOathId) ~= nil
    local wasGivenNewWeapon = GearedNPCs.kingsOath[actor.id] == true
    return wasGivenNewWeapon or (not hasOldWeapon and hasNewWeapon)
end

function AddKingsOath(actor)
    if not isRoyalGuard(actor) or hasKingsOath(actor) then return end

    -- remove old claymores
    local adamClaymores = types.Actor.inventory(actor):findAll(AdamantiumClaymoreId)
    for _, adamClaymore in ipairs(adamClaymores) do
        adamClaymore:remove()
    end

    local kingsOath = world.createObject(KingsOathId)
    kingsOath:moveInto(actor)
    TryItemEquip(
        actor,
        kingsOath,
        types.Actor.EQUIPMENT_SLOT.CarriedRight,
        true)

    Log("Given King's Oath to " .. actor.recordId)
    GearedNPCs.kingsOath[actor.id] = true
end
