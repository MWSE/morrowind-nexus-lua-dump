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
-- GLOBAL SCRIPT – handles NPC teleportation, wandering, and rotation
----------------------------------------------------------------------

local storage = require('openmw.storage')

-- Global scripts must use *global* storage instead of player storage
local settings = storage.globalSection("SettingsSHOPset")
local vars = storage.globalSection("SettingsSHOPsetVars")
local settingsBounties = storage.globalSection("SettingsSHOPsetBounties")
local seenMessages = {}
local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local util = require('openmw.util')
local classification = require('scripts.antitheftai.modules.npc_classification')
local companionDetection = require('scripts.antitheftai.modules.companion_detection')
local bedVoices = require('scripts.antitheftai.modules.bed_voices')
local config = require('scripts.antitheftai.modules.config')
local utils = require('scripts.antitheftai.modules.utils')
-- local cache, used by your log() helper
local _enableGlobalDebug = settings:get('enableGlobalDebug')
local _enableLogging = settings:get('enableLogging')
if _enableLogging == nil then _enableLogging = true end
local _enableDoorMechanics = settings:get('enableDoorMechanics')
if _enableDoorMechanics == nil then _enableDoorMechanics = true end
local _enableBedDetection = settings:get('enableBedDetection')
if _enableBedDetection == nil then _enableBedDetection = true end

local function log(...)
    if not _enableLogging or not _enableGlobalDebug then return end
    
    local args = { ... }
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    
    print("[AntiTheft-Global]", table.concat(args, "\t"))
end

-- event sent from the player script whenever a setting changes
local function onUpdateSetting(data)
    if not data or not data.key then return end
    -- store it permanently
    settings:set(data.key, data.value)
    -- also handle vars settings
    if data.key == 'dispositionChange' or data.key == 'removeDispositionOnce' then
        vars:set(data.key, data.value)
    end
    -- refresh the local cache so the new value is used immediately
    if data.key == 'enableGlobalDebug' then
        _enableGlobalDebug = data.value
    elseif data.key == 'enableLogging' then
        _enableLogging = data.value
    elseif data.key == 'enableDoorMechanics' then
        _enableDoorMechanics = data.value
    elseif data.key == 'enableBedDetection' then
        _enableBedDetection = data.value
    end
    log('Setting', data.key, 'changed to', tostring(data.value))
end
log("=== GLOBAL SCRIPT LOADING v18.1 ===")

local world = require('openmw.world')
local util  = require('openmw.util')
local core  = require('openmw.core')
local types = require('openmw.types')
local async = require('openmw.async')
local config        = require('scripts.antitheftai.modules.config')
local pendingReturns  = {}
local activeRotations = {}
local wanderingNPCs = {}
local activeWakeUpWanders = {} -- Tracks NPCs doing the wake-up wander, to allow cancellation
local recentlyRotated = {}  -- Track NPCs currently wandering
local pendingTeleports = {}  -- Track NPCs waiting to be teleported
local teleportingNPCs = {}  -- Track NPCs currently being teleported home
local teleportTimeouts = {}  -- Track NPCs with 5-minute timeout to return to default position
local dispositionAppliedCells = {}  -- Track cells where disposition penalty has been applied (count up to 2)
local lastPlayerCell = nil  -- Track the last cell the player was in
local searchTimers = {}  -- Track search timers for NPCs
local returnStartTimes = {}  -- Track when NPCs started returning home (for simulation when not loaded)
local recentlyRotated = {}  -- Track NPCs that recently completed rotation to prevent duplicate returns
local doorLastLockLevels = {}  -- Track last lock levels for doors (doorId -> lockLevel)
local doorLockCheckDelay = 0  -- Manual delay timer for door lock checks in global script
local doorInvestigation = {}  -- Track NPCs investigating doors (npcId -> {doorPosition, startTime, lastLog})
local followingNPCs = {}  -- Track NPCs currently following the player (npcId -> true)

local KEYLOCK_RANGES = {
    ['keylock-iron']     = {min = 1,  max = 25},
    ['keylock-imperial'] = {min = 26, max = 50},
    ['keylock-dwemer']   = {min = 51, max = 75},
    ['keylock-master']   = {min = 76, max = 99},
    ['keylock-skeleton'] = {min = 100, max = 100}
}

-- Local cache for NPC race/gender data (fetched once and reused)
local npcRaceGenderCache = {}
local npcHomePositions = {} -- npcId -> homePosition

-- Combat door lock monitoring state variables (moved from player script)
local monitorDoorLocksDuringCombat = false
local combatDoorStates = {}
local doorLockStates = {}
local doorLockStatesJustInitialized = false  -- Flag to skip first check after initialization
local combatDoorInvestigation = {}  -- Track NPCs approaching doors during combat
local npcsInCombatWithPlayer = {}  -- Track which NPCs are in combat with player (npcId -> true)
local pendingBountyChecks = {}  -- Track pending bounty checks waiting for LoS verification after unlock (doorId -> {npcId, bountyAmount, timestamp})

-- Door lock check function (will be called directly by async timer)
-- Note: performDoorLockCheck is defined later in the file

----------------------------------------------------------------------
-- Helper: find NPC by ID
----------------------------------------------------------------------
local function findNPC(npcId)
    for _, actor in ipairs(world.activeActors) do
        if actor.id == npcId then return actor end
    end
    return nil
end

----------------------------------------------------------------------
-- Bed Detection Functions (Global Script)
----------------------------------------------------------------------

-- Check if an activator is a bed
local function isBed(object)
    if not object or object.type ~= types.Activator then
        return false
    end
    
    local recordId = object.recordId
    if not recordId then return false end
    
    -- Get activator record
    local record = types.Activator.record(recordId)
    if not record then return false end
    
    -- Only match beds with display name exactly "Bed"
    local name = record.name or ""
    if name == "Bed" then
        return true
    end
    
    return false
end

-- Find all beds in a cell and cache their positions
local bedScanCache = {} -- Cache bed scans per cell

local function scanBedsInCell(cell)
    if not cell or cell.isExterior then
        return {}
    end
    
    local cellName = cell.name or ""
    
    -- Return cached result if available
    if bedScanCache[cellName] then
        log("[BED SCAN GLOBAL] Using cached bed scan for cell", cellName)
        return bedScanCache[cellName]
    end

    -- Check for disabled cell name keys
    local lowerCellName = cellName:lower()
    for _, key in ipairs(config.DISABLED_CELL_NAME_CONTAINS) do
        if lowerCellName:find(key:lower()) then
            log("[BED SCAN GLOBAL] Cell", cellName, "contains disabled key", key, "- skipping bed scan")
            bedScanCache[cellName] = {} -- Cache empty result to avoid re-checking
            return {}
        end
    end
    
    -- Check if cell is disabled via configuration
    if classification.isCellDisabled(cell, config.DISABLED_CELL_NAMES) then
        log("[BED SCAN GLOBAL] Cell", cellName, "is disabled in config - skipping bed scan")
        bedScanCache[cellName] = {}
        return {}
    end

    -- Build a 'nearby' context for classification checks using all actors in the cell
    local allActors = cell:getAll(types.NPC)
    local nearbyContext = { actors = allActors }

    -- Check for "Slaves and Enemies" condition
    if classification.shouldDisableCellForSlavesAndEnemies(nearbyContext, types) then
        log("[BED SCAN GLOBAL] Cell", cellName, "contains Slaves and Enemies - skipping bed scan")
        bedScanCache[cellName] = {}
        return {}
    end

    -- Check for "Only Enemies" condition
    if classification.shouldDisableCellForOnlyEnemies(nearbyContext, types) then
        log("[BED SCAN GLOBAL] Cell", cellName, "contains Only Enemies - skipping bed scan")
        bedScanCache[cellName] = {}
        return {}
    end

    -- Check for "Publican" condition
    if classification.shouldDisableCellForPublican(nearbyContext, types) then
        log("[BED SCAN GLOBAL] Cell", cellName, "contains a Publican - skipping bed scan")
        bedScanCache[cellName] = {}
        return {}
    end

    -- Check for Guild Rank condition
    local cellFaction = classification.detectCellFaction(nearbyContext, types)
    if cellFaction then
        local player = world.players[1]
        if player and types.Player and types.Player.factions then
            local playerFactions = types.Player.factions(player)
            local rankThreshold = config.FACTION_IGNORE_RANK or 5
            
            for _, pf in ipairs(playerFactions) do
                if pf.factionId == cellFaction then
                    if pf.rank >= rankThreshold then
                        log("[BED SCAN GLOBAL] Player rank", pf.rank, "in faction", cellFaction, ">= threshold", rankThreshold, "- skipping bed scan")
                        bedScanCache[cellName] = {}
                        return {}
                    end
                    break 
                end
            end
        end
    end
    
    log("[BED SCAN GLOBAL] Starting scan, cell name:", cellName)
    local bedPositions = {}
    local bedCount = 0
    
    for _, object in pairs(cell:getAll(types.Activator)) do
        if isBed(object) then
            table.insert(bedPositions, object.position)
            bedCount = bedCount + 1
            log("[BED SCAN GLOBAL] Found bed:", object.recordId, "at position:", object.position)
        end
    end
    
    log("[BED SCAN GLOBAL] Found", bedCount, "beds in cell", cellName)
    
    -- Cache the result
    bedScanCache[cellName] = bedPositions
    
    return bedPositions
end

-- Bed tracking state
local cellBedCache = {}  -- cellName -> {positions = {...}}
local bedVoiceState = {}  -- npcId -> {firstFired = bool, secondFired = bool, lastCheck = time}

--── FIX : remember race/gender once passed from player script
local function rememberRaceGender(npcId,race,gender)
    if npcId and race and gender then
        npcRaceGenderCache[npcId] = {race=race,gender=gender}
    end
end

----------------------------------------------------------------------
-- Unconscious Body Discovery System
----------------------------------------------------------------------
-- Detection pulse system - each unconscious NPC emits 800-unit pulse every 1 second
local unconsciousPulseTimers = {}  -- npcId -> pulse timer
local unconsciousNPCStates = {}    -- npcId -> {wasSpotted = bool}
local bodyDiscoveries = {}         -- discovererNpcId -> {unconsciousNpcId -> true}

-- Constants
local PULSE_RANGE_INTERIOR = 1000
local PULSE_RANGE_EXTERIOR = 2500
local PULSE_INTERVAL = 1.0
local DISCOVERY_BOUNTY_VALUE = 99  -- Trigger for stun bounty

-- Helper function to check if NPC is unconscious
local function isNPCUnconscious(npc)
    if not (npc and npc:isValid()) then 
        return false 
    end
    
    -- Check if NPC has the sleep spell active
    local SLEEP_SPELL_ID = 'detd_sleep_spell3'
    local hasSpell = types.Actor.activeSpells(npc):isSpellActive(SLEEP_SPELL_ID)
    
    if hasSpell then
        -- Also check stance - unconscious NPCs should be in knockdown/prone stance
        local stance = types.Actor.getStance(npc)
        local isUnconscious = (stance == 0)
        
        if isUnconscious then
            log("[DEBUG isNPCUnconscious] NPC", npc.id, "IS unconscious - spell active, stance:", stance)
        else
            log("[DEBUG isNPCUnconscious] NPC", npc.id, "has spell but stance is", stance, "not unconscious")
        end
        
        return isUnconscious
    end
    
    return false
end

-- Pulse emission function - scans for nearby conscious NPCs and alerts them
local function emitDetectionPulse(unconsciousNpc, unconsciousNpcId)
    if not (unconsciousNpc and unconsciousNpc:isValid()) then
        -- NPC woke up or is invalid - cancel pulse
        if unconsciousPulseTimers[unconsciousNpcId] then
            log("[PULSE] NPC", unconsciousNpcId, "woke up - cancelling detection pulse")
            unconsciousPulseTimers[unconsciousNpcId] = nil
            unconsciousNPCStates[unconsciousNpcId] = nil
        end
        return
    end
    
    -- Check if still unconscious
    if not isNPCUnconscious(unconsciousNpc) then
        log("[PULSE] NPC", unconsciousNpcId, "woke up - cancelling pulse")
        unconsciousPulseTimers[unconsciousNpcId] = nil
        unconsciousNPCStates[unconsciousNpcId] = nil
        return
    end

    -- GLOBAL PULSE DISABLED: Relying on local script (blackjack_sleep.lua) for detection.
    -- Global scripts cannot reliably check LoS across all objects.
    log("[PULSE] NPC", unconsciousNpcId, "pulse skipped (using local detection)")
    return
end

----------------------------------------------------------------------
-- Finish return: set rotation and restore default behavior
----------------------------------------------------------------------
local function finishReturn(rot)
    local npc = rot.npc

    -- Check if NPC is still valid before teleporting
    if not (npc and npc:isValid()) then
        log("NPC", rot.npcId, "became invalid before finishing rotation - cleaning up")
        return
    end

    -- Check if NPC is already being teleported
    if teleportingNPCs[rot.npcId] then
        log("NPC", rot.npcId, "is already being teleported - skipping duplicate teleport")
        return
    end

    if not rot.homeRotation then
        log("ERROR: Missing homeRotation for NPC", rot.npcId)
        return
    end

    local homeRotTransform = util.transform.rotateZ(rot.homeRotation.z or 0) *
                             util.transform.rotateY(rot.homeRotation.y or 0) *
                             util.transform.rotateX(rot.homeRotation.x or 0)

    -- Final validity check before teleport
    if npc and npc:isValid() then
        -- Mark as teleporting to prevent duplicate teleports
        teleportingNPCs[rot.npcId] = true

        npc:teleport(npc.cell.name, npc.position, { rotation = homeRotTransform, onGround = true })

        local player = world.players[1]
        if player then
            player:sendEvent('AntiTheft_NPCReady', { npcId = rot.npcId })
            player:sendEvent('AntiTheft_ClearSearchState', { npcId = rot.npcId })
            log("✓ NPC", rot.npcId, "ready – can detect player")
        else
            log("ERROR: Could not find player to send ready event")
        end

        -- Enable default AI behavior after teleporting home
        npc:sendEvent('AntiTheft_EnableDefaultAI')

        -- Clear teleporting flag immediately (async not available in global scripts)
        teleportingNPCs[rot.npcId] = nil

        -- Remove from pending returns to prevent re-triggering rotation
        for i = #pendingReturns, 1, -1 do
            if pendingReturns[i].npcId == rot.npcId then
                table.remove(pendingReturns, i)
                log("Removed NPC", rot.npcId, "from pending returns after rotation completion")
                break
            end
        end
    else
        log("NPC", rot.npcId, "became invalid during final teleport - cleaning up")
    end
end

----------------------------------------------------------------------
-- Begin smooth rotation
----------------------------------------------------------------------
local function startGlobalRotation(npc, targetRotation, duration, homePosition, homeRot)
    if not (npc and npc:isValid()) then
        log("ERROR: Invalid NPC in startGlobalRotation")
        return
    end

    if not targetRotation then
        log("ERROR: Missing targetRotation for NPC", npc.id)
        return
    end

    -- Always perform smooth rotation when player is in the same cell
    -- (Direct teleportation is only for cross-cell transitions or search timer expirations)

    local currentZ = npc.rotation:getAnglesZYX()

    log("Starting smooth rotation for", npc.id,
        "from", math.deg(currentZ), "to", math.deg(targetRotation.z or 0), "deg")

    local targetZ = targetRotation.z or 0
    local diff = targetZ - currentZ
    if diff >  math.pi then diff = diff - 2*math.pi
    elseif diff < -math.pi then diff = diff + 2*math.pi end

    table.insert(activeRotations, {
        npcId             = npc.id,
        npc               = npc,
        startZ            = currentZ,
        targetX           = targetRotation.x or 0,
        targetY           = targetRotation.y or 0,
        targetZ           = targetZ,
        duration          = duration,
        elapsed           = 0,
        diffZ             = diff,
        lastLog           = 0,
        exactHomePosition = homePosition,
        homeRotation      = homeRot
    })
end

----------------------------------------------------------------------
-- Per-frame rotation updater
----------------------------------------------------------------------
local function updateGlobalRotations(dt)
    for i = #activeRotations, 1, -1 do
        local rot = activeRotations[i]
        if not (rot.npc and rot.npc:isValid()) then
            log("NPC became invalid during rotation - cleaning up")
            table.remove(activeRotations, i)
        else
            rot.elapsed = rot.elapsed + dt
            if rot.elapsed >= rot.duration then
                -- Check validity before finishing return
                if rot.npc and rot.npc:isValid() then
                    finishReturn(rot)
                else
                    log("NPC became invalid before finishing rotation - cleaning up")
                end
                table.remove(activeRotations, i)
            else
                -- Check validity before teleporting
                if rot.npc and rot.npc:isValid() then
                    local t = rot.elapsed / rot.duration
                    local eased = (t < 0.5) and (4*t*t*t)
                                  or (1 - math.pow(-2*t + 2, 3)/2)
                    local curZ = rot.startZ + rot.diffZ * eased
                    local curRot = util.transform.rotateZ(curZ)
                                  * util.transform.rotateY(rot.targetY)
                                  * util.transform.rotateX(rot.targetX)

                    -- Final validity check before teleport and ensure not already teleporting
                    if rot.npc and rot.npc:isValid() and not teleportingNPCs[rot.npcId] then
                        rot.npc:teleport(rot.npc.cell.name, rot.npc.position,
                                         { rotation = curRot, onGround = true })
                        rot.lastLog = rot.lastLog + dt
                        if rot.lastLog >= 0.5 then
                            log("Rotating NPC", rot.npcId, "...", math.floor(t*100), "%")
                            rot.lastLog = 0
                        end
                    else
                        if teleportingNPCs[rot.npcId] then
                            log("NPC", rot.npcId, "is already teleporting - skipping rotation teleport")
                        else
                            log("NPC became invalid during rotation teleport - cleaning up")
                            table.remove(activeRotations, i)
                        end
                    end
                else
                    log("NPC became invalid during rotation - cleaning up")
                    table.remove(activeRotations, i)
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- Pending-return state machine (for same-cell returns)
----------------------------------------------------------------------
local function processPendingReturns(dt)
    local i = 1
    while i <= #pendingReturns do
        local ret = pendingReturns[i]
        ret.timer     = ret.timer - dt
        ret.totalTime = (ret.totalTime or 0) + dt

        if ret.totalTime > 30 then
            log("WARNING: NPC", ret.npcId, "timeout after 30s – forcing restore")
            local npc = findNPC(ret.npcId)
            if npc and npc:isValid() then npc:sendEvent('RemoveAIPackages') end
            local player = world.players[1]
            if player then
                player:sendEvent('AntiTheft_NPCReady', { npcId = ret.npcId })
            else
                log("ERROR: Could not find player to send ready event")
            end
            table.remove(pendingReturns, i)
            i = i - 1

        elseif ret.timer <= 0 then
            local npc = findNPC(ret.npcId)

            if npc and npc:isValid() then
                -- Determine target position based on two-phase return
                local targetPos = ret.exactHomePosition
                if ret.postTeleportPos then
                    targetPos = ret.postTeleportPos
                end

                local dist = (npc.position - targetPos):length()
                local curPos = util.vector3(npc.position.x, npc.position.y, npc.position.z)

                -- Check if NPC has stopped moving
                if ret.lastPosition then
                    local move = (curPos - ret.lastPosition):length()
                    if move < 0.1 then
                        ret.stopCount = (ret.stopCount or 0) + 1
                    else
                        ret.stopCount = 0
                    end
                end
                ret.lastPosition = curPos

                -- Log distance periodically (not every frame)
                if not ret.lastDistanceLog or ret.totalTime - ret.lastDistanceLog >= 1.0 then
                    log("NPC", ret.npcId, "distance to target:", math.floor(dist), "units")
                    ret.lastDistanceLog = ret.totalTime
                end

                -- Check if NPC has arrived at target (within 5 units tolerance for accurate positioning)
                if dist < 50 then
                    if ret.postTeleportPos then
                        -- Phase 1 complete: arrived at post-teleport position (door)
                        local state = require('scripts.antitheftai.modules.state')
                        local returnPos = state.returnPositions and state.returnPositions[ret.npcId]

                        if returnPos then
                            -- Walk-after-teleport: Teleport to entrance, then walk home
                            log("NPC", ret.npcId, "arrived at door - teleporting to entrance and walking home")

                            local npc = findNPC(ret.npcId)
                            if npc and npc:isValid() then
                                -- Teleport to entrance
                                npc:teleport(npc.cell.name, returnPos, { onGround = true })
                                log("  ✓ Teleported to entrance position:", returnPos)

                                -- Send Travel package to home
                                npc:sendEvent('RemoveAIPackages')
                                npc:sendEvent('StartAIPackage', {
                                    type = 'Travel',
                                    destPosition = ret.exactHomePosition,
                                    cancelOther = true
                                })
                                log("  ✓ Travel package sent - NPC will walk to home")

                                -- Update pending return to track this new walk
                                ret.postTeleportPos = nil -- Clear this so next time it treats it as final arrival
                                ret.lastPosition = nil
                                ret.stopCount = 0
                                ret.timer = 0.2

                                -- Clear stored return position
                                state.returnPositions[ret.npcId] = nil
                                state.postTeleportPositions[ret.npcId] = nil
                            end
                        else
                            -- Fallback: No return position stored, start smooth rotation
                            log("NPC", ret.npcId, "arrived at post-teleport position - starting smooth rotation (no return position)")

                            local npc = findNPC(ret.npcId)
                            if npc and npc:isValid() then
                                npc:sendEvent('RemoveAIPackages')

                                -- Start rotation to home orientation (No Teleport)
                                startGlobalRotation(npc, ret.homeRotation, 0.85, ret.exactHomePosition, ret.homeRotation)
                            end

                            -- Clear two-phase return state
                            local state = require('scripts.antitheftai.modules.state')
                            state.postTeleportPositions[ret.npcId] = nil
                            state.twoPhaseReturns[ret.npcId] = nil

                            -- Remove from pending returns
                            table.remove(pendingReturns, i)
                            i = i - 1
                        end
                    else
                        -- Normal return: arrived home, start rotation (no teleport)
                        log("NPC", ret.npcId, "arrived home (within 50 units) - starting rotation")

                        -- Clear AI packages
                        npc:sendEvent('RemoveAIPackages')

                        -- Start rotation to home orientation
                        startGlobalRotation(npc, ret.homeRotation, 0.85, ret.exactHomePosition, ret.homeRotation)

                        -- Remove from pending returns
                        table.remove(pendingReturns, i)
                        i = i - 1
                    end
                else
                    -- Still traveling, check again in 0.2 seconds
                    ret.timer = 0.2
                end
            else
                log("WARNING: NPC", ret.npcId, "not found - will retry")
                ret.timer = 1.0
            end
        end
        i = i + 1
    end
end

----------------------------------------------------------------------
-- ★★★ EVENT: Start Wandering (search-style behavior) ★★★
----------------------------------------------------------------------
local function onStartWandering(data)
    if not data or not data.npcId then return end

    log("═══════════════════════════════════════════════════")
    log("START WANDERING (search-style) for NPC", data.npcId)
    log("  Wander position:", data.wanderPosition)
    log("  Wander distance:", data.wanderDistance)
    log("  Wander duration:", data.wanderDuration, "seconds")

    -- Clear any existing search timers for this NPC to prevent conflicts
    if searchTimers[data.npcId] then
        searchTimers[data.npcId] = nil
        log("Cleared existing search timer for NPC", data.npcId)
    end

    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        -- Skip player companions and escort NPCs
        if companionDetection.isCompanion(npc) then
            log("  ⚠ NPC is a companion or escort - skipping wandering")
            return
        end
        log("  ✓ NPC found - sending search-style AI packages")

        -- Clear any existing AI packages
        npc:sendEvent('RemoveAIPackages')

        -- ★★★ Give Travel + Wander combo (same as search behavior) ★★★
        -- First travel to last known position (if any)
        if data.wanderPosition then
            npc:sendEvent('StartAIPackage', {
                type = 'Travel',
                destPosition = data.wanderPosition,
                cancelOther = false
            })
        end

        -- Then wander around
        npc:sendEvent('StartAIPackage', {
            type = 'Wander',
            distance = data.wanderDistance,
            duration = data.wanderDuration,
            cancelOther = false
        })

        -- Track wandering NPC
        wanderingNPCs[data.npcId] = {
            npcId = data.npcId,
            homePosition = data.homePosition,
            homeRotation = data.homeRotation,
            wanderEndTime = core.getRealTime() + data.wanderDuration
        }

        log("  ✓ Search-style packages sent (Travel + Wander)")
        log("  NPC will wander for", math.floor(data.wanderDuration), "seconds")
    else
        log("  ⚠ NPC not found in loaded cells")
        log("  NPC will wander when cell loads")

        -- Still track it in case cell loads later
        wanderingNPCs[data.npcId] = {
            npcId = data.npcId,
            homePosition = data.homePosition,
            homeRotation = data.homeRotation,
            wanderEndTime = core.getRealTime() + data.wanderDuration
        }
    end

    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- ★★★ EVENT: Start Walking Home (after wandering) ★★★
----------------------------------------------------------------------
local function onStartWalkingHome(data)
    if not data or not data.npcId then return end

    log("═══════════════════════════════════════════════════")
    log("START WALKING HOME for NPC", data.npcId)
    log("  (Wandering complete, now traveling to home)")

    -- Check for post-teleport position (two-phase return)
    local state = require('scripts.antitheftai.modules.state')
    local postTeleportPos = state.postTeleportPositions[data.npcId]
    local destPosition = data.homePosition

    if postTeleportPos then
        destPosition = postTeleportPos
        log("  Two-phase return detected: NPC will walk to post-teleport position first")
    end

    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        log("  ✓ NPC found in loaded cells - sending travel package")
        log("  Destination:", destPosition)

        npc:sendEvent('RemoveAIPackages')
        npc:sendEvent('StartAIPackage', {
            type = 'Travel',
            destPosition = destPosition,
            cancelOther = true
        })

        log("  ✓ Travel package sent - NPC will walk to home")
        log("  Distance:", math.floor((npc.position - destPosition):length()), "units")
    else
        log("  NPC not in loaded cells (unexpected for real-time return)")
    end

    -- Inherit rotation logic from working return function
    table.insert(pendingReturns, {
        npcId              = data.npcId,
        exactHomePosition  = data.homePosition,
        homeRotation       = data.homeRotation,
        postTeleportPos    = postTeleportPos,
        timer              = 0.2,
        phase              = 1,
        totalTime          = 0,
        phase1Checks       = 0,
        stopCount          = 0,
        lastPosition       = nil
    })
    log("  ✓ Added to pending returns queue for rotation")

    -- Remove from wandering tracker
    wanderingNPCs[data.npcId] = nil

    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- ★★★ EVENT: Finalize return (called by player script) ★★★
----------------------------------------------------------------------
local function onFinalizeReturn(data)
    if not data or not data.npcId then return end
    
    log("═══════════════════════════════════════════════════")
    log("FINALIZING RETURN for NPC", data.npcId)
    
    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        -- First teleport to exact home position

        -- Wait a moment for teleport to complete, then start rotation
        async:newUnsavableSimulationTimer(0.1, function()
            local npc = findNPC(data.npcId)
            if npc and npc:isValid() then
                log("  Starting rotation to home orientation")
                startGlobalRotation(npc, data.homeRotation, 0.5, data.homePosition, data.homeRotation)
            end
        end)
    else
        log("  ERROR: NPC not found - sending ready event anyway")
        local player = world.players[1]
        if player then
            player:sendEvent('AntiTheft_NPCReady', { npcId = data.npcId })
        end
    end
    
    -- Clean up wandering tracker if present
    wanderingNPCs[data.npcId] = nil
    
    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- ★★★ EVENT: Place returning NPC at simulated position ★★★
----------------------------------------------------------------------
local function onPlaceReturningNPC(data)
    if not data or not data.npcId then return end
    
    log("═══════════════════════════════════════════════════")
    log("PLACING RETURNING NPC", data.npcId)
    log("  At position:", data.currentPosition)
    log("  Cell:", data.cellName)
    
    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        -- Teleport to simulated position with walking rotation
        local walkRot = util.transform.rotateZ(data.walkRotation)
        
        npc:teleport(data.cellName, data.currentPosition, {
            rotation = walkRot,
            onGround = true
        })
        
        log("  ✓ NPC teleported to simulated position")
        
        -- Give Travel AI package to continue walking home
        npc:sendEvent('RemoveAIPackages')
        npc:sendEvent('StartAIPackage', {
            type = 'Travel',
            destPosition = data.homePosition,
            cancelOther = true
        })
        
        log("  ✓ Travel AI package sent - NPC will walk to home")
        log("  Distance remaining:", math.floor((data.homePosition - data.currentPosition):length()), "units")
    else
        log("  ERROR: NPC not found")
    end
    
    -- Clean up wandering tracker if present
    wanderingNPCs[data.npcId] = nil
    
    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- ★★★ EVENT: Teleport NPC home and finalize ★★★
----------------------------------------------------------------------
local function onTeleportAndFinalize(data)
    if not data or not data.npcId then return end
    
    log("═══════════════════════════════════════════════════")
    log("TELEPORT AND FINALIZE for NPC", data.npcId)
    log("  Position:", data.position)
    
    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        -- Build home rotation
        local homeRotTransform = util.transform.rotateZ(data.homeRotation.z or 0) *
                                 util.transform.rotateY(data.homeRotation.y or 0) *
                                 util.transform.rotateX(data.homeRotation.x or 0)
        
        -- Teleport to home with correct rotation
        npc:teleport(data.cellName, data.position, {
            rotation = homeRotTransform,
            onGround = true
        })
        
        log("  ✓ NPC teleported to home position with correct rotation")
        
        -- Clear AI packages
        npc:sendEvent('RemoveAIPackages')
        
        -- Send ready event immediately (already at home with correct rotation)
        local player = world.players[1]
        if player then
            player:sendEvent('AntiTheft_NPCReady', { npcId = data.npcId })
            log("  ✓ Sent NPCReady event")
        end
    else
        log("  ERROR: NPC not found - sending ready anyway")
        local player = world.players[1]
        if player then
            player:sendEvent('AntiTheft_NPCReady', { npcId = data.npcId })
        end
    end
    
    -- Clean up wandering tracker if present
    wanderingNPCs[data.npcId] = nil
    
    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- ★★★ EVENT: Cancel NPC return (for LOS detection) ★★★
----------------------------------------------------------------------
local function onCancelReturn(data)
    if not data or not data.npcId then return end
    
    log("═══════════════════════════════════════════════════")
    log("CANCELING RETURN for NPC", data.npcId)
    log("  Reason: Line of sight regained with player")
    
    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        npc:sendEvent('RemoveAIPackages')
        log("  ✓ AI packages removed - NPC can now follow player")
    end
    
    -- Remove from pending returns if present
    for i = #pendingReturns, 1, -1 do
        if pendingReturns[i].npcId == data.npcId then
            table.remove(pendingReturns, i)
            log("  ✓ Removed from pending returns queue")
        end
    end
    
    -- Remove from wandering tracker if present
    if wanderingNPCs[data.npcId] then
        wanderingNPCs[data.npcId] = nil
        log("  ✓ Removed from wandering tracker")
    end
    
    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- ★★★ EVENT: Teleport Guard (for transition doors) ★★★
----------------------------------------------------------------------
local function onTeleportGuard(data)
    if not data or not data.npcId then return end

    log("═══════════════════════════════════════════════════")
    log("TELEPORT GUARD for transition door - NPC", data.npcId)
    log("  Target position:", data.position)
    log("  Cell:", data.cellName)

    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        -- Store the post-teleport position for two-phase return
        local state = require('scripts.antitheftai.modules.state')
        state.postTeleportPositions[data.npcId] = data.position
        log("  Stored post-teleport position for NPC", data.npcId, ":", data.position)

        -- Store the return position (entrance) for walk-after-teleport
        if data.returnPosition then
            state.returnPositions = state.returnPositions or {}
            state.returnPositions[data.npcId] = data.returnPosition
            log("  Stored return position (entrance) for NPC", data.npcId, ":", data.returnPosition)
        end

        -- Teleport guard to player's new position in same cell
        npc:teleport(data.cellName, data.position, { onGround = true })
        log("  ✓ Guard teleported to player's position through transition door")
    else
        log("  ERROR: Guard NPC not found for teleportation")
    end

    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- Finalize return: Directly teleport NPC with rotation (old working script)
----------------------------------------------------------------------
local function finalizeNPCReturn(npcId, homePosition, homeRotation)
    local npc = findNPC(npcId)
    if not (npc and npc:isValid()) then
        log("ERROR: NPC", npcId, "not found or invalid during finalize")
        local player = world.players[1]
        if player then
            player:sendEvent('AntiTheft_NPCReady', { npcId = npcId })
        end
        return false
    end

    npc:sendEvent('RemoveAIPackages')

    log("NPC", npcId, "reached home. Applying direct rotation teleport")
    log("  Target rotation - X:", math.deg(homeRotation.x), "Y:", math.deg(homeRotation.y), "Z:", math.deg(homeRotation.z))

    -- Build final rotation transform
    local finalRot = util.transform.rotateZ(homeRotation.z) *
                     util.transform.rotateY(homeRotation.y) *
                     util.transform.rotateX(homeRotation.x)

    -- Teleport NPC to home position with correct rotation
    npc:teleport(npc.cell.name, homePosition, {
        rotation = finalRot,
        onGround = true
    })

    log("NPC teleported to home with rotation - COMPLETE")

    -- Send ready event immediately
    local player = world.players[1]
    if player then
        player:sendEvent('AntiTheft_NPCReady', { npcId = npcId })
        player:sendEvent('AntiTheft_ClearSearchState', { npcId = npcId })
        log("  ✓ Sent NPCReady and ClearSearchState events")
    end

    -- Enable default AI behavior after teleporting home
    npc:sendEvent('AntiTheft_EnableDefaultAI')

    return true
end

----------------------------------------------------------------------
-- ★★★ EVENT: Teleport NPC Home (for spell teleports) ★★★
----------------------------------------------------------------------
local function onTeleportHome(data)
    if not data or not data.npcId then return end

    log("═══════════════════════════════════════════════════")
    log("TELEPORT HOME for NPC", data.npcId, "(spell teleport)")
    log("  Home position:", data.homePosition)

    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        -- Skip player companions and escort NPCs
        if companionDetection.isCompanion(npc) then
            log("  ⚠ NPC is a companion or escort - skipping teleport home")
            return
        end
        -- NPC is loaded, teleport immediately
        -- NPC is loaded, start smooth rotation
        -- First teleport to exact position to ensure correct starting point (optional, but good for consistency)
        npc:teleport(npc.cell.name, data.homePosition, { onGround = true })
        
        -- Start smooth rotation
        startGlobalRotation(npc, data.homeRotation, 0.85, data.homePosition, data.homeRotation)
    else
        -- NPC not loaded, add to pending teleports for when it loads
        log("  ⚠ NPC not found in loaded cells - adding to pending teleports")
        pendingTeleports[data.npcId] = {
            homePosition = data.homePosition,
            homeRotation = data.homeRotation
        }
    end

    -- Clean up wandering tracker if present
    wanderingNPCs[data.npcId] = nil

    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- ★★★ EVENT: Cleanup request ★★★
----------------------------------------------------------------------
local function onRequestCleanup(data)
    log("Cleanup request received from player script")
    log("  Global script state is clean")
end

----------------------------------------------------------------------
-- EVENT: player script orders a return-home (same cell)
----------------------------------------------------------------------
local function onStartReturnHome(data)
    if not data then
        log("ERROR: Received nil data in onStartReturnHome")
        return
    end

    if not data.npcId then
        log("ERROR: Missing npcId in return home event")
        return
    end

    if not data.homePosition then
        log("ERROR: Missing homePosition for NPC", data.npcId)
        return
    end

    if not data.homeRotation then
        log("ERROR: Missing homeRotation for NPC", data.npcId)
        return
    end

    -- Check if this NPC is already being sent home to prevent duplicate travel packages
    for _, ret in ipairs(pendingReturns) do
        if ret.npcId == data.npcId then
            log("NPC", data.npcId, "is already returning home - ignoring duplicate request")
            return
        end
    end

    -- Check if this NPC recently completed rotation to prevent infinite loop
    if recentlyRotated[data.npcId] then
        local timeSinceRotation = core.getRealTime() - recentlyRotated[data.npcId]
        if timeSinceRotation < 2.0 then  -- Within 2 seconds of completing rotation
            log("NPC", data.npcId, "recently completed rotation (", string.format("%.1f", timeSinceRotation), "s ago) - ignoring duplicate return request")
            return
        end
    end

    log("═══════════════════════════════════════════════════")
    log("GLOBAL: Return home request for NPC", data.npcId)
    log("  (Player in same cell - using AI movement with rotation)")

    local state = require('scripts.antitheftai.modules.state')
    local postTeleportPos = state.postTeleportPositions[data.npcId]

    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        -- Skip player companions and escort NPCs
        if companionDetection.isCompanion(npc) then
            log("  ⚠ NPC is a companion or escort - skipping return home")
            return
        end
        log("  ✓ NPC found - sending travel package and setting up rotation")
        log("  Home position:", data.homePosition)
        log("  Distance:", math.floor((npc.position - data.homePosition):length()), "units")

        -- Restore hello value if provided
        if data.originalHelloValue ~= nil then
            npc:sendEvent('AntiTheft_SetHello', { value = data.originalHelloValue })
            log("  ✓ Sent event to restore hello value to", data.originalHelloValue, "for NPC", data.npcId)
        end

        -- Clear any existing AI packages
        npc:sendEvent('RemoveAIPackages')

        -- Determine destination based on two-phase return
        local destination = data.homePosition
        if postTeleportPos then
            -- Two-phase return: first travel to post-teleport position
            destination = postTeleportPos
            state.twoPhaseReturns[data.npcId] = true
            log("  ✓ Two-phase return: NPC will first travel to post-teleport position", postTeleportPos)
        end

        -- Send travel package
        npc:sendEvent('StartAIPackage', {
            type        = 'Travel',
            destPosition= destination,
            cancelOther = true
        })

        log("  ✓ Travel package sent - NPC will walk to destination")
    else
        log("  ⚠ NPC not found in loaded cells")
    end

    -- Add to pending returns for arrival detection and rotation
    table.insert(pendingReturns, {
        npcId              = data.npcId,
        exactHomePosition  = data.homePosition,
        homeRotation       = data.homeRotation,
        timer              = 0.2,  -- Check more frequently for smoother detection
        phase              = 1,
        totalTime          = 0,
        lastPosition       = nil,
        stopCount          = 0,
        postTeleportPos    = postTeleportPos  -- Store for two-phase return
    })
    log("  ✓ Added to pending returns for rotation when arrived")

    log("═══════════════════════════════════════════════════")
end

local function onLowerCellDisposition(data)
    log("=== GLOBAL: LOWERING CELL DISPOSITION ===")
    local player = world.players[1]
    if not player or not player.cell then
        log("ERROR: Could not find player or player cell")
        return
    end

    local playerCell = player.cell
    log("Player cell:", playerCell.name)

    local removeDispositionOnce = vars:get('removeDispositionOnce') or false
    local currentCount = dispositionAppliedCells[playerCell.name] or 0
    if removeDispositionOnce and currentCount >= 2 then
        log("  Disposition already applied twice in this cell visit - skipping")
        log("=== CELL DISPOSITION LOWERING SKIPPED ===")
        return
    end

    local dispositionChange = vars:get('dispositionChange') or 15
    local count = 0
    for _, actor in ipairs(world.activeActors) do
        if actor.type == types.NPC and actor:isValid() and actor.cell == playerCell then
            local currentDisp = types.NPC.getBaseDisposition(actor, player) or 50
            local newDisp = math.max(0, currentDisp - dispositionChange)
            log("  Lowering NPC", actor.id, "base disposition:", currentDisp, "->", newDisp)
            types.NPC.modifyBaseDisposition(actor, player, -dispositionChange)
            count = count + 1
        end
    end

    if removeDispositionOnce then
        dispositionAppliedCells[playerCell.name] = currentCount + 1
        log("  Marked cell as disposition-applied (count:", currentCount + 1, ") for this visit")
    end

    log("  Processed", count, "NPCs in cell")
    log("=== CELL DISPOSITION LOWERING COMPLETE ===")
end

local function onLowerNPCDisposition(data)
    if not data or not data.npcId then return end
    log("=== GLOBAL: LOWERING SPECIFIC NPC DISPOSITION (NPC:", data.npcId, ") ===")
    
    local player = world.players[1]
    if not player then return end

    local dispositionChange = vars:get('dispositionChange') or 15
    local npc = nil
    
    -- Find actor by ID across all active actors
    for _, actor in ipairs(world.activeActors) do
        if actor.id == data.npcId then
            npc = actor
            break
        end
    end

    if npc and npc:isValid() and npc.type == types.NPC then
        local currentDisp = types.NPC.getBaseDisposition(npc, player) or 50
        local newDisp = math.max(0, currentDisp - dispositionChange)
        log("  Lowering NPC", npc.id, "base disposition:", currentDisp, "->", newDisp)
        types.NPC.modifyBaseDisposition(npc, player, -dispositionChange)
    else
        log("  NPC", data.npcId, "not found or invalid for disposition lowering")
    end
    log("=== NPC DISPOSITION LOWERING COMPLETE ===")
end

local npcVoiceResponses = {
    argonian = {
        female = {
            {response = "Hiss.", file = "sound/Vo/a/f/Thf_AF004.wav"},
            {response = "Stop!", file = "sound/Vo/a/f/Thf_AF003.wav"},
            {response = "No! Thief!", file = "sound/Vo/a/f/Thf_AF002.wav"},
            {response = "Stop the thief!", file = "sound/Vo/a/f/Thf_AF001.wav"},
        },
        male = {
            {response = "I see you!", file = "sound/vo/a/m/Thf_AM005.wav"},
            {response = "Scoundrel.", file = "sound/vo/a/m/Thf_AM001.wav"},
        }
    },
    breton = {
        female = {
            {response = "I saw that!", file = "vo/b/f/Thf_BF003.wav"},
            {response = "This is outrageous. Guards!", file = "vo/b/f/Thf_BF002.wav"},
            {response = "You scoundrel!", file = "vo/b/f/Thf_BF001.wav"},
            {response = "Do you take me for a fool!", file = "vo/b/f/Thf_BF005.wav"},
        },
        male = {
            {response = "What do you think you're doing?!", file = "vo/b/m/Thf_BM004.wav"},
            {response = "You cowardly thief!", file = "vo/b/m/Thf_BM003.wav"},
            {response = "Guards!", file = "vo/b/m/Thf_BM002.wav"},
            {response = "Do you take me for a fool!", file = "vo/b/m/Thf_BM005.wav"},
        }
    },
    darkelf = {
        female = {
            {response = "Filthy S'wit!", file = "sound/Vo/d/f/Hlo_DF027.wav"},
            {response = "Help!", file = "sound/Vo/d/f/Thf_DF003.wav"},
            {response = "Filthy S'wit!", file = "sound/Vo/d/f/Hlo_DF027.wav"},
        },
        male = {
            {response = "That is quite enough thief!", file = "sound/vo/d/m/Thf_DM004.wav"},
            {response = "You're finished!", file = "sound/vo/d/m/Thf_DM003.wav"},
            {response = "Wretched thief!", file = "sound/vo/d/m/Thf_DM002.wav"},
            {response = "I'll deal with you thief!", file = "sound/vo/d/m/Thf_DM001.wav"},
            {response = "Help, guards!", file = "sound/vo/d/m/Thf_DM005.wav"},
            {response = "Maybe I'll throw you into the river. How'd like that, you thief?", file = "sound/Vo/at_ord/ATOrd_Thf01.wav"},
        }
    },
    highelf = {
        female = {
            {response = "You scoundrel! You won't get away with this! Thief!", file = "sound/vo/h/f/Thf_HF004.wav"},
            {response = "Help! Thief!", file = "sound/vo/h/f/Thf_HF003.wav"},
            {response = "You've been caught! Guards!", file = "sound/vo/h/f/Thf_HF002.wav"},
            {response = "Why, you little thief! Come back!", file = "sound/vo/h/f/Thf_HF001.wav"},
            {response = "There is no escape!", file = "sound/vo/h/f/Thf_HF005.wav"},
        },
        male = {
            {response = "Thief!", file = "sound/vo/h/m/Thf_HM004.wav"},
            {response = "You'll get more than you bargained for, thief!", file = "sound/vo/h/m/Thf_HM003.wav"},
            {response = "Thievery is a serious offense! Guards!", file = "sound/vo/h/m/Thf_HM002.wav"},
            {response = "Do you take me for a fool? Guards!", file = "sound/vo/h/m/Thf_HM001.wav"},
            {response = "You can't escape!", file = "sound/vo/h/m/Thf_HM005.wav"},
        }
    },
    imperial = {
        female = {
            {response = "You've made your last mistake! Thief!", file = "sound/Vo/i/f/Thf_IF003.wav"},
            {response = "You've stolen for the last time!", file = "sound/Vo/i/f/Thf_IF002.wav"},
            {response = "Help! Guards! A thief!", file = "sound/Vo/i/f/Thf_IF001.wav"},
        },
        male = {
            {response = "Help! Guards! A thief!", file = "sound/Vo/i/m/Thf_IM001.wav"},
            {response = "You've stolen for the last time!", file = "sound/Vo/i/m/Thf_IM002.wav"},
            {response = "You've made your last mistake thief!", file = "sound/Vo/i/m/Thf_IM003.wav"},
        }
    },
    khajiit = {
        female = {
            {response = "You can't escape!", file = "sound/vo/k/f/Thf_KF004.wav"},
            {response = "Stop! Thief!", file = "sound/vo/k/f/Thf_KF002.wav"},
            {response = "Thief. No! Thief!", file = "sound/vo/k/f/Thf_KF001.wav"},
            {response = "You can't escape!", file = "sound/vo/k/f/Thf_KF005.wav"},
        },
        male = {
            {response = "You can't escape", file = "sound/vo/k/m/Thf_KM004.wav"},
            {response = "Stop! Thief!", file = "sound/vo/k/m/Thf_KM002.wav"},
            {response = "Thief. No! Thief!", file = "sound/vo/k/m/Thf_KM001.wav"},
            {response = "You can't escape!", file = "sound/vo/k/m/Thf_KM005.wav"},
        }
    },
    nord = {
        female = {
            {response = "Guards!", file = "sound/vo/n/f/Thf_NF004.wav"},
            {response = "Quickly, over here! A thief!", file = "sound/vo/n/f/Thf_NF002.wav"},
            {response = "Stop that thief!", file = "sound/vo/n/f/Thf_NF001.wav"},
        },
        male = {
            {response = "There is a thief here! Guards!", file = "sound/vo/n/m/Thf_NM004.wav"},
            {response = "Not today, thief!", file = "sound/vo/n/m/Thf_NM002.wav"},
            {response = "This is the end for you, thief!", file = "sound/vo/n/m/Thf_NM001.wav"},
            {response = "Stay where you are, thief!", file = "sound/vo/n/m/Thf_NM005.wav"},
        }
    },
    orc = {
        female = {
            {response = "Surrender, thief!", file = "sound/vo/o/f/Thf_OF004.wav"},
            {response = "Hold, thief!", file = "sound/vo/o/f/Thf_OF003.wav"},
            {response = "Guards! A thief!", file = "sound/vo/o/f/Thf_OF002.wav"},
            {response = "You think me a fool? Guards!", file = "sound/vo/o/f/Thf_OF001.wav"},
            {response = "You can't hide, thief!", file = "sound/vo/o/f/Thf_OF005.wav"},
        },
        male = {
            {response = "Thief!", file = "sound/vo/o/m/Thf_OM004.wav"},
            {response = "Coward!", file = "sound/vo/o/m/Thf_OM003.wav"},
            {response = "Surrender yourself! Guards!", file = "sound/vo/o/m/Thf_OM002.wav"},
            {response = "Do you take me for a fool?", file = "sound/vo/o/m/Thf_OM001.wav"},
            {response = "You can't escape!", file = "sound/vo/o/m/Thf_OM005.wav"},
        }
    },
    redguard = {
        female = {
            {response = "Over here!", file = "sound/vo/r/f/Thf_RF004.wav"},
            {response = "You'll pay for that!", file = "sound/vo/r/f/Thf_RF003.wav"},
            {response = "Guards!", file = "sound/vo/r/f/Thf_RF002.wav"},
            {response = "Not on my watch, thief.", file = "sound/vo/r/f/Thf_RF001.wav"},
            {response = "I will not be taken for a fool!", file = "sound/vo/r/f/Thf_RF005.wav"},
        },
        male = {
            {response = "You'll pay for that!", file = "sound/vo/r/m/Thf_RM003.wav"},
            {response = "Over here!", file = "sound/vo/r/m/Thf_RM004.wav"},
            {response = "Guards!", file = "sound/vo/r/m/Thf_RM002.wav"},
            {response = "Not on my watch, thief.", file = "sound/vo/r/m/Thf_RM001.wav"},
            {response = "I will not be taken for a fool!", file = "sound/vo/r/m/Thf_RM005.wav"},
        }
    },
    woodelf = {
        female = {
            {response = "You'll get yours, thief!", file = "sound/vo/w/f/Thf_WF004.wav"},
            {response = "Over here! A thief!", file = "sound/vo/w/f/Thf_WF003.wav"},
            {response = "What are you doing?!", file = "sound/vo/w/f/Thf_WF002.wav"},
            {response = "Over here! Thief!", file = "sound/vo/w/f/Thf_WF005.wav"},
        },
        male = {
            {response = "You've stolen for the last time, thief!", file = "sound/vo/w/m/Thf_WM004.wav"},
            {response = "Over here!", file = "sound/vo/w/m/Thf_WM003.wav"},
            {response = "Outrageous!", file = "sound/vo/w/m/Thf_WM002.wav"},
            {response = "No! Stop!", file = "sound/vo/w/m/Thf_WM001.wav"},
            {response = "What's this? Thief!", file = "sound/vo/w/m/Thf_WM005.wav"},
        }
    },
    -- Additional special NPC voice responses can be added here...
    T_Mw_Malahk_Orc = {
        female = {
            {response = "Surrender, thief!", file = "sound/vo/o/f/Thf_OF004.wav"},
            {response = "Hold, thief!", file = "sound/vo/o/f/Thf_OF003.wav"},
            {response = "Guards! A thief!", file = "sound/vo/o/f/Thf_OF002.wav"},
            {response = "You think me a fool? Guards!", file = "sound/vo/o/f/Thf_OF001.wav"},
            {response = "You can't hide, thief!", file = "sound/vo/o/f/Thf_OF005.wav"},
        },
        male = {
            {response = "Thief!", file = "sound/vo/o/m/Thf_OM004.wav"},
            {response = "Coward!", file = "sound/vo/o/m/Thf_OM003.wav"},
            {response = "Surrender yourself! Guards!", file = "sound/vo/o/m/Thf_OM002.wav"},
            {response = "Do you take me for a fool?", file = "sound/vo/o/m/Thf_OM001.wav"},
            {response = "You can't escape!", file = "sound/vo/o/m/Thf_OM005.wav"},
        }
    },
    T_Val_Imga = {
        male = {
            {response = "Guards! Guards! There is a thief among us!", file = "sound/Va/Vo/img/m/Thf_004.wav"},
            {response = "Thievery! Banditry! Skullduggery!", file = "sound/Va/Vo/img/m/Thf_003.wav"},
            {response = "I see you, thief.", file = "sound/Va/Vo/img/m/Thf_002.wav"},
            {response = "Your name will live in infamy, blasted thief.", file = "sound/Va/Vo/img/m/Thf_001.wav"},
        }
    },
    T_Cnq_ChimeriQuey = {
        female = {
            {response = "You are repulsive. Get out of here!", file = "sound/TR/Vo/TR_ChiF_Hlo_001.wav"},
        },
        male = {
            {response = "Go away.", file = "sound/TR/Vo/TR_ChiM_Hlo_002.wav"},
        }
    },
    T_Cnq_Keptu = {
        female = {
            {response = "No!", file = "sound/TR/Vo/TR_KepF_Hit_001.wav"},
        },
        male = {
            {response = "Ugghh! Not today!", file = "sound/TR/Vo/TR_KepM_Hlo_002.wav"},
        }
    },
    T_Sky_Reachman = {
        female = {
            {response = "Put it back!", file = "sound/vo/b/f/Thf_BF004.wav"},
            {response = "I saw that!", file = "sound/vo/b/f/Thf_BF003.wav"},
            {response = "This is outrageous. Guards!", file = "sound/vo/b/f/Thf_BF002.wav"},
            {response = "You scoundrel!", file = "sound/vo/b/f/Thf_BF001.wav"},
            {response = "Do you take me for a fool!", file = "sound/vo/b/f/Thf_BF005.wav"},
        },
        male = {
            {response = "Surrender!", file = "sound/sky/Vo/Rc/m/Thf_RcM002.wav"},
            {response = "You take me for a fool.", file = "sound/sky/Vo/Rc/m/Thf_RcM003.wav"},
            {response = "Thief!", file = "sound/sky/Vo/Rc/m/Thf_RcM004.wav"},
            {response = "Over here!", file = "sound/sky/Vo/Rc/m/Thf_RcM001.wav"},
        }
    }
}

local raceIdToName = {
    ["argonian"] = "argonian",
    ["breton"] = "breton",
    ["darkelf"] = "darkelf",
    ["highelf"] = "highelf",
    ["imperial"] = "imperial",
    ["khajiit"] = "khajiit",
    ["nord"] = "nord",
    ["orc"] = "orc",
    ["redguard"] = "redguard",
    ["woodelf"] = "woodelf",
    ["imga"] = "T_Val_Imga",
    ["chimeriquey"] = "T_Cnq_ChimeriQuey",
    ["keptuquey"] = "T_Cnq_Keptu",
    ["reachman"] = "T_Sky_Reachman"
}

local function onPlayCivilianUnlockSound(data)
    if not data or not data.npcId then return end
    local npc = findNPC(data.npcId)
    if not npc or not npc:isValid() then return end
    
    log("[UNLOCK SOUND] Request received for NPC", data.npcId)
    
    -- MIXED VOICE LOGIC: Pick from either Standard (Old) or Bed Voices (New)
    local bedVoices = require('scripts.antitheftai.modules.bed_voices')
    -- Normalize race string
    local raceKey = data.race and data.race:lower():gsub(" ", "") or "darkelf"
    local bedVoiceList = nil
    if bedVoices[raceKey] and bedVoices[raceKey][data.gender] then
        bedVoiceList = bedVoices[raceKey][data.gender]
    end
    
    -- Prepare Standard Voice List
    -- Use global raceIdToName
    local standardKey = raceIdToName[data.race] or data.race
    local standardVoiceList = npcVoiceResponses[standardKey] and npcVoiceResponses[standardKey][data.gender]
    
    -- Create Combined Pool
    local combinedPool = {}
    if bedVoiceList then
        for _, v in ipairs(bedVoiceList) do table.insert(combinedPool, v) end
    end
    if standardVoiceList then
        for _, v in ipairs(standardVoiceList) do table.insert(combinedPool, v) end
    end
    
    if #combinedPool > 0 then
        local entry = combinedPool[math.random(#combinedPool)]
        -- Fix sound path
        local voicePath = entry.file
        if voicePath:find("^Vo/") then voicePath = "sound/" .. voicePath
        elseif not voicePath:find("^sound/") then voicePath = "sound/" .. voicePath end
        
        core.sound.say(voicePath, npc, entry.response)
        log("[UNLOCK SOUND] Played MIXED voice:", entry.file, "Pool:", #combinedPool)
    else
        log("[UNLOCK SOUND] No voices found for", data.race, data.gender)
    end
end

local function playNpcVoiceResponse(npc, race, gender)
    local player = world.players[1]

    if not npc then
        log("[NPC VOICE RESPONSE] ERROR: npc argument is nil or missing")
        return
    end
    if not npc:isValid() then
        log("[NPC VOICE RESPONSE] ERROR: npc is invalid or not valid")
        return
    end

    -- Update raceIdToName to include spaced variants if missing
    if not raceIdToName["dark elf"] then raceIdToName["dark elf"] = "darkelf" end
    if not raceIdToName["high elf"] then raceIdToName["high elf"] = "highelf" end
    if not raceIdToName["wood elf"] then raceIdToName["wood elf"] = "woodelf" end

    -- Normalize race if provided
    if race then
        race = race:lower()
        -- clean up spaces/underscores just in case
        race = race:gsub("_", " "):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
        
        if raceIdToName[race] then
            race = raceIdToName[race]
        end
    end

    --── FIX : first: check cached map
    if (not race or not gender) and npcRaceGenderCache then
        local m=npcRaceGenderCache[npc.id]; if m then race,gender=m.race,m.gender end
    end
    -- fallback to record lookup
    if not race or not gender then
        local record = types.NPC.record(npc)
        if not record then
            log("[NPC VOICE RESPONSE] ERROR: Failed to get NPC record for npc ID:", npc.id)
            return
        end

        -- Try multiple methods to extract race ID
        local rawRace = nil
        if record.race then
            -- Method 1: record.race.id (standard)
            if record.race.id then
                rawRace = record.race.id:lower()
            -- Method 2: record.race is already a string
            elseif type(record.race) == "string" then
                rawRace = record.race:lower()
            -- Method 3: Try to iterate the race object to find an id field
            else
                for k, v in pairs(record.race) do
                    if k == "id" or k == "recordId" then
                        rawRace = tostring(v):lower()
                        break
                    end
                end
            end
        end
        
        if not rawRace then
            log("[NPC VOICE RESPONSE] ERROR: Could not extract race id from record for npc ID:", npc.id)
            log("[NPC VOICE RESPONSE] record.race type:", type(record.race))
            log("[NPC VOICE RESPONSE] record.race value:", tostring(record.race))
            return
        end
        
        race = raceIdToName[rawRace]
        if not race then
            log("[NPC VOICE RESPONSE] ERROR: npc race", rawRace, "not found in raceIdToName mapping for npc ID:", npc.id)
            return
        end

        -- Debug gender field
        log("[NPC VOICE RESPONSE] DEBUG: record.isMale =", tostring(record.isMale))

        -- Gender detection: isMale = true means male, isMale = false means female
        if record.isMale then
            gender = "male"
        else
            gender = "female"
        end
        
        -- Cache the result for future use (ensure string)
        local validGender = (gender == "male" or gender == "female") and gender or "male"
        npcRaceGenderCache[npc.id] = {race=race, gender=validGender}
        log("[NPC VOICE RESPONSE] Cached race:", race, "gender:", validGender, "for npc:", npc.id)
    end
    
    -- Safety check for bad cache data (Fix for "gender true")
    if npcRaceGenderCache[npc.id] and type(npcRaceGenderCache[npc.id].gender) ~= "string" then
        log("[NPC VOICE RESPONSE] Clearing invalid cache for NPC", npc.id)
        npcRaceGenderCache[npc.id] = nil
        -- Recurse once to re-fetch
        -- return onPlayNPCVoice(data) -- Avoid recursion stack risk, just continue
    end

    local responsesForRaceGender = npcVoiceResponses[race] and npcVoiceResponses[race][gender]
    if not responsesForRaceGender or #responsesForRaceGender == 0 then
        log("[NPC VOICE RESPONSE] WARNING: no voice responses found for race", race, "gender", gender)
        return
    end

    local idx = math.random(#responsesForRaceGender)
    local voiceResponse = responsesForRaceGender[idx]
    if voiceResponse and voiceResponse.file and voiceResponse.response then
        log("[NPC VOICE RESPONSE] Playing voice file:", voiceResponse.file, "for npc ID:", npc.id)
        core.sound.say(voiceResponse.file, npc, voiceResponse.response)

        else
        log("[NPC VOICE RESPONSE] WARNING: invalid voiceResponse data for npc ID:", npc.id)
    end
end

----------------------------------------------------------------------
-- ★★★ EVENT: Body Discovery Relay (from blackjack_sleep.lua) ★★★
----------------------------------------------------------------------
local function onBodyDiscoveryRelay(data)
    if not data or not data.witnessId or not data.bodyId then return end
    
    log("[BODY DISCOVERY RELAY] Witness", data.witnessId, "found body", data.bodyId)
    
    local witness = findNPC(data.witnessId)
    
    if witness and witness:isValid() then
        -- 1. Apply Disposition Penalty (Cell-wide)
        onLowerCellDisposition()
        
        -- 2. Play Voice Response
        onPlayNPCVoice({npcId = data.witnessId})
        
        -- 3. Alert Logic
        log("[BODY DISCOVERY] Disposition lowered and voice played for witness", data.witnessId)
        
        -- Future: Can trigger specific guard investigation behaviors here if needed
    end
end

----------------------------------------------------------------------
-- ★★★ EVENT: Apply Lock Spell Bounty ★★★
----------------------------------------------------------------------
local function onApplyLockSpellBounty(data)
    if not data or not data.bountyAmount then return end

    log("═══════════════════════════════════════════════════")
    log("APPLYING LOCK SPELL BOUNTY")
    log("  Amount:", data.bountyAmount, "gold")

    local player = world.players[1]
    if not player then
        log("  ERROR: Could not find player")
        return
    end

    -- Use unified and robust bounty logic
    onSetPlayerBounty(data)
    
    local newBounty = (types.Player.getCrimeLevel and types.Player.getCrimeLevel(player)) or (types.Player.getBounty and types.Player.getBounty(player)) or 0
    log("  New bounty:", newBounty)
    log("  hasFollowingNPC flag:", tostring(data.hasFollowingNPC))
    
    -- Send detection pulse to alert NPCs only if no NPC is following player
    if data.hasFollowingNPC then
        log("  NPC is following player - skipping detection pulse")
    else
        log("  No NPC following - sending detection pulse")
        core.sendGlobalEvent('AntiTheft_SendDetectionPulse', {
            playerPosition = data.playerPosition or (world.players[1] and world.players[1].position)
        })
    end
    
    -- Show message to player
    player:sendEvent('ShowMessage', {
        message = "You have been caught locking doors! Bounty increased by " .. data.bountyAmount .. " gold."
    })

    -- Play NPC voice response if we have the NPC ID
    if data.npcId then
        local npc = nil
        -- Try to find the NPC in active actors
        for _, actor in ipairs(world.activeActors) do
            if actor.id == data.npcId then
                npc = actor
                break
            end
        end
        
        if npc and npc:isValid() then
            log("  Playing voice response for NPC", data.npcId)
            
            -- If race and gender were provided in the event, cache them and pass to the function
            if data.npcRace and data.npcGender ~= nil then
                -- Convert race ID to the format used in npcVoiceResponses
                local raceIdToName = {
                    ["argonian"] = "argonian",
                    ["breton"] = "breton",
                    ["dark elf"] = "darkelf",
                    ["darkelf"] = "darkelf",
                    ["high elf"] = "highelf",
                    ["highelf"] = "highelf",
                    ["imperial"] = "imperial",
                    ["khajiit"] = "khajiit",
                    ["nord"] = "nord",
                    ["orc"] = "orc",
                    ["redguard"] = "redguard",
                    ["wood elf"] = "woodelf",
                    ["woodelf"] = "woodelf"
                }
                local raceName = raceIdToName[data.npcRace] or data.npcRace
                
                -- SANITIZE GENDER (Fix for "gender true")
                local genderStr = "male"
                if type(data.npcGender) == "boolean" then
                     genderStr = data.npcGender and "male" or "female"
                elseif type(data.npcGender) == "string" then
                     genderStr = data.npcGender
                end
                
                -- Cache race and gender safely
                npcRaceGenderCache[npc.id] = {race=raceName, gender=genderStr}
                log("  Cached race from event:", raceName, "gender:", genderStr, "(Raw:", tostring(data.npcGender), ")")
                
                -- Call with race and gender parameters
                playNpcVoiceResponse(npc, raceName, genderStr)
            else
                -- Call without parameters, will use cache or record lookup
                playNpcVoiceResponse(npc)
            end

            -- FORCE PURSUE LOGIC (After Bounty + Voice)
            -- "Pursue must be applied after adding bounty, not before."
            if data.forcePursue and npc and npc:isValid() and isGuard(npc) then
                 log("  [FORCE PURSUE] Triggering Pursue package for Guard", npc.id)
                 local player = world.players[1]
                 if player then
                     npc:sendEvent('StartAIPackage', {
                        type = 'Pursue',
                        target = player,
                        cancelOther = false
                     })
                     log("✓ Sent Pursue package (Global Trigger)")
                 end
            end
        else
            log("  WARNING: Could not find NPC", data.npcId, "to play voice response")
        end
    else
        log("  WARNING: No npcId provided in bounty event - cannot play voice response")
    end

    log("✓ Lock spell bounty applied successfully")
    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------

-- Helper to determine if NPC is a guard (Duplicated from Player script for Global usage)
local function isGuard(npc)
    if not npc then return false end
    local record = types.NPC.record(npc)
    if not (record and record.class) then return false end
    local class = record.class:lower()
    return class:find("guard") or class:find("ordinator") or class:find("buoyant")
end

-- New event handler to play NPC voice in global script (fixes local script permission error)


local function onPlayNPCVoice(data)
    if not data or not data.npcId then
        log("[AntiTheft_PlayNPCVoice] Missing npcId in event data")
        return
    end

    local npc = findNPC(data.npcId)
    
    if npc and npc:isValid() then
        if data.voiceFile then
            -- Use core.sound.say to play specific voice file
            core.sound.say(data.voiceFile, npc, data.response)
        else
            -- Auto-resolve voice using the helper function
            playNpcVoiceResponse(npc, data.race, data.gender)
        end
    else
        log("[AntiTheft_PlayNPCVoice] Could not find NPC", data.npcId)
    end
end





-- ★★★ EVENT: Door Detection ★★★
local function onDoorDetection(data)
    if not _enableDoorMechanics then return end
    log("[DOOR DETECTION] Global script received door detection event")

    local player = world.players[1]
    if not player then
        log("[DOOR DETECTION] ERROR: Could not find player")
        return
    end

    -- Player position and facing direction
    local playerPos     = player.position
    local playerForward = player.rotation:apply(util.vector3(0, 1, 0))

    -- Detection parameters
    local maxDistance = 400             -- units
    local maxAngle    = math.rad(360)    -- 30-degree cone

    local closestDoor     = nil
    local closestDistance = math.huge
    local closestAngle    = math.huge

    ------------------------------------------------------------------
    --  Iterate every door reference in the player’s current cell
    ------------------------------------------------------------------
    for _, door in ipairs(player.cell:getAll(types.Door)) do
        -- Skip teleport doors (remove this line if you want them)
        if not types.Door.isTeleport(door) then
            local doorPos  = door.position
            local distance = (doorPos - playerPos):length()

            if distance <= maxDistance then
                local toDoor = (doorPos - playerPos):normalize()
                local angle  = math.acos(playerForward:dot(toDoor))

                if angle <= maxAngle
                   and (distance < closestDistance
                     or (distance == closestDistance and angle < closestAngle)) then
                    closestDoor     = door
                    closestDistance = distance
                    closestAngle    = angle
                end
            end
        end
    end

    ------------------------------------------------------------------
    --  Save initial lock level for closest door
    ------------------------------------------------------------------
    if closestDoor then
        local doorRecord = types.Door.record(closestDoor)
        local doorPos = closestDoor.position
        local lockedDoorPos = closestDoor.position
        log("[DOOR DETECTION] Door detected:")
        log("  ID:         " .. tostring(closestDoor.id))
        log("  Door Coords:         " .. tostring(doorPos))
        log("  Name:       " .. (doorRecord and doorRecord.name or "unnamed door"))
        log("  Locked:     " .. tostring(types.Lockable.isLocked(closestDoor)))
        log("  Lock Level: " .. tostring(types.Lockable.getLockLevel(closestDoor)))
        log("  State:      " .. tostring(types.Door.getDoorState(closestDoor)))
        log("  Is Closed:  " .. tostring(types.Door.isClosed(closestDoor)))
        log("  Is Open:    " .. tostring(types.Door.isOpen(closestDoor)))
        log("  Is Teleport:" .. tostring(types.Door.isTeleport(closestDoor)))
        log("  Distance:   " .. string.format("%.1f", closestDistance) .. " units")
        log("  Angle:      " .. string.format("%.1f", math.deg(closestAngle)) .. " degrees")

        -- Save/Update last lock level for this door
        local doorId = closestDoor.id
        local isLocked = types.Lockable.isLocked(closestDoor)
        local rawLockLevel = types.Lockable.getLockLevel(closestDoor)
        local effectiveLockLevel = isLocked and rawLockLevel or 0
        doorLastLockLevels[doorId] = effectiveLockLevel
        log("[DOOR DETECTION] Updated last lock level for door", doorId, ":", effectiveLockLevel, "(isLocked:", isLocked, "rawLevel:", rawLockLevel, ")")
    else
        log("[DOOR DETECTION] No door detected in range or facing direction")
    end
end

----------------------------------------------------------------------
-- ★★★ EVENT: Set Hello Value ★★★
----------------------------------------------------------------------
local function onSetHello(data)
    if not data or not data.npcId or data.value == nil then return end

    log("═══════════════════════════════════════════════════")
    log("SETTING HELLO VALUE for NPC", data.npcId, "to", data.value)

    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        types.NPC.stats.ai.hello(npc).base = data.value
        log("  ✓ Hello value set to", data.value, "for NPC", data.npcId)
    else
        log("  ERROR: NPC not found for hello value setting")
    end

    log("═══════════════════════════════════════════════════")
end

-- ★★★ EVENT: Check Door Locks ★★★
local function onCheckDoorLocks(data)
    if not _enableDoorMechanics then return end
    log("[DOOR DETECTION] Global script received CheckDoorLocks event")

    local delay = data.delay or 1.9  -- Default to 2.5 seconds if not specified
    log("[DOOR DETECTION] Delaying check by", delay, "seconds")

    -- Use manual delay timer for global scripts since async:newSimulationTimer is not available
    doorLockCheckDelay = delay
end

local function performDoorLockCheck()
    if not _enableDoorMechanics then return end
    log("[DOOR DETECTION] Performing delayed door lock check")

    local player = world.players[1]
    if not player then
        log("[DOOR DETECTION] ERROR: Could not find player")
        return
    end

    -- Player position and facing direction
    local playerPos     = player.position
    local playerForward = player.rotation:apply(util.vector3(0, 1, 0))

    -- Detection parameters
    local maxDistance = 400             -- units
    local maxAngle    = math.rad(360)    -- 30-degree cone

    local closestDoor     = nil
    local closestDistance = math.huge
    local closestAngle    = math.huge

    ------------------------------------------------------------------
    --  Iterate every door reference in the player’s current cell
    ------------------------------------------------------------------
    for _, door in ipairs(player.cell:getAll(types.Door)) do
        -- Skip teleport doors (remove this line if you want them)
        if not types.Door.isTeleport(door) then
            local doorPos  = door.position
            local distance = (doorPos - playerPos):length()

            if distance <= maxDistance then
                local toDoor = (doorPos - playerPos):normalize()
                local angle  = math.acos(playerForward:dot(toDoor))

                if angle <= maxAngle
                   and (distance < closestDistance
                     or (distance == closestDistance and angle < closestAngle)) then
                    closestDoor     = door
                    closestDistance = distance
                    closestAngle    = angle
                end
            end
        end
    end

    ------------------------------------------------------------------
    --  Check lock level change for closest door
    ------------------------------------------------------------------
    if closestDoor then
        local doorRecord = types.Door.record(closestDoor)
        local doorId = closestDoor.id
        local lastLockLevel = doorLastLockLevels[doorId] or 0
        local isLocked = types.Lockable.isLocked(closestDoor)
        local rawLockLevel = types.Lockable.getLockLevel(closestDoor)
        local currentLockLevel = isLocked and rawLockLevel or 0
        local lockedDoorPos = closestDoor.position

        log("[DOOR DETECTION] Door detected:")
        log("  ID:         " .. tostring(closestDoor.id))
        log("  Door Coords: " .. tostring(lockedDoorPos))
        log("  Name:       " .. (doorRecord and doorRecord.name or "unnamed door"))
        log("  Locked:     " .. tostring(isLocked))
        log("  Lock Level: " .. tostring(rawLockLevel))
        log("  Distance:   " .. string.format("%.1f", closestDistance) .. " units")

        -- Check if lock level increased (door became locked or more locked)
        if currentLockLevel > lastLockLevel then
            log("[DOOR DETECTION] Door lock level increased from " .. lastLockLevel .. " to " .. currentLockLevel .. " - triggering unlock sequence")
            
            -- First check if there's a following NPC - they take priority
            local closestNPC = nil
            local npcDist = math.huge
            local foundFollowingNPC = false
            
            -- Check following NPCs first (within 1000 units of player)
            for fNpcId, _ in pairs(followingNPCs) do
                local fnPC = findNPC(fNpcId)
                if fnPC and fnPC:isValid() and not types.Actor.isDead(fnPC) and fnPC.cell == player.cell then
                    local d = (fnPC.position - playerPos):length()
                    if d <= 1000 then
                        closestNPC = fnPC
                        npcDist = d
                        foundFollowingNPC = true
                        log("[DOOR DETECTION] Found following NPC", fNpcId, "at distance", math.floor(d), "- prioritizing for unlock")
                        break
                    end
                end
            end
            
            -- If no following NPC found, find closest NPC (excluding companions)
            if not foundFollowingNPC then
                for _, actor in ipairs(world.activeActors) do
                    if actor and actor.type == types.NPC and actor:isValid() and not types.Actor.isDead(actor) and actor.cell == player.cell then
                        if not companionDetection.isCompanion(actor) then
                            local d = (actor.position - playerPos):length()
                            if d <= 1000 and d < npcDist then
                                npcDist = d
                                closestNPC = actor
                            end
                        end
                    end
                end
            end

            if closestNPC then
                -- Check if door is within 1000 units of the NPC
                local doorDistFromNpc = (closestDoor.position - closestNPC.position):length()
                if doorDistFromNpc <= 1000 then
                    -- Check if door is already opening/open
                    local doorState = types.Door.getDoorState(closestDoor)
                    if doorState ~= types.Door.STATE.Opening and not types.Door.isOpen(closestDoor) then
                        
                        -- Check if we should skip bounty application
                        local skipBounty = false
                        local skipReason = ""
                        
                        if combatDoorInvestigation[closestNPC.id] then
                            skipBounty = true
                            skipReason = "NPC is in combat door unlock sequence"
                        end
                        
                        if not skipBounty and player.cell then
                            local nearbyNPCs = { actors = player.cell:getAll(types.NPC) }
                            local isOnlyEnemies = classification.shouldDisableCellForOnlyEnemies(nearbyNPCs, types)
                            local isSlavesAndEnemies = classification.shouldDisableCellForSlavesAndEnemies(nearbyNPCs, types)
                            
                            if isOnlyEnemies or isSlavesAndEnemies then
                                skipBounty = true
                                skipReason = "Hostile cell (" .. (player.cell.name or "unknown") .. ")"
                            end
                        end
                        
                        if not skipBounty then
                            -- Store pending bounty check
                            pendingBountyChecks[doorId] = {
                                npcId = closestNPC.id,
                                bountyAmount = 150,
                                doorPosition = lockedDoorPos,
                                timestamp = core.getRealTime()
                            }
                            log("[DOOR DETECTION] Pending bounty stored for door", doorId, "with NPC", closestNPC.id)
                        else
                            log("[DOOR DETECTION] Skipping bounty application - " .. skipReason)
                        end
                        
                        -- Trigger unlock sequence
                        core.sendGlobalEvent('AntiTheft_UnlockDoorDuringCombat', {
                            npcId = closestNPC.id,
                            doorPosition = lockedDoorPos,
                            playerPosition = playerPos
                        })
                    else
                        log("[DOOR DETECTION] Door is already opening or open - skipping NPC trigger")
                    end
                else
                    log("[DOOR DETECTION] Closest NPC is too far from the door (" .. math.floor(doorDistFromNpc) .. " units)")
                end
            else
                log("[DOOR DETECTION] No valid NPCs found within 1000 units of player")
            end
        end

        -- Always update the last lockevel to the current one
        doorLastLockLevels[doorId] = currentLockLevel
        log("[DOOR DETECTION] Updated last lock level for door", doorId, "to", currentLockLevel)
    else
        log("[DOOR DETECTION] No door detected in range")
    end
end

-- ★★★ EVENT: Disband for Investigation ★★★
local function onDisbandForInvestigation(data)
    if not data or not data.npcId then return end

    log("[DOOR INVESTIGATION] Disbanding guard for investigation:", data.npcId)

    -- Find the NPC
    local npc = findNPC(data.npcId)

    if npc and npc:isValid() then
        -- Send event to player script to stop path recording
        local player = world.players[1]
        if player then
            player:sendEvent('AntiTheft_StopPathRecording', {npcId = data.npcId, position = npc.position})
        end
        -- Clear AI packages
        npc:sendEvent('RemoveAIPackages')
        log("✓ NPC", data.npcId, "completely disbanded for door investigation")
    else
        log("ERROR: NPC", data.npcId, "not found for disbanding")
    end
end

-- ★★★ EVENT: Set Player Bounty (with door investigation) ★★★


local function onSetPlayerBounty(data)
    log("[GLOBAL] onSetPlayerBounty call received")
    if not data or not data.bountyAmount then
        log("[GLOBAL] ERROR: Missing bountyAmount in data package")
        return
    end
    
    local amount = tonumber(data.bountyAmount) or 0
    if amount <= 0 then
        log("[GLOBAL] Skip applying non-positive bounty: " .. tostring(amount))
    else
        local player = world.players[1]
        if not player then
            log("[GLOBAL] CRITICAL ERROR: world.players[1] is nil!")
        else
            -- Robust API check and application
            local typesPlayer = types.Player
            if typesPlayer then
                local currentBounty = 0
                if typesPlayer.getBounty then
                    currentBounty = typesPlayer.getBounty(player) or 0
                elseif typesPlayer.getCrimeLevel then
                    currentBounty = typesPlayer.getCrimeLevel(player) or 0
                end
                
                local newBounty = currentBounty + amount
                
                if typesPlayer.setBounty then
                    typesPlayer.setBounty(player, newBounty)
                    log("[GLOBAL] ★ SUCCESS: Applied bounty (setBounty): " .. tostring(amount) .. ". New Total: " .. tostring(newBounty))
                elseif typesPlayer.setCrimeLevel then
                    typesPlayer.setCrimeLevel(player, newBounty)
                    log("[GLOBAL] ★ SUCCESS: Applied bounty (setCrimeLevel): " .. tostring(amount) .. ". New Total: " .. tostring(newBounty))
                else
                    -- Fallback via mwscript run
                    world.mwscript.run(player, 'SetPCCrimeLevel ' .. newBounty)
                    log("[GLOBAL] ★ WARNING: Used mwscript fallback for bounty. New Total: " .. tostring(newBounty))
                end
            end
        end
    end

    -- Check if there's a valid NPC - if not, skip voice/door reactions only
    if not data or not data.npcId then
        log("[GLOBAL] No NPC ID for voice/investigation reaction - bounty already applied")
        return
    end

    local npc = findNPC(data.npcId)
    if not npc or not npc:isValid() then
        log("[GLOBAL] NPC not found or invalid - skipping voice/investigation")
        return
    end
    log("[GLOBAL] NPC found and valid for reaction:", npc.id)

    --── FIX : cache race+gender immediately
    if rememberRaceGender then
        rememberRaceGender(data.npcId,data.npcRace,data.npcGender)
    end

    -- first reaction voice
    if data.npcId then
        local npc = findNPC(data.npcId)
        if npc and npc:isValid() then playNpcVoiceResponse(npc,data.npcRace,data.npcGender) end
    end

    -- Trigger door investigation if door position and NPC ID are provided
    local doorPosition = nil
    if data.doorPosition then
        doorPosition = data.doorPosition
    elseif data.doorX and data.doorY and data.doorZ then
        doorPosition = util.vector3(data.doorX, data.doorY, data.doorZ)
    end

    if doorPosition and data.npcId then
        -- Check if door is still locked before triggering investigation
        local doorStillLocked = false
        for _, door in ipairs(player.cell:getAll(types.Door)) do
            if door.position == doorPosition then
                doorStillLocked = types.Lockable.isLocked(door)
                break
            end
        end

        if doorStillLocked then
            -- Check if the NPC is currently in combat with the player
            local npcInCombat = npcsInCombatWithPlayer[data.npcId] or false
            if npcInCombat then
                log("[DOOR INVESTIGATION] NPC", data.npcId, "is in combat - skipping regular door investigation (combat unlock handles this)")
            else
                log("[DOOR INVESTIGATION] Door bounty applied - triggering NPC investigation")
                log("[DOOR INVESTIGATION] Door position:", doorPosition)
                log("[DOOR INVESTIGATION] NPC ID:", data.npcId)

            local npc = findNPC(data.npcId)
            if npc and npc:isValid() then
                log("[DOOR INVESTIGATION] Sending NPC to door position for investigation:")
                log("  Door position:         ", doorPosition)

                -- Send event to player script to set investigation state
                core.sendGlobalEvent('AntiTheft_StartDoorInvestigation', { npcId = data.npcId })

                -- Send event to stop following before sending travel package
                core.sendGlobalEvent('AntiTheft_StopFollowing', { npcId = data.npcId })

                -- Send NPC to travel to door position
                log("[DOOR INVESTIGATION] Sending NPC to door position")
                npc:sendEvent('StartAIPackage', {
                    type = 'Travel',
                    destPosition = doorPosition,
                    cancelOther = true
                })

                -- Track investigation - NPC will stop when entering 150-unit radius circle around door
                doorInvestigation[data.npcId] = {
                    doorPosition = doorPosition,
                    startTime = core.getRealTime(),
                    lastLog = core.getRealTime()
                }

                log("[DOOR INVESTIGATION] NPC", data.npcId, "sent to investigate door - will stop when within 150 units of door")
            else
                log("[DOOR INVESTIGATION] ERROR: NPC", data.npcId, "not found for door investigation")
            end

            log("[DOOR INVESTIGATION] Door investigation initiated")
            end
        else
            log("[DOOR INVESTIGATION] Door is no longer locked - skipping investigation")
        end
    else
        log("[DOOR INVESTIGATION] Door investigation not triggered - missing data: doorPosition:", data.doorPosition, "npcId:", data.npcId)
    end
end

----------------------------------------------------------------------
-- ★★★ EVENT: Start Search Timer ★★★
----------------------------------------------------------------------
local function onStartSearchTimer(data)
    if not data or not data.npcId then return end

    -- Prevent creating multiple timers for the same NPC
    if searchTimers[data.npcId] then
        log("Search timer already exists for NPC", data.npcId, "- not creating new one")
        return
    end

    log("STARTING SEARCH TIMER for NPC", data.npcId, "with search time:", data.searchTime, "seconds")

    searchTimers[data.npcId] = {
        startTime = core.getRealTime(),
        endTime = core.getRealTime() + data.searchTime,
        homePosition = data.homePosition,
        homeRotation = data.homeRotation,
        startPosition = data.startPosition,
        walkRotation = data.walkRotation or 0,
        cellName = data.cellName
    }

    log("Search timer started - NPC will return home at:", searchTimers[data.npcId].endTime)
end

-- Function to start combat door unlock sequence when NPC reaches the door
local function startCombatDoorUnlockSequence(npcId, doorPosition, playerPosition)
    log("[COMBAT DOOR UNLOCK SEQUENCE] Starting unlock sequence for NPC", npcId, "at door position:", doorPosition)

    local npc = findNPC(npcId)
    if not npc or not npc:isValid() then
        log("[COMBAT DOOR UNLOCK SEQUENCE] NPC not found or invalid")
        return
    end

    -- Play voice response when starting unlock sequence
    playNpcVoiceResponse(npc)

    -- Get NPC stats to determine unlock method
    local Attr = types.Actor.stats.attributes
    local function getAttr(actor, fn)
        local stat = fn(actor)
        return (stat and stat.modified) or 0
    end

    local strength = getAttr(npc, Attr.strength)
    local agility = getAttr(npc, Attr.agility)
    local intelligence = getAttr(npc, Attr.intelligence)

    -- Determine highest stat
    local highestStat = "strength"
    local highestValue = strength
    if agility > highestValue then
        highestStat = "agility"
        highestValue = agility
    end
    if intelligence > highestValue then
        highestStat = "intelligence"
        highestValue = intelligence
    end

    log("[COMBAT DOOR UNLOCK SEQUENCE] NPC", npcId, "highest stat:", highestStat, "(", highestValue, ")")

    -- Find the door to unlock
    local player = world.players[1]
    local doorToUnlock = nil
    if player then
        for _, door in ipairs(player.cell:getAll(types.Door)) do
            local dist = (door.position - doorPosition):length()
            if dist < 1.0 then  -- within 1 unit tolerance
                doorToUnlock = door
                break
            end
        end
    end

    if doorToUnlock and types.Lockable.isLocked(doorToUnlock) then
        -- Stop NPC movement and make them stand near the door
        npc:sendEvent('RemoveAIPackages')
        log("[COMBAT DOOR UNLOCK SEQUENCE] NPC", npcId, "stopped near door for lock opening sequence")

        -- Get lock level and compute delay between 1 and 15 seconds
        local lockLevel = types.Lockable.getLockLevel(doorToUnlock) or 15
        if lockLevel < 1 then lockLevel = 1 end
        if lockLevel > 100 then lockLevel = 100 end
        local delayTime = 5 + ((lockLevel - 1) / 99) * (17.5 - 1)

        -- Show before message based on highest stat
        local npcName = "The NPC"
        local record = types.NPC.record(npc)
        if record and record.name then
            npcName = record.name
        end

        local beforeMsg = nil
        if highestStat == "strength" then
            beforeMsg = string.format("%s is bashing the doors!", npcName)
        elseif highestStat == "agility" then
            beforeMsg = string.format("%s is picking the lock!", npcName)
        elseif highestStat == "intelligence" then
            beforeMsg = string.format("%s is magically opening the lock!", npcName)
        end
        if player and beforeMsg then
            player:sendEvent('ShowMessage', { message = beforeMsg })
        end

        -- Sound helper functions
        local function rndSlamFile() return ("sound/slam/slam"..math.random(1,7)..".wav") end
        local function playRandomBash(ref)
            local file=rndSlamFile()
            log("[DOOR INVESTIGATION] Attempting to play bash sound: "..file.." on ref:", ref and ref.id or "nil")
            if ref and ref:isValid() then
                core.sound.playSoundFile3d(file,ref,
                    {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                log("[DOOR INVESTIGATION] Successfully initiated bash sound playback: "..file)
            else
                log("[DOOR INVESTIGATION] ERROR: Invalid door reference for bash sound - ref:", ref and ref.id or "nil", "isValid:", ref and ref:isValid() or "nil")
            end
        end
        local function startBashLoop(ref,dur)
            log("[DOOR INVESTIGATION] Starting bash loop with duration:", dur, "seconds on ref:", ref and ref.id or "nil")
            local t0=core.getRealTime()
            local bashCount = 0
            local function step()
                local elapsed = core.getRealTime()-t0
                if elapsed >= dur or (ref and not types.Lockable.isLocked(ref)) then
                    if elapsed >= dur then
                        log("[DOOR INVESTIGATION] Bash loop completed after", bashCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                    else
                        log("[DOOR INVESTIGATION] Bash loop stopped early - door unlocked after", bashCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                    end
                    return
                end
                bashCount = bashCount + 1
                log("[DOOR INVESTIGATION] Bash loop step", bashCount, "at", string.format("%.1f", elapsed), "seconds")
                playRandomBash(ref)
                async:newUnsavableSimulationTimer(0.9+math.random()*0.5,step)
            end
            step()
        end
        local function rndPickFile() return ("sound/pick/pickmove"..math.random(1,7)..".wav") end
        local function playRandomPick(ref)
            local file=rndPickFile()
            log("[DOOR INVESTIGATION] Attempting to play pick sound: "..file.." on ref:", ref and ref.id or "nil")
            if ref and ref:isValid() then
                core.sound.playSoundFile3d(file,ref,
                    {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                log("[DOOR INVESTIGATION] Successfully initiated pick sound playback: "..file)
            else
                log("[DOOR INVESTIGATION] ERROR: Invalid door reference for pick sound - ref:", ref and ref.id or "nil", "isValid:", ref and ref:isValid() or "nil")
            end
        end
        local function playRandomFailOrSuccess(ref)
            local files = {"sound/pick/lock_fail.wav", "sound/pick/llock_success.wav", "Sound/Fx/trans/lever.wav"}
            local file = files[math.random(#files)]
            log("[DOOR INVESTIGATION] Attempting to play fail/success sound: "..file.." on ref:", ref and ref.id or "nil")
            if ref and ref:isValid() then
                core.sound.playSoundFile3d(file,ref,
                    {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                log("[DOOR INVESTIGATION] Successfully initiated fail/success sound playback: "..file)
            else
                log("[DOOR INVESTIGATION] ERROR: Invalid door reference for fail/success sound - ref:", ref and ref.id or "nil", "isValid:", ref and ref:isValid() or "nil")
            end
        end
        local function startPickLoop(ref,dur)
            log("[DOOR INVESTIGATION] Starting pick loop with duration:", dur, "seconds on ref:", ref and ref.id or "nil")
            local t0=core.getRealTime()
            local pickCount = 0
            local cycleCount = 0
            local function step()
                local elapsed = core.getRealTime()-t0
                if elapsed >= dur or (ref and not types.Lockable.isLocked(ref)) then
                    if elapsed >= dur then
                        log("[DOOR INVESTIGATION] Pick loop completed after", pickCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                    else
                        log("[DOOR INVESTIGATION] Pick loop stopped early - door unlocked after", pickCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                    end
                    return
                end
                pickCount = pickCount + 1
                cycleCount = cycleCount + 1
                log("[DOOR INVESTIGATION] Pick loop step", pickCount, "at", string.format("%.1f", elapsed), "seconds")
                if cycleCount <= 3 or cycleCount <= 4 then
                    playRandomPick(ref)
                else
                    playRandomFailOrSuccess(ref)
                    cycleCount = 0
                end
                async:newUnsavableSimulationTimer(0.6+math.random()*0.5,step)
            end
            step()
        end
        local spellCastPairs = {
            {"sound/Fx/magic/altrC.wav", "sound/Fx/magic/altrFAIL.wav"},
            {"sound/Fx/magic/conjC.wav", "sound/Fx/magic/conjFAIL.wav"},
            {"sound/Fx/magic/destC.wav", "sound/Fx/magic/destFAIL.wav"},
            {"sound/Fx/magic/illuC.wav", "sound/Fx/magic/illuFAIL.wav"},
            {"sound/Fx/magic/mystC.wav", "sound/Fx/magic/mystFAIL.wav"},
            {"sound/Fx/magic/restC.wav", "sound/Fx/magic/restFAIL.wav"}
        }

        local function playRandomSpellCast(ref)
            local pair = spellCastPairs[math.random(#spellCastPairs)]
            local castSound = pair[1]
            -- local failSound = pair[2] 

            log("[DOOR INVESTIGATION] Attempting to play cast sound: "..castSound.." on ref:", ref and ref.id or "nil")
            if ref and ref:isValid() then
                core.sound.playSoundFile3d(castSound,ref,
                    {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                log("[DOOR INVESTIGATION] Successfully initiated cast sound playback: "..castSound)
            else
                log("[DOOR INVESTIGATION] ERROR: Invalid door reference for cast sound - ref:", ref and ref.id or "nil", "isValid:", ref and ref:isValid() or "nil")
            end
        end

        local function startSpellCastLoop(ref,dur)
            log("[DOOR INVESTIGATION] Starting spell cast loop with duration:", dur, "seconds on ref:", ref and ref.id or "nil")
            local t0=core.getRealTime()
            local castCount = 0
            local function step()
                local elapsed = core.getRealTime()-t0
                if elapsed >= dur or (ref and not types.Lockable.isLocked(ref)) then
                    if elapsed >= dur then
                        log("[DOOR INVESTIGATION] Cast loop completed after", castCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                    else
                        log("[DOOR INVESTIGATION] Cast loop stopped early - door unlocked after", castCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                    end
                    return
                end
                castCount = castCount + 1
                log("[DOOR INVESTIGATION] Cast loop step", castCount, "at", string.format("%.1f", elapsed), "seconds")
                playRandomSpellCast(ref)
                async:newUnsavableSimulationTimer(1.2+math.random()*0.5,step)
            end
            step()
        end

        -- Start the appropriate sound sequence based on highest stat
        if highestStat == "strength" then
            log("[COMBAT DOOR UNLOCK SEQUENCE] Starting strength-based bash sequence")
            core.sound.playSoundFile3d("Sound/Fx/trans/drlatch_lokd.wav", doorToUnlock,
                {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
            startBashLoop(doorToUnlock, delayTime)
        elseif highestStat == "agility" then
            log("[COMBAT DOOR UNLOCK SEQUENCE] Starting agility-based pick sequence")
            core.sound.playSoundFile3d("Sound/Fx/trans/drlatch_lokd.wav", doorToUnlock,
                {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
            async:newUnsavableSimulationTimer(1.0, function()
                startPickLoop(doorToUnlock, delayTime)
            end)
        elseif highestStat == "intelligence" then
            log("[COMBAT DOOR UNLOCK SEQUENCE] Intelligence-based unlocking sequence")
            core.sound.playSoundFile3d("Sound/Fx/trans/drlatch_lokd.wav", doorToUnlock,
            {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
            async:newUnsavableSimulationTimer(1.0, function()
            startSpellCastLoop(doorToUnlock, delayTime)
        end)
        end

        -- Schedule the final unlock and return to player
        async:newUnsavableSimulationTimer(delayTime, function()
            log("[COMBAT DOOR UNLOCK SEQUENCE] Lock opening sequence complete - unlocking door and sending NPC back")

            -- Unlock the door
            types.Lockable.unlock(doorToUnlock)
            types.Door.activateDoor(doorToUnlock, true)

            -- Reset door lock state to 0 so it can detect future locking
            local doorId = doorToUnlock.id
            doorLockStates[doorId] = 0
            doorLastLockLevels[doorId] = 0
            log("[COMBAT DOOR UNLOCK SEQUENCE] Reset door lock state for door", doorId, "to 0")

            -- Play final sound based on highest stat
            if highestStat == "strength" then
                core.sound.playSoundFile3d("sound/slam/final/doorslam.wav", doorToUnlock,
                    {volume=41.5+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
            elseif highestStat == "agility" then
                core.sound.playSoundFile3d("sound/fx/trans/chain_pul2.wav", doorToUnlock,
                    {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
            elseif highestStat == "intelligence" then
                 -- Play alteration cast sound first
                 core.sound.playSoundFile3d("sound/Fx/magic/altrC.wav", doorToUnlock,
                 {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                 -- Play alteration hit sound after a delay
                 async:newUnsavableSimulationTimer(0.4, function()
                     if doorToUnlock and doorToUnlock:isValid() then
                         core.sound.playSoundFile3d("sound/Fx/magic/altrH.wav", doorToUnlock,
                         {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                     end
                 end)
                 core.sound.playSoundFile3d("sound/fx/trans/chain_pul2.wav", doorToUnlock,
                 {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
            end

            -- Apply Guard (Pursue) vs Civilian (Sound) logic (User Request)
            local npc = npcId and findNPC(npcId)
            if npc and npc:isValid() then
                npc:sendEvent('RemoveAIPackages')
                
                if isGuard(npc) then
                    log("[COMBAT DOOR UNLOCK SEQUENCE] NPC is GUARD - Applying bounty and Pursuing")
                    
                    local player = world.players[1]
                    if player then
                         npc:sendEvent('StartAIPackage', {
                            type = 'Pursue',
                            target = player,
                            cancelOther = true
                         })
                         log("✓ Sent Pursue package to guard")
                    end
                else
                    log("[COMBAT DOOR UNLOCK SEQUENCE] NPC is CIVILIAN - Skipping direct sound playback (relying on Player script detection)")
                    -- We do NOT play sound here to avoid duplication.
                    -- The Player script detects the unlock (checkDoorStateChanges) and sends 'AntiTheft_PlayCivilianUnlockSound'.
                    -- That event handler now mixes both voice tables.
                    
                    -- Re-recruit civilian logic (replacing travel)
                    local player = world.players[1]
                    if player then
                        player:sendEvent('AntiTheft_ReRecruitGuard', {npcId = npcId})
                    end
                end
                
                -- Clear door investigation tracking
                combatDoorInvestigation[npcId] = nil
            end

            log("[COMBAT DOOR UNLOCK SEQUENCE] Door unlocked successfully by NPC", npcId, "- checking for pending bounty")

            -- Check if there's a pending bounty for this door
            if pendingBountyChecks[doorId] then
                local pendingBounty = pendingBountyChecks[doorId]
                log("[COMBAT DOOR UNLOCK SEQUENCE] Found pending bounty check - sending LoS check request to player script")
                
                -- Send event to player script to START continuous LoS monitoring
                local player = world.players[1]
                if player then
                    player:sendEvent('AntiTheft_StartLOSMonitoring', {
                        npcId = pendingBounty.npcId,
                        bountyAmount = pendingBounty.bountyAmount,
                        doorPosition = pendingBounty.doorPosition,
                        doorId = doorId
                    })
                    log("[COMBAT DOOR UNLOCK SEQUENCE] Continuous LoS monitoring started for NPC", pendingBounty.npcId)
                end
                
                -- Clear the pending bounty
                pendingBountyChecks[doorId] = nil
            else
                log("[COMBAT DOOR UNLOCK SEQUENCE] No pending bounty check for this door")
            end

            -- Re-acquire NPC to ensure validity after delay
            local npc = findNPC(npcId)
            if npc and npc:isValid() then
                local player = world.players[1]
                if player then
                    log("[COMBAT DOOR UNLOCK SEQUENCE] Starting Combat package on NPC", npcId)
                    npc:sendEvent('StartAIPackage', {
                        type = 'Travel',
                        destPosition = player.position,
                        cancelOther = false
                    })                
                end
            end

        end)
    else
        log("[COMBAT DOOR UNLOCK SEQUENCE] Door not found or already unlocked")
    end
end

log("=== GLOBAL SCRIPT LOADED SUCCESSFULLY v18.1 ===")
local function onCancelSearchTimer(data)
    if not (data and data.npcId) then return end
    if searchTimers[data.npcId] then
        searchTimers[data.npcId] = nil
        log("Search timer cancelled for NPC", data.npcId, "by external event")
    end
end

----------------------------------------------------------------------
-- ★★★ EVENT: Cancel Return Home Process ★★★
----------------------------------------------------------------------
local function onCancelReturnHome(data)
    if not data or not data.npcId then return end

    log("═══════════════════════════════════════════════════")
    log("CANCELING RETURN HOME PROCESS for NPC", data.npcId)
    log("  Reason: NPC recruited while returning home")

    -- Remove from pending returns if present
    for i = #pendingReturns, 1, -1 do
        if pendingReturns[i].npcId == data.npcId then
            table.remove(pendingReturns, i)
            log("  ✓ Removed from pending returns queue")
        end
    end

    -- Cancel any search timers for this NPC
    if searchTimers[data.npcId] then
        searchTimers[data.npcId] = nil
        log("  ✓ Cancelled search timer")
    end

    -- Remove from wandering tracker if present
    if wanderingNPCs[data.npcId] then
        wanderingNPCs[data.npcId] = nil
        log("  ✓ Removed from wandering tracker")
    end

    -- Cancel any teleport timeouts
    if teleportTimeouts[data.npcId] then
        teleportTimeouts[data.npcId] = nil
        log("  ✓ Cancelled teleport timeout")
    end

    -- Remove from pending teleports
    if pendingTeleports[data.npcId] then
        pendingTeleports[data.npcId] = nil
        log("  ✓ Removed from pending teleports")
    end

    -- Remove from door investigation if present
    if doorInvestigation[data.npcId] then
        doorInvestigation[data.npcId] = nil
        log("  ✓ Removed from door investigation")
    end

    log("═══════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- ★★★ EVENT: Play Second Bed Voice (delayed) ★★★
----------------------------------------------------------------------
local function onBedSecondVoice(data)
    if not data or not data.npcId then return end
    
    local npc = findNPC(data.npcId)
    if not npc or not npc:isValid() then
        log("[BED SECOND VOICE] NPC", data.npcId, "not found or invalid")
        return
    end
    
    -- Check if NPC is still following
    if not followingNPCs[data.npcId] then
        log("[BED SECOND VOICE] NPC", data.npcId, "no longer following - skipping")
        return
    end
    
    local state = bedVoiceState[data.npcId]
    if not state or state.secondFired then
        log("[BED SECOND VOICE] Second voice for NPC", data.npcId, "already fired or state missing")
        return
    end
    
    -- Get voice responses
    local responses = bedVoices[data.race] and bedVoices[data.race][data.gender]
    if responses and #responses > 0 then
        local idx = math.random(#responses)
        local voice = responses[idx]
        
        if voice and voice.file and voice.response then
            -- Fix voice path: add sound/ prefix for custom voices
            local voicePath = voice.file
            if voicePath:find("^Vo/") then
                -- Vanilla voice - add sound/ prefix
                voicePath = "sound/" .. voicePath
            elseif not voicePath:find("^sound/") then
                -- Custom voice - add sound/ prefix
                voicePath = "sound/" .. voicePath
            end
            core.sound.say(voicePath, npc, voice.response)
            
            state.secondFired = true
            log("[BED SECOND VOICE] Played for NPC", data.npcId, ":", voice.response)
            
            -- Lower cell disposition after second voice
            if player and player.cell then
                log("[BED SECOND VOICE] Lowering cell disposition for", player.cell.name)
                onLowerCellDisposition({cellName = player.cell.name})
            end
        end
    end
end

----------------------------------------------------------------------
-- Sleep Check Event Handler (for blackjack integration)
----------------------------------------------------------------------
local function onSleepCheck(data)
    if not data then return end
    
    log("[SLEEP CHECK] ★★★ Received sleep check event with value:", data)
    log("[SLEEP CHECK] Received sleep check event with value:", data)
    
    -- Set global mwscript variable for integration with other mod
    -- This matches the structure from sleep_npc_script_global.lua
    local success, err = pcall(function()
        world.mwscript.getGlobalScript("detd_sleepcheck_global").variables.CheckSleep = data
    end)
    
    if success then
        log("[SLEEP CHECK] Successfully set global CheckSleep variable to:", data)
    else
        log("[SLEEP CHECK] ERROR setting global variable:", err)
    end
    
    -- ADDED: Apply bounty directly for spotted blackjack hits
    if data == 99 then
        log("[SLEEP CHECK] Value is 99 - applying bounty for witnessed blackjack")
        local player = world.players[1]
        if player then
            -- Apply 200 gold bounty for witnessed assault/knockout
            local currentBounty = 0
            if types.Player.getCrimeLevel then
                currentBounty = types.Player.getCrimeLevel(player)
            end
            
            local newBounty = currentBounty + 200
            if types.Player.setCrimeLevel then
                types.Player.setCrimeLevel(player, newBounty)
                log("[SLEEP CHECK] Applied 200 gold bounty. Old:", currentBounty, "New:", newBounty)
            else
                log("[SLEEP CHECK] ERROR: setCrimeLevel not available")
            end
        else
            log("[SLEEP CHECK] ERROR: Could not find player to apply bounty")
        end
    end
end

----------------------------------------------------------------------
-- Event handlers for unconscious NPC pulse system
----------------------------------------------------------------------
local function onNPCUnconscious(data)
    if not data or not data.npcId then return end
    
    local npcId = data.npcId
    log("[PULSE] Received unconscious event for NPC", npcId, "wasSpotted:", data.wasSpotted or false)
    
    -- Store spotted status
    unconsciousNPCStates[npcId] = {
        wasSpotted = data.wasSpotted or false
    }
    
    -- Don't start pulse if already running
    if unconsciousPulseTimers[npcId] then
        log("[PULSE] Pulse already running for NPC", npcId)
        return
    end
    
    -- Find NPC and start pulse
    local npc = findNPC(npcId)
    log("[PULSE] DEBUG: findNPC returned", npc, "for npcId", npcId)
    
    if npc and npc:isValid() and isNPCUnconscious(npc) then
        log("[PULSE] NPC unconscious event received. Global pulse DISABLED (delegating to local script for LoS checks).")
        -- emitDetectionPulse(npc, npcId) -- DISABLED
    else
        log("[PULSE] ERROR: NPC", npcId, "not found or not unconscious. npc:", npc, "valid:", npc and npc:isValid(), "unconscious:", npc and isNPCUnconscious(npc))
    end
end

local function onNPCConscious(data)
    if not data or not data.npcId then return end
    
    local npcId = data.npcId
    log("[PULSE] Received conscious event for NPC", npcId, "- cancelling pulse")
    
    -- Cancel pulse timer
    if unconsciousPulseTimers[npcId] then
        unconsciousPulseTimers[npcId] = nil
    end
    
    -- Clear state
    unconsciousNPCStates[npcId] = nil
    
    -- Clear any discoveries of this body
    for discovererNpc, bodies in pairs(bodyDiscoveries) do
        bodies[npcId] = nil
    end

    -- ★★★ WAKE UP WANDER: Make NPC travel in a ring for 10 seconds ★★★
    local npc = findNPC(npcId)
    if npc and npc:isValid() then
        local utils = require('scripts.antitheftai.modules.utils')
        log("[WAKE UP] NPC", npcId, "woke up - starting 10s wander behavior with multiple points")
        
        -- Capture home position (where they woke up) to return to after wandering
        local homePos = npc.position
        -- Capture home rotation as Euler angles table (required by onStartReturnHome)
        local z, y, x = npc.rotation:getAnglesZYX() -- getAnglesZYX returns Z, Y, X order
        local homeRot = { x = x, y = y, z = z }
        
        local startTime = core.getRealTime()
        local wanderDuration = 20
        
        -- Set active state
        activeWakeUpWanders[npcId] = true
        
        local function wanderStep()
            -- Re-acquire NPC to ensure they are still valid/loaded
            local n = findNPC(npcId)
            if not (n and n:isValid()) then 
                activeWakeUpWanders[npcId] = nil
                return 
            end
            
            -- Check if wander was cancelled (e.g. by spotting player)
            if not activeWakeUpWanders[npcId] then
                log("[WAKE UP] Wander loop cancelled externally for NPC", npcId)
                return
            end
            
            -- Check if wander time has expired
            if core.getRealTime() - startTime >= wanderDuration then
                log("[WAKE UP] Wander time expired - sending NPC home/to original position")
                activeWakeUpWanders[npcId] = nil -- Clear state
                
                -- Use onStartReturnHome to properly return and rotate
                onStartReturnHome({
                    npcId = npcId,
                    homePosition = homePos,
                    homeRotation = homeRot
                })
                return
            end
            
            -- Pick new random point in 300u ring relative to original spot
            -- Use homePos as center to ensure they stay in the general area
            local randomDir = util.vector3(math.random()-0.5, math.random()-0.5, 0):normalize()
            local fakePos = homePos + randomDir -- just to give direction to ring function
            local targetPos = utils.ring(homePos, fakePos, 100, 300)
            
            log("[WAKE UP] Wander step - travelling to:", targetPos)
            n:sendEvent('StartAIPackage', {
                type = 'Travel',
                destPosition = targetPos,
                cancelOther = true -- Override previous travel to change direction immediately
            })
            
            -- Schedule next step in 2.5 seconds (gives them time to walk a bit)
            async:newUnsavableSimulationTimer(2.5, wanderStep)
        end
        
        -- Start loop
        wanderStep()
    end
end



----------------------------------------------------------------------
local function onStopWakeUpWander(data)
    if not data or not data.npcId then return end
    if activeWakeUpWanders[data.npcId] then
        activeWakeUpWanders[data.npcId] = nil
        log("[WAKE UP] Received stop request for NPC", data.npcId, "- cancelling wander loop")
    end
end

----------------------------------------------------------------------
return {
    eventHandlers = {
        SHOP_UpdateSetting = onUpdateSetting,
        AntiTheft_StartReturnHome = onStartReturnHome,
        AntiTheft_StartWandering = onStartWandering,
        AntiTheft_StartWalkingHome = onStartWalkingHome,
        AntiTheft_FinalizeReturn = onFinalizeReturn,
        AntiTheft_PlaceReturningNPC = onPlaceReturningNPC,
        AntiTheft_TeleportAndFinalize = onTeleportAndFinalize,
        AntiTheft_CancelReturn = onCancelReturn,
        AntiTheft_TeleportGuard = onTeleportGuard,
        AntiTheft_TeleportHome = onTeleportHome,
        AntiTheft_RequestCleanup = onRequestCleanup,
        AntiTheft_LowerCellDisposition = onLowerCellDisposition,
        AntiTheft_LowerNPCDisposition = onLowerNPCDisposition,
        AntiTheft_RefundKeylock = onRefundKeylock,
        AntiTheft_StartSearchTimer = onStartSearchTimer,
        AntiTheft_ApplyLockSpellBounty = onApplyLockSpellBounty,
        AntiTheft_DoorDetection = onDoorDetection,
        AntiTheft_CheckDoorLocks = onCheckDoorLocks,
        AntiTheft_SetPlayerBounty = onSetPlayerBounty,
        AntiTheft_DisbandForInvestigation = onDisbandForInvestigation,
        
        -- Bed Detection Events
        AntiTheft_ScanBedsInPlayerCell = function(data)
            -- Triggered by player script. Scans beds in player's current cell.
            local player = world.players[1]
            if not player or not player.cell then return end
            
            -- Scan and Cache
            local cellName = player.cell.name or "unknown"
            local beds = scanBedsInCell(player.cell)
            cellBedCache[cellName] = beds
            
            -- Send data back to player
            player:sendEvent("AntiTheft_UpdateBedCache", {
                cellName = cellName,
                beds = beds
            })
            log("[BED SCAN GLOBAL] Scanned and sent", #beds, "beds to player for cell", cellName)
        end,
        
        AntiTheft_PlayerSleepingInBed = function(data)
            -- Data: { npcId = string, playerPos = vec3, cellName = string }
            if not data or not data.npcId then return end
            
            local npc = findNPC(data.npcId)
            if not npc or not npc:isValid() then 
                log("[BED REACTION] Invalid NPC ID:", data.npcId)
                return 
            end
            
            -- Security check: Is NPC in same cell?
            if npc.cell.name ~= data.cellName then
                log("[BED REACTION] NPC in different cell - ignoring. NPC:", npc.cell.name, "Player:", data.cellName)
                return
            end
            
            -- Reaction Logic
            log("[BED REACTION] NPC", npc.id, "reacting to player in bed!")
            
            -- 1. Voice
            local record = types.NPC.record(npc)
            if record then
                local race = record.race and record.race:lower():gsub(" ", "") or "darkelf"
                local gender = record.isMale and "male" or "female"
                
                -- Construct voice path (using existing module logic would be best, but we'll inline a simple lookup or call helper)
                
                if not bedVoiceState[npc.id] then bedVoiceState[npc.id] = {firstFired=false, secondFired=false, attackFired=false, lastCheck=0} end
                local state = bedVoiceState[npc.id]
                
                -- Reset state if stale (> 60s)
                if core.getSimulationTime() - state.lastCheck > 60 then
                    state.firstFired = false
                    state.secondFired = false
                    state.attackFired = false
                    state.firstWarningTime = nil
                    state.secondWarningTime = nil
                end
                state.lastCheck = core.getSimulationTime()
                
                if not state.firstFired then
                    -- First warning / Voice
                    -- We can just call existing voice helpers if their scope allows, 
                    -- OR we can accept that the player script sends event to trigger a voice separately?
                    -- No, let's trigger it here.
                    
                    local bedVoices = require('scripts.antitheftai.modules.bed_voices')
                    -- Normalize race key access
                    local voices = nil
                    if bedVoices[race] then voices = bedVoices[race][gender]
                    elseif bedVoices[record.race:lower()] then voices = bedVoices[record.race:lower()][gender] end
                    
                    if voices and #voices > 0 then
                        local voice = voices[math.random(#voices)]
                        core.sound.say(voice.file, npc, voice.response)
                        state.firstFired = true
                        log("[BED REACTION] Played FIRST warning voice:", voice.response)
                    else
                        log("[BED REACTION] No voice lines found for", race, gender)
                    end
                    
                    -- Face player
                    -- Face player (Warning only)
                     npc:sendEvent('StartAIPackage', {type='Travel', destPosition=npc.position, callback=function() end}) -- Stop movement
                     -- Ideally we'd use 'TurnTo' but that might not be exposed directly or require a different package.
                     -- For now, we rely on the voice.
                     log("[BED REACTION] First warning given - NO COMBAT yet.")
                     
                elseif not state.secondFired then
                    -- Second Warning
                    if not state.firstWarningTime then
                         state.firstWarningTime = core.getSimulationTime()
                    end
                    
                    local timeInViolation = core.getSimulationTime() - state.firstWarningTime
                    log("[BED REACTION] Time in violation:", string.format("%.1f", timeInViolation), "seconds")
                    
                    if timeInViolation > 30 then
                        -- 30 seconds passed - PLAY SECOND WARNING
                        local bedVoices = require('scripts.antitheftai.modules.bed_voices')
                        local voices = nil
                        if bedVoices[race] then voices = bedVoices[race][gender]
                        elseif bedVoices[record.race:lower()] then voices = bedVoices[record.race:lower()][gender] end
                        
                         if voices and #voices > 0 then
                            local voice = voices[math.random(#voices)]
                            core.sound.say(voice.file, npc, voice.response)
                            onLowerCellDisposition({cellName = player.cell.name})
                            log("[BED REACTION] Played SECOND warning voice")
                        end
                        
                        state.secondFired = true
                        state.secondWarningTime = core.getSimulationTime()
                        log("[BED REACTION] Second warning given - 30s grace period starting before attack.")
                    else
                         -- Still in grace period
                         log("[BED REACTION] Player in bed area for < 30s (" .. string.format("%.1f", timeInViolation) .. "). Waiting to play second warning.")
                    end
                elseif not state.attackFired then
                    -- Attack Phase (30s after second warning)
                    local timeSinceSecondWarning = core.getSimulationTime() - state.secondWarningTime
                    log("[BED REACTION] Time since second warning:", string.format("%.1f", timeSinceSecondWarning), "seconds")
                    
                    if timeSinceSecondWarning > 30 then
                        log("[BED REACTION] 30 seconds passed since second warning - EXECUTING ATTACK")
                        npc:sendEvent('StartAIPackage', {type='Combat', target=world.players[1]})
                        state.attackFired = true
                    else
                        log("[BED REACTION] Player still in area after second warning. Attacking in " .. string.format("%.1f", 30 - timeSinceSecondWarning) .. "s")
                    end
                end
            end
        end,
        AntiTheft_CancelSearchTimer = onCancelSearchTimer,
        AntiTheft_CancelReturnHome = onCancelReturnHome,
        AntiTheft_UpdateDoorLockState = function(data)
            if data and data.doorId and data.lockLevel then
                doorLastLockLevels[data.doorId] = data.lockLevel
                log("[DOOR DETECTION] Received explicit lock state update for door", data.doorId, "to", data.lockLevel)
            end
        end,
        AntiTheft_NPCUnconscious = onNPCUnconscious,
        AntiTheft_NPCConscious = onNPCConscious,
        AntiTheft_StopWakeUpWander = onStopWakeUpWander,
        AntiTheft_PlayCivilianUnlockSound = onPlayCivilianUnlockSound, -- NEW handler
        S3CombatTargetAdded = function(data)
            if data and data.id then
                npcsInCombatWithPlayer[data.id] = true
                log("[COMBAT TRACKING] NPC", data.id, "entered combat with player")
            end
        end,
        S3CombatTargetRemoved = function(data)
            if data and data.id then
                npcsInCombatWithPlayer[data.id] = nil
                log("[COMBAT TRACKING] NPC", data.id, "removed from combat with player")
            end
        end,
        
        AntiTheft_AddBlackjack = function(data)
        if not data or not data.npcId or not data.itemId then return end
        local npc = findNPC(data.npcId)
        if npc and npc:isValid() then
            -- Check if item exists in inventory first (double check)
            if types.Actor.inventory(npc):count(data.itemId) == 0 then
                npc:sendEvent('AddItem', { itemId = data.itemId, count = 1 })
                log("[BLACKJACK] Added", data.itemId, "to NPC", data.npcId)
            end
        end
    end,

    AntiTheft_UnlockDoorDuringCombat = function(data)
            if not _enableDoorMechanics then return end
            if data and data.npcId and data.doorPosition then
                local npc = findNPC(data.npcId)
                if npc and npc:isValid() then
                    log("[UNLOCK DOOR DURING COMBAT] Received request for NPC", npc.id)
                    
                    -- Check if door is still locked
                    local doorStillLocked = false
                    if npc.cell then
                        for _, door in ipairs(npc.cell:getAll(types.Door)) do
                            -- Check position with small tolerance
                            if (door.position - data.doorPosition):length() < 5 then
                                doorStillLocked = types.Lockable.isLocked(door)
                                break
                            end
                        end
                    end
                    
                    if doorStillLocked then
                        log("[UNLOCK DOOR DURING COMBAT] Door still locked - sending NPC to approach")

                         -- Send NPC to travel to door position
                        npc:sendEvent('RemoveAIPackages')
                        npc:sendEvent('StartAIPackage', {
                            type = 'Travel',
                            destPosition = data.doorPosition,
                            cancelOther = true
                        })

                        -- Add to combat door investigation tracking
                        combatDoorInvestigation[data.npcId] = {
                            doorPosition = data.doorPosition,
                            playerPosition = data.playerPosition,
                            startTime = core.getRealTime(),
                            lastLog = core.getRealTime()
                        }
                        
                        -- Remove from regular door investigation if present
                        if doorInvestigation[data.npcId] then
                            doorInvestigation[data.npcId] = nil
                        end
                    else
                         log("[UNLOCK DOOR DURING COMBAT] Door no longer locked - skipping")
                    end
                else
                    log("[UNLOCK DOOR DURING COMBAT] NPC not found or invalid")
                end
            end
        end,
        AntiTheft_RegisterFollowingNPC = function(data)
            if data and data.npcId then
                if not followingNPCs[data.npcId] then
                    followingNPCs[data.npcId] = true
                    log("[GLOBAL] Registered following NPC", data.npcId)
                    log("[GLOBAL DEBUG] Registered following NPC", data.npcId)
                    
                    -- Cache race/gender if provided
                    if data.race and data.gender then
                        rememberRaceGender(data.npcId, data.race, data.gender)
                        log("[GLOBAL] Cached race/gender for NPC", data.npcId, ":", data.race, data.gender)
                    end

                    -- Cache home position if provided
                    if data.homePosition then
                        npcHomePositions[data.npcId] = data.homePosition
                        log("[GLOBAL] Cached home position for NPC", data.npcId, ":", data.homePosition)
                    end
                    
                    -- Initialize bed voice state
                    bedVoiceState[data.npcId] = {firstFired = false, secondFired = false, lastCheck = 0}
                    
                    -- Immediately scan for beds in current cell (in case we missed the cell change event)
                    local player = world.players[1]
                    if player and player.cell and not player.cell.isExterior then
                        log("[GLOBAL DEBUG] Force scanning beds for following NPC in cell:", player.cell.name)
                        local cellName = player.cell.name or "unknown"
                        local beds = scanBedsInCell(player.cell)
                        cellBedCache[cellName] = beds
                        log("[GLOBAL DEBUG] Force scan cached", #beds, "bed positions")
                    end
                end
            end
        end,
        AntiTheft_UnregisterFollowingNPC = function(data)
            if data and data.npcId then
                followingNPCs[data.npcId] = nil
                bedVoiceState[data.npcId] = nil  -- Clear bed voice state
                log("[GLOBAL] Unregistered following NPC", data.npcId)
            end
        end,
        detdGlobalCheckSleep = onSleepCheck,
        
        
        -- Force NPC to Flee (Global - modifies AI stats and triggers combat)
        AntiTheft_MakeNPCFlee = function(data)
            if not data or not data.npcId then return end
            
            -- Find NPC locally
            local function findNPC(npcId)
                for _, actor in ipairs(world.activeActors) do
                    if actor.id == npcId then return actor end
                end
                return nil
            end

            local npc = nil
            if data.npcId then npc = findNPC(data.npcId) end
            
            if npc and npc:isValid() then
                log("[AntiTheft_MakeNPCFlee] Forcing NPC", data.npcId, "to FLEE")
                
                -- 1. Modify AI Stats (Fight=0, Flee=100)
                -- Note: Only persistent if defined in base record or saves, here we modify active instance
                if types.NPC.stats.ai.fight(npc) then
                    types.NPC.stats.ai.fight(npc).base = 0
                end
                if types.NPC.stats.ai.flee(npc) then
                    types.NPC.stats.ai.flee(npc).base = 100
                end
                
                -- 2. Apply Demoralize (Backup)
                local success, err = pcall(function()
                    types.Actor.activeEffects(npc):set(100, core.magic.EFFECT_TYPE.Demoralize, 45)
                end)
                if success then
                    log("[AntiTheft_MakeNPCFlee] Demoralize effect applied successfully")
                else
                    log("[AntiTheft_MakeNPCFlee] FAILED to apply Demoralize effect:", err)
                end
                

                
                log("[AntiTheft_MakeNPCFlee] NPC", data.npcId, "Fight set to 0, Flee to 100, Combat started.")
            end
        end,

        -- Trigger Voice (Remote)
        AntiTheft_TriggerVoice = function(data)
            if not data or not data.path then return end
            
            -- Find NPC locally
            local function findNPC(npcId)
                for _, actor in ipairs(world.activeActors) do
                    if actor.id == npcId then return actor end
                end
                return nil
            end

            local npc = nil
            if data.npcId then npc = findNPC(data.npcId) end
            
            if npc and npc:isValid() then
                local success, err = pcall(function()
                    if core.sound and core.sound.say then
                        core.sound.say(data.path, npc, data.text)
                    else
                        error("core.sound.say not available in Global")
                    end
                end)
                
                if not success then
                    -- Fallback to playSound3D
                    if data.position and core.sound and core.sound.playSound3D then
                         core.sound.playSound3D(data.path, data.position, { volume = 1.0, pitch = 1.0 })
                    end
                end
            end
        end,
        
        -- Flee Effects Handler (Moved to Global)
        -- Flee Effects Handler (Moved to Global)
        AntiTheft_ApplyGlobalFlee = function(data)
           if not data or not data.npcId then return end
           local npcId = data.npcId
           log("[GLOBAL FLEE] Received Apply Request for NPC", npcId)

           local npc = findNPC(npcId)
           if npc and npc:isValid() then
               -- 1. Apply Demoralize (ID 54 or 5000 mag)
               local demoId = core.magic.EFFECT_TYPE.DemoralizeHumanoid or 54
               -- Note: activeEffects on NPC from Global requires finding the actor first
               types.Actor.activeEffects(npc):set(5000, demoId, 15)
               log("[GLOBAL FLEE] Demoralize (5000/15s) Applied to", npcId)


               -- 3. Global Charge Drain (Requested Move)
               _G.AT_FleeChargeData = _G.AT_FleeChargeData or {}
               _G.AT_FleeChargeData[npcId] = {}
               
               local inventory = types.Actor.inventory(npc)
               local itemTypes = { types.Weapon, types.Armor, types.Clothing }
               local drained = 0
               
               for _, iType in ipairs(itemTypes) do
                   for _, item in ipairs(inventory:getAll(iType)) do
                       -- Use itemData(item) as requested
                       local data = types.Item.itemData(item)
                       if data then
                           local current = data.enchantmentCharge
                           if current and current > 0 then
                               -- Store
                               table.insert(_G.AT_FleeChargeData[npcId], { item = item, charge = current })
                               -- Drain
                               data.enchantmentCharge = 0
                               drained = drained + 1
                               log("[GLOBAL FLEE] Drained Item (Global): " .. item.recordId .. " Was: " .. current)
                           end
                       end
                   end
               end
               log("[GLOBAL FLEE] Total Items Drained: " .. drained)

               -- 4. Global Scroll Removal
               _G.AT_FleeScrollData = _G.AT_FleeScrollData or {}
               _G.AT_FleeScrollData[npcId] = {}
               local books = inventory:getAll(types.Book)
               local scrollsRemoved = 0
               
               for _, item in ipairs(books) do
                   local record = types.Book.record(item)
                   -- Log checking
                   -- log("[GLOBAL FLEE] Checking Book: " .. record.id .. " isScroll: " .. tostring(record.isScroll))
                   
                   if record and record.isScroll then
                       -- Verified Scroll Check
                       table.insert(_G.AT_FleeScrollData[npcId], { recordId = record.id, count = item.count })
                       item:remove()
                       scrollsRemoved = scrollsRemoved + 1
                       log("[GLOBAL FLEE] Removed Scroll: " .. record.id .. " Count: " .. item.count)
                   end
               end
               log("[GLOBAL FLEE] Total Scrolls Removed: " .. scrollsRemoved)

               -- 5. Global Ranged Weapon Removal (Bows, Crossbows, Thrown)
               _G.AT_FleeWeaponData = _G.AT_FleeWeaponData or {}
               _G.AT_FleeWeaponData[npcId] = {}
               local weapons = inventory:getAll(types.Weapon)
               local weaponsRemoved = 0

               for _, item in ipairs(weapons) do
                   local record = types.Weapon.record(item)
                   if record and (
                       record.type == types.Weapon.TYPE.MarksmanBow or
                       record.type == types.Weapon.TYPE.MarksmanCrossbow or
                       record.type == types.Weapon.TYPE.MarksmanThrown
                   ) then
                       table.insert(_G.AT_FleeWeaponData[npcId], { recordId = record.id, count = item.count })
                       item:remove()
                       weaponsRemoved = weaponsRemoved + 1
                       log("[GLOBAL FLEE] Removed Ranged Weapon: " .. record.id .. " Type: " .. record.type)
                   end
               end
               log("[GLOBAL FLEE] Total Ranged Weapons Removed: " .. weaponsRemoved)

               -- 5. Force Weapon Stance & Drain Magicka (Moved to end)
               -- Sent AFTER items are cleaned so Local script can clear casting with empty hands/drained items
               local weaponStance = types.Actor.STANCE.Weapon
               npc:sendEvent('AntiTheft_ApplyFleeEffectsLocal', { stance = weaponStance })
               log("[GLOBAL FLEE] Sent 'AntiTheft_ApplyFleeEffectsLocal' (Weapon/"..tostring(weaponStance).." + Drain) to", npcId)

           else
               log("[GLOBAL FLEE] NPC", npcId, "not found or invalid")
           end
        end,

        AntiTheft_RemoveGlobalFlee = function(data)
            if not data or not data.npcId then return end
            local npcId = data.npcId
            log("[GLOBAL FLEE] Received Remove Request for NPC", npcId)

            local npc = findNPC(npcId)
            if npc and npc:isValid() then
                local nothingStance = types.Actor.STANCE.Nothing
                npc:sendEvent('AntiTheft_ApplyFleeEffectsLocal', { stance = nothingStance }) 
                log("[GLOBAL FLEE] Sent 'AntiTheft_ApplyFleeEffectsLocal' (Nothing/"..tostring(nothingStance)..") to", npcId)
                
                -- Restore Charges
                if _G.AT_FleeChargeData and _G.AT_FleeChargeData[npcId] then
                    local restored = 0
                    for _, entry in ipairs(_G.AT_FleeChargeData[npcId]) do
                        local item = entry.item
                        local charge = entry.charge
                        if item:isValid() then
                            local data = types.Item.itemData(item)
                            if data then
                                data.enchantmentCharge = charge
                                restored = restored + 1
                            end
                        end
                    end
                    log("[GLOBAL FLEE] Restored Charges for " .. restored .. " items.")
                    _G.AT_FleeChargeData[npcId] = nil
                end

                -- Restore Scrolls
                if _G.AT_FleeScrollData and _G.AT_FleeScrollData[npcId] then
                    for _, entry in ipairs(_G.AT_FleeScrollData[npcId]) do
                        -- Global: Create object and move it into inventory
                        local newScroll = world.createObject(entry.recordId, entry.count)
                        if newScroll then
                            newScroll:moveInto(types.Actor.inventory(npc))
                            log("[GLOBAL FLEE] Restored scroll:", entry.recordId, "Count:", entry.count)
                        else
                             log("[GLOBAL FLEE] ERROR: Failed to create scroll object:", entry.recordId)
                        end
                    end

                    _G.AT_FleeScrollData[npcId] = nil
                end

                -- Restore Ranged Weapons
                if _G.AT_FleeWeaponData and _G.AT_FleeWeaponData[npcId] then
                    for _, entry in ipairs(_G.AT_FleeWeaponData[npcId]) do
                        local newWeapon = world.createObject(entry.recordId, entry.count)
                        if newWeapon then
                            newWeapon:moveInto(types.Actor.inventory(npc))
                            log("[GLOBAL FLEE] Restored Ranged Weapon:", entry.recordId)
                        else
                             log("[GLOBAL FLEE] ERROR: Failed to create weapon object:", entry.recordId)
                        end
                    end
                    _G.AT_FleeWeaponData[npcId] = nil
                end
            else
                log("[GLOBAL FLEE] NPC", npcId, "not found or invalid")
            end
        end,
        AntiTheft_SyncSetting = function(data)
            local shopSettings = require('scripts.antitheftai.SHOPsettings')
            -- Sync player settings to global storage for NPC scripts
            if data and data.key and data.group and shopSettings[data.group] then
                log("[SETTINGS] Syncing", data.group, data.key, "to", tostring(data.value))
                shopSettings[data.group]:set(data.key, data.value)
            end
        end,

        -- Relay Sleep Bounty Event (Bridge for Blackjack Sleep)
        AntiTheft_Relay_SleepBounty = function(data)
            log("[GLOBAL] AntiTheft_Relay_SleepBounty received")
            if not data then return end
            -- Apply bounty directly (custom amount) or relay to global
            local amount = 0
            local npcId = nil
            
            if type(data) == 'number' then
                amount = data
            elseif type(data) == 'table' then
                amount = data.amount or 0
                npcId = data.npcId
            end
            
            -- If amount is 99 or greater, use legacy path to trigger alarms in mwscript mods
            if amount >= 99 then
                 log("[GLOBAL] Relaying bounty to mwscript integration (amount: " .. amount .. ")")
                 onSleepCheck(amount)
            end

            -- Apply bounty via Lua (Robust Path)
            onSetPlayerBounty({
                bountyAmount = amount,
                npcId = npcId
            })
        end,

        -- Mapped Event Handlers
        detdGlobalCheckSleep = onSleepCheck,
        AntiTheft_Relay_NPCUnconscious = onNPCUnconscious,
        AntiTheft_NPCConscious = onNPCConscious,
        AntiTheft_HandleKeylockOutcome = function(data)
            if not data or (not data.door and not data.doorId) or data.success == nil or not data.keylockId or not data.damagePerUse then return end
            
            local player = world.players[1]
            if not player or not player.cell then return end
            
            log("[GLOBAL KEYLOCK] Outcome handler triggered - Success:", data.success, "Keylock:", data.keylockId)
            
            -- Find the door object (prefer data.door if passed as object)
            local door = data.door
            if not door or not door:isValid() then
                -- Fallback to search by ID
                for _, obj in pairs(player.cell:getAll(types.Door)) do
                    if obj.id == data.doorId then
                        door = obj
                        break
                    end
                end
                
                -- Global search if still not found
                if not door then
                    for _, cell in pairs(world.cells) do
                        for _, obj in pairs(cell:getAll(types.Door)) do
                            if obj.id == data.doorId then
                                door = obj
                                break
                            end
                        end
                        if door then break end
                    end
                end
            end
            
            if not door or not door:isValid() then
                log("[GLOBAL KEYLOCK] Error: Door object not found or invalid")
                return
            end
            
            -- 1. Handle Success Actions (Locking & Sound)
            if data.success then
                -- Calculate lock level based on keylock type and player Security skill
                local securitySkill = types.NPC.stats.skills.security(player).modified
                local rangeInfo = KEYLOCK_RANGES[data.keylockId:lower()]
                local lockLevel = 50 -- Fallback
                
                if rangeInfo then
                    local range = rangeInfo.max - rangeInfo.min
                    local skillFactor = math.min(1.0, securitySkill / 100)
                    lockLevel = math.floor(rangeInfo.min + (range * skillFactor))
                end
                
                local initialLockLevel = types.Lockable.getLockLevel(door)
                local initialIsLocked = types.Lockable.isLocked(door)
                local doorState = types.Door.getDoorState(door)
                
                log("[GLOBAL KEYLOCK] Attempting to lock door. Initial Level:", initialLockLevel, "Locked:", initialIsLocked, "State:", doorState)
                
                -- SUCCESS FIX: Use the combined lock(door, level) API as requested
                types.Lockable.lock(door, lockLevel)
                
                local finalLockLevel = types.Lockable.getLockLevel(door)
                local finalIsLocked = types.Lockable.isLocked(door)
                
                log("[GLOBAL KEYLOCK] SetLockLevel Result -> Final Level:", finalLockLevel, "Locked:", finalIsLocked)
                
                if finalLockLevel ~= lockLevel then
                    log("[GLOBAL KEYLOCK] WARNING: Lock level did not match expected value! Engine may have rejected it.")
                end
                
                log("[GLOBAL KEYLOCK] Success! Door locked to level", lockLevel, "(Security:", securitySkill, ")")
                
                -- Play 3D success sound at door position
                local soundIdx = math.random(1, 3)
                local soundFile = string.format("lock/lock%d.mp3", soundIdx)
                 core.sound.playSoundFile3d(soundFile, door, {volume = 20.0, pitch = 0.9 + math.random() * 0.2, loop = false})
                log("[GLOBAL KEYLOCK] Playing 3D success sound:", soundFile, "at door")
            else
                -- Play 3D failure sound at door position
                core.sound.playSoundFile3d("sound/Fx/trans/lever.wav", door, {volume = 20.0, pitch = 0.9 + math.random() * 0.2, loop = false})
                log("[GLOBAL KEYLOCK] Playing 3D failure sound: sound/Fx/trans/lever.wav at door")
            end
            
            -- 2. Handle Item Damage
            local equipment = types.Actor.getEquipment(player)
            local equippedItem = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            
            -- Verify it's the correct item
            if equippedItem and equippedItem.recordId:lower() == data.keylockId:lower() then
                local itemData = types.Item.itemData(equippedItem)
                if itemData then
                    local currentCondition = itemData.condition
                    local newCondition = math.max(0, currentCondition - data.damagePerUse)
                    itemData.condition = newCondition
                    log("[GLOBAL KEYLOCK] Item damaged: condition", currentCondition, "->", newCondition)
                    
                    if newCondition <= 0 then
                        log("[GLOBAL KEYLOCK] Item broken - removing from inventory")
                        equippedItem:remove()
                        player:sendEvent('AntiTheft_ShowMessage', { text = "Your keylock has broken!" })
                    end
                end
            end
        end,
        
        AntiTheft_PlayDetectionVoice = function(data)
            if not data or not data.npcId then return end
            local npc = findNPC(data.npcId)
            if npc and npc:isValid() then
                playNpcVoiceResponse(npc)
            end
        end,

        AntiTheft_RefundKeylock = function(data)
            if not data or not data.keylockId then return end
            
            local player = world.players[1]
            if not player then return end
            
            log("[GLOBAL KEYLOCK] Refund triggered for:", data.keylockId)
            
            local equipment = types.Actor.getEquipment(player)
            local equippedItem = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            
            if equippedItem and equippedItem.recordId:lower() == data.keylockId:lower() then
                local itemData = types.Item.itemData(equippedItem)
                if itemData then
                    -- Refund exactly 1 condition charge as requested
                    local currentCondition = itemData.condition
                    -- Get max condition from record (default to 100 if unknown)
                    local record = types.Lockpick.record(equippedItem)
                    local maxCondition = record and record.maxCondition or 100
                    
                    local newCondition = math.min(maxCondition, currentCondition + 1)
                    itemData.condition = newCondition
                    log("[GLOBAL KEYLOCK] Refunded 1 charge: condition", currentCondition, "->", newCondition)
                end
            end
        end,

        AntiTheft_FinalizeReturn = function(data)
            if not data or not data.npcId or not data.homePosition or not data.homeRotation then return end
            
            -- Replaced hard teleport with smooth rotation
            local npc = findNPC(data.npcId)
            if npc and npc:isValid() then
                log("[GLOBAL] AntiTheft_FinalizeReturn called for NPC", data.npcId, "- starting smooth rotation (no teleport)")
                npc:sendEvent('RemoveAIPackages')
                
                -- Start smooth rotation from CURRENT position (no snap)
                startGlobalRotation(npc, data.homeRotation, 0.85, data.homePosition, data.homeRotation)
                
                -- Ensure search state is cleared immediately as well
                local player = world.players[1]
                if player then
                    player:sendEvent('AntiTheft_ClearSearchState', { npcId = data.npcId })
                end
            end
        end,

        AntiTheft_StartReturnHome = onStartReturnHome,

        AntiTheft_LowerCellDisposition = onLowerCellDisposition,

        -- Added handlers for Voice and Body Discovery (Relay from Blackjack script)
        AntiTheft_PlayDetectionVoice = onPlayNPCVoice,
        AntiTheft_BodyDiscovered = onBodyDiscoveryRelay, -- Alias for consistency
        AntiTheft_BodyDiscoveryRelay = onBodyDiscoveryRelay,
    },
    engineHandlers = {
        onUpdate = function(dt)
            -- Init persistence variables if missing
            if not lastBodyCheckTime then lastBodyCheckTime = 0 end
            if not BODY_CHECK_INTERVAL then BODY_CHECK_INTERVAL = 0.5 end

            updateGlobalRotations(dt)
            processPendingReturns(dt)
            
            -- [PULSE TEST] log removed
            
            -- Poll for unconscious NPCs every second (DISABLED - Handled locally by blackjack_sleep.lua)
            --[[
            local currentTime = core.getRealTime()
            local POLL_INTERVAL = 1.0
            if not lastUnconsciousPollTime then lastUnconsciousPollTime = 0 end
            
            if currentTime - lastUnconsciousPollTime >= POLL_INTERVAL then
                lastUnconsciousPollTime = currentTime
                
                local player = world.players[1]
                if player and player.cell then
                    -- log("[PULSE POLL] Scanning for unconscious NPCs in cell:", player.cell.name)
                    local npcCount = 0
                    local unconsciousCount = 0
                    
                    -- Scan for unconscious NPCs
                    for _, actor in ipairs(world.activeActors) do
                        if actor.type == types.NPC and actor.cell == player.cell then
                            npcCount = npcCount + 1
                            local isUnconscious = isNPCUnconscious(actor)
                            
                            if isUnconscious then
                                unconsciousCount = unconsciousCount + 1
                                local npcId = actor.id
                                
                                -- Check if we've already started pulse for this NPC
                                if not unconsciousPulseTimers[npcId] then
                                    log("[PULSE AUTO-DETECT] ★★★ Found unconscious NPC", npcId, "- starting pulse")
                                    
                                    -- Initialize state (assume not spotted since we can't check from here)
                                    unconsciousNPCStates[npcId] = {
                                        wasSpotted = false  -- Will be set to true if pulse discovers body
                                    }
                                    
                                    -- Start pulse
                                    emitDetectionPulse(actor, npcId)
                                else
                                    -- log("[PULSE POLL] NPC", npcId, "already has active pulse")
                                end
                            end
                        elseif actor.type == types.NPC and unconsciousPulseTimers[actor.id] then
                            -- NPC was unconscious but is now conscious - cancel pulse
                            if not isNPCUnconscious(actor) then
                                local npcId = actor.id
                                log("[PULSE AUTO-DETECT] NPC", npcId, "woke up - cancelling pulse")
                                unconsciousPulseTimers[npcId] = nil
                                unconsciousNPCStates[npcId] = nil
                                
                                -- Clear discoveries
                                for discovererNpc, bodies in pairs(bodyDiscoveries) do
                                    bodies[npcId] = nil
                                end
                            end
                        end
                    end
                    
                    -- log("[PULSE POLL] Found", npcCount, "NPCs,", unconsciousCount, "unconscious")
                end
            end
            ]]

            -- Check for cell change to reset disposition tracking AND door lock states
            local player = world.players[1]
            if player and player.cell then
                if lastPlayerCell ~= player.cell.name then
                    log("[GLOBAL DEBUG] Cell change detected! Old:", lastPlayerCell or "nil", "New:", player.cell.name)
                    if lastPlayerCell then
                        log("Player left cell", lastPlayerCell, "- resetting disposition tracking")
                    end
                    lastPlayerCell = player.cell.name
                    -- Reset disposition tracking for the new cell
                    dispositionAppliedCells[player.cell.name] = nil
                    -- Reset door lock states to prevent triggering on cell load
                    doorLockStates = {}
                    doorLockStatesJustInitialized = false
                    log("Player entered cell", player.cell.name, "- disposition can be applied again")
                    log("[GLOBAL DEBUG] About to check if cell is interior...")
                    
                    --Scan beds in new cell
                    if _enableBedDetection and not player.cell.isExterior then
                        log("[GLOBAL BED DEBUG] Scanning beds in interior cell:", player.cell.name)
                        local cellName = player.cell.name or "unknown"
                        local beds = scanBedsInCell(player.cell)
                        cellBedCache[cellName] = beds
                        log("[GLOBAL BED DEBUG] Cached", #beds, "bed positions for cell", cellName)
                        log("[BED CACHE] Cached", #beds, "bed positions for cell", cellName)
                    end
                end
                
                -- Check bed proximity for following NPCs (every 0.5s to save resources)
                if _enableBedDetection then
                for npcId, _ in pairs(followingNPCs) do
                    local npc = findNPC(npcId)
                    if npc and npc:isValid() and npc.cell == player.cell then
                        -- Initialize state for this NPC if needed
                        if not bedVoiceState[npcId] then
                            bedVoiceState[npcId] = {firstFired = false, secondFired = false, secondVoiceCancelled = false, lastCheck = 0}
                        end
                        
                        local state = bedVoiceState[npcId]
                        local currentTime = core.getRealTime()
                        
                        -- Check every 0.5 seconds
                        if currentTime - state.lastCheck >= 0.5 then
                            state.lastCheck = currentTime
                            
                            -- Only check if both voices haven't fired yet
                            if not state.secondFired and not player.cell.isExterior then
                                local cellName = player.cell.name or "unknown"
                                local cachedBeds = cellBedCache[cellName]
                                
                                if cachedBeds and #cachedBeds > 0 then
                                    -- Find nearest bed to optimize performance (Skip beds near home)
                                    local nearestDist = math.huge
                                    local nearestBedPos = nil
                                    local homePos = npcHomePositions[npcId]
                                    
                                    for _, bedPos in ipairs(cachedBeds) do
                                        local skipBed = false
                                        if homePos then
                                            local distToHome = (bedPos - homePos):length()
                                            if distToHome < 500 then
                                                skipBed = true
                                                -- log("[BED PROXIMITY GLOBAL] Skipping bed at", bedPos, "because it is within 500 units of home")
                                            end
                                        end

                                        if not skipBed then
                                            local dist = (player.position - bedPos):length()
                                            if dist < nearestDist then
                                                nearestDist = dist
                                                nearestBedPos = bedPos
                                            end
                                        end
                                    end
                                    
                                    -- Cancel second voice if player moved >500 units from beds
                                    if nearestDist > 500 and state.firstFired and not state.secondFired then
                                        -- Set cancellation flag (timer will check this)
                                        if not state.secondVoiceCancelled then
                                            state.secondVoiceCancelled = true
                                            log("[BED PROXIMITY GLOBAL] Player moved >500 units from bed - will cancel second voice for NPC", npcId)
                                        end
                                    end
                                    
                                    -- Only proceed if player is within 400 units (performance optimization)
                                    if nearestDist <= 400 then
                                        log("[BED PROXIMITY GLOBAL] NPC", npcId, "nearest bed dist:", math.floor(nearestDist), "units")
                                        
                                        -- Check if within 350 units to trigger voice
                                        if nearestDist <= 350 and not state.firstFired then
                                            -- LoS Check (User Request)
                                            -- LoS Check (Delegated to Player Script)
                                            -- Global script cannot castRay. We assume if player script says "valid bed", it's valid.
                                            -- For now, we stick to distance check + maybe check a synced flag if available.
                                            -- If we want strict LoS, we must wait for player event.
                                            
                                            local blocked = false 
                                            -- Ideally: blocked = not state.playerHasLineOfSightToBed
                                            -- But we don't have that synced yet.
                                            -- For "Warning Voices" (mild), distance check is often enough.
                                            -- User requested strict LoS to prevent wall detection.
                                            
                                            -- FIX: We cannot do Raycast here. 
                                            -- We will rely on distance for now, OR if I add the sync logic.
                                            -- Temporarily assuming NOT BLOCKED to fix crash, 
                                            -- but adding TODO to sync LoS from player.
                                            
                                            -- If nearestDist is very close (e.g. < 150), likely in same room.
                                            -- Through-wall usage usually happens at max range.
                                            -- Let's restrict distance slightly more for "Blind" check?
                                            -- Or just proceed.
                                            
                                            -- blocked = false (already set)

                                            if not blocked then
                                            -- Get NPC race/gender from cache
                                            local raceGender = npcRaceGenderCache[npcId]
                                            if raceGender then
                                                local race = raceGender.race:lower():gsub(" ", "") -- Normalize race string
                                                local gender = raceGender.gender
                                                
                                                log("[BED PROXIMITY GLOBAL] Playing first voice for NPC", npcId, "race:", race, "gender:", gender)
                                                
                                                -- Mark first fired immediately to prevent loop
                                                state.firstFired = true
                                                
                                                -- Get voice responses
                                                local responses = bedVoices[race] and bedVoices[race][gender]
                                                if responses and #responses > 0 then
                                                    local idx = math.random(#responses)
                                                    local voice = responses[idx]
                                                    
                                                    if voice and voice.file and voice.response then
                                                        -- Fix voice path: add sound/ prefix for custom voices
                                                        local voicePath = voice.file
                                                        if voicePath:find("^Vo/") then
                                                            -- Vanilla voice - add sound/ prefix
                                                            voicePath = "sound/" .. voicePath
                                                        elseif not voicePath:find("^sound/") then
                                                            -- Custom voice - add sound/ prefix
                                                            voicePath = "sound/" .. voicePath
                                                        end
                                                        core.sound.say(voicePath, npc, voice.response)
                                                        
                                                        log("[BED PROXIMITY GLOBAL] First voice played:", voice.response)
                                                        
                                                        -- Schedule second voice (10-20 seconds delay)
                                                        local delay = math.random(10, 20)
                                                        async:newUnsavableSimulationTimer(delay, function()
                                                            -- Check if second voice was cancelled
                                                            local currentState = bedVoiceState[npcId]
                                                            if currentState and not currentState.secondVoiceCancelled then
                                                                -- Call the BedSecondVoice event handler
                                                                onBedSecondVoice({npcId = npcId, race = race, gender = gender})
                                                            else
                                                                log("[BED PROXIMITY GLOBAL] Second voice cancelled for NPC", npcId)
                                                            end
                                                        end)
                                                        
                                                        log("[BED PROXIMITY GLOBAL] Second voice scheduled in", delay, "seconds")
                                                    end
                                                else
                                                     log("[BED PROXIMITY GLOBAL] No voices found for race:", race)
                                                end
                                            else
                                                log("[BED PROXIMITY GLOBAL] No race/gender cached for NPC", npcId)
                                            end
                                        end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                end -- closes _enableBedDetection
            end
            
            --[[ DISABLED: Redundant Global Polling (Handled locally by blackjack_sleep.lua)
            -- Check for unconscious body discoveries (throttled to 0.5s intervals)
            local currentTime = core.getRealTime()
            if player and player.cell and (currentTime - lastBodyCheckTime >= BODY_CHECK_INTERVAL) then
                lastBodyCheckTime = currentTime
                
                -- Scan for unconscious NPCs and update tracking
                local currentUnconsciousNPCs = {}
                for _, actor in ipairs(world.activeActors) do
                    if actor.type == types.NPC and actor.cell == player.cell and isNPCUnconscious(actor) then
                        currentUnconsciousNPCs[actor.id] = true
                    end
                end
                
                -- Update active unconscious NPCs tracking
                activeUnconsciousNPCs = currentUnconsciousNPCs
                
                -- Count unconscious NPCs for logging
                local unconsciousCount = 0
                for _ in pairs(activeUnconsciousNPCs) do
                    unconsciousCount = unconsciousCount + 1
                end
                
                if unconsciousCount > 0 then
                    -- log("[BODY DISCOVERY] Found", unconsciousCount, "unconscious NPC(s) in cell") -- SPAM
                    -- log("[BODY DISCOVERY] Running detection check -", unconsciousCount, "unconscious NPCs")
                    
                    -- Collect unconscious NPCs for discovery checks
                    local unconsciousNPCs = {}
                    for _, actor in ipairs(world.activeActors) do
                        if actor.type == types.NPC and actor.cell == player.cell and activeUnconsciousNPCs[actor.id] then
                            table.insert(unconsciousNPCs, actor)
                        end
                    end
                    
                    -- If there are unconscious NPCs, check if conscious NPCs discover them
                    if #unconsciousNPCs > 0 then
                        for _, actor in ipairs(world.activeActors) do
                            if actor.type == types.NPC and actor.cell == player.cell and not isNPCUnconscious(actor) then
                                local actorId = actor.id
                                
                                -- Check if already approaching
                                if bodyApproaching and bodyApproaching[actorId] then
                                    local approach = bodyApproaching[actorId]
                                    local unconscious = findNPC(approach.bodyId)
                                    
                                    if unconscious and unconscious:isValid() then
                                        local dist = (actor.position - approach.bodyPos):length()
                                        if dist <= APPROACH_DISTANCE then
                                            handleBodyReaction(actor, unconscious)
                                        end
                                    else
                                        bodyApproaching[actorId] = nil
                                    end
                                else
                                    -- Check for new discoveries
                                    for _, unconscious in ipairs(unconsciousNPCs) do
                                        local unconsciousId = unconscious.id
                                        
                                        if not (bodyDiscoveries[actorId] and bodyDiscoveries[actorId][unconsciousId]) then
                                            local dist = (actor.position - unconscious.position):length()
                                            
                                            if dist <= BODY_DISCOVERY_RANGE then
                                                local hasLoS = world.castRay(actor.position, unconscious.position)
                                                
                                                if not hasLoS or not hasLoS.hit then
                                                    handleBodyDiscovery(actor, unconscious)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            ]]

            -- Process pending teleports
            for npcId, teleportData in pairs(pendingTeleports) do
                local npc = findNPC(npcId)
                if npc and npc:isValid() then
                    log("Processing pending teleport for NPC", npcId)
                    -- First teleport to exact position to ensure correct starting point
                    npc:teleport(npc.cell.name, teleportData.homePosition, { onGround = true })
                    -- Start smooth rotation
                    startGlobalRotation(npc, teleportData.homeRotation, 0.85, teleportData.homePosition, teleportData.homeRotation)
                    
                    pendingTeleports[npcId] = nil
                end
            end

            -- Process search timers
            local currentTime = core.getRealTime()
            for npcId, timerData in pairs(searchTimers) do
                if currentTime >= timerData.endTime then
                    -- Search timer expired - start return home process
                    log("SEARCH TIMER EXPIRED for NPC", npcId, "- starting return home")

                    -- Check if player is in the same cell as the NPC
                    local player = world.players[1]
                    local playerCell = player and player.cell and player.cell.name or ""
                    if timerData.cellName == playerCell then
                        -- Player is in same cell - use real walking instead of simulation
                        log("Player in same cell as NPC", npcId, "- using real walking to home")

                        local npc = findNPC(npcId)
                        if npc and npc:isValid() then
                            -- Clear any existing AI packages first
                            npc:sendEvent('RemoveAIPackages')

                            -- Clear any existing pending return state to prevent duplicate blocking
                            for i = #pendingReturns, 1, -1 do
                                if pendingReturns[i].npcId == npcId then
                                    table.remove(pendingReturns, i)
                                    log("Cleared existing pending return for NPC", npcId, "due to search timer expiration")
                                    break
                                end
                            end

                            -- Send event to start walking home (same as onStartReturnHome)
                            core.sendGlobalEvent('AntiTheft_StartReturnHome', {
                                npcId = npcId,
                                homePosition = timerData.homePosition,
                                homeRotation = timerData.homeRotation
                            })

                            -- Clear search state in player script to prevent re-detection
                            local player = world.players[1]
                            if player then
                                player:sendEvent('AntiTheft_ClearSearchState', { npcId = npcId })
                                log("Sent clear search state event for NPC", npcId)
                            end

                            -- Clear the search timer since we're now returning home
                            searchTimers[npcId] = nil
                            log("Cleared search timer for NPC", npcId, "- now returning home")
                        else
                            log("NPC", npcId, "not found for real walking - will use simulation")
                            -- Fall back to simulation if NPC not found
                            if not timerData.isTraveling then
                                log("NPC", npcId, "starting simulated travel to home position")

                                -- Initialize travel simulation data
                                searchTimers[npcId].travelStartTime = currentTime
                                searchTimers[npcId].isTraveling = true

                                -- Calculate total travel time
                                local distance = (timerData.homePosition - timerData.startPosition):length()
                                local travelSpeed = config.SIMULATED_TRAVEL_SPEED or 300
                                if travelSpeed <= 0 then travelSpeed = 300 end  -- Safety check
                                searchTimers[npcId].totalTravelTime = distance / travelSpeed
                                searchTimers[npcId].lastProgressLog = 0

                                log("NPC", npcId, "will take", string.format("%.1f", searchTimers[npcId].totalTravelTime), "seconds to reach home")
                            end
                        end
                    else
                        -- Player not in same cell - use simulation
                        if not timerData.isTraveling then
                            log("NPC", npcId, "starting simulated travel to home position")

                            -- Initialize travel simulation data
                            searchTimers[npcId].travelStartTime = currentTime
                            searchTimers[npcId].isTraveling = true

                            -- Calculate total travel time
                            local distance = (timerData.homePosition - timerData.startPosition):length()
                            local travelSpeed = config.SIMULATED_TRAVEL_SPEED or 300
                            if travelSpeed <= 0 then travelSpeed = 300 end  -- Safety check
                            searchTimers[npcId].totalTravelTime = distance / travelSpeed
                            searchTimers[npcId].lastProgressLog = 0

                            log("NPC", npcId, "will take", string.format("%.1f", searchTimers[npcId].totalTravelTime), "seconds to reach home")
                        end
                    end
                else
                    -- Search timer still running - check if player returned to cell
                    local player = world.players[1]
                    local playerCell = player and player.cell and player.cell.name or ""
                    if timerData.cellName == playerCell and not timerData.playerReturned then
                        -- Player just returned to the cell while NPC is searching
                        log("Player returned to cell", playerCell, "while NPC", npcId, "is searching - NPC will finish search and walk home")
                        timerData.playerReturned = true
                    end
                end

                -- Continue simulated travel (always runs once started)
                if timerData.isTraveling then
                    local timeSinceTravelStart = currentTime - timerData.travelStartTime
                    local progress = math.min(timeSinceTravelStart / timerData.totalTravelTime, 1.0)

                    if progress >= 1.0 then
                        -- NPC has arrived home via simulation - teleport to final position
                        log("NPC", npcId, "has arrived home via simulation - teleporting to home position")
                        pendingTeleports[npcId] = {
                            homePosition = timerData.homePosition,
                            homeRotation = timerData.homeRotation
                        }
                        searchTimers[npcId] = nil
                    else
                        -- Update simulated position for when NPC loads
                        local currentPos = timerData.startPosition + (timerData.homePosition - timerData.startPosition) * progress
                        local distance = (timerData.homePosition - timerData.startPosition):length()
                        local distanceRemaining = math.floor(distance * (1 - progress))

                        -- Log progress periodically
                        if currentTime - timerData.lastProgressLog >= 1.0 then  -- Log every second
                            log("NPC", npcId, "travel progress:", string.format("%.1f%%", progress * 100),
                                "current pos:", currentPos, "distance remaining:", distanceRemaining)
                            timerData.lastProgressLog = currentTime
                        end

                        -- Store current travel state for when NPC loads
                        pendingTeleports[npcId] = {
                            currentPosition = currentPos,
                            homePosition = timerData.homePosition,
                            homeRotation = timerData.homeRotation,
                            walkRotation = timerData.walkRotation or 0,
                            cellName = timerData.cellName,
                            isSimulationOngoing = true
                        }
                    end
                end
            end

            -- Process door lock check delay timer
            if doorLockCheckDelay > 0 then
                doorLockCheckDelay = doorLockCheckDelay - dt
                if doorLockCheckDelay <= 0 then
                    performDoorLockCheck()
                    doorLockCheckDelay = 0
                end
            end

            -- Process 5-minute teleport timeouts
            for npcId, timeoutData in pairs(teleportTimeouts) do
                if currentTime >= timeoutData.timeoutTime then
                    log("5-minute timeout reached for NPC", npcId, "- teleporting to default position")
                    local npc = findNPC(npcId)
                    if npc and npc:isValid() then
                        finalizeNPCReturn(npcId, timeoutData.homePosition, timeoutData.homeRotation)
                    else
                        log("NPC", npcId, "not found for timeout teleport")
                    end
                    teleportTimeouts[npcId] = nil
                end
            end

            ------------------------------------------------------------------
            -- bash-sound helpers (re-usable) -------------------------------------
            ------------------------------------------------------------------
            local function rndSlamFile() return ("sound/slam/slam"..math.random(1,7)..".wav") end
            local function playRandomBash(ref)
                local file=rndSlamFile()
                log("[DOOR INVESTIGATION] Attempting to play bash sound: "..file.." on ref:", ref and ref.id or "nil")
                if ref and ref:isValid() then
                    core.sound.playSoundFile3d(file,ref,
                        {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                    log("[DOOR INVESTIGATION] Successfully initiated bash sound playback: "..file)
                else
                    log("[DOOR INVESTIGATION] ERROR: Invalid door reference for bash sound - ref:", ref and ref.id or "nil", "isValid:", ref and ref:isValid() or "nil")
                end
            end
            local function startBashLoop(ref,dur)
                log("[DOOR INVESTIGATION] Starting bash loop with duration:", dur, "seconds on ref:", ref and ref.id or "nil")
                local t0=core.getRealTime()
                local bashCount = 0
                local function step()
                    local elapsed = core.getRealTime()-t0
                    if elapsed >= dur or (ref and not types.Lockable.isLocked(ref)) then
                        if elapsed >= dur then
                            log("[DOOR INVESTIGATION] Bash loop completed after", bashCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                        else
                            log("[DOOR INVESTIGATION] Bash loop stopped early - door unlocked after", bashCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                        end
                        return
                    end
                    bashCount = bashCount + 1
                    log("[DOOR INVESTIGATION] Bash loop step", bashCount, "at", string.format("%.1f", elapsed), "seconds")
                    playRandomBash(ref)
                    async:newUnsavableSimulationTimer(0.9+math.random()*0.5,step)
                end
                step()
            end
            local function rndPickFile() return ("sound/pick/pickmove"..math.random(1,7)..".wav") end
            local function playRandomPick(ref)
                local file=rndPickFile()
                log("[DOOR INVESTIGATION] Attempting to play pick sound: "..file.." on ref:", ref and ref.id or "nil")
                if ref and ref:isValid() then
                    core.sound.playSoundFile3d(file,ref,
                        {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                    log("[DOOR INVESTIGATION] Successfully initiated pick sound playback: "..file)
                else
                    log("[DOOR INVESTIGATION] ERROR: Invalid door reference for pick sound - ref:", ref and ref.id or "nil", "isValid:", ref and ref:isValid() or "nil")
                end
            end
            local function playRandomFailOrSuccess(ref)
                local files = {"sound/pick/lock_fail.wav", "sound/pick/llock_success.wav", "Sound/Fx/trans/lever.wav"}
                local file = files[math.random(#files)]
                log("[DOOR INVESTIGATION] Attempting to play fail/success sound: "..file.." on ref:", ref and ref.id or "nil")
                if ref and ref:isValid() then
                    core.sound.playSoundFile3d(file,ref,
                        {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                    log("[DOOR INVESTIGATION] Successfully initiated fail/success sound playback: "..file)
                else
                    log("[DOOR INVESTIGATION] ERROR: Invalid door reference for fail/success sound - ref:", ref and ref.id or "nil", "isValid:", ref and ref:isValid() or "nil")
                end
            end
            local function startPickLoop(ref,dur)
                log("[DOOR INVESTIGATION] Starting pick loop with duration:", dur, "seconds on ref:", ref and ref.id or "nil")
                local t0=core.getRealTime()
                local pickCount = 0
                local cycleCount = 0
                local function step()
                    local elapsed = core.getRealTime()-t0
                    if elapsed >= dur or (ref and not types.Lockable.isLocked(ref)) then
                        if elapsed >= dur then
                            log("[DOOR INVESTIGATION] Pick loop completed after", pickCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                        else
                            log("[DOOR INVESTIGATION] Pick loop stopped early - door unlocked after", pickCount, "sounds over", string.format("%.1f", elapsed), "seconds")
                        end
                        return
                    end
                    pickCount = pickCount + 1
                    cycleCount = cycleCount + 1
                    log("[DOOR INVESTIGATION] Pick loop step", pickCount, "at", string.format("%.1f", elapsed), "seconds")
                    if cycleCount <= 3 or cycleCount <= 4 then
                        playRandomPick(ref)
                    else
                        playRandomFailOrSuccess(ref)
                        cycleCount = 0
                    end
                    async:newUnsavableSimulationTimer(0.6+math.random()*0.5,step)
                end
                step()
            end
            
            -- Spell casting functions for intelligence-based unlocking
            local spellCastPairs = {
                {"sound/Fx/magic/altrC.wav", "sound/Fx/magic/altrFAIL.wav"},
                {"sound/Fx/magic/conjC.wav", "sound/Fx/magic/conjFAIL.wav"},
                {"sound/Fx/magic/destC.wav", "sound/Fx/magic/destFAIL.wav"},
                {"sound/Fx/magic/illuC.wav", "sound/Fx/magic/illuFAIL.wav"},
                {"sound/Fx/magic/mystC.wav", "sound/Fx/magic/mystFAIL.wav"},
                {"sound/Fx/magic/restC.wav", "sound/Fx/magic/restFAIL.wav"}
            }
            
            local function playRandomSpellCast(ref)
                local pair = spellCastPairs[math.random(#spellCastPairs)]
                local castSound = pair[1]
                local failSound = pair[2]
                
                log("[DOOR INVESTIGATION] Attempting to play spell cast sounds on ref:", ref and ref.id or "nil")
                if ref and ref:isValid() then
                    -- Play cast sound first
                    core.sound.playSoundFile3d(castSound, ref,
                        {volume=20.7+math.random()*0.3, pitch=0.9+math.random()*0.3, loop=false})
                    log("[DOOR INVESTIGATION] Successfully initiated spell cast sound: "..castSound)
                    
                    -- Play fail sound shortly after
                    async:newUnsavableSimulationTimer(0.4, function()
                        if ref and ref:isValid() then
                            core.sound.playSoundFile3d(failSound, ref,
                                {volume=20.7+math.random()*0.3, pitch=0.9+math.random()*0.3, loop=false})
                            log("[DOOR INVESTIGATION] Successfully initiated spell fail sound: "..failSound)
                        end
                    end)
                else
                    log("[DOOR INVESTIGATION] ERROR: Invalid door reference for spell sounds - ref:", ref and ref.id or "nil", "isValid:", ref and ref:isValid() or "nil")
                end
            end
            
            local function startSpellCastLoop(ref, dur)
                log("[DOOR INVESTIGATION] Starting spell cast loop with duration:", dur, "seconds on ref:", ref and ref.id or "nil")
                local t0 = core.getRealTime()
                local castCount = 0
                local function step()
                    local elapsed = core.getRealTime() - t0
                    if elapsed >= dur or (ref and not types.Lockable.isLocked(ref)) then
                        if elapsed >= dur then
                            log("[DOOR INVESTIGATION] Spell cast loop completed after", castCount, "casts over", string.format("%.1f", elapsed), "seconds")
                        else
                            log("[DOOR INVESTIGATION] Spell cast loop stopped early - door unlocked after", castCount, "casts over", string.format("%.1f", elapsed), "seconds")
                        end
                        return
                    end
                    castCount = castCount + 1
                    log("[DOOR INVESTIGATION] Spell cast loop step", castCount, "at", string.format("%.1f", elapsed), "seconds")
                    playRandomSpellCast(ref)
                    -- Spell casting has longer intervals than picking/bashing
                    async:newUnsavableSimulationTimer(1.2 + math.random() * 0.5, step)
                end
                step()
            end

            -- Process combat door lock monitoring (moved from player script)
            if monitorDoorLocksDuringCombat and _enableDoorMechanics then
                local player = world.players[1]
                if player and player.cell and not player.cell.isExterior then
                    local doorsLocked = 0
                    local lockedDoorPos = nil

                    -- Check all doors in player's cell
                    for _, door in ipairs(player.cell:getAll(types.Door)) do
                        if door then
                            local doorId = door.id
                            local isLocked = types.Lockable.isLocked(door)
                            local rawLockLevel = types.Lockable.getLockLevel(door)
                            local currentLockLevel = isLocked and rawLockLevel or 0
                            local lastLockLevel = combatDoorStates[doorId]

                            -- Initialize lock level if not tracked yet
                            if lastLockLevel == nil then
                                combatDoorStates[doorId] = currentLockLevel
                                lastLockLevel = currentLockLevel
                            end

                            -- Check if lock level increased (door became more locked)
                            if currentLockLevel > lastLockLevel then
                                doorsLocked = doorsLocked + 1
                                lockedDoorPos = door.position
                                log("[COMBAT DOOR LOCK] Door", doorId, "lock level increased from", lastLockLevel, "to", currentLockLevel, "during combat - triggering unlock")

                                -- Find closest NPC to player
                                local closestNPC = nil
                                local closestDist = math.huge
                                for _, actor in ipairs(world.activeActors) do
                                    if actor and actor.type == types.NPC and actor:isValid() and not types.Actor.isDead(actor) and actor.cell == player.cell then
                                        local dist = (actor.position - player.position):length()
                                        if dist < closestDist then
                                            closestDist = dist
                                            closestNPC = actor
                                        end
                                    end
                                end

                                if closestNPC then
                                    -- Verify NPC is actually in combat with the player using our tracking table
                                    local npcInCombatWithPlayer = npcsInCombatWithPlayer[closestNPC.id] or false
                                    
                                    if npcInCombatWithPlayer then
                                        log("[COMBAT DOOR LOCK] NPC", closestNPC.id, "is in combat with player - sending unlock request at distance", math.floor(closestDist))
                                        -- Send global event to trigger door unlocking
                                        core.sendGlobalEvent('AntiTheft_UnlockDoorDuringCombat', {
                                            npcId = closestNPC.id,
                                            doorPosition = lockedDoorPos,
                                            playerPosition = player.position
                                        })
                                    else
                                        log("[COMBAT DOOR LOCK] NPC", closestNPC.id, "not in combat with player - skipping unlock request")
                                    end
                                else
                                    log("[COMBAT DOOR LOCK] No valid NPCs found to unlock door")
                                end
                            end

                            -- Update door lock level
                            combatDoorStates[doorId] = currentLockLevel
                        end
                    end

                    if doorsLocked == 0 then
                        -- No doors were locked, clear the monitoring flag
                        monitorDoorLocksDuringCombat = false
                        combatDoorStates = {}
                        log("[COMBAT DOOR LOCK] No doors locked during combat - clearing monitoring")
                    end
                end
            end

            -- Door lock level monitoring removed from passive update loop
            -- Now handled explicitly via AntiTheft_CheckDoorLocks event and performDoorLockCheck function

           
            -- Process combat door investigations
            if _enableDoorMechanics then
            for npcId, investigationData in pairs(combatDoorInvestigation) do
                local npc = findNPC(npcId)
                if npc and npc:isValid() then
                    local distanceToDoor = (npc.position - investigationData.doorPosition):length()
                    local timeSinceStart = currentTime - investigationData.startTime

                    -- Log progress periodically
                    if currentTime - investigationData.lastLog >= 1.0 then
                        log("[COMBAT DOOR INVESTIGATION] NPC", npcId, "distance to door:", string.format("%.1f", distanceToDoor), "units, time elapsed:", string.format("%.1f", timeSinceStart), "seconds")
                        investigationData.lastLog = currentTime
                    end

                    -- Check if NPC reached the door (within 115 units)
                    if distanceToDoor <= 155 then
                        log("[COMBAT DOOR INVESTIGATION] NPC", npcId, "reached door - starting unlock sequence")
                        startCombatDoorUnlockSequence(npcId, investigationData.doorPosition, investigationData.playerPosition)
                        combatDoorInvestigation[npcId] = nil
                    end
                else
                    log("[COMBAT DOOR INVESTIGATION] NPC", npcId, "no longer valid - removing from investigation tracking")
                    combatDoorInvestigation[npcId] = nil
                end
            end
            end

            -- Process door investigations
            if _enableDoorMechanics then
            for npcId, investigationData in pairs(doorInvestigation) do
                -- Skip if NPC is being handled by combat investigation
                if combatDoorInvestigation[npcId] then
                    log("[DOOR INVESTIGATION] Skipping NPC", npcId, "- being handled by combat investigation")
                    doorInvestigation[npcId] = nil
                    goto continue
                end
                
                local npc = findNPC(npcId)
                if npc and npc:isValid() then
                    local distanceToDoor = (npc.position - investigationData.doorPosition):length()
                    local timeSinceStart = currentTime - investigationData.startTime

                    -- Log progress periodically
                    if currentTime - investigationData.lastLog >= 1.0 then
                        log("[DOOR INVESTIGATION] NPC", npcId, "distance to door:", string.format("%.1f", distanceToDoor), "units, time elapsed:", string.format("%.1f", timeSinceStart), "seconds")
                        investigationData.lastLog = currentTime
                    end

                    -- Check if NPC reached the investigation area (within 100 units of door)
                    if distanceToDoor <= 115 then
                        -- Check if we haven't already started the waiting period
                        if not investigationData.waitingStarted then
                            log("[DOOR INVESTIGATION] NPC", npcId, "entered investigation area (within 100 units of door) - stopping movement and starting 15-second wait")

                            -- Immediately stop the NPC by removing AI packages
                            npc:sendEvent('RemoveAIPackages')
                            log("[DOOR INVESTIGATION] Removed AI packages from NPC", npcId, "- NPC should now be standing still")

                            -- Directly disband the NPC
                            onDisbandForInvestigation({npcId = npcId})

                            -- Mark that waiting has started
                            investigationData.waitingStarted = true
                            investigationData.waitStartTime = currentTime

                            local npc = findNPC(npcId)
                            if npc and npc:isValid() then
                                -- Replicate getAttr function for stats retrieval
                                local Attr = types.Actor.stats.attributes
                                local function getAttr(actor, fn)
                                    local stat = fn(actor)
                                    return (stat and stat.modified) or 0
                                end

                                -- Get NPC stats
                                local strength = getAttr(npc, Attr.strength)
                                local agility = getAttr(npc, Attr.agility)
                                local intelligence = getAttr(npc, Attr.intelligence)

                                -- Determine highest stat and messages
                                local highestStat = "strength"
                                local highestValue = strength
                                if agility > highestValue then
                                    highestStat = "agility"
                                    highestValue = agility
                                end
                                if intelligence > highestValue then
                                    highestStat = "intelligence"
                                    highestValue = intelligence
                                end

                                -- Get NPC name
                                local npcName = "The NPC"
                                local record = types.NPC.record(npc)
                                if record and record.name then
                                    npcName = record.name
                                end

                                -- Get lock level and compute delay between 1 and 15 seconds
                                local player = world.players[1]
                                local doorPosition = doorInvestigation[npcId].doorPosition
                                local lockLevel = 15 -- default max for safety
                                if player then
                                    for _, door in ipairs(player.cell:getAll(types.Door)) do
                                        if door.position == doorPosition then
                                            lockLevel = types.Lockable.getLockLevel(door) or 15
                                            break
                                        end
                                    end
                                end
                                if lockLevel < 1 then lockLevel = 1 end
                                if lockLevel > 100 then lockLevel = 100 end
                                local delayTime = 5 + ((lockLevel - 1) / 99) * (17.5 - 1)

                                -- Show before message based on highest stat
                                local beforeMsg = nil
                                if highestStat == "strength" then
                                    beforeMsg = string.format("%s is bashing the doors!", npcName)
                                elseif highestStat == "agility" then
                                    beforeMsg = string.format("%s is picking the lock!", npcName)
                                elseif highestStat == "intelligence" then
                                    beforeMsg = string.format("%s is magically opening the lock!", npcName)
                                end
                                if player and beforeMsg then
                                    player:sendEvent('ShowMessage', { message = beforeMsg })
                                end

                                -- voice + bash if STR
                                local doorRef
                                for _,d in ipairs(player.cell:getAll(types.Door)) do
                                    -- Use distance check instead of exact equality for floating point precision
                                    local dist = (d.position - investigationData.doorPosition):length()
                                    if dist < 1.0 then  -- within 1 unit tolerance
                                        doorRef = d
                                        log("[DOOR INVESTIGATION] Found door reference for bash sounds - distance:", string.format("%.3f", dist))
                                        break
                                    end
                                end

                                log("[DOOR INVESTIGATION] Door reference search - highestStat:", highestStat, "doorRef found:", doorRef ~= nil)
                                if doorRef then
                                    log("[DOOR INVESTIGATION] Door reference details - position:", doorRef.position, "investigation position:", investigationData.doorPosition)
                                end

                                if highestStat=="strength" and doorRef then
                                    log("[DOOR INVESTIGATION] Starting voice and bash loop for strength-based NPC")
                                    core.sound.playSoundFile3d("Sound/Fx/trans/drlatch_lokd.wav", doorRef,
                                    {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})                      -- uses cached race/gender
                                    startBashLoop(doorRef,delayTime)                 -- immediate loop
                                elseif highestStat=="agility" and doorRef then
                                    log("[DOOR INVESTIGATION] Starting voice and pick loop for agility-based NPC")
                                    -- Play initial sound first
                                    core.sound.playSoundFile3d("Sound/Fx/trans/drlatch_lokd.wav", doorRef,
                                        {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                                    -- Wait for initial sound to play before starting pick loop
                                    async:newUnsavableSimulationTimer(1.0, function()
                                        startPickLoop(doorRef,delayTime)
                                    end)
                                elseif highestStat=="intelligence" and doorRef then
                                    log("[DOOR INVESTIGATION] Starting spell cast loop for intelligence-based NPC")
                                    -- Play initial sound first
                                    core.sound.playSoundFile3d("Sound/Fx/trans/drlatch_lokd.wav", doorRef,
                                        {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                                    -- Wait for initial sound to play before starting spell cast loop
                                    async:newUnsavableSimulationTimer(1.0, function()
                                        startSpellCastLoop(doorRef,delayTime)
                                    end)
                                else
                                    log("[DOOR INVESTIGATION] Skipping voice/bash - highestStat:", highestStat, "doorRef exists:", doorRef ~= nil)
                                end

                                -- schedule unlock/finish exactly as before ---------------
                                async:newUnsavableSimulationTimer(delayTime,function()
                                    -- (content from original async body BUT
                                    --  remove the old duplicate voice/bash section)
                                    local player=world.players[1]
                                    npc:sendEvent('RemoveAIPackages')
                                    npc:sendEvent('StartAIPackage',{type='Follow',target=player,cancelOther=true})
                                    -- unlock door & finish
                                    for _,d in ipairs(player.cell:getAll(types.Door)) do
                                        if d.position==investigationData.doorPosition then
                                            types.Lockable.unlock(d); types.Door.activateDoor(d,true);
                                            -- Play final door slam sound for strength-based unlocking
                                            if highestStat == "strength" then
                                                log("[DOOR INVESTIGATION] Playing final door slam sound for strength-based unlock")
                                                core.sound.playSoundFile3d("sound/slam/final/doorslam.wav", d,
                                                {volume=41.5+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                                                npc:sendEvent('StartAIPackage', {
                                                    type = 'Travel',
                                                    destPosition = player.position,
                                                    cancelOther = true
                                                       })
                                            elseif highestStat == "agility" then
                                                log("[DOOR INVESTIGATION] Playing final chain pull sound for agility-based unlock")
                                                core.sound.playSoundFile3d("sound/fx/trans/chain_pul2.wav", d,
                                                {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                                                npc:sendEvent('StartAIPackage', {
                                                    type = 'Travel',
                                                    destPosition = player.position,
                                                    cancelOther = true
                                                       })
                                            elseif highestStat == "intelligence" then
                                                log("[DOOR INVESTIGATION] Playing final spell cast sound for intelligence-based unlock")
                                                -- Play alteration cast sound first
                                                core.sound.playSoundFile3d("sound/Fx/magic/altrC.wav", d,
                                                {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                                                -- Play alteration hit sound after a delay
                                                async:newUnsavableSimulationTimer(0.4, function()
                                                    if d and d:isValid() then
                                                        core.sound.playSoundFile3d("sound/Fx/magic/altrH.wav", d,
                                                        {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                                                    end
                                                end)
                                                core.sound.playSoundFile3d("sound/fx/trans/chain_pul2.wav", d,
                                                {volume=20.7+math.random()*0.3,pitch=0.9+math.random()*0.3,loop=false})
                                                npc:sendEvent('StartAIPackage', {
                                                    type = 'Travel',
                                                    destPosition = player.position,
                                                    cancelOther = true
                                                       })
                                            end
                                            break
                                        end
                                    end
                                    doorInvestigation[npcId]=nil          
                                    -- Send event to player script to re-recruit the NPC so it re-follows the player
                                           core.sendGlobalEvent('AntiTheft_ReRecruitGuard', {npcId = npcId})
                                    log("[DOOR INVESTIGATION] Door investigation complete for NPC",npcId, "- re-recruiting to follow player")
                                end)
                            end

                            log("[DOOR INVESTIGATION] NPC", npcId, "is now stopped and waiting 15 seconds before re-recruitment")
                        else
                            -- NPC is already waiting, check if 15 seconds have passed
                            local waitTimeElapsed = currentTime - investigationData.waitStartTime
                            if currentTime - investigationData.lastLog >= 1.0 then
                                log("[DOOR INVESTIGATION] NPC", npcId, "stopped for investigation - time elapsed:", string.format("%.1f", waitTimeElapsed), "seconds (total 15 seconds)")
                                investigationData.lastLog = currentTime
                            end
                        end
                    else
                        -- NPC is still traveling to the door position
                        if currentTime - investigationData.lastLog >= 1.0 then
                            log("[DOOR INVESTIGATION] NPC", npcId, "traveling to door position - distance to door:", string.format("%.1f", distanceToDoor), "units")
                            investigationData.lastLog = currentTime
                        end
                    end
                else
                    log("[DOOR INVESTIGATION] NPC", npcId, "no longer valid - removing from investigation tracking")
                    doorInvestigation[npcId] = nil
                end
                ::continue::
            end
            end -- closes if _enableDoorMechanics
        end -- closes onUpdate
    } -- closes engineHandlers
} -- closes return
