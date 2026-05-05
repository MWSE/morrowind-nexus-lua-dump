local config = require("sanekEnchant.config")

local this = {}

this.VANILLA = {
    enchantChanceMult = 3.0,
    constantChanceMult = 0.5,
    constantDurationMult = 100.0,
    enchantMult = 0.1,
    enchantValueMult = 1000.0,
}

this.DEFAULTS = {
    enchantChanceMult = 0.5,
    constantChanceMult = 0.5,
    constantDurationMult = 100.0,
    enchantMult = 0.1,
    enchantValueMult = 1000.0,
}

function this.applyGMST()
    tes3.findGMST(tes3.gmst.fEnchantmentChanceMult).value = config.enchantChanceMult
    tes3.findGMST(tes3.gmst.fEnchantmentConstantChanceMult).value = config.constantChanceMult
    tes3.findGMST(tes3.gmst.fEnchantmentConstantDurationMult).value = config.constantDurationMult
    tes3.findGMST(tes3.gmst.fEnchantmentMult).value = config.enchantMult
    tes3.findGMST(tes3.gmst.fEnchantmentValueMult).value = config.enchantValueMult
end

function this.restoreVanilla()
    for k, v in pairs(this.VANILLA) do
        config[k] = v
    end
    mwse.saveConfig("sanekEnchant", config)
    this.applyGMST()
end

function this.restoreDefaults()
    for k, v in pairs(this.DEFAULTS) do
        config[k] = v
    end
    mwse.saveConfig("sanekEnchant", config)
    this.applyGMST()
end

return this