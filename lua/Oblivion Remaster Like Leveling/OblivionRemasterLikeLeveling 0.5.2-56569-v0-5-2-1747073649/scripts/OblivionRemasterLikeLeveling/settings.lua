local I = require("openmw.interfaces")

I.Settings.registerPage {
  key = 'OblivionRemasterLikeLevelingPage',
  l10n = 'OblivionRemasterLikeLeveling',
  name = 'name',
  description = "description",
}

I.Settings.registerGroup {
  key = 'levelUpSettings',
  page = 'OblivionRemasterLikeLevelingPage',
  l10n = 'OblivionRemasterLikeLeveling',
  name = "levelUpSettingsTitle",
  description = "levelUpSettingsDescription",
  permanentStorage = true,
  settings = {
    {
      key = 'attributePoints',
      renderer = 'number',
      argument = {
        integer = true,
        min = 0,
      },
      name = 'attributePointsName',
      description = 'attributePointsDescription',
      default = 12,
    },
    {
      key = 'maxUpdatableAttribute',
      renderer = 'number',
      argument = {
        integer = true,
        min = 2,
      },
      name = 'maxUpdatableAttributeName',
      description = 'maxUpdatableAttributeDescription',
      default = 3,
    },
    {
      key = 'allowLuckIncrease',
      renderer = 'checkbox',
      argument = {
        l10n = 'OblivionRemasterLikeLeveling',
        trueLabel = 'yes',
        falseLabel = 'no',
      },
      name = 'allowLuckIncreaseName',
      description = 'allowLuckIncreaseDescription',
      default = true,
    },
    {
      key = 'luckIncreaseCost',
      renderer = 'number',
      argument = {
        integer = true,
        min = 1,
      },
      name = 'luckIncreaseCostName',
      description = 'luckIncreaseCostDescription',
      default = 4,
    },
  },
}

I.Settings.registerGroup {
  key = 'skillSettings',
  page = 'OblivionRemasterLikeLevelingPage',
  l10n = 'OblivionRemasterLikeLeveling',
  name = "skillSettingsTitle",
  description = "skillSettingsDescription",
  permanentStorage = true,
  settings = {
    {
      key = 'majorSkillsImpact',
      renderer = 'number',
      argument = {
        integer = true,
        min = 0,
      },
      name = 'majorSkillsImpactName',
      description = 'majorSkillsImpactDescription',
      default = 10,
    },
    {
      key = 'minorSkillsImpact',
      renderer = 'number',
      argument = {
        integer = true,
        min = 0,
      },
      name = 'minorSkillsImpactName',
      description = 'minorSkillsImpactDescription',
      default = 8,
    },
    {
      key = 'miscSkillsImpact',
      renderer = 'number',
      argument = {
        integer = true,
        min = 0,
      },
      name = 'miscSkillsImpactName',
      description = 'miscSkillsImpactDescription',
      default = 4,
    },
  },
}
