local self = require('openmw.self')
local quests = {
    {
        id = "Vashai418_Salvation",
        name = "Salvation for Dra'Vashai",
        category = "Dra'Vashai's Journey",
        subcategory = "Dra'Vashai",
        master = "Tamriel Rebuilt Intro",
        text = "Dra'Vashai seeks an escort to Old Ebonheart, where he hopes to begin a safer life."
    },

    {
        id = "Vashai418_Shoes",
        name = "Shoes for Dra'Vashai",
        category = "Dra'Vashai's Journey",
        subcategory = "Dra'Vashai",
        master = "Tamriel Rebuilt Intro",
        text = "A freed Khajiit named Dra'Vashai needs his missing boots recovered from Addamasartus."
    },

    {
        id = "Vashai418_Money",
        name = "Money for Dra'Vashai",
        category = "Dra'Vashai's Journey",
        subcategory = "Dra'Vashai",
        master = "Tamriel Rebuilt Intro",
        text = "After reaching Seyda Neen, Dra'Vashai asks to borrow some gold until he can get back on his feet."
    },

    {
        id = "Vashai418_Cake",
        name = "A Cake for a Cat",
        category = "Dra'Vashai's Journey",
        subcategory = "Dra'Vashai",
        master = "Tamriel Rebuilt Intro",
        text = "While in Ebonheart, Dra'Vashai asks for help obtaining a cake he has been craving."
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
