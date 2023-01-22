--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (e.newlyCreated and tes3.player == nil) then
        local iw, ih = 2048, 1024
        local w, h = tes3ui.getViewportSize()

        e.element.absolutePosAlignX = 64 / iw
        e.element.absolutePosAlignY = 1 - 64 / ih
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
                for i = 1, 3 do
                    element.children[i].width = (512 / iw) * w * 0.5
                    element.children[i].height = (128 / ih) * h * 0.5
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
    end
end

event.register(tes3.event.uiActivated, uiMenuOptionsActivatedCallback, { filter = "MenuOptions" })
