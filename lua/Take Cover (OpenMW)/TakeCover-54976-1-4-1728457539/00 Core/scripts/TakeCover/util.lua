local core = require('openmw.core')
local types = require('openmw.types')
local util = require("openmw.util")
local nearby = require('openmw.nearby')

local S = require('scripts.TakeCover.settings')

local pi = math.rad(180)
local fCombatDistance = core.getGMST("fCombatDistance")
local fHandToHandReach = core.getGMST("fHandToHandReach")

local function debugPrint(str)
    if S.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end

local function getRecord(item)
    if item.type and item.type.record then
        return item.type.record(item)
    end
    return nil
end

local function actorId(actor)
    return string.format("<%s (%s)>", getRecord(actor).id, actor.id)
end

local function getItemEffects(item)
    local record = getRecord(item)
    if record and record.enchant then
        return core.magic.enchantments.records[record.enchant].effects
    end
    return nil
end

local function hasTargetEffect(effects)
    for _, effect in ipairs(effects) do
        if effect.range == core.magic.RANGE.Target and effect.effect.harmful then
            return true
        end
    end
    return false
end

local function isLevitating(actor)
    return types.Actor.activeEffects(actor):getEffect("levitate").magnitude ~= 0
end

-- Return isRanged, meleeReach
local function getAttackInfo(actor)
    local stance = types.Actor.getStance(actor)

    if stance == types.Actor.STANCE.Nothing then
        return false, 0.0
    end

    if stance == types.Actor.STANCE.Weapon then
        local item = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
        if item == nil or item.type ~= types.Weapon then
            return false, fHandToHandReach * fCombatDistance
        end
        local weapon = types.Weapon.record(item)
        return weapon.type == types.Weapon.TYPE.MarksmanBow
                or weapon.type == types.Weapon.TYPE.MarksmanCrossbow
                or weapon.type == types.Weapon.TYPE.MarksmanThrown,
        weapon.reach * fCombatDistance
    end

    local spell = types.Actor.getSelectedSpell(actor)
    if spell ~= nil then
        return hasTargetEffect(spell.effects), fCombatDistance
    else
        local item = types.Actor.getSelectedEnchantedItem(actor)
        if item == nil then
            return false, 0.0
        end
        local effects = getItemEffects(item)
        return hasTargetEffect(effects), fCombatDistance
    end
end

local function canAttackTarget(actor, target)
    if target == nil then return false end

    local isRanged, meleeReach = getAttackInfo(actor)
    if isRanged then
        return true
    end

    -- Find nearest navigation path to reach to the player
    local status, path = nearby.findPath(actor.position, target.position, {
        agentBounds = types.Actor.getPathfindingAgentBounds(actor),
        destinationTolerance = 0,
    })
    if status ~= nearby.FIND_PATH_STATUS.Success or path == nil or #path == 0 then
        return
    end

    -- If there is a path, it might not be sufficient to reach the player with a melee attack
    local actorBounds = types.Actor.getPathfindingAgentBounds(actor)
    local targetBounds = types.Actor.getPathfindingAgentBounds(target)
    -- We use the closest point to the player and compute if the actor car hit the player (with a weapon, hands or spell)
    local boundingDist = (target.position - path[#path]):length() - actorBounds.halfExtents.y - targetBounds.halfExtents.y
    --debugPrint(string.format("Actor %s could be at distance %s from target %s, %s to attack", actorId(actor),
    --        boundingDist, actorId(target), boundingDist - meleeReach))
    return boundingDist - meleeReach <= 0
end

local function castRay(from, to, actor, target)
    -- Start ray from distance to the actor to prevent detecting himself
    local result = nearby.castRay(
            from,
            to,
            {
                collisionType = nearby.COLLISION_TYPE.AnyPhysical,
                ignore = actor,
            }
    )
    if result.hitObject == nil then
        -- Happens, but shouldn't, might be a false negative
        --debugPrint(string.format("Actor %s sees nothing at all", actorId(actor)))
        return true
    end

    if result.hitObject.id == target.id then
        --debugPrint(string.format("Actor %s sees his enemy %s", actorId(actor), actorId(target)))
        return true
    else
        --debugPrint(string.format("Actor %s sees a \"%s\" with id \"%s\"", actorId(actor), result.hitObject.type, result.hitObject.id))
        return false
    end

end

local function seenByTarget(actor, target)
    local actorBox = actor:getBoundingBox()
    local actorHead = actorBox.center + util.vector3(0, 0, actorBox.halfSize.z * .8)
    local targetBox = target:getBoundingBox()
    local targetHead = targetBox.center + util.vector3(0, 0, targetBox.halfSize.z * .8)

    if castRay(targetHead, actorHead, target, actor) then
        return true
    end

    local actorTorso = actorBox.center + util.vector3(0, 0, actorBox.halfSize.z / 2)
    local actorLeftShoulder = actorTorso
            + util.transform.rotateZ(target.rotation:getYaw())
            * util.vector3(actorBox.halfSize.x * .8, 0, 0)

    if castRay(targetHead, actorLeftShoulder, target, actor) then
        return true
    end

    local actorRightShoulder = actorTorso
            + util.transform.rotateZ(target.rotation:getYaw() + pi)
            * util.vector3(actorBox.halfSize.x * .8, 0, 0)
    if castRay(targetHead, actorRightShoulder, target, actor) then
        return true
    end

    local actorFeet = actorBox.center - util.vector3(0, 0, -actorBox.halfSize.z * .6)
    return castRay(targetHead, actorFeet, target, actor)
end

local function turnAround(actor, target, deltaTime)
    actor.controls.movement = 0
    actor.controls.sideMovement = 0
    local deltaPos = target.position - actor.position
    local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(actor.rotation:getYaw())
    local deltaYaw = math.atan2(destVec.x, destVec.y)
    if math.abs(deltaYaw) > math.rad(30) then
        actor.controls.yawChange = util.clamp(deltaYaw, -deltaTime * 5, deltaTime * 5)
        return true
    else
        actor.controls.yawChange = 0
        return false
    end
end

return {
    debugPrint = debugPrint,
    getRecord = getRecord,
    actorId = actorId,
    isLevitating = isLevitating,
    getAttackInfo = getAttackInfo,
    canAttackTarget = canAttackTarget,
    seenByTarget = seenByTarget,
    turnAround = turnAround,
}