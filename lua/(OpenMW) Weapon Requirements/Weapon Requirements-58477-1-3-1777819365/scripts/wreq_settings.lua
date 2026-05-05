local I      = require('openmw.interfaces')
local shared = require('scripts.wreq_shared')
local D      = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'WeaponRequirements',
    l10n        = 'WeaponRequirements',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'SettingsWReq',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_general_name',
    permanentStorage = true,
    order            = 1,
    settings = {
        { key='MOD_ENABLED',     renderer='checkbox', name='mod_enabled_name',     description='mod_enabled_desc',     default=D.MOD_ENABLED },
        { key='TOOLTIP_ENABLED', renderer='checkbox', name='tooltip_enabled_name', description='tooltip_enabled_desc', default=D.TOOLTIP_ENABLED },
        { key='BURDEN_ENABLED',  renderer='checkbox',  name='burden_enabled_name', description='burden_enabled_desc',  default=D.BURDEN_ENABLED },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqReqs',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_reqs_name',
    permanentStorage = true,
    order            = 2,
    settings = {
        { key='T1_SKILL', renderer='number', name='t1_skill_name', description='t1_skill_desc', default=D.T1_SKILL, argument={integer=true,min=0,max=100} },
        { key='T2_SKILL', renderer='number', name='t2_skill_name', description='t2_skill_desc', default=D.T2_SKILL, argument={integer=true,min=0,max=100} },
        { key='T3_SKILL', renderer='number', name='t3_skill_name', description='t3_skill_desc', default=D.T3_SKILL, argument={integer=true,min=0,max=100} },
        { key='T4_SKILL', renderer='number', name='t4_skill_name', description='t4_skill_desc', default=D.T4_SKILL, argument={integer=true,min=0,max=100} },
        { key='T1_ATTR',  renderer='number', name='t1_attr_name',  description='t1_attr_desc',  default=D.T1_ATTR,  argument={integer=true,min=0,max=100} },
        { key='T2_ATTR',  renderer='number', name='t2_attr_name',  description='t2_attr_desc',  default=D.T2_ATTR,  argument={integer=true,min=0,max=100} },
        { key='T3_ATTR',  renderer='number', name='t3_attr_name',  description='t3_attr_desc',  default=D.T3_ATTR,  argument={integer=true,min=0,max=100} },
        { key='T4_ATTR',  renderer='number', name='t4_attr_name',  description='t4_attr_desc',  default=D.T4_ATTR,  argument={integer=true,min=0,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqAxe1h',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_axe1h_name',
    permanentStorage = true,
    order            = 3,
    settings = {
        { key='AXE1H_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.AXE1H_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='AXE1H_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.AXE1H_T3_DMG, argument={integer=true,min=1,max=100} },
        { key='AXE1H_T4_DMG', renderer='number', name='t4_dmg_name', description='t4_dmg_desc', default=D.AXE1H_T4_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqAxe2h',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_axe2h_name',
    permanentStorage = true,
    order            = 4,
    settings = {
        { key='AXE2H_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.AXE2H_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='AXE2H_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.AXE2H_T3_DMG, argument={integer=true,min=1,max=100} },
        { key='AXE2H_T4_DMG', renderer='number', name='t4_dmg_name', description='t4_dmg_desc', default=D.AXE2H_T4_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqMace',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_mace_name',
    permanentStorage = true,
    order            = 5,
    settings = {
        { key='MACE_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.MACE_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='MACE_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.MACE_T3_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqHammer',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_hammer_name',
    permanentStorage = true,
    order            = 6,
    settings = {
        { key='HAMMER_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.HAMMER_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='HAMMER_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.HAMMER_T3_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqStaff',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_staff_name',
    permanentStorage = true,
    order            = 7,
    settings = {
        { key='STAFF_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.STAFF_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='STAFF_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.STAFF_T3_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqBlade1h',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_blade1h_name',
    permanentStorage = true,
    order            = 8,
    settings = {
        { key='BLADE1H_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.BLADE1H_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='BLADE1H_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.BLADE1H_T3_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqBlade2h',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_blade2h_name',
    permanentStorage = true,
    order            = 9,
    settings = {
        { key='BLADE2H_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.BLADE2H_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='BLADE2H_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.BLADE2H_T3_DMG, argument={integer=true,min=1,max=100} },
        { key='BLADE2H_T4_DMG', renderer='number', name='t4_dmg_name', description='t4_dmg_desc', default=D.BLADE2H_T4_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqShort',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_short_name',
    permanentStorage = true,
    order            = 10,
    settings = {
        { key='SHORT_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.SHORT_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='SHORT_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.SHORT_T3_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqSpear',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_spear_name',
    permanentStorage = true,
    order            = 11,
    settings = {
        { key='SPEAR_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.SPEAR_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='SPEAR_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.SPEAR_T3_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqBow',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_bow_name',
    permanentStorage = true,
    order            = 12,
    settings = {
        { key='BOW_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.BOW_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='BOW_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.BOW_T3_DMG, argument={integer=true,min=1,max=100} },
        { key='BOW_T4_DMG', renderer='number', name='t4_dmg_name', description='t4_dmg_desc', default=D.BOW_T4_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqXbow',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_xbow_name',
    permanentStorage = true,
    order            = 13,
    settings = {
        { key='XBOW_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.XBOW_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='XBOW_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.XBOW_T3_DMG, argument={integer=true,min=1,max=100} },
        { key='XBOW_T4_DMG', renderer='number', name='t4_dmg_name', description='t4_dmg_desc', default=D.XBOW_T4_DMG, argument={integer=true,min=1,max=100} },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsWReqThrown',
    page             = 'WeaponRequirements',
    l10n             = 'WeaponRequirements',
    name             = 'group_thrown_name',
    permanentStorage = true,
    order            = 14,
    settings = {
        { key='THROWN_T2_DMG', renderer='number', name='t2_dmg_name', description='t2_dmg_desc', default=D.THROWN_T2_DMG, argument={integer=true,min=1,max=100} },
        { key='THROWN_T3_DMG', renderer='number', name='t3_dmg_name', description='t3_dmg_desc', default=D.THROWN_T3_DMG, argument={integer=true,min=1,max=100} },
    },
}