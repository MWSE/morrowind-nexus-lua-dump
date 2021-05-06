--[[
    Big Icons
    v.1.0
    by JaceyS

    Uses loose texture files to replace the small effect icons with their big variants,
    normally used for telling you what spell you have equipped. Goes in with MWSE to rejigger
    the menus to mostly accept the larger icons.

    Compatibility: Will have inconsistent results with mods that replace or add spell effect icons.

    Known issues:
    -the tooltip created when mousing over spell effects in the tray does not show
    the new icon correctly.
    -All but one of the textures included in the mod are renamed vanilla textures.
    I tried to just tell the images to point to those textures, but it did
    not work in the effect tray.
]]
local init = {}

local function onMenuMagicActivated (e)
    if (not e.newlyCreated) then return end
    local menuMagic = tes3ui.findMenu(init.menuMagic)
    local innerList = menuMagic:findChild(init.innerList)
    for _, row in ipairs(innerList.children) do
        row.autoHeight = true
    end
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagic" })
local function onSpellTooltip (e)
    local helpMenu = e.tooltip
    if (helpMenu == nil) then return end
    local effect = helpMenu:findChild(init.effect)
    for _, element in ipairs(effect.children) do
        element.width = 32
        element.height = 32
        for _, subElement in ipairs (element.children) do
            if (subElement.contentType == "image") then
                subElement.width = 32
                subElement.height = 32
            end
            for _, subSubElement in ipairs (subElement.children) do
                if(subSubElement.contentType == "image") then
                    subElement.maxWidth = nil
                    subElement.width = 32
                    subElement.height = 32
                    subSubElement.width = 32
                    subSubElement.height = 32
                end
            end
        end
    end
end
event.register("uiSpellTooltip", onSpellTooltip)

local function onObjectTooltip (e)
    local helpMenu = e.tooltip
    if (helpMenu == nil) then return end
    local image = helpMenu:findChild(init.image)
    image.width = 32
    image.height = 32
    image.parent.maxWidth = nil
    image.parent.width = 32
    image.parent.height = 32
end
event.register("uiObjectTooltip", onObjectTooltip)

local function onInit()
    init = {
        menuMagic = tes3ui.registerID("MenuMagic"),
        innerList = tes3ui.registerID("MagicMenu_icons_list_inner"),

        helpMenu = tes3ui.registerID("HelpMenu"),
        mainPart = tes3ui.registerID("PartHelpMenu_main"),
        effect = tes3ui.registerID("effect"),
        image = tes3ui.registerID("image")
    }
end
event.register("initialized", onInit)