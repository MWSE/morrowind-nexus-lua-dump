local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')

local version = '1.2'

I.Settings.registerRenderer('SaneMagic/inputKeySelection', function(value, set)
    local name = 'No Key Set'
    if value then
        name = input.getKeyName(value)
    end
    return {
        template = I.MWUI.templates.box,
        content = ui.content {{
            template = I.MWUI.templates.padding,
            content = ui.content {{
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = name
                },
                events = {
                    keyPress = async:callback(function(e)
                        if e.code == input.KEY.Escape then
                            return
                        end
                        set(e.code)
                    end)
                }
            }}
        }}
    }
end)

I.Settings.registerPage {
    key = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'SaneMagic',
    description = "settings_description"
}

I.Settings.registerGroup {
    key = 'SettingsPlayerSaneMagic01_General',
    page = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'smGeneralName',
    description = '',
    permanentStorage = true,
    settings = {{
	    key = 'smSaneMagicCap',
        name = 'smSaneMagicCapName',
        description = 'smSaneMagicCapDesc',
        default = "Lax",
        argument = {
            l10n = 'SaneMagic',
            items = {"OnlySpells", "Strict", "Lax", "Disabled"}
        },
        renderer = 'select'
    }, {
        key = 'sm100Unlimit',
        name = 'sm100UnlimitName',
        description = 'sm100UnlimitDesc',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'smSpellFatigue',
        name = 'smSpellFatigueName',
        description = 'smSpellFatigueDesc',
        default = "Clumsy",
        argument = {
            l10n = 'SaneMagic',
            items = {"Destro", "Clumsy", "Disabled"}
        },
        renderer = 'select'
    }, {
        key = 'smSpellFatMult',
        name = 'smSpellFatMultName',
        default = 0.8,
        argument = {
            max = 2,
            min = 0.5
        },
        renderer = 'number'
    }, {
        key = 'smTypeMerger',
        name = 'smTypeMergerName',
        description = 'smTypeMergerDesc',
        default = false,
        renderer = 'checkbox'
    }}
}

I.Settings.registerGroup {
    key = 'SettingsPlayerSaneMagic02_Crime',
    page = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'smCrimeName',
    description = '',
    permanentStorage = true,
    settings = {{
        key = 'smSuspiciousEffect',
        name = 'smSuspiciousEffectName',
        description = 'smSuspiciousEffectDesc',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'smSummon',
        name = 'smSummonName',
        description = 'smSummonDesc',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'smFrenzyCrime',
        name = 'smFrenzyCrimeName',
        description = 'smFrenzyCrimeDesc',
        default = true,
        renderer = 'checkbox'
    }}
}

I.Settings.registerGroup {
    key = 'SettingsPlayerSaneMagic03_Social',
    page = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'smSocialName',
    description = '',
    permanentStorage = true,
    settings = {{
        key = 'smCharm',
        name = 'smCharmName',
        description = 'smCharmDesc',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'smCharmSneakLimit',
        name = 'smCharmSneakLimitName',
        description = 'smCharmSneakLimitDesc',
        default = 25,
        argument = {
           max = 75,
           min = 15,
        },
        renderer = 'number'
     }, {
        key = 'smFortifyPerson',
        name = 'smFortifyPersonName',
        description = 'smFortifyPersonDesc',
        default = true,
        renderer = 'checkbox'
    }}
}

I.Settings.registerGroup {
    key = 'SettingsPlayerSaneMagic04_Summons',
    page = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'smSummonsName',
    description = '',
    permanentStorage = true,
    settings = {{
        key = 'smNecromancy',
        name = 'smNecromancyName',
        description = 'smNecromancyDesc',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'smConjurationMode',
        name = 'smConjurationModeName',
        description = 'smConjurationModeDesc',
        default = "Both",
        argument = {
            l10n = 'SaneMagic',
            items = {"SummonBreach", "DamageShare", "Both", "Disabled"}
        },
        renderer = 'select'
    }, {
        key = 'smConjurationDamageType',
        name = 'smConjurationDamageTypeName',
        description = 'smConjurationDamageTypeDesc',
        default = "Health",
        argument = {
            l10n = 'SaneMagic',
            items = {"Health", "Fatigue", "Magicka"}
        },
        renderer = 'select'
    }, {
        key = 'smConjurationDamage',
        name = 'smConjurationDamageName',
        default = 0.6,
        argument = {
            max = 2,
            min = 0.1
        },
        renderer = 'number'      
    }, {
        key = 'smConjurationOnlyPlayerDamage',
        name = 'smConjurationOnlyPlayerDamageName',
        description = '',
        default = false,
        renderer = 'checkbox'
    }}
}

I.Settings.registerGroup {
    key = 'SettingsPlayerSaneMagic05_Other',
    page = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'smOtherName',
    description = '',
    permanentStorage = true,
    settings = {{
        key = 'smAbsorb',
        name = 'smAbsorbName',
        description = 'smAbsorbDesc',
        default = false,
        renderer = 'checkbox'
    }, {
        key = 'smLevitate',
        name = 'smLevitateName',
        description = 'smLevitateDesc',
        default = false,
        renderer = 'checkbox'
    }, {
        key = 'smMark',
        name = 'smMarkName',
        description = 'smMarkDesc',
        default = false,
        renderer = 'checkbox'
    },{
        key = 'smMarkTimeout',
        name = 'smMarkTimeoutName',
        default = 12,
        argument = {
            max = 24,
            min = 1
        },
        renderer = 'number'
    }, {
        key = 'smOpen',
        name = 'smOpenName',
        description = 'smOpenDesc',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'smSlowfallFix',
        name = 'smSlowfallFixName',
        description = 'smSlowfallFixDesc',
        default = false,
        renderer = 'checkbox'
    }, {
        key = 'smSpeedFallKey',
        name = 'smSpeedFallKeyName',
        default = input.KEY.Space,
        renderer = 'SaneMagic/inputKeySelection'
    }, {
        key = 'smSpeedFallCost',
        name = 'smSpeedFallCostName',
        default = 20,
        argument = {
            max = 100,
            min = 0
        },
        renderer = 'number'
    }}
}

I.Settings.registerGroup {
    key = 'SettingsPlayerSaneMagic06_Compatible',
    page = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'smCompatibleName',
    description = '',
    permanentStorage = true,
    settings = {{
        key = 'smQuickKeyCompatible',
        name = 'smQuickKeyCompatibleName',
        description = 'smQuickKeyCompatibleDesc',
        default = "None",

        argument = {
            l10n = 'SaneMagic',
            items = {"None", "ZerkishHotbar", "QuickCast"}
        },
        renderer = 'select'

    }, }
}
