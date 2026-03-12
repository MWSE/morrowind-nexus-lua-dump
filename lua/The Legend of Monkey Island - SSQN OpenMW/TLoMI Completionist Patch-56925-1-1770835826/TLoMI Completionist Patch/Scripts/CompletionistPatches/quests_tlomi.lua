local self = require('openmw.self')

local tlomiquests = {
	-- #########################################################################
	-- MOD: The Legend of Monkey Island	
	-- #########################################################################

    {
        id = "TS_melee1",
        name = "Journey to Melee Island",
        category = "Main Quest",
        subcategory = "Melee Island",
        master= "The Legend of Monkey Island", text = "A woman named Elaine asked me to help save her husband, but I have to become a pirate."
    },
    {
        id = "TS_melee2",
        name = "Quest For Guybrush",
        category = "Main Quest",
        subcategory = "Melee Island",
        master= "The Legend of Monkey Island", text = "I must find the ship called The Mad Monkey to find LeChuck's hideout."
    },
    {
        id = "TS_melee3",
        name = "Lair of LeChuck",
        category = "Main Quest",
        subcategory = "Melee Island",
        master= "The Legend of Monkey Island", text ="I must enter LeChuck's hideout and defeat him."
    },
    {
        id = "TS_meathook",
        name = "Uninvited Guests",
        category = "Miscellaneous",
        subcategory = "Melee Island",
        master= "The Legend of Monkey Island", text = "Meathook has a problem with rats in his basement."
    },
    {
        id = "TS_noodle",
        name = "Bad For Bussiness",
        category = "Miscellaneous",
        subcategory = "Melee Island",
        master= "The Legend of Monkey Island", text = "The Fettuccini brothers need help collecting the posters scattered around the island."
    },
    {
        id = "ts_stanQuest1",
        name = "Sunken Manifests",
        category = "Miscellaneous",
        subcategory = "Melee Island",
        master= "The Legend of Monkey Island", text = "Stan offered me a generous reward if I help him find his manifests."
    },    
    {
        id = "ts_stanQuest2",
        name = "Sunken Treasure",
        category = "Miscellaneous",
        subcategory = "Melee Island",
        master= "The Legend of Monkey Island", text = "Stan has asked me to recover a strange cup."
    },
    {
        id = "ts_stanQuest2",
        name = "Lost Deed",
        category = "Miscellaneous",
        subcategory = "Melee Island",
        master= "The Legend of Monkey Island", text ="Stan asked if I could recover the lost deed and key to one of his ships."
    },

}

local hasSent = false
return {
	engineHandlers = {
		onUpdate = function(dt)       
			if not hasSent then
				print("[Completionist] Sending WH data...")
				self:sendEvent("Completionist_RegisterPack", tlomiquests)
				hasSent = true
			end
		end
    }
}