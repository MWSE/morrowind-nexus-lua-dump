
local ExtraFeatures = require("mer.chargenScenarios.component.ExtraFeatures")
local ChargenMenu = require("mer.chargenScenarios.component.ChargenMenu")

---@type ChargenScenarios.ChargenMenu.config
local menu = {
    id = "extrasMenu",
    name = "Дополнительные опции",
    priority = -2000,
    buttonLabel = "Опции",
    getButtonValue = function(self)
        return string.format("Выбранные опции: %d", #ExtraFeatures.getActiveFeatures())
    end,
    createMenu = function(self)
        ExtraFeatures.openMenu{
            okCallback = function()
                self:okCallback()
            end,
        }
    end,
    onStart = function(self)
        ExtraFeatures.onStart()
    end,
    getTooltip = function(self)
        return ExtraFeatures.getTooltip()
    end,
    isActive = function(self)
        return #ExtraFeatures.getAvailableFeatures() > 0
    end
}

ChargenMenu.register(menu)