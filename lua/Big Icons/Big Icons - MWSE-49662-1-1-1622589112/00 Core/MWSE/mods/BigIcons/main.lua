--[[
    Big Icons
    v.1.1, Vectorized
    by JaceyS

    Uses loose texture files to replace the small effect icons with their bigger icons. Goes in with MWSE to rejigger
    the menus to mostly accept the larger icons.

    New in 1.1:
    Now supports multiple sizes of icons, and comes packaged with remastered hi-res icons from Jacey's Vector Icons resource pack.
    Added an MCM to adjust the size (should come pre-set with your pack.)

    Compatibility: Will have inconsistent results with mods that replace or add spell effect icons.

    Known issues:
    -the tooltip created when mousing over spell effects in the tray does not show
    the new icon correctly.

]]
local init = {}
local defaultConfig = {
    pixels = 32
}
local config = mwse.loadConfig("BigIcons", defaultConfig)

local function onSpellEfectTooltip (e)
    tes3.messageBox("Test!")
    e.source:forwardEvent(e)
    local helpMenu = tes3ui.findHelpLayerMenu({id = init.helpMenu})
    if (helpMenu == nil) then return end
    local image = helpMenu:findChild(init.image)
    if (image == nil) then return end
    image.width = tonumber(config.pixels)
    image.height = tonumber(config.pixels)
end

local function onMenuMagicActivated (e)
    if (not e.newlyCreated) then return end
    local menuMagic = tes3ui.findMenu(init.menuMagic)
    local innerList = menuMagic:findChild(init.innerList)
    for _, row in ipairs(innerList.children) do
        row.autoHeight = true
        -- This was a failed attempt at grabbing the spell effect tooltip. Threw no errors, but the registered event never triggered, and the tooltip was made as normal.
        --for _, child in ipairs(row.children) do
        --    child:register("help", onSpellEfectTooltip)
        --end
    end
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagic" })

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