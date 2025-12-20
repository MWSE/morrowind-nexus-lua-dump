-- Global script for door lock detection and bounty application
-- This script monitors door lock level changes and applies bounty when conditions are met

local config = require('scripts.antitheftai.modules.config')
local settings = require('scripts.antitheftai.SHOPsettings') -- Import settings
local async = require('openmw.async')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')

-- Door state tracking for lock spell bounty
local doorStates = {}  -- doorId -> {wasLockLevel = number, preActivateLockLevel = number, doorState = string, lastCheckTime = number}

-- Debug logging
local function log(...)
    print('[AntiTheft-Global-Door]', ...)
end

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
                    wasLockLevel = lockLevel,
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

                            -- Send event to player script to apply bounty and trigger investigation
                            local player = world.players[1]
                            if player then
                                player:sendEvent('AntiTheft_ApplyDoorBounty', {
                                    bountyAmount = 150,
                                    doorX = obj.position.x,
                                    doorY = obj.position.y,
                                    doorZ = obj.position.z
                                })
                                log("✓ Sent door bounty event to player script with door position:", obj.position)
                            else
                                log("ERROR: Could not find player to send door bounty event")
                            end

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

                            -- Send event to player script to apply bounty and trigger investigation
                            local player = world.players[1]
                            if player then
                                player:sendEvent('AntiTheft_ApplyDoorBounty', {
                                    bountyAmount = 150,
                                    doorX = obj.position.x,
                                    doorY = obj.position.y,
                                    doorZ = obj.position.z
                                })
                                log("✓ Sent door bounty event to player script with door position:", obj.position)
                            else
                                log("ERROR: Could not find player to send door bounty event")
                            end

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

-- Event handler for door state recording trigger from player script
local function onRecordDoorStates(eventData)
    log("Received record door states event - initializing door tracking")
    initializeDoorStates()
end

-- Event handler for door lock check trigger from player script
local function onCheckDoorLocks(eventData)
    if eventData and eventData.delay then
        log("Received door lock check trigger, scheduling check in", eventData.delay, "seconds")

        -- Schedule the door check after the specified delay
        async:registerTimerCallback("AntiTheft_CheckDoorLockChanges", function()
            checkDoorStateChanges()
        end, eventData.delay)
    else
        log("Received door lock check trigger without delay, checking immediately")
        checkDoorStateChanges()
    end
end

return {
    eventHandlers = {
        AntiTheft_RecordDoorStates = onRecordDoorStates,
        AntiTheft_CheckDoorLocks = onCheckDoorLocks
    }
}
