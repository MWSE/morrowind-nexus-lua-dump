local config = require("EnchantmentImproved.config")

-- blocklistToggle, alwaysLog, showInGame, blocklist

local function createMainSettingsPage(template)

    local page = template:createSideBarPage({
        label = "General Settings",
        description = "Enchantment Improved v1.0\nby C89C\n\nThis mod will allow non mages to enchant items using the spells that the enchanter knows in addition to any the player knows.\nThis means non-mages no longer need to learn spells to enchant items, though they might not have access to all enchantment effects."
    })

    page:createOnOffButton({
        label = "Calculate Enchantment Price?",
        description = "If enabled, We'll calculate the enchantment price using my formula. See the readme for more information about that.",
        variable = mwse.mcm.createTableVariable{
            id = "priceEnchantments",
            table = config
        }
    })

end

local template = mwse.mcm.createTemplate("EnchantmentImproved")
template:saveOnClose("EnchantmentImproved", config)

createMainSettingsPage(template)

mwse.mcm.register(template)