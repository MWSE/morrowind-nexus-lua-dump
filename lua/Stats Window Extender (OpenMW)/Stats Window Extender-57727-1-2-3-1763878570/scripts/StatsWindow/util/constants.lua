local core = require('openmw.core')
local util = require('openmw.util')

local helpers = require('scripts.StatsWindow.util.helpers')

local C = {}

C.NIL = '%!nil!%'

C.Colors = {
    -- CFG colors
    DEFAULT = helpers.colorFromGMST('fontcolor_color_normal'),
    DEFAULT_LIGHT = helpers.colorFromGMST('fontcolor_color_normal_over'),
    DEFAULT_PRESSED = helpers.colorFromGMST('fontcolor_color_normal_pressed'),
    ACTIVE = helpers.colorFromGMST('fontcolor_color_active'),
    ACTIVE_LIGHT = helpers.colorFromGMST('fontcolor_color_active_over'),
    ACTIVE_PRESSED = helpers.colorFromGMST('fontcolor_color_active_pressed'),
    BAR_HEALTH = helpers.colorFromGMST('fontcolor_color_health'),
    BAR_MAGIC = helpers.colorFromGMST('fontcolor_color_magic'),
    BAR_FATIGUE = helpers.colorFromGMST('fontcolor_color_fatigue'),
    POSITIVE = helpers.colorFromGMST('fontcolor_color_positive'),
    DAMAGED = helpers.colorFromGMST('fontcolor_color_negative'),
    BACKGROUND = helpers.colorFromGMST('fontcolor_color_background'),
    -- Generic colors
    WHITE = util.color.rgb(1, 1, 1),
    GRAY = util.color.rgb(0.5, 0.5, 0.5),
    DARK_GRAY = util.color.rgb(0.25, 0.25, 0.25),
    BLACK = util.color.rgb(0, 0, 0),
    CYAN = util.color.rgb(0, 1, 1),
    YELLOW = util.color.rgb(1, 1, 0),
    RED = util.color.rgb(1, 0, 0),
    DARK_RED = util.color.rgb(0.5, 0, 0),
    RED_DESAT = util.color.rgb(0.7, 0.3, 0.3),
    DARK_RED_DESAT = util.color.rgb(0.3, 0.05, 0.05),
}

C.Strings = {
    HEALTH = 'sHealth',
    HEALTH_DESC = 'sHealthDesc',
    MAGICKA = 'sMagic',
    MAGICKA_DESC = 'sMagDesc',
    FATIGUE = 'sFatigue',
    FATIGUE_DESC = 'sFatDesc',
    LEVEL = 'sLevel',
    LEVEL_PROGRESS = 'sLevelProgress',
    RACE = 'sRace',
    CLASS = 'sClass',
    SPEC = 'sSpecialization',
    SPEC_COMBAT = 'sSpecializationCombat',
    SPEC_MAGIC = 'sSpecializationMagic',
    SPEC_STEALTH = 'sSpecializationStealth',
    MAJOR_SKILLS = 'sSkillClassMajor',
    MINOR_SKILLS = 'sSkillClassMinor',
    MISC_SKILLS = 'sSkillClassMisc',
    SKILL = 'sSkill',
    SKILL_PROGRESS = 'sSkillProgress',
    SKILL_MAX_REACHED = 'sSkillMaxReached',
    GOVERNING_ATTRIBUTE = 'sGoverningAttribute',
    FACTION = 'sFaction',
    EXPELLED = 'sExpelled',
    NEXT_RANK = 'sNextRank',
    FAVORITE_SKILLS = 'sFavoriteSkills',
    NEED_ONE_SKILL = 'sNeedOneSkill',
    NEED_TWO_SKILLS = 'sNeedTwoSkills',
    AND = 'sAnd',
    BIRTH_SIGN = 'sBirthSign',
    REPUTATION = 'sReputation',
    REPUTATION_DESC = 'sSkillsMenuReputationHelp',
    BOUNTY = 'sBounty',
    BOUNTY_DESC = 'sCrimeHelp',
    TYPE_SPELL = 'sTypeSpell',
    TYPE_ABILITY = 'sTypeAbility',
    TYPE_POWER = 'sTypePower',
}
for key, gmst in pairs(C.Strings) do
    C.Strings[key] = core.getGMST(gmst)
end

C.Placement = {
    AFTER = 1,
    BEFORE = 2,
    TOP = 3,
    BOTTOM = 4,
}

C.Sort = {
    ADDED_ORDER = 1,
    LABEL_ASC = 2,
    LABEL_DESC = 3,
}

C.Panes = {
    LEFT = 'leftPane',
    RIGHT = 'rightPane',
}

C.DefaultBoxes = {
    HEALTH_BOX = 'healthStatsBox',
    LEVEL_BOX = 'levelStatsBox',
    ATTRIBUTES_BOX = 'attributesBox',
    LEFT_FACTION_BOX = 'leftFactionBox',
    RIGHT_SCROLL_BOX = 'rightScrollBox',
}

C.DefaultSections = {
    HEALTH_STATS = 'healthStats',
    LEVEL_STATS = 'levelStats',
    ATTRIBUTES = 'attributes',
    MAJOR_SKILLS = 'majorSkills',
    MINOR_SKILLS = 'minorSkills',
    MISC_SKILLS = 'miscSkills',
    FACTION = 'faction',
    BIRTHSIGN = 'birthSign',
    REPUTATION = 'reputation',
    BOUNTY = 'bounty',
}

C.DefaultLines = {
    HEALTH = 'health',
    MAGICKA = 'magicka',
    FATIGUE = 'fatigue',
    LEVEL = 'level',
    RACE = 'race',
    CLASS = 'class',
    REPUTATION = 'reputation',
    BOUNTY = 'bounty',
}

C.LineType = {
    STRING = 'string',
    PROGRESS_BAR = 'progressBar',
    CUSTOM = 'custom',
}

C.TrackedStats = {
    REPUTATION = 'SW_PCRep',
    BOUNTY = 'bounty',
    FACTIONS = 'factions',
    BIRTHSIGN = 'sign',
    CLASS = 'class',
}

C.Events = {
    WINDOW_SHOWN = 'StatsWindow_Shown',
    WINDOW_HIDDEN = 'StatsWindow_Hidden',
}

return C