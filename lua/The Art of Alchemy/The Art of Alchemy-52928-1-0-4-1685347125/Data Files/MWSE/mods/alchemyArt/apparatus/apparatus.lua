local ui = require("alchemyArt.ui")
local potion = require("alchemyArt.potion.potion")
local standardPotion = require("alchemyArt.potion.standard")
local common = require("alchemyArt.common")
local specialEffects = require("alchemyArt.specialEffects")
local ingredients = require("alchemyArt.ingredients.ingredients")
local ingredType = require("alchemyArt.ingredients.ingredType")
local formulas = require("alchemyArt.formulas")

local apparatus = {}

apparatus.contents = {}
apparatus.menuName = "MenuApparatus"
apparatus.minContents = 1
apparatus.maxItems = 6
apparatus.count = 1
apparatus.magnitudeDurationValue = 3
apparatus.rightBlockLeftBorder = 154
apparatus.notEnoughContentsMessage = common.dictionary.retortIngredientNotSelected
apparatus.filterBy = tes3.objectType.alchemy -- or tes3.objectType.ingredient

function apparatus:new (a)
    a = a or {}
    setmetatable(a, self)
    self.__index = self
    return a
end

function apparatus:countUp()
    local menu = tes3ui.findMenu(self.menuName)
    local total = 0
    for slot, item in pairs(self.contents) do
        if item then
            slot = menu:findChild(slot)
            local countLabel = slot:findChild("Ingredient_count")
            local count
            if countLabel then
                count = tonumber(countLabel.text)
            else
                count = 1
            end
            total = total + count
            if tes3.getItemCount{reference = tes3.player, item = item} <= count then
                return
            end
        end
    end

    if self.maxItems and total >= self.maxItems then
        tes3.messageBox(common.dictionary.tooManyItems, self.maxItems)
        return
    end

    for slot, item in pairs(self.contents) do
        if item then
            slot = menu:findChild(slot)
            local countLabel = slot:findChild("Ingredient_count")
            if not countLabel then
                local countLabel = slot:findChild("Item_Image"):createLabel{id = "Ingredient_count", text = "2"}
                countLabel.color = {0.875,0.788,0.624}
                countLabel.absolutePosAlignX = 1
                countLabel.absolutePosAlignY = 1
                self.count = 2
            else
                self.count = tonumber(countLabel.text) + 1
                countLabel.text = tostring(self.count)
            end
        end
    end
    menu:updateLayout()
end


function apparatus:countDown()
    local menu = tes3ui.findMenu(self.menuName)
    for slot, item in pairs(self.contents) do
        if item then
            slot = menu:findChild(slot)
            local countLabel = slot:findChild("Ingredient_count")
            if not countLabel then
                return
                --slot:destroyChildren()
            else
                self.count = tonumber(countLabel.text) - 1
                countLabel.text = tostring(self.count)
                if countLabel.text == "1" then
                    countLabel:destroy()
                end
            end
        end
    end
    menu:updateLayout()
end

function apparatus:onItemSelected()

end

function apparatus:selectItem(e)
    local source = e.source
    self:createSelectionMenu()
    event.clear("alchemyArt_itemSelected")
    event.register("alchemyArt_itemSelected", function(params)
        self:onItemSelected()
        local selectedObject = params.item
        ui.createItemImage(source, selectedObject)
        -- mwse.log(selectedObject.id)
        -- mwse.log(selectedObject.name)
        local menu = tes3ui.findMenu(self.menuName)
        source:register("mouseClick", function (removeParams)
            self:removeSelected(removeParams)
        end)
        event.clear("alchemyArt_itemSelected")
        self.contents[source.name] = selectedObject
        --source:setPropertyObject("MenuAlchemy_object", selectedObject)
        common.selectedEffects[source.name] = {}
        for i, effect in ipairs(selectedObject.effects) do
            local effectId
            local attributeId
            if type(effect) == "number" then
                effectId = effect
                if effectId == -1 then
                    break
                end
                local magicEffect = tes3.getMagicEffect(effectId)
                if magicEffect.targetsAttributes then
                    attributeId = selectedObject.effectAttributeIds[i]
                elseif magicEffect.targetsSkills then
                    attributeId = selectedObject.effectSkillIds[i]
                else
                    attributeId = -1
                end
            else
                effectId = effect.id
                if effectId == -1 then
                    break
                end
                local magicEffect = tes3.getMagicEffect(effectId)
                if magicEffect.targetsAttributes then
                    attributeId = effect.attribute
                elseif magicEffect.targetsSkills then
                    attributeId = effect.skill
                else
                    attributeId = -1
                end
                attributeId = effect.attribute
            end
            common.selectedEffects[source.name][effectId] = common.selectedEffects[source.name][effectId] or {}
            common.selectedEffects[source.name][effectId][attributeId] = true

        end
        menu:updateLayout()
    end)
end

function apparatus:removeSelected(e)
    local item = self.contents[e.source.name]
    self:onItemSelected()
    --e.source:setPropertyObject("MenuAlchemy_object", nil)
    self.contents[e.source.name] = nil
    common.selectedEffects[e.source.name] = {}
    e.source:destroyChildren()
    -- e.source:unregister("mouseClick", function (removeParams)
    --     self:removeSelected(removeParams)
    -- end)
    e.source:register("mouseClick", function (selectParams)
        self:selectItem(selectParams)
    end)
end

function apparatus:removeContentsFromPlayer()
    local contents = {}
    local i = 1
    for slot, item in pairs(self.contents) do
        tes3.removeItem{reference = tes3.player, item = item, count = self.count or 1, playSound=false}
        contents[i] = item.id
        i = i + 1
    end
    return contents
end

function apparatus:countContents()
    local count = 0
    for slot, item in pairs(self.contents) do
        if item then
            count = count + 1
        end
    end
    return count
end

function apparatus:alreadyIn(itemToCheck)
    for slot, item in pairs(self.contents) do
        if item.id == itemToCheck.id then
            return true
        elseif ingredients.isSame(item, itemToCheck) then
            return true
        end
    end
    return false
end

function apparatus:itemPassesFilter(item)
    if self.filterBy == tes3.objectType.alchemy and item.objectType == tes3.objectType.alchemy then
        return self:potionPassesFilter(item)
    elseif self.filterBy == tes3.objectType.ingredient and item.objectType == tes3.objectType.ingredient then
        return self:ingredientPassesFilter(item)
    else
        return false
    end
end

function apparatus:potionPassesFilter(item)
    if self:alreadyIn(item) then
        if tes3.getItemCount{reference = tes3.player, item = item.id } == 1 then
            return false
        end
    end
    if common.filteredEffect then
        for i, effect in ipairs(item.effects) do
            if effect.id == common.filteredEffect.id then
                return true
            end
        end
    else
        return true
    end
    return false
end

function apparatus:ingredientPassesFilter(item)
    if self:alreadyIn(item) then
        return false
    end

    if ingredType.insoluble[item.id] then
        return false
    end

    if common.filteredEffect then
        for i, effect in ipairs(item.effects) do
            if effect == common.filteredEffect.id then
                return true
            end
        end
    else
        return true
    end
    return false
end


function apparatus:pickResultEnd(reference)

end

function apparatus:cleanUp(reference)
    reference.data.alchemyArt.progress = nil
    reference.data.alchemyArt.result = nil
    reference.data.alchemyArt.effectsArray = nil
    reference.data.alchemyArt.contents = nil
    reference.data.alchemyArt.count = nil
end

function apparatus:pickResult(reference)
    local count = reference.data.alchemyArt.count or 1
    local item = reference.data.alchemyArt.result
    tes3.addItem{reference = tes3.player, item = item, count = count}
    potion.learnEffects(tes3.getObject(item), reference.data.alchemyArt.contents)
    self:cleanUp(reference)
    self:pickResultEnd(reference)
    potion.showNamingMenu(tes3.getObject(item), count)
end

function apparatus:createSelectionMenu()
	local menu = tes3ui.createMenu{id = "MenuInventorySelect", fixedFrame = true}
	menu.width = 380
	menu.height = 560
	menu.minWidth = 380
	menu.minHeight = 560
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2
    local text
    if self.filterBy == tes3.objectType.alchemy then
        text = common.dictionary.potions
    elseif self.filterBy == tes3.objectType.ingredient then
        text = common.dictionary.ingredients
    end
	local prompt = menu:createLabel{id = tes3ui.registerID("MenuInventorySelect_prompt"),  text = text}
	prompt.borderAllSides = 2
	prompt.borderBottom = 4
	local scrollpane = menu:createVerticalScrollPane{id = tes3ui.registerID("MenuInventorySelect_scrollpane")}
	scrollpane.borderAllSides = 6
	for _, stack in pairs(tes3.player.object.inventory) do
        if self:itemPassesFilter(stack.object) then
            --mwse.log(inspect(stack))
            ui.createItemBlock(menu, scrollpane, stack)
        end
	end
	local lowerBlock = ui.createAutoBlock(menu, "null")
	local cancelButton = lowerBlock:createButton {id = tes3ui.registerID("MenuInventorySelect_cancel_button"), text = common.dictionary.cancel}
	cancelButton.borderLeft = 290
	cancelButton:register("mouseClick", function() 
		menu:destroy()
		tes3ui.leaveMenuMode()
	end)
	tes3ui.enterMenuMode("MenuInventorySelect")
    --event.trigger("uiActivated", { element = menu, newlyCreated = true }, { filter = "MenuInventorySelect" })
end

function apparatus:activate(reference)

    if string.endswith(reference.id, "_static") then
        if tes3.hasOwnershipAccess{target = reference} then
            self:createMenu(reference)
        end
        return false
    end

    if not tes3.hasOwnershipAccess{target = reference} then
        return true
    end

    if reference.data.alchemyArt and reference.data.alchemyArt.progress == 100 then
        self:pickResult(reference)
        return false
    elseif reference.data.alchemyArt and reference.data.alchemyArt.progress and reference.data.alchemyArt.progress > 0 then
        return false
    elseif not tes3.menuMode() then
        self:createMenu(reference)
        return false
    else
        return true
    end
end

function apparatus:getFilterEffectList(inventory)
    return ingredients.getEffectList(inventory)
end

-- abstract method
function apparatus:createLeftBlock(element)
    mwse.log("[The Art of Alchemy]: Warning! Tried to call abstract method createLeftBlock")
end

function apparatus:addVisualEffect(reference)
end

function apparatus:startTimer(reference)

    local iterations = 100 - reference.data.alchemyArt.progress
    local alchemyTime = common.config.alchemyTime/6

    timer.start{
        duration = alchemyTime/100,
        iterations = iterations,
        type = timer.game,
        callback = function ()
            reference.data.alchemyArt.progress = reference.data.alchemyArt.progress + 1
            if reference.data.alchemyArt.progress == 100 then
                self:alchemyEnd(reference)
            end
            tes3ui.refreshTooltip()
        end
    }
end

function apparatus:alchemyBegin(reference)
    reference.data.alchemyArt = reference.data.alchemyArt or {}
    reference.data.alchemyArt.contents =  self:removeContentsFromPlayer()
    local effectsArray
    if not formulas.getSuccess() then
        effectsArray = {}
    else
        effectsArray = self:getEffectsArray(self.contents, reference.object.quality)
        -- mwse.log(inspect(effectsArray))
    end
    reference.data.alchemyArt.effectsArray = effectsArray
    -- tes3.messageBox("Current count: %s", self.count)
    reference.data.alchemyArt.count = self.count
    reference.data.alchemyArt.progress = 0
    reference.data.alchemyArt.makeStandard = tes3.worldController.inputController:isControlDown()
    self:addVisualEffect(reference)
    --specialEffects.addRetortFire(reference)
    self:startTimer(reference)
end

function apparatus:alchemyEnd(reference)
    -- mwse.log(inspect(reference.data.alchemyArt))
    local effectsArray = reference.data.alchemyArt.effectsArray
    local count = reference.data.alchemyArt.count or 1
    if next(effectsArray) == nil then
        tes3.messageBox(tes3.findGMST("sNotifyMessage8").value)
        self:cleanUp(reference)
        self:pickResultEnd(reference)
        return
    end
    local brewedPotion = potion.findExistent(effectsArray) or potion.createNew(effectsArray)
    if reference.data.alchemyArt.makeStandard then
        local sp = standardPotion.getLowerOrEqual(brewedPotion)
        brewedPotion = sp or brewedPotion
    end
    specialEffects.alchemySuccess(reference, brewedPotion)
    tes3.messageBox(tes3.findGMST("sPotionSuccess").value)
    common.practiceAlchemy(2)
    reference.data.alchemyArt.progress = 100
    reference.data.alchemyArt.result = brewedPotion.id
    tes3ui.refreshTooltip()
end

function apparatus:createRightBlock(element)
    local rightBlock = ui.createAutoBlock(element, self.menuName.."_right")
    rightBlock.borderLeft = self.rightBlockLeftBorder
    local effectList = self:getFilterEffectList(tes3.player.object.inventory)
    ui.createEffectFilter(rightBlock, "effectFilter", effectList)
end

function apparatus:onCreateEnd(menu)
    menu:destroy()
    tes3ui.leaveMenuMode()
    common.selectedEffects = {}
end

apparatus.showMainTutorial = function(e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label =  tooltip:createLabel{text = "No tutorial info found for this item"}
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end

function apparatus:createMenuWithHeader(id, item)
    local menu = tes3ui.createMenu{id = id, fixedFrame = true}
    menu.autoWidth = true
	menu.autoHeight = true
    menu.flowDirection = "top_to_bottom"
    local headerBlock = ui.createAutoBlock(menu, id.."_header")
    headerBlock.flowDirection ="top_to_bottom"
    local apparatusBlock = ui.createAutoBlock(headerBlock, id.."_apparatus") --leftBlock:createBlock{id = "MenuAlembic_alembic"}
    apparatusBlock.flowDirection = "left_to_right"
    apparatusBlock:createImage{id = id.."_image", path = "icons\\"..item.icon}
    if common.config.tutorialMode then
        apparatusBlock:register("mouseOver", self.showMainTutorial)
    end
    local label = apparatusBlock:createLabel{id = "MenuApparatus_label", text = item.name}
    label.borderTop = 7
    label.color = {0.875,0.788,0.624}
    return menu
end

function apparatus:createMenu(reference)
    self.contents = {}
    self.count = 1
    ui.selectedEffectColor = tes3ui.getPalette("header_color")
    common.filteredEffect = nil
    local menu = self:createMenuWithHeader(self.menuName, reference.object)
    local middleBlock = ui.createAutoBlock(menu, self.menuName.."_middle")
    middleBlock.flowDirection = "left_to_right"
    self:createLeftBlock(middleBlock)
    self:createRightBlock(middleBlock)

    local function onCreate(e)
        if self:countContents() >= self.minContents then
            self:alchemyBegin(reference)
        else
            tes3.messageBox(self.notEnoughContentsMessage)
            return
        end
        apparatus:onCreateEnd(menu)
    end

    ui.createBottomBlock(menu, reference, onCreate)

    tes3ui.enterMenuMode(self.menuName)
    menu:updateLayout()
end

apparatus.onTooltip = function (e)
    if not e.reference then
        return
    end

    if not e.reference.data.alchemyArt then
        return
    end

    if e.reference.data.alchemyArt.progress == nil then
        return
    end

    local main = e.tooltip:findChild("PartHelpMenu_main")

    if e.reference.data.alchemyArt.progress < 100 then
        local progressLabel = main:createLabel{id = "HelpMenu_AlchemyProgress", text = string.format("Progress: %s%%", e.reference.data.alchemyArt.progress)}
    else
        local result = tes3.getObject(e.reference.data.alchemyArt.result)
        ui.createEffectBlock(main, result.effects)
    end

    e.tooltip:updateLayout()
end


return apparatus