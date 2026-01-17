local core = require('openmw.core')
local async = require('openmw.async')
local T = require('openmw.types')
local I = require("openmw.interfaces")
local util = require("openmw.util")
local nearby = require('openmw.nearby')
local recordId
if I.Controls or I.AI then
    recordId = require('openmw.self').recordId
end

local mS = require('scripts.TakeCover.settings')

local fCombatDistance = core.getGMST("fCombatDistance")
local fHandToHandReach = core.getGMST("fHandToHandReach")

local module = {}

local doLog = mS.globalStorage:get("debugMode")

module.log = function(str)
    if not doLog then return end
    if recordId then
        print(string.format("DEBUG (%s): %s", recordId, str))
    else
        print("DEBUG: " .. str)
    end
end

module.targetsToString = function(targets)
    local parts = {}
    for _, target in ipairs(targets) do
        table.insert(parts, string.format("(%s, %s)", target.id, target.recordId))
    end
    return string.format("{ %s }", table.concat(parts, ", "))
end

local function getItemEffects(item)
    local record = item.type.record(item)
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

module.isLevitating = function(actor)
    return T.Actor.activeEffects(actor):getEffect("levitate").magnitude ~= 0
end

-- Return isRanged, meleeReach
module.getAttackInfo = function(actor)
    local stance = T.Actor.getStance(actor)

    if stance == T.Actor.STANCE.Nothing then
        return false, 0.0
    end

    if stance == T.Actor.STANCE.Weapon then
        local item = T.Actor.getEquipment(actor, T.Actor.EQUIPMENT_SLOT.CarriedRight)
        if not item or item.type ~= T.Weapon then
            return false, fHandToHandReach * fCombatDistance
        end
        local weapon = T.Weapon.record(item)
        return weapon.type == T.Weapon.TYPE.MarksmanBow
                or weapon.type == T.Weapon.TYPE.MarksmanCrossbow
                or weapon.type == T.Weapon.TYPE.MarksmanThrown,
        weapon.reach * fCombatDistance
    end

    local spell = T.Actor.getSelectedSpell(actor)
    if spell ~= nil then
        return hasTargetEffect(spell.effects), fCombatDistance
    else
        local item = T.Actor.getSelectedEnchantedItem(actor)
        if not item then
            return false, 0.0
        end
        local effects = getItemEffects(item)
        return hasTargetEffect(effects), fCombatDistance
    end
end

module.canAttackTarget = function(actor, target)
    local isRanged, meleeReach = module.getAttackInfo(actor)
    if isRanged then
        return true
    end

    -- Find nearest navigation path to reach to the player
    local status, path = nearby.findPath(actor.position, target.position, {
        agentBounds = T.Actor.getPathfindingAgentBounds(actor),
        destinationTolerance = 0,
    })
    if status ~= nearby.FIND_PATH_STATUS.Success or not path or #path == 0 then
        return
    end

    -- If there is a path, it might not be sufficient to reach the player with a melee attack
    local actorBounds = T.Actor.getPathfindingAgentBounds(actor)
    local targetBounds = T.Actor.getPathfindingAgentBounds(target)
    -- We use the closest point to the player and compute if the actor car hit the player (with a weapon, hands or spell)
    local boundingDist = (target.position - path[#path]):length() - actorBounds.halfExtents.y - targetBounds.halfExtents.y
    --module.debugPrint(string.format("Actor %s could be at distance %s from target %s, %s to attack", actorId(actor),
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
    if not result.hit then
        --module.debugPrint(string.format("Actor %s sees nothing at all", actorId(actor)))
        return false
    end

    if result.hitObject and result.hitObject.id == target.id then
        --module.debugPrint(string.format("Actor %s sees his enemy %s", actorId(actor), actorId(target)))
        return true
    else
        --module.debugPrint(string.format("Actor %s sees a \"%s\" with id \"%s\"", actorId(actor), result.hitObject.type, result.hitObject.id))
        return false
    end
end

module.seenByTarget = function(actor, target)
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
            + util.transform.rotateZ(target.rotation:getYaw() + math.pi)
            * util.vector3(actorBox.halfSize.x * .8, 0, 0)
    if castRay(targetHead, actorRightShoulder, target, actor) then
        return true
    end

    local actorFeet = actorBox.center - util.vector3(0, 0, -actorBox.halfSize.z * .6)
    return castRay(targetHead, actorFeet, target, actor)
end

module.turnAround = function(actor, target, deltaTime)
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

mS.globalStorage:subscribe(async:callback(function(_, key)
    if key == "debugMode" then
        doLog = mS.globalStorage:get("debugMode")
    end
end))

return module