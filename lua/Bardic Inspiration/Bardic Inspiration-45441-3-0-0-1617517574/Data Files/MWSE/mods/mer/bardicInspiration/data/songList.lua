
local Song = require("mer.bardicInspiration.Song")
local messages = require("mer.bardicInspiration.messages.messages")

local songList = {
    beginner = {
        {   
            name = "Sujamma Nights",
            path = "mer_bard/beg/1.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Beneath the Mushroom Tree",
            path = "mer_bard/beg/2.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Legion March",
            path = "mer_bard/beg/3.mp3",
            difficulty = "beginner",
        },
        {   
            name = "When the Heather Blooms",
            path = "mer_bard/beg/4.mp3",
            difficulty = "beginner",
        },
        {   
            name = "By the Light of Mara",
            path = "mer_bard/beg/5.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Take me, Elsewyr",
            path = "mer_bard/beg/6.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Night Falls over Balmora",
            path = "mer_bard/beg/7.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Stendarr the Merciful",
            path = "mer_bard/beg/8.mp3",
            difficulty = "beginner",
        },
        {   
            name = "I fell in Love with an Argonian",
            path = "mer_bard/beg/9.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Ode to Hla Oad",
            path = "mer_bard/beg/10.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Fly me to Secunda",
            path = "mer_bard/beg/11.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Over the Fields of Kummu",
            path = "mer_bard/beg/12.mp3",
            difficulty = "beginner",
        },
        {   
            name = "The Lonely Scrib",
            path = "mer_bard/beg/13.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Moon Sugar Baby",
            path = "mer_bard/beg/14.mp3",
            difficulty = "beginner",
        },
        {   
            name = "The Witch and the Nord's Wardrobe",
            path = "mer_bard/beg/15.mp3",
            difficulty = "beginner",
        },
        {   
            name = "Valley of the Wind",
            path = "mer_bard/beg/16.mp3",
            difficulty = "beginner",
        },
    },
    intermediate = {
        {   
            name = "Kagouti Cutie",
            path = "mer_bard/int/1.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "Flight of the Cliff Racers",
            path = "mer_bard/int/2.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "Dream Sleeves",
            path = "mer_bard/int/3.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "Nocturnal Awaits",
            path = "mer_bard/int/4.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "The Girl from Ald Velothi",
            path = "mer_bard/int/5.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "The Little Kwama that Could",
            path = "mer_bard/int/6.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "The Perplexed Guar",
            path = "mer_bard/int/7.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "Imperial Stallion",
            path = "mer_bard/int/8.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "The Adventure Begins",
            path = "mer_bard/int/9.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "Harvest's End",
            path = "mer_bard/int/10.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "Kwama Hive",
            path = "mer_bard/int/11.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "Howl of the Wind",
            path = "mer_bard/int/12.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "A Trip to the Market",
            path = "mer_bard/int/13.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "The Road to Balmora",
            path = "mer_bard/int/14.mp3",
            difficulty = "intermediate",
        },
        {   
            name = "Ancestor Spirit",
            path = "mer_bard/int/15.mp3",
            difficulty = "intermediate",
        },
    },
    advanced = {
        {   
            name = "Clockwork City",
            path = "mer_bard/pro/1.mp3",
            difficulty = "advanced",
        },
        {   
            name = "The Warrior Poet",
            path = "mer_bard/pro/2.mp3",
            difficulty = "advanced",
        },
        {   
            name = "Ash Fall",
            path = "mer_bard/pro/3.mp3",
            difficulty = "advanced",
        },
        {   
            name = "Gigue",
            path = "mer_bard/pro/4.mp3",
            difficulty = "advanced",
        },
        {   
            name = "Falling Ash",
            path = "mer_bard/pro/5.mp3",
            difficulty = "advanced",
        },
        {   
            name = "Prelude No.1",
            path = "mer_bard/pro/6.mp3",
            difficulty = "advanced",
        },
        {   
            name = "Fantasia",
            path = "mer_bard/pro/6.mp3",
            difficulty = "advanced",
        },
    }
}
return songList