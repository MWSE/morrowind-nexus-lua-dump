local self = require('openmw.self')

local quests = {

    {
        id = "QOTW_072_01",
        name = "Land Ho!",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Clear a Reaver ship docked along the mid Iggnir River on Solstheim."
    },
    {
        id = "QOTW_072_02",
        name = "Land Ho!",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Clear a Reaver ship docked east of Thirsk on Solstheim."
    },
    {
        id = "QOTW_072_03",
        name = "Land Ho!",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Clear a Reaver camp and its ship on Solstheim."
    },
    {
        id = "QOTW_072_04",
        name = "Land Ho!",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Clear a Reaver ship on the northwest coast of Solstheim."
    },
    {
        id = "QOTW_072_05",
        name = "Land Ho!",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Clear a Reaver camp and its ship on Solstheim."
    },
    {
        id = "QOTW_078_01",
        name = "Root Seeds",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find root seeds needed for a task in Skaal Village."
    },
    {
        id = "QOTW_078_02",
        name = "Root Water",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find root water needed for a task in Skaal Village."
    },
    {
        id = "QOTW_001_1",
        name = "Daedric Boots",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a pair of Daedric Boots from the shrine of Zergonipal."
    },
    {
        id = "QOTW_001_2",
        name = "Daedric Cuirass",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a Daedric Cuirass from the shrine of Dushariran."
    },
    {
        id = "QOTW_001_3",
        name = "Daedric Gauntlets",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a pair of Daedric Gauntlets from the shrine of Bal Ur."
    },
    {
        id = "QOTW_001_4",
        name = "Daedric Greaves",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a pair of Daedric Greaves from the shrine of Ularradallaku."
    },
    {
        id = "QOTW_001_5",
        name = "Daedric Helm",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a Daedric Helm from the shrine of Addadshashanammu."
    },
    {
        id = "QOTW_001_6",
        name = "Daedric Pauldrons",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a pair of Daedric Pauldrons from the shrine of Kushtashpi."
    },
    {
        id = "QOTW_001_7",
        name = "Daedric Shield",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a Daedric Shield from the shrine of Assalkushalit."
    },
    {
        id = "QOTW_001_8",
        name = "Daedric Tower Shield",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a Daedric Tower Shield from the shrine of Assurnabitashpi."
    },
    {
        id = "QOTW_014_1",
        name = "Stalhrim Dagger",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a Stalhrim Dagger from Fjell for a Nord in Thirsk."
    },
    {
        id = "QOTW_014_2",
        name = "Grand Soul Gem",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Obtain a Grand Soul Gem from Fjell for a Nord in Thirsk."
    },
    {
        id = "QOTW_014_3",
        name = "Nordic Power Spell",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find a Nordic Power spell for a Nord in Thirsk."
    },
    {
        id = "QOTW_016_1",
        name = "Moonmoth Letter",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deliver a letter to Moonmoth Legion Fort on behalf of the Duke."
    },
    {
        id = "QOTW_016_2",
        name = "Pelagiad Letter",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deliver a letter to Fort Pelagiad on behalf of the Duke."
    },
    {
        id = "QOTW_031_1",
        name = "New Appetites Cannibal",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Hunt down the cannibal threatening Fort Frostmoth."
    },
    {
        id = "QOTW_037_1",
        name = "Cliff Racer Delvery",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deliver a cliff racer trophy to Snedbrir the Smith in Skaal Village."
    },
    {
        id = "QOTW_037_2",
        name = "Cliff Racer Delvery",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deliver a cliff racer trophy to Lassnr in Skaal Village."
    },
    {
        id = "QOTW_037_3",
        name = "Cliff Racer Delvery",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deliver a cliff racer trophy to Risi Ice-Mane in Skaal Village."
    },
    {
        id = "QOTW_038_1",
        name = "Dwarven Battle Axes",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find two Dwarven Battle Axes for Master Aryon's Dwemer exhibit."
    },
    {
        id = "QOTW_038_2",
        name = "Dwarven Spears",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find two Dwarven Spears for Master Aryon's Dwemer exhibit."
    },
    {
        id = "QOTW_038_3",
        name = "Dwemer Boots",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find a pair of Dwemer Boots for Master Aryon's Dwemer exhibit."
    },
    {
        id = "QOTW_039_1",
        name = "Roner Arano's Calcinator",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of four calcinators stolen from a merchant in Mournhold."
    },
    {
        id = "QOTW_039_2",
        name = "Roner Arano's Calcinator",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of four calcinators stolen from a merchant in Mournhold."
    },
    {
        id = "QOTW_039_3",
        name = "Roner Arano's Calcinator",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of four calcinators stolen from a merchant in Mournhold."
    },
    {
        id = "QOTW_039_4",
        name = "Roner Arano's Calcinator",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of four calcinators stolen from a merchant in Mournhold."
    },
    {
        id = "QOTW_041_1",
        name = "Hlaalu Tournament Fighter",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Recruit a House Hlaalu representative for the tournament in Vivec."
    },
    {
        id = "QOTW_041_2",
        name = "Redoran Tournament Fighter",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Recruit a House Redoran representative for the tournament in Vivec."
    },
    {
        id = "QOTW_041_3",
        name = "Telvanni Tournament Fighter",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Recruit a House Telvanni representative for the tournament in Vivec."
    },
    {
        id = "QOTW_041_4",
        name = "Ordinator Tournament Fighter",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Recruit a Temple representative for the tournament in Vivec."
    },
    {
        id = "QOTW_046_1",
        name = "Kill Strange Revel",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Stop the man responsible for unleashing chaos upon the skies."
    },
    {
        id = "QOTW010_1",
        name = "Golden Egg",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of five Golden Eggs hidden along the Bitter Coast."
    },
    {
        id = "QOTW010_2",
        name = "Golden Egg",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of five Golden Eggs hidden along the Bitter Coast."
    },
    {
        id = "QOTW010_3",
        name = "Golden Egg",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of five Golden Eggs hidden along the Bitter Coast."
    },
    {
        id = "QOTW010_4",
        name = "Golden Egg",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of five Golden Eggs hidden along the Bitter Coast."
    },
    {
        id = "QOTW010_5",
        name = "Golden Egg",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find one of five Golden Eggs hidden along the Bitter Coast."
    },
    {
        id = "QOTW_001",
        name = "Scattered Armor",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Collect a scattered set of Daedric armor from shrines across Vvardenfell."
    },
    {
        id = "QOTW_003",
        name = "The Wandering Warrior",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find a Nord wandering near Fort Frostmoth who has lost something."
    },
    {
        id = "QOTW_004",
        name = "Vault Robbery",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate the reported robbery of the Hlaalu Vault in Vivec."
    },
    {
        id = "QOTW_005",
        name = "Axe Of Thunder",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a named weapon on behalf of a smith in the Mournhold Great Bazaar."
    },
    {
        id = "QOTW_006",
        name = "Unrested Spirit",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate mysterious noises heard around Godsreach in Mournhold at night."
    },
    {
        id = "QOTW_007",
        name = "Dwemer Army",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deal with a rumored Dwemer threat near Molag Mar."
    },
    {
        id = "QOTW_008",
        name = "Frostblade",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a Nord in Thirsk recover an ancient blade meaningful to the Skaal."
    },
    {
        id = "QOTW_009",
        name = "Thin Ice",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate the disappearance of a fisherman who went north to fish."
    },
    {
        id = "QOTW_010",
        name = "Egg Hunt",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find five Golden Eggs hidden along the Bitter Coast for an Argonian in Hla Oad."
    },
    {
        id = "QOTW_011",
        name = "Ra'Zakar",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help an Argonian find her friend who has been missing for several days."
    },
    {
        id = "QOTW_012",
        name = "Wellog",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate the disappearance of a man last seen heading toward a Dwemer ruin."
    },
    {
        id = "QOTW_013",
        name = "Cult Of Ur",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate the disappearance of three brothers in Molag Mar."
    },
    {
        id = "QOTW_014",
        name = "Magic Dagger",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Acquire three items for a Nord in Thirsk, including a blade, a soul gem, and a spell."
    },
    {
        id = "QOTW_015",
        name = "Ghostgate Defense",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Respond to rumors of a possible threat to Ghostgate."
    },
    {
        id = "QOTW_016",
        name = "Royal Mail",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deliver important letters after the original courier is found dead."
    },
    {
        id = "QOTW_017",
        name = "Research And Relics",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Clear out a ruin east of Moonmoth for a mage at the Eight Plates in Balmora."
    },
    {
        id = "QOTW_018",
        name = "Smuggling Or Marriage",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find a man and convince him to return home to his wife in Gnaar Mok."
    },
    {
        id = "QOTW_019",
        name = "Murderer On The Loose",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Track down a dangerous murderer who has escaped from Buckmoth Legion Fort."
    },
    {
        id = "QOTW_020",
        name = "Thought That Counts",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find an appropriate gift for a man in Thirsk."
    },
    {
        id = "QOTW_021",
        name = "Booze Treasure",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Follow a lead from a scroll found in Arrille's Tradehouse to a hidden treasure."
    },
    {
        id = "QOTW_022",
        name = "Opposition Legion",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Infiltrate a rogue Orcish militia on behalf of the Imperial Legion."
    },
    {
        id = "QOTW_023",
        name = "One By One",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate a series of overnight disappearances in the village of Vos."
    },
    {
        id = "QOTW_024",
        name = "What A Drink",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Piece together what happened the previous night after waking with no memory."
    },
    {
        id = "QOTW_025",
        name = "A Wizards Paradise",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find a wizard who has gone missing for several days."
    },
    {
        id = "QOTW_026",
        name = "Friends In Justice",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Report a body found in the Mournhold Temple Courtyard to the authorities."
    },
    {
        id = "QOTW_027",
        name = "Treasure Of Ashes",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a traveler obtain a key needed to reach a hidden treasure."
    },
    {
        id = "QOTW_028",
        name = "Curse Of Roarer",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a man break a curse that has afflicted him and his family heirloom."
    },
    {
        id = "QOTW_029",
        name = "Nothing To Lose",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Assist a destitute man living on the streets of Balmora."
    },
    {
        id = "QOTW_030",
        name = "Blurred Memory",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a Nord in Pelagiad track down his missing axe after a night of drinking."
    },
    {
        id = "QOTW_031",
        name = "New Appetites",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate the disappearance of a soldier from Fort Frostmoth."
    },
    {
        id = "QOTW_032",
        name = "Mystery Of The Woods",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate a series of disappearances along the road between Gnisis and Ald-ruhn."
    },
    {
        id = "QOTW_033",
        name = "Two Helms A Day",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a mage in Dagon Fel locate a man believed to be hiding in a Dwemer ruin."
    },
    {
        id = "QOTW_034",
        name = "Two Assassins One Boss",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deliver a package to a contact hiding in the Mournhold sewers."
    },
    {
        id = "QOTW_035",
        name = "Hunting For Rings",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find a missing archer and help her recover a stolen ring."
    },
    {
        id = "QOTW_036",
        name = "Not Lost But Stuck",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Search for a man who went to Ebonheart and never returned home."
    },
    {
        id = "QOTW_037",
        name = "Cliff Racer Trophies",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Hunt cliff racers and deliver trophies to locals in Skaal Village."
    },
    {
        id = "QOTW_038",
        name = "New Exhibit",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find Dwemer artifacts for a new exhibit at the museum in Tel Vos."
    },
    {
        id = "QOTW_039",
        name = "Merchant Prank",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Recover four calcinators hidden throughout Mournhold as a prank."
    },
    {
        id = "QOTW_040",
        name = "Staff Of Slythin",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a mage in Maar Gan recover a staff stolen by a necromancer."
    },
    {
        id = "QOTW_041",
        name = "The Tournament",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Recruit representatives from the Great Houses and Temple for a tournament in Vivec."
    },
    {
        id = "QOTW_042",
        name = "Bell Curse",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Track down a Sixth House cultist who has placed a curse on you."
    },
    {
        id = "QOTW_045",
        name = "Picked And Burned",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate a suspicious blocked door inside Fort Frostmoth."
    },
    {
        id = "QOTW_046",
        name = "Skies On Fire",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Stop a man who has threatened to change the sky using a cauldron."
    },
    {
        id = "QOTW_047",
        name = "In The Shadows",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate a series of murders in Sadrith Mora."
    },
    {
        id = "QOTW_048",
        name = "Little Assassin",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate a suspicious figure found in a storehouse in Raven Rock."
    },
    {
        id = "QOTW_049",
        name = "Where Am I Welcome",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help an Orc worker in Caldera who has been shunned by the locals."
    },
    {
        id = "QOTW_050",
        name = "The Jerk",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deal with a man who has been stealing coins from people in a tavern."
    },
    {
        id = "QOTW_051",
        name = "From The Roots",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate the cause of structural weakening in Tel Branora."
    },
    {
        id = "QOTW_052",
        name = "Freedom To The North",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help an Argonian slave at Fort Frostmoth evade his pursuing master."
    },
    {
        id = "QOTW_053",
        name = "Roots",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a man from Cyrodiil search for his family's Redoran connections in Morrowind."
    },
    {
        id = "QOTW_054",
        name = "Stranded At Sea",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Search for a fisherman from Ald Velothi who went out to sea and never returned."
    },
    {
        id = "QOTW_055",
        name = "Have A Feast On Me",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Arrange a feast for the soldiers stationed at Fort Frostmoth."
    },
    {
        id = "QOTW_056",
        name = "Northern Reach",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Join a new guild of explorers operating out of Fort Frostmoth on Solstheim."
    },
    {
        id = "QOTW_057",
        name = "Outbreak",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help an apothecary in Mournhold identify the source of a spreading illness."
    },
    {
        id = "QOTW_058",
        name = "Bar Wars",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Mediate a dispute between two Dunmer over who has claim to a tavern in Balmora."
    },
    {
        id = "QOTW_059",
        name = "Morals",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Assist a man speaking out against certain practices in Morrowind."
    },
    {
        id = "QOTW_060",
        name = "The Coming Storm",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Deliver a supply of food to a man in Mournhold preparing for difficult times."
    },
    {
        id = "QOTW_061",
        name = "A Cornered Rat",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a woman arrange safe passage out of Vivec for her brother in hiding."
    },
    {
        id = "QOTW_062",
        name = "All For A Few Drakes",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help resolve a guard pay dispute in Suran before it escalates."
    },
    {
        id = "QOTW_063",
        name = "Locked Away",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a researcher who has made a Dwemer discovery in northern Solstheim."
    },
    {
        id = "QOTW_064",
        name = "Broken Trades",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate pirates disrupting East Empire Company trade along Vvardenfell's coast."
    },
    {
        id = "QOTW_065",
        name = "Bloody Business",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate the disappearance of a local man in Morrowind."
    },
    {
        id = "QOTW_066",
        name = "The Jason",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Report a man making violent threats to the local guards."
    },
    {
        id = "QOTW_067",
        name = "Foreign Manhunt",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help warriors from Skyrim track down a fugitive Nord hiding in Morrowind."
    },
    {
        id = "QOTW_068",
        name = "Fighters Competition",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help preserve the Fighters Competition in Balmora from cancellation."
    },
    {
        id = "QOTW_069",
        name = "Fresh Bate",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Join a Redguard and her crew in a raid on a nearby Imperial ship."
    },
    {
        id = "QOTW_070",
        name = "Bad Hiding Spot",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate the whereabouts of a man who has gone missing from Khuul."
    },
    {
        id = "QOTW_071",
        name = "Ore Rush",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate rumors of a mine hidden beneath Mournhold."
    },
    {
        id = "QOTW_072",
        name = "Land Ho!",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help clear Reaver encampments and ships along the coast of Solstheim."
    },
    {
        id = "QOTW_073",
        name = "Cross Dresser",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a wanted man in Tel Mora change the townspeople's attitude toward him."
    },
    {
        id = "QOTW_074",
        name = "Forgotten Sacrifices",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help an aging Imperial soldier find a place to retire in Morrowind."
    },
    {
        id = "QOTW_075",
        name = "Lost Pages",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a stolen book for a mage in the Ald-ruhn Mages Guild."
    },
    {
        id = "QOTW_076",
        name = "Love Dies",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find a missing husband who was last seen heading toward Suran."
    },
    {
        id = "QOTW_077",
        name = "A Loyal Follower",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Track down a hired companion who robbed you and disappeared."
    },
    {
        id = "QOTW_078",
        name = "A Village Tree",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help a smith obtain a tree to plant in the center of Skaal Village."
    },
    {
        id = "QOTW_079",
        name = "Ministry Heist",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Retrieve a holy artifact hidden inside the Ministry of Truth in Vivec."
    },
    {
        id = "QOTW_080",
        name = "Watching Among Us",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Find the stranger who pulled you from the icy waters of Lake Fjalding."
    },
    {
        id = "QOTW002",
        name = "Thief On The Loose",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Help track down an escaped prisoner loose in Mournhold."
    },
    {
        id = "QOTW043",
        name = "Creature I Have Become",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate a series of murders occurring at night in the Mournhold Temple Courtyard."
    },
    {
        id = "QOTW044",
        name = "Smuggler Trouble",
        category = "Miscellaneous",
        subcategory = "Quest of the Week",
        master = "Quest Of The Week",
        text = "Investigate thieves who have broken into a guard tower in Pelagiad."
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
-- Quest count: 121
