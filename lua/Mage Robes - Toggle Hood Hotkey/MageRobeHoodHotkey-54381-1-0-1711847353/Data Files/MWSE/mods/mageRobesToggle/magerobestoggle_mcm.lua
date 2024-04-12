---@class ModConfig
---@field suppressPickupScript boolean 
---@field suppressEffects boolean 
---@field keybind mwseKeyCombo
local defaults = {
    suppressPickupScript = true,
    suppressEffects = true,
    keybind = {
        ---@type tes3.scanCode
        keyCode = tes3.scanCode["backslash"],
        isAltDown = false,
        isShiftDown = false,
        isSuperDown = false,
        isControlDown = false
    }
}

local function registerMCM(modName ,config)
    local template = mwse.mcm.createTemplate("Mage Robes Hood Toggle")
    local page = template:createPage()
    page:createOnOffButton({
        label = "Disable pickup script?",
        description = "If enabled this will suppress the hood selection popup when you pick robes up from the ground.",
        variable = mwse.mcm.createTableVariable({
            id = "suppressPickupScript",
            table = config
        })
    })

    page:createOnOffButton({
        label = "Suppress equip effects?",
        description = "If enabled this will suppress sound and visual FX when using the hotkey.",
        variable = mwse.mcm.createTableVariable({
            id = "suppressEffects",
            table = config
        })
    })

    page:createKeyBinder({
        label = "Hood toggle hotkey",
        description = "Key to toggle between hooded and hoodless variant of robes.",
        variable = mwse.mcm.createTableVariable({
            id = "keybind",
            table = config
        })
    })

    template:register()
    template:saveOnClose(modName, config)
end

return {
    registerMCM = registerMCM,
    defaults = defaults
}
