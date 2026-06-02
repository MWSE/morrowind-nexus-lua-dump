local I = require('openmw.interfaces')
local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')
local config = require('scripts.WeaponPoisoning.config')

local l10nContext = 'WeaponPoisoning'
local l10n = core.l10n(l10nContext)

I.Settings.registerRenderer('WeaponPoisoning/keyBinding', function(value, set)
    local name = type(value) == 'number' and input.getKeyName(value) or l10n('NoKeySet')
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = name,
                        },
                        events = {
                            keyPress = async:callback(function(e)
                                if e.code == input.KEY.Escape then
                                    return
                                end
                                set(e.code)
                            end),
                        },
                    },
                },
            },
        },
    }
end)

I.Settings.registerPage {
    key = 'WeaponPoisoning',
    l10n = l10nContext,
    name = l10n('SettingsPageName'),
    description = l10n('SettingsPageDescription', { version = config.VERSION }),
}

I.Settings.registerGroup {
    key = 'Settings/WeaponPoisoning/1_Gameplay',
    page = 'WeaponPoisoning',
    l10n = l10nContext,
    name = l10n('GameplayGroupName'),
    description = l10n('GameplayGroupDescription'),
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = 'EnableMod',
            renderer = 'checkbox',
            name = l10n('EnableModName'),
            description = l10n('EnableModDescription'),
            default = true,
        },
        {
            key = 'AutoReapplyPoison',
            renderer = 'checkbox',
            name = l10n('AutoReapplyPoisonName'),
            description = l10n('AutoReapplyPoisonDescription'),
            default = false,
        },
        {
            key = 'StackPoisonsOnTarget',
            renderer = 'checkbox',
            name = l10n('StackPoisonsOnTargetName'),
            description = l10n('StackPoisonsOnTargetDescription'),
            default = false,
        },
        {
            key = 'ProtectStrongerPoison',
            renderer = 'checkbox',
            name = l10n('ProtectStrongerPoisonName'),
            description = l10n('ProtectStrongerPoisonDescription'),
            default = true,
        },
        {
            key = 'ShowMessages',
            renderer = 'checkbox',
            name = l10n('ShowMessagesName'),
            description = l10n('ShowMessagesDescription'),
            default = true,
        },
        {
            key = 'AlchemyProgressGain',
            renderer = 'number',
            name = l10n('AlchemyProgressGainName'),
            description = l10n('AlchemyProgressGainDescription'),
            default = 0.1,
            argument = { min = 0, max = 1 },
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/WeaponPoisoning/2_Keybinds',
    page = 'WeaponPoisoning',
    l10n = l10nContext,
    name = l10n('KeybindsGroupName'),
    description = l10n('KeybindsGroupDescription'),
    permanentStorage = true,
    order = 20,
    settings = {
        {
            key = 'SuppressPoisonApplicationKey',
            renderer = 'WeaponPoisoning/keyBinding',
            name = l10n('SuppressPoisonApplicationBindingName'),
            description = l10n('SuppressPoisonApplicationBindingDescription'),
            default = input.KEY.RightCtrl,
        },
        {
            key = 'ForcePoisonApplicationKey',
            renderer = 'WeaponPoisoning/keyBinding',
            name = l10n('ForcePoisonApplicationBindingName'),
            description = l10n('ForcePoisonApplicationBindingDescription'),
            default = input.KEY.RightAlt,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/WeaponPoisoning/3_NPC',
    page = 'WeaponPoisoning',
    l10n = l10nContext,
    name = l10n('NpcGroupName'),
    description = l10n('NpcGroupDescription'),
    permanentStorage = true,
    order = 30,
    settings = {
        {
            key = 'EnableNpcPoisoning',
            renderer = 'checkbox',
            name = l10n('EnableNpcPoisoningName'),
            description = l10n('EnableNpcPoisoningDescription'),
            default = true,
        },
        {
            key = 'NpcPoisonReapplyCooldownSeconds',
            renderer = 'number',
            name = l10n('NpcPoisonReapplyCooldownSecondsName'),
            description = l10n('NpcPoisonReapplyCooldownSecondsDescription'),
            default = 10,
            argument = { min = 0, max = 60 },
        },
        {
            key = 'NpcGeneratedPoisonMaxCount',
            renderer = 'number',
            name = l10n('NpcGeneratedPoisonMaxCountName'),
            description = l10n('NpcGeneratedPoisonMaxCountDescription'),
            default = 3,
            argument = { min = 1, max = 10 },
        },
        {
            key = 'EnableNpcPoisonAnimation',
            renderer = 'checkbox',
            name = l10n('EnableNpcPoisonAnimationName'),
            description = l10n('EnableNpcPoisonAnimationDescription'),
            default = true,
        },
        {
            key = 'EnableNpcDebugLogging',
            renderer = 'checkbox',
            name = l10n('EnableNpcDebugLoggingName'),
            description = l10n('EnableNpcDebugLoggingDescription'),
            default = false,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/WeaponPoisoning/5_VFX',
    page = 'WeaponPoisoning',
    l10n = l10nContext,
    name = l10n('VfxGroupName'),
    description = l10n('VfxGroupDescription'),
    permanentStorage = true,
    order = 50,
    settings = {
        {
            key = 'EnablePoisonHitVfx',
            renderer = 'checkbox',
            name = l10n('EnablePoisonHitVfxName'),
            description = l10n('EnablePoisonHitVfxDescription'),
            default = true,
        },
        {
            key = 'EnablePoisonHitSound',
            renderer = 'checkbox',
            name = l10n('EnablePoisonHitSoundName'),
            description = l10n('EnablePoisonHitSoundDescription'),
            default = true,
        },
        {
            key = 'ShowPoisonVfxForFullDuration',
            renderer = 'checkbox',
            name = l10n('ShowPoisonVfxForFullDurationName'),
            description = l10n('ShowPoisonVfxForFullDurationDescription'),
            default = true,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/WeaponPoisoning/4_Integrations',
    page = 'WeaponPoisoning',
    l10n = l10nContext,
    name = l10n('IntegrationsGroupName'),
    description = l10n('IntegrationsGroupDescription'),
    permanentStorage = true,
    order = 40,
    settings = {
        {
            key = 'EnableInventoryExtenderIntegration',
            renderer = 'checkbox',
            name = l10n('EnableInventoryExtenderIntegrationName'),
            description = l10n('EnableInventoryExtenderIntegrationDescription'),
            default = true,
        },
        {
            key = 'EnableNpcPotionsRefinedIntegration',
            renderer = 'checkbox',
            name = l10n('EnableNpcPotionsRefinedIntegrationName'),
            description = l10n('EnableNpcPotionsRefinedIntegrationDescription'),
            default = true,
        },
    },
}
