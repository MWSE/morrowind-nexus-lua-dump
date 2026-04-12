local self = require('openmw.self')

local quests = {

    {
        id = "WMVC_nobledonationsAB",
        name = "Abbey of St. Delyn - Noble Donations",
        category = "Temple",
        subcategory = "Abbey of St. Delyn",
        master = "Vibrant Cities",
        text = "Collect noble donations."
    },
    {
        id = "WMVC_merchantsrentsAB",
        name = "Abbey of St. Delyn - The Merchants' Rents",
        category = "Temple",
        subcategory = "Abbey of St. Delyn",
        master = "Vibrant Cities",
        text = "Collect the merchants' rents."
    },
    {
        id = "WMVC_sharNightmAB",
        name = "Abbey of St. Delyn - The Sharmat's Nightmares",
        category = "Temple",
        subcategory = "Abbey of St. Delyn",
        master = "Vibrant Cities",
        text = "Ask about troubling nightmares."
    },
    {
        id = "WMVC_pilgrimprepAB",
        name = "Abbey of St. Delyn - Preparing a pilgrimage",
        category = "Temple",
        subcategory = "Abbey of St. Delyn",
        master = "Vibrant Cities",
        text = "Gather supplies for a pilgrimage."
    },
    {
        id = "WMVC_arelasStaffAB",
        name = "Abbey of St. Delyn - Artisa's Staff",
        category = "Temple",
        subcategory = "Abbey of St. Delyn",
        master = "Vibrant Cities",
        text = "Arrange to repair a broken staff."
    },
    {
        id = "WMVC_GolsBqestAB",
        name = "Abbey of St. Delyn - A signed Book",
        category = "Temple",
        subcategory = "Abbey of St. Delyn",
        master = "Vibrant Cities",
        text = "Obtain a signed copy of a book."
    },
    {
        id = "WMVCBH_bottleshipment",
        name = "Brewers Hall: Handing out the booze",
        category = "Brewers and Fishmongers",
        subcategory = "Brewers Hall",
        master = "Vibrant Cities",
        text = "Deliver an alcohol shipment."
    },
    {
        id = "WMVCBH_fishingpoles",
        name = "Brewers Hall: The fishing poles",
        category = "Brewers and Fishmongers",
        subcategory = "Brewers Hall",
        master = "Vibrant Cities",
        text = "Collect a shipment of fishing poles."
    },
    {
        id = "WMVCBH_fishshipment",
        name = "Brewers Hall: A Shipment of Fish",
        category = "Brewers and Fishmongers",
        subcategory = "Brewers Hall",
        master = "Vibrant Cities",
        text = "Retrieve a shipment of fish."
    },
    {
        id = "WMVCBH_brewstastej",
        name = "Brewers Hall: Inspecting the Goods",
        category = "Brewers and Fishmongers",
        subcategory = "Brewers Hall",
        master = "Vibrant Cities",
        text = "Inspect a questionable shipment of drinks."
    },
    {
        id = "WMVCBH_poordonations",
        name = "Brewers Hall: Donating to the Poor",
        category = "Brewers and Fishmongers",
        subcategory = "Brewers Hall",
        master = "Vibrant Cities",
        text = "Deliver fish for the poor."
    },
    {
        id = "WMVCTAD_newsupplier",
        name = "Tailors and Dyers Hall: Looking for a New Supplier",
        category = "Tailors and Dyers",
        subcategory = "Tailors and Dyers Hall",
        master = "Vibrant Cities",
        text = "Seek a new cloth supplier."
    },
    {
        id = "WMVCTAD_searchingcloth",
        name = "Tailors and Dyers Hall: Buying Cloth",
        category = "Tailors and Dyers",
        subcategory = "Tailors and Dyers Hall",
        master = "Vibrant Cities",
        text = "Buy bolts of colored cloth."
    },
    {
        id = "WMVCTAD_struth",
        name = "Tailors and Dyers Hall: Spreading the Truth",
        category = "Tailors and Dyers",
        subcategory = "Tailors and Dyers Hall",
        master = "Vibrant Cities",
        text = "Distribute a set of flyers."
    },
    {
        id = "WMVC_Glass_delivery",
        name = "Glass Worker's Hall - Glass Delivery",
        category = "Faction",
        subcategory = "Glassworkers Hall",
        master = "Vibrant Cities",
        text = "Bring in a shipment of raw glass."
    },
    {
        id = "WMVC_limeware_delivery",
        name = "Glass Worker's Hall - Limeware Platter Delivery",
        category = "Faction",
        subcategory = "Glassworkers Hall",
        master = "Vibrant Cities",
        text = "Deliver a limeware platter."
    },
    {
        id = "WMVC_maulstheft",
        name = "Glass Worker's Hall - Theft of a Glass Vase",
        category = "Faction",
        subcategory = "Glassworkers Hall",
        master = "Vibrant Cities",
        text = "Look into a missing glass vase."
    },
    {
        id = "WMVC_drurilebook",
        name = "Glass Worker's Hall - a Book for Drurile Valaai",
        category = "Faction",
        subcategory = "Glassworkers Hall",
        master = "Vibrant Cities",
        text = "Find a book on raw glasswork."
    },

    {
        id = "WMVC_negwithgov",
        name = "Glass Worker's Hall - Negotiating with the Governor",
        category = "Faction",
        subcategory = "Glassworkers Hall",
        master = "Vibrant Cities",
        text = "Negotiate better payment for a commission."
    },
    {
        id = "WMVC_fatmonopoly",
        name = "Glass Worker's Hall - Fighting against the monopoly",
        category = "Faction",
        subcategory = "Glassworkers Hall",
        master = "Vibrant Cities",
        text = "Carry a letter about trade practices."
    },
    {
        id = "WMVC_ordinaryshipmentsd",
        name = "Potter's Hall - An ordinary shipment",
        category = "Faction",
        subcategory = "Potter's Hall",
        master = "Vibrant Cities",
        text = "Retrieve an ordinary shipment."
    },
    {
        id = "WMPH_simpletask",
        name = "Potter's Hall - A simple task",
        category = "Faction",
        subcategory = "Potter's Hall",
        master = "Vibrant Cities",
        text = "Deliver a package and collect it later."
    },
    {
        id = "WMVC_presentforhlaalu",
        name = "Potter's Hall - A gift for the Hlaalu Councillors",
        category = "Faction",
        subcategory = "Potter's Hall",
        master = "Vibrant Cities",
        text = "Present fine wares to Hlaalu councillors."
    },
    {
        id = "WMVC_badbogfiresalts",
        name = "Potter's Hall - Fire salts for the Furnace",
        category = "Faction",
        subcategory = "Potter's Hall",
        master = "Vibrant Cities",
        text = "Find a supplier of fire salts."
    },
    {
        id = "WMVC_strangeletter",
        name = "Poter's Hall - A Strange Message",
        category = "Faction",
        subcategory = "Potter's Hall",
        master = "Vibrant Cities",
        text = "Carry a strange message."
    },
    {
        id = "WMVC_destroycompetence",
        name = "Potter's Hall - Destroying the Competition",
        category = "Faction",
        subcategory = "Potter's Hall",
        master = "Vibrant Cities",
        text = "Deal with a rival artisan."
    },
    {
        id = "WMVC_pottersendquest",
        name = "Potter's Hall - Thanking for Favors",
        category = "Faction",
        subcategory = "Potter's Hall",
        master = "Vibrant Cities",
        text = "Deliver a small pouch."
    }
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

-- Quest count: 6