--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (e.newlyCreated and tes3.player == nil) then
        local iw, ih = 2048, 1024
        local w, h = tes3ui.getViewportSize()

        e.element.absolutePosAlignX = 108 / iw
        e.element.absolutePosAlignY = 0.5 --1 - 32 / ih
        e.element.autoWidth = true
        e.element.autoHeight = true

        local tipMenu = tes3ui.createMenu{ id = "sb_tip", fixedFrame = true }
        tipMenu.alpha = 0
        tipMenu:destroyChildren()
        tipMenu.width = (512 / iw) * w
        tipMenu.height = (64 / ih) * h
        tipMenu.absolutePosAlignX = (108 + 64) / iw
        tipMenu.absolutePosAlignY = (ih - 138) / ih

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
                tipMenu:createImage{ id = contentPath, path = ("Textures\\sb_othermenus\\tooltip_%s.tga"):format(contentPath) }
                for i = 1, 3 do
                    element.children[i].width = (512 / iw) * w
                    element.children[i].height = (64 / ih) * h
                    element.children[i].imageScaleX = (w / iw)
                    element.children[i].imageScaleY = (h / ih)
                    if (i == 2) then
                        element.children[i].contentPath = ("Textures\\sb_othermenus\\menu_%s.tga"):format(contentPath ..
                            "_over")
                    else
                        element.children[i].contentPath = ("Textures\\sb_othermenus\\menu_%s.tga"):format(contentPath)
                    end
                end
                element:registerAfter(tes3.uiEvent.mouseOver, function (e)
                    tipMenu:findChild(contentPath).visible = true
                end)
                element:registerAfter(tes3.uiEvent.mouseLeave, function (e)
                    tipMenu:findChild(contentPath).visible = false
                end)
            end
        end

        tipMenu:updateLayout()
        for _, tip in ipairs(tipMenu.children) do
            tip.visible = false
        end

        e.element:updateLayout()
    end
end

event.register(tes3.event.uiActivated, uiMenuOptionsActivatedCallback, { filter = "MenuOptions" })
