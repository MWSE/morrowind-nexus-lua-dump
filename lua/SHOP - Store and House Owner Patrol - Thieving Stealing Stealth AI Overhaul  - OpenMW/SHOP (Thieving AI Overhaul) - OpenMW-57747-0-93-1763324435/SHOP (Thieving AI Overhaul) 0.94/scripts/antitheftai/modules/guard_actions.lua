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
----------------------------------------------------------------------
-- Guard Actions (Recruit, Follow, Search, Home)
----------------------------------------------------------------------

local utils = require('scripts.antitheftai.modules.utils')
local pathModule = require('scripts.antitheftai.modules.path_recording')
local storage = require('scripts.antitheftai.modules.storage')
local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local actions = {}

local config = require('scripts.antitheftai.modules.config')
local settings = require('scripts.antitheftai.SHOPsettings')
local vars     = settings.vars
local seenMessages = {}

local function log(...)
    if settings.general:get("enableDebug") then
        local args = {...}
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
        local msg = table.concat(args, " ")
        if not seenMessages[msg] then
            print("[NPC-AI]", table.unpack(args))
            seenMessages[msg] = true
        end
    end
end

-- Recruit guard
function actions.recruit(npc, state, detection, self)
    if not npc then return end

    local classification = require('scripts.antitheftai.modules.npc_classification')
    local types = require('openmw.types')

    log("[RECRUIT] Recruiting NPC", npc.id)

    if state.mustCompleteReturn[npc.id] or state.returnInProgress[npc.id] then
        return
    end

    -- Check if we already have a different following guard in this cell
    local cellName = npc.cell.name or ""
    if state.guardsPerCell[cellName] and state.guardsPerCell[cellName].following and state.guardsPerCell[cellName].guard.id ~= npc.id then
        -- Allow recruiting if the current guard is being sent home (for hierarchy switches) or if new NPC has higher priority
        local currentGuardId = state.guardsPerCell[cellName].guard.id
        local newPriority = classification.getNPCPriority(npc, types, self, npc.cell, config, require('openmw.nearby'))
        local currentPriority = state.guardPriority or 999
        if not state.returnInProgress[currentGuardId] and newPriority >= currentPriority then
            log("[RECRUIT] Already have a different following guard in cell", cellName, "with equal/higher priority - cannot recruit another")
            return
        end
    end

    local storedData = storage.retrieveNPCData(npc.id, npc.cell, require('openmw.util'))

    if storedData then
        state.npcOriginalData[npc.id] = storedData
    elseif not state.npcOriginalData[npc.id] then
        state.npcOriginalData[npc.id] = {
            cell = npc.cell,
            pos = utils.v3(npc.position),
            rot = utils.copyRotation(npc.rotation)
        }
        storage.storeNPCData(npc.id, state.npcOriginalData[npc.id])
    end

    -- If there's already a guard, send it home first
    if state.guard and state.guard.id ~= npc.id then
        log("[RECRUIT] Sending current guard", state.guard.id, "home before recruiting new guard", npc.id)
        actions.goHome(state, core)
    end

    state.guard = npc
    -- attach
    if npc.addScript and not npc:hasScript('scripts/antitheftai/guardCombatForward') then
        npc:addScript('scripts/antitheftai/guardCombatForward')
    else
        -- fallback: remember that this NPC is a guard so we can
        -- still resume combat via the global timer (see below)
        state.activeGuards[npc.id] = true
    end
    state.guardPriority = classification.getNPCPriority(npc, types, self, npc.cell, config, require('openmw.nearby'))
    state.home = state.npcOriginalData[npc.id]

    -- Set guard per cell
    state.guardsPerCell[cellName] = { guard = npc, following = false }

    state.following = false
    state.searching = false
    state.ernBurglarySpottedInvoked = false  -- Reset flag when recruiting a new NPC
    state.searchTimerStarted = false  -- Reset search timer flag for new NPC

    -- Clear invisibility and chameleon removal flags when recruiting
    detection.removedEffects[require('scripts.antitheftai.modules.config').EFFECT_INVIS] = nil
    detection.removedEffects[require('scripts.antitheftai.modules.config').EFFECT_CHAM] = nil

    -- Check if this NPC has combat memory from previous encounters
    local hasCombatMemory = false
    if state.disbandedGuards[npc.id] and state.disbandedGuards[npc.id].wasInCombatWithPlayer then
        hasCombatMemory = true
    elseif storage.retrieveCombatMemory(npc.id) then
        hasCombatMemory = true
        -- Restore to runtime state if not already there
        if not state.disbandedGuards[npc.id] then
            state.disbandedGuards[npc.id] = { wasInCombatWithPlayer = true }
        end
    end

    if hasCombatMemory then
        log("[RECRUIT] NPC", npc.id, "has combat memory - starting combat immediately")
        state.guardInCombat = true
        state.wasInCombatWithPlayer = true
        -- Start combat AI package to attack the player
        npc:sendEvent('StartAIPackage', {type='Combat', target=require('openmw.self')})
        -- Clear from disbanded guards list since we're resuming combat
        state.disbandedGuards[npc.id] = nil
        return
    end
end

-- Follow player
function actions.followPlayer(state, self, config)
    if not (state.guard and state.guard:isValid()) then return end

    log("[FOLLOW] Starting follow for NPC", state.guard.id)

    -- Set hello to 0 when following to prevent greeting packages (only once per NPC, if setting enabled)
    if config.DISABLE_HELLO_WHILE_FOLLOWING and state.originalHelloValues[state.guard.id] and not state.helloSet[state.guard.id] then
        state.guard:sendEvent('AntiTheft_SetHello', {
            value = 0
        })
        state.helloSet[state.guard.id] = true
        log("[FOLLOW] Sent event to set hello to 0 for NPC", state.guard.id, "(original was", state.originalHelloValues[state.guard.id], ")")
    end

    -- Set alarm to 100 when following to increase combat awareness (only once per NPC)
    if state.originalAlarmValues[state.guard.id] and not state.alarmSet[state.guard.id] then
        state.guard:sendEvent('AntiTheft_SetAlarm', {
            value = 100
        })
        state.alarmSet[state.guard.id] = true
        log("[FOLLOW] Sent event to set alarm to 100 for NPC", state.guard.id, "(original was", state.originalAlarmValues[state.guard.id], ")")
    end

    state.guard:sendEvent('StartAIPackage', {
        type = 'Travel',
        destPosition = utils.ring(self.position, state.guard.position, config.DESIRED_DIST),
        cancelOther = true
    })

    if not pathModule.pathRecording[state.guard.id] or
       (not pathModule.pathRecording[state.guard.id].locked and
        not pathModule.pathRecording[state.guard.id].recordingActive) then
        pathModule.startPathRecording(state.guard.id, state.guard)
    end

    state.following = true
    state.searching = false
    state.returningHome = false
    state.lastSeenPlayer = self.position
    log("[FOLLOW] Now following player")

    -- Update guards per cell to mark as following
    local cellName = state.guard.cell.name or ""
    if state.guardsPerCell[cellName] then
        state.guardsPerCell[cellName].following = true
    end

    -- Start LOS monitoring for the recruited NPC
    if state.guard and state.guard:isValid() then
        log("[FOLLOW] Starting LOS monitoring for recruited NPC", state.guard.id)
        -- LOS monitoring is handled in the main update loop, but we can force an initial check
        state.forceLOSCheck = true
    end

    -- Check for ErnBurglary integration - only invoke once per NPC following start
    if not state.ernBurglarySpottedInvoked then
        local success, mod = pcall(require, "scripts.ErnBurglary.interface")
        if success and mod and mod.interface and mod.interface.spotted and settings.compatibility:get("enableErnBurglarySpotted") then
            print("[NPC-AI] [FOLLOW] Invoking ErnBurglary spotted function")
            mod.interface.spotted(self, state.guard, false)
            state.ernBurglarySpottedInvoked = true
        end
    end
end

-- Start search/wander
function actions.startWandering(state, config)
    if not (state.guard and state.guard:isValid()) then return end

    log("[WANDER] Starting wander for NPC", state.guard.id)

    if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
        pathModule.stopPathRecording(state.guard.id, state.guard.position)
    end

    -- Wander AI
    local function wander(n, dist, dur)
        n:sendEvent('StartAIPackage', {
            type = 'Wander',
            distance = dist,
            duration = dur,
            cancelOther = false
        })
    end

    -- Use fixed wander time if set, otherwise random range
    local wanderTime
    if config.FIXED_WANDER_TIME and config.FIXED_WANDER_TIME > 0 then
        wanderTime = config.FIXED_WANDER_TIME
    else
        wanderTime = config.MIN_WANDER_DELAY + math.random() * (config.MAX_WANDER_DELAY - config.MIN_WANDER_DELAY)
    end
    wander(state.guard, config.SEARCH_WDIST, wanderTime)

    state.following = false
    state.searching = false
    state.returningHome = false
    state.searchT = 0

    log("[WANDER] Wandering randomly")
end

-- Start search/wander
function actions.startSearch(state, detection, config)
    if not (state.guard and state.guard:isValid()) then return end
    
    log("[SEARCH] Starting wander at last known location for NPC", state.guard.id)
    log("[SEARCH] Player became invisible")
    
    if pathModule.pathRecording[state.guard.id] and pathModule.pathRecording[state.guard.id].recordingActive then
        pathModule.stopPathRecording(state.guard.id, state.guard.position)
    end
    
    -- Clear the invisibility and chameleon removal flags
    detection.removedEffects[config.EFFECT_INVIS] = nil
    detection.removedEffects[config.EFFECT_CHAM] = nil
    state.invisMessageSent = false
    state.stealthMessageSent = false
    
    if state.lastSeenPlayer then
        log("[SEARCH] Last seen position:", state.lastSeenPlayer)
        state.guard:sendEvent('StartAIPackage', {
            type = 'Travel',
            destPosition = state.lastSeenPlayer,
            cancelOther = true
        })
    end
    
    -- Wander AI
    local function wander(n, dist, dur)
        n:sendEvent('StartAIPackage', {
            type = 'Wander',
            distance = dist,
            duration = dur,
            cancelOther = false
        })
    end

    -- Use fixed search time if set, otherwise random range
    if not state.searchTime then
        if config.FIXED_SEARCH_TIME > 0 then
            state.searchTime = config.FIXED_SEARCH_TIME
        else
            state.searchTime = config.SEARCH_WTIME_MIN + math.random() * (config.SEARCH_WTIME_MAX - config.SEARCH_WTIME_MIN)
        end
    end
    wander(state.guard, config.SEARCH_WDIST, state.searchTime)

    -- Send global event to start search timer (only once per search start)
    if not state.searchTimerStarted then
        local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)
        core.sendGlobalEvent('AntiTheft_StartSearchTimer', {
            npcId = state.guard.id,
            searchTime = state.searchTime,
            searchDistance = config.SEARCH_WDIST,
            homePosition = state.home.pos,
            homeRotation = { x = rotX, y = rotY, z = rotZ },
            startPosition = state.guard.position,
            walkRotation = state.guard.rotation:getAnglesZYX(),
            cellName = state.guard.cell.name
        })
        state.searchTimerStarted = true
        log("[SEARCH] Search timer started for NPC", state.guard.id)
    end

    state.following = false
    state.searching = true
    state.returningHome = false
    state.searchT = 0
    
    log("[SEARCH] Wandering at last known player location")
end

-- Go home
function actions.goHome(state, core)
    if not state.guard or not state.home then return end

    local guardId = state.guard.id

    if pathModule.pathRecording[guardId] and pathModule.pathRecording[guardId].recordingActive then
        pathModule.stopPathRecording(guardId, state.guard.position)
    end

    state.returnInProgress[guardId] = true
    state.mustCompleteReturn[guardId] = true

    local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)

    local waypointCount = pathModule.pathRecording[guardId] and #pathModule.pathRecording[guardId].waypoints or 0
    log("Sending NPC", guardId, "home with", waypointCount, "recorded waypoints")

    -- Include original hello value for restoration
    local originalHello = state.originalHelloValues[guardId] or 0

    core.sendGlobalEvent('AntiTheft_StartReturnHome', {
        npcId = guardId,
        homePosition = state.home.pos,
        homeRotation = {
            x = rotX,
            y = rotY,
            z = rotZ
        },
        originalHelloValue = originalHello
    })

    -- Restore hello value to default when disbanding (if it was set to 0)
    if config.DISABLE_HELLO_WHILE_FOLLOWING and state.helloSet[guardId] then
        state.guard:sendEvent('AntiTheft_SetHello', {
            value = originalHello
        })
        state.helloSet[guardId] = nil
        log("[GO HOME] Restored hello value to", originalHello, "for NPC", guardId)
    end

    -- Restore alarm value to default when disbanding (if it was set to 100)
    if state.alarmSet[guardId] then
        local originalAlarm = state.originalAlarmValues[guardId] or 0
        state.guard:sendEvent('AntiTheft_SetAlarm', {
            value = originalAlarm
        })
        state.alarmSet[guardId] = nil
        log("[GO HOME] Restored alarm value to", originalAlarm, "for NPC", guardId)
    end

    -- detach
    if state.guard and state.guard:isValid() then
        if state.guard.removeScript and state.guard:hasScript('scripts/antitheftai/guardCombatForward') then
            state.guard:removeScript('scripts/antitheftai/guardCombatForward')
        end
    end
    state.activeGuards[state.guard.id] = nil      -- always clear the table entry

    state.following = false
    state.searching = false
    state.returningHome = true
    state.searchT = 0

    -- Clear guard per cell when going home
    local cellName = state.guard.cell.name or ""
    if state.guardsPerCell[cellName] then
        state.guardsPerCell[cellName] = nil
    end

    state.guard = nil  -- Clear guard reference to allow recruitment of another NPC
end

-- Send pending returns home
function actions.sendPendingReturnsHome(npc, state, core)
    if not npc then return end

    local storedData = storage.retrieveNPCData(npc.id, npc.cell, require('openmw.util'))
    local npcHome

    if storedData then
        npcHome = storedData
    elseif state.npcOriginalData[npc.id] then
        npcHome = state.npcOriginalData[npc.id]
    else
        npcHome = {
            cell = npc.cell,
            pos = utils.v3(npc.position),
            rot = utils.copyRotation(npc.rotation)
        }
        storage.storeNPCData(npc.id, npcHome)
    end

    state.returnInProgress[npc.id] = true
    state.mustCompleteReturn[npc.id] = true

    local rotX, rotY, rotZ = utils.getEulerAngles(npcHome.rot)

    core.sendGlobalEvent('AntiTheft_StartReturnHome', {
        npcId = npc.id,
        homePosition = npcHome.pos,
        homeRotation = {
            x = rotX,
            y = rotY,
            z = rotZ
        }
    })
end

-- Teleport home instantly (for spell teleports)
function actions.teleportHome(state, core)
    if not state.guard or not state.home then return end

    local guardId = state.guard.id

    if pathModule.pathRecording[guardId] and pathModule.pathRecording[guardId].recordingActive then
        pathModule.stopPathRecording(guardId, state.guard.position)
    end

    state.returnInProgress[guardId] = true
    state.mustCompleteReturn[guardId] = true

    local rotX, rotY, rotZ = utils.getEulerAngles(state.home.rot)

    log("Instantly teleporting NPC", guardId, "home due to spell teleport")

    -- Use global event to teleport the NPC (player script cannot directly teleport NPCs)
    core.sendGlobalEvent('AntiTheft_TeleportHome', {
        npcId = guardId,
        homePosition = state.home.pos,
        homeRotation = {
            x = rotX,
            y = rotY,
            z = rotZ
        }
    })

    state.following = false
    state.searching = false
    state.returningHome = true
    state.searchT = 0
end

return actions