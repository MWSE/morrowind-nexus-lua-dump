local config = require("OperatorJack.SimpleCombatMechanics.config")

local this = {}
this.debug = function (message)
    if (config.debugMode == true) then
        local prepend = '[Simple Combat Mechanics: DEBUG] '
        mwse.log(prepend .. message)
        tes3.messageBox(prepend .. message)
    end
end

this.skillMappings = {
    [tes3.weaponType.shortBladeOneHand] = "shortBlade",
    [tes3.weaponType.longBladeOneHand] = "longBlade",
    [tes3.weaponType.longBladeTwoClose] = "longBlade",
    [tes3.weaponType.bluntOneHand] = "bluntWeapon",
    [tes3.weaponType.bluntTwoClose] = "bluntWeapon",
    [tes3.weaponType.bluntTwoWide] = "bluntWeapon",
    [tes3.weaponType.spearTwoWide] = "spear",
    [tes3.weaponType.axeOneHand] = "axe",
    [tes3.weaponType.axeTwoHand] = "axe",
    [tes3.weaponType.marksmanBow] = "marksman",
    [tes3.weaponType.marksmanCrossbow] = "marksman",
    [tes3.weaponType.marksmanThrown] = "marksman",
    [tes3.weaponType.bolt] = "marksman",
    [tes3.weaponType.arrow] = "marksman",
}

this.weaponTypeBlacklist = {
    [tes3.weaponType.marksmanBow] = true,
    [tes3.weaponType.marksmanCrossbow] = true,
    [tes3.weaponType.marksmanThrown] = true,
    [tes3.weaponType.arrow] = true,
    [tes3.weaponType.bolt] = true,
}

this.getReferencesNearPoint = function(position, distance)
    local cells = tes3.getActiveCells()
    local references = {}
    for _, cell in pairs(cells) do
        for reference in cell:iterateReferences() do
            if (reference.position:distance(position) <= distance) then
                table.insert(references, reference)
            end
        end
    end
    return references
end

return this