
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local util = require("openmw.util")

local module = {}

--------------------------------------------------
-- Calm effect check (NPC vs creature aware)
--------------------------------------------------
local function hasCalm(actor)
    local effects = types.Actor.activeEffects(actor)

    if types.NPC.objectIsInstance(actor) then
        local calm = effects:getEffect(core.magic.EFFECT_TYPE.CalmHumanoid)
        return calm and calm.magnitude > 0
    else
        local calm = effects:getEffect(core.magic.EFFECT_TYPE.CalmCreature)
        return calm and calm.magnitude > 0
    end
end

--------------------------------------------------
-- Distance bias (matches engine math)
--------------------------------------------------
local iFightDistanceBase = core.getGMST('iFightDistanceBase')
local fFightDistanceMultiplier = core.getGMST('fFightDistanceMultiplier')
local fFightDispMult = core.getGMST('fFightDispMult')
local function getFightDistanceBias(actor, target)
    local dist = (actor.position - target.position):length()    

    return iFightDistanceBase - fFightDistanceMultiplier * dist
end

--------------------------------------------------
-- Disposition bias (creatures fixed at 50)
--------------------------------------------------

local function getFightDispositionBias(disposition)
    local mult = fFightDispMult
    return (50 - disposition) * mult
end

--------------------------------------------------
-- Aggression decision
--------------------------------------------------
local function isAggressive(ast, target)
    -- TO DO: Doesnt really make sense as some monsters are not agressive
    --------------------------------------------------
    -- NPC override rule
    --------------------------------------------------

    if types.NPC.objectIsInstance(ast.actor) then
        return not hasCalm(ast.actor)
    end

    --------------------------------------------------
    -- Creature logic
    --------------------------------------------------

    -- calm suppresses aggression
    if hasCalm(ast.actor) then
        return false
    end

    local aiFight = ast.gactor:aiFightStat().modified

    -- fight score calculation
    local fight =
        aiFight  -- Access the modified value of the AI stat
        + getFightDistanceBias(ast.actor, target)
        + getFightDispositionBias(50)

    local res = fight >= 100

    --[[ if not res then
        print("Actor", ast.actor.recordId, "is not agressive towards target", target.recordId, "Fight:", aiFight, "Distance Bias:", getFightDistanceBias(ast.actor, target), "Disposition Bias:", getFightDispositionBias(50), "Total: ", fight)
    end ]]
    
    return fight >= 100
end
module.isAggressive = isAggressive

local function aggroDistance(ast)
    local aiFight = ast.gactor:aiFightStat().modified
    return (iFightDistanceBase + aiFight - 100) / fFightDistanceMultiplier
end
module.aggroDistance = aggroDistance

return module