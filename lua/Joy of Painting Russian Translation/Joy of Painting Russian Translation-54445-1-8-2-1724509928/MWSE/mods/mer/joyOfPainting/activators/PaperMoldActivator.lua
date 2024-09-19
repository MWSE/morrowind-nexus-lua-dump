local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaperMoldActivator")
local Activator = require("mer.joyOfPainting.services.AnimatedActivator")
local PaperMold = require("mer.joyOfPainting.items.PaperMold")

local function activate(e)
    logger:debug("Activating paper mold")
    local paperMold = PaperMold:new{
        reference = e.target,
        item = e.item,
        itemData = e.itemData,
    }
    if paperMold == nil then
        logger:error("PaperMold is nil")
        return
    end

    tes3ui.showMessageMenu{
        message = paperMold.item.name,
        buttons = {
            {
                text = "Добавить бумажную массу.",
                callback = function()
                    paperMold:doAddPulp()
                end,
                enableRequirements = function()
                    return paperMold:playerHasPulp()
                        and (not paperMold:hasPulp())
                        and (not paperMold:hasPaper())
                end,
                tooltipDisabled = function()
                    if not paperMold:playerHasPulp() then
                        return { text = "У вас нет бумажной массы." }
                    end
                    if paperMold:hasPulp() then
                        return { text = "В этой форме уже есть масса." }
                    end
                end
            },
            {
                text = "Возьмите бумагу",
                callback = function()
                    paperMold:takePaper()
                end,
                enableRequirements = function()
                    return paperMold:hasPaper()
                end,
            },
            {
                text = "Убрать",
                callback = function()
                    common.pickUp(paperMold.reference)
                end,
                showRequirements = function()
                    if paperMold.reference then
                        return true
                    end
                    return false
                end
            }
        },
        cancels = true
    }
end

Activator.registerActivator{
    onActivate = activate,
    isActivatorItem = function(e)
        if e.target and tes3ui.menuMode() then
            logger:debug("Menu mode, skip")
            return false
        end
        --Only use when in world
        if not e.target then return end
        return PaperMold:new{
            reference = e.target,
            item = e.item,
            itemData = e.itemData,
        } ~= nil
    end
}