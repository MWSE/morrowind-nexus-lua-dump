-- Abandon all hope, ye who enter here

local I = require('openmw.interfaces')
local input = require('openmw.input')

-- =====================
-- SETTINGS PAGE
-- =====================

I.Settings.registerPage {
    key = 'QuickUnequip',
    l10n = 'QuickUnequip_Settings',
    name = 'Devilish Dress Undress Hotkey',
    description = 'page_description',
}

-- =====================
-- HOTKEY
-- =====================

I.Settings.registerGroup {
    key = 'QuickUnequip_Hotkey',
    page = 'QuickUnequip',
    l10n = 'QuickUnequip_Settings',
    name = 'Hotkey',
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'unequipHotkey',
            renderer = 'inputBinding',
            name = 'Choose hotkey',
            description = 'Click and press a key',
            default = 'u',
            argument = {
                type = 'trigger',
                key = 'QuickUnequipTrigger',
            },
        },
    }
}

-- =====================
-- OPTIONAL BEHAVIOR
-- =====================

I.Settings.registerGroup {
    key = 'unequipwhenwetkey',
    page = 'QuickUnequip',
    l10n = 'QuickUnequip_Settings',
    name = 'Behaviour',
    order = 100,
    permanentStorage = true,
    settings = {
        {
            key = 'unequipwhenwetkey2',
            renderer = 'checkbox',
            name = 'Undress when swimming',
            default = false,
        },
    }
}

-- =====================
-- INPUT TRIGGER
-- =====================

input.registerTrigger {
    key = 'QuickUnequipTrigger',
    name = 'Quick Unequip',
    l10n = 'QuickUnequip_Settings',
}
