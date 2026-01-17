--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (tes3.player == nil) then
        local w, h = tes3ui.getViewportSize()
        
        e.element.autoWidth = false
        e.element.autoHeight = false
        e.element.width = w
        e.element.height = h
        if (e.newlyCreated) then
            local logo = e.element:createBlock()
            logo:createImage{path = "Textures\\sb_othermenus\\logo.tga"}
            logo.width = (w / 1920) * 1472
            logo.autoHeight = true
            logo.absolutePosAlignX = 0.5
            logo.absolutePosAlignY = 0.1
            logo.children[1].imageScaleX = (w / 1920)
            logo.children[1].imageScaleY = (w / 1920)
            logo.children[1].consumeMouseEvents = false
        end
        local content = e.element:getContentElement().children[1]
        content.absolutePosAlignX = 0.5
        content.absolutePosAlignY = 0.9
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
    end
end
event.register(tes3.event.uiActivated, uiMenuOptionsActivatedCallback, { filter = "MenuOptions" })