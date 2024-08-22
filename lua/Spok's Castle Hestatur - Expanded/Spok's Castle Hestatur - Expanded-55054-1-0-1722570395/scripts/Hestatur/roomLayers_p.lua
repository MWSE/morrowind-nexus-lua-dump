local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local async = require("openmw.async")
local messagebox = require("scripts.Hestatur.MessageBox")


local layers = require("scripts.Hestatur.roomLayers_data")
local lightState = {
    lightsOn = 1,
    lightsOff = 2,
    lightsHidden = 3,
}
local myLayerName

local renameWindow = nil
local uithing = nil

local currentLayer = nil

local bedCount = 0
local layerState = {}
local layerUnlocks = {}
local genModData = storage.globalSection("MoveObjectsCellGen")

local currentCategory = nil --if nil, then show the category selection level
local currentSubCat = nil   --if nil, but above isn't, show subcategories.

local CreateLayerBox = nil
local ConfigLayerBox = nil
local currentText = ""
local buttonContext = ""
local doorID = ""
local settlementMarker = nil

local maxLayers = 0
local function textChanged(firstField)
    currentText = (firstField)
end
local function buttonClick()
    --print(currentText)

    I.UI.setMode()
    CreateLayerBox:destroy()
end

local function destroyWindow()
    renameWindow:destory()
    I.RoomLayers_Cam.exitCameraMode()
end

local allowMales = false



local function yesText(bool)
    if (bool == true) then
        return "Yes"
    else
        return "No"
    end
end
local function buttonClickRename()
    --print(currentText)
    core.sendGlobalEvent("renameLayerEvent",
        {
            name = currentText,
            id = settlementMarker
        })
    I.UI.setMode()
end
local function updateLayerUi()
    if (ConfigLayerBox ~= nil) then
        ConfigLayerBox = I.RoomLayers.renderTextInput(currentLayer)
    end
end
local function ToggleTableItem(x, text)
    local text = text.props.name
    if (text == "DoneButton") then
        ConfigLayerBox:destroy()
        ConfigLayerBox = nil
        I.RoomLayers_Cam.exitCameraMode()
        I.UI.setMode()
        return
    end
    if (text == "Next Camera") then

        I.RoomLayers_Cam.nextCamera()
        --print("next cam")
        return
    end
    if not layerState[self.cell.id] then
        layerState[self.cell.id] = {}
        layerState[self.cell.id].lights = lightState.lightsOff
    end
    if text == "lights" then
        --print("lights")
        local state = layerState[self.cell.id].lights
        if not layerState[self.cell.id].lights then
            layerState[self.cell.id].lights = lightState.lightsOff
            state = lightState.lightsOff
        end
        state = state + 1
        if state == 4 then
            state = lightState.lightsOn
        end
        layerState[self.cell.id].lights = state
        --print(state)
        if state == lightState.lightsOff then
            core.sendGlobalEvent("turnCellLightsOff_Hest", self.cell.id)
        elseif state == lightState.lightsOn then
            core.sendGlobalEvent("turnCellLightsOn_Hest", self.cell.id)
        elseif state == lightState.lightsHidden then
            core.sendGlobalEvent("turnCellLightsOn_Hest", self.cell.id)
            core.sendGlobalEvent("hideLightsInCell", self.cell.id)
        end
        updateLayerUi()
        return
    end
    for layerId, layer in pairs(layers[self.cell.id]) do
        -- --print(layerId)
        if layerId == text and layer.objects then
            if not layerUnlocks[self.cell.id] then
                layerUnlocks[self.cell.id] = {}
            end
            if not layerUnlocks[self.cell.id][layerId] == true then
               
                local goldCount = types.Actor.inventory(self):countOf("gold_001")
                if goldCount < layer.price then
                    ui.showMessage(layer.name .. " costs " .. tostring(layer.price) )
                    return
                end
                messagebox.showMessageBox(layerId,
                    { "Pay " .. tostring(layer.price) .. " to unlock " .. layer.name .. "?" },{"Yes","No"})
                return
            end
            layerState[self.cell.id][layerId] = not layerState[self.cell.id][layerId]
            core.sendGlobalEvent("setLayerState",
                {
                    layerId = layerId,
                    cellId = self.cell.id,
                    state = layerState[self.cell.id][layerId],
                    layerStateData =
                        layerState[self.cell.id]
                })
            updateLayerUi()
        end
    end
end
local aux_util = require('openmw_aux.util')


local function RenderToggleBox(toggleName, toggleText, toggleCallback, toggleBool, overRide)
    local booltext = overRide or "Yes"



    if (toggleBool == false) then
        booltext = "No"
    end
    if not toggleText then
        toggleText = toggleName
    end
    return I.ZackUtilsUI_Hest.boxedTextContent(toggleText .. ": " .. booltext, async:callback(toggleCallback), 0.8,
        toggleName)
end
local function RenderBox(toggleName, toggleText, toggleCallback)
    return I.ZackUtilsUI_Hest.boxedTextContent(toggleText, async:callback(toggleCallback), 0.8, toggleName)
end
local function renderTextInput(settlementId, existingText, editCallback, OKCallback, OKText)
    local mySettle = nil
    bedCount = 0
    local settlerCount = 0
    --print("rendering")

    myLayerName = "Layert1"
    if (ConfigLayerBox ~= nil) then
        ConfigLayerBox:destroy()
    end
    if (OKText == nil) then
        OKText = "OK"
    end
    local vertical = 50
    local horizontal = (ui.layers[1].size.x / 2) - 400

    local vertical = 0
    local horizontal = ui.layers[1].size.x / 2 - 25
    local vertical = vertical + ui.layers[1].size.y / 2 + 100

    local content = {}

    local validRaceCount = 0
    local validGender = false
    if not layerState[self.cell.id] then
        layerState[self.cell.id] = {}
        layerState[self.cell.id].lights = lightState.lightsOff
    end
    for layerId, layer in pairs(layers[self.cell.id]) do
        if layer.objects then
            if layerState[self.cell.id][layerId] == nil then
                layerState[self.cell.id][layerId] = false
            end
            local text = layer.name
            table.insert(content, RenderToggleBox(layerId, text, ToggleTableItem, layerState[self.cell.id][layerId]))
        end
    end
    local lightText = "Off"
    if layerState[self.cell.id].lights == lightState.lightsHidden then
        lightText = "Hidden"
    elseif layerState[self.cell.id].lights == lightState.lightsOn then
        lightText = "On"
    end
    table.insert(content, RenderToggleBox("lights", "Lights", ToggleTableItem, true, lightText))

    table.insert(content, RenderBox("DoneButton", "Done", ToggleTableItem))
    table.insert(content, RenderBox("Next Camera", "Next Camera", ToggleTableItem))
    core.sendGlobalEvent("setMasterLayerState",layerState)
    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 1),
            anchor = v2(0.5, 1),
            --position = v2(horizontal, vertical),
            vertical = false,
            relativeSize = util.vector2(0.1, 0.1),
            arrange = ui.ALIGNMENT.Start
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.Start,
                    size = util.vector2(400, 10),
                }
            }
        }
    }
end
local function showLayerConfig()
    if not I.RoomLayers_Cam.isInCamMode() then
        if layers[self.cell.id] and layers[self.cell.id].camPos and layers[self.cell.id].camPos[1] then
            local data = layers[self.cell.id].camPos[1]

            I.RoomLayers_Cam.enterCameraMode(util.vector3(data.position[1], data.position[2], data.position[3]), data
            .yaw, data.pitch, data.fov)
        end
    end
    ConfigLayerBox = renderTextInput(currentLayer)

    I.UI.setMode('Interface', { windows = {} })
    --Need to show data here. Allow you to config which type of settler to allow, how many to allow(Defaults to 0), and
end
local function createNewLayer(settlementMarker)
    core.sendGlobalEvent("addLayerEvent",
        {
            settlementId = settlementMarker.id,
            position = nearby.findRandomPointAroundCircle(settlementMarker.position, 400)
        })
end
local function onConsoleCommand(mode, command, selectedObject)
    if (command == "luasettler" and selectedObject.recordId == "zhac_settlement_marker") then
        core.sendGlobalEvent("addActorToLayer", selectedObject.id)
    end
end
local function processGreeting(data)
    local actor = data.npc
    local jobSiteData = data.jobSiteData

    local actorRecord = actor.type.record(actor)
    local playerRecord = self.type.record(self)
end

local function ButtonClicked_Hest(data)
    local winName = data.name
    local text = data.text
    if text == "No" then
        return
    end
    --print(winName,text)
    for layerId, layer in pairs(layers[self.cell.id]) do
        if layer.objects and winName ==  layerId then
            layerUnlocks[self.cell.id][layerId] = true
            layerState[self.cell.id][layerId] = true
            core.sendGlobalEvent("removeGoldCount",layer.price)
            core.sendGlobalEvent("setLayerState",
                {
                    layerId = layerId,
                    cellId = self.cell.id,
                    state = layerState[self.cell.id][layerId],
                    layerStateData =
                        layerState[self.cell.id]
                })
            updateLayerUi()
        end
    end
end
local lastMode
local spokenActor
return {
    interfaceName = "RoomLayers",
    interface = {
        version = 1,
        destroyWindow = destroyWindow,
        renderTextInput = renderTextInput,
        createNewLayer = createNewLayer,
        showLayerConfig = showLayerConfig,
    },
    eventHandlers = {
        updateLayerUi = updateLayerUi,
        showLayerConfig = showLayerConfig,
        ButtonClicked_Hest = ButtonClicked_Hest,
        UiModeChanged = function(data)
            --print(data.newMode)
            if data.newMode == "Dialogue" then
                spokenActor = data.arg
            elseif not data.newMode and data.oldMode == "Dialogue" and spokenActor then
               core.sendGlobalEvent("sayGoodByeActor",spokenActor)
               --print("GO TO JAIL", spokenActor.recordId)
               spokenActor = nil
            end
            lastMode = data.newMode
        end,
        updateLayerState = function (data)
            layerState = data
        end,
        showMessageHestatur = function (msg)
            ui.showMessage(msg)
        end,
        processGreeting = processGreeting,
    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
        onSave = function ()
            return {
                layerState = layerState,
                layerUnlocks = layerUnlocks
            }
        end,
        onLoad = function (data)
            if data then
                layerState = data.layerState or {}
                layerUnlocks = data.layerUnlocks or {}
            end
        end,
        onConsoleCommand = onConsoleCommand,
    }
}
