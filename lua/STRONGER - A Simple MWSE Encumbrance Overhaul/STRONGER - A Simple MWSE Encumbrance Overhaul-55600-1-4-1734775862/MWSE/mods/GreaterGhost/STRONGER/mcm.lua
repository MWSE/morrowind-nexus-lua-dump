local config = require("GreaterGhost.STRONGER.config")

local version = "1.4"

local mod_desc = (
    "This mod multiples your PC's and all NPCs' maximum encumbrance by a value, 20 by default. "..
    "It also multiplies the effects of the Feather and Burden spell-effects by the same value. "..
    "By default, this means that for every magnitude point in a Feather effect, 20 times that amount will be removed from your weight. "..
    "And similarly, 20 times the magnitude of a Burden effect is how much will be added by it.\n\n"..
    "The multiplier value can be set to any value between 1 and 100, "..
    "resulting in a maximum encumbrance between x5 your character's strength (equivalent to vanilla Morrowind), and x500 your character's strength. "..
    "The value can be changed whenever desired, but requires you to restart your game to take full effect.\n\n"..
    "You can also disable the changes to Feather and Burden individually, restoring them to their vanilla behavior, "..
    "but you will need to forget all custom spells and delete all custom enchanted items with Feather or Burden effects, as they will not be effected by the changes. "..
    "Both settings are enabled by default."
)

local function enable_button_desc(effect)
    return (
        "Enable Stronger ".. effect .."\n\n"..
        "If enabled, any ".. effect .. " effects will be multiplied by the above value. "..
        "Forget any custom spells and delete any custom enchanted items with a Feather effect before changing this value."..
        "Then, restart your game for it to take effect.\n\n"..
        "Enabled by default."
    )
end


-- When the mod config menu is ready to start accepting registrations,
-- register this mod.
local function registerModConfig()
    -- Create the top level component Template.
    -- This is basically a box that holds all the other parts of the menu.
    local template = mwse.mcm.createTemplate({
        -- This will be displayed in the mod list on the lefthand pane.
        name = "STRONGER",
        description = (
            "STRONGER - A Simple MWSE Encumbrance Overhaul\n\n"..
            "By GreaterGhost\n\n"..
            "Version ".. version .."\n\n"..
            mod_desc
        ),
    })

    -- Saves the config to a file whenever the menu is closed.
    template:saveOnClose("GreaterGhost\\STRONGER", config)

    -- Create a simple container Page under Template.
    local page = template:createSideBarPage({ label = "Settings" })

    page.sidebar:createHyperlink({
        text = "STRONGER - A Simple MWSE Encumbrance Overhaul",
        url = "https://www.nexusmods.com/morrowind/mods/55600"
    })

    page.sidebar:createHyperlink({
        text = "By GreaterGhost",
        url = "https://next.nexusmods.com/profile/GreaterGhost"
    })

    page.sidebar:createInfo({text = (
        "Version ".. version .."\n\n"..
        mod_desc..
        "\n\nRequirements"
    )})

    page.sidebar:createHyperlink({
        text = "Morrowind Script Extender (MWSE)",
        url = "https://www.nexusmods.com/morrowind/mods/45468"
    })

    page.sidebar:createHyperlink({
        text = "Magicka Expanded",
        url = "https://www.nexusmods.com/morrowind/mods/47111"
    })

    page.sidebar:createInfo({text = (
        "\nCredit\n"..
        "Based on the MWSE-Lua code from:"
    )})

    page.sidebar:createHyperlink({
        text = "OperatorJacks's \"MM - Enhanced Light\"",
        url = "https://www.nexusmods.com/morrowind/mods/47672"
    })

    page.sidebar:createInfo({text = (
        "\nUnistallation\n"..
        "Simply uncheck the mod in your mod manager. "..
        "If uninstalling mid-playthrough, it is vital that you first forget all custom spells and delete all custom enchantments with Feather or Burden effects on them. "..
        "If you installed the mod manually, then you can delete the folder \"Data Files\\MWSE\\mods\\GreaterGhost\\STRONGER\" to remove the mod."
    )})

    -- Encumbrance Multiplier Value Slider
    page:createSlider({
        label = "Encumbrance Multiplier Value",
        description = (
            "Encumbrance Multiplier Value\n\n"..
            "The number by which all encumbrance values will be multiplied. "..
            "Feather and Burden effects will also be multiplied if their respective settings are on. "..
            "Restart your game after changing this setting for it to take effect.\n\n"..
            "Set to 20 by default."
        ),
        min = 1,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable({id = "multiplier", table = config}),
    })

    -- Enable Stronger Feather Button
    page:createYesNoButton({
        label = "Enable Stronger Feather",
        description = enable_button_desc("Feather"),
        variable = mwse.mcm.createTableVariable({id = "stronger_feather", table = config}),
    })

    -- Enable Stronger Burden Button
    page:createYesNoButton({
        label = "Enable Stronger Burden",
        description = enable_button_desc("Burden"),
        variable = mwse.mcm.createTableVariable({id = "stronger_burden", table = config}),
    })

    template:register()

end
event.register(tes3.event.modConfigReady, registerModConfig)