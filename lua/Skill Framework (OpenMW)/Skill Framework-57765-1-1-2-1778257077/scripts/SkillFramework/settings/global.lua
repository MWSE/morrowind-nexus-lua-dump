local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'Settings/SkillFramework/2_GlobalOptions',
    page = 'SkillFramework',
    l10n = 'SkillFramework',
    name = 'ConfigCategoryGlobalOptions',
    permanentStorage = true,
    settings = {
        {
            key = 'b_SkillsProgressAttributes',
            renderer = 'checkbox',
            default = true,
            name = 'ConfigSkillsProgressAttributes',
            description = 'ConfigSkillsProgressAttributesDesc',
        },
    },
}