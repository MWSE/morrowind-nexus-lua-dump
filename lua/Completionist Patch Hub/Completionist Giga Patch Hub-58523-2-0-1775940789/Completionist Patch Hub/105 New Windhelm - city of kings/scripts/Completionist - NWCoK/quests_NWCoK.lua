local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: New Windhelm - city of kings
    -- #########################################################################

    {
        id = "wh_investigateruins",
        name = "Investigate the ancient ruins",
        category = "Miscellaneous",
        subcategory = "",
        master = "New Windhelm - city of kings", text = "Their first duty is help Stentus Quaspus with his investigation."
    },
    {
        id = "wh_recoverhammer",
        name = "Recover Hammer from Bandits",
        category = "Miscellaneous",
        subcategory = "",
        master = "New Windhelm - city of kings", text = "Harik Jurgaldsen he asked them to retrieve the Stendarr's Hammer before talking about their admission to the guild."
    },
    {
        id = "wh_guardkilled",
        name = "The Missing Guard",
        category = "Miscellaneous",
        subcategory = "",
        master = "New Windhelm - city of kings", text = "Snodir sent them to check why the soldier guarding the Dunmeth Pass has not heard from him."
    },
    {
        id = "wh_ollurhook",
        name = "Legendary Hook Hand of Ollur the Maulhand",
        category = "Miscellaneous",
        subcategory = "",
        master = "New Windhelm - city of kings", text = "In Windhlem one heard the legend of Ollur."
    },
    {
        id = "wh_blackrats",
        name = "Rats on Warehouse",
        category = "Miscellaneous",
        subcategory = "",
        master = "New Windhelm - city of kings", text = "Attend to a matter involving rats on warehouse."
    },
    {
        id = "wh_kjaldiron",
        name = "Recover Iron for Kjald",
        category = "Miscellaneous",
        subcategory = "",
        master = "New Windhelm - city of kings", text = "Kjald told them his shipment of iron hasn't arrived."
    },
    {
        id = "wh_huntmoon",
        name = "The Hunter and the Moon",
        category = "Miscellaneous",
        subcategory = "",
        master = "New Windhelm - city of kings", text = "A local adventurer found an injured hunter who asked them for help."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending New Windhelm - city of kings data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 7
