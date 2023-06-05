local effects = {}

effects.override = {
    [tes3.effect.poison] = {
        duration = 5,
        powerDiv = 3,
    },
    [tes3.effect.fireDamage] = {
        duration = 5,
        powerDiv = 6,
    },
    [tes3.effect.frostDamage] = {
        duration = 5,
        powerDiv = 6,
    },
    [tes3.effect.shockDamage] = {
        duration = 5,
        powerDiv = 6,
    },
    [tes3.effect.damageHealth] = {
        duration = 5,
        powerDiv = 6,
    },
    [tes3.effect.damageMagicka] = {
        duration = 5,
        powerDiv = 6,
    },
    [tes3.effect.damageFatigue] = {
        duration = 5,
        powerDiv = 3,
    },
    [tes3.effect.drainMagicka] = {
        powerDiv = 0.5
    },
    [tes3.effect.drainHealth] = {
        powerDiv = 0.5
    },
    [tes3.effect.drainFatigue] = {
        powerDiv = 0.25
    },
    [tes3.effect.damageAttribute] = {
        duration = 0,
        powerDiv = 20,
    },
    [tes3.effect.damageSkill] = {
        duration = 0,
        powerDiv = 20,
    },
    [tes3.effect.restoreHealth] = {
        duration = 5,
        powerDiv = 6,
    },
    [tes3.effect.restoreFatigue] = {
        duration = 5,
        powerDiv = 3,
    },
    [tes3.effect.restoreMagicka] = {
        duration = 5,
        powerDiv = 6,
    },
    [tes3.effect.restoreAttribute] = {
        duration = 0,
        powerDiv = 20,
    },
    [tes3.effect.restoreSkill] = {
        duration = 0,
        powerDiv = 20,
    },
    [tes3.effect.fortifyMaximumMagicka] = {
        powerDiv = 4
    },
    [tes3.effect.fortifyMagicka] = {
        powerDiv = 0.5
    },
    [tes3.effect.fortifyHealth] = {
        powerDiv = 0.5
    },
    [tes3.effect.fortifyFatigue] = {
        powerDiv = 0.25
    },
    [tes3.effect.burden] = {
        powerDiv = 0.25
    },
    [tes3.effect.feather] = {
        powerDiv = 0.25
    },
    [tes3.effect.sound] = {
        powerDiv = 0.25
    }
}

effects.combinations = {

    -- Damage

    [tes3.effect.poison] = {
        [tes3.effect.weaknesstoPoison] = true,
        [tes3.effect.fireDamage] = true,
        [tes3.effect.frostDamage] = true,
        [tes3.effect.shockDamage] = true,
        [tes3.effect.damageHealth] = true
    },

    [tes3.effect.fireDamage] = {
        [tes3.effect.weaknesstoFire] = true,
        [tes3.effect.frostDamage] = true,
        [tes3.effect.shockDamage] = true,
        [tes3.effect.damageHealth] = true
    },

    [tes3.effect.frostDamage] = {
        [tes3.effect.weaknesstoFrost] = true,
        [tes3.effect.shockDamage] = true,
        [tes3.effect.damageHealth] = true
    },

    [tes3.effect.shockDamage] = {
        [tes3.effect.weaknesstoShock] = true,
        [tes3.effect.damageHealth] = true
    },

    [tes3.effect.damageHealth] = {
        [tes3.effect.weaknesstoMagicka] = true,
        [tes3.effect.damageFatigue] = true,
        [tes3.effect.damageMagicka] = true,
        [tes3.effect.drainHealth] = true
    },
    [tes3.effect.damageMagicka] = {
        [tes3.effect.weaknesstoMagicka] = true,
        [tes3.effect.drainMagicka] = true,
        [tes3.effect.damageFatigue] = true,
    },

    [tes3.effect.damageFatigue] = {
        [tes3.effect.weaknesstoMagicka] = true,
        [tes3.effect.drainFatigue] = true,
    },

    [tes3.effect.fortifyAttribute] = {
        [tes3.effect.fortifyAttribute] = true,
        -- {
        --     [tes3.attribute.strength] = true,
        --     [tes3.attribute.intelligence] = true,
        --     [tes3.attribute.willpower] = true,
        --     [tes3.attribute.agility] = true,
        --     [tes3.attribute.speed] = true,
        --     [tes3.attribute.endurance] = true,
        --     [tes3.attribute.personality] = true,
        --     [tes3.attribute.luck] = true,
        -- },
        [tes3.effect.fortifySkill] = true,
        [tes3.effect.fortifyHealth] = true,
        [tes3.effect.fortifyFatigue] = true,
        [tes3.effect.fortifyMagicka] = true
    },

    [tes3.effect.restoreFatigue] = {
        [tes3.effect.fortifyFatigue] = true,
    },

    [tes3.effect.restoreHealth] = {
        [tes3.effect.fortifyHealth] = true,
    },

    [tes3.effect.restoreMagicka] = {
        [tes3.effect.fortifyMagicka] = true,
        [tes3.effect.fortifyMaximumMagicka] = true,
    },

    [tes3.effect.swiftSwim] = {
        [tes3.effect.waterBreathing] = true
    },

    -- Magical

    [tes3.effect.spellAbsorption] = {
        [tes3.effect.reflect] = true,
        [tes3.effect.resistMagicka] = true
    },

    [tes3.effect.reflect] = {
        [tes3.effect.resistMagicka] = true
    },


    -- Elemental

    [tes3.effect.fireShield] = {
        [tes3.effect.resistFire] = true
    },

    [tes3.effect.frostShield] = {
        [tes3.effect.resistFrost] = true
    },

    [tes3.effect.lightningShield] = {
        [tes3.effect.resistShock] = true
    },

    -- Physical

    [tes3.effect.shield] = {
        [tes3.effect.sanctuary] = true,
        [tes3.effect.resistNormalWeapons] = true,
    },

    [tes3.effect.sanctuary] = {
        [tes3.effect.resistNormalWeapons] = true,
    },
    

    -- Resistances to damage

    [tes3.effect.resistNormalWeapons] = {
        [tes3.effect.resistFrost] = true,
        [tes3.effect.resistShock] = true,
        [tes3.effect.resistFire] = true,
        [tes3.effect.resistMagicka] = true,
        [tes3.effect.resistPoison] = true,
    },

    [tes3.effect.resistFrost] = {
        [tes3.effect.resistShock] = true,
        [tes3.effect.resistFire] = true,
        [tes3.effect.resistMagicka] = true,
        [tes3.effect.resistPoison] = true,
    },

    [tes3.effect.resistShock] = {
        [tes3.effect.resistFire] = true,
        [tes3.effect.resistMagicka] = true,
        [tes3.effect.resistPoison] = true,
    },

    [tes3.effect.resistFire] = {
        [tes3.effect.resistMagicka] = true,
        [tes3.effect.resistPoison] = true,
    },

    [tes3.effect.resistMagicka] = {
        [tes3.effect.resistPoison] = true,
    },

    -- Resistances to status effects

    [tes3.effect.resistCommonDisease] = {
        [tes3.effect.resistBlightDisease] = true,
        [tes3.effect.resistCorprusDisease] = true,
        [tes3.effect.resistParalysis] = true,
        [tes3.effect.resistPoison] = true,
    },

    [tes3.effect.resistBlightDisease] = {
        [tes3.effect.resistCorprusDisease] = true,
        [tes3.effect.resistParalysis] = true,
        [tes3.effect.resistPoison] = true,
    },

    [tes3.effect.resistCorprusDisease] = {
        [tes3.effect.resistParalysis] = true,
        [tes3.effect.resistPoison] = true,
    },

    [tes3.effect.resistParalysis] = {
        [tes3.effect.resistPoison] = true,
    },

    [tes3.effect.jump] = {
        [tes3.effect.slowFall] = true,
        [tes3.effect.feather] = true,
    },

    [tes3.effect.slowFall] = {
        [tes3.effect.feather] = true,
    },

    [tes3.effect.blind] = {
        [tes3.effect.sound] = true,
        [tes3.effect.burden] = true, --???
    },

    [tes3.effect.fortifyAttack] = {
        [tes3.effect.sanctuary] = true,
        [tes3.effect.fortifyAttribute] = true, --???
    },


}

-- Combinations are symmetrical

for e1, effectSet in pairs(effects.combinations) do
    for e2, _ in pairs(effectSet) do
        effects.combinations[e2] = effects.combinations[e2] or {}
        effects.combinations[e2][e1] = true
    end
end

effects.getModifier = function (effectArray)

    local allCombinations = {
        -- [1] = {effect1 = true, effect2 = true, effect3 = true},
        -- [2] = {effect3 = true, effect4 = true}
        -- ...
    }
    local modifier = 0

    -- mwse.log("Effect Combinations Modifier")

    for i, effect in ipairs(effectArray) do

        mwse.log(effect.name)

        for _, effectSet in ipairs(allCombinations) do
            if effectSet[effect.id] then
                modifier = modifier + 1
            end
        end

        local newCombination = effects.combinations[effect.id]
        if newCombination then
            allCombinations[i] = newCombination
        end
    end
    -- mwse.log("Modifier: %s", modifier)
    return modifier
end

-- local test_alchemy = {
--     {
--         name = "Test0",
--         effects = {
--             {
--                 name = "Jump",
--                 id = tes3.effect.jump,
--             },
--             {
--                 name = "Blind",
--                 id = tes3.effect.blind
--             }

--         }
--     },

--     {
--         name = "Test1",
--         effects = {
--             {
--                 name = "Raise Attribute",
--                 id = tes3.effect.fortifyAttribute,
--             },
--             {
--                 name = "Raise Attribute",
--                 id = tes3.effect.fortifyAttribute
--             },
--             {
--                 name = "Raise Attribute",
--                 id = tes3.effect.fortifyAttribute
--             }

--         }
--     },

--     {
--         name = "Test2",
--         effects = {
--             {
--                 name = "Resist Fire",
--                 id = tes3.effect.resistFire,
--             },
--             {
--                 name = "Fire Shield",
--                 id = tes3.effect.fireShield
--             },
--             {
--                 name = "Resist Frost",
--                 id = tes3.effect.resistFrost
--             }

--         }
--     },

--     {
--         name = "Test3",
--         effects = {
--             {
--                 name = "Jump",
--                 id = tes3.effect.jump,
--             },
--             {
--                 name = "Feather",
--                 id = tes3.effect.feather
--             },
--             {
--                 name = "Slow Fall",
--                 id = tes3.effect.slowFall
--             }

--         }
--     },

--     {
--         name = "Test4",
--         effects = {
--             {
--                 name = "Resist Fire",
--                 id = tes3.effect.resistFire,
--             },
--             {
--                 name = "Fire Shield",
--                 id = tes3.effect.fireShield
--             },
--             {
--                 name = "Frost Shield",
--                 id = tes3.effect.frostShield
--             },

--             {
--                 name = "Resist Frost",
--                 id = tes3.effect.resistFrost,
--             },

--         }
--     },

--     {
--         name = "Test4",
--         effects = {
--             {
--                 name = "Fire Shield",
--                 id = tes3.effect.fireShield
--             },
--             {
--                 name = "Frost Shield",
--                 id = tes3.effect.frostShield
--             },

--             {
--                 name = "Resist Fire",
--                 id = tes3.effect.resistFire,
--             },

--             {
--                 name = "Resist Frost",
--                 id = tes3.effect.resistFrost,
--             },

--         }
--     },

--     {
--         name = "Test5",
--         effects = {
--             {
--                 name = "Resist Poison",
--                 id = tes3.effect.resistPoison
--             },
--             {
--                 name = "Resist Shock",
--                 id = tes3.effect.resistShock
--             },

--             {
--                 name = "Resist Fire",
--                 id = tes3.effect.resistFire,
--             },

--             {
--                 name = "Resist Common Disease",
--                 id = tes3.effect.resistCommonDisease,
--             },

--         }
--     },

--     {
--         name = "Test6",
--         effects = {
--             {
--                 name = "Resist Poison",
--                 id = tes3.effect.resistPoison
--             },
--             {
--                 name = "Resist Shock",
--                 id = tes3.effect.resistShock
--             },

--             {
--                 name = "Resist Fire",
--                 id = tes3.effect.resistFire,
--             },

--             {
--                 name = "Resist Frost",
--                 id = tes3.effect.resistFrost,
--             },

--         }
--     },
-- }

-- for i, alch in ipairs(test_alchemy) do
--     effects.getModifier(alch.effects)
-- end


return effects