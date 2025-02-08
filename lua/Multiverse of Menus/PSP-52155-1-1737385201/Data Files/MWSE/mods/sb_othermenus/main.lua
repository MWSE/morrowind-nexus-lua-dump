--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (tes3.player == nil) then
        local iw = 1920
        local w, h = tes3ui.getViewportSize()
        local newScale = w > iw and (w / iw) or (iw / w)
       
        e.element.autoWidth = false
        e.element.autoHeight = false
        e.element.width = w
        e.element.height = h
        if (e.newlyCreated) then
            local logo = e.element:createImage{path = "Textures\\sb_othermenus\\logo.tga"}
            logo.imageScaleX = newScale
            logo.imageScaleY = newScale
            logo.autoWidth = true
            logo.autoHeight = true
            logo.absolutePosAlignX = 1
            logo.absolutePosAlignY = 0
            logo.consumeMouseEvents = false
        end
        local content = e.element:getContentElement().children[1]
        content.flowDirection = tes3.flowDirection.leftToRight
        content.ignoreLayoutY = true
        content.positionY = -128 * newScale
        ---@param element tes3uiElement
        for _, element in ipairs(content.children) do
            local contentPath = element.name:find("_New") and "newgame" or
                element.name:find("_Load") and "loadgame" or
                element.name:find("_Options") and "options" or
                element.name:find("_MCM") and "modconfig" or
                element.name:find("_Credits") and "credits" or
                element.name:find("_Exit") and "exitgame"
            if (contentPath) then
                element.autoWidth = true
                element.autoHeight = true
                element.borderLeft = 32
                element.borderRight = 32
                for i = 1, 3 do
                    element.children[i].width = 256 * newScale
                    element.children[i].height = 668 * newScale
                    if (i == 2) then
                        element.children[i].contentPath = ("Textures\\sb_othermenus\\menu_%s.tga"):format(contentPath ..
                            "_over")
                    else
                        element.children[i].contentPath = ("Textures\\sb_othermenus\\menu_%s.tga"):format(contentPath)
                    end
                end
            end
        end
        for i = 0, #content.children - 1, 1 do
            content:reorderChildren(i, -1, 1)
        end

        e.element:updateLayout()

        timer.start{ type = timer.real, duration = 0.1, persist = false, callback = function()
            local topMostNode = e.element.sceneNode
            while topMostNode.parent do
                topMostNode = topMostNode.parent
            end
            local cursor = topMostNode:getObjectByName("cursor")
            local texturingProperty = cursor.texturingProperty
            local map = texturingProperty.baseMap
            local texture = niSourceTexture.createFromPath("Textures\\sb_othermenus\\cursor.tga")
            map.texture = texture
            cursor:updateProperties()
        end }
    end
end

event.register(tes3.event.uiActivated, uiMenuOptionsActivatedCallback, { filter = "MenuOptions" })

--- @param e loadEventData
local function loadCallback(e)
    local topMostNode = tes3ui.findMenu("MenuOptions").sceneNode
    while topMostNode.parent do
        topMostNode = topMostNode.parent
    end
    local cursor = topMostNode:getObjectByName("cursor")
    local texturingProperty = cursor.texturingProperty
    local map = texturingProperty.baseMap
    local texture = niSourceTexture.createFromPath("Textures\\cursor_drop.dds")
    map.texture = texture
    cursor:updateProperties()
end

event.register(tes3.event.load, loadCallback)
