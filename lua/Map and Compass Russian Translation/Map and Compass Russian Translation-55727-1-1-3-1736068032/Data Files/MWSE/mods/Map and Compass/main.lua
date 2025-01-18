
--[[Map and Compass
    v1.1.3
    by JaceyS
    1.1.3 cleans up a lot of the mess I left behind when I got tired of modding last year.
    The mod should no longer attempt to reregister events, cutting out the log spam this mod has become infamous for.
    The dropdown should now correctly initialize to the current map, rather than filling with nonsense (like compassface.png).
    That happened because the MCM dropdown component was not expecting a table as the value, and freaked out when it tried to compare that to the current selection. Now I store the value as a hyphen separated string, which is then broken out for each function that needs it.
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
local id = {} -- Put element IDs here on init, to reduce the spam in each of the functions
local keydown = false
local inGame = false

local function createMapMarkers()
    local currentMap = tes3.player.data.JaceyS.MaC.currentMap
    local separator = string.find(currentMap, "-")
    local mapPack = string.sub(currentMap, 1, separator - 1)
    local map = string.sub(currentMap, separator + 1)
    local menuMap = tes3ui.findMenu(id.menuMap)
    local elementID = tes3ui.registerID(map.. "_image")
    local element = menuMap:findChild(elementID)
    for _, child in pairs(element.children) do
        if (child.id == id.mapMarker) then
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
            local mapMarker = element:createImage({ id = id.mapMarker, path = "icons/map_marker_red.dds"})
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
    local menuMap = tes3ui.findMenu(id.menuMap)
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
    local menuMap = tes3ui.findMenu(id.menuMap)
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
    local currentMap = tes3.player.data.JaceyS.MaC.currentMap
    local separator = string.find(currentMap, "-")
    local mapPack = string.sub(currentMap, 1, separator - 1)
    local map = string.sub(currentMap, separator + 1)
    local mapPaneID = tes3ui.registerID(map)
    local mapPane = e.source:findChild(mapPaneID)
    local currentMapElementID = tes3ui.registerID(map .. "_image")
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
    local menuMap = tes3ui.findMenu(id.menuMap)
    menuMap:updateLayout()
end

createNote = function(e)
    if(tes3.worldController.inputController:isKeyDown(config.noteKey.keyCode) or e.coords) then
        if(tes3ui.findMenu(id.noteEditor)) then
            return
        end
        local menuMap = tes3ui.findMenu(id.menuMap)
        local currentMap = tes3.player.data.JaceyS.MaC.currentMap
        local separator = string.find(currentMap, "-")
        local mapPack = string.sub(currentMap, 1, separator - 1)
        local map = string.sub(currentMap, separator + 1)
        local mapPaneID = tes3ui.registerID(map .. "_image")
        local mapPane = menuMap:findChild(mapPaneID)
        local noteEditorTop = tes3ui.createMenu({id = id.noteEditor, fixedFrame = true})
        local noteEditorLayout = noteEditorTop:createBlock()
        noteEditorLayout.autoWidth = true
        noteEditorLayout.autoHeight = true
        noteEditorLayout.flowDirection = "top_to_bottom"
        local rect = noteEditorLayout:createRect({color = {0,0,0}})
        rect.absolutePosAlignX = 0
        rect.absolutePosAlignY = 0
        noteEditorLayout:createLabel({text = "Редактор заметок"})

        local paragraphField = noteEditorLayout:createParagraphInput(id.paragraphField)
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
        cancelButton.text = "Удалить"
        cancelButton:register("mouseClick", function()
                                                tes3ui.acquireTextInput(nil)
                                                noteEditorTop:destroy()
                                                if (e.coords) then
                                                    table.removevalue(tes3.player.data.JaceyS.MaC[mapPack][map].notes, e)
                                                end
                                                createMapMarkers()
                                            end)
        local saveButton = buttonBlock:createButton()
        saveButton.text = "Сохранить"
        saveButton:register("mouseClick", function()
                                            tes3ui.acquireTextInput(nil)
                                            local coords
                                            if (e.coords) then
                                                coords = e.coords
                                            else
                                                coords = {x = e.relativeX / mapPane.imageScaleX, y = e.relativeY / mapPane.imageScaleY}
                                            end
                                            if not (tes3.player.data.JaceyS.MaC[mapPack]) then
                                                tes3.player.data.JaceyS.MaC[mapPack] = {}
                                            end
                                            if not (tes3.player.data.JaceyS.MaC[mapPack][map]) then
                                                tes3.player.data.JaceyS.MaC[mapPack][map] = {}
                                            end
                                            if not (tes3.player.data.JaceyS.MaC[mapPack][map].notes) then
                                                tes3.player.data.JaceyS.MaC[mapPack][map].notes = {}
                                            end
                                            local note = {coords = coords, text = paragraphField.text}
                                            if (e.coords) then
                                                local key = table.find(tes3.player.data.JaceyS.MaC[mapPack][map].notes, e)
                                                tes3.player.data.JaceyS.MaC[mapPack][map].notes[key] = note
                                            else
                                                table.insert(tes3.player.data.JaceyS.MaC[mapPack][map].notes, note)
                                            end
                                            noteEditorTop:destroy()
                                            createMapMarkers()
                                        end)

    end
end

local function mapSelected()
    if (tes3ui.findMenu(id.menuOptions)) then
        return
    end
    local menuMap = tes3ui.findMenu(id.menuMap)
    local localMap = menuMap:findChild(id.localMap)
    local worldMap = menuMap:findChild(id.worldMap)
    local customMap = menuMap:findChild(id.customMap)
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
    local currentMap = tes3.player.data.JaceyS.MaC.currentMap
    local separator = string.find(currentMap, "-")
    local mapPack = string.sub(currentMap, 1, separator - 1)
    local map = string.sub(currentMap, separator + 1)
    if (config[mapPack][map].enabled ~= true) then
        -- Gets rid of bad data made when you disable a currently selected map in the MCM.
        tes3.player.data.JaceyS.MaC.currentMap = "noMap"
        return
    end
    local map = string.sub(currentMap, separator + 1)
    local childID = tes3ui.registerID(map)
    local element = customMap:findChild(childID)
    element.visible = true
    element.disabled = false
    createMapMarkers()
    createDropdown()
end

local function onMenuMapActivated()
    local menuMulti = tes3ui.findMenu(id.menuMulti)
    if (menuMulti == nil) then return end
    -- Minimap to Compass
    do
        local minimap = menuMulti:findChild(id.minimap)
        local compassPanel = menuMulti:findChild(id.compassPanel)
        if (menuMulti:findChild(id.compassFace)) then
            menuMulti:findChild(id.compassFace):destroy()
        end
        if(config.compass) then
            minimap.visible = false
            local compassFace = compassPanel:createImage({id = id.compassFace, path = "MWSE/mods/Map and Compass/" .. config.compass})
            compassFace.absolutePosAlignX = 0
            compassFace.absolutePosAlignY = 0
        else
            minimap.visible = true
        end
    end

    -- Hide or show the map notification popup
    do
        local notification = menuMulti:findChild(id.notification)
        if(config.hideMapNotification) then
            notification.visible = false
            notification.disabled = true
        else
            notification.visible = true
            notification.disabled = false
        end
    end

    -- Initialize currentMap
    if (not tes3.player.data.JaceyS) then
        tes3.player.data.JaceyS = {}
    end
    if (not tes3.player.data.JaceyS.MaC) then
        tes3.player.data.JaceyS.MaC = {}
    end
    if (tes3.player.data.JaceyS.MaC.currentMap) then
        local currentMap = tes3.player.data.JaceyS.MaC.currentMap
        if (type(currentMap) == "table") then
            tes3.player.data.JaceyS.MaC.currentMap = tostring(currentMap.mapPack) .. "-" .. tostring(currentMap.map)
            currentMap = tes3.player.data.JaceyS.MaC.currentMap
        end
        if (currentMap ~= "MenuMap_Local" and currentMap ~= "MenuMap_world" and currentMap ~= "noMap") then
            local separator = string.find(currentMap, "-")
            if(separator ~= nil) then
                local mapPack = string.sub(currentMap, 1, separator - 1)
                local map = string.sub(currentMap, separator + 1)
                if (config[mapPack][map].enabled ~= true) then
                    -- clears out bad data if a currently selected map is disabled
                    tes3.player.data.JaceyS.MaC.currentMap = "noMap"
                end
            end
        end
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
        local menuMap = tes3ui.findMenu(id.menuMap)
        local mapMain = menuMap:findChild(id.partDragMenu_main)

        -- This frame holds our custom maps
        if(mapMain:findChild(id.customMap)) then
            mapMain:findChild(id.customMap):destroy()
        end
        local customMap = mapMain:createBlock({id = id.customMap})
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
                    local mapID = tes3ui.registerID(map)
                    local frame = customMap:createBlock({id = mapID})
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
        local menuMap = tes3ui.findMenu(id.menuMap)
        local switch = menuMap:findChild(id.switch)
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
        local menuMap = tes3ui.findMenu(id.menuMap)
        local title = menuMap:findChild(id.title)
        if(config.hideMapTitle) then
            title.visible = false
        else
            title.visible = true
        end
    end
    -- Create the Selection Dropdown, needs to be done before map selected, because that uses info from the dropdown.
    createDropdown()
    mapSelected()
end
event.register("uiActivated", onMenuMapActivated, {filter = "MenuMap"})

local function onSave()
    local menuMap = tes3ui.findMenu(id.menuMap)
    if (menuMap == nil) then return end
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
    keydown = false
end

local function delayAgain()
    timer.delayOneFrame(resetMap, timer.real)
end
escapeReturn = function()
    timer.delayOneFrame(delayAgain, timer.real)
end
local function onMenuOptionsActivated(e)
    onSave()
    local returnButton = e.element:findChild(id.returnButton)
    returnButton:register("mouseClick", function(e)
                                            e.source:forwardEvent(e)
                                            resetMap()
                                        end)
    if (keydown == false) then
        event.register("keyDown", escapeReturn, {filter = tes3.scanCode.escape})
        keydown = true
    end
end



local function onLoaded()
    if (keydown == true) then
        event.unregister("keyDown", escapeReturn, {filter = tes3.scanCode.escape})
        keydown = false
    end
    if (inGame == false) then
        event.register("uiActivated", onMenuOptionsActivated, {filter = "MenuOptions"})
        inGame = true
    end
end
event.register("loaded", onLoaded)

event.register("menuEnter", mapSelected)
event.register("jaceyS_MaC_MCM_Closed", onMenuMapActivated)



createDropdown = function()
    local menuMap = tes3ui.findMenu(id.menuMap)
    local selector = menuMap:findChild(id.selector)
    if(selector) then
        selector:destroy()
    end
    if (config.selectionDropdown) then
        -- Pregenerate the options for the dropdown
        local options = {{label = "Без карты", value = "noMap"}}
        if (config.worldMap) then
            table.insert(options, {label = "Мир", value = "MenuMap_world"})
        end
        if (config.localMap) then
            table.insert(options, {label = "Местность", value = "MenuMap_local"})
        end
        for _, mapPack in pairs(config.mapPacks) do
            local maps = require("Map and Compass.".. mapPack .. ".maps")
            for map, values in pairs(maps) do
                if (config[mapPack] and config[mapPack][map] and config[mapPack][map].enabled) then
                    local option = {}
                    option.label = config[mapPack][map].name
                    if (option.label == nil or option.label == "") then
                        option.label = values.name
                    end
                    option.value = tostring(mapPack) .. "-" ..  tostring(map)
                    table.insert(options, option)
                end
            end
        end

        --Create the dropdown
        local mapMain = menuMap:findChild(id.partDragMenu_main)
        local block = mapMain:createBlock({id = id.selector})
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
        dropdown:create( block ) -- This line assigns the drop down to an element in the UI
        local innerContainer = block:findChild(id.innerContainer)
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

local function onInitialized()
    -- Preloading the IDs seems to work well.
    id.innerContainer = tes3ui.registerID("InnerContainer")
    id.partDragMenu_main = tes3ui.registerID("PartDragMenu_main")
    id.selector = tes3ui.registerID("MenuMap_selector")
    id.menuMap = tes3ui.registerID("MenuMap")
    id.returnButton = tes3ui.registerID("MenuOptions_Return_container")
    id.title = tes3ui.registerID("PartDragMenu_title")
    id.switch = tes3ui.registerID("MenuMap_switch")
    id.customMap = tes3ui.registerID("MenuMap_custom")
    id.menuMulti = tes3ui.registerID("MenuMulti")
    id.notification = tes3ui.registerID("MenuMulti_main")
    id.compassFace = tes3ui.registerID("CompassFace")
    id.compassPanel = tes3ui.registerID("MenuMap_panel")
    id.minimap = tes3ui.registerID("MenuMap_pane")
    id.worldMap = tes3ui.registerID("MenuMap_world")
    id.localMap = tes3ui.registerID("MenuMap_local")
    id.menuOptions = tes3ui.registerID("MenuOptions")
    id.paragraphField = tes3ui.registerID("MaC_NoteEditor_paragraph")
    id.noteEditor = tes3ui.registerID("MaC_NoteEditor")
    id.mapMarker =  tes3ui.registerID("MapMarker")
end
event.register("initialized", onInitialized)

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