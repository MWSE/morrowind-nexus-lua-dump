local self = require('openmw.self')

local quests = {

    {
        id = "kd_LlothisCrosierCurse",
        name = "Piety Restored",
        category = "Temple",
        subcategory = "Lost Relics",
        master = "Lost Relics of the Tribunal Temple",
        text = "Assist the Temple in cleansing a tainted sacred relic."
    },

    {
        id = "kd_FelmsCleaverCurse",
        name = "To Cleave a Cleaver's Curse",
        category = "Temple",
        subcategory = "Lost Relics",
        master = "Lost Relics of the Tribunal Temple",
        text = "Gather ritual materials to cleanse a cursed Temple relic."
    },

    {
        id = "kd_HairShirtCurse",
        name = "Penance of the Penitent",
        category = "Temple",
        subcategory = "Lost Relics",
        master = "Lost Relics of the Tribunal Temple",
        text = "Help purge a holy garment that has been defiled."
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