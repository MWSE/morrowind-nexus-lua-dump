local config = require("StormAtronach.TUD.config").config

local wisdoms = {
    {   saying = "Fear not, for I am watchful",
        effects = {{id = tes3.effect.fortifySkill, skill = tes3.skill.mysticism, min = 1, max =1, duration = config.duration } },
    },
    {   saying = "Better a living coward than a dead hero",
        effects = {{id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, min = 5, max =5, duration = config.duration },
                   {id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.luck, min = 10, max = 10, duration = config.duration } 
                  },
    },
    { saying = "Never back down! Never give an inch!",
        effects = {
            { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, min = 5, max = 5, duration = config.duration },
            { id = tes3.effect.drainSkill, skill = tes3.skill.speechcraft, min = 5, max = 5, duration = config.duration }
        },
    },
    {   saying = "Fish in a dry well if you want to catch an emperor.",
        effects = {
            { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.intelligence, min = 5, max = 5, duration = config.duration }
        }
    },
    {   saying = "I like Bosmer girls and I cannot lie",
        effects = {
            -- This would require scripting for gender/race checks. Placeholder:
            { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 5, max = 5, duration = config.duration }
        }
    },
    {   saying = "Do not die with a clean sword!",
        effects = {
            { id = tes3.effect.fortifyAttack, min = 15, max = 15, duration = config.duration },
            { id = tes3.effect.drainAttribute, attribute = tes3.attribute.agility, min = 5, max = 5, duration = config.duration }
        }
    },
    {   saying = "The blue plates are nice, but the brown ones last longer",
        effects = {
            { id = tes3.effect.fortifySkill, skill = tes3.skill.mercantile, min = 5, max = 5, duration = config.duration }
        }
    },
    {   saying = "Never accept a bargain until you've barted them down",
        effects = {
            { id = tes3.effect.fortifySkill, skill = tes3.skill.mercantile, min = 1, max = 1, duration = config.duration },
            { id = tes3.effect.drainSkill, skill = tes3.skill.speechcraft, min = 1, max = 1, duration = config.duration }
        }
    },
    {   saying = "Do not think before making a judgement. Act on your first impulses!",
        effects = {
            { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, min = 5, max = 5, duration = config.duration },
            { id = tes3.effect.drainAttribute, attribute = tes3.attribute.luck, min = 10, max = 10, duration = config.duration }
        }
    },
    {   saying = "What is the price of a mile?",
        effects = {
            { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, min = 10, max = 10, duration = config.duration }
        }
    },
    {   saying = "In every time; in every place; the deeds of man; remains the same",
        effects = {
            { id = tes3.effect.fortifySkill, skill = tes3.skill.mysticism, min = 2, max = 2, duration = config.duration }
        }
    },
    {   saying = "A man's life of fifty years is nothing compared to the eternity of Aetherius. All men's monuments inevitably crumble. Even the proudest of clans one day find ruin. In this transient world, is there nothing that lasts...?",
        effects = {
            { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, min = 10, max = 10, duration = config.duration },
            { id = tes3.effect.fortifySkill, skill = tes3.skill.destruction, min = 5, max = 5, duration = config.duration },
            { id = tes3.effect.drainSkill, skill = tes3.skill.speechcraft, min = 25, max = 25, duration = config.duration }
        }
    },
    {   saying = "The realm of Resdayn, long divided, was united. Long united, Resdayn was then divided. Such is the history of Resdayn.",
        effects = {
            { id = tes3.effect.fortifySkill, skill = tes3.skill.speechcraft, min = 5, max = 5, duration = config.duration }
        }
    },
    {   saying = "Chop up the kings like lumber!",
        effects = {
            { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.strength, min = 20, max = 20, duration = config.duration },
            { id = tes3.effect.drainAttribute, attribute = tes3.attribute.agility, min = 50, max = 50, duration = config.duration },
            { id = tes3.effect.fortifyAttack, min = 25, max = 25, duration = config.duration },
            { id = tes3.effect.weaknessToNormalWeapons, min = 25, max = 25, duration = config.duration }
        }
    },
    {   saying = "The Empire gave Khajiits rights. Now there's thieves everywhere.",
        effects = {
            { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 10, max = 10, duration = config.duration },
            -- "Khajiit Disposition -5" would require scripting, not a magic effect
            { id = tes3.effect.fortifySkill, skill = tes3.skill.sneak, min = 5, max = 5, duration = config.duration }
        }
    },
    {   saying = "My dearest descendant, may you always feel my warmth and protection.",
        effects = {
            { id = tes3.effect.sanctuary, min = 5, max = 5, duration = config.duration }
        }
    },
   {    saying = "Don't let anyone find your socks!!",
        effects = {
            { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 10, max = 10, duration = config.duration },
            { id = tes3.effect.fortifySkill, skill = tes3.skill.sneak, min = 2, max = 2, duration = config.duration }
        }
    },
{   saying = "Blue Heaven; Yellow Earth.",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.mysticism, min = 1, max = 1, duration = config.duration }
    }
},
{   saying = "Gotta get that BOOM BOOM BOOM",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.personality, min = 10, max = 10, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Woke up one morning, got myself a knife. Mother always said I had a blue moon in my eyes...",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.shortBlade, min = 1, max = 1, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "While everyone else was playing in the fields, I studied the blade.",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.longBlade, min = 1, max = 1, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 10, max = 10, duration = config.duration }
    }
},
{   saying = "While everyone else played with girls, I studied the accounts.",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.mercantile, min = 1, max = 1, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 10, max = 10, duration = config.duration }
    }
},
{   saying = "Now you expect me to protect YOU?",
    effects = {
        { id = tes3.effect.weaknessToNormalWeapons, min = 10, max = 10, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 10, max = 10, duration = config.duration }
    }
},
{   saying = "Make sure to always get eight hours of sleep and brush your teeth!",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.personality, min = 5, max = 5, duration = config.duration },
        { id = tes3.effect.sanctuary, min = 1, max = 1, duration = config.duration }
    }
},
{   saying = "Remember to douse the candles before you leave home!",
    effects = {
        { id = tes3.effect.sanctuary, min = 1, max = 1, duration = config.duration },
        { id = tes3.effect.resistFire, min = 10, max = 10, duration = config.duration }
    }
},
{   saying = "Remember to bring spare underwear.",
    effects = {
        { id = tes3.effect.sanctuary, min = 1, max = 1, duration = config.duration },
        { id = tes3.effect.resistPoison, min = 10, max = 10, duration = config.duration }
    }
},
{   saying = "Don't let anyone take my baby away from me!!",
    effects = {
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 25, max = 25, duration = config.duration },
        { id = tes3.effect.sanctuary, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Don't sweat the small stuff.",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, min = 5, max = 5, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.intelligence, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "The devil is in the details.",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.intelligence, min = 5, max = 5, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Take care of the little things and the big ones will sort themselves out.",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Focus on what you are capable of doing, not what you are incapable of.",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "May God grant you the wisdom to know what you can and cannot do.",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.luck, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "A.E.I.O.U.",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.personality, min = 25, max = 25, duration = config.duration }
    }
},
{   saying = "Run, run like the wind",
    effects = {
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.speed, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Never gonna give you up, never gonna let you down, never gonna run around and desert you!",
    effects = {
        { id = tes3.effect.sanctuary, min = 5, max = 5, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Master of puppets, I'm pulling your strings Twisting your mind and smashing your dreams Blinded by me, you can't see a thing",
    effects = {
        { id = tes3.effect.blind, min = 10, max = 10, duration = config.duration },
        { id = tes3.effect.fortifySkill, skill = tes3.skill.conjuration, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Come with me if you want to live",
    effects = {
        { id = tes3.effect.sanctuary, min = 5, max = 5, duration = config.duration },
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.strength, min = 1, max = 1, duration = config.duration }
    }
},
{   saying = "I'm gonna make him an offer he can't refuse",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.mercantile, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "All your base are belong to us",
    effects = {
        { id = tes3.effect.drainSkill, skill = tes3.skill.speechcraft, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "It builds character",
    effects = {
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.personality, min = 1, max = 1, duration = config.duration }
    }
},
{   saying = "Well, if your friends jumped off a bridge...",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.acrobatics, min = 5, max = 5, duration = config.duration },
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.intelligence, min = 1, max = 1, duration = config.duration }
    }
},
{   saying = "By all means, ignore my decades of experience",
    effects = {
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.intelligence, min = 5, max = 5, duration = config.duration },
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Oh, you're stressed? I survived the Nord invasion with nothing but trama tea and common sense",
    effects = {
        { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, min = 2, max = 2, duration = config.duration },
        { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.strength, min = 2, max = 2, duration = config.duration }
    }
},
{   saying = "Appear weak when you are strong, and strong when you are weak",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.illusion, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Walk softly, and carry a big stick",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.sneak, min = 5, max = 5, duration = config.duration },
        { id = tes3.effect.fortifySkill, skill = tes3.skill.bluntWeapon, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "Try turning it off and on again",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.armorer, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "You'll poke someone's eye out with that",
    effects = {
        { id = tes3.effect.fortifySkill, skill = tes3.skill.spear, min = 5, max = 5, duration = config.duration }
    }
},
{   saying = "I must not fear. Fear is the mind-killer. Fear is the little-death that brings total obliteration."..
             "I will face my fear. I will permit it to pass over me and through me. And when it has gone past, I will turn the inner eye to see its path."..
             "Where the fear has gone there will be nothing. Only I will remain.",
    effects = {
        {id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, min = 10, max = 10, duration = config.duration },
        {id = tes3.effect.fortifySkill, skill = tes3.skill.mysticism, min = 5, max = 5, duration = config.duration }
    }
}
}
return wisdoms