local util = require('openmw.util')
local world = require('openmw.world')
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
    local dropHeight = 75
    
    -- Always use player position Z + offset - completely ignore aimed Z
    local safeZ = playerPos.z + dropHeight + lightHeight
    -- Drop closer to player: use player position with small forward offset instead of aimed position
    local forward = data.Actor.rotation * util.vector3(0, 1, 0)
    local dropPos = playerPos + forward * 60  -- 30 units in front of player
    local finalPosition = util.vector3(dropPos.x, dropPos.y, safeZ)

    -- Add left offset based on actor's rotation for realistic left-hand drop
    local left = data.Actor.rotation * util.vector3(-1, 0, 0)
    finalPosition = finalPosition + left * 28

    -- Add small random position offset for varied drops
    local randomPosOffset = util.vector3((math.random() - 0.5) * 15, (math.random() - 0.5) * 15, 0)
    finalPosition = finalPosition + randomPosOffset

    light:teleport(data.Actor.cell, finalPosition)
    
    -- Initialize physics
    light:sendEvent(D.e.WhatIsMyPhysicsData, { object = light })
    
    -- Check if this is a special floating lantern with robust ID checking

    local itemId = light.recordId
    local isFloatingLantern = false
    if itemId then
        local lowerItemId = string.lower(itemId)
    --ADD HERE YOUR EXCEPTION ID LIGHT ITEMS (EXAMPLE: HACKLE-LO PIPE)
        isFloatingLantern = (
            lowerItemId == "light_com_lantern_02_inf" or
            lowerItemId == "light_com_lantern_bm_unique"
        )
    end
    
    -- Set physics properties based on lantern type
    local buoyancyValue = isFloatingLantern and 1.5 or 0.3  -- High buoyancy for floating lanterns
    
    -- Set physics for bouncy drop with enhanced rolling and slope interaction
    light:sendEvent(D.e.SetPhysicsProperties, {
        drag = 0.08,              -- Moderate drag for controlled bouncing
        bounce = 1.2,            -- Good bounce factor for sustained bouncing  
        isSleeping = false,       -- Wake up physics
        culprit = data.Actor,     -- Track who dropped it
        mass = 1.2,               -- Good mass for impact and rolling momentum
        buoyancy = buoyancyValue, -- Buoyancy based on lantern type
        lockRotation = false,     -- CRITICAL: Allow full rotation and rolling
        angularDrag = 0.20,       -- Ultra-low angular drag for maximum rolling
        resetOnLoad = false,      -- Don't reset position when loading
        ignoreWorldCollisions = false, -- Allow collision with all surfaces
        collisionMode = "sphere", -- Sphere collision for rolling behavior
        realignWhenRested = false -- Don't auto-align - let it rest naturally rotated
    })
    
    -- Apply impact impulse with random horizontal components for realistic rolling
    local randomHorizontal = util.vector3(
        (math.random() - 0.5) * 16,  -- Random X component (-8 to +8) for rolling direction
        (math.random() - 0.5) * 16,  -- Random Y component (-8 to +8) for rolling direction
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
