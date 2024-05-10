local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
tes3.claimSpellEffectId("boundGrassSwd", 7779)

local function getDescription(weaponName)
    return "This effect summons a " .. weaponName .. ", utilized by the Druids. The " .. weaponName .. " appears automatically equipped and displaces any equipped weapon to inventory."
end

local function addBoundWeaponEffects()
    local grassSwordName = "Grass Sword"  -- Define the name of the weapon
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundGrassSwd,
        name = "Grass Sword",
        baseCost = 15,
        weaponId = "vss_drd_grssSwrd",
        icon = "RFD\\RFD_ms_conjuration.dds"
    })
    tes3.addSpell({
        id = "vss_drd_grssSwrd_spell",
        name = "Grass Sword",
        effect = tes3.effect.boundGrassSwd,
        range = tes3.effectRange.self,
        duration = 30,
        magickaCost = 33,
        description = getDescription(grassSwordName)  -- Pass the weapon name to getDescription function
    })
end

event.register("magicEffectsResolved", addBoundWeaponEffects)
