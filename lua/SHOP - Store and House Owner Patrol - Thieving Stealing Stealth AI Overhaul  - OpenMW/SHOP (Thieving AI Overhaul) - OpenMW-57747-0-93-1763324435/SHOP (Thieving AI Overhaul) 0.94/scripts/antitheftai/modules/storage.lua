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
-- Persistent Storage Management
----------------------------------------------------------------------

local storage = require('openmw.storage')
local utils = require('scripts.antitheftai.modules.utils')
local state = require('scripts.antitheftai.modules.state')

local storageModule = {}

local npcDataStorage = storage.playerSection('AntiTheftNPCData')

local config = require('scripts.antitheftai.modules.config')
local settings = require('scripts.antitheftai.SHOPsettings')
local seenMessages = {}

local function log(...)
    if settings.general:get("enableDebug") or settings.vars:get("enableGlobalDebug") then
        local args = {...}
        for i, v in ipairs(args) do
            args[i] = tostring(v)
        end
        local msg = table.concat(args, " ")
        if not seenMessages[msg] then
            print("[NPC-AI]", ...)
            seenMessages[msg] = true
        end
    end
end

-- Store NPC data
function storageModule.storeNPCData(npcId, data)
    local key = "npc_" .. tostring(npcId)

    local rotX, rotY, rotZ = 0, 0, 0
    if data.rot then
        rotX, rotY, rotZ = utils.getEulerAngles(data.rot)
    end

    log("Storing NPC", npcId, "- Rot X:", math.deg(rotX),
        "Y:", math.deg(rotY), "Z:", math.deg(rotZ))

    npcDataStorage:set(key, {
        cellName = data.cell.name or "unknown",
        posX = data.pos.x,
        posY = data.pos.y,
        posZ = data.pos.z,
        rotX = rotX,
        rotY = rotY,
        rotZ = rotZ,
        stored = true
    })
end

-- Store combat memory for NPC
function storageModule.storeCombatMemory(npcId, wasInCombatWithPlayer)
    local key = "combat_" .. tostring(npcId)
    npcDataStorage:set(key, {
        wasInCombatWithPlayer = wasInCombatWithPlayer,
        stored = true
    })
    log("Stored combat memory for NPC", npcId, "- wasInCombatWithPlayer:", wasInCombatWithPlayer)
end

-- Retrieve combat memory for NPC
function storageModule.retrieveCombatMemory(npcId)
    local key = "combat_" .. tostring(npcId)
    local data = npcDataStorage:get(key)
    if data and data.stored then
        return data.wasInCombatWithPlayer
    end
    return false
end

-- Retrieve NPC data
function storageModule.retrieveNPCData(npcId, currentCell, util)
    local key = "npc_" .. tostring(npcId)
    local data = npcDataStorage:get(key)
    if data and data.stored then
        return {
            cell = currentCell,
            pos = util.vector3(data.posX, data.posY, data.posZ),
            rot = util.transform.rotateZ(data.rotZ) * 
                  util.transform.rotateY(data.rotY) * 
                  util.transform.rotateX(data.rotX)
        }
    end
    return nil
end

-- Save all NPCs in cell
function storageModule.saveAllNPCsInCell(cell, nearby, types, util)
    if not cell then return end

    local cellName = cell.name or "unknown"
    log("Saving all NPC positions in cell:", cellName)

    local count = 0
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC and not types.Actor.isDead(actor) then
            local existingData = storageModule.retrieveNPCData(actor.id, cell, util)
            if not existingData then
                local npcData = {
                    cell = cell,
                    pos = utils.v3(actor.position),
                    rot = utils.copyRotation(actor.rotation)
                }
                storageModule.storeNPCData(actor.id, npcData)
                count = count + 1
            end

            -- Store original hello value if not already stored
            if not state.originalHelloValues[actor.id] then
                local helloStat = types.NPC.stats.ai.hello(actor)
                if helloStat then
                    state.originalHelloValues[actor.id] = helloStat.base
                    log("[STORAGE] Stored original hello value:", helloStat.base, "for NPC", actor.id)
                end
            end
        end
    end

    log("Saved", count, "new NPC positions")
end

return storageModule