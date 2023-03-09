local defaultConfig = {
    modEnabled = true,
    alchemyRebalance = true,
    scaleCureCommon = true,
    scaleCureBlight = true,
    scaleCurePoison = true,
    scaleCureParalyzation = true,
    defaultMagnitude = {
        [tostring(tes3.effect.cureCommonDisease)] = {
            [tostring(tes3.objectType.alchemy)] = 50,
            [tostring(tes3.objectType.enchantment)] = 100,
            [tostring(tes3.objectType.spell)] = 100
        },
        [tostring(tes3.effect.cureBlightDisease)] = {
            [tostring(tes3.objectType.alchemy)] = 35,
            [tostring(tes3.objectType.enchantment)] = 100,
            [tostring(tes3.objectType.spell)] = 100
        },
        [tostring(tes3.effect.curePoison)] = {
            [tostring(tes3.objectType.alchemy)] = 100,
            [tostring(tes3.objectType.enchantment)] = 100,
            [tostring(tes3.objectType.spell)] = 100
        },
        [tostring(tes3.effect.cureParalyzation)] = {
            [tostring(tes3.objectType.alchemy)] = 100,
            [tostring(tes3.objectType.enchantment)] = 100,
            [tostring(tes3.objectType.spell)] = 100
        }
    }
}

local mwseConfig = mwse.loadConfig("cureMagnitude", defaultConfig)

return mwseConfig