local Multi = require("BeefStranger.UI Tweaks.menu.MenuMulti")
local Magic = require("BeefStranger.UI Tweaks.menu.MenuMagic")
local Contents = require("BeefStranger.UI Tweaks.menu.MenuContents")
local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")
local sf = string.format
local find = tes3ui.findMenu

---@class bsHelpMenu
local Help = {}
function Help:get() return tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu")) end
function Help:child(child) if not self:get() then return end return self:get():findChild(child) end
function Help:Main() return self:child("PartHelpMenu_main") end
function Help:Enchant() return self:child("HelpMenu_enchantmentContainer") end
function Help:Effect() return self:child("effect") end

---@class bsUITweaksTooltips
local this = {}

---Add Charge Cost to Tooltip
--- @param e uiObjectTooltipEventData
local function onTooltipCreation(e)
    if not cfg.tooltip.enable then return end
    if cfg.tooltip.charge then this.chargeCost(e) end
    if cfg.tooltip.totalWeight then this.totalWeight(e) end
    if cfg.tooltip.totalValue then this.totalValue(e) end
end
event.register(tes3.event.uiObjectTooltip, onTooltipCreation)

---Add Charge Cost to Tooltip
--- @param e uiObjectTooltipEventData
function this.chargeCost(e)
    local enchant = e.object.enchantment
    if enchant and enchant.castType ~= tes3.enchantmentType.constant then
        local baseCost = enchant.chargeCost
        local actualCost =  baseCost - (baseCost / 100) * (tes3.mobilePlayer.enchant.current - 10)
        local displayCost = math.max(1, math.floor(actualCost))
        local new = e.tooltip:createLabel({id = "ChargeCost", text = "Стоимость заряда: ".. displayCost})
        e.tooltip.children[1]:reorderChildren(Help:Enchant(), new, 1)
    end
end

---NEED TO ACCOUNT FOR NO UIEXP
--- @param e uiObjectTooltipEventData
function this.totalWeight(e)
    if not tes3ui.menuMode() or e.reference then return end
    local count = e.count
    if Contents:visible() and e.count < 1 then
        count = tes3.getItemCount({item = e.object, reference = Contents:Reference()})
    end

    if e.tooltip:findChild("UIEXP_Tooltip_IconWeightBlock") and count > 1 then
        local weight = e.tooltip:findChild("UIEXP_Tooltip_IconWeightBlock").children[2]
        weight.text = string.format("%.2f/%.2f", e.object.weight, e.object.weight * count)
        e.tooltip:getContentElement().minWidth = 155 ---Have to expand, editing weight doesnt seem to jive well with auto sizing
    end
end

function this.totalValue(e)
    if not tes3ui.menuMode() or e.reference then return end
        
    local count = e.count
    if Contents:get() and e.count < 1 then
        count = tes3.getItemCount({item = e.object, reference = Contents:Reference()})
    end
    if e.tooltip:findChild("UIEXP_Tooltip_IconGoldBlock") and count > 1 then
        local value = e.tooltip:findChild("UIEXP_Tooltip_IconGoldBlock").children[2]
        value.text = string.format("%d/%d", e.object.value, e.object.value * count)
        e.tooltip:getContentElement().minWidth = 190 ---Have to expand, editing weight doesnt seem to jive well with auto sizing
    end
end

---@param active tes3activeMagicEffect
function this.labelText(active)
    local name = active.instance.item and active.instance.item.name or active.instance.source.name
    local duration = active.duration
    local magnitude = active.magnitude
    local remainingTime = math.round(duration - active.effectInstance.timeActive, cfg.tooltip.durationDigits)

    return string.format("%s: %s%% | Длительность: %s sec", name, magnitude, remainingTime)
end

function this.hideNullLabels()
    for i, label in ipairs(Help:Main().children) do
        if label.name == "null" then label.visible = false end
    end
end

---@param active tes3activeMagicEffect
---@param effectBlock tes3uiElement
function this.createEffectTooltips(active, effectBlock)
    local source = active.instance.source
    local isAbility = source.castType == tes3.spellType.ability
    local isEnchant = source.objectType == tes3.objectType.enchantment
    local isDisease = source.castType == tes3.spellType.disease or source.castType == tes3.spellType.blight
    local isConstant = (isEnchant and source.castType == tes3.enchantmentType.constant) or false
    local isValid = not isAbility and not isConstant and active.duration > 1 and not isDisease
    local effect = tes3.getMagicEffect(active.effectId)

    if effect and isValid then
        for _, blockChildren in ipairs(effectBlock.children) do
            if #blockChildren.children > 0 then
                for _, effectIcon in ipairs(blockChildren.children) do
                    if string.match(effectIcon.contentPath, effect.icon) then
                        effectIcon:registerAfter(tes3.uiEvent.help, function (e)
                            this.hideNullLabels()
                            local labelMade = Help:child(tostring(source))
                            if labelMade then
                                labelMade.text = this.labelText(active)
                            else
                                Help:get():createLabel({id = tostring(source), text = this.labelText(active)})
                            end
                        end)
                    end
                end
            end
        end
    end
end

---@param e menuEnterEventData
function this.effectTooltip(e)
    local inv = find(id.Inventory)

    if not tes3.isCharGenFinished() or not inv or not inv.visible and not Magic:get() or not Magic:get().visible then return end
    for _, active in pairs(tes3.mobilePlayer.activeMagicEffectList) do
        this.createEffectTooltips(active, Magic:EffectBlock())
        this.createEffectTooltips(active, Multi:MagicIconsBox())
    end
end

---@param e menuEnterEventData
local function menuEnter(e)
    if cfg.tooltip.showDur then this.effectTooltip(e) end
end
event.register(tes3.event.menuEnter, menuEnter)

return Help
