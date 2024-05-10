---@class Rule
local this = {}

local logger = require("YourName.logger")
local memo = require("YourName.memory")

-- specific allow/deny
-- It should be possible for the script to determine if the name is unique, if it can speak, and if it may partially identify itself.
-- If we could find a way to do that, this list would be unnecessary.
local filter = {
    -- NPC
    -- https://en.uesp.net/wiki/Morrowind:Cattle
    ["cattle_kha_f01"] = false,
    ["cattle_kha_f02"] = false,
    ["cattle_arg_f01"] = false,
    ["cattle_arg_f02"] = false,
    ["cattle_arg_m01"] = false,
    ["cattle_kha_m01"] = false,
    ["cattle_dun_m01"] = false,
    ["cattle_red_m01"] = false,
    ["cattle_bos_m01"] = false,
    ["cattle_dun_f01"] = false,
    ["cattle_red_f01"] = false,
    ["cattle_bos_f01"] = false,
    ["cattle_bre_f01"] = false,
    ["cattle_bre_m01"] = false,
    ["cattle_nor_m01"] = false,
    ["cattle_nor_f01"] = false,
    ["cattle_imp_m01"] = false,
    ["cattle_imp_f01"] = false,
    ["cattle_orc_m01"] = false,
    ["cattle_orc_f01"] = false,
    -- Dead ~~
    -- ["dead random male"] = false,
    -- ["dead random female"] = false,
    -- ["dead de male"] = false,
    -- ["dead de female"] = false,
    -- ["dead de female_01"] = false,
    -- ["dead de male_01"] = false,
    -- ["dead he male_01"] = false,
    -- ["dead we male_01"] = false,
    -- ["dead de male_berandas"] = false,
    -- ["dead imp male_01"] = false,
    -- ["dead de male_tomb01"] = false,
    -- ["dead de male_tomb02"] = false,
    -- ["dead imp male_tomb01"] = false,
    -- ["dead imp male_02"] = false,
    -- ["dead orc male_02"] = false,
    -- ["dreamer_dead"] = false,
    -- ["miner_dead00"] = false,
    -- ["miner_dead01"] = false,
    -- ["dead elite ord"] = false,
    -- ["warrior dead 00"] = false,
    -- ["wizard dead 00"] = false,
    -- ["thief dead 00"] = false,
    -- ["wizard dead 01"] = false,
    -- ["wizard dead 02"] = false,
    -- ["wizard dead 03"] = false,
    -- ["dead ordinator"] = false,
    -- ["dead ordinator_key"] = false,
    -- ["Smuggler_Dead_01"] = false,
    -- ["Smuggler_Dead_02"] = false,
    -- ["Smuggler_Dead_03"] = false,
    -- ["dead warlock"] = false,
    -- Dreamer
    ["dreamer"] = false,
    ["dreamer_f_01"] = false,
    ["dreamer_02"] = false,
    ["dreamer_f_key"] = false,
    ["dreamer_ranged"] = false,
    ["dreamer_04"] = false,
    ["dreamer_05"] = false,
    ["dreamer_06"] = false,
    ["Dreamer_Talker"] = false,
    ["Dreamer_Talker01"] = false,
    ["Dreamer_Talker02"] = false,
    ["Dreamer_Talker03"] = false,
    ["Dreamer_Talker04"] = false,
    ["Dreamer_Talker05"] = false,
    ["Dreamer_Talker06"] = false,
    ["Dreamer_Talker07"] = false,
    ["Dreamer_Talker08"] = false,
    ["Dreamer_Talker09"] = false,
    ["Dreamer_Talker10"] = false,
    ["Dreamer_Talker11"] = false,
    ["Dreamer_Talker12"] = false,
    -- Egg Miner
    ["miner_01"] = false,
    ["miner_02"] = false,
    ["miner_03"] = false,
    -- Vampire
    ["berne vampire 1"] = false,
    ["berne vampire 2"] = false,
    ["berne vampire 3"] = false,
    ["berne vampire 4"] = false,
    ["berne vampire 5"] = false,
    ["quarra vampire 1"] = false,
    ["quarra vampire 2"] = false,
    ["quarra vampire 3"] = false,
    ["quarra vampire 4"] = false,
    ["quarra vampire 5"] = false,
    ["aundae vampire 1"] = false,
    ["aundae vampire 2"] = false,
    ["aundae vampire 3"] = false,
    ["aundae vampire 4"] = false,
    ["aundae vampire 5"] = false,
    -- Worshipper
    ["mehrunesworshipper_m01"] = false,
    ["mehrunesworshipper_f01"] = false,
    ["mehrunesworshipper_m02"] = false,
    -- Assassin
    ["db_assassin1"] = false,
    ["db_assassin2"] = false,
    ["db_assassin3"] = false,
    ["db_assassin4"] = false,
    ["db_assassin1b"] = false,
    ["hels_assassin2"] = false,
    ["hels_assassin3"] = false,
    -- Dark Brotherhood Apprentice
    ["db_assassin1c"] = false, -- Dark Brotherhood Apprentice
    ["db_assassin4a"] = false, -- Dark Brotherhood Assassin
    ["db_assassin1a"] = false, -- Dark Brotherhood Journeyman
    ["db_assassin2a"] = false, -- Dark Brotherhood Operator
    ["db_assassin3a"] = false, -- Dark Brotherhood Punisher
    --- Warewolf
    ["BM_werewolf_skaal1A3"] = false,
    ["BM_werewolf_skaal1B3"] = false,
    ["BM_werewolf_skaal1C3"] = false,
    ["BM_werewolf_skaal1D3"] = false,
    ["BM_werewolf_skaal1E3"] = false,
    ["BM_werewolf_skaal1F3"] = false,
    ["BM_werewolf_skaal1G3"] = false,
    ["BM_werewolf_skaal2a"] = false,
    ["BM_werewolf_wildhunt"] = false,
    ["BM_werewolf_wildhunt2"] = false,
    ["BM_werewolf_wildhunt3"] = false,
    ["BM_werewolf_wildhunt4"] = false,
    ["werewolf_bearhunt"] = false,
    ["werewolf_ceremony"] = false,
    ["bm_werewolf_wild01"] = false,      -- Wandering Lunatic
    ["bm_werewolf_wild02"] = false,      -- Wandering Lunatic
    ["bm_werewolf_wild03"] = false,      -- Insane Wanderer
    ["bm_werewolf_wild04"] = false,      -- Insane Wanderer
    ["bm_werewolf_wild05"] = false,      -- Gibbering Lunatic
    ["bm_werewolf_wild06"] = false,      -- Gibbering Lunatic
    ["bm_werewolf_wild07"] = false,      -- Wandering Idiot
    ["bm_werewolf_wild08"] = false,      -- Confused Lunatic
    ["bm_werewolf_wild09"] = false,      -- Wandering Lunatic
    ["bm_werewolf_wildernessC"] = false, -- Confused Lunatic
    ["BM_werewolf_maze1"] = false,       -- Hound of Hircine
    ["wolfender_f_imperial"] = false,    -- Female Imperial Innocent
    ["wolfender_f_nord"] = false,        -- Female Nord Innocent
    ["wolfgiver_f_nord"] = false,        -- Female Nord Innocent
    -- Berserker
    ["BM_berserker_f1"] = false,         -- Berserker
    ["BM_berserker_f1_lvl5"] = false,    -- Berserker
    ["BM_berserker_f2"] = false,         -- Berserker
    ["BM_berserker_f3"] = false,         -- Berserker
    ["BM_berserker_m1"] = false,         -- Berserker
    ["BM_berserker_m1_lvl5"] = false,    -- Berserker
    ["BM_berserker_m2"] = false,         -- Berserker
    ["BM_berserker_m3"] = false,         -- Berserker
    ["BM_berserker_f4"] = false,         -- Berserker Denmother
    -- Berserker
    ["bm_reaver_10"] = false,            -- Reaver
    ["bm_reaver_30"] = false,            -- Reaver
    ["bm_reaver_50"] = false,            -- Reaver
    ["bm_reaver_archer_10"] = false,     -- Reaver
    ["bm_reaver_archer_30"] = false,     -- Reaver
    ["bm_reaver_archer_50"] = false,     -- Reaver
    ["bm_smugglers_redguard"] = false,   -- Smuggler
    ["bm_smugglers_imperial"] = false,   -- Smuggler
    ["bm_smugglers_darkelf"] = false,    -- Smuggler
    ["bm_smugglers_darkelf_f"] = false,  -- Smuggler
    ["bm_smugglers_imperial_f"] = false, -- Smuggler
    ["bm_smugglers_redguard_f"] = false, -- Smuggler
    ["bm_smugglers_woodelf"] = false,    -- Smuggler
    ["a smuggler boss"] = false,         -- Smuggler Boss
    -- Thirsk Worker
    ["thirsk_build"] = false,
    ["thirsk_build_2"] = false,
    ["thirsk_build_3"] = false,
    -- creature
    ---- morrowind
    ["dagoth_ur_1"] = true,
    ["dagoth_ur_2"] = true,
    ["heart_akulakhan"] = false,
    ["vivec_god"] = true,
    ["yagrum bagarn"] = true,
    ["dagoth fandril"] = false,
    ["dagoth molos"] = false,
    ["dagoth felmis"] = false,
    ["dagoth rather"] = false,
    ["dagoth garel"] = false,
    ["dagoth reler"] = false,
    ["dagoth goral"] = false,
    ["dagoth tanis"] = false,
    ["dagoth_hlevul"] = false,
    ["dagoth uvil"] = false,
    ["dagoth malan"] = false,
    ["dagoth vaner"] = false,
    ["dagoth ulen"] = false,
    ["dagoth irvyn"] = false,
    ["dagoth aladus"] = false,
    ["dagoth fovon"] = false,
    ["dagoth baler"] = false,
    ["dagoth girer"] = false,
    ["dagoth daynil"] = false,
    ["dagoth ienas"] = false,
    ["dagoth delnus"] = false,
    ["dagoth mendras"] = false,
    ["dagoth drals"] = false,
    ["dagoth mulis"] = false,
    ["dagoth muthes"] = false,
    ["dagoth elam"] = false,
    ["dagoth nilor"] = false,
    ["dagoth fervas"] = false,
    ["dagoth ralas"] = false,
    ["dagoth soler"] = false,
    ["dagoth fals"] = false,
    ["dagoth galmis"] = false,
    ["dagoth gares"] = true, -- Dagoth Gares (main quest)
    ["dagoth velos"] = false,
    ["dagoth araynys"] = false,
    ["dagoth endus"] = false,
    ["dagoth gilvoth"] = false,
    ["dagoth odros"] = false,
    ["dagoth Tureynul"] = false,
    ["dagoth uthol"] = false,
    ["dagoth vemyn"] = false,
    ["guar_llovyn_unique"] = false,
    ["guar_rollie_unique"] = false,
    ["mudcrab_unique"] = true, -- Mudcrab (merchant)
    ["rat_cave_hhte1"] = false,
    ["atronach_flame_ttmk"] = false,
    ["atronach_frost_ttmk"] = false,
    ["atronach_frost_gwai_uni"] = false,
    ["atronach_storm_ttmk"] = false,
    ["daedroth_menta_unique"] = false,
    ["dremora_ttmg"] = true, -- Anhaedra
    ["dremora_ttpc"] = true, -- Krazzt talks name?
    ["dremora_special_Fyr"] = false,
    ["golden saint_staada"] = false,
    ["lustidrike"] = true,    -- Lustidrike talks name?
    ["scamp_creeper"] = true, -- Creeper doesnt talk his name
    ["winged twilight_grunda_"] = false,
    ["ancestor_guardian_fgdd"] = false,
    ["gateway_haunt"] = false,
    ["ancestor_guardian_heler"] = false,
    ["ancestor_mg_wisewoman"] = false,
    ["ancestor_ghost_vabdas"] = true, -- Mansilamat Vabdas talks name?
    ["wraith_sul_senipul"] = false,
    ["Dahrk Mezalf"] = false,
    ["skeleton_Vemynal"] = false,
    ["worm lord"] = false,
    ---- tribunal
    ["almalexia"] = true,
    ["almalexia_warrior"] = true,
    ["goblin_warchief1"] = false,
    ["goblin_warchief2"] = false,
    ["lich_profane_unique"] = false,
    ["lich_relvel"] = false,
    ["lich_barilzar"] = false,
    ["ancestor_ghost_Variner"] = false,
    ["dwarven ghost_radac"] = true, -- Radac Stungnthumz
    ["dremora_lord_khash_uni"] = false,
    ---- bloodmoon
    ["glenmoril_raven"] = true,
    ["glenmoril_raven_cave"] = true,
    ["BM_hircine"] = true,
    ["BM_hircine2"] = true,
    ["BM_hircine_huntaspect"] = false,
    ["BM_hircine_spdaspect"] = false,
    ["BM_hircine_straspect"] = false,
    ["bm_frost_giant"] = false,
    ["BM_udyrfrykte"] = false,
    ["draugr_valbrandr"] = false,
    ["draugr_aesliip"] = true,          -- Draugr Lord Aesliip talks name?
    ["BM_riekling_Dulk_UNIQUE"] = true, -- Dulk
    ["BM_riekling_Krish_UNIQU"] = true, -- Krish talks name?
}

---@param actor tes3creature|tes3creatureInstance|tes3npc|tes3npcInstance
---@param config Config.Filtering
---@return boolean
local function IsTargetByConfig(actor, config)
    if config.essential == false and actor.isEssential == true then
        logger:trace("%s is an essential", actor.id)
        return false
    end
    if config.corpse == false and actor.persistent == true then
        logger:trace("%s is a corpse", actor.id)
        return false
    end
    if config.guard == false and actor.isGuard == true then
        logger:trace("%s is a guard", actor.id)
        return false
    end
    if config.nolore == false and actor.script ~= nil then
        -- base object has modified variables?
        if actor.script.context["NoLore"] ~= nil then
            logger:trace("%s has NoLore in script %s", actor.id, actor.script.id)
            return false
        end
    end
    return true
end

---@param actor (tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon)?
---@param config Config.Filtering
---@return boolean
function this.IsTarget(actor, config)
    if actor == nil then
        return false
    end
    if actor.objectType == tes3.objectType.npc then
        if IsTargetByConfig(actor --[[@as tes3npc|tes3npcInstance]], config) == false then
            return false
        end

        -- implicit true
        local f = filter[memo.GetAliasedID(actor.id)]
        logger:trace("%s is a NPC in deny list: %s", actor.id, tostring(f))
        return (f == nil) or (f == true)
    elseif actor.objectType == tes3.objectType.creature and config.creature == true then
        if IsTargetByConfig(actor --[[@as tes3creature|tes3creatureInstance]], config) == false then
            return false
        end

        -- only special creatures
        local f = filter[memo.GetAliasedID(actor.id)]
        logger:trace("%s is a creature in allow list: %s", actor.id, tostring(f))
        return (filter[memo.GetAliasedID(actor.id)] == true)
    end
    return false
end

return this
