local self = require('openmw.self')

local quests = {

    {
        id = "UG_Contracts",
        name = "Grave Business",
        category = "Stronghold",
        subcategory = "Uvirith's Grave",
        master = "Building Up Uvirith's Legacy",
        text = "Arrange improvements and new services for the growing settlement at Uvirith's Grave."
    },

    {
        id = "UG_Strider",
        name = "All in Stride",
        category = "Stronghold",
        subcategory = "Uvirith's Grave",
        master = "Building Up Uvirith's Legacy",
        text = "Establish transportation links for Tel Uvirith and Uvirith's Grave."
    },

    {
        id = "UG_Slaves",
        name = "Slaving Away",
        category = "Twin Lamps",
        subcategory = "Uvirith's Grave",
        master = "Building Up Uvirith's Legacy",
        text = "Help free captives and support a safe haven near Uvirith's Grave."
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

-- Quest count: 3
