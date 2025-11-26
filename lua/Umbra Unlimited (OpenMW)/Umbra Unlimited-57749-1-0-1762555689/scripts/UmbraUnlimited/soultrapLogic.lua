local self = require("openmw.self")

local function addSoultrap(attack)
    local activeSpells = self.type.activeSpells(self)
    activeSpells:add({
        -- "soul trap" instead of "umbra's hunger" for foolproofing
        -- in case someone decides to edit base enchantment for some reason
        id = "soul trap",
        effects = { 0 },
        caster = attack.attacker,
    })
end

local sourceTypes = {
    melee = function (attack)
        local weapon = attack.weapon
        return weapon.recordId == "longsword_umbra_unique"  -- vanilla Umbra Sword
            or string.find(weapon.recordId, "^md_umb_") -- MD's Umbra Blademaster melee weapons
    end,
    ranged = function (attack)
        return string.find(attack.ammo, "^md_umb_") -- MD's Umbra Blademaster throwable weapons
    end
}

function DoSoultrap(attack)
    if not attack.successful
        or not attack.weapon
        or not attack.ammo
    then
        return
    end

    if sourceTypes[attack.sourceType]
        or sourceTypes[attack.sourceType](attack)
    then
        addSoultrap(attack)
    end
end