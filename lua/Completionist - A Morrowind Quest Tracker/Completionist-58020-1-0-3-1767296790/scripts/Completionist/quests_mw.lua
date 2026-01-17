local Mechanics = require('scripts.Completionist.mechanics')

local quests = {

    -- #########################################################################
    -- GAME: MORROWIND
    -- #########################################################################

    -- =========================================================================
    -- MAIN QUEST
    -- =========================================================================
    {
        id = "A1_1_FindSpymaster",
        name = "Report to Caius Cosades",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Deliver a package to Caius Cosades in Balmora."
    },
    {
        id = "A1_2_AntabolisInformant",
        name = "Antabolis Informant",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Trade an ancient artifact for an expert's insight."
    },
    {
        id = "C3_DestroyDagoth", --According to the UESp the quest will remain active during the entire Main Quest, and be marked as finished after destroying Dagoth Ur.
        name = "Sleepers Awake",
        category = "Main Quest | Morrowind",
        subcategory = "Optional Quests",
        text = "Save several people from Dagoth Ur's spell."
    },
    {
        id = "A1_4_MuzgobInformant",
        name = "Gra-Muzgob Informant",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Deliver the Skull of Llevule Andrano to Sharn gra-Muzgob in exchange for information that Caius Cosades desires."
    },
    {
        id = "A1_V_VivecInformants, A1_10_MehraMilo, A1_6_AddhiranirrInformant, A1_7HuleeyaInformant",
        name = "Vivec Informants",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Speak with three informants in Vivec about the Nerevarine Cult and the Sixth House."
    },
    {
        id = "A1_11_ZainsubaniInformant",
        name = "Zainsubani Informant",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Seek out Hassour Zainsubani in Ald'ruhn and ask him about the Ashlanders and the Nerevarine Cult."
    },
    {
        id = "A2_1_MeetSulMatuul",
        name = "Meet Sul-Matuul",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Travel to the northern coast to find out more about the Nerevarine Prophecies and how it relates to you."
    },
    {
        id = "A2_2_6thHouse",
        name = "Sixth House Base",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Dispose of a Sixth House base recently discovered near Gnaar Mok."
    },
    {
        id = "A2_3_CorprusCure",
        name = "Corprus Cure",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Find a way to cure the dreaded Corprus disease."
    },
    {
        id = "A2_4_MiloGone",
        name = "Mehra Milo and the Lost Prophecies",
        category = "Main Quest | Morrowind",
        subcategory = "Caius Cosades' Quests",
        text = "Find Mehra Milo in Vivec."
    },
    {
        id = "A2_6_Incarnate",
        name = "The Path of the Incarnate",
        category = "Main Quest | Morrowind",
        subcategory = "Third, Fourth, and Fifth Trial Quests",
        text = "Visit the Urshilaku Camp and complete the Third Trial of the prophecy."
    },
    {
        id = "B5_RedoranHort",
        name = "Redoran Hortator",
        category = "Main Quest | Morrowind",
        subcategory = "Third, Fourth, and Fifth Trial Quests",
        text = "Persuade House Redoran to name you their Hortator."
    },
    {
        id = "B6_HlaaluHort",
        name = "Hlaalu Hortator",
        category = "Main Quest | Morrowind",
        subcategory = "Third, Fourth, and Fifth Trial Quests",
        text = "Persuade House Hlaalu to name you their Hortator."
    },
    {
        id = "B7_TelvanniHort",
        name = "Telvanni Hortator",
        category = "Main Quest | Morrowind",
        subcategory = "Third, Fourth, and Fifth Trial Quests",
        text = "Persuade House Telvanni to name you their Hortator."
    },
    {
        id = "B1_UnifyUrshilaku",
        name = "Urshilaku Nerevarine",
        category = "Main Quest | Morrowind",
        subcategory = "Third, Fourth, and Fifth Trial Quests",
        text = "Talk to Sul-Matuul to be named Urshilaku Nerevarine."
    },
    {
        id = "B2_AhemmusaSafe",
        name = "Ahemmusa Nerevarine",
        category = "Main Quest | Morrowind",
        subcategory = "Third, Fourth, and Fifth Trial Quests",
        text = "Travel to the Ahemmusa camp in order for them to recognize you as the Nerevarine."
    },
    {
        id = "B3_ZainabBride",
        name = "Zainab Nerevarine",
        category = "Main Quest | Morrowind",
        subcategory = "Third, Fourth, and Fifth Trial Quests",
        text = "Travel to the Zainab camp in order for them to recognize you as the Nerevarine."
    },
    {
        id = "B4_KillWarLovers",
        name = "Erabenimsun Nerevarine",
        category = "Main Quest | Morrowind",
        subcategory = "Third, Fourth, and Fifth Trial Quests",
        text = "Travel to the Erabenimsun camp in order for them to recognize you as the Nerevarine."
    },
    {
        id = "B8_MeetVivec - B8_Failed_Nerevarine",
        name = "Hortator and Nerevarine",
        category = "Main Quest | Morrowind",
        subcategory = "Endgame Quests",
        text = "Make the arrangements to meet the god Vivec and receive the plan to defeat Dagoth Ur."
    },
    {
        id = "CX_BackPath",
        name = "Yagrum Bagarn and Wraithguard",
        category = "Main Quest | Morrowind",
        subcategory = "Optional Quests",
        text = "Complete the Main Quest without divine aid."
    },
    {
        id = "C3_DestroyDagoth",
        name = "The Citadels of the Sixth House",
        category = "Main Quest | Morrowind",
        subcategory = "Endgame Quests",
        text = "Find the Ash Vampires to collect powerful artifacts and make your assault on Dagoth Ur himself."
    },

    -- =========================================================================
    -- MISCELLANEOUS
    -- =========================================================================
    {
        id = "A1_SleeperDreamer02",
        name = "Strange Man at Gindrala Hleran's House",
        category = "Miscellaneous",
        subcategory = "Ald'ruhn",
        text = "Kill the trespassing Dreamer in Gindrala Hleran's house."
    },
    {
        id = "A2_1_Kurapli_Zallay",
        name = "Kurapli Seeks Justice",
        category = "Miscellaneous",
        subcategory = "Urshilaku Camp",
        text = "Take vengeance for the death of Kurapli's husband by killing the outcast Zallay Subaddamael."
    },
    {
        id = "MS_WhiteGuar",
        name = "Dreams of a White Guar",
        category = "Miscellaneous",
        subcategory = "Ahemmusa Camp",
        text = "Help Urshamusa Rapli find the white guar she has been dreaming about."
    },
    {
        id = "MV_OutcastAshlanders",
        name = "Girith's Stolen Hides",
        category = "Miscellaneous",
        subcategory = "Ahemmusa Camp",
        text = "Find the thieves who robbed Athanden Girith of some guar hides."
    },
    {
        id = "MV_InnocentAshlanders",
        name = "Marsus Tullius' Missing Hides",
        category = "Miscellaneous",
        subcategory = "Erabenimsun Camp",
        text = "Recover some guar hides stolen by two Ashlanders."
    },
    {
        id = "MV_RichTrader",
        name = "A Man and His Guar",
        category = "Miscellaneous",
        subcategory = "Ascadian Isles",
        text = "Escort this trader and his beast of burden to Vivec."
    },
    {
        id = "MV_TraderMissed",
        name = "An Escort to Molag Mar",
        category = "Miscellaneous",
        subcategory = "Ascadian Isles",
        text = "Help this lost trader reunite with his business partner."
    },
    {
        id = "MV_3_Charming",
        name = "Nels Llendo",
        category = "Miscellaneous",
        subcategory = "Ascadian Isles",
        text = "Give this handsome bandit some gold, a kiss, or a shallow grave."
    },
    {
        id = "MV_AngryTrader",
        name = "The Angry Trader",
        category = "Miscellaneous",
        subcategory = "Ascadian Isles",
        text = "Help Tinos Drothan retrieve some raw glass stolen by his two \"escorts\"."
    },
    {
        id = "MV_VictimRomance",
        name = "The Beauty and the Bandit",
        category = "Miscellaneous",
        subcategory = "Ascadian Isles",
        text = "Help a woman find love."
    },
    {
        id = "MV_StrayedPilgrim",
        name = "The Scholars and the Mating Kagouti",
        category = "Miscellaneous",
        subcategory = "Ascadian Isles",
        text = "Help protect a naturalist who got a little too curious for his own good."
    },
    {
        id = "MV_WanderingPilgrim",
        name = "To the Fields of Kummu",
        category = "Miscellaneous",
        subcategory = "Ascadian Isles",
        text = "Escort this lost pilgrim to the Fields of Kummu shrine."
    },
    {
        id = "MV_FakeSlave",
        name = "Tul's Escape",
        category = "Miscellaneous",
        subcategory = "Ascadian Isles",
        text = "Help an \"escaped slave\" find \"safe haven\"."
    },
    {
        id = "MS_VassirDidanat",
        name = "Vassir-Didanat Ebony Mine",
        category = "Miscellaneous",
        subcategory = "Vassir-Didanat Cave",
        text = "Rediscover the lost Vassir-Didanat Ebony Mine, and report it to one of three Hlaalu Councilors."
    },
    {
        id = "MV_MissingCompanion",
        name = "Divided by Nix Hounds",
        category = "Miscellaneous",
        subcategory = "Ashlands",
        text = "Reunite this couple after an attack by wild beasts."
    },
    {
        id = "MV_PoorPilgrim",
        name = "Lead the Pilgrim to Koal Cave",
        category = "Miscellaneous",
        subcategory = "Ashlands",
        text = "Escort this poor shrine seeker to his destination."
    },
    {
        id = "MV_RichPilgrim",
        name = "Viatrix, The Annoying Pilgrim",
        category = "Miscellaneous",
        subcategory = "Ashlands",
        text = "Escort this ungrateful snob to a shrine inside the Ghostfence."
    },
    {
        id = "MS_ArenimTomb",
        name = "Search for Her Father's Amulet",
        category = "Miscellaneous",
        subcategory = "Arenim Ancestral Tomb",
        text = "Aid Satyana to find her father's amulet in the Arenim Ancestral Tomb."
    },
    {
        id = "MV_RecoverWidowmaker",
        name = "Widowmaker",
        category = "Miscellaneous",
        subcategory = "Grazelands",
        text = "Help a half-naked barbarian retrieve his prize axe from a witch."
    },
    {
        id = "MV_RunawaySlave",
        name = "The Runaway Slave",
        category = "Miscellaneous",
        subcategory = "Molag Amur",
        text = "Escort Reeh-Jah to the safety of the Argonian Mission in Ebonheart."
    },
    {
        id = "MS_Umbra",
        name = "Umbra",
        category = "Miscellaneous",
        subcategory = "Suran",
        text = "Help this depressed Orc warrior in achieving his final request."
    },
    {
        id = "MV_BanditVictim",
        name = "Aeta Wave-Breaker's Jewels",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Retrieve two family heirlooms stolen by a Khajiit and his band of thieves."
    },
    {
        id = "MV_Bugrol",
        name = "Favors for Orcs",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Help deliver some notes in exchange for a \"useless\" rock."
    },
    {
        id = "MV_CultistVictim",
        name = "Kidnapped by Cultists",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Save a poor Redguard woman from uncertain fate and reunite her with her husband."
    },
    {
        id = "MV_TraderAbandoned",
        name = "Pemenie and the Boots of Blinding Speed",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Escort this shady trader to Gnaar Mok in exchange for her flawed, but still very useful boots."
    },
    {
        id = "MV_AbusedHealer",
        name = "Recovering Cloudcleaver",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Help mediate a dispute between a naked Barbarian and a witch who tried to teach him a lesson."
    },
    {
        id = "MV_SkoomaCorpse",
        name = "The Corpse and the Skooma Pipe",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Discover the body of Ernil Omoran north of Balmora."
    },
    {
        id = "MV_LostRing",
        name = "The Lady's Ring",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Find this \"poor\" girl's ring which fell into the pond."
    },
    {
        id = "MV_MonsterDisease",
        name = "The Man Who Spoke to Slaughterfish",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Escort this delirious Legionary to the Gnisis temple for healing."
    },
    {
        id = "MV_ParalyzedBarbarian",
        name = "The Paralyzed Barbarian",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Rescue this naked Barbarian from his cruel punishment at the hands of a mysterious witch."
    },
    {
        id = "MS_HatandSkirt",
        name = "The Sad Sorcerer",
        category = "Miscellaneous",
        subcategory = "Palansour",
        text = "Find out what happened in this cave."
    },
    {
        id = "MV_TraderLate",
        name = "The Shirt of His Back",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Take a vow to deliver these shirts to Ald'ruhn."
    },
    {
        id = "MV_ThiefTrader",
        name = "The Weapon Delivery",
        category = "Miscellaneous",
        subcategory = "West Gash",
        text = "Bring a delivery of weapons to Ald'ruhn for this lost trader."
    },
    {
        id = "MS_Trerayna_bounty",
        name = "A Bounty for Trerayna Dalen",
        category = "Miscellaneous",
        subcategory = "Tel Branora",
        text = "Aid Councilor Therana by killing Trerayna Dalen and her gang outside."
    },
    {
        id = "EB_Deed",
        name = "A Friend in Deed",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Help a businessman in Vivec squash some local competition."
    },
    {
        id = "MS_Apologies",
        name = "A Rash of Insults",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Cure Tarer Braryn who was cursed by Arch-Mage Trebonius Artorius."
    },
    {
        id = "Romance_Ahnassi",
        name = "Ahnassi, a Special Friend",
        category = "Miscellaneous",
        subcategory = "Pelagiad",
        text = "A great romance awaits for those male characters brave enough to try."
    },
    {
        id = "EB_False",
        name = "An Apothecary Slandered",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Investigate the source of some inflammatory leaflets about Aurane Frernis."
    },
    {
        id = "EB_Invisible",
        name = "An Invisible Son",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Help a mostly invisible man become more visible."
    },
    {
        id = "MV_DeadTaxman",
        name = "Death of a Taxman",
        category = "Miscellaneous",
        subcategory = "Seyda Neen",
        text = "Investigate the murder of a tax collector in Seyda Neen."
    },
    {
        id = "EB_Express",
        name = "Dredil's Delivery",
        category = "Miscellaneous",
        subcategory = "Ebonheart",
        text = "A simple note delivery to the East Empire Company in town."
    },
    {
        id = "MS_Lookout",
        name = "Fargoth's Hiding Place",
        category = "Miscellaneous",
        subcategory = "Seyda Neen",
        text = "Find out where Fargoth is hiding his money."
    },
    {
        id = "MS_FargothRing",
        name = "Fargoth's Ring",
        category = "Miscellaneous",
        subcategory = "Seyda Neen",
        text = "Return a missing ring and win favor with the owner and his friends."
    },
    {
        id = "MV_Bastard",
        name = "Fjol the Outlaw",
        category = "Miscellaneous",
        subcategory = "Moonmoth Legion Fort",
        text = "Investigate the reports of an outlaw near town for Larrius Varro at Moonmoth Legion Fort."
    },
    {
        id = "EB_Unrequited",
        name = "For the Love of a Bosmer",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Find and investigate the source of a love letter from Gadayn Andarys to Eraldil."
    },
    {
        id = "MS_JobashaAbolitionist",
        name = "Free the Slaves",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Receive a reward for freeing some slaves."
    },
    {
        id = "town_Sadrith",
        name = "Gateway Ghost",
        category = "Miscellaneous",
        subcategory = "Sadrith Mora",
        text = "Solve the case of this haunted inn in Sadrith Mora."
    },
    {
        id = "MS_Hannat",
        name = "Hannat Zainsubani",
        category = "Miscellaneous",
        subcategory = "Ald'ruhn",
        text = "Rescue this explorer from the Sixth House base of Mamaea."
    },
    {
        id = "MS_HentusPants",
        name = "Hentus Needs Pants",
        category = "Miscellaneous",
        subcategory = "Gnisis",
        text = "Retrieve some stolen pants so Hentus Yansurnummu can get out of the water without embarrassment"
    },
    {
        id = "Town_Ald_Bevene - Town_Ald_Bivale - Town_Ald_Daynes - Town_Ald_Llethri - Town_Ald_Tiras",
        name = "Ienas Sarandas",
        category = "Miscellaneous",
        subcategory = "Ald'ruhn",
        text = "Help local merchants collect on overdue purchases."
    },
    {
        id = "town_balmora",
        name = "Larrius Varro Tells a Little Story",
        category = "Miscellaneous",
        subcategory = "Moonmoth Legion Fort",
        text = "Perform a \"little favor\" for Larrius Varro in Moonmoth Legion Fort."
    },
    {
        id = "EB_Shipment",
        name = "Liberate the Limeware",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Steal a shipment of limeware from a ship at the docks."
    },
    {
        id = "town_Vivec",
        name = "Mysterious Killings in Vivec",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Solve the mystery of seven recent murders in Vivec."
    },
    {
        id = "MV_SlaveMule",
        name = "Rabinna's Inner Beauty",
        category = "Miscellaneous",
        subcategory = "Hla Oad",
        text = "Deliver a slave from Relam Arinith in Hla Oad."
    },
    {
        id = "MS_Gold_kanet_flower",
        name = "Roland's Tear",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Find five of these rare flowers for the alchemist Aurane Frernis."
    },
    {
        id = "EB_Actor",
        name = "The Bad Actor",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Get rid of an annoying fool looking for a troupe."
    },
    {
        id = "EB_Clients",
        name = "The Client List",
        category = "Miscellaneous",
        subcategory = "Ebonheart",
        text = "Steal a list from the enchanter Audenian Valius in Vivec."
    },
    {
        id = "MV_BountyHunter",
        name = "The Drunken Bounty Hunter",
        category = "Miscellaneous",
        subcategory = "Suran",
        text = "Help a drunk bounty hunter in Suran track down an escaped Argonian slave."
    },
    {
        id = "EB_Bone",
        name = "The Dwemer's Bone",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Help Balen Andrano's failing business by sabotaging his competitor, Jeanne."
    },
    {
        id = "EB_Pest",
        name = "The Enchanter's Rats",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Find the cause of a rat infestation for a Telvanni enchanter."
    },
    {
        id = "EB_TradeSpy",
        name = "The Price List",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Find out how the East Empire Company sets its prices."
    },
    {
        id = "EB_DeadMen",
        name = "The Short Unhappy Life of Danar Uvelas",
        category = "Miscellaneous",
        subcategory = "Vivec",
        text = "Find a missing husband for a lady in the Brewers Hall."
    },
    {
        id = "MS_Piernette",
        name = "The Silver Bowl",
        category = "Miscellaneous",
        subcategory = "Ulummusa",
        text = "Return this silver bowl found in a smugglers' cave to its rightful owner."
    },
    {
        id = "town_Tel_Vos",
        name = "Trade Mission to the Zainab",
        category = "Miscellaneous",
        subcategory = "Tel Vos",
        text = "Help Turedus Talanian in Tel Vos learn some information about the Zainab Ashlanders."
    },
    {
        id = "MS_Nuccius",
        name = "Vodunius Nuccius",
        category = "Miscellaneous",
        subcategory = "Seyda Neen",
        text = "Help a fellow who's down on his luck raise the funds to get home."
    },

    -- =========================================================================
    -- IMPERIAL CULT
    -- =========================================================================
    {
        id = "IC30_Imperial_veteran",
        name = "A Lucky Coin",
        category = "Factions | Imperial Cult",
        subcategory = "Special Quests",
        text = "A strange and very rare meeting at the Ghostgate."
    },
    {
        id = "IC1_marshmerrow ",
        name = "Gathering Marshmerrow",
        category = "Factions | Imperial Cult",
        subcategory = "Synnolian Tunifus' Quests, Imperial Chapels, Ebonheart",
        text = "Retrieve five pieces of this ingredient from a Pelagiad farmer."
    },
    {
        id = "IC2_Muck ",
        name = "Gathering Muck",
        category = "Factions | Imperial Cult",
        subcategory = "Synnolian Tunifus' Quests, Imperial Chapels, Ebonheart",
        text = "Find five pieces of muck and deliver some potions to Gnisis."
    },
    {
        id = "IC3_willow ",
        name = "Gathering Willow Anther",
        category = "Factions | Imperial Cult",
        subcategory = "Synnolian Tunifus' Quests, Imperial Chapels, Ebonheart",
        text = "Steal five pieces of willow anther from Gro-Bagrat Plantation, north of Vivec."
    },
    {
        id = "IC4_scrib ",
        name = "Gathering Scrib Jelly",
        category = "Factions | Imperial Cult",
        subcategory = "Synnolian Tunifus' Quests, Imperial Chapels, Ebonheart",
        text = "Visit an egg mine to harvest the jelly from some unlucky scribs."
    },
    {
        id = "IC5_corkbulb ",
        name = "Gathering Corkbulb Root",
        category = "Factions | Imperial Cult",
        subcategory = "Synnolian Tunifus' Quests, Imperial Chapels, Ebonheart",
        text = "Harvest this root at the Arvel Plantation, north of Vivec."
    },
    {
        id = "IC6_Rat ",
        name = "Gathering Rat Meat",
        category = "Factions | Imperial Cult",
        subcategory = "Synnolian Tunifus' Quests, Imperial Chapels, Ebonheart",
        text = "Kill some Rats in Vivec to get some meat for Cure Poison potions."
    },
    {
        id = "IC7_netch ",
        name = "Gathering Netch Leather",
        category = "Factions | Imperial Cult",
        subcategory = "Synnolian Tunifus' Quests, Imperial Chapels, Ebonheart",
        text = "Kill a netch for its leather to make Cure Paralysis potions."
    },
    {
        id = "IC_8_Nord_alms ",
        name = "Alms from the Skyrim Mission",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Visit the Skyrim Mission in Ebonheart and collect donations for the Cult."
    },
    {
        id = "IC9_Argonian_alms ",
        name = "Alms from the Argonian Mission",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Visit the Argonian Mission in Ebonheart and collect donations for the Cult."
    },
    {
        id = "IC10_buckmoth_alms ",
        name = "Buckmoth Alms",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Visit the citizens of Ald'ruhn and collect donations for the Cult."
    },
    {
        id = "IC11_shirt ",
        name = "Shirt and Vest for Harvest's End",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Collect a red shirt and black vest for the Harvest's End festival."
    },
    {
        id = "IC12_dinner ",
        name = "Brandy for the Fundraising Dinner",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Find and persuade some tavern owners to donate this expensive brandy."
    },
    {
        id = "IC13_rich ",
        name = "Donation from Cunius Pelelius",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Collect a 500 gold pledge from the owner of the Caldera Mine."
    },
    {
        id = "IC14_Ponius ",
        name = "Pledge from Canctunian Ponius",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Collect a 1000 gold pledge from the East Empire Company in Ebonheart."
    },
    {
        id = "IC15_Missing_Limeware ",
        name = "Missing Limeware",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Recover a limeware bowl stolen from the chapel by a High Elf named Caryarel."
    },
    {
        id = "IC16_Haunting ",
        name = "The Haunting",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Stop the haunting of Nedhelas' house in Caldera."
    },
    {
        id = "IC17_Witch ",
        name = "Thelsa Dral the Witch",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Dispose of the witch Dral hiding in an egg mine near Khuul."
    },
    {
        id = "IC18_Silver_Staff ",
        name = "The Silver Staff of Shaming",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Find this staff, last held by Linus Iulus, in the shadow of Mount Kand."
    },
    {
        id = "IC19_Restless_Spirit ",
        name = "Restless Spirit",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Calm the restless spirit of murdered Julielle Aumine who is haunting Okur in Hla Oad."
    },
    {
        id = "IC25_JonHawker ",
        name = "Ring in Darkness",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Find this legendary ring in the caverns of Nammu."
    },
    {
        id = "IC26_AmaNin ",
        name = "Boots of the Apostle",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Find these legendary boots in the stronghold of Berandas, south of Gnisis."
    },
    {
        id = "IC27_Oracle ",
        name = "Ice Blade of the Monarch",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Find this powerful blade in the stronghold of Rotheran."
    },
    {
        id = "IC28_Urjorad",
        name = "The Scroll of Fiercely Roasting",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Find this artifact in the shrine of Ashalmimilkala, on the west coast."
    },
    {
        id = "IC29_Crusher",
        name = "Skull-Crusher",
        category = "Factions | Imperial Cult",
        subcategory = "Iulus Truptor's Quests, Imperial Chapels, Ebonheart",
        text = "Find this powerful warhammer within the Forgotten Vaults of Anudnabia, east of Sadrith Mora."
    },

    -- =========================================================================
    -- HOUSE HLAALU
    -- =========================================================================
    {
        id = "HH_Stronghold",
        name = "Stronghold",
        category = "Great Houses | House Hlaalu",
        subcategory = "General Quests",
        text = "Build your House stronghold, Rethan Manor, in three phases."
    },
    {
        id = "HH_DisguisedArmor",
        name = "Disguise",
        category = "Great Houses | House Hlaalu",
        subcategory = "Nileno Dorvayn's Quests, Balmora",
        text = "Steal orders from Neminda in the disguise of a dead Redoran."
    },
    {
        id = "HH_IndEsp1",
        name = "Alchemical Formulas",
        category = "Great Houses | House Hlaalu",
        subcategory = "Nileno Dorvayn's Quests, Balmora",
        text = "A rival alchemist is spoiling business for a loyal Hlaalu alchemist."
    },
    {
        id = "HH_EggMine",
        name = "Inanius Egg Mine",
        category = "Great Houses | House Hlaalu",
        subcategory = "Nileno Dorvayn's Quests, Balmora",
        text = "Kill a queen in the Inanius Egg Mine near Suran."
    },
    {
        id = "HH_IndEsp2",
        name = "Guar Hide Squeeze",
        category = "Great Houses | House Hlaalu",
        subcategory = "Nileno Dorvayn's Quests, Balmora",
        text = "Convince a guar hide salesman in Vivec to buy Hlaalu hides."
    },
    {
        id = "HH_IndEsp3",
        name = "Delivery for Bivale Teneran",
        category = "Great Houses | House Hlaalu",
        subcategory = "Nileno Dorvayn's Quests, Balmora",
        text = "Deliver orders to the clothier Bivale Teneran in Ald'ruhn."
    },
    {
        id = "HH_Retaliation",
        name = "The Death of Ralen Hlaalo",
        category = "Great Houses | House Hlaalu",
        subcategory = "Nileno Dorvayn's Quests, Balmora",
        text = "Solve the murder of Ralen Hlaalo in Balmora."
    },
    {
        id = "HH_IndEsp4",
        name = "Epony Trade",
        category = "Great Houses | House Hlaalu",
        subcategory = "Nileno Dorvayn's Quests, Balmora",
        text = "Convince Canctunian Ponius to buy Ebony from House Hlaalu, or shut down the Sudanit Mine."
    },
    {
        id = "HH_BankCourier",
        name = "Bank Courier",
        category = "Great Houses | House Hlaalu",
        subcategory = "Edryno Arethi's Quests, Vivec",
        text = "Deliver a sealed report to the treasury."
    },
    {
        id = "HH_BuriedTreasure",
        name = "Murudius Flaeus's Debt",
        category = "Great Houses | House Hlaalu",
        subcategory = "Edryno Arethi's Quests, Vivec",
        text = "Retrieve some debt money owed by Flaeus in Hla Oad."
    },
    {
        id = "HH_EscortMerchant",
        name = "Escort Tarvyn Faren",
        category = "Great Houses | House Hlaalu",
        subcategory = "Edryno Arethi's Quests, Vivec",
        text = "Escort a House Hlaalu merchant to Pelagiad."
    },
    {
        id = "HH_Odirniran",
        name = "Telvanni at Odirniran",
        category = "Great Houses | House Hlaalu",
        subcategory = "Edryno Arethi's Quests, Vivec",
        text = "Travel to Odirniran to look for survivors and kill the evil Telvanni there."
    },
    {
        id = "HH_TheExterminator",
        name = "Exterminator",
        category = "Great Houses | House Hlaalu",
        subcategory = "Edryno Arethi's Quests, Vivec",
        text = "Kill some diseased rats among Yngling's game rats in Vivec."
    },
    {
        id = "HH_AshlanderEbony",
        name = "Ashlander Ebony",
        category = "Great Houses | House Hlaalu",
        subcategory = "Edryno Arethi's Quests, Vivec",
        text = "Convince the Zainab Ashlander camp to sell ebony only to House Hlaalu."
    },
    {
        id = "HH_SunkenTreasure",
        name = "The Shipwreck 'Prelude'",
        category = "Great Houses | House Hlaalu",
        subcategory = "Edryno Arethi's Quests, Vivec",
        text = "Find the sunken wreck and recover a Daedric blade."
    },
    {
        id = "HH_GuardMerchant",
        name = "Guard Ralen Tilvur",
        category = "Great Houses | House Hlaalu",
        subcategory = "Edryno Arethi's Quests, Vivec",
        text = "Guard Ralen Tilvur's smithy in Vivec's Foreign Quarter Plaza from thieves."
    },
    {
        id = "HH_Crassius",
        name = "An Admiring Sponsor",
        category = "Great Houses | House Hlaalu",
        subcategory = "Crassius Curio's Quests, Vivec",
        text = "Meet with Crassius Curio in his house in Vivec to be sponsored."
    },
    {
        id = "HH_NordSmugglers",
        name = "Velfred the Outlaw",
        category = "Great Houses | House Hlaalu",
        subcategory = "Crassius Curio's Quests, Vivec",
        text = "Find an outlaw and get him to pay his smuggling fees."
    },
    {
        id = "HH_DestroyIndarysManor",
        name = "Kill Banden Indarys",
        category = "Great Houses | House Hlaalu",
        subcategory = "Crassius Curio's Quests, Vivec",
        text = "Kill this Lord in his manor between Maar Gan and Ald'ruhn."
    },
    {
        id = "HH_BeroSupport",
        name = "Bero's Support",
        category = "Great Houses | House Hlaalu",
        subcategory = "Crassius Curio's Quests, Vivec",
        text = "Get the support of this elusive councilor."
    },
    {
        id = "HH_DestroyTelUvirith",
        name = "Kill Reynel Uvirith",
        category = "Great Houses | House Hlaalu",
        subcategory = "Crassius Curio's Quests, Vivec",
        text = "Kill this Telvanni sorcerer in the stronghold of Tel Uvirith."
    },
    {
        id = "HH_BankFraud",
        name = "Sealed Orders",
        category = "Great Houses | House Hlaalu",
        subcategory = "Odral Helvi's Quests, Caldera",
        text = "Deliver some suspicious orders to the Hlaalu Vault clerk in Vivec."
    },
    {
        id = "HH_CaptureSpy",
        name = "The Caldera Spy",
        category = "Great Houses | House Hlaalu",
        subcategory = "Odral Helvi's Quests, Caldera",
        text = "Find the thief who stole some documents from the Caldera Mine."
    },
    {
        id = "HH_ReplaceDocs",
        name = "Erroneous Documents",
        category = "Great Houses | House Hlaalu",
        subcategory = "Odral Helvi's Quests, Caldera",
        text = "Replace some \"erroneous\" land deeds with fake ones in the Hlaalu Records Office in Vivec."
    },
    {
        id = "HH_RentCollector",
        name = "Rent and Taxes",
        category = "Great Houses | House Hlaalu",
        subcategory = "Odral Helvi's Quests, Caldera",
        text = "Collect some rent and taxes from two farmers, or simply kill them if they refuse."
    },
    {
        id = "HH_EbonyDelivery",
        name = "Shipment of Ebony",
        category = "Great Houses | House Hlaalu",
        subcategory = "Odral Helvi's Quests, Caldera",
        text = "Smuggle some raw ebony to Ald'ruhn."
    },
    {
        id = "HH_LiteracyCampaign",
        name = "Literacy Campaign",
        category = "Great Houses | House Hlaalu",
        subcategory = "Ilmeni Dren's Quests, Vivec",
        text = "Find two books for the school in the Ald'ruhn Mages Guild."
    },
    {
        id = "HH_TwinLamps1",
        name = "The Twin Lamps",
        category = "Great Houses | House Hlaalu",
        subcategory = "Ilmeni Dren's Quests, Vivec",
        text = "Find and rescue an escaped slave."
    },
    {
        id = "HH_TwinLamps3",
        name = "Free Hides-His-Foot",
        category = "Great Houses | House Hlaalu",
        subcategory = "Ilmeni Dren's Quests, Vivec",
        text = "Free an Argonian slave from Dren Plantation."
    },
    {
        id = "HH_WinSaryoni",
        name = "Control the Ordinators",
        category = "Great Houses | House Hlaalu",
        subcategory = "Duke Vedam Dren's Quests, Ebonheart",
        text = "Talk with Archcanon Saryoni on how to control the Ordinators."
    },
    {
        id = "HH_WinCamonna",
        name = "Dealing with Orvas Dren",
        category = "Great Houses | House Hlaalu",
        subcategory = "Duke Vedam Dren's Quests, Ebonheart",
        text = "Convince Orvas Dren to give you control of the Camonna Tong."
    },

    -- =========================================================================
    -- HOUSE REDORAN
    -- =========================================================================
    {
        id = "HR_Stronghold",
        name = "Stronghold",
        category = "Great Houses | House Redoran",
        subcategory = "General Quests",
        text = "Build your House stronghold, Indarys Manor, in three phases."
    },
    {
        id = "HR_MudcrabNest",
        name = "Mudcrab Pests",
        category = "Great Houses | House Redoran",
        subcategory = "Neminda's Quests, Ald'ruhn",
        text = "Take care of some mudcrabs that have been bothering Falen's guar herd."
    },
    {
        id = "HR_Courier",
        name = "Deliver Cure Disease Potion",
        category = "Great Houses | House Redoran",
        subcategory = "Neminda's Quests, Ald'ruhn",
        text = "Deliver a potion to Theldyn Virith in Ald Velothi."
    },
    {
        id = "HR_FindDalobar",
        name = "Find Mathis Dalobar",
        category = "Great Houses | House Redoran",
        subcategory = "Neminda's Quests, Ald'ruhn",
        text = "Find this missing trader around Ald'ruhn."
    },
    {
        id = "HR_FoundersHelm",
        name = "Founder's Helm",
        category = "Great Houses | House Redoran",
        subcategory = "Neminda's Quests, Ald'ruhn",
        text = "Retrieve a helm stolen by Alvis in Balmora."
    },
    {
        id = "HR_GuardGuarHerds",
        name = "Trouble with Bandits",
        category = "Great Houses | House Redoran",
        subcategory = "Neminda's Quests, Ald'ruhn",
        text = "Help Falen again by protecting her and her herd from bandits."
    },
    {
        id = "HR_GuardSarethi",
        name = "Guard Sarethi Manor",
        category = "Great Houses | House Redoran",
        subcategory = "Neminda's Quests, Ald'ruhn",
        text = "Guard Athyn Sarethi from assassins in his Ald'ruhn manor."
    },
    {
        id = "HR_OldBlueFin",
        name = "Old Blue Fin",
        category = "Great Houses | House Redoran",
        subcategory = "Theldyn Virith's Quests, Ald Velothi",
        text = "Kill an old menace that has been bothering people around the docks in Ald Velothi."
    },
    {
        id = "HR_AshimanuMine",
        name = "Ashimanu Mine",
        category = "Great Houses | House Redoran",
        subcategory = "Theldyn Virith's Quests, Ald Velothi",
        text = "Kill an infected shalk in this egg mine."
    },
    {
        id = "HR_Kagouti",
        name = "Kagouti Den",
        category = "Great Houses | House Redoran",
        subcategory = "Theldyn Virith's Quests, Ald Velothi",
        text = "Kill an annoying Kagouti in the vicinity of the Ashimanu Egg Mine."
    },
    {
        id = "HR_ShishiReport",
        name = "Shishi Report",
        category = "Great Houses | House Redoran",
        subcategory = "Theldyn Virith's Quests, Ald Velothi",
        text = "Check on soldiers sent to this House outpost."
    },
    {
        id = "HR_CultElimination",
        name = "Kill Gordol",
        category = "Great Houses | House Redoran",
        subcategory = "Theldyn Virith's Quests, Ald Velothi",
        text = "Kill this Daedra worshipper in the shrine of Ashalmawia."
    },
    {
        id = "HR_RescueSarethi",
        name = "Rescue Varvur Sarethi",
        category = "Great Houses | House Redoran",
        subcategory = "Athyn Sarethi's Quests, Ald'ruhn",
        text = "Rescue Sarethi's son being held in the Venim Manor."
    },
    {
        id = "HR_ClearSarethi",
        name = "Clear Varvur Sarethi's Name",
        category = "Great Houses | House Redoran",
        subcategory = "Athyn Sarethi's Quests, Ald'ruhn",
        text = "Start the investigation into the murder of Sarethi's friend."
    },
    {
        id = "HR_HonorChallenge",
        name = "Ondres Nerano's Slanders",
        category = "Great Houses | House Redoran",
        subcategory = "Athyn Sarethi's Quests, Ald'ruhn",
        text = "Defend your House honor."
    },
    {
        id = "HR_Shurinbaal",
        name = "Shurinbaal",
        category = "Great Houses | House Redoran",
        subcategory = "Athyn Sarethi's Quests, Ald'ruhn",
        text = "Take care of some smugglers in Shurinbaal."
    },
    {
        id = "HR_RansomMandas",
        name = "The Mad Lord of Milk",
        category = "Great Houses | House Redoran",
        subcategory = "Athyn Sarethi's Quests, Ald'ruhn",
        text = "Calm an enraged inhabitant of Milk."
    },
    {
        id = "HR_Archmaster",
        name = "Duel with Bolvyn Venim",
        category = "Great Houses | House Redoran",
        subcategory = "Athyn Sarethi's Quests, Ald'ruhn",
        text = "Challenge Bolvyn Venim to a duel to the death for the title of Archmaster."
    },
    {
        id = "HR_SixthHouseBase",
        name = "Ash Statue",
        category = "Great Houses | House Redoran",
        subcategory = "Lloros Sarano's Quests, Ald'ruhn",
        text = "Continue the investigation to find out how and why Varvur received an ash statue."
    },
    {
        id = "HR_FindTharen",
        name = "Find Fedris Tharen",
        category = "Great Houses | House Redoran",
        subcategory = "Lloros Sarano's Quests, Ald'ruhn",
        text = "Find this pilgrim who disappeared on his way to the Koal Cave shrine."
    },
    {
        id = "HR_FindGiladren",
        name = "Find Beden Giladren",
        category = "Great Houses | House Redoran",
        subcategory = "Lloros Sarano's Quests, Ald'ruhn",
        text = "Find another pilgrim who disappeared on his way to Maar Gan."
    },
    {
        id = "HR_LostBanner",
        name = "Recover Shields from Andasreth",
        category = "Great Houses | House Redoran",
        subcategory = "Lloros Sarano's Quests, Ald'ruhn",
        text = "Find four soldiers who disappeared in the Andasreth Stronghold."
    },
    {
        id = "HR_MorvaynManor",
        name = "Mission to Morvayn Manor",
        category = "Great Houses | House Redoran",
        subcategory = "Redoran Councilor Quests, Ald'ruhn",
        text = "Recover an ash statue from this councilor's house now overrun by Corprus creatures."
    },
    {
        id = "HR_TaxCollector",
        name = "Taxes from Gnisis",
        category = "Great Houses | House Redoran",
        subcategory = "Redoran Councilor Quests, Ald'ruhn",
        text = "Retrieve some taxes from Hetman Abelmawia in Gnisis."
    },
    {
        id = "HR_OldFlame",
        name = "Nalvilie Saren",
        category = "Great Houses | House Redoran",
        subcategory = "Redoran Councilor Quests, Ald'ruhn",
        text = "Find a lost love for Hlaren Ramoran."
    },
    {
        id = "HR_CalderaCorrupt",
        name = "Evidence of Corruption",
        category = "Great Houses | House Redoran",
        subcategory = "Redoran Councilor Quests, Ald'ruhn",
        text = "Recover proof of Hlaalu corruption in the Caldera Mining operation."
    },
    {
        id = "HR_CalderaDisrupt",
        name = "Shut the Mines Down",
        category = "Great Houses | House Redoran",
        subcategory = "Redoran Councilor Quests, Ald'ruhn",
        text = "Shut down the Caldera Mine for Garisa Llethri."
    },
    {
        id = "HR_ArobarKidnap",
        name = "Miner Arobar's Support",
        category = "Great Houses | House Redoran",
        subcategory = "Redoran Councilor Quests, Ald'ruhn",
        text = "Find out what or who has been influencing Councilor Miner Arobar."
    },
    {
        id = "HR_HlaanoSlanders",
        name = "Meril Hlaano's Slanders",
        category = "Great Houses | House Redoran",
        subcategory = "Faral Retheran's Quests, Vivec",
        text = "Convince this Hlaalu noble to stop slandering House Redoran."
    },
    {
        id = "HR_RedasTomb",
        name = "Redas Tomb",
        category = "Great Houses | House Redoran",
        subcategory = "Faral Retheran's Quests, Vivec",
        text = "Retrieve three items from this tomb south of Molag Mar."
    },
    {
        id = "HR_CowardDisgrace",
        name = "Duel of Honor",
        category = "Great Houses | House Redoran",
        subcategory = "Faral Retheran's Quests, Vivec",
        text = "Convince Rothis Nethan to complete a duel that he's chickened out of."
    },
    {
        id = "HR_DagothTanis",
        name = "Slay Dagoth Tanis",
        category = "Great Houses | House Redoran",
        subcategory = "Faral Retheran's Quests, Vivec",
        text = "Kill this Dagoth at the bottom of the Falasmaryon Stronghold."
    },
    {
        id = "HR_AttackUvirith",
        name = "Slay Reynel Uvirith",
        category = "Great Houses | House Redoran",
        subcategory = "Faral Retheran's Quests, Vivec",
        text = "Kill this Telvanni wizard at Tel Uvirith."
    },
    {
        id = "HR_AttackRethan",
        name = "Slay Raynasa Rethan",
        category = "Great Houses | House Redoran",
        subcategory = "Faral Retheran's Quests, Vivec",
        text = "Kill this Hlaalu lord on the Odai Plateau."
    },
    {
        id = "HR_KoalCave",
        name = "Escort to Koal Cave",
        category = "Great Houses | House Redoran",
        subcategory = "Tuveso Beleth's Quests, Ald'ruhn",
        text = "Escort Tuveso's son on his pilgrimage to Koal Cave south of Gnisis."
    },
    {
        id = "HR_BillCollect",
        name = "Armor Repair Debts",
        category = "Great Houses | House Redoran",
        subcategory = "Tuveso Beleth's Quests, Ald'ruhn",
        text = "Try to collect money owed by a Buoyant Armiger Giras Indaram in his stronghold in Molag Mar."
    },

    -- =========================================================================
    -- HOUSE TELVANNI
    -- =========================================================================
    {
        id = "HT_Stronghold",
        name = "Stronghold",
        category = "Great Houses | House Telvanni",
        subcategory = "General Quests",
        text = "Build your House stronghold, Tel Uvirith, in three phases."
    },
    {
        id = "HT_Muck",
        name = "Muck",
        category = "Great Houses | House Telvanni",
        subcategory = "Raven Omayn's Quests, Sadrith Mora",
        text = "Retrieve five pieces of Muck for some potion making."
    },
    {
        id = "HT_BlackJinx",
        name = "Black Jinx",
        category = "Great Houses | House Telvanni",
        subcategory = "Raven Omayn's Quests, Sadrith Mora",
        text = "Find a magical ring somewhere in Sadrith Mora."
    },
    {
        id = "HT_SloadSoap",
        name = "Sload Soap",
        category = "Great Houses | House Telvanni",
        subcategory = "Arara Uvulas' Quests, Sadrith Mora",
        text = "Retrieve five pieces of sload soap for Neloth's research."
    },
    {
        id = "HT_SilverDawn",
        name = "Staff of the Silver Dawn",
        category = "Great Houses | House Telvanni",
        subcategory = "Arara Uvulas' Quests, Sadrith Mora",
        text = "Find this magical staff somewhere in Sadrith Mora."
    },
    {
        id = "HT_TheranaClothes",
        name = "New Clothes",
        category = "Great Houses | House Telvanni",
        subcategory = "Felisa Ulessen's Quests, Sadrith Mora",
        text = "Deliver a skirt to Mistress Therana in Tel Branora."
    },
    {
        id = "HT_SlaveRebellion",
        name = "Slave Rebellion",
        category = "Great Houses | House Telvanni",
        subcategory = "Felisa Ulessen's Quests, Sadrith Mora",
        text = "Put an end to the slave revolt in Abebaal Egg Mine near Tel Branora."
    },
    {
        id = "HT_DwemerLaw, HT_ChroniclesNchuleft, HT_FireAndFaith",
        name = "Dwemer Books",
        category = "Great Houses | House Telvanni",
        subcategory = "Baladas Demnevanni's Quests, Gnisis",
        text = "Find three rare books for Baladas in Gnisis."
    },
    {
        id = "HT_DahrkMezalf",
        name = "Dahrk Mezalf",
        category = "Great Houses | House Telvanni",
        subcategory = "Baladas Demnevanni's Quests, Gnisis",
        text = "Recover an ancient Dwemer ring from the ruins of Bthungthumz."
    },
    {
        id = "HT_SpyBaladas",
        name = "Three Questions for Baladas Demnevanni",
        category = "Great Houses | House Telvanni",
        subcategory = "Mallam Ryon's Quests, Sadrith Mora",
        text = "Question this scholar in Gnisis on three pivotal questions on the Dwemer."
    },
    {
        id = "HT_NchuleftKey",
        name = "Mission to Nchuleft",
        category = "Great Houses | House Telvanni",
        subcategory = "Mallam Ryon's Quests, Sadrith Mora",
        text = "Retrieve plans from these Dwemer ruins far west of Vos."
    },
    {
        id = "HT_FyrMessage",
        name = "Coded Message",
        category = "Great Houses | House Telvanni",
        subcategory = "Galos Mathendis' Quests, Sadrith Mora",
        text = "Deliver a coded message to Divayth Fyr in Tel Fyr."
    },
    {
        id = "HT_CureBlight",
        name = "Cure Blight",
        category = "Great Houses | House Telvanni",
        subcategory = "Galos Mathendis' Quests, Sadrith Mora",
        text = "Deliver three Cure Blight potions to an alchemist in Tel Vos."
    },
    {
        id = "HT_DaedraSkin",
        name = "Daedra Skin",
        category = "Great Houses | House Telvanni",
        subcategory = "Galos Mathendis' Quests, Sadrith Mora",
        text = "Find and deliver a Daedra skin to Master Aryon in Tel Vos."
    },
    {
        id = "HT_AurielBow",
        name = "Auriel's Bow",
        category = "Great Houses | House Telvanni",
        subcategory = "Therana's Quest, Tel Branora",
        text = "Find the bow that smells like ash yams somewhere in Ghostgate."
    },
    {
        id = "HT_FleshAmulet",
        name = "Flesh Made Whole",
        category = "Great Houses | House Telvanni",
        subcategory = "Dratha's Quest, Tel Mora",
        text = "Retrieve this amulet from Tel Naga in Sadrith Mora."
    },
    {
        id = "HT_DrakePride",
        name = "Drake's Pride",
        category = "Great Houses | House Telvanni",
        subcategory = "Neloth's Quest, Tel Naga, Sadrith Mora",
        text = "Find this robe on a poor servant in Tel Aruhn."
    },
    {
        id = "HT_BaladasAlly",
        name = "Baladas Demnevanni",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Convince Baladas in Gnisis to join the Council."
    },
    {
        id = "HT_MineCure",
        name = "Mudan-Mul Egg Mine",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Cure the blighted Kwama queen in this egg mine west of Tel Vos."
    },
    {
        id = "HT_Odirniran",
        name = "Odirniran",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Help Milyn Faram, who is being attacked by House Hlaalu."
    },
    {
        id = "HT_Monopoly",
        name = "Mages Guild Monopoly",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Convince three Redoran Councilors to support a proposal to allow House Telvanni to compete with the Mages Guild."
    },
    {
        id = "HT_Shishi",
        name = "Shishi",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Rescue Faves Andas from House Redoran forces northwest of Maar Gan."
    },
    {
        id = "HT_RecruitEddie",
        name = "Recruit a Mouth",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Recruit a mouth in order to be promoted to Councilor."
    },
    {
        id = "HT_AttackRethan",
        name = "Kill Raynasa Rethan",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Kill this Hlaalu noble in Rethan Manor south of Balmora."
    },
    {
        id = "HT_AttackIndarys",
        name = "Kill Banden Indarys",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Kill a Redoran noble in his manor house."
    },
    {
        id = "HT_Archmagister",
        name = "Archmagister Gothren",
        category = "Great Houses | House Telvanni",
        subcategory = "Aryon's Quests, Tel Vos",
        text = "Get the support of all House Councilors to become the Archmagister."
    },
    {
        id = "HT_EddieRing",
        name = "Ring of Equity",
        category = "Great Houses | House Telvanni",
        subcategory = "Fast Eddie's Quests, Sadrith Mora",
        text = "Help Eddie to retrieve this magical ring from Neloth's treasury."
    },
    {
        id = "HT_EddieAmulet",
        name = "Amulet of Unity",
        category = "Great Houses | House Telvanni",
        subcategory = "Fast Eddie's Quests, Sadrith Mora",
        text = "Help Eddie to retrieve this magical amulet from the mainland."
    },

    -- =========================================================================
    -- FIGHTERS GUILD
    -- =========================================================================
    {
        id = "FG_RatHunt",
        name = "Exterminator",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Exterminate a few cave rats in a local Balmora house."
    },
    {
        id = "FG_Egg_Poachers",
        name = "The Egg Poachers",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Get rid of two poachers in the Shulk Egg Mine."
    },
    {
        id = "FG_Telvanni_agents",
        name = "The Telvanni Agents",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Kill four Telvanni agents responsible for thefts in the Caldera Mine."
    },
    {
        id = "FG_Sottilde",
        name = "The Code Book",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Retrieve a code book held by Sottilde at the South Wall Cornerclub in Balmora."
    },
    {
        id = "FG_DeseleDebt",
        name = "Desele's Debt",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Collect some debt money from Helviane Desele in Suran."
    },
    {
        id = "FG_OrcBounty",
        name = "Gra-Bol's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Fulfill a bounty contract on an Orc living in Balmora."
    },
    {
        id = "FG_AlofsFarm",
        name = "Alof and the Orcs",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Take care of some Orcs at a Daedric ruin for the Duke."
    },
    {
        id = "FG_VerethiGang",
        name = "The Verethi Gang",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Kill the leader of a smuggler ring in Mannammu, southeast of Pelagiad."
    },
    {
        id = "FG_HungerLoose",
        name = "Hunger in the Sarano Tomb",
        category = "Factions | Fighters Guild",
        subcategory = "Eydis Fire-Eye's Quests, Balmora Guild",
        text = "Kill a hunger who has defiled the Sarano Tomb."
    },
    {
        id = "FG_DebtOrc",
        name = "Juicedaw Ring",
        category = "Factions | Fighters Guild",
        subcategory = "Lorbumol gro-Aglakh's Quests, Vivec Guild",
        text = "Get a ring from an Orc in the Hlaalu canton."
    },
    {
        id = "FG_TongueToad",
        name = "Silence Tongue-Toad",
        category = "Factions | Fighters Guild",
        subcategory = "Lorbumol gro-Aglakh's Quests, Vivec Guild",
        text = "Silence an Argonian in Ald'ruhn for a reward."
    },
    {
        id = "FG_KhajiitBounty",
        name = "Dro'Sakhar's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Lorbumol gro-Aglakh's Quests, Vivec Guild",
        text = "Fulfill the bounty on a Khajiit outlaw in Vivec."
    },
    {
        id = "FG_DebtStoine",
        name = "Lirielle's Debt",
        category = "Factions | Fighters Guild",
        subcategory = "Lorbumol gro-Aglakh's Quests, Vivec Guild",
        text = "Retrieve 2000 gold of debt money from Lirielle in Ald'ruhn."
    },
    {
        id = "FG_SilenceTaxgirl",
        name = "Vandacia's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Lorbumol gro-Aglakh's Quests, Vivec Guild",
        text = "Collect the bounty on a tax lady in Seyda Neen."
    },
    {
        id = "FG_SilenceMagistrate",
        name = "Alleius' Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Lorbumol gro-Aglakh's Quests, Vivec Guild",
        text = "Collect another bounty on a judge in Ebonheart."
    },
    {
        id = "FG_Nchurdamz",
        name = "Battle at Nchurdamz",
        category = "Factions | Fighters Guild",
        subcategory = "Hrundi's Quests, Wolverine Hall Guild",
        text = "Aid a warrior in her vendetta against a daedroth in Nchurdamz."
    },
    {
        id = "FG_DissaplaMine",
        name = "The Dissapla Mine",
        category = "Factions | Fighters Guild",
        subcategory = "Hrundi's Quests, Wolverine Hall Guild",
        text = "Rescue a healer from a Nix-Hound infested mine."
    },
    {
        id = "FG_CorprusStalker",
        name = "Berwen's Stalker",
        category = "Factions | Fighters Guild",
        subcategory = "Hrundi's Quests, Wolverine Hall Guild",
        text = "Kill a corprus stalker in a shop in Tel Mora."
    },
    {
        id = "FG_TenimBounty",
        name = "Tenim's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Hrundi's Quests, Wolverine Hall Guild",
        text = "Kill the outlaw Rels Tenim near Vos."
    },
    {
        id = "FG_DuniraiSupply",
        name = "Sujamma to Dunirai",
        category = "Factions | Fighters Guild",
        subcategory = "Hrundi's Quests, Wolverine Hall Guild",
        text = "Deliver a load of sujamma to Nelacar at the Dunirai Caverns."
    },
    {
        id = "FG_Telasero",
        name = "Sondaale",
        category = "Factions | Fighters Guild",
        subcategory = "Hrundi's Quests, Wolverine Hall Guild",
        text = "Rescue researcher Sondaale from Sixth House cultists and escort her through Telasero."
    },
    {
        id = "FG_EngaerBounty",
        name = "Engaer's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Hrundi's Quests, Wolverine Hall Guild",
        text = "Take care of the outlaw Engaer in Tel Naga."
    },
    {
        id = "FG_FindPudai",
        name = "The Pudai Eggmine",
        category = "Factions | Fighters Guild",
        subcategory = "Hrundi's Quests, Wolverine Hall Guild",
        text = "Retrieve the Seven Eggs of Gold from the Pudai Egg Mine in the Sheogorad region."
    },
    {
        id = "FG_Vas",
        name = "The Necromancer of Vas",
        category = "Factions | Fighters Guild",
        subcategory = "Percius Mercius' Quests, Ald'ruhn Guild",
        text = "Clean out a den of Necromancers far north in the Sheogorad Region."
    },
    {
        id = "FG_BeneranBounty",
        name = "Beneran's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Percius Mercius' Quests, Ald'ruhn Guild",
        text = "Collect a bounty on the murderer Nerer Beneran in Sargon."
    },
    {
        id = "FG_SuranBandits",
        name = "Bandits in Suran",
        category = "Factions | Fighters Guild",
        subcategory = "Percius Mercius' Quests, Ald'ruhn Guild",
        text = "Get rid of some bandits in Suran for Avon Oran."
    },
    {
        id = "FG_ElithPalSupply",
        name = "Flin for Elith-Pal",
        category = "Factions | Fighters Guild",
        subcategory = "Percius Mercius' Quests, Ald'ruhn Guild",
        text = "Deliver a load of flin to the Elith-Pal Mine at the base of the Red Mountain."
    },
    {
        id = "FG_KillCronies",
        name = "Remove Sjoring's Supporters",
        category = "Factions | Fighters Guild",
        subcategory = "Percius Mercius' Quests, Ald'ruhn Guild",
        text = "Kill a pair of corrupted Fighters Guild members."
    },
    {
        id = "FG_KillHardHeart",
        name = "Kill Hard-Heart",
        category = "Factions | Fighters Guild",
        subcategory = "Percius Mercius' Quests, Ald'ruhn Guild",
        text = "Kill the Master of the Fighters Guild in Vivec."
    },
    {
        id = "FG_KillBosses",
        name = "Remove the Heads of the Thieves Guild",
        category = "Factions | Fighters Guild",
        subcategory = "Sjoring Hard-Heart's Quests, Vivec Guild",
        text = "Kill the Thieves Guild bosses."
    },
    {
        id = "FG_BigBosses",
        name = "Kill the Master Thief",
        category = "Factions | Fighters Guild",
        subcategory = "Sjoring Hard-Heart's Quests, Vivec Guild",
        text = "Kill the Main Boss of the Thieves Guild, 'Gentleman' Jim Stacey in Vivec."
    },

    -- =========================================================================
    -- MAGES GUILD
    -- =========================================================================
    {
        id = "MG_Advancement",
        name = "A Wizard's Staff",
        category = "Factions | Mages Guild",
        subcategory = "General Quests",
        text = "Procure a Wizard's Staff required for the rank of Wizard."
    },
    {
        id = "MG_Sharn_Necro",
        name = "I'm NOT a Necromancer!",
        category = "Factions | Mages Guild",
        subcategory = "General Quests",
        text = "Discover a practitioner of the forbidden arts within the guild."
    },
    {
        id = "MG_BCShrooms",
        name = "Four Types of Mushrooms",
        category = "Factions | Mages Guild",
        subcategory = "Ajira's Quests, Balmora Guild",
        text = "Help Ajira research four different local mushroom species."
    },
    {
        id = "MG_Sabotage",
        name = "Fake Soul Gem",
        category = "Factions | Mages Guild",
        subcategory = "Ajira's Quests, Balmora Guild",
        text = "You must help Ajira ensure she wins a bet."
    },
    {
        id = "MG_Flowers",
        name = "Four Types of Flowers",
        category = "Factions | Mages Guild",
        subcategory = "Ajira's Quests, Balmora Guild",
        text = "Another mission to find some local flowers for Ajira to study."
    },
    {
        id = "MG_Bowl",
        name = "Ceramic Bowl",
        category = "Factions | Mages Guild",
        subcategory = "Ajira's Quests, Balmora Guild",
        text = "A simple run to the local shop to fetch a ceramic bowl for Ajira."
    },
    {
        id = "MG_StolenReport",
        name = "Stolen Reports",
        category = "Factions | Mages Guild",
        subcategory = "Ajira's Quests, Balmora Guild",
        text = "Find Ajira's stolen reports on mushrooms and flowers."
    },
    {
        id = "MG_StaffMagnus",
        name = "The Staff of Magnus",
        category = "Factions | Mages Guild",
        subcategory = "Ajira's Quests, Balmora Guild",
        text = "Recover a powerful staff from the Assu Cave."
    },
    {
        id = "MG_WarlocksRing",
        name = "Warlock's Ring",
        category = "Factions | Mages Guild",
        subcategory = "Ajira's Quests, Balmora Guild",
        text = "Receive the location of another powerful artifact."
    },
    {
        id = "MG_JoinUs",
        name = "Recruit or Kill Llarar Bereloth",
        category = "Factions | Mages Guild",
        subcategory = "Ranis Athrys' Quests, Balmora Guild",
        text = "Take a recruitment trip to a Telvanni in Sulipund."
    },
    {
        id = "MG_PayDues",
        name = "Manwe's Dues",
        category = "Factions | Mages Guild",
        subcategory = "Ranis Athrys' Quests, Balmora Guild",
        text = "Retrieve guild dues from a Mages Guild member in Punabi."
    },
    {
        id = "MG_StopCompetition",
        name = "Unsanctioned Training",
        category = "Factions | Mages Guild",
        subcategory = "Ranis Athrys' Quests, Balmora Guild",
        text = "Stop an Argonian from offering Restoration training without the Guild's approval."
    },
    {
        id = "MG_EscortScholar2",
        name = "Escort Itermerel",
        category = "Factions | Mages Guild",
        subcategory = "Ranis Athrys' Quests, Balmora Guild",
        text = "Escort the scholar Itermerel to Pelagiad."
    },
    {
        id = "MG_KillNecro2",
        name = "Kill Necromancer Tashpi Ashibael",
        category = "Factions | Mages Guild",
        subcategory = "Ranis Athrys' Quests, Balmora Guild",
        text = "Investigate a possible case of necromancy in Maar Gan."
    },
    {
        id = "MG_SpyCatch",
        name = "Catch a Spy",
        category = "Factions | Mages Guild",
        subcategory = "Ranis Athrys' Quests, Balmora Guild",
        text = "Search for a Telvanni spy who has infiltrated the Guild."
    },
    {
        id = "MG_NchuleftBook",
        name = "Chronicles of Nchuleft",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "Search for the rare Dwemer book Chronicles of Nchuleft."
    },
    {
        id = "MG_Potion",
        name = "A Potion from Skink-in-Tree's-Shade",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "Fetch a potion from the Sadrith Mora Guild hall."
    },
    {
        id = "MG_StealBook",
        name = "Steal Chimarvamidium",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "You are asked to 'borrow' a book from the Vivec Guild hall."
    },
    {
        id = "MG_Apprentice",
        name = "Huleen's Hut",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "Investigate reports of disturbances from Huleen's Hut in Maar Gan."
    },
    {
        id = "MG_ReturnBook",
        name = "Return Chimarvamidium",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "Return the book you 'borrowed' from the Vivec Guild hall."
    },
    {
        id = "MG_Science",
        name = "Dwemer Tube from Arkngthunch-Sturdumz",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "Acquire a rare Dwemer Tube from Arkngthunch-Sturdumz."
    },
    {
        id = "MG_Excavation",
        name = "Nchuleftingth Expedition",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "Check on an expedition to the Dwemer ruin of Nchuleftingth."
    },
    {
        id = "MG_Mzuleft",
        name = "Scarab Plans in Mzuleft",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "Retrieve Dwemer plans from the ruins of Mzuleft."
    },
    {
        id = "MG_Bethamez",
        name = "Bethamez",
        category = "Factions | Mages Guild",
        subcategory = "Edwinna Elbert's Quests, Ald'ruhn Guild",
        text = "Retrieve some ancient Dwemer documents."
    },
    {
        id = "MG_EscortScholar1",
        name = "Escort Tenyeminwe",
        category = "Factions | Mages Guild",
        subcategory = "Skink-in-Tree's-Shade's Quests, Wolverine Hall Guild",
        text = "Escort a scholar to the docks of Sadrith Mora."
    },
    {
        id = "MG_VampVol2",
        name = "Vampires of Vvardenfell, Vol II",
        category = "Factions | Mages Guild",
        subcategory = "Skink-in-Tree's-Shade's Quests, Wolverine Hall Guild",
        text = "Find a rare vampire book, Vampires of Vvardenfell, Volume II."
    },
    {
        id = "MG_WiseWoman",
        name = "Meeting with a Wise Woman",
        category = "Factions | Mages Guild",
        subcategory = "Skink-in-Tree's-Shade's Quests, Wolverine Hall Guild",
        text = "Arrange a meeting with Skink-in-Tree's-Shade and an Ashlander Wise Woman."
    },
    {
        id = "MG_KillNecro1",
        name = "Kill Necromancer Telura Ulver",
        category = "Factions | Mages Guild",
        subcategory = "Skink-in-Tree's-Shade's Quests, Wolverine Hall Guild",
        text = "Take care of a former guild member that has turned to the dark art of Necromancy."
    },
    {
        id = "MG_SoulGem2",
        name = "Soul of an Ash Ghoul",
        category = "Factions | Mages Guild",
        subcategory = "Skink-in-Tree's-Shade's Quests, Wolverine Hall Guild",
        text = "Capture the soul of an Ash Ghoul for Skink to study."
    },
    {
        id = "MG_VampireCure",
        name = "Galur Rithari's Papers",
        category = "Factions | Mages Guild",
        subcategory = "Skink-in-Tree's-Shade's Quests, Wolverine Hall Guild",
        text = "Find a very rare book by Galur Rithari about vampirism cause and cure."
    },
    {
        id = "MG_Dwarves",
        name = "Mystery of the Dwarves",
        category = "Factions | Mages Guild",
        subcategory = "Trebonius Artorius' Quests, Vivec Guild",
        text = "Discover what really happened to the Dwemer."
    },
    {
        id = "MG_KillTelvanni - MG_Telvanni",
        name = "Kill the Telvanni Councilors",
        category = "Factions | Mages Guild",
        subcategory = "Trebonius Artorius' Quests, Vivec Guild",
        text = "A strange request from the Arch-Mage to kill all the Telvanni councilors."
    },
    {
        id = "MG_Guildmaster",
        name = "Arch-Mage",
        category = "Factions | Mages Guild",
        subcategory = "General Quests",
        text = "Your final quest to replace Trebonius as the guildmaster of the Mages Guild."
    },

    -- =========================================================================
    -- THIEVES GUILD
    -- =========================================================================
    {
        id = "TG_Diamonds",
        name = "Diamonds for Habasi",
        category = "Factions | Thieves Guild",
        subcategory = "Sugar-Lips Habasi's Quests, Balmora Guild",
        text = "Obtain a diamond from the local alchemist."
    },
    {
        id = "TG_ManorKey",
        name = "Nerano Manor Key",
        category = "Factions | Thieves Guild",
        subcategory = "Sugar-Lips Habasi's Quests, Balmora Guild",
        text = "Get the key to Nerano Manor."
    },
    {
        id = "TG_OverduePayments",
        name = "Ra'Zhid's Dwemer Artifacts",
        category = "Factions | Thieves Guild",
        subcategory = "Sugar-Lips Habasi's Quests, Balmora Guild",
        text = "Recover some Dwemer artifacts from Ra'Zhid in Hla Oad."
    },
    {
        id = "TG_VintageBrandy",
        name = "The Vintage Brandy",
        category = "Factions | Thieves Guild",
        subcategory = "Sugar-Lips Habasi's Quests, Balmora Guild",
        text = "Steal some fine Brandy from the Hlaalo Manor."
    },
    {
        id = "TG_BrotherBragor",
        name = "Free New-Shoes Bragor",
        category = "Factions | Thieves Guild",
        subcategory = "Sugar-Lips Habasi's Quests, Balmora Guild",
        text = "Free a fellow member of the Guild from prison in Pelagiad."
    },
    {
        id = "TG_BalmoraDefenses",
        name = "Master of Security",
        category = "Factions | Thieves Guild",
        subcategory = "Sugar-Lips Habasi's Quests, Balmora Guild",
        text = "Help Habasi find the security master in town."
    },
    {
        id = "TG_LootAldruhnMG",
        name = "Loot the Mages Guild",
        category = "Factions | Thieves Guild",
        subcategory = "Aengoth the Jeweler's Quests, Ald'ruhn Guild",
        text = "Borrow a tanto from the Ald'ruhn Mages Guild."
    },
    {
        id = "TG_MasterHelm",
        name = "Redoran Master Helm",
        category = "Factions | Thieves Guild",
        subcategory = "Aengoth the Jeweler's Quests, Ald'ruhn Guild",
        text = "Stick it to a Redoran councilor by stealing his master helm."
    },
    {
        id = "TG_BadGandosa",
        name = "Naughty Gandosa",
        category = "Factions | Thieves Guild",
        subcategory = "Aengoth the Jeweler's Quests, Ald'ruhn Guild",
        text = "Steal a naughty little girl's book."
    },
    {
        id = "TG_Withershins",
        name = "Withershins",
        category = "Factions | Thieves Guild",
        subcategory = "Aengoth the Jeweler's Quests, Ald'ruhn Guild",
        text = "Pick up a copy of this rare book."
    },
    {
        id = "TG_AldruhnDefenses",
        name = "Retrieve the Scrap Metal",
        category = "Factions | Thieves Guild",
        subcategory = "Aengoth the Jeweler's Quests, Ald'ruhn Guild",
        text = "Protect the Thieves Guild by making a Spider Centurion."
    },
    {
        id = "TG_DartsJudgement",
        name = "The Darts of Judgement",
        category = "Factions | Thieves Guild",
        subcategory = "Aengoth the Jeweler's Quests, Ald'ruhn Guild",
        text = "Steal four daedric darts from a Redoran Guard."
    },
    {
        id = "TG_CookbookAlchemy",
        name = "Potion Recipe",
        category = "Factions | Thieves Guild",
        subcategory = "Big Helende's Quests, Wolverine Hall Guild",
        text = "Help the local Mages Guild with their alchemy."
    },
    {
        id = "TG_GrandmasterRetort",
        name = "The Grandmaster's Retort",
        category = "Factions | Thieves Guild",
        subcategory = "Big Helende's Quests, Wolverine Hall Guild",
        text = "Steal a rare Retort for some cash."
    },
    {
        id = "TG_SadrithMoraDefenses",
        name = "Wizard For Hire",
        category = "Factions | Thieves Guild",
        subcategory = "Big Helende's Quests, Wolverine Hall Guild",
        text = "Hire a battlemage to protect the guild."
    },
    {
        id = "TG_RedoranCookbook",
        name = "Redoran Cookbook",
        category = "Factions | Thieves Guild",
        subcategory = "Big Helende's Quests, Wolverine Hall Guild",
        text = "Steal the Redoran cooking secrets."
    },
    {
        id = "TG_EbonyStaff",
        name = "Felen's Ebony Staff",
        category = "Factions | Thieves Guild",
        subcategory = "Big Helende's Quests, Wolverine Hall Guild",
        text = "Steal a staff from a mean Telvanni."
    },
    {
        id = "TG_BrotherThief",
        name = "Find Brother Nads",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Quests, Vivec Guild",
        text = "Find a fellow guild member that has disappeared."
    },
    {
        id = "TG_EnemyParley",
        name = "Speak With Percius",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Quests, Vivec Guild",
        text = "Visit Percius in the Ald'ruhn Fighters Guild to learn information on the Camonna Tong."
    },
    {
        id = "TG_BitterBribe",
        name = "The Bitter Cup",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Quests, Vivec Guild",
        text = "Find the Bittercup artifact and persuade Eydis Fire-Eye to betray the Camonna Tong."
    },
    {
        id = "TG_Hostage",
        name = "Hrundi's Lover",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Quests, Vivec Guild",
        text = "Persuade Hrundi in Sadrith Mora's Fighters Guild to join the Thieves Guild against the Camonna Tong."
    },
    {
        id = "TG_KillIenith",
        name = "The Brothers Ienith",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Quests, Vivec Guild",
        text = "Kill these top two enforcers in the Camonna Tong guild."
    },
    {
        id = "TG_KillHardHeart",
        name = "Kill Hard-Heart",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Quests, Vivec Guild",
        text = "Kill the corrupt Master of the Fighters Guild in Vivec."
    },
    {
        id = "TG_SS_Generosity1",
        name = "The Hlervu Locket",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Bal Molagmer Quests, Vivec Guild",
        text = "Steal a locket from a Redoran bigwig, and give it back to its owner."
    },
    {
        id = "TG_SS_Yngling",
        name = "Yngling's Ledger",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Bal Molagmer Quests, Vivec Guild",
        text = "Gentleman Jim Stacey wants you to fight corruption in Vivec."
    },
    {
        id = "TG_SS_Generosity2",
        name = "Land Deed",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Bal Molagmer Quests, Vivec Guild",
        text = "Save a woman's home by robbing the Vivec Library."
    },
    {
        id = "TG_SS_Enamor",
        name = "Enamor",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Bal Molagmer Quests, Vivec Guild",
        text = "Return Enamor to Salyn Sarethi at the Tower of Dusk."
    },
    {
        id = "TG_SS_GreedySlaver",
        name = "Brallion's Ring",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Bal Molagmer Quests, Vivec Guild",
        text = "Give a girl a stolen ring."
    },
    {
        id = "TG_SS_Plutocrats",
        name = "Books for Vala",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Bal Molagmer Quests, Vivec Guild",
        text = "Steal 4 history books from Odral Helvi in Caldera and donate them to Vala Catraso in Ald'ruhn."
    },
    {
        id = "TG_SS_ChurchPolice",
        name = "The Dwemer Goblet",
        category = "Factions | Thieves Guild",
        subcategory = "Gentleman Jim Stacey's Bal Molagmer Quests, Vivec Guild",
        text = "Give a fancy goblet to a poor priest."
    },

    -- =========================================================================
    -- IMPERIAL LEGION
    -- =========================================================================
    {
        id = "IL_WidowLand",
        name = "Widow Vabdas' Deed",
        category = "Factions | Imperial Legion",
        subcategory = "General Darius' Quests, Gnisis",
        text = "Trying to get the deed from this widow in Gnisis is just the start."
    },
    {
        id = "IL_GnisisBlight",
        name = "Gnisis Eggmine",
        category = "Factions | Imperial Legion",
        subcategory = "General Darius' Quests, Gnisis",
        text = "Cure the Queen of the blighted Gnisis Eggmine."
    },
    {
        id = "IL_RescuePilgrim",
        name = "Rescue Madura Seran",
        category = "Factions | Imperial Legion",
        subcategory = "General Darius' Quests, Gnisis",
        text = "Rescue this pilgrim, kidnapped by Ashlander outcasts, north of Gnisis."
    },
    {
        id = "IL_RescueRagash",
        name = "Rescue Ragash gra-Shuzgub",
        category = "Factions | Imperial Legion",
        subcategory = "General Darius' Quests, Gnisis",
        text = "Find out what happened to the town's tax collector."
    },
    {
        id = "IL_TalosTreason",
        name = "Talos Cult Conspiracy",
        category = "Factions | Imperial Legion",
        subcategory = "General Darius' Quests, Gnisis",
        text = "Investigate this cult in Gnisis that may try to move against the Emperor."
    },
    {
        id = "IL_Smuggler",
        name = "Dwemer Artifacts at Drinar Varyon's Place",
        category = "Factions | Imperial Legion",
        subcategory = "Imsin the Dreamer's Quests, Buckmoth Legion Fort",
        text = "Find proof that Drinar Varyon in Ald'ruhn is a smuggler of Dwemer artifacts."
    },
    {
        id = "IL_RescueKnight",
        name = "Rescue Joncis Dalomax",
        category = "Factions | Imperial Legion",
        subcategory = "Imsin the Dreamer's Quests, Buckmoth Legion Fort",
        text = "Rescue this fellow knight being held in Ashurnibibi."
    },
    {
        id = "IL_MaidenToken",
        name = "Maiden's Token",
        category = "Factions | Imperial Legion",
        subcategory = "Imsin the Dreamer's Quests, Buckmoth Legion Fort",
        text = "Recover a maiden's embroidered gauntlet from Varona Nelas in Assumanu."
    },
    {
        id = "IL_ScrapMetal",
        name = "Scrap Metal",
        category = "Factions | Imperial Legion",
        subcategory = "Radd Hard-Heart's Quests, Moonmoth Legion Fort",
        text = "Retrieve some Dwemer scrap metal to complete a contest."
    },
    {
        id = "IL_RescueHermit",
        name = "Rescue Jocien Ancois",
        category = "Factions | Imperial Legion",
        subcategory = "Radd Hard-Heart's Quests, Moonmoth Legion Fort",
        text = "Rescue someone kidnapped from the Erabenimsun Ashlander camp."
    },
    {
        id = "IL_Damsel",
        name = "Rescue Dandsa",
        category = "Factions | Imperial Legion",
        subcategory = "Radd Hard-Heart's Quests, Moonmoth Legion Fort",
        text = "Rescue an Imperial citizen held hostage by raiders."
    },
    {
        id = "IL_GiantNetch",
        name = "Breeding Netch",
        category = "Factions | Imperial Legion",
        subcategory = "Radd Hard-Heart's Quests, Moonmoth Legion Fort",
        text = "Eliminate a pair of dangerous breeding netch."
    },
    {
        id = "IL_Necromancer",
        name = "Sorkvild the Raven",
        category = "Factions | Imperial Legion",
        subcategory = "Radd Hard-Heart's Quests, Moonmoth Legion Fort",
        text = "Kill this necromancer in his tower near Dagon Fel."
    },
    {
        id = "IL_Courtesy",
        name = "Courtesy",
        category = "Factions | Imperial Legion",
        subcategory = "Frald the White's Quests, Ebonheart",
        text = "Defend the Legion's honor from a Buoyant Armiger in Ghostgate."
    },
    {
        id = "IL_TraitorWarrior",
        name = "Honthjolf is a Traitor",
        category = "Factions | Imperial Legion",
        subcategory = "Frald the White's Quests, Ebonheart",
        text = "Kill this deserter of the Legion in the cave of Aharnabi."
    },
    {
        id = "IL_FalseOrdinator",
        name = "Suryn Athones' Slanders",
        category = "Factions | Imperial Legion",
        subcategory = "Frald the White's Quests, Ebonheart",
        text = "Kill an Ordinator in Vivec who is spreading lies about the Legion."
    },
    {
        id = "IL_ProtectEntius",
        name = "Saprius Entius",
        category = "Factions | Imperial Legion",
        subcategory = "Frald the White's Quests, Ebonheart",
        text = "Find and protect this Legion Knight accused of murder."
    },
    {
        id = "IL_KnightShield",
        name = "Lord's Mail",
        category = "Factions | Imperial Legion",
        subcategory = "Varus Vantinius' Quests, Ebonheart",
        text = "Retrieve the Lord's Mail and Chrysamere artifacts to receive a promotion."
    },
    {
        id = "IL_Grandmaster",
        name = "Grandmaster Duel",
        category = "Factions | Imperial Legion",
        subcategory = "Varus Vantinius' Quests, Ebonheart",
        text = "Achieve the highest rank by dueling with Vantinius in the Arena."
    },

    -- =========================================================================
    -- MORAG TONG
    -- =========================================================================
    {
        id = "MT_WritOran",
        name = "Writ for Feruren Oran",
        category = "Factions | Morag Tong",
        subcategory = "Getting Started with the Morag Tong",
        text = "Prove your worth to the Morag Tong by performing the execution of Feruren Oran."
    },
    {
        id = "MT_WritYasalmibaal",
        name = "Writ for Odaishah Yasalmibaal",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Odaishah near Tel Fyr."
    },
    {
        id = "MT_WritSaren",
        name = "Writ for Toris Saren",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Toris in Vivec."
    },
    {
        id = "MT_WritSadus",
        name = "Writ for Sarayn Sadus",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Sadus in Zaintirari."
    },
    {
        id = "MT_WritVendu",
        name = "Writ for Ethal Seloth and Idroso Vendu",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Vendu and Seloth in Temporary Housing in Vivec."
    },
    {
        id = "MT_WritGuril",
        name = "Writ for Guril Retheran",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Guril, found in Vivec."
    },
    {
        id = "MT_WritGalasa",
        name = "Writ for Galasa Uvayn",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Galasa, found in Vivec."
    },
    {
        id = "MT_WritMavon",
        name = "Writ for Mavon Drenim",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Drenim in Vivec."
    },
    {
        id = "MT_WritBelvayn",
        name = "Writ for Tirer Belvayn",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Tirer in the dungeon of Shara."
    },
    {
        id = "MT_WritBemis",
        name = "Writ for Mathyn Bemis",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Mathyn Bemis in Vivec."
    },
    {
        id = "MT_WritBrilnosu",
        name = "Writ for Brilnosu Llarys",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Execute Llarys in the Hlormaren stronghold."
    },
    {
        id = "MT_WritNavil",
        name = "Writ for Navil and Ranes Ienith",
        category = "Factions | Morag Tong",
        subcategory = "Writs Given By Any Quest Giver",
        text = "Kill these two brothers in the basement of the Dren Plantation Villa."
    },
    {
        id = "MT_S_BalancedArmor, MT_S_DeepBiting, MT_S_Denial, MT_S_Fleetness, MT_S_FluidEvasion, MT_S_GlibSpeech, MT_S_Golden, MT_S_Green, MT_S_Hewing, MT_S_HornyFist, MT_S_Impaling, MT_S_Leaping, MT_S_MartialCraft, MT_S_NimbleArmor, MT_S_Red, MT_S_Safekeeping, MT_S_Silver, MT_S_Smiting, MT_S_Stalking, MT_S_StolidArmor, MT_S_Sublime, MT_S_Sureflight, MT_S_Swiftblade, MT_S_Transcendent, MT_S_Transfiguring, MT_S_Unseen",
        name = "Threads of the Webspinner",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Find 26 Sanguine items for Eno Hlaalu to receive a nice reward from Mephala."
    },
    {
        id = "MT_DB_Contact",
        name = "A Contact in the Dark Brotherhood",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Find out the name of a Dark Brotherhood contact from an enchanter in the canton."
    },
    {
        id = "MT_S_Fleetness",
        name = "Belt of Sanguine Fleetness",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Recover this belt in Pelagiad."
    },
    {
        id = "MT_DB_Darys",
        name = "Ultimatum for Movis Darys",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Persuade this Dark Brotherhood member to join the Morag Tong."
    },
    {
        id = "MT_DB_Carecalmo",
        name = "Ultimatum for Carecalmo",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Deliver an ultimatum to Carecalmo, a worshipper of Mehrunes Dagon who is aiding the Dark Brotherhood."
    },
    {
        id = "MT_S_Sublime",
        name = "Ring of Sanguine Sublime Wisdom",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Recover this ring from the shrine of Yasammidan, northwest of Gnisis."
    },
    {
        id = "MT_DB_Assernerairan",
        name = "Execute Durus Marius",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Kill this Dark Brotherhood assassin found in a shrine in the St. Olms Underworks."
    },
    {
        id = "MT_DB_AldSotha",
        name = "Execute Severa Magia",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Execute the Night Mother of the Dark Brotherhood within Ald Sotha."
    },
    {
        id = "MT_Grandmaster",
        name = "Grandmaster",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vivec Guild",
        text = "Eno Hlaalu wants to retire and name you the Grandmaster of the Morag Tong."
    },
    {
        id = "MT_WritVarro",
        name = "Writ for Larrius Varro",
        category = "Factions | Morag Tong",
        subcategory = "Grandmaster Writs",
        text = "Execute Larrius Varro in the Moonmoth Legion Fort."
    },
    {
        id = "MT_WritBaladas",
        name = "Writ for Baladas Demnevanni",
        category = "Factions | Morag Tong",
        subcategory = "Grandmaster Writs",
        text = "Execute this powerful spellcaster in Gnisis."
    },
    {
        id = "MT_WritBero",
        name = "Writ for Dram Bero",
        category = "Factions | Morag Tong",
        subcategory = "Grandmaster Writs",
        text = "Execute this Hlaalu council member in Vivec."
    },
    {
        id = "MT_WritTherana",
        name = "Writ for Mistress Therana",
        category = "Factions | Morag Tong",
        subcategory = "Grandmaster Writs",
        text = "Execute this loony Telvanni council member in Tel Branora."
    },

    -- =========================================================================
    -- TRIBUNAL TEMPLE
    -- =========================================================================
    {
        id = "TT_SevenGraces, TT_PilgrimsPath, TT_FieldsKummu, TT_StopMoon, TT_PalaceVivec, TT_PuzzleCanal, TT_MaskVivec, TT_Ghostgate, TT_RuddyMan",
        name = "Pilgrimages of the Seven Graces",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests",
        text = "Your first task is to visit seven shrines throughout the island."
    },
    {
        id = "TT_Compassion",
        name = "Compassion",
        category = "Factions | Tribunal Temple",
        subcategory = "Tuls Valen's Quests, Ald'ruhn Temple",
        text = "Cure a mortal enemy of Blight to learn of compassion."
    },
    {
        id = "TT_FalseIncarnate",
        name = "False Incarnate",
        category = "Factions | Tribunal Temple",
        subcategory = "Tuls Valen's Quests, Ald'ruhn Temple",
        text = "Investigate the claims of a possible Nerevarine in Suran."
    },
    {
        id = "TT_MaarGan",
        name = "Pilgrimage to Maar Gan",
        category = "Factions | Tribunal Temple",
        subcategory = "Tuls Valen's Quests, Ald'ruhn Temple",
        text = "Perform another pilgrimage to the shrine in Maar Gan."
    },
    {
        id = "TT_Hassour",
        name = "Dark Cult in Hassour",
        category = "Factions | Tribunal Temple",
        subcategory = "Tuls Valen's Quests, Ald'ruhn Temple",
        text = "Destroy a dark Sixth House cult in the cave of Hassour."
    },
    {
        id = "TT_DiseaseCarrier",
        name = "Disease Carrier",
        category = "Factions | Tribunal Temple",
        subcategory = "Endryn Llethan's Quests, Vivec High Fane",
        text = "Convince a pilgrim in Vivec who has Corprus to leave the city."
    },
    {
        id = "TT_SanctusShrine",
        name = "Silent Pilgrimage",
        category = "Factions | Tribunal Temple",
        subcategory = "Endryn Llethan's Quests, Vivec High Fane",
        text = "Take a vow of silence to perform a pilgrimage to the Sanctus Shrine, west of Dagon Fel."
    },
    {
        id = "TT_RilmsShoes",
        name = "Shoes of St. Rilms",
        category = "Factions | Tribunal Temple",
        subcategory = "Endryn Llethan's Quests, Vivec High Fane",
        text = "Recover these precious artifacts of the Temple in the depths of Ald Sotha."
    },
    {
        id = "TT_StAralor",
        name = "Foul Cult Beneath St. Delyn Canton",
        category = "Factions | Tribunal Temple",
        subcategory = "Endryn Llethan's Quests, Vivec High Fane",
        text = "Eliminate this foul cult operating somewhere in St. Delyn canton of Vivec."
    },
    {
        id = "TT_CuringTouch",
        name = "Cure Lette",
        category = "Factions | Tribunal Temple",
        subcategory = "Tharer Rotheloth's Quests, Molag Mar Temple",
        text = "Cure a villager in Tel Mora of swamp fever."
    },
    {
        id = "TT_MountKand",
        name = "Pilgrimage to Mount Kand",
        category = "Factions | Tribunal Temple",
        subcategory = "Tharer Rotheloth's Quests, Molag Mar Temple",
        text = "Demonstrate your wisdom and bravery by visiting the Mount Kand shrine."
    },
    {
        id = "TT_Mawia",
        name = "Necromancer in Mawia",
        category = "Factions | Tribunal Temple",
        subcategory = "Tharer Rotheloth's Quests, Molag Mar Temple",
        text = "Eliminate a necromancer from Mawia."
    },
    {
        id = "TT_GalomDeus",
        name = "Slay Raxle Berne",
        category = "Factions | Tribunal Temple",
        subcategory = "Tharer Rotheloth's Quests, Molag Mar Temple",
        text = "Cleanse out the vampire lair Galom Daeus and kill the elder vampire Raxle Berne."
    },
    {
        id = "TT_MinistryHeathen",
        name = "Cure the Outcast Outlander",
        category = "Factions | Tribunal Temple",
        subcategory = "Uvoo Llaren's Quests, Ghostgate Temple",
        text = "Cure an ill Ashlander in his camp nearby."
    },
    {
        id = "TT_SupplyMonk",
        name = "Food and Drink for the Hermit",
        category = "Factions | Tribunal Temple",
        subcategory = "Uvoo Llaren's Quests, Ghostgate Temple",
        text = "Deliver some food to the hermit Sendus Sathis on Shuran Island."
    },
    {
        id = "TT_HairShirt",
        name = "Hair Shirt of St. Aralor",
        category = "Factions | Tribunal Temple",
        subcategory = "Uvoo Llaren's Quests, Ghostgate Temple",
        text = "Recover this lost relic from Kogoruhn."
    },
    {
        id = "TT_FelmsCleaver",
        name = "Cleaver of St. Felms",
        category = "Factions | Tribunal Temple",
        subcategory = "Uvoo Llaren's Quests, Ghostgate Temple",
        text = "Recover this lost relic from Tureynulal."
    },
    {
        id = "TT_LlothisCrosier",
        name = "Crosier of St. Llothis the Pious",
        category = "Factions | Tribunal Temple",
        subcategory = "Uvoo Llaren's Quests, Ghostgate Temple",
        text = "Recover yet another artifact in the crater of Red Mountain."
    },
    {
        id = "TT_DagonFel",
        name = "Malacath of the House of Troubles",
        category = "Factions | Tribunal Temple",
        subcategory = "Archcanon Tholer Saryoni's Quests, Vivec High Fane",
        text = "Start the Pilgrimages of the Four Corners by visiting the Statue of Malacath."
    },
    {
        id = "TT_AldSotha",
        name = "Mehrunes Dagon of the House of Troubles",
        category = "Factions | Tribunal Temple",
        subcategory = "Archcanon Tholer Saryoni's Quests, Vivec High Fane",
        text = "Renew the pact with Mehrunes Dagon by visiting his shrine."
    },
    {
        id = "TT_BalUr",
        name = "Molag Bal of the House of Troubles",
        category = "Factions | Tribunal Temple",
        subcategory = "Archcanon Tholer Saryoni's Quests, Vivec High Fane",
        text = "Renew the pact with Molag Bal by visiting his shrine."
    },
    {
        id = "TT_AldDaedroth",
        name = "Sheogorath of the House of Troubles",
        category = "Factions | Tribunal Temple",
        subcategory = "Archcanon Tholer Saryoni's Quests, Vivec High Fane",
        text = "Visit the Statue of Sheogorath to finish the Pilgrimages of the Four Corners."
    },
    {
        id = "TT_Assarnibibi",
        name = "Ebony Mail",
        category = "Factions | Tribunal Temple",
        subcategory = "Archcanon Tholer Saryoni's Quests, Vivec High Fane",
        text = "Retrieve this artifact from the shrine at the top of Mount Assarnibibi."
    },

    -- =========================================================================
    -- DAEDRIC QUESTS
    -- =========================================================================
    {
        id = "DA_Azura",
        name = "Azura's Quest",
        category = "Daedric Quests",
        subcategory = "Shrine of Azura",
        text = "Settle a bet between Azura and Sheogorath."
    },
    {
        id = "DA_Boethiah",
        name = "Boethiah's Quest",
        category = "Daedric Quests",
        subcategory = "Shrine of Boethiah",
        text = "Restore the glory of this forgotten Daedra Lord."
    },
    {
        id = "DA_Malacath",
        name = "Malacath's Quest",
        category = "Daedric Quests",
        subcategory = "Assurdirapal",
        text = "End the bloodline of a false hero."
    },
    {
        id = "DA_Mehrunes",
        name = "Mehrunes Dagon's Quest",
        category = "Daedric Quests",
        subcategory = "Yasammidan",
        text = "Retrieve a lost blade."
    },
    {
        id = "DA_Mephala",
        name = "Mephala's Quest",
        category = "Daedric Quests",
        subcategory = "Vivec Arena, Hidden Area",
        text = "Take care of this \"free agent\" for the Morag Tong."
    },
    {
        id = "DA_MolagBal",
        name = "Molag Bal's Quest",
        category = "Daedric Quests",
        subcategory = "Yansirramus",
        text = "Help deal with a lazy minion."
    },
    {
        id = "DA_Sheogorath",
        name = "Sheogorath's Quest",
        category = "Daedric Quests",
        subcategory = "Vivec St. Delyn, Ihinipalit",
        text = "Stick a fork in a Bull Netch to make sure it's done."
    },

    -- =========================================================================
    -- VAMPIRE QUESTS
    -- =========================================================================
    {
        id = "MS_VampireCure",
        name = "A Cure for Vampirism",
        category = "Vampire Quests",
        subcategory = "General Quests",
        text = "Find the elusive cure to the dreaded disease."
    },
    {
        id = "VA_VampRich",
        name = "The Boy Who Would Be Undead",
        category = "Vampire Quests",
        subcategory = "General Quests",
        text = "Convince a young man in Ald'ruhn that Vampirism isn't all it's cracked up to be."
    },
    {
        id = "VA_VampMarara",
        name = "The Weary Vampire",
        category = "Vampire Quests",
        subcategory = "General Quests",
        text = "Investigate the numerous deaths at the hand of a vampire near Tel Mora."
    },
    {
        id = "VA_VampCurse",
        name = "The Imprisonment of Mastrius",
        category = "Vampire Quests",
        subcategory = "General Quests",
        text = "Aid this vampire imprisoned in the Salvel Ancestral Tomb by Azura."
    },
    {
        id = "VA_Shashev",
        name = "Shashev's Key",
        category = "Vampire Quests",
        subcategory = "General Quests",
        text = "Kill this rival mage for Sirilonwe in Vivec."
    },
    {
        id = "VA_VampDust",
        name = "Dust of the Vampire",
        category = "Vampire Quests",
        subcategory = "General Quests",
        text = "Find three portions of vampire dust for Sirilonwe in Vivec."
    },
    {
        id = "VA_Rimintil",
        name = "Murder Rimintil",
        category = "Vampire Quests",
        subcategory = "General Quests",
        text = "Kill a troublesome Altmer for Mouth Raven Omayn in Sadrith Mora."
    },
    {
        id = "VA_VampBlood2",
        name = "Blood for Mistress Dratha",
        category = "Vampire Quests",
        subcategory = "General Quests",
        text = "Steal a potion of Quarra blood for Mouth Raven Omayn in Sadrith Mora."
    },
    {
        id = "VA_VampChild",
        name = "Blood Ties",
        category = "Vampire Quests",
        subcategory = "Clan Aundae's Quests",
        text = "Find out what happened to the Ancient's son after she became a vampire."
    },
    {
        id = "VA_VampHunter",
        name = "The Vampire Hunter",
        category = "Vampire Quests",
        subcategory = "Clan Aundae's Quests",
        text = "Kill a vampire hunter from Ald'ruhn who has been seen near the headquarters."
    },
    {
        id = "VA_VampBlood",
        name = "The Blood of the Quarra",
        category = "Vampire Quests",
        subcategory = "Clan Berne's Quests",
        text = "Retrieve a potion of Quarra blood from their headquarters."
    },
    {
        id = "VA_VampCountess",
        name = "The Vampire Merta",
        category = "Vampire Quests",
        subcategory = "Clan Berne's Quests",
        text = "Kill this former member of the clan in the Reloth Ancestral Tomb."
    },
    {
        id = "VA_VampCult",
        name = "The Cult of Lord Irarak",
        category = "Vampire Quests",
        subcategory = "Clan Quarra's Quests",
        text = "Kill this vampire in the Ginith Ancestral Tomb who thinks himself a god."
    },
    {
        id = "VA_VampAmulet",
        name = "The Quarra Amulet",
        category = "Vampire Quests",
        subcategory = "Clan Quarra's Quests",
        text = "Retrieve a number of ingredients for amulet making."
    },

    -- #########################################################################
    -- GAME: PLUGIN
    -- #########################################################################

    -- =========================================================================
    -- MISCELLANEOUS
    -- =========================================================================
    {
        id = "EBQ_Artifact",
        name = "Helm of Tohan",
        category = "Miscellaneous",
        subcategory = "Dagon Fel",
        text = "Help two brothers avenge their father's death."
    },
    {
        id = "MS_Master_Index",
        name = "Master Index",
        category = "Miscellaneous",
        subcategory = "Caldera",
        text = "Collect each of the ten Propylon Indices."
    },
    {
        id = "ms_firemoth",
        name = "Siege at Firemoth",
        category = "Miscellaneous",
        subcategory = "Seyda Neen",
        text = "Battle an army of skeletons to recover an ancient shield."
    },

    -- #########################################################################
    -- GAME: TRIBUNAL
    -- #########################################################################

    -- =========================================================================
    -- MAIN QUEST
    -- =========================================================================
    {
        id = "TR_DBAttack",
        name = "Dark Brotherhood Attacks",
        category = "Main Quest | Tribunal",
        subcategory = "Starting Out",
        text = "Stop masked Assassins from attacking you in your sleep, and find out who they are."
    },
    {
        id = "TR_DBHunt",
        name = "Hunt the Dark Brotherhood",
        category = "Main Quest | Tribunal",
        subcategory = "Starting Out",
        text = "Follow the trail of clues leading to the Dark Brotherhood in the sewers and ruins beneath Mournhold"
    },
    {
        id = "TR05_People",
        name = "Speak to the People",
        category = "Main Quest | Tribunal",
        subcategory = "Royal Palace Quests (Optional)",
        text = "Learn of the local rumors surrounding the recent death of the previous king."
    },
    {
        id = "TR06_Temple",
        name = "A Temple Informant",
        category = "Main Quest | Tribunal",
        subcategory = "Royal Palace Quests (Optional)",
        text = "Speak to people in the Temple to find out their true feelings about King Helseth."
    },
    {
        id = "TR07_Guard",
        name = "Disloyalty Among the Guards",
        category = "Main Quest | Tribunal",
        subcategory = "Royal Palace Quests (Optional)",
        text = "Investigate the Royal Guards to search for evidence related to a possible plot against the King."
    },
    {
        id = "TR08_Hlaalu",
        name = "Evidence of Conspiracy",
        category = "Main Quest | Tribunal",
        subcategory = "Royal Palace Quests (Optional)",
        text = "Look into another possible plot against the king involving the former King Llethan's widow."
    },
    {
        id = "TR09_Journalist",
        name = "Muckraking Journalist",
        category = "Main Quest | Tribunal",
        subcategory = "Royal Palace Quests (Optional)",
        text = "Learn the identity of the anonymous writer of The Common Tongue."
    },
    {
        id = "TR_KillGoblins",
        name = "The Goblin Army",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Investigate the rumors of a Goblin army being gathered by Lord Helseth."
    },
    {
        id = "TR_ShrineDead",
        name = "The Shrine of the Dead",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Explore the Temple Sewers to find and cleanse this forgotten shrine."
    },
    {
        id = "TR_MazedBand",
        name = "Barilzar's Mazed Band",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Find this powerful artifact hidden beneath the Temple and return it to Almalexia."
    },
    {
        id = "TR_MHAttack",
        name = "An Attack on Mournhold",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Defend the Mournhold Plaza from a Fabricant attack."
    },
    {
        id = "TR_Bamz",
        name = "Investigate Bamz-Amschend",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Explore a newly-discovered ruin and find out where the fabricants originate."
    },
    {
        id = "TR_Assassins",
        name = "An Assassination Attempt",
        category = "Main Quest | Tribunal",
        subcategory = "Royal Palace Quests (Optional)",
        text = "Discover a possible plot to kill King Helseth."
    },
    {
        id = "TR_Champion",
        name = "Helseth's Champion",
        category = "Main Quest | Tribunal",
        subcategory = "Royal Palace Quests (Optional)",
        text = "Prove your worth to King Helseth by dueling his personal bodyguard."
    },
    {
        id = "TR_ShowPower",
        name = "A Show of Power",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Further investigate the Plaza attack for Helseth by working for Almalexia."
    },
    {
        id = "TR_MissingHand_02",
        name = "The Missing Hand",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Take care of one of the Hands of Almalexia who has abandoned his post."
    },
    {
        id = "TR_Blade",
        name = "The Blade of Nerevar",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Gather the three broken pieces of this legendary blade to reforge it."
    },
    {
        id = "TR_SothaSil",
        name = "The Mad God",
        category = "Main Quest | Tribunal",
        subcategory = "Temple Quests",
        text = "Find the supposedly mad Sotha Sil in his hidden Clockwork City for Almalexia."
    },

    -- =========================================================================
    -- MISCELLANEOUS
    -- =========================================================================
    {
        id = "MS_BarbarianBook",
        name = "The Barbarian and the Book",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Aid poor Thrud in finding his missing wizard friend Dilborn in the Godsreach sewers."
    },
    {
        id = "MS_Bouncer",
        name = "Bouncer",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Fill in for a missing bouncer for Hession in the Winged Guar."
    },
    {
        id = "MS_ClutterCollector",
        name = "The Champion of Clutter",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Help Detritus Caria complete his exhaustive collection of junk."
    },
    {
        id = "MS_BattleBots1",
        name = "Dwemer Warbots",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Help Ignatius Flaccus repair his robots in the basement of his home."
    },
    {
        id = "MS_EstateSale",
        name = "Estate Sale",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Retrieve this rare dagger from the widow Arnsa Thendas for a collector."
    },
    {
        id = "MS_Adulterer",
        name = "Infidelities",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Investigate Deldrise Andoren's possibly unfaithful husband."
    },
    {
        id = "MS_BattleBots2",
        name = "Robot Arena",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Save Ignatius Flaccus from his own robots."
    },
    {
        id = "MS_JobHunt",
        name = "The Smith's Apprentice",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Meet this unhappy apprentice in the Craftsmen's Hall."
    },
    {
        id = "MS_Thief",
        name = "The Thief",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "The investigation of a mad woman yields an unexpected adventure."
    },
    {
        id = "MS_Warlords - MS_Warlords_a",
        name = "The Warlords",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Help a band of rebels in the Vacant Manor kill and take valuable items from local nobles."
    },
    {
        id = "MS_HolyElf",
        name = "Wood Elf with a Grievance",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Help High-Pockets with a bully in The Winged Guar."
    },
    {
        id = "MS_BlackDart",
        name = "The Black Dart Gang",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Help a woman avenge her dead lover by killing his killers, the Black Dart Gang."
    },
    {
        id = "MS_MatchMaker",
        name = "The MatchMaker",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Help a lonely woman meet a nice man."
    },
    {
        id = "MS_ScrollSales",
        name = "Scroll Sales",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Find out the source of the special offers available in the Pawnbroker's shop."
    },
    {
        id = "MS_Performers",
        name = "A Star is Born",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Replace an ill actor for this theater troupe."
    },
    {
        id = "MS_Summoner",
        name = "The Summoner",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Hear a vague rumor of a wizard named Velas who just moved into the area."
    },
    {
        id = "MS_CrimsonPlague",
        name = "Crimson Plague",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Solve this recent epidemic caused by a number of infected rats in the Temple."
    },
    {
        id = "MS_Natural",
        name = "The Natural",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        text = "Meet this Wood Elf who wants you to donate vast sums of money."
    },

    -- #########################################################################
    -- GAME: BLOODMOON
    -- #########################################################################

    -- =========================================================================
    -- MAIN QUEST
    -- =========================================================================
    {
        id = "BM_Rumors",
        name = "An Island to the North",
        category = "Main Quest | Bloodmoon",
        subcategory = "Vvardenfell",
        text = "Learn about Solstheim and how to get there."
    },
    {
        id = "BM_Morale",
        name = "Rebellion at Frostmoth",
        category = "Main Quest | Bloodmoon",
        subcategory = "Fort Frostmoth",
        text = "Investigate the low morale of Fort Frostmoth for Captain Carius."
    },
    {
        id = "BM_Smugglers",
        name = "The Frostmoth Smugglers",
        category = "Main Quest | Bloodmoon",
        subcategory = "Fort Frostmoth",
        text = "Help Captain Falx Carius find out who has been smuggling weapons out of the fort."
    },
    {
        id = "BM_CariusGone",
        name = "The Disappearance of Captain Carius",
        category = "Main Quest | Bloodmoon",
        subcategory = "Fort Frostmoth",
        text = "The fort has been attacked and the Captain is missing."
    },
    {
        id = "BM_Stones",
        name = "The Skaal Test of Loyalty",
        category = "Main Quest | Bloodmoon",
        subcategory = "Skaal Village",
        text = "You must complete a ritual for the Skaal in order to gain their trust."
    },
    {
        id = "BM_Trial",
        name = "The Skaal Test of Wisdom",
        category = "Main Quest | Bloodmoon",
        subcategory = "Skaal Village",
        text = "Investigate a possible theft of furs within the Skaal Village to determine the fate of the accused."
    },
    {
        id = "BM_Draugr",
        name = "The Skaal Test of Strength",
        category = "Main Quest | Bloodmoon",
        subcategory = "Skaal Village",
        text = "Prove your strength to the Skaal tribe by investigating the pillar of fire emanating from Lake Fjalding."
    },
    {
        id = "BM_SkaalAttack",
        name = "The Siege of the Skaal Village",
        category = "Main Quest | Bloodmoon",
        subcategory = "Skaal Village",
        text = "Defend the town against a vicious attack by werewolves and get infected by one of them."
    },
    {
        id = "BM_Ceremony1",
        name = "The Totem of Claw and Fang",
        category = "Main Quest | Bloodmoon",
        subcategory = "Skaal Village",
        text = "Recover the Totem of Claw and Fang for the Skaal."
    },
    {
        id = "BM_BearHunt1",
        name = "The Ristaag",
        category = "Main Quest | Bloodmoon",
        subcategory = "Skaal Village",
        text = "Perform this Skaal ceremony by hunting the great Spirit Bear."
    },
    {
        id = "BM_FrostGiant1",
        name = "The Castle Karstaag",
        category = "Main Quest | Bloodmoon",
        subcategory = "Skaal Village",
        text = "Investigate the ominous signs which have foretold the Bloodmoon Prophecy by investigating Castle Karstaag."
    },
    {
        id = "BM_Ceremony2",
        name = "Dream of Hircine",
        category = "Main Quest | Bloodmoon",
        subcategory = "Anywhere",
        text = "Protect the Totem of Claw and Fang from the Skaal."
    },
    {
        id = "BM_BearHunt2",
        name = "Disrupt the Skaal Hunt",
        category = "Main Quest | Bloodmoon",
        subcategory = "Anywhere",
        text = "Interrupt a Skaal ceremony by killing the participants and the Spirit Bear."
    },
    {
        id = "BM_FrostGiant2",
        name = "Siege of Castle Karstaag",
        category = "Main Quest | Bloodmoon",
        subcategory = "Anywhere",
        text = "Stop a rebellion in this castle far to the north on the island."
    },
    {
        id = "BM_WildHunt",
        name = "Hircine's Hunt",
        category = "Main Quest | Bloodmoon",
        subcategory = "Skaal Village or anywhere",
        text = "You are now irrevocably involved in the Hunter's Game and it's a fight for survival."
    },
    {
        id = "BM_WolfGiver, BM_WolfGiver_a",
        name = "Rite of the Wolf Giver",
        category = "Main Quest | Bloodmoon",
        subcategory = "Fort Frostmoth",
        text = "Permanently cure your lycanthropy."
    },

    -- =========================================================================
    -- EAST EMPIRE COMPANY
    -- =========================================================================
    {
        id = "CO_1",
        name = "Establish the Mine",
        category = "Factions | East Empire Company",
        subcategory = "Fort Frostmoth",
        text = "Starting out on the quest to build the Raven Rock colony."
    },
    {
        id = "CO_2",
        name = "A Blocked Door",
        category = "Factions | East Empire Company",
        subcategory = "Fort Frostmoth",
        text = "Get a crazy Nord to leave the villagers alone."
    },
    {
        id = "CO_3, CO_3a, CO_3b",
        name = "Missing Supply Ship",
        category = "Factions | East Empire Company",
        subcategory = "Fort Frostmoth",
        text = "Search for a missing shipment scheduled to arrive at Raven Rock."
    },
    {
        id = "CO_Choice",
        name = "Making a Choice",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock or Fort Frostmoth",
        text = "Take sides to either make the colony succeed or fail."
    },
    {
        id = "CO_4",
        name = "Setting up Shop",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock or Fort Frostmoth",
        text = "Help Falco/Carnius decide which shop to build."
    },
    {
        id = "CO_5",
        name = "Supply Route Problems",
        category = "Factions | East Empire Company",
        subcategory = "Fort Frostmoth",
        text = "Deal with a shipper who is demanding extra payments for delivering some ebony ore."
    },
    {
        id = "CO_6",
        name = "To Catch a Thief",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock",
        text = "Track down who is stealing ebony ore from the mine."
    },
    {
        id = "CO_6a",
        name = "Aiding and Abetting",
        category = "Factions | East Empire Company",
        subcategory = "Fort Frostmoth",
        text = "Help Carnius and Uryn to smuggle ore out of the Raven Rock mine."
    },
    {
        id = "CO_7",
        name = "Bar Brawl",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock or Fort Frostmoth",
        text = "Calm down an old man in the bar who is picking fights with everyone."
    },
    {
        id = "CO_8 or CO_8a",
        name = "Discovery in the Mine",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock or Fort Frostmoth",
        text = "Investigate a strange burial chamber just discovered deep within the ebony mine."
    },
    {
        id = "CO_9",
        name = "Race Against the Clock",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock",
        text = "Deliver a report quickly to Carnius in Fort Frostmoth."
    },
    {
        id = "CO_9a",
        name = "Stop the Messenger",
        category = "Factions | East Empire Company",
        subcategory = "Fort Frostmoth",
        text = "Intercept a report from Falco for Carnius with the help of Hroldar."
    },
    {
        id = "CO_10",
        name = "Razing the Forest",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock or Fort Frostmoth",
        text = "Take care of some Spriggans that have begun attacking the colony."
    },
    {
        id = "CO_11",
        name = "Hiring Guards",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock or Fort Frostmoth",
        text = "Find some guards to protect the colony."
    },
    {
        id = "CO_12",
        name = "Protect Falco",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock",
        text = "Someone wants Falco dead and you have to protect him."
    },
    {
        id = "CO_13",
        name = "Under Siege",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock",
        text = "Protect Raven Rock from a fake Skaal attack."
    },
    {
        id = "CO_12a",
        name = "The Assassin",
        category = "Factions | East Empire Company",
        subcategory = "Fort Frostmoth",
        text = "Carnius requires your skills in the assassination of Falco."
    },
    {
        id = "CO_13a",
        name = "Drastic Measures",
        category = "Factions | East Empire Company",
        subcategory = "Fort Frostmoth",
        text = "Help Carnius Magius plan an attack to slaughter the occupants of Raven Rock."
    },
    {
        id = "CO_Estate",
        name = "The Factor's Estate",
        category = "Factions | East Empire Company",
        subcategory = "Raven Rock or Fort Frostmoth",
        text = "Build your estate as new Factor of the colony."
    },

    -- =========================================================================
    -- MISCELLANEOUS
    -- =========================================================================
    {
        id = "BM_MoonSugar",
        name = "The Moon Sugar Mystery",
        category = "Miscellaneous",
        subcategory = "Fort Frostmoth",
        text = "Investigate some jolly poisonings."
    },
    {
        id = "BM_Missionary",
        name = "The Missing Missionary",
        category = "Miscellaneous",
        subcategory = "Fort Frostmoth",
        text = "Track down this wayward teetotaler."
    },
    {
        id = "BM_Falmer",
        name = "In Search of the Falmer",
        category = "Miscellaneous",
        subcategory = "Raven Rock",
        text = "Find some proof for the existence of Snow Elves for a High Elf in the Raven Rock bar."
    },
    {
        id = "BM_Tymvaul",
        name = "Tymvaul in the Well",
        category = "Miscellaneous",
        subcategory = "Skaal Village",
        text = "Lassnr! Tymvaul has fallen in the well!"
    },
    {
        id = "BM_MeadHall, BM_Meadhall_a",
        name = "The Mead Hall Massacre",
        category = "Miscellaneous",
        subcategory = "Thirsk",
        text = "Visit this mead hall and find out what happened to its patrons."
    },
    {
        id = "BM_MeadHall_b, BM_MeadHall_c",
        name = "Mead Hall Business",
        category = "Miscellaneous",
        subcategory = "Thirsk",
        text = "Run the mead hall as the new chieftain."
    },
    {
        id = "BM_BrodirGrove",
        name = "Betrayal at Brodir Grove",
        category = "Miscellaneous",
        subcategory = "Ulfgar the Unending's Dwelling",
        text = "Help an old barbarian to find his beloved Sovngarde."
    },
    {
        id = "BM_SadSeer",
        name = "The Sad Seer",
        category = "Miscellaneous",
        subcategory = "Geilir the Mumbling's Dwelling",
        text = "A poor old prophet has lost his head."
    },
    {
        id = "BM_CursedCaptain",
        name = "The Cursed Captain",
        category = "Miscellaneous",
        subcategory = "Thormoor's Watch",
        text = "Help a restless sailor find some peace."
    },
    {
        id = "BM_Ingmar",
        name = "Ingmar in a Bind",
        category = "Miscellaneous",
        subcategory = "Valbrandr Barrow",
        text = "A young warrior needs a decoy. Interested?"
    },
    {
        id = "BM_WomanScorned",
        name = "A Woman Scorned",
        category = "Miscellaneous",
        subcategory = "Kjolver's Dwelling",
        text = "Avenge Kjolver's broken heart."
    },
    {
        id = "BM_Retribution",
        name = "A Wife's Retribution",
        category = "Miscellaneous",
        subcategory = "Kolfinna's Dwelling",
        text = "Help extract wergild for a grieving widow."
    },
    {
        id = "BM_Airship - BM_Airship_a - BM_Airship_c",
        name = "The Patchwork Airship",
        category = "Miscellaneous",
        subcategory = "Ald'ruhn",
        text = "Discover the remains of a crashed airship in the wilderness of Solstheim."
    },
}

Mechanics.registerQuests(quests)

return true