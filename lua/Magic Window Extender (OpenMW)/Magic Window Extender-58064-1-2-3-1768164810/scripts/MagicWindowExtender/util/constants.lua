local core = require('openmw.core')
local util = require('openmw.util')

local colorFromGMST = function(gmst)
    local colorString = core.getGMST(gmst)
    local numberTable = {}
    for numberString in colorString:gmatch("([^,]+)") do
        if #numberTable == 3 then break end
        local number = tonumber(numberString:match("^%s*(.-)%s*$"))
        if number then
            table.insert(numberTable, number / 255)
        end
    end

    if #numberTable < 3 then error('Invalid color GMST name: ' .. gmst) end

    return util.color.rgb(table.unpack(numberTable))
end

local C = {}

C.NIL = '%!nil!%'

C.Colors = {
    -- CFG colors
    DEFAULT = colorFromGMST('fontcolor_color_normal'),
    DEFAULT_LIGHT = colorFromGMST('fontcolor_color_normal_over'),
    DEFAULT_PRESSED = colorFromGMST('fontcolor_color_normal_pressed'),
    ACTIVE = colorFromGMST('fontcolor_color_active'),
    ACTIVE_LIGHT = colorFromGMST('fontcolor_color_active_over'),
    ACTIVE_PRESSED = colorFromGMST('fontcolor_color_active_pressed'),
    DISABLED = colorFromGMST('fontcolor_color_disabled'),
    DISABLED_LIGHT = colorFromGMST('fontcolor_color_disabled_over'),
    DISABLED_PRESSED = colorFromGMST('fontcolor_color_disabled_pressed'),
    BAR_HEALTH = colorFromGMST('fontcolor_color_health'),
    BAR_MAGIC = colorFromGMST('fontcolor_color_magic'),
    BAR_FATIGUE = colorFromGMST('fontcolor_color_fatigue'),
    POSITIVE = colorFromGMST('fontcolor_color_positive'),
    DAMAGED = colorFromGMST('fontcolor_color_negative'),
    BACKGROUND = colorFromGMST('fontcolor_color_background'),
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
    POWERS = 'sPowers',
    SPELLS = 'sSpells',
    MAGIC_ITEMS = 'sMagicItem',
    ITEM_WEIGHT = 'sWeight',
    ITEM_VALUE = 'sValue',
    ITEM_CAST_ONCE = 'sItemCastOnce',
    ITEM_CAST_WHEN_STRIKES = 'sItemCastWhenStrikes',
    ITEM_CAST_WHEN_USED = 'sItemCastWhenUsed',
    ITEM_CAST_CONSTANT = 'sItemCastConstant',
    RANGE = 'sRange',
    RANGE_SELF = 'sRangeSelf',
    RANGE_TOUCH = 'sRangeTouch',
    RANGE_TARGET = 'sRangeTarget',
    AREA = 'sArea',
    MAGNITUDE = 'sMagnitude',
    DURATION = 'sDuration',
    DRAIN = 'sDrain',
    ABSORB = 'sAbsorb',
    FORTIFY = 'sFortify',
    RESTORE = 'sRestore',
    DAMAGE = 'sDamage',
    POINT = 'spoint',
    POINTS = 'spoints',
    PERCENT = 'spercent',
    FOR = 'sfor',
    SECOND = 'ssecond',
    SECONDS = 'sseconds',
    LEVEL = 'sLevel',
    LEVELS = 'sLevels',
    IN = 'sin',
    FOOT_AREA = 'sfootarea',
    FEET = 'sfeet',
    X_TIMES = 'sXTimes',
    X_TIMES_INT = 'sXTimesInt',
    ON = 'sonword',
    TO = 'sTo',
    CHARGE = 'sCharges',
    SCHOOL = 'sSchool',
    SCHOOL_ALTERATION = 'sSchoolAlteration',
    SCHOOL_CONJURATION = 'sSchoolConjuration',
    SCHOOL_DESTRUCTION = 'sSchoolDestruction',
    SCHOOL_ILLUSION = 'sSchoolIllusion',
    SCHOOL_MYSTICISM = 'sSchoolMysticism',
    SCHOOL_RESTORATION = 'sSchoolRestoration',
    NONE = 'sNone',
    COST_CHANCE = 'sCostChance',
    COST_CHARGE = 'sCostCharge',
    DELETE = 'sDelete',
    DELETE_SPELL_ERROR = 'sDeleteSpellError',
    DELETE_SPELL_QUESTION = 'sQuestionDeleteSpell',
    YES = 'sYes',
    NO = 'sNo',
    OK = 'sOK',
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
    MAIN = 'mainPane',
}

C.DefaultBoxes = {
    TOP_BAR = 'topBar',
    MAGIC = 'magic',
    BOTTOM_BAR = 'bottomBar',
}

C.DefaultSections = {
    TOP_BAR = 'topBar',
    POWERS = 'powers',
    SPELLS = 'spells',
    MAGIC_ITEMS = 'magicItems',
    BOTTOM_BAR = 'bottomBar',
}

C.DefaultLines = {
    ACTIVE_SPELLS = 'activeSpells',
    EDIT_MODE_BUTTON = 'editModeButton',
    SEARCH_BAR = 'searchBar',
    SCHOOL_FILTER = 'schoolFilter',
    DELETE_BUTTON = 'deleteButton',
}

C.LineType = {
    ACTIVE_SPELLS = 'activeSpells',
    LABELED_VALUE = 'labeledValue',
    CUSTOM = 'custom',
}

C.ValueType = {
    STRING = 'string',
    CUSTOM = 'custom',
}

C.TrackedStats = {
    ACTIVE_SPELLS = 'activeSpells',
    POWERS = 'powers',
    SPELLS = 'spells',
    MAGIC_ITEMS = 'magicItems',
    SEARCH_FILTER = 'searchFilter',
    SCHOOL_FILTER = 'schoolFilter',
    EDIT_MODE = 'editMode',
    PINNED = 'pinned',
    HIDDEN = 'hidden',
    EFFECT_OVERRIDES = 'effectOverrides',
    SPELL_OVERRIDES = 'spellOverrides',
    DELETED_SPELLS = 'deletedSpells',
}

C.Events = {
    WINDOW_SHOWN = 'MagicWindow_Shown',
    WINDOW_HIDDEN = 'MagicWindow_Hidden',
}

C.Magic = {
    MagnitudeDisplayType = {
        NONE = 1,
        TIMES_INT = 2,
        FEET = 3,
        LEVEL = 4,
        PERCENTAGE = 5,
        POINTS = 6,
    }
}

return C