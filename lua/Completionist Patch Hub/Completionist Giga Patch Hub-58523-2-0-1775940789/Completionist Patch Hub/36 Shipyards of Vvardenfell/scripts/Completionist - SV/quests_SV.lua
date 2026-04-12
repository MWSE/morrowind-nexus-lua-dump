local self = require('openmw.self')

local quests = {

    {
        id = "ShipyardMOD1",
        name = "Escaped Slaves",
        category = "Sadrith Mora",
        subcategory = "Shipyards of Vvardenfell",
        master = "Shipyards of Vvardenfell",
        text = "Deal with a slave escape."
    },

    {
        id = "ShipyardMOD2",
        name = "Lost Delivery",
        category = "Sadrith Mora",
        subcategory = "Shipyards of Vvardenfell",
        master = "Shipyards of Vvardenfell",
        text = "Find a missing shipment."
    },

    {
        id = "ShipyardMOD3",
        name = "Final Negotiations",
        category = "Seyda Neen",
        subcategory = "Shipyards of Vvardenfell",
        master = "Shipyards of Vvardenfell",
        text = "Assist with troubles at a shipyard."
    },

    {
        id = "ShipyardMOD4",
        name = "Vanished Men",
        category = "Gnaar Mok",
        subcategory = "Shipyards of Vvardenfell",
        master = "Shipyards of Vvardenfell",
        text = "Look into the disappearance of some workers."
    },

    {
        id = "ShipyardMOD5",
        name = "Free Selman's Khajiit slaves",
        category = "Sadrith Mora",
        subcategory = "Shipyards of Vvardenfell",
        master = "Shipyards of Vvardenfell",
        text = "Help some slaves escape."
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
-- Quest count: 5
