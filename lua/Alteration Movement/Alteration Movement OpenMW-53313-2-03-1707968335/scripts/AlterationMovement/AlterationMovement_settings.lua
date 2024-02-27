local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local ambLoaded, ambient = pcall(require, 'openmw.ambient')
local configDefault = {
    toggleMode = false,
    magickaCost = 3,
    levelreq = 30,
    allowAirJump = true,
    airJumpCost = 10,
    airJumpMultiplier = 15,
    enableJumpVfx = true,
    enableSounds = true,
    enableJumpLimit = false,
    alterationPerJump = 30,
    requireKnown = false
}--Default settings, defined below
if not I.SkillProgression or not ambLoaded then
    I.Settings.registerPage {
        key = "AlterationMovement",
        l10n = "AlterationMovement",
        name = "Alteration Movement",
        description =
        "Your OpenMW version is too old to use Alteration Movement.\n\nMake sure to download the latest OpenMW Development version."
    }
    --Register the settings page for the mod to indicate to the user that they are running an outdated version of OpenMW
    return
elseif not core.contentFiles.has("lack_AlterationMovement.esp") and true == false then
    I.Settings.registerPage {
        key = "AlterationMovement",
        l10n = "AlterationMovement",
        name = "Alteration Movement",
        description = "Enable lack_AlterationMovement.esp to use Alteration Movement"
    }

    --Register the settings page for the mod to indicate to the user that they are lacking the ESP
    return
end
I.Settings.registerPage {
    key = "AlterationMovement",
    l10n = "AlterationMovement",
    name = "Alteration Movement",
    description = "Alteration Movement"
}--Create the page for alteration movement
I.Settings.registerGroup {
    key = "SettingsAlterationMovement",
    page = "AlterationMovement",
    l10n = "AlterationMovement",
    name = "Alteration Movement",
    description =
    "Alteration Movement\n\nby AlandroSul\n\nControls:\nJump while falling/jumping to levitate\nSneak while falling to slowfall\n\nNote that Air jumping is not currently supported in OpenMW.",
    permanentStorage = false,
    settings = {
        {
            key = "toggleMode",
            renderer = "checkbox",
            name = "Disable/Enable Toggle controls",
            description =
            "Enable to control by jump/sneak toggle rather than by holding the jump/sneak button down. Default: disabled",
            default = configDefault.toggleMode
        },
        {
            key = "enableSounds",
            renderer = "checkbox",
            name = "Disable/Enable Sounds",
            description =
            "Enable for alteration spell audio when using alteration movement abilities. Default: enabled",
            default = configDefault.enableSounds
        },
        {
            key = "requireKnown",
            renderer = "checkbox",
            name = "Require that the player learn the spells.",
            description =
            "In order to unlock intuitive magic you must cast a spell with the corresponding effect (levitate, slowfall and jump) at least once. Default: disabled",
            default = configDefault.requireKnown
        },
        {
            key = "allowWaterTakeoff",
            renderer = "checkbox",
            name = "Allow Water Takeoff",
            description =
            "Enable to allow you to start levitation while swimming. Default: disabled",
            default = false
        },
        {
            key = "magickaCost",
            renderer = "number",
            name = "Magicka Cost",
            description =
            "Magicka cost per second when levitating/slowfalling. Default: 3",
            default = configDefault.magickaCost,
            argument = {
                min = 1,
                integer = true,
                max = 100,
            },
        },
        {
            key = "levelreq",
            renderer = "number",
            name = "Alteration Level Req",
            description =
            "Alteration Level Requirement for intuitive magic. Default 30",
            default = configDefault.levelreq,
            argument = {
                min = 1,
                integer = true,
                max = 100,
            },
        },
    }
}
