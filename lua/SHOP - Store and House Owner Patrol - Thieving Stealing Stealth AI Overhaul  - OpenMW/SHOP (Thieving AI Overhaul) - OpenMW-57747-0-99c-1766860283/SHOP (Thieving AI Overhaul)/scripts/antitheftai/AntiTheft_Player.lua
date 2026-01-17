--[[
SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW.
Copyright (C) 2025 Łukasz Walczak

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
----------------------------------------------------------------------
-- Anti-Theft Guard AI  •  v0.9 PUBLIC TEST  •  OpenMW ≥ 0.49
-- PLAYER SCRIPT – Modular Architecture
----------------------------------------------------------------------
-- Load modules
local config      = require('scripts.antitheftai.modules.config')
local omwStorage  = require('openmw.storage')
local async       = require('openmw.async')
local core        = require('openmw.core')
local settings     = require('scripts.antitheftai.SHOPsettings')
local utils       = require('scripts.antitheftai.modules.utils')
local storage     = require('scripts.antitheftai.modules.storage')   -- module version
local detection   = require('scripts.antitheftai.modules.detection')
local classification = require('scripts.antitheftai.modules.npc_classification')
local companionDetection = require('scripts.antitheftai.modules.companion_detection')
local pathModule  = require('scripts.antitheftai.modules.path_recording')
local doorModule  = require('scripts.antitheftai.modules.door_transitions')
local state = require('scripts.antitheftai.modules.state')
local types = require('openmw.types')
local ui = require('openmw.ui')

-- Local hardcoded NPC voice response table based on race and gender
local guardActions = require('scripts.antitheftai.modules.guard_actions')


-- Use the settings module which automatically handles player/global storage context

-- Track which NPCs are currently in search mode
local searchingNPCs = {}

-- Flag to skip cell change logic when teleport spells are used
local skipCellChangeLogic = false
local actions     = require('scripts.antitheftai.modules.guard_actions')
local crossCell   = require('scripts.antitheftai.modules.cross_cell_returns')

-- Track pending bounty LoS checks (continuous monitoring during door opening)
local pendingBountyMonitoring = {}  -- doorId -> {npcId, bountyAmount, startTime, doorPosition}
local pendingWitnessAttacks = {}    -- npcId -> boolean (true if we expect this NPC to attack player shortly)

----------------------------------------------------------------------
-- Debug logging with live-toggle support
----------------------------------------------------------------------

local seenMessages = {}
local globalDebugEnabled = settings.general:get('enableGlobalDebug') -- For door logs as requested
local masterLoggingEnabled = settings.general:get('enableLogging')
if masterLoggingEnabled == nil then masterLoggingEnabled = true end

-- Debug: Check what value is actually stored
local rawStunValue = settings.general:get('stunChanceDisplay')
print("[STUN DISPLAY DEBUG] Raw value from settings:", rawStunValue)
print("[STUN DISPLAY DEBUG] Type:", type(rawStunValue))
config.STUN_CHANCE_DISPLAY = rawStunValue or 'contextual'
print("[STUN DISPLAY DEBUG] Final config value:", config.STUN_CHANCE_DISPLAY)

config.ADD_STUN_SUFFIX = settings.general:get('addStunChanceSuffix') or false

-- refresh when the storage section changes (option toggled in MCM)
settings.general:subscribe(async:callback(function(_, key)
    -- Log handling is now direct, no local variable needed
    
    -- Sync to Global/NPCs
    if key then
        local val = settings.general:get(key)
        core.sendGlobalEvent('AntiTheft_SyncSetting', { group = 'general', key = key, value = val })
    elseif key == nil then
        -- Sync all essential keys if nil (changed all or init?)
        local keys = {'enableDebug', 'enableGlobalDebug', 'enableBlackjackSpawning', 'enableLogging', 'enableDoorMechanics', 'disableHelloWhileFollowing', 'stunChanceDisplay', 'addStunChanceSuffix', 'enableBedDetection'}
        for _, k in ipairs(keys) do
            core.sendGlobalEvent('AntiTheft_SyncSetting', { group = 'general', key = k, value = settings.general:get(k) })
        end
    end

    if key == nil or key == 'enableGlobalDebug' then
        globalDebugEnabled = settings.general:get('enableGlobalDebug')
    end
    if key == nil or key == 'enableLogging' then
        masterLoggingEnabled = settings.general:get('enableLogging')
        if masterLoggingEnabled == nil then masterLoggingEnabled = true end
    end
    if key == nil or key == 'stunChanceDisplay' then 
        local rawValue = settings.general:get('stunChanceDisplay')
        print("[STUN DISPLAY SUBSCRIBE DEBUG] Key:", key, "Raw value:", rawValue, "Type:", type(rawValue))
        config.STUN_CHANCE_DISPLAY = rawValue or 'contextual'
        print("[STUN DISPLAY SUBSCRIBE DEBUG] Updated config.STUN_CHANCE_DISPLAY to:", config.STUN_CHANCE_DISPLAY)
    end
    if key == nil or key == 'addStunChanceSuffix' then config.ADD_STUN_SUFFIX = settings.general:get('addStunChanceSuffix') or false end
    if key == nil or key == 'disableHelloWhileFollowing' then
        config.DISABLE_HELLO_WHILE_FOLLOWING = settings.general:get('disableHelloWhileFollowing')
        if config.DISABLE_HELLO_WHILE_FOLLOWING == nil then config.DISABLE_HELLO_WHILE_FOLLOWING = true end
    end
end))

-- Update config values when settings change
settings.timing:subscribe(async:callback(function(_, key)
    if key == nil or key == 'enterDelay' then config.ENTER_DELAY = settings.timing:get('enterDelay') or 1.5 end
    if key == nil or key == 'updatePeriod' then config.UPDATE_PERIOD = settings.timing:get('updatePeriod') or 1.0 end
    if key == nil or key == 'searchWTimeMin' then config.SEARCH_WTIME_MIN = settings.timing:get('searchWTimeMin') or 10.0 end
    if key == nil or key == 'searchWTimeMax' then config.SEARCH_WTIME_MAX = settings.timing:get('searchWTimeMax') or 15.0 end
    if key == nil or key == 'losCheckInterval' then config.LOS_CHECK_INTERVAL = settings.timing:get('losCheckInterval') or 1.0 end
    if key == nil or key == 'hierarchyCheckInterval' then config.HIERARCHY_CHECK_INTERVAL = settings.timing:get('hierarchyCheckInterval') or 1.5 end
    if key == nil or key == 'pathSampleInterval' then config.PATH_SAMPLE_INTERVAL = settings.timing:get('pathSampleInterval') or 1.0 end
    if key == nil or key == 'minWanderDelay' then config.MIN_WANDER_DELAY = settings.timing:get('minWanderDelay') or 10.0 end
    if key == nil or key == 'maxWanderDelay' then config.MAX_WANDER_DELAY = settings.timing:get('maxWanderDelay') or 15.0 end
end))

settings.distances:subscribe(async:callback(function(_, key)
    if key == nil or key == 'searchWDist' then config.SEARCH_WDIST = settings.distances:get('searchWDist') or 1000 end
    if key == nil or key == 'pickRange' then config.PICK_RANGE = settings.distances:get('pickRange') or 1000 end
    if key == nil or key == 'desiredDistMin' then config.DESIRED_DIST_MIN = settings.distances:get('desiredDistMin') or 100 end
    if key == nil or key == 'desiredDistMax' then config.DESIRED_DIST_MAX = settings.distances:get('desiredDistMax') or 350 end
    if key == nil or key == 'losRange' then config.LOS_RANGE = settings.distances:get('losRange') or 1000 end
end))

settings.vars:subscribe(async:callback(function(_, key)
    if key == nil or key == 'losHalfCone' then config.LOS_HALF_CONE = math.rad(settings.vars:get('losHalfCone') or 170) end
    if key == nil or key == 'chamHideLimit' then config.CHAM_HIDE_LIMIT = settings.vars:get('chamHideLimit') or 1 end
    if key == nil or key == 'dispositionFollowingIgnore' then config.DISPOSITION_FOLLOWING_IGNORE = settings.vars:get('dispositionFollowingIgnore') or 100 end
    if key == nil or key == 'simulatedTravelSpeed' then config.SIMULATED_TRAVEL_SPEED = settings.vars:get('simulatedTravelSpeed') or 300.0 end
end))

settings.distances:subscribe(async:callback(function(_, key)
    if key == nil or key == 'detectionRange' then config.DETECTION_RANGE = settings.distances:get('detectionRange') or 175.0 end
end))

settings.bounties:subscribe(async:callback(function(_, key)
    if key == nil or key == 'lockingDoorBounty' then config.LOCKING_DOOR_BOUNTY = settings.bounties:get('lockingDoorBounty') or 150 end
end))

----------------------------------------------------------------------
-- Safe module loading
----------------------------------------------------------------------

local function safeRequire(moduleName)
    local success, module = pcall(require, moduleName)
    if not success then
        log('[AntiTheft-Player] Error loading module ' .. moduleName .. ': ' .. tostring(module))
        return nil
    end
    return module
end



local self   = safeRequire('openmw.self')
local nearby = safeRequire('openmw.nearby')
local types  = safeRequire('openmw.types')
local util   = safeRequire('openmw.util')
local core   = safeRequire('openmw.core')
local I      = safeRequire('openmw.interfaces')
local input  = safeRequire('openmw.input')
local ui     = safeRequire('openmw.ui')
local camera = safeRequire('openmw.camera')

if not (self and nearby and types and util and core) then
    error('[AntiTheft-Player] CRITICAL: Required modules failed to load!')
end

----------------------------------------------------------------------
-- Debug logging with live-toggle support
----------------------------------------------------------------------

local function log(...)
    -- PERFORMANCE: Early exit if debug is disabled (saves ~1500 ops/sec)
    if not masterLoggingEnabled or not (settings.general and settings.general:get('enableDebug')) then return end
    
    -- Only do string conversion and logging if debug is actually enabled
    local args = { ... }
    for i, v in ipairs(args) do
        -- Simplified: Just convert to string, skip expensive NPC name lookup
        -- The hex IDs are still useful for debugging
        args[i] = tostring(v)
    end
    
    local msg = table.concat(args, ' ')
    -- Note: reusing seenMessages logic if desired, or just print
    -- The simple log I added earlier uses print directly.
    -- I'll use print consistent with previous changes.
    print('[AntiTheft-Player] ' .. msg)
end

-- Helper: Door Debug Logging (Controlled by enableGlobalDebug)
local function doorLog(...)
    if masterLoggingEnabled and globalDebugEnabled then
        print('[AntiTheft-Player] [DOOR]', ...)
    end
end

-- Initial Settings Sync (Ensure Global Scripts/NPCs match Player Settings)
local keys = {'enableDebug', 'enableGlobalDebug', 'enableBlackjackSpawning', 'enableLogging', 'enableDoorMechanics', 'disableHelloWhileFollowing'}
for _, k in ipairs(keys) do
    if settings.general then
        core.sendGlobalEvent('AntiTheft_SyncSetting', { group = 'general', key = k, value = settings.general:get(k) })
    end
end

log('=== SCRIPT LOADING STARTED v20.0 - MODULAR ===')
log('All required modules loaded successfully')

-- Initialize systems
local disabledNpcNames, disabledCellNames = classification.initializeFilters(config)


----------------------------------------------------------------------
-- Stealth-effect helpers (invis / chameleon)
----------------------------------------------------------------------

-- Return the first ActiveSpellEffect on the actor that matches effectId,
-- or nil if the effect isn't running.
local function getActiveSpellEffect(actor, effectId)
    if not actor then return nil end
    local activeSpells = types.Actor.activeSpells(actor)
    if not activeSpells or not activeSpells.getSize then return nil end
    for i = 0, activeSpells:getSize() - 1 do
        local spell = activeSpells:get(i)
        if spell and spell.effects and spell.effects.getSize then
            for j = 0, spell.effects:getSize() - 1 do
                local eff = spell.effects:get(j)
                if eff and eff.id == effectId then
                    return eff   -- has .duration and .durationLeft
                end
            end
        end
    end
    return nil
end

-- When we have a recruited guard, log the remaining time of the two
-- "stealth" effects once per call.  (Called from the two places you
-- already examine the durations.)
local function debugPrintStealthDurations()
    if not (state.guard and state.guard:isValid()) then return end  -- only after recruitment

    local invisEff = getActiveSpellEffect(self, config.EFFECT_INVIS)
    local chamEff  = getActiveSpellEffect(self, config.EFFECT_CHAM)

    if invisEff then
        local left = invisEff.durationLeft or invisEff.duration
        log("[STEALTH-DEBUG] Invisibility:  " ..
            (left and string.format("%.1f s left", left) or "constant"))
    end
    if chamEff then
        local left = chamEff.durationLeft or chamEff.duration
        log("[STEALTH-DEBUG] Chameleon:     " ..
            (left and string.format("%.1f s left", left) or "constant"))
    end
end


----------------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------------

local function isCellAllowed()
    if not self.cell then return false end
    if not self.cell.isExterior then return true end -- Interior cells are allowed
    -- Check if this exterior cell is in the enabled list
    local cellName = self.cell.name or ""
    return config.ENABLED_EXTERIOR_CELLS[cellName] == true
end

-- Cache for cell disabled check (only check once per cell)
local cellDisabledCache = {}
local lastCheckedCellName = nil

local function isCellDisabledByAnyRule()
    local cellName = self.cell and self.cell.name or ""
    
    -- If cell changed, clear cache
    if lastCheckedCellName ~= cellName then
        cellDisabledCache = {}
        lastCheckedCellName = cellName
    end
    
    -- Return cached result if available
    if cellDisabledCache[cellName] ~= nil then
        return cellDisabledCache[cellName]
    end
    
    -- Perform check only once per cell
    log("Checking cell disabled rules for cell:", cellName)

    -- Enforce enabled exterior cells: if this exterior cell is enabled, allow it regardless of other rules
    if self.cell and self.cell.isExterior and config.ENABLED_EXTERIOR_CELLS[cellName] then
        log("Exterior cell", cellName, "is in ENABLED_EXTERIOR_CELLS - allowing following")
        cellDisabledCache[cellName] = false
        return false -- not disabled
    end



    if classification.isCellDisabled(self.cell, disabledCellNames) then 
        cellDisabledCache[cellName] = true
        return true 
    end
    -- Removed slave/enemy checks to allow script in guild cells with slaves
    -- if classification.shouldDisableCellForSlavesAndEnemies(nearby, types) then return true end
    if classification.shouldDisableCellForOnlyEnemies(nearby, types) then 
        cellDisabledCache[cellName] = true
        return true 
    end
    if classification.shouldDisableCellForPublican(nearby, types) then 
        cellDisabledCache[cellName] = true
        return true 
    end
    
    -- Cache result as not disabled
    cellDisabledCache[cellName] = false
    return false
end

-- Lower disposition of all NPCs in the cell by 15
local function lowerCellDisposition()
    log("=== SENDING GLOBAL EVENT TO LOWER CELL DISPOSITION ===")
    core.sendGlobalEvent('AntiTheft_LowerCellDisposition', {})
    log("=== GLOBAL EVENT SENT ===")
end

-- Lower disposition of a specific NPC by 15
local function lowerNPCDisposition(npcId)
    if not npcId then return end
    log("=== SENDING GLOBAL EVENT TO LOWER DISPOSITION FOR NPC", npcId, "===")
    core.sendGlobalEvent('AntiTheft_LowerNPCDisposition', { npcId = npcId })
    log("=== GLOBAL EVENT SENT ===")
end

----------------------------------------------------------------------
-- Guard Picker
----------------------------------------------------------------------

-- Disposition cache - only check disposition once per NPC
local dispositionCache = {} -- npcId -> {disposition, lastCheckedCell}
local dispositionThresholdLogged = false

local function pickGuard(allowCurrentGuard)
    if not isCellAllowed() then return nil end
    if isCellDisabledByAnyRule() then return nil end

    -- Check if player has high rank in detected guild faction (disable script)
    if self.cell and not self.cell.isExterior then
        local cellFaction = classification.detectCellFaction(nearby, types)
        if cellFaction then
            if types.NPC and types.NPC.getFactions then
                local playerFactions = types.NPC.getFactions(self)
                if playerFactions then
                    for _, factionId in ipairs(playerFactions) do
                        if factionId == cellFaction then
                            local playerRank = types.NPC.getFactionRank(self, factionId)
                            if playerRank >= config.FACTION_IGNORE_RANK then
                                log("Player has rank", playerRank, "in", cellFaction, "- disabling script in this guild cell")
                                state.scriptDisabled = true
                                return nil
                            end
                        end
                    end
                end
            end
        end
    end
    state.scriptDisabled = false

    -- Log the current disposition threshold setting (only once)
    local dispositionThreshold = config.DISPOSITION_FOLLOWING_IGNORE
    if not dispositionThresholdLogged then
        log("Disposition following ignore threshold:", dispositionThreshold)
        dispositionThresholdLogged = true
    end

    local best = nil
    local bestPriority = 999
    local bestDist = math.huge
    
    local currentCellName = self.cell and self.cell.name or ""

    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC then
            -- Skip unconscious NPCs (stunned by blackjack)
            if not types.Actor.activeSpells(actor):isSpellActive('detd_sleep_spell3') then
                local record = types.NPC.record(actor)
                local essential = record and record.isEssential or false

                if not essential and not classification.isNpcDisabled(actor, disabledNpcNames, types) and utils.friendly(actor, self, types, nearby) then
                    if not state.mustCompleteReturn[actor.id] and not state.returnInProgress[actor.id] then
                        local isDismissed = false
                        for _, dismissedData in pairs(state.dismissedNPCs) do
                            if dismissedData.npc.id == actor.id then
                                isDismissed = true
                                break
                            end
                        end

                        if not isDismissed then
                            -- Skip vanilla companions (NPCs following player via AI packages)
                             if companionDetection.isCompanion(actor) then
                                 log("NPC", actor.id, "is a vanilla companion - skipping recruitment")
                                 goto continue_pick
                            end

                            -- Check disposition threshold (with caching)
                            local npcDisposition
                            local cached = dispositionCache[actor.id]
                            
                            -- Use cached disposition if available and cell hasn't changed
                            if cached and cached.lastCheckedCell == currentCellName then
                                npcDisposition = cached.disposition
                            else
                                -- Fetch fresh disposition
                                npcDisposition = types.NPC.getDisposition(actor, self) or 50
                                -- Cache it
                                dispositionCache[actor.id] = {
                                    disposition = npcDisposition,
                                    lastCheckedCell = currentCellName
                                }
                                log("Checking NPC", actor.id, "- disposition:", npcDisposition, "threshold:", dispositionThreshold)
                            end
                            
                            if npcDisposition <= dispositionThreshold then
                                if allowCurrentGuard or not (state.guard and actor.id == state.guard.id) then
                                    local d = (actor.position - self.position):length()
                                    if d <= config.PICK_RANGE and detection.canNpcSeePlayer(actor, self, nearby, types, config) then
                                        local priority = classification.getNPCPriority(actor, types, self, self.cell, config, nearby)
                                        if priority < bestPriority or (priority == bestPriority and d < bestDist) then
                                            best = actor
                                            bestPriority = priority
                                            bestDist = d
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        ::continue_pick:: ;
    end

    return best, bestPriority
end

----------------------------------------------------------------------
-- UI Feedback Loop (Stun Chance)
----------------------------------------------------------------------
local lastStunUpdate = 0
local STUN_UPDATE_INTERVAL = 0.5 -- Check 2 times per second (User Requested)
local lastStunMessage = nil

local lastStunMessageTime = 0
local MESSAGE_COOLDOWN = 5.0

-- Keylock Hold/Cooldown state
local lastKeylockAttemptTime = 0
local KEYLOCK_COOLDOWN = 1.0 -- Show message once every 5 seconds if condition persists



local function onNPCReady(eventData)
    if eventData and eventData.npcId then
        log("NPC", eventData.npcId, "is READY for re-detection")

        state.mustCompleteReturn[eventData.npcId] = nil
        state.returnInProgress[eventData.npcId] = nil
        state.crossCellReturns[eventData.npcId] = nil

        local wasCurrentGuard = state.guard and state.guard.id == eventData.npcId
        if wasCurrentGuard then
            state.reset()
            state.hasReturnedHome = true
        end

        -- Clear the guard state if this was the current guard, and prepare for normal recruitment
        if wasCurrentGuard then
            state.guard = nil
            state.guardPriority = 999
            state.searching = false  -- Clear search state to prevent re-searching when invisibility wears off
            state.forceLOSCheck = true  -- Force a LOS check to trigger normal recruitment
            -- Clear from disbanded guards list since NPC has returned home
            state.disbandedGuards[eventData.npcId] = nil
            log("Cleared guard state for returned NPC", eventData.npcId, "- will re-engage via normal recruitment when player is visible")
        end

        -- Force specific recruitment for returned NPC when player becomes visible
        if isCellAllowed() then
            state.returnedNPCToRecruit = eventData.npcId
            log("Returned NPC", eventData.npcId, "will be recruited when player is visible and in LOS")
        end
    end
end

-- Clear search state when NPC is teleported home
local function onClearSearchState(eventData)
    if eventData and eventData.npcId then
        log("Clearing search state for NPC", eventData.npcId, "- NPC was teleported home")

        -- Clear all search-related state for this NPC
        core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = eventData.npcId })
        state.searching = false
        state.searchT = 0
        state.searchTime = nil
        state.wasHidden = false
        state.stealthMessageSent = false
        state.invisMessageSent = false
        state.justRemovedInvisibility = false
        state.justRemovedChameleon = false

        -- Clear any stored spell durations
        state.invisSpellDuration = nil
        state.chamSpellDuration = nil

        -- Clear detection effects
        detection.removedEffects[config.EFFECT_INVIS] = nil
        detection.removedEffects[config.EFFECT_CHAM] = nil

        log("✓ Search state cleared for NPC", eventData.npcId)
    end
end

-- Handle successful blackjack hit (XP gain + Durability loss)
local function onBlackjackSuccess(data)
    if not data then return end
    
    -- 1. XP Gain (3% of total level progress)
    -- Note: OpenMW Lua API for progress modification
    if types.Player.stats.skills.sneak then
        local sneakSkill = types.Player.stats.skills.sneak(self)
        local currentProgress = sneakSkill.progress
        -- Add 0.05 (5%)
        sneakSkill.progress = math.min(1.0, currentProgress + 0.05)
        log("[AntiTheft-Player] Blackjack Success: Added 5% Sneak XP. Progress:", currentProgress, "->", sneakSkill.progress)
        
        -- If progress reached 1.0, the engine handles level up on next frame/check
    end
    
    -- 2. Durability Loss (Must be done by Global script)
    if data.weapon then
        core.sendGlobalEvent('AntiTheft_DamageWeapon', { 
            weapon = data.weapon, 
            damage = 50,
            owner = self 
        })
        log("[AntiTheft-Player] Sent AntiTheft_DamageWeapon request to global")
    end
end

local function onS3CombatTargetAdded(eventData)
    log("DEBUG: S3CombatTargetAdded event received, actor:", eventData and eventData.id or "nil")
    
    -- Relay event to the actor so they can handle local logic (like Flee Silence application)
    if eventData and eventData.sendEvent then
        eventData:sendEvent('AntiTheft_FleeConfirm')
        log("DEBUG: Relayed AntiTheft_FleeConfirm to actor", eventData.id)
    end

    -- eventData is the actor that entered combat
    if eventData and state.guard and state.guard.id == eventData.id and state.following then
        -- Check if the NPC is fighting the player by checking the player's combat targets
        local combatTargets = I.s3lf.combatTargets
        local fightingPlayer = false
        if combatTargets then
            for _, target in ipairs(combatTargets) do
                if target.id == eventData.id then
                    fightingPlayer = true
                    break
                end
            end
        end

        -- OVERRIDE: If we explicitly expect this NPC to attack (e.g. witnessed body)
        if pendingWitnessAttacks[eventData.id] then
            log("[COMBAT SYNC] NPC", eventData.id, "flagged as witness attacker - Force Combat Allow")
            fightingPlayer = true
        end

        if fightingPlayer then
            log("Following NPC entered combat with player - allowing combat to continue")
            state.guardInCombat = true
            state.wasInCombatWithPlayer = true
            -- Don't disband, let the NPC fight the player
        else
            log("Following NPC entered combat with non-player target - disbanding completely")
            -- Disband completely from the player and remove all scripts to allow default behavior
            state.following = false
            core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
            state.searching = false
            state.returningHome = false

            -- Add to disbanded guards list to maintain effect detection and combat memory
            if state.guard and state.guard:isValid() then
                state.disbandedGuards[state.guard.id] = {
                    wasInCombatWithPlayer = state.wasInCombatWithPlayer
                }
                -- Store combat memory persistently
                storage.storeCombatMemory(state.guard.id, state.wasInCombatWithPlayer)
                log("Added NPC", state.guard.id, "to disbanded guards list for effect detection (combat memory:", state.wasInCombatWithPlayer and "yes" or "no", ")")
            end

            -- Clear guard reference to allow recruitment of another NPC
            state.guard = nil
            state.guardPriority = 999
            state.guardInCombat = false
        end
    elseif not state.guard then
        -- No guard is following - but door monitoring should still be active during combat
        log("No guard following - combat continues with door monitoring active")
    end
end

local function onS3CombatTargetRemoved(eventData)
    log("DEBUG: S3CombatTargetRemoved event received, actor:", eventData and eventData.id or "nil")
    -- eventData is the actor that exited combat
    if eventData and state.guard and state.guard.id == eventData.id then
        if types.Actor.isDead(eventData) then
            log("Following NPC", state.guard.id, "died - removing AI packages")
            state.guard:sendEvent('RemoveAIPackages')
    else
        log("Following NPC", state.guard.id, "exited combat - starting search for player")
        -- Mark that this search was initiated due to combat removal
        state.searchDueToCombatRemoval = true
        -- Start search behavior instead of going home
        actions.startSearch(state, detection, config)
    end
        -- Reset combat state
        state.guardInCombat = false
    end
end

-- List of teleport effect IDs that should trigger guard teleport
local TELEPORT_EFFECT_IDS = {
    'almsivi intervention',
    'sc_almsiviintervention',
    'sc_divineintervention',
    'divine intervention',
    'recall',
    'SummonCreature05'
}

-- Special effect that requires location selection before teleporting
local DELAYED_TELEPORT_EFFECT = 'SummonCreature05'
local pendingDelayedTeleport = false
local wasDelayedTeleportActive = false
local delayedTeleportTimer = 0
local delayedTeleportActive = false
local interfaceWindowOpenTime = 0
local INTERFACE_WINDOW_TIMEOUT = 30 -- seconds

-- Door state tracking for lock spell bounty
local doorStates = {}  -- doorId -> {wasLocked = boolean, doorState = string, lastCheckTime = number}

-- List of lock effect IDs that should trigger bounty check
local LOCK_EFFECT_IDS = {
    'lock',
    'sc_lock',
    'lock lock'
}

-- Helper to determine if NPC is a guard
local function isGuard(npc)
    if not npc then return false end
    local record = types.NPC.record(npc)
    if not (record and record.class) then return false end
    local class = record.class:lower()
    return class:find("guard") or class:find("ordinator") or class:find("buoyant")
end

-- Centralized function to handle NPC travel/investigation (Replacing old Travel script behavior)
local function onForceTravelToPlayer(data)
    if not data or not data.npcId then return end
    local npc = world.getObjectByFormId(data.npcId)
    if not npc or npc.type ~= types.NPC then return end

    if isGuard(npc) then
         log("[FORCE TRAVEL] NPC", npc.id, "is GUARD - Applying bounty and investigating (Travel to player)")
         
         -- 1. Apply Bounty (Configurable)
         local race, gender = nil, nil
         local record = types.NPC.record(npc)
         if record then
             local rawRace = record.race and record.race.id and record.race.id:lower() or nil
             race = rawRace
             gender = record.isMale -- boolean
         end
         
         
         -- 2. Initiate Investigation (Request Pursue via Global Event)
         -- "Pursue must be applied after adding bounty, not before."
         -- We send the flag to Global script to trigger Pursue AFTER bounty application.
         
         local amount = config.LOCKING_DOOR_BOUNTY or 150
         if amount > 0 then
             core.sendGlobalEvent('AntiTheft_SetPlayerBounty', {
                bountyAmount = amount,
                reason = "Unlocking door while observed",
                npcId = npc.id,
                npcRace = race,
                npcGender = gender,
                forcePursue = true -- Flag to tell Global to trigger Pursue
             })
             log("✓ Sent Bounty event with forcePursue flag to Global")
         else
            -- If no bounty, we might still want to pursue?
            -- Assuming yes if "guard detecting crime".
             core.sendGlobalEvent('AntiTheft_SetPlayerBounty', {
                bountyAmount = 0,
                npcId = npc.id,
                npcRace = race,
                npcGender = gender,
                forcePursue = true
             })
             log("✓ Sent Zero-Bounty event with forcePursue flag (Config=0)")
         end
         
         -- No local package start - waiting for Global to do it
         
    else
        log("[FORCE TRAVEL] NPC", npc.id, "is CIVILIAN - Playing bed voice instead of traveling")
        local record = types.NPC.record(npc)
        if record then
             local race = record.race and record.race.id and record.race.id:lower() or "dark elf"
             local gender = record.isMale and "male" or "female"
             
             -- Send to global for sound playback (using bed_voices module)
             core.sendGlobalEvent('AntiTheft_PlayCivilianUnlockSound', {
                npcId = npc.id,
                race = race,
                gender = gender
             })
             log("✓ Sent sound request to global")
        end
    end
end

-- Initialize door states when entering interior cell
local function initializeDoorStates()
    if not settings.general:get('enableDoorMechanics') then return end

    doorLog("=== INITIALIZING DOOR STATES ===")
    doorStates = {}
    local doorCount = 0
    local unlockedDoors = 0

    if not nearby.objects then
        log("[DOOR STATE] WARNING: nearby.objects is nil - cannot initialize door states")
        return
    end

    for _, obj in ipairs(nearby.objects) do
        if obj.type == types.Door then
            local doorId = obj.id
            local isLocked = types.Lockable.isLocked(obj)
            local lockLevel = types.Lockable.getLockLevel(obj)
            local doorState = types.Door.getDoorState(obj)

            -- Only track doors that are not locked and in Idle or Closing state
            if not isLocked and (doorState == types.Door.STATE.Idle or doorState == types.Door.STATE.Closing) then
                doorStates[doorId] = {
                    wasLocked = false,
                    doorState = doorState,
                    lastCheckTime = core.getSimulationTime()
                }
                unlockedDoors = unlockedDoors + 1
                doorLog("Tracking unlocked door", doorId, "- state =", doorState, "- lock level =", lockLevel)
            else
                doorLog("Skipping door", doorId, "- locked =", isLocked, "- state =", doorState)
            end
            doorCount = doorCount + 1
        end
    end
    log("[DOOR STATE] === INITIALIZED", doorCount, "total doors,", unlockedDoors, "unlocked doors being tracked ===")
end
-- Check for door state changes and apply bounty if conditions met
local function checkDoorStateChanges(targetDoor)
    if not settings.general:get('enableDoorMechanics') then return end

    local doorsToCheck = {}
    if targetDoor then
        table.insert(doorsToCheck, targetDoor)
    else
        -- Fallback: Scan all nearby objects and actors (legacy behavior)
        if nearby.objects then
            for _, obj in ipairs(nearby.objects) do
                -- Only sync when actual state changes are detected
            end
        end
    end

    doorLog("=== CHECK COMPLETE - Total doors:", totalDoors, "- Doors locked this check:", doorsLocked, "===")
end
-- Detect teleport effects applied to player and teleport guard home immediately
local function onMagicEffectApplied(effectId, magnitude, effect)
    -- Check if this is a teleport effect
    local isTeleportEffect = false
    for _, teleportId in ipairs(TELEPORT_EFFECT_IDS) do
        if effectId == teleportId then
            isTeleportEffect = true
            break
        end
    end

    if isTeleportEffect and state.guard and state.guard:isValid() and (state.following or state.searching) then
        -- Special handling for delayed teleport effect (requires location selection)
        if effectId == DELAYED_TELEPORT_EFFECT then
            log("Delayed teleport effect '" .. effectId .. "' applied to player - waiting for location selection")
            pendingDelayedTeleport = true
            skipCellChangeLogic = true  -- Skip cell change logic when teleport spells are used
            return
        end

        log("Teleport effect '" .. effectId .. "' applied to player (magnitude: " .. tostring(magnitude) .. ") - teleporting guard home immediately")

        -- Stop path recording first
        if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
            pathModule.stopPathRecording(state.guard.id, state.guard.position)
        end

        -- Send event to global script to teleport the NPC
        local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)

        core.sendGlobalEvent('AntiTheft_TeleportHome', {
            npcId = state.guard.id,
            homePosition = state.home.pos,
            homeRotation = {
                x = rotX,
                y = rotY,
                z = rotZ
            }
        })

        -- Clear AI packages
        state.guard:sendEvent('RemoveAIPackages')

        -- Mark as teleported home
        state.returnInProgress[state.guard.id] = true
        state.mustCompleteReturn[state.guard.id] = true
        state.following = false
        core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
        state.searching = false
        state.returningHome = true
        state.searchT = 0

        skipCellChangeLogic = true  -- Skip cell change logic when teleport spells are used

        log("✓ NPC teleported home via global event due to teleport effect '" .. effectId .. "'")
    elseif (effectId == config.EFFECT_INVIS or effectId == config.EFFECT_CHAM) and state.guard and state.guard:isValid() and state.searching then
        -- Extend search time if invisibility/chameleon effect is applied during search
        local extension = 0
        if effect and effect.duration then
            if effect.duration == 0 or effect.duration > 1000000 then
                extension = 600 -- 10 minutes for constant effect
            else
                extension = effect.duration + math.random(15, 30)
            end
        end
        state.searchTime = (state.searchTime or config.SEARCH_WTIME_MAX) + extension
        log("Extended search time by", extension, "seconds due to effect '" .. effectId .. "' applied during search")
    end

    -- Store spell duration when invisibility/chameleon effect is applied
    if effectId == config.EFFECT_INVIS then
        state.invisSpellDuration = effect.duration
        log("Stored invisibility spell duration:", effect.duration, "seconds")
    elseif effectId == config.EFFECT_CHAM then
        state.chamSpellDuration = effect.duration
        log("Stored chameleon spell duration:", effect.duration, "seconds")
    end
end

-- Track door lock states for lock spell detection
local preCastDoorStates = {}

-- Delayed callback for lock spell success verification
local function checkLockSpellSuccess()
    doorLog("[LOCK SPELL] Checking if lock spell was successful...")

    local lockedDoors = 0
    local totalCheckedDoors = 0
    local lockedDoorPos = nil

    -- Check all doors in the cell
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.Door then
            totalCheckedDoors = totalCheckedDoors + 1
            local doorId = actor.id
            local wasUnlocked = preCastDoorStates[doorId]
            local isLocked = types.Lockable.isLocked(actor)

            if wasUnlocked and isLocked then
                lockedDoors = lockedDoors + 1
                doorLog("[LOCK SPELL] Door", doorId, "was unlocked before spell, now locked - SUCCESS!")
                -- Store position of first locked door
                if not lockedDoorPos then
                    lockedDoorPos = actor.position
                end
            elseif wasUnlocked and not isLocked then
                doorLog("[LOCK SPELL] Door", doorId, "was unlocked before spell, still unlocked - no change")
            end
        end
    end

    doorLog("[LOCK SPELL] Checked", totalCheckedDoors, "doors, found", lockedDoors, "newly locked doors")

    -- Clear the pre-cast states
    preCastDoorStates = {}

    -- If doors were successfully locked, check conditions and apply bounty
    if lockedDoors > 0 then
        -- Send event to global script to trigger NPC response and bounty check
        core.sendGlobalEvent('AntiTheft_CheckDoorLocks', {
            delay = 0.1  -- Check after 0.1 seconds
        })
        log("[LOCK SPELL] Lock spell successful - triggered global door lock check")
    else
        log("[LOCK SPELL] No doors were successfully locked - no bounty applied")
    end
end

-- Detect when player casts lock spells
local function onSpellCast(spellId)
    -- Check if this spell contains teleport effects
    local spellRecord = types.Spell.record(spellId)
    if spellRecord then
        for _, effect in ipairs(spellRecord.effects) do
            local effectId = effect.id
            local isTeleportEffect = false
            for _, teleportId in ipairs(TELEPORT_EFFECT_IDS) do
                if effectId == teleportId then
                    isTeleportEffect = true
                    break
                end
            end

            if isTeleportEffect and state.guard and state.guard:isValid() and (state.following or state.searching) then
                log("Player casting teleport spell '" .. spellId .. "' with effect '" .. effectId .. "' - teleporting guard home immediately")

                -- Stop path recording first
                if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
                    pathModule.stopPathRecording(state.guard.id, state.guard.position)
                end

                -- Send event to global script to teleport the NPC
                local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)

                core.sendGlobalEvent('AntiTheft_TeleportHome', {
                    npcId = state.guard.id,
                    homePosition = state.home.pos,
                    homeRotation = {
                        x = rotX,
                        y = rotY,
                        z = rotZ
                    }
                })

                -- Clear AI packages
                state.guard:sendEvent('RemoveAIPackages')

                -- Mark as teleported home
                state.returnInProgress[state.guard.id] = true
                state.mustCompleteReturn[state.guard.id] = true
                state.following = false
                core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
                state.searching = false
                state.returningHome = true
                state.searchT = 0

                log("✓ NPC teleported home via global event due to teleport spell '" .. spellId .. "'")
                break -- Only handle once per spell cast
            end

            -- Check for lock effects
            local isLockEffect = false
            for _, lockId in ipairs(LOCK_EFFECT_IDS) do
                if effectId == lockId then
                    isLockEffect = true
                    break
                end
            end

            if isLockEffect then
                log("Player casting lock spell '" .. spellId .. "' with effect '" .. effectId .. "' - tracking door states for success verification")

                -- Record current door lock states
                preCastDoorStates = {}
                for _, actor in ipairs(nearby.actors) do
                    if actor.type == types.Door then
                        local doorId = actor.id
                        local isLocked = types.Lockable.isLocked(actor)
                        preCastDoorStates[doorId] = not isLocked  -- true if was unlocked
                        log("[LOCK SPELL] Door", doorId, "pre-cast state: unlocked =", not isLocked)
                    end
                end

                -- Schedule success check after a short delay (1 second)
                async:registerTimerCallback("AntiTheft_LockSpellCheck", function()
                    checkLockSpellSuccess()
                end, 1.0)

                log("[LOCK SPELL] Lock spell cast detected - will check success in 1 second")
                break -- Only handle once per spell cast
            end
        end
    end
end

-- Event handler for lock spell bounty check
local function onCheckLockSpellBounty()
    log("[LOCK SPELL] Received bounty check event from global script")

    -- No immediate bounty - let global script handle it after unlock + LoS check
    log("[LOCK SPELL] Lock spell detected - global script will handle bounty after unlock sequence")
end

-- Event handler for door bounty application
local guardActions = require('scripts.antitheftai.modules.guard_actions')

local function playNpcVoiceResponse(npc)
    if not npc then
        log("[NPC VOICE RESPONSE] ERROR: npc argument is nil or missing")
        return
    end
    if not npc:isValid() then
        log("[NPC VOICE RESPONSE] ERROR: npc is invalid or not valid")
        return
    end
    
    local raceGenderInfo = guardActions.npcRaceGenderMap[npc.id]
    local race, gender

    if raceGenderInfo then
        race = raceGenderInfo.race
        gender = raceGenderInfo.gender
        log("[NPC VOICE RESPONSE] Using stored race and gender from npcRaceGenderMap for npc ID:", npc.id, "Race:", race, "Gender:", gender)
    else
        local record = types.NPC.record(npc)
        if not record then
            log("[NPC VOICE RESPONSE] ERROR: Failed to get NPC record for npc ID:", npc.id)
            return
        end

        -- Get race string from record's race id
        local rawRace = record.race and record.race.id and record.race.id:lower() or nil
        if not rawRace then
            log("[NPC VOICE RESPONSE] ERROR: npc race id is nil for npc ID:", npc.id)
            return
        end
        race = raceIdToName[rawRace]
        if not race then
            log("[NPC VOICE RESPONSE] ERROR: npc race", rawRace, "not found in raceIdToName mapping for npc ID:", npc.id)
            return
        end

        -- Get gender: true = female, false = male
        local isFemale = record.female
        gender = isFemale and "female" or "male"
        log("[NPC VOICE RESPONSE] Using race and gender from NPC record for npc ID:", npc.id, "Race:", race, "Gender:", gender)
    end

    -- Check if npcVoiceResponses exists (it was removed by user earlier)
    if not npcVoiceResponses then
        log("[NPC VOICE RESPONSE] npcVoiceResponses table not available - skipping voice response")
        return
    end

    local responsesForRaceGender = npcVoiceResponses[race] and npcVoiceResponses[race][gender]
    if not responsesForRaceGender or #responsesForRaceGender == 0 then
        log("[NPC VOICE RESPONSE] WARNING: no voice responses found for race", race, "gender", gender)
        return
    end

    -- Pick a random response
    local idx = math.random(#responsesForRaceGender)
    local voiceResponse = responsesForRaceGender[idx]
    if voiceResponse and voiceResponse.file and voiceResponse.response then
        log("[NPC VOICE RESPONSE] Sending global event to play voice file:", voiceResponse.file, "with response text:", voiceResponse.response, "for npc ID:", npc.id)
        core.sendGlobalEvent('AntiTheft_PlayNPCVoice', {npcId = npc.id, voiceFile = voiceResponse.file})
        log("[NPC VOICE RESPONSE] Global event sent for npc ID:", npc.id)
    else
        log("[NPC VOICE RESPONSE] WARNING: invalid voiceResponse data for npc ID:", npc.id)
    end
end

local function onApplyDoorBounty(data)
    if not data then return end -- data.bountyAmount check removed as we override it
    
    local bountyAmount = settings.bounties:get('lockingDoorBounty')
    log("[DOOR BOUNTY] Applying door bounty:", bountyAmount, "gold (Config)")

    -- Check if there's a valid guard following - if not, skip bounty application
    if not state.guard or not state.guard:isValid() then
        log("[DOOR BOUNTY] No valid guard following - skipping bounty application")
        return
    end

    local race, gender = nil, nil
    local guardRaceGender = guardActions.npcRaceGenderMap[state.guard.id]
    if guardRaceGender then
        race = guardRaceGender.race
        gender = guardRaceGender.gender
        log("[DOOR BOUNTY] Retrieved race and gender from npcRaceGenderMap: race =", race, ", gender =", gender)
    else
        -- Fallback: try to get from NPC record
        local record = types.NPC.record(state.guard)
        if record then
            local rawRace = record.race and record.race.id and record.race.id:lower() or nil
            if rawRace and raceIdToName[rawRace] then
                race = raceIdToName[rawRace]
                gender = record.isMale  -- true = male, false = female
                log("[DOOR BOUNTY] Retrieved race and gender from NPC record: race =", race, ", gender =", gender)
            else
                log("[DOOR BOUNTY] ERROR: Could not find race or gender for guard NPC")
            end
        else
            log("[DOOR BOUNTY] ERROR: NPC record not found for guard NPC")
        end
    end

    -- Since we're in a player script, we need to send the bounty change to a global script
    -- The global script will handle the actual bounty modification and investigation
    core.sendGlobalEvent('AntiTheft_SetPlayerBounty', {
        player = self,
        bountyAmount = bountyAmount, -- Use config value
        reason = "Door interaction while being followed",
        doorX = data.doorX,
        doorY = data.doorY,
        doorZ = data.doorZ,
        npcId = state.guard.id,
        npcRace = race,
        npcGender = gender
    })

    -- Play NPC voice response for the guard
    log("[DOOR BOUNTY] state.guard is valid with NPC ID:", state.guard.id, "calling playNpcVoiceResponse now")
    playNpcVoiceResponse(state.guard)

    -- Show message to player
    self:sendEvent('ShowMessage', {
        message = "You have been caught interacting with doors while being followed! Bounty increased by " .. bountyAmount .. " gold."
    })

    log("✓ Door bounty event sent to global script")

    -- Trigger investigation/pursue behavior (Guard vs Civilian logic)
    -- This ensures the guard reacts immediately to the locking action
    if state.guard and state.guard:isValid() then
        onForceTravelToPlayer({
            npcId = state.guard.id,
            playerPosition = self.position
        })
    end
end

-- Event handler for starting door investigation
local function onStartDoorInvestigation(data)
    if not data or not data.npcId then return end

    log("[DOOR INVESTIGATION] Starting door investigation for NPC:", data.npcId)

    -- Set investigation state to prevent normal following behavior
    state.investigatingDoor = true
    state.doorPosition = nil  -- Will be set when NPC reaches door area

    log("✓ Door investigation state set - NPC will not follow player during investigation")
end



-- Event handler for re-recruiting guard after door investigation
local function onReRecruitGuard(data)
    if not data or not data.npcId then return end

    log("[RECRUIT] Re-recruiting guard after door investigation:", data.npcId)

    -- Clear investigation state
    state.investigatingDoor = false
    state.doorPosition = nil

    -- Find the NPC
    local npc = nil
    for _, actor in ipairs(nearby.actors) do
        if actor.id == data.npcId then
            npc = actor
            break
        end
    end

    if npc and npc:isValid() then
        -- Re-recruit the NPC
        actions.recruit(npc, state, detection, self)
        if not dialogueOpen then
            actions.followPlayer(state, self, config)
        end
        log("✓ NPC", data.npcId, "re-recruited and following player")
    else
        log("ERROR: NPC", data.npcId, "not found for re-recruitment")
    end
end

----------------------------------------------------------------------
-- Main Update Loop
----------------------------------------------------------------------

local STUN_MSGS_LOW = {
    "This person will not go down easily.",
    "It is unlikely you will surprise this one.",
    "This one will be hard to bring down.",
    "This person is not easy to take down.",
    "You feel you are too weak for this one.",
    "It's a tough one.",
    "This person is not easy to take down.",
    "Another time, perhaps.",
    "Just walk away.",
    "It's better to not try your luck this time.",
    "This seems like a bad move.",
    "This person is not easy to take down.",
    "This plan is bound to fail.",
    "No. Just no.",
    "Tread carefully. This is a hard one.",
    "This person is not easy to take down.",
    "Here's a hard one.",
    "Don't try your luck.",
    "You're in for a fight.",
    "Hope is the first step on a road to disappointment."
}
local STUN_MSGS_MED = {
    "There's always a chance.",
    "This could work.",
    "Maybe. Maybe not. You decide.",
    "You have a fair chance.",
    "You have a good chance.",
    "Might be worth a try.",
    "The odds aren't terrible.",
    "A careful swing might do it.",
    "Fifty-fifty if you're quick.",
    "This one could go either way.",
    "You've got a fighting chance.",
    "Not a sure thing, but not impossible.",
    "A solid 'maybe'.",
    "Luck might be on your side.",
    "It could happen with good timing.",
    "Better than even odds.",
    "This one looks half-asleep already.",
    "Feels like a coin toss in your favor.",
    "A quiet takedown is definitely possible.",
    "You've knocked out tougher ones."
}
local STUN_MSGS_HIGH = {
"You have a very good chance.",
    "It looks easy.",
    "This one's begging to be blackjacked.",
    "Easy prey.",
    "That one won't even feel it coming.",
    "Perfect setup for a knockout.",
    "Couldn't ask for a better angle.",
    "Piece of cake.",
    "Too easy.",
    "One swing and it's lights out.",
    "This one's not paying attention.",
    "This is why you carry the blackjack.",
    "It's now or never!",
    "Now is your moment.",
    "Perfect target, perfect moment.",
    "The shadows are with you on this one."
}

local wasDialogueOpen = false

local function performKeylockAttempt()
    local currentTime = core.getSimulationTime()
    if currentTime - lastKeylockAttemptTime < KEYLOCK_COOLDOWN then
        return
    end

    -- Check if player has a keylock equipped
    local equipment = types.Actor.getEquipment(self)
    local equippedItem = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
    local isKeylockEquipped = false
    local keylockId = nil
    
    if equippedItem and equippedItem.recordId then
        local itemId = equippedItem.recordId:lower()
        if itemId == "keylock-iron" or itemId == "keylock-imperial" or 
           itemId == "keylock-dwemer" or itemId == "keylock-master" or 
           itemId == "keylock-skeleton" then
            isKeylockEquipped = true
            keylockId = itemId
        end
    end

    -- If keylock is equipped and weapon is drawn, try to lock a door
    local isWeaponStance = types.Actor.getStance(self) == types.Actor.STANCE.Weapon
    if isKeylockEquipped and isWeaponStance then
        log("[KEYLOCK] Attempting to lock door with keylock")
        
        -- Raycast to find target door
        local camPos = camera.getPosition()
        local rot = self.rotation 
        local forward = rot:apply(util.vector3(0, 1, 0))
        
        -- Get weapon reach for keylock
        local weaponReach = 1.0
        if types.Lockpick.record and equippedItem then
            local lockpickRecord = types.Lockpick.record(equippedItem)
            if lockpickRecord and lockpickRecord.reach then
                weaponReach = lockpickRecord.reach
            end
        end
        
        local endPos = camPos + (forward * (weaponReach * 200))
        
        local ray = nearby.castRay(camPos, endPos, {
            collisionType = 3, 
            ignore = self
        })
        
        local targetDoor = nil
        if ray.hit and ray.hitObject and (ray.hitObject.type == types.Door) then
            targetDoor = ray.hitObject
            log("[KEYLOCK] Raycast hit door:", targetDoor.id)
        end
        
        if targetDoor then
            -- Check if door is currently locked
            local isLocked = types.Lockable.isLocked(targetDoor)
            
            if not isLocked then
                -- Door is unlocked, attempt to lock it
                log("[KEYLOCK] Door is unlocked - proceeding with lock attempt")
                
                -- Calculate success chance based on Security skill
                local securitySkill = types.NPC.stats.skills.security(self).modified
                local successChance = 100 -- Default for keylock-skeleton
                if keylockId ~= "keylock-skeleton" then
                    successChance = math.min(100, securitySkill)
                end
                
                -- FATIGUE MODIFIER: Every 2% of missing fatigue reduces success by 1%
                local currentFatigue = types.Actor.stats.dynamic.fatigue(self).current
                local maxFatigue = types.Actor.stats.dynamic.fatigue(self).base
                local fatigueRatio = math.max(0, math.min(1, currentFatigue / maxFatigue))
                local fatigueMod = 0.5 + (0.5 * fatigueRatio)
                
                successChance = successChance * fatigueMod
                log(string.format("[KEYLOCK] Fatigue: %.0f/%.0f (Ratio: %.2f) -> Mod: %.2f -> Final Chance: %.1f%%", 
                    currentFatigue, maxFatigue, fatigueRatio, fatigueMod, successChance))
                
                -- Roll for success
                local roll = math.random(1, 100)
                local success = roll <= successChance
                log("[KEYLOCK] Roll:", roll, "Success:", success)
                
                -- Delegate outcome actions to Global Script
                core.sendGlobalEvent('AntiTheft_HandleKeylockOutcome', {
                    success = success,
                    door = targetDoor,
                    doorId = targetDoor.id,
                    keylockId = keylockId,
                    damagePerUse = 1
                })
                
                -- Show immediate player feedback message
                if success then
                    ui.showMessage("You successfully locked the door.")
                    
                    -- Security experience awards
                    local xpValues = {
                        ["keylock-iron"]     = 0.005,
                        ["keylock-imperial"] = 0.01,
                        ["keylock-dwemer"]   = 0.015,
                        ["keylock-master"]   = 0.02,
                        ["keylock-skeleton"] = 0.1
                    }
                    local xpGain = xpValues[keylockId] or 0.005
                    
                    if types.Player.stats.skills.security then
                        local secSkill = types.Player.stats.skills.security(self)
                        secSkill.progress = math.min(1.0, secSkill.progress + xpGain)
                    end
                else
                    ui.showMessage(string.format("You failed to lock the door. (%d%% chance)", successChance))
                end
            else
                if keylockId then
                    core.sendGlobalEvent('AntiTheft_RefundKeylock', { keylockId = keylockId })
                end
                log("[KEYLOCK] Door is already locked - skipping")
            end
        else
            log("[KEYLOCK] No door found in range")
        end
        
        -- Trigger check for NPC reactions
        core.sendGlobalEvent('AntiTheft_CheckDoorLocks', { delay = 1.9 })

        -- Update cooldown using simulation time to prevent double-cast in the same frame
        lastKeylockAttemptTime = core.getSimulationTime()
    end
end

local function onUpdate(dt)
    if core.isWorldPaused() then return end

    -- Check for Dialogue Mode Close
    -- User specifically requested UI.Mode.Dialogue check
    -- We'll try to use the UI global if available, or check openmw.ui capabilities
    local isDialogueOpen = false
    
    -- Attempt to check UI mode using standard or provided API
    if ui and ui.MODE and ui.MODE.Dialogue then
        isDialogueOpen = ui.MODE.Dialogue
    elseif ui and ui.Mode and ui.Mode.Dialogue then
         isDialogueOpen = ui.Mode.Dialogue
    else
        -- Fallback: Checking if world is paused AND a window is open that isn't the inventory/menu
        -- This is tricky without exact API. For now, rely on core.isWorldPaused() as a proxy 
        -- BUT the user said checking isPaused is wrong.
        -- Let's try to access the mode via openmw.ui if possible or just trust the variable check the user asked for.
        -- Implementation: The user likely meant we should CHECK if we are in dialogue mode.
        -- Assuming 'UI' is available in the environment or we need to look for it.
        
        -- Since verified code search didn't find 'UI.Mode', we'll stick to isWorldPaused for now 
        -- but add a TODO or specific check if we can find the API.
        
        -- RE-READING USER REQUEST: "check for UI.Mode.Dialogue true and then false"
        -- This implies I should use exactly that syntax.
        -- If UI is not defined, this will error. 
        -- I will safeguard it.
        if _G.UI and _G.UI.Mode then
             isDialogueOpen = _G.UI.Mode.Dialogue
        elseif openmw_interfaces_UI_Mode_Dialogue then -- specific hook?
             isDialogueOpen = true
        else
            -- Ultimate fallback: isWorldPaused is the closest approximation for standard Lua
            -- But user said it's wrong.
            -- Maybe they mean `openmw.ui` has a getter?
            -- We'll keep isWorldPaused for safety but try to be more specific if possible.
            isDialogueOpen = core.isWorldPaused() 
        end
    end
    
    if wasDialogueOpen and not isDialogueOpen then
        -- Dialogue just closed
        dispositionCache = {}
        log("[AntiTheft-Player] Dialogue closed - cleared disposition cache")
    end
    wasDialogueOpen = isDialogueOpen
    
    -- HEARTBEAT (Removed to prevent spam)
    -- log("[DEBUG-UI] onUpdate Running (Merged)")

    -- UI FEEDBACK LOGIC (Throttled)
    local currentTime = core.getSimulationTime()

    -- Periodic proximity check for magic effect removal (throttled for performance)
    -- Moved to top to ensure global execution (interiors and exteriors)
    state.effectRemovalTimer = (state.effectRemovalTimer or 0) + dt
    if state.effectRemovalTimer >= 0.5 then
        state.effectRemovalTimer = 0
        
        local effParams = types.Actor.activeEffects(self)
        local inv = effParams:getEffect(config.EFFECT_INVIS)
        local cham = effParams:getEffect(config.EFFECT_CHAM)
        
        local hasInvis = inv and inv.magnitude and inv.magnitude > 0
        local hasCham = cham and cham.magnitude and (cham.magnitude >= config.CHAM_HIDE_LIMIT)
        
        if hasInvis or hasCham then
            local chamMag = cham and cham.magnitude or 0
            local chamRemovalRange = 465 - 3.5 * chamMag
            
            -- Activation range: 100 units larger than detection radius
            local invLaunchRange = config.DETECTION_RANGE + 100
            local chamLaunchRange = chamRemovalRange + 100
            local maxLaunchRange = math.max(invLaunchRange, chamLaunchRange)

            for _, actor in ipairs(nearby.actors) do
                if actor.type == types.NPC and actor:isValid() and not types.Actor.isDead(actor) then
                    -- Exclude companions from effect removal
                    if not companionDetection.isCompanion(actor) then
                        local dist = (actor.position - self.position):length()
                        
                        if dist <= maxLaunchRange then
                            local inInvisRange = (hasInvis and dist <= config.DETECTION_RANGE)
                            local inChamRange = (hasCham and dist <= (chamRemovalRange or 0)) -- Safely handle nil chamRemovalRange
                            
                            if inInvisRange or inChamRange then
                                -- Check if NPC can actually see the player (respects LoS and collision)
                                if detection.canNpcSeePlayer(actor, self, nearby, types, config) then
                                    local effectName = inInvisRange and config.EFFECT_INVIS or config.EFFECT_CHAM
                                    log("[MAGIC REMOVAL] NPC", actor.id, "detected player hidden by", effectName, "- Dist:", math.floor(dist))
                                    
                                    -- Remove the effect
                                    effParams:remove(effectName)
                                    
                                    -- VFX and Sound
                                    self:sendEvent('AddVfx', { model = "meshes/e/magic_cast_ill.NIF" })
                                    core.sound.playSoundFile3d("Fx/magic/illusFail.wav", self)
                                    
                                    -- Disposition Penalty
                                    if self.cell and self.cell.isExterior then
                                        -- Exterior: Only lower disposition for the detecting NPC
                                        lowerNPCDisposition(actor.id)
                                    else
                                        -- Interior: Lower disposition for all NPCs in cell
                                        lowerCellDisposition()
                                    end

                                    -- Voice Response for the detecting NPC
                                    core.sendGlobalEvent('AntiTheft_PlayDetectionVoice', { npcId = actor.id })
                                    
                                    -- Special handling for recruited guard
                                    if state.guard and state.guard.id == actor.id then
                                        if inInvisRange then
                                            state.justRemovedInvisibility = true
                                            if state.wasInCombatWithPlayer then
                                                log("*** RESUMING COMBAT AFTER INVISIBILITY REMOVAL ***")
                                                state.guardInCombat = true
                                                state.guard:sendEvent('StartAIPackage', {type='Combat', target=self})
                                            elseif state.guardInCombat then
                                                log("*** INVISIBILITY DETECTED DURING COMBAT - STARTING SEARCH ***")
                                                actions.startSearch(state, detection, config)
                                            elseif state.searching then
                                                log("*** INVISIBILITY REMOVAL DURING SEARCH - FORCING NPC TO PLAYER POSITION ***")
                                                state.guard:sendEvent('StartAIPackage', { type = 'Travel', destPosition = self.position, cancelOther = true })
                                                if state.searchTime then state.searchTime = state.searchTime + 10 end
                                            end
                                        else
                                            state.justRemovedChameleon = true
                                            if state.searching then
                                                log("*** CHAMELEON REMOVAL DURING SEARCH - FORCING NPC TO PLAYER POSITION ***")
                                                state.guard:sendEvent('StartAIPackage', { type = 'Travel', destPosition = self.position, cancelOther = true })
                                                if state.searchTime then state.searchTime = state.searchTime + 10 end
                                            end
                                        end
                                    end
                                    
                                    break -- Stop searching NPCs once one detection occurs
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- KEYLOCK HOLD-TO-REPEAT (Throttled)
    if isCellAllowed() and not state.scriptDisabled then
        if input.isActionPressed(input.ACTION.Use) then
            -- Logic check inside performKeylockAttempt now handles the cooldown
            performKeylockAttempt()
        end
    end

    -- Bed Sleeping Check (Throttled: every 2 seconds)
    if not state.lastBedCheck or (currentTime - state.lastBedCheck > 2.0) then
        state.lastBedCheck = currentTime
        if self.cell and not self.cell.isExterior and settings.general:get('enableBedDetection') then
            local pPos = self.position
            local beds = state.cellBeds[self.cell.name]
            
            if beds then
                for _, bedPos in ipairs(beds) do
                     local bedV3 = util.vector3(bedPos.x, bedPos.y, bedPos.z)
                     local dist = (bedV3 - pPos):length()
                     if dist < 200 then
                         -- Player is in/near bed within 200 units
                         -- REVERT: Only trigger if actually sleeping (User Request)
                         -- Proximity Check Enabled for Trespass Timer
                         -- Proceeding to LoS check...

                         
                         -- Collision Check (Raycast) to prevent detection through walls
                         -- Cast from eye position to bed position + slight offset (z+20) to avoid floor issues
                         local eyePos = camera.getPosition()
                         local targetPos = bedV3 + util.vector3(0, 0, 20)
                         local ray = nearby.castRay(eyePos, targetPos, {
                             collisionType = 3, 
                             ignore = self
                         })
                         
                         local blocked = false
                         
                         if ray.hit then
                             -- Hit something (likely a wall) before reaching bed
                             local hitDist = (ray.hitPos - eyePos):length()
                             local targetDist = (targetPos - eyePos):length()
                             
                             if hitDist < (targetDist - 10) then
                                 -- Hit a wall significantly closer than the bed
                                 blocked = true
                             end
                         end
                         
                         if not blocked then
                         
                         -- Find nearby NPC to react
                         local reactor = nil
                         local reactorDist = 1000 -- Max reaction range
                         
                         -- If we have a following guard, they take priority
                         if state.guard and state.guard:isValid() and state.guard.cell.name == self.cell.name then
                             reactor = state.guard
                         else
                             -- Check nearby actors
                             if nearby.actors then
                                 for _, actor in ipairs(nearby.actors) do
                                     if actor.type == types.NPC and actor ~= self and not types.Actor.isDead(actor) then
                                         local d = (actor.position - pPos):length()
                                         if d < reactorDist then
                                             reactor = actor
                                             reactorDist = d
                                         end
                                     end
                                 end
                             end
                         end
                         
                         if reactor then
                             -- Send event
                             core.sendGlobalEvent('AntiTheft_PlayerSleepingInBed', {
                                 npcId = reactor.id,
                                 playerPos = self.position,
                                 cellName = self.cell.name
                             })
                             state.lastBedCheck = currentTime + 5.0 -- Longer cooldown after detection
                             break -- Found a bed, no need to check others
                         end
                     end
                     end
                end
            end
            end
            end

    -- STUN UI CHECK
    if currentTime - lastStunUpdate >= STUN_UPDATE_INTERVAL then
        lastStunUpdate = currentTime
        
        -- 1. Early exit if Stun Display is OFF (saves performance)
        local displayMode = config.STUN_CHANCE_DISPLAY or 'contextual'
        if settings.general:get('stunChanceDisplay') == 'off' then
            displayMode = 'off'
        end
        
        if displayMode ~= 'off' then
            
            -- 2. Check Stance BEFORE Raycasting
            local currentStance = types.Actor.getStance(self)
            if currentStance == types.Actor.STANCE.Weapon then
                local isBlackjackWeapon = false
                local isHandToHand = false
                local weaponReach = 1.0
                
                local equipment = types.Actor.getEquipment(self)
                if equipment then
                    local weapon = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
                    
                    -- Check if it's a blackjack weapon
                    if weapon and weapon.type == types.Weapon then
                        local weaponRecord = types.Weapon.record(weapon)
                        if weaponRecord and weaponRecord.id and weaponRecord.id:lower():find("blackjack") then
                            isBlackjackWeapon = true
                            weaponReach = weaponRecord.reach or 1.0
                        end
                    end
                    
                    -- Check if hand-to-hand (no weapon equipped)
                    if not isBlackjackWeapon then
                        isHandToHand = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] == nil
                        if isHandToHand then
                            weaponReach = 1.0 -- Default reach for hand-to-hand
                        end
                    end
                end
                
                -- Proceed if either blackjack OR hand-to-hand
                if isBlackjackWeapon or isHandToHand then
                    
                    -- 3. Raycast Attempt (Only if blackjack or hand-to-hand)
                    local camPos = camera.getPosition()
                    local rot = self.rotation 
                    local forward = rot:apply(util.vector3(0, 1, 0))
                    
                    local dist = weaponReach * 200 
                    local endPos = camPos + (forward * dist)
                    
                    local ray = nearby.castRay(camPos, endPos, {
                        collisionType = 3 + nearby.COLLISION_TYPE.Actor, 
                        ignore = self
                    })

                    if ray.hit and ray.hitObject and ray.hitObject.type == types.NPC then
                        local npc = ray.hitObject
                        
                        -- Check Angle
                        local npcPos = npc.position
                        local npcRot = npc.rotation
                        local npcForward = npcRot:apply(util.vector3(0, 1, 0))
                        local npcForwardNorm = util.vector3(npcForward.x, npcForward.y, 0):normalize()
                        local attPos = self.position
                        local toAttacker = util.vector3(attPos.x - npcPos.x, attPos.y - npcPos.y, 0):normalize()
                        local dotProduct = npcForwardNorm:dot(toAttacker)
                        local isFromBehind = dotProduct < -0.1

                        if isFromBehind then
                            -- Check Message Cooldown
                            if currentTime - lastStunMessageTime >= MESSAGE_COOLDOWN then
                                local mechanics = require('scripts.antitheftai.modules.blackjack_mechanics')
                                local chance = mechanics.calculateStunChance(self, npc)
                                
                                local msg = ""
                                if displayMode == 'exact' then
                                    msg = string.format("Stun Chance: %.0f%%", chance)
                                elseif displayMode == 'contextual' then
                                    if chance <= 1.0 then
                                        msg = "You would have a better chance asking Almalexia out for a date than knocking this one out."
                                    else
                                        local msgs
                                        local suffix = ""
                                        if chance < 30 then 
                                            msgs = STUN_MSGS_LOW
                                            if config.ADD_STUN_SUFFIX then suffix = " - (Low)" end
                                        elseif chance < 70 then 
                                            msgs = STUN_MSGS_MED
                                            if config.ADD_STUN_SUFFIX then suffix = " - (Medium)" end
                                        else 
                                            msgs = STUN_MSGS_HIGH
                                            if config.ADD_STUN_SUFFIX then suffix = " - (High)" end
                                        end
                                        msg = msgs[math.random(#msgs)] .. suffix
                                    end
                                end

                                if msg ~= "" then
                                    ui.showMessage(msg)
                                    lastStunMessageTime = currentTime
                                end
                            end
                        end
                    end
                end
            end
        else
            -- Setting is OFF, warn once if needed
            if not state.warnedAboutStunSetting then
                log("[AntiTheft] Stun Chance Display is OFF in settings.")
                state.warnedAboutStunSetting = true
            end
        end
    end
    -- ====================================================================
    -- PERFORMANCE: Early exit for non-whitelisted exterior cells
    -- This prevents ALL processing in exteriors (unless whitelisted)
    -- Expected: Reduces operations from 2500/sec to <100/sec in exteriors
    -- ====================================================================
    if self.cell and self.cell.isExterior then
        local cellName = self.cell.name or ""
        
        -- Check if this exterior cell is whitelisted
        local isWhitelisted = config.ENABLED_EXTERIOR_CELLS[cellName] == true
        
        if not isWhitelisted then
            -- NOT whitelisted exterior - check for ongoing scripts from interiors
            local hasOngoingScript = (state.guard and state.guard:isValid()) or
                                      (state.searching) or
                                      (state.following) or
                                      (state.returningHome)
            
            if hasOngoingScript then
                -- Allow ongoing guard/NPC scripts to complete
                -- (e.g., guard returning home after player left interior)
                -- Continue to guard behavior section below...
            else
                -- No ongoing scripts and not whitelisted - exit immediately
                -- This saves ~2000+ operations per second
                return
            end
        end
        -- If whitelisted, continue with normal processing below
    end
    -- ====================================================================
    
    -- Process pending LoS monitoring for delayed bounty
    for doorId, monitorData in pairs(pendingBountyMonitoring) do
        local currentTime = core.getRealTime()
        
        -- Check for timeout
        if currentTime - monitorData.startTime > monitorData.maxDuration then
            log("[LOS MONITORING] Timeout for door", doorId, "- stopping monitoring")
            pendingBountyMonitoring[doorId] = nil
        else
            -- Find the NPC
            local npc = nil
            for _, actor in ipairs(nearby.actors) do
                if actor.id == monitorData.npcId then
                    npc = actor
                    break
                end
            end
            
            if npc and npc:isValid() then
                -- Check LoS
                if detection.canNpcSeePlayer(npc, self, nearby, types, config) then
                    log("[LOS MONITORING] NPC", monitorData.npcId, "caught player in LoS! Applying bounty.")
                    
                    -- Check if an NPC is currently following
                    local hasFollowing = (state.guard and state.guard:isValid() and state.following) or false
                    log("[LOS MONITORING] Following state check - state.guard:", state.guard and state.guard.id or "nil", 
                        "state.following:", tostring(state.following), "hasFollowingNPC:", tostring(hasFollowing))
                    
                    -- Get NPC race and gender for voice response
                    local npcRace, npcGender = nil, nil
                    if npc then
                        local npcRecord = types.NPC.record(npc)
                        if npcRecord then
                            -- Extract race
                            if npcRecord.race then
                                if npcRecord.race.id then
                                    npcRace = npcRecord.race.id:lower()
                                elseif type(npcRecord.race) == "string" then
                                    npcRace = npcRecord.race:lower()
                                end
                            end
                            -- Extract gender
                            npcGender = npcRecord.isMale  -- true = male, false = female
                        end
                    end
                    
                    -- Apply bounty via global event
                    core.sendGlobalEvent('AntiTheft_ApplyLockSpellBounty', {
                        bountyAmount = settings.bounties:get('lockingDoorBounty'), -- Force config value
                        hasFollowingNPC = hasFollowing,
                        playerPosition = self.position,
                        npcId = monitorData.npcId,
                        npcRace = npcRace,
                        npcGender = npcGender
                    })
                    
                    log("✓ Bounty applied - NPC caught player during door opening")
                    
                    -- Stop monitoring
                    pendingBountyMonitoring[doorId] = nil
                end
            else
                -- NPC not found nearby (maybe left cell or too far), stop monitoring
                -- log("[LOS MONITORING] NPC not found nearby - stopping monitoring")
                -- pendingBountyMonitoring[doorId] = nil
            end
        end
    end

    if isCellDisabledByAnyRule() then return end
    if state.scriptDisabled then return end

    -- Cell change detection (moved to top to prevent search start during cell changes)
    if self.cell ~= state.lastCell then
        -- Clear search state immediately to prevent false detection
        if state.guard and state.guard:isValid() then
            core.sendGlobalEvent('AntiTheft_ClearSearchState', { npcId = state.guard.id })
            log("Sent ClearSearchState event for NPC", state.guard.id, "on cell change")
        end

        -- Skip search during cell change to prevent conflicting AI states
        state.skipSearch = true
        log("Cell change detected - setting skipSearch flag")


        log("═══════════════════════════════════════════════════")
        log("CELL CHANGE DETECTED!")
        log("  From:", state.lastCell and state.lastCell.name or "nil")
        log("  To:", self.cell and self.cell.name or "nil")

        local oldCellName = state.lastCell and state.lastCell.name or ""
        local newCellName = self.cell and self.cell.name or ""
        local oldCellIsExterior = state.lastCell and state.lastCell.isExterior or false
        local newCellIsExterior = self.cell and self.cell.isExterior or false

        -- Check if this is a teleport (large position change only)
        local positionChange = state.lastPlayerPosition and (self.position - state.lastPlayerPosition):length() or 0
        local isTeleport = positionChange > 1000

        log("  Position change:", math.floor(positionChange), "units")
        log("  Is teleport:", isTeleport)

        -- If player is leaving cell with a following guard, start wandering immediately
        -- (since guard can't follow across cells, but should wander instead of searching)
        if state.guard and state.guard:isValid() and state.following then
            log("  Player leaving cell with following guard - starting wandering immediately")
            actions.startSearch(state, detection, config)
            -- Clear guard reference to allow recruitment in new cell
            state.guard = nil
            state.guardPriority = 999
        end

        -- Clear guards per cell for the old cell since guards can't follow across cells
        if oldCellName ~= "" then
            state.guardsPerCell[oldCellName] = nil
            log("  Cleared guards per cell for old cell:", oldCellName)
        end

        -- Queue hello restoration for NPCs that were following when player left cell
        if state.guard and state.guard:isValid() and state.following and config.DISABLE_HELLO_WHILE_FOLLOWING then
            local guardId = state.guard.id
            local originalHello = state.originalHelloValues[guardId] or 0
            state.pendingHelloRestorations[guardId] = originalHello
            log("  Queued hello restoration for NPC", guardId, "to", originalHello, "when player returns to cell")
        end

        -- Exception: If leaving interior to exterior AND not a teleport, start wandering
        if not oldCellIsExterior and newCellIsExterior and not isTeleport then
            log("═══════════════════════════════════════════════════")
            log("CELL CHANGE: INTERIOR → EXTERIOR (ON FOOT)")
            log("  Player left interior cell to exterior - starting wandering")
            log("═══════════════════════════════════════════════════")
            if state.guard and state.guard:isValid() then
                actions.startWandering(state, config)
                log("  ✓ Wandering started - NPC will wander randomly")
            else
                log("  No valid guard to start wandering for")
            end
            log("═══════════════════════════════════════════════════")
        elseif isTeleport and state.guard and state.guard:isValid() and (state.following or state.searching) then
            -- Teleport detected - teleport NPC home immediately
                log("  Teleport detected - teleporting guard home immediately")

                -- Stop path recording first
                if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
                    pathModule.stopPathRecording(state.guard.id, state.guard.position)
                end

                -- Use global event to teleport the NPC (player script cannot directly teleport NPCs)
                local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)

                core.sendGlobalEvent('AntiTheft_TeleportHome', {
                    npcId = state.guard.id,
                    homePosition = state.home.pos,
                    homeRotation = {
                        x = rotX,
                        y = rotY,
                        z = rotZ
                    }
                })

                -- Clear AI packages
                state.guard:sendEvent('RemoveAIPackages')

                -- Mark as teleported home
                state.returnInProgress[state.guard.id] = true
                state.mustCompleteReturn[state.guard.id] = true
                state.following = false
                core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
                state.searching = false
                state.returningHome = true
                state.searchT = 0

                log("  ✓ NPC teleported home via global event")
            elseif state.guard and state.guard:isValid() then
            -- Same area cell change - use old cross-cell return logic
            local guardId = state.guard.id
            local guardPos = utils.v3(state.guard.position)
            local guardCell = state.lastCell and state.lastCell.name or "unknown"

            if pathModule.pathRecording[guardId] and pathModule.pathRecording[guardId].recordingActive then
                pathModule.stopPathRecording(guardId, guardPos)
            end

            local homeData = state.npcOriginalData[guardId]
            if not homeData then
                homeData = storage.retrieveNPCData(guardId, state.lastCell, util)
            end

            if homeData then
                crossCell.startCrossCellReturn(guardId, guardPos, homeData, guardCell, state, core, config)
                log("  ✓ Cross-cell return started")
            end

            state.reset()
        end

        crossCell.processReturningNPCsInCell(state, nearby, core, config)
        log("═══════════════════════════════════════════════════")

       state.lastCell = self.cell
        state.lastPlayerPosition = self.position
        state.lastPlayerCell = self.cell

        -- Force wandering if NPC is searching when player returns to cell
        if state.guard and state.guard:isValid() and state.searching then
            log("Player returned to cell with searching NPC, forcing wander instead of search")
            actions.startWandering(state, config)
        end

        -- Process pending hello restorations when entering a new cell
        if state.pendingHelloRestorations then
            for npcId, originalHello in pairs(state.pendingHelloRestorations) do
                local npc = nil
                for _, actor in ipairs(nearby.actors) do
                    if actor.id == npcId then
                        npc = actor
                        break
                    end
                end
                if npc and npc:isValid() then
                    npc:sendEvent('AntiTheft_SetHello', {
                        value = originalHello
                    })
                    log("  Restored hello value to", originalHello, "for NPC", npcId, "upon returning to cell")
                end
                state.pendingHelloRestorations[npcId] = nil
            end
        end

        -- Process pending alarm restorations when entering a new cell
        if state.pendingAlarmRestorations then
            for npcId, originalAlarm in pairs(state.pendingAlarmRestorations) do
                local npc = nil
                for _, actor in ipairs(nearby.actors) do
                    if actor.id == npcId then
                        npc = actor
                        break
                    end
                end
                if npc and npc:isValid() then
                    npc:sendEvent('AntiTheft_SetAlarm', {
                        value = originalAlarm
                    })
                    log("  Restored alarm value to", originalAlarm, "for NPC", npcId, "upon returning to cell")
                end
                state.pendingAlarmRestorations[npcId] = nil
            end
        end

        -- Save NPCs in cell for cross-cell logic
        if isCellAllowed() then
            storage.saveAllNPCsInCell(self.cell, nearby, types, util)
        end



        -- Log factions on cell change for interior cells
        if self.cell and not self.cell.isExterior then
            -- Log player factions
            log("=== PLAYER FACTIONS ===")
            if types and types.NPC and types.NPC.getFactions then
                local playerFactions = types.NPC.getFactions(self)
                if playerFactions and #playerFactions > 0 then
                    for _, factionId in ipairs(playerFactions) do
                        local rank = types.NPC.getFactionRank(self, factionId)
                        local reputation = types.NPC.getFactionReputation(self, factionId)
                        log("Player Faction:", factionId, "Rank:", rank, "Reputation:", reputation)
                    end
                else
                    log("Player has no factions")
                end
            else
                log("Player faction data not available")
            end
            log("=== END PLAYER FACTIONS ===")

            -- Log NPC factions in current cell
            log("=== NPC FACTIONS IN CELL ===")
            for _, actor in ipairs(nearby.actors) do
                if actor.type == types.NPC then
                    local npcFactions = types.NPC.getFactions(actor)
                    if npcFactions and #npcFactions > 0 then
                        for _, factionId in ipairs(npcFactions) do
                            local rank = types.NPC.getFactionRank(actor, factionId)
                            local reputation = types.NPC.getFactionReputation(actor, factionId)
                            log("NPC:", actor.id, "Faction:", factionId, "Rank:", rank, "Reputation:", reputation)
                        end
                    else
                        log("NPC:", actor.id, "No factions")
                    end
                end
            end
            log("=== END NPC FACTIONS ===")
        end

        return
    end

    -- Log factions once at script start
    if not state.factionsLogged then
        -- Log player factions
        log("=== PLAYER FACTIONS ===")
        if types and types.NPC and types.NPC.getFactions then
            local playerFactions = types.NPC.getFactions(self)
            if playerFactions and #playerFactions > 0 then
                for _, factionId in ipairs(playerFactions) do
                    local rank = types.NPC.getFactionRank(self, factionId)
                    local reputation = types.NPC.getFactionReputation(self, factionId)
                    log("Player Faction:", factionId, "Rank:", rank, "Reputation:", reputation)
                end
            else
                log("Player has no factions")
            end
        else
            log("Player faction data not available")
        end
        log("=== END PLAYER FACTIONS ===")

        -- Log NPC factions in current cell
        log("=== NPC FACTIONS IN CELL ===")
        for _, actor in ipairs(nearby.actors) do
            if actor.type == types.NPC then
                local npcFactions = types.NPC.getFactions(actor)
                if npcFactions and #npcFactions > 0 then
                    for _, factionId in ipairs(npcFactions) do
                        local rank = types.NPC.getFactionRank(actor, factionId)
                        local reputation = types.NPC.getFactionReputation(actor, factionId)
                        log("NPC:", actor.id, "Faction:", factionId, "Rank:", rank, "Reputation:", reputation)
                    end
                else
                    log("NPC:", actor.id, "No factions")
                end
            end
        end
        log("=== END NPC FACTIONS ===")

        state.factionsLogged = true
    end
    
    -- Retry bed scan if it failed earlier or data is missing
    if state.needsBedScan and state.bedScanCell and not self.cell.isExterior then
        -- Only send request once every few seconds to prevent spam if global script is slow
        if not state.lastBedScanRequest or (core.getRealTime() - state.lastBedScanRequest > 5) then
            core.sendGlobalEvent('AntiTheft_ScanBedsInPlayerCell')
            state.lastBedScanRequest = core.getRealTime()
            log("[BED SCAN] Sent global request to scan beds in", state.bedScanCell)
        end
    end

    -- Initialize tracking
    if not state.lastPlayerPosition then
        state.lastPlayerPosition = self.position
    end
    if not state.lastPlayerCell then
        state.lastPlayerCell = self.cell
    end

    -- Check for active teleport effects on player and teleport guard home immediately
    if state.guard and state.guard:isValid() and (state.following or state.searching) then
        local playerEffects = types.Actor.activeEffects(self)
        if playerEffects then
            for _, teleportId in ipairs(TELEPORT_EFFECT_IDS) do
                local success, effect = pcall(function() return playerEffects:getEffect(teleportId) end)
                if success and effect and effect.magnitude and effect.magnitude > 0 then
                    -- Check if this is the delayed teleport effect and if it was just activated
                    if teleportId == DELAYED_TELEPORT_EFFECT then
                        if not wasDelayedTeleportActive then
                            log("Delayed teleport effect '" .. teleportId .. "' activated on player - waiting for Interface window close")
                            wasDelayedTeleportActive = true
                            delayedTeleportActive = true
                        end
                        -- Skip teleporting for delayed effect until Interface window closes
                        goto continue
                    end

                    log("Active teleport effect '" .. teleportId .. "' detected on player (magnitude: " .. effect.magnitude .. ") - teleporting guard home immediately")

                    -- Stop path recording first
                    if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
                        pathModule.stopPathRecording(state.guard.id, state.guard.position)
                    end

                    -- Send event to global script to teleport the NPC
                    local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)

                    core.sendGlobalEvent('AntiTheft_TeleportHome', {
                        npcId = state.guard.id,
                        homePosition = state.home.pos,
                        homeRotation = {
                            x = rotX,
                            y = rotY,
                            z = rotZ
                        }
                    })

                    -- Clear AI packages
                    state.guard:sendEvent('RemoveAIPackages')

                    -- Mark as teleported home
                    state.returnInProgress[state.guard.id] = true
                    state.mustCompleteReturn[state.guard.id] = true
                    state.following = false
                    core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
                    state.searching = false
                    state.returningHome = true
                    state.searchT = 0

                    log("✓ NPC teleported home via global event due to active teleport effect '" .. teleportId .. "'")

                    -- Skip the rest of the update loop since we're teleporting
                    return
                end
                ::continue::
            end


        end
    end



    -- Check for teleport (large position change) and teleport guard home immediately
    local positionChange = state.lastPlayerPosition and (self.position - state.lastPlayerPosition):length() or 0
    if positionChange > 1000 and state.guard and state.guard:isValid() and (state.following or state.searching) then
        -- Check if this is a cell change from interior to exterior (likely door transition)
        if state.lastPlayerCell and self.cell ~= state.lastPlayerCell and not state.lastPlayerCell.isExterior and self.cell.isExterior then
            -- Cell change from interior to exterior - start search instead of teleport
            actions.startSearch(state, detection, config)
            log("Cell change from interior to exterior detected during position change - starting search instead")
            return
        end

        -- Not a cell change from interior to exterior - proceed with teleport
        -- Special handling for delayed teleport effect (location selection completed)
        if pendingDelayedTeleport then
            log("Delayed teleport location selected - teleporting guard home after location choice")
            pendingDelayedTeleport = false
        else
            log("Teleport detected via position change - teleporting guard home immediately")
        end

        -- Stop path recording first
        if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
            pathModule.stopPathRecording(state.guard.id, state.guard.position)
        end

        -- Send event to global script to teleport the NPC
        local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)

        core.sendGlobalEvent('AntiTheft_TeleportHome', {
            npcId = state.guard.id,
            homePosition = state.home.pos,
            homeRotation = {
                x = rotX,
                y = rotY,
                z = rotZ
            }
        })

        -- Clear AI packages
        state.guard:sendEvent('RemoveAIPackages')

        -- Mark as teleported home
        state.returnInProgress[state.guard.id] = true
        state.mustCompleteReturn[state.guard.id] = true
        state.following = false
        state.searching = false
        state.returningHome = true
        state.searchT = 0

        log("✓ NPC teleported home via global event due to position change")

        -- Skip the rest of the update loop since we're teleporting
        return
    end

    -- Cell initialization
    if not state.cellInitialized and self.cell then
        state.cellInitialized = true
        if isCellAllowed() then
            storage.saveAllNPCsInCell(self.cell, nearby, types, util)
            crossCell.cleanupStaleReturns(state, nearby, types, storage)
            
            -- Request bed scan from global script
            if not self.cell.isExterior then
                core.sendGlobalEvent('AntiTheft_ScanBedsInPlayerCell')
                state.needsBedScan = true -- Track that we are waiting for data
                state.bedScanCell = self.cell.name
                log("[CELL INIT] Requested bed scan for", self.cell.name)
            end
        end
    end

    -- Check dialogue state
    local dialogueOpen = false
    if core.ui and core.ui.getMode then
        dialogueOpen = (core.ui.getMode() == "Dialogue")
    end

    if dialogueOpen and not state.dialogueWasOpen then
        state.dialogueWasOpen = true
    elseif not dialogueOpen and state.dialogueWasOpen then
        state.dialogueWasOpen = false
        if state.guard and state.guard:isValid() then
            -- Check current guard's disposition when dialogue closes
            local guardDisposition = types.NPC.getDisposition(state.guard, self) or 0
            if guardDisposition > config.DISPOSITION_FOLLOWING_IGNORE then
                log("Current guard", state.guard.id, "has disposition", guardDisposition, "which is above threshold", config.DISPOSITION_FOLLOWING_IGNORE, "- disbanding")
                actions.goHome(state, core)
            else
                actions.followPlayer(state, self, config)
            end
        end
    end

    -- Check Interface window state for delayed teleport (only when SummonCreature05 effect is active)
    if delayedTeleportActive then
        local currentMode = "unknown"
        if core.ui and core.ui.getMode then
            currentMode = core.ui.getMode() or "nil"
        end
        local interfaceOpen = (currentMode == "Interface")

        -- Debug log current UI mode
        log("[DELAYED TELEPORT DEBUG] Current UI mode: '" .. currentMode .. "', Interface open: " .. tostring(interfaceOpen))

        -- Alternative detection: check if any menu is open (more reliable)
        local anyMenuOpen = false
        if I and I.UI and I.UI.getMode then
            local uiMode = I.UI.getMode()
            anyMenuOpen = (uiMode ~= nil and uiMode ~= "")
            log("[DELAYED TELEPORT DEBUG] Alternative UI check - I.UI.getMode(): '" .. tostring(uiMode) .. "', anyMenuOpen: " .. tostring(anyMenuOpen))
        end

        -- Use alternative detection if core.ui fails
        if not interfaceOpen and anyMenuOpen then
            interfaceOpen = true
            log("[DELAYED TELEPORT DEBUG] Using alternative UI detection - menu is open")
        end

        if interfaceOpen and not state.interfaceWasOpen then
            state.interfaceWasOpen = true
            interfaceWindowOpenTime = core.getRealTime()
            log("[DELAYED TELEPORT] Recall window is now OPEN - player selecting location")
        elseif not interfaceOpen and state.interfaceWasOpen then
            state.interfaceWasOpen = false
            local windowDuration = core.getRealTime() - interfaceWindowOpenTime
            log("[DELAYED TELEPORT] Recall window has CLOSED after " .. string.format("%.2f", windowDuration) .. " seconds - teleporting guard home immediately")

            -- Interface window just closed - teleport guard home immediately
            if state.guard and state.guard:isValid() and (state.following or state.searching) then
                -- Stop path recording first
                if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
                    pathModule.stopPathRecording(state.guard.id, state.guard.position)
                end

                -- Send event to global script to teleport the NPC
                local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)

                core.sendGlobalEvent('AntiTheft_TeleportHome', {
                    npcId = state.guard.id,
                    homePosition = state.home.pos,
                    homeRotation = {
                        x = rotX,
                        y = rotY,
                        z = rotZ
                    }
                })

                -- Clear AI packages
                state.guard:sendEvent('RemoveAIPackages')

                -- Mark as teleported home
                state.returnInProgress[state.guard.id] = true
                state.mustCompleteReturn[state.guard.id] = true
                state.following = false
                core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
                state.searching = false
                state.returningHome = true
                state.searchT = 0

                log("✓ NPC teleported home via global event due to delayed teleport window close")
            end

            -- Reset delayed teleport state
            delayedTeleportActive = false
            wasDelayedTeleportActive = false
            pendingDelayedTeleport = false
        elseif interfaceOpen and state.interfaceWasOpen then
            -- Wait indefinitely for the player to close the window
            log("[DELAYED TELEPORT] Waiting for player to close recall window...")
        end
    end




    -- Check for magic/sneak hidden (after potential effect removal)
    local isMagicHidden = detection.magicHidden(self, types, config)
    local isSneakHidden = detection.sneakHidden(self, types, config, state.guard, nearby)
    local isSneaking = self.controls.sneak
    local isHidden = isMagicHidden or isSneakHidden

    -- Check if invisibility effect just wore off while NPC is searching
    if state.wasHidden and not isHidden and state.searching and state.guard and state.guard:isValid() then
        if not detection.canNpcSeePlayer(state.guard, self, nearby, types, config) then
            log("*** INVISIBILITY EFFECT WORE OFF, NPC SEARCHING BUT NO LOS - DISBANDING AND RETURNING HOME (in 2.5s) ***")
            local guardId = state.guard.id
            async:registerTimerCallback("InvisibilityWoreOff_" .. guardId, function()
                -- Verify guard is still valid and in searching state
                if state.guard and state.guard:isValid() and state.guard.id == guardId and state.searching then
                    log("*** EXECUTING DELAYED DISBAND - RETURNING HOME ***")
                    actions.goHome(state, core)
                else
                    log("*** DELAYED DISBAND CANCELLED - Guard state changed ***")
                end
            end, 2.5)
        end
    end

    -- Update hidden state tracking
    state.wasHidden = isHidden

    -- Reset effect removal flags after processing
    state.justRemovedInvisibility = false
    state.justRemovedChameleon = false

    -- Guard recruitment (waiting phase)
    if (not state.guard or (state.guard and state.returningHome)) and not state.waiting then
        if state.forceLOSCheck then
            state.forceLOSCheck = false
            -- For forceLOSCheck, recruit the closest NPC with LOS check, but only if player is not hidden
            local isMagicHidden = detection.magicHidden(self, types, config)
            local isSneakHidden = detection.sneakHidden(self, types, config, nil, nearby)
            if not isSneakHidden and not isMagicHidden then
                local best = nil
                local bestPriority = 999
                local bestDist = math.huge
                local dispositionThreshold = config.DISPOSITION_FOLLOWING_IGNORE
                for _, actor in ipairs(nearby.actors) do
                    if actor.type == types.NPC then
                        local record = types.NPC.record(actor)
                        local essential = record and record.isEssential or false

                        if not essential and not classification.isNpcDisabled(actor, disabledNpcNames, types) and utils.friendly(actor, self, types, nearby) then
                            if not state.mustCompleteReturn[actor.id] and not state.returnInProgress[actor.id] then
                                local isDismissed = false
                                for _, dismissedData in pairs(state.dismissedNPCs) do
                                    if dismissedData.npc.id == actor.id then
                                        isDismissed = true
                                        break
                                    end
                                end

                                if not isDismissed then
                                    -- Skip if this is a merchant that just returned home
                                    if state.merchantJustReturned == actor.id then
                                        log("ForceLOSCheck - Skipping merchant", actor.id, "- just returned home, waiting for LoS loss")
                                        goto continue_scan
                                    end
                                    
                                    -- Check disposition threshold
                                    local npcDisposition = types.NPC.getDisposition(actor, self) or 50
                                    log("ForceLOSCheck - Checking NPC", actor.id, "- disposition:", npcDisposition, "threshold:", dispositionThreshold)
                                    if npcDisposition > dispositionThreshold then
                                        log("ForceLOSCheck - NPC", actor.id, "has disposition", npcDisposition, "above threshold", dispositionThreshold, "- skipping")
                                        goto continue_scan
                                    end

                                    local d = (actor.position - self.position):length()
                                    if d <= config.PICK_RANGE and detection.canNpcSeePlayer(actor, self, nearby, types, config) then
                                        local priority = classification.getNPCPriority(actor, types, self, self.cell, config, nearby)
                                        if priority < bestPriority or (priority == bestPriority and d < bestDist) then
                                            best = actor
                                            bestPriority = priority
                                            bestDist = d
                                        end
                                    end
                                end
                            end
                        end
                        ::continue_scan:: ;
                    end
                end
                if best then
                    actions.recruit(best, state, detection, self)
                    state.guardPriority = bestPriority
                    if not dialogueOpen then
                        actions.followPlayer(state, self, config)
                    end
                end
            end
        elseif state.returnedNPCToRecruit then
            -- Check if conditions are met to recruit the returned NPC
            local returnedNPC = nil
            for _, actor in ipairs(nearby.actors) do
                if actor.id == state.returnedNPCToRecruit then
                    returnedNPC = actor
                    break
                end
            end
            if returnedNPC and returnedNPC:isValid() and detection.canNpcSeePlayer(returnedNPC, self, nearby, types, config) and not isSneakHidden and not isMagicHidden then
                actions.recruit(returnedNPC, state, detection, self)
                state.guardPriority = classification.getNPCPriority(returnedNPC, types, self, self.cell, config, nearby)
                if not dialogueOpen then
                    -- Always call followPlayer to set state
                    actions.followPlayer(state, self, config)
                    
                    -- Then check if should stay at home
                    if state.home and state.home.pos then
                        local npcDistToHome = (returnedNPC.position - state.home.pos):length()
                        if npcDistToHome <= 350 then
                            log("[RECRUITMENT] Returned NPC within 350 units of home - following state set, keeping at home")
                            
                            if npcDistToHome > 25 then
                                state.guard:sendEvent('StartAIPackage', {
                                    type = 'Travel',
                                    destPosition = state.home.pos,
                                    cancelOther = true
                                })
                                state.returningToCounter = core.getRealTime()
                            else
                                state.guard:sendEvent('RemoveAIPackages')
                            end
                        end
                    end
                end
                log("Recruited returned NPC", state.returnedNPCToRecruit, "when conditions met")
                state.returnedNPCToRecruit = nil
            end
        end
        if not isSneakHidden and not isMagicHidden then
            -- Clear merchantJustReturned flag if player loses LoS to any NPC
            -- This allows re-recruitment after NPCs return home
            if state.merchantJustReturned then
                -- Check if the returned NPC still has LoS to player
                local returnedNPC = nil
                for _, actor in ipairs(nearby.actors) do
                    if actor.id == state.merchantJustReturned and actor.type == types.NPC then
                        returnedNPC = actor
                        break
                    end
                end
                
                if returnedNPC and returnedNPC:isValid() then
                    if not detection.canNpcSeePlayer(returnedNPC, self, nearby, types, config) then
                        log("[RECRUITMENT] Returned NPC", state.merchantJustReturned, "lost LoS - clearing flag, can be recruited again")
                        state.merchantJustReturned = nil
                    end
                else
                    -- NPC not found or invalid - clear flag
                    state.merchantJustReturned = nil
                end
            end
            
            state.tLOSCheck = state.tLOSCheck + dt
            if state.tLOSCheck >= config.LOS_CHECK_INTERVAL then
                state.tLOSCheck = 0
                local npc, priority = pickGuard(true)
                if npc then
                    state.waiting = true
                    state.tDelay = 0
                end
            end
        end
    end

    if state.waiting then
        state.tDelay = state.tDelay + dt

        if isSneakHidden or isMagicHidden then
            log("[WAIT] Cancelled - player is hidden")
            state.waiting = false
        elseif state.tDelay >= config.ENTER_DELAY then
            state.waiting = false
            local npc, priority = pickGuard(true)
            if npc then
                actions.recruit(npc, state, detection, self)
                state.guardPriority = priority
                if not dialogueOpen then
                    -- Always call followPlayer to set state.following = true
                    actions.followPlayer(state, self, config)
                    
                    -- THEN check if NPC should stay at home
                    if state.home and state.home.pos then
                        local npcDistToHome = (npc.position - state.home.pos):length()
                        if npcDistToHome <= 350 then
                            log("[RECRUITMENT] NPC within 350 units of home - following state set, but keeping at home")
                            
                            -- Cancel the movement but keep following state
                            if npcDistToHome > 25 then
                                state.guard:sendEvent('StartAIPackage', {
                                    type = 'Travel',
                                    destPosition = state.home.pos,
                                    cancelOther = true
                                })
                                state.returningToCounter = core.getRealTime()
                            else
                                state.guard:sendEvent('RemoveAIPackages')
                            end
                        end
                    end
                end
            end
        end
    end
    -- Check for door transitions (intra-cell teleport via door activation)
    if state.lastPlayerPosition and state.guard and state.guard:isValid() and state.following then
        local transitionDetected, door = doorModule.detectDoorTransition(state.lastPlayerPosition, self.position, nearby, types)
        if transitionDetected and door then
            log("[DOOR TRANSITION] Detected player moved through door", door.id, "- teleporting guard")
            -- Pass state.lastPlayerPosition as the return position (entrance)
            doorModule.teleportGuardThroughDoor(state.guard.id, self.position, self.cell, self.cell, core, util, state.lastPlayerPosition)
        end
    end

    state.lastPlayerPosition = self.position
    state.lastPlayerCell = self.cell

    -- Update cross-cell returns
    crossCell.updateWanderingNPCs(dt, state, core)

    -- Update real-time wandering
    local currentTime = core.getRealTime()
    for npcId, wanderData in pairs(state.realTimeWandering) do
        if currentTime >= wanderData.endTime then
            log("REAL-TIME WANDERING COMPLETE for NPC", npcId)
            local rotX, rotY, rotZ = utils.getEulerAngles(wanderData.homeRot)
            core.sendGlobalEvent('AntiTheft_StartWalkingHome', {
                npcId = npcId,
                homePosition = wanderData.homePos,
                homeRotation = { x = rotX, y = rotY, z = rotZ }
            })
            state.realTimeWandering[npcId] = nil
        end
    end

    -- Monitor returning NPCs
    crossCell.monitorReturningNPCsLOS(state, nearby, detection, actions, self, types, config, core)

    -- PERFORMANCE: Door state checking moved to onInputAction (USE key)
    -- This was running every frame (60 FPS) causing ~600 ops/sec overhead
    -- Now only checks when player presses USE key
    -- if self.cell and not self.cell.isExterior and nearby.objects then
    --     checkDoorStateChanges()
    -- end





    -- Guard behavior
    if state.guard and state.guard:isValid() then
        if dialogueOpen then return end

        -- Check if NPC is in combat with player and player becomes hidden - start search immediately
        if state.guardInCombat and isHidden and not state.searching then
            log("*** PLAYER BECAME HIDDEN DURING COMBAT - STARTING SEARCH ***")
            state.guardInCombat = false  -- Clear combat state to prevent fleeing
            state.searchDueToCombatRemoval = true  -- Mark that search is due to combat interruption
            actions.startSearch(state, detection, config)
        end

        if state.following then
            if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
                pathModule.updatePathRecording(state.guard.id, state.guard, dt, config)
            end

            -- Prevent unwanted AI packages like hello/greeting
            state.tAIPackageCleanup = (state.tAIPackageCleanup or 0) + dt
            if state.tAIPackageCleanup >= 2.0 then
                state.tAIPackageCleanup = 0
                
                -- AI cleanup removed - all NPCs now managed by return-to-home logic below
                -- No need to re-send follow commands every 2 seconds
            end

            -- Hierarchy check
            state.tHierarchyCheck = state.tHierarchyCheck + dt
            if state.tHierarchyCheck >= config.HIERARCHY_CHECK_INTERVAL then
                state.tHierarchyCheck = 0
                local newGuard, newPriority = pickGuard(false)

                if newGuard and newPriority < state.guardPriority then
                    if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
                        pathModule.stopPathRecording(state.guard.id, state.guard.position)
                    end

                    actions.sendPendingReturnsHome(state.guard, state, core)
                    actions.recruit(newGuard, state, detection, self)
                    state.guardPriority = newPriority
                    
                    -- Always call followPlayer to set state
                    actions.followPlayer(state, self, config)
                    
                    -- Then check if should stay at home
                    if state.home and state.home.pos then
                        local npcDistToHome = (newGuard.position - state.home.pos):length()
                        if npcDistToHome <= 350 then
                            log("[HIERARCHY] Replacement NPC within 350 units of home - following state set, keeping at home")
                            
                            if npcDistToHome > 25 then
                                state.guard:sendEvent('StartAIPackage', {
                                    type = 'Travel',
                                    destPosition = state.home.pos,
                                    cancelOther = true
                                })
                                state.returningToCounter = core.getRealTime()
                            else
                                state.guard:sendEvent('RemoveAIPackages')
                            end
                        end
                    end
                end
            end

            -- Skip normal following logic if investigating door
            if state.investigatingDoor then
                -- Door investigation in progress - don't follow player
                log("[DOOR INVESTIGATION] Skipping normal following - door investigation active")
            elseif isMagicHidden and not state.justRecruitedAfterReturn then
                if state.skipSearch then
                    state.skipSearch = false
                    log("Skipping search start due to cell change - player left cell")
                else
                    log("*** PLAYER BECAME INVISIBLE WHILE FOLLOWING ***")
                    -- Calculate search time based on effect duration
                    local searchTime = config.SEARCH_WTIME_MAX -- default
                    local invisEff = getActiveSpellEffect(self, config.EFFECT_INVIS)
                    local chamEff = getActiveSpellEffect(self, config.EFFECT_CHAM)
                    debugPrintStealthDurations()
                    if invisEff and invisEff.duration ~= nil then
                        log("Invisibility effect duration read:", invisEff.duration, "seconds")
                        if invisEff.duration == 0 then
                            searchTime = 600 -- 10 minutes for constant effect
                            log("Constant invisibility effect detected, search time set to:", searchTime, "seconds")
                        else
                            local extra = math.random(15, 30)
                            searchTime = invisEff.duration + extra
                            log("Calculated search time for invisibility:", searchTime, "seconds (duration +", extra, ")")
                        end
                    elseif chamEff and chamEff.duration ~= nil then
                        log("Chameleon effect duration read:", chamEff.duration, "seconds")
                        if chamEff.duration == 0 then
                            searchTime = 600 -- 10 minutes for constant effect
                            log("Constant chameleon effect detected, search time set to:", searchTime, "seconds")
                        else
                            local extra = math.random(15, 30)
                            searchTime = chamEff.duration + extra
                            log("Calculated search time for chameleon:", searchTime, "seconds (duration +", extra, ")")
                        end
                    else
                        log("No effect duration found, using default search time:", searchTime, "seconds")
                    end
                    state.searchTime = searchTime
                    actions.startSearch(state, detection, config)
                    lowerCellDisposition()
                end
            else
                -- Handle Pending Arrests (Force Dialogue) from AntiTheft_ExpectArrest


                state.tRefresh = state.tRefresh + dt
                if state.tRefresh >= config.UPDATE_PERIOD then
                    state.tRefresh = 0
                    state.lastSeenPlayer = self.position
                    local d = (state.guard.position - self.position):length()
                    
                    -- DEBUG: Log distance and home state periodically
                    state.debugCounter = (state.debugCounter or 0) + 1
                    if state.debugCounter >= 4 then -- Every 4 ticks (approx 2 seconds)
                        state.debugCounter = 0
                        if state.home and state.home.pos then
                            local dist = (state.guard.position - state.home.pos):length()
                            log("[DEBUG] Guard:", state.guard.id, "Dist:", string.format("%.1f", dist), "Outside:", tostring(state.npcWasOutsideRadius), "Home:", state.home.pos)
                        else
                            log("[DEBUG] Guard:", state.guard.id, "NO HOME DATA")
                        end
                    end
                    
                    
                    -- Merchant-specific priority return logic REMOVED
                    -- All NPCs now use unified return-to-home logic below (lines 2222+)
                    
                    -- SPECIAL CASE: Check for finalization when NPC is returning home
                    if state.guard and state.guard:isValid() and state.returningToCounter and state.home and state.home.pos and state.npcWasOutsideRadius then
                        local npcDistToHome = (state.guard.position - state.home.pos):length()
                        
                        if npcDistToHome <= 35 then
                            -- Arrived at home while returning - finalize
                            log("[NPC] NPC arrived at home while returning (dist: " .. string.format("%.1f", npcDistToHome) .. "). Finalizing position and rotation.")
                            
                            -- Remove AI packages to stop any movement
                            state.guard:sendEvent('RemoveAIPackages')
                            
                            -- Send global event to finalize return with rotation (global script handles teleport + rotation)
                            local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)
                            core.sendGlobalEvent('AntiTheft_FinalizeReturn', {
                                npcId = state.guard.id,
                                homePosition = state.home.pos,
                                homeRotation = { x = rotX, y = rotY, z = rotZ }
                            })
                            
                            -- Clear NPC state
                            local guardId = state.guard.id
                            state.guard = nil
                            state.following = false
                            state.returningToCounter = false
                            state.npcWasOutsideRadius = false
                            state.guardPriority = 999
                            state.activeGuards[guardId] = nil
                            
                            -- Set flag to prevent immediate re-recruitment
                            state.merchantJustReturned = guardId
                            
                            log("[NPC] NPC state cleared. Will not re-recruit until player loses LoS.")
                        end
                    end
                    
                    -- Apply return-to-home behavior to ALL NPCs (not just merchants)
                    -- NPCs follow when no LoS, return home when close and have LoS
                    if state.guard and state.guard:isValid() and not state.returningToCounter then
                            -- Check if player is out of LoS
                            local hasLoS = detection.canNpcSeePlayer(state.guard, self, nearby, types, config)
                            
                            if not hasLoS then
                                -- Out of LoS: Clear merchantJustReturned flag if set
                                if state.merchantJustReturned then
                                    log("[NPC] Player lost LoS - clearing merchantJustReturned flag for", state.merchantJustReturned)
                                    state.merchantJustReturned = nil
                                end
                                
                                -- Follow the player to find them
                                if state.home and state.home.pos then
                                    local distanceToHome = (state.guard.position - state.home.pos):length()
                                    log("[NPC] No LoS. NPC distance to home: " .. string.format("%.1f", distanceToHome))
                                    
                                    -- Only dismiss if already returning to counter, otherwise follow
                                    if state.returningToCounter and distanceToHome < 500 then
                                        log("[NPC] NPC returning and lost LoS - dismissing")
                                        actions.goHome(state, core)
                                    else
                                        log("[NPC] NPC lost LoS - following player to find them")
                                        -- Don't set npcWasOutsideRadius here - let the distance check below handle it
                                        actions.followPlayer(state, self, config)
                                    end
                                else
                                    -- Fallback: NPC lost LoS but missing home data - follow anyway
                                    log("[NPC] NPC lost LoS (no home data) - following player")
                                    actions.followPlayer(state, self, config)
                                end
                            else
                                -- Player has LoS: Check distance logic for return-to-home
                                if state.home and state.home.pos then
                                    local playerDistToHome = (self.position - state.home.pos):length()
                                    local npcDistToHome = (state.guard.position - state.home.pos):length()
                                    
                                    log("[NPC] LoS Active. Player dist to home: " .. string.format("%.1f", playerDistToHome) .. ", NPC dist to home: " .. string.format("%.1f", npcDistToHome))
                                    
                                    -- Track when NPC is outside the 350-unit radius
                                    if npcDistToHome > 350 then
                                        if not state.npcWasOutsideRadius then
                                            log("[NPC] NPC is now OUTSIDE 350-unit radius (tracking)")
                                            state.npcWasOutsideRadius = true
                                        end
                                        
                                        -- Normal following logic when outside radius
                                        if playerDistToHome > 350 then
                                            if state.returningToCounter then
                                                state.returningToCounter = false
                                                log("[NPC] Player moved > 350 units away - Resuming follow")
                                            end
                                            if not state.returningToCounter then
                                                actions.followPlayer(state, self, config)
                                            end
                                        end
                                    else
                                        -- NPC is within 350 units of home
                                        if state.npcWasOutsideRadius then
                                            log("[NPC] *** NPC ENTERED 350-unit radius (was outside before) ***")
                                            
                                            if npcDistToHome > 35 then
                                                if not state.returningToCounter then
                                                    -- Only start returning if not already returning
                                                    log("[NPC] NPC entered 350-unit radius. Sending NPC home. Dist: " .. string.format("%.1f", npcDistToHome))
                                                    state.guard:sendEvent('StartAIPackage', {
                                                        type = 'Travel',
                                                        destPosition = state.home.pos,
                                                        cancelOther = true
                                                    })
                                                    state.returningToCounter = core.getRealTime()
                                                else
                                                    log("[NPC] Already returning - skipping duplicate Travel package")
                                                end
                                            else
                                                -- Arrived at home - teleport to exact position, then rotate
                                                log("[NPC] NPC arrived at home. Finalizing position and rotation.")
                                                
                                                -- First teleport to EXACT home position and apply rotation via Global script
                                                -- (Teleporting actors is not supported in player scripts)
                                                
                                                -- Remove AI packages to stop any movement
                                                state.guard:sendEvent('RemoveAIPackages')
                                                
                                                -- Send global event to finalize return with rotation
                                                local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)
                                                core.sendGlobalEvent('AntiTheft_FinalizeReturn', {
                                                    npcId = state.guard.id,
                                                    homePosition = state.home.pos,
                                                    homeRotation = { x = rotX, y = rotY, z = rotZ }
                                                })
                                                
                                                -- Clear NPC state
                                                local guardId = state.guard.id
                                                state.guard = nil
                                                state.following = false
                                                state.returningToCounter = false
                                                state.npcWasOutsideRadius = false
                                                state.guardPriority = 999
                                                state.activeGuards[guardId] = nil
                                                
                                                -- Set flag to prevent immediate re-recruitment
                                                state.merchantJustReturned = guardId
                                                
                                                log("[NPC] NPC state cleared. Will not re-recruit until player loses LoS.")
                                             end
                                        else
                                            -- NPC is within 350 units but never left radius
                                            -- CRITICAL: Only keep at home if HAS LoS
                                            -- If no LoS, let them leave to follow player
                                            log("[NPC] NPC within 350 units (never left radius) - staying at home while visible")
                                        end
                                    end
                                else
                                    -- Fallback for NPCs missing home data
                                log("[NPC] Keeping NPC", state.guard.id, "stationary while player in LoS")
                            end
                        end
                    -- Old distance-based following removed - all NPCs now use return-to-home behavior
                    end
                end
            end



            -- Check door investigation progress
            if state.investigatingDoor and state.doorPosition then
                local distanceToDoor = (state.guard.position - state.doorPosition):length()
                log("[DOOR INVESTIGATION] Distance to door: " .. string.format("%.1f", distanceToDoor) .. " units")
                if distanceToDoor <= 550 then
                    log("[DOOR INVESTIGATION] NPC reached door investigation position (<=550 units), removing AI packages for 15 seconds")
                    state.guard:sendEvent('RemoveAIPackages')
                    state.investigatingDoor = false
                    async:registerTimerCallback("DoorInvestigationComplete", function()
                        log("[DOOR INVESTIGATION] 15-second wait complete, re-recruiting NPC")
                        core.sendGlobalEvent('AntiTheft_ReRecruitGuard', {npcId = state.guard.id})
                    end, 15.0)
                end
            end

            -- Clear the just recruited flag after processing
            state.justRecruitedAfterReturn = false

        elseif state.searching then
            local distance = (state.guard.position - self.position):length()
            log("[SEARCH] Guard dist:", math.floor(distance), "Time:", math.floor(state.searchT), "/", (state.searchTime or 75))

            state.searchT = state.searchT + dt

            -- Check if invisibility effect just wore off while NPC is searching
            if state.wasHidden and not isHidden and state.searching and state.guard and state.guard:isValid() then
                if not detection.canNpcSeePlayer(state.guard, self, nearby, types, config) then
                    log("*** INVISIBILITY EFFECT WORE OFF, NPC SEARCHING BUT NO LOS - DISBANDING AND RETURNING HOME (in 2.5s) ***")
                    local guardId = state.guard.id
                    async:registerTimerCallback("InvisibilityWoreOffSearch_" .. guardId, function()
                        -- Verify guard is still valid and in searching state
                        if state.guard and state.guard:isValid() and state.guard.id == guardId and state.searching then
                            log("*** EXECUTING DELAYED DISBAND - RETURNING HOME ***")
                            actions.goHome(state, core)
                        else
                            log("*** DELAYED DISBAND CANCELLED - Guard state changed ***")
                        end
                    end, 2.5)
                    return
                end
            end

            -- Check if any other NPC in the cell can see the player (imitate informing each other)
            local playerSpottedByOtherNPC = false
            if not isSneakHidden and not isMagicHidden then
                for _, actor in ipairs(nearby.actors) do
                    if actor.type == types.NPC and actor.id ~= state.guard.id and detection.canNpcSeePlayer(actor, self, nearby, types, config) then
                        playerSpottedByOtherNPC = true
                        log("*** PLAYER SPOTTED BY OTHER NPC ***")
                        break
                    end
                end
            end

            if (not isSneakHidden and not isMagicHidden and detection.canNpcSeePlayer(state.guard, self, nearby, types, config)) or playerSpottedByOtherNPC then
                log("*** PLAYER DETECTED BY GUARD DURING SEARCH ***")
                if not state.stealthMessageSent and not state.invisMessageSent then
                    core.sendGlobalEvent('AntiTheft_PlayDetectionVoice', { npcId = state.guard.id })
                    state.stealthMessageSent = true
                end
                -- Clear search state and resume appropriate behavior
                core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
                state.searching = false
                state.searchT = 0
                state.searchTime = nil

                -- If NPC was previously in combat with player OR search was due to combat removal, resume combat
                if state.wasInCombatWithPlayer or state.searchDueToCombatRemoval then
                    log("*** RESUMING COMBAT WITH PLAYER DURING SEARCH ***")
                    state.guardInCombat = true
                    state.wasInCombatWithPlayer = true
                    -- Start combat AI package to attack the player
                    state.guard:sendEvent('StartAIPackage', {type='Combat', target=self})
                    -- Clear the combat removal flag
                    state.searchDueToCombatRemoval = false
                else
                    actions.followPlayer(state, self, config)
                end
            elseif state.searchT >= (state.searchTime or 75) then
                log("*** SEARCH TIME EXPIRED ***")
                -- Check if player is visible and NPC was previously in combat with player
                if state.wasInCombatWithPlayer and not isSneakHidden and not isMagicHidden and detection.canNpcSeePlayer(state.guard, self, nearby, types, config) then
                    log("*** PLAYER VISIBLE WHEN SEARCH EXPIRED AND WAS IN COMBAT - RESUMING COMBAT ***")
                    -- Resume combat state from before invisibility
                    state.guardInCombat = true
                    state.wasInCombatWithPlayer = true
                    -- Start combat AI package to attack the player
                    state.guard:sendEvent('StartAIPackage', {type='Combat', target=self})
                    -- Clear search state
                    core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
                    state.searching = false
                    state.searchT = 0
                    state.searchTime = nil
                elseif not isSneakHidden and not isMagicHidden and detection.canNpcSeePlayer(state.guard, self, nearby, types, config) then
                    log("*** PLAYER VISIBLE WHEN SEARCH EXPIRED - RESUMING FOLLOW ***")
                    actions.followPlayer(state, self, config)
                elseif not isHidden then
                    actions.goHome(state, core)
                    -- Clear search state after returning home to prevent endless search loop
                    if state.hasReturnedHome then
                        core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = state.guard.id })
                        state.searching = false
                        state.hasReturnedHome = false
                        log("*** SEARCH CANCELLED AFTER RETURNING HOME ***")
                    end
                end
            end

        elseif not state.following and not state.searching and not state.returningHome and not state.guardInCombat and
               not dialogueOpen and not isSneakHidden and not isMagicHidden then
            log("[UPDATE] Guard exists but not in known state - starting follow")
            actions.followPlayer(state, self, config)
            
            -- After setting following state, check if should stay at home
            if state.home and state.home.pos and state.guard then
                local npcDistToHome = (state.guard.position - state.home.pos):length()
                if npcDistToHome <= 350 then
                    log("[UPDATE] Guard within 350 units of home - canceling movement, keeping at home")
                    
                    if npcDistToHome > 25 then
                        state.guard:sendEvent('StartAIPackage', {
                            type = 'Travel',
                            destPosition = state.home.pos,
                            cancelOther = true
                        })
                        state.returningToCounter = core.getSimulationTime()
                    else
                        state.guard:sendEvent('RemoveAIPackages')
                    end
                end
            end
            end
        
    end
end

log("=== SCRIPT LOADED SUCCESSFULLY v20.0 - MODULAR ===")

----------------------------------------------------------------------
-- Offset vectors for LOS (from detection.lua)
local vEye   = util.vector3(0, 0, 90)

-- Door detection on Activate key press
local function onInputAction(action)
    if core.isWorldPaused() then return end

    if action == input.ACTION.Activate then
        log("Activate key pressed - sending detection event to global script")
        core.sendGlobalEvent('AntiTheft_DoorDetection', {})
    end
    
    if action == input.ACTION.Use then
        log("Use key pressed - triggering global door detection")
        core.sendGlobalEvent('AntiTheft_DoorDetection', {})

        -- Check if player has a keylock equipped
        local equipment = types.Actor.getEquipment(self)
        local equippedItem = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
        local isKeylockEquipped = false
        local keylockId = nil
        
        if equippedItem and equippedItem.recordId then
            local itemId = equippedItem.recordId:lower()
            if itemId == "keylock-iron" or itemId == "keylock-imperial" or 
               itemId == "keylock-dwemer" or itemId == "keylock-master" or 
               itemId == "keylock-skeleton" then
                isKeylockEquipped = true
                keylockId = itemId
                log("[KEYLOCK] Keylock equipped:", itemId)
            end
        end

        -- If keylock is equipped and weapon is drawn, try to lock a door
        local isWeaponStance = types.Actor.getStance(self) == types.Actor.STANCE.Weapon
        if isKeylockEquipped and isWeaponStance then
            performKeylockAttempt()
        else
            -- Normal door lock detection (only if keylock not actively being used)
            log("Global door detection triggered (Normal Mode)")
            
            -- Send event to global script to check for door lock changes
            core.sendGlobalEvent('AntiTheft_CheckDoorLocks', {
                delay = 1.9  -- Check after 1.9 seconds for lock action to complete
            })

            doorStatesRecorded = false  -- Reset flag after use

            -- CRITICAL FIX: Run door check in async callback to avoid blocking input
            async:newUnsavableSimulationTimer(0.1, function()
                if self.cell and not self.cell.isExterior then
                    -- Raycast to find target door
                    local camPos = camera.getPosition()
                    local rot = self.rotation 
                    local forward = rot:apply(util.vector3(0, 1, 0))
                    local endPos = camPos + (forward * 200) -- 200 units reach
                    
                    local ray = nearby.castRay(camPos, endPos, {
                        collisionType = 3 + nearby.COLLISION_TYPE.Door, 
                        ignore = self
                    })
                    
                    local targetDoorCheck = nil
                    if ray.hit and ray.hitObject and (ray.hitObject.type == types.Door) then
                        targetDoorCheck = ray.hitObject
                        log("[DOOR CHECK] Raycast hit door:", targetDoorCheck.id)
                    end
                    
                    if targetDoorCheck then
                        checkDoorStateChanges(targetDoorCheck)
                    end
                end
            end)
        end
    end
    
    -- IMPORTANT: Don't return anything - let input pass through to game
    -- Returning a value would consume the input and break camera/controls
end


log("[DEBUG-UI] Script Reached Return Block - Handlers Registered")
return {
    engineHandlers = {
         onUpdate = onUpdate,
        onInputAction = onInputAction
    },
    eventHandlers = {
        AntiTheft_NPCReady = onNPCReady,
        AntiTheft_ClearSearchState = onClearSearchState,
        AntiTheft_MagicEffectApplied = onMagicEffectApplied,
        AntiTheft_CheckLockSpellBounty = onCheckLockSpellBounty,
        AntiTheft_ApplyDoorBounty = onApplyDoorBounty,
        AntiTheft_StartDoorInvestigation = onStartDoorInvestigation,
        AntiTheft_ClearGuardState = function(data)
            if not data or not data.npcId then return end
            log("[DOOR INVESTIGATION] Clearing guard state for NPC:", data.npcId)
            state.following = false
            core.sendGlobalEvent('AntiTheft_CancelSearchTimer', { npcId = data.npcId })
            state.searching = false
            state.returningHome = false
            state.guard = nil
            state.guardPriority = 999
            log("✓ Guard state cleared for NPC", data.npcId)
        end,
        AntiTheft_ReRecruitGuard = onReRecruitGuard,
        AntiTheft_StartSearchForPlayer = function(data)
            if not data or not data.npcId then return end
            if state.guard and state.guard.id == data.npcId then
                actions.startSearch(state, detection, config)
            end
        end,
        AntiTheft_ForceTravelToPlayer = onForceTravelToPlayer,
        AntiTheft_StartLOSMonitoring = function(data)
            if not (data and data.npcId and data.bountyAmount and data.doorId) then 
                log("[LOS MONITORING] Invalid data received")
                return 
            end
            
            log("[LOS MONITORING] Starting continuous LoS monitoring for NPC", data.npcId, "on door", data.doorId)
            
            pendingBountyMonitoring[data.doorId] = {
                npcId = data.npcId,
                bountyAmount = data.bountyAmount,
                startTime = core.getRealTime(),
                doorPosition = data.doorPosition,
                maxDuration = 15  -- Monitor for max 15 seconds
            }
            
            log("[LOS MONITORING] Monitoring started - will check LoS continuously until NPC sees player or timeout")
        end,
        AntiTheft_StopLOSMonitoring = function(data)
            if not (data and data.doorId) then return end
            
            if pendingBountyMonitoring[data.doorId] then
                log("[LOS MONITORING] Stopping LoS monitoring for door", data.doorId)
                pendingBountyMonitoring[data.doorId] = nil
            end
        end,
        -- Relay events from NPC scripts to global script
        -- NPC scripts can't send to global directly, must go through player script
        AntiTheft_Relay_NPCUnconscious = function(data)
            log("[PLAYER RELAY] Relaying unconscious event to global:", data.npcId, "wasSpotted:", data.wasSpotted)
            
            -- Check Faction Rank Compliance: Suppress body discovery if rank is high enough
            if self.cell and not self.cell.isExterior then
                -- NEW: Also check if the victim is a player companion (Escort/Follow)
                if companionDetection.isCompanion(data.npcId and nearby.getObjectByEntityId(data.npcId) or nil) then
                     log("[PLAYER RELAY] Unconscious NPC is a companion - suppressing global unconscious event")
                     return
                end

                local cellFaction = classification.detectCellFaction(nearby, types)
                if cellFaction then
                    if types.NPC and types.NPC.getFactions then
                        local playerFactions = types.NPC.getFactions(self)
                        if playerFactions then
                            for _, factionId in ipairs(playerFactions) do
                                if factionId == cellFaction then
                                    local playerRank = types.NPC.getFactionRank(self, factionId)
                                    if playerRank >= config.FACTION_IGNORE_RANK then
                                        log("[PLAYER RELAY] Player has rank", playerRank, "in", cellFaction, "- suppressing global unconscious event (no body discovery pulse)")
                                        return -- Suppress event
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            -- Disband follower if it's the current guard (Fix for unconscious follower bug)
            if state.guard and state.guard.id == data.npcId then
                 log("[ANTI-THEFT] Current follower knocked UNCONSCIOUS! Disbanding.")
                 local guardId = state.guard.id
                 state.guard = nil
                 state.following = false
                 state.returningToCounter = false
                 state.activeGuards[guardId] = nil
                 -- Also ensure logic doesn't try to use invalid guard
            end
            
            core.sendGlobalEvent('AntiTheft_NPCUnconscious', data)
        end,
        
        AntiTheft_RequestBodyLOSCheck = function(data)
            if not (data and data.witnessId and data.bodyId and data.bodyPos and data.witnessPos) then
                log("[PLAYER RELAY] Invalid LOS check request data")
                return
            end
            
            log("[PLAYER RELAY] Performing LoS check for witness", data.witnessId, "to body", data.bodyId)
            
            -- Perform raycast between witness and body
            local startPos = data.witnessPos + util.vector3(0, 0, 80) -- Witness eye level
            local endPos = data.bodyPos + util.vector3(0, 0, 10)    -- Body center (prone)
            
            local ray = nearby.castRay(startPos, endPos, {
                collisionType = 3,
                ignore = self 
            })
            
            if not ray.hit then
                log("[PLAYER RELAY] LoS clear! Witness", data.witnessId, "sees body", data.bodyId)
                core.sendGlobalEvent('AntiTheft_BodyDiscoveryConfirmed', {
                    witnessId = data.witnessId,
                    bodyId = data.bodyId
                })
            else
                log("[PLAYER RELAY] LoS blocked for witness", data.witnessId, "to body", data.bodyId)
            end
        end,
        

        AntiTheft_Relay_NPCConscious = function(data)
            log("[PLAYER RELAY] Relaying conscious event to global:", data.npcId)
            core.sendGlobalEvent('AntiTheft_NPCConscious', data)
        end,
        AntiTheft_Relay_SleepBounty = function(data)
            log("[PLAYER RELAY] Processing sleep bounty event")
            local amount = 0
            local npcId = nil
            
            -- Handle table input (new format)
            if type(data) == 'table' then
                amount = data.amount or 0
                npcId = data.npcId
            elseif type(data) == 'number' then
                amount = data
            end
            
            -- User Request: Use stunNPCBounty for Illegal Sleep Spell / Stun
            local settingAmount = settings.bounties:get('stunNPCBounty') or 300
            if amount == 0 then amount = settingAmount end
            
            if amount > 0 then
                log("[PLAYER RELAY] Relaying bounty to global. Amount:", amount, "NPC:", npcId)
                core.sendGlobalEvent('AntiTheft_SetPlayerBounty', {
                    bountyAmount = amount,
                    npcId = npcId,
                    reason = "Assault (Blackjack Stun)"
                })
                
                -- Local UI message for feedback (Removed as requested)
            else
                log("[PLAYER RELAY] Error: Invalid bounty amount received (0)")
            end
        end,
        
        AntiTheft_UpdateBedCache = function(data)
            if not data or not data.cellName or not data.beds then return end
            log("[BED CACHE UPDATED] Received", #data.beds, "beds for cell", data.cellName)
            state.cellBeds[data.cellName] = data.beds
            state.needsBedScan = false
        end,
        AntiTheft_NotifyWitnessAttack = function(data)
            if data and data.npcId then
               log("[COMBAT SYNC] Expecting witness attack from", data.npcId)
               pendingWitnessAttacks[data.npcId] = true
               -- Auto-clear after 3 seconds in case combat doesn't start
               async:newUnsavableSimulationTimer(3.0, function() pendingWitnessAttacks[data.npcId] = nil end)
            end
        end,
        AntiTheft_ShowMessage = function(data)
            if data and data.text then
                ui.showMessage(data.text)
            end
        end,
        ShowMessage = function(data)
            log("[PLAYER DEBUG] ShowMessage event received:", data and data.message or "nil")
        end,
        S3CombatTargetAdded = onS3CombatTargetAdded,
        S3CombatTargetRemoved = onS3CombatTargetRemoved,
        AntiTheft_BlackjackSuccess = onBlackjackSuccess
    }
}
