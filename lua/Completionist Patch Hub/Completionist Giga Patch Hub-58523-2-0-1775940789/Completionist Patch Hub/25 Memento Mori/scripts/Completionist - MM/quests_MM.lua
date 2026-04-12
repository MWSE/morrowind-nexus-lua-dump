local self = require('openmw.self')
local quests = {
    {
        id = "GG_CorruptPriest",
        name = "The Ossuary of Ayem: Wayward Servants",
        category = "Ossuary Quests",
        subcategory = "Ayem",
        master = "Memento Mori",
        text = "The Prefect of Ayem seeks help investigating troubling disturbances and missing heirlooms in the catacombs.",
    },

    {
        id = "GG_Confirmation",
        name = "Order of Ghosts: Remains Donation Registration Form",
        category = "Order of Ghosts",
        subcategory = "Assignments",
        master = "Memento Mori",
        text = "An assistant of the Order of Ghosts asks that a donation form be delivered and signed.",
    },

    {
        id = "GG_Pilgrimage",
        name = "Memento Mori: The Pilgrimage of the Dead",
        category = "Pilgrimage",
        subcategory = "Order of Ghosts",
        master = "Memento Mori",
        text = "A funerary text describes a solemn pilgrimage to the shrines of the Great Ossuaries.",
    },

    {
        id = "GG_SehtShrine",
        name = "The Ossuary of Seht: A Broken Clock",
        category = "Ossuary Quests",
        subcategory = "Seht",
        master = "Memento Mori",
        text = "The shrine at the Ossuary of Seht has fallen silent, and its caretakers need help restoring it.",
    },

    {
        id = "GG_6thHouse",
        name = "The Ossuary of Vehk: As Above, So Below",
        category = "Ossuary Quests",
        subcategory = "Vehk",
        master = "Memento Mori",
        text = "The defenders of the Ossuary of Vehk need aid against a dangerous threat in the catacombs.",
    },

    {
        id = "GG_Quest_1",
        name = "Order of Ghosts: Pilgrimage",
        category = "Order of Ghosts",
        subcategory = "Assignments",
        master = "Memento Mori",
        text = "The Order of Ghosts offers an assignment tied to the rites and duties of pilgrimage.",
    },

    {
        id = "GG_Quest_2",
        name = "Order of Ghosts: Gather Remains",
        category = "Order of Ghosts",
        subcategory = "Assignments",
        master = "Memento Mori",
        text = "The Order of Ghosts tasks you with gathering the remains of the recently deceased.",
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

-- Quest count: 7
