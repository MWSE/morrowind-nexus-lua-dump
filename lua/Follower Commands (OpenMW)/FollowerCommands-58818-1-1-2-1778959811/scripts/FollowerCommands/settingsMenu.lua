local I = require('openmw.interfaces')
local input = require("openmw.input")

local consts = require("scripts.FollowerCommands.utils.consts")

input.registerTrigger {
    key = consts.commandTriggerKey,
    l10n = "FollowerCommands",
    name = "giveCommand_name",
    description = "giveCommand_desc",
}

I.Settings.registerPage {
    key = 'FollowerCommands',
    l10n = 'FollowerCommands',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsFollowerCommands_settings',
    page = 'FollowerCommands',
    l10n = 'FollowerCommands',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'commandHotkey',
            name = 'hotkey_name',
            description = 'hotkey_desc',
            renderer = 'inputBinding',
            default = 'c',
            argument = {
                type = 'trigger',
                key = consts.commandTriggerKey
            },
        },
        {
            key = 'maxDistance',
            name = 'maxDistance_name',
            description = "maxDistance_desc",
            renderer = 'number',
            default = 5000,
        },
        {
            key = 'animationVariant',
            name = 'animationVariant_name',
            renderer = 'select',
            default = "kcommand_random",
            argument = {
                l10n = "FollowerCommands",
                items = {
                    "kcommand01",
                    "kcommand02",
                    "kcommand03",
                    "kcommand04",
                    "kcommand_random",
                },
            },
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsFollowerCommands_commands',
    page = 'FollowerCommands',
    l10n = 'FollowerCommands',
    name = 'commands_groupName',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'unlockOwned',
            name = 'unlockOwned_name',
            description = "unlockOwned_desc",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'lootOwned',
            name = 'lootOwned_name',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'minUnlockChance',
            name = 'minUnlockChance_name',
            description = "minUnlockChance_desc",
            renderer = 'number',
            default = 10,
            min = 0,
            max = 100,
        },
        {
            key = 'kamikazeUntrapMinHealth',
            name = 'kamikazeUntrapMinHealth_name',
            description = "kamikazeUntrapMinHealth_desc",
            renderer = 'number',
            default = 50,
        },
        {
            key = 'kamikazeUntrapRefuseChance',
            name = 'kamikazeUntrapRefuseChance_name',
            renderer = 'number',
            default = 25,
        },
    }
}
