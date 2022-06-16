local modInfo = require("AccurateTooltipStats.modInfo")
local config = require("AccurateTooltipStats.config")

local invMenuId = tes3ui.registerID("MenuInventory")
local invMenuArDisplay = tes3ui.registerID("MenuInventory_ArmorRating")

-- This is almost identical to the onEnterFrame function in main.lua, but only runs when the player turns *off* the
-- menuArPrecision setting, and forces the menu to display an integer. This is needed in case the player turns off the
-- setting while in menu mode, so it will change immediately.
local function onChangeMenuPrecision()
    if config.menuArPrecision then
        return
    end

    if not tes3.mobilePlayer then
        return
    end

    local menu = tes3ui.findMenu(invMenuId)

    if not menu then
        return
    end

    local arElem = menu:findChild(invMenuArDisplay)

    if not arElem then
        return
    end

    local ar = tes3.mobilePlayer.armorRating
    local text = string.format("Armor: %d", ar)

    if arElem.text == text then
        return
    end

    arElem.text = text
end

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod implements more accurate, context-dependent tooltip displays for weapon damage and armor ratings.\n" ..
            "\n" ..
            "In vanilla Morrowind, weapon tooltips will display the official damage values for each attack type (chop/slash/thrust) as listed in the Construction Set. However, the game also takes the player's strength and the weapon's condition into account in determining the actual damage done by the weapon. With this mod, the tooltip damage display will take these factors into account as well.\n" ..
            "\n" ..
            "For armor, in vanilla, the armor rating listed in the CS is modified by the player's relevant armor skill to determine the AR displayed in the tooltip, but the game also takes into account the armor's condition when determining the actual AR provided by the armor. With this mod, the tooltip AR display will also take condition into account.\n" ..
            "\n" ..
            "Each aspect of the mod can be enabled/disabled as you wish. Hover over each setting to learn more about it.",
    }

    local categoryWeapons = page:createCategory("Weapon Tooltips")

    categoryWeapons:createYesNoButton{
        label = "Consider strength",
        description =
            "If this setting is enabled, the damage display in weapon tooltips will take the player's strength into account, reflecting how the game considers strength in determining weapon damage.\n" ..
            "\n" ..
            "If this setting is disabled, player strength will not be considered when determining what to display in the tooltip, as in vanilla.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "weaponStrength",
            table = config,
        },
        defaultSetting = true,
    }

    categoryWeapons:createYesNoButton{
        label = "Consider condition",
        description =
            "If this setting is enabled, the damage display in weapon tooltips will take the weapon's condition into account, reflecting how the game considers condition in determining weapon damage.\n" ..
            "\n" ..
            "If this setting is disabled, a weapon's condition will not be considered when determining what to display in the tooltip, as in vanilla.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "weaponCondition",
            table = config,
        },
        defaultSetting = true,
    }

    categoryWeapons:createYesNoButton{
        label = "More precise damage display",
        description =
            "In vanilla, weapon tooltips will only display min/max damage as integers, even though they can be non-integer values. If this setting is enabled, weapon tooltips will show one digit past the decimal point when displaying weapon damage.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "weaponPrecision",
            table = config,
        },
        defaultSetting = false,
    }

    local categoryArmor = page:createCategory("Armor Tooltips")

    categoryArmor:createYesNoButton{
        label = "Consider skill",
        description =
            "If this setting is enabled, the AR display in armor tooltips will take the player's relevant armor skill into account, as in vanilla, reflecting how the game considers armor skill in determining AR.\n" ..
            "\n" ..
            "If this setting is disabled, player armor skill will not be considered when determining what to display in the tooltip.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "armorSkill",
            table = config,
        },
        defaultSetting = true,
    }

    categoryArmor:createYesNoButton{
        label = "Consider condition",
        description =
            "If this setting is enabled, the AR display in armor tooltips will take the armor's condition into account, reflecting how the game considers condition in determining AR.\n" ..
            "\n" ..
            "If this setting is disabled, an armor piece's condition will not be considered when determining what to display in the tooltip, as in vanilla.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "armorCondition",
            table = config,
        },
        defaultSetting = true,
    }

    categoryArmor:createYesNoButton{
        label = "More precise AR display",
        description =
            "In vanilla, armor tooltips will only display AR as an integer, even though it can be a non-integer value. If this setting is enabled, armor tooltips will show one digit past the decimal point when displaying AR.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "armorPrecision",
            table = config,
        },
        defaultSetting = false,
    }

    local categoryOther = page:createCategory("Other")

    categoryOther:createYesNoButton{
        label = "More precise AR display in inventory menu",
        description =
            "This setting affects the armor rating display below the character portrait in the inventory menu.\n" ..
            "\n" ..
            "In vanilla, this display will only show an integer value. If this setting is enabled, it will show one digit past the decimal point for greater precision.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "menuArPrecision",
            table = config,
        },
        defaultSetting = false,
        callback = onChangeMenuPrecision,
    }

    return page
end

local template = mwse.mcm.createTemplate("Accurate Tooltip Stats")
template:saveOnClose("AccurateTooltipStats", config)

createPage(template)

mwse.mcm.register(template)