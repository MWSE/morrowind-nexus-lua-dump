local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local debug = require("openmw.debug")
local ambient = require('openmw.ambient')
local uiUtil = require("scripts.Aetherwind.util.ui")
local buttonsAndInfo = nil
local airshipMode = false
local useUI = true
local airshipOb = nil
local useACCam = false
local ownedShips = {}
local function onLoad(data)
    if data and data.ownedShips then
        ownedShips = data.ownedShips
    end
end
local function WriteToConsole(text, error)
    if error == true then
        ui.printToConsole(text, ui.CONSOLE_COLOR.Error)
        return
    end
    ui.printToConsole(text, ui.CONSOLE_COLOR.Info)
end
local function setAirshipOb(ob)
    if not ob then return end
    airshipOb = ob
end
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function isBelow(sourcePos, ignoreOb)
    if not ignoreOb then
        ignoreOb = self
    end
    if not sourcePos then
        sourcePos = self.position
    end
    local destPos = util.vector3(sourcePos.x, sourcePos.y, sourcePos.z - 1000)
    local hit = nearby.castRay(sourcePos, destPos, { ignore = ignoreOb })
    if hit.hitObject and hit.hitObject.recordId == "aeth_ship" then
        return true
    else
        return false
    end
end
local function inControlRange(sourcePos)
    return true
end
local recordState = false
local keys = {
    RotatePlus = input.KEY.A,
    RotateMinus = input.KEY.D,
    MoveForward = input.KEY.W,
    MoveBackwards = input.KEY.S,
    MoveLeft = input.KEY.Z,
    MoveRight = input.KEY.C,
    MoveUp = input.KEY.Tab,
    MoveDown = input.KEY.LeftShift,
    ChangeSpeed = input.KEY.Space,
    Mount = input.KEY.U,
    changeStaticMode = input.KEY.O,
    TPToExit = input.KEY.M,
    nextDest = input.KEY.N,
    selDest = input.KEY.G,
    toggleUI = input.KEY.V,
    startRecord = input.KEY.J,
    lockMovement = input.KEY.Y,
    playBackRecord = input.KEY.K,
    toggleCollision = input.KEY.I,
}
local function drawUI()
    if buttonsAndInfo then
        buttonsAndInfo:destroy()
    end
    if not airshipMode then
        return
    end
    local buttonTable = {}
    if not useUI then
        table.insert(buttonTable, string.format("Toggle Info UI:  %s", input.getKeyName(keys.toggleUI)))
    else
        table.insert(buttonTable,
            string.format("Move Airship Forward and Backwards:  %s, %s", input.getKeyName(keys.MoveForward),
                input.getKeyName(keys.MoveBackwards)))
        table.insert(buttonTable,
            string.format("Rotate Airship Left and Right: %s, %s", input.getKeyName(keys.RotateMinus),
                input.getKeyName(keys.RotatePlus)))
        table.insert(buttonTable,
            string.format("Move Airship Left and Right:  %s, %s", input.getKeyName(keys.MoveLeft),
                input.getKeyName(keys.MoveRight)))
        table.insert(buttonTable,
            string.format("Move Airship Up and Down:  %s, %s", input.getKeyName(keys.MoveUp), input.getKeyName(keys.MoveDown)))
        table.insert(buttonTable, string.format("Change Airship Speed:  %s", input.getKeyName(keys.ChangeSpeed)))
        table.insert(buttonTable, string.format("Switch Camera Mode:  %s", input.getKeyName(keys.changeStaticMode)))
        table.insert(buttonTable, string.format("Toggle Info UI:  %s", input.getKeyName(keys.toggleUI)))
        --table.insert(buttonTable, string.format("Toggle Recording:  %s", input.getKeyName(keys.startRecord)))
    -- table.insert(buttonTable, string.format("Playback Recording:  %s", input.getKeyName(keys.playBackRecord)))
        table.insert(buttonTable, string.format("Lock Movement:  %s", input.getKeyName(keys.lockMovement)))
    -- table.insert(buttonTable, string.format("Start Travel to Selected Destination:  %s", input.getKeyName(keys.selDest)))
        table.insert(buttonTable, string.format("Engage/Disengage Airship Control:  %s", input.getKeyName(keys.Mount)))
        table.insert(buttonTable, string.format("Toggle Ship Collision:  %s", input.getKeyName(keys.toggleCollision)))
    end
    buttonsAndInfo = uiUtil.renderItemChoice(buttonTable, 0.0, 0.01)
end
local function getPositionBehind(pos, rot, distance, direction)
    local currentRotation = -rot
    local angleOffset = 0

    if direction == "north" then
        angleOffset = math.rad(90)
    elseif direction == "south" then
        angleOffset = math.rad(-90)
    elseif direction == "east" then
        angleOffset = 0
    elseif direction == "west" then
        angleOffset = math.rad(180)
    else
        error("Invalid direction. Please specify 'north', 'south', 'east', or 'west'.")
    end

    currentRotation = currentRotation - angleOffset
    local obj_x_offset = distance * math.cos(currentRotation)
    local obj_y_offset = distance * math.sin(currentRotation)
    local obj_x_position = pos.x + obj_x_offset
    local obj_y_position = pos.y + obj_y_offset
    return util.vector3(obj_x_position, obj_y_position, pos.z)
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(math.rad(z))
        return rotate
    end
end
local function getAirship()
    if (airshipOb ~= nil) then
        return
    end
    for index, value in ipairs(nearby.activators) do
        if value.recordId == "aeth_ship" then
            airshipOb = value
            return
        end
    end
end

local function actorCheck()
    local actorData = {}
    for index, actor in ipairs(nearby.actors) do
       local  result = nearby.castRay(actor.position,util.vector3(actor.position.x,actor.position.y,actor.position.z - 1000),             { ignore = actor })

       if result.hitObject then
        table.insert(actorData,{actor = actor,object = result.hitObject})
       end
    end
    core.sendGlobalEvent("ActorCheckShip",actorData)
end
local function POVAirship()
    actorCheck()
    camera.setMode(camera.MODE.Static)
    input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
    airshipMode = true
end
local rOffset = 0
local airshipSpeed = {
    slow = { forward = 10, rot = 0.1, vert = 6, rotspeed = 1, },
    medium = { forward = 50, rot = 0.1, vert = 12, rotspeed = 3 },
    fast = { forward = 100, rot = 0.1, vert = 20, rotspeed = 6 }
}
local speed = airshipSpeed.slow
local wasSpeedChanged
local function changeSpeed()
    if (speed == airshipSpeed.fast) then
        speed = airshipSpeed.slow
        ui.showMessage("Speed: Slow")
    elseif speed == airshipSpeed.slow then
        speed = airshipSpeed.medium
        ui.showMessage("Speed: Medium")
    elseif speed == airshipSpeed.medium then
        speed = airshipSpeed.fast
        ui.showMessage("Speed: Fast")
    end
end
local ASKP = false

local locDat = storage.globalSection("airshipLocations")
local selDest = nil
local function saveData()
    local data = locDat:get("locationData")
    local next = false
    for index, value in pairs(data) do
        local rz = value.shipRot:getAnglesZYX()
        local line = string.format("{infoName = '%s',px = %.2f, py = %.2f, pz = %.2f,pr =  %.2f},", value.infoName,
            value.shipLoc.x, value.shipLoc.y, value.shipLoc.z, rz)

    end
end
local function onKeyPress(k)
    if k.code == keys.Mount and inControlRange() then
        if airshipMode then
            camera.setMode(camera.MODE.FirstPerson)
            input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
            airshipMode = false
            ASKP = true
            drawUI()
            core.sendGlobalEvent("lockShipObjectx", false)
            core.sendGlobalEvent("showLadders")
        elseif airshipOb and ownedShips[airshipOb.id] then
            POVAirship()
            drawUI()
            core.sendGlobalEvent("lockShipObjectx", true)
        end
    end
    if airshipMode then
        local keyData = {}
        for index, value in pairs(keys) do
            keyData[index] = { keyName = index, pressed = input.isKeyPressed(value) }
        end
        core.sendGlobalEvent("airshipKeysOnPressed", { keyData = keyData })
    end
    if k.code == keys.toggleUI and airshipMode then
        useUI = not useUI
        drawUI()
    elseif k.code == keys.changeStaticMode and airshipMode then
        if airshipMode then
            if camera.getMode() == camera.MODE.Static then
                camera.setMode(camera.MODE.FirstPerson)
            else
                camera.setMode(camera.MODE.Static)
            end
        end
    elseif k.code == keys.selDest and selDest ~= nil then
        core.sendGlobalEvent("navToDest", selDest)
        ui.showMessage(selDest)
    elseif k.code == keys.startRecord then
        if not airshipOb then
            ui.showMessage("No ship object loaded")
        else
            if not recordState then
                core.sendGlobalEvent("startRecording", airshipOb.id)
                ui.showMessage("Recording Started")
            else
                core.sendGlobalEvent("stopRecording", airshipOb.id)
            end
            recordState = not recordState
        end
    elseif k.code == keys.playBackRecord then
        if not airshipOb then
            ui.showMessage("No ship object loaded")
        else
            if not recordState then
                core.sendGlobalEvent("startPlayback", airshipOb.id)
                ui.showMessage("Playback Started")
            else
            end
            recordState = not recordState
        end
    elseif k.code == keys.TPToExit and airshipMode then
        core.sendGlobalEvent("TPToExit")
    end
end
local rotationAmount = 0.2
local function onFrame(dt)
    if (dt == 0) then
        return
    else
    end
    local multiplier = 100
    local realSpeed = {
        forward = (speed.forward * dt) * multiplier,
        rot = speed.rot * dt,
        vert = speed.vert * dt * multiplier,
        rotspeed = speed.rotspeed * dt * multiplier
    }
    -- print(realSpeed.forward, speed.forward, dt)
    if airshipOb == nil then
        return
    end
    local useOffset   = rOffset * 0.01
    local newPos      = airshipOb.position
    local actRot      = airshipOb.rotation:getAnglesZYX()
    local angleChange = 0
    -- newPos = getPositionBehind(newPos, actRot, speed, "north")

    --Cast to ground and adjust height accordingly
    local result = nearby.castRay(newPos, util.vector3(newPos.x, newPos.y, newPos.z - 512), { collisionType=nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.Water })
    local adjustedNewPos = newPos
    -- if (result and result.hit) then
    --     adjustedNewPos = util.vector3(newPos.x, newPos.y, result.hitPos.z + 512)
    -- end

    if airshipMode then
        rOffset = rOffset + -input.getMouseMoveX()
        local keyData = {}
        if input.isKeyPressed(keys.RotateMinus) then
            --  actRot = actRot - realSpeed.rot
            -- core.sendGlobaleEvent("moveAirshipEvent", { ob = airshipOb, position = airshipOb.position, rotationZ = actRot })
            -- core.sendGlobalEvent("rotateObjects", -1)
            --  angleChange = -rotationAmount
        elseif input.isKeyPressed(keys.RotatePlus) then
            -- actRot = actRot + realSpeed.rot
            --core.sendGlobalEvent("moveAirshipEvent", { ob = airshipOb, position = airshipOb.position, rotationZ = actRot })
            --  core.sendGlobalEvent("rotateObjects", 1)
            --  angleChange = rotationAmount
        end
        if input.isKeyPressed(keys.MoveForward) then
            -- newPos = getPositionBehind(newPos, actRot, realSpeed.forward, "north")
            -- core.sendGlobalEvent("moveAirshipEvent", { ob = airshipOb, position = newPos, rotationZ = actRot })
        elseif input.isKeyPressed(keys.MoveBackwards) then
            --   newPos = getPositionBehind(newPos, actRot, realSpeed.forward, "south")
            --  core.sendGlobalEvent("moveAirshipEvent", { ob = airshipOb, position = newPos, rotationZ = actRot })
        end
        if input.isKeyPressed(keys.MoveLeft) then
            --   newPos = getPositionBehind(newPos, actRot, realSpeed.forward, "east")
            --  core.sendGlobalEvent("moveAirshipEvent", { ob = airshipOb, position = newPos, rotationZ = actRot })
        elseif input.isKeyPressed(keys.MoveRight) then
            --  newPos = getPositionBehind(newPos, actRot, realSpeed.forward, "west")
            --  core.sendGlobalEvent("moveAirshipEvent", { ob = airshipOb, position = newPos, rotationZ = actRot })
        end
        if input.isKeyPressed(keys.MoveUp) then
            -- newPos = util.vector3(newPos.x, newPos.y, newPos.z + realSpeed.vert)
            --  core.sendGlobalEvent("moveAirshipEvent", { ob = airshipOb, position = newPos, rotationZ = actRot })
        elseif input.isKeyPressed(keys.MoveDown) then
            --newPos = util.vector3(newPos.x, newPos.y, newPos.z - realSpeed.vert)
            --
        end
        if input.isKeyPressed(keys.ChangeSpeed) then
            -- if (not wasSpeedChanged) then
            --      wasSpeedChanged = true
            --      changeSpeed()
            -- end
        elseif input.isKeyPressed(keys.Mount) then

        else
            wasSpeedChanged = false
            ASKP = false
        end

        if camera.getMode() == camera.MODE.Static then
            local pos = util.vector3(adjustedNewPos.x, adjustedNewPos.y, adjustedNewPos.z + 800)
            local camPos = getPositionBehind(pos, actRot + useOffset, 2800, "south")
            camera.setStaticPosition(camPos)
            local rot = actRot + math.rad(180) + useOffset
            camera.setYaw(rot)
            camera.setPitch(0.4)
        end
    else
        if input.isKeyPressed(keys.Mount) then
            ASKP = true
            return
        else
            ASKP = false
        end
    end

    if adjustedNewPos ~= airshipOb.position or angleChange ~= 0 then
        core.sendGlobalEvent("moveAirshipEvent",
            { rot = angleChange * realSpeed.rotspeed, ob = airshipOb, position = adjustedNewPos, rotationZ = actRot })
    end
end
local function endsWith(str, suffix)
    return suffix == "" or string.sub(str, -string.len(suffix)) == suffix
end
local function getDifferentPart(str, separator)
    local parts = {}
    for part in str:gmatch("[^" .. separator .. "]+") do
        table.insert(parts, part)
    end

    if #parts >= 3 then
        return parts[3]
    else
        return nil -- or an empty string, depending on your needs
    end
end
local function hasKey(id)
local isGodMode = debug.isGodMode()

if isGodMode then return true end

return types.Actor.inventory(self):countOf(id) > 0 
end
local function compassActivatex(recordId)
    if ownedShips[recordId] then

        POVAirship()
        drawUI()
        core.sendGlobalEvent("lockShipObjectx", true)

    elseif recordId == "aeth_ae_compass_airship" and not ownedShips[recordId] and not hasKey("aeth_shipkey_3") == 0 then
        ui.showMessage("You don't have control of this ship.")
    elseif recordId == "aeth_ae_compass_airship" and not ownedShips[recordId] and hasKey("aeth_shipkey_3") then
        ownedShips[recordId] = true
        ownedShips[airshipOb.id] = true
        ui.showMessage("You take control of the ship")
        POVAirship()
        drawUI()
        core.sendGlobalEvent("lockShipObjectx", true)
        core.sendGlobalEvent("hideLadders")
    elseif recordId == "aeth_ae_compass_silver" and not ownedShips[recordId] and not hasKey("aeth_shipkey_1") == 0 then
        ui.showMessage("You don't have control of this ship.")
    elseif recordId == "aeth_ae_compass_silver" and not ownedShips[recordId] and hasKey("aeth_shipkey_1") then
        ownedShips[recordId] = true
        ownedShips[airshipOb.id] = true
        ui.showMessage("You take control of the ship")
        POVAirship()
        drawUI()
        core.sendGlobalEvent("lockShipObjectx", true)
        core.sendGlobalEvent("hideLadders")
    elseif recordId == "aeth_ae_compass_steam" and not ownedShips[recordId] and not hasKey("aeth_shipkey_2") == 0 then
        ui.showMessage("You don't have control of this ship.")
    elseif recordId == "aeth_ae_compass_steam" and not ownedShips[recordId] and hasKey("aeth_shipkey_2") then
        ownedShips[recordId] = true
        ownedShips[airshipOb.id] = true
        ui.showMessage("You take control of the ship")
        POVAirship()
        drawUI()
        core.sendGlobalEvent("lockShipObjectx", true)
    end
end
-- Test the function
local function collisionCheck(data)
    local hit = false
    for index, value in pairs(data) do
        if endsWith(index, "inner") then
            local idNum = getDifferentPart(index, "_")
            local outer = "aeth_collisionchecker_" .. idNum .. "_outer"
            if data[outer] then
                local rayC = nearby.castRay(data[index], data[outer])
                if rayC.hit then
                    hit = true
                    if rayC.hitObject then
                        if rayC.hitObject.recordId ~= "aeth_silvercascade_ship" and rayC.hitObject.recordId ~= "aeth_dship_x" then
                            core.sendGlobalEvent("ShipHit")
                        end
                    else
                        core.sendGlobalEvent("ShipHit")
                    end
                end
            end
        end
    end
end
--TODO:
--Build correct airship
--Save objects
--Smooth movement, can rotate and move at once
--Docking locations, automatic

--Reenable SS that we aren't replacing
--Wait to do the ones that are loaded until the object is not in sight or we go into an interior
local knownObject = nil
local function onSave()
    return { ownedShips = ownedShips }
end
local function onUpdate(dt)
    local hit = nearby.castRay(self.position, util.vector3(self.position.x, self.position.y, self.position.z - 1000))
    if hit and hit.hitObject and not airshipMode then
        if knownObject ~= hit.hitObject.id then
            knownObject = hit.hitObject.id
            core.sendGlobalEvent("ChangeShipObject", knownObject)
        end
    elseif not airshipMode and knownObject then
        knownObject = nil
        core.sendGlobalEvent("ChangeShipObject", nil)
    elseif hit and not airshipMode and not hit.hitObject and knownObject then
        knownObject = nil
        core.sendGlobalEvent("ChangeShipObject", nil)
    end
    if airshipMode then
        local keyData = {}
        for index, value in pairs(keys) do
            keyData[index] = { keyName = index, pressed = input.isKeyPressed(value) }
        end
        core.sendGlobalEvent("airshipKeysPressedx", { keyData = keyData, dt = dt })
    else
        local keyData = {}
        for index, value in pairs(keys) do
            keyData[index] = { keyName = index, pressed = false }
        end
        core.sendGlobalEvent("airshipKeysPressedx", { keyData = keyData, dt = dt })
    end
end
local function onConsoleCommand(mode, command, selectedObject)
    local words = {}


    for word in command:gmatch("%S+") do
        table.insert(words, word)
    end
    local restOf = string.sub(command, string.len(words[1]) + 2)
    if words[1] == "shippos" or words[1] == "luashippos" then
        core.sendGlobalEvent("saveLocation", restOf)
        WriteToConsole("Setting val:" .. restOf)
    elseif words[1] == "buildship" or words[1] == "buildairship" or words[1] == "luabuildship" or words[1] == "luabuildairship" then
        core.sendGlobalEvent("buildAirship")
    elseif words[1] == "savedata" then
        saveData()
    end
end
local function onInit()
    core.sendGlobalEvent("DNAirshipPlayerx", self)
end
local function AOSmessage(message)
    ui.showMessage(message)
end
return {
    interfaceName = "Aeth_PlayerControls",
    interface = {
        version = 1,
        onInit = onInit,
        POVAirship = POVAirship,

    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onInit = onInit,
        onUpdate = onUpdate,
        onFrame = onFrame,
        onKeyPress = onKeyPress,
        onConsoleCommand = onConsoleCommand,
    },
    eventHandlers = {
        POVAirship      = POVAirship,
        setAirshipOb    = setAirshipOb,
        AOSmessage      = AOSmessage,
        collisionCheck  = collisionCheck,
        compassActivatex = compassActivatex,
        PlaySound_AO = function (soundId)
            ambient.playSound(soundId)
        end
    }
}
