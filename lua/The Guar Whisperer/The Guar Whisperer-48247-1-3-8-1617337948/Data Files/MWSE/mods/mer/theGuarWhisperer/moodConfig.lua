local this = {}

this.happiness = {
    {
        id = "Miserable",
        description = "is completely miserable",
        maxValue = 10,
    },

    {
        id = "Depressed",
        description = "looks quite depressed",
        maxValue = 20,
    },

    {
        id = "Sad",
        description = "could use some affection",
        maxValue = 40,
    },

    {
        id = "Content",
        description = "looks content",
        maxValue = 60,
    },

    {
        id = "Happy",
        description = "looks happy",
        maxValue = 80,
    },

    {
        id = "Joyful",
        description = "is full of joy",
        maxValue = 100,
    },
}


this.affection = {
    {
        id = "Neglected",
        pettingResult = function(animal)
            return string.format(
                "You you pat %s, but %s still looks neglected.",
                animal.refData.name, animal:getHeShe(true)
            )
        end,
        maxValue = 25
    },
    {
        id = "Lonely",
        pettingResult = function(animal)
            return string.format(
                "%s starts to cheer up as you pat %s on the head.",
                animal.refData.name, animal:getHimHer(true)
            )
        end,
        maxValue = 50
    },
    {
        id = "Affectionate",
        pettingResult = function(animal)
            return string.format(
                "%s purrs loudly as you give %s a scratch behind the ears.",
                animal.refData.name, animal:getHimHer(true)
            )
        end,
        maxValue = 75
    },
    {
        id = "Very Affectionate",
        pettingResult = function(animal)
            return string.format(
                "%s snuggles you affectionately.",
                animal.refData.name
            )
        end,
        maxValue = 100
    },
}
this.defaultAffection = 20

this.trust = {
    {
        id = "Untrusting",
        description = "doesn't trust you at all",
        minValue = 0,
        maxValue = 20
    },
    {
        id = "Wary",
        description = "is wary of you",
        skillDescription = "will now move or follow you and attack enemies at your command.",
        minValue = 20,
        maxValue = 40
    },
    {
        id = "Familiar",
        description = "has grown familiar with you",
        skillDescription = "can now fetch, harvest and steal items for you.",
        minValue = 40,
        maxValue = 60
    },
    {
        id = "Trusting",
        description = "is beginning to trust you",
        skillDescription = "can now wear a backpack.",
        minValue = 60,
        maxValue = 80
    },
    {
        id = "Very Trusting",
        description = "trusts you unconditionally",
        skillDescription = "can now breed with other guars.",
        minValue = 80,
        maxValue = 100
    },
}
this.defaultTrust = 10
this.skillRequirements = {
    follow = this.trust[2].minValue,
    attack = this.trust[2].minValue,
    eat = this.trust[2].minValue,
    fetch = this.trust[3].minValue,
    charm = this.trust[3].minValue,
    pack = this.trust[4].minValue,
    breed = this.trust[5].minValue
}


this.hunger = {
    {
        minValue = 0,
        maxValue = 20,
        description = "starving"
    },
    {
        minValue = 20,
        maxValue = 40,
        description = "very hungry"
    },
    {
        minValue = 40,
        maxValue = 60,
        description = "hungry"
    },
    {
        minValue = 60,
        maxValue = 80,
        description = "peckish"
    },
    {
        minValue = 80,
        maxValue = 100,
        description = "full"
    },
}



this.defaultHunger = 50
this.defaultPlay = 20

return this 