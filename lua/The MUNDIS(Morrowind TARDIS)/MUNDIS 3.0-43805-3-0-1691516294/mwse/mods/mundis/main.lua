local modName = "Mundis"
local dataHandler = require("mundis.mundisdatahandler")
local teleportEffect = require("mundis.teleport_effect")
local cheatSystem = require("mundis.mundischeat_objects")
local settings = require("mundis.mundissettings")
local powerSystem = require("mundis.mundis_powersystem")
local sorter = require("mundis.util.sorter")
local merchants = require("mundis.mundis_merchants")
local mundis = {}
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
    return tes3vector3.new(obj_x_position, obj_y_position, pos.z)
end
local function getBoxExitPos(pos, rot, direction)
    local offset = 0
    if not direction then
        direction = "north"
        offset = 180
    else

    end
    local targetPos = getPositionBehind(pos, rot, 150, direction)
    return targetPos, math.rad(offset) + rot
end
function mundis.fixDoorData()
    local boxRef = tes3.getReference("mundis_3_extBox")
    local intDoor = tes3.getReference("mundis_3_exitDoor_door")
    local extDoor = tes3.getReference("mundis_3_enterDoor")
    if not intDoor then return end

    for index, dataItem in ipairs(tes3.player.data.Mundis.LocData) do
        if (tes3.player.data.Mundis.currentDest == dataItem.id) then
            -- local angleFixed = dataItem.rz
            -- print(dataItem.cell)
            -- print(angleFixed)
            local extPos = tes3vector3.new(dataItem.px, dataItem.py, dataItem.pz)
            local doorPos, doorAngle = getBoxExitPos(extPos, dataItem.rotation)
            --  local doorPos = tes3vector3.new(dataItem.dx, dataItem.dy, dataItem.dz)
            --local doorAngle = dataItem.drz
            local extRot = tes3vector3.new(0, 0, dataItem.rotation)
            -- print(dataItem.cell)
            --  print(angleFixed)
            -- angleFixed = doorAngle - math.round(180)
            tes3.setDestination({
                reference = intDoor,
                position = doorPos,
                orientation = tes3vector3.new(0, 0, doorAngle),
                cell = dataItem.cell
            })
            tes3.positionCell({
                reference = boxRef,
                cell = dataItem.cell,
                position = extPos,
                orientation = extRot
            })
            tes3.positionCell({
                reference = extDoor,
                cell = dataItem.cell,
                position = extPos,
                orientation = extRot
            })
            tes3.positionCell({
                reference = boxRef,
                cell = dataItem.cell,
                position = extPos,
                orientation = extRot
            })
            tes3.positionCell({
                reference = extDoor,
                cell = dataItem.cell,
                position = extPos,
                orientation = extRot
            })
            tes3.positionCell({
                reference = intDoor,
                cell = "MUNDIS Control Room",
                position = tes3vector3.new(6262.600, 2427.532, 10718.883),
                orientation = tes3vector3.new(0, 0,
                    math.rad(179.2))
            })
            -- extDoor:disable()
            --   boxRef:disable()
            --   intDoor:enable()
            --   extDoor:enable()


            --   boxRef:enable()
            --  intDoor:enable()
            return
        end
    end
end

function mundis.spellCasted(e)
    if e.source.id == "aa_summonspell" then
        local chargeCount = powerSystem.getChargeCount()
        if chargeCount < tes3.player.data.Mundis.powerData.summonCost then
            tes3.messageBox(string.format("You don't have enough charges. You currently have %d, but you need %d",
                chargeCount,
                tes3.player.data.Mundis.powerData.summonCost))
            return
        end
        if  tes3.player.data.Mundis.legacySummon then
        for index, dataItem in ipairs(tes3.player.data.Mundis.LocData) do
            if dataItem.cell:lower() == e.caster.cell.name:lower() then
                teleportEffect.startTeleport(dataItem.id, mundis)
                return
            end
        end
    end
        local newPosition, newRotation = getBoxExitPos(tes3.player.position,
            tes3.player.orientation.z, "south")
        local newData = dataHandler.interface.addMundisLocation(newPosition, newRotation,
            tes3.player.cell.name)
        powerSystem.incrementChargeCount(-tes3.player.data.Mundis.powerData.summonCost)
        teleportEffect.startTeleport(newData.id, mundis)
    end
    print(e.source.id)
end

local buttonToChange = nil
local function clickOKButton()
    if buttonToChange then
        tes3.player.data.Mundis.buttonData[buttonToChange] = tes3.player.data.Mundis.currentDest
        tes3.getObject(buttonToChange).name = dataHandler.interface.getCellFromId(tes3.player.data.Mundis.currentDest)
        buttonToChange = nil
    end
end
local buttonDest = nil
function mundis.activateObject(e)
    local id = e.target.object.id
    if not tes3.player.data.Mundis.buttonDest then
        tes3.player.data.Mundis.buttonDest = tes3.player.data.Mundis.currentDest
    end
    if tes3.player.data.Mundis.buttonData[e.target.object.id] then
        if not tes3.mobilePlayer.isSneaking and tes3.player.data.Mundis.buttonData[e.target.object.id] ~= -1 then
            local chargeCount = powerSystem.getChargeCount()
            if chargeCount < tes3.player.data.Mundis.powerData.buttonCost then
                tes3.messageBox(string.format("You don't have enough charges. You currently have %d, but you need %d",
                    chargeCount,
                    tes3.player.data.Mundis.powerData.buttonCost))
                return
            end
            powerSystem.incrementChargeCount(-tes3.player.data.Mundis.powerData.buttonCost)
            teleportEffect.startTeleport(tes3.player.data.Mundis.buttonData[e.target.object.id], mundis)
        else
            if tes3.player.data.Mundis.buttonData[e.target.object.id] ~= -1 then
                local buttons = {
                    { text = "Yes", callback = clickOKButton },
                    { text = "No" }
                }
                buttonToChange = e.target.object.id
                tes3ui.showMessageMenu({
                    header = "Currently set to:" ..
                    dataHandler.interface.getCellFromId(tes3.player.data.Mundis.buttonData[e.target.object.id]),
                    message = "Do you want to change this button to " ..
                    dataHandler.interface.getCellFromId(tes3.player.data.Mundis.currentDest) .. "?",
                    buttons = buttons
                })
            else
                local buttons = {
                    { text = "Yes", callback = clickOKButton },
                    { text = "No" }
                }
                buttonToChange = e.target.object.id
                tes3ui.showMessageMenu({
                    message = "Do you want to change this button to " ..
                    dataHandler.interface.getCellFromId(tes3.player.data.Mundis.currentDest) .. "?",
                    buttons = buttons
                })
            end
        end
    elseif id == "zhac_button_mundis_prev" then
        local lastId = buttonDest
        for index, dataItem in ipairs(tes3.player.data.Mundis.LocData) do
            if (dataItem.id == tes3.player.data.Mundis.buttonDest and dataItem.visited == true) then
                if lastId then
                    tes3.player.data.Mundis.buttonDest = lastId.id

                    tes3.getObject("zhac_button_mundis_curr").name = dataHandler.interface.getCellFromId(tes3.player
                    .data.Mundis.buttonDest)
                    tes3.player.data.Mundis.buttonData["zhac_button_mundis_curr"] = tes3.player.data.Mundis.buttonDest
                    tes3.messageBox(string.format("%g: %s", index - 1, lastId.cell))
                end

                return
            else
                lastId = dataItem
            end
        end
        -- tes3.player.data.Mundis.buttonDest = tes3.player.data.Mundis.currentDest
    elseif id == "zhac_button_mundis_next" then
        local next = false
        local lastId = buttonDest
        for index, dataItem in ipairs(tes3.player.data.Mundis.LocData) do
            if (dataItem.id == tes3.player.data.Mundis.buttonDest) and dataItem.visited == true then
                next = true
            elseif next then
                tes3.player.data.Mundis.buttonDest = dataItem.id
                tes3.getObject("zhac_button_mundis_curr").name = dataHandler.interface.getCellFromId(tes3.player.data
                .Mundis.buttonDest)
                tes3.player.data.Mundis.buttonData["zhac_button_mundis_curr"] = tes3.player.data.Mundis.buttonDest
                tes3.messageBox(string.format("%g: %s", index + 1, dataItem.cell))
                return
            end
        end
        -- tes3.player.data.Mundis.buttonDest = tes3.player.data.Mundis.currentDest
    end
end

function mundis.gameLoaded(e)
    dataHandler.engineHandlers.onInit()
    mundis.fixDoorData()
    --merchants.placeMerchantsInWorld()
end

local function sneakDown(e)
    if not (e.keyCode == tes3.getInputBinding(tes3.keybind.sneak).code) then
        return
    end

    if tes3.menuMode() then
        return
    end
    dataHandler.interface.initButtons(true)
end

local function sneakUp(e)
    if not (e.keyCode == tes3.getInputBinding(tes3.keybind.sneak).code) then
        return
    end

    if tes3.menuMode() then
        return
    end
    dataHandler.interface.initButtons(nil)
end
--event.register(tes3.event.keyDown, sneakDown)
--event.register(tes3.event.keyUp, sneakUp)
event.register(tes3.event.spellCasted, mundis.spellCasted)
event.register(tes3.event.loaded, mundis.gameLoaded)
event.register(tes3.event.activate, mundis.activateObject)
return mundis
