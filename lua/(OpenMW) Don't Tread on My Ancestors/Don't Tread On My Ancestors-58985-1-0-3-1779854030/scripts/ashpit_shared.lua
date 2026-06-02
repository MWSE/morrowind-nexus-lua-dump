local core = require('openmw.core')

local function hasContent(name)
    local target = name:lower()
    for _, f in ipairs(core.contentFiles.list) do
        if f:lower() == target then return true end
    end
    return false
end

local hasTribunal = hasContent("Tribunal.esm")
local hasTR       = hasContent("Tamriel_Data.esm")

-- tier-based undead pool
local HOSTILE_TIERS = {
    { minLevel = 1,  creatures = { "ancestor_ghost", "bonewalker_weak", "skeleton" } },
    { minLevel = 5,  creatures = { "bonelord", "bonewalker", "skeleton archer", "skeleton warrior" } },
    { minLevel = 8,  creatures = { "bonewalker_greater", "skeleton champion" } },
    { minLevel = 11, creatures = {} },
}

-- Tribunal-only addition
if hasTribunal then
    table.insert(HOSTILE_TIERS[3].creatures, "ancestor_ghost_greater")
end

-- Tamriel Data
if hasTR then
    table.insert(HOSTILE_TIERS[3].creatures, "T_Cyr_Und_Ghst_02")
    table.insert(HOSTILE_TIERS[3].creatures, "T_Mw_Und_SkelWWiz_01")
    table.insert(HOSTILE_TIERS[4].creatures, "T_Mw_Und_BoneldGr_01")
    table.insert(HOSTILE_TIERS[4].creatures, "T_Glb_Und_SkelCmpGr_01")
end

local UP_PENALTY = 3

local function pickWeightedUndead(playerLevel)
    playerLevel = playerLevel or 1
    local weights = {}
    local total = 0

    for ti, tier in ipairs(HOSTILE_TIERS) do
        local n = #tier.creatures
        if n > 0 then
            local d = tier.minLevel - playerLevel
            local w
            if d <= 0 then
                w = 100 / (1 + (-d))            -- below or at player's level
            else
                w = 100 / (1 + d * UP_PENALTY)  -- above player's level
            end
            weights[ti] = w
            total = total + w
        else
            weights[ti] = 0
        end
    end

    if total <= 0 then return nil end

    local r = math.random() * total
    local acc = 0
    for ti = 1, #HOSTILE_TIERS do
        local w = weights[ti]
        if w > 0 then
            acc = acc + w
            if r <= acc then
                local pool = HOSTILE_TIERS[ti].creatures
                return pool[math.random(#pool)]
            end
        end
    end
    return nil
end

return {
    DEFAULTS = {
        MOD_ENABLED         = true,
        CHECK_TICK          = 1,     -- seconds between proximity checks
        SPAWN_RADIUS        = 96,    -- horizontal distance from ashpit
        SPAWN_HEIGHT        = 200,   -- vertical tolerance from ashpit
        HOSTILE_CHANCE      = 10,    -- % chance per tick to spawn while standing on ashpit (no temple rank)
        TEMPLE_REDUCTION    = 10,    -- % reduction per Temple rank
        FOLLOWER_CHANCE     = 10,    -- % chance per tick at rank Patriarch to spawn followers
        FOLLOWER_DURATION   = 300,   -- seconds before follower despawns
        MIN_SPAWNS          = 1,
        MAX_SPAWNS          = 3,
        WARN_NO_SPAWN       = true,  -- show a warning message when stepping on an ashpit without a spawn
        PRINT_LOG           = false,
    },

    -- Cells containing these strings (case-insensitive) will be ignored by the ashpit scanner
    BLACKLISTED_CELLS = {
        "guild",
    },

    -- Strict matching: only these exact record IDs count as ashpits.
    ASHPIT_IDS = {
        ["in_redoran_ashpit_01"] = true,
        ["in_redoran_ashpit_02"] = true,
        ["in_velothi_ashpit_01"] = true,
        ["in_velothi_ashpit_02"] = true,
        ["in_hlaalu_ashpit_01"]  = true,
        ["in_hlaalu_ashpit_02"]  = true,
        ["t_de_setind_i_ashpit_01"]     = true,
        ["t_de_setind_i_ashpit_02"]     = true,
        ["t_de_setind_i_ashpit_03"]     = true,
        ["t_de_setind_i_ashpit_04"]     = true,
        ["t_de_setveloth_i_ashpit_01"]  = true,
    },

    HOSTILE_TIERS = HOSTILE_TIERS,
    pickWeightedUndead = pickWeightedUndead,

    -- Temple faction id
    TEMPLE_FACTION  = "temple",
    TEMPLE_MAX_RANK = 10,

    CREATURE_NAMES = {
        ancestor_ghost            = "Ancestor Ghost",
        ancestor_ghost_greater    = "Greater Ancestor Ghost",
        bonelord                  = "Bonelord",
        bonewalker_greater        = "Greater Bonewalker",
        bonewalker_weak           = "Lesser Bonewalker",
        t_mw_und_boneldgr_01      = "Bonelord Warder",
        ["skeleton archer"]       = "Skeleton Archer",
        ["skeleton champion"]     = "Skeleton Champion",
        ["skeleton warrior"]      = "Skeleton Warrior",
        T_Glb_Und_SkelCmpGr_01    = "Greater Skeleton Champion",
        skeleton                  = "Skeleton",
        bonewalker                = "bonewalker",
        T_Cyr_Und_Ghst_02         = "Ghost Guardian",
        T_Mw_Und_SkelWWiz_01      = "Skeleton War-Wizard",
    },

    MESSAGES_HOSTILE = {
        "Disturbed ashes spill forth restless dead.",
        "You have desecrated the resting place. The ancestors answer in fury.",
        "The ashpit stirs, something long buried claws its way back.",
        "Ashes scatter and a shape unfolds from them, hateful and hungry.",
    },

    MESSAGES_FOLLOWER = {
        "The ancestors recognize the Tribunal's hand upon you and walk at your side.",
        "An ancestor rises, bound to your purpose by sacred rank.",
        "The dead heed your station and lend their guard.",
    },

    MESSAGES_WARN_OUTSIDE = {
        "The ashes shift beneath your foot. The ancestors are watching.",
        "A cold breath stirs the pit. You are not welcome here.",
        "Something old and patient marks your trespass.",
        "The dust whispers your name. It will be remembered.",
        "The pit is quiet, for now. The ancestors withhold their wrath.",
    },

    MESSAGES_WARN_INSIDE = {
        "The ancestors know your face. They expect better.",
        "The ashes stir. Even the faithful may be found wanting.",
        "You wear the Temple's mark, yet tread on the dead. Tread carefully.",
        "The pit remembers every vow you have sworn.",
        "Your rank shields you today from the ancestors' wrath. Do not mistake patience for permission.",
    },

    HAS_TRIBUNAL = hasTribunal,
    HAS_TR       = hasTR,
}