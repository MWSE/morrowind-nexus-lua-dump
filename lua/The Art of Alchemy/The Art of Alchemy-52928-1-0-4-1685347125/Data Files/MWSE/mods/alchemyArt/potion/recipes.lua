local common = require("alchemyArt.common")

local function createConstantEffect(params)
    local constantEffect = tes3.createObject{
        id = params.id,
        objectType = tes3.objectType.spell,

    }
    constantEffect.name = params.name
    constantEffect.castType = tes3.spellType.ability
    -- constantEffect.isActiveCast = false
    local i = 1
    for _, effect in ipairs(params.effects) do
        if effect.duration == 0 then
            constantEffect.effects[i].id = effect.id
            constantEffect.effects[i].attribute = effect.attribute or -1
            constantEffect.effects[i].skill = effect.skill or -1
            constantEffect.effects[i].min = effect.magnitude
            constantEffect.effects[i].max = effect.magnitude
            constantEffect.effects[i].duration = effect.duration
            constantEffect.effects[i].radius = effect.radius or 0
            constantEffect.effects[i].rangeType = effect.rangeType or tes3.effectRange.self
            i = i + 1
        end
        -- constantEffect.effects[i].object = tes3.getMagicEffect(effect.id)
    end

    return constantEffect
end

local attributeEffect = {
    [tes3.attribute.strength] = {
        [tes3.effect.fortifyAttack] = true,
        [tes3.effect.fortifyFatigue] = true,
        --[tes3.effect.restoreHealth] = true, ???
        --[tes3.effect.feather] = true, --???
        [tes3.effect.shield] = true,  --???
    },
    [tes3.attribute.intelligence] = {
        [tes3.effect.fortifyMaximumMagicka] = true,
        [tes3.effect.fortifyMagicka] = true,
        [tes3.effect.detectAnimal] = true,
        [tes3.effect.detectEnchantment] = true,
    },
    [tes3.attribute.willpower] = {
        [tes3.effect.resistMagicka] = true,
        [tes3.effect.restoreMagicka] = true,
    },
    [tes3.attribute.agility] = {
        [tes3.effect.fortifyAttack] = true,
        [tes3.effect.sanctuary] = true,
        [tes3.effect.chameleon] = true,
        [tes3.effect.jump] = true,
        [tes3.effect.slowFall] = true
        --[tes3.effect.detectAnimal] = true, ???
    },
    [tes3.attribute.speed] = {
        --[tes3.effect.sanctuary] = true,
        [tes3.effect.feather] = true,
        [tes3.effect.fortifyFatigue] = true,
    },
    [tes3.attribute.endurance] = {
        [tes3.effect.restoreHealth] = true,
        [tes3.effect.restoreFatigue] = true,
        [tes3.effect.fortifyHealth] = true,
        [tes3.effect.feather] = true,
        [tes3.effect.shield] = true,
    },
    [tes3.attribute.personality] = {
        [tes3.effect.sanctuary] = true,
        [tes3.effect.fortifyHealth] = true,
        [tes3.effect.restoreFatigue] = true
    },
    [tes3.attribute.luck] = {
    },
}

-- endurance and speed: slowFall
-- endurance and strength: restoreHealth
-- endurance and agility: jump?
-- endurance and intelligence: fortifyMaxMagicka?
-- endurance and willpower: resistMagicka
-- endurance and personality: fortifyHealth

-- strength and agility: fortifyAttack
-- strength and speed: feather
-- strength and personality: fortifyFatigue
-- strength and willpower: shield
-- strength and intelligence

-- agility and speed: restoreFatigue
-- agility and personality: sanctuary
-- agility and willpower: detectAnimal
-- agility and intelligence: chameleon?

-- speed and intelligence: telekinesis
-- speed and personality
-- speed and willpower

-- willpower and personality
-- willpower and intelligence: restoreMagicka

-- personality and intelligence: fortifyMagicka


local effects = {

    AA_SP_Neurotoxin = {
        {
            id = tes3.effect.paralyze,
            duration = 60,
        },
        {
            id = tes3.effect.drainFatigue,
            magnitude = 300,
            duration = 150,
        },
        {
            id = tes3.effect.drainHealth,
            magnitude = 150,
            duration = 150
        },
        {
            id = tes3.effect.damageFatigue,
            magnitude = 2,
            duration = 0
        },
        {
            id = tes3.effect.damageHealth,
            magnitude = 1,
            duration = 150
        }
    },

    AA_SP_DeadlyPoison = {
        {
            id = tes3.effect.poison,
            magnitude = 1,
            duration = 0,
        },
        {
            id = tes3.effect.damageHealth,
            magnitude = 1,
            duration = 0,
        },
        {
            id = tes3.effect.fireDamage,
            magnitude = 1,
            duration = 0
        },
        {
            id = tes3.effect.frostDamage,
            magnitude = 1,
            duration = 0
        },
        {
            id = tes3.effect.shockDamage,
            magnitude = 1,
            duration = 0
        }
    },

    AA_SP_Invulnerability = {
        {
            id = tes3.effect.sanctuary,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.shield,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.absorbMagicka,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.reflect,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.resistMagicka,
            magnitude = 50,
            duration = 150
        },
    },

    AA_SP_AquaForm = {
        {
            id = tes3.effect.waterBreathing,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.swiftSwim,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.speed,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.restoreFatigue,
            magnitude = 15,
            duration = 150
        },
    },
    AA_SP_Acrobat = { -- jump
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.agility,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.endurance,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.jump,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.slowFall,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.feather,
            magnitude = 100,
            duration = 300
        },
    },
    AA_SP_Agent = { -- sanctuary
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.personality,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.agility,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.sanctuary,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.chameleon,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.restoreFatigue,
            magnitude = 4,
            duration = 600
        },
    },
    AA_SP_Archer = { -- fortifyFatinue?
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.agility,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.strength,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttack,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyFatigue,
            magnitude = 70,
            duration = 212
        },
        {
            id = tes3.effect.restoreFatigue, -- jump?
            magnitude = 2,
            duration = 0
        },
    },
    AA_SP_Assassin = { -- chameleon?
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.speed,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.intelligence,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttack,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.chameleon,
            magnitude = 70,
            duration = 212
        },
        {
            id = tes3.effect.detectAnimal,
            magnitude = 2,
            duration = 0
        },
    },
    AA_SP_Barbarian = { -- constant strength?
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.strength,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.speed,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.feather,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyFatigue,
            magnitude = 100,
            duration = 300
        },
        {
            id = tes3.effect.shield,
            magnitude = 50,
            duration = 150
        },
    },
    AA_SP_Bard = { -- constant personality
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.personality,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.intelligence,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.luck,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.sanctuary,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyFatigue, -- restore
            magnitude = 100,
            duration = 300
        },
    },
    AA_SP_Battlemage = { -- intelligence
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.intelligence,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.strength,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyMaximumMagicka,
            magnitude = 5,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttack,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.restoreMagicka,
            magnitude = 4,
            duration = 300
        },
    },
    AA_SP_Crusader = { -- resistMagicka
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.willpower,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.strength,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.shield,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttack,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.resistMagicka,
            magnitude = 50,
            duration = 150
        },
    },
    AA_SP_Healer = { -- willpower
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.willpower,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.personality,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyMaximumMagicka, -- restoreMagicka
            magnitude = 5,
            duration = 150
        },
        {
            id = tes3.effect.sanctuary,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.detectAnimal,
            magnitude = 4,
            duration = 300
        },
    },
    AA_SP_Knight = { -- fortifyAttack
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.strength,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.personality,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttack,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.shield,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyHealth,
            magnitude = 70,
            duration = 212
        },
    },
    AA_SP_Monk = { -- agility
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.agiity,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.willpower,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttack,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.sanctuary,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.restoreFatigue,
            magnitude = 70,
            duration = 212
        },
    },
    AA_SP_Pilgrim = { -- endurance/ fort health
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.personality,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.endurance,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyHealth,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.sanctuary,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.shield,
            magnitude = 4,
            duration = 600
        },
    },
    AA_SP_Rogue = { -- speed
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.speed,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.personality,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyFatigue,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.sanctuary,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttack,
            magnitude = 50,
            duration = 150
        },
    },
    AA_SP_Scout = { -- feather
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.speed,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.endurance,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.restoreFatigue, -- restore
            magnitude = 8,
            duration = 300
        },
        {
            id = tes3.effect.shield,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.feather,
            magnitude = 50,
            duration = 150
        },
    },
    AA_SP_Sorcerer = { -- maxMagicka
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.intelligence,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.endurance,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyMagicka,
            magnitude = 70,
            duration = 212
        },
        {
            id = tes3.effect.shield,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyMaximumMagicka,
            magnitude = 5,
            duration = 150
        },
    },
    AA_SP_Spellsword = {
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.willpower,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.endurance,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.restoreMagicka,
            magnitude = 4,
            duration = 150
        },
        {
            id = tes3.effect.shield,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.resistMagicka,
            magnitude = 50,
            duration = 150
        },
    },
    AA_SP_Witchhunter = {
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.intelligence,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.agility,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.detectAnimal,
            magnitude = 70,
            duration = 212
        },
        {
            id = tes3.effect.sanctuary,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.resistMagicka,
            magnitude = 5,
            duration = 150
        },
    },
    AA_SP_LegendaryWarrior = {
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.strength,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.endurance,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttack,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.shield,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.restoreHealth,
            magnitude = 1,
            duration = 0
        },
    },
    AA_SP_Nightblade = {
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.willpower,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.speed,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.chameleon,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.feather,
            magnitude = 100,
            duration = 300
        },
        {
            id = tes3.effect.telekinesis, -- detect
            magnitude = 50,
            duration = 150
        },
    },
    AA_SP_MasterThief = {
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.agility,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.speed,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.chameleon,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.feather,
            magnitude = 100,
            duration = 300
        },
        {
            id = tes3.effect.restoreFatigue, -- restoreFatigu
            magnitude = 2,
            duration = 0
        },
    },
    AA_SP_Archmage = {
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.intelligence,
            magnitude = 50,
            duration = 150,
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.willpower,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyMagicka,
            magnitude = 70,
            duration = 212
        },
        {
            id = tes3.effect.fortifyMaximumMagicka,
            magnitude = 0.5,
            duration = 0
        },
        {
            id = tes3.effect.restoreMagicka,
            magnitude = 1,
            duration = 0
        },
    },
    AA_SP_JackOfAllTrades = {
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.strength,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.endurance,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.agility,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.speed,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.intelligence,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.willpower,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.personality,
            magnitude = 50,
            duration = 150
        },
        {
            id = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.luck,
            magnitude = 20,
            duration = 150
        }
    }

}

local recipes = {

    -- potionId = {
    --     name = "potionName",
    --     isEpic = true, 
    --     create = true, -- whether to create a new potion or use already existent one in the CS
    --     icon = "m\\Tx_potion_exclusive_01.tga", -- Optional
    --     mesh = "m\\Misc_Potion_Exclusive_01.nif", -- Optional
    --     value = 2500,
    --     weight = 2,
    --     effects = { -- list of effects required to brew this potion
    --         {
    --             id = tes3.effect.id,
    --             attribute = tes3.attribute.id,
    --             minPower = 1200 --minimal amount of this effect power required to brew this potion default is 0
    --             magnitude = 50, --resulting magnitude of this potion. Required if create = true
    --             duration = 150, --resulting duration of this potion. Required if create = true
    --         },
    --         ...
    --     },
    --     components = { -- Optional. Array of 2 - 3 ingredients or 2 potions. Components only from which this potion can be brewed.
    --         component1Id,
    --         component2Id
    --     },
    --     onConsumed = function() end -- potion consumed callback
    -- }
    -- AA_SP_Invulnerability = {
    --     name = common.dictionary.potionInvulnerability,
    --     isEpic = true,
    --     create = true,
    --     effects = {
    --         
    --     },
    --     onConsumed = function(e)
    --         createConstantEffect{id = "AA_Const_AM", name = common.dictionary.potionArchmage, effects = recipes.potions.AA_SP_Archmage.effects}
    --         tes3.addSpell{reference = e.reference, spell = "AA_Const_AM"}
    --     end
    -- },

    -- AA_SP_Archmage = {
    --     name = common.dictionary.potionArchmage,
    --     isEpic = true,
    --     create = true,
    --     effects = effects.AA_SP_Archmage,
    --     onConsumed = function(e)
    --         createConstantEffect{id = "AA_Const_AM", name = common.dictionary.potionArchmage, effects = effects.AA_SP_Archmage}
    --         tes3.addSpell{reference = e.reference, spell = "AA_Const_AM"}
    --     end
    -- },

    AA_SP_JackOfAllTrades = {
        name = common.dictionary.potionJackOfAllTrades,
        isEpic = true,
        create = true,
        effects = effects.AA_SP_JackOfAllTrades,
        onConsumed = function(e)
            createConstantEffect{id = "AA_Const_JAL", name = common.dictionary.potionJackOfAllTrades, effects = effects.AA_SP_JackOfAllTrades}
            tes3.addSpell{reference = e.reference, spell = "AA_Const_JAL"}
        end
    }
}

return recipes