local input = require("openmw.input")
local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require('openmw.core')
local storage = require("openmw.storage")
local async = require("openmw.async")
local util = require("openmw.util")

local MapRenderer = require("scripts/DenyingProduct-Dynamic-Map/MapRenderer")
local playerSettings = storage.playerSection("DenyingProductDynamicMap")

-- Saved Data
local initialMapFrameSize
local initialButtonFrameSize
local initialMapFramePos
local initialButtonFramePos
local initialplayerGamePos

local DEADZONE = 0.25
local panSpeed = 800
local curZoomReset = 0.25
local ReplaceBuiltInMap = false

local mapReady = false

----------------------------------------------
-- Save and Load
----------------------------------------------
local function onSave()

    local state = MapRenderer.getState()
    return {
        playerGamePos = state.playerGamePos,
        mapFrameSize = state.mapFrameSize,
        buttonFrameSize = state.buttonFrameSize,
        mapFramePos = state.mapFramePos,
        buttonFramePos = state.buttonFramePos,
    }
end

local function onLoad(data)
    if not data then
        return
    end
    initialplayerGamePos = data.playerGamePos
    initialMapFrameSize = data.mapFrameSize
    initialButtonFrameSize = data.buttonFrameSize
    initialMapFramePos = data.mapFramePos
    initialButtonFramePos = data.buttonFramePos
end

----------------------------------------------
-- Get data from engine
----------------------------------------------

--get data from Global Script
local function DP_DM_fromGlobal(data)
    MapRenderer.initialize({
        mapFrameSize = initialMapFrameSize,
        buttonFrameSize = initialButtonFrameSize,
        mapFramePos = initialMapFramePos,
        buttonFramePos = initialButtonFramePos,
        playerGamePos = initialplayerGamePos,
        exteriorCells = data.exteriorCells,
        interiorCells = data.interiorCells
    })
    mapReady = true
end
core.sendGlobalEvent('DP_DM_sendPlayerCells', { actor = self.object })

----------------------------------------------
-- Settings
----------------------------------------------
I.Settings.registerPage{
    key = "DenyingProductDynamicMap",
    l10n = "none",
    name = "Dynamic Map",
    description = "DenyingProduct Dynamic Map."
}
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'none',
    key = "DynamicMap_OpenMapTrigger",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'none',
    key = "DynamicMap_OpenMapTriggerAlt",
})

I.Settings.registerGroup{
    key = "DenyingProductDynamicMap",
    page = "DenyingProductDynamicMap",
    l10n = "none",
    name = "Mod Options",
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = "OnlyShowDiscoveredMarkers",
            renderer = "checkbox",
            name = "Only Show Discovered Markers (Coming Soon)",
            description = "",
            default = true
        },
        {
            key = "FastTravelMode",
            renderer = "checkbox",
            name = "Only Show Discovered Travel Routes (Coming Soon)",
            description = "Only show paths between markers you have visited",
            default = true
        },
        {
            key = "ReplaceBuiltIn",
            renderer = "checkbox",
            name = "Replace Built-in Map",
            description = "Requires restart to disable",
            default = false
        },
        {
            key = "DynamicMap_OpenMapTrigger",
            renderer = "inputBinding",
            name = "Open Map Key",
            description = "",
            default="DynamicMap_OpenMapTriggerKey",
            argument = {
                type = "trigger",
                key = "DynamicMap_OpenMapTrigger"
            },
        },
        {
            key = "DynamicMap_OpenMapTriggerAlt",
            renderer = "inputBinding",
            name = "Open Map Key Alt",
            description = "",
            default="DynamicMap_OpenMapTriggerKeyAlt",
            argument = {
                type = "trigger",
                key = "DynamicMap_OpenMapTriggerAlt"
            },
        },
        {
            key = "OnlyOpenMapOutside",
            renderer = "checkbox",
            name = "Only Open Map Outside",
            description = "Uses last exterior position indoors",
            default = false
        },
        {
            key = "MaskInstalledMods",
            renderer = "checkbox",
            name = "Mask Installed Mods (Gray out not installed zones)",
            description = "Currently supports the following (April 2026 Versions)\n   *Solstheim Tomb of The Snow Prince\n   *Anthology Solstheim\n   *Tamriel Rebuilt\n   *Project Cyrodiil\n   *Skyrim: Home of the Nords",
            default = true
        },
        {
            key = "altFTColor",
            renderer = "checkbox",
            name = "Use Original Travel Route Colors",
            description = "Use Yellow/Red/Blue instead of the orange",
            default = false
        },
        {
            key = "PanSpeed",
            renderer = "number",
            name = "Map Pan Speed",
            description = "How fast to pan.",
            default = 800,
        },
    }
}
local bindingSection = storage.playerSection('OMWInputBindings')
if not bindingSection:get("DynamicMap_OpenMapTriggerKey") then
    bindingSection:set("DynamicMap_OpenMapTriggerKey", {
        device = 'keyboard',
        button = 16, -- M
        type = 'trigger',
        key = 'DynamicMap_OpenMapTrigger',
    })
end

if not bindingSection:get("DynamicMap_OpenMapTriggerKeyAlt") then
    bindingSection:set("DynamicMap_OpenMapTriggerKeyAlt", {
        device = 'controller',
        button = 4, -- select on controller
        type = 'trigger',
        key = 'DynamicMap_OpenMapTriggerAlt',
    })
end

input.registerTriggerHandler("DynamicMap_OpenMapTrigger", async:callback(function () MapRenderer.toggleMap(true,false) end))  
input.registerTriggerHandler("DynamicMap_OpenMapTriggerAlt", async:callback(function () MapRenderer.toggleMap(true,false) end))  


local function updateSettings()
    panSpeed = playerSettings:get("PanSpeed") 
    ReplaceBuiltInMap = playerSettings:get("ReplaceBuiltIn")
    MapRenderer.applySettings({
        onlyOpenMapOutside = playerSettings:get("OnlyOpenMapOutside"),
        maskInstalledMods = playerSettings:get("MaskInstalledMods"),
        altFTColor = playerSettings:get("altFTColor")
    })
    if(ReplaceBuiltInMap) then
        I.UI.registerWindow(
            "Map",
            function() MapRenderer.showMap(true,true) end,
            function() MapRenderer.hideMap(true) end
        )
    end
end
playerSettings:subscribe(async:callback(function(section, key) updateSettings() end))
updateSettings()

----------------------------------------------
-- Inputs
----------------------------------------------
local function panMapController(dt)
    local panAmount = util.vector2(0,0)

    -- Controller DPad
    if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadLeft)    then panAmount = util.vector2(panAmount.x + dt , panAmount.y) end
    if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadRight)   then panAmount = util.vector2(panAmount.x - dt , panAmount.y) end
    if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp)      then panAmount = util.vector2(panAmount.x, panAmount.y + dt ) end
    if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown)    then panAmount = util.vector2(panAmount.x, panAmount.y - dt ) end

    -- Controller analog
    local axisX = input.getAxisValue(input.CONTROLLER_AXIS.LeftX)
    local axisY = input.getAxisValue(input.CONTROLLER_AXIS.LeftY)
    if math.abs(axisX) > DEADZONE then panAmount = util.vector2(panAmount.x - axisX * dt , panAmount.y) end
    if math.abs(axisY) > DEADZONE then panAmount = util.vector2(panAmount.x, panAmount.y - axisY * dt ) end
        
    -- panspeed
    panAmount = util.vector2(panAmount.x * panSpeed, panAmount.y * panSpeed)

    if panAmount.x ~= 0 or panAmount.y ~= 0 then
        MapRenderer.pan(panAmount)
    end
end

local function panMapKBM(dt)
    local panAmount = util.vector2(0,0)

    -- Keyboard 
    if input.isKeyPressed(input.KEY.A) or input.isKeyPressed(input.KEY.LeftArrow)   then panAmount = util.vector2(panAmount.x + dt , panAmount.y) end
    if input.isKeyPressed(input.KEY.D) or input.isKeyPressed(input.KEY.RightArrow)  then panAmount = util.vector2(panAmount.x - dt , panAmount.y) end
    if input.isKeyPressed(input.KEY.W) or input.isKeyPressed(input.KEY.UpArrow)     then panAmount = util.vector2(panAmount.x, panAmount.y + dt ) end
    if input.isKeyPressed(input.KEY.S) or input.isKeyPressed(input.KEY.DownArrow)   then panAmount = util.vector2(panAmount.x, panAmount.y - dt ) end
  
    -- panspeed
    panAmount = util.vector2(panAmount.x * panSpeed, panAmount.y * panSpeed)

    -- Mouse drag (no pan speed)
    if input.isMouseButtonPressed(1) then
        local dx = input.getMouseMoveX()
        local dy = input.getMouseMoveY()
        if dx ~= 0 or dy ~= 0 then
            panAmount = util.vector2(panAmount.x + dx,panAmount.y + dy)
        end
    end

    if panAmount.x ~= 0 or panAmount.y ~= 0 then
        MapRenderer.pan(panAmount)
    end
end

local function zoomMapController(dt)
    --only allow zoom every 0.25s to prevent spam
    if(curZoomReset < 0.2)then
        curZoomReset = curZoomReset + dt
    else
        local axisY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
        if axisY > DEADZONE then
            curZoomReset = 0
            MapRenderer.zoom(false)
        elseif axisY < -DEADZONE then
            curZoomReset = 0
            MapRenderer.zoom(true)
        end
    end
end

local function zoomMapKBM(dt, zoomControl)
    --only allow zoom every 0.25s to prevent spam
    if(curZoomReset < 0.2)then
        curZoomReset = curZoomReset + dt
    else
        if zoomControl < 0 then
            curZoomReset = 0
            MapRenderer.zoom(false)
        elseif zoomControl > 0 then
            curZoomReset = 0
            MapRenderer.zoom(true)
        end
    end
end

local function resizeFrame()
    if not MapRenderer.isResizing() then return end
    local dx = input.getMouseMoveX()
    local dy = input.getMouseMoveY()
    MapRenderer.resize(dx,dy)
end

local function moveFrame()
    if not MapRenderer.isMoving() then return end
    local dx = input.getMouseMoveX()
    local dy = input.getMouseMoveY()
    MapRenderer.move(dx,dy)
end

local function checkIfShouldCloseMap()
    if(I.UI.getMode() ~= "Interface") then
        MapRenderer.hideMap(false)
    end
end

local function onUpdate()
    if(not mapReady) then return end

    local dt = core.getRealFrameDuration()
    --KBM requires Focus
    if(MapRenderer.canControl()) then
        panMapKBM(dt)
        zoomMapKBM(dt,0)
    end
    --controller 
    panMapController(dt)
    zoomMapController(dt)

    resizeFrame()
    moveFrame()

    if(MapRenderer.isMapOpen()) then
        checkIfShouldCloseMap()
    end
end

local function onKeyPress(key)
    if(not mapReady) then return end
    if(MapRenderer.canControl()) then
        if key.code==input.KEY.Minus or key.code==input.KEY.NP_Minus then
            zoomMapKBM(0,-1)
        elseif key.code==input.KEY.Equals or key.code==input.KEY.NP_Plus then
            zoomMapKBM(0,1)
        end
    end
end

local function onMouseWheel(vertical, horizontal)
    if(not mapReady) then return end
    if(MapRenderer.canControl()) then
        local dt = core.getRealFrameDuration()
        zoomMapKBM(dt,vertical)
    end
end

local function onControllerButtonPress(id)
    if(not mapReady) then return end
    if id == input.CONTROLLER_BUTTON.Y then	
        MapRenderer.switchFastTravelLayer()
    end
end

return {
    engineHandlers = {
        onMouseWheel = onMouseWheel,
		onControllerButtonPress = onControllerButtonPress,
        onKeyPress = onKeyPress,
        onUpdate = onUpdate,
		onLoad = onLoad,
		onSave = onSave,
    },
    eventHandlers = {
        DP_DM_fromGlobal = DP_DM_fromGlobal
    }
}