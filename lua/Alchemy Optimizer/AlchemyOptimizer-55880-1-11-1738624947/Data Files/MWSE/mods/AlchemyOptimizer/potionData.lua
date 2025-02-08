-- potionData.lua
local this = {}

local menuId = "potionDataMenu"

function this.showPotionData(potionName, ingredientIds, potionCount)
    -- Destroy existing menu if present
    local existing = tes3ui.findMenu(menuId)
    if existing then
        existing:destroy()
    end

    -- Create the menu
    local menu = tes3ui.createMenu({ id = menuId, dragFrame = true, fixedFrame = false, modal = false, loadable = true })
    menu.text = potionName
    menu.width = 400
    menu.height = 300
    menu.absolutePosAlignX = 0.8
    menu.absolutePosAlignY = 0.5

    -- Title block
    local titleBlock = menu:createBlock({})
    titleBlock.widthProportional = 1.0
    titleBlock.autoHeight = true
    titleBlock.childAlignX = 0.5
    titleBlock:createLabel({ text = string.format("Potion: %s", potionName) })

    -- Potion count
    local countBlock = menu:createBlock({})
    countBlock.widthProportional = 1.0
    countBlock.autoHeight = true
    countBlock.childAlignX = 0.5
    countBlock:createLabel({ text = string.format("Can brew: %d", potionCount) })

    -- Ingredient list
    local scrollPane = menu:createVerticalScrollPane({})
    scrollPane.widthProportional = 1.0
    scrollPane.heightProportional = 1.0

    for _, ingrId in ipairs(ingredientIds) do
        local ingredient = tes3.getObject(ingrId)
        if ingredient then
            local block = scrollPane:createBlock({})
            block.widthProportional = 1.0
            block.autoHeight = true
            block:createLabel({ text = ingredient.name })
        else
            mwse.log("[PotionData] Warning: Ingredient ID '%s' not found!", ingrId)
        end
    end

    -- Close button
    local closeBlock = menu:createBlock({})
    closeBlock.widthProportional = 1.0
    closeBlock.autoHeight = true
    closeBlock.childAlignX = 1.0
    local closeButton = closeBlock:createButton({ text = "Close" })
    closeButton:register("mouseClick", function()
        menu:destroy()
    end)

    -- Finalize layout
    menu:updateLayout()
end

function this.close()
    local existing = tes3ui.findMenu(menuId)
    if existing then
        existing:destroy()
    end
end

return this
