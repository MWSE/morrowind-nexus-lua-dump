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
    GREEN = util.color.rgb(0, 1, 0),
    GOLD = util.color.rgb(255 / 255, 205 / 255, 0),
}

C.Strings = {
    POWERS = 'sPowers',
    SPELLS = 'sSpells',
    MAGIC_ITEMS = 'sMagicItem',
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
    HAND_TO_HAND = 'sSkillHandtohand',
    LIGHT = 'sLight',
    MEDIUM = 'sMedium',
    HEAVY = 'sHeavy',
    CONDITION = 'sCondition',
    WEIGHT = 'sWeight',
    VALUE = 'sValue',
    SLASH = 'sSlash',
    THRUST = 'sThrust',
    CHOP = 'sChop',
    ATTACK = 'sAttack',
    USES = 'sUses',
    QUALITY = 'sQuality',
    ARMOR_RATING = 'sArmorRating',
    TYPE = 'sType',
    SPEED = 'sAttributeSpeed',
    ONE_HANDED = 'sOneHanded',
    TWO_HANDED = 'sTwoHanded',
    TAKE = 'sTake',
    TAKE_ALL = 'sTakeAll',
    CANCEL = 'sCancel',
    CLOSE = 'sClose',
    DISPOSE_OF_CORPSE = 'sDisposeOfCorpse',
    DISPOSE_CORPSE_FAIL = 'sDisposeCorpseFail',
    OFFER = 'sBarterDialog8',
    BARTER_NO_ITEMS = 'sBarterDialog11',
    BARTER_PC_TOO_POOR = 'sBarterDialog1',
    BARTER_NPC_TOO_POOR = 'sBarterDialog2',
    BARTER_REFUSED = 'sNotifyMessage9',
    BARTER_THANK_YOU = 'sBarterDialog5',
    TOTAL_SOLD = 'sTotalSold',
    TOTAL_COST = 'sTotalCost',
    MAX_SALE = 'sMaxSale',
    CONTAINER_ORGANIC = 'sContentsMessage2',
    THATS_MINE = 'sNotifyMessage49',
    PROFIT_VALUE = 'sProfitValue',
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

C.Events = {
    INVENTORY_SHOWN = 'IE_InventoryShown',
    INVENTORY_HIDDEN = 'IE_InventoryHidden',
    BARTER_SHOWN = 'IE_BarterShown',
    BARTER_HIDDEN = 'IE_BarterHidden',
    CONTAINER_SHOWN = 'IE_ContainerShown',
    CONTAINER_HIDDEN = 'IE_ContainerHidden',
    COMPANION_SHOWN = 'IE_CompanionShown',
    COMPANION_HIDDEN = 'IE_CompanionHidden',
}

C.DragType = {
    ResizeTL = 'top_left',
    ResizeBR = 'bottom_right',
    ResizeTR = 'top_right',
    ResizeBL = 'bottom_left',
    ResizeL = 'left',
    ResizeR = 'right',
    ResizeT = 'top',
    ResizeB = 'bottom',
    Move = 'move',
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

C.WeaponClass = {
    Melee = 1,
    Ranged = 2,
    Thrown = 3,
    Ammo = 4,
}

C.OPT_KEYS = {
    CompareItemsMode = 's_CompareItemsMode',
    SeparatorsMode = 's_NumberSeparators',
    SortingBarterReverseEquipped = 'b_SortingBarterReverseEquipped',
    SortingBarterReverseFavorite = 'b_SortingBarterReverseFavorite',
    TooltipShowItemUseCost = 'b_TooltipShowItemUseCost',
}

C.COMPARISON_OPTS = {
    Never = 'ConfigCompareItemsMode_Never',
    ALT = 'ConfigCompareItemsMode_ALT',
    Always = 'ConfigCompareItemsMode_Always',
}

C.SEPARATOR_OPTS = {
    None = 'ConfigNumberSeparators_None',
    Comma = 'ConfigNumberSeparators_Comma',
    Space = 'ConfigNumberSeparators_Space',
}

local boundItemGMSTs = {
    "sMagicBoundDaggerID",
    "sMagicBoundLongswordID",
    "sMagicBoundMaceID",
    "sMagicBoundBattleAxeID",
    "sMagicBoundSpearID",
    "sMagicBoundLongbowID",
    "sMagicBoundCuirassID",
    "sMagicBoundHelmID",
    "sMagicBoundBootsID",
    "sMagicBoundShieldID",
    "sMagicBoundLeftGauntletID",
    "sMagicBoundRightGauntletID",
}
C.BoundItemIDs = {}
for _, gmst in ipairs(boundItemGMSTs) do
    local value = core.getGMST(gmst):lower()
    C.BoundItemIDs[value] = true
end

-- TD Bound Items
local err, trData = pcall(require, 'scripts.tr_spells.trData')
if trData and trData.BOUND_ITEMS then
    for _, data in pairs(trData.BOUND_ITEMS) do
        for _, itemId in ipairs(data.items) do
            C.BoundItemIDs[itemId:lower()] = true
        end
    end 
end

-- Bound Balance Bound Items
local bbBase = 'momw_bb_bound_'
local bbItemTypes = { 'battle_axe', 'boots', 'cuirass', 'dagger', 'gauntletl', 'gauntletr', 'greaves', 'helm', 'longbow', 'longsword', 'mace', 'pauldronl', 'pauldronr', 'shield', 'spear' }
local bbLevels = { 'i', 'ii', 'iii', 'iv', 'v', 'vi' }
local bbSuffixes = { '', '_td', '_tw', '_oaab' }

for _, itemType in ipairs(bbItemTypes) do
    for _, level in ipairs(bbLevels) do
        for _, suffix in ipairs(bbSuffixes) do
            local id = bbBase .. itemType .. '_' .. level .. suffix
            C.BoundItemIDs[id:lower()] = true
        end
    end
end

C.TypeToService = {
    Weapon = "Weapon",
    Armor = "Armor",
    Clothing = "Clothing",
    Book = "Books",
    Potion = "Potions",
    Ingredient = "Ingredients",
    Lockpick = "Picks",
    Probe = "Probes",
    Light = "Lights",
    Apparatus = "Apparatus",
    Repair = "RepairItem",
    Miscellaneous = "Misc",
}

return C