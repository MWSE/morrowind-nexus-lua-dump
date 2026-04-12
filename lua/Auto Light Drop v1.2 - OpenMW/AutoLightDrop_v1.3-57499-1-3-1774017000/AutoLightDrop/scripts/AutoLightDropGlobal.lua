local util = require('openmw.util')
local world = require('openmw.world')

-- Import physics definitions like physics engine does
local mp = 'scripts/MaxYari/LuaPhysics/'
local D = require(mp .. 'scripts/physics_defs')

local function DropLight(data)
    local light = data.Light
    local position = data.Position or data.Actor.position
    
    -- Get light height for proper placement
    local bbox = light:getBoundingBox()
    local lightHeight = bbox.halfSize.z
    
    -- Drop height for dramatic fall and rolling
    local playerPos = data.Actor.position
    local dropHeight = 55
    
    -- Always use player position Z + offset - completely ignore aimed Z
    local safeZ = playerPos.z + dropHeight + lightHeight
    local finalPosition = util.vector3(position.x, position.y, safeZ)
    
    light:teleport(data.Actor.cell, finalPosition)
    
    -- Initialize physics
    light:sendEvent(D.e.WhatIsMyPhysicsData, { object = light })
    
    -- Set physics for bouncy drop with enhanced rolling and slope interaction
    light:sendEvent(D.e.SetPhysicsProperties, {
        drag = 0.08,              -- Moderate drag for controlled bouncing
        bounce = 1.2,            -- Good bounce factor for sustained bouncing  
        isSleeping = false,       -- Wake up physics
        culprit = data.Actor,     -- Track who dropped it
        mass = 1.2,               -- Good mass for impact and rolling momentum
        buoyancy = 0.3,           -- Natural buoyancy for realistic behavior
        lockRotation = false,     -- CRITICAL: Allow full rotation and rolling
        angularDrag = 0.20,       -- Ultra-low angular drag for maximum rolling
        resetOnLoad = false,      -- Don't reset position when loading
        ignoreWorldCollisions = false, -- Allow collision with all surfaces
        collisionMode = "sphere", -- Sphere collision for rolling behavior
        realignWhenRested = false -- Don't auto-align - let it rest naturally rotated
    })
    
    -- Apply impact impulse with random horizontal components for realistic rolling
    local randomHorizontal = util.vector3(
        (math.random() - 0.5) * 8,  -- Random X component (-4 to +4) for rolling direction
        (math.random() - 0.5) * 8,  -- Random Y component (-4 to +4) for rolling direction  
        -12                         -- Strong downward component for impact
    )
    light:sendEvent(D.e.ApplyImpulse, {
        impulse = randomHorizontal,
        culprit = data.Actor
    })
    
    -- Send activation event with enhanced rotation
    light:sendEvent("ActivateLightPhysics", {
        impulse = util.vector3(0, 0, -1),
        culprit = data.Actor,
        newInitialPosition = finalPosition,
        enableRolling = true
    })
end

return {
    eventHandlers = {
        DropLight = DropLight,
    },
    engineHandlers = {
        
    }
}