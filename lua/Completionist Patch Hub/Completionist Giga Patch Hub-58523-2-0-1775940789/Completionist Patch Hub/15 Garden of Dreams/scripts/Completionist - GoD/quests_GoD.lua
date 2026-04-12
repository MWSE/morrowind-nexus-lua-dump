local self = require('openmw.self')
local quests = {
    {
        id = "X32_MTMHello",
        name = "Morag Tong: The Monastery of Mephala",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Meet the masters and students at the Monastery of Mephala."
    },

    {
        id = "X32_MTMSummon",
        name = "Morag Tong: Grandmaster Summons",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Answer a summons and report to the Monastery of Mephala."
    },

    {
        id = "X32_MTMWritFinal",
        name = "Morag Tong: Cleaning House",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Review a ledger and settle a troubling Morag Tong matter."
    },

    {
        id = "X32_MTMWritOneSelf",
        name = "Morag Tong: Writ for Raynil Ondor",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Carry out a writ against a mercenary target."
    },

    {
        id = "X32_MTMWritOneStudents",
        name = "Morag Tong: A Study in Subtlety.",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Assign writs to the students of the Monastery."
    },

    {
        id = "X32_MTMWritTwoSelf",
        name = "Morag Tong: Writ for Shepherd",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Fulfill a violent writ against a dangerous fugitive."
    },

    {
        id = "X32_MTMWritTwoStudents",
        name = "Morag Tong: The Pursuit of Violent Teachings",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Distribute another set of writs to the students."
    },

    {
        id = "x32_MQ",
        name = "Destiny, Dreaming",
        category = "Main Quest",
        subcategory = "The Garden of Dreams",
        master = "The Garden of Dreams",
        text = "Follow a strange message to a hidden place beyond the Monastery."
    },

    {
        id = "x32_MQ_Nebula",
        name = "Destiny, Dreaming",
        category = "Main Quest",
        subcategory = "The Garden of Dreams",
        master = "The Garden of Dreams",
        text = "Decide whether to accept aid from mysterious beings in a strange realm."
    },

    {
        id = "x32_SideQ_Doors",
        name = "Lost Footsteps",
        category = "Side Quest",
        subcategory = "White Cliffs",
        master = "The Garden of Dreams",
        text = "Help a lost spirit find the proper way forward."
    },

    {
        id = "x32_SideQ_Duel",
        name = "Echoes of the Duel",
        category = "Side Quest",
        subcategory = "White Cliffs",
        master = "The Garden of Dreams",
        text = "Complete a forgotten duel for a wandering spirit."
    },

    {
        id = "x32_SideQ_MTMDuel",
        name = "Morag Tong: An Eighteen Drake Run of Bad Luck",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Recover and deliver a dead drop for the Sedrin siblings."
    },

    {
        id = "x32_SideQ_MTMNoble",
        name = "Morag Tong: To Deliver",
        category = "Faction",
        subcategory = "Morag Tong",
        master = "The Garden of Dreams",
        text = "Deliver a package for Favil Ondor."
    },

    {
        id = "x32_SideQ_Space",
        name = "The Mind Races",
        category = "Side Quest",
        subcategory = "White Cliffs",
        master = "The Garden of Dreams",
        text = "Search a nearby realm for an item lost by a spirit."
    },

    {
        id = "x32_SideQ_Zadavi",
        name = "Zadavi's Tent",
        category = "Side Quest",
        subcategory = "Zadavi",
        master = "The Garden of Dreams",
        text = "Bring hides to Zadavi so he will trade."
    },

    {
        id = "x32_SideQ_Zadavi2",
        name = "Zadavi's Pillows",
        category = "Side Quest",
        subcategory = "Zadavi",
        master = "The Garden of Dreams",
        text = "Gather a set of silk pillows for Zadavi."
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

-- Quest count: 16
