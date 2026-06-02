local nearby  = require("openmw.nearby")
local types   = require("openmw.types")
local core    = require("openmw.core")
local util    = require("openmw.util")
local selfRef = require("openmw.self")
local ambient = require("openmw.ambient")
local ui      = require("openmw.ui")
local input   = require("openmw.input")

---------------------------------------------------------------------------
-- CONFIG  ▸ all tuning knobs in one table
---------------------------------------------------------------------------
local STEALTH_CFG = {
    MAX_DISTANCE        = 1500,
    DISTANCE_EXPONENT   = 2.5,
    DISTANCE_WEIGHT     = 1.2,
    BASE_DIFFICULTY     = 10,
    SNEAK_EFFECTIVENESS = 0.4,
    COMPROMISED_PENALTY = 40,  -- huge bonus to detection once seen
}

---------------------------------------------------------------------------
-- HELPER ▸ distance-based difficulty term
---------------------------------------------------------------------------
local function distancePenalty(dist)
    local closeFactor =
        1 - math.min(dist, STEALTH_CFG.MAX_DISTANCE) / STEALTH_CFG.MAX_DISTANCE
    return (closeFactor ^ STEALTH_CFG.DISTANCE_EXPONENT)
           * 100 * STEALTH_CFG.DISTANCE_WEIGHT
end

---------------------------------------------------------------------------
-- HELPER ▸ single sneak roll
---------------------------------------------------------------------------
local function doSneakRoll(actor, dist, compromised)
    local sneak = actor.type.stats.skills.sneak(actor).modified
    local chameleonEffect = types.Actor.activeEffects(actor):getEffect('chameleon')
    local chameleon = chameleonEffect and chameleonEffect.magnitudeModifier or 0
    local distanceFactor = distancePenalty(dist)

    -- Base difficulty
    local difficulty =
          STEALTH_CFG.BASE_DIFFICULTY
        + distanceFactor
        - (sneak * STEALTH_CFG.SNEAK_EFFECTIVENESS)

    if compromised then
        difficulty = difficulty + STEALTH_CFG.COMPROMISED_PENALTY
    end

    -- Chameleon acts as a percentage reduction on the final difficulty
    local chameleonMultiplier = 1 - math.min(chameleon, 100) / 100
    difficulty = difficulty * chameleonMultiplier

    difficulty = math.max(0, math.min(100, difficulty))
    return math.random(1, 100) <= difficulty
end

---------------------------------------------------------------------------
-- HELPER ▸ line-of-sight + facing + sneak
---------------------------------------------------------------------------
local function isDetected(actor, npc, compromised)
    local v = actor.position - npc.position
    local dist = v:length()
    if dist > STEALTH_CFG.MAX_DISTANCE then return false end

    -- facing: dot product of NPC forward vs direction to actor
    if (npc.rotation * util.vector3(0, 1, 0)):dot(v:normalize()) < 0.2 then
        return false
    end

    -- line of sight:
    --   hit == nil              → rayo libre → LOS ok
    --   hit.hitObject == actor  → rayo llegó al actor → LOS ok
    --   cualquier otra cosa     → pared/puerta/mueble → bloqueado
    local hit = nearby.castRay(npc.position, actor.position, { ignore = npc })
    if hit ~= nil and hit.hitObject ~= actor then
        return false
    end

    -- sneak roll
    return doSneakRoll(actor, dist, compromised)
end

---------------------------------------------------------------------------
-- HELPER ▸ line-of-sight check (shared, no sneak roll)
-- Returns true if the NPC has an unobstructed path to targetPos.
---------------------------------------------------------------------------
local function hasLineOfSight(npc, target)
    local hit = nearby.castRay(npc.position, target.position, { ignore = npc })
    -- nil  → nothing hit → clear path
    -- hit.hitObject == target → ray reached the target directly → clear
    if hit == nil then return true end
    if hit.hitObject == target then return true end
    return false
end

---------------------------------------------------------------------------
-- HELPER ▸ iterate nearby actors once
---------------------------------------------------------------------------
local function checkForWitnesses(data)
    local actor = data.actor
    local keg   = data.keg
    local drink = data.drink

    -- Use selfRef to check actual sneak stance, not just the toggle key.
    -- selfRef.controls.sneak is true when the character is physically crouching.
    local isSneaking = selfRef.controls and selfRef.controls.sneak

    -- Not sneaking: pay for the drink.
    -- Find a seller: must be alive, enabled, within 1000 units, and have LOS.
    if not isSneaking then
        local seller
        local SELLER_MAX_DIST = 1000
        for _, npc in ipairs(nearby.actors) do
            if npc ~= actor
               and npc.type == types.NPC
               and npc.enabled
               and not types.Actor.isDead(npc)
            then
                local dist = (actor.position - npc.position):length()
                if dist <= SELLER_MAX_DIST and hasLineOfSight(npc, actor) then
                    seller = npc
                    break
                end
            end
        end
        core.sendGlobalEvent("KegstandMod_buyDrink_eqnx", {
            actor  = actor,
            keg    = keg,
            drink  = drink,
            seller = seller,
        })
        return
    end

    -- Sneaking: check if anyone detects you
    local sawYou = false
    local firstWitness = true
    local compromised = false

    for _, npc in ipairs(nearby.actors) do
        if npc ~= actor
           and npc.type == types.NPC
           and npc.enabled
           and not types.Actor.isDead(npc)
           and isDetected(actor, npc, compromised)
        then
            sawYou = true
            core.sendGlobalEvent("KegstandMod_commitTheft_eqnx", {
                player = actor,
                victim = npc,
                value  = firstWitness and 10 or 0,
            })
            firstWitness = false
            compromised = true -- everyone after gets harder checks
        end
    end

    if not sawYou then
        core.sendGlobalEvent("KegstandMod_resumeDrink_eqnx", {
            actor  = actor,
            keg    = keg,
            drink  = drink,
            stolen = true,
        })
    end
end

---------------------------------------------------------------------------
-- HELPER ▸ show message + sound
---------------------------------------------------------------------------
local function showMessage(data)
    if not (data and data.msg) then return end
    ambient.playSound(data.fail and "repair fail" or "Drink")
    ui.showMessage(data.msg)
end

---------------------------------------------------------------------------
-- EVENT TABLE
---------------------------------------------------------------------------
return {
    eventHandlers = {
        KegstandMod_checkTheft_eqnx = checkForWitnesses,
        KegstandMod_UIShowMessage_eqnx = showMessage,
    },
}

