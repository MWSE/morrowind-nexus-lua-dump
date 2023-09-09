local MOD_VERSION = "0.1.0-beta"
-- ==============================================
-- IMPORTS
-- ==============================================
-- ALL SCRIPTS
local async = require('openmw.async')
local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local storage = require('openmw.storage')
local types = require('openmw.types')
local util = require('openmw.util')
-- PLAYER SCRIPTS ONLY
local ambient = require('openmw.ambient')
local camera = require('openmw.camera')
local input = require('openmw.input')
local ui = require('openmw.ui')
-- LOCAL SCRIPTS ONLY
local nearby = require('openmw.nearby')
local self = require('openmw.self')

-- ==============================================
-- IMPORTED CONSTANTS
-- ==============================================
local ANY_PHY = nearby.COLLISION_TYPE.AnyPhysical


-- ==============================================
-- SCRIPT CONFIGURABLE CONSTANTS (BEST TO LEAVE AS-IS)
-- ==============================================
local ITEM_Z_OFFSET = 5             -- Items can be very flat so a low / zero z offset is optimal
local BUMP_OFFSET = 15              -- Offset to prevent teleports from pushing objects through wall / floor
local STUCK_DIST_THRESHOLD = 0.0001 -- Object has to move more than this distance per tick or sequence ends
local STUCK_COUNT_THRESHOLD = 0     -- Number of frames the object has been stuck before stopping ragdoll
local MAX_TIMEOUT = 2               -- Maximum ragdoll duration (seconds) for fail-safe purposes
local ITEM_HALF_WIDTH = 10          -- Bounding box data for items
local ITEM_HEIGHT = 20              -- Bounding box data for items
local PREV_POS_UPDATE_DT = 50/1000  -- Time to update prevPos
local BOUNDING_DATA_PTS = 6         -- Number of points that comprises of a bounding box

local M_TO_UNITS = 400              -- Gut-feel conversion from meters to... whatever units Morrowind uses for distance
local TERMINAL_VELOCITY = 53 * M_TO_UNITS   -- Maximum downward velocity by gravity. Super basic physics ok
local GRAVITY_MS2 = 9.80665 * M_TO_UNITS    -- The power of Earth's love

-- ==============================================
-- ADVANCED USER CONFIGURABLE CONSTANTS
-- ==============================================
-- todo: review these
interfaces.Settings.registerPage { key = "OpenMWHookshotPg", l10n = "OpenMWHookshot", name = "OpenMW Hookshot", description = "OpenMW Hookshot Lua Mod v" .. MOD_VERSION .. ". After modifying settings, reload the game or run `reloadlua` in the console to apply them." }
interfaces.Settings.registerGroup { 
    key = "Settings_OpenMW_Hookshot_2",
    page = "OpenMWHookshotPg",
    l10n = "OpenMWHookshot",
    name = "Advanced Settings",
    description = "Best to leave as-is",
    permanentStorage = true,
    settings = {
        { key = "BASE_RETICLE_SIZE", renderer = "number", name = "BASE_RETICLE_SIZE", default = 1000, description = 'Starting size of hookshot reticle before scaling down due to distance'},
        { key = "PULL_OFFSET", renderer = "number", name = "PULL_OFFSET", default = 50, description = 'Distance from player to pull target to' },
        { key = "SELF_PULL_OFFSET", renderer = "number", name = "SELF_PULL_OFFSET", default = 80, description = 'Distance from target to send player to (to avoid clipping)' },
        { key = "PULL_SPD", renderer = "number", name = "PULL_SPD", default = 3000, description = 'Speed per second to pull targets at' },
        { key = "MAX_HOOKSHOT_RANGE", renderer = "number", name = "MAX_HOOKSHOT_RANGE", default = 2000, description = 'Maximum range for hookshot to have effect' }
    }
}
local advancedSettings = storage.playerSection("Settings_OpenMW_Hookshot_2")
local BASE_RETICLE_SIZE = advancedSettings:get("BASE_RETICLE_SIZE")
local PULL_OFFSET = advancedSettings:get("PULL_OFFSET")                 -- Distance from player to pull objects to
local SELF_PULL_OFFSET = advancedSettings:get("SELF_PULL_OFFSET")       -- Distance from objects to pull player to
local PULL_SPD = advancedSettings:get("PULL_SPD")                       -- Speed to pull objects
local MAX_HOOKSHOT_RANGE = advancedSettings:get("MAX_HOOKSHOT_RANGE")   -- Maximum hookshot range

-- ==============================================
-- BASIC USER CONFIGURABLE CONSTANTS SETUP
-- ==============================================
interfaces.Settings.registerGroup {
  key = "Settings_OpenMW_Hookshot_1",
  page = "OpenMWHookshotPg",
  l10n = "OpenMWHookshot",
  name = "Basic Settings",
  description = "",
  permanentStorage = true,
  settings = {
    { key = "HOOKSHOT_KEY", renderer = "textLine", name = "Hookshot key", default = 'z', description = 'Keybinding for drawing/firing hookshot (lower-case)'},
    { key = "SHEATH_KEY", renderer = "textLine", name = "Sheath key", default = 'x', description = 'Keybinding for putting hookshot away (lower-case)'},
  }
}
local basicSettings = storage.playerSection("Settings_OpenMW_Hookshot_1")
local HOOKSHOT_KEY = basicSettings:get("HOOKSHOT_KEY")                              -- Keybinding for hookshot (lower-case)
local SHEATH_KEY = basicSettings:get("SHEATH_KEY")                                  -- Keybinding for cancel (lower-case)

-- ==============================================
-- RESOURCES & TEXTURES
-- ==============================================
local reticleTexturePath = "Textures/hookshot_circle.dds"
local reticleTexture = ui.texture { path = reticleTexturePath }

local reticle = ui.create {
    layer = "HUD",
    type = ui.TYPE.Image,
    size = util.vector2(BASE_RETICLE_SIZE, BASE_RETICLE_SIZE), -- I don't think this does anything
    props = {
        size = util.vector2(BASE_RETICLE_SIZE, BASE_RETICLE_SIZE),
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(0.5, 0.5),
        resource = reticleTexture,
        visible = false,
        color = util.color.rgb(1, 0, 0)
    }
}

-- ==============================================
-- SOUNDS
-- ==============================================
local hookshotToggle = "Sound\\OOT_Hookshot_Toggle.mp3"
local hookshotSet = "Sound\\OOT_Hookshot_Set.mp3"
local hookshotFire = "Sound\\OOT_Hookshot_Fire.mp3"
local hookshotTarget = "Sound\\OOT_Hookshot_Target.mp3"

-- ==============================================
-- SCRIPT LOCAL VARIABLES
-- ==============================================
local hookshotIsDrawn = false
local reticleActive = false
local lastPlayerCameraMode = camera.MODE.FirstPerson
local cameraPos
local cameraV
local sightImpact
local sightRange
local ragDollData = {}
--[[
    When adding objects to this array, each object in this array follows this format: {
        Name        Type            Descript
        target      GameObject      
        boundingData
        seqs        Sequence[]      Array of Sequences in inverted order; the last occurs first.
        contOnHit   boolean         Optional: Continue animating on colliding with a physical object.
        
        Helper params for the ragdoll logic to work properly
        seqInit     boolean         For the updater to track if these params have been initialized
        zOffset     int             virtual Z (vertical) offset to apply to current position to avoid floor collision
        origDist    int             There to smooth animation when using targetP
        prevPos     Vector 3        
        dtPrevPos   float           dt since last prevPos update.
        tElapsed    float           Time elapsed
        stuckCount  int             Counter for number of frames item has been stuck
        travelled   float           Distance travelled
    }

    A Sequence comprises of: {
        v           Vector3         Directional vector. Either v or targetP must be set.
        targetP     Vector3         Target position; if set, v is ignored and object is tweened to position instead.
        spd         float           Speed for targetP.
        applyG      boolean         Optional: If set, apply gravity to v.
        timeout     float           Optional: Maximum time elapsed (seconds) until terminating sequence
        contToTime  boolean         Optional: Continue until timeout.
        contOnHit   boolean         Optional: Continue on hit. Otherwise, the sequence will be removed immediately.
    }

    Implicit rules:
    1. Collisions wlll stop sequences / the entire animating logic by default.
    2. If spd drops to zero or less than 0, or object stops moving (tracked by prevPos), sequence is removed.
--]]

-- ==============================================
-- GENERIC FUNCTIONS
-- ==============================================
-- Safely rm items from an array table while iterating
-- For your fnKeep, return true if keeping element, otherwise false
local function ArrayIter(t, fnKeep)
    local j, n = 1, #t
    for i=1,n do
        if (fnKeep(t,i,j)) then
            if(i~=j) then 
                t[j] = t[i];
            end
            j = j+1;
        end
    end
    table.move(t,n+1,n+n-j+1,j)
    return t;
end

-- ----------------------------------------------
-- MISC FUNCTIONS
-- ----------------------------------------------
local function anglesToV(pitch, yaw) 
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw),  -- x
        xzLen * math.cos(yaw),  -- y
        math.sin(pitch)         -- z
    )
end
local function addToVector3(v, xDiff, yDiff, zDiff) return util.vector3(v.x + xDiff, v.y + yDiff, v.z + zDiff) end
local function getHP(actor) return types.Actor.stats.dynamic.health(actor).current end
local function isAlive(actor) return getHP(actor) > 0 end
local function getName(o)
    if not o then return "Target" end
    if o.type == types.NPC then return types.NPC.record(o).name end
    if o.type == types.Creature then return types.Creature.record(o).name end
    return "Target"
end
-- Light-producing objects can be placed in inventory by console, so they cause problems.
-- We have to exclude them or we can pick up e.g. the braziers in vivec's room
-- should use Types.Item.IsCarriable() but it's currently broken in the API
local function isCarriableItem(t)
    local isItem = t and types.Item.objectIsInstance(t)
    local isLight = t and types.Light.objectIsInstance(t)
    return isItem and not isLight
end
local function isActor(t) return t and t.type and t.type.baseType == types.Actor end
local function rmFromRagDollData(t) ArrayIter(ragDollData, function(ragDollData, i, j) return ragDollData[i].target ~= t end) end

-- ----------------------------------------------
-- ACCESS RESTRICTION FUNCTIONS
-- ----------------------------------------------
local function isGrabbable(t) return isCarriableItem(t) or isActor(t) end

-- ----------------------------------------------
-- CAMERA/TARGETING FUNCTIONS
-- ----------------------------------------------

local function getCameraDirData()
    local pos = camera.getPosition()
    local pitch = -(camera.getPitch() + camera.getExtraPitch())
    local yaw = (camera.getYaw() + camera.getExtraYaw())
    return pos, anglesToV(pitch, yaw)
end

local function asyncGetObjInCrosshairs(rayCastingResult)
    if rayCastingResult.hitPos then
        sightImpact = rayCastingResult
        sightRange = (cameraPos - rayCastingResult.hitPos):length()
    else
        sightImpact = nil
        sightRange = nil
    end
end

local function toggleReticleOff()
    if not reticleActive then return end

    reticle.layout.props.visible = false
    reticle:update()
    camera.showCrosshair(true)
    reticleActive = false
end

local function toggleReticleOn()
    if reticleActive then return end

    -- we always call update() right after this, so no need to call it here
    reticle.layout.props.visible = true
    camera.showCrosshair(false)
    reticleActive = true
end

local function tryDrawReticle()
    if not hookshotIsDrawn then return end

    cameraPos, cameraV = getCameraDirData()
    local rayTarget = cameraPos + cameraV * MAX_HOOKSHOT_RANGE

    nearby.asyncCastRenderingRay(
        async:callback(
            function(rayCastingResult) asyncGetObjInCrosshairs(rayCastingResult) end
        ),
        cameraPos,
        rayTarget
    )

    if not sightImpact then
        toggleReticleOff()
        return
    end

    -- print(sightRange)
    toggleReticleOn()
    local reticleSize = BASE_RETICLE_SIZE / (sightRange / 4)
    reticle.layout.props.size = util.vector2(reticleSize, reticleSize)
    reticle:update()
end


-- ----------------------------------------------
-- COLLISION MANAGEMENT FUNCTIONS
-- ----------------------------------------------

-- Teleport with collision handling
-- Returns array of {position=teleport target position, collided=whether or not a collision occurred}
local function tpWithCollision(target, boundingData, newPos, startPos)
    local pos = startPos or target.position
    local dirVector = (newPos - pos):normalize()
    local currVectorLen = (newPos - pos):length()
    -- print(currVectorLen)
    local collidedWithSomething = false

    -- Iterate through all bounding points, pushing back the travelled distance as necessary
    for idx = 1, BOUNDING_DATA_PTS do
        local tmpPos = pos + boundingData.sideVectors[idx]
        local obstacle = nearby.castRay(
            tmpPos,
            tmpPos + dirVector * math.max(0, currVectorLen),
            {
                collisionType = ANY_PHY,
                ignore = target
            }
        )
        if obstacle.hitPos then
            collidedWithSomething = true

            -- Shorten the actual moved amount
            local f = currVectorLen
            currVectorLen = (tmpPos - obstacle.hitPos):length() - BUMP_OFFSET
        end
    end

    if collidedWithSomething then
        local actualNewPos = pos + dirVector * currVectorLen
        core.sendGlobalEvent('ragdollTeleport', { object = target, newPos = actualNewPos })
        return {position=newPos, collided=true}
    else
        core.sendGlobalEvent('ragdollTeleport', { object = target, newPos = newPos })
        return {position=newPos, collided=false}
    end
end

-- Concept: castRay will impact on target's side, telling us its bounds. Doing so we can obtain an approximation of its bounding box.
-- From the origin, cast a ray outwards to the nearest object, then cast back at the target. The difference is the height / halfWidth depending on the direction.
-- Returns an object that follows this format:
--[[
    {
        halfWidth
        height
        sideVectors: An array of 6 vector3s for the midpoint of every side of the bounding cube. Add position to get their actual position during runtime.
    }
--]]
local function getBoundingData(target)
    -- Items don't have collision
    local halfWidth = ITEM_HALF_WIDTH
    local height = ITEM_HEIGHT
    local zOffset
    if target == self then
        -- todo: look up ways to get bounding box of player
    elseif isActor(target) then
        -- Assumption is that nothing is clipping through the target at time of measurement
        -- Assuming that no actor will be taller than 2000
        -- In the event of failure, just keep it simple & return the default bounds
        local MAX_ACTOR_RADIUS = 2000
        -- Get top
        local refPt = addToVector3(target.position, 0, 0, MAX_ACTOR_RADIUS)
        local ref = nearby.castRay(target.position, refPt, { collisionType = ANY_PHY, ignore = target })
        if ref.hitPos then refPt = addToVector3(ref.hitPos, 0, 0, -1) end
        local bbPos = nearby.castRay(refPt, target.position, { collisionType = ANY_PHY }).hitPos
        if bbPos then
            height = (bbPos - target.position):length()
        end

        -- Assumes that the that position is the midpoint of the width
        refPt = addToVector3(target.position, MAX_ACTOR_RADIUS, 0, height / 2)
        ref = nearby.castRay(target.position, refPt, { collisionType = ANY_PHY, ignore = target })
        if ref.hitPos then refPt = addToVector3(ref.hitPos, -1, 0, 0) end
        bbPos = nearby.castRay(refPt, target.position, { collisionType = ANY_PHY }).hitPos
        if bbPos then
            halfWidth = (bbPos - target.position):length()
        end

        -- Get the larger of x / y
        refPt = addToVector3(target.position, 0, MAX_ACTOR_RADIUS, height / 2)
        ref = nearby.castRay(target.position, refPt, { collisionType = ANY_PHY, ignore = target })
        if ref.hitPos then refPt = addToVector3(ref.hitPos, 0, -1, 0) end
        bbPos = nearby.castRay(refPt, target.position, { collisionType = ANY_PHY }).hitPos
        if bbPos then
            halfWidth = math.max(halfWidth, (bbPos - target.position):length())
        end

        -- Note that target will most likely be lying down if they are dead.
        if not isAlive(target) then height = height / 4 end
        zOffset = 50
    else
        -- Items can be very flat, so it's important they don't have a zOffset
        zOffset = ITEM_Z_OFFSET
    end

    return {
            halfWidth = halfWidth,
            height = height,
            sideVectors = {
                util.vector3(0, 0, zOffset), -- Assume position is bottom side
                util.vector3(0, 0, height), -- top
                util.vector3(halfWidth, 0, height / 2), -- rest of the sides
                util.vector3(-halfWidth, 0, height / 2),
                util.vector3(0, halfWidth, height / 2),
                util.vector3(0, -halfWidth, height / 2),
            }
        }
end

-- ==============================================
-- ON_UPDATE LOGIC
-- ==============================================
local function dropObject(ragdoll)
    table.insert(ragDollData, {
        target = ragdoll.target,
        isFalling = true,
        boundingData = ragdoll.boundingData,
        seqs = {{ v = util.vector3(0, 0, 0.1), timeout = MAX_TIMEOUT, applyG = true }}
    })
end

local function terminateHook(ragdoll)
    if not ragdoll.isFalling then
        ambient.stopSoundFile(hookshotFire)
        if isCarriableItem(ragdoll.target) then
            dropObject(ragdoll)
        end
    end
end

local function removeSequences(ragdoll)
    table.remove(ragdoll.seqs)
    ragdoll.seqInit = false
    terminateHook(ragdoll)
    return true
end

local function updateRagdoll(deltaSeconds)
    -- Basic physics ragdolling
    ArrayIter(ragDollData, function(ragDollData, i, j)
        local o = ragDollData[i]
        -- Stop animating object if it's finished all its sequences
        local lastIdx = table.getn(o.seqs)
        if lastIdx <= 0 then
            return false
        end

        -- lift objects/player slightly before first moving them
        local zOffset = 0 -- o.zOffset or 0
        o.zOffset = 0
        -- teleportation takes place one frame later, so we need to buffer our position change for self
        -- to avoid jaggy teleportation

        local objectPosition = o.bufferPosition or o.target.position

        -- apply z offset if applicable
        -- objectPosition = addToVector3(objectPosition, 0, 0, zOffset)

        local s = o.seqs[lastIdx]
        -- If not initialized, do so
        if not o.seqInit then
            if not o.travelled then o.travelled = 0 end
            o.seqInit = true
            o.tElapsed = deltaSeconds
            o.prevPos = nil
            o.dtPrevPos = 0
            o.stuckCount = 0
            if s.targetP then
                o.origDist = (objectPosition - s.targetP):length()
            end
        else 
            -- Else, monitor termination events
            o.tElapsed = o.tElapsed + deltaSeconds
            if o.prevPos and o.dtPrevPos >= PREV_POS_UPDATE_DT then
                o.travelled = o.travelled + (o.target.position - o.prevPos):length()
            end
            if (s.timeout and s.timeout < o.tElapsed) then
                print("Removed by timeout")
                return removeSequences(o)
            elseif(o.prevPos and (o.target.position - o.prevPos):length() < STUCK_DIST_THRESHOLD and o.dtPrevPos >= PREV_POS_UPDATE_DT) then
                o.stuckCount = o.stuckCount + 1
                if o.stuckCount > STUCK_COUNT_THRESHOLD and not s.contToTime then
                    print("Removed by stuck position")
                    return removeSequences(o)
                end
            end
        end

        if s.targetP then
            -- Set v to tween to position if targetP is set
            -- Update v continually as teleported position is not guaranteed
            s.v = s.targetP - objectPosition
            local currDist = s.v:length()
            s.v = s.v:normalize() * s.spd
        end

        -- Set v modifiers
        if s.applyG and s.v.z < TERMINAL_VELOCITY then
            s.v = util.vector3(s.v.x, s.v.y, s.v.z - GRAVITY_MS2 * deltaSeconds)
        end

        -- Move & check terminations on collision
        if o.dtPrevPos >= PREV_POS_UPDATE_DT then
            o.prevPos = o.target.position
            o.dtPrevPos = 0
        else
            o.dtPrevPos = o.dtPrevPos + deltaSeconds
        end
        local speedV = s.v * deltaSeconds
        local newPos = objectPosition + speedV
        local reachedDestination = false
        -- probably replace this logic with just checking the length after the teleport with collision
        if s.targetP then
            local posV = newPos - s.targetP
            -- If +ve, acute angle. Negative, obtuse angle i.e. we've reached our destination
            local isAcute = math.acos(
                math.max(-1, 
                    math.min(1, 
                        s.v:dot(posV) / (s.v:length() * posV:length())
                    )
                )
            )
            if isAcute <= 0 then
                newPos = s.targetP
                reachedDestination = true
            end
        end

        local tpResult = tpWithCollision(o.target, o.boundingData, newPos, objectPosition)
        if tpResult.collided then
            if not o.contOnHit and not s.contToTime then
                print("Removed by hit 1")
                removeSequences(o)
                return false
            elseif not s.contOnHit and not s.contToTime then
                print("Removed by hit 2")
                removeSequences(o)
            else
                o.bufferPosition = tpResult.position
            end
        end

        if reachedDestination and not s.contToTime then
            print("Removed by arrival")
            removeSequences(o)
        end
        return true
    end)
end

local function onUpdate(deltaSeconds)
    updateRagdoll(deltaSeconds)
    tryDrawReticle()
end

-- ==============================================
-- INPUT ENGINE HANDLERS
-- ==============================================
local function pullHookedObject(target, v)
    rmFromRagDollData(target)
    local camZ = camera.getPosition().z -- might need to revisit these
    local newZ = isActor(target) and (camZ + self.position.z) / 2 or camZ
    -- set target position for pull to PULL_OFFSET distance from player along line between player/object
    local targetPos = util.vector3(self.position.x, self.position.y, newZ) + v * (PULL_OFFSET)
    table.insert(ragDollData, {
        target = target,
        boundingData = getBoundingData(target),
        seqs = {{
            targetP = targetPos,
            spd = PULL_SPD,
            timeout = MAX_TIMEOUT,
        }}
    })
end

local function hookToWorldObject(object, targetPos, v)
    -- set target position for pull to SELF_PULL_OFFSET distance from target along line between player/target
    local updatedTargetPos = targetPos - v * (SELF_PULL_OFFSET)
    table.insert(ragDollData, {
        target = self,
        boundingData = getBoundingData(object),
        seqs = {{
            targetP = updatedTargetPos,
            spd = PULL_SPD,
            timeout = MAX_TIMEOUT,
        }}
    })
end

local function drawHookshot()
    ambient.playSoundFile(hookshotToggle)
    ambient.playSoundFile(hookshotSet)
    lastPlayerCameraMode = camera.getMode()
    camera.setMode(camera.MODE.FirstPerson)
    input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, false)
    hookshotIsDrawn = true
end

local function deactivateHookshotDrawnState()
    toggleReticleOff()
    hookshotIsDrawn = false
    camera.setMode(lastPlayerCameraMode)
    input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, true)
end

local function fireHookshot()
    -- todo: disable inputs while hookshot is happening
    if not sightImpact then
        ui.showMessage("No target in hookshot range")
        return
    end
    local target = sightImpact.hitObject or nil

    ambient.playSoundFile(hookshotFire)
    ambient.playSoundFile(hookshotTarget)
    deactivateHookshotDrawnState()
    if isGrabbable(target) then
        pullHookedObject(target, cameraV)
    else
        -- ray hit a world object, so pull self to ray hit position
        hookToWorldObject(target, sightImpact.hitPos, cameraV)
    end
end

local function trySheathHookshot()
    if not hookshotIsDrawn then return end

    ambient.playSoundFile(hookshotToggle)
    deactivateHookshotDrawnState()
end

local function tryActivateHookshot()
    -- might need logic here to prevent this from happening sometimes
    if hookshotIsDrawn then
        fireHookshot()
    else
        drawHookshot()
    end
end

local function onKeyPress(key)
    if key.symbol == HOOKSHOT_KEY then tryActivateHookshot()
    elseif key.symbol == SHEATH_KEY then trySheathHookshot()
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = onKeyPress
    }
}


-- TODO:
-- add graphics
-- add hookshot mode with camera switch and reticle activation
-- add ability to cancel hookshot mode
