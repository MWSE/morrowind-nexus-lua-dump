-- cfguration
local cfg = {

    --seconds between snake updates (travel speed)
    updateInterval = .25,

    --bronze color
    bronze = "#CD7F32",

    -- GUI IDs
    mainMenuId = 31450,
    gameOverId = 31451,
    leaderboardId_1 = 31452,
    leaderboardId_2 = 31453,
    ask_yagrum_id = 31454,

    yagrums_explanation =
        "Ah, the marvels of pre-Numidium engineering!\n" ..
        "I reverse-engineered this 'Snake' device from what\n" ..
        "the outlanders once called a Nokia 6110.\n" ..
        "\n" ..
        "Its architecture is eerily akin to a Dwemer puzzle cube,\n" ..
        "layered tonal glyphs, recursive harmonics,\n" ..
        "and logic bound in bronze.\n" ..
        "\n" ..
        "A touch of Kagrenac’s Insight,\n" ..
        "a few recalibrated resonators,\n" ..
        "and the serpent slithers again.\n" ..
        "\n" ..
        "Of course, the amount of cubes required to power such a device....\n" ..
        "That's where Caius came in, right neravar?\n",

    --path to leaderboard file
    leaderboardFile = "custom/snakeLeaderboard.json",
    maxLeaderboardEntries = 25, -- Number of top scores to display

    initialSnakeLength = 3,

    stagingLocation = {
        x = 120.0,
        y = 120.0,
        z = -50
    },

    --scales
    headScale = 1,
    bodyScale = .6,
    foodScale = 1.5,
    wallScale = -1000, --negative to invert the rectnagular stone block so we see the texture on the inside
    borderScale = 2,
    floorScale = 10,

    --sounds
    eatFoodSound = "Swallow",
    moveSound = "corpDRAG",

    --cell used
    roomCell = "Abandoned Skooma Distillery",
    cellBaseId = "Vor Lair, Interior",
    --location in cell
    roomPosition = { x = 0, y = 0, z = 0 },
    wallPosition = { x = 120, y = 120, z = 0 },
    --size of the game grid
    roomSize = 16,

    objects = {
        snakeHead = "sg_snake_head",
        snakeBody = "sg_snake_body",
        food = {
            "sg_rotating_skooma",
            "sg_rotating_skooma_pipe",
            "sg_rotating_moonsugar"
        },
        wall = "sg_skooma_ruins",
        floor = "in_lava_1024",
        border = "sg_dwemer_cube"
        -- border = "light_de_lantern_14"
    },
    --bring the skooma bottle up to floor level
    rotating_skooma_height_offset = 14,

    -- Specific rotations for the head
    headRotations = {
        raise = { rotX = 0, rotY = 0, rotZ = 180 },
        up = { rotX = 0, rotY = 0, rotZ = 180 },
        down = { rotX = 0, rotY = 0, rotZ = 0 },
        lower = { rotX = 0, rotY = 0, rotZ = 0 },
        left = { rotX = 0, rotY = 0, rotZ = 90 },
        right = { rotX = 0, rotY = 0, rotZ = 270 }
    },
    -- Player platform position
    platformPosition = {
        x = 120,
        y = -25,
        z = 0
    },
    commands = {
        start = "snake",
        stop = "stop",
        up = "raise",
        down = "lower",
        left = "left",
        right = "right"
    },

    foodCollision = true,
    initFood = true,
    initializing = false,

    --  "vo\\w\\m\\atk_wm002.mp3" fetcher bosmer
    --  "vo\\w\\m\\hit_wm005.mp3" stupid bosmer
    --  "vo\\o\\m\\hit_om009.mp3" orc fetcher

    --npc voice lines
    npcVoiceLines = {
        ["yagrum"] = {
            "vo\\Misc\\Yagrum_1.mp3", -- yagrum bagarn: welcome
            "vo\\Misc\\Yagrum_2.mp3", -- yagrum bagarn: nooooooooooooo
            "vo\\Misc\\Yagrum_3.mp3", -- yagrum bagarn: engineer talk
        },
        ["caius"] = {
            "vo\\i\\m\\bIdl_IM022.mp3", -- imperial: without me it all falls to pieces
            "vo\\i\\m\\Hit_IM002.mp3"   -- imperial:WHA!
        },
    },

    -- Food-specific voice lines
    foodVoiceLines = {
        ["sg_rotating_skooma"] = {
            "vo\\a\\m\\idl_am008.mp3",  -- argonian nom noms
            "vo\\d\\m\\tidl_dm015.mp3", -- dunmer burp
            "vo\\a\\m\\idl_am008.mp3",  -- argonian nom noms
            "vo\\k\\m\\idl_km001.mp3",  -- sweet skooma
            "vo\\a\\m\\idl_am008.mp3",  -- argonian nom noms
            "vo\\n\\m\\hit_nm005.mp3",  -- nord groan
            "vo\\a\\m\\idl_am008.mp3",  -- argonian nom noms
            "Vo\\o\\m\\Idl_OM005.mp3",  -- orc sniff
            -- "Vo\\o\\m\\hit_om007.mp3", -- orc noise
            -- "Vo\\o\\m\\hit_om006.mp3", -- orcnoise
        },
        ["sg_rotating_skooma_pipe"] = {
            "vo\\a\\m\\idl_am008.mp3", -- argonian nom noms
            "vo\\d\\m\\idl_dm001.mp3", -- dunmer
            "vo\\a\\m\\idl_am008.mp3", -- argonian nom noms
            "vo\\h\\m\\idl_hm008.mp3", -- altmer clear throat
            "vo\\h\\m\\idl_hm007.mp3", -- altmer hummmmm
            "vo\\a\\m\\idl_am008.mp3", -- argonian nom noms
            "Vo\\i\\m\\Idl_IM004.mp3", --imperial clear throat
            "vo\\a\\m\\idl_am008.mp3", -- argonian nom noms
            "vo\\a\\m\\idl_am008.mp3", -- argonian nom noms
            "Vo\\i\\m\\Idl_IM009.mp3", --imperial clear throat
            "vo\\k\\m\\idl_km001.mp3", -- sweet skooma
            "vo\\n\\m\\idl_nm002.mp3", -- nord cough
            "vo\\n\\m\\idl_nm004.mp3", -- nord cough
            "vo\\n\\m\\idl_nm007.mp3", -- nord cough
            "vo\\r\\m\\idl_rm009.mp3", -- redguard cough
            "vo\\w\\m\\idl_wm002.mp3", -- bosmer cough
            "Vo\\o\\m\\idl_om006.mp3", -- orc cough
            "Vo\\o\\m\\idl_om007.mp3", -- orc clear throat
            -- "Vo\\o\\m\\hit_om007.mp3", -- orc noise
            -- "Vo\\o\\m\\hit_om006.mp3", -- orcnoise
        },
        ["sg_rotating_moonsugar"] = {
            "Vo\\o\\m\\Idl_OM005.mp3",    -- orc sniff
            "Vo\\i\\m\\Idl_IM001.mp3",    --imperial sniff
            "Vo\\i\\m\\Idl_IM002.mp3",
            "Vo\\o\\m\\Idl_OM005.mp3",    -- orc sniff
            "vo\\d\\m\\idl_dm002.mp3",    --dunmer
            "Vo\\o\\m\\Idl_OM005.mp3",    -- orc sniff
            "vo\\a\\m\\hlo_am056.mp3",    -- argonian
            "Vo\\o\\m\\Idl_OM005.mp3",    -- orc sniff
            "vo\\a\\m\\idl_am008.mp3",    -- argonian nom noms
            "vo\\b\\m\\idl_bm009.mp3",    --breton
            "vo\\h\\m\\idl_hm009.mp3",    -- altmer sniff
            "vo\\k\\m\\idl_km004.mp3",    -- khajiit sniff
            "vo\\k\\m\\hlo_km133.mp3",    -- our sugar is yours friend
            "vo\\k\\m\\hlo_km120.mp3",    -- welcome friend, share some sugar?
            "vo\\n\\m\\sweetshare03.mp3", -- when the sugar is warmed by the pale hearth light, the happiness spreads throughout the night!
            "vo\\k\\m\\idl_km009.mp3",    -- sweet moon sugar.
            "vo\\k\\m\\hlo_km091.mp3",    -- some sugar for you, friend?
            "vo\\n\\m\\idl_nm003.mp3",    -- nord sniff
            "vo\\n\\m\\sweetshare03.mp3", -- when the sugar is warmed by the pale hearth light, the happiness spreads throughout the night!
            "vo\\r\\m\\idl_rm008.mp3",    -- redguard sniff
            "vo\\w\\m\\idl_wm001.mp3",    -- bosmer sniff
        },
    }

}

return cfg
