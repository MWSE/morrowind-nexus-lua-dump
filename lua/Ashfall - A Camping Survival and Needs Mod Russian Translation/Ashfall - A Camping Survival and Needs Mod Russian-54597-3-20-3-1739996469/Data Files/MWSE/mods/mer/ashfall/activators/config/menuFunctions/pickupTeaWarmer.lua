local common = require ("mer.ashfall.common.common")

return {
    text = "Убрать",
    tooltip = function()
        return common.helper.showHint(string.format(
            "Вы можете взять его напрямую, активировав, удерживая %s.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(reference)
        timer.delayOneFrame(function()
            common.helper.pickUp(reference)
        end)
    end
}