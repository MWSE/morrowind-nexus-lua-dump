local types = require("openmw.types")

require("scripts.Bullseye.utils.utils")

local whitelistedCreatureTypes = {
    [types.Creature.TYPE.Humanoid] = true,
    [types.Creature.TYPE.Daedra]   = true,
    [types.Creature.TYPE.Undead]   = true,
}

-- MUST BE LOWERCASE
local whitelistedModels = {
    -- vanilla
    ["almalexia"]          = true,
    ["almalexia_warrior"]  = true,
    ["byagram"]            = true,
    ["cr_draugr"]          = true,
    ["draugrLord"]         = true,
    ["frostgiant"]         = true,
    ["goblin01"]           = true,
    ["goblin02"]           = true,
    ["goblin03"]           = true,
    ["golden saint"]       = true,
    ["ice troll"]          = true,
    ["iceminion"]          = true,
    ["icemraider"]         = true,
    ["kwama warrior"]      = true,
    ["lordvivec"]          = true,
    ["sphere_centurions"]  = true,
    ["spherearcher"]       = true,
    ["spriggan"]           = true,
    ["steam_centurions"]   = true,
    ["udyrfrykte"]         = true,
    ["skinnpc"]            = true, -- werewolf
    -- Tamriel_Data
    ["pc_minotaur_01"]     = true,
    ["pc_minotaur_02"]     = true,
    ["pc_stridentbird"]    = true,
    ["pc_minotaurbarr01"]  = true,
    ["tr_dwemer"]          = true,
    ["tr_dwe_colos_01"]    = true,
    ["tr_golem_mud_vo"]    = true,
    ["tr_gremlin_01"]      = true,
    ["tr_gremlin_02"]      = true,
    ["tr_gremlin_03"]      = true,
    ["tr_gremlin_04"]      = true,
    ["tr_gremlin_05"]      = true,
    ["tr_kobold_01"]       = true,
    ["tr_landdreugh"]      = true,
    ["pc_sload_01"]        = true,
    ["tr_troll_armor_01"]  = true,
    ["tr_troll_armor_02"]  = true,
    ["tr_troll_armor_03"]  = true,
    ["tr_troll_armor_04"]  = true,
    ["tr_troll_cave01"]    = true,
    ["tr_troll_cave02"]    = true,
    ["tr_troll_frost01"]   = true,
    ["tr_troll_frost02"]   = true,
    ["tr_troll_frost03"]   = true,
    ["tr_troll_frost04"]   = true,
    ["sky_wereboar_01"]    = true,
    ["sky_werewolf_01"]    = true,
    ["tr_goblin_blind_01"] = true,
    ["tr_goblin_blind_02"] = true,
    ["tr_goblin_blind_03"] = true,
    ["tr_goblin_blind_04"] = true,
    ["tr_goblinshaman"]    = true,
    ["sky_goblinthr_01"]   = true,
    ["sky_hagraven_01"]    = true,
    ["sky_minotaur_01"]    = true,
    ["tr_canyonthresher"]  = true,
    ["tr_cr_ashfowl_01"]   = true,
    ["tr_swamp_troll"]     = true,
    ["sky_giant"]          = true,
    ["pi_roc01"]           = true,
    ["sky_koglingadult"]   = true,
    ["sky_koglingelder"]   = true,
    -- OAAB_Data
    ["cent_sphere_chute"]  = true,
}

-- MUST BE LOWERCASE
local blacklistedModels = {
    -- vanilla
    ["undeadwolf_2"]         = true,
    -- Tamriel_Data
    ["tr_skeleton_headless"] = true,
}

local function headshottable(victim)
    if types.NPC.objectIsInstance(victim) then
        return true
    end

    local victimRecord = victim.type.records[victim.recordId]

    if victimRecord.canUseWeapons then
        return true
    elseif blacklistedModels[ExtractFileName(victimRecord.model)] then
        return false
    elseif whitelistedCreatureTypes[victimRecord.type] then
        return true
    end

    return whitelistedModels[ExtractFileName(victimRecord.model)]
end

function HeadshotSuccessful(victim, attackPos)
    if not headshottable(victim) then return false end

    -- bor: might not be super accurate for creatures, but idc
    local headShotLevel = .85
    -- code from Ranged Headshot mod by SkyHasCats
    -- https://modding-openmw.gitlab.io/ranged-headshot/
    local bbox = victim:getBoundingBox()
    local half = bbox.halfSize
    local center = bbox.center
    -- Local hit position relative to center
    local rel = attackPos - center
    -- Convert to 0..1 along vertical axis
    -- bottom = -half.z, top = +half.z
    local normalizedHeight = (rel.z + half.z) / (2 * half.z)
    -- print(string.format("Hit height ratio: %.2f", normalizedHeight))
    return normalizedHeight > headShotLevel
end
