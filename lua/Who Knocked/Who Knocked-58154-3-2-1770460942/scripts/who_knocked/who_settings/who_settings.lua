-- Who Knocked Settings Registration
-- Modular settings for interactive door system

local I = require('openmw.interfaces')

-- Register the Who Knocked settings page
I.Settings.registerPage {
    key = 'WhoKnocked',
    l10n = 'WhoKnocked',
    name = 'Who Knocked',
    description = 'Configure interactive door system options',
}

-- Register main system settings
I.Settings.registerGroup {
    key = 'SettingsWhoKnocked_Main',
    page = 'WhoKnocked',
    name = 'Main Settings',
    description = 'Core system configuration',
    l10n = 'WhoKnocked',
    permanentStorage = false,
    settings = {
        {
            key = 'enableWhoKnocked',
            name = 'Enable Who Knocked',
            description = 'Master toggle for the entire Who Knocked system',
            default = true,
            renderer = 'checkbox',
        },
    },
}

-- Register lockpick system settings
I.Settings.registerGroup {
    key = 'SettingsWhoKnocked_Lockpick',
    page = 'WhoKnocked',
    name = 'Lockpick System',
    description = 'Configure lockpicking and forced entry options',
    l10n = 'WhoKnocked',
    permanentStorage = false,
    settings = {
        {
            key = 'enableLockpickSystem',
            name = 'Enable Lockpick System',
            description = 'Enable Force, Pick, Magic, and Master lock options',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'skillDifficultyModifier',
            name = 'Skill Difficulty Modifier',
            description = 'Global multiplier for lockpick difficulty (0.5=easy, 2.0=hard)',
            default = 1.0,
            renderer = 'number',
            min = 0.5,
            max = 2.0,
        },
    },
}

-- Register dialogue system settings
I.Settings.registerGroup {
    key = 'SettingsWhoKnocked_Dialogue',
    page = 'WhoKnocked',
    name = 'Dialogue System',
    description = 'Configure dialogue-based door entry options',
    l10n = 'WhoKnocked',
    permanentStorage = false,
    settings = {
        {
            key = 'enableDialogueSystem',
            name = 'Enable Dialogue System',
            description = 'Enable Admire, Intimidate, and Bribe dialogue options',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'dialogueDifficultyModifier',
            name = 'Dialogue Difficulty Modifier',
            description = 'Global multiplier for dialogue difficulty (0.5=easy, 2.0=hard)',
            default = 1.0,
            renderer = 'number',
            min = 0.5,
            max = 2.0,
        },
    },
}

-- Register crime system settings
I.Settings.registerGroup {
    key = 'SettingsWhoKnocked_Crime',
    page = 'WhoKnocked',
    name = 'Crime System',
    description = 'Configure bounty and reputation penalties',
    l10n = 'WhoKnocked',
    permanentStorage = false,
    settings = {
        {
            key = 'enableCrimeSystem',
            name = 'Enable Crime System',
            description = 'Enable bounty and reputation penalties for failed attempts',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'bountyMultiplier',
            name = 'Bounty Multiplier',
            description = 'Multiplier for crime penalties (0.0=disabled, 2.0=double)',
            default = 1.0,
            renderer = 'number',
            min = 0.0,
            max = 2.0,
        },
    },
}

-- Register UI settings
I.Settings.registerGroup {
    key = 'SettingsWhoKnocked_UI',
    page = 'WhoKnocked',
    name = 'Interface',
    description = 'Configure user interface and message options',
    l10n = 'WhoKnocked',
    permanentStorage = false,
    settings = {
        {
            key = 'showSuccessMessages',
            name = 'Show Result Messages',
            description = 'Show success and failure messages for door attempts',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'messageDisplayTime',
            name = 'Message Display Time',
            description = 'How long messages remain on screen (seconds)',
            default = 3,
            renderer = 'number',
            min = 1,
            max = 10,
        },
    },
}

-- Return empty table (no direct exports)
return {}
