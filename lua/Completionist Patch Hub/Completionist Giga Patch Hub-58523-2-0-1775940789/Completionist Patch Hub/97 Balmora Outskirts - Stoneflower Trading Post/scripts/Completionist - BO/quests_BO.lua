local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Balmora Outskirts
    -- #########################################################################

    {
        id = "AAkarRV_PosMarbaniQuest1",
        name = "Trouble at the Marbani Egg Mine",
        category = "Miscellaneous",
        subcategory = "",
        master = "Balmora Outskirts", text = "Nia Arvel asked them to get rid of the bandits who occupied an egg mine near the Stoneflower trading post."
    },
    {
        id = "AAkarRV_PosMarbaniQuest2",
        name = "Nevrasa's Lost Amulet",
        category = "Miscellaneous",
        subcategory = "",
        master = "Balmora Outskirts", text = "Nevrasa Sarandas, one of the merchants at the Stoneflower Trading Post, asked them to retrieve a valuable amulet made of green stone from Marbani egg mine."
    },
    {
        id = "AAkarRV_PosMarbaniQuest3",
        name = "Treats for the Bard",
        category = "Miscellaneous",
        subcategory = "",
        master = "Balmora Outskirts", text = "Runi Dilmyn, a herder from the Stoneflower trading post near Balmora, asked them to deliver Possya special Sweet Bantam Guar meat."
    },
    {
        id = "AAkarRV_PosRoomSale",
        name = "Stoneflower Quarters",
        category = "Miscellaneous",
        subcategory = "",
        master = "Balmora Outskirts", text = "At the outskirts of Balmora there's a Stoneflower Trading Post."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Balmora Outskirts data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 4
