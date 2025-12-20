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
-- Detection Systems (LOS, Sneak, Magic)
----------------------------------------------------------------------

local util = require('openmw.util')

local detection = {}

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
            print("[Detection]", ...)
            seenMessages[msg] = true
        end
    end
end

-- Offset vectors for LOS
local vEye   = util.vector3(0, 0, 90)
local vChest = util.vector3(0, 0, 60)
local vFeet  = util.vector3(0, 0, 15)

-- Sneak detection state
local lastSneakTick = math.huge

-- Magic hidden state tracking
local lastMagicHiddenState = false

-- Effect removal tracking
detection.removedEffects = {}

----------------------------------------------------------------------
-- Line of Sight
----------------------------------------------------------------------

local function clearRay(from, to, ignoreNpc, nearby, self)
    local result = nearby.castRay(from, to, {
        collisionType = 3,  -- Check static objects (walls, architecture) to block LOS
        ignore = {ignoreNpc, self}
    })

    -- If no collision detected, LOS is clear
    if not result.hit then return true end

    -- If collision detected, LOS is blocked (walls, objects, etc.)
    return false
end

function detection.canNpcSeePlayer(npc, self, nearby, types, config)
    if not self.cell or self.cell.isExterior then return false end
    if not (npc and npc:isValid()) then return false end
    if npc.cell ~= self.cell then return false end
    if types.Actor.isDead(npc) then return false end

    local toPlayer = self.position - npc.position
    local distance = toPlayer:length()

    if distance > config.LOS_RANGE then return false end

    local npcForward = npc.rotation:apply(util.vector3(0, 1, 0))
    local angleToPlayer = npcForward:dot(toPlayer:normalize())

    if angleToPlayer < math.cos(config.LOS_HALF_CONE) then return false end

    local playerChest = self.position + vChest
    local playerFeet  = self.position + vFeet
    local npcEye      = npc.position + vEye
    local npcChest    = npc.position + vChest

    local eyeToChestClear = clearRay(npcEye, playerChest, npc, nearby, self)
    local chestToChestClear = clearRay(npcChest, playerChest, npc, nearby, self)
    local eyeToFeetClear = clearRay(npcEye, playerFeet, npc, nearby, self)

    return eyeToChestClear or chestToChestClear or eyeToFeetClear
end


function detection.sneakHidden(self, types, config, guard, nearby)
    -- Check if the sneak icon is displayed by checking if the player is sneaking
    -- The sneak icon "Icons\k\Stealth_Sneak.dds" is displayed when the player is in sneak mode
    -- AND the player is not in any NPC's line of sight
    if not self.controls.sneak then return false end

    -- Check if any NPC can see the player
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC and actor:isValid() and not types.Actor.isDead(actor) then
            if detection.canNpcSeePlayer(actor, self, nearby, types, config) then
                return false  -- Player is visible to at least one NPC
            end
        end
    end

    return true  -- Player is sneaking and not visible to any NPC
end

----------------------------------------------------------------------
-- Magic Detection
----------------------------------------------------------------------

function detection.magicHidden(self, types, config)
    log("[MAGIC] Checking magic hidden state...")
    
    local eff = types.Actor.activeEffects(self)
    if not eff then
        log("[MAGIC] ERROR: Could not get active effects")
        return false
    end
    
    -- Check invisibility
    local inv = eff:getEffect(config.EFFECT_INVIS)
    local hasInvis = false
    
    if inv and inv.magnitude and inv.magnitude > 0 then
        hasInvis = true
        log("[MAGIC] Invisibility IS ACTIVE (magnitude:", inv.magnitude, ")")
    else
        log("[MAGIC] No invisibility effect detected")
    end
    
    -- Check chameleon
    local ch = eff:getEffect(config.EFFECT_CHAM)
    local chamMag = 0
    local hasCham = false
    
    if ch then
        chamMag = ch.magnitude or 0
        log("[MAGIC] Chameleon magnitude:", chamMag, "threshold:", config.CHAM_HIDE_LIMIT)
        if chamMag >= config.CHAM_HIDE_LIMIT then
            hasCham = true
            log("[MAGIC] Player HAS chameleon active")
        end
    end
    
    local isHidden = hasInvis or hasCham
    
    -- Log state changes
    if isHidden ~= lastMagicHiddenState then
        log("*** MAGIC HIDDEN STATE CHANGED ***")
        log("  Was:", lastMagicHiddenState and "HIDDEN" or "VISIBLE")
        log("  Now:", isHidden and "HIDDEN" or "VISIBLE")
        lastMagicHiddenState = isHidden
    end
    
    log("[MAGIC] Result: isHidden =", tostring(isHidden))
    
    return isHidden
end

return detection
