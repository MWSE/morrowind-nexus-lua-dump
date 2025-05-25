-- Configuration with map's Construction Set Item ID, file path, and map size (should be square)
local config = {
    mapItemId    = "map_paper_vvardenfell",
    mapImagePath = "textures/pm/paper_map.dds",
    mapWidth     = 2048,
    mapHeight    = 2048,
}

-- Global variables
local main_map_menu  -- Reference for the UI menu; nil when closed.
local lastMouseX, lastMouseY = 0, 0  -- For drag calculations.
local width, height = 0, 0           -- Current (scaled) image dimensions.
local current_map = config.mapImagePath
local windowSize = 800

-- Checks if player has map
local function hasMapItem()
    local player = tes3.player
    if player and player.object then
        for _, stack in pairs(player.object.inventory) do
            if stack.object.id == config.mapItemId then
                return true
            end
        end
    end
    return false
end

-- Zoom In function without clamping, top–left alignment system
local function zoomIn(e)
    if current_map == nil then return end

    local menu = e.source
    local image = menu:findChild(config.mapItemId)
    if not image then return end
    local container = image.parent

    -- Calculate unscaled dimensions (should equal config dimensions)
    local unscaledW = image.width  / image.imageScaleX
    local unscaledH = image.height / image.imageScaleY
    -- With top–left alignment, unscaled offset is simple:
    local unscaledOffX = container.childOffsetX / image.imageScaleX
    local unscaledOffY = container.childOffsetY / image.imageScaleY

    local newScale = math.min(image.imageScaleX + 0.1, 3)
    image.imageScaleX = newScale
    image.imageScaleY = newScale

    image.width  = unscaledW * newScale
    image.height = unscaledH * newScale
    width  = image.width
    height = image.height

    local newOffX = unscaledOffX * newScale
    local newOffY = unscaledOffY * newScale

    -- (No clamping here: let the user pan freely.)
    container.childOffsetX = newOffX
    container.childOffsetY = newOffY

    menu:updateLayout()
end

-- Zoom Out function
local function zoomOut(e)
    if current_map == nil then return end

    local menu = e.source
    local image = menu:findChild(config.mapItemId)
    if not image then return end
    local container = image.parent

    local unscaledW = image.width  / image.imageScaleX
    local unscaledH = image.height / image.imageScaleY

    -- Prevent zooming out so that the image becomes smaller than the container.
    if (unscaledW * (image.imageScaleX - 0.1) < container.width) or 
       (unscaledH * (image.imageScaleY - 0.1) < container.height) then
        return
    end

    local unscaledOffX = container.childOffsetX / image.imageScaleX
    local unscaledOffY = container.childOffsetY / image.imageScaleY

    local newScale = math.max(0.1, image.imageScaleX - 0.1)
    image.imageScaleX = newScale
    image.imageScaleY = newScale

    image.width  = unscaledW * newScale
    image.height = unscaledH * newScale
    width  = image.width
    height = image.height

    local newOffX = unscaledOffX * newScale
    local newOffY = unscaledOffY * newScale

    -- If we've zoomed back out to the initial scale, re-center (Doesn't work)
    local initialScale = windowSize / config.mapWidth  -- e.g. 800/2048
    if newScale == initialScale then
        newOffX = 0
        newOffY = 0
    end

    container.childOffsetX = newOffX
    container.childOffsetY = newOffY

    menu:updateLayout()
end

-- Click and Drag function without clamping. Add the mouse delta to the container’s child offset.
local function startDrag(e)
    if current_map == nil then return end
    tes3ui.captureMouseDrag(true)
    lastMouseX = e.data0
    lastMouseY = e.data1
end

local function releaseDrag(e)
    if current_map == nil then return end
    tes3ui.captureMouseDrag(false)
end

local function dragController(e)
    if current_map == nil then return end

    local dx = e.data0 - lastMouseX
    local dy = e.data1 - lastMouseY

    local menu = tes3ui.findMenu("PaperMapMenu")
    if not menu then return end
    local pane = menu:findChild("PartDragMenu_main")
    if not pane then return end

    pane.childOffsetX = pane.childOffsetX + dx
    pane.childOffsetY = pane.childOffsetY + dy

    lastMouseX = e.data0
    lastMouseY = e.data1

    menu:updateLayout()
end

-- Toggle map function. This creates an 800×800 UI window. Offsets are measured from the top–left corner.
local function togglePaperMap()
    if main_map_menu then
        main_map_menu:destroy()
        main_map_menu = nil
        return
    end
  
    if not hasMapItem() then
        tes3.messageBox("You do not possess a map of Vvardenfell.")
        return
    end

    -- Force menu mode activation so the cursor appears immediately
    tes3ui.enterMenuMode(menuID)

    local initialScale = windowSize / config.mapWidth  

    main_map_menu = tes3ui.createMenu({ id = "PaperMapMenu", fixedFrame = true })
    main_map_menu.text = "Paper Map of Vvardenfell"
    main_map_menu.width = windowSize
    main_map_menu.height = windowSize
    main_map_menu.positionX = 50
    main_map_menu.positionY = 50

    local mapPane = main_map_menu:createBlock({ id = "PartDragMenu_main" })
    mapPane.width = main_map_menu.width
    mapPane.height = main_map_menu.height
    mapPane.childAlignX = 0  
    mapPane.childAlignY = 0  
    mapPane.childOffsetX = 0
    mapPane.childOffsetY = 0

    main_map_menu:updateLayout()

    local mapImage = mapPane:createImage({ id = config.mapItemId, path = current_map })
    mapImage.imageScaleX = initialScale
    mapImage.imageScaleY = initialScale
    mapImage.width = config.mapWidth * initialScale  
    mapImage.height = config.mapHeight * initialScale  
    width = mapImage.width  
    height = mapImage.height  
    lastMouseX = 0
    lastMouseY = 0

    main_map_menu:updateLayout()

    main_map_menu:register("mouseScrollUp", zoomIn)
    main_map_menu:register("mouseScrollDown", zoomOut)
    main_map_menu:register("mouseDown", startDrag)
    main_map_menu:register("mouseRelease", releaseDrag)
    main_map_menu:register("mouseStillPressed", dragController)
end

-- HOTKEY: Toggle the map UI when M is pressed.
event.register("keyDown", function(e)
    if e.keyCode == tes3.scanCode.m then
        togglePaperMap()
    end
end)

-- Register event to activate the map when equipped in the inventory
event.register("equip", function(e)
    if e.item.id == config.mapItemId then
        togglePaperMap() -- Open the map UI
        return false -- Prevent default equip behavior
    end
end)

-- Cleanup on menu exit
event.register("menuExit", function(e)
    if e.menu and e.menu.id == "PaperMapMenu" then
        main_map_menu = nil
    end
end)

mwse.log("Paper Map mod initialized")