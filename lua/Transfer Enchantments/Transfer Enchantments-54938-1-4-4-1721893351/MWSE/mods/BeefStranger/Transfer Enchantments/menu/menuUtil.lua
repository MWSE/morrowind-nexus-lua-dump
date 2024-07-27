local bs = require("BeefStranger.Transfer Enchantments.common")
local cfg = require("BeefStranger.Transfer Enchantments.config")
local ui = require("BeefStranger.Transfer Enchantments.ui")

---Every Element in Either Transfer/ItemSelect Menus
local menu = {
    Transfer = { --TopLevel Enchant Transfer Menu
        Main = nil, ---@type tes3uiElement
        text = nil, ---@type tes3uiElement
        text_Border = nil, ---@type tes3uiElement
        text_Border_Input = nil, ---@type tes3uiElement

        text_Label_Cost = nil, ---@type tes3uiElement

        text_Info = nil, ---@type tes3uiElement
        text_Info_Soul = nil, ---@type tes3uiElement
        text_Info_Slash = nil, ---@type tes3uiElement
        text_Info_Cost = nil, ---@type tes3uiElement

        select = nil, ---@type tes3uiElement
        select_Enchant = nil, ---@type tes3uiElement
        select_Enchant_Item = nil, ---@type tes3uiElement
        select_Target = nil, ---@type tes3uiElement
        select_Target_Item = nil, ---@type tes3uiElement
        select_Options = nil, ---@type tes3uiElement
        select_SoulGem = nil, ---@type tes3uiElement
        select_SoulGem_Item = nil, ---@type tes3uiElement

        buttons = nil, ---@type tes3uiElement
        buttons_Close = nil, ---@type tes3uiElement
        buttons_Confirm = nil, ---@type tes3uiElement
    },

    ItemSelect = { --ItemSelect Menu
        Main = nil, ---@type tes3uiElement
        scrollPane = nil, ---@type tes3uiElement
        scrollPane_Block = nil, ---@type tes3uiElement
        scrollPane_Block_Icon = nil, ---@type tes3uiElement
        scrollPane_Block_Name = nil, ---@type tes3uiElement
        close = nil, ---@type tes3uiElement
    },

    cycleWidget = nil, ---@type tes3uiCycleButton
    combine = false, ---The Value of cycleWidget

}

---The Item Selected as the Target
---@return tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon|tes3leveledItem 
function menu:targetItem()
    return self.Transfer.select_Target_Item:getLuaData("item")
end
---The Enchant Selected
---@return tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon|tes3leveledItem 
function menu:enchantItem()
    return self.Transfer.select_Enchant_Item:getLuaData("item")
end
---The value of the Soul of the Selected Gem
---@return number
function menu:soul()
    return self.Transfer.select_SoulGem_Item:getLuaData("soul") or 0
end
---The SoulGem Object Selected
---@return tes3misc
function menu:soulGem()
    return self.Transfer.select_SoulGem_Item:getLuaData("item")
end

function menu:enchantOnStrike()
    if self:enchantItem() and self:enchantItem().enchantment then
        return self:enchantItem().enchantment.castType == tes3.enchantmentType.onStrike
    end
end

function menu:targetOnStrike()
    if self:targetItem() and self:targetItem().enchantment then
        return self:targetItem().enchantment.castType == tes3.enchantmentType.onStrike
    end
end

---@return number Cost The Displayed cost of the Enchantment
function menu:enchantCost()
    return tonumber(self.Transfer.text_Info_Cost.text)
end

function menu.addItem(object)
    tes3.addItem({ reference = tes3.player, item = object })
end

---removeItem from player
function menu.removeItem(object)
    tes3.removeItem({ reference = tes3.player, item = object, count = 1 })
end

---Sets Name of item to either the target items name or the player input name
---@param target tes3armor|tes3clothing|tes3weapon The Item to retrieve the name from
---@return string name Sets Target Items name to its original name unless Player inputs Name in rename bar
function menu.nameHandler(target)
    local name
    if menu.Transfer.text_Border_Input.text == "Rename Item" then
        name = target.name
    else
        name = menu.Transfer.text_Border_Input.text
    end
    return name
end

function menu.getIcon(object)
    return "icons\\" .. object.icon
end

function menu.calcCost(object, combine)
    local chargeCost = object.enchantment.chargeCost       --The Charge Cost of the Enchantment
    local type = object.enchantment.castType               --The Cast Type
    local constant = type == tes3.enchantmentType.constant --If type is Constant
    local cost = (constant and 400) or (chargeCost)        --Charge Cost or 300 if Constant

    if combine then
        local combineCost = math.min(cost * cfg.combineMult, 400)
        return combineCost
    else
        return tostring(cost)
    end
end

function menu:resetSelection()
    local itemElements = {
        self.Transfer.select_Enchant_Item,
        self.Transfer.select_Target_Item,
        self.Transfer.select_SoulGem_Item
    }

    for _, element in pairs(itemElements) do
        element:setLuaData("item", nil)
        element.contentPath = nil
        element.visible = false
    end
    self.Transfer.text_Info_Cost.text = "0"
    self.Transfer.text_Info_Soul.text = "0"
    self.Transfer.Main:updateLayout()
end

---Removes Selected SoulGem taking into account Azura's Star
function menu.removeGem()
    local gem = menu:soulGem()
    if gem and gem.id == "Misc_SoulGem_Azura" then
        --debug.log("Azuras Star Detected")
        for _, stack in pairs(tes3.player.object.inventory) do
            if stack.object.id == gem.id and stack.variables then
                for _, data in pairs(stack.variables) do
                    data.soul.soul = nil
                end
            end
        end
    else
        menu.removeItem(gem)
    end
end

---@return tes3armor|tes3clothing|tes3weapon|
function menu.data(element)
    return element:getLuaData("item")
end

---Calculates the maxCharge
---@param enchant tes3armor|tes3weapon|tes3clothing The original Enchant
---@param target tes3armor|tes3weapon|tes3clothing Can be an unenchanted item (0)
---@return number maxCharge (enchantCharge * 0.85) + (targetCharge * 0.85) + ((soul / 2) - cost)
function menu.calcMaxCharge(enchant, target)
    local enchantMax = enchant.enchantment.maxCharge
    local targetMax = target.enchantment and target.enchantment.maxCharge or 0
    local maxCharge = ((enchantMax * 0.85) + (targetMax * 0.85) + ((menu:soul() / 2) - menu:enchantCost()))
    return maxCharge
end

---Transfer/Combine Enchantments
function menu.transferConfirm()
    local target = menu:targetItem() ---@type tes3armor|tes3weapon|tes3clothing
    local enchant = menu:enchantItem()--@type tes3armor|tes3weapon|tes3clothing
    local combine = menu.cycleWidget and menu.cycleWidget.value

    if enchant and target then
        if combine then
            local cost = tonumber(menu.Transfer.text_Info_Cost.text)
            --debug.log(cost)
            if cost <= menu:soul() then
                --debug.log(menu:soul())
                local sourceEnchant = enchant.enchantment:createCopy({}) --The Source Item Enchant
                local targetEnchant = target.enchantment:createCopy({}) --The Target Item Enchant
                local newTarget = target:createCopy({})              --The Target Item

                local enchantEffects = {}                            --The Source Items Effects
                local targetEffects = {}                             --The Target Items Effects
                local combinedEffects = {}                           --All Effects Combined
                local newCost = 0

                ---Either Combine or Skip Duplicate Effects ```cfg.combineMax```
                local function combineOrSkipEffect(combinedEffects, newEffect)
                    for _, effect in ipairs(combinedEffects) do
                        ---@cast effect tes3effect
                        if effect.id == newEffect.id then
                            if cfg.combineMags then
                                effect.min = math.min(effect.min + newEffect.min, 100)
                                effect.max = math.min(effect.max + newEffect.max, 100)
                                newCost = enchant.enchantment.chargeCost + target.enchantment.chargeCost + newCost

                                return true
                            else
                                effect.min = math.max(effect.min, newEffect.min)
                                effect.max = math.max(effect.max, newEffect.max)

                                newCost = enchant.enchantment.chargeCost + target.enchantment.chargeCost + newCost
                                return true
                            end
                            newCost = effect.cost + newEffect.cost + newCost
                            return true -- Effect combined, skip adding as new
                        end
                        newCost = enchant.enchantment.chargeCost + target.enchantment.chargeCost + newCost
                    end
                    return false -- No duplicate found, add as new
                end
                local function populateCombination(tbl)
                    for _, effect in ipairs(tbl) do
                        ---@cast effect tes3effect
                        if not combineOrSkipEffect(combinedEffects, effect) then
                            table.insert(combinedEffects, effect)
                        end
                    end
                end

                for i = 1, sourceEnchant:getActiveEffectCount() do
                    table.insert(enchantEffects, sourceEnchant.effects[i])
                end

                for i = 1, targetEnchant:getActiveEffectCount() do
                    table.insert(targetEffects, targetEnchant.effects[i])
                end

                populateCombination(enchantEffects)
                populateCombination(targetEffects)

                if #combinedEffects > 8 then --Remove excess effects if its even posible
                    while #combinedEffects > 8 do
                        table.remove(combinedEffects)
                    end
                end

                if cfg.keepOg then        --Give back a copy of the original item if enabled
                    local oldItem = enchant:createCopy({})
                    oldItem.enchantment = nil --Clear Enchantment
                    menu.addItem(oldItem)
                end

                newTarget.name = menu.nameHandler(newTarget)

                local newEnchant = targetEnchant:createCopy({}) --Dont remember why i needed this
                for i = 1, #combinedEffects do
                    newEnchant.effects[i] = combinedEffects[i]
                end

                newEnchant.chargeCost = newCost --Set charge to newCost, has to be done here or its unreliable
                newTarget.enchantment = newEnchant --Add newEnchant to the newTarget
                newTarget.enchantment.maxCharge = math.max(newCost, menu.calcMaxCharge(enchant, target))
                
                menu.addItem(newTarget)

                menu.removeItem(target)
                menu.removeItem(enchant)
                menu.removeGem()

                if cfg.giveXP then
                    tes3.mobilePlayer:exerciseSkill(tes3.skill.enchant, 5)
                end

                if cfg.autoExit then
                    menu.Transfer.Main:exit()
                else
                    menu:resetSelection()
                end
                --===================================
            else
                ui.msg("Soul not powerful enough")
                bs.playSound(bs.sound.enchant_fail)
            end

        else
            if tonumber(menu.calcCost(enchant)) <= menu:soul() then
                local newTarget = target:createCopy({})

                newTarget.enchantment = enchant.enchantment --Add Original Enchant to the newTarget Item
                newTarget.name = menu.nameHandler(newTarget)
                newTarget.enchantment.maxCharge = menu.calcMaxCharge(enchant, newTarget)

                if cfg.keepOg then --Give back a copy of the original item if enabled
                    local oldItem = enchant:createCopy({})
                    oldItem.enchantment = nil --Clear Enchantment
                    menu.addItem(oldItem)
                end

                menu.addItem(newTarget)
                menu.removeItem(enchant)
                menu.removeItem(target)
                menu.removeGem()

                if cfg.giveXP then tes3.mobilePlayer:exerciseSkill(tes3.skill.enchant, 5) end

                if cfg.autoExit then
                    menu.Transfer.Main:exit()
                else
                    menu:resetSelection()
                end

                bs.playSound(bs.sound.enchant_success)
            else
                ui.msg("Soul not powerful enough")
                bs.playSound(bs.sound.enchant_fail)
            end
        end
    end
end

--Called on item select in ItemSelection
---@param element tes3uiElement
---@param object any
function menu.selectionUpdate(element, object)
    element.visible = true                         --Make it visible
    element.contentPath = menu.getIcon(object)     --Set icon to items icon
    element:setLuaData("item", object)             --Add item to elements luaData
    element:itemTooltip(object)                    --Create Tooltip for item
    element:topUpdate()                            --Update Menu
    menu.ItemSelect.Main:exit()                    --Exit menu and menuMode
    bs.playSound(bs.sound.Item_Misc_Up)            --Play select sound
end

return menu