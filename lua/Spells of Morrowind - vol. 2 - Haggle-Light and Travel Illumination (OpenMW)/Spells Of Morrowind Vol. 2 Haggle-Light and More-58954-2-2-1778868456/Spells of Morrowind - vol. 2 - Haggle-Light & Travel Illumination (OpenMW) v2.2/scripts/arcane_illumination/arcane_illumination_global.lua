-- ============================================================
-- Spells of Morrowind: Haggle-light and Travel Illumination — GLOBAL Script
-- Pure-container Haggle-light rewrite
--
-- MAJOR UPDATES:
-- - Added Detach Light spell support
-- - Fixed dispel/expiry detection for all spell types
-- - Added light position (Left/Right) setting with live updates
-- - Added VFX scale setting (0.0-1.0, 0 = disabled)
-- - Fixed pickup blocking with proper error handling
-- - Fixed save/load persistence for all spell types
-- - Added Attach Light blacklist system
-- - Added duration tooltip updates every second
-- - Fixed Attach Light race condition with startup grace period
-- ============================================================

local core  = require('openmw.core')
local types = require('openmw.types')
local util  = require('openmw.util')
local async = require('openmw.async')
local world = require('openmw.world')
local I     = require('openmw.interfaces')

local activeSpell = nil

local settingsCache = {
    haggleCooldownHours       = "24 Hours",
    haggleMercantileRatio     = 0.5,
    haggleMagnitudeMultiplier = 0.5,
    lightPosition             = "Left",
    vfxOffsetConjure    = -50,
    vfxOffsetAttach     = -50,
    vfxEnabled                = true,
    vfxScaleConjure           = 0.3,   -- Conjure Lantern anchor scale
    vfxScaleAttach            = 0.2,   -- Attach Lantern anchor scale
    vfxScaleWispHaggle        = 0.2,   -- Light Wisp + Haggle-light scale
}

local function debugLog(msg)
    if settingsCache and settingsCache.debugMode then
        print("[Haggle-Light] " .. tostring(msg))
    end
end

-- ============================================================
-- CONSTANTS
-- ============================================================
local LIGHT_CARRIER_REC            = 'colony_assassin_act'
local HOVER_SOUND                  = 'alteration bolt'
local ORBIT_RADIUS                 = 75
local DOUSE_DEPTH                  = -20
local ANIMATE_LANTERN_LIFETIME     = 300
local ANIMATE_LANTERN_BLOCK_PICKUP = true
local ANIMATE_VFX_ANCHOR_MODEL     = 'meshes/EditorMarker.NIF'
local HAGGLE_ORB_MODEL             = 'meshes/magic_target_ill_nc.nif'
local HAGGLE_TIMEOUT               = 120
local GOLD_REC                     = 'gold_001'
local HAGGLE_ORB_SCALE             = 0.6
local SPAWN_LEFT_BIAS              = 30
local DURATION_UPDATE_INTERVAL     = 1.0

-- Attach spell startup grace: skip validity/inventory checks for this many sim-seconds
-- after the spell is first cast, preventing the race condition where the engine
-- briefly drops the world object or has it transiently visible in inventory.
local ATTACH_STARTUP_GRACE         = 3.0

local uiOpen = false

-- ============================================================
-- PROTECTED ITEMS (for Haggle-light container - cannot be destroyed)
-- ============================================================
local PROTECTED_ITEMS = {
    ['keening'] = true,
    ['sunder'] = true,
    ['wraithguard'] = true,
    ['lugrub\'s axe'] = true,
    ['dwarven war axe_redas'] = true,
    ['ebony staff caper'] = true,
    ['ebony wizard\'s staff'] = true,
    ['rusty_dagger_unique'] = true,
    ['devil_tanto_tgamg'] = true,
    ['daedric wakizashi_hhst'] = true,
    ['glass_dagger_enamor'] = true,
    ['dart_uniq_judgement'] = true,
    ['dwemer_boots of flying'] = true,
    ['bonemold_gah-julan_hhda'] = true,
    ['bonemold_founders_helm'] = true,
    ['bonemold_tshield_hrlb'] = true,
    ['amulet of ashamanu'] = true,
    ['amuletfleshmadewhole_uniq'] = true,
    ['amulet_agustas_unique'] = true,
    ['expensive_amulet_delyna'] = true,
    ['expensive_amulet_aeta'] = true,
    ['sarandas_amulet'] = true,
    ['exquisite_amulet_hlervu1'] = true,
    ['julielle_aumines_amulet'] = true,
    ['linus_iulus_maran amulet'] = true,
    ['amulet_skink_unique'] = true,
    ['linus_iulus_stendarran_belt'] = true,
    ['sarandas_belt'] = true,
    ['common_glove_l_balmolagmer'] = true,
    ['common_glove_r_balmolagmer'] = true,
    ['extravagant_rt_art_wild'] = true,
    ['expensive_glove_left_ilmeni'] = true,
    ['extravagant_glove_left_maur'] = true,
    ['extravagant_glove_right_maur'] = true,
    ['common_pants_02_hentus'] = true,
    ['sarandas_pants_2'] = true,
    ['adusamsi\'s_ring'] = true,
    ['extravagant_ring_aund_uni'] = true,
    ['ring_blackjinx_uniq'] = true,
    ['exquisite_ring_brallion'] = true,
    ['common_ring_danar'] = true,
    ['sarandas_ring_2'] = true,
    ['ring_keley'] = true,
    ['expensive_ring_01_bill'] = true,
    ['expensive_ring_aeta'] = true,
    ['sarandas_ring_1'] = true,
    ['expensive_ring_01_hrdt'] = true,
    ['exquisite_ring_processus'] = true,
    ['ring_dahrkmezalf_uniq'] = true,
    ['extravagant_robe_01_red'] = true,
    ['robe of st roris'] = true,
    ['exquisite_robe_drake\'s pride'] = true,
    ['sarandas_shirt_2'] = true,
    ['exquisite_shirt_01_rasha'] = true,
    ['sarandas_shoes_2'] = true,
    ['therana\'s skirt'] = true,
    ['misc_beluelle_silver_bowl'] = true,
    ['misc_lw_bowl_chapel'] = true,
    ['misc_dwrv_artifact_ils'] = true,
    ['misc_dwarfbone_unique'] = true,
    ['misc_dwrv_ark_cube00'] = true,
    ['misc_fakesoulgem'] = true,
    ['ingred_guar_hide_girith'] = true,
    ['misc_uniq_egg_of_gold'] = true,
    ['misc_goblet_dagoth'] = true,
    ['ingred_guar_hide_marsus'] = true,
    ['misc_6th_ash_hrmm'] = true,
    ['misc_de_goblet_01_redas'] = true,
    ['misc_skull_llevule'] = true,
    ['misc_6th_ash_hrcs'] = true,
    ['misc_wraithguard_no_equip'] = true,
    ['bk_a1_1_caiuspackage'] = true,
    ['bk_a1_1_packagedecoded'] = true,
    ['tr_m3_q_theriftcandle'] = true,
    ['tr_m3_q_theriftcandleoff'] = true,
    ['tr_m3_a9_q_ritualcandle'] = true,
    ['tr_m3_raathimtorch01'] = true,
    ['tr_m3_raathimtorch02'] = true,
    ['tr_m3_raathimtorch03'] = true,
    ['tr_m3_oe_mg_ritualcandle'] = true,
    ['tr_m3_oe_mg_ritualcandle_lit'] = true,
    ['tr_m1_fw_tg2_candlestick'] = true,
    ['tr_m3-794_lantern'] = true,
    ['tr_m3_lgt_lantern1'] = true,
    ['tr_m3_lgt_candle'] = true,
    ['tr_m2_kaishi_lantern'] = true,
    ['tr_m3_q_a7_nethrillantern'] = true,
    ['tr_m3_tt_rip_ritualcandle'] = true,
    ['tr_m3_i3_316_com_candle_14_off'] = true,
    ['tr_m3_oe_mg_silvercandle'] = true,
    ['tr_m2_q_14_candle02'] = true,
    ['tr_m2_q_14_candle01'] = true,
    ['tr_m3_et14_lantern'] = true,
    ['tr_m3_votive_i3-399-ind'] = true,
    ['tr_m2_q_14_commonsoulgem'] = true,
    ['tr_m1_soulgem_curse_i62'] = true,
    ['tr_m3_oe_q_missagem'] = true,
    ['tr_m3_oe_q_missagem2'] = true,
    ['tr_m3_oe_q_missagempre'] = true,
    ['tr_m1_q_hernessoul'] = true,
    ['tr_m3_oe_fiendgem'] = true,
    ['tr_m3_zymelkaazsoulgem'] = true,
    ['tr_m2_plans_i2-307'] = true,
    ['tr_m2_kmlz_chefb_coherer'] = true,
    ['tr_m3_dwemeroreprobe'] = true,
    ['tr_m2_dwrv_artifact70_01'] = true,
    ['tr_m1_q_attackpiece4'] = true,
    ['tr_m3_q_fakedwemercoin'] = true,
    ['tr_m1_q_attackpiece3'] = true,
    ['tr_m1_eec_harecoherer'] = true,
    ['tr_m1_q_attackpiece2'] = true,
    ['tr_m2_q_22_lw_platter'] = true,
    ['tr_m2_q_22_lw_platter2'] = true,
    ['tr_m2_q_9_flinbottle'] = true,
    ['tr_m3_essempty_i3-128-ind'] = true,
    ['tr_m3_oe_tg_goblet'] = true,
    ['tr_m2_q_9_pot_uni'] = true,
    ['tr_m1_yamanakal_spoon'] = true,
    ['tr_m3_voicebottle21'] = true,
    ['tr_m3_oe_fg_lenwskel'] = true,
    ['tr_m3_oe_fg_q_constskelet'] = true,
    ['tr_m3_kha_anguish_crux'] = true,
    ['tr_m2_necrom_enduur_uni'] = true,
    ['tr_m3_tt_rip_fedura_ash'] = true,
    ['tr_m3_voicebottle7'] = true,
    ['tr_m4_aa_uvaynjewelrybag_01'] = true,
    ['tr_m3_essrose_i3-128-ind'] = true,
    ['tr_m3_q_bloodstone'] = true,
    ['tr_m3_q_bloodstone_actv'] = true,
    ['tr_m3_oe_mggemreward'] = true,
    ['tr_m3_blood_i1-453-aun'] = true,
    ['tr_m3_q_oe_tokenbrass'] = true,
    ['tr_m2_q_6_badshovel'] = true,
    ['tr_m3_q_oe_urien_sword_01'] = true,
    ['tr_m3_voicebottle17'] = true,
    ['tr_m3_oe_svarrcloth'] = true,
    ['tr_m3_voicebottle14'] = true,
    ['tr_m1_q_diamondsample'] = true,
    ['tr_i2_445_sealingskull'] = true,
    ['tr_m3_kha_sy_hand'] = true,
    ['tr_m3_voicebottle10'] = true,
    ['tr_m2_q_a9_6_skull'] = true,
    ['tr_m3_oe_mg_enchbroom'] = true,
    ['tr_m3_q_hideseekskull'] = true,
    ['tr_m1_faruna_roll_pin'] = true,
    ['tr_m1_q_57_featherspear'] = true,
    ['tr_m3_et22_forceps'] = true,
    ['tr_m4_armun_ganahiru_hide'] = true,
    ['tr_m3_esskanet_i3-128-ind'] = true,
    ['tr_m3_q_ienasajug'] = true,
    ['tr_m2_q_10_treatment'] = true,
    ['tr_m1_q50_cloth_1'] = true,
    ['tr_m1_q50_cloth_2'] = true,
    ['tr_m3_voicebottle22'] = true,
    ['tr_m3_voicebottle24'] = true,
    ['tr_m3_voicebottle8'] = true,
    ['tr_m7_ns_tt_chavana1_potion'] = true,
    ['tr_m3_q_theriftdeskitem6'] = true,
    ['tr_m4_kassadpackage'] = true,
    ['tr_m3_rd_hiseyes_intelligence'] = true,
    ['tr_m1_bo_muskfly_oil'] = true,
    ['tr_m3_q_oe_ulka_dice'] = true,
    ['tr_m3_voicebottle16'] = true,
    ['tr_m7_othm_q_madranadrum'] = true,
    ['tr_m3_oe_fg_sycobroom'] = true,
    ['tr_m2_q_6_goodshovel'] = true,
    ['tr_m3_essnight_i3-128-ind'] = true,
    ['tr_m3_essnirth_i3-128-ind'] = true,
    ['tr_m2_q_a8_2_nobura_tayo'] = true,
    ['tr_m3_voicebottle19'] = true,
    ['tr_m3_oe_ashstatue'] = true,
    ['tr_m3_oe_cirtielashstatue'] = true,
    ['tr_m1_fw_ic2_package'] = true,
    ['tr_m3_dirt_i3-390-ind'] = true,
    ['tr_m3_relic1_i3-559-ind'] = true,
    ['tr_m3-725_misc_rot_khj_02'] = true,
    ['tr_m3-725_misc_rot_orc_02'] = true,
    ['tr_m3_elysanadiamond'] = true,
    ['tr_m3_trueelysanadiamond'] = true,
    ['tr_m3_q_theriftdeskitem7'] = true,
    ['tr_m3_voicebottle23'] = true,
    ['tr_m7_q_scryingglass'] = true,
    ['tr_m3_tt_flood_sarnatash'] = true,
    ['tr_m3_seedbag_i3-390-ind'] = true,
    ['tr_m7_q_hh_alvynu_glassshard'] = true,
    ['tr_m7_q_hh_alvynu_glassshard_x'] = true,
    ['tr_m7_q_hh_seventhfam_seydaneen'] = true,
    ['tr_m2_q_a9_5_aryn_skull'] = true,
    ['tr_m3_voicebottle20'] = true,
    ['tr_m3_voicebottle13'] = true,
    ['tr_m1_q50_go2_finethread'] = true,
    ['tr_m3_essstone_i3-128-ind'] = true,
    ['tr_m3_sa_supplypackage'] = true,
    ['tr_m7_talmsbelethlute'] = true,
    ['tr_m3_esstimsa_i3-128-ind'] = true,
    ['tr_m3_voicebottle18'] = true,
    ['tr_m3_voicebottle15'] = true,
    ['tr_m3_q_oe_tokenwood'] = true,
    ['tr_m1_eec_zarenpack'] = true,
    ['tr_m3_voicebottle9'] = true,
    ['pc_m1_mg_cha3_potion2'] = true,
    ['pc_m1_cha_cassynder_goblet'] = true,
    ['pc_m1_mg_cha3_potion1'] = true,
    ['pc_m1_ip_lki4_blood'] = true,
    ['pc_m1_anv_blkview_asoulgemmsc1'] = true,
    ['pc_m1_anv_blkview_asoulgemmsc2'] = true,
    ['pc_m1_anv_blkview_asoulgemmsc3'] = true,
    ['pc_m1_dm_adunadosu'] = true,
    ['pc_m1_tg_anv3_painting'] = true,
    ['pc_m1_mg_anv7_crystalball'] = true,
    ['pc_m1_anv_crabbuck_bucket'] = true,
    ['pc_m1_anv_workorc_pole'] = true,
    ['pc_m1_cha_pelleg_vial'] = true,
    ['pc_m1_ip_lki2_painting'] = true,
    ['pc_m1_cha_selkies_skin'] = true,
    ['pc_m1_k1_mc2_shipment'] = true,
    ['pc_m1_fg_anv5_painting'] = true,
    ['pc_m1_anv_decatorremains'] = true,
    ['pc_m1_mg_cha2_basket'] = true,
}

-- ============================================================
-- ATTACH LIGHT BLACKLIST
-- ============================================================
local ATTACH_LIGHT_BLACKLIST = {
    ['uvi_buglamp_gothren'] = true,
    ['light_com_lantern_bm_unique'] = true,
    ['torch_infinite_time'] = true,
    ['torch_infinite_time_unique'] = true,
    ['light_com_lantern_02_inf'] = true,
    ['light_de_buglamp_01_64'] = true,
    ['light_de_buglamp_01'] = true,
    ['light_com_torch_burnedout_01'] = true,
    ['light_com_candle_03_64'] = true,
    ['light_com_candle_03'] = true,
    ['light_com_candle_01'] = true,
    ['light_com_candle_01_64'] = true,
    ['light_de_candle_ivory_dead'] = true,
    ['tr_m3_q_theriftcandle'] = true,
    ['tr_m3_q_theriftcandleoff'] = true,
    ['tr_m3_a9_q_ritualcandle'] = true,
    ['tr_m3_raathimtorch01'] = true,
    ['tr_m3_raathimtorch02'] = true,
    ['tr_m3_raathimtorch03'] = true,
    ['tr_m3_lgt_candle'] = true,
    ['tr_m3_oe_mg_ritualcandle'] = true,
    ['tr_m3_oe_mg_ritualcandle_lit'] = true,
    ['tr_m1_fw_tg2_candlestick'] = true,
    ['tr_m2_kaishi_lantern'] = true,
    ['tr_m3_q_a7_nethrillantern'] = true,
    ['tr_m3_tt_rip_ritualcandle'] = true,
    ['tr_m2_q_14_candle02'] = true,
    ['tr_m2_q_14_candle01'] = true,
    ['pc_m1_garage_candle'] = true,
    ['pc_m1_garage_lightvarla'] = true,
    ['pc_m1_wormusoel_lightvarla'] = true,
    ['pc_m1_lindasael_lightvarla'] = true,
    ['pc_m1_gulaida_lightvarla'] = true,
}

-- ============================================================
-- STATE / RECORD CACHES
-- ============================================================
local WISP_LIGHT_REC            = nil
local WISP_ORB_REC              = nil
local ANIMATE_VFX_ANCHOR_REC    = nil
local ANIMATE_LANTERN_RECORD_CACHE = {}
local ATTACH_LANTERN_RECORD_CACHE  = {}
local HAGGLE_CONTAINER_RECS     = {}
local HAGGLE_LIGHT_REC          = nil
local injected_npcs             = {}
local pickedUpLights            = {}
local lightValidityCheckTime    = 0
local attachInventoryCheckCooldown = 0
local durationUpdateTimer       = 0
local haggleLastUsedTime        = nil

-- per-instance spell tracking
local seenActiveSpellIds   = {}
local seenSpellHandlerKey  = {}
local seenSpellEndAtSim    = {}
local seenSpellFirstSeenAt = {}
local DISPEL_GRACE_PERIOD  = 2.0

-- ============================================================
-- LANTERN LIST
-- ============================================================
local lanterns = {
    'light_de_lantern_02',
    'light_de_lantern_06_256',
    'Light_De_Lantern_01',
    'light_de_lantern_05',
    'light_de_lantern_07',
    'light_de_lantern_07_warm',
    'light_de_lantern_10',
    'light_de_lantern_14',
    'light_com_lantern_02',
    'light_com_lantern_01',
}

local function pickRandomLantern()
    return lanterns[math.random(1, #lanterns)]
end

-- ============================================================
-- SETTINGS HELPERS
-- ============================================================
local function getHaggleCooldownHours()
    local s = tostring(settingsCache.haggleCooldownHours)
    if s == "Disabled" then return 0 end
    if s == "1 Hour"   then return 1 end
    if s == "3 Hours"  then return 3 end
    if s == "6 Hours"  then return 6 end
    if s == "12 Hours" then return 12 end
    if s == "24 Hours" then return 24 end
    return 24
end

local function isHaggleCooldownEnabled() return getHaggleCooldownHours() > 0 end

local function getHaggleMercantileRatio()
    local r = tonumber(settingsCache.haggleMercantileRatio) or 0.5
    return math.max(0, r)
end

local function getHaggleMagnitudeMultiplier()
    local m = tonumber(settingsCache.haggleMagnitudeMultiplier) or 0.5
    return math.max(0, m)
end
-- Returns the VFX offset for an attached light based on its name
local function getAttachVfxOffsetForLight(lightRecordId)
    local lightName = ""
    pcall(function()
        local rec = types.Light.record(lightRecordId)
        if rec and rec.name then
            lightName = rec.name:lower()
        end
    end)
    
    -- Hardcoded offsets based on light type
    if lightName:find("torch") then
        return 10
    elseif lightName:find("lantern") then
        return -41
    elseif lightName:find("candle") then
        return -10
    else
        return getVfxOffsetAttach()  -- use setting as fallback
    end
end
local function getVfxScaleConjure()
    local s = tonumber(settingsCache.vfxScaleConjure) or 0.3
    return math.max(0.05, math.min(1.0, s))
end

local function getVfxScaleAttach()
    local s = tonumber(settingsCache.vfxScaleAttach) or 0.2
    return math.max(0.05, math.min(1.0, s))
end

local function getVfxScaleWispHaggle()
    local s = tonumber(settingsCache.vfxScaleWispHaggle) or 0.2
    return math.max(0.05, math.min(1.0, s))
end

local function isLightPositionRight()
    return tostring(settingsCache.lightPosition):lower() == "right"
end

local function getVfxOffsetConjure()
    local o = tonumber(settingsCache.vfxOffsetConjure) or -50
    return math.max(-100, math.min(100, o))
end

local function getVfxOffsetAttach()
    local o = tonumber(settingsCache.vfxOffsetAttach) or -50
    return math.max(-100, math.min(100, o))
end

-- Convenience: returns the correct offset for whatever spell is currently active.
-- Returns 0 for spell types that have no separate anchor (wisp, haggle).
local function getVfxOffsetForActiveSpell()
    if not activeSpell then return 0 end
    if activeSpell.type == 'animate' then return getVfxOffsetConjure() end
    if activeSpell.type == 'attach' then
        -- Use the stored computed offset (context-sensitive to light type)
        return activeSpell.attachVfxOffset or getVfxOffsetAttach()
    end
    return 0
end

-- ============================================================
-- GENERAL HELPERS
-- ============================================================
local function showMsg(player, message)
    if player and player:isValid() and message and message ~= '' then
        player:sendEvent('ShowMessage', { message = message })
    end
end

local function getMercantileSkill(actor)
    local skill = 0
    local ok = pcall(function()
        local s = types.Actor.stats.skills.mercantile(actor)
        skill = (s.modified ~= nil) and s.modified or (s.base or 0)
    end)
    if not ok then
        pcall(function()
            local s = types.NPC.stats.skills.mercantile(actor)
            skill = (s.modified ~= nil) and s.modified or (s.base or 0)
        end)
    end
    return tonumber(skill) or 0
end

local function safeRemove(obj)
    if not obj or not obj:isValid() then return end
    pcall(function()
        if obj.enabled ~= nil then obj.enabled = false end
        obj:remove()
    end)
end

local function safeStopLoop(soundId, obj)
    if obj and obj:isValid() then
        pcall(function() core.sound.stopSound3d(soundId, obj) end)
    end
end

local function hasSpell(actor, spellId)
    for _, spell in pairs(types.Actor.spells(actor)) do
        if spell.id == spellId then return true end
    end
    return false
end

-- ============================================================
-- SPELL / EFFECT ID TABLES
-- ============================================================
local WATCHED_SPELLS = {
    attach_lantern_spell  = 'attachLantern',
    animate_lantern_spell = 'animateLantern',
    light_wisp_spell      = 'lightWisp',
    haggle_light_spell    = 'haggleLight',
    detach_light_spell    = 'detachLight',
}

local ARCANE_EFFECTS = {
    animate_lantern_mgef = 'animateLantern',
    attach_lantern_mgef  = 'attachLantern',
    light_wisp_mgef      = 'lightWisp',
    haggle_light_mgef    = 'haggleLight',
    detach_light_mgef    = 'detachLight',
}

local function resolveEffectId(key)
    if not key then return nil end
    if key == 'animateLantern' or key == 'animate' then return 'animate_lantern_mgef' end
    if key == 'attachLantern'  or key == 'attach'  then return 'attach_lantern_mgef'  end
    if key == 'lightWisp'      or key == 'wisp'    then return 'light_wisp_mgef'      end
    if key == 'haggleLight'    or key == 'haggle'  then return 'haggle_light_mgef'    end
    if key == 'detachLight'    or key == 'detach'  then return 'detach_light_mgef'    end
    if ARCANE_EFFECTS[key] then return key end
    return nil
end

-- ============================================================
-- EFFECT REMOVAL
-- ============================================================
local function removeAllArcaneEffects(player, keepKey)
    if not (player and player:isValid()) then return end
    local keepEffectId = resolveEffectId(keepKey)
    local arcaneEffectIds = {
        'animate_lantern_mgef',
        'attach_lantern_mgef',
        'light_wisp_mgef',
        'haggle_light_mgef',
        'detach_light_mgef',
    }
    local effects = types.Actor.activeEffects(player)
    for _, effectId in ipairs(arcaneEffectIds) do
        if not (keepEffectId and effectId == keepEffectId) then
            pcall(function()
                effects:remove(effectId)
                debugLog("Removed effect: " .. effectId)
            end)
        end
    end
end

-- ============================================================
-- EFFECT-BASED SPELL DETECTION
-- ============================================================
local detectArcaneSpellByEffects

detectArcaneSpellByEffects = function(activeSpellData, instanceId)
    local spellId = ''
    if activeSpellData.id then
        spellId = activeSpellData.id:lower()
    elseif activeSpellData.spell and activeSpellData.spell.id then
        spellId = activeSpellData.spell.id:lower()
    end

    local legacyHandler = WATCHED_SPELLS[spellId]
    if legacyHandler then return legacyHandler end

    local effects = nil
    if activeSpellData.effects and type(activeSpellData.effects) == 'table' then
        effects = activeSpellData.effects
    end
    if not effects and activeSpellData.spell and activeSpellData.spell.effects then
        effects = activeSpellData.spell.effects
    end
    if not effects and spellId and spellId ~= '' then
        local spellRecord = nil
        pcall(function() spellRecord = core.magic.spells.records[spellId] end)
        if spellRecord and spellRecord.effects then
            effects = spellRecord.effects
        end
    end
    if not effects then return nil end

    for _, effect in ipairs(effects) do
        local effectId = effect.id
        if effectId then
            local handler = ARCANE_EFFECTS[effectId]
            if handler then
                if not seenActiveSpellIds[instanceId] then
                    debugLog("Detected custom spell with effect: " .. tostring(effectId) .. " -> " .. handler)
                end
                return handler
            end
        end
    end
    return nil
end

-- ============================================================
-- RECORD CREATION HELPERS
-- ============================================================
local function ensureWispRecords()
    if WISP_ORB_REC and WISP_LIGHT_REC then return true end
    local ok = pcall(function()
        if not WISP_ORB_REC then
            local orbDraft = types.Activator.createRecordDraft({
                name  = 'Light Wisp Orb',
                model = 'meshes/magic_target_ill_nc.nif',
            })
            WISP_ORB_REC = world.createRecord(orbDraft).id
        end
        if not WISP_LIGHT_REC then
            local lightDraft = types.Light.createRecordDraft({
                name        = 'Light Wisp Glow',
                model       = 'meshes/EditorMarker.NIF',
                duration    = 1000000,
                radius      = 450,
                color       = util.color.rgb(1.0, 0.95, 0.8),
                isDynamic   = true,
                isCarriable = false,
            })
            WISP_LIGHT_REC = world.createRecord(lightDraft).id
        end
    end)
    return ok
end

local function ensureAnimateVfxAnchorRecord()
    if ANIMATE_VFX_ANCHOR_REC then return true end
    local ok, result = pcall(function()
        local draft = types.Activator.createRecordDraft({
            name  = 'AI_AnimateLantern_VfxAnchor',
            model = ANIMATE_VFX_ANCHOR_MODEL,
        })
        local rec = world.createRecord(draft)
        ANIMATE_VFX_ANCHOR_REC = rec.id
        debugLog("AnimateLantern VFX anchor record created: " .. tostring(ANIMATE_VFX_ANCHOR_REC))
    end)
    if not ok then
        debugLog("ERROR creating AnimateLantern VFX anchor record: " .. tostring(result))
        return false
    end
    return true
end

local function ensureConjuredLightRecord(srcRecId)
    if ANIMATE_LANTERN_RECORD_CACHE[srcRecId] then return ANIMATE_LANTERN_RECORD_CACHE[srcRecId] end
    local srcRec = nil
    local okRec, recOrErr = pcall(function() return types.Light.record(srcRecId) end)
    if okRec then srcRec = recOrErr end
    if not srcRec then
        debugLog("ensureConjuredLightRecord: could not read Light record for " .. tostring(srcRecId))
        return srcRecId
    end
    local ok, result = pcall(function()
        local draft = types.Light.createRecordDraft({
            name           = srcRec.name,
            model          = srcRec.model,
            icon           = srcRec.icon,
            weight         = srcRec.weight,
            value          = srcRec.value,
            duration       = srcRec.duration,
            radius         = srcRec.radius,
            color          = srcRec.color,
            isCarriable    = false,
            isOffByDefault = false,
            isFire         = srcRec.isFire,
            isFlicker      = srcRec.isFlicker,
            isFlickerSlow  = srcRec.isFlickerSlow,
            isPulse        = srcRec.isPulse,
            isPulseSlow    = srcRec.isPulseSlow,
            isDynamic      = true,
            isNegative     = srcRec.isNegative,
        })
        local rec = world.createRecord(draft)
        return rec.id
    end)
    if ok then
        ANIMATE_LANTERN_RECORD_CACHE[srcRecId] = result
        debugLog("Created conjured light record: " .. tostring(result))
        return result
    else
        debugLog("ERROR creating conjured light record for " .. srcRecId .. ": " .. tostring(result))
        return srcRecId
    end
end

local function createAttachLanternRecord(sourceRecordId, dur)
    local cacheKey = sourceRecordId .. '_' .. tostring(dur)
    if ATTACH_LANTERN_RECORD_CACHE[cacheKey] then
        return ATTACH_LANTERN_RECORD_CACHE[cacheKey]
    end

    local sourceRecord = types.Light.record(sourceRecordId)
    if not sourceRecord then
        debugLog("createAttachLanternRecord: cannot read record for " .. tostring(sourceRecordId))
        return nil
    end

    local ok, result = pcall(function()
        local draft = types.Light.createRecordDraft({
            name          = sourceRecord.name,
            model         = sourceRecord.model,
            icon          = sourceRecord.icon,
            weight        = sourceRecord.weight,
            value         = sourceRecord.value,
            radius        = sourceRecord.radius,
            color         = sourceRecord.color,
            isCarriable   = sourceRecord.isCarriable,
            isDynamic     = true,
            isOffByDefault = false,
            isFire        = sourceRecord.isFire,
            isFlicker     = sourceRecord.isFlicker,
            isFlickerSlow = sourceRecord.isFlickerSlow,
            isPulse       = sourceRecord.isPulse,
            isPulseSlow   = sourceRecord.isPulseSlow,
            isNegative    = sourceRecord.isNegative,
            sound         = sourceRecord.sound,
            duration      = dur,   -- NOTE: 'duration', not 'time'
            script        = sourceRecord.script,
        })
        return world.createRecord(draft).id
    end)

    if ok and result then
        ATTACH_LANTERN_RECORD_CACHE[cacheKey] = result
        debugLog("Created attach lantern record: " .. tostring(result))
        return result
    else
        debugLog("ERROR creating attach lantern record for "
            .. tostring(sourceRecordId) .. ": " .. tostring(result))
        return nil
    end
end

local function ensureHaggleContainerRecord(rawCapacity)
    local multiplier  = getHaggleMagnitudeMultiplier()
    local adjustedCap = math.max(1, math.floor(rawCapacity * multiplier))
    if HAGGLE_CONTAINER_RECS[adjustedCap] then return HAGGLE_CONTAINER_RECS[adjustedCap] end
    local ok, recOrErr = pcall(function()
        local draft = types.Container.createRecordDraft({
            name         = 'Haggle-light',
            model        = HAGGLE_ORB_MODEL,
            weight       = adjustedCap,
            isOrganic    = false,
            isRespawning = false,
        })
        return world.createRecord(draft)
    end)
    if not ok then
        debugLog("ERROR creating haggle container record: " .. tostring(recOrErr))
        return nil
    end
    HAGGLE_CONTAINER_RECS[adjustedCap] = recOrErr.id
    debugLog("Created haggle container record " .. tostring(recOrErr.id)
        .. " adjustedCapacity=" .. tostring(adjustedCap))
    return recOrErr.id
end

local function ensureHaggleLightRecord()
    if HAGGLE_LIGHT_REC then return true end
    local ok, result = pcall(function()
        local draft = types.Light.createRecordDraft({
            name           = 'Haggle-light Glow',
            model          = 'meshes/EditorMarker.NIF',
            weight         = 0,
            value          = 0,
            duration       = 1000000,
            radius         = 450,
            color          = util.color.rgb(1.0, 0.95, 0.8),
            isCarriable    = false,
            isDynamic      = true,
            isOffByDefault = false,
            isNegative     = false,
            isFire         = false,
            isFlicker      = false,
            isFlickerSlow  = false,
            isPulse        = false,
            isPulseSlow    = false,
        })
        local rec = world.createRecord(draft)
        HAGGLE_LIGHT_REC = rec.id
        debugLog("Haggle light record created: " .. tostring(HAGGLE_LIGHT_REC))
    end)
    if not ok then
        debugLog("ERROR creating haggle light record: " .. tostring(result))
        return false
    end
    return true
end

-- ============================================================
-- ITEM VALUE HELPER
-- ============================================================
local function getItemGoldValue(item)
    local count = item.count or 1
    local rec, ok = nil, false
    if     item.type == types.Weapon        then ok, rec = pcall(types.Weapon.record,        item)
    elseif item.type == types.Armor         then ok, rec = pcall(types.Armor.record,         item)
    elseif item.type == types.Clothing      then ok, rec = pcall(types.Clothing.record,      item)
    elseif item.type == types.Book          then ok, rec = pcall(types.Book.record,           item)
    elseif item.type == types.Ingredient    then ok, rec = pcall(types.Ingredient.record,    item)
    elseif item.type == types.Potion        then ok, rec = pcall(types.Potion.record,         item)
    elseif item.type == types.Miscellaneous then ok, rec = pcall(types.Miscellaneous.record, item)
    elseif item.type == types.Light         then ok, rec = pcall(types.Light.record,          item)
    elseif item.type == types.Apparatus     then ok, rec = pcall(types.Apparatus.record,     item)
    elseif item.type == types.Lockpick      then ok, rec = pcall(types.Lockpick.record,      item)
    elseif item.type == types.Probe         then ok, rec = pcall(types.Probe.record,          item)
    elseif item.type == types.Repair        then ok, rec = pcall(types.Repair.record,         item)
    end
    if ok and rec and rec.value then return rec.value * count end
    return 0
end

-- ============================================================
-- INVENTORY HELPERS
-- ============================================================
local function findBestLightInInventory(player)
    local bestItem, bestRemaining = nil, 0
    local blacklistedCount, totalLightsFound = 0, 0

    for _, item in pairs(types.Actor.inventory(player):getAll()) do
        if item.type == types.Light then
            totalLightsFound = totalLightsFound + 1

            -- We **no longer** exclude “Generated:” records; every attach lamp
            -- is fair game because the spell now gives the same record back.
            -- (Was:  if not item.recordId:find("^Generated:") then … end)

            local rec = types.Light.record(item)
            if rec and rec.isCarriable then
                local lowerId = item.recordId:lower()
                if ATTACH_LIGHT_BLACKLIST[lowerId] then
                    blacklistedCount = blacklistedCount + 1
                    debugLog("Skipping blacklisted light: " .. item.recordId)
                else
                    local remaining
                    local data = types.Item.itemData(item)
                    if data and data.condition then
                        remaining = (data.condition == -1) and math.huge or data.condition
                    else
                        remaining = rec.duration or 0
                    end
                    if remaining > bestRemaining then
                        bestRemaining = remaining
                        bestItem      = item
                    end
                end
            end
        end
    end

    if bestRemaining == math.huge then bestRemaining = 86400 end
    if not bestItem and blacklistedCount > 0 and totalLightsFound == blacklistedCount then
        return nil, 0, "This light is of a bigger importance, I cannot sacrifice it."
    end
    return bestItem, bestRemaining, nil
end

-- ============================================================
-- SPAWN POSITION HELPER
-- ============================================================
local function getSuspensionPos(player)
    local fwd   = player.rotation * util.vector3(0, 1, 0)
    local right = player.rotation * util.vector3(1, 0, 0)
    local sideDir = isLightPositionRight() and right or (right * -1)
    local spawnOffset = fwd * ORBIT_RADIUS
                      + sideDir * SPAWN_LEFT_BIAS
                      + util.vector3(0, 0, 100)
    return player.position + spawnOffset, fwd:normalize()
end
-- ============================================================
-- REMOVE ACTIVE SPELL
-- ============================================================
local function removeActiveSpell(reason)
    if not activeSpell then return end

    local state = activeSpell
    activeSpell = nil

    debugLog("Removing active spell objects: "
        .. tostring(state.type) .. " (reason: " .. tostring(reason or "unknown") .. ")")

    ------------------------------------------------------------------
    -- PATCH B – Always stop the particle emitter on the anchor first
    ------------------------------------------------------------------
    if state.vfxAnchor and state.vfxAnchor:isValid() then
        pcall(function()
            state.vfxAnchor:sendEvent('ArcaneLight_StopVfx',
                                      { vfxId = 'ArcaneLight_HangVfx' })
        end)
    end

    debugLog("Removing active spell objects: "
        .. tostring(state.type) .. " (reason: " .. tostring(reason or "unknown") .. ")")

    -- Play torch out sound on expiry for animate and attach
    if reason == 'expired' and (state.type == 'animate' or state.type == 'attach') then
        if state.attacker and state.attacker:isValid() then
            pcall(function()
                core.sound.playSound3d('torch out', state.attacker, { volume = 0.8, pitch = 1.0 })
            end)
        end
    end

    -- Haggle handling
    if state.type == 'haggle' then
        if reason == 'expired' or reason == 'sealed' then
            if state.containerObj and state.containerObj:isValid() then
                local player = state.attacker
                if player and player:isValid() then
                    debugLog("Haggle-light auto-sealing during removal...")
                    pcall(function() processHaggleContainer(player, state.containerObj) end)
                end
            end
        elseif reason == 'canceled' or reason == 'dispelled' or reason == 'recast_or_replaced' then
            if state.containerObj and state.containerObj:isValid() then
                local player = state.attacker
                if player and player:isValid() then
                    debugLog("Haggle-light cancelled, returning items...")
                    pcall(function() returnHaggleItems(player, state.containerObj) end)
                end
            end
        end
    end

        -- SPECIAL HANDLING FOR ATTACH LIGHT
    -- When the attach spell ends for ANY reason (except manual cancel),
    -- return the light to inventory with remaining duration.
if state.type == 'attach' and reason ~= 'canceled' and reason ~= 'sealed' and reason ~= 'expired' then
        -- Check if we should create a return item (only once)
        local shouldCreateItem = not state.pickupProcessed
        
        if shouldCreateItem then
            state.pickupProcessed = true  -- mark as processed
            
            local player = state.attacker
            if player and player:isValid() then
                local nowSim = core.getSimulationTime()
                local remainingDuration = math.max(1, (state.expiresAt or nowSim) - nowSim)

                -- Use sourceRecordId (generated) to maintain our "keep generated record" fix
                local recordToReturn = state.originalSourceRecordId or state.sourceRecordId
                
                if not recordToReturn then
                    debugLog("ERROR: No sourceRecordId found for attach light, cannot return to inventory")
                else
                    debugLog("Attach light removal (" .. reason .. "): returning " .. recordToReturn 
                        .. " to inventory with " .. string.format("%.1f", remainingDuration) .. "s remaining")

                    -- Create item with the generated record (as per our earlier fix)
                    local returnedItem = world.createObject(recordToReturn, 1)
                    if returnedItem and returnedItem:isValid() then
                        pcall(function()
                            local itemData = types.Item.itemData(returnedItem)
                            if itemData then
                                itemData.condition = remainingDuration
                            end
                        end)

                        local ok, err = pcall(function()
                            returnedItem:moveInto(types.Actor.inventory(player))
                        end)

                        if not ok then
                            debugLog("Return to inventory failed: " .. tostring(err) .. " — dropping at player feet")
                            returnedItem:teleport(player.cell.name, player.position)
                        else
                            debugLog("Successfully returned attach light to inventory")
                            -- Show message for player-initiated actions
                            if reason == 'detached' or reason == 'recast_or_replaced' then
                                --showMsg(player, "Attached light returned to inventory ("
                                --  .. string.format("%.0f", remainingDuration) .. "s remaining)")
                            end
                        end
                    else
                        debugLog("ERROR: Failed to create return item for attach light")
                    end
                end
            end
        else
            debugLog("Attach pickup already processed, skipping duplicate item creation")
        end
    -- On expiry: world object must still be removed even though we don't return the item
    if state.type == 'attach' and reason == 'expired' then
        if state.lightObj and state.lightObj:isValid() then
            pickedUpLights[state.lightObj.id] = true
            safeRemove(state.lightObj)
            debugLog("Expired attach light removed from world (not returned to inventory)")
        end
        state.lightObj = nil
    end
        -- ALWAYS clean up world object, even if we skipped item creation above
        -- (This handles the case where removeActiveSpell is called multiple times)
        if state.lightObj and state.lightObj:isValid() then
            pickedUpLights[state.lightObj.id] = true
            safeRemove(state.lightObj)
            debugLog("Removed attach light world object")
        end

        -- Nil the reference so the main cleanup loop below does nothing
        state.lightObj = nil
    end

    -- Main cleanup loop (skips lightObj for attach picked_up / replaced cases)
    if state.lightObj     then safeRemove(state.lightObj) end
    if state.vfxAnchor    then safeRemove(state.vfxAnchor) end
    if state.containerObj then safeRemove(state.containerObj) end
    if state.orbObj       then safeRemove(state.orbObj) end

    if state.proj and state.proj:isValid() then
        pcall(function() safeStopLoop(HOVER_SOUND, state.proj) end)
        pcall(function() state.proj:sendEvent('MagExp_ForceCancel') end)
        safeRemove(state.proj)
    end

    local player = state.attacker
    if player and player:isValid() then
        local endEvent = nil
        if     state.type == 'animate' then endEvent = 'AnimateLantern_Ended'
        elseif state.type == 'attach'  then endEvent = 'AttachLantern_Ended'
        elseif state.type == 'wisp'    then endEvent = 'LightWisp_Ended'
        elseif state.type == 'haggle'  then endEvent = 'HaggleLight_Ended'
        end
        if endEvent then player:sendEvent(endEvent, {}) end
    end
end
-- ============================================================
-- ACTIVATION HANDLER HELPERS
-- ============================================================
local function installBlockPickupHandler(obj, spellName)
    if not (obj and obj:isValid()) then return end
    I.Activation.addHandlerForObject(obj, function(object, actor)
        if object ~= obj then return end
        if actor and actor:isValid() then
            --showMsg(actor, "Cannot pick up conjured " .. (spellName or "light"))
        end
        return false
    end)
    debugLog("Installed pickup blocker for " .. (spellName or "light") .. " object")
end

local function installAttachedLightPickupHandler(obj, originalSourceRecordId, expiresAt)
    if not (obj and obj:isValid()) then return end
    
    I.Activation.addHandlerForObject(obj, function(object, actor)
        if object ~= obj then return end
        if pickedUpLights[obj.id] then return true end
        pickedUpLights[obj.id] = true

        local player = actor
        if not (player and player:isValid()) then return end

        debugLog("Pickup handler: player activated attached light, ending spell")

        if activeSpell and activeSpell.type == 'attach' then
            activeSpell.pickupProcessed = true
        end

        if activeSpell and activeSpell.type == 'attach' then
            removeAllArcaneEffects(player)
            removeActiveSpell("picked_up")
        end

        return true
    end)
    
    debugLog("Installed attached light pickup handler for object")
end

-- ============================================================
-- FORWARD DECLARATIONS  ← ← ← MOVE THIS BLOCK HERE
-- ============================================================
local processHaggleContainer
local sealHaggleLight

-- ============================================================
-- HAGGLE-LIGHT activation handler
-- ============================================================
local function installHaggleActivationHandler(containerObj)
    I.Activation.addHandlerForObject(containerObj, function(object, actor)
        local state = activeSpell
        if not state or state.type ~= 'haggle' or state.containerObj ~= object then
            return
        end

        if actor ~= state.attacker then
            if actor and actor:isValid() then
                showMsg(actor, "This Haggle-light belongs to someone else")
            end
            return false
        end

        if not state.openedOnce then
            state.openedOnce = true
            state.openedAt   = core.getSimulationTime()
            state.autoSealAt = state.openedAt + 60
            debugLog("Haggle-light opened – auto-seal in 60 s")
            return
        end

        debugLog("Haggle-light second activation – sealing now")
        sealHaggleLight(state.attacker, state.containerObj)
        return false
    end)
end

-- ============================================================
-- HAGGLE HELPERS
-- ============================================================
local function returnHaggleItems(player, containerObj)
    if not (containerObj and containerObj:isValid()) then return end
    if not (player and player:isValid()) then return end
    debugLog("Returning all items from Haggle-light container to player")
    local items = types.Container.inventory(containerObj):getAll()
    local returnedCount = 0
    for _, item in pairs(items) do
        local ok, err = pcall(function()
            item:moveInto(types.Actor.inventory(player))
            returnedCount = returnedCount + (item.count or 1)
        end)
        if not ok then
            debugLog("ERROR returning item " .. item.recordId .. ": " .. tostring(err))
        end
    end
    if returnedCount > 0 then
        showMsg(player, "Haggle-light: " .. returnedCount .. " item(s) returned to inventory")
        debugLog("Returned " .. returnedCount .. " items to player")
    end
end

processHaggleContainer = function(player, containerObj)
    if not (containerObj and containerObj:isValid()) then return end
    if not (player and player:isValid()) then return end
    local items        = types.Container.inventory(containerObj):getAll()
    local totalValue   = 0
    local itemCount    = 0
    local removedCount = 0
    for _, item in pairs(items) do
        local count = item.count or 1
        itemCount = itemCount + count
        if PROTECTED_ITEMS[item.recordId:lower()] then
            local ok, err = pcall(function() item:moveInto(types.Actor.inventory(player)) end)
            if ok then
                local msg = "Haggle-light: Protected item returned: " .. item.recordId
                player:sendEvent('ShowMessage', { message = msg })
                debugLog(msg)
            else
                debugLog("ERROR returning protected item " .. item.recordId .. ": " .. tostring(err))
            end
        else
            totalValue   = totalValue + getItemGoldValue(item)
            removedCount = removedCount + count
            pcall(function() item:remove() end)
        end
    end
    local merc          = util.clamp(getMercantileSkill(player), 0, 100)
    local ratio         = getHaggleMercantileRatio()
    local payoutPercent = util.clamp(merc * ratio, 0, 100)
    local goldReward    = math.floor(totalValue * (payoutPercent / 100.0))
    if goldReward == 0 and totalValue > 0 then goldReward = 1 end
    
    print(string.format(
        "[Arcane Illumination] Haggle-light: total=%d merc=%.1f ratio=%.3f payoutPct=%.1f%% gold=%d",
        totalValue, merc, ratio, payoutPercent, goldReward))
    if goldReward > 0 then
        pcall(function()
            core.sound.playSound3d('Item Gold Up', player, { volume = 1.0, loop = false, pitch = 1.0 })
        end)
        local itemWord = (removedCount == 1) and "item" or "items"
        local msg = string.format(
            "Haggle-light: Earned %d gold (%.0f%%) for haggling %d %s.",
            goldReward, payoutPercent, removedCount, itemWord)
        player:sendEvent('ShowMessage', { message = msg })
        local goldObj = world.createObject(GOLD_REC, goldReward)
        if goldObj and goldObj:isValid() then
            local ok, err = pcall(function() goldObj:moveInto(types.Actor.inventory(player)) end)
            if not ok then
                debugLog("moveInto gold failed: " .. tostring(err) .. " — dropping at player feet")
                goldObj:teleport(player.cell.name, player.position)
            else
                debugLog("Awarded " .. goldReward .. " gold to player")
            end
        end
    else
        debugLog("No items in container / no gold awarded")
    end
end

sealHaggleLight = function(player, containerObj)
    if not activeSpell or activeSpell.type ~= 'haggle' then return end
    local attacker = player or activeSpell.attacker
    local obj      = containerObj or activeSpell.containerObj
    debugLog("Haggle-light sealing deal...")
    processHaggleContainer(attacker, obj)
    removeAllArcaneEffects(attacker)
    removeActiveSpell("sealed")
end
-- ============================================================
-- DURATION TOOLTIP UPDATE (attach only)
-- ============================================================
local function updateLightDuration()
    if not activeSpell or activeSpell.type ~= 'attach' then return end
    local lightObj = activeSpell.lightObj
    if not (lightObj and lightObj:isValid()) then return end
    local nowSim    = core.getSimulationTime()
    local remaining = math.max(0, activeSpell.expiresAt - nowSim)
    if remaining < 0.5 then return end
    pcall(function()
        local data = types.Item.itemData(lightObj)
        if data then data.condition = remaining end
    end)
    debugLog("Updated light duration tooltip: " .. string.format("%.1f", remaining) .. "s remaining")
end

-- ============================================================
-- CAST TRIGGER FUNCTIONS
-- ============================================================
local function triggerAnimateLantern(player, spellDuration)
    debugLog("Triggering Conjure Lantern (Animate Lantern)")
    removeActiveSpell("recast_or_replaced")
    local spawnPos, direction = getSuspensionPos(player)
    local lanternRecId  = pickRandomLantern()
    local conjuredRecId = ensureConjuredLightRecord(lanternRecId)
    local lightObj = world.createObject(conjuredRecId, 1)
    if not (lightObj and lightObj:isValid()) then
        debugLog("ERROR: could not create Animate Lantern light object")
        return
    end
    lightObj:teleport(player.cell.name, spawnPos)
    local spawnedCellName = player.cell.name
    pcall(function()
        lightObj:addScript('scripts/arcane_illumination/arcane_illumination_light_local.lua')
    end)
    if not ensureAnimateVfxAnchorRecord() then
        safeRemove(lightObj)
        return
    end
    local vfxAnchor = world.createObject(ANIMATE_VFX_ANCHOR_REC, 1)
    if not (vfxAnchor and vfxAnchor:isValid()) then
        debugLog("ERROR: could not create Animate Lantern VFX anchor object")
        safeRemove(lightObj)
        return
    end
    vfxAnchor:teleport(player.cell.name, spawnPos + util.vector3(0, 0, getVfxOffsetConjure()))
    pcall(function()
        vfxAnchor:addScript('scripts/arcane_illumination/arcane_illumination_light_local.lua')
    end)
    vfxAnchor:setScale(getVfxScaleConjure())
    vfxAnchor:sendEvent('ArcaneLight_InitVfx', {
        model = 'meshes/e/magic_hit.NIF',
        vfxId = 'AnimateLantern_HangVfx',
    })
    
    if ANIMATE_LANTERN_BLOCK_PICKUP then
        installBlockPickupHandler(lightObj, "Conjured Lantern")
        installBlockPickupHandler(vfxAnchor, "Conjured Lantern VFX")
    end
    local now = core.getSimulationTime()
    local dur = tonumber(spellDuration) or 0
    if dur <= 0 then dur = ANIMATE_LANTERN_LIFETIME end
    activeSpell = {
        type         = 'animate',
        handlerKey   = 'animateLantern',
        effectId     = resolveEffectId('animateLantern'),
        attacker     = player,
        lightObj     = lightObj,
        vfxAnchor    = vfxAnchor,
        dir          = (direction and direction:normalize()) or util.vector3(0, 1, 0),
        pos          = spawnPos,
        cellName     = spawnedCellName,
        expiresAt    = now + dur,
        startedAt    = now,
        lanternRecId = lanternRecId,
    }
    player:sendEvent('AnimateLantern_Started', {})
    debugLog("Conjure Lantern active (" .. tostring(lanternRecId) .. "), expires in " .. tostring(dur) .. "s")
end

local function triggerAttachLantern(player)
    debugLog("Triggering Attach Lantern")
    removeActiveSpell("recast_or_replaced")

    local bestItem, remainingTime, errorMsg = findBestLightInInventory(player)
    if not bestItem then
        local reason = errorMsg or "No carriable light item in inventory"
        debugLog("No light found: " .. reason)
        if errorMsg then showMsg(player, errorMsg) end
        removeAllArcaneEffects(player)
        return
    end

    local sourceRecordId = bestItem.recordId
    local stackCount     = bestItem.count or 1

    -- Resolve duration before anything else
    local dur = tonumber(remainingTime) or 0
    if dur == math.huge then dur = 86400 end
    if dur <= 0 then dur = 1 end

    debugLog("Pre-found light: " .. sourceRecordId .. " x" .. stackCount
        .. " | duration=" .. tostring(dur))

    -- ----------------------------------------------------------------
    -- STEP 1: Create the world record BEFORE touching inventory.
    -- ----------------------------------------------------------------
    local generatedId = createAttachLanternRecord(sourceRecordId, dur)
    if not generatedId then
        debugLog("ERROR: could not create attach lantern record for " .. sourceRecordId)
        removeAllArcaneEffects(player)
        return
    end

    -- ----------------------------------------------------------------
    -- STEP 2: Spawn the world object BEFORE touching inventory.
    -- ----------------------------------------------------------------
    local spawnPos, direction = getSuspensionPos(player)
    local lightObj = world.createObject(generatedId, 1)
    if not (lightObj and lightObj:isValid()) then
        debugLog("ERROR: could not create attach world light object")
        removeAllArcaneEffects(player)
        return
    end

    pcall(function() lightObj:teleport(player.cell.name, spawnPos) end)

    if not lightObj:isValid() then
        debugLog("Teleport failed for attach light, object invalid")
        safeRemove(lightObj)
        removeAllArcaneEffects(player)
        return
    end

    -- ----------------------------------------------------------------
    -- STEP 3: World object is live — NOW safely consume the inventory item.
    -- ----------------------------------------------------------------
    if stackCount > 1 then
        local remainder = world.createObject(sourceRecordId, stackCount - 1)
        if remainder and remainder:isValid() then
            local ok, err = pcall(function()
                remainder:moveInto(types.Actor.inventory(player))
            end)
            if not ok then
                debugLog("moveInto remainder failed, dropping: " .. tostring(err))
                remainder:teleport(player.cell.name, player.position)
            end
        end
    end

    local itemData = types.Item.itemData(bestItem)
    if itemData then pcall(function() itemData.condition = nil end) end

    local okRem, errRem = pcall(function() bestItem:remove() end)
    if not okRem then
        debugLog("Item removal failed: " .. tostring(errRem))
        safeRemove(lightObj)
        removeAllArcaneEffects(player)
        return
    end

    -- ----------------------------------------------------------------
    -- STEP 4: Stamp condition and add scripts to the light object.
    -- ----------------------------------------------------------------
    pcall(function()
        local data = types.Item.itemData(lightObj)
        if data then data.condition = -1 end   -- prevent engine expiry
    end)

    pcall(function()
        lightObj:addScript('scripts/arcane_illumination/arcane_illumination_light_local.lua')
    end)

    -- ----------------------------------------------------------------
    -- STEP 5: Create VFX anchor with context-sensitive offset
    -- ----------------------------------------------------------------
    local attachVfxAnchor = nil
    local computedOffset = getAttachVfxOffsetForLight(sourceRecordId)  -- ← compute once
    
    if ensureAnimateVfxAnchorRecord() then
        local anchor = world.createObject(ANIMATE_VFX_ANCHOR_REC, 1)
        if anchor and anchor:isValid() then
            anchor:teleport(player.cell.name, spawnPos + util.vector3(0, 0, computedOffset))
            anchor:setScale(getVfxScaleAttach())
            pcall(function()
                anchor:addScript('scripts/arcane_illumination/arcane_illumination_light_local.lua')
            end)
            if ANIMATE_LANTERN_BLOCK_PICKUP then
                installBlockPickupHandler(anchor, "Attached Light VFX")
            end
            anchor:sendEvent('ArcaneLight_InitVfx', {
                model = 'meshes/e/magic_hit.NIF',
                vfxId = 'ArcaneLight_HangVfx',
            })
            attachVfxAnchor = anchor
        end
    else
        debugLog("Attach: could not create VFX anchor record")
    end

    -- ----------------------------------------------------------------
    -- STEP 6: NOW create activeSpell including the computed offset
    -- ----------------------------------------------------------------
    local now = core.getSimulationTime()
    lightValidityCheckTime = now + ATTACH_STARTUP_GRACE

    activeSpell = {
        type                   = 'attach',
        handlerKey             = 'attachLantern',
        effectId               = resolveEffectId('attachLantern'),
        attacker               = player,
        lightObj               = lightObj,
        vfxAnchor              = attachVfxAnchor,
        attachVfxOffset        = computedOffset,  -- ← store it so position updates use it
        dir                    = direction:normalize(),
        pos                    = spawnPos,
        cellName               = player.cell.name,
        expiresAt              = now + dur,
        startedAt              = now,
        sourceRecordId         = generatedId,
        originalSourceRecordId = sourceRecordId,
        startupGraceUntil      = now + ATTACH_STARTUP_GRACE,
    }

    installAttachedLightPickupHandler(lightObj, sourceRecordId, activeSpell.expiresAt)
    player:sendEvent('AttachLantern_Started', {})
    debugLog("Attach Lantern active, expires in " .. tostring(dur) .. "s")
end

local function triggerHaggleLight(player, magnitude)
    debugLog("Triggering Haggle-light magnitude=" .. tostring(magnitude or 1))
    removeActiveSpell("recast_or_replaced")
    if isHaggleCooldownEnabled() then
        local now = core.getGameTime()
        if haggleLastUsedTime then
            local cooldownHours    = getHaggleCooldownHours()
            local cooldownDuration = cooldownHours * 3600
            local timeSinceLastUse = now - haggleLastUsedTime
            if timeSinceLastUse < cooldownDuration then
                local remainingTime    = cooldownDuration - timeSinceLastUse
                local remainingHours   = math.floor(remainingTime / 3600)
                local remainingMinutes = math.floor((remainingTime % 3600) / 60)
                showMsg(player, string.format("Haggle-light cooldown: %dh %dm remaining",
                    remainingHours, remainingMinutes))
                return
            end
        end
    end
    magnitude = math.max(1, math.min(100, math.floor(magnitude or 1)))
    local rawCapacity    = math.max(1, math.floor(magnitude / 2))
    local containerRecId = ensureHaggleContainerRecord(rawCapacity)
    if not containerRecId then return end
    if not ensureHaggleLightRecord() then return end
    local spawnPos, direction = getSuspensionPos(player)
    local containerObj = world.createObject(containerRecId, 1)
    if not (containerObj and containerObj:isValid()) then return end
    containerObj:teleport(player.cell.name, spawnPos)
    containerObj:setScale(HAGGLE_ORB_SCALE)
    -- ADD THESE THREE LINES:
    pcall(function()
    containerObj:addScript('scripts/arcane_illumination/arcane_illumination_light_local.lua')
    end)
    containerObj:sendEvent('ArcaneLight_InitVfx', {
    model = 'meshes/e/magic_hit.NIF',
    vfxId = 'HaggleLight_HangVfx',
})
    local lightObj = world.createObject(HAGGLE_LIGHT_REC, 1)
    if not (lightObj and lightObj:isValid()) then
        safeRemove(containerObj)
        return
    end
    lightObj:teleport(player.cell.name, spawnPos)
    haggleLastUsedTime = core.getGameTime()
    local now = core.getSimulationTime()
    activeSpell = {
        type         = 'haggle',
        handlerKey   = 'haggleLight',
        effectId     = resolveEffectId('haggleLight'),
        attacker     = player,
        containerObj = containerObj,
        lightObj     = lightObj,
        dir          = direction:normalize(),
        pos          = spawnPos,
        cellName     = player.cell.name,
        openedOnce   = false,
        expiresAt    = now + HAGGLE_TIMEOUT,
        startedAt    = now,
        magnitude    = magnitude,
        capacity     = rawCapacity,
    }
    installHaggleActivationHandler(containerObj)
    player:sendEvent('HaggleLight_Started', {})
    debugLog("Haggle-light active, expires in " .. tostring(HAGGLE_TIMEOUT) .. "s")
end

local function triggerLightWisp(player, spellDuration)
    debugLog("Triggering Light Wisp")
    removeActiveSpell("recast_or_replaced")
    if not ensureWispRecords() then
        debugLog("ERROR: could not create Light Wisp records")
        return
    end
    local spawnPos, direction = getSuspensionPos(player)
    local hDir = direction:normalize()
    local dur  = tonumber(spellDuration) or 0
    if dur <= 0 then dur = 300 end
    local orbObj = world.createObject(WISP_ORB_REC, 1)
    if not (orbObj and orbObj:isValid()) then
        debugLog("ERROR: could not create Light Wisp orb object")
        return
    end
    orbObj:teleport(player.cell.name, spawnPos)
    orbObj:setScale(getVfxScaleWispHaggle())
    installBlockPickupHandler(orbObj, "Light Wisp")
    local lightObj = world.createObject(WISP_LIGHT_REC, 1)
    if not (lightObj and lightObj:isValid()) then
        debugLog("ERROR: could not create Light Wisp light object")
        safeRemove(orbObj)
        return
    end
    lightObj:teleport(player.cell.name, spawnPos)
    pcall(function()
        orbObj:addScript('scripts/arcane_illumination/arcane_illumination_light_local.lua')
    end)
    orbObj:sendEvent('ArcaneLight_InitVfx', {
        model = 'meshes/e/magic_hit.NIF',
        vfxId = 'LightWisp_HangVfx',
    })
    local now = core.getSimulationTime()
    activeSpell = {
        type       = 'wisp',
        handlerKey = 'lightWisp',
        effectId   = resolveEffectId('lightWisp'),
        attacker   = player,
        lightObj   = lightObj,
        orbObj     = orbObj,
        dir        = hDir,
        pos        = spawnPos,
        cellName   = player.cell.name,
        expiresAt  = now + dur,
        startedAt  = now,
    }
    player:sendEvent('LightWisp_Started', {})
    debugLog("Light Wisp active, expires in " .. tostring(dur) .. "s")
end

local function triggerDetachLight(player)
    debugLog("Triggering Detach Light - removing all active light spells")
    removeAllArcaneEffects(player)
    removeActiveSpell("detached")
    --showMsg(player, "All conjured lights detached")
end

local SPELL_TRIGGERS = {
    attachLantern  = triggerAttachLantern,
    animateLantern = triggerAnimateLantern,
    lightWisp      = triggerLightWisp,
    haggleLight    = triggerHaggleLight,
    detachLight    = triggerDetachLight,
}

-- ============================================================
-- MAGNITUDE / DURATION EXTRACTION
-- ============================================================
local function extractMagnitudeFromActiveSpell(activeSpellData, effectId)
    if not (activeSpellData and effectId) then return 1 end
    local function fromEffectEntry(effect)
        if effect.magnitude                            then return effect.magnitude end
        if effect.magnitudeMin and effect.magnitudeMax then return math.random(effect.magnitudeMin, effect.magnitudeMax) end
        if effect.minMagnitude and effect.maxMagnitude then return math.random(effect.minMagnitude, effect.maxMagnitude) end
        if effect.baseMagnitude                        then return effect.baseMagnitude end
        if effect.currentMagnitude                     then return effect.currentMagnitude end
        for key, value in pairs(effect) do
            if type(value) == 'number'
            and (string.find(key:lower(), 'magnitude') or string.find(key:lower(), 'power')) then
                return value
            end
        end
        return nil
    end
    if activeSpellData.effects and type(activeSpellData.effects) == 'table' then
        for _, effect in ipairs(activeSpellData.effects) do
            if effect.id == effectId then
                local m = fromEffectEntry(effect)
                if m then return m end
            end
        end
    end
    local spellId = ''
    if activeSpellData.id then
        spellId = activeSpellData.id:lower()
    elseif activeSpellData.spell and activeSpellData.spell.id then
        spellId = activeSpellData.spell.id:lower()
    end
    local spellRecord = activeSpellData.spell
    if not spellRecord and spellId ~= '' then
        pcall(function() spellRecord = core.magic.spells.records[spellId] end)
    end
    if spellRecord and spellRecord.effects then
        for _, effect in ipairs(spellRecord.effects) do
            if effect.id == effectId then
                local m = fromEffectEntry(effect)
                if m then return m end
            end
        end
    end
    return 1
end

local function getDurationLeftForEffect(activeSpellData, effectId)
    if not (activeSpellData and effectId) then return nil end
    local effects = activeSpellData.effects
    if not (effects and type(effects) == 'table') then
        if activeSpellData.spell and type(activeSpellData.spell.effects) == 'table' then
            effects = activeSpellData.spell.effects
        end
    end
    if not (effects and type(effects) == 'table') then return nil end
    local best = nil
    for _, e in ipairs(effects) do
        if e and e.id == effectId and type(e.durationLeft) == 'number' then
            if (not best) or (e.durationLeft > best) then best = e.durationLeft end
        end
    end
    return best
end

-- ============================================================
-- CENTRAL CAST / RECAST HANDLER
-- ============================================================
local function castOrRecast(handlerKey, activeSpellData, instanceId)
    local player = world.players[1]
    if not (player and player:isValid()) then return end
    local effectId = resolveEffectId(handlerKey)
    if not effectId then return end
    local nowSim = core.getSimulationTime()
    removeAllArcaneEffects(player, handlerKey)
    local trigger = SPELL_TRIGGERS[handlerKey]
    if not trigger then return end
    local ok, err
    if handlerKey == 'detachLight' then
        ok, err = pcall(trigger, player)
        return  -- instant, no tracking
    elseif handlerKey == 'haggleLight' then
        local mag = extractMagnitudeFromActiveSpell(activeSpellData, effectId)
        ok, err = pcall(trigger, player, mag)
    elseif handlerKey == 'animateLantern' or handlerKey == 'lightWisp' then
        local durLeft = getDurationLeftForEffect(activeSpellData, effectId)
        local fallback = (handlerKey == 'animateLantern') and ANIMATE_LANTERN_LIFETIME or 300
        local dur = tonumber(durLeft) or fallback
        if dur <= 0 then dur = fallback end
        ok, err = pcall(trigger, player, dur)
    else
        ok, err = pcall(trigger, player)
    end
    if not ok then
        debugLog("ERROR triggering " .. tostring(handlerKey) .. ": " .. tostring(err))
        return
    end
    seenActiveSpellIds[instanceId]   = true
    seenSpellHandlerKey[instanceId]  = handlerKey
    seenSpellFirstSeenAt[instanceId] = nowSim
    local durLeft = getDurationLeftForEffect(activeSpellData, effectId)
    seenSpellEndAtSim[instanceId] = (type(durLeft) == 'number') and (nowSim + durLeft) or nowSim
    debugLog("castOrRecast complete for " .. handlerKey)
end

-- ============================================================
-- SAVE / LOAD
-- ============================================================
local function onSave()
    local savedActive = nil
    if activeSpell then
        savedActive = {
            type           = activeSpell.type,
            handlerKey     = activeSpell.handlerKey,
            effectId       = activeSpell.effectId,
            expiresAt      = activeSpell.expiresAt,
            startedAt      = activeSpell.startedAt,
            pos            = { x = activeSpell.pos.x, y = activeSpell.pos.y, z = activeSpell.pos.z },
            dir            = { x = activeSpell.dir.x, y = activeSpell.dir.y, z = activeSpell.dir.z },
            attacker       = activeSpell.attacker,
            magnitude      = activeSpell.magnitude,
            capacity       = activeSpell.capacity,
            openedOnce     = activeSpell.openedOnce,
            openedAt       = activeSpell.openedAt,
            autoSealAt     = activeSpell.autoSealAt,
            sourceRecordId = activeSpell.sourceRecordId,
            originalSourceRecordId = activeSpell.originalSourceRecordId,  -- NEW
            lanternRecId   = activeSpell.lanternRecId,
            cellName       = activeSpell.cellName,
            lightObjId     = activeSpell.lightObj     and activeSpell.lightObj.id,
            vfxAnchorId    = activeSpell.vfxAnchor    and activeSpell.vfxAnchor.id,
            containerObjId = activeSpell.containerObj  and activeSpell.containerObj.id,
            orbObjId       = activeSpell.orbObj        and activeSpell.orbObj.id,
        }
    end
    return {
        haggleLastUsedTime = haggleLastUsedTime,
        activeSpell        = savedActive,
        injected_npcs      = injected_npcs,
        settingsCache      = settingsCache,
    }
end

local function onLoad(data)
    if not data then return end
    haggleLastUsedTime = data.haggleLastUsedTime
    if data.injected_npcs  then injected_npcs  = data.injected_npcs  end
    if data.settingsCache  then settingsCache  = data.settingsCache  end

    HAGGLE_CONTAINER_RECS = {}
    HAGGLE_LIGHT_REC      = nil
    seenActiveSpellIds    = {}
    seenSpellHandlerKey   = {}
    seenSpellEndAtSim     = {}
    seenSpellFirstSeenAt  = {}

    if not data.activeSpell then return end
    local saved  = data.activeSpell
    local nowSim = core.getSimulationTime()
    if not (saved.expiresAt and saved.expiresAt > nowSim) then return end

    local player = saved.attacker
    if not (player and player:isValid()) then return end

    local spawnPos  = util.vector3(saved.pos.x, saved.pos.y, saved.pos.z)
    local hDir      = util.vector3(saved.dir.x, saved.dir.y, saved.dir.z)
    local remaining = math.max(1, saved.expiresAt - nowSim)

    debugLog("Restoring active spell: " .. tostring(saved.type) .. " with "
        .. string.format("%.1f", remaining) .. "s remaining")

    local function findObjectById(objId)
        if not objId then return nil end
        for _, cell in pairs(world.cells) do
            local ok, allObjects = pcall(function() return cell:getAll() end)
            if ok and allObjects then
                for _, cellObj in pairs(allObjects) do
                    if cellObj.id == objId and cellObj:isValid() then
                        debugLog("Found object " .. objId .. " in cell " .. tostring(cell.name))
                        return cellObj
                    end
                end
            end
        end
        return nil
    end

    if saved.type == 'animate' then
        local lightObj  = findObjectById(saved.lightObjId)
        local vfxAnchor = findObjectById(saved.vfxAnchorId)
        if lightObj and vfxAnchor then
            debugLog("Reusing existing Animate Lantern objects after load")
            installBlockPickupHandler(lightObj,  "Conjured Lantern")
            installBlockPickupHandler(vfxAnchor, "Conjured Lantern VFX")
            -- Re-apply scale in case it was lost on reload
            vfxAnchor:setScale(getVfxScaleConjure())
            vfxAnchor:sendEvent('ArcaneLight_InitVfx', {
                model = 'meshes/e/magic_hit.NIF',
                vfxId = 'AnimateLantern_HangVfx',
            })
            activeSpell = {
                type         = 'animate',
                handlerKey   = 'animateLantern',
                effectId     = resolveEffectId('animateLantern'),
                attacker     = player,
                lightObj     = lightObj,
                vfxAnchor    = vfxAnchor,
                dir          = hDir,
                pos          = spawnPos,
                expiresAt    = saved.expiresAt,
                startedAt    = nowSim,
                lanternRecId = saved.lanternRecId,
            }
        else
            debugLog("Existing objects not found, recreating Animate Lantern")
            triggerAnimateLantern(player, remaining)
        end

    elseif saved.type == 'attach' then
        local lightObj  = findObjectById(saved.lightObjId)
        -- vfxAnchorId may be absent in older saves — handle both cases
        local vfxAnchor = findObjectById(saved.vfxAnchorId)
        if lightObj then
            debugLog("Reusing existing Attach Light object after load")
            installAttachedLightPickupHandler(lightObj, saved.originalSourceRecordId or saved.sourceRecordId, saved.expiresAt)

            -- Restore or recreate the VFX anchor
            if vfxAnchor then
                debugLog("Reusing existing Attach VFX anchor after load")
                installBlockPickupHandler(vfxAnchor, "Attached Light VFX")
                vfxAnchor:setScale(getVfxScaleAttach())
                vfxAnchor:sendEvent('ArcaneLight_InitVfx', {
                    model = 'meshes/e/magic_hit.NIF',
                    vfxId = 'ArcaneLight_HangVfx',
                })
                else
                -- Old save or anchor was lost — create a fresh one with correct offset
                debugLog("No VFX anchor found for Attach Light, creating new one")
                if ensureAnimateVfxAnchorRecord() then
                    local computedOffset = getAttachVfxOffsetForLight(saved.originalSourceRecordId or saved.sourceRecordId)
                    local newAnchor = world.createObject(ANIMATE_VFX_ANCHOR_REC, 1)
                    if newAnchor and newAnchor:isValid() then
                        newAnchor:teleport(player.cell.name, spawnPos + util.vector3(0, 0, computedOffset))
                        newAnchor:setScale(getVfxScaleAttach())
                        pcall(function()
                            newAnchor:addScript('scripts/arcane_illumination/arcane_illumination_light_local.lua')
                        end)
                        installBlockPickupHandler(newAnchor, "Attached Light VFX")
                        newAnchor:sendEvent('ArcaneLight_InitVfx', {
                            model = 'meshes/e/magic_hit.NIF',
                            vfxId = 'ArcaneLight_HangVfx',
                        })
                        vfxAnchor = newAnchor
                    end
                end
            end

            lightValidityCheckTime = nowSim + ATTACH_STARTUP_GRACE
            activeSpell = {
                type                   = 'attach',
                handlerKey             = 'attachLantern',
                effectId               = resolveEffectId('attachLantern'),
                attacker               = player,
                lightObj               = lightObj,
                vfxAnchor              = vfxAnchor,
                attachVfxOffset        = vfxAnchor and getAttachVfxOffsetForLight(saved.originalSourceRecordId or saved.sourceRecordId) or nil,  -- ← recompute on load
                dir                    = hDir,
                pos                    = spawnPos,
                expiresAt              = saved.expiresAt,
                startedAt              = nowSim,
                sourceRecordId         = saved.sourceRecordId,
                originalSourceRecordId = saved.originalSourceRecordId,
                startupGraceUntil      = nowSim + ATTACH_STARTUP_GRACE,
            }
        else
            debugLog("Existing light object not found, cannot restore Attach Light")
        end

    elseif saved.type == 'wisp' then
        local lightObj = findObjectById(saved.lightObjId)
        local orbObj   = findObjectById(saved.orbObjId)
        if lightObj and orbObj then
            debugLog("Reusing existing Light Wisp objects after load")
            installBlockPickupHandler(orbObj, "Light Wisp")
            -- Re-apply scale in case it was lost on reload
            orbObj:setScale(getVfxScaleWispHaggle())
            orbObj:sendEvent('ArcaneLight_InitVfx', {
                model = 'meshes/e/magic_hit.NIF',
                vfxId = 'LightWisp_HangVfx',
            })
            activeSpell = {
                type       = 'wisp',
                handlerKey = 'lightWisp',
                effectId   = resolveEffectId('lightWisp'),
                attacker   = player,
                lightObj   = lightObj,
                orbObj     = orbObj,
                dir        = hDir,
                pos        = spawnPos,
                expiresAt  = saved.expiresAt,
                startedAt  = nowSim,
            }
        else
            debugLog("Existing objects not found, recreating Light Wisp")
            triggerLightWisp(player, remaining)
        end

    elseif saved.type == 'haggle' then
        local containerObj = findObjectById(saved.containerObjId)
        local lightObj     = findObjectById(saved.lightObjId)
        if containerObj and lightObj then
            debugLog("Reusing existing Haggle-light objects after load")
            installHaggleActivationHandler(containerObj)
            -- Re-apply scale and VFX in case they were lost on reload
            containerObj:setScale(HAGGLE_ORB_SCALE)
            pcall(function()
                containerObj:addScript('scripts/arcane_illumination/arcane_illumination_light_local.lua')
            end)
            containerObj:sendEvent('ArcaneLight_InitVfx', {
                model = 'meshes/e/magic_hit.NIF',
                vfxId = 'HaggleLight_HangVfx',
            })
            activeSpell = {
                type         = 'haggle',
                handlerKey   = 'haggleLight',
                effectId     = resolveEffectId('haggleLight'),
                attacker     = player,
                containerObj = containerObj,
                lightObj     = lightObj,
                dir          = hDir,
                pos          = spawnPos,
                openedOnce   = saved.openedOnce,
                openedAt     = saved.openedAt,
                autoSealAt   = saved.autoSealAt,
                expiresAt    = saved.expiresAt,
                startedAt    = nowSim,
                magnitude    = saved.magnitude,
                capacity     = saved.capacity,
            }
        else
            debugLog("Existing objects not found, recreating Haggle-light")
            triggerHaggleLight(player, saved.magnitude)
            if activeSpell then
                activeSpell.expiresAt  = saved.expiresAt
                activeSpell.startedAt  = nowSim
                activeSpell.openedOnce = saved.openedOnce
                activeSpell.openedAt   = saved.openedAt
                activeSpell.autoSealAt = saved.autoSealAt
            end
        end
    end

    if activeSpell then
        local startEvent = nil
        if     saved.type == 'animate' then startEvent = 'AnimateLantern_Started'
        elseif saved.type == 'attach'  then startEvent = 'AttachLantern_Started'
        elseif saved.type == 'wisp'    then startEvent = 'LightWisp_Started'
        elseif saved.type == 'haggle'  then startEvent = 'HaggleLight_Started'
        end
        if startEvent then player:sendEvent(startEvent, {}) end
    end
end

-- ============================================================
-- UPDATE LOOP
-- ============================================================
local function onUpdateGlobal(dt)
    if not activeSpell then return end
    local player = activeSpell.attacker
    if not (player and player:isValid()) then return end
    local nowSim = core.getSimulationTime()

        -- Validity + inventory checks — ATTACH ONLY, and only after grace + not in UI + cooldown expired
    if activeSpell.type == 'attach' then
        local inGrace = activeSpell.startupGraceUntil and (nowSim < activeSpell.startupGraceUntil)
        
        -- Also gate on cooldown — skip the check for 1 frame after UI closes
        local inCooldown = (nowSim < attachInventoryCheckCooldown)
        
        if not inGrace and not uiOpen and not inCooldown and nowSim >= lightValidityCheckTime then
            lightValidityCheckTime = nowSim + 0.1

            if activeSpell.lightObj and not activeSpell.lightObj:isValid() then
                debugLog("Light object invalid - ending spell")
                removeAllArcaneEffects(player)
                removeActiveSpell("object_invalid")
                return
            end

            if activeSpell.sourceRecordId then
                local inv = types.Actor.inventory(player)
                if inv:find(activeSpell.sourceRecordId) then
                    -- MUTUAL GUARD: if pickup was already processed (by UI drag or activation),
                    -- the spell should already be gone — but if it isn't, clean up now.
                    if activeSpell.pickupProcessed then
                        debugLog("Light in inventory but pickupProcessed=true — spell likely already cleaned up")
                        return
                    end
                    debugLog("Light returned to inventory - ending spell")
                    removeAllArcaneEffects(player)
                    removeActiveSpell("picked_up")
                    return
                end
            end
        end
    end

    -- Expiry
    if nowSim >= (activeSpell.expiresAt or 0) then
        debugLog("Spell expired: " .. tostring(activeSpell.type))
        removeAllArcaneEffects(player)
        removeActiveSpell("expired")
        return
    end

    -- Validity + inventory checks — ATTACH ONLY, and only after grace + not in UI + cooldown expired
    if activeSpell.type == 'attach' then
        local inGrace = activeSpell.startupGraceUntil and (nowSim < activeSpell.startupGraceUntil)
        
        -- NEW: Also gate on cooldown — skip the check for 1 frame after UI closes
        -- to let the deferred UI-closed event process first.
        local inCooldown = (nowSim < attachInventoryCheckCooldown)
        
        if not inGrace and not uiOpen and not inCooldown and nowSim >= lightValidityCheckTime then
            lightValidityCheckTime = nowSim + 0.1

            if activeSpell.lightObj and not activeSpell.lightObj:isValid() then
                debugLog("Light object invalid - ending spell")
                removeAllArcaneEffects(player)
                removeActiveSpell("object_invalid")
                return
            end

            if activeSpell.sourceRecordId then
                local inv = types.Actor.inventory(player)
                if inv:find(activeSpell.sourceRecordId) then
                    debugLog("Light returned to inventory - ending spell")
                    removeAllArcaneEffects(player)
                    removeActiveSpell("picked_up")
                    return
                end
            end
        end
    end

    -- Haggle auto-seal
    if activeSpell.type == 'haggle'
    and activeSpell.openedOnce and activeSpell.autoSealAt
    and nowSim >= activeSpell.autoSealAt then
        debugLog("Haggle-light safety timeout — auto-sealing")
        sealHaggleLight(activeSpell.attacker, activeSpell.containerObj)
        return
    end

    -- Duration tooltip update (attach only) — NEW: gate on not uiOpen
    -- Once the light is in inventory, stop decrementing its duration.
    if not uiOpen then
        durationUpdateTimer = durationUpdateTimer + dt
        if durationUpdateTimer >= DURATION_UPDATE_INTERVAL then
            durationUpdateTimer = 0
            updateLightDuration()
        end
    end
end

-- ============================================================
-- MAIN UPDATE — spell detection & recast detection
-- ============================================================
local function onUpdateInternal(dt)
    onUpdateGlobal(dt)
    local player = world.players[1]
    if not (player and player:isValid()) then return end
    local nowSim     = core.getSimulationTime()
    local currentIds = {}

    for instanceId, active in pairs(types.Actor.activeSpells(player)) do
        currentIds[instanceId] = true
        local handlerKey = detectArcaneSpellByEffects(active, instanceId)
        if handlerKey then
            local isNew     = not seenActiveSpellIds[instanceId]
            local prevEndAt = seenSpellEndAtSim[instanceId]
            local effectId  = resolveEffectId(handlerKey)
            local durLeft   = getDurationLeftForEffect(active, effectId)
            local expectedEnd = (type(durLeft) == 'number') and (nowSim + durLeft) or nil

            local isRecast = false
            if (not isNew) and prevEndAt and expectedEnd
            and (handlerKey == 'animateLantern' or handlerKey == 'lightWisp') then
                if expectedEnd > prevEndAt + 0.25 then
                    isRecast = true
                    debugLog("Recast detected for " .. handlerKey)
                end
            end

            if isNew or isRecast then
                castOrRecast(handlerKey, active, instanceId)
            else
                if expectedEnd then seenSpellEndAtSim[instanceId] = expectedEnd end
            end

            if not seenSpellHandlerKey[instanceId] then
                seenSpellHandlerKey[instanceId] = handlerKey
            end
        end
    end

    -- Dispel detection
    for instanceId in pairs(seenActiveSpellIds) do
        if not currentIds[instanceId] then
            local firstSeen = seenSpellFirstSeenAt[instanceId] or 0
            if (nowSim - firstSeen) < DISPEL_GRACE_PERIOD then
                --debugLog("Ignoring early effect removal for instance " .. instanceId
                  --  .. " (grace period, age=" .. string.format("%.2f", nowSim - firstSeen) .. "s)")
            else
                local handlerKey = seenSpellHandlerKey[instanceId]
                debugLog("Effect removed for instance " .. instanceId
                    .. " (handler: " .. tostring(handlerKey) .. ")")
                if activeSpell and activeSpell.handlerKey == handlerKey then
                    debugLog("Removing world objects because effect was dispelled/removed")
                    removeActiveSpell("dispelled")
                end
                seenActiveSpellIds[instanceId]   = nil
                seenSpellHandlerKey[instanceId]  = nil
                seenSpellEndAtSim[instanceId]    = nil
                seenSpellFirstSeenAt[instanceId] = nil
            end
        end
    end
end

-- ============================================================
-- POSITION UPDATES FROM PLAYER SCRIPT
-- ============================================================
local function safeTeleport(obj, pos, player)
    if not (obj and obj:isValid()) then return end
    if not (player and player:isValid()) then return end
    if not player.cell then return end
    if not obj.cell then return end
    pcall(function() obj:teleport(player.cell.name, pos) end)
end

local function onPositionUpdate(data, stateType)
    if uiOpen then return end
    if not activeSpell or activeSpell.type ~= stateType then return end
    local lightObj = activeSpell.lightObj
    if not (lightObj and lightObj:isValid()) then
        debugLog("Position update skipped - light object no longer valid")
        return
    end
    local player = activeSpell.attacker
    if not (player and player:isValid()) then return end
    activeSpell.pos = data.position
    activeSpell.dir = data.direction
    safeTeleport(activeSpell.lightObj,     data.position, player)
safeTeleport(activeSpell.vfxAnchor, data.position + util.vector3(0, 0, getVfxOffsetForActiveSpell()), player)
    safeTeleport(activeSpell.orbObj,       data.position, player)
    safeTeleport(activeSpell.containerObj, data.position, player)
end

local function onAnimateUpdate(data) onPositionUpdate(data, 'animate') end
local function onAttachUpdate(data)  onPositionUpdate(data, 'attach')  end
local function onWispUpdate(data)    onPositionUpdate(data, 'wisp')    end
local function onHaggleUpdate(data)  onPositionUpdate(data, 'haggle')  end

local function onPlayerTeleported()
    if not activeSpell then return end
    local player = activeSpell.attacker
    if not (player and player:isValid()) then return end
    local cellName = player.cell.name
    local pos      = activeSpell.pos
    if activeSpell.lightObj     and activeSpell.lightObj:isValid()     and activeSpell.lightObj.cell     then pcall(function() activeSpell.lightObj:teleport(cellName, pos) end) end
    if activeSpell.orbObj       and activeSpell.orbObj:isValid()       and activeSpell.orbObj.cell       then pcall(function() activeSpell.orbObj:teleport(cellName, pos) end) end
if activeSpell.vfxAnchor and activeSpell.vfxAnchor:isValid() and activeSpell.vfxAnchor.cell then
    pcall(function()
        activeSpell.vfxAnchor:teleport(cellName, pos + util.vector3(0, 0, getVfxOffsetForActiveSpell()))
    end)
end    if activeSpell.containerObj and activeSpell.containerObj:isValid() and activeSpell.containerObj.cell then pcall(function() activeSpell.containerObj:teleport(cellName, pos) end) end
end

local function onLightPositionChanged()
    debugLog("Light position setting changed, updating slot positions...")
    local player = world.players[1]
    if not (player and player:isValid()) then return end
    player:sendEvent('ArcaneIllumination_RefreshSlots', {})
end

-- ============================================================
-- RETURN
-- ============================================================
return {
    engineHandlers = {
        onUpdate = onUpdateInternal,
        onSave   = onSave,
        onLoad   = onLoad,
        onActorActive = function(actor)
            if actor == world.players[1] then onPlayerTeleported() end
            if not types.NPC.objectIsInstance(actor) then return end
            if not actor.id or injected_npcs[actor.id] then return end
            local alteration  = types.NPC.stats.skills.alteration(actor).base
            local conjuration = types.NPC.stats.skills.conjuration(actor).base
            local illusion    = types.NPC.stats.skills.illusion(actor).base
            local changed     = false
            if conjuration >= 48 and not hasSpell(actor, "animate_lantern_spell") then
                types.Actor.spells(actor):add("animate_lantern_spell"); changed = true
            end
            if alteration >= 49 and not hasSpell(actor, "attach_lantern_spell") then
                types.Actor.spells(actor):add("attach_lantern_spell"); changed = true
            end
            if illusion >= 52 and not hasSpell(actor, "light_wisp_spell") then
                types.Actor.spells(actor):add("light_wisp_spell"); changed = true
            end
            if illusion >= 52 and not hasSpell(actor, "haggle_light_spell") then
                types.Actor.spells(actor):add("haggle_light_spell"); changed = true
            end
            if conjuration >= 48 and not hasSpell(actor, "detach_light_spell") then
                types.Actor.spells(actor):add("detach_light_spell"); changed = true
            end
            if changed then injected_npcs[actor.id] = true end
        end,
    },
    eventHandlers = {
                -- Fired by player script when any UI closes while attach spell was active.
        -- Checks whether the player dragged the light to inventory via UI, and if
        -- so performs a clean removal of the world object + ends the spell properly.
        -- Fired by player script when any UI closes while attach spell was active.
        -- Checks whether the player dragged the light to inventory via UI, and if
        -- so performs a clean removal of the world object + ends the spell properly.
    ArcaneIllumination_AttachUIClosed = function()
    local player = world.players[1]
    if not (player and player:isValid()) then return end

    if not activeSpell or activeSpell.type ~= 'attach' then
        debugLog("AttachUIClosed: no active attach spell, ignoring")
        return
    end

    -- Always reset pickupProcessed when UI closes without the light being in inventory.
    -- This prevents the flag from being permanently poisoned by routine inventory opens.
    local generatedRecId = activeSpell.sourceRecordId
    if not generatedRecId then return end

    local inv = types.Actor.inventory(player)
    local generatedItem = inv:find(generatedRecId)

    if not generatedItem then
        -- Light is still in the world — NOT picked up via UI drag.
        -- Clear the flag so future recast/detach/expiry CAN create the return item.
        debugLog("AttachUIClosed: light not in inventory — resetting pickupProcessed flag")
        activeSpell.pickupProcessed = false
        return
    end

    -- Light WAS dragged into inventory via UI — now process it properly.
    debugLog("AttachUIClosed: Generated light found in inventory — replacing with original record")

    -- Only mark as processed NOW that we know the item is actually there.
    activeSpell.pickupProcessed = true

    -- Get remaining duration
    local remainingDuration = 1
    local itemData = types.Item.itemData(generatedItem)
    if itemData and itemData.condition and itemData.condition > 0 then
        remainingDuration = itemData.condition
    elseif activeSpell.expiresAt then
        local nowSim = core.getSimulationTime()
        remainingDuration = math.max(1, activeSpell.expiresAt - nowSim)
    end

    local originalRecId = activeSpell.originalSourceRecordId
    if not originalRecId then
        debugLog("AttachUIClosed: original record ID not found, cannot replace")
        activeSpell.lightObj = nil
        removeAllArcaneEffects(player)
        removeActiveSpell("picked_up")
        return
    end

    -- Remove the Generated item
    pcall(function() generatedItem:remove() end)

    -- Create new item with original record + stamped duration
    local newItem = world.createObject(originalRecId, 1)
    if newItem and newItem:isValid() then
        pcall(function()
            local newData = types.Item.itemData(newItem)
            if newData then newData.condition = remainingDuration end
        end)

        local ok, err = pcall(function()
            newItem:moveInto(types.Actor.inventory(player))
        end)

        if not ok then
            debugLog("AttachUIClosed: moveInto failed: " .. tostring(err))
            newItem:teleport(player.cell.name, player.position)
        else
            debugLog("AttachUIClosed: returned original record to inventory with "
                .. string.format("%.1f", remainingDuration) .. "s remaining")
        end
    end

    -- Clean up world object
    if activeSpell.lightObj then
        pickedUpLights[activeSpell.lightObj.id] = true
        activeSpell.lightObj = nil
    end

    removeAllArcaneEffects(player)
    removeActiveSpell("picked_up")
end,
        ArcaneIllumination_UpdateSettings = function(data)
            if data.debugMode ~= nil then settingsCache.debugMode = data.debugMode end
            if data.haggleCooldownHours ~= nil then
                settingsCache.haggleCooldownHours = data.haggleCooldownHours
            end
            if data.haggleMercantileRatio ~= nil then
                local r = tonumber(data.haggleMercantileRatio)
                if r then settingsCache.haggleMercantileRatio = r end
            end
            if data.haggleMagnitudeMultiplier ~= nil then
                local m = tonumber(data.haggleMagnitudeMultiplier)
                if m then
                    settingsCache.haggleMagnitudeMultiplier = m
                    HAGGLE_CONTAINER_RECS = {}
                end
            end
            if data.lightPosition ~= nil then
                local oldPos = settingsCache.lightPosition
                settingsCache.lightPosition = data.lightPosition
                if oldPos ~= data.lightPosition then onLightPositionChanged() end
            end
            if data.vfxEnabled ~= nil then
                settingsCache.vfxEnabled = (data.vfxEnabled == true)
            end

            -- Update per-spell VFX scales in cache
            if data.vfxScaleConjure ~= nil then
                local s = tonumber(data.vfxScaleConjure)
                if s then settingsCache.vfxScaleConjure = s end
            end
            if data.vfxScaleAttach ~= nil then
                local s = tonumber(data.vfxScaleAttach)
                if s then settingsCache.vfxScaleAttach = s end
            end
            if data.vfxScaleWispHaggle ~= nil then
                local s = tonumber(data.vfxScaleWispHaggle)
                if s then settingsCache.vfxScaleWispHaggle = s end
            end

            -- Helper: toggle VFX on a specific object
            local function applyVfxToObj(obj, vfxId)
                if not (obj and obj:isValid()) then return end
                if settingsCache.vfxEnabled then
                    obj:sendEvent('ArcaneLight_InitVfx', {
                        model = 'meshes/e/magic_hit.nif',
                        vfxId = vfxId,
                    })
                else
                    obj:sendEvent('ArcaneLight_StopVfx', { vfxId = vfxId })
                end
            end

            -- Live-apply scale + VFX toggle to the currently active spell
            if activeSpell then
                if activeSpell.type == 'animate' and activeSpell.vfxAnchor and activeSpell.vfxAnchor:isValid() then
                    activeSpell.vfxAnchor:setScale(getVfxScaleConjure())
                    applyVfxToObj(activeSpell.vfxAnchor, 'AnimateLantern_HangVfx')

                elseif activeSpell.type == 'attach' and activeSpell.vfxAnchor and activeSpell.vfxAnchor:isValid() then
                    activeSpell.vfxAnchor:setScale(getVfxScaleAttach())
                    applyVfxToObj(activeSpell.vfxAnchor, 'ArcaneLight_HangVfx')

                elseif activeSpell.type == 'wisp' and activeSpell.orbObj and activeSpell.orbObj:isValid() then
                    activeSpell.orbObj:setScale(getVfxScaleWispHaggle())
                    applyVfxToObj(activeSpell.orbObj, 'LightWisp_HangVfx')

                elseif activeSpell.type == 'haggle' and activeSpell.containerObj and activeSpell.containerObj:isValid() then
                    activeSpell.containerObj:setScale(getVfxScaleWispHaggle())
                    applyVfxToObj(activeSpell.containerObj, 'HaggleLight_HangVfx')
                end
            end

                       -- Update per-spell VFX offsets in cache
            if data.vfxOffsetConjure ~= nil then
                local o = tonumber(data.vfxOffsetConjure)
                if o then
                    settingsCache.vfxOffsetConjure = o
                    -- Live-reposition if animate anchor is active
                    if activeSpell and activeSpell.type == 'animate'
                    and activeSpell.vfxAnchor and activeSpell.vfxAnchor:isValid()
                    and activeSpell.vfxAnchor.cell then
                        local pos = activeSpell.pos + util.vector3(0, 0, getVfxOffsetConjure())
                        pcall(function()
                            activeSpell.vfxAnchor:teleport(activeSpell.vfxAnchor.cell.name, pos)
                        end)
                        debugLog("Repositioned Conjure Lantern VFX anchor, offset=" .. tostring(o))
                    end
                end
            end

            if data.vfxOffsetAttach ~= nil then
                local o = tonumber(data.vfxOffsetAttach)
                if o then
                    settingsCache.vfxOffsetAttach = o
                    -- Live-reposition if attach anchor is active
                    if activeSpell and activeSpell.type == 'attach'
                    and activeSpell.vfxAnchor and activeSpell.vfxAnchor:isValid()
                    and activeSpell.vfxAnchor.cell then
                        local pos = activeSpell.pos + util.vector3(0, 0, getVfxOffsetAttach())
                        pcall(function()
                            activeSpell.vfxAnchor:teleport(activeSpell.vfxAnchor.cell.name, pos)
                        end)
                        debugLog("Repositioned Attach Lantern VFX anchor, offset=" .. tostring(o))
                    end
                end
            end

            -- REMOVE the old vfxOffset block entirely — it is replaced by the two above
        end,

        ArcaneIllumination_UiStateChanged = function(data)
            if data and type(data.uiOpen) == 'boolean' then
                uiOpen = data.uiOpen
                debugLog("UI state updated from player: uiOpen=" .. tostring(uiOpen))
                
                -- NEW: When UI closes, set a 1-frame cooldown before periodic inventory
                -- checks resume. This gives the deferred AttachUIClosed event time to
                -- process first, preventing a race where the periodic check removes the
                -- spell before the proper cleanup can preserve the item.
                if not uiOpen then
                    local nowSim = core.getSimulationTime()
                    attachInventoryCheckCooldown = nowSim + 0.05   -- 1 frame @ 20 FPS
                    debugLog("UI closed — inventory check cooldown set")
                end
            end
        end,

        AnimateLantern_Cancel = function()
            local player = world.players[1]
            if player and player:isValid() then removeAllArcaneEffects(player) end
            removeActiveSpell("canceled")
        end,
        AnimateLantern_Update = onAnimateUpdate,

        AttachLantern_Cancel = function()
            local player = world.players[1]
            if player and player:isValid() then removeAllArcaneEffects(player) end
            removeActiveSpell("canceled")
        end,
        AttachLantern_Update = onAttachUpdate,

        LightWisp_Cancel = function()
            local player = world.players[1]
            if player and player:isValid() then removeAllArcaneEffects(player) end
            removeActiveSpell("canceled")
        end,
        LightWisp_Update = onWispUpdate,

        HaggleLight_Cancel = function()
            local player = world.players[1]
            if player and player:isValid() then removeAllArcaneEffects(player) end
            removeActiveSpell("canceled")
        end,
        HaggleLight_Update = onHaggleUpdate,
        HaggleLight_Seal   = function(data)
            sealHaggleLight(data and data.player, data and data.container)
        end,

        ArcaneIllumination_FailureEffects = function(data)
            if not data.pos then return end
            local dummy = world.createObject(LIGHT_CARRIER_REC, 1)
            if dummy and dummy:isValid() then
                dummy:teleport(world.players[1].cell.name, data.pos)
            end
            pcall(function()
                core.sound.playSoundFile3d("sound/fx/magic/altrfail.wav", dummy)
            end)
            world.vfx.spawn('meshes\\e\\magic_hit.nif',
                data.pos + util.vector3(0, 0, -30), { scale = 0.8 })
            async:newUnsavableSimulationTimer(1.0, function() safeRemove(dummy) end)
        end,
    },
}