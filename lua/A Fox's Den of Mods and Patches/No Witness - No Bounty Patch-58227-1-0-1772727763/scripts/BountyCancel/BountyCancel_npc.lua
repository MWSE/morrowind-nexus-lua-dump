local nearby = require("openmw.nearby")
local self   = require("openmw.self")
local core   = require("openmw.core")
local types  = require("openmw.types")
local util   = require("openmw.util")
local I      = require("openmw.interfaces")

local apiver = core.API_REVISION

local function getPlayer()
    if apiver == 29 then
        for index, value in ipairs(nearby.actors) do
            if value.type == types.Player then
                return value
            end
        end
    end
    return nearby.players[1]
end

local isWitness = false
local canSeePlayer = false
local updateWait = 0

local function isFollowingPlayer()
    if types.NPC.record(self).class == "guard" then
        return false
    end
    local result = false
    local func = function(param)
        if param.target == getPlayer() and param.type == "Follow" then
            result = true
        end
    end
    I.AI.forEachPackage(func)
    return result
end

local function isFightingPlayer()
    local result = false
    local func = function(param)
        if param.target and param.target.type == types.Player and param.type == "Combat" then
            result = true
        end
    end
    I.AI.forEachPackage(func)
    return result
end

local function getHalfSize(object)
    if apiver == 29 then
        return 150
    else
        return object:getBoundingBox().halfSize.z
    end
end

local function getViewpoint(pos, object)
    local offset = getHalfSize(object)
    return util.vector3(pos.x, pos.y, pos.z + offset)
end

local function getObjectID(obj)
    if apiver == 29 then
        return obj.recordId
    else
        return obj.id
    end
end

local function onUpdate()
    if isWitness then
        if types.Actor.stats.dynamic.health(self).current == 0 then
            isWitness = false
            core.sendGlobalEvent("WitnessDeath", getObjectID(self))
        end
    end

    if not canSeePlayer and updateWait == 0 and #nearby.actors < 10 then
        local player = getPlayer()
        local cast = nearby.castRay(
            getViewpoint(self.position, self),
            getViewpoint(player.position, player),
            { ignore = self }
        )
        if cast.hit and cast.hitObject == player then
            canSeePlayer = true
        end
        updateWait = math.random(8, 15)
    elseif not canSeePlayer and updateWait == 0 and #nearby.actors >= 10 then
        canSeePlayer = true
    elseif not canSeePlayer and updateWait > 0 then
        updateWait = updateWait - 1
    end
end

local function checkCrimeWitness(crimeId)
    local returnData = { npcId = getObjectID(self), isWitness = false, crimeId = crimeId }

    if isFollowingPlayer() then
        returnData.isWitness = false
    elseif isFightingPlayer() or canSeePlayer then
        returnData.isWitness = true
    end

    if returnData.isWitness then
        isWitness = true
    end

    core.sendGlobalEvent("NPCReportReturn", returnData)
end

local function onSave()
    return { isWitness = isWitness }
end

local function onActive()
    canSeePlayer = false
end

local function onLoad(data)
    if data then
        isWitness = data.isWitness
    end
    canSeePlayer = false
end

return {
    interfaceName = "BountyCancel",
    interface = { isFightingPlayer = isFightingPlayer },
    engineHandlers = { onUpdate = onUpdate, onActive = onActive, onSave = onSave, onLoad = onLoad },
    eventHandlers = { checkCrimeWitness = checkCrimeWitness }
}