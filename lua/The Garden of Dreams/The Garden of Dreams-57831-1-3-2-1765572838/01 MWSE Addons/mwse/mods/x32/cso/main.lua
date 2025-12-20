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
        { id = "x32\\u\\x32_garden_Fabric05_1", category = cso.landTypes.carpet, soundType = "land" },

        -- Land, Grass:
        { id = "x32\\f\\x32_f_puzzle_leaves_02", category = cso.landTypes.grass, soundType = "land" },

        -- Land, Gravel:
        { id = "x32\\i\\x32_i_black_trail_01", category = cso.landTypes.gravel, soundType = "land" },
        { id = "x32\\i\\x32_land_whitegravel", category = cso.landTypes.gravel, soundType = "land" },

        -- Land, Ice:
        { id = "x32\\i\\x32_i_garden_glass", category = cso.landTypes.ice, soundType = "land" },

        -- Land, Metal:
        { id = "x32\\e\\x32_e_gold_scraped_metal00", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_e_gold_sword_flow", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_i_garden_door", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_i_garden_grate", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_i_garden_grate_shelf", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_i_garden_trim_01", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_i_garden_trim_02", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_i_garden_wall", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_garden_Bronze1", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_garden_Bronze2", category = cso.landTypes.metal, soundType = "land" },
        { id = "x32\\e\\x32_i_garden_wall", category = cso.landTypes.metal, soundType = "land" },

        -- Land, Stone:
        { id = "x32\\i\\x32_i_black_rock_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_i_blackruin_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_i_blackruin_02", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_i_blackruin_03", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_i_blackruin_04", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_i_fresco_meph", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_i_garden_floor", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_land_whiterock", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_o_blackruinurn_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_o_blackruinurn_02", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_StatueCreep01", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_StatueCreep02A", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_StatueCreep02B", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_StatueCreep02C", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_X_WhiteRuin_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_X_WhiteRuin_02", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_X_WhiteRuin_03", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_X_WhiteRuin_04", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_X_WhiteRuin_05", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_X_WhiteRuin_06", category = cso.landTypes.stone, soundType = "land" },
        { id = "x32\\i\\x32_x_whiteruin_07", category = cso.landTypes.stone, soundType = "land" },

        -- Land, Wood:
        { id = "x32\\f\\x32_bark_01", category = cso.landTypes.wood, soundType = "land" },
        { id = "x32\\f\\x32_f_puzzle_root_01", category = cso.landTypes.wood, soundType = "land" },
        { id = "x32\\i\\x32_i_blackwood_01", category = cso.landTypes.wood, soundType = "land" },
        { id = "x32\\i\\x32_garden_Wood16", category = cso.landTypes.wood, soundType = "land" },
        { id = "x32\\i\\x32_x_whiteruin_door_01", category = cso.landTypes.wood, soundType = "land" },

        -- Lockpicks/Keys
        { id = "x32\\m\\key_floral_blue.nif", category = cso.itemTypes.lockpick, soundType = "item" },
        { id = "x32\\m\\key_floral_green.nif", category = cso.itemTypes.lockpick, soundType = "item" },
        { id = "x32\\m\\key_floral_red.nif", category = cso.itemTypes.lockpick, soundType = "item" },

        -- Items, Repair:
        { id = "x32\\m\\garden_cultivator.nif", category = cso.itemTypes.repair, soundType = "item" },
        { id = "x32\\m\\garden_hoe.nif", category = cso.itemTypes.repair, soundType = "item" },
        { id = "x32\\m\\garden_trowel.nif", category = cso.itemTypes.repair, soundType = "item" },

        -- Items, Scrolls:
        { id = "x32\\m\\writ_open.nif", category = cso.itemTypes.scrolls, soundType = "item" },

        -- Creatures
        { id = "x32\\r\\spirit.nif", category = cso.specialTypes.ghost, soundType = "creature" },
        { id = "x32\\r\\voidghost.nif", category = cso.specialTypes.ghost, soundType = "creature" },

    }
    for _, data in ipairs(soundData) do
        cso.addSoundData(data.id, data.category, data.soundType)
    end
end
event.register("initialized", initialized)