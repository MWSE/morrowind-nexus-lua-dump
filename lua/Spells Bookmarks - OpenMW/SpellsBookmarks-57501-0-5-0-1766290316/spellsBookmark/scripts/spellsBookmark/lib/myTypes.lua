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


return {
        ARMOR_TYPE = ARMOR_TYPE,
        CLOTHING_TYPE = CLOTHING_TYPE,
        SLOTS = SLOTS

}
