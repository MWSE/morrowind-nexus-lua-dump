return {
    -- animation group and its text keys
    ANIM_GROUP = 'prayer2',
    START_KEY  = 'start',
    STOP_KEY   = 'stop',

    -- approximate length of the closing "rise to feet" segment
    RISE_DURATION = 1.3,

    -- FIRST PERSON: yaw is both the view and the body facing
    GLANCE_YAW_DEG = 8.0,

    -- don't change that
    DEFAULTS = {
        DELAY    = 1.0,
        DURATION = 5.0,
        SHRINE_ACTIVATOR = true,
        ALLOW_IMPERIAL = false,
        ALLOW_DAEDRA   = false,
        MURMUR_SOUND   = true,
        VOLUME         = 150,
    },

    -- substring searched for (case-insensitive) in an Activator's MWScript
    SHRINE_KEYWORDS = {
        'shrine',
        'VOF_DunTempShrnMW',
    },

    -- IMPERIAL group: substrings + exact names. Excluded unless ALLOW_IMPERIAL is enabled
    IMPERIAL_KEYWORDS = {
        'T_ScObj_ShrineHlaalu',
        'T_ScObj_ShrineDivines',
        'T_ScObj_ShrineSaint',
        'T_ScObj_ShrineWay',
        'VOF_ImpFthShrnMW',
    },
    IMPERIAL_NAMES = {
        'shrineImperial',
        'T_ScObj_ShrineAlessia',
        'T_ScObj_ShrineClavicusPC',
        'T_ScObj_ShrineCuhlecain',
        'T_ScObj_ShrineMorihaus',
        'T_ScObj_ShrineImperialPC',
        'T_ScObj_ShrinePelinal',
        'T_ScObj_ShrineReman',
        'TR_m3-649_TalosScript',
        'VOF_ImpFthShrnCYRGen',
    },

    -- DAEDRA group: exact script names. Excluded unless ALLOW_DAEDRA is enabled
    DAEDRA_NAMES = {
        'shrineDagonFel',
        'shrineAldSotha',
        'shrineAldDaedroth',
        'DaedraAzura',
        'DaedraBoethiah2',
        'DaedraMalacath',
        'DaedraMehrunes',
        'DaedraMephala',
        'DaedraMolagBal',
        'DaedraSheogorath',
        'TR_m7_DA_Namira_Statue_sc',
    },

    -- quest stages that trigger the prayer animation
    TRIGGERS = {
        ['TT_MaarGan'] = { [60] = true },
        ['TT_Assarnibibi'] = { [100] = true },
        ['TT_DagonFel'] = { [100] = true },
        ['TT_AldSotha'] = { [100] = true },
        ['TT_BalUr'] = { [100] = true },
        ['TT_AldDaedroth'] = { [100] = true },
        ['TT_FieldsKummu'] = { [100] = true },
        ['TT_StopMoon'] = { [100] = true },
        ['TT_PalaceVivec'] = { [100] = true },
        ['TT_PuzzleCanal'] = { [100] = true },
        ['TT_MaskVivec'] = { [100] = true },
        ['TT_RuddyMan'] = { [100] = true },
        ['TT_Ghostgate'] = { [100] = true },
        ['TT_MountKand'] = { [100] = true },
        ['TT_SanctusShrine'] = { [50] = true },
        ['TR_m3_TT_Bloodstone'] = { [100] = true },
        ['TR_m7_TT_PedestalMuatra'] = { [10] = true },
        ['TR_m4_TT_ShrineAlmaFury'] = { [10] = true },
        ['TR_m2_TT_1a'] = { [10] = true },
        ['TR_m1_TT_1c'] = { [10] = true },
        ['TR_m2_TT_1c'] = { [10] = true },
        ['TR_m1_TT_1a'] = { [10] = true },
        ['TR_m7_HO_TT_ShrineHO'] = { [10] = true },
        ['TR_m4_TT_ShrineOlmsRest'] = { [10] = true },
    },
}