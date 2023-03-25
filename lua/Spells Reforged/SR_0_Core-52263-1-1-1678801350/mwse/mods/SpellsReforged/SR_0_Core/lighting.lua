local ffi = require("ffi")

---@type fun(niObject):number
local addressof = mwse.memory.convertFrom.niObject ---@diagnostic disable-line

local ptr = ffi.typeof("void*")
local function asPtr(niObject)
    return ffi.cast(ptr, addressof(niObject))
end

local _updateLighting = ffi.cast("void (__cdecl*)(void*, void*, unsigned int, int, bool, bool)", 0x4D2F40)
local function updateLighting(light, node, radius, lightFlags, isLand, isHighPriority)
    _updateLighting(asPtr(light), asPtr(node), radius, lightFlags, isLand, isHighPriority)
end

local _cleanupAffectedNodes = ffi.cast("void (__cdecl*)(void*)", 0x4D3360)
local function cleanupAffectedNodes(light)
    _cleanupAffectedNodes(asPtr(light))
end


--- Iterate over all scene nodes that are subject to lighting.
---@return fun():(niNode, boolean)
local function iterLightingTargets()
    return coroutine.wrap(function()
        -- yield player
        coroutine.yield(tes3.player.sceneNode, false)
        -- yield cell refs
        local cell = tes3.player.cell
        for ref in cell:iterateReferences() do
            local sceneNode = not (ref.disabled or ref.deleted) and ref.sceneNode
            if sceneNode then
                coroutine.yield(sceneNode, false)
            end
        end
        -- yield land chunks
        if not cell.isInterior then
            for _, chunk in pairs(tes3.game.worldLandscapeRoot.children) do
                for _, sceneNode in pairs(chunk.children) do
                    coroutine.yield(sceneNode, true)
                end
            end
        end
    end)
end

---@class ActiveLight
---@field owner niAVObject
---@field light niPointLight

--- Global storage of all currently active lights.
---@type table<number, ActiveLight>
local activeLights = {}

---@param owner niAVObject
---@param light niPointLight
local function addActiveLight(owner, light)
    debug.log(owner)
    debug.log(light)
    activeLights[addressof(owner)] = { owner = owner, light = light }
end

--- Clean up any lights that no longer exist.
---
--- A light is considered orphaned if either it or its owner are no longer connected to the world scene graph.
local function cleanOrphanLights()
    for key, value in pairs(activeLights) do
        if not (value.owner.parent and value.light.parent) then
            debug.log("EXPIRED")
            debug.log(value.owner)
            debug.log(value.light)
            cleanupAffectedNodes(value.light)
            activeLights[key] = nil
        end
    end
end

--- Update lighting for all objects affected by an active light.
---
--- This function must run periodically on timer so that world lighting stays up to date.
local function updateActiveLights()
    if next(activeLights) then
        for sceneNode, isLand in iterLightingTargets() do
            for _, value in pairs(activeLights) do
                updateLighting(value.light, sceneNode, value.light.scale, 0, isLand, true)
            end
        end
    end
end
event.register(tes3.event.loaded, function()
    timer.start({
        iterations = -1,
        duration = 0.15,
        callback = function()
            cleanOrphanLights()
            updateActiveLights()
        end,
    })
end)

-- Public API

local this = {}

---@param owner niNode
function this.addManagedLights(owner)
    for light in table.traverse({ owner }) do
        if light:isInstanceOfType(ni.type.NiPointLight) then
            light:setRadius(light.scale)
            addActiveLight(owner, light)
        end
    end
end

-- Events

---@param e vfxCreatedEventData
event.register(tes3.event.vfxCreated, function(e)
    if e.vfx.effectNode:hasStringDataWith("SR_ManagedLights") then ---@diagnostic disable-line
        this.addManagedLights(e.vfx.effectNode)
    end
end)


event.register(tes3.event.mobileActivated, function(e)
    if e.mobile.objectType == tes3.objectType.mobileSpellProjectile then
        local sceneNode = e.reference.sceneNode
        if sceneNode and sceneNode:hasStringDataWith("SR_ManagedLights") then ---@diagnostic disable-line
            e.reference:deleteDynamicLightAttachment(true)
            for light in table.traverse(sceneNode.children) do
                if light:isInstanceOfType(ni.type.NiPointLight) then
                    light:setRadius(light.scale)
                    e.reference:getOrCreateAttachedDynamicLight(light)
                    break
                end
            end
        end
    end
end)

return this
