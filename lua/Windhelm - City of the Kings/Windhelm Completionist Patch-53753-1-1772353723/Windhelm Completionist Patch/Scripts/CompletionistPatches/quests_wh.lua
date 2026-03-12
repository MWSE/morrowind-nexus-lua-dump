local self = require('openmw.self')

local whquests = {
	-- #########################################################################
	-- MOD: Windhelm - city of the Kings
	-- #########################################################################


    {
        id = "wh_blackrats",
        name = "Rats on Warehouse",
        category = "Miscellaneous",
        subcategory = "Windhelm",
        master= "Windhelm - City of the Kings", text = "Asgald has a problem with rats."
    },
    {
        id = "wh_guardkilled",
        name = "The Missing Guard",
        category = "Miscellaneous",
        subcategory = "Windhelm",
        master= "Windhelm - City of the Kings", text = "The guard did not show up for duty."
    },
    {
        id = "wh_investigateruins",
        name = "Investigate the Ancient Ruins",
        category = "Factions | Mages Guild",
        subcategory = "Skyrim",
        master= "Windhelm - City of the Kings", text = "What secrets lie hidden in the ancient ruins?"
    },
    {
        id = "wh_kjaldiron",
        name = "Recover Iron for Kjald",
        category = "Miscellaneous",
        subcategory = "Windhelm",
        master= "Windhelm - City of the Kings", text = "Kjald needs his special iron."
    },
    {
        id = "wh_ollurhook",
        name = "Legendary Hook Hand of Ollur the Maulhand",
        category = "Miscellaneous",
        subcategory = "Windhelm",
        master= "Windhelm - City of the Kings", text = "What is true about the legend?"
    },
    {
        id = "wh_recoverhammer",
        name = "Recover Hammer from Bandits",
        category = "Factions | Fighters Guild",
        subcategory = "Windhelm",
        master= "Windhelm - City of the Kings", text = "The stolen artefact must be recovered."
    },
    {
        id = "wh_huntmoon",
        name = "The Hunter and the Moon",
        category = "Miscellaneous",
        subcategory = "Skyrim",
        master= "Windhelm - City of the Kings", text = "What injured the hunter?"
    },

}

local hasSent = false
return {
	engineHandlers = {
		onUpdate = function(dt)       
			if not hasSent then
				print("[Completionist] Sending WH data...")
				self:sendEvent("Completionist_RegisterPack", whquests)
				hasSent = true
			end
		end
    }
}