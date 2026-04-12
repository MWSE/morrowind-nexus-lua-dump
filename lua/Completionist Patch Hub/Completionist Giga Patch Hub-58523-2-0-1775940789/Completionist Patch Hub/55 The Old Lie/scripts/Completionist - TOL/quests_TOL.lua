local self = require('openmw.self')

local quests = {
    {
        id = "TOL_m7_Invstg2sub2",
        name = "Where Thirty Years Three Thousand Guar Fed",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Gather information about the saltrice trade and report the findings."
    },

    {
        id = "TOL_m7_Invstg2sub3",
        name = "Where Thirty Years Three Thousand Guar Fed",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Look into suspicious evidence connected to the Narsis investigation."
    },

    {
        id = "TOL_m7_Invstg1sub",
        name = "The Love of Honor That Never Grows Old",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Speak with a Temple authority about the wider investigation."
    },

    {
        id = "TOL_m7_Invstg2sub",
        name = "Where Thirty Years Three Thousand Guar Fed",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Investigate the spread of the saltrice blight in Narsis."
    },

    {
        id = "TOL_m2_Drey2sub",
        name = "A Fool's End",
        category = "Main Quest",
        subcategory = "Dreyvan and Vilithmar",
        master = "The Old Lie",
        text = "Deal with the aftermath of a dangerous search in the ruins."
    },

    {
        id = "TOL_m2_Drey1sub",
        name = "A Fool's Errand",
        category = "Main Quest",
        subcategory = "Dreyvan and Vilithmar",
        master = "The Old Lie",
        text = "Recover from a sickness contracted during the investigation."
    },

    {
        id = "TOL_m7_Showdown",
        name = "To Banish Ghosts and Goblins",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Follow a lead on the river and confront those involved."
    },

    {
        id = "TOL_m7_Invstg1",
        name = "The Love of Honor That Never Grows Old",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Assist the ordinators with the early stages of their investigation."
    },

    {
        id = "TOL_m7_Invstg2",
        name = "Where Thirty Years Three Thousand Guar Fed",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Help examine the blight case and gather leads in Narsis."
    },

    {
        id = "TOL_m7_Invstg3",
        name = "Consequentialism",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Review the consequences of recent events and continue the inquiry."
    },

    {
        id = "TOL_m2_RR1sub",
        name = "Epigenesis",
        category = "Main Quest",
        subcategory = "Reycan Investigation",
        master = "The Old Lie",
        text = "Pursue a small lead connected to the search for Reycan."
    },

    {
        id = "TOL_m2_RR2sub",
        name = "The Land's Panegyric",
        category = "Main Quest",
        subcategory = "Reycan Investigation",
        master = "The Old Lie",
        text = "Examine a clue found during the farm investigation."
    },

    {
        id = "TOL_m2_Drey2",
        name = "A Fool's End",
        category = "Main Quest",
        subcategory = "Dreyvan and Vilithmar",
        master = "The Old Lie",
        text = "Explore the ruins further using information from a recovered journal."
    },

    {
        id = "TOL_m2_Drey1",
        name = "A Fool's Errand",
        category = "Main Quest",
        subcategory = "Dreyvan and Vilithmar",
        master = "The Old Lie",
        text = "Search for a missing Temple layman near Helnim."
    },

    {
        id = "TOL_m2_WCsub",
        name = "To See The Truth",
        category = "Main Quest",
        subcategory = "Waterfall Cavern",
        master = "The Old Lie",
        text = "Respond to losses suffered during the cavern expedition."
    },

    {
        id = "TOL_m7_Final",
        name = "Pro Patria Mori",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Report the outcome of the investigation and see the matter concluded."
    },

    {
        id = "TOL_m7_Auto",
        name = "Summit of his Fortune, Escaped",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Assist with an examination tied to the ongoing Temple inquiry."
    },

    {
        id = "TOL_m2_RR1",
        name = "Epigenesis",
        category = "Main Quest",
        subcategory = "Reycan Investigation",
        master = "The Old Lie",
        text = "Investigate the disappearance of a layman linked to Ranyon-Ruhn."
    },

    {
        id = "TOL_m7_Int",
        name = "To Tell The Truth",
        category = "Main Quest",
        subcategory = "Narsis Investigation",
        master = "The Old Lie",
        text = "Answer questions from the ordinators and decide how to proceed."
    },

    {
        id = "TOL_m2_RR2",
        name = "The Land's Panegyric",
        category = "Main Quest",
        subcategory = "Reycan Investigation",
        master = "The Old Lie",
        text = "Follow Reycan's trail from a plantation to a remote farm."
    },

    {
        id = "TOL_m2_WC",
        name = "To See The Truth",
        category = "Main Quest",
        subcategory = "Waterfall Cavern",
        master = "The Old Lie",
        text = "Accompany the ordinators into a hidden ruin and uncover its purpose."
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

-- Quest count: 21
