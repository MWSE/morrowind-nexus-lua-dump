local i18n = mwse.loadTranslations("Pirate.HUDEquippedLight")
local config = require("Pirate.HUDEquippedLight.config")
require("Pirate.HUDEquippedLight.mcm")
local seph = include("seph.hudCustomizer.interop")
local hudLightId = tes3ui.registerID("HUDEquippedLight")
local hudItemSlotId = tes3ui.registerID("EquippedItemSlot")
local menuLight

local function getEquippedShield()
    return tes3.getEquippedItem({ 
        actor = tes3.player, 
        objectType = tes3.objectType.armor, 
        slot = tes3.armorSlot.shield 
    })
end

local function getEquippedLight()
    return tes3.getEquippedItem({ 
        actor = tes3.player, 
        objectType = tes3.objectType.light 
    })
end

local function updateLight()
    if not menuLight then return end

    menuLight:destroyChildren()

    if not config.mcm.SlotLightVisible then
        return
    else
        menuLight.visible = config.mcm.SlotLightVisible
    end

    local equippedLight = config.mcm.EquippedLightVisible and getEquippedLight() or nil
    local equippedShield = config.mcm.EquippedShieldVisible and getEquippedShield() or nil
    local equippedItem = equippedLight or equippedShield

    if not equippedItem and not config.mcm.EmptySlotVisible then
        menuLight.visible = false
        return
    end

    if not (seph and config.mcm.sephIntegration) then
        menuLight.absolutePosAlignX = config.mcm.SlotPositionX / 100
        menuLight.absolutePosAlignY = config.mcm.SlotPositionY / 100
    end

    local barWidth = config.mcm.SlotIconSize + config.BorderSize * 2
    local barHeight = math.ceil(config.mcm.SlotIconSize * 3 / 16)

    local borde = menuLight:createBlock({ id = hudItemSlotId })
    borde.flowDirection = "top_to_bottom"
    borde.autoWidth = true
    borde.autoHeight = true
    borde.paddingAllSides = 0
    borde.borderAllSides = 0

    local border = borde:createThinBorder()
    border.autoWidth = true
    border.autoHeight = true
    border.paddingAllSides = config.BorderSize

    local darkness = border:createRect({ color = {0.0, 0.0, 0.0} })
    darkness.width = config.mcm.SlotIconSize
    darkness.height = config.mcm.SlotIconSize
    darkness.alpha = 0.8

    if equippedItem then
        local icon = darkness:createImage({ path = "Icons\\" .. equippedItem.object.icon })
        icon.scaleMode = true
        icon.width = config.mcm.SlotIconSize
        icon.height = config.mcm.SlotIconSize
    end

    local barsCount = 0

    -- Шкала времени для светильника
    if equippedLight then
        local light = equippedLight.object
        local itemData = equippedLight.itemData
        local bar = borde:createFillBar()
        bar.width = barWidth
        bar.height = barHeight
        bar.widget.showText = false
        bar.widget.fillColor = {255 / 255, 140 / 255, 20 / 255}
        bar.widget.max = light.time
        bar.widget.current = itemData and itemData.timeLeft or light.time
        barsCount = barsCount + 1
    end

    -- Шкалы для щита
    if equippedShield then
        local shield = equippedShield.object
        local itemData = equippedShield.itemData
        -- Шкала прочности
        if itemData and shield.maxCondition and shield.maxCondition > 0 then
            local conditionBar = borde:createFillBar()
            conditionBar.widget.showText = false
            conditionBar.width = barWidth
            conditionBar.height = barHeight
            conditionBar.widget.max = shield.maxCondition
            conditionBar.widget.current = itemData.condition
            barsCount = barsCount + 1
        end
        -- Шкала заряда
        if itemData and shield.enchantment and shield.enchantment.maxCharge > 0 then
            local castType = shield.enchantment.castType
            if castType == tes3.enchantmentType.onStrike or castType == tes3.enchantmentType.onUse then
                local chargeBar = borde:createFillBar()
                chargeBar.widget.fillColor = tes3ui.getPalette("magic_color")
                chargeBar.widget.showText = false
                chargeBar.width = barWidth
                chargeBar.height = barHeight
                chargeBar.widget.max = shield.enchantment.maxCharge
                chargeBar.widget.current = itemData.charge
                barsCount = barsCount + 1
            end
        end
    end

    -- Пустая шкала для пустого слота
    if not equippedLight and not equippedShield then
        local bar = borde:createFillBar()
        bar.width = barWidth
        bar.height = barHeight
        bar.widget.showText = false
        bar.widget.fillColor = {255 / 255, 140 / 255, 20 / 255}
        bar.widget.max = 100
        bar.widget.current = 0
        barsCount = barsCount + 1
    end

    -- Невидимый блок для выравнивания высоты
    if barsCount == 1 then
        local spacer = borde:createRect({ color = {0, 0, 0, 0} })
        spacer.alpha = 0
        spacer.width = barWidth
        spacer.height = barHeight
    end

    menuLight:updateLayout()
end

local function createHUDEquippedLight(e)
    if not e.newlyCreated then return end

    menuLight = e.element:createRect({ id = hudLightId })
    menuLight.color = {0.0, 0.0, 0.0}
    menuLight.alpha = 0
    menuLight.autoWidth = true
    menuLight.autoHeight = true
    menuLight.flowDirection = "top_to_bottom"
    menuLight.visible = config.mcm.SlotLightVisible

    updateLight()
end
event.register(tes3.event.uiActivated, createHUDEquippedLight, { filter = "MenuMulti" })

local function updateOnEquipped()
updateLight()
end
event.register("equipped", updateOnEquipped)

local function updateOnUnequipped()
updateLight()
end
event.register("unequipped", updateOnUnequipped)

local function updateRealTime()
    if tes3.menuMode() and not tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu")) then return end
    updateLight()
end

local function startTimer()
    timer.start({
        duration = 1.0,
        type = timer.real,
        callback = updateRealTime,
        iterations = -1
    })
end
event.register("loaded", startTimer)

local function tooltips()
    if not menuLight then return end

    local block = menuLight:findChild({ id = hudItemSlotId })
    if not block then return end

    local equippedLight = config.mcm.EquippedLightVisible and getEquippedLight() or nil
    local equippedShield = config.mcm.EquippedShieldVisible and getEquippedShield() or nil
    local equippedItem = equippedLight or equippedShield

    block:register(tes3.uiEvent.help, function()
        if equippedItem then
            tes3ui.createTooltipMenu({ item = equippedItem.object, itemData = equippedItem.itemData})
        end
    end)
end
event.register("mouseAxis", tooltips)

local function initialized()
    if seph and config.mcm.sephIntegration then
        seph:registerElement(
        "HUDEquippedLight",
        i18n("mcm.modname"),
        {
        positionX = 0.13,
        positionY = 1.0,
        visible = true
        },
        {
        position = true,
        })
    end

    mwse.log("["..i18n("mcm.modname").."] Version: "..config.modVersion.." Initialized!")
end
event.register("initialized", initialized)