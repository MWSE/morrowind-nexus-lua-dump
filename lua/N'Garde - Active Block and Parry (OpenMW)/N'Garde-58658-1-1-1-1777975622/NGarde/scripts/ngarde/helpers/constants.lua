local types = require('openmw.types')
local anim = require('openmw.animation')
local core = require('openmw.core')
Constants = {}

Constants.staggerAnimations = {
    "hit1",
    "hit2",
    "hit3",
    "hit4",
    "hit5",
    "swimhit1",
    "swimhit2",
    "swimhit3",
    "knockdown",
    "knockout",
    "swimknockout",
    "swimknockdown",
}

Constants.attackAnimations = {
    "attack1",
    "attack2",
    "attack3",
    "chop max attack",
    "chop min attack",
    "slash max attack",
    "slash min attack",
    "thrust max attack",
    "thrust min attack",
    "swimattack1",
    "swimattack2",
    "swimattack3",
    "handtohand",
    "weapontwowide",
    "weapontwohand",
    "weapononehand",
    "weapontwowide1",
    "weapontwohand1",
    "weapononehand1",
    "throwweapon",
    "throwweapon1",
}


Constants.weaponToTypeMap = {
    [0]  = "shortbladeonehand",
    [1]  = "longbladeonehand",
    [2]  = "longbladetwohand",
    [3]  = "bluntonehand",
    [4]  = "blunttwoclose",
    [5]  = "blunttwowide",
    [6]  = "speartwowide",
    [7]  = "axeonehand",
    [8]  = "axetwohand",
    [9]  = "marksmanbow",
    [10] = "marksmancrossbow",
    [11] = "marksmanthrown",
    [12] = "arrow",
    [13] = "bolt",
    [99] = "handtohand"
}

Constants.meleeWeaponSkillIds = {
    "longblade",
    "shortblade",
    "bluntweapon",
    "spear",
    "axe",
    "handtohand",
}

Constants.attackEffectivenessMap = {

}

Constants.skillIdToName = {
    ["longblade"] = "Long Blade",
    ["shortblade"] = "Short Blade",
    ["bluntweapon"] = "Blunt Weapon",
    ["spear"] = "Spear",
    ["axe"] = "Axe",
    ["handtohand"] = "Hand-to-Hand",
}

Constants.twoHandWeapons = {
    [2] = true,  -- LongBladeTwoHand
    [4] = true,  -- BluntTwoClose
    [5] = true,  -- BluntTwoWide
    [6] = true,  -- SpearTwoWide
    [8] = true,  -- AxeTwoHand
    [9] = true,  -- MarksmanBow
    [10] = true, -- MarksmanCrossbow
    [99] = true, -- HandToHand
}


Constants.rangedWeapons = {
    [9] = true,  -- MarksmanBow
    [10] = true, -- MarksmanCrossbow
    [11] = true, -- MarksmanThrown
}

Constants.HandToHandRecordStub = { name = 'hand-to-hand', type = 99, reach = core.getGMST("fHandToHandReach") or 1, weight = 0 }
---It seems interesting to give short blades bonuses against long-reach weapons. Not exactly convenient to defend with a spear or warhammer against a dagger hit.

Constants.parryAllowedWeaponTypes = {
    [0] = {
        name = "shortbladeonehand",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'shortblade',
        secondarySkillId = 'block',
        material = "metal",
        animation = "1hSupportedHighGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.RightArm + anim.BLEND_MASK.Torso,
        parryArc = 100,  --degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1.5,
        moveSpeedMultiplier = 0.95,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 0'
    },
    [1] = {
        name = "longbladeonehand",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'longblade',
        secondarySkillId = 'block',
        material = "metal",
        animation = "1hSwHighGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.RightArm,
        parryArc = 140,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1.5,
        moveSpeedMultiplier = 0.85,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1'
    },
    [2] = {
        name = "longbladetwohand",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'longblade',
        secondarySkillId = 'block',
        material = "metal",
        animation = "2hSwHighGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.RightArm + anim.BLEND_MASK.Torso,
        parryArc = 160,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1,
        moveSpeedMultiplier = 0.75,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1'
    },
    [3] = {
        name = "bluntonehand",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'bluntweapon',
        secondarySkillId = 'block',
        material = "metal_heavy",
        animation = "1hSupportedHighGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm,
        parryArc = 120,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1.5,
        moveSpeedMultiplier = 0.85,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1'
    },
    [4] = {
        name = "blunttwoclose",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'bluntweapon',
        secondarySkillId = 'block',
        material = "metal_heavy",
        animation = "2hAxeBluntGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm,
        parryArc = 140,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1,
        moveSpeedMultiplier = 0.75,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1'
    },
    [5] = {
        name = "blunttwowide",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'bluntweapon',
        secondarySkillId = 'block',
        material = "wood",
        animation = "2hStaffSpearGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.RightArm,
        parryArc = 160,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1,
        moveSpeedMultiplier = 0.75,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1'
    },
    [6] = {
        name = "speartwowide",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'spear',
        secondarySkillId = 'block',
        material = "wood",
        animation = "2hStaffSpearGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm,
        parryArc = 160,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1,
        moveSpeedMultiplier = 0.8,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 0'
    },
    [7] = {
        name = "axeonehand",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'axe',
        secondarySkillId = 'block',
        material = "metal",
        animation = "1hSupportedHighGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm,
        parryArc = 120,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1.5,
        moveSpeedMultiplier = 0.85,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1'
    },
    [8] = {
        name = "axetwohand",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'axe',
        secondarySkillId = 'block',
        material = "metal_heavy",
        animation = "2hAxeBluntGuard",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.RightArm,
        parryArc = 140,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 1,
        moveSpeedMultiplier = 0.75,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1'
    },
    [99] = {
        name = "handtohand",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'handtohand',
        secondarySkillId = 'handtohand',
        material = "hands",     -- default material if not gauntlets
        animation = "h2hblock",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm,
        parryArc = 100,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 4,
        moveSpeedMultiplier = 1,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Weapon Bone'
    },
}


Constants.shieldParryConfig = {
    name = "shield",
    effectiveness = 0,
    baseEffectiveness = 1,
    mainSkillId = 'block',
    secondarySkillId = 'block',
    material = "lightarmor",
    animation = "shieldraise",
    priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted },
    blendMask = anim.BLEND_MASK.LeftArm,
    parryArc = 160,   -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
    parryOffset = 10, -- how easy it is to bring the weapon to opposite side to parry
    animationSpeed = 0.8,
    moveSpeedMultiplier = 0.65,
    vfxModel = 'meshes/e/spark.nif',
    vfxBone = 'Shield Bone'
}


Constants.materialToSoundMap = {
    ["metal"] = { parry = { path = "sounds/parry/parry_metal_light.wav", options = { volume = 1 } }, perfectParry = { path = "sounds/parry/perfect_parry_metal.wav", options = { volume = 1 }, overlap = true, } },
    ["metal_heavy"] = { parry = { path = "sounds/parry/parry_metal_heavy.wav", options = { volume = 1 } }, perfectParry = { path = "sounds/parry/perfect_parry_metal.wav", options = { volume = 1, pitch = 0.85 }, overlap = true, } },
    ["wood"] = { parry = { path = "sounds/parry/parry_wood.wav", options = { volume = 1 } }, perfectParry = { path = "sounds/parry/perfect_parry_metal.wav", options = { volume = 0.9, pitch = 0.85 }, overlap = true, } },
    ["hands"] = { parry = { path = "sounds/parry/hand-to-hand-whack.wav", options = { volume = 1 } }, perfectParry = { path = "sounds/parry/hand-to-hand-perfect-whack.wav", options = { volume = 0.8, pitch = 0.9 }, overlap = false, } },
    ["lightarmor"] = { parry = { path = "Light Armor Hit", options = { volume = 1, } }, perfectParry = { path = "sounds/parry/perfect_parry_metal.wav", options = { volume = 0.85, pitch = 0.9 }, overlap = true, } },
    ["mediumarmor"] = { parry = { path = "Medium Armor Hit", options = { volume = 1, } }, perfectParry = { path = "sounds/parry/perfect_parry_metal.wav", options = { volume = 0.85, pitch = 0.8 }, overlap = true, } },
    ["heavyarmor"] = { parry = { path = "Heavy Armor Hit", options = { volume = 1, } }, perfectParry = { path = "sounds/parry/perfect_parry_metal.wav", options = { volume = 0.85, pitch = 0.75 }, overlap = true, } },
}

Constants.shieldMoveSpeedMultiplierMap = {
    ["heavyarmor"] = 0.55,
    ["mediumarmor"] = 0.65,
    ["lightarmor"] = 0.75,
}

Constants.gauntletParryModMap =
{
    ["heavyarmor"] = 0.5,
    ["mediumarmor"] = 0.3,
    ["lightarmor"] = 0.15,
}
Constants.shieldCategoryModMap =
{
    ["heavyarmor"] = 2.5,
    ["mediumarmor"] = 1.75,
    ["lightarmor"] = 1,
}


Constants.creatureBlackList = {
    "bm_riekling",
    "bm_riekling_be_unique1",
    "bm_riekling_be_unique2",
    "bm_riekling_be_unique3",
    "bm_riekling_be_unique4",
    "bm_riekling_be_unique5",
    "bm_riekling_dulk_unique",
    "bm_riekling_krish_uniqu",
    "bm_riekling_be_unique",
    "bm_riekling_boarmaster",
    "bm_riekling_st_unique",
    "bm_riekling_mounted",
    "goblin_grunt",
    "goblin_footsoldier",
    "goblin_officeruni",
    "ab_und_dwrvspectrewep",
    "ab_und_dwrvspectrewepf",
    "t_cyr_cre_gob_01",
    "t_cyr_cre_gobchf_01",
    "t_cyr_cre_gobskm_01",
    "t_cyr_und_wrth_01",
    "t_cyr_und_wrthfad_01",
    "t_dae_cre_seducdark_01",
    "t_dwe_cre_centarc_01",
    "centurion_projectile",
    "centurion_projectile_c",
    "t_dwe_cre_centarcml_01",
    "t_dwe_cre_centarcsh_01",
    "t_glb_cre_dreumow_01",
    "t_mw_cre_dreumow_01",
    "t_mw_cre_gobblind_01",
    "t_mw_cre_gobblind_02",
    "t_mw_cre_gobblind_03",
    "t_mw_cre_gobblind_04",
    "t_mw_cre_gobbrs_01",
    "t_mw_cre_gobbru_01",
    "t_mw_cre_gobchf_01",
    "t_mw_cre_gobshm_01",
    "t_mw_cre_gobskr_01",
    "t_mw_cre_gobthr_01",
    "t_mw_und_ancestorwep_01",
    "t_sky_cre_gobbrs_01",
    "t_sky_cre_gobbru_01",
    "t_sky_cre_gobchf_01",
    "t_sky_cre_gobshm_01",
    "t_sky_cre_gobskr_01",
    "t_sky_cre_gobthr_01",
    "t_tsa_cre_tsaesci_01",
    "t_tsa_cre_tsaesci_02",
    "t_tsa_cre_tsaesci _01", -- td has some bad creature ids. keeping both variants in case they fix them in the future
    "t_tsa_cre_tsaesci _02",
    "almalexia",
    "almalexia_warrior",
}


return Constants
