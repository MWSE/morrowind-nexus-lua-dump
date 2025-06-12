
local common = require("mer.chargenScenarios.common")
local ChargenMenu = require("mer.chargenScenarios.component.ChargenMenu")
local backgroundsInterop = include('mer.characterBackgrounds.interop')
local logger = common.createLogger("Menus")

---@type ChargenScenarios.ChargenMenu.config
local menu = {
    id = "characterBackgrounds",
    name = "Предыстории персонажей",
    priority = 100,
    buttonLabel = "Предыстория",
    getButtonValue = function(self)
        local background = backgroundsInterop.getCurrentBackground()
        return background and background:getName() or "None"
    end,
    createMenu = function(self)
        backgroundsInterop.openMenu{
            okCallback = function()
                logger:debug("Backgrounds menu closed, calling okCallback")
                self:okCallback()
            end
        }
    end,
    isActive = function(self)
        return backgroundsInterop
            and backgroundsInterop.openMenu ~= nil
    end,
    getTooltip = function(self)
        local background = backgroundsInterop.getCurrentBackground()
        return background and {
            header = background:getName(),
            description = background:getDescription()
        } or {
            header = "Предыстория",
            description = "Выберите предысторию персонажа."
        }
    end
}

ChargenMenu.register(menu)