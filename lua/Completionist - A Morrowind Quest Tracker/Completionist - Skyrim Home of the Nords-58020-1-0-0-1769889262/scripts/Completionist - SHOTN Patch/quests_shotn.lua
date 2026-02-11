local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Skyrim
    -- #########################################################################

    {
        id = "Sky_qRe_KWFG1_Journal",
        name = "Wormmouth Problem",
        category = "Factions | Skyrim Fighters Guild",
        subcategory = "Geod Entoriane's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Kill a violent wormmouth."
    },
    {
        id = "Sky_qRe_KWFG2_Journal",
        name = "Kill Orcish Bandits",
        category = "Factions | Skyrim Fighters Guild",
        subcategory = "Geod Entoriane's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Kill two Orcish bandits in the Vorndgad Forest."
    },
    {
        id = "Sky_qRe_KWFG3_Journal",
        name = "Ildos Norvor's Caravan",
        category = "Factions | Skyrim Fighters Guild",
        subcategory = "Geod Entoriane's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Discover the fate of Ildos Norvor's unlucky caravan."
    },
    {
        id = "Sky_qRe_KWFG4_Journal",
        name = "Geod's Vendetta",
        category = "Factions | Skyrim Fighters Guild",
        subcategory = "Geod Entoriane's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Geod wants you to settle a score for him."
    },
    {
        id = "Sky_qRe_DSMG1_Journal",
        name = "Regulated Research",
        category = "Factions | Hammerfell Mages Guild",
        subcategory = "Harelia's Quests, Dragonstar Guild",
        master = "Skyrim: Home of the Nords", text = "Gather some research notes for an alchemist."
    },
    {
        id = "Sky_qRe_DSMG2_Journal",
        name = "Mesa Medicine",
        category = "Factions | Hammerfell Mages Guild",
        subcategory = "Harelia's Quests, Dragonstar Guild",
        master = "Skyrim: Home of the Nords", text = "Pick up a Reachman secret."
    },
    {
        id = "Sky_qRe_DSMG3_Journal",
        name = "An Acolyte in the Arena",
        category = "Factions | Hammerfell Mages Guild",
        subcategory = "Eranthos's Quests, Dragonstar Guild",
        master = "Skyrim: Home of the Nords", text = "Save an apprentice from his fight."
    },
    {
        id = "Sky_qRe_DSMG4_Journal",
        name = "Public Perception",
        category = "Factions | Hammerfell Mages Guild",
        subcategory = "Eranthos's Quests, Dragonstar Guild",
        master = "Skyrim: Home of the Nords", text = "Make people have a higher opinion of the Guild."
    },
    {
        id = "Sky_qRe_DSMG5_Journal",
        name = "Angturiel",
        category = "Factions | Hammerfell Mages Guild",
        subcategory = "Eranthos's Quests, Dragonstar Guild",
        master = "Skyrim: Home of the Nords", text = "Discover an old Direnni Ruin."
    },
    {
        id = "Sky_qRe_KWMG1_Journal",
        name = "Optimistic Outreach",
        category = "Factions | Skyrim Mages Guild",
        subcategory = "Ji'Tavarad's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Bring some scrolls to a Guild member."
    },
    {
        id = "Sky_qRe_KWMG2_Journal",
        name = "Out for a Spell",
        category = "Factions | Skyrim Mages Guild",
        subcategory = "Ji'Tavarad's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Search for a forbidden spell."
    },
    {
        id = "Sky_qRe_KWMG3_Journal",
        name = "A Case for Concern",
        category = "Factions | Skyrim Mages Guild",
        subcategory = "Ji'Tavarad's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Help resolve a dispute about a shipment of cloth."
    },
    {
        id = "Sky_qRe_KWMG4_Journal",
        name = "A Crisis of Character",
        category = "Factions | Skyrim Mages Guild",
        subcategory = "Ji'Tavarad's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Ravos Terandas has gotten into some trouble in Karthgad."
    },
    {
        id = "Sky_qRe_KWMG5_Journal",
        name = "Turbulent Teleporting",
        category = "Factions | Skyrim Mages Guild",
        subcategory = "Ji'Tavarad's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Ji'Tavarad wishes to re-establish the severed link between the Dragonstar Guild of Mages."
    },
    {
        id = "Sky_qRe_KWMG6_Journal",
        name = "The Penumbra",
        category = "Factions | Skyrim Mages Guild",
        subcategory = "Nistamal's Quests, Karthwasten Guild",
        master = "Skyrim: Home of the Nords", text = "Clear out several ghosts from a ruined village."
    },
    {
        id = "Sky_qRe_DSTG1_Journal",
        name = "Census and Excess",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Anbod's Quests, Shadowkey Tavern, Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Steal three bolts of Moth-Silk from the Ra-Habi Company Hall and deliver them to Gorelius at the Census and Excise Office."
    },
    {
        id = "Sky_qRe_DSTG2_Journal",
        name = "How to Rob Oneself",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Anbod's Quests, Shadowkey Tavern, Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Rob a warehouse of two Khajiit brothers, for them."
    },
    {
        id = "Sky_qRe_DSTG3_Journal, Sky_qRe_DSTG3a_Journal",
        name = "Networking",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Anbod's Quests, Shadowkey Tavern, Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Find some new informants and another Toad for the Thieves Guild."
    },
    {
        id = "Sky_qRe_DSTG4_Journal",
        name = "Papers, please!",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Anbod's Quests, Shadowkey Tavern, Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Get forged papers for the newest member of the Thieves Guild from Karthwasten."
    },
    {
        id = "Sky_qRe_DSTG5_Journal",
        name = "Distractions",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Anbod's Quests, Shadowkey Tavern, Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Find more information about Dalach and his gang."
    },
    {
        id = "Sky_qRe_DSTG6_Journal",
        name = "Eye-Spy",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Anbod's Quests, Shadowkey Tavern, Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Deal with Dalach's spy in the Crown Palace in Dragonstar West."
    },
    {
        id = "Sky_qRe_DSTG7_Journal, Sky_qRe_DSTG7a_Journal",
        name = "The Dragon Heist",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Anbod's Quests, Shadowkey Tavern, Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Steal the orichalc blade, Tangra, from the Jarl's vault beneath the Dragonstar Castle."
    },
    {
        id = "Sky_qRe_KWTG1_Journal",
        name = "A Dancing Distraction",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Lorvacah's Quests, Droopy Mare Inn, Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Steal a ring from Caponicus Valion."
    },
    {
        id = "Sky_qRe_KWTG2_Journal",
        name = "Doing a Cat's Job",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Lorvacah's Quests, Droopy Mare Inn, Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Sell some moon sugar for J'Diir."
    },
    {
        id = "Sky_qRe_KWTG3_Journal",
        name = "Bumbling Competition",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Lorvacah's Quests, Droopy Mare Inn, Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Deal with the troublesome thief, Corelyn."
    },
    {
        id = "Sky_qRe_KWTG4_Journal",
        name = "Top-Shelf Theft",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Lorvacah's Quests, Droopy Mare Inn, Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Steal a vintage wine."
    },
    {
        id = "Sky_qRe_KWTG5_Journal",
        name = "A Curious Concoction",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Boss Kanah's Quests, Thieves Guild Hideout, Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Steal a new sample from the local alchemist."
    },
    {
        id = "Sky_qRe_KWTG6_Journal",
        name = "Dilemma For Disarray",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Boss Kanah's Quests, Thieves Guild Hideout, Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Plant a fake map in the City Barracks."
    },
    {
        id = "Sky_qRe_KWTG7_Journal",
        name = "Looting the Lost Heirloom",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Boss Kanah's Quests, Thieves Guild Hideout, Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Steal an heirloom from the Boar Snout Manor."
    },
    {
        id = "Sky_qRe_KWTG8_Journal",
        name = "Playing All Sides",
        category = "Factions | Skyrim Thieves Guild",
        subcategory = "Boss Kanah's Quests, Thieves Guild Hideout, Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Intercept some correspondence."
    },
    {
        id = "Sky_qRe_KWB07_Journal",
        name = "Bounty: Azzam",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Azzam."
    },
    {
        id = "Sky_qRe_KWB08_Journal",
        name = "Bounty: Beloth's Gang",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Beloth and his gang."
    },
    {
        id = "Sky_qRe_KWB02_Journal",
        name = "Bounty: Dovica",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Dovica."
    },
    {
        id = "Sky_qRe_KWB05_JournalA",
        name = "Bounty: Emfrid",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Emfrid."
    },
    {
        id = "Sky_qRe_KWB06_Journal",
        name = "Bounty: Herkja's Gang",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Herkja and her gang."
    },
    {
        id = "Sky_qRe_KWB01_Journal",
        name = "Bounty: Hjalmar Bear-Eye's Gang",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Hjalmar Bear-Eye and his gang."
    },
    {
        id = "Sky_qRe_KWB09_Journal",
        name = "Bounty: Jaghren's Cult",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Jaghren's Cult."
    },
    {
        id = "Sky_qRe_KW_B10_JournalA, Sky_qRe_KW_B10_JournalB",
        name = "Bounty: Rakan",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Rakan and the Sur-Rata."
    },
    {
        id = "Sky_qRe_KW_B04_JournalA, Sky_qRe_KW_B04_JournalB",
        name = "Bounty: Tharag gro-Kul and Meshif",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Tharag gro-Kul and Meshif."
    },
    {
        id = "Sky_qRe_KWB03_Journal",
        name = "Bounty: Uldar Ember-Seeker",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Uldar Ember-Seeker."
    },
    {
        id = "Sky_qRe_DSB5_Journal",
        name = "Bounty: Bogakh gro-Durz",
        category = "Miscellaneous",
        subcategory = "Taurus Hall",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Bogakh gro-Durz."
    },
    {
        id = "Sky_qRe_DSB1_Journal",
        name = "Bounty: Cacitus Suspilus",
        category = "Miscellaneous",
        subcategory = "Taurus Hall",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Cacitus Suspilus."
    },
    {
        id = "Sky_qRe_DSB2_Journal",
        name = "Bounty: Cegoraec",
        category = "Miscellaneous",
        subcategory = "Taurus Hall",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Cegoraec."
    },
    {
        id = "Sky_qRe_DSB4_Journal",
        name = "Bounty: Iztara",
        category = "Miscellaneous",
        subcategory = "Taurus Hall",
        master = "Skyrim: Home of the Nords", text = "Escort the Sogat Dur-Gada informant Iztara into Imperial custody."
    },
    {
        id = "Sky_qRe_DSB3_Journal",
        name = "Bounty: Lovi the Gut",
        category = "Miscellaneous",
        subcategory = "Taurus Hall",
        master = "Skyrim: Home of the Nords", text = "Claim the bounty on Lovi the Gut."
    },
    {
        id = "Sky_qRe_DSW6_Journal",
        name = "Out of Practice",
        category = "Miscellaneous",
        subcategory = "Vvardenfell and Project Cyrodiil",
        master = "Skyrim: Home of the Nords", text = "Cross boundaries while helping a teleporter practice their craft."
    },
    {
        id = "Sky_qRe_DSE1_Journal",
        name = "Alms for Mara",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Collect alms for the House of Mara from the citizens of Dragonstar East."
    },
    {
        id = "Sky_qRe_DS1_Journal",
        name = "Dragonstar Travel Papers",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Get yourself travel papers to allow access between Dragonstar East and West."
    },
    {
        id = "Sky_qRe_DSE3_Journal",
        name = "Illness in the Alehouse",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Discover what's ailing an alehouse in Dragonstar East."
    },
    {
        id = "Sky_qRe_DSW1_Journal",
        name = "Nahassar's Love Letter",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "A man wants you to deliver a love letter."
    },
    {
        id = "Sky_qRe_DSW3_Journal",
        name = "Seeking a Supplier",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "A Redguard merchant is look for a supplier."
    },
    {
        id = "Sky_qRe_DSE2_Journal",
        name = "That Pig of a Nord",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Help a Nord get his body back."
    },
    {
        id = "Sky_qRe_DSW4_Journal",
        name = "The Baker and the Bread Thief",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Retrieve some stolen bread for a baker."
    },
    {
        id = "Sky_qRe_DSE4_Journal",
        name = "The Dragonstar Arena",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Become the Champion of the Arena."
    },
    {
        id = "Sky_qRe_DSE5_Journal",
        name = "The Fateful Guest",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "A Redguard has returned to his old home. Unfortunately, somebody else has moved in...."
    },
    {
        id = "Sky_qRe_DSW2_Journal",
        name = "The Missing Skull",
        category = "Miscellaneous",
        subcategory = "Dragonstar",
        master = "Skyrim: Home of the Nords", text = "Retrieve some remains for an Orsimer emissary."
    },
    {
        id = "Sky_qRe_HA1a_Journal, Sky_qRe_HA1b_Journal, Sky_qRe_HA1c_Journal",
        name = "Ghoul Hunt",
        category = "Miscellaneous",
        subcategory = "Haimtir",
        master = "Skyrim: Home of the Nords", text = "Deal with some weird people that have been bothering the residents of Haimtír."
    },
    {
        id = "Sky_qRe_HA2_Journal",
        name = "The Spell Unreached",
        category = "Miscellaneous",
        subcategory = "Haimtir",
        master = "Skyrim: Home of the Nords", text = "Rid a Reachwoman of a spell."
    },
    {
        id = "Sky_qRe_HA3_Journal",
        name = "Don't Eat the Wheat",
        category = "Miscellaneous",
        subcategory = "Haimtir",
        master = "Skyrim: Home of the Nords", text = "Help a farmer with a poisonous plan."
    },
    {
        id = "Sky_qRe_LH02_Journal",
        name = "Bandits at Iron-Mane Farm",
        category = "Miscellaneous",
        subcategory = "Iron-Mane Farm",
        master = "Skyrim: Home of the Nords", text = "Deal with a gang harassing the Iron-Mane Farm."
    },
    {
        id = "Sky_qRe_KG4_Journal",
        name = "A Forlorn Barrow",
        category = "Miscellaneous",
        subcategory = "Karthgad",
        master = "Skyrim: Home of the Nords", text = "Investigate a mysterious barrow."
    },
    {
        id = "Sky_qRe_KG3_Journal",
        name = "Blocked From Worship",
        category = "Miscellaneous",
        subcategory = "Karthgad",
        master = "Skyrim: Home of the Nords", text = "Help deal with the spriggan, Harwyleth."
    },
    {
        id = "Sky_qRe_KG2_Journal",
        name = "Karthgad Manhunters",
        category = "Miscellaneous",
        subcategory = "Karthgad",
        master = "Skyrim: Home of the Nords", text = "Be a part of a surprise attack."
    },
    {
        id = "Sky_qRe_KG1_Journal",
        name = "Mining for Worms",
        category = "Miscellaneous",
        subcategory = "Karthgad",
        master = "Skyrim: Home of the Nords", text = "Clear a mine full of spikeworms."
    },
    {
        id = "Sky_qRe_KG5_Journal",
        name = "S'Viir's Hoard",
        category = "Miscellaneous",
        subcategory = "Karthgad",
        master = "Skyrim: Home of the Nords", text = "Find a Khajiit's hidden stash."
    },
    {
        id = "Sky_qRe_KW6_Journal",
        name = "A Beggar in Need",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Help a beggar reunite with an old friend."
    },
    {
        id = "Sky_qRe_KW2_Journal",
        name = "A Lost Sister",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Find a member of Skyrim's Imperial Cult."
    },
    {
        id = "Sky_qRe_KW8_Journal",
        name = "Brokk's Bundles of Barley",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Sort out a missing shipment of flour."
    },
    {
        id = "Sky_qRe_KW1_Journal, Sky_qRe_KW1a_Journal, Sky_qRe_KW1b_Journal, Sky_qRe_KW1c_Journal, Sky_qRe_KW1d_Journal",
        name = "Direnni Registers",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Find some old Direnni Tomes."
    },
    {
        id = "Sky_qRe_KW9_Journal",
        name = "Hide and Seek",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Take an ill-advised sip of an alchemist's potion."
    },
    {
        id = "Sky_qRe_KW3_Journal, Sky_qRe_KW3a_Journal",
        name = "Hjalmar's Captives",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Free the captives taken by Hjalmar."
    },
    {
        id = "Sky_qRe_KW4a_Journal, Sky_qRe_KW4b_Journal",
        name = "Lost in the Reach",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Find a lost husband."
    },
    {
        id = "Sky_qRe_KW5_Journal",
        name = "Pursuit of Knowledge",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Help a mage find her misplaced notes."
    },
    {
        id = "Sky_qRe_KW7_Journal",
        name = "Unwelcome in Karthwasten",
        category = "Miscellaneous",
        subcategory = "Karthwasten",
        master = "Skyrim: Home of the Nords", text = "Help a Khajiit track down his cousin."
    },
    {
        id = "Sky_qRe_MAI4_Journal",
        name = "Gylghi's Goats",
        category = "Miscellaneous",
        subcategory = "Mairager",
        master = "Skyrim: Home of the Nords", text = "Find some goats that have wandered off."
    },
    {
        id = "Sky_qRe_MAI3_Journal",
        name = "Reaching For Answers",
        category = "Miscellaneous",
        subcategory = "Mairager",
        master = "Skyrim: Home of the Nords", text = "Find an escapee from Mairager."
    },
    {
        id = "Sky_qRe_MAI2_Journal",
        name = "Reaching For Love",
        category = "Miscellaneous",
        subcategory = "Mairager",
        master = "Skyrim: Home of the Nords", text = "Aid a Reachman's quest for love."
    },
    {
        id = "Sky_qRe_BM1_Journal",
        name = "Murder in Merduibh",
        category = "Miscellaneous",
        subcategory = "Merduibh",
        master = "Skyrim: Home of the Nords", text = "Investigate the murder of the Merduibh matriarch's apprentice."
    },
    {
        id = "Sky_qRe_BM2_Journal",
        name = "Just Asking Questions",
        category = "Miscellaneous",
        subcategory = "Merduibh",
        master = "Skyrim: Home of the Nords", text = "Continue the investigation of the apprentice's murder."
    },
    {
        id = "Sky_qRe_BM3_Journal",
        name = "A Promise Kept",
        category = "Miscellaneous",
        subcategory = "Merduibh",
        master = "Skyrim: Home of the Nords", text = "Perform a mysterious ritual with the matriarch."
    },
    {
        id = "Sky_qRe_BM4_Journal",
        name = "Chthonic Secrets",
        category = "Miscellaneous",
        subcategory = "Merduibh",
        master = "Skyrim: Home of the Nords", text = "Vesmorah believes that the Bailcnoss Moon Cult were behind her apprentice's murder."
    },
    {
        id = "Sky_qRe_BM5_Journal",
        name = "Between a Hag and a Boar",
        category = "Miscellaneous",
        subcategory = "Merduibh",
        master = "Skyrim: Home of the Nords", text = "The Sun Mother has summoned you to her sanctum."
    },
    {
        id = "Sky_qRe_NAR2_Journal",
        name = "The Alovach and the Nargozh",
        category = "Miscellaneous",
        subcategory = "Nargozh Camp",
        master = "Skyrim: Home of the Nords", text = "Help settle a dispute between the Alovach Reachmen and the Nargozh Orcs."
    },
    {
        id = "Sky_qRe_NAR1_Journal",
        name = "The Beast of Nargozh Camp",
        category = "Miscellaneous",
        subcategory = "Nargozh Camp",
        master = "Skyrim: Home of the Nords", text = "Yarok gra-Malash would like me to find a way to stop a great beast stalking the camp at night."
    },
    {
        id = "Sky_qRe_LH1_Journal",
        name = "A Mine Out of Time",
        category = "Miscellaneous",
        subcategory = "Ruari",
        master = "Skyrim: Home of the Nords", text = "There is some trouble at the nearby Blackstone Silver Mine."
    },
    {
        id = "Sky_qRe_URA1_Journal",
        name = "Misguided Kin",
        category = "Miscellaneous",
        subcategory = "Uramok Camp",
        master = "Skyrim: Home of the Nords", text = "Rid Skyrim of some Malacath worshippers."
    },
    {
        id = "Sky_qRe_VF3_Journal",
        name = "Aland Remyon's Treasure",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Find the treasure of a fallen adventurer."
    },
    {
        id = "Sky_qRe_DH1_Journal",
        name = "An Unreasonable Request",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Kjalmar the Unreasonable has asked me to bring him something useful."
    },
    {
        id = "Sky_qRe_CK1_Journal",
        name = "Clan Khulari: Cattle Rustling",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Collect some cattle for Clan Khulari."
    },
    {
        id = "Sky_qRe_VF1_Journal",
        name = "Curses and Horses",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Track down some runaway horses."
    },
    {
        id = "Sky_qRe_VF2_Journal, Sky_qRe_VF2a_Journal, Sky_qRe_VF2b_Journal, Sky_qRe_VF2c_Journal, Sky_qRe_VF2d_Journal",
        name = "Divided Loyalties",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Deliver a warning from a prisoner."
    },
    {
        id = "Sky_qRe_DH2_Journal",
        name = "Facing a Chicken Menace",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Solve the mystery of the dead chickens."
    },
    {
        id = "Sky_qRe_DH5_Journal",
        name = "Head in the Game",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Win a competition of riddles"
    },
    {
        id = "Sky_qRe_DH4_Journal",
        name = "Hunting with Larrik",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Larrik Ember-Eye is looking for assistance hunting Beten the Horrible."
    },
    {
        id = "Sky_qRe_BAI1_Journal",
        name = "The Tinkerer's Wife",
        category = "Miscellaneous",
        subcategory = "Wilderness",
        master = "Skyrim: Home of the Nords", text = "Seonach wants me to speak to his sorrowful wife"
    },
}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Sky quest data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
