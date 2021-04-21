
--[[Map and Compass
    v1.1.1
    by JaceyS
    Credit:
    All maps in the mapsWagner pack were created by Mike Wagner for Bethesda Softworks.
        Copyright information has been removed for immersion, not to obfuscate ownership. Consider the general copyright on the game to cover these maps.
        vvardenfellMapWagner and mournholdMapWagner are taken from imperial-library.info, and were scanned in high res by Raptormeat.
        solstheimMapWagner was based on a map from redit user u/graemecloutman, which seems to be a composite of a GOTY scan and a low res image of the Bloodmoon map,
         and elements taken from the raptormeat scan of the Vvardenfel map.
    All maps in the mapsOutlander pack are from London Rook, posted as a modders resource here: https://www.patreon.com/posts/11784257
    ]]
local config = require("Map and Compass.config")
local lastMouseX
local lastMouseY
local createDropdown
local createNote

local function createMapMarkers()
    local mapPack = tes3.player.data.JaceyS.MaC.currentMap.mapPack
    local map = tes3.player.data.JaceyS.MaC.currentMap.map
    local menuMapID = tes3ui.registerID("MenuMap")
    local menuMap = tes3ui.findMenu(menuMapID)
    local elementID = tes3ui.registerID(map.. "_image")
    local element = menuMap:findChild(elementID)
    local mapMarkerID = tes3ui.registerID("MapMarker")
    for _, child in pairs(element.children) do
        if (child.id == mapMarkerID) then
            child:destroy()
        end
    end
    if (tes3.player.data.JaceyS.MaC[mapPack] and tes3.player.data.JaceyS.MaC[mapPack][map] and tes3.player.data.JaceyS.MaC[mapPack][map].notes) then
        for key, note in pairs(tes3.player.data.JaceyS.MaC[mapPack][map].notes) do
            -- remove old notes that are indexed by string, so they don't mess us up.
            if (type(key) == "string") then
                tes3.player.data.JaceyS.MaC[mapPack][map].notes = {}
                break
            end
            local x = note.coords.x
            local y = note.coords.y
            local mapMarker = element:createImage({ id = mapMarkerID, path = "icons/map_marker_red.dds"})
            mapMarker.absolutePosAlignX = x * element.imageScaleX / element.width
            mapMarker.absolutePosAlignY = y * element.imageScaleY / element.height
            mapMarker:register("help", function()
                                        local toolTip = tes3ui.createTooltipMenu()
                                        local block = toolTip:createBlock()
                                        block.autoWidth = false
                                        block.width = 200
                                        block.autoHeight = true
                                        block.minHeight = 30
                                        local text = block:createLabel()
                                        text.text = note.text
                                        text.wrapText = true
                                    end)
            mapMarker:register("mouseClick", function()
                                        createNote(note)
                                        end)
        end
    end
    menuMap:updateLayout()
end

local function zoomIn(e)
    local unscaledWidth = e.source.width / e.source.imageScaleX
    local unscaledHeight = e.source.height / e.source.imageScaleY
    local unscaledOffsetX = (e.source.parent.childOffsetX - 0.5 * e.source.parent.width) / e.source.imageScaleX
    local unscaledOffsetY = (e.source.parent.childOffsetY + 0.5 * e.source.parent.height) / e.source.imageScaleY
    e.source.imageScaleX = math.min(e.source.imageScaleX + 0.1, config.maxScale)
    e.source.imageScaleY = math.min(e.source.imageScaleY + 0.1, config.maxScale)
    e.source.width = unscaledWidth * e.source.imageScaleX
    e.source.height = unscaledHeight * e.source.imageScaleY
    e.source.parent.childOffsetX = math.min((unscaledOffsetX * e.source.imageScaleX) + 0.5 * e.source.parent.width, 0)
    e.source.parent.childOffsetY = math.max((unscaledOffsetY * e.source.imageScaleY) - 0.5 * e.source.parent.height, 0)
    local menuMapID = tes3ui.registerID("MenuMap")
    local menuMap = tes3ui.findMenu(menuMapID)
    createMapMarkers()
    createDropdown()
    menuMap:updateLayout()
end

local function zoomOut(e)
    local unscaledWidth = e.source.width / e.source.imageScaleX
    local unscaledHeight = e.source.height / e.source.imageScaleY
    if (unscaledWidth * (e.source.imageScaleX - 0.1 ) < e.source.parent.width) then
        return
    elseif (unscaledHeight * (e.source.imageScaleY - 0.1) < e.source.parent.height) then
        return
    end
    local unscaledOffsetX = (e.source.parent.childOffsetX - 0.5 * e.source.parent.width) / e.source.imageScaleX
    local unscaledOffsetY = (e.source.parent.childOffsetY + 0.5 * e.source.parent.height) / e.source.imageScaleY
    e.source.imageScaleX = math.max (0.1, e.source.imageScaleX - 0.1)
    e.source.imageScaleY = math.max (0.1, e.source.imageScaleY - 0.1)
    e.source.width = unscaledWidth * e.source.imageScaleX
    e.source.height = unscaledHeight * e.source.imageScaleY
    e.source.parent.childOffsetX = math.min((unscaledOffsetX * e.source.imageScaleX) + 0.5 * e.source.parent.width, 0)
    e.source.parent.childOffsetY = math.max((unscaledOffsetY * e.source.imageScaleY) - 0.5 * e.source.parent.height, 0)
    
    if(e.source.parent.childOffsetX < -1 * (e.source.width - e.source.parent.width)) then
        e.source.parent.childOffsetX = -1 * (e.source.width - e.source.parent.width)
    end
    if(e.source.parent.childOffsetY > e.source.height - e.source.parent.height) then
        e.source.parent.childOffsetY = e.source.height - e.source.parent.height
    end
    local menuMapID = tes3ui.registerID("MenuMap")
    local menuMap = tes3ui.findMenu(menuMapID)
    createMapMarkers()
    createDropdown()
    menuMap:updateLayout()
end

local function startDrag(e)
    tes3ui.captureMouseDrag(true)
    lastMouseX = e.data0
    lastMouseY = e.data1
end

local function releaseDrag()
    tes3ui.captureMouseDrag(false)
end

local function dragController(e)
    local changeX = lastMouseX - e.data0
    local changeY = lastMouseY - e.data1
    local mapPaneID = tes3ui.registerID(tes3.player.data.JaceyS.MaC.currentMap.map)
    local mapPane = e.source:findChild(mapPaneID)
    local currentMapElementID = tes3ui.registerID(tes3.player.data.JaceyS.MaC.currentMap.map .. "_image")
    local currentMapElement = mapPane:findChild(currentMapElementID)
    mapPane.childOffsetX = math.min(0, mapPane.childOffsetX - changeX)
    mapPane.childOffsetY = math.max(0, mapPane.childOffsetY - changeY)
    if(mapPane.childOffsetX < -1 * (currentMapElement.width - mapPane.width)) then
        mapPane.childOffsetX = -1 * (currentMapElement.width - mapPane.width)
    end
    if(mapPane.childOffsetY > currentMapElement.height - mapPane.height) then
        mapPane.childOffsetY = currentMapElement.height - mapPane.height
    end
    lastMouseX = e.data0
    lastMouseY = e.data1
    local menuMapID = tes3ui.registerID("MenuMap")
    local menuMap = tes3ui.findMenu(menuMapID)
    menuMap:updateLayout()
end

createNote = function(e)
    if(tes3.worldController.inputController:isKeyDown(config.noteKey.keyCode) or e.coords) then
        if(tes3ui.findMenu(tes3ui.registerID("MaC_NoteEditor"))) then
            return
        end
        local menuMapID = tes3ui.registerID("MenuMap")
        local menuMap = tes3ui.findMenu(menuMapID)
        local currentMap = tes3.player.data.JaceyS.MaC.currentMap
        local mapPaneID = tes3ui.registerID(tes3.player.data.JaceyS.MaC.currentMap.map .. "_image")
        local mapPane = menuMap:findChild(mapPaneID)
        local noteEditorTop = tes3ui.createMenu({id = tes3ui.registerID("MaC_NoteEditor"), fixedFrame = true})
        local noteEditorLayout = noteEditorTop:createBlock()
        noteEditorLayout.autoWidth = true
        noteEditorLayout.autoHeight = true
        noteEditorLayout.flowDirection = "top_to_bottom"
        local rect = noteEditorLayout:createRect({color = {0,0,0}})
        rect.absolutePosAlignX = 0
        rect.absolutePosAlignY = 0
        noteEditorLayout:createLabel({text = "Note Editor"})

        local paragraphFieldID = tes3ui.registerID("MaC_NoteEditor_paragraph")
        local paragraphField = noteEditorLayout:createParagraphInput(paragraphFieldID)
        paragraphField.width = 600
        paragraphField.height = 400
        if (e.text) then
            paragraphField.text = e.text
        end
        tes3ui.acquireTextInput(paragraphField)
        local buttonBlock = noteEditorLayout:createBlock()
        buttonBlock.absolutePosAlignX = 1
        buttonBlock.autoWidth = true
        buttonBlock.height = 25
        local cancelButton = buttonBlock:createButton()
        cancelButton.text = "Delete"
        cancelButton:register("mouseClick", function()
                                                tes3ui.acquireTextInput(nil)
                                                noteEditorTop:destroy()
                                                if (e.coords) then
                                                    table.removevalue(tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].notes, e)
                                                end
                                                createMapMarkers()
                                            end)
        local saveButton = buttonBlock:createButton()
        saveButton.text = "Save"
        saveButton:register("mouseClick", function()
                                            tes3ui.acquireTextInput(nil)
                                            local coords
                                            if (e.coords) then
                                                coords = e.coords
                                            else
                                                coords = {x = e.relativeX / mapPane.imageScaleX, y = e.relativeY / mapPane.imageScaleY}
                                            end
                                            if not (tes3.player.data.JaceyS.MaC[currentMap.mapPack]) then
                                                tes3.player.data.JaceyS.MaC[currentMap.mapPack] = {}
                                            end
                                            if not (tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map]) then
                                                tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map] = {}
                                            end
                                            if not (tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].notes) then
                                                tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].notes = {}
                                            end
                                            local note = {coords = coords, text = paragraphField.text}
                                            if (e.coords) then
                                                local key = table.find(tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].notes, e)
                                                tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].notes[key] = note
                                            else
                                                table.insert(tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].notes, note)
                                            end
                                            noteEditorTop:destroy()
                                            createMapMarkers()
                                        end)

    end
end

local function mapSelected()
    if (tes3ui.findMenu(tes3ui.registerID("MenuOptions"))) then
        return
    end
    local menuMapID = tes3ui.registerID("MenuMap")
    local menuMap = tes3ui.findMenu(menuMapID)
    local localMapID = tes3ui.registerID("MenuMap_local")
    local localMap = menuMap:findChild(localMapID)
    local worldMapID = tes3ui.registerID("MenuMap_world")
    local worldMap = menuMap:findChild(worldMapID)
    local customMapID = tes3ui.registerID("MenuMap_custom")
    local customMap = menuMap:findChild(customMapID)
    local mapMainID = tes3ui.registerID("PartDragMenu_main")
    local mapMain = menuMap:findChild(mapMainID)
    local selectorID = tes3ui.registerID("MenuMap_selector")
    local selector = menuMap:findChild(selectorID)
    if (tes3.player.data.JaceyS.MaC.currentMap == "MenuMap_local") then
        localMap.visible = true
        localMap.disabled = false
        worldMap.visible = false
        worldMap.disabled = true
        customMap.visible = false
        customMap.disabled = true
        return
    end
    if(tes3.player.data.JaceyS.MaC.currentMap == "MenuMap_world") then
        worldMap.visible = true
        worldMap.disabled = false
        localMap.visible = false
        localMap.disabled = true
        customMap.visible = false
        customMap.disabled = false
        return
    end
    customMap.visible = true
    customMap.disabled = false
    worldMap.visible = false
    worldMap.disabled = true
    localMap.visible = false
    localMap.disabled = true
    for _, element in pairs(customMap.children) do
        element.visible = false
        element.disabled = true
    end
    if (tes3.player.data.JaceyS.MaC.currentMap == "noMap") then
        return
    end
    local childID = tes3ui.registerID(tes3.player.data.JaceyS.MaC.currentMap.map)
    local element = customMap:findChild(childID)
    element.visible = true
    element.disabled = false
    createMapMarkers()
    createDropdown()
end

local function onMenuMapActivated()
    -- Minimap to Compass
    do
        local menuMultiID = tes3ui.registerID("MenuMulti")
        local menuMulti = tes3ui.findMenu(menuMultiID)
        local minimapID = tes3ui.registerID("MenuMap_pane")
        local minimap = menuMulti:findChild(minimapID)
        local compassPanelID = tes3ui.registerID("MenuMap_panel")
        local compassPanel = menuMulti:findChild(compassPanelID)
        local compassFaceID = tes3ui.registerID("CompassFace")
        if (menuMulti:findChild(compassFaceID)) then
            menuMulti:findChild(compassFaceID):destroy()
        end
        if(config.compass) then
            minimap.visible = false
            local compassFace = compassPanel:createImage({path = "MWSE/mods/Map and Compass/" .. config.compass})
            compassFace.absolutePosAlignX = 0
            compassFace.absolutePosAlignY = 0
        else
            minimap.visible = true
        end
    end

    -- Hide the map notification popup
    if(config.hideMapNotification) then
        local menuMultiID = tes3ui.registerID("MenuMulti")
        local menuMulti = tes3ui.findMenu(menuMultiID)
        local notificationID = tes3ui.registerID("MenuMulti_main")
        local notification = menuMulti:findChild(notificationID)
        notification.visible = false
        notification.disabled = true
    end

    -- Initialize currentMap
    if (not tes3.player.data.JaceyS) then
        tes3.player.data.JaceyS = {}
    end
    if (not tes3.player.data.JaceyS.MaC) then
        tes3.player.data.JaceyS.MaC = {}
    end
    if (not tes3.player.data.JaceyS.MaC.currentMap) then
        if (tes3.player.cell.isInterior) then
            if (config.localMap) then
                tes3.player.data.JaceyS.MaC.currentMap = "MenuMap_local"
            elseif (config.worldMap) then
                tes3.player.data.JaceyS.MaC.currentMap = "MenuMap_world"
            else
                tes3.player.data.JaceyS.MaC.currentMap = "noMap"
            end
        else
            if (config.worldMap) then
                tes3.player.data.JaceyS.MaC.currentMap = "MenuMap_world"
            elseif (config.localMap) then
                tes3.player.data.JaceyS.MaC.currentMap = "MenuMap_local"
            else
                tes3.player.data.JaceyS.MaC.currentMap = "noMap"
            end
        end
    end

    -- Create Custom Map Elements
    do
        local menuMapID = tes3ui.registerID("MenuMap")
        local menuMap = tes3ui.findMenu(menuMapID)
        local mapMainID = tes3ui.registerID("PartDragMenu_main")
        local mapMain = menuMap:findChild(mapMainID)

        -- This frame holds our custom maps
        local customMapID = tes3ui.registerID("MenuMap_custom")
        if(mapMain:findChild(customMapID)) then
            mapMain:findChild(customMapID):destroy()
        end
        local customMap = mapMain:createBlock({id = customMapID})
        customMap.visible = false
        customMap.disabled = true
        customMap.widthProportional =1
        customMap.heightProportional = 1
        customMap:register("mouseDown", startDrag)
        customMap:register("mouseRelease", releaseDrag)
        customMap:register("mouseStillPressed", dragController)

        -- Create all the maps right now, to prevent slowdown later.
        for _, mapPack in pairs(config.mapPacks) do
            local maps = require("Map and Compass.".. mapPack .. ".maps")
            for map, values in pairs(maps) do
                if (config[mapPack] and config[mapPack][map] and config[mapPack][map].enabled) then
                    if( not tes3.player.data.JaceyS.MaC[mapPack]) then
                        tes3.player.data.JaceyS.MaC[mapPack] = {}
                    end
                    if (not tes3.player.data.JaceyS.MaC[mapPack][map]) then
                        tes3.player.data.JaceyS.MaC[mapPack][map] = {}
                    end
                    local id = tes3ui.registerID(map)
                    local frame = customMap:createBlock({id = id})
                    frame.visible = false
                    frame.disabled = true
                    frame.widthProportional = 1
                    frame.heightProportional = 1
                    frame.alpha = 0
                    frame.childOffsetX = tes3.player.data.JaceyS.MaC[mapPack][map].offsetX or 0
                    frame.childOffsetY = tes3.player.data.JaceyS.MaC[mapPack][map].offsetY or 0
                    local elementID = tes3ui.registerID(map.."_image")
                    local element = frame:createImage({id = elementID, path = values.path})
                    element.visible = true
                    element.disabled = false
                    element.imageScaleX = tes3.player.data.JaceyS.MaC[mapPack][map].scale or 1
                    element.imageScaleY = tes3.player.data.JaceyS.MaC[mapPack][map].scale or 1
                    element.width = values.width * element.imageScaleX
                    element.height = values.height * element.imageScaleY
                    element:register("mouseScrollUp", zoomIn)
                    element:register("mouseScrollDown", zoomOut)
                    element:register("mouseClick", createNote)
                end
            end
        end
    end

    -- Hide the "Switch" button.
    do
        local menuMapID = tes3ui.registerID("MenuMap")
        local menuMap = tes3ui.findMenu(menuMapID)
        local switchID = tes3ui.registerID("MenuMap_switch")
        local switch = menuMap:findChild(switchID)
        if (config.selectionDropdown or config.hideSwitch) then
            switch.visible = false
            switch.disabled = true
        else
            switch.visible = true
            switch.disabled = false
        end
    end

    -- Hide the Map Title
    do
        local menuMapID = tes3ui.registerID("MenuMap")
        local menuMap = tes3ui.findMenu(menuMapID)
        local titleID = tes3ui.registerID("PartDragMenu_title")
        local title = menuMap:findChild(titleID)
        if(config.hideMapTitle) then
            title.visible = false
        else
            title.visible = true
        end
    end
    -- Create the Selection Dropdown
    createDropdown()
    mapSelected()
end
event.register("uiActivated", onMenuMapActivated, {filter = "MenuMap"})

local function onSave()
    local menuMapID = tes3ui.registerID("MenuMap")
    local menuMap = tes3ui.findMenu(menuMapID)
    for _, mapPack in pairs(config.mapPacks) do
        local maps = require("Map and Compass.".. mapPack .. ".maps")
        for map, values in pairs(maps) do
            if (config[mapPack] and config[mapPack][map] and config[mapPack][map].enabled) then
                local mapID = tes3ui.registerID(map)
                local panel = menuMap:findChild(mapID)
                tes3.player.data.JaceyS.MaC[mapPack][map].offsetX = panel.childOffsetX
                tes3.player.data.JaceyS.MaC[mapPack][map].offsetY = panel.childOffsetY
                local elementID = tes3ui.registerID(map .. "_image")
                local element = menuMap:findChild(elementID)
                tes3.player.data.JaceyS.MaC[mapPack][map].scale = element.imageScaleX
            end
        end
    end
end

event.register("save", onSave)



local escapeReturn
local function resetMap()
    mapSelected()
    event.unregister("keyDown", escapeReturn, {filter = tes3.scanCode.escape})
end

local function delayAgain()
    timer.delayOneFrame(resetMap, timer.real)
end
escapeReturn = function()
    timer.delayOneFrame(delayAgain, timer.real)
end
local function onMenuOptionsActivated(e)
    onSave()
    local returnButtonID = tes3ui.registerID("MenuOptions_Return_container")
    local returnButton = e.element:findChild(returnButtonID)
    returnButton:register("mouseClick", function(e)
                                            e.source:forwardEvent(e)
                                            resetMap()
                                        end)
    event.register("keyDown", escapeReturn, {filter = tes3.scanCode.escape})
end



local function onLoaded()
    event.register("menuEnter", mapSelected)
    event.register("jaceyS_MaC_MCM_Closed", onMenuMapActivated)
    event.register("uiActivated", onMenuOptionsActivated, {filter = "MenuOptions"})
end
event.register("loaded", onLoaded)
createDropdown = function()
    local menuMapID = tes3ui.registerID("MenuMap")
    local menuMap = tes3ui.findMenu(menuMapID)
    local selectorID = tes3ui.registerID("MenuMap_selector")
    local selector = menuMap:findChild(selectorID)
    if(selector) then
        selector:destroy()
    end
    if (config.selectionDropdown) then
        -- Pregenerate the options for the dropdown
        local options = {{label = "No Map", value = "noMap"}}
        if (config.worldMap) then
            table.insert(options, {label = "World", value = "MenuMap_world"})
        end
        if (config.localMap) then
            table.insert(options, {label = "Local", value = "MenuMap_local"})
        end
        for _, mapPack in pairs(config.mapPacks) do
            local maps = require("Map and Compass.".. mapPack .. ".maps")
            for map, values in pairs(maps) do
                if (config[mapPack] and config[mapPack][map] and config[mapPack][map].enabled) then
                    local option = {}
                    option.label = config[mapPack][map].name or values.name
                    option.value = {mapPack = mapPack, map = map}
                    table.insert(options, option)
                end
            end
        end

        --Create the dropdown
        local mapMainID = tes3ui.registerID("PartDragMenu_main")
        local mapMain = menuMap:findChild(mapMainID)
        local block = mapMain:createBlock({id = selectorID})
        block.absolutePosAlignX = 0
        block.absolutePosAlignY = 0
        block.autoWidth = false
        block.autoHeight = true
        block.width = 300
        block.minHeight = 10
        local dropdown = mwse.mcm.createDropdown({
            options = options,
            callback = mapSelected,
            variable = mwse.mcm.createPlayerData({id = "currentMap", path = "JaceyS.MaC"})
        })
        dropdown:create( block )
        local innerContainer = block:findChild(tes3ui.registerID("InnerContainer"))
        local rect = innerContainer:createRect({color = {0,0,0}})
        rect.alpha = 0.5
        rect.absolutePosAlignX = 0
        rect.absolutePosAlignY = 0
        rect.consumeMouseEvents = false
        rect.width = 1000
        rect.height = 1000
        innerContainer:reorderChildren(0, rect, 1)
    end
end



event.register("modConfigReady", function()
    for _, mapPack in ipairs(config.mapPacks) do
        if (not config[mapPack]) then
            config[mapPack] = {}
        end
        local maps = require("Map and Compass.".. mapPack .. ".maps")
        for map, _ in pairs(maps) do
            if (not config[mapPack][map]) then
                config[mapPack][map] = {}
            end
        end
    end
	require("Map and Compass.mcm")
end)

--[[local mapSelect
local selectedMap


local function onMapInteract(e)
    if(e.block.id == tes3ui.registerID("MaC_SelectedMap")) then
        if (e.property == tes3.uiProperty.stillPressed) then
            if (tes3.player.data.JaceyS and tes3.player.data.JaceyS.MaC and tes3.player.data.JaceyS.MaC.currentMap and tes3.player.data.JaceyS.MaC.currentMap ~= "MenuMap_world" and tes3.player.data.JaceyS.MaC.currentMap ~= "MenuMap_local") then
                if (selectedMap and selectedMap.parent) then
                    local currentMap = tes3.player.data.JaceyS.MaC.currentMap
                    local xOffset = selectedMap.parent.childOffsetX
                    local yOffset = selectedMap.parent.childOffsetY
                    tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].xOffset = xOffset
                    tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].yOffset = yOffset
                end
            end
        end
    end
end
event.register("uiEvent", onMapInteract)


local function updateMap(e)
    local menuMapID = tes3ui.registerID("MenuMap")
    local localMapID = tes3ui.registerID("MenuMap_local")
    local worldMapID = tes3ui.registerID("MenuMap_world")
    local switchID = tes3ui.registerID("MenuMap_switch")
    local localMapPanelID = tes3ui.registerID("MenuMap_panel")
    local worldMapPanelID = tes3ui.registerID("MenuMap_world_panel")
    local localMapPaneID = tes3ui.registerID("MenuMap_pane")
    local worldMapPaneID = tes3ui.registerID("MenuMap_world_pane")
    local topBarID = tes3ui.registerID("PartDragMenu_title_tint")
    local leftBlockID = tes3ui.registerID("PartDragMenu_left_title_block")
    local titleID = tes3ui.registerID("PartDragMenu_title")
    local mapMainID = tes3ui.registerID("PartDragMenu_main")
    local selectedMapID = tes3ui.registerID("MaC_SelectedMap")

    local menuMap = tes3ui.findMenu(menuMapID)
    local localMap = menuMap:findChild(localMapID)
    local worldMap = menuMap:findChild(worldMapID)
    local switch = menuMap:findChild(switchID)
    local localMapPanel = menuMap:findChild(localMapPanelID)
    local worldMapPanel = menuMap:findChild(worldMapPanelID)
    local localMapPane = menuMap:findChild(localMapPaneID)
    local worldMapPane = menuMap:findChild(worldMapPaneID)
    local topBar = menuMap:findChild(topBarID)
    local leftBlock = menuMap:findChild(leftBlockID)
    local title = menuMap:findChild(titleID)
    local mapMain = menuMap:findChild(mapMainID)

    if (not ( tes3.player.data.JaceyS and tes3.player.data.JaceyS.MaC and tes3.player.data.JaceyS.MaC.currentMap)) then
        return
    end
    local currentMap = tes3.player.data.JaceyS.MaC.currentMap
    if (currentMap == "MenuMap_world") then
        if(not worldMap.visible) then
            switch:triggerEvent("mouseClick")
        end
        if (menuMap:findChild(selectedMapID)) then
            menuMap:findChild(selectedMapID):destroy()
            selectedMap = nil
        end
        worldMapPane.visible = true
        worldMapPane.disabled = false
        return
    end
    if (currentMap == "MenuMap_local") then
        if(not localMap.visible) then
            switch:triggerEvent("mouseClick")
        end
        if (menuMap:findChild(selectedMapID)) then
            menuMap:findChild(selectedMapID):destroy()
            selectedMap = nil
        end
        localMapPane.visible = true
        localMapPane.disabled = false
        return
    end

    if(not worldMap.visible) then
        switch:triggerEvent("mouseClick")
    end
    if (menuMap:findChild(selectedMapID)) then
        menuMap:findChild(selectedMapID):destroy()
    end
    worldMapPane.visible = false
    worldMapPane.disabled = true

    local maps = require("Map and Compass."..currentMap.mapPack..".maps")
    local mapData = maps[currentMap.map]
    selectedMap = worldMapPanel:createImage({id = selectedMapID, path = mapData.path})
    selectedMap:register("mouseClick", function(e)
        if(tes3.worldController.inputController:isKeyDown(config.noteKey)) then
            if(tes3ui.findMenu(tes3ui.registerID("MaC_NoteEditor"))) then
                return
            end
            local noteEditorTop = tes3ui.createMenu({id = tes3ui.registerID("MaC_NoteEditor"), fixedFrame = true})
            local noteEditorLayout = noteEditorTop:createBlock()
            noteEditorLayout.height = 400
            noteEditorLayout.width = 400
            noteEditorLayout.autoWidth = false
            noteEditorLayout.autoHeight = false
            noteEditorLayout:createRect({color = {0,0,0}})
           
            local paragraphField = mwse.mcm.createParagraphField({
                    label = "Note Editor",
                    callback = function() noteEditorTop:destroy() updateMap() end,
                    variable = mwse.mcm.createPlayerData({
                        path = "JaceyS.MaC."..currentMap.mapPack.."."..currentMap.map..".notes",
                        id = e.relativeX .. ",".. e.relativeY -- Really hacky, but oh well.
                    })
            })
            paragraphField:create(noteEditorLayout)
            local cancelButton = noteEditorLayout:createButton()
            cancelButton.text = "Cancel"
            cancelButton.absolutePosAlignY = 1
            cancelButton.absolutePosAlignX = 1
            cancelButton:register("mouseClick", function() noteEditorTop:destroy() end)
        end
    end)

    if (mapData.width) then
        selectedMap.width = mapData.width
    end
    if (mapData.height) then
        selectedMap.height = mapData.height
    end
    if (tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].xOffset) then
        selectedMap.parent.childOffsetX = tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].xOffset
    end
    if (tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].yOffset) then
        selectedMap.parent.childOffsetY = tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].yOffset
    end
    if(tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].notes) then
        for coords, note in pairs(tes3.player.data.JaceyS.MaC[currentMap.mapPack][currentMap.map].notes) do
            local sep = string.find(coords, ",")
            local x = tonumber(string.sub(coords, 1, sep -1))
            local y = tonumber(string.sub(coords, sep + 1, -1))
            local mapMarker = selectedMap:createImage({path = "icons/map_marker_red.dds"})
            mapMarker.absolutePosAlignX = x / selectedMap.width
            mapMarker.absolutePosAlignY = y / selectedMap.height
            mapMarker.consumeMouseEvents = false
            mapMarker:register("help", function()
                                        local toolTip = tes3ui.createTooltipMenu()
                                        local block = toolTip:createBlock()
                                        block.autoWidth = false
                                        block.width = 200
                                        block.autoHeight = true
                                        block.minHeight = 200
                                        local text = block:createLabel()
                                        text.text = note
                                        text.wrapText = true
                                    end)
            mapMarker:register("mouseClick", function(event)
                                            event.source:destroy()
                                            tes3.player.data.JaceyS[currentMap.mapPack][currentMap.map].notes[coords] = nil
                                            -- doesn't work.
                                        end)
        end
    end
    menuMap:updateLayout()
end

local function onMenuEnter()
    if(not tes3ui.findMenu(tes3ui.registerID("MenuMap"))) then
        return
    end
    if (tes3ui.findMenu(tes3ui.registerID("MenuOptions"))) then
        return
    end

    local menuMapID = tes3ui.registerID("MenuMap")
    local localMapID = tes3ui.registerID("MenuMap_local")
    local worldMapID = tes3ui.registerID("MenuMap_world")
    local switchID = tes3ui.registerID("MenuMap_switch")
    local localMapPanelID = tes3ui.registerID("MenuMap_panel")
    local worldMapPanelID = tes3ui.registerID("MenuMap_world_panel")
    local localMapPaneID = tes3ui.registerID("MenuMap_pane")
    local worldMapPaneID = tes3ui.registerID("MenuMap_world_pane")
    local topBarID = tes3ui.registerID("PartDragMenu_title_tint")
    local leftBlockID = tes3ui.registerID("PartDragMenu_left_title_block")
    local titleID = tes3ui.registerID("PartDragMenu_title")
    local mapMainID = tes3ui.registerID("PartDragMenu_main")
    local dropdownID = tes3ui.registerID("OuterContainer")

    local menuMap = tes3ui.findMenu(menuMapID)
    local localMap = menuMap:findChild(localMapID)
    local worldMap = menuMap:findChild(worldMapID)
    local switch = menuMap:findChild(switchID)
    local localMapPanel = menuMap:findChild(localMapPanelID)
    local worldMapPanel = menuMap:findChild(worldMapPanelID)
    local localMapPane = menuMap:findChild(localMapPaneID)
    local worldMapPane = menuMap:findChild(worldMapPaneID)
    local topBar = menuMap:findChild(topBarID)
    local leftBlock = menuMap:findChild(leftBlockID)
    local title = menuMap:findChild(titleID)
    local mapMain = menuMap:findChild(mapMainID)

    switch.visible = false
    switch.disabled = true

    if (not tes3.player.data.JaceyS) then
        tes3.player.data.JaceyS = {}
    end
    if (not tes3.player.data.JaceyS.MaC) then
        tes3.player.data.JaceyS.MaC = {}
    end
    if (not tes3.player.data.JaceyS.MaC.currentMap or tes3.player.data.JaceyS.MaC.currentMap == "MenuMap_local" or tes3.player.data.JaceyS.MaC.currentMap == "MenuMap_world") then
        if (tes3.player.cell.isInterior) then
            tes3.player.data.JaceyS.MaC.currentMap = "MenuMap_local"
        else
            tes3.player.data.JaceyS.MaC.currentMap = "MenuMap_world"
        end
    end
    if (not mapMain:findChild(dropdownID)) then
        mapSelect = mwse.mcm.createDropdown({ options = {}, callback = updateMap, variable = mwse.mcm.createPlayerData({id = "currentMap", path = "JaceyS.MaC"})})
        local block = mapMain:createBlock()
        block.absolutePosAlignX = 0
        block.absolutePosAlignY = 0
        block.autoWidth = false
        block.autoHeight = true
        block.width = 300
        block.minHeight = 10
        mapSelect:create(block)
        local innerContainer = block:findChild(tes3ui.registerID("InnerContainer"))
        local rect = innerContainer:createRect({color = {0,0,0}})
        rect.alpha = 0.5
        rect.absolutePosAlignX = 0
        rect.absolutePosAlignY = 0
        rect.consumeMouseEvents = false
        rect.width = 1000
        rect.height = 1000
        innerContainer:reorderChildren(0, rect, 1)

    end
    if (not config.worldMap) then
        worldMapPane.visible = false
        worldMapPane.disabled = true
    end
    if (not config.localMap) then
        localMapPane.visible = false
        localMapPane.disabled = true
    end
    updateMap()

    if (mapSelect) then
        local options ={}
        if (config.worldMap) then
            table.insert(options, {label = "World", value = "MenuMap_world"})
        end
        if(config.localMap) then
            table.insert(options, {label = "Local", value = "MenuMap_local"})
        end
        for _, mapPack in pairs(config.mapPacks) do
            print("Calling up map pack ".. mapPack)
            local maps = require("Map and Compass."..mapPack..".maps")
            print("maps.lua file contains: " .. tostring(maps))
            if (not maps) then
                tes3.messageBox({
                    message = "Map and Compass Error!\nExpected to find maps.lua in \"Map and Compass\\".. mapPack.."\", but did not.\nCheck the readme for installation instructions.",
                    buttons = {"OK"}
                })
            else
                for map, value in pairs(maps) do
                    if (tes3.player.data and tes3.player.data.JaceyS and tes3.player.data.JaceyS.MaC and tes3.player.data.JaceyS.MaC[mapPack] and tes3.player.data.JaceyS.MaC[mapPack][map] and tes3.player.data.JaceyS.MaC[mapPack][map].enable) then
                        local name
                        if (tes3.player.data.JaceyS.MaC[mapPack][map].name) then
                            name = tes3.player.data.JaceyS.MaC[mapPack][map].name
                        else
                            name = value.name
                        end
                        table.insert(options, {label = name, value = {mapPack = mapPack, map = map}})
                    end
                end
            end
        end
        mapSelect.options = options
    end

    if (config.hideMapTitle) then
        title.alpha = 0
    else
        title.alpha = 1
    end
    menuMap:updateLayout()
end

local function onNoteMenuActivated(e)
end
event.register("uiActivated", onNoteMenuActivated, {filter = "MenuMapNoteEdit"})


local function onLoad()
    mapSelect = nil
    selectedMap = nil
    event.unregister("menuEnter", onMenuEnter)
end
event.register("load", onLoad, {priority = -1000})

local function onLoaded()
    event.register("menuEnter", onMenuEnter)
    if(config.compass) then
        -- Minimap to Compass
        local menuMultiID = tes3ui.registerID("MenuMulti")
        local menuMulti = tes3ui.findMenu(menuMultiID)
        local minimapID = tes3ui.registerID("MenuMap_pane")
        local minimap = menuMulti:findChild(minimapID)
        minimap.visible = false
        local compassPanelID = tes3ui.registerID("MenuMap_panel")
        local compassPanel = menuMulti:findChild(compassPanelID)
        local compassFace = compassPanel:createImage({path = "MWSE/mods/Map and Compass/" .. config.compass})
        compassFace.absolutePosAlignX = 0
        compassFace.absolutePosAlignY = 0
    end
end
event.register("loaded", onLoaded)
event.register("modConfigReady", function()
	require("Map and Compass.mcm")
end)
]]