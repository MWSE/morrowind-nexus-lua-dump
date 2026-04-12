local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")
local Inventory = require("BeefStranger.UI Tweaks.menu.MenuInventory")
local Magic = require("BeefStranger.UI Tweaks.menu.MenuMagic")
local Map = require("BeefStranger.UI Tweaks.menu.MenuMap")
local Stat = require("BeefStranger.UI Tweaks.menu.MenuStat")
local startTime = os.clock()


---@class bsMenuEffects_Func
local this = {}

---@class bsMenuEffects
local Menu = {}
Menu.UID = {
    TOP = "MenuEffects",
}
Menu.PROP = {
    SERIAL = "MenuEffects_Serial",
    PIN = "Menu_Pinned"
}

function Menu:get() return tes3ui.findMenu(self.UID.TOP) end
function Menu:child(child) return self:get() and self:get():findChild(child) end
function Menu:DragMain() return self:child("PartDragMenu_main") end
function Menu:TopBorder() return self:child("PartDragMenu_thick_border") end
function Menu:Title() return self:child("PartDragMenu_title_tint") end

function Menu:isPinned() return self:get():getPropertyBool(self.PROP.PIN) end
function Menu:setPinned(set) return self:get():setPropertyBool(self.PROP.PIN, set) end


function this.create()
    local active = tes3ui.createMenu({id = Menu.UID.TOP, dragFrame = true, modal = false})
    -- local active = tes3ui.bs_createDragFixedFrame({id = Menu.UID.TOP})
    active.width = 300
    active.height = 100
    active.minWidth = 200
    active.minHeight = 100
    active.text = "Активные эффекты"
    active.alpha = tes3.worldController.menuAlpha

    local drag_frame = active:findChild("PartDragMenu_drag_frame")
    for index, value in ipairs(drag_frame.children) do
        if value.name == "null" and value.type == tes3.uiElementType.model then
            value:setPropertyProperty("name", "PartDragMenu_inner_border")
        end
    end
    active:findChild("PartDragMenu_thick_border").contentPath = nil
    active:findChild("PartDragMenu_inner_border").contentPath = nil

    active:bs_createPinButton()

    this.createSpellBlock()

    active:registerAfter(tes3.uiEvent.mouseOver, this.mouseOver)
    active:registerAfter(tes3.uiEvent.mouseLeave, this.mouseLeave)
    active:registerAfter(tes3.uiEvent.preUpdate, this.update)
    active:bs_loadPos()

    local isPinned = Menu:isPinned()

    Menu:Title().visible = not isPinned
    active.visible = isPinned
    active.alpha = isPinned and 0 or active.alpha
end

---Need checks for effect
---@param e uiEventEventData
function this.update(e)
    this.createMissing()
    this.activeUpdate(e)
end

---comments
---@param effect tes3activeMagicEffect
function this.validType(effect)
    if effect.instance.source.isActiveCast or effect.instance.sourceType == tes3.magicSourceType.alchemy or effect.instance.sourceType == tes3.magicSourceType.enchantment then
        return true
    else
        return false
    end
end
---Check if an active effect serial is not already tied to a child
function this.createMissing()
    local current = {}
    for _, child in ipairs(Menu:get():getContentElement().children) do
        table.insert(current, child:getPropertyInt(Menu.PROP.SERIAL))
    end

    for _, effect in ipairs(tes3.mobilePlayer.activeMagicEffectList) do
        if this.validType(effect) then
            local isReg = table.find(current, effect.serial)
            -- debug.log(reg)
            if not isReg then
                -- debug.log(isReg)
                this.createSpellBlock()
            end
        end
    end
end

local nameUpdate = os.clock()

---@param e uiEventEventData
function this.activeUpdate(e)
    for _, child in ipairs(e.source:getContentElement().children) do
        local serial = child:getPropertyInt(Menu.PROP.SERIAL)
        local effect = tes3.mobilePlayer:getActiveMagicEffects({ serial = serial })
        -- debug.log(#effect)
        if serial > 0 then
            for i, active in ipairs(effect) do
                local remaining = active.duration - active.effectInstance.timeActive
                for index, effectBlock in ipairs(child.children) do
                    if effectBlock.name == tes3.getMagicEffectName({ effect = active.effectId }) then
                        if os.clock() - nameUpdate >= 1 then
                            nameUpdate = os.clock()
                            local effectName = tes3.getMagicEffectName({ effect = active.effectId, attribute = active.attributeId, skill = active.skillId })
                            effectBlock:findChild("Name").text = ("%s: (%s п.)"):format(effectName, active.magnitude)
                        end
                        effectBlock:findChild("Fillbar").widget.current = math.round(remaining)
                        if math.round(remaining, 2) <= 0.5 then
                            if effectBlock then
                                effectBlock:destroy()
                            end
                        end
                    end
                end
            end
            if #effect < 1 then
                if child then
                    -- debug.log("DESTROY")
                    child:destroy()
                end
            end
        end
    end
end

function this.createSpellBlock()
    local menu = Menu:get()
    for _, spells in ipairs(tes3.mobilePlayer.activeMagicEffectList) do
        local source = spells.instance.source
        if this.validType(spells) then
            if spells.duration >= cfg.effects.durationThreshold then
                local block = menu:findChild(source.id)
                if not block then
                    if cfg.effects.borderMode == 1 then
                        block = menu:createThinBorder { id = source.id }
                    elseif cfg.effects.borderMode == 2 then
                        block = menu:createRect { id = source.id, color = { 0, 0, 0 } }
                    elseif cfg.effects.borderMode == 3 then
                        block = menu:createBlock { id = source.id }
                    end
                    block:bs_autoSize(true)--DEBUG
                    block.alpha = 0.75
                    block.flowDirection = tes3.flowDirection.topToBottom
                    block.widthProportional = 1
                    block.autoHeight = true
                    block:setPropertyInt(Menu.PROP.SERIAL, spells.serial)
                    block.borderBottom = 6
                end

                this:createEffectBlock(spells)
                this:createTitle(spells)
                this:createFillBar(spells)
            end
        end
    end
end

---@param spells tes3activeMagicEffect
function this:createEffectBlock(spells)
    local block = self:getBlock(spells)
    local effectBlock = self:getEffectBlock(spells)
    if not effectBlock then
        effectBlock = block:createBlock { id = tes3.getMagicEffectName({effect = spells.effectId}) }
        effectBlock:bs_autoSize(true) --DEBUG
        effectBlock.alpha = 1
        effectBlock.widthProportional = 1
        effectBlock.autoHeight = true
        effectBlock.flowDirection = tes3.flowDirection.topToBottom
    end
    block:register(tes3.uiEvent.help, function (e)
        tes3ui.createTooltipMenu({spell = spells.instance.source})
    end)
    return effectBlock
end

function this:createTitle(spells)
    local effectName = tes3.getMagicEffectName({ effect = spells.effectId, attribute = spells .attributeId, skill = spells.skillId })
    local nameText = string.format("%s: (%s п.)", effectName, spells.magnitude)
    local effectBlock = self:getEffectBlock(spells)
    local title = effectBlock:findChild("Title")
    if not title then
        title = effectBlock:createBlock { id = "Title" }
        title:bs_autoSize(true)--DEBUG
        title.widthProportional = 1
        title.autoHeight = true
        title.childAlignY = 1
        title.borderBottom = 4
    end

    local icon = title:findChild("Icon")
    if not icon then
        icon = title:createImage({ id = "Icon", path = "Icons\\" .. tes3.getMagicEffect(spells.effectId).icon })
        icon.borderRight = 4
    end

    local name = title:findChild("Name")
    if not name then
        name = title:createLabel({ id = "Name", text = nameText })
    end
    return title
end

function this:createFillBar(spells)
    -- local menu = Active:get()
    local effectBlock = self:getEffectBlock(spells)
    local fillbar = effectBlock:findChild("Fillbar")
    if not fillbar then
        fillbar = effectBlock:createFillBar({ id = "Fillbar", current = spells.duration, max = spells.duration })
        fillbar.widthProportional = 1
    end
    return fillbar
end

function this.mouseOver(e)
    if Menu:isPinned() then
        Menu:Title().visible = true
        e.source.alpha = 0.8
    end
end

function this.mouseLeave(e)
    if Menu:isPinned() then
        Menu:Title().visible = false
        e.source.alpha = cfg.effects.menuModeAlpha
    end
end

function this:getBlock(spells)
    local menu = Menu:get()
    local spell = spells.instance.source
    local block = menu:findChild(spell.id)
    return block
end

function this:getEffectBlock(spells)
    local menu = Menu:get()
    local spell = spells.instance.source
    local block = menu:findChild(spell.id)
    return block:findChild(tes3.getMagicEffectName({ effect = spells.effectId }))
end

local function focusAll()
    if Magic:get() then
        tes3ui.moveMenuToFront(Magic:get())
    end
    if Stat:get() then
        tes3ui.moveMenuToFront(Stat:get())
    end
    if Map:get() then
        tes3ui.moveMenuToFront(Map:get())
    end
    if Inventory:get() then
        tes3ui.moveMenuToFront(Inventory:get())
    end
end

--- @param e menuEnterEventData
local function menuEnter(e)
    if Magic:visible() and cfg.effects.enable and tes3.isCharGenFinished() then
        local ae = Menu:get()
        if ae then
            if ae.visible then
                focusAll()
            end
            if Menu:isPinned() then
                ae.alpha = cfg.effects.menuModeAlpha
            else
                ae.alpha = tes3.worldController.menuAlpha
            end
            ae.visible = true
            ae:updateLayout()
        end
        if not cfg.effects.enable then
            if ae then
                ae:destroy()
            end
        end
    end
end
event.register(tes3.event.menuEnter, menuEnter)

--- @param e menuExitEventData
local function menuExitCallback(e)
    local ae = Menu:get()
    if ae then
        ae:bs_savePos()
        ae.visible = Menu:isPinned()
        ae.alpha = cfg.effects.pinnedAlpha
        if not cfg.effects.enable then
            ae:destroy()
        end
    else
        if cfg.effects.enable then
            this.create()
        end
    end
end
event.register(tes3.event.menuExit, menuExitCallback)

--- @param e simulateEventData
local function simulateCallback(e)
    if not cfg.effects.enable then return end
    if os.clock() - startTime >= cfg.effects.updateRate then
        startTime = os.clock()
        local ae = Menu:get()
        if ae then
            ae:updateLayout()
        end
    end
end
event.register(tes3.event.simulate, simulateCallback)

--- @param e loadedEventData
local function loadedCallback(e)
    if cfg.effects.enable then
        this.create()
    end
end
event.register(tes3.event.loaded, loadedCallback)

event.register("bs_MenuEffects_Update", function (e)
    if cfg.effects.enable then
        Menu:get():destroy()
        this.create()
    end
end)