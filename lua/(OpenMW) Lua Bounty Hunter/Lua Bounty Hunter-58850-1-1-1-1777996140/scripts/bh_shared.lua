local core = require("openmw.core")

local function hasContent(name)
    local target = name:lower()
    for _, f in ipairs(core.contentFiles.list) do
        if f:lower() == target then return true end
    end
    return false
end

local hasTR = core.contentFiles.has("TR_Mainland.esm")
local hasPC = hasContent("Cyr_Main.esm")
local hasBCoM = hasContent("Beautiful cities of morrowind.esp")
local hasBL = hasContent("Bloodmoon.esm")

local M = {
    DEFAULTS = {
        MOD_ENABLED      = true,
        ESCAPE_CHANCE    = 10,
        REWARD_PER_LEVEL  = 50,
        MIN_PRISONER_LEVEL = 3,
        SHOW_DEATH_TAUNT = true,
        SHOW_ALREADY_ESCORTING = true,
        ENABLE_LOGS      = false,
    },

    -- Fort definitions. Each fort has:
    --   id            : internal id used for slot tracking
    --   name          : display name of the fort/location (shown in UI)
    --   rewardNpcName : display name of the reward NPC (shown in UI)
    --   targetCell    : cell the player must bring the prisoner to (matched case-insensitively)
    --   rewardNpc     : recordId of the NPC who pays the reward (matched case-insensitively)
    --   rewardRadius  : how close the player must be to that NPC horizontally to claim reward
    --   rewardZRange  : max vertical distance between player and reward NPC
    --   fullMessage   : message shown when all cells are occupied AND player tries to deliver
    --   prisonCell    : cell where caught NPCs are teleported
    --   prisonSlots   : list of {x, y, z} positions in the prison cell
    --   mod           : (optional) gating tag. "TR" entries are only included when
    --                   TR_Mainland.esm is in the active content list. "BCOM" entries are only included
    --                   when Beautiful cities of morrowind.esp is in the active content list
    FORTS = {
        -- Morrowind.esm
        {
            id            = "moonmoth",
            name          = "Moonmoth Legion Fort",
            rewardNpcName = "Radd Hard-Heart",
            targetCell    = "moonmoth legion fort, interior",
            rewardNpc     = "radd hard-heart",
            rewardRadius  = 150,
            rewardZRange = 100,
            fullMessage   = "Radd Hard-Heart: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "moonmoth legion fort, prison towers",
            prisonSlots = {
                { x =  261.6, y =  269.8, z = -127.0 },
                { x =  494.5, y =  508.6, z = -127.0 },
                { x =  254.0, y =  755.3, z = -127.0 },
                { x = -463.5, y =  522.8, z = -127.0 },
            },
        },
        {
            id            = "hawkmoth",
            name          = "Ebonheart, Hawkmoth Legion Garrison",
            rewardNpcName = "Frald the White",
            targetCell    = "ebonheart, hawkmoth legion garrison",
            rewardNpc     = "frald the white",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Frald the White: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "ebonheart, hawkmoth legion garrison",
            prisonSlots = {
                { x =  755.8, y =  2513.6, z = -383.0 },
            },
        },
        {
            id            = "pelagiad",
            name          = "Fort Pelagiad",
            rewardNpcName = "Guard Captain",
            targetCell    = "pelagiad, fort pelagiad",
            rewardNpc     = "imperial guard captain",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Guard Captain: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "pelagiad, south wall",
            prisonSlots = {
                { x =  62.9, y =  135.0, z = -1535.0 },
                { x =  251.3, y =  338.6, z = -1535.0 },
                { x =  472.8, y = -384.7, z = -1535.0 },
            },
        },
        {
            id            = "buckmoth",
            name          = "Buckmoth Legion Fort",
            rewardNpcName = "Raesa Pullia",
            targetCell    = "buckmoth legion fort, interior",
            rewardNpc     = "raesa pullia",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Raesa Pullia: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "buckmoth legion fort, prison",
            prisonSlots = {
                { x =  512.4, y =  -254.7, z = 1.0 },
                { x =  50.0, y =  0.0, z = 1.0 },
                { x =  471.3, y = 262.7, z = 1.0 },
                { x =  508.7, y = 2.4, z = 257.0 },
            },
        },
        -- Bloodmoon.esm
        {
            id            = "frostmoth",
            mod           = "BLOODMOON",
            name          = "Fort Frostmoth",
            rewardNpcName = "Guard",
            targetCell    = "fort frostmoth, prison",
            rewardNpc     = "bm_imperial guard",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Guard: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "fort frostmoth, prison",
            prisonSlots = {
                { x =  2059.3, y =  -604.9, z = -127.0 },
                { x =  1801.7, y =  -622.3, z = -127.0 },
                { x =  1529.2, y =  -607.2, z = -127.0 },
                { x =  1.85, y =  -605.1, z = -127.0 },
                { x =  255.1, y =  -607.9, z = -127.0 },
                { x =  -256.1, y =  -625.4, z = -127.0 },
            },
        },
        -- Beautiful Cities of Morrowind
        {
            id            = "vivecarenabcom",
            mod           = "BCOM",
            name          = "Vivec, Arena Holding Cells",
            rewardNpcName = "Ordinator",
            targetCell    = "vivec, arena holding cells",
            rewardNpc     = "ordinator stationary",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Ordinator: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "vivec, arena holding cells",
            prisonSlots = {
                { x =  1225.2, y =  -6.0, z = 129.1 },
                { x =  1243.8, y =  259.2, z = 129.1 },
                { x =  1254.3, y =  512.4, z = 129.1 },
                { x =  1240.5, y =  780.3, z = 129.1 },
                { x =  805.4, y =  762.9, z = 129.1 },
                { x =  799.3, y =  498.1, z = 129.1 },
            },
        },
        -- Tamriel Rebuilt
        {
            id            = "nivalis",
            mod           = "TR",
            name          = "Nivalis, Icebreaker Keep",
            rewardNpcName = "Fazahr",
            targetCell    = "nivalis, icebreaker keep",
            rewardNpc     = "tr_m1_fazahr",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Fazahr: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "nivalis, icebreaker keep",
            prisonSlots = {
                { x =  4198.9, y =  4423.0, z = 12993.0 },
            },
        },
        {
            id            = "windmoth",
            mod           = "TR",
            name          = "Windmoth Legion Fort",
            rewardNpcName = "Arvs Rethrathi",
            targetCell    = "windmoth legion fort, interior",
            rewardNpc     = "tr_m2_arvs_rethrathi",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Arvs Rethrathi: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "windmoth legion fort, interior",
            prisonSlots = {
                { x =  3365.0, y =  4162.0, z = 11873.0 },
            },
        },
        {
            id            = "ancylis",
            mod           = "TR",
            name          = "Fort Ancylis",
            rewardNpcName = "Rojanna Jades",
            targetCell    = "fort ancylis, main keep",
            rewardNpc     = "tr_m4_rojanna jades",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Rojanna Jades: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "fort ancylis, prison",
            prisonSlots = {
                { x =  11963.0, y =  6848.8, z = 13280.9 },
                { x =  11948.1, y =  6332.9, z = 13280.9 },
                { x =  11523.0, y =  6798.8, z = 13280.9 },
                { x =  11488.4, y =  6605.0, z = 13280.9 },
                { x =  11218.9, y =  6526.9, z = 13280.9 },
                { x =  11013.8, y =  6126.4, z = 13280.9 },
                { x =  11223.8, y =  6110.0, z = 13280.9 },
                { x =  11472.7, y =  6127.1, z = 13280.9 },
                { x =  11713.7, y =  6128.0, z = 13280.9 },
            },
        },
        {
            id            = "umbermoth",
            mod           = "TR",
            name          = "Fort Umbermoth",
            rewardNpcName = "Cinia Andacia",
            targetCell    = "fort umbermoth, interior",
            rewardNpc     = "tr_m3_cinia_andacia",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Cinia Andacia: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "fort umbermoth, interior",
            prisonSlots = {
                { x =  4229.8, y =  4565.3, z = 13425.9 },
                { x =  4223.7, y =  4809.5, z = 13440.6 },
                { x =  5290.8, y =  4012.2, z = 13440.6 },
            },
        },
        {
            id            = "helnim",
            mod           = "TR",
            name          = "Helnim, Fort Servas",
            rewardNpcName = "Servas Capris",
            targetCell    = "helnim, fort servas",
            rewardNpc     = "tr_m2_servas capris",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Servas Capris: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "helnim, prison tower",
            prisonSlots = {
                { x =  4150.4, y =  4166.1, z = 14320.5 },
            },
        },
        {
            id            = "dustmoth",
            mod           = "TR",
            name          = "Firewatch, Dustmoth Legion Garrison",
            rewardNpcName = "Vycius Pitio",
            targetCell    = "firewatch, dustmoth legion garrison: east tower",
            rewardNpc     = "tr_m1_vycius_pitio",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Vycius Pitio: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "firewatch, dustmoth legion garrison: dungeon",
            prisonSlots = {
                { x =  3858.5, y =  3662.5, z = 15297.0 },
                { x =  4308.8, y =  4423.1, z = 15297.0 },
                { x =  3881.3, y =  4403.3, z = 15297.0 },
                { x =  3879.5, y =  3886.6, z = 15041.0 },
                { x =  4320.6, y =  4156.5, z = 15297.0 },
            },
        },
        -- Requires Cyr_Main.esm
        {
            id            = "goldstone",
            mod           = "PC",
            name          = "Goldstone, Dungeons",
            rewardNpcName = "Caldia Acon",
            targetCell    = "goldstone, dungeons",
            rewardNpc     = "pc_m1_caldiaacon",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Caldia Acon: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "goldstone, dungeons",
            prisonSlots = {
                { x =  4457.5, y =  4318.4, z = 14337.0 },
                { x =  4493.6, y =  3866.3, z = 14337.0 },
                { x =  4204.7, y =  3888.0, z = 14337.0 },
                { x =  3981.7, y =  4329.2, z = 14337.0 },
                { x =  3954.9, y =  3905.7, z = 14337.0 },
                { x =  3711.1, y =  4332.8, z = 14337.0 },
                { x =  3430.1, y =  4296.1, z = 14337.0 },
                { x =  3457.4, y =  3864.9, z = 14337.0 },
                { x =  3444.8, y =  4551.2, z = 14593.0 },
                { x =  4225.7, y =  4598.2, z = 14593.0 },
            },
        },
        {
            id            = "fortheath",
            mod           = "PC",
            name          = "Fort Heath",
            rewardNpcName = "Tarilin Nylaen",
            targetCell    = "fort heath, prison",
            rewardNpc     = "pc_m1_tarilinnylaen",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "Tarilin Nylaen: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "fort heath, prison",
            prisonSlots = {
                { x =  3541.9, y =  3752.4, z = 6239.7 },
                { x =  4283.9, y =  3743.2, z = 6239.7 },
                { x =  3535.9, y =  2722.4, z = 6239.7 },
                { x =  4252.5, y =  2710.5, z = 6239.7 },
            },
        },
        {
            id            = "forttelodrach",
            mod           = "PC",
            name          = "Fort Telodrach",
            rewardNpcName = "JSahdo",
            targetCell    = "fort telodrach, east tower",
            rewardNpc     = "pc_m1_jsahdo",
            rewardRadius  = 150,
            rewardZRange  = 100,
            fullMessage   = "JSahdo: \"The cells are full. Come back when there's room.\"",
            prisonCell    = "fort telodrach, east tower",
            prisonSlots = {
                { x =  4148.3, y =  4295.3, z = 15457.0 },
                { x =  3675.0, y =  3794.0, z = 15457.0 },
                { x =  4051.5, y =  4542.7, z = 15457.0 },
            },
        },
    },

    KHAJIIT_RACE = {
        ["khajiit"]           = true,
        ["t_els_cathay"]      = true,
        ["t_els_cathay-raht"] = true,
        ["t_els_ohmes"]       = true,
        ["t_els_ohmes-raht"]  = true,
        ["t_els_suthay"]      = true,
        ["t_els_dagi-raht"]   = true,
    },

    MESSAGES = {
        -- player says this after NPC gets up
        player_order = {
            "On your feet. You're coming with me.",
            "Get up. We're heading to the fort.",
            "Move. And don't try anything.",
            "You're under arrest. Follow me.",
        },
        khajiit_player_order = {
            "On your paws. This one is taking you in.",
            "Get up. This one knows the way to the fort.",
            "Move. And do not try anything foolish.",
            "Walk. This one will be watching.",
            "You are under arrest. Follow this one.",
        },
        -- reward line. %s = reward NPC display name, %d = gold amount.
        reward = "%s: \"Good work bringing this one in. Here's your %d gold.\"",
        -- appended to reward line when the last free slot is taken.
        reward_last_slot = " That fills our last cell. Don't bring any more until we have room.",
        -- prisoner attacks the player.
        escape_attempt = {
            "I've had enough of this!",
            "You should have finished me when you had the chance!",
            "Your back was turned for a moment too long!",
            "I'm done following you around like a summoned scamp!",
        },
        khajiit_escape_attempt = {
            "This one is done being herded like a guar!",
            "Khajiit did not survive the road to die in a cell!",
            "You should have bound this one's claws. Too late now.",
            "The moons do not smile on cages. Neither does this one.",
        },
        low_hp_attack = {
            "Now's my chance!",
            "You look weak. Time to strike!",
            "I've been waiting for this moment!",
        },
        khajiit_low_hp_attack = {
            "This one smells blood. Yours.",
            "You stumble. Khajiit does not waste such gifts.",
            "The weak fall. This one is still standing.",
        },
        -- player taunts after killing a prisoner who turned on them.
        death_prisoner = {
            "Looks like your journey ends here. And nothing of value was lost.",
        },
        khajiit_death_prisoner = {
            "This one remembers the bounty said 'alive', but this one’s arm is so very tired.",
        },
        -- shown when the prisoner does not reappear after the player changes cells.
        prisoner_escaped = "The prisoner escaped.",
        -- player already has a prisoner when a new knockout fires.
        already_escorting = "You already have a prisoner. Deal with them first.",
    },
}

local function isFortAvailable(fort)
    if fort.mod == "TR"   then return hasTR   end
    if fort.mod == "BCOM" then return hasBCoM end
    if fort.mod == "PC" then return hasPC end
    if fort.mod == "BLOODMOON" then return hasBL end
    return true
end

local filteredForts = {}
for _, fort in ipairs(M.FORTS) do
    if isFortAvailable(fort) then
        filteredForts[#filteredForts + 1] = fort
    end
end
M.FORTS = filteredForts

return M