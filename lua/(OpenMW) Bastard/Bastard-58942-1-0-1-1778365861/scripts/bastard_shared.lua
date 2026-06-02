local M = {}

-- ======================================================================================================
-- CLASS BUCKETS
-- every NPC class is sorted into one of: warrior, commoner, mage, noble, guard
-- anything not listed defaults to "commoner"

M.CLASS_BUCKETS = {
    -- warriors
    ["acrobat"]       = "warrior",
    ["agent"]         = "warrior",
    ["archer"]        = "warrior",
    ["assassin"]      = "warrior",
    ["barbarian"]     = "warrior",
    ["crusader"]      = "warrior",
    ["knight"]        = "warrior",
    ["warrior service"]    = "warrior",
    ["assassin service"]   = "warrior",
    ["scout service"]      = "warrior",
    ["archer service"]     = "warrior",
    ["barbarian service"]  = "warrior",
    ["knight service"]     = "warrior",
    ["crusader service"]   = "warrior",
    ["rogue service"]      = "warrior",
    ["agent service"]      = "warrior",
    ["acrobat service"]    = "warrior",
    ["rogue"]         = "warrior",
    ["scout"]         = "warrior",
    ["warrior"]       = "warrior",
    ["buoyant armiger"]  = "warrior",
    ["champion"]         = "warrior",
    ["drillmaster"]      = "warrior",
    ["enforcer"]         = "warrior",
    ["hunter"]           = "warrior",
    ["master-at-arms"]   = "warrior",
    ["sharpshooter"]     = "warrior",
    ["lamp knight"]      = "warrior",
    ["cat-catcher"]      = "warrior",

    -- commoners
    ["alchemist"]     = "commoner",
    ["alchemist service"]  = "commoner",
    ["smith service"]      = "commoner",
    ["trader service"]     = "commoner",
    ["pawnbroker service"] = "commoner",
    ["bookseller service"] = "commoner",
    ["clothier service"]   = "commoner",
    ["publican service"]   = "commoner",
    ["caravaner service"]  = "commoner",
    ["shipmaster service"] = "commoner",
    ["bard service"]       = "commoner",
    ["thief service"]      = "commoner",
    ["smuggler service"]   = "commoner",
    ["t_smuggler service"] = "commoner",
    ["artist"]        = "commoner",
    ["astrologer"]    = "commoner",
    ["apothecary"]    = "commoner",
    ["bard"]          = "commoner",
    ["bookseller"]    = "commoner",
    ["caravaner"]     = "commoner",
    ["commoner"]      = "commoner",
    ["clothier"]      = "commoner",
    ["dreamer"]       = "commoner",
    ["farmer"]        = "commoner",
    ["herder"]        = "commoner",
    ["miner"]         = "commoner",
    ["pauper"]        = "commoner",
    ["pawnbroker"]    = "commoner",
    ["pilgrim"]       = "commoner",
    ["publican"]      = "commoner",
    ["savant"]        = "commoner",
    ["shipmaster"]    = "commoner",
    ["slave"]         = "commoner",
    ["smith"]         = "commoner",
    ["smuggler"]      = "commoner",
    ["thief"]         = "commoner",
    ["trader"]        = "commoner",
    ["t_smuggler"]    = "commoner",
    ["baker"]         = "commoner",
    ["banker"]        = "commoner",
    ["barrister"]     = "commoner",
    ["carpenter"]     = "commoner",
    ["cook"]          = "commoner",
    ["courtesan"]     = "commoner",
    ["dockworker"]    = "commoner",
    ["fletcher"]      = "commoner",
    ["jeweler"]       = "commoner",
    ["naturalist"]    = "commoner",
    ["potter"]        = "commoner",
    ["ratcatcher"]    = "commoner",
    ["sailor"]        = "commoner",
    ["scribe"]        = "commoner",
    ["gardener"]      = "commoner",
    ["caretaker"]     = "commoner",
    ["journalist"]    = "commoner",
    ["therionaut"]    = "commoner",

    -- mages
    ["battlemage"]    = "mage",
    ["healer"]        = "mage",
    ["guild guide"]    = "mage",
    ["mage"]          = "mage",
    ["nightblade"]    = "mage",
    ["nightblade service"] = "mage",
    ["mage service"]       = "mage",
    ["sorcerer service"]   = "mage",
    ["battlemage service"] = "mage",
    ["spellsword service"] = "mage",
    ["healer service"]     = "mage",
    ["priest service"]     = "mage",
    ["enchanter service"]  = "mage",
    ["necromancer service"]= "mage",
    ["witch service"]      = "mage",
    ["warlock service"]    = "mage",
    ["monk service"]       = "mage",
    ["monk"]          = "mage",
    ["necromancer"]   = "mage",
    ["priest"]        = "mage",
    ["sorcerer"]      = "mage",
    ["spellsword"]    = "mage",
    ["warlock"]       = "mage",
    ["witch"]         = "mage",
    ["mabrigash"]     = "mage",
    ["wise woman"]    = "mage",
    ["wise woman service"]    = "mage",
    ["enchanter"]     = "mage",
    ["clever-man"]    = "mage",
    ["shaman"]        = "mage",

    -- nobles
    ["noble"]         = "noble",

    -- guards
    ["guard"]            = "guard",
    ["ordinator"]        = "guard",
    ["ordinator guard"]  = "guard",
}

M.GUARD_PATTERNS = { "guard", "ordinator", "watchman" }

-- ======================================================================================================
-- FACTIONS
-- each faction shifts Fight (attack) and Give-In percentages additively
-- positive Fight = more aggressive. Negative GiveIn = harder to rob

M.FACTION_MODS = {
    -- houses (Redoran/Telvanni harder. Hlaalu more pragmatic)
    ["redoran"]                  = { fight =  25, giveIn = -25 },
    ["telvanni"]                 = { fight =  18, giveIn = -25 },
    ["hlaalu"]                   = { fight =   0, giveIn =   5 },
    ["t_mw_houseredoran"]        = { fight =  25, giveIn = -25 },
    ["t_mw_housetelvanni"]       = { fight =  18, giveIn = -25 },
    ["t_mw_househlaalu"]         = { fight =   0, giveIn =   5 },
    ["t_mw_housedres"]           = { fight =  10, giveIn = -10 },
    ["t_mw_houseindoril"]        = { fight =  10, giveIn = -15 },

    -- military (close to guards)
    ["imperial legion"]          = { fight =  35, giveIn = -30 },
    ["t_mw_imperiallegion"]      = { fight =  35, giveIn = -30 },
    ["t_mw_imperialnavy"]        = { fight =  35, giveIn = -30 },
    ["fighters guild"]           = { fight =  30, giveIn = -20 },
    ["t_mw_fightersguild"]       = { fight =  30, giveIn = -20 },

    -- religious (calmer but defiant)
    ["temple"]                   = { fight =   5, giveIn = -15 },
    ["t_mw_temple"]              = { fight =   5, giveIn = -15 },
    ["imperial cult"]            = { fight =   0, giveIn =  -5 },
    ["t_mw_imperialcult"]        = { fight =   0, giveIn =  -5 },

    -- magic (low fight, defiant willpower)
    ["mages guild"]              = { fight = -10, giveIn = -10 },
    ["t_mw_magesguild"]          = { fight = -10, giveIn = -10 },

    -- criminal / outlaw
    ["thieves guild"]            = { fight =  -5, giveIn =  20 },
    ["t_mw_thievesguild"]        = { fight =  -5, giveIn =  20 },
    ["camonna tong"]             = { fight =  30, giveIn = -10 },
    ["morag tong"]               = { fight =  25, giveIn = -20 },
    ["t_mw_moragtong"]           = { fight =  25, giveIn = -20 },

    -- trade / common organizations
    ["east empire company"]      = { fight =   0, giveIn =  10 },
    ["t_mw_eastempirecompany"]   = { fight =   0, giveIn =  10 },

    -- ashlanders (proud, defiant)
    ["ashlanders"]               = { fight =  15, giveIn = -15 },
    ["t_mw_shinathi"]            = { fight =  15, giveIn = -15 },

    -- default for unlisted
    ["none"]                     = { fight =   0, giveIn =   0 },
}

-- ======================================================================================================
-- RACE INTIMIDATION
-- player race adds (or subtracts) to GiveIn (more intimidating = easier rob) and to NPC's Fight resistance. Orcs scariest. Bosmer/Khajiit least.

M.RACE_MODS = {
    ["orc"]        = { intimidate =  20 },
    ["nord"]       = { intimidate =  12 },
    ["redguard"]   = { intimidate =  10 },
    ["dunmer"]     = { intimidate =   6 },
    ["imperial"]   = { intimidate =   4 },
    ["altmer"]     = { intimidate =   2 },
    ["breton"]     = { intimidate =   0 },
    ["argonian"]   = { intimidate =  -2 },
    ["khajiit"]    = { intimidate =  -6 },
    ["t_els_cathay"]      = { intimidate =  -6 },
    ["t_els_cathay-raht"] = { intimidate =  -6 },
    ["t_els_ohmes"]       = { intimidate =  -6 },
    ["t_els_ohmes-raht"]  = { intimidate =  -6 },
    ["t_els_suthay"]      = { intimidate =  -6 },
    ["t_els_dagi-raht"]   = { intimidate =  -6 },
    ["bosmer"]     = { intimidate =  -8 },
}

-- ======================================================================================================
-- TIME OF DAY

M.TIME_BANDS = {
    -- start, end, label, fightMod, giveInMod
    { 0,  5,  "Exhausted", -10,  8 },  -- deep night
    { 5,  9,  "Energetic", 5,   -6 },  -- morning
    { 9,  17, "Alert", 10,  -8 },  -- midday
    { 17, 21, "Slightly Tired", -5,  6 },  -- evening
    { 21, 24, "Tired", -8,  8 },  -- late evening
}

-- ======================================================================================================
-- RECOMMENDATION LABELS

M.FIGHT_LABELS = {
    { 100, "Certain to attack"       },
    { 80, "Almost certain to attack" },
    { 60, "Highly likely to fight"   },
    { 40, "Might fight back"         },
    { 20, "Probably won't attack"    },
    {  0, "Unlikely to attack"       },
}

M.GIVEIN_LABELS = {
    { 100, "Certain to give in"           },
    { 80, "Will almost certainly give in" },
    { 60, "Likely to give in"             },
    { 40, "Might give in"                 },
    { 20, "Probably won't give in"        },
    {  0, "Unlikely to give in"           },
}

-- threshold-based descriptors for Alarm. Higher alarm means the NPC is jumpy and quick to react to nearby trouble. Shown for info only
M.ALARM_LABELS = {
    { 80, "Hair-trigger" },
    { 60, "Highly alert" },
    { 40, "Watchful"     },
    { 20, "Calm"         },
    {  0, "Oblivious"    },
}

M.CONFIDENCE_LABELS = {
    -- by levelDiff = npcLevel - playerLevel
    {  6, "Fearless" },
    {  3, "Confident" },
    { -2, "Calm" },
    { -5, "Nervous" },
    { -10, "Scared" },
}

-- ======================================================================================================
-- INFO REVEAL TIERS
-- score = (speechcraft + personality + intelligence) / 3
-- gates: name | caste | vigor | class | faction | mood | recommendation | numeric

M.REVEAL_TIERS = {
    name           =  0,
    caste          = 40,
    vigor          = 30,
    class          = 20,
    faction        = 50,
    mood           = 60,
    recommendation = 70,
    numeric        = 85,
}

-- ======================================================================================================
-- DROP RULES
-- equippable slots that may be given up

M.DROPPABLE_TYPES = {
    Apparatus = true,
    Book      = true,
    Clothing  = true,
    Ingredient = true,
    Lockpick   = true,
    Miscellaneous = true,
    Potion        = true,
    Probe         = true,
    Repair        = true,
    Armor         = true,
    Weapon        = true,
}

M.GOLD_IDS = {
    ["gold_001"] = true,
    ["gold_005"] = true,
    ["gold_010"] = true,
    ["gold_025"] = true,
    ["gold_100"] = true,
}

-- ======================================================================================================
-- WEAPON SKILL RESOLUTION
-- used to evaluate the equipped weapon's contribution to Fight

M.WEAPON_SKILL_BY_TYPE = {
    -- These match openmw.types.Weapon.TYPE values
    ShortBladeOneHand = "shortblade",
    LongBladeOneHand  = "longblade",
    LongBladeTwoHand  = "longblade",
    BluntOneHand      = "bluntweapon",
    BluntTwoClose     = "bluntweapon",
    BluntTwoWide      = "bluntweapon",
    SpearTwoWide      = "spear",
    AxeOneHand        = "axe",
    AxeTwoHand        = "axe",
    MarksmanBow       = "marksman",
    MarksmanCrossbow  = "marksman",
    MarksmanThrown    = "marksman",
    Arrow             = "marksman",
    Bolt              = "marksman",
}

-- ======================================================================================================
-- MESSAGES

M.MESSAGES_GIVE_IN = {
    "Take it! Just take it and go!",
    "Alright, alright, here. Don't hurt me!",
    "Fine. Have it. I want no trouble.",
    "Gods, just leave! Take what you want!",
    "Please... here. That's everything.",
}

M.MESSAGES_FIGHT = {
    "You picked the wrong one, s'wit!",
    "I'll see you in the dirt!",
    "Try it and die!",
    "You'll regret this!",
}

M.MESSAGES_HOLD = {
    "Get out of my face.",
    "I don't think so.",
    "You don't scare me.",
    "Walk away. Now.",
    "Try it. I dare you.",
}

M.MESSAGES_GIVE_IN_KHAJIIT = {
    "Take it! Take it and go, please!",
    "This one wants no trouble. Take what you want.",
    "Fine, fine. Have it. Just leave this one be.",
    "By the moons, just go! Take it all!",
    "Here. That is everything this one has.",
}

M.MESSAGES_FIGHT_KHAJIIT = {
    "This one will see you in the dirt!",
}

M.MESSAGES_HOLD_KHAJIIT = {
    "Out of this one's face.",
    "This one thinks not.",
    "You do not scare this one.",
    "Walk away. Now.",
    "Try it. This one dares you.",
}

M.MESSAGES_GUARD_HALT = {
    "Halt! You're under arrest. Surrender or face the consequences.",
    "Stop right there, criminal scum!",
    "You there! Halt in the name of the law!",
}

M.MESSAGES_NO_LOOT = {
    "They have nothing worth taking.",
    "Their pockets are empty.",
    "Not worth the trouble, they have nothing.",
}

M.MESSAGES_NO_LOOT_WEAPON_ONLY = {
    "Their pockets are empty, only a weapon, and they don't seem keen to part with it without a fight.",
    "Nothing on them but the blade in their hand. They won't hand that over peacefully.",
    "Empty purse, and the weapon they carry isn't coming off without bloodshed.",
}

-- Header line shown above the list of looted items on a successful robbery.
M.MESSAGES_LOOT_SUMMARY = {
    "Obtained:",
}

M.MESSAGES_LOOT_GOLD = "%d gold"

-- ======================================================================================================
-- VOICELINES (MercyCAO)
-- filename stems for MercyCAO's Mercy
-- races without entries (e.g. khajiit, bosmer, breton, redguard, altmer, argonian, imperial F) get no voiceline

M.VOICE_BASE_PATH = 'scripts/Bastard/voices/'
 
M.VOICELINES = {
    Mercy = {
        ['imperial'] = { male = { 'ImpMMercy1', 'ImpMMercy2', 'ImpMMercy3' } },
        ['orc']      = {
            male   = { 'OrcMMercy1', 'OrcMMercy2', 'OrcMMercy3' },
            female = { 'OrcFMercy1', 'OrcFMercy2', 'OrcFMercy3' },
        },
        ['nord'] = {
            male   = { 'NordMMercy1', 'NordMMercy2', 'NordMMercy3' },
            female = { 'NordFMercy1', 'NordFMercy2', 'NordFMercy3' },
        },
        ['dark elf'] = {
            male   = { 'DunMMercy1', 'DunMMercy2', 'DunMMercy3' },
            female = { 'DunFMercy1', 'DunFMercy2', 'DunFMercy3' },
        },
    },
    MercyDisarm = {
        ['imperial'] = { male = { 'ImpMMercyDisarm1', 'ImpMMercyDisarm2', 'ImpMMercyDisarm3' } },
        ['orc'] = {
            male   = { 'OrcMMercyDisarm1', 'OrcMMercyDisarm2', 'OrcMMercyDisarm3' },
            female = { 'OrcFMercyDisarm1', 'OrcFMercyDisarm2', 'OrcFMercyDisarm3' },
        },
        ['nord'] = {
            male   = { 'NordMMercyDisarm1', 'NordMMercyDisarm2', 'NordMMercyDisarm3' },
            female = { 'NordFMercyDisarm1', 'NordFMercyDisarm2', 'NordFMercyDisarm3',
                       'NordFMercyDisarm4', 'NordFMercyDisarm5', 'NordFMercyDisarm6' },
        },
        ['dark elf'] = {
            male   = { 'DunMMercyDisarm1', 'DunMMercyDisarm2', 'DunMMercyDisarm3' },
            female = { 'DunFMercyDisarm1', 'DunFMercyDisarm2', 'DunFMercyDisarm3' },
        },
    },
}

M.RACE_TO_VOICE_KEY = {
    ['dunmer']   = 'dark elf',
    ['imperial'] = 'imperial',
    ['nord']     = 'nord',
    ['orc']      = 'orc',
}

M.RACE_TO_MESSAGE_KEY = {
    ['khajiit']           = 'khajiit',
    ['t_els_cathay']      = 'khajiit',
    ['t_els_cathay-raht'] = 'khajiit',
    ['t_els_ohmes']       = 'khajiit',
    ['t_els_ohmes-raht']  = 'khajiit',
    ['t_els_suthay']      = 'khajiit',
    ['t_els_dagi-raht']   = 'khajiit',
}

-- ======================================================================================================
-- DEFAULT BASE PERCENTAGES PER CASTE
M.CLASS_BASE = {
    warrior  = { fight = 30, giveIn = 20 },
    commoner = { fight = 15, giveIn = 65 },
    mage     = { fight = 20, giveIn = 25 },
    noble    = { fight = 40, giveIn = 15 },
    guard    = { fight = 60, giveIn =  5 },
}

-- ======================================================================================================
-- DEFAULTS

M.DEFAULTS = {
    MOD_ENABLED      = true,
    LOG              = false,
    PLAY_VOICELINES  = true,
    SIMPLE_MODE      = false,
    GUARD_WITNESS_RADIUS = 300,
    THEFT_BOUNTY_BONUS = 60,
    VALUABLES_MIN = 1,
    VALUABLES_MAX = 3,
    DROP_GEAR_CHANCE   = 25,
    SHOW_LOOT_SUMMARY  = true,
    FATIGUE_WEIGHT   = 20,
    LEVEL_DIFF_WEIGHT = 4,
    LEVEL_DIFF_CAP    = 30,
    RANK_FIGHT_BONUS_PER_RANK = 3,
    RANK_FIGHT_BONUS_CAP = 25,
    COMBAT_DIVISOR  = 4,
    SOCIAL_DIVISOR  = 4,
}

return M