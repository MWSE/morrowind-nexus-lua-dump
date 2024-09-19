local common = require("mer.fishing.common")
local logger = common.createLogger("Integrations - loot")
local Interop = require("mer.fishing")

---@class Fishing.Integration.LootConfig.FishTypeDefaults : Fishing.FishType
---@field baseId? any

---@class Fishing.Integration.LootConfig
---@field defaults Fishing.Integration.LootConfig.FishTypeDefaults
---@field types Fishing.FishType.new.params[]

---@class Fishing.Integration.Loots
---@field common Fishing.Integration.LootConfig
---@field uncommon Fishing.Integration.LootConfig
---@field rare Fishing.Integration.LootConfig
---@field legendary Fishing.Integration.LootConfig
local loots = {
    common = {
        defaults = {
            size = 0.5,
            speed = 10,
            difficulty = 1,
            class = "loot",
            habitat = {},
        },
        types = {
            {
                baseId = "ashfall_firewood",
                variants = {
                    "ashfall_flint",
                    "ashfall_stone"
                }
            },
            {
                baseId = "AB_Key_Junk",
                totalPopulation = 1,
            },
            {
                baseId = "misc_com_basket_01",
                variants = {
                    "misc_com_basket_02",
                    "misc_de_basket_01"
                }
            },
            {
                baseId = "misc_com_tankard_01",
                variants = {
                    "misc_de_tankard_01"
                }

            },
            {
                baseId = "misc_com_wood_fork",
                variants = {
                    "misc_com_wood_knife",
                    "misc_com_wood_spoon_01"
                }
            },
            {
                baseId = "misc_com_wood_cup_01",
                variants = {
                    "misc_com_wood_cup_02",
                    "ashfall_cup_01",
                    "ashfall_bowl_01",

                }
            },
            {
                baseId = "misc_com_bottle_01",
                variants = {
                    "misc_com_bottle_02",
                    "misc_com_bottle_03",
                    "misc_com_bottle_04",
                    "misc_com_bottle_05",
                    "misc_com_bottle_06",
                    "misc_com_bottle_07",
                    "misc_com_bottle_08",
                    "misc_com_bottle_09",
                    "misc_com_bottle_10",
                    "misc_com_bottle_11",
                    "misc_com_bottle_12",
                    "misc_com_bottle_13",
                    "misc_com_bottle_14",
                    "misc_com_bottle_15",
                }
            },
            { baseId = "misc_de_bowl_01" },
            { baseId = "misc_dwrv_gear00" },
            {
                baseId = "misc_flask_01",
                variants = {
                    "misc_flask_02"
                }
            },
            {
                baseId = "ingred_muck_01",
                variants = {
                    "ingred_scales_01",
                    "ingred_bc_spore_pod",
                    "ingred_chokeweed_01",
                    "ingred_bittergreen_petals_01",
                    "ingred_dreugh_wax_01",
                    "ingred_red_lichen_01",

                }
            },
            { baseId = "misc_dwrv_coin00" },
            {
                baseId = "AB_Misc_BkRuinedFolio",
                variants = {
                    "AB_Misc_BkRuinedOctavo01",
                    "AB_Misc_BkRuinedOctavo02",
                    "AB_Misc_BkRuinedQuarto",
                }
            },
            { baseId = "AB_Misc_Bone" },
            { baseId = "AB_Misc_PurseCoin" },
            {
                baseId = "common_ring_01",
                variants = {
                    "ashfall_wood_ring_01",
                    "common_ring_02",
                    "common_ring_03",
                    "AB_c_CommonRing01",
                    "AB_c_CommonRing02"
                }
            },
            {
                baseId = "common_amulet_01",
                variants = {
                    "ashfall_stone_am_01",
                    "common_amulet_02",
                    "common_amulet_03",
                    "common_amulet_04",
                    "common_amulet_05",
                    "AB_c_CommonAmulet01",
                    "AB_c_CommonAmulet02"
                }
            },
            { baseId = "chitin throwing star" },
            { baseId = "chitin dagger" },
            { baseId = "ingred_pearl_01" },
        }
    },
    uncommon = {
        defaults = {
            size = 0.5,
            speed = 10,
            difficulty = 1,
            class = "loot",
            habitat = {},
        },
        types = {
            { baseId = "AB_Misc_HairBrush" },
            { baseId = "Misc_Quill" },
            { baseId = "mer_fishing_pole_01" },
            { baseId = "mer_fishing_net" },
            { baseId = "Misc_SoulGem_Petty" },
            { baseId = "misc_skull00" },
            { baseId = "misc_de_drum_01" },
            { baseId = "AB_Misc_Abacus" },
            {
                baseId = "AB_Misc_ComPaintBrush01",
                variants = {
                    "AB_Misc_ComPaintBrush02",
                }
            },
            { baseId = "AB_Misc_DiceSingle" },
            { baseId = "AB_Misc_Waterskin" },
            { baseId = "AB_Mus_AshlFlute" },
            { baseId = "netch_leather_boots" },
            {
                baseId = "common_shoes_01",
                variants = {
                    "common_shoes_02",
                    "common_shoes_03",
                    "common_shoes_04",
                    "common_shoes_05"
                }
            },
            { baseId = "AB_w_ChitinSickle" },
            { baseId = "AB_w_CookKnifeDinner" },
            { baseId = "steel dagger" },
            {
                baseId = "gondolier_helm",
                habitat = {
                    cells = { "Vivec" }
                }
            },
            {
                baseId = "expensive_ring_01",
                variants = {
                    "ashfall_wood_ring_02",
                    "expensive_ring_02",
                    "expensive_ring_03",
                    "AB_c_ExpensiveRing01",
                    "AB_c_ExpensiveRing02",
                    "AB_c_ExpensiveRing03",
                }
            },
            {
                baseId = "expensive_amulet_01",
                variants = {
                    "ashfall_stone_am_02",
                    "expensive_amulet_02",
                    "expensive_amulet_03",
                    "AB_c_DwemerAmuletClock",
                    "AB_c_ExpensiveAmulet01"
                }
            },
        }
    },
    rare = {
        defaults = {
            size = 0.5,
            speed = 70,
            difficulty = 1,
            class = "loot",
            habitat = {},
        },
        types = {
            { baseId = "ashfall_crabpot_02_m" },
            { baseId = "misc_de_muck_shovel_01" },
            { baseId = "misc_6th_ash_statue_01" },
            {
                baseId = "misc_de_lute_01",
                totalPopulation = 1
            },
            {
                baseId = "AB_Misc_ComCard01",
                variants = {
                    "AB_Misc_ComCard02",
                    "AB_Misc_ComCard03",
                    "AB_Misc_ComCard04",
                    "AB_Misc_ComCard05",
                    "AB_Misc_ComCard06",
                    "AB_Misc_ComCard07",
                    "AB_Misc_ComCard08",
                    "AB_Misc_ComCard09",
                    "AB_Misc_ComCard10",
                    "AB_Misc_ComCard11",
                    "AB_Misc_ComCard12",
                }
            },
            {
                baseId = "AB_Misc_ComCardDeck01",
                variants = {
                    "AB_Misc_ComCardDeck02",
                },
                totalPopulation = 1
            },
            { baseId = "AB_Misc_HairSilverComb" },
            {
                baseId = "AB_IngMine_BlackPearl_01",
                variants = {
                    "AB_IngMine_GoldPearl_01",
                },
                totalPopulation = 1
            },
            { baseId = "chitin boots" },
            { baseId = "mole_crab_helm" },
            { baseId = "glass throwing star" },
            { baseId = "dreugh club" },
        }
    },
    legendary = {
        defaults = {
            size = 0.5,
            speed = 10,
            difficulty = 1,
            class = "loot",
            habitat = {},
            totalPopulation = 1,
        },
        types = {
            {
                baseId = "extravagant_ring_01",
                variants = {
                    "extravagant_ring_02",
                    "exquisite_ring_02",
                    "AB_c_ExquisiteRing01",
                    "AB_c_ExtravagantRing01",
                    "AB_c_ExtravagantRing02"
                },
                totalPopulation = 5
            },
            {
                baseId = "extravagant_amulet_01",
                variants = {
                    "extravagant_amulet_02",
                    "exquisite_amulet_01",
                    "AB_c_ExquisiteAmulet01",
                    "AB_c_ExtravagantAmulet01"
                },
                totalPopulation = 5
            },
            {
                baseId = "dwemer_boots",
                variants = {
                    "glass_boots",
                    "daedric_boots"
                },
                totalPopulation = 2
            },
            {
                baseId = "AB_w_EbonyDagger",
                totalPopulation = 1
            },
        }
    }
}

event.register("initialized", function(e)
    for rarity, lootConfig in pairs(loots) do
        logger:debug("Registering %s loot", rarity)
        local types = lootConfig.types
        for _, loot in ipairs(types) do
            logger:debug("Registering loot %s", loot.baseId)
            table.copymissing(loot, lootConfig.defaults)
            loot.rarity = rarity
            Interop.registerFishType(loot)
        end
    end
end)
