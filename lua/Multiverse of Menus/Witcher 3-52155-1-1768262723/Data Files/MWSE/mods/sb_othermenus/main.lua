--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (e.newlyCreated and tes3.player == nil) then
        local iw, ih = 1920, 1080
        local w, h = tes3ui.getViewportSize()

        e.element.positionX = (-(iw / 2) + 159) * (w / iw)
        e.element.absolutePosAlignY = 0.5
        e.element.autoWidth = true
        e.element.autoHeight = true
        e.element.ignoreLayoutX = true

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
                for i = 1, 3 do
                    element.children[i].width = (360 / iw) * w
                    element.children[i].height = (40 / ih) * h
                    element.children[i].imageScaleX = (w / iw)
                    element.children[i].imageScaleY = (h / ih)
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
