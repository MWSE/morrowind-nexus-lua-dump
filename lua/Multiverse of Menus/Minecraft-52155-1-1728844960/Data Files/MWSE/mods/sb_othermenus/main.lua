--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (e.newlyCreated and tes3.player == nil) then
        local iw, ih = 2048, 1024
        local w, h = tes3ui.getViewportSize()

        e.element.absolutePosAlignY = 0.75
        e.element.autoWidth = true
        e.element.autoHeight = true

        local splashMenu = tes3ui.createMenu{ id = "sb_splash", fixedFrame = true }
        splashMenu.alpha = 0
        splashMenu:destroyChildren()
        splashMenu.width = (512 / iw) * w
        splashMenu.height = (256 / ih) * h
        splashMenu.absolutePosAlignX = 1
        splashMenu.absolutePosAlignY = 0

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
                element.paddingAllSides = 4
                for i = 1, 3 do
                    element.children[i].width = (400 / iw) * w
                    element.children[i].height = (40 / ih) * h
                    element.children[i].imageScaleX = (w / iw) * (400 / 512)
                    element.children[i].imageScaleY = (h / ih) * (40 / 64)
                    if (i == 2) then
                        element.children[i].contentPath = ("Textures\\sb_othermenus\\menu_%s.tga"):format(contentPath ..
                            "_over")
                    else
                        element.children[i].contentPath = ("Textures\\sb_othermenus\\menu_%s.tga"):format(contentPath)
                    end
                end
            end
        end

        splashMenu:createImage{ id = "splash", path = ("Textures\\sb_othermenus\\splash%i.tga"):format(math.random(21)) }
        splashMenu:updateLayout()
        e.element:updateLayout()
    end
end

event.register(tes3.event.uiActivated, uiMenuOptionsActivatedCallback, { filter = "MenuOptions" })
