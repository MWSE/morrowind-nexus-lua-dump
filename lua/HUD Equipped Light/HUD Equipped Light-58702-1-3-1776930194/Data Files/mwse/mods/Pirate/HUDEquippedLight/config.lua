local config = {}
config.modVersion = "1.3"
config.configPath = "HUDEquippedLight"
config.BorderSize = 2
config.mcmDefault = {
    sephIntegration = true,
    SlotLightVisible = true,
    EmptySlotVisible = true,
    SlotPositionX = 13,
    SlotPositionY = 98,
    EquippedLightVisible = true,
    EquippedShieldVisible = true,
    SlotIconSize = 32,
    }
config.mcm = mwse.loadConfig(config.configPath, config.mcmDefault)
return config