-- OpenMW Lua Physics for Light Objects - Based on physicsenginelocal.lua
-- Authors: Maksim Eremenko, GPT-4o (Copilot) - Adapted for Light sources

local mp = 'scripts/MaxYari/LuaPhysics/'

local core = require('openmw.core')
local util = require('openmw.util')
local vfs = require('openmw.vfs')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local async = require('openmw.async')

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
    dropPosition = nil,      -- Remember where it was dropped
    isFloatingLantern = false, -- Track if this is a special floating lantern
    floatingStartTime = nil,  -- When the lantern started floating
    lowSpeedStartTime = nil   -- When the item started moving slowly
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
    local itemId = omwself.recordId
    local isExcluded = false
    if itemId then
        local lowerItemId = string.lower(itemId)
        isExcluded = (
            lowerItemId == "light_com_lantern_02_inf" or
            lowerItemId == "light_com_lantern_bm_unique"
        )
    end
    if not isExcluded then return end

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

    -- Check if item has been moving slowly for x seconds, then disable movement
    if persistentData.lowSpeedStartTime and not physicsObject.isSleeping then
        local now = core.getRealTime()
        local lowSpeedDuration = now - persistentData.lowSpeedStartTime

        if lowSpeedDuration >= 2.35 then -- x seconds
            -- Sleep the physics object to stop movement but allow waking on impulse
            physicsObject:sleep()
            persistentData.lowSpeedStartTime = nil -- Reset timer
        end
    end

    -- Start or reset low speed timer based on current speed
    local speedThreshold = physicsObject.isUnderwater and 30 or 100
    if physicsObject.velocity:length() < speedThreshold then
        if not persistentData.lowSpeedStartTime then
            persistentData.lowSpeedStartTime = core.getRealTime()
        end
    else
        persistentData.lowSpeedStartTime = nil
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

    -- When light touches water, handle based on light type
    if crossedWater and physicsObject.isUnderwater then
        -- Check if this is one of the special lanterns that should float
        local itemId = omwself.recordId
        
        -- More robust ID checking with multiple possible variations
        local isFloatingLantern = false
        if itemId then
            local lowerItemId = string.lower(itemId)
  --ADD HERE YOUR EXCEPTION ID LIGHT ITEMS (EXAMPLE: HACKLE-LO PIPE)
            isFloatingLantern = (
                lowerItemId == "light_com_lantern_02_inf" or
                lowerItemId == "light_com_lantern_bm_unique"
            )
        end
        
        if isFloatingLantern then
            -- These lanterns float on water - adjust buoyancy to keep them on surface
            physicsObject.buoyancy = 1.15  -- High buoyancy to float
            
            -- Mark as floating lantern and start timer if not already started
            if not persistentData.isFloatingLantern then
                persistentData.isFloatingLantern = true
                persistentData.floatingStartTime = core.getRealTime()
            end
            
            -- Don't play extinguish sound or remove the object
        else
            -- Regular lights get extinguished
            core.sendGlobalEvent(D.e.PlaySound, {
                file = "sound/fx/envrn/trch_out.wav",  -- Correct extinguish sound name
                object = omwself,  -- Play on the object so it can be heard while drowning
                params = { volume = 0.7, pitch = 1, loop = false }
            })
            -- Let the light drown for 0.5 seconds while the sound plays, then remove it
            async:newUnsavableGameTimer(0.5, function()
                if omwself and omwself:isValid() then
                    core.sendGlobalEvent(D.e.RemoveObject, { object = omwself })
                end
            end)
        end
    end

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

            -- Reset floating lantern data upon dropping again to ensure sleep is reset (only for floating lantern types)
            local itemId = omwself.recordId
            local isFloatingLantern = false
            if itemId then
                local lowerItemId = string.lower(itemId)
                isFloatingLantern = (
                    lowerItemId == "light_com_lantern_02_inf" or
                    lowerItemId == "light_com_lantern_bm_unique"
                )
            end
            if isFloatingLantern then
                persistentData.isFloatingLantern = false
                persistentData.floatingStartTime = nil
            end

            -- Update initial position to current drop position
            physicsObject.initialPosition = physicsObject.position
            physicsObject.resetOnLoad = false

            -- Add small random side offset to drop position for varied left/right direction
            local sideOffset = util.vector3(math.random(-10, 10), 0, 0)  -- random left/right offset in world coordinates
            physicsObject.position = physicsObject.position + sideOffset
            physicsObject.initialPosition = physicsObject.position

            -- Add small random position offset for varied drops
            local randomPosOffset = util.vector3(math.random(-5,5), math.random(-5,5), 0)
            physicsObject.position = physicsObject.position + randomPosOffset
            physicsObject.initialPosition = physicsObject.position

            -- Re-initialize physics object to clear any previous state
            physicsObject:reInit()

            -- Reset disabled state for new drop
            physicsObject.disabled = false

            -- Reset low speed timer
            persistentData.lowSpeedStartTime = nil

            -- Wake up the physics object when torch is dropped
            physicsObject:wakeUp()
            physicsObject:setCulprit(e.culprit)

            -- Set gentle physics for controlled fall
            physicsObject.drag = 0.1
            physicsObject.angularDrag = 0.1
            physicsObject.friction = 2.0
            physicsObject.bounce = 0.69
            physicsObject.mass = 0.55
            physicsObject.buoyancy = 0.1
            physicsObject.realignWhenRested = false

            if e.impulse then
                physicsObject:applyImpulse(e.impulse, e.culprit)
            end
            -- Add small random momentum with upward bias and left/right direction
            local randomImpulse = util.vector3(math.random(-10,10), math.random(-5,5), math.random(35,70))
            physicsObject:applyImpulse(randomImpulse, e.culprit)

            -- Add small forward push in player's facing direction
            local playerForward = e.culprit.rotation:apply(util.vector3(0, 1, 0))
            local forwardImpulse = playerForward * 10
            physicsObject:applyImpulse(forwardImpulse, e.culprit)

            -- Add slight random rotation
            local randomAngularImpulse = util.vector3(math.random(-30,30), math.random(-30,30), math.random(-20,20))
            physicsObject.angularVelocity = randomAngularImpulse

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