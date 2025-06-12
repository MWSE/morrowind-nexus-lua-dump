local menuMainIngred = require("vozhban.lordofskooma.menuMainIngred")
local menuUpgrade = require("vozhban.lordofskooma.menuUpgrade")
local ui = require("vozhban.lordofskooma.ui")
local distillation = require("vozhban.lordofskooma.distillation")
local apparatusState = require("vozhban.lordofskooma.apparatusState")
local values = require("vozhban.lordofskooma.values")

local function show(target)
    local menuId = "MenuSkooma"

    local state = apparatusState.get(target)

    if state.isRunning == true then
        tes3.messageBox("Do not put your fingers into a working device")
        return
    end

    if state.storage and next(state.storage) then
        for id, count in pairs(state.storage or {}) do
            tes3.addItem{reference = tes3.player, item = id, count = count}
            tes3.messageBox("You collect %d %s.", count, tes3.getObject(id).name)
        end
        apparatusState.clear(target)
        return
    end

    apparatusState.clear(target)

    local menu = tes3ui.createMenu {
        id = menuId,
        fixedFrame = true
    }
    menu.autoWidth = true
    menu.autoHeight = true
    menu.flowDirection = "top_to_bottom"

    local topBlock = ui.createEmptyBlock(menu, menuId.."topBlock")
    topBlock.borderBottom = 10
    topBlock.flowDirection = "left_to_right"
    topBlock:createImage {
        id = "apparatus_image",
        path = "icons\\"..target.object.icon
    }
    topBlock:createLabel {
        text = "Distillery",
    }
    ui.createTooltip(topBlock, "Skooma distilling apparatus")

    local centerBlock = ui.createEmptyBlock(menu, menuId.."centerBlock")
    centerBlock.flowDirection = "left_to_right"

    local mainIngredBlock = ui.createEmptyBlock(centerBlock, menuId.."mainIngredBlock")
    mainIngredBlock.flowDirection = "top_to_bottom"
    mainIngredBlock.minWidth = 140
    local mainIngredSlotsBlock = ui.createEmptyBlock(mainIngredBlock, menuId.."mainIngredSlotsBlock")
    mainIngredSlotsBlock.flowDirection = "left_to_right"
    local mainIngredSlot
    mainIngredSlot = ui.createItemSlot(mainIngredSlotsBlock, menuId.."mainIngredSlot", function()
        menuMainIngred.show(mainIngredSlot, target)
    end)
    ui.createTooltip(mainIngredSlot, ui.tooltip_mainIngred)
    local recipeOutputSlot = ui.createItemSlot(mainIngredSlotsBlock, menuId.."recipeOutputSlot", function()
        return
    end)
    ui.createTooltip(recipeOutputSlot, ui.tooltip_recipeOutput)
    mainIngredBlock:createDivider()

    --main stats section
    local mainIngredConsumption = mainIngredBlock:createLabel{id = "ingred_consumption_label",text = "Consumption: "}
    local distillationDifficulty = mainIngredBlock:createLabel{id = "distill_difficulty_label",text = "Difficulty: "}
    local timeConsumption = mainIngredBlock:createLabel{id = "distill_time_label",text = "Time: "}

    mainIngredBlock:createDivider()
    --upgrades section
    local mortarStatLabel = mainIngredBlock:createLabel{id = "mortar_stat_label", text = "Mortar: "}
    local calcinatorStatLabel = mainIngredBlock:createLabel{id = "calcinator_stat_label", text = "Calcinator: "}
    local alembicStatLabel = mainIngredBlock:createLabel{id = "alembic_stat_label", text = "Alembic: "}
    local retortStatLabel = mainIngredBlock:createLabel{id = "retort_stat_label", text = "Retort: "}

    ui.createTooltip(mortarStatLabel, ui.tooltip_secIngred_mortar)
    ui.createTooltip(calcinatorStatLabel, ui.tooltip_secIngred_calcinator)
    ui.createTooltip(alembicStatLabel, ui.tooltip_secIngred_alembic)
    ui.createTooltip(retortStatLabel, ui.tooltip_secIngred_retort)

    mainIngredBlock:createDivider()
    --retort section

    for i = 1, values.maxUpgradeSlots do
        local block = ui.createEmptyBlock(centerBlock, string.format("%s_upgradeBlock%d", menuId, i))
        block.flowDirection = "top_to_bottom"

        local slot
        slot = ui.createItemSlot(block, string.format("%s_upgradeSlot%d", menuId, i), function()
            menuUpgrade.show(slot, target, i)
        end)
        ui.createTooltip(slot, ui.tooltip_upgrade)

        local upgrade = state.upgrades[i]
        if upgrade then
            local item = tes3.getObject(upgrade)
            if item then
                local icon = slot:createImage{path = "icons\\" .. item.icon}
                icon.absolutePosAlignX = 0.5
                icon.absolutePosAlignY = 0.5
                icon.autoWidth = true
                icon.autoHeight = true

                local qualityLabel = icon:createLabel{text = string.format("%.2f", item.quality)}
                qualityLabel.color = {0.6, 0.6, 0.6}
                qualityLabel.absolutePosAlignX = 1
                qualityLabel.absolutePosAlignY = 0

                local upgradeType = item.type
                local secSlotCount = 1
                if upgradeType == tes3.apparatusType.mortarAndPestle then
                    ui.createTooltip(slot, ui.tooltip_mortar)
                    secSlotCount = 2
                elseif upgradeType == tes3.apparatusType.calcinator then
                    ui.createTooltip(slot, ui.tooltip_calcinator)
                elseif upgradeType == tes3.apparatusType.alembic then
                    ui.createTooltip(slot, ui.tooltip_alembic)
                elseif upgradeType == tes3.apparatusType.retort then
                    ui.createTooltip(slot, ui.tooltip_retort)
                end

                slot:register("mouseClick", function()
                    for n = 1, secSlotCount do
                        local secSlot = menu:findChild("MenuSkooma_secIngredSlot".. (i - 1) * 2 + n)
                        if secSlot then
                            secSlot:destroy()
                            state.secondaryIngreds[(i - 1) * 2 + n] = nil
                        end
                    end
                    icon:destroy()
                    state.upgrades[i] = nil
                    tes3.addItem{reference = tes3.player, item = item.id, count = 1}
                    slot:register("mouseClick", function()
                        menuUpgrade.show(slot, target, i)
                    end)
                    ui.refreshAll(menu, target)
                    menu:updateLayout()
                    ui.createTooltip(slot, ui.tooltip_mainIngred)
                end)

                for n = 1, secSlotCount do
                    ui.createSecondaryIngredSlot(target, i, n)
                end

            end
        end
    end

    local rightBlock = ui.createEmptyBlock(centerBlock, menuId.."rightBlock")
    rightBlock.minWidth = 250
    rightBlock.flowDirection = "top_to_bottom"

    menu:createDivider()
    local lowBlock = ui.createEmptyBlock(menu, menuId.."lowBlock")
    local distillationChance = lowBlock:createLabel{id = "distill_chance_label",text = "Chance: "}

    local bottomBlock = ui.createEmptyBlock(menu, menuId.."bottomBlock")
    bottomBlock.borderTop = 10
    bottomBlock.flowDirection = "left_to_right"
    local bottomLeftBlock = ui.createEmptyBlock(bottomBlock, menuId.."bottomLeftBlock")
    local distillButton = bottomLeftBlock:createButton{id = menuId.."distill_button", text = "Distill"}
    ui.createTooltip(distillButton, "Start distillation process")
    distillButton:register("mouseClick", function()
        local state = apparatusState.get(target)
        if state.isRunning then
            --Should not happen
            tes3.messageBox("Distillation already in progress.")
            return
        end
        if not state.mainIngredId then
            tes3.messageBox("No main ingredient selected.")
            return
        end

        local forceVanilla = tes3.worldController.inputController:isKeyDown(tes3.scanCode.leftShift)
        apparatusState.setForceVanilla(target, forceVanilla)

        -- Always include the main ingredient
        local checklist = {
            { id = state.mainIngredId }
        }

        -- In empowered mode add every secondary slot that is filled
        if not apparatusState.getForceVanilla(target) then
            for slot = 1, values.maxUpgradeSlots * 2 do
                local sid = state.secondaryIngreds and state.secondaryIngreds[slot]
                if sid then
                    table.insert(checklist, { id = sid })
                end
            end
        end

        local requiredMap = {}     -- id → required count
        for _, entry in ipairs(checklist) do
            local id       = entry.id
            if not requiredMap[id] then        -- skip duplicates (two same ingredients can share source stack)
                local available = tes3.getItemCount{ reference = tes3.player, item = id }
                local required = distillation.getMainIngredConsumption(target, state.mainIngredId)

                if state.mode == 1 then
                    local prowess    = distillation.getProwess()
                    local difficulty = distillation.getRecipeDifficulty(target, state.mainIngredId)
                    local potentialProduced = math.floor((prowess - difficulty) / 100) + 1

                    if required < potentialProduced then
                        required = math.min(potentialProduced, available)
                    end
                elseif state.mode == 0 then
                    required = available
                end

                if available < 1 then
                    tes3.messageBox("Not enough ingredients.")
                    return
                end
                if available < required then
                    tes3.messageBox("Not enough %s (need %d)", tes3.getObject(id).name, required)
                    return
                end

                requiredMap[id] = required
            end
        end

        --[[tes3.removeItem{reference = tes3.player, item = state.mainIngredId, count = required}
        apparatusState.setValue(target, "storage", { [state.mainIngredId] = required })
        ]]

        local storage = apparatusState.get(target).storage or {}
        for id, required in pairs(requiredMap) do
            tes3.removeItem{ reference = tes3.player, item = id, count = required, playSound = false }
            storage[id] = (storage[id] or 0) + required
        end
        tes3.playSound{reference = tes3.player, sound = "Item Ingredient Up"}

        apparatusState.setValue(target, "storage", storage)
        apparatusState.setValue(target, "prowessSamples", {})

        apparatusState.setValue(target, "isRunning", true)
        apparatusState.setValue(target, "startTime", tes3.getSimulationTimestamp())
        tes3.messageBox("Distillation started")
        tes3.createVisualEffect{
            position = target.position:copy(),
            object = "Light_Fire",
            lifespan = distillation.getDistillationTime(target)*120,
            scale = 0.1,
            verticalOffset = 0
        }

        tes3ui.leaveMenuMode()
        menu:destroy()

    end)

    local optionButton = bottomLeftBlock:createCycleButton{id = menuId.."option_button", options = {{text = "Once", value = 1},{text = "All", value = 0}}}
    ui.createTooltip(optionButton, "Distill one batch or while the ingredients last")
    optionButton:register("valueChanged", function()
        apparatusState.setValue(target, "mode", optionButton.widget.value)
    end)

    local bottomRightBlock = ui.createEmptyBlock(bottomBlock, menuId.."bottomRightBlock")
    local pickUpButton = bottomRightBlock:createButton{id = menuId.."pickUp_button", text = "Pick Up"}
    pickUpButton:register("mouseClick", function()

        for i = 1, values.maxUpgradeSlots do
            local upgrade = state.upgrades and state.upgrades[i]
            if upgrade then
                tes3.addItem{reference = tes3.player, item = upgrade, count = 1}
            end
        end

        if tes3.worldController.inputController:isKeyDown(tes3.scanCode.leftShift) then
            apparatusState.setValue(target, "upgrades", {})
            tes3.messageBox("All upgrades uninstalled.")
            menu:destroy()
            tes3ui.leaveMenuMode()
            show(target)
            return
        end

        menu:destroy()
        tes3ui.leaveMenuMode()
        apparatusState.clear(target, true)
        tes3.addItem{reference = tes3.player, item = target.id}
        target:disable()
        target:delete()
    end)

    local cancelButton = bottomRightBlock:createButton{id = menuId.."cancel_button", text = "Cancel"}
    cancelButton:register("mouseClick", function()
        apparatusState.clear(target)
        menu:destroy()
        tes3ui.leaveMenuMode()
    end)

    ui.refreshAll(menu, target)
    if menu then menu:updateLayout() end
    tes3ui.enterMenuMode(menuId)
end

return {
    show = show
}