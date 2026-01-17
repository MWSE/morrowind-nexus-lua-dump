local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')

local MODNAME = "Pilferer"
local lastCellId = nil
local wasSneaking = false

local v2 = util.vector2
local playerSection = storage.playerSection(MODNAME)

local saveData = {}
local hudEye = nil
local eyeGraphic = nil

local EYE_SIZE = 48
local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size
EYE_COLOR = util.color.hex("caa560")

local function createEyeHud()
    -- Load size from storage
    local storedSize = playerSection:get("eyeSize")
    if storedSize then
        EYE_SIZE = storedSize
    end
    
    local pos = playerSection:get("eyePos")
    if not pos then
        pos = v2(hudLayerSize.x * 0.05, hudLayerSize.y * 0.05)
    else
        pos = v2(pos.x, pos.y)
    end
    
    if hudEye then
        hudEye:destroy()
    end
    
    pos = v2(
        math.max(0, math.min(pos.x, hudLayerSize.x - EYE_SIZE)),
        math.max(0, math.min(pos.y, hudLayerSize.y - EYE_SIZE))
    )
    
    hudEye = ui.create({
        type = ui.TYPE.Container,
        layer = 'HUD',
        name = "pilfererEye",
        props = {
            anchor = v2(0, 0),
            position = pos,
            alpha = saveData.isDetected and 0.9 or 0
        },
        content = ui.content {},
        userData = {
            windowStartPosition = pos,
        }
    })
    
    hudEye.layout.events = {
        mousePress = async:callback(function(data, elem)
            if data.button == 1 then
                if not elem.userData then
                    elem.userData = {}
                end
                elem.userData.isDragging = true
                elem.userData.dragStartPosition = data.position
                elem.userData.windowStartPosition = hudEye.layout.props.position or v2(0, 0)
            end
            hudEye:update()
        end),
        
        mouseRelease = async:callback(function(data, elem)
            if elem.userData then
                elem.userData.isDragging = false
            end
            hudEye:update()
        end),
        
        mouseMove = async:callback(function(data, elem)
            if elem.userData and elem.userData.isDragging then
                local deltaX = data.position.x - elem.userData.dragStartPosition.x
                local deltaY = data.position.y - elem.userData.dragStartPosition.y
                local newPosition = v2(
                    elem.userData.windowStartPosition.x + deltaX,
                    elem.userData.windowStartPosition.y + deltaY
                )
                playerSection:set("eyePos", {x = newPosition.x, y = newPosition.y})
                hudEye.layout.props.position = newPosition
                hudEye:update()
            end
        end),
    }
    
    eyeGraphic = {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = "textures/Pilferer/eye.png" },
            tileH = false,
            tileV = false,
            size = v2(EYE_SIZE, EYE_SIZE),
			color = EYE_COLOR,
			
        },
    }
    hudEye.layout.content:add(eyeGraphic)
end

local function updateEyeVisibility()
    if hudEye then
        hudEye.layout.props.alpha = (saveData.isDetected and wasSneaking) and 0.9 or 0
        hudEye:update()
    end
end

local function onMouseWheel(vertical)
    if hudEye and hudEye.layout.userData and hudEye.layout.userData.isDragging then
        EYE_SIZE = math.max(16, math.min(128, EYE_SIZE + vertical * 4))
        playerSection:set("eyeSize", EYE_SIZE)
        eyeGraphic.props.size = v2(EYE_SIZE, EYE_SIZE)
        hudEye:update()
    end
end

local function onLoad(data)
    saveData = data or {}
    saveData.isDetected = saveData.isDetected or false
    createEyeHud()
end

local function onSave()
    return saveData
end

local function onUpdate()
    local currentCell = self.cell
    if not currentCell then return end

    local currentCellId = currentCell.id

    if lastCellId and currentCellId ~= lastCellId then
        core.sendGlobalEvent("Pilferer_cellChanged", self.object)
        -- Reset detection on cell change
        saveData.isDetected = false
        updateEyeVisibility()
    end

    lastCellId = currentCellId
    
    -- Check sneak state
    local isSneaking = self.controls.sneak
    
    if isSneaking ~= wasSneaking then
        wasSneaking = isSneaking
        updateEyeVisibility()
        
        if isSneaking and saveData.isDetected then
            ui.showMessage("You are being watched! Sneaking won't help now.")
        end
    end
end

local function onGreetingReceived(data)
    local name = data and data.name or "someone"
    ui.showMessage(string.format("You were spotted by %s!", name))
    print(string.format("[%s] You were greeted by %s - you've been detected!", MODNAME, name))
    saveData.isDetected = true
    updateEyeVisibility()
end

local function onTheftWitnessed(data)
    local stolenValue = data and data.stolenValue or 0
    ui.showMessage(string.format("Your theft of %d gold has been witnessed! Bounty added.", stolenValue))
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
        onMouseWheel = onMouseWheel,
    },
    eventHandlers = {
        Pilferer_greetingReceived = onGreetingReceived,
        Pilferer_theftWitnessed = onTheftWitnessed,
    },
}