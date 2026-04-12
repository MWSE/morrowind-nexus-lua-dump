local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Wyrmhaven
    -- #########################################################################

    {
        id = "WYRM_12_DarkBrotherhood",
        name = "Order of Kynareth: Attempted Murder",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "One has reported their success to Lady Olivia -- if it can indeed be called a success, with the threat of death still hanging over Centurion Marhaus."
    },
    {
        id = "WYRM_00_EadricsTower",
        name = "Wyrmhaven: Eadric's Tower",
        category = "Miscellaneous",
        subcategory = "",
        master = "Wyrmhaven", text = "One has purchased Eadric's Tower from Alboin for the sum of 100,000 gold."
    },
    {
        id = "WYRM_14_BlackKnight",
        name = "Order of Kynareth: The Black Knight",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Lady Olivia has asked that we do not speak of the Black Knight again."
    },
    {
        id = "WYRM_19_Chimeranyon",
        name = "Order of Kynareth: Chimeranyon",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Knight-Marshal Lucius praised them for returning the Girdle of Belaurin and the body of Sir Uldor."
    },
    {
        id = "WYRM_20_FalseKnight",
        name = "Order of Kynareth: The False Knight",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Complete a task for Order of Kynareth."
    },
    {
        id = "WYRM_06_Worshipper",
        name = "Order of Kynareth: Daedra Worship in Wyrmhaven",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "A local adventurer brought their evidence of Gaius Eudonius' Daedra worship to Sir Beowine."
    },
    {
        id = "WYRM_02_Laureloss",
        name = "Order of Kynareth: Sir Laureloss",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "A local adventurer told Sir Beowine that Sir Laureloss had come down with food poisoning."
    },
    {
        id = "WYRM_21_Espionage",
        name = "Order of Kynareth: Gathering Intelligence",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "The Knight-Marshal was intrigued by this revelation, and agrees that we will need to work closely with the Legion."
    },
    {
        id = "WYRM_04_Shrunken",
        name = "Order of Kynareth: A Small Problem",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Sir Beowine was pleased that Goriath has been found."
    },
    {
        id = "WYRM_08_Sabotage",
        name = "Order of Kynareth: Sabotage",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Lady Olivia thanked them for successfully planting the fake skooma."
    },
    {
        id = "WYRM_10_Caedmund",
        name = "Order of Kynareth: The Bones of Caedmund",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Grandmaster Raedwald was pleased that his ancestor's remains have been returned to their original resting place."
    },
    {
        id = "WYRM_11_Werewolf",
        name = "Order of Kynareth: Werewolves of Wyrmhaven",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Lady Olivia was impressed with our handling of the werewolf attack."
    },
    {
        id = "WYRM_05_Braglor",
        name = "Order of Kynareth: Braglor",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Sir Ambrose was ecstatic, and called it "one of the most exciting archaeological discoveries of our time"."
    },
    {
        id = "WYRM_13_Godfrey",
        name = "Order of Kynareth: Prison Break",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Damn it! one has forgotten to take off their uniform, and one of the guards has identified them as a Knight of Kynareth."
    },
    {
        id = "WYRM_15_Ufedhin",
        name = "Order of Kynareth: Ufedhin",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Complete a task for Order of Kynareth."
    },
    {
        id = "WYRM_17_Reavers",
        name = "Order of Kynareth: Eviction Notice",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "A local adventurer reported their success to the Knight-Marshal."
    },
    {
        id = "WYRM_25_Council",
        name = "Order of Kynareth: A Change of Leadership",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Grandmaster Raedwald and one confronted Lucius and told him of his impending demotion."
    },
    {
        id = "WYRM_26_Endgame",
        name = "Order of Kynareth: Endgame",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "One has chosen Lady Gwendelin to be their Knight-Captain."
    },
    {
        id = "WYRM_03_Corpse",
        name = "Order of Kynareth: Washed Up",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Sir Beowine thanked them for bringing Romulus Nero to justice, though regretted that he could not be taken alive."
    },
    {
        id = "WYRM_16_Squire",
        name = "Order of Kynareth: Choosing a Squire",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "One has chosen Squire Gwendelin."
    },
    {
        id = "WYRM_23_Attack",
        name = "Order of Kynareth: Caedmund's Wake",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Their squire is now a Knight-Errant."
    },
    {
        id = "WYRM_24_Ledger",
        name = "Order of Kynareth: Thief in the Night",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "The Knight-Marshal thanked them for bringing him the shipping ledger."
    },
    {
        id = "WYRM_01_Armor",
        name = "Order of Kynareth: A Trip to the Smithy",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "One has returned the repaired equipment to Lady Olivia, Sir Monty, Sir Fenris and Marianne."
    },
    {
        id = "WYRM_09_Troll",
        name = "Order of Kynareth: Trollslayer",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "One has brought Lady Olivia a troll's heart."
    },
    {
        id = "WYRM_18_Witch",
        name = "Order of Kynareth: Witchhunt",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "The Knight-Marshal was pleased to learn of Morag's "demise"."
    },
    {
        id = "WYRM_07_Alms",
        name = "Order of Kynareth: Alms for the Poor",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "A local adventurer gave Lady Olivia the alms money one collected."
    },
    {
        id = "WYRM_22_Baby",
        name = "Order of Kynareth: A Miscarriage of Justice",
        category = "Miscellaneous",
        subcategory = "Order of Kynareth",
        master = "Wyrmhaven", text = "Knight-Marshal Lucius thanked them for dealing with his delicate matter."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Wyrmhaven data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 27
