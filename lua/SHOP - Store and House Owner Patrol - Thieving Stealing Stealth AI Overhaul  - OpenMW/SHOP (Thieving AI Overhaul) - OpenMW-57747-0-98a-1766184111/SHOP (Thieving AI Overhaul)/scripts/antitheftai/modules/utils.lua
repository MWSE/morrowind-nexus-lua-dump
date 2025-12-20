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
-- Utility Functions
----------------------------------------------------------------------

local util = require('openmw.util')

local utils = {}

-- Vector3 helper
function utils.v3(v)
    return util.vector3(v.x, v.y, v.z)
end

-- Copy rotation
function utils.copyRotation(rot)
    if type(rot) == 'table' then
        return util.transform.rotateZ(rot.z or 0) * 
               util.transform.rotateY(rot.y or 0) * 
               util.transform.rotateX(rot.x or 0)
    else
        local z, y, x = rot:getAnglesZYX()
        return util.transform.rotateZ(z) * 
               util.transform.rotateY(y) * 
               util.transform.rotateX(x)
    end
end

-- Extract Euler angles
function utils.getEulerAngles(rotation)
    if type(rotation) == 'table' then
        return rotation.x or 0, rotation.y or 0, rotation.z or 0
    else
        local z, y, x = rotation:getAnglesZYX()
        return x, y, z
    end
end

-- Calculate ring position around player
function utils.ring(playerPos, npcPos, desiredDistMin, desiredDistMax)
    local d = npcPos - playerPos
    if d:length() < 1 then d = util.vector3(1, 0, 0) end
    
    -- Use random distance between min and max
    local desiredDist = desiredDistMin + math.random() * (desiredDistMax - desiredDistMin)
    return playerPos + d:normalize() * desiredDist
end

-- Check if NPC is friendly
function utils.friendly(npc, player, types, nearby)
    local isFriendly = not types.Actor.isDead(npc)
       and (types.NPC.getDisposition(npc, player) or 50) >= 30
       and types.Actor.stats.ai.fight(npc).modified < 80

    -- In guild cells, be more lenient with disposition if player is not in the faction
    if nearby and not isFriendly then
        local classification = require('scripts.antitheftai.modules.npc_classification')
        local cellFaction = classification.detectCellFaction(nearby, types)
        if cellFaction then
            local playerInFaction = false
            local playerFactions = types.NPC.getFactions(player)
            for _, factionId in ipairs(playerFactions) do
                if factionId == cellFaction then
                    playerInFaction = true
                    break
                end
            end
            if not playerInFaction then
                -- Player not in guild faction, so ignore disposition and fight rating for guild NPCs
                isFriendly = not types.Actor.isDead(npc) and types.Actor.stats.ai.fight(npc).modified < 80
            end
        end
    end

    return isFriendly
end

-- Find NPC by ID
function utils.findNPC(npcId, nearby)
    for _, actor in ipairs(nearby.actors) do
        if actor.id == npcId then return actor end
    end
    return nil
end

return utils