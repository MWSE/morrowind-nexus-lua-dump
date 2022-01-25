require('ss20.roomRegistration.mcm')
local common = require('ss20.roomRegistration.common')
local config = common.config
local modName = config.modName
local mcmConfig = common.mcmConfig


local function log(message, ...)
    if config.debug then
        local output = string.format("[%s] %s", modName, tostring(message):format(...) )
        mwse.log(output)
    end
end

--[[

    Room Registration Functions
]]
local function doSkipRef(ref)
    return (
        ref == tes3.player
        or ref.disabled == true
        or ref.deleted == true
    )
end

local function registerRoom()
    local cell = tes3.player.cell
    log("Registering %s", cell.id)
    mcmConfig.rooms[cell.id] = {}
    for ref in cell:iterateReferences() do
        if doSkipRef(ref) then
            log("SKIPPING %s", ref.object.id)
        else
            --log("Registering %s", ref.object.id)
            local obj = ref.baseObject and ref.baseObject or ref.object
            table.insert(mcmConfig.rooms[cell.id], {
                id = obj.id,
                position = {
                    x = ref.position.x,
                    y = ref.position.y,
                    z = ref.position.z
                },
                orientation = {
                    ref.orientation.x,
                    ref.orientation.y,
                    ref.orientation.z
                },
                scale = ref.scale
            })
        
        end
    end
    mwse.saveConfig(config.modName, mcmConfig)
end

local function rotateAboutOrigin(ref, zRot)
    --Rotate around the 0,0,0 origin
    local m = tes3matrix33.new()
    m:fromEulerXYZ(0, 0, zRot)

    local t = ref.sceneNode.worldTransform
    ref.position = m * t.translation
    ref.orientation = m * t.rotation
end

local function placeItem(data, target)
    --Starting position around 0,0,0 for matrix rotation
    local placedRef = tes3.createReference{
        object = data.id,
        position = {
            data.position.x,
            data.position.y,
            data.position.z,
        },
        orientation = data.orientation,
        cell = target.cell
    }
    placedRef.scale = data.scale

    rotateAboutOrigin(placedRef, target.orientation.z)

    local m1 = tes3matrix33.new()
    m1:fromEulerXYZ(data.orientation)
    local m2 = placedRef.sceneNode.worldTransform
    placedRef.orientation = m1 * m2.rotation


    placedRef.position = {
        placedRef.position.x + target.position.x,
        placedRef.position.y + target.position.y,
        placedRef.position.z + target.position.z,
    }
    if placedRef.object.objectType == tes3.objectType.light then
        
        timer.delayOneFrame(function()
            log("Turning lights on")
            common.onLight(placedRef)
        end)
    end
    log("Placed %s", data.id)

end

local function placeRoom(room, target)
    log("Placing room")
    for _, data in ipairs(room) do
        local obj = tes3.getObject(data.id)
        
        if obj and obj.objectType ~= tes3.objectType.light then
            placeItem(data, target)
        end
    end

    --place lights last I guess
    for _, data in ipairs(room) do
        local obj = tes3.getObject(data.id)
        if obj and  obj.objectType == tes3.objectType.light then
            placeItem(data, target)
        end
    end


    if target.disable then
        log("disabling %s", target.object.id)
        target:disable()
    else
        log("%s does not have a disable function", target.object.id)
    end
    log("Finished placing room")
end

local function loadRoom()
    local cell = tes3.player.cell
    local room = mcmConfig.rooms[cell.id]
    if room then
        --clear existing room
        for ref in cell:iterateReferences() do
            if ref ~= tes3.player then
                log("Disabling %s", ref.object.id)
                ref:disable()
                mwscript.setDelete{ reference = ref }
            end
        end
        
        timer.delayOneFrame(function()
            placeRoom(room, {
                cell = tes3.player.cell,
                position = tes3vector3.new(0,0,0),
                orientation = tes3vector3.new(0,0,0)
            })
        end)
        
    else
        log("No config found for %s", cell.id)
    end
end

local function selectPlaceRoom(target)
    local buttons = {}
    for name, room in pairs(mcmConfig.rooms) do
        table.insert(buttons, {
            text = name,
            callback = function() 
                placeRoom(room, target)
            end
        })
    end
    table.insert(buttons, { text = "Cancel" })
    common.messageBox{
        message = "Select Room to Place",
        buttons = buttons
    }
end


local function openItemMenu()

end

--[[
    Menu
]]
local function activateMenu(e)
    if tes3ui.menuMode() then return end
    if common.keyPressed(e, mcmConfig.menuKey) then
        local buttons = {}
        --register room button
        local cell = tes3.player.cell
        if cell.isInterior then
            table.insert(buttons, {
                text = string.format("Register %s", cell.id),
                callback = registerRoom
            })
        end

        --Load room button
        if mcmConfig.rooms[cell.id] then
            table.insert(buttons, {
                text = string.format("Load config for %s", cell.id),
                callback = loadRoom
            })
        end

        --place room button
        local rayTest = tes3.rayTest({
            position = tes3.getPlayerEyePosition(),
            direction = tes3.getPlayerEyeVector(),
            ignore = { tes3.player },
        })
        local target = rayTest and rayTest.reference
        if target then
            table.insert(buttons, {
                text = string.format("Place Room at %s", target.object.id),
                callback = function()
                    selectPlaceRoom(target)
                end
            })
        end
        table.insert(buttons, { text = "cancel" })

        table.insert(buttons, {
            text = "Open Item Menu",
            callback = openItemMenu
        })

        common.messageBox{
            message = "Room Registration",
            buttons = buttons,
        }
    end
end
event.register("keyDown", activateMenu)

