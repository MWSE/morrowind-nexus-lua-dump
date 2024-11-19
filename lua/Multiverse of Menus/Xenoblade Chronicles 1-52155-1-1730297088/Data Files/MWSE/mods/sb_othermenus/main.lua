--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (e.newlyCreated and tes3.player == nil) then
        local iw, ih = 2048, 1024
        local w, h = tes3ui.getViewportSize()

        e.element.absolutePosAlignY = 0.75
        e.element.autoWidth = true
        e.element.autoHeight = true

        ---@param element tes3uiElement
        for _, element in ipairs(e.element:getContentElement().children[1].children) do
            local contentPath = element.name:find("_New") and "newgame" or
                element.name:find("_Load") and "loadgame" or
                element.name:find("_Options") and "options" or
                element.name:find("_MCM") and "modconfig" or
                element.name:find("_Credits") and "credits" or
                element.name:find("_Exit") and "exitgame"
            if (contentPath) then
                element.autoWidth = true
                element.autoHeight = true
                element.borderAllSides = 8
                for i = 1, 3 do
                    element.children[i].width = (512 / iw) * w * 0.5
                    element.children[i].height = (64 / ih) * h * 0.5
                    element.children[i].imageScaleX = (w / iw) * 0.5
                    element.children[i].imageScaleY = (h / ih) * 0.5
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

        local topMostNode = e.element.sceneNode
        while topMostNode.parent do
            topMostNode = topMostNode.parent
        end
        local cursor = topMostNode:getObjectByName("cursor")
        local texturingProperty = cursor.texturingProperty
        local map = texturingProperty.baseMap
        local texture = niSourceTexture.createFromPath("Icons\\w\\tx_art_keening.dds")
        map.texture = texture
        cursor:updateProperties()
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