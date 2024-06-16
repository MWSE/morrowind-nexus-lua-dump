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
    return "Этот эффект заклинания вызывает малую Даэдру, скованную в форме магического, удивительно легкого" ..
    weaponName .. ". Он немедленно появляется в руке заклинателя, перемещая любое экипированное оружие в инвентарь" ..
    " Когда эффект ".. weaponName .. " заканчивается,  призванное оружие исчезает, а то, которым пользовался заклинатель вначале, автоматически экипируется."
end

local function getFemaleDescription(weaponName)
    return "Этот эффект заклинания вызывает малую Даэдру, скованную в форме магической, удивительно легкой" ..
    weaponName .. ". Она немедленно появляется в руке заклинателя, перемещая любое экипированное оружие в инвентарь" ..
    " Когда эффект ".. weaponName .. " заканчивается,  призванное оружие исчезает, а то, которым пользовался заклинатель вначале, автоматически экипируется."
end

local function addBoundWeaponEffects()
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundWarhammer,
        name = "Призвать боевой молот",
        description = getDescription("Даэдрического боевого молота"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundWarhammer",
		icon = "RFD\\RFD_lf_warhammer.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundWarAxe,
        name = "Призвать топор",
        description = getDescription("Даэдрического топора"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundWarAxe",
		icon = "RFD\\RFD_lf_waraxe.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundWakizashi,
        name = "Призвать вакидзаси",
        description = getDescription("Даэдрического вакидзаси"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundWakizashi",
		icon = "RFD\\RFD_lf_wakizashi.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundTanto,
        name = "Призвать танто",
        description = getDescription("Даэдрического танто"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundTanto",
		icon = "RFD\\RFD_lf_tanto.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundStaff,
        name = "Призвать посох",
        description = getDescription("Даэдрического посоха"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundStaff",
		icon = "RFD\\RFD_lf_staff.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundShortSword,
        name = "Призвать короткий меч",
        description = getDescription("Даэдрического короткого меча"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundShortsword",
		icon = "RFD\\RFD_lf_shortsword.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundKatana,
        name = "Призвать катану",
        description = getFemaleDescription("Даэдрической катаны"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundKatana",
		icon = "RFD\\RFD_lf_katana.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundDaiKatana,
        name = "Призвать дайкатану",
        description = getFemaleDescription("Даэдрической дайкатаны"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundDaiKatana",
		icon = "RFD\\RFD_lf_daikatana.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundClub,
        name = "Призвать дубину",
        description = getFemaleDescription("Даэдрической дубины"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundClub",
		icon = "RFD\\RFD_lf_club.dds"
    })
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundClaymore,
        name = "Призвать клеймору",
        description = getFemaleDescription("Даэдрической клейморы"),
        baseCost = 2,
        weaponId = "OJ_ME_BoundClaymore",
		icon = "RFD\\RFD_lf_claymore.dds"
    })
end

event.register("magicEffectsResolved", addBoundWeaponEffects)