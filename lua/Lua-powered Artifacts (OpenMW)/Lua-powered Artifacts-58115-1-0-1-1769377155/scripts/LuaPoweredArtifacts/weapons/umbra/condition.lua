local storage = require("openmw.storage")

local sectionUmbra = storage.globalSection("SettingsLuaPoweredArtifacts_umbra")

local sourceTypes = {
    melee = function(attack)
        local weapon = attack.weapon
        return weapon.recordId == "longsword_umbra_unique" -- vanilla Umbra Sword
            or string.find(weapon.recordId, "^md_umb_")    -- MD's Umbra Blademaster melee weapons
    end,
    ranged = function(attack)
        return string.find(attack.ammo, "^md_umb_") -- MD's Umbra Blademaster throwable weapons
    end
}

function UmbraCond(attack)
    if not sectionUmbra:get("enabled") then
        return false
    end

    if not (attack.successful and (attack.weapon or attack.ammo)) then
        return false
    end

    local checkWeapon = sourceTypes[attack.sourceType]
    return checkWeapon and checkWeapon(attack)
end
