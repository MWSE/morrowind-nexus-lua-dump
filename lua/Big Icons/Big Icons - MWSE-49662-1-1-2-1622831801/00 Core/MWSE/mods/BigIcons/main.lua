--[[
Big Icons
v.1.1.2, Vectorized
by JaceyS

Uses loose texture files to replace the small effect icons with bigger icons. Goes in with MWSE to rejigger the menus to mostly accept the larger icons. Alternatively, works well with the UI scaling in OpenMW.

New in 1.1.2:
MWSE only update, fixes the issue with spell effect tooltips!
New in 1.1.1:
Changed my choice of alternate icons to be the default. All alternatives are still included, appended with either "_ori" or "_alt".
Added missing icons pointed out in JVI by hokan45.
New in 1.1:
Now supports multiple sizes of icons, and comes packaged with remastered hi-res icons from Jacey's Vector Icons resource pack.
Added an MCM to adjust the size (should come pre-set with your pack.)

Compatibility: Will have inconsistent results with mods that replace or add spell effect icons.


Coming in the future:
- Magicka Expanded compatibility. If there are non-ME mods that add icons, let me know!
- If there are any OpenMW compatible mods that add spell effects, let me know and I can remaster the icons for them.
- Resizing of icons in other contexts for MWSE?
]]

local init = {}
local defaultConfig = {
    pixels = 32
}
local config = mwse.loadConfig("BigIcons", defaultConfig)

local function onSpellEfectTooltip (e)
    e.source:forwardEvent(e)
    local helpMenu = tes3ui.findHelpLayerMenu(init.helpMenu)
    if (helpMenu == nil) then return end
    local image = helpMenu:findChild(init.image)
    if (image == nil) then return end
    image.width = tonumber(config.pixels)
    image.height = tonumber(config.pixels)
end

local function onMenuMagicActivated()
    local menuMagic = tes3ui.findMenu(init.menuMagic)
    local innerList = menuMagic:findChild(init.innerList)
    for _, row in ipairs(innerList.children) do
        row.autoHeight = true
        for _, child in ipairs(row.children) do
            child:register("help", onSpellEfectTooltip)
        end
    end
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagic" })
event.register("loaded", onMenuMagicActivated) -- needs to call the function on loaded as well, because the above event fires before the help uiEvents are registered in the first place, so they get overwritten.

local function onMenuMultiActivated()
    local menuMulti = tes3ui.findMenu(init.menuMulti)
    local box = menuMulti:findChild(init.box)
    for _, subBox in ipairs(box.children) do
        for _, icon in ipairs(subBox.children) do
            icon:register("help", onSpellEfectTooltip)
        end
    end
end
event.register("uiActivated", onMenuMultiActivated, {filter = "MenuMulti"})
event.register("loaded", onMenuMultiActivated)

local function onSpellTooltip (e)
    local helpMenu = e.tooltip
    if (helpMenu == nil) then return end
    local effect = helpMenu:findChild(init.effect)
    for _, element in ipairs(effect.children) do
        element.width = tonumber(config.pixels)
        element.height = tonumber(config.pixels)
        for _, subElement in ipairs (element.children) do
            if (subElement.contentType == "image") then
                subElement.width = tonumber(config.pixels)
                subElement.height = tonumber(config.pixels)
            end
            for _, subSubElement in ipairs (subElement.children) do
                if(subSubElement.contentType == "image") then
                    subElement.maxWidth = nil
                    subElement.width = tonumber(config.pixels)
                    subElement.height = tonumber(config.pixels)
                    subSubElement.width = tonumber(config.pixels)
                    subSubElement.height = tonumber(config.pixels)
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
    if (image == nil) then return end
    image.width = tonumber(config.pixels)
    image.height = tonumber(config.pixels)
    image.parent.maxWidth = nil
    image.parent.width = tonumber(config.pixels)
    image.parent.height = tonumber(config.pixels)
end
event.register("uiObjectTooltip", onObjectTooltip)

local function onInit()
    init = {
        menuMagic = tes3ui.registerID("MenuMagic"),
        innerList = tes3ui.registerID("MagicMenu_icons_list_inner"),

        helpMenu = tes3ui.registerID("HelpMenu"),
        mainPart = tes3ui.registerID("PartHelpMenu_main"),
        effect = tes3ui.registerID("effect"),
        image = tes3ui.registerID("image"),
        multiIcons1 = tes3ui.registerID("MenuMulti_magic_icons_1"),
        multiIcons2 = tes3ui.registerID("MenuMulti_magic_icons_2"),
        multiIcons3 = tes3ui.registerID("MenuMulti_magic_icons_3"),
        magicIcons1 = tes3ui.registerID("MagicMenu_t_icon_row_1"),
        magicIcons2 = tes3ui.registerID("MagicMenu_t_icon_row_2"),
        magicIcons3 = tes3ui.registerID("MagicMenu_t_icon_row_3"),
        menuMulti = tes3ui.registerID("MenuMulti"),
        box = tes3ui.registerID("MenuMulti_magic_icons_box")
    }
end
event.register("initialized", onInit)

event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate("Big Icons")
    template:saveOnClose("BigIcons", config)
    local page = template:createSideBarPage()
    page.label = "General Settings"
    page.description = "Big Icons\nby JaceyS"

    page:createTextField({
        numbersOnly = true,
        label = "Pixels",
        description = "Height and Width of your icons, in pixels. Corresponds to the pack you have installed. Vanilla is 16.",
        variable = mwse.mcm:createTableVariable{id = "pixels", table = config}
    })
    mwse.mcm.register(template)
end)