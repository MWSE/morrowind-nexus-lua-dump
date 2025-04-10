local I = require("openmw.interfaces")

I.Settings.registerPage {
    key = 'OpenMWQuestStatusMenuPage',
    l10n = 'OpenMWQuestStatusMenu',
    name = 'OpenMW Quest Status Menu',
    description = 'Settings for the quest status menu. For some of the options you need to reopen the quest status menu to see changes.',
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestStatusMenuControls',
    page = 'OpenMWQuestStatusMenuPage',
    l10n = 'OpenMWQuestStatusMenu',
    name = 'Controls',
    permanentStorage = true,
    settings = {
        {
            key = 'OpenMenu',
            renderer = 'textLine',
            name = 'Open Menu',
            description = 'Key to open menu.',
            default = 'x',
        },
    },
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestStatusMenuCustomization',
    page = 'OpenMWQuestStatusMenuPage',
    l10n = 'OpenMWQuestStatusMenu',
    name = 'Customization',
    permanentStorage = true,
    settings = {
        {
            key = 'IconSizeList',
            renderer = 'number',
            name = 'List Quest Icon Size',
            description = 'Sets the size of the quest icons within the list.',
            default = 20,
        },
        {
            key = 'IconSize',
            renderer = 'number',
            name = 'Details Quest Icon Size',
            description = 'Sets the size of the quest icon within the details view.',
            default = 30,
        },
        {
            key = 'HeadlineSize',
            renderer = 'number',
            name = 'Quest Name Size',
            description = 'Sets the size of the Quest names.',
            default = 14,
        },
        {
            key = 'TextSize',
            renderer = 'number',
            name = 'Text Size',
            description = 'Sets the size of the Quest description and "back" button.',
            default = 12,
        },
        {
            key = 'ButtonSize',
            renderer = 'number',
            name = 'Button Size',
            description = 'Sets the size of the buttons.',
            default = 12,
        },
    },
}

return
