local common = require("blight.common")

local function attemptTransmission(reference, isTransmitterPlayer, transmitterName, spell)
    local message = "You have transmitted %s to " .. reference.object.name .. "."
    if (isTransmitterPlayer == false) then
        message = "You have contracted %s from " .. transmitterName .. "."
    end

    event.trigger("blight:TriggerBlight", {
        reference = reference,
        diseaseId = spell.id,
        displayMessage = true,
        message = message
    })
end

event.register("activate", function(e)
    if not common.config.enableActiveTransmission then return end

    if  e.target.object.organic ~= true and
        e.target.object.objectType ~= tes3.objectType.npc and
        e.target.object.objectType ~= tes3.objectType.creature then
        return
    end

    local activator = e.activator
    local target = e.target
    local actorSpells, actCanTransmit = common.getTransmittableBlightDiseases(activator, target)
    local targetSpells, targetCanTransmit = common.getTransmittableBlightDiseases(target, activator)

    -- Calculated blight status separately so that the first actions would not impact the target's set of actions.
    if actCanTransmit == true then
        attemptTransmission(target, activator == tes3.player, activator.object.name, table.choice(actorSpells))
    end
    if targetCanTransmit == true then
        attemptTransmission(activator, target == tes3.player, target.object.name, table.choice(targetSpells))
    end
end)