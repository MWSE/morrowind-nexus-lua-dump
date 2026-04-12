local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: OAAB Ebonheart Six Fishes
    -- #########################################################################

    {
        id = "luce_sfo_falcoletter",
        name = "Letter for Falco",
        category = "Miscellaneous",
        subcategory = "",
        master = "OAAB Ebonheart Six Fishes", text = "Arius Galenus has asked them to deliver a letter to his cousin Falco Galenus."
    },
    {
        id = "luce_sfo_nixhound",
        name = "Hound Hassles",
        category = "Miscellaneous",
        subcategory = "",
        master = "OAAB Ebonheart Six Fishes", text = "The cook at the Six Fishes is being hassled by a nix-hound in the kitchen."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending OAAB Ebonheart Six Fishes data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 2
