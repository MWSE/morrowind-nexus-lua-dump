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
local settings     = require('scripts.antitheftai.SHOPsettings')
local utils       = require('scripts.antitheftai.modules.utils')
local storage     = require('scripts.antitheftai.modules.storage')   -- module version
local detection   = require('scripts.antitheftai.modules.detection')
local classification = require('scripts.antitheftai.modules.npc_classification')
local pathModule  = require('scripts.antitheftai.modules.path_recording')
local doorModule  = require('scripts.antitheftai.modules.door_transitions')
local state = require('scripts.antitheftai.modules.state')

-- Use the settings module which automatically handles player/global storage context

-- Track which NPCs are currently in search mode
local searchingNPCs = {}

-- Flag to skip cell change logic when teleport spells are used
local skipCellChangeLogic = false
local actions     = require('scripts.antitheftai.modules.guard_actions')
local crossCell   = require('scripts.antitheftai.modules.cross_cell_returns')

----------------------------------------------------------------------
-- Debug logging with live-toggle support
----------------------------------------------------------------------

local seenMessages = {}
local debugEnabled = settings.general:get('enableDebug')  -- initial value

-- refresh when the storage section changes (option toggled in MCM)
settings.general:subscribe(async:callback(function(_, key)
    if key == nil or key == 'enableDebug' then
        debugEnabled = settings.general:get('enableDebug')
        print(('[AntiTheft-Player] debug %s'):format(debugEnabled and 'enabled' or 'disabled'))
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
    if key == nil or key == 'desiredDist' then config.DESIRED_DIST = settings.distances:get('desiredDist') or 100 end
    if key == nil or key == 'losRange' then config.LOS_RANGE = settings.distances:get('losRange') or 1000 end
end))

settings.vars:subscribe(async:callback(function(_, key)
    if key == nil or key == 'losHalfCone' then config.LOS_HALF_CONE = math.rad(settings.vars:get('losHalfCone') or 170) end
    if key == nil or key == 'chamHideLimit' then config.CHAM_HIDE_LIMIT = settings.vars:get('chamHideLimit') or 1 end
    if key == nil or key == 'disableHelloWhileFollowing' then config.DISABLE_HELLO_WHILE_FOLLOWING = settings.vars:get('disableHelloWhileFollowing') or true end
    if key == nil or key == 'factionIgnoreRank' then config.FACTION_IGNORE_RANK = settings.vars:get('factionIgnoreRank') or 5 end
    if key == nil or key == 'dispositionFollowingIgnore' then config.DISPOSITION_FOLLOWING_IGNORE = settings.vars:get('dispositionFollowingIgnore') or 100 end
end))

settings.distances:subscribe(async:callback(function(_, key)
    if key == nil or key == 'detectionRange' then config.DETECTION_RANGE = settings.distances:get('detectionRange') or 75.0 end
end))

----------------------------------------------------------------------
-- Safe module loading
----------------------------------------------------------------------

local function safeRequire(moduleName)
    local success, module = pcall(require, moduleName)
    if not success then
        print('[AntiTheft-Player] ERROR: Failed to load', moduleName, ':', module)
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

if not (self and nearby and types and util and core) then
    error('[AntiTheft-Player] CRITICAL: Required modules failed to load!')
end

----------------------------------------------------------------------
-- Debug logging with live-toggle support
----------------------------------------------------------------------

local function log(...)
    -- Temporarily enabled for debugging - always print
    local args = { ... }
    for i, v in ipairs(args) do
        if type(v) == "string" and v:match("^0x%x+$") then
            -- If it's a hex ID, try to find the NPC in nearby actors
            local npcName = nil
            for _, actor in ipairs(nearby.actors) do
                if actor.id == v and actor.type == types.NPC then
                    local record = types.NPC.record(actor)
                    if record and record.name then
                        npcName = record.name
                        break
                    end
                end
            end
            if npcName then
                args[i] = npcName .. " (" .. v .. ")"
            end
        end
        args[i] = tostring(args[i])
    end
    local msg = table.concat(args, ' ')
    if not seenMessages[msg] then
        print('[AntiTheft-Player]', table.unpack(args))
        seenMessages[msg] = true
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

-- When we have a recruited guard, print the remaining time of the two
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

local function isCellDisabledByAnyRule()
    log("Checking cell disabled rules for cell:", self.cell and self.cell.name or "nil")
    local cellName = self.cell and self.cell.name or ""

    -- Enforce enabled exterior cells: if this exterior cell is enabled, allow it regardless of other rules
    if self.cell and self.cell.isExterior and config.ENABLED_EXTERIOR_CELLS[cellName] then
        log("Exterior cell", cellName, "is in ENABLED_EXTERIOR_CELLS - allowing following")
        return false -- not disabled
    end



    if classification.isCellDisabled(self.cell, disabledCellNames) then return true end
    -- Removed slave/enemy checks to allow script in guild cells with slaves
    -- if classification.shouldDisableCellForSlavesAndEnemies(nearby, types) then return true end
    if classification.shouldDisableCellForOnlyEnemies(nearby, types) then return true end
    if classification.shouldDisableCellForPublican(nearby, types) then return true end
    return false
end

-- Lower disposition of all NPCs in the cell by 15
local function lowerCellDisposition()
    log("=== SENDING GLOBAL EVENT TO LOWER CELL DISPOSITION ===")
    core.sendGlobalEvent('AntiTheft_LowerCellDisposition', {})
    log("=== GLOBAL EVENT SENT ===")
end

----------------------------------------------------------------------
-- Guard Picker
----------------------------------------------------------------------

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

    -- Log the current disposition threshold setting
    local dispositionThreshold = config.DISPOSITION_FOLLOWING_IGNORE
    log("Disposition following ignore threshold:", dispositionThreshold)

    local best = nil
    local bestPriority = 999
    local bestDist = math.huge

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
                        -- Check disposition threshold
                        local npcDisposition = types.NPC.getDisposition(actor, self) or 50
                        log("Checking NPC", actor.id, "- disposition:", npcDisposition, "threshold:", dispositionThreshold)
                        if npcDisposition > dispositionThreshold then
                            log("NPC", actor.id, "has disposition", npcDisposition, "which is above threshold", dispositionThreshold, "- skipping")
                            goto continue
                        end

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
                    ::continue::
                end
            end
        end
    end

    return best, bestPriority
end

----------------------------------------------------------------------
-- Event Handlers
----------------------------------------------------------------------

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

local function onS3CombatTargetAdded(eventData)
    log("DEBUG: S3CombatTargetAdded event received, actor:", eventData and eventData.id or "nil")
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

        if fightingPlayer then
            log("Following NPC entered combat with player - allowing combat to continue")
            state.guardInCombat = true
            state.wasInCombatWithPlayer = true
            -- Don't disband, let the NPC fight the player
        else
            log("Following NPC entered combat with non-player target - disbanding completely")
            -- Disband completely from the player and remove all scripts to allow default behavior
            state.following = false
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

-- Initialize door states when entering interior cell
local function initializeDoorStates()
    log("[DOOR STATE] === INITIALIZING DOOR STATES ===")
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
                    lastCheckTime = core.getRealTime()
                }
                unlockedDoors = unlockedDoors + 1
                log("[DOOR STATE] Tracking unlocked door", doorId, "- state =", doorState, "- lock level =", lockLevel)
            else
                log("[DOOR STATE] Skipping door", doorId, "- locked =", isLocked, "- state =", doorState)
            end
            doorCount = doorCount + 1
        end
    end
    log("[DOOR STATE] === INITIALIZED", doorCount, "total doors,", unlockedDoors, "unlocked doors being tracked ===")
end

-- Check for door state changes and apply bounty if conditions met
local function checkDoorStateChanges()
    log("[DOOR STATE] === CHECKING DOOR STATE CHANGES ===")

    -- Debug: Check if we're in the right cell type
    local isInterior = self.cell and not self.cell.isExterior
    log("[DOOR STATE] Cell check - cell exists:", self.cell ~= nil, "- is interior:", isInterior, "- cell name:", self.cell and self.cell.name or "nil")

    -- Debug: Count all objects and actors
    local totalObjects = 0
    local doorObjects = 0
    local totalActors = 0
    local doorActors = 0
    local npcActors = 0

    -- Count objects (doors are objects)
    if nearby.objects then
        for _, obj in ipairs(nearby.objects) do
            totalObjects = totalObjects + 1
            if obj.type == types.Door then
                doorObjects = doorObjects + 1
            end
        end
    else
        log("[DOOR STATE] WARNING: nearby.objects is nil!")
        return -- Exit early if objects table is nil
    end

    -- Count actors (doors might be actors, NPCs are actors)
    for _, actor in ipairs(nearby.actors) do
        totalActors = totalActors + 1
        if actor.type == types.Door then
            doorActors = doorActors + 1
        elseif actor.type == types.NPC then
            npcActors = npcActors + 1
        end
    end

    log("[DOOR STATE] Object counts - total:", totalObjects, "- doors:", doorObjects)
    log("[DOOR STATE] Actor counts - total:", totalActors, "- doors:", doorActors, "- NPCs:", npcActors)

    local currentTime = core.getRealTime()
    local doorsLocked = 0
    local totalDoors = 0

    -- Check doors in nearby.objects first (doors are objects)
    for _, obj in ipairs(nearby.objects) do
        -- Check if this is a door using multiple methods
        local isDoor = false
        local doorRecord = nil
        local doorName = "unknown"
        local doorRecordId = "unknown"

        if obj.type == types.Door then
            isDoor = true
            doorRecord = types.Door.record(obj)
            if doorRecord then
                doorName = doorRecord.name or "unnamed"
                doorRecordId = doorRecord.id or "no-id"
            end
        end

        if isDoor then
            totalDoors = totalDoors + 1
            local doorId = obj.id
            local isLocked = types.Lockable.isLocked(obj)
            local lockLevel = types.Lockable.getLockLevel(obj)
            local doorState = types.Door.getDoorState(obj)

            log("[DOOR STATE] Found door in objects", doorId, "- name:", doorName, "- record id:", doorRecordId, "- locked =", isLocked, "- lock level =", lockLevel, "- state =", doorState)

            local doorData = doorStates[doorId]

            if doorData then
                -- Check if door was unlocked and is now locked
                if not doorData.wasLocked and isLocked then
                    doorsLocked = doorsLocked + 1
                    log("[DOOR STATE] Door", doorId, "(", doorName, ") was unlocked, now locked - LOCK DETECTED!")

                    -- Check conditions: NPC following and player not in LOS
                    log("[DOOR STATE] Checking conditions - guard exists:", state.guard and state.guard:isValid() or false, "- following:", state.following or false)

                    if state.guard and state.guard:isValid() and state.following then
                        local canSeePlayer = detection.canNpcSeePlayer(state.guard, self, nearby, types, config)
                        log("[DOOR STATE] NPC following, checking LOS - can see player:", canSeePlayer)

                        if not canSeePlayer then
                            log("[DOOR STATE] SUCCESSFUL LOCK DETECTED - NPC following and player not in LOS - APPLYING 150 GOLD BOUNTY")

                            -- Send global event to apply bounty
                            core.sendGlobalEvent('AntiTheft_ApplyLockSpellBounty', {
                                bountyAmount = 150
                            })

                            log("✓ 150 gold bounty applied for successful door lock while NPC is following and player is not in LOS")
                        else
                            log("[DOOR STATE] Door lock successful but player is in LOS - no bounty applied")
                        end
                    else
                        log("[DOOR STATE] Door lock successful but NPC not following - no bounty applied")
                        if not (state.guard and state.guard:isValid()) then
                            log("  - Reason: No valid guard")
                        elseif not state.following then
                            log("  - Reason: NPC not following")
                        end
                    end
                elseif doorData.wasLocked and not isLocked then
                    log("[DOOR STATE] Door", doorId, "(", doorName, ") was locked, now unlocked - UNLOCK DETECTED")
                else
                    log("[DOOR STATE] Door", doorId, "(", doorName, ") state unchanged - locked =", isLocked)
                end

                -- Update door state
                doorStates[doorId] = {
                    wasLocked = isLocked,
                    lastCheckTime = currentTime
                }
            else
                -- New door, initialize it
                log("[DOOR STATE] New door detected, initializing:", doorId, "(", doorName, ")")
                doorStates[doorId] = {
                    wasLocked = isLocked,
                    lastCheckTime = currentTime
                }
            end
        end
    end

    -- Also check doors in nearby.actors (in case they are there too)
    for _, actor in ipairs(nearby.actors) do
        -- Check if this is a door using multiple methods
        local isDoor = false
        local doorRecord = nil
        local doorName = "unknown"
        local doorRecordId = "unknown"

        if actor.type == types.Door then
            isDoor = true
            doorRecord = types.Door.record(actor)
            if doorRecord then
                doorName = doorRecord.name or "unnamed"
                doorRecordId = doorRecord.id or "no-id"
            end
        end

        if isDoor then
            totalDoors = totalDoors + 1
            local doorId = actor.id
            local isLocked = types.Lockable.isLocked(actor)
            local lockLevel = types.Lockable.getLockLevel(actor)
            local doorState = types.Door.getDoorState(actor)

            log("[DOOR STATE] Found door in actors", doorId, "- name:", doorName, "- record id:", doorRecordId, "- locked =", isLocked, "- lock level =", lockLevel, "- state =", doorState)

            local doorData = doorStates[doorId]

            if doorData then
                -- Check if door was unlocked and is now locked
                if not doorData.wasLocked and isLocked then
                    doorsLocked = doorsLocked + 1
                    log("[DOOR STATE] Door", doorId, "(", doorName, ") was unlocked, now locked - LOCK DETECTED!")

                    -- Check conditions: NPC following and player not in LOS
                    log("[DOOR STATE] Checking conditions - guard exists:", state.guard and state.guard:isValid() or false, "- following:", state.following or false)

                    if state.guard and state.guard:isValid() and state.following then
                        local canSeePlayer = detection.canNpcSeePlayer(state.guard, self, nearby, types, config)
                        log("[DOOR STATE] NPC following, checking LOS - can see player:", canSeePlayer)

                        if not canSeePlayer then
                            log("[DOOR STATE] SUCCESSFUL LOCK DETECTED - NPC following and player not in LOS - APPLYING 150 GOLD BOUNTY")

                            -- Send global event to apply bounty
                            core.sendGlobalEvent('AntiTheft_ApplyLockSpellBounty', {
                                bountyAmount = 150
                            })

                            log("✓ 150 gold bounty applied for successful door lock while NPC is following and player is not in LOS")
                        else
                            log("[DOOR STATE] Door lock successful but player is in LOS - no bounty applied")
                        end
                    else
                        log("[DOOR STATE] Door lock successful but NPC not following - no bounty applied")
                        if not (state.guard and state.guard:isValid()) then
                            log("  - Reason: No valid guard")
                        elseif not state.following then
                            log("  - Reason: NPC not following")
                        end
                    end
                elseif doorData.wasLocked and not isLocked then
                    log("[DOOR STATE] Door", doorId, "(", doorName, ") was locked, now unlocked - UNLOCK DETECTED")
                else
                    log("[DOOR STATE] Door", doorId, "(", doorName, ") state unchanged - locked =", isLocked)
                end

                -- Update door state
                doorStates[doorId] = {
                    wasLocked = isLocked,
                    lastCheckTime = currentTime
                }
            else
                -- New door, initialize it
                log("[DOOR STATE] New door detected, initializing:", doorId, "(", doorName, ")")
                doorStates[doorId] = {
                    wasLocked = isLocked,
                    lastCheckTime = currentTime
                }
            end
        end
    end

    log("[DOOR STATE] === CHECK COMPLETE - Total doors:", totalDoors, "- Doors locked this check:", doorsLocked, "===")
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
    log("[LOCK SPELL] Checking if lock spell was successful...")

    local lockedDoors = 0
    local totalCheckedDoors = 0

    -- Check all doors in the cell
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.Door then
            totalCheckedDoors = totalCheckedDoors + 1
            local doorId = actor.id
            local wasUnlocked = preCastDoorStates[doorId]
            local isLocked = types.Lockable.isLocked(actor)

            if wasUnlocked and isLocked then
                lockedDoors = lockedDoors + 1
                log("[LOCK SPELL] Door", doorId, "was unlocked before spell, now locked - SUCCESS!")
            elseif wasUnlocked and not isLocked then
                log("[LOCK SPELL] Door", doorId, "was unlocked before spell, still unlocked - no change")
            end
        end
    end

    log("[LOCK SPELL] Checked", totalCheckedDoors, "doors, found", lockedDoors, "newly locked doors")

    -- Clear the pre-cast states
    preCastDoorStates = {}

    -- If doors were successfully locked, check conditions and apply bounty
    if lockedDoors > 0 then
        -- Check conditions: NPC following and player not in LOS
        if state.guard and state.guard:isValid() and state.following and not detection.canNpcSeePlayer(state.guard, self, nearby, types, config) then
            log("[LOCK SPELL] SUCCESSFUL LOCK SPELL DETECTED - NPC following and player not in LOS - APPLYING 150 GOLD BOUNTY")

            -- Send global event to apply bounty
            core.sendGlobalEvent('AntiTheft_ApplyLockSpellBounty', {
                bountyAmount = 150
            })

            log("✓ 150 gold bounty applied for successful lock spell cast while NPC is following and player is not in LOS")
        else
            log("[LOCK SPELL] Lock spell successful but conditions not met - no bounty applied")
            if not (state.guard and state.guard:isValid() and state.following) then
                log("  - Reason: NPC not following")
            elseif detection.canNpcSeePlayer(state.guard, self, nearby, types, config) then
                log("  - Reason: Player in LOS")
            end
        end
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

    -- Check conditions: NPC following and player not in LOS
    if state.guard and state.guard:isValid() and state.following and not detection.canNpcSeePlayer(state.guard, self, nearby, types, config) then
        log("[LOCK SPELL] SUCCESSFUL LOCK SPELL DETECTED - NPC following and player not in LOS - APPLYING 150 GOLD BOUNTY")

        -- Send global event to apply bounty
        core.sendGlobalEvent('AntiTheft_ApplyLockSpellBounty', {
            bountyAmount = 150
        })

        log("✓ 150 gold bounty applied for successful lock spell cast while NPC is following and player is not in LOS")
    else
        log("[LOCK SPELL] Lock spell successful but conditions not met - no bounty applied")
        if not (state.guard and state.guard:isValid() and state.following) then
            log("  - Reason: NPC not following")
        elseif detection.canNpcSeePlayer(state.guard, self, nearby, types, config) then
            log("  - Reason: Player in LOS")
        end
    end
end

-- Event handler for door bounty application
local function onApplyDoorBounty(data)
    if not data or not data.bountyAmount then return end

    log("[DOOR BOUNTY] Applying door bounty:", data.bountyAmount, "gold")

    -- Since we're in a player script, we need to send the bounty change to a global script
    -- The global script will handle the actual bounty modification
    core.sendGlobalEvent('AntiTheft_SetPlayerBounty', {
        player = self,
        bountyAmount = data.bountyAmount,
        reason = "Door interaction while being followed"
    })

    -- Show message to player
    self:sendEvent('ShowMessage', {
        message = "You have been caught interacting with doors while being followed! Bounty increased by " .. data.bountyAmount .. " gold."
    })

    log("✓ Door bounty event sent to global script")
end

----------------------------------------------------------------------
-- Main Update Loop
----------------------------------------------------------------------

local function onUpdate(dt)
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

    -- Handle effect removal first (before status checks)
    if state.searching or state.following or state.guardInCombat then
        local eff = types.Actor.activeEffects(self)
        local inv = eff:getEffect(config.EFFECT_INVIS)
        local cham = eff:getEffect(config.EFFECT_CHAM)
        local chamMag = cham and cham.magnitude or 0

    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC and ((state.guard and actor.id == state.guard.id) or state.searching or state.disbandedGuards[actor.id]) then
                local distance = (actor.position - self.position):length()

                -- Calculate dynamic removal range for chameleon
                local chamRemovalRange = 450 - 3.5 * chamMag  -- 100% chameleon: 100 units, 0% chameleon: 450 units

                if distance <= config.DETECTION_RANGE or (cham and chamMag >= config.CHAM_HIDE_LIMIT and distance <= chamRemovalRange) then
                    log("[SPELL REMOVAL] Within removal range of NPC", actor.id, "- distance:", math.floor(distance), "chamMag:", chamMag, "chamRange:", math.floor(chamRemovalRange))

                    if inv and inv.magnitude and inv.magnitude > 0 and not detection.removedEffects[config.EFFECT_INVIS] then
                        log("*** REMOVING INVISIBILITY ***")

                        types.Actor.activeEffects(self):remove(config.EFFECT_INVIS)
                        detection.removedEffects[config.EFFECT_INVIS] = true
                        state.justRemovedInvisibility = true

                        self:sendEvent('AddVfx', { model = "meshes/e/magic_cast_ill.NIF" })
                        core.sound.playSoundFile3d("Fx/magic/illusFail.wav", self)
                        lowerCellDisposition()

                        -- If NPC was in combat with player before invisibility, resume combat (after state is set)
                        if state.wasInCombatWithPlayer and state.guard and state.guard.id == actor.id then
                            log("*** RESUMING COMBAT AFTER INVISIBILITY REMOVAL ***")
                            state.guardInCombat = true
                            state.guard:sendEvent('StartAIPackage', {type='Combat', target=self})
                        elseif state.guardInCombat and state.guard and state.guard.id == actor.id then
                            log("*** INVISIBILITY DETECTED DURING COMBAT - STARTING SEARCH ***")
                            actions.startSearch(state, detection, config)
                        end

                        log("*** INVISIBILITY REMOVED ***")
                    elseif cham and chamMag >= config.CHAM_HIDE_LIMIT and not detection.removedEffects[config.EFFECT_CHAM] then
                        log("*** REMOVING CHAMELEON ***")

                        types.Actor.activeEffects(self):remove(config.EFFECT_CHAM)
                        detection.removedEffects[config.EFFECT_CHAM] = true
                        state.justRemovedChameleon = true

                        self:sendEvent('AddVfx', { model = "meshes/e/magic_cast_ill.NIF" })
                        core.sound.playSoundFile3d("Fx/magic/illusFail.wav", self)
                        lowerCellDisposition()

                        log("*** CHAMELEON REMOVED ***")
                    end
                end
            end
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
            log("*** INVISIBILITY EFFECT WORE OFF, NPC SEARCHING BUT NO LOS - DISBANDING AND RETURNING HOME ***")
            actions.goHome(state, core)
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
                                    -- Check disposition threshold
                                    local npcDisposition = types.NPC.getDisposition(actor, self) or 50
                                    log("ForceLOSCheck - Checking NPC", actor.id, "- disposition:", npcDisposition, "threshold:", dispositionThreshold)
                                    if npcDisposition > dispositionThreshold then
                                        log("ForceLOSCheck - NPC", actor.id, "has disposition", npcDisposition, "above threshold", dispositionThreshold, "- skipping")
                                        goto continue
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
                        ::continue::
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
                    actions.followPlayer(state, self, config)
                end
                log("Recruited returned NPC", state.returnedNPCToRecruit, "when conditions met")
                state.returnedNPCToRecruit = nil
            end
        end
        if not isSneakHidden and not isMagicHidden then
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
                    actions.followPlayer(state, self, config)
                end
            end
        end
    end



    -- Helper function to check if all words from str1 are contained in str2
    local function containsAllWords(str1, str2)
        if not str1 or not str2 then return false end
        local words1 = {}
        for word in str1:gmatch("%S+") do
            table.insert(words1, word:lower())
        end
        for _, word in ipairs(words1) do
            if not str2:lower():find(word, 1, true) then
                return false
            end
        end
        return true
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

    -- Check for door state changes (lock spell bounty detection)
    if self.cell and not self.cell.isExterior and nearby.objects then
        checkDoorStateChanges()
    end

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
                if state.guard and state.guard:isValid() then
                    -- Remove AI packages to prevent greeting/hello packages
                    state.guard:sendEvent('RemoveAIPackages')
                    -- Re-send following immediately
                    actions.followPlayer(state, self, config)
                end
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
                    actions.followPlayer(state, self, config)
                end
            end

            -- Check if player becomes invisible
            if isMagicHidden and not state.justRecruitedAfterReturn then
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
                state.tRefresh = state.tRefresh + dt
                if state.tRefresh >= config.UPDATE_PERIOD then
                    state.tRefresh = 0
                    state.lastSeenPlayer = self.position
                    local d = (state.guard.position - self.position):length()
                    if math.abs(d - config.DESIRED_DIST) > config.DIST_TOLERANCE then
                        actions.followPlayer(state, self, config)
                    end
                end
            end

            if isSneakHidden and not state.justRecruitedAfterReturn then
                log("*** PLAYER BECAME STEALTHED WHILE FOLLOWING ***")
                actions.startSearch(state, detection, config)
                lowerCellDisposition()
            else
                state.tRefresh = state.tRefresh + dt
                if state.tRefresh >= config.UPDATE_PERIOD then
                    state.tRefresh = 0
                    state.lastSeenPlayer = self.position
                    local d = (state.guard.position - self.position):length()
                    if math.abs(d - config.DESIRED_DIST) > config.DIST_TOLERANCE then
                        actions.followPlayer(state, self, config)
                    end
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
                    log("*** INVISIBILITY EFFECT WORE OFF, NPC SEARCHING BUT NO LOS - DISBANDING AND RETURNING HOME ***")
                    actions.goHome(state, core)
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
                    self:sendEvent('ShowMessage', {
                        message = config.invisRemovalMessages[math.random(#config.invisRemovalMessages)]
                    })
                    state.stealthMessageSent = true
                end
                -- Clear search state and resume appropriate behavior
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
        end
    end
end

log("=== SCRIPT LOADED SUCCESSFULLY v20.0 - MODULAR ===")

----------------------------------------------------------------------
-- Offset vectors for LOS (from detection.lua)
local vEye   = util.vector3(0, 0, 90)

-- Door detection on Activate key press
local function onInputAction(action)
    if action == input.ACTION.Activate then
        log("[DOOR DETECTION] Activate key pressed - sending detection event to global script")
        core.sendGlobalEvent('AntiTheft_DoorDetection', {})
    end
    if action == input.ACTION.Use then
        log("[DOOR DETECTION] Use key pressed - triggering global door detection")

    -- Send event to global script to check for door lock changes
    core.sendGlobalEvent('AntiTheft_CheckDoorLocks', {
        delay = 1.9  -- Check after 2.5 seconds for lock action to complete
    })

        doorStatesRecorded = false  -- Reset flag after use

        log("[DOOR DETECTION] Global door detection triggered")
    end
end

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
        S3CombatTargetAdded = onS3CombatTargetAdded,
        S3CombatTargetRemoved = onS3CombatTargetRemoved
    }
}
