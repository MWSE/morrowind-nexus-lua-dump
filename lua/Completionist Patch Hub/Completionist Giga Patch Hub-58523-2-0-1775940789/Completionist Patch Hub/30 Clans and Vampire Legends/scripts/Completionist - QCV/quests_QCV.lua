local self = require('openmw.self')

local quests = {

    {
        id = "VA_TheQuarraBloodlineSecrets_Elayne_U",
        name = "The Quarra Bloodline Secrets",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Follow up on what Cienne revealed."
    },

    {
        id = "VA_FelarasArtOfNecromancy_Elayne_U",
        name = "Felara's Art of Devilish Necromancy",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Help Felara Varan of the Ferver Clan practice the arts of Conjuration and Necromancy."
    },

    {
        id = "VA_ToKillADerangedThrall_Elayne_U",
        name = "To Kill a Deranged Thrall",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Take on a dangerous mission against a rival or hostile threat."
    },

    {
        id = "VA_LegendQuarraMatriarch_Elayne_U",
        name = "The Legendary Quarra Matriarch",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Follow up on what Sebaonard Nermierie revealed."
    },

    {
        id = "VA_NoStoneLeftUnturned_Elayne_U",
        name = "No Stone Left Unturned",
        category = "Miscellaneous",
        subcategory = "",
        master = "Clans and Vampire Legends",
        text = "Help Cienne retrieve some enchanted weed seeds from Aurane Frernis, an upstart apothecary in Vivec's Foreign Quarter."
    },

    {
        id = "VA_PotentWereboarBlood_Elayne_U",
        name = "New Potent Wereboar Blood",
        category = "Vampire Clans",
        subcategory = "",
        master = "Clans and Vampire Legends",
        text = "Pursue a task tied to the rival vampire clans of Vvardenfell."
    },

    {
        id = "VA_RepelQuarraInvasion_Elayne_U",
        name = "Repel the Quarra Invasion",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Answer Lord Mehrar Urves's request and deal with the Quarra intruders that entered the ruins not so long ago."
    },

    {
        id = "VA_RivalBeyondTheGrave_Elayne_U",
        name = "Rivalry Beyond the Grave",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Follow up on what Wesley the Blade of the Quarra clan revealed."
    },

    {
        id = "VA_MehrarSpearTraining_Elayne_U",
        name = "Urves Family Values",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Lord Mehrar Urves practice with spears."
    },

    {
        id = "VA_MastriusEbonyArmor_Elayne_U",
        name = "Bloodforged Ebony Armor",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Svarg bring him the full set of ebony armor worn by Mastrius, the vampire imprisoned by Azura."
    },

    {
        id = "VA_QuarraClanReunited_Elayne_U",
        name = "Quarra Clan, Reunited at Last",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Earn favor and navigate the politics of a vampire bloodline."
    },

    {
        id = "VA_VampireClanCulling_Elayne_U",
        name = "The Vampire Clan Culling Mission",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Take on a dangerous mission against a rival or hostile threat."
    },

    {
        id = "VA_LamentConfigDwemer_Elayne_U",
        name = "A Very Special Dwemer Artifact",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Help Felara Varan of the Ferver Clan talk to Ferver himself and find out what happened to the lost Dwemer artifact he once had."
    },

    {
        id = "VA_SubjugateSmugglers_Elayne_U",
        name = "Friendly Neighborhood Cattle",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Investigate a matter involving Cienne."
    },

    {
        id = "VA_VolrinasWarVSBerne_Elayne_U",
        name = "Volrina's War against Clan Berne",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Follow up on what Volrina Quarra revealed."
    },

    {
        id = "VA_KillMansionHaunts_Elayne_U",
        name = "Beware of the Menacing Phantoms",
        category = "Miscellaneous",
        subcategory = "",
        master = "Clans and Vampire Legends",
        text = "Help A strange Imperial girl called Elayne get rid of several ghosts that haunt her giant underground dwelling, the one she calls a 'mansion'."
    },

    {
        id = "VA_ThirtyDwemerCoins_Elayne_U",
        name = "For Thirty Dwemer Coins...",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Investigate a troubling discovery tied to vampire intrigues."
    },

    {
        id = "VA_SilenceOfTheGuars_Elayne_U",
        name = "Silence of the Guars",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Gamorea of the Quarra clan bring her a portion of Sload Soap, saying it would help her heal our cattle."
    },

    {
        id = "VA_SvargsLuckyHammer_Elayne_U",
        name = "Sweet Dreams are Made of This...",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Follow a troubling vision tied to vampire affairs."
    },

    {
        id = "VA_AundaeAltmerPurge_Elayne_U",
        name = "The Great Aundae Altmer Purge",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Act on a troubling vision tied to vampire affairs."
    },

    {
        id = "VA_LumenostasisExTenebris_BER",
        name = "Find a Copy of 'Lumenostasis ex Tenebris'",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_CliffRacerPlumesOhtwe_CAVD",
        name = "Cliff Racer Plumes for Ohtwe",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Ohtwe, the devoted follower of Mistress Earaya of the Andus Aundae Coven, gather 10 Cliff Racer plumes for her alchemical experiments."
    },

    {
        id = "VA_AncientNecroRing_Elayne_U",
        name = "Ancient Necromancer's Rings",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Elder Elayne of the Quarra clan retrieve an Ancient Necromancer's Ring from a vampire living somewhere close to Tel Mora."
    },

    {
        id = "VA_MoreMouthsToFeed_Elayne_U",
        name = "More Mouths to Feed",
        category = "Miscellaneous",
        subcategory = "",
        master = "Clans and Vampire Legends",
        text = "Help Selena Automia talk to Hubert about our blood supply situation."
    },

    {
        id = "VA_RawEbonyForSvarg_Elayne_U",
        name = "Raw Ebony Material for Svarg",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Svarg the Anvilbreaker of the Quarra clan get him 30 pieces of raw ebony."
    },

    {
        id = "VA_GiftForTrebonius_Elayne_U",
        name = "A Gift for Trebonius",
        category = "Miscellaneous",
        subcategory = "",
        master = "Clans and Vampire Legends",
        text = "Seek out a notable item tied to vampire intrigues."
    },

    {
        id = "VA_FaelansEbonyScimitar_CAVD",
        name = "Faelan's Enchanted Scimitar",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Mollrion Caemfhaer of the Selaro Ancestral Tomb's Aundae coven bring him Faelan's enchanted ebony scimitar."
    },

    {
        id = "VA_OpusculusLamaeBalVOne_BER",
        name = "Find the First Volume of 'Opusculus Lamae Bal'",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Gergio help him find another book to read to pass eternity."
    },

    {
        id = "VA_EltonbrandWesley_Elayne_U",
        name = "The Eltonbrand Blade",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Follow up on what Wesley revealed."
    },

    {
        id = "VA_KillElaniaQuarra_Elayne_U",
        name = "The Quarra's Quarrels",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Quarra."
    },

    {
        id = "VA_ElderSkullsForAundae_CAVD",
        name = "The Legend of Ferver",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Follow up on what Our Ancient, Dhaunayne Aundae, revealed."
    },

    {
        id = "VA_VaranLegacySword_Elayne_U",
        name = "The Lost Varan Trophy Sword",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Help Drinar Varan, the undead husband of Felara, retrieve his legacy sword hidden somewhere below Ferver's lair."
    },

    {
        id = "VA_IraraksUnlordlyDemise_BER",
        name = "Irarak's Unlordly Demise",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Take on a dangerous mission against a rival or hostile threat."
    },

    {
        id = "VA_WingsQueenOfBats_Elayne_U",
        name = "Wings of the Queen of Bats",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_VolrinaDeadPreQ_Elayne_U",
        name = "The Final Death of Volrina Quarra",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Quarra."
    },

    {
        id = "VA_WesleysNewBlade_Elayne_U",
        name = "Wesley's New Blade",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Wesley, a Quarra vampire, give him the unique sword I found in the dungeon beneath the Velothi Underground Mansion."
    },

    {
        id = "VA_KillMoriciusForRaxle_BER",
        name = "The Arrogant Steward",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Take on a dangerous mission against a rival or hostile threat."
    },

    {
        id = "FG_ElaynesIdentity_Elayne_U",
        name = "Elayne's True Identity",
        category = "Factions",
        subcategory = "Fighters Guild",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_StrangeVampCult_Elayne_U",
        name = "A New Strange Vampire Cult in West Gash",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Quarra."
    },

    {
        id = "VA_ABottleOfBrandy_Elayne_U",
        name = "The Thirsty Skeleton",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Help One of Felara's Ancient Skeleton Champions bring him a bottle of Cyrodiilic Brandy."
    },

    {
        id = "VA_HleranGratitude_Elayne_U",
        name = "Hleran's Gratitude",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_FindJeancieleMacile_CAVD",
        name = "A Message for Jeanciele Macile",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help One of the Darethi Aundae Coven vampires, Mynard Jeannick, deliver a note to his associate Jeanciele Macile."
    },

    {
        id = "VA_VUMLLTwoAccess_Elayne_U",
        name = "The Riddle of Bone and Dust",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Ferver."
    },

    {
        id = "VA_TheAndusConspiracy_CAVD",
        name = "The Andus Conspiracy",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_DestroyAundaeCovens_BER",
        name = "Destroy Aundae Covens",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Take on a dangerous mission against a rival or hostile threat."
    },

    {
        id = "VA_TheBeastWithin_Elayne_U",
        name = "The Beast Within",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Help Varisa Urves acquire ten pairs of exquisite shoes for herself and her friend Felara Varan."
    },

    {
        id = "VA_TimedStealthMission_BER",
        name = "Beheading the Temple",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Berne."
    },

    {
        id = "VA_AndarnimarcoGambit_CAVD",
        name = "Andarnimarco's Gambit",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Aundae."
    },

    {
        id = "VA_HildarsCuirass_Elayne_U",
        name = "Hildar's Nordic Ringmail Cuirass",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Hildar, one of the rogue Quarra vampires from Hleran Ancestral Tomb, find her Nordic ringmail cuirass."
    },

    {
        id = "VA_EbonyHelmetsQO_Elayne_U",
        name = "Ebony Helmets for Quarra Leaders",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Svarg the Anvilbreaker deliver ebony helmets to Siri and Mastrius."
    },

    {
        id = "VA_FindElamHleran_Elayne_U",
        name = "Find Elam Hleran",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Darvame Hleran, the Dark Elf caravaner from Seyda Neen, explore Hleran Ancestral Tomb and find her uncle, Elam Hleran."
    },

    {
        id = "VA_HleranVSSelaro_Elayne_U",
        name = "A Favor for Saras Selaro",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Saras Selaro, a Quarra vampire, kill our rivals, the Aundae who settled in Selaro Ancestral Tomb near Ald'ruhn."
    },

    {
        id = "VA_SvargsVisions_Elayne_U",
        name = "Visions and Omens of Uncertain Fate",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_SecretPassage_Elayne_U",
        name = "Forgotten Secrets of Velothi Architecture",
        category = "Miscellaneous",
        subcategory = "",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_TheQuarraHeir_Elayne_U",
        name = "The Rightful Heir of the Quarra Masters",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Cienne find the remaining blood of the Quarra Masters and give it to Elayne."
    },

    {
        id = "VA_CluelessFledgling_CAVD",
        name = "The Clueless Fledgling",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Hleras Sadas bring him a copy of the 'Vampires of Vvardenfell, Volume I'."
    },

    {
        id = "FG_RervmonsDeath_Elayne_U",
        name = "Rervmon's Sudden Death",
        category = "Factions",
        subcategory = "Fighters Guild",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Fighters Guild."
    },

    {
        id = "VA_HleranProblem_Elayne_U",
        name = "Dothagor's Hleran Problem",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Earn favor and navigate the politics of a vampire bloodline."
    },

    {
        id = "VA_WarringCovens_Elayne_U",
        name = "The Warring Covens",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Elayne eliminate every Aundae vampire inside the Selaro Ancestral Tomb, located west of Ald-Ruhn."
    },

    {
        id = "VA_AshmelechConverts_CAVD",
        name = "The Converts of Ashmelech",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Earn favor and navigate the politics of a vampire bloodline."
    },

    {
        id = "VA_AnainasLuckyCharm_CAVD",
        name = "Anaina's Lucky Charm",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Seek out a notable item tied to vampire intrigues."
    },

    {
        id = "VA_HealingWounds_Elayne_U",
        name = "The Wounds That Won't Heal",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Igna acknowledged her role in Svarg's mental decline and speak with him on her behalf."
    },

    {
        id = "VA_FindKihselokh_Elayne_U",
        name = "Find Vi'sratj Kihselokh",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Dro'Jhor, one of the Quarra vampires from Hleran Ancestral Tomb, find his friend, Vi'sratj Kihselokh, and make sure he is doing well."
    },

    {
        id = "VA_MastriusAlly_Elayne_U",
        name = "Recruit Mastrius of the Quarra Bloodline",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Elayne help free Mastrius, a powerful old Quarra Vampire."
    },

    {
        id = "VA_TombOfFerver_Elayne_U",
        name = "Tomb of Ferver",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Ferver."
    },

    {
        id = "VA_FelarasSkirt_Elayne_U",
        name = "A Skirt for Felara",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Help Felara Varan bring her an exquisite skirt."
    },

    {
        id = "VA_KillYoungerQuarra_BER",
        name = "Yet Another Quarra Girl",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Moricius Procrastius find a kill a relative of Volrina Quarra, her hiding place should be somewhere near Seyda Neen."
    },

    {
        id = "VA_ScrollsForArenara_BER",
        name = "Scrolls for Arenara",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Arenara, the blacksmith of the Berne clan, bring her three Scrolls of Savage Might and one Scroll of The Gambler's Prayer."
    },

    {
        id = "VA_VerverSkulls_Elayne_U",
        name = "Nervala's Last Will",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_RavnilFindCienne_CAVD",
        name = "Find Cienne for Ravnil",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Ravnil, the Elder of the Verver Aundae Coven find and eliminate Cienne, a failed convert kidnapped by the Quarra vampires."
    },

    {
        id = "VA_FerverVerver_Elayne_U",
        name = "Ferver and Verver",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Earn favor and navigate the politics of a vampire bloodline."
    },

    {
        id = "VA_SelaroRescue_Elayne_U",
        name = "Rescue Salver Selaro",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Sebaonard Nermierie, the bard, rescue his friend, Salver Selaro, if he is still alive."
    },

    {
        id = "FG_OneStepAhead_Elayne_U",
        name = "One Step Ahead of Them",
        category = "Factions",
        subcategory = "Fighters Guild",
        master = "Clans and Vampire Legends",
        text = "Help Percius Mercius eliminate all vampires in the abandoned Selaro Ancestral tomb."
    },

    {
        id = "VA_MarilAndSondonea_CAVD",
        name = "Maril and Sondonea",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Maril Thelas, one of Irarak's minions, find a woman called Sondonea Dradrel."
    },

    {
        id = "VA_InfiltrateCovens_CAVD",
        name = "Infiltrate Aundae Covens",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Aundae."
    },

    {
        id = "VA_VisitTelFyr_Elayne_U",
        name = "A visit to Tel Fyr",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Help Lord Mehrar Urves visit Tel Fyr and bring one of Ferver's ancient Dwemer spears as a gift to Divayth Fyr, who apparently was Mehrar's friend once."
    },

    {
        id = "VA_QorrnilsRevenge_CAVD",
        name = "Qorrnil's Bitter Revenge",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Qorrnil kill Ohtwe, another feral Aundae vampire who resides in Andus Ancestral Tomb."
    },

    {
        id = "VA_MararasDeathWish_BER",
        name = "Marara's Death Wish",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Berne."
    },

    {
        id = "VA_SecondTomeSadas_CAVD",
        name = "The Second Tome for Sadas",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Pursue knowledge connected to dark lore and vampire affairs."
    },

    {
        id = "VA_FateOfSentinels_CAVD",
        name = "The Fate of Aundae Sentinels",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_WarnBaladas_Elayne_U",
        name = "Warn Baladas Demnevanni",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Take on a dangerous mission against a rival or hostile threat."
    },

    {
        id = "VA_EscapeUnderworks_BER",
        name = "Vivicia's Escape",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Raxle's agent obtain several parts of Indoril Armor worn by the Ordinators of the Tribunal Temple."
    },

    {
        id = "VA_HildarsPlea_Elayne_U",
        name = "Hildar's Plea",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Aundae."
    },

    {
        id = "VA_HleranATomb_Elayne_U",
        name = "Expanding the Clan: Hleran Ancestral Tomb",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Aundae."
    },

    {
        id = "VA_DustToDust_Elayne_U",
        name = "Dust to Dust",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Cienne, the servant of Elayne of the Quarra Clan Outcasts, bring her ten portions of vampire dust and a Quality Spell Absorption potion."
    },

    {
        id = "VA_TharenTakeover_CAVD",
        name = "Tharen Takeover",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Olyls Guvthril, a Dunmer vampire who resides inside Tharen Ancestral Tomb, help him with a coup against his master, Faelan Thromeus."
    },

    {
        id = "VA_HuntDownStaada_CAVD",
        name = "Banish Staada",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Gilonilmo Larethal, a powerful Aundae vampire who leads the Darethi coven, help him banish Staada, a daedric servant of Lord Sheogorath."
    },

    {
        id = "VA_EarnBernesTrust_BER",
        name = "A Way to Earn Berne's Trust",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Earn favor and navigate the politics of a vampire bloodline."
    },

    {
        id = "VA_RavnilEmissary_CAVD",
        name = "Ravnil's Emissary to Ashmelech",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Aundae."
    },

    {
        id = "VA_UndyingFashion_CAVD",
        name = "Undying Fashion",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Niren Kaelock of the Darethi Aundae Coven acquire three exquisite robes, exactly like her own."
    },

    {
        id = "VA_VarisaRing_Elayne_U",
        name = "Varisa's Wedding Ring",
        category = "Vampire Clans",
        subcategory = "Clan Ferver",
        master = "Clans and Vampire Legends",
        text = "Help Varisa Urves kill Felara's skeleton minions until I find her wedding ring."
    },

    {
        id = "VA_HealBerneCattle_BER",
        name = "Clasomo's Healthy Food",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Berne."
    },

    {
        id = "VA_SirisGrief_Elayne_U",
        name = "Siri's Grief",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Help Overcome with grief, Siri find a small soul gem she once gave to Elayne as a gift."
    },

    {
        id = "VA_YarilsConcerns_CAVD",
        name = "Yaril's Concerns",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Earn favor and navigate the politics of a vampire bloodline."
    },

    {
        id = "VA_SheoCheese_Elayne_U",
        name = "A Cheesy Situation",
        category = "Miscellaneous",
        subcategory = "",
        master = "Clans and Vampire Legends",
        text = "Pursue the matter known as A Cheesy Situation."
    },

    {
        id = "VA_SelaroVSHleran_CAVD",
        name = "Kill Saras Selaro",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Nirlae Koreus enter Hleran Ancestral Tomb and kill Saras Selaro."
    },

    {
        id = "VA_AnjasFate_Elayne_U",
        name = "Anja's Fate",
        category = "Vampire Clans",
        subcategory = "Clan Quarra",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_GiftForEaraya_CAVD",
        name = "A Gift for Earaya",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Earaya of the Aundae bloodline bring her a ruby to thank her for welcoming me in her lair."
    },

    {
        id = "VA_RattleMeBones_CAVD",
        name = "Rattle Me Bones",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Sealdur Silinael bring him a servant's skull to repair Earaya's favorite skeleton minion, Old Rattleslink."
    },

    {
        id = "VA_ToolsForGermia_BER",
        name = "Cheap Thieves' Tools for Germia",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Germia of the Berne clan bring her at least ten Master's Lockpicks and eight Master's Probes."
    },

    {
        id = "VA_BooksForGergio_BER",
        name = "Gergio the Bookworm",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Gergio, one of the Berne vampires, bring him a book written by Crassius Curio."
    },

    {
        id = "VA_CureRatSelaro_CAVD",
        name = "A Cure for Squabbles",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Mollrion Caemfhaer of the Selaro Aundae Coven help him cure his pet rat, Squabbles."
    },

    {
        id = "VA_WorthyNeonate_CAVD",
        name = "A Worthy Aundae Neonate",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Earn favor and navigate the politics of a vampire bloodline."
    },

    {
        id = "VA_SkeletonCrew_CAVD",
        name = "Our New Skeleton Crew",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Nirlae Koreus, one of the Aundae vampire leaders, bring her three silver longswords to arm her skeleton sentinels with."
    },

    {
        id = "VA_RavnilAmulet_CAVD",
        name = "Ravnil's Lost Amulet",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help A powerful Aundae vampire named Ravnil find her amulet."
    },

    {
        id = "VA_RindonasMate_CAVD",
        name = "A Soulless Mate for Rindona",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help Rindona Barkwood, a female Aundae Bosmer vampire from the Darethi Aundae Coven, help her find a handsome Bosmer lad she once met while travelling across the island of Vvardenfell."
    },

    {
        id = "VA_IldogestosKey_BER",
        name = "Ildogesto's Key",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Ildogesto take his key to Galom Daeus and place it in Moricius' pocket, claiming it would be a pleasant surprise for our steward's amusement."
    },

    {
        id = "VA_VevulsNewLair_BER",
        name = "A New Lair for Vevul Menarys",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Berne."
    },

    {
        id = "VA_AnainasFall_CAVD",
        name = "Anaina's Fall from Grace",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Help One of the Darethi Aundae vampires, the one who calls herself 'Anaina', plead her case in front of Dhaunayne Aundae, swearing she was our Matriarch's loyal subject, unlike most other vampires of the Darethi Aundae Coven."
    },

    {
        id = "VA_LlovynAndus_CAVD",
        name = "Eliminate Llovyn Andus",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Carry out a task connected to Clan Aundae."
    },

    {
        id = "VA_GadelaAndus_CAVD",
        name = "Kill Gadela Andus",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Take on a dangerous mission against a rival or hostile threat."
    },

    {
        id = "VA_DrarelAndus_CAVD",
        name = "Murder Drarel Andus",
        category = "Vampire Clans",
        subcategory = "Clan Aundae",
        master = "Clans and Vampire Legends",
        text = "Investigate a hidden matter tied to the island's vampire clans."
    },

    {
        id = "VA_HelpIlana_BER",
        name = "Help Ilana's Twisted Sister",
        category = "Vampire Clans",
        subcategory = "Clan Berne",
        master = "Clans and Vampire Legends",
        text = "Help Ilana, the 'twin' sister of Eloe of the Berne clan, learn the reason behind her abnormal behavior."
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

-- Quest count: 113
