-- For the following sneak check methods: based on code by Blurpandra lifterd from Burglary Overhaul --
----------------------------------------------------------------------------------------------

--[[
Better Sneak for OpenMW.
Copyright (C) 2026 Erin Pentecost, Maksim Eremenko

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
local mp = "scripts/MaxYari/SneakIsGoodNow/"

local types = require("openmw.types")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local omwself = require("openmw.self")
local util = require("openmw.util")
local ui = require('openmw.ui')
local aux_util = require('openmw_aux.util')

local DEFS = require(mp .. 'utils/sneak_defs')
local gutils = require(mp .. 'utils/gutils')
local selfActor = gutils.Actor:new(omwself)
local settings = require(mp .. 'settings').settings

local module = {}

-- Main config ---------
fSneakUseDist = core.getGMST("fSneakUseDist")
detectionRange = fSneakUseDist -- to do, dont forget to change this
nearDetectionRange = detectionRange*0.66
gutils.print("Sneak detection range", detectionRange * DEFS.GUtoM, nearDetectionRange * DEFS.GUtoM, 1)

module.detectionRange = detectionRange
module.nearDetectionRange = nearDetectionRange

-- Helper methods -----------------------------
-----------------------------------------------
local function facingFactor(actor)
    -- 1 if actor is facing player, -1 if facing away
    local facing = actor.rotation:apply(util.vector3(0.0, 1.0, 0.0)):normalize()
    local relativePos = (omwself.position - actor.position):normalize()
    return facing:dot(relativePos)
end

local function directionMult(actor)
    local facing = facingFactor(actor)
    facing = util.clamp(facing, -1, 0)

    local mult = util.remap(facing, -1, 0.25, 0.5, 0.75)
    -- This is modified from vanilla, in vanilla its hardcoded to be 1.5 past 90 deg and 0.5 behind
    -- 0.75 on a side (actually slighly closer to front than pure 90deg, maybe 100-110deg or so)
    -- 0.5 behind
    -- gutils.print("direction mult: " .. mult .. " (facing factor: " .. facing .. ")")
    return mult
end

local function LOS(player, actor)
    -- cast once from center of box to center of box
    local playerBounds = types.Actor.getPathfindingAgentBounds(player) -- Use pathfinding bounds as they should match collider size. If mesh bounding box is used instead - center is sometimes outside the collider.
    local playerHeight = playerBounds.halfExtents.z * 2
    local playerEyes = player.position + util.vector3(0,0,playerHeight * 0.75)
    local actorEyes = actor:getBoundingBox().center -- Some actors (like creatures) have wonky pathfinding bounds, so better use mesh bounding box here

    local castResult = nearby.castRay(actorEyes, playerEyes, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = actor
    })
    --gutils.print("raycast(center, "..tostring(actorCenter)..") from " .. actor.recordId .. " hit" ..
    --                        aux_util.deepToString(castResult.hitObject, 4))

    if (castResult.hitObject ~= nil) and (castResult.hitObject.id == player.id) then
        return true
    end

    return false
end
module.LOS = LOS

-- Main math -----------------------------------------
------------------------------------------------------
local closeRangeDistMax = DEFS.MtoGU * 7.0
local closeRangeDistMin = DEFS.MtoGU * 1.0
local function awareness(ast, ps, extraMods)
    -- https://en.uesp.net/wiki/Morrowind:Sneak    

    local sneakTerm = ast.gactor:getSneakValue()
    local agilityTerm = ast.gactor:getAttributeStat("agility").modified / 5
    local luckTerm = ast.gactor:getAttributeStat("luck").modified / 10

    local fatigueStat = ast.gactor:getDynamicStat("fatigue")
    local fatigueTerm = 0.75 + (0.5 * math.min(1, math.max(0, fatigueStat.current / fatigueStat.base)))

    local blindEffect = ast.gactor:activeEffects():getEffect(core.magic.EFFECT_TYPE.Blind)
    local blind = 0
    if blindEffect ~= nil then
        blind = blindEffect.magnitude
    end

    local isFacing = facingFactor(ast.actor) > 0.25
    local facingMult = 0
    if isFacing then
        facingMult = 0.5
    end
    if ps.chameleon > 0 then
        facingMult = facingMult * (1 - ps.chameleon / 100)
    end
    if ps.isInvisible then
        facingMult = 0
    end

    local closeFacingTerm = 0
    if isFacing and ast.distance <= closeRangeDistMax then
        closeFacingTerm = util.remap(ast.distance, closeRangeDistMin, closeRangeDistMax, 100, 25)
        if closeFacingTerm < 0 then closeFacingTerm = 0 end
    end
    if ps.chameleon > 0 then
        closeFacingTerm = closeFacingTerm * (1 - ps.chameleon / 100)
    end
    if ps.isInvisible then
        closeFacingTerm = 0
    end
    
    
    local awarenessScore = (sneakTerm + agilityTerm + luckTerm - blind) * fatigueTerm * directionMult(ast.actor) * (1 + facingMult) + closeFacingTerm
    -- gutils.print("awareness: " .. awarenessScore .. " = " .. "(" .. sneakTerm .. "+" .. agilityTerm .. "+" ..
    --                      luckTerm .. "-" .. blind .. ") * " .. fatigueTerm .. " * " .. directionMult)  
    
    return awarenessScore
end

local function elusiveness(distance, ps, extraMods)
    -- https://en.uesp.net/wiki/Morrowind:Sneak

    local sneakTerm = selfActor:getSkillStat("sneak").modified
    local agilityTerm = selfActor:getAttributeStat("agility").modified / 5
    local luckTerm = selfActor:getAttributeStat("luck").modified / 10    
    local fatigueStat = selfActor:getDynamicStat("fatigue")
    local fatigueTerm = 0.75 + (0.5 * math.min(1, math.max(0, fatigueStat.current / fatigueStat.base)))

    -- Vanilla is more or less local distanceTerm = 0.5 + (distance / detectionRange) -- vanilla detection Range is 500, ours will be at 1000 or more, vanilla dist term is 0.5-1.5
    local distTermFar = 2.0
    local distTermNear = 1.0
    local distTerm = 1
    if distance <= nearDetectionRange then
        distTerm = distTermNear
    else
        distTerm = util.remap(distance, nearDetectionRange, detectionRange, distTermNear, distTermFar)
    end

    local chameleonTerm = ps.chameleon
    if ps.isInvisible then chameleonTerm = 100 end
    
    local standStillTerm = 1.25 -- not in vanilla, newly added
    if ps.isMoving then
        standStillTerm = 1
    end     

    local elusivenessScore = (sneakTerm + agilityTerm + luckTerm) * distTerm * fatigueTerm * standStillTerm * extraMods.elusivenessMod + chameleonTerm + extraMods.elusivenessConst
    -- gutils.print("elusiveness: " .. elusivenessScore .. " = " .. "(" .. sneakTerm .. "+" .. agilityTerm .. "+" ..
    --                        luckTerm .. ") * " .. distTerm .. " * " .. fatigueTerm .. " + " .. ps.chameleon)
    return elusivenessScore
end

-- sneakCheck should return true if the actor can't see the player.
-- Note: ast.inLOS must be set before calling this function
local function sneakCheck(ast, ps, extraMods)
    -- if we aren't sneaking, then you don't pass the check.
    if ps.isSneaking ~= true then return false, nil end

    if ast.inLOS == false then return true,nil end

    local elusivenessScore = elusiveness(ast.distance, ps, extraMods)
    local awarenessScore = awareness(ast, ps, extraMods) * settings.DifficultyMultiplier
    local sneakChance = math.min(100, math.max(0, elusivenessScore - awarenessScore))
    local success = math.random(0, 100) <= sneakChance
    -- gutils.print("elusivenessScore: " .. elusivenessScore .. ", awarenessScore: " .. awarenessScore .. ", sneakChance: " .. sneakChance .. ", success: " .. tostring(success))


    -- gutils.print("sneak chance: " .. sneakChance .. ", roll: " .. roll)
    return success, sneakChance
end
module.sneakCheck = sneakCheck

return module