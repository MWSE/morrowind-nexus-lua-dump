-- Code taken from "SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW" by Łukasz "skrow42" Walczak

local util      = require('openmw.util')

local detection = {}

-- Offset vectors for LOS
local vEye      = util.vector3(0, 0, 90)
local vChest    = util.vector3(0, 0, 60)
local vFeet     = util.vector3(0, 0, 15)

----------------------------------------------------------------------
-- Line of Sight
----------------------------------------------------------------------

local function clearRay(from, to, ignoreNpc, nearby, self)
    local result = nearby.castRay(from, to, {
        collisionType = 3, -- Check static objects (walls, architecture) to block LOS
        ignore = { ignoreNpc, self }
    })

    -- If no collision detected, LOS is clear
    -- If collision detected, LOS is blocked (walls, objects, etc.)
    return not result.hit
end

function detection.canNpcSeePlayer(npc, self, nearby, maxDistance)
    if not self.cell then return false end
    if not (npc and npc:isValid()) then return false end
    if npc.cell ~= self.cell then return false end
    if npc.type.isDead(npc) then return false end

    local toPlayer = self.position - npc.position
    local distance = toPlayer:length()

    if distance > maxDistance then return false end

    local playerChest       = self.position + vChest
    local playerFeet        = self.position + vFeet
    local npcEye            = npc.position + vEye
    local npcChest          = npc.position + vChest

    local eyeToChestClear   = clearRay(npcEye, playerChest, npc, nearby, self)
    local chestToChestClear = clearRay(npcChest, playerChest, npc, nearby, self)
    local eyeToFeetClear    = clearRay(npcEye, playerFeet, npc, nearby, self)

    return eyeToChestClear or chestToChestClear or eyeToFeetClear
end

----------------------------------------------------------------------
-- General distance
----------------------------------------------------------------------

function detection.isWithinDistance(npc, self, maxDistance)
    if not self.cell then return false end
    if not (npc and npc:isValid()) then return false end
    if npc.cell ~= self.cell then return false end
    if npc.type.isDead(npc) then return false end

    local toNpc = npc.position - self.position
    local distance = toNpc:length()

    return distance <= maxDistance
end

return detection
