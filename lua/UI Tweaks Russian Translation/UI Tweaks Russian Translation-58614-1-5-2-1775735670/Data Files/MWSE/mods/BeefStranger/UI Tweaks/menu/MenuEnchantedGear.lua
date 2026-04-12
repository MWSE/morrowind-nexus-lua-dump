local cfg = require("BeefStranger.UI Tweaks.config")
local Magic = require("BeefStranger.UI Tweaks.menu.MenuMagic")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")

---@class bsMenuEnchantedFunctions
local this = {}

---@class bsMenuEnchanted
local Enchant = {}
Enchant.prop = {
    obj = "EnchantedGear_Object",
    data = "EnchantedGear_itemData",
    hidden = "EnchantedGear_Hidden"
}

Enchant.UID = {
    Top = tes3ui.registerID("BS_MenuEnchanted"),
    Header = tes3ui.registerID("Header"),
    GearHeader = tes3ui.registerID("Gear Header"),
    GearCost = tes3ui.registerID("Gear Cost"),
    MainBlock = tes3ui.registerID("Main Block"),
    Enchantments = tes3ui.registerID("Enchantments"),
    GearIcons = tes3ui.registerID("Gear Icons"),
    IconPre = "Icon ",
    GearNames = tes3ui.registerID("Gear Names"),
    CostBlock = tes3ui.registerID("CostBlock"),
    ChargeBlock = tes3ui.registerID("ChargeBlock"),
    Cost = tes3ui.registerID("Cost"),
    Charge = tes3ui.registerID("Charge"),
    GearBlock = tes3ui.registerID("Gear Block"),
    ScrollHeader = tes3ui.registerID("Scrolls Header"),
    ScrollsBlock = tes3ui.registerID("Scrolls"),
    ScrollIcons = tes3ui.registerID("Scroll Icons"),
    ScrollLabel = tes3ui.registerID("Scrolls Label"),
    ScrollNames = tes3ui.registerID("Scroll Names"),
    Divider = tes3ui.registerID("Divider"),
    HideButton = tes3ui.registerID("Show Gear Menu")
}

local TEXT = {}
TEXT.GEAR = "Зачарованное снаряжение"
TEXT.COST_CHARGE = "Цена/Заряд"
TEXT.SCROLL = "Свитки"
TEXT.HIDE = " . . . "
TEXT.MAXIMIZE = "Открыть окно зачарованного снаряжения"
TEXT.MINIMIZE = "Закрыть окно зачарованного снаряжения"

function Enchant:get() return tes3ui.findMenu(self.UID.Top) end
function Enchant:child(child) return self:get() and self:get():findChild(child) end
function Enchant:ChargeBlock() return self:child(self.UID.ChargeBlock) end
function Enchant:CostBlock() return self:child(self.UID.CostBlock) end
function Enchant:Enchantments() return self:child(self.UID.Enchantments) end
function Enchant:GearIcons() return self:child(self.UID.GearIcons) end
function Enchant:GearNames() return self:child(self.UID.GearNames) end
function Enchant:GearBlock() return self:child(self.UID.GearBlock) end
function Enchant:GearHeader() return self:child(self.UID.GearHeader) end
function Enchant:ScrollIcons() return self:child(self.UID.ScrollIcons) end
function Enchant:ScrollNames() return self:child(self.UID.ScrollNames) end
function Enchant:ScrollLabel() return self:child(self.UID.ScrollLabel) end
function Enchant:ScrollBlock() return self:child(self.UID.ScrollsBlock) end
function Enchant:HideButton() return Magic:child(self.UID.HideButton) end

local UID = Enchant.UID

local function createMenuEnchanted()
    if not tes3.isCharGenFinished() then return end
    local enchantedGear = tes3ui.createMenu({ id = UID.Top, dragFrame = true, modal = false })
    enchantedGear.height = 275
    enchantedGear.maxWidth = 450
    enchantedGear.minHeight = 90
    enchantedGear.minWidth = 235
    enchantedGear.visible = Magic:get().visible
    enchantedGear.width = 300

    ---Menu not hidden by default
    this.setHidden(false)

    local mainBlock = enchantedGear:createVerticalScrollPane{ id = UID.MainBlock }
    mainBlock.widthProportional = 1
    mainBlock.heightProportional = 1

    local gearheader = mainBlock:createBlock{ id = UID.Header } ---Rename Header/GearHeader Label
    gearheader.widthProportional = 1
    gearheader.childAlignX = -1
    gearheader.autoHeight = true

    local gearTitle = gearheader:createLabel({ id = UID.GearHeader, text = TEXT.GEAR })
    gearTitle.color = bs.rgb.headerColor
    gearTitle:register(tes3.uiEvent.mouseClick, this.hideGear)

    local gearCost = gearheader:createLabel({ id = UID.GearCost, text = TEXT.COST_CHARGE })
    gearCost.color = bs.rgb.headerColor

    local enchants = mainBlock:createBlock({ id = UID.Enchantments })
    enchants.autoHeight = true
    enchants.widthProportional = 1
    enchants.flowDirection = tes3.flowDirection.topToBottom

    local gearBlock = enchants:createBlock({id = UID.GearBlock})
    gearBlock.autoHeight = true
    gearBlock.widthProportional = 1

    local gearIcons = gearBlock:createBlock { id = UID.GearIcons }
    gearIcons.paddingLeft = 2
    gearIcons.paddingRight = 4
    gearIcons.flowDirection = tes3.flowDirection.topToBottom
    gearIcons:bs_autoSize(true)

    local gearNames = gearBlock:createBlock({ id = UID.GearNames })
    gearNames.flowDirection = tes3.flowDirection.topToBottom
    gearNames.autoHeight = true
    gearNames.widthProportional = 1
    gearNames.borderBottom = 5

    local cost = gearBlock:createBlock({ id = UID.CostBlock })
    cost.flowDirection = tes3.flowDirection.topToBottom
    cost.borderLeft = 4
    cost:bs_autoSize(true)
    cost.childAlignX = 1

    local charge = gearBlock:createBlock({ id = UID.ChargeBlock })
    charge.flowDirection = tes3.flowDirection.topToBottom
    charge:bs_autoSize(true)
    charge.borderRight = 4

---=============================================
    enchants:createDivider({id = UID.Divider})
---=============================================

    local scrollHeader = enchants:createBlock({id = UID.ScrollHeader})
    scrollHeader.autoHeight = true
    scrollHeader.widthProportional = 1
    scrollHeader.borderBottom = 5

    local scrollLabel = scrollHeader:createLabel({id = UID.ScrollLabel, text = TEXT.SCROLL})
    scrollLabel.color = bs.rgb.headerColor

    scrollLabel:register(tes3.uiEvent.mouseClick, this.hideScrolls)

    local scrolls = enchants:createBlock({ id = UID.ScrollsBlock })
    scrolls.autoHeight = true
    scrolls.widthProportional = 1

    local scrollIcons = scrolls:createBlock { id = UID.ScrollIcons }
    scrollIcons.paddingLeft = 2
    scrollIcons.paddingRight = 4
    scrollIcons.flowDirection = tes3.flowDirection.topToBottom
    scrollIcons.autoHeight = true
    scrollIcons.autoWidth = true

    local scrollNames = scrolls:createBlock({ id = UID.ScrollNames })
    scrollNames.flowDirection = tes3.flowDirection.topToBottom
    scrollNames.autoHeight = true
    scrollNames.widthProportional = 1

    ---Create Gear Cost/Charge
    ---@param stack tes3itemStack
    ---@param itemData tes3itemData
    local function createCharge(stack, itemData)
        local maxCharge = itemData and itemData.charge or stack.object.enchantment.maxCharge

        local costText = tostring(stack.object.enchantment.chargeCost)
        local chargeText = "/" .. tostring(math.round(maxCharge))

        cost:createLabel { id = stack.object.id, text = costText }
        charge:createLabel { id = stack.object.id, text = chargeText }
    end

    ---Create Items Text Select
    ---@param stack tes3itemStack
    ---@return tes3uiElement item
    local function createItemLabel(stack)
        local effectIcon = stack.object.enchantment.effects[1].object.icon
        local isScroll = stack.object.enchantment.castType == tes3.enchantmentType.castOnce
        local iconType = (isScroll and scrollIcons) or gearIcons
        local nameType = (isScroll and scrollNames) or gearNames

        local icon = iconType:createImage({ id = stack.object.id, path = "Icons\\" .. effectIcon })
        icon.borderTop = 2
        local COUNT = ((isScroll and stack.count > 1) and (": (%s)"):format(stack.count)) or ""
        local item = nameType:createTextSelect({ id = stack.object.id, text = ("%s %s"):format(stack.object.name, COUNT) })

        if isScroll then
            item.widget.idle = bs.rgb.disabledColor
        end

        return item
    end

    local function createEnchantList()
        local top = Enchant:get()
        this.clearLabels()
        top.text = TEXT.GEAR

        for _, stack in pairs(tes3.mobilePlayer.inventory) do
            local enchant = stack.object.enchantment
            local onUse = enchant and enchant.castType == tes3.enchantmentType.onUse
            local isScroll = enchant and enchant.castType == tes3.enchantmentType.castOnce
            local castable = isScroll or onUse
            if castable then
                local itemData = stack.variables and stack.variables[1]
                local item = createItemLabel(stack)

                this.setObj(item, stack)
                this.setData(item, itemData)
                this.highlightNew(stack, item)

                ---Update Text State to be Active if Enchant Equipped
                if tes3.mobilePlayer.currentEnchantedItem.object == stack.object then
                    item.widget.state = tes3.uiState.active
                    top.text = stack.object.name
                end

                if not isScroll then
                    createCharge(stack, itemData)
                end

                item:register(tes3.uiEvent.mouseClick, function(e) this.onItemClick(e, stack) end)
                item:register(tes3.uiEvent.help, function(e) tes3ui.createTooltipMenu({ item = stack.object, itemData = itemData }) end)
            end
        end
    end

    createEnchantList()

    ---@param e tes3uiEventData
    local function preUpdate(e)
        createEnchantList()
        e.source:bs_savePos()
        -- bs.savePos(e.source)
    end

    enchantedGear:register(tes3.uiEvent.preUpdate, preUpdate)
    Magic:get():registerAfter(tes3.uiEvent.preUpdate, this.MagicPre)

    enchantedGear:bs_loadPos()
    -- bs.loadPos(enchantedGear)
end

---===============================================
---===================Events======================
---===============================================

--- @param e menuEnterEventData
local function menuEnterCallback(e)
    if cfg.enchantedGear.enable and not Enchant:get() then
        createMenuEnchanted()
    end

    if Enchant:HideButton() then
        Enchant:HideButton().visible = cfg.enchantedGear.enable
    end

    if Enchant:get() and Magic:get().visible then
        Enchant:get().visible = not this.getHidden()
        Enchant:get():updateLayout()
    end
end
event.register(tes3.event.menuEnter, menuEnterCallback)

--- @param e menuExitEventData
local function menuExitCallback(e)
    if not cfg.enchantedGear.enable and Enchant:get() then
        Magic:get():unregisterAfter(tes3.uiEvent.preUpdate, this.MagicPre)
        Enchant:get():destroy()
    end
    if Enchant:get() then
        Enchant:get().visible = false
    end
end
event.register(tes3.event.menuExit, menuExitCallback)

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    if not e.newlyCreated then return end
    -- if Magic:child(UID.MinMax) then return end
    local hide = e.element:createButton({id = UID.HideButton, text = TEXT.MINIMIZE })
    hide.visible = cfg.enchantedGear.enable
    hide:register(tes3.uiEvent.mouseClick, this.hideButtonClick)
end
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = id.Magic})

---===============================================
---==============Helper Functions=================
---===============================================

---Clear All Items from Menu
function this.clearLabels()
    Enchant:GearIcons():destroyChildren()
    Enchant:GearNames():destroyChildren()
    Enchant:CostBlock():destroyChildren()
    Enchant:ChargeBlock():destroyChildren()
    Enchant:ScrollNames():destroyChildren()
    Enchant:ScrollIcons():destroyChildren()
end

---@param e uiEventEventData
function this.hideButtonClick(e)
    if not tes3.isCharGenFinished() then return end
    this.setHidden(not this.getHidden())
    Enchant:get().visible = not this.getHidden()
    e.source.text = this.getHidden() and TEXT.MAXIMIZE or TEXT.MINIMIZE
    if cfg.enchantedGear.showVanillaOnHide then
        Magic:Enchants().visible = true
        Magic:EnchantTitle().visible = true
        Magic:Enchants().parent.children[6].visible = true
    end
    e.source:getTopLevelMenu():updateLayout()
    Magic:SpellScrollPane().widget:contentsChanged()
    -- -- e.source:findChild("MagicMenu_spells_list").widget:contentsChanged()
end

---Highlight New Enchants/Scrolls
---@param stack tes3itemStack
---@param item tes3uiElement
function this.highlightNew(stack, item)
    if cfg.enchantedGear.highlightNew then
        local lookedAt = bs.initData().lookedAt
        if not lookedAt[stack.object.id] then
            item.color = bs.color(cfg.magic.highlightColor)
        end
    end
end
---Hide the Enchanted Gear Category
function this.hideGear()
    local gearBlock = Enchant:GearBlock()
    local title = Enchant:GearHeader()
    gearBlock.visible = not gearBlock.visible
    title.text = not gearBlock.visible and TEXT.GEAR .. TEXT.HIDE or TEXT.GEAR
end

---Hide the Scrolls Category
function this.hideScrolls()
    local scrollBlock = Enchant:ScrollBlock()
    local title = Enchant:ScrollLabel()
    scrollBlock.visible = not scrollBlock.visible
    title.text = not scrollBlock.visible and TEXT.SCROLL .. TEXT.HIDE or TEXT.SCROLL
end

---Update Enchanted Gear layout everytime Vanilla Magic Menu Updates
---@param e tes3uiEventData
function this.MagicPre(e)
    local minMax = Magic:child(UID.HideButton)
    local enchant = Magic:Enchants()
    local title = Magic:EnchantTitle()
    local div = enchant.parent.children[6]
    if cfg.enchantedGear.hideVanilla then
        enchant.visible = false
        title.visible = false
        div.visible = false
    end
    if cfg.enchantedGear.showVanillaOnHide and this.getHidden() then
       enchant.visible = true
        title.visible = true
        div.visible = true
    end
    if minMax then minMax.visible = cfg.enchantedGear.enable end
    if Enchant:get() then Enchant:get():updateLayout() end
end

---When an Item/Scroll is Clicked
---@param stack tes3itemStack
function this.onItemClick(e, stack)
    local castable = stack.object.enchantment.castType == tes3.enchantmentType.onUse
    local isScroll = stack.object.enchantment.castType == tes3.enchantmentType.castOnce

    if castable or isScroll then
        tes3.mobilePlayer:equipMagic({ source = stack.object, equipItem = true })
    else
        tes3.mobilePlayer:equip({item = stack.object, itemData = stack.variables})
    end

    Enchant:get().text = stack.object.name
end

---@param hide boolean
function this.setHidden(hide)
    Enchant:get():setPropertyBool(Enchant.prop.hidden, hide)
end

function this.setObj(menu, stack)
    menu:setPropertyObject(Enchant.prop.obj, stack.object)
end

function this.setData(menu, data)
    if data then
        menu:setPropertyObject(Enchant.prop.data, data)
    end
end

---@return boolean
function this.getHidden()
    return Enchant:get():getPropertyBool(Enchant.prop.hidden)
end

---@return tes3weapon|tes3clothing|tes3armor|tes3book
function this.getObj(menu)
    return menu:getPropertyObject(Enchant.prop.obj)
end

---@return tes3itemData
function this.getData(menu)
    return menu:getPropertyObject(Enchant.prop.data, "tes3itemData")
end

return Enchant