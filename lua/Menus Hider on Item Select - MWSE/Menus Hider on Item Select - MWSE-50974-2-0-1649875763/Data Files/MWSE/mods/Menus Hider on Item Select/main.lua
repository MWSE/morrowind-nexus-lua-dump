

local function invisibleMenuMagic()
    local menuMap = tes3ui.findMenu("MenuMap")
    menuMap.visible = true
    local menuStat = tes3ui.findMenu("MenuStat")
    menuStat.visible = true
    local menuMagic = tes3ui.findMenu("MenuMagic")
    menuMagic.visible = false
end


local function invisibleMenuMap()
    local menuMagic = tes3ui.findMenu("MenuMagic")
    menuMagic.visible = true
    local menuStat = tes3ui.findMenu("MenuStat")
    menuStat.visible = true
    local menuMap = tes3ui.findMenu("MenuMap")
    menuMap.visible = false
end


local function invisibleMenuStat()
    local menuMap = tes3ui.findMenu("MenuMap")
    menuMap.visible = true
    local menuMagic = tes3ui.findMenu("MenuMagic")
    menuMagic.visible = true
    local menuStat = tes3ui.findMenu("MenuStat")
    menuStat.visible = false
end

local function visibleMenu()
    local menuMap = tes3ui.findMenu("MenuMap")
    menuMap.visible = true
    local menuMagic = tes3ui.findMenu("MenuMagic")
    menuMagic.visible = true
    local menuStat = tes3ui.findMenu("MenuStat")
    menuStat.visible = true


end

local function invisibleMenu()
    local menuMap = tes3ui.findMenu("MenuMap")
    menuMap.visible = false
    local menuMagic = tes3ui.findMenu("MenuMagic")
    menuMagic.visible = false
    local menuStat = tes3ui.findMenu("MenuStat")
    menuStat.visible = false
end



--[[local function onInventory(e)
    e.element:registerBefore("mouseClick", invisibleMenu)
    e.element:registerBefore("mouseClick", function()

        local succes = pcall(function()
        local c = tes3ui.findHelpLayerMenu("CursorIcon"):getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
        local pcInventory = tes3.player.object.inventory
        return assert(
            pcInventory:contains(c.item, c.itemData)
            and pcInventory:contains(e.item, e.itemData)
            and c
        )
        end)
        if succes then
            visibleMenu()
        end
    end)
end


event.register("itemTileUpdated", onInventory, {filter = "MenuInventory"})]]

local function test()
    if not tes3.menuMode then return end
    local menuBarter = tes3ui.findMenu("MenuBarter")
    local menuContents = tes3ui.findMenu("MenuContents")
    local menuAlchemy = tes3ui.findMenu("MenuAlchemy")
    local menuEnchant = tes3ui.findMenu("MenuEnchantment")
    local menuRepair = tes3ui.findMenu("MenuRepair")
    --if menuBarter and menuBarter.visible == true then return end
    local menuInventory = tes3ui.findMenu("MenuInventory")
    local menuMagic = tes3ui.findMenu("MenuMagic")
    local menuStat = tes3ui.findMenu("MenuStat")
    local menuMap = tes3ui.findMenu("MenuMap")
    local menuMap2
    local menuMap3
    if menuMap then
        menuMap2 = menuMap:findChild("MenuMap_world")
        menuMap3 = menuMap:findChild("MenuMap_local")
    end

    local success, errMsg = pcall(function()
        local c = tes3ui.findHelpLayerMenu("CursorIcon"):getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
        local pcInventory = tes3.player.object.inventory
        return assert(
            pcInventory:contains(c.item, c.itemData)
            and c
        )
        end)

        --success = tes3ui.findHelpLayerMenu("CursorIcon")

        if success then
            menuStat:register("mouseOver", invisibleMenuStat)
            --menuInventory:register("mouseOver", visibleMenuMagic)
            --menuInventory:register("mouseOver", visibleMenuMap)
            menuMagic:register("mouseOver", invisibleMenuMagic)
            --menuMagic:register("mouseLeave", visibleMenu)
            menuMap2:register("mouseOver", invisibleMenuMap)
            menuMap3:register("mouseOver", invisibleMenuMap)
            if menuAlchemy then invisibleMenu() end
            if menuEnchant then invisibleMenu() end
            if menuRepair then invisibleMenu() end
            if not menuBarter and not menuContents then menuInventory:register("mouseOver", visibleMenu) end
            --menuMap:register("mouseLeave", visibleMenuMap)
        elseif errMsg then pcall(function()
            menuStat:unregister("mouseOver")
            --menuInventory:register("mouseOver", visibleMenuMagic)
            --menuInventory:register("mouseOver", visibleMenuMap)
            menuMagic:unregister("mouseOver")
            --menuMagic:register("mouseLeave", visibleMenu)
            menuMap2:unregister("mouseOver")
            menuMap3:unregister("mouseOver")
             end)
             if menuAlchemy then invisibleMenu() end
             if menuEnchant then invisibleMenu() end
             if menuRepair then invisibleMenu() end
             if menuInventory and (not menuBarter and not menuContents) then menuInventory:register("mouseOver", visibleMenu) elseif menuInventory and (menuBarter or menuContents) then menuInventory:register("mouseOver", invisibleMenu) end
            --menuMap:register("mouseLeave", visibleMenuMap)
        end
end
event.register("enterFrame", test)


local function initialized()
print("[Menus Hider on Item Select] Initialized.")
end

event.register("initialized", initialized)