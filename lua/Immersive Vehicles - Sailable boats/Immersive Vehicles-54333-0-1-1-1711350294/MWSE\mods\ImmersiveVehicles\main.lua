local common = require("rfuzzo.ImmersiveTravel.common")

local DEBUG = false

local logger = require("logging.logger")
local log = logger.new {
    name = "Immersive Vehicles",
    logLevel = "INFO", -- TODO add to mcm?
    logToConsole = false,
    includeTimestamp = false
}

-- TYPES

---@class MountDataEx : MountData
---@field minSpeed number?
---@field maxSpeed number?
---@field changeSpeed number?
---@field freedomtype string? -- flying, boat, ground
---@field accelerateAnimation string? -- animation to play while accelerating. slowing
---@diagnostic disable-next-line: undefined-doc-name
---@field materials CraftingFramework.MaterialRequirement[]? -- recipe materials for crafting the mount
---@field name string? -- name of the mount
---@field price number? -- price of the mount
---@field length number? -- length of the mount
---@field width number? -- width of the mount

-- CONSTANTS

local localmodpath = "mods\\ImmersiveVehicles\\"
local fullmodpath = "Data Files\\MWSE\\" .. localmodpath

local sway_max_amplitude = 3       -- how much the ship can sway in a turn
local sway_amplitude_change = 0.01 -- how much the ship can sway in a turn
local sway_frequency = 0.12        -- how fast the mount sways
local sway_amplitude = 0.014       -- how much the mount sways
local timertick = 0.01
local travelMarkerId = "marker_arrow.nif"

local travelMarkerMesh = nil
local mountMarkerMesh = nil

-- VARIABLES

local myTimer = nil ---@type mwseTimer | nil
local virtualDestination = nil ---@type tes3vector3|nil

local swayTime = 0
local last_position = nil ---@type tes3vector3|nil
local last_forwardDirection = nil ---@type tes3vector3|nil
local last_facing = nil ---@type number|nil
local last_sway = 0 ---@type number
local current_speed = 0 ---@type number
local is_on_mount = false

local mountData = nil ---@type MountDataEx|nil
local mountHandle = nil ---@type mwseSafeObjectHandle|nil

local travelMarker = nil ---@type niNode?
local mountMarker = nil ---@type niNode?

local cameraOffset = nil ---@type tes3vector3?
local editmode = false
local speedChange = 0

--- HELPERS


--- @param from tes3vector3
--- @return number|nil
local function getGroundZ(from)
    local rayhit = tes3.rayTest {
        position = from,
        direction = tes3vector3.new(0, 0, -1),
        returnNormal = true,
        root = tes3.game.worldLandscapeRoot
    }

    if (rayhit) then
        local to = rayhit.intersection
        return to.z
    end

    return nil
end

--- @param from tes3vector3
--- @return number|nil
local function testCollisionZ(from)
    local rayhit = tes3.rayTest {
        position = from,
        direction = tes3vector3.new(0, 0, -1),
        returnNormal = true,
        root = tes3.game.worldObjectRoot
    }

    if (rayhit) then
        local to = rayhit.intersection
        return to.z
    end

    return nil
end

--- EVENTS

--- @param e mouseWheelEventData
local function mouseWheelCallback(e)
    local isControlDown = tes3.worldController.inputController:isControlDown()
    if is_on_mount and isControlDown then
        -- update fov
        if e.delta > 0 then
            tes3.set3rdPersonCameraOffset({ offset = tes3.get3rdPersonCameraOffset() + tes3vector3.new(0, 10, 0) })
        else
            tes3.set3rdPersonCameraOffset({ offset = tes3.get3rdPersonCameraOffset() - tes3vector3.new(0, 10, 0) })
        end
    end
end

--- @param e keyDownEventData
local function mountKeyDownCallback(e)
    if is_on_mount and mountHandle and mountHandle:valid() and mountData then
        if e.keyCode == tes3.scanCode["w"] then
            -- increment speed
            if current_speed < mountData.maxSpeed then
                speedChange = 1
                -- play anim
                if mountData.accelerateAnimation then
                    tes3.loadAnimation({ reference = mountHandle:getObject() })
                    tes3.playAnimation({
                        reference = mountHandle:getObject(),
                        group = tes3.animationGroup
                            [mountData.accelerateAnimation]
                    })
                end
            end
        end

        if e.keyCode == tes3.scanCode["s"] then
            -- decrement speed
            if current_speed > mountData.minSpeed then
                speedChange = -1
                -- play anim
                if mountData.accelerateAnimation then
                    tes3.loadAnimation({ reference = mountHandle:getObject() })
                    tes3.playAnimation({
                        reference = mountHandle:getObject(),
                        group = tes3.animationGroup
                            [mountData.accelerateAnimation]
                    })
                end
            end
        end
    end
end

--- @param e keyUpEventData
local function keyUpCallback(e)
    if is_on_mount and mountHandle and mountHandle:valid() and mountData then
        if e.keyCode == tes3.scanCode["w"] or e.keyCode == tes3.scanCode["s"] then
            -- stop increment speed
            speedChange = 0
            -- play anim
            if mountData.forwardAnimation then
                tes3.loadAnimation({ reference = mountHandle:getObject() })
                tes3.playAnimation({
                    reference = mountHandle:getObject(),
                    group = tes3.animationGroup
                        [mountData.forwardAnimation]
                })
            end

            if DEBUG then
                tes3.messageBox("Current Speed: " .. tostring(current_speed))
            end
        end
    end
end

--- visualize on tick
--- @param e simulatedEventData
local function mountSimulatedCallback(e)
    -- update next pos
    if not editmode and is_on_mount and mountHandle and mountHandle:valid() and
        mountData then
        local mount = mountHandle:getObject()
        local dist = 2048
        if mountData.freedomtype == "ground" then
            dist = 100
        end
        local target = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector() * dist

        local isControlDown = tes3.worldController.inputController:isControlDown()
        if isControlDown then
            target = mount.sceneNode.worldTransform * tes3vector3.new(0, 2048, 0)
        end
        if mountData.freedomtype == "boat" then
            -- pin to waterlevel
            target.z = 0
        elseif mountData.freedomtype == "ground" then
            -- pin to groundlevel
            local z = getGroundZ(target + tes3vector3.new(0, 0, 100))
            if not z then
                target.z = 0
            else
                target.z = z + 50
            end
        end

        virtualDestination = target

        -- render debug marker
        if DEBUG and travelMarker then
            travelMarker.translation = target
            local m = tes3matrix33.new()
            if isControlDown then
                m:fromEulerXYZ(mount.orientation.x, mount.orientation.y, mount.orientation.z)
            else
                m:fromEulerXYZ(tes3.player.orientation.x, tes3.player.orientation.y, tes3.player.orientation.z)
            end
            travelMarker.rotation = m
            travelMarker:update()
        end
    end

    -- collision
    if not editmode and is_on_mount and mountHandle and mountHandle:valid() and mountData then
        -- raytest at sealevel to detect shore transition
        local box = mountHandle:getObject().object.boundingBox
        local max = box.max * mountData.scale
        local min = box.min * mountData.scale
        local t = mountHandle:getObject().sceneNode.worldTransform

        if current_speed > 0 then
            -- detect shore
            if mountData.freedomtype == "boat" then
                local bowPos = t * tes3vector3.new(0, max.y, min.z + (mountData.offset * mountData.scale))
                local hitResult1 = tes3.rayTest({
                    position = bowPos,
                    direction = tes3vector3.new(0, 0, -1),
                    root = tes3.game.worldLandscapeRoot,
                    --maxDistance = 4096
                })
                if (hitResult1 == nil) then
                    current_speed = 0
                    if DEBUG then
                        tes3.messageBox("HIT Shore Fwd")
                        log:debug("HIT Shore Fwd")
                    end
                end
            end

            -- raytest from above to detect objects in water
            local bowPosTop = t * tes3vector3.new(0, max.y, max.z)
            local hitResult2 = tes3.rayTest({
                position = bowPosTop,
                direction = tes3vector3.new(0, 0, -1),
                root = tes3.game.worldObjectRoot,
                ignore = { mountHandle:getObject() },
                maxDistance = max.z * mountData.scale
            })
            if (hitResult2 ~= nil) then
                current_speed = 0
                if DEBUG then
                    tes3.messageBox("HIT Object Fwd")
                    log:debug("HIT Object Fwd")
                end
            end
        elseif current_speed < 0 then
            -- detect shore
            if mountData.freedomtype == "boat" then
                local sternPos = t * tes3vector3.new(0, min.y, min.z + (mountData.offset * mountData.scale))
                local hitResult1 = tes3.rayTest({
                    position = sternPos,
                    direction = tes3vector3.new(0, 0, -1),
                    root = tes3.game.worldLandscapeRoot,
                    --maxDistance = 4096
                })
                if (hitResult1 == nil) then
                    current_speed = 0
                    if DEBUG then
                        tes3.messageBox("HIT Shore Back")
                        log:debug("HIT Shore Back")
                    end
                end
            end

            -- raytest from above to detect objects in water
            local sternPosTop = t * tes3vector3.new(0, min.y, max.z)
            local hitResult2 = tes3.rayTest({
                position = sternPosTop,
                direction = tes3vector3.new(0, 0, -1),
                root = tes3.game.worldObjectRoot,
                ignore = { mountHandle:getObject() },
                maxDistance = max.z
            })
            if (hitResult2 ~= nil) then
                current_speed = 0
                if DEBUG then
                    tes3.messageBox("HIT Object Back")
                    log:debug("HIT Object Back")
                end
            end
        end
    end
end

-- HELPERS

local function safeCancelTimer() if myTimer ~= nil then myTimer:cancel() end end

local function cleanup()
    log:debug("cleanup")

    if cameraOffset then
        tes3.set3rdPersonCameraOffset({ offset = cameraOffset })
    end

    -- reset global vars
    safeCancelTimer()
    virtualDestination = nil

    swayTime = 0
    last_position = nil
    last_forwardDirection = nil
    last_facing = nil
    last_sway = 0
    current_speed = 0
    is_on_mount = false
    current_speed = 0

    if mountData and mountHandle and mountHandle:valid() then
        tes3.removeSound({
            sound = mountData.sound,
            reference = mountHandle:getObject()
        })
    end
    mountHandle = nil

    if mountData then
        -- delete statics
        if mountData.clutter then
            log:debug("cleanup statics")
            for index, clutter in ipairs(mountData.clutter) do
                if clutter.handle and clutter.handle:valid() then
                    clutter.handle:getObject():delete()
                    clutter.handle = nil
                    log:debug("cleanup static " .. clutter.id)
                end
            end
        end
    end
    mountData = nil

    -- don't delete ref since we may want to use the mount later
    -- if mount then mount:delete() end

    local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
    ---@diagnostic disable-next-line: param-type-mismatch
    if travelMarker then vfxRoot:detachChild(travelMarker) end
    if mountMarker then vfxRoot:detachChild(mountMarker) end
    travelMarker = nil
    mountMarker = nil

    -- unregister events
    event.unregister(tes3.event.mouseWheel, mouseWheelCallback)
    event.unregister(tes3.event.keyDown, mountKeyDownCallback)
    event.unregister(tes3.event.keyUp, keyUpCallback)
    event.unregister(tes3.event.simulated, mountSimulatedCallback)
end

local function destinationReached()
    log:debug("destinationReached")

    -- reset player
    tes3.mobilePlayer.movementCollision = true;
    tes3.loadAnimation({ reference = tes3.player })
    tes3.playAnimation({ reference = tes3.player, group = 0 })

    -- teleport followers
    if mountData then
        for index, slot in ipairs(mountData.slots) do
            if slot.handle and slot.handle:valid() then
                local ref = slot.handle:getObject()
                if ref ~= tes3.player and ref.mobile and
                    common.isFollower(ref.mobile) then
                    log:debug("teleporting follower " .. ref.id)

                    ref.mobile.movementCollision = true;
                    tes3.loadAnimation({ reference = ref })
                    tes3.playAnimation({ reference = ref, group = 0 })

                    local f = tes3.player.forwardDirection
                    f:normalize()
                    local offset = f * 60.0
                    tes3.positionCell({
                        reference = ref,
                        position = tes3.player.position + offset
                    })

                    slot.handle = nil
                end
            end
        end
    end

    cleanup()
end

---Checks if a reference is on water
---@param reference tes3reference
---@param data MountDataEx
---@return boolean
local function onWater(reference, data)
    local cell = tes3.player.cell
    local waterLevel = cell.hasWater and cell.waterLevel
    if not cell.isInterior and waterLevel and reference.position.z - waterLevel <
        data.offset then
        return true
    end
    return false
end

local function playerIsUnderwater()
    local waterLevel = tes3.mobilePlayer.cell.waterLevel
    local minPosition = tes3.mobilePlayer.position.z

    return minPosition < waterLevel
end



--- load json static mount data
---@param id string
---@return MountDataEx|nil
local function loadMountData(id)
    local filePath = localmodpath .. "mounts\\" .. id .. ".json"
    local result = nil ---@type MountDataEx?
    result = json.loadfile(filePath)
    if result then
        -- set defaults
        if not result.scale then
            result.scale = 1.0
        end

        return result
    else
        log:error("!!! failed to load mount: " .. id)
        return nil
    end
end

-- LOGIC

--- Load all mounts
---@return string[]
local function loadMountNames()
    log:debug("Loading mount names...")

    ---@type string[]
    local names = {}
    for fileName in lfs.dir(fullmodpath .. "mounts") do
        if (string.endswith(fileName, ".json")) then
            table.insert(names, fileName:sub(0, -6))
        end
    end
    return names
end

--- check if valid mount
---@param id string
---@return boolean
local function validMount(id)
    ---@type string[]
    local mount_ids = loadMountNames()
    return common.is_in(mount_ids, id)
end

--- map ids to mounts
---@param id string
---@return string|nil
local function getMountForId(id)
    -- NOTE add exceptions here
    return id
end

--- main loop
local function onTimerTick()
    -- checks
    if mountHandle == nil then
        return
    end
    if not mountHandle:valid() then
        return
    end
    if mountData == nil then
        return
    end
    if myTimer == nil then
        return
    end
    if virtualDestination == nil then
        return
    end

    if last_position == nil then
        return
    end
    if last_facing == nil then
        return
    end
    if last_forwardDirection == nil then
        return
    end

    local mount = mountHandle:getObject()
    if mount.sceneNode == nil then
        return
    end

    local rootBone = mount.sceneNode
    if mountData.nodeName then
        rootBone = mount.sceneNode:getObjectByName(mountData.nodeName) --[[@as niNode]]
    end
    if rootBone == nil then
        rootBone = mount.sceneNode
    end
    if rootBone == nil then
        return
    end

    -- register keypresses
    if speedChange > 0 then
        local change = current_speed + (mountData.changeSpeed * timertick)
        current_speed = math.clamp(change, mountData.minSpeed, mountData.maxSpeed)
    elseif speedChange < 0 then
        local change = current_speed - (mountData.changeSpeed * timertick)
        current_speed = math.clamp(change, mountData.minSpeed, mountData.maxSpeed)
    end

    -- skip
    if current_speed < mountData.minSpeed then return end

    local mountOffset = tes3vector3.new(0, 0, mountData.offset) * mount.scale
    local nextPos = virtualDestination
    local currentPos = last_position - mountOffset

    -- calculate diffs
    local forwardDirection = last_forwardDirection
    forwardDirection:normalize()
    local d = (nextPos - currentPos):normalized()

    -- calculate position
    local lerp = forwardDirection:lerp(d, mountData.turnspeed / 10.0):normalized()
    local forward = tes3vector3.new(mount.forwardDirection.x, mount.forwardDirection.y, lerp.z):normalized()
    local delta = forward * current_speed

    -- calculate facing
    local turn = 0
    local current_facing = last_facing
    local new_facing = math.atan2(d.x, d.y)
    local facing = new_facing
    local diff = new_facing - current_facing
    if diff < -math.pi then diff = diff + 2 * math.pi end
    if diff > math.pi then diff = diff - 2 * math.pi end
    local angle = mountData.turnspeed / 10000
    if diff > 0 and diff > angle then
        facing = current_facing + angle
        turn = 1
    elseif diff < 0 and diff < -angle then
        facing = current_facing - angle
        turn = -1
    else
        facing = new_facing
    end

    -- move ship
    mount.facing = facing
    mount.position = currentPos + delta + mountOffset

    -- save
    last_position = mount.position
    last_forwardDirection = mount.forwardDirection
    last_facing = mount.facing

    -- set sway
    local amplitude = sway_amplitude * mountData.sway
    local sway_change = amplitude * sway_amplitude_change
    swayTime = swayTime + timertick
    if swayTime > (2000 * sway_frequency) then swayTime = timertick end

    local sway = amplitude * math.sin(2 * math.pi * sway_frequency * swayTime)
    -- offset roll during turns
    if turn > 0 then
        local max = (sway_max_amplitude * amplitude)
        sway = math.clamp(last_sway - sway_change, -max, max) -- + sway
    elseif turn < 0 then
        local max = (sway_max_amplitude * amplitude)
        sway = math.clamp(last_sway + sway_change, -max, max) -- + sway
    else
        -- normalize back
        if last_sway < (sway - sway_change) then
            sway = last_sway + sway_change -- + sway
        elseif last_sway > (sway + sway_change) then
            sway = last_sway - sway_change -- + sway
        end
    end
    last_sway = sway
    local newOrientation = common.toWorldOrientation(
        tes3vector3.new(0.0, sway, 0.0),
        mount.orientation)
    mount.orientation = newOrientation

    -- passengers
    for index, slot in ipairs(mountData.slots) do
        if slot.handle and slot.handle:valid() then
            slot.handle:getObject().position = rootBone.worldTransform * common.vec(slot.position)
        end
    end

    -- statics
    if mountData.clutter then
        for index, clutter in ipairs(mountData.clutter) do
            if clutter.handle and clutter.handle:valid() then
                clutter.handle:getObject().position = rootBone.worldTransform * common.vec(clutter.position)
                if clutter.orientation then
                    clutter.handle:getObject().orientation = common.toWorldOrientation(
                        common.radvec(clutter.orientation), mount.orientation)
                end
            end
        end
    end
end

--- set up everything
local function startTravel()
    if mountData == nil then return end
    if mountHandle == nil then return end
    if not mountHandle:valid() then return end

    local mount = mountHandle:getObject()
    virtualDestination = mount.position

    -- fade out
    tes3.fadeOut({ duration = 1 })

    -- register events
    event.register(tes3.event.mouseWheel, mouseWheelCallback)
    event.register(tes3.event.keyDown, mountKeyDownCallback)
    event.register(tes3.event.keyUp, keyUpCallback)
    event.register(tes3.event.simulated, mountSimulatedCallback)


    -- fade back in
    timer.start({
        type = timer.simulate,
        iterations = 1,
        duration = 1,
        callback = (function()
            tes3.fadeIn({ duration = 1 })

            -- position mount at ground level
            if mountData.freedomtype ~= "boat" then
                local top = tes3vector3.new(0, 0, mount.object.boundingBox.max.z)
                local z = getGroundZ(mount.position + top)
                if not z then
                    z = tes3.player.position.z
                end
                mount.position = tes3vector3.new(mount.position.x, mount.position.y,
                    z + (mountData.offset * mountData.scale))
            end
            mount.orientation = tes3.player.orientation

            -- visualize debug marker
            if DEBUG and travelMarkerMesh then
                local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
                local child = travelMarkerMesh:clone()
                local from = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector() * 256
                child.translation = from
                child.appCulled = false
                ---@diagnostic disable-next-line: param-type-mismatch
                vfxRoot:attachChild(child)
                vfxRoot:update()
                travelMarker = child
            end

            -- calculate positions
            local startPos = virtualDestination
            local mountOffset = tes3vector3.new(0, 0, mountData.offset) *
                mountData.scale

            -- register player
            log:debug("> registering player")
            tes3.player.position = startPos + mountOffset
            common.registerRefInRandomSlot(mountData, tes3.makeSafeObjectHandle(
                tes3.player))

            -- register statics
            if mountData.clutter then
                log:debug("> registering statics")
                for index, clutter in ipairs(mountData.clutter) do
                    if clutter.id then
                        -- instantiate
                        if clutter.orientation then
                            local inst =
                                tes3.createReference {
                                    object = clutter.id,
                                    position = startPos + mountOffset,
                                    orientation = common.toWorldOrientation(common.radvec(clutter.orientation), mount.orientation)
                                }
                            common.registerStatic(mountData,
                                tes3.makeSafeObjectHandle(inst),
                                index)
                        else
                            local inst =
                                tes3.createReference {
                                    object = clutter.id,
                                    position = startPos + mountOffset,
                                    orientation = mount.orientation
                                }
                            common.registerStatic(mountData,
                                tes3.makeSafeObjectHandle(inst),
                                index)
                        end
                    end
                end
            end

            -- TODO register passengers

            -- start timer
            cameraOffset = tes3.get3rdPersonCameraOffset()
            is_on_mount = true
            current_speed = 1
            last_position = mount.position
            last_forwardDirection = mount.forwardDirection
            last_facing = mount.facing
            last_sway = 0
            tes3.playSound({
                sound = mountData.sound,
                reference = mount,
                loop = true
            })


            log:debug("starting timer")
            myTimer = timer.start({
                duration = timertick,
                type = timer.simulate,
                iterations = -1,
                callback = onTimerTick
            })
        end)
    })
end

--- activate the vehicle
---@param reference tes3reference
local function activateMount(reference)
    if validMount(reference.id) then
        if is_on_mount then
            -- stop
            safeCancelTimer()
            destinationReached()
        else
            -- start
            mountData = loadMountData(getMountForId(reference.id))
            if mountData then
                mountHandle = tes3.makeSafeObjectHandle(reference)
                startTravel()
            end
        end
    end
end

--- destroy the vehicle
---@param reference tes3reference
local function destroyMount(reference)
    -- stop
    safeCancelTimer()
    destinationReached()
    reference:disable()
    reference:delete()
end

-- EVENTS

local dbg_mount_id = nil ---@type string?

--- @param e keyDownEventData
local function keyDownCallback(e)
    -- leave editor and spawn vehicle
    if DEBUG then
        if e.keyCode == tes3.scanCode["o"] and editmode and mountMarker and dbg_mount_id then
            -- spawn vehicle
            local obj = tes3.createReference {
                object = dbg_mount_id,
                position = mountMarker.translation,
                orientation = mountMarker.rotation:toEulerXYZ(),
                scale = mountMarker.scale
            }
            obj.facing = tes3.player.facing

            -- remove marker
            local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
            vfxRoot:detachChild(mountMarker)
            mountMarker = nil
            editmode = false
        elseif e.keyCode == tes3.scanCode["o"] and not editmode and not is_on_mount then
            local buttons = {}
            local mounts = loadMountNames()
            for _, id in ipairs(mounts) do
                table.insert(buttons, {
                    text = id,
                    callback = function(e)
                        mountData = loadMountData(getMountForId(id))
                        if not mountData then return nil end
                        -- visualize placement node
                        local target = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector() * (256 / mountData.scale)

                        mountMarkerMesh = tes3.loadMesh(mountData.mesh)
                        local child = mountMarkerMesh:clone()
                        child.translation = target
                        child.scale = mountData.scale
                        child.appCulled = false
                        local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
                        ---@diagnostic disable-next-line: param-type-mismatch
                        vfxRoot:attachChild(child)
                        vfxRoot:update()
                        mountMarker = child

                        -- enter placement mode
                        editmode = true
                        dbg_mount_id = id
                    end,
                })
            end
            tes3ui.showMessageMenu({ id = "rf_dbg_iv", message = "Choose your mount", buttons = buttons, cancels = true })
        end
    end
end
event.register(tes3.event.keyDown, keyDownCallback)

--- visualize on tick
--- @param e simulatedEventData
local function simulatedCallback(e)
    -- visualize mount scene node
    if DEBUG then
        if editmode and mountMarker and mountData then
            local from = tes3.getPlayerEyePosition() + (tes3.getPlayerEyeVector() * 500.0 * mountData.scale)
            if mountData.freedomtype == "boat" then
                from.z = mountData.offset * mountData.scale
            elseif mountData.freedomtype == "ground" then
                local z = getGroundZ(from + tes3vector3.new(0, 0, 200))
                if not z then
                    from.z = 0
                else
                    from.z = z
                end
            end

            mountMarker.translation = from
            local m = tes3matrix33.new()
            m:fromEulerXYZ(tes3.player.orientation.x, tes3.player.orientation.y, tes3.player.orientation.z)
            mountMarker.rotation = m
            mountMarker:update()
        end
    end
end
event.register(tes3.event.simulated, simulatedCallback)

--- Cleanup on save load
--- @param e loadEventData
local function loadCallback(e)
    cleanup()
    travelMarkerMesh = tes3.loadMesh(travelMarkerId)
end
event.register(tes3.event.load, loadCallback)

--- @param e activateEventData
local function activateCallback(e) activateMount(e.target) end
event.register(tes3.event.activate, activateCallback)


-- //////////////////////////////////////////////////////////////////////////////////////////
-- UI MENU
---comment
---@param testpos tes3vector3
---@return boolean
local function checkIsCollision(testpos)
    -- raycast fore and aft to check boundaries
    local hitResult = tes3.rayTest({
        position = testpos,
        direction = tes3vector3.new(0, 0, -1),
        root = tes3.game.worldObjectRoot,
        maxDistance = 2048
    })

    if not hitResult then
        hitResult = tes3.rayTest({
            position = testpos,
            direction = tes3vector3.new(0, 0, -1),
            root = tes3.game.worldPickRoot,
            maxDistance = 2048
        })
    end

    -- no result means no collision
    return hitResult ~= nil
end

--- @param ref tes3reference
--- @param id string
---@return boolean
local function trySpawnBoat(ref, id)
    local data = loadMountData(getMountForId(id))
    if not data then return false end

    local refpos = ref.position
    local playerEyePositionZ = tes3.getPlayerEyePosition().z
    log:debug("Try spawning %s at position %s", id, refpos)

    -- local rotation = ref.sceneNode.worldTransform.rotation
    -- local rotation = tes3.player.sceneNode.worldTransform.rotation
    local orientation = tes3.player.orientation
    local rotation = tes3matrix33.new()
    rotation:fromEulerXYZ(orientation.x, orientation.y, orientation.z)
    -- rotate matrix 90 degrees
    rotation = rotation * tes3matrix33.new(
        0, 1, 0,
        -1, 0, 0,
        0, 0, 1
    )

    -- get bounding box
    local mesh = tes3.loadMesh(data.mesh)
    local box = mesh:createBoundingBox()
    local max = box.max
    local min = box.min

    -- go in concentric circles around ref
    for i = 1, 20, 1 do
        local radius = i * 50
        -- check in a circle around ref in 45 degree steps
        for angle = 0, 360, 45 do
            local angle_rad = math.rad(angle)

            -- test position in water
            local x = refpos.x + radius * math.cos(angle_rad)
            local y = refpos.y + radius * math.sin(angle_rad)
            local testpos = tes3vector3.new(x, y, data.offset)

            -- check angles in 45 degree steps


            -- for z = 0, 360, 45 do
            --     -- rotate matrix 45 degrees
            --     if z > 0 then
            --         rotation = rotation * tes3matrix33.new(
            --             math.cos(math.rad(z)), -math.sin(math.rad(z)), 0,
            --             math.sin(math.rad(z)), math.cos(math.rad(z)), 0,
            --             0, 0, 1
            --         )
            --     end



            local t = tes3transform:new(rotation, testpos, data.scale)

            -- test four corners of bounding box from top and X
            --- @type tes3vector3[]
            local tests = {}
            tests[1] = t * tes3vector3.new(0, 0, 0)
            tests[2] = t * tes3vector3.new(max.x, max.y, 0)
            tests[3] = t * tes3vector3.new(max.x, min.y, 0)
            tests[4] = t * tes3vector3.new(min.x, max.y, 0)
            tests[5] = t * tes3vector3.new(min.x, min.y, 0)
            tests[6] = t * tes3vector3.new(max.x, 0, 0)
            tests[7] = t * tes3vector3.new(min.x, 0, 0)
            tests[8] = t * tes3vector3.new(0, max.y, 0)
            tests[9] = t * tes3vector3.new(0, min.y, 0)
            tests[10] = t * tes3vector3.new(max.x / 2, 0, 0)
            tests[11] = t * tes3vector3.new(min.x / 2, 0, 0)


            local collision = false
            for _, test in ipairs(tests) do
                test.z = playerEyePositionZ
                -- check if a collision found
                if checkIsCollision(test) then
                    collision = true
                    break
                end
            end

            if not collision then
                -- debug
                -- local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
                -- vfxRoot:detachAllChildren()

                -- for _, test in ipairs(tests) do
                --     if travelMarkerMesh then
                --         local child = travelMarkerMesh:clone()
                --         child.translation = test
                --         child.rotation = rotation
                --         child.appCulled = false
                --         ---@diagnostic disable-next-line: param-type-mismatch
                --         vfxRoot:attachChild(child)
                --     end
                -- end
                -- vfxRoot:update()

                tes3.createReference {
                    object = id,
                    position = testpos,
                    orientation = rotation:toEulerXYZ(),
                    scale = data.scale
                }
                log:debug("\tSpawning %s at %s", id, testpos)
                return true
            end
            -- end
        end
    end

    log:debug("No suitable position found")
    tes3.messageBox("No suitable position found")
    return false
end

--- no idea why this is needed
---@param menu tes3uiElement
local function updatePurchaseButton(menu)
    timer.frame.delayOneFrame(function()
        if not menu then return end
        local button = menu:findChild("rf_id_purchase_topic")
        if not button then return end
        button.visible = true
        button.disabled = false
    end)
end

---@param menu tes3uiElement
---@param ref tes3reference
local function createPurchaseTopic(menu, ref)
    local divider = menu:findChild("MenuDialog_divider")
    local topicsList = divider.parent
    local button = topicsList:createTextSelect({
        id = "rf_id_purchase_topic",
        text = "Purchase"
    })
    button.widthProportional = 1.0
    button.visible = true
    button.disabled = false

    topicsList:reorderChildren(divider, button, 1)

    button:register("mouseClick", function()
        local buttons = {}
        local mountNames = loadMountNames()

        for _, id in ipairs(mountNames) do
            local data = loadMountData(getMountForId(id))
            -- check if data is a boat
            -- TODO message by vehicle
            if data and data.freedomtype == "boat" then
                local buttonText = string.format("Buy %s for %s gold", data.name, data.price)
                table.insert(buttons, {
                    text = buttonText,
                    callback = function(e)
                        -- check gold
                        local goldCount = tes3.getPlayerGold()
                        if data.price and goldCount < data.price then
                            tes3.messageBox("You don't have enough gold")
                            return
                        end

                        local success = tes3.payMerchant({ merchant = ref.mobile, cost = data.price })
                        if success then
                            if trySpawnBoat(ref, id) then
                                tes3.messageBox("You bought a new boat!")
                            end
                        else
                            tes3.messageBox("You don't have enough gold")
                        end

                        tes3ui.leaveMenuMode()
                    end,
                })
            end
        end
        -- TODO message by class
        tes3ui.showMessageMenu({ message = "Purchase a boat", buttons = buttons, cancels = true })
    end)
    menu:registerAfter("update", function() updatePurchaseButton(menu) end)
end

-- upon entering the dialog menu, create the travel menu
---@param e uiActivatedEventData
local function onMenuDialog(e)
    local menuDialog = e.element
    local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor") ---@cast mobileActor tes3mobileActor
    if mobileActor.actorType == tes3.actorType.npc then
        local ref = mobileActor.reference
        local obj = ref.baseObject
        local npc = obj ---@cast obj tes3npc

        -- check if npc is Shipmaster
        if npc.class.id == "Shipmaster" then
            log:debug("createPurchaseTopic for %s", npc.id)
            createPurchaseTopic(menuDialog, ref)
            menuDialog:updateLayout()
        end
    end
end
event.register("uiActivated", onMenuDialog, { filter = "MenuDialog" })

-- //////////////////////////////////////////////////////////////////////////////////////////
-- CRAFTING FRAMEWORK

local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

local enterVehicle = {
    text = "Get in/out",
    callback = function(e)
        activateMount(e.reference)
    end
}

local destroyVehicle = {
    text = "Destroy",
    callback = function(e)
        destroyMount(e.reference)
    end
}

-- MATERIALS

--Register your materials
local materials = {
    {
        id = "mushroom",
        name = "Mushroom",
        ids = {
            "ingred_russula_01",
            "ingred_coprinus_01",
            "ingred_bc_bungler's_bane",
            "ingred_bc_hypha_facia",
            "ingred_bloat_01"
        }
    },

}
CraftingFramework.Material:registerMaterials(materials)

-- RECIPES

---get recipe with data
---@param id string
local function getRecipeFor(id)
    local data = loadMountData(getMountForId(id))
    if data and data.materials and data.scale then
        local recipe = {
            id = "recipe_" .. id,
            craftableId = id,
            soundType = "wood",
            category = "Vehicles",
            materials = data.materials,
            scale = data.scale,
            craftedOnly = false,
            additionalMenuOptions = { enterVehicle, destroyVehicle },
            -- secondaryMenu         = false,
            quickActivateCallback = function(_, e) activateMount(e.reference) end
        }

        return recipe
    end
    return nil
end

---@diagnostic disable-next-line: undefined-doc-name
---@type CraftingFramework.Recipe.data[]
local recipes = {}
local mounts = loadMountNames()
for _, id in ipairs(mounts) do
    local r = getRecipeFor(id)
    if r then
        table.insert(recipes, r)
    end
end

local function registerRecipes(e)
    if e.menuActivator then e.menuActivator:registerRecipes(recipes) end
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerRecipes)

--[[

-- boats

Mount a_gondola_01
  Bounding Box min: (-71.20,-356.43,-86.24)
  Bounding Box max: (71.20,356.43,86.24)
Mount a_mushroomdola_iv
  Bounding Box min: (-192.74,-332.32,-86.24)
  Bounding Box max: (183.23,453.84,223.41)
Mount a_rowboat_iv
  Bounding Box min: (-67.72,-175.68,-36.73)
  Bounding Box max: (67.75,179.42,36.73)
Mount a_sailboat_iv
  Bounding Box min: (-108.11,-320.38,-74.86)
  Bounding Box max: (210.41,444.66,809.85)
Mount a_telvcatboat_iv
  Bounding Box min: (-283.74,-908.30,-282.73)
  Bounding Box max: (225.16,830.83,658.28)


-- creatures

Mount a_cliffracer
  Bounding Box min: (-205.65,-420.28,-67.17)
  Bounding Box max: (205.41,41.53,251.36)
Mount a_nix-hound
  Bounding Box min: (-75.46,-230.34,-34.39)
  Bounding Box max: (135.54,11.85,161.92)

]]
