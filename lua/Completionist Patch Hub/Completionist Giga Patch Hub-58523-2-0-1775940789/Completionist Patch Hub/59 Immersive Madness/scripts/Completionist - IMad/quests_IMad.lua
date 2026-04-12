local self = require('openmw.self')

local quests = {

    {
        id = "FSheog_J00",
        name = "Cult of Sheogorath: Initiation",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Travel to the shrine of Zaintiraris to join the Cult of Sheogorath."
    },
    {
        id = "FSheog_JTunengore",
        name = "Cult of Sheogorath: Pyrolalia",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Aid an Altmer cultist at Zaintiraris who laments losing his connection to the flames."
    },
    {
        id = "FSheog_JBurzob1",
        name = "Cult of Sheogorath: Pull Up the Rear",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Recover something an Orc cultist believes was stolen from her."
    },
    {
        id = "FSheog_JBurzob2",
        name = "Cult of Sheogorath: Posterior Analytics",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Seek outside confirmation for a recovered item on behalf of an Orc cultist."
    },
    {
        id = "FSheog_JBurzob3",
        name = "Cult of Sheogorath: Ars Medica",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Complete a purification ritual for an Orc cultist in Zaintiraris."
    },
    {
        id = "FSheog_JHaki1",
        name = "Cult of Sheogorath: That Damn Rock",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Deal with an inanimate nuisance that a cultist at Zaintiraris finds offensive."
    },
    {
        id = "FSheog_JHaki2",
        name = "Cult of Sheogorath: That Damn Puddle",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Dispose of a puddle that has been causing trouble for a cultist at Zaintiraris."
    },
    {
        id = "FSheog_JHaki3",
        name = "Cult of Sheogorath: Those Damn Air-Jackasses",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Retrieve feathers from cliff racers atop Zaintiraris for a cultist."
    },
    {
        id = "FSheog_JCid1",
        name = "Cult of Sheogorath: Eye to Eye",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Represent the Cult of Sheogorath in a contest issued by followers of Molag Bal near Tel Mora."
    },
    {
        id = "FSheog_JCid2",
        name = "Cult of Sheogorath: Disorder",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Investigate a reported threat near Suran on behalf of the Cult of Sheogorath."
    },
    {
        id = "FSheog_JCid3",
        name = "Cult of Sheogorath: Gambolpuddy",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Travel to Ald Daedroth as the cult's ambassador to deliver a message to Sheogorath's followers."
    },
    {
        id = "FSheog_JCid4",
        name = "Cult of Sheogorath: Egg",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Deliver an offering from the Cult of Sheogorath to a notable figure in Tel Branora."
    },
    {
        id = "FSheog_JCid5",
        name = "Cult of Sheogorath: Dream-Irruptions of Red Mountain",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Respond to a summons from a Sheogorath priestess and resolve a disturbance in a nearby ruin."
    },
    {
        id = "FSheog_JCid6",
        name = "Cult of Sheogorath: Coronation",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Travel to Mournhold to claim a royal title bestowed by the Cult of Sheogorath."
    },
    {
        id = "FSheog_JCid6b",
        name = "Cult of Sheogorath: Coronation",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Investigate a discovery related to the Sheogorath cult in Mournhold."
    },
    {
        id = "FSheog_JCid6c",
        name = "Cult of Sheogorath: Coronation",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Arrange a return to Vvardenfell after an unexpected journey to Mournhold."
    },
    {
        id = "FSheog_JCid7",
        name = "Cult of Sheogorath: Uneasy Lies the Head",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Find a suitable candidate to fill the vacant role of High Priest in the Cult of Sheogorath."
    },
    {
        id = "FSheog_JAzura",
        name = "Azura's Quest",
        category = "Daedric",
        subcategory = "Cult of Sheogorath",
        master = "Immersive Madness",
        text = "Receive a reward from Sheogorath's servant following a confrontation involving Azura."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 18
