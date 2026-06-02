-- Armor material bonuses in this file apply at full strength when the target
-- temperature before these bonuses is below zero, and at 50% strength when it
-- is zero or above.
local M = {
    keywordOrder = {
        'bear',
		'wolf',
        'fur',
        'leather',
        'hide',
    },
    fur = {
        cuirass = 10,
        helmet = 10,
        greaves = 10,
        boots = 10,
        gauntlet = 5,
        pauldron = 5,
    },
    bear = {
        cuirass = 20,
        helmet = 15,
        greaves = 20,
        boots = 15,
        gauntlet = 7.5,
        pauldron = 10,
    },
    wolf = {
        cuirass = 15,
        helmet = 10,
        greaves = 15,
        boots = 10,
        gauntlet = 7.5,
        pauldron = 7.5,
    },
    leather = {
        cuirass = 10,
        helmet = 10,
        greaves = 10,
        boots = 10,
        gauntlet = 5,
        pauldron = 5,
    },
    hide = {
        cuirass = 10,
        helmet = 10,
        greaves = 10,
        boots = 10,
        gauntlet = 5,
        pauldron = 5,
    },
}

return M
