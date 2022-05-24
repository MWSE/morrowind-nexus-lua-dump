local mod = {
    name = "Replica",
    ver = "1.0",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)



local menu

mod.moveit = function(e)
    --local map = e.element:findChild("MenuMulti_map")
    --map.absolutePosAlignX = 0.038
    --map.absolutePosAlignY = 0.049
    menu.absolutePosAlignX = e.absolutePosAlignX-1.8
    menu.absolutePosAlignY = e.absolutePosAlignY-2.9
end


local function getMemoryUsageInMB()
	return mwse.getVirtualMemoryUsage() / 1024 / 1024
end

local function onMemoryUsageHelp(e)
	local tooltip = tes3ui.createTooltipMenu()
	tooltip:createLabel({ text = string.format("Total usage: %d MB", getMemoryUsageInMB()) })
	tooltip:createLabel({ text = string.format("Lua usage: %d MB", collectgarbage("count") / 1024) })
end

mod.loaded = function(e)
    if not e.newlyCreated then return end
    local parent = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main"))
    menu = parent:createRect({id = "Spa_replica", color = {0.0, 0.0, 0.0}})
    menu.alpha = 0
    menu.width = 1000
    menu.height = 146
    menu.absolutePosAlignX = 0.02
    menu.absolutePosAlignY = 0.02
    local vanillasneak = e.element:findChild("MenuMulti_fillbars")
    vanillasneak.visible = tes3.isLuaModActive("mer\\ashfall")
    local sneak = parent:createImage({id = "Spa_sneak", path = "Textures\\ui\\sneak.dds"})
    sneak.absolutePosAlignX = 0.5
    sneak.absolutePosAlignY = 0.5
    sneak.visible = false
    local block1 = parent:createRect({id = "Spa_lung", color = {0,0,0}})
    block1.alpha = 0
    block1.width = 250
    block1.height = 40
    block1.absolutePosAlignX = 0.5
    block1.absolutePosAlignY = 0.05
    local fill = block1:createFillBar({id = "Spa_breathFill", current = 20, max = 20})
    fill.width = 215
    fill.height = 15
    fill.absolutePosAlignX = 0.888
    fill.absolutePosAlignY = 0.506
    fill.widget.fillColor = tes3ui.getPalette("misc_color")
    fill.widget.showText = false
    --fill.visible = false
    local breath = block1:createImage({id = "Spa_breath", path = "Textures\\ui\\breathbarfull.dds"})
    breath.absolutePosAlignX = 0.5
    breath.absolutePosAlignY = 0.5
    --breath.visible = false
    breath.scaleMode = true
    breath.height = 32
    breath.width = 240

    local health = menu:createImage({path = "Textures\\ui\\healthbar.dds"})
    health.scaleMode = true
    health.height = 32
    health.width = 240
    health.absolutePosAlignX = 0.16
    health.absolutePosAlignY = 0.15
    local healthfill = health:createFillBar({id = "Spa_health", current = tes3.mobilePlayer.health.current, max = tes3.mobilePlayer.health.base})
    healthfill.widget.showText = false
    healthfill.absolutePosAlignX = 0.16
    healthfill.absolutePosAlignY = 0.520
    healthfill.height = 14
    healthfill.width = 210

    local enchfill = health:createFillBar({id = "Spa_weacon", current = 1, max = 1})
    enchfill.widget.showText = false
    enchfill.widget.fillColor = tes3ui.getPalette("misc_color")
    enchfill.absolutePosAlignX = 0.35
    enchfill.absolutePosAlignY = 0.9
    enchfill.height = 10

    local magicka = menu:createImage({path = "Textures\\ui\\magickabar.dds"})
    magicka.scaleMode = true
    magicka.height = 32
    magicka.width = 240
    magicka.absolutePosAlignX = 0.16
    magicka.absolutePosAlignY = 0.45
    local magickafill = magicka:createFillBar({id = "Spa_magicka", current = tes3.mobilePlayer.magicka.current, max = tes3.mobilePlayer.magicka.base})
    magickafill.widget.showText = false
    magickafill.widget.fillColor = tes3ui.getPalette("magic_color")
    magickafill.absolutePosAlignX = 0.35
    magickafill.absolutePosAlignY = 0.520
    magickafill.height = 14

    local enchfill2 = magicka:createFillBar({id = "Spa_enchance", current = 1, max = 1})
    enchfill2.widget.showText = false
    enchfill2.widget.fillColor = tes3ui.getPalette("misc_color")
    enchfill2.absolutePosAlignX = 0.35
    enchfill2.absolutePosAlignY = 0.9
    enchfill2.height = 10
    local stamina = menu:createImage({path = "Textures\\ui\\staminabar.dds"})
    stamina.scaleMode = true
    stamina.height = 32
    stamina.width = 240
    stamina.absolutePosAlignX = 0.16
    stamina.absolutePosAlignY = 0.75
    local staminafill = stamina:createFillBar({id = "Spa_fatigue", current = tes3.mobilePlayer.fatigue.current, max = tes3.mobilePlayer.fatigue.base})
    staminafill.widget.showText = false
    staminafill.widget.fillColor = tes3ui.getPalette("fatigue_color")
    staminafill.absolutePosAlignX = 0.16
    staminafill.absolutePosAlignY = 0.520
    staminafill.height = 14
    staminafill.width = 210
    --staminafill.contentPath = "button.nif"

    local enchfill3 = stamina:createFillBar({id = "Spa_weacharge", current = 1, max = 1})
    enchfill3.widget.showText = false
    enchfill3.widget.fillColor = tes3ui.getPalette("misc_color")
    enchfill3.absolutePosAlignX = 0
    enchfill3.absolutePosAlignY = 0.9
    enchfill3.height = 10
    enchfill3.width = 216
    enchfill3.visible = tes3.isLuaModActive("Memory Monitor")
    enchfill3:register(tes3.uiEvent.help, onMemoryUsageHelp)

    local health2 = menu:createImage({path = "Textures\\ui\\healthbar.dds"})
    health2.scaleMode = true
    health2.height = 32
    health2.width = 240
    health2.absolutePosAlignX = 0.16
    health2.absolutePosAlignY = 0.15
    local magicka2 = menu:createImage({path = "Textures\\ui\\magickabar.dds"})
    magicka2.scaleMode = true
    magicka2.height = 32
    magicka2.width = 240
    magicka2.absolutePosAlignX = 0.16
    magicka2.absolutePosAlignY = 0.45
    local stamina2 = menu:createImage({path = "Textures\\ui\\staminabar.dds"})
    stamina2.scaleMode = true
    stamina2.height = 32
    stamina2.width = 240
    stamina2.absolutePosAlignX = 0.16
    stamina2.absolutePosAlignY = 0.75

    local block = menu:createRect({id = "Spa_HotQuick", color = {0.0, 0.0, 0.0}})
    block:destroyChildren()
    block.width = 146
    block.height = 146
    block.alpha = 0
    block.paddingAllSides = -1
    block.flowDirection = "top_to_bottom"
    local main = block:createImage({path = "Textures\\ui\\compass.dds"})
    main.scaleMode = true
    main.width = 146
    main.height = 146
    local lock = main:createImage({id = "Spa_lock", path = "Textures\\ui\\compass_hidden.dds"})
    lock.scaleMode = true
    lock.width = 146
    lock.height = 146
    lock.visible = false
    local magicItem = tes3.mobilePlayer.currentEnchantedItem
    local magicSpell = tes3.mobilePlayer.currentSpell
    local block2 = block:createRect({id = "Spa_magic", color = {0.0, 0.0, 0.0}})
    block2:destroyChildren()
    block2.width = 32
    block2.height = 32
    block2.alpha = 0
    block2.paddingAllSides = -1
    block2.absolutePosAlignX = 0.2498
    block2.absolutePosAlignY = 0.79
    if magicItem and magicItem.object then
        local icon = magicItem.object.icon
        local texture = block2:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
        texture.scaleMode = true
        texture.width = 29
        texture.height = 29
        local shadowIcon = texture:createImage({path = "Icons\\" ..icon})
        shadowIcon.color = {0.0, 0.0, 0.0}
        shadowIcon.absolutePosAlignX = 0.6
        shadowIcon.absolutePosAlignY = 0.7
        shadowIcon.scaleMode = true
        shadowIcon.width = 29
        shadowIcon.height = 29
        local Icon = texture:createImage({path = "Icons\\"..icon})
        Icon.absolutePosAlignX = 0.5
        Icon.absolutePosAlignY = 0.5
        Icon.scaleMode = true
        Icon.width = 29
        Icon.height = 29
    elseif magicSpell then
        local icon = magicSpell.effects[1].object.bigIcon
        local texture = block2:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
        texture.scaleMode = true
        texture.width = 29
        texture.height = 29
        local shadowIcon = texture:createImage({path = "Icons\\" ..icon})
        shadowIcon.color = {0.0, 0.0, 0.0}
        shadowIcon.absolutePosAlignX = 0.6
        shadowIcon.absolutePosAlignY = 0.7
        shadowIcon.scaleMode = true
        shadowIcon.width = 29
        shadowIcon.height = 29
        local Icon = texture:createImage({path = "Icons\\"..icon})
        Icon.absolutePosAlignX = 0.5
        Icon.absolutePosAlignY = 0.5
        Icon.scaleMode = true
        Icon.width = 29
        Icon.height = 29
    end
    local ring = block:createImage({id = "Spa_magicRing", path = "Textures\\ui\\compass_ring.dds"})
    ring.scaleMode = true
    ring.width = 48
    ring.height = 48
    ring.absolutePosAlignX = 0.185
    ring.absolutePosAlignY = 0.818

    local weapon = tes3.mobilePlayer.readiedWeapon
    local block3 = block:createRect({id = "Spa_weapon", color = {0.0, 0.0, 0.0}})
    block3:destroyChildren()
    block3.width = 32
    block3.height = 32
    block3.paddingAllSides = -1
    block3.absolutePosAlignX = 0.894
    block3.absolutePosAlignY = 0.165
    block3.alpha = 0
    if weapon and weapon.object and weapon.object.enchantment then
        local icon = weapon.object.icon
        local texture = block3:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
        texture.scaleMode = true
        texture.width = 29
        texture.height = 29
        local shadowIcon = texture:createImage({path = "Icons\\" ..icon})
        shadowIcon.color = {0.0, 0.0, 0.0}
        shadowIcon.absolutePosAlignX = 0.6
        shadowIcon.absolutePosAlignY = 0.7
        shadowIcon.scaleMode = true
        shadowIcon.width = 29
        shadowIcon.height = 29
        local Icon = texture:createImage({path = "Icons\\"..icon})
        Icon.absolutePosAlignX = 0.5
        Icon.absolutePosAlignY = 0.5
        Icon.scaleMode = true
        Icon.width = 29
        Icon.height = 29
    elseif weapon and weapon.object then
        local icon = weapon.object.icon
        local texture = block3:createImage({path = "Icons\\"..icon})
        texture.scaleMode = true
        texture.width = 29
        texture.height = 29
    end
    local ring2 = block:createImage({id = "Spa_weaponRing", path = "Textures\\ui\\compass_ring.dds"})
    ring2.scaleMode = true
    ring2.width = 48
    ring2.height = 48
    ring2.absolutePosAlignX = 0.97
    ring2.absolutePosAlignY = 0.12
end

local breathtimer
local left = 19




function mod.enterFrame()
    local menu2 = tes3ui.findMenu("MenuMulti")
    if not menu2 then return end
    --[[local visibilityTable = {
        [2] = menu2:findChild("Spa_magic"),
        [3] = menu2:findChild("Spa_weapon"),
        [1] = menu2:findChild("Spa_weaponRing"),
        [4] = menu2:findChild("Spa_magicRing")}]]
    local fill = menu2:findChild(tes3ui.registerID("MenuMulti_map_notify"))
    local fill2 = menu2:findChild("MenuMap_panel")
    if tes3.isLuaModActive("inom - User interface hider") then
        menu.visible = fill.visible or fill2.visible
    end
    --[[for _, v in ipairs(visibilityTable) do
        v.visible = not tes3ui.menuMode()
    end]]
    --local block3 = menu2:findChild("Spa_weapon")
    --block3.absolutePosAlignX = cf.slider/1000
    --block3.absolutePosAlignY = cf.sliderpercent/1000

    local weacharge = menu2:findChild("Spa_weacharge")
    local nullMem = menu2:findChild("NullC:MemoryUsage")
    if not nullMem then return end
    if nullMem.visible then nullMem.visible = false end
    weacharge.widget.fillColor = nullMem.widget.fillColor
    weacharge.widget.max = nullMem.widget.max
    weacharge.widget.current = nullMem.widget.current
    weacharge:register(tes3.uiEvent.help, onMemoryUsageHelp)
end


function mod.simulate()
    local bigMap = tes3ui.findMenu("MenuMap")
    local menu2 = tes3ui.findMenu("MenuMulti")
    if not menu2 then return end
    local lock = menu2:findChild("Spa_lock")
    if bigMap then
        lock.visible = not bigMap:getPropertyBool("menu_is_docked")
    else
        lock.visible = true
    end
    --local fill = menu2:findChild(tes3ui.registerID("MenuMulti_map_notify"))
    --menu.visible = fill.visible
    local health = menu2:findChild("Spa_health")
    local magicka = menu2:findChild("Spa_magicka")
    local fatigue = menu2:findChild("Spa_fatigue")
    health.widget.current = tes3.mobilePlayer.health.current
    health.widget.max = tes3.mobilePlayer.health.base
    magicka.widget.current = tes3.mobilePlayer.magicka.current
    magicka.widget.max = tes3.mobilePlayer.magicka.base
    fatigue.widget.current = tes3.mobilePlayer.fatigue.current
    fatigue.widget.max = tes3.mobilePlayer.fatigue.base
    local block2 = menu2:findChild("Spa_magic")
    if not tes3.isLuaModActive("Essential Indicators") then
    local vanillasneak = menu2:findChild("MenuMulti_sneak_icon")
    local mySneak = menu2:findChild("Spa_sneak")
    local mainVanillaSneak = menu2:findChild("MenuMulti_fillbars")
    mainVanillaSneak.visible = vanillasneak.visible and tes3.mobilePlayer.is3rdPerson
    mySneak.visible = vanillasneak.visible and not tes3.mobilePlayer.is3rdPerson end
    local swim = tes3ui.findHelpLayerMenu("MenuSwimFillBar")
    local breath = menu2:findChild("Spa_breathFill")
    local mySwim = menu2:findChild("Spa_lung")
    local enchance = menu2:findChild("Spa_enchance")
    local weacon = menu2:findChild("Spa_weacon")
    local block3 = menu2:findChild("Spa_weapon")
    local ring1 = menu2:findChild("Spa_weaponRing")
    local ring2 = menu2:findChild("Spa_magicRing")
    if swim then
        swim.visible = false
        mySwim.visible = true
        --breath.visible = true
        if not breathtimer then
            breathtimer = timer.start({duration = 1, iterations = 20, type = timer.simulate, callback = function()
                breath.widget.current = left
                left = left-1
            end})
        end
    else
        mySwim.visible = false
        --breath.visible = false
        if breathtimer then
            breathtimer:cancel()
            left = 19
            breath.widget.current = 20
            breathtimer = nil
        end
    end
    timer.delayOneFrame(function()
    local weapon = tes3.mobilePlayer.readiedWeapon
    if weapon and weapon.object and weapon.object.enchantment then
        block3:destroyChildren()
        ring1.visible = true
        block3.alpha = 1
        local icon = weapon.object.icon
        local texture = block3:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
        texture.scaleMode = true
        texture.width = 31
        texture.height = 31
        texture.absolutePosAlignX = 0.894
        texture.absolutePosAlignY = 0.188
        local shadowIcon = texture:createImage({path = "Icons\\" ..icon})
        shadowIcon.color = {0.0, 0.0, 0.0}
        shadowIcon.absolutePosAlignX = 0.6
        shadowIcon.absolutePosAlignY = 0.7
        shadowIcon.scaleMode = true
        shadowIcon.width = 29
        shadowIcon.height = 29
        local Icon = texture:createImage({path = "Icons\\"..icon})
        Icon.absolutePosAlignX = 0.5
        Icon.absolutePosAlignY = 0.5
        Icon.scaleMode = true
        Icon.width = 29
        Icon.height = 29
        weacon.widget.current = weapon.itemData.condition
        weacon.widget.max = weapon.object.maxCondition
        if weapon.itemData then
        --weacharge.widget.current = weapon.itemData.charge
        --weacharge.widget.max = weapon.object.enchantment.maxCharge
        else
        --weacharge.widget.current = 0
        end
    elseif weapon and weapon.object then
        block3:destroyChildren()
        ring1.visible = true
        block3.alpha = 1
        local icon = weapon.object.icon
        local texture = block3:createImage({path = "Icons\\"..icon})
        texture.scaleMode = true
        texture.width = 29
        texture.height = 29
        --weacharge.widget.current = 0
        if weapon.itemData then
            weacon.widget.current = weapon.itemData.condition
            weacon.widget.max = weapon.object.maxCondition
        else
            weacon.widget.current = 0
        end
    elseif block3.children then
        block3:destroyChildren()
        ring1.visible = false
        block3.alpha = 0
        weacon.widget.current = 0
        --weacharge.widget.current = 0
    end
    local magicItem = tes3.mobilePlayer.currentEnchantedItem
    local magicSpell = tes3.mobilePlayer.currentSpell
    if magicItem and magicItem.object then
        local icon = magicItem.object.icon
        block2:destroyChildren()
        block2.alpha = 1
        ring2.visible = true
        local texture = block2:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
        texture.scaleMode = true
        texture.width = 29
        texture.height = 29
        local shadowIcon = texture:createImage({path = "Icons\\" ..icon})
        shadowIcon.color = {0.0, 0.0, 0.0}
        shadowIcon.absolutePosAlignX = 0.6
        shadowIcon.absolutePosAlignY = 0.7
        shadowIcon.scaleMode = true
        shadowIcon.width = 29
        shadowIcon.height = 29
        local Icon = texture:createImage({path = "Icons\\"..icon})
        Icon.absolutePosAlignX = 0.5
        Icon.absolutePosAlignY = 0.5
        Icon.scaleMode = true
        Icon.width = 29
        Icon.height = 29
        if magicItem.itemData then
            enchance.widget.current = magicItem.itemData.charge
            enchance.widget.max = magicItem.object.enchantment.maxCharge
        else
            enchance.widget.current = 0
        end
    elseif magicSpell then
        local icon = magicSpell.effects[1].object.bigIcon
        block2:destroyChildren()
        block2.alpha = 1
        ring2.visible = true
        local Icon = block2:createImage({path = "Icons\\"..icon})
        Icon.scaleMode = true
        Icon.width = 29
        Icon.height = 29
        enchance.widget.current = magicSpell:calculateCastChance({checkMagicka = true, caster = tes3.player})
        enchance.widget.max = 100
    elseif block2.children then
        enchance.widget.current = 0
        block2:destroyChildren()
        block2.alpha = 0
        ring2.visible = false
    end end)
end


mod.registerModConfig = function()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory(" ")
    category0:createOnOffButton{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

    category0:createKeyBinder{label = " ", description = " ", allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = true, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}}}

    local category1 = page:createCategory(" ")
    local elementGroup = category1:createCategory("")

    elementGroup:createDropdown { description = " ",
        options  = {
            { label = " ", value = 0 },
            { label = " ", value = 1 },
            { label = " ", value = 2 },
            { label = " ", value = 3 },
            { label = " ", value = 4 },
            { label = " ", value = -1}
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown",
            table = cf
        }
    }

    elementGroup:createTextField{
        label = " ",
        variable = mwse.mcm.createTableVariable{
            id = "textfield",
            table = cf,
            numbersOnly = false,
        }
    }

    local category2 = page:createCategory(" ")
    local subcat = category2:createCategory(" ")

    subcat:createSlider{label = " ", description = " ", min = 0, max = 1000, step = 1, jump = 50, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}

    subcat:createSlider{label = " ".."%s%%", description = " ", min = 0, max = 1000, step = 1, jump = 50, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}


    template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "npcs", table = cf}, filters = {{label = "NPCs", type = "Object", objectType = tes3.objectType.npc}}}

    local page2 = template:createSideBarPage({label = "Extermination list"})
    page2:createButton{
        buttonText = "Switch",
        callback = function()
            cf.switch = not cf.switch
            local pageBlock = template.elements.pageBlock
            pageBlock:destroyChildren()
            page2:create(pageBlock)
            template.currentPage = page2
            pageBlock:getTopLevelParent():updateLayout()
        end,
        inGameOnly = false}
    local category = page2:createCategory("")
    category:createInfo{
        text = "",
        inGameOnly = false,
        postCreate = function(self)
        if cf.switch then
            self.elements.info.text = "Creatures gone extinct:"
            self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
        else
            self.elements.info.text = "Creatures you've killed:"
            self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
        end
    end}
    category:createInfo{
        text = "Load a saved game to see this.",
        inGameOnly = true,
        postCreate = function(self)
        if cf.switch then
            if tes3.player then
                local list = ""
                for actor,value in pairs(tes3.getKillCounts()) do
                    if (actor.objectType == tes3.objectType.creature) and (value >= tonumber(cf.slider)) then
                        list = actor.name.."s (RIP)".."\n" .. list
                    end
                end
                if list == "" then
                    list = "None."
                end
                self.elements.info.text = list
            end
        else
            if tes3.player then
                local list = ""
                for actor,value in pairs(tes3.getKillCounts()) do
                    if (actor.objectType == tes3.objectType.creature) and actor.cloneCount > 1 then
                        list = actor.name.."s: "..value.."\n" .. list
                    end
                end
                if list == "" then
                    list = "None."
                end
                self.elements.info.text = list
            end
        end
    end}
end

return mod
