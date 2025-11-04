local defaultConfig = {
    enabled = true,
    baseChance = 50,
    minDamage = 15,
    enableCreatures = true,
    enableFists = true,
    enableShortBlade = true,
    enableLongBladeOneHand = true,
    enableLongBladeTwoHand = true,
    enableBluntOneHand = false,
    enableBluntTwoClose = false,
    enableBluntTwoWide = false,
    enableSpearTwoWide = true,
    enableAxeOneHand = true,
    enableAxeTwoHand = true,
    enableMarksmanBow = true,
    enableMarksmanCrossbow = true,
    enableMarksmanThrown = true,
}

local mwseConfig = mwse.loadConfig("dismember", defaultConfig)

return mwseConfig;