local I = require('openmw.interfaces')
local storage = require("openmw.storage")
local async = require("openmw.async")

I.Settings.registerPage {
    key = 'MeritsOfService',
    l10n = 'MeritsOfService',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsMeritsOfService_meta',
    page = 'MeritsOfService',
    l10n = 'MeritsOfService',
    name = 'meta_groupName',
    permanentStorage = true,
    order = 0,
    settings = {
        {
            key = 'settingsPreset',
            name = 'settingsPreset_name',
            description = 'settingsPreset_description',
            renderer = 'select',
            argument = {
                l10n = 'MeritsOfService',
                items = {
                    "Fast and Small",
                    "Slow and Impactful",
                },
            },
            default = "Fast and Small",
        },
        {
            key = 'ncgInstalled',
            name = 'ncgInstalled_name',
            description = 'ncgInstalled_description',
            renderer = 'checkbox',
            default = false,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsMeritsOfService_rewards',
    page = 'MeritsOfService',
    l10n = 'MeritsOfService',
    name = 'rewards_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'questsPerReward',
            name = 'questsPerReward_name',
            renderer = 'number',
            integer = true,
            default = 1,
            min = 1,
        },
        {
            key = 'skillRewardWeight',
            name = 'skillRewardWeight_name',
            description = "skillRewardWeight_desc",
            renderer = 'number',
            integer = false,
            default = 1,
            min = 0,
        },
        {
            key = 'attributeRewardWeight',
            name = 'attributeRewardWeight_name',
            description = "attributeRewardWeight_desc",
            renderer = 'number',
            integer = false,
            default = 0.2,
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
            default = 1,
            min = 0,
        },
        {
            key = 'maxSkillReward',
            name = 'maxSkillReward_name',
            renderer = 'number',
            integer = true,
            default = 1,
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
            default = 1,
            min = 0,
        },
        {
            key = 'maxAttributeReward',
            name = 'maxAttributeReward_name',
            renderer = 'number',
            integer = true,
            default = 1,
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

local function metaSettingsChanged(sectionKey, settingKey)
    local rewardsSection = storage.playerSection("SettingsMeritsOfService_rewards")
    local skillsSection = storage.playerSection("SettingsMeritsOfService_skills")
    local attrsSection = storage.playerSection("SettingsMeritsOfService_attributes")
    local settingValue = storage.playerSection(sectionKey):get(settingKey)

    if settingKey == "settingsPreset" then
        if settingValue == "Fast and Small" then
            rewardsSection:set("questsPerReward", 1)
            rewardsSection:set("skillRewardWeight", 1)
            rewardsSection:set("attributeRewardWeight", 0.2)

            skillsSection:set("minSkillReward", 1)
            skillsSection:set("maxSkillReward", 1)

            attrsSection:set("minAttributeReward", 1)
            attrsSection:set("maxAttributeReward", 1)
        elseif settingValue == "Slow and Impactful" then
            rewardsSection:set("questsPerReward", 3)
            rewardsSection:set("skillRewardWeight", 1)
            rewardsSection:set("attributeRewardWeight", 0.5)

            skillsSection:set("minSkillReward", 3)
            skillsSection:set("maxSkillReward", 5)

            attrsSection:set("minAttributeReward", 2)
            attrsSection:set("maxAttributeReward", 3)
        end
    elseif settingKey == "ncgInstalled" then
        if settingValue then
            attrsSection:set("luckRewardType", "Replace")
            attrsSection:set("luckRewardChance", 1)
        else
            attrsSection:set("luckRewardType", "Bonus")
            attrsSection:set("luckRewardChance", .1)
        end
    end
end

storage.playerSection("SettingsMeritsOfService_meta"):subscribe(async:callback(metaSettingsChanged))
