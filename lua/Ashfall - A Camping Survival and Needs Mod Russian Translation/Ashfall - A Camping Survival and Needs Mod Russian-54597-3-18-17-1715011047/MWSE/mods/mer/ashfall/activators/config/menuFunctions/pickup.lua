local common = require ("mer.ashfall.common.common")

return {
    text = "Убрать",
    showRequirements = function(reference)

        if not reference.supportsLuaData then return false end
        return reference.data.utensilId == nil
            and common.staticConfigs.bottleList[reference.object.id:lower()] ~= nil
    end,
    tooltip = function()
        return common.helper.showHint(string.format(
            "Вы можете взять предмет напрямую, активировав его, удерживая %s.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(reference)
        local safeRef = tes3.makeSafeObjectHandle(reference)
        timer.delayOneFrame(function()
            if safeRef and safeRef:valid() then
                common.helper.pickUp(reference, true)
            end
        end)
    end
}