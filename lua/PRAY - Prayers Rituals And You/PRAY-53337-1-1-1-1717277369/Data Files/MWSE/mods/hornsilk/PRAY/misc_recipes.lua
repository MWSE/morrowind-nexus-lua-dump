local this = {}

-- use these pages to look up spell effects
-- https://mwse.github.io/MWSE/apis/tes3/?h=script#tes3applymagicsource
-- https://mwse.github.io/MWSE/references/magic-effects/
-- https://mwse.github.io/MWSE/references/attributes/
-- https://mwse.github.io/MWSE/references/skills/
-- https://mwse.github.io/MWSE/references/magic-effects-modded/

-- decent place to look for icons https://en.uesp.net/wiki/Category:Morrowind-Banner_Images


this.recipes = {
    {
        name = "The Gray Maybe",
        id = "luck_prayer",
        handler = "Miscellaneous Prayers",
        skillReq = 5,
        skill = "divine_theology",
        description = "See what luck the day will bring",
        skillProgress = 0,
        prayerDuration = 5,
        image = "Icons\\PRAY\\art\\dice.dds",
        soundPath = "Fx\\magic\\mystC.wav",
        knowledgeRequirement = function()
            return true
        end,
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 7, --luck
                duration = 720,
                min = 0,
                max = 10,
            },
            {
                id = 17, --drainAttribute
                attribute = 7, --luck
                duration = 720,
                min = 0,
                max = 10,
            }
        },
        text = "Man or mer, things begin with the dualism of Anu and His Other.\nThese twin forces go by many names\n\nAnu-Padomay\nAnuiel-Sithis\nAk-El\nSatak-Akel\nIs-Is Not."
    },
    {
        name = "No-h's Prayer",
        id = "noh_prayer",
        handler = "Miscellaneous Prayers",
        skillReq = 5,
        skill = "tribunal_theology",
        description = "Read 'No-h's Picture Book of Wood' aloud",
        skillProgress = 0,
        prayerDuration = 5,
        image = "Icons\\PRAY\\art\\kurt_noh.dds",
        soundPath = "PRAY\\noh_pray.wav",
        knowledgeRequirement = function ()
            return tes3.player.data.hasReadNoh
        end,
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 7, --luck
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 48, --sound
                duration = 720,
                min = 50,
                max = 100,
            },
        },
        text = "Wood is pretty\nWood is nice\nIf one looks good\nI'll make it twice!"
    },
    {
        name = "Caius's 'Ritual'",
        id = "caius_skooma",
        handler = "Miscellaneous Rituals",
        skillReq = 5,
        skill = "divine_theology",
        description = "Caius taught me a 'ritual'",
        image = "Icons\\PRAY\\art\\caius_skooma.dds",
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A1_1_FindSpymaster" } >= 11
        end,
        soundPath = "Fx\\envrn\\undrwatr.wav",
        skillProgress = 0,
        materials = {
            { material = "skooma_pipe", count = 1},
            { material = "pray_moon_sugar", count = 1},
        },
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 0, --strength
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 4, --speed
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 17, --drainAttribute
                attribute = 1, --intelligence
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 17, --drainAttribute
                attribute = 3, --agility
                duration = 720,
                min = 20,
                max = 30,
            },
            {
               id = 43, --nightEye
               duration = 720,
               min = 0,
               max = 50,
            },
            {
               id = 47, --blind
               duration = 720,
               min = 0,
               max = 50,
            },
        },
        text = "'I'm just an old man with a skooma problem.' ~ Caius Cosades",
    },
}

return this
