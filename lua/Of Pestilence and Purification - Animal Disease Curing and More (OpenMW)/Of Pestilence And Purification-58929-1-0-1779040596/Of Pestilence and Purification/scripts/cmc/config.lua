local M = {}

M.version = '1.0.8d'

M.spells = {
    purifyBeast = 'cmc_purify_beast',
    spreadCommon = 'cmc_spread_common_disease',
    peryiteGift = 'cmc_peryites_gift',
    spreadBlight = 'cmc_spread_blight_disease',
    dagothCompassion = 'cmc_dagoths_compassion',
    contagionFeverbite = 'cmc_contagion_feverbite',
    contagionDamage = 'cmc_contagion',
    contagionPlagueburst = 'cmc_contagion_plagueburst',

    mercyBlightBane = 'cmc_mercy_blight_bane',
    mercyCleansingRay = 'cmc_mercy_cleansing_ray',
    mercyPurifyingStorm = 'cmc_mercy_purifying_storm',

    mercyKindred = 'cmc_mercy_kindred_trait',
    mercyWarden = 'cmc_mercy_warden_trait',
    mercyPlaguebreaker = 'cmc_mercy_plaguebreaker_trait',

    peryiteCarrier = 'cmc_peryite_carrier_trait',
    peryiteVotary = 'cmc_peryite_votary_trait',
    peryiteVector = 'cmc_peryite_vector_trait',
    peryiteOrderedPestilence = 'cmc_peryite_ordered_pestilence',

    blightCarrier = 'cmc_blight_carrier_trait',
    redDreamer = 'cmc_red_dreamer_trait',
    ashstormApostle = 'cmc_ashstorm_apostle_trait',
    ashPlume = 'cmc_ash_plume',
    ashstormCommunion = 'cmc_ashstorm_communion',

    commonAfflictionBoost1 = 'cmc_common_affliction_boost_1',
    commonAfflictionBoost2 = 'cmc_common_affliction_boost_2',
    commonAfflictionBoost3 = 'cmc_common_affliction_boost_3',
    blightAfflictionBoost1 = 'cmc_blight_affliction_boost_1',
    blightAfflictionBoost2 = 'cmc_blight_affliction_boost_2',
    blightAfflictionBoost3 = 'cmc_blight_affliction_boost_3',
}

M.effects = {
    spreadCommon = 'cmc_spread_common_disease_effect',
    spreadBlight = 'cmc_spread_blight_disease_effect',
    antiBlight = 'cmc_anti_blight_damage_effect',
    contagionResistDamage = 'cmc_contagion_resist_damage_effect',
    blightResistDamage = 'cmc_blight_resist_damage_effect',
    cureCommon = 'cmc_purify_common_disease_effect',
    cureBlight = 'cmc_purify_blight_disease_effect',
    nativeCureCommon = 'curecommondisease',
    nativeCureBlight = 'cureblightdisease',
    weaknessCommon = 'weaknesstocommondisease',
    weaknessBlight = 'weaknesstoblightdisease',
}

M.settingsDefaults = {
    autoLearnBaseSpells = false,
    showMessages = true,
    integrateSpellMerchants = true,
    integrateSpellTomes = true,
    enableRewardUnlocks = true,
    enableDreamMessages = true,
    enableCarrierTraits = true,
    enableAntiBlightDamage = true,
    enableAreaSpreadRewards = true,
    enableSpeciesFriendship = true,
    enableAnimalAllies = true,
    enablePathConflict = true,
    rewardThreshold1 = 10,
    rewardThreshold2 = 20,
    rewardThreshold3 = 30,
    debugMessages = false,
    debugDamageMessages = false,
}

M.thresholds = {
    reward1 = 10,
    reward2 = 20,
    reward3 = 30,
    speciesFriendship = 20,
    cureAllyChance = 10,
    contagionAllyChance = 20,
    blightAllyChance = 20,
    allyFollowMinHours = 2,
    allyFollowMaxHours = 6,

    -- Performance tuning. Actor scripts still resolve real active magic effects,
    -- but they poll less aggressively and the harmless OPP carrier effects last
    -- long enough to remain detectable between polls.
    effectScanInterval = 0.50,
    effectCarrierDuration = 2,
    playerAfflictionScanInterval = 1.00,
    speciesFriendshipPollInterval = 10.00,
}

-- Healthy creature records from some creature packs run one-shot MWScript spawn
-- events for babies, pups, herds, or nearby predators on first update. Curing a
-- diseased/blighted animal into one of those records should not replay that
-- wilderness-population event. The global script dynamically clones affected
-- healthy records with mwscript cleared and uses those clones only for cure
-- replacements.
M.cureSpawnScriptIds = {
    ttooth_alit_spawns = true,
    ttooth_bearb_spawns = true,
    ttooth_bearp_spawns = true,
    ttooth_boar_spawns = true,
    ttooth_guar_spawns = true,
    ttooth_horker_spawns = true,
    ttooth_kagouti_spawns = true,
    ttooth_netch_spawns = true,
    ttooth_nix_spawns = true,
    ttooth_wolfg_spawns = true,
    ttooth_wolfr_spawns = true,
    plx_spawn_babyguar = true,
    plx_spawn_babyguarwild = true,
    plx_spawn_babynetch = true,
    plx_babynetch = true,
    plx_spawn_herdofguars = true,
    plx_spawn_herdofshalks = true,
    plx_spawn_shalkherd = true,
    plx_spawn_nixpup = true,
}

-- Each entry is { healthy record id, infected/blighted record id }.
-- Multiple candidates for a healthy record are allowed; the global script picks
-- the first candidate that exists in the current load order. The explicit lists
-- cover vanilla/official IDs and known Tamriel Data/OAAB-style IDs. Heuristic
-- suffix matching in global.lua covers many additional TR/PT/OAAB variants.
M.commonPairs = {
    -- Vanilla / official expansions.
    { 'alit', 'alit_diseased' },
    { 'cliff racer', 'cliff racer_diseased' },
    { 'durzog', 'durzog_diseased' },
    { 'kagouti', 'kagouti_diseased' },
    { 'kwama worker', 'kwama worker diseased' },
    { 'mudcrab', 'mudcrab-diseased' },
    { 'rat', 'rat_diseased' },
    { 'scrib', 'scrib diseased' },
    { 'shalk', 'shalk_diseased' },
    { 'shalk', 'shalk_diseased_hram' },

    -- Extra harmless candidates for common community naming patterns.
    { 'kwama forager', 'kwama forager diseased' },
    { 'kwama warrior', 'kwama warrior diseased' },
    { 'kwama queen', 'kwama queen diseased' },
    { 'netch_betty', 'netch_betty_diseased' },
    { 'netch_bull', 'netch_bull_diseased' },
    { 'nix-hound', 'nix-hound_diseased' },
    { 'guar', 'guar_diseased' },

    -- Tamriel Data / OAAB-style IDs seen in current creature packs.
    { 'guar', 't_mw_fau_guards_01' },
    { 't_mw_fau_guar_01', 't_mw_fau_guards_01' },
    { 't_mw_fau_guarfr_01', 't_mw_fau_guarfrds_01' },
    { 't_mw_fau_beetlebl_01', 't_mw_fau_beetleblds_01' },
    { 't_mw_fau_beetlebr_01', 't_mw_fau_beetlebrds_01' },
    { 't_mw_fau_beetlegr_01', 't_mw_fau_beetlegrds_01' },
    { 't_mw_fau_beetlehr_01', 't_mw_fau_beetlehrds_01' },
    { 't_mw_fau_thresher_01', 't_mw_fau_thresherds_01' },
    { 'kwama worker', 't_mw_fau_kwawrds_01' },
    { 'kwama forager', 't_mw_fau_kwafrgds_01' },
    { 'kwama queen', 't_mw_fau_kwaqnds_01' },
    { 't_mw_fau_molec_01', 't_mw_fau_molecds_01' },
    { 'netch_betty', 't_mw_fau_netbtyds_01' },
    { 'netch_bull', 't_mw_fau_netblds_01' },
    { 'nix-hound', 't_mw_fau_nixhds_01' },
    { 't_mw_fau_para_01', 't_mw_fau_parads_01' },
    { 'rat', 't_glb_fau_ratds_01' },
    { 't_mw_fau_sharaihoppe_01', 't_mw_fau_sharaihopds_01' },
}

M.blightPairs = {
    -- Vanilla blighted creature families.
    { 'alit', 'alit_blighted' },
    { 'cliff racer', 'cliff racer_blighted' },
    { 'kagouti', 'kagouti_blighted' },
    { 'kwama forager', 'kwama forager blighted' },
    { 'kwama queen', 'kwama queen blighted' },
    { 'kwama warrior', 'kwama warrior blighted' },
    { 'kwama worker', 'kwama worker blighted' },
    { 'nix-hound', 'nix-hound blighted' },
    { 'rat', 'rat_blighted' },
    { 'scrib', 'scrib blighted' },
    { 'shalk', 'shalk_blighted' },

    -- Extra harmless candidates for community naming patterns.
    { 'guar', 'guar_blighted' },
    { 'mudcrab', 'mudcrab_blighted' },
    { 'durzog', 'durzog_blighted' },
    { 'netch_betty', 'netch_betty_blighted' },
    { 'netch_bull', 'netch_bull_blighted' },
}

-- Groups multiple healthy records under a player-facing animal family for
-- species-friendship unlocks.
M.familyAliases = {
    ['t_mw_fau_guar_01'] = 'guar',
    ['t_mw_fau_guarfr_01'] = 'guar',
    ['t_mw_fau_guards_01'] = 'guar',
    ['t_mw_fau_guarfrds_01'] = 'guar',

    ['t_mw_fau_beetlebl_01'] = 'beetle',
    ['t_mw_fau_beetlebr_01'] = 'beetle',
    ['t_mw_fau_beetlegr_01'] = 'beetle',
    ['t_mw_fau_beetlehr_01'] = 'beetle',
    ['t_mw_fau_beetleblds_01'] = 'beetle',
    ['t_mw_fau_beetlebrds_01'] = 'beetle',
    ['t_mw_fau_beetlegrds_01'] = 'beetle',
    ['t_mw_fau_beetlehrds_01'] = 'beetle',

    ['netch_betty'] = 'netch',
    ['netch_bull'] = 'netch',
    ['t_mw_fau_netbtyds_01'] = 'netch',
    ['t_mw_fau_netblds_01'] = 'netch',

    ['t_mw_fau_para_01'] = 'parasitic beetle',
    ['t_mw_fau_parads_01'] = 'parasitic beetle',
    ['t_mw_fau_molec_01'] = 'mole crab',
    ['t_mw_fau_molecds_01'] = 'mole crab',
    ['t_mw_fau_thresher_01'] = 'thresher',
    ['t_mw_fau_thresherds_01'] = 'thresher',
    ['t_mw_fau_sharaihoppe_01'] = 'sharai hopper',
    ['t_mw_fau_sharaihopds_01'] = 'sharai hopper',
}

M.familyDisplayNames = {
    ['alit'] = 'Alit',
    ['beetle'] = 'Beetles',
    ['cliff racer'] = 'Cliff Racers',
    ['durzog'] = 'Durzogs',
    ['guar'] = 'Guar',
    ['kagouti'] = 'Kagouti',
    ['kwama forager'] = 'Kwama Foragers',
    ['kwama queen'] = 'Kwama Queens',
    ['kwama warrior'] = 'Kwama Warriors',
    ['kwama worker'] = 'Kwama Workers',
    ['mole crab'] = 'Mole Crabs',
    ['mudcrab'] = 'Mudcrabs',
    ['netch'] = 'Netch',
    ['nix-hound'] = 'Nix-Hounds',
    ['parasitic beetle'] = 'Parasitic Beetles',
    ['rat'] = 'Rats',
    ['scrib'] = 'Scribs',
    ['shalk'] = 'Shalk',
    ['sharai hopper'] = 'Sharai Hoppers',
    ['thresher'] = 'Threshers',
}

M.rewardPaths = {
    mercy = 'mercy',
    disease = 'disease',
    blight = 'blight',
}

M.rewardDefs = {
    {
        id = 'mercy_1', path = 'mercy', threshold = 10,
        title = 'Kindred of the Afflicted',
        message = 'You have become Kindred of the Afflicted. Your mercy blesses those in need.',
        dream = 'You dream of a guar calf drinking greedily from a stream of clean water. It appears to smile back at you.',
        spells = { 'cmc_mercy_kindred_trait' },
    },
    {
        id = 'mercy_2', path = 'mercy', threshold = 20,
        title = 'Warden of the Stricken',
        message = 'You have become Warden of the Stricken. You fear no disease.',
        dream = 'In your sleep, you witness a family of Alit embrace each other in the verdant plains of the Grazelands.',
        spells = { 'cmc_mercy_warden_trait' },
    },
    {
        id = 'mercy_3', path = 'mercy', threshold = 30,
        title = 'Plaguebreaker',
        message = 'You have become a breaker of plagues and suffer not the presence of pestilence.',
        dream = 'You dream of red blight and weeping sores disappearing beneath the cleansing force of the rain. Diseased beasts gather around you and lower their heads in thanks.',
        spells = { 'cmc_mercy_plaguebreaker_trait' },
    },
    {
        id = 'disease_1', path = 'disease', threshold = 10,
        title = 'Vector of Peryite',
        message = 'You have become a Vector of Peryite. Blight falters before you, while common disease finds easier purchase, as is only natural.',
        dream = 'You dream of a coiled shape endlessly tallying every cough, every fever, every afflicted failure of flesh.',
        spells = { 'cmc_peryite_carrier_trait' },
    },
    {
        id = 'disease_2', path = 'disease', threshold = 20,
        title = "Harbinger of Plague",
        message = "You have become Peryite's Harbinger of Plague. Sickness invigorates you further.",
        dream = "In your sleep, you come to understand that disease is not an ending. It's only the beginning.",
        spells = { 'cmc_peryite_votary_trait' },
    },
    {
        id = 'disease_3', path = 'disease', threshold = 30,
        title = "Peryite's Herald",
        message = "You have earned your place as Peryite's Herald. Affliction must be spread. The non-believers will come to see the truth.",
        dream = "You dream yourself digging in the sand. Suddenly you realize that each grain is its own unique and perfected illness. Frantically, you dig faster and deeper in order to obtain for yourself the ultimate disease. You awake before you can reach it...",
        spells = { 'cmc_peryite_vector_trait' },
    },
    {
        id = 'blight_1', path = 'blight', threshold = 10,
        title = 'Blighted Advocate',
        message = 'You have become an advocate of Blight. Common diseases wither before you, while blight now finds easier purchase.',
        dream = "You dream of a fine and almost invisible red haze moving back and forth gently throughout the land, as if under the influence of a giant's breath. Something vast approves of your recent actions.",
        spells = { 'cmc_blight_carrier_trait' },
    },
    {
        id = 'blight_2', path = 'blight', threshold = 20,
        title = 'Miasmatist of Blight',
        message = 'You have become the Miasmatist of Blight. You must share these blessings with all around you.',
        dream = "In sleep, you stand beneath Red Mountain. You don't recognise the room you are in, but you know you are home.",
        spells = { 'cmc_red_dreamer_trait' },
    },
    {
        id = 'blight_3', path = 'blight', threshold = 30,
        title = 'Apostle of the Blessed Ashstorm',
        message = 'You are the Apostle of the Blessed Ashstorm. The storm recognizes what it has made, and it instructs you on what must be done next.',
        dream = "The Dreamer is awake. He greets you in your own as an old friend. The two of you traverse a land that you don't quite recognize. Yet in your corrupted heart it feels oddly familiar as the two of you set to rule over it.",
        spells = { 'cmc_ashstorm_apostle_trait' },
    },
}

M.rewardById = {}
for _, reward in ipairs(M.rewardDefs) do
    M.rewardById[reward.id] = reward
end

function M.sanitizeRewardThresholds(settings)
    settings = settings or {}
    local t1 = math.floor(tonumber(settings.rewardThreshold1 or M.settingsDefaults.rewardThreshold1 or M.thresholds.reward1) or 10)
    local t2 = math.floor(tonumber(settings.rewardThreshold2 or M.settingsDefaults.rewardThreshold2 or M.thresholds.reward2) or 20)
    local t3 = math.floor(tonumber(settings.rewardThreshold3 or M.settingsDefaults.rewardThreshold3 or M.thresholds.reward3) or 30)
    t1 = math.max(1, math.min(9999, t1))
    t2 = math.max(t1, math.min(9999, t2))
    t3 = math.max(t2, math.min(9999, t3))
    return t1, t2, t3
end

function M.rewardThreshold(reward, settings)
    if not reward then return 0 end
    local t1, t2, t3 = M.sanitizeRewardThresholds(settings)
    local suffix = tostring(reward.id or ''):match('_(%d+)$')
    if suffix == '1' then return t1 end
    if suffix == '2' then return t2 end
    if suffix == '3' then return t3 end
    return tonumber(reward.threshold) or 0
end

function M.thresholdLabel(settings)
    local t1, t2, t3 = M.sanitizeRewardThresholds(settings)
    return tostring(t1) .. '/' .. tostring(t2) .. '/' .. tostring(t3)
end


M.spellTags = {
    cmc_mercy_kindred_trait = 'carrier',
    cmc_mercy_warden_trait = 'carrier',
    cmc_mercy_plaguebreaker_trait = 'carrier',
    cmc_mercy_blight_bane = 'antiBlight',
    cmc_mercy_cleansing_ray = 'antiBlight',
    cmc_mercy_purifying_storm = 'antiBlight',
    cmc_peryite_carrier_trait = 'carrier',
    cmc_peryite_votary_trait = 'carrier',
    cmc_peryite_vector_trait = 'carrier',
    cmc_blight_carrier_trait = 'carrier',
    cmc_red_dreamer_trait = 'carrier',
    cmc_ashstorm_apostle_trait = 'carrier',
    cmc_common_affliction_boost_1 = 'carrier',
    cmc_common_affliction_boost_2 = 'carrier',
    cmc_common_affliction_boost_3 = 'carrier',
    cmc_blight_affliction_boost_1 = 'carrier',
    cmc_blight_affliction_boost_2 = 'carrier',
    cmc_blight_affliction_boost_3 = 'carrier',
    cmc_peryites_gift = 'areaSpread',
    cmc_peryite_ordered_pestilence = 'areaSpread',
    cmc_contagion_feverbite = 'contagion',
    cmc_contagion = 'resistDamage',
    cmc_contagion_plagueburst = 'areaSpread',
    cmc_dagoths_compassion = 'areaSpread',
    cmc_ash_plume = 'resistDamage',
    cmc_ashstorm_communion = 'areaSpread',
}

M.antiBlightDamage = {
    cmc_mercy_blight_bane = 25,
    cmc_mercy_cleansing_ray = 50,
    cmc_mercy_purifying_storm = 80,
}


M.resistScaledDamage = {
    cmc_contagion_feverbite = 10,
    cmc_contagion = 35,
    cmc_contagion_plagueburst = 20,
    cmc_ash_plume = 70,
    cmc_ashstorm_communion = 40,
}

M.resistScaledDamageKindBySpell = {
    cmc_contagion_feverbite = 'common',
    cmc_contagion = 'common',
    cmc_contagion_plagueburst = 'common',
    cmc_ash_plume = 'blight',
    cmc_ashstorm_communion = 'blight',
}

M.worldSpellOrder = {
    'cmc_purify_beast',
    'cmc_spread_common_disease',
    'cmc_peryites_gift',
    'cmc_spread_blight_disease',
    'cmc_dagoths_compassion',
    'cmc_contagion_feverbite',
    'cmc_contagion',
    'cmc_contagion_plagueburst',
    'cmc_mercy_blight_bane',
    'cmc_mercy_cleansing_ray',
    'cmc_mercy_purifying_storm',
    'cmc_peryite_ordered_pestilence',
    'cmc_ash_plume',
    'cmc_ashstorm_communion',
}

M.consoleSpellOrder = {}
for _, id in ipairs(M.worldSpellOrder) do table.insert(M.consoleSpellOrder, id) end

M.consoleSpellAliases = {
    purify = 'cmc_purify_beast',
    cure = 'cmc_purify_beast',
    disease = 'cmc_spread_common_disease',
    spreadcommon = 'cmc_spread_common_disease',
    common = 'cmc_spread_common_disease',
    gift = 'cmc_peryites_gift',
    peryitesgift = 'cmc_peryites_gift',
    blight = 'cmc_spread_blight_disease',
    spreadblight = 'cmc_spread_blight_disease',
    compassion = 'cmc_dagoths_compassion',
    dagothscompassion = 'cmc_dagoths_compassion',
    feverbite = 'cmc_contagion_feverbite',
    fever = 'cmc_contagion_feverbite',
    contagion = 'cmc_contagion',
    plagueburst = 'cmc_contagion_plagueburst',
    plague = 'cmc_contagion_plagueburst',
    mercy = 'cmc_mercy_blight_bane',
    rebuke = 'cmc_mercy_blight_bane',
    cleansing = 'cmc_mercy_cleansing_ray',
    ray = 'cmc_mercy_cleansing_ray',
    storm = 'cmc_mercy_purifying_storm',
    purifyingstorm = 'cmc_mercy_purifying_storm',
    peryite = 'cmc_peryite_ordered_pestilence',
    ordered = 'cmc_peryite_ordered_pestilence',
    orderedpestilence = 'cmc_peryite_ordered_pestilence',
    ashplume = 'cmc_ash_plume',
    ashstorm = 'cmc_ashstorm_communion',
    communion = 'cmc_ashstorm_communion',
}

M.rewardTraitSpellOrder = {
    'cmc_mercy_kindred_trait',
    'cmc_mercy_warden_trait',
    'cmc_mercy_plaguebreaker_trait',
    'cmc_peryite_carrier_trait',
    'cmc_peryite_votary_trait',
    'cmc_peryite_vector_trait',
    'cmc_blight_carrier_trait',
    'cmc_red_dreamer_trait',
    'cmc_ashstorm_apostle_trait',
}

M.tomeDefs = {
    { tomeId = 'cmc_tome_purify_beast', name = 'Spell Tome: Purify Beast', spells = { 'cmc_purify_beast' }, message = 'You learn Purify Beast.' },
    { tomeId = 'cmc_tome_spread_common_disease', name = 'Spell Tome: Spread Common Disease', spells = { 'cmc_spread_common_disease' }, message = 'You learn Spread Common Disease.' },
    { tomeId = 'cmc_tome_peryites_gift', name = "Spell Tome: Peryite's Gift", spells = { 'cmc_peryites_gift' }, message = "You learn Peryite's Gift." },
    { tomeId = 'cmc_tome_spread_blight_disease', name = 'Spell Tome: Spread Blight Disease', spells = { 'cmc_spread_blight_disease' }, message = 'You learn Spread Blight Disease.' },
    { tomeId = 'cmc_tome_dagoths_compassion', name = "Spell Tome: Dagoth's Compassion", spells = { 'cmc_dagoths_compassion' }, message = "You learn Dagoth's Compassion." },
    { tomeId = 'cmc_tome_contagion_feverbite', name = 'Spell Tome: Contagion: Feverbite', spells = { 'cmc_contagion_feverbite' }, message = 'You learn Contagion: Feverbite.' },
    { tomeId = 'cmc_tome_contagion', name = 'Spell Tome: Contagion', spells = { 'cmc_contagion' }, message = 'You learn Contagion.' },
    { tomeId = 'cmc_tome_contagion_plagueburst', name = 'Spell Tome: Contagion: Plagueburst', spells = { 'cmc_contagion_plagueburst' }, message = 'You learn Contagion: Plagueburst.' },
    { tomeId = 'cmc_tome_mercy_blight_bane', name = "Spell Tome: Mercy's Rebuke", spells = { 'cmc_mercy_blight_bane' }, message = "You learn Mercy's Rebuke." },
    { tomeId = 'cmc_tome_cleansing_ray', name = 'Spell Tome: Cleansing Ray', spells = { 'cmc_mercy_cleansing_ray' }, message = 'You learn Cleansing Ray.' },
    { tomeId = 'cmc_tome_purifying_storm', name = 'Spell Tome: Purifying Storm', spells = { 'cmc_mercy_purifying_storm' }, message = 'You learn Purifying Storm.' },
    { tomeId = 'cmc_tome_peryite_ordered_pestilence', name = "Spell Tome: Peryite's Ordered Pestilence", spells = { 'cmc_peryite_ordered_pestilence' }, message = "You learn Peryite's Ordered Pestilence." },
    { tomeId = 'cmc_tome_ash_plume', name = 'Spell Tome: Ash Plume', spells = { 'cmc_ash_plume' }, message = 'You learn Ash Plume.' },
    { tomeId = 'cmc_tome_ashstorm_communion', name = 'Spell Tome: Ashstorm Communion', spells = { 'cmc_ashstorm_communion' }, message = 'You learn Ashstorm Communion.' },
}

M.tomeById = {}
M.tomeByName = {}
M.tomeOrder = {}
for _, def in ipairs(M.tomeDefs) do
    M.tomeById[def.tomeId] = def
    M.tomeById[tostring(def.tomeId):lower()] = def
    if def.name then M.tomeByName[tostring(def.name):lower()] = def end
    table.insert(M.tomeOrder, def.tomeId)
end

M.vendorSpellLists = {
    general = {
        'cmc_purify_beast',
        'cmc_mercy_blight_bane',
    },
    healer = {
        'cmc_purify_beast',
        'cmc_mercy_blight_bane',
        'cmc_mercy_cleansing_ray',
        'cmc_mercy_purifying_storm',
    },
    profane = {
        'cmc_spread_common_disease',
        'cmc_peryites_gift',
        'cmc_spread_blight_disease',
        'cmc_dagoths_compassion',
        'cmc_contagion_feverbite',
        'cmc_contagion',
        'cmc_contagion_plagueburst',
        'cmc_peryite_ordered_pestilence',
        'cmc_ash_plume',
        'cmc_ashstorm_communion',
    },
}

M.vendorTomes = {
    general = {
        'cmc_tome_purify_beast',
        'cmc_tome_mercy_blight_bane',
    },
    healer = {
        'cmc_tome_purify_beast',
        'cmc_tome_mercy_blight_bane',
        'cmc_tome_cleansing_ray',
        'cmc_tome_purifying_storm',
    },
    profane = {
        'cmc_tome_spread_common_disease',
        'cmc_tome_peryites_gift',
        'cmc_tome_spread_blight_disease',
        'cmc_tome_dagoths_compassion',
        'cmc_tome_contagion_feverbite',
        'cmc_tome_contagion',
        'cmc_tome_contagion_plagueburst',
        'cmc_tome_peryite_ordered_pestilence',
        'cmc_tome_ash_plume',
        'cmc_tome_ashstorm_communion',
    },
}

local function addPair(healthyToVariant, variantToHealthy, healthy, variant)
    healthy = tostring(healthy):lower()
    variant = tostring(variant):lower()
    healthyToVariant[healthy] = healthyToVariant[healthy] or {}
    table.insert(healthyToVariant[healthy], variant)
    variantToHealthy[variant] = healthy
end

M.healthyToCommon = {}
M.commonToHealthy = {}
for _, pair in ipairs(M.commonPairs) do
    addPair(M.healthyToCommon, M.commonToHealthy, pair[1], pair[2])
end

M.healthyToBlight = {}
M.blightToHealthy = {}
for _, pair in ipairs(M.blightPairs) do
    addPair(M.healthyToBlight, M.blightToHealthy, pair[1], pair[2])
end

M.familyForId = {}
local function noteFamily(id)
    id = tostring(id):lower()
    M.familyForId[id] = M.familyAliases[id] or id
end
for _, pair in ipairs(M.commonPairs) do
    noteFamily(pair[1])
    M.familyForId[tostring(pair[2]):lower()] = M.familyAliases[tostring(pair[1]):lower()] or tostring(pair[1]):lower()
end
for _, pair in ipairs(M.blightPairs) do
    noteFamily(pair[1])
    M.familyForId[tostring(pair[2]):lower()] = M.familyAliases[tostring(pair[1]):lower()] or tostring(pair[1]):lower()
end

function M.lowerId(value)
    if value == nil then return nil end
    return tostring(value):lower()
end


M.playerAfflictionBoostDefs = {
    common = {
        { diseaseId = 'ataxia', boostId = 'cmc_affliction_boost_ataxia', title = 'Ataxic Adaptation', effects = {{ kind = 'attribute', name = 'strength', min = 10, max = 10 }, { kind = 'attribute', name = 'agility', min = 10, max = 10 }} },
        { diseaseId = 'brown rot', boostId = 'cmc_affliction_boost_brown_rot', title = 'Brown Rot Adaptation', effects = {{ kind = 'attribute', name = 'personality', min = 10, max = 10 }, { kind = 'attribute', name = 'strength', min = 10, max = 10 }} },
        { diseaseId = 'chills', boostId = 'cmc_affliction_boost_chills', title = 'Chills Adaptation', effects = {{ kind = 'attribute', name = 'intelligence', min = 10, max = 30 }, { kind = 'attribute', name = 'personality', min = 10, max = 30 }, { kind = 'attribute', name = 'strength', min = 10, max = 30 }} },
        { diseaseId = 'collywobbles', boostId = 'cmc_affliction_boost_collywobbles', title = 'Collywobbles Adaptation', effects = {{ kind = 'attribute', name = 'endurance', min = 10, max = 10 }, { kind = 'attribute', name = 'speed', min = 10, max = 10 }, { kind = 'attribute', name = 'strength', min = 10, max = 10 }} },
        { diseaseId = 'crimson_plague', boostId = 'cmc_affliction_boost_crimson_plague', title = 'Crimson Plague Adaptation', effects = {{ kind = 'fatigue', min = 100, max = 100 }, { kind = 'skill', name = 'acrobatics', min = 10, max = 20 }, { kind = 'skill', name = 'athletics', min = 10, max = 20 }, { kind = 'attribute', name = 'strength', min = 10, max = 10 }, { kind = 'attribute', name = 'endurance', min = 10, max = 10 }} },
        { diseaseId = 'dampworm', boostId = 'cmc_affliction_boost_dampworm', title = 'Dampworm Adaptation', effects = {{ kind = 'attribute', name = 'speed', min = 10, max = 30 }} },
        { diseaseId = 'droops', boostId = 'cmc_affliction_boost_droops', title = 'Droops Adaptation', effects = {{ kind = 'attribute', name = 'strength', min = 10, max = 30 }} },
        { diseaseId = 'greenspore', boostId = 'cmc_affliction_boost_greenspore', title = 'Greenspore Adaptation', effects = {{ kind = 'attribute', name = 'personality', min = 10, max = 20 }} },
        { diseaseId = 'helljoint', boostId = 'cmc_affliction_boost_helljoint', title = 'Helljoint Adaptation', effects = {{ kind = 'attribute', name = 'agility', min = 10, max = 10 }, { kind = 'attribute', name = 'speed', min = 10, max = 10 }} },
        { diseaseId = 'rattles', boostId = 'cmc_affliction_boost_rattles', title = 'Rattles Adaptation', effects = {{ kind = 'attribute', name = 'agility', min = 10, max = 10 }, { kind = 'attribute', name = 'willpower', min = 10, max = 10 }} },
        { diseaseId = 'rockjoint', boostId = 'cmc_affliction_boost_rockjoint', title = 'Rockjoint Adaptation', effects = {{ kind = 'attribute', name = 'agility', min = 10, max = 40 }} },
        { diseaseId = 'rotbone', boostId = 'cmc_affliction_boost_rotbone', title = 'Rotbone Adaptation', effects = {{ kind = 'fatigue', min = 3, max = 3 }} },
        { diseaseId = 'rust chancre', boostId = 'cmc_affliction_boost_rust_chancre', title = 'Rust Chancre Adaptation', effects = {{ kind = 'attribute', name = 'personality', min = 10, max = 10 }, { kind = 'attribute', name = 'speed', min = 10, max = 10 }} },
        { diseaseId = 'serpiginous dementia', boostId = 'cmc_affliction_boost_serpiginous_dementia', title = 'Serpiginous Dementia Adaptation', effects = {{ kind = 'attribute', name = 'intelligence', min = 10, max = 10 }, { kind = 'attribute', name = 'personality', min = 10, max = 10 }, { kind = 'attribute', name = 'willpower', min = 10, max = 10 }} },
        { diseaseId = 'swamp fever', boostId = 'cmc_affliction_boost_swamp_fever', title = 'Swamp Fever Adaptation', effects = {{ kind = 'attribute', name = 'endurance', min = 10, max = 10 }, { kind = 'attribute', name = 'strength', min = 10, max = 10 }} },
        { diseaseId = 'witbane', boostId = 'cmc_affliction_boost_witbane', title = 'Witbane Adaptation', effects = {{ kind = 'attribute', name = 'agility', min = 10, max = 40 }} },
        { diseaseId = 'witchwither', boostId = 'cmc_affliction_boost_witchwither', title = 'Witchwither Adaptation', effects = {{ kind = 'resistparalysis', min = 100, max = 100 }} },
        { diseaseId = 'wither', boostId = 'cmc_affliction_boost_wither', title = 'Wither Adaptation', effects = {{ kind = 'attribute', name = 'strength', min = 10, max = 10 }, { kind = 'attribute', name = 'endurance', min = 10, max = 10 }} },
        { diseaseId = 'yellow tick', boostId = 'cmc_affliction_boost_yellow_tick', title = 'Yellow Tick Adaptation', effects = {{ kind = 'attribute', name = 'strength', min = 10, max = 10 }, { kind = 'attribute', name = 'speed', min = 10, max = 10 }} },
    },
    blight = {
        { diseaseId = 'ash woe blight', boostId = 'cmc_affliction_boost_ash_woe_blight', title = 'Ash Woe Adaptation', effects = {{ kind = 'attribute', name = 'intelligence', min = 20, max = 40 }, { kind = 'attribute', name = 'willpower', min = 20, max = 40 }} },
        { diseaseId = 'ash-chancre', boostId = 'cmc_affliction_boost_ash_chancre', title = 'Ash-Chancre Adaptation', effects = {{ kind = 'attribute', name = 'personality', min = 20, max = 40 }} },
        { diseaseId = 'black-heart blight', boostId = 'cmc_affliction_boost_black_heart_blight', title = 'Black-Heart Adaptation', effects = {{ kind = 'attribute', name = 'strength', min = 20, max = 40 }, { kind = 'attribute', name = 'endurance', min = 20, max = 40 }} },
        { diseaseId = 'chanthrax blight', boostId = 'cmc_affliction_boost_chanthrax_blight', title = 'Chanthrax Adaptation', effects = {{ kind = 'attribute', name = 'agility', min = 20, max = 40 }, { kind = 'attribute', name = 'speed', min = 20, max = 40 }} },
    },
}

-- Adaptation abilities mirror the matching disease penalty. The player
-- script suppresses the original disease record after detecting an eligible
-- adaptation, so the positive ability no longer needs to double the magnitude
-- to overcome a still-active drain.

M.playerAfflictionBoostByDiseaseId = {}
M.playerAfflictionBoostIds = {}
for kind, defs in pairs(M.playerAfflictionBoostDefs) do
    for _, def in ipairs(defs) do
        local id = M.lowerId(def.diseaseId)
        M.playerAfflictionBoostByDiseaseId[id] = def
        M.playerAfflictionBoostIds[#M.playerAfflictionBoostIds + 1] = def.boostId
        def.kind = kind
    end
end

function M.displayFamily(family)
    family = M.lowerId(family)
    return M.familyDisplayNames[family] or family or 'this animal family'
end

function M.familyOf(recordId)
    recordId = M.lowerId(recordId)
    if not recordId then return nil end
    return M.familyForId[recordId] or M.familyAliases[recordId] or recordId
end

function M.isSpreadSpell(spellId)
    spellId = M.lowerId(spellId)
    if spellId == M.spells.spreadCommon or spellId == M.spells.peryiteGift then return 'common' end
    if spellId == M.spells.spreadBlight or spellId == M.spells.dagothCompassion then return 'blight' end
    if spellId == M.spells.contagionFeverbite then return 'common' end
    if spellId == M.spells.contagionPlagueburst then return 'common' end
    if spellId == M.spells.peryiteOrderedPestilence then return 'common' end
    if spellId == M.spells.ashstormCommunion then return 'blight' end
    return nil
end

function M.isAntiBlightSpell(spellId)
    spellId = M.lowerId(spellId)
    return M.antiBlightDamage[spellId] ~= nil
end

function M.isAntiBlightEffect(effectId)
    effectId = M.lowerId(effectId)
    if effectId == M.effects.antiBlight then return true end
    return false
end

function M.isSpreadEffect(effectId)
    effectId = M.lowerId(effectId)
    if effectId == M.effects.spreadCommon then return 'common' end
    if effectId == M.effects.spreadBlight then return 'blight' end
    return nil
end

function M.isResistScaledDamageEffect(effectId)
    effectId = M.lowerId(effectId)
    if effectId == M.effects.contagionResistDamage then return 'common' end
    if effectId == M.effects.blightResistDamage then return 'blight' end
    return nil
end

function M.isResistScaledDamageSpell(spellId)
    spellId = M.lowerId(spellId)
    if not spellId then return nil end
    return M.resistScaledDamageKindBySpell[spellId]
end

function M.isCureEffect(effectId)
    effectId = M.lowerId(effectId)
    if effectId == M.effects.cureCommon or effectId == M.effects.nativeCureCommon then return 'common' end
    if effectId == M.effects.cureBlight or effectId == M.effects.nativeCureBlight then return 'blight' end
    return nil
end

function M.cureKindsForSpell(spellId)
    spellId = M.lowerId(spellId)
    if spellId == M.spells.purifyBeast then return { 'common', 'blight' } end
    return nil
end

function M.isInfectedRecord(recordId)
    recordId = M.lowerId(recordId)
    return M.commonToHealthy[recordId] ~= nil or M.blightToHealthy[recordId] ~= nil
end

function M.heuristicVariantCandidates(kind, healthyId)
    healthyId = M.lowerId(healthyId)
    if not healthyId then return {} end
    if kind == 'common' then
        return {
            healthyId .. '_diseased',
            healthyId .. ' diseased',
            healthyId .. '-diseased',
            healthyId .. '_ds',
        }
    elseif kind == 'blight' then
        return {
            healthyId .. '_blighted',
            healthyId .. ' blighted',
            healthyId .. '-blighted',
            healthyId .. '_blight',
        }
    end
    return {}
end

function M.heuristicHealthyCandidates(kind, variantId)
    variantId = M.lowerId(variantId)
    if not variantId then return {} end
    local suffixes = {}
    if kind == 'common' then
        suffixes = { '_diseased', ' diseased', '-diseased', '_ds' }
    elseif kind == 'blight' then
        suffixes = { '_blighted', ' blighted', '-blighted', '_blight' }
    end
    local out = {}
    for _, suffix in ipairs(suffixes) do
        if variantId:sub(-#suffix) == suffix then
            out[#out + 1] = variantId:sub(1, #variantId - #suffix)
        end
    end
    return out
end

function M.isExcludedDagothOrAshVampire(recordId, name)
    local text = ((recordId or '') .. ' ' .. (name or '')):lower()
    return text:find('dagoth', 1, true) ~= nil or text:find('ash vampire', 1, true) ~= nil
end

function M.isSixthHouseLike(recordId, name)
    local text = ((recordId or '') .. ' ' .. (name or '')):lower()
    if M.isExcludedDagothOrAshVampire(recordId, name) then return false end
    if text:find('corprus', 1, true) then return true end
    if text:find('ascended sleeper', 1, true) then return true end
    if text:find('ash slave', 1, true) then return true end
    if text:find('ash zombie', 1, true) then return true end
    if text:find('ash ghoul', 1, true) then return true end
    if text:find('ash creature', 1, true) then return true end
    if text:find('sixth house', 1, true) then return true end
    return false
end

return M
