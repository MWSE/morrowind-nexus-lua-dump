---@omw-context local
local anim                     = require('openmw.animation')
local core                     = require('openmw.core')
local Constants                = {}

---@enum TRUE_ATTACK_TYPE
Constants.TRUE_ATTACK_TYPE     = {
    Chop = 0,
    Slash = 1,
    Thrust = 2,
}

Constants.readableAttackType   = {
    [0] = "chop",
    [1] = "slash",
    [2] = "thrust"
}

Constants.attackTypeByIndex    = {
    [0] = Constants.TRUE_ATTACK_TYPE.Chop,
    [1] = Constants.TRUE_ATTACK_TYPE.Slash,
    [2] = Constants.TRUE_ATTACK_TYPE.Thrust,
}

--For isPlaying checks
Constants.parryAnimations      = {
    "1hsupportedhighguard",
    "1hswhighguard",
    "2hswhighguard",
    "2haxebluntguard",
    "2hstaffspearguard",
    "h2hblock",
    "shieldraise",
}

Constants.h2hdodgeAnimations   = {
    "missdr",
    "missdl",
    "missdfwd",
    "missdfwdr",
    "missdfwdl",
    "missdbk",
    "missdbkr",
    "missdbkl",
    "dodgeturnleft",
    "dodgeturnright",
    "dodgeleanback",
}

Constants.armedDodgeAnimations = {
    "dodgeturnleft",
    "dodgeturnright",
    "dodgeleanback",
}

Constants.dodgeBlendMask       = anim.BLEND_MASK.Torso + anim.BLEND_MASK.LowerBody
Constants.dodgePriority        = anim.PRIORITY.Scripted

Constants.staggerAnimations    = {
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

Constants.attackAnimations     = {
    -- "attack1",
    -- "attack2",
    -- "attack3",
    -- "chop max attack",
    -- "chop min attack",
    -- "slash max attack",
    -- "slash min attack",
    -- "thrust max attack",
    -- "thrust min attack",
    -- "swimattack1",
    -- "swimattack2",
    -- "swimattack3",
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

Constants.attackEndKeys        = {
    -- "chop min hit",
    "chop hit",
    -- "slash min hit",
    "slash hit",
    -- "thrust min hit",
    "thrust hit",
    "unequip start",
    "unequip stop"
}

Constants.attackStartKeys      = {
    "chop min attack",
    "slash min attack",
    "thrust min attack",
    "chop max attack",
    "slash max attack",
    "thrust max attack",
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
        animationSpeed = 2.4074,
        moveSpeedMultiplier = 0.95,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 0',
        attackAnimationGroup = "weapononehand"
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
        animationSpeed = 2.4074,
        moveSpeedMultiplier = 0.85,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1',
        attackAnimationGroup = "weapononehand"
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
        animationSpeed = 2.333335,
        moveSpeedMultiplier = 0.75,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1',
        attackAnimationGroup = "weapontwohand"
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
        animationSpeed = 2.4074,
        moveSpeedMultiplier = 0.85,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1',
        attackAnimationGroup = "weapononehand"
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
        animationSpeed = 2.333335,
        moveSpeedMultiplier = 0.75,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1',
        attackAnimationGroup = "weapontwohand"
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
        animationSpeed = 2.333335,
        moveSpeedMultiplier = 0.75,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1',
        attackAnimationGroup = "weapontwowide"
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
        animationSpeed = 2.333335,
        moveSpeedMultiplier = 0.8,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 0',
        attackAnimationGroup = "weapontwowide"
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
        animationSpeed = 2.4074,
        moveSpeedMultiplier = 0.85,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1',
        attackAnimationGroup = "weapononehand"
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
        animationSpeed = 2.333335,
        moveSpeedMultiplier = 0.75,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Bip01 Parry Sparks 1',
        attackAnimationGroup = "weapontwohand"
    },
    [99] = {
        name = "handtohand",
        effectiveness = 0,
        baseEffectiveness = 1,
        mainSkillId = 'handtohand',
        secondarySkillId = 'handtohand',
        material = "hands", -- default material if not gauntlets
        animation = "h2hblock",
        priority = { [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted, [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted, },
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm,
        parryArc = 100,  -- degrees, to some extent representing reach with weapon type, and to some extent the size/coverage
        parryOffset = 0, -- how easy it is to bring the weapon to opposite side to parry
        animationSpeed = 2.4074,
        moveSpeedMultiplier = 1,
        vfxModel = 'meshes/e/spark.nif',
        vfxBone = 'Weapon Bone',
        attackAnimationGroup = "handtohand"
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
    animationSpeed = 1.66665,
    moveSpeedMultiplier = 0.65,
    vfxModel = 'meshes/e/spark.nif',
    vfxBone = 'Shield Bone',
    attackAnimationGroup = "weapononehand"
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

Constants.creatureWhiteList = {
    "vivec_god",
    "bm_hircine_huntaspect"
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
    "ab_und_dwrvspectrewep",
    "ab_und_dwrvspectrewepf",
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
    "t_mw_und_ancestorwep_01",
    "t_tsa_cre_tsaesci_01",
    "t_tsa_cre_tsaesci_02",
    "t_tsa_cre_tsaesci _01", -- td has some bad creature ids. keeping both variants in case they fix them in the future
    "t_tsa_cre_tsaesci _02",
    "almalexia",
    "pc_m1_cha_goldnets_gob1",
    "pc_m1_cha_goldnets_gob2",
    "pc_m1_cha_goldnets_gob3",
    "pc_m1_mg_cha4_goblin1",
    "pc_m1_mg_cha4_goblin5",
    "goblin_officeruni",
    "t_cyr_cre_gob_01",
    "t_cyr_cre_gobchf_01",
    "pc_m1_sc_goattrbls_gob1",
    "pc_m1_sc_goattrbls_gob2",
    "t_mw_cre_gobbrs_01",
    "t_mw_cre_gobbru_01",
    "t_sky_cre_gobbrs_01",
    "t_sky_cre_gobbru_01",
    "tr_m7_cre_gobmag_uni",
    "tr_m7_cre_gobmaggot_01",
    "tr_m7_cre_gobmaggot_02",
    "sky_qre_dse4_goba",
    "t_cyr_cre_gobchf_01",
    "t_mw_cre_gobchf_01",
    "t_sky_cre_gobchf_01",
    "tr_m7_cre_gobmag_chief",
    "tr_m7_cre_gobmaggot_03",
    "tr_m7_ns_arena_gobboss",
    "pc_m1_mg_cha4_goblin4",
    "t_sky_cre_gobthr_01",
    "t_mw_cre_gobthr_01",
    "tr_m7_cre_gobmaggot_06",
    "t_mw_cre_gobblind_01",
    "t_sky_cre_gobshm_01",
    "t_mw_cre_gobshm_01",
    "tr_m7_cre_gobmaggot_04",
    "t_mw_cre_gobblind_02",
    "tr_m7_kalk_goblinfollow",
    "t_mw_cre_gobblind_03",
    "t_mw_cre_gobblind_04",
    -- "almalexia_warrior",
    -- "goblin_grunt",
    -- "goblin_footsoldier",
    -- "t_mw_cre_gobskr_01",
    -- "t_cyr_cre_gobskm_01",
    -- "tr_m7_cre_gobmaggot_05",
    -- "tr_m7_ns_arena_gobreg",
    -- "tr_m7_ns_arena_gobr1eg",
    --BENEATH THE PERMAFROST
    "sch_FVFC1_sc_e1CrMum",
    "sch_FVFC1_sc_e1CrSkel",
    "sch_FVFC2_cr_BSpec2a",
    "sch_FVFC2_cr_BSpec2b",
    "sch_FVFC2_cr_BSpec4",
}


return Constants
