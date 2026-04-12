local self = require('openmw.self')

local quests = {

    {
        id = "VF_BalmoraRumors",
        name = "The Search for the Dissident Priests: Suran",
        category = "Temple",
        subcategory = "Dissident Priests",
        master = "Vivec's Fate",
        text = "Investigate reports that may lead to the Dissident Priests."
    },

    {
        id = "VF_TempleQuest",
        name = "A Special Task",
        category = "Temple",
        subcategory = "Archcanon Saryoni",
        master = "Vivec's Fate",
        text = "Meet with Archcanon Saryoni regarding a sensitive matter."
    },

    {
        id = "VF_StolenBook",
        name = "The Archcanon's Book",
        category = "Temple",
        subcategory = "Dissident Priests",
        master = "Vivec's Fate",
        text = "Recover a missing manuscript connected to the late Archcanon."
    },

    {
        id = "VF_Ghostgate",
        name = "A Public Statement",
        category = "Temple",
        subcategory = "Ghostgate",
        master = "Vivec's Fate",
        text = "Investigate a dispute at Ghostgate involving sacred remains."
    },

    {
        id = "VF_Ordinator",
        name = "The Search for the Dissident Priests: Ordinator",
        category = "Temple",
        subcategory = "Ordinators",
        master = "Vivec's Fate",
        text = "Track down the remaining leaders of the Dissident Priests."
    },

    {
        id = "VF_Search",
        name = "The Search for the Dissident Priests",
        category = "Temple",
        subcategory = "Dissident Priests",
        master = "Vivec's Fate",
        text = "Investigate the murder of Archcanon Saryoni and search for the Dissident Priests."
    },

    {
        id = "VF_Vivec",
        name = "Final Reckoning",
        category = "Main Quest",
        subcategory = "Finale",
        master = "Vivec's Fate",
        text = "Attend a confrontation in Vivec's palace as tensions reach a climax."
    },

    {
        id = "VF_Hands",
        name = "The Hand of Nerevar",
        category = "Ashlanders",
        subcategory = "Hand of Nerevar",
        master = "Vivec's Fate",
        text = "Speak with a group of Ashlander followers offering their support."
    },

    {
        id = "VF_Cult",
        name = "The Ashlander Revival: Imperial Cult",
        category = "Imperial Cult",
        subcategory = "Ashlander Revival",
        master = "Vivec's Fate",
        text = "Find a missing Imperial Cult missionary and learn what became of him."
    },

    {
        id = "VF_Erab",
        name = "Han-Ammu",
        category = "Ashlanders",
        subcategory = "Erabenimsun",
        master = "Vivec's Fate",
        text = "Speak with Han-Ammu about the state of the Erabenimsun."
    },

    {
        id = "VF_EOT",
        name = "End of Times: Ald-ruhn",
        category = "Miscellaneous",
        subcategory = "Ald-ruhn",
        master = "Vivec's Fate",
        text = "Hear out a preacher in Ald-ruhn spreading dire warnings."
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

-- Quest count: 11