local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require('openmw.async')
local core = require('openmw.core')

if I.Settings and I.Settings.registerPage then
    pcall(function()
        I.Settings.registerPage({
            key         = 'ReanimateSpellPage',
            l10n        = 'ReanimateSpell',
            name        = "Loafy's Reanimate v1.1",
            description = "Settings for loafy's reanimate spell"
        })
    end)

    pcall(function()
        I.Settings.registerGroup({
            key              = 'SettingsReanimateSpellGeneral',
            page             = 'ReanimateSpellPage',
            l10n             = 'ReanimateSpell',
            name             = 'General',
            permanentStorage = true,
            order            = 1,
            settings         = {
                {
                    key         = 'MasteryMode',
                    name        = 'Require Mastery',
                    description = 'Disabling this makes it so that the player does not require a conjuration of 100 or greater to keep corpses from being destroyed.',
                    renderer    = 'checkbox',
                    default     = true
                },
                {
                    key         = 'masteryUiBox',
                    name        = 'Conjuration Mastery notice',
                    description = "Enables/Disables the Conjuration mastery popup",
                    renderer    = 'checkbox',
                    default     = true
                },
                {
                    key         = 'CastingUiBox',
                    name        = 'Casting Notices',
                    description = "Enables/Disables the popups you get when you successfully raise a zombie.",
                    renderer    = 'checkbox',
                    default     = true
                },
                 {
                    key         = 'CrimeMode',
                    name        = 'Illegal Necromancy',
                    description = "Enable/disable this if you want necromancy to be illegal",
                    renderer    = 'checkbox',
                    default     = true
                },
                 {
                    key         = 'expulsionMode',
                    name        = 'Faction Expulsion',
                    description = "Enables/Disables faction expulsion, off by default if Illegal Necromancy is turned off",
                    renderer    = 'checkbox',
                    default     = true
                 },
                   {
                    key         = 'automatonMode',
                    name        = 'Summoning Automatons',
                    description = "Enables/Disables automatons to be reanimated, off by default(Yes this counts the imperfect too.)",
                    renderer    = 'checkbox',
                    default     = false
                 },
                  {
                    key         = 'witnessDistanceModeNormal',
                    name        = 'Witness Distance',
                    description = "Sets the max distance at which a witness will be able to notice the player being a filthy necromancer. Minimum of 100 to keep the detection from breaking.",
                    renderer    = 'number',
                    default     = 1200,
                    min         = 100,
                  },
                  {
                    key         = 'witnessDistanceModeSneak',
                    name        = 'Witness Distance',
                    description = "Sets the max distance at which a witness will be able to notice the player being a filthy necromancer while sneaking. Minimum of 100 to keep the detection from breaking.",
                    renderer    = 'number',
                    default     = 1200,
                    min         = 100,
                }
            }
        })
    end)

    

end

print("ReanimationSpell settings script loaded")

return {}
