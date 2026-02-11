local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Cyrodill
    -- #########################################################################

    {
        id = "PC_m1_FG_Anv1",
        name = "Wet Feet",
        category = "Factions | Cyrodiil Fighters Guild",
        subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Find out what happened to a missing guild member."
    },
    {
        id = "PC_m1_FG_Anv2",
        name = "Khofar's Debt",
        category = "Factions | Cyrodiil Fighters Guild",
        subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
        master = "Project Cyrodill", text = "The guild needs you to collect an unlucky gambler's debt."
    },
    {
        id = "PC_m1_FG_Anv3",
        name = "Lost in the Lowlands",
        category = "Factions | Cyrodiil Fighters Guild",
        subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Take care of a Colovian bear that's terrorizing the Gold Road."
    },
    {
        id = "PC_m1_FG_Anv4",
        name = "Cinduin's Bounty",
        category = "Factions | Cyrodiil Fighters Guild",
        subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Collect the bounty on a Bosmer outlaw."
    },
    {
        id = "PC_m1_FG_Anv5",
        name = "Repossess and Return",
        category = "Factions | Cyrodiil Fighters Guild",
        subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Repossess a painting for the Conservatory of Saint Laeca."
    },
    {
        id = "PC_m1_FG_Anv6",
        name = "Perils of Thesigir",
        category = "Factions | Cyrodiil Fighters Guild",
        subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Brave both bandits and beast in Thesigir Chasm."
    },
    {
        id = "PC_m1_FG_Anv7",
        name = "Growing Up",
        category = "Factions | Cyrodiil Fighters Guild",
        subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Test the guildmaster's son's abilities by helping him clear an Ayleid ruin."
    },
    {
        id = "PC_m1_FG_Anv8",
        name = "Goblin Trouble on the Strident Coast",
        category = "Factions | Cyrodiil Fighters Guild",
        subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Take care of the goblins troubling Brina Cross."
    },
    {
        id = "PC_m1_MG_Anv1",
        name = "Delivery to Fort Heath",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Tisia's Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Deliver some much needed Scrolls of Turn Undead to the legionnaires at Fort Heath."
    },
    {
        id = "PC_m1_MG_Anv2",
        name = "Books from Benirus Manor",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Tisia's Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Borrow some books from the haunted Benirus Manor."
    },
    {
        id = "PC_m1_MG_Anv3",
        name = "Kill Aeril",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Tisia's Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Slay a necromancer that has taken up residence in a nearby crypt."
    },
    {
        id = "PC_m1_MG_Anv4",
        name = "Escort Anaryan",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Tisia's Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Make sure the guild's new expert on necromancy makes it to the guildhall safely."
    },
    {
        id = "PC_m1_MG_Anv5",
        name = "Extermination at Strand",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Tisia's Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Eradicate a group of undead in the ruins of Strand."
    },
    {
        id = "PC_m1_MG_Anv6",
        name = "Staff of Banishing Light",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Tisia's Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Obtain the Staff of Banishing Light from a local enchanter."
    },
    {
        id = "PC_m1_MG_Anv7",
        name = "Soul for Baeralorn",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Tisia's Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Pick up a crystal ball from Anvil's court mage."
    },
    {
        id = "PC_m1_MG_Anv8",
        name = "Slay Edroth",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Tisia's Quests, Anvil Guild",
        master = "Project Cyrodill", text = "Go to the Ayleid ruins of Valsar and kill a necromancer plaguing the Strident Coast."
    },
    {
        id = "PC_m1_MG_BC1",
        name = "A Shocking Experience",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Sielle Eumand's Quests, Brina Cross Guild",
        master = "Project Cyrodill", text = "Get enchanting ingredients at shocking prices!"
    },
    {
        id = "PC_m1_MG_BC2",
        name = "The Spoiled Swordsman",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Sielle Eumand's Quests, Brina Cross Guild",
        master = "Project Cyrodill", text = "Put an end to a swordsman's slander."
    },
    {
        id = "PC_m1_MG_BC3",
        name = "An Unshielded Soul",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Sielle Eumand's Quests, Brina Cross Guild",
        master = "Project Cyrodill", text = "Witness an enlightening lesson in experimental enchanting."
    },
    {
        id = "PC_m1_MG_BC4",
        name = "The Animating Principle",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Sielle Eumand's Quests, Brina Cross Guild",
        master = "Project Cyrodill", text = "Assist Sielle with her experiments by acquiring the soul of a Redeemed Keeper."
    },
    {
        id = "PC_m1_MG_Cha1",
        name = "Five Types of Pearls",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Lysandra Draco's Quests, Charach Guild",
        master = "Project Cyrodill", text = "Scour the seafloor for local varieties of pearls."
    },
    {
        id = "PC_m1_MG_Cha3",
        name = "Unwanted Advances",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Lysandra Draco's Quests, Charach Guild",
        master = "Project Cyrodill", text = "Put a stop to the unwanted advances of an infatuated fool."
    },
    {
        id = "PC_m1_MG_Cha2",
        name = "Welcome Basket",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Ardavan Caralus' Quests, Charach Guild",
        master = "Project Cyrodill", text = "Treat a visiting guild member to some local hospitality."
    },
    {
        id = "PC_m1_MG_Cha4",
        name = "And Stay Out!",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Ardavan Caralus' Quests, Charach Guild",
        master = "Project Cyrodill", text = "Deal with some goblin pests and keep them out for good!"
    },
    {
        id = "PC_m1_MG_Cha5",
        name = "Rescue Divides-To-Iron",
        category = "Factions | Cyrodiil Mages Guild",
        subcategory = "Ardavan Caralus' Quests, Charach Guild",
        master = "Project Cyrodill", text = "Save a guildmate who got in a little too deep."
    },
    {
        id = "PC_m1_TG_Anv1",
        name = "Stolen Valor",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
        master = "Project Cyrodill", text = "Con the Navy into buying their own gear."
    },
    {
        id = "PC_m1_TG_Anv2",
        name = "Saint Emmelia",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
        master = "Project Cyrodill", text = "Collect the hefty insurance on your tragically crashed ship."
    },
    {
        id = "PC_m1_TG_Anv3",
        name = "Intercepted Inspiration",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
        master = "Project Cyrodill", text = "Fine art demands an expensive delivery."
    },
    {
        id = "PC_m1_TG_Anv4PC_m1_TG_Anv4B",
        name = "The Fix is In",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
        master = "Project Cyrodill", text = "Fix a fight for some fast cash."
    },
    {
        id = "PC_m1_TG_Anv5",
        name = "The Black Isle Company",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
        master = "Project Cyrodill", text = "Acquire a golden anvil for your 'prestigious' company."
    },
    {
        id = "PC_m1_TG_Anv6",
        name = "The Black Isle Bounty",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
        master = "Project Cyrodill", text = "Convince Anvil's upper crust to invest in your new company."
    },
    {
        id = "PC_m1_TG_Anv7",
        name = "The Black Isle Bubble",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
        master = "Project Cyrodill", text = "Conduct an interview with the Abecean Monitor to make your company's stock soar!"
    },
    {
        id = "PC_m1_TG_Cha1",
        name = "Vintage Isquel",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
        master = "Project Cyrodill", text = "'Acquire' a rare bottle of isquel for the guild."
    },
    {
        id = "PC_m1_TG_Cha2",
        name = "Alessian Bronze Boots",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
        master = "Project Cyrodill", text = "Located an ancient pair of boots for a wealthy collector."
    },
    {
        id = "PC_m1_TG_Cha3",
        name = "Brass Astrolabe",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
        master = "Project Cyrodill", text = "Steal an astrolabe for the guild."
    },
    {
        id = "PC_m1_TG_Cha4",
        name = "Spring Vida Light-Foot",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
        master = "Project Cyrodill", text = "Break the guild's pawnbroker out of the Goldstone dungeons in Anvil."
    },
    {
        id = "PC_m1_TG_Cha5",
        name = "Flashgrit",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
        master = "Project Cyrodill", text = "Acquire three canisters of explosive flashgrit."
    },
    {
        id = "PC_m1_TG_Cap",
        name = "The Captain",
        category = "Factions | Cyrodiil Thieves Guild",
        subcategory = "The Masqued Captain's Quests, Crypsis",
        master = "Project Cyrodill", text = "The Masqued Captain has requested your assistance with a job."
    },
    {
        id = "PC_m1_K1_HT1",
        name = "By Right of Blood",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
        master = "Project Cyrodill", text = "Plots and poisoned wine mark a change in allegiance."
    },
    {
        id = "PC_m1_K1_HT2",
        name = "Destabilization",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
        master = "Project Cyrodill", text = "Raid a tomb for an ambassador's gift."
    },
    {
        id = "PC_m1_K1_HT3",
        name = "An Imperial Bargain",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
        master = "Project Cyrodill", text = "Strike a deal with the Emperor's scion."
    },
    {
        id = "PC_m1_K1_HT4",
        name = "Last Salute to the Admiral",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
        master = "Project Cyrodill", text = "Ensure that the Navy will not counter a coup."
    },
    {
        id = "PC_m1_K1_HT5",
        name = "Battle for Goldstone",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
        master = "Project Cyrodill", text = "Assault Goldstone castle to force an abdication."
    },
    {
        id = "PC_m1_K1_MC1",
        name = "Ashes of the Missing",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Solvus Orrich's Quests, Anvil",
        master = "Project Cyrodill", text = "A strange intrusion in the royal crypt requires investigation."
    },
    {
        id = "PC_m1_K1_MC2",
        name = "State Charity",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Solvus Orrich's Quests, Anvil",
        master = "Project Cyrodill", text = "Support the needy in the Queen's name."
    },
    {
        id = "PC_m1_K1_MC3",
        name = "The Rumor Mill",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Solvus Orrich's Quests, Anvil",
        master = "Project Cyrodill", text = "Quell rumors of a near-mythical monarch's return."
    },
    {
        id = "PC_m1_K1_MC4",
        name = "Soap Surplus",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Solvus Orrich's Quests, Anvil",
        master = "Project Cyrodill", text = "Investigate a recent influx of Sload soap into Anvil."
    },
    {
        id = "PC_m1_K1_MC5",
        name = "Foreign Aid",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Solvus Orrich's Quests, Anvil",
        master = "Project Cyrodill", text = "Satisfy a diplomat's demand for donations."
    },
    {
        id = "PC_m1_K1_MC6",
        name = "Mergers and Acquisitions",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Solvus Orrich's Quests, Anvil",
        master = "Project Cyrodill", text = "Sway a vote on a company merger."
    },
    {
        id = "PC_m1_K1_MC7",
        name = "An Imperial Hangover",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Queen Millona Conomorus' Quests, Anvil",
        master = "Project Cyrodill", text = "Intoxicate a Prince of the Empire."
    },
    {
        id = "PC_m1_K1_MC8",
        name = "Prevent the Coup",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Queen Millona Conomorus' Quests, Anvil",
        master = "Project Cyrodill", text = "The conspirators muster their forces - ride out and meet them."
    },
    {
        id = "PC_m1_K1_RP1",
        name = "Rancher's Curse",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Reymanus Pelelius' Quests, Anvil",
        master = "Project Cyrodill", text = "There are rumors of a curse at Ossius Ranch."
    },
    {
        id = "PC_m1_K1_RP2",
        name = "Sewer Noises",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Reymanus Pelelius' Quests, Anvil",
        master = "Project Cyrodill", text = "A dangerous cult is thought to have infiltrated the city's sewers."
    },
    {
        id = "PC_m1_K1_RP3",
        name = "Bridge Repair",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Reymanus Pelelius' Quests, Anvil",
        master = "Project Cyrodill", text = "Oversee the repair of a broken bridge."
    },
    {
        id = "PC_m1_K1_RP4",
        name = "Unfair Trade",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Reymanus Pelelius' Quests, Anvil",
        master = "Project Cyrodill", text = "The slave-farmed saltrice of Morrowind sparks a protest in sleepy Marav."
    },
    {
        id = "PC_m1_K1_RP5",
        name = "Breaking Good",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Reymanus Pelelius' Quests, Anvil",
        master = "Project Cyrodill", text = "Set up a sting on a skooma distributor."
    },
    {
        id = "PC_m1_K1_RP6",
        name = "Voiceless Harmony",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Reymanus Pelelius' Quests, Anvil",
        master = "Project Cyrodill", text = "Slay a dreugh queen whose brood is plaguing the coasts of Colovia."
    },
    {
        id = "PC_m1_K1_TH1",
        name = "Collect Call",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Lurius Alro's Quests, Brina Cross",
        master = "Project Cyrodill", text = "Bring forward a tax deadline, to a publican's dismay."
    },
    {
        id = "PC_m1_K1_TH2",
        name = "Good to the Last Drop",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Lurius Alro's Quests, Brina Cross",
        master = "Project Cyrodill", text = "Resolve a payment dispute over tampered brews."
    },
    {
        id = "PC_m1_K1_TH3",
        name = "Liquidity Crisis",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Lurius Alro's Quests, Brina Cross",
        master = "Project Cyrodill", text = "Cover the Marshal's old loans with new ones."
    },
    {
        id = "PC_m1_K1_TH4",
        name = "Bandits in Talgiana Crypt",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Lurius Alro's Quests, Brina Cross",
        master = "Project Cyrodill", text = "Rescue a Skingrad noble from Talgiana Crypt."
    },
    {
        id = "PC_m1_K1_TH5",
        name = "The Blade of Kenes",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Lurius Alro's Quests, Brina Cross",
        master = "Project Cyrodill", text = "A fabled blade could fix the Marshal's finances once and for all."
    },
    {
        id = "PC_m1_K1_VT1",
        name = "The Marshal's Message",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Villina Telvor's Quests, Charach",
        master = "Project Cyrodill", text = "Deliver a petition of redress to the Navy's Navarch."
    },
    {
        id = "PC_m1_K1_VT2",
        name = "Arresting Advice",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Villina Telvor's Quests, Charach",
        master = "Project Cyrodill", text = "Question a smuggler held in the Charach guardhouse."
    },
    {
        id = "PC_m1_K1_VT3",
        name = "Downed and Drowned",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Villina Telvor's Quests, Charach",
        master = "Project Cyrodill", text = "Determine the cause of a sudden shipwreck."
    },
    {
        id = "PC_m1_K1_VT4",
        name = "Naval Leverage",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Villina Telvor's Quests, Charach",
        master = "Project Cyrodill", text = "Secure a lobbyist for Charach's naval interests."
    },
    {
        id = "PC_m1_K1_VT5",
        name = "Unjust Confinement",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Villina Telvor's Quests, Charach",
        master = "Project Cyrodill", text = "Reopen the case of the smugglers' lookout."
    },
    {
        id = "PC_m1_K1_VT6",
        name = "Smugglers' Ruin",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Villina Telvor's Quests, Charach",
        master = "Project Cyrodill", text = "Deal a crippling blow to the smugglers of Stirk Isle."
    },
    {
        id = "PC_m1_Anv_Goldenrod",
        name = "Goldenrod House",
        category = "Factions | Kingdom of Anvil",
        subcategory = "Miscellaneous",
        master = "Project Cyrodill", text = "Purchase Goldenrod House."
    },
    {
        id = "PC_m1_IP_Als1",
        name = "Changing Seasons",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Alsia Juvanus' Quests, Brina Cross",
        master = "Project Cyrodill", text = "A priest seeks closure at a rural wayshrine."
    },
    {
        id = "PC_m1_IP_Als2",
        name = "Culture Shock",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Alsia Juvanus' Quests, Brina Cross",
        master = "Project Cyrodill", text = "Quiet a zealot of Zenithar."
    },
    {
        id = "PC_m1_IP_Als3",
        name = "Lost Stars",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Alsia Juvanus' Quests, Brina Cross",
        master = "Project Cyrodill", text = "Unravel the meaning of a most perplexing phrase."
    },
    {
        id = "PC_m1_IP_Als4",
        name = "Sinweaver",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Alsia Juvanus' Quests, Brina Cross",
        master = "Project Cyrodill", text = "Confront Uricalimo."
    },
    {
        id = "PC_m1_IP_GS1",
        name = "The Old Man and the Sea",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Gerius Siralus' Quests, Charach",
        master = "Project Cyrodill", text = "Find both fish and fisherman in the White Reef Isles."
    },
    {
        id = "PC_m1_IP_GS2",
        name = "The Blind Share",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Gerius Siralus' Quests, Charach",
        master = "Project Cyrodill", text = "Assist a home for old sailors by collecting a donation from a former pirate."
    },
    {
        id = "PC_m1_IP_GS3",
        name = "Drowned Memory",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Gerius Siralus' Quests, Charach",
        master = "Project Cyrodill", text = "Recover a sign of Kynareth's divine favor."
    },
    {
        id = "PC_m1_IP_GS4",
        name = "The Broken Shrine",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Gerius Siralus' Quests, Charach",
        master = "Project Cyrodill", text = "Help a member of the order find absolution by restoring a broken shrine."
    },
    {
        id = "PC_m1_IP_HY1",
        name = "The Monk and the Missing",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Haela Ysonian's Quests, Strident Coast",
        master = "Project Cyrodill", text = "Break the chains of an imprisoned minotaur."
    },
    {
        id = "PC_m1_IP_HY2",
        name = "Parvo's Problem",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Haela Ysonian's Quests, Strident Coast",
        master = "Project Cyrodill", text = "Return the heirloom of a waylaid pilgrim."
    },
    {
        id = "PC_m1_IP_HY3",
        name = "Lindasael",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Haela Ysonian's Quests, Strident Coast",
        master = "Project Cyrodill", text = "Retrieve a varla stone for the Temple of Dibella Estetica."
    },
    {
        id = "PC_m1_IP_HY4",
        name = "A Place to Serve",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Haela Ysonian's Quests, Strident Coast",
        master = "Project Cyrodill", text = "Find a way for Haela Ysonian and Kuram to serve an Anvil temple."
    },
    {
        id = "PC_m1_IP_Lki1",
        name = "Coal for the Furnaces",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Luaki's Quests, Anvil",
        master = "Project Cyrodill", text = "Collect coal for the ascetics of Dibella."
    },
    {
        id = "PC_m1_IP_Lki2",
        name = "Dye Me a River",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Luaki's Quests, Anvil",
        master = "Project Cyrodill", text = "Check the Sacred Workshops; someone over there might need help."
    },
    {
        id = "PC_m1_IP_Lki3",
        name = "Meat-Cute",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Luaki's Quests, Anvil",
        master = "Project Cyrodill", text = "Prepare Dibellan rites for a Bosmer duo."
    },
    {
        id = "PC_m1_IP_Lki4",
        name = "The Drowned",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Luaki's Quests, Anvil",
        master = "Project Cyrodill", text = "Crush a cult or join its ranks."
    },
    {
        id = "PC_m1_IP_Run1",
        name = "Alms for the Hostel of Saint Rosunius",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Runs-Towards-Time's Quests, Anvil",
        master = "Project Cyrodill", text = "Raise money for the Hostel of Saint Rosunius."
    },
    {
        id = "PC_m1_IP_Run2",
        name = "Bluepox",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Runs-Towards-Time's Quests, Anvil",
        master = "Project Cyrodill", text = "Research and cure a rare disease."
    },
    {
        id = "PC_m1_IP_Run3",
        name = "Persarine Contract",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Runs-Towards-Time's Quests, Anvil",
        master = "Project Cyrodill", text = "Of apologetic alchemists and goblin flower-thieves."
    },
    {
        id = "PC_m1_IP_Run4",
        name = "Recruit Vurila",
        category = "Factions | Order of Itinerant Priests",
        subcategory = "Runs-Towards-Time's Quests, Anvil",
        master = "Project Cyrodill", text = "Re-recruit Vurila, an ex-Itinerant Priest."
    },
    {
        id = "PC_m1_AFP01",
        name = "Making a Name",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Sign on as a performer in the fighting pit under the Abecette."
    },
    {
        id = "PC_m1_AFP02",
        name = "Unbitten?",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Defeat Willy the Unbitten, first lackey of the Nightingale."
    },
    {
        id = "PC_m1_AFP03",
        name = "Saint",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Beat a blessing out of the high priestess of Sed-Yenna."
    },
    {
        id = "PC_m1_AFP04",
        name = "Snake",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Strike the Snake - an opponent claiming a Tsaesci bloodline."
    },
    {
        id = "PC_m1_AFP05",
        name = "The Large",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Throw down Harge the Large, scion of giants."
    },
    {
        id = "PC_m1_AFP06",
        name = "Knight of Cups",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Prevail in a fight against a dishonorable knight."
    },
    {
        id = "PC_m1_AFP07",
        name = "Rough Boarding",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Face off against a piratical pair."
    },
    {
        id = "PC_m1_AFP08",
        name = "Less Than Buoyant",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Fend off the glass-clad Armiger, a sworn champion of Vivec."
    },
    {
        id = "PC_m1_AFP09",
        name = "A Thousand Hands and Two",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Depose an Ayleid king to the cheers of the crowd."
    },
    {
        id = "PC_m1_AFP10",
        name = "Warlord Wartgog",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Duel a warlord of Orsinium."
    },
    {
        id = "PC_m1_AFP11",
        name = "Takhur The Terrible",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "Triumph against Takhur the Terrible, a powerful hand-to-hand fighter."
    },
    {
        id = "PC_m1_AFP12",
        name = "Simulacrum",
        category = "Miscellaneous",
        subcategory = "Abecette Fight Pit, Anvil",
        master = "Project Cyrodill", text = "The nefarious Nightingale reveals himself! Prepare for battle!"
    },
    {
        id = "PC_m1_Anv_Bounty_Annka",
        name = "Bounty: Annka Stone-Sides",
        category = "Miscellaneous",
        subcategory = "Lantin Chaskav's Bounties, Anvil",
        master = "Project Cyrodill", text = "Annka Stone-Sides is wanted dead or alive."
    },
    {
        id = "PC_m1_Anv_Bounty_Catius",
        name = "Bounty: Catius Rilo",
        category = "Miscellaneous",
        subcategory = "Lantin Chaskav's Bounties, Anvil",
        master = "Project Cyrodill", text = "Hunt down a murderous deserter from the Imperial Navy."
    },
    {
        id = "PC_m1_Anv_Bounty_Firas",
        name = "Bounty: Firas",
        category = "Miscellaneous",
        subcategory = "Lantin Chaskav's Bounties, Anvil",
        master = "Project Cyrodill", text = "Take down a trio of bandits camped near the Dasek Marsh."
    },
    {
        id = "PC_m1_Anv_Bounty_Jarus",
        name = "Bounty: Jarus Trasius",
        category = "Miscellaneous",
        subcategory = "Lantin Chaskav's Bounties, Anvil",
        master = "Project Cyrodill", text = "Find an armed robber last seen on the Gold Road."
    },
    {
        id = "PC_m1_Anv_Bounty_MC",
        name = "Bounty: The Masqued Captain",
        category = "Miscellaneous",
        subcategory = "Lantin Chaskav's Bounties, Anvil",
        master = "Project Cyrodill", text = "The kingdom's put a price on the head of a pirate lord."
    },
    {
        id = "PC_m1_Anv_Bounty_Rue",
        name = "Bounty: Rue Vaneria",
        category = "Miscellaneous",
        subcategory = "Lantin Chaskav's Bounties, Anvil",
        master = "Project Cyrodill", text = "Find out who's been killing outlaws along the Sutch-Anvil border."
    },
    {
        id = "PC_m1_Anv_Bounty_Rycima",
        name = "Bounty: Rycima",
        category = "Miscellaneous",
        subcategory = "Lantin Chaskav's Bounties, Anvil",
        master = "Project Cyrodill", text = "Capture a skooma dealer on the streets of Anvil."
    },
    {
        id = "PC_m1_Anv_Bounty_SDato",
        name = "Bounty: S'Dato",
        category = "Miscellaneous",
        subcategory = "Lantin Chaskav's Bounties, Anvil",
        master = "Project Cyrodill", text = "Track down a murderer who has fled over the sea."
    },
    {
        id = "PC_m1_SC_Bounty_Jarus",
        name = "Bounty: Jarus Trasius",
        category = "Miscellaneous",
        subcategory = "Foroch's Bounties, Strident Coast",
        master = "Project Cyrodill", text = "A thief has made off with a bottle of wine."
    },
    {
        id = "PC_m0_Vva_TropVac, PC_m0_Vva_TropVacB",
        name = "Agrippina Herennia's Tropical Vacation",
        category = "Miscellaneous",
        subcategory = "Vvardenfell",
        master = "Project Cyrodill", text = "Help Agrippina Herennia travel to Charach for a tropical vacation."
    },
    {
        id = "PC_m1_Anv_Glimpse",
        name = "A Glimpse of Beauty",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A poet's long absence alarms a follower of Dibella."
    },
    {
        id = "PC_m1_Anv_AdvRead",
        name = "Advanced Reading",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Banish a bookseller's unwelcome Guardian."
    },
    {
        id = "PC_m1_Anv_AppBorg",
        name = "An Apprentice for Borgush",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "An old Orc smith seeks an apprentice."
    },
    {
        id = "PC_m1_Anv_BeNeigh",
        name = "Being Neighborly",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Solve a neighbor problem by bringing a silver spear."
    },
    {
        id = "PC_m1_Anv_BlkView",
        name = "Blocking the View",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Remove the tree blocking a heavenly view."
    },
    {
        id = "PC_m1_Anv_BookClub",
        name = "Book Club",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Join a book club in search of dangerous radicals."
    },
    {
        id = "PC_m1_Anv_CallTribe",
        name = "Call for a Tribe",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A tribeless Bosmer wants to join the Srethuun Tribe."
    },
    {
        id = "PC_m1_Anv_CrabBuck",
        name = "Crab Bucket",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Don't murder mooncrabs in a bucket-retrieval run."
    },
    {
        id = "PC_m1_Anv_DauMarks",
        name = "Daughter of a Marksman",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Take down an Alphyn with the help of a young hunter."
    },
    {
        id = "PC_m1_Anv_DownWithShip",
        name = "Down With the Ship",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Recover a body for a guilt-ridden captain."
    },
    {
        id = "PC_m1_Anv_FeedSal",
        name = "Feed Sal",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A sailor is worried about their pet muskrat."
    },
    {
        id = "PC_m1_Anv_GrimFortune",
        name = "A Grim Fortune",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A Tenet-reading predicts a grim fate - or long life."
    },
    {
        id = "PC_m1_Anv_HeriHadr",
        name = "Heritage of the Hadrachs",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Recover three relics from the Hadrach family's crypt."
    },
    {
        id = "PC_m1_Anv_ImpCause",
        name = "Improbable Cause",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "An imprisoned Sea Elf protests his innocence."
    },
    {
        id = "PC_m1_Gld_LetterIn",
        name = "Letter In",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A Breton's pen-pal has stopped writing - find out why."
    },
    {
        id = "PC_m1_Gld_LunarIntox",
        name = "Lunar Intoxication",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Obtain a rare lunar substance for the court wizard."
    },
    {
        id = "PC_m1_Anv_MidLife",
        name = "Mid-Life Crisis",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Occupy an Orc to give his daughter some space."
    },
    {
        id = "PC_m1_Anv_NakedNard",
        name = "The Naked 'Nard",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A nude Montagnard requests your aid."
    },
    {
        id = "PC_m1_Anv_OceanBlue",
        name = "The Ocean Blue",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Secure funding for a western trade mission to Akavir."
    },
    {
        id = "PC_m1_Anv_PickPilg",
        name = "The Picky Pilgrim",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A Hlaalu pilgrim pines for Morrowind fare."
    },
    {
        id = "PC_m1_Anv_PirRev",
        name = "A Pirate's Revenge",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "An imprisoned pirate wants revenge on his former captain."
    },
    {
        id = "PC_m1_Anv_PorMug",
        name = "Portrait of a Mugger",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A young artist seeks a place at the Conservatory of Saint Laeca."
    },
    {
        id = "PC_m1_Anv_Recluse",
        name = "The Recluse",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A man seeks someone who can undo the vampiric curse."
    },
    {
        id = "PC_m1_Anv_StrokeFort",
        name = "Stroke of Fortune",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A lucky amulet's been lost to a bet gone bad."
    },
    {
        id = "PC_m1_Anv_TakingTax",
        name = "Taking Care of Taxes",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Aid the collection of tax arrears."
    },
    {
        id = "PC_m1_Anv_ThreeStrang",
        name = "Three Perfect Strangers",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A nobleman misses his wife, and his wife her freedom."
    },
    {
        id = "PC_m1_Anv_WarmWtr",
        name = "Warm Water",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "A Redguard sailor is in hot water."
    },
    {
        id = "PC_m1_Anv_WellMet",
        name = "Well Met By Moonlight",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Class divides beset a fledgling love."
    },
    {
        id = "PC_m1_Anv_WorkOrc",
        name = "Work for an Orc",
        category = "Miscellaneous",
        subcategory = "Anvil",
        master = "Project Cyrodill", text = "Help an unemployed orc find work."
    },
    {
        id = "PC_m1_Arc_AloeThere",
        name = "Aloe There",
        category = "Miscellaneous",
        subcategory = "Archad",
        master = "Project Cyrodill", text = "The healer in Archad wants five portions of aloe vera pulp."
    },
    {
        id = "PC_m1_Arc_Snakebit",
        name = "Snakebitten",
        category = "Miscellaneous",
        subcategory = "Archad",
        master = "Project Cyrodill", text = "A vicious aspis is terrorizing the village of Archad."
    },
    {
        id = "PC_m1_BC_MurdCross",
        name = "Murder on the Crossroads",
        category = "Miscellaneous",
        subcategory = "Brina Cross",
        master = "Project Cyrodill", text = "Investigate Arahn Kimoi's murder."
    },
    {
        id = "PC_m1_BC_WomPetri",
        name = "A Woman Named Petri",
        category = "Miscellaneous",
        subcategory = "Brina Cross",
        master = "Project Cyrodill", text = "Claims of stolen valor demand investigation."
    },
    {
        id = "PC_m1_Cha_FigSpeech",
        name = "Fig-ure of Speech",
        category = "Miscellaneous",
        subcategory = "Charach",
        master = "Project Cyrodill", text = "Explain things to the gremlin Witgi."
    },
    {
        id = "PC_m1_Cha_GhastOrd",
        name = "The Ghastly Ordeal of Saverius Albuttian",
        category = "Miscellaneous",
        subcategory = "Charach",
        master = "Project Cyrodill", text = "Aid an absconscion from an old sailors home."
    },
    {
        id = "PC_m1_Cha_GoldNets",
        name = "Gold in the Nets",
        category = "Miscellaneous",
        subcategory = "Charach",
        master = "Project Cyrodill", text = "Discover the truth behind a fisherman's glittering haul."
    },
    {
        id = "PC_m1_Cha_MGTinySeadrake",
        name = "Tiny Seadrake",
        category = "Miscellaneous",
        subcategory = "Charach",
        master = "Project Cyrodill", text = "A member of the Mages Guild wants you to find a rare seadrake egg."
    },
    {
        id = "PC_m1_Cha_PelLeg",
        name = "The Pelladia Legacy",
        category = "Miscellaneous",
        subcategory = "Charach",
        master = "Project Cyrodill", text = "Recover the relics of an ancient Colovian lineage."
    },
    {
        id = "PC_m1_Cha_PlaDand",
        name = "Plants for Dandryn Arethyn",
        category = "Miscellaneous",
        subcategory = "Charach",
        master = "Project Cyrodill", text = "Help a botanist with his studies by collecting some plants."
    },
    {
        id = "PC_m1_Cha_Selkies",
        name = "Selkies",
        category = "Miscellaneous",
        subcategory = "Charach",
        master = "Project Cyrodill", text = "Help a fisherman find the beautiful woman he's looking for."
    },
    {
        id = "PC_m1_Cha_Cassynder",
        name = "Wreck of the Cassynder",
        category = "Miscellaneous",
        subcategory = "Charach",
        master = "Project Cyrodill", text = "Dredge up cargo and contraband for Charach's harbormaster."
    },
    {
        id = "PC_m1_Sdk_HermDag",
        name = "The Hermontar Dagger",
        category = "Miscellaneous",
        subcategory = "Hal Sadek",
        master = "Project Cyrodill", text = "A fisherman is lamenting the loss of his 'lucky dagger'."
    },
    {
        id = "PC_m1_Mrv_ReevesKey",
        name = "Needle in a Haystack",
        category = "Miscellaneous",
        subcategory = "Marav",
        master = "Project Cyrodill", text = "Hay! Help!"
    },
    {
        id = "PC_m1_Tvy_NobleDebt, PC_m1_Tvy_NobleDebt1,PC_m1_Tvy_NobleDebt2, PC_m1_Tvy_NobleDebt3",
        name = "A Noble Debt",
        category = "Miscellaneous",
        subcategory = "Thresvy",
        master = "Project Cyrodill", text = "A down on his luck noble needs you to handle his debt."
    },
    {
        id = "PC_m1_Tvy_ThresvyDef",
        name = "Thresvy's Defender",
        category = "Miscellaneous",
        subcategory = "Thresvy",
        master = "Project Cyrodill", text = "Thresvy lacks troops and its Reeve needs an adventurer."
    },
    {
        id = "PC_m1_DM_AdosusAdun",
        name = "Adosu's Adun",
        category = "Miscellaneous",
        subcategory = "Wilderness (Dasek Marsh)",
        master = "Project Cyrodill", text = "Bring a bard back their instrument from a Dasek Marsh barrow."
    },
    {
        id = "PC_m1_SC_WineMasons",
        name = "Battlewine for Brickmasons",
        category = "Miscellaneous",
        subcategory = "Wilderness (Strident Coast)",
        master = "Project Cyrodill", text = "Help some construction workers get some relief from their backbreaking labor."
    },
    {
        id = "PC_m1_SC_GoatTrbls",
        name = "Calvus' Goat Troubles",
        category = "Miscellaneous",
        subcategory = "Wilderness (Strident Coast)",
        master = "Project Cyrodill", text = "Keep an eye out for a missing buck, Kod."
    },
    {
        id = "PC_m1_SC_TravelMerch",
        name = "Fortune of a Traveling Merchant",
        category = "Miscellaneous",
        subcategory = "Wilderness (Strident Coast)",
        master = "Project Cyrodill", text = "A famed helm is up for sale."
    },
    {
        id = "PC_m1_SC_GarlasAgeaPC_m1_SC_GarlasAgeaAuroranPC_m1_SC_GarlasAgeaNotes",
        name = "Into Ugly Obscurity",
        category = "Miscellaneous",
        subcategory = "Wilderness (Strident Coast)",
        master = "Project Cyrodill", text = "Delve into an Ayleid stronghold, and unlock terrible secrets..."
    },
    {
        id = "PC_m1_SC_ManuMaraud",
        name = "Manuscript Marauders",
        category = "Miscellaneous",
        subcategory = "Wilderness (Strident Coast)",
        master = "Project Cyrodill", text = "Return an ecologist's research from the outskirts of a bandit camp."
    },
    {
        id = "PC_m1_SC_SweetTooth",
        name = "Pintra's Sweet Tooth",
        category = "Miscellaneous",
        subcategory = "Wilderness (Strident Coast)",
        master = "Project Cyrodill", text = "A legionnaire is sick of her monotonous, fishy diet."
    },
}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending PC quest data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
