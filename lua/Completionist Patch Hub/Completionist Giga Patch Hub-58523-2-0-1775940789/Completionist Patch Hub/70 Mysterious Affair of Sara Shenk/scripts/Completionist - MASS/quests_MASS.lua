local self = require('openmw.self')

local quests = {

    {
        id = "aa_shenk00",
        name = "The Mysterious Affair of Sara Shenk: The Shovel",
        category = "Miscellaneous",
        subcategory = "The Mysterious Affair of Sara Shenk",
        master = "Mysterious Affair of Sara Shenk BCOM",
        text = "Investigate the disappearance of Sara Shenk, wife of an innkeeper in Caldera."
    },
    {
        id = "aa_shenk01",
        name = "The Mysterious Affair of Sara Shenk: The Meat",
        category = "Miscellaneous",
        subcategory = "The Mysterious Affair of Sara Shenk",
        master = "Mysterious Affair of Sara Shenk BCOM",
        text = "Follow a disturbing rumor surrounding the innkeeper Shenk and his missing wife."
    },
    {
        id = "aa_shenk02",
        name = "The Mysterious Affair of Sara Shenk: The Moon Sugar",
        category = "Miscellaneous",
        subcategory = "The Mysterious Affair of Sara Shenk",
        master = "Mysterious Affair of Sara Shenk BCOM",
        text = "Investigate rumors of moon sugar and skooma at the inn in Caldera."
    },
    {
        id = "aa_shenk03",
        name = "The Mysterious Affair of Sara Shenk: The Debt",
        category = "Miscellaneous",
        subcategory = "The Mysterious Affair of Sara Shenk",
        master = "Mysterious Affair of Sara Shenk BCOM",
        text = "Investigate the source of an innkeeper's unexplained wealth."
    },
    {
        id = "aa_shenk03a",
        name = "The Mysterious Affair of Sara Shenk: The Debt",
        category = "Miscellaneous",
        subcategory = "The Mysterious Affair of Sara Shenk",
        master = "Mysterious Affair of Sara Shenk BCOM",
        text = "Investigate rumors that Shenk was involved in a heist on a Great House vault."
    },
    {
        id = "aa_shenk03b",
        name = "The Mysterious Affair of Sara Shenk: The Debt",
        category = "Miscellaneous",
        subcategory = "The Mysterious Affair of Sara Shenk",
        master = "Mysterious Affair of Sara Shenk BCOM",
        text = "Investigate rumors connecting the innkeeper Shenk to the Camonna Tong."
    },
    {
        id = "aa_shenk03c",
        name = "The Mysterious Affair of Sara Shenk: The Debt",
        category = "Miscellaneous",
        subcategory = "The Mysterious Affair of Sara Shenk",
        master = "Mysterious Affair of Sara Shenk BCOM",
        text = "Look into a rumored connection between Shenk and a man in Suran."
    },
    {
        id = "aa_shenk03d",
        name = "The Mysterious Affair of Sara Shenk: The Debt",
        category = "Miscellaneous",
        subcategory = "The Mysterious Affair of Sara Shenk",
        master = "Mysterious Affair of Sara Shenk BCOM",
        text = "Investigate rumors that Shenk acquired wealth through inheritance or a lucky find."
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
-- Quest count: 8
