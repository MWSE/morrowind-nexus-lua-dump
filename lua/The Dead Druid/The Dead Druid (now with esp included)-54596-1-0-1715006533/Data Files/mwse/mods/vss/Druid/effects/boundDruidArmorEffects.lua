local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
tes3.claimSpellEffectId("boundWoodWard", 7781)

-- Define the name of the spell effect as a string
local wardOfWoodName = "Ward of Wood"

local function getSingleDescription(armorName)
    return "The spell effect conjures an enchanted Druidic shield in the form of the " ..
            armorName ..
            ". The " ..
            armorName ..
            " appears automatically equipped on the caster, displacing any currently equipped armor to inventory.  When the effect ends, the " ..
            armorName ..
            " disappears, and any previously equipped armor is automatically re-equipped."
end

local function addBoundArmorEffects()
    framework.effects.conjuration.createBasicBoundArmorEffect({
        id = tes3.effect.boundWoodWard,
        name = "Ward of Wood",
        baseCost = 15,
        armorId = "vss_drd_woodWard",
        icon = "RFD\\RFD_ms_conjuration.dds",
        description = getSingleDescription(wardOfWoodName)  -- Use getSingleDescription to set the description
    })
end

event.register("magicEffectsResolved", addBoundArmorEffects)

