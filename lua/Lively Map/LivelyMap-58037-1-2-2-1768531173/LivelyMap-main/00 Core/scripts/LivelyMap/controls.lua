--[[
LivelyMap for OpenMW.
Copyright (C) Erin Pentecost 2025

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
local MOD_NAME    = require("scripts.LivelyMap.ns")
local mutil       = require("scripts.LivelyMap.mutil")
local putil       = require("scripts.LivelyMap.putil")
local core        = require("openmw.core")
local util        = require("openmw.util")
local pself       = require("openmw.self")
local aux_util    = require('openmw_aux.util')
local camera      = require("openmw.camera")
local ui          = require("openmw.ui")
local settings    = require("scripts.LivelyMap.settings")
local async       = require("openmw.async")
local types       = require("openmw.types")
local interfaces  = require('openmw.interfaces')
local storage     = require('openmw.storage')
local input       = require('openmw.input')
local heightData  = storage.globalSection(MOD_NAME .. "_heightData")
local keytrack    = require("scripts.LivelyMap.keytrack")
local uiInterface = require("openmw.interfaces").UI


local controls        = require('openmw.interfaces').Controls
local cameraInterface = require("openmw.interfaces").Camera

local defaultHeight   = 200
local defaultPitch    = 1
local minCameraHeight = 100
local maxCameraHeight = 600

local stickDeadzone   = 0.3

local settingCache    = {
    controllerButtons = settings.controls.controllerButtons,
}
settings.controls.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.controls[key]
end))

-- Track inputs we need for navigating the map.
local keys = {
    forward         = keytrack.NewKey("forward", function(dt)
        return input.isKeyPressed(input.KEY.UpArrow) or
            (settingCache.controllerButtons and input.getAxisValue(input.CONTROLLER_AXIS.RightY) < -1 * stickDeadzone)
    end),
    backward        = keytrack.NewKey("backward", function(dt)
        return input.isKeyPressed(input.KEY.DownArrow) or
            (settingCache.controllerButtons and input.getAxisValue(input.CONTROLLER_AXIS.RightY) > stickDeadzone)
    end),
    left            = keytrack.NewKey("left", function(dt)
        return input.isKeyPressed(input.KEY.LeftArrow) or
            (settingCache.controllerButtons and input.getAxisValue(input.CONTROLLER_AXIS.RightX) < -1 * stickDeadzone)
    end),
    right           = keytrack.NewKey("right", function(dt)
        return input.isKeyPressed(input.KEY.RightArrow) or
            (settingCache.controllerButtons and input.getAxisValue(input.CONTROLLER_AXIS.RightX) > stickDeadzone)
    end),

    zoomIn          = keytrack.NewKey("zoomIn", function(dt)
        return input.isKeyPressed(input.KEY.Equals) or
            input.isKeyPressed(input.KEY.NP_Plus) or
            (settingCache.controllerButtons and input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown))
    end),
    zoomOut         = keytrack.NewKey("zoomOut", function(dt)
        return input.isKeyPressed(input.KEY.Equals) or
            input.isKeyPressed(input.KEY.NP_Plus) or
            (settingCache.controllerButtons and input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp))
    end),

    statsWindow     = keytrack.NewKey("statsWindow", function(dt)
        return settingCache.controllerButtons and
            input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > stickDeadzone
    end),
    inventoryWindow = keytrack.NewKey("inventoryWindow", function(dt)
        return settingCache.controllerButtons and
            input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > stickDeadzone
    end),
}

-- Reset inputs so they don't get stuck.
local function clearControls()
    pself.controls.sideMovement = 0
    pself.controls.movement = 0
    pself.controls.yawChange = 0
    pself.controls.pitchChange = 0
    pself.controls.run = false
end

---@class ControlSwitches
---@field [any] any

---@return ControlSwitches
local function currentControlSwitches()
    local out = {}
    for _, v in pairs(pself.type.CONTROL_SWITCH) do
        out[v] = pself.type.getControlSwitch(pself, v)
    end
    print("Saved control switches: " .. aux_util.deepToString(out, 4))
    return out
end

---@param switches ControlSwitches
local function applyControlSwitches(switches)
    if switches then
        print("Applying control switches: " .. aux_util.deepToString(switches, 4))
        for k, v in pairs(switches) do
            pself.type.setControlSwitch(pself, k, v)
        end
    else
        print("No saved control switches.")
    end
end

local function disableControlSwitches()
    for _, v in pairs(pself.type.CONTROL_SWITCH) do
        pself.type.setControlSwitch(pself, v, false)
    end
end

---@class Rotation
---@field z number
---@field y number
---@field x number

---@class CameraData
---@field pitch number?
---@field yaw number?
---@field roll number?
---@field position util.vector3?
---@field relativePosition util.vector3?
---@field mode any
---@field force boolean? Ignore validation!
---@field controlSwitches any? Used during restore only.
---@field playerRotation Rotation? Used during restore only.

---@type MeshAnnotatedMapData?
local currentMapData = nil

---@return CameraData
local function currentCameraData()
    return {
        pitch = camera.getPitch(),
        yaw = camera.getYaw(),
        position = camera.getPosition(),
        roll = camera.getRoll(),
        mode = camera.getMode(),
        force = false,
    }
end

---Applies data changes to the actual camera.
---@param data CameraData
local function setCamera(data)
    print("setCamera: "..aux_util.deepToString(data, 4))
    camera.setMode(data.mode, true)
    camera.setPitch(data.pitch)
    camera.setYaw(data.yaw)
    camera.setRoll(data.roll)
end

-- Store old camera state so we can reset to that same state
-- once we exit the map.
-- Then set the initial camera state we need.
---@type CameraData?
local originalCameraState = nil
local function startCamera()
    print("Assuming control.")
    cameraInterface.disableModeControl(MOD_NAME)
    uiInterface.setHudVisibility(false)
    clearControls()
    if originalCameraState == nil then
        -- Don't override the old state.
        -- this might be called multiple times before
        -- endCamera() is called.
        originalCameraState = currentCameraData()
        originalCameraState.controlSwitches = currentControlSwitches()
        if originalCameraState.mode == camera.MODE.Static then
            originalCameraState.mode = camera.MODE.ThirdPerson
        end

        local z, y, x = pself.rotation:getAnglesZYX()
        originalCameraState.playerRotation = {
            z= z,
            y= y,
            x= x,
        }
        print("Saved original camera state: " .. aux_util.deepToString(originalCameraState, 4))
    end
    disableControlSwitches()
    camera.setMode(camera.MODE.Static, true)
    camera.setYaw(0)
    -- player position gets completely messed up
    -- when we swap to static camera. we need to reset it.
    core.sendGlobalEvent(MOD_NAME .. "onRotate", {object=pself, rotation=originalCameraState.playerRotation})
end

--- Restore the camera back to original state.
local function endCamera()
    print("Ending control.")
    cameraInterface.enableModeControl(MOD_NAME)
    uiInterface.setHudVisibility(true)
    clearControls()
    if originalCameraState then
        print("Restoring camera state: " .. aux_util.deepToString(originalCameraState, 4))
        setCamera(originalCameraState)
        applyControlSwitches(originalCameraState.controlSwitches)
    else
        print("No camera state to restore!")
    end
    originalCameraState = nil
end

local function facing2D(camViewVector)
    local viewDir = camViewVector or camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    return util.vector3(viewDir.x, viewDir.y, 0):normalize()
end


---@class ScreenHit
---@field hitMap boolean Whether this corner collided with the map mesh or not.
---@field normalizedScreenPosition util.vector2 The normalized screen position for this corner.
---@field worldSpace util.vector3? The world space coordinate where the ray collided with a plane that is coplanar to the map mesh.

---@class ScreenHits
---@field bottomLeft ScreenHit
---@field bottomRight ScreenHit
---@field topLeft ScreenHit
---@field topRight ScreenHit

---@param data ScreenHits
---@return number
local function screenPositionsValid(data)
    local count = 4
    for _, pos in pairs(data) do
        if not pos.hitMap then
            count = count - 1
        end
    end
    return count
end

---@return ScreenHits
local function getScreenPositions()
    ---@type ScreenHits
    local out = {
        topLeft = {
            hitMap = false,
            normalizedScreenPosition = util.vector2(0, 0),
        },
        topRight = {
            hitMap = false,
            normalizedScreenPosition = util.vector2(1, 0),
        },
        bottomLeft = {
            hitMap = false,
            normalizedScreenPosition = util.vector2(0, 1),
        },
        bottomRight = {
            hitMap = false,
            normalizedScreenPosition = util.vector2(1, 1),
        },
    }


    local bounds = currentMapData ~= nil and currentMapData.safeBounds
    if not bounds then
        return out
    end

    -- Extract rectangle extents
    local minX = bounds.bottomLeft.x
    local maxX = bounds.bottomRight.x
    local minY = bounds.bottomLeft.y
    local maxY = bounds.topLeft.y
    local planeZ = bounds.bottomLeft.z

    --print("bounds: " .. aux_util.deepToString(bounds, 3))

    local camPos = camera.getPosition()

    -- Camera must be above the map plane
    if camPos.z <= planeZ then
        return out
    end

    for k, screenPos in pairs(out) do
        local dir = camera.viewportToWorldVector(screenPos.normalizedScreenPosition):normalize()

        -- Ray must intersect the plane
        if math.abs(dir.z) < 1e-6 then
            --[[print("no intersection for screenPos " ..
                aux_util.deepToString(screenPos, 3) ..
                ", dir: " .. tostring(dir) .. ", camerapos: " .. tostring(camera.getPosition()))]]
            goto continue
        end

        local t = (planeZ - camPos.z) / dir.z

        -- Intersection must be in front of camera
        if t <= 0 then
            --[[print("intersection behind camera for screenPos " ..
                aux_util.deepToString(screenPos, 3) ..
                ", dir: " .. tostring(dir) .. ", camerapos: " .. tostring(camera.getPosition()) ..
                ", t: " .. tostring(t))]]
            goto continue
        end

        out[k].worldSpace = camPos + dir * t

        -- 2D bounds containment
        if out[k].worldSpace.x < minX or out[k].worldSpace.x > maxX
            or out[k].worldSpace.y < minY or out[k].worldSpace.y > maxY then
            --[[print("intersection beyond bounds for screenpos " ..
                aux_util.deepToString(screenPos, 3) ..
                ", dir: " ..
                tostring(dir) ..
                ", camerapos: " ..
                tostring(camera.getPosition()) .. ", t: " .. tostring(t) .. ", hit:" .. tostring(out[k].worldSpace))]]
            goto continue
        end

        -- this point is in the mesh
        out[k].hitMap = true
        :: continue ::
    end

    return out
end



---@class MoveResult
---@field success boolean  Indicates that the camera moved to the destination.
---@field northCollision boolean?
---@field southCollision boolean?
---@field westCollision boolean?
---@field eastCollision boolean?

---comment
---@param a MoveResult
---@param b MoveResult?
---@return MoveResult
local function mergeMoveResult(a, b)
    if b == nil then
        return a
    end
    a.success = a.success and b.success
    a.northCollision = a.northCollision and b.northCollision
    a.southCollision = a.southCollision and b.southCollision
    a.westCollision = a.westCollision and b.westCollision
    a.eastCollision = a.eastCollision and b.eastCollision

    return a
end

---@param res MoveResult
local function handleCollision(res)
    if currentMapData == nil then
        return
    end
    local swapWith = function(id)
        local newMap = mutil.getMap(id)
        if newMap == nil then
            error("no data for map " .. id)
            return
        end

        local newMapCenter = putil.cellPosToRelativeMeshPos(currentMapData,
            util.vector3(newMap.CenterX, newMap.CenterY, 0), true)

        if not newMapCenter then
            print("can't find relative position of " .. tostring(newMap.ID) .. " in current map")
            return
        end

        local absNewMapCenter = putil.relativeMeshPosToAbsoluteMeshPos(currentMapData, newMapCenter)

        --- absNewMapCenter works great when there's sufficient overlap between the current tile and new tile.
        --- But when there's basically no overlap, the camera is not really looking at anything.
        --- This causes a lot of instability. So I need to slide the map tile over more so it's in view.
        --- This will cause any current tracking to be offset, so I also need to cancel tracking.

        local showData = mutil.shallowMerge(newMap, {
            cellID = pself.cell.id,
            player = pself,
            mapPosition = absNewMapCenter,
        })
        core.sendGlobalEvent(MOD_NAME .. "onShowMap", showData)
    end
    if res.eastCollision and currentMapData.ConnectedTo.east then
        swapWith(currentMapData.ConnectedTo.east)
    elseif res.northCollision and currentMapData.ConnectedTo.north then
        swapWith(currentMapData.ConnectedTo.north)
    elseif res.southCollision and currentMapData.ConnectedTo.south then
        swapWith(currentMapData.ConnectedTo.south)
    elseif res.westCollision and currentMapData.ConnectedTo.west then
        swapWith(currentMapData.ConnectedTo.west)
    end
end

--- moveCamera safely moves the camera within acceptable bounds.
--- Once we move the camera, we won't be able to reliable read
--- from it for the rest of the frame.
---@param data CameraData?
---@return MoveResult
local function moveCamera(data)
    ---@type MoveResult
    local out = { success = true }

    if data == nil then
        error("moveCamera: nil data!!")
        out.success = false
        return out
    end

    local currentPosition = camera.getPosition()
    --- newPos replaces data.position or data.relativePosition.
    --- This is done because we might specify a relative position
    --- instead of an absolute position for the camera.
    ---@type util.vector3
    local newPos = currentPosition
    if data.position or data.relativePosition then
        newPos = data.position or (currentPosition + data.relativePosition)
    end

    if not data.force then
        local screenPositions = getScreenPositions()
        local validPositions = screenPositionsValid(screenPositions)


        -- clamp camera height
        if currentMapData and (newPos.z ~= currentPosition.z) then
            local relativeZ = util.clamp(newPos.z - currentMapData.object.position.z, minCameraHeight, maxCameraHeight)
            newPos = util.vector3(newPos.x, newPos.y, relativeZ + currentMapData.object.position.z)
        end

        if validPositions ~= 4 then
            --print("Map collision failure.")
            -- Forbid zooming out on any collision.
            if newPos.z > currentPosition.z then
                newPos = util.vector3(newPos.x, newPos.y, currentPosition.z)
            end

            if (not screenPositions.topLeft.hitMap) and (not screenPositions.topRight.hitMap) then
                -- we are too far up.
                if currentPosition.y <= newPos.y then
                    newPos = util.vector3(newPos.x, currentPosition.y, currentPosition.z)
                    out.success = false
                    out.northCollision = true
                end
            end
            if (not screenPositions.bottomLeft.hitMap) and (not screenPositions.bottomRight.hitMap) then
                -- we are too far down.
                if currentPosition.y >= newPos.y then
                    newPos = util.vector3(newPos.x, currentPosition.y, currentPosition.z)
                    out.success = false
                    out.southCollision = true
                end
            end
            if (not screenPositions.topLeft.hitMap) and (not screenPositions.bottomLeft.hitMap) then
                -- we are too far to the left
                if currentPosition.x >= newPos.x then
                    newPos = util.vector3(currentPosition.x, newPos.y, currentPosition.z)
                    out.success = false
                    out.westCollision = true
                end
            end
            if (not screenPositions.topRight.hitMap) and (not screenPositions.bottomRight.hitMap) then
                -- we are too far to the right
                if currentPosition.x <= newPos.x then
                    newPos = util.vector3(currentPosition.x, newPos.y, currentPosition.z)
                    out.success = false
                    out.eastCollision = true
                end
            end
        end
    end


    if data.pitch then
        camera.setPitch(util.clamp(data.pitch, 0.9, 1.1))
    end
    if data.yaw then
        camera.setYaw(util.clamp(data.yaw, 0.785, 1.4))
    end

    if newPos then
        camera.setStaticPosition(newPos)
    end

    handleCollision(out)

    --print("moveCamera(" .. aux_util.deepToString(data, 3) .. "): " .. aux_util.deepToString(out, 3))
    return out
end


---@class TrackInfo
---@field tracking boolean
---@field startTime number
---@field endTime number
---@field onEnd fun(result: MoveResult?)?
---@field startCameraData CameraData?
---@field endCameraData CameraData?
---@field movesResult MoveResult

--- Lerp the camera to a new position.
---@type TrackInfo
local trackInfo = {
    tracking = false,
    startTime = 0,
    endTime = 0,
    onEnd = nil,
    startCameraData = nil,
    endCameraData = nil,
    movesResult = { success = true },
}

local function advanceTracker()
    if not trackInfo.tracking then
        return
    end
    local currentTime = core.getRealTime()
    local intermediate = nil
    local i = 0
    if currentTime >= trackInfo.endTime then
        -- set to end
        i = 1
        intermediate = {
            position = trackInfo.endCameraData.position,
            pitch = trackInfo.endCameraData.pitch,
        }
    else
        -- lerp!
        i = util.remap(currentTime, trackInfo.startTime, trackInfo.endTime, 0, 1)
        intermediate = {
            position = mutil.lerpVec3(trackInfo.startCameraData.position, trackInfo.endCameraData.position, i),
            pitch = mutil.lerpAngle(trackInfo.startCameraData.pitch, trackInfo.endCameraData.pitch, i)
        }
    end

    trackInfo.movesResult = mergeMoveResult(trackInfo.movesResult, moveCamera(intermediate))

    if i >= 1 then
        trackInfo.tracking = false
        if trackInfo.onEnd then
            trackInfo.onEnd(trackInfo.movesResult)
        end
    end
end

---@param cameraData CameraData
---@param duration number?
---@param onEnd fun(result: MoveResult?)?
local function trackPosition(cameraData, duration, onEnd)
    --print("trackPosition: " .. aux_util.deepToString(cameraData, 3))
    if cameraData == nil then
        error("trackPosition cameraData is required.")
    end
    trackInfo.tracking = true
    trackInfo.startCameraData = currentCameraData()
    trackInfo.endCameraData = cameraData
    trackInfo.movesResult = { success = true }

    if trackInfo.endCameraData.relativePosition and not trackInfo.endCameraData.position then
        trackInfo.endCameraData.position = camera.getPosition() + trackInfo.endCameraData.relativePosition
        trackInfo.endCameraData.relativePosition = nil
    end

    trackInfo.startTime = core.getRealTime()
    duration = duration or 0
    trackInfo.endTime = trackInfo.startTime + duration
    trackInfo.onEnd = onEnd
end

-- cameraOffset returns a vector offset for the camera position
-- so that the center of the viewPort lands on targetPosition.
local function cameraOffset(targetPosition, camPitch, camViewVector)
    local pos = targetPosition or camera.getPosition()
    local pitch = camPitch or camera.getPitch()
    local height = pos.z - currentMapData.object.position.z
    local viewDir = facing2D(camViewVector)
    -- 1.5708 - pitch is the angle between straight down and camera center.
    return viewDir * (-1 * height * math.tan(1.5708 - pitch))
end

---@param worldPos util.vector3
---@param relativeHeight number? Zoom level you want.
---@return CameraData?
local function worldPosToCameraPos(worldPos, relativeHeight)
    if not currentMapData then
        error("currentMapData is nil")
    end
    local mapCenter = currentMapData.object:getBoundingBox().center
    local cellPos = mutil.worldPosToCellPos(worldPos)
    local rel = putil.cellPosToRelativeMeshPos(currentMapData, cellPos, true)
    local mapWorldPos = putil.relativeMeshPosToAbsoluteMeshPos(currentMapData, rel)

    if not relativeHeight then
        relativeHeight = camera.getPosition().z - currentMapData.object.position.z
    end
    local heightOffset = util.vector3(0, 0, relativeHeight)
    --- these vars are all good!
    ---print("cellPos:" .. tostring(cellPos) .. ", rel:" .. tostring(rel) .. ", mapmeshpos:" .. tostring(mapWorldPos))
    local camOffset = cameraOffset(mapCenter + heightOffset, defaultPitch, util.vector3(0, 1, 0))
    local camData = {
        pitch = defaultPitch,
        position = mapWorldPos + camOffset + heightOffset,
    }
    return camData
end

---@param worldPos util.vector3
---@param duration number?
---@param onEnd fun(result: MoveResult?)?
local function trackToWorldPosition(worldPos, duration, onEnd)
    if not currentMapData then
        return nil
    end
    --[[print("trackToWorldPosition(" ..
        aux_util.deepToString(worldPos, 3) ..
        ", " .. tostring(duration) .. ", " .. aux_util.deepToString(onEnd, 1) .. ")")]]
    local camPos = worldPosToCameraPos(worldPos)
    if not camPos then
        return nil
    end
    trackPosition(camPos, duration, onEnd)
end

local function haltTracking()
    if trackInfo.tracking then
        trackInfo.movesResult.success = false
        if trackInfo.onEnd then
            trackInfo.onEnd(trackInfo.movesResult)
        end
    end
    trackInfo.tracking = false
end

local pendingMouseMove = 0
local function onMouseWheel(direction)
    pendingMouseMove = direction
end

local vecForward = util.vector3(0, 1, 0)
local vecBackward = vecForward * -1
local vecRight = util.vector3(1, 0, 0)
local vecLeft = vecRight * -1
local vecUp = util.vector3(0, 0, 1)
local vecDown = vecUp * -1
local moveSpeed = 150

local newMapTileThisFrame = false

-- easeInOutSine is a smoothing function. t ranges from 0 to 1.
local function easeInOutSine(t)
    return -1 * (math.cos(math.pi * t) - 1) / 2
end

local function onFrame(dt)
    -- Fake a duration if we're paused.
    if dt <= 0 then
        dt = core.getRealFrameDuration()
    end
    -- Only track inputs while the map is up.
    if not originalCameraState then
        return
    end

    -- Track inputs.
    for _, inp in pairs(keys) do
        inp:update(dt)
    end

    if newMapTileThisFrame then
        newMapTileThisFrame = false
        return
    end

    -- If we have input, cancel trackPosition,
    -- then move the camera manually.
    -- Else, advance the camera toward tracked position.
    local hasInput = false
    for _, key in pairs(keys) do
        if key.pressed then
            hasInput = true
            break
        end
    end
    hasInput = hasInput or (pendingMouseMove ~= 0)
    if not hasInput then
        advanceTracker()
        return
    end

    if keys.inventoryWindow.rise then
        print("Switching to inventory window.")
        interfaces.LivelyMapToggler.toggleMap(false,
            function()
                print("Done switching to inventory window.")
                interfaces.UI.addMode('Interface', { windows = { "Inventory" } })
            end)
        return
    end
    if keys.statsWindow.rise then
        print("Switching to stats window.")
        interfaces.LivelyMapToggler.toggleMap(false, function()
            print("Done switching to stats window.")
            if interfaces.StatsWindow then
                interfaces.StatsWindow.show(true)
            else
                interfaces.UI.addMode('Interface', { windows = { "Stats" } })
            end
        end)
        return
    end

    local heightSpeedModifier = util.remap(camera.getPosition().z - currentMapData.object.position.z, minCameraHeight,
        maxCameraHeight, 0, 1)

    local planarMoveVec = (vecForward * keys.forward.analog +
        vecBackward * keys.backward.analog +
        vecRight * keys.right.analog +
        vecLeft * keys.left.analog
    ):normalize() * moveSpeed * dt * (3 * heightSpeedModifier + 1)

    local zoomMoveVec = (vecUp * keys.zoomOut.analog +
        vecDown * keys.zoomIn.analog +
        vecUp * pendingMouseMove):normalize() * moveSpeed * dt * (3 * easeInOutSine(heightSpeedModifier) + 1)

    pendingMouseMove = 0

    moveCamera({
        relativePosition = planarMoveVec + zoomMoveVec
    })
    -- Interrupt tracking
    haltTracking()
    -- clear hoverbox
    --interfaces.LivelyMapDraw.setHoverBoxContent()
end

---@param hits ScreenHits
---@param bounds any  -- currentMapData.safeBounds
---@return util.vector3|nil
local function computeVisibilityCorrection(hits, bounds)
    local minX = bounds.bottomLeft.x
    local maxX = bounds.bottomRight.x
    local minY = bounds.bottomLeft.y
    local maxY = bounds.topLeft.y

    local cx = 0
    local cy = 0
    local count = 0

    -- Compute center of viewport on the map plane
    for _, h in pairs(hits) do
        if h.worldSpace then
            cx = cx + h.worldSpace.x
            cy = cy + h.worldSpace.y
            count = count + 1
        end
    end

    -- No valid intersection at all → nothing we can do
    if count == 0 then
        return nil
    end

    cx = cx / count
    cy = cy / count

    local dx = 0
    local dy = 0

    if cx < minX then
        dx = minX - cx
    elseif cx > maxX then
        dx = maxX - cx
    end

    if cy < minY then
        dy = minY - cy
    elseif cy > maxY then
        dy = maxY - cy
    end

    if dx == 0 and dy == 0 then
        return nil
    end

    return util.vector3(dx, dy, 0)
end


local function doOnMapMoved(data)
    print("controls.doOnMapMoved")
    currentMapData = data
    newMapTileThisFrame = true
    -- If this is not a swap, then this is a brand new map session.
    if not data.swapped and data.startWorldPosition then
        -- Orient the camera so starting position is in the center.
        startCamera()
        print("initial track start")
        local camPos = worldPosToCameraPos(data.startWorldPosition, defaultHeight)
        camPos.force = true
        moveCamera(camPos)
    end

    -- This is a tile swap. Let's make sure the map is visible.
    if data.swapped then
        local screenPositions = getScreenPositions()
        local validPositions = screenPositionsValid(screenPositions)
        if validPositions ~= 4 then
            --- the map is not completely visible!
            print("New map doesn't fully occupy viewport, sliding into safe zone.")
            haltTracking()
            --- slide the camera over so the map is more visible
            --- TODO: this jumps around like mad if you are zoomed out too much
            local correction = computeVisibilityCorrection(
                screenPositions,
                currentMapData.safeBounds
            )

            if correction then
                moveCamera({
                    position = camera.getPosition() + correction,
                    force = true
                })
            end
        end
    end
end

interfaces.LivelyMapToggler.onMapMoved(doOnMapMoved)

local function doOnMapHidden(data)
    print("controls.doOnMapHidden")
    currentMapData = nil
    -- If it's not a swap, it means we are done looking at the map.
    if not data.swapped then
        endCamera()
    end
end

interfaces.LivelyMapToggler.onMapHidden(doOnMapHidden)

local function onLoad(data)
    originalCameraState = data
end

local function onSave()
    return originalCameraState
end

return {
    interfaceName = MOD_NAME .. "Controls",
    interface = {
        version = 1,
        trackPosition = trackPosition,
        trackToWorldPosition = trackToWorldPosition,
    },
    engineHandlers = {
        onMouseWheel = onMouseWheel,
        onFrame = onFrame,
        onSave = onSave,
        onLoad = onLoad,
    },
}
