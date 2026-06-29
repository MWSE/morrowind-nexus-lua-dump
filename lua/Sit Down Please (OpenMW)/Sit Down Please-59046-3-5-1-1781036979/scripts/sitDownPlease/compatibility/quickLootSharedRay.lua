---@omw-context player
---@diagnostic disable: assign-type-mismatch, undefined-field, param-type-mismatch
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local VERSION = 2
local cachedResult = {}
local raycast = nearby.castRenderingRay
local maxActivateDistance = core.getGMST("iMaxActivateDist") or 192

if I.SharedRay and I.SharedRay.version >= VERSION then
    return
end

local function cameraVector()
    local yaw = camera.getYaw()
    local pitch = camera.getPitch()
    local cosPitch = math.cos(pitch)
    return util.vector3(
        math.sin(yaw) * cosPitch,
        math.cos(yaw) * cosPitch,
        -math.sin(pitch)
    )
end

local function objectText(obj)
    if not obj then return "" end
    local parts = {
        tostring(obj.recordId or obj.id or ""),
        tostring(obj.type or ""),
    }
    local okRecord, record = pcall(function()
        return obj.type and obj.type.record and obj.type.record(obj) or nil
    end)
    if okRecord and record then
        parts[#parts + 1] = tostring(record.name or "")
        parts[#parts + 1] = tostring(record.model or "")
    end
    return string.lower(table.concat(parts, " "))
end

local function actorOrContainer(obj)
    if not obj then return false end
    local okActor, isActor = pcall(function() return types.Actor.objectIsInstance(obj) end)
    if okActor and isActor then return true end
    local okContainer, isContainer = pcall(function() return types.Container.objectIsInstance(obj) end)
    return okContainer and isContainer == true
end

local function furnitureText(obj)
    local text = objectText(obj)
    return text:find("furn", 1, true) ~= nil
        or text:find("chair", 1, true) ~= nil
        or text:find("bench", 1, true) ~= nil
        or text:find("stool", 1, true) ~= nil
        or text:find("seat", 1, true) ~= nil
        or text:find("table", 1, true) ~= nil
        or text:find("desk", 1, true) ~= nil
        or text:find("counter", 1, true) ~= nil
        or text:find("lectern", 1, true) ~= nil
        or text:find("lecturn", 1, true) ~= nil
end

local function chooseHit(renderHit, physicsHit, cameraPos)
    if renderHit and actorOrContainer(renderHit.hitObject) then
        return renderHit, "rendering"
    end
    if not (physicsHit and actorOrContainer(physicsHit.hitObject)) then
        return renderHit, "rendering"
    end
    if not (renderHit and renderHit.hitObject and renderHit.hitPos) then
        return physicsHit, "physics"
    end
    if actorOrContainer(renderHit.hitObject) then
        return renderHit, "rendering"
    end
    if not furnitureText(renderHit.hitObject) then
        return renderHit, "rendering"
    end

    local renderDistance = (renderHit.hitPos - cameraPos):length()
    local physicsDistance = physicsHit.hitPos and (physicsHit.hitPos - cameraPos):length() or renderDistance
    if physicsDistance >= renderDistance and physicsDistance - renderDistance <= 120 then
        return physicsHit, "physics_behind_furniture"
    end
    return renderHit, "rendering"
end

local function onFrame()
    if I.SharedRay and I.SharedRay.version > VERSION then return end

    local cameraPos = camera.getPosition()
    local maxDist = maxActivateDistance + camera.getThirdPersonDistance()
    local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        maxDist = maxDist + telekinesis.magnitude * 22
    end

    local endPos = cameraPos + cameraVector() * maxDist
    local renderHit = raycast(cameraPos, endPos, { ignore = self })
    local physicsHit = nearby.castRay(cameraPos, endPos, {
        collisionType = nearby.COLLISION_TYPE.Default,
        ignore = self,
        radius = 0,
    })
    local selected, source = chooseHit(renderHit, physicsHit, cameraPos)
    selected = selected or {}

    cachedResult = {
        hit = selected.hit,
        hitPos = selected.hitPos,
        hitNormal = selected.hitNormal,
        hitObject = selected.hitObject,
        hitTypeName = selected.hitObject and tostring(selected.hitObject.type) or nil,
        source = source,
        renderHitObject = renderHit and renderHit.hitObject or nil,
        renderHitPos = renderHit and renderHit.hitPos or nil,
        physicsHitObject = physicsHit and physicsHit.hitObject or nil,
        physicsHitPos = physicsHit and physicsHit.hitPos or nil,
    }
end

local function get()
    return cachedResult
end

local function setRayType(func)
    raycast = func
    if func == nearby.castRenderingRay then
        print("[SharedRay] changing raycast to castRenderingRay")
    elseif func == nearby.castRay then
        print("[SharedRay] changing raycast to castRay")
    else
        print("[SharedRay] changing raycast to unknown")
    end
end

return {
    interfaceName = "SharedRay",
    interface = {
        version = VERSION,
        get = get,
        setRayType = setRayType,
    },
    engineHandlers = {
        onFrame = onFrame,
    },
}
