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
-- Cross-Cell Return Logic
----------------------------------------------------------------------

local utils = require('scripts.antitheftai.modules.utils')
local pathModule = require('scripts.antitheftai.modules.path_recording')

local crossCell = {}

local config = require('scripts.antitheftai.modules.config')
local seenMessages = {}

local function log(...)
    if config.DEBUG then
        local args = {...}
        for i, v in ipairs(args) do
            args[i] = tostring(v)
        end
        local msg = table.concat(args, " ")
        if not seenMessages[msg] then
            print("[CrossCell]", ...)
            seenMessages[msg] = true
        end
    end
end

-- Start cross-cell return
function crossCell.startCrossCellReturn(npcId, currentPos, homeData, cellName, state, core, config)
    local totalDistance = (homeData.pos - currentPos):length()
    
    local shouldWander = not state.npcHasWandered[npcId]
    local wanderDelay = 0
    local wanderEndTime = core.getRealTime()
    
    if shouldWander then
        wanderDelay = config.MIN_WANDER_DELAY + math.random() * (config.MAX_WANDER_DELAY - config.MIN_WANDER_DELAY)
        wanderEndTime = core.getRealTime() + wanderDelay
        state.npcHasWandered[npcId] = false
        log("NPC", npcId, "will wander for", math.floor(wanderDelay), "seconds (FIRST TIME)")
    else
        log("NPC", npcId, "has wandered before - skipping wander")
    end
    
    local waypoints = nil
    if pathModule.pathRecording[npcId] and pathModule.pathRecording[npcId].locked and #pathModule.pathRecording[npcId].waypoints > 1 then
        local recordedPath = pathModule.pathRecording[npcId].waypoints
        
        waypoints = {}
        for i = #recordedPath, 1, -1 do
            table.insert(waypoints, recordedPath[i])
        end
        
        local pathLength = 0
        for i = 1, #waypoints - 1 do
            pathLength = pathLength + (waypoints[i + 1] - waypoints[i]):length()
        end
        
        totalDistance = pathLength
        
        log("═══════════════════════════════════════════════════")
        log("USING STORED LOCKED PATH")
        log("  Waypoints:", #waypoints)
        log("  Recorded path length:", math.floor(pathLength), "units")
        log("═══════════════════════════════════════════════════")
    end
    
    state.returnInProgress[npcId] = true
    state.mustCompleteReturn[npcId] = true
    
    state.crossCellReturns[npcId] = {
        startPos = currentPos,
        homePos = homeData.pos,
        homeRot = homeData.rot,
        departureTime = shouldWander and nil or core.getRealTime(),
        cellName = cellName,
        totalDistance = totalDistance,
        waypoints = waypoints,
        wandering = shouldWander,
        wanderEndTime = wanderEndTime,
        wanderDelay = wanderDelay,
        wanderStartPos = currentPos
    }
    
    if shouldWander then
        local rotX, rotY, rotZ = utils.getEulerAngles(homeData.rot)
        core.sendGlobalEvent('AntiTheft_StartWandering', {
            npcId = npcId,
            wanderPosition = currentPos,
            wanderDistance = config.SEARCH_WDIST,
            wanderDuration = wanderDelay,
            homePosition = homeData.pos,
            homeRotation = { x = rotX, y = rotY, z = rotZ }
        })
    else
        local rotX, rotY, rotZ = utils.getEulerAngles(homeData.rot)
        core.sendGlobalEvent('AntiTheft_StartWalkingHome', {
            npcId = npcId,
            homePosition = homeData.pos,
            homeRotation = { x = rotX, y = rotY, z = rotZ }
        })
    end
end

-- Update wandering NPCs
function crossCell.updateWanderingNPCs(dt, state, core)
    local currentTime = core.getRealTime()
    local currentCellName = require('openmw.self').cell and require('openmw.self').cell.name or nil

    for npcId, returnData in pairs(state.crossCellReturns) do
        if returnData.cellName ~= currentCellName then
            if returnData.wandering then
                if currentTime >= returnData.wanderEndTime then
                    log("═══════════════════════════════════════════════════")
                    log("WANDER DELAY COMPLETE for NPC", npcId)
                    log("  Starting actual return simulation")
                    log("═══════════════════════════════════════════════════")

                    returnData.wandering = false
                    returnData.departureTime = currentTime

                    local rotX, rotY, rotZ = utils.getEulerAngles(returnData.homeRot)
                    core.sendGlobalEvent('AntiTheft_StartWalkingHome', {
                        npcId = npcId,
                        homePosition = returnData.homePos,
                        homeRotation = { x = rotX, y = rotY, z = rotZ }
                    })
                end
            end
        end
    end
end

-- Process returning NPCs in cell
function crossCell.processReturningNPCsInCell(state, nearby, core, config)
    local self = require('openmw.self')
    
    for npcId, returnData in pairs(state.crossCellReturns) do
        if self.cell and self.cell.name == returnData.cellName then
            local npc = utils.findNPC(npcId, nearby)

            if npc and npc:isValid() then
                log("═══════════════════════════════════════════════════")
                log("PLAYER RE-ENTERED CELL - NPC", npcId, "status")

                if returnData.wandering then
                    log("  STARTING REAL-TIME WANDERING for NPC", npcId)
                    
                    -- Wander AI
                    npc:sendEvent('StartAIPackage', {
                        type = 'Wander',
                        distance = config.SEARCH_WDIST,
                        duration = returnData.wanderDelay,
                        cancelOther = true
                    })

                    state.realTimeWandering[npcId] = {
                        startTime = core.getRealTime(),
                        endTime = core.getRealTime() + returnData.wanderDelay,
                        homePos = returnData.homePos,
                        homeRot = returnData.homeRot
                    }

                    log("  ✓ Real-time wandering started")
                else
                    log("  STARTING REAL-TIME WALK HOME for NPC", npcId)

                    local rotX, rotY, rotZ = utils.getEulerAngles(returnData.homeRot)
                    core.sendGlobalEvent('AntiTheft_StartWalkingHome', {
                        npcId = npcId,
                        homePosition = returnData.homePos,
                        homeRotation = { x = rotX, y = rotY, z = rotZ }
                    })

                    log("  ✓ Real-time walk home started")
                end

                log("═══════════════════════════════════════════════════")
            end
        end
    end
end

-- Monitor returning NPCs LOS
function crossCell.monitorReturningNPCsLOS(state, nearby, detection, actions, self, types, config, core)
    for npcId, returnData in pairs(state.crossCellReturns) do
        if self.cell and self.cell.name == returnData.cellName then
            local npc = utils.findNPC(npcId, nearby)
            
            if npc and npc:isValid() then
                if detection.canNpcSeePlayer(npc, self, nearby, types, config) then
                    log("═══════════════════════════════════════════════════")
                    log("LOS REGAINED! NPC", npcId, "can see player")
                    log("  Canceling return - recruiting NPC")
                    
                    core.sendGlobalEvent('AntiTheft_CancelReturn', { npcId = npcId })
                    
                    state.crossCellReturns[npcId] = nil
                    state.returnInProgress[npcId] = nil
                    state.mustCompleteReturn[npcId] = nil
                    
                    actions.recruit(npc, state, detection)
                    if not state.dialogueWasOpen then
                        actions.followPlayer(state, self, config)
                    end
                    
                    log("  ✓ NPC is now following player")
                    log("═══════════════════════════════════════════════════")
                else
                    if not returnData.wandering then
                        local distToHome = (npc.position - returnData.homePos):length()
                        if distToHome < 50 then
                            log("NPC", npcId, "arrived home - finalizing return")

                            local rotX, rotY, rotZ = utils.getEulerAngles(returnData.homeRot)

                            core.sendGlobalEvent('AntiTheft_FinalizeReturn', {
                                npcId = npcId,
                                homePosition = returnData.homePos,
                                homeRotation = { x = rotX, y = rotY, z = rotZ }
                            })

                            state.crossCellReturns[npcId] = nil
                        end
                    end
                end
            else
                log("WARNING: Returning NPC", npcId, "disappeared - cleaning up")
                state.crossCellReturns[npcId] = nil
                state.returnInProgress[npcId] = nil
                state.mustCompleteReturn[npcId] = nil
            end
        end
    end
end

-- Cleanup stale returns
function crossCell.cleanupStaleReturns(state, nearby, types, storage)
    log("Checking for stale return flags...")
    local cleaned = 0
    local self = require('openmw.self')
    
    if self.cell and not self.cell.isExterior then
        for _, actor in ipairs(nearby.actors) do
            if actor.type == types.NPC then
                local npcId = actor.id
                
                if (state.mustCompleteReturn[npcId] or state.returnInProgress[npcId]) and not state.crossCellReturns[npcId] then
                    local homeData = state.npcOriginalData[npcId] or storage.retrieveNPCData(npcId, self.cell, require('openmw.util'))
                    
                    if homeData then
                        local distToHome = (actor.position - homeData.pos):length()
                        
                        if distToHome < 50 then
                            log("  Clearing stale flags for NPC", npcId, "(dist to home:", math.floor(distToHome), ")")
                            state.mustCompleteReturn[npcId] = nil
                            state.returnInProgress[npcId] = nil
                            cleaned = cleaned + 1
                        end
                    end
                end
            end
        end
    end
    
    if cleaned > 0 then
        log("✓ Cleaned", cleaned, "stale return flags")
    end
end

return crossCell