--[[
    A UI for showing the current line tension and
    the remaining fatigue of the fish
]]

local common = require("mer.fishing.common")
local logger = common.createLogger("FightIndicator")
local config = require("mer.fishing.config")
local FishingNet = require("mer.fishing.FishingNet")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

---@class Fishing.FightIndicator.new.params
---@field fightManager Fishing.FightManager

---@class Fishing.FightIndicator
---@field fightManager Fishing.FightManager
local FightIndicator = {
    uiids = {
        menu ="Fishing:FightIndicatorMenu",
        tensionBar = "Fishing:FightIndicatorTension",
        tensionIndicator = "Fishing:FightIndicatorTensionIndicator",
        fatigueBar = "Fishing:FightIndicatorFatigue",

    },
    width = 360,
    barHeight = 12,
}

---@param e Fishing.FightIndicator.new.params
function FightIndicator:new(e)
    local self = setmetatable({}, {__index = FightIndicator})
    self.fightManager = e.fightManager
    return self
end

function FightIndicator:getMenu()
    local menuMulti = tes3ui.findMenu("MenuMulti")
    if not menuMulti then
        logger:error("Could not find MenuMulti")
        return
    end
    local menu = menuMulti:findChild(self.uiids.menu)
    if not menu then
        logger:trace("Could not find FightIndicatorMenu")
        return
    end
    return menu
end

--[[
    Calculate the size of the left block
    by comparing the minimum tension to the

]]
local function getLeftBlockProportion()
    local minRange = config.constants.TENSION_MINIMUM
    local maxRange = config.constants.TENSION_MAXIMUM
    local totalRange = maxRange - minRange
    logger:debug("totalRange: %s", totalRange)

    local minLimit = config.constants.FIGHT_TENSION_LOWER_LIMIT
    local leftSize = minLimit - minRange
    logger:debug("leftSize: %s", leftSize)

    logger:debug("leftSize / totalRange: %s", leftSize / totalRange)
    return leftSize / totalRange * 0.9
end

local function getRightBlockProportion()
    local minRange = config.constants.TENSION_MINIMUM
    local maxRange = config.constants.TENSION_MAXIMUM
    local totalRange = maxRange - minRange

    local maxLimit = config.constants.FIGHT_TENSION_UPPER_LIMIT
    local rightSize = maxRange - maxLimit

    return rightSize / totalRange * 0.9
end

--[[Y
    Creates an indicator showing how much tension
    is being applied to the fishing line.

    On the left and right, are red bars showing
    the tension where the fish will escape
]]
---@param parent tes3uiElement
function FightIndicator:createTensionBar(parent)
    local label = parent:createLabel{
        text = "Натяжение",
    }
    label.absolutePosAlignX = 0.5
    label.color = tes3ui.getPalette("header_color")

    local border = parent:createThinBorder()
    border.autoWidth = true
    border.autoHeight = true
    border.widthProportional = 1
    border.borderTop = 5
    border.borderBottom = 5
    border.paddingAllSides = 4
    --create block with auto width
    local tensionBar = border:createBlock{
        id = self.uiids.tensionBar,
    }
    tensionBar.widthProportional = 1
    tensionBar.autoHeight = true

    --Add red bar to the left
    local red = tes3vector3.new(0.75,0.2,0.2)
    local extraOverlapZone = 10
    local leftBlock = tensionBar:createRect{
        color = red,
    }
    leftBlock.width = self.width * getLeftBlockProportion() + extraOverlapZone
    leftBlock.height = self.barHeight
    leftBlock.absolutePosAlignX = 0.0

    --Add red bar to the right
    local rightBlock = tensionBar:createRect{
        color = red,
    }
    rightBlock.width = self.width * getRightBlockProportion() + extraOverlapZone
    rightBlock.height = self.barHeight
    rightBlock.absolutePosAlignX = 1.0

    --Create tension indicator image, overlapping other UI elements via ignoreLayout
    local tensionImage = parent:createBlock{
        id = self.uiids.tensionIndicator,
    }
    tensionImage.ignoreLayoutY = true
    tensionImage.positionY = -26
    tensionImage.autoHeight = true
    tensionImage.autoWidth = true

    local image = tensionImage:createImage{
        path = "textures\\mer_fishing\\tension_indicator.dds",
    }
    image.width = 32
    image.height = 32
    image.scaleMode = true
end

---@param parent tes3uiElement
function FightIndicator:createFatigueBar(parent)
    local label = parent:createLabel{
        text = "Усталость",
    }
    label.absolutePosAlignX = 0.5
    label.color = tes3ui.getPalette("header_color")

    --create block with auto width
    local border = parent:createThinBorder()
    border.widthProportional = 1
    border.autoWidth = false
    border.autoHeight = true

    local fatigueBar = border:createFillBar{
        id = self.uiids.fatigueBar,
        current = self.fightManager.fish.fatigue,
        max = self.fightManager.fish.fatigue,
    }
    fatigueBar.widthProportional = 1
    fatigueBar.height = 20

    if FishingNet.playerHasNet() then
        local netIcon = border:createImage{
            path = "textures\\mer_fishing\\neticon.dds",
        }
        netIcon.width = 18
        netIcon.height = 18
        netIcon.scaleMode = true
        netIcon.absolutePosAlignX = 0.075
    end
end

local simulateUpdate
function FightIndicator:updateMenu()
    local menu = self:getMenu()
    if not menu then
        event.unregister("simulate", simulateUpdate)
        return
     end
    --update tension indicator
    local tensionIndicator = menu:findChild(self.uiids.tensionIndicator)
    local tension = FishingStateManager.getTension() - config.constants.TENSION_MINIMUM
    local totalTension = config.constants.TENSION_MAXIMUM - config.constants.TENSION_MINIMUM
    local tensionProportion = tension / totalTension
    tensionIndicator.absolutePosAlignX = tensionProportion

    logger:trace("Indicator Tension: %s", tension)
    --update fatigue
    local fatigueBar = menu:findChild(self.uiids.fatigueBar)
    fatigueBar.widget.current = self.fightManager.fish.fatigue
end


function FightIndicator:createMenuBlock(menuMulti)
    local menu = menuMulti:createBlock{
        id = self.uiids.menu,
    }
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.03
    menu.autoWidth = true
    menu.autoHeight = true

    --create black background
    local background = menu:createRect{
        color = tes3vector3.new(0,0,0),
    }
    background.autoWidth = true
    background.autoHeight = true

    --Add border
    local border = background:createThinBorder{}
    border.width = self.width
    border.autoWidth = false
    border.autoHeight = true
    border.paddingAllSides = 10
    border.flowDirection = "top_to_bottom"
    return menu, border
end

function FightIndicator:createMenu()
    local menuMulti = tes3ui.findMenu("MenuMulti")
    if not menuMulti then
        logger:error("Could not find MenuMulti")
        return
    end
    local menu, border = self:createMenuBlock(menuMulti)
    self:createTensionBar(border)
    self:createFatigueBar(border)
    menu:updateLayout()
    simulateUpdate = function()
        self:updateMenu()
    end
    event.register("simulate", simulateUpdate)
end

function FightIndicator:destroy()
    logger:debug("Destroying FightIndicator")
    local menu = self:getMenu()
    if menu then

        menu:destroy()
    end
end

return FightIndicator