local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("removeSupports")
return {
    text = "Убрать опоры",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return (
            reference.sceneNode:getObjectByName("ATTACH_SUPPORTS")
            and reference.data.supportsId
            and reference.data.dynamicConfig
            and reference.data.dynamicConfig.supports == "dynamic"
        )
    end,
    enableRequirements = function(reference)
        return reference.data.utensil == nil
    end,
    tooltipDisabled = {
        text = "Сначала необходимо снять посуду."
    },
    tooltip = function()
        return common.helper.showHint(string.format(
            "Вы можете взять предмет напрямую, активировав, удерживая %s.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(reference)
        local supports = reference.data.supportsId
        local data = common.staticConfigs.supports[supports:lower()]

        logger:debug("Removing supports %s", supports)
        if data.materials then
            for id, count in pairs(data.materials ) do
                tes3.addItem{
                    reference = tes3.player,
                    item = id, count = count,
                    playSound = false,
                    showMessage = true,
                }
            end
        else
            tes3.addItem{
                reference = tes3.player,
                item = reference.data.supportsId,
                count = 1,
                playSound = false,
                showMessage = true,
            }
        end
        reference.data.supportsId = nil
        common.helper.playDeconstructionSound()
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end
}