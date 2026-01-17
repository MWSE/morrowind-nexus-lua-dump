local core = require 'openmw.core'
local time = require 'openmw_aux.time'
local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local ModInfo = require('scripts.sw4.modinfo')
local I = require('openmw.interfaces')

local revision = core.API_REVISION
local RequiredRevision = 71

assert(revision >= RequiredRevision,
    string.format("This mod requires OpenMW version %s or higher. Current version: %s",
        RequiredRevision, revision))

I.Settings.registerPage {
    key = ModInfo.name .. 'CorePage',
    l10n = ModInfo.l10nName,
    name = "SWAMP - Starwind Modernization",
    description = "Wot are ye doing in mah SWAMP?\nRequires OpenMW 0.49."
}

I.Settings.registerPage {
    key = ModInfo.name .. 'BlasterPage',
    l10n = ModInfo.l10nName,
    name = "SWAMP - Blaster Settings",
    description = "Settings related to blaster damage and automatic firing. Speed multipliers scale based on your Marksman skill, with the full multiplier value being used at >= 100 Marksman.\nRequires OpenMW 0.49."
}

I.Settings.registerPage {
    key = ModInfo.name .. 'CameraMovementPage',
    l10n = ModInfo.l10nName,
    name = "SWAMP - Camera and Movement",
    description = "Settings related to KOTOR-style controls and extended camera behaviors."
}

I.Settings.registerPage {
    key = ModInfo.name .. 'CursorPage',
    l10n = ModInfo.l10nName,
    name = 'SWAMP - Cursor Settings',
    description = 'Settings for the custom cursor implemented by StarwindV4'
}

I.Settings.registerPage {
    key = ModInfo.name .. 'QuickActionsPage',
    l10n = ModInfo.l10nName,
    name = 'SWAMP - Quick Actions',
    description = 'Settings related to quick attacks and casting.'
}

print(string.format("%s loaded version %s. Thank you for playing %s! <3",
    ModInfo.logPrefix,
    ModInfo.version,
    ModInfo.name))
