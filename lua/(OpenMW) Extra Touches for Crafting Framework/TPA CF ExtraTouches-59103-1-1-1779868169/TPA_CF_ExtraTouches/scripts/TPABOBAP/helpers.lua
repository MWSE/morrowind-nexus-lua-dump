local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2

local Helpers = {}

Helpers.addIngredient = function(ctx, ingredient, type, count)
    local name = string.lower(ingredient)
    local ingredients = ingredientsMutable(ctx)
    for _, i in ipairs(ingredients) do
        if i.id and string.lower(i.id) == name then
            i.count = i.count + count
            return
        end
    end
    table.insert(ingredients, { type = type, id = name, count = count })
end

-- wraps text with 2/5 vertical and 4/5 horizontal padding
Helpers.makeTextTooltip = function(text, description)
    local font_size = ui._getDefaultFontSize()
    return ui.content {
        { props = { size = v2(1, 1) } },
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                { props = { size = v2(5, 2) } },
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = text,
                        textSize = font_size,
                        textColor = TOOLTIP_FONT_COLOR,
                        textAlignH = ui.ALIGNMENT.Center,
                        multiline = true,
                        autoSize = true,
                    },
                },
                { props = { size = v2(5, 2) } },
            },
        },
        { props = { size = v2(2, 5) } },
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                { props = { size = v2(5, 2) } },
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = description,
                        textSize = font_size - 2,
                        textColor = morrowindGold,
                        textAlignH = ui.ALIGNMENT.Center,
                        autoSize = true,
                        multiline = true,
                        wordWrap = true,
                    },
                },
                { props = { size = v2(5, 2) } },
            },
        },
        { props = { size = v2(2, 2) } },
    }
end


return Helpers