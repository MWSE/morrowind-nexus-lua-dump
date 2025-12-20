local types = require('openmw.types')
local util = require('openmw.util')
local ui = require('openmw.ui')

local slotIndexToName = {
        'Helmet',
        'Cuirass',
        'Greaves',
        'Pauldron L',
        'Pauldron R',
        'Gauntlet L',
        'Gauntlet R',
        'Boots',
        'Shirt',
        'Pants',
        'Skirt',
        'Robe',
        'Ring L',
        'Ring R',
        'Amulet',
        'Belt',
        'Carried R',
        'Carried L',
        'Ammo',
}

-- local slotIndexToName = {
--         'Helmet',
--         'Cuirass',
--         'Greaves',
--         'LeftPauldron',
--         'RightPauldron',
--         'LeftGauntlet',
--         'RightGauntlet',
--         'Boots',
--         'Shirt',
--         'Pants',
--         'Skirt',
--         'Robe',
--         'LeftRing',
--         'RightRing',
--         'Amulet',
--         'Belt',
--         'CarriedRight',
--         'CarriedLeft',
--         'Ammunition',
-- }

local SLOTS = {
        Helmet = 0,
        Cuirass = 1,
        Greaves = 2,
        LeftPauldron = 3,
        RightPauldron = 4,
        LeftGauntlet = 5,
        RightGauntlet = 6,
        Boots = 7,
        Shirt = 8,
        Pants = 9,
        Skirt = 10,
        Robe = 11,
        LeftRing = 12,
        RightRing = 13,
        Amulet = 14,
        Belt = 15,
        CarriedRight = 16,
        CarriedLeft = 17,
        Ammunition = 18,
}

local ARMOR_TYPE = {
        [0] = SLOTS.Helmet,
        [1] = SLOTS.Cuirass,
        [2] = SLOTS.LeftPauldron,
        [3] = SLOTS.RightPauldron,
        [4] = SLOTS.Greaves,
        [5] = SLOTS.Boots,
        [6] = SLOTS.LeftGauntlet,
        [7] = SLOTS.RightGauntlet,
        [8] = SLOTS.CarriedLeft,
        [9] = SLOTS.LeftGauntlet,
        [10] = SLOTS.RightGauntlet,
}

local CLOTHING_TYPE = {
        [0] = SLOTS.Pants,
        [1] = SLOTS.Boots,
        [2] = SLOTS.Shirt,
        [3] = SLOTS.Belt,
        [4] = SLOTS.Robe,
        [5] = SLOTS.RightGauntlet,
        [6] = SLOTS.LeftGauntlet,
        [7] = SLOTS.Skirt,
        -- Ring = nil,
        [9] = SLOTS.Amulet,
}


local WEAPON_TYPE = {
        ShortBladeOneHand = 0,
        LongBladeOneHand = 1,
        LongBladeTwoHand = 2,
        BluntOneHand = 3,
        BluntTwoClose = 4,
        BluntTwoWide = 5,
        SpearTwoWide = 6,
        AxeOneHand = 7,
        AxeTwoHand = 8,
        MarksmanBow = 9,
        MarksmanCrossbow = 10,
        MarksmanThrown = 11,
        Arrow = 12,
        Bolt = 13,
}


local RANGED_AMMO = {
        [WEAPON_TYPE.Arrow] = true,
        [WEAPON_TYPE.Bolt] = true
}


local RANGED_WEAPON = {
        [WEAPON_TYPE.MarksmanBow] = true,
        [WEAPON_TYPE.MarksmanCrossbow] = true,
        [WEAPON_TYPE.MarksmanThrown] = true
}

local ONE_HAND_WEAPON = {
        [WEAPON_TYPE.AxeOneHand] = true,
        [WEAPON_TYPE.BluntOneHand] = true,
        [WEAPON_TYPE.LongBladeOneHand] = true,
        [WEAPON_TYPE.ShortBladeOneHand] = true,
}

local TWO_HAND_WEAPON = {
        [WEAPON_TYPE.AxeTwoHand] = true,
        [WEAPON_TYPE.BluntTwoClose] = true,
        [WEAPON_TYPE.BluntTwoWide] = true,
        [WEAPON_TYPE.SpearTwoWide] = true,
        [WEAPON_TYPE.LongBladeTwoHand] = true,
}



-- local CLOTHING_TYPE = {
--         Pants = 0,
--         Shoes = 1,
--         Shirt = 2,
--         Belt = 3,
--         Robe = 4,
--         RGlove = 5,
--         LGlove = 6,
--         Skirt = 7,
--         Ring = 8,
--         Amulet = 9,
-- }

-- local ARMOR_TYPE = {
--         Helmet = 0,
--         Cuirass = 1,
--         LPauldron = 2,
--         RPauldron = 3,
--         Greaves = 4,
--         Boots = 5,
--         LGauntlet = 6,
--         RGauntlet = 7,
--         Shield = 8,
--         LBracer = 9,
--         RBracer = 10,
-- }





return {
        ARMOR_TYPE = ARMOR_TYPE,
        CLOTHING_TYPE = CLOTHING_TYPE,
        SLOTS = SLOTS,
        slotIndexToName = slotIndexToName,
        RANGED_AMMO = RANGED_AMMO,
        RANGED_WEAPON = RANGED_WEAPON,
        ONE_HAND_WEAPON = ONE_HAND_WEAPON,
        TWO_HAND_WEAPON = TWO_HAND_WEAPON
}
