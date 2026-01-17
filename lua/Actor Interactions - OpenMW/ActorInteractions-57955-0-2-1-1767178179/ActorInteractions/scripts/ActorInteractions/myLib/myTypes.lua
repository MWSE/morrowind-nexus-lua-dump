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
        'Instrument'
}

local ARRANGED_SLOTS = {
        'Helmet',
        'Amulet',
        'LeftPauldron',
        'Shirt',
        'Cuirass',
        'Robe',
        'RightPauldron',
        'LeftRing',
        'LeftGauntlet',
        'Belt',
        'RightGauntlet',
        'RightRing',
        'CarriedLeft',
        'Pants',
        'Greaves',
        'Skirt',
        'CarriedRight',
        'Ammunition',
        'Boots',
        -- 'Instrument'
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
        -- Instrument = 19,
}

local SLOT_GRAPH_TO_LIST = {
        [0] = 0,
        [14] = 1,
        [3] = 2,
        [8] = 3,
        [1] = 4,
        [11] = 5,
        [4] = 6,
        [12] = 7,
        [5] = 8,
        [15] = 9,
        [6] = 10,
        [13] = 11,
        [17] = 12,
        [9] = 13,
        [2] = 14,
        [10] = 15,
        [16] = 16,
        [18] = 17,
        [7] = 18,
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


local WEAPON_TYPE_TO_TEXT = {
        [0] = 'Short Blade, One Handed',
        [1] = 'Long Blade, One Handed',
        [2] = 'Long Blade, Two Handed',
        [3] = 'Blunt Weapon, One Handed',
        [4] = 'Blunt Weapon, Two Handed',
        [5] = 'Blunt Weapon, Two Handed',
        [6] = 'Spear, Two Handed',
        [7] = 'Axe, One Handed',
        [8] = 'Axe, Two Handed',
        [9] = 'Marksman',
        [10] = 'Marksman',
        [11] = 'Marksman',
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



local SKILL_GROUP = {
        combat = {
                axe = true,
                bluntweapon = true,
                handtohand = true,
                longblade = true,
                marksman = true,
                shortblade = true,
                spear = true,
        },
        armor = {
                lightarmor = true,
                mediumarmor = true,
                heavyarmor = true,
                unarmored = true,
                block = true,
        },
        magic = {
                restoration = true,
                alteration = true,
                mysticism = true,
                destruction = true,
                conjuration = true,
                illusion = true,
        },
        other = {
                armorer = true,
                alchemy = true,
                enchant = true,
                athletics = true,
                acrobatics = true,
                mercantile = true,
                speechcraft = true,
                security = true,
                sneak = true,
        },
}



local TOKENS_REFILL_BASE = {
        potion_skooma_01 = 5,
        potion_t_bug_musk_01 = 1,
}

local TOKENS_REFILL_EXTRA = {
        'p_fortify_strength_e',
        'p_fortify_intelligence_e',
        'p_fortify_willpower_e',
        'p_fortify_agility_e',
        'p_fortify_speed_e',
        'p_fortify_endurance_e',
        'p_fortify_personality_e',
        'p_fortify_luck_e',

        -- p_restore_[attribute]_e
        --- ##########,
        'p_burden_e',
        'p_feather_e',
        'p_fire_shield_e',
        'p_frost_shield_e',
        'p_jump_e',
        'p_levitation_e',
        'p_lightning shield_e',
        'p_swift_swim_e',
        'p_chameleon_e',
        'p_invisibility_e',
        'p_light_e',
        'p_night-eye_e',
        'p_paralyze_e',
        'p_silence_e',
        'p_reflection_e',
        'p_spell_absorption_e',
        ---
        'p_fortify_fatigue_e',
        'p_fortify_health_e',
        'p_fortify_magicka_e',
        'p_disease_resistance_e',
        'p_fire_resistance_e',
        'p_frost_resistance_e',
        'p_magicka_resistance_e',
        'p_poison_resistance_e',
        'p_shock_resistance_e',
        'p_restore_fatigue_e',
        'p_restore_health_e',
        'p_restore_magicka_e'


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

local ATTRIBUTES = {
        'strength',
        'intelligence',
        'willpower',
        'agility',
        'speed',
        'endurance',
        'personality',
        'luck',
}



return {
        ARMOR_TYPE = ARMOR_TYPE,
        CLOTHING_TYPE = CLOTHING_TYPE,
        SLOTS = SLOTS,
        slotIndexToName = slotIndexToName,
        RANGED_AMMO = RANGED_AMMO,
        RANGED_WEAPON = RANGED_WEAPON,
        ONE_HAND_WEAPON = ONE_HAND_WEAPON,
        TWO_HAND_WEAPON = TWO_HAND_WEAPON,
        ARRANGED_SLOTS = ARRANGED_SLOTS,
        WEAPON_TYPE_TO_TEXT = WEAPON_TYPE_TO_TEXT,

        SLOT_GRAPH_TO_LIST = SLOT_GRAPH_TO_LIST,
        SKILL_GROUP = SKILL_GROUP,
        TOKENS_REFILL_BASE = TOKENS_REFILL_BASE,
        TOKENS_REFILL_EXTRA = TOKENS_REFILL_EXTRA,
        ATTRIBUTES = ATTRIBUTES,
}
