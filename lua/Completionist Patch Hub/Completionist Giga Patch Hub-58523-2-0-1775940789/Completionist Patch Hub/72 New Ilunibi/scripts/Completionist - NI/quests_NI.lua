local self = require('openmw.self')

local quests = {

    {
        id = "SLF_Saint_Left_In_Balance",
        name = "A Saint Left In The Balance",
        category = "Dungeon",
        subcategory = "Ilunibi",
        master = "New Ilunibi",
        text = "Investigate a strange undead presence encountered deep in the caverns of Ilunibi."
    },
    {
        id = "SLF_a_cowardly_soldier",
        name = "A Cowardly Soldier",
        category = "Dungeon",
        subcategory = "Ilunibi",
        master = "New Ilunibi",
        text = "Assist an Imperial soldier encountered in the caverns of Ilunibi."
    },
    {
        id = "SLF_digging_for_bones",
        name = "Digging for Bones",
        category = "Dungeon",
        subcategory = "Ilunibi",
        master = "New Ilunibi",
        text = "Collect creature bones for a mage encountered in Ilunibi."
    },
    {
        id = "SLF_Saint_Workload",
        name = "A Saint's Workload",
        category = "Dungeon",
        subcategory = "Ilunibi",
        master = "New Ilunibi",
        text = "Assist a saint in collecting souls from the Sixth House creatures within Ilunibi."
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
-- Quest count: 4
