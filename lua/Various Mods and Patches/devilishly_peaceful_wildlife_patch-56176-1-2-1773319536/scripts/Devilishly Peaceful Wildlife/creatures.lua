
local self   = require("openmw.self")
local core   = require("openmw.core")
local types  = require("openmw.types")
local nearby = require("openmw.nearby")
local time   = require("openmw_aux.time")
local AI     = require("openmw.interfaces").AI
local anim   = require("openmw.animation")

------------------------------------------------------------
-- AI FIGHT VALUES
------------------------------------------------------------

local fight = {
    ["alit"] = 10, ["alit_diseased"] = 10,
    ["guar"] = 10, ["guar_feral"] = 10,
    ["kagouti"] = 10, ["kagouti_diseased"] = 10, ["t_mw_fau_armunkag_01"] = 10, ["t_mw_fau_armunkagmat_01"] = 10,
    ["kwama forager"] = 10, ["kwama warrior"] = 10,
    ["mudcrab"] = 10,
    ["nix-hound"] = 10, ["t_mw_fau_nixhds_01"] = 10,
    ["rat"] = 10, ["rat_diseased"] = 10,
    ["rat_cave_fgrh"] = 10, ["rat_cave_fgt"] = 10,
    ["shalk"] = 10, ["shalk_diseased"] = 10,
    ["slaughterfish_small"] = 10,
    ["t_mw_fau_ceph_01"] = 10, ["t_mw_fau_cephbg_01"] = 10,
    ["t_glb_fau_seacr_01"] = 10, ["t_glb_fau_seacrds_01"] = 10,
    ["t_mw_fau_molec_01"] = 10, ["t_mw_fau_molecds_01"] = 10,
    ["pc_m1_anv_crabbuck_crab"] = 10,
    ["bm_bear_black"] = 10,
    ["bm_bear_brown"] = 10,
    ["bm_bear_snow_unique"] = 10,
    ["bm_frost_boar"] = 10,
    ["t_cyr_fau_bearcol_01"] = 10, ["t_cyr_fau_bearcolids_01"] = 10,
    ["bm_spriggan"] = 10, ["t_sky_cre_spriggan_01"] = 10, ["t_sky_cre_sprigganel_01"] = 10, ["t_sky_cre_sprigganny_01"] = 10,
    ["t_glb_fau_ratbk_01"] = 10,

    ["bm_wolf_grey"] = 10,
    ["bm_wolf_grey_lvl_1"] = 10,
    ["bm_wolf_red"] = 10,
    ["t_cyr_fau_wolfcol_01"] = 10,  ["t_cyr_fau_wolfcolds_01"] = 10,
    ["t_cyr_fau_wolfcol_02"] = 10,  ["t_cyr_fau_wolfcolds_02"] = 10,
    ["t_cyr_fau_muskrat_01"] = 10,   ["t_cyr_fau_muskratds_01"] = 10,

    ["t_cyr_fau_moonc_01"] = 10, ["t_cyr_fau_mooncDis_01"] = 10,
    ["t_sky_fau_bearbk_01"] = 10,
    ["t_sky_fau_bearbr_01"] = 10,
    ["t_sky_fau_bearsn_01"] = 10,
    ["pc_m1_arc_snakebit_snke"] = 10,
    ["t_cyr_fau_birdstrid_01"] = 10, ["t_cyr_fau_birdstridn_01"] = 10,
    ["t_cyr_fau_alphyn_01"] = 10,
    ["t_mw_fau_muskf_01"] = 10,  ["t_mw_fau_muskfds_01"] = 10,
    ["t_mw_fau_beetlehr_01"] = 10,  ["t_mw_fau_beetlehr_01ds"] = 10,
    ["t_mw_fau_beetlegr_01"] = 10,  ["t_mw_fau_beetlegrds_01"] = 10,
    ["t_mw_fau_beetlebr_01"] = 10,  ["t_mw_fau_beetlebrds_01"] = 10,
    ["t_mw_fau_beetlebl_01"] = 10,  ["t_mw_fau_beetleblds_01"] = 10,
    ["sky_qre_kg1_spikeworm"] = 10,   ["t_ham_fau_spkworm_01"] = 10,

    ["t_sky_fau_wolfbla_01"] = 10,
    ["t_sky_fau_wolfblasml_01"] = 10,
    ["t_sky_fau_wolfblads_01"] = 10,
    ["t_sky_fau_wolfgr_01"] = 10,
    ["t_sky_fau_wolfgr_dis_01"] = 10,
    ["t_sky_fau_wolfred_01"] = 10,
    ["t_sky_fau_wolfredds_01"] = 10,
    ["t_ham_fau_wormmth_01"] = 10, ["sky_qre_dse4_wormmouth"] = 10,
    ["t_glb_cre_trollcave_01"] = 10, ["t_glb_cre_trollcave_02"] = 10, ["t_glb_cre_trollcave_03"] = 10, ["t_glb_cre_trollcave_04"] = 10, ["t_glb_cre_trollcaved_03"] = 10,
    ["t_glb_cre_kobold_01"] = 10,

    ["bm_riekling"] = 10,
    ["bm_riekling_mounted"] = 10,

    ["goblin_bruiser"] = 10, ["goblin_footsoldier"] = 10,
    ["goblin_grunt"] = 10, ["goblin_handler"] = 10,
    ["goblin_officer"] = 10, ["t_cyr_cre_gob_01"] = 10,
    ["t_cyr_cre_gobbrs_01"] = 10, ["t_cyr_cre_gobchf_01"] = 10,
    ["t_cyr_cre_gobskm_01"] = 10, ["t_sky_cre_gobskr_01"] = 10,
    ["t_sky_cre_gobshm_01"] = 10,
    ["t_sky_cre_gobthr_01"] = 10, ["tr_m7_ns_arena_gobreg"] = 10,
    ["t_sky_fau_boar_01"] = 10,
    ["ab_fau_bat"] = 10, [" t_glb_fau_bat_01"] = 10,

    ["cliff racer"] = 10,
    ["cliff racer_diseased"] = 10,

    -- instant-aggro set handled below
    ["slaughterfish"] = 10,
    ["dreugh"] = 10,

    -- Repopulated Creatures
    ["t_mw_fau_mucklch_01"] = 10,
    ["t_mw_fau_mucklchds_01"] = 10,

    -- Ttooth Ecology
    ["ttooth_guar"] = 10,
    ["ttooth_rat"] = 10,
    ["ttooth_shalk"] = 10,
    ["ttooth_kwama forager"] = 10,

    -- Synthesis Series - Creatures and Diseases
    ["h11_dreugh_dis"] = 10,
    ["h11_kwama_forager_dis"] = 10,
    ["h11_kwama_warrior_dis"] = 10,
    ["h11_nix-hound_dis"] = 10,
    ["h11_nix-hound_rogue"] = 10,
    ["h11_rat_rust"] = 10,
    ["h11_slaughterfish_dis"] = 10,

    -- Mushroom Crabs
    ["nm_mushcrab"] = 10,

    -- Creatures Restored
    ["bm_riekling_2"] = 10,
    ["bm_riekling_mounted_2"] = 10,
}

------------------------------------------------------------
-- CREATURE GROUPS (for sounds/anims only)
------------------------------------------------------------

local wolves = {
    ["bm_wolf_grey"] = true,
    ["bm_wolf_grey_lvl_1"] = true,
    ["bm_wolf_red"] = true,
    ["bm_wolf_snow_unique"] = true,
    ["t_sky_fau_wolfbla_01"] = true,
    ["t_sky_fau_wolfblasml_01"] = true,
    ["t_sky_fau_wolfblads_01"] = true,
    ["t_sky_fau_wolfgr_01"] = true,
    ["t_sky_fau_wolfgr_dis_01"] = true,
    ["t_sky_fau_wolfred_01"] = true,
    ["t_sky_fau_wolfredds_01"] = true,
    ["t_cyr_fau_wolfcol_01"] = true,
    ["t_cyr_fau_wolfcolds_01"] = true,
}

local bears = {
    ["bm_bear_black"] = true,
    ["bm_bear_brown"] = true,
    ["bm_bear_snow_unique"] = true,
    ["t_sky_fau_bearbk_01"] = true,
    ["t_sky_fau_bearbr_01"] = true,
    ["t_sky_fau_bearsn_01"] = true,
    ["t_cyr_fau_bearcol_01"] = true,
    ["t_cyr_fau_bearcolids_01"] = true,
}

local rieklings = {
    ["bm_riekling"] = true,
    ["bm_riekling_mounted"] = true,
    --
    ["bm_riekling_2"] = true,
    ["bm_riekling_mounted_2"] = true,
}

local nixhounds = {
    ["nix-hound"] = true,
    ["t_mw_fau_nixhds_01"] = true,
    --
    ["h11_nix-hound_dis"] = true,
    ["h11_nix-hound_rogue"] = true,
}

local kagouti = {
    ["kagouti"] = true,
    ["kagouti_diseased"] = true,
    ["t_mw_fau_armunkag_01"] = true,
    ["t_mw_fau_armunkagmat_01"] = true,
}

local alit = {
    ["alit"] = true,
    ["alit_diseased"] = true,
    ["tr_m4_q_alit_troupe"] = true,
}

local aphyn = {
    ["t_cyr_fau_alphyn_01"] = true,
}

local wormmouth = {
    ["t_ham_fau_wormmth_01"] = true, ["sky_qre_dse4_wormmouth"] = true,
}

local trolls = {
    ["t_glb_cre_trollcave_01"] = true,
    ["t_glb_cre_trollcave_02"] = true,
    ["t_glb_cre_trollcave_03"] = true,
    ["t_glb_cre_trollcave_04"] = true,
    ["t_glb_cre_trollcaved_03"] = true,
}

local kobold = {
    ["t_glb_cre_kobold_01"] = true,
}

local boars = {
    ["bm_frost_boar"] = true,
    ["t_sky_fau_boar_01"] = true,
}

local goblins = {
    ["goblin_bruiser"] = true, ["goblin_footsoldier"] = true,
    ["goblin_grunt"] = true,  ["goblin_handler"] = true,
    ["goblin_officer"] = true,  ["t_cyr_cre_gob_01"] = true,
    ["t_cyr_cre_gobbrs_01"] = true,  ["t_cyr_cre_gobchf_01"] = true,
    ["t_cyr_cre_gobskm_01"] = true,  ["t_sky_cre_gobskr_01"] = true,
    ["t_sky_cre_gobshm_01"] = true,
    ["t_sky_cre_gobthr_01"] = true,  ["tr_m7_ns_arena_gobreg"] = true,
}

local cliffracers = {
     ["cliff racer"] = true, ["cliff racer_diseased"] = true,
}

local kwama = {
    ["kwama forager"] = true,
    --
    ["ttooth_kwama forager"] = true,
    ["h11_kwama_forager_dis"] = true,
}

------------------------------------------------------------
-- GROUP-AGGRO WHITELIST
------------------------------------------------------------

local groupAggroEnabled = {}

local function enableGroupAggroFor(tbl)
    for id in pairs(tbl) do groupAggroEnabled[id] = true end
end

enableGroupAggroFor(wolves)
enableGroupAggroFor(cliffracers)
enableGroupAggroFor(rieklings)
enableGroupAggroFor(goblins)
enableGroupAggroFor(boars)
enableGroupAggroFor(trolls)
enableGroupAggroFor(kagouti) -- add more if desired

------------------------------------------------------------
-- GROWL SOUNDS
------------------------------------------------------------

local growlSoundsWolf = { "WolfEquip1", "WolfEquip2", "WolfEquip3", "WolfEquip4", "WolfEquip5" }
local growlSoundsBear = { "bear scream", "bear roar", "bear moan" }
local growlSoundsRiek = { "rmnt moan", "riek scream", "riek roar", "riek moan" }
local growlSoundsNixhound = { "nix hound scream", "nix hound roar", "nix hound moan" }
local growlSoundsKagouti = { "kagouti roar", "kagouti scream", "kagouti moan" }
local growlSoundsAlit = { "alitscrm", "alitroar", "alitmoan" }
local growlSoundsAphyin = { "t_sndcrea_alphynscream", "t_sndcrea_alphynroar", "t_sndcrea_alphynmoan" }
local growlSoundsWormmouth= { "t_sndcrea_herneroar", "t_sndcrea_hernemoan", "t_sndcrea_hernescream" }
local growlSoundsTroll= { "t_sndcrea_cvtrollroar", "t_sndcrea_cvtrollscream", "t_sndcrea_cvtrollmoan" }
local growlSoundsKobold= { "t_sndcrea_koboldmoan", "t_sndcrea_koboldroar", "t_sndcrea_mummyroar" }
local growlSoundsGoblins= { "goblin scream", "goblin roar", "goblin moan" }
local growlSoundsBoars= { "boar moan", "boar roar", "boarsniff" }
local growlSoundsCliffs= { "cliff racer scream", "cliff racer roar", "cliff racer moan" }
--
local growlSoundsKwama = { "kwamF moan", "kwamF roar", "kwamF scream" }

------------------------------------------------------------
-- WARNING ANIMATIONS
------------------------------------------------------------

local warningAnimWolf = "walkForward"
local warningAnimBear = "walkForward"
local warningAnimNix = "walkForward"
local warningAnimKagouti = "walkForward"
local warningAnimAlit = "walkForward"
local warningAnimApyhin = "walkForward"
local warningAnimWormM = "walkForward"
local warningAnimTroll = "walkForward"
local warningAnimKobold = "walkForward"
local warningAnimGoblins = "walkForward"
local warningAnimBoar = "walkForward"
local warningAnimRiek = "WalkBack1h"
local warningAnimCliff = "Idle"
--
local warningAnimKwama = "Idle4"

------------------------------------------------------------
-- BEHAVIOR DEFINITION TABLE (sounds/anims per species)
------------------------------------------------------------

local warningCreatures = {}

for id in pairs(wolves)    do warningCreatures[id] = { sounds = growlSoundsWolf,    anim = warningAnimWolf   } end
for id in pairs(bears)     do warningCreatures[id] = { sounds = growlSoundsBear,    anim = warningAnimBear   } end
for id in pairs(rieklings) do warningCreatures[id] = { sounds = growlSoundsRiek,    anim = warningAnimRiek   } end
for id in pairs(nixhounds) do warningCreatures[id] = { sounds = growlSoundsNixhound,anim = warningAnimNix    } end
for id in pairs(kagouti)   do warningCreatures[id] = { sounds = growlSoundsKagouti, anim = warningAnimKagouti} end
for id in pairs(alit)      do warningCreatures[id] = { sounds = growlSoundsAlit,    anim = warningAnimAlit   } end
for id in pairs(aphyn)     do warningCreatures[id] = { sounds = growlSoundsAphyin,  anim = warningAnimApyhin } end
for id in pairs(wormmouth) do warningCreatures[id] = { sounds = growlSoundsWormmouth,anim= warningAnimWormM  } end
for id in pairs(trolls)    do warningCreatures[id] = { sounds = growlSoundsTroll,   anim = warningAnimTroll  } end
for id in pairs(kobold)    do warningCreatures[id] = { sounds = growlSoundsKobold,  anim = warningAnimKobold } end
for id in pairs(goblins)   do warningCreatures[id] = { sounds = growlSoundsGoblins, anim = warningAnimGoblins} end
for id in pairs(boars)     do warningCreatures[id] = { sounds = growlSoundsBoars,   anim = warningAnimBoar   } end
for id in pairs(cliffracers) do warningCreatures[id] = { sounds = growlSoundsCliffs, anim = warningAnimCliff } end
--
for id in pairs(kwama)     do warningCreatures[id] = { sounds = growlSoundsKwama,    anim = warningAnimKwama } end

------------------------------------------------------------
-- OPTIONAL DISTANCE OVERRIDES (e.g., cliff racers)
-- Defaults: warn 350..1500, attack < 350
------------------------------------------------------------

local DEFAULT_WARN_NEAR   = 350
local DEFAULT_WARN_FAR    = 1500
local DEFAULT_ATTACK_DIST = 350

local distanceOverrides = {
    ["cliff racer"]          = { warnNear = 1000, warnFar = 3000, attack = 1000 },
    ["cliff racer_diseased"] = { warnNear = 1000, warnFar = 3000, attack = 1000 },
}

-- No-warning instant aggro species (distance < 2000)
local instantAggro = {
    ["slaughterfish"] = true,
    ["dreugh"] = true,
    --
    ["h11_dreugh_dis"] = true,
    ["h11_slaughterfish_dis"] = true,
}

------------------------------------------------------------
-- INIT + "SET CLIFF SPEED ONCE"
------------------------------------------------------------

-- Cached per-actor locals to reduce table lookups
local _REC_ID, _BEHAVIOR, _INSTANT = nil, nil, false
local lastGrowlTime = 0
local GROWL_COOLDOWN = 1.25  -- seconds

-- persistence for "once" behavior
local didSetCliffSpeed = false

local function setCliffBaseSpeedOnce()
    -- Only for cliff racers; run once per actor instance
    if didSetCliffSpeed then return end
    if _REC_ID == "cliff racer" or _REC_ID == "cliff racer_diseased" then
        -- Set base "Speed" attribute to 300
        types.Actor.stats.attributes.speed(self).base = 300
        didSetCliffSpeed = true
    end
end

local function onInit()
    if self.type ~= types.Creature then return end
    _REC_ID   = self.recordId
    _BEHAVIOR = warningCreatures[_REC_ID]
    _INSTANT  = instantAggro[_REC_ID] == true

    local newFight = fight[_REC_ID]
    if newFight then
        types.Actor.stats.ai.fight(self).base = newFight
    end

    setCliffBaseSpeedOnce()
end

-- Persist the "once" flag across saves
local function onSave()
    return { didSetCliffSpeed = didSetCliffSpeed }
end

local function onLoad(saved)
    if saved then
        didSetCliffSpeed = saved.didSetCliffSpeed or false
    end
    -- Ensure IDs cached after load as well
    onInit()
end

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local growlCounter   = 0
local growlThreshold = math.random(1, 3)
local aiWasRemoved   = false
local savedPackage   = nil
local trackTimer     = nil

------------------------------------------------------------
-- MATH
------------------------------------------------------------

local function angleDifference(a, b)
    local diff = b - a
    return math.atan2(math.sin(diff), math.cos(diff))
end

------------------------------------------------------------
-- STOP TRACKING
------------------------------------------------------------

local function stopTracking()
    if trackTimer then
        trackTimer()
        trackTimer = nil
    end
    self.controls.yawChange = 0
end

------------------------------------------------------------
-- START TRACKING (uses per-species warning window)
------------------------------------------------------------

local function startTracking(player, warnNear, warnFar)
    if trackTimer then return end
    -- reduce inner timer frequency from 0.01s → 0.03s (still smooth, fewer callbacks)
    trackTimer = time.runRepeatedly(function()
        if types.Actor.stats.dynamic.health(self).current <= 0
        or types.Actor.stats.ai.fight(self).base == 100 then
            stopTracking()
            return
        end

        local toPlayer = player.position - self.position
        local distance = toPlayer:length()

        if distance < warnFar and distance > warnNear then
            local targetYaw  = math.atan2(toPlayer.x, toPlayer.y)
            local currentYaw = self.rotation:getYaw()
            self.controls.yawChange = angleDifference(currentYaw, targetYaw) / 6
        else
            stopTracking()
        end
    end, 0.03 * time.second)
end

------------------------------------------------------------
-- GROUP AWARENESS (whitelisted + strict same-record)
------------------------------------------------------------

local GROUP_RADIUS = 5000

local function checkGroupAggro(player)
    -- If we're already hostile, skip.
    if types.Actor.stats.ai.fight(self).modified >= 100 then return end

    -- Only species explicitly whitelisted can propagate group aggro.
    if not groupAggroEnabled[_REC_ID] then return end

    -- Skip group scan if player is far away from us. Packmates unlikely to matter.
    local pDist = (player.position - self.position):length()
    if pDist > GROUP_RADIUS + 1000 then return end

    for _, other in ipairs(nearby.actors) do
        if other ~= self
        and other.type == types.Creature
        -- STRICT: must be *exactly* the same record as us to propagate
        and other.recordId == _REC_ID
        and types.Actor.stats.dynamic.health(other).current > 0 then

            local dist = (other.position - self.position):length()
            if dist <= GROUP_RADIUS
            and types.Actor.stats.ai.fight(other).modified >= 90 then
                types.Actor.stats.ai.fight(self).base = 100
                AI.startPackage({ type = 'Combat', target = player })
                stopTracking()
                return
            end
        end
    end
end

------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------

local CHECK_INTERVAL = 2   -- keep as-is; early-outs do most of the work

time.runRepeatedly(function()

    if types.Actor.stats.dynamic.health(self).current <= 0 then return end
    if self.type ~= types.Creature then return end

    local player = nearby.players[1]
    if not player then return end

    -- Per-species distances (with fallback to defaults)
    local distOverride = distanceOverrides[_REC_ID]
    local warnNear   = distOverride and distOverride.warnNear or DEFAULT_WARN_NEAR
    local warnFar    = distOverride and distOverride.warnFar  or DEFAULT_WARN_FAR
    local attackDist = distOverride and distOverride.attack   or DEFAULT_ATTACK_DIST
    local resetDist  = math.max(2000, warnFar + 500)

    -- Cheap far-distance early-out
    local distance  = (player.position - self.position):length()
    if distance > resetDist then
        if growlCounter ~= 0 then
            growlCounter   = 0
            growlThreshold = math.random(1, 3)
        end
        return
    end

    -- GROUP CHECK (cheap guard inside)
    checkGroupAggro(player)

    -- SPECIAL: INSTANT AGGRO (no warning) FOR SLAUGHTERFISH/DREUGH
    if _INSTANT and distance < 2000 then
        types.Actor.stats.ai.fight(self).base = 100
        AI.startPackage({ type = 'Combat', target = player })
        stopTracking()
        return
    end

    -- COMBAT STATE
    if types.Actor.stats.ai.fight(self).base == 100 then
        stopTracking()
        if aiWasRemoved then
            aiWasRemoved = false
            if savedPackage then
                AI.startPackage(savedPackage)
                savedPackage = nil
            end
        end
        return
    end

    --------------------------------------------------------
    -- WARNING / STALKING *ONLY* FOR WARNING CREATURES
    --------------------------------------------------------
    if _BEHAVIOR then
        if distance < warnFar and distance > warnNear then

            if not aiWasRemoved then
                savedPackage = AI.getActivePackage()
                aiWasRemoved = true
                AI.removePackages("Wander")
            end

            startTracking(player, warnNear, warnFar)

            -- Gate anim/sound so we don't spam every tick
            if _BEHAVIOR.anim then
                anim.playBlended(self, _BEHAVIOR.anim, {
                    priority = anim.PRIORITY.Scripted
                })
            end

            local now = core.getRealTime and core.getRealTime() or 0
            if now == 0 or (now - lastGrowlTime) >= GROWL_COOLDOWN then
                local sounds = _BEHAVIOR.sounds
                if sounds and #sounds > 0 then
                    local sound = sounds[math.random(#sounds)]
                    core.sound.playSound3d(sound, self, {
                        timeOffset = 0.1,
                        volume = 5,
                        loop = false,
                        pitch = 1.0
                    })
                end
                lastGrowlTime = now
            end

            growlCounter = growlCounter + 1

        else
            stopTracking()
            if aiWasRemoved then
                aiWasRemoved = false
                if savedPackage then
                    AI.startPackage(savedPackage)
                    savedPackage = nil
                end
            end
        end

        -- ATTACK TRIGGER: ONLY for warning creatures
        if distance < attackDist or growlCounter > 1 + growlThreshold then
            types.Actor.stats.ai.fight(self).base = 100
            AI.startPackage({ type = 'Combat', target = player })
            stopTracking()
        end
    end

    -- RESET if close-but-not-warning and we drifted away
    if distance > resetDist then
        growlCounter   = 0
        growlThreshold = math.random(1, 3)
    end

end, CHECK_INTERVAL * time.second)

------------------------------------------------------------
-- RETURN
------------------------------------------------------------

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
    }
}
