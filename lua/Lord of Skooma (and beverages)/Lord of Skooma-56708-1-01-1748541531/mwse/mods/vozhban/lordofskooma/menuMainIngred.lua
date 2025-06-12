local ui = require("vozhban.lordofskooma.ui")
local recipes = require("vozhban.lordofskooma.recipes")
local apparatusState = require("vozhban.lordofskooma.apparatusState")
local distillation = require("vozhban.lordofskooma.distillation")

local function onIngredSelected(e)
    event.trigger("LOS_mainIngredSelected", {item = e.item, count = e.count})
end

local function show(itemSlot, apparatus)
    local menuID = "MenuMainIngred"
    local menu = tes3ui.showInventorySelectMenu({
        title = "Select Main Ingredient",
        noResultsText = "No suitable ingredients",
        filter = function(itemData)
            for _, other in pairs(apparatusState.get(apparatus).secondaryIngreds or {}) do
                if itemData.item.id == other then return false end
            end
	        return recipes.mainIngredIds[itemData.item.id] or false
        end,
        callback = onIngredSelected})
    event.clear("LOS_mainIngredSelected")
    event.register("LOS_mainIngredSelected", function(params)
        local item = params.item
        if not item then
            event.clear("LOS_mainIngredSelected")
            return
        end
        local count = params.count or 1
        local icon = itemSlot:createImage{id = "main_ingred_icon", path = "icons\\"..item.icon}
        icon.absolutePosAlignX = 0.5
        icon.absolutePosAlignY = 0.5
        icon.autoWidth = true
        icon.autoHeight = true

        local countLabel = icon:createLabel{id = "main_ingred_count", text = tostring(count)}
        countLabel.color = {0.6, 0.6, 0.6}
        countLabel.absolutePosAlignX = 1
        countLabel.absolutePosAlignY = 1

        local recipe = recipes.recipeList[item.id]
        local recipeOutputSlot
        local outputIcon
        if recipe then
            ui.createTooltip(itemSlot, item.name .. " produces " .. recipe.name)
            recipeOutputSlot = tes3ui.findMenu("MenuSkooma"):findChild("MenuSkoomarecipeOutputSlot")
            if recipeOutputSlot then 
                local result = tes3.getObject(recipe.result)
                outputIcon = recipeOutputSlot:createImage{id = "recipe_output_icon", path = "icons\\"..result.icon}
                recipeOutputSlot:register("help", function()
                    tes3ui.createTooltipMenu{object = result}
                end)
            end
        end

        local mainMenu = tes3ui.findMenu("MenuSkooma")
        itemSlot:register("mouseClick", function()
            icon:destroy()
            outputIcon:destroy()
            apparatusState.setValue(apparatus, "mainIngredId", nil)
            itemSlot:register("mouseClick", function()
                show(itemSlot, apparatus)
            end)
            ui.refreshAll(mainMenu, apparatus)
            ui.createTooltip(itemSlot, ui.tooltip_mainIngred)
            ui.createTooltip(recipeOutputSlot, ui.tooltip_recipeOutput)
        end)

        apparatusState.setValue(apparatus, "mainIngredId", item.id)

        if mainMenu then
            ui.refreshAll(mainMenu, apparatus)
            mainMenu:updateLayout()
        end

        event.clear("LOS_mainIngredSelected")
    end)
end

return {
    show = show
}