local common = require ("mer.ashfall.common.common")
local WoodStack = require("mer.ashfall.items.woodStack")
local takeWood = WoodStack.buttons.takeWood
return {
    text = takeWood.text,
    tooltip = function()
        return common.helper.showHint(string.format(
            "Вы можете взять дрова напрямую, активировав стопку дров, удерживая нажатой кнопку %s.",
            common.helper.getModifierKeyString()
        ))
    end,
    enableRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return takeWood.enableRequirements{ reference = reference }
    end,
    tooltipDisabled = takeWood.tooltipDisabled,
    callback = function(reference)
        return takeWood.callback{reference = reference}
    end,
}