local types = require("openmw.types")
local world = require("openmw.world")

require("scripts.CanonicalGear.globalValues")
require("scripts.CanonicalGear.utils")
require("scripts.CanonicalGear.equipment.items")

local function isMouth(actor)
    if ExcludedMouths[actor.recordId] then return false end
    return types.NPC.getFactionRank(actor, "telvanni") >= TelvanniRanks.mouth
end

local function hasMouthStaff(actor)
    local hasStaff = types.Actor.inventory(actor):find(MouthStaffId) ~= nil
    local wasGivenStaff = GearedNPCs.mouthStaff[actor.id] == true
    return hasStaff or wasGivenStaff
end

function AddMouthStaff(actor)
    if not isMouth(actor) or hasMouthStaff(actor) then return end

    local staff = world.createObject(MouthStaffId)
    staff:moveInto(actor)
    TryItemEquip(
        actor,
        staff,
        types.Actor.EQUIPMENT_SLOT.CarriedRight,
        Toggles:get("mouthStaffForceEquip"))

    Log("Given Mouth Staff to " .. actor.recordId)
    GearedNPCs.mouthStaff[actor.id] = true
end
