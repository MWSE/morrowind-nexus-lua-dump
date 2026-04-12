local self = require('openmw.self')
local quests = {
    {
        id = "AG_JP3SealockCharter",
        name = "Astrologians Guild: Guild Hall at Sealock",
        category = "Factions | Astrologians Guild",
        subcategory = "Sealock Charter",
        master = "Astrologian's Guild",
        text = "I should travel to Sealock Charter and check on the progress of the guild hall there."
    },

    {
        id = "AG_JP3PeaceOffering",
        name = "Astrologians Guild: Peace Offering",
        category = "Factions | Astrologians Guild",
        subcategory = "Sealock Charter",
        master = "Astrologian's Guild",
        text = "I should speak with the hermit near Sealock Charter and learn what he wants."
    },

    {
        id = "AG_JSSDwemerArmor",
        name = "Astrologians Guild: Orbital Armor",
        category = "Factions | Astrologians Guild",
        subcategory = "Galom Daeus",
        master = "Astrologian's Guild",
        text = "I should aid the Dwemer astrologers of Galom Daeus in restoring an unusual piece of armor."
    },

    {
        id = "AG_JP3ArkBandits",
        name = "Astrologians Guild: Arkgnthand Bandits",
        category = "Factions | Astrologians Guild",
        subcategory = "Arkngthand",
        master = "Astrologian's Guild",
        text = "I have been asked to clear the bandits from Arkngthand so the guild may study the ruins safely."
    },

    {
        id = "AG_JPostTelvanni",
        name = "Astrologians Guild: Hermit Rescue",
        category = "Factions | Astrologians Guild",
        subcategory = "Sealock Charter",
        master = "Astrologian's Guild",
        text = "I should investigate the matter of the Telvanni and the hermit on Sealock Charter."
    },

    {
        id = "AG_JTreasureHunt",
        name = "Astrologians Guild: Dwemer Trinket Codes",
        category = "Factions | Astrologians Guild",
        subcategory = "Dwemer Research",
        master = "Astrologian's Guild",
        text = "I should search several Dwemer ruins for coded trinkets of interest to the guild."
    },

    {
        id = "AG_JBoxofScrolls",
        name = "Astrologians Guild: Missing Box of Scrolls",
        category = "Factions | Astrologians Guild",
        subcategory = "Guild Hall",
        master = "Astrologian's Guild",
        text = "I should look into the disappearance of a missing box of scrolls from the guild hall."
    },

    {
        id = "AG_JObservatory",
        name = "Astrologians Guild: New Guild Hall",
        category = "Factions | Astrologians Guild",
        subcategory = "Guild Hall",
        master = "Astrologian's Guild",
        text = "I should assist with plans for a new guild hall and its observatory."
    },

    {
        id = "AG_JTelMeridiem",
        name = "Astrologians Guild: Tel Meridiem",
        category = "Factions | Astrologians Guild",
        subcategory = "Twilight Realm",
        master = "Astrologian's Guild",
        text = "I should explore Tel Meridiem and recover anything of value for the guild."
    },

    {
        id = "AG_JNvelDungeon",
        name = "Astrologians Guild: Nvelfingu Velar",
        category = "Factions | Astrologians Guild",
        subcategory = "Twilight Realm",
        master = "Astrologian's Guild",
        text = "I should explore Nvelfingu Velar for charts or records left behind in the ruins."
    },

    {
        id = "AG_JTempDungeon",
        name = "Astrologians Guild: Twilight Temple",
        category = "Factions | Astrologians Guild",
        subcategory = "Twilight Realm",
        master = "Astrologian's Guild",
        text = "I should search the Twilight Temple for anything the guild may find useful."
    },

    {
        id = "AG_JP3GDBandits",
        name = "Astrologians Guild: Galom Daeus Vampire Hunter",
        category = "Factions | Astrologians Guild",
        subcategory = "Galom Daeus",
        master = "Astrologian's Guild",
        text = "I have been asked to hunt down the vampires haunting Galom Daeus."
    },

    {
        id = "AG_JPArkRestore",
        name = "Astrologians Guild: Arkgnthand Observatory",
        category = "Factions | Astrologians Guild",
        subcategory = "Arkngthand",
        master = "Astrologian's Guild",
        text = "I should see to the restoration of the observatory in Arkngthand."
    },

    {
        id = "AG_JRosaAntrum",
        name = "Astrologians Guild: Rosa Antrum",
        category = "Factions | Astrologians Guild",
        subcategory = "",
        master = "Astrologian's Guild",
        text = "I should look into the matter of Rosa Antrum for the Astrologians Guild."
    },

    {
        id = "AG_JP3BookHunt",
        name = "Astrologians Guild: Book Hunt",
        category = "Factions | Astrologians Guild",
        subcategory = "Guild Hall",
        master = "Astrologian's Guild",
        text = "I should locate Bastir's missing book and bring it to Nelangoth."
    },

    {
        id = "AG_JFinalQuest",
        name = "Astrologians Guild: Mystery of Sealock Cave",
        category = "Factions | Astrologians Guild",
        subcategory = "Sealock Charter",
        master = "Astrologian's Guild",
        text = "I should investigate the mystery surrounding the cave beneath Sealock."
    },

    {
        id = "AG_JPostTavern",
        name = "Astrologians Guild: Inn Construction",
        category = "Factions | Astrologians Guild",
        subcategory = "Sealock Charter",
        master = "Astrologian's Guild",
        text = "I should help arrange the construction of an inn at Sealock Charter."
    },

    {
        id = "AG_J8Twilight",
        name = "Astrologians Guild: Rally to the Citadel",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should carry word to the guild and help rally support at the Twilight Citadel."
    },

    {
        id = "AG_JTelDolore",
        name = "Astrologians Guild: Tel Dolore",
        category = "Factions | Astrologians Guild",
        subcategory = "Twilight Realm",
        master = "Astrologian's Guild",
        text = "I should search Tel Dolore for signs of the realm's origins."
    },

    {
        id = "AG_JCityscape",
        name = "Astrologians Guild: Galom Daeus Cityscape",
        category = "Factions | Astrologians Guild",
        subcategory = "Galom Daeus",
        master = "Astrologian's Guild",
        text = "I should explore the cityscape beneath Galom Daeus and tend to the Dwemer machines there."
    },

    {
        id = "AG_JPostNewb1",
        name = "Astrologians Guild: Cirna",
        category = "Factions | Astrologians Guild",
        subcategory = "Recruitment",
        master = "Astrologian's Guild",
        text = "This journal tracks Cirna Virmoriane's assignment within the Astrologians Guild."
    },

    {
        id = "AG_JPostNewb2",
        name = "Astrologians Guild: Dro'garroo",
        category = "Factions | Astrologians Guild",
        subcategory = "Recruitment",
        master = "Astrologian's Guild",
        text = "This journal tracks Dro'garroo's assignment within the Astrologians Guild."
    },

    {
        id = "AG_JPostPylon",
        name = "Astrologians Guild: Pylon Construction",
        category = "Factions | Astrologians Guild",
        subcategory = "Sealock Charter",
        master = "Astrologian's Guild",
        text = "I should help oversee the construction of a pylon at Sealock Charter."
    },

    {
        id = "AG_JPArkExcav",
        name = "Astrologians Guild: Arkgnthand Excavation",
        category = "Factions | Astrologians Guild",
        subcategory = "Arkngthand",
        master = "Astrologian's Guild",
        text = "I should assist with the guild's new excavation deeper within Arkngthand."
    },

    {
        id = "AG_JCaldera2",
        name = "Astrologians Guild: Back to Caldera",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should go to Caldera to find Bastir and see whether Jimore has news for the guild."
    },

    {
        id = "AG_JTelMetus",
        name = "Astrologians Guild: Tel Metus",
        category = "Factions | Astrologians Guild",
        subcategory = "Twilight Realm",
        master = "Astrologian's Guild",
        text = "I should explore Tel Metus for anything that may explain this strange realm."
    },

    {
        id = "AG_JGalomRun",
        name = "Astrologians Guild: Report from Galom Daeus",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should carry a starmap and a report between Galom Daeus and Nelangoth."
    },

    {
        id = "AG_JPostZeal",
        name = "Astrologians Guild: Lost Ruins of Sealock",
        category = "Factions | Astrologians Guild",
        subcategory = "Twilight Realm",
        master = "Astrologian's Guild",
        text = "I should explore the lost ruins beyond the Sealock pylon."
    },

    {
        id = "AG_JP3Portal",
        name = "Astrologians Guild: Portal",
        category = "Factions | Astrologians Guild",
        subcategory = "Guild Hall",
        master = "Astrologian's Guild",
        text = "I should aid Nova with the unstable portal beneath the guild hall."
    },

    {
        id = "AG_JPGDExcav",
        name = "Astrologians Guild: Galom Daeus Excavation",
        category = "Factions | Astrologians Guild",
        subcategory = "Galom Daeus",
        master = "Astrologian's Guild",
        text = "I should join the guild's excavation into the deeper ruins of Galom Daeus."
    },

    {
        id = "AG_J2Quest2",
        name = "Astrologians Guild: Training",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should complete Bastir's training in repairing Dwemer machinery."
    },

    {
        id = "AG_J2Task1",
        name = "Astrologians Guild: Balmora Run",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "Nelangoth has sent me to Balmora to gather supplies and information for the guild."
    },

    {
        id = "AG_J3Task1",
        name = "Astrologians Guild: Secrets of Arkngthand",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should begin my first true assignment by helping excavate the depths of Arkngthand."
    },

    {
        id = "AG_J4Task1",
        name = "Astrologians Guild: Excursion to Galom Daeus",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should travel to Galom Daeus and perform duties for the Astrologians there."
    },

    {
        id = "AG_J5Task1",
        name = "Astrologians Guild: Concoction from Caldera",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should travel to Caldera to obtain a special concoction for Nelangoth."
    },

    {
        id = "AG_J6Task1",
        name = "Astrologians Guild: Stargazing",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should meet Clagen outside Arkngthand and learn to use the Dwemer telescope."
    },

    {
        id = "AG_J7Task1",
        name = "Astrologians Guild: Bitter Coast Discovery",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should find Nova in the Bitter Coast and assist with her Dwemer discovery."
    },

    {
        id = "AG_JP3Rock",
        name = "Astrologians Guild: Mysterious Rock",
        category = "Factions | Astrologians Guild",
        subcategory = "Miscellaneous",
        master = "Astrologian's Guild",
        text = "I should investigate reports of a strange rock in the Grazelands."
    },

    {
        id = "AG_JNote2",
        name = "Astrologians Guild: Reply to Jimore",
        category = "Factions | Astrologians Guild",
        subcategory = "Main Questline",
        master = "Astrologian's Guild",
        text = "I should deliver Nelangoth's reply to Jimore Nerlion of the Mages Guild."
    },

    {
        id = "AG_JNova1",
        name = "Astrologians Guild: Nova",
        category = "Factions | Astrologians Guild",
        subcategory = "Companions",
        master = "Astrologian's Guild",
        text = "I should learn more about Nova and her place within the guild."
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

-- Quest count: 40
