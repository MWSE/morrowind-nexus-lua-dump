local self = require('openmw.self')
local quests = {
    {
        id = "lev_BG_OE_0",
        name = "A Barrister in Old Ebonheart",
        category = "Factions | Barristers Guild",
        subcategory = "Initiation",
        master = "Barrister's Guild",
        text = "I should speak with the barristers of Old Ebonheart and see whether they have work for me."
    },

    {
        id = "lev_BG_OE_1",
        name = "Barristers Guild: Initiation",
        category = "Factions | Barristers Guild",
        subcategory = "Initiation",
        master = "Barrister's Guild",
        text = "I have been directed to seek introductory legal work from the barristers of Marsh and Ellerian."
    },

    {
        id = "lev_BG_OE_1A",
        name = "Barristers Guild: Initiation",
        category = "Factions | Barristers Guild",
        subcategory = "Initiation",
        master = "Barrister's Guild",
        text = "I have been asked to assist with a merchant dispute in Old Ebonheart."
    },

    {
        id = "lev_BG_OE_1B",
        name = "Barristers Guild: Initiation",
        category = "Factions | Barristers Guild",
        subcategory = "Initiation",
        master = "Barrister's Guild",
        text = "I have been asked to help settle a legal dispute concerning an escaped slave in Old Ebonheart."
    },

    {
        id = "lev_BG_OE_1C",
        name = "Barristers Guild: Initiation",
        category = "Factions | Barristers Guild",
        subcategory = "Initiation",
        master = "Barrister's Guild",
        text = "I have been asked to investigate the case of an imprisoned Imperial Legion officer."
    },

    {
        id = "lev_BG_OE_2",
        name = "Barristers Guild: A Case of Limeware",
        category = "Factions | Barristers Guild",
        subcategory = "Old Ebonheart Cases",
        master = "Barrister's Guild",
        text = "I have been assigned to investigate a disputed theft case involving a stolen limeware platter."
    },

    {
        id = "lev_BG_OE_3",
        name = "Barristers Guild: A Thief in the Treasure Room",
        category = "Factions | Barristers Guild",
        subcategory = "Old Ebonheart Cases",
        master = "Barrister's Guild",
        text = "I have been assigned to look into the charges against a thief caught in the Ebon Tower treasure chamber."
    },

    {
        id = "lev_BG_OE_4",
        name = "Barristers Guild: A Questionable Duel",
        category = "Factions | Barristers Guild",
        subcategory = "Old Ebonheart Cases",
        master = "Barrister's Guild",
        text = "I have been asked to investigate the circumstances surrounding a nobleman's death in a duel."
    },

    {
        id = "lev_BG_OE_5",
        name = "Barristers Guild: The Case of the Tavern Brawl",
        category = "Factions | Barristers Guild",
        subcategory = "Old Ebonheart Cases",
        master = "Barrister's Guild",
        text = "I have been asked to examine a killing that took place during a tavern brawl."
    },

    {
        id = "lev_BG_OE_6",
        name = "Barristers Guild: The Necromancer's Apprentice",
        category = "Factions | Barristers Guild",
        subcategory = "Old Ebonheart Cases",
        master = "Barrister's Guild",
        text = "I have been assigned to investigate a legal dispute involving an apprentice accused of necromancy."
    },

    {
        id = "lev_BG_OE_7",
        name = "Barristers Guild: The Duke's Assassin",
        category = "Factions | Barristers Guild",
        subcategory = "Old Ebonheart Cases",
        master = "Barrister's Guild",
        text = "I have been called to advise on a serious matter brought before the Duke of Deshaan."
    },

    {
        id = "lev_BG_OE_8",
        name = "Barristers Guild: The Case of the Serial Murders",
        category = "Factions | Barristers Guild",
        subcategory = "The Case of the Serial Murders",
        master = "Barrister's Guild",
        text = "I have been asked to assist in a murder case tied to the Legion dungeons of Ebon Tower."
    },

    {
        id = "lev_BG_OE_8A",
        name = "Barristers Guild: The Case of the Serial Murders",
        category = "Factions | Barristers Guild",
        subcategory = "The Case of the Serial Murders",
        master = "Barrister's Guild",
        text = "I should gather additional evidence that may strengthen the case."
    },

    {
        id = "lev_BG_OE_8B",
        name = "Barristers Guild: The Case of the Serial Murders",
        category = "Factions | Barristers Guild",
        subcategory = "The Case of the Serial Murders",
        master = "Barrister's Guild",
        text = "I should search for further incriminating evidence connected to the murder case."
    },

    {
        id = "lev_BG_OE_8C",
        name = "Barristers Guild: The Case of the Serial Murders",
        category = "Factions | Barristers Guild",
        subcategory = "The Case of the Serial Murders",
        master = "Barrister's Guild",
        text = "I need help removing a magical shackle before I can proceed freely."
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

-- Quest count: 15
