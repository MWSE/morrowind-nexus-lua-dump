local this = {}

-- refactor: from skills.lua
this.name = "ashlander_theology"
this.fullName = "Ashlander Theology"
this.specialization = tes3.specialization.magic
this.attribute = tes3.attribute.endurance
this.icon = "Icons\\PRAY\\ashlander.dds"
this.sound = "PRAY\\ash_pray.wav"
this.description = (
    "The Ashlander Theology skill determines your knowledge of traditional prayers and rituals of the Ashlanders of Morrowind."
)

this.knowledgeRequirement = function()
    return tes3.getJournalIndex{ id = "A2_1_MeetSulMatuul" } >= 44
end


this.recipes = {
    {
        name = "Acknowledge the Ancestors",
        id = "basic_ancestor_prayer",
        handler = "Ashlander Prayers",
        skillReq = 10,
        skill = "ashlander_theology",
        skillProgress = 30,
        description = "Acknowledge the memories of our ancestors\n\n    Summon Ancestral Ghost, 6 minutes",
        image = "Icons\\PRAY\\art\\wise_woman.dds",
        knowledgeRequirement = function ()
            return tes3.player.data.hasReadAshlanderLit or tes3.getJournalIndex{ id = "A2_1_MeetSulMatuul" } >= 44
        end,
        spellEffects = {
            {
                id = 106, --summonAncestralGhost
                duration = 360,
            }
        },
        text = "I pray for the herder\nThat whistles to his guar at play."
    },
    {
        name = "Venerate the Ancestors",
        id = "ancestor_prayer",
        handler = "Ashlander Prayers",
        skillReq = 10,
        skill = "ashlander_theology",
        description = "Praise the memories of our ancestors\n\n    Summon Ancestral Ghost, 24 minutes",
        image = "Icons\\PRAY\\art\\wise_woman.dds",
        spellEffects = {
            {
                id = 106, --summonAncestralGhost
                duration = 1440,
            }
        },
        text = "I pray for the herder\nThat whistles to his guar at play.\n\nI pray for the hunter\nThat stalks the white walkers.\n\nI pray for the wise one\nThat seeks under the hill,\n\nAnd the wife who wishes\nFor one last touch of her dead child's hand."
    },
    {
        name = "Wanderer Under Moon-and-Star",
        id = "wanderer_prayer",
        handler = "Ashlander Prayers",
        skillReq = 12,
        skill = "ashlander_theology",
        description = "See in the darkness by the light of Moon-and-Star\n\n    Night Eye 20 - 40",
        image = "Icons\\PRAY\\art\\ashland_scout.dds",
        spellEffects = {
            {
                id = 43, --nightEye
                duration = 720,
                min = 20,
                max = 40,
            }
        },
        text = "Never shall I yield my home and hearth.\n\nAnd from my tears shall spring forth\n\nThe flowers of grassland springs."
    },
    {
        name = "Stride 'Cross the Ash-Wastes",
        id = "feather_prayer",
        handler = "Ashlander Prayers",
        skillReq = 14,
        skill = "ashlander_theology",
        description = "Travel light and quietly as our kin of old\n\n    Feather 10 - 30\n    Fortify Sneak 10 - 30",
        image = "Icons\\PRAY\\art\\ashland_vista.dds",
        spellEffects = {
            {
                id = 8, --feather
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 83, --fortifySkill 
                skill = 19, --sneak
                duration = 720,
                min = 10,
                max = 30,
            }
        },
        text = "May I shrink to dust\n\nIn your cold, wild Wastes,\n\nAnd may my tongue speak\n\nIts last hymn to your winds."
    },
    {
        name = "Prayer of the Wise Woman",
        id = "wise_woman_prayer",
        handler = "Ashlander Prayers",
        skillReq = 16,
        skill = "ashlander_theology",
        description = "Step through fire and frost, hold fast your body from disease\n\n    Resist Fire 20 - 50\n    Resist Frost 20 - 50\n    Resist Common Disease 20 - 50\n    Resist Blight Disease 20 - 50",
        image = "Icons\\PRAY\\art\\wise_woman_landscape.dds",
        spellEffects = {
            {
                id = 90, --resistFire
                duration = 720,
                min = 20,
                max = 50,
            },
            {
                id = 91, --resistFrost
                duration = 720,
                min = 20,
                max = 50,
            },
            {
                id = 94, --resistCommonDisease
                duration = 720,
                min = 20,
                max = 50,
            },
            {
                id = 95, --resistBlightDisease
                duration = 720,
                min = 20,
                max = 50,
            },
        },
        text = "I will not pray for that which I've lost\nWhen my heart springs forth\nFrom your soil, like a seed,\nAnd blossoms anew beneath tomorrow's sun."
    },
    {
        name = "Prayer of the Ashkhan",
        id = "ashkhan_prayer",
        handler = "Ashlander Prayers",
        skillReq = 18,
        skill = "ashlander_theology",
        description = "Gird yourself in mystic armors\n\n    Shield 10 - 30\n    Sound 10 - 30\n    Telekinesis 5 - 15",
        image = "Icons\\PRAY\\art\\red_mountain.dds",
        spellEffects = {
            {
                id = 3, --shield
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 48, --sound
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 59, --telekinesis 
                duration = 720,
                min = 5,
                max = 15,
            }
        },
        text = "Rise from darkness, Red Mountain!\nSpread your dark clouds and green vapors!\nBirth earthquakes, shatter stones!\nFeed the winds with fire!\nFlay the tents of the tribes from the land!\nFeed the burned earth with our souls!\n\nYet never shall you have your rule over me."
    },
    {
        name = "Invocation of Alandro Sul",
        id = "alandro_sul",
        handler = "Ashlander Rituals",
        skillReq = 20,
        skill = "ashlander_theology",
        description = "Commune with the whispers of Alandro Sul's Spirit\n\n    Blind 100\n    Sanctuary 100\n    Detect Animal 100\n    Detect Enchantment 100\n    Detect Key 100",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\alandro_sul.dds",
        materials = {
            { material = "pray_ashlander_cuirass", count = 1},
            { material = "ashlander_lit", count = 1},
            { material = "candle", count = 5 },
        },
        spellEffects = {
            {
                id = 47, --blind
                duration = 720,
                min = 100,
                max = 100,
            },
            {
                id = 42, --sanctuary
                duration = 720,
                min = 100,
                max = 100,
            },
            {
                id = 64, --detectAnimal
                duration = 720,
                min = 100,
                max = 100,
            },
            {
                id = 65, --detectEnchantment
                duration = 720,
                min = 100,
                max = 100,
            },
            {
                id = 66, --detectKey
                duration = 720,
                min = 100,
                max = 100,
            },
            -- {
            --     id = 336, --detectDaedra (Enhanced Detection)
            --     duration = 720,
            --     min = 100,
            --     max = 100,
            -- },
            -- {
            --     id = 338, --detectHumanoid (Enhanced Detection)
            --     duration = 720,
            --     min = 100,
            --     max = 100,
            -- },
            -- {
            --     id = 340, --detectUndead (Enhanced Detection)
            --     duration = 720,
            --     min = 100,
            --     max = 100,
            -- },
        },
        text = "When earth is sundered, and skies choked black\nAnd sleepers serve the seven curses\nTo the hearth there comes a stranger,\nJourneyed far 'neath moon and star",
    }
}

return this
