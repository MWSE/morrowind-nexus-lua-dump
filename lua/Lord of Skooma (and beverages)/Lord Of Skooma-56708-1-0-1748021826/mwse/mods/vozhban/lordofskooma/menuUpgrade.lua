local ui = require("vozhban.lordofskooma.ui")
local apparatusState = require("vozhban.lordofskooma.apparatusState")
local distillation = require("vozhban.lordofskooma.distillation")

local function filterApparatus(itemData)
    --mwse.log("Checking item: %s", itemData.item.id..(tostring(recipes.mainIngredIds[itemData.item.id]) or "false"))
	return itemData.item.objectType == tes3.objectType.apparatus or false
end

local function onApparatusSelected(e)
    event.trigger("LOS_upgradeSelected", {item = e.item})
end

local function show(itemSlot, apparatus, slotIndex)
    local menuID = "MenuUpgrade"
    local menu = tes3ui.showInventorySelectMenu({title = "Select an Apparatus to install", noResultsText = "No suitable apparatus", filter = filterApparatus, callback = onApparatusSelected})
    event.clear("LOS_upgradeSelected")
    event.register("LOS_upgradeSelected", function(params)
        local item = params.item
        if not item then
            event.clear("LOS_upgradeSelected")
            return
        end
        local icon = itemSlot:createImage{id = itemSlot.name.."upgrade_icon", path = "icons\\"..item.icon}
        icon.absolutePosAlignX = 0.5
        icon.absolutePosAlignY = 0.5
        icon.autoWidth = true
        icon.autoHeight = true

        local qualityLabel = icon:createLabel{id = itemSlot.name.."upgrade_quality", text = string.format("%.2f", item.quality)}
        qualityLabel.color = {0.6, 0.6, 0.6}
        qualityLabel.absolutePosAlignX = 1
        qualityLabel.absolutePosAlignY = 0

        local upgradeType = item.type
        local slotCount = 1
        if upgradeType == tes3.apparatusType.mortarAndPestle then
            ui.createTooltip(itemSlot, ui.tooltip_mortar)
            slotCount = 2
        elseif upgradeType == tes3.apparatusType.calcinator then
            ui.createTooltip(itemSlot, ui.tooltip_calcinator)
        elseif upgradeType == tes3.apparatusType.alembic then
            ui.createTooltip(itemSlot, ui.tooltip_alembic)
        elseif upgradeType == tes3.apparatusType.retort then
            ui.createTooltip(itemSlot, ui.tooltip_retort)
        end

        local state = apparatusState.get(apparatus)

        local mainMenu = tes3ui.findMenu("MenuSkooma")
        itemSlot:register("mouseClick", function()
            for n = 1, slotCount do
                local secSlot = tes3ui.findMenu("MenuSkooma"):findChild("MenuSkooma_secIngredSlot".. (slotIndex - 1) * 2 + n)
                if secSlot then
                    secSlot:destroy()
                    state.secondaryIngreds[(slotIndex - 1) * 2 + n] = nil
                end
            end
            icon:destroy()
            state.upgrades[slotIndex] = nil
            tes3.addItem{reference = tes3.player, item = item.id, count = 1}
            itemSlot:register("mouseClick", function()
                show(itemSlot, apparatus, slotIndex)
            end)
            ui.refreshAll(mainMenu, apparatus)
            tes3ui.findMenu("MenuSkooma"):updateLayout()
            ui.createTooltip(itemSlot, ui.tooltip_upgrade)
        end)

        state.upgrades[slotIndex] = item.id
        tes3.removeItem{reference = tes3.player, item = item.id, count = 1, playSound = false}

        -- Create Secondary Ingred Slot(s)
        for n = 1, slotCount do
            ui.createSecondaryIngredSlot(apparatus, slotIndex, n)
        end

        if mainMenu then
            ui.refreshAll(mainMenu, apparatus)
            mainMenu:updateLayout()
        end

        event.clear("LOS_upgradeSelected")
    end)
end

return {
    show = show
}