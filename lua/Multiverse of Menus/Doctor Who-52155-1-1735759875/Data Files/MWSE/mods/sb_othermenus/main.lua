--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (tes3.player == nil) then
        local iw, ih = 2048, 1024
        local w, h = tes3ui.getViewportSize()
        
        e.element.autoWidth = false
        e.element.autoHeight = false
        e.element.width = w
        e.element.height = h
        if (e.newlyCreated) then
            local logo = e.element:createImage{path = "Textures\\menu_morrowind.tga"}
            logo.imageScaleX = (w / iw)
            logo.imageScaleY = (w / iw)
            logo.positionX = 0
            logo.positionY = 0
            logo.ignoreLayoutX = true
            logo.ignoreLayoutY = true
            logo.consumeMouseEvents = false
        end
        local content = e.element:getContentElement().children[1]
        content.absolutePosAlignX = 0.5
        content.absolutePosAlignY = 0.95
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
                for i = 1, 3 do
                    element.children[i].width = 256
                    element.children[i].height = 64
                    if (i == 2) then
                        element.children[i].contentPath = ("Textures\\sb_othermenus\\menu_%s.tga"):format(contentPath ..
                            "_over")
                    else
                        element.children[i].contentPath = ("Textures\\sb_othermenus\\menu_%s.tga"):format(contentPath)
                    end
                end
            end
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
            local texture = niSourceTexture.createFromPath("Textures\\sb_othermenus\\icon.tga")
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
