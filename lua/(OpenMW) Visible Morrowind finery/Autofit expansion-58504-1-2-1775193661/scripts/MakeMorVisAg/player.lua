local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local anim = require("openmw.animation")
local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local camera = require("openmw.camera")
local vfs = require("openmw.vfs")
local storage = require("openmw.storage")
local input = require("openmw.input")

local Actor, ctrls, ST = types.Actor, self.controls, types.Actor.STANCE
local MD = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }

local cam = camera.getMode()
local devMode = false

local equipped = {}
local items = { default = "meshes/c/c_ring_common05_skins.nif" }
local items = { default = "meshes/c/C_belt_Common_5_skins.nif" }

local L = {
    bbody = { first="BB", third="BB" },
    rbody = { first="RB", third="RB" },
    vbody = { first="VB", third="VS" },
    vsbr  = { first="VS", third="VS" },
    slim  = { first="50", third="45" },
    glove = { first="50", third="50" },
    mid55 = { first="60", third="55" },
    mid60 = { first="60", third="60" },
    wide  = { first="70", third="60" },
    wide70= { first="70", third="70" },
}

local offset = {
    bareHands = { first="50", third="50" },
    ["bm bear left gauntlet"]  = L.mid55,
    ["bm bear right gauntlet"] = L.mid55,
    bm_ice_gauntletl           = L.slim,
    bm_ice_gauntletr           = L.slim,
    bm_nordicmail_gauntletl    = L.slim,
    bm_nordicmail_gauntletr    = L.slim,
    ["bm wolf left gauntlet"]  = L.mid60,
    ["bm wolf right gauntlet"] = L.mid60,
    ["chitin guantlet - left"] = L.glove,
    ["chitin guantlet - right"]= L.glove,
    ["bonedancer gauntlet"]        = L.glove,
    ["boneweave gauntlet"]         = L.glove,
    ["left gauntlet of the horny fist"]  = L.glove,
    ["right gauntlet of the horny fist"] = L.glove,
    ["darkBrotherhood gauntlet_l"] = L.mid55,
    ["darkBrotherhood gauntlet_r"] = L.mid55,
    fur_gauntlet_left  = L.wide70,
    fur_gauntlet_right = L.wide70,
    gauntlet_of_glory_left  = L.wide70,
    gauntlet_of_glory_right = L.wide70,
    Helsethguard_gauntlet_left  = L.mid55,
    Helsethguard_gauntlet_right = L.mid55,
    ["imperial left gauntlet"]  = L.glove,
    ["imperial right gauntlet"] = L.glove,
    iron_gauntlet_left  = L.mid55,
    iron_gauntlet_right = L.mid55,
    ["indoril left gauntlet"]   = L.mid55,
    ["indoril right gauntlet"]  = L.mid55,
    indoril_mh_guard_gauntlet_l = L.mid55,
    indoril_mh_guard_gauntlet_r = L.mid55,
    indoril_almalexia_gauntlet_l= L.mid55,
    indoril_almalexia_gauntlet_r= L.mid55,
    netch_leather_gauntlet_left  = L.glove,
    netch_leather_gauntlet_right = L.glove,
    gauntlet_horny_fist_l = L.glove,
    gauntlet_horny_fist_r = L.glove,
    steel_gauntlet_left  = L.wide,
    steel_gauntlet_right = L.wide,
}

for k, v in pairs(L) do offset[k] = v end

-- ============================================================
-- Amulet / Belt size offsets — five tiers
-- ============================================================
local amuletOffset = {
    naked   = { first="46", third="46" },
    clothes = { first="48", third="48" },
    light   = { first="50", third="50" },
    medium  = { first="55", third="53" },
    heavy   = { first="62", third="58" },
}

local beltOffset = {
    naked   = { first="46", third="46" },
    clothes = { first="48", third="48" },
    light   = { first="50", third="50" },
    medium  = { first="55", third="53" },
    heavy   = { first="62", third="58" },
}

-- ============================================================
-- DEFAULT FALLBACK — iron cuirass (heavy tier)
-- Applied when a cuirass ID is not found anywhere in the lists.
-- Change "heavy" here to adjust the global unknown-armor default.
-- ============================================================
local DEFAULT_ARMOR_AMULET = amuletOffset.heavy
local DEFAULT_ARMOR_BELT   = beltOffset.heavy

-- ============================================================
-- EXACT cuirass record IDs → tier
-- All keys are lowercase to match :lower() comparisons.
-- Sources: Morrowind / Tribunal / Bloodmoon base armor tables
--          + Tamriel Rebuilt / Tamriel_Data naming scheme.
-- ============================================================
local cuirassExact = {
    -- ── VANILLA MORROWIND — HEAVY ───────────────────────────
    iron_cuirass                      = "heavy",
    ["iron cuirass"]                  = "heavy",
    steel_cuirass                     = "heavy",
    dwemer_cuirass                    = "heavy",
    daedric_cuirass                   = "heavy",
    ebony_cuirass                     = "heavy",
    imperial_steel_cuirass            = "heavy",
    imperial_templar_cuirass          = "heavy",
    silver_dukesguard_cuirass         = "heavy",
    lords_mail_unique                 = "heavy",
    dragonbone_cuirass_unique         = "heavy",
    ["chest of fire"]                 = "heavy",
    ["heart wall"]                    = "heavy",
    domina_cuirass                    = "heavy",

    -- ── VANILLA MORROWIND — MEDIUM ──────────────────────────
    bonemold_cuirass                  = "medium",
    ["armun-an bonemold cuirass"]     = "medium",
    ["gah-julan bonemold cuirass"]    = "medium",
    indoril_cuirass                   = "medium",
    orcish_cuirass                    = "medium",
    dreugh_cuirass                    = "medium",
    ebony_mail_unique                 = "medium",
    imperial_chain_cuirass            = "medium",
    imperial_dragonscale_cuirass      = "medium",
    imperial_silver_cuirass           = "medium",
    adamantium_cuirass                = "medium",
    gold_cuirass                      = "medium",
    indoril_mh_guard_cuirass          = "medium",
    indoril_almalexia_cuirass         = "medium",
    erurdan_cuirass                   = "medium",

    -- ── VANILLA MORROWIND — LIGHT ───────────────────────────
    chitin_cuirass                    = "light",
    netch_leather_cuirass             = "light",
    netch_leather_boiled_cuirass      = "light",
    glass_cuirass                     = "light",
    leather_cuirass                   = "light",
    imperial_studded_leather_cuirass  = "light",
    newtscale_cuirass                 = "light",
    ["cuirass of the savior's hide"]  = "light",
    saviors_hide_unique               = "light",

    -- ── TRIBUNAL — MEDIUM / LIGHT ───────────────────────────
    helsethguard_cuirass              = "medium",
    ["helseth guard cuirass"]         = "medium",
    royalguard_cuirass                = "medium",
    ["royal guard cuirass"]           = "medium",
    ["dark brotherhood cuirass"]      = "light",
    db_cuirass                        = "light",

    -- ── BLOODMOON — HEAVY ───────────────────────────────────
    bm_nordicmail_cuirass             = "heavy",
    ["bm nordic mail cuirass"]        = "heavy",
    bm_nordic_iron_cuirass            = "heavy",
    ["bm nordic iron cuirass"]        = "heavy",
    bm_trollbone_cuirass              = "heavy",
    ["bm trollbone cuirass"]          = "heavy",

    -- ── BLOODMOON — MEDIUM ──────────────────────────────────
    ["bm bear cuirass"]               = "medium",
    bm_bear_cuirass                   = "medium",
    ["bm wolf cuirass"]               = "medium",
    bm_wolf_cuirass                   = "medium",
    bm_ice_cuirass                    = "medium",
    ["bm ice cuirass"]                = "medium",
    stalhrim_cuirass                  = "medium",
    ["bm stalhrim cuirass"]           = "medium",
    ["bm snow bear cuirass"]          = "medium",
    ["bm snow wolf cuirass"]          = "medium",

    -- ── BLOODMOON — LIGHT ───────────────────────────────────
    bm_fur_cuirass                    = "light",
    ["bm fur cuirass"]                = "light",
    fur_cuirass                       = "light",
    fur_bearskin_cuirass              = "light",

    -- ── TAMRIEL REBUILT — LIGHT ─────────────────────────────
    ["t_de_netch_cuirass_01"]         = "light",
    ["t_de_netch_cuirass_02"]         = "light",
    ["t_de_chitin_cuirass_01"]        = "light",
    ["t_de_chitin_cuirass_02"]        = "light",
    ["t_de_redwatchchitin_cuirass_01"]= "light",
    ["t_de_redoranwatchman_cuirass"]  = "light",
    ["t_imp_newtscale_cuirass_01"]    = "light",
    ["t_imp_studded leather_cuirass_01"] = "light",
    ["t_arg_hist_cuirass_visitor"]    = "light",

    -- ── TAMRIEL REBUILT — MEDIUM ────────────────────────────
    ["t_de_bonemold_cuirass_01"]      = "medium",
    ["t_de_bonemold_cuirass_02"]      = "medium",
    ["t_de_redmastbonemold_cuirass_01"] = "medium",
    ["t_de_indoril_cuirass_01"]       = "medium",
    ["t_de_molecrab_cuirass_01"]      = "medium",
    ["t_de_dreugh_cuirass_01"]        = "medium",
    ["t_de_dreugh_cuirass_swim"]      = "medium",
    ["t_de_orcish_cuirass_01"]        = "medium",
    ["t_nor_guard_cuirass_01"]        = "medium",
    ["t_nor_ringmail_cuirass_01"]     = "medium",
    ["t_imp_chainmail_cuirass_01"]    = "medium",
    ["t_imp_dragonscale_cuirass_01"]  = "medium",

    -- ── TAMRIEL REBUILT — HEAVY ─────────────────────────────
    ["t_com_iron_cuirass_01"]         = "heavy",
    ["t_com_iron_cuirass_02"]         = "heavy",
    ["t_com_steel_cuirass_01"]        = "heavy",
    ["t_com_steel_cuirass_02"]        = "heavy",
    ["t_com_steel_cuirass_steelhearth"] = "heavy",
    ["t_dwe_cuirass_01"]              = "heavy",
    ["t_dwe_scavenged_cuirass_01"]    = "heavy",
    ["t_de_daedrichide_cuirass_01"]   = "heavy",
    ["t_he_direnni_cuirass_01"]       = "heavy",
    ["t_imp_steel_cuirass_01"]        = "heavy",
    ["t_nor_iron_cuirass_01"]         = "heavy",
    ["t_nor_iron_cuirass_wintery"]    = "heavy",
}

-- ============================================================
-- KEYWORD cuirass patterns (fallback after exact lookup)
-- Checked in order; first match wins.
-- ============================================================
local cuirassKeywords = {
    -- ── HEAVY ───────────────────────────────────────────────
    { "dragonbone",         "heavy" },
    { "lords_mail",         "heavy" },
    { "lord's mail",        "heavy" },
    { "lords mail",         "heavy" },
    { "herhand",            "heavy" },
    { "her_hand",           "heavy" },
    { "her hands",          "heavy" },
    { "nordic_mail",        "heavy" },
    { "nordicmail",         "heavy" },
    { "nordic mail",        "heavy" },
    { "bm_nordic",          "heavy" },
    { "nordic_iron",        "heavy" },
    { "nordic iron",        "heavy" },
    { "trollbone",          "heavy" },
    { "daedric",            "heavy" },
    { "dwemer",             "heavy" },
    { "dwe_",               "heavy" },
    { "ebony_c",            "heavy" },
	{ "ebon_plate_cuirass_unique", "heavy" },
	{ "ebon_",              "heavy" },
    { "imperial_templar",   "heavy" },
    { "imperial templar",   "heavy" },
    { "imperial_steel",     "heavy" },
    { "imperial steel",     "heavy" },
    { "imperial_dragon",    "heavy" },
    { "imperial dragon",    "heavy" },
    { "iron_cuirass",       "heavy" },
    { "iron cuirass",       "heavy" },
    { "t_com_iron",         "heavy" },
    { "t_nor_iron",         "heavy" },
    { "steel_cuirass",      "heavy" },
    { "steel cuirass",      "heavy" },
    { "t_com_steel",        "heavy" },
    { "templar",            "heavy" },
    { "silver_cuirass",     "heavy" },
    { "silver cuirass",     "heavy" },
    { "duke_guard",         "heavy" },
    { "duke guard",         "heavy" },
    { "dukesguard",         "heavy" },
    { "domina",             "heavy" },
    { "direnni",            "heavy" },
    { "t_he_",              "heavy" },

    -- ── MEDIUM ──────────────────────────────────────────────
    { "ebony_mail",         "medium" },
    { "indoril",            "medium" },
    { "mh_guard",           "medium" },
    { "almalexia",          "medium" },
    { "orcish",             "medium" },
    { "bonemold",           "medium" },
    { "armun",              "medium" },
    { "gah_julan",          "medium" },
    { "gah julan",          "medium" },
    { "gah-julan",          "medium" },
    { "imperial_chain",     "medium" },
    { "imperial chain",     "medium" },
    { "dragonscale",        "medium" },
    { "nordic_ringmail",    "medium" },
    { "nordic ringmail",    "medium" },
    { "ringmail",           "medium" },
    { "royal_guard",        "medium" },
    { "royalguard",         "medium" },
    { "helsethguard",       "medium" },
    { "helseth_guard",      "medium" },
    { "helseth guard",      "medium" },
    { "adamantium",         "medium" },
    { "dreugh",             "medium" },
    { "molecrab",           "medium" },
    { "gold_cuirass",       "medium" },
    { "gold cuirass",       "medium" },
    { "bm_bear",            "medium" },
    { "bm snow bear",       "medium" },
    { "bear cuirass",       "medium" },
    { "bm_wolf",            "medium" },
    { "bm snow wolf",       "medium" },
    { "wolf cuirass",       "medium" },
    { "stalhrim",           "medium" },
    { "bm_ice",             "medium" },
    { "bm ice",             "medium" },
    { "ice cuirass",        "medium" },
    { "t_nor_guard",        "medium" },
    { "t_nor_ringmail",     "medium" },
    { "t_imp_chainmail",    "medium" },
    { "t_imp_dragonscale",  "medium" },
    { "t_de_orcish",        "medium" },
    { "hist",               "medium" },

    -- ── LIGHT ───────────────────────────────────────────────
    { "glass",              "light"  },
    { "chitin",             "light"  },
    { "boiled_netch",       "light"  },
    { "boiled netch",       "light"  },
    { "netch_leather",      "light"  },
    { "netch",              "light"  },
    { "fur_bearskin",       "light"  },
    { "fur_cuirass",        "light"  },
    { "fur cuirass",        "light"  },
    { "fur_",               "light"  },
    { "newtscale",          "light"  },
    { "imperial_studded",   "light"  },
    { "imperial studded",   "light"  },
    { "studded leather",    "light"  },
    { "leather_cuirass",    "light"  },
    { "leather cuirass",    "light"  },
    { "db_cuirass",         "light"  },
    { "dark_brotherhood",   "light"  },
    { "dark brotherhood",   "light"  },
    { "savior",             "light"  },
    { "saviours",           "light"  },
    { "cultist",            "light"  },
    { "telvanni",           "light"  },
    { "smuggler",           "light"  },
    { "redwatchchitin",     "light"  },
    { "redoranwatchman",    "light"  },
    { "t_de_netch",         "light"  },
    { "t_de_chitin",        "light"  },
    { "t_imp_newtscale",    "light"  },
    { "t_arg_hist",         "light"  },
}

-- ============================================================
-- EXACT clothing record IDs
-- All keys are lowercase. Any match → "clothes" tier.
-- ============================================================
local clothingExact = {
    -- ── MORROWIND — SHIRTS ───────────────────────────────────
    shirt_common_01             = true,
    shirt_common_02             = true,
    shirt_common_03             = true,
    shirt_common_04             = true,
    shirt_expensive_01          = true,
    shirt_expensive_02          = true,
    shirt_expensive_03          = true,
    shirt_extravagant_01        = true,
    shirt_extravagant_02        = true,
    shirt_exquisite_01          = true,
    shirt_exquisite_02          = true,
    shirt_worn_01               = true,
    shirt_worn_02               = true,
    shirt_worn_03               = true,

    -- ── MORROWIND — ROBES ────────────────────────────────────
    robe_cheap_01               = true,
    robe_cheap_02               = true,
    robe_cheap_03               = true,
    robe_cheap_04               = true,
    robe_common_01              = true,
    robe_common_02              = true,
    robe_common_03              = true,
    robe_common_04              = true,
    robe_expensive_01           = true,
    robe_expensive_02           = true,
    robe_expensive_03           = true,
    robe_expensive_04           = true,
    robe_extravagant_01         = true,
    robe_extravagant_02         = true,
    robe_exquisite_01           = true,
    robe_exquisite_02           = true,

    -- ── MORROWIND — VESTS / MISC ─────────────────────────────
    vest_common_01              = true,
    vest_expensive_01           = true,
    vest_extravagant_01         = true,
    vest_exquisite_01           = true,
    velvet_shirt                = true,
    caius_pants                 = true,
    shirt_mudcrab_unique        = true,

    -- ── TRIBUNAL ─────────────────────────────────────────────
    trib_shirt_01               = true,
    tribunal_shirt_01           = true,
    shirt_ordinator_01          = true,
    shirt_ordinator_02          = true,
    robe_ordinator_01           = true,
    robe_mournhold_01           = true,
    robe_mournhold_02           = true,
    shirt_mournhold_01          = true,
    shirt_mournhold_02          = true,
    shirt_helseth_01            = true,
    robe_alta_01                = true,
    robe_alta_02                = true,

    -- ── BLOODMOON ────────────────────────────────────────────
    bm_shirt_01                 = true,
    bm_shirt_02                 = true,
    bm_robe_01                  = true,
    bm_robe_02                  = true,
    bm_shirt_skaal_01           = true,
    bm_robe_skaal_01            = true,
    bm_shirt_guard_01           = true,
    bm_shirt_legate_01          = true,
    bm_skaal_coat               = true,
    bm_shirt_huntsman           = true,

    -- ── TAMRIEL REBUILT ──────────────────────────────────────
    ["t_de_cm_robe_01"]         = true,
    ["t_de_cm_robe_02"]         = true,
    ["t_de_cm_robe_03"]         = true,
    ["t_de_cm_robe_04"]         = true,
    ["t_de_ep_robe_01"]         = true,
    ["t_de_ep_robe_02"]         = true,
    ["t_de_et_robe_01"]         = true,
    ["t_de_ex_robe_01"]         = true,
    ["t_de_ex_robenecrom_01"]   = true,
    ["t_de_cm_shirtind_01"]     = true,
    ["t_de_cm_shirtind_02"]     = true,
    ["t_nor_et_shirt_01"]       = true,
    ["t_nor_et_shirt_02"]       = true,
    ["t_imp_et_shirtcolwest_01"]= true,
    ["t_imp_et_shirtcolwest_02"]= true,
    ["t_de_shirtnecromordinator_01"] = true,
    ["t_com_shirtcm_01"]        = true,
    ["t_com_shirtcm_02"]        = true,
}

-- ============================================================
-- KEYWORD clothing patterns (fallback after exact lookup)
-- ============================================================
local clothesKeywords = {
    "shirt", "robe", "tunic", "dress", "vest", "coat",
    "common_", "expensive_", "extravagant_", "exquisite_",
    "colovian", "velvet", "worn",
    "t_de_cm_", "t_de_ep_", "t_de_et_", "t_de_ex_",
    "t_nor_et_", "t_imp_et_", "t_com_shirt", "t_de_shirt",
}

local function getCuirassSize(cuirassObj, shirtObj)
    if cuirassObj then
        local id = cuirassObj.recordId:lower()

        -- 1. Exact ID
        local tier = cuirassExact[id]
        if tier then
            return amuletOffset[tier], beltOffset[tier]
        end

        -- 2. Keyword scan
        for _, entry in ipairs(cuirassKeywords) do
            if id:find(entry[1], 1, true) then
                return amuletOffset[entry[2]], beltOffset[entry[2]]
            end
        end

        -- 3. Not found anywhere → always heavy (iron cuirass default)
        return DEFAULT_ARMOR_AMULET, DEFAULT_ARMOR_BELT
    end

    if shirtObj then
        local id = shirtObj.recordId:lower()
        if clothingExact[id] then
            return amuletOffset.clothes, beltOffset.clothes
        end
        for _, kw in ipairs(clothesKeywords) do
            if id:find(kw, 1, true) then
                return amuletOffset.clothes, beltOffset.clothes
            end
        end
        return amuletOffset.clothes, beltOffset.clothes
    end

    return amuletOffset.naked, beltOffset.naked
end

-- ─────────────────────────────────────────────────────────────────────────────

L = {
    fallback = {
        { "brace",      offset.bareHands },
        { "chitin",     offset.glove     },
        { "netch",      offset.glove     },
        { "daedric",    offset.glove     },
        { "guardtown1", offset.mid55     },
        { "iron",       offset.mid55     },
        { "steel",      offset.wide      },
        { "glove",      offset.glove     },
        { "helsethguard", offset.mid55   },
        { "bear",       offset.mid55     },
        { "wolf",       offset.mid60     },
        { "_ice_",      offset.slim      },
        { "nordicmail", offset.slim      },
        { "imperial",   offset.glove     },
        { "indoril",    offset.mid55     },
    },
    uiModes = { [I.UI.MODE.Rest] = true, [I.UI.MODE.Training] = true, [I.UI.MODE.Travel] = true },
    vfxItem = { loop=true, useAmbientLight=false, vfxId="visibleItems" },
}

L.getGlove = function(o)
    local sizes
    if o.type ~= types.Armor then
        if devMode then print("NOT ARMOR") end
        sizes = offset.glove
        offset[o.recordId] = sizes
        return sizes
    end
    for _, v in ipairs(L.fallback) do
        local i, j = table.unpack(v)
        if o.recordId:find(i) then sizes = j    break end
    end
    if not sizes then sizes = offset.glove end
    offset[o.recordId] = sizes
    return sizes
end

L.getItem = function(o)
    local id = o.recordId
    local model = o.type.records[id].model:lower()
    model = model:gsub("_gnd%.nif$", ".nif")
    model = model:gsub("%.nif$", "_skins.nif")
    if not vfs.fileExists(model) then
        if devMode then print("No visible model for "..model) end
        model = ""
    end
    items[id] = model
    return model
end

local function debug(m)
    if devMode then
        print(m)
        ui.showMessage(m)
    end
end

local settings = storage.playerSection("Settings_tt_visiblefinery")
local frameSkip, onlyHands
local counter, refresh

local function updateSettings()
    frameSkip = settings:get("frameSkip") or 20
    onlyHands = settings:get("bareHandsOnly")
    NoRings = settings:get("ShowRings")
    NoBelts = settings:get("ShowBelts")
    NoAmulets = settings:get("ShowAmulets")
    local model = settings:get("defaultModel")
    local Bmodel = settings:get("defaultBelt")
    local Amodel = settings:get("defaultAmulet")
    if type(model) == "string" and vfs.fileExists(model) then
        L.defaultModel = model
    else
        L.defaultModel = nil
    end
    if type(Bmodel) == "string" and vfs.fileExists(Bmodel) then
        L.defaultModelB = Bmodel
    else
        L.defaultModelB = nil
    end
    if type(Amodel) == "string" and vfs.fileExists(Amodel) then
        L.defaultModelA = Amodel
    else
        L.defaultModelA = nil
    end
    local b, rec = types.NPC.records[self.recordId].isMale and settings:get("bodyReplacer")
        or settings:get("bodyReplacer_f")
    if b == "opt_better" then
        rec = offset.bbody
    elseif b == "opt_robert" then
        rec = offset.rbody
    elseif b == "opt_vsbr" then
        rec = offset.vsbr
    else
        rec = offset.vbody
    end
    offset.bareHands.first = rec.first
    offset.bareHands.third = rec.third
    counter = math.random(3, 20)
    refresh = true
end

settings:subscribe(async:callback(updateSettings))
updateSettings()

local function addRingVfx(o, bone, hand)
    local model = items[o.recordId] or L.getItem(o)
    if model == "" then
        if devMode then print(model, "USE DEFAULT") end
        model = L.defaultModel
        if not model then return end
    end
    local id = hand and hand.recordId or "bareHands"
    local sizes = offset[id] or L.getGlove(hand)
    if NoRings then return end
    if onlyHands and sizes ~= offset.bareHands then return end
    local view = (cam == MD.first and "first") or "third"
    if devMode then print(sizes[view], id) end
    debug(model.." add ring vfx")
    L.vfxItem.boneName = bone .. " " .. sizes[view]
    anim.addVfx(self, model, L.vfxItem)
end

local scanSlots = {
    Actor.EQUIPMENT_SLOT.LeftRing,
    Actor.EQUIPMENT_SLOT.RightRing,
    Actor.EQUIPMENT_SLOT.LeftGauntlet,
    Actor.EQUIPMENT_SLOT.RightGauntlet,
    Actor.EQUIPMENT_SLOT.Amulet,
    Actor.EQUIPMENT_SLOT.Belt,
    Actor.EQUIPMENT_SLOT.Cuirass,
    Actor.EQUIPMENT_SLOT.Shirt,
}

local newEquip = false

local function scanInv(reset)
    newEquip = false
    refresh = false
    local e, f = Actor.getEquipment(self)
    local eq = equipped
    for _, v in ipairs(scanSlots) do
        if eq[v] ~= e[v] then f = true    eq[v] = e[v] end
    end
    if not f and not reset then return end
    debug("remove items vfx")
    anim.removeVfx(self, "visibleItems")
    local l, r, lG, rG, a, b, c, s = table.unpack(scanSlots)

    -- Rings
    if eq[l] then addRingVfx(eq[l], "Ring L Finger1", eq[lG]) end
    if eq[r] then addRingVfx(eq[r], "Ring R Finger1", eq[rG]) end

    if cam == MD.first then return end

    local view = "third"
    local amuletSize, beltSize = getCuirassSize(eq[c], eq[s])

    -- Amulet
    if eq[a] then
        local model = items[eq[a].recordId] or L.getItem(eq[a])
        if not NoAmulets then
            if model == "" then model = L.defaultModelA end
            if model then
                L.vfxItem.boneName = "Necklace " .. amuletSize[view]
                anim.addVfx(self, model, L.vfxItem)
            end
        end
    end

    -- Belt
    if eq[b] then
        local model = items[eq[b].recordId] or L.getItem(eq[b])
        if not NoBelts then
            if model == "" then model = L.defaultModelB end
            if model then
                L.vfxItem.boneName = "waist " .. beltSize[view]
                anim.addVfx(self, model, L.vfxItem)
            end
        end
    end
end

local useHelper = false

local function onFrame(dt)
    if newEquip then scanInv(refresh) end
    counter = counter - 1
    if counter > 0 then return end
    counter = frameSkip
    if refresh or not useHelper then scanInv(refresh) end
end

local function onUpdate(dt)
    if dt == 0 then return end
    if cam == camera.getMode() then return end
    local mode, fp = camera.getMode(), MD.first
    if mode == fp or cam == fp then
        cam = mode    counter = 3    refresh = true
    end
    cam = mode
end

return {
    engineHandlers = { onUpdate = onUpdate, onFrame = onFrame },
    eventHandlers = {
        UiModeChanged = function(e)
            if L.uiModes[e.oldMode] then
                counter = 3
                refresh = true
            end
        end,
        olhInitialized = function()
            if frameSkip ~= 20 then return end
            if not useHelper then
                useHelper = true
                I.luaHelper.eventRegister("equipped",   function() newEquip = true end)
                I.luaHelper.eventRegister("unequipped", function() newEquip = true end)
            end
        end,
        vfxRemoveAll = function() counter = math.random(3, 8)    refresh = true end
    },
}