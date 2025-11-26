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
local seenMessages = {}

-- local cache, used by your log() helper
local _enableGlobalDebug = settings:get('enableGlobalDebug') or false
local _enableDebug       = settings:get('enableDebug')       or false

local function log(...)
    if _enableGlobalDebug then
        local args = {...}
        for i, v in ipairs(args) do
            if type(v) == "string" and v:match("^0x%x+$") then
                -- If it's a hex ID, try to find the NPC in active actors
                local npcName = nil
                if world and world.activeActors then
                    for _, actor in ipairs(world.activeActors) do
                        if actor.id == v and actor.type == types.NPC then
                            local record = types.NPC.record(actor)
                            if record and record.name then
                                npcName = record.name
                                break
                            end
                        end
                    end
                end
                if npcName then
                    args[i] = npcName .. " (" .. v .. ")"
                else
                    -- Fallback: just use the ID if name not found
                    args[i] = v
                end
            end
            args[i] = tostring(args[i])
        end
        local msg = table.concat(args, " ")
        if not seenMessages[msg] then
            print("[GlobalWalkBack]", table.unpack(args))
            seenMessages[msg] = true
        end
    end
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
    elseif data.key == 'enableDebug' then
        _enableDebug = data.value
    end
    log('Setting', data.key, 'changed to', tostring(data.value))
end
log("=== GLOBAL SCRIPT LOADING v18.1 ===")

local world = require('openmw.world')
local util  = require('openmw.util')
local core  = require('openmw.core')
local types = require('openmw.types')
local async = require('openmw.async')
local config = require('scripts.antitheftai.modules.config')

local pendingReturns  = {}
local activeRotations = {}
local wanderingNPCs = {}  -- Track NPCs currently wandering
local pendingTeleports = {}  -- Track NPCs waiting to be teleported
local teleportingNPCs = {}  -- Track NPCs currently being teleported home
local teleportTimeouts = {}  -- Track NPCs with 5-minute timeout to return to default position
local dispositionAppliedCells = {}  -- Track cells where disposition penalty has been applied (count up to 2)
local lastPlayerCell = nil  -- Track the last cell the player was in
local searchTimers = {}  -- Track search timers for NPCs
local returnStartTimes = {}  -- Track when NPCs started returning home (for simulation when not loaded)
local recentlyRotated = {}  -- Track NPCs that recently completed rotation to prevent duplicate returns
local doorInitialLockLevels = {}  -- Track initial lock levels for doors (doorId -> lockLevel)
local doorLockCheckDelay = 0  -- Manual delay timer for door lock checks in global script

-- Door lock check function (will be called directly by async timer)
local function performDoorLockCheck()
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
        local initialLockLevel = doorInitialLockLevels[doorId]
        local currentLockLevel = types.Lockable.getLockLevel(closestDoor)

        log("[DOOR DETECTION] Checking door:")
        log("  ID:         " .. tostring(doorId))
        log("  Name:       " .. (doorRecord and doorRecord.name or "unnamed door"))
        log("  Initial Lock Level: " .. tostring(initialLockLevel))
        log("  Current Lock Level: " .. tostring(currentLockLevel))
        log("  Distance:   " .. string.format("%.1f", closestDistance) .. " units")
        log("  Angle:      " .. string.format("%.1f", math.deg(closestAngle)) .. " degrees")

        -- Apply bounty only if lock level changed from 0 to 1-100
        if initialLockLevel and initialLockLevel == 0 and currentLockLevel >= 1 and currentLockLevel <= 100 then
            log("[DOOR DETECTION] Lock level changed from 0 to", currentLockLevel, "- applying bounty")

            -- Send event to player script to apply bounty
            local player = world.players[1]
            if player then
                player:sendEvent('AntiTheft_ApplyDoorBounty', { bountyAmount = 150 })
                log("[DOOR DETECTION] Sent event to player script to apply 150 door bounty")
            else
                log("[DOOR DETECTION] ERROR: Could not find player to send bounty event")
            end
        else
            log("[DOOR DETECTION] Lock level did not change from 0 to 1-100 - no bounty applied")
        end
    else
        log("[DOOR DETECTION] No door detected in range or facing direction")
    end
end

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
            log("✓ NPC", rot.npcId, "ready – can detect player")
        else
            log("ERROR: Could not find player to send ready event")
        end

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

                -- Check if NPC has arrived at target (within 15 units tolerance)
                if dist < 15 then
                    if ret.postTeleportPos then
                        -- Phase 1 complete: arrived at post-teleport position, now teleport to real home
                        log("NPC", ret.npcId, "arrived at post-teleport position - teleporting to real home position")

                        -- Teleport directly to home position with rotation
                        local npc = findNPC(ret.npcId)
                        if npc and npc:isValid() then
                            npc:sendEvent('RemoveAIPackages')

                            log("NPC", ret.npcId, "reached home. Applying direct rotation teleport")
                            log("  Target rotation - X:", math.deg(ret.homeRotation.x), "Y:", math.deg(ret.homeRotation.y), "Z:", math.deg(ret.homeRotation.z))

                            -- Build final rotation transform
                            local finalRot = util.transform.rotateZ(ret.homeRotation.z) *
                                             util.transform.rotateY(ret.homeRotation.y) *
                                             util.transform.rotateX(ret.homeRotation.x)

                            -- Teleport NPC to home position with correct rotation
                            npc:teleport(npc.cell.name, ret.exactHomePosition, {
                                rotation = finalRot,
                                onGround = true
                            })

                            log("NPC teleported to home with rotation - COMPLETE")

                            -- Send ready event immediately
                            local player = world.players[1]
                            if player then
                                player:sendEvent('AntiTheft_NPCReady', { npcId = ret.npcId })
                                player:sendEvent('AntiTheft_ClearSearchState', { npcId = ret.npcId })
                                log("  ✓ Sent NPCReady and ClearSearchState events")
                            end

                            -- Enable default AI behavior after teleporting home
                            npc:sendEvent('AntiTheft_EnableDefaultAI')
                        end

                        -- Clear two-phase return state
                        local state = require('scripts.antitheftai.modules.state')
                        state.postTeleportPositions[ret.npcId] = nil
                        state.twoPhaseReturns[ret.npcId] = nil

                        -- Remove from pending returns
                        table.remove(pendingReturns, i)
                        i = i - 1
                    else
                        -- Normal return: arrived home, start rotation
                        log("NPC", ret.npcId, "arrived home (within 15 units) - starting rotation to base position")

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

    local npc = findNPC(data.npcId)
    if npc and npc:isValid() then
        log("  ✓ NPC found in loaded cells - sending travel package")
        log("  Home position:", data.homePosition)

        npc:sendEvent('RemoveAIPackages')
        npc:sendEvent('StartAIPackage', {
            type = 'Travel',
            destPosition = data.homePosition,
            cancelOther = true
        })

        log("  ✓ Travel package sent - NPC will walk to home")
        log("  Distance:", math.floor((npc.position - data.homePosition):length()), "units")
    else
        log("  NPC not in loaded cells (unexpected for real-time return)")
    end

    -- Inherit rotation logic from working return function
    table.insert(pendingReturns, {
        npcId              = data.npcId,
        exactHomePosition  = data.homePosition,
        homeRotation       = data.homeRotation,
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
        log("  Starting rotation to home orientation")
        startGlobalRotation(npc, data.homeRotation, 0.5, data.homePosition, data.homeRotation)
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
        -- NPC is loaded, teleport immediately
        finalizeNPCReturn(data.npcId, data.homePosition, data.homeRotation)
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

    -- Get current bounty
    local currentBounty = types.Player.getBounty(player) or 0
    log("  Current bounty:", currentBounty)

    -- Add the bounty amount
    types.Player.setBounty(player, currentBounty + data.bountyAmount)
    log("  New bounty:", currentBounty + data.bountyAmount)

    -- Show message to player
    player:sendEvent('ShowMessage', {
        message = "You have been caught locking doors while being followed! Bounty increased by " .. data.bountyAmount .. " gold."
    })

    log("✓ Lock spell bounty applied successfully")
    log("═══════════════════════════════════════════════════")
end

-- ★★★ EVENT: Door Detection ★★★
local function onDoorDetection(data)
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

        log("[DOOR DETECTION] Door detected:")
        log("  ID:         " .. tostring(closestDoor.id))
        log("  Name:       " .. (doorRecord and doorRecord.name or "unnamed door"))
        log("  Locked:     " .. tostring(types.Lockable.isLocked(closestDoor)))
        log("  Lock Level: " .. tostring(types.Lockable.getLockLevel(closestDoor)))
        log("  State:      " .. tostring(types.Door.getDoorState(closestDoor)))
        log("  Is Closed:  " .. tostring(types.Door.isClosed(closestDoor)))
        log("  Is Open:    " .. tostring(types.Door.isOpen(closestDoor)))
        log("  Is Teleport:" .. tostring(types.Door.isTeleport(closestDoor)))
        log("  Distance:   " .. string.format("%.1f", closestDistance) .. " units")
        log("  Angle:      " .. string.format("%.1f", math.deg(closestAngle)) .. " degrees")

        -- Save initial lock level for this door if not already tracked
        local doorId = closestDoor.id
        if not doorInitialLockLevels[doorId] then
            local initialLockLevel = types.Lockable.getLockLevel(closestDoor)
            doorInitialLockLevels[doorId] = initialLockLevel
            log("[DOOR DETECTION] Saved initial lock level for door", doorId, ":", initialLockLevel)
        end
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
    log("[DOOR DETECTION] Global script received CheckDoorLocks event")

    local delay = data.delay or 1.9  -- Default to 2.5 seconds if not specified
    log("[DOOR DETECTION] Delaying check by", delay, "seconds")

    -- Use manual delay timer for global scripts since async:newSimulationTimer is not available
    doorLockCheckDelay = delay
end

local function performDoorLockCheck()
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
        local initialLockLevel = doorInitialLockLevels[doorId]
        local currentLockLevel = types.Lockable.getLockLevel(closestDoor)

        log("[DOOR DETECTION] Checking door:")
        log("  ID:         " .. tostring(doorId))
        log("  Name:       " .. (doorRecord and doorRecord.name or "unnamed door"))
        log("  Initial Lock Level: " .. tostring(initialLockLevel))
        log("  Current Lock Level: " .. tostring(currentLockLevel))
        log("  Distance:   " .. string.format("%.1f", closestDistance) .. " units")
        log("  Angle:      " .. string.format("%.1f", math.deg(closestAngle)) .. " degrees")

        -- Apply bounty only if lock level changed from 0 to 1-100
        if initialLockLevel and initialLockLevel == 0 and currentLockLevel >= 1 and currentLockLevel <= 100 then
            log("[DOOR DETECTION] Lock level changed from 0 to", currentLockLevel, "- applying bounty")

            -- Send event to player script to apply bounty
            local player = world.players[1]
            if player then
                player:sendEvent('AntiTheft_ApplyDoorBounty', { bountyAmount = 150 })
                log("[DOOR DETECTION] Sent event to player script to apply 150 door bounty")
            else
                log("[DOOR DETECTION] ERROR: Could not find player to send bounty event")
            end
        else
            log("[DOOR DETECTION] Lock level did not change from 0 to 1-100 - no bounty applied")
        end
    else
        log("[DOOR DETECTION] No door detected in range or facing direction")
    end
end

-- ★★★ EVENT: Set Player Bounty ★★★
local function onSetPlayerBounty(data)
    if not data or not data.player or not data.bountyAmount then
        log("[GLOBAL] Error: Invalid bounty data received")
        return
    end

    -- Get current bounty
    local currentBounty = types.Player.getCrimeLevel(data.player)
    local newBounty = currentBounty + data.bountyAmount

    -- Set new bounty (only works in global scripts)
    types.Player.setCrimeLevel(data.player, newBounty)

    log("[GLOBAL] Applied bounty:", data.bountyAmount, "to player - new total:", newBounty)
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

log("=== GLOBAL SCRIPT LOADED SUCCESSFULLY v18.1 ===")

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
        AntiTheft_StartSearchTimer = onStartSearchTimer,
        AntiTheft_ApplyLockSpellBounty = onApplyLockSpellBounty,
        AntiTheft_DoorDetection = onDoorDetection,
        AntiTheft_CheckDoorLocks = onCheckDoorLocks,
        AntiTheft_SetPlayerBounty = onSetPlayerBounty
    },
    engineHandlers = {
        onUpdate = function(dt)
            processPendingReturns(dt)
            updateGlobalRotations(dt)

            -- Check for cell change to reset disposition tracking
            local player = world.players[1]
            if player and player.cell then
                if lastPlayerCell ~= player.cell.name then
                    if lastPlayerCell then
                        log("Player left cell", lastPlayerCell, "- resetting disposition tracking")
                    end
                    lastPlayerCell = player.cell.name
                    -- Reset disposition tracking for the new cell
                    dispositionAppliedCells[player.cell.name] = nil
                    log("Player entered cell", player.cell.name, "- disposition can be applied again")
                end
            end

            -- Process pending teleports
            for npcId, teleportData in pairs(pendingTeleports) do
                local npc = findNPC(npcId)
                if npc and npc:isValid() then
                    log("Processing pending teleport for NPC", npcId)
                    finalizeNPCReturn(npcId, teleportData.homePosition, teleportData.homeRotation)
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
        end
    }
}
