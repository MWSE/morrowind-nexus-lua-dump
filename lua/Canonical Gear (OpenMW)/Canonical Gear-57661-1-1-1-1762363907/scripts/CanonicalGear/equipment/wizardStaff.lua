local types = require("openmw.types")
local world = require("openmw.world")

require("scripts.CanonicalGear.globalValues")
require("scripts.CanonicalGear.utils")
require("scripts.CanonicalGear.equipment.items")

local function isWizard(actor)
    if ExcludedWizards[actor.recordId] then return false end
    return IsHighEnoughRankInFactionGroup(actor, MGFactionIds, MGRanks.wizard)
end

local function hasWizardStaff(actor)
    local hasStaff = types.Actor.inventory(actor):find(WizardStaffId) ~= nil
    local wasGivenStaff = GearedNPCs.wizardStaff[actor.id] == true
    return hasStaff or wasGivenStaff
end

function AddWizardStaff(actor)
    if not isWizard(actor) or hasWizardStaff(actor) then return end

    local staff = world.createObject(WizardStaffId)
    staff:moveInto(actor)
    TryItemEquip(
        actor,
        staff,
        types.Actor.EQUIPMENT_SLOT.CarriedRight,
        Toggles:get("wizardStaffForceEquip"))

    Log("Given Wizard Staff to " .. actor.recordId)
    GearedNPCs.wizardStaff[actor.id] = true
end
