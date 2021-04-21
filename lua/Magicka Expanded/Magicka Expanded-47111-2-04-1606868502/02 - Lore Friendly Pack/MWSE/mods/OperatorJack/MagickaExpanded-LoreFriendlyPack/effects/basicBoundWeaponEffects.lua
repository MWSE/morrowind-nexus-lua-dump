local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("boundClaymore", 229)
tes3.claimSpellEffectId("boundClub", 230)
tes3.claimSpellEffectId("boundDaiKatana", 231)
tes3.claimSpellEffectId("boundKatana", 232)
tes3.claimSpellEffectId("boundShortSword", 233)
tes3.claimSpellEffectId("boundStaff", 234)
tes3.claimSpellEffectId("boundTanto", 235)
tes3.claimSpellEffectId("boundWakizashi", 236)
tes3.claimSpellEffectId("boundWarAxe", 237)
tes3.claimSpellEffectId("boundWarhammer", 238)

local function getDescription(weaponName)
    return "The spell effect conjures a lesser Daedra bound in the form of  amagical, wondrously light Daedric " ..
    weaponName .. ". The ".. weaponName .. " appear automatically equipped on the caster, displacing any currently " ..
    " equipped weapon to inventory.  When the effect ends, the ".. weaponName .. " disappears, and any previously " .. 
    " equipped weapon is automatically re-equipped."
end

local function addBoundWeaponEffects()
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundWarhammer,
        name = "Bound Warhammer",
        description = getDescription("Daedric Warhammer"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundWarhammer",
		icon = "RFD\\RFD_lf_warhammer.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundWarAxe,
        name = "Bound War Axe",
        description = getDescription("Daedric War Axe"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundWarAxe",
		icon = "RFD\\RFD_lf_waraxe.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundWakizashi,
        name = "Bound Wakizashi",
        description = getDescription("Daedric Wakizashi"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundWakizashi",
		icon = "RFD\\RFD_lf_wakizashi.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundTanto,
        name = "Bound Tanto",
        description = getDescription("Daedric Tanto"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundTanto",
		icon = "RFD\\RFD_lf_tanto.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundStaff,
        name = "Bound Staff",
        description = getDescription("Daedric Staff"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundStaff",
		icon = "RFD\\RFD_lf_staff.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundShortSword,
        name = "Bound Shortsword",
        description = getDescription("Daedric Shortsword"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundShortsword",
		icon = "RFD\\RFD_lf_shortsword.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundKatana,
        name = "Bound Katana",
        description = getDescription("Daedric Katana"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundKatana",
		icon = "RFD\\RFD_lf_katana.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundDaiKatana,
        name = "Bound Dai-Katana",
        description = getDescription("Daedric Dai-Katana"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundDaiKatana",
		icon = "RFD\\RFD_lf_daikatana.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundClub,
        name = "Bound Club",
        description = getDescription("Daedric Club"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundClub",
		icon = "RFD\\RFD_lf_club.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundClaymore,
        name = "Bound Claymore",
        description = getDescription("Daedric Claymore"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundClaymore",
		icon = "RFD\\RFD_lf_claymore.dds"
    })
end

event.register("magicEffectsResolved", addBoundWeaponEffects)