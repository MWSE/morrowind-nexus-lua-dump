local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'MeritsOfService',
    l10n = 'MeritsOfService',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsMeritsOfService_general',
    page = 'MeritsOfService',
    l10n = 'MeritsOfService',
    name = 'general_groupName',
    description = 'general_groupDesc',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'questsPerReward',
            name = 'questsPerReward_name',
            renderer = 'number',
            integer = true,
            default = 3,
            min = 1,
        },
        {
            key = 'skillRewardWeight',
            name = 'skillRewardWeight_name',
            renderer = 'number',
            integer = false,
            default = 1,
            min = 0,
        },
        {
            key = 'attributeRewardWeight',
            name = 'attributeRewardWeight_name',
            renderer = 'number',
            integer = false,
            default = 0.5,
            min = 0,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsMeritsOfService_skills',
    page = 'MeritsOfService',
    l10n = 'MeritsOfService',
    name = 'skills_groupName',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'minSkillReward',
            name = 'minSkillReward_name',
            renderer = 'number',
            integer = true,
            default = 3,
            min = 0,
        },
        {
            key = 'maxSkillReward',
            name = 'maxSkillReward_name',
            renderer = 'number',
            integer = true,
            default = 5,
            min = 0,
        },
        {
            key = 'capSkills',
            name = 'capSkills_name',
            renderer = 'number',
            integer = true,
            default = 100,
            min = 1,
        },
        {
            key = 'carrySkillXp',
            name = 'carrySkillXp_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'triggerSkillupHandlers',
            name = 'triggerSkillupHandlers_name',
            description = 'triggerSkillupHandlers_description',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsMeritsOfService_attributes',
    page = 'MeritsOfService',
    l10n = 'MeritsOfService',
    name = 'attributes_groupName',
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'minAttributeReward',
            name = 'minAttributeReward_name',
            renderer = 'number',
            integer = true,
            default = 2,
            min = 0,
        },
        {
            key = 'maxAttributeReward',
            name = 'maxAttributeReward_name',
            renderer = 'number',
            integer = true,
            default = 3,
            min = 0,
        },
        {
            key = 'capAttr',
            name = 'capAttr_name',
            renderer = 'number',
            integer = true,
            default = 100,
            min = 1,
        },
        {
            key = 'luckRewardType',
            name = 'luckRewardType_name',
            description = 'luckRewardType_description',
            renderer = 'select',
            argument = {
                l10n = 'MeritsOfService',
                items = {
                    "Replace",
                    "Bonus",
                },
            },
            default = "Bonus",
        },
        {
            key = 'luckRewardChance',
            name = 'luckRewardChance_name',
            renderer = 'number',
            integer = false,
            default = 0.1,
            min = 0,
            max = 1,
        },
    }
}