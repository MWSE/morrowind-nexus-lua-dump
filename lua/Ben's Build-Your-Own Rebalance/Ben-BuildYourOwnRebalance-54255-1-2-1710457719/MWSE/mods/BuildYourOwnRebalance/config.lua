local util = require("BuildYourOwnRebalance.util")

this = {}

local defaultMcmConfig = {
    shared = {
        modEnabled = true,
        loggingEnabled = false,
        detectBoundItemsByName = true,
        excludedItemIds = {
            -- ARMOR: Vanilla
            ["cephalopod_helm"] = true,
            ["mole_crab_helm"] = true,
            
            -- ARMOR: OAAB_Data
            ["AB_a_CephHelmOpen"] = true,
            
            -- CLOTHING: Tamriel_Data
            ["T_De_Uni_ClawGlove"] = true,
            
            -- WEAPONS: Vanilla
            ["azura_star_unique"] = true,
            ["BM nord leg"] = true,
            ["bm_ebonyarrow_s"] = true,
            ["stendar_hammer_unique"] = true,
            ["stendar_hammer_unique_x"] = true,
            
            -- WEAPONS: OAAB_Data
            ["AB_w_DwrvToolCrowbar"] = true,
            ["AB_w_ToolEbonyPick"] = true,
            ["AB_w_ToolFishingNet"] = true,
            
            -- WEAPONS: Tamriel_Data
            ["T_Com_Var_FishingNet_01"] = true,
            ["T_Cr_Goblin_Axe_01"] = true,
            ["T_Cr_Goblin_Axe_Poison"] = true,
            ["T_Cr_Goblin_Club_01"] = true,
            ["T_De_Ebony_Pickaxe_01"] = true,
            
            -- WEAPONS: More Deadly Morrowind Denizens
            ["mdmd_sanyonaxe"] = true,
            ["mdmd_THEGAMBLER"] = true,
        },
        boundItemIds = {
            -- ARMOR: Vanilla
            ["bound_boots"] = true,
            ["bound_cuirass"] = true,
            ["bound_gauntlet_left"] = true,
            ["bound_gauntlet_right"] = true,
            ["bound_shield"] = true,
            ["bound_helm"] = true,
            
            -- ARMOR: Magicka Expanded
            ["OJ_ME_BoundGreaves"] = true,
            ["OJ_ME_BoundPauldronLeft"] = true,
            ["OJ_ME_BoundPauldronRight"] = true,
            
            -- ARMOR: Tamriel_Data
            ["T_Com_Bound_Greaves_01"] = true,
            ["T_Com_Bound_PauldronL_01"] = true,
            ["T_Com_Bound_PauldronR_01"] = true,
            
            -- WEAPONS: Vanilla
            ["bound_battle_axe"] = true,
            ["bound_dagger"] = true,
            ["bound_longbow"] = true,
            ["bound_longsword"] = true,
            ["bound_mace"] = true,
            ["bound_spear"] = true,
            
            -- WEAPONS: Magicka Expanded
            ["OJ_ME_BoundClaymore"] = true,
            ["OJ_ME_BoundClub"] = true,
            ["OJ_ME_BoundDaiKatana"] = true,
            ["OJ_ME_BoundKatana"] = true,
            ["OJ_ME_BoundShortsword"] = true,
            ["OJ_ME_BoundStaff"] = true,
            ["OJ_ME_BoundTanto"] = true,
            ["OJ_ME_BoundWakizashi"] = true,
            ["OJ_ME_BoundWarAxe"] = true,
            ["OJ_ME_BoundWarhammer"] = true,
            
            -- WEAPONS: Tamriel_Data
            ["T_Com_Bound_WarAxe_01"] = true,
            ["T_Com_Bound_Warhammer_01"] = true,
        },
    },
    armor = {
        rebalanceEnabled = true,
        baseArmorSkill = 30, -- 10 to 100
        tierCount = 6, -- 2 to 20
        slot = {
            weight = { -- 0.1 to 10.0
                helm = 2,
                pauldron = 2,
                cuirass = 6,
                gauntlet = 1,
                greaves = 2,
                boots = 2,
                shield = 2,
            },
            enchant = { -- 0.0 to 50.0
                helm = 10,
                pauldron = 1,
                cuirass = 5,
                gauntlet = 5,
                greaves = 1,
                boots = 2,
                shield = 20,
            },
            health = { -- 0 to 500
                helm = 50,
                pauldron = 50,
                cuirass = 150,
                gauntlet = 25,
                greaves = 50,
                boots = 50,
                shield = 100,
            },
            value = { -- 0.0 to 10.0
                helm = 2,
                pauldron = 2,
                cuirass = 6,
                gauntlet = 1,
                greaves = 2,
                boots = 2,
                shield = 2,
            },
        },
        weightClass = {
            armorRating = { -- 0.0 to 10.0
                light = 2,
                medium = 3,
                heavy = 4,
            },
            enchant = { -- 0.0 to 10.0
                light = 2,
                medium = 3,
                heavy = 4,
            },
            health = { -- 0.0 to 10.0
                light = 2,
                medium = 3,
                heavy = 4,
            },
            value = { -- 0.0 to 10.0
                light = 2,
                medium = 3,
                heavy = 4,
            },
        },
        tier = {
            armorRating = { -- 0 to 100
                [1] = 10,
                [2] = 20,
                [3] = 40,
                [4] = 50,
                [5] = 60,
                [6] = 80,
            },
            weight = { -- 1.50 to 2.90
                [1] = 1.5,
                [2] = 1.5,
                [3] = 2.1,
                [4] = 2.4,
                [5] = 2.7,
                [6] = 2.7,
            },
            enchant = { -- 0.0 to 10.0
                [1] = 1,
                [2] = 1,
                [3] = 2,
                [4] = 2,
                [5] = 3,
                [6] = 3,
            },
            health = { -- 0.0 to 10.0
                [1] = 1,
                [2] = 1,
                [3] = 2,
                [4] = 3,
                [5] = 4,
                [6] = 5,
            },
            value = { -- 0 to 10000
                [1] = 4,
                [2] = 15,
                [3] = 200,
                [4] = 750,
                [5] = 3000,
                [6] = 10000,
            },
        },
        detectWeightClass = {
            searchTerms =
                "M:Imperial Chain\n"..
                "H:A_Shield_Imperial",
        },
        detectTier = {
            maxArmorRating = { -- 0 to 200
                light = {
                    [1] = 9,
                    [2] = 19,
                    [3] = 29,
                    [4] = 39,
                    [5] = 50,
                    [6] = 200,
                },
                medium = {
                    [1] = 11,
                    [2] = 29,
                    [3] = 39,
                    [4] = 49,
                    [5] = 60,
                    [6] = 200,
                },
                heavy = {
                    [1] = 14,
                    [2] = 39,
                    [3] = 54,
                    [4] = 69,
                    [5] = 80,
                    [6] = 200,
                },
            },
            searchTerms =
                "2:Orc Leather\n"..
                "2:Imperial Chain\n"..
                "3:Dark Brotherhood\n"..
                "3:Orc\n"..
                "3:Dreugh\n"..
                "3:Dwemer\n"..
                "3:Dwarven\n"..
                "3:Nordic Mail\n"..
                "4:Adamantium\n"..
                "4:Snow Bear\n"..
                "4:Ebony\n"..
                "4:Her Hand's\n"..
                "5:Glass\n"..
                "5:Native Ebony\n"..
                "1:AB_c_DwrvHat\n"..
                "2:A_Shield_Imperial\n"..
                "2:pc_a_guardarmorch\n"..
                "6:ebon_plate_cuirass_unique",
        },
        boundItem = {
            scaleWithLightArmorSkill = false,
            weightClass = "H", -- L, M, H
            tier = 5, -- 1 to 20
            armorRating = 80, -- 0 to 200
        },
        enchantedItem = {
            recalculateValue = false,
            valueMult = 1.20, -- 1.00 to 2.00
            valueScale = 1.00, -- 0.00 to 2.00
        },
    },
    clothing = {
        rebalanceEnabled = true,
        tierCount = 4, -- 2 to 20
        slot = {
            weight = { -- 0.0 to 10.0
                amulet = 1,
                ring = 0.1,
                shirt = 2,
                skirt = 2,
                pants = 2,
                belt = 1,
                glove = 1,
                shoes = 3,
                robe = 3,
            },
            enchant = { -- 0.0 to 50.0
                amulet = 15,
                ring = 15,
                shirt = 7.5,
                skirt = 7.5,
                pants = 7.5,
                belt = 5,
                glove = 5,
                shoes = 5,
                robe = 5,
            },
            value = { -- 0.0 to 50.0
                amulet = 15,
                ring = 15,
                shirt = 7.5,
                skirt = 7.5,
                pants = 7.5,
                belt = 5,
                glove = 5,
                shoes = 5,
                robe = 5,
            },
        },
        tier = {
            weight = { -- 0.0 to 10.0
                [1] = 1,
                [2] = 1,
                [3] = 1,
                [4] = 1,
            },
            enchant = { -- 0.0 to 20.0
                [1] = 0.1,
                [2] = 1,
                [3] = 4,
                [4] = 8,
            },
            value = { -- 0.0 to 100.0
                [1] = 0.2,
                [2] = 2,
                [3] = 8,
                [4] = 16,
            },
        },
        detectTier = {
            maxEnchant = { -- 0 to 200
                amulet = {
                    [1] = 6,
                    [2] = 30,
                    [3] = 90,
                    [4] = 200,
                },
                ring = {
                    [1] = 6,
                    [2] = 30,
                    [3] = 90,
                    [4] = 200,
                },
                shirt = {
                    [1] = 3,
                    [2] = 15,
                    [3] = 45,
                    [4] = 200,
                },
                skirt = {
                    [1] = 3,
                    [2] = 15,
                    [3] = 45,
                    [4] = 200,
                },
                pants = {
                    [1] = 3,
                    [2] = 15,
                    [3] = 45,
                    [4] = 200,
                },
                belt = {
                    [1] = 2,
                    [2] = 10,
                    [3] = 30,
                    [4] = 200,
                },
                glove = {
                    [1] = 2,
                    [2] = 10,
                    [3] = 30,
                    [4] = 200,
                },
                shoes = {
                    [1] = 2,
                    [2] = 10,
                    [3] = 30,
                    [4] = 200,
                },
                robe = {
                    [1] = 2,
                    [2] = 10,
                    [3] = 30,
                    [4] = 200,
                },
            },
            searchTerms =
                "1:Common\n"..
                "1:com\n"..
                "1:_cm_\n"..
                "2:Expensive\n"..
                "2:exp\n"..
                "2:_ep_\n"..
                "3:Extravagant\n"..
                "3:ext\n"..
                "3:_et_\n"..
                "4:Exquisite\n"..
                "4:exq\n"..
                "4:_ex_",
        },
        enchantedItem = {
            recalculateValue = false,
            valueMult = 10.0, -- 1.0 to 100.0
            valueScale = 1.00, -- 0.00 to 2.00
        },
        unenchantedItem = {
            excludeHighValueItems = true,
            maxValue = 500, -- 0 to 10000
        },
    },
    weapon = {
        rebalanceEnabled = true,
        defaultWeightClass = "M", -- L, M, H
        tierCount = 6, -- 2 to 20
        fixIsSilverFlag = true,
        subtypeCount = { -- 1 to 10
            shortBladeOneHand = 4,
            longBladeOneHand = 5,
            bluntOneHand = 2,
            axeOneHand = 1,
            spearTwoWide = 3,
            bluntTwoWide = 1,
            longBladeTwoClose = 2,
            bluntTwoClose = 1,
            axeTwoHand = 1,
            marksmanCrossbow = 1,
            marksmanBow = 2,
            bolt = 1,
            arrow = 1,
            marksmanThrown = 1,
        },
        subtype = {
            shortBladeOneHand = {
                [1] = {
                    displayName = "Dagger",
                    minDamage = 0.50, -- 0.00 to 1.00
                    chop = 1, -- 0.00 to 1.00
                    slash = 1, -- 0.00 to 1.00
                    thrust = 1, -- 0.00 to 1.00
                    bestAttack = "chop", -- chop, slash, thrust
                    
                    damage = 20, -- 0 to 100
                    speed = 2.5, -- 0.00 to 5.00
                    reach = 1, -- 0.00 to 5.00
                    weight = 3, -- 0.0 to 50.0
                    enchant = 2, -- 0.0 to 50.0
                    health = 600, -- 0 to 5000
                    value = 10, -- 0.0 to 100.0
                    
                    searchTerms = "Dagger", -- slash-delimited list
                    maxSpeed = 0, -- 0.00 to 5.00
                    maxReach = 0, -- 0.00 to 5.00
                    maxDamageTierZero = 2, -- 0 to 200
                    maxDamage = { -- 0 to 200
                        [1] = 5,
                        [2] = 8,
                        [3] = 11,
                        [4] = 14,
                        [5] = 16,
                        [6] = 200,
                    },
                },
                [2] = {
                    displayName = "Tanto",
                    minDamage = 0.33,
                    chop = 1,
                    slash = 1,
                    thrust = 1,
                    bestAttack = "chop",
                    
                    damage = 30,
                    speed = 2.5,
                    reach = 1,
                    weight = 6,
                    enchant = 4,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "Tanto",
                    maxSpeed = 5,
                    maxReach = 0,
                    maxDamageTierZero = 4,
                    maxDamage = {
                        [1] = 7,
                        [2] = 11,
                        [3] = 15,
                        [4] = 18,
                        [5] = 20,
                        [6] = 200,
                    },
                },
                [3] = {
                    displayName = "Wakizashi",
                    minDamage = 0.33,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.5,
                    bestAttack = "chop",
                    
                    damage = 32,
                    speed = 2.25,
                    reach = 1,
                    weight = 7,
                    enchant = 4,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "Wakizashi",
                    maxSpeed = 2.25,
                    maxReach = 0,
                    maxDamageTierZero = 6,
                    maxDamage = {
                        [1] = 12,
                        [2] = 16,
                        [3] = 21,
                        [4] = 26,
                        [5] = 30,
                        [6] = 200,
                    },
                },
                [4] = {
                    displayName = "Shortsword",
                    minDamage = 0.33,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.9,
                    bestAttack = "chop",
                    
                    damage = 34,
                    speed = 2,
                    reach = 1,
                    weight = 8,
                    enchant = 4,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "Shortsword/Short Sword",
                    maxSpeed = 2,
                    maxReach = 0,
                    maxDamageTierZero = 6,
                    maxDamage = {
                        [1] = 11,
                        [2] = 14,
                        [3] = 19,
                        [4] = 23,
                        [5] = 26,
                        [6] = 200,
                    },
                },
            },
            longBladeOneHand = {
                [1] = {
                    displayName = "Rapier",
                    minDamage = 0.17,
                    chop = 0.5,
                    slash = 0.5,
                    thrust = 1.0,
                    bestAttack = "thrust",
                    
                    damage = 36,
                    speed = 1.85,
                    reach = 1,
                    weight = 14,
                    enchant = 6,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "Rapier/Impaler",
                    maxSpeed = 0,
                    maxReach = 0,
                    maxDamageTierZero = 10,
                    maxDamage = {
                        [1] = 16,
                        [2] = 22,
                        [3] = 28,
                        [4] = 34,
                        [5] = 40,
                        [6] = 200,
                    },
                },
                [2] = {
                    displayName = "Katana",
                    minDamage = 0.17,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.5,
                    bestAttack = "chop",
                    
                    damage = 38,
                    speed = 1.7,
                    reach = 1,
                    weight = 15,
                    enchant = 6,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "Katana",
                    maxSpeed = 5,
                    maxReach = 0,
                    maxDamageTierZero = 11,
                    maxDamage = {
                        [1] = 18,
                        [2] = 23,
                        [3] = 30,
                        [4] = 37,
                        [5] = 44,
                        [6] = 200,
                    },
                },
                [3] = {
                    displayName = "Saber",
                    minDamage = 0.17,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.5,
                    bestAttack = "chop",
                    
                    damage = 40,
                    speed = 1.6,
                    reach = 1,
                    weight = 16,
                    enchant = 6,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "Saber/Scimitar",
                    maxSpeed = 1.4,
                    maxReach = 0,
                    maxDamageTierZero = 11,
                    maxDamage = {
                        [1] = 18,
                        [2] = 22,
                        [3] = 29,
                        [4] = 36,
                        [5] = 42,
                        [6] = 200,
                    },
                },
                [4] = {
                    displayName = "Longsword",
                    minDamage = 0.17,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.9,
                    bestAttack = "chop",
                    
                    damage = 42,
                    speed = 1.5,
                    reach = 1,
                    weight = 17,
                    enchant = 6,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "Longsword/Long Sword",
                    maxSpeed = 1.35,
                    maxReach = 0,
                    maxDamageTierZero = 11,
                    maxDamage = {
                        [1] = 18,
                        [2] = 23,
                        [3] = 30,
                        [4] = 37,
                        [5] = 44,
                        [6] = 200,
                    },
                },
                [5] = {
                    displayName = "Broadsword",
                    minDamage = 0.17,
                    chop = 1,
                    slash = 1,
                    thrust = 1,
                    bestAttack = "chop",
                    
                    damage = 44,
                    speed = 1.4,
                    reach = 1,
                    weight = 18,
                    enchant = 6,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "Broadsword",
                    maxSpeed = 1.25,
                    maxReach = 0,
                    maxDamageTierZero = 9,
                    maxDamage = {
                        [1] = 14,
                        [2] = 18,
                        [3] = 23,
                        [4] = 28,
                        [5] = 34,
                        [6] = 200,
                    },
                },
            },
            bluntOneHand = {
                [1] = {
                    displayName = "Club",
                    minDamage = 0.17,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.1,
                    bestAttack = "chop",
                    
                    damage = 40,
                    speed = 1.6,
                    reach = 1,
                    weight = 16,
                    enchant = 6,
                    health = 1200,
                    value = 20,
                    
                    searchTerms = "Club",
                    maxSpeed = 5,
                    maxReach = 0,
                    maxDamageTierZero = 2,
                    maxDamage = {
                        [1] = 5,
                        [2] = 6,
                        [3] = 8,
                        [4] = 10,
                        [5] = 12,
                        [6] = 200,
                    },
                },
                [2] = {
                    displayName = "Mace",
                    minDamage = 0.17,
                    chop = 1,
                    slash = 1,
                    thrust = 0.1,
                    bestAttack = "chop",
                    
                    damage = 44,
                    speed = 1.4,
                    reach = 1,
                    weight = 18,
                    enchant = 6,
                    health = 1200,
                    value = 20,
                    
                    searchTerms = "Mace",
                    maxSpeed = 1.3,
                    maxReach = 0,
                    maxDamageTierZero = 8,
                    maxDamage = {
                        [1] = 12,
                        [2] = 16,
                        [3] = 21,
                        [4] = 26,
                        [5] = 30,
                        [6] = 200,
                    },
                },
            },
            axeOneHand = {
                [1] = {
                    displayName = "War Axe",
                    minDamage = 0,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.1,
                    bestAttack = "chop",
                    
                    damage = 48,
                    speed = 1.25,
                    reach = 1,
                    weight = 20,
                    enchant = 6,
                    health = 800,
                    value = 20,
                    
                    searchTerms = "",
                    maxSpeed = 0,
                    maxReach = 0,
                    maxDamageTierZero = 11,
                    maxDamage = {
                        [1] = 18,
                        [2] = 23,
                        [3] = 30,
                        [4] = 37,
                        [5] = 44,
                        [6] = 200,
                    },
                },
            },
            spearTwoWide = {
                [1] = {
                    displayName = "Spear",
                    minDamage = 0.33,
                    chop = 0.1,
                    slash = 0.1,
                    thrust = 1,
                    bestAttack = "thrust",
                    
                    damage = 45,
                    speed = 1.6,
                    reach = 1.8,
                    weight = 14,
                    enchant = 8,
                    health = 1200,
                    value = 30,
                    
                    searchTerms = "Spear",
                    maxSpeed = 0,
                    maxReach = 1.8,
                    maxDamageTierZero = 10,
                    maxDamage = {
                        [1] = 16,
                        [2] = 21,
                        [3] = 28,
                        [4] = 34,
                        [5] = 40,
                        [6] = 200,
                    },
                },
                [2] = {
                    displayName = "Long Spear",
                    minDamage = 0.33,
                    chop = 0.1,
                    slash = 0.1,
                    thrust = 1,
                    bestAttack = "thrust",
                    
                    damage = 45,
                    speed = 1.45,
                    reach = 2.2,
                    weight = 16,
                    enchant = 8,
                    health = 1200,
                    value = 30,
                    
                    searchTerms = "Long Spear/Longspear",
                    maxSpeed = 0,
                    maxReach = 5,
                    maxDamageTierZero = 10,
                    maxDamage = {
                        [1] = 16,
                        [2] = 21,
                        [3] = 28,
                        [4] = 34,
                        [5] = 40,
                        [6] = 200,
                    },
                },
                [3] = {
                    displayName = "Halberd",
                    minDamage = 0.33,
                    chop = 1,
                    slash = 1,
                    thrust = 0.7,
                    bestAttack = "slash",
                    
                    damage = 48,
                    speed = 1.8,
                    reach = 1.8,
                    weight = 16,
                    enchant = 8,
                    health = 1200,
                    value = 30,
                    
                    searchTerms = "Halberd/Glaive/Long Axe",
                    maxSpeed = 0,
                    maxReach = 0,
                    maxDamageTierZero = 10,
                    maxDamage = {
                        [1] = 16,
                        [2] = 21,
                        [3] = 28,
                        [4] = 34,
                        [5] = 40,
                        [6] = 200,
                    },
                },
            },
            bluntTwoWide = {
                [1] = {
                    displayName = "Staff",
                    minDamage = 0.33,
                    chop = 1,
                    slash = 1,
                    thrust = 0.7,
                    bestAttack = "slash",
                    
                    damage = 16,
                    speed = 1.8,
                    reach = 1.8,
                    weight = 8,
                    enchant = 40,
                    health = 600,
                    value = 10,
                    
                    searchTerms = "",
                    maxSpeed = 0,
                    maxReach = 0,
                    maxDamageTierZero = 4,
                    maxDamage = {
                        [1] = 6,
                        [2] = 9,
                        [3] = 12,
                        [4] = 14,
                        [5] = 16,
                        [6] = 200,
                    },
                },
            },
            longBladeTwoClose = {
                [1] = {
                    displayName = "Dai-katana",
                    minDamage = 0.08,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.5,
                    bestAttack = "chop",
                    
                    damage = 60,
                    speed = 1.5,
                    reach = 1,
                    weight = 20,
                    enchant = 8,
                    health = 1200,
                    value = 30,
                    
                    searchTerms = "Dai-katana/Daikatana",
                    maxSpeed = 5,
                    maxReach = 0,
                    maxDamageTierZero = 15,
                    maxDamage = {
                        [1] = 25,
                        [2] = 31,
                        [3] = 40,
                        [4] = 50,
                        [5] = 60,
                        [6] = 200,
                    },
                },
                [2] = {
                    displayName = "Claymore",
                    minDamage = 0.08,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.9,
                    bestAttack = "chop",
                    
                    damage = 66,
                    speed = 1.3,
                    reach = 1,
                    weight = 23,
                    enchant = 8,
                    health = 1200,
                    value = 30,
                    
                    searchTerms = "Claymore",
                    maxSpeed = 1.25,
                    maxReach = 0,
                    maxDamageTierZero = 15,
                    maxDamage = {
                        [1] = 25,
                        [2] = 31,
                        [3] = 40,
                        [4] = 50,
                        [5] = 60,
                        [6] = 200,
                    },
                },
            },
            bluntTwoClose = {
                [1] = {
                    displayName = "Warhammer",
                    minDamage = 0,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.1,
                    bestAttack = "chop",
                    
                    damage = 72,
                    speed = 1.15,
                    reach = 1,
                    weight = 26,
                    enchant = 8,
                    health = 1800,
                    value = 30,
                    
                    searchTerms = "",
                    maxSpeed = 0,
                    maxReach = 0,
                    maxDamageTierZero = 14,
                    maxDamage = {
                        [1] = 29,
                        [2] = 36,
                        [3] = 48,
                        [4] = 59,
                        [5] = 70,
                        [6] = 200,
                    },
                },
            },
            axeTwoHand = {
                [1] = {
                    displayName = "Battle Axe",
                    minDamage = 0,
                    chop = 1,
                    slash = 0.9,
                    thrust = 0.1,
                    bestAttack = "chop",
                    
                    damage = 80,
                    speed = 1,
                    reach = 1,
                    weight = 30,
                    enchant = 8,
                    health = 1200,
                    value = 30,
                    
                    searchTerms = "",
                    maxSpeed = 0,
                    maxReach = 0,
                    maxDamageTierZero = 20,
                    maxDamage = {
                        [1] = 33,
                        [2] = 41,
                        [3] = 54,
                        [4] = 67,
                        [5] = 80,
                        [6] = 200,
                    },
                },
            },
            marksmanCrossbow = {
                [1] = {
                    displayName = "Crossbow",
                    minDamage = 1,
                    chop = 1, -- hidden
                    slash = 0, -- hidden
                    thrust = 0, -- hidden
                    bestAttack = "chop", -- hidden
                    
                    damage = 50,
                    speed = 1, -- hidden
                    reach = 1, -- hidden
                    weight = 10,
                    enchant = 6,
                    health = 800,
                    value = 30,
                    
                    searchTerms = "",
                    maxSpeed = 0,
                    maxReach = 0, -- hidden
                    maxDamageTierZero = 9,
                    maxDamage = {
                        [1] = 19,
                        [2] = 23,
                        [3] = 30,
                        [4] = 38,
                        [5] = 45,
                        [6] = 200,
                    },
                },
            },
            marksmanBow = {
                [1] = {
                    displayName = "Short Bow",
                    minDamage = 0,
                    chop = 1, -- hidden
                    slash = 0, -- hidden
                    thrust = 0, -- hidden
                    bestAttack = "chop", -- hidden
                    
                    damage = 54,
                    speed = 1, -- hidden
                    reach = 1, -- hidden
                    weight = 4,
                    enchant = 6,
                    health = 800,
                    value = 30,
                    
                    searchTerms = "Short Bow/Shortbow",
                    maxSpeed = 0,
                    maxReach = 0, -- hidden
                    maxDamageTierZero = 9,
                    maxDamage = {
                        [1] = 19,
                        [2] = 23,
                        [3] = 30,
                        [4] = 38,
                        [5] = 45,
                        [6] = 200,
                    },
                },
                [2] = {
                    displayName = "Long Bow",
                    minDamage = 0,
                    chop = 1, -- hidden
                    slash = 0, -- hidden
                    thrust = 0, -- hidden
                    bestAttack = "chop", -- hidden
                    
                    damage = 60,
                    speed = 1, -- hidden
                    reach = 1, -- hidden
                    weight = 8,
                    enchant = 6,
                    health = 800,
                    value = 30,
                    
                    searchTerms = "Long Bow/Longbow",
                    maxSpeed = 5,
                    maxReach = 0, -- hidden
                    maxDamageTierZero = 11,
                    maxDamage = {
                        [1] = 21,
                        [2] = 26,
                        [3] = 34,
                        [4] = 42,
                        [5] = 50,
                        [6] = 200,
                    },
                },
            },
            bolt = {
                [1] = {
                    displayName = "Bolt",
                    minDamage = 1,
                    chop = 1, -- hidden
                    slash = 0, -- hidden
                    thrust = 0, -- hidden
                    bestAttack = "chop", -- hidden
                    
                    damage = 10,
                    speed = 1, -- hidden
                    reach = 1, -- hidden
                    weight = 0.1,
                    enchant = 1,
                    health = 10, -- hidden
                    value = 0.2,
                    
                    searchTerms = "",
                    maxSpeed = 0,
                    maxReach = 0, -- hidden
                    maxDamageTierZero = 0,
                    maxDamage = {
                        [1] = 3,
                        [2] = 4,
                        [3] = 7,
                        [4] = 10,
                        [5] = 15,
                        [6] = 200,
                    },
                },
            },
            arrow = {
                [1] = {
                    displayName = "Arrow",
                    minDamage = 0,
                    chop = 1, -- hidden
                    slash = 0, -- hidden
                    thrust = 0, -- hidden
                    bestAttack = "chop", -- hidden
                    
                    damage = 12,
                    speed = 1, -- hidden
                    reach = 1, -- hidden
                    weight = 0.1,
                    enchant = 1,
                    health = 10, -- hidden
                    value = 0.2,
                    
                    searchTerms = "",
                    maxSpeed = 0,
                    maxReach = 0, -- hidden
                    maxDamageTierZero = 0,
                    maxDamage = {
                        [1] = 3,
                        [2] = 4,
                        [3] = 7,
                        [4] = 10,
                        [5] = 15,
                        [6] = 200,
                    },
                },
            },
            marksmanThrown = {
                [1] = {
                    displayName = "Thrown",
                    minDamage = 0,
                    chop = 1, -- hidden
                    slash = 0, -- hidden
                    thrust = 0, -- hidden
                    bestAttack = "chop", -- hidden
                    
                    damage = 24,
                    speed = 1, -- hidden
                    reach = 1, -- hidden
                    weight = 0.2,
                    enchant = 2,
                    health = 20, -- hidden
                    value = 0.4,
                    
                    searchTerms = "",
                    maxSpeed = 0,
                    maxReach = 0, -- hidden
                    maxDamageTierZero = 0,
                    maxDamage = {
                        [1] = 3,
                        [2] = 4,
                        [3] = 7,
                        [4] = 10,
                        [5] = 15,
                        [6] = 200,
                    },
                },
            },
        },
        weightClass = {
            damage = { -- 0.0 to 10.0
                light = 0.8,
                medium = 0.9,
                heavy = 1.0,
            },
            weight = { -- 0.0 to 10.0
                light = 0.5,
                medium = 1.0,
                heavy = 1.5,
            },
            enchant = { -- 0.0 to 10.0
                light = 0.5,
                medium = 1.0,
                heavy = 1.5,
            },
            health = { -- 0.0 to 10.0
                light = 0.5,
                medium = 1.0,
                heavy = 1.5,
            },
            value = { -- 0.0 to 10.0
                light = 0.5,
                medium = 1.0,
                heavy = 1.5,
            },
        },
        tier = {
            damage = { -- 0.00 to 2.00
                [1] = 0.4,
                [2] = 0.5,
                [3] = 0.67,
                [4] = 0.83,
                [5] = 1,
                [6] = 1.52,
            },
            weight = { -- 0.0 to 10.0
                [1] = 1,
                [2] = 1.2,
                [3] = 1.4,
                [4] = 1.6,
                [5] = 1.8,
                [6] = 2,
            },
            enchant = { -- 0.0 to 10.0
                [1] = 1,
                [2] = 1,
                [3] = 1.5,
                [4] = 1.5,
                [5] = 2,
                [6] = 2,
            },
            health = { -- 0.0 to 10.0
                [1] = 1,
                [2] = 1.5,
                [3] = 2,
                [4] = 3,
                [5] = 4,
                [6] = 5,
            },
            value = { -- 0 to 10000
                [1] = 2,
                [2] = 8,
                [3] = 100,
                [4] = 400,
                [5] = 1500,
                [6] = 5000,
            },
        },
        detectWeightClass = {
            searchTerms =
                "L:Corkbulb\n"..
                "L:Chitin\n"..
                "L:Dreugh\n"..
                "L:Glass\n"..
                "L:Crystal\n"..
                "H:Orc\n"..
                "H:Ebony\n"..
                "H:Daedric\n"..
                "M:daedric_scourge_unique\n"..
                "M:ebony_bow_auriel\n"..
                "M:Gravedigger",
        },
        detectTier = {
            searchTerms =
                "1:Ashlander Glass\n"..
                "1:Corkbulb\n"..
                "1:Iron\n"..
                "2:Chitin\n"..
                "2:Steel\n"..
                "2:Silver\n"..
                "2:Imperial\n"..
                "2:Nordic\n"..
                "2:Bonemold\n"..
                "2:Huntsman\n"..
                "2:Goblin\n"..
                "2:Riekling\n"..
                "3:Dwarven\n"..
                "3:Dwemer\n"..
                "3:Nordic Silver\n"..
                "3:Nordic_Silver\n"..
                "3:NordicSilver\n"..
                "3:Berserker Silver\n"..
                "3:Nord_\n"..
                "3:Orc\n"..
                "4:Dreugh\n"..
                "4:Adamantium\n"..
                "4:Sixth House\n"..
                "4:Ebony\n"..
                "5:Glass\n"..
                "5:Crystal\n"..
                "5:Stalhrim\n"..
                "5:Daedric\n"..
                "1:riekling sword_rusted\n"..
                "2:spiked club\n"..
                "3:ashglass\n"..
                "6:daedric_scourge_unique\n"..
                "6:ebony_bow_auriel\n"..
                "6:Gravedigger\n"..
                "6:T_Dae_UNI_EbonyBlade",
        },
        ignoresNormalWeaponResistance = {
            minTier = 3, -- 1 to 20
            includeSilver = true,
            includeEnchanted = true,
        },
        boundItem = {
            weightClass = "H", -- L, M, H
            tier = 5, -- 1 to 20
        },
        enchantedItem = {
            recalculateValue = false,
            valueMult = 1.20, -- 1.00 to 2.00
            valueScale = 1.00, -- 0.00 to 2.00
        },
    },
    unarmored = {
        rebalanceEnabled = true,
        armorRating = 60, -- 0 to 200
    },
    condition = {
        fixItemHealthOverflow = true,
        repairDamagedItems = false,
    },
}

local staticConfig = {
    shared = {
        boundItemSearchPattern = "^[bB][oO][uU][nN][dD] ",
    },
    armor = {
        gameSettings = {
            [tes3.gmst.fLightMaxMod] = 0.295,
            [tes3.gmst.fMedMaxMod] = 0.595,
        },
        weightClass = {
            weight = {
                light = 1,
                medium = 2,
                heavy = 4,
            },
        },
    },
    weapon = {
        isSilverSearchPatterns = {
            ["[sS][iI][lL][vV][eE][rR]"] = true,
        },
    },
    unarmored = {
        gameSettings = {
            [tes3.gmst.fUnarmoredBase1] = 0.1,
        },
    },
}

local restartRequiredConfig = nil

local gameConfig = {} -- all of the above configs merged into one table

local gameConfigUpdated = { -- onLoaded events need to re-run if config changed
    armor = false,
    unarmored = false,
    clothing = false,
    weapon = false,
}

local configName = "BuildYourOwnRebalance"

local function updateGameConfig(mcmConfig)
    
    gameConfig.shared.boundItemIds = nil
    util.deepMerge(gameConfig, mcmConfig)
    
    gameConfig.shared.excludedItemIds = nil
    util.deepMerge(gameConfig, restartRequiredConfig)
    
    gameConfig.armor.gameSettings[tes3.gmst.iBaseArmorSkill] = mcmConfig.armor.baseArmorSkill
    gameConfig.armor.gameSettings[tes3.gmst.iBootsWeight] = mcmConfig.armor.slot.weight.boots * 10
    gameConfig.armor.gameSettings[tes3.gmst.iCuirassWeight] = mcmConfig.armor.slot.weight.cuirass * 10
    gameConfig.armor.gameSettings[tes3.gmst.iGauntletWeight] = mcmConfig.armor.slot.weight.gauntlet * 10
    gameConfig.armor.gameSettings[tes3.gmst.iGreavesWeight] = mcmConfig.armor.slot.weight.greaves * 10
    gameConfig.armor.gameSettings[tes3.gmst.iHelmWeight] = mcmConfig.armor.slot.weight.helm * 10
    gameConfig.armor.gameSettings[tes3.gmst.iPauldronWeight] = mcmConfig.armor.slot.weight.pauldron * 10
    gameConfig.armor.gameSettings[tes3.gmst.iShieldWeight] = mcmConfig.armor.slot.weight.shield * 10
    
    gameConfig.unarmored.gameSettings[tes3.gmst.fUnarmoredBase2] = mcmConfig.unarmored.armorRating * 0.001
    
    gameConfigUpdated.armor = true
    gameConfigUpdated.unarmored = true
    gameConfigUpdated.clothing = true
    gameConfigUpdated.weapon = true
    
end

this.saveMcmConfig = function(newConfig)
    
    for key, value in pairs(newConfig.shared.excludedItemIds) do
        if value == false then newConfig.shared.excludedItemIds[key] = nil end
    end
    
    for key, value in pairs(newConfig.shared.boundItemIds) do
        if value == false then newConfig.shared.boundItemIds[key] = nil end
    end
    
    mwse.saveConfig(configName, newConfig)
    updateGameConfig(newConfig)
    
end

local function updateRestartRequiredConfig(mcmConfig)
    
    if restartRequiredConfig ~= nil then return end
    
    restartRequiredConfig = {
        shared = {
            modEnabled = mcmConfig.shared.modEnabled,
            excludedItemIds = mcmConfig.shared.excludedItemIds,
        },
        armor = {
            rebalanceEnabled = mcmConfig.armor.rebalanceEnabled,
            tierCount = mcmConfig.armor.tierCount,
        },
        clothing = {
            rebalanceEnabled = mcmConfig.clothing.rebalanceEnabled,
            tierCount = mcmConfig.clothing.tierCount,
            unenchantedItem = {
                excludeHighValueItems = mcmConfig.clothing.unenchantedItem.excludeHighValueItems,
                maxValue = mcmConfig.clothing.unenchantedItem.maxValue,
            },
        },
        weapon = {
            rebalanceEnabled = mcmConfig.weapon.rebalanceEnabled,
            tierCount = mcmConfig.weapon.tierCount,
            subtypeCount = util.deepCopy(mcmConfig.weapon.subtypeCount),
            subtype = {},
        },
    }
    
    for weaponType, subtypes in pairs(mcmConfig.weapon.subtype) do
        
        restartRequiredConfig.weapon.subtype[weaponType] = {}
        
        for subtype, subtypeTable in pairs(subtypes) do
            
            restartRequiredConfig.weapon.subtype[weaponType][subtype] = {
                maxDamageTierZero = subtypeTable.maxDamageTierZero,
            }
            
        end
        
    end
    
end

local function updateDependentSettings(mcmConfig)
    
    mcmConfig.armor.boundItem.tier = util.clamp(mcmConfig.armor.boundItem.tier, 1, mcmConfig.armor.tierCount)
    mcmConfig.weapon.boundItem.tier = util.clamp(mcmConfig.weapon.boundItem.tier, 1, mcmConfig.weapon.tierCount)
    mcmConfig.weapon.ignoresNormalWeaponResistance.minTier = util.clamp(mcmConfig.weapon.ignoresNormalWeaponResistance.minTier, 1, mcmConfig.weapon.tierCount)
    
end

local function restoreAllOrNothingTables(mcmConfig, mcmConfig_AllOrNothingTables)
    
    if mcmConfig_AllOrNothingTables.shared.excludedItemIds ~= nil then
        mcmConfig.shared.excludedItemIds = mcmConfig_AllOrNothingTables.shared.excludedItemIds
    end
    
    if mcmConfig_AllOrNothingTables.shared.boundItemIds ~= nil then
        mcmConfig.shared.boundItemIds = mcmConfig_AllOrNothingTables.shared.boundItemIds
    end
    
end

local function saveAllOrNothingTables(mcmConfig)
    
    local mcmConfig_AllOrNothingTables = {
        shared = {},
    }
    
    if mcmConfig.shared ~= nil and type(mcmConfig.shared.excludedItemIds) == "table" then
        mcmConfig_AllOrNothingTables.shared.excludedItemIds = mcmConfig.shared.excludedItemIds
        mcmConfig.shared.excludedItemIds = nil
    end
    
    if mcmConfig.shared ~= nil and type(mcmConfig.shared.boundItemIds) == "table" then
        mcmConfig_AllOrNothingTables.shared.boundItemIds = mcmConfig.shared.boundItemIds
        mcmConfig.shared.boundItemIds = nil
    end
    
    return mcmConfig_AllOrNothingTables
    
end

local function updateDefaultWeaponTiersAndSubtypes(mcmConfig)
    
    local tierCount = defaultMcmConfig.weapon.tierCount
    
    if mcmConfig.weapon ~= nil then
        
        tierCount = util.getNumber(
            mcmConfig.weapon.tierCount,
            defaultMcmConfig.weapon.tierCount)
        
    end
    
    local tierTable = {}
    
    for tier = 1, tierCount do
        tierTable[tier] = 0
    end
    
    for stat, _ in pairs(defaultMcmConfig.weapon.tier) do
        
        local target = defaultMcmConfig.weapon.tier[stat]
        
        util.deepRemoveMissingKeys(target, tierTable)
        util.deepMergeWhenNil(target, tierTable)
        
    end
    
    --------------------------------------------------
    
    local defaultSubtype = {
        displayName = "",
        minDamage = 0,
        chop = 0,
        slash = 0,
        thrust = 0,
        bestAttack = "chop",
        
        damage = 0,
        speed = 0,
        reach = 0,
        weight = 0,
        enchant = 0,
        health = 0,
        value = 0,
        
        searchTerms = "",
        maxSpeed = 0,
        maxReach = 0,
        maxDamageTierZero = 0,
        maxDamage = tierTable,
    }
    
    for weaponType, _ in pairs(defaultMcmConfig.weapon.subtype) do
        
        local subtypeCount = defaultMcmConfig.weapon.subtypeCount[weaponType]
        
        if mcmConfig.weapon ~= nil
        and mcmConfig.weapon.subtypeCount ~= nil then
            
            subtypeCount = util.getNumber(
                mcmConfig.weapon.subtypeCount[weaponType],
                defaultMcmConfig.weapon.subtypeCount[weaponType])
            
        end
        
        local subtypeTable = {}
        
        for subtype = 1, subtypeCount do
            subtypeTable[subtype] = util.deepCopy(defaultSubtype)
        end
        
        local target = defaultMcmConfig.weapon.subtype[weaponType]
        
        util.deepRemoveMissingKeys(target, subtypeTable)
        util.deepMergeWhenNil(target, subtypeTable)
        
    end
    
end

local function updateDefaultClothingTiers(mcmConfig)
    
    local tierCount = defaultMcmConfig.clothing.tierCount
    
    if mcmConfig.clothing ~= nil then
        
        tierCount = util.getNumber(
            mcmConfig.clothing.tierCount,
            defaultMcmConfig.clothing.tierCount)
        
    end
    
    local tierTable = {}
    
    for tier = 1, tierCount do
        tierTable[tier] = 0
    end
    
    for stat, _ in pairs(defaultMcmConfig.clothing.tier) do
        
        local target = defaultMcmConfig.clothing.tier[stat]
        
        util.deepRemoveMissingKeys(target, tierTable)
        util.deepMergeWhenNil(target, tierTable)
        
    end
    
    for slot, _ in pairs(defaultMcmConfig.clothing.detectTier.maxEnchant) do
        
        local target = defaultMcmConfig.clothing.detectTier.maxEnchant[slot]
        
        util.deepRemoveMissingKeys(target, tierTable)
        util.deepMergeWhenNil(target, tierTable)
        
    end
    
end

local function updateDefaultArmorTiers(mcmConfig)
    
    local tierCount = defaultMcmConfig.armor.tierCount
    
    if mcmConfig.armor ~= nil then
        
        tierCount = util.getNumber(
            mcmConfig.armor.tierCount,
            defaultMcmConfig.armor.tierCount)
        
    end
    
    local tierTable = {}
    
    for tier = 1, tierCount do
        tierTable[tier] = 0
    end
    
    for stat, _ in pairs(defaultMcmConfig.armor.tier) do
        
        local target = defaultMcmConfig.armor.tier[stat]
        
        util.deepRemoveMissingKeys(target, tierTable)
        util.deepMergeWhenNil(target, tierTable)
        
    end
    
    for weightClass, _ in pairs(defaultMcmConfig.armor.detectTier.maxArmorRating) do
        
        local target = defaultMcmConfig.armor.detectTier.maxArmorRating[weightClass]
        
        util.deepRemoveMissingKeys(target, tierTable)
        util.deepMergeWhenNil(target, tierTable)
        
    end
    
end

this.loadMcmConfig = function()
    
    local mcmConfig = mwse.loadConfig(configName, {})
    local mcmConfig_AllOrNothingTables = saveAllOrNothingTables(mcmConfig)
    
    updateDefaultArmorTiers(mcmConfig)
    updateDefaultClothingTiers(mcmConfig)
    updateDefaultWeaponTiersAndSubtypes(mcmConfig)
    
    util.deepRemoveMissingKeys(mcmConfig, defaultMcmConfig)
    util.deepMergeWhenNil(mcmConfig, defaultMcmConfig)
    
    restoreAllOrNothingTables(mcmConfig, mcmConfig_AllOrNothingTables)
    updateDependentSettings(mcmConfig)
    updateRestartRequiredConfig(mcmConfig)
    
    return mcmConfig
    
end

this.getDefaultMcmConfig = function ()
    return defaultMcmConfig
end

this.getGameConfig = function()
    return gameConfig
end

this.getGameConfigUpdated = function()
    return gameConfigUpdated
end

this.eventPriority = {
    modConfigReady = {
        mcm = 0,
    },
    initialized = {
        armor = -11,
        clothing = -12,
        weapon = -13,
        unarmored = -14,
        condition = -15,
    },
    load = {
        condition = 0,
    },
    loaded = {
        armor = -11,
        clothing = -12,
        weapon = -13,
        unarmored = -14,
        condition = -15,
    },
    cellActivated = {
        condition = -10,
    },
    damage = {
        weapon = -10,
    },
}

util.deepMerge(gameConfig, staticConfig)
updateGameConfig(this.loadMcmConfig())

return this
