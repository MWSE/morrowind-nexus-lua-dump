local T = require('openmw.types')

return {
    -- Ids of available self heal spells provided by the addon
    healSelfSpellIds = {
        "fair care self heal huge",
        "fair care self heal high",
        "fair care self heal medium",
        "fair care self heal low",
    },

    -- Ids of available touch heal spells provided by the addon
    healTouchSpellIds = {
        "fair care touch heal huge",
        "fair care touch heal high",
        "fair care touch heal medium",
        "fair care touch heal low",
    },

    -- Names of creature types
    creatureTypes = {
        [T.Creature.TYPE.Creatures] = "Creature",
        [T.Creature.TYPE.Daedra] = "Daedra",
        [T.Creature.TYPE.Humanoid] = "Humanoid",
        [T.Creature.TYPE.Undead] = "Undead",
    },

    -- Names of actor stances
    stances = {
        [T.Actor.STANCE.Nothing] = "Nothing",
        [T.Actor.STANCE.Weapon] = "Weapon",
        [T.Actor.STANCE.Spell] = "Spell",
    }
}
