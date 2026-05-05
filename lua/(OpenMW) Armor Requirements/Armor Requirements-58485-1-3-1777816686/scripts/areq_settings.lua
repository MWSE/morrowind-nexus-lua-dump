local I      = require('openmw.interfaces')
local shared = require('scripts.areq_shared')
local D      = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'ArmorRequirements',
    l10n        = 'ArmorRequirements',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'SettingsAReq',
    page             = 'ArmorRequirements',
    l10n             = 'ArmorRequirements',
    name             = 'group_general_name',
    permanentStorage = true,
    order            = 1,
    settings = {
        { key='MOD_ENABLED',         renderer='checkbox', name='mod_enabled_name',         description='mod_enabled_desc',         default=D.MOD_ENABLED },
        { key='BURDEN_ENABLED',      renderer='checkbox', name='burden_enabled_name',      description='burden_enabled_desc',      default=D.BURDEN_ENABLED },
        { key='TOOLTIP_ENABLED',     renderer='checkbox', name='tooltip_enabled_name',     description='tooltip_enabled_desc',     default=D.TOOLTIP_ENABLED },
        { key='HEAVY_ENABLED',       renderer='checkbox', name='heavy_enabled_name',       description='heavy_enabled_desc',       default=D.HEAVY_ENABLED },
        { key='MEDIUM_ENABLED',      renderer='checkbox', name='medium_enabled_name',      description='medium_enabled_desc',      default=D.MEDIUM_ENABLED },
        { key='LIGHT_ENABLED',       renderer='checkbox', name='light_enabled_name',       description='light_enabled_desc',       default=D.LIGHT_ENABLED },
        { key='BOUND_CHECK_ENABLED', renderer='checkbox', name='bound_check_enabled_name', description='bound_check_enabled_desc', default=D.BOUND_CHECK_ENABLED },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsAReqHeavy',
    page             = 'ArmorRequirements',
    l10n             = 'ArmorRequirements',
    name             = 'group_heavy_name',
    permanentStorage = true,
    order            = 2,
    settings = {
        { key='HEAVY_T2_RATING', renderer='number', name='t2_rating_name', description='t2_rating_desc', default=D.HEAVY_T2_RATING, argument={ integer=true, min=1, max=200 } },
        { key='HEAVY_T3_RATING', renderer='number', name='t3_rating_name', description='t3_rating_desc', default=D.HEAVY_T3_RATING, argument={ integer=true, min=1, max=200 } },
        { key='HEAVY_T4_RATING', renderer='number', name='t4_rating_name', description='t4_rating_desc', default=D.HEAVY_T4_RATING, argument={ integer=true, min=1, max=200 } },
        { key='HEAVY_T2_SKILL',  renderer='number', name='t2_skill_name',  description='t2_skill_desc',  default=D.HEAVY_T2_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='HEAVY_T3_SKILL',  renderer='number', name='t3_skill_name',  description='t3_skill_desc',  default=D.HEAVY_T3_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='HEAVY_T4_SKILL',  renderer='number', name='t4_skill_name',  description='t4_skill_desc',  default=D.HEAVY_T4_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='HEAVY_T2_ATTR',   renderer='number', name='t2_attr_name',   description='t2_attr_desc',   default=D.HEAVY_T2_ATTR,   argument={ integer=true, min=0, max=100 } },
        { key='HEAVY_T3_ATTR',   renderer='number', name='t3_attr_name',   description='t3_attr_desc',   default=D.HEAVY_T3_ATTR,   argument={ integer=true, min=0, max=100 } },
        { key='HEAVY_T4_ATTR',   renderer='number', name='t4_attr_name',   description='t4_attr_desc',   default=D.HEAVY_T4_ATTR,   argument={ integer=true, min=0, max=100 } },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsAReqMedium',
    page             = 'ArmorRequirements',
    l10n             = 'ArmorRequirements',
    name             = 'group_medium_name',
    permanentStorage = true,
    order            = 3,
    settings = {
        { key='MEDIUM_T2_RATING', renderer='number', name='t2_rating_name', description='t2_rating_desc', default=D.MEDIUM_T2_RATING, argument={ integer=true, min=1, max=200 } },
        { key='MEDIUM_T3_RATING', renderer='number', name='t3_rating_name', description='t3_rating_desc', default=D.MEDIUM_T3_RATING, argument={ integer=true, min=1, max=200 } },
        { key='MEDIUM_T4_RATING', renderer='number', name='t4_rating_name', description='t4_rating_desc', default=D.MEDIUM_T4_RATING, argument={ integer=true, min=1, max=200 } },
        { key='MEDIUM_T2_SKILL',  renderer='number', name='t2_skill_name',  description='t2_skill_desc',  default=D.MEDIUM_T2_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='MEDIUM_T3_SKILL',  renderer='number', name='t3_skill_name',  description='t3_skill_desc',  default=D.MEDIUM_T3_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='MEDIUM_T4_SKILL',  renderer='number', name='t4_skill_name',  description='t4_skill_desc',  default=D.MEDIUM_T4_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='MEDIUM_T2_ATTR',   renderer='number', name='t2_attr_name',   description='t2_attr_desc',   default=D.MEDIUM_T2_ATTR,   argument={ integer=true, min=0, max=100 } },
        { key='MEDIUM_T3_ATTR',   renderer='number', name='t3_attr_name',   description='t3_attr_desc',   default=D.MEDIUM_T3_ATTR,   argument={ integer=true, min=0, max=100 } },
        { key='MEDIUM_T4_ATTR',   renderer='number', name='t4_attr_name',   description='t4_attr_desc',   default=D.MEDIUM_T4_ATTR,   argument={ integer=true, min=0, max=100 } },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsAReqLight',
    page             = 'ArmorRequirements',
    l10n             = 'ArmorRequirements',
    name             = 'group_light_name',
    permanentStorage = true,
    order            = 4,
    settings = {
        { key='LIGHT_T2_RATING', renderer='number', name='t2_rating_name', description='t2_rating_desc', default=D.LIGHT_T2_RATING, argument={ integer=true, min=1, max=200 } },
        { key='LIGHT_T3_RATING', renderer='number', name='t3_rating_name', description='t3_rating_desc', default=D.LIGHT_T3_RATING, argument={ integer=true, min=1, max=200 } },
        { key='LIGHT_T4_RATING', renderer='number', name='t4_rating_name', description='t4_rating_desc', default=D.LIGHT_T4_RATING, argument={ integer=true, min=1, max=200 } },
        { key='LIGHT_T2_SKILL',  renderer='number', name='t2_skill_name',  description='t2_skill_desc',  default=D.LIGHT_T2_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='LIGHT_T3_SKILL',  renderer='number', name='t3_skill_name',  description='t3_skill_desc',  default=D.LIGHT_T3_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='LIGHT_T4_SKILL',  renderer='number', name='t4_skill_name',  description='t4_skill_desc',  default=D.LIGHT_T4_SKILL,  argument={ integer=true, min=0, max=100 } },
        { key='LIGHT_T2_ATTR',   renderer='number', name='t2_attr_name',   description='t2_attr_desc',   default=D.LIGHT_T2_ATTR,   argument={ integer=true, min=0, max=100 } },
        { key='LIGHT_T3_ATTR',   renderer='number', name='t3_attr_name',   description='t3_attr_desc',   default=D.LIGHT_T3_ATTR,   argument={ integer=true, min=0, max=100 } },
        { key='LIGHT_T4_ATTR',   renderer='number', name='t4_attr_name',   description='t4_attr_desc',   default=D.LIGHT_T4_ATTR,   argument={ integer=true, min=0, max=100 } },
    },
}