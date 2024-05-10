---@class ModConfig
local defaults = {
    suppressEnchantAudio = true,
    suppressEnchantVFX = true,
    suppressAlchemyAudio = false,
    suppressAlchemyVFX = false,
}

---@param modName string Name of the mod.
---@param config ModConfig
local function registerMCM(modName ,config)
    local template = mwse.mcm.createTemplate("Peace and Quiet")
    local page = template:createPage()
    page:createOnOffButton({
        label = "Suppress enchant audio",
        description = "Prevents sound effects from playing when constant effect items are equipped.",
        variable = mwse.mcm.createTableVariable({
            id = "suppressEnchantAudio",
            table = config
        })
    })

    page:createOnOffButton({
        label = "Suppress enchant VFX?",
        description = "Prevents visual effects from playing when constant effect items are equipped.",
        variable = mwse.mcm.createTableVariable({
            id = "suppressEnchantVFX",
            table = config
        })
    })

    page:createOnOffButton({
        label = "Suppress alchemy audio",
        description = "Prevents sound effects from playing when a potion is consumed.",
        variable = mwse.mcm.createTableVariable({
            id = "suppressAlchemyAudio",
            table = config
        })
    })

    page:createOnOffButton({
        label = "Suppress enchant VFX?",
        description = "Prevents visual effects from playing when a potion is consumed.",
        variable = mwse.mcm.createTableVariable({
            id = "suppressAlchemyVFX",
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
