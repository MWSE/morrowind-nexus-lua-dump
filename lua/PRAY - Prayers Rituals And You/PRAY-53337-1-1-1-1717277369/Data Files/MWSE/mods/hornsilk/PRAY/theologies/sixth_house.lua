local this = {}

local skillModule = require("OtherSkills.skillModule")

this.name = "sixth_house_theology"
this.fullName = "Sixth House Theology"
this.specialization = tes3.specialization.magic
this.attribute = tes3.attribute.personality
this.icon = "Icons\\PRAY\\sixthHouse.dds"
this.sound = "PRAY\\six_pray.wav"
this.description = (
    "The Sixth House Theology skill determines your knowledge of traditional prayers and rituals of the Tribe Unmourned."
)

this.knowledgeRequirement = function()
    return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41
end

this.recipes = {
    {
        name = "Form of the Dreamer",
        id = "sixthHouse_prayer_6",
        handler = "Sixth House Prayers",
        skillReq = 16,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.\nCome to me, through fire and war. I welcome you.\nWelcome, Moon-and-Star. I have prepared a place for you.",
        image = "Icons\\PRAY\\art\\dagoth6.dds",
        skillProgress = 200,
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 6, --personality
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 6, --strength
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 3, --shield
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 4, --fireShield
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 98, --resistNormalWeapons
                duration = 720,
                min = 60,
                max = 66,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah.\nWhy have you denied him?\nAs Lord Dagoth has said. All shall greet him as flesh, or as dust.\nIt is the Hour of Wakening. He comes forth in his glory, and his people shall rejoice, and his enemies shall scatter like dust."
    },
    {
        name = "First Word of the Dreamer",
        id = "sixthHouse_ritual_1",
        handler = "Sixth House Rituals",
        skillReq = 10,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned?",
        image = "Icons\\PRAY\\art\\dagoth1.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 1 }
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixth_house_theology').value < 11
        end,
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 10,
                max = 10,
            },
        },
        text = "He is the Lord, and Father of the Mountain."
    },
    {
        name = "Second Word of the Dreamer",
        id = "sixthHouse_ritual_2",
        handler = "Sixth House Rituals",
        skillReq = 11,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned?",
        image = "Icons\\PRAY\\art\\dagoth2.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 1 },
            { material = "corprusmeat", count = 3 },
        },
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 20,
                max = 20,
            },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixth_house_theology').value < 12
        end,
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him."
    },
    {
        name = "Third Word of the Dreamer",
        id = "sixthHouse_ritual_3",
        handler = "Sixth House Rituals",
        skillReq = 12,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.",
        image = "Icons\\PRAY\\art\\dagoth3.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 2 },
            { material = "corprusmeat", count = 5 },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixth_house_theology').value < 13
        end,
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 30,
                max = 30,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah."
    },
    {
        name = "Forth Word of the Dreamer",
        id = "sixthHouse_ritual_4",
        handler = "Sixth House Rituals",
        skillReq = 13,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.",
        image = "Icons\\PRAY\\art\\dagoth4.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 3 },
            { material = "corprusmeat", count = 11 },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixth_house_theology').value < 14
        end,
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 40,
                max = 40,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah.\nWhy have you denied him?"
    },
    {
        name = "Fifth Word of the Dreamer",
        id = "sixthHouse_ritual_5",
        handler = "Sixth House Rituals",
        skillReq = 14,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.\nCome to me, through fire and war. I welcome you.",
        image = "Icons\\PRAY\\art\\dagoth5.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 4 },
            { material = "corprusmeat", count = 19 },
        },
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 50,
                max = 50,
            },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixth_house_theology').value < 15
        end,
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah.\nWhy have you denied him?\nAs Lord Dagoth has said. All shall greet him as flesh, or as dust."
    },
    {
        name = "Final Word of the Dreamer",
        id = "sixthHouse_ritual_6",
        handler = "Sixth House Rituals",
        skillReq = 15,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.\nCome to me, through fire and war. I welcome you.\nWelcome, Moon-and-Star. I have prepared a place for you.",
        image = "Icons\\PRAY\\art\\dagoth6.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 6 },
            { material = "corprusmeat", count = 36 },
            { material = "pray_6th_house", count = 1 },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixth_house_theology').value < 16
        end,
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 6, --personality
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 6, --strength
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 3, --shield
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 4, --fireShield
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 98, --resistNormalWeapons
                duration = 720,
                min = 60,
                max = 66,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah.\nWhy have you denied him?\nAs Lord Dagoth has said. All shall greet him as flesh, or as dust.\nIt is the Hour of Wakening. He comes forth in his glory, and his people shall rejoice, and his enemies shall scatter like dust."
    },
}

return this
