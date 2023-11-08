--[[
Format for Mods:
- ID can be for any soundID, mesh filepath, or texture filepath. Must be lowercase.
- Category hooks into the tables above, so the first value will be the name of the desired table, and the second the desired value within it.
    Anything getting added to ignoreList must have an empty category of: ""
    Anything getting added to corpseMapping must have a category of: "Body"
- Define your soundType so it's properly sorted, for instance 'soundType = land' to specify texture material type.
--]]

local function initialized()
    local cso = include("Character Sound Overhaul.interop")
    if cso == nil then return end
    local soundData = {
        -- Land, Carpet:
        { id = "vv23\\f\\vv23_shelfshroomtop", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\f\\vv23_shelfshroomtop_g", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\f\\vv23_glowmushroom_g", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\f\\vv23_glowshroom_01", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\f\\vv23_glowshroom_large", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\f\\vv23_glowshroom_large_g", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\f\\vv23_shelfshroombot", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\f\\vv23_shelfshroombot_g", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_banner_01", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_banner_02", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_banner_03", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_banner_04", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_fabric_01", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_fabric_02", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_fabric_03", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_rug_01", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_rug_02", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_rug_03", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_rug_04", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_rug_05", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_rug_06", category = cso.landTypes.carpet, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_rug_07", category = cso.landTypes.carpet, soundType = "land" },

        -- Land, Dirt:
        -- { id = "oaab\\corpseburnedatlas", category = cso.landTypes.dirt, soundType = "land" },

        -- Land, Grass:
        -- { id = "oaab\\ab_straw_01", category = cso.landTypes.grass, soundType = "land" },

        -- Land, Gravel:
        -- { id = "oaab\\rem\\mv\\tx_mv_ground_04", category = cso.landTypes.gravel, soundType = "land" },

        -- Land, Ice:
        { id = "vv23\\i\\vv23_jyg_arch_window_02", category = cso.landTypes.ice, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_crystal_01", category = cso.landTypes.ice, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_crystal_01_G", category = cso.landTypes.ice, soundType = "land" },

        -- Land, Metal:
        { id = "vv23\\i\\vv23_axiom_trim_01", category = cso.landTypes.metal, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_door_silver_01", category = cso.landTypes.metal, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_gold_coin_01", category = cso.landTypes.metal, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_gold_diamonds_01", category = cso.landTypes.metal, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_gold_trim_01", category = cso.landTypes.metal, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_silver_bauble_02", category = cso.landTypes.metal, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_silver_hook_01", category = cso.landTypes.metal, soundType = "land" },
        { id = "vv23\\u\\vv23_brass_plain_01", category = cso.landTypes.metal, soundType = "land" },

        -- Land, Mud:
        -- { id = "oaab\\corpsefreshatlas", category = cso.landTypes.mud, soundType = "land" },

        -- Land, Stone:
        { id = "vv23\\i\\vv23_jyg_arch_bricks_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_floor_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_panels_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_relief_02", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\i\\vv23_jyg_arch_trim_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\i\\vv23_cave_py_rocks_overlay", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_square_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_square_02", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_square_03", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_square_04", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_square_05", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_square_06", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_wide_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_wide_02", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_wide_03", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_wide_04", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_wide_05", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_wide_06", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_wide_07", category = cso.landTypes.stone, soundType = "land" },
        { id = "vv23\\u\\vv23_jyg_blackboard_wide_08", category = cso.landTypes.stone, soundType = "land" },

        -- Land, Water:
        -- { id = "oaab\\dr_tx_blood_512x", category = cso.landTypes.water, soundType = "land" },

        -- Land, Wood:
        { id = "vv23\\f\\vv23_bark_01", category = cso.landTypes.wood, soundType = "land" },

        -- Items, Book:
        { id = "vv23\\m\\bk_arcanaenigmas.nif", category = cso.itemTypes.book, soundType = "item" },
        { id = "vv23\\m\\bk_justice.nif", category = cso.itemTypes.book, soundType = "item" },
        { id = "vv23\\m\\bk_telvanni_evil.nif", category = cso.itemTypes.book, soundType = "item" },
        { id = "vv23\\m\\codex.nif", category = cso.itemTypes.book, soundType = "item" },

        -- Items, Clothing:
        { id = "vv23\\c\\c_glove_ext.nif", category = cso.itemTypes.clothing, soundType = "item" },
        { id = "vv23\\c\\c_glove_ext_gnd.nif", category = cso.itemTypes.clothing, soundType = "item" },
        { id = "vv23\\c\\jygRobe.nif", category = cso.itemTypes.clothing, soundType = "item" },
        { id = "vv23\\c\\jygRobe2.nif", category = cso.itemTypes.clothing, soundType = "item" },
        { id = "vv23\\c\\jygRobe3.nif", category = cso.itemTypes.clothing, soundType = "item" },
        { id = "vv23\\c\\jygRobe4.nif", category = cso.itemTypes.clothing, soundType = "item" },
        { id = "vv23\\c\\jygRobeGND.nif", category = cso.itemTypes.clothing, soundType = "item" },

        -- Items, Gold:
        { id = "vv23\\m\\coinDwrv05.nif", category = cso.itemTypes.gold, soundType = "item" },
        { id = "vv23\\m\\coinDwrv10.nif", category = cso.itemTypes.gold, soundType = "item" },
        { id = "vv23\\m\\coinDwrv25.nif", category = cso.itemTypes.gold, soundType = "item" },
        { id = "vv23\\m\\coinDwrv100.nif", category = cso.itemTypes.gold, soundType = "item" },
        { id = "vv23\\m\\coinPile01.nif", category = cso.itemTypes.gold, soundType = "item" },
        { id = "vv23\\m\\coinPile02.nif", category = cso.itemTypes.gold, soundType = "item" },
        { id = "vv23\\m\\coinPile03.nif", category = cso.itemTypes.gold, soundType = "item" },
        { id = "vv23\\m\\coinPile04.nif", category = cso.itemTypes.gold, soundType = "item" },
        { id = "vv23\\m\\coinPlane256.nif", category = cso.itemTypes.gold, soundType = "item" },

        -- Items, Gems:
        { id = "vv23\\m\\crystalOrder01.nif", category = cso.itemTypes.gems, soundType = "item" },
        { id = "vv23\\m\\crystalOrder02.nif", category = cso.itemTypes.gems, soundType = "item" },
        { id = "vv23\\m\\crysTreeBonsai01.nif", category = cso.itemTypes.gems, soundType = "item" },
        { id = "vv23\\m\\dwe_turquoise.nif", category = cso.itemTypes.gems, soundType = "item" },

        -- Lockpicks/Keys
        -- { id = "oaab\\m\\misc_keyring.nif", category = cso.itemTypes.lockpick, soundType = "item" },

        -- Items, Repair:
        -- { id = "oaab\\m\\dwrvtoolclamp.nif", category = cso.itemTypes.repair, soundType = "item" },

        -- Items, Scrolls:
        -- { id = "oaab\\m\\crumpledpaper.nif", category = cso.itemTypes.scrolls, soundType = "item" },

        -- Corpse Containers:
        -- { id = "oaab\\o\\corpse_arg_01.nif", category = cso.specialTypes.body, soundType = "corpse" },

        -- Creatures
        -- { id = "oaab\\r\\dwspecter_f.nif", category = cso.specialTypes.ghost, soundType = "creature" },

    }
    for _, data in ipairs(soundData) do
        cso.addSoundData(data.id, data.category, data.soundType)
    end
end
event.register("initialized", initialized)