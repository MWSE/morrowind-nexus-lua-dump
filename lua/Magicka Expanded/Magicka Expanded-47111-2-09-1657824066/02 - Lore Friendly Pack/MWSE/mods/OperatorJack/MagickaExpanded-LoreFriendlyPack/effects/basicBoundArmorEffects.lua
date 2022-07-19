local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("boundGreaves", 239)
tes3.claimSpellEffectId("boundLeftPauldron", 240)
tes3.claimSpellEffectId("boundRightPauldron", 264)


local function getPairDescription(armorName)
    return "The spell effect conjures a lesser Daedra bound in the form of a magical," ..
    " wondrously light pair of " .. armorName ..". The ".. armorName .." appear automatically" ..
    " equipped on the caster, displacing any currently equipped armor to inventory.  When the effect ends, "..
    " the " .. armorName .. " disappear, and any previously equipped armor is automatically re-equipped."
end
local function getSingleDescription(armorName)
    return "The spell effect conjures a lesser Daedra bound in the form of a magical," ..
    " wondrously light " .. armorName ..". The ".. armorName .." appears automatically" ..
    " equipped on the caster, displacing any currently equipped armor to inventory.  When the effect ends, "..
    " the " .. armorName .. " disappears, and any previously equipped armor is automatically re-equipped."
end

local function addBoundArmorEffects()
    framework.effects.conjuration.createBasicBoundArmorEffect({
        id = tes3.effect.boundGreaves,
        name = "Bound Greaves",
        description = getPairDescription("Daedric Greaves"),
        baseCost = 2,
        armorId = "OJ_ME_BoundGreaves",
		icon = "RFD\\RFD_lf_greaves.dds"
    })
    framework.effects.conjuration.createBasicBoundArmorEffect({
        id = tes3.effect.boundLeftPauldron,
        name = "Bound Left Pauldron",
        description = getSingleDescription("Daedric Left Pauldron"),
        baseCost = 2,
        armorId = "OJ_ME_BoundPauldronLeft",
		icon = "RFD\\RFD_lf_pauldron_L.dds"
    })
    framework.effects.conjuration.createBasicBoundArmorEffect({
        id = tes3.effect.boundRightPauldron,
        name = "Bound Right Pauldron",
        description = getSingleDescription("Daedric Right Pauldron"),
        baseCost = 2,
        armorId = "OJ_ME_BoundPauldronRight",
		icon = "RFD\\RFD_lf_pauldron_R.dds"
    })
end

event.register("magicEffectsResolved", addBoundArmorEffects)