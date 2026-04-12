local self = require('openmw.self')

local quests = {

    {
        id = "BS_RelmynaFetcher1",
        name = "Relmyna's Fetcher",
        category = "Sheogorath",
        subcategory = "Shivering Isles",
        master = "The Doors of Oblivion",
        text = "Relmyna Verenim has asked me to gather several unusual ingredients for her."
    },

    {
        id = "BS_jointhekitchen1",
        name = "Uleni's Kitchen",
        category = "Clavicus Vile",
        subcategory = "Kitchen",
        master = "The Doors of Oblivion",
        text = "I should speak with Chef Uleni about earning a place in her kitchen."
    },

    {
        id = "BS_MorphoidFetch1",
        name = "Gold For A Morphoid",
        category = "Sheogorath",
        subcategory = "Shivering Isles",
        master = "The Doors of Oblivion",
        text = "A morphoid named Salgg wants me to recover a debt from a seducer."
    },

    {
        id = "BS_SmithDelivery1",
        name = "Serlene's Delivery",
        category = "Coldharbour",
        subcategory = "Fortress",
        master = "The Doors of Oblivion",
        text = "Serlene the smith has asked me to carry out a troublesome delivery for her."
    },

    {
        id = "BS_wheedleserror2",
        name = "All Namira's Children",
        category = "Namira",
        subcategory = "",
        master = "The Doors of Oblivion",
        text = "I must help return stolen belongings to their rightful owners."
    },

    {
        id = "BS_sanguinecalls1",
        name = "Sanguine Calls",
        category = "Sanguine",
        subcategory = "Pelagiad",
        master = "The Doors of Oblivion",
        text = "Sanguine has sent me to persuade a mortal in Pelagiad to enter his service."
    },

    {
        id = "BS_PerfectSpool1",
        name = "The Perfect Spool",
        category = "Sheogorath",
        subcategory = "Shivering Isles",
        master = "The Doors of Oblivion",
        text = "A bosmer named Pengael desires a perfectly wound spool."
    },

    {
        id = "BS_UnusualAmber1",
        name = "An Unusual Acquisition",
        category = "Sheogorath",
        subcategory = "Shivering Isles",
        master = "The Doors of Oblivion",
        text = "Delvas Norend is seeking rare curiosities from across the realms."
    },

    {
        id = "BS_TankardFetch1",
        name = "Valeth's Tankard",
        category = "Sheogorath",
        subcategory = "Court of Contested Acquisition",
        master = "The Doors of Oblivion",
        text = "Valeth wants me to recover his lost tankard from the Court of Contested Acquisition."
    },

    {
        id = "BS_argonianfood1",
        name = "Food for a Slave",
        category = "Coldharbour",
        subcategory = "Ashen Mines",
        master = "The Doors of Oblivion",
        text = "Zeenana has asked me to carry food to her husband in the Ashen Mines."
    },

    {
        id = "BS_SaalumoFetch1",
        name = "Ingredients for Saalumo",
        category = "Clavicus Vile",
        subcategory = "Kitchen",
        master = "The Doors of Oblivion",
        text = "Chef Saalumo needs uncommon ingredients gathered from several realms."
    },

    {
        id = "BS_hernetrouble1",
        name = "Herne Trouble",
        category = "Sanguine",
        subcategory = "The Sundark Drape",
        master = "The Doors of Oblivion",
        text = "There is trouble with local herne in the Sundark Drape, and I should investigate."
    },

    {
        id = "BS_vaerminatask1",
        name = "Pegaro's Neglect",
        category = "Vaermina",
        subcategory = "Sanguine's Demesne",
        master = "The Doors of Oblivion",
        text = "Vaermina has entrusted me with a delivery to one of her servants."
    },

    {
        id = "BS_mehrunestask1",
        name = "Dagon's Request",
        category = "Mehrunes Dagon",
        subcategory = "Ebonheart",
        master = "The Doors of Oblivion",
        text = "Mehrunes Dagon has ordered me to slay an Imperial governor in Ebonheart and recover his papers."
    },

    {
        id = "BS_Dawnbreaker1",
        name = "Trouble for Meridia",
        category = "Meridia",
        subcategory = "Gaihl",
        master = "The Doors of Oblivion",
        text = "Meridia has asked me to investigate an attack upon her realm and recover a missing sword."
    },

    {
        id = "BS_MaggothKill1",
        name = "Dust to Dust",
        category = "Mehrunes Dagon",
        subcategory = "Maggoth's Prison",
        master = "The Doors of Oblivion",
        text = "Fasette Imonde wants me to gather grave dust from Maggoth's Prison."
    },

    {
        id = "BS_moriansbook1",
        name = "Book Hunter",
        category = "Hermaeus Mora",
        subcategory = "Apocrypha",
        master = "The Doors of Oblivion",
        text = "Morian Zenas has asked me to search Apocrypha for a lost book."
    },

    {
        id = "BS_dremorabelt1",
        name = "A Dremora's Pittance",
        category = "Mehrunes Dagon",
        subcategory = "Molten Halls",
        master = "The Doors of Oblivion",
        text = "A dremora will trade me a key if I can bring him a new belt."
    },

    {
        id = "BS_dwemerneeds1",
        name = "Dwemer Needs",
        category = "Miscellaneous",
        subcategory = "Dwemer",
        master = "The Doors of Oblivion",
        text = "An ancient dwemer wants help recovering his lost centurion and other belongings."
    },

    {
        id = "BS_lutestrings1",
        name = "Strings for Cadwell",
        category = "Coldharbour",
        subcategory = "Cadwell",
        master = "The Doors of Oblivion",
        text = "Cadwell has asked me to learn why his new lute strings have not arrived."
    },

    {
        id = "BS_NamiraKill1",
        name = "Namira's Bidding",
        category = "Namira",
        subcategory = "",
        master = "The Doors of Oblivion",
        text = "Namira has commanded me to deal with an intruder in her realm."
    },

    {
        id = "BS_UleniFetch1",
        name = "Helping a Hob",
        category = "Clavicus Vile",
        subcategory = "Kitchen",
        master = "The Doors of Oblivion",
        text = "Chef Uleni needs me to gather ingredients for her kitchen."
    },

    {
        id = "BS_MadBrother1",
        name = "Inganare's Brother",
        category = "Meridia",
        subcategory = "",
        master = "The Doors of Oblivion",
        text = "Inganare has asked me to search for his missing brother in Meridia's realm."
    },

    {
        id = "BS_sloadfetch1",
        name = "N'Gasta's Experiment",
        category = "Hermaeus Mora",
        subcategory = "Apocrypha",
        master = "The Doors of Oblivion",
        text = "N'Gasta has enlisted me to gather rare materials for one of his experiments."
    },

    {
        id = "BS_helpaltren1",
        name = "Dealing With Thendaramil",
        category = "Clavicus Vile",
        subcategory = "Kitchen",
        master = "The Doors of Oblivion",
        text = "Chef Altren wants my help in dealing with a difficult patron."
    },

    {
        id = "BS_sweetrolls1",
        name = "Pegdel's Obsession",
        category = "Clavicus Vile",
        subcategory = "Caprice",
        master = "The Doors of Oblivion",
        text = "A bosmer named Pegdel has asked me to keep him supplied with sweet rolls."
    },

    {
        id = "BS_ElvaysBowl1",
        name = "Elvays' Bowl",
        category = "Molag Bal",
        subcategory = "Burgeoning Bowels",
        master = "The Doors of Oblivion",
        text = "Procis Pleborius wants me to find out why Elvays has neglected his task and recover an important bowl."
    },

    {
        id = "BS_lillandril1",
        name = "Flask of Lillandril",
        category = "Clavicus Vile",
        subcategory = "Caprice",
        master = "The Doors of Oblivion",
        text = "Clavicus Vile has spoken to me about the Flask of Lillandril now in my possession."
    },

    {
        id = "BS_lostsister1",
        name = "Find Corda",
        category = "Clavicus Vile",
        subcategory = "Caprice",
        master = "The Doors of Oblivion",
        text = "Haroon has asked me to look for his missing sister, Corda."
    },

    {
        id = "BS_barbasgone1",
        name = "The Wayward Hound",
        category = "Clavicus Vile",
        subcategory = "Caprice",
        master = "The Doors of Oblivion",
        text = "Barbas has gone missing, and Clavicus Vile wants me to discover what happened."
    },

    {
        id = "BS_ForgeRest1",
        name = "To Forge a Respite",
        category = "Coldharbour",
        subcategory = "Bleeding Forge",
        master = "The Doors of Oblivion",
        text = "Finius wants me to deal with the guards of the Bleeding Forge so the workers may rest."
    },

    {
        id = "BS_Moonstone1",
        name = "Moonstone and a Shortsword",
        category = "Meridia",
        subcategory = "Sile Alari",
        master = "The Doors of Oblivion",
        text = "Inganare is waiting on a moonstone shortsword, and I have agreed to see it delivered."
    },

    {
        id = "BS_scampneed1",
        name = "A Scamp In Need",
        category = "Coldharbour",
        subcategory = "Fortress",
        master = "The Doors of Oblivion",
        text = "A scamp in Coldharbour has offered me a key if I help it with a dangerous problem."
    },

    {
        id = "BS_sheoprank1",
        name = "A Gift of Cheer",
        category = "Sheogorath",
        subcategory = "Coldharbour",
        master = "The Doors of Oblivion",
        text = "Sheogorath has given me a strange errand to carry out before Molag Bal."
    },

    {
        id = "BS_sapfetch1",
        name = "Sap Fetcher",
        category = "Clavicus Vile",
        subcategory = "Meridia's Realm",
        master = "The Doors of Oblivion",
        text = "A servant of Clavicus Vile has asked me to bring her two kinds of healing sap."
    },

    {
        id = "BS_cvkiller1",
        name = "Kill the Traitor",
        category = "Clavicus Vile",
        subcategory = "Solstheim",
        master = "The Doors of Oblivion",
        text = "Clavicus Vile has sent me to hunt down a traitor on Solstheim."
    },

    {
        id = "BS_twosons2",
        name = "Two Sons",
        category = "Malacath",
        subcategory = "",
        master = "The Doors of Oblivion",
        text = "An orc matron wants me to help one of her sons remember his duty and honor."
    },

    {
        id = "BS_twosons3",
        name = "Two Sons",
        category = "Malacath",
        subcategory = "",
        master = "The Doors of Oblivion",
        text = "An orc matron wants me to help one of her sons remember his duty and honor."
    },

    {
        id = "BS_thegoat1",
        name = "A Goat In Despair",
        category = "Sanguine",
        subcategory = "The Sundark Drape",
        master = "The Doors of Oblivion",
        text = "Sanguine's black goat has begged me to free him from his present bondage."
    },

    {
        id = "BS_xivkill1",
        name = "Baulshur's Soul",
        category = "Coldharbour",
        subcategory = "",
        master = "The Doors of Oblivion",
        text = "Rathyn Varil has asked me to hunt down the xivilai Baulshur and claim his soul."
    },

    {
        id = "BS_Akrash1",
        name = "A New Scabbard For Akrash",
        category = "Clavicus Vile",
        subcategory = "Caprice",
        master = "The Doors of Oblivion",
        text = "I have purchased Akrash's sword from Peliah Minegaur."
    },

    {
        id = "BS_serset1",
        name = "Helping a Harpy",
        category = "Azura",
        subcategory = "",
        master = "The Doors of Oblivion",
        text = "A harpy named Serset has asked me for help with a hunter who preys upon her kind."
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
-- Quest count: 42