local self = require('openmw.self')

local CyrodiilQuests = {

    -- #########################################################################
    -- Project Cyrodiil
    -- #########################################################################

	-- =========================================================================
    -- KINGDOM OF ANVIL
    -- =========================================================================
  {
	id = "PC_m1_K1_HT1",
	name = "01. By Right of Blood",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
	text = "Plots and poisoned wine mark a change in allegiance." 
  },
  {
	id = "PC_m1_K1_HT2",
	name = "02. Destabilization",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
	text = "Raid a tomb for an ambassador's gift." 
  },
  {
	id = "PC_m1_K1_HT3",
	name = "03. An Imperial Bargain",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
	text = "Strike a deal with the Emperor's scion." 
  },
  {
	id = "PC_m1_K1_HT4",
	name = "04. Last Salute to the Admiral",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
	text = "Ensure that the Navy will not counter a coup." 
  },
  {
	id = "PC_m1_K1_HT5",
	name = "05. Battle for Goldstone",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Micella Marin and Herrius Thimistrel's Quests, Anvil",
	text = "Assault Goldstone castle to force an abdication." 
  },
  {
	id = "PC_m1_K1_MC1",
	name = "01. Ashes of the Missing",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Solvus Orrich's Quests, Anvil",
	text = "A strange intrusion in the royal crypt requires investigation." 
  },
  {
	id = "PC_m1_K1_MC2",
	name = "02. State Charity",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Solvus Orrich's Quests, Anvil",
	text = "Support the needy in the Queen's name." 
  },
  {
	id = "PC_m1_K1_MC3",
	name = "03. The Rumor Mill",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Solvus Orrich's Quests, Anvil",
	text = "Quell rumors of a near-mythical monarch's return." 
  },
  {
	id = "PC_m1_K1_MC4",
	name = "04. Soap Surplus",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Solvus Orrich's Quests, Anvil",
	text = "Investigate a recent influx of Sload soap into Anvil." 
  },
  {
	id = "PC_m1_K1_MC5",
	name = "05. Foreign Aid",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Solvus Orrich's Quests, Anvil",
	text = "Satisfy a diplomat's demand for donations." 
  },
  {
	id = "PC_m1_K1_MC6",
	name = "06. Mergers and Acquisitions",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Solvus Orrich's Quests, Anvil",
	text = "Sway a vote on a company merger." 
  },
  {
	id = "PC_m1_K1_MC7",
	name = "01. An Imperial Hangover",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Queen Millona Conomorus' Quests, Anvil",
	text = "Intoxicate a Prince of the Empire." 
  },
  {
	id = "PC_m1_K1_MC8",
	name = "02. Prevent the Coup",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Queen Millona Conomorus' Quests, Anvil",
	text = "The conspirators muster their forces - ride out and meet them." 
  },
  {
	id = "PC_m1_K1_RP1",
	name = "01. Rancher's Curse",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Reymanus Pelelius' Quests, Anvil",
	text = "There are rumors of a curse at Ossius Ranch." 
  },
  {
	id = "PC_m1_K1_RP2",
	name = "02. Sewer Noises",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Reymanus Pelelius' Quests, Anvil",
	text = "A dangerous cult is thought to have infiltrated the city's sewers." 
  },
  {
	id = "PC_m1_K1_RP3",
	name = "03. Bridge Repair",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Reymanus Pelelius' Quests, Anvil",
	text = "Oversee the repair of a broken bridge." 
  },
  {
	id = "PC_m1_K1_RP4",
	name = "04. Unfair Trade",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Reymanus Pelelius' Quests, Anvil",
	text = "The slave-farmed saltrice of Morrowind sparks a protest in sleepy Marav." 
  },
  {
	id = "PC_m1_K1_RP5",
	name = "05. Breaking Good",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Reymanus Pelelius' Quests, Anvil",
	text = "Set up a sting on a skooma distributor."
  },
  {
	id = "PC_m1_K1_RP6",
	name = "06. Voiceless Harmony",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Reymanus Pelelius' Quests, Anvil",
	text = "Slay a dreugh queen whose brood is plaguing the coasts of Colovia." 
  },
  {
	id = "PC_m1_K1_TH1",
	name = "01. Collect Call",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Lurius Alro's Quests, Brina Cross",
	text = "Bring forward a tax deadline, to a publican's dismay."
  },
  {
	id = "PC_m1_K1_TH2",
	name = "02. Good to the Last Drop",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Lurius Alro's Quests, Brina Cross",
	text = "Resolve a payment dispute over tampered brews." 
  },
  {
	id = "PC_m1_K1_TH3",
	name = "03. Liquidity Crisis",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Lurius Alro's Quests, Brina Cross",
	text = "Cover the Marshal's old loans with new ones." 
  },
  {
	id = "PC_m1_K1_TH4",
	name = "04. Bandits in Talgiana Crypt",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Lurius Alro's Quests, Brina Cross",
	text = "Rescue a Skingrad noble from Talgiana Crypt." 
  },
  {
	id = "PC_m1_K1_TH5",
	name = "05. The Blade of Kenes",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Lurius Alro's Quests, Brina Cross",
	text = "A fabled blade could fix the Marshal's finances once and for all." 
  },
  {
	id = "PC_m1_K1_VT1",
	name = "01. The Marshal's Message",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Villina Telvor's Quests, Charach",
	text = "Deliver a petition of redress to the Navy's Navarch." 
  },
  {
	id = "PC_m1_K1_VT2",
	name = "02. Arresting Advice",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Villina Telvor's Quests, Charach",
	text = "Question a smuggler held in the Charach guardhouse."
  },
  {
	id = "PC_m1_K1_VT3",
	name = "03. Downed and Drowned",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Villina Telvor's Quests, Charach",
	text = "Determine the cause of a sudden shipwreck." 
  },
  {
	id = "PC_m1_K1_VT4",
	name = "04. Naval Leverage",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Villina Telvor's Quests, Charach",
	text = "Secure a lobbyist for Charach's naval interests." 
  },
  {
	id = "PC_m1_K1_VT5",
	name = "05. Unjust Confinement",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Villina Telvor's Quests, Charach",
	text = "Reopen the case of the smugglers' lookout." 
  },
  { 
	id = "PC_m1_K1_VT6",
	name = "06. Smugglers' Ruin",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Villina Telvor's Quests, Charach",
	text = "Deal a crippling blow to the smugglers of Stirk Isle." 
  },
  { 
	id = "PC_m1_Anv_Goldenrod, PC_m1_Anv_GoldenrodBR, PC_m1_Anv_GoldenrodDR, PC_m1_Anv_GoldenrodEH, PC_m1_Anv_GoldenrodLI, PC_m1_Anv_GoldenrodPA, PC_m1_Anv_GoldenrodSM, PC_m1_Anv_GoldenrodST",
	name = "Goldenrod House",
	category = "Cyrodiil: Factions | Kingdom of Anvil",
	subcategory = "Miscellaneous",
	text = "Purchase Goldenrod House." 
  },
  
    -- =========================================================================
    -- FIGHTERS GUILD
    -- =========================================================================
  {
    id = "PC_m1_FG_Anv1",
    name = "01. Wet Feet",
    category = "Cyrodiil: Factions | Fighters Guild",
    subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
    text = "Find out what happened to a missing guild member."
  },
  {
    id = "PC_m1_FG_Anv2",
    name = "02. Khofar's Debt",
    category = "Cyrodiil: Factions | Fighters Guild",
    subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
    text = "The guild needs you to collect an unlucky gambler's debt."
  },
  {
    id = "PC_m1_FG_Anv3",
    name = "03. Lost in the Lowlands",
    category = "Cyrodiil: Factions | Fighters Guild",
    subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
    text = "Take care of a Colovian bear that's terrorizing the Gold Road."
  },
  {
    id = "PC_m1_FG_Anv4",
    name = "04. Cinduin's Bounty",
    category = "Cyrodiil: Factions | Fighters Guild",
    subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
    text = "Collect the bounty on a Bosmer outlaw."
  },
  {
    id = "PC_m1_FG_Anv5",
    name = "05. Repossess and Return",
    category = "Cyrodiil: Factions | Fighters Guild",
    subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
    text = "Repossess a painting for the Conservatory of Saint Laeca."
  },
  {
    id = "PC_m1_FG_Anv6",
    name = "06. Perils of Thesigir",
    category = "Cyrodiil: Factions | Fighters Guild",
    subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
    text = "Brave both bandits and beast in Thesigir Chasm."
  },
  {
    id = "PC_m1_FG_Anv7",
    name = "07. Growing Up",
    category = "Cyrodiil: Factions | Fighters Guild",
    subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
    text = "Test the guildmaster's son's abilities by helping him clear an Ayleid ruin."
  },
  {
    id = "PC_m1_FG_Anv8",
    name = "08. Goblin Trouble on the Strident Coast",
    category = "Cyrodiil: Factions | Fighters Guild",
    subcategory = "Palagrius Vinicius' Quests, Anvil Guild",
	text = "Take care of the goblins troubling Brina Cross."
  },
  
    -- =========================================================================
    -- MAGES GUILD
    -- ========================================================================= 
  {
    id = "PC_m1_MG_Anv1",
    name = "01. Delivery to Fort Heath",
    category = "Cyrodiil: Factions | Mages Guild",
    subcategory = "Tisia's Quests, Anvil Guild",
    text = "Deliver some much needed Scrolls of Turn Undead to the legionnaires at Fort Heath."
  },
  {
    id = "PC_m1_MG_Anv2",
    name = "02. Books from Benirus Manor",
    category = "Cyrodiil: Factions | Mages Guild",
    subcategory = "Tisia's Quests, Anvil Guild",
    text = "Borrow some books from the haunted Benirus Manor."
  },
  {
    id = "PC_m1_MG_Anv3",
    name = "03. Kill Aeril",
    category = "Cyrodiil: Factions | Mages Guild",
    subcategory = "Tisia's Quests, Anvil Guild",
    text = "Slay a necromancer that has taken up residence in a nearby crypt."
  },
  {
    id = "PC_m1_MG_Anv4",
    name = "04. Escort Anaryan",
    category = "Cyrodiil: Factions | Mages Guild",
    subcategory = "Tisia's Quests, Anvil Guild",
    text = "Make sure the guild's new expert on necromancy makes it to the guildhall safely."
  },
  {
    id = "PC_m1_MG_Anv5",
    name = "05. Extermination at Strand",
    category = "Cyrodiil: Factions | Mages Guild",
    subcategory = "Tisia's Quests, Anvil Guild",
    text = "Eradicate a group of undead in the ruins of Strand."
  },
  {
    id = "PC_m1_MG_Anv6",
    name = "06. Staff of Banishing Light",
    category = "Cyrodiil: Factions | Mages Guild",
    subcategory = "Tisia's Quests, Anvil Guild",
    text = "Obtain the Staff of Banishing Light from a local enchanter."
  },
  {
    id = "PC_m1_MG_Anv7",
    name = "07. Soul for Baeralorn",
    category = "Cyrodiil: Factions | Mages Guild",
    subcategory = "Tisia's Quests, Anvil Guild",
    text = "Pick up a crystal ball from Anvil's court mage."
  },
  {
    id = "PC_m1_MG_Anv8",
    name = "08. Slay Edroth",
    category = "Cyrodiil: Factions | Mages Guild",
    subcategory = "Tisia's Quests, Anvil Guild",
    text = "Go to the Ayleid ruins of Valsar and kill a necromancer plaguing the Strident Coast."
  },
  { 
	id = "PC_m1_MG_BC1",
	name = "01. A Shocking Experience",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Sielle Eumand's Quests, Brina Cross Guild",
	text = "Get enchanting ingredients at shocking prices!"
  },
  { 
	id = "PC_m1_MG_BC2",
	name = "02. The Spoiled Swordsman",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Sielle Eumand's Quests, Brina Cross Guild",
	text = "Put an end to a swordsman's slander."
  },
  { 
	id = "PC_m1_MG_BC3",
	name = "03. An Unshielded Soul",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Sielle Eumand's Quests, Brina Cross Guild",
	text = "Witness an enlightening lesson in experimental enchanting."
  },
  { 
	id = "PC_m1_MG_BC4",
	name = "04. The Animating Principle",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Sielle Eumand's Quests, Brina Cross Guild",
	text = "Assist Sielle with her experiments by acquiring the soul of a Redeemed Keeper."
  },
  { 
	id = "PC_m1_MG_Cha1",
	name = "01. Five Types of Pearls",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Lysandra Draco's Quests, Charach Guild",
	text = "Scour the seafloor for local varieties of pearls."
  },
  { 
	id = "PC_m1_MG_Cha3",
	name = "02. Unwanted Advances",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Lysandra Draco's Quests, Charach Guild",
	text = "Put a stop to the unwanted advances of an infatuated fool."
  },
  { 
	id = "PC_m1_MG_Cha2",
	name = "01. Welcome Basket",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Ardavan Caralus' Quests, Charach Guild",
	text = "Treat a visiting guild member to some local hospitality."
  },
  { 
	id = "PC_m1_MG_Cha4",
	name = "02. And Stay Out!",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Ardavan Caralus' Quests, Charach Guild",
	text = "Deal with some goblin pests and keep them out for good!"
  },
  { 
	id = "PC_m1_MG_Cha5",
	name = "03. Rescue Divides-To-Iron",
	category = "Cyrodiil: Factions | Mages Guild",
	subcategory = "Ardavan Caralus' Quests, Charach Guild",
	text = "Save a guildmate who got in a little too deep."
  },
 
    -- =========================================================================
    -- THIEVES GUILD
    -- =========================================================================
  {
	id = "PC_m1_TG_Anv1",
	name = "01. Stolen Valor",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
	text = "Con the Navy into buying their own gear."
  },
  {
	id = "PC_m1_TG_Anv2",
	name = "02. Saint Emmelia",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
	text = "Collect the hefty insurance on your tragically crashed ship."
  }, 
  {
	id = "PC_m1_TG_Anv3",
	name = "03. Intercepted Inspiration",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
	text = "Fine art demands an expensive delivery."
  }, 
  {
	id = "PC_m1_TG_Anv4",
	name = "04. The Fix is In",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
	text = "Fix a fight for some fast cash."
  }, 
  {
	id = "PC_m1_TG_Anv5",
	name = "05. The Black Isle Company",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
	text = "Acquire a golden anvil for your 'prestigious' company."
  },
  {
	id = "PC_m1_TG_Anv6",
	name = "06. The Black Isle Bounty",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
	text = "Convince Anvil's upper crust to invest in your new company."
  }, 
  {
	id = "PC_m1_TG_Anv7",
	name = "07. The Black Isle Bubble",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "The Arenthian's Quests, Sailor's Fluke, Anvil",
	text = "Conduct an interview with the Abecean Monitor to make your company's stock soar!"
  }, 
  {
	id = "PC_m1_TG_Cha1",
	name = "01. Vintage Isquel",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
	text = "'Acquire' a rare bottle of isquel for the guild."
  }, 
  {
	id = "PC_m1_TG_Cha2",
	name = "02. Alessian Bronze Boots",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
	text = "Located an ancient pair of boots for a wealthy collector."
  }, 
  {
	id = "PC_m1_TG_Cha3",
	name = "03. Brass Astrolabe",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
	text = "Steal an astrolabe for the guild."
  }, 
  {
	id = "PC_m1_TG_Cha4",
	name = "04. Spring Vida Light-Foot",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
	text = "Break the guild's pawnbroker out of the Goldstone dungeons in Anvil."
  }, 
  {
	id = "PC_m1_TG_Cha5",
	name = "05. Flashgrit",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "Caspus Quillan's Quests, Duskwatch Keep, Charach",
	text = "Acquire three canisters of explosive flashgrit."
  }, 
  {
	id = "PC_m1_TG_Cap",
	name = "01. The Captain",
	category = "Cyrodiil: Factions | Thieves Guild",
	subcategory = "The Masqued Captain's Quests, Crypsis",
	text = "The Masqued Captain has requested your assistance with a job."
  },
  
    -- =========================================================================
    -- ORDER OF THE ITINERANT PRIESTS
    -- =========================================================================
  {
    id = "PC_m1_IP_Als1",
    name = "01. Changing Seasons",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Alsia Juvanus' Quests, Brina Cross",
    text = "A priest seeks closure at a rural wayshrine."
  },
  {
    id = "PC_m1_IP_Als2",
    name = "02. Culture Shock",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Alsia Juvanus' Quests, Brina Cross",
    text = "Quiet a zealot of Zenithar."
  },
  {
    id = "PC_m1_IP_Als3",
    name = "03. Lost Stars",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Alsia Juvanus' Quests, Brina Cross",
    text = "Unravel the meaning of a most perplexing phrase."
  },
  {
    id = "PC_m1_IP_Als4",
    name = "04. Sinweaver",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Alsia Juvanus' Quests, Brina Cross",
    text = "Confront Uricalimo."
  },
  {
    id = "PC_m1_IP_GS1",
    name = "01. The Old Man and the Sea",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Gerius Siralus' Quests, Charach",
    text = "Find both fish and fisherman in the White Reef Isles."
  },
  {
    id = "PC_m1_IP_GS2",
    name = "02. The Blind Share",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Gerius Siralus' Quests, Charach",
    text = "Assist a home for old sailors by collecting a donation from a former pirate."
  },
  {
    id = "PC_m1_IP_GS3",
    name = "03. Drowned Memory",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Gerius Siralus' Quests, Charach",
    text = "Recover a sign of Kynareth's divine favor."
  },
  {
    id = "PC_m1_IP_GS4",
    name = "04. The Broken Shrine",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Gerius Siralus' Quests, Charach",
    text = "Help a member of the order find absolution by restoring a broken shrine."
  },
  {
    id = "PC_m1_IP_HY1",
    name = "01. The Monk and the Missing",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Haela Ysonian's Quests, Strident Coast",
    text = "Break the chains of an imprisoned minotaur."
  },
  {
    id = "PC_m1_IP_HY2",
    name = "02. Parvo's Problem",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Haela Ysonian's Quests, Strident Coast",
    text = "Return the heirloom of a waylaid pilgrim."
  },
  {
    id = "PC_m1_IP_HY3",
    name = "03. Lindasael",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Haela Ysonian's Quests, Strident Coast",
    text = "Retrieve a varla stone for the Temple of Dibella Estetica."
  },
  {
    id = "PC_m1_IP_HY4",
    name = "04. A Place to Serve",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Haela Ysonian's Quests, Strident Coast",
    text = "Find a way for Haela Ysonian and Kuram to serve an Anvil temple."
  },
  {
    id = "PC_m1_IP_Lki1",
    name = "01. Coal for the Furnaces",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Luaki's Quests, Anvil",
    text = "Collect coal for the ascetics of Dibella."
  },
  {
    id = "PC_m1_IP_Lki2",
    name = "02. Dye Me a River",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Luaki's Quests, Anvil",
    text = "Check the Sacred Workshops; someone over there might need help."
  },
  {
    id = "PC_m1_IP_Lki3",
    name = "03. Meat-Cute",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Luaki's Quests, Anvil",
    text = "Prepare Dibellan rites for a Bosmer duo."
  },
  {
    id = "PC_m1_IP_Lki4",
    name = "04. The Drowned",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Luaki's Quests, Anvil",
    text = "Crush a cult or join its ranks."
  },
  {
    id = "PC_m1_IP_Run1",
    name = "01. Alms for the Hostel of Saint Rosunius",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Runs-Towards-Time's Quests, Anvil",
    text = "Raise money for the Hostel of Saint Rosunius."
  },
  {
    id = "PC_m1_IP_Run2",
    name = "02. Bluepox",
    category = "Cyrodiil: Factions | Order of Itinerant Priests",
    subcategory = "Runs-Towards-Time's Quests, Anvil",
    text = "Research and cure a rare disease."
  },
  {
    id = "PC_m1_IP_Run3",
	name = "03. Persarine Contract",
	category = "Cyrodiil: Factions | Order of Itinerant Priests",
	subcategory = "Runs-Towards-Time's Quests, Anvil",
	text = "Of apologetic alchemists and goblin flower-thieves."
  },
  {
	id = "PC_m1_IP_Run4",
	name = "04. Recruit Vurila",
	category = "Cyrodiil: Factions | Order of Itinerant Priests",
	subcategory = "Runs-Towards-Time's Quests, Anvil",
	text = "Re-recruit Vurila, an ex-Itinerant Priest."
  },
    
    -- =========================================================================
    -- BOUNTIES
    -- =========================================================================
  {
    id = "PC_m1_Anv_Bounty_Annka",
    name = "Bounty: Annka Stone-Sides",
    category = "Cyrodiil: Bounties",
    subcategory = "Lantin Chaskav, Anvil",
    text = "Annka Stone-Sides is wanted dead or alive."
  },
  {
    id = "PC_m1_Anv_Bounty_Catius",
    name = "Bounty: Catius Rilo",
    category = "Cyrodiil: Bounties",
    subcategory = "Lantin Chaskav, Anvil",
    text = "Hunt down a murderous deserter from the Imperial Navy."
  },
  {
    id = "PC_m1_Anv_Bounty_Firas",
    name = "Bounty: Firas",
    category = "Cyrodiil: Bounties",
    subcategory = "Lantin Chaskav, Anvil",
    text = "Take down a trio of bandits camped near the Dasek Marsh."
  },
  {
    id = "PC_m1_Anv_Bounty_Jarus",
    name = "Bounty: Jarus Trasius",
    category = "Cyrodiil: Bounties",
    subcategory = "Lantin Chaskav, Anvil",
    text = "Find an armed robber last seen on the Gold Road."
  },
  {
    id = "PC_m1_Anv_Bounty_MC",
    name = "Bounty: The Masqued Captain",
    category = "Cyrodiil: Bounties",
    subcategory = "Lantin Chaskav, Anvil",
    text = "The kingdom's put a price on the head of a pirate lord."
  },
  {
    id = "PC_m1_Anv_Bounty_Rue",
    name = "Bounty: Rue Vaneria",
    category = "Cyrodiil: Bounties",
    subcategory = "Lantin Chaskav, Anvil",
    text = "Find out who's been killing outlaws along the Sutch-Anvil border."
  },
  {
    id = "PC_m1_Anv_Bounty_Rycima",
    name = "Bounty: Rycima",
    category = "Cyrodiil: Bounties",
    subcategory = "Lantin Chaskav, Anvil",
    text = "Capture a skooma dealer on the streets of Anvil."
  },
  {
    id = "PC_m1_Anv_Bounty_SDato",
    name = "Bounty: S'Dato",
    category = "Cyrodiil: Bounties",
    subcategory = "Lantin Chaskav, Anvil",
    text = "Track down a murderer who has fled over the sea."
  },  
  {
    id = "PC_m1_Anv_Bounty_SDato",
    name = "Bounty: Jarus Trasius",
    category = "Cyrodiil: Bounties",
    subcategory = "Foroch, Strident Coast",
    text = "A thief has made off with a bottle of wine."
  }, 
    -- =========================================================================
    -- ARENA
    -- =========================================================================
  {
	id = "PC_m1_AFP01",
	name = "01. Making a Name",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Sign on as a performer in the fighting pit under the Abecette."
  },
  {
	id = "PC_m1_AFP02",
	name = "02. Unbitten?",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Defeat Willy the Unbitten, first lackey of the Nightingale."
  },
  { 
	id = "PC_m1_AFP03",
	name = "03. Saint",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Beat a blessing out of the high priestess of Sed-Yenna."
  },
  {
	id = "PC_m1_AFP04",
	name = "04. Snake",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Strike the Snake – an opponent claiming a Tsaesci bloodline."
  },
  { 
	id = "PC_m1_AFP05",
	name = "05. The Large",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Throw down Harge the Large, scion of giants."
  },
  { 
	id = "PC_m1_AFP06",
	name = "06. Knight of Cups",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Prevail in a fight against a dishonorable knight."
  },
  { 
	id = "PC_m1_AFP07",
	name = "07. Rough Boarding",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Face off against a piratical pair."
  },
  { 
	id = "PC_m1_AFP08",
	name = "08. Less Than Buoyant",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Fend off the glass-clad Armiger, a sworn champion of Vivec."
  },
  { 
	id = "PC_m1_AFP09",
	name = "09. A Thousand Hands and Two",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Depose an Ayleid king to the cheers of the crowd."
  },
  { 
	id = "PC_m1_AFP10",
	name = "10. Warlord Wartgog",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Duel a warlord of Orsinium."
  },
  { 
	id = "PC_m1_AFP11",
	name = "11. Takhur The Terrible",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "Triumph against Takhur the Terrible, a powerful hand-to-hand fighter."
  },
  { 
	id = "PC_m1_AFP12",
	name = "12. Simulacrum",
	category = "Cyrodiil: Arenas",
	subcategory = "Abecette Fight Pit, Anvil",
	text = "The nefarious Nightingale reveals himself! Prepare for battle!"
  },
  
    -- =========================================================================
    -- MISCELLANEOUS
    -- =========================================================================
  {
    id = "PC_m1_Anv_Glimpse",
    name = "A Glimpse of Beauty",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A poet's long absence alarms a follower of Dibella."
  },
  {
    id = "PC_m1_Anv_AdvRead - PC_m1_Anv_AdvReadB",
    name = "Advanced Reading",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Banish a bookseller's unwelcome Guardian."
  },
  {
    id = "PC_m1_Anv_AppBorg",
    name = "An Apprentice for Borgush",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "An old Orc smith seeks an apprentice."
  },
  {
    id = "PC_m1_Anv_BeNeigh",
    name = "Being Neighborly",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Solve a neighbor problem by bringing a silver spear."
  },
  {
    id = "PC_m1_Anv_BlkView",
    name = "Blocking the View",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Remove the tree blocking a heavenly view."
  },
  {
    id = "PC_m1_Anv_BookClub",
    name = "Book Club",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Join a book club in search of dangerous radicals."
  },
  {
    id = "PC_m1_Anv_CallTribe",
    name = "Call for a Tribe",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A tribeless Bosmer wants to join the Srethuun Tribe."
  },
  {
    id = "PC_m1_Anv_CrabBuck",
    name = "Crab Bucket",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Don't murder mooncrabs in a bucket-retrieval run."
  },
  {
    id = "PC_m1_Anv_DauMarks",
    name = "Daughter of a Marksman",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Take down an Alphyn with the help of a young hunter."
  },
  {
    id = "PC_m1_Anv_DownWithShip",
    name = "Down With the Ship",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Recover a body for a guilt-ridden captain."
  },
  {
    id = "PC_m1_Anv_FeedSal",
    name = "Feed Sal",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A sailor is worried about their pet muskrat."
  },
  {
    id = "PC_m1_Anv_GrimFortune",
    name = "A Grim Fortune",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A Tenet-reading predicts a grim fate - or long life."
  },
  {
    id = "PC_m1_Anv_HeriHadr",
    name = "Heritage of the Hadrachs",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Recover three relics from the Hadrach family's crypt."
  },
  {
    id = "PC_m1_Anv_ImpCause",
    name = "Improbable Cause",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "An imprisoned Sea Elf protests his innocence."
  },
  {
    id = "PC_m1_Gld_LetterIn",
    name = "Letter In",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A Breton's pen-pal has stopped writing - find out why."
  },
  {
    id = "PC_m1_Gld_LunarIntox",
    name = "Lunar Intoxication",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Obtain a rare lunar substance for the court wizard."
  },
  {
    id = "PC_m1_Anv_MidLife",
    name = "Mid-Life Crisis",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Occupy an Orc to give his daughter some space."
  },
  {
    id = "PC_m1_Anv_NakedNard, PC_m1_Anv_NakedNardGloves, PC_m1_Anv_NakedNardHat, PC_m1_Anv_NakedNardPants, PC_m1_Anv_NakedNardShirt, PC_m1_Anv_NakedNardShoes",
    name = "The Naked 'Nard",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A nude Montagnard requests your aid."
  },
  {
    id = "PC_m1_Anv_OceanBlue, PC_m1_Anv_OceanBlueDate, PC_m1_Anv_OceanBlueFood, PC_m1_Anv_OceanBlueRoute, PC_m1_Anv_OceanBlueShip",
    name = "The Ocean Blue",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Secure funding for a western trade mission to Akavir."
  },
  {
    id = "PC_m1_Anv_PickPilg",
    name = "The Picky Pilgrim",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A Hlaalu pilgrim pines for Morrowind fare."
  },
  {
    id = "PC_m1_Anv_PirRev",
    name = "A Pirate's Revenge",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "An imprisoned pirate wants revenge on his former captain."
  },
  {
    id = "PC_m1_Anv_PorMug",
    name = "Portrait of a Mugger",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A young artist seeks a place at the Conservatory of Saint Laeca."
  },
  {
    id = "PC_m1_Anv_Recluse",
    name = "The Recluse",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A man seeks someone who can undo the vampiric curse."
  },
  {
    id = "PC_m1_Anv_StrokeFort",
    name = "Stroke of Fortune",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A lucky amulet's been lost to a bet gone bad."
  },
  {
    id = "PC_m1_Anv_TakingTax - PC_m1_Anv_TakingTaxKra - PC_m1_Anv_TakingTaxSle ",
    name = "Taking Care of Taxes",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Aid the collection of tax arrears."
  },
  {
    id = "PC_m1_Anv_ThreeStrang",
    name = "Three Perfect Strangers",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A nobleman misses his wife, and his wife her freedom."
  },
  {
    id = "PC_m1_Anv_WarmWtr",
    name = "Warm Water",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "A Redguard sailor is in hot water."
  },
  {
    id = "PC_m1_Anv_WellMet",
    name = "Well Met By Moonlight",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Class divides beset a fledgling love."
  },
  {
    id = "PC_m1_Anv_WorkOrc, PC_m1_Anv_WorkOrcFG - PC_m1_Anv_WorkOrcFish - PC_m1_Anv_WorkOrcIAS - PC_m1_Anv_WorkOrcKarrel - PC_m1_Anv_WorkOrcNavy - PC_m1_Anv_WorkOrcRG - PC_m1_Anv_WorkOrcSmith - PC_m1_Anv_WorkOrcSW",
    name = "Work for an Orc",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Anvil",
    text = "Help an unemployed orc find work."
  },
  {
    id = "PC_m1_Arc_AloeThere",
    name = "Aloe There",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Archad",
    text = "The healer in Archad wants five portions of aloe vera pulp."
  },
  {
    id = "PC_m1_Arc_Snakebit",
    name = "Snakebitten",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Archad",
    text = "A vicious aspis is terrorizing the village of Archad."
  },
  {
    id = "PC_m1_BC_MurdCross - PC_m1_BC_MurdCrossBrescius - PC_m1_BC_MurdCrossGosha - PC_m1_BC_MurdCrossMedina - PC_m1_BC_MurdCrossRamus - PC_m1_BC_MurdCrossWound",
    name = "Murder on the Crossroads",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Brina Cross",
    text = "Investigate Arahn Kimoi's murder."
  },
  {
    id = "PC_m1_BC_WomPetri, PC_m1_BC_WomPetriLegion, PC_m1_BC_WomPetriLetter",
    name = "A Woman Named Petri",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Brina Cross",
    text = "Claims of stolen valor demand investigation."
  },
  {
    id = "PC_m1_Cha_FigSpeech",
    name = "Fig-ure of Speech",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Charach",
    text = "Explain things to the gremlin Witgi."
  },
  {
    id = "PC_m1_Cha_GhastOrd",
    name = "The Ghastly Ordeal of Saverius Albuttian",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Charach",
    text = "Aid an absconscion from an old sailors home."
  },
  {
    id = "PC_m1_Cha_GoldNets",
    name = "Gold in the Nets",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Charach",
    text = "Discover the truth behind a fisherman's glittering haul."
  },
  {
    id = "PC_m1_Cha_MGTinySeadrake",
    name = "Tiny Seadrake",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Charach",
    text = "A member of the Mages Guild wants you to find a rare seadrake egg."
  },
  {
    id = "PC_m1_Cha_PelLeg",
    name = "The Pelladia Legacy",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Charach",
    text = "Recover the relics of an ancient Colovian lineage."
  },
  {
    id = "PC_m1_Cha_PlaDand",
    name = "Plants for Dandryn Arethyn",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Charach",
    text = "Help a botanist with his studies by collecting some plants."
  },
  {
    id = "PC_m1_Cha_Selkies",
    name = "Selkies",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Charach",
    text = "Help a fisherman find the beautiful woman he's looking for."
  },
  {
    id = "PC_m1_Cha_Cassynder",
    name = "Wreck of the Cassynder",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Charach",
    text = "Dredge up cargo and contraband for Charach's harbormaster."
  },
  {
    id = "PC_m1_Sdk_HermDag",
    name = "The Hermontar Dagger",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Hal Sadek",
    text = "A fisherman is lamenting the loss of his 'lucky dagger'."
  },
  {
    id = "PC_m1_Mrv_ReevesKey",
    name = "Needle in a Haystack",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Marav",
    text = "Hay! Help!"
  },
  {
    id = "PC_m1_Tvy_NobleDebt, PC_m1_Tvy_NobleDebt1 - PC_m1_Tvy_NobleDebt2 - PC_m1_Tvy_NobleDebt3",
    name = "A Noble Debt",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Thresvy",
    text = "A down on his luck noble needs you to handle his debt."
  },
  {
    id = "PC_m1_Tvy_ThresvyDef",
    name = "Thresvy's Defender",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Thresvy",
    text = "Thresvy lacks troops and its Reeve needs an adventurer."
  },
  {
    id = "PC_m1_DM_AdosusAdun",
    name = "Adosu's Adun",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Wilderness (Dasek Marsh)",
    text = "Bring a bard back their instrument from a Dasek Marsh barrow."
  },
  {
    id = "PC_m1_SC_WineMasons",
    name = "Battlewine for Brickmasons",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Wilderness (Strident Coast)",
    text = "Help some construction workers get some relief from their backbreaking labor."
  },
  {
    id = "PC_m1_SC_GoatTrbls",
    name = "Calvus' Goat Troubles",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Wilderness (Strident Coast)",
    text = "Keep an eye out for a missing buck, Kod."
  },
  {
    id = "PC_m1_SC_TravelMerch",
    name = "Fortune of a Traveling Merchant",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Wilderness (Strident Coast)",
    text = "A famed helm is up for sale."
  },
  {
    id = "PC_m1_SC_GarlasAgea - PC_m1_SC_GarlasAgeaAuroran - PC_m1_SC_GarlasAgeaNotes ",
    name = "Into Ugly Obscurity",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Wilderness (Strident Coast)",
    text = "Delve into an Ayleid stronghold, and unlock terrible secrets..."
  },
  {
    id = "PC_m1_SC_ManuMaraud",
    name = "Manuscript Marauders",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Wilderness (Strident Coast)",
    text = "Return an ecologist's research from the outskirts of a bandit camp."
  },
  {
    id = "PC_m1_SC_SweetTooth",
    name = "Pintra's Sweet Tooth",
    category = "Cyrodiil: Miscellaneous",
    subcategory = "Wilderness (Strident Coast)",
    text = "A legionnaire is sick of her monotonous, fishy diet."
  }
}

local hasSent = false

return {
    engineHandlers = {
        onUpdate = function(dt)
           
            if not hasSent then
                print("[Completionist] Sending quest data...")
               
                self:sendEvent("Completionist_RegisterPack", CyrodiilQuests)
               
                print("[Completionist] Data sent successfully!")
                hasSent = true
            end
        end
    }
}