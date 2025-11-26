--[[
ErnOneStick for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME = require("scripts.ErnOneStick.ns")
local state = require("scripts.ErnOneStick.state")
local radians = require("scripts.ErnOneStick.radians")
local targetui = require("scripts.ErnOneStick.targetui")
local keytrack = require("scripts.ErnOneStick.keytrack")
local targets = require("scripts.ErnOneStick.targets")
local fatigue = require("scripts.ErnOneStick.fatigue")
local unitoggle = require("scripts.ErnOneStick.unitoggle")
local shaderUtils = require("scripts.ErnOneStick.shader_utils")
local core = require("openmw.core")
local pself = require("openmw.self")
local camera = require('openmw.camera')
local util = require('openmw.util')
local async = require("openmw.async")
local types = require('openmw.types')
local input = require('openmw.input')
local controls = require('openmw.interfaces').Controls
local nearby = require('openmw.nearby')
local cameraInterface = require("openmw.interfaces").Camera
local uiInterface = require("openmw.interfaces").UI

local admin = require("scripts.ErnOneStick.settings.admin")
local inputSettings = require("scripts.ErnOneStick.settings.input")
local dpadSettings = require("scripts.ErnOneStick.settings.dpad")

if admin.val.disable then
    print(MOD_NAME .. " is disabled.")
    return
end

local function takeControl(assumeControl)
    if assumeControl then
        controls.overrideMovementControls(true)
        cameraInterface.disableModeControl(MOD_NAME)
    else
        controls.overrideMovementControls(false)
        cameraInterface.enableModeControl(MOD_NAME)
    end
end

takeControl(not inputSettings.val.twoStickMode)

local runThreshold = 0.9

local invertLook = 1
if inputSettings.val.invertLookVertical then
    invertLook = -1
end

local function clearControls()
    pself.controls.sideMovement = 0
    pself.controls.movement = 0
    pself.controls.yawChange = 0
    pself.controls.pitchChange = 0
    pself.controls.run = false
end

local function getSoundFilePath(file)
    return "Sound\\" .. MOD_NAME .. "\\" .. file
end

local function resetCamera()
    camera.setYaw(pself.rotation:getYaw())
    camera.setPitch(pself.rotation:getPitch())
end

local function inBox(position, box)
    local normalized = box.transform:inverse():apply(position)
    return math.abs(normalized.x) <= 1
        and math.abs(normalized.y) <= 1
        and math.abs(normalized.z) <= 1
end

local function inWorldSpace(entity)
    return (entity ~= nil) and entity:isValid() and entity.enabled and (entity.parentContainer == nil) and
        pself.cell:isInSameSpace(entity)
end

local function targetAngles(worldVector, t)
    -- This swings the viewport toward worldVector
    if t == nil then
        t = 1
    end

    -- safety for when we're too close
    if (util.vector2(pself.position.x, pself.position.y) - util.vector2(worldVector.x, worldVector.y)):length2() < 200 then
        admin.debugPrint("too close")
        return {
            yaw = 0,
            pitch = 0
        }
    end

    local direction = (worldVector - camera.getPosition()):normalize()
    -- Two-variable atan2 is not available here!
    local targetYaw = util.normalizeAngle(math.atan2(direction.x, direction.y))
    local targetPitch = util.normalizeAngle(-math.asin(direction.z))

    targetYaw = radians.lerpAngle(pself.rotation:getYaw(), targetYaw, t)
    targetPitch = radians.lerpAngle(pself.rotation:getPitch(), targetPitch, t)

    return {
        yaw = targetYaw,
        pitch = targetPitch
    }
end

local function identity(p) return p end

local function trackPitch(targetPitch, t, pitchModFn)
    if t == nil then
        t = 1
    end
    if pitchModFn == nil then
        pitchModFn = identity
    end
    targetPitch = radians.lerpAngle(pself.rotation:getPitch(), targetPitch, t)

    if radians.anglesAlmostEqual(pself.rotation:getPitch(), targetPitch) then
        return
    end

    camera.setPitch(pitchModFn(targetPitch))
    pself.controls.pitchChange = radians.subtract(pself.rotation:getPitch(), targetPitch)
end

local function track(worldVector, t, pitchModFn, yawModFn)
    if pitchModFn == nil then
        pitchModFn = identity
    end
    if yawModFn == nil then
        yawModFn = identity
    end
    local angles = targetAngles(worldVector, t)

    if radians.anglesAlmostEqual(pself.rotation:getYaw(), angles.yaw) and radians.anglesAlmostEqual(pself.rotation:getPitch(), angles.pitch) then
        return
    end

    camera.setPitch(pitchModFn(angles.pitch))
    pself.controls.pitchChange = radians.subtract(pself.rotation:getPitch(), angles.pitch)

    camera.setYaw(yawModFn(angles.yaw))
    pself.controls.yawChange = radians.subtract(pself.rotation:getYaw(), angles.yaw)
end

local function look(worldVector, t)
    -- This is instant and works during pause.
    local angles = targetAngles(worldVector, t)

    if radians.anglesAlmostEqual(pself.rotation:getYaw(), angles.yaw) and radians.anglesAlmostEqual(pself.rotation:getPitch(), angles.pitch) then
        return
    end

    -- Actually rotate the player so they are facing that direction.
    -- This will also change the camera to match.
    local trans = util.transform
    core.sendGlobalEvent(MOD_NAME .. "onRotate", {
        object = pself,
        rotation = trans.rotateZ(angles.yaw) * trans.rotateX(angles.pitch)
    })

    -- this all matches
    --[[admin.debugPrint("Yaw/Pitch: target(" ..
        string.format("%.3f", targetYaw) ..
        "/" .. string.format("%.3f", targetPitch) ..
        ") actual(" ..
        string.format("%.3f", camera.getYaw()) .. "/" .. string.format("%.3f", camera.getPitch()) ..
        ") self(" ..
        string.format("%.3f", pself.rotation:getYaw()) .. "/" .. string.format("%.3f", pself.rotation:getPitch()) ..
        ")")]]
end

local function setThirdPOVSettings()
    camera.setPreferredThirdPersonDistance(120)
    camera.setFocalPreferredOffset(util.vector2(0, 15))
end

local function isActor(entity)
    return entity.type == types.Actor or entity.type == types.NPC or entity.type == types.Creature
end


local function lerpVector3(a, b, t)
    return a + (b - a) * t
end

-- easeInOutSine is a smoothing function. t ranges from 0 to 1.
local function easeInOutSine(t)
    return -1 * (math.cos(math.pi * t) - 1) / 2
end

-- boundingBoxSizeCache is used to damp bounding box size changes.
local boundingBoxSizeCache = {}

local function lockOnPosition(entity)
    local pos = entity:getBoundingBox().center
    if isActor(entity) then
        local sizes = entity:getBoundingBox().halfSize
        local lastSizes = boundingBoxSizeCache[entity.id] or sizes
        local dampedSize = lerpVector3(sizes, lastSizes, 0.9)
        boundingBoxSizeCache[entity.id] = dampedSize
        -- if the actor is tall, offset so we are hopefully looking at their face.
        -- this needs to be smooth
        local zRatio = util.clamp(dampedSize.z / math.max(dampedSize.x, dampedSize.y), 0, 2) / 2
        -- zRatio is 0 for a flat plane, ~0.5 for a cube, 1 for an actor whose height is twice their base.
        -- the issue with this is that the bounding box z height can change rapidly during an animation (even walking)
        -- so it needs to be damped.
        pos = pos + entity.rotation:apply(util.vector3(0, 0, (dampedSize.z) * zRatio * 0.7))
    end

    --admin.debugPrint(string.format("%.3f", entity:getBoundingBox().center.z) .. " - " .. string.format("%.3f", pos.z))
    return pos
end

local function getReach()
    -- magnitude of telekinesis is in feet
    -- need "Constants::UnitsPerFoot" =  21.33333333f
    -- normal reach is gmst: iMaxActivateDist, which is in game units
    local dist = core.getGMST("iMaxActivateDist")
    local telekinesisEffect = types.Actor.activeEffects(pself):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesisEffect ~= nil then
        dist = dist + telekinesisEffect.magnitude * 21.33333333
    end
    return dist
end

local keyLock = keytrack.NewKey("lock",
    function(dt) return input.getBooleanActionValue(MOD_NAME .. "LockButton") end)
local keyForward = keytrack.NewKey("forward", function(dt)
    return input.getRangeActionValue("MoveForward")
end)
local keyBackward = keytrack.NewKey("backward", function(dt)
    return input.getRangeActionValue("MoveBackward")
end)

local keyLeft = keytrack.NewKey("left", function(dt)
    return input.getRangeActionValue("MoveLeft")
end)
local keyRight = keytrack.NewKey("right", function(dt)
    return input.getRangeActionValue("MoveRight")
end)

local keySneak = keytrack.NewKey("sneak",
    function(dt) return input.getBooleanActionValue("Sneak") end)

-- Jump is a trigger, not an action.
input.registerTriggerHandler("Jump", async:callback(function() pself.controls.jump = true end))

local activating = false
input.registerTriggerHandler("Activate", async:callback(function() activating = true end))
local function handleActivate(dt)
    activating = false
end

-- Have to recreate sneak toggle.
local function handleSneak(dt)
    keySneak:update(dt)
    if keySneak.rise then
        pself.controls.sneak = not pself.controls.sneak
    end
end

local stateMachine = state.NewStateContainer()


local hexDofShader = shaderUtils.NewShaderWrapper("hexDoFProgrammable", {
    uDepth = 0,
    uAperture = 0.8,
    enabled = false,
})

local normalState = state.NewState({
    name = "normalState",
    onFrame = function(dt) end
})

stateMachine:push(normalState)

local lockSelectionState = state.NewState()
local lockedOnState = state.NewState()
local oneStickTravelState = state.NewState()
local twoStickTravelState = state.NewState()
local preliminaryFreeLookState = state.NewState()
local freeLookState = state.NewState()
local uiState = state.NewState()
local noControlState = state.NewState()

local function getTravelState()
    if inputSettings.val.twoStickMode then
        return twoStickTravelState
    else
        return oneStickTravelState
    end
end

-- lastHit is the last NPC that was struck by the player.
local lastHit = nil

local function onStruck(data)
    --onStruck is called when the player hits some other actor.
    lastHit = data.target
end

local function startLockon(target)
    print("Locking onto " .. target.recordId .. " (" .. target.id .. ")!")
    lockedOnState.base.target = target
    stateMachine:replace(lockedOnState)
end

uiState:set({
    name = "uiState",
    onEnter = function(base)
        clearControls()
        takeControl(false)
    end,
    onExit = function(base)
        takeControl(not inputSettings.val.twoStickMode)
    end,
    onFrame = function(s, dt)
        if uiInterface.getMode() == nil then
            stateMachine:pop()
        end
    end,
    onUpdate = function(s, dt)
    end
})

local function handleControlLoss()
    -- try to not destroy the camera so much
    if (types.Player.getControlSwitch(pself, types.Player.CONTROL_SWITCH.Looking) ~= true) or (types.Player.getControlSwitch(pself, types.Player.CONTROL_SWITCH.Controls) ~= true) then
        if stateMachine:current().name ~= noControlState.name then
            admin.debugPrint("Detected lack of control, stopping one-stick mode.")
            stateMachine:push(noControlState)
        end
    end
end

noControlState:set({
    name = "noControlState",
    onEnter = function(base)
        clearControls()
        controls.overrideMovementControls(false)
    end,
    onExit = function(base)
        controls.overrideMovementControls(true)
    end,
    onFrame = function(s, dt)
    end,
    onUpdate = function(s, dt)
        if (types.Player.getControlSwitch(pself, types.Player.CONTROL_SWITCH.Looking) == true) and (types.Player.getControlSwitch(pself, types.Player.CONTROL_SWITCH.Controls) == true) then
            stateMachine:pop()
        end
    end
})

lockedOnState:set({
    name = "lockedOnState",
    target = nil,
    lookPosition = util.vector3(0, 0, 0),
    pitchMod = nil,
    yawMod = nil,
    lowFatigue = false,
    onEnter = function(base)
        clearControls()
        if inputSettings.val.lockedoncam == "third" then
            base.pitchMod = function(p)
                -- there's a tendency for this to look near-straight-down when in melee.
                return math.min(p + 0.2, 0.7)
            end
            base.yawMod = function(y)
                -- the further away, the less the yaw mod.
                -- the closer, the more.
                -- this is messed up because the camera determines where your cursor is,
                -- not which direction your character is facing. this makes your aim really bad.
                -- Blocked by https://gitlab.com/OpenMW/openmw/-/issues/7684
                --local dist = (pself:getBoundingBox().center - base.lookPosition):length()
                --local yawMod = 1 - util.remap(util.clamp(dist, 200, 1000), 200, 1000, 0, 1)
                --return y + yawMod * (-0.5)
                return y
            end
            base.lowFatigue = false
            setThirdPOVSettings()
            camera.setMode(camera.MODE.ThirdPerson, true)
        elseif inputSettings.val.lockedoncam == "first" then
            camera.setMode(camera.MODE.FirstPerson, true)
            base.pitchMod = nil
            base.yawMod = nil
        else
            error("unknown setting value for travelcam")
        end
        if inWorldSpace(base.target) == false then
            error("no target for locked-on state")
            base.lookPosition = util.vector3(0, 0, 0)
        else
            base.lookPosition = lockOnPosition(base.target)
        end


        if core.sound.isSoundFilePlaying(getSoundFilePath("wind.mp3"), pself) ~= true then
            core.sound.playSoundFile3d(getSoundFilePath("wind.mp3"), pself, {
                volume = inputSettings.val.volume * 0.2,
                loop = true,
            })
        end
    end,
    onExit = function(base)
        boundingBoxSizeCache = {}
        resetCamera()
        clearControls()
        core.sound.playSoundFile3d(getSoundFilePath("cancel.mp3"), pself, {
            volume = inputSettings.val.volume,
        })
        core.sound.stopSoundFile3d(getSoundFilePath("wind.mp3"), pself)
    end,
    onFrame = function(s, dt)
        if keyLock.rise then
            stateMachine:replace(getTravelState())
            return
        end

        -- Why do I have to set this on every frame?
        if inputSettings.val.lockedoncam == "third" then
            setThirdPOVSettings()
        end

        local shouldRun = false
        track(s.base.lookPosition, 0.8, s.base.pitchMod, s.base.yawMod)
        if keyForward.pressed then
            pself.controls.movement = keyForward.analog
            shouldRun = shouldRun or (keyForward.analog > runThreshold)
        elseif keyBackward.pressed then
            pself.controls.movement = -1 * keyBackward.analog
            shouldRun = shouldRun or (keyBackward.analog > runThreshold)
        else
            pself.controls.movement = 0
        end
        if keyLeft.pressed then
            pself.controls.sideMovement = -1 * keyLeft.analog
            shouldRun = shouldRun or (keyLeft.analog > runThreshold)
        elseif keyRight.pressed then
            pself.controls.sideMovement = keyRight.analog
            shouldRun = shouldRun or (keyRight.analog > runThreshold)
        else
            pself.controls.sideMovement = 0
        end

        if s.base.lowFatigue then
            shouldRun = false
        end

        pself.controls.run = shouldRun and dpadSettings.val.runWhileLockedOn
    end,
    onUpdate = function(s, dt)
        if inWorldSpace(s.base.target) == false then
            inputSettings.val.debugPrint("target not valid")
            stateMachine:replace(getTravelState())
            return
        end
        s.base.lookPosition = lockOnPosition(s.base.target)

        s.base.lowFatigue = fatigue.hasLowFatigue(dpadSettings.runMinimumFatigue())
    end
})

local function hasLOS(playerHead, entity)
    local box = entity:getBoundingBox()


    if inBox(playerHead, box) then
        admin.debugPrint("collison: " .. entity.recordId .. " contains playerhead")
        return true
    end

    -- should add anything that the item intersects with to the
    -- ignore list. items clip into tables and weapon racks.
    -- instead of casting from the center of the entity, cast from near the surface of the box
    -- facing the playerHead. this is needed so items on racks don't collide with the wall meshes.
    local fudgeFactor = math.min(30, (playerHead - box.center):length() / 2)

    local startPosition = box.center + (((playerHead - box.center)):normalize() * fudgeFactor)

    local ignoreList = {}
    table.insert(ignoreList, entity)
    for i = 1, 10 do
        local castResult = nearby.castRay(startPosition, playerHead, {
            collisionType = nearby.COLLISION_TYPE.Default,
            ignore = ignoreList
        })
        if castResult.hit == false then
            admin.debugPrint("collison: " .. entity.recordId .. " shot out into space")
            return false
        end
        if (castResult.hitObject ~= nil) and (castResult.hitObject.id == pself.id) then
            return true
        end
        -- if the thing we hit is intersecting with us, then skip it and try again.
        if (castResult.hitPos ~= nil) and inBox(castResult.hitPos, box) then
            admin.debugPrint("inBox(" .. tostring(castResult.hitPos) .. "," .. tostring(entity.recordId) .. ")")
            -- ignore the thing we hit (if it's an object)
            if castResult.hitObject ~= nil then
                table.insert(ignoreList, castResult.hitObject)
            end
            -- also advance the start position (in the case of world or heightmap)
            startPosition = castResult.hitPos
        else
            if castResult.hitObject ~= nil then
                admin.debugPrint("collison: " .. entity.recordId .. " stopped by " .. castResult.hitObject.recordId)
            else
                admin.debugPrint("collison: " .. entity.recordId .. " stopped by something")
            end

            return false
        end
    end
    admin.debugPrint("collison: " .. entity.recordId .. " gave up")
    return false
end

local function getDistance(playerHead, entity)
    -- dist is a little closer because activation distance should be based
    -- on the closest face of the box, not on the center of the box.
    -- just fudge it by taking max of x,y,z box halfsize.
    local boxSize = entity:getBoundingBox().halfSize
    return (playerHead - entity:getBoundingBox().center):length() -
        math.max(boxSize.x, boxSize.y, boxSize.z)
end

lockSelectionState:set({
    name = "lockSelectionState",
    selectingActors = true,
    currentTarget = nil,
    actors = {},
    others = {},
    onEnter = function(base)
        admin.debugPrint("enter state: lockselection")
        clearControls()
        takeControl(true)
        resetCamera()
        core.sendGlobalEvent(MOD_NAME .. "onPause")
        uiInterface.setHudVisibility(false)
        controls.overrideUiControls(true)
        camera.setMode(camera.MODE.FirstPerson, true)

        local playerHead = pself:getBoundingBox().center + util.vector3(0, 0, 0.9 * (pself:getBoundingBox().halfSize.z))


        base.actors = targets.TargetCollection:new(nearby.actors,
            function(e)
                --admin.debugPrint("Filtering actor " .. e.recordId .. " (" .. e.id .. ")....")
                if e:isValid() == false then
                    return false
                end
                if types.Actor.isDead(e) then
                    return false
                end
                if e.id == pself.id then
                    return false
                end
                if e.type.records[e.recordId].name == "" then
                    -- only instances with names can be targetted
                    return false
                end

                -- dist is a little closer because activation distance should be based
                -- on the closest face of the box, not on the center of the box.
                -- just fudge it by taking max of x,y,z box halfsize.
                local dist = getDistance(playerHead, e)
                -- if the actor is very close, ignore LOS check.
                -- we were getting problems with mudcrabs (horrible creatures).
                if dist <= core.getGMST("iMaxActivateDist") * 0.75 then
                    return true
                end

                -- max distance
                if (dist >= 1000) then
                    return false
                end

                -- reduce max distance to activation distance if we don't have hands out
                if (dist >= core.getGMST("iMaxActivateDist")) and (types.Actor.getStance(pself) == types.Actor.STANCE.Nothing) then
                    return false
                end

                return hasLOS(playerHead, e)
            end)

        local others = {}
        for _, e in ipairs(nearby.activators) do
            table.insert(others, e)
        end
        for _, e in ipairs(nearby.actors) do
            table.insert(others, e)
        end
        for _, e in ipairs(nearby.items) do
            table.insert(others, e)
        end
        for _, e in ipairs(nearby.doors) do
            table.insert(others, e)
        end
        for _, e in ipairs(nearby.containers) do
            table.insert(others, e)
        end

        local reach = getReach()

        base.others = targets.TargetCollection:new(others,
            function(e)
                --admin.debugPrint("Filtering non-actor " .. e.recordId .. " (" .. e.id .. ")....")
                if e:isValid() == false then
                    return false
                end
                if e.id == pself.id then
                    return false
                end
                if e.type.records[e.recordId].name == "" then
                    -- only instances with names can be targetted
                    return false
                end
                -- only dead actors allowed
                if isActor(e) and (types.Actor.isDead(e) == false) then
                    return false
                end

                if getDistance(playerHead, e) > reach then
                    return false
                end

                -- ignore picked plants
                if types.Container.objectIsInstance(e) then
                    local containerRecord = types.Container.record(e)
                    local inventory = types.Container.inventory(e)
                    if inventory:isResolved() and containerRecord.isOrganic then
                        if #inventory:getAll() == 0 then
                            admin.debugPrint("Filtering picked plant " .. tostring(containerRecord.name))
                            return false
                        end
                    end
                end
                return hasLOS(playerHead, e)
            end)

        base.currentTarget = base.actors:next()
        base.selectingActors = true
        if base.currentTarget == nil then
            base.currentTarget = base.others:next()
            base.selectingActors = false
        end
        if base.currentTarget == nil then
            admin.debugPrint("no valid targets!")
            -- we will exit this state on next frame.
        else
            admin.debugPrint("Started looking at " ..
                base.currentTarget.recordId .. " (" .. base.currentTarget.id .. ").")
            hexDofShader.enabled = true
            core.sound.playSoundFile3d(getSoundFilePath("wind.mp3"), pself, {
                volume = inputSettings.val.volume * 0.2,
                loop = true,
            })
            targetui.showTargetUI(base.currentTarget)
        end

        core.sound.playSoundFile3d(getSoundFilePath("breath_in.mp3"), pself, {
            volume = inputSettings.val.volume,
        })
    end,
    onExit = function(base)
        core.sendGlobalEvent(MOD_NAME .. "onUnpause")
        uiInterface.setHudVisibility(true)
        controls.overrideUiControls(false)
        pself.controls.yawChange = 0
        pself.controls.pitchChange = 0
        resetCamera()

        --core.sound.stopSoundFile3d(getSoundFilePath("wind.mp3"), pself)

        hexDofShader.enabled = false
        targetui.destroy()
    end,
    onFrame = function(s, dt)
        if keyLock.rise then
            if s.base.currentTarget then
                -- we selected a target
                startLockon(s.base.currentTarget)
            else
                print("No target on keyLock rise, quitting.")
                -- no target, so move to travel state.
                core.sound.stopSoundFile3d(getSoundFilePath("wind.mp3"), pself)
                stateMachine:replace(getTravelState())
            end
            return
        end

        local newTarget = function(new)
            if (new ~= nil) and (new ~= s.base.currentTarget) then
                s.base.currentTarget = new
                admin.debugPrint("Looking at " ..
                    s.base.currentTarget.recordId .. " (" .. s.base.currentTarget.id .. ").")

                targetui.showTargetUI(s.base.currentTarget)
                core.sound.playSoundFile3d(getSoundFilePath("ping.mp3"), pself, {
                    volume = inputSettings.val.volume,
                })
            end
        end

        -- up/down cycles actors
        -- left/right cycles everything else
        if keyForward.rise then
            s.base.selectingActors = true
            newTarget(s.base.actors:next())
        elseif keyBackward.rise then
            s.base.selectingActors = true
            newTarget(s.base.actors:previous())
        elseif keyLeft.rise then
            s.base.selectingActors = false
            newTarget(s.base.others:previous())
        elseif keyRight.rise then
            s.base.selectingActors = false
            newTarget(s.base.others:next())
        elseif inWorldSpace(s.base.currentTarget) == false then
            --admin.debugPrint("Current target (" ..
            --    aux_util.deepToString(s.base.currentTarget, 2) .. ") is no longer valid. Finding a new one...")
            -- we didn't change our target, but our current target is no longer valid.
            -- try jumping to the next one.
            if s.base.selectingActors then
                newTarget(s.base.actors:next())
                -- no more actors, so swap to non-actors.
                if s.base.currentTarget == nil then
                    newTarget(s.base.others:next())
                    s.base.selectingActors = false
                end
            else
                newTarget(s.base.others:next())
                if s.base.currentTarget == nil then
                    -- no more non-actors, so swap to actors.
                    newTarget(s.base.actors:next())
                    s.base.selectingActors = true
                end
            end
        end

        if inWorldSpace(s.base.currentTarget) == false then
            -- we have no valid targets at all.
            core.sound.playSoundFile3d(getSoundFilePath("cancel.mp3"), pself, {
                volume = inputSettings.val.volume,
            })
            core.sound.stopSoundFile3d(getSoundFilePath("wind.mp3"), pself)
            print("No valid target....")
            stateMachine:replace(getTravelState())
            return
        end

        -- point camera to the active target.
        local lockPosition = lockOnPosition(s.base.currentTarget)
        look(lockPosition, 0.3)
        hexDofShader.u.uDepth = (lockPosition - camera.getPosition()):length()

        -- check if we are activating the target.
        -- this will always stop target selection mode.
        if activating then
            core.sound.stopSoundFile3d(getSoundFilePath("wind.mp3"), pself)

            if isActor(s.base.currentTarget) and (getDistance(camera.getPosition(), s.base.currentTarget) > core.getGMST("iMaxActivateDist")) then
                admin.debugPrint("Actor target is too far away to activate.")
                core.sound.playSoundFile3d(getSoundFilePath("cancel.mp3"), pself, {
                    volume = inputSettings.val.volume,
                })
            else
                -- activation doesn't work while paused!
                -- so we need to drop out of this state and into a non-paused state.
                core.sound.stopSoundFile3d(getSoundFilePath("wind.mp3"), pself)
                core.sendGlobalEvent(MOD_NAME .. "onActivate", {
                    entity = s.base.currentTarget,
                    player = pself,
                })
            end
            stateMachine:replace(getTravelState())
        end
    end,
    onUpdate = function(s, dt)
    end
})

local objectsAffectingPitch = {
    ["In_prison_ship"] = true,
    ["chargen_plank"] = true,
    ["ex_common_plat_end"] = true,
    ["ex_de_docks_steps_01"] = true,
}

local function objectAffectsDynamicPitch(entity)
    if entity == nil then
        --admin.debugPrint("pitch: hit nil")
        return true
    end
    if entity.type ~= types.Static then
        --admin.debugPrint("pitch: hit non-static " .. entity.recordId)
        return false
    end
    if objectsAffectingPitch[entity.recordId] then
        --admin.debugPrint("pitch: hit force-listed " .. entity.recordId)
        return true
    end
    -- only pitch for high-volume objects (like stairs and buildings)
    local boxLengths = entity:getBoundingBox().halfSize * 2
    local volume = boxLengths.x * boxLengths.y * boxLengths.z

    local affects = volume > 1500000
    --admin.debugPrint("pitch: hit static item " .. entity.recordId .. " - " ..
    --        tostring(affects))
    return affects
end

twoStickTravelState:set({
    name = "twoStickTravelState",
    onEnter = function(base)
        clearControls()
        takeControl(false)
    end,
    onExit = function(base)
        takeControl(true)
    end,
    onFrame = function(s, dt)
        if keyLock.rise and types.Actor.canMove(pself) then
            stateMachine:replace(lockSelectionState)
            return
        end
    end,
    onUpdate = function(s, dt)
    end
})

oneStickTravelState:set({
    name = "oneStickTravelState",
    desiredPitch = 0,
    updateCounter = 0,
    onGround = false,
    lowFatigue = false,
    alwaysRun = false,
    pitchMod = nil,
    onEnter = function(base)
        if inputSettings.val.travelcam == "third" then
            camera.setMode(camera.MODE.ThirdPerson, true)
            setThirdPOVSettings()
            base.pitchMod = function(p) return p + 0.3 end
        elseif inputSettings.val.travelcam == "first" then
            camera.setMode(camera.MODE.FirstPerson, true)
            base.pitchMod = nil
        else
            error("unknown setting value for travelcam: " .. tostring(inputSettings.val.travelcam))
        end
        clearControls()
        base.onGround = types.Actor.isOnGround(pself)
        base.lowFatigue = false
    end,
    onExit = function(base)
        pself.controls.movement = 0
        pself.controls.run = false
        pself.controls.yawChange = 0
        pself.controls.pitchChange = 0
    end,
    onFrame = function(s, dt)
        if keyLock.rise and types.Actor.canMove(pself) then
            stateMachine:replace(preliminaryFreeLookState)
            return
        end

        if inputSettings.val.autoLockon and lastHit ~= nil then
            core.sound.playSoundFile3d(getSoundFilePath("breath_in.mp3"), pself, {
                volume = inputSettings.val.volume,
            })
            startLockon(lastHit)
        end

        -- Why do I have to set this on every frame?
        if inputSettings.val.travelcam == "third" then
            setThirdPOVSettings()
        end

        pself.controls.sideMovement = 0
        -- Reset camera to foward if we are on the ground.
        -- Don't do this when swimming or levitating so the player
        -- can point up or down.
        if s.base.onGround then
            trackPitch(s.base.desiredPitch, 0.1, s.base.pitchMod)
        else
            pself.controls.pitchChange = 0
        end

        if keyForward.pressed then
            pself.controls.movement = keyForward.analog
            pself.controls.run = s.base.alwaysRun or ((keyForward.analog > runThreshold) and (s.base.lowFatigue ~= true))
        elseif keyBackward.pressed then
            pself.controls.movement = -1 * keyBackward.analog
            pself.controls.run = s.base.alwaysRun or
                ((keyBackward.analog > runThreshold) and (s.base.lowFatigue ~= true))
        else
            pself.controls.movement = 0
            pself.controls.run = false
        end
        if keyLeft.pressed then
            pself.controls.yawChange = keyLeft.analog * inputSettings.val.lookSensitivityHorizontal * (-1 * dt)
        elseif keyRight.pressed then
            pself.controls.yawChange = keyRight.analog * inputSettings.val.lookSensitivityHorizontal * dt
        else
            pself.controls.yawChange = 0
        end
    end,
    onUpdate = function(s, dt)
        s.base.onGround = types.Actor.isOnGround(pself)
        if s.base.onGround == false then
            return
        end

        s.base.lowFatigue = fatigue.hasLowFatigue(dpadSettings.runMinimumFatigue())
        s.base.alwaysRun = dpadSettings.val.runWhenReadied and
            (types.Actor.getStance(pself) ~= types.Actor.STANCE.Nothing)

        if inputSettings.val.dynamicPitch == false then
            s.base.desiredPitch = 0
            return
        end
        -- this is really expensive, so don't do it on every update.
        s.base.updateCounter = s.base.updateCounter + dt
        if s.base.updateCounter < 0.1 then
            return
        else
            s.base.updateCounter = 0
        end

        local zHalfHeight = pself:getBoundingBox().halfSize.z
        -- positive Z is up.

        local facing = pself.rotation:apply(util.vector3(0, 1, 0))
        facing = util.vector3(facing.x, facing.y, 0):normalize()
        local leadingPosition = camera.getTrackedPosition() + (facing * 100)

        local downward = util.vector3(leadingPosition.x, leadingPosition.y,
            leadingPosition.z - (10 * zHalfHeight))
        -- cast down from leading position to ground.
        local castResult = nearby.castRay(leadingPosition,
            downward,
            {
                -- We need World to see stairs, but this also triggers on tables (which is bad).
                -- This doesn't hit docks or boats, though, so on those we stare down if the
                -- bottom of the water is close enough. Can't win them all, I guess.
                collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World +
                    nearby.COLLISION_TYPE.Water,
                radius = 2
            }
        )

        -- if we get a hit, do a second hit further ahead.
        --[[if castResult.hit and objectAffectsDynamicPitch(castResult.hitObject) then
            local leadingPosition = camera.getTrackedPosition() + (facing * 1.8 * pself:getBoundingBox().halfSize.y)

            local downward = util.vector3(leadingPosition.x, leadingPosition.y,
                leadingPosition.z - (10 * zHalfHeight))
        end]]


        if castResult.hit and objectAffectsDynamicPitch(castResult.hitObject) then
            --admin.debugPrint("pzed: " ..
            --                string.format("%.3f", pself.position.z) .. ", hitzed: " .. string.format("%.3f", castResult.hitPos.z))

            -- we hit the ground.
            -- I don't want the z-length between the camera and the hitposition.
            -- I want the difference between the hit position and the leading position.
            local opposite = (camera.getTrackedPosition().z - castResult.hitPos.z) -
                (camera.getTrackedPosition().z - pself.position.z)
            local adjacentLength = (util.vector2(castResult.hitPos.x, castResult.hitPos.y) -
                util.vector2(camera.getTrackedPosition().x, camera.getTrackedPosition().y)):length()

            local pitch = util.normalizeAngle(math.atan2(opposite, adjacentLength))

            local targetPitch = pitch

            -- clamp this so we never look straight up or straight down.
            local maxPitchCorrection = 0.4
            local upDown = -1
            if targetPitch > 0 then
                targetPitch = math.min(maxPitchCorrection, targetPitch)
                upDown = 1
            else
                targetPitch = math.max(-1 * maxPitchCorrection, targetPitch)
                upDown = -1
            end

            -- Make a deadzone around 0
            local minPitch = 0.07
            if targetPitch > minPitch then
                targetPitch = targetPitch - minPitch
            elseif targetPitch < -1 * minPitch then
                targetPitch = targetPitch + minPitch
            end

            -- swingToMax is the linear progress of zero pitch to max pitch
            local swingToMax = math.abs(targetPitch) / maxPitchCorrection
            -- when stuck on ground, heightoffset is only 72.
            --[[admin.debugPrint("swing:" ..
                string.format("%.3f", swingToMax) ..
                " raw:" ..
                string.format("%.3f", rawTarget) ..
                " heightoffset:" .. string.format("%.3f", camera.getFirstPersonOffset().z + (2 * zHalfHeight)))
                ]]
            -- this is 0
            --admin.debugPrint("camera.getFirstPersonOffset().z: " ..
            -- string.format("%.3f", camera.getFirstPersonOffset().z))
            --admin.debugPrint("campos-pselfpos: " .. tostring(camera.getPosition() - pself.position))

            s.base.desiredPitch = easeInOutSine(swingToMax) * maxPitchCorrection * upDown
        else
            -- we didn't hit anything, so look straight ahead.
            s.base.desiredPitch = 0
        end

        --[[admin.debugPrint("pself:" ..
            string.format("%.3f", pself.rotation:getPitch()) ..
            " camera:" ..
            string.format("%.3f", camera.getPitch()) .. " desired:" ..
            string.format("%.3f", s.base.desiredPitch))
            ]]
    end
})

preliminaryFreeLookState:set({
    name = "preliminaryFreeLookState",
    initialMode = nil,
    initialFOV = nil,
    timeInState = 0,
    onEnter = function(base)
        base.initialMode = camera.getMode()
        base.initialFOV = camera.getFieldOfView()
        camera.setFieldOfView(base.initialFOV / inputSettings.val.freeLookZoom)
        camera.setMode(camera.MODE.FirstPerson, true)
        base.timeInState = 0
        clearControls()
        --admin.debugPrint(base.name .. ".OnEnter() = " .. aux_util.deepToString(base, 3))
    end,
    onFrame = function(s, dt)
        --admin.debugPrint(s.name .. ".OnFrame() = " .. aux_util.deepToString(s.base, 3))
        if types.Actor.canMove(pself) == false then
            stateMachine:replace(getTravelState())
        end

        if keyLock.fall then
            stateMachine:replace(lockSelectionState)
        elseif keyLock.pressed == false then
            -- it's possible that we miss the "fall" frame because we opened an inventory.
            stateMachine:replace(getTravelState())
        end

        -- we started looking around
        if (keyForward.rise or keyBackward.rise or keyLeft.rise or keyRight.rise) then
            stateMachine:replace(freeLookState)
        end
        -- if we're spending too long in this state, just go to freelook.
        s.base.timeInState = s.base.timeInState + dt
        if s.base.timeInState > 0.2 then
            admin.debugPrint("held lock for too long (" .. tostring(s.base.timeInState) .. "s), entering freelook")
            stateMachine:replace(freeLookState)
        end
    end,
    onExit = function(base)
        camera.setMode(base.initialMode, true)
        camera.setFieldOfView(base.initialFOV)
    end,
    onUpdate = function(s, dt)
    end
})

freeLookState:set({
    name = "freeLookState",
    initialMode = nil,
    initialFOV = nil,
    onEnter = function(base)
        takeControl(true)
        -- this is not resetting base.looking
        base.initialMode = camera.getMode()
        base.initialFOV = camera.getFieldOfView()
        clearControls()

        resetCamera()

        camera.setFieldOfView(base.initialFOV / inputSettings.val.freeLookZoom)
        camera.setMode(camera.MODE.FirstPerson, true)
    end,
    onExit = function(base)
        camera.setMode(base.initialMode, true)
        camera.setFieldOfView(base.initialFOV)
        pself.controls.yawChange = 0
        pself.controls.pitchChange = 0
    end,
    onFrame = function(s, dt)
        if keyLock.fall then
            stateMachine:replace(getTravelState())
            return
        end

        if inputSettings.val.autoLockon and lastHit ~= nil then
            core.sound.playSoundFile3d(getSoundFilePath("breath_in.mp3"), pself, {
                volume = inputSettings.val.volume,
            })
            startLockon(lastHit)
        end

        if keyForward.pressed then
            pself.controls.pitchChange = keyForward.analog * inputSettings.val.lookSensitivityVertical * (-1 * dt) *
                invertLook
        elseif keyBackward.pressed then
            pself.controls.pitchChange = keyBackward.analog * inputSettings.val.lookSensitivityVertical * dt * invertLook
        else
            pself.controls.pitchChange = 0
        end
        if keyLeft.pressed then
            pself.controls.yawChange = keyLeft.analog * inputSettings.val.lookSensitivityHorizontal * (-1 * dt)
        elseif keyRight.pressed then
            pself.controls.yawChange = keyRight.analog * inputSettings.val.lookSensitivityHorizontal * dt
        else
            pself.controls.yawChange = 0
        end
    end,
    onUpdate = function(s, dt)
    end
})

stateMachine:push(getTravelState())

local function onFrame(dt)
    keyLock:update(dt)
    keyForward:update(dt)
    keyBackward:update(dt)
    keyLeft:update(dt)
    keyRight:update(dt)
    handleSneak(dt)

    handleControlLoss()

    local currentState = stateMachine:current()
    currentState.onFrame(currentState, dt)

    -- triggers should be disabled after state handling, since they are once per frame.
    handleActivate(dt)

    -- lastHit must be cleaned up so it is only set once per frame.
    lastHit = nil

    unitoggle.onFrame(dt)
end

local function onUpdate(dt)
    if dt == 0 then return end
    if inputSettings.val.enableShaders then
        shaderUtils.HandleShaders(dt)
    end

    local currentState = stateMachine:current()
    currentState.onUpdate(currentState, dt)
end

local function UiModeChanged(data)
    if (data.newMode ~= nil) and (data.oldMode == nil) then
        stateMachine:push(uiState)
    end
end

local function onSettingsChange(data)
    print("Settings change. Reloading.")
    stateMachine:replace(stateMachine:current())
end

inputSettings.val.subscribe(onSettingsChange)
dpadSettings.val.subscribe(onSettingsChange)


return {
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        [MOD_NAME .. 'onStruck'] = onStruck,
    },
    engineHandlers = {
        onFrame = onFrame,
        onUpdate = onUpdate
    }
}
