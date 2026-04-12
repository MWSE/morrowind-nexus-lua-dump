local self = require('openmw.self')
local quests = {
    {
        id = "DD_HalfmanDeviceJ",
        name = "Halfman Device",
        category = "Side Quest",
        subcategory = "Halfman's Ascent",
        master = "Tel Eurus",
        text = "Use a special device to deal with several rogue Halfmen.",
    },

    {
        id = "DD_MusicGhostJ",
        name = "Music for the Ghost's Ears",
        category = "Side Quest",
        subcategory = "Dwemer Ruins",
        master = "Tel Eurus",
        text = "Recover an old Dwemer book for a ghostly resident.",
    },

    {
        id = "DD_SpiderJailJ",
        name = "Spider Egg Hunt",
        category = "Side Quest",
        subcategory = "Marketplace",
        master = "Tel Eurus",
        text = "Assist a local with a hunt for spider eggs.",
    },

    {
        id = "DD_RoninQuest",
        name = "Undead Warrior",
        category = "Side Quest",
        subcategory = "Tel Eurus",
        master = "Tel Eurus",
        text = "Report a troubling encounter involving an undead traveler.",
    },

    {
        id = "DD_JGardenium",
        name = "Brothel Gardenium",
        category = "Side Quest",
        subcategory = "Arms of the Ocean",
        master = "Tel Eurus",
        text = "Help arrange a new addition for a local establishment.",
    },

    {
        id = "DD_JPowerCore",
        name = "Dwemer Power Core",
        category = "Side Quest",
        subcategory = "Dwemer Ruins",
        master = "Tel Eurus",
        text = "Look into a missing Dwemer power source and help restore it.",
    },

    {
        id = "DD_JTwinLamps",
        name = "Twin Lamps on Tel Eurus",
        category = "Faction",
        subcategory = "Twin Lamps",
        master = "Tel Eurus",
        text = "Follow up on a lead connected to the Twin Lamps.",
    },

    {
        id = "DD_JournalMP",
        name = "Marketplace Investigation",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Collect evidence in the marketplace for an ongoing investigation.",
    },

    {
        id = "DD_Journal1",
        name = "Sabotage on Tel Eurus",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Investigate a series of sabotage incidents in Tel Eurus.",
    },

    {
        id = "DD_PetSnail",
        name = "Sload's Lost Pet",
        category = "Side Quest",
        subcategory = "Marketplace",
        master = "Tel Eurus",
        text = "Search for a missing pet for an eccentric local.",
    },

    {
        id = "DD_Journal2",
        name = "Visitor in the Tunnels",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Scout the tunnels for signs of a suspicious visitor.",
    },

    {
        id = "DD_Journal3",
        name = "Draven's Floating Ruins",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Inspect nearby ruins for evidence tied to the investigation.",
    },

    {
        id = "DD_Journal4",
        name = "Book of Riddles",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Deliver a strange book for examination and follow its clues.",
    },

    {
        id = "DD_KeeperJ",
        name = "Tel Eurus Lighthouse Keeper",
        category = "Side Quest",
        subcategory = "Lighthouse",
        master = "Tel Eurus",
        text = "Find the missing lighthouse keeper and pass along a message.",
    },

    {
        id = "DD_PantsJ",
        name = "Comfy Work Pants",
        category = "Side Quest",
        subcategory = "Crystal Mines",
        master = "Tel Eurus",
        text = "Recover a worker's missing pants from an abandoned mine.",
    },

    {
        id = "DD_Lead1",
        name = "Mysterious Letters",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Have a suspicious note examined as part of the investigation.",
    },

    {
        id = "DD_Lead2",
        name = "Fire and Glass",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Trace the source of broken glass found at the crime scene.",
    },

    {
        id = "DD_Lead3",
        name = "Where are the Slaves?",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Pursue a lead involving missing slaves and suspicious evidence.",
    },

    {
        id = "DD_Lead4",
        name = "The Mask Slips",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Investigate a masked lead connected to the saboteur.",
    },

    {
        id = "DD_Lead5",
        name = "Toxic Alchemy",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Look into suspicious acid jars tied to the case.",
    },

    {
        id = "DD_Lead6",
        name = "The Headless Halfman",
        category = "Main Quest",
        subcategory = "Sabotage Investigation",
        master = "Tel Eurus",
        text = "Follow evidence involving a Halfman near the marketplace.",
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
