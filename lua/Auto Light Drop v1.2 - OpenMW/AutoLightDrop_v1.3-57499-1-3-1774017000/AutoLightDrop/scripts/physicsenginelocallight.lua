-- OpenMW Lua Physics for Light Objects - Based on physicsenginelocal.lua
-- Authors: Maksim Eremenko, GPT-4o (Copilot) - Adapted for Light sources

local mp = 'scripts/MaxYari/LuaPhysics/'

local core = require('openmw.core')
local util = require('openmw.util')
local vfs = require('openmw.vfs')
local nearby = require('openmw.nearby')
local types = require('openmw.types')

local omwself = require('openmw.self')

-- Only attach to Light objects
if omwself.type ~= types.Light then return end

local PhysicsObject = require(mp..'PhysicsObject')
local D = require(mp..'scripts/physics_defs')

-- Main stuff - adapted from physicsenginelocal.lua
local frame = 0
local lastCell = omwself.cell
local physicsObject = PhysicsObject:new(omwself, { 
    drag = 0.2,           -- Slightly more drag for lights
    bounce = 0.3,         -- Less bouncy than other objects
    isSleeping = true,    -- Start sleeping until activated
    resetOnLoad = false   -- Don't reset position on load
})
local lastUnderwater = physicsObject.isUnderwater
local crossedWater = false
local lastSleeping = physicsObject.isSleeping
local persistentData = {
    isDroppedTorch = false,  -- Track if this is a dropped torch
    dropPosition = nil       -- Remember where it was dropped
}

local soundPause = 0.23;
local lastSoundTime = 0.0;
local sfxMinSpeed = 50;
local fenagledMinSpeed = 50;

local function volumeFromVelocity(velocity)
    local volume = 0
    if velocity:length() >= sfxMinSpeed then
        volume = util.remap(velocity:length(), sfxMinSpeed, 600, 0.33, 1)
    end
    return volume
end

local function tryPlayCollisionSounds(hitResult)
    local now = core.getRealTime()
    local velocity = physicsObject.velocity
    local volume = volumeFromVelocity(velocity)
    
    local pitch = 0.8 + math.random() * 0.2
    local params = { volume = volume, pitch = pitch, loop = false }

    if volume > 0 and now - lastSoundTime > soundPause then
        core.sendGlobalEvent(D.e.PlayCollisionSounds, {
            object = omwself,
            surface = hitResult.hitObject,                              
            params = params
        })

        core.sendGlobalEvent(D.e.SpawnCollilsionEffects, {
            object = omwself,
            surface = hitResult.hitObject, 
            position = hitResult.hitPos
        })

        lastSoundTime = now
    end
end

local function tryPlayWaterSounds()
    local now = core.getRealTime()
    if not physicsObject.isSleeping and physicsObject.velocity:length() > 50 and now - lastSoundTime > soundPause then
        core.sendGlobalEvent(D.e.SpawnMaterialEffect, {
            material = "Water",
            position = physicsObject.position
        })
        core.sendGlobalEvent(D.e.PlayWaterSplashSound, {
            object = omwself,
            params = { volume = volumeFromVelocity(physicsObject.velocity), pitch = 0.8 + math.random() * 0.2, loop = false }
        })
        lastSoundTime = now
    end
end

local lastOOBCheck = math.random()
local function checkOutOfBounds()
    if physicsObject.isSleeping then return end
    local now = core.getRealTime()
    if now - lastOOBCheck < 1 then return end

    local position = physicsObject.position
    local initialPosition = physicsObject.initialPosition
    local isOOB = false

    if omwself.cell and not omwself.cell.isExterior then
        -- More lenient bounds for dropped torches - allow much deeper falls
        if position.z < initialPosition.z - 500 * 72 then -- Much more lenient
            physicsObject:resetPosition(true)
            isOOB = true
        end
    elseif omwself.cell and omwself.cell.isExterior then
        -- For exterior, only reset if truly underwater and deep
        if crossedWater and physicsObject.isUnderwater then
            -- Cast ray upward to see if we're really deep underground
            local rayStart = position
            local rayEnd = position + util.vector3(0, 0, 200 * 72) -- Check less distance
            local hitResult = nearby.castRay(rayStart, rayEnd, { collisionType = nearby.COLLISION_TYPE.HeightMap })

            -- Only reset if we're very deep underwater
            if hitResult and hitResult.hit and (hitResult.hitPos.z - position.z) > 100 * 72 then
                physicsObject:resetPosition(true)
                isOOB = true
            end
        end
    end
    lastOOBCheck = now
    return isOOB
end

local function onCollision(hitResult)
    tryPlayCollisionSounds(hitResult)
    if physicsObject.velocity:length() >= fenagledMinSpeed then
        core.sendGlobalEvent(D.e.ObjectFenagled, {
            object = omwself,
            culprit = physicsObject.culprit,
            isOffensive = true
        })
    end
end

physicsObject.onCollision:addEventHandler(onCollision)
physicsObject.onPhysObjectCollision:addEventHandler(onCollision)

local function onUpdate(dt)
    if physicsObject.isSleeping or not omwself.count then return end   
    
    local cell = omwself.cell
    
    if cell and not lastCell then
        physicsObject:reInit()
    end
    lastCell = cell

    if cell == nil then         
        return
    end

    -- Update physics simulation
    physicsObject:update(dt)
    physicsObject:trySleep(dt)

    if physicsObject.isSleeping == false and physicsObject.isSleeping ~= lastSleeping then
        lastSleeping = physicsObject.isSleeping
        core.sendGlobalEvent(D.e.ObjectFenagled, {
            object = omwself,
            culprit = physicsObject.culprit
        })
    end
    
    if lastUnderwater ~= physicsObject.isUnderwater then
        crossedWater = true        
    else
        crossedWater = false
    end
    lastUnderwater = physicsObject.isUnderwater
    
    local isOOB = checkOutOfBounds()

    if crossedWater and not isOOB then tryPlayWaterSounds() end

    frame = frame + 1
end

onUpdate(0)

local function onSave()
    return {
        physicsObjectPersistentData = physicsObject:getPersistentData(),
        persistentData = persistentData
    }
end

local function onLoad(data)
    if not data then return end
    
    if data.persistentData then 
        persistentData = data.persistentData 
        
        -- If this is a dropped torch, don't reset it
        if persistentData.isDroppedTorch then
            physicsObject.resetOnLoad = false
            physicsObject.initialPosition = persistentData.dropPosition or physicsObject.position
        end
        
        core.sendGlobalEvent(D.e.PersistentDataReport, {
            source = omwself,
            data = persistentData
        })
    end
    
    physicsObject:loadPersistentData(data.physicsObjectPersistentData)
end

local function onInactive(data)
    core.sendGlobalEvent(D.e.InactivationReport, {
        object = omwself
    })
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onInactive = onInactive
    },
    eventHandlers = {
        [D.e.MoveTo] = function(e)
            local currentVelocity = physicsObject.velocity;
            local pushVector = e.position - physicsObject.position - currentVelocity/4;
    
            if pushVector:length() > e.maxImpulse then
                pushVector = pushVector:normalize() * e.maxImpulse
            end

            physicsObject:applyImpulse(pushVector, e.culprit)
        end,
        [D.e.ApplyImpulse] = function(e)
            physicsObject:applyImpulse(e.impulse, e.culprit)
        end,
        [D.e.SetPhysicsProperties] = function(props)
            physicsObject:updateProperties(props)
        end,
        [D.e.SetMaterial] = function(e)
            physicsObject:updateMaterial(e.material, e.recalcMass, e.recalcBuoyancy)
        end,
        [D.e.SetPositionUnadjusted] = function(e)
            physicsObject:setPositionUnadjusted(e.position)
        end,
        [D.e.CollidingWithPhysObj] = function(e)
            physicsObject:handlePhysObjectCollision(e.other)
        end,
        [D.e.UpdatePersistentData] = function(data)
            persistentData = data
            core.sendGlobalEvent(D.e.PersistentDataReport, {
                source = omwself,
                data = persistentData
            })
        end,
        -- Special event for torch drop activation
        ["ActivateLightPhysics"] = function(e)
            
            -- Mark this as a dropped torch and save drop position
            persistentData.isDroppedTorch = true
            persistentData.dropPosition = physicsObject.position
            
            -- Update initial position to current drop position
            physicsObject.initialPosition = physicsObject.position
            physicsObject.resetOnLoad = false
            
            -- Re-initialize physics object to clear any previous state
            physicsObject:reInit()
            
            -- Wake up the physics object when torch is dropped
            physicsObject:wakeUp()
            physicsObject:setCulprit(e.culprit)
            
            -- Set gentle physics for controlled fall
            physicsObject.drag = 0.15
            physicsObject.bounce = 0.55
            physicsObject.mass = 0.8
            physicsObject.buoyancy = 0.5
            
            if e.impulse then
                physicsObject:applyImpulse(e.impulse, e.culprit)
            end
            
            -- Save the persistent data
            core.sendGlobalEvent(D.e.PersistentDataReport, {
                source = omwself,
                data = persistentData
            })

        end
    },
    interfaceName = "LuaPhysicsLight",
    interface = {version=1.0, physicsObject=physicsObject}
}