local core = require('openmw.core')
local I = require('openmw.interfaces')

local l10n = core.l10n('SkillFramework')
local versionString = "1.1.0"

-- Settings page
I.Settings.registerPage {
    key = 'SkillFramework',
    l10n = 'SkillFramework',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}
I.Settings.registerGroup {
    key = 'Settings/SkillFramework/1_ClientOptions',
    page = 'SkillFramework',
    l10n = 'SkillFramework',
    name = 'ConfigCategoryClientOptions',
    permanentStorage = true,
    settings = {
        {
            key = 'b_ShowSubsections',
            renderer = 'checkbox',
            default = true,
            name = 'ConfigShowSubsections',
            description = 'ConfigShowSubsectionsDesc',
        },
    },
}