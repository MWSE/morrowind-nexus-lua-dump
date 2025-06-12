local ui = {}

local apparatusState = require("vozhban.lordofskooma.apparatusState")
local values = require("vozhban.lordofskooma.values")
local distillation = require("vozhban.lordofskooma.distillation")
local effectPreview = require("vozhban.lordofskooma.effectPreview")

ui.tooltip_mainIngred = "Main ingredient defines the type of brew that will be distilled"
ui.tooltip_recipeOutput = "Product will be displayed here"

ui.tooltip_upgrade = "Alchemical apparatus can be installed here for additional benefits"
ui.tooltip_mortar = "Mortar and Pestle: reduces difficulty, adds two ingredient slots, matching effect empowers product."
ui.tooltip_calcinator = "Calcinator: reduces consumption, adds one ingredient slot, matching effect empowers product."
ui.tooltip_alembic = "Alembic: reduces duration, adds one ingredient slot, matching effect empowers product."
ui.tooltip_retort = "Retort: chance for bonus product, adds one ingredient slot, empowers product by fixed amount."

ui.tooltip_secIngred_mortar = "Matching effects from this pair of ingredients will be added as in normal potions. If effects match already present - empowers product (quality) times per match."
ui.tooltip_secIngred_calcinator = "For each full quality a random effect from this ingredient will be added, may repeat. If effects match already present(including repeats) - empowers product 1 time per match. Remaining (quality) fraction will not add effect, but will empower if match."
ui.tooltip_secIngred_alembic = "If any effect in this ingredient matches the already present ones - empowers product (quality) times per match. No effects are added. Accepts potions." -- Can use a matching sample of target brew for great effect, can also premake a potion with additional effects to match all the added by other interactions. Although both may be unreasonably expensive due to consumption.
ui.tooltip_secIngred_retort = "This ingredient's value is multiplied by (quality) and added to the product value. Effects are ignored. Empowers product (quality) times."

function ui.createEmptyBlock(parent, id)
    local block = parent:createBlock{id = id}
    block.autoWidth = true
    block.autoHeight = true
    return block
end

function ui.createItemSlot(parent, id, onMouseClick)
    local slot = parent:createThinBorder{id = id}
    slot.minHeight = 50
    slot.maxHeight = 50
    slot.minWidth = 50
    slot.maxWidth = 50
    slot.autoHeight = true
    slot.autoWidth = true
    slot.borderAllSides = 4
    slot.paddingAllSides = 8
    slot.childAlignY = 0.5
    slot:register("mouseClick", onMouseClick)
    return slot
end

function ui.createSecondaryIngredSlot(apparatus, slotIndex, n)
    local slotId = (slotIndex - 1) * 2 + n
    local menu = tes3ui.findMenu("MenuSkooma")
    local block
    if menu then
        block = menu:findChild(string.format("MenuSkooma_upgradeBlock%d", slotIndex))
    else
        return
    end
    local slot
    if block then
        slot = block:createThinBorder{id = string.format("MenuSkooma_secIngredSlot%d", slotId)}
    else
        return
    end
    slot.minHeight = 50
    slot.maxHeight = 50
    slot.minWidth = 50
    slot.maxWidth = 50
    slot.autoHeight = true
    slot.autoWidth = true
    slot.borderAllSides = 4
    slot.paddingAllSides = 8
    slot.childAlignY = 0.5

    local upgradeType = tes3.getObject(apparatusState.get(apparatus).upgrades[slotIndex]).type
    local acceptPotions = false
    if upgradeType == tes3.apparatusType.mortarAndPestle then
        ui.createTooltip(slot, ui.tooltip_secIngred_mortar)
    elseif upgradeType == tes3.apparatusType.calcinator then
        ui.createTooltip(slot, ui.tooltip_secIngred_calcinator)
    elseif upgradeType == tes3.apparatusType.alembic then
        ui.createTooltip(slot, ui.tooltip_secIngred_alembic)
        acceptPotions = true
    elseif upgradeType == tes3.apparatusType.retort then
        ui.createTooltip(slot, ui.tooltip_secIngred_retort)
    end

    local function openSecIngredSelector()
        local state = apparatusState.get(apparatus)
        if state.mainIngredId == "" or state.mainIngredId == nil then
            tes3.messageBox("Select a main ingredient first.")
            return
        end

        tes3ui.showInventorySelectMenu{
            title = "Select Secondary Ingredient",
            filter = function(itemData)
                if itemData.item.id == state.mainIngredId then return false end
                for _, other in pairs(state.secondaryIngreds or {}) do
                    if itemData.item.id == other then return false end
                end
                if acceptPotions then
                    return itemData.item.objectType == tes3.objectType.alchemy or itemData.item.objectType == tes3.objectType.ingredient or false
                end
                return itemData.item.objectType == tes3.objectType.ingredient or false
            end,
            callback = function(e)
                if not e.item then return end
                state.secondaryIngreds = state.secondaryIngreds or {}
                state.secondaryIngreds[slotId] = e.item.id
                local icon = slot:createImage{path = "icons\\"..e.item.icon}
                icon.absolutePosAlignX = 0.5
                icon.absolutePosAlignY = 0.5
                icon.autoWidth = true
                icon.autoHeight = true

                local countLabel = icon:createLabel{id = "main_ingred_count", text = tostring(e.count)}
                countLabel.color = {0.6, 0.6, 0.6}
                countLabel.absolutePosAlignX = 1
                countLabel.absolutePosAlignY = 1

                slot:register("help", function()
                    tes3ui.createTooltipMenu{object = e.item}
                end)

                slot:register("mouseClick", function()
                    icon:destroy()
                    state.secondaryIngreds[slotId] = nil
                    slot:register("mouseClick", function()
                        openSecIngredSelector()
                    end)
                    ui.refreshAll(menu, apparatus)
                    if upgradeType == tes3.apparatusType.mortarAndPestle then
                        ui.createTooltip(slot, ui.tooltip_secIngred_mortar)
                    elseif upgradeType == tes3.apparatusType.calcinator then
                        ui.createTooltip(slot, ui.tooltip_secIngred_calcinator)
                    elseif upgradeType == tes3.apparatusType.alembic then
                        ui.createTooltip(slot, ui.tooltip_secIngred_alembic)
                    elseif upgradeType == tes3.apparatusType.retort then
                        ui.createTooltip(slot, ui.tooltip_secIngred_retort)
                    end
                end)
                if menu then
                    ui.refreshAll(menu, apparatus)
                    menu:updateLayout()
                end
            end
        }
    end

    slot:register("mouseClick", openSecIngredSelector)
    return slot
end

function ui.createTooltip(parent, text)
    parent:register("help", function()
        local tooltip = tes3ui.createTooltipMenu()
        tooltip.autoHeight = true
        tooltip.autoWidth = true
        tooltip.wrapText = true
        local label = tooltip:createLabel{text = text}
        label.autoHeight = true
        label.autoWidth = true
        label.wrapText = true
    end)
end

function ui.refreshStats(menu, apparatus)
    local state = apparatusState.get(apparatus)
    local totals = apparatusState.getTotals(state)

    if state.mainIngredId == nil or state.mainIngredId == "" then return end

    local distillDiffLabel = menu:findChild("distill_difficulty_label")
    local ingredConsLabel = menu:findChild("ingred_consumption_label")
    local timeLabel = menu:findChild("distill_time_label")
    local distillChanLabel = menu:findChild("distill_chance_label")

    local diff = distillation.getRecipeDifficulty(apparatus, state.mainIngredId)
    local cons = distillation.getMainIngredConsumption(apparatus, state.mainIngredId)
    local chance = distillation.getSuccessChance(apparatus, state.mainIngredId)
    local time = distillation.getDistillationTimeMult(apparatus)

    distillDiffLabel.text = string.format("Difficulty: %d ", diff)
    ingredConsLabel.text = string.format("Consumption: %d ", cons)
    timeLabel.text = string.format("Time: %d%% ", time)
    distillChanLabel.text = string.format("Chance: %d%% ", chance)

    -- bonus section
    local mortarStatLabel = menu:findChild("mortar_stat_label")
    local calcinatorStatLabel = menu:findChild("calcinator_stat_label")
    local alembicStatLabel = menu:findChild("alembic_stat_label")
    local retortStatLabel = menu:findChild("retort_stat_label")

    mortarStatLabel.text = string.format("Mortar: %.2f", apparatusState.getMortarQuality(totals))
    calcinatorStatLabel.text = string.format("Calcinator: %.2f", apparatusState.getCalcinatorQuality(totals))
    alembicStatLabel.text = string.format("Alembic: %.2f", apparatusState.getAlembicQuality(totals))
    retortStatLabel.text = string.format("Retort: %.2f", apparatusState.getRetortQuality(totals))

    --retort section
    local mainIngredBlock = menu:findChild("MenuSkoomamainIngredBlock")
    for i = 1, values.maxUpgradeSlots do
        local upgrade = state.upgrades and state.upgrades[i]
        if upgrade then
            local item = tes3.getObject(upgrade)
            if item and item.type == tes3.apparatusType.retort then
                local retortBonusLabel = mainIngredBlock:findChild("retort_output_label_"..i)
                if retortBonusLabel then retortBonusLabel:destroy() end
                retortBonusLabel = mainIngredBlock:createLabel{id = "retort_output_label_"..i, text = string.format("%d. Extra product[%.2f]: %.2f%%", i, item.quality, apparatusState.getRetortBonus(totals) * item.quality)}
            end
        else
            local retortBonusLabel = mainIngredBlock:findChild("retort_output_label_"..i)
            if retortBonusLabel then retortBonusLabel:destroy() end
        end
    end
end

function ui.drawApparatusTooltip(tooltip, reference)
    if not reference or not reference.data then return end
    local state = apparatusState.get(reference)

    local block = ui.createEmptyBlock(tooltip)
    block.flowDirection = "top_to_bottom"
    block.minWidth = 150
    block.paddingAllSides = 6

    local topBlock = ui.createEmptyBlock(block)
    topBlock.flowDirection = "left_to_right"

    topBlock:createImage{path = "icons\\"..reference.object.icon}
    local label = topBlock:createLabel{text = reference.object.name}
    label.color = {0.8, 0.8, 0.8}
    label.absolutePosAlignY = 0.5
    block:createDivider()

    local upgradeBlock = ui.createEmptyBlock(block)
    upgradeBlock.flowDirection = "left_to_right"
    local hasUpgrades = false
    
    for i = 1, values.maxUpgradeSlots do
        local upgrade = state.upgrades and state.upgrades[i]
        if upgrade then
            local item = tes3.getObject(upgrade)
            if item then
                local row = ui.createEmptyBlock(upgradeBlock)
                row.flowDirection = "left_to_right"
                local icon = row:createImage{path = "icons\\"..item.icon}
                icon.width = 32
                local qualityLabel = icon:createLabel{text = string.format("%.2f", item.quality)}
                qualityLabel.absolutePosAlignX = 1
                qualityLabel.absolutePosAlignY = 0
                qualityLabel.color = {0.6, 0.6, 0.6}
                hasUpgrades = true
            end
        end
    end

    block:createDivider()

    -- Show running progress
    if state.isRunning and state.startTime then
        local elapsed = tes3.getSimulationTimestamp() - state.startTime
        local progress = math.min(elapsed / distillation.getDistillationTime(reference), 1)

        local progressBar = block:createThinBorder{}
        progressBar.width = 120
        progressBar.height = 16
        progressBar.absolutePosAlignX = 0.5
        progressBar.childOffsetX = 1
        progressBar.childOffsetY = -2
        local fill = progressBar:createRect{}
        fill.color = {0.5, 0.25, 0.1}
        fill.width = progress * 118
        fill.height = 12
    end

    local contentBlock = ui.createEmptyBlock(tooltip)
    contentBlock.flowDirection = "left_to_right"

    local hasItems = false

    for id, count in pairs(state.storage or {}) do
        local item = tes3.getObject(id)
        if item and count > 0 then
            local row = ui.createEmptyBlock(contentBlock)
            row.flowDirection = "left_to_right"
            local icon = row:createImage{path = "icons\\"..item.icon}
            icon.width = 32
            local countLabel = icon:createLabel{text = tostring(count)}
            countLabel.absolutePosAlignX = 1
            countLabel.absolutePosAlignY = 1
            countLabel.color = {0.6, 0.6, 0.6}
            hasItems = true
        end
    end

    if not hasItems and not state.isRunning then
        block:createLabel{text = "Empty"}.absolutePosAlignX = 0.5
    elseif not state.isRunning and hasItems then
        block:createLabel{text = "Ready to collect"}.absolutePosAlignX = 0.5
    end
end

-- Builds (or refreshes) the RightBlock pane ----------
function ui.drawEffectPane(menu, apparatus)
    local right = menu:findChild("MenuSkoomarightBlock")
    if not right then return end
    right:destroyChildren()

    local prev = effectPreview.calculate(apparatus)
    if not prev then return end

    -- header
    local header = ui.createEmptyBlock(right)
    header.flowDirection = "left_to_right"
    header:createLabel{text = string.format("Power: %.2f - %.2f", prev.guaranteed, prev.potential)}

    right:createDivider()

    local dividerDropped = false
    for _, fx in ipairs(prev.effects) do
        if fx.potentialOnly and not dividerDropped then
            right:createDivider()
            dividerDropped = true
        end

        local row = ui.createEmptyBlock(right)
        row.flowDirection = "left_to_right"
        row.minWidth = 320

        local icon
        if fx.id == "retort_fake" then
            icon = row:createImage{path = "icons\\Vozhb\\fake_retort_eff.dds"}
        else
            icon = row:createImage{path = ("icons\\"..tes3.getMagicEffect(fx.id).icon) or "icons\\Vozhb\\fake_retort_eff.dds"}
        end
        icon.width=16

        local nameLabel = row:createLabel{ text = fx.name }
        nameLabel.borderLeft = 4
        nameLabel.borderRight = 12

        if fx.potentialOnly then
            nameLabel.color = { 0.5, 0.5, 0.4 }   -- dim
        end

        local gpow = row:createLabel{text = string.format("%.2f", fx.g)}
        gpow.absolutePosAlignX = 0.85
        gpow.color = {0.8, 0.8, 0.8}

        if fx.p > 0 then
            local ppow = row:createLabel{text  = string.format(" / %.2f", fx.p)}
            ppow.absolutePosAlignX = 1
            ppow.color = { 0.5, 0.5, 0.5 }
        end
    end

    right:createDivider()

    -- totals
    right:createLabel{text=string.format("Magnitude: %.0f - %.0f", prev.mag or 0, prev.magMax or 0)}
    right:createLabel{text=string.format("Duration: %.0f - %.0f", prev.dur or 0, prev.durMax or 0)}
    right:createLabel{text=string.format("Value: %.0f - %.0f", prev.value or 0, prev.valueMax or 0)}
end

-- call this instead of plain refreshStats when layout might change
function ui.refreshAll(menu, apparatus)
    ui.refreshStats(menu, apparatus)
    ui.drawEffectPane(menu, apparatus)
    if menu then menu:updateLayout() end
end

return ui