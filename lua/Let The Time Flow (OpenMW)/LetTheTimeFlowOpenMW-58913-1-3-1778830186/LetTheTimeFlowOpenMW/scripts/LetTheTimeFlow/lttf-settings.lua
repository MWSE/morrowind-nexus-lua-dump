--
-- [ Libraries ]
--
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local core = require('openmw.core')


--
-- [ Variables ]
--
local l10n = core.l10n('LetTheTimeFlow')


--
-- [ Page ]
--
I.Settings.registerPage {
	key = 'LetTheTimeFlowPage',
    l10n = 'LetTheTimeFlow',
    name = 'modName',
    description = 'modDescription'
}


--
-- [ General ]
--
I.Settings.registerGroup {
	key = 'F_GeneralSettings',
    page = 'LetTheTimeFlowPage',
    l10n = 'LetTheTimeFlow',
    name = 'generalSettingsName',
    permanentStorage = true,
    settings = {
        {
        	-- _ Rest recovery _
            key = 'RestRecovery',
            renderer = 'number',
            name = 'restRecoveryName',
            description = 'restRecoveryDescription',
            default = 8,
            argument = {
                min = 1,
                max = 12,
            }
        },
        {
            -- _ Maximum Rest Credit _
            key = 'MaxRestCredit',
            renderer = 'number',
            name = 'maxRestCreditName',
            description = 'maxRestCreditDescription',
            default = 16,
            argument = {
                min = 1,
                max = 24,
            }
        },
        --[[
        {
            -- _ Maximum Rest Debit _
            key = 'MaxRestDebit',
            renderer = 'number',
            name = 'maxRestDebitName',
            description = 'maxRestDebitDescription',
            default = 23,
            argument = {
                min = 1,
                max = 24,
            }
        },
        ]]--
        {
            -- _ Wake Up installed _
            key = 'WakeUpInstalled',
            renderer = 'checkbox',
            name = 'wakeUpInstalledName',
            description = 'wakeUpInstalledDescription',
            default = false
        }
    }
}


--
-- [ Debug ]
--
I.Settings.registerGroup {
    key = 'S_DebugSettings',
    page = 'LetTheTimeFlowPage',
    l10n = 'LetTheTimeFlow',
    name = 'debugSettingsName',
    description = 'debugSettingsDescription',
    permanentStorage = true,
    settings = {
        {
            -- _ Debug password _
            key = 'Password',
            renderer = 'textLine',
            name = 'passwordName',
            description = 'passwordDescription',
            default = ''
        },
        {
            -- _ Recovery Cycle _
            key = 'RecoveryCycle',
            renderer = 'number',
            name = 'recoveryCycleName',
            description = 'recoveryCycleDescription',
            default = 450,
            argument = {
                min = 1,
                max = 86400,
            }
        }
    }
}


--
-- [ Broadcast ]
--
local generalSettings = storage.playerSection('F_GeneralSettings')
local debugSettings = storage.playerSection('S_DebugSettings')
