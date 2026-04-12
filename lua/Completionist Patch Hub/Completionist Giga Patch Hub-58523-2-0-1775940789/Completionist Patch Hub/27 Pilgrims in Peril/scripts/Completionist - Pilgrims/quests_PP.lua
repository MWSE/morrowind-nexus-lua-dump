local self = require('openmw.self')

local quests = {

    {
        id = "MwG_PiP_01",
        name = "Sacrilegious Scrib",
        category = "Pilgrimage",
        subcategory = "Fields of Kummu",
        master = "Pilgrims in Peril",
        text = "A pilgrim has lost a sacred keepsake near the Fields of Kummu and needs help recovering it."
    },

    {
        id = "MwG_PiP_02",
        name = "Blighted Trouble",
        category = "Pilgrimage",
        subcategory = "Ghostgate",
        master = "Pilgrims in Peril",
        text = "A sick pilgrim near Ghostgate needs aid before illness overtakes him."
    },

    {
        id = "MwG_PiP_03",
        name = "Stolen Offerings",
        category = "Pilgrimage",
        subcategory = "West Gash",
        master = "Pilgrims in Peril",
        text = "A pilgrim needs help recovering stolen offerings taken by bandits on the road."
    },

    {
        id = "MwG_PiP_04",
        name = "The Burden of Faith",
        category = "Pilgrimage",
        subcategory = "Maar Gan",
        master = "Pilgrims in Peril",
        text = "A weary pilgrim seeks help bearing a heavy burden on the road to Maar Gan."
    },

    {
        id = "MwG_PiP_05",
        name = "Interrupted Prayer",
        category = "Pilgrimage",
        subcategory = "Ashlands",
        master = "Pilgrims in Peril",
        text = "A pilgrim is in danger in the wilderness and may need immediate assistance."
    },

    {
        id = "MwG_PiP_06",
        name = "A Pilgrim's Dying Wish",
        category = "Pilgrimage",
        subcategory = "Molag Mar",
        master = "Pilgrims in Peril",
        text = "A dying pilgrim asks that his final act of devotion be completed in his stead."
    },

    {
        id = "MwG_PiP_07",
        name = "The Bitter Offering",
        category = "Pilgrimage",
        subcategory = "Vivec",
        master = "Pilgrims in Peril",
        text = "A troubled pilgrim in Vivec is wrestling with faith and may need guidance."
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